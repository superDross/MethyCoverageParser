# Created by David Ross
import pandas as pd
import argparse
import os

def coverage(cov_dir, out):
    ''' Combine all BED coverage data from all samples into a 
        Pandas DataFrame.

    Args:
        cov_dir: directory containg BED coverage files
        out: output file
    '''
    cov_files = [f for f in os.listdir(cov_dir) if f.endswith('coverage.txt')]
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
    cov_df.to_csv(out, sep="\t")
    return cov_df


def cli():
        parser = argparse.ArgumentParser(description="parse CpG coverage data into a data frame like format and output as a tsv")
        parser.add_argument('-d', '--dir', help="directory containing the coverage files (bedtools coverage output)")
        parser.add_argument('-o', '--out', help="output file")

        args = vars(parser.parse_args())

        coverage(args['dir'], args['out'])


if __name__ == '__main__':
        cli()


