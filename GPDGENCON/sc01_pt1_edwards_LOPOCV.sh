#!/bin/bash                                                                                                                                                      
#SBATCH -p day                                                                                                                                                   
#SBATCH -n 1 -c 1  -N 1                                                                                                                                          
#SBATCH --mem-per-cpu=50000                                                                                                                                      
#SBATCH -t 10:00:00                                                                                                                                              
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc01_pt1_edwards_LOPOCV.sh.%J.out                                                                          
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc01_pt1_edwards_LOPOCV.sh.%J.err                                                                          
#SBATCH --mail-type=ALL                                                                                                                                          
#SBATCH --mail-user=anusha.bishop@yale.edu                                                                                                                       
#SBATCH --job-name=sc01_pt1_edwards_LOPOCV.sh                                                                                                                  

# sbatch /home/fas/caccone/apb56/scripts/GPDGENCON/sc01_pt1_edwards_LOPOCV.sh ; done                                                                           

ulimit -c 0

module load StdEnv

module load R/3.4.4-foss-2018a-X11-20180131

module load GDAL/2.2.3-foss-2018a-Python-2.7.14

# --slave      use if you only want to see output                                                                                                                

R --vanilla --no-readline -q  -f /home/fas/caccone/apb56/scripts/GPDGENCON/sc01_pt1_edwards_LOPOCV.R
