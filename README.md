# MethyCoverageParser
Produces coverage and methylation percentage data from FASTQ files derived from bisulfite converted targeted Illumina sequencing.

## Description
### Summary
A command line tool which uses [Bismark](https://www.bioinformatics.babraham.ac.uk/projects/bismark/) and a selection of parsing scripts to manipulate FASTQ files derived from bisulfite-converted targeted-sequencing to produce four files: <br />

**mapping_efficiency_summary.txt** <br />
Contains the number of reads with a unique best alignment over the total number of reads for every generated SAM file <br />
```
Sample1_PE_report.txt    Mapping efficiency    78.7%
Sample2_PE_report.txt    Mapping efficiency    82.3%
Sample3_PE_report.txt    Mapping efficiency    86.3%
```
**Coverage.tsv** <br /> 
Details the coverage for each amplicon across all sequenced samples <br />
```
Chromosome  Start     End      Sample1    Sample2    Sample3 
chr4        657827    657996   1230       908        1340 
chr7        987654    987901   1300       1500       750 
```

**CpG_meth_percent.tsv** <br />
Details CpG methylation percentages for all CpG sites within the sequenced amplicons. <br />
```
Chromosome  Position    Strand    Sample1    Sample2    Sample3
chr4        657900   OB        67.2       75.1       38.7 
chr4        657936   OB        21.1       45.6       87.9
chr7        987721   OT        NA         76.8       9.8 
chr7        987809   OT        NA         NA         92.4
```

**CpG_amplicon_coverage.tsv** <br />
The total methylated and unmethylated coverage for all CpG sites covering each sequenced amplicon <br />
```
Chromosome  Start     End       Strand    Methylation Status    Sample1    Sample2    Sample3
chr4        657827    657996    OB        meth                  1200       1500       768
chr4        657827    657996    OB        unmeth                290        1200       1289
chr7        987654    987901    OT        meth                  17689      20000      2007
chr7        987654    987901    OT        unmeth                12000      76         789
```
Reading the [Bismark documentation](https://rawgit.com/FelixKrueger/Bismark/master/Docs/Bismark_User_Guide.html) is **highly recommended** prior to using MethyCoverageParser.




### Pipeline

![](docs/MethyCoverageParser_Image.png?raw=true)

#### I - Generating SAM files
*optional*: The FASTQ files can be downloaded directly from BaseSpace using the ```--basespace``` option and/or the reference genome can be bisulfite converted using  ```--bs-convert``` flag.

The FASTQ files contained within the directory detailed in the ```--fastq``` option have the sequencing primers cut off  to produce trimmed FASTQ files. The subsequently produced FastQC files should be inspected to ensure they are of adequate quality    for alignment. The following [document](https://www.epigenesys.eu/images/stories/protocols/pdf/20120720103700_p57.pdf) can be used  to help determine this.

Bismark aligns the trimmed FASTQ files to the bisulfite-converted genome stored in the directory detailed within the ```--ref``` option to produce SAM files. A *mapping_efficiency_summary.txt* file is also       produced and details the percentage of reads from a FASTQ file pair which uniquely align to the genome. A [MultiQC](http://multiqc.info/) file is generated and contains quality information for all parsed FASTQ files.

#### II - Coverage
The Sam2Bed script iterates through the SAM files and outputs the positions of paired reads which map in proper pairs and outputs them into BED files. [Bedtools Coverage](http://bedtools.readthedocs.io/en/latest/content/tools/coverage.html) subsequently determines the number of times a position range described within the BED file overlaps with the amplicons described within the amplicon bed file (parsed to the ```--amplicon``` option) to produce BED Coverage files. The information from all BED Coverage files are grouped, reformatted and exported as *Coverage.tsv*.

#### III - BedGraph Generation
Bismark Methylation Extractor extracts all CpG context cytosines from the SAM files and exports their methylation status into two separate CpG-site files for directional alignments; one for the positive strand (OT) and another for the negative strand (OB). Non-directional alignments produce an extra two CpG site files for both complementary strands (CTOB & CTOT). The CpG-Site files are parsed together into Bismark2Bedgraph to produce Bedgraph Coverage files detailing; methylation percentage, methylated count and unmethylated count for each CpG site. 

#### IV - CpG Sites Coverage 
The CpG sites detailed in the bedgraph coverage files are grouped together by amplicon and their methylated count and unmethylated count are summarised. The resulting data is then reformatted to show total methylated and unmethylated CpG coverage across all amplicons along with which strand the amplicon was designed to and exported as *CpG_amplicon_coverage.tsv*.  

#### V - CpG Methylation Percentage
All the methylation percentage data from each CpG site within our amplicons are extracted from the bedgraph coverage files, filtered for sites with a minimum of 1000 coverage, annotated with the strand the CpG site derives from and exported as *CpG_meth_percent.tsv*.

*optional*: The methylation percentage data can be further filtered for sites of interest before being exported. Simply parse a file detailing said sites of interest with the ```--cpg``` option.


 

## Installation
A quick-start can be viewed in the docs/ directory.
```bash
git clone https://github.com/superDross/MethyCoverageParser/
cd MethyCoverageParser/
./MethyCoverageParser --help
```



## Requirements
MethyCoverageParser has only been tested with bash version 4.2.46. The below programs must be in your PATH before script execution (confirmed to function correctly with the referenced versions):
```
python2.7
FastQC 
MultiQC v1.0
cutadapt v1.13
TrimGalore v0.4.1
bowtie2 v2.3.1
samtools v1.3
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
```--filter-by-tile``` Directory path containing BBMap scripts. This removes reads with poor tile quality from the FASTQ files. <br />
```--bs-convert``` Bisulfite convert the genome FASTA file. This only needs to be performed once. <br />
```--non-directional``` align reads in an non-directional fashion. <br />
```--fluidigm``` Trim the CS1rc and CS2rc Fluidigm sequencing primers, oppossed to Illuminas, from your FASTQ files. <br />
```--no-sams``` Do not generate SAM files. <br/>
```--no-trim``` Do not trim FASTQ files. <br />
```--no-bme``` Do not produce bismark methylation extraction and bedGraph coverage files. <br />
```--test``` This will only work on a GridEngine system and will take several hours to complete.



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
The below command instructs MethyCoverageParser: that data processing will occur within the scratch directory, to download the FASTQ files from the BaseSpace project 'Methylation_Project' and which directory to store them within (scratch/fq_files/), the directory in which the reference genome is stored within, the location of the amplicon BED file used to determine coverage and to filter *CpG_meth_percent.tsv* for the CpGs detailed in *CpG_sites.tsv*
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
cd basespace/basespace-python-sdk/src
python2 setup.py install --prefix=~/.local/
# if an error occurs while trying to install via setup.py then simply install any package using pip2 then retry the above command
# e.g. pip2 install --user multiqc
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


## Versions
Major changes between versions have been detailed below. Major Bug fixes and documentation updating occurs over every version.

### V0.05
- option ```--test``` adds basic non-comprehensive testing in a GridEngine clustered computing environment

### V0.04
- option ```--filter-by-tile``` to filter FastQ files based upon tile/positional quality prior to adapter trimming
- ```--cpg``` now adds the probe name to all reshaper output files
- MultiQC report is now generated after data processing

### V0.03
- non-directional libraries can now be analysed

### V0.02
- All reshaper scripts have been rewritten using the Pandas library in Python

### V0.01
- FastQ files can be downloaded directly from BaseSpace
