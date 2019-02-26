#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for the RSPM model.
cat('run_model.R: script entered\n')
#Load libraries
#--------------
library(visioneval)
#devtools::load_all('C:/Users/matt.landis/Git/VisionEval/sources/framework/visioneval/')
cat('run_model.R: library visioneval loaded\n')

planType <- 'multiprocess'

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
cat('run_model.R: initializeModel completed\n')
#Run all demo module for all years
#---------------------------------
for(Year in getYears()) {
  runModule("CreateHouseholds",                "VESimHouseholds",       RunFor = "AllYears",    RunYear = Year)
  runModule("PredictWorkers",                  "VESimHouseholds",       RunFor = "AllYears",    RunYear = Year)
  runModule("AssignLifeCycle",                 "VESimHouseholds",       RunFor = "AllYears",    RunYear = Year)
  runModule("PredictIncome",                   "VESimHouseholds",       RunFor = "AllYears",    RunYear = Year)
  runModule("PredictHousing",                  "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("LocateEmployment",                "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("AssignLocTypes",                  "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("Calculate4DMeasures",             "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("CalculateUrbanMixMeasure",        "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("AssignParkingRestrictions",       "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("AssignDemandManagement",          "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("AssignCarSvcAvailability",        "VELandUse",             RunFor = "AllYears",    RunYear = Year)
  runModule("AssignTransitService",            "VETransportSupply",     RunFor = "AllYears",    RunYear = Year)
  runModule("AssignRoadMiles",                 "VETransportSupply",     RunFor = "AllYears",    RunYear = Year)
  runModule("AssignDrivers",                   "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("AssignVehicleOwnership",          "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("AssignVehicleType",               "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("CreateVehicleTable",              "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("AssignVehicleAge",                "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("CalculateVehicleOwnCost",         "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("AdjustVehicleOwnership",          "VEHouseholdVehicles",   RunFor = "AllYears",    RunYear = Year)
  runModule("CalculateHouseholdDvmt",          "VEHouseholdTravel",     RunFor = "AllYears",    RunYear = Year)
  runModule("CalculateAltModeTrips",           "VEHouseholdTravel",     RunFor = "AllYears",    RunYear = Year)
  runModule("CalculateVehicleTrips",           "VEHouseholdTravel",     RunFor = "AllYears",    RunYear = Year)
  runModule("DivertSovTravel",                 "VEHouseholdTravel",     RunFor = "AllYears",    RunYear = Year)
  runModule("CalculateCarbonIntensity",        "VEPowertrainsAndFuels", RunFor = "AllYears",    RunYear = Year)
  runModule("AssignHhVehiclePowertrain",       "VEPowertrainsAndFuels", RunFor = "AllYears",    RunYear = Year)
  for (i in 1:2) {
    runModule("CalculateBaseRoadDvmt",            "VETravelPerformance",   RunFor = "BaseYear",    RunYear = Year)
    runModule("CalculateFutureRoadDvmt",          "VETravelPerformance",   RunFor = "NotBaseYear", RunYear = Year)
    runModule("CalculateRoadPerformance",         "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
    runModule("CalculateMpgMpkwhAdjustments",     "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
    runModule("AdjustHhVehicleMpgMpkwh",          "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
    runModule("CalculateVehicleOperatingCost",    "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
    runModule("BudgetHouseholdDvmt",              "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
  }
  runModule("CalculateComEnergyAndEmissions",   "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
  runModule("CalculatePtranEnergyAndEmissions", "VETravelPerformance",   RunFor = "AllYears",    RunYear = Year)
}
