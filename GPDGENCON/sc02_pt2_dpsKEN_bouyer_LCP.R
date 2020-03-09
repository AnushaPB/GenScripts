#Import foldnum for 10-fold cross validation

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
library("dplyr")

load("/home/fas/caccone/apb56/project/GPDGENCON/DPS/CV/RF_pt1.RData")

crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") # ... add coordinate system

rmr=function(x){
  ## function to truly delete raster and temporary files associated with them
  if(class(x)=="RasterLayer"&grepl("^/tmp",x@file@name)&fromDisk(x)==T){
    file.remove(x@file@name,sub("grd","gri",x@file@name))
    rm(x)
  }
}


###############################################
#Plot lines as SpatialLines:
###############################################

#Plot straight lines for first iteration of RF
Test.table <- read.table(file=paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/CV/testData_", foldnum, ".csv"), sep=",", header=T)
##For testing;
#Test.table <- Test.table[1:10,]

Train.table <- read.table(file=paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/CV/trainData_", foldnum, ".csv"), sep=",", header=T)
##For testing:
#Train.table <- Train.table[1:10,]

###############################################
#Create pixel of 1s for Buoyer methods
###############################################
pixels_raster <- env[[1]]
pixels_raster[,] <- 1
names(pixels_raster) <- "pixvals"

#create for projection
envPlus <- addLayer(env,pixels_raster)
names(envPlus) <- c(names(env),"pixvals") 

#START BUILDING TRAIN DF
#begin using objects that will be overwritten
#create group of ONLY unique train coordinate pairs (reduces number of lines)
unique_coords <-  unique(Train.table[,c("long1","lat1","long2","lat2")])

begin.table <- unique_coords[,c("long1","lat1")]
begin.coord <- begin.table #copy one for coords, one for df
coordinates(begin.coord) <- c("long1", "lat1")

end.table <- unique_coords[,c("long2","lat2")]
end.coord <- end.table #copy one for coords, one for df
coordinates(end.coord) <- c("long2", "lat2")

registerDoMC(cores=detectCores()) 

StraightMeanUniq <- foreach(r=1:nrow(begin.table), .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
  p <- psp(begin.table[r,1], begin.table[r,2], end.table[r,1], end.table[r,2], owin(range(c(begin.table[,1], end.table[,1])), range(c(begin.table[,2], end.table[,2]))))
  spatial.p <- as(p, "SpatialLines")
  proj4string(spatial.p) <- crs.geo 
  envvals <- raster::extract(env, spatial.p, fun=mean, na.rm=TRUE)
  pixvals <- raster::extract(pixels_raster, spatial.p, fun=sum, na.rm=TRUE)
  cbind(envvals, pixvals)
}
  
gc() 
#end using objects that will be overwritten

StraightMeanUniqDF.train <- as.data.frame(StraightMeanUniq)

#bind unique coords to unique lines
StraightMeanUniqDF.train <- cbind(unique_coords, StraightMeanUniqDF.train)

#use left_join to merge tables by coords in order to get the distance for each pair/line
StraightMeanDF.train <- left_join(StraightMeanUniqDF.train, Train.table, by = c("long1","lat1","long2","lat2"))

#subset to retain only necessary vars (remove long/lat, var1/var2, etc.) before building models
StraightMeanDF.train <- StraightMeanDF.train[,c(names(env),"pixvals","value")]

#remove any NAs for random forest
StraightMeanDF.train <- StraightMeanDF.train[complete.cases(StraightMeanDF.train),]

#END BUILDING TRAIN DF

#START BUILDING TEST DF
#begin using objects that will be overwritten (object names will be reused for testing)
#create group of ONLY unique test coordinate pairs (reduces number of lines)
unique_coords <-  unique(Test.table[,c("long1","lat1","long2","lat2")])

begin.table <- unique_coords[,c("long1","lat1")]
begin.coord <- begin.table #copy one for coords, one for df
coordinates(begin.coord) <- c("long1", "lat1")

end.table <- unique_coords[,c("long2","lat2")]
end.coord <- end.table #copy one for coords, one for df
coordinates(end.coord) <- c("long2", "lat2")

registerDoMC(cores=detectCores()) 

StraightMeanUniq <- foreach(r=1:nrow(begin.table), .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
  p <- psp(begin.table[r,1], begin.table[r,2], end.table[r,1], end.table[r,2], owin(range(c(begin.table[,1], end.table[,1])), range(c(begin.table[,2], end.table[,2]))))
  spatial.p <- as(p, "SpatialLines")
  proj4string(spatial.p) <- crs.geo 
  envvals <- raster::extract(env, spatial.p, fun=mean, na.rm=TRUE)
  pixvals <- raster::extract(pixels_raster, spatial.p, fun=sum, na.rm=TRUE)
  cbind(envvals, pixvals)
}

gc() 

#end using objects that will be overwritten
StraightMeanUniqDF.test <- as.data.frame(StraightMeanUniq)

#bind unique coords to unique lines
StraightMeanUniqDF.test <- cbind(unique_coords, StraightMeanUniqDF.test)

#use left_join to merge tables by coords in order to get the distance for each pair/line
StraightMeanDF.test <- left_join(StraightMeanUniqDF.test, Test.table, by = c("long1","lat1","long2","lat2"))

#subset to retain only necessary vars (remove long/lat, var1/var2, etc.) before building models
StraightMeanDF.test<- StraightMeanDF.test[,c(names(env),"pixvals","value")]

#remove any NAs for random forest
StraightMeanDF.test <- StraightMeanDF.test[complete.cases(StraightMeanDF.test),]

set.seed(NULL)

#tune RF
tune_x <- StraightMeanDF.train[,c(names(env),"pixvals")]
tune_y <- StraightMeanDF.train[,c("value")]
bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]

Straight_RF = randomForest(value ~ ., importance=TRUE, mtry = mtry_opt, na.action=na.omit, data=StraightMeanDF.train)

gc()

#Define empty vectors
RSQ_vec = c()
RMSE_vec = c()
RMSE2_vec = c()
MAE_vec = c()
MAE2_vec = c()
MAE3_vec = c()
Cor1_vec  = c()
Cor2_vec  = c()

#Validation parameters
RSQ = tail(Straight_RF$rsq ,1 )
RMSE = sqrt(tail(Straight_RF$mse ,1 ))
RMSE2 = sqrt(mean((predict(Straight_RF, StraightMeanDF.test) - StraightMeanDF.test$value)^2))
MAE = mean(abs(Straight_RF$predicted - StraightMeanDF.train$value))
MAE2 =  mean(abs(predict(Straight_RF, StraightMeanDF.train) - StraightMeanDF.train$value))
MAE3 = mean(abs(predict(Straight_RF, StraightMeanDF.test) - StraightMeanDF.test$value))
Cor1 = cor(predict(Straight_RF, StraightMeanDF.train), StraightMeanDF.train$value)
Cor2 = cor(predict(Straight_RF, StraightMeanDF.test), StraightMeanDF.test$value)

#Add straight line parameters to the vectors
RSQ_vec   = c(RSQ)
RMSE_vec   = c(RMSE)
RMSE2_vec  = c(RMSE2)
MAE_vec = c(MAE)
MAE2_vec = c(MAE2)
MAE3_vec = c(MAE3)
Cor1_vec  = c(Cor1)
Cor2_vec  = c(Cor2)

StraightPred <- predict(envPlus, Straight_RF)

print("first prediction resistance surface done")

pred.cond <- StraightPred #build conductance surface (DO NOT TAKE INVERSE FOR DPS - proportion of alleles shared is already a measure of connectivity)

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/BOUYER/LinDPSData_beforeLCP_Fold",foldnum,".RData"))

#Prepare points for use in least cost path loops - Training
unique_train <-  unique(Train.table[,c("long1","lat1","long2","lat2")])
P.points1.train <- SpatialPoints(unique_train[,c("long1","lat1")])
P.points2.train <- SpatialPoints(unique_train[,c("long2","lat2")])
proj4string(P.points1.train) <- crs.geo
proj4string(P.points2.train) <- crs.geo
NumPairs.train <- length(P.points1.train)


#Prepare points for use in least cost path loops - Testing
unique_test <-  unique(Test.table[,c("long1","lat1","long2","lat2")])
P.points1.test <- SpatialPoints(unique_test[,c("long1","lat1")])
P.points2.test <- SpatialPoints(unique_test[,c("long2","lat2")])
proj4string(P.points1.test) <- crs.geo
proj4string(P.points2.test) <- crs.geo
NumPairs.test		           <- length(P.points1.test)

#get parallelization set up
nw <- detectCores()
# cl <- makePSOCKcluster(nw) # is create multiple copy and it is usefull for works in multiple node
# registerDoParallel(cl)     # is create multiple copy and it is usefull for works in multiple node
registerDoMC(cores=nw)       # is create forks of the data good; for one node many cpu

print("cores registered")

print("starting loops")

for (it in 1:3) {
  
  rm(trNAm1C)
  gc()
  
  trNAm1 <- transition(pred.cond, transitionFunction=mean, directions=8) #make transitional matrix
  
  print("transition matrix done")
  
  trNAm1C <- geoCorrection(trNAm1, type="c") 
  
  rm(trNAm1)
  gc()
  
  
  #Extract mean value from LCP for TRAINING data
  
  UniqueLcpLoop.train <- foreach(r=1:NumPairs.train, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    if (extent(P.points1.train[r]) != extent(P.points2.train[r])){
      Ato <- shortestPath(trNAm1C, P.points1.train[r], P.points2.train[r]  , output="SpatialLines")
    } else {
      Ato <- P.points1.train[r]
    }
    envvals <- raster::extract(env, Ato, fun=mean, na.rm=TRUE)
    pixvals <- raster::extract(pixels_raster, Ato, fun=sum, na.rm=TRUE)
    cbind(envvals, pixvals)
  }
  
  UniqueLcpLoopDF.train <- as.data.frame(UniqueLcpLoop.train)
  
  #bind unique coords to unique lines
  UniqueLcpLoopDF.train <- cbind(unique_train, UniqueLcpLoopDF.train)
  
  #use left_join to merge tables by coords in order to get the distance for each pair/line
  LcpLoopDF.train <- left_join(UniqueLcpLoopDF.train, Train.table, by = c("long1","lat1","long2","lat2"))
  
  #subset to retain only necessary vars (remove long/lat, var1/var2, etc.) before building models
  LcpLoopDF.train <- LcpLoopDF.train[,c(names(env),"pixvals","value")]
  
  #remove any NAs for random forest
  LcpLoopDF.train <- LcpLoopDF.train[complete.cases(LcpLoopDF.train),]
  
  #Extract mean value from LCP for TESTING data
  UniqueLcpLoop.test <- foreach(r=1:NumPairs.test, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    if (extent(P.points1.test[r]) != extent(P.points2.test[r])){
      Ato <- shortestPath(trNAm1C, P.points1.test[r], P.points2.test[r]  , output="SpatialLines")
    } else {
      Ato <- P.points1.test[r]
    }
    envvals <- raster::extract(env, Ato, fun=mean, na.rm=TRUE)
    pixvals <- raster::extract(pixels_raster, Ato, fun=sum, na.rm=TRUE)
    cbind(envvals, pixvals)
  }
  
  UniqueLcpLoopDF.test <- as.data.frame(UniqueLcpLoop.test)
  
  #bind unique coords to unique lines
  UniqueLcpLoopDF.test <- cbind(unique_test, UniqueLcpLoopDF.test)
  
  #use left_join to merge tables by coords in order to get the distance for each pair/line
  LcpLoopDF.test <- left_join(UniqueLcpLoopDF.test, Test.table, by = c("long1","lat1","long2","lat2"))
  
  #subset to retain only necessary vars (remove long/lat, var1/var2, etc.) before building models
  LcpLoopDF.test <- LcpLoopDF.test[,c(names(env),"pixvals","value")]
  
  #remove any NAs for random forest
  LcpLoopDF.test <- LcpLoopDF.test[complete.cases(LcpLoopDF.test),]
  
  tune_x <- LcpLoopDF.train[,c(names(env),"pixvals")]
  tune_y <- LcpLoopDF.train[,c("value")]
  bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
  mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]
  
  LCP_RF = randomForest(value ~ ., importance=TRUE, mtry=mtry_opt, na.action=na.omit, data=LcpLoopDF.train)
  
  assign(paste0("LCP_RF", it), LCP_RF )
  
  print(paste0("finishing RF for iteration #", it))
  
  gc()
  
  rm(trNAm1C)
  
  gc()
  
  #add validation parameters here
  RSQ = tail(LCP_RF$rsq ,1 )
  RMSE = sqrt(tail(LCP_RF$mse ,1 ))
  RMSE2 = sqrt(mean((predict(LCP_RF, LcpLoopDF.test) - LcpLoopDF.test$value)^2))
  MAE = mean(abs(LCP_RF$predicted - LcpLoopDF.train$value))
  MAE2 =  mean(abs(predict(LCP_RF, LcpLoopDF.train) - LcpLoopDF.train$value))
  MAE3 = mean(abs(predict(LCP_RF, LcpLoopDF.test) - LcpLoopDF.test$value))
  Cor1 = cor(predict(LCP_RF, LcpLoopDF.train), LcpLoopDF.train$value)
  Cor2 = cor(predict(LCP_RF, LcpLoopDF.test), LcpLoopDF.test$value)
  
  RSQ_vec   = append(RSQ_vec, RSQ)
  RMSE_vec   = append(RMSE_vec, RMSE)
  RMSE2_vec  = append(RMSE2_vec, RMSE2)
  MAE_vec   = append(MAE_vec, MAE)
  MAE2_vec  = append(MAE2_vec, MAE2)
  MAE3_vec  = append(MAE3_vec, MAE3)
  Cor1_vec  = append(Cor1_vec, Cor1)
  Cor2_vec  = append(Cor2_vec, Cor2)
  
  
  pred = predict(envPlus, LCP_RF)
  
  print(paste0("finishing prediction for iteration #", it))
  
  rm(LCP_RF)
  
  assign(paste0("pred", it), pred)
  
  pred.cond <- pred #build conductance surface (DO NOT TAKE INVERSE FOR DPS - proportion of alleles shared is already a measure of connectivity)
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))
  
}  

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/BOUYER/LinDPSData_afterLCP_Fold",foldnum,".RData"))

