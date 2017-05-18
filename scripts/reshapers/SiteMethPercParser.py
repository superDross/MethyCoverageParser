# This produces the same results as SiteMethPercParser
import pandas as pd
import argparse
import os



def CpG_dataframe(cov_files, percentage=True):
    ''' Get the methylation percentages from all CpG sites with
        a coverage over 1000 from all BME coverage files in a 
        given directory and output into a Pandas DataFrame.
    
    Args:
        BME_cov_dir: dir containing BME coverage files
    
       '''
    df_store = []

    for cov_file in cov_files:
        sam = cov_file.split("/")[-1].split(".")[0]
        df = pd.read_csv(cov_file, sep="\t", header=None)
        df.columns = ['Chromosome', 'Position', 'pos_end', 'meth_percent', 'meth_cov', 'unmeth_cov']
        df['coverage'] = df['meth_cov'] + df['unmeth_cov']

        if percentage:
            df = df[df['coverage'] > 1000]
            field = 'meth_percent'
        else:
            field = 'meth_cov'

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

            
            
def main(BME_cov_dir, out, amplicon=None, cpg_sites=None, methylation=True, coverage=False):
    ''' 
    Notes:
        cpg_sites should be in this format, with header:
        
            probe   chrom   pos   strand
            cg167   chr12   1728    +
    '''
    # create a df of all cov files methylation percentages and 
    if methylation:
        cov_files = [BME_cov_dir+"/"+f for f in os.listdir(BME_cov_dir) 
                     if f.endswith('cov') and not f.endswith('meth.txt')]
        cpg = CpG_dataframe(cov_files, percentage=True)

    if coverage:
        # input the same coverage files, but determine which sites are from an amplicon and add all these sites (that deive from the same amplicon) meth_coverage together and unmeth_coverage together. The output should look like:
           # chrom   start   end   strand   meth_status   SAM1
           #  chr7   6278    6728   OB      meth          50245

        # this will give the same answer as CpG_divided_coverage.tsv
        pass


    if amplicon:
        cpg = insert_strand(cpg, amplicon)
    if cpg_sites:
        pass
    
    cpg.to_csv(out, na_rep='NA')
    return cpg


def get_parser():
    parser = argparse.ArgumentParser(description="Parses bedgraph coverage files to create a dataframe of samples CpG methylation % at given genomic positions of interest")
    parser.add_argument('-b', '--bedgraph_dir', help='dir containing bedgraph coverage files')
    parser.add_argument('-o', '--output', help='output file name')
    parser.add_argument('-a', '--amplicon', help='amplicon bed file containing primer positions and strand')
    parser.add_argument('-p', '--positions', help='file containing positions of interest')
    parser.add_argument('-m', '--methylation', action='store_true', default=True)
    parser.add_argument('-c', '--coverage', action='store_true')

    return parser


def cli():
    parser = get_parser()
    args = vars(parser.parse_args())
    if args['methylation'] and args['coverage']:
        raise IOError("--methylation and --coverage cannot be parsed together. Parse only one flag")
    main(args['bedgraph_dir'], args['output'], args['amplicon'], 
         args['positions'], args['methylation'], args['coverage'])
    
    
if __name__ == '__main__':
    cli()
    
