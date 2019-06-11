#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc07_wget_tmean.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc07_wget_tmean.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu                                                      
#SBATCH --job-name=sc07_tmean.sh  

module load Libs/GDAL/1.11.2

cd /home/fas/caccone/apb56/project/CHELSA/tmean

for x in 01 02 03 04 05 06 07 08 09 10 11 12 ;
do
    for y in 2008 2009 2010 2011 2012 2013 ;
    do
    wget https://www.wsl.ch/lud/chelsa/data/timeseries/tmean/CHELSA_tmean_${y}_${x}_V1.2.1.tif
gdal_edit.py -a_ullr -180 84 180 -90 CHELSA_tmean_${y}_${x}_V1.2.1.tif
    done
done
