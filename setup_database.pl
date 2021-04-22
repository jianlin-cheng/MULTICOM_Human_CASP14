#!/usr/bin/perl -w
 use FileHandle; # use FileHandles instead of open(),close()
 use Cwd;
 use Cwd 'abs_path';

 # perl /home/jh7x3/DeepRank_v1.1/setup_database.pl
 
######################## !!! customize settings here !!! ############################
#																					#
# Set directory of DeepRank databases and tools								        #

$multicom_human_db_tools_dir = "/home/jianliu/MULTICOM_Human_CASP14";
						        

######################## !!! End of customize settings !!! ##########################

######################## !!! Don't Change the code below##############

$install_dir = getcwd;
$install_dir=abs_path($install_dir);


if(!-s $install_dir)
{
	die "The multicom human directory ($install_dir) is not existing, please revise the customize settings part inside the configure.pl, set the path as  your unzipped DeepRank directory\n";
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
        die "\nPlease check the installation directory setting and run the configure program under the main directory of DeepRank.\n";
}
print " OK!\n";


if(!(-d $multicom_human_db_tools_dir))
{
	$status = system("mkdir $multicom_human_db_tools_dir");
	if($status)
	{
		die "Failed to create folder $multicom_human_db_tools_dir\n\n";
	}
}
$multicom_human_db_tools_dir=abs_path($multicom_human_db_tools_dir);



if ( substr($multicom_human_db_tools_dir, length($multicom_human_db_tools_dir) - 1, 1) ne "/" )
{
        $multicom_human_db_tools_dir .= "/";
}

print "Start install multicom human system into <$multicom_human_db_tools_dir>\n";

chdir($multicom_human_db_tools_dir);

$database_dir = "$multicom_human_db_tools_dir/databases";
$tools_dir = "$multicom_human_db_tools_dir/tools";

if(!-d $database_dir)
{
	$status = system("mkdir $database_dir");
	if($status)
	{
		die "Failed to create folder ($database_dir), check permission or folder path\n";
	}
	`chmod -R 755 $database_dir`;
}

if(!-d $tools_dir)
{ 
	$status = system("mkdir $tools_dir");
	if($status)
	{
		die "Failed to create folder ($tools_dir), check permission or folder path\n";
	}
	`chmod -R 755 $tools_dir`;
}

#### (1) Download basic tools
print("\n#### (1) Download basic tools\n\n");

chdir($tools_dir);
$basic_tools_list = "scwrl4.tar.gz;TMscore_32.tar.gz;q_score.tar.gz;modeller-9.16.tar.gz;blast-2.2.17.tar.gz;blast-2.2.25.tar.gz;disorder_new.tar.gz;i3Drefine.tar.gz;pspro2.tar.gz;";
@basic_tools = split(';',$basic_tools_list);
foreach $tool (@basic_tools)
{
	$toolname = substr($tool,0,index($tool,'.tar.gz'));
	if(-d "$tools_dir/$toolname")
	{
		if(-e "$tools_dir/$toolname/download.done")
		{
			print "\t$toolname is done!\n";
			next;
		}
	}elsif(-f "$tools_dir/$toolname")
	{
			print "\t$toolname is done!\n";
			next;
	}
	if(-e $tool)
	{
		 `rm $tool`;
	}
 
  if($tool eq 'TMscore_32.tar.gz' or $tools eq 'q_score.tar.gz')
  {
      `wget http://sysbio.rnet.missouri.edu/bdm_download/DeepRank_db_tools/tools/$tool`;
  }
  else
  {
	    `wget http://daisy.rnet.missouri.edu/multicom_db_tools/tools/$tool`;
  }
  
	if(-e "$tool")
	{
		print "\n\t$tool is found, start extracting files......\n\n";
		`tar -zxf $tool`;
		if(-d $toolname)
		{
			`echo 'done' > $toolname/download.done`;
		}
		`rm $tool`;
		`chmod -R 755 $toolname`;
	}
  else
  {
		die "Failed to download $tool from http://daisy.rnet.missouri.edu/multicom_db_tools/tools or http://sysbio.rnet.missouri.edu/bdm_download/DeepRank_db_tools/tools/ , please contact chengji\@missouri.edu\n";
	}
}

#### (2) Download uniref90
print("\n#### (2) Download uniref90\n\n");
$uniref_dir = "$database_dir/uniref";
if(!(-d "$uniref_dir"))
{
	`mkdir $uniref_dir`;
}
chdir($uniref_dir);

