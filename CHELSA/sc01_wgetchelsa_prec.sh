
module load Libs/GDAL/1.11.2

cd /home/fas/caccone/apb56/project/GFFHABITAT/RASTERS/CHELSA/prec

for x in 01 02 03 04 05 06 07 08 09 10 11 12 ;
do
    for y in 2008 2009 2010 2011 2012 2013 ;
    do
    wget https://www.wsl.ch/lud/chelsa/data/timeseries/prec/CHELSA_prec_${y}_${x}_V1.2.1.tif
    done
done
