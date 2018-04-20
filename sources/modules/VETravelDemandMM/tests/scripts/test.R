#Test VETravelDemandMM module
library(visioneval)
library(VETravelDemandMM)

TestDir <- normalizePath(".")
if (!endsWith(TestDir, 'tests'))
  TestDir <- file.path(TestDir, 'tests')

#Test PredictVehicles module
testModule(
  ModuleName = "PredictVehicles",
  #ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictDrivers module
testModule(
  ModuleName = "PredictDrivers",
  #ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictAADVMT module
testModule(
  ModuleName = "PredictAADVMT",
  #ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictBikePMT module
testModule(
  ModuleName = "PredictBikePMT",
  #ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictWalkPMT module
testModule(
  ModuleName = "PredictWalkPMT",
  #ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictTransitPMT module
testModule(
  ModuleName = "PredictTransitPMT",
  #ProjectDir = TestDir,
  ParamDir = "defs",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
