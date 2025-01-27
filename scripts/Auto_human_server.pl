#! /usr/bin/perl
#
 require 5.003; # need this version of Perl or newer
use lib "/home/tools/MIME-Lite-2.117/lib/";
use email;
use MIME::Lite;
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 #use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 use Scalar::Util qw(looks_like_number);
 sub select_models_MUFOLD($$$$$);
 sub get_seq($);
 sub get_bottom_10_percent($);
 sub select_based_on_GDT($$$$$$$);
 sub combine_init_refined($$$);
 #################################################
# Set the environment variables
#################################################
$ENV{'PATH'}.=':/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/software/jdk1.7.0_01/bin';
$ENV{'CLASSPATH'}.=':/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/software/3Drefine:/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/software/3Drefine/programs';
#$tool_TM = '/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/tm_score/TMscore_32';
$tool_TM = '/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/TMscore';
	if(@ARGV<3)
	{
		print "This power script will only need two inputs : target name, fasta sequence! It will calculate the concensus score, and use clustering information to find five best models, further more, the script will use modeller to re-combine the model, and use my script to add the local quality, even send the generated prediction automatically! \n";

		print "perl $0 targetname fasta_sequence dir_output (dir_models, this is optional, if you provide, I will not go to the CASP11 website to download the tarball)\n";

		print "For example:\n";
		print "\n********* CASP12 human prediction *************\n";
		print "perl $0 T0759 ../test/T0759.fasta ../test/test_human_serverT0759 ../test/filtered-T0759\n";
		print "perl $0 T0765 ../data/T0765.fasta /home/rcrg4/HT0765\n";
		exit(0);
	}

	####### first use consensus QA script to get the consensus score #######
	my($targetname) = $ARGV[0];
	my($addr_fasta) = $ARGV[1];
	my($dir_output) = $ARGV[2];
	my($contactfile) = $ARGV[3];
	-s $dir_output || system("mkdir $dir_output");
	
	if(!defined($contactfile))
	{
		$contactfile='NULL';
	}
	chdir($dir_output);  
	my($tar) = "NULL";
	if(@ARGV > 4)
	{	# you provide the models folder, so no need to download from the website
		$tar = abs_path($ARGV[4]);
	}
	else
	{
	 $tar = "http://www.predictioncenter.org/download_area/CASP12/server_predictions/$targetname.3D.srv.tar.gz";
	}

	$dir_models = "NULL";
	#my($sequence) = get_seq($addr_fasta);           # get the sequence from fasta sequence file
	
	if(!(-e $addr_fasta))
	{
		$problem = "Failed to find sequence $addr_fasta\n";
		sendlog($problem);
		die;
		
	}
  
	if($tar=~m/http/)
	{
		system("wget $tar");
		my($idx) = rindex($tar, "/");
		my($ball_name) = substr($tar, $idx+1);
		system("tar xzf $ball_name");  #should be un-commented

		$dir_models = $dir_output."/".$targetname;       # this is the original model folder!
	}
	else
	{
		$dir_models = abs_path($tar);
	}

	if(!-s $dir_models)
	{
		$problem = "The tarball location has some problem for target $targetname, check $tar, input is ".@ARGV."!";
		sendlog($problem);
		die;
	}

	
 my($dir_tem) = $dir_output."/"."TEM";
 -s $dir_tem || system("mkdir $dir_tem");

  my($auto_all) = "/home/jh7x3/MULTICOM_Human_CASP14/DeepRank/bin/run_DeepRank.sh"; # use this in casp13

  if(!-s $auto_all)
  {
    print "Error, not existing $auto_all!\n";
    $problem = "Error, not existing $auto_all!\n";
	sendlog($problem);
	die;
    exit(0);
  }

=pod
  my($auto_all_loss0048) = "/home/casp13/Human_QA_package/scripts/run_CASP13_HumanQA_humanqalit_fea18_nosubfix.sh"; # use this in casp13
  #my($auto_all) = "/home/casp13/Human_QA_package/scripts/run_CASP13_HumanQA_humanqalit_fea19_nosubfix.sh"; 

  if(!-s $auto_all_loss0048)
  {
    print "Error, not existing $auto_all_loss0048!\n";
    $problem = "Error, not existing $auto_all_loss0048!\n";
	sendlog($problem);
	die;
    exit(0);
  }
=cut


  $eva_dir = "$dir_output/eva";
  -s $eva_dir || system("mkdir $eva_dir");
  
  
  
	my($name)= $targetname;
	open(MLIST, ">$dir_output/$name.mlist");
	opendir(MDIR, $dir_models); 
	my @models = readdir(MDIR);
	closedir(MDIR);
	foreach my $model (@models){
	 if($model eq '.' || $model eq '..'){
				next;
	 }
	 print MLIST "$dir_models/$model\n";
	}
	close(MLIST);


	###########FILTER MODELS#########
	#filter out redudant models from the same group, changed to use version 2 on July 9, 2012. ##
	my($same_group_log) = $dir_output."/"."Same_group.log";
	print("/home/jh7x3/MULTICOM_Human_CASP14/scripts/filter_model_same_group_v2.pl $name.mlist $name.nlist  /home/jh7x3/MULTICOM_Human_CASP14/mutlicom/tools/tm_score2/TMscore > $same_group_log\n\n");
	system("/home/jh7x3/MULTICOM_Human_CASP14/scripts/filter_model_same_group_v2.pl $name.mlist $name.nlist  /home/jh7x3/MULTICOM_Human_CASP14/mutlicom/tools/tm_score2/TMscore > $same_group_log");
	my($ren_filter) = $dir_output."/"."filtered_same_group_model/";     # save the filtered model 
	-s $ren_filter || system("mkdir $ren_filter");
	open(REN,"$name.nlist");
	my(@ren_models) = <REN>;
	close(REN);
	foreach my $ren_each (@ren_models)
	{
		chomp($ren_each);
		system("cp $ren_each $ren_filter");
	}


  ### filter the partial models and run qa
  print "\n\n### filter the partial models and run qa\n\n";
  my($final_ranking1) = $eva_dir."/"."HumanQA_gdt_prediction.txt";                 # this is the final ranking file 
  if(-e $final_ranking1)
  {
		print "$final_ranking1 is already generated\n\n";
  }else{
	  print(" $auto_all $targetname $addr_fasta $ren_filter $eva_dir $contactfile &> $dir_output/run_human_casp13.eva\n\n");
	  if(system(" $auto_all $targetname $addr_fasta $ren_filter $eva_dir $contactfile &> $dir_output/run_human_casp13.eva"))
	  {
		print " $auto_all $targetname $addr_fasta $ren_filter $eva_dir  $contactfile &> $dir_output/run_human_casp13.eva fails!\n";
		$problem = " $auto_all $targetname $addr_fasta $ren_filter $eva_dir  $contactfile &> $dir_output/run_human_casp13.eva fails!\n";
		sendlog($problem);
		exit(0);
	  }
  }
  
