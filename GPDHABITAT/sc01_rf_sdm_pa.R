
##Script for evaluation of random forest SDM using:
  #SCALED environmental data
  #PRESENCE-ABSENCE data

##Libraries
library(raster)
library(dismo)
library(rgdal)
library(randomForest)
library(SDMTools)

##Generate necessary objects
#field data
gpd_field<-read.csv(file="/home/fas/caccone/apb56/project/GPDHABITAT/gpd_kenya_data_20152019.csv")

#define CRS and coords
crs.geo <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
coords<-data.frame(x=gpd_field$Long,y=gpd_field$Lat)
coordinates(coords)=~x+y
proj4string(coords)=crs.geo # set it to lat-long

#define extent
ext <- extent(33.7,42.5,-5,4.73)

#use envvar layers to create predictors
envvars_seasonal <- stack("/home/fas/caccone/apb56/project/CHELSA/biovars/KenyaBiovarsSeasonalAllYears.tif")
envvars_seasonal <- setExtent(envvars_seasonal,extent(33.7,42.5,-4.8,5))
envvars_biovars <- stack("/home/fas/caccone/apb56/project/CHELSA/biovars/UgandaKenyaBiovarsAllYears.tif")
envvars_biovars <- setExtent(envvars_biovars,extent(33.7,42.5,-4.8,5))
envvars <- stack(envvars_seasonal,envvars_biovars)
names(envvars)<-c(paste0("BIO",c(8:11),"S"),paste0("BIO",c(16:19),"S"),paste0("BIO",c(1:19)))
proj4string(envvars)<-crs.geo
predictors<-envvars

#predictor mask object should be a Raster object (stack, layer, etc.) of environmental variables of interest for model with NA values masked (i.e. ocean)
#the masked object will be used to assign background points that do not fall outside the extent and (importantly) are not placed in the ocean
predictors_mask<-stack("/home/fas/caccone/apb56/project/GPDHABITAT/envvars_scaled_ktmask.tif")
proj4string(predictors_mask)<-crs.geo

#extracting point values of all environmental variables from raster stack 
pointvals <- raster::extract(predictors,coords)
pointvals <- data.frame(pointvals)
gpd_vars <- data.frame(cbind(Total.Day=gpd_field$Total.Day,Long=gpd_field$Long,Lat=gpd_field$Lat,pointvals))

#coords of PRESENCE ONLY data (Kenya data is presence only, Uganda data is not)
pres_points <- data.frame(lon=gpd_vars$Long,lat=gpd_vars$Lat) 
presvals <- extract(predictors, pres_points)

##Evaluate random forest using k-fold partitioning

#create lists for storage
rf_eval_results <- list() #list to store evaluation results
rf_acc_results <- list() #list to store accuracy results
rf_tss_results <- list() #list to store tss results

#set k value (default:using k=5 for evaluation)
k=5

