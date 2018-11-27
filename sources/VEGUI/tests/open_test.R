#===================
# open_test.R
#===================

# This script runs a shinytest that opens and closes the VEGUI, compares the
# output (json and image) and confirms running of VEGUI without any problems

#=====================================================================
#SECTION 1: INITIATE THE APP AND DEFINE THE CONSTANTS AND FUNCTIONS
#=====================================================================

library('jsonlite')
# Check if creating expected results or comparing current results.
if(!exists("createExpectedResults")){
  createExpectedResults <- FALSE
}

# Start the browser
app <- ShinyDriver$new(".", loadTimeout = 10000, phantomTimeout = 10000)

name <- "open_test"

if ( !exists(tests_dir) ){
  tests_dir <- file.path(app$getAppDir(),"tests")
  tests_dir <- normalizePath(tests_dir)
}

# Directory name to store the results
if ( createExpectedResults ){
  save_dir <- file.path(tests_dir, paste0(name, '-expected'))
} else {
  save_dir <- file.path(tests_dir, paste0(name, '-current'))
}

if(!dir.exists(save_dir)){
  dir.create(save_dir, recursive = TRUE)
}

# Set the model and run parameters to nothing to ensure consistency in the tests.
#app$setInputs(MODEL_PARAMETERS_FILE = "[\"\"]")
#app$setInputs(RUN_PARAMETERS_FILE = "[\"\"]")

#===========================
#SECTION 2: CREATE RESULTS
#===========================

# Take the screenshot of the VEGUI
Sys.sleep(time = 5) # Give the app time to hide tabs etc.
app$takeScreenshot(file = file.path(save_dir, "001.png"))

# Take all the values displayed in the browser
jsonlite::write_json(app$getAllValues(),
                     path = file.path(save_dir, "001.json"))

#=============================
#SECTION 3: COMPARE RESULTS
#=============================
if(!createExpectedResults){
  snapshotCompare(app$getAppDir(),name)
}

#=============================
#SECTION 4: STOP THE APP
#=============================
app$stop()
rm(app)
gc()
