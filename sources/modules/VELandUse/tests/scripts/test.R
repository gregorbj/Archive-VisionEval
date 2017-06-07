#Test CreateHouseholds module
source("R/CreateHouseholds.R")
testModule(
  ModuleName = "CreateHouseholds",
  LoadDatastore = FALSE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictWorkers module
source("R/PredictWorkers.R")
testModule(
  ModuleName = "PredictWorkers",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignLifeCycle module
source("R/AssignLifeCycle.R")
testModule(
  ModuleName = "AssignLifeCycle",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictIncome module
source("R/PredictIncome.R")
testModule(
  ModuleName = "PredictIncome",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test PredictHousing module
source("R/PredictHousing.R")
testModule(
  ModuleName = "PredictHousing",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
