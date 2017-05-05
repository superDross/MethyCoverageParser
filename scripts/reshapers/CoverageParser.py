''' Reformat Bedtools coverage output derived from Bismark SAM file

created by Danny Laurents 
edited by David R: cli interface construction, redefined variables, docstring
'''
import os
import argparse


def coverage2dict(datadir):
        ''' Take the coverage information from coverage files in a given dir
            and store it in a dict.
            
        Args:
             datadir: dir containing coverage files

        Returns:
            a dictionry in the following format:

            data ={ (chr1, 127383, 637836): { Sample1: 100,
                                            Sample2: 150 }
                    (chr2, 28393, 7398523): { Sample1: 200,
                                              Sample2: 150 }
                  }
            
        '''
        # key = (chrom, start, end), item = dict(key = sample, item=CpG_covergae)
        data = {}

        for filename in os.listdir(datadir):
            if filename.endswith("coverage.txt"):
                fname = os.path.join(datadir, filename)
                with open(fname) as fin:
                    for line in fin:
                        chrom, start, end, cov, n, length, fraction = line.strip().split("\t")
                        key = (chrom, start, end)
                        if key not in data:
                            data[key] = {}
                        data[key][filename] = cov
        return data


def reformat_coverage(data, fout):
        ''' Take the dict from coverage2dict() and format into a 
            a tsv file where the columns are the sample, rows are the 
            amplicons start and end position and fields contain contain
            CpG coverage for a specific sample at a amplicon.

        Args:
            data: coverage2dict() dictionarg
            fout: output file
        '''
        fout = open(fout, 'w')
        printheader = True
        for (chrom, start, end) in data:
            if printheader:
                fout.write('\t\t')
                for sam in data[(chrom, start, end)]:
                    fout.write('\t' + sam)
                fout.write('\n')
                printheader = False
            fout.write(chrom + '\t' + start + '\t' + end)
            for sam in data[(chrom, start, end)]:
                fout.write('\t' + data[(chrom, start, end)][sam])
            fout.write('\n')


def cli():
        parser = argparse.ArgumentParser(description="parse CpG coverage data into a data frame like format and output as a tsv")
        parser.add_argument('-d', '--dir', help="directory containing the coverage files (bedtools coverage output)")
        parser.add_argument('-o', '--out', help="output file")

        args = vars(parser.parse_args())

        data = coverage2dict(args['dir'])
        reformat_coverage(data, args['out'])


if __name__ == '__main__':
        cli()
