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

#Plot straight lines for first iteration of RF
G.table <- read.table(file="/home/fas/caccone/apb56/project/GFFGENCON/uga_gendf.csv", sep=",", header=T)

env <- stack("/home/fas/caccone/apb56/project/GFFGENCON/chelsa_merit_vars_Uganda.tif")

crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") # ... add coordinate system

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
StraightMean <- raster::extract(env, spatial.p, fun=mean, na.rm=TRUE)

StraightMeanDF <- as.data.frame(StraightMean)

StraightMeanDF$Fst <- G.table$Fst



###############################################
#Model with all data
###############################################
#check these
tune_x <- StraightMeanDF[,names(env)]
tune_y <- StraightMeanDF[,c("Fst")]
bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]

Straight_RF = randomForest(Fst ~ ., importance=TRUE, mtry = mtry_opt, na.action=na.omit, data=StraightMeanDF)

save.image("/home/fas/caccone/apb56/project/GFFGENCON/RF/LinFSTData_beforeLCP_AllData.RData")