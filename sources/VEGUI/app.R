#=======
# app.R
#=======

# This script builds an application that provides a user with the an interface to select a VE Model script to run, modify the input parameters to the model, run the model, and observe the output of the model.

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
source(file.path(scriptDir,"ancillaryfunctions.R"))

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
#============================================
#SECTION 3: DEFINE THE UI FOR APPLICATION
#============================================

# Define the webpage
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    # resize to window: http://stackoverflow.com/a/37060206/283973
    tags$script(
      '$(document).on("shiny:connected", function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });
      $(window).resize(function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });'
      ), #end tag$script

    tags$script(
      "$(document).on('click', '#INPUT_FILES button', function () {
      Shiny.onInputChange('EDIT_INPUT_FILE_ID',this.id);
      Shiny.onInputChange('EDIT_INPUT_FILE_LAST_CLICK', Math.random())
      });"
      ), #end tag$script
    tags$meta(charset = "UTF-8"),
    tags$meta(name = "google", content = "notranslate"),
    tags$meta(`http-equiv` = "Content-Language", content = "en")
    ),#end tag$head

  # Define title of the page
  titlePanel(windowTitle = PAGE_TITLE,
             title = div(img(
               src = "visioneval_logo.png",
               height = 100,
               width = 100,
               style = "margin:10px 10px"
               ), PAGE_TITLE)),#end titlePanel

  # Setup a panel to select the model script from a local drive
  navlistPanel(
    id = "navlist",
    # Define Scenario Tab
    tabPanel(
      "Scenario",
      shinyFiles::shinyFilesButton( # Creates a window with a display of directories and files for selection of model script
        id = SELECT_RUN_SCRIPT_BUTTON,
        label = "Select scenario run script...",
        title = "Please select model run script",
        multiple = FALSE,
        class=list(R = "R")
      ), #end shinyFilesButton
      
      h3("Run script: "),
      verbatimTextOutput(SCRIPT_NAME, placeholder=TRUE),
      
      shinyFiles::shinySaveButton( # Creates a window with a display of directories and files for saving
        id = COPY_MODEL_BUTTON,
        label = "Copy scenario...",
        title = "Please select location for new folder containing copy of current model",
        list('hidden_mime_type' = c(""))
        ) #end shinySaveButton
      ), #end tabPanel

    # Define Settings Tab
    tabPanel( # Defines the tab for displaying and changing the input parameters to the model.
      title = "Settings",
      value = TAB_SETTINGS,

      h3("Model parameters"),
      #shinyAce does not support setting height by lines and the updateAceEditor does not
      #have a height parameter so not sure what to do...
      #https://github.com/trestletech/shinyAce/issues/4
      shinyAce::aceEditor(MODEL_PARAMETERS_FILE, height = (16 * 10), mode = "json"),
      fluidRow(column(3, actionButton(SAVE_MODEL_PARAMETERS_FILE, "Save Changes")),
               column(3, actionButton(REVERT_MODEL_PARAMETERS_FILE, "Revert Changes"))
               ),
      
      #h3("Geo File"),
      #DT::dataTableOutput(GEO_CSV_FILE),

      h3("Run parameters"),
      shinyAce::aceEditor(RUN_PARAMETERS_FILE, height = (16 * 11), mode = "json"),
      fluidRow(column(3, actionButton(SAVE_RUN_PARAMETERS_FILE, "Save Changes")),
               column(3, actionButton(REVERT_RUN_PARAMETERS_FILE, "Revert Changes") )
               )
      ), #end tabPanel

    # Define Module Specifications Tab
    tabPanel(
      "Module specifications",
      value = TAB_INPUTS,
      h3("Input files:"),
      DT::dataTableOutput(INPUT_FILES),
      verbatimTextOutput(EDITOR_INPUT_FILE_IDENTIFIER, FALSE),
      rhandsontable::rHandsontableOutput(EDITOR_INPUT_FILE),
      h3("Datastore tables:"),
      DT::dataTableOutput(HDF5_TABLES),
      h3("Module specifications:"),
      "Currently Selected:",
      verbatimTextOutput(INPUTS_TREE_SELECTED_TEXT, placeholder = TRUE),
      shinyTree::shinyTree(INPUTS_TREE)
      ), #end tabPanel

    # Define Run Tab
    tabPanel(
      "Run",
      value = TAB_RUN,
      actionButton(RUN_MODEL_BUTTON, "Run Model Script"),
      h3("Module progress:"),
      DT::dataTableOutput(MODULE_PROGRESS),
      h3("Modules in model:"),
      DT::dataTableOutput(MODEL_MODULES),
      h3("VisionEval console output:"),
      verbatimTextOutput(CAPTURED_SOURCE, FALSE)
    ), #end tabPanel

    # Define Outputs Tab
    tabPanel(
      "Outputs",
      value = TAB_OUTPUTS,
      verbatimTextOutput(DATASTORE_TABLE_IDENTIFIER, FALSE),
      shinyFiles::shinySaveButton(
        id = DATASTORE_TABLE_EXPORT_BUTTON,
        label = "Export displayed datastore data...",
        title = "Please pick location and name for the exported data...",
        myFileTypes_ls
      ),
      actionButton(DATASTORE_TABLE_CLOSE_BUTTON, "Close Datastore table"),
      DT::dataTableOutput(VIEW_DATASTORE_TABLE),
      h3("Datastore: (click row to view and export)"),
      DT::dataTableOutput(DATASTORE_TABLE),
      h3("Model state"),
      verbatimTextOutput(MODEL_STATE_FILE, FALSE)
    ), #end tabPanel

    # Define Log Tab
    tabPanel(
      "Logs (newest first)",
      value = TAB_LOGS,
      h3("Log:"),
      DT::dataTableOutput(VE_LOG),
      h3("Console output:"),
      DT::dataTableOutput(DEBUG_CONSOLE_OUTPUT)
    ) #end tabPanel
 ) #end navlistPanel
) #end ui <- fluid page


