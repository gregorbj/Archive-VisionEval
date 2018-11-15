
# This script builds an application that provides a user with
# an interface to select a VE Model script to run,
# modify the input parameters to the model, run the model, and observe the
# output of the model.



#============================================
# DEFINE THE SERVER FOR APPLICATION
#============================================

server <- function(input, output, session) {

  # Following variables are the reactive variables
  # 1. otherReactiveValues_rv
  # 2. reactiveFilePaths_rv
  # 3. getModuleProgress
  # 4. getModelModules
  # 5. getInputsTree

  # FUNCTIONS ---------------------------------------------------------------

  # Print all the messages out to the console
  debugConsole <- function(msg) {
    testit::assert("debugConsole was passed NULL!", !is.null(msg))
    time <- paste(Sys.time())
    newRow_dt <- data.table::data.table(time = time, message = msg)
    existingRows_dt <- isolate(otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]])
    otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]] <<- rbind(newRow_dt, existingRows_dt)
    print(paste0(nrow(isolate(otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]])),
                 ": ", time, ": ", msg))
    flush.console()
  } # end debugConsole

  # Read a json file
  SafeReadJSON <- function(filePath) {
    debugConsole(paste0("SafeReadJSON function called to load ",
                        filePath,". Exists? ",file.exists(filePath)))
    if (file.exists(filePath)) {
      fileContent_ls <- fromJSON(filePath)
      return(fileContent_ls)
    } else {
      return("")
    }
  }# end SafeReadJSON

  # Read an ASCII file
  SafeReadLines <- function(filePath) {
    debugConsole(paste0("SafeReadLines called to load ",
                        filePath,". Exists? ",file.exists(filePath)))
    result_vc <- ""
    if (file.exists(filePath)) {
      result_vc <- readLines(filePath)
    }
    return(result_vc)
  } #end SafeReadLines

  SafeReadAndCleanLines <- function(filePath) {
    debugConsole(paste0("SafeReadAndCleanLinesfunction called to load ",
                        filePath, ". Exists? ", file.exists(filePath)
                        )
                 ) #end SafeReadAndCleanLines
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
  } #end SafeReadAndCleanLines

  # Read a csv file
  SafeReadCSV <- function(filePath) {
    debugConsole(paste0("SafeReadCSV called to load ",
                        filePath,". Exists? ",file.exists(filePath)))
    result_dt <- ""
    if (file.exists(filePath)) {
      result_dt <- data.table::fread(filePath)
    }
    return(result_dt)
  } #end SafeReadCSV

  #http://stackoverflow.com/questions/38064038/reading-an-rdata-file-into-shiny-application
  # This function, borrowed from http://www.r-bloggers.com/safe-loading-of-rdata-files/,
  #load the Rdata into a new environment to avoid side effects
  LoadToEnvironment <- function(filePath, env = new.env(parent = emptyenv())) {
    debugConsole(paste0("LoadToEnvironment called to load ",
                        filePath,". Exists? ",file.exists(filePath)))
    if (file.exists(filePath)) {
      load(filePath, env)
    }
    return(env)
  }


  # Function that adds reactive objects that read files to a globally maintained list.
  registerReactiveFileHandler <- function(reactiveFileNameKey, readFunc = SafeReadLines) {
    debugConsole(paste0("registerReactiveFileHandler called to register '",
                        reactiveFileNameKey, "' names(reactiveFileReaders_ls): ",
                        paste0(collapse = ", ", names(isolate(reactiveFileReaders_ls)))
                        )
                 )
    reactiveFileReaders_ls[[reactiveFileNameKey]] <<-
      reactiveFileReader(DEFAULT_POLL_INTERVAL,
                         session,
                         filePath = function() {
                           returnValue <- reactiveFilePaths_rv[[reactiveFileNameKey]]
                           if (is.null(returnValue)){
                             returnValue <- "" #cannot be null since it is used by reactiveFileReader in file.info.
                           }
                           return(returnValue)
                         },
                         #end filePath function
                         #use a function so change of filePath will trigger refresh....
                         readFunc = readFunc
                         )#end reactiveFileReader
  } #end registerReactiveFileHandler

  # Buttons to disable when the model is running
  disableActionButtons <- function() {
    disable(id = SELECT_RUN_SCRIPT_BUTTON, selector = NULL)
    disable(id = RUN_MODEL_BUTTON, selector = NULL)
    disable(id = COPY_MODEL_BUTTON, selector = NULL)
  }

  # Buttons to enable when the model has finished running
  enableActionButtons <- function() {
    enable(id = SELECT_RUN_SCRIPT_BUTTON, selector = NULL)
    enable(id = RUN_MODEL_BUTTON, selector = NULL)
    enable(id = COPY_MODEL_BUTTON, selector = NULL)

  }

  # Gather the output of model run
  getScriptOutput <- function(datapath, captureFile) {
    #From now on we will get the current ModelState by reading the object stored on disk
    #store the current ModelState in the global options
    #so that the process will use the same log file as the one we have already started tracking...
    debugConsole('Calling readModelState')
    ModelState_ls <- readModelState()
    options("visioneval.preExistingModelState" = ModelState_ls)
    debugConsole("getScriptOutput entered")
    debugConsole(paste("Model output is captured in", captureFile))
    setwd(dirname(datapath))
    debugConsole(paste('Working directory is', getwd()))
    debugConsole(paste('Calling source on', datapath))
    capture.output(source(datapath), file = captureFile)
    debugConsole(paste('Captured source from', datapath))
    options("visioneval.preExistingModelState" = NULL)
    debugConsole("getScriptOutput exited")
    return(NULL)
  } #end getScriptOutput

  # Flattens the file path to be displayed
  semiFlatten <- function(node, ancestorPath) {
    #debugConsole('semiFlatten function entered')
    if (is.list(node)) {
      #if a list does not have names, use the index in names as the name
      if (is.null(names(node))) {
        names(node) <- 1:length(node)
      }
      for (name in names(node)) {
        #replace node with semiFlattened node
        childPath <- paste0(ancestorPath, "-->", name)
        childNodeValue <- node[[name]]
        semiFlattenedChildNode <- semiFlatten(childNodeValue, childPath)
        attr(semiFlattenedChildNode, "ancestorPath") <- childPath
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
      #must be a leaf but shinyTree requires even these to be lists
      if (!is.na(node)) {
        nodeString <- trimws(as.character(node))
      } else {
        nodeString = ""
      }
      if (nodeString == "") {
        nodeString <- "{empty}"
      }
      #icons https://shiny.rstudio.com/reference/shiny/latest/icon.html
      leafNode <- structure(list(), sticon = "signal")
      leafNode[[nodeString]] <- structure("ignored-type-2", sticon = "asterisk")
      node <- leafNode
    }
    #debugConsole('semiFlatten function about to exit')
    return(node)
  } #end semiFlatten

  # Write a function for rhandsontable so parameters are the same
  # whether it is used to create the table or in revertParameterFile
  createParamTable <- function(df){
    rht <- rhandsontable::rhandsontable(df,
                                 width="600",
                                 height="270",
                                 stretchH = 'all',
                                 useTypes=TRUE,
                                 readOnly=FALSE)
    hot_cols(rht, fixedColumnsLeft = 1)
  } # end createParamTable

  # Save the changes made to the parameters to the parameter file
  saveParameterFile <- function(parameterFileIdentifier) {
    debugConsole('Entered saveParameterFile')

    parameterTableId <- gsub(pattern = '_FILE',
                             replacement = '_RHT',
                             x = parameterFileIdentifier)

    editedContent <- input[[parameterTableId]]
    editedDf <- rhandsontable::hot_to_r(editedContent)

    filePath <- reactiveFilePaths_rv[[parameterFileIdentifier]]

    if (!is.null(editedDf) && nrow(editedDf) > 0) {
      file.rename(filePath, paste0(filePath, "_", format(Sys.time(), "%Y-%m-%d_%H-%M"),
                                   ".bak")
      )
      debugConsole(paste0("writing out '", filePath, "' with nrows: ",
                   nrow(editedDf), " ncols: ", ncol(editedDf)))

      if(basename(filePath) == 'model_parameters.json'){
        jsonlite::write_json(editedDf, filePath, pretty=TRUE)
      } else if ( basename(filePath) == 'run_parameters.json'){
        jsonlite::write_json(convertRunParam2Lst(editedDf), filePath, pretty=TRUE)
      } else {
        stop("File name ", filePath, "not recognized in saveParameterFile")
      }

    }
  } # end saveParameterFile

  # Revert the changes made to the parameter in the display window
  revertParameterFile <- function(parameterFileIdentifier) {
    debugConsole("Entered revertParameterFile")

    parameter_obj <- reactiveFileReaders_ls[[parameterFileIdentifier]]()

    if (parameterFileIdentifier == MODEL_PARAMETERS_FILE){
      df <- parameter_obj
    } else if ( parameterFileIdentifier == RUN_PARAMETERS_FILE) {
      df <- convertRunParam2Df(parameter_obj)
    } else {
      stop("parameterFileIdentifier: ", parameterFileIdentifier, "not recognized in revertParameterFile")
    }

    rhandsontable::renderRHandsontable({
      createParamTable(df)
    })
  } # end revertParameterFile

  extractFromTree <- function(target) {
    debugConsole('extractFromTree function entered')
    resultList <- vector('character') #a zero length vector unlike c() which is NULL
    resultAncestorsList <- vector('character') #a zero length vector unlike c() which is NULL
    extractItemFromTree <- function(node) {
      names <- names(node)
      for (name in names) {
        currentNode <- node[[name]]
        if (name == target) {
          targetValue <- names(currentNode)[[1]]
          ancestorPath <- getAncestorPath(currentNode)
          resultList <<- c(resultList, targetValue)
          resultAncestorsList <<- c(resultAncestorsList, ancestorPath)
        } else {
          extractItemFromTree(currentNode) #RECURSIVE
        }
      } #end for loop over names
    } # end internal function
    extractItemFromTree(getInputsTree())
    return(list(
      "resultList" = resultList,
      "resultAncestorsList" = resultAncestorsList
    ))
  } #end extractFromTree

  getAncestorPath <- function(leaf) {
    # debugConsole('getAncestorPath entered')
    ancestorPath <- attr(leaf, "ancestorPath")
    return(ancestorPath)
  } #end getAncestorPath


  # Functions for writing output data to a CSV

  # Create a function to check if a specified attributes
  # belongs to the variable
  attributeExist <- function(variable, attr_name){
    if(is.list(variable)){
      if(!is.na(variable[[1]])){
        attr_value <- variable[[attr_name]]
        if(!is.null(attr_value)) return(TRUE)
      }
    }
    return(FALSE)
  }

  makeDataFrame <- function(Table, GroupTableName, OutputData, OutputAttr){
    OutputAllYr <- data.frame()

    for ( year in getYears()){
      OutputIndex <- GroupTableName$Table %in% Table & GroupTableName$Group %in% year
      Output <- OutputData[OutputIndex]

      if ( Table %in% c('Azone', 'Bzone', 'Marea') ){
        names(Output) <- paste0(GroupTableName$Name[OutputIndex], "_",
                                OutputAttr[OutputIndex], "_")
      } else if ( Table %in% c('FuelType', 'IncomeGroup') ){
        names(Output) <- paste0(GroupTableName$Name[OutputIndex])
      } else {
        stop(Table, 'not found')
      }

      Output <- data.frame(Output, stringsAsFactors = FALSE)
      if( Table %in% c('Azone', 'Bzone', 'Marea') | year != ModelState_ls$BaseYear ){
        Output$Year <- year
        OutputAllYr <- rbindlist(list(OutputAllYr, Output), fill = TRUE)
      }
    }
    return(OutputAllYr)
  }

  exportOutputData <- function(datadir){
    # Get the model state
    ModelState_ls <- readModelState(FileName=reactiveFilePaths_rv[[MODEL_STATE_FILE]])
    Datastore <- ModelState_ls$Datastore

    # Collect the output of all the modules into a dataframe
    InputIndex <- sapply(Datastore$attributes, attributeExist, "FILE")

    splitGroupTableName <- strsplit(Datastore[!InputIndex, "groupname"], "/")
    maxLength <- max(unlist(lapply(splitGroupTableName, length)))
    GroupTableName <- do.call(rbind.data.frame, lapply(splitGroupTableName, function(x) c(x, rep(NA, maxLength-length(x)))))
    colnames(GroupTableName) <- c("Group", "Table", "Name")
    GroupTableName <- GroupTableName[complete.cases(GroupTableName),]


    OutputData <- apply(GroupTableName, 1, function(x){
      readFromTableRD(Name = x[3], Table = x[2], Group = x[1],
                      DstoreLoc=reactiveFilePaths_rv[[DATASTORE]],
                      ReadAttr = TRUE)
    })

    OutputAttr <- lapply(OutputData, function(x) attr(x, "UNITS"))


    # Write all the outputs by table

    output_dir <- reactiveFilePaths_rv[[OUTPUT_DIR]]
    if(!dir.exists(output_dir)){
      dir.create(output_dir)
    } else {
      system(paste("rm -rf", output_dir))
      dir.create(output_dir)
    }
    for ( tbl in c("Azone", "Bzone", "Marea", "FuelType", "IncomeGroup") ){
      if ( ! tbl %in% GroupTableName$Table ) next()
      debugConsole(paste('Writing out', tbl, '\n'))
      OutDf <- makeDataFrame(tbl, GroupTableName, OutputData, OutputAttr)

      if ( tbl == "IncomeGroup" ) tbl <- "JobAccessibility"
      filename <- file.path(output_dir, paste0(tbl, ".csv"))
      fwrite(OutDf, file = filename)
    }

    # Call reactiveFilePaths_rv[[OUTPUT_DIR]] to trigger refresh of
    # the list on outputs page

    reactiveFilePaths_rv[[OUTPUT_DIR]] <- ''
    reactiveFilePaths_rv[[OUTPUT_DIR]] <- output_dir
  }


  # Reactive values ------------------------------------------------------------------------

  otherReactiveValues_rv <- reactiveValues() #WARNING- DON'T USE VARIABLES TO INITIALIZE LIST KEYS - the variable name will be used, not the value

  otherReactiveValues_rv[[DEBUG_CONSOLE_OUTPUT]] <- data.table::data.table(time = character(), message = character())

  otherReactiveValues_rv[[MODULE_PROGRESS]] <- data.table::data.table()

  reactiveFilePaths_rv <- reactiveValues()

  reactiveFilePaths_rv[[CAPTURED_SOURCE]] <- tempfile(pattern = "VEGUI_source_capture", fileext = ".txt")

  reactiveFileReaders_ls <- list() # A list of reactive variables


  # Get the progress of modules
  getModuleProgress <- reactive({
    pattern <- "(?<date>^20[0-9]{2}(?:-[0-9]{2}){2}) (?<time>[^ ]+) :.*-- (?<actionType>(?:Finish|Start)(?:ing)?) module '(?<moduleName>[^']+)' for year '(?<year>[^']+)'"
    cleanedLogLines <- reactiveFileReaders_ls[[VE_LOG]]() # reactiveFileReaders_ls[[VE_LOG]]: reactive value
    result_dt <- data.table::data.table()
    if (length(cleanedLogLines) > 0) {
      modulesFoundInLogFile_dt <- data.table::as.data.table(namedCapture::str_match_named(cleanedLogLines, pattern))[!is.na(actionType),]
      if (nrow(modulesFoundInLogFile_dt) > 0) {
        result_dt <- modulesFoundInLogFile_dt
      }
    }
    return(result_dt)
  }) #end getModuleProgress

  registerReactiveFileHandler(VE_LOG, readFunc = function(filePath) {
    cleanedLines <- SafeReadAndCleanLines(filePath)
    return(rev(cleanedLines))
  }
  ) #end VE_LOG file handler

  registerReactiveFileHandler(DATASTORE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for DATASTORE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    if (!file.exists(filePath)) {
      returnValue_dt <- NULL
    } else {
      G <- readModelState()
      table_dt <- data.table::data.table(G$Datastore)
      if(nrow(table_dt) > 0){
        table_attributes_ls <- table_dt[,attributes]
        table_groups_present <- sapply(table_attributes_ls, function(x) "LENGTH" %in% names(x))
        table_dt <- table_dt[table_groups_present,.(Group = group,Name = name)]
        returnValue_dt <- table_dt#[!Name %in% getYears()]
      } else {
        returnValue_dt <- NULL
      }
    }
    return(returnValue_dt)
  }
  ) #end DATASTORE

  registerReactiveFileHandler(CAPTURED_SOURCE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for CAPTURED_SOURCE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    lines <- SafeReadLines(filePath)
    if (length(lines) > 1) {
      result <- paste0(collapse = "\n", lines)
    } else {
      result <- lines
    }
    return(result)
  }
  )

  registerReactiveFileHandler(MODEL_PARAMETERS_FILE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for MODEL_PARAMETERS_FILE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    return(SafeReadJSON(filePath))}
    )
  registerReactiveFileHandler(RUN_PARAMETERS_FILE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for RUN_PARAMETERS_FILE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    return(SafeReadJSON(filePath))}
    )

  registerReactiveFileHandler(GEO_CSV_FILE, readFunc = function(filePath) {
    debugConsole(paste0("registerReactiveFileHandler for GEO_CSV_FILE called to load ",
                        filePath, ". Exists? ", file.exists(filePath)))
    return(SafeReadCSV(filePath))}
    )

  registerReactiveFileHandler(MODEL_STATE_FILE,
                              #use a function so change of filePath will trigger refresh....
                              readFunc = function(filePath) {
                                debugConsole(paste0("MODEL_STATE_FILE function called to load ",
                                                    filePath, ". Exists? ", file.exists(filePath)
                                                    )
                                             )
                                if (file.exists(filePath)) {
                                  env <- LoadToEnvironment(filePath)
                                  debugConsole(paste0("MODEL_STATE_FILE loaded ", filePath,
                                                      ". names(env): ", paste0(collapse = ", ",
                                                                               names(env)))
                                               )
                                  testit::assert(paste0("'", filePath, "' must contain '",
                                                        MODEL_STATE_LS,
                                                        "' but has this instead: ",
                                                        paste0(collapse = ", ", names(env))),
                                                 MODEL_STATE_LS %in% names(env))
                                  myModelState_ls <- env[[MODEL_STATE_LS]]
                                  return(myModelState_ls)
                                } else {
                                  return("")
                                }
                              }# end readFunc
                              ) #end call to registerReactiveFileHandler

  # Get the information about the scipt like paths to the scripts and input files
  getScriptInfo <- eventReactive(input[[SELECT_RUN_SCRIPT_BUTTON]],
                                 ignoreNULL = TRUE,
                                 ignoreInit=TRUE, valueExpr={
      debugConsole("getScriptInfo entered")
      debugConsole(paste('SELECT_RUN_SCRIPT_BUTTON:', input[[SELECT_RUN_SCRIPT_BUTTON]]))

      scriptInfo_ls <- list()

      if ( ! 'integer' %in% class(input[[SELECT_RUN_SCRIPT_BUTTON]])){

        inFile <- parseFilePaths(roots = volumeRoots, input[[SELECT_RUN_SCRIPT_BUTTON]])
        scriptInfo_ls$datapath <- normalizePath(as.character(inFile$datapath))
        scriptInfo_ls$fileDirectory <- dirname(scriptInfo_ls$datapath)
        scriptInfo_ls$fileBase <- basename(scriptInfo_ls$datapath)

        debugConsole(paste("getScriptInfo:", scriptInfo_ls$datapath))

        #call the first few methods so can find out log file value and get the ModelState_ls global
        setwd(scriptInfo_ls$fileDirectory)
        visioneval::initModelStateFile()
        visioneval::initLog()
        visioneval::writeLog("VE_GUI called visioneval::initModelStateFile() and visioneval::initLog()")

        #From now on we will get the current ModelState by reading the object stored on disk
        reactiveFilePaths_rv[[MODEL_STATE_FILE]] <- file.path(scriptInfo_ls$fileDirectory, "ModelState.Rda")

        reactiveFilePaths_rv[[VE_LOG]] <- file.path(scriptInfo_ls$fileDirectory, readModelState()$LogFile)
        reactiveFilePaths_rv[[DATASTORE]] <- file.path(scriptInfo_ls$fileDirectory, readModelState()$DatastoreName)

        defsDirectory <- file.path(scriptInfo_ls$fileDirectory, "defs")

        reactiveFilePaths_rv[[MODEL_PARAMETERS_FILE]] <- file.path(defsDirectory, "model_parameters.json")

        reactiveFilePaths_rv[[RUN_PARAMETERS_FILE]] <- file.path(defsDirectory, "run_parameters.json")

        reactiveFilePaths_rv[[GEO_CSV_FILE]] <- file.path(defsDirectory, "geo.csv")

        reactiveFilePaths_rv[[OUTPUT_DIR]] <- file.path(scriptInfo_ls$fileDirectory, 'outputs')

        #move to the settings tab
        #updateNavlistPanel(session, "navlist", selected = TAB_SETTINGS)
      }

      debugConsole("getScriptInfo exited")
      return(scriptInfo_ls)
    }) #end getScriptInfo reactive

  getModelModules <- reactive({
    if ( ! 'integer' %in% class(input[[SELECT_RUN_SCRIPT_BUTTON]]) ){
      datapath <- getScriptInfo()$datapath
      debugConsole(paste0("getModelModules entered with datapath: ", datapath))
      setwd(dirname(datapath))
      modelModules_dt <- data.table::as.data.table(visioneval::parseModelScript(datapath, TestMode = TRUE))
      debugConsole('getModelModules has finished')
      return(modelModules_dt)
    } else {
      return(NULL)
    }
  }) #end getModelModules

    # Get a tree structure of inputs to the model
  getInputsTree <- reactive({
    debugConsole('getInputsTree entered')
    modules <- getModelModules()
    scriptInfo <- getScriptInfo()

    root_ls <- list()

    if ( length(scriptInfo) > 0 ){

      #prepare for calling into visioneval for module specs
      setwd(scriptInfo$fileDirectory)
      packages <- sort(unique(modules[, PackageName]))

      for (packageName in packages) {
        packageNode <- list()
        modulesInPackage <- sort(modules[PackageName == (packageName), ModuleName])
        for (moduleName in modulesInPackage) {
          ModuleSpecs_ls <- visioneval::processModuleSpecs(
            visioneval::getModuleSpecs(moduleName, packageName)
          )
          semiFlattened <- semiFlatten(ModuleSpecs_ls, "ModuleSpecs_ls")
          packageNode[[moduleName]] <- semiFlattened
        } #end for moduleName
        root_ls[[packageName]] <- packageNode
      } #end packageName
    }
    debugConsole('getInputsTree about to exit')
    return(root_ls)
  }) #end getInputsTree

  getInputFiles <- reactive({
    debugConsole('getInputFiles entered')
    fileItems <- list()
    if ( ! 'integer' %in% class(input[[SELECT_RUN_SCRIPT_BUTTON]]) ){
      getInputsTree()
      fileItems <- extractFromTree("FILE")
    }
    return(fileItems)
  })

  getOutputFiles <- reactive({
    debugConsole('getOutputFiles entered')
    files <- Sys.glob(file.path(reactiveFilePaths_rv[[OUTPUT_DIR]], '*.csv'))
    return(files)
  })

  ### SCENARIO TAB (TAB_SCENARIO) ----------------------------------------------------------

  observe({
    shinyjs::toggleState(id = COPY_MODEL_BUTTON,
                         condition = input[[SELECT_RUN_SCRIPT_BUTTON]],
                         selector = NULL)
  })

    # how to hide/show tabs https://github.com/daattali/advanced-shiny/blob/master/hide-tab/app.R
  observe({
    shinyjs::toggle(
      id = NULL,
      condition = input[[SELECT_RUN_SCRIPT_BUTTON]],
      anim = TRUE,
      animType = "Slide",
      time = 0.25,
      #select all items where data-value starts with 'TAB_'. The ^= similar to ^ in grep 'starts with'
      selector = "#navlist li a[data-value^=TAB_]"
    )
  })

  shinyFiles::shinyFileChoose(
    input = input,
    id = SELECT_RUN_SCRIPT_BUTTON,
    session = session,
    roots = volumeRoots,
    #defaultRoot = "VisionEval",
    filetypes = c("R")
  )

  shinyFiles::shinyFileSave(
    input = input,
    id = COPY_MODEL_BUTTON,
    session = session,
    roots = volumeRoots,
    defaultRoot = 'VisionEval',
    #must specify a filetype due to shinyFiles bug https://github.com/thomasp85/shinyFiles/issues/56
    #even though in my case I am creating a folder so don't care about the mime type
    filetypes = c("")
  )

  output[[SCRIPT_NAME]] = renderText({
    getScriptInfo()$datapath
  })

  output[[MODEL_MODULES]] = DT::renderDataTable({
    getScriptInfo()
    returnValue <- getModelModules()
    return(returnValue)
  }, server=FALSE, selection = 'none')


  ### SETTINGS TAB (TAB_SETTINGS) -----------------------------------------


  observeEvent(input[[SAVE_RUN_PARAMETERS_FILE]], handlerExpr = {
    saveParameterFile(RUN_PARAMETERS_FILE)
    showNotification('File saved.', type='message', duration=10)
  }, label = SAVE_RUN_PARAMETERS_FILE)

  observeEvent(input[[REVERT_RUN_PARAMETERS_FILE]], handlerExpr = {
    output[[RUN_PARAMETERS_RHT]] <- revertParameterFile(RUN_PARAMETERS_FILE)
  }, label = REVERT_RUN_PARAMETERS_FILE)

  observeEvent(input[[SAVE_MODEL_PARAMETERS_FILE]], handlerExpr = {
    saveParameterFile(MODEL_PARAMETERS_FILE)
    showNotification('File saved.', type='message', duration=10)
  }, label = SAVE_MODEL_PARAMETERS_FILE)

  observeEvent(input[[REVERT_MODEL_PARAMETERS_FILE]], handlerExpr = {
    output[[MODEL_PARAMETERS_RHT]] <- revertParameterFile(MODEL_PARAMETERS_FILE)
  }, label = REVERT_MODEL_PARAMETERS_FILE)

  output[[RUN_PARAMETERS_FILE]] <- renderText({
    reactiveFilePaths_rv[[RUN_PARAMETERS_FILE]]
  })

  output[[MODEL_PARAMETERS_FILE]] <- renderText({
    reactiveFilePaths_rv[[MODEL_PARAMETERS_FILE]]
  })

  output[[RUN_PARAMETERS_RHT]] <- rhandsontable::renderRHandsontable({
    createParamTable(
      convertRunParam2Df(
        reactiveFileReaders_ls[[RUN_PARAMETERS_FILE]]()
      )
    )
  })

  output[[MODEL_PARAMETERS_RHT]] <- rhandsontable::renderRHandsontable({
    createParamTable(reactiveFileReaders_ls[[MODEL_PARAMETERS_FILE]]())
  })

  ### INPUTS TAB (TAB_INPUTS) -------------------------------------------------

  observe({
    if ( length(getInputFiles()) > 0 ){
      debugConsole('Getting Module specifications Input files')
      choices <- sort(getInputFiles()$resultList)
      updateSelectInput(session, INPUT_FILES, choices=choices)
    }
  })

  observe({
    fileName <- input[[INPUT_FILES]]
    if ( fileName != "" ){
      filePath <- file.path(getScriptInfo()$fileDirectory, "inputs", fileName)

      fileDataTable <- SafeReadCSV(filePath)
      debugConsole(paste("nrow(fileDataTable):", nrow(fileDataTable)))
      otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]] <- fileName
      otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]] <- fileDataTable
    }
  })

  observeEvent(input[[INPUT_FILE_SAVE_BUTTON]], handlerExpr={
    editedContent <- rhandsontable::hot_to_r(input[[EDITOR_INPUT_FILE_RHT]])
    if (!is.null(editedContent) && nchar(editedContent) > 0) {
      fileName <- otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]]
      filePath <- file.path(getScriptInfo()$fileDirectory, "inputs", fileName)
      file.rename(filePath, paste0(filePath, "_",
                                   format(Sys.time(), "%Y-%m-%d_%H-%M"),
                                   ".bak"))
      debugConsole(paste0("writing out '", filePath,
                   "' with nrow(editedContent): ", nrow(editedContent),
                   " ncol(editedContent): ", ncol(editedContent))
                   )
      data.table::fwrite(editedContent, filePath)
      showNotification('File saved.', type='message', duration=10)
    }
  })

  observeEvent(input[[INPUT_FILE_REVERT_BUTTON]], handlerExpr={
    fileName <- input[[INPUT_FILES]]
    if ( fileName != "" ){
      filePath <- file.path(getScriptInfo()$fileDirectory, "inputs", fileName)

      fileDataTable <- SafeReadCSV(filePath)
      debugConsole(paste("nrow(fileDataTable):", nrow(fileDataTable)))
      otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]] <- fileName
      otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]] <- fileDataTable
    }
  })

  output[[EDITOR_INPUT_FILE_IDENTIFIER]] = renderText({
    fileName <- otherReactiveValues_rv[[EDITOR_INPUT_FILE_IDENTIFIER]]
    filePath <- file.path(getScriptInfo()$fileDirectory, "inputs", fileName)

    debugConsole(paste0('EDITOR_INPUT_FILE_IDENTIFIER: ', fileName))
    if ( is.null(fileName) ){
      filePath <- 'No file selected'
    }
    filePath
  })

  output[[EDITOR_INPUT_FILE_RHT]] <- rhandsontable::renderRHandsontable({
    DF <- otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]]
    if (is.null(DF) || !data.table::is.data.table(DF)) {
      DF <- data.table::data.table(foo='bar')
    } else {
      # Convert integers to numeric so edits will take!
      DF[, names(DF) := lapply(.SD, function(x) if(is.integer(x)){as.numeric(x)} else {x})]
    }

    debugConsole(paste0("EDITOR_INPUT_FILE_DT: nrow(DF): ", nrow(DF), " class(DF): ",
                        paste0(collapse = ", ", class(DF))))

    rhandsontable(DF, useTypes = FALSE, height=400)
  })

    # Hide or show the editor_input_file_dt
  observe({

    dt <- otherReactiveValues_rv[[EDITOR_INPUT_FILE_DT]]
    debugConsole(paste('EDITOR_INPUT_FILE_DT has', nrow(dt), 'rows'))
    debugConsole(paste('EDITOR_INPUT_FILE_DT class:',
                       paste0(collapse = ", ", class(dt))))
    if (data.table::is.data.table(dt) ){
      shinyjs::show(
        id=EDITOR_INPUT_DIV,
        anim=TRUE,
        animType="Slide",
        time=0.25
        #selector="#EDITOR_INPUT_FILE_DT, #EDITOR_INPUT_FILE_IDENTIFIER"
      )
    } else {
      shinyjs::hide(
        id=EDITOR_INPUT_DIV,
        anim=FALSE,
        time=0.1
        #selector="#EDITOR_INPUT_FILE_DT, #EDITOR_INPUT_FILE_IDENTIFIER"
      )

    }
  })


  ### RUN TAB (TAB_RUN) --------------------------------------------------

  #need to call processRunningTasks so that the callback to the future Function will be hit
  observe(
    label = "processRunningTasks",
    x = {
      invalidateLater(DEFAULT_POLL_INTERVAL)
      processRunningTasks(debug = TRUE)
    }
  ) #end observe(label = processRunningTasks


    # Run the model
  observeEvent(input[[RUN_MODEL_BUTTON]], label = RUN_MODEL_BUTTON, handlerExpr = {
    req(input[[SELECT_RUN_SCRIPT_BUTTON]])
    debugConsole("observeEvent input$runModel entered")
    datapath <- getScriptInfo()$datapath

    disableActionButtons()
    showNotification('Model is initializing', type='message', duration=10)

    startAsyncTask(CAPTURED_SOURCE, future({
      # if(file.exists(reactiveFilePaths_rv[[MODEL_STATE_FILE]])){
      #   remove(reactiveFilePaths_rv[[MODEL_STATE_FILE]])
      # }
      #reference ModelState_ls so future will recognize it as a global
      getScriptOutput(datapath, isolate(reactiveFilePaths_rv[[CAPTURED_SOURCE]]))
    }),
    callback = function(asyncResult) {
      # asyncResult:
      #   asyncTaskName = asyncTaskName,
      #   taskResult = taskResult,
      #   submitTime = submitTime,
      #   endTime = endTime,
      #   elapsedTime = elapsedTime,
      #   caughtError = caughtError,
      #   caughtWarning = caughtWarning
      enableActionButtons()
      exportOutputData(dirname(datapath))
    },
    debug = TRUE) # end startAsyncTask
    # updateNavlistPanel(session, "navlist", selected = TAB_LOGS)
    debugConsole("observeEvent input$runModel exited")
  }) #end runModel observeEvent

  output[[MODULE_PROGRESS]] = DT::renderDataTable({
    returnValue <- getModuleProgress()
    return(returnValue)
  }, server=FALSE, selection = 'none') #, options = list(order = list(list(2, 'desc'))))

  output[[CAPTURED_SOURCE]] <- renderText({
    reactiveFileReaders_ls[[CAPTURED_SOURCE]]()
  })

  ### OUTPUTS TAB (TAB_OUTPUTS)------------------------------------------

  observe({
    if ( length(getOutputFiles()) > 0){
      debugConsole("Getting output files")
      choices <- sort(basename(getOutputFiles()))
      updateSelectInput(session, OUTPUT_FILE, choices=choices)
    }
  })

  output[[OUTPUT_FILE_PATH]] <- renderText({
    fileName <- input[[OUTPUT_FILE]]
    filePath <- file.path(reactiveFilePaths_rv[[OUTPUT_DIR]], fileName)
    debugConsole(paste0('OUTPUT_FILE_PATH: ', filePath))
    filePath
  })


  output_rht <- eventReactive(input[[OUTPUT_FILE]],{
    dataTable <- data.frame()
    fileName <- input[[OUTPUT_FILE]]
    if ( fileName != "" ){
      filePath <- file.path(reactiveFilePaths_rv[[OUTPUT_DIR]], fileName)
      dataTable <- SafeReadCSV(filePath)
      debugConsole(paste0('Loaded ', filePath))
      }
    rhandsontable::hot_context_menu(
      rhandsontable::rhandsontable(dataTable, readOnly=TRUE),
      allowRowEdit=FALSE,
      allowColEdit=FALSE)
  })

  output[[OUTPUT_FILE_RHT]] <- rhandsontable::renderRHandsontable({
    output_rht()
    })

  output[[OUTPUT_FILE_SAVE_BUTTON]] <- downloadHandler(
    filename=function() paste0('data.csv'),
    content=function(file){
      write.csv(rhandsontable::hot_to_r(input[[OUTPUT_FILE_RHT]]),
                file,
                row.names=FALSE)
    },
    contentType='text/csv'
    )

} #end server


