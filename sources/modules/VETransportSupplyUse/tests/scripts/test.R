library(visioneval)
library(filesstrings)

##################################################
## Section 1. Tests for modules used in VERSPM
##################################################


##################################################
## Section 2. Tests for modules used in VERPAT
##################################################

# Set the working directory to tests folder and load the output from
# previous module runs
setwd("tests")
# Copy and save the results from previous module tests
# zip("ModelState.zip","ModelState.Rda")
# file.remove("ModelState.Rda")
# tar("defs.tar","defs")
# tar("inputs.tar","inputs")
# dir.remove("defs")
# dir.remove("inputs")
untar("Datastore_CalculateCongestionBase.tar")
untar("defs_CalculateCongestionBase.tar")
unzip("ModelState_CalculateCongestionBase.zip")
untar("inputs_CalculateCongestionBase.tar")
setwd("..")

#Test CalculateCongestionBase module
source("R/CalculateCongestionBase.R")
testModule(
  ModuleName = "CalculateCongestionBase",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Reorganize folder to test next VERPAT module
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
file.remove("ModelState.rda")
untar("Datastore_CalculateCongestionFuture.tar")
untar("defs_CalculateCongestionFuture.tar")
unzip("ModelState_CalculateCongestionFuture.zip")
setwd("..")

#Test CalculateCongestionFuture module
source("R/CalculateCongestionFuture.R")
testModule(
  ModuleName = "CalculateCongestionFuture",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "NotBaseYear"
)

#Reorganize folder to test next VERPAT module
setwd("tests")
dir.remove("Datastore")
dir.remove("defs")
file.remove("ModelState.rda")
untar("Datastore_CalculateCongestionPolicy.tar")
untar("defs_CalculateCongestionPolicy.tar")
unzip("ModelState_CalculateCongestionPolicy.zip")
setwd("..")

#Test CalculateCongestionPolicy module
source("R/CalculateCongestionPolicy.R")
testModule(
  ModuleName = "CalculateCongestionPolicy",
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
file.remove("ModelState.rda")
# file.remove("ModelState.Rda")
# unzip("ModelState.zip")
# file.remove("ModelState.zip")
# untar("defs.tar")
# file.remove("defs.tar")
# untar("inputs.tar")
# file.remove("inputs.tar")
setwd("..")
