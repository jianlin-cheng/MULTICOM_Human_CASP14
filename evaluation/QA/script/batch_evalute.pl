use FileHandle; # use FileHandles instead of open(),close()
use Cwd 'abs_path';

if(@ARGV != 4)
{
  print "Usage: <Model dir> <Working dir > <True pdb dir> <QA scores dir>\n";
  exit;
}

$all_model_dir = abs_path($ARGV[1]); #This is where you store your input models, "/home/jlkcp/work/CASP14/TS_common/evaluation/tarballs";
$output_base_dir =  abs_path($ARGV[2]);#This is where you store your outputs, "/home/jlkcp/work/CASP14/TS_common/evaluation/stage2/";
$true_pdb_dir = abs_path($ARGV[3]);#This is where you store your true structures(named by their names), "/home/jlkcp/work/CASP14/TS_common/evaluation/true_pdbs";
$qa_dir = abs_path($ARGV[4]); #This is where you stored your predicted qa scores, "/home/jlkcp/work/CASP14/TS_common/qa2";

opendir (DIR, $true_pdb_dir) or die "can't open the directory!";
@dir = readdir DIR;
foreach $target (@dir)
{
    if(index($target,'.pdb') == -1 || $target eq "." || $target eq "..")
    {
        next;
    }
    $idx = index($target,'.pdb');
    $targetname = substr($target, 0, $idx);
    
    print "Running target $targetname\n";
    $all_models = "$all_model_dir/$targetname";
    $target_pdb_filtered = "$true_pdb_dir/$targetname.pdb";
    $output_dir = "$output_base_dir/data/$targetname"."_eva";
    -d "$output_dir" || `mkdir $output_dir`;
    if(!-e "$output_dir/modeller_summary.txt")
    {
      `perl P1_evaluate_models_batch_no_subfix.pl $all_models $target_pdb_filtered $output_dir`;
    }
    `perl P2_combine_score_into_SVMformat.pl $all_models $targetname $output_dir $qa_dir $output_dir/modeller_summary.txt &> $targetname.log`;
    $feature_dir = "$output_dir/feature_analysis";
    `mkdir $feature_dir`;
    `perl P3_evaluate_feature_by_targets.pl $output_dir/all_scores.summary  $feature_dir  $output_dir/all_scores.eva`;
}
