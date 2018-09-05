#========
#module.R
#========

#This script defines functions related to the development and use of modules.


#DEFINE LIST ALIAS
#=================
#' Alias for list function.
#'
#' \code{item} a visioneval framework module developer function that is an alias
#' for the list function whose purpose is to make module specifications easier
#' to read.
#'
#' This function defines an alternate name for list. It is used in module
#' specifications to identify data items in the Inp, Get, and Set portions of
#' the specifications.
#'
#' @return a list.
#' @export
item <- list

#' Alias for list function.
#'
#' \code{items} a visioneval framework \strong{module developer} function that is
#' an alias for the list function whose purpose is to make module specifications
#' easier to read.
#'
#' This function defines an alternate name for list. It is used in module
#' specifications to identify a group of data items in the Inp, Get, and Set
#' portions of the specifications.
#'
#' @return a list.
#' @export
items <- list


#INITIALIZE DATA LIST
#====================
#' Initialize a list for data transferred to and from datastore
#'
#' \code{initDataList} a visioneval framework module developer function that
#' creates a list to be used for transferring data to and from the datastore.
#'
#' This function initializes a list to store data that is transferred from
#' the datastore to a module or returned from a module to be saved in the
#' datastore. The list has 3 named components (Global, Year, and BaseYear). This
#' is the standard structure for data being passed to and from a module and the
#' datastore.
#'
#' @return A list that has 3 named list components: Global, Year, BaseYear
#' @export
initDataList <- function() {
  list(Global = list(),
       Year = list(),
       BaseYear = list())
}


#ADD ERROR MESSAGE TO RESULTS LIST
#=================================
#' Add an error message to the results list
#'
#' \code{addErrorMsg} a visioneval framework module developer function that adds
#' an error message to the Errors component of the module results list that is
#' passed back to the framework.
#'
#' This function is a convenience function for module developers for passing
#' error messages back to the framework. The preferred method for handling
#' errors in module execution is for the module to handle the error by passing
#' one or more error messages back to the framework. The framework will then
#' write error messages to the log and stop execution. Error messages are
#' stored in a component of the returned list called Errors. This component is
#' a string vector where each element is an error message. The addErrorMsg will
#' create the Error component if it does not already exist and will add an error
#' message to the vector.
#'
#' @param ResultsListName the name of the results list given as a character
#' string
#' @param ErrMsg a character string that contains the error message
#' @return None. The function modifies the results list by adding an error
#' message to the Errors component of the results list. It creates the Errors
#' component if it does not already exist.
#' @export
addErrorMsg <- function(ResultsListName, ErrMsg) {
  Results_ls <- get(ResultsListName, envir = parent.frame())
  Results_ls$Errors <- c(Results_ls$Errors, ErrMsg)
  assign(ResultsListName, Results_ls, envir = parent.frame())
}


#ADD WARNING MESSAGE TO RESULTS LIST
#===================================
#' Add a warning message to the results list
#'
#' \code{addWarningMsg} a visioneval framework module developer function that
#' adds an warning message to the Warnings component of the module results list
#' that is passed back to the framework.
#'
#' This function is a convenience function for module developers for passing
#' warning messages back to the framework. The preferred method for handling
#' warnings in module execution is for the module to handle the warning by
#' passing one or more warning messages back to the framework. The framework
#' will then write warning messages to the log and stop execution. Warning
#' messages are stored in a component of the returned list called Warnings. This
#' component is a string vector where each element is an warning message. The
#' addWarningMsg will create the Warning component if it does not already exist
#' and will add a warning message to the vector.
#'
#' @param ResultsListName the name of the results list given as a character
#' string
#' @param WarnMsg a character string that contains the warning message
#' @return None. The function modifies the results list by adding a warning
#' message to the Warnings component of the results list. It creates the
#' Warnings component if it does not already exist.
#' @export
addWarningMsg <- function(ResultsListName, WarnMsg) {
  Results_ls <- get(ResultsListName, envir = parent.frame())
  Results_ls$Warnings <- c(Results_ls$Warnings, WarnMsg)
  assign(ResultsListName, Results_ls, envir = parent.frame())
}


#LOAD ESTIMATION DATA
#====================
#' Load estimation data
#'
#' \code{processEstimationInputs} a visioneval framework module developer
#' function that checks whether specified model estimation data meets
#' specifications and returns the data in a data frame.
#'
#' This function is used to check whether a specified CSV-formatted data file
#' used in model estimation is correctly formatted and contains acceptable
#' values for all the datasets contained within. The function checks whether the
#' specified file exists in the "inst/extdata" directory. If the file does not
#' exist, the function stops and transmits a standard error message that the
#' file does not exist. If the file does exist, the function reads the file into
#' the data frame and then checks whether it contains the specified columns and
#' that the data meets all specifications. If any of the specifications are not
#' met, the function stops and transmits an error message. If there are no
#' data errors the function returns a data frame containing the data in the
#' file.
#'
#' @param Inp_ls A list that describes the specifications for the estimation
#' file. This list must meet the framework standards for specification
#' description.
#' @param FileName A string identifying the file name. This is the file name
#' without any path information. The file must located in the "inst/extdata"
#' directory of the package.
#' @param ModuleName A string identifying the name of the module the estimation
#' data is being used in.
#' @return A data frame containing the estimation data according to
#' specifications with data types consistent with specifications and columns
#' not specified removed. Execution stops if any errors are found. Error
#' messages are printed to the console. Warnings are also printed to the console.
#' @export
processEstimationInputs <- function(Inp_ls, FileName, ModuleName) {
  #Define a function which expands a specification with multiple NAME items
  expandSpec <- function(SpecToExpand_ls) {
    Names_ <- unlist(SpecToExpand_ls$NAME)
    Expanded_ls <- list()
    for (i in 1:length(Names_)) {
      Temp_ls <- SpecToExpand_ls
      Temp_ls$NAME <- Names_[i]
      Expanded_ls <- c(Expanded_ls, list(Temp_ls))
    }
    Expanded_ls
  }
  #Define a function to process a component of a specifications list
  processComponent <- function(Component_ls) {
    Result_ls <- list()
    for (i in 1:length(Component_ls)) {
      Temp_ls <- Component_ls[[i]]
      if (length(Temp_ls$NAME) == 1) {
        Result_ls <- c(Result_ls, list(Temp_ls))
      } else {
        Result_ls <- c(Result_ls, expandSpec(Temp_ls))
      }
    }
    Result_ls
  }
  #Expand the specifications
  Inp_ls <- processComponent(Inp_ls)
  #Try to load the estimation file
  FilePath <- paste0("inst/extdata/", FileName)
  if (!file.exists(FilePath)) {
    Message <- paste("File", FilePath,
                     "required to estimate parameters for module", ModuleName,
                     "is missing.")
    stop(Message)
  } else {
    Data_df <- read.csv(FilePath, as.is = TRUE)
  }
  #Check whether all the necessary columns exist and remove unnecessary ones
  Names <- unlist(lapply(Inp_ls, function(x) x$NAME))
  if (!all(Names %in% names(Data_df))) {
    Message <- paste("Some required columns are missing from", FileName,
                     "required to estimate parameters for module", ModuleName)
    stop(Message)
  }
  Data_df <- Data_df[, Names]
  #Iterate through each column and check whether data meets specifications
  Errors_ <- character(0)
  Warnings_ <- character(0)
  for (i in 1:length(Inp_ls)) {
    Spec_ls <- Inp_ls[[i]]
    DatasetName <- Spec_ls$NAME
    Data_ <- Data_df[[DatasetName]]
    #Calculate SIZE of data if character data
    #This is only necessary because checkDataConsistency requires a SIZE attribute
    if (typeof(Data_) == "character") {
      Spec_ls$SIZE <- max(nchar(Data_))
    } else {
      Spec_ls$SIZE <- 0
    }
    #Check the dataset consistency with the specs
    DataCheck_ls <- checkDataConsistency(DatasetName, Data_, Spec_ls)
    if (length(DataCheck_ls$Errors) != 0) {
      Errors_ <- c(Errors_, DataCheck_ls$Errors)
    }
    if (length(DataCheck_ls$Warnings) != 0) {
      Warnings_ <- c(Warnings_, DataCheck_ls$Warnings)
    }
  }
  #Stop and list any errors if there are any
  if (length(Errors_) != 0) {
    Message <- paste(
      paste("Estimation file", FileName, "contains the following errors:"),
      paste(Errors_, collapse = "\n"),
      paste("Check data specifications in module", ModuleName, "script."),
      sep = "\n"
    )
    stop(Message)
  }
  #Print any warnings if there are any
  if (length(Warnings_) != 0) {
    print("The following data items match data conditions that are UNLIKELY:")
    for (i in length(Warnings_)) {
      print(Warnings_[i])
    }
  }
  #Identify the data class for each input file field
  ColClasses_ <- unlist(lapply(Inp_ls, function(x) {
    Type <- x$TYPE
    Class <- Types()[[Type]]$mode
    if (Class == "double") Class <- "numeric"
    Class
  }))
  names(ColClasses_) <- unlist(lapply(Inp_ls, function(x) {
    x$NAME
  }))
  #Match the classes with order of field names in the input file
  ColClasses_ <- ColClasses_[names(Data_df)]
  #Convert NA values into "NULL" (columns in data not to be read in)
  ColClasses_[is.na(ColClasses_)] <- "NULL"
  #Read the data file with the assigned column classes
  read.csv(FilePath, colClasses = ColClasses_)[, Names]
}


