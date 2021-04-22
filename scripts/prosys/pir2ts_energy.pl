#!/usr/bin/perl -w
##############################################################################
#common interface to the script of model generation using Modeller 7v7 or
#Modeller 9v7
#Assumption: the other scripts of running modeller are in the same directory
#as this one
############################################################################# 

$prosys_dir = "/home/chengji/software/prosys/script";
use Cwd 'abs_path';
$script_path =  abs_path($0);
$ridx = rindex($script_path, "/");
$prosys_dir = substr($script_path, 0, $ridx); 
#print "$prosys_dir\n";

if (@ARGV != 5)
{
	die "need five parameters: modeller path, atom file dir, working dir, msa file, number of models to simulate.\n"; 
}

$modeller_dir = shift @ARGV;
$atom_dir = shift @ARGV;
$work_dir = shift @ARGV;
$msa_file = shift @ARGV;
$model_num = shift @ARGV;

if ($modeller_dir =~ /7v7/)
{
	print "Run Modeller 7v7...\n";
	system("$prosys_dir/pir2ts_energy_7v7.pl $modeller_dir $atom_dir $work_dir $msa_file $model_num"); 	
}
elsif ($modeller_dir =~ /9v7/)
{
	print "Run Modeller 9v7...\n";
	system("$prosys_dir/pir2ts_energy_9v7.pl $modeller_dir $atom_dir $work_dir $msa_file $model_num"); 	
	
}
else #run modeller version 16
{
	print "Run Modeller version 9.16...\n";	
	system("$prosys_dir/pir2ts_energy_9v16.pl $modeller_dir $atom_dir $work_dir $msa_file $model_num"); 	
}

