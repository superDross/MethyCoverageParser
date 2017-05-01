#Created by Duncan Sproul
#takes the results of bismark methylation extractor and creates two bed files;
#one for methylated CpGs and another for unmethylated CpGs
use warnings;

# Takes bismark methylation extractor output
# Converts to 2 BED files, one meth CpG, one unmeth

my $file_id = $ARGV[0];
chomp $file_id;

my $infile = $file_id;

my $methoutfile = $file_id."_bismark_CpG_meth.BED";
my $unmethoutfile = $file_id."_bismark_CpG_unmeth.BED";

open (INFILE, "$infile");
open (METHOUTFILE, ">$methoutfile");
open (UNMETHOUTFILE, ">$unmethoutfile");

my @line = ();
my $chr = 0;
my $start = 0;
my $end = 0;
my $type = "";

# Read in header
<INFILE>;

while (<INFILE>)
{
	chomp;
	@line = split("\t", $_);
	$chr = $line[2];
	$start = $line[3];
	$end = $start + 1;
	$type = $line[4];
	
	if ($type eq "Z")
	{
		print METHOUTFILE ($chr,"\t",$start,"\t",$end,"\n");	
	}
	elsif ($type eq "z")
	{
		print UNMETHOUTFILE ($chr,"\t",$start,"\t",$end,"\n");
	}
}

close INFILE;
close METHOUTFILE;
close UNMETHOUTFILE;

