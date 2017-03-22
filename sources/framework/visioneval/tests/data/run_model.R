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
for(Year in getYears()) {
    runModule   ( #spaces in from for opening parenthesis for parsing test
      ModuleName = "CreateFutureSyntheticFirms",
      PackageName = "VESyntheticFirms",
      RunFor = "NotBaseYear"
      ) #Comment for parsing test purposes
    runModule   ( #spaces in from for opening parenthesis for parsing test
      "CreateFutureSyntheticFirms",
      PackageName = "VESyntheticFirms",
      RunFor = "NotBaseYear"
    ) #Comment for parsing test purposes
    runModule   (
      "CreateFutureSyntheticFirms", #spaces in from for opening parenthesis for parsing test
      PackageName = "VESyntheticFirms",
      RunFor = "NotBaseYear"
    ) #Comment for parsing test purposes
    runModule   ( #spaces in from for opening parenthesis for parsing test
      ModuleName = "CreateFutureSyntheticFirms",
      PackageName = "VESyntheticFirms",
      RunFor = "NotBaseYear"
    ) #Comment for parsing test purposes

}


