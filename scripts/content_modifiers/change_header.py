# Created by David R
import numpy as np 
import argparse


def main(filename, output):
    ''' Change the name of the samples in the header of the
	inputed files (MethylCoverageParser.sh output) to 
	the most unique part of the name. 

    Args:
	filename: input file
	output: name of output file

    Notes:
        required as Edinburgh Genomics don't use the default
        naming conventions for the their FASTQ files. As we
        will likely recieve data from both EG and the CG MiSeq
        we need something that automates the sample name 
        extraction from the FASTQ file names reagardless of
        naming conventionm used. The default naming convention:

            SampleName_SampleID_LaneNum_ReadNum_001.fq
    '''	
    output = open(output, 'w')
    count = 0 # line count
    with open(filename) as f:
        for line in f:
            # if header
            if count == 0:
                line = line.rstrip("\n").split("\t")
                # get all sample names from header, split and turn into an array
                samples = np.array([x.split("_") for x in line if "_" in x])
                remain = [x for x in line if "_" not in x] 
                
                # sliding window, find column in which has unequal values and assign this as the sample names
                # potentially problematic if the read number comes before the sample_name
                for n in range(0, len(samples[0])):
                    if not np.all(samples[0,n] == samples[:,n], axis=0):
                        new_sample_names = samples[:,n]
                        new_header = remain + list(new_sample_names)
                        output.write("\t".join(new_header) + "\n")
                        break

            else:
                output.write(line)

            count +=1

    output.close()


def cli():
	parser = argparse.ArgumentParser(description="change the name of the samples in the header of the inputed file")
	parser.add_argument('-i', '--in', help="input file")
	parser.add_argument('-o', '--out', help="output file")

	args = vars(parser.parse_args())

	main(args['in'], args['out'])


if __name__ == '__main__':
	cli()
