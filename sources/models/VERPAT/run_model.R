#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for a demonstration RPAT Module

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
  runModule(
    ModuleName = "CreateHouseholds",
    PackageName = "VESimHouseholds",
    RunFor = "BaseYear",
    RunYear = Year
  )
  runModule(
    ModuleName = "PredictWorkers",
    PackageName = "VESimHouseholds",
    RunFor = "BaseYear",
    RunYear = Year
  )
  runModule(
    ModuleName = "PredictIncome",
    PackageName = "VESimHouseholds",
    RunFor = "BaseYear",
    RunYear = Year
  )
  runModule(
    ModuleName = "CreateHouseholds",
    PackageName = "VESimHouseholds",
    RunFor = "NotBaseYear",
    RunYear = Year
  )
  runModule(
    ModuleName = "PredictWorkers",
    PackageName = "VESimHouseholds",
    RunFor = "NotBaseYear",
    RunYear = Year
  )
  runModule(
    ModuleName = "PredictIncome",
    PackageName = "VESimHouseholds",
    RunFor = "NotBaseYear",
    RunYear = Year
  )
   runModule(
    ModuleName = "CreateBaseSyntheticFirms",
    PackageName = "VESyntheticFirms",
    RunFor = "BaseYear",
    RunYear = Year)
  runModule(
    ModuleName = "CreateFutureSyntheticFirms",
    PackageName = "VESyntheticFirms",
    RunFor = "NotBaseYear",
    RunYear = Year)
  runModule(
    ModuleName = "CalculateBasePlaceTypes",
    PackageName = "VELandUse",
    RunFor = "BaseYear",
    RunYear = Year)
  runModule(
    ModuleName = "CalculateFuturePlaceTypes",
    PackageName = "VELandUse",
    RunFor = "NotBaseYear",
    RunYear = Year)
}