#CHECK MODULE OUTPUTS FOR CONSISTENCY WITH MODULE SPECIFICATIONS
#===============================================================
#' Check module outputs for consistency with specifications
#'
#' \code{checkModuleOutputs} a visioneval framework module developer function
#' that checks output list produced by a module for consistency with the
#' module's specifications.
#'
#' This function is used to check whether the output list produced by a module
#' is consistent with the module's specifications. If there are any
#' specifications for creating tables, the function checks whether the output
#' list contains the table(s), if the LENGTH attribute of the table(s) are
#' present, and if the LENGTH attribute(s) are consistent with the length of the
#' datasets to be saved in the table(s). Each of the datasets in the output list
#' are checked against the specifications. These include checking that the
#' data type is consistent with the specified type and whether all values are
#' consistent with PROHIBIT and ISELEMENTOF conditions. For character types,
#' a check is made to ensure that a SIZE attribute exists and that the size
#' is sufficient to store all characters.
#'
#' @param Data_ls A list of all the datasets returned by a module in the
#' standard list form required by the VisionEval model system.
#' @param ModuleSpec_ls A list of module specifications in the standard list
#' form required by the VisionEval model system.
#' @param ModuleName A string identifying the name of the module.
#' @return A character vector containing a list of error messages or having a
#' length of 0 if there are no error messages.
#' @export
checkModuleOutputs <-
  function(Data_ls, ModuleSpec_ls, ModuleName) {
    #Initialize Errors vector
    Errors_ <- character(0)
    #Check that required info for specified tables is present in the outputs
    #-----------------------------------------------------------------------
    if (!is.null(ModuleSpec_ls$NewSetTable)) {
      TableSpec_ls <- ModuleSpec_ls$NewSetTable
      for (i in 1:length(TableSpec_ls)) {
        Table <- TableSpec_ls[[i]]$TABLE
        Group <- TableSpec_ls[[i]]$GROUP
        if (is.null(Data_ls[[Group]][[Table]])) {
          Msg <-
            paste0("Table ", Table, " in group ", Group, " is not defined in outputs.")
          Errors_ <- c(Errors_, Msg)
        } else {
          TableLength <- attributes(Data_ls[[Group]][[Table]])$LENGTH
          if (is.null(TableLength)) {
            Msg <-
              paste0("Table ", Table, " in group ", Group, " does not have a LENGTH attribute.")
            Errors_ <- c(Errors_, Msg)
          } else {
            DSetLengths_ <- unlist(lapply(Data_ls[[Group]][[Table]], length))
            if (!all(DSetLengths_ == TableLength)) {
              Msg <-
                paste0("The LENGTH attribute of table, ", Table, " in group ",
                       Group, " does not match length of datasets to be ",
                       "stored in the table.")
              Errors_ <- c(Errors_, Msg)
            }
            rm(DSetLengths_)
          }
          rm(TableLength)
        }
        rm(Table, Group)
      }
    }
    #Check that all Set specifications are satisfied
    #-----------------------------------------------
    SetSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Set
    for (i in 1:length(SetSpec_ls)) {
      #Identify the Group, Table, and Name
      Spec_ls <- SetSpec_ls[[i]]
      Spec_ls$MODULE <- ModuleName
      Group <- Spec_ls$GROUP
      Table <- Spec_ls$TABLE
      Name <- Spec_ls$NAME
      #Check that the dataset exists and if so whether it correct
      if (is.null(Data_ls[[Group]][[Table]][[Name]])) {
        Msg <-
          paste0("Specified dataset ", Name, " in table ", Table,
                 " and group ", Group, " is not present in outputs.")
        Errors_ <- c(Errors_, Msg)
      } else {
        if (Spec_ls$TYPE == "character" & is.null(Spec_ls$SIZE)) {
          SizeSpec <- attributes(Data_ls[[Group]][[Table]][[Name]])$SIZE
          if (is.null(SizeSpec)) {
            Msg <-
              paste0("Specified dataset ", Name, " in table ", Table,
                     " and group ", Group, " has no SIZE attribute.")
            Errors_ <- c(Errors_, Msg)
          } else {
            Spec_ls$SIZE <- SizeSpec
          }
          rm(SizeSpec)
        }
        DSet_ <- Data_ls[[Group]][[Table]][[Name]]
        DataCheck_ls <- checkDataConsistency(Name, DSet_, Spec_ls)
        Errors_ <- c(Errors_, DataCheck_ls$Errors)
      }
      rm(Spec_ls, Group, Table, Name)
    }
    Errors_
  }


