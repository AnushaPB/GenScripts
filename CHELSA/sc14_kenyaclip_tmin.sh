#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc14_edit_tmin.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc14_edit_tmin.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc14_tmin.sh  

ulimit -c 0

cd /project/fas/caccone/apb56/CHELSA/tmin_mean

OUTDIR=/project/fas/caccone/apb56/CHELSA/tmin_mean/kenya_clips

for n in 01 02 03 04 05 06 07 08 09 10 11 12; do

#gdal_edit.py -a_ullr -180   84  180  -90   CHELSA_tmin_${n}_V1.2.1.tif 

pksetmask -i CHELSA_tmin_${n}_V1.2.1.tif -m CHELSA_tmin_${n}_V1.2.1.tif -o $OUTDIR/CHELSA_tmin_${n}_V1.2.1_Edit.tif --msknodata 65535 -nodata -999

gdal_edit.py -a_nodata -999 $OUTDIR/CHELSA_tmin_${n}_V1.2.1_Edit.tif    

gdal_translate -projwin 33.7 4.73 42.5 -4.8 $OUTDIR/CHELSA_tmin_${n}_V1.2.1_Edit.tif $OUTDIR/CHELSA_tmin_${n}_V1.2.1_KenyaClip.tif

rm $OUTDIR/CHELSA_tmin_${n}_V1.2.1_Edit.tif

done
