#!/bin/bash
# created by David Ross
version="0.01"


### NOTES ###############################################
# FASTQ, HUMAN_GENOME, AMPLICON_BED and CpG_SITES have to be copied over to scratch first
#########################################################


### HELP PAGE ###########################################
if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    echo -e "usage:\t[-h] [-f DIR] [-d DIR] [-r DIR] [-a FILE] [-c FILE] [-o DIR] [-s STRING]\n"
    echo -e "Calculate the total coverage, CpG coverage & CpG coverage per given CpG site from \na given set of FASTQ files over a set of given amplicons\n"
    echo -e "required arguments:"
    echo -e "-f, --fastq\tpath containing dirs with fastq files"
    echo -e "-d, --dir\tdirectory in which data generation will take place (SCRATCH)"
    echo -e "-r, --ref\tdirectory containing BS-converted genome"
    echo -e "-a, --amplicon\tBED file containing amplicon start and end coordinates"
    echo -e "optional arguments:"
    echo -e "-b, --basespace\tbasespace project name to download FASTQ files from"
    echo -e "-c, --cpg\tfile containing CpG sites of interest in BED like format"    
    echo -e "options:"
    echo -e "--bs-convert\tBS-convert the given reference genome"
    echo -e "--no-sams\tdo not generate SAM files"
    exit 0
fi
#########################################################


### VERSION #############################################
if [ "$1" = "-v" ] || [ "$1" = "--version" ] ; then
    echo "version $version"
    exit 0
fi
#########################################################


### ARGUMENT PARSER #####################################
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in 
      -f|--fastq) FASTQ_DIR="$2"; shift ;;
      -d|--dir) SCRATCH="$2"; shift ;;
      -r|--ref) REF="$2"; shift ;;
      -a|--amplicon) AMPLICON="$2"; shift ;;
      -c|--cpg) CPG="$2"; shift ;;
      -b|--basespace) BASESPACE="$2"; shift ;;
      --bs-convert) BS_CONVERT="YES" ;;
      --no-sams) SAM_GENERATION="NO" ;;
      *) echo -e "Unknown argument:\t$arg"; exit 0 ;;
    esac

    shift
done

# make the following arguments compulsory
if [ -z $FASTQ_DIR ]; then
    echo "--fastq argument is required"
    exit 1
elif [ -z $SCRATCH ]; then
    echo "--dir argument is required"
    exit 1 
elif [ -z $REF ]; then
    echo "--ref argument is required"
    exit 1 
elif [ -z $AMPLICON ]; then
    echo "--amplicon argument is required"
    exit 1 
fi

#########################################################


### GLOBAL VARIABLES #####################################
SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/scripts/ # the absolute path of the dir in which this script is within
SAMS=$SCRATCH/alignment/sams/
BEDS=$SCRATCH/BED_files/
BME=$SCRATCH/BME/
FASTQC=$SCRATCH/fastqc/
RESULT=$SCRATCH/results/

##########################################################


### FUNCTIONS ############################################

##############################################
# download_FASTQ()
#
# download fastq files from a parsed project 
# name present on your basespace page
#
# Globals:
#   FASTQ_DIR = dir containing subdir with fastq pairs
#   BASESPACE = basespace project name containing FASTQ files
#
# Returns:
#   downloads and saves fastq files to $FASTQ_DIR
#
##############################################

download_FASTQ() {
    # check config file exist
    if [ ! -f $HOME/.basespacepy.cfg ]; then
       >&2 echo "ERROR: $HOME/.basespacepy.cfg does not exist"
       exit 1
    fi 

    KEY=`awk 'FNR == 3 {print $3}' ~/.basespacepy.cfg`
    SECRET=`awk 'FNR == 4 {print $3}' ~/.basespacepy.cfg`
    TOKEN=`awk 'FNR == 5 {print $3}' ~/.basespacepy.cfg`
    
    python2 $SCRIPTS/basespace/samples2files.py \
      -K $KEY -S $SECRET -A $TOKEN -y $BASESPACE -o $FASTQ_DIR
}


##############################################
# generate_SAMS()
#
# Trim the CS1rc and CS2rc adapters from the 
# FASTQ files, generate fastqc and SAM files.
#
# Globals:
#   FASTQ_DIR = dir containing subdirs with fastq pairs.
#   REF = dir containing BS-converted reference geneome.
#   SCRATCH = dir used to generate files
#   SAMS = dir containing SAM files
#
# Returns:
#   SAM files
#
##############################################

