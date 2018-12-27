library(visioneval)
library(filesstrings)

#Load datastore from VEHouseholdTravel package
file.copy("../VEPowertrainsAndFuels/tests/Datastore.tar", "tests/Datastore.tar", overwrite = TRUE)
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Load default data used in calculating road DVMT
source("R/LoadDefaultRoadDvmtValues.R")
ModelFiles_ <-
  c("data/RoadDvmtModel_ls.rda", "data/Access_df.rda", "data/BaseSpeeds_df.rda",
    "data/Delay_df.rda", "data/Incident_df.rda", "data/Ramp_df.rda",
    "data/Signal_df.rda")
for (File in ModelFiles_) {
  load(File)
}

#Test Initialize module
source("R/Initialize.R")
testModule(
  ModuleName = "Initialize",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CalculateBaseRoadDvmt module
source("R/CalculateBaseRoadDvmt.R")
TestDat_ <- testModule(
  ModuleName = "CalculateBaseRoadDvmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "BaseYear"
)

#Test CalculateFutureRoadDvmt module
source("R/CalculateFutureRoadDvmt.R")
TestDat_ <- testModule(
  ModuleName = "CalculateFutureRoadDvmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Test CalculateRoadPerformance module
source("R/CalculateRoadPerformance.R")
TestDat_ <- testModule(
  ModuleName = "CalculateRoadPerformance",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "AllYears"
)

#Test CalculateMpgMpkwhAdjustments module
source("R/CalculateMpgMpkwhAdjustments.R")
TestDat_ <- testModule(
  ModuleName = "CalculateMpgMpkwhAdjustments",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "AllYears"
)

#Test AdjustHhVehicleMpgMpkwh module
source("R/AdjustHhVehicleMpgMpkwh.R")
TestDat_ <- testModule(
  ModuleName = "AdjustHhVehicleMpgMpkwh",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "AllYears"
)

#Test CalculateVehicleOperatingCost module
source("R/CalculateVehicleOperatingCost.R")
testModule(
  ModuleName = "CalculateVehicleOperatingCost",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test BudgetHouseholdDvmt module
source("R/BudgetHouseholdDvmt.R")
testModule(
  ModuleName = "BudgetHouseholdDvmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CalculateComEnergyAndEmissions module
source("R/CalculateComEnergyAndEmissions.R")
testModule(
  ModuleName = "CalculateComEnergyAndEmissions",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test CalculatePtranEnergyAndEmissions module
source("R/CalculatePtranEnergyAndEmissions.R")
testModule(
  ModuleName = "CalculatePtranEnergyAndEmissions",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
