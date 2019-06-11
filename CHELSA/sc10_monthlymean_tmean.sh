#!/bin/bash                                                                     
#SBATCH -p day                                                                  
##SBATCH -n 1 -c 1 -N 1                                                         
#SBATCH -t 24:00:00                                                             
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc10_monthlymean_tmean.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc10_monthlymean_tmean.sh.%A_%a.err
#SBATCH --mail-type=ALL             
#SBATCH --mail-user=email                                                       
#SBATCH --job-name=sc10_tmean_mean.sh                                              

module load Libs/GDAL/1.11.2

INDIR=/home/fas/caccone/apb56/project/CHELSA/tmean
OUTDIR=/home/fas/caccone/apb56/project/CHELSA/tmean_mean

for x in 01 02 03 04 05 06 07 08 09 10 11 12 ; do

echo Create a multiband vrt
gdalbuildvrt -overwrite -separate $OUTDIR/CHELSA_tmean_${x}_V1.2.1.vrt $INDIR/CHELSA_tmean_*_${x}_V1.2.1.tif

echo Calculate mean for month $x

pkstatprofile -co  COMPRESS=LZW -nodata 0 -f mean -i $OUTDIR/CHELSA_tmean_${x}_V\
1.2.1.vrt -o  $OUTDIR/CHELSA_tmean_${x}_V1.2.1.tif

#rm -f $OUTDIR/CHELSA_tmean_${x}_V1.2.1.vrt

done
