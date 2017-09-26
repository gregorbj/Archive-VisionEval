library(rhdf5)
library(filesstrings)

#Load datastore from VESimHouseholds package
file.copy("../VESimHouseholds/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Test PredictHousing module
source("R/PredictHousing.R")
testModule(
  ModuleName = "PredictHousing",
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

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
