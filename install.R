
#Download and Install VisionEval Resources

#library(httr)
#If working within a proxy server, run the following commands to enable install from GitHub
#set_config(use_proxy(url="proxynew.odot.state.or.us", port=8080))
#set_config( config( ssl_verifypeer = 0L ) )

#Set repository
local({currentRepo <- getOption("repos")
currentRepo["CRAN"] <- "https://cran.cnr.berkeley.edu/"
options(repos = currentRepo)
})

# Download and install the required libraries and their dependencies
cat("\nInstalling dependencies\n")
install.packages(c("curl","devtools", "roxygen2", "stringr", "knitr", "digest"), dependencies = TRUE, quiet=TRUE)
install.packages(c("shiny", "shinyjs", "shinyFiles", "data.table", "DT", "shinyBS", "future", "testit", "jsonlite", "shinyAce", "envDocument", "rhandsontable","shinyTree"), dependencies = TRUE, quiet=TRUE)
devtools::install_github("tdhock/namedCapture", quiet=TRUE)
source("https://bioconductor.org/biocLite.R")
biocLite(c("rhdf5","zlibbioc"), suppressUpdates=TRUE, quiet=TRUE)

#Download the VE repository
host <- "https://api.github.com/repos/"
repo <- "gregorbj/visioneval/"
ref <- "master"  # "add_scenario" or "develop"

destfile <- tempfile(fileext = paste0(".zip"))
destdir <- normalizePath(tempdir())
cat("\nDownloading VE repository to", destdir, "\n")
request <- httr::GET(paste0(host, repo, "zipball/", ref))
if(httr::status_code(request) >= 400){
	stop("\nError downloading the repository\n")
}
writeBin(httr::content(request, "raw"), destfile)
unzip(zipfile = destfile, exdir = destdir)
destdir <- normalizePath(file.path(destdir, grep("visioneval", list.files(destdir), value=TRUE, ignore.case=TRUE)))
cat("\nFinished downloading VE repository\n")
cat(paste0("\n","Download directory: ", destdir, "\n"))

# VE framework and modules
VE_framework <- "visioneval"
VE_modules <- c(
	"VE2001NHTS",
	"VESyntheticFirms",
	"VESimHouseholds",
	"VELandUse",
	"VETransportSupply",
	"VETransportSupplyUse",
	"VEHouseholdTravel",
	"VEHouseholdVehicles",
	"VEPowertrainsAndFuels",
	"VETravelPerformance",
	"VEReports",
	"VEScenario"
)

#Install the required VE framework package
cat("\nInstalling VE framework\n")
devtools::install_local(normalizePath(file.path(destdir, "sources", "framework", VE_framework)),
                        force=TRUE)

#Download and install the required VE modules for VERPAT and VERSPM
for(module in VE_modules){
	cat(paste("\nInstalling Module:", module,"\n"))
	devtools::install_local(normalizePath(file.path(destdir, "sources", "modules", module)))
	if(!module %in% rownames(installed.packages())){
		stop(paste0(module, " cannot be installed."))
	}
}