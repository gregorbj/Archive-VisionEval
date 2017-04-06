library(shiny)
library(shinyFiles)
library(visioneval)
library(DT)
library(data.table)
library(shinyBS)
library(future)
library(testit)
library(shinyjs)
library(jsonlite)

#use of future in shiny: http://stackoverflow.com/questions/41610354/calling-a-shiny-javascript-callback-from-within-a-future
plan(multiprocess) #tell "future" library to use multiprocessing

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

MODEL_PARAMETERS_FILE <- "Model_Parameters_File"
RUN_PARAMETERS_FILE <- "Run_Parameters_File"
GEO_CSV_FILE <- "Geo_File"
MODEL_STATE <- "Model_State"
MODEL_MODULES <- "Model_Modules"
VE_LOG <- "visionEval_Log"
CAPTURED_SOURCE <- "run_module_output"


# Define UI for application
ui <- fluidPage(
  useShinyjs(),
  tags$head(tags$style(type = "text/css",
                       ".recalculating { opacity: 1.0; }")),
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
        "file",
        label = "Select Run Script",
        title = "Please select model run script",
        multiple = FALSE
      ),

      disabled(actionButton("runModel", "Run Model Script")),

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
          DT::dataTableOutput("modulesTable")
        ),
        tabPanel(MODEL_STATE,
                 verbatimTextOutput(MODEL_STATE, FALSE)),
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
          DT::dataTableOutput("debugConsoleTable")
        )
      )
    ) #end mainPanel
  ) #end sidebarLayout
) #end ui

DEFAULT_POLL_INTERVAL <- 500 #milliseconds


