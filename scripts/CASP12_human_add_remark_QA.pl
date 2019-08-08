#! /usr/bin/perl -w

 require 5.003; # need this version of Perl or newer
 use English; # use English names, not cryptic ones
 use FileHandle; # use FileHandles instead of open(),close()
 use Carp; # get standard error / warning messages
 use strict; # force disciplined use of variables
 use Cwd;
 use Cwd 'abs_path';
 use Scalar::Util qw(looks_like_number);
 sub get_len($);
 if(@ARGV<4)
 {
     print "This script just add the final REMARK and local QA for the genrated casp12 human pdbs!\n";
     print "perl $0 servername_of_this_model addr_local_QA_CASP_format addr_input_model addr_output\n";
     print "For example:\n";
     print "perl $0 MULTICOM-REFINE_TS1 ../data/NOVEL_final.prediction ../data/casp1.pdb ../result/casp1.pdb\n";
     print "perl $0 QUARK_TS1 ../all_scores/T0759/T0759.NOVELqa ../result/T0759_selected/casp1.pdb ../result/T0759_final_5_models/casp1.pdb\n";
     exit(0);
 }

 my($start_name)=$ARGV[0];
 my($QAlocal)=abs_path($ARGV[1]);
 my($input_model) = abs_path($ARGV[2]);
 my($output_model)=abs_path($ARGV[3]);


 my($file,$path_one_target,$path_out);
 my(@files,@tem);
 my($IN,$OUT,$line,$i);
 my(@local_QA)=();
 my($index_local)=0;
 
 ######## search the start name at the QAlocal file, get the local QA of that model #########
 my($tag)=0;
 $IN = new FileHandle "$QAlocal";
 while(defined($line=<$IN>))
 {
    chomp($line);
    @tem = split(/\s+/,$line);
    if(looks_like_number($tem[0]) || $tem[0] eq "X")
    {# this is the local QA line
       if($tag == 0)
       {# not the model we want
           next;
       }
       for($i=0;$i<@tem;$i++)
       {
           $local_QA[$index_local++]=$tem[$i];
       }
    }
    else
    {
       if($tag == 1)
       {# we come to a new model quality
          last;
       }
       if($tem[0] eq $start_name)
       {# get the server name
          $tag=1;
          for($i=2;$i<@tem;$i++)
          {
             $local_QA[$index_local++] = $tem[$i];
          }
       }
    }
 }
 $IN->close();
 
 ##### convert X to 10?? #######
 for($i=0;$i<@local_QA;$i++)
 {
    if($local_QA[$i] eq "X")
    {
       $local_QA[$i] = 99;
    }
 }
  
 if($tag == 1)
 {
    print "We get the model: "."@local_QA"."\n";
 }
 else
 {
    print "we don't get the model!\n";
 }
 
 my($model_len) = get_len($input_model);          # get the sequence length of the input model
 if($model_len != $index_local)
 {
    print "Error, the local QA length $index_local of input model is not equal to the model atom length $model_len!\n";
    print "Trying to fix this problem ...\n";
    if($index_local < $model_len)
    {
       for(;$index_local<$model_len;$index_local++)
       {
          $local_QA[$index_local] = 99;
       }
       print "Fixed, please double check here!\n";
    }
    else
    {
       die "Sorry, cannot fix this problem! check here!\n";
    }
 } 

 $i=0;
 my($index);
 my($current_index)="NULL"; 
 $OUT = new FileHandle ">$output_model";
 my($l_len);
 $IN = new FileHandle "$input_model";
 while(defined($line=<$IN>))
 {
    chomp($line);
    @tem = split(/\s+/,$line);
    if($tem[0] eq "AUTHOR")
    {
       next;
    }
    if($tem[0] eq "PFRMAT")
    {
       print $OUT $line."\n"; 
       next;
    }
    if($tem[0] eq "METHOD")
    {
       next;
    }
    if($tem[0] eq "TARGET")
    {
       print $OUT $line."\n";
       #print $OUT "AUTHOR 1528-6535-8094\n";
       print $OUT "AUTHOR MULITCOM\n";
       print $OUT "METHOD model evaluation, model combination, and model refinement\n";
       ### add the remark ####
       print $OUT "REMARK 1\t$start_name\n";
       print $OUT "REMARK 2\tmodel selection based on both single and pairwise QA, model combination, and model optimization\n";
       next;
    }
    if($tem[0] ne "ATOM")
    {
       print $OUT $line."\n";
       next;
    }
    ### get the index ###
    $index = substr($line,22,4);
    $index = int($index);   
    if($current_index eq "NULL")
    {
       $current_index = $index;
######## change the local QA ##########
       $local_QA[$i] = sprintf("%6.2f",$local_QA[$i]);
#print "\n";
#print $local_QA[$i];
#die;
       substr($line,60,6) = "      ";
       substr($line,60,6) = $local_QA[$i]; 

    }
    else
    {
       if($current_index != $index)
       {# a new atom
          $current_index=$index;
          $i++;
       }
######## change the local QA ##########
       substr($line,60,6) = "      ";
#       $local_QA[$i] = sprintf("%3.2f",$local_QA[$i]);
       $local_QA[$i] = sprintf("%6.2f",$local_QA[$i]);

       substr($line,60,6) = $local_QA[$i];

    }
    $l_len = length($line);
    $l_len = 78-$l_len;
    for(;$l_len>0;$l_len--)
    {
       $line.=" ";
    }

    print $OUT $line."\n";
 }
 $IN->close();
 $OUT->close();

 sub get_len($)
 {
    my($input)=@_;
    my($IN,$line,$index);
    my(@tem);
    my($c_l)="NULL";
    my($len)=0;
    $IN= new FileHandle "$input";
    while(defined($line=<$IN>))
    {
      chomp($line);
      @tem = split(/\s+/,$line);
      if($tem[0] eq "ATOM")
      {
         $index = substr($line,22,4);
         $index=int($index);
         if($c_l eq "NULL")
         {
            $len++;
            $c_l=$index;
         }
         else
         {
            if($c_l != $index)
            {
               $c_l=$index;
               $len++;
            }
         }
      }
    }
    $IN->close();
    return $len;
 } 
