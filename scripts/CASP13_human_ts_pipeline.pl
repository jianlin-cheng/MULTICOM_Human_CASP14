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

$domain_parse = "/home/jh7x3/MULTICOM_Human_CASP14/scripts/parse_domain_v3.pl";
$pdb_program = "/home/jh7x3/MULTICOM_Human_CASP14/tools/pdp";
$modeller_dir = "";
$tm_score = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/tm_score/TMscore_32";
$q_score = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/pairwiseQA/q_score";
#$meta_dir = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/src/meta/";
$multicom_dir = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/src/meta/"; 
$pdb2casp2 = "$multicom_dir/script/pdb2casp.pl";
#prosys dir
$prosys_dir = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/src/prosys/";
#model dir

$modeller_dir = "/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/modeller-9.16/";
$domain_split_comb = 0; 
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
my($domain_information) = $ARGV[3]; # path, domain_parser, alignment, NULL
my($contactfile) = $ARGV[4]; # path,  NULL
-s $dir_output || system("mkdir $dir_output");

if(!defined($domain_information))
{
	$domain_information='NULL';
}
if(!defined($contactfile))
{
	$contactfile='NULL';
}

if($domain_information eq 'domain_parser')
{
	print "!!!!! Setting domain_parser as domain identification method\n\n";
}elsif($domain_information eq 'alignment')
{
	print "!!!!! Setting alignment as domain identification method\n\n";
}elsif($domain_information eq 'NULL')
{
	print "!!!!! Setting alignment (default) as domain identification method\n\n";
}elsif(-e $domain_information)
{
	print "!!!!! Setting manual domain information ($domain_information) as domain identification method\n\n";
}else{
	die "Failed to define correct domain identification method\n\n";
}


chdir($dir_output);  
my($tar) = "NULL";
if(@ARGV > 5)
{	# you provide the models folder, so no need to download from the website
	$tar = abs_path($ARGV[5]);
}
else
{
 #$tar = "http://www.predictioncenter.org/download_area/CASP13/server_predictions/$targetname.3D.srv.tar.gz";
 $tar = "http://www.predictioncenter.org/download_area/CASP13/server_predictions/$targetname.stage2.3D.srv.tar.gz";
}

$dir_models = "NULL";
#my($sequence) = get_seq($addr_fasta);           # get the sequence from fasta sequence file

if(!(-e $addr_fasta))
{
	$problem = "Failed to find sequence $addr_fasta\n";
	#sendlog($problem);
	die "$problem\n";
	
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
	#sendlog($problem);
	die "$problem\n";
}

`cp -ar $dir_models $dir_output/Original_models`;

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
open(FASTA, $addr_fasta) || die "can't find $addr_fasta.\n";
$name = <FASTA>;
chomp $name;
$name = substr($name, 1); 
$qseq = <FASTA>;
chomp $qseq; 
close FASTA; 
$qlen = length($qseq); 

###########FILTER MODELS#########
#filter out redudant models from the same group, changed to use version 2 on July 9, 2012. ##
my($same_group_log) = $dir_output."/"."Same_group.log";
print("/home/jh7x3/MULTICOM_Human_CASP14/scripts/filter_model_same_group_v2.pl $name.mlist $name.nlist  /home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/tm_score2/TMscore > $same_group_log\n\n");
system("/home/jh7x3/MULTICOM_Human_CASP14/scripts/filter_model_same_group_v2.pl $name.mlist $name.nlist  /home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/tm_score2/TMscore > $same_group_log");
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

#ab initio: generate model scores (for full length model only)   ####here is modelEvaluator
my($wen_path_scwrl)="/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/scwrl4/Scwrl4";


my($wen_processed_model)=$dir_output."/"."scwrl_model";
system("mkdir $wen_processed_model");
$wen_processed_model=$dir_output."/"."scwrl_model/$name";
system("mkdir $wen_processed_model");

