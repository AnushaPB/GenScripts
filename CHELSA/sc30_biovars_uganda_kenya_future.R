library(rgdal)
library(raster)
library(sp)
library(dismo)

ext<-extent(28.6,42.5,-4.8,5)
crs.geo<-CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

prec_uganda_kenya<-raster::stack(paste0("/home/fas/caccone/apb56/project/CHELSA/future/prec/uganda_kenya_clips/CHELSA_prec_",c("1","2","3","4","5","6","7","8","9","10","11","12"),"_rcp45_2041-2060_UgandaKenyaClip.tif"))
proj4string(prec_uganda_kenya)<-crs.geo
prec_uganda_kenya<-setExtent(prec_uganda_kenya,ext)

tmax_uganda_kenya<-raster::stack(paste0("/home/fas/caccone/apb56/project/CHELSA/future/tmax/uganda_kenya_clips/CHELSA_tmax_",c("1","2","3","4","5","6","7","8","9","10","11","12"),"_rcp45_2041-2060_UgandaKenyaClip.tif"))
proj4string(tmax_uganda_kenya)<-crs.geo
tmax_uganda_kenya<-setExtent(tmax_uganda_kenya,ext)

tmin_uganda_kenya<-raster::stack(paste0("/home/fas/caccone/apb56/project/CHELSA/future/tmin/uganda_kenya_clips/CHELSA_tmin_",c("1","2","3","4","5","6","7","8","9","10","11","12"),"_rcp45_2041-2060_UgandaKenyaClip.tif"))
proj4string(tmin_uganda_kenya)<-crs.geo
tmin_uganda_kenya<-setExtent(tmin_uganda_kenya,ext)

biovar_uganda_kenya.future <- biovars(prec_uganda_kenya,tmin_uganda_kenya,tmax_uganda_kenya)
#repetitive definition of projection, but added in case (this line is sufficent for the output to be in the desired CRS)
proj4string(biovar_uganda_kenya.future)<-crs.geo

writeRaster(biovar_uganda_kenya.future,"/home/fas/caccone/apb56/project/CHELSA/biovars/UgandaKenyaBiovarsFuture",format="GTiff")