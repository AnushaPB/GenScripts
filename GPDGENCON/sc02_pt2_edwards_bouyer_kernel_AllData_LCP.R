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
G.table <- read.table(file="/home/fas/caccone/apb56/project/GPDGENCON/ken_edwards_gendf.csv", sep=",", header=T)
##for testing
#G.table <- G.table[1:5,]

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

#Validation parameters
RSQ = tail(Straight_RF$rsq ,1 )
RMSE = sqrt(tail(Straight_RF$mse ,1 ))
RMSE2 = sqrt(mean((predict(Straight_RF, StraightMeanDF) - StraightMeanDF$Distance)^2))
MAE2 =  mean(abs(predict(Straight_RF, StraightMeanDF) - StraightMeanDF$Distance))

#Add straight line parameters to the vectors
RSQ_vec   = c(RSQ)
RMSE_vec   = c(RMSE)
RMSE2_vec  = c(RMSE2)
MAE2_vec = c(MAE2)

StraightPred <- predict(envPlus, Straight_RF)

pred.cond <- 1/StraightPred #build conductance surface

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/EdwardsBouyerKernel_beforeLCP_AllData.RData"))

rmr=function(x){
  ## function to truly delete raster and temporary files associated with them
  if(class(x)=="RasterLayer"&grepl("^/tmp",x@file@name)&fromDisk(x)==T){
    file.remove(x@file@name,sub("grd","gri",x@file@name))
    rm(x)
  }
}

gc()

#previous script created RF straight paths model

#Prepare points for use in least cost path loops
P.points1 <- SpatialPoints(G.table[,c("long1","lat1")])
P.points2 <- SpatialPoints(G.table[,c("long2","lat2")])
proj4string(P.points1) <- crs.geo
proj4string(P.points2) <- crs.geo
NumPairs	                         <- length(P.points1)

#get parallelization set up
nw <- detectCores()
registerDoMC(cores=nw)       # is create forks of the data good; for one node many cpu

print("cores registerred")

print("starting loops")

for (it in 1:4) {
  
  rm(trNAm1C)
  gc()
  
  trNAm1 <- transition(pred.cond, transitionFunction=mean, directions=8) #make transitional matrix
  
  print("transition matrix done")
  
  trNAm1C <- geoCorrection(trNAm1, type="c") 
  
  rm(trNAm1)
  gc()
  
  #Extract mean value from LCP 
  
  LcpLoop <- foreach(r=1:NumPairs, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    Ato <- shortestPath(trNAm1C, P.points1[r], P.points2[r]  , output="SpatialLines")
    envvals <- raster::extract(env, Ato, fun=mean, na.rm=TRUE)
    pixvals <- raster::extract(pixels_raster, Ato, fun=sum, na.rm=TRUE)
    cbind(envvals,pixvals)
  }
  
  #Convert to DF
  LcpLoopDF<- as.data.frame(LcpLoop)
  #Add genetic distance
  LcpLoopDF$Distance <- G.table$Distance
  
  #tune RF parameters
  tune_x <- LcpLoopDF[,c(names(env),"pixvals")]
  tune_y <- LcpLoopDF[,c("Distance")]
  bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
  mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]
  
  LCP_RF = randomForest(Distance ~ ., importance=TRUE, mtry=mtry_opt, na.action=na.omit, data=LcpLoopDF)
  
  assign(paste0("LCP_RF", it), LCP_RF )
  
  print(paste0("finishing RF for iteration #", it))
  
  gc()
  
  rm(trNAm1C)
  
  gc()
  
  #add validation parameters here
  RSQ = tail(LCP_RF$rsq ,1 )
  RMSE = sqrt(tail(LCP_RF$mse ,1 ))
  RMSE2 = sqrt(mean((predict(LCP_RF, LcpLoopDF) - LcpLoopDF$Distance)^2))
  MAE2 =  mean(abs(predict(LCP_RF, LcpLoopDF) - LcpLoopDF$Distance))
  
  RSQ_vec   = append(RSQ_vec, RSQ)
  RMSE_vec   = append(RMSE_vec, RMSE)
  RMSE2_vec  = append(RMSE2_vec, RMSE2)
  MAE2_vec  = append(MAE2_vec, MAE2)
  
  pred = predict(envPlus, LCP_RF)
  
  print(paste0("finishing prediction for iteration #", it))
  
  rm(LCP_RF)
  
  assign(paste0("pred", it), pred)
  
  pred.cond <- 1/pred 
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))
  
  save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/EdwardsBouyerKernel_afterLCP_AllData.RData"))
  
}  


save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/EdwardsBouyerKernel_afterLCP_AllData.RData"))