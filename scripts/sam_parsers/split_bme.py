import os
import argparse


def methylation_split(bme_dir, out_dir):
    ''' Split all BME outputs into methylated and unmethylated
        files.

    Args:
        bme_dir: directory containing bme output files
        out_dir: directory to store split files
    '''
    cpg_files = [f for f in os.listdir(bme_dir) 
                 if f.startswith("CpG") and not f.endswith("meth.txt")]

    for cpg_file in cpg_files:
        meth = open(out_dir+cpg_file+"_bismark_CpG_meth.txt", 'w')
        unmeth = open(out_dir+cpg_file+"_bismark_CpG_unmeth.txt", 'w')
        with open(bme_dir+cpg_file) as f:
            header = next(f)
            meth.write(header)
            unmeth.write(header)
            for line in f:
                seq_id, meth_state, chrom, pos, meth_call = line.rstrip("\n").split("\t")
                if meth_call == "Z":
                    meth.write(line)
                elif meth_call == "z":
                    unmeth.write(line)
            meth.close()
            unmeth.close()


def cli():
    parser = argparse.ArgumentParser(description='Split all BME outputs into methylated and unmethylated files')
    parser.add_argument('-i', '--in', help='directory containing BME output files.')
    parser.add_argument('-o', '--out', help='directory to store output')
    
    args = vars(parser.parse_args())
    methylation_split(args['in'], args['out'])


if __name__ == '__main__':
    cli()
