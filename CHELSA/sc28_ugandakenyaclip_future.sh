#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc28_ugandakenyaclip_future.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc28_ugandakenyaclip_future.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc28_ugandakenyaclip_future.sh

ulimit -c 0

cd /home/fas/caccone/apb56/project/CHELSA/future/prec

OUTDIR=/home/fas/caccone/apb56/project/CHELSA/future/prec/uganda_kenya_clips

for n in 1 2 3 4 5 6 7 8 9 10 11 12; do

pksetmask -i CHELSA_pr_mon_GISS-E2-R_rcp45_r1i1p1_g025.nc_${n}_2041-2060.tif -m CHELSA_pr_mon_GISS-E2-R_rcp45_r1i1p1_g025.nc_${n}_2041-2060.tif -o $OUTDIR/CHELSA_prec_${n}_rcp45_2041-2060_Edit.tif --msknodata -32767 -nodata -999

gdal_edit.py -a_nodata -999 $OUTDIR/CHELSA_prec_${n}_rcp45_2041-2060_Edit.tif    

gdal_translate -projwin 28.6 5 42.5 -4.8 $OUTDIR/CHELSA_prec_${n}_rcp45_2041-2060_Edit.tif $OUTDIR/CHELSA_prec_${n}_rcp45_2041-2060_UgandaKenyaClip.tif

rm $OUTDIR/CHELSA_prec_${n}_rcp45_2041-2060_Edit.tif

done



cd /home/fas/caccone/apb56/project/CHELSA/future/tmax

OUTDIR=/home/fas/caccone/apb56/project/CHELSA/future/tmax/uganda_kenya_clips

for n in 1 2 3 4 5 6 7 8 9 10 11 12; do

pksetmask -i CHELSA_tasmax_mon_GISS-E2-R_rcp26_r1i1p1_g025.nc_${n}_2041-2060_V1.2.tif -m CHELSA_tasmax_mon_GISS-E2-R_rcp26_r1i1p1_g025.nc_${n}_2041-2060_V1.2.tif -o $OUTDIR/CHELSA_tmax_${n}_rcp45_2041-2060_Edit.tif --msknodata -32767 -nodata -999

gdal_edit.py -a_nodata -999 $OUTDIR/CHELSA_tmax_${n}_rcp45_2041-2060_Edit.tif

gdal_translate -projwin 28.6 5 42.5 -4.8 $OUTDIR/CHELSA_tmax_${n}_rcp45_2041-2060_Edit.tif $OUTDIR/CHELSA_tmax_${n}_rcp45_2041-2060_UgandaKenyaClip.tif

rm $OUTDIR/CHELSA_tmax_${n}_rcp45_2041-2060_Edit.tif

done



cd /home/fas/caccone/apb56/project/CHELSA/future/tmin

OUTDIR=/home/fas/caccone/apb56/project/CHELSA/future/tmin/uganda_kenya_clips

for n in 1 2 3 4 5 6 7 8 9 10 11 12; do

pksetmask -i CHELSA_tasmin_mon_GISS-E2-R_rcp26_r1i1p1_g025.nc_${n}_2041-2060_V1.2.tif -m CHELSA_tasmin_mon_GISS-E2-R_rcp26_r1i1p1_g025.nc_${n}_2041-2060_V1.2.tif -o $OUTDIR/CHELSA_tmin_${n}_rcp45_2041-2060_Edit.tif --msknodata -32767 -nodata -999

gdal_edit.py -a_nodata -999 $OUTDIR/CHELSA_tmin_${n}_rcp45_2041-2060_Edit.tif

gdal_translate -projwin 28.6 5 42.5 -4.8 $OUTDIR/CHELSA_tmin_${n}_rcp45_2041-2060_Edit.tif $OUTDIR/CHELSA_tmin_${n}_rcp45_2041-2060_UgandaKenyaClip.tif

rm $OUTDIR/CHELSA_tmin_${n}_rcp45_2041-2060_Edit.tif

done



cd /home/fas/caccone/apb56/project/CHELSA/future/tmean

OUTDIR=/home/fas/caccone/apb56/project/CHELSA/future/tmean/uganda_kenya_clips

for n in 1 2 3 4 5 6 7 8 9 10 11 12; do

pksetmask -i CHELSA_tas_mon_GISS-E2-R_rcp45_r1i1p1_g025.nc_${n}_2041-2060_V1.2.tif -m CHELSA_tas_mon_GISS-E2-R_rcp45_r1i1p1_g025.nc_${n}_2041-2060_V1.2.tif -o $OUTDIR/CHELSA_tmean_${n}_rcp45_2041-2060_Edit.tif --msknodata -32767 -nodata -999

gdal_edit.py -a_nodata -999 $OUTDIR/CHELSA_tmean_${n}_rcp45_2041-2060_Edit.tif

gdal_translate -projwin 28.6 5 42.5 -4.8 $OUTDIR/CHELSA_tmean_${n}_rcp45_2041-2060_Edit.tif $OUTDIR/CHELSA_tmean_${n}_rcp45_2041-2060_UgandaKenyaClip.tif

rm $OUTDIR/CHELSA_tmean_${n}_rcp45_2041-2060_Edit.tif

done
