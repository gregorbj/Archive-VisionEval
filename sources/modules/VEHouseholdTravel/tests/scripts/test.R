#library(rhdf5)
library(filesstrings)
library(visioneval)
library(data.table)

#Load datastore from VEHouseholdVehicles package
file.copy("../VEHouseholdVehicles/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Test CalculateHouseholdDvmt module
source("R/CalculateHouseholdDvmt.R")
testModule(
  ModuleName = "CalculateHouseholdDvmt",
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

#Test DivertSovTravel module
source("R/DivertSovTravel.R")
testModule(
  ModuleName = "DivertSovTravel",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
