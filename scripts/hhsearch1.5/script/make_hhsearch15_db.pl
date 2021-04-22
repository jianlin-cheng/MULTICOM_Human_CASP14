#!/usr/bin/perl -w
###########################################################################
#Create the hmm database for hhsearch15
#Inputs: prosys_database dir, hhsearch15 dir, output dir, output db name
#Output: hmm files for sor90 proteins, a joined db
#Author: Jianlin Cheng
#Start date: 12/30/2009
###########################################################################

if (@ARGV != 5)
{
	die "need 5 parameters: script dir (hhsearch15), prosys_db dir, hhsearch15 dir, output dir, output db name.\n";
}

$script_dir = shift @ARGV;
$prosysdb_dir = shift @ARGV;
$hhsearch15_dir = shift @ARGV;
$output_dir = shift @ARGV;
$hhsearchdb = shift @ARGV;

-d $script_dir || die "can't find script dir: $script_dir.\n";
-d $prosysdb_dir || die "can't find prosys db dir: $prosysdb_dir.\n";  
-d $hhsearch15_dir || die "can't find hhsearch dir: $hhsearch15_dir.\n";
-d $output_dir || die "can't find output dir: $output_dir.\n";
$hhsearchdb = $output_dir . "/$hhsearchdb"; 
-f $hhsearchdb || `>$hhsearchdb`; 

$src_db = $prosysdb_dir . "/fr_lib/sort90"; 
-f $src_db || die "can't find sort90: $src_db.\n";
$align_dir = $prosysdb_dir . "/library/"; 
-d $align_dir || die "can't find $align_dir.\n";

open(FASTA, $src_db) || die "can't read fasta file.\n";
@fasta = <FASTA>;
close FASTA;
$count = 0; 

#create a temporary addition database
`>$hhsearchdb.add`;

while (@fasta)
{
	$name = shift @fasta;
	chomp $name;
	if ($name =~ /^>(.+)/)
	{
		$name = $1;
	}
	else
	{
		print "$name\n";
		die "fasta format error.\n"; 
	}
	$seq = shift @fasta;

	#check if alignment file exists
	$align_file = "$align_dir/$name.align";
	-f $align_file || die "can't find alignment file: $align_file.\n"; 

	#check if hmm15 file exists  
	$hmm_file = "$output_dir/$name.hmm15";
	if (-f $hmm_file) 
	{ 
		print "$name exists in the database. Skipped.\n";
		next; 
	}

	#create a temporary file
	open(TMP, ">$name.fasta.tmp") || die "can't create temporary file.\n";
	print TMP ">$name\n";
	print TMP $seq;
	close TMP;

	#create hmm files
	#convert fasta and msa to gde format multiple alignments
	system("$script_dir/msa2gde.pl $name.fasta.tmp $align_file fasta $name.tmp.fas");
	print "make hmm for $name...\n";
	#create hmm from msa
	system("$hhsearch15_dir/hhmake -i  $name.tmp.fas -o $hmm_file.tmp >/dev/null"); 
	#add secondary structure into hmm
	$seq_file = $prosysdb_dir . "/seq/$name.seq"; 
	if (! -f $seq_file)
	{
		print "can't find file $seq_file. No secondary structure is added.\n";
		`cp $hmm_file.tmp $hmm_file`; 
	}
	else
	{
		system("$script_dir/addtss2hhm.pl $seq_file $hmm_file.tmp > $hmm_file");
	}

	#add the file into the database
	print "add $hmm_file into the database.\n";
	`cat $hmm_file >> $hhsearchdb.add`; 
	$count++; 

	`rm $name.tmp.fas`; 
	`rm $hmm_file.tmp`; 
	`rm $name.fasta.tmp`; 
}
if ($count > 0)
{
	`cat $hhsearchdb.add >> $hhsearchdb`; 
}
print "The database $hhsearchdb has been updated. $count templates are added.\n";

