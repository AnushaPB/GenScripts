library(rgdal)
library(raster)
library(sp)
library(dismo)

#make sure to cd~ before running, if done interactively. Sh submission script has this included. 

prec_uganda_kenya<-raster::stack(paste0("/home/fas/caccone/apb56/project/CHELSA/prec/uganda_kenya_clips/CHELSA_prec_2013_",c("01","02","03","04","05","06","07","08","09","10","11","12"),"_V1.2.1_UgandaKenyaClip.tif"))
prec_uganda_kenya<-setExtent(prec_uganda_kenya,extent(28.6,42.5,-4.8,5))#fix extent of files permanently later

proj4string(prec_uganda_kenya)<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

tmax_uganda_kenya<-raster::stack(paste0("/home/fas/caccone/apb56/project/CHELSA/tmax/uganda_kenya_clips/CHELSA_tmax_2013_",c("01","02","03","04","05","06","07","08","09","10","11","12"),"_V1.2.1_UgandaKenyaClip.tif"))
proj4string(tmax_uganda_kenya)<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

tmin_uganda_kenya<-raster::stack(paste0("/home/fas/caccone/apb56/project/CHELSA/tmin/uganda_kenya_clips/CHELSA_tmin_2013_",c("01","02","03","04","05","06","07","08","09","10","11","12"),"_V1.2.1_UgandaKenyaClip.tif"))
proj4string(tmin_uganda_kenya)<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

biovar_uganda_kenya_2013 <- biovars(prec_uganda_kenya,tmin_uganda_kenya,tmax_uganda_kenya)
#repetitive definition of projection, but added in case (this line is sufficent for the output to be in the desired CRS)
proj4string(biovar_uganda_kenya_2013)<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
writeRaster(biovar_uganda_kenya_2013,"/home/fas/caccone/apb56/project/CHELSA/biovars/UgandaKenyaBiovars2013",format="GTiff")
