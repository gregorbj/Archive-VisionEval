#library(rhdf5)
library(filesstrings)
library(visioneval)
library(data.table)
library(pscl)

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

#Test CalculateVehicleTrips module
source("R/CalculateVehicleTrips.R")
testModule(
  ModuleName = "CalculateVehicleTrips",
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

#Test ApplyDvmtReductions module
source("R/ApplyDvmtReductions.R")
testModule(
  ModuleName = "ApplyDvmtReductions",
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
untar("Datastore_CalculateTravelDemand.tar")
untar("defs_CalculateTravelDemand.tar")
unzip("ModelState_CalculateTravelDemand.zip")
untar("inputs_CalculateTravelDemand.tar")
setwd("..")

#Test CalculateTravelDemand module
source("R/CalculateTravelDemand.R")
testModule(
  ModuleName = "CalculateTravelDemand",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

# Reorganize folder for next VERPAT module test
setwd("tests")
dir.remove("Datastore")
file.remove("ModelState.Rda")
dir.remove("defs")
untar("Datastore_CalculateTravelDemandFuture.tar")
untar("defs_CalculateTravelDemandFuture.tar")
unzip("ModelState_CalculateTravelDemandFuture.zip")
setwd("..")

#Test CalculateTravelDemandFuture module
source("R/CalculateTravelDemandFuture.R")
testModule(
  ModuleName = "CalculateTravelDemandFuture",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

# Reorganize folder for next VERPAT module test
setwd("tests")
dir.remove("Datastore")
file.remove("ModelState.Rda")
dir.remove("defs")
dir.remove("inputs")
untar("Datastore_CalculateInducedDemand.tar")
untar("defs_CalculateInducedDemand.tar")
unzip("ModelState_CalculateInducedDemand.zip")
untar("inputs_CalculateInducedDemand.tar")
setwd("..")

#Test CalculateInducedDemand module
source("R/CalculateInducedDemand.R")
testModule(
  ModuleName = "CalculateInducedDemand",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

# Reorganize folder for next VERPAT module test
setwd("tests")
dir.remove("Datastore")
file.remove("ModelState.Rda")
dir.remove("defs")
dir.remove("inputs")
untar("Datastore_CalculatePolicyVmt.tar")
untar("defs_CalculatePolicyVmt.tar")
untar("inputs_CalculatePolicyVmt.tar")
unzip("ModelState_CalculatePolicyVmt.zip")
setwd("..")

#Test CalculatePolicyVmt module
source("R/CalculatePolicyVmt.R")
testModule(
  ModuleName = "CalculatePolicyVmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Finish up
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
unzip("ModelState.zip")
file.remove("ModelState.zip")
untar("defs.tar")
file.remove("defs.tar")
untar("inputs.tar")
file.remove("inputs.tar")
setwd("..")
