#Import packages
library("sp")
library("spatstat")
library("maptools")
library("raster")
library("randomForest")
library("gdistance")
#library("SDraw")
#library("tidyverse")
library("foreach")
library("doParallel")
library("doMC")

load("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/RF_pt1.RData")

crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") # ... add coordinate system

rmr=function(x){
  ## function to truly delete raster and temporary files associated with them
  if(class(x)=="RasterLayer"&grepl("^/tmp",x@file@name)&fromDisk(x)==T){
    file.remove(x@file@name,sub("grd","gri",x@file@name))
    rm(x)
  }
}

#load envvars
envvars <- stack("/home/fas/caccone/apb56/project/GPDHABITAT/chelsa_merit_vars_kenya.tif")
names(envvars)<-c(paste0("BIO",c(8:11),"S"),paste0("BIO",c(16:19),"S"),paste0("BIO",c(1:19)),"slope","altitude")
#remove quarters (retain only seasonal variables)
envvars <- dropLayer(envvars, c(paste0("BIO",c(8:11)),paste0("BIO",c(16:19))))

#load river density layer
rivers <- raster("/home/fas/caccone/apb56/project/GPDGENCON/KenTz_rivers_kernel_2km_2020-03-18.tif")
names(rivers) <- "rivers"

#load kernel density layer
kernel <- raster("/home/fas/caccone/apb56/project/GPDGENCON/KenTz_kernel_50m_2020-03-10_final.tif")
names(kernel) <- "kernel"

#stack predictor vars
env <- stack(envvars, rivers, kernel)

###############################################
#Create pixel of 1s for Buoyer methods
###############################################
pixels_raster <- env[[1]]
pixels_raster[,] <- 1
names(pixels_raster) <- "pixvals"

#create for projection
envPlus <- addLayer(env,pixels_raster)
names(envPlus) <- c(names(env),"pixvals") 

###############################################
#Plot lines as SpatialLines:
###############################################
#Plot straight lines for first iteration of RF
G.table <- read.table(file="/home/fas/caccone/apb56/project/GPDGENCON/ken_edwards_gendf.csv", sep=",", header=T)

#Plot straight lines for first iteration of RF
begin.table <- G.table[,c("long1","lat1")]
begin.coord <- begin.table
coordinates(begin.coord) <- c("long1", "lat1")

end.table <- G.table[,c("long2","lat2")]
end.coord <- end.table
coordinates(end.coord) <- c("long2", "lat2")

p <- psp(begin.table[,1], begin.table[,2], end.table[,1], end.table[,2], owin(range(c(begin.table[,1], end.table[,1])), range(c(begin.table[,2], end.table[,2]))))

spatial.p <- as(p, "SpatialLines")
proj4string(spatial.p) <- crs.geo  # define projection system of our data


########################################
#Calculate mean of straight lines 
#######################################
envvals <- raster::extract(env, spatial.p, fun=mean, na.rm=TRUE)
pixvals <- raster::extract(pixels_raster, spatial.p, fun=sum, na.rm=TRUE)

StraightMean <- cbind(envvals,pixvals)

StraightMeanDF <- as.data.frame(StraightMean)

StraightMeanDF$Distance <- G.table$Distance

###############################################
#Model with all data
###############################################
#check these
tune_x <- StraightMeanDF[,c(names(env),"pixvals")]
tune_y <- StraightMeanDF[,c("Distance")]
bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]

Straight_RF = randomForest(Distance ~ ., importance=TRUE, mtry = mtry_opt, na.action=na.omit, data=StraightMeanDF)

#Validation parameters
RSQ = tail(Straight_RF$rsq ,1 )
RMSE = sqrt(tail(Straight_RF$mse ,1 ))
RMSE2 = sqrt(mean((predict(Straight_RF, StraightMeanDF) - StraightMeanDF$Distance)^2))
MAE2 =  mean(abs(predict(Straight_RF, StraightMeanDF) - StraightMeanDF$Distance))

StraightPred <- predict(envPlus, Straight_RF)

pred.cond <- 1/StraightPred #build conductance surface

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/MEDIAN/EdwardsBouyerKernelMed_AllData.RData"))

