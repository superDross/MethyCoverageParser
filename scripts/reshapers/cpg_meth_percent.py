# Created by David Ross
import pandas as pd
import argparse
import os


def CpG_dataframe(cov_dir):
    ''' Get the methylation percentages from all CpG sites with
        a coverage over 1000 from all bismark2bedGraph coverage files in a 
        given directory and output into a Pandas DataFrame.
    
    Args:
        cov_dir: dir containing bismark2BedGraph coverage files
    
       '''
    cov_files = [f for f in os.listdir(cov_dir) 
                 if f.endswith('cov')]

    df_store = []

    for cov_file in cov_files:
        sam = cov_file.split("/")[-1].split(".")[0]
        df = pd.read_csv(cov_dir+"/"+cov_file, sep="\t", header=None)
        df.columns = ['Chromosome', 'Position', 'pos_end', 'meth_percent', 'meth_cov', 'unmeth_cov']
        df['coverage'] = df['meth_cov'] + df['unmeth_cov']
        df = df[df['coverage'] > 1000]
        field = 'meth_percent'

        df = df[['Chromosome', 'Position', field]]
        df.rename(columns={field: sam}, inplace=True)
        # setting index and transposition is required for proper concatanation
        df_store.append(df.set_index(['Chromosome', 'Position']).T)

    cpg_df = pd.concat(df_store).T
    return cpg_df


def insert_strand(cpg, amplicon):
    ''' Determine whether the CpG site falls within a primer
        designed to OT or OB strand and place into a new Strand
        column.
        
    Args: 
        cpg: CpG_dataframe() output
        amplicon: BED like file describing primer start , end pos 
                  and strand
    
    Notes:
        amplicon should be in the following format, without header:
            
            chr12   1272   1767   OT
            chr14   7280   9898   OB
    '''
    cpg = cpg.reset_index()
    cpg['Strand'] = cpg.apply(lambda x: determine_strand(x, amplicon), axis=1)

    cpg = cpg.set_index(['Chromosome', 'Position', 'Strand'])
    return cpg


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


def filter_cpg(cpg, cpg_sites):
    ''' Filter methylation percentage dataframe for
        cpg sites of interest.
    
    Args:
        cpg: CpG_methylation dataframe
        cpg_sites: sites to filter for
    
    Notes:
        cpg_sites should be in the following format, with a header:
            probe   chrom    start    strand
            GB18272 ch17     879373   -
    '''
    chrom = [x.rstrip("\n").split("\t")[1] for x in open(cpg_sites)][1:]
    pos = [x.rstrip("\n").split("\t")[2] for x in open(cpg_sites)][1:]
    cpg = cpg.reset_index()
    filtered_cpg = cpg[(cpg['Chromosome'].isin(chrom)) & (cpg['Position'].astype(str).isin(pos))]
    return filtered_cpg.set_index(['Chromosome', 'Position', 'Strand'])

            
            
def main(cov_dir, out, amplicon=None, cpg_sites=None):
    ''' Filter methylation percentage dataframe for
        cpg sites of interest.

    Args:
        cpg: CpG methylation dataframe
        cpg_sites: sites to filter for

    Notes:
        cpg_sites should be in this format, with header:
        
            probe   chrom   pos   strand
            cg167   chr12   1728    +
    '''
    # create a df of all cov files methylation percentages and 
    cpg = CpG_dataframe(cov_dir)

    if amplicon:
        cpg = insert_strand(cpg, amplicon)

    if cpg_sites:
        cpg = filter_cpg(cpg, cpg_sites)

    cpg.to_csv(out, na_rep='NA', sep="\t")
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
    
