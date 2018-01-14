library(rhdf5)
library(filesstrings)

#Load datastore from VEHouseholdTravel package
file.copy("../VEHouseholdTravel/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Test CalculateBaseCommercialDvmt module
source("R/CalculateBaseCommercialDvmt.R")
testModule(
  ModuleName = "CalculateBaseCommercialDvmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "BaseYear"
)

#Test CalculateFutureCommercialDvmt module
source("R/CalculateFutureCommercialDvmt.R")
testModule(
  ModuleName = "CalculateFutureCommercialDvmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
