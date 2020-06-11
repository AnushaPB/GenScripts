#!/bin/bash                                         
#SBATCH -p day                                           
#SBATCH --mem=90g
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00                                      
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc01_pt1_geno_mind.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderrsc01_pt1_geno_mind.sh.%J.err  
#SBATCH --mail-type=ALL                                  
#SBATCH --mail-user=anusha.bishop@yale.edu                                
#SBATCH --job-name=sc01_pt1_geno_mind.sh    

#load appropriate modules 
module load StdEnv
module load PLINK/1.90-beta6.9
module load VCFtools

#PLINK to convert VCF to PLINK:
NAME=BCFtools_GxE
OUTDIR=/home/fas/caccone/apb56/project/VCFFILTER
cd /home/fas/caccone/apb56/project/VCF
plink --vcf $NAME.recode.vcf --double-id --allow-extra-chr --make-bed --out $OUTDIR/$NAME
cd $OUTDIR
plink --bfile $NAME --double-id --allow-extra-chr --recode tab --out $NAME

#PLINK to filter by missing data:
cp /dev/null $NAME.missing.log
plink --file $NAME --geno .7 --double-id --allow-extra-chr --recode --out ${NAME}_geno70           >> $NAME.missing.log
plink --file ${NAME}_geno70 --mind .7 --double-id --allow-extra-chr --recode --out ${NAME}_mind70    >> $NAME.missing.log
plink --file ${NAME}_mind70 --geno .65 --double-id --allow-extra-chr --recode --out ${NAME}_geno65    >> $NAME.missing.log
plink --file ${NAME}_geno65 --mind .65 --double-id --allow-extra-chr --recode --out ${NAME}_mind65    >> $NAME.missing.log
plink --file ${NAME}_mind65 --geno .6 --double-id --allow-extra-chr --recode --out ${NAME}_geno60    >> $NAME.missing.log
plink --file ${NAME}_geno60 --mind .6 --double-id --allow-extra-chr --recode --out ${NAME}_mind60    >> $NAME.missing.log
plink --file ${NAME}_mind60 --geno .55 --double-id --allow-extra-chr --recode --out ${NAME}_geno55    >> $NAME.missing.log
plink --file ${NAME}_geno55 --mind .55 --double-id --allow-extra-chr --recode --out ${NAME}_mind55    >> $NAME.missing.log
plink --file ${NAME}_mind55 --geno .5 --double-id --allow-extra-chr --recode --out ${NAME}_geno50    >> $NAME.missing.log
plink --file ${NAME}_geno50 --mind .5 --double-id --allow-extra-chr --recode --out ${NAME}_mind50    >> $NAME.missing.log
cat $NAME.missing.log | grep "QC."

#Extract sites from missing filters for 0.50 filter:
cat ${NAME}_mind50.map | awk '{print $1 "\t" $4}' > ${NAME}_mind50.pos
NAME=BCFtools_GxE
vcftools --vcf /home/fas/caccone/apb56/project/VCF/${NAME}.recode.vcf \
--positions $OUTDIR/${NAME}_mind50.pos \
--recode --out $OUTDIR/${NAME}_missing
