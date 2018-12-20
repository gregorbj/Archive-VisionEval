#============================
# run_verpat_model_test.r
#============================

# This script runs a shinytest that does the following steps:
# 1. Runs app.R (VEGUI)
# 2. Selects run_model.R script from VERPAT project folder
# 3. Runs the model
# 4. Collects the results from the model run
# 5. Compares the results with the expected results

#=====================================================================
#SECTION 1: INITIATE THE APP AND DEFINE THE CONSTANTS AND FUNCTIONS
#=====================================================================
# Functions to remove user, platform, and/or time dependent identifiers in the results from the model run.

# Removes time-stamp from the results
removeDates <- function(modeldate){
  modeldate <- gsub("(\\d{4}-\\d{2}-\\d{2})?\\s?(\\d{2}:\\d{2}:\\d{2})?","",modeldate)
  return(modeldate)
} # end removeDates

# Removes log dates from the results
removeLogs <- function(logdates){
  logdates <- gsub("Log__\\d{2}_\\d{2}_\\d{2}","Log_removed",logdates)
  return(logdates)
} # end removeLogs

# Get the names of the div class
getname <- function(divclass){
  return(divclass$getText())
} # end getname


# Check if creating expected results or comparing current results.
if(!exists("createExpectedResults")){
  createExpectedResults <- FALSE
}

name <- "run_verpat_model_test"

# Start the app
app <- ShinyDriver$new(".", debug = 'all',
                       loadTimeout = 10000, phantomTimeout = 10000)

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

# Set the model and run parameters to nothing to ensure consistency in the tests.
#app$setInputs(MODEL_PARAMETERS_FILE = "[\"\"]")
#app$setInputs(RUN_PARAMETERS_FILE = "[\"\"]")

# Find and press select button
cat('Pressing the select button\n')
select_button <- app$findElement(xpath = "//*[@id='SELECT_RUN_SCRIPT_BUTTON']")
select_button$click()
Sys.sleep(10)
#app$takeScreenshot()

# Select run_model.R
cat('Finding the run_model.R script\n')
dir_file <- app$findElements(xpath = "//*//div[contains(@class,'sF-file')]//*//div[contains(string(),'run_model.R')]")
cat('Length of dir_file:', length(dir_file), '\n')

foldernames <- sapply(dir_file,getname)
index <- match("run_model.R",foldernames)
cat('Index = ', index, '\n')
cat('Clicking the run model file\n')
run_model_file <- dir_file[[index]]
run_model_file$click()

cat('Clicking the select button\n')
select_button <- app$findElement(xpath = "//*[@id='sF-selectButton']")
select_button$click()
app$expectUpdate(output = "SCRIPT_NAME", timeout = 10e3) # Monitor that the run_model.R is loaded completely

# Get results of selecting run_model.R
cat('Taking screenshots and saving output\n')
Sys.sleep(10)
app$takeScreenshot(file = file.path(save_dir,"001.png"))

# Clean the results displayed in the browser (remove the identifiers)
output <- app$getAllValues()
output$output$SCRIPT_NAME <- NULL
jsonlite::write_json(output, path = file.path(save_dir,"001.json"),pretty=TRUE)

# Move to the run model tab
cat('Moving to the run model tab\n')
run_tab <- app$findElement(xpath = "//*//a[@data-value='TAB_RUN']")
run_tab$click()
Sys.sleep(1)

# Clean the results displayed in the browser (remove the identifiers)
cat('Saving output\n')
output <- app$getAllValues()
output$output$SCRIPT_NAME <- NULL
app$takeScreenshot(file = file.path(save_dir,"002.png"))
jsonlite::write_json(output, path = file.path(save_dir,"002.json"),pretty=TRUE)

# Run the model
cat('Running model\n')
run_model_script_button <- app$findElement(xpath = "//*[@id='RUN_MODEL_BUTTON']")
run_model_script_button$click()
#app$expectUpdate(output = "MODULE_PROGRESS")
#app$expectUpdate(output = "CAPTURED_SOURCE")

# FIXME: if the script stops, the run_model_script_button will still not be enabled
while(!run_model_script_button$isEnabled()) {
  Sys.sleep(30)
  print(paste0("Running Model: ",!run_model_script_button$isEnabled()))
  print(paste0("Time: ", Sys.time()))
  #app$takeScreenshot()
}
Sys.sleep(1)

# Screenshot not take as the displayed value contains timestamp and other identifiers
# app$takeScreenshot(file = file.path(save_dir,"003.png"))

# Clean the results displayed in the browser (remove the identifiers)
cat('Getting output\n')
output <- app$getAllValues()
output$output <- lapply(output$output,removeDates)
output$output$SCRIPT_NAME <- NULL
jsonlite::write_json(output, path = file.path(save_dir,"003.json"),pretty=TRUE)

# Move to the output tab
cat('Moving to the Output tab\n')
outputs_button <- app$findElement(xpath = "//*//a[@data-value='TAB_OUTPUTS']")
outputs_button$click()
Sys.sleep(1)
# Screenshot not take as the displayed value contains timestamp and other identifiers
# app$takeScreenshot(file = file.path(save_dir,"004.png"))

# Clean the results displayed in the browser (remove the identifiers)
output <- app$getAllValues()
output$output <- lapply(output$output,removeDates)
output$output <- lapply(output$output,removeLogs)
output$output$SCRIPT_NAME <- NULL
jsonlite::write_json(output, path = file.path(save_dir,"004.json"),pretty=TRUE)

#=============================
#SECTION 3: COMPARE RESULTS
#=============================
if(!createExpectedResults){
  snapshotCompare(app$getAppDir(),name)
}

#=============================
#SECTION 4: STOP THE APP
#=============================
cat('Finished!  Stopping the app\n')
app$stop()
rm(app)
gc()
cat('run_verpat_model_test.R complete!\n')