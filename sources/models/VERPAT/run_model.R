#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for a demonstration RPAT
#Module

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

#Run all demo module for all years
#---------------------------------
BaseYear <- getModelState()$BaseYear
for(Year in getYears()) {
  if (Year == BaseYear) {
    runModule(ModuleName = "CreateBaseSyntheticFirms", PackageName = "VisionEvalSyntheticFirms")
  } else {
    runModule(ModuleName = "CreateFutureSyntheticFirms", PackageName = "VisionEvalSyntheticFirms")
  }
}

