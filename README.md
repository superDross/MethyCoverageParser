# MethyCoverageParser
Produces coverage and methylation % data from FASTQ files derived from bisulfite converted amplicon-sequencing.

Pipeline created by Danny Laurent and Duncan Sproul.
CLI interface, documentation, organisation and main bash script created by David R

## Installation
git clone https://github.com/superDross/MethyCoverageParser/

## Description
A command line tool which uses Bismark and a selection of parsing scripts to produce three files:
- Coverage.tsv; details coverage across given amplicon ranges for every parsed FASTQ file 
- CpG_divided_coverage.tsv; contains coverage split into methylated/unmethylated/OT/OB for every read containing a CpG in the given FASTQ files 
- CpG_meth_percent_site.tsv; details CpG methylation percentages for selected genomic positions across all FASTQ files 

## Requirements
python
perl
TrimGalore
bowtie
bismark
FastQC
bedtools

## Example Usage
```bash
MethyCoverageParser.sh \
	--fastq ~/fastq/ \
	--dir ~/scratch \
	--ref ~/scratch/human/hg38-1000G/ \
	--amplicon ~/scratch/amplicon.bed \
	--cpg ~/scratch/CpG_sites.tsv \
	--out ~/results/
```
Help page
```
MethyCoverageParser.sh --help
```

