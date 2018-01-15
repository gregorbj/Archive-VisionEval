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
  runModule("CreateHouseholds", "VESimHouseholds", 
                RunFor = "AllYears", RunYear = Year)
  runModule("PredictWorkers", "VESimHouseholds", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignLifeCycle", "VESimHouseholds", 
                RunFor = "AllYears", RunYear = Year)
  runModule("PredictIncome", "VESimHouseholds", 
                RunFor = "AllYears", RunYear = Year)
  runModule("PredictHousing", "VELandUse", 
                RunFor = "AllYears", RunYear = Year)
  runModule("LocateEmployment", "VELandUse", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignDevTypes", "VELandUse", 
                RunFor = "AllYears", RunYear = Year)
  runModule("Calculate4DMeasures", "VELandUse", 
                RunFor = "AllYears", RunYear = Year)
  runModule("CalculateUrbanMixMeasure", "VELandUse", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignTransitService", "VETransportSupply", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignRoadMiles", "VETransportSupply", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignVehicleOwnership", "VEHouseholdVehicles", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignVehicleType", "VEHouseholdVehicles", 
                RunFor = "AllYears", RunYear = Year)
  runModule("CreateVehicleTable", "VEHouseholdVehicles", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignVehicleAge", "VEHouseholdVehicles", 
                RunFor = "AllYears", RunYear = Year)
  runModule("CalculateHouseholdDvmt", "VEHouseholdTravel", 
                RunFor = "AllYears", RunYear = Year)
  runModule("CalculateAltModeTrips", "VEHouseholdTravel", 
                RunFor = "AllYears", RunYear = Year)
  runModule("DivertSovTravel", "VEHouseholdTravel", 
                RunFor = "AllYears", RunYear = Year)
  runModule("CalculateBaseCommercialDvmt", "VECommercialTravel", 
                RunFor = "BaseYear", RunYear = Year)
  runModule("CalculateFutureCommercialDvmt", "VECommercialTravel", 
                RunFor = "NotBaseYear", RunYear = Year)
  runModule("AssignHhVehiclePowertrain", "VEEnergyAndEmissions", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignHhVehicleDvmtSplit", "VEEnergyAndEmissions", 
                RunFor = "AllYears", RunYear = Year)
  runModule("AssignHhVehicleDvmt", "VEEnergyAndEmissions", 
                RunFor = "AllYears", RunYear = Year)
}
