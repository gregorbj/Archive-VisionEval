#library(rhdf5)
library(filesstrings)
library(visioneval)
library(ordinal)

##################################################
## Section 1. Tests for modules used in VERSPM
##################################################

#Load datastore from VETransportSupply package
file.copy("../VETransportSupply/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Test AssignVehicleOwnership module
source("R/AssignVehicleOwnership.R")
testModule(
  ModuleName = "AssignVehicleOwnership",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignVehicleType module
source("R/AssignVehicleType.R")
testModule(
  ModuleName = "AssignVehicleType",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CreateVehicleTable module
source("R/CreateVehicleTable.R")
testModule(
  ModuleName = "CreateVehicleTable",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignVehicleAge module
source("R/AssignVehicleAge.R")
testModule(
  ModuleName = "AssignVehicleAge",
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
untar("Datastore_AssignVehicleFeatures.tar")
untar("defs_AssignVehicleFeatures.tar")
unzip("ModelState_AssignVehicleFeatures.zip")
untar("inputs_AssignVehicleFeatures.tar")
setwd("..")

#Test CreateBaseAccessibility module
source("R/AssignVehicleFeatures.R")
testModule(
  ModuleName = "AssignVehicleFeatures",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

# Reorganize folder for next VERPAT module test
setwd("tests")
file.remove("ModelState.Rda")
dir.remove("Datastore")
dir.remove("defs")
untar("Datastore_AssignVehicleFeaturesFuture.tar")
untar("defs_AssignVehicleFeaturesFuture.tar")
unzip("ModelState_AssignVehicleFeaturesFuture.zip")
setwd("..")

#Test CreateBaseAccessibility module
source("R/AssignVehicleFeaturesFuture.R")
testModule(
  ModuleName = "AssignVehicleFeaturesFuture",
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