d = data.frame(RSQ = RSQ_vec, RMSE = RMSE_vec, RMSE2 = RMSE2_vec, MAE = MAE_vec, MAE2 = MAE2_vec, MAE3 = MAE3_vec, Cor1 = Cor1_vec,  Cor2 = Cor2_vec) 

RF0 = Straight_RF
RF1 = LCP_RF1 
RF2 = LCP_RF2 
#RF3 = LCP_RF3 
#RF4 = LCP_RF4 
#RF5 = LCP_RF5 
#RF6 = LCP_RF6 
#RF7 = LCP_RF7
#RF8 = LCP_RF8
#RF9 = LCP_RF9
#RF10 = LCP_RF10
resist0 = StraightPred
resist1 = pred1 
resist2 = pred2 
#resist3 = pred3 
#resist4 = pred4 
#resist5 = pred5 
#resist6 = pred6 
#resist7 = pred7
#resist8 = pred8
#resist9 = pred9
#resist10 = pred10

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/BOUYER/LinDPSData_afterLCP_Fold",foldnum,".RData"))

#Best iteration based on Cor2 (DECIDE WHETHER THIS IS WHAT YOU WANT)
pos_max = which.max(RSQ_vec)

best_it = pos_max - 1 #first thing in the list in the list is straight lines and the second is iteration one, etc. 
RF = paste0("RF", best_it)
ResistanceMap = paste0("resist", best_it)

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/BOUYER/LinDPSData_afterLCP_Fold",foldnum,".RData"))