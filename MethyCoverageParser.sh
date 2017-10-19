#!/bin/bash
# created by David Ross
version="v0.05"

# TODO: reduce repetitive code in reshaper scripts (check out design patterns)

### NOTES ###############################################
# FASTQ, HUMAN_GENOME, AMPLICON_BED and CpG_SITES have to be copied over to scratch (--dir) first
#
# The below command is useful for identifying unanticipated outputs within this scripts STANDOUT & STANDERR
#        grep "ERROR\|SUCCESS\|NOTE\|SKIPPING" <log-files>
#########################################################


### HELP PAGE ###########################################
if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
	cat <<- EOF
	usage:  [-h] [-f DIR] [-d DIR] [-r DIR] [-a FILE] [-b STRING ] [-c FILE] [-f FILE]

	Calculate the total coverage, CpG coverage & CpG coverage per given CpG site from 
	a given set of FASTQ files over a set of given amplicons

	required arguments:
	-f, --fastq          path containing dirs with fastq files
	-d, --dir            directory in which data generation will take place (SCRATCH)
	-r, --ref            directory containing BS-converted genome
	-a, --amplicon       BED file containing amplicon start and end coordinates
	optional arguments:
	-b, --basespace      basespace project name to download FASTQ files from
	-c, --cpg            file containing CpG sites of interest in BED like format    
	-f, --filter-by-tile filter reads based on tile quality - path to BBMap dir
	options:
	--bs-convert         BS-convert the given reference genome
	--non-directional    align in an non-directional fashion
	--fluidigm           trim the fluidigm CS1rc & CS2rc adapters from FASTQs
	--no-sams            do not generate SAM files
	--no-trim            do not trim FASTQ files
	--no-bme             do not generate BME or bedgraph coverage files
	other:
	--help               print this help page 
	--version            print version number
	--test               test the application - requires path to genome as argument
	EOF
	exit 0
fi
#########################################################


### VERSION #############################################
if [ "$1" = "-v" ] || [ "$1" = "--version" ] ; then
    echo "version $version"
    exit 0
fi
#########################################################


### TEST ################################################
if [ "$1" = "-t" ] || [ "$1" = "--test" ] ; then
    # store the path to the directory in which this script is within
    HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    qsub -M ${USER}@staffmail.ed.ac.uk -m a -m b -m e \
        $HERE/test/test1.sh $2 $HERE
    qsub -M ${USER}@staffmail.ed.ac.uk -m a -m b -m e \
        $HERE/test/test2.sh $2 $HERE
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
      -f|--filter-by-tile) BBMAP="$2"; shift ;;
      --bs-convert) BS_CONVERT="YES" ;;
      --non-directional) DIRECTIONAL="NO" ;;
      --no-sams) SAM_GENERATION="NO" ;;
      --no-trim) TRIM="NO" ;;
      --no-bme) METHY_EXTRACT="NO" ;;
      --fluidigm) FLUIDIGM="YES" ;;
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
FASTQS=`find $FASTQ_DIR/*/* -iregex '.*\.\(fastq.gz\|fq.gz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | sort`
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
       >&2 echo "ERROR: $HOME/.basespacepy.cfg does not exist," \
                "this must be present to download FASTQ files from BaseSpace"
       exit 1
    fi 
    
    # basespace-python-sdk has trouble reading the config file, hence the below awk hack
    KEY=`awk 'FNR == 3 {print $3}' ~/.basespacepy.cfg`
    SECRET=`awk 'FNR == 4 {print $3}' ~/.basespacepy.cfg`
    TOKEN=`awk 'FNR == 5 {print $3}' ~/.basespacepy.cfg`
 
    # basespace-sdk-python is written in python2
    python2 $SCRIPTS/basespace/samples2files.py \
      -K $KEY -S $SECRET -A $TOKEN -y $BASESPACE -o $FASTQ_DIR
    
    # update FASTQS var
    FASTQS=`find $FASTQ_DIR/*/* -iregex '.*\.\(fastq.gz\|fq.gz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | sort`
}


#############################################
# get_FASTQ_num()
#
# Detrmine the number of FASTQS, if odd number 
# then exit script and warn user.
#
#
# Globals:
#   FASTQS = list of all fastq files to 
#   FASTQ_DIR = dir containg FASTQ files
#
##############################################

