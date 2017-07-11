# created by David Ross
import pandas as pd
import argparse
import os
from append_probe_info import add_probe

def CpG_cov(cov_dir, field):
    ''' Get the methylated/unmethylated coverage for all CpG sites
        from all bismark2bedgraph coverage files in a given directory and output 
        into a Pandas DataFrame.
    
    Args:
        cov_dir: dir containing BME coverage files
        field: the column values to parse into cells (meth_cov or unmeth_cov)
    '''
    if field not in ('meth_cov', 'unmeth_cov'):
        raise IOError("field must be meth_cov or unmeth_cov not {}".format(field))
        
    cov_files = sorted([f for f in os.listdir(cov_dir) if f.endswith('cov')])
    print("NOTE: the following BME coverage files will be combined\n"+str(cov_files))
    df_store = []

    for cov_file in cov_files:
        sam = cov_file.split("/")[-1].split(".")[0]
        df = pd.read_csv(cov_dir+cov_file, sep="\t", header=None)
        df.columns = ['Chromosome', 'Position', 'pos_end', 'meth_percent', 'meth_cov', 'unmeth_cov']
        df['coverage'] = df['meth_cov'] + df['unmeth_cov']
        df = df[['Chromosome', 'Position', field]]
        df.rename(columns={field: sam}, inplace=True)
        df['methy_status'] = field
        # setting index and transposition is required for proper concatanation
        df_store.append(df.set_index(['Chromosome', 'Position', 'methy_status']).T)

    cpg_df = pd.concat(df_store).T
    return cpg_df


def amplicon_cpg_coverage(cov_df, amplicon):
    ''' Calulate the total CpG coverage across all given amplicons and
        create an amplicon CpG file.
    
    Args:
        cov_df: CpG_cov() outputted DataFrame
        amplicon: BED like file describing primer start , end pos 
                  and strand
    '''
    # store all amplicon cpg coverage values
    series_store = []

    with open(amplicon) as amp:
        cov_df = cov_df.reset_index()
        
        for line in amp.readlines():
            chrom, start, end, strand = line.strip("\n").split("\t")
            # filter for CpG sites within the amplicon
            filtered = cov_df[(cov_df['Chromosome'] == str(chrom)) & (cov_df['Position'] >= int(start)) & 
                              (cov_df['Position'] <= int(end))]
            # sum all the filtered CpG sites coverage values together to get a summarised series
            headers = [x for x in filtered if x not in ('Chromosome', 'Position', 'methy_status')]
            sum_filtered = filtered[headers].sum()
            # create a series with amplicon & methylation information and concat with summarised CpG coverage series
            amp_range = pd.Series([chrom, start, end, strand, cov_df['methy_status'].unique()[0]], 
                                  index=['Chromosome', 'Start', 'End', 'Strand', 'Methylation Status'])
            amp_series = amp_range.append(sum_filtered)
            series_store.append(amp_series)

    # concat all the series together and set index
    df = pd.concat(series_store, axis=1).T
    df = df.set_index(['Chromosome', 'Start', 'End', 'Strand', 'Methylation Status']).sort_index()
    return df



def main(cov_dir, amplicon, out, probe_file=None):
    # produce a dataframe detailing the coverage for all meth/unmeth CpG sites from bismark2bedGrpah coverage files
    meth_site_cov = CpG_cov(cov_dir, 'meth_cov')
    unmeth_site_cov = CpG_cov(cov_dir, 'unmeth_cov')
    
    # get the total CpG site methylation coverage over a set of amplicons and transform into dataframes
    meth_amplicon_cov = amplicon_cpg_coverage(meth_site_cov, amplicon)
    unmeth_amplicon_cov = amplicon_cpg_coverage(unmeth_site_cov, amplicon) 

    # concatenate both the methyalted and non methylated counterparts
    com_cov = pd.concat([meth_amplicon_cov, unmeth_amplicon_cov]).sort_index()

    # add probe name to the amplicons
    if probe_file:
        com_cov = add_probe(com_cov, probe_file)
        com_cov = com_cov.set_index(['Probe', 'Chromosome', 'Start', 'End', 'Strand', 'Methylation Status'])
      
    com_cov.to_csv(out, sep="\t")

    return com_cov


def get_parser():
    parser = argparse.ArgumentParser(description="Parses bedgraph coverage files to create a dataframe of samples CpG methylated/unmethylated coverage at given genomic range of interest")
    parser.add_argument('-b', '--bedgraph_dir', help='dir containing bedgraph coverage files')
    parser.add_argument('-o', '--output', help='output file name')
    parser.add_argument('-a', '--amplicon', help='amplicon bed file containing primer positions and strand')
    parser.add_argument('-p', '--probe', nargs='?', default=None, help='probe list to filter positions for')

    return parser


def cli():
    parser = get_parser()
    args = vars(parser.parse_args())
    main(args['bedgraph_dir'], args['amplicon'], args['output'], args['probe'])
    
    
if __name__ == '__main__':
    cli()
    
