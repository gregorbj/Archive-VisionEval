library(shiny)
library(shinyFiles)
library(visioneval)
library(DT)
library(data.table)
library(shinyBS)
library(future)
library(testit)

#use of future in shiny: http://stackoverflow.com/questions/41610354/calling-a-shiny-javascript-callback-from-within-a-future
plan(multiprocess) #tell 'future' library to use multiprocessing

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

# Define UI for application
ui <- fluidPage(
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
        'file',
        label = 'Select Run Script',
        title = 'Please select model run script',
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
          verbatimTextOutput('scriptName', TRUE),
          h3("Modules"),
          DT::dataTableOutput("modulesTable")
        ),
        tabPanel("Model State",
                 verbatimTextOutput('modelState', FALSE)),
        tabPanel(
          "Debug console",
          h5("(most recent first)"),
          DT::dataTableOutput("debugConsoleTable")
        ),
        tabPanel("visioneval Log",
                 DT::dataTableOutput("veLogTable")),
        tabPanel(
          "script source output",
          verbatimTextOutput('scriptOutput', FALSE)
        )
      )
    ) #end mainPanel
  ) #end sidebarLayout
) #end ui


server <- function(input, output, session) {
  #VEGUI_logOutput must be in Global so that trace functions inside visioneval can write to it
  assign(
    "VEGUI_logOutput",
    value = data.table::data.table(message = character()),
    envir = .GlobalEnv
  )
  #ModelState_ls must be in Global because that is what visioneval creates -- this is just a placeholder
  assign("ModelState_ls", value = "", envir = .GlobalEnv)

  MODEL_MODULES <- "modelModules"
  SCRIPT_OUTPUT <- "scriptOutput"
  asyncData <-
    reactiveValues(MODEL_MODULES = NULL, SCRIPT_OUTPUT = NULL)
  asyncDataBeingLoaded <- list()

  startAsyncDataLoad <- function(asyncDataName, futureObj) {
    debugConsole(paste0("startAsyncDataLoad asyncDataName '", asyncDataName, "' entered"))
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
    debugConsole(paste0("startAsyncDataLoad asyncDataName '", asyncDataName, "' exited"))
  } #end startAsyncDataLoad

  checkAsyncDataBeingLoaded <- observe({
    debugConsole(paste0("checkAsyncDataBeingLoaded called. names(asyncDataBeingLoaded): ", names(asyncDataBeingLoaded)))
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
    id = 'file',
    session = session,
    roots = getVolumes(),
    filetypes = c('R')
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
    inFile = parseFilePaths(roots = getVolumes(''), input$file)
    scriptInfo$datapath <-
      normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$modelStateFile <-
      file.path(scriptInfo$fileDirectory, 'ModelState.Rda')
    scriptInfo$fileBase <- basename(scriptInfo$datapath)
    startAsyncDataLoad(MODEL_MODULES, future(getModelModules(scriptInfo$datapath)))
    debugConsole("getScriptInfo exit")
    return(scriptInfo)
  }) #end reactive

  getModelModules <- function(datapath) {
    setwd(dirname(datapath))
    # use trace to hook into visioneval::log
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

    #must call initializeModel even though don't know the correct parameters
    #because otherwise parseModelScript gets an error: Warning:ror in getModelState: object 'ModelState_ls' not found
    visioneval::initializeModel()

    modelModules <-
      visioneval::parseModelScript(datapath)
    return(modelModules)
  } #end getModelModules

  observeEvent(input$runModel, label="runModel", handlerExpr={
    req(input$file)
    debugConsole("observeEvent input$runModel entered")
    datapath <- getScriptInfo()$datapath
    startAsyncDataLoad(SCRIPT_OUTPUT, future(getScriptOutput(datapath)))
    debugConsole("observeEvent input$runModel entered")
  }) #end runModel observeEvent

getScriptOutput <- function(datapath) {
  debugConsole("getScriptOutput entered")
  setwd(dirname(datapath))
  scriptOutput <- capture.output(source(datapath))
  debugConsole("getScriptOutput exited")
  return(scriptOutput)
}

  #Don't know how to get shiny to auto update when VEGUI_logOutput changes so use a timer.. :-(
  # Re-execute this reactive expression after a set interval
  getDebugConsoleOutput <- reactivePoll(
    1000,
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

  #Don't know how to get shiny to auto update when VEGUI_logOutput changes so use a timer.. :-(
  # Re-execute this reactive expression after a set interval
  getVELogData <- reactivePoll(
    1000,
    session,
    # This function returns the time that the logfile was last
    # modified
    checkFunc = function() {
      result <- nrow(VEGUI_logOutput)
      #debugConsole(paste0("getVELogData checkFunc returning: ", result))
      return(result)
    },
    # This function returns the content of the logfile
    valueFunc = function() {
      VEGUI_logOutput
    }
  ) #end reactivePoll getVELogData

  # Re-execute this reactive expression after a set interval
  getModelState <- reactivePoll(
    1000,
    session,
    # This function returns the time that the logfile was last
    # modified
    checkFunc = function() {
      result <- -1
      localModelState <- get("ModelState_ls", envir=.GlobalEnv)
      classOFModelState <- class(localModelState)
      #debugConsole(paste0("class(ModelState_ls): ", classOFModelState))
      if (classOFModelState == "list") {
        result <- file.mtime(getScriptInfo()$modelStateFile)
      }
      #debugConsole(paste0("getModelState checkFunc returning: ", result))
      return(result)
    },
    # This function returns the content of the logfile
    valueFunc = function() {
      localModelState <- get("ModelState_ls", envir=.GlobalEnv)
      return(localModelState)
    }
  ) #end reactivePoll getModelState

  output$debugConsoleTable = DT::renderDataTable({
    DT::datatable(getDebugConsoleOutput())
  })

  output$veLogTable = DT::renderDataTable({
    print("output$veLogTable")
    DT::datatable(getVELogData())
  })

  output$modelState = renderPrint({
    getModelState()
  })

  output$scriptOutput <- renderPrint({
    asyncData[[SCRIPT_OUTPUT]]
  })

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  output$modulesTable = DT::renderDataTable({
    DT::datatable(asyncData[[MODEL_MODULES]])
  })

} #end server

app <- shinyApp(ui, server)
