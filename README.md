# MethyCoverageParser
Produces coverage and methylation percentage data from FASTQ files derived from bisulfite converted targeted Illumina sequencing.

Pipeline created by Danny Laurent and Duncan Sproul. <br />
CLI interface, documentation, organisation and wrapper bash script created by David Ross



## Description
### Summary
A command line tool which uses [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) and a selection of parsing scripts to manipulate FASTQ files derived from bisulfite-converted targeted-sequencing to produce four files: <br />
- mapping_efficiency_summary.txt - percentage of sequences which uniquely align to the BS-genome <br />
- Coverage.tsv - details amplicon coverage <br />
- CpG_amplicon_coverage.tsv - the total methylated and unmethylated coverage for all CpG sites covering each sequenced amplicon <br />
- CpG_meth_percent.tsv - details CpG methylation percentages for all sequenced CpG sites. <br />

Reading the [Bismark documentation](https://www.bioinformatics.babraham.ac.uk/projects/bismark/Bismark_User_Guide.pdf) is **highly recommended** prior to using this script.


### Pipeline

![](docs/MethyCoverageParser_Image.png?raw=true)

#### I - Generating SAM files
*optional*: The FASTQ files can be downloaded directly from BaseSpace using```--basespace``` option and/or the reference genome can be bisulfite converted using  ```--bs-convert``` flag.

The FASTQ files contained within the directory detailed in the ```--fastq``` option have the sequencing primers cut off  to produce trimmed FASTQ files. The subsequently produce FastQC files should be inspected to ensure they are of adequate quality    for alignment and the following [document](https://www.epigenesys.eu/images/stories/protocols/pdf/20120720103700_p57.pdf) can be used  to help determine this.

Bismark aligns the trimmed FASTQ files to the bisulfite-converted genome stored in the directory detailed within the ```--ref``` option to produce [SAM files](https://samtools.github.io/hts-specs/SAMv1.pdf). A *mapping_efficiency_summary.txt* file is also       produced and details the percentage of reads from a FASTQ file pair which uniquely align to the genome.

#### II - Coverage
The Sam2Bed script iterates through the SAM files and outputs the positions of paired reads which map in proper pairs and outputs them into BED files. [Bedtools Coverage](http://bedtools.readthedocs.io/en/latest/content/tools/coverage.html) subsequently determines the number of times a position range described within the BED file overlaps with the amplicons described within the amplicon bed file (parsed to the ```--amplicon``` option) to produce BED Coverage files. The information from all BED Coverage files are grouped, reformatted and exported as *Coverage.tsv*.

#### III - BedGraph Generation
Bismark Methylation Extractor will extract all CpG context cytosines from the SAM files and export their methylation status into two seperate CpG-site files; one for the positive strand (OT) and another for the negative strand (OB). The CpG-Site files are paired and parsed into Bismark2Bedgraph to produce Bedgraph Coverage files detailing; methylation percentage, methylated count and unmethylated count for each CpG site. 

#### IV - CpG Sites Coverage 
The CpG sites detailed in the bedgraph coverage files are grouped together by amplicon and their methylated count and unmethylated count are summarised. The resulting data is then reformatted to show total methylated and unmethylated CpG coverage across all amplicons along with which strand the amplicon was designed to and exported as *CpG_amplicon_coverage.tsv*.  

#### V - CpG Methylation Percentage
All the methylation percentage data from each CpG site are extracted from the Bedgraph Coverage files, filtered for sites with a minimum of 1000 coverage, annotated with the strand the CpG site derives from and exported as *CpG_meth_percent.tsv*.

*optional*: The methylation percentage data can be further filtered for sites of interest before being exported. Simply parse a file detailing said sites of interest with the ```--cpg``` option.


 

## Installation
```bash
git clone https://github.com/superDross/MethyCoverageParser/
cd MethyCoverageParser/
./MethyCoverageParser --help
```



## Requirements
The script has only been tested with bash version 4.2.46. The below programs must be in your PATH before running the script (confirmed to function correctly with the referenced versions):
```
python2.7
FastQC 
cutadapt v1.13
TrimGalore v0.4.1
bowtie2 v2.3.1
bismark v0.16.3
bedtools v2.26.0
```



## Options
### Required
```--fastq``` The directory containing FASTQ files or directory with sub-directories containing FASTQ files.  <br />
```--dir``` The directory in which the data processing and generation will take place. <br />
```--ref``` The directory containing the genome FASTA file. <br />
```--amplicon``` An amplicon BED file describing the genomic ranges covered in the amplicon-seq libraries. This is expected to have a fourth column detailing whether the amplicon was designed to the original top strand (OT) or original bottom strand (OB). Formating of amplicon BED file should be as below:
```
chr4    657827    657996    OB 
chr7    987654    987901    OT 
```

### Optional
```--basespace``` BaseSpace project name to download the FASTQ files from. See the Downloading FASTQ Files section below for further information in utilising this feature. <br />
```--cpg``` The CpG site file to filter specific positions for generating ```CpG_meth_percent_site.tsv```. This file should contain a probe name in the first field and strand orientation in the last field with a header present in the first row. Formatting of the CpG site file should be as below: 
```
probe    chrom    pos    strand
GB788    chr3    73837    -
GB987    chr9    98654    +
```
```--bs-convert``` Bisulfite convert the genome FASTA file. This only needs to be performed once. <br />
```--fluidigm``` Trim the CS1rc and CS2rc Fluidigm sequencing primers, oppossed to Illuminas, from your FASTQ files. <br />
```--no-sams``` Do not generate SAM files. <br/>
```--no-trim``` Do not trim FASTQ files.



## Example Usage
The below command instructs MethyCoverageParser: that data processing will occur within the scratch directory, the directories in which the reference genome and FASTQ files are stored within, the location of the amplicon BED file used to determine coverage, to bisulfite convert the given genome and trim the Fluidigm CS1rc and CS2rc sequencing primers from the FASTQ files.

```bash
MethyCoverageParser.sh \
	--dir scratch/ \
	--ref scratch/human/hg38/ \
	--fastq scratch/fq_files/ \
	--amplicon scratch/amplicon.bed \
	--bs-convert \
	--fluidigm
```
The below command instructs MethyCoverageParser: that data processing will occur within the scratch directory, to download the FASTQ files from the BaseSpace project 'Methylation_Project' and which directory to store them within (scratch), the directory in which the reference genome is stored within, the location of the amplicon BED file used to determine coverage and to filter *CpG_meth_percent.tsv* for the CpGs detailed in *CpG_sites.tsv*
```bash
MethyCoverageParser.sh \
	--dir scratch/ \
	--basespace Methylation_Project \
	--fastq scratch/fq_files/ \
	--ref scratch/human/hg38/ \
	--amplicon scratch/amplicon.bed \
	--cpg scratch/CpG_sites.tsv 
```



## Downloading FASTQ files
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

Create a file in your home directory ```~/.basespacepy.cfg``` and fill in the clientKey, clientSecret and clientToken with the information noted from the credentials tab.
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
The script allowing this feature is an adaptation of [Basespace-Invaders](https://github.com/nh13/basespace-invaders) samples2files script.



