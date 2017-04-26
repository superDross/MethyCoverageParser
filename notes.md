# I: generating SAM files
1 - Convert the genome to BS genome
2 - Check the BS conversion efficiency
3 - Trim CS*rc adapters from FastQs
4 - Fastqc, check they aren't shit
5 - Align to BS-genome to create SAM files
6 - Check mapping efficiency 

SAM files used as input for all subsequent processes

# II: CpG methylation coverage
1 - Produce a BED file which contains chromosome ranges of reads that are 
	proper pairs and contain a methylated CpG (Duncan.py)
2 - Compare the CpG methylation calls against Amplicon Locations BED file to get coverage 
	data(betools coverage). 
3 - Transform into a dataframe (CSV) (CoverageParse.py)


# III: CpG methylation per amplicon
# WHY? looking for overall differential methylation in the amplicon (so mean methylation % for entire amplicon).
# This is what Duncan does but we don't want this; if one site is largely differentially methylated and only
# one site, then the mean % will drop substantially. We will therefore miss this highly differemtially methylated
# site at the analysis stage.
1 - Extract the methylation calls for every C in the SAM file and the position of every C is 
	written into 3 seperate files depedning on context (CpG, CHG or CHH) using BME.
2 - The BME output containing the methylated C call in CpG contexts is then split into two
	files; one containing methylated CpG calls for every available chromosome position in the bed 
	file and the other containing the unmethylated conterpart (Duncan.pl).
3 -	Compare ALL methylation calls against Amplicon Locations BED file. The resulting BED file
	allows you to determine the methylation frequency per amplicon (repurposed 
	usage of betools coverage).
4 - Transform into a dataframe (CSV) (DavidParry.pl)


# IV: CpG methylation per site
# WHY? We are loooking for markers of methylation that are highly differnt in tumours compared to leukocytes.
# Looking at a site by site basis (oppossed to an amplicon by amplicon basis).
1 - Extract every C position across the SAM file and output it in a BED format with the methylation 
	percentage for that position in an additional fourth column (BME --bedgraph).
2 - Transform into Dataframe (CSV) (Sophie.py)



