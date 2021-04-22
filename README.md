# MULTICOM_Human_CASP14
MULTICOM human system for CASP14 tertiary structure prediction


**(1) Download MULTICOM_Human_CASP14 package (short path is recommended)**

```
cd /home/MULTICOM_Human_CASP14
git clone --branch CASP14_DeepRank3 https://github.com/jianlin-cheng/MULTICOM_Human_CASP14.git
cd MULTICOM_Human_CASP14
```

**(2) Download databases and tools (required)**

```
a. edit setup_database.pl

    Set the path of variable '$multicom_human_db_tools_dir' for your current installation path (i.e., /data/commons/MULTICOM_Human_CASP14/).

b. perl setup_database.pl
```

**(3) Configure DeepRank and DeepRank3 system (required)**

```
a. edit configure.pl

b. set the path of variable '$DeepRank_dir' for MULTICOM method (i.e., /storage/htc/bdm/jh7x3/DeepRank/).

c. set the path of variable '$DeepRank3_dir' for DeepRank method (i.e., /storage/htc/bdm/jh7x3/DeepRank3/).

$DeepRank_dir = "/storage/htc/bdm/jh7x3/DeepRank/";
$DeepRank3_dir = "/storage/htc/bdm/jh7x3/DeepRank3/";


d. save configure.pl

perl configure.pl
```

**(4) Test example (required)**

```
cd examples/

sh T0-run-multicom-T0951.sh
```


**(5) Run multicom prediction (required)**

```
   Usage:
   $ sh bin/run_multicom_Human.sh <target id> <file name>.fasta  <output folder> <3D models>

   Example:
   $ sh bin/run_multicom_Human.sh T0993s2 /home/MULTICOM_Human_CASP14/examples/T0993s2.fasta /home/MULTICOM_Human_CASP14/test_out/T0993s2_out /home/MULTICOM_Human_CASP14/examples/T0951
```
