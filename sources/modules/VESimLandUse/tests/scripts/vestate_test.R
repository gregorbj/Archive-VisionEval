#vestate_test.R
#--------------

#Load packages and test functions
library(filesstrings)
library(visioneval)
source("tests/scripts/test_functions.R")

load("data/SimBzone_ls.rda")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-State",
  DatastoreName = "Datastore.tar",
  LoadDatastore = TRUE,
  TestDocsDir = "vestate",
  ClearLogs = TRUE,
  # SaveDatastore = TRUE
  SaveDatastore = FALSE
)

#Define the module tests
Tests_ls <- list(
  list(ModuleName = "Initialize",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "CreateSimBzones",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "SimulateHousing",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "SimulateEmployment",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "Simulate4DMeasures",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "SimulateUrbanMixMeasure",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignParkingRestrictions",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignCarSvcAvailability",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignDemandManagement",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)


