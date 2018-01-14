library(visioneval)
library(filesstrings)

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
