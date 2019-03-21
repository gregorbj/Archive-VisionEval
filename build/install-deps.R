devtools.CRAN <- c(
   "devtools"
  ,"knitr"
  ,"roxygen2"
  ,"curl"
  ,"yaml"
)
modules.BioC <- c("rhdf5")
vegui.github <- c("tdhock/namedCapture")
modules.CRAN <- c(
   "jsonlite"
  ,"stringr"
  ,"filesstrings"
  ,"knitr"
  ,"usethis"
  ,"reshape"
  ,"car"
  ,"pbkrtest"
  ,"quantreg"
  ,"geosphere"
  ,"fields"
  ,"tidycensus"
  ,"plot3D"
  ,"pscl"
  ,"ordinal"
  ,"reshape2"
  ,"data.table"
  ,"future.callr"
)
vegui.CRAN <- c(
   "DT"
  ,"envDocument"
  ,"rhandsontable"
  ,"shiny"
  ,"shinyBS"
  ,"shinyFiles"
  ,"shinyjs"
  ,"shinytest"
  ,"testit"
  ,"testthat"
  ,"webdriver"
)

cat("Installing to:",.libPaths()[1],"\n")

# Acknowledge the cache for the top-level packages
sought.pkgs <- c(devtools.CRAN,modules.CRAN,vegui.CRAN)
new.pkgs <- sought.pkgs[ ! (sought.pkgs %in% installed.packages()[,"Package"]) ]
if( length(new.pkgs) > 0 ) install.packages(new.pkgs)

devtools::install_bioc(c("3.6/BiocInstaller", paste("3.6",modules.BioC,sep="/")))
devtools::install_github(vegui.github)
