# MethyCoverageParser
Produces coverage and methylation percentage data from FASTQ files derived from bisulfite converted targeted Illumina sequencing.

Pipeline created by Danny Laurent and Duncan Sproul. <br />
CLI interface, documentation, organisation and wrapper bash script created by David Ross



## Description
### Summary
A command line tool which uses [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) and a selection of parsing scripts to manipulate FASTQ files derived from bisulfite-converted targeted-sequencing to produce four files: <br />
- mapping_efficiency_summary.txt - percentage of sequences with a unique best alignment for each sample <br />
- Coverage.tsv - details coverage across given amplicon ranges for every parsed FASTQ file <br />
- CpG_divided_coverage.tsv - The total methylated and unmethylated coverage for all CpG sites in every amplicon <br />
- CpG_meth_percent_site.tsv - details CpG methylation percentages for all CpG sites within the amplicons of all parsed FASTQ files. The CpG sites written to file can be filtered using the --cpg argument.

Reading the [Bismark documentation](https://www.bioinformatics.babraham.ac.uk/projects/bismark/Bismark_User_Guide.pdf) is **highly recommended** prior to using this script.


### Pipeline

![](docs/MethyCoverageParser_Image.png?raw=true)

#### I - Generating SAM files
*optional*: The FASTQ files can be downloaded directly from BaseSpace using```--basespace``` option and/or the reference genome can be       bisulfite converted using  ```--bs-convert``` flag.

The FASTQ files contained within the directory detailed in the ```--fastq``` option have the Fluidigm sequencing primers cut off  to produce trimmed FASTQ files. The subsequently produce FastQC files should be inspected to ensure they are of adequate quality    for alignment and the following [document](https://www.epigenesys.eu/images/stories/protocols/pdf/20120720103700_p57.pdf) can be used  to help determine this.

Bismark aligns the trimmed FASTQ files to the bisulfite-converted genome stored in the directory detiled in the ```--ref``` option to produce [SAM files](https://samtools.github.io/hts-specs/SAMv1.pdf). A *mapping_efficiency_summary.txt* file is also       produced and details the percentage of reads from a FASTQ file pair which uniquely align to the genome.

#### II - Coverage
The Sam2Bed script iterates through the SAM files and outputs the positions of paired reads which map in proper pairs and outputs them into BED files. [Bedtools Coverage](http://bedtools.readthedocs.io/en/latest/content/tools/coverage.html) subsequently determines the number of times a position range described within the BED file overlaps with the amplicons described within the amplicon bed file (parsed to the ```--amplicon``` option) to produce BED Coverage files. The CoverageParser script takes the information from all BED Coverage files and reformats them into a data frame like format exported as *Coverage.tsv*.

#### III - CpG Sites
Bismark Methylation Extractor will extract all CpG context cytosines from the SAM files and export their methylation status into two seperate CpG-site files; one for the positive strand (OT) and another for the negative strand (OB).

#### IV - CpG Sites Coverage 
Both the OT and OB CpG-site files are split by methylation status, producing CpG-site files for; OT-methylated positions, OT-unmthylated positions, OB-methylated positions & OB-unmethylated positions. Bedtools Coverage then creates BED Coverage files for each of the four split CpG-site files using the aforementioned amplicon bed file. Finally, DivededCoverageParser extracts all the BED Coverage data and reformats it into a dataframe like format exported as *CpG_divided_coverage.tsv*. This file details the methylated and unmethylated CpG coverage across each amplicon; the coverage of each methylated/unmethylated CpG site that lies within an amplicon is added together. 

#### V - CpG Methylation Percentage
The CpG-Site files generated in step III are paired and parsed into Bismark2Bedgraph to produce Bedgraph Coverage files detailing; cytosine coverage, non-cytosine coverage and the percent methylated at said sites. SiteMethPercParser extracts all the methylation percentage data from the Bedgraph Coverage files, filters for sites with a minimum of 1000 coverage and reformats them into a dataframe like format exported as *CpG_meth_percent_site.tsv*.

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
python2
python3 
perl5 
FastQC 
cutadapt v1.13
TrimGalore v0.4.1
bowtie2 v2.3.1
bismark v0.16.3
bedtools v2.26.0
```



## Options
### Required
```--fastq``` The directory containing FASTQ files or sub-directories in containing FASTQ files. <br />
```--dir``` The directory in which the data processing and generation will take place. <br />
```--ref``` The directory containing the genome FASTA file. <br />
```--amplicon``` The required amplicon BED file used to generate coverage file. This is expected to have a fourth column detailing whether the amplicon was designed to the original top strand (OT) or original bottom strand (OB). If this is not present then a ```CpG_divided_coverage.tsv``` file cannot be created. Formating of amplicon BED file should be as below:
```
chr4    657827    657996    OB 
chr7    987654    987901    OT 
```

### Optional
```--basespace``` BaseSpace project name to download the FASTQ files from. See the Downloading FASTQ Files section below for further information in utilising this feature. <br />
```--cpg``` The CpG site file to filter specific positions for generating ```CpG_meth_percent_site.tsv```. This file should contain a probe name in the first field and strand orientation in the last field with a header present in the first row. If the file does not fulfill these criteria then the ```CpG_meth_percent_site.tsv``` file cannot be generated. Formatting of the CpG site file should be as below: 
```
probe    chrom    pos    strand
GB788    chr3    73837    -
GB987    chr9    98654    +
```
```--bs-convert``` Bisulfite convert the genome FASTA file. This only has to be performed once. <br />
```--fluidigm``` Trim the CS1rc and CS2rc Fluidigm sequencing primers, oppossed to Illuminas, from your FASTQ files. <br />
```--no-sams``` do not generate SAM files. <br/>
```--no-trim``` do not trim FASTQ files.



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
The below command instructs MethyCoverageParser: that data processing will occur within the scratch directory, to download the FASTQ files from the BaseSpace project 'Methylation_Project' and which directory to store them within (scratch), the directory in which the reference genome is stored within, the location of the amplicon BED file used to determine coverage and to filter CpG_meth_percent_site.tsv for the CpGs detailed in CpG_sites.tsv
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
**This feature is experimental** <br />
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
The script allowing this feature is an adaptation of [Basespace-Invaders](https://github.com/nh13/basespace-invaders) samples2files script.



