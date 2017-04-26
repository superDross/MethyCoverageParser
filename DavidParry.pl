#!/usr/bin/env perl 
#David A. Parry, 17/05/2016
##Edited regex for CpG file identification

#Written for Danny Laurent to parse output from bismark/bedtools analysis of 
#methylation data
#Requires as the first argument a primer file giving the coordinates of the 
#regions analysed and the original strand (either OT or OB) e.g.
#chr1    1000    2000    OT
#chr1    5000    6000    OB

#and as the 2nd to Nth arguments, directories containing the results folders, 
#four files per sample for OT, OB, meth and unmeth results. 

#TODO - write more detailed documentation if this it to be more widely/frequenctly used

use strict;
use warnings;
use Data::Dumper;

if (@ARGV < 2){
    die "Usage: perl $0 primers.txt methylation_results_directory [meth_results_dir2 ... ]\n";
}
my $primers = shift;
open (my $PRIMERS, $primers) or die "Could not open $primers for reading: $!\n";

my %regions;

while (my $line = <$PRIMERS>){
    chomp $line;
    next if not $line;
    my @split = split("\t", $line); 
    if (@split != 4){
        die "Required 4 fields in primer line, found " . scalar(@split) . " for line:\n$line\n";
    }
    my $coords = join("\t", @split[0..2]); 
    my $strand; 
    if (uc($split[3]) eq 'OT'){
        $strand = 'OT';
    }elsif (uc($split[3]) eq 'OB'){
        $strand = 'OB';
    }else{
        die "Don't recognise fourth field \"$split[3]\" in primer file.\n";
    }
    $regions{$strand}->{$coords} = undef;
}
close $PRIMERS;

my %samples = (); 
while (my $dir = shift){
    opendir(my $DIR, $dir) or die "Could not read directory $dir: $!\n";
    while (my $f = readdir($DIR)){
      #if ($f =~ /CpG_(O[TB])_(.+)\..*_bismark_pe\.txt_bismark_CpG_(meth|unmeth)\.BED_output\.txt/){
        if ($f =~ /CpG_(O[TB])_(.+)\..*_bismark.*pe\.txt_bismark_CpG_(meth|unmeth)\.BED/){
            my $strand = $1;
            my $sample = $2;
            my $meth   = $3;
            if (exists $samples{$sample}->{$meth}->{$strand}){
                die "Duplicate sample ($sample), methylation status ($meth) and strand ($strand) found!\n";
            }
            $samples{$sample}->{$meth}->{$strand} = "$dir/$f";
        }
    }    
}
die "No input files found! " if not keys %samples;
my %output = ();
my @samps = ();
foreach my $s (sort keys %samples){
    push @samps, $s;
    if (keys %{$samples{$s}} != 2){
        die "Expected two methylation statuses for $s, found " . scalar (keys %{$samples{$s}}) . "\n";
    }
    foreach my $meth (keys  %{$samples{$s}}  ) {
        if (keys %{$samples{$s}->{$meth}} != 2){
            die "Expected two strand files for $s, found " . scalar (keys %{$samples{$s}->{$meth}}) . "\n";
        }
        foreach my $strand (keys %{$samples{$s}->{$meth}}){
            appendOutput($strand, $meth, $samples{$s}->{$meth}->{$strand});
        }
    }
}

print "#Chrom\tStart\tEnd\tStrand\tMethylation\t" . join("\t", @samps) . "\n";
foreach my $strand (sort keys %output){
    foreach my $reg (sort keys %{$output{$strand}}){
        foreach my $meth (sort keys %{$output{$strand}->{$reg}}){
            print "$reg\t$strand\t$meth\t" . join("\t", @{$output{$strand}->{$reg}->{$meth}}) . "\n";
        }
    }
}

#################################################
sub appendOutput{
    my $strand = shift;
    my $meth = shift;
    my $file = shift;
    open (my $IN, $file) or die "Can't open $file for reading: $!\n";
    while (my $line = <$IN>){
        chomp $line;
        next if not $line;
        my @split = split("\t", $line); 
        if (@split < 4){
            die "Required 4 fields in $file, found" . scalar(@split) . " for line:\n$line";
        }
        my $coords = join("\t", @split[0..2]); 
        if (not exists $regions{$strand}->{$coords}){
            next ; #skip if region not for this strand
        }
        push @{$output{$strand}->{$coords}->{$meth}}, $split[3];
    }
    close $IN;
}
        
