# This produces the same results as SiteMethPercParser
import pandas as pd
import numpy as np
import argparse
import os


def CpG_methylation(BME_cov_dir, cpg_sites=None):
    ''' Get the methylation percentages from all CpG sites with
        a coverage over 1000 from all BME coverage files in a 
        given directory and output into a Pandas DataFrame.
    
    Args:
        BME_cov_dir: dir containing BME coverage files
        cpg_sites: positions to filter the DataFrame for
    
    Notes:
        cpg_sites should be in this format, with header:
        
            probe   chrom   pos   strand
            cg167   chr12   1728    +
    '''
    cov_files = [f for f in os.listdir(BME_cov_dir) if f.endswith('cov')]
    df_store = []

    for cov_file in cov_files:
        sam = cov_file.split(".")[0]
        df = pd.read_csv(BME_cov_dir+cov_file, sep="\t", header=None)
        df.columns = ['Chromosome', 'Position', 'pos_end', 'meth_percent', 'c_cov', 'tri_cov']
        df['coverage'] = df['c_cov'] + df['tri_cov']
        df = df[df['coverage'] > 1000]
        df = df[['Chromosome', 'Position', 'meth_percent']]
        df.rename(columns={'meth_percent': sam}, inplace=True)
        # setting index and transposition is required for proper concatanation
        df_store.append(df.set_index(['Chromosome', 'Position']).T)

    cpg_df = pd.concat(df_store).T
    return cpg_df


def insert_strand(cpg, amplicon):
    ''' Determine whether the CpG site falls within a primer
        designed to OT or OB strand and place into a new Strand
        column.
        
    Args: 
        cpg: CpG_methylation() output
        amplicon: BED like file describing primer start , end pos 
                  and strand
    
    Notes:
        amplicon should be in the following format, without header:
            
            chr12   1272   1767   OT
            chr14   7280   9898   OB
    '''
    cpg = cpg.reset_index()
    cpg['Strand'] = cpg.apply(lambda x: determine_strand(x, amplicon), axis=1)

    cpg = cpg.set_index(['Chromosome', 'Position'])
    reorder = ['Strand'] + [x for x in cpg.columns.values if x != 'Strand']
    return cpg[reorder]


def determine_strand(x, amplicon):
    ''' Determine if the the chromosome position
        is within any of the amplicons and if so
        return the associated strand value.
    '''
    with open(amplicon) as amp:
        for line in amp.readlines():
            chrom, start, end, strand = line.strip("\n").split("\t")
            if str(x['Chromosome']) == str(chrom) and x['Position'] >= int(start) and x['Position'] <= int(end):
                return strand
            #else:
            #    return np.nan

            
            
def main(BME_cov_dir, out, amplicon=None, cpg_sites=None):
    '''
    '''
    # create a df of all cov files methylation percentages and 
    cpg = CpG_methylation(BME_cov_dir, cpg_sites)
    if amplicon:
        cpg = insert_strand(cpg, amplicon)
    
    cpg.to_csv(out, na_rep='NA')
    return cpg


def get_parser():
    parser = argparse.ArgumentParser(description="Parses bedgraph coverage files to create a dataframe of samples CpG methylation % at given genomic positions of interest")
    parser.add_argument('-b', '--bedgraph_dir', help='dir containing bedgraph coverage files')
    parser.add_argument('-o', '--output', help='output file name')
    parser.add_argument('-a', '--amplicon', help='amplicon bed file containing primer positions and strand')
    parser.add_argument('-p', '--positions', help='file containing positions of interest')
    return parser


def cli():
    parser = get_parser()
    args = vars(parser.parse_args())
    main(args['bedgraph_dir'], args['output'], args['amplicon'], args['positions'])
    
    
if __name__ == '__main__':
    cli()
    
