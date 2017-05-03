#========
#module.R
#========

#This script defines functions related to the development and use of modules.


#DEFINE LIST ALIAS
#=================
#' Alias for list function.
#'
#' \code{item} is an alias for the list function whose purpose is to make
#' module specifications easier to read.
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
#' \code{items} is an alias for the list function whose purpose is to make
#' module specifications easier to read.
#'
#' This function defines an alternate name for list. It is used in module
#' specifications to identify a group of data items in the Inp, Get, and Set
#' portions of the specifications.
#'
#' @return a list.
#' @export
items <- list


#LOAD ESTIMATION DATA
#====================
#' Load estimation data
#'
#' \code{processEstimationInputs} checks whether specified model estimation data
#' meets specifications and returns the data in a data frame.
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
#' @return A data frame containing the estimation data.
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
  #Return the data frame
  Data_df
}


#CHECK MODULE OUTPUTS FOR CONSISTENCY WITH MODULE SPECIFICATIONS
#===============================================================
#' Check module outputs for consistency with specifications
#'
#' \code{checkModuleOutputs} checks output list produced by a module for
#' consistency with the module's specifications.
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
                paste0("The LENGTH attribute of table, ", TABLE, " in group ",
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
#' \code{testModule} sets up a test environment and tests a module.
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
#' #'
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
#' @return None. The function writes out messages to the console and to the log
#' as the testing proceeds. These messages include the time when each test
#' starts and when it ends. When a key test fails, requiring a fix before other
#' tests can be run, execution stops and an error message is written to the
#' console. Detailed error messages are also written to the log.
#' @export
testModule <-
  function(ModuleName,
           ParamDir = "defs",
           RunParamFile = "run_parameters.json",
           GeoFile = "geo.csv",
           ModelParamFile = "model_parameters.json",
           LoadDatastore = FALSE,
           SaveDatastore = TRUE) {

    #Set working directory to tests and return to main module directory on exit
    #--------------------------------------------------------------------------
    setwd("tests")
    on.exit(setwd("../"))

    #Initialize model state and log files
    #------------------------------------
    Msg <- paste0("Testing ", ModuleName, ".")
    initModelStateFile(Dir = ParamDir, ParamFile = RunParamFile)
    initLog()
    writeLog(Msg, Print = TRUE)
    rm(Msg)

    #Load datastore if specified or initialize new datastore
    #-------------------------------------------------------
    if (LoadDatastore) {
      print("Attempting to load datastore.")
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
        SaveDatastore = SaveDatastore
      )
      writeLog("Datastore loaded.", Print = TRUE)
    } else {
      print("Attempting to initialize datastore.")
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
    writeLog("Module specifications successfully loaded and checked.",
             Print = TRUE)

    #Process, check, and load module inputs
    #--------------------------------------
    writeLog("Attempting to process, check and load module inputs.",
             Print = TRUE)
    ProcessedInputs_ls <- processModuleInputs(Specs_ls, ModuleName)
    if (length(ProcessedInputs_ls$Errors) != 0)  {
      stop("Input files have errors. Check the log for details.")
    }
    inputsToDatastore(ProcessedInputs_ls, Specs_ls, ModuleName)
    writeLog("Module inputs successfully checked and loaded into datastore.",
             Print = TRUE)

    #Check whether datastore contains all data items in Get specifications
    #---------------------------------------------------------------------
    writeLog(
      "Checking whether datastore contains all datasets in Get specifications.",
      Print = TRUE)
    G <- getModelState()
    Get_ls <- Specs_ls$Get
    Missing_ <- character(0)
    for (i in 1:length(Get_ls)) {
      Spec_ls <- Get_ls[[i]]
      if (Spec_ls$GROUP == "Year") {
        for (Year in G$Years) {
          Present <-
            checkDataset(Spec_ls$NAME, Spec_ls$TABLE, Year, G$Datastore)
          if (!Present) Missing_ <- c(Missing_, attributes(Present))
        }
      }
      if (Spec_ls$GROUP == "BaseYear") {
        Present <-
          checkDataset(Spec_ls$NAME, Spec_ls$TABLE, Year, G$Datastore)
        if (!Present) Missing_ <- c(Missing_, attributes(Present))
      }
      if (Spec_ls$GROUP == "Global") {
        Present <-
          checkDataset(Spec_ls$NAME, Spec_ls$TABLE, Year, G$Datastore)
        if (!Present) Missing_ <- c(Missing_, attributes(Present))
      }
    }
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
    writeLog(
      "Datastore contains all datasets identified in module Get specifications.",
      Print = TRUE)

    #Run the module and check that results meet specifications
    #---------------------------------------------------------
    writeLog(
      "Running module and checking whether outputs meet Set specifications.",
      Print = TRUE
    )
    if (SaveDatastore) {
      writeLog("Also saving module outputs to datastore.", Print = TRUE)
    }
    Func <- get(ModuleName)
    for (Year in getYears()) {
      ResultsCheck_ <- character(0)
      if (Specs_ls$RunBy == "Region") {
        #Get data from datastore
        L <- getFromDatastore(Specs_ls, Geo = NULL, RunYear = Year)
        #Run module
        R <- Func(L)
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
      } else {
        GeoCategory <- Specs_ls$RunBy
        Geo_ <- readFromTable(GeoCategory, GeoCategory, Year)
        #Run module for each geographic area
        for (Geo in Geo_) {
          #Get data from datastore for geographic area
          L <- getFromDatastore(Specs_ls, Geo = Geo)
          #Run model for geographic area
          R <- Func(L)
          #Check results
          Check_ <-
            checkModuleOutputs(
              Data_ls = R,
              ModuleSpec_ls = Specs_ls,
              ModuleName = ModuleName)
          ResultsCheck_ <- c(ResultsCheck_, Check_)
          #Save results if SaveDatastore and no errors found
          if (SaveDatastore & length(Check_) == 0) {
            setInDatastore(R, Specs_ls, ModuleName, Year, Geo = Geo)
          }
        }
      }
      if (length(ResultsCheck_) != 0) {
        Msg <-
          paste0("Following are inconsistencies between module outputs and the ",
                 "module Set specifications:")
        Msg <- paste(c(Msg, OutputCheck_), collapse = "\n")
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

    #Finish
    #------
    #Print success message if no errors found
    Msg <- paste0("Congratulations. Module ", ModuleName, " passed all tests.")
    writeLog(Msg, Print = TRUE)
    rm(Msg)
  }
