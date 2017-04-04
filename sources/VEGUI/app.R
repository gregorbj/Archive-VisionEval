library(shiny)
library(shinyFiles)
library(visioneval)
library(DT)
library(data.table)
library(shinyBS)
library(future)
library(testit)
library(shinyjs)

#use of future in shiny: http://stackoverflow.com/questions/41610354/calling-a-shiny-javascript-callback-from-within-a-future
plan(multiprocess) #tell "future" library to use multiprocessing

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

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

      actionButton("runModel", "Run Model Script"),

      width = 2

    ),

    mainPanel(
      tabsetPanel(
        tabPanel(
          "Main",
          bsAlert("parseProblems"),
          h3("Script Name"),
          verbatimTextOutput("scriptName", TRUE),
          h3("Modules"),
          DT::dataTableOutput("modulesTable")
        ),
        tabPanel("Model State",
                 verbatimTextOutput("modelState", FALSE)),
        tabPanel(
          "Debug console",
          h5("(most recent first)"),
          DT::dataTableOutput("debugConsoleTable")
        ),
        tabPanel("visioneval Log",
                 verbatimTextOutput("veLogTable", FALSE)),
        tabPanel(
          "script source output",
          verbatimTextOutput("scriptOutput", FALSE)
        )
      )
    ) #end mainPanel
  ) #end sidebarLayout
) #end ui

DEFAULT_POLL_INTERVAL <- 500 #milliseconds

