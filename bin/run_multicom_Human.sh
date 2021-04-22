#!/bin/sh
if [ $# -ne 4 ]
then
        echo "need three parameters: target id, input fasta file, output directory."
        exit 1
fi

targetid=$1
fastafile=$2
outputdir=$3
models=$4

source /home/jianliu/MULTICOM_Human_CASP14/DeepRank3/tools/python_virtualenv/bin/activate
export LD_LIBRARY_PATH=/home/jianliu/MULTICOM_Human_CASP14/DeepRank3/tools/boost_1_55_0/lib/:/home/jianliu/MULTICOM_Human_CASP14/DeepRank3/tools/OpenBLAS:$LD_LIBRARY_PATH

if [ ! -d "$outputdir" ]; then
  mkdir -p $outputdir
fi

perl /home/jianliu/MULTICOM_Human_CASP14/scripts/CASP14_human_ts_pipeline.pl $targetid $fastafile $outputdir alignment null null $models

