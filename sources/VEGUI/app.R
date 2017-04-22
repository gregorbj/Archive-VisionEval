library(visioneval)
library(shiny)
library(shinyjs)
library(shinyFiles)
library(data.table)
library(shinyBS)
library(future)
library(testit)
library(jsonlite)
library(DT)

#https://github.com/tdhock/namedCapture
if (!require(namedCapture)) {
  if (!require(devtools)) {
    install.packages("devtools")
  }
  devtools::install_github("tdhock/namedCapture")
}
library(namedCapture)

if (!require(shinyTree)) {
  if (!require(devtools)) {
    install.packages("devtools")
  }
  devtools::install_github("trestletech/shinyTree")
}
library(shinyTree)

#DT options https://rstudio.github.io/DT/options.html
# only display the table, and nothing else
options(DT.options = list(dom = 't', rownames='f'))

#use of future in shiny: http://stackoverflow.com/questions/41610354/calling-a-shiny-javascript-callback-from-within-a-future
plan(multiprocess) #tell "future" library to use multiprocessing

if (interactive()) {
  options(shiny.reactlog = TRUE)
}

DEBUG_CONSOLE_OUTPUT <- "DEBUG_CONSOLE_OUTPUT"
MODEL_PARAMETERS_FILE <- "MODEL_PARAMETERS_FILE"
RUN_PARAMETERS_FILE <- "RUN_PARAMETERS_FILE"
GEO_CSV_FILE <- "GEO_CSV_FILE"
MODEL_STATE_FILE <- "MODEL_STATE_FILE"
MODEL_MODULES <- "MODEL_MODULES"
VE_LOG <- "VE_LOG"
CAPTURED_SOURCE <- "CAPTURED_SOURCE"
MODEL_STATE_LS <-
  "ModelState_ls"
SELECT_RUN_SCRIPT_BUTTON <- "SELECT_RUN_SCRIPT_BUTTON"
COPY_MODEL_BUTTON <- "COPY_MODEL_BUTTON"
RUN_MODEL_BUTTON <- "RUN_MODEL_BUTTON"
SCRIPT_NAME <- "SCRIPT_NAME"
INPUTS_TREE <- "INPUTS_TREE"
INPUTS_TREE_SELECTED_TEXT <- "INPUTS_TREE_SELECTED_TEXT"
OUTPUTS_TREE <- "OUTPUTS_TREE"
HDF5_TABLES <- "HDF5_TABLES"
INPUT_FILES <- "INPUT_FILES"
EDIT_INPUT_FILE_ID <- "EDIT_INPUT_FILE_ID"
EDIT_INPUT_FILE_LAST_CLICK <- "EDIT_INPUT_FILE_LAST_CLICK"

MODULE_PROGRESS <- "MODULE_PROGRESS"
PAGE_TITLE <- "Pilot Model Runner and Scenario Viewer"

volumeRoots = getVolumes("")

