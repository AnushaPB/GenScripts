
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

load("/home/fas/caccone/apb56/project/GPDGENCON/RF/LinFSTData_beforeLCP_AllData.RData")

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

pred.cond <- 1/StraightPred #build conductance surface

#Prepare points for use in least cost path loops
P.points1 <- SpatialPoints(G.table[,c("long1","lat1")])
P.points2 <- SpatialPoints(G.table[,c("long2","lat2")])
proj4string(P.points1) <- crs.geo
proj4string(P.points2) <- crs.geo
NumPairs	           <- length(P.points1)

#For now update NumPoints based on how many points you're running
#figure out how to replace 38 with a variable
##NumPoints = 38

#get parallelization set up
nw <- detectCores()
# cl <- makePSOCKcluster(nw) # is create multiple copy and it is usefull for works in multiple node
# registerDoParallel(cl)     # is create multiple copy and it is usefull for works in multiple node
registerDoMC(cores=nw)       # is create forks of the data good; for one node many cpu

print("cores registerred")

## create list for iteration
##is it ok if it's too long bc indexing doesn't really matter?
##a=c() 
##for (x in 1:(NumPoints-1)) {      
  ##for (y in (x+1):NumPoints) {   
   ## a = rbind (a, c(x,y) )
  ##}
##}

##FT=a[,1] != a[,2]
##pointlist=a[ which(FT),]
##pointlist = G.table[,c('Var1','Var2')]
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
    data.frame(raster::extract(env,  Ato     , fun=mean, na.rm=TRUE))
    
  }
  
  
  #Add geo distance and FST to the datasets
  LcpLoopDF<- as.data.frame(LcpLoop)
  #LcpLoopDF.train$GeoDist <- DistVar.train
  LcpLoopDF$Distance <- G.table$Distance
  
  tune_x <- LcpLoopDF[,names(env)]
  tune_y <- LcpLoopDF[,c("Distance")]
  bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
  mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]
  
  LCP_RF = randomForest(Distance ~ ., importance=TRUE, mtry=mtry_opt, na.action=na.omit, data=LcpLoopDF)
  
  assign(paste0("LCP_RF", it), LCP_RF )
  
  print(paste0("finishing RF for iteration #", it))
  
  gc()
  
  rm(trNAm1C)
  
  gc()
  
  pred = predict(env, LCP_RF)
  
  print(paste0("finishing prediction for iteration #", it))
  
  rm(LCP_RF)
  
  assign(paste0("pred", it), pred)
  
  pred.cond <- 1/pred 
 
  pdf(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/LinDisData_ALLDATA_Pred_it",it,".pdf"), 5, 5)
  plot(pred.cond)
  dev.off()
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))
  
}  

save.image(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/LinFSTData_afterLCP_AllData.RData"))


