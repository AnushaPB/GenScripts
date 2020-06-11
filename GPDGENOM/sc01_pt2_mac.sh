#!/bin/bash                                         
#SBATCH -p day                                           
#SBATCH --mem=90g
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00                                      
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc01_pt2_mac.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc01_pt2_mac.sh.%J.err  
#SBATCH --mail-type=ALL                                  
#SBATCH --mail-user=anusha.bishop@yale.edu                                
#SBATCH --job-name=sc01_pt2_mac.sh    

#load appropriate modules 
module load StdEnv
module load PLINK/1.90-beta6.9
module load VCFtools

cd /home/fas/caccone/apb56/project/VCFFILTER

NAME=BCFtools_GxE_missing

vcftools --vcf ${NAME}.recode.vcf \
--max-alleles 2 --min-alleles 2 --mac 3 --recode --out ${NAME}_mac3

