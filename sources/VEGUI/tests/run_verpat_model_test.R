#============================
# run_verpat_model_test.r
#============================

# This script runs a shinytest that does the following steps:
# 1. Runs global.R (VEGUI)
# 2. Selects run_model.R script from VERPAT project folder
# 3. Runs the model
# 4. Collects the results from the model run
# 5. Compares the results with the expected results

#=====================================================================
#SECTION 1: INITIATE THE APP AND DEFINE THE CONSTANTS AND FUNCTIONS
#=====================================================================
# Check if creating expected results or comparing current results.
if(!exists("createExpectedResults")){
  createExpectedResults <- FALSE
}

# Start the browser
suppressWarnings(app <- ShinyDriver$new("."))
name <- "run_verpat_model_test"
save_dir <- file.path(app$getAppDir(),"tests")
save_dir <- normalizePath(save_dir)

# Directory name to store the results
expected <- "-expected"
current <- "-current"

if(!dir.exists(save_dir)){
  dir.create(save_dir)
}

# Function to remove user, platform, and/or time dependent identifiers in the results from the model run.

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

# Set the model and run parameters to nothing to ensure consistency in the tests.
# app$setInputs(MODEL_PARAMETERS_FILE = "[\"\"]")
# app$setInputs(RUN_PARAMETERS_FILE = "[\"\"]")


#===========================
#SECTION 2: CREATE RESULTS
#===========================
if(dir.exists(file.path(save_dir,paste0(name,expected))) & !createExpectedResults){
  if(!dir.exists(file.path(save_dir,paste0(name,current)))){
    dir.create(file.path(save_dir,paste0(name,current)))
  }
  Sys.sleep(1)
  # Find and press select button
  select_button <- app$findElement(xpath = "//*[@id='SELECT_RUN_SCRIPT_BUTTON']")
  select_button$click()
  Sys.sleep(4)

  # Click on VERPAT model
  select_dropdown <- app$findElement(xpath = "//*[@value='VERPAT']")
  select_dropdown$click()
  Sys.sleep(2)

  # Select run_model.R
  dir_file <- app$findElements(xpath = "//*//div[contains(@class,'sF-file')]//*//div[contains(string(),'run_model.R')]")
  foldernames <- sapply(dir_file,getname)
  index <- match("run_model.R",foldernames)
  run_model_file <- dir_file[[index]]
  run_model_file$click()
  Sys.sleep(1)
  select_button <- app$findElement(xpath = "//*[@id='sF-selectButton']")
  select_button$click()
  app$expectUpdate(output = "SCRIPT_NAME", timeout = 10e3) # Monitor that the run_model.R is loaded completely
  Sys.sleep(1)
  app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"001.png"))

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,current),"001.json"),pretty=TRUE)

  # Move to the run model tab
  run_button <- app$findElement(xpath = "//*//a[@data-value='TAB_RUN']")
  run_button$click()
  app$expectUpdate(output = "CAPTURED_SOURCE", timeout = 10e3)
  Sys.sleep(1)

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"002.png"))
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,current),"002.json"),pretty=TRUE)

  # Run the model
  run_model_script_button <- app$findElement(xpath = "//*[@id='RUN_MODEL_BUTTON']")
  run_model_script_button$click()
  while(!run_model_script_button$isEnabled()) {
    Sys.sleep(30)
    print(paste0("Running Model: ",!run_model_script_button$isEnabled()))
    print(paste0("Time: ", Sys.time()))
  }
  Sys.sleep(1)
  # Screenshot not take as the displayed value contains timestamp and other identifiers
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"003.png"))

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,current),"003.json"),pretty=TRUE)

  # Move to the output tab
  outputs_button <- app$findElement(xpath = "//*//a[@data-value='TAB_OUTPUTS']")
  outputs_button$click()
  app$expectUpdate(output = "MODEL_STATE_FILE", timeout = 10e3)
  Sys.sleep(1)
  # Screenshot not take as the displayed value contains timestamp and other identifiers
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,current),"004.png"))

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output <- lapply(output$output,removeLogs)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,current),"004.json"),pretty=TRUE)

} else {
  if(dir.exists(file.path(save_dir, paste0(name, expected)))){
    unlink(file.path(save_dir, paste0(name, expected), "*"))
  } else {
    dir.create(file.path(save_dir,paste0(name,expected)))
  }
  Sys.sleep(1)
  # Find and press select button
  select_button <- app$findElement(xpath = "//*[@id='SELECT_RUN_SCRIPT_BUTTON']")
  select_button$click()
  Sys.sleep(4)

  # Click on VERPAT model
  select_dropdown <- app$findElement(xpath = "//*[@value='VERPAT']")
  select_dropdown$click()
  Sys.sleep(2)

  # Select run_model.R
  dir_file <- app$findElements(xpath = "//*//div[contains(@class,'sF-file')]//*//div[contains(string(),'run_model.R')]")
  getname <- function(divclass){
    return(divclass$getText())
  }
  foldernames <- sapply(dir_file,getname)
  index <- match("run_model.R",foldernames)
  run_model_file <- dir_file[[index]]
  run_model_file$click()
  Sys.sleep(1)
  select_button <- app$findElement(xpath = "//*[@id='sF-selectButton']")
  select_button$click()
  app$expectUpdate(output = "SCRIPT_NAME", timeout = 10e3) # Monitor that the run_model.R is loaded completely
  Sys.sleep(1)

  # Clean the results displayed in the browser (remove the identifiers)
  app$takeScreenshot(file = file.path(save_dir,paste0(name,expected),"001.png"))
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,expected),"001.json"),pretty=TRUE)

  # Move to the run model tab
  run_button <- app$findElement(xpath = "//*//a[@data-value='TAB_RUN']")
  run_button$click()
  app$expectUpdate(output = "CAPTURED_SOURCE", timeout = 10e3)
  Sys.sleep(1)
  app$takeScreenshot(file = file.path(save_dir,paste0(name,expected),"002.png"))

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,expected),"002.json"),pretty=TRUE)

  # Run the model
  Sys.sleep(30)
  run_model_script_button <- app$findElement(xpath = "//*[@id='RUN_MODEL_BUTTON']")
  run_model_script_button$click()
  while(!run_model_script_button$isEnabled()) {
    Sys.sleep(30)
    print(paste0("Running Model: ",!run_model_script_button$isEnabled()))
    print(paste0("Time: ", Sys.time()))
  }
  Sys.sleep(1)
  # Screenshot not take as the displayed value contains timestamp and other identifiers
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,expected),"003.png"))

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,expected),"003.json"),pretty=TRUE)

  # Move to the output tab
  outputs_button <- app$findElement(xpath = "//*//a[@data-value='TAB_OUTPUTS']")
  outputs_button$click()
  app$expectUpdate(output = "MODEL_STATE_FILE", timeout = 10e3)
  Sys.sleep(1)

  # Screenshot not take as the displayed value contains timestamp and other identifiers
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,expected),"004.png"))

  # Clean the results displayed in the browser (remove the identifiers)
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output <- lapply(output$output,removeLogs)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,expected),"004.json"),pretty=TRUE)
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
cat('Finished!  Stopping the app\n')
app$stop()
rm(app)
gc()
cat('run_verpat_model_test.R complete!\n')
