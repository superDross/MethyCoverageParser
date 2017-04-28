#!/bin/bash

# TODO: script something which copies over FASTQ, REF, AMPLICON_BED and CPG over to scratch
# TODO: script something which copies all the data over to OUT
# TODO: place all bisulphite stages into functions
# TODO: figure out a way to add option --no-amplicon-methylation, --bs-genome and --version
# TODO: rename py, pl files to a more logical name
# TODO: increase readability of python files
# TODO: automate the chromosome position conversion to hg19 -> hg38 and negative strand to positive (pos +1)


## HELP PAGE
if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    echo -e "usage:\t[-h] [-f DIR] [-d DIR] [-r DIR] [-a FILE] [-c FILE] [-o DIR]\n"
    echo -e "Calculate the total CpG coverage, mean CpG coverage per amplicon & CpG coverage per given CpG site from a given set of FASTQ files\n"
    echo -e "required arguments:"
    echo -e "-f, --fastq\tpath containing dirs with fastq files"
    echo -e "-d, --dir\tdirectory to perform commands (SCRATCH)"
    echo -e "-r, --ref\tdirectory containing BS-converted genome"
    echo -e "-a, --amplicon\tBED file containing amplicon start and end coordinates"
    echo -e "-c, --cpg\tfile containing CpG sites of interest"    
    echo -e "-o, --out\tdirectory to output all the results"
    exit 0
fi



## ARGUMENT PARSER
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in 
      -f|--fastq) FASTQ_DIR="$2"; shift ;;
      -d|--dir) SCRATCH="$2"; shift ;;
      -r|--ref) REF="$2"; shift ;;
      -o|--out) OUT="$2"; shift ;;
      -a|--amplicon) AMPLICON="$2"; shift ;;
      -c|--cpg) CPG="$2"; shift ;;
      *) echo "Unknown argument:\t$arg"; exit 0 ;;
    esac

    shift
done

# make all arguments compulsory
if [ -z $FASTQ_DIR ]; then
    echo "--fastq argument is required"
    exit 1
elif [ -z $SCRATCH ]; then
    echo "--dir argument is required"
    exit 1 
elif [ -z $REF ]; then
    echo "--ref argument is required"
    exit 1 
elif [ -z $OUT ]; then
    echo "--out argument is required"
    exit 1 
elif [ -z $AMPLICON ]; then
    echo "--amplicon argument is required"
    exit 1 
elif [ -z $CPG ]; then
    echo "--cpg argument is required"
    exit 1 
fi



## PATHS
# SCRATCH=/exports/eddie/scratch/dross11
SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/ # the absolute path of the dir in which this script is within
# REF=$SCRATCH/human/hg38-1000G/
# FASTQ_DIR=$SCRATCH/fastq/
# CPG={SCRATCH}/FluidigmAmplicons/CpG_sites.csv 
SAMS=$SCRATCH/alignment/sams/
BEDS=$SCRATCH/BED_files/
BME=$SCRATCH/BME/
FASTQC=$SCRATCH/fastqc/
RESULT=$SCRATCH/results/

# construct the required directories if they are not present
mkdir -p $SAMS $BEDS/coverage $BME $FASTQC ${SCRATCH}/BME_BED/coverage/ ${SCRATCH}/BME_bedgraph/ $SCRATCH/fastq_trimmed/ $RESULT

# cut the amplicon file (in case it has OT/OB info in the fourth column)
awk '{print $1 "\t" $2 "\t" $3}' $AMPLICON > $RESULT/AmpliconLocation.BED
CUT_AMP=$RESULT/AmpliconLocation.BED


### I: SAM FILE GENERATION

# get sample names from fastq filenames
SAM_LIST=`find $FASTQ_DIR/ -name *gz | awk -F "/" '{print $NF}' | awk -F "_" '{print $2}' | uniq | xargs`

# BS_convert the Genome ONLY HAS TO BE PERFORMED ONCE
# bismark_genome_preparation --bowtie2 $REF 

