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


rmr=function(x){
  ## function to truly delete raster and temporary files associated with them
  if(class(x)=="RasterLayer"&grepl("^/tmp",x@file@name)&fromDisk(x)==T){
    file.remove(x@file@name,sub("grd","gri",x@file@name))
    rm(x)
  }
}

#GeoDist <- raster(nrows = 1500, ncols = 4140, xmn = -113.5, xmx = -79, ymn = 24, ymx = 36.5, crs = crs.geo, vals = 1)
#names(GeoDist) <- c('GeoDist')

rm(env)

###############################################
#Plot lines as SpatialLines:
###############################################

#Plot straight lines for first iteration of RF
G.table <- read.table(file="/home/fas/caccone/apb56/project/GPDGENCON/ken_edwards_gendf.csv", sep=",", header=T)

#Create Leave One Point Out Cross Validation (LOPOCV) data 
for (i in levels(pop.df$Var1)){
  testData <- pop.df[pop.df$Var1==i | pop.df$Var2==i,]
  #write.csv(testData, paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/testData_", i, ".csv"))
  assign(paste0("testData_", i), testData)
  
  trainData <- pop.df[pop.df$Var1!=i & pop.df$Var2!=i,]
  #write.csv(trainData, paste0("/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/trainData_", i, ".csv"))
  assign(paste0("trainData_", i), trainData)
  
  print(nrow(train)+nrow(test) == nrow(pop.df)) #SHOULD BE TRUE ALWAYS
}

save.image(file = "/home/fas/caccone/apb56/project/GPDGENCON/Edwards/LOPOCV/RF_pt1.RData")