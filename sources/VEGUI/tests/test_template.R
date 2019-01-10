#===================
# test_template.R
#===================

# This is a template to write tests for VEGUI. Please modify this script to test different functionalities of VEGUI.

#=====================================================================
#SECTION 1: INITIATE THE APP AND DEFINE THE CONSTANTS AND FUNCTIONS
#=====================================================================
# Check if creating expected results or comparing current results.
if(!exists("createExpectedResults")){
  createExpectedResults <- FALSE
}

# Start the browser
suppressWarnings(app <- ShinyDriver$new("."))


name <- "test_name" # Modify this

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

#===========================
#SECTION 2: CREATE RESULTS
#===========================

# YOUR SCRIPT to produce and save expected results. Following are the commands
# to save the results.

# If creating images
# app$takeScreenshot(file = file.path(save_dir, "001.png"))

# If creating outputs
# output <- app$getAllValues()
# jsonlite::write_json(output, path = file.path(save_dir, "001.json"), pretty=TRUE)

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