=pod 
  #### run the second qa version, loss = 0.048, developed during casp13
   $eva_loss0048_dir = "$dir_output/eva_loss0048";
  -s $eva_loss0048_dir || system("mkdir $eva_loss0048_dir");
  my($final_ranking2) = $eva_loss0048_dir."/"."HumanQA_gdt_prediction_loss0048.txt";                 # this is the final ranking file 
  if(-e $final_ranking2)
  {
		print "$final_ranking2 is already generated\n\n";
  }else{
		
		`cp -ar $eva_dir/ALL_scores  $eva_loss0048_dir`;
	  print(" $auto_all_loss0048 $targetname $addr_fasta $ren_filter $eva_loss0048_dir $contactfile &> $dir_output/run_human_casp13_loss0048.eva\n\n");
	  if(system(" $auto_all_loss0048 $targetname $addr_fasta $ren_filter $eva_loss0048_dir $contactfile &> $dir_output/run_human_casp13_loss0048.eva"))
	  {
		print " $auto_all_loss0048 $targetname $addr_fasta $ren_filter $eva_loss0048_dir  $contactfile &> $dir_output/run_human_casp13_loss0048.eva fails!\n";
		$problem = " $auto_all_loss0048 $targetname $addr_fasta $ren_filter $eva_loss0048_dir  $contactfile &> $dir_output/run_human_casp13_loss0048.eva fails!\n";
		sendlog($problem);
		exit(0);
	  }
  }  
=cut
  
  
  
  
  
  #$score_log_file = "$dir_output/run_human_casp13.eva";
  #print "!!!!! Human evaluation done, check the log file $score_log_file\n\n";

  
  -s $final_ranking1 || die "Cannot find $final_ranking1\n";
  #my($filter_partial) = "/home/casp13/Human_TS/scripts/filter_partial.pl";
  $final_ranking_old = $eva_dir."/"."HumanQA_gdt_prediction_sort.txt";
  print("perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/sort_deep_qa_score.pl $final_ranking1 $final_ranking_old\n\n"); 
  system("perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/sort_deep_qa_score.pl $final_ranking1 $final_ranking_old"); 

=pod  
  $final_ranking = $eva_loss0048_dir."/"."HumanQA_gdt_prediction_loss0048_sort.txt"; # use this one as rerank method
  print("perl /home/casp13/Human_TS/scripts/sort_deep_qa_score.pl $final_ranking2 $eva_loss0048_dir/HumanQA_gdt_prediction_loss0048_sort.txt\n\n"); 
  system("perl /home/casp13/Human_TS/scripts/sort_deep_qa_score.pl $final_ranking2 $eva_loss0048_dir/HumanQA_gdt_prediction_loss0048_sort.txt"); 
=cut
  
  #### (1) filter out the model whose sequence not match the original sequence, saved in $eva_dir."/mod2"

  ####  the final scoring file is at output folder with the name Final_ranking.txt, ren_filtered_model is the folder for models ####
  my($filtered_model) = $eva_dir."/mod2";
  if(!-s $filtered_model)
  {
    print "check the output $auto_all output, $filtered_model!\n";
    exit(0);
  }
=pod  
  if(system("perl $filter_partial $addr_fasta $final_ranking1 $filtered_model $final_ranking"))
  {
    print "perl $filter_partial $addr_fasta $final_ranking1 $filtered_model $final_ranking fails!\n";
    $problem = "perl $filter_partial $addr_fasta $final_ranking1 $filtered_model $final_ranking fails!\n";
	sendlog($problem);
    exit(0);
  }
=cut 
  
  my($score_novel) = $eva_dir."/"."HumanQA_gdt_prediction_sort.txt";    # this is the NOVEL server prediction 
  #my($score_novel) = $eva_loss0048_dir."/"."HumanQA_gdt_prediction_loss0048_sort.txt";    # this is the NOVEL server prediction 
  -s $score_novel || die "cannot find the server NOVEL prediction : $score_novel\n";  

  ######### now use mufold the to clustering #####
  print "\n\n######### now use mufold the to clustering #####\n\n";
  my($tool_mufold) = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/1_MUFOLD_cluster_for_one_target.pl";
  if(!-s $tool_mufold)
  {
    print "not exiting $tool_mufold!\n";
    exit(0);
  } 
  my($mucluster) = $dir_output."/"."MUFOLD_cluster";
  print("perl $tool_mufold $filtered_model /home/jh7x3/MULTICOM_Human_CASP14/tools/MUfold_cluster/MUFOLD_CL $mucluster > /dev/null 2>&1\n\n");
  if(system("perl $tool_mufold $filtered_model /home/jh7x3/MULTICOM_Human_CASP14/tools/MUfold_cluster/MUFOLD_CL $mucluster > /dev/null 2>&1"))
  {
    print "perl $tool_mufold $filtered_model /home/jh7x3/MULTICOM_Human_CASP14/tools/MUfold_cluster/MUFOLD_CL $mucluster fails!\n";
    exit(0);
  }

  
  my(@bottom_models)=();
  @bottom_models = get_bottom_10_percent($score_novel);           # based on the novel server prediction, get 10% bottom models
  my($bottom_models) = $dir_output."/"."Bottom_10_percent_models.txt";
  my($i);
  my($OUT) = new FileHandle ">$bottom_models";
  for($i=0;$i<@bottom_models;$i++)
  {
    print $OUT $bottom_models[$i]."\n";
  }
  $OUT->close();  
  ######## get the consensus ranking scores ######
  my(%hash) = ();
