#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc02_straight_mean.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc02_straight_mean.sh.%J.err                       
#SBATCH --mail-type=ALL                                                         
#SBATCH --mail-user=anusha.bishop@yale.edu  
#SBATCH --job-name=sc02_straight_mean

#Cd to home directory 
cd ~

#have to unload python to load miniconda
module unload Langs/Python
# Loading conda env
module load Tools/miniconda

# Load R 
module load Apps/R/3.5.1-generic
module load Rpkgs/RGDAL/1.2-5
module load Rpkgs/RASTER/2.5.2

# Activate env_name
source activate r_env

R --vanilla -no-readline -q  -f  /home/fas/caccone/apb56/scripts/GPDHABITAT/sc02_straight_mean.R
