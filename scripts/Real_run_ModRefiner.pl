#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 sub select_based_on_GDT($$$$$$$);
 sub combine_init_refined($$$);

 if(@ARGV<4)
 {
    print "This script is going to use ModRefiner to refine a model. We just submit and run the job.\n";
    print "perl $0 addr_ModRefiner dir_models dir_ModRefiner name name 100 random addr_delete\n";
    print "For example:\n";
	exit(0);
 }
 my($addr_ModRefiner)=abs_path($ARGV[0]);
 my($dir_models) = abs_path($ARGV[1]);
 my($dir_ModRefiner)=abs_path($ARGV[2]);
 my($name) = $ARGV[3];
 #my($name) = $ARGV[4];
 my($per) = abs_path($ARGV[5]);
 my($ran) = abs_path($ARGV[6]);
 my($reference) = abs_path($ARGV[7]);

 system("$addr_ModRefiner $dir_models $dir_ModRefiner $name $name $per $ran");
 system("rm $reference");
