library(visioneval)
library(data.table)
library(filesstrings)

#Load datastore from VECommercialTravel package
file.copy("../VECommercialTravel/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Load energy and emissions default data
load("data/EnergyEmissionsDefaults_ls.rda")

#Test Initialize module
source("R/Initialize.R")
testModule(
  ModuleName = "Initialize",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = FALSE
)

#Test AssignHhVehiclePowertrain module
source("R/AssignHhVehiclePowertrain.R")
testModule(
  ModuleName = "AssignHhVehiclePowertrain",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignHhVehicleDvmtSplit module
source("R/AssignHhVehicleDvmtSplit.R")
testModule(
  ModuleName = "AssignHhVehicleDvmtSplit",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignHhVehicleDvmt module
source("R/AssignHhVehicleDvmt.R")
testModule(
  ModuleName = "AssignHhVehicleDvmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
