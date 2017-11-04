#============
#visioneval.R
#============

#This script defines the main functions that implement the VisionEval framework
#and are intended to be exported.


#INITIALIZE MODEL
#================
#' Initialize model.
#'
#' \code{initializeModel}Function initializes a VisionEval model, loading all
#' parameters and inputs, and making checks to ensure that model can run
#' successfully.
#'
#' This function does several things to initialize the model environment and
#' datastore including:
#' 1) Initializing a file that is used to keep track of the state of key model
#' run variables and the datastore;
#' 2) Initializes a log to which messages are written;
#' 3) Creates the datastore and initializes its structure, reads in and checks
#' the geographic specifications and initializes the geography in the datastore,
#' or loads an existing datastore if one has been identified;
#' 4) Parses the model run script to identify the modules in their order of
#' execution and checks whether all the identified packages are installed and
#' the modules exist in the packages;
#' 5) Checks that all data requested from the datastore will be available when
#' it is requested and that the request specifications match the datastore
#' specifications;
#' 6) Checks all of the model input files to determine whether they they are
#' complete and comply with specifications.
#'
#' @param ParamDir A string identifying the relative or absolute path to the
#'   directory where the parameter and geography definition files are located.
#'   The default value is "defs".
#' @param RunParamFile A string identifying the name of a JSON-formatted text
#' file that contains parameters needed to identify and manage the model run.
#' The default value is "run_parameters.json".
#' @param GeoFile A string identifying the name of a text file in
#' comma-separated values format that contains the geographic specifications
#' for the model. The default value is "geo.csv".
#' @param ModelParamFile A string identifying the name of a JSON-formatted text
#' file that contains global model parameters that are important to a model and
#' may be shared by several modules.
#' @param LoadDatastore A logical identifying whether an existing datastore
#' should be loaded.
#' @param DatastoreName A string identifying the full path name of a datastore
#' to load or NULL if an existing datastore in the working directory is to be
#' loaded.
#' @param SaveDatastore A string identifying whether if an existing datastore
#' in the working directory should be saved rather than removed.
#' @return None. The function prints to the log file messages which identify
#' whether or not there are errors in initialization. It also prints a success
#' message if initialization has been successful.
#' @export
initializeModel <-
  function(
    ParamDir = "defs",
    RunParamFile = "run_parameters.json",
    GeoFile = "geo.csv",
    ModelParamFile = "model_parameters.json",
    LoadDatastore = FALSE,
    DatastoreName = NULL,
    SaveDatastore = TRUE) {

    #Initialize model state and log files
    #------------------------------------
    Msg <-
      paste0(Sys.time(), " -- Initializing Model.")
    print(Msg)

    #unusual code to work with VE_GUI which needs to know log file location before long running operation begins...
    preExistingModelState <- getOption("visioneval.preExistingModelState", NULL)
    if (is.null(preExistingModelState)) {
      initModelStateFile(Dir = ParamDir, ParamFile = RunParamFile)
      initLog()
      writeLog(Msg)
    } else {
      writeLog("option visioneval.keepExistingModelState TRUE so skipping initModelStateFile and initLog",
               Print=TRUE)
      setModelState(preExistingModelState)
    }

    #Assign the correct datastore interaction functions
    #--------------------------------------------------
    assignDatastoreFunctions(readModelState()$DatastoreType)

    #Load existing model if specified and initialize geography
    #---------------------------------------------------------
    if (LoadDatastore) {
      if (!is.null(DatastoreName)) {
        if (file.exists(DatastoreName)) {
          loadDatastore(
            FileToLoad = DatastoreName,
            GeoFile = GeoFile,
            SaveDatastore = SaveDatastore
          )
        } else {
          Msg <-
            paste0("Call of 'initializeModel' function has error. ",
                   "'LoadDatastore' argument is TRUE, but ",
                   "file specified by 'DatastoreName' argument (",
                   DatastoreName, ") does not exist.")
          stop(Msg)
        }
      } else {
        if (file.exists(getModelState()[["DatastoreName"]])) {
          LoadDatastore <- getModelState()[["DatastoreName"]]
          loadDatastore(
            FileToLoad = DatastoreName,
            GeoFile = GeoFile,
            SaveDatastore = SaveDatastore
          )
        } else {
          Msg <-
            paste0("Call of 'initializeModel' function has error. ",
                   "'LoadDatastore' argument is TRUE, but ",
                   "since the 'DatastoreName' argument is NULL, ",
                   "it is attempting to load the previous datastore ",
                   "which can't be found.")
          stop(Msg)
        }
      }
    } else {
      initDatastore()
      readGeography(Dir = ParamDir, GeoFile = GeoFile)
      initDatastoreGeography()
      loadModelParameters(ModelParamFile = ModelParamFile)
    }

    #Parse script to make table of all the module calls, check and combine specs
    #---------------------------------------------------------------------------
    #Parse script and make data frame of modules that are called directly
    parseModelScript(FilePath = "run_model.R")
    ModuleCalls_df <- unique(getModelState()$ModuleCalls_df)
    #Get list of installed packages
    InstalledPkgs_ <- rownames(installed.packages())
    #Iterate through each module call and check availability and specifications
    #create combined list of all specifications
    Errors_ <- character(0)
    AllSpecs_ls <- list()
    for (i in 1:nrow(ModuleCalls_df)) {
      AllSpecs_ls[[i]] <- list()
      ModuleName <- ModuleCalls_df$ModuleName[i]
      AllSpecs_ls[[i]]$ModuleName <- ModuleName
      PackageName <- ModuleCalls_df$PackageName[i]
      AllSpecs_ls[[i]]$PackageName <- PackageName
      AllSpecs_ls[[i]]$RunFor <- ModuleCalls_df$RunFor[i]
      #Check module availability
      Err <- checkModuleExists(ModuleName, PackageName, InstalledPkgs_)
      if (length(Err) > 0) {
        Errors_ <- c(Errors_, Err)
        next()
      }
      #Load and check the module specifications
      Specs_ls <-
        processModuleSpecs(getModuleSpecs(ModuleName, PackageName))
      Err <- checkModuleSpecs(Specs_ls, ModuleName)
      if (length(Err) > 0) {
        Errors_ <- c(Errors_, Err)
        next()
      } else {
        AllSpecs_ls[[i]]$Specs <- Specs_ls
      }
      #If the 'Call' spec is not null, check the called module
      if (!is.null(Specs_ls$Call)) {
        #If it is a list of module calls
        if (is.list(Specs_ls$Call)) {
        #Iterate through module calls
          for (j in 1:length(Specs_ls$Call)) {
            Call_ <- unlist(strsplit(Specs_ls$Call[[j]], "::"))
            #Check module availability
            Err <-
              checkModuleExists(
                Call_[2],
                Call_[1],
                InstalledPkgs_,
                c(Module = ModuleName, Package = PackageName))
            if (length(Err) > 0) {
              Errors_ <- c(Errors_, Err)
              next()
            }
            #Load and check the module specifications and add Get specs if
            #there are no specification errors
            CallSpecs_ls <-
              processModuleSpecs(getModuleSpecs(Call_[2], Call_[1]))
            Err <- checkModuleSpecs(CallSpecs_ls, Call_[2])
            if (length(Err) > 0) {
              Errors_ <- c(Errors_, Err)
              next()
            } else {
              AllSpecs_ls[[i]]$Specs$Get <-
                c(AllSpecs_ls[[i]]$Specs$Get <- Specs_ls$Get)
            }
          }
        }
      }
    }
    #If any errors, print to log and stop execution
    if (length(Errors_) > 0) {
      Msg <-
        paste0("There are one or more errors in the module calls: ",
               "package not installed, or module not present in package, ",
               "or errors in module specifications. ",
               "Check the log for details.")
      stop(Msg)
    }

    #Simulate model run
    #------------------
    simDataTransactions(AllSpecs_ls)

    #Check and process module inputs
    #-------------------------------
    #Set up a list to store processed inputs for all modules
    ProcessedInputs_ls <- list()
    #Process inputs for all modules and add results to list
    for (i in 1:nrow(ModuleCalls_df)) {
      Module <- ModuleCalls_df$ModuleName[i]
      Package <- ModuleCalls_df$PackageName[i]
      ModuleSpecs_ls <-
        processModuleSpecs(getModuleSpecs(Module, Package))
      if (!is.null(ModuleSpecs_ls$Inp)) {
        ProcessedInputs_ls[[Module]] <-
          processModuleInputs(ModuleSpecs_ls, Module)
      }
    }
    #Check whether there are any input errors
    HasErrors <-
      any(unlist(lapply(ProcessedInputs_ls, function(x) {
        x$Errors != 0
      })))
    if (HasErrors) {
      writeLog(ProcessedInputs_ls$Errors)
      stop("Input files have errors. Check the log for details.")
    }

    #Load model inputs into the datastore
    #------------------------------------
    for (i in 1:nrow(ModuleCalls_df)) {
      Module <- ModuleCalls_df$ModuleName[i]
      Package <- ModuleCalls_df$PackageName[i]
      ModuleSpecs_ls <-
        processModuleSpecs(getModuleSpecs(Module, Package))
      if (!is.null(ModuleSpecs_ls$Inp)) {
        inputsToDatastore(ProcessedInputs_ls[[Module]], ModuleSpecs_ls, Module)
      }
    }

    #If no errors print out message
    #------------------------------
    SuccessMsg <-
      paste0(Sys.time(), " -- Model successfully initialized.")
    writeLog(SuccessMsg)
    print(SuccessMsg)
  }


