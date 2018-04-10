library(filesstrings)
library(visioneval)
library(fields)

##################################################
## Section 1. Tests for modules used in VERSPM
##################################################

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

#Test AssignParkingRestrictions module
source("R/AssignParkingRestrictions.R")
testModule(
  ModuleName = "AssignParkingRestrictions",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignDemandManagement module
source("R/AssignDemandManagement.R")
testModule(
  ModuleName = "AssignDemandManagement",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")

##################################################
## Section 2. Tests for modules used in VERPAT
##################################################

# Set the working directory to tests folder and load the output from
# previous module runs
setwd("tests")
# Copy and save the results from previous module tests
zip("ModelState.zip","ModelState.Rda")
file.remove("ModelState.Rda")
tar("defs.tar","defs")
dir.remove("defs")
untar("Datastore_VERPAT.tar")
unzip("ModelState_VERPAT.zip")
setwd("..")

#Test CalculateBasePlaceTypes module
source("R/CalculateBasePlaceTypes.R")
testModule(
  ModuleName = "CalculateBasePlaceTypes",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "BaseYear"
)

#Test CalculateFuturePlaceTypes module
source("R/CalculateFuturePlaceTypes.R")
testModule(
  ModuleName = "CalculateFuturePlaceTypes",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Finish up
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
file.remove("ModelState.Rda")
unzip("ModelState.zip")
file.remove("ModelState.zip")
untar("defs.tar")
file.remove("defs.tar")
setwd("..")