# Define UI for application
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(type = "text/css",
               ".recalculating { opacity: 1.0; }"),
    # resize to window: http://stackoverflow.com/a/37060206/283973
    tags$script(
      '$(document).on("shiny:connected", function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });
      $(window).resize(function(e) {
      Shiny.onInputChange("innerWidth", window.innerWidth);
      });'
                        ),

      tags$script("$(document).on('click', '#INPUT_FILES button', function () {
                  Shiny.onInputChange('EDIT_INPUT_FILE_ID',this.id);
                  Shiny.onInputChange('EDIT_INPUT_FILE_LAST_CLICK', Math.random())
                  });"),
    #end tag$script
    tags$meta(charset = "UTF-8"),
    tags$meta(name = "google", content = "notranslate"),
    tags$meta(`http-equiv` = "Content-Language", content = "en")
  ),
  #end tag$head
  titlePanel(windowTitle = PAGE_TITLE,
             title =
               div(
                 img(
                   src = "visioneval_logo.png",
                   height = 100,
                   width = 100,
                   style = "margin:10px 10px"
                 ),
                 PAGE_TITLE
               )
             ),


  navlistPanel(
    id="navlist",
    tabPanel(
      "Scenario",
      shinyFilesButton(
        id = SELECT_RUN_SCRIPT_BUTTON,
        label = "Select scenario script...",
        title = "Please select model run script",
        multiple = FALSE
      ),
      h3("Run script: "),
      verbatimTextOutput(SCRIPT_NAME, FALSE),
      shinySaveButton(
        id = COPY_MODEL_BUTTON,
        label = "Copy scenario...",
        title = "Please select location for new folder containing copy of current model",
        #must specify a filetype due to shinyFiles bug https://github.com/thomasp85/shinyFiles/issues/56
        #even though in my case I am creating a folder so don't care about the mime type
        filetype = list('hidden_mime_type' = c(""))
      )
    ),
    tabPanel(
      title="Settings",
      value="TAB_SETTINGS",
      h3("Model state"),
      verbatimTextOutput(MODEL_STATE_FILE, FALSE),
      h3("Model parameters"),
      verbatimTextOutput(MODEL_PARAMETERS_FILE, FALSE),
      h3("Geo File"),
      DT::dataTableOutput(GEO_CSV_FILE),
      h3("Run parameters"),
      verbatimTextOutput(RUN_PARAMETERS_FILE, FALSE)
    ),
    tabPanel("Module specifications",
             value="TAB_INPUTS",
             h3("Input files:"),
             DT::dataTableOutput(INPUT_FILES),
             h3("Datastore tables:"),
             DT::dataTableOutput(HDF5_TABLES),
             h3("Module specifications:"),
             "Currently Selected:",
             verbatimTextOutput(INPUTS_TREE_SELECTED_TEXT, placeholder = TRUE),
             shinyTree(INPUTS_TREE)
             ),
    tabPanel(
      "Run",
      value="TAB_RUN",
      actionButton(RUN_MODEL_BUTTON, "Run Model Script"),
      h3("Module progress:"),
      DT::dataTableOutput(MODULE_PROGRESS),
      h3("Modules in model:"),
      DT::dataTableOutput(MODEL_MODULES),
      h3("VisionEval console output:"),
      verbatimTextOutput(CAPTURED_SOURCE, FALSE)
    ),
    # tabPanel("Outputs",
    #          value="TAB_OUTPUTS",
    #          shinyTree(OUTPUTS_TREE),
    #          tags$label("To Be Implemented...")
    # ),
    tabPanel(
      "Logs (newest first) ",
      value="TAB_LOGS",
      h3("Log:"),
      DT::dataTableOutput(VE_LOG),
      h3("Console output:"),
      DT::dataTableOutput(DEBUG_CONSOLE_OUTPUT)
    )
  ) #end navlistPanel
  ) #end ui <- fluid page

DEFAULT_POLL_INTERVAL <- 500 #milliseconds


