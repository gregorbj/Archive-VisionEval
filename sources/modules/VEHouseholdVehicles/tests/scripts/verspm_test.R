#verspm_test.R
#-------------

#Load packages and test functions
library(filesstrings)
library(visioneval)
library(ordinal)
source("tests/scripts/test_functions.R")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-RSPM",
  DatastoreName = "Datastore.tar",
  LoadDatastore = TRUE,
  TestDocsDir = "verspm",
  ClearLogs = TRUE
)

#Define the module tests
Tests_ls <- list(
  AssignDrivers = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignVehicleOwnership = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignVehicleType = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  CreateVehicleTable = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignVehicleAge = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  CalculateVehicleOwnCost = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AdjustVehicleOwnership = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)

