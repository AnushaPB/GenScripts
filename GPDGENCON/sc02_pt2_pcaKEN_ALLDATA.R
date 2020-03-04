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
library("dplyr")

#Plot straight lines for first iteration of RF
env <- stack("/home/fas/caccone/apb56/project/GPDHABITAT/chelsa_merit_vars_kenya.tif")
ext <- extent(env)
crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") # ... add coordinate system

G.table <- read.table(file="/home/fas/caccone/apb56/project/GPDGENCON/ken_pca_genbtwdf.csv", sep=",", header=T)
#G.table <- read.table(file="/Users/Anusha/Documents/GpdKenya/ken_pca_gendf.csv", sep=",", header=T)
#REMOVE POINTS OUTSIDE OF EXTENT
G.table <- subset(G.table, 
                  long1 > ext@xmin 
                  & long1 < ext@xmax 
                  & lat1 > ext@ymin 
                  & lat1 < ext@ymax 
                  & long2 > ext@xmin 
                  & long2 < ext@xmax 
                  & lat2 > ext@ymin 
                  & lat2 < ext@ymax)

###############################################
#Plot lines as SpatialLines:
###############################################

#Plot straight lines for first iteration of RF
#create group of ONLY unique coordinate pairs (reduces number of lines)
unique_coords <-  unique(G.table[,c("long1","lat1","long2","lat2")])

begin.table <- unique_coords[,c("long1","lat1")]
begin.coord <- begin.table #copy one for coords, one for df
coordinates(begin.coord) <- c("long1", "lat1")

end.table <- unique_coords[,c("long2","lat2")]
end.coord <- end.table #copy one for coords, one for df
coordinates(end.coord) <- c("long2", "lat2")

########################################
#Calculate mean of straight lines 
#######################################
registerDoMC(cores=detectCores()) 

StraightMeanUniq <- foreach(r=1:nrow(begin.table), .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
  p <- psp(begin.table[r,1], begin.table[r,2], end.table[r,1], end.table[r,2], owin(range(c(begin.table[,1], end.table[,1])), range(c(begin.table[,2], end.table[,2]))))
  spatial.p <- as(p, "SpatialLines")
  proj4string(spatial.p) <- crs.geo 
  data.frame(raster::extract(env, spatial.p, fun=mean, na.rm=TRUE))
  }

gc()

StraightMeanUniqDF <- as.data.frame(StraightMeanUniq)

#export table
write.csv(StraightMeanUniqDF,"/home/fas/caccone/apb56/project/GPDGENCON/PCA/StraightMeanUniqDF.csv") 

#bind unique coords to unique lines
StraightMeanUniqDF <- cbind(unique_coords, StraightMeanUniqDF)

#use left_join to merge tables by coords in order to get the distance for each pair/line
StraightMeanDF <- left_join(StraightMeanUniqDF, G.table, by = c("long1","lat1","long2","lat2"))

#subset to remove long/lat and var1/var2 and X before building models
StraightMeanDF <- subset(StraightMeanDF, select=c("value",names(env)))

write.csv(StraightMeanDF,"/home/fas/caccone/apb56/project/GPDGENCON/PCA/StraightMeanDF.csv")

#remove any NAs before random forest
StraightMeanDF <- StraightMeanDF[complete.cases(StraightMeanDF),]

###############################################
#Model with all data
###############################################
#check these
tune_x <- StraightMeanDF[,names(env)]
tune_y <- StraightMeanDF[,c("value")]
bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]

Straight_RF = randomForest(value ~ ., importance=TRUE, mtry = mtry_opt, na.action=na.omit, data=StraightMeanDF)

StraightPred <- predict(env, Straight_RF)

pred.cond <- 1/StraightPred #build conductance surface

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/PCA/LinPCAData_beforeLCP_AllData.RData"))