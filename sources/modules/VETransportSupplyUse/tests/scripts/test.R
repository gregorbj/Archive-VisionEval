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
untar("Datastore_VERPAT.tar")
untar("defs_VERPAT.tar")
unzip("ModelState_VERPAT.zip")
untar("inputs_VERPAT.tar")
setwd("..")

#Test CreateBaseAccessibility module
source("R/CalculateCongestionBase.R")
testModule(
  ModuleName = "CalculateCongestionBase",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "AllYears"
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
