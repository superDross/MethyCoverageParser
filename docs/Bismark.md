# Direction
The sequence library can be generated in two ways:

    directional - the actual sequencing reads will correspond to a bisulfite converted version of either the original forward or reverse strand.
    non-directional - strand specificity is not preserved, meaning a bisulfite converted version of the original forward/top strand (OT), complementary to original top/forward strand (CTOT), the original reverse/bottom strand (OB) and complementary to original reverse/bottom strand (CTOB).


Directional has to be designed in such a way that the OT and OB strand are tagged so that the primers only amplify these configurations; post-bisulfite adapter tagging (PBAT) sequencing (the EpiGnome is a good example of this). Non-directional has no such tagging so all configurations are amplified.

PBOT   ATCCGA         PB = pre-bisulfite
--------------
OT     ATTTGA
CTOT   TAAACT

PBOB   TAGGCT
--------------
OB     TAGGTT      
CTOB   ATCCAA


# Bismark
1- create a C-to-T and G-to-A versions of the genome using Bismark Genome Preperation
2- bisulfite reads from Read1 are transformed to C-to-T and reads from Read2 are transformed to G-to-A (C-to-T equivalent on the reverse strand). If the strands are non-directional (specify by giving the --non_directional flag) then all reads are transformed to C-to-T and G-to-A.
3- each converted read is aligned to the converted forms of the reference genome to determine orietation (OT/OB/CTOT/CTOB), if --directional then the CTOT and CTOB reads are thrown away
4- a single converted read orientation is selected as being the most uniquely aligned; which uniquely aligns to one part of the genome and which maps most uniquely among orientations
5- methylation calls are then made

## FastQC
base per sequence cytosine percentage will be around 0% if only the OT and OB strands align, however the percentage will increase if CTOT or CTOB align so don't be alarmed by the high C content. Look for a large increase in cytosine percentage at the ends of the reads; these will need to be trimmed. Ensure all base percentages are not equal as this will possibly imply poor bisulfite conversion (?).


# PROBLEM SOLVING
## Clara's Primer Design
She designed the forward primer to include the REVERSE fluidigm sequencing primer sequence and the reverse primer to include the FORWARD fluidigm sequencing primer sequence. This is wrong and will make read1 look like read2 and vice versa (evident by the inclusion of the reverse-complemented sequence of the forward fluidigm sequencing primer being present within within R2 reads). So the resulting sequence will look like CTOB when it is actually OB. This also explains the high cytosine percentage in the per base sequence section of the fastqc files; as the apparent complementary strands (CTOB/CTOT) will naturally contain cytosine bases.

## Solution
I couldn't separate amplicons from sample FASTQ files and rename them to the correct read number. Instead, I had to use the --non_directional flag in Bismark to ensure that both the OT and CTOB (actually OB) reads align to the genome. Sam2Bed was also altered to ensure CTOB properly converted to BED.

# COMMANDS OF INTEREST
## coverage across chromosome
samtools view -Sb  <SAMFILE>  >  <BAMFILE>
samtools sort <BAMFILE> > <SORTED-BAMFILE>
## output in bedgraph format (--strand + or --strand -) 
bedtools genomecov -ibam <SORTED-BAMFILE> -bga > <COVFILE>