#TEST MODULE
#===========
#' Test module
#'
#' \code{testModule} a visioneval framework module developer function that sets
#' up a test environment and tests a module.
#'
#' This function is used to set up a test environment and test a module to check
#' that it can run successfully in the VisionEval model system. The function
#' sets up the test environment by switching to the tests directory and
#' initializing a model state list, a log file, and a datastore. The user may
#' use an existing datastore rather than initialize a new datastore. The use
#' case for loading an existing datastore is where a package contains several
#' modules that run in sequence. The first module would initialize a datastore
#' and then subsequent modules use the datastore that is modified by testing the
#' previous module. When run this way, it is also necessary to set the
#' SaveDatastore argument equal to TRUE so that the module outputs will be
#' saved to the datastore. The function performs several tests including
#' checking whether the module specifications are written properly, whether
#' the the test inputs are correct and complete and can be loaded into the
#' datastore, whether the datastore contains all the module inputs identified in
#' the Get specifications, whether the module will run, and whether all of the
#' outputs meet the module's Set specifications. The latter check is carried out
#' in large part by the checkModuleOutputs function that is called.
#'
#' @param ModuleName A string identifying the module name.
#' @param ParamDir A string identifying the location of the directory where
#' the run parameters, model parameters, and geography definition files are
#' located. The default value is defs. This directory should be located in the
#' tests directory.
#' @param RunParamFile A string identifying the name of the run parameters
#' file. The default value is run_parameters.json.
#' @param GeoFile A string identifying the name of the file which contains
#' geography definitions.
#' @param ModelParamFile A string identifying the name of the file which
#' contains model parameters. The default value is model_parameters.json.
#' @param LoadDatastore A logical value identifying whether to load an existing
#' datastore. If TRUE, it loads the datastore whose name is identified in the
#' run_parameters.json file. If FALSE it initializes a new datastore.
#' @param SaveDatastore A logical value identifying whether the module outputs
#' will be written to the datastore. If TRUE the module outputs are written to
#' the datastore. If FALSE the outputs are not written to the datastore.
#' @param DoRun A logical value identifying whether the module should be run. If
#'   FALSE, the function will initialize a datastore, check specifications, and
#'   load inputs but will not run the module but will return the list of module
#'   specifications. That setting is useful for module development in order to
#'   create the all the data needed to assist with module programming. It is
#'   used in conjunction with the getFromDatastore function to create the
#'   dataset that will be provided by the framework. The default value for this
#'   parameter is TRUE. In that case, the module will be run and the results
#'   will checked for consistency with the Set specifications.
#' @param RunFor A string identifying what years the module is to be tested for.
#'   The value must be the same as the value that is used when the module is run
#'   in a module. Allowed values are 'AllYears', 'BaseYear', and 'NotBaseYear'.
#' @param StopOnErr A logical identifying whether model execution should be
#'   stopped if the module transmits one or more error messages or whether
#'   execution should continue with the next module. The default value is TRUE.
#'   This is how error handling will ordinarily proceed during a model run. A
#'   value of FALSE is used when 'Initialize' modules in packages are run during
#'   model initialization. These 'Initialize' modules are used to check and
#'   preprocess inputs. For this purpose, the module will identify any errors in
#'   the input data, the 'initializeModel' function will collate all the data
#'   errors and print them to the log.
#' @return If DoRun is FALSE, the return value is a list containing the module
#'   specifications. If DoRun is TRUE, there is no return value. The function
#'   writes out messages to the console and to the log as the testing proceeds.
#'   These messages include the time when each test starts and when it ends.
#'   When a key test fails, requiring a fix before other tests can be run,
#'   execution stops and an error message is written to the console. Detailed
#'   error messages are also written to the log.
#' @export
testModule <-
  function(ModuleName,
           ParamDir = "defs",
           RunParamFile = "run_parameters.json",
           GeoFile = "geo.csv",
           ModelParamFile = "model_parameters.json",
           LoadDatastore = FALSE,
           SaveDatastore = TRUE,
           DoRun = TRUE,
           RunFor = "AllYears",
           StopOnErr = TRUE) {

    #Set working directory to tests and return to main module directory on exit
    #--------------------------------------------------------------------------
    setwd("tests")
    on.exit(setwd("../"))

    #Initialize model state and log files
    #------------------------------------
    Msg <- paste0("Testing ", ModuleName, ".")
    initModelStateFile(Dir = ParamDir, ParamFile = RunParamFile)
    initLog(ModuleName)
    writeLog(Msg, Print = TRUE)
    rm(Msg)

    #Assign the correct datastore interaction functions
    #--------------------------------------------------
    assignDatastoreFunctions(readModelState()$DatastoreType)

    #Load datastore if specified or initialize new datastore
    #-------------------------------------------------------
    if (LoadDatastore) {
      writeLog("Attempting to load datastore.", Print = TRUE)
      DatastoreName <- getModelState()[["DatastoreName"]]
      if (!file.exists(DatastoreName)) {
        Msg <-
          paste0("LoadDatastore argument is TRUE but the datastore file ",
                 "specified in the RunParamFile doesn't exist in the tests ",
                 "directory.")
        stop(Msg)
        rm(Msg)
      }
      loadDatastore(
        FileToLoad = DatastoreName,
        GeoFile = GeoFile,
        SaveDatastore = FALSE
      )
      writeLog("Datastore loaded.", Print = TRUE)
    } else {
      writeLog("Attempting to initialize datastore.", Print = TRUE)
      initDatastore()
      readGeography(Dir = ParamDir, GeoFile = GeoFile)
      initDatastoreGeography()
      loadModelParameters(ModelParamFile = ModelParamFile)
      writeLog("Datastore initialized.", Print = TRUE)
    }

    #Load module specifications and check whether they are proper
    #------------------------------------------------------------
    loadSpec <- function() {
      SpecsName <- paste0(ModuleName, "Specifications")
      SpecsFileName <- paste0("../data/", SpecsName, ".rda")
      load(SpecsFileName)
      return(processModuleSpecs(get(SpecsName)))
    }
    writeLog("Attempting to load and check specifications.", Print = TRUE)
    Specs_ls <- loadSpec()
    #Check for errors
    Errors_ <- checkModuleSpecs(Specs_ls, ModuleName)
    if (length(Errors_) != 0) {
      Msg <-
        paste0("Specifications for module '", ModuleName,
               "' have the following errors.")
      writeLog(Msg)
      writeLog(Errors_)
      Msg <- paste0("Specifications for module '", ModuleName,
                    "' have one or more errors. Check the log for details.")
      stop(Msg)
      rm(Msg)
    }
    rm(Errors_)
    writeLog("Module specifications successfully loaded and checked for errors.",
             Print = TRUE)
    #Check for developer warnings
    DeveloperWarnings_ls <-
      lapply(c(Specs_ls$Inp, Specs_ls$Get, Specs_ls$Set), function(x) {
        attributes(x)$WARN
      })
    DeveloperWarnings_ <-
      unique(unlist(lapply(DeveloperWarnings_ls, function(x) x[!is.null(x)])))
    if (length(DeveloperWarnings_) != 0) {
      writeLog(DeveloperWarnings_)
      Msg <- paste0(
        "Specifications check for module '", ModuleName, "' generated one or ",
        "more warnings. Check log for details."
      )
      warning(Msg)
      rm(DeveloperWarnings_ls, DeveloperWarnings_, Msg)
    }

    #Process, check, and load module inputs
    #--------------------------------------
    if (is.null(Specs_ls$Inp)) {
      writeLog("No inputs to process.", Print = TRUE)
    } else {
      writeLog("Attempting to process, check and load module inputs.",
             Print = TRUE)
      # Process module inputs
      ProcessedInputs_ls <- processModuleInputs(Specs_ls, ModuleName)
      # Write warnings to log if any
      if (length(ProcessedInputs_ls$Warnings != 0)) {
        writeLog(ProcessedInputs_ls$Warnings)
      }
      # Write errors to log and stop if any errors
      if (length(ProcessedInputs_ls$Errors) != 0)  {
        Msg <- paste0(
          "Input files for module ", ModuleName,
          " have errors. Check the log for details."
        )
        stop(Msg)
      }
      # If module is NOT Initialize, save the inputs in the datastore
      if (ModuleName != "Initialize") {
        inputsToDatastore(ProcessedInputs_ls, Specs_ls, ModuleName)
        writeLog("Module inputs successfully checked and loaded into datastore.",
                 Print = TRUE)
      } else {
        if (DoRun) {
          # If module IS Initialize, apply the Initialize function
          initFunc <- get("Initialize")
          InitializedInputs_ls <- initFunc(ProcessedInputs_ls)
          # Write warnings to log if any
          if (length(InitializedInputs_ls$Warnings != 0)) {
            writeLog(InitializedInputs_ls$Warnings)
          }
          # Write errors to log and stop if any errors
          if (length(InitializedInputs_ls$Errors) != 0) {
            writeLog(InitializedInputs_ls$Errors)
            stop("Errors in Initialize module inputs. Check log for details.")
          }
          # Save inputs to datastore
          inputsToDatastore(InitializedInputs_ls, Specs_ls, ModuleName)
          writeLog("Module inputs successfully checked and loaded into datastore.",
                   Print = TRUE)
          return() # Break out of function because purpose of Initialize is to process inputs.
        } else {
          return(ProcessedInputs_ls)
        }
      }
    }

    #Check whether datastore contains all data items in Get specifications
    #---------------------------------------------------------------------
    writeLog(
      "Checking whether datastore contains all datasets in Get specifications.",
      Print = TRUE)
    G <- getModelState()
    Get_ls <- Specs_ls$Get
    #Vector to keep track of missing datasets that are specified
    Missing_ <- character(0)
    #Function to check whether dataset is optional
    isOptional <- function(Spec_ls) {
      if (!is.null(Spec_ls$OPTIONAL)) {
        Spec_ls$OPTIONAL
      } else {
        FALSE
      }
    }
    #Vector to keep track of Get specs that need to be removed from list because
    #they are optional and the datasets are not present
    OptSpecToRemove_ <- numeric(0)
    #Check each specification
    for (i in 1:length(Get_ls)) {
      Spec_ls <- Get_ls[[i]]
      if (Spec_ls$GROUP == "Year") {
        for (Year in G$Years) {
          if (RunFor == "NotBaseYear"){
            if(!Year %in% G$BaseYear){
              Present <-
                checkDataset(Spec_ls$NAME, Spec_ls$TABLE, Year, G$Datastore)
              if (!Present) {
                if(isOptional(Spec_ls)) {
                  #Identify for removal because optional and not present
                  OptSpecToRemove_ <- c(OptSpecToRemove_, i)
                } else {
                  #Identify as missing because not optional and not present
                  Missing_ <- c(Missing_, attributes(Present))
                }
              }
            }
          } else {
            Present <-
              checkDataset(Spec_ls$NAME, Spec_ls$TABLE, Year, G$Datastore)
            if (!Present) {
              if(isOptional(Spec_ls)) {
                #Identify for removal because optional and not present
                OptSpecToRemove_ <- c(OptSpecToRemove_, i)
              } else {
                #Identify as missing because not optional and not present
                Missing_ <- c(Missing_, attributes(Present))
              }
            }
          }

        }
      }
      if (Spec_ls$GROUP == "BaseYear") {
        Present <-
          checkDataset(Spec_ls$NAME, Spec_ls$TABLE, G$BaseYear, G$Datastore)
        if (!Present) {
          if (isOptional(Spec_ls)) {
            #Identify for removal because optional and not present
            OptSpecToRemove_ <- c(OptSpecToRemove_, i)
          } else {
            #Identify as missing because not optional and not present
            Missing_ <- c(Missing_, attributes(Present))
          }
        }
      }
      if (Spec_ls$GROUP == "Global") {
        Present <-
          checkDataset(Spec_ls$NAME, Spec_ls$TABLE, "Global", G$Datastore)
        if (!Present) {
          if (isOptional(Spec_ls)) {
            #Identify for removal because optional and not present
            OptSpecToRemove_ <- c(OptSpecToRemove_, i)
          } else {
            #Identify as missing because not optional and not present
            Missing_ <- c(Missing_, attributes(Present))
          }
        }
      }
    }
    #If any non-optional datasets are missing, write out error messages and
    #stop execution
    if (length(Missing_) != 0) {
      Msg <-
        paste0("The following datasets identified in the Get specifications ",
               "for module ", ModuleName, " are missing from the datastore.")
      Msg <- paste(c(Msg, Missing_), collapse = "\n")
      writeLog(Msg)
      stop(
        paste0("Datastore is missing one or more datasets specified in the ",
               "Get specifications for module ", ModuleName, ". Check the log ",
               "for details.")
      )
      rm(Msg)
    }
    #If any optional datasets are missing, remove the specifications for them so
    #that there will be no errors when data are retrieved from the datastore
    if (length(OptSpecToRemove_) != 0) {
      Specs_ls$Get <- Specs_ls$Get[-OptSpecToRemove_]
    }
    writeLog(
      "Datastore contains all datasets identified in module Get specifications.",
      Print = TRUE)

    #Run the module and check that results meet specifications
    #---------------------------------------------------------
    #The module is run only if the DoRun argument is TRUE. Otherwise the
    #datastore is initialized, specifications are checked, and a list is
    #returned which contains the specifications list, the data list from the
    #datastore meeting specifications, and a functions list containing any
    #called module functions.

    #Run the module if DoRun is TRUE
    if (DoRun) {
      writeLog(
        "Running module and checking whether outputs meet Set specifications.",
        Print = TRUE
      )
      if (SaveDatastore) {
        writeLog("Also saving module outputs to datastore.", Print = TRUE)
      }
      #Load the module function
      Func <- get(ModuleName)
      #Load any modules identified by 'Call' spec if any
      if (is.list(Specs_ls$Call)) {
        Call <- list(
          Func = list(),
          Specs = list()
        )
        for (Alias in names(Specs_ls$Call)) {
          Function <- Specs_ls$Call[[Alias]]
          Specs <- paste0(Specs_ls$Call[[Alias]], "Specifications")
          Call$Func[[Alias]] <- eval(parse(text = Function))
          Call$Specs[[Alias]] <- processModuleSpecs(eval(parse(text = Specs)))
          Call$Specs[[Alias]]$RunBy <- Specs_ls$RunBy
        }
      }
      #Run module for each year
      if (RunFor == "AllYears") Years <- getYears()
      if (RunFor == "BaseYear") Years <- G$BaseYear
      if (RunFor == "NotBaseYear") Years <- getYears()[!getYears() %in% G$BaseYear]
      for (Year in Years) {
        ResultsCheck_ <- character(0)
        #If RunBy is 'Region', this code is run
        if (Specs_ls$RunBy == "Region") {
          #Get data from datastore
          L <- getFromDatastore(Specs_ls, RunYear = Year)
          if (exists("Call")) {
            for (Alias in names(Call$Specs)) {
              L[[Alias]] <-
                getFromDatastore(Call$Specs[[Alias]], RunYear = Year)
            }
          }
          #Run module
          if (exists("Call")) {
            R <- Func(L, Call$Func)
          } else {
            R <- Func(L)
          }
          #Check for errors and warnings in module return list
          #Save results in datastore if no errors from module
          if (is.null(R$Errors)) {
            #Check results
            Check_ <-
              checkModuleOutputs(
                Data_ls = R,
                ModuleSpec_ls = Specs_ls,
                ModuleName = ModuleName)
            ResultsCheck_ <- Check_
            #Save results if SaveDatastore and no errors found
            if (SaveDatastore & length(Check_) == 0) {
              setInDatastore(R, Specs_ls, ModuleName, Year, Geo = NULL)
            }
          }
          #Handle warnings
          if (!is.null(R$Warnings)) {
            writeLog(R$Warnings)
            Msg <-
              paste0("Module ", ModuleName, " has reported one or more warnings. ",
                     "Check log for details.")
            warning(Msg)
          }
          #Handle errors
          if (!is.null(R$Errors) & StopOnErr) {
            writeLog(R$Errors)
            Msg <-
              paste0("Module ", ModuleName, " has reported one or more errors. ",
                     "Check log for details.")
            stop(Msg)
          }
        #Otherwise the following code is run
        } else {
          #Initialize vectors to store module errors and warnings
          Errors_ <- character(0)
          Warnings_ <- character(0)
          #Identify the units of geography to iterate over
          GeoCategory <- Specs_ls$RunBy
          #Create the geographic index list
          GeoIndex_ls <- createGeoIndexList(c(Specs_ls$Get, Specs_ls$Set), GeoCategory, Year)
          if (exists("Call")) {
            for (Alias in names(Call$Specs)) {
              GeoIndex_ls[[Alias]] <-
                createGeoIndexList(Call$Specs[[Alias]]$Get, GeoCategory, Year)
            }
          }
          #Run module for each geographic area
          Geo_ <- readFromTable(GeoCategory, GeoCategory, Year)
          for (Geo in Geo_) {
            #Get data from datastore for geographic area
            L <-
              getFromDatastore(Specs_ls, RunYear = Year, Geo = Geo, GeoIndex_ls = GeoIndex_ls)
            if (exists("Call")) {
              for (Alias in names(Call$Specs)) {
                L[[Alias]] <-
                  getFromDatastore(Call$Specs[[Alias]], RunYear = Year, Geo = Geo, GeoIndex_ls = GeoIndex_ls[[Alias]])
              }
            }
            #Run model for geographic area
            if (exists("Call")) {
              R <- Func(L, Call$Func)
            } else {
              R <- Func(L)
            }
            #Check for errors and warnings in module return list
            #Save results in datastore if no errors from module
            if (is.null(R$Errors)) {
              #Check results
              Check_ <-
                checkModuleOutputs(
                  Data_ls = R,
                  ModuleSpec_ls = Specs_ls,
                  ModuleName = ModuleName)
              ResultsCheck_ <- c(ResultsCheck_, Check_)
              #Save results if SaveDatastore and no errors found
              if (SaveDatastore & length(Check_) == 0) {
                setInDatastore(R, Specs_ls, ModuleName, Year, Geo = Geo, GeoIndex_ls = GeoIndex_ls)
              }
            }
            #Handle warnings
            if (!is.null(R$Warnings)) {
              writeLog(R$Warnings)
              Msg <-
                paste0("Module ", ModuleName, " has reported one or more warnings. ",
                       "Check log for details.")
              warning(Msg)
            }
            #Handle errors
            if (!is.null(R$Errors) & StopOnErr) {
              writeLog(R$Errors)
              Msg <-
                paste0("Module ", ModuleName, " has reported one or more errors. ",
                       "Check log for details.")
              stop(Msg)
            }
          }
        }
        if (length(ResultsCheck_) != 0) {
          Msg <-
            paste0("Following are inconsistencies between module outputs and the ",
                   "module Set specifications:")
          Msg <- paste(c(Msg, ResultsCheck_), collapse = "\n")
          writeLog(Msg)
          rm(Msg)
          stop(
            paste0("The outputs for module ", ModuleName, " are inconsistent ",
                   "with one or more of the module's Set specifications. ",
                   "Check the log for details."))
        }
      }
      writeLog("Module run successfully and outputs meet Set specifications.",
               Print = TRUE)
      if (SaveDatastore) {
        writeLog("Module outputs saved to datastore.", Print = TRUE)
      }
      #Print success message if no errors found
      Msg <- paste0("Congratulations. Module ", ModuleName, " passed all tests.")
      writeLog(Msg, Print = TRUE)
      rm(Msg)

      #Return the specifications, data list, and functions list if DoRun is FALSE
    } else {
      #Load any modules identified by 'Call' spec if any
      if (!is.null(Specs_ls$Call)) {
        Call <- list(
          Func = list(),
          Specs = list()
        )
        for (Alias in names(Specs_ls$Call)) {
          Function <- Specs_ls$Call[[Alias]]
          Specs <- paste0(Specs_ls$Call[[Alias]], "Specifications")
          Call$Func[[Alias]] <- eval(parse(text = Function))
          Call$Specs[[Alias]] <- processModuleSpecs(eval(parse(text = Specs)))
        }
      }
      #Get data from datastore
      if (RunFor == "AllYears") Year <- getYears()[1]
      if (RunFor == "BaseYear") Year <- G$BaseYear
      if (RunFor == "NotBaseYear") Year <- getYears()[!getYears() %in% G$BaseYear][1]
      L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = NULL)
      if (exists("Call")) {
        for (Alias in names(Call$Specs)) {
          L[[Alias]] <-
            getFromDatastore(Call$Specs[[Alias]], RunYear = Year, Geo = NULL)
        }
      }
      #Return the specifications, data list, and called functions
      if (exists("Call")) {
        return(list(Specs_ls = Specs_ls, L = L, M = Call$Func))
      } else {
        return(list(Specs_ls = Specs_ls, L = L))
      }
    }
  }


