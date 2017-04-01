library(shiny)
library(shinyFiles)
library(visioneval)
library(DT)
library(shinyBS)

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

# Define UI for application
ui <- fluidPage(
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
        condition =  "true", #"input.file != null",

        h3("Script Name"),
        verbatimTextOutput('scriptName', TRUE),
        h3("Script Output"),
        verbatimTextOutput('scriptOutput', TRUE),
        h3("Datastore List"),
        verbatimTextOutput('datastoreList', TRUE),
        verbatimTextOutput('traceOutput', TRUE),
        fluidRow(
          DT::dataTableOutput("modulesTable")
        )
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
    setwd(scriptInfo$fileDirectory)
    #must call initializeModel even though don't know the correct parameters
    #because otherwise parseModelScript gets an error: Warning: Error in getModelState: object 'ModelState_ls' not found
    visioneval::initializeModel()
    scriptInfo$modelModules <- visioneval::parseModelScript(scriptInfo$datapath)
    return(scriptInfo)
  }) #end reactive

  getRunInfo <- eventReactive(input$runModel, {
    req(input$file)
    req(input$runModel)
    runInfo <- list()
    runInfo$datastoreList <- ""
    runInfo <- list()
    scriptInfo <- getScriptInfo()
    setwd(scriptInfo$fileDirectory)
    runInfo$traceOutput <- "CAN I SEE THIS?"
    foo <- "bar"
    trace(visioneval::initializeModel, tracer=function() {
      print("What the hey!")
      print(paste0("The value of foo: ", foo))
      print(paste0("Inside call runInfo$traceOutput: ", runInfo$traceOutput))
      runInfo$traceOutput <- "visioneval::initializeModel entered"
      print(paste0("Inside call after change runInfo$traceOutput: ", runInfo$traceOutput))
    }, print = FALSE)
    runInfo$scriptOutput = capture.output(source(scriptInfo$datapath))
    print(paste0("After call runInfo$traceOutput: ", runInfo$traceOutput))

    #read resulting datastore
    if (file.exists("ModelState.Rda")) {
      runInfo$datastoreList = capture.output(getModelState("Datastore"))
     } else {
      output$datastoreList = renderPrint({
        "Temp fix for now: rerun model to read datastore"
      })
    }
    return(runInfo)
  }) #end reactive

  output$modulesTable = DT::renderDataTable({
    DT::datatable(getScriptInfo()$modelModules)
    })

  output$scriptName = renderPrint({
    getScriptInfo()$datapath
  })

  output$scriptOutput = renderPrint({
    getRunInfo()$scriptOutput
  })

  output$traceOutput = renderPrint({
    getRunInfo()$traceOutput
  })

  output$datastoreList = renderPrint({
    getRunInfo()$datastoreList
  })

} #end server

app <- shinyApp(ui, server)
