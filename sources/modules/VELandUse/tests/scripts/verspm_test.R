#verspm_test.R
#-------------

#Load packages and test functions
library(filesstrings)
library(visioneval)
library(fields)
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
  PredictHousing = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  LocateEmployment = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignLocTypes = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  Calculate4DMeasures = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  CalculateUrbanMixMeasure = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignParkingRestrictions = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignDemandManagement = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignCarSvcAvailability = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)

