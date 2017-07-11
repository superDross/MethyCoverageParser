# Created by David Ross
import pandas as pd
import argparse
import os
from append_probe_info import add_probe

def coverage(cov_dir):
    ''' Combine all BED coverage data from all samples into a 
        Pandas DataFrame.

    Args:
        cov_dir: directory containg BED coverage files
        out: output file
    '''
    cov_files = [f for f in os.listdir(cov_dir) if f.endswith('coverage.txt')]
    print("NOTE: the following BED coverage files will be combined\n"+str(cov_files))
    df_store = []

    for cov_file in cov_files:
        sam = cov_file.split("/")[-1].split(".")[0]
        df = pd.read_csv(cov_dir+cov_file, sep="\t", header=None)
        df.columns = ['Chromosome', 'Start', 'End', 'Cov', 'n', 'length', 'fraction']
        df = df[['Chromosome', 'Start', 'End', 'Cov']]
        df.rename(columns={'Cov': sam}, inplace=True)

        # setting index and transposition is required for proper concatanation
        df_store.append(df.set_index(['Chromosome', 'Start', 'End']).T)

    cov_df = pd.concat(df_store).T.sort_index()
    return cov_df


def cli():
    parser = argparse.ArgumentParser(description="parse CpG coverage data into a data frame like format and output as a tsv")
    parser.add_argument('-d', '--dir', help="directory containing the coverage files (bedtools coverage output)")
    parser.add_argument('-o', '--out', help="output file")
    parser.add_argument('-p', '--probe', nargs='?', default=None, help='probe list to filter positions for')

    args = vars(parser.parse_args())

    cov_df = coverage(args['dir'])
    
    if args['probe']:
        cov_df = add_probe(cov_df, args['probe'])
        cov_df = cov_df.set_index(['Probe', 'Chromosome', 'Start', 'End'])

    cov_df.to_csv(args['out'], sep="\t")

if __name__ == '__main__':
        cli()


