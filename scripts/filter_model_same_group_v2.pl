#!/usr/bin/perl -w

if (@ARGV !=3)
{
	die "need three parameters: model name list, output list, tm score path(eg:/home/chengji/software/tm_score2).\n";
}

$name_list = shift @ARGV;
$output_list = shift @ARGV;

$tm_score = shift @ARGV;


open(LIST, $name_list) || die "can't read $name_list.\n";
@list = <LIST>;
close LIST;

@sort_list = sort @list;

@filter_list = ();
while (@sort_list)
{
	$name = shift @sort_list;
	chomp $name;
	#get the stub name
	$stubname = substr($name, rindex($name, '/')+1);
	$model_no = substr($stubname, length($stubname) - 1, 1);
	$model_name = substr($stubname, 0, length($stubname) - 1);
	#print "$model_name$model_no\n";

#	$model_no == 1 || next;

	#check if the model is similar to previous model of the same group
	$removed = 0;

	foreach $filter_model (@filter_list)
	{
		$fname = $filter_model;
		#get the stub name
		$fstubname = substr($fname, rindex($fname, '/')+1);
		$fmodel_name = substr($fstubname, 0, length($fstubname) - 1);
		if ($model_name eq $fmodel_name || ($model_name =~ /^MULTICOM/ && $fmodel_name =~/^MULTICOM/) || ($model_name =~ /^RBO/ && $fmodel_name =~/^RBO/) || ($model_name =~ /^Pcons/ && $fmodel_name =~/^Pcons/) || ($model_name =~ /^FALCON/ && $fmodel_name =~/^FALCON/) || ($model_name =~ /^Zhang-/ && $fmodel_name =~ /^Zhang-/) || ($model_name =~ /^Yang/ && $fmodel_name =~ /^Yang/) || ($model_name =~ /^tFold/ && $fmodel_name =~ /^tFold/))
		#if ($model_name eq $fmodel_name || ($model_name =~ /^RBO/ && $fmodel_name =~/^RBO/) )
		{
			#compare two models
			system("$tm_score $fname $name > $fstubname.out");
			open(RES, "$fstubname.out") || die "can't read $fstubname.out\n";
			@res = <RES>;
			close RES;
			`rm $fstubname.out`;
			foreach $line (@res)
			{
				if ($line =~ /^GDT-TS-score= ([\d\.]+) /)
				{
					$gdt_score = $1;
					if ($gdt_score > 0.95)
					{
						$removed = 1;
						print "Two models are similar: $name, $fname, score = $gdt_score\n";
						last;
					}
				}
			}

		}
	}

	if ($removed == 1)
	{
		print "$name is similar to a model in the same group. removed.\n";
	}
	else
	{
		push @filter_list, $name;
	}

}

open(OUT, ">$output_list");
foreach $model (@filter_list)
{
	print OUT "$model\n";
}
close OUT;




