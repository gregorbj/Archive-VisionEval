
#Install VisionEval Resources

# Install packages in a directory within the root wd.
# Then make sure that the the run scripts use that directory!

ve_root <- getwd()
ve_lib <- file.path(ve_root, 've-lib')

if (!dir.exists(ve_lib)){
  dir.create(ve_lib)
}


#Set repository ------------------------------------------------------------
local({
  currentRepo <- getOption("repos")
  currentRepo["CRAN"] <- "https://cran.cnr.berkeley.edu/"
  options(repos = currentRepo)
})

# Set directories ----------------------------------------------------------

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
  "VEReports"
)


VE_src_dirs <- c(file.path(ve_root, 'sources', 'framework', VE_framework),
                 file.path(ve_root, 'sources', 'modules', VE_modules))


# Install requirements --------------------------------------------------------
# Download and install the required libraries and their dependencies
# Installed in system .libPaths() directories

cat("\nInstalling dependencies\n")

# Packages that belong in the system directory ------------------------------
external_pkgs <- c("BiocManager", "curl","data.table", "devtools", "digest", "DT","envDocument",
                   "future", "jsonlite", "knitr", "packrat", "rhandsontable",
                   "roxygen2", "shiny", "shinyBS", "shinyFiles", "shinyjs",
                   "stringr", "testit")

current_pkgs <- installed.packages()[, 'Package']

to_install <- external_pkgs[!external_pkgs %in% current_pkgs]
if ( length(to_install) > 0){
  install.packages(to_install, dependencies = TRUE, quiet=TRUE)
}

# Set a local directory for all the VE specific stuff
if ( ! ve_lib %in% .libPaths() ){
  .libPaths(c(ve_lib, .libPaths()))
}

current_pkgs <- installed.packages()[, 'Package']

# Github packages
github_pkgs <- data.frame(repo=c('namedCapture'), username=c('tdhock'))
to_install <- github_pkgs[!github_pkgs$repo %in% current_pkgs, ]
if ( nrow(to_install) > 0){
  devtools::install_github(paste0(to_install$username, '/', to_install$repo),
                           quiet=TRUE)
}

# Bioconductor packages
bioc_pkgs <- c("rhdf5","zlibbioc")
to_install <- bioc_pkgs[!bioc_pkgs %in% current_pkgs]
if ( length(to_install) > 0){
  BiocManager::install(to_install, suppressUpdates=TRUE, quiet=TRUE)
}


# Install the framework and required VE modules for VERPAT and VERSPM
for(src_dir in VE_src_dirs){
  module <- basename(src_dir)
	cat(paste("\nInstalling:", module,"\n"))
	if ( !module %in% rownames(installed.packages(lib.loc=ve_lib)) ){
	  devtools::install_local(normalizePath(src_dir), force=TRUE, lib = ve_lib)
	}
	if(!module %in% rownames(installed.packages(lib.loc=ve_lib))){
		stop(paste0(module, " cannot be installed."))
	}
}

# Write .RProfile in each directory with .Rproj so that ve-lib is recognized
# no matter where you open R from.

txt <- paste0('.libPaths(c("', ve_lib, '", .libPaths()))')
writeLines(text = txt, con = '.Rprofile')

subdirs <- dirname(list.files(path = '.', pattern = '*.Rproj',
                               full.names = TRUE,
                               recursive = TRUE))

for ( sd in subdirs ){
  file.copy('.Rprofile', file.path(sd,'.Rprofile'))
}

cat('VisionEval installer has finished')