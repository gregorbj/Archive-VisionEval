#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework. It loads the framework library (visioneval) and supporting libraries. It then initializes a model and then runs 3 modules from the vedemo1 package.

#Load libraries
#--------------
library(visioneval)

#Initialize model
#----------------
initializeModel(ParamDir = "defs",
                RunParamFile = "run_parameters.json",
                GeoFile = "geo.csv",
                ModelParamFile = "model_parameters.json",
                DatastoreToLoad = NULL)

#Run all demo modules for all years
#----------------------------------
for (Year in getYears()) {
    runModule("CreateHouseholds", "vedemo1", Year = Year)
    runModule("CreateBzones", "vedemo1", Year = Year)
    runModule("CreateBzoneDev", "vedemo1", Year = Year)
}

#Check results in datastore
#--------------------------
#Household size in Household table
table(readFromTable("HhSize", "Household", "2010"))
table(readFromTable("HhSize", "Household", "2050"))
#Population density in Bzone table
plot(density(readFromTable("PopDen", "Bzone", "2010"), bw=200))
lines(density(readFromTable("PopDen", "Bzone", "2050"), bw=200), col="red")
#Distance from center in Bzone table
plot(density(readFromTable("DistFromCtr", "Bzone", "2010"), bw=0.25, na.rm=TRUE))
lines(density(readFromTable("DistFromCtr", "Bzone", "2050"), bw=0.25, na.rm=TRUE), col="red")
#Development type in Bzone table
boxplot(readFromTable("PopDen", "Bzone", "2010") ~ readFromTable("DevType", "Bzone", "2010"))
boxplot(readFromTable("PopDen", "Bzone", "2050") ~ readFromTable("DevType", "Bzone", "2050"), border="red", add=TRUE)

