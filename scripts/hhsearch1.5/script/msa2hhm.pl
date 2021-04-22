#!/usr/bin/perl -w
##########################################################################
#Use hhmake32 to create hhm profiles from msa and query 
#input: script dir, hmmer dir, query file(fasta), query(msa), output file
#Author: Jianlin Cheng
#Modified from msa2hmm.pl
#Date: 7/25/2005
##########################################################################
if (@ARGV != 5)
{
	die "need five parameters: script dir, hhsearch dir(hhsearch), query file(fasta), query msa(from blast), output file.\n";
}
$script_dir = shift @ARGV;
$hhsearch_dir = shift @ARGV;
-d $script_dir || die "can't find script dir.\n";
-d $hhsearch_dir || die "can't find hhsearch dir.\n";

$query_fasta = shift @ARGV;
-f $query_fasta || die "can't find query fasta file.\n";
open(QUERY, $query_fasta);
$code1 = <QUERY>;
chomp $code1; 
$code1 = substr($code1, 1);
$seq1 = <QUERY>;
chomp $seq1; 
close QUERY;

$query_msa = shift @ARGV;
-f $query_msa || die "can't find query msa file.\n";

$out_file = shift @ARGV;

#convert fasta and msa to gde format multiple alignments
system("$script_dir/msa2gde.pl $query_fasta $query_msa fasta $query_msa.fas");

#create hmm from msa
system("$hhsearch_dir/hhmake32 -i  $query_msa.fas -o $out_file >/dev/null"); 

`rm $query_msa.fas`; 




