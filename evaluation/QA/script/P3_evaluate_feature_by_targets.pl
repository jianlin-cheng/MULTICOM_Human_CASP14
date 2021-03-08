$num = @ARGV;



if($num != 3)
{
  die "The number of parameter is not correct!\n";
}

$feature_summary = $ARGV[0];
$workdir = $ARGV[1];
$resultfile = $ARGV[2];

if(-e $resultfile)
{
  `rm $resultfile`;
}

#1:feature_DeepQA 2:feature_pairwiseScore 3:feature_RF_SRS 4:feature_dfire 5:feature_pcons 6:feature_RWplus 7:feature_voronot
#a 8:feature_dope 9:feature_proq2 10:feature_proq3_lowres 11:feature_proq3_highres 12:feature_proq3 13:feature_proq2D_global 14:fe
#ature_proq3D_global 15:feature_proq3D_ProQRosCenD_global 16:feature_proq3D_ProQRosFAD_global 17:modfoldclust2 18:feature_modeleva
# 19:feature_OPUS 20:feature_QApro 21:NOVEL_final_prediction 22:feature_total_surf 23:feature_ss_sim 24:feature_solvent 25:feature
#_surface 26:feature_weighted 27:feature_euclidean 28:feature_ss_penalty


#### get target list
open(IN,$feature_summary) || die "Failed to find $feature_summary\n";  # #T0838:eThread_TS2
%train_target_list = ();
$c=0;
while(<IN>)
{
  $line=$_;
  chomp $line;
  if(index($line,'#LGA')>=0)
  {
    next;
  }
  @tmp = split(/\s/,$line);
  $target_info = pop @tmp;
  @tmp2 = split(':',$target_info);
  $targetid = $tmp2[0];###T0838
  if(substr($targetid,0,1) eq '#')
  {
      $targetid = substr($targetid,1);
  }
  $train_target_list{$targetid} = 1;
}
close IN;


foreach $target (sort keys %train_target_list)
{
  chomp $target;
  print "grep $target  $feature_summary > $workdir/$target.txt\n";
  `grep $target  $feature_summary > $workdir/$target.txt`;
  
  print "python /home/jlkcp/work/CASP14/TS_common/evaluation/stage2/P1_evaluate_feature_per_target_20180201.py $workdir/$target.txt $target >> $resultfile\n";
	`python /home/jlkcp/work/CASP14/TS_common/evaluation/stage2/P1_evaluate_feature_per_target_20180201.py $workdir/$target.txt $target >> $resultfile`;
	
}
