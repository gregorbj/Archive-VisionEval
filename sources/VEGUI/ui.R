library(shiny)
library(shinyFiles)

# Define UI for application
shinyUI(fluidPage(

    titlePanel("Pilot Model Runner and Scenario Viewer"),

    sidebarLayout(
    
      sidebarPanel( 
        
        img(src="visioneval_logo.png", height=100, width=100, style="margin:10px 10px"),
    
        shinyFilesButton('file', label='Select Model Run Script', 
          title='Please select model run script', multiple=FALSE)
        
      ),
      
      mainPanel(
      
        h3("Script Name"),
        verbatimTextOutput('filepath', TRUE),
        h3("Script Output"),
        verbatimTextOutput('scriptprint', TRUE),
        h3("Datastore List"),
        verbatimTextOutput('datastorelist', TRUE)
      
      )
        
    )

))