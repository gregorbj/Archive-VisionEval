library(shiny)
library(shinyFiles)
library(shinyjs)
library(visioneval)
library(DT)
library(shinyBS)

# Define UI for application
ui <- fluidPage(
  useShinyjs(),
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
      actionButton("resetScriptOutput", "Reset script output"),
      actionButton("resetScriptName", "Reset script name"),

      width = 2

    ),

    mainPanel(
      bsAlert("parseProblems"),
      h3("Script Name"),
      verbatimTextOutput('scriptName', TRUE),
      h3("Script Output"),
      verbatimTextOutput('scriptOutput', TRUE),
      h3("Datastore List"),
      verbatimTextOutput('datastorelist', TRUE),
      DT::dataTableOutput('parseModelScriptTable')

    )

  )

) #end ui

server <- function(input, output, session) {
  shinyFileChoose(
    input = input,
    id = 'file',
    roots = c(wd = '.'),
    session = session,
    filetypes = c('R')
  )

  getScriptInfo <- reactive({
    scriptInfo <- list()
    inFile = parseFilePaths(roots = getVolumes(''), input$file)
    scriptInfo$datapath <- normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$fileBase <- basename(scriptInfo$datapath)
    scriptInfo$parsedModelScript <- parse(scriptInfo$datapath)
    if (sum(grepl("^initializeModel", scriptInfo$parsedModelScript)) != 1) {
      createAlert(
        session = session,
        anchorId = "parseProblems",
        title = "Invalid initializeModel",
        content = paste0(datapath, "should have one call to initializeModel")
      )
      return()
    } else {
      initializeExpressions <-
        parsedModelScript[grepl("^initializeModel", parsedModelScript)]
      script$paramDir <- initializeExpressions$ParamDir
      # initializeModel(
      #   ParamDir = "defs",
      #   RunParamFile = "run_parameters.json",
      #   GeoFile = "geo.csv",
      #   ModelParamFile = "model_parameters.json",
      #   LoadDatastore = NULL,
      #   IgnoreDatastore = FALSE,
      #   SaveDatastore = TRUE
      # )
    }
    return(scriptInfo)
  }) #end reactive

  output$parseModelScriptTable = DT::renderDataTable(getScriptInfo()$parsedModelScript)

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  getScriptOutput <- reactive({
    return(capture.output(source(getScriptInfo()$datapath)))
  })

  output$scriptOutput = renderPrint( {
    getScriptOutput()
  } )

  observeEvent(input$resetScriptOutput, {
    reset("scriptOutput")
  })

  observeEvent(input$resetScriptName, {
    reset("scriptName")
  })

  #run model on click
  observeEvent(input$runmodel, {
    reset("scriptOutput")
    reset("datastorelist")
    #run model
    setwd(script$fileDirectory)
    output$scriptOutput = renderPrint({
      capture.output(source(g$scriptName()))
    })

    #read resulting datastore
    if (file.exists("ModelState.Rda")) {
      datastorePrint = capture.output(getModelState("Datastore"))
      output$datastorelist = renderPrint({
        datastorePrint
      })
    } else {
      output$datastorelist = renderPrint({
        "Temp fix for now: rerun model to read datastore"
      })
    }

  })

} #end server

shinyApp(ui, server)
