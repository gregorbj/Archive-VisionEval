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
    # YOUR SCRIPT
    # to produce and save current results. Following are the commands to save the results. Please make sure that the expected results and current results have the same nomenclature.

    # If creating images
    # app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"001.png"))

    # If creating outputs
    # output <- app$getAllValues()
    # jsonlite::write_json(output, path = file.path(save_dir,paste0(name,current),"001.json"),pretty=TRUE)
  }
} else {
  # YOUR SCRIPT
  # to produce and save expected results. Following are the commands to save the results. Please make sure that the expected results and current results have the same nomenclature.

  # If creating images
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,expected),"001.png"))

  # If creating outputs
  # output <- app$getAllValues()
  # jsonlite::write_json(output, path = file.path(save_dir,paste0(name,expected),"001.json"),pretty=TRUE)
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
