library(shiny)
library(shinyFiles)
library(shinyjs)
library(visioneval)
library(DT)
library(shinyBS)

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

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
      conditionalPanel(
        condition =  "true", #"input.file != null",

        h3("Script Name"),
        verbatimTextOutput('scriptName', TRUE),
        h3("Script Output"),
        verbatimTextOutput('scriptOutput', TRUE),
        h3("Datastore List"),
        verbatimTextOutput('datastorelist', TRUE)
        #DT::dataTableOutput('parseModelScriptTable')
      ) #end conditionalPanel
    ) #end mainPanel
  ) #end sidebarLayout
) #end ui


server <- function(input, output, session) {

    shinyFileChoose(
    input = input,
    id = 'file',
    session = session,
    roots = getVolumes(),
    filetypes = c('R')
  )

  getScriptInfo <- reactive({
    req(input$file)
    scriptInfo <- list()
    inFile = parseFilePaths(roots = getVolumes(''), input$file)
    scriptInfo$datapath <-
      normalizePath(as.character(inFile$datapath))
    scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
    scriptInfo$fileBase <- basename(scriptInfo$datapath)
    scriptInfo$parsedModelScript <- parse(scriptInfo$datapath)

    callsToInitialize <- grepl("^initializeModel", scriptInfo$parsedModelScript)
    if (sum(callsToInitialize) != 1) {
      createAlert(
        session = session,
        anchorId = "parseProblems",
        title = "Invalid initializeModel",
        content = paste0(datapath, " should have one call to initializeModel")
      )
      return()
    } else {
    }
    return(scriptInfo)
  }) #end reactive

  #output$parseModelScriptTable = DT::renderDataTable(getScriptInfo()$parsedModelScript)

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

   observeEvent(input$resetScriptOutput, {
    reset("scriptOutput")
  })

  observeEvent(input$resetScriptName, {
    reset("scriptName")
  })

  #run model on click
  observeEvent(input$runModel, {
    reset("scriptOutput")
    reset("datastorelist")
    scriptInfo <- getScriptInfo()
    setwd(scriptInfo$fileDirectory)
    output$scriptOutput = renderPrint({
      capture.output(source(scriptInfo$datapath))
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

app <- shinyApp(ui, server)
