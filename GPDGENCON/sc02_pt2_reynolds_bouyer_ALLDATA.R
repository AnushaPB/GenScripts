#Import packages
library("sp")
library("spatstat")
library("maptools")
library("raster")
library("randomForest")
library("gdistance")
library("foreach")
library("doParallel")
library("doMC")

#Plot straight lines for first iteration of RF
G.table <- read.table(file="/home/fas/caccone/apb56/project/GPDGENCON/ken_reynolds_gendf.csv", sep=",", header=T)

env <- stack("/home/fas/caccone/apb56/project/GPDHABITAT/chelsa_merit_vars_kenya.tif")

crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") # ... add coordinate system

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

StraightPred <- predict(envPlus, Straight_RF)

pred.cond <- 1/StraightPred #build conductance surface

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Reynolds/BOUYER/LinReynoldsBouyer_beforeLCP_AllData.RData"))