if(-e "uniref90.pal")
{
	print "\tuniref90 has been formatted, skip!\n";
}elsif(-e "uniref90.fasta")
{
	print "\tuniref90.fasta is found, start formating......\n";
	`$tools_dir/blast-2.2.25/bin/formatdb -i uniref90.fasta -o T -t uniref90 -n uniref90`;
		`chmod -R 755 uniref90*`;
}else{
	if(-e "uniref90.fasta.gz")
	{
		`rm uniref90.fasta.gz`;
	}
	`wget http://daisy.rnet.missouri.edu/multicom_db_tools/databases/uniref/20190703/uniref90.fasta.gz`;
	if(-e "uniref90.fasta.gz")
	{
		print "\tuniref90.fasta.gz is found, start extracting files\n";
	}else{
		die "Failed to download uniref90.fasta.gz from ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/\n";
	}
	`gzip -d uniref90.fasta.gz`;
	`$tools_dir/blast-2.2.25/bin/formatdb -i uniref90.fasta -o T -t uniref90 -n uniref90`;
		`chmod -R 755 uniref90*`;

}

#### (3) Generating uniref70
print("\n#### (4) Generating uniref70\n\n");
chdir($uniref_dir);

if(-e "uniref70.pal")
{
	print "\tuniref70 has been formatted, skip!\n";
}elsif(-e "uniref70.fasta")
{
	print "\tuniref70.fasta is found, start formating......\n";
	`$tools_dir/blast-2.2.25/bin/formatdb -i uniref70.fasta -o T -t uniref70 -n uniref70`;
}else{
	chdir($uniref_dir);
	if(-e "uniref70.fasta.gz")
	{
		`rm uniref70.fasta.gz`;
	}
	`wget http://daisy.rnet.missouri.edu/multicom_db_tools/databases/uniref/20190703/uniref70.fasta.gz`;
	if(-e "uniref70.fasta.gz")
	{
		print "\tuniref70.fasta.gz is found, start extracting files\n";
	}else{
		die "Failed to download uniref70.fasta.gz from ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref70/\n";
	}
	`gzip -d uniref70.fasta.gz`;

	`$tools_dir/blast-2.2.25/bin/formatdb -i uniref70.fasta -o T -t uniref70 -n uniref70`;
		`chmod -R 755 uniref70*`;
}

#### (4) Linking databases
print("\n#### (6) Linking databases\n\n");

### linking sequence database

-d "$database_dir/nr70_90" || `mkdir $database_dir/nr70_90`;

opendir(DBDIR,"$uniref_dir") || die "Failed to open $uniref_dir\n";
@files = readdir(DBDIR);
closedir(DBDIR);
foreach $file (@files)
{
	if($file eq '.' or $file eq '..')
	{
		next;
	}

	if(substr($file,0,9) eq 'uniref90.')
	{
		$subfix = substr($file,9);
		if(-l "$database_dir/nr70_90/nr90.$subfix")
		{
			$status = system("rm $database_dir/nr70_90/nr90.$subfix");
			if($status)
			{
				die "Failed to remove file ($database_dir/nr70_90/nr90.$subfix), check the permission\n";
			}
		}
		if($subfix eq 'pal')
		{
			## change to nr90
			open(TMP,"$uniref_dir/$file");
			open(TMPOUT,">$database_dir/nr70_90/nr90.pal");
			while(<TMP>)
			{
				$li=$_;
				chomp $li;
				if(index($li,'uniref90')>=0)
				{
					$li =~ s/uniref90/nr90/g;
					print TMPOUT "$li\n";
				}else{
					print TMPOUT "$li\n";
				}
			}
			close TMP;
			close TMPOUT;
			`chmod -R 755 $uniref_dir/$file`;
		}else{

			$status = system("ln -s $uniref_dir/$file $database_dir/nr70_90/nr90.$subfix");
			if($status)
			{
				die "Failed to link database ($database_dir/nr70_90/nr90.$subfix), check the permission\n";
			}

			`chmod -R 755 $database_dir/nr70_90/nr90.$subfix`;
		}
		`chmod -R 755 $uniref_dir/$file`;
	}

	if(substr($file,0,9) eq 'uniref70.')
	{
		$subfix = substr($file,9);
		if(-l "$database_dir/nr70_90/nr70.$subfix")
		{

			$status = system("rm $database_dir/nr70_90/nr70.$subfix");
			if($status)
			{
				die "Failed to remove file ($database_dir/nr70_90/nr70.$subfix), check the permission\n";
			}

		}
		if($subfix eq 'pal')
		{
			## change to nr90
			open(TMP,"$uniref_dir/$file");
			open(TMPOUT,">$database_dir/nr70_90/nr70.pal");
			while(<TMP>)
			{
				$li=$_;
				chomp $li;
				if(index($li,'uniref70')>=0)
				{
					$li =~ s/uniref70/nr70/g;
					print TMPOUT "$li\n";
				}else{
					print TMPOUT "$li\n";
				}
			}
			close TMP;
			close TMPOUT;
		}else{

			$status = system("ln -s $uniref_dir/$file $database_dir/nr70_90/nr70.$subfix");
			if($status)
			{
				 die "Failed to link database ($database_dir/nr70_90/nr70.$subfix), check the permission\n";
			}

			`chmod -R 755 $database_dir/nr70_90/nr70.$subfix`;
		}
		`chmod -R 755 $uniref_dir/$file`;

	}
}

