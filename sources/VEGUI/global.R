#=============================================
#SECTION 1: LOAD LIBRARIES
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
library(shinyAce)
library(envDocument)
library(rhdf5)
library(namedCapture)
library(shinyTree)

#==========================================================
#SECTION 2: DEFINE CONSTANTS AND DEFINITIONS OF FUNCTIONS
#==========================================================

scriptDir <- getSrcDirectory(function(x) x )
source(file.path(scriptDir, "FutureTaskProcessor.R"))
#source(file.path(scriptDir,"ancillaryfunctions.R"))

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
DATASTORE_TABLE <- "DATASTORE_TABLE"
DATASTORE_TABLE_CLOSE_BUTTON <- "DATASTORE_TABLE_CLOSE_BUTTON"
DATASTORE_TABLE_EXPORT_BUTTON <- "DATASTORE_TABLE_EXPORT_BUTTON"
DATASTORE_TABLE_IDENTIFIER <- "DATASTORE_TABLE_IDENTIFIER"
DATASTORE_TABLE_VIEW_BUTTON_PREFIX <- "datastore_view"
DEBUG_CONSOLE_OUTPUT <- "DEBUG_CONSOLE_OUTPUT"
EDIT_INPUT_FILE_ID <- "EDIT_INPUT_FILE_ID"
EDIT_INPUT_FILE_LAST_CLICK <- "EDIT_INPUT_FILE_LAST_CLICK"
EDITOR_INPUT_FILE <- "EDITOR_INPUT_FILE"
EDITOR_INPUT_FILE_IDENTIFIER <- "EDITOR_INPUT_FILE_IDENTIFIER"
GEO_CSV_FILE <- "GEO_CSV_FILE"
HDF5_TABLES <- "HDF5_TABLES"
INPUT_FILE_CANCEL_BUTTON_PREFIX <- "input_file_cancel"
INPUT_FILE_EDIT_BUTTON_PREFIX <- "input_file_edit"
INPUT_FILE_SAVE_BUTTON_PREFIX <- "input_file_save"
INPUT_FILES <- "INPUT_FILES"
INPUTS_TREE <- "INPUTS_TREE"
INPUTS_TREE_SELECTED_TEXT <- "INPUTS_TREE_SELECTED_TEXT"
MODEL_MODULES <- "MODEL_MODULES"
MODEL_PARAMETERS_FILE <- "MODEL_PARAMETERS_FILE"
MODEL_STATE_FILE <- "MODEL_STATE_FILE"
MODEL_STATE_LS <- "ModelState_ls"
MODULE_PROGRESS <- "MODULE_PROGRESS"
OUTPUTS_TREE <- "OUTPUTS_TREE"
PAGE_TITLE <- "Pilot Model Runner and Scenario Viewer"
REVERT_MODEL_PARAMETERS_FILE <- "REVERT_MODEL_PARAMETERS_FILE"
REVERT_RUN_PARAMETERS_FILE <- "REVERT_RUN_PARAMETERS_FILE"
RUN_MODEL_BUTTON <- "RUN_MODEL_BUTTON"
RUN_PARAMETERS_FILE <- "RUN_PARAMETERS_FILE"
SAVE_MODEL_PARAMETERS_FILE <- "SAVE_MODEL_PARAMETERS_FILE"
SAVE_RUN_PARAMETERS_FILE <- "SAVE_RUN_PARAMETERS_FILE"
SCRIPT_NAME <- "SCRIPT_NAME"
SELECT_RUN_SCRIPT_BUTTON <- "SELECT_RUN_SCRIPT_BUTTON"
TAB_LOGS <- "TAB_LOGS"
TAB_INPUTS <- "TAB_INPUTS"
TAB_OUTPUTS <- "TAB_OUTPUTS"
TAB_RUN <- "TAB_RUN"
TAB_SETTINGS <- "TAB_SETTINGS"
VE_LOG <- "VE_LOG"
VIEW_DATASTORE_TABLE <- "VIEW_DATASTORE_TABLE"


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
