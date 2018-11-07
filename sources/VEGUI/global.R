#=============================================
# LOAD LIBRARIES
#=============================================

library(visioneval)
library(shiny)
library(shinyjs)
library(shinyFiles)
library(data.table)
library(shinyBS)
library(future)
library(testit)
library(jsonlite)
library(DT)
library(rhandsontable)
library(envDocument)
library(rhdf5)
library(namedCapture)

#==========================================================
# DEFINE CONSTANTS AND DEFINITIONS OF FUNCTIONS
#==========================================================

scriptDir <- getSrcDirectory(function(x) x )
source(file.path(scriptDir, "FutureTaskProcessor.R"))

#DT options https://datatables.net/reference/option/dom
# only display the table, and nothing else
options(DT.options = list(dom = 'tip', rownames = 'f'))

#use of future in shiny
#http://stackoverflow.com/questions/41610354/calling-a-shiny-javascript-callback-from-within-a-future
plan(multiprocess) #tell "future" library to use multiprocessing

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

# VARIABLES USED AS THE NAME OF REACTIVE ELEMENTS IN SHINY OUTPUT
CAPTURED_SOURCE <- "CAPTURED_SOURCE"
COPY_MODEL_BUTTON <- "COPY_MODEL_BUTTON"
DATASTORE <- "DATASTORE"
DEBUG_CONSOLE_OUTPUT <- "DEBUG_CONSOLE_OUTPUT"
EDITOR_INPUT_FILE_DT <- "EDITOR_INPUT_FILE_DT"
EDITOR_INPUT_FILE_RHT <- "EDITOR_INPUT_FILE_RHT"
EDITOR_INPUT_FILE_IDENTIFIER <- "EDITOR_INPUT_FILE_IDENTIFIER"
EDITOR_INPUT_DIV <- "EDITOR_INPUT_DIV"
GEO_CSV_FILE <- "GEO_CSV_FILE"
INPUT_FILE_SAVE_BUTTON <- "INPUT_FILE_SAVE_BUTTON"
INPUT_FILE_REVERT_BUTTON <- "INPUT_FILE_REVERT_BUTTON"
INPUT_FILES <- "INPUT_FILES"
MODEL_MODULES <- "MODEL_MODULES"
MODEL_PARAMETERS_FILE <- "MODEL_PARAMETERS_FILE"
MODEL_PARAMETERS_RHT <- "MODEL_PARAMETERS_RHT"
MODEL_STATE_FILE <- "MODEL_STATE_FILE"
MODEL_STATE_LS <- "ModelState_ls"
MODULE_PROGRESS <- "MODULE_PROGRESS"
OUTPUT_DIR <- "OUTPUT_DIR"
OUTPUT_FILE <- "OUTPUT_FILE"
OUTPUT_FILE_PATH <- "OUTPUT_FILE_PATH"
OUTPUT_FILE_RHT <- "OUTPUT_FILE_RHT"
OUTPUT_FILE_SAVE_BUTTON <- "OUTPUT_FILE_SAVE_BUTTON"
PAGE_TITLE <- "Model Runner"
REVERT_MODEL_PARAMETERS_FILE <- "REVERT_MODEL_PARAMETERS_FILE"
REVERT_RUN_PARAMETERS_FILE <- "REVERT_RUN_PARAMETERS_FILE"
RUN_MODEL_BUTTON <- "RUN_MODEL_BUTTON"
RUN_PARAMETERS_FILE <- "RUN_PARAMETERS_FILE"
RUN_PARAMETERS_RHT <- "RUN_PARAMETERS_RHT"
SAVE_MODEL_PARAMETERS_FILE <- "SAVE_MODEL_PARAMETERS_FILE"
SAVE_RUN_PARAMETERS_FILE <- "SAVE_RUN_PARAMETERS_FILE"
SCRIPT_NAME <- "SCRIPT_NAME"
SELECT_RUN_SCRIPT_BUTTON <- "SELECT_RUN_SCRIPT_BUTTON"
TAB_INPUTS <- "TAB_INPUTS"
TAB_OUTPUTS <- "TAB_OUTPUTS"
TAB_RUN <- "TAB_RUN"
TAB_SETTINGS <- "TAB_SETTINGS"
VE_LOG <- "VE_LOG"

# Time between the checks for the result of the model output
DEFAULT_POLL_INTERVAL <- 1500 #milliseconds

# Define the file types
myFileTypes_ls <- list(
  `comma separated values` = "csv",
  `tab separated values` = "tsv"
)

# Get the volumes of local drive
volumeRoots = c('working directory' = '.', 'models' = '../models', 'VisionEval' = '../..', getVolumes("")())
# volumeRoots = getVolumes("")()

# Define utility functions ----------------------------------------

convertRunParam2Df <- function(rp_lst){

  lst2 <- lapply(rp_lst, function(x){
    if ( length(x) > 1 ){
      x <- paste(x, collapse=', ')
    }
    x
  })

  mat <- t(as.data.frame(lst2 ))
  df <- data.frame(Parameter = row.names(mat),
                      Value = mat,
                      stringsAsFactors = FALSE)
  row.names(df) <- NULL
  df
}

convertRunParam2Lst <- function(rp_df){

  parameters <- rp_df$Parameter
  values <- rp_df$Value

  lst <- as.list(values)
  names(lst) <- parameters

  lst2 <- lapply(lst, function(x){
    strsplit(x, split=",[ ]*")[[1]]
  })

  lst2
}

