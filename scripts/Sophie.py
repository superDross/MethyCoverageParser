'''Python script to parse individual CpG percentages from Bismark bedgrpah coverage files.

Created by Sophie M and Danny L
Edited by David R
'''
import argparse
from os import listdir
from os.path import isfile, join


def position_dict(cov_files, minCov=1000):
	''' Construct a nested dict whereby the key is a genomic position 
	    and the items is a dict of all samples with its own bedgraph 
	    coverage file and their corresponding CpG methylation % for said
	    position.
	
	Args:
	    cov_files: list of bedgraph coverage files
	    minCov: minimum coverage filter for the position to be included in the returned dict

	Returns:
	    e.g. { '1:162726': { sample1: 50%, sample2: 47% },
		   '2:748378': { sample1: 89%, sample2: 23% }
		   }
	'''
	# key = chr:pos, item = dict(key = sample, item = meth%)
	pos_meth_dict = {}

	for cov_file in cov_files:
		# get sample name from file path
		sample = cov_file.split("/")[-1].split(".")[0]
		cov_file = open(cov_file, "r")
		
		for line in cov_file:
			if not line.startswith("track type"):
				# chr6	77462129	77462129	39.9770904925544	349	524
				chrom, pos_start, pos_end, meth_percent, c_cov, tri_cov = line.rstrip("\n").split("\t")
				chr_pos = str(chrom + "_" + pos_start)
				cov = int(c_cov+tri_cov)

				# filter for those that pass minCov
				if cov < minCov:
					continue

				# produce subdict
				sample_dict = {}
				sample_dict[sample] = meth_percent
				
				# update top level dict with subdict as an item
				if chr_pos in pos_meth_dict:
					pos_meth_dict[chr_pos].update(sample_dict)
				else: 
					pos_meth_dict[chr_pos]= sample_dict
		cov_file.close()

	return pos_meth_dict



def meth_percentage_file(sam_list, pos_meth_dict, soi, out):
	''' Create a tsv file containing methylation percentage
	    across all sites of interest and all samples.
	
	Args:
	    sam_list: list of samples
	    pos_meth_dict: positin methylation dictionary created via position_dict()
	    soi: tab delimitated file describing sites of interest consisting of probe\tchr\tposition
	    out: file to output to
	'''
	# get file names and store in a list and use to create the header for the output file
	filesString = "\t".join(sam_list)
	out.write("probe\tchromosome\tposition\t" + str(filesString) + "\n")

	for chr_pos in pos_meth_dict:
		chrom, pos = chr_pos.split("_")
		if chr_pos in soi.keys():
			probe = soi.get(chr_pos)
			out.write(str(probe) + "\t" + str(chrom) + "\t" + str(pos))
			for sam in sam_list:
				subdict = pos_meth_dict[chr_pos]
				if sam in subdict:
					out.write("\t" + str(subdict[sam]))
				else:
					out.write("\tNA")
			out.write("\n")
	out.close()


def get_parser():
	parser = argparse.ArgumentParser(description="Parses bedgraph coverage files to create a dataframe of samples CpG methylation % at given genomic positions of interest")
	parser.add_argument('-b', '--bedgraph_dir', help='dir containing bedgraph coverage files')
	parser.add_argument('-p', '--positions', help='file containing positions of interest')
	parser.add_argument('-o', '--output', help='output file name')
	return parser


def cli():
	parser = get_parser()
	args = vars(parser.parse_args())

	# define bedfile directory
	bedfilesdirectory = args['bedgraph_dir']

	# key = CpG sites/genome-coordinates of interest, item = probe
	soi = {x.split("\t")[1]+"_"+x.split("\t")[2]: x.split('\t')[0] for x in open(args['positions']).readlines()[1:]}

	# Create an output file
	output_file = open(args['output'], "w")

	# read only coverage files and store into a list
	cov_files = [bedfilesdirectory+f for f in listdir(bedfilesdirectory) 
		     if isfile(join(bedfilesdirectory, f)) and f.endswith('cov')]

	sam_list = [x.split("/")[-1].split(".")[0] for x in cov_files]


	pos_meth_dict = position_dict(cov_files)
	meth_percentage_file(sam_list, pos_meth_dict, soi, output_file)


if __name__ == '__main__':
	cli()