## Quality and adpater trimming of all fastqs. CS1rc and CS2rc need to be trimmed off, this explains the high C % per base sequence count at the end of the read.
#FASTQS=`find $FASTQ_DIR/*/* -name '*.fastq.gz'`
#echo $FASTQS | xargs -n2 trim_galore --paired \
#				     --path_to_cutadapt /exports/eddie3_homes_local/dross11/.local/bin/cutadapt \
#				     --output_dir $SCRATCH/fastq_trimmed/ \
#				     --adapter AGACCAAGTCTCTGCTACCGTA \
#				     --adapter2 TGTAGAACCATGTCGTCAGTGT \
#				     --trim1 
#
## generate fastqc reports
#fastqc $SCRATCH/fastq_trimmed/*val*gz -o $FASTQC
#
## generate list of post-trimmed Read 1 and Read 2 fastq files (not sure if adding the comma is neccessary.
#R1=`find $SCRATCH/fastq_trimmed/ -name *_R1_*val*fq.gz | sort | xargs | sed 's/ /,/g'`
#R2=`find $SCRATCH/fastq_trimmed/ -name *_R2_*val*fq.gz | sort | xargs | sed 's/ /,/g'`
#
## Align to BS-converted genome and convert bam to sam files. Bowtie2 for >50bp reads.
#bismark --bowtie2 -1 $R1 -2 $R2 --sam -o $SAMS/ $REF 
#
#
#### II: CpG METHYLATION COVERAGE
#
## determines which read pairs contain a methylated CpG and parse the read start and end positions into a BED file
#find $SAMS -name *sam | xargs -I {} python2 $SCRIPTS/Duncan.py {} {}.bed
#find $SAMS -name *bed -print0 | xargs -r0 mv -t $BEDS
#
## get the coverage per amplicon for the given intervals.
#for bed in `find $BEDS -name *bed | xargs`; do
#    bedtools coverage -a $CUT_AMP -b $bed > ${bed}_coverage.txt
#    mv ${bed}_coverage.txt $BEDS/coverage/
#done
#
## give the dir containing the coverage text files
#python $SCRIPTS/CoverageParse.py $BEDS/coverage/ $RESULT/CpG_coverage.tsv
#
#### III: CpG METHYLATION PER AMPLICON
#
## extract the methylation call for every C and write out its position and % methylated at said position. Report will allow you to work out methylation % in CpG, CHG & CHG contexts.
#bismark_methylation_extractor -p -o $BME/ `find $SAMS -name *sam | xargs`
#
## Duncans perl script takes BME results and creates 2 BED files; one for meth CpG and another for unmeth CpG sites
#find $BME -name "CpG*txt" | xargs -I {} perl -w $SCRIPTS/Duncan.pl {} 
#find $BME -name "CpG*BED" -print0 | xargs -r0 mv -t ${SCRATCH}/BME_BED
#
## get the coverage for methylated CpG 
#for bed in `find ${SCRATCH}/BME_BED -name CpG*BED | xargs`; do
#    bedtools coverage -a $CUT_AMP -b $bed > ${bed}_coverage.txt
#    mv ${bed}_coverage.txt ${SCRATCH}/BME_BED/coverage/
#done
#
## DavidParry.pl and AmpliconLocationDP.BED
#perl -w $SCRIPTS/DavidParry.pl $AMPLICON ${SCRATCH}/BME_BED/coverage/ > $RESULT/CpG_meth_coverage_amplicon.tsv
#
#### IV: CpG METHYLATION PER SITE
#
## bismark2bedgraph needed to produce the coverage files along with the bedgraph files
#for sam in $SAM_LIST; do
#    cpg_pairs=`find $BME -name "CpG*_${sam}_*txt" | xargs`
#    bismark2bedGraph $cpg_pairs --dir ${SCRATCH}/BME_bedgraph -o ${sam}.bedGraph
#    gunzip ${SCRATCH}/BME_bedgraph/*.gz
#done 

## CpG_sites.csv contains CpG sites which are found to be highly differntailly methylated between tumour and leukocytes
python3 $SCRIPTS/Sophie.py ${SCRATCH}/BME_bedgraph/ $CPG $RESULT/CpG_meth_coverage_site.tsv

# copy over
#rsync -r $SCRATCH $OUT
