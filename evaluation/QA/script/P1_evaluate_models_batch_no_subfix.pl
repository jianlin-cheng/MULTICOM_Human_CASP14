#!/usr/bin/perl -w

if (@ARGV != 3) {
  print "Usage: <ExperimentTarget_dir> <Working dir > <true target pdb>\n";
  exit;
}
$pdb_dir = $ARGV[0];
$reference_model = $ARGV[1];
$outputdir = $ARGV[2];




opendir(DIR,"$pdb_dir") || die "Failed to open directory $pdb_dir\n";

@files = readdir(DIR);
closedir(DIR);

open(OUT,">$outputdir/modeller_summary.txt") || die "Failed to open file $outputdir/modeller_summary.txt";
%model2score=();
foreach $file (@files)
{
		chomp $file;
		#if($file eq '.' or $file eq '..' or index($file,'.pdb') <0)
		if($file eq '.' or $file eq '..')
		{
			next;
		}
		$premodel="$pdb_dir/$file";
		$filtered_pdb = $reference_model;
		$t_f="$outputdir/${file}_filtered";

		if(-e $premodel and -e $filtered_pdb)
		{
			print "Evaluate predicted model <$premodel> to native structure <$filtered_pdb>\n";
		}elsif(!(-e $filtered_pdb))
		{
			die  "<$filtered_pdb> is not found\n";
		}
		else{
			print "Predicted model <$premodel> is not found\n";
			next;
		}
		
		print "perl pre2zhang.pl $premodel $filtered_pdb $t_f\n\n";
		`perl pre2zhang.pl $premodel $filtered_pdb $t_f`;
				
	
		open(TMP, ">$outputdir/tmp") || die("Couldn't open file tmp\n");
		my $command1="tools/TMscore $t_f $filtered_pdb";
		print "Run $command1 \n";
		my @result1=`$command1`;

		#system("rm $t_f");
		foreach $j (@result1){
			print TMP $j;
		}
		close TMP;

		open(TMP, "$outputdir/tmp") || die("Couldn't open file tmp\n"); 
		@arr1=<TMP>;
		close TMP;
		$tmscore=0;
		$maxscore=0;
		$gdttsscore=0;
		$rmsd=0;

		foreach $ln2 (@arr1){
			chomp($ln2);
			if ("RMSD of  the common residues" eq substr($ln2,0,28)){
				$s1=substr($ln2,index($ln2,"=")+1);
				while (substr($s1,0,1) eq " ") {
					$s1=substr($s1,1);
				}
				$rmsd=1*$s1;
			}
			if ("TM-score" eq substr($ln2,0,8)){
				$s1=substr($ln2,index($ln2,"=")+2);
				$s1=substr($s1,0,index($s1," "));
				$tmscore=1*$s1;
			}
			if ("MaxSub-score" eq substr($ln2,0,12)){
				$s1=substr($ln2,index($ln2,"=")+2);
				$s1=substr($s1,0,index($s1," "));
				$maxscore=1*$s1;
			}
			if ("GDT-TS-score" eq substr($ln2,0,12)){
				$s1=substr($ln2,index($ln2,"=")+2);
				$s1=substr($s1,0,index($s1," "));
				$gdttsscore=1*$s1;
			}
		}
		
		print $file."\t$gdttsscore\t".$reference_model." \t".$tmscore."\t".$gdttsscore."\t".$rmsd."\t".$maxscore;
		$content = $file."\t$gdttsscore\t".$reference_model." \t".$tmscore."\t".$gdttsscore."\t".$rmsd."\t".$maxscore;
		
		$model2score{$content} = $gdttsscore;
		#print OUT $file."\t".$reference_model." \t".$tmscore."\t".$gdttsscore."\t".$rmsd."\t".$maxscore."\n";
}
close IN;

foreach my $name (sort { $model2score{$b} <=> $model2score{$a} } keys %model2score) {
    print OUT "$name\t".$model2score{$name}."\n";
}


close OUT;

