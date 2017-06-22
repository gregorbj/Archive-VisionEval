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
#' @param DoRun A logical value identifying whether the module should be run. If
#'   FALSE, the function will initialize a datastore, check specifications, and
#'   load inputs but will not run the module but will return the list of module
#'   specifications. That setting is useful for module development in order to
#'   create the all the data needed to assist with module programming. It is
#'   used in conjunction with the getFromDatastore function to create the
#'   dataset that will be provided by the framework. The default value for this
#'   parameter is TRUE. In that case, the module will be run and the results
#'   will checked for consistency with the Set specifications.
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
           DoRun = TRUE) {

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
    if(!is.null(Specs_ls$Inp)) {

      writeLog("Attempting to process, check and load module inputs.",
               Print = TRUE)
      ProcessedInputs_ls <- processModuleInputs(Specs_ls, ModuleName)
      if (length(ProcessedInputs_ls$Errors) != 0)  {
        writeLog(ProcessedInputs_ls$Errors)
        stop("Input files have errors. Check the log for details.")
      }
      inputsToDatastore(ProcessedInputs_ls, Specs_ls, ModuleName)
      writeLog("Module inputs successfully checked and loaded into datastore.",
               Print = TRUE)
    } else {
      writeLog("No inputs to process.", Print = TRUE)
    }

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
    #The module is run only if the DoRun argument is TRUE. Otherwise the
    #datastore is initialized, specifications are checked, and inputs are
    #loaded only.
    if (DoRun) {
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
          L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = NULL)
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
            L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = Geo)
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
    } else {
      return(Specs_ls)
    }
  }


#BINARY SEARCH FUNCTION
#======================
#' Binary search function to find a parameter which achieves a target value.
#'
#' \code{binarySearch} uses a binary search algorithm to find the value of a
#' function parameter for which the function achieves a target value.
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
        Chg <- diff(tail(Mid_, 4)) / tail(Mid_, 3)
        if (all(Chg < Tolerance)) break()
      }
    }
    #Return the weighted average of the midpoint value
    tail(WtMid_, 1)
  }


