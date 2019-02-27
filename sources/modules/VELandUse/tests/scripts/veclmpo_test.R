#veclmpo_test.R
#-------------

#Load packages and test functions
library(filesstrings)
library(visioneval)
library(fields)
source("tests/scripts/test_functions.R")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-CLMPO",
  DatastoreName = "Datastore.tar",
  LoadDatastore = TRUE,
  TestDocsDir = "veclmpo",
  ClearLogs = TRUE,
  # SaveDatastore = TRUE
  SaveDatastore = FALSE
)

#Define the module tests
Tests_ls <- list(
  list(ModuleName = "PredictHousing", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "LocateEmployment", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignLocTypes", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "Calculate4DMeasures", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "CalculateUrbanMixMeasure", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignParkingRestrictions", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignDemandManagement", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignCarSvcAvailability", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)
