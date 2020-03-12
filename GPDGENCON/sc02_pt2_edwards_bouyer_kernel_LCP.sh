#!/bin/bash                                         
#SBATCH -p bigmem                                           
#SBATCH --mem=500g
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00                                      
#SBATCH -o /gpfs/scratch60/fas/caccone/apb56/stdout/sc02_pt2_edwards_bouyer_kernel_LCP.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/caccone/apb56/stderr/sc02_pt2_edwards_bouyer_kernel_LCP.sh.%J.err  
#SBATCH --mail-type=ALL                                  
#SBATCH --mail-user=anusha.bishop@yale.edu                                
#SBATCH --job-name=sc02_pt2_edwards_bouyer_kernel_LCP.sh                   

####  for foldnum in 1 2 3 4 5 6 7 8 9 10; do sbatch --export=foldnum=$foldnum /home/fas/caccone/apb56/scripts/GPDGENCON/sc02_pt2_edwards_bouyer_kernel_LCP.sh  ; done    

#for testing script
####  for foldnum in 1; do sbatch --export=foldnum=$foldnum /home/fas/caccone/apb56/scripts/GPDGENCON/sc02_pt2_edwards_bouyer_kernel_LCP.sh  ; done 

ulimit -c 0

module load StdEnv

module load R/3.5.3-foss-2018a-X11-20180131

module load GDAL/2.2.3-foss-2018a-Python-2.7.14

# --slave      use if you only want to see output

export foldnum=$foldnum

#run script with just envvars
R --vanilla --no-readline -q  -f /home/fas/caccone/apb56/scripts/GPDGENCON/sc02_pt2_edwards_bouyer_kernel_LCP.R
