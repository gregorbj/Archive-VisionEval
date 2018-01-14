#library(rhdf5)
library(filesstrings)
library(visioneval)
library(ordinal)

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
