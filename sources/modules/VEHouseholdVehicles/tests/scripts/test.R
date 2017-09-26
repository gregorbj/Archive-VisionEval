library(rhdf5)
library(filesstrings)

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

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
