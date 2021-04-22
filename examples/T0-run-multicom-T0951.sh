#!/bin/bash
#SBATCH -J  T0951
#SBATCH -o T0951-%j.out
#SBATCH --partition Lewis,hpc5,hpc4
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=2G
#SBATCH --time 2-00:00

mkdir -p /home/jianliu/MULTICOM_Human_CASP14/test_out/T0951_multicom/
cd /home/jianliu/MULTICOM_Human_CASP14/test_out/T0951_multicom/

if [[ ! -f "/home/jianliu/MULTICOM_Human_CASP14/test_out/T0951_multicom/mcomb/casp1.pdb" ]];then 
	perl /home/jianliu/MULTICOM_Human_CASP14/bin/run_multicom_Human.sh T0951 /home/jianliu/MULTICOM_Human_CASP14/examples/T0951.fasta /home/jianliu/MULTICOM_Human_CASP14/test_out/T0951_multicom/ /home/jianliu/MULTICOM_Human_CASP14/examples/T0951

fi


printf "\nFinished.."
printf "\nCheck log file </home/jianliu/MULTICOM_Human_CASP14/test_out/T0951_multicom.log>\n\n"
