library(shinytest)
library(testthat)

tests_dir <- file.path(".","tests")
tests_dir <- normalizePath(tests_dir)

### Modify the volumeroots to point to VERPAT run_model script
myapp <- readLines("app.R")

# replace the volumeroots command
replaceVolumeroots <- function(mystr,first=TRUE){
  if(first){
    mystr <- gsub("volumeRoots = getVolumes.*","volumeRoots = c(\"VERPAT\"=file.path(getwd(),\"..\",\"models\",\"VERPAT\"))",mystr)
  } else {
    mystr <- gsub("volumeRoots = c(.*","volumeRoots = getVolumes(\"\")",mystr)
  }
  return(mystr)
}

file.rename("app.R","app.R.tmp")
write(sapply(myapp,replaceVolumeroots),"app.R")

if(dir.exists(tests_dir)){
  test_that("Application Runs",{
    source(file.path(tests_dir,"opentest.R"));
    source(file.path(tests_dir,"run_verpat_model_test.R"))
  })
} else {
  stop("Tests do not exist!")
}

file.rename("app.R.tmp","app.R")