get_FASTQ_num() {

    FASTQS=`find $FASTQ_DIR/*/* -iregex '.*\.\(fastq.gz\|fq.gz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | sort`
    FASTQS_NUM=`echo $FASTQS | wc -w`

    if [ $((FASTQS_NUM%2)) -eq 0 ]; then
        # even
        echo "SUCCESS: Acceptable number of fastq files found ($FASTQS_NUM)." \
             "Fastq files will be paired and parsed into filterbytile and/or trim-galore as follows:"
        echo $FASTQS | xargs -n 2
    else
	    # odd
        >&2 echo "ERROR: Unacceptable number of fastq files found ($FASTQS_NUM)." \
                 "Must be even number of fastq files. The following fastq files" \
                 "would have been paired before being parsed into filterbytile and/or trim-galore:"
        >&2 echo $FASTQS | xargs -n 2
        exit 1
    fi
}


#############################################
# filter_by_tile()
#
# Remove reads from FASTQ files with tile positional
# issues; poor sequence per til quality in fastqc output
#
# Globals:
#   FASTQS = all FASTQ files 
#
# Returns:
#   FASTQS = filtered FASTQ files
#
#############################################

filter_by_tile() {
    
    echo "NOTE: filtering FASTQ files based upon tile quality"

    # NOTE: below sed hack is not nice, fix it
    for read_pairs in `echo $FASTQS | xargs -n 2 | sed 's/ /____/g'`; do
        FIRST=`echo $read_pairs | awk -F'____' '{print $1}'`
        SECOND=`echo $read_pairs | awk -F '____' '{print $2}'`
        FIRST_OUT=`echo $FIRST | awk -F'/' '{print $NF}'`
        SECOND_OUT=`echo $SECOND | awk -F'/' '{print $NF}'`
        
        $BBMAP/filterbytile.sh in1=$FIRST in2=$SECOND \
             out1=$SCRATCH/fastq_filtered/$FIRST_OUT \
             out2=$SCRATCH/fastq_filtered/$SECOND_OUT
    done
        
    # trim these FASTQ files instead of the raw fastq files
    FASTQS=`find $SCRATCH/fastq_filtered/* -iregex '.*\.\(fastq.gz\|fq.gz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | sort`

}

##############################################
# trim_FASTQS()
#
# Trim the CS1rc and CS2rc or Ilumina adapters from the 
# FASTQ files and subsequently produce FastQC files.
#
# Globals:
#   FLUIDIGM = var determining what adapters to trim
#   FASTQS = raw or fltered FASTQ files
#   FASTQC = dir to contain fastqc reports
# 
# Returns:
#   SAM files
#
##############################################

trim_FASTQS() {

    if [ ! -z $BBMAP ]; then
        echo "NOTE: Filtered FASTQ files will be trimmed"
    else
        echo "NOTE: Raw FASTQ files will be trimmed"
    fi
       
    if [ ! -z $FLUIDIGM ]; then
        # -n2 works under the assumption that the FATSQS are sorted in read pairs
        echo "NOTE: Trimming Fluidigm CS1rc and CS2rc sequencing primers from FASTQ files"
        echo $FASTQS | xargs -n2 trim_galore --paired \
                             --output_dir $SCRATCH/fastq_trimmed/ \
                             --adapter AGACCAAGTCTCTGCTACCGTA \
                             --adapter2 TGTAGAACCATGTCGTCAGTGT \
                             --trim1 \
                             --fastqc_args "--outdir $FASTQC"
    else
        echo "NOTE: Trimming Illumina sequencing primers from FASTQ files"
        echo $FASTQS | xargs -n2 trim_galore --paired \
                                 --output_dir $SCRATCH/fastq_trimmed/ \
                                 --trim1 \
                                 --fastqc_args "--outdir $FASTQC"
    fi

}


##############################################
# generate_SAMS()
#
# Generate SAM files and summary mapping effciency
# file.
#
# Globals:
#   REF = dir containing BS-converted reference geneome.
#   DIRECTIONAL = if variable empty then align directionally
#   SCRATCH = dir used to generate files
#   SAMS = dir containing SAM files
# 
# Returns:
#   SAM files
#
##############################################

generate_SAMS() {
   
    # generate list of post-trimmed Read 1 and Read 2 fastq files
    R1=`find $SCRATCH/fastq_trimmed/ -iregex '.*\(_R1_*val.*\|val_1.\)\(fq.gz\|fastq.gz\|fq\|fastq\|sanfastq\|sanfastq.gz\)' |  sort | xargs | sed 's/ /,/g'`
    R2=`find $SCRATCH/fastq_trimmed/ -iregex '.*\(_R2_*val.*\|val_2.\)\(fq.gz\|fastq.gz\|fq\|fastq\|sanfastq\|sanfastq.gz\)' | sort | xargs | sed 's/ /,/g'`
    
    # align to BS-converted genome and convert bam to sam files. Bowtie2 for >50bp reads.
    if [ -z $DIRECTIONAL ]; then
        echo "NOTE: aligning in directional fashion"
        bismark --bowtie2 -1 $R1 -2 $R2 --sam --temp_dir $SCRATCH -o $SAMS/ $REF 
    else 
        echo "NOTE: aligning in non-directional fashion"
        bismark --non_directional --bowtie2 -1 $R1 -2 $R2 --sam --temp_dir $SCRATCH -o $SAMS/ $REF 
    fi

    # create a mapping efficiency summary file
    find $SAMS/ -name "*_report.txt" | xargs grep "Mapping efficiency" | sed 's/:/\t/g' | awk -F"/" '{print $NF}' > $RESULT/mapping_efficiency_summary.txt

}

