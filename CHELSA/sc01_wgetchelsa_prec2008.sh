MAKE FILE: 
cd /home/fas/caccone/apb56/project/GFFHABITAT/RASTERS/CHELSA/prec

for n in 01 02 03 04 05 06 07 08 09 10 11 12 ; do
wget https://www.wsl.ch/lud/chelsa/data/timeseries/prec/CHELSA_prec_2008_${n}_V1.2.1.tif
done