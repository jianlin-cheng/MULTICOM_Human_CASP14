# MULTICOM_Human_CASP14
MULTICOM human system for CASP14 tertiary structure prediction


**(1) Download MULTICOM_Human_CASP14 package (short path is recommended)**

```
cd /home/MULTICOM_Human_CASP14
git clone https://github.com/jianlin-cheng/MULTICOM_Human_CASP14.git
cd MULTICOM_Human_CASP14
```


**(2) Configure MULTICOM and DeepRank system (required)**

```
a. edit configure.pl

b. set the path of variable '$MULTICOM_dir' for MULTICOM method (i.e., /storage/htc/bdm/jh7x3/multicom/).

c. set the path of variable '$DeepRank_dir' for DeepRank method (i.e., /storage/htc/bdm/jh7x3/DeepRank/).

$MULTICOM_dir = "/storage/htc/bdm/jh7x3/multicom/";
$DeepRank_dir = "/storage/htc/bdm/jh7x3/DeepRank/";


d. save configure.pl

perl configure.pl
```


**(3) Test example (required)**

```
cd examples/

sh T0-run-multicom-T0951.sh
```


**(4) Run multicom prediction (required)**

```
   Usage:
   $ sh bin/run_multicom.sh <target id> <file name>.fasta  <output folder>

   Example:
   $ sh bin/run_multicom.sh T0993s2 examples/T0993s2.fasta test_out/T0993s2_out
```
