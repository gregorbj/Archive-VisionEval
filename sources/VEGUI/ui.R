#============================================
#SECTION 3: DEFINE THE UI FOR APPLICATION
#============================================

# Define the webpage
ui <- fluidPage(

  useShinyjs(),

  tags$head(
    # resize to window: http://stackoverflow.com/a/37060206/283973

    tags$script(
      '$(document).on("shiny:connected", function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });
      $(window).resize(function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });'
    ), #end tag$script

    # FIXME: Modify so it also triggers events for Save and Cancel
    # we want to toggle off the file name and table in those cases too.
    tags$script(
      "$(document).on('click', '#INPUT_FILES button', function () {
      Shiny.onInputChange('EDIT_INPUT_FILE_ID',this.id);
      Shiny.onInputChange('EDIT_INPUT_FILE_LAST_CLICK', Math.random())
      });"
    ), #end tag$script  
    
    tags$meta(charset = "UTF-8"),
    tags$meta(name = "google", content = "notranslate"),
    tags$meta(`http-equiv` = "Content-Language", content = "en")
    
  ),     #end tag$head

  # Define title of the page
  titlePanel(windowTitle = paste('VisionEval', PAGE_TITLE),
             title = div(
               img(
                 src = "visioneval_logo.png",
                 height = 100,
                 width = 100,
                 style = "margin:10px 10px"
               ),
               PAGE_TITLE)
             ),  #end titlePanel

  # Setup a panel to select the model script from a local drive
  navlistPanel(
    id = "navlist",

    # Define Scenario Tab ---------------------------------------------------
    tabPanel(
      "Scenario",
      shinyFiles::shinyFilesButton( # Creates a window with a display of directories and files for selection of model script
        id = SELECT_RUN_SCRIPT_BUTTON,
        label = "Select scenario run script...",
        title = "Please select model run script",
        multiple = FALSE,
        class=list(R = "R")
        
      ), #end shinyFilesButton

      h3("Run script: "),
      verbatimTextOutput(SCRIPT_NAME, placeholder=TRUE),

      shinyFiles::shinySaveButton( # Creates a window with a display of directories and files for saving
        id = COPY_MODEL_BUTTON,
        label = "Copy scenario...",
        title = "Please select location for new folder containing copy of current model",
        list('hidden_mime_type' = c(""))
      ) #end shinySaveButton
      
    ), #end tabPanel

    # Define Settings Tab ------------------------------------------------
    tabPanel( # Defines the tab for displaying and changing the input parameters to the model.
      title = "Settings",
      value = TAB_SETTINGS,

      # TODO: parse the json file to a data.frame, then display using DT? or
      # rhandsontable
      
      h3("Model parameters"),
      #shinyAce does not support setting height by lines and the updateAceEditor does not
      #have a height parameter so not sure what to do...
      #https://github.com/trestletech/shinyAce/issues/4
      shinyAce::aceEditor(MODEL_PARAMETERS_FILE, height = (16 * 10), mode = "json"),
      fluidRow(column(3, actionButton(SAVE_MODEL_PARAMETERS_FILE, "Save Changes")),
               column(3, actionButton(REVERT_MODEL_PARAMETERS_FILE, "Revert Changes"))
               ),

      # TODO: parse the json file to a data.frame, then display using
      # rhandsontable
      h3("Run parameters"),
      shinyAce::aceEditor(RUN_PARAMETERS_FILE, height = (16 * 11), mode = "json"),
      fluidRow(column(3, actionButton(SAVE_RUN_PARAMETERS_FILE, "Save Changes")),
               column(3, actionButton(REVERT_RUN_PARAMETERS_FILE, "Revert Changes") )
               )

      #h3("Geo File"),
      #DT::dataTableOutput(GEO_CSV_FILE)

    ), #end tabPanel

    # Define Module Specifications Tab -------------------------------------
    tabPanel(
      "Inputs",
      value = TAB_INPUTS,

      h3("Input files:"),
      DT::dataTableOutput(INPUT_FILES),

      div(id = EDITOR_INPUT_DIV,
          verbatimTextOutput(EDITOR_INPUT_FILE_IDENTIFIER, FALSE),
          rhandsontable::rHandsontableOutput(EDITOR_INPUT_FILE_DT)
      ),
      br(),
      br()
      
      # h3("Datastore tables:"),
      # DT::dataTableOutput(HDF5_TABLES)

      # h3("Module specifications:"),

      # "Currently Selected:",
      # verbatimTextOutput(INPUTS_TREE_SELECTED_TEXT, placeholder = TRUE),
      
      # shinyTree::shinyTree(INPUTS_TREE)
      
    ), #end tabPanel

    # Define Run Tab ---------------------------------------------------------
    tabPanel(
      "Run",
      value = TAB_RUN,
      actionButton(RUN_MODEL_BUTTON, "Run Model Script"),
      
      h3("Module progress:"),
      DT::dataTableOutput(MODULE_PROGRESS),

      h3("Modules in model:"),
      DT::dataTableOutput(MODEL_MODULES),

      h3("VisionEval console output:"),
      verbatimTextOutput(CAPTURED_SOURCE, FALSE)

    ), #end tabPanel

    # Define Outputs Tab -----------------------------------------------------
    tabPanel(
      "Outputs",
      value = TAB_OUTPUTS,
      verbatimTextOutput(DATASTORE_TABLE_IDENTIFIER, FALSE),
      
      shinyFiles::shinySaveButton(
        id = DATASTORE_TABLE_EXPORT_BUTTON,
        label = "Export displayed datastore data...",
        title = "Please pick location and name for the exported data...",
        myFileTypes_ls
      ),

      actionButton(DATASTORE_TABLE_CLOSE_BUTTON, "Close Datastore table"),

      DT::dataTableOutput(VIEW_DATASTORE_TABLE),

      h3("Datastore: (click row to view and export)"),
      DT::dataTableOutput(DATASTORE_TABLE),

      h3("Model state"),
      verbatimTextOutput(MODEL_STATE_FILE, FALSE)
    ), #end tabPanel

    # Define Log Tab ---------------------------------------------------------
    tabPanel(
      "Logs (newest first)",
      value = TAB_LOGS,

      h3("Log:"),
      DT::dataTableOutput(VE_LOG),

      h3("Console output:"),
      DT::dataTableOutput(DEBUG_CONSOLE_OUTPUT)
    ) #end tabPanel
    
  ) #end navlistPanel
) #end ui <- fluid page