#  print @bottom_models."\n"."@bottom_models\n";   
  my(%hash_bottom)=();
 
  for($i=0;$i<@bottom_models;$i++)
  {
     $hash_bottom{$bottom_models[$i]} = 1;
  }
  my($IN,$line);
  my(@tem);
  $IN = new FileHandle "$final_ranking";
  while(defined($line=<$IN>))
  {
     chomp($line);
     @tem = split(/\s+/,$line);
     if(@tem<2)
     {
       next;
     }
     $hash{$tem[0]} = $tem[1];               #model name , and the final ranking score
  }
  $IN->close(); 

  ###### use MUFOLD clustering information and my NOVEL prediction, get the top 5 best models, and re-rank the ranking file ##
  my($re_rank) = $dir_output."/"."Re_ranking.txt";
  print "\n\n###### use MUFOLD clustering information and my NOVEL prediction, get the top 5 best models, and re-rank the ranking file, saved to $re_rank ##\n\n";

  select_models_MUFOLD(\%hash_bottom,\%hash,$mucluster,$final_ranking,$re_rank);   ### be_careful, the initial rank must be ranked.

  
  my(@top5_models) = ();
  my($i_top5)=0;
  $IN = new FileHandle "$re_rank";
  while(defined($line=<$IN>))
  {
    chomp($line);
    @tem = split(/\s+/,$line);
    if($i_top5>=5)
    {
      last;
    }
    if(@tem<2)
    {
      print "Should not happen, check $re_rank, line : $line\n";
      next;
    }
    $top5_models[$i_top5++]=$tem[0];
  }
  $IN->close();

  ##### now use the new ranking to combine the model using structure similarity #####
  print "##### now use the new ranking to combine the model #####\n\n";
  my($tool_combine) = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/global_local_human_2016.pl";
  my($selected_out) = $dir_output."/"."Selected_models_combined";
  -s $selected_out || system("mkdir $selected_out");
  if(-e "$selected_out/combine_model.done")
  {
	print "Model combination using structural similarity is done\n\n";
  }else{
	  print("perl $tool_combine $filtered_model $addr_fasta $re_rank $selected_out  &> $dir_output/combine_model.log\n\n");
	  if(system("perl $tool_combine $filtered_model $addr_fasta $re_rank $selected_out  &> $dir_output/combine_model.log"))
	  {
		 print "perl $tool_combine $filtered_model $addr_fasta $re_rank $selected_out fails!\n";
	  }
	  `touch $selected_out/combine_model.done`;
  }
  
  ###### compare the GDT score and check the model drifting #######
    my(@model_casp) = ();
  $model_casp[0] = "casp1.pdb";
  $model_casp[1] = "casp2.pdb";
  $model_casp[2] = "casp3.pdb";
  $model_casp[3] = "casp4.pdb"; 
  $model_casp[4] = "casp5.pdb"; 
  
  print "###### compare the GDT score and check the model drifting #######\n\n";
  my($tool_GDT) = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/tm_score/TMscore_32";
  my($model1,$model2,$tmp_out);
  $tmp_out = $dir_output."/"."TM_tmp";
  
  for($i_modelcasp=0;$i_modelcasp < @model_casp; $i_modelcasp++)
  {
     $tmp_out = $dir_output."/"."TM_score.$model_casp[$i_modelcasp]";
	 print("$tool_GDT $filtered_model/$top5_models[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp] > $tmp_out\n\n");
     if(system("$tool_GDT $filtered_model/$top5_models[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp] > $tmp_out"))
     {
        print "$tool_GDT $filtered_model/$top5_models[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp] > $tmp_out fails!\n";
        next;
     }
     $IN = new FileHandle "$tmp_out";
	 $sim_score='NULL';
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          print "The GDT-TS score between initial and combined model of $model_casp[$i_modelcasp] is $tem[2]\n";
		  $sim_score = $tem[2];
          last;
        }   
     }
     $IN->close();
	 
	 if($sim_score eq 'NULL')
	 {
		print "!!!!! Failed to compute similarity score between ".$model_casp[$i_modelcasp]."\n\n";
	 }else
	 {
		if ($sim_score < 0.88)
		{
			warn "The similarity between the combined model ($selected_out/$model_casp[$i_modelcasp]) and the top ranked model ($filtered_model/$top5_models[$i_modelcasp]) is $sim_score. Revert back to $filtered_model/$top5_models[$i_modelcasp].\n\n";
			
			print "mv $selected_out/$model_casp[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp].comb\n"; 
			`mv $selected_out/$model_casp[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp].comb`; 

			print "cp $filtered_model/$top5_models[$i_modelcasp] $selected_out/casp$i_modelcasp.pdb\n";
			$idnew = $i_modelcasp + 1;
			`cp $filtered_model/$top5_models[$i_modelcasp] $selected_out/casp${idnew}.norefine.pdb`;
			
			#### use self_model.pl or 3Drefine, and recheck
			
			 ######## now run several refinement parallel #########
			 print "!!! Start to refine $selected_out/casp${idnew}.norefine.pdb\n\n";
			 $dir_tem_refine = "$selected_out/refine";
			 if(!(-d $dir_tem_refine))
			 {
				`mkdir $dir_tem_refine`;
			 }
				chdir($dir_tem_refine);
				`grep ATOM $selected_out/casp${idnew}.norefine.pdb  > casp${idnew}.norefine.pdb`;
				print "/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/bin/i3Drefine.sh   casp${idnew}.norefine.pdb  5 &> casp${idnew}.norefine.pdb.refinelog\n";
				`/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/bin/i3Drefine.sh   casp${idnew}.norefine.pdb  5 &> casp${idnew}.norefine.pdb.refinelog`;
				
				open(IN,"casp${idnew}.norefine.pdb.refinelog") || next;
				while(<IN>)
				{
					$line = $_;
					chomp $line;
					if(index($line,'Path of Refined Model(s) =')>=0)
					{
						$path = substr($line,index($line,'=')+1);
						$path =~ s/^\s+|\s+$//g;
						last;
					}
				}
				close IN;
				
				print "The refined models are saved in $path\n\n";
				
				$run1 = $path."/REFINED_1.pdb";
				$run2 = $path."/REFINED_2.pdb";
				$run3 = $path."/REFINED_3.pdb";
				$run4 = $path."/REFINED_4.pdb";
				$run5 = $path."/REFINED_5.pdb";
				$initial_model = "$dir_tem_refine/casp${idnew}.norefine.pdb";
				$final_model = $selected_out."/casp${idnew}.refine.pdb";


				 select_based_on_GDT($run1,$run2,$run3,$run4,$run5,$initial_model,$final_model);
				if(-e $final_model)
				{
					`cp $final_model $selected_out/casp${idnew}.pdb`;
				}else{
					print "\n!!! Failed to find $final_model\n\n";
				}
			
		}
		else
		{
			print "The similarity between the combined model ($selected_out/$model_casp[$i_modelcasp]) and the top ranked model ($filtered_model/$top5_models[$i_modelcasp]) is $sim_score. No reversion.\n\n";
		}
	}
  }
