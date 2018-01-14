library(rhdf5)
library(filesstrings)

#Load datastore from VEHouseholdVehicles package
file.copy("../VEHouseholdVehicles/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

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

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