my($wen_path1,$wen_path2,$wen_path);
my(@wen_paths);
####### use scwrl to process the model #######
opendir(DIR, "$ren_filter");
@wen_paths = readdir(DIR);
foreach $wen_path (@wen_paths)
{
        if($wen_path eq '.' || $wen_path eq '..')
        {
                next;
        }
        $wen_path1=$ren_filter."/".$wen_path;
        $wen_path2=$wen_processed_model."/".$wen_path;
        $ren_return_val=system("$wen_path_scwrl -i $wen_path1 -o $wen_path2");
        if($ren_return_val!=0)
        {
          print  "$wen_path_scwrl -i $wen_path1 -o $wen_path2 fails !\n";
        }
		if(!-s $wen_path2)
	    {# scwrl fails in this case, only CA atom is in the pdb, we directly copy it from original
			system("cp $wen_path1 $wen_path2");
		}
}



### **************************************************************************************************** ###
closedir(DIR);
print  "Data part finished, please check log file in each server directory! \n";


$dir_models = $wen_processed_model;

####### (2) run Domain_based human structure prediction 

# a. get domain information from alignment
# b. get domain information from domain parser (top1 model)
# c. get domain information from manual setting

$domain_method="NULL";
if($domain_information eq 'domain_parser')
{
	print "!!!!! Setting domain_parser as domain identification method\n\n";
	$domain_method = $domain_information;
}elsif($domain_information eq 'alignment')
{
	print "!!!!! Setting alignment as domain identification method\n\n";
	$domain_method = $domain_information;
}elsif($domain_information eq 'NULL')
{
	print "!!!!! Setting alignment (default) as domain identification method\n\n";
}elsif(-e $domain_information)
{
	print "!!!!! Setting manual domain information ($domain_information) as domain identification method\n\n";
	$domain_method = "Manual";
}else{
	die "Failed to define correct domain identification method\n\n";
}


###### predict domain information by hhsearch
print "\n\n###### predict domain information by hhsearch\n\n";
$dom_hhsearch_out = "$dir_output/Dom_by_hhsearch";
if(!(-d $dom_hhsearch_out))
{
	`mkdir $dom_hhsearch_out`;
}
if(-e "$dom_hhsearch_out/domain_info")
{
	print "!!!!! Found $dom_hhsearch_out/domain_info\n\n";
}else{
	print("perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/P1_get_domains_by_hhsearch15.pl $addr_fasta $dom_hhsearch_out /home/jh7x3/MULTICOM_Human_CASP14/multicom/databases/hhsearch1.5_db/hhsearch15db 40\n");
	system("perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/P1_get_domains_by_hhsearch15.pl $addr_fasta $dom_hhsearch_out /home/jh7x3/MULTICOM_Human_CASP14/multicom/databases/hhsearch1.5_db/hhsearch15db 40");
	`cp $dom_hhsearch_out/domain_info_thre40 $dom_hhsearch_out/domain_info`;
}


###### predict domain information by manually provided info
print "\n\n###### predict domain information by manually provided info\n\n";
$dom_manual_out = "$dir_output/Dom_by_manual";
if($domain_method eq 'Manual')
{
	if(!(-d $dom_manual_out))
	{
		`mkdir $dom_manual_out`;
	}	
	`cp $domain_information $dom_manual_out/domain_info`;
}



###### predict disorder information for domain decision
print "\n\n###### predict disorder information for domain decision\n\n";
$disorder_out = "$dir_output/disorder_prediction";
if(!(-d $disorder_out))
{
	`mkdir $disorder_out`;
}
if(-e "$disorder_out/$name.fasta.disorder")
{
	print "$disorder_out/$name.fasta.disorder generated\n\n";
}else{
	print("sh /home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/disorder_new/bin/predict_diso.sh $addr_fasta $disorder_out/$name.fasta.disorder\n");
	system("sh /home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/disorder_new/bin/predict_diso.sh $addr_fasta $disorder_out/$name.fasta.disorder");
}


$full_pred_dir = "$dir_output/Full_TS";
if(!-s $full_pred_dir)
{
	`mkdir $full_pred_dir`;
}
####### (1) run full-length human structure prediction 