for (i in 1:k) {
  #kfold partitioning of presence data to create testing and training pres data
  set.seed(0)
  group <- kfold(pres_points, k)
  pres_train <- pres_points[group != i, ]
  pres_test <- pres_points[group == i, ]
  
  #generate background data for testing and training and partition using kfold
  set.seed(10)
  backg <- randomPoints(predictors_mask, n=300, ext=ext) #n=approx. number of points in pres set
  colnames(backg) = c('lon', 'lat')
  group <- kfold(backg, k)
  backg_train <- backg[group != i, ]
  backg_test <- backg[group == i, ]
  
  #use training set points to create training set of pa data and env data
  train <- rbind(pres_train, backg_train)
  pb_train <- c(rep(1, nrow(pres_train)), rep(0, nrow(backg_train)))
  envtrain <- raster::extract(predictors, train)
  envtrain <- data.frame(cbind(pa=pb_train, envtrain))
  
  #create test presence and test background data for model validation
  testpres <- data.frame(raster::extract(predictors, pres_test))
  testbackg <- data.frame(raster::extract(predictors, backg_test))
  
  model <- pa ~ .
  rf <- randomForest(model, data=envtrain)
  rf.pred<-predict(predictors,rf)
  
  #stor these results as list
  rf_eval_results[[i]] <- evaluate(testpres, testbackg, rf)
  
  
  #defining threshold for presence/absence by taking the mean of the threshold outputs
  tr <- mean(unlist(threshold(evaluate(testpres, testbackg, rf))))
  
  #presence points
  ##observed presence made binary
  pres_obs<-c(rep(1, nrow(pres_test)))
  ##predicted presence made binary
  predp_points<-extract(rf.pred,pres_test)
  predp_points[predp_points<tr] <- 0
  predp_points[predp_points>tr] <- 1
  
  #background points
  ##observed background made binary
  backg_obs<-c(rep(0, nrow(backg_test)))
  ##predicted background made binary
  predb_points<-extract(rf.pred,backg_test)
  predb_points[predb_points<tr] <- 0
  predb_points[predb_points>tr] <- 1
  
  #observed vector (bind in the same order so coords should be the same)
  obs<-c(pres_obs,backg_obs)
  #predicted vector (bind in the same order so coords should be the same)
  pred<-c(predp_points,predb_points)
  
  #assess accuracy
  rf_acc_results[[i]]<-accuracy(obs,pred,threshold=tr)
  
  #calculate True Skill Statistic  (true positive rate (sensitivity) + true negative rate (specificity) - 1)
  rf_tss_results[[i]]<-(rf_acc_results[[i]]$sensitivity+rf_acc_results[[i]]$specificity-1)
  
}

##Export Results
#create exportable dataframe with outputs of evaluation and accuracy objects
rf_eval_results.auc<-list()
rf_eval_results.cor<-list()
rf_acc_results.auc<-list()
rf_acc_results.thr<-list()
rf_acc_results.sen<-list()
rf_acc_results.spe<-list()
rf_acc_results.kappa<-list()
rf_acc_results.prop<-list()
rf_acc_results.tss<-list()

for (i in 1:k) {
  rf_eval_results.auc[[i]] <- rf_eval_results[[i]]@auc
  rf_eval_results.cor[[i]] <- rf_eval_results[[i]]@cor
  rf_acc_results.auc[[i]]<- rf_acc_results[[i]]$AUC
  rf_acc_results.thr[[i]]<- rf_acc_results[[i]]$threshold
  rf_acc_results.sen[[i]]<- rf_acc_results[[i]]$sensitivity
  rf_acc_results.spe[[i]]<- rf_acc_results[[i]]$specificity
  rf_acc_results.kappa[[i]]<- rf_acc_results[[i]]$Kappa
  rf_acc_results.prop[[i]]<- rf_acc_results[[i]]$prop.correct
  rf_acc_results.tss[[i]]<- rf_tss_results[[i]]
}

#create table of results for each iteration
rf_eval_results.df<-data.frame(
  Index=c(1:k),
  AUC=unlist(rf_eval_results.auc),
  COR=unlist(rf_eval_results.cor),
  AUC.binary=unlist(rf_acc_results.auc),
  Threshold=unlist(rf_acc_results.thr),
  Sensitivity=unlist(rf_acc_results.sen),
  Specificity=unlist(rf_acc_results.spe),
  Kappa=unlist(rf_acc_results.kappa),
  Prop.Correct=unlist(rf_acc_results.prop),
  TSS=unlist(rf_acc_results.tss)
)

#Add row to summary table for mean values
mean_vals<-cbind(Index="mean",rbind(sapply(rf_eval_results.df[,-1],mean)))
rf_eval_results.df<-rbind(rf_eval_results.df,mean_vals)

write.csv(rf_eval_results.df,file="/home/fas/caccone/apb56/project/GPDHABITAT/randomforest_evalresults.csv")

