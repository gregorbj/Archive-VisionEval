#============
#validation.R
#============

#This script defines functions that are used to perform validate data prior to
#reading or writing to the datastore. The functions check whether the datastore
#contains the group/table/dataset requested and whether the data match
#specifications. Unlike the functions defined in the "hdf5.R" script, these
#functions don't directly interact with the datastore. Instead, they rely on the
#datastore listing (Datastore) that is maintained in the model state file.


#CHECK YEAR GROUP EXISTENCE
#==========================
#' Check year group existence
#'
#' \code{checkYear} checks whether datastore has group for specified year
#'
#' This function checks whether the datastore has a group for the argument year.
#' It also converts the year into a character type and returns the value.
#'
#' @param Year A string or numeric representation of the year to check.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @return A string representation of the input year.
#' @export
checkYear <- function(Year, DstoreListing_df) {
  Year <- as.character(Year)
  if (!(Year %in% DstoreListing_df$groupname)) {
    Message <- paste("Group", Year, "has not been created in the datastore.")
    writeLog(Message)
    stop(Message)
  }
  Year
}


#CHECK TABLE EXISTENCE
#=====================
#' Check table existence
#'
#' \code{checkTable} checks whether datastore contains a specified table
#'
#' This function checks whether the datastore has a group for the specified
#' table and year. If so, it returns the full path name to the table.
#'
#' @param Table a string representation of the table name.
#' @param Year a string or numeric representation of the year.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @param ThrowError a logical identifying whether function execution should be
#' stopped if an error is found. The default value is TRUE.
#' @return A string representation of the full path name for the table in the
#' datastore.
#' @export
checkTable <- function(Table, Year, DstoreListing_df, ThrowError = TRUE) {
  Year <- checkYear(Year, DstoreListing_df)
  Table <- as.character(Table)
  TableName <- file.path(Year, Table)
  TableExists <- TableName %in% DstoreListing_df$groupname
  if (!TableExists) {
    Message <- paste("Group", TableName, "has not been created in the datastore.")
    writeLog(Message)
    if (ThrowError) {
      stop(Message)
    } else {
      return(list(FALSE, TableName))
    }
  } else {
    return(list(TRUE, TableName))
  }
}


#CHECK DATASET EXISTENCE
#=======================
#' Check dataset existence
#'
#' \code{checkDataset} checks whether a dataset exists and if so returns the
#' full path name.
#'
#' This function checks whether a dataset exists. The dataset is identified by
#' its name and the table and year names it is in. If the dataset is not in the
#' datastore, an error is thrown. If it is located in the datastore, the full
#' path name to the dataset is returned.
#'
#' @param Name a string identifying the dataset name.
#' @param Table a string identifying the table the dataset is a part of.
#' @param Year a string or numeric representation of the year.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @param ThrowError a logical value that determines whether an error should be
#'   thrown or whether the results of the check should just be returned to the
#'   calling function.
#' @return A string identifying the full path name for the dataset in the
#'   datastore.
#' @export
checkDataset <- function(Name, Table, Year, DstoreListing_df, ThrowError = TRUE) {
  Name <- as.character(Name)
  Table <- as.character(Table)
  Year <- as.character(Year)
  TableName <- checkTable(Table, Year, DstoreListing_df)[[2]]
  DatasetName <- file.path(TableName, Name)
  DatasetExists <- DatasetName %in% DstoreListing_df$groupname
  if (!DatasetExists) {
    Message <-
      paste("Dataset", DatasetName, "has not been initialized in the datastore.")
    writeLog(Message)
    if (ThrowError) {
      stop(Message)
    } else {
      return(list(FALSE, DatasetName))
    }
  } else {
    return(list(TRUE, DatasetName))
  }
}


#GET ATTRIBUTES OF A DATASET
#===========================
#' Get attributes of a dataset
#'
#' \code{getDatasetAttr} retrieves the attributes for a dataset in the datastore
#'
#' This function extracts the listed attributes for a specific dataset from the
#' datastore listing.
#'
#' @param Name a string identifying the dataset name.
#' @param Table a string identifying the table the dataset is a part of.
#' @param Year a string or numeric representation of the year.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @return A named list of the dataset attributes.
#' @export
getDatasetAttr <- function(Name, Table, Year, DstoreListing_df) {
  DatasetName <- checkDataset(Name, Table, Year, DstoreListing_df)[[2]]
  DatasetIdx <- which(DstoreListing_df$groupname == DatasetName)
  DstoreListing_df$attributes[[DatasetIdx]]
}


