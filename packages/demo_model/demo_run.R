#==========
#demo_run.R
#==========

#This script demonstrates the VisionEval framework. It loads the framework library (visioneval) and supporting libraries. It then initializes a model and then runs 3 modules from the vedemo1 package.

#Load libraries
#--------------
library(jsonlite)
library(rhdf5)
library(visioneval)

#Initialize model
#----------------
initializeModel(Dir = "defs", ParamFile = "parameters.json",
                GeoFile = "geo.csv")

#Run all demo modules for all years
#----------------------------------
for (Year in E$Years) {
    runModule("CreateHouseholds", "vedemo1", Year = Year, IgnoreInp_ = NULL, IgnoreSet_ = NULL)
    runModule("CreateBzones", "vedemo1", Year = Year, IgnoreInp_ = NULL, IgnoreSet_ = NULL)
    runModule("CreateBzoneDev", "vedemo1", Year = Year, IgnoreInp_ = NULL, IgnoreSet_ = NULL)
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

