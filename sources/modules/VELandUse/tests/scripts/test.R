#Test LocateHouseholds module
source("R/LocateHouseholds.R")
testModule(
  ModuleName = "LocateHouseholds",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test LocateEmployment module
source("R/LocateEmployment.R")
testModule(
  ModuleName = "LocateEmployment",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignDevTypes module
source("R/AssignDevTypes.R")
testModule(
  ModuleName = "AssignDevTypes",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test Calculate4DMeasures module
source("R/Calculate4DMeasures.R")
testModule(
  ModuleName = "Calculate4DMeasures",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CalculateUrbanMixMeasure module
source("R/CalculateUrbanMixMeasure.R")
testModule(
  ModuleName = "CalculateUrbanMixMeasure",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)
