# MethyCoverageParser
Produces coverage and methylation % data from FASTQ files derived from bisulfite converted targeted Illumina sequencing.

Pipeline created by Danny Laurent and Duncan Sproul. <br />
CLI interface, documentation, organisation and wrapper bash script created by David Ross

## Installation
```bash
git clone https://github.com/superDross/MethyCoverageParser/
cd MethyCoverageParser/
./MethyCoverageParser --help
```

## Description
A command line tool which uses [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) and a selection of parsing scripts upon FASTQ files derived from bisulfite-converted targeted-sequencing to produce three files: <br />
- Coverage.tsv - details coverage across given amplicon ranges for every parsed FASTQ file <br />
- CpG_divided_coverage.tsv - contains coverage split into methylated/unmethylated/OT/OB for every read containing a CpG in the given FASTQ files <br />
- CpG_meth_percent_site.tsv - details CpG methylation percentages for selected genomic positions across all FASTQ files

Reading the [Bismark documentation](https://www.bioinformatics.babraham.ac.uk/projects/bismark/Bismark_User_Guide.pdf) is **highly recommended** prior to using this script.

## Caveats
- The required amplicon BED file (--amplicon argument) is expected to have a fourth column detailing whether the amplicon was designed to the original top strand (OT) or original bottom strand (OB). If this is not present then a CpG_divided_coverage.tsv file cannot be created. e.g. <br />
       chr4&nbsp;&nbsp;&nbsp;&nbsp;657827&nbsp;&nbsp;&nbsp;&nbsp;876254&nbsp;&nbsp;&nbsp;&nbsp;OB

- The mandatory CpG site file (--cpg argument) is expected to contain a probe name in the first field and strand orientation in the last field with a header present in the first row. If it does not then the CpG_meth_percent_site.tsv file cannot be generated. e.g. <br />
        probe&nbsp;&nbsp;&nbsp;&nbsp;chrom&nbsp;&nbsp;&nbsp;&nbsp;pos&nbsp;&nbsp;&nbsp;&nbsp;strand <br />
        GB788&nbsp;&nbsp;&nbsp;&nbsp;chr3&nbsp;&nbsp;&nbsp;&nbsp;73837&nbsp;&nbsp;&nbsp;&nbsp;-

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
	--fastq fq_files/ \
	--dir scratch/ \
	--ref scratch/human/hg38/ \
	--amplicon scratch/amplicon.bed \
	--cpg scratch/CpG_sites.tsv \
	--bs-convert
```


