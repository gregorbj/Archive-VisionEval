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
untar("Datastore_ReportRPATMetrics.tar")
untar("defs_ReportRPATMetrics.tar")
unzip("ModelState_ReportRPATMetrics.zip")
untar("inputs_ReportRPATMetrics.tar")
setwd("..")

#Test CalculateCongestionBase module
source("R/ReportRPATMetrics.R")
testModule(
  ModuleName = "ReportRPATMetrics",
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
setwd("..")
