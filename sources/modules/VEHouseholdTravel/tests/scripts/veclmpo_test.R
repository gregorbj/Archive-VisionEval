#verspm_test.R
#-------------

library(filesstrings)
library(visioneval)
library(data.table)
library(pscl)
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
  list(ModuleName = "CalculateHouseholdDvmt",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "CalculateAltModeTrips",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "CalculateVehicleTrips",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "DivertSovTravel",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "ApplyDvmtReductions",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)
