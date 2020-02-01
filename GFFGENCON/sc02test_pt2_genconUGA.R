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

load("/home/fas/caccone/apb56/project/GFFGENCON/RF/CV/LinFSTData_beforeLCP_Fold1.RData")

myExpl <- stack("/home/fas/caccone/apb56/project/GFFGENCON/chelsa_merit_vars_Uganda.tif")

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
NumPairs.test    <- length(P.points1.test)

registerDoMC(cores=nw)      

print("cores registered")

print("starting loops")


#start of big loop
for (it in 1:10) {
  
  rm(trNAm1C)
  gc()
  
  trNAm1 <- transition(pred.cond, transitionFunction=mean, directions=8) #make transitional matrix
  
  print("transition matrix done")
  
  trNAm1C <- geoCorrection(trNAm1, type="c") 
  
  rm(trNAm1)
  gc()
  
  
  #Extract mean value from LCP for training data
  
  LcpLoop.train <- foreach(r=1:NumPairs.train, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    Ato <- shortestPath(trNAm1C, P.points1.train[r], P.points2.train[r]  , output="SpatialLines")
    data.frame(raster::extract(myExpl,  Ato     , fun=mean, na.rm=TRUE))
    
  }
  
  
  
  #Extract mean value from LCP for testing data
  
  LcpLoop.test <- foreach(r=1:NumPairs.test, .combine='rbind', .packages=c('raster', 'gdistance')  ,   .inorder=TRUE   ) %dopar% {
    Ato <- shortestPath(trNAm1C, P.points1.test[r], P.points2.test[r]  , output="SpatialLines")
    data.frame(raster::extract(myExpl,  Ato     , fun=mean, na.rm=TRUE))
    
  }
  
  
  #Add geo distance and FST to the datasets
  LcpLoopDF.train <- as.data.frame(LcpLoop.train)
  #LcpLoopDF.train$GeoDist <- DistVar.train
  LcpLoopDF.train$Fst <- Train.table$Fst
  
  LcpLoopDF.test <- as.data.frame(LcpLoop.test)
  # LcpLoopDF.test$GeoDist <- DistVar.test
  LcpLoopDF.test$Fst = Test.table$Fst
  
  tune_x <- LcpLoopDF.train[,names(myExpl)]
  tune_y <- LcpLoopDF.train[,c("Fst")]
  bestmtry <- tuneRF(tune_x, tune_y, stepFactor=1.5, improve=1e-5, ntree=500)
  mtry_opt <- bestmtry[,"mtry"][which.min(bestmtry[,"OOBError"])]
  
  LCP_RF = randomForest(Fst ~ ., importance=TRUE, mtry=mtry_opt, na.action=na.omit, data=LcpLoopDF.train)
  
  assign(paste0("LCP_RF", it), LCP_RF )
  
  
  print(paste0("finishing RF for iteration #", it))
  
  gc()
  
  rm(trNAm1C)
  
  gc()
  
  #add validation parameters here
  RSQ = tail(LCP_RF$rsq ,1 )
  RMSE = sqrt(tail(LCP_RF$mse ,1 ))
  RMSE2 = sqrt(mean((predict(LCP_RF, LcpLoopDF.test) - LcpLoopDF.test$Fst)^2))
  MAE = mean(abs(LCP_RF$predicted - LcpLoopDF.train$Fst))
  MAE2 =  mean(abs(predict(LCP_RF, LcpLoopDF.train) - LcpLoopDF.train$Fst))
  MAE3 = mean(abs(predict(LCP_RF, LcpLoopDF.test) - LcpLoopDF.test$Fst))
  Cor1 = cor(predict(LCP_RF, LcpLoopDF.train), LcpLoopDF.train$Fst)
  Cor2 = cor(predict(LCP_RF, LcpLoopDF.test), LcpLoopDF.test$Fst)
  
  
  RSQ_vec   = append(RSQ_vec, RSQ)
  RMSE_vec   = append(RMSE_vec, RMSE)
  RMSE2_vec  = append(RMSE2_vec, RMSE2)
  MAE_vec   = append(MAE_vec, MAE)
  MAE2_vec  = append(MAE2_vec, MAE2)
  MAE3_vec  = append(MAE3_vec, MAE3)
  Cor1_vec  = append(Cor1_vec, Cor1)
  Cor2_vec  = append(Cor2_vec, Cor2)
  
  
  pred = predict(myExpl, LCP_RF)
  
  print(paste0("finishing prediction for iteration #", it))
  
  
  rm(LCP_RF)
  
  assign(paste0("pred", it), pred)
  
  pred.cond <- 1/pred 
  
  rmr(pred)
  
  gc()
  
  print(paste0("end of loop for iteration #", it))
  
}  