$final_ranking = $full_pred_dir."/eva/HumanQA_gdt_prediction_sort.txt";
$final_ranking2 = $full_pred_dir."/eva_loss0048/HumanQA_gdt_prediction_loss0048_sort.txt";
if(-e $final_ranking and -e $final_ranking2)
{
	print "Full_length evaluation ($final_ranking and $final_ranking2) has been finished!\n\n";
}else{
	print "Start to run full_length evaluation!\n\n";
	print("perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/Auto_human_server.pl $name $addr_fasta $full_pred_dir $contactfile $dir_models &> $full_pred_dir/auto_human_server.log\n\n");
	system("perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/Auto_human_server.pl $name $addr_fasta $full_pred_dir $contactfile $dir_models &> $full_pred_dir/auto_human_server.log");

	print("perl /home/casp13/Human_TS/scripts/sort_deep_qa_score.pl $full_pred_dir/eva/HumanQA_gdt_prediction.txt $full_pred_dir/eva/HumanQA_gdt_prediction_sort.txt\n\n");
	system("perl /home/casp13/Human_TS/scripts/sort_deep_qa_score.pl $full_pred_dir/eva/HumanQA_gdt_prediction.txt $full_pred_dir/eva/HumanQA_gdt_prediction_sort.txt");

}


-s $final_ranking || die "Cannot find $final_ranking\n";

$dom_parse_out = "$dir_output/Dom_by_domain_parser";
if(!(-d $dom_parse_out))
{
	`mkdir $dom_parse_out`;
}

###### predict domain information by domain parser
print "\n\n###### predict domain information by domain parser\n\n";
if(-e "$dom_parse_out/domain_info")
{
	print "!!!!! Found $dom_parse_out/domain_info\n\n";
}else{
	print("perl /home/casp13/Human_TS/scripts/P1_get_domains_by_DomainParser.pl $addr_fasta $dir_models $final_ranking2 $dom_parse_out\n");
	system("perl /home/casp13/Human_TS/scripts/P1_get_domains_by_DomainParser.pl $addr_fasta $dir_models $final_ranking2 $dom_parse_out");
}



#### get final domain information taking disorder into consideration
print "\n\n#### get final domain information taking disorder into consideration\n\n";



$disorder_file = "$disorder_out/$name.fasta.disorder";

$domain_file="NULL";
if($domain_information eq 'domain_parser')
{
	print "!!!!! Setting domain_parser as domain identification method\n\n";
	$domain_file = "$dom_parse_out/domain_info";
	$domain_method = $domain_information;
}elsif($domain_information eq 'alignment')
{
	print "!!!!! Setting alignment as domain identification method\n\n";
	$domain_file = "$dom_hhsearch_out/domain_info";
	$domain_method = $domain_information;
}elsif($domain_information eq 'NULL')
{
	print "!!!!! Setting alignment (default) as domain identification method\n\n";
}elsif(-e $domain_information)
{
	print "!!!!! Setting manual domain information ($domain_information) as domain identification method\n\n";
	$domain_file = "$dom_manual_out/domain_info";
	$domain_method = "Manual";
}

if(!(-e $domain_file))
{
	print "Failed to find domain file $domain_file\n\n";
	goto FINISH;
}

open(IN,"$addr_fasta");
@content = <IN>;
close IN;
shift @content;
$sequence = shift @content;
chomp $sequence;

$disorder_seq="";


## get disorder information
if(!(-e $disorder_file))
{
	print "Failed to find disorder file $disorder_file, ignore it\n\n";
	for($i=0;$i<length($sequence);$i++)
	{
		$disorder_seq .="N";
	}
}else{
	open(IN,"$disorder_file");
	@content = <IN>;
	close IN;	
	$disorder_seq_tmp = shift @content;
	$disorder_tmp = shift @content;
	chomp $disorder_seq_tmp;
	chomp $disorder_tmp;
	if($disorder_seq_tmp ne $sequence)
	{
		print "Warning: disorder sequence not match the fasta sequence, ignore it\n$sequence\n$disorder_seq_tmp\n\n";
		for($i=0;$i<length($sequence);$i++)
		{
			$disorder_seq .="N";
		}
	}else{
		$disorder_seq = $disorder_tmp;
	}
}

open(IN,"$domain_file");
@content = <IN>;
close IN;

$domain_num = @content;
print "\n\nTotal $domain_num domains\n\n";

