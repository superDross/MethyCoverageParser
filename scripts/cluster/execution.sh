#!/bin/bash

# define job name, email and working dir
#$ -N TestEG.BS_Seq_Analysis
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

DATASTORE=/exports/igmm/datastore/aitman-lab/dross11/	
SCRATCH=/exports/eddie/scratch/dross11/
HOME=/home/dross11/

$HOME/MethyCoverageParser/MethyCoverageParser.sh \
	--fastq $SCRATCH/fastq/ \
	--dir $SCRATCH \
	--ref $SCRATCH/human/hg38-1000G/ \
	--amplicon $SCRATCH/FluidigmAmplicons/AmpliconDaveParry.BED \
    --cpg $SCRATCH/FluidigmAmplicons/CpG_locations_hg38_strand_converted.txt