#BINARY SEARCH FUNCTION
#======================
#' Binary search function to find a parameter which achieves a target value.
#'
#' \code{binarySearch} a visioneval framework module developer function that
#' uses a binary search algorithm to find the value of a function parameter for
#' which the function achieves a target value.
#'
#' A binary search algorithm is used by several modules to calibrate the
#' intercept of a binary logit model to match a specified proportion or to
#' calibrate a dispersion parameter for a linear model to match a mean value.
#' This function implements a binary search algorithm in a consistent manner to
#' be used in all modules that need it. It is written to work with stochastic
#' models which by their nature don't produce the same outputs given the same
#' inputs and so will not converge reliably. To deal with the stochasticity,
#' this function uses a successive averaging  approach to smooth out the effect
#' of stochastic variation on reliable convergence. Rather than use the results
#' of a single search iteration to determine the next value range to use in the
#' search, a weighted average of previous values is used with the more recent
#' values being weighted more heavily.
#'
#' @param Function a function which returns a value which is compared to the
#' 'Target' argument. The function must take as its first argument a value which
#' from the 'SearchRange_'. It must return a value that may be compared to the
#' 'Target' value.
#' @param SearchRange_ a two element numeric vector which has the lowest and
#' highest values of the parameter range within which the search will be carried
#' out.
#' @param ... one or more optional arguments for the 'Function'.
#' @param Target a numeric value that is compared with the return value of the
#' 'Function'.
#' @param DoWtAve a logical indicating whether successive weighted averaging is
#' to be done. This is useful for getting stable results for stochastic
#' calculations.
#' @param MaxIter an integer specifying the maximum number of iterations
#' to all the search to attempt.
#' @param Tolerance a numeric value specifying the proportional difference
#' between the 'Target' and the return value of the 'Function' to determine
#' when the search is complete.
#' @return the value in the 'SearchRange_' for the function parameter which
#' matches the target value.
#' @export
binarySearch <-
  function(Function,
           SearchRange_,
           ...,
           Target = 0,
           DoWtAve = TRUE,
           MaxIter = 100,
           Tolerance = 0.0001) {
    #Initialize vectors of low, middle and high values
    Lo_ <- SearchRange_[1]
    Mid_ <- mean(SearchRange_)
    Hi_ <- SearchRange_[2]
    #Initialize vector to store weighted average of middle value
    WtMid_ <- numeric(0)
    #Define function to calculate weighted average value of a vector
    calcWtAve <- function(Values_) {
      Wts_ <- (1:length(Values_))^2 / sum((1:length(Values_))^2)
      sum(Values_ * Wts_)
    }
    #Iterate to find best fit
    for (i in 1:MaxIter) {
      Lo <- calcWtAve(Lo_)
      Hi <- calcWtAve(Hi_)
      #Range of input values to test
      InValues_ <- c(Lo, (Lo + Hi) / 2, Hi)
      #Apply Function to calculate results for the InValues_ vector
      Result_ <-
        sapply(InValues_, Function, ...)
      #Check whether any values of Result_ are NA
      if (any(is.na(Result_))) {
        Msg <-
          paste0("Error in 'binarySearch' function to match target value. ",
                 "The low and/or high values of the search range produce ",
                 "NA results. The low result is ", Result_[1], ". ",
                 "The high result is ", Result_[2], ". ",
                 "Modify the search range to avoid NA values.")
        stop(Msg)
      }
      #Determine which two Result_ values bracket the target value
      GT_ <- Result_ > Target
      Idx <- which(diff(GT_) != 0)
      #Calculate new low and high values
      if (length(Idx) > 0) {
        Lo_ <- c(Lo_, InValues_[Idx])
        Hi_ <- c(Hi_, InValues_[Idx + 1])
        Mid_ <- c(Mid_, mean(c(InValues_[Idx], InValues_[Idx + 1])))
      } else {
        MinIdx <- which(abs(Result_ - Target) == min(abs(Result_ - Target)))
        Lo_ <- c(Lo_, tail(Lo_, 1))
        Hi_ <- c(Hi_, tail(Hi_, 1))
        Mid_ <- c(Mid_, tail(Mid_, 1))
      }
      WtMid_ <- c(WtMid_, calcWtAve(Mid_))
      #Break out of loop if change in weighted mean of midpoint is less than tolerance
      if (length(Mid_) > 10) {
        Chg <- abs(diff(tail(Mid_, 4)) / tail(Mid_, 3))
        if (all(Chg < Tolerance)) break()
      }
    }
    #Return the weighted average of the midpoint value
    if (DoWtAve) {
      Result <- tail(WtMid_, 1)
    } else {
      Result <- tail(Mid_, 1)
    }
    Result
  }