#### (5) Setting up tools and databases for methods
print("\n#### (5) Setting up tools and databases for methods\n\n");

$method_file = "$install_dir/method.list";
$method_info = "$install_dir/installation/server_info";

if(!(-e $method_file) or !(-e $method_info))
{
	print "\nFailed to find method file ($method_file and $method_info), please contact us!\n\n";
}else{

	open(IN,$method_info) || die "Failed to open file $method_info\n";
	@contents = <IN>;
	close IN;
	%method_db_tools=();
	foreach $line (@contents)
	{
		chomp $line;
		if(substr($line,0,1) eq '#')
		{
			next;
		}
		$line =~ s/^\s+|\s+$//g;
		if($line eq '')
		{
			next;
		}
		@tmp = split(':',$line);
		$method_db_tools{$tmp[0]} = $tmp[1];
	}

	open(IN,$method_file) || die "Failed to open file $method_file\n";
	@contents = <IN>;
	foreach $method (@contents)
	{
		chomp $method;
		if(substr($method,0,1) eq '#')
		{
			next;
		}
		$method =~ s/^\s+|\s+$//g;
		if($method eq '')
		{
			next;
		}
		if(exists($method_db_tools{"${method}_tools"}) and exists($method_db_tools{"${method}_databases"}))
		{
			print "\n\tSetting for method <$method>\n\n";
			### tools
			chdir($tools_dir);
			$basic_tools_list = $method_db_tools{"${method}_tools"};
			@basic_tools = split(';',$basic_tools_list);
			foreach $tool (@basic_tools)
			{
				$toolname = substr($tool,0,index($tool,'.tar.gz'));

				if(-d "$tools_dir/$toolname")
				{
					if(-e "$tools_dir/$toolname/download.done")
					{
						print "\t$toolname is done!\n";
						next;
					}
				}elsif(-f "$tools_dir/$toolname")
				{
						print "\t$toolname is done!\n";
						next;
				}

				if(-e $tool)
				{
					`rm $tool`;
				}
				`wget http://daisy.rnet.missouri.edu/multicom_db_tools/tools/$tool`;

				if(-e "$tool")
				{
					print "\n\t\t$tool is found, start extracting files......\n\n";
					`tar -zxf $tool`;
					chdir($tools_dir);
					`echo 'done' > $toolname/download.done`;
					`rm $tool`;
					`chmod -R 755 $toolname`;
				}else{
					die "Failed to download $tool from http://daisy.rnet.missouri.edu/multicom_db_tools/tools, please contact chengji\@missouri.edu\n";
				}
			}

			### databases
			chdir($database_dir);
			$basic_db_list = $method_db_tools{"${method}_databases"};
			@basic_db = split(';',$basic_db_list);
			foreach $db (@basic_db)
			{
				$dbname = substr($db,0,index($db,'.tar.gz'));
				if(-e "$database_dir/$dbname/download.done")
				{
					print "\t\t$dbname is done!\n";
					next;
				}
				`wget http://daisy.rnet.missouri.edu/multicom_db_tools/databases/$db`;
				if(-e "$db")
				{
					print "\t\t$db is found, start extracting files......\n\n";
					`tar -zxf $db`;
					`echo 'done' > $dbname/download.done`;
					`rm $db`;
					`chmod -R 755 $dbname`;
				}else{
					die "Failed to download $db from http://daisy.rnet.missouri.edu/multicom_db_tools/databases, please contact chengji\@missouri.edu\n";
				}
			}
		}else{
			print "Failed to find database/tool definition for method $method\n";
		}
	}
}

