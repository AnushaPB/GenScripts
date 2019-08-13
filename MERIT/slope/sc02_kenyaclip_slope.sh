#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc02_edit_slope.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc02_edit_slope.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc02_edit_slope.sh 

cd /home/fas/caccone/apb56/project/MERIT/slope

OUTDIR=/home/fas/caccone/apb56/project/MERIT/slope/kenya_clips

gdal_edit.py -a_ullr -180   84  180  -90 slope_1KMmedian_MERIT.tif

#pksetmask -i slope_1KMmedian_MERIT.tif -m slope_1KMmedian_MERIT.tif -o slope_1KMmedian_MERIT.tif --msknodata -999 -nodata -999

#gdal_edit.py -a_nodata -999 slope_1KMmedian_MERIT.tif

gdal_translate  -projwin 33.7 5 42.5 -4.8  slope_1KMmedian_MERIT.tif  $OUTDIR/slope_1KMmedian_MERIT_KenyaClip.tif
