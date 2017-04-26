#!/bin/bash

################################################################################################
#
# qsub -q staging stagein.sh /some/file/or/dir/ 
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


SOURCE=${1}/
DESTINATION=/exports/eddie/scratch/dross11/

# Destination path on Eddie. It should be on Eddie fast HPC disk, starting with one of:
# /exports/csce/eddie, /exports/chss/eddie, /exports/cmvm/eddie, /exports/igmm/eddie or /exports/eddie/scratch, 

# Do the copy with lftp without password assuming ssh keys have been setup on DataStore
rsync -r $SOURCE $DESTINATION