print "######### (6) Configuring tools\n";

$option_list = "$install_dir/installation/MULTICOM_configure_files/multicom_tools_list";

if (! -f $option_list)
{
        die "\nOption file $option_list not exists.\n";
}
configure_tools($option_list,'tools',$multicom_human_db_tools_dir);

print "#########  Configuring tools, done\n\n\n";


configure_tools($option_list,'tools',$multicom_human_db_tools_dir);

my($addr_mod9v16) = $multicom_human_db_tools_dir."/tools/modeller-9.16/bin/mod9.16";
if(-e $addr_mod9v16)
{
	print "\n#########  Setting up MODELLER 9v16 \n";
	if (!-s $addr_mod9v16) {
		die "Please check $addr_mod9v16, you can download the modeller and install it by yourself if the current one in the tool folder is not working well, the key is MODELIRANJE.  please install it to the folder tools/modeller-9.16, with the file mod9v7 in the bin directory\n";
	}

	my($deep_mod9v16) = $multicom_human_db_tools_dir."/tools/modeller-9.16/bin/modeller9v16local";
	$OUT = new FileHandle ">$deep_mod9v16";
	$IN=new FileHandle "$addr_mod9v16";
	while(defined($line=<$IN>))
	{
			chomp($line);
			@ttt = split(/\=/,$line);

			if(@ttt>1 && $ttt[0] eq "MODINSTALL9v16")
			{
					print $OUT "MODINSTALL9v16=\"$multicom_human_db_tools_dir/tools/modeller-9.16\"\n";
			}
			else
			{
					print $OUT $line."\n";
			}
	}
	$IN->close();
	$OUT->close();
	#system("chmod 777 $deep_mod9v16");
	$modeller_conf = $multicom_human_db_tools_dir."/tools/modeller-9.16/modlib/modeller/config.py";
	$OUT = new FileHandle ">$modeller_conf";
	print $OUT "install_dir = r\'$multicom_human_db_tools_dir/tools/modeller-9.16/\'\n";
	print $OUT "license = \'MODELIRANJE\'";
	$OUT->close();
	#system("chmod 777 $modeller_conf");
	system("cp $deep_mod9v16 $addr_mod9v16");
	print "Done\n";
}

$tooldir = $multicom_db_tools_dir.'/tools/pspro2/';
if(-d $tooldir)
{
	print "#########  Setting up pspro2\n";
	chdir $tooldir;
	if(-f 'configure.pl')
	{
		$status = system("perl configure.pl");
		if($status){
			die "Failed to run perl configure.pl \n";
			exit(-1);
		}
	}else{
		die "The configure.pl file for $tooldir doesn't exist, please contact us(Jie Hou: jh7x3\@mail.missouri.edu)\n";
	}
}

######
$tooldir = $multicom_human_db_tools_dir.'/tools/disorder_new/';
if(-d $tooldir)
{
	print "\n\n#########  Setting up disorder\n";
	chdir $tooldir;
	if(-f 'configure.pl')
	{
		$status = system("perl configure.pl");
		if($status){
			die "Failed to run perl configure.pl \n";
			exit(-1);
		}
	}else{
		die "The configure.pl file for $tooldir doesn't exist, please contact us(Jie Hou: jh7x3\@mail.missouri.edu)\n";
	}
}

$addr_scwrl4 = $multicom_human_db_tools_dir."/tools/scwrl4";
if(-d $addr_scwrl4)
{
	print "\n#########  Setting up scwrl4 \n";
	$addr_scwrl_orig = $addr_scwrl4."/"."Scwrl4.ini";
	$addr_scwrl_back = $addr_scwrl4."/"."Scwrl4.ini.back";
	system("cp $addr_scwrl_orig $addr_scwrl_back");
	@ttt = ();
	$OUT = new FileHandle ">$addr_scwrl_orig";
	$IN=new FileHandle "$addr_scwrl_back";
	while(defined($line=<$IN>))
	{
		chomp($line);
		@ttt = split(/\s+/,$line);
		
		if(@ttt>1 && $ttt[1] eq "FilePath")
		{
			print $OUT "\tFilePath\t=\t$addr_scwrl4/bbDepRotLib.bin\n"; 
		}
		else
		{
			print $OUT $line."\n";
		}
	}
	$IN->close();
	$OUT->close();
	print "Done\n";
}

print "\n\n";




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



