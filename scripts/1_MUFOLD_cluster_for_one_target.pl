#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';

  if(@ARGV<3)
  {
	  print "This script use MUfold clustering tool, and process one target, get the output without processing any thing!\n";
	  print "perl $0 dir_targets addr_MUFOLD_cluster addr_output\n";

	  print "For example:\n";
	  print "perl $0 ../data/casp10_human_all_targets/T0644 /home/rcrg4/tool/MUfold_cluster/MUFOLD_CL ../test/MUFOLD_T0644_clustering_txt\n";
          print "\n********** CASP11 human prediction **********\n";
          print "perl $0 ../data/CASP11_prediction_human/T0759 /home/rcrg4/tool/MUfold_cluster/MUFOLD_CL ../result/CASP11_MUFOLD_human/T0759_clustering_txt\n";
	  exit(0);
  }

  my($dir_input)=abs_path($ARGV[0]);
  my($tool)=abs_path($ARGV[1]);
  my($addr_output)=abs_path($ARGV[2]);
  
  my($dir_output) = $addr_output."_tmp";
  -s $dir_output || system("mkdir $dir_output");

  chdir($dir_output);
  
  my(@tem) = split(/\//,$dir_input);
  my($name)=$tem[@tem-1];
  ########## write the list file ################
  my($list) = $dir_output."/".$name.".list";
  my($path,$IN,$OUT,$file,$line);

  my(@files);
  $OUT = new FileHandle ">$list";
  opendir(DIR,"$dir_input");
  @files=readdir(DIR);
  foreach $file (@files) {
	  if($file eq "." || $file eq "..")
	  {
		  next;
	  }
	  $path = $dir_input."/".$file;
	  print $OUT $path."\n";
  }
  $OUT->close();

  ######### run clustering ##########
  if(system("$tool -L $list"))
  {
	  print "$tool -L $list fails!\n";
	  exit(0);
  }

  my($c_out) = $dir_output."/".$name.".log";         # this is the output file 
  if(system("cp $c_out $addr_output"))
  {
	  print "cp $c_out $addr_output fails!\n";
	  exit(0);
  }
  system("rm -R $dir_output");

