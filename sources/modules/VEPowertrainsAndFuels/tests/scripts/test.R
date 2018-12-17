library(visioneval)
library(data.table)
library(filesstrings)

#Load datastore from VERoadPerformance package
file.copy("../VEHouseholdTravel/tests/Datastore.tar", "tests/Datastore.tar", overwrite = TRUE)
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Load energy and emissions default data
load("data/PowertrainFuelDefaults_ls.rda")

#Test Initialize module
source("R/Initialize.R")
testModule(
  ModuleName = "Initialize",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CalculateCarbonIntensity module
source("R/CalculateCarbonIntensity.R")
testModule(
  ModuleName = "CalculateCarbonIntensity",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignHhVehiclePowertrain module
source("R/AssignHhVehiclePowertrain.R")
testModule(
  ModuleName = "AssignHhVehiclePowertrain",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
