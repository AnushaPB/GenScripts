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

load("/home/fas/caccone/apb56/project/GPDGENCON/Reynolds/BOUYER/LinReynoldsBouyer_beforeLCP_AllData.RData")

crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs") # ... add coordinate system

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
NumPairs	                  <- length(P.points1)

#get parallelization set up
nw <- detectCores()
registerDoMC(cores=nw)       # is create forks of the data good; for one node many cpu

print("cores registerred")

print("starting loops")

for (it in 1:10) {
  
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
  
  pred = predict(envPlus, LCP_RF)
  
  print(paste0("finishing prediction for iteration #", it))
  
  rm(LCP_RF)
  
  assign(paste0("pred", it), pred)
  
  pred.cond <- 1/pred 
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))
  
}  

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/Reynolds/BOUYER/LinReynoldsBouyer_afterLCP_AllData.RData"))

