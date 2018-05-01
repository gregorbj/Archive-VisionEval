
#Download and Install VisionEval Resources

#library(httr)
#If working within a proxy server, run the following commands to enable install from GitHub
#set_config(use_proxy(url="proxynew.odot.state.or.us", port=8080))
#set_config( config( ssl_verifypeer = 0L ) )

# Download and install the required libraries and their dependencies
install.packages(c("curl","devtools", "roxygen2", "stringr", "knitr", "digest"), dependencies = TRUE)
install.packages(c("shiny", "shinyjs", "shinyFiles", "data.table", "DT", "shinyBS", "future", "testit", "jsonlite", "shinyAce", "envDocument", "rhandsontable","shinyTree"), dependencies = TRUE)
devtools::install_github("tdhock/namedCapture")
source("https://bioconductor.org/biocLite.R")
biocLite(c("rhdf5","zlibbioc"), suppressUpdates=TRUE)

#Download and install the required VE framework package
devtools::install_github("gregorbj/VisionEval/sources/framework/visioneval")

#Download and install the required VE modules for VERPAT and VERSPM
devtools::install_github("gregorbj/VisionEval/sources/modules/VESyntheticFirms")
devtools::install_github("gregorbj/VisionEval/sources/modules/VESimHouseholds")
devtools::install_github("gregorbj/VisionEval/sources/modules/VELandUse")
devtools::install_github("gregorbj/VisionEval/sources/modules/VETransportSupply")
devtools::install_github("gregorbj/VisionEval/sources/modules/VETransportSupplyUse")
devtools::install_github("gregorbj/VisionEval/sources/modules/VEHouseholdVehicles")
devtools::install_github("gregorbj/VisionEval/sources/modules/VEHouseholdTravel")
devtools::install_github("gregorbj/VisionEval/sources/modules/VETransportSupplyUse")
devtools::install_github("gregorbj/VisionEval/sources/modules/VEPowertrainsAndFuels")
devtools::install_github("gregorbj/VisionEval/sources/modules/VETravelPerformance")
devtools::install_github("gregorbj/VisionEval/sources/modules/VEReports")
