library(shiny)
library(shinyFiles)
library(visioneval)
library(DT)
library(data.table)
library(shinyBS)
library(future)

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
        tabPanel("Debug console",
                 DT::dataTableOutput("debugConsoleTable")),
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

  debugConsoleOutput <-
    data.table::data.table(message = character())

  shinyFileChoose(
    input = input,
    id = 'file',
    session = session,
    roots = getVolumes(),
    filetypes = c('R')
  )

  debugConsole <- function(msg) {
    timeStampedMsg <- paste0(Sys.time(), ": ", msg)
    flush.console()
    debugConsoleOutput <<-
      rbind(data.table::data.table(message = timeStampedMsg),
            debugConsoleOutput)
    print(paste0(nrow(debugConsoleOutput), ": ", timeStampedMsg))
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
    debugConsole("getScriptInfo exit")
    return(scriptInfo)
  }) #end reactive

  getParseInfo <- reactive({
    req(getScriptInfo()$fileDirectory)
    debugConsole("getParseInfo called")
    parseInfo <- list()
    scriptInfo <- getScriptInfo()
    setwd(scriptInfo$fileDirectory)
    # use trace to hook into visioneval::log
    trace(visioneval::writeLog,
          exit = quote(
            assign(
              "VEGUI_logOutput",
              envir = .GlobalEnv,
              value = rbind(
                data.table::data.table(message = Content),
                get("VEGUI_logOutput", envir = .GlobalEnv)
              )
            )
          ),
          print = FALSE)

    #must call initializeModel even though don't know the correct parameters
    #because otherwise parseModelScript gets an error: Warning:ror in getModelState: object 'ModelState_ls' not found
    visioneval::initializeModel()

    #makeReactiveBinding("ModelState_ls", env =.GlobalEnv)
    parseInfo$modelModules <-
      visioneval::parseModelScript(scriptInfo$datapath)
    debugConsole("getParseInfo exit")
    return(parseInfo)
  }) #end reactive


  getRunInfo <- eventReactive(input$runModel, {
    req(input$file)
    debugConsole("getRunInfo called")
    runInfo <- list()
    runInfo$datastoreList <- ""
    runInfo <- list()
    scriptInfo <- getScriptInfo()
    setwd(scriptInfo$fileDirectory)
    runInfo$scriptOutput <-
      future(capture.output(source(scriptInfo$datapath)))
    check_if_future_data_is_loaded$resume()
    return(runInfo)
  }) #end reactive


  check_if_future_data_is_loaded <- observe({
    req(getRunInfo)
    debugConsole("check_if_future_data_is_loaded called")
    invalidateLater(1000)
    runInfo <- getRunInfo()
    if (resolved(runInfo$scriptOutput)) {
      debugConsole(
        "check_if_future_data_is_loaded found resolved(runInfo$scriptOutput) == TRUE"
      )
      check_if_future_data_is_loaded$suspend()
      output$scriptOutput <- renderPrint({
        runInfo$scriptOutput
      })
    }
  }, suspended = TRUE)

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

  output$debugConsoleTable = DT::renderDataTable({
    DT::datatable(getDebugConsoleOutput())
  })

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

  output$veLogTable = DT::renderDataTable({
    DT::datatable(getVELogData())
  })

  # Re-execute this reactive expression after a set interval
  getModelState <- reactivePoll(
    1000,
    session,
    # This function returns the time that the logfile was last
    # modified
    checkFunc = function() {
      result <- -1
      if (class(ModelState_ls) == "list") {
        result <- file.mtime(getScriptInfo()$modelStateFile)
      }
      #debugConsole(paste0("getModelState checkFunc returning: ", result))
      return(result)
    },
    # This function returns the content of the logfile
    valueFunc = function() {
      ModelState_ls
    }
  ) #end reactivePoll getModelState

  output$modelState = renderPrint({
    getModelState()
  })

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  output$modulesTable = DT::renderDataTable({
    DT::datatable(getParseInfo()$modelModules)
  })

} #end server

app <- shinyApp(ui, server)
