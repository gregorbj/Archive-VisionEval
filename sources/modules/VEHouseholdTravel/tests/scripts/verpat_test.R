#verpat_test.R
#-------------
library(filesstrings)
library(visioneval)

#Define function to copy files
#-----------------------------
copyFiles <- function(Files_) {
  From_ <- file.path("tests/verpat", Files_)
  To_ <- file.path("tests", Files_)
  file.copy(From_, To_)
}

#Test the CalculateTravelDemand module
#-------------------------------------
# Set up test directory
copyFiles(c(
  "Datastore_CalculateTravelDemand.tar",
  "defs_CalculateTravelDemand.tar",
  "ModelState_CalculateTravelDemand.zip",
  "inputs_CalculateTravelDemand.tar"))
setwd("tests")
untar("Datastore_CalculateTravelDemand.tar")
untar("defs_CalculateTravelDemand.tar")
unzip("ModelState_CalculateTravelDemand.zip")
untar("inputs_CalculateTravelDemand.tar")
file.remove(c(
  "Datastore_CalculateTravelDemand.tar",
  "defs_CalculateTravelDemand.tar",
  "ModelState_CalculateTravelDemand.zip",
  "inputs_CalculateTravelDemand.tar"))
setwd("..")
#Run default data generation for CalculateTravelDemand Module
source("R/LoadDefaultValues.R")
#Test Initialize module
source("R/Initialize.R")
testModule(
  ModuleName = "Initialize",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
#Test CalculateTravelDemand module
source("R/CalculateTravelDemand.R")
testModule(
  ModuleName = "CalculateTravelDemand",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
#Move log files and clean up
setwd("tests")
file.copy("Log_Initialize.txt", "verpat/Log_Initialize.txt", overwrite = TRUE)
file.copy("Log_CalculateTravelDemand.txt", "verpat/Log_CalculateTravelDemand.txt", overwrite = TRUE)
file.remove("Log_Initialize.txt", "Log_CalculateTravelDemand.txt")
dir.remove("Datastore")
dir.remove("defs")
file.remove("ModelState.Rda")
setwd("..")

#Test the CalculateTravelDemandFuture module
#-------------------------------------------
# Set up test directory
copyFiles(c(
  "Datastore_CalculateTravelDemandFuture.tar",
  "defs_CalculateTravelDemandFuture.tar",
  "ModelState_CalculateTravelDemandFuture.zip"))
setwd("tests")
untar("Datastore_CalculateTravelDemandFuture.tar")
untar("defs_CalculateTravelDemandFuture.tar")
unzip("ModelState_CalculateTravelDemandFuture.zip")
file.remove(c(
  "Datastore_CalculateTravelDemandFuture.tar",
  "defs_CalculateTravelDemandFuture.tar",
  "ModelState_CalculateTravelDemandFuture.zip"))
setwd("..")
#Test CalculateTravelDemandFuture module
source("R/CalculateTravelDemandFuture.R")
testModule(
  ModuleName = "CalculateTravelDemandFuture",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
#Move log files and clean up
setwd("tests")
file.copy("Log_CalculateTravelDemandFuture.txt", "verpat/Log_CalculateTravelDemandFuture.txt", overwrite = TRUE)
file.remove("Log_CalculateTravelDemandFuture.txt")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
setwd("..")

#Test the CalculateInducedDemand module
#--------------------------------------
# Set up test directory
copyFiles(c(
  "Datastore_CalculateInducedDemand.tar",
  "defs_CalculateInducedDemand.tar",
  "ModelState_CalculateInducedDemand.zip",
  "inputs_CalculateInducedDemand.tar"))
setwd("tests")
untar("Datastore_CalculateInducedDemand.tar")
untar("defs_CalculateInducedDemand.tar")
unzip("ModelState_CalculateInducedDemand.zip")
untar("inputs_CalculateInducedDemand.tar")
file.remove(c(
  "Datastore_CalculateInducedDemand.tar",
  "defs_CalculateInducedDemand.tar",
  "ModelState_CalculateInducedDemand.zip",
  "inputs_CalculateInducedDemand.tar"))
setwd("..")
#Test CalculateInducedDemand module
source("R/CalculateInducedDemand.R")
testModule(
  ModuleName = "CalculateInducedDemand",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
#Move log files and clean up
setwd("tests")
file.copy("Log_CalculateInducedDemand.txt", "verpat/Log_CalculateInducedDemand.txt", overwrite = TRUE)
file.remove("Log_CalculateInducedDemand.txt")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
setwd("..")

#Test the CalculatePolicyVmt module
#----------------------------------
# Set up test directory
copyFiles(c(
  "Datastore_CalculatePolicyVmt.tar",
  "defs_CalculatePolicyVmt.tar",
  "inputs_CalculatePolicyVmt.tar",
  "ModelState_CalculatePolicyVmt.zip"))
setwd("tests")
untar("Datastore_CalculatePolicyVmt.tar")
untar("defs_CalculatePolicyVmt.tar")
untar("inputs_CalculatePolicyVmt.tar")
unzip("ModelState_CalculatePolicyVmt.zip")
file.remove(c(
  "Datastore_CalculatePolicyVmt.tar",
  "defs_CalculatePolicyVmt.tar",
  "inputs_CalculatePolicyVmt.tar",
  "ModelState_CalculatePolicyVmt.zip"))
setwd("..")
#Test CalculatePolicyVmt module
source("R/CalculatePolicyVmt.R")
testModule(
  ModuleName = "CalculatePolicyVmt",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
#Move log files and clean up
setwd("tests")
file.copy("Log_CalculatePolicyVmt.txt", "verpat/Log_CalculatePolicyVmt.txt", overwrite = TRUE)
file.remove("Log_CalculatePolicyVmt.txt")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
setwd("..")
