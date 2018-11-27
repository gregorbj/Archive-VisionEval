#===================
# run_vegui_test.R
#===================

# This script allows a user to run multiple tests on VEGUI to ensure its
# functionality and utility in running VISIONEVAL models. Following is a list of
# tests that have been implemented as of now: 1. opentest.R: Ensures that the
# VEGUI opens and closes properly. 2. run_verpat_model.R: Ensures that the
# VERPAT model is run properly through the VEGUI.


#=============================================
#SECTION 1: LOAD LIBRARIES
#=============================================

library(shinytest)
library(testthat)
library(shinyFiles)

#==========================================================
#SECTION 2: DEFINE CONSTANTS AND DEFINITIONS OF FUNCTIONS
#==========================================================

# TRUE: Create expected results, FALSE: Compare current results to expected
# results
createExpectedResults <- FALSE

# Test directory containing test scripts and expected output
tests_dir <- file.path(".","tests")
tests_dir <- normalizePath(tests_dir)

# Function to replace the volumeroots command in the global.R script with the model
# directory
replaceVolumeroots <- function(mystr, modelname){

  # Pattern to search for
  pattern <- "volumeRoots = c.*"

  # Define replacement
  replacement <- paste0('volumeRoots = c("',
                        modelname,
                        '" = file.path(getwd(), "..", "models", "',
                        modelname,
                        '"))'
  )

  return(gsub(pattern, replacement, mystr))
}

# Rename
file.copy("global.R","global.R.tmp", overwrite = TRUE)

# Read in the script to modify
myapp <- readLines("global.R.tmp")

#============================================
#SECTION 3: RUN THE TESTS
#============================================
if(dir.exists(tests_dir)){
  test_that("Application Runs",{
    source(file.path(tests_dir,"open_test.R")); # open the app test

    # Change the model directory in the app.R to the project directory of the
    # model intended to run
    write(sapply(myapp, replaceVolumeroots, modelname="VERPAT"), "global.R");
    source(file.path(tests_dir,"run_verpat_model_test.R")) # run VERPAT model test

    # More tests go here:
    # source(file.path(tests_dir,"test_name.R"))
  })
} else {
  stop("Tests do not exist!")
}

file.rename("global.R.tmp","global.R")

