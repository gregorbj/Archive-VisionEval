#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for a demonstration RPAT Module

#Load libraries
#--------------
library(visioneval)

planType <- 'multiprocess'

ptm <- proc.time()

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
    ModuleName = "BuildScenarios",
    PackageName = "VEScenario",
    RunFor = "AllYears",
    RunYear = Year
  )
  runModule(
    ModuleName = "RunScenarios",
    PackageName = "VEScenario",
    RunFor = "AllYears",
    RunYear = Year
  )
  runModule(
    ModuleName = "VERSPMResults",
    PackageName = "VEScenario",
    RunFor = "AllYears",
    RunYear = Year
  )
  runModule(
    ModuleName = "ViewResults",
    PackageName = "VEScenario",
    RunFor = "AllYears",
    RunYear = Year
  )
}

proc.time() - ptm
