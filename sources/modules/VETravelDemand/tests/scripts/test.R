library(visioneval)

#Test CalculateHouseholdDVMT module
source("R/CalculateHouseholdDVMT.R")
testModule(
  ModuleName = "CalculateHouseholdDVMT",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CalculateAltModeTrips module
source("R/CalculateAltModeTrips.R")
testModule(
  ModuleName = "CalculateAltModeTrips",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
