#!/bin/sh
# original pipeline script by Danny Laurent

#$ -M s1442429@sms.ed.ac.uk
#$ -m a 
#$ -m b 
#$ -m e 
#$ -cwd
#$ -l h_rt=10:00:00
#$ -l h_vmem=16G

#The Pipeline of RatBS Methylation Analysis
#The script is written by Danny Laurent
#The pipeline is designed by Dr. Duncan Sproul

#Loading the required modules first
. /etc/profile.d/modules.sh
MODULEPATH=$MODULEPATH:/exports/igmm/software/etc/el7/modules
module load igmm/apps/bismark/0.14.5 
module load igmm/apps/bowtie/1.1.2 
module load igmm/apps/BEDTools/2.23.0
module load igmm/apps/python/2.7.10
module load igmm/apps/samtools/1.3
module load igmm/libs/ncurses/6.0

#The first step is to do in silico bisulphite conversion of Rat Genome rn5
#bismmark_genome_preparation --bowtie1 /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/Genome Folder
#This command above had been run in advance, therefore we can ignore it for now and just use the existing bisulphite converted genome

#Next step is to do bismark alignment
#Change directory to the location of the FastQ files for each library and execute the command. -o will direct the output to a folder called BismarkResult
cd /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/FastQ

Mates1=`ls *_1*fastq | sed ':a;N;$!ba;s/\n/,/g'`
Mates2=`ls *_2*fastq | sed ':a;N;$!ba;s/\n/,/g'`
bismark --bowtie1 --sam -o /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BismarkResult /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/GenomeFolder -1 $Mates1 -2 $Mates2

#Bismark command will produce SAM files by default (contains all alignment plus methylation call strings) and text files (contains alignment and methylation summary)
#An important thing to do here is to move all the files with .sam ending from folder BismarkResult to a new folder called BismarkSAM
mv /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BismarkResult/*sam /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BismarkSAM

#I will change directory to where the SAMfiles are
cd /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BismarkSAM

#Next, I need to setup a loop to repeat Duncan's python script over all of the SAM files in that folder
#Duncan's python script uses python and requires an inputfile and an outputfilename to be specified to work properly

for samfile in *sam
do
	outputfile=$samfile".BED"
	python /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/code/Duncan.py $samfile $outputfile
done

#Move all the BED files into a new directory called DuncanPythonBED
mv /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BismarkSAM/*BED /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/DuncanPythonBED/

#I need to change directory to the place

cd /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/DuncanPythonBED

#Use the coverage command by bedtools to obtain the coverage
for BEDfile in *BED
do
	outputcoverage=$BEDfile"_coverage.txt"
	bedtools coverage -a $BEDfile -b /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/AmpliconLocation/AmpliconLocation.BED > /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/CoverageFiles/$outputcoverage
done

#The next part of the analysis is to obtain total methylated and total unmethylated amplicon
#To do this, I need to run bismark methylation extractor command to the SAM files
#The SAM files are in the BismarkSAM directory, so I need to change directory there
cd /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BismarkSAM

#I create a list of space separated SAM files in a variable called SAMfilelist
SAMfilelist=`ls | sed ':a;N;$!ba;s/\n/ /g'`

#I run bismark methylation extractor with paired end option and direct the output to /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BMEResult
bismark_methylation_extractor -p -o /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BMEResult $SAMfilelist

#The outputs of the bismark methylation extractor are CpG, CHG and CHH text files, but we only need CpG text files for this application, so I need to move the CpG text files to another directory called BMECpG
mv /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BMEResult/CpG* /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BMECpG/

#Then I need to run Duncan Sproul's perl script
#But before I do that, I need to change directory to the BMECpG
cd /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BMECpG

#Then I can run the command
for CpGFile in CpG*txt
do
	perl -w /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/code/Duncan.pl $CpGFile
done

#Then I can move the BEDfiles to a folder called DuncanPerlBED /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/DuncanPerlBED
mv /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/BMECpG/*BED /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/DuncanPerlBED

#Finally I process the methylated and unmethylated BED files with bedtools coverage command to obtain total methylated and total unmethylated amplicons
#I change directory to where the bedfiles are /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/DuncanPerlBED
cd /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/DuncanPerlBED

#I make a loop to do the coverage command
for beds in *BED
do
	fileoutput=$beds"_output.txt"
	bedtools coverage -a $beds -b /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/AmpliconLocation/AmpliconLocation.BED > /exports/igmm/datastore/aitman-lab/s1442429/DannyPhD/MethylationAnalysis/RatBS2/MethylationResult/$fileoutput
done