server <- function(input, output, session) {
  asyncData <-
    reactiveValues()
  asyncDataBeingLoaded <- list()

  otherReactiveValues <-
    reactiveValues() #WARNING- DON'T USE VARIABLES TO INITIALIZE LIST KEYS - the variable name will be used, not the value

  otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]] <-
    data.table::data.table(time = paste(Sys.time()), message = "Placeholder to be deleted")[-1, ]

  otherReactiveValues[[MODULE_PROGRESS]] <- data.table::data.table()

  reactiveFilePaths <-reactiveValues()

  reactiveFilePaths[[CAPTURED_SOURCE]] <-
    tempfile(pattern = "VEGUI_source_capture", fileext = ".txt")

  reactiveFileReaders <- list()

  debugConsole <- function(msg) {
    testit::assert("debugConsole was passed NULL!", !is.null(msg))
    time <- paste(Sys.time())
    newRow <- data.table::data.table(time = time, message = msg)
    existingRows <-
      isolate(otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]])
    otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]] <<-
      rbind(newRow,
            existingRows)
    print(paste0(nrow(isolate(
      otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]]
    )), ": ", time, ": ", msg))
    flush.console()
  }

  SafeReadJSON <- function(filePath) {
    debugConsole(paste0(
      "readJSON function called to load ",
      filePath,
      ". Exists? ",
      file.exists(filePath)
    ))
    if (file.exists(filePath)) {
      fileContent <- fromJSON(filePath)
      return(fileContent)
    } else {
      return("")
    }
  }# end SafeReadJSON

  SafeReadLines <- function(filePath) {
    debugConsole(paste0(
      "SafeReadLines called to load ",
      filePath,
      ". Exists? ",
      file.exists(filePath)
    ))
    result <- ""
    if (file.exists(filePath)) {
      result <- readLines(filePath)
    }
    return(result)
  }

  SafeReadCSV <- function(filePath) {
    debugConsole(paste0(
      "SafeReadCSV called to load ",
      filePath,
      ". Exists? ",
      file.exists(filePath)
    ))
    result <- ""
    if (file.exists(filePath)) {
      result <- read.csv(filePath)
    }
    return(result)
  }

  #http://stackoverflow.com/questions/38064038/reading-an-rdata-file-into-shiny-application
  # This function, borrowed from http://www.r-bloggers.com/safe-loading-of-rdata-files/, load the Rdata into a new environment to avoid side effects
  LoadToEnvironment <-
    function(filePath, env = new.env(parent = emptyenv())) {
      debugConsole(paste0(
        "LoadToEnvironment called to load ",
        filePath,
        ". Exists? ",
        file.exists(filePath)
      ))
      if (file.exists(filePath)) {
        load(filePath, env)
      }
      return(env)
    }

  registerReactiveFileHandler <-
    function(reactiveFileNameKey, readFunc = SafeReadLines) {
      debugConsole(
        paste0(
          "registerReactiveFileHandler called to register '",
          reactiveFileNameKey
          ,
          "' names(reactiveFileReaders): ",
          paste0(collapse = ", ", names(isolate(
            reactiveFileReaders
          )))
        )
      )
      reactiveFileReaders[[reactiveFileNameKey]] <<-
        reactiveFileReader(
          DEFAULT_POLL_INTERVAL,
          session,
          filePath = function() {
            returnValue <- reactiveFilePaths[[reactiveFileNameKey]]
            if (is.null(returnValue)) {
              returnValue <-
                "" #cannot be null since it is used by reactiveFileReader in file.info.
            }
            return(returnValue)
          },
          #end filePath function
          #use a function so change of filePath will trigger refresh....
          readFunc = readFunc
        )#end reactiveFileReader
    } #end registerReactiveFileHandler

  startAsyncDataLoad <-
    function(asyncDataName, futureObj, callback = NULL) {
      debugConsole(paste0(
        "startAsyncDataLoad asyncDataName '",
        asyncDataName,
        "' called"
      ))
      checkAsyncDataBeingLoaded$suspend()
      asyncData[[asyncDataName]] <<- NULL
      asyncDataBeingLoaded[[asyncDataName]] <<-
        list(futureObj = futureObj,
             callback = callback)
      checkAsyncDataBeingLoaded$resume()
    } #end startAsyncDataLoad

  checkAsyncDataBeingLoaded <- observe({
    invalidateLater(DEFAULT_POLL_INTERVAL)
    for (asyncDataName in names(asyncDataBeingLoaded)) {
      asyncFutureObject <- asyncDataBeingLoaded[[asyncDataName]]$futureObj
      if (resolved(asyncFutureObject)) {
        debugConsole(paste0(
          "checkAsyncDataBeingLoaded resolved: '",
          asyncDataName,
          "'"
        ))
        #NOTE future will send any errors it caught when we ask it for the value -- same as if we had evaluated the expression ourselves
        tryCatch(
          expr = {
            asyncData[[asyncDataName]] <<- value(asyncFutureObject)
          },
          warning = function(w) {
            debugConsole(
              paste0(
                "checkAsyncDataBeingLoaded: '",
                asyncDataName,
                "' returned a warning: ",
                w
              )
            )
          },
          error = function(e) {
            debugConsole(
              paste0(
                "checkAsyncDataBeingLoaded: '",
                asyncDataName,
                "' returned an error: ",
                e
              )
            )
          }
        )#end tryCatch
        callback <- asyncDataBeingLoaded[[asyncDataName]]$callback
        asyncDataBeingLoaded[[asyncDataName]] <<- NULL
        if (!is.null(callback)) {
          callback(asyncDataName, asyncData[[asyncDataName]])
        }
      } #end if resolved
    }#end loop over async data items being loaded
    #if there are no more asynchronous data items being loaded then stop checking
    if (length(asyncDataBeingLoaded) == 0) {
      checkAsyncDataBeingLoaded$suspend()
    }
  }, suspended = TRUE) # checkAsyncDataBeingLoaded


  shinyFileSave(
    input = input,
    id = COPY_MODEL_BUTTON,
    session = session,
    roots = volumeRoots
  )

  shinyFileChoose(
    input = input,
    id = SELECT_RUN_SCRIPT_BUTTON,
    session = session,
    roots = volumeRoots,
    filetypes = c("R")
  )

  observe({
    shinyjs::toggleState(id = COPY_MODEL_BUTTON,
                condition = input[[SELECT_RUN_SCRIPT_BUTTON]],
                selector = NULL)
  })

  #how to hide/show tabs https://github.com/daattali/advanced-shiny/blob/master/hide-tab/app.R
  observe({
    toggle(id=NULL, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], anim=TRUE, animType = "Slide", time = 0.25,
                    selector = "#navlist li a[data-value=TAB_SETTINGS]")

    toggle(id=NULL, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], anim=TRUE, animType = "Slide", time = 0.25,
           selector = "#navlist li a[data-value=TAB_INPUTS]")

    toggle(id=NULL, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], anim=TRUE, animType = "Slide", time = 0.25,
           selector = "#navlist li a[data-value=TAB_RUN]")

    toggle(id=NULL, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], anim=TRUE, animType = "Slide", time = 0.25,
           selector = "#navlist li a[data-value=TAB_OUTPUTS]")

    toggle(id=NULL, condition = input[[SELECT_RUN_SCRIPT_BUTTON]], anim=TRUE, animType = "Slide", time = 0.25,
           selector = "#navlist li a[data-value=TAB_LOGS]")

  })

  SafeReadAndCleanLines <- function(filePath) {
    debugConsole(
      paste0(
        "SafeReadAndCleanLinesfunction called to load ",
        filePath,
        ". Exists? ",
        file.exists(filePath)
      )
    )
    fileContents <- SafeReadLines(filePath)
    results <- vector('character') #a zero length vector unlike c() which is NULL
    for (line in fileContents) {
      if (nchar(trimws(line)) > 0) {
        #remove all leading and/or traiing spaces or quotes
        cleanLine <- gsub("^[ \"]+|[v\"]+$", "", line)
        if (nchar(cleanLine) > 0) {
          results <- c(results, cleanLine)
        }
      }
    } #end loop over lines
    return(results)
  }

  getModuleProgress <- reactive({
    pattern <-
      "(?<date>^20[0-9]{2}(?:-[0-9]{2}){2}) (?<time>[^ ]+) :.*-- (?<actionType>(?:Finish|Start)(?:ing)?) module '(?<moduleName>[^']+)' for year '(?<year>[^']+)'"
    cleanedLogLines <- reactiveFileReaders[[VE_LOG]]()
    result <- data.table::data.table()
    if (length(cleanedLogLines) > 0) {
      modulesFoundInLogFile <-
        data.table::as.data.table(namedCapture::str_match_named(rev(cleanedLogLines), pattern))[!is.na(actionType),]
      if (nrow(modulesFoundInLogFile) > 0) {
        result <- modulesFoundInLogFile
      }
    }
    return(result)
  }) #end getModuleProgress

  registerReactiveFileHandler(
    VE_LOG,
    readFunc = function(filePath) {
      cleanedLines <- SafeReadAndCleanLines(filePath)
      debugConsole(paste0(
        "VE_LOG",
        paste0(collapse = ", ", cleanedLines)
      ))
      return(rev(cleanedLines))
    }
  ) #end VE_LOG file handler

  registerReactiveFileHandler(
    CAPTURED_SOURCE,
    readFunc = function(filePath) {
      debugConsole(
        paste0(
          "registerReactiveFileHandler for CAPTURED_SOURCE called to load ",
          filePath,
          ". Exists? ",
          file.exists(filePath)
        )
      )
      lines <- SafeReadLines(filePath)
      if (length(lines) > 1) {
        result <- paste0(collapse = "\n", lines)
      } else {
        result <- lines
      }
      return(result)
    }
  )
  registerReactiveFileHandler(MODEL_PARAMETERS_FILE, SafeReadJSON)
  registerReactiveFileHandler(RUN_PARAMETERS_FILE, SafeReadJSON)
  registerReactiveFileHandler(GEO_CSV_FILE, SafeReadCSV)

  registerReactiveFileHandler(
    MODEL_STATE_FILE,
    #use a function so change of filePath will trigger refresh....
    readFunc = function(filePath) {
      debugConsole(
        paste0(
          "MODEL_STATE_FILE function called to load ",
          filePath,
          ". Exists? ",
          file.exists(filePath)
        )
      )
      if (file.exists(filePath)) {
        env <- LoadToEnvironment(filePath)
        debugConsole(paste0(
          "MODEL_STATE_FILE loaded ",
          filePath,
          ". names(env): ",
          paste0(collapse = ", ", names(env))
        ))
        testit::assert(
          paste0(
            "'",
            filePath,
            "' must contain '",
            MODEL_STATE_LS,
            "' but has this instead: ",
            paste0(collapse = ", ", names(env))
          ),
          MODEL_STATE_LS %in% names(env)
        )
        myModelState_Ls <-
          env[[MODEL_STATE_LS]]
        return(myModelState_Ls)
      } else {
        return("")
      }
    }# end readFunc
  ) #end call to registerReactiveFileHandler

  getScriptInfo <-
    eventReactive(input[[SELECT_RUN_SCRIPT_BUTTON]], {
      debugConsole("getScriptInfo entered")
      scriptInfo <- list()
      inFile = parseFilePaths(roots = volumeRoots, input[[SELECT_RUN_SCRIPT_BUTTON]])
      scriptInfo$datapath <-
        normalizePath(as.character(inFile$datapath))
      scriptInfo$fileDirectory <- dirname(scriptInfo$datapath)
      scriptInfo$fileBase <- basename(scriptInfo$datapath)

      #call the first few methods so can find out log file value and get the ModelState_ls global
      setwd(scriptInfo$fileDirectory)
      visioneval::initModelStateFile()
      visioneval::initLog()
      visioneval::writeLog("VE_GUI called visioneval::initModelStateFile() and visioneval::initLog()")
      otherReactiveValues[[MODEL_STATE_LS]] <<- ModelState_ls
      reactiveFilePaths[[VE_LOG]] <<-
        file.path(scriptInfo$fileDirectory, ModelState_ls$LogFile)
      debugConsole(
        paste0(
          "after visioneval::initModelStateFile() and visioneval::initLog() global variable ModelState_ls has size: ",
          object.size(ModelState_ls)
        )
      )
      reactiveFilePaths[[MODEL_STATE_FILE]] <<-
        file.path(scriptInfo$fileDirectory, "ModelState.Rda")
      getModelModules(scriptInfo$datapath)
      startAsyncDataLoad(
        MODEL_MODULES,
        future({
          ModelState_ls
          getModelModules(scriptInfo$datapath)
        }),
        callback = function(asyncDataName, asyncData) {
          if (!is.null(asyncData)) {
            enable(id = RUN_MODEL_BUTTON, selector = NULL)
            enable(id = COPY_MODEL_BUTTON, selector = NULL)
          }
          debugConsole(
            paste0(
              "callback asyncDataName '",
              asyncDataName,
              "' returning with data of size ",
              object.size(asyncData)
            )
          )
        }
      )

      defsDirectory <- file.path(scriptInfo$fileDirectory, "defs")

      reactiveFilePaths[[MODEL_PARAMETERS_FILE]] <<-
        file.path(defsDirectory, "model_parameters.json")

      reactiveFilePaths[[RUN_PARAMETERS_FILE]] <<-
        file.path(defsDirectory, "run_parameters.json")

      reactiveFilePaths[[GEO_CSV_FILE]] <<-
        file.path(defsDirectory, "geo.csv")

      debugConsole("getScriptInfo exited")
      return(scriptInfo)
    }) #end getScriptInfo reactive

  getModelModules <- function(datapath) {
    debugConsole(paste0("getModelModules entered with datapath: ", datapath))
    setwd(dirname(datapath))
    modelModules <-
      data.table::as.data.table(visioneval::parseModelScript(datapath, TestMode = TRUE))
    return(modelModules)
  } #end getModelModules

  observeEvent(input[[RUN_MODEL_BUTTON]], label = RUN_MODEL_BUTTON, handlerExpr = {
    req(input[[SELECT_RUN_SCRIPT_BUTTON]])
    debugConsole("observeEvent input$runModel entered")
    datapath <- getScriptInfo()$datapath
    enable(id = "scriptOutput", selector = NULL)
    enable(id = "modeState", selector = NULL)
    disableActionButtons()
    startAsyncDataLoad(CAPTURED_SOURCE, future(getScriptOutput(datapath, isolate(reactiveFilePaths[[CAPTURED_SOURCE]]))),
                       function(asyncDataName, asyncData) {
                         enableActionButtons()
                         debugConsole(
                           paste0(
                             "callback asyncDataName '",
                             asyncDataName,
                             "' returning with data of size ",
                             object.size(asyncData)
                           )
                         )
                       })
    debugConsole("observeEvent input$runModel exited")
  }) #end runModel observeEvent

  disableActionButtons <- function() {
    disable(id = SELECT_RUN_SCRIPT_BUTTON, selector = NULL)
    disable(id = RUN_MODEL_BUTTON, selector = NULL)
    disable(id = COPY_MODEL_BUTTON, selector = NULL)
  }

  enableActionButtons <- function() {
    enable(id = SELECT_RUN_SCRIPT_BUTTON, selector = NULL)
    enable(id = RUN_MODEL_BUTTON, selector = NULL)
    enable(id = COPY_MODEL_BUTTON, selector = NULL)

  }

  getScriptOutput <- function(datapath, captureFile) {
    debugConsole("getScriptOutput entered")
    #store the current ModelState in the global options
    #so that the process will use the same log file as the one we have already started tracking...
    options("visioneval.preExistingModelState" = ModelState_ls)
    setwd(dirname(datapath))
    capture.output(source(datapath), file = captureFile)
    options("visioneval.preExistingModelState" = NULL)
    debugConsole("getScriptOutput exited")
    return(NULL)
  } #end getScriptOutput

  observeEvent(input$copyModelDirectory,
               label = COPY_MODEL_BUTTON,
               handlerExpr = {
                 req(input$selectRunScript)
                 debugConsole("observeEvent input$copyModelDirectory entered")
                 datapath <- getScriptInfo()$datapath
                 disableActionButtons()
                 inCopy = parseSavePath(roots = volumeRoots, input$copyModelDirectory)
                 #suppressWarnings because the path does not yet exist
                 inCopyDirectory <-
                   suppressWarnings(normalizePath(as.character(inCopy$datapath)))
                 if (!dir.exists(inCopyDirectory)) {
                   if (file.exists(inCopyDirectory)) {
                     file.remove(inCopyDirectory)
                   }
                   dir.create(inCopyDirectory)
                   testit::assert(
                     paste0(
                       "Expect directory to exist after creation: '",
                       inCopyDirectory,
                       "'"
                     ),
                     dir.exists(inCopyDirectory)
                   )
                 }
                 fromDirectory <- dirname(datapath)
                 filesAndDirectoriesToCopy <-
                   list.files(fromDirectory,
                              full.names = TRUE,
                              recursive = FALSE)
                 file.copy(
                   from = filesAndDirectoriesToCopy,
                   to = inCopyDirectory,
                   recursive = TRUE,
                   overwrite = TRUE,
                   copy.date = TRUE,
                   copy.mode = TRUE
                 )
                 enableActionButtons()
                 debugConsole("observeEvent input$copyModelDirectory exited")
               }) #end copyModelDirectory observeEvent

  output[[DEBUG_CONSOLE_OUTPUT]] = renderDataTable({
    DT::datatable(otherReactiveValues[[DEBUG_CONSOLE_OUTPUT]], options = list(dom = 'ft'))
  })

  getInputsTree <- reactive({
    modules <- asyncData[[MODEL_MODULES]]

    scriptInfo <- getScriptInfo()
    #prepare for calling into visioneval for module specs
    setwd(scriptInfo$fileDirectory)
    packages <- sort(unique(modules[,PackageName]))

    root <- list()
    for(packageName in packages) {
      packageNode <- list()
      modulesInPackage <- sort(modules[PackageName == (packageName), ModuleName])
      for(moduleName in modulesInPackage) {
        ModuleSpecs_ls <- visioneval::processModuleSpecs(visioneval::getModuleSpecs(moduleName, packageName))
        semiFlattened <- semiFlatten(ModuleSpecs_ls, "ModuleSpecs_ls")
        packageNode[[moduleName]] <- semiFlattened
      } #end for moduleName
      root[[packageName]] <- packageNode
    } #end packageName
    return(root)
  }) #end getInputsTree <- reactive({

  semiFlatten <- function(node, ancestorPath) {
    if (is.list(node)) {
      #if a list does not have names, use the index in names as the name
      if (is.null(names(node))) {
        names(node) <- 1:length(node)
      }
      for (name in names(node)) {
        #replace node with semiFlattened node
        childPath <- paste0(ancestorPath, "-->", name)
        childNodeValue <- node[[name]]

        semiFlattenedChildNode <-
          semiFlatten(childNodeValue, childPath)
        attr(semiFlattenedChildNode, "ancestorPath") <-
          childPath
        #replace the child with the flattened version
        node[[name]] <- semiFlattenedChildNode
      } #end for loop over child nodes
    } # end if list
    else if (length(node) > 1) {
      #since not a list this is probably a vector of strings
      #need to convert to a list with the strings as the key and the value is irrelevant
      emptyListWithNumbersAsKeys <- lapply(1:length(node), function(i) "ignored-type-1")
      leafList <- setNames(emptyListWithNumbersAsKeys, node)
      node <- leafList
    } else {
      #must be a leaf but shinyTree requires even these be lists
      leafNode <- list()
      leafNode[[as.character(node)]] <- "ignored-type-2"
      node <- leafNode
    }
    return(node)
  } #end semiFlatten

  getInputFilesTable <- reactive({
    getInputsTree()
    fileItems <- extractFromTree("FILE")
    inputFilesDataTable <- unique(data.table::data.table(File = fileItems$resultList))
    return(inputFilesDataTable)
  })

  output[[INPUT_FILES]] = renderDataTable({
    DT <- getInputFilesTable()
    DT[["Actions"]]<-
      paste0('
             <div class="btn-group" role="group" aria-label="Basic example">
             <button type="button" class="btn btn-secondary edit" id=edite_',1:nrow(DT),'>Edit</button>
             </div>
             ')
    returnValue <- DT::datatable(DT,
              escape=F)
    return(returnValue)
  }) #end output[[INPUT_FILES]]

  #https://antoineguillot.wordpress.com/2017/03/01/three-r-shiny-tricks-to-make-your-shiny-app-shines-33-buttons-to-delete-edit-and-compare-datatable-rows
  observeEvent(input[[EDIT_INPUT_FILE_LAST_CLICK]], label = EDIT_INPUT_FILE_LAST_CLICK, handlerExpr = {
    buttonId <- input[[EDIT_INPUT_FILE_ID]]
    row_to_edit=as.numeric(gsub("edit_","",buttonId))
    DT <- getInputFilesTable()
    debugConsole(paste0("got click inside table. id: ", input[[EDIT_INPUT_FILE_ID]], "row to edit: ", row_to_edit, " fileName: ", DT[row_to_edit, File]))
  })

  output[[HDF5_TABLES]] = renderDataTable({
    getInputsTree()
    tableItems <- extractFromTree("TABLE")
    tables <- unique(data.table::data.table(File = tableItems$resultList))
                                            # TreePath = tableItems$resultAncestorsList))
    return(DT::datatable(tables))
  }) #end output[[HDF5_TABLES]]

  extractFromTree <- function(target) {
    resultList <- vector('character') #a zero length vector unlike c() which is NULL
    resultAncestorsList <- vector('character') #a zero length vector unlike c() which is NULL
    extractFilesFromTree <- function(node) {
      names <- names(node)
      for (name in names) {
        currentNode <- node[[name]]
        if (name == target) {
          targetValue <- names(currentNode)[[1]]
          ancestorPath <- getAncestorPath(currentNode)
          resultList <<- c(resultList, targetValue)
          resultAncestorsList <<- c(resultAncestorsList, ancestorPath)
        } else {
          extractFilesFromTree(currentNode) #RECURSIVE
        }
      } #end for loop over names
    } # end internal function
    extractFilesFromTree(getInputsTree())
    return(list("resultList" = resultList,
                "resultAncestorsList" = resultAncestorsList))
  } #end extractFromTree

  getAncestorPath <- function(leaf) {
    ancestorPath <- attr(leaf, "ancestorPath")
    return(ancestorPath)
  } #end getAncestorPath

  output[[INPUTS_TREE]] <- renderTree({
    getInputsTree()
  })

  output[[INPUTS_TREE_SELECTED_TEXT]] <- renderText({
    tree <- input[[INPUTS_TREE]]
    results <- ""
    if (!is.null(tree)) {
      selectedItemPaths <- list()
      selectedItems <- get_selected(tree)
      if (length(selectedItems) > 0) {
        for (selectedItemNumber in 1:length(selectedItems)) {
          selectedItem <- selectedItems[[selectedItemNumber]]
          #https://rdrr.io/cran/shinyTree/man/get_selected.html
          ancestry <-
            attr(selectedItem, "ancestry") # character vector
          selectedNode <- as.character(selectedItem)
          totalPath <- c(ancestry, selectedNode)
          isFile <- length(ancestry) > 0 && (ancestry[[length(ancestry)]] == "FILE")
          pathInfo <- list(
            "ancestry" = ancestry,
            "finalNode" = selectedNode,
            "fullPath" = paste0(collapse = "-->", totalPath),
            "isFile" = isFile
          )
          selectedItemPaths[[selectedItemNumber]] <- pathInfo
        } #end for over selected items
        results <- paste0(collapse="\n", lapply(selectedItemPaths,
                                                function(x) x$fullPath))
      } # end if tree has a selection
    } #end if tree exists
    return(results)
  }) #end output[[INPUTS_TREE_SELECTED_TEXT]]

  output[[VE_LOG]] = renderDataTable({
    getScriptInfo()
    logLines <- reactiveFileReaders[[VE_LOG]]()
    DT <- data.table::data.table(message = logLines)
    returnValue <- DT::datatable(DT)
    return(returnValue)
  })

  output[[GEO_CSV_FILE]] = renderDataTable({
    getScriptInfo()
    returnValue <- DT::datatable(reactiveFileReaders[[GEO_CSV_FILE]]())
    return(returnValue)
  })

  output[[RUN_PARAMETERS_FILE]] = renderText({
    getScriptInfo()
    jsonlite::toJSON(reactiveFileReaders[[RUN_PARAMETERS_FILE]](), pretty =
                       TRUE)
  })

  output[[MODEL_PARAMETERS_FILE]] = renderText({
    getScriptInfo()
    jsonlite::toJSON(reactiveFileReaders[[MODEL_PARAMETERS_FILE]](), pretty =
                       TRUE)
  })

  output[[MODEL_STATE_FILE]] = renderText({
    getScriptInfo()
    jsonlite::toJSON(reactiveFileReaders[[MODEL_STATE_FILE]](), pretty =
                       TRUE)
  })

  output[[CAPTURED_SOURCE]] <- renderText({
    reactiveFileReaders[[CAPTURED_SOURCE]]()
  })

  output[[SCRIPT_NAME]] = renderText({
    getScriptInfo()$datapath
  })

  output[[MODULE_PROGRESS]] = renderDataTable({
    returnValue <- DT::datatable(getModuleProgress())
    return(returnValue)
  })

  output[[MODEL_MODULES]] = renderDataTable({
    getScriptInfo()
    returnValue <- DT::datatable(asyncData[[MODEL_MODULES]])
    return(returnValue)
  })

} #end server

app <- shinyApp(ui, server)
