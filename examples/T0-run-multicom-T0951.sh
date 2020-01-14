#!/bin/bash
#SBATCH -J  T0951
#SBATCH -o T0951-%j.out
#SBATCH --partition Lewis,hpc5,hpc4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=2G
#SBATCH --time 2-00:00

mkdir -p /home/jh7x3/MULTICOM_Human_CASP14/test_out/T0951_multicom/
cd /home/jh7x3/MULTICOM_Human_CASP14/test_out/T0951_multicom/

source /home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/python_virtualenv/bin/activate
export LD_LIBRARY_PATH=/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/boost_1_55_0/lib/:/home/jh7x3/MULTICOM_Human_CASP14/multicom/tools/OpenBLAS:$LD_LIBRARY_PATH

if [[ ! -f "/home/jh7x3/MULTICOM_Human_CASP14/test_out/T0951_multicom/mcomb/casp1.pdb" ]];then 
	perl /home/jh7x3/MULTICOM_Human_CASP14/scripts/CASP13_human_ts_pipeline.pl T0951 /home/jh7x3/MULTICOM_Human_CASP14/examples/T0951.fasta /home/jh7x3/MULTICOM_Human_CASP14/test_out/T0951_multicom/ alignment null /home/jh7x3/MULTICOM_Human_CASP14/examples/T0951

fi


printf "\nFinished.."
printf "\nCheck log file </home/jh7x3/MULTICOM_Human_CASP14/test_out/T0951_multicom.log>\n\n"

