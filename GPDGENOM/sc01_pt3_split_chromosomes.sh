#!/bin/bash                                         
#SBATCH -p bigmem                                                                                                                         
#SBATCH --mem=500g   
#SBATCH -t 24:00:00                                      
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc01_pt3_split_chromosomes.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc01_pt3_split_chromosomes.sh.%J.err  
#SBATCH --mail-type=ALL                                  
#SBATCH --mail-user=anusha.bishop@yale.edu                                
#SBATCH --job-name=sc01_pt3_split_chromosomes.sh    

#load appropriate modules 
module load StdEnv
module load PLINK/1.90-beta6.9
module load VCFtools

cd /home/fas/caccone/apb56/project/VCF
OUTDIR=/home/fas/caccone/apb56/project/VCFFILTER
#make the bed files that map scaffold to autosome/X/other
cat meA.bed meD.bed meF.bed > $OUTDIR/X.bed
cat meB.bed meC.bed meE.bed > $OUTDIR/autosomes.bed
cat meA.bed meB.bed meC.bed meD.bed meE.bed meF.bed > $OUTDIR/all_mes.bed

cd /home/fas/caccone/apb56/project/VCFFILTER
NAME=BCFtools_GxE_missing_mac3
vcftools --vcf ${NAME}.recode.vcf --bed autosomes.bed --recode --out ${NAME}_autosomes
vcftools --vcf ${NAME}.recode.vcf --bed X.bed --recode --out ${NAME}_X
vcftools --vcf ${NAME}.recode.vcf --exclude-bed all_mes.bed --recode --out ${NAME}_other
