library(rhdf5)

#Test AssignTransitService module
source("R/AssignTransitService.R")
testModule(
  ModuleName = "AssignTransitService",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignRoadMiles module
source("R/AssignRoadMiles.R")
testModule(
  ModuleName = "AssignRoadMiles",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
