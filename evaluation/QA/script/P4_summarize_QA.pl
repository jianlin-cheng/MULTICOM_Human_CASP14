#!/usr/bin/perl -w

$numArgs = @ARGV;
if($numArgs != 2)
{   
	print "the number of parameters is not correct!\n";
	exit(1);
}

$score_dir		= "$ARGV[0]";
$outputfile		= "$ARGV[1]";

open(OUT,">$outputfile") || die "Failed to open file $outputfile\n\n";

$all_features_list2 = "DeepRank";

@all_features = split(',',$all_features_list2);

print "Total features number: ".@all_features."\n";


opendir(DIR,"$score_dir") || die "Failed to open dir $score_dir\n\n";
@subdirs = readdir(DIR);
closedir(DIR);

print OUT "Feature\tTarget\tFeature_index\tMSE\tCorr\tLoss\n";

%corr_summary=();
%corr_num=();
%loss_summary=();
%loss_num=();
foreach $subdir (@subdirs)
{
	chomp $subdir;
	if(substr($subdir,length($subdir)-4) ne '_eva')
	{
		next;
	}
	
	$evadir = "$score_dir/$subdir";
	$targetid = substr($subdir,0,index($subdir,'_eva'));
	print "Evaluating $targetid.....\n";
	$scorefile = "$evadir/all_scores.eva";
	if(!(-e $evadir))
	{
		die "Failed to find $evadir\n\n";
	}
	
	open(IN,"$scorefile");
	@contents = <IN>;
	close IN;
	if(@contents != @all_features)
	{
		die "The feature number not match\n\n".@contents." != ".@all_features."\n\n";
	}
	foreach $line (@contents)
	{
		chomp $line;
		@tmp = split(/\s/,$line);
		$targetid = $tmp[0];
		$feature = $tmp[1];
		$MSE = $tmp[2];
		$Corr = $tmp[3];
		$Loss = $tmp[4];
		@tmp2 = split(/\_/,$feature);
		$featureid = $tmp2[1];
		$featurename = $all_features[$featureid-1];
		print  OUT "$targetid\t$featurename\t$feature\t$MSE\t$Corr\t$Loss\n";
		if(exists($corr_summary{$featurename}))
		{
			$corr_summary{$featurename} += $Corr;
			$loss_summary{$featurename} += $Loss;
			$corr_num{$featurename} += 1;
			$loss_num{$featurename} += 1;
		}else{
			$corr_summary{$featurename} = $Corr;
			$loss_summary{$featurename} = $Loss;
			$corr_num{$featurename} = 1;
			$loss_num{$featurename} = 1;
		}
	}
	
}

print "\n\nFeature\tAvg_corr\tAvg_loss\tTarget_num\n";
print OUT "\n\nFeature\tAvg_corr\tAvg_loss\tTarget_num\n";
foreach $featurename (sort keys %corr_summary)
{
	$corr_avg = sprintf("%.5f",$corr_summary{$featurename}/$corr_num{$featurename});
	$loss_avg = sprintf("%.5f",$loss_summary{$featurename}/$loss_num{$featurename});
	print "$featurename\t$corr_avg\t$loss_avg\t".$corr_num{$featurename}."\n";
	print OUT "$featurename\t$corr_avg\t$loss_avg\t".$corr_num{$featurename}."\n";
}
close OUT;

