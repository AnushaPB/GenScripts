#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc18_wget_future.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc06_wget_future.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc18_future.sh  

module load Libs/GDAL/1.11.2

cd /home/fas/caccone/apb56/project/CHELSA/future/prec

for x in 1 2 3 4 5 6 7 8 9 10 11 12 ;
do
wget https://www.wsl.ch/lud/chelsa/data/cmip5/2041-2060/prec/CHELSA_pr_mon_GISS-E2-H-CC_rcp45_r1i1p1_g025.nc_${x}_2041-2060.tif
gdal_edit.py -a_ullr -180 84 180 -90 CHELSA_tmax_${y}_${x}_V1.2.1.tif
done

cd /home/fas/caccone/apb56/project/CHELSA/future/tmax

for x in 1 2 3 4 5 6 7 8 9 10 11 12 ;
do
wget https://www.wsl.ch/lud/chelsa/data/cmip5/2041-2060/tmax/CHELSA_pr_mon_GISS-E2-H-CC_rcp45_r1i1p1_g025.nc_${x}_2041-2060.tif
gdal_edit.py -a_ullr -180 84 180 -90 CHELSA_tmax_${y}_${x}_V1.2.1.tif
done

cd /home/fas/caccone/apb56/project/CHELSA/future/tmin

for x in 1 2 3 4 5 6 7 8 9 10 11 12 ;
do
wget https://www.wsl.ch/lud/chelsa/data/cmip5/2041-2060/tmax/CHELSA_pr_mon_GISS-E2-H-CC_rcp45_r1i1p1_g025.nc_${x}_2041-2060.tif
gdal_edit.py -a_ullr -180 84 180 -90 CHELSA_tmax_${y}_${x}_V1.2.1.tif
done

cd /home/fas/caccone/apb56/project/CHELSA/future/tmean

for x in 1 2 3 4 5 6 7 8 9 10 11 12 ;
do
wget https://www.wsl.ch/lud/chelsa/data/cmip5/2041-2060/tmax/CHELSA_pr_mon_GISS-E2-H-CC_rcp45_r1i1p1_g025.nc_${x}_2041-2060.tif
gdal_edit.py -a_ullr -180 84 180 -90 CHELSA_tmax_${y}_${x}_V1.2.1.tif
done