## correct the domain region if need using disorder information
@domain_disorder_info=();
@domain_range_info=();
foreach $info (@content)
{
	chomp $info;
	@tmp = split(/\s/,$info);
	$range = $tmp[1];
	@tmp2 = split(':',$range);
	$range2 = $tmp2[1];
	@tmp3 = split('-',$range2);
	$start = $tmp3[0];
	$end = $tmp3[1];
	
	$disorder_region = substr($disorder_seq,$start-1,$end-$start+1);
	$disorder_num=0;
	for($i=0;$i<length($disorder_region);$i++)
	{
		if(substr($disorder_region,$i,1) eq 'T')
		{
			$disorder_num++;
		}
	}
	$ratio = sprintf("%.3f",$disorder_num/length($disorder_region));
	if($ratio > 0.7)
	{
			push @domain_disorder_info,'Disorder';
	}else{
			push @domain_disorder_info,'Normal';
	}
	
	push @domain_range_info,"$start-$end";
}
@domain_range_info_corrected = @domain_range_info;
@domain_disorder_info_corrected = @domain_disorder_info;
=pod
### check left region 
$type_cur = $domain_disorder_info_corrected[0];
$type_next = $domain_disorder_info_corrected[1];
if($type_cur eq 'Disorder' and ($type_next eq 'Disorder' or $type_next eq 'Normal'))
{
	## merge two region
	$range_cur = $domain_range_info_corrected[0];
	$range_next = $domain_range_info_corrected[1];
	@range_cur_tmp = split('-',$range_cur);
	$range_cur_start = $range_cur_tmp[0];
	
	@range_next_tmp = split('-',$range_next);
	$range_next_end = $range_next_tmp[1];
	shift @domain_range_info_corrected;
	shift @domain_range_info_corrected;
	shift @domain_disorder_info_corrected;
	shift @domain_disorder_info_corrected;
	
	print "Merging [$range_cur]:$type_cur and [$range_next]$type_next into [$range_cur_start-$range_next_end]\n\n";
	unshift @domain_range_info_corrected,"$range_cur_start-$range_next_end";
	unshift @domain_disorder_info_corrected,"Normal";
}
### check right region 
$type_cur = $domain_disorder_info_corrected[@domain_disorder_info_corrected-1];
$type_prev = $domain_disorder_info_corrected[@domain_disorder_info_corrected-2];
if($type_cur eq 'Disorder' and ($type_prev eq 'Disorder' or $type_prev eq 'Normal'))
{
	## merge two region
	$range_cur = $domain_range_info_corrected[@domain_disorder_info_corrected-1];
	$range_prev = $domain_range_info_corrected[@domain_disorder_info_corrected-2];
	@range_prev_tmp = split('-',$range_prev);
	$range_prev_start = $range_prev_tmp[0];
	
	@range_cur_tmp = split('-',$range_cur);
	$range_cur_end = $range_cur_tmp[1];
	pop @domain_range_info_corrected;
	pop @domain_range_info_corrected;
	pop @domain_disorder_info_corrected;
	pop @domain_disorder_info_corrected;
	
	print "Merging [$range_cur]:$type_cur and [$range_prev]:$type_prev into [$range_prev_start-$range_cur_end]\n\n";
	push @domain_range_info_corrected,"$range_prev_start-$range_cur_end";
	push @domain_disorder_info_corrected,"Normal";
}
=cut

@domain_start = ();
@domain_end = (); 
#print out domain information
$domain_def = "$dir_output/domain_info_final";
open(DOM_DEF, ">$domain_def");
print "\nCorrected domain regions:\n";
for($i=0;$i<@domain_range_info_corrected;$i++)
{
	print "domain $i:".$domain_range_info_corrected[$i]." ".$domain_disorder_info_corrected[$i]."\n";
	print DOM_DEF "domain $i:".$domain_range_info_corrected[$i]." ".$domain_disorder_info_corrected[$i]."\n";
	
	@tmp = split('-',$domain_range_info_corrected[$i]);
	
	push @domain_start, $tmp[0] ; 
	push @domain_end, $tmp[1]; 
}
close DOM_DEF;


