# MULTICOM_Human_CASP14
CASP14 evaluation scripts


**(1) Manually create two files in 'script' directory: pdb_ids(pdb codes) and target_ids**
```
pdb_ids     target_ids	
6t1z	    T1024
6s44	    T1026
6poo	    T1030
6vr4	    T1031
6n64	    T1032
6vr4	    T1033
6vr4	    T1035
6vn1	    T1036s1
6vr4	    T1037
6vr4	    T1039
6vr4	    T1040
6vr4	    T1041
6vr4	    T1042
6vr4	    T1043
6px4	    T1046s1
6px4	    T1046s2
6hk8	    T1072s2
```

**(2) Create folders and copy sequence files (fasta format) into sequence folder(Already have CASP14 sequences in the folder)**
```
mkdir pdb_orig alignment pdb_filtered
```

**(3) Run following commands to generate filtered pdbs(stored in ../pdb_filtered)**
```
cd script
rm ../pdb_orig/*
perl filter_pdb.pl pdb_ids target_ids ../pdb_orig ../sequence ../alignment ../pdb_filtered
```


**(4) Run evaluation scripts for server models**

```
###download all server models
cd ..
cd tarball
python download_CASP14.py

cd ..
mkdir temp target_results

###run evaluation script, results are stored in target_results
cd script
perl eva_casp_v2.pl ../pdb_filtered/ ../tarball ../temp/ ../tools/TMscore_32 ./ ./target_ids ../target_results

cd ..
more target_results/T1024.result

###Columns for the result table(number means the number of submitted model):
###groupname,tmscore1,MaxSub-score1,GDT-TS1,tmscore2,MaxSub-score2,GDT-TS2,tmscore3,MaxSub-score3,GDT-TS3,tmscore4,MaxSub-score4,GDT-TS4,tmscore5,MaxSub-score5,GDT-TS5

###calculate zscores
mkdir Z_score
perl script/zscore_1_all.pl target_results/ Z_score/
perl script/zscore_5_all.pl target_results/ Z_score/

###The zscore ranking file is zscore_1.txt and zscore_5.txt
more Z_score/zscore_1.txt
more Z_score/zscore_5.txt

```

**(4) Post-evaluation for all targets based on domains**
```
mkdir -p domain_pdbs/all
cd domain_pdbs/all

###download CASP14 native domain structures from lewis server
scp username@lewis.rnet.missouri.edu:/storage/htc/bdm/jianliu/CASP14/pdb/domain/* .
ls *pdb > target_domain.list

cd  ../..
mkdir domain_temp pdb_filtered_domain_eva pdb_filtered_domain_eva_target_results
cd script
perl eva_casp_v2_DomainBased.pl ../domain_pdbs/all  ../tarball/  ../domain_temp/ ../tools/TMscore_32 ../pdb_filtered_domain_eva ../domain_pdbs/all/target_domain.list ../pdb_filtered_domain_eva_target_results

perl script/zscore_1_all.pl pdb_filtered_domain_eva_target_results/ pdb_filtered_domain_eva_Z_score/
perl script/zscore_5_all.pl pdb_filtered_domain_eva_target_results/ pdb_filtered_domain_eva_Z_score/
```