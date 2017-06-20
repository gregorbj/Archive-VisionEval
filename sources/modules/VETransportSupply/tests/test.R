#Test AssignTransitService module
#source("R/AssignTransitService.R")
library(visioneval)

TestDir <- normalizePath(".")
if (!endsWith(TestDir, 'tests'))
  TestDir <- file.path(TestDir, 'tests')

testModule(
  ModuleName = "VETransportSupply::AssignTransitService",
  ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignRoadMiles module
#source("R/AssignRoadMiles.R")
testModule(
  ModuleName = "VETransportSupply::AssignRoadMiles",
  ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
