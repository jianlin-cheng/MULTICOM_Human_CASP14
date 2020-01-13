#!/usr/bin/perl -w

##########################################################################
#The main script of template-based modeling using hhsearch and combinations
#Inputs: option file, fasta file, output dir.
#Outputs: hhsearch output file, local alignment file, combined pir msa file,
#         pdb file (if available, and log file
#Author: Jianlin Cheng
#Modifided from cm_main_comb_join.pl
#Date: 10/16/2007
##########################################################################

my $GLOBAL_PATH;
BEGIN { $GLOBAL_PATH ='/home/jh7x3/MULTICOM_Human_CASP14/multicom/src/meta/hhsearch1.5/'; }
if (@ARGV != 4)
{
	die "need three parameters: option file, sequence file, output dir.\n";
}

$option_file = shift @ARGV; #/home/jh7x3/CASP13_development/DeepSF-3D/version-V2-2017-12-05/deepsf3d_tools/hhsearch_suite/scripts/hhsearch1.5_option
$fasta_file = shift @ARGV; #/home/jh7x3/test/casp1.fa
$work_dir = shift @ARGV; #/home/jh7x3/test/casp1_deepsf
$hhsearchdb = shift @ARGV; #

=pod
#make sure work dir is a full path (abosulte path)
$cur_dir = `pwd`;
chomp $cur_dir;
#change dir to work dir
if ($work_dir !~ /^\//)
{
	if ($work_dir =~ /^\.\/(.+)/)
	{
		$work_dir = $cur_dir . "/" . $1;
	}
	else
	{
		$work_dir = $cur_dir . "/" . $work_dir;
	}
	print "working dir: $work_dir\n";
}
=cut
-d $work_dir || die "working dir doesn't exist.\n";

`cp $fasta_file $work_dir`;
`cp $option_file $work_dir`;
chdir $work_dir;

#take only filename from fasta file
$pos = rindex($fasta_file, "/");
if ($pos >= 0)
{
	$fasta_file = substr($fasta_file, $pos + 1);
}

$meta_dir=$GLOBAL_PATH;
$hhsearch_dir="/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/hhsearch1.5.0/";
#$hhsearchdb=$GLOBAL_PATH.'/deepsf3d_tools/hhsearch_suite/hhsearch1.5.0/hhsearch15db';
#$meta_common_dir=$GLOBAL_PATH.'/common_scripts';


#check fast file format
open(FASTA, $fasta_file) || die "can't read fasta file.\n";
$name = <FASTA>;
chomp $name;
$seq = <FASTA>;
chomp $seq;
close FASTA;
if ($name =~ /^>/)
{
	$name = substr($name, 1);
}
else
{
	die "fasta foramt error.\n";
}

#check if local alignment file exist.
if (-f "$fasta_file.local")
{
        print "The local alignment file exists, so directly go to alignment refinement and model generation.\n";
        goto MULTICOM;
}

################################################################
#blast protein and nr(if necessary) to find homology templates.
#assumption: pdb database name is: pdb_cm
#	     nr database name is: nr
#################################################################

print "Generate alignments from the nr database...\n";
print("perl $meta_dir/scripts/buildali.pl $fasta_file >/dev/null\n\n");
system("perl $meta_dir/scripts/buildali.pl $fasta_file >/dev/null");

#get file name prefix
$idx = rindex($fasta_file, ".");
if ($idx > 0)
{
	$filename = substr($fasta_file, 0, $idx);
}
else
{
	$filename = $fasta_file;
}
-f "$name.a3m" || die "Alignment file $filename.a3m is not created.\n";

#conver raw alignment to hhm
print "convert alignment to HMM...\n";
print("$hhsearch_dir/hhmake -i $filename.a3m -o $filename.hhm\n\n");
system("$hhsearch_dir/hhmake -i $filename.a3m -o $filename.hhm");

#calibrate the hhm model
print "calibrate HMM model...\n";
print("$hhsearch_dir/hhsearch -cal -i $filename.hhm -d $hhsearch_dir/cal.hhm\n\n");
system("$hhsearch_dir/hhsearch -cal -i $filename.hhm -d $hhsearch_dir/cal.hhm");

#search shhm against the database
print "search HMM against HMM database...\n";
print("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb\n\n");
system("$hhsearch_dir/hhsearch -i $filename.hhm -d $hhsearchdb");
#output file is: name.hhr

print "generate ranking list...\n";
print("perl $meta_dir/scripts/rank_templates.pl $filename.hhr $work_dir/$name.rank\n\n");
system("perl $meta_dir/scripts/rank_templates.pl $filename.hhr $work_dir/$name.rank");

#parse the blast output
print "parse hhsearch output...\n";
print("perl $meta_dir/scripts/parse_hhsearch.pl $filename.hhr $fasta_file.local\n\n");
system("perl $meta_dir/scripts/parse_hhsearch.pl $filename.hhr $fasta_file.local");


MULTICOM:
print "Comparative modelling for $fasta_file is done.\n";
