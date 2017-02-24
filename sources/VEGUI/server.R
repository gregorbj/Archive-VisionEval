library(shiny)
library(shinyFiles)
library(visioneval)

# Define server logic
shinyServer(function(input, output) {
    
    #file picker
    shinyFileChoose(input, 'file', root=getVolumes(''), filetypes=c('', 'R'))
    
    #run model on file name change
    observeEvent(input$file, {
      
      #parse script name
      inFile = parseFilePaths(roots=getVolumes(''), input$file)
      scriptName = as.character(inFile$datapath)
      output$filepath = renderPrint( { scriptName } ) 
        
      #run model
      setwd(dirname(scriptName))
      output$scriptprint = renderPrint( { 
        capture.output(source(scriptName, local=FALSE)) #sourced in global environment
      } )
      
      #read resulting datastore
      datastorePrint = capture.output(getModelState("Datastore"))
      output$datastorelist = renderPrint( { datastorePrint } )

    })

})