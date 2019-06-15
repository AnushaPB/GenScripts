#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc02_edit_alt.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc02_edit_alt.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc02_edit_alt.sh 

cd /home/fas/caccone/apb56/project/MERIT/altitude

OUTDIR=/home/fas/caccone/apb56/project/MERIT/altitude/kenya_clips

gdal_edit.py -a_ullr -180   84  180  -90 altitude_1KMmedian_MERIT.tif

gdal_edit.py -a_nodata -999 altitude_1KMmedian_MERIT.tif

pksetmask -i altitude_1KMmedian_MERIT.tif -m altitude_1KMmedian_MERIT.tif -o altitude_1KMmedian_MERIT.tif --msknodata -9999 -nodata -999   
 
gdal_translate  -projwin 33.7 4.73 42.5 -4.8  altitude_1KMmedian_MERIT.tif  $OUTDIR/altitude_1KMmedian_MERIT_KenyaClip.tif
