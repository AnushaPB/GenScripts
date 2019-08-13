#!/bin/bash
#SBATCH -p day
##SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc30_biovars_uganda_kenya_future.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc30_biovars_uganda_kenya_future.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu  
#SBATCH --job-name=sc30_biovars_uganda_kenya_future

#Cd to home directory 
cd ~

#have to unload python to load miniconda
module unload Langs/Python
# Loading conda env
module load Tools/miniconda

# Load R 
module load Apps/R/3.3.2-generic
module load Rpkgs/RGDAL/1.2-5
module load Rpkgs/RASTER/2.5.2

# Activate env_name
source activate r_env

R --vanilla -no-readline -q  -f  /home/fas/caccone/apb56/scripts/CHELSA/sc30_biovars_uganda_kenya_future.R