#CHECK SPECIFICATION CONSISTENCY
#===============================
#' Check specification consistency
#'
#' \code{checkSpecConsistency} checks whether the specifications for a dataset
#' are consistent with the data attributes in the datastore
#'
#' This function compares the specifications for a dataset identified in a
#' module "Get" or "Set" are consistent with the attributes for that data in the
#' datastore.
#'
#' @param Spec_ls a list of data specifications consistent with a module "Get"
#'   or "Set" specifications.
#' @param DstoreAttr_ a named list where the components are the attributes of a
#'   dataset.
#' @return A list containing two components, Errors and Warnings. If no
#'   inconsistencies are found, both components will have zero-length character
#'   vectors. If there are one or more inconsistencies, then these components
#'   will hold vectors of error and warning messages. Mismatch between UNITS
#'   will produce a warning message. All other inconsistencies will produce
#'   error messages.
#' @export
checkSpecConsistency <- function(Spec_ls, DstoreAttr_) {
  Errors_ <- character(0)
  Warnings_ <- character(0)
  if (Spec_ls$TYPE != DstoreAttr_$TYPE) {
    Message <- paste0(
      "TYPE mismatch for ", Spec_ls$NAME, ". ",
      "Module ", Spec_ls$MODULE, " asks for TYPE = (", Spec_ls$TYPE, "). ",
      "Datastore contains TYPE = (", DstoreAttr_$TYPE, ")."
    )
    Errors_ <- c(Errors_, Message)
  }
  if (Spec_ls$UNITS != DstoreAttr_$UNITS) {
    Message <- paste0(
      "UNITS mismatch for ", Spec_ls$NAME, ". ",
      "Module ", Spec_ls$MODULE, "asks for UNITS = (", Spec_ls$UNITS, "). ",
      "Datastore contains UNITS = (", DstoreAttr_$UNITS, ")."
    )
    Warnings_ <- c(Warnings_, Message)
  }
  if (!all(Spec_ls$PROHIBIT %in% DstoreAttr_$PROHIBIT) |
      !all(DstoreAttr_$PROHIBIT %in% Spec_ls$PROHIBIT)) {
    SpecProhibit <- paste(Spec_ls$PROHIBIT, collapse = ", ")
    DstoreProhibit <- paste(DstoreAttr_$PROHIBIT, collapse = ", ")
    Message <- paste0(
      "PROHIBIT mismatch for ", Spec_ls$NAME, ". ",
      "Module ", Spec_ls$MODULE, " specifies PROHIBIT as (", SpecProhibit, "). ",
      "Datastore specifies PROHIBIT as (", DstoreProhibit, ")."
    )
    Errors_ <- c(Errors_, Message)
  }
  if (!all(Spec_ls$ISELEMENTOF %in% DstoreAttr_$ISELEMENTOF) |
      !all(DstoreAttr_$ISELEMENTOF %in% Spec_ls$ISELEMENTOF)) {
    SpecElements <- paste(Spec_ls$ISELEMENTOF, collapse = ", ")
    DstoreElements <- paste(DstoreAttr_$ISELEMENTOF, collapse = ", ")
    Message <- paste0(
      "ISELEMENTOF mismatch for ", Spec_ls$NAME, ". ",
      "Module ", Spec_ls$MODULE, " specifies ISELEMENTOF as (", SpecElements, "). ",
      "Datastore specifies ISELEMENTOF as (", DstoreElements, ")."
    )
    Errors_ <- c(Errors_, Message)
  }
  list(Errors = Errors_, Warnings = Warnings_)
}