#MAKE A MODEL FORMULA STRING
#===========================
#' Makes a string representation of a model equation.
#'
#' \code{makeModelFormulaString} a visioneval framework module developer
#' function that creates a string equivalent of a model equation.
#'
#' The return values of model estimation functions such as 'lm' and 'glm'
#' contain a large amount of information in addition to the parameter estimates
#' for the specified model. This is particularly the case when the estimation
#' dataset is large. Most of this information is not needed to apply the model
#' and including it can add substantially to the size of a package that includes
#' several estimated models. All that is really needed to implement an estimated
#' model is an equation of the model terms and estimated coefficients. This
#' function creates a string representation of the model equation.
#'
#' @param EstimatedModel the return value of the 'lm' or 'glm' functions.
#' @return a string expression of the model equation.
#' @export
makeModelFormulaString <- function (EstimatedModel) {
  # Extract the model coefficients
  Coeff. <- coefficients( EstimatedModel )
  # Make the model formula
  FormulaString <- gsub( ":", " * ", names( Coeff. ) )
  FormulaString[ 1 ] <- "Intercept"
  FormulaString <- paste( Coeff., FormulaString, sep=" * " )
  FormulaString <- paste( FormulaString, collapse= " + " )
  return(FormulaString)
}


#APPLY A BINOMIAL MODEL
#======================
#' Applies an estimated binomial model to a set of input values.
#'
#' \code{applyBinomialModel} a visioneval framework module developer function
#' that applies an estimated binomial model to a set of input data.
#'
#' The function calculates the result of applying a binomial logit model to a
#' set of input data. If a target proportion (TargetProp) is specified, the
#' function calls the 'binarySearch' function to calculate an adjustment to
#' the constant of the model equation so that the population proportion matches
#' the target proportion. The function will also test whether the target search
#' range specified for the model will produce acceptable values.
#'
#' @param Model_ls a list which contains the following components:
#' 'Type' which has a value of 'binomial';
#' 'Formula' a string representation of the model equation;
#' 'Choices' a two-element vector listing the choice set. The first element is
#' the choice that the binary logit model equation predicts the odds of;
#' 'PrepFun' a function which prepares the input data frame for the model
#' application. If no preparation, this element of the list should not be
#' present or should be set equal to NULL;
#' 'SearchRange' a two-element numeric vector which specifies the acceptable
#' search range to use when determining the factor for adjusting the model
#' constant.
#' 'RepeatVar' a string which identifies the name of a field to use for
#' repeated draws of the model. This is used in the case where for example the
#' input data is households and the output is vehicles and the repeat variable
#' is the number of vehicles in the household.
#' 'ApplyRandom' a logical identifying whether the results will be affected by
#' random draws (i.e. if a random number in range 0 - 1 is less than the
#' computed probability) or if a probability cutoff is used (i.e. if the
#' computed probability is greater then 0.5). This is an optional component. If
#' it isn't present, the function runs with ApplyRandom = TRUE.
#'
#' @param Data_df a data frame containing the data required for applying the
#' model.
#' @param TargetProp a number identifying a target proportion for the default
#' choice to be achieved for the input data or NULL if there is no target
#' proportion to be achieved.
#' @param CheckTargetSearchRange a logical identifying whether the function
#' is to only check whether the specified 'SearchRange' for the model will
#' produce acceptable values (i.e. no NA or NaN values). If FALSE (the default),
#' the function will run the model and will not check the target search range.
#' @param ApplyRandom a logical identifying whether the outcome will be
#' be affected by random draws (i.e. if a random number in range 0 - 1 is less
#' than the computed probability) or if a probability cutoff is used (i.e. if
#' the computed probability is greater than 0.5)
#' @return a vector of choice values for each record of the input data frame if
#' the model is being run, or if the function is run to only check the target
#' search range, a two-element vector identifying if the search range produces
#' NA or NaN values.
#' @export
applyBinomialModel <-
  function(Model_ls,
           Data_df,
           TargetProp = NULL,
           CheckTargetSearchRange = FALSE,
           ApplyRandom = TRUE) {
    #Check that model is 'binomial' type
    if (Model_ls$Type != "binomial") {
      Msg <- paste0("Wrong model type. ",
                    "Model is identified as Type = ", Model_ls$Type, ". ",
                    "Function only works with 'binomial' type models.")
      stop(Msg)
    }
    #Check whether Model_ls has ApplyRandom component and assign value if so
    if (!is.null(Model_ls$ApplyRandom)) {
      ApplyRandom <- Model_ls$ApplyRandom
    }
    #Prepare data
    if (!is.null(Model_ls$PrepFun)) {
      Data_df <- Model_ls$PrepFun(Data_df)
    }
    #Define function to calculate probabilities
    calcProbs <- function(x) {
      Results_ <- x + eval(parse(text = Model_ls$Formula), envir = Data_df)
      if (!is.null(Model_ls$RepeatVar)) {
        Results_ <- rep(Results_, Data_df[[Model_ls$RepeatVar]])
      }
      Odds_ <- exp(Results_)
      Odds_ / (1 + Odds_)
    }
    #Define function to calculate factor to match target proportion
    checkProportionMatch <- function(TestValue) {
      Probs_ <- calcProbs(TestValue)
      sum(Probs_) / length(Probs_)
    }
    #Define a function to assign results
    if (ApplyRandom) {
      assignResults <- function(Probs_) {
        N <- length(Probs_)
        Result_ <- rep(Model_ls$Choices[2], N)
        Result_[runif(N) <= Probs_] <- Model_ls$Choices[1]
        Result_
      }
    } else {
      assignResults <- function(Probs_) {
        ifelse(Probs_ > 0.5, Model_ls$Choices[1], Model_ls$Choices[2])
      }
    }
    #Apply the model
    if (CheckTargetSearchRange) {
      Result_ <- c(
        Lo = checkProportionMatch(Model_ls$SearchRange[1]),
        Hi = checkProportionMatch(Model_ls$SearchRange[2])
      )
    } else {
      if (is.null(TargetProp)) {
        Probs_ <- calcProbs(0)
        Result_ <- assignResults(Probs_)
      } else {
        if (TargetProp == 0 | TargetProp == 1) {
          if (TargetProp == 0) Result_ <- rep(Model_ls$Choices[2], nrow(Data_df))
          if (TargetProp == 1) Result_ <- rep(Model_ls$Choices[1], nrow(Data_df))
        } else {
          Factor <- binarySearch(checkProportionMatch, Model_ls$SearchRange, Target = TargetProp)
          Probs_ <- calcProbs(Factor)
          Result_ <- assignResults(Probs_)
        }
      }
    }
    #Return values
    Result_
  }


