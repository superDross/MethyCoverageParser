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
- mapping_efficiency_summary.txt - percentage of sequences with a unique best alignment for each sample <br />
- Coverage.tsv - details coverage across given amplicon ranges for every parsed FASTQ file <br />
- CpG_divided_coverage.tsv - contains coverage split into methylated/unmethylated/OT/OB for every read containing a CpG in the given FASTQ files <br />
- CpG_meth_percent_site.tsv - details CpG methylation percentages for selected genomic positions across all FASTQ files

Reading the [Bismark documentation](https://www.bioinformatics.babraham.ac.uk/projects/bismark/Bismark_User_Guide.pdf) is **highly recommended** prior to using this script.

## Downloading FASTQ files
**This feature is highly experimental** <br />
The optional ```--basespace``` flag allows one to download FASTQ files related to a parsed BaseSpace project name and outputs them into the given ```--fastq``` directory. The script allowing this functionality requires [basespace-python-sdk](https://github.com/basespace/basespace-python-sdk) to be cloned and be present in your PYTHONPATH. 
```
git clone https://github.com/basespace/basespace-python-sdk
export PYTHONPATH=$PYTHONPATH:/path/to/basespace-python-sdk/src
```
The proper credentials have to be generated to facilitate communication with BaseSpace:

1. Login to https://developer.basespace.illumina.com/
2. Click on the My Apps button present in the header 
3. Click 'create new application'
4. Fill out the app details with something (anything, it's really not important)
5. Click on the credentials tab and note the Client ID, Client Secret and Access Token.

Create a file in your home directory ```~/basespacepy.cfg``` and fill in the clientKey, clientSecret and clientToken with the information noted from the credentials tab.
```
[DEFAULT]
name = my new app
clientKey = Client ID
clientSecret = Client Secret
accessToken = Access Token
appSessionId = "
apiServer = https://api.cloud-hoth.illumina.com/
apiVersion = v1pre3
```
The script allowing this feature is an adaptation of [Basespace-Invaders](https://github.com/nh13/basespace-invaders) samples2files.py script.

## Caveats
- The required amplicon BED file (--amplicon argument) is expected to have a fourth column detailing whether the amplicon was designed to the original top strand (OT) or original bottom strand (OB). If this is not present then a CpG_divided_coverage.tsv file cannot be created. Formating of amplicon BED file should be as below: <br /> <br />
       chr4&nbsp;&nbsp;&nbsp;&nbsp;657827&nbsp;&nbsp;&nbsp;&nbsp;876254&nbsp;&nbsp;&nbsp;&nbsp;OB

- The mandatory CpG site file (--cpg argument) is expected to contain a probe name in the first field and strand orientation in the last field with a header present in the first row. If it does not then the CpG_meth_percent_site.tsv file cannot be generated. Formatting of the CpG site file should be as below: <br /> <br />
        probe&nbsp;&nbsp;&nbsp;&nbsp;chrom&nbsp;&nbsp;&nbsp;&nbsp;pos&nbsp;&nbsp;&nbsp;&nbsp;strand <br />
        GB788&nbsp;&nbsp;&nbsp;&nbsp;chr3&nbsp;&nbsp;&nbsp;&nbsp;73837&nbsp;&nbsp;&nbsp;&nbsp;-

## Requirements
The following programs must be in your PATH before running the script:
```
python2
python3 
perl5 
TrimGalore 
bowtie2 
bismark 
FastQC 
bedtools
```
## Example Usage
```bash
MethyCoverageParser.sh \
	--fastq fq_files/ \
	--dir scratch/ \
	--ref scratch/human/hg38/ \
	--amplicon scratch/amplicon.bed \
	--cpg scratch/CpG_sites.tsv \
	--basespace Methylation_Project \
	--bs-convert
```