=pod  
/home/chengji/software/tm_score/TMscore_32 /home/casp13/Human_TS/run/T0950/Full_HumanTS/eva/mod2/RaptorX-DeepModeller_TS1 /home/casp13/Human_TS/run/T0950/Full_HumanTS/Selected_models_combined/casp1.pdb > /home/casp13/Human_TS/run/T0859/TM_score.casp1.pdb

The GDT-TS score between initial and combined model of casp1.pdb is 1.0000
/home/chengji/software/tm_score/TMscore_32 /home/casp13/Human_TS/run/T0859/eva/mod2/GOAL_TS3 /home/casp13/Human_TS/run/T0859/Selected_models_combined/casp2.pdb > /home/casp13/Human_TS/run/T0859/TM_score.casp2.pdb

The GDT-TS score between initial and combined model of casp2.pdb is 0.9643
/home/chengji/software/tm_score/TMscore_32 /home/casp13/Human_TS/run/T0859/eva/mod2/QUARK_TS5 /home/casp13/Human_TS/run/T0859/Selected_models_combined/casp3.pdb > /home/casp13/Human_TS/run/T0859/TM_score.casp3.pdb

The GDT-TS score between initial and combined model of casp3.pdb is 1.0000
/home/chengji/software/tm_score/TMscore_32 /home/casp13/Human_TS/run/T0859/eva/mod2/chuo-u-server_TS2 /home/casp13/Human_TS/run/T0859/Selected_models_combined/casp4.pdb > /home/casp13/Human_TS/run/T0859/TM_score.casp4.pdb

The GDT-TS score between initial and combined model of casp4.pdb is 0.7406
/home/chengji/software/tm_score/TMscore_32 /home/casp13/Human_TS/run/T0859/eva/mod2/chuo-u-server_TS3 /home/casp13/Human_TS/run/T0859/Selected_models_combined/casp5.pdb > /home/casp13/Human_TS/run/T0859/TM_score.casp5.pdb

The GDT-TS score between initial and combined model of casp5.pdb is 0.8741
=cut


#### can compare with zhang1 and baker1 and cluster1
=pod
  ##### compare the consensus best model with the pairwise best model and the cluster_TS1, Zhang_TS1 ####

  my($log_con_comp) = $dir_output."/"."Comparison_of_consensus_vs_pairwise_cluster_zhang";
  print("perl /home/casp13/Human_TS/scripts/validate_consensus_best_model_for_one_target.pl $dir_output $tool_GDT $log_con_comp\n\n");
  system("perl /home/casp13/Human_TS/scripts/validate_consensus_best_model_for_one_target.pl $dir_output $tool_GDT $log_con_comp");
  print "\n******* comparison of the consensus best model with the refenrece model ********\n";
  $IN = new FileHandle "$log_con_comp";
  while(defined($line=<$IN>))
  {
    chomp($line);
    print $line."\n";
  }  
  $IN->close();
