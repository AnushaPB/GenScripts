library(rgdal)
library(raster)

biostack<-stack(paste0("/home/fas/caccone/apb56/project/CHELSA/biovars/UgandaKenyaBiovars",c(2008:2013),".tif"))
#combine corresponding biovar layers by mean (take mean of all biovars for all years)
indices<-rep(c(1:19), times = 6)
biostack_mean<-stackApply(biostack, indices, fun=mean)
writeRaster(biostack_mean,"/home/fas/caccone/apb56/project/CHELSA/biovars/UgandaKenyaBiovarsAllYears",format="GTiff")