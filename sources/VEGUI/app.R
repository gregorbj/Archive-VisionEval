library(shiny)
library(shinyjs)
library(shinyFiles)
library(visioneval)
#library(DT)
library(data.table)
library(shinyBS)
library(future)
library(testit)
library(jsonlite)
library(shinyAce)

#https://github.com/tdhock/namedCapture
if (!require(namedCapture)) {
  if (!require(devtools)) {
    install.packages("devtools")
  }
  devtools::install_github("tdhock/namedCapture")
  library(namedCapture)
}

#use of future in shiny: http://stackoverflow.com/questions/41610354/calling-a-shiny-javascript-callback-from-within-a-future
plan(multiprocess) #tell "future" library to use multiprocessing

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

DEBUG_CONSOLE_OUTPUT <- "debugConsoleOutput"
MODEL_PARAMETERS_FILE <- "Model_Parameters_File"
RUN_PARAMETERS_FILE <- "Run_Parameters_File"
GEO_CSV_FILE <- "Geo File"
MODEL_STATE_FILE <- "Model State File"
MODEL_MODULES <- "Model_Modules"
VE_LOG <- "visionEval_Log"
CAPTURED_SOURCE <- "run_module_output"
MODEL_STATE_LS <-
  "ModelState_ls"

MODEL_PARAMETERS_FILE_EDITOR <- "modelParametersFileEditor"
EDIT_MODEL_PARAMETERS_SHOW <- "EDIT_MODEL_PARAMETERS_SHOW"
EDIT_MODEL_PARAMETERS_BUTTON <- "editModelParametersButton"
SAVE_MODEL_PARAMETERS_BUTTON <- "saveModelParametersButton"
CANCEL_EDIT_MODEL_PARAMETERS_BUTTON <-
  "cancelEditModelParametersButton"

MODULE_PROGRESS <- "moduleProgress"

volumeRoots = getVolumes("")

# Define UI for application
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(type = "text/css",
               ".recalculating { opacity: 1.0; }"),
    # resize to window: http://stackoverflow.com/a/37060206/283973
    tags$script(
      '$(document).on("shiny:connected", function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });
      $(window).resize(function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });'
                        )
  ),
  titlePanel("Pilot Model Runner and Scenario Viewer"),

  sidebarLayout(
    sidebarPanel(
      img(
        src = "visioneval_logo.png",
        height = 100,
        width = 100,
        style = "margin:10px 10px"
      ),

      shinyFilesButton(
        id = "selectRunScript",
        label = "Select Run Script",
        title = "Please select model run script",
        multiple = FALSE
      ),


      disabled(actionButton("runModel", "Run Model Script")),

      shinySaveButton(
        id = "copyModelDirectory",
        label = "Copy model directory...",
        title = "Please select location for new folder containing copy of current model",
        #must specify a filetype due to shinyFiles bug https://github.com/thomasp85/shinyFiles/issues/56
        #even though in my case I am creating a folder so don't care about the mime type
        filetype = list('hidden_mime_type' = c(""))
      ),

      width = 2

    ),

    mainPanel(
      dataTableOutput(MODULE_PROGRESS),
      tabsetPanel(
        tabPanel(
          "Main",
          bsAlert("parseProblems"),
          h3("Script Name"),
          verbatimTextOutput("scriptName", FALSE),
          h3("Modules"),
          dataTableOutput(MODEL_MODULES)
        ),
        tabPanel(
          MODEL_STATE_FILE,
          verbatimTextOutput(MODEL_STATE_FILE, FALSE)
        ),
        tabPanel(
          MODEL_PARAMETERS_FILE,
          conditionalPanel(condition = "!output.EDIT_MODEL_PARAMETERS_SHOW",
                           {
                             verbatimTextOutput(MODEL_PARAMETERS_FILE, FALSE)
                             actionButton(EDIT_MODEL_PARAMETERS_BUTTON, "Edit...")
                           }),
          conditionalPanel(condition = "output.EDIT_MODEL_PARAMETERS_SHOW",
                           {
                             aceEditor(MODEL_PARAMETERS_FILE_EDITOR, mode = "json")
                             actionButton(SAVE_MODEL_PARAMETERS_BUTTON, "Save and replace current")
                             actionButton(CANCEL_EDIT_MODEL_PARAMETERS_BUTTON,
                                          "Quit editing without saving")
                           })
        ),
        tabPanel(GEO_CSV_FILE,
                 dataTableOutput(GEO_CSV_FILE)),
        tabPanel(
          RUN_PARAMETERS_FILE,
          verbatimTextOutput(RUN_PARAMETERS_FILE, FALSE)
        ),
        tabPanel(VE_LOG,
                 verbatimTextOutput(VE_LOG, FALSE)),
        tabPanel(CAPTURED_SOURCE,
                 verbatimTextOutput(CAPTURED_SOURCE, FALSE)),
        tabPanel(
          "Debug console",
          h5("(most recent first)"),
          dataTableOutput(DEBUG_CONSOLE_OUTPUT)
        )
      )
    ) #end mainPanel
  ) #end sidebarLayout
    ) #end ui

