# MULTICOM_Human_CASP14
CASP14 QA evaluation scripts

**(1) Set up your python2.7 environment**
```
pip install numpy
pip install scipy
```

**(2) Download all server models**
```
cd tarball
python download_CASP14.py
```

**(3) Download all true structures**
```
cd ../true_pdbs
scp username@lewis.rnet.missouri.edu:/storage/htc/bdm/jianliu/CASP14/pdb/full/* .
```

**(4) Run following commands to evaluate QAs**
```
cd ../script
perl batch_evaluate.pl ../tarball ../workdir ../true_pdbs ../qa_scores

perl filter_pdb.pl pdb_ids target_ids ../pdb_orig ../sequence ../alignment ../pdb_filtered
perl P4_summarize_QA.pl ../workdir result.txt
```

**(5) Customize the program to evaluate your qa scores**

**(5a) Copy your qa scores into the workdir (line 28-31 in script/P2_combine_score_into_SVMformat.pl)** 

**(5b) Modify the feature list (line 38 in script/P2_combine_score_into_SVMformat.pl)**