=cut


  ##### copy the final five models and add the local quality ####
  print "\n\n##### copy the final five models and add the local quality ####\n\n";
  $add_local = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/CASP12_human_add_remark_QA.pl";
  $final_top5 = $dir_output."/"."Final_top5_models_before";
  -s $final_top5 || system("mkdir $final_top5");

  $i_modelcasp = 0;
  for($i_modelcasp=0;$i_modelcasp < @model_casp; $i_modelcasp++)
  {
	 print("perl $add_local $top5_models[$i_modelcasp] $score_novel $selected_out/$model_casp[$i_modelcasp] $final_top5/$model_casp[$i_modelcasp] > /dev/null 2>&1\n\n");
     if(system("perl $add_local $top5_models[$i_modelcasp] $score_novel $selected_out/$model_casp[$i_modelcasp] $final_top5/$model_casp[$i_modelcasp] > /dev/null 2>&1"))
     {
        print "perl $add_local $top5_models[$i_modelcasp] $score_novel $selected_out/$model_casp[$i_modelcasp] $final_top5/$model_casp[$i_modelcasp] fails!\n";    
        #exit(0);
     }
  }
  

  ####### new added by Renzhi at 5/20/2016 for model refinement ###########
  $model_refine_script = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/ModRefiner_refine.pl";
  $real_refine_script = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/Real_run_ModRefiner.pl";
  #my($refine_tool) = "/home/jh7x3/MULTICOM_Human_CASP14/tools/ModRefiner-l";
  $refine_tool = "/home/jh7x3/MULTICOM_Human_CASP14/tools/ModRefiner-l";
  $refine_TM = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/tm_score/TMscore_32";
  $refined_top5_no_local = $dir_output."/"."Final_top5_models_no_local";
  $refined_top5 = $dir_output."/"."Final_top5_models";
  if(!(-d $refined_top5))
  {
	`mkdir $refined_top5`;
  }
  
  
      print("cp $final_top5/*pdb $refined_top5");
      system("cp $final_top5/*pdb $refined_top5");
	  #print "warning !!! model refinement part is missing, all models are not refined. check $model_refine_script, $real_refine_script, $refine_tool, and $refine_TM\n";

	  
=pod
  print "\n***************** model refinement information ***************\n";
  if((-s $model_refine_script) && (-s $real_refine_script) && (-s $refine_tool) && (-s $refine_TM))
  {# check whether exists  
	  print("perl $model_refine_script $real_refine_script $refine_tool $refine_TM $final_top5 $refined_top5_no_local\n\n");
	  system("perl $model_refine_script $real_refine_script $refine_tool $refine_TM $final_top5 $refined_top5_no_local");
	  -s $refined_top5 || system("mkdir $refined_top5");

	  # add local quality score
	  for($i_modelcasp=0;$i_modelcasp < @model_casp; $i_modelcasp++)
	  {
		 print("perl $add_local $top5_models[$i_modelcasp] $score_novel $refined_top5_no_local/$model_casp[$i_modelcasp] $refined_top5/$model_casp[$i_modelcasp] > /dev/null 2>&1\n\n");
	     if(system("perl $add_local $top5_models[$i_modelcasp] $score_novel $refined_top5_no_local/$model_casp[$i_modelcasp] $refined_top5/$model_casp[$i_modelcasp] > /dev/null 2>&1"))
	     {
	        print "perl $add_local $top5_models[$i_modelcasp] $score_novel $refined_top5_no_local/$model_casp[$i_modelcasp] $refined_top5/$model_casp[$i_modelcasp] fails!\n";    
	        exit(0);
	     }
	  }
  }
  else
  {
      system("mv $final_top5 $refined_top5");
	  print "warning !!! model refinement part is missing, all models are not refined. check $model_refine_script, $real_refine_script, $refine_tool, and $refine_TM\n";
  }
=cut