#end of big loop


d = data.frame(RSQ = RSQ_vec, RMSE = RMSE_vec, RMSE2 = RMSE2_vec, MAE = MAE_vec, MAE2 = MAE2_vec, MAE3 = MAE3_vec, Cor1 = Cor1_vec,  Cor2 = Cor2_vec) 
write.csv(d, paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/CV/LinDisData_Run", foldnum, "_ValidationTable.csv"), row.names =FALSE)

RF0 = Straight_RF
RF1 = LCP_RF1 
RF2 = LCP_RF2 
RF3 = LCP_RF3 
RF4 = LCP_RF4 
RF5 = LCP_RF5 
RF6 = LCP_RF6 
RF7 = LCP_RF7
RF8 = LCP_RF8
RF9 = LCP_RF9
RF10 = LCP_RF10
resist0 = StraightPred
resist1 = pred1 
resist2 = pred2 
resist3 = pred3 
resist4 = pred4 
resist5 = pred5 
resist6 = pred6 
resist7 = pred7
resist8 = pred8
resist9 = pred9
resist10 = pred10

#Best iteration based on Cor2 (DECIDE WHETHER THIS IS WHAT YOU WANT)
pos_max = which.max(Cor2_vec)

best_it = pos_max - 1 #first thing in the list in the list is straight lines and the second is iteration one, etc. 
RF = paste0("RF", best_it)
ResistanceMap = paste0("resist", best_it)

pdf(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/CV/LinDisData_Run",foldnum,"_BestCor2_Pred_it",best_it,".pdf"), 5, 5)
plot(get(ResistanceMap))
dev.off()

fit = lm(get(RF)$predicted ~ LcpLoopDF.train$Fst)
#adjr2 = round(summary(fit)$adj.r.squared, digits=3)
pdf(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/CV/LinDisData_Run",foldnum,"_BestCor2_TrainingScatter_it", best_it, ".pdf"), 5, 5)
plot(LcpLoopDF.train$Fst,get(RF)$predicted,  xlab ="Observed FST* (train)", ylab="Predicted FST")
#legend("bottomright", legend=c(paste0("Adj. R^2 = ", adjr2)), cex=0.7)
dev.off()

fit = lm(predict(get(RF), LcpLoopDF.test) ~ LcpLoopDF.test$Fst)
#adjr2 = round(summary(fit)$adj.r.squared, digits=3)
pdf(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/CV/LinDisData_Run",foldnum,"_BestCor2_ValidScatter_it", best_it,".pdf"), 5, 5)
plot(LcpLoopDF.test$Fst, predict(get(RF), LcpLoopDF.test),  xlab ="Observed FST* (valid)", ylab="Predicted FST")
#legend("bottomright", legend=c(paste0("Adj. R^2 = ", adjr2)), cex=0.7)
dev.off()

pdf(paste0("/home/fas/caccone/apb56/project/GPDGENCON/RF/CV/LinDisData_Run",foldnum,"_BestCor2_ImpVars_it",best_it,".pdf"), 5, 5)
varImpPlot(get(RF))
dev.off()

