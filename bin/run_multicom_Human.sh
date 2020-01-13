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

source /home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/python_virtualenv/bin/activate
export LD_LIBRARY_PATH=/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/boost_1_55_0/lib/:/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/OpenBLAS:$LD_LIBRARY_PATH

if [ ! -d "$outputdir" ]; then
  mkdir -p $outputdir
fi

perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/CASP13_human_ts_pipeline.pl $targetid $fastafile $outputdir alignment null $models