#============================================
#SECTION 4: DEFINE THE SERVER FOR APPLICATION
#============================================

server <- function(input, output, session) {

  # Following variables are the reactive variables
  # 1. otherReactiveValues_rv
  # 2. reactiveFilePaths_rv
  # 3. getModuleProgress
  # 4. getModelModules
  # 5. getInputsTree
  # 6. getOutputHDF5_TABLES
  # 7. getOutputINPUT_FILES

  otherReactiveValues_rv <- reactiveValues() #WARNING- DON'T USE VARIABLES TO INITIALIZE LIST KEYS - the variable name will be used, not the value

  otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]] <- data.table::data.table(time = character(), message = character())

  otherReactiveValues_rv[[MODULE_PROGRESS]] <- data.table::data.table()

  reactiveFilePaths_rv <- reactiveValues()

  reactiveFilePaths_rv[[CAPTURED_SOURCE]] <- tempfile(pattern = "VEGUI_source_capture", fileext = ".txt")

  reactiveFileReaders_ls <- list() # A list of reactive variables


  # Print all the messages out to the console
  debugConsole <- function(msg) {
    testit::assert("debugConsole was passed NULL!", !is.null(msg))
    time <- paste(Sys.time())
    newRow_dt <- data.table::data.table(time = time, message = msg)
    existingRows_dt <- isolate(otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]])
    otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]] <<- rbind(newRow_dt, existingRows_dt)
    print(paste0(nrow(isolate(otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]])),
                 ": ", time, ": ", msg))
    flush.console()
  } # end debugConsole

  # Read a json file
  SafeReadJSON <- function(filePath) {
    debugConsole(paste0("SafeReadJSON function called to load ",
      filePath,". Exists? ",file.exists(filePath)))
    if (file.exists(filePath)) {
      fileContent_ls <- fromJSON(filePath)
      return(fileContent_ls)
    } else {
      return("")
    }
  }# end SafeReadJSON

  # Read an ASCII file
  SafeReadLines <- function(filePath) {
    debugConsole(paste0("SafeReadLines called to load ",
      filePath,". Exists? ",file.exists(filePath)))
    result_vc <- ""
    if (file.exists(filePath)) {
      result_vc <- readLines(filePath)
    }
    return(result_vc)
  } #end SafeReadLines

  SafeReadAndCleanLines <- function(filePath) {
    debugConsole(paste0("SafeReadAndCleanLinesfunction called to load ",
                        filePath, ". Exists? ", file.exists(filePath)
    )
    ) #end SafeReadAndCleanLines
    fileContents <- SafeReadLines(filePath)
    results <- vector('character') #a zero length vector unlike c() which is NULL

    for (line in fileContents) {
      if (nchar(trimws(line)) > 0) {
        #remove all leading and/or traiing spaces or quotes
        cleanLine <- gsub("^[ \"]+|[v\"]+$", "", line)
        if (nchar(cleanLine) > 0) {
          results <- c(results, cleanLine)
        }
      }
    } #end loop over lines
    return(results)
  } #end SafeReadAndCleanLines

  # Read a csv file
  SafeReadCSV <- function(filePath) {
    debugConsole(paste0("SafeReadCSV called to load ",
      filePath,". Exists? ",file.exists(filePath)))
    result_dt <- ""
    if (file.exists(filePath)) {
      result_dt <- data.table::fread(filePath)
    }
    return(result_dt)
  } #end SafeReadCSV

  #http://stackoverflow.com/questions/38064038/reading-an-rdata-file-into-shiny-application
  # This function, borrowed from http://www.r-bloggers.com/safe-loading-of-rdata-files/,
  #load the Rdata into a new environment to avoid side effects
  LoadToEnvironment <- function(filePath, env = new.env(parent = emptyenv())) {
      debugConsole(paste0("LoadToEnvironment called to load ",
        filePath,". Exists? ",file.exists(filePath)))
      if (file.exists(filePath)) {
        load(filePath, env)
      }
      return(env)
    }


  # Function that adds reactive objects that read files to a globally maintained list.
  registerReactiveFileHandler <- function(reactiveFileNameKey, readFunc = SafeReadLines) {
      debugConsole(paste0("registerReactiveFileHandler called to register '",
          reactiveFileNameKey, "' names(reactiveFileReaders_ls): ",
          paste0(collapse = ", ", names(isolate(reactiveFileReaders_ls)))
        )
      )
      reactiveFileReaders_ls[[reactiveFileNameKey]] <<- reactiveFileReader(DEFAULT_POLL_INTERVAL,
                                                                           session,
                                                                           filePath = function() {
                                                                             returnValue <- reactiveFilePaths_rv[[reactiveFileNameKey]]
                                                                             if (is.null(returnValue)){
                                                                               returnValue <- "" #cannot be null since it is used by reactiveFileReader in file.info.
                                                                               }
                                                                             return(returnValue)
                                                                           },
                                                                           #end filePath function
                                                                           #use a function so change of filePath will trigger refresh....
                                                                           readFunc = readFunc
                                                                           )#end reactiveFileReader
    } #end registerReactiveFileHandler

  shinyFiles::shinyFileSave(
    input = input,
    id = COPY_MODEL_BUTTON,
    session = session,
    roots = volumeRoots,
    defaultRoot = 'VisionEval',
    #must specify a filetype due to shinyFiles bug https://github.com/thomasp85/shinyFiles/issues/56
    #even though in my case I am creating a folder so don't care about the mime type
    filetypes = c("")
  )

  shinyFiles::shinyFileSave(
    input = input,
    id = DATASTORE_TABLE_EXPORT_BUTTON,
    session = session,
    roots = volumeRoots,
    filetypes = myFileTypes_ls
  )

  shinyFiles::shinyFileChoose(
    input = input,
    id = SELECT_RUN_SCRIPT_BUTTON,
    session = session,
    roots = volumeRoots,
    defaultRoot = "VisionEval",
    filetypes = c("R")
  )

  observe({
    shinyjs::toggleState(id = COPY_MODEL_BUTTON,
                         condition = input[[SELECT_RUN_SCRIPT_BUTTON]],
                         selector = NULL)
  })

  observe({
    shinyjs::toggle(
      id = NULL,
      condition = data.table::is.data.table(otherReactiveValues_rv[[EDITOR_INPUT_FILE]]),
      anim = TRUE,
      animType = "Slide",
      time = 0.25,
      selector = "#EDITOR_INPUT_FILE, #EDITOR_INPUT_FILE_IDENTIFIER"
    )
  })

  observe({
    shinyjs::toggle(
      id = NULL,
      condition = data.table::is.data.table(otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]]),
      anim = TRUE,
      animType = "Slide",
      time = 0.25,
      selector = "#VIEW_DATASTORE_TABLE, #DATASTORE_TABLE_EXPORT_BUTTON, #DATASTORE_TABLE_IDENTIFIER, #DATASTORE_TABLE_CLOSE_BUTTON"
    )
  })

  #how to hide/show tabs https://github.com/daattali/advanced-shiny/blob/master/hide-tab/app.R
  observe({
    shinyjs::toggle(
      id = NULL,
      condition = input[[SELECT_RUN_SCRIPT_BUTTON]],
      anim = TRUE,
      animType = "Slide",
      time = 0.25,
      #select all items where data-value starts with 'TAB_'. The ^= similar to ^ in grep 'starts with'
      selector = "#navlist li a[data-value^=TAB_]"
    )
  })

  #need to call processRunningTasks so that the callback to the future Function will be hit
  observe(
    label = "processRunningTasks",
    x = {
      invalidateLater(DEFAULT_POLL_INTERVAL)
      processRunningTasks(debug = TRUE)
    }
  ) #end observe(label = processRunningTasks

  # Get the progress of modules
  getModuleProgress <- reactive({
    pattern <- "(?<date>^20[0-9]{2}(?:-[0-9]{2}){2}) (?<time>[^ ]+) :.*-- (?<actionType>(?:Finish|Start)(?:ing)?) module '(?<moduleName>[^']+)' for year '(?<year>[^']+)'"
    cleanedLogLines <- reactiveFileReaders_ls[[VE_LOG]]() # reactiveFileReaders_ls[[VE_LOG]]: reactive value
    result_dt <- data.table::data.table()
    if (length(cleanedLogLines) > 0) {
      modulesFoundInLogFile_dt <- data.table::as.data.table(namedCapture::str_match_named(rev(cleanedLogLines), pattern))[!is.na(actionType),]
      if (nrow(modulesFoundInLogFile_dt) > 0) {
        result_dt <- modulesFoundInLogFile_dt
      }
    }
    return(result_dt)
  }) #end getModuleProgress

  registerReactiveFileHandler(VE_LOG, readFunc = function(filePath) {
    cleanedLines <- SafeReadAndCleanLines(filePath)
    return(rev(cleanedLines))
    }
  ) #end VE_LOG file handler

  registerReactiveFileHandler(DATASTORE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for DATASTORE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    if (!file.exists(filePath)) {
      returnValue_dt <- NULL
      } else {
        G <- readModelState()
        table_dt <- data.table::data.table(G$Datastore)
        if(nrow(table_dt) > 0){
          table_attributes_ls <- table_dt[,attributes]
          table_groups_present <- sapply(table_attributes_ls, function(x) "LENGTH" %in% names(x))
          table_dt <- table_dt[table_groups_present,.(Group = group,Name = name)]
          returnValue_dt <- table_dt#[!Name %in% getYears()]
        } else {
          returnValue_dt <- NULL
        }
      }
      return(returnValue_dt)
    }
  ) #end DATASTORE

  registerReactiveFileHandler(CAPTURED_SOURCE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for CAPTURED_SOURCE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    lines <- SafeReadLines(filePath)
    if (length(lines) > 1) {
      result <- paste0(collapse = "\n", lines)
      } else {
        result <- lines
        }
    return(result)
    }
  )

  registerReactiveFileHandler(MODEL_PARAMETERS_FILE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for MODEL_PARAMETERS_FILE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    return(SafeReadJSON(filePath))}
  )
  registerReactiveFileHandler(RUN_PARAMETERS_FILE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for RUN_PARAMETERS_FILE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    return(SafeReadJSON(filePath))}
  )

  registerReactiveFileHandler(GEO_CSV_FILE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for GEO_CSV_FILE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    return(SafeReadCSV(filePath))}
  )

  registerReactiveFileHandler(MODEL_STATE_FILE, #use a function so change of filePath will trigger refresh....
                              readFunc = function(filePath) {
                                debugConsole(paste0("MODEL_STATE_FILE function called to load ",
                                                    filePath, ". Exists? ", file.exists(filePath)
                                                    )
                                             )
                                if (file.exists(filePath)) {
                                  env <- LoadToEnvironment(filePath)
                                  debugConsole(paste0("MODEL_STATE_FILE loaded ", filePath,
                                                      ". names(env): ", paste0(collapse = ", ",
                                                                               names(env)))
                                               )
                                  testit::assert(paste0("'", filePath, "' must contain '",
                                                        MODEL_STATE_LS,
                                                        "' but has this instead: ",
                                                        paste0(collapse = ", ", names(env))),
                                                 MODEL_STATE_LS %in% names(env))
                                  myModelState_ls <- env[[MODEL_STATE_LS]]
                                  return(myModelState_ls)
                                  } else {
                                    return("")
                                    }
                                }# end readFunc
        ) #end call to registerReactiveFileHandler

  # Get the information about the scipt like paths to the scripts and input files
  getScriptInfo <- eventReactive(
  {!'integer' %in% class(input[[SELECT_RUN_SCRIPT_BUTTON]])},
  {
    debugConsole("getScriptInfo entered")
    scriptInfo_ls <- list()
    inFile <- parseFilePaths(roots = volumeRoots, input[[SELECT_RUN_SCRIPT_BUTTON]])
    debugConsole(paste('SELECT_RUN_SCRIPT_BUTTON:', input[[SELECT_RUN_SCRIPT_BUTTON]]))
    scriptInfo_ls$datapath <- normalizePath(as.character(inFile$datapath))
    scriptInfo_ls$fileDirectory <- dirname(scriptInfo_ls$datapath)
    scriptInfo_ls$fileBase <- basename(scriptInfo_ls$datapath)
    debugConsole(paste("getScriptInfo:", scriptInfo_ls$datapath))

    #call the first few methods so can find out log file value and get the ModelState_ls global
    setwd(scriptInfo_ls$fileDirectory)
    visioneval::initModelStateFile()
    visioneval::initLog()
    visioneval::writeLog("VE_GUI called visioneval::initModelStateFile() and visioneval::initLog()")

      #From now on we will get the current ModelState by reading the object stored on disk
    reactiveFilePaths_rv[[MODEL_STATE_FILE]] <<- file.path(scriptInfo_ls$fileDirectory, "ModelState.Rda")

    reactiveFilePaths_rv[[VE_LOG]] <<- file.path(scriptInfo_ls$fileDirectory, readModelState()$LogFile)
    reactiveFilePaths_rv[[DATASTORE]] <<- file.path(scriptInfo_ls$fileDirectory, readModelState()$DatastoreName)

    defsDirectory <- file.path(scriptInfo_ls$fileDirectory, "defs")

    reactiveFilePaths_rv[[MODEL_PARAMETERS_FILE]] <<- file.path(defsDirectory, "model_parameters.json")

    reactiveFilePaths_rv[[RUN_PARAMETERS_FILE]] <<- file.path(defsDirectory, "run_parameters.json")

    reactiveFilePaths_rv[[GEO_CSV_FILE]] <<- file.path(defsDirectory, "geo.csv")

    #move to the settings tab
    updateNavlistPanel(session, "navlist", selected = TAB_SETTINGS)
    debugConsole("getScriptInfo exited")
    return(scriptInfo_ls)
    }
    ) #end getScriptInfo reactive

  getModelModules <- reactive({
    datapath <- getScriptInfo()$datapath
    debugConsole(paste0("getModelModules entered with datapath: ", datapath))
    setwd(dirname(datapath))
    modelModules_dt <- data.table::as.data.table(visioneval::parseModelScript(datapath, TestMode = TRUE))
    return(modelModules_dt)
  }) #end getModelModules

  # Buttons to disable when the model is running
  disableActionButtons <- function() {
    disable(id = SELECT_RUN_SCRIPT_BUTTON, selector = NULL)
    disable(id = RUN_MODEL_BUTTON, selector = NULL)
    disable(id = COPY_MODEL_BUTTON, selector = NULL)
  }

  # Buttons to enable when the model has finished running
  enableActionButtons <- function() {
    enable(id = SELECT_RUN_SCRIPT_BUTTON, selector = NULL)
    enable(id = RUN_MODEL_BUTTON, selector = NULL)
    enable(id = COPY_MODEL_BUTTON, selector = NULL)

  }

  # Gather the output of model run
  getScriptOutput <- function(datapath, captureFile) {
    #From now on we will get the current ModelState by reading the object stored on disk
    #store the current ModelState in the global options
    #so that the process will use the same log file as the one we have already started tracking...
    ModelState_ls <- readModelState()
    options("visioneval.preExistingModelState" = ModelState_ls)
    debugConsole("getScriptOutput entered")
    setwd(dirname(datapath))
    capture.output(source(datapath), file = captureFile)
    options("visioneval.preExistingModelState" = NULL)
    debugConsole("getScriptOutput exited")
    return(NULL)
  } #end getScriptOutput

  # Run the model
  observeEvent(input[[RUN_MODEL_BUTTON]], label = RUN_MODEL_BUTTON, handlerExpr = {
    req(input[[SELECT_RUN_SCRIPT_BUTTON]])
    debugConsole("observeEvent input$runModel entered")
    datapath <- getScriptInfo()$datapath
    disableActionButtons()
    startAsyncTask(CAPTURED_SOURCE, future({
      # if(file.exists(reactiveFilePaths_rv[[MODEL_STATE_FILE]])){
      #   remove(reactiveFilePaths_rv[[MODEL_STATE_FILE]])
      # }
      #reference ModelState_ls so future will recognize it as a global
      getScriptOutput(datapath, isolate(reactiveFilePaths_rv[[CAPTURED_SOURCE]]))
      }),
      callback = function(asyncResult) {
        # asyncResult:
        #   asyncTaskName = asyncTaskName,
        #   taskResult = taskResult,
        #   submitTime = submitTime,
        #   endTime = endTime,
        #   elapsedTime = elapsedTime,
        #   caughtError = caughtError,
        #   caughtWarning = caughtWarning
        enableActionButtons()
      },
      debug = TRUE) # end startAsyncTask
    debugConsole("observeEvent input$runModel exited")
  }) #end runModel observeEvent



  # Save the changes made to the parameters to the parameter file
  saveParameterFile <- function(parameterFileIdentifier) {
    editedContent <- input[[parameterFileIdentifier]]
    filePath <- reactiveFilePaths_rv[[parameterFileIdentifier]]
    if (!is.null(editedContent) && nchar(editedContent) > 0) {
      file.rename(filePath, paste0(filePath, "_", format(Sys.time(), "%Y-%m-%d_%H-%M"),
                                   ".bak")
                  )
      print(paste0("writing out '", filePath, "' with nrow(editedContent): ",
                   nrow(editedContent), " ncol(editedContent): ", ncol(editedContent))
            )
      write(editedContent, filePath)
    }
  } # end saveParameterFile

  # Revert the changes made to the parameter in the display window
  revertParameterFile <- function(parameterFileIdentifier) {
    shinyAce::updateAceEditor(session, parameterFileIdentifier,
                              value = jsonlite::toJSON(
                                reactiveFileReaders_ls[[parameterFileIdentifier]](),
                                pretty = TRUE))
  } # end revertParameterFile

  observeEvent(input[[SAVE_MODEL_PARAMETERS_FILE]], handlerExpr = {
      saveParameterFile(MODEL_PARAMETERS_FILE)
    }, label = SAVE_MODEL_PARAMETERS_FILE)


  observeEvent(input[[REVERT_MODEL_PARAMETERS_FILE]], handlerExpr = {
      revertParameterFile(MODEL_PARAMETERS_FILE)
    }, label = REVERT_MODEL_PARAMETERS_FILE)

  observeEvent(input[[SAVE_RUN_PARAMETERS_FILE]], handlerExpr = {
      saveParameterFile(RUN_PARAMETERS_FILE)
    }, label = SAVE_RUN_PARAMETERS_FILE)

  observeEvent(input[[REVERT_RUN_PARAMETERS_FILE]], handlerExpr = {
      revertParameterFile(RUN_PARAMETERS_FILE)
    }, label = REVERT_RUN_PARAMETERS_FILE)

  observeEvent(input[[DATASTORE_TABLE_CLOSE_BUTTON]], handlerExpr = {
    otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]] <- FALSE
    },  label = DATASTORE_TABLE_CLOSE_BUTTON)

  observeEvent(input[[DATASTORE_TABLE_EXPORT_BUTTON]], label = DATASTORE_TABLE_EXPORT_BUTTON,
               handlerExpr = {
                 debugConsole("observeEvent input[[DATASTORE_TABLE_EXPORT_BUTTON]] entered")
                 fileInfo = shinyFiles::parseSavePath(roots = volumeRoots,
                                                      input[[DATASTORE_TABLE_EXPORT_BUTTON]])
                 datapath <- as.character(fileInfo$datapath)
                 dataTable <- otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]]
                 print(paste("Saving exported HDF5 table with", nrow(dataTable),
                             "rows and ", ncol(dataTable), "to:", datapath)
                       )
                 separator <- if (endsWith(datapath, ".tsv")) "\t" else ","
                 data.table::fwrite(dataTable, datapath, sep = separator)
                 if (!file.exists(datapath)) {
                   stop(paste("Right after saving file it is missing:", datapath))
                 }
                 debugConsole("observeEvent(input[[DATASTORE_TABLE_EXPORT_BUTTON]], exited")
               }) #end  observeEvent(input[[DATASTORE_TABLE_EXPORT_BUTTON]],

  # Get a tree structure of inputs to the model
  getInputsTree <- reactive({
    modules <- getModelModules()
    scriptInfo <- getScriptInfo()

    #prepare for calling into visioneval for module specs
    setwd(scriptInfo$fileDirectory)
    packages <- sort(unique(modules[, PackageName]))

    root_ls <- list()
    for (packageName in packages) {
      packageNode <- list()
      modulesInPackage <- sort(modules[PackageName == (packageName), ModuleName])
      for (moduleName in modulesInPackage) {
        ModuleSpecs_ls <- visioneval::processModuleSpecs(
          visioneval::getModuleSpecs(moduleName, packageName)
          )
        semiFlattened <- semiFlatten(ModuleSpecs_ls, "ModuleSpecs_ls")
        packageNode[[moduleName]] <- semiFlattened
      } #end for moduleName
      root_ls[[packageName]] <- packageNode
    } #end packageName
    return(root_ls)
  }) #end getInputsTree

  # Flattens the file path to be displayed
  semiFlatten <- function(node, ancestorPath) {
    if (is.list(node)) {
      #if a list does not have names, use the index in names as the name
      if (is.null(names(node))) {
        names(node) <- 1:length(node)
      }
      for (name in names(node)) {
        #replace node with semiFlattened node
        childPath <- paste0(ancestorPath, "-->", name)
        childNodeValue <- node[[name]]
        semiFlattenedChildNode <- semiFlatten(childNodeValue, childPath)
        attr(semiFlattenedChildNode, "ancestorPath") <- childPath
        #replace the child with the flattened version
        node[[name]] <- semiFlattenedChildNode
      } #end for loop over child nodes
    } # end if list
    else if (length(node) > 1) {
      #since not a list this is probably a vector of strings
      #need to convert to a list with the strings as the key and the value is irrelevant
      emptyListWithNumbersAsKeys <- lapply(1:length(node), function(i) "ignored-type-1")
      leafList <- setNames(emptyListWithNumbersAsKeys, node)
      node <- leafList
    } else {
      #must be a leaf but shinyTree requires even these to be lists
      if (!is.na(node)) {
        nodeString <- trimws(as.character(node))
      } else {
        nodeString = ""
      }
      if (nodeString == "") {
        nodeString <- "{empty}"
      }
      #icons https://shiny.rstudio.com/reference/shiny/latest/icon.html
      leafNode <- structure(list(), sticon = "signal")
      leafNode[[nodeString]] <- structure("ignored-type-2", sticon = "asterisk")
      node <- leafNode
    }
    return(node)
  } #end semiFlatten

  getInputFilesTable <- reactive({
    getInputsTree()
    fileItems <- extractFromTree("FILE")
    inputFilesDataTable_dt <- unique(data.table::data.table(File = fileItems$resultList))
    return(inputFilesDataTable_dt)
  })



  #https://antoineguillot.wordpress.com/2017/03/01/three-r-shiny-tricks-to-make-your-shiny-app-shines-33-buttons-to-delete-edit-and-compare-datatable-rows
  observeEvent(input[[EDIT_INPUT_FILE_LAST_CLICK]], label = EDIT_INPUT_FILE_LAST_CLICK,
               handlerExpr = {
                 buttonId <- input[[EDIT_INPUT_FILE_ID]]
                 namedResult <- data.table::as.data.table(
                   namedCapture::str_match_named(buttonId, "^(?<action>.+)_(?<row>[^_]+)$"))
                 action <- namedResult[, action]
                 row <- as.integer(namedResult[, row])
                 DT <- getInputFilesTable()
                 fileName <- DT[row, File]
                 debugConsole(paste("got click inside table.  buttonId:", buttonId,
                                    " action:", action, "row:", row, "fileName:", fileName)
                              )

                 for (rowNumber in 1:nrow(DT)) {
                   editButtonOnRow <- paste0(INPUT_FILE_EDIT_BUTTON_PREFIX, "_", rowNumber)
                   if (rowNumber == row) {
                     cancelButtonOnRow <- paste0(INPUT_FILE_CANCEL_BUTTON_PREFIX, "_", rowNumber)
                     saveButtonOnRow <- paste0(INPUT_FILE_SAVE_BUTTON_PREFIX, "_", rowNumber)
                     filePath <- file.path(getScriptInfo()$fileDirectory, "inputs", fileName)

                     #do the appropriate action
                     if (action == INPUT_FILE_EDIT_BUTTON_PREFIX) {
                       fileDataTable <- SafeReadCSV(filePath)
                       otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]] <- fileName
                       print(paste("nrow(fileDataTable):", nrow(fileDataTable)))
                       otherReactiveValues_rv[[EDITOR_INPUT_FILE]] <- fileDataTable
                       shinyjs::disable(editButtonOnRow, selector = NULL)
                       shinyjs::enable(saveButtonOnRow, selector = NULL)
                       shinyjs::enable(cancelButtonOnRow, selector = NULL)
                       } else {
                         if (action == INPUT_FILE_SAVE_BUTTON_PREFIX) {
                           editedContent <- rhandsontable::hot_to_r(input[[EDITOR_INPUT_FILE]])
                           if (!is.null(editedContent) && nchar(editedContent) > 0) {
                             file.rename(filePath, paste0(filePath, "_",
                                                          format(Sys.time(), "%Y-%m-%d_%H-%M"),
                                                          ".bak"))
                             print(paste0("writing out '", filePath,
                                          "' with nrow(editedContent): ", nrow(editedContent),
                                          " ncol(editedContent): ", ncol(editedContent))
                                   )
                             data.table::fwrite(editedContent, filePath)
                             }
                           otherReactiveValues_rv[[EDITOR_INPUT_FILE]] <- FALSE
                           } else if (action == INPUT_FILE_CANCEL_BUTTON_PREFIX) {
                             otherReactiveValues_rv[[EDITOR_INPUT_FILE]] <- FALSE
                             } else {
                               stop(paste("Got an unexpected button action. buttonId:",
                                          buttonId, " action:", action, "row:", row)
                               )
                             }
                         shinyjs::enable(editButtonOnRow, selector = NULL)
                         shinyjs::disable(saveButtonOnRow, selector = NULL)
                         shinyjs::disable(cancelButtonOnRow, selector = NULL)
                       }
                 } else {
                     #if not row clicked on then enable or disable edit button
                     #depending whether we beginning editing (disable all others)
                     #or finishing editing (re-enabling all others)
                     if (action == INPUT_FILE_EDIT_BUTTON_PREFIX) {
                       shinyjs::disable(editButtonOnRow, selector = NULL)
                       } else {
                         shinyjs::enable(editButtonOnRow, selector = NULL)
                       }
                   } #end if not clicked on row
             } #end for loop over files
}) #end observeEvent click on button in file table


  extractFromTree <- function(target) {
    resultList <- vector('character') #a zero length vector unlike c() which is NULL
    resultAncestorsList <- vector('character') #a zero length vector unlike c() which is NULL
    extractFilesFromTree <- function(node) {
      names <- names(node)
      for (name in names) {
        currentNode <- node[[name]]
        if (name == target) {
          targetValue <- names(currentNode)[[1]]
          ancestorPath <- getAncestorPath(currentNode)
          resultList <<- c(resultList, targetValue)
          resultAncestorsList <<- c(resultAncestorsList, ancestorPath)
        } else {
          extractFilesFromTree(currentNode) #RECURSIVE
        }
      } #end for loop over names
    } # end internal function
    extractFilesFromTree(getInputsTree())
    return(list(
      "resultList" = resultList,
      "resultAncestorsList" = resultAncestorsList
    ))
  } #end extractFromTree


  getAncestorPath <- function(leaf) {
    ancestorPath <- attr(leaf, "ancestorPath")
    return(ancestorPath)
  } #end getAncestorPath

  getOutputHDF5_TABLES <- reactive({
    getInputsTree()
    groupItems <- extractFromTree("GROUP")
    tableItems <- extractFromTree("TABLE")
    tables <- unique(data.table::data.table(
          Group = groupItems$resultList,
          Table = tableItems$resultList
        )
      )
    # TreePath = tableItems$resultAncestorsList))
    returnValue <- DT::datatable(tables, selection = 'none')
    return(returnValue)
  }) #end getOutputHDF5_TABLES

  getOutputINPUT_FILES <- reactive({
    DT <- getInputFilesTable()
    DT[["Actions"]] <- paste0('
        <div class="btn-group" role="group" aria-label="Basic example">
        <button type="button" class="btn btn-secondary" id=',
        INPUT_FILE_EDIT_BUTTON_PREFIX,
        '_',
        1:nrow(DT),
        '>Edit</button>
        <button type="button" class="btn btn-secondary" disabled id=',
        INPUT_FILE_CANCEL_BUTTON_PREFIX,
        '_',
        1:nrow(DT),
        '>Cancel</button>
        <button type="button" class="btn btn-secondary" disabled id=',
        INPUT_FILE_SAVE_BUTTON_PREFIX,
        '_',
        1:nrow(DT),
        '>Save</button>
        </div>
        '
      )
    returnValue <- DT::datatable(DT, escape = F, selection = 'none')
    return(returnValue)
  }) #end getOutputINPUT_FILES

  output[[EDITOR_INPUT_FILE_IDENTIFIER]] = renderText({
    otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]]
  })

  output[[EDITOR_INPUT_FILE]] <- rhandsontable::renderRHandsontable({
    DF <- otherReactiveValues_rv[[EDITOR_INPUT_FILE]]
    if (is.null(DF) || !data.table::is.data.table(DF)) {
      DF <- data.table::data.table("foo" = "bar")
      }
    print(paste0("nrow(DF): ", nrow(DF), " class(DF): ", paste0(collapse = ", ", class(DF))))
    rhandsontable(DF, useTypes = TRUE)
    })

  getOutputINPUTS_TREE_SELECTED_TEXT <- reactive({
    tree <- input[[INPUTS_TREE]]
    results <- ""
    if (!is.null(tree)) {
      selectedItemPaths <- list()
      selectedItems <- get_selected(tree)
      if (length(selectedItems) > 0) {
        for (selectedItemNumber in 1:length(selectedItems)) {
          selectedItem <- selectedItems[[selectedItemNumber]]
          #https://rdrr.io/cran/shinyTree/man/get_selected.html
          ancestry <- attr(selectedItem, "ancestry") # character vector
          selectedNode <- as.character(selectedItem)
          totalPath <- c(ancestry, selectedNode)
          isFile <- length(ancestry) > 0 && (ancestry[[length(ancestry)]] == "FILE")
          pathInfo <- list(
            "ancestry" = ancestry,
            "finalNode" = selectedNode,
            "fullPath" = paste0(collapse = "-->", totalPath),
            "isFile" = isFile
          )
          selectedItemPaths[[selectedItemNumber]] <- pathInfo
        } #end for over selected items
        results <- paste0(collapse = "\n", lapply(selectedItemPaths, function(x) x$fullPath))
      } # end if tree has a selection
    } #end if tree exists
    return(results)
  }) #end getOutputINPUTS_TREE_SELECTED_TEXT

  output[[SCRIPT_NAME]] = renderText({
    getScriptInfo()$datapath
  })

  # Function to load data from visioneval readFromTable function
  loadVERPAT <- function(filepaths, datastore_type = "RD"){
    # Ancillary function
    mbasename <- function(filepath,n=1){
      for(i in seq_len(n-1)){
        filepath <- dirname(filepath)
      }
      return(basename(filepath))
    }

    if(datastore_type == "RD"){
      readFromTable <- visioneval::readFromTableRD
    } else {
      readFromTable <- visioneval::readFromTableH5
    }
    ModelState_ls <<- readModelState()
    verpatoutput <- filepaths[,.(value = list(readFromTable(Name=mbasename(groupname, 1), Table = mbasename(groupname, 2), Group = mbasename(groupname, 3)))), by = .(name)]
    finaloutput <- as.data.table(verpatoutput$value)
    setnames(finaloutput, colnames(finaloutput), verpatoutput$name)
    return(finaloutput)
  }

  observeEvent(input$DATASTORE_TABLE_row_last_clicked,{
    selection <- input$DATASTORE_TABLE_row_last_clicked
    print(paste0("input$DATASTORE_TABLE_row_last_clicked: ", selection))
    if (!is.null(selection)) {
      row <- as.integer(selection)
      DataPathTable <- reactiveFileReaders_ls[[DATASTORE]]()
      DataRow <- DataPathTable[row]
      G <- readModelState()
      filepaths <- data.table::data.table(G$Datastore)
      otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]] <- paste0(DataRow$Group, "/",
                                                                     DataRow$Name)
      if(nrow(filepaths) > 0){
        filepaths <- filepaths[group %in% otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]]]
      }

      if(nrow(filepaths) > 0){
        table_dt <- loadVERPAT(filepaths,G$DatastoreType)
        otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]] <- table_dt
      } else {
        otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]] <- ""
        otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]] <- FALSE
      }
    } else {
      otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]] <- ""
      otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]] <- FALSE
    }
  }, label = "DATASTORE_TABLE_row_last_clicked")

  output[[DATASTORE_TABLE_IDENTIFIER]] = renderText({
    otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]]
  })

  output[[VIEW_DATASTORE_TABLE]] = DT::renderDataTable({
    hdf5DataTable <- otherReactiveValues_rv[[VIEW_DATASTORE_TABLE]]
    if (data.table::is.data.table(hdf5DataTable) && nrow(hdf5DataTable) > 0) {
      returnValue <- hdf5DataTable
      } else {
        returnValue <- data.table::data.table(
          Message = c(paste("There is no data for '",
                            otherReactiveValues_rv[[DATASTORE_TABLE_IDENTIFIER]], "'."))
          )
    }
    return(returnValue)
  }, server=TRUE, options = list(dom = 'ftip'), selection='none')

  output[[DATASTORE_TABLE]] <- DT::renderDataTable({
    result <- reactiveFileReaders_ls[[DATASTORE]]()
    if (is.null(result)) {
      dataTable <- data.table::data.table()
    } else {
      dataTable <- result
    }
    return(dataTable)
    }, server=FALSE, options = list(dom = 'ftip'), escape = F, selection = 'single')

  output[[GEO_CSV_FILE]] = DT::renderDataTable({
    getScriptInfo()
    returnValue <- reactiveFileReaders_ls[[GEO_CSV_FILE]]()
    return(returnValue)
  }, server=FALSE, selection = 'none')

  output[[MODEL_STATE_FILE]] = renderText({
    getScriptInfo()
    jsonlite::toJSON(reactiveFileReaders_ls[[MODEL_STATE_FILE]](), pretty = TRUE)
  })

  observe({
    shinyAce::updateAceEditor(
      session,
      MODEL_PARAMETERS_FILE,
      value = jsonlite::toJSON(reactiveFileReaders_ls[[MODEL_PARAMETERS_FILE]](), pretty = TRUE)
    )

    shinyAce::updateAceEditor(
      session,
      RUN_PARAMETERS_FILE,
      value = jsonlite::toJSON(reactiveFileReaders_ls[[RUN_PARAMETERS_FILE]](), pretty = TRUE)
    )
  })

  ###RUN TAB_RUN
  output[[MODULE_PROGRESS]] = DT::renderDataTable({
    returnValue <- getModuleProgress()
    return(returnValue)
  }, server=FALSE, selection = 'none')

  output[[CAPTURED_SOURCE]] <- renderText({
    reactiveFileReaders_ls[[CAPTURED_SOURCE]]()
  })

  output[[MODEL_MODULES]] = DT::renderDataTable({
    getScriptInfo()
    returnValue <- getModelModules()
    return(returnValue)
  }, server=FALSE, selection = 'none')

  ###MODULE_SPECIFICATIONS TAB_INPUTS
  output[[INPUT_FILES]] = DT::renderDataTable({
    return(getOutputINPUT_FILES())
  }, server=FALSE) #end output[[INPUT_FILES]]

  output[[HDF5_TABLES]] = DT::renderDataTable({
    return(getOutputHDF5_TABLES())
  }, server=FALSE) #end output[[HDF5_TABLES]]

  output[[INPUTS_TREE_SELECTED_TEXT]] <- renderText({
    return(getOutputINPUTS_TREE_SELECTED_TEXT())
  }) #end output[[INPUTS_TREE_SELECTED_TEXT]]

  output[[INPUTS_TREE]] <- renderTree({
    specTree <- getInputsTree()
    return(specTree)
  })

  ###LOGS TAB_LOGS
  output[[VE_LOG]] = DT::renderDataTable({
    getScriptInfo()
    logLines <- reactiveFileReaders_ls[[VE_LOG]]()
    DT <- data.table::data.table(message = logLines)
    return(DT)
  }, server=FALSE, selection = 'none')

  output[[DEBUG_CONSOLE_OUTPUT]] = DT::renderDataTable({
    return(otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]])
  }, server=FALSE, options = list(dom = 'ftip'), selection = 'none')


  } #end server

app <- shinyApp(ui, server)
