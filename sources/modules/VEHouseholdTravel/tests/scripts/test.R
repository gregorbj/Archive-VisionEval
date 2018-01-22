#library(rhdf5)
library(filesstrings)
library(visioneval)
library(data.table)

##################################################
## Section 1. Tests for modules used in VERSPM
##################################################

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

##################################################
## Section 2. Tests for modules used in VERPAT
##################################################

# Set the working directory to tests folder and load the output from
# previous module runs
setwd("tests")
# Copy and save the results from previous module tests
zip("ModelState.zip","ModelState.Rda")
file.remove("ModelState.Rda")
tar("defs.tar","defs")
tar("inputs.tar","inputs")
dir.remove("defs")
dir.remove("inputs")
untar("Datastore_VERPAT.tar")
unzip("ModelState_VERPAT.zip")
untar("inputs_VERPAT.tar")
setwd("..")

#Test CalculateTravelDemand module
source("R/CalculateTravelDemand.R")
testModule(
  ModuleName = "CalculateTravelDemand",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)


#Finish up
setwd("tests")
# tar("Datastore_VERPAT.tar", c("Datastore", "defs"))
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
# zip("ModelState_VERPAT.zip","ModelState.Rda")
file.remove("ModelState.Rda")
unzip("ModelState.zip")
file.remove("ModelState.zip")
untar("defs.tar")
file.remove("defs.tar")
untar("inputs.tar")
file.remove("inputs.tar")
setwd("..")
