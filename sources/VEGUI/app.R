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

volumeRoots = getVolumes("")

# Define UI for application
ui <- fluidPage(
  useShinyjs(),
  tags$head(tags$style(type = "text/css",
                       ".recalculating { opacity: 1.0; }"),
            # resize to window: http://stackoverflow.com/a/37060206/283973
            tags$script('$(document).on("shiny:connected", function(e) {
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
      tabsetPanel(
        tabPanel(
          "Main",
          bsAlert("parseProblems"),
          h3("Script Name"),
          verbatimTextOutput("scriptName", FALSE),
          h3("Modules"),
          dataTableOutput("modulesTable")
        ),
        tabPanel(MODEL_STATE_LS,
                 verbatimTextOutput(MODEL_STATE_LS, FALSE)),
        tabPanel(
          MODEL_STATE_FILE,
          verbatimTextOutput(MODEL_STATE_FILE, FALSE)
        ),
        tabPanel(
          MODEL_PARAMETERS_FILE,
          verbatimTextOutput(MODEL_PARAMETERS_FILE, FALSE)
        ),
        tabPanel(GEO_CSV_FILE,
                 verbatimTextOutput(GEO_CSV_FILE, FALSE)),
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
  assign("ModelState_ls",
         envir = .GlobalEnv,
         value = "placeholder_from_VE_GUI")

  asyncData <-
    reactiveValues()
  asyncDataBeingLoaded <- list()

  filePaths <-
    list()

  otherReactiveValues <-
    reactiveValues() #WARNING- DON'T USE VARIABLES TO INITIALIZE LIST KEYS - the variable name will be used, not the value

  otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]] <-
    data.table::data.table(time = Sys.time(), message = "Placeholder to be deleted")[-1,]

  filePaths[[CAPTURED_SOURCE]] <-
    tempfile(pattern = "VEGUI_source_capture", fileext = ".txt")

  oldFilePaths <- filePaths
  reactiveFileReaders <- list()


  debugConsole <- function(msg) {
    testit::assert("debugConsole was passed NULL!", !is.null(msg))
    time <- Sys.time()
    newRow <- data.table::data.table(time = time, message = msg)
    existingRows <- isolate(otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]])
    otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]] <<-
      rbind(newRow,
            existingRows)
    print(paste0(nrow(isolate(otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]])), ": ", time, ": ", msg))
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
      fileContent <- fromJSON(filePath)
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
          paste0(collapse = ", ", names(isolate(reactiveFileReaders)))
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
            debugConsole(paste0("checkAsyncDataBeingLoaded: '", asyncDataName, "' returned a warning: ", w))
          },
          error = function(e) {
            debugConsole(paste0("checkAsyncDataBeingLoaded: '", asyncDataName, "' returned an error: ", e))
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
  registerReactiveFileHandler(VE_LOG, readFunc = function(filePath) {
    fileContents <- SafeReadLines(filePath)
    startModulesLogStatements <- grep(pattern="-- Finishing module", x = fileContents, useBytes = TRUE, )
    print(paste0("startModulesLogStatements", startModulesLogStatements))
    return(fileContents)
  }) #end VE_LOG file handler
  registerReactiveFileHandler(CAPTURED_SOURCE)
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
        myModelState_Ls <-
          env[[MODEL_STATE_LS]]
        filePaths[[VE_LOG]] <<-
          file.path(getScriptInfo()$fileDirectory,
                    myModelState_Ls$LogFile)
        return(myModelState_Ls)
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

    #call the first few methods so can find out log file value and get the ModelState_ls global
    setwd(scriptInfo$fileDirectory)
    visioneval::initModelStateFile()
    visioneval::initLog()
    visioneval::writeLog("VE_GUI called visioneval::initModelStateFile() and visioneval::initLog()")
    otherReactiveValues[[MODEL_STATE_LS]] <<- ModelState_ls
    filePaths[[VE_LOG]] <<-
      file.path(scriptInfo$fileDirectory, ModelState_ls$LogFile)
    debugConsole(
      paste0(
        "after visioneval::initModelStateFile() and visioneval::initLog() global variable ModelState_ls has size: ",
        object.size(ModelState_ls)
      )
    )
    filePaths[[MODEL_STATE_FILE]] <<-
      file.path(scriptInfo$fileDirectory, "ModelState.Rda")
    getModelModules(scriptInfo$datapath)
    startAsyncDataLoad(
      MODEL_MODULES,
      future({
        ModelState_ls
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
    #store the current ModelState in the global options
    #so that the process will use the same log file as the one we have already started tracking...
    options("visioneval.preExistingModelState" = ModelState_ls)
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
    otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]]
  })

  output[[VE_LOG]] = renderPrint({
    reactiveFileReaders[[VE_LOG]]()
  })

  output[[GEO_CSV_FILE]] = renderPrint({
    reactiveFileReaders[[GEO_CSV_FILE]]()
  })

  output[[RUN_PARAMETERS_FILE]] = renderPrint({
    reactiveFileReaders[[RUN_PARAMETERS_FILE]]()
  })

  output[[MODEL_PARAMETERS_FILE]] = renderPrint({
    reactiveFileReaders[[MODEL_PARAMETERS_FILE]]()
  })

  output[[MODEL_STATE_FILE]] = renderPrint({
    reactiveFileReaders[[MODEL_STATE_FILE]]()
  })

  output[[MODEL_STATE_LS]] = renderPrint({
    otherReactiveValues[[MODEL_STATE_LS]]
  })

  output[[CAPTURED_SOURCE]] <- renderPrint({
    reactiveFileReaders[[CAPTURED_SOURCE]]()
  })

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  output$modulesTable = renderDataTable({
    asyncData[[MODEL_MODULES]]
  })

} #end server

app <- shinyApp(ui, server)