DEFAULT_POLL_INTERVAL <- 500 #milliseconds


server <- function(input, output, session) {
  asyncData <-
    reactiveValues()
  asyncDataBeingLoaded <- list()

  filePaths <-
    list()

  otherReactiveValues <-
    reactiveValues() #WARNING- DON'T USE VARIABLES TO INITIALIZE LIST KEYS - the variable name will be used, not the value

  otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]] <-
    data.table::data.table(time = Sys.time(), message = "Placeholder to be deleted")[-1, ]

  otherReactiveValues[[MODULE_PROGRESS]] <- data.table::data.table()

  otherReactiveValues[[EDIT_MODEL_PARAMETERS_SHOW]] <- FALSE
  filePaths[[CAPTURED_SOURCE]] <-
    tempfile(pattern = "VEGUI_source_capture", fileext = ".txt")

  oldFilePaths <- filePaths
  reactiveFileReaders <- list()


  debugConsole <- function(msg) {
    testit::assert("debugConsole was passed NULL!", !is.null(msg))
    time <- Sys.time()
    newRow <- data.table::data.table(time = time, message = msg)
    existingRows <-
      isolate(otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]])
    otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]] <<-
      rbind(newRow,
            existingRows)
    print(paste0(nrow(isolate(
      otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]]
    )), ": ", time, ": ", msg))
    flush.console()
  }

  SafeReadJSON <- function(filePath) {
    debugConsole(paste0(
      "readJSON function called to load ",
      filePath,
      ". Exists? ",
      file.exists(filePath)
    ))
    if (file.exists(filePath)) {
      fileContent <- jsonlite::toJSON(filePath, pretty = TRUE)
      return(fileContent)
    } else {
      return("")
    }
  }# end SafeReadJSON

  SafeReadLines <- function(filePath) {
    debugConsole(paste0(
      "SafeReadLines called to load ",
      filePath,
      ". Exists? ",
      file.exists(filePath)
    ))
    result <- ""
    if (file.exists(filePath)) {
      result <- readLines(filePath)
    }
    return(result)
  }

  SafeReadCSV <- function(filePath) {
    debugConsole(paste0(
      "SafeReadCSV called to load ",
      filePath,
      ". Exists? ",
      file.exists(filePath)
    ))
    result <- ""
    if (file.exists(filePath)) {
      result <- read.csv(filePath)
    }
    return(result)
  }

  #http://stackoverflow.com/questions/38064038/reading-an-rdata-file-into-shiny-application
  # This function, borrowed from http://www.r-bloggers.com/safe-loading-of-rdata-files/, load the Rdata into a new environment to avoid side effects
  LoadToEnvironment <-
    function(filePath, env = new.env(parent = emptyenv())) {
      debugConsole(paste0(
        "LoadToEnvironment called to load ",
        filePath,
        ". Exists? ",
        file.exists(filePath)
      ))
      if (file.exists(filePath)) {
        load(filePath, env)
      }
      return(env)
    }

  registerReactiveFileHandler <-
    function(reactiveFileNameKey, readFunc = SafeReadLines) {
      debugConsole(
        paste0(
          "registerReactiveFileHandler called to register '",
          reactiveFileNameKey
          ,
          "' names(reactiveFileReaders): ",
          paste0(collapse = ", ", names(isolate(
            reactiveFileReaders
          )))
        )
      )
      reactiveFileReaders[[reactiveFileNameKey]] <<-
        reactiveFileReader(
          DEFAULT_POLL_INTERVAL,
          session,
          filePath = function() {
            if (is.null(oldFilePaths[[reactiveFileNameKey]]) ||
                (oldFilePaths[[reactiveFileNameKey]] != filePaths[[reactiveFileNameKey]])) {
              if (is.null(filePaths[[reactiveFileNameKey]])) {
                #cannot be null since it is used by reactiveFileReader in file.info so change to blank which does not cause an error
                filePaths[[reactiveFileNameKey]] <<- ""
              }
              debugConsole(paste0(reactiveFileNameKey,
                                  ": set to '",
                                  filePaths[[reactiveFileNameKey]],
                                  "'"))
              oldFilePaths[[reactiveFileNameKey]] <<-
                filePaths[[reactiveFileNameKey]]
            }
            returnValue <- filePaths[[reactiveFileNameKey]]
            if (is.null(returnValue)) {
              returnValue <-
                "" #cannot be null since it is used by reactiveFileReader in file.info.
            }
            return(returnValue)
          },
          #end filePath function
          #use a function so change of filePath will trigger refresh....
          readFunc = readFunc
        )#end reactiveFileReader
    } #end registerReactiveFileHandler

  startAsyncDataLoad <-
    function(asyncDataName, futureObj, callback = NULL) {
      debugConsole(paste0(
        "startAsyncDataLoad asyncDataName '",
        asyncDataName,
        "' called"
      ))
      checkAsyncDataBeingLoaded$suspend()
      asyncData[[asyncDataName]] <<- NULL
      asyncDataBeingLoaded[[asyncDataName]] <<-
        list(futureObj = futureObj,
             callback = callback)
      checkAsyncDataBeingLoaded$resume()
    } #end startAsyncDataLoad

  checkAsyncDataBeingLoaded <- observe({
    invalidateLater(DEFAULT_POLL_INTERVAL)
    for (asyncDataName in names(asyncDataBeingLoaded)) {
      asyncFutureObject <- asyncDataBeingLoaded[[asyncDataName]]$futureObj
      if (resolved(asyncFutureObject)) {
        debugConsole(paste0(
          "checkAsyncDataBeingLoaded resolved: '",
          asyncDataName,
          "'"
        ))
        #NOTE future will send any errors it caught when we ask it for the value -- same as if we had evaluated the expression ourselves
        tryCatch(
          expr = {
            asyncData[[asyncDataName]] <<- value(asyncFutureObject)
          },
          warning = function(w) {
            debugConsole(
              paste0(
                "checkAsyncDataBeingLoaded: '",
                asyncDataName,
                "' returned a warning: ",
                w
              )
            )
          },
          error = function(e) {
            debugConsole(
              paste0(
                "checkAsyncDataBeingLoaded: '",
                asyncDataName,
                "' returned an error: ",
                e
              )
            )
          }
        )#end tryCatch
        callback <- asyncDataBeingLoaded[[asyncDataName]]$callback
        asyncDataBeingLoaded[[asyncDataName]] <<- NULL
        if (!is.null(callback)) {
          callback(asyncDataName, asyncData[[asyncDataName]])
        }
      } #end if resolved
    }#end loop over async data items being loaded
    #if there are no more asynchronous data items being loaded then stop checking
    if (length(asyncDataBeingLoaded) == 0) {
      checkAsyncDataBeingLoaded$suspend()
    }
  }, suspended = TRUE) # checkAsyncDataBeingLoaded


  shinyFileSave(
    input = input,
    id = "copyModelDirectory",
    session = session,
    roots = volumeRoots
  )

  shinyFileChoose(
    input = input,
    id = "selectRunScript",
    session = session,
    roots = volumeRoots,
    filetypes = c("R")
  )

  observe({
    toggleState(
      id = "copyModelDirectory",
      condition = input$selectRunScript,
      selector = NULL
    )
  })

  SafeReadAndCleanLines <- function(filePath) {
    debugConsole(
      paste0(
        "SafeReadAndCleanLinesfunction called to load ",
        filePath,
        ". Exists? ",
        file.exists(filePath)
      )
    )
    fileContents <- SafeReadLines(filePath)
    results <- c()
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
  }

  getModuleProgress <- reactive({
    pattern <-
      "(?<date>^20[0-9]{2}(?:-[0-9]{2}){2}) (?<time>[^ ]+) :.*-- (?<actionType>(?:Finish|Start)(?:ing)?) module '(?<moduleName>[^']+)' for year '(?<year>[^']+)'"
    cleanedLogLines <- reactiveFileReaders[[VE_LOG]]()
    result <- data.table::data.table()
    if (length(cleanedLogLines) > 0) {
      modulesFoundInLogFile <-
        data.table::as.data.table(str_match_named(rev(cleanedLogLines), pattern))[!is.na(actionType),]
      if (nrow(modulesFoundInLogFile) > 0) {
        result <- modulesFoundInLogFile
      }
    }
    return(result)
  }) #end getModuleProgress

  registerReactiveFileHandler(
    VE_LOG,
    readFunc = function(filePath) {
      cleanedLines <- SafeReadAndCleanLines(filePath)
      debugConsole(paste0(
        "startModulesLogStatements",
        paste0(collapse = ", ", cleanedLines)
      ))
      return(cleanedLines)
    }
  ) #end VE_LOG file handler

  registerReactiveFileHandler(
    CAPTURED_SOURCE,
    readFunc = function(filePath) {
      debugConsole(
        paste0(
          "registerReactiveFileHandler for CAPTURED_SOURCE called to load ",
          filePath,
          ". Exists? ",
          file.exists(filePath)
        )
      )
      lines <- SafeReadLines(filePath)
      if (length(lines) > 1) {
        result <- paste0(collapse = "\n", lines)
      } else {
        result <- lines
      }
      return(result)
    }
  )
  registerReactiveFileHandler(MODEL_PARAMETERS_FILE, SafeReadJSON)
  registerReactiveFileHandler(RUN_PARAMETERS_FILE, SafeReadJSON)
  registerReactiveFileHandler(GEO_CSV_FILE, SafeReadCSV)

  registerReactiveFileHandler(
    MODEL_STATE_FILE,
    #use a function so change of filePath will trigger refresh....
    readFunc = function(filePath) {
      debugConsole(
        paste0(
          "MODEL_STATE_FILE function called to load ",
          filePath,
          ". Exists? ",
          file.exists(filePath)
        )
      )
      if (file.exists(filePath)) {
        env <- LoadToEnvironment(filePath)
        debugConsole(paste0(
          "MODEL_STATE_FILE loaded ",
          filePath,
          ". names(env): ",
          paste0(collapse = ", ", names(env))
        ))
        testit::assert(
          paste0(
            "'",
            filePath,
            "' must contain '",
            MODEL_STATE_LS,
            "' but has this instead: ",
            paste0(collapse = ", ", names(env))
          ),
          MODEL_STATE_LS %in% names(env)
        )
        myModelState_ls <-
          env[[MODEL_STATE_LS]]
        jsonOutput <-
          jsonlite::toJSON(myModelState_ls, pretty = TRUE)
        return(jsonOutput)
      } else {
        return("")
      }
    }# end readFunc
  ) #end call to registerReactiveFileHandler

  getScriptInfo <- eventReactive(input$selectRunScript, {
    debugConsole("getScriptInfo entered")
    scriptInfo <- list()
    inFile = parseFilePaths(roots = volumeRoots, input$selectRunScript)
    scriptInfo$datapath <-
      normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$fileBase <- basename(scriptInfo$datapath)

    #call the first few methods so can find out log file value and get the ModelState_ls global and therefore
    #then log file name
    setwd(scriptInfo$fileDirectory)
    if (exists(MODEL_STATE_LS)) {
      #delete any leftover
      rm("ModelState_ls")
    }
    visioneval::initModelStateFile()
    testit::assert(
      paste0(
        "After calls to visioneval initModelStateFile expect a global variable '",
        MODEL_STATE_LS,
        "' to exist"
      ),
      exists(MODEL_STATE_LS)
    )
    visioneval::initLog()
    visioneval::writeLog("VE_GUI called visioneval::initModelStateFile() and visioneval::initLog()")
    filePaths[[VE_LOG]] <<-
      file.path(scriptInfo$fileDirectory, ModelState_ls$LogFile)
    debugConsole(
      paste0(
        "after visioneval::initModelStateFile() and visioneval::initLog() global variable ModelState_ls has size: ",
        object.size(ModelState_ls)
      )
    )
    #store the current ModelState in the global options
    #so that the process will use the same log file as the one we have already started tracking...
    options("visioneval.preExistingModelState" = ModelState_ls)
    #finally remove it because this is a 'dead' copy -- visionEval will never update it since globals in Future
    #are different than the globals here
    rm(MODEL_STATE_LS)

    filePaths[[MODEL_STATE_FILE]] <<-
      file.path(scriptInfo$fileDirectory, "ModelState.Rda")
    getModelModules(scriptInfo$datapath)
    startAsyncDataLoad(
      MODEL_MODULES,
      future({
        getModelModules(scriptInfo$datapath)
      }),
      callback = function(asyncDataName, asyncData) {
        if (!is.null(asyncData)) {
          enable(id = "runModel", selector = NULL)
          enable(id = "copyModelDirectory", selector = NULL)
        }
        debugConsole(
          paste0(
            "callback asyncDataName '",
            asyncDataName,
            "' returning with data of size ",
            object.size(asyncData)
          )
        )
      }
    )

    defsDirectory <- file.path(scriptInfo$fileDirectory, "defs")

    filePaths[[MODEL_PARAMETERS_FILE]] <<-
      file.path(defsDirectory, "model_parameters.json")

    filePaths[[RUN_PARAMETERS_FILE]] <<-
      file.path(defsDirectory, "run_parameters.json")

    filePaths[[GEO_CSV_FILE]] <<-
      file.path(defsDirectory, "geo.csv")

    debugConsole("getScriptInfo exited")
    return(scriptInfo)
  }) #end getScriptInfo reactive

  getModelModules <- function(datapath) {
    debugConsole(paste0("getModelModules entered with datapath: ", datapath))
    setwd(dirname(datapath))
    modelModules <-
      visioneval::parseModelScript(datapath, TestMode = TRUE)
    return(modelModules)
  } #end getModelModules

  observeEvent(input$runModel, label = "runModel", handlerExpr = {
    req(input$selectRunScript)
    debugConsole("observeEvent input$runModel entered")
    datapath <- getScriptInfo()$datapath
    enable(id = "scriptOutput", selector = NULL)
    enable(id = "modeState", selector = NULL)
    disableActionButtons()
    startAsyncDataLoad(CAPTURED_SOURCE, future(getScriptOutput(datapath, filePaths[[CAPTURED_SOURCE]])),
                       function(asyncDataName, asyncData) {
                         enableActionButtons()
                         debugConsole(
                           paste0(
                             "callback asyncDataName '",
                             asyncDataName,
                             "' returning with data of size ",
                             object.size(asyncData)
                           )
                         )
                       })
    debugConsole("observeEvent input$runModel exited")
  }) #end runModel observeEvent

  disableActionButtons <- function() {
    disable(id = "selectRunScript", selector = NULL)
    disable(id = "runModel", selector = NULL)
    disable(id = "copyModelDirectory", selector = NULL)
  }

  enableActionButtons <- function() {
    enable(id = "selectRunScript", selector = NULL)
    enable(id = "runModel", selector = NULL)
    enable(id = "copyModelDirectory", selector = NULL)

  }

  getScriptOutput <- function(datapath, captureFile) {
    debugConsole("getScriptOutput entered")
    setwd(dirname(datapath))
    capture.output(source(datapath), file = captureFile)
    options("visioneval.preExistingModelState" = NULL)
    debugConsole("getScriptOutput exited")
    return(NULL)
  } #end getScriptOutput

  observeEvent(input$copyModelDirectory,
               label = "copyModelDirectory",
               handlerExpr = {
                 req(input$selectRunScript)
                 debugConsole("observeEvent input$copyModelDirectory entered")
                 datapath <- getScriptInfo()$datapath
                 disableActionButtons()
                 inCopy = parseSavePath(roots = volumeRoots, input$copyModelDirectory)
                 #suppressWarnings because the path does not yet exist
                 inCopyDirectory <-
                   suppressWarnings(normalizePath(as.character(inCopy$datapath)))
                 if (!dir.exists(inCopyDirectory)) {
                   if (file.exists(inCopyDirectory)) {
                     file.remove(inCopyDirectory)
                   }
                   dir.create(inCopyDirectory)
                   testit::assert(
                     paste0(
                       "Expect directory to exist after creation: '",
                       inCopyDirectory,
                       "'"
                     ),
                     dir.exists(inCopyDirectory)
                   )
                 }
                 fromDirectory <- dirname(datapath)
                 filesAndDirectoriesToCopy <-
                   list.files(fromDirectory,
                              full.names = TRUE,
                              recursive = FALSE)
                 file.copy(
                   from = filesAndDirectoriesToCopy,
                   to = inCopyDirectory,
                   recursive = TRUE,
                   overwrite = TRUE,
                   copy.date = TRUE,
                   copy.mode = TRUE
                 )
                 enableActionButtons()
                 debugConsole("observeEvent input$copyModelDirectory exited")
               }) #end copyModelDirectory observeEvent

  output[[DEBUG_CONSOLE_OUTPUT]] = renderDataTable({
    getScriptInfo()
    otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]]
  })

  output[[VE_LOG]] = renderText({
    getScriptInfo()
    paste0(collapse = "\n", reactiveFileReaders[[VE_LOG]]())
  })

  output[[GEO_CSV_FILE]] = renderDataTable({
    getScriptInfo()
    reactiveFileReaders[[GEO_CSV_FILE]]()
  })

  output[[RUN_PARAMETERS_FILE]] = renderText({
    getScriptInfo()
    reactiveFileReaders[[RUN_PARAMETERS_FILE]]()
  })

  output[[MODEL_PARAMETERS_FILE]] = renderText({
    getScriptInfo()
    reactiveFileReaders[[MODEL_PARAMETERS_FILE]]()
  })

  output[[MODEL_STATE_FILE]] = renderText({
    getScriptInfo()
    reactiveFileReaders[[MODEL_STATE_FILE]]()
  })

  output[[CAPTURED_SOURCE]] <- renderText({
    reactiveFileReaders[[CAPTURED_SOURCE]]()
  })

  output$scriptName = renderText({
    getScriptInfo()$datapath
  })

  output[[MODULE_PROGRESS]] = renderDataTable({
    getModuleProgress()
  })

  output[[MODEL_MODULES]] = renderDataTable({
    getScriptInfo()
    asyncData[[MODEL_MODULES]]
  })

  output[[EDIT_MODEL_PARAMETERS_SHOW]] <- reactive({
    otherReactiveValues[[EDIT_MODEL_PARAMETERS_SHOW]]
  })

  observeEvent(input[[EDIT_MODEL_PARAMETERS_BUTTON]], {
    otherReactiveValues[[EDIT_MODEL_PARAMETERS_SHOW]] = TRUE
  })

  observe({
    updateAceEditor(session,
                    MODEL_PARAMETERS_FILE_EDITOR,
                    reactiveFileReaders[[MODEL_PARAMETERS_FILE]]())
  })
} #end server

app <- shinyApp(ui, server)
