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

load("/home/fas/caccone/apb56/project/GPDGENCON/DPS/LinDPSGeoData_beforeLCP_AllData.RData")

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

StraightPred <- predict(env, Straight_RF)

print("first prediction resistance surface done")

pred.cond <- StraightPred #build conductance surface (DO NOT TAKE INVERSE)

#Prepare points for use in least cost path loops
unique_coords <- unique(G.table[,c("long1","lat1","long2","lat2")])

#FOR TESTING: (COMMENT OUT BEFORE FINAL RUN)
#unique_coords <- unique_coords[1:20,]

P.points1 <- SpatialPoints(unique_coords[,c("long1","lat1")])
P.points2 <- SpatialPoints(unique_coords[,c("long2","lat2")])
proj4string(P.points1) <- crs.geo
proj4string(P.points2) <- crs.geo
NumPairs	                  <- length(P.points1)

#get parallelization set up
nw <- detectCores()
# cl <- makePSOCKcluster(nw) # is create multiple copy and it is usefull for works in multiple node
# registerDoParallel(cl)     # is create multiple copy and it is usefull for works in multiple node
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
  UniqueLcpLoop <- foreach(r=1:NumPairs, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    #conditional statement to distinguish comparisons of the same coords (points) from lines (needed for extract to work)
    Ato <- shortestPath(trNAm1C, P.points1[r], P.points2[r]  , output="SpatialLines") #LINES
    if (extent(Ato)@xmin == extent(Ato)@xmax & extent(Ato)@ymin == extent(Ato)@ymax){ #IF TRUE: POINT, if FALSE: LINE
      Ato <- SpatialPoints(data.frame(extent(Ato)@xmin, extent(Ato)@ymin)) #POINT xmin == xmax/ymin == ymax so just choose one
      proj4string(Ato) <- crs.geo
    }
    data.frame(raster::extract(env, Ato, fun=mean, na.rm=TRUE))
  }
  
  
  #convert to DF
  UniqueLcpLoopDF<- as.data.frame(UniqueLcpLoop)
  
  #bind unique coords to unique lines
  UniqueLcpLoopDF <- cbind(unique_coords, UniqueLcpLoopDF)
  
  #use left_join to merge tables by coords in order to get the distance for each pair/line
  LcpLoopDF <- left_join(UniqueLcpLoopDF, G.table, by = c("long1","lat1","long2","lat2"))
  
  #subset to retain only necessary vars (remove long/lat, var1/var2, etc.) before building models
  LcpLoopDF <- LcpLoopDF[,c(names(env),"value")]
  
  #remove any NAs for random forest
  LcpLoopDF <- LcpLoopDF[complete.cases(LcpLoopDF),]
  
  tune_x <- LcpLoopDF[,names(env)]
  tune_y <- LcpLoopDF[,c("value")]
  bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
  mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]
  
  LCP_RF = randomForest(value ~ ., importance=TRUE, mtry=mtry_opt, na.action=na.omit, data=LcpLoopDF)
  
  assign(paste0("LCP_RF", it), LCP_RF )
  
  print(paste0("finishing RF for iteration #", it))
  
  rm(trNAm1C)
  
  gc()
  
  pred = predict(env, LCP_RF)
  
  print(paste0("finishing prediction for iteration #", it))
  
  rm(LCP_RF)
  
  assign(paste0("pred", it), pred)
  
  pred.cond <- pred #DO NOT TAKE INVERSE (1/pred) FOR DPS (already a measure of connectivity)
  
  pdf(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/LinDisData_ALLDATA_Pred_it",it,".pdf"), 5, 5)
  plot(pred.cond)
  dev.off()
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))
  
}  

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/DPS/LinDPSData_afterLCP_AllData.RData"))
