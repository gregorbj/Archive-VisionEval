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


#TEST MODULE
#===========
#' Test module
#'
#' \code{testModule} runs a module and checks whether the outputs match
#' specifications.
#'
#' This function is used to run a module and then check whether the outputs
#' include all of the outputs that are specified, whether the outputs meet all
#' of the specifications, and if the outputs are character strings, whether
#' there is a specification for the SIZE parameter.
#'
#' @param ModuleName A string representation of the module name.
#' @param L A named list containing all of the inputs required to run the
#' module.
#' @param Specs_ls A named list containing the module 'Set' specifications.
#' @return A list containing the following components:
#' Errors: A vector containing error messages having length 0 if there are no
#' errors.
#' Warnings: A vector containing warning messages having length 0 if there are
#' no warnings.
#' Results: A list containing the return values from the module being tested.
#' @export
testModule <- function(ModuleName, L, Specs_ls) {
  #Load the specifications
  DataNames <- unlist(lapply(Specs_ls, function(x) x$NAME))
  names(Specs_ls) <- DataNames
  #Run the module
  Results_ls <- eval(parse(text = paste0(ModuleName, "(L)")))
  #Initialize data structures to save errors and warnings
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Check whether results meet specifications
  for (dname in DataNames) {
    if (dname %in% names(Results_ls)) {
      Spec_ls <- Specs_ls[[dname]]
      if (is.null(Spec_ls$SIZE)) {
        if (is.na(Results_ls$SIZE[dname])) {
          Message <- paste(dname, "is missing SIZE parameter.")
          Errors_[dname] <- Message
          next
        } else {
          Spec_ls$SIZE <- Results_ls$SIZE[dname]
          Checks_ls <-
            checkDataConsistency(dname, Results_ls[[dname]], Spec_ls)
          Errors_[dname] <- Checks_ls$Errors
          Warnings_[dname] <- Checks_ls$Warnings
        }
      }
    } else {
      Message <- paste("Module did not produce", dname)
    }
  }
  #Return list of errors, warnings, and module results
  list(Name = ModuleName, Errors = Errors_, Warnings = Warnings_,
       Results = Results_ls)
}


#RETURN MODULE ERRORS
#====================
#' Return module errors
#'
#' \code{hasErrors} checks whether the return value from the testModule function
#' contains any error messages and returns a message stating them.
#'
#' This function checks whether the results from testing a module contain any
#' errors. The function stops script execution if there are any errors and the
#' message contains a list of the errors.
#'
#' @param ModuleCheck_ls A list that is returned from the "testModule" function.
#' @return None. The function stops script execution if there are any errors and
#' the message contains a list of the errors.
#' @export
hasErrors <- function(ModuleCheck_ls) {
  Errors_ <- ModuleCheck_ls$Errors
  if (length(Errors_) != 0) {
    Message <- paste(
      paste("Module", ModuleCheck_ls$Name, "produced the following errors:"),
      paste(Errors_, collapse = "\n"),
      sep = "\n"
    )
    stop(Message)
  } else {
    Message <- paste("Outputs from module", ModuleCheck_ls$Name,
                     "meet all output specifications.")
  }
  Message
}
