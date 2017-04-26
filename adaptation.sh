#!/bin/sh

# define job name, email and working dir
#$ -N Sophie.BS_Seq_Analysis_Test
#$ -M dross11@staffmail.ed.ac.uk
#$ -wd /exports/eddie/scratch/dross11/

# email me after, before and ending
#$ -m a
#$ -m b
#$ -m e

# place the standard error and out into the specified dir
#$ -e /home/dross11/standerrout/
#$ -o /home/dross11/standerrout/

# inherit environment variables
#$ -V 

# specify walltime and RAM usage
#$ -l h_rt=71:00:00
#$ -l h_vmem=60G

# TODO: ARGS that should be parsed
#
#	FASTQ_DIR
#	SCRATCH
#	SAMPLE_NAMES
#	BS_REF
#	OUT_DIR (to rsync to at the end)
#	AMPLICON_BED_FILE (fluidigm amplicon start and end sites)
#	CpG_SITES (containing CpG sites of interest)


# define paths
SCRATCH=/exports/eddie/scratch/dross11
SCRIPTS=/home/dross11/scripts/
REF=$SCRATCH/human/hg38-1000G/
FASTQ_DIR=$SCRATCH/fastq/
PRIMERS=$SCRATCH/FluidigmAmplicons/
BAMS=$SCRATCH/alignment/bams/
SAMS=$SCRATCH/alignment/sams/
BEDS=$SCRATCH/BED_files/
BME=$SCRATCH/BME/

### I: SAM FILE GENERATION

# get sample names from fastq filenames
SAM_LIST=`find $FASTQ_DIR/ -name *gz | awk -F "/" '{print $NF}' | awk -F "_" '{print $2}' | uniq | xargs`

# BS_convert the Genome ONLY HAS TO BE PERFORMED ONCE
bismark_genome_preparation --bowtie2 $REF 

# Quality and adpater trimming of all fastqs. CS1rc and CS2rc need to be trimmed off, this explains the high C % per base sequence count at the end of the read.
FASTQS=`find $FASTQ_DIR/*/* -name '*.fastq.gz'`
echo $FASTQS | xargs -n2 trim_galore --paired \
				     --path_to_cutadapt /exports/eddie3_homes_local/dross11/.local/bin/cutadapt \
				     --output_dir $SCRATCH/fastq_trimmed/ \
				     --adapter AGACCAAGTCTCTGCTACCGTA \
				     --adapter2 TGTAGAACCATGTCGTCAGTGT \
				     --trim1 

# generate fastqc reports
fastqc $SCRATCH/fastq_trimmed/*val*gz -o $SCRATCH/fastqc/

# generate list of post-trimmed Read 1 and Read 2 fastq files (not sure if adding the comma is neccessary.
R1=`find $SCRATCH/fastq_trimmed/ -name *_R1_*val*fq.gz | sort | xargs | sed 's/ /,/g'`
R2=`find $SCRATCH/fastq_trimmed/ -name *_R2_*val*fq.gz | sort | xargs | sed 's/ /,/g'`

# Align to BS-converted genome and convert bam to sam files. Bowtie2 for >50bp reads.
bismark --bowtie2 -1 $R1 -2 $R2 --sam -o $SAMS/ $REF 


### II: CpG METHYLATION COVERAGE

# determines which read pairs contain a methylated CpG and parse the read start and end positions into a BED file
find $SAMS -name *sam | xargs -I {} python2 ~/scripts/Duncan.py {} {}.bed
find $SAMS -name *bed -print0 | xargs -r0 mv -t $BEDS

# get the coverage per amplicon for the given intervals.
for bed in `find $BEDS -name *bed | xargs`; do
    bedtools coverage -a $PRIMERS/AmpliconLocation.BED -b $bed > ${bed}_coverage.txt
    mv ${bed}_coverage.txt $BEDS/coverage/
done

# give the dir containing the coverage text files
python $SCRIPTS/CoverageParse.py $BEDS/coverage/ $SCRATCH/meth_coverage.tsv

### III: CpG METHYLATION PER AMPLICON

# extract the methylation call for every C and write out its position and % methylated at said position. Report will allow you to work out methylation % in CpG, CHG & CHG contexts.
bismark_methylation_extractor -p -o $BME/ `find $SAMS -name *sam | xargs`

# Duncans perl script takes BME results and creates 2 BED files; one for meth CpG and another for unmeth CpG sites
find $BME -name "CpG*txt" | xargs -I {} perl -w ~/scripts/Duncan.pl {} 
find $BME -name "CpG*BED" -print0 | xargs -r0 mv -t ${SCRATCH}/BME_BED

# get the coverage for methylated CpG 
for bed in `find ${SCRATCH}/BME_BED -name CpG*BED | xargs`; do
    bedtools coverage -a $PRIMERS/AmpliconLocation.BED -b $bed > ${bed}_coverage.txt
    mv ${bed}_coverage.txt ${SCRATCH}/BME_BED/coverage/
done

# DavidParry.pl and AmpliconLocationDP.BED
 perl -w $SCRIPTS/DavidParry.pl $PRIMERS/AmpliconDaveParry.BED ${SCRATCH}/BME_BED/coverage/ > ${SCRATCH}/CpG_meth_coverage_amplicon.tsv

## IV: CpG METHYLATION PER SITE

# bismark2bedgraph needed to produce the coverage files along with the bedgraph files
for sam in $SAM_LIST; do
    cpg_pairs=`find $BME -name "CpG*_${sam}_*txt" | xargs`
    bismark2bedGraph $cpg_pairs --dir ${SCRATCH}/BME_bedgraph -o ${sam}.bedGraph
    gunzip ${SCRATCH}/BME_bedgraph/*.gz
done 

# TODO: automate the chromosome position conversion to hg19 -> hg38 and negative strand to positive (pos +1)

# construct
## CpG_sites.csv contains CpG sites which are found to be highly differntailly methylated between tumour and leukocytes
python3 $SCRIPTS/Sophie.py ${SCRATCH}/BME_bedgraph/ ${SCRATCH}/FluidigmAmplicons/CpG_sites.csv ${SCRATCH}/CpG_meth_coverage_site.tsv