@pir_seq = (); #record pir self alignment between domains and the query sequence
@domain_len = ();

#### get domain models 


if (@domain_start > 1) #multiple domain case
{
	print "#### get domain models \n\n";
	$domain_split_comb = 1;
	for ($i = 0; $i < @domain_start; $i++)
	{
		#create a directory 
		$domain_dir = "$dir_output/domain$i";
		`mkdir $domain_dir`;

		$start = $domain_start[$i];
		@astart = split(/:/, $start);
		$end = $domain_end[$i];
		@aend = split(/:/, $end);

		#create a fasta sequence
		$dom_seq = "";

		$prev_idx = 0;

		$align_seq = "";
		$dlen = 0;

		@adjust_start = ();
		@adjust_end = (); 

		print "domain start: $domain_start[$i], domain end: $domain_end[$i]\n";
#		print "astart: @astart\n";
		for ($j = 0; $j < @astart; $j++)
		{
			$x = $astart[$j];
			$y  = $aend[$j];

			##########for non-first domain, extend the front size a little
			$FRONT_EXTENT = 5;
			if ($i > 0 && $j == 0)
			{
					$x -= $FRONT_EXTENT;
					$x >= 1 || die "domain index error.\n";
			}

			push @adjust_start, $x; 
			push @adjust_end, $y; 

			$dom_seq .= substr($qseq, $x - 1, $y - $x + 1);
			#num of gaps
			$n_gaps = $x - $prev_idx - 1;
			$align_seq .= &generate_gaps($n_gaps);

			#$align_seq .= $dom_seq; 
		    $align_seq .= substr($qseq, $x - 1, $y - $x + 1);

			$prev_idx = $y;
			$dlen += ($y - $x + 1);
		}
		#add end gaps
#		print "$qlen - $prev_idx\n";
		$align_seq .= &generate_gaps($qlen - $prev_idx);
		push @pir_seq, $align_seq;
		push @domain_len, $dlen;

		#create a sequence
		open(DOM, ">$dir_output/domain$i.fasta") || die "can't create file domain$i.\n";
		print DOM ">domain$i\n";
		print DOM "$dom_seq\n";
		close DOM;

		#predict the structure of the domain
		#here we need distinguish easy and hard domains
		#we may need to call ab inito appraoches
		print "Get models for domain $i\n";
		#system("$multicom_dir/script/multicom_server_v9.pl $meta_option_easy_domain domain$i.fasta $domain_dir");
#		&extract_model($input_model_file, \@adjust_start, \@adjust_end, $output_model_file); 
		open(RANK, $final_ranking2) || die "can't read $final_ranking2.\n"; 
		@rank = <RANK>;
		close RANK;
		foreach $entry (@rank)
		{
			@fields = split(/\s+/, $entry);
			$model_name = $fields[0]; 	
			$input_model_file = "$dir_models/$model_name";				
			if (!-f $input_model_file)
			{
				$input_model_file .= ".pdb";
			}
			if(!(-e $input_model_file))
			{
				print "Failed to find model $input_model_file\n";
				next;
			}
			$output_model_file = "$domain_dir/$model_name";
			&extract_model($input_model_file, \@adjust_start, \@adjust_end, $output_model_file); 
		}
		#print "Evaluate the models of domain$i using a pairwise approach...\n";

		#system("/home/chengji/casp8/casp10_tools/domain_eva/pairwise_model_eva.pl $domain_dir domain$i.fasta $q_score $tm_score domain$i .");
		
    }
	
		
	#### perform QA evaluation on domain
	print "\n\n#### perform QA evaluation on domain\n\n";
	for ($i = 0; $i < @domain_start; $i++)
	{
		#create a directory 
		$domain_dir = "$dir_output/domain$i";
		$domain_fasta = "$dir_output/domain$i.fasta";
		
			
		$domain_pred_dir = "$dir_output/dom${i}_TS";
		if(!-s $domain_pred_dir)
		{
			`mkdir $domain_pred_dir`;
		}
		####### (1) run full-length human structure prediction 

		#perl /home/casp13/Human_TS/scripts/Auto_human_server.pl T0859 /home/casp13/Human_TS/run/T0859/T0859.fasta /home/casp13/Human_TS/run/T0859 /home/casp13/Human_QA_package/validation/dncon2_results/T0859.dncon2.rr 

		$domain_final_ranking = $domain_pred_dir."/eva/HumanQA_gdt_prediction_sort.txt";
		$domain_final_ranking2 = $domain_pred_dir."/eva_loss0048/HumanQA_gdt_prediction_loss0048_sort.txt";
		if(-e $domain_final_ranking and -e $domain_final_ranking2)
		{
			print "Domain_based evaluation ($domain_final_ranking) has been finished!\n\n";
		}else{
			print "Start to run full_length evaluation!\n\n";
			print("perl /home/casp13/Human_TS/scripts/Auto_human_server.pl domain${i} $domain_fasta $domain_pred_dir NULL $domain_dir\n\n");
			system("perl /home/casp13/Human_TS/scripts/Auto_human_server.pl domain${i} $domain_fasta $domain_pred_dir NULL $domain_dir");
				
			print("perl /home/casp13/Human_TS/scripts/sort_deep_qa_score.pl $domain_pred_dir/eva/HumanQA_gdt_prediction.txt $domain_pred_dir/eva/HumanQA_gdt_prediction_sort.txt\n\n");
			system("perl /home/casp13/Human_TS/scripts/sort_deep_qa_score.pl $domain_pred_dir/eva/HumanQA_gdt_prediction.txt $domain_pred_dir/eva/HumanQA_gdt_prediction_sort.txt");
		}
	#### perform combination 

	# a. modeller
	# a. another tools

	}
}



