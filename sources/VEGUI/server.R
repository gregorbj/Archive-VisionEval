library(shiny)
library(shinyFiles)
library(visioneval)

# Define server logic
shinyServer(function(input, output) {
    
    #file picker
    shinyFileChoose(input, 'file', root=getVolumes(''), filetypes=c('', 'R'))
    
    #run model on click
    observeEvent(input$file, {
      
      #parse script name
      inFile = parseFilePaths(roots=getVolumes(''), input$file)
      scriptName = as.character(inFile$datapath)
      output$filepath = renderPrint( { scriptName } ) 

    })
    
    #run model on click
    observeEvent(input$runmodel, {
      
      #parse script name
      inFile = parseFilePaths(roots=getVolumes(''), input$file)
      scriptName = as.character(inFile$datapath)
      
      #run model
      setwd(dirname(scriptName))
      output$scriptprint = renderPrint( { 
        capture.output(source(scriptName))
      } )
      
      #read resulting datastore
      if(file.exists("ModelState.Rda")) {
        datastorePrint = capture.output(getModelState("Datastore"))
        output$datastorelist = renderPrint( { datastorePrint } )
      } else {
        output$datastorelist = renderPrint( { "Temp fix for now: rerun model to read datastore" } )
      }

    })

})