#MAKE A MODEL FORMULA STRING
#===========================
#' Makes a string representation of a model equation.
#'
#' \code{makeModelFormulaString} creates a string equivalent of a model equation.
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
#' \code{applyBinomialModel} applies an estimated binomial model to a set of
#' input data.
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
#' @param Data_df a data frame containing the data required for applying the
#' model.
#' @param TargetProp a number identifying a target proportion for the default
#' choice to be achieved for the input data or NULL if there is no target
#' proportion to be achieved.
#' @param CheckTargetSearchRange a logical identifying whether the function
#' is to only check whether the specified 'SearchRange' for the model will
#' produce acceptable values (i.e. no NA or NaN values). If FALSE (the default),
#' the function will run the model and will not check the target search range.
#' @return a vector of choice values for each record of the input data frame if
#' the model is being run, or if the function is run to only check the target
#' search range, a two-element vector identifying if the search range produces
#' NA or NaN values.
#' @export
applyBinomialModel <-
  function(Model_ls,
           Data_df,
           TargetProp = NULL,
           CheckTargetSearchRange = FALSE) {
    #Check that model is 'binomial' type
    if (Model_ls$Type != "binomial") {
      Msg <- paste0("Wrong model type. ",
                    "Model is identified as Type = ", Model_ls$Type, ". ",
                    "Function only works with 'binomial' type models.")
      stop(Msg)
    }
    #Prepare data
    if (!is.null(Model_ls$PrepFun)) {
      Data_df <- Model_ls$PrepFun(Data_df)
    }
    #Define function to calculate probabilities
    calcProbs <- function(x) {
      Results_ <- x + eval(parse(text = Model_ls$Formula), envir = Data_df)
      Odds_ <- exp(Results_)
      Odds_ / (1 + Odds_)
    }
    #Define function to calculate factor to match target proportion
    checkProportionMatch <- function(TestValue) {
      Probs_ <- calcProbs(TestValue)
      sum(Probs_) / length(Probs_)
    }
    #Define a function to assign results
    assignResults <- function(Probs_) {
      N <- length(Probs_)
      Result_ <- rep(Model_ls$Choices[2], N)
      Result_[runif(N) <= Probs_] <- Model_ls$Choices[1]
      Result_
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
#' \code{applyLinearModel} applies an estimated linear model to a set of input
#' data.
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
#' \code{writeVENameRegistry} writes module Inp and Set specifications to the
#' VisionEval name registry.
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
  function(ModuleName, PackageName, NameRegistryDir = "..") {
    #Check whether the name registry file exists
    NameRegistryFile <- file.path(NameRegistryDir, "VENameRegistry.json")
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
    ModuleSpecs_ls <- processModuleSpecs(getModuleSpecs(ModuleName, PackageName))
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
#' \code{readVENameRegistry} reads the VisionEval name registry and returns a
#' list of data frames containing the Inp and Set specifications.
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
  function(NameRegistryDir = "..") {
    #Check whether the name registry file exists
    NameRegistryFile <- file.path(NameRegistryDir, "VENameRegistry.json")
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
#' \code{getRegisteredGetSpecs} returns properly formatted list of Get
#' specifications for datasets in the VisionEval name registry.
#'
#' The VisionEval name registry (VENameRegistry.json) keeps track of the
#' dataset names created by all registered modules by reading in datasets
#' specified in the module Inp specifications or by returning calculated
#' datasets as specified in the module Set specifications. This function
#' reads in the name registry and returns properly formatted Get specifications
#' for identified datasets.
#'
#' @param Names_ A character vector of the dataset names to get specifications
#' for.
#' @param Tables_ A character vector of the tables that the datasets are a part
#' of.
#' @param Groups_ A character vector of the groups that the tables are a part of.
#' @param NameRegistryDir a string identifying the path to the directory
#' where the name registry file is located.
#' @return A list containing the properly formatted Get specifications for the
#' identified datasets.
#' @export
getRegisteredGetSpecs <-
  function(Names_, Tables_, Groups_, NameRegistryDir = "..") {
    #Put Names_, Tables_, Groups_ into data frame
    Datasets_df <-
      data.frame(
        NAME = Names_,
        TABLE = Tables_,
        GROUP = Groups_
      )
    #Check whether the name registry file exists
    NameRegistryFile <- file.path(NameRegistryDir, "VENameRegistry.json")
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

=======
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
#' @param ModuleName A string identifying the module name; may contain prefix for PackageName
#' @param ProjectDir A string identifying the location of a project. ParamDir ("defs/") can be
#' specified as being relative to ProjectDir, similarly for "Inputs/".
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
           ProjectDir = NULL,
           ParamDir = "defs",
           RunParamFile = "run_parameters.json",
           GeoFile = "geo.csv",
           ModelParamFile = "model_parameters.json",
           LoadDatastore = FALSE,
           SaveDatastore = TRUE,
           DoRun = TRUE) {

    PkgModuleName <- unlist(strsplit(ModuleName, "::"))
    if (length(PkgModuleName)==2) {
      PackageName <- PkgModuleName[1]
      ModuleName <- PkgModuleName[2]
      library(PackageName, character.only=TRUE)
      on.exit(detach(paste0("package:", PackageName), unload=TRUE, character.only=TRUE))
    } else {
      PackageName <- NULL

    }

    if ((!is.null(ProjectDir)) && file.exists(ProjectDir)) {
      ParamDir <- file.path(ProjectDir, ParamDir)
      InputsDir <- file.path(ProjectDir, "inputs")
    } else {
      #Set working directory to tests and return to main module directory on exit
      #--------------------------------------------------------------------------
      setwd("tests")
      on.exit(setwd("../"))

      InputsDir  <- "inputs"
    }

    #Initialize model state and log files
    #------------------------------------
    Msg <- paste0("Testing ", ModuleName, ".")
    initModelStateFile(Dir = ParamDir, ParamFile = RunParamFile)
    initLog(ModuleName)
    writeLog(Msg, Print = TRUE)
    rm(Msg)

    #Load datastore if specified or initialize new datastore
    #-------------------------------------------------------
    if (LoadDatastore) {
      writeLog("Attempting to load datastore.", Print = TRUE)
      DatastoreName <- getModelState()[["DatastoreName"]]
      # Datastore file is assumed to be in ProjectDir if ProjectDir is not NULL
      if ((!is.null(ProjectDir)) && file.exists(ProjectDir)) {
        DatastoreName <- file.path(ProjectDir, DatastoreName)
      }
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
        Dir = ParamDir,
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
      if (is.null(PackageName)) {
        SpecsFileName <- file.path("../data", paste0(SpecsName, ".rda"))
        load(SpecsFileName)
      } else {
        data(list=SpecsName, package=PackageName, 
             envir=environment())
      }
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
    if(!is.null(Specs_ls$Inp)) {

      writeLog("Attempting to process, check and load module inputs.",
               Print = TRUE)
      ProcessedInputs_ls <- processModuleInputs(Specs_ls, ModuleName, Dir=InputsDir)
      if (length(ProcessedInputs_ls$Errors) != 0)  {
        writeLog(ProcessedInputs_ls$Errors)
        stop("Input files have errors. Check the log for details.")
      }
      inputsToDatastore(ProcessedInputs_ls, Specs_ls, ModuleName)
      writeLog("Module inputs successfully checked and loaded into datastore.",
               Print = TRUE)
    } else {
      writeLog("No inputs to process.", Print = TRUE)
    }

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
    #The module is run only if the DoRun argument is TRUE. Otherwise the
    #datastore is initialized, specifications are checked, and inputs are
    #loaded only.
    if (DoRun) {
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
          L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = NULL)
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
            L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = Geo)
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
    } else {
      return(Specs_ls)
    }
  }


#BINARY SEARCH FUNCTION
#======================
#' Binary search function to find a parameter which achieves a target value.
#'
#' \code{binarySearch} uses a binary search algorithm to find the value of a
#' function parameter for which the function achieves a target value.
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
        Chg <- diff(tail(Mid_, 4)) / tail(Mid_, 3)
        if (all(Chg < Tolerance)) break()
      }
    }
    #Return the weighted average of the midpoint value
    tail(WtMid_, 1)
  }


