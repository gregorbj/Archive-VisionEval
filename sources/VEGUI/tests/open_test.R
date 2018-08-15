#===================
# open_test.R
#===================

# This script runs a shinytest that opens and closes the VEGUI, compares the output (json and image) and confirms running of VEGUI without any problems

#=====================================================================
#SECTION 1: INITIATE THE APP AND DEFINE THE CONSTANTS AND FUNCTIONS
#=====================================================================
# Check if creating expected results or comparing current results.
if(!exists("createExpectedResults")){
  createExpectedResults <- FALSE
}

# Start the browser
suppressWarnings(app <- ShinyDriver$new("."))

name <- "open_test"
save_dir <- file.path(app$getAppDir(),"tests")
save_dir <- normalizePath(save_dir)

# Directory name to store the results
expected <- "-expected"
current <- "-current"



if(!dir.exists(save_dir)){
  dir.create(save_dir)
}

# Set the model and run parameters to nothing to ensure consistency in the tests.
app$setInputs(MODEL_PARAMETERS_FILE = "[\"\"]")
app$setInputs(RUN_PARAMETERS_FILE = "[\"\"]")

#===========================
#SECTION 2: CREATE RESULTS
#===========================

if(dir.exists(file.path(save_dir,paste0(name,expected))) & !createExpectedResults){
  if(dir.exists(file.path(save_dir,paste0(name,current)))){
    app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"001.png")) # Take the screenshot of the VEGUI
    jsonlite::write_json(app$getAllValues(), path = file.path(save_dir,paste0(name,current),"001.json")) # Take all the values displayed in the browser
  } else {
    dir.create(file.path(save_dir,paste0(name,current)))
    app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"001.png")) # Take the screenshot of the VEGUI
    jsonlite::write_json(app$getAllValues(), path = file.path(save_dir,paste0(name,current),"001.json")) # Take all the values displayed in the browser
  }
} else {
  if(dir.exists(file.path(save_dir, paste0(name, expected)))){
    unlink(file.path(save_dir, paste0(name, expected), "*"))
  } else {
    dir.create(file.path(save_dir,paste0(name,expected)))
  }
  app$takeScreenshot(file = file.path(save_dir,paste0(name,expected),"001.png")) # Take the screenshot of the VEGUI
  jsonlite::write_json(app$getAllValues(), path = file.path(save_dir,paste0(name,expected),"001.json"),pretty=TRUE) # Take all the values displayed in the browser
} # End check for directory

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
