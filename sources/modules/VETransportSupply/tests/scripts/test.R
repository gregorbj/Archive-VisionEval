library(visioneval)
library(filesstrings)

##################################################
## Section 1. Tests for modules used in VERSPM
##################################################

#Load datastore from VELandUse package
file.copy("../VELandUse/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Test AssignTransitService module
source("R/AssignTransitService.R")
testModule(
  ModuleName = "AssignTransitService",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Test AssignRoadMiles module
source("R/AssignRoadMiles.R")
testModule(
  ModuleName = "AssignRoadMiles",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE
)

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")


##################################################
## Section 2. Tests for modules used in VERPAT
##################################################

# Set the working directory to tests folder and load the output from
# previous module runs
setwd("tests")
# Copy and save the results from previous module tests
zip("ModelState.zip","ModelState.Rda")
file.remove("ModelState.Rda")
tar("defs.tar","defs")
tar("inputs.tar","inputs")
dir.remove("defs")
dir.remove("inputs")
untar("Datastore_VERPAT.tar")
unzip("ModelState_VERPAT.zip")
untar("inputs_VERPAT.tar")
setwd("..")

#Test CreateBaseAccessibility module
source("R/CreateBaseAccessibility.R")
testModule(
  ModuleName = "CreateBaseAccessibility",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = TRUE,
  RunFor = "BaseYear"
)

#Test CreateFutureAccessibility module
source("R/CreateFutureAccessibility.R")
testModule(
  ModuleName = "CreateFutureAccessibility",
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
unzip("ModelState.zip")
file.remove("ModelState.zip")
untar("defs.tar")
file.remove("defs.tar")
untar("inputs.tar")
file.remove("inputs.tar")
setwd("..")
