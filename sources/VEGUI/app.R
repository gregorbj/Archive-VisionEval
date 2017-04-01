library(shiny)
library(shinyFiles)
library(visioneval)
library(DT)
library(data.table)
library(shinyBS)

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
      bsAlert("parseProblems"),
      conditionalPanel(
        condition =  "true",
        #"input.file != null",

        h3("Script Name"),
        verbatimTextOutput('scriptName', TRUE),
        h3("Log"),
        DT::dataTableOutput("logTable"),
        h3("Modules"),
        DT::dataTableOutput("modulesTable"),
        h3("Model State"),
        verbatimTextOutput('modelState', FALSE),
        h3("Script Output"),
        verbatimTextOutput('scriptOutput', FALSE),
        h3("Datastore List"),
        verbatimTextOutput('datastoreList', FALSE)
      ) #end conditionalPanel
    ) #end mainPanel
  ) #end sidebarLayout
) #end ui


server <- function(input, output, session) {
  assign(
    "VEGUI_logOutput",
    value = data.table::data.table(message = character()),
    envir = .GlobalEnv
  )

  assign("ModelState_ls", value = "", envir = .GlobalEnv)

  shinyFileChoose(
    input = input,
    id = 'file',
    session = session,
    roots = getVolumes(),
    filetypes = c('R')
  )

  getScriptInfo <- reactive({
    req(input$file)
    print(paste0(Sys.time(), ": getScriptInfo called"))
    scriptInfo <- list()
    inFile = parseFilePaths(roots = getVolumes(''), input$file)
    scriptInfo$datapath <-
      normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$modelStateFile <- file.path(scriptInfo$fileDirectory, 'ModelState.Rda')
    scriptInfo$fileBase <- basename(scriptInfo$datapath)
    return(scriptInfo)
  }) #end reactive

  getParseInfo <- reactive({
    req(input$file)
    print(paste0(Sys.time(), ": getParseInfo called"))
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
    return(parseInfo)
  }) #end reactive


  getRunInfo <- eventReactive(input$runModel, {
    req(input$file)
    req(input$runModel)
    print(paste0(Sys.time(), ": getRunInfo called"))
    runInfo <- list()
    runInfo$datastoreList <- ""
    runInfo <- list()
    scriptInfo <- getScriptInfo()
    setwd(scriptInfo$fileDirectory)
    runInfo$scriptOutput = capture.output(source(scriptInfo$datapath))

    #read resulting datastore
    if (file.exists("ModelState.Rda")) {
      runInfo$datastoreList = capture.output(getModelState("Datastore"))
    } else {
      runInfo$datastoreList = "Temp fix for now: rerun model to read datastore"
    }
    return(runInfo)
  }) #end reactive

  #Don't know how to get shiny to auto update when VEGUI_logOutput changes so use a timer.. :-(
  # Re-execute this reactive expression after a set interval
  getLogData <- reactivePoll(
    100,
    session,
    # This function returns the time that the logfile was last
    # modified
    checkFunc = function() {
      nrow(VEGUI_logOutput)
    },
    # This function returns the content of the logfile
    valueFunc = function() {
      VEGUI_logOutput
    }
  ) #getLogData()

  # Re-execute this reactive expression after a set interval
  getModelState <- reactivePoll(
    100,
    session,
    # This function returns the time that the logfile was last
    # modified
    checkFunc = function() {
      if (class(ModelState_ls) == "list") {
        file.mtime(getScriptInfo()$modelStateFile)
      } else {
        -1
      }

    },
    # This function returns the content of the logfile
    valueFunc = function() {
      ModelState_ls
    }
  ) #end getModelState()

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })


  output$logTable = DT::renderDataTable({
    DT::datatable(getLogData())
  })

  output$modelState = renderPrint({
    getModelState()
  })

  output$modulesTable = DT::renderDataTable({
    DT::datatable(getParseInfo()$modelModules)
  })

  output$scriptOutput = renderPrint({
    getRunInfo()$scriptOutput
  })

  output$datastoreList = renderPrint({
    getRunInfo()$datastoreList
  })

} #end server

app <- shinyApp(ui, server)
