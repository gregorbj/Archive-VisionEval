#verspm_test.R
#-------------

#Load libraries and test functions
library(visioneval)
library(filesstrings)
source("tests/scripts/test_functions.R")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-RSPM",
  DatastoreName = "Datastore.tar",
  LoadDatastore = TRUE,
  TestDocsDir = "verspm",
  ClearLogs = TRUE,
  # SaveDatastore = TRUE
  SaveDatastore = FALSE
)

#Define the module tests
Tests_ls <- list(
  list(ModuleName = "Initialize",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "CalculateRoadDvmt",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RunFor = "BaseYear"),
  list(ModuleName = "CalculateRoadDvmt",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RunFor = "NotBaseYear"),
  list(ModuleName = "CalculateRoadPerformance",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RunFor = "BaseYear"),
  list(ModuleName = "CalculateRoadPerformance",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RunFor = "NotBaseYear"),
  list(ModuleName = "CalculateMpgMpkwhAdjustments",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RequiredPackages = "VEPowertrainsAndFuels"),
  list(ModuleName = "AdjustHhVehicleMpgMpkwh",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RequiredPackages = c("VEHouseholdTravel", "VEPowertrainsAndFuels")),
  list(ModuleName = "CalculateVehicleOperatingCost",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "BudgetHouseholdDvmt",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RequiredPackages = "VEHouseholdTravel"),
  list(ModuleName = "BalanceRoadCostsAndRevenues",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "CalculateComEnergyAndEmissions",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RequiredPackages = "VEPowertrainsAndFuels"),
  list(ModuleName = "CalculatePtranEnergyAndEmissions",
       LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE,
       RequiredPackages = "VEPowertrainsAndFuels")
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)



