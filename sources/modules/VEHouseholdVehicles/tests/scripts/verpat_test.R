#verpat_test.R
#-------------

#Test AssignVehicleFeatures module
#---------------------------------
# Organize tests folder for testing the AssignVehicleFeatures module
file.copy("tests/verpat/Datastore_AssignVehicleFeatures.tar", "tests/Datastore_AssignVehicleFeatures.tar")
file.copy("tests/verpat/defs_AssignVehicleFeatures.tar", "tests/defs_AssignVehicleFeatures.tar")
file.copy("tests/verpat/ModelState_AssignVehicleFeatures.zip", "tests/ModelState_AssignVehicleFeatures.zip")
file.copy("tests/verpat/inputs_AssignVehicleFeatures.tar", "tests/inputs_AssignVehicleFeatures.tar")
setwd("tests")
untar("Datastore_AssignVehicleFeatures.tar")
untar("defs_AssignVehicleFeatures.tar")
unzip("ModelState_AssignVehicleFeatures.zip")
untar("inputs_AssignVehicleFeatures.tar")
file.remove(c(
  "Datastore_AssignVehicleFeatures.tar",
  "defs_AssignVehicleFeatures.tar",
  "ModelState_AssignVehicleFeatures.zip",
  "inputs_AssignVehicleFeatures.tar"))
setwd("..")
# Test AssignVehicleFeatures module
source("R/AssignVehicleFeatures.R")
testModule(
  ModuleName = "AssignVehicleFeatures",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
# Move the Log_AssignVehicleFeatures.txt file
setwd("tests")
file.copy("Log_AssignVehicleFeatures.txt", "verpat/Log_AssignVehicleFeatures.txt", overwrite = TRUE)
file.remove("Log_AssignVehicleFeatures.txt")
dir.remove("Datastore")
dir.remove("defs")
file.remove("ModelState.Rda")
setwd("..")

#Test AssignVehicleFeaturesFuture module
#---------------------------------------
# Organize tests folder for testing the AssignVehicleFeaturesFuture module
file.copy("tests/verpat/Datastore_AssignVehicleFeaturesFuture.tar", "tests/Datastore_AssignVehicleFeaturesFuture.tar")
file.copy("tests/verpat/defs_AssignVehicleFeaturesFuture.tar", "tests/defs_AssignVehicleFeaturesFuture.tar")
file.copy("tests/verpat/ModelState_AssignVehicleFeaturesFuture.zip", "tests/ModelState_AssignVehicleFeaturesFuture.zip")
setwd("tests")
untar("Datastore_AssignVehicleFeaturesFuture.tar")
untar("defs_AssignVehicleFeaturesFuture.tar")
unzip("ModelState_AssignVehicleFeaturesFuture.zip")
file.remove(c(
  "Datastore_AssignVehicleFeaturesFuture.tar",
  "defs_AssignVehicleFeaturesFuture.tar",
  "ModelState_AssignVehicleFeaturesFuture.zip"))
setwd("..")
# Test AssignVehicleFeaturesFuture module
source("R/AssignVehicleFeaturesFuture.R")
testModule(
  ModuleName = "AssignVehicleFeaturesFuture",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)
# Move the Log_AssignVehicleFeaturesFuture.txt file
setwd("tests")
file.copy("Log_AssignVehicleFeaturesFuture.txt", "verpat/Log_AssignVehicleFeaturesFuture.txt", overwrite = TRUE)
file.remove("Log_AssignVehicleFeaturesFuture.txt")
setwd("..")

#Clean up the tests directory
#----------------------------
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
dir.remove("inputs")
file.remove("ModelState.Rda")
setwd("..")
