#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework. It loads the framework library (visioneval) and supporting libraries. It then initializes a model and then runs 3 modules from the vedemo1 package.

#Load libraries
#--------------
library(visioneval)

#Initialize model
#----------------
initializeModel(
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = NULL,
  IgnoreDatastore = FALSE,
  SaveDatastore = TRUE
)  

#Run all demo modules for all years
#----------------------------------
for(Year in getYears()) {
  runModule(
    ModuleName = "CreateHouseholds", 
    PackageName = "SimHouseholds",
    RunFor = "AllYears")
}