#############################################
# generate_BME()
#
# Produce BME and bedgrpah files 
#
# Globals:
#   BME = output directory for BME files
#   SAMS = directory containing alignment files
#   SCRATCH = directory of data processing
#   FASTQ_DIR = directory containing raw FASTQ files
#
#############################################
generate_BME() {

    echo "NOTE: generating BME files"

    # extract the methylation call for every C and write out its position. 
    # --mbias_off as GD perl module error disallows its creation within eddie3.
    bismark_methylation_extractor -p --mbias_off -o $BME/ `find $SAMS -name "*sam" | xargs`
     
    # create fastq-filename/sample list
    SAM_LIST=`find $FASTQ_DIR/ -iregex '.*\(_R1_\|_1.\).*\.\(fastq.gz\|fq.gz\|fq\|fastq\|sanfastq.gz\|sanfastq\)$' | awk -F"/" '{print $NF}' | awk -F"." '{print $1}' | sort | xargs`
    
    # produce bedgraph coverage files
    for sam in $SAM_LIST; do
        cpg_pairs=`find $BME -name "CpG*_${sam}_*txt" | xargs`
        bismark2bedGraph $cpg_pairs --dir ${SCRATCH}/bedgraph -o ${sam}.bedGraph
        gunzip ${SCRATCH}/bedgraph/*.gz
    done 
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
#   DIRECTIONAL = if variable empty then align directionally
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
    echo -e "NOTE: the following SAMs will be converted to BED\n`find $SAMS -name '*sam'`"

    # add complementary proper paired reads to BED file if directional is not empty
    if [ -z $DIRECTIONAL ]; then
        find $SAMS -name '*sam' | xargs -I {} python $SCRIPTS/sam_parsers/Sam2Bed.py --sam {} --bed {}.bed
    else
        find $SAMS -name '*sam' | xargs -I {} python $SCRIPTS/sam_parsers/Sam2Bed.py --non_directional --sam {} --bed {}.bed
    fi

    find $SAMS -name '*bed' -print0 | xargs -r0 mv -t $BEDS
    
    # get the coverage per amplicon for the given intervals.
    for bed in `find $BEDS -name '*bed' | xargs`; do
        echo "NOTE: calculating $bed coverage...."
        bedtools coverage -a $CUT_AMP -b $bed > ${bed}_coverage.txt
        mv ${bed}_coverage.txt $BEDS/coverage/
    done
    
    if [ -z $CPG ]; then 
        # give the dir containing the coverage text files
        python $SCRIPTS/reshapers/coverage_parser.py \
            -d $BEDS/coverage/ -o $RESULT/pre_coverage.tsv
    else
        python $SCRIPTS/reshapers/coverage_parser.py \
            -d $BEDS/coverage/ -p $CPG -o $RESULT/pre_coverage.tsv
    fi

    # alter column names in header to sample names
    python $SCRIPTS/content_modifiers/change_header.py \
        -i $RESULT/pre_coverage.tsv -o $RESULT/coverage.tsv
    rm $RESULT/pre_coverage.tsv

}


##############################################
# CpG_amplicon_cov()
#
# Gets both the total methylated and unmethylated CpG 
# coverage across each given amplicon for every 
# sample from the bedGraph coverage files & outputs 
# it into a tsv file.
#
# Globals:
#   SCRIPTS = dir containing all scripts
#   RESULT = dir to place returned file
#   SCRATCH = dir used to generate files
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

CpG_amplicon_cov() {

    if [ -z $CPG ]; then 
        python $SCRIPTS/reshapers/cpg_amplicon_coverage.py -a $AMPLICON \
            -b ${SCRATCH}/bedgraph/ -o $RESULT/pre_CpG_amplicon_coverage.tsv
    else
        python $SCRIPTS/reshapers/cpg_amplicon_coverage.py -a $AMPLICON \
            -b ${SCRATCH}/bedgraph/ -p $CPG -o $RESULT/pre_CpG_amplicon_coverage.tsv
    fi

    # alter the column names to the sample it refers to 
    python $SCRIPTS/content_modifiers/change_header.py \
        -i $RESULT/pre_CpG_amplicon_coverage.tsv -o $RESULT/CpG_amplicon_coverage.tsv
    rm $RESULT/pre_CpG_amplicon_coverage.tsv

}


##############################################
# CpG_meth_perc()
#
# Calculate the CpG methylation coverage % across
# each CpG site present in the bedGraph coverage files
# and output into a tsv file.
#
# Globals:
#   SCRIPTS = dir containing all scripts
#   RESULT = dir to place returned file
#   SCRATCH = dir used to generate files
#   AMPLICON = bed file containing amplicon co-ordinates plus OT/OB status in a fourth column
#
# Returns:
#   a tsv containing CpG methylation percentage
#   across all samples (columns) across all sites
#   detailed in the given CpG sites of interest 
#   file (rows)
#
##############################################

CpG_meth_perc() {
  
    # CpG methylation percentage for all CpG sites within given amplicon ranges. Determine whther to filter for specific CpG sites or not 
    if [ -z $CPG ]; then 
        python $SCRIPTS/reshapers/cpg_meth_percent.py -a $AMPLICON \
            -b ${SCRATCH}/bedgraph/ -o $RESULT/pre_CpG_meth_percent.tsv
    else
        # CpG_sites.csv contains CpG sites which are found to be highly differntailly methylated between tumour and leukocytes
        python $SCRIPTS/reshapers/cpg_meth_percent.py -a $AMPLICON \
            -b ${SCRATCH}/bedgraph/ -p $CPG -o $RESULT/pre_CpG_meth_percent.tsv
    fi

    # alter column names in header to sample names
    python $SCRIPTS/content_modifiers/change_header.py \
        -i $RESULT/pre_CpG_meth_percent.tsv -o $RESULT/CpG_meth_percent.tsv
    rm $RESULT/pre_CpG_meth_percent.tsv

}


##########################################################


### EXECUTION ############################################

main() {

    echo "NOTE: initiating MethyCoverageParser $version"

    # construct the required directories if they are not present
    mkdir -p $SAMS $BEDS/coverage $BME $FASTQC ${SCRATCH}/bedgraph/ $SCRATCH/fastq_trimmed/ $RESULT $SCRATCH/fastq_filtered/

    # cut the amplicon file (OT/OB info in the fourth column), bedtools coverage behaves oddly if a fourth column is present 
    awk '{print $1 "\t" $2 "\t" $3}' $AMPLICON > $RESULT/AmpliconLocation.BED
    CUT_AMP=$RESULT/AmpliconLocation.BED

    # download FASTQ files if BASESPACE var not empty (; if --basespace arg given)
    if [ ! -z $BASESPACE ]; then
        download_FASTQ
    fi

    # BS-convert the genome if the $BS_CONVERT variable is not empty (; if --bs-convert option selected)
    if [ ! -z $BS_CONVERT ]; then
        bismark_genome_preparation --bowtie2 $REF 
    else
        echo "SKIPPING: bisulfite conversion of the genome" 
    fi
    
    # calculate number FASTQS, ensure there aren't an odd number and return list of FASTQS to be trimmed
    get_FASTQ_num

    # filter FASTQS by tile quality (; if --filter-by-tile argument given)
    if [ ! -z $BBMAP ]; then
        filter_by_tile
    else
        echo "SKIPPING: filterbytile"
    fi

    # trim fastq files provided the --no-trim flag has not been given
    if [ -z $TRIM ]; then
        trim_FASTQS 
    else 
        echo "SKIPPING: trimming of FASTQ files"
    fi
    
    # generate bismark SAM files provided --no-sams flag has not been given
    if [ -z $SAM_GENERATION ]; then
    	generate_SAMS 
    else
        echo "SKIPPING: generation of SAM files"
    fi
    
    # Combine QC data for all samples fastqc, trimmed fastq and sam files
    multiqc --force --ignore *_val_2_* $SCRATCH/fastq_trimmed/ $SCRATCH/fastqc/ $SCRATCH/alignment/sams/ \
            --outdir $SCRATCH/results/

    # only intiatate BME and bismark2bedgraph if --no-bme flag is not present
    if [ -z $METHY_EXTRACT ]; then
        generate_BME
    else
        echo "SKIPPING: bismark methylation extraction and bedGraph coverage file generation"
    fi

    # get coverage for all samples/FASTQs
    Coverage
    
    # get total meth/unmeth coverage for all CpG sites in each amplicon
    CpG_amplicon_cov
    
    # get CpG methylation percantages for ech CpG site
    CpG_meth_perc
}


main

##########################################################

