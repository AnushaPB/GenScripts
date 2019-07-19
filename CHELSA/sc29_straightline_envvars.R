library("raster")
library("maptools")
library("spatstat")
library("foreach")
library("doParallel")

crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

#bioclim variables for uganda
envvars_seasonal <- stack("/home/fas/caccone/apb56/project/CHELSA/biovars/KenyaBiovarsSeasonalAllYears.tif")
envvars_biovars <- stack("/home/fas/caccone/apb56/project/CHELSA/biovars/UgandaKenyaBiovarsAllYears.tif")
envvars_seasonal <- setExtent(envvars_seasonal,extent(33.7,42.5,-4.8,5))
envvars_biovars <- setExtent(envvars_biovars,extent(33.7,42.5,-4.8,5))
envvars <- stack(envvars_seasonal,envvars_biovars)
names(envvars)<-c(paste0("BIO",c(8:11),"S"),paste0("BIO",c(16:19),"S"),paste0("BIO",c(1:19)))
proj4string(envvars)<-crs.geo

#use indices to give a unique integer value to each row
coords_gen<-read.csv("/home/fas/caccone/apb56/project/GPDHABITAT/connectivity_coords.csv")
coords_gen$ID <- seq.int(nrow(coords_gen))
data_index<-as.matrix(coords_gen$ID)

combos<-data.frame(t(combn(data_index,2))) 
colnames(combos)<-c("locality1","locality2")
combos

coords_locality1<-merge(combos[c("locality1")], gpd_data[c("ID","Long","Lat")], by.x = "locality1", by.y = "ID")
colnames(coords_locality1)<-c("ID","long1","lat1")

coords_locality2<-merge(combos[c("locality2")], gpd_data[c("ID","Long","Lat")], by.x = "locality2", by.y = "ID")
colnames(coords_locality2)<-c("ID","long2","lat2")

combos_coords<-cbind(coords_locality1[,2:3],coords_locality2[,2:3])
combos_coords<-coordinates(combos_coords)

#draw lines between points
p <- psp(combos_coords[,1],combos_coords[,2],combos_coords[,3],combos_coords[,4],owin(range(combos_coords[,1:2]),range(combos_coords[,3:4])))
spatial.p <- as(p, "SpatialLines")
proj4string(spatial.p) <- crs.geo 

#calculate mean of env vars along straight line
numCores <- detectCores()-1
registerDoParallel(numCores)  # use multicore, set to the number of our cores

StraightMean <- foreach(i=1:27, .combine=cbind) %:%
        foreach(n=1:length(spatial.p), .combine=rbind) %dopar% {
          raster::extract(envvars[[i]], spatial.p[n], fun=mean, na.rm=TRUE)
        }

stopImplicitCluster()

StraightMeanDF<-data.frame(StraightMean)
colnames(StraightMeanDF)<-names(envvars)
rownames(StraightMeanDF)<-as.character(c(1:length(spatial.p)))
StraightMeanDF<-cbind(combos_coords,StraightMeanDF)

write.csv(StraightMeanDF,file="/home/fas/caccone/apb56/project/GPDHABITAT/StraightMeanDF.csv")