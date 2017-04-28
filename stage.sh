#!/bin/bash

################################################################################################
# stage.sh
# 
# Data staging job script that copies a directory from one place to another with rsync
#
# USAGE:
#     echo "stage.sh --out ~/scratch/ --dirs ~/file1.txt ~/reference/" | qsub -q staging
#
# NOTES:
#     Job will restart from where it left off if it runs out of time 
#     (so setting an accurate hard runtime limit is less important)
################################################################################################

#$ -cwd
#$ -N stagein
#  Runtime limit - set a sensible value here
#$ -l h_rt=01:00:00 

# Make job resubmit if it runs out of time
#$ -r yes
#$ -notify
trap 'exit 99' sigusr1 sigusr2 sigterm

### ARGUMENT PARSER ############################
# directery to copy files/directories to 
if [ "$1" = "-o" ] || [ "$1" = "--out" ]; then
   DESTINATION=$2
else
   echo "--out must be first argument given"
   exit 0
fi

# array of directories/files to copy to out
if [ "$3" = "-d" ] || [ "$3" = "--dirs" ]; then
     DIRS=`echo "${@:4}" | xargs`
else
   echo "--dir must be the second argument given"
   exit 0
fi
###################################################


# Do the copy with lftp without password assuming ssh keys have been setup on DataStore
rsync -r $DIRS $DESTINATION
