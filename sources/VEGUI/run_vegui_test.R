#===================
# run_vegui_test.R
#===================

# This script allows a user to run multiple tests on VEGUI to ensure its functionality and utility in running VISIONEVAL models. Following is a list of tests that have been implemented as of now:
# 1. opentest.R: Ensures that the VEGUI opens and closes properly.
# 2. run_verpat_model.R: Ensures that the VERPAT model is run properly through the VEGUI.


#=============================================
#SECTION 1: LOAD LIBRARIES
#=============================================

library(shinytest)
library(testthat)
library(shinyFiles)

#==========================================================
#SECTION 2: DEFINE CONSTANTS AND DEFINITIONS OF FUNCTIONS
#==========================================================
# TRUE: Create expected results, FALSE: Compare current results to expected results
createExpectedResults <- TRUE

tests_dir <- file.path(".","tests") # Test directory containing test scripts and expected output
tests_dir <- normalizePath(tests_dir)

### Modify the volumeroots to point to PROJECT run_model script
myapp <- readLines("app.R")

# Function to replace the volumeroots command with the model directory in the application script
replaceVolumeroots <- function(mystr,modelname,first=TRUE){
  if(first){
    mystr <- gsub("volumeRoots = getVolumes.*",paste0("volumeRoots = c(\"",modelname,"\"=file.path(getwd(),\"..\",\"models\",\"",modelname,"\"))"),mystr)
  } else {
    mystr <- gsub("volumeRoots = c(.*","volumeRoots = getVolumes(\"\")",mystr)
  }
  return(mystr)
}

# Rename
file.rename("app.R","app.R.tmp")
write(sapply(myapp,replaceVolumeroots),"app.R")

#============================================
#SECTION 3: RUN THE TESTS
#============================================
if(dir.exists(tests_dir)){
  test_that("Application Runs",{
    source(file.path(tests_dir,"open_test.R")); # open the app test

    write(sapply(myapp,replaceVolumeroots,modelname="VERPAT"),"app.R"); # Changed the model directory in the app.R to the project directory of the model intended to run
    source(file.path(tests_dir,"run_verpat_model_test.R")) # run VERPAT model test
    # More tests go here:
    # source(file.path(tests_dir,"test_name.R"))
  })
} else {
  stop("Tests do not exist!")
}

file.rename("app.R.tmp","app.R")

