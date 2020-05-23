#Import foldnum for LOPOCV
foldnum<-Sys.getenv(c('foldnum'))
print(foldnum)


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

#need to download test

Test.table <- read.table(file=paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/testData_", foldnum, ".csv"), sep=",", header=T)
Test.table <- Test.table[Test.table$Var1 != "24_SHT" & Test.table$Var2 != "24_SHT",]
##FOR TESTING SCRIPT:
#Test.table <- Test.table[1:5,]

Train.table <- read.table(file=paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/trainData_", foldnum, ".csv"), sep=",", header=T)
Train.table <- Train.table[Train.table$Var1 != "24_SHT" & Train.table$Var2 != "24_SHT",]
##FOR TESTING SCRIPT:
#Train.table <- Train.table[1:5,]

#For train data
#create dataframes of begin and end coordinates from a file:
begin.table <- Train.table[,c("long1","lat1")]
begin.coord <- begin.table
coordinates(begin.coord) <- c("long1", "lat1")

end.table <- Train.table[,c("long2","lat2")]
end.coord <- end.table
coordinates(end.coord) <- c("long2", "lat2")

p <- psp(begin.table[,1], begin.table[,2], end.table[,1], end.table[,2], owin(range(c(begin.table[,1], end.table[,1])), range(c(begin.table[,2], end.table[,2]))))

spatial.p.train <- as(p, "SpatialLines")
proj4string(spatial.p.train) <- crs.geo  # define projection system of our data

#For test data
begin.table <- Test.table[,c("long1","lat1")]
begin.coord <- begin.table
coordinates(begin.coord) <- c("long1", "lat1")

end.table <- Test.table[,c("long2","lat2")]
end.coord <- end.table
coordinates(end.coord) <- c("long2", "lat2")

p <- psp(begin.table[,1], begin.table[,2], end.table[,1], end.table[,2], owin(range(c(begin.table[,1], end.table[,1])), range(c(begin.table[,2], end.table[,2]))))

spatial.p.test <- as(p, "SpatialLines")
proj4string(spatial.p.test) <- crs.geo  # define projection system of our data


########################################
#Calculate median of straight lines and making initial RF model
#######################################
#For training
envvals <- raster::extract(env, spatial.p.train, fun=median, na.rm=TRUE)
pixvals <- raster::extract(pixels_raster, spatial.p.train, fun=sum, na.rm=TRUE)
StraightMedian.train <- cbind(envvals,pixvals)

StraightMedianDF.train <- as.data.frame(StraightMedian.train)

StraightMedianDF.train$Distance <- Train.table$Distance

#For testing
envvals <- raster::extract(env, spatial.p.test, fun=median, na.rm=TRUE)
pixvals <- raster::extract(pixels_raster, spatial.p.test, fun=sum, na.rm=TRUE)
StraightMedian.test <- cbind(envvals,pixvals)

StraightMedianDF.test <- as.data.frame(StraightMedian.test)

StraightMedianDF.test$Distance <- Test.table$Distance

set.seed(NULL)

#check these
tune_x <- StraightMedianDF.train[,c(names(env),"pixvals")]
tune_y <- StraightMedianDF.train[,c("Distance")]
bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]

Straight_RF = randomForest(Distance ~ ., importance=TRUE, mtry = mtry_opt, na.action=na.omit, data=StraightMedianDF.train)

gc()

StraightPred <- predict(envPlus, Straight_RF)

writeRaster(StraightPred, paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/MEDIAN/SHT/StraightPaths_EBKM_Point",foldnum,".RData"), format="GTiff", overwrite=TRUE)

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/MEDIAN/SHT/EdwardsBouyerKernelMed_SHTremoved_Point",foldnum,".RData"))

#Validation parameters
RSQ = tail(Straight_RF$rsq ,1 )
RMSE = sqrt(tail(Straight_RF$mse ,1 ))
RMSE2 = sqrt(mean((predict(Straight_RF, StraightMedianDF.test) - StraightMedianDF.test$Distance)^2))
MAE = mean(abs(Straight_RF$predicted - StraightMedianDF.train$Distance))
MAE2 =  mean(abs(predict(Straight_RF, StraightMedianDF.train) - StraightMedianDF.train$Distance))
MAE3 = mean(abs(predict(Straight_RF, StraightMedianDF.test) - StraightMedianDF.test$Distance))
Cor1 = cor(predict(Straight_RF, StraightMedianDF.train), StraightMedianDF.train$Distance)
Cor2 = cor(predict(Straight_RF, StraightMedianDF.test), StraightMedianDF.test$Distance)
 
print(RSQ)
print(RMSE2)

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/MEDIAN/SHT/EdwardsBouyerKernelMed_SHTremoved_Point",foldnum,".RData"))

