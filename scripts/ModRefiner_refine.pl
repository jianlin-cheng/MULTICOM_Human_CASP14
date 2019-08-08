#! /usr/bin/perl -w
#
 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 sub select_based_on_GDT($$$$$);
 sub combine_init_refined($$$);
 sub produce($)
 {
	 my($path) = @_;
	 my($OUT)=new FileHandle ">$path";
	 print $OUT "$path is generated and running now\n";
	 $OUT->close();
 }

 if(@ARGV<5)
 {
    print "This script is going to use ModRefiner to refine a model. We generate 5 refined models, and select the one with the max GDT score compared with initial model, if none of them larger than 0.98, we use initial model.\n";
    print "perl $0 addr_real_run dir_ModRefiner addr_TM_score dir_models dir_output\n";
    print "For example:\n";
    print "perl $0 /home/rcrg4/Benchmark/script/Real_run_ModRefiner.pl /home/rcrg4/tools_CASP12/ModRefiner-l /home/rcrg4/tools/TM_score_old_version/TMscore_32 /home/rcrg4/Benchmark/test/models_for_refine ../test/models_refined3\n";
	
	exit(0);
 }
 my($addr_real) = abs_path($ARGV[0]);
 my($tool_modrefiner)=abs_path($ARGV[1]);
 my($tool_TM) = abs_path($ARGV[2]);
 my($dir_target)=abs_path($ARGV[3]);
 my($dir_out) = abs_path($ARGV[4]);

 -s $dir_out || system("mkdir $dir_out");

 if($dir_target ne $dir_out)
 {
	system("cp $dir_target/* $dir_out");         # first put all initial models
 }
 my($dir_tem) = $dir_out."/"."TEM";
 -s $dir_tem || system("mkdir $dir_tem");

 my($dir_0) = $dir_tem."/"."0";
 system("mkdir $dir_0");
 system("cp $dir_target/* $dir_0");
 my($dir_1) = $dir_tem."/"."1";
 system("mkdir $dir_1");
 system("cp $dir_target/* $dir_1");
 my($dir_2) = $dir_tem."/"."2";
 system("mkdir $dir_2");
 system("cp $dir_target/* $dir_2");



 my($file,$path_target,$check_path,$name,$path_seq,$path_out,$reference);
 my(@files);
 my(%hash) = ();
 opendir(DIR,"$dir_target");
 @files = readdir(DIR);
 foreach $file (@files)
 {
    if($file eq "." || $file eq "..")
    {
       next;
    }
	if(($dir_target eq $dir_out) && ($file eq "TEM"))
	{
		next;
	}
    $path_target = $dir_target."/".$file;
    $name = $file;
	if(not exists $hash{$name})
	{
		$hash{$name} = 1;
	}

	$check_path = $dir_target."/em".$name;
	if(-s $check_path)
	{# we already run it
		next;
	}
	$check_path = $dir_target."/running".$name;
	if(-s $check_path)
	{# some program is now processing it
		next;
	}

    ######## now run several refinement parallel #########
	chdir("$dir_0");
	$reference = $dir_0."/"."running.".$name;produce($reference);
	system("perl $addr_real $tool_modrefiner/emrefinement $dir_0 $tool_modrefiner $name $name 100 1 $reference >/dev/null 2>&1 &");

	chdir("$dir_1");
	$reference = $dir_1."/"."running.".$name;produce($reference);
	system("perl $addr_real $tool_modrefiner/emrefinement $dir_1 $tool_modrefiner $name $name 100 5234 $reference >/dev/null 2>&1 &");

	chdir("$dir_2");
	$reference = $dir_2."/"."running.".$name;produce($reference);
	system("perl $addr_real $tool_modrefiner/emrefinement $dir_2 $tool_modrefiner $name $name 100 452666 $reference >/dev/null 2>&1 &");

 }

 my($done) = 0;
 my($key);
 my($check0,$check1,$check2,$run0,$run1,$run2,$initial_model,$final_model);
 while(1)
 {# check each model
	 $done = 1;           # try to finish it
	 foreach $key (keys %hash) {
		 if($hash{$key} == 1)
		 {
			 $done=0;
			 $check0 = $dir_0."/running.".$key;
			 $check1 = $dir_1."/running.".$key;
			 $check2 = $dir_2."/running.".$key;
			 $run0 = $dir_0."/em".$key;
			 $run1 = $dir_1."/em".$key;
			 $run2 = $dir_2."/em".$key;
			 $initial_model = $dir_target."/".$key;
			 $final_model = $dir_out."/".$key;
			 
			 if( (!-s $check0) && (!-s $check1) && (!-s $check2))
			 {# all created 
				 select_based_on_GDT($run0,$run1,$run2,$initial_model,$final_model);
				 $hash{$key} = 0;
			 }
		 }
	 }
	 if($done == 1)
	 {# great, finish it
		 last;
	 }
	 sleep(200);

 }

 system("rm -R $dir_tem");

 sub cal_GDT($$$)
 {
	 my($ini,$s,$log)=@_;
	 my($IN,$OUT,$line);
	 my($score)=0;
	 my(@tem);
	 system("$tool_TM $ini $s > $log");
     $IN = new FileHandle "$log";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 @tem = split(/\s+/,$line);
		 if(@tem<2)
		 {
			 next;
		 }
		 if($tem[0] eq "GDT-score")
		 {
			 $score = $tem[2];
			 last;
		 }
	 }
	 $IN->close();
	 return $score;
 }

 sub select_based_on_GDT($$$$$)
 {
	 my($c0,$c1,$c2,$ini,$final)= @_;
	 my($IN,$line,$OUT,$log);
	 my(@tem);
	 my($s0,$s1,$s2);
	 $s0 = 0;
	 $s1 = 0;
	 $s2 = 0;

	 #### check model 0 ########
	 @tem = split(/\//,$c0);
	 $log = $dir_tem."/"."0_".$tem[@tem-1];
	 $s0 = cal_GDT($ini,$c0,$log);
	 #### check model 1 ########
	 @tem = split(/\//,$c1);
	 $log = $dir_tem."/"."1_".$tem[@tem-1];
	 $s1 = cal_GDT($ini,$c1,$log);
	 #### check model 2 ########
	 @tem = split(/\//,$c2);
	 $log = $dir_tem."/"."2_".$tem[@tem-1];
	 $s2 = cal_GDT($ini,$c2,$log);

   
     my($max,$index_max);
	 $max = 0;
	 $index_max = -1;
	 if($s0>$max)
	 {
		 $max = $s0;
		 $index_max = $c0;
	 }
	 if($s1>$max)
	 {
		 $max = $s1;
		 $index_max = $c1;
	 }
	 if($s2>$max)
	 {
		 $max = $s2;
		 $index_max = $c2;
	 }

	 if($max>=0.98)
	 {# working
		 combine_init_refined($ini,$index_max,$final);      # we need to keep some head information and use the refined ATOM information
		 print "Selected GDT-TS score before and after refinement for $final is $max\n";
		 #system("cp $index_max $final");     # great
	 }
	 else
	 {
		 print "Selected GDT-TS score before and after refinement for $final is 1\n";
	 }
 }

 sub combine_init_refined($$$)
 {# combine the information from the initial model and refined model 
	 my($ini_pdb,$refine_pdb,$final) = @_;
	 my($OUT,$IN,$line);
	 my(@tem);
	 $OUT = new FileHandle ">$final";
	 $IN = new FileHandle "$ini_pdb";
	 while(defined($line=<$IN>))
	 {# 
		 chomp($line);
		 @tem = split(/\s+/,$line);
		 if(@tem<1)
		 {
			 next;
		 }
		 if($tem[0] eq "ATOM")
		 {
			 last;
		 }
		 print $OUT $line."\n";
	 }
	 $IN->close();
	 $IN = new FileHandle "$refine_pdb";
	 while(defined($line=<$IN>))
	 {# just copy the ATOM line
		 @tem = split(/\s+/,$line);
		 if(@tem<1)
		 {
			 next;
		 }
		 if($tem[0] eq "ATOM")
		 {
			 print $OUT $line;
		 }
	 }
	 $IN->close();
	 print $OUT "TER\n";
	 print $OUT "END";
	 $OUT->close();
 }
