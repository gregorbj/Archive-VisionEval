#vestate_test.R
#--------------

#Load resources
source("tests/scripts/test_functions.R")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-State",
  DatastoreName = "Datastore.tar",
  LoadDatastore = TRUE,
  TestDocsDir = "vestate",
  ClearLogs = TRUE
)

#Define the module tests
Tests_ls <- list(
  CreateHouseholds = c(LoadDatastore = FALSE, SaveDatastore = TRUE, DoRun = TRUE),
  PredictWorkers = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  AssignLifeCycle = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  PredictIncome = c(LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)
