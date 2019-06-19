#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc25_ugandakenya_clip 

cd /home/fas/caccone/apb56/project/CHELSA/tmean
OUTDIR=/home/fas/caccone/apb56/project/CHELSA/tmean/uganda_kenya_clips

for x in 01 02 03 04 05 06 07 08 09 10 11 12 ;
do
    for y in 2008 2009 2010 2011 2012 2013 ;
    do
    gdal_edit.py -a_ullr -180   84  180  -90   CHELSA_prec_${n}_V1.2.1.tif
    
    pksetmask -i CHELSA_tmean_${y}_${x}_V1.2.1.tif -m CHELSA_tmean_${y}_${x}_V1.2.1.tif -o $OUTDIR/CHELSA_tmean_${y}_${x}_V1.2.1_Edit.tif --msknodata 65535 -nodata -999   
    
    gdal_edit.py -a_nodata -999 $OUTDIR/CHELSA_tmean_${y}_${x}_V1.2.1_Edit.tif 
    
    gdal_translate  -projwin 28.6 5 42.5 -4.8  $OUTDIR/CHELSA_tmean_${y}_${x}_V1.2.1_Edit.tif     $OUTDIR/CHELSA_tmean_${y}_${x}_V1.2.1_UgandaKenyaClip.tif
    
    rm $OUTDIR/CHELSA_tmean_${y}_${x}_V1.2.1_Edit.tif
    done
done