############ added on 2018/05/28, generated top 5 models without clustering 

  $score_novel_sort = $eva_dir."/"."HumanQA_gdt_prediction_sort.txt";    # this is the NOVEL server prediction 
  #$score_novel_sort = $eva_loss0048_dir."/"."HumanQA_gdt_prediction_loss0048_sort.txt";    # this is the NOVEL server prediction 
  -s $score_novel_sort || die "cannot find the server NOVEL prediction : $score_novel_sort\n";  
  @top5_models = ();
  $i_top5=0;
  $IN = new FileHandle "$score_novel_sort";
  while(defined($line=<$IN>))
  {
    chomp($line);
    @tem = split(/\s+/,$line);
    if($i_top5>=5)
    {
      last;
    }
    if(@tem<2)
    {
      print "Should not happen, check $score_novel_sort, line : $line\n";
      next;
    }
    $top5_models[$i_top5++]=$tem[0];
  }
  $IN->close();

  ##### now use the new ranking to combine the model using structure similarity #####
  print "##### now use the new ranking to combine the model #####\n\n";
  $tool_combine = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/global_local_human_2016.pl";
  $selected_out = $dir_output."/"."Selected_models_combined_noClustering";
  -s $selected_out || system("mkdir $selected_out");
  if(-e "$selected_out/combine_model.done")
  {
	print "Model combination using structural similarity is done\n\n";
  }else{
	  print("perl $tool_combine $filtered_model $addr_fasta $score_novel_sort $selected_out  &> $dir_output/combine_model_noClustering.log\n\n");
	  if(system("perl $tool_combine $filtered_model $addr_fasta $score_novel_sort $selected_out  &> $dir_output/combine_model_noClustering.log"))
	  {
		 print "perl $tool_combine $filtered_model $addr_fasta $score_novel_sort $selected_out fails!\n";
	  }
	  `touch $selected_out/combine_model.done`;
  }
  
  ###### compare the GDT score and check the model drifting #######
  @model_casp = ();
  $model_casp[0] = "casp1.pdb";
  $model_casp[1] = "casp2.pdb";
  $model_casp[2] = "casp3.pdb";
  $model_casp[3] = "casp4.pdb"; 
  $model_casp[4] = "casp5.pdb"; 
  
  print "###### compare the GDT score and check the model drifting #######\n\n";
  $tool_GDT = "/home/chengji/software/tm_score/TMscore_32";
  #my($model1,$model2,$tmp_out);
  $tmp_out = $dir_output."/"."TM_tmp";
  
  for($i_modelcasp=0;$i_modelcasp < @model_casp; $i_modelcasp++)
  {
     $tmp_out = $dir_output."/"."TM_score.$model_casp[$i_modelcasp]";
	 print("$tool_GDT $filtered_model/$top5_models[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp] > $tmp_out\n\n");
     if(system("$tool_GDT $filtered_model/$top5_models[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp] > $tmp_out"))
     {
        print "$tool_GDT $filtered_model/$top5_models[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp] > $tmp_out fails!\n";
        next;
     }
     $IN = new FileHandle "$tmp_out";
	 $sim_score='NULL';
     while(defined($line=<$IN>))
     {
        chomp($line);
        if($line=~m/GDT-score/)
        {
          @tem = split(/\s+/,$line);
          print "The GDT-TS score between initial and combined model of $model_casp[$i_modelcasp] is $tem[2]\n";
		  $sim_score = $tem[2];
          last;
        }   
     }
     $IN->close();
	 
	 if($sim_score eq 'NULL')
	 {
		print "!!!!! Failed to compute similarity score between ".$model_casp[$i_modelcasp]."\n\n";
	 }else
	 {
		if ($sim_score < 0.88)
		{
			warn "The similarity between the combined model ($selected_out/$model_casp[$i_modelcasp]) and the top ranked model ($filtered_model/$top5_models[$i_modelcasp]) is $sim_score. Revert back to $filtered_model/$top5_models[$i_modelcasp].\n\n";
			
			print "mv $selected_out/$model_casp[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp].comb\n"; 
			`mv $selected_out/$model_casp[$i_modelcasp] $selected_out/$model_casp[$i_modelcasp].comb`; 

			print "cp $filtered_model/$top5_models[$i_modelcasp] $selected_out/casp$i_modelcasp.pdb\n";
			$idnew = $i_modelcasp + 1;
			`cp $filtered_model/$top5_models[$i_modelcasp] $selected_out/casp${idnew}.norefine.pdb`;
			
			#### use self_model.pl or 3Drefine, and recheck
			
			 ######## now run several refinement parallel #########
			 print "!!! Start to refine $selected_out/casp${idnew}.norefine.pdb\n\n";
			 $dir_tem_refine = "$selected_out/refine";
			 if(!(-d $dir_tem_refine))
			 {
				`mkdir $dir_tem_refine`;
			 }
				chdir($dir_tem_refine);
				`grep ATOM $selected_out/casp${idnew}.norefine.pdb  > casp${idnew}.norefine.pdb`;
				print "/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/bin/i3Drefine.sh   casp${idnew}.norefine.pdb  5 &> casp${idnew}.norefine.pdb.refinelog\n";
				`/home/jh7x3/MULTICOM_Human_CASP14/tools/i3Drefine/bin/i3Drefine.sh   casp${idnew}.norefine.pdb  5 &> casp${idnew}.norefine.pdb.refinelog`;
				
				open(IN,"casp${idnew}.norefine.pdb.refinelog") || next;
				while(<IN>)
				{
					$line = $_;
					chomp $line;
					if(index($line,'Path of Refined Model(s) =')>=0)
					{
						$path = substr($line,index($line,'=')+1);
						$path =~ s/^\s+|\s+$//g;
						last;
					}
				}
				close IN;
				
				print "The refined models are saved in $path\n\n";
				
				$run1 = $path."/REFINED_1.pdb";
				$run2 = $path."/REFINED_2.pdb";
				$run3 = $path."/REFINED_3.pdb";
				$run4 = $path."/REFINED_4.pdb";
				$run5 = $path."/REFINED_5.pdb";
				$initial_model = "$dir_tem_refine/casp${idnew}.norefine.pdb";
				$final_model = $selected_out."/casp${idnew}.refine.pdb";


				 select_based_on_GDT($run1,$run2,$run3,$run4,$run5,$initial_model,$final_model);
				if(-e $final_model)
				{
					`cp $final_model $selected_out/casp${idnew}.pdb`;
				}else{
					print "\n!!! Failed to find $final_model\n\n";
				}
			
		}
		else
		{
			print "The similarity between the combined model ($selected_out/$model_casp[$i_modelcasp]) and the top ranked model ($filtered_model/$top5_models[$i_modelcasp]) is $sim_score. No reversion.\n\n";
		}
	}
  }

  ##### copy the final five models and add the local quality ####
  print "\n\n##### copy the final five models and add the local quality ####\n\n";
  $add_local = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/CASP12_human_add_remark_QA.pl";
  $final_top5 = $dir_output."/"."Final_top5_models_noClustering_before";
  -s $final_top5 || system("mkdir $final_top5");
  $refined_top5 = $dir_output."/"."Final_top5_models_noClustering";
  if(!(-d $refined_top5))
  {
	`mkdir $refined_top5`;
  }

  $i_modelcasp = 0;
  for($i_modelcasp=0;$i_modelcasp < @model_casp; $i_modelcasp++)
  {
	 print("perl $add_local $top5_models[$i_modelcasp] $score_novel $selected_out/$model_casp[$i_modelcasp] $final_top5/$model_casp[$i_modelcasp] > /dev/null 2>&1\n\n");
     if(system("perl $add_local $top5_models[$i_modelcasp] $score_novel $selected_out/$model_casp[$i_modelcasp] $final_top5/$model_casp[$i_modelcasp] > /dev/null 2>&1"))
     {
        print "perl $add_local $top5_models[$i_modelcasp] $score_novel $selected_out/$model_casp[$i_modelcasp] $final_top5/$model_casp[$i_modelcasp] fails!\n";    
        #exit(0);
     }
	 
  }
  
  print("cp $final_top5/*pdb $refined_top5");
  system("cp $final_top5/*pdb $refined_top5");
  
  



 sub get_bottom_10_percent($)
 {
   my($path) = @_;
   my(%hash_novel) = ();
   my(@tem);
   my($IN,$line);
   my($count) = 0;
   $IN = new FileHandle "$path";
   while(defined($line=<$IN>))
   {
      chomp($line);
      @tem = split(/\s+/,$line);
       if(@tem<2)
       {
          next;
       }
       if($tem[0] eq "REMARK" || $tem[0] eq "PFRMAT" ||$tem[0] eq "TARGET" ||$tem[0] eq "AUTHOR" ||$tem[0] eq "METHOD" ||$tem[0] eq "MODEL" || $tem[0] eq "QMODE" || $tem[0] eq "END")
       {
           next;
       }
       if(looks_like_number($tem[0]) || $tem[0] eq "X")
       {
           next;
       }
       $hash_novel{$tem[0]} = $tem[1];
       $count++;
   }
   $IN->close();
   my($i)=int($count/10);
#   print "Pick $i models ranking at the bottom of the NOVERL server $path!\n";
   my($key);
   my(@models)=0;
   my($index)=0;
   foreach $key (sort{$hash_novel{$a} <=> $hash_novel{$b}} keys %hash_novel)   
   {
      if($i<0)
      {
         last;
      }
      $i--;
      $models[$index++] = $key;
   }
   return @models;
 }

 sub get_seq($)
 {
    my($addr_seq)=@_;
    my($IN,$line,$seq);
    $seq = "NULL";
    $IN = new FileHandle "$addr_seq";
    while(defined($line = <$IN>))
    {
       chomp($line);
       if(substr($line,0,1) eq ">")
       {
          next;
       }
       if($seq eq "NULL")
       {
          $seq = $line;
       }
       else
       {
          $seq.=$line;
       }
    }
    $IN->close();
    return $seq;
 }

 sub select_models_MUFOLD($$$$$)
 {
	 my($tmp_bottom,$tmp_hash,$input,$final_ranking,$output)=@_;
	 my(%hash)=%$tmp_hash;          # this has the consensus scores
         my(%bottom_hash) = %$tmp_bottom;  # this is the bottom hash, all the models in the bad cluster
         my(@selected)=();              # selected models
	 my($index)=0;

#	 print "Processing MUFOLD_CL output $input ...\n";
	 my($IN,$line,$OUT,$key,$i,$value);
         my(@tem,@infor);
     
	 my(%cluster)=();
	 my(%cluster_models)=();
	 my($NUM_cluster)=0;

	 $IN = new FileHandle "$input";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 @tem=split(/\s+/,$line);

		 if($tem[0] eq "INFO" && $tem[2] eq "Cluster" && $tem[3] eq "Centroid")
		 {# this is the start of cluster information
#			 print "We get the information that cluster starts!\n";
			 last;
		 }
	 }
	 ######## read the cluster information #########
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 if($line eq "INFO  : ======================================")
		 {# finish it
			 last;
		 }
		 @tem = split(/\:/,$line);
                 @infor = split(/\s+/,$tem[1]);
		 $key = $infor[1];                # cluster index
		 @infor = split(/\s+/,$tem[2]);
		 $value = $infor[1];
		 for($i=2;$i<@infor;$i++)
		 {
			 $value.="_".$infor[$i];
		 }
		 $cluster{$key}=$value;
         $NUM_cluster++;
	 }
