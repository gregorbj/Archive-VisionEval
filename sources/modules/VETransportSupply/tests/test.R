#Test AssignTransitService module
#source("R/AssignTransitService.R")
library(visioneval)

ProjectDir <- normalizePath("./tests")

testModule(
  ModuleName = "VETransportSupply::AssignTransitService",
  ProjectDir = ProjectDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignRoadMiles module
#source("R/AssignRoadMiles.R")
testModule(
  ModuleName = "VETransportSupply::AssignRoadMiles",
  ProjectDir = ProjectDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
