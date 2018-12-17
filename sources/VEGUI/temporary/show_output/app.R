#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(DT)
library(rhandsontable)
library(data.table)

# Read in the data files
cat(getwd())

output_dir <- 'C:/Users/matt.landis/Git/VisionEval/sources/models/VERPAT/output'

data_ls <- lapply(list.files(output_dir, full.names = TRUE), function(x) data.table::fread(x))
names(data_ls) <- gsub('.csv', '', list.files(output_dir))


# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Application title
  titlePanel("Show VisionEval RPAT output"),

  mainPanel(  
      h3('Output'),
      
      uiOutput('outputTabset')
      
  ) # end mainPanel
)    # end fluidPage


# Define server logic
server <- function(input, output) {
   
  # Create dynamic tabs
  output$outputTabset <- renderUI({
    cat(paste(names(data_ls), collapse=', '), '\n')
    outputTabs <- lapply(seq_along(data_ls), function(i){
      
      tbl_name <- names(data_ls)[i]
      tbl_outputId <- paste0('dt_', tbl_name)
      btn_outputId <- paste0('download_btn_', tbl_name)
      
      tabPanel(tbl_name,
               rhandsontable::rHandsontableOutput(outputId=tbl_outputId),
               downloadButton(outputId=btn_outputId, label='Download data')
      )
    })
    do.call(tabsetPanel, outputTabs)
  })
  
  # Create data tables for each tab
  # See https://jrowen.github.io/rhandsontable/#right-click
  # for how to do the context menu options
  
  # Note that default filename is incorrect in RStudio browser but works in
  # a real browser
  observe(
    lapply(seq_along(data_ls), function(i){
      
      tbl_name <- names(data_ls)[i]
      tbl_outputId <- paste0('dt_', tbl_name)
      btn_outputId <- paste0('download_btn_', tbl_name)
      
      output[[tbl_outputId]] <- rhandsontable::renderRHandsontable({
        rhandsontable::hot_context_menu(
          rhandsontable::rhandsontable(data_ls[[i]], readOnly=TRUE),
          allowRowEdit = FALSE,
          allowColEdit = FALSE)
        }) # end renderRHandsontable
      
      output[[btn_outputId]] <- downloadHandler(
        filename = function() paste0(tbl_name, '.csv'),
        content = function(file){
          write.csv(rhandsontable::hot_to_r(input[[tbl_outputId]]),
                    file,
                    row.names=FALSE)
        },
        contentType = 'text/csv'
      ) # end downloadHandler
    })   # end lapply  
  )  # end observe
}  # end server

# Run the application 
shinyApp(ui = ui, server = server)

