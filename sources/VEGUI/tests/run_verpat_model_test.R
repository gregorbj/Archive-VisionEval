suppressWarnings(app <- ShinyDriver$new("."))
library(shinyFiles)
name <- "run_verpat_model_test"
save_dir <- file.path(app$getAppDir(),"tests")
save_dir <- normalizePath(save_dir)

if(!dir.exists(save_dir)){
  dir.create(save_dir)
}

removeDates <- function(modeldate){
  modeldate <- gsub("(\\d{4}-\\d{2}-\\d{2})?\\s?(\\d{2}:\\d{2}:\\d{2})?","",modeldate)
  return(modeldate)
}

removeLogs <- function(logdates){
  logdates <- gsub("Log__\\d{2}_\\d{2}_\\d{2}","Log_removed",logdates)
  return(logdates)
}

app$setInputs(MODEL_PARAMETERS_FILE = "[\"\"]")
app$setInputs(RUN_PARAMETERS_FILE = "[\"\"]")

if(dir.exists(file.path(save_dir,paste0(name,"-expected")))){
  if(!dir.exists(file.path(save_dir,paste0(name,"-current")))){
    dir.create(file.path(save_dir,paste0(name,"-current")))
  }
  select_button <- app$findElement(xpath = "//*[@id='SELECT_RUN_SCRIPT_BUTTON']")
  select_button$click()
  dir_file <- app$findElements(xpath = "//*//div[contains(@class,'sF-file')]//*//div[contains(string(),'run_model.R')]")
  getname <- function(divclass){
    return(divclass$getText())
  }
  foldernames <- sapply(dir_file,getname)
  index <- match("run_model.R",foldernames)
  run_model_file <- dir_file[[index]]
  run_model_file$click()
  select_button <- app$findElement(xpath = "//*[@id='sF-selectButton']")
  select_button$click()
  app$expectUpdate(output = "SCRIPT_NAME", timeout = 10e3)
  Sys.sleep(1)
  app$takeScreenshot(file = file.path(save_dir,paste0(name,"-current"),"001.png"))
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-current"),"001.json"),pretty=TRUE)
  run_button <- app$findElement(xpath = "//*//a[@data-value='TAB_RUN']")
  run_button$click()
  app$expectUpdate(output = "CAPTURED_SOURCE", timeout = 10e3)
  Sys.sleep(1)
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  app$takeScreenshot(file = file.path(save_dir,paste0(name,"-current"),"002.png"))
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-current"),"002.json"),pretty=TRUE)
  run_model_script_button <- app$findElement(xpath = "//*[@id='RUN_MODEL_BUTTON']")
  run_model_script_button$click()
  while(!run_model_script_button$isEnabled()) {
    Sys.sleep(1)
    print(paste0("Running Model: ",!run_model_script_button$isEnabled()))
  }
  Sys.sleep(1)
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,"-current"),"003.png"))
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-current"),"003.json"),pretty=TRUE)
  outputs_button <- app$findElement(xpath = "//*//a[@data-value='TAB_OUTPUTS']")
  outputs_button$click()
  app$expectUpdate(output = "MODEL_STATE_FILE", timeout = 10e3)
  Sys.sleep(1)
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,"-current"),"004.png"))
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output <- lapply(output$output,removeLogs)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-current"),"004.json"),pretty=TRUE)

} else {
  dir.create(file.path(save_dir,paste0(name,"-expected")))
  select_button <- app$findElement(xpath = "//*[@id='SELECT_RUN_SCRIPT_BUTTON']")
  select_button$click()
  dir_file <- app$findElements(xpath = "//*//div[contains(@class,'sF-file')]//*//div[contains(string(),'run_model.R')]")
  getname <- function(divclass){
    return(divclass$getText())
  }
  foldernames <- sapply(dir_file,getname)
  index <- match("run_model.R",foldernames)
  run_model_file <- dir_file[[index]]
  run_model_file$click()
  select_button <- app$findElement(xpath = "//*[@id='sF-selectButton']")
  select_button$click()
  app$expectUpdate(output = "SCRIPT_NAME", timeout = 10e3)
  Sys.sleep(1)
  app$takeScreenshot(file = file.path(save_dir,paste0(name,"-expected"),"001.png"))
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-expected"),"001.json"),pretty=TRUE)
  run_button <- app$findElement(xpath = "//*//a[@data-value='TAB_RUN']")
  run_button$click()
  app$expectUpdate(output = "CAPTURED_SOURCE", timeout = 10e3)
  Sys.sleep(1)
  app$takeScreenshot(file = file.path(save_dir,paste0(name,"-expected"),"002.png"))
  output <- app$getAllValues()
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-expected"),"002.json"),pretty=TRUE)
  run_model_script_button <- app$findElement(xpath = "//*[@id='RUN_MODEL_BUTTON']")
  run_model_script_button$click()
  while(!run_model_script_button$isEnabled()) {
    Sys.sleep(1)
    print(paste0("Running Model: ",!run_model_script_button$isEnabled()))
  }
  Sys.sleep(1)
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,"-expected"),"003.png"))
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-expected"),"003.json"),pretty=TRUE)
  outputs_button <- app$findElement(xpath = "//*//a[@data-value='TAB_OUTPUTS']")
  outputs_button$click()
  app$expectUpdate(output = "MODEL_STATE_FILE", timeout = 10e3)
  Sys.sleep(1)
  # app$takeScreenshot(file = file.path(save_dir,paste0(name,"-expected"),"004.png"))
  output <- app$getAllValues()
  output$output <- lapply(output$output,removeDates)
  output$output <- lapply(output$output,removeLogs)
  output$output$SCRIPT_NAME <- NULL
  jsonlite::write_json(output, path = file.path(save_dir,paste0(name,"-expected"),"004.json"),pretty=TRUE)
} # End check for directory

snapshotCompare(app$getAppDir(),name)

app$stop()
rm(app)
gc()
