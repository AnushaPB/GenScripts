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

rm(env)

###############################################
#Plot lines as SpatialLines:
###############################################

#Plot straight lines for first iteration of RF
G.table <- read.table(file="/home/fas/caccone/apb56/project/GFFGENCON/Gff_Uganda_GenDistTable.csv", sep=",", header=T)

#create sorted list of unique sites 
sites <-  sort(unique(c(levels(G.table$Pop1),levels(G.table$Pop2))))

#create list of points
#Create Leave One Point Out Cross Validation (LOPOCV) data 
for (i in 1:length(sites)){
  testData <- G.table[G.table$Pop1 == sites[i] | G.table$Pop2 == sites[i],] #include rows where the site appears in either column (OR)
  write.csv(testData, paste0("/home/fas/caccone/apb56/project/GFFGENCON/Edwards/LOPOCV/testData_", i, ".csv"))
  assign(paste0("testData_", i), testData)
  
  trainData <- G.table[G.table$Pop1 != sites[i] & G.table$Pop2 != sites[i],] #keep rows where the Vars do NOT equal the site for BOTH Vars (&)
  #note: needs to be &  not | because you want the conditionalf for both rows to be TRUE (both rows to NOT have the site)
  #for ex, if you get a T for V1 (V1 does not equal site) and a F for V2 (V2 does equal site) and you want that row DISCARDED 
  write.csv(trainData, paste0("/home/fas/caccone/apb56/project/GFFGENCON/Edwards/LOPOCV/trainData_", i, ".csv"))
  assign(paste0("trainData_", i), trainData)
  
  print(nrow(trainData)+nrow(testData) == nrow(G.table)) #SHOULD BE TRUE ALWAYS
}

save.image(file = "/home/fas/caccone/apb56/project/GFFGENCON/Edwards/LOPOCV/RF_pt1.RData")