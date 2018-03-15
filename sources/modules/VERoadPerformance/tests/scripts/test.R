library(visioneval)
library(filesstrings)

#Load datastore from VEHouseholdTravel package
file.copy("../VEHouseholdTravel/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Load default data used in calculating road DVMT
source("R/LoadDefaultRoadDvmtValues.R")
ModelFiles_ <-
  c("data/RoadDvmtModel_ls.rda", "data/Access_df.rda", "data/BaseSpeeds_df.Rda",
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

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
