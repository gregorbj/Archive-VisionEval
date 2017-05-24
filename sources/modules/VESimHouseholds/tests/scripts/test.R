#Test CreateHouseholds module
source("R/CreateHouseholds.R")
testModule(
  ModuleName = "CreateHouseholds",
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = FALSE,
  SaveDatastore = TRUE
)

#Test PredictWorkers module
source("R/PredictWorkers.R")
testModule(
  ModuleName = "PredictWorkers",
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE
)

#Test PredictIncome module
source("R/PredictIncome.R")
testModule(
  ModuleName = "PredictIncome",
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE
)

#Test PredictHousing module
source("R/PredictHousing.R")
testModule(
  ModuleName = "PredictHousing",
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE
)