$final_model_num = 5; 
$cm_model_num = 8; 
if ($domain_split_comb == 1)
{
	#### domain combination using modeller
	print "\n\n#### domain combination using modeller\n\n";
	print "Combine domains into full-length models...\n";

	my $domain_num = @pir_seq;
	my @domain_models = ();

	#get the models of each domain
	for ($i = 0; $i < $domain_num; $i++)
	{
		$domain_dir = "$dir_output/domain$i";
		#$rank_file =  "$dir_output/domain${i}_HumanTS/eva/HumanQA_gdt_prediction_sort.txt";
		$rank_file =  "$dir_output/dom${i}_TS/eva_loss0048/HumanQA_gdt_prediction_loss0048_sort.txt";

		open(RANK, $rank_file) || die "can't open $rank_file.\n";
		@drank = <RANK>;
		close RANK;
		$model = "";
		foreach $record (@drank)
		{
			@fields = split(/\s+/, $record);
			$model_id = $fields[0];
			$model .= "$domain_dir/$model_id ";
		}
			push @domain_models, $model;
	}

	#generate pir alignments and models for each combination
	$comb_dir = $dir_output . "/comb/";
	$atom_dir = $comb_dir . "atom/";

	`mkdir -p $comb_dir $atom_dir`;

	for ($i = 0; $i < $final_model_num; $i++)
	{
		#generate pir alignment for each combination    
		$idx = $i + 1;
		$pir_file = $comb_dir . "comb$idx.pir";

		open(PIR, ">$pir_file") || die "can't create pir file $pir_file.\n";
		for ($j = 0; $j < $domain_num; $j++)
		{
			print PIR "C;combination $i, domain $j\n";

			$model_names = $domain_models[$j];


			@mnames = split(/\s+/, $model_names);
			$model_file = $mnames[$i];

			if (rindex($model_file, ".") > 0)
			{
				$model_name = substr($model_file, rindex($model_file, "/") + 1, rindex($model_file, ".") - rindex($model_file, "/") -1);
			}
			else
			{
				$model_name = substr($model_file, rindex($model_file, "/") + 1);
			}

				$model_name .= "_dom$j";
				print PIR ">P1;$model_name\n";
				#copy the file to the atom dir
				print "cp -f $model_file $atom_dir/$model_name.atom\n";
				`cp -f $model_file $atom_dir/$model_name.atom`;
				print "gzip -f $atom_dir/$model_name.atom\n";
				`gzip -f $atom_dir/$model_name.atom`;
				$dlen = $domain_len[$j];
				print PIR "structureX:$model_name: 1: : $dlen: : : : : \n";
				print PIR "$pir_seq[$j]*\n\n";
		}
		print PIR "C; combination of multiple domains\n";
		print PIR ">P1;comb$idx\n";
		print PIR " : : : : : : : : : \n";

		print PIR "$qseq*\n";
		close PIR;

		#generate models
		print "Use Modeller to generate models combining multiple domains...\n";
		print("$prosys_dir/script/pir2ts_energy.pl $modeller_dir $atom_dir $comb_dir $pir_file $cm_model_num\n\n");
		system("$prosys_dir/script/pir2ts_energy.pl $modeller_dir $atom_dir $comb_dir $pir_file $cm_model_num");

		if ( -f "$comb_dir/comb$idx.pdb")
		{
				print "A combined model $comb_dir/comb$idx.pdb is generated.\n";

			$model_file = "$comb_dir/comb$idx.pdb";
			`mv $model_file $model_file.org`;
			system("/home/chengji/software/scwrl4/Scwrl4 -i $model_file.org -o $comb_dir/casp$idx.scw >/dev/null");
			system("/home/chengji/casp8/model_cluster/script/clash_check.pl $name.fasta $comb_dir/casp$idx.scw > $comb_dir/clash$idx.txt");
			system("$pdb2casp2 $comb_dir/casp$idx.scw $idx $name $comb_dir/casp$idx.pdb");

		}
	}
	
	print "\n\nThe human models are saved in the folder $comb_dir\n\n";

}else{
	print "\n\nThe human models are saved in the folder $full_pred_dir\n\n";
}

