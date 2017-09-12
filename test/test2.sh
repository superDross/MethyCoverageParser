#!/bin/bash

# define job name, email and working dir
#$ -N Test2.MethyCoverageParser

# inherit environment variables
#$ -V 

# specify walltime and RAM usage
#$ -l h_rt=71:00:00
#$ -l h_vmem=60G

# allows one to use module commands
. /etc/profile.d/modules.sh


# load the following modules upon login
module unload python
module load python/3.4.3 
module load roslin/bedtools/2.26.0
module load igmm/apps/FastQC/0.11.4
module load igmm/apps/TrimGalore/0.4.1
module load igmm/apps/bowtie/2.3.1
module load igmm/apps/bismark/0.16.3


# ensure reference genome and MethyCoverageParser paths has been parsed
if [ -z $1 ]; then
    echo -e "Reference genome must be parsed e.g.\n./MethyCoverageParser --test /path/to/genome/"
    exit 1
elif [ -z $2 ]; then 
    echo path to MethCoverage parser must be parse as second argument
    exit 1
fi


### VARS ################################
REF=$1 # path to reference genome
MCP=$2/ # path to the MethCoverageParser directory
CWD=$MCP/test/
SCRATCH=/exports/eddie/scratch/${USER}/
TEST1=${SCRATCH}/Test/TestRun/
TEST2=${SCRATCH}/Test/TestRunCD/
mkdir -p $TEST1 $TEST2
#########################################


### TEST2 #################################
$MCP/MethyCoverageParser.sh \
    --basespace ClaraFluidigm1 \
	--fastq $TEST2/fastq/ \
	--dir $TEST2 \
	--ref $REF \
	--amplicon $CWD/amplicons/AmpliconCD.bed \
    --non-directional \
    --fluidigm 


echo 'TESTING: TEST2'

if [[ `diff $TEST2/results/coverage.tsv $CWD/answers/Test2/coverage.tsv` != "" ]]
then
    echo "FAIL: different results detected for Test1 coverage.tsv"
else
    echo "PASS: coverage.tsv"
fi

if [[ `diff $TEST2/results/CpG_amplicon_coverage.tsv $CWD/answers/Test2/CpG_amplicon_coverage.tsv` != "" ]]
then
    echo "FAIL: CpG_amplicon_coverage.tsv"
else
    echo "PASS: CpG_amplicon_coverage.tsv"
fi

if [[ `diff $TEST2/results/CpG_meth_percent.tsv $CWD/answers/Test2/CpG_meth_percent.tsv` != "" ]]
then
    echo "FAIL: CpG_meth_percent.tsv"
else
    echo "PASS: CpG_meth_percent.tsv"
fi
#########################################


### CLEANUP #############################
# rm -r ${SCRATCH}/Test/
#########################################