server <- function(input, output, session) {

  MODEL_MODULES <- "modelModules"
  SCRIPT_OUTPUT <- "scriptOutput"
  asyncData <-
    reactiveValues(MODEL_MODULES = NULL, SCRIPT_OUTPUT = NULL)
  asyncDataBeingLoaded <- list()

  MODEL_STATE_LS <- "ModelState_ls" #global variable used by visioneval
  MODEL_STATE <- "modelState"
  VE_LOG <- "veLog"
  CAPTURED_SOURCE <- "capturedSource"

  filePaths <-
    list(VE_LOG = "", MODEL_STATE = "", CAPTURED_SOURCE = tempfile(pattern = "VEGUI_source_capture", fileext = ".txt"))

  oldFilePaths <- filePaths

  reactiveFileReaders <-
    reactiveValues(VE_LOG = NULL, MODEL_STATE = NULL, CAPTURED_SOURCE = NULL)

  SafeReadLines <- function(filePath) {
    debugConsole(paste0("SafeReadLines called to load ", filePath, ". Exists? ", file.exists(filePath)))
    result <- ""
    if (file.exists(filePath)) {
      result <- readLines(filePath)
    }
    return(result)
  }

  #http://stackoverflow.com/questions/38064038/reading-an-rdata-file-into-shiny-application
  # This function, borrowed from http://www.r-bloggers.com/safe-loading-of-rdata-files/, load the Rdata into a new environment to avoid side effects
  LoadToEnvironment <- function(filePath, env = new.env()) {
    debugConsole(paste0("LoadToEnvironment called to load ", filePath, ". Exists? ", file.exists(filePath)))
    if (file.exists(filePath)) {
      load(filePath, env)
    }
    return(env)
  }

  startAsyncDataLoad <- function(asyncDataName, futureObj) {
    debugConsole(paste0(
      "startAsyncDataLoad asyncDataName '",
      asyncDataName,
      "' entered"
    ))
    testit::assert(
      paste0(
        "startAsyncDataLoad called with asyncDataName: ",
        asyncDataName,
        " which is not is in asyncData",
        asyncDataName %in% names(asyncData)
      )
    )
    checkAsyncDataBeingLoaded$suspend()
    asyncDataBeingLoaded[[asyncDataName]] <<- futureObj
    checkAsyncDataBeingLoaded$resume()
    debugConsole(paste0(
      "startAsyncDataLoad asyncDataName '",
      asyncDataName,
      "' exited"
    ))
  } #end startAsyncDataLoad

  checkAsyncDataBeingLoaded <- observe({
    debugConsole(
      paste0(
        "checkAsyncDataBeingLoaded called. names(asyncDataBeingLoaded): ",
        names(asyncDataBeingLoaded)
      )
    )
    invalidateLater(1000)
    for (asyncDataName in names(asyncDataBeingLoaded)) {
      asyncFutureObject <- asyncDataBeingLoaded[[asyncDataName]]
      if (resolved(asyncFutureObject)) {
        asyncData[[asyncDataName]] <<- value(asyncFutureObject)
        asyncDataBeingLoaded[[asyncDataName]] <<- NULL
        debugConsole(paste0("checkAsyncDataBeingLoaded resolved: ", asyncDataName))
      }
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

  debugConsole <- function(msg) {
    time <- Sys.time()
    newRow <- data.table::data.table(time = time, message = msg)
    debugConsoleOutput <<-
      rbind(newRow,
            debugConsoleOutput)
    print(paste0(nrow(debugConsoleOutput), ": ", time, ": ", msg))
    flush.console()
  }

  getScriptInfo <- eventReactive(input$file, {
    debugConsole("getScriptInfo called")
    scriptInfo <- list()
    inFile = parseFilePaths(roots = getVolumes(""), input$file)
    scriptInfo$datapath <-
      normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$fileBase <- basename(scriptInfo$datapath)
    startAsyncDataLoad(MODEL_MODULES, future(getModelModules(scriptInfo$datapath)))
    filePaths$MODEL_STATE <<-
      file.path(scriptInfo$fileDirectory, "ModelState.Rda")
    # #use trace to hook into visioneval::log
    # trace(visioneval::writeLog,
    #       exit = quote(assign(
    #         "VEGUI_logOutput",
    #         envir = .GlobalEnv,
    #         value = rbind(
    #           data.table::data.table(message = Content),
    #           get("VEGUI_logOutput", envir = .GlobalEnv)
    #         )
    #       )),
    #       print = FALSE)
    debugConsole("getScriptInfo exit")
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
    enable(id = "scriptOutput", "")
    enable(id = "modeState", "")
    startAsyncDataLoad(SCRIPT_OUTPUT, future(getScriptOutput(datapath, filePaths$CAPTURED_SOURCE)))
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



  reactiveFileReaders[[VE_LOG]] <-
    reactiveFileReader(DEFAULT_POLL_INTERVAL,
                       session,
                       filePath = function() {
                         if (oldFilePaths$VE_LOG != filePaths$VE_LOG) {
                           debugConsole(paste0("VE_LOG: ", oldFilePaths$VE_LOG, " != ", filePaths$VE_LOG))
                           oldFilePaths$VE_LOG <<- filePaths$VE_LOG
                         }
                         return(filePaths$VE_LOG)
                       }, #use a function so change of filePath will trigger refresh....
                       readFunc = SafeReadLines)

  reactiveFileReaders[[MODEL_STATE]] <-
    reactiveFileReader(DEFAULT_POLL_INTERVAL,
                       session,
                       filePath = function() {
                         if (oldFilePaths$MODEL_STATE != filePaths$MODEL_STATE) {
                           debugConsole(paste0("MODEL_STATE: ", oldFilePaths$MODEL_STATE, " != ", filePaths$MODEL_STATE))
                           oldFilePaths$MODEL_STATE <<- filePaths$MODEL_STATE
                         }
                         return(filePaths$MODEL_STATE)
                         }, #use a function so change of filePath will trigger refresh....
                       readFunc = function(filePath) {
                         debugConsole(paste0("MODEL_STATE function called to load ", filePath, ". Exists? ", file.exists(filePath)))
                         if (file.exists(filePath)) {
                         env <- LoadToEnvironment(filePath)
                         testit::assert(
                           paste0("'", filePath, "' must contain '", MODEL_STATE_LS, "'"),
                           exists(MODEL_STATE_LS, envir = env)
                         )
                         ModelState_Ls <-
                           env[[MODEL_STATE_LS]]
                         filePaths$VE_LOG <<-
                           file.path(getScriptInfo()$fileDirectory,ModelState_Ls$LogFile)
                         return(ModelState_Ls)
                         } else {
                           return("")
                         }
                       })


  # Re-execute this reactive expression after a set interval
  reactiveFileReaders[[CAPTURED_SOURCE]] <-
    reactiveFileReader(DEFAULT_POLL_INTERVAL,
                       session,
                       filePath = function() {
                         if (oldFilePaths$CAPTURED_SOURCE != filePaths$CAPTURED_SOURCE) {
                           debugConsole(paste0(oldFilePaths$CAPTURED_SOURCE, " != ", filePaths$CAPTURED_SOURCE))
                           oldFilePaths$CAPTURED_SOURCE <<- filePaths$CAPTURED_SOURCE
                         }
                         return(filePaths$CAPTURED_SOURCE)
                       }, #use a function so change of filePath will trigger refresh....
                       readFunc = SafeReadLines) #end reactiveFileReader

  output$debugConsoleTable = DT::renderDataTable({
    DT::datatable(getDebugConsoleOutput())
  })

  output$veLogTable = renderPrint({
    reactiveFileReaders[[VE_LOG]]()
  })

  output$modelState = renderPrint({
    reactiveFileReaders[[MODEL_STATE]]()
  })

  output$scriptOutput <- renderPrint({
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
