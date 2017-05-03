''' Converts hg19 positions to hg38 and converts all negative to positive strands

Created by David R
'''
import subprocess
import argparse
import os
import re

# GLOABL VAR, not good
probes = []


def strand_convert(f, out):
	''' convert negative strand to positive strand
	    and reformat so it can parsed into liftOver
	
	Args:
	    f: file containing positions of interest
	    out: output file
	
	Notes:

	    format of f should like the following;

	    probes    chr    pos    strand
	    CG1527    chr4   1452733    -
	'''
	f = open(f).readlines()
	lift_in = open(out, 'w')

	# strand conversion and liftOver input file prep
	for line in f[1:]:
		probe, chrom, pos, strand = line.rstrip("\n").split("\t")
		if strand == '-':
			pos = int(pos) + 1
		lift_in.write("{}:{}-{}\n".format(chrom, pos, pos))
		probes.append(probe)
	lift_in.close()


def reconfigure_output(liftOver_out, out): 
	''' Reconfigure the file format outputted from liftover
	    along with the probe value.

	Args:
	    liftOver_out: output of liftOver
	    out: output file name
	'''
	out = open(out, 'w')
	out.write("probe\tchr\tpositions\tposition")
	print(probes)
	for line, probe in zip(open(liftOver_out).readlines(), probes):
		print(probe)
		print(line)
		line = line.rstrip("\n")
		chrom = line.split(":")[0]
		pos = line.split("-")[-1]
		new = "\t".join([probe, chrom, pos])
		out.write(new+"\n")
	out.close()	


def clean_up():
	''' delete unwanted files
	'''
	for f in os.listdir():
		if re.search('liftOver_.*.bed.*', f) or f in ['lift_in.pos', 'converted.txt']:
			os.remove(f)


def cli():
	parser = argparse.ArgumentParser(description='Convert negative strand hg19 genomic locations to positive strand hg38 genomic locations')
	parser.add_argument('-s', '--sites', help='tab delimited fiel containing sites of interest')
	parser.add_argument('-l', '--liftover', help='path to liftOver')
	parser.add_argument('-c', '--chain', help='path to chain file')
	parser.add_argument('-o', '--out', help='output file')

	args = vars(parser.parse_args())
	
	strand_convert(args['sites'], 'lift_in.pos')
	subprocess.call([args['liftover'], '-positions', 'lift_in.pos', args['chain'], 'converted.txt', 'unMapped'])
	reconfigure_output('converted.txt', args['out'])

	clean_up()


if __name__ == '__main__':
	cli()




