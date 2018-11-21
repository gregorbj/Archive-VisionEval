#============================================
# DEFINE THE UI FOR APPLICATION
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

    # Modify appearance of notifications
    tags$style(
      HTML(".shiny-notification {
            position:fixed;
            top: 35%;
            left: 35%;
            font-size: larger;
            font-weight: bold;
            width: 15em;
            opacity: 0.8;
            }
            "
           )
      ),

    tags$meta(charset = "UTF-8"),
    tags$meta(name = "google", content = "notranslate"),
    tags$meta(`http-equiv` = "Content-Language", content = "en")#,

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
    widths=c(2,10),
    # Define Scenario Tab ---------------------------------------------------
    tabPanel(
      "Scenario",
      shinyFiles::shinyFilesButton( # Creates a window with a display of directories and files for selection of model script
        id = SELECT_RUN_SCRIPT_BUTTON,
        label = "Select scenario run script...",
        title = "Please select model run script",
        multiple = FALSE,
        buttonType='primary',
        class=list(R = "R")

      ), #end shinyFilesButton

      shinyFiles::shinySaveButton( # Creates a window with a display of directories and files for saving
        id = COPY_MODEL_BUTTON,
        label = "Copy scenario...",
        title = "Please select location for new folder containing copy of current model",
        buttonType='primary',
        list('hidden_mime_type' = c(""))
      ), #end shinySaveButton

      h3("Run script"),
      verbatimTextOutput(SCRIPT_NAME, placeholder=TRUE),

      h3("Modules in model"),
      DT::dataTableOutput(MODEL_MODULES)

    ), #end tabPanel

    # Define Settings Tab ------------------------------------------------
    tabPanel( # Defines the tab for displaying and changing the input parameters to the model.
      title = "Settings",
      value = TAB_SETTINGS,

      h3("Run parameters"),

      verbatimTextOutput(RUN_PARAMETERS_FILE),

      actionButton(SAVE_RUN_PARAMETERS_FILE,
                   "Save Changes",
                   icon=icon('save', lib='glyphicon'),
                   class = 'btn-primary'),

      actionButton(REVERT_RUN_PARAMETERS_FILE,
                   "Revert Changes",
                   icon = icon('remove', lib='glyphicon'), class='btn-primary'),

      br(),
      br(),

      rhandsontable::rHandsontableOutput(outputId = RUN_PARAMETERS_RHT),
      bsTooltip(id=RUN_PARAMETERS_RHT, title='Double-click to edit',
                placement='left'),



      h3("Model parameters"),

      verbatimTextOutput(MODEL_PARAMETERS_FILE),

      actionButton(SAVE_MODEL_PARAMETERS_FILE,
                   "Save Changes",
                   icon = icon('save', lib='glyphicon'), class='btn-primary'),

      actionButton(REVERT_MODEL_PARAMETERS_FILE,
                   "Revert Changes",
                   icon = icon('remove', lib='glyphicon'), class='btn-primary'),

      br(),
      br(),
      rhandsontable::rHandsontableOutput(outputId = MODEL_PARAMETERS_RHT),
      bsTooltip(id=MODEL_PARAMETERS_RHT, title='Double-click to edit',
                placement='left')

      #h3("Geo File"),
      #DT::dataTableOutput(GEO_CSV_FILE)

    ), #end tabPanel

    # Define Inputs Tab -------------------------------------
    tabPanel(
      "Inputs",
      value = TAB_INPUTS,

      h3("Input files"),
      selectInput(inputId=INPUT_FILES, label="",
                  choices=""),
      div(id = EDITOR_INPUT_DIV,
          verbatimTextOutput(EDITOR_INPUT_FILE_IDENTIFIER, FALSE),
                   actionButton(INPUT_FILE_SAVE_BUTTON,
                       "Save Changes",
                       icon = icon('save', lib='glyphicon'),
                       class='btn-primary'),

          actionButton(INPUT_FILE_REVERT_BUTTON,
                       "Revert Changes",
                       icon = icon('remove', lib='glyphicon'),
                       class='btn-primary'),
          br(),
          br(),
          rhandsontable::rHandsontableOutput(EDITOR_INPUT_FILE_RHT),
          bsTooltip(id=EDITOR_INPUT_FILE_RHT, title='Double-click to edit',
                    placement='left')

          )
    ), #end tabPanel

    # Define Run Tab ---------------------------------------------------------
    tabPanel(
      "Run",
      value = TAB_RUN,
      actionButton(RUN_MODEL_BUTTON, "Run Model", class='btn-primary'),

      h3("Module progress"),
      DT::dataTableOutput(MODULE_PROGRESS),

      h3("VisionEval console output"),
      verbatimTextOutput(CAPTURED_SOURCE, FALSE)

    ), #end tabPanel


    # Define Outputs Tab -----------------------------------------------------
    tabPanel(
      "Outputs",
      value = TAB_OUTPUTS,

      h3("Output files"),
      selectInput(OUTPUT_FILE, label="", choices=""),
      verbatimTextOutput(OUTPUT_FILE_PATH, placeholder=TRUE),
      downloadButton(outputId=OUTPUT_FILE_SAVE_BUTTON, label="Download data",
                     class="btn-primary"),
      br(),
      rhandsontable::rHandsontableOutput(OUTPUT_FILE_RHT)
    ) #end tabPanel

  ) #end navlistPanel
) #end ui <- fluid page
