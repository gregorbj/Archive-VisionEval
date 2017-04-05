#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for the RSPM model.

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
  LoadDatastore = FALSE,
  DatastoreName = NULL,
  SaveDatastore = TRUE
  )  

#Run all demo module for all years
#---------------------------------
for(Year in getYears()) {
  runModule(ModuleName = "CreateHouseholds", 
            PackageName = "VESimHouseholds",
            RunFor = "AllYears")
}