#MAKE A MODEL FORMULA STRING
#===========================
#' Makes a string representation of a model equation.
#'
#' \code{makeModelFormulaString} creates a string equivalent of a model equation.
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
#' \code{applyBinomialModel} applies an estimated binomial model to a set of
#' input data.
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
#' @param Data_df a data frame containing the data required for applying the
#' model.
#' @param TargetProp a number identifying a target proportion for the default
#' choice to be achieved for the input data or NULL if there is no target
#' proportion to be achieved.
#' @param CheckTargetSearchRange a logical identifying whether the function
#' is to only check whether the specified 'SearchRange' for the model will
#' produce acceptable values (i.e. no NA or NaN values). If FALSE (the default),
#' the function will run the model and will not check the target search range.
#' @return a vector of choice values for each record of the input data frame if
#' the model is being run, or if the function is run to only check the target
#' search range, a two-element vector identifying if the search range produces
#' NA or NaN values.
#' @export
applyBinomialModel <-
  function(Model_ls,
           Data_df,
           TargetProp = NULL,
           CheckTargetSearchRange = FALSE) {
    #Check that model is 'binomial' type
    if (Model_ls$Type != "binomial") {
      Msg <- paste0("Wrong model type. ",
                    "Model is identified as Type = ", Model_ls$Type, ". ",
                    "Function only works with 'binomial' type models.")
      stop(Msg)
    }
    #Prepare data
    if (!is.null(Model_ls$PrepFun)) {
      Data_df <- Model_ls$PrepFun(Data_df)
    }
    #Define function to calculate probabilities
    calcProbs <- function(x) {
      Results_ <- x + eval(parse(text = Model_ls$Formula), envir = Data_df)
      Odds_ <- exp(Results_)
      Odds_ / (1 + Odds_)
    }
    #Define function to calculate factor to match target proportion
    checkProportionMatch <- function(TestValue) {
      Probs_ <- calcProbs(TestValue)
      sum(Probs_) / length(Probs_)
    }
    #Define a function to assign results
    assignResults <- function(Probs_) {
      N <- length(Probs_)
      Result_ <- rep(Model_ls$Choices[2], N)
      Result_[runif(N) <= Probs_] <- Model_ls$Choices[1]
      Result_
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
#' \code{applyLinearModel} applies an estimated linear model to a set of input
#' data.
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
>>>>>>> eb5982bd341616f8b43b4561b234e7c29065a625
