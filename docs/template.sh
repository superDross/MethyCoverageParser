#!/bin/bash

# define job name, email and working dir
#$ -N BS_Seq_Analysis
#$ -M fiona.semple@igmm.ed.ac.uk
#$ -wd /exports/eddie/scratch/user/

# email me after, before and ending
#$ -m a
#$ -m b
#$ -m e

# place the standard error and out into the specified dir
#$ -e /home/user/
#$ -o /home/user/

# inherit environment variables
#$ -V 

# specify walltime and RAM usage
#$ -l h_rt=71:00:00
#$ -l h_vmem=60G


# allows one to use the module commands
. /etc/profile.d/modules.sh

# load the following modules
module unload python
module load python/3.4.3 
module load roslin/bedtools/2.26.0
module load igmm/apps/TrimGalore/0.4.1
module load igmm/apps/bowtie/2.3.1
module load igmm/apps/bismark/0.16.3
module load igmm/apps/FastQC/0.11.4
module load igmm/apps/samtools/1.3
# the below two modules may be required to run samtools correctly
module load igmm/libs/htslib/1.3
module load igmm/libs/ncurses/6.0

# cutadapt and multiQC needs to be downloaded seperately in your user space. 
# execute the below commands to install them. They only have to be executed once.
# pip3 install --user cutadapt
# pip3 install --user multiqc


## EVERYTHING BELOW THIS WILL NEED TO BE EDITED FOR EACH SPECIFIC ANALYSIS
# environment variables; essesntially shorthands for directory paths
DATASTORE=/exports/igmm/datastore/aitman-lab/user/	
USER=/exports/eddie/scratch/user/
HOME=/home/user/

# MethyCoverageParser command
$HOME/MethyCoverageParser/MethyCoverageParser.sh \
	--fastq $USER/fastq/ \
	--dir $USER \
	--ref /exports/eddie/scratch/user/hg38/ \
	--amplicon $USER/FluidigmAmplicons/Fiona2Amplicon.txt \
    --non-directional \
    --no-trim \
    --fluidigm 