#APPLY A LINEAR MODEL
#====================
#' Applies an estimated linear model to a set of input values.
#'
#' \code{applyLinearModel} a visioneval framework module developer function that
#' applies an estimated linear model to a set of input data.
#'
#' The function calculates the result of applying a linear regression model to a
#' set of input data. If a target mean value (TargetMean) is specified, the
#' function calculates a standard deviation of a sampling distribution which
#' is applied to linear model results. For each value returned by the linear
#' model, a sample is drawn from a normal distribution where the mean value of
#' the distribution is the linear model result and the standard deviation of the
#' distibution is calculated by the binary search to match the population mean
#' value to the target mean value. This process is meant to be applied to linear
#' model where the dependent variable is power transformed. Applying the
#' sampling distribution to the linear model results increases the dispersion
#' of results to match the observed dispersion and also matches the mean values
#' of the untransformed results. This also enables the model to be applied to
#' situations where the mean value is different than the observed mean value.
#'
#' @param Model_ls a list which contains the following components:
#' 'Type' which has a value of 'linear';
#' 'Formula' a string representation of the model equation;
#' 'PrepFun' a function which prepares the input data frame for the model
#' application. If no preparation, this element of the list should not be
#' present or should be set equal to NULL;
#' 'SearchRange' a two-element numeric vector which specifies the acceptable
#' search range to use when determining the dispersion factor.
#' 'OutFun' a function that is applied to transform the results of applying the
#' linear model. For example to untransform a power-transformed variable. If
#' no transformation is necessary, this element of the list should not be
#' present or should be set equal to NULL.
#' @param Data_df a data frame containing the data required for applying the
#' model.
#' @param TargetMean a number identifying a target mean value to be achieved  or
#' NULL if there is no target.
#' @param CheckTargetSearchRange a logical identifying whether the function
#' is to only check whether the specified 'SearchRange' for the model will
#' produce acceptable values (i.e. no NA or NaN values). If FALSE (the default),
#' the function will run the model and will not check the target search range.
#' @return a vector of numeric values for each record of the input data frame if
#' the model is being run, or if the function is run to only check the target
#' search range, a summary of predicted values when the model is run with
#' dispersion set at the high value of the search range.
#' @export
applyLinearModel <-
  function(Model_ls,
           Data_df,
           TargetMean = NULL,
           CheckTargetSearchRange = FALSE) {
    #Prepare data
    if (!is.null(Model_ls$PrepFun)) {
      Data_df <- Model_ls$PrepFun(Data_df)
    }
    #Define function for applying linear model
    calcValues <- function() {
      eval(parse(text = Model_ls$Formula), envir = Data_df)
    }
    #Define function to test match with TargetMean
    testModelMean <- function(SD) {
      Values_ <- calcValues()
      Est_ <- Values_ + rnorm(length(Values_), 0, sd = SD)
      if (!is.null(Model_ls$OutFun)) Est_ <- Model_ls$OutFun(Est_)
      TargetMean - mean(Est_)
    }
    #Define function for checking target search range
    testSearchRange <- function(Range_) {
      Values_ <- calcValues()
      Est_ <- Values_ + rnorm(length(Values_), 0, sd = Range_[2])
      if (!is.null(Model_ls$OutFun)) Est_ <- Model_ls$OutFun(Est_)
      Est_
    }
    #Calculate result
    if (CheckTargetSearchRange) {
      Result_ <- summary(testSearchRange(Model_ls$SearchRange))
    } else {
      if (is.null(TargetMean)) {
        Result_ <- calcValues()
        if (!is.null(Model_ls$OutFun)) Result_ <- Model_ls$OutFun(Result_)
      } else {
        SD <- binarySearch(testModelMean, Model_ls$SearchRange)
        Values_ <- calcValues()
        Result_ <- Values_ + rnorm(length(Values_), 0, sd = SD)
        if (!is.null(Model_ls$OutFun)) Result_ <- Model_ls$OutFun(Result_)
        attributes(Result_) <- list(SD = SD)
      }
    }
    Result_
  }


#WRITE TO THE VISIONEVAL NAME REGISTRY
#=====================================
#' Writes module Inp and Set specifications to the VisionEval name registry.
#'
#' \code{writeVENameRegistry} a visioneval framework control function that
#' writes module Inp and Set specifications to the VisionEval name registry.
#'
#' The VisionEval name registry (VENameRegistry.json) keeps track of the
#' dataset names created by all registered modules by reading in datasets
#' specified in the module Inp specifications or by returning calculated
#' datasets as specified in the module Set specifications. This functions adds
#' the Inp and Set specifications for a module to the registry. It removes any
#' existing entries for the module first.
#'
#' @param ModuleName a string identifying the module name.
#' @param PackageName a string identifying the package name.
#' @param NameRegistryDir a string identifying the path to the directory
#' where the name registry file is located.
#' @return TRUE if successful. Has a side effect of updating the VisionEval
#' name registry.
#' @export
writeVENameRegistry <-
  function(ModuleName, PackageName, NameRegistryDir = NULL) {
    #Check whether the name registry file exists
    if (is.null(NameRegistryDir)) {
      NameRegistryFile <- "VENameRegistry.json"
    } else {
      NameRegistryFile <- file.path(NameRegistryDir, "VENameRegistry.json")
    }
    if (!file.exists(NameRegistryFile)) {
      stop("VENameRegistry.json file is not present in the identified directory.")
    }
    #Read in the name registry file as a list
    NameRegistry_ls <-
      fromJSON(readLines(NameRegistryFile), simplifyDataFrame = FALSE)
    #Remove any existing registry entries for the module
    for (x in c("Inp", "Set")) {
      NameRegistry_df <- readVENameRegistry()
      ExistingModuleEntries_ <-
        NameRegistry_df[[x]]$MODULE == ModuleName &
        NameRegistry_df[[x]]$PACKAGE == PackageName
      NameRegistry_ls[[x]] <- NameRegistry_ls[[x]][!ExistingModuleEntries_]
    }
    #Process the Inp and Set specifications
    ModuleSpecs_ls <-
      processModuleSpecs(getModuleSpecs(ModuleName, PackageName))
    Inp_ls <-
      lapply(ModuleSpecs_ls$Inp, function(x) {
        x$PACKAGE <- PackageName
        x$MODULE <- ModuleName
        x
      })
    Set_ls <-
      lapply(ModuleSpecs_ls$Set, function(x) {
        x$PACKAGE <- PackageName
        x$MODULE <- ModuleName
        x
      })
    #Add the the module specifications to the registry
    NameRegistry_ls$Inp <- c(NameRegistry_ls$Inp, Inp_ls)
    NameRegistry_ls$Set <- c(NameRegistry_ls$Set, Set_ls)
    #Save the revised name registry
    writeLines(toJSON(NameRegistry_ls), NameRegistryFile)
    TRUE
  }


#READ THE VISIONEVAL NAME REGISTRY
#=================================
#' Reads the VisionEval name registry.
#'
#' \code{readVENameRegistry} a visioneval framework module developer function
#' that reads the VisionEval name registry and returns a list of data frames
#' containing the Inp and Set specifications.
#'
#' The VisionEval name registry (VENameRegistry.json) keeps track of the
#' dataset names created by all registered modules by reading in datasets
#' specified in the module Inp specifications or by returning calculated
#' datasets as specified in the module Set specifications. This function reads
#' the VisionEval name registry and returns a list of data frames containing the
#' registered Inp and Set specifications.
#'
#' @param NameRegistryDir a string identifying the path to the directory
#' where the name registry file is located.
#' @return A list having two components: Inp and Set. Each component is a data
#' frame containing the respective Inp and Set specifications of registered
#' modules.
#' @export
readVENameRegistry <-
  function(NameRegistryDir = NULL) {
    #Check whether the name registry file exists
    if (is.null(NameRegistryDir)) {
      NameRegistryFile <- "VENameRegistry.json"
    } else {
      NameRegistryFile <- file.path(NameRegistryDir, "VENameRegistry.json")
    }
    if (!file.exists(NameRegistryFile)) {
      stop("VENameRegistry.json file is not present in the identified directory.")
    }
    #Read in the name registry file
    fromJSON(readLines(NameRegistryFile))
  }


#GET REGISTERED GET SPECIFICATIONS
#=================================
#' Returns Get specifications for registered datasets.
#'
#' \code{getRegisteredGetSpecs} a visioneval framework module developer function
#' that returns a data frame of Get specifications for datasets in the
#' VisionEval name registry.
#'
#' The VisionEval name registry (VENameRegistry.json) keeps track of the
#' dataset names created by all registered modules by reading in datasets
#' specified in the module Inp specifications or by returning calculated
#' datasets as specified in the module Set specifications. This function
#' reads in the name registry and returns Get specifications for identified
#' datasets.
#'
#' @param Names_ A character vector of the dataset names to get specifications
#' for.
#' @param Tables_ A character vector of the tables that the datasets are a part
#' of.
#' @param Groups_ A character vector of the groups that the tables are a part of.
#' @param NameRegistryDir a string identifying the path to the directory
#' where the name registry file is located.
#' @return A data frame containing the Get specifications for the identified
#' datasets.
#' @export
getRegisteredGetSpecs <-
  function(Names_, Tables_, Groups_, NameRegistryDir = NULL) {
    #Put Names_, Tables_, Groups_ into data frame
    Datasets_df <-
      data.frame(
        NAME = Names_,
        TABLE = Tables_,
        GROUP = Groups_
      )
    #Check whether the name registry file exists
    if (is.null(NameRegistryDir)) {
      NameRegistryFile <- "VENameRegistry.json"
    } else {
      NameRegistryFile <- file.path(NameRegistryDir, "VENameRegistry.json")
    }
    if (!file.exists(NameRegistryFile)) {
      stop("VENameRegistry.json file is not present in the identified directory.")
    }
    #Read in the name registry file
    NameRegistry_df <- fromJSON(readLines(NameRegistryFile))
    #Identify attributes to return
    AttrNames_ <-
      c("NAME", "TABLE", "GROUP", "TYPE", "UNITS", "PROHIBIT", "ISELEMENTOF")
    #Define function to return records matching criteria
    extractRecords <- function(Data_df) {
      ToGetIdxNames_ <- apply(Datasets_df, 1, paste, collapse = "-")
      DataIdxNames_ <- apply(Data_df[,c("NAME", "TABLE", "GROUP")], 1, paste, collapse = "-")
      Data_df <- Data_df[DataIdxNames_ %in% ToGetIdxNames_, AttrNames_]
    }
    #Extract the specifications to be returned
    Specs_df <-
      rbind(extractRecords(NameRegistry_df$Inp),
            extractRecords(NameRegistry_df$Set))
    #Return data frame of identified Get specifications
    Specs_df
  }


#DOCUMENT A MODULE
#=================
#' Produces markdown documentation for a module
#'
#' \code{documentModule} a visioneval framework module developer function
#' that creates a vignettes directory if one does not exist and produces
#' module documentation in markdown format which is saved in the vignettes
#' directory.
#'
#' This function produces documentation for a module in markdown format. A
#' 'vignettes' directory is created if it does not exist and the markdown file
#' and any associated resources such as image files are saved in that directory.
#' The function is meant to be called within and at the end of the module
#' script. The documentation is created from a commented block within the
#' module script which is enclosed by the opening tag, <doc>, and the closing
#' tag, </doc>. (Note, these tags must be commented along with all the other
#' text in the block). This commented block may also include tags which identify
#' resources to include within the documentation. These tags identify the
#' type of resource and the name of the resource which is located in the 'data'
#' directory. A colon (:) is used to separate the resource type and resource
#' name identifiers. For example:
#' <txt:DvmtModel_ls$EstimationStats$NonMetroZeroDvmt_GLM$Summary>
#' is a tag which will insert text which is located in a component of the
#' DvmtModel_ls list that is saved as an rdata file in the 'data' directory
#' (i.e. data/DvmtModel_ls.rda). The following 3 resource types are recognized:
#' * txt - a vector of strings which are inserted as lines of text in a code block
#' * fig - a png file which is inserted as an image
#' * tab - a matrix or data frame which is inserted as a table
#' The function also reads in the module specifications and creates
#' tables that document user input files, data the module gets from the
#' datastore, and the data the module produces that is saved in the datastore.
#' This function is intended to be called in the R script which defines the
#' module. It is placed near the end of the script (after the portions of the
#' script which estimate module parameters and define the module specifications)
#' so that it is run when the package is built. It may not properly in other
#' contexts.
#'
#' @param ModuleName A string identifying the name of the module
#' (e.g. 'CalculateHouseholdDvmt')
#' @return None. The function has the side effects of creating a 'vignettes'
#' directory if one does not exist, copying identified 'fig' resources to the
#' 'vignettes' directory, and saving the markdown documentation file to the
#' 'vignettes' directory. The markdown file is named with the module name and
#' has a 'md' suffix.
#' @export
documentModule <- function(ModuleName){

  #Make vignettes directory if doesn't exist
  #-----------------------------------------
  if(!file.exists("vignettes")) dir.create("vignettes")

  #Define function to trim strings
  #-------------------------------
  trimStr <-
    function(String, Delimiters = NULL, Indices = NULL, Characters = NULL) {
      Chars_ <- unlist(strsplit(String, ""))
      if (!is.null(Delimiters)) {
        Start <- which(Chars_ == Delimiters[1]) + 1
        End <- which(Chars_ == Delimiters[2]) - 1
        Result <- paste(Chars_[Start:End], collapse = "")
      }
      if (!is.null(Indices)) {
        Result <- paste(Chars_[-Indices], collapse = "")
      }
      if (!is.null(Characters)) {
        Result <- paste(Chars_[!(Chars_ %in% Characters)], collapse = "")
      }
      Result
    }

  #Define function to split documentation into list
  #------------------------------------------------
  splitDocs <-
    function(Docs_, Idx_) {
      Starts_ <- c(1, Idx_ + 1)
      Ends_ <- c(Idx_ - 1, length(Docs_))
      apply(cbind(Starts_, Ends_), 1, function(x) Docs_[x[1]:x[2]])
    }

  #Define function to process documentation tag
  #--------------------------------------------
  #Returns list identifying documentation type and reference
  processDocTag <- function(DocTag) {
    DocTag <- trimStr(DocTag, Delimiters = c("<", ">"))
    DocTagParts_ <- unlist(strsplit(DocTag, ":"))
    if (length(DocTagParts_) != 2) {
      DocTag_ <- c(Type = "none", Reference = "none")
    } else {
      DocTag_ <- DocTagParts_
      names(DocTag_) <- c("Type", "Reference")
      DocTag_["Type"] <- tolower(DocTag_["Type"])
      if (!(DocTag_["Type"] %in% c("txt", "tab", "fig"))) {
        DocTag_["Type"] <- "none"
      }
    }
    DocTag_
  }

  #Define function to insert Rmarkdown for 'txt' tags
  #--------------------------------------------------
  insertTxtMarkdown <- function(Reference) {
    Object <- unlist(strsplit(Reference, "\\$"))[1]
    File <- paste0("data/", Object, ".rda")
    if (file.exists(File)) {
      load(File)
      if (!is.null(eval(parse(text = Reference)))) {
        Markdown_ <- c(
          "```",
          eval(parse(text = Reference)),
          "```"
        )
        rm(list = Object)
      } else {
        return("Error in module documentation tag reference")
      }
    } else {
      return("Error in module documentation tag reference")
    }
    Markdown_
  }

  #Define function to insert Rmarkdown for 'fig' tags
  #--------------------------------------------------
  insertFigMarkdown <- function(Reference) {
    FromFile <- paste0("data/", Reference)
    ToFile <- gsub("data", "vignettes", FromFile)
    if (file.exists(FromFile)) {
      file.copy(from = FromFile, to = ToFile)
      Markdown_ <- paste0("![", Reference, "](", Reference, ")")
    } else {
      return("Error in module documentation tag reference")
    }
    Markdown_
  }

  #Define function to insert Rmarkdown for 'tab' tags
  #--------------------------------------------------
  insertTabMarkdown <- function(Reference) {
    Object <- unlist(strsplit(Reference, "\\$"))[1]
    File <- paste0("data/", Object, ".rda")
    if (file.exists(File)) {
      load(File)
      if (!is.null(eval(parse(text = Reference)))) {
        Table_df <- eval(parse(text = Reference))
        ColNames <- colnames(Table_df)
        Markdown_ <- c(
          "",
          kable(
            eval(Table_df),
            format = "markdown",
            col.names = ColNames)
        )
        rm(list = Object, Table_df, ColNames)
      } else {
        return("Error in module documentation tag reference")
      }
    } else {
      return("Error in module documentation tag reference")
    }
    Markdown_
  }

  #Locate documentation portion of script and strip off leading comments
  #---------------------------------------------------------------------
  FilePath <- paste0("R/", ModuleName, ".R")
  Text_ <- readLines(FilePath)
  DocStart <- grep("#<doc>", Text_) + 1
  DocEnd <- grep("#</doc>", Text_) - 1
  Docs_ <-
    unlist(lapply(Text_[DocStart:DocEnd], function(x) trimStr(x, Indices = 1)))

  #Define knitr setup code for formatting statistics documentation
  #---------------------------------------------------------------
  KnitrSetup_ <- c(
    "```{r setup, include=FALSE}",
    "knitr::opts_chunk$set(echo = TRUE)",
    "```"
  )

  #Insert knitr code for inserting documentation tag information
  #-------------------------------------------------------------
  #Locate statistics documentation tags
  TagIdx_ <- grep("<", Docs_)
  #Split documentation into list of components before and after tags
  Docs_ls <- splitDocs(Docs_, TagIdx_)
  #Initialize new list into which knitr-processed tags will be inserted
  RevDocs_ls <- list(
    list(KnitrSetup_),
    Docs_ls[1]
  )
  #Iterate through tags and insert knitr-processed tags
  for (n in 1:length(TagIdx_)) {
    Idx <- TagIdx_[n]
    DocTag_ <- processDocTag(Docs_[Idx])
    if (DocTag_["Type"] == "none") {
      Markdown_ <- "Error in module documentation tag"
    }
    if (DocTag_["Type"] == "txt") {
      Markdown_ <- insertTxtMarkdown(DocTag_["Reference"])
    }
    if (DocTag_["Type"] == "fig") {
      Markdown_ <- insertFigMarkdown(DocTag_["Reference"])
    }
    if (DocTag_["Type"] == "tab") {
      Markdown_ <- insertTabMarkdown(DocTag_["Reference"])
    }
    RevDocs_ls <- c(
      RevDocs_ls,
      list(Markdown_),
      Docs_ls[n + 1]
    )
  }

  #Load module specifications
  #--------------------------
  #Define function to process specifications
  processModuleSpecs <- function(Spec_ls) {
    #Define a function to process a component of a specifications list
    processComponent <- function(Component_ls, ComponentName) {
      Result_ls <- list()
      for (i in 1:length(Component_ls)) {
        Temp_ls <- Component_ls[[i]]
        Result_ls <- c(Result_ls, expandSpec(Temp_ls, ComponentName))
      }
      Result_ls
    }
    #Process the list components and return the results
    Out_ls <- list()
    Out_ls$RunBy <- Spec_ls$RunBy
    if (!is.null(Spec_ls$NewInpTable)) {
      Out_ls$NewInpTable <- Spec_ls$NewInpTable
    }
    if (!is.null(Spec_ls$NewSetTable)) {
      Out_ls$NewSetTable <- Spec_ls$NewSetTable
    }
    if (!is.null(Spec_ls$Inp)) {
      FilteredInpSpec_ls <- doProcessInpSpec(Spec_ls$Inp)
      if (length(FilteredInpSpec_ls) > 0) {
        Out_ls$Inp <- processComponent(FilteredInpSpec_ls, "Inp")
      }
    }
    if (!is.null(Spec_ls$Get)) {
      Out_ls$Get <- processComponent(Spec_ls$Get, "Get")
    }
    if (!is.null(Spec_ls$Set)) {
      Out_ls$Set <- processComponent(Spec_ls$Set, "Set")
    }
    if (!is.null(Spec_ls$Call)) {
      Out_ls$Call <- Spec_ls$Call
    }
    Out_ls
  }
  #Define a function to load the specifications
  loadSpecs <- function(ModuleName) {
    ModuleSpecs <- paste0(ModuleName, "Specifications")
    ModuleSpecsFile <- paste0("data/", ModuleSpecs, ".rda")
    load(ModuleSpecsFile)
    eval(parse(text = ModuleSpecs))
  }
  #Define function to creates a data frame from specifications Inp, Get, or Set
  makeSpecsTable <- function(ModuleName, Component) {
    Specs_ls <- processModuleSpecs(loadSpecs(ModuleName))[[Component]]
    Specs_ls <- lapply(Specs_ls, function(x) {
      data.frame(lapply(x, function(y) {
        if (length(y) == 1) {
          y
        } else {
          paste(y, collapse = ", ")
        }
      }))
    })
    do.call(rbind, Specs_ls)
  }
  #Define function to break long strings into lines
  wordWrap <- function(WordString, MaxLength) {
    Words_ls <- list(
      "",
      unlist(strsplit(WordString, " "))
    )
    #Define recursive function to peel off first words from string
    getFirstWords <- function(Words_ls) {
      if (length(Words_ls[[2]]) == 0) {
        return(Words_ls[[1]][-1])
      } else {
        RemWords_ <- Words_ls[[2]]
        NumChar_ <- cumsum(nchar(RemWords_))
        NumChar_ <- NumChar_ + 1
        IsFirst_ <- NumChar_ < MaxLength
        AddString <-paste(RemWords_[IsFirst_], collapse = " ")
        RemWords_ <- RemWords_[!IsFirst_]
        getFirstWords(list(
          c(Words_ls[[1]], AddString),
          RemWords_
        ))
      }
    }
    paste(getFirstWords(Words_ls), collapse = "<br>")
  }

  #Insert documentation of user input files
  #----------------------------------------
  #Make a table of Inp specifications
  InpSpecs_df <- makeSpecsTable(ModuleName, "Inp")
  #Make markdown text
  if (!is.null(InpSpecs_df)) {
    InpMarkdown_ <- c(
      "",
      "## User Inputs",
      "The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:",
      "* NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.",
      "* TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'",
      "* UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.",
      "* PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.",
      "* ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.",
      "* UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.",
      "* DESCRIPTION - A description of the data.",
      ""
    )
    InpSpecs_ls <- split(InpSpecs_df, InpSpecs_df$FILE)
    FileNames_ <- names(InpSpecs_ls)
    for (fn in FileNames_) {
      InpMarkdown_ <- c(
        InpMarkdown_,
        paste("###", fn)
      )
      ColNames_ <-
        c("NAME", "TYPE", "UNITS", "PROHIBIT", "ISELEMENTOF", "UNLIKELY", "DESCRIPTION")
      SpecsTable_df <- InpSpecs_ls[[fn]][, ColNames_]
      # SpecsTable_df$DESCRIPTION <-
      #   unname(sapply(as.character(SpecsTable_df$DESCRIPTION), function(x)
      #   {wordWrap(x, 40)}))
      Geo <- as.character(unique(InpSpecs_ls[[fn]]$TABLE))
      HasGeo <- Geo %in% c("Marea", "Azone", "Bzone", "Czone")
      Year <- as.character(unique(InpSpecs_ls[[fn]]$GROUP))
      if (HasGeo) {
        if (Year == "Year") {
          GeoYearDescription <- wordWrap(paste(
            "Must contain a record for each", Geo, "and model run year."
          ), 40)
        }
        if (Year == "BaseYear") {
          GeoYearDescription <- wordWrap(paste(
            "Must contain a record for each", Geo, "for the base year only."
          ), 40)
        }
        if (Year == "Global") {
          GeoYearDescription <- wordWrap(paste(
            "Must contain a record for each", Geo, "which is applied to all years."
          ), 40)
        }
      } else {
        GeoYearDescription <- wordWrap(paste(
          "Must contain a record for each model run year"
        ), 40)
      }
      if (Year == "Year") {
        Year_df <- data.frame(
          NAME = "Year",
          UNITS = "",
          PROHIBIT = "",
          ISELEMENTOF = "",
          UNLIKELY = "",
          DESCRIPTION = GeoYearDescription
        )
        SpecsTable_df <- rbind(Year_df, SpecsTable_df)
      }
      if (HasGeo) {
        Geo_df <- data.frame(
          NAME = "Geo",
          UNITS = "",
          PROHIBIT = "",
          ISELEMENTOF = paste0(Geo, "s"),
          UNLIKELY = "",
          DESCRIPTION = GeoYearDescription
        )
      }
      InpMarkdown_ <- c(
        InpMarkdown_,
        kable(rbind(Geo_df, SpecsTable_df))
      )
    }
  } else {
    InpMarkdown_ <- c(
      "",
      "## User Inputs",
      "This module has no user input requirements."
    )
  }
  #Add the markdown text to the documentation list
  RevDocs_ls <- c(
    RevDocs_ls,
    list(InpMarkdown_)
  )

  #Insert documentation of module inputs
  #-------------------------------------
  #Make a table of Get specifications
  GetSpecs_df <- makeSpecsTable(ModuleName, "Get")
  #Make markdown text
  if (!is.null(GetSpecs_df)) {
    GetMarkdown_ <- c(
      "",
      "## Datasets Used by the Module",
      "The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:",
      "* NAME - The dataset name.",
      "* TABLE - The table in the datastore that the data is retrieved from.",
      "* GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.",
      "* TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.",
      "* UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.",
      "* PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.",
      "* ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.",
      ""
    )
    ColNames_ <-
      c("NAME", "TABLE", "GROUP", "TYPE", "UNITS", "PROHIBIT", "ISELEMENTOF")
    SpecsTable_df <- GetSpecs_df[, ColNames_]
    GetMarkdown_ <- c(
      GetMarkdown_,
      kable(SpecsTable_df)
    )
  } else {
    GetMarkdown_ <- c(
      "",
      "## Datasets Used by the Module",
      "This module uses no datasets that are in the datastore."
    )
  }
  #Add the markdown text to the documentation list
  RevDocs_ls <- c(
    RevDocs_ls,
    list(GetMarkdown_)
  )

  #Insert documentation of module outputs
  #--------------------------------------
  #Make a table of Set specifications
  SetSpecs_df <- makeSpecsTable(ModuleName, "Set")
  #Make markdown text
  if (!is.null(SetSpecs_df)) {
    SetMarkdown_ <- c(
      "",
      "## Datasets Produced by the Module",
      "The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:",
      "* NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator is inputs are in thousand, millions, etc. The VisionEval users guide should be consulted on how to do that.",
      "* TABLE - The table in the datastore that the data is retrieved from.",
      "* GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.",
      "* TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.",
      "* UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.",
      "* PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.",
      "* ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.",
      "* DESCRIPTION - A description of the data.",
      ""
    )
    ColNames_ <-
      c("NAME", "TABLE", "GROUP", "TYPE", "UNITS", "PROHIBIT", "ISELEMENTOF", "DESCRIPTION")
    SpecsTable_df <- SetSpecs_df[, ColNames_]
    # SpecsTable_df$DESCRIPTION <-
    #   unname(sapply(as.character(SpecsTable_df$DESCRIPTION), function(x)
    #     {wordWrap(x, 40)}))
    SetMarkdown_ <- c(
      SetMarkdown_,
      kable(SpecsTable_df)
    )
  } else {
    SetMarkdown_ <- c(
      "",
      "## Datasets Produced by the Module",
      "This module produces no datasets to store in the datastore."
    )
  }
  #Add the markdown text to the documentation list
  RevDocs_ls <- c(
    RevDocs_ls,
    list(SetMarkdown_)
  )

  #Produce markdown file documentation
  knit(output = paste0("vignettes/", ModuleName, ".md"),
       text = unlist(RevDocs_ls))
}
