library(visioneval)
library(filesstrings)

#Test the CreateBaseAccessibility module
#---------------------------------------
# Organize tests folder for testing the CreateBaseAccessibility module
file.copy("tests/verpat/Datastore_CreateBaseAccessibility.tar", "tests/Datastore_CreateBaseAccessibility.tar")
file.copy("tests/verpat/defs_CreateBaseAccessibility.tar", "tests/defs_CreateBaseAccessibility.tar")
file.copy("tests/verpat/ModelState_CreateBaseAccessibility.zip", "tests/ModelState_CreateBaseAccessibility.zip")
file.copy("tests/verpat/inputs_CreateBaseAccessibility.tar", "tests/inputs_CreateBaseAccessibility.tar")
setwd("tests")
untar("Datastore_CreateBaseAccessibility.tar")
untar("defs_CreateBaseAccessibility.tar")
unzip("ModelState_CreateBaseAccessibility.zip")
untar("inputs_CreateBaseAccessibility.tar")
file.remove(c(
  "Datastore_CreateBaseAccessibility.tar",
  "defs_CreateBaseAccessibility.tar",
  "ModelState_CreateBaseAccessibility.zip",
  "inputs_CreateBaseAccessibility.tar"))
setwd("..")
# Test CreateBaseAccessibility module
source("R/CreateBaseAccessibility.R")
testModule(
  ModuleName = "CreateBaseAccessibility",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
# Move the Log_CreateBaseAccessibility.txt file
setwd("tests")
file.copy("Log_CreateBaseAccessibility.txt", "verpat/Log_CreateBaseAccessibility.txt", overwrite = TRUE)
file.remove("Log_CreateBaseAccessibility.txt")
setwd("..")

#Test the CreateFutureAccessibility module
#-----------------------------------------
# Reorganize folder for next VERPAT module test
file.copy("tests/verpat/Datastore_CreateFutureAccessibility.tar", "tests/Datastore_CreateFutureAccessibility.tar")
file.copy("tests/verpat/defs_CreateFutureAccessibility.tar", "tests/defs_CreateFutureAccessibility.tar")
file.copy("tests/verpat/ModelState_CreateFutureAccessibility.zip", "tests/ModelState_CreateFutureAccessibility.zip")
setwd("tests")
dir.remove("defs")
dir.remove("Datastore")
file.remove("ModelState.Rda")
untar("Datastore_CreateFutureAccessibility.tar")
untar("defs_CreateFutureAccessibility.tar")
unzip("ModelState_CreateFutureAccessibility.zip")
file.remove(c(
  "Datastore_CreateFutureAccessibility.tar",
  "defs_CreateFutureAccessibility.tar",
  "ModelState_CreateFutureAccessibility.zip"))
setwd("..")
# Test CreateFutureAccessibility module
source("R/CreateFutureAccessibility.R")
testModule(
  ModuleName = "CreateFutureAccessibility",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
# Move the Log_CreateFutureAccessibility.txt file
setwd("tests")
file.copy("Log_CreateFutureAccessibility.txt", "verpat/Log_CreateFutureAccessibility.txt", overwrite = TRUE)
file.remove("Log_CreateFutureAccessibility.txt")
setwd("..")


#Clean up the tests directory
#----------------------------
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
setwd("..")