#RUN MODULE
#==========
#' Run module.
#'
#' \code{runModule} runs a model module.
#'
#' This function runs a module for  a specified year.
#'
#' @param ModuleName A string identifying the name of a module object.
#' @param PackageName A string identifying the name of the package the module is
#'   a part of.
#' @param RunFor A string identifying whether to run the module for all years
#' "AllYears", only the base year "BaseYear", or for all years except the base
#' year "NotBaseYear".
#' @param RunYear A string identifying the run year.
#' @return None. The function writes results to the specified locations in the
#'   datastore and prints a message to the console when the module is being run.
#' @export
runModule <- function(ModuleName, PackageName, RunFor, RunYear) {
  #Check whether the module should be run for the current run year
  #---------------------------------------------------------------
  BaseYear <- getModelState()$BaseYear
  if (RunYear == BaseYear & RunFor == "NotBaseYear") {
    return()
  }
  if (RunYear != BaseYear & RunFor == "BaseYear") {
    return()
  }
  #Log and print starting message
  #------------------------------
  Msg <-
    paste0(Sys.time(), " -- Starting module '", ModuleName,
           "' for year '", RunYear, "'.")
  writeLog(Msg)
  print(Msg)
  #Load the package and module
  #---------------------------
  Function <- paste0(PackageName, "::", ModuleName)
  Specs <- paste0(PackageName, "::", ModuleName, "Specifications")
  M <- list()
  M$Func <- eval(parse(text = Function))
  M$Specs <- processModuleSpecs(eval(parse(text = Specs)))
  #Load any modules identified by 'Call' spec if any
  if (is.list(M$Specs$Call)) {
    Call <- list(
      Func = list(),
      Specs = list()
    )
    for (Alias in names(M$Specs$Call)) {
      Function <- M$Specs$Call[[Alias]]
      Specs <- paste0(M$Specs$Call[[Alias]], "Specifications")
      Call$Func[[Alias]] <- eval(parse(text = Function))
      Call$Specs[[Alias]] <- processModuleSpecs(eval(parse(text = Specs)))
      Call$Specs[[Alias]]$RunBy <- M$Specs$RunBy
    }
  }
  #Run module
  #----------
  if (M$Specs$RunBy == "Region") {
    #Get data from datastore
    L <- getFromDatastore(M$Specs, RunYear = Year)
    if (exists("Call")) {
      for (Alias in names(Call$Specs)) {
        L[[Alias]] <-
          getFromDatastore(Call$Specs[[Alias]], RunYear = Year)
      }
    }
    #Run module and store results in datastore
    if (exists("Call")) {
      R <- M$Func(L, Call$Func)
    } else {
      R <- M$Func(L)
    }
    setInDatastore(R, M$Specs, ModuleName, Year = RunYear, Geo = NULL)
  } else {
    #Identify the units of geography to iterate over
    GeoCategory <- M$Specs$RunBy
    #Create the geographic index list
    GeoIndex_ls <- createGeoIndexList(c(M$Specs$Get, M$Specs$Set), GeoCategory, Year)
    if (exists("Call")) {
      for (Alias in names(Call$Specs)) {
        GeoIndex_ls[[Alias]] <-
          createGeoIndexList(Call$Specs[[Alias]]$Get, GeoCategory, Year)
      }
    }
    #Run module for each geographic area
    Geo_ <- readFromTable(GeoCategory, GeoCategory, RunYear)
    for (Geo in Geo_) {
      #Get data from datastore for geographic area
      L <-
        getFromDatastore(M$Specs_ls, RunYear, Geo, GeoIndex_ls)
      if (exists("Call")) {
        for (Alias in names(Call$Specs)) {
          L[[Alias]] <-
            getFromDatastore(Call$Specs[[Alias]], RunYear = Year, Geo, GeoIndex_ls = GeoIndex_ls[[Alias]])
        }
      }
      #Run model for geographic area and store results in datastore
      if (exists("Call")) {
        R <- M$Func(L, Call$Func)
      } else {
        R <- M$Func(L)
      }
      setInDatastore(R, M$Specs, ModuleName, RunYear, Geo, GeoIndex_ls)
    }
  }
  #Log and print ending message
  #----------------------------
  Msg <-
    paste0(Sys.time(), " -- Finish module '", ModuleName,
           "' for year '", RunYear, "'.")
  writeLog(Msg)
  print(Msg)
}
