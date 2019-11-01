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

#load prepared raster stack for North America
env <- stack("/home/fas/caccone/apb56/project/GFFHABITAT/chelsa_merit_vars_Uganda.tif")

###############################################
#Plot lines as SpatialLines:
###############################################

#Plot straight lines for first iteration of RF
G.table <- read.table(file="/home/fas/caccone/apb56/project/GFFGENCON/uga_gendf.csv", sep=",", header=T)

#Randomly shuffle the data
yourData<-G.table[sample(nrow(G.table)),]

#Create 10 equally size folds
folds <- cut(seq(1,nrow(yourData)),breaks=10,labels=FALSE)

#Perform 10 fold cross validation
for(i in 1:10){
  #Segement your data by fold using the which() function 
  testIndexes <- which(folds==i,arr.ind=TRUE)
  testData <- yourData[testIndexes, ]
  write.csv(testData, paste0("/home/fas/caccone/apb56/project/GFFGENCON/RF/CV/testData_", i, ".csv"))
  trainData <- yourData[-testIndexes, ]
  assign(paste0("trainData_", i), trainData)
  write.csv(trainData, paste0("/home/fas/caccone/apb56/project/GFFGENCON/RF/CV/trainData_", i, ".csv"))
}


save.image(file = "/home/fas/caccone/apb56/project/GFFGENCON/RF/CV/RF_pt1.RData")