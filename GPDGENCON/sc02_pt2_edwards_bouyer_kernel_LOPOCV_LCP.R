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

#load kernel density layer
kernel <- raster("/home/fas/caccone/apb56/project/GPDGENCON/KenTz_kernel_50m_2020-03-10_final.tif")
names(kernel) <- "kernel"

#stack predictor vars
env <- stack(envvars,kernel)

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
##FOR TESTING SCRIPT:
#Test.table <- Test.table[1:5,]

Train.table <- read.table(file=paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/trainData_", foldnum, ".csv"), sep=",", header=T)
##FOR TESTING SCRIPT:
#Train.table <- Test.table[1:5,]

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
#Calculate mean of straight lines and making initial RF model
#######################################
#For training
envvals <- raster::extract(env, spatial.p.train, fun=mean, na.rm=TRUE)
pixvals <- raster::extract(pixels_raster, spatial.p.train, fun=sum, na.rm=TRUE)
StraightMean.train <- cbind(envvals,pixvals)

#DistVar.train <- raster::extract(GeoDist, spatial.p.train, fun=sum, na.rm=TRUE)

StraightMeanDF.train <- as.data.frame(StraightMean.train)

#StraightMeanDF.train$GeoDist <- DistVar.train

StraightMeanDF.train$Distance <- Train.table$Distance

#For testing
envvals <- raster::extract(env, spatial.p.test, fun=mean, na.rm=TRUE)
pixvals <- raster::extract(pixels_raster, spatial.p.test, fun=sum, na.rm=TRUE)
StraightMean.test <- cbind(envvals,pixvals)

#DistVar.test <- raster::extract(GeoDist, spatial.p.test, fun=sum, na.rm=TRUE)

StraightMeanDF.test <- as.data.frame(StraightMean.test)

#StraightMeanDF.test$GeoDist <- DistVar.test

StraightMeanDF.test$Distance <- Test.table$Distance

set.seed(NULL)

#check these
tune_x <- StraightMeanDF.train[,c(names(env),"pixvals")]
tune_y <- StraightMeanDF.train[,c("Distance")]
bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]

Straight_RF = randomForest(Distance ~ ., importance=TRUE, mtry = mtry_opt, na.action=na.omit, data=StraightMeanDF.train)

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
RMSE2 = sqrt(mean((predict(Straight_RF, StraightMeanDF.test) - StraightMeanDF.test$Distance)^2))
MAE = mean(abs(Straight_RF$predicted - StraightMeanDF.train$Distance))
MAE2 =  mean(abs(predict(Straight_RF, StraightMeanDF.train) - StraightMeanDF.train$Distance))
MAE3 = mean(abs(predict(Straight_RF, StraightMeanDF.test) - StraightMeanDF.test$Distance))
Cor1 = cor(predict(Straight_RF, StraightMeanDF.train), StraightMeanDF.train$Distance)
Cor2 = cor(predict(Straight_RF, StraightMeanDF.test), StraightMeanDF.test$Distance)

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

#build conductance surface
pred.cond <- 1/StraightPred 

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/LinEdwardsBouyerKernel_beforeLCP_Point",foldnum,".RData"))


#Prepare points for use in least cost path loops - Training
P.points1.train <- SpatialPoints(Train.table[,c("long1","lat1")])
P.points2.train <- SpatialPoints(Train.table[,c("long2","lat2")])
proj4string(P.points1.train) <- crs.geo
proj4string(P.points2.train) <- crs.geo
NumPairs.train <- length(P.points1.train)


#Prepare points for use in least cost path loops - Testing
P.points1.test <- SpatialPoints(Test.table[,c("long1","lat1")])
P.points2.test <- SpatialPoints(Test.table[,c("long2","lat2")])
proj4string(P.points1.test) <- crs.geo
proj4string(P.points2.test) <- crs.geo
NumPairs.test		                                       <- length(P.points1.test)


#get parallelization set up
nw <- detectCores()
# cl <- makePSOCKcluster(nw) # is create multiple copy and it is usefull for works in multiple node
# registerDoParallel(cl)     # is create multiple copy and it is usefull for works in multiple node
registerDoMC(cores=nw)       # is create forks of the data good; for one node many cpu

