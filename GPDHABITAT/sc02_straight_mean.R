library(spatstat)
library(raster)
library(maptools)
library(foreach)
library(doParallel)

#load envvars and spatial lines files
envvars<-stack("/home/fas/caccone/apb56/project/GPDHABITAT/envvars_kenya.tif")
combos_coords1<-read.csv("/home/fas/caccone/apb56/project/GPDHABITAT/coord_combos_cluster1.csv")
combos_coords1<-combos_coords1[,-1] #get rid of index row
combos_coords2<-read.csv("/home/fas/caccone/apb56/project/GPDHABITAT/coord_combos_cluster2.csv")
combos_coords2<-combos_coords2[,-1] #get rid of index row

#set CRS and coordinates
crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
coordinates(combos_coords1)
coordinates(combos_coords2)

#CLUSTER 1
#draw lines between points
p.cluster1 <- psp(combos_coords1[,1],combos_coords1[,2],combos_coords1[,3],combos_coords1[,4],owin(range(combos_coords1[,1:2]),range(combos_coords1[,3:4])))
spatial.p.cluster1  <- as(p.cluster1 , "SpatialLines")
proj4string(spatial.p.cluster1) <- crs.geo 

numCores <- detectCores()
registerDoParallel(numCores)  # use multicore, set to the number of our cores

StraightMean1 <- foreach(i=1:27, .combine=cbind) %:%
        foreach(n=1:length(spatial.p.cluster1), .combine=rbind) %dopar% {
          raster::extract(envvars[[i]], spatial.p.cluster1[n], fun=mean, na.rm=TRUE)
        }

stopImplicitCluster()

StraightMeanDF1<-data.frame(StraightMean1)
colnames(StraightMeanDF1)<-names(envvars)
rownames(StraightMeanDF1)<-as.character(c(1:length(spatial.p.cluster1)))
StraightMeanDF1<-cbind(combos_coords1,StraightMeanDF1)

write.csv(StraightMeanDF1,file="/home/fas/caccone/apb56/project/GPDHABITAT/StraightMeanDF1.csv")

#CLUSTER 2
#draw lines between points
p.cluster2 <- psp(combos_coords2[,1],combos_coords2[,2],combos_coords2[,3],combos_coords2[,4],owin(range(combos_coords2[,1:2]),range(combos_coords2[,3:4])))
spatial.p.cluster2  <- as(p.cluster2 , "SpatialLines")
proj4string(spatial.p.cluster2) <- crs.geo 

#calculate mean of env vars along straight line
numCores <- detectCores()-1
registerDoParallel(numCores)  

StraightMean2 <- foreach(i=1:27, .combine=cbind) %:%
        foreach(n=1:length(spatial.p.cluster2), .combine=rbind) %dopar% {
          raster::extract(envvars[[i]], spatial.p.cluster2[n], fun=mean, na.rm=TRUE)
        }

stopImplicitCluster()

StraightMeanDF2<-data.frame(StraightMean2)
colnames(StraightMeanDF2)<-names(envvars)
rownames(StraightMeanDF2)<-as.character(c(1:length(spatial.p.cluster2)))
StraightMeanDF2<-cbind(combos_coords2,StraightMeanDF2)

write.csv(StraightMeanDF2,file="/home/fas/caccone/apb56/project/GPDHABITAT/StraightMeanDF2.csv")

