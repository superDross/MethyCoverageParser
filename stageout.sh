#!/bin/bash

################################################################################################
#
# qsub -q staging stagout.sh /some/file/or/dir/ /dir/to/copy/to/
#
# data staging job script that copies a directory from Scratch to Datastore with rsync
# 
#   Job will restart from where it left off if it runs out of time 
#   (so setting an accurate hard runtime limit is less important)
################################################################################################

#$ -cwd
#$ -N stagein
#  Runtime limit - set a sensible value here
#$ -l h_rt=01:00:00 

# Make job resubmit if it runs out of time
#$ -r yes
#$ -notify
trap 'exit 99' sigusr1 sigusr2 sigterm


# SOURCE should something in scratch
SOURCE=${1}/

# DESTINATION should be in Datastore
DESTINATION=${2}/

# Do the copy with rsync
rsync -r $SOURCE $DESTINATION