=pod
     print "We get $NUM_cluster clusters in total for $input!\n";
	 print "Here is the information for each cluster:\n";
	 print "Cluster  Centroid  ClutSize MeanRmsd  StdRmsd           CentDecoyName\n";
	 for($i=1;$i<=$NUM_cluster;$i++)
	 {
		 print $i."\t";
		 @tem=split(/\_/,$cluster{$i});
		 print "@tem"."\n";
	 }
=cut
#     print "************************\n";
	 if($NUM_cluster < 5)
	 {
		 print "Warning, we get less than 5 clusters!\n";
	 }
	 for($i=1;$i<=$NUM_cluster;$i++)
	 {
		 @tem=split(/\_/,$cluster{$i});
		 if($tem[1] > 60)
		 {
#			 print "Warning, for cluster $i, the cluster size is larger than 60, maybe we can pick two models from this cluster!\n";
		 }
	 }
#     print "**********************\n";
         my(%modelscluster) = ();
#	 print "Now read the information of models for each cluster ...\n";
	 while(defined($line=<$IN>))
	 {
		 chomp($line);
		 @tem = split(/\:/,$line);
		 if(@tem !=3)
		 {# not the line we need : INFO  :    Item     Cluster                     DecoyName
			 next;
		 }
		 @infor = split(/\s+/,$tem[2]);       # get the cluster index and model name
		 if(not exists $cluster_models{$infor[1]})
		 {
			 $cluster_models{$infor[1]} = $infor[2];
		 }
		 else
		 {
			 $cluster_models{$infor[1]}.="|".$infor[2];
		 }
                 if(not exists $modelscluster{$infor[2]})
                 {
                         $modelscluster{$infor[2]} = $infor[1];
                 }
	 }
	 $IN->close();
     
	 if($NUM_cluster < 5)
	 {
		 print "Not enough clusters, suggest get more models in the largest cluster! Right now, we just pick one from each, so finally, we may not get enough five models, mannually check here, and tell me what to do!\n";
	     print "In this case, I revise my method, so if one cluster has more than 60 models, I will pick the top 2 models from that cluster based on the energy score, if more than 90, pick three!\n";
	 }
         ###### get all bad cluster #######
         my(%bad_cluster)=();
         foreach $key (keys %hash_bottom)
         {
             if(not exists $bad_cluster{$modelscluster{$key}})
             {
                 $bad_cluster{$modelscluster{$key}} = 1;
             }
         }
         ##################################     

	 my($total_model_choose)=5;
         my($picked)=0;
         ###### select the top 2 models directly, others, not in the same cluster as top 2, and not in the bad cluster #######
         my(@backup) = ();
         my($index_backup)=0;
         my(%select_cluster)=();
         $IN = new FileHandle "$final_ranking";
         if(defined($line=<$IN>))
         { 
             chomp($line);
             @tem = split(/\s+/,$line);
             if(@tem<2)
             {
                 print "Warning, check $final_ranking, and line $line\n";
             }
             else
             {
                 $selected[$index++] = $tem[0];
                 $picked++;

                 if(not exists $modelscluster{$tem[0]})
                 {
                     print "Warning, MUFOLD ignore this model : check $line!!!!!!\n";
                     $modelscluster{$tem[0]} = -1;
                 } 
                 if(not exists $select_cluster{$modelscluster{$tem[0]}})
                 {
                     $select_cluster{$modelscluster{$tem[0]}} = 1;
                 }
                 print "!!! Picked the top 1 model $tem[0] based on consensus ranking!\n";
             }
         }
         if(defined($line=<$IN>))
         {
             chomp($line);
             @tem = split(/\s+/,$line);
             if(@tem<2)
             {
                 print "Warning, check $final_ranking, and line $line\n";
             }
             else
             {
                 $selected[$index++] = $tem[0];
                 $picked++;
                 if(not exists $modelscluster{$tem[0]})
                 {
                     print "Warning, MUFOLD ignore this model : check $line!!!!!!\n";
                     $modelscluster{$tem[0]} = -1;
                 }
                 if(not exists $select_cluster{$modelscluster{$tem[0]}})
                 {
                     $select_cluster{$modelscluster{$tem[0]}} = 1;
                 }
                 print "!!! Picked the top 2 model $tem[0] based on consensus ranking!\n";
             }
         }
         while(defined($line=<$IN>))
         {# for the rest of models, we start selecting ...
            chomp($line);
            @tem = split(/\s+/,$line);
            if(@tem<2)
            {
                 print "Warning, check $final_ranking, and line $line\n";
                 next;
            }

            if(not exists $modelscluster{$tem[0]})
            {
                 print "Warning,MUFOLD ignore this model, check $line!!!!!!\n";
                 $modelscluster{$tem[0]} = -1;
            }
            if(exists $select_cluster{$modelscluster{$tem[0]}})
            {
                 if($picked<$total_model_choose)
                 {
                    print "model $tem[0] is not selected, since it is in the same cluster as the top selected models!\n";
                 }
                 $backup[$index_backup++]=$line;
                 next;
            }
#            if(exists $bad_cluster{$modelscluster{$tem[0]}})
            if(exists $bottom_hash{$tem[0]})                 # we only remove the bottom 10% bad models, instead of clusters!
            {
                 if($picked<$total_model_choose)
                 {
                    #print "model $tem[0] is not selected, since it is in a bad cluster : cluster $modelscluster{$tem[0]}!\n";
                    print "model $tem[0] is not selected, since it is at the bottom 10% based on the single QA ranking. !!!!!!! WARNING !!!!!!!!!\n";
                 }
                 $backup[$index_backup++]=$line;
                 next;
            }
            if($picked<$total_model_choose)
            {
                 if(not exists $select_cluster{$modelscluster{$tem[0]}})
                 {
                     $select_cluster{$modelscluster{$tem[0]}} = 1;
                 }
                 print "!!! model $tem[0] is selected!\n";
                 $selected[$index++]=$tem[0];
                 $picked++;
                 next;
            }  
            $backup[$index_backup++] = $line;
         }         

         $IN->close();       
  
         ###############################################	 
         ######## output the result #########
         if(@selected < 5)
         {
            print "\n***** Warning!!! Not select 5 top models, maybe need mannually inspection!\n";
         }
         $OUT = new FileHandle ">$output";
         for($i=0;$i<@selected;$i++)
         {
            print $OUT $selected[$i]."\t"."1\n";
         }
         for($i=0;$i<@backup;$i++)
         {
            print $OUT $backup[$i]."\n";
         }
         $OUT->close();
 }

