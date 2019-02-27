#verpat_test.R
#-------------

library(filesstrings)
library(visioneval)
library(fields)

# Set the working directory to tests folder
file.copy("tests/verpat/Datastore.tar", "tests/Datastore.tar")
file.copy("tests/verpat/inputs", "tests", recursive = TRUE)
file.copy("tests/verpat/defs", "tests", recursive = TRUE)
file.copy("tests/verpat/ModelState.Rda", "tests/ModelState.Rda")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Test CalculateBasePlaceTypes module
source("R/CalculateBasePlaceTypes.R")
testModule(
  ModuleName = "CalculateBasePlaceTypes",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "BaseYear"
)

#Test CalculateFuturePlaceTypes module
source("R/CalculateFuturePlaceTypes.R")
testModule(
  ModuleName = "CalculateFuturePlaceTypes",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Finish up
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
LogFiles_ <- local({
  Files_ <- dir()
  Files_[grep("Log_", Files_)]
})
file.copy(LogFiles_, file.path("verpat", LogFiles_))
file.remove(LogFiles_)
setwd("..")