#CHECK DATA TYPE
#===============
#' Check data type
#'
#' \code{checkMatchType} checks whether the data type of a data vector is
#' consistent with specifications.
#'
#' This function checks whether the data type of a data vector is consistent
#' with a specified data type. An error message is generated if data can't be
#' coerced into the specified data type without the possibility of error or loss
#' of information (e.g. if a double is coerced to an integer). A warning message
#' is generated if the specified type is 'character' but the input data type is
#' 'integer', 'double' or 'logical' since these can be coerced correctly, but
#' that may not be what is intended (e.g. zone names may be input as numbers).
#'
#' @param Data_ A data vector.
#' @param Type A string identifying the specified data type.
#' @param DataName A string identifying the field name of the data being
#'   compared (used for composing message identifying non-compliant fields).
#' @return A list having 2 components, Errors and Warnings. If no error or
#'   warning is identified, both components will contain a zero-length character
#'   string. If either an error or warning is identified, the relevant component
#'   will contain a character string that identifies the data field and the type
#'   mismatch.
#' @export
checkMatchType <- function(Data_, Type, DataName) {
  DataType <- typeof(Data_)
  Types <- paste0(Type, DataType)
  makeMessage <- function() {
    paste0("Type of data in field '", DataName, "' is ", DataType,
           " but is specified as ", Type)
  }
  makeError <- function() {
    list(Error = makeMessage(),
         Warning = character(0))
  }
  makeWarning <- function() {
    list(Error = character(0),
         Warning = makeMessage())
  }
  makeOk <- function() {
    list(Error = character(0),
         Warning = character(0))
  }
  switch(
    Types,
    integerdouble = makeError(),
    integercharacter = makeError(),
    integerlogical = makeError(),
    doublecharacter = makeError(),
    doublelogical = makeError(),
    characterinteger = makeWarning(),
    characterdouble = makeWarning(),
    characterlogical = makeWarning(),
    logicalinteger = makeError(),
    logicaldouble = makeError(),
    logicalcharacter = makeError(),
    makeOk()
  )
}


#CHECK VALUES WITH CONDITIONS
#============================
#' Check values with conditions.
#'
#' \code{checkMatchConditions} checks whether a data vector contains any
#' elements that match a set of conditions.
#'
#' This function checks whether any of the values in a data vector match one or
#' more conditions. The conditions are specified in a character vector where
#' each element is either "NA" (to match for the existence of NA values) or a
#' character representation of a valid R comparison expression for comparing
#' each element with a specified value (e.g. "< 0", "> 1", "!= 10"). This
#' function is used both for checking for the presence of prohibited values and
#' for the presence of unlikely values.
#'
#' @param Data_ A vector of data of type integer, double, character, or logical.
#' @param Conditions_ A character vector of valid R comparison expressions or an
#'   empty vector if there are no conditions.
#' @param DataName A string identifying the field name of the data being
#'   compared (used for composing message identifying non-compliant fields).
#' @param ConditionType A string having a value of either "PROHIBIT" or
#' "UNLIKELY", the two data specifications which use conditions.
#' @return A character vector of messages which identify the data field and the
#'   condition that is not met. A zero-length vector is returned if none of the
#'   conditions are met.
#' @export
checkMatchConditions <- function(Data_, Conditions_, DataName, ConditionType) {
  if (length(Conditions_) == 1) {
    if (Conditions_ == "") {
      return(character(0))
    }
  }
  makeMessage <- function(Cond) {
    paste0("Data in data name '", DataName,
           "' includes values matching ", ConditionType, " condition (",
           Cond, ").")
  }
  Results_ <- character(0)
  DataChecks_ <- list()
  for (i in 1:length(Conditions_)) {
    DataChecks_[[i]] <- any(sapply(Data_, function(x) {
      Cond <- Conditions_[i]
      if (Cond  == "NA") {
        is.na(x)
      } else {
        eval(parse(text = paste(x, Cond)))
      }
    }), na.rm = TRUE)
  }
  TrueConditions_ <- Conditions_[unlist(DataChecks_)]
  for (Condition in TrueConditions_) {
    Results_ <- c(Results_, makeMessage(Condition))
  }
  Results_
}


#CHECK IF VALUES IN SET
#======================
#' Check if values in set
#'
#' \code{checkIsElementOf} checks whether a data vector contains any elements
#' that are not in an allowed set of values.
#'
#' This function is used to check whether categorical data values are consistent
#' with the defined set of allowed values.
#'
#' @param Data_ A vector of data of type integer, double, character, or logical.
#' @param SetElements_ A vector of allowed values.
#' @param DataName A string identifying the field name of the data being
#'   compared (used for composing message identifying non-compliant fields).
#' @return A character vector of messages which identify the data field and the
#'   condition that is not met. A zero-length vector is returned if none of the
#'   conditions are met.
#' @export
checkIsElementOf <- function(Data_, SetElements_, DataName){
  if (length(SetElements_) == 1) {
    if (SetElements_ == "") {
      return(character(0))
    }
  }
  makeMessage <- function(El) {
    paste0("Data in data name '", DataName,
           "' includes value (", El, ") not in allowed set."
    )
  }
  Results_ <- character(0)
  DataChecks_ <- list()
  IsElement_ <- is.element(Data_, SetElements_)
  ProhibitedElements_ <- unique(Data_[!IsElement_])
  for (Element in ProhibitedElements_) {
    Results_ <- c(Results_, makeMessage(Element))
  }
  Results_
}


