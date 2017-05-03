import argparse

def main(filename, n, output):
	''' Change the name of the samples in the header of the
	    inputted file by a given number of delimitions of '_'

	Args:
	    filename: input file
	    n: number of delimitions of '_'
	    output: name of output file
	
	Example:
	    lets assume the sample names in the header of a tsv file
	    looks like 'xxx_s1_xxx\txxx_s2_xxx\txxx_s3_xxx'
	    
	    the command main(in.tsv, 2, out.tsv) will alter the output 
	    files header to 's1\ts2\ts3'
	'''
	output = open(output, 'w')
	count = 0
	with open(filename) as f:
		for line in f:
			if count == 0:
				header = [x.split("_")[int(n)-1] if "_" in x else x for x in line.rstrip("\n").split("\t")]
				new_header = "\t".join(header) + "\n"
				output.write(new_header)
				count += 1
			else:
				output.write(line)
				count += 1
	output.close()

def cli():
	parser = argparse.ArgumentParser(description="change the name of the samples in the header of the inputed file by a given number of delimitions of '_'")
	parser.add_argument('-i', '--in', help="input file")
	parser.add_argument('-n', '--number', help="delimiter number of '_' to take the sample name from")
	parser.add_argument('-o', '--out', help="output file")

	args = vars(parser.parse_args())

	main(args['in'], args['number'], args['out'])


if __name__ == '__main__':
	cli()
