# MethyCoverageParser
Produces coverage and methylation % data from FASTQ files derived from bisulfite converted targeted-sequencing.

Pipeline created by Danny Laurent and Duncan Sproul. <br />
CLI interface, documentation, organisation and main bash script created by David Ross

## Installation
```bash
git clone https://github.com/superDross/MethyCoverageParser/
```

## Description
A command line tool which uses [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) and a selection of parsing scripts upon FASTQ files derived from bisulfite-converted targeted-sequencing to produce three files:
- Coverage.tsv; details coverage across given amplicon ranges for every parsed FASTQ file 
- CpG_divided_coverage.tsv; contains coverage split into methylated/unmethylated/OT/OB for every read containing a CpG in the given FASTQ files 
- CpG_meth_percent_site.tsv; details CpG methylation percentages for selected genomic positions across all FASTQ files 

## Caveats
- The --number argument needs to be set for all non-standard FASTQ file naming so the sample ID can be extracted from the FASTQ filename. The --number flag is used to extract the sample name from the FASTQ filename by splitting the filename by "_" and selecting an element number from the resulting list e.g. if the files are named like "1078TA_SAMPLE1_XXXX_XXXX.fq" and '--numbers 2' is used then the sample name extracted will be SAMPLE1. 

- The required amplicon BED file (--amplicon) is expected to have a fourth column detailing whether the amplicon was designed to the original top strand (OT) or original bottom starnd (OB). If this is not present then a CpG_divided_coverage.tsv file cannot be created. e.g. <br />
       chr4 657827  876254  OB

- The mandatory CpG site file (--cpg) is expected to contain a probe name in the first field and strand orientation in the last field with a header present in the first row. If it does not then the CpG_meth_percent_site.tsv file cannot be generated. e.g. <br />
        probe chrom pos strand <br />
        GB788 chr3  73837 -

## Requirements
python <br />
perl <br />
TrimGalore <br />
bowtie2 <br />
bismark <br />
FastQC <br />
bedtools

## Example Usage
```bash
MethyCoverageParser.sh \
	--fastq ~/fastq/ \
	--dir ~/scratch/ \
	--ref ~/scratch/human/hg38-1000G/ \
	--amplicon ~/scratch/amplicon.bed \
	--cpg ~/scratch/CpG_sites.tsv \
```
Help page
```
MethyCoverageParser.sh --help
```