for (it in 1:5) {
  
  rm(trNAm1C)
  gc()
  
  trNAm1 <- transition(pred.cond, transitionFunction=mean, directions=8) #make transitional matrix
  
  print("transition matrix done")
  
  trNAm1C <- geoCorrection(trNAm1, type="c") 
  
  rm(trNAm1)
  gc()
  
  
  #Extract mean value from LCP for training data
  
  LcpLoop.train <- foreach(r=1:NumPairs.train, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    Ato <- shortestPath(trNAm1C, P.points1.train[r], P.points2.train[r], output="SpatialLines")
    envvals <- raster::extract(env, Ato, fun=mean, na.rm=TRUE)
    pixvals <- raster::extract(pixels_raster, Ato, fun=sum, na.rm=TRUE)
    cbind(envvals, pixvals)
  }
  
  
  
  #Extract mean value from LCP for testing data
  
  LcpLoop.test <- foreach(r=1:NumPairs.test, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    Ato <- shortestPath(trNAm1C, P.points1.test[r], P.points2.test[r]  , output="SpatialLines")
    envvals <- raster::extract(env, Ato, fun=mean, na.rm=TRUE)
    pixvals <- raster::extract(pixels_raster, Ato, fun=sum, na.rm=TRUE)
    cbind(envvals, pixvals)
  }
  
  
  #Add Edwards distance to the datasets
  LcpLoopDF.train <- as.data.frame(LcpLoop.train)
  LcpLoopDF.train$Distance <- Train.table$Distance
  assign(paste0("LcpLoopDF.train", it), LcpLoopDF.train)
  
  LcpLoopDF.test <- as.data.frame(LcpLoop.test)
  LcpLoopDF.test$Distance = Test.table$Distance
  assign(paste0("LcpLoopDF.test", it), LcpLoopDF.test)
  
  tune_x <- LcpLoopDF.train[,c(names(env),"pixvals")]
  tune_y <- LcpLoopDF.train[,c("Distance")]
  bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
  mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]
  
  LCP_RF = randomForest(Distance ~ ., importance=TRUE, mtry=mtry_opt, na.action=na.omit, data=LcpLoopDF.train)
  
  assign(paste0("LCP_RF", it), LCP_RF )
  
  print(paste0("finishing RF for iteration #", it))
  
  gc()
  
  rm(trNAm1C)
  
  gc()
  
  #add validation parameters here
  RSQ = tail(LCP_RF$rsq ,1 )
  RMSE = sqrt(tail(LCP_RF$mse ,1 ))
  RMSE2 = sqrt(mean((predict(LCP_RF, LcpLoopDF.test) - LcpLoopDF.test$Distance)^2))
  MAE = mean(abs(LCP_RF$predicted - LcpLoopDF.train$Distance))
  MAE2 =  mean(abs(predict(LCP_RF, LcpLoopDF.train) - LcpLoopDF.train$Distance))
  MAE3 = mean(abs(predict(LCP_RF, LcpLoopDF.test) - LcpLoopDF.test$Distance))
  Cor1 = cor(predict(LCP_RF, LcpLoopDF.train), LcpLoopDF.train$Distance)
  Cor2 = cor(predict(LCP_RF, LcpLoopDF.test), LcpLoopDF.test$Distance)
  
  
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
  
  pred.cond <- 1/pred 
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))

  save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/LinEdwardsBouyerKernel_afterLCP_Fold",foldnum,".RData"))
  
}  

d = data.frame(RSQ = RSQ_vec, RMSE = RMSE_vec, RMSE2 = RMSE2_vec, MAE = MAE_vec, MAE2 = MAE2_vec, MAE3 = MAE3_vec, Cor1 = Cor1_vec,  Cor2 = Cor2_vec)

RF0 = Straight_RF
RF1 = LCP_RF1 
RF2 = LCP_RF2 
RF3 = LCP_RF3 
RF4 = LCP_RF4 
RF5 = LCP_RF5 
#RF6 = LCP_RF6 
#RF7 = LCP_RF7
#RF8 = LCP_RF8
#RF9 = LCP_RF9
#RF10 = LCP_RF10
resist0 = StraightPred
resist1 = pred1 
resist2 = pred2 
resist3 = pred3 
resist4 = pred4 
resist5 = pred5 
#resist6 = pred6 
#resist7 = pred7
#resist8 = pred8
#resist9 = pred9
#resist10 = pred10

#Best iteration based on RMSE 
pos_max = which.max(RMSE_vec)

best_it = pos_max - 1 #first thing in the list in the list is straight lines and the second is iteration one, etc. 
RF = paste0("RF", best_it)
ResistanceMap = paste0("resist", best_it)

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/LinEdwardsBouyerKernel_afterLCP_Point",foldnum,".RData"))
