#-------
#setup.R
#-------
#This script installs all the packages needed to run the VisionEval demo
#Required packages are "rhdf5", "devtools", "jsonlite", "visioneval", "vedemo1"

#Install rhdf5 package
source("http://bioconductor.org/biocLite.R")
biocLite()
biocLite("rhdf5")

#Install devtools package
#Enables you to install from GitHub & also installs jsonlite package
install.packages("devtools")

#Install visioneval and vedemo1 packages from GitHub
library("devtools")
install_github(repo = "gregorbj/VisionEval/sources/framework/visioneval")
install_github(repo = "gregorbj/VisionEval/sources/modules/vedemo1")
