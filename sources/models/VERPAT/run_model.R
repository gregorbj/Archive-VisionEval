#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for a demonstration RPAT Module

#Load libraries
#--------------
library(visioneval)
library(VESyntheticFirms)

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
BaseYear <- getModelState()$BaseYear
for(Year in getYears()) {
  if (Year == BaseYear) {
    runModule(ModuleName = "CreateBaseSyntheticFirms", PackageName = "VESyntheticFirms")
  } else {
    runModule(ModuleName = "CreateFutureSyntheticFirms", PackageName = "VESyntheticFirms")
  }
}