sub sendlog
{
   my($prob)=@_;
   
   my($subject)="Human consensus quality needs help! Here is the problem : $prob";
   my $msg = MIME::Lite->new(
                From    => "Renzhi Cao <rcrg4\@mail.missouri.edu>",
                To      => "rcrg4\@mail.missouri.edu",
                Subject => "$subject",
                Cc     => 'rcrg4@mail.missouri.edu',
                Type    => 'multipart/mixed',
    ) or die ("cannot create MIME object!");
    my($body) = "NULL";

    $msg->attach(
        Type     =>'TEXT',
        Data     =>"$body"
    );
	$msg->send or print "Error sending email, MIME::Lite->send failed: $!\n";   
}

 sub cal_GDT($$$)
 {
	 my($ini,$s,$log)=@_;
	 my($IN,$OUT,$line);
	 my($score)=0;
	 my(@tem);
	 print("$tool_TM $ini $s > $log\n\n");
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
		 if($tem[0] eq "GDT-TS-score=")
		 {
			 $score = $tem[1];
			 last;
		 }
	 }
	 $IN->close();
	 return $score;
 }

 sub select_based_on_GDT($$$$$$$)
 {
	 my($c0,$c1,$c2,$c3,$c4,$ini,$final)= @_;
	 my($IN,$line,$OUT,$log);
	 my(@tem);
	 my($s0,$s1,$s2,$s3,$s4);
	 $s0 = 0;
	 $s1 = 0;
	 $s2 = 0;
	 $s3 = 0;
	 $s4 = 0;

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
	 #### check model 3 ########
	 @tem = split(/\//,$c3);
	 $log = $dir_tem."/"."3_".$tem[@tem-1];
	 $s3 = cal_GDT($ini,$c3,$log);
	 #### check model 4 ########
	 @tem = split(/\//,$c4);
	 $log = $dir_tem."/"."4_".$tem[@tem-1];
	 $s4 = cal_GDT($ini,$c4,$log);

   
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

	 if($s3>$max)
	 {
		 $max = $s3;
		 $index_max = $c3;
	 }

	 if($s4>$max)
	 {
		 $max = $s4;
		 $index_max = $c4;
	 }

	 if($max>=0.98)
	 {# working
		 combine_init_refined($ini,$index_max,$final);      # we need to keep some head information and use the refined ATOM information
		 print "working: Selected GDT-TS score before and after refinement for $final is $max\n";
		 system("cp $index_max $final");     # great
	 }
	 else
	 {
		 print "gdt-score is $max, less than 0.98, keep original model for $final\n";
		 system("cp $ini $final");     # great
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