server <- function(input, output, session) {
  assign("intializeModelArguments",
         envir = .GlobalEnv,
         value = "foo")

  asyncData <-
    reactiveValues()
  asyncDataBeingLoaded <- list()
  # asyncData[[MODEL_MODULES]] <- data.table::data.table() #empty table as a placeholder until data arrives

  MODEL_STATE_LS <-
    "ModelState_ls" #global variable used by visioneval

  filePaths <-
    list()

  filePaths[[CAPTURED_SOURCE]] <-
    tempfile(pattern = "VEGUI_source_capture", fileext = ".txt")

  oldFilePaths <- filePaths
  reactiveFileReaders <- list()


  debugConsole <- function(msg) {
    testit::assert("debugConsole was passed NULL!", !is.null(msg))
    time <- Sys.time()
    newRow <- data.table::data.table(time = time, message = msg)
    debugConsoleOutput <<-
      rbind(newRow,
            debugConsoleOutput)
    print(paste0(nrow(debugConsoleOutput), ": ", time, ": ", msg))
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
  LoadToEnvironment <- function(filePath, env = new.env()) {
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
          "registerReactiveFileHandler called to register ",
          reactiveFileNameKey,
          "' names(reactiveFileReaders): ",
          paste0(collapse=", ", names(reactiveFileReaders))
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
            debugConsole(paste0("'", asyncDataName, "' returned a warning: ", w))
          },
          error = function(e) {
            debugConsole(paste0("'", asyncDataName, "' returned an error: ", e))
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

  debugConsoleOutput <-
    data.table::data.table(time = Sys.time(), message = "placeholder about to be deleted")

  #don't know how to create data.table with particular types without actually creating a row so need to delete it...
  debugConsoleOutput <-  debugConsoleOutput[-1] #removes all rows

  shinyFileChoose(
    input = input,
    id = "file",
    session = session,
    roots = getVolumes(),
    filetypes = c("R")
  )

  registerReactiveFileHandler(VE_LOG)
  registerReactiveFileHandler(CAPTURED_SOURCE)
  registerReactiveFileHandler(MODEL_PARAMETERS_FILE, SafeReadJSON)
  registerReactiveFileHandler(RUN_PARAMETERS_FILE, SafeReadJSON)
  registerReactiveFileHandler(GEO_CSV_FILE, SafeReadCSV)

  registerReactiveFileHandler(
    MODEL_STATE,
    #use a function so change of filePath will trigger refresh....
    readFunc = function(filePath) {
      debugConsole(paste0(
        "MODEL_STATE function called to load ",
        filePath,
        ". Exists? ",
        file.exists(filePath)
      ))
      if (file.exists(filePath)) {
        env <- LoadToEnvironment(filePath)
        testit::assert(
          paste0("'", filePath, "' must contain '", MODEL_STATE_LS, "'"),
          exists(MODEL_STATE_LS, envir = env)
        )
        ModelState_Ls <-
          env[[MODEL_STATE_LS]]
        filePaths[[VE_LOG]] <<-
          file.path(getScriptInfo()$fileDirectory, ModelState_Ls$LogFile)
        return(ModelState_Ls)
      } else {
        return("")
      }
    }# end readFunc
  ) #end call to registerReactiveFileHandler

  getScriptInfo <- eventReactive(input$file, {
    debugConsole("getScriptInfo entered")
    scriptInfo <- list()
    inFile = parseFilePaths(roots = getVolumes(""), input$file)
    scriptInfo$datapath <-
      normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$fileBase <- basename(scriptInfo$datapath)
    disable(id = "runModel", selector = NULL)
    startAsyncDataLoad(
      MODEL_MODULES,
      future(getModelModules(scriptInfo$datapath)),
      callback = function(asyncDataName, asyncData) {
        if (!is.null(asyncData)) {
          enable(id = "runModel", selector = NULL)
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
    filePaths[[MODEL_STATE]] <<-
      file.path(scriptInfo$fileDirectory, "ModelState.Rda")

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
    setwd(dirname(datapath))
    modelModules <-
      visioneval::parseModelScript(datapath, TestMode = TRUE)
    return(modelModules)
  } #end getModelModules

  observeEvent(input$runModel, label = "runModel", handlerExpr = {
    req(input$file)
    debugConsole("observeEvent input$runModel entered")
    datapath <- getScriptInfo()$datapath
    enable(id = "scriptOutput", selector = NULL)
    enable(id = "modeState", selector = NULL)
    disable(id = "file", selector = NULL)
    disable(id = "runModel", selector = NULL)
    startAsyncDataLoad(CAPTURED_SOURCE, future(getScriptOutput(datapath, filePaths[[CAPTURED_SOURCE]])),
                       function(asyncDataName, asyncData) {
                         enable(id = "file", selector = NULL)
                         enable(id = "runModel", selector = NULL)
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

  getScriptOutput <- function(datapath, captureFile) {
    debugConsole("getScriptOutput entered")
    setwd(dirname(datapath))
    capture.output(source(datapath), file = captureFile)
    debugConsole("getScriptOutput exited")
    return(NULL)
  }

  # Re-execute this reactive expression after a set interval
  getDebugConsoleOutput <- reactivePoll(
    DEFAULT_POLL_INTERVAL,
    session,
    # This function returns the time that the logfile was last
    # modified
    checkFunc = function() {
      result <- nrow(debugConsoleOutput)
      #debugConsole(paste0("getDebugConsoleOutput checkFunc returning: ", result))
      return(result)
    },
    # This function returns the content of the logfile
    valueFunc = function() {
      debugConsoleOutput
    }
  ) #end reactivePoll getDebugConsoleOutput

  output$debugConsoleTable = DT::renderDataTable({
    DT::datatable(getDebugConsoleOutput())
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

  output[[MODEL_STATE]] = renderPrint({
    reactiveFileReaders[[MODEL_STATE]]()
  })

  output[[CAPTURED_SOURCE]] <- renderPrint({
    reactiveFileReaders[[CAPTURED_SOURCE]]()
  })

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  output$modulesTable = DT::renderDataTable({
    DT::datatable(asyncData[[MODEL_MODULES]])
  })

} #end server

app <- shinyApp(ui, server)
