''' Functions which add probe information to the three tsv files outputted by MethyCoverageParser
'''
import pandas as pd

def rename_probe_header(probe):
    ''' Rename the headers of a probe df with the correct
        headers.

    Args:
        probe: DataFrame containing probe information

    Notes:
        probes should look like:

    '''
    # unwanted df headers
    unwanted_chr = ['chr', 'chrom', 'Chromosome', 'chromosome']
    unwanted_pos = ['pos', 'Position', 'position']

    # dictionary containing unwanted headers as keys and wanted header as items
    create_dict = lambda k,v: dict((x,v) for x in k)
    alter_header = create_dict(unwanted_chr, 'Chrom')
    alter_header.update(create_dict(unwanted_pos, 'Pos'))
    alter_header.update({'probe': 'Probe'})

    headers = set(probe.columns.tolist())
    unwanted = set(unwanted_chr+unwanted_pos)
    
    # rename the unwanted headers
    if headers.intersection(unwanted):
        probe = probe.rename(columns=alter_header)
   

    return probe


def add_probe(df, probe_file, cpg_site=False):
    ''' Determine which amplicons in df overlap a probe
        genomic co-ordinate and add a column detailing 
        name of probe.

    Args:
        df: ouput of CpG_cov()
        probe: DataFrame containing probe information
        cpg_sites: True - looks to see if the probe 
                   positions matches the CpG site
                   False - looks to see if the probe
                   is within the amplicons range 
    '''
    # cleanup probe file
    probe = pd.read_csv(probe_file, sep='\t')
    probe = rename_probe_header(probe)

    # prepare df
    df = df.reset_index()

    if cpg_site:
        df['Position'] = df['Position'].convert_objects(convert_numeric=True)
        df = df.merge(probe, left_on='Chromosome', right_on='Chrom').query('Position == Pos')
    else:
        df['Start'] = df['Start'].convert_objects(convert_numeric=True)
        df['End'] = df['End'].convert_objects(convert_numeric=True)
        # add probe in correct place
        df = df.merge(probe, left_on='Chromosome', right_on='Chrom').query('Start <= Pos <= End')

    # cleanup merged df and return
    df.drop(['Chrom', 'Pos', 'strand'], axis=1, inplace=True)

    return df


