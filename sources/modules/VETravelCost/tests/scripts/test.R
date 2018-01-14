library(visioneval)
library(filesstrings)

#Load datastore from VEHouseholdVehicles package
file.copy("../VEHouseholdVehicles/tests/Datastore.tar", "tests/Datastore.tar")
setwd("tests")
untar("Datastore.tar")
file.remove("Datastore.tar")
setwd("..")

#Put test code here

#Finish up
setwd("tests")
tar("Datastore.tar", "Datastore")
dir.remove("Datastore")
setwd("..")
