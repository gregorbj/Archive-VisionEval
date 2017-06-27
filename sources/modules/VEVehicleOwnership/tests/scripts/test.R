#Test AssignVehicleOwnership module
source("R/AssignVehicleOwnership.R")
testModule(
  ModuleName = "AssignVehicleOwnership",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