FINISH:
print "\n\nHuman tertiary structurep prediction done!\n\n";
	

### no need refine

	
	
#generate a gap sequence with with gnum of -. 
sub generate_gaps
{
        my $gnum = $_[0];
        my $gaps = "";
        my $i;
        for ($i = 0; $i < $gnum; $i++)
        {
                $gaps .= "-";
        }
        return $gaps;
}

sub extract_model  
{
	#extract a range of residues from a model and reorder them 
	my $input_model_file = $_[0];
	my @start_range = @{$_[1]}; 
	my @end_range = @{$_[2]}; 
	my $output_model_file = $_[3]; 


	open(PDB, $input_model_file); 
	my @pdb = <PDB>;
	close PDB;
	open(OUT, ">$output_model_file"); 
	my $prev_res_ord = -1; 
	my $new_atom_ord = 0; 
	my $new_res_ord = 0; 
	while (@pdb)
	{
		my $atom_line = shift @pdb;	
		if ($atom_line !~ /^ATOM/)
		{
			next;
		}
		my $atom_ord = substr($atom_line, 6, 5); 	
		my $res_ord = substr($atom_line, 22, 4); 

		my $selected = 0; 
		my $ii = 0; 
		for ($ii = 0; $ii < @start_range; $ii++)
		{
			if ($start_range[$ii] <= $res_ord && $res_ord <= $end_range[$ii])
			{
				$selected = 1; 	
			}		
		}	
		if ($selected == 1)
		{
			if ($res_ord != $prev_res_ord)
			{
				$new_res_ord++;
			}						
			$new_atom_ord++; 

			$atom_ind = sprintf("%5d", $new_atom_ord);
       		        $new_line = substr($atom_line, 0, 6) . $atom_ind . substr($atom_line, 11);
           		     #replace residue index with new index
        	        $res_ind = sprintf("%4d", $new_res_ord);
               		 $new_line = substr($new_line, 0, 22) . $res_ind . substr($new_line, 26);
			print OUT $new_line;
			
		}

		if ($res_ord != $prev_res_ord)
		{
			$prev_res_ord = $res_ord; 
		}						


	}

	my $total_len = 0; 
	for ($ii = 0; $ii < @start_range; $ii++)
	{
		$total_len += ($end_range[$ii] - $start_range[$ii] + 1); 				
	}	
	$total_len  == $new_res_ord || die "number of extracted residues is not correct for pdb 1 ($total_len  != $new_res_ord) in $input_model_file\n";
	print OUT "TER\nEND\n";
	close OUT; 
#############################################################################################
}
