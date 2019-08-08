#!/usr/bin/perl -w
 use FileHandle; # use FileHandles instead of open(),close()
 use Cwd;
 use Cwd 'abs_path';

######################## !!! customize settings here !!! ############################
#																					#
# Set directory of multicom databases and tools								        #

$MULTICOM_dir = "/storage/htc/bdm/jh7x3/multicom/";							        
$DeepRank_dir = "/storage/htc/bdm/jh7x3/DeepRank/";


######################## !!! End of customize settings !!! ##########################

######################## !!! Don't Change the code below##############


$install_dir = getcwd;
$install_dir=abs_path($install_dir);


if(!-d $install_dir)
{
	die "The multicom directory ($install_dir) is not existing, please revise the customize settings part inside the configure.pl, set the path as  your unzipped multicom directory\n";
}

if ( substr($install_dir, length($install_dir) - 1, 1) ne "/" )
{
        $install_dir .= "/";
}


print "checking whether the configuration file run in the installation folder ...";
$cur_dir = `pwd`;
chomp $cur_dir;
$configure_file = "$cur_dir/configure.pl";
if (! -f $configure_file || $install_dir ne "$cur_dir/")
{
        die "\nPlease check the installation directory setting and run the configure program under the main directory of multicom.\n";
}
print " OK!\n";


if (! -d $install_dir)
{
	die "can't find installation directory.\n";
}
if ( substr($install_dir, length($install_dir) - 1, 1) ne "/" )
{
	$install_dir .= "/"; 
}


######### check the DeepRank tool

if($DeepRank_dir eq "$cur_dir/")
{
	die "Same directory as MULTICOM main folder. Differnt path for original databases/tools folder $DeepRank_dir is recommended.\n";
}

#create link for multicom databases and tools
if(-l "${install_dir}DeepRank")
{
	`rm ${install_dir}DeepRank`;
}

`ln -s $DeepRank_dir ${install_dir}DeepRank`;




######### check the MULTICOM tool

if($MULTICOM_dir eq "$cur_dir/")
{
	die "Same directory as MULTICOM main folder. Differnt path for original databases/tools folder $MULTICOM_dir is recommended.\n";
}

#create link for multicom databases and tools
if(-l "${install_dir}multicom")
{
	`rm ${install_dir}multicom`;
}

`ln -s $MULTICOM_dir ${install_dir}multicom`;



#if (prompt_yn("multicom will be installed into <$install_dir> ")){
#
#}else{
#	die "The installation is cancelled!\n";
#}
print "Start install multicom into <$install_dir>\n"; 


print "#########  (1) Configuring option files\n";

$option_list = "$install_dir/installation/configure_list";

if (! -f $option_list)
{
        die "\nOption file $option_list not exists.\n";
}

configure_file2($option_list,'scripts');
print "#########  Configuring option files, done\n\n\n";



system("cp $install_dir/src/run_multicom.sh $install_dir/bin/run_multicom.sh");
system("chmod +x $install_dir/bin/*.sh");



sub prompt_yn {
  my ($query) = @_;
  my $answer = prompt("$query (Y/N): ");
  return lc($answer) eq 'y';
}
sub prompt {
  my ($query) = @_; # take a prompt string as argument
  local $| = 1; # activate autoflush to immediately show the prompt
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}


sub configure_file{
	my ($option_list,$prefix) = @_;
	open(IN,$option_list) || die "Failed to open file $option_list\n";
	$file_indx=0;
	while(<IN>)
	{
		$file = $_;
		chomp $file;
		if ($file =~ /^$prefix/)
		{
			$option_default = $install_dir.$file.'.default';
			$option_new = $install_dir.$file;
			$file_indx++;
			print "$file_indx: Configuring $option_new\n";
			if (! -f $option_default)
			{
					die "\nOption file $option_default not exists.\n";
			}	
			
			open(IN1,$option_default) || die "Failed to open file $option_default\n";
			open(OUT1,">$option_new") || die "Failed to open file $option_new\n";
			while(<IN1>)
			{
				$line = $_;
				chomp $line;

				if(index($line,'SOFTWARE_PATH')>=0)
				{
					$line =~ s/SOFTWARE_PATH/$install_dir/g;
					$line =~ s/\/\//\//g;
					print OUT1 $line."\n";
				}else{
					print OUT1 $line."\n";
				}
			}
			close IN1;
			close OUT1;
		}
	}
	close IN;
}


sub configure_tools{
	my ($option_list,$prefix,$DBtool_path) = @_;
	open(IN,$option_list) || die "Failed to open file $option_list\n";
	$file_indx=0;
	while(<IN>)
	{
		$file = $_;
		chomp $file;
		if ($file =~ /^$prefix/)
		{
			$option_default = $DBtool_path.$file.'.default';
			$option_new = $DBtool_path.$file;
			$file_indx++;
			print "$file_indx: Configuring $option_new\n";
			if (! -f $option_default)
			{
					next;
					#die "\nOption file $option_default not exists.\n";
			}	
			
			open(IN1,$option_default) || die "Failed to open file $option_default\n";
			open(OUT1,">$option_new") || die "Failed to open file $option_new\n";
			while(<IN1>)
			{
				$line = $_;
				chomp $line;

				if(index($line,'SOFTWARE_PATH')>=0)
				{
					$line =~ s/SOFTWARE_PATH/$DBtool_path/g;
					$line =~ s/\/\//\//g;
					print OUT1 $line."\n";
				}else{
					print OUT1 $line."\n";
				}
			}
			close IN1;
			close OUT1;
		}
	}
	close IN;
}



sub configure_file2{
	my ($option_list,$prefix) = @_;
	open(IN,$option_list) || die "Failed to open file $option_list\n";
	$file_indx=0;
	while(<IN>)
	{
		$file = $_;
		chomp $file;
		if ($file =~ /^$prefix/)
		{
			@tmparr = split('/',$file);
			$filename = pop @tmparr;
			chomp $filename;
			$filepath = join('/',@tmparr);
			$option_default = $install_dir.$filepath.'/.'.$filename.'.default';
			$option_new = $install_dir.$file;
			$file_indx++;
			print "$file_indx: Configuring $option_new\n";
			if (! -f $option_default)
			{
					die "\nOption file $option_default not exists.\n";
			}	
			
			open(IN1,$option_default) || die "Failed to open file $option_default\n";
			open(OUT1,">$option_new") || die "Failed to open file $option_new\n";
			while(<IN1>)
			{
				$line = $_;
				chomp $line;

				if(index($line,'SOFTWARE_PATH')>=0)
				{
					$line =~ s/SOFTWARE_PATH/$install_dir/g;
					$line =~ s/\/\//\//g;
					print OUT1 $line."\n";
				}else{
					print OUT1 $line."\n";
				}
			}
			close IN1;
			close OUT1;
		}
	}
	close IN;
}





=pod
database downloading 


/home/casp13/MULTICOM_package/software/prosys_database/cm_lib/chain_stx_info
/home/casp13/MULTICOM_package/software/prosys_database/cm_lib/pdb_cm
/home/casp13/MULTICOM_package/software/prosys_database/cm_lib/pdb_cm.phr
/home/casp13/MULTICOM_package/software/prosys_database/cm_lib/pdb_cm.pin
/home/casp13/MULTICOM_package/software/prosys_database/cm_lib/pdb_cm.psq
/home/casp13/MULTICOM_package/software/prosys_database/cm_lib/pdb_cm_all_sel.fasta 


/home/casp13/MULTICOM_package/software/prosys_database/atom.tar.gz

/home/casp13/MULTICOM_package/software/prosys_database/nr_latest/



=cut