#CHECK DATA CONSISTENCY WITH SPECIFICATION
#=========================================
#' Check data consistency with specification
#'
#' \code{checkDataConsistency} checks whether data to be written to a dataset is
#' consistent with the dataset attributes.
#'
#' This function compares characteristics of data to be written to a dataset to
#' the dataset attributes to determine whether they are consistent.
#'
#' @param DatasetName A string identifying the dataset that is being checked.
#' @param Data_ A vector of values that may be of type integer, double,
#'   character, or logical.
#' @param DstoreAttr_ A named list where the components are the attributes of a
#'   dataset.
#' @return A list containing two components, Errors and Warnings. If no
#'   inconsistencies are found, both components will have zero-length character
#'   vectors. If there are one or more inconsistencies, then these components
#'   will hold vectors of error and warning messages. Mismatch between UNITS
#'   will produce a warning message. All other inconsistencies will produce
#'   error messages.
#' @export
checkDataConsistency <- function(DatasetName, Data_, DstoreAttr_) {
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Check data TYPE
  TypeCheckResult_ <- checkMatchType(Data_, DstoreAttr_$TYPE, DatasetName)
  if (length(TypeCheckResult_$Error) != 0) {
    Message <-
      paste0("The storage mode of the data (", typeof(Data_),
             ") does not match the storage mode of datastore (",
             DstoreAttr_["TYPE"], ") for dataset ", DatasetName)
    Errors_ <- c(Errors_, Message)
  }
  if (length(TypeCheckResult_$Warning) != 0) {
    Message <-
      paste0("The storage mode of the data (", typeof(Data_),
             ") does not match the storage mode of datastore (",
             DstoreAttr_["TYPE"], ") for dataset ", DatasetName)
  }
  #Check if character and SIZE is adequate
  if (typeof(Data_) == "character") {
    MaxSize <- max(nchar(Data_))
    if (MaxSize > DstoreAttr_$SIZE) {
      Message <-
        paste0("Attempting to write character data of length (",
              MaxSize, ") which is longer than specified in datastore (",
              DstoreAttr_["SIZE"], ") for dataset ", DatasetName)
      Errors_ <- c(Errors_, Message)
    }
  }
  #Check if any values in PROHIBIT
  if (DstoreAttr_$PROHIBIT[1] != "") {
    Message <- checkMatchConditions(
      Data_, DstoreAttr_$PROHIBIT, DatasetName, "PROHIBIT")
    Errors_ <- c(Errors_, Message)
  }
  #Check if all values in ISELEMENTOF
  if (DstoreAttr_$ISELEMENTOF[1] != "") {
    Message <- checkIsElementOf(
      Data_, DstoreAttr_$ISELEMENTOF, DatasetName)
    Errors_ <- c(Errors_, Message)
  }
  #Check if any values in UNLIKELY
  if (!is.null(DstoreAttr_$UNLIKELY)) {
    if (DstoreAttr_$UNLIKELY != "") {
      Message <- checkMatchConditions(
        Data_, DstoreAttr_$UNLIKELY, DatasetName, "UNLIKELY")
      Warnings_ <- c(Warnings_, Message)
    }
  }
  #Check whether the sum of values equals the value specified in TOTAL
  if (!is.null(DstoreAttr_$TOTAL)) {
    if (DstoreAttr_$TOTAL != "") {
      if (sum(Data_) != DstoreAttr_$TOTAL) {
        Message <- paste("Sum of", DatasetName,
                         "does not match specified total.")
        Errors_ <- c(Errors_, Message)
      }
    }
  }
  #Return list of errors and warnings
  list(Errors = Errors_, Warnings = Warnings_)
}


