# MULTICOM_Human_CASP14
CASP14 evaluation scripts


**(1) Manually create two files in 'script' directory: pdb_ids and target_ids**
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
mkdir tarball
cd tarball

wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1024.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1026.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1030.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1031.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1033.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1035.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1036s1.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1037.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1039.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1040.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1041.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1042.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1043.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1046s1.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1046s2.3D.srv.tar.gz
wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/T1072s2.3D.srv.tar.gz

tar -zxvf T1024.3D.srv.tar.gz
tar -zxvf T1026.3D.srv.tar.gz
tar -zxvf T1030.3D.srv.tar.gz
tar -zxvf T1031.3D.srv.tar.gz
tar -zxvf T1033.3D.srv.tar.gz
tar -zxvf T1035.3D.srv.tar.gz
tar -zxvf T1036s1.3D.srv.tar.gz
tar -zxvf T1037.3D.srv.tar.gz
tar -zxvf T1039.3D.srv.tar.gz
tar -zxvf T1040.3D.srv.tar.gz
tar -zxvf T1041.3D.srv.tar.gz
tar -zxvf T1042.3D.srv.tar.gz
tar -zxvf T1043.3D.srv.tar.gz
tar -zxvf T1046s1.3D.srv.tar.gz
tar -zxvf T1046s2.3D.srv.tar.gz
tar -zxvf T1072s2.3D.srv.tar.gz

cd ..
mkdir temp target_results

###run evaluation script, results are stored in target_results
cd script
perl eva_casp_v2.pl ../pdb_filtered/ ../tarball ../temp/ ../tools/TMscore_32 ./ ./target_ids ../target_results

cd ../target_results/
more T1024.result

###Columns for the result table(number means the number of submitted model):
###groupname,tmscore1,MaxSub-score1,GDT-TS1,tmscore2,MaxSub-score2,GDT-TS2,tmscore3,MaxSub-score3,GDT-TS3,tmscore4,MaxSub-score4,GDT-TS4,tmscore5,MaxSub-score5,GDT-TS5
```