generate_SAMS() {
    # Quality and adpater trimming of all fastqs. CS1rc and CS2rc need to be trimmed off, this explains the high C % per base sequence count at the end of the read.
    FASTQS=`find $FASTQ_DIR/*/* -iregex '.*\.\(fastq.gz\|fq.qz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | sort`
    
    # ensure there are an even number of fastq files
    FASTQS_NUM=`echo $FASTQ | wc -w`
    if [ $((FASTQ_NUM%2)) -eq 0 ]; then
        # even
	echo "SUCCESS: Acceptable number of fastq files found ($FASTQS_NUM). Fastq files will be paired and parsed into trim-galore as follows:"
	for f in `echo $FASTQS | xargs -n 2`; do echo -e "$f \n"; done
    else
	# odd
	>&2 echo "ERROR: Unacceptable number of fastq files found ($FASTQS_NUM). Must be even number of fastq files. The following fastq files would have been paired before being parsed into trim-galore:"
	for f in `echo $FASTQS | xargs -n 2`; do echo -e "$f \n"; done
	exit 1
    fi

    # -n2 works under the assumption that the FATSQS are sorted in read pairs
    echo $FASTQS | xargs -n2 trim_galore --paired \
    				     --path_to_cutadapt /exports/eddie3_homes_local/dross11/.local/bin/cutadapt \
    				     --output_dir $SCRATCH/fastq_trimmed/ \
    				     --adapter AGACCAAGTCTCTGCTACCGTA \
    				     --adapter2 TGTAGAACCATGTCGTCAGTGT \
    				     --trim1 
    
    fastqc $SCRATCH/fastq_trimmed/*val*gz -o $FASTQC
    
    # generate list of post-trimmed Read 1 and Read 2 fastq files (not sure if adding the comma is neccessary.
    R1=`find $SCRATCH/fastq_trimmed/ -iregex '.*\(_R1_*val.*\|val_1.\)\(fq.gz\|fastq.gz\|fq\|fastq\|sanfastq\|sanfastq.gz\)' | sort | xargs | sed 's/ /,/g'`
    R2=`find $SCRATCH/fastq_trimmed/ -iregex '.*\(_R2_*val.*\|val_2.\)\(fq.gz\|fastq.gz\|fq\|fastq\|sanfastq\|sanfastq.gz\)' | sort | xargs | sed 's/ /,/g'`
    
    # align to BS-converted genome and convert bam to sam files. Bowtie2 for >50bp reads.
    bismark --bowtie2 -1 $R1 -2 $R2 --sam -o $SAMS/ $REF 

    # create a mapping efficiency summary file
    find $SAMS/ -name "*_report.txt" | xargs grep "Mapping efficiency" | sed 's/:/\t/g' | awk -F"/" '{print $NF}' > $SCRATCH/mapping_efficiency_summary.txt

}


##############################################
# Coverage()
#
# Gets the total coverage for reads in the bismark
# SAM files for all samples and output into a tsv file.
#
# Globals:
#   SAMS = dir containing SAM files
#   BEDS = dir containing to be generated BED files
#   SCRIPTS = dir containing all scripts
#   RESULT = dir to place returned file
#   CUT_AMP = bed file containing amplicon co-ordinates
#
# Returns:
#   a tsv file which shows the coverage
#   for each sample (columns) across
#   each amplicon region (rows).
##############################################

Coverage() {
	# determines which reads are proper pairs (judging from the bitwise flags..) and parse the read start and end positions into a BED file
    find $SAMS -name *sam | xargs -I {} python2 $SCRIPTS/sam_parsers/Sam2Bed.py {} {}.bed
    find $SAMS -name *bed -print0 | xargs -r0 mv -t $BEDS
    
    # get the coverage per amplicon for the given intervals.
    for bed in `find $BEDS -name *bed | xargs`; do
        bedtools coverage -a $CUT_AMP -b $bed > ${bed}_coverage.txt
        mv ${bed}_coverage.txt $BEDS/coverage/
    done
    
    # give the dir containing the coverage text files
    python $SCRIPTS/reshapers/CoverageParser.py -d $BEDS/coverage/ -o $RESULT/pre_Coverage.tsv

    # alter column names in header to sample names
    python $SCRIPTS/content_modifiers/change_header.py -i $RESULT/pre_Coverage.tsv -o $RESULT/Coverage.tsv
    rm $RESULT/pre_Coverage.tsv
}


##############################################
# CpG_divided_cov()
#
# Gets both the methylated and unmethylated CpG 
# coverage for both OT and OB strands across each 
# given amplicon for every sample & output into a
# tsv file.
#
# Globals:
#   BME = dir to contain meth calls for every CpG CpH and CHH sites
#   SAMS = dir containing SAM files
#   SCRIPTS = dir containing all scripts
#   RESULT = dir to place returned file
#   SCRATCH = dir used to generate files
#   CUT_AMP = bed file containing amplicon co-ordinates
#   AMPLICON = bed file containing amplicon co-ordinates plus OT/OB status in a fourth column
#
# Returns:
#   a tsv file containing CpG methylation 
#   coverage for every every sample (columns)
#   across each amplicons strand and methylation
#   status (4 rows per amplicon)
#
# Notes:
#   OT: original top strand
#   OB: original bottom starnd
##############################################

CpG_divided_cov() {
    # Duncans perl script takes BME results and creates 2 BED files; one for meth CpG and another for unmeth CpG sites
    find $BME -name "CpG*txt" | xargs -I {} perl -w $SCRIPTS/sam_parsers/MethUnmethCpGs2Bed.pl {} 
    find $BME -name "CpG*BED" -print0 | xargs -r0 mv -t ${SCRATCH}/BME_BED
    
    # get the coverage for methylated CpG 
    for bed in `find ${SCRATCH}/BME_BED -name CpG*BED | xargs`; do
        bedtools coverage -a $CUT_AMP -b $bed > ${bed}_coverage.txt
        mv ${bed}_coverage.txt ${SCRATCH}/BME_BED/coverage/
    done
    
    # Create the output tsv file
    perl -w $SCRIPTS/reshapers/DivededCoverageParser.pl $AMPLICON ${SCRATCH}/BME_BED/coverage/ > $RESULT/pre_CpG_divided_coverage.tsv

    # alter the column names to the sample it refers to 
    python $SCRIPTS/content_modifiers/change_header.py -i $RESULT/pre_CpG_divided_coverage.tsv -o $RESULT/CpG_divided_coverage.tsv
    rm $RESULT/pre_CpG_divided_coverage.tsv

}


##############################################
# CpG_meth_cov_site()
#
# Calculate the CpG methylation coverage % across
# each site given in the CpG_site file and output
# into a tsv file.
#
# Globals:
#   BME = dir to contain meth calls for every CpG CpH and CHH sites
#   SCRIPTS = dir containing all scripts
#   RESULT = dir to place returned file
#   SCRATCH = dir used to generate files
#
# Returns:
#   a tsv containing CpG methylation percentage
#   across all samples (columns) across all sites
#   detailed in the given CpG sites of interest 
#   file (rows)
#
##############################################

CpG_meth_cov_site() {
    # create fastq-filename/sample list
    SAM_LIST=`find $FASTQ_DIR/ -iregex '.*\(_R1_\|_1.\).*\.\(fastq.gz\|fq.qz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | awk -F"/" '{print $NF}' | awk -F"." '{print $1}' | sort | xargs`
    
    # bismark2bedgraph needed to produce the coverage files along with the bedgraph files
    for sam in $SAM_LIST; do
        cpg_pairs=`find $BME -name "CpG*_${sam}_*txt" | xargs`
        bismark2bedGraph $cpg_pairs --dir ${SCRATCH}/BME_bedgraph -o ${sam}.bedGraph
        gunzip ${SCRATCH}/BME_bedgraph/*.gz
    done 
   
    # determine whther to filter for specific CpG sites or not 
    if [ -z $CPG ]; then 
        python3 $SCRIPTS/reshapers/SiteMethPercParser.py -b ${SCRATCH}/BME_bedgraph/ -o $RESULT/pre_CpG_meth_percent_site.tsv
    else
        # CpG_sites.csv contains CpG sites which are found to be highly differntailly methylated between tumour and leukocytes
        python3 $SCRIPTS/reshapers/SiteMethPercParser.py -b ${SCRATCH}/BME_bedgraph/ -p $CPG -o $RESULT/pre_CpG_meth_percent_site.tsv
    fi

    # alter column names in header to sample names
    python $SCRIPTS/content_modifiers/change_header.py -i $RESULT/pre_CpG_meth_percent_site.tsv -o $RESULT/CpG_meth_percent_site.tsv
    rm $RESULT/pre_CpG_meth_percent_site.tsv
}


##########################################################


### EXECUTION ############################################

main() {
    # construct the required directories if they are not present
    mkdir -p $SAMS $BEDS/coverage $BME $FASTQC ${SCRATCH}/BME_BED/coverage/ ${SCRATCH}/BME_bedgraph/ $SCRATCH/fastq_trimmed/ $RESULT

    # cut the amplicon file (in case it has OT/OB info in the fourth column), bedtools coverage behaves differently if a fourth column is present 
    # so doing this is neccassery for getting an accurate output from Coverage() and CpG_meth_cov_site()
    awk '{print $1 "\t" $2 "\t" $3}' $AMPLICON > $RESULT/AmpliconLocation.BED
    CUT_AMP=$RESULT/AmpliconLocation.BED

    # download FASTQ files if BASESPACE var not empty (; if --basespace arg given)
    if [ ! -z $BASESPACE ]; then
	download_FASTQ
    fi

    # BS-convert the genome if the $BS_CONVERT variable is not empty (; if --bs-convert option selected)
    if [ ! -z $BS_CONVERT ]; then
        bismark_genome_preparation --bowtie2 $REF 
    fi
    
    # generate bismark SAM files provided --no-sams option has not been given
    if [ -z $SAM_GENERATION ]; then
    	generate_SAMS
    fi
    
    # extract the methylation call for every C and write out its position. Report will allow you to work out methylation % in CpG, CHG & CHG contexts. 
    # --mbias_off as GD perl module error disallows its creation in eddie3.
    bismark_methylation_extractor -p --mbias_off -o $BME/ `find $SAMS -name *sam | xargs`
    
    # get coverage for all samples/FASTQs
    Coverage
    
    # get coverage for all CpG that are meth/unmeth/OT/OB
    CpG_divided_cov
    
    # get CpG methylation percantages for all sites stored in $CPG
    CpG_meth_cov_site
}

main

##########################################################

