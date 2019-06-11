#!/bin/bash                                                                    
#SBATCH -p day                                                                 
##SBATCH -n 1 -c 1 -N 1                                                        
#SBATCH -t 24:00:00                           
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc04_rerunCHELSA_prec.sh.%A_%a.out                   
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc04_rerunCHELSA_prec.sh.%A_%a.err                        
#SBATCH --mail-type=ALL
#SBATCH --mail-user=anusha.bishop@yale.edu
#SBATCH --job-name=sc04_bioclim.sh

module load Libs/GDAL/1.11.2

INDIR=/home/fas/caccone/apb56/project/CHELSA/prec
OUTDIR=/home/fas/caccone/apb56/project/CHELSA/prec_mean

echo Create a multiband vrt
gdalbuildvrt -overwrite -separate $OUTDIR/CHELSA_prec_01_V1.2.1.vrt $INDIR/CHELSA_prec_*_01_V1.2.1.tif

echo Calculate mean for month 01

pkstatprofile -co  COMPRESS=LZW -nodata 0 -f mean -i $OUTDIR/CHELSA_prec_01_V1.2.1.vrt -o  $OUTDIR/CHELSA_prec_01_V1.2.1.tif

#rm -f $OUTDIR/CHELSA_prec_01_V1.2.1.vrt                                      
done
