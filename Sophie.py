'''Python script to parse individual CpG percentages from 'Bismark --bedgraph' Output

arg1: directory containing the bedgraph coverage files
arg2: CpG sites of interest to filter the bedgraph coverage files for
arg3: output file

Created by Sophie and Danny
Edited by David R
'''
#import os module
import os, sys
from os import listdir
from os.path import isfile, join
import re

#define bedfile directory
bedfilesdirectory = sys.argv[1]

# key = CpG sites of interest, item = probe
soi = {x.split("\t")[1]+"_"+x.split("\t")[2]: x.split('\t')[0] for x in open(sys.argv[2]).readlines()[1:]}

#Create an output file
outputfile = open(sys.argv[3], "w")

#Make an empty dictionary. The keys to this dictionary will be chr_pos
# key = chr:pos, item = dict(key = sample, item = meth%)
dannydict = {}
minCov = 1000

#read only files into a list
onlyfiles = [f for f in listdir(bedfilesdirectory) if isfile(join(bedfilesdirectory, f))]
#Loop over a directory that contains the bedfiles
for bedfile in onlyfiles:
	if re.search(r".cov", bedfile):
		#save in a variable called subdictkey
		subdictkey = bedfile.rstrip(".bedgraph.gz.bismark.cov")
		#Open file and save it in a variable
		bedfile = join(bedfilesdirectory, bedfile)
		bedfileopen = open(bedfile, "r")
		#make a variable name from the filename, this variable name will be used as the sub-dictionary key
		for line in bedfileopen:
			if not line.startswith("track type"):
				#chr6	77462129	77462129	39.9770904925544	349	524
				#do rstrip to remove newline
				strippedline = line.rstrip("\n")
				#do split by tab to separate into a list, save into a variable called dannylist
				dannylist = strippedline.split("\t")
				#make a variable that contains chromosome + position, called chr_pos
				chr_pos = str(dannylist[0] + "_" + dannylist[1])
				cov = int(dannylist[4]+dannylist[5])
				# Filter out anything that doensn't meet the min coverage filter
				if cov < minCov:
					continue
				#make a dictionary (will be the subdictionary)
				subdict = {}
				# key = sample, item = meth% for a position
				subdict[subdictkey] = dannylist[3]
				#dannydict[chr_pos] = {}
				if chr_pos in dannydict:
					# key = chr:pos, item = dict(key = sample, item = meth%)
					dannydict[chr_pos].update(subdict)
				else: 
					dannydict[chr_pos]= subdict
		bedfileopen.close()


listfiles = []
for file in onlyfiles:
	if re.search(r"cov", file):
		files = file.rstrip(".bedgraph.gz.bismark.cov")
		listfiles.append(files)
	
filesString = "\t".join(listfiles)
outputfile.write("probe\tchromosome\tposition\t" + str(filesString) + "\n")
for key in dannydict:
	# if the position is in a sit of interest
	if key in soi.keys():
		dannylist = key.split("_")
		chr = dannylist[0]
		pos = dannylist[1]
		probe = soi.get(key)
		outputfile.write(str(probe) + "\t" + str(chr) + "\t" + str(pos))
		for file in listfiles:
			dannykey = file.rstrip(".bedgraph.gz.bismark.cov")
			subdict = dannydict[key]
			if dannykey in subdict:
				outputfile.write("\t" + str(subdict[dannykey]))
			else:
				outputfile.write("\tNA")
		outputfile.write("\n")
outputfile.close()
	


