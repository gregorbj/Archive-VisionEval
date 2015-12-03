#=====================
#datastore_utilities.R
#=====================

#This script defines utility functions to assist interactions with the
#datastore. However, unlike the functions defined in the "hdf5_utilities.R"
#script, these functions don't directly interact with the datastore. Instead,
#the functions mostly use the datastore listing (E$Datastore) as the basis for
#checking whether data can be written to a table or dataset. When reading from
#or writing to the datastore is required, the functions call hdf5 utility
#functions.


#DEFINE FUNCTION TO CHECK WHETHER DATASTORE CONTAINS A GROUP FOR A SPECIFIED YEAR
#================================================================================
#' Check if datastore has year group
#'
#' \code{checkYear} checks whether datastore has group for specified year
#'
#' This function checks whether the datastore has a group for the argument year.
#' It also converts the year into a character type and returns the value.
#'
#' @param Year the year to check. Can be a 4 digit string or numeric
#'   representation of the year.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in E$datastore.
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


#DEFINE FUNCTION TO CHECK WHETHER DATASTORE CONTAINS A TABLE
#===========================================================
#' Check if datastore has year group
#'
#' \code{checkTable} checks whether datastore contains a specifies table
#'
#' This function checks whether the datastore has a group for the specified
#' table and year. If so, it returns the full path name to the table.
#'
#' @param Table a string representation of the table name.
#' @param Year the year to check. Can be a 4 digit string or numeric
#'   representation of the year.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in E$datastore.
#' @return A string representation of the full path name for the table.
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


#DEFINE FUNCTION TO CHECK WHETHER DATASTORE CONTAINS A SPECIFIED DATASET
#=======================================================================
#' Check if dataset exists and return full path name
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
#' @param Year a string identifying the year group that the table is in.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in E$datastore.
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


#DEFINE FUNCTION TO READ THE ATTRIBUTES OF A DATASET
#===================================================
#' Get the attributes for a dataset
#'
#' \code{getDatasetAttr} retrieves the attributes for a dataset in the datastore
#'
#' This function reads the listed attributes for a dataset in the datastore
#'
#' @param Name a string identifying the dataset name.
#' @param Table a string identifying the table the dataset is a part of.
#' @param Year a string identifying the year group that the table is in.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in E$datastore.
#' @return A named list of the dataset attributes.
#' @export
getDatasetAttr <- function(Name, Table, Year, DstoreListing_df) {
  DatasetName <- checkDataset(Name, Table, Year, DstoreListing_df)[[2]]
  DatasetIdx <- which(DstoreListing_df$groupname == DatasetName)
  DstoreListing_df$attributes[[DatasetIdx]]
}


#DEFINE FUNCTION TO CHECK DATASET SPECIFICATION CONSISTENCY WITH DATASTORE
#=========================================================================
#' Check data specifications consistency with datastore
#'
#' \code{checkSpecConsistency} checks whether the specifications for a dataset
#' are consistent with the data attributes in the datastore
#'
#' This function compares the specifications for a dataset identified in a
#' module "Get" or "Set" are consistent with the attributes for that data in the
#' datastore.
#'
#' @param Spec_ls a list of data specifications consistent with a module "Get"
#'   or "Set".
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


#DEFINE A FUNCTION WHICH CHECKS DATA TYPES
#=========================================
#' Compare data type with specification.
#'
#' \code{checkMatchType} checks whether the data type of a data vector is
#' inconsistent with specifications.
#'
#' This function checks whether the data type of a data vector is inconsistent
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
#' @return A list having 2 components, Errors and Warnings. If the no error or
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


#DEFINE A FUNCTION WHICH CHECKS DATA VALUES AGAINST CONDITIONS
#=============================================================
#' Check values against conditions.
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


#DEFINE A FUNCTION TO CHECK WHETHER DATA ARE ELEMENTS OF ALLOWED VALUE SET
#=========================================================================
#' Check values for inclusion in set
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


#DEFINE FUNCTION TO CHECK DATA CONSISTENCY WITH SPECIFICATION
#============================================================
#' Check data consistency with dataset attributes
#'
#' \code{checkDataConsistency} checks whether data to be written to a dataset is
#' consisten with the dataset attributes.
#'
#' This function compares characteristics of data to be written to a dataset to
#' the dataset attributes to determine whether they are consistent.
#'
#' @param Data_ a vector of values that may be of type integer, double,
#'   character, or logical.
#' @param DstoreAttr_ a named list where the components are the attributes of a
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
  list(Errors = Errors_, Warnings = Warnings_)
}


#DEFINE FUNCTION FOR CHECKING GEOGRAPHIC SPECIFICATIONS
#======================================================
#' Check correctness of geographic specifications.
#'
#' \code{checkGeography} checks geographic specifications file for
#' model.
#'
#' This function reads the file containing geographic specifications for the
#' model and checks the file entries to determine whether they are internally
#' consistent.
#'
#' @param Directory A string identifying the path to the geographic
#'   specifications file. Note that don't include the final separator in the
#'   path name 'e.g. not defs/'.
#' @param Filename A string identifying the name of the geographic
#'   specifications file. This is a csv-formatted text file which contains
#'   columns named 'Azone', 'Bzone', 'Czone', and 'Marea'. The 'Azone' column
#'   must have zone names in all rows. The 'Bzone' and 'Czone' columns can be
#'   unspecified (NA in all rows) or may have have unique names in every row.
#'   The 'Marea' column (referring to metropolitan areas) identifies
#'   metropolitan areas corresponding to each Azone or the value 'None' if a
#'   metropolitan area does not occupy any portion of an Azone. The geographic
#'   specifications file must exist in the "defs" directory.
#' @return The value TRUE is returned if the function is successful at reading
#'   the file and the specifications are consistent. It stops if there are any
#'   errors in the specifications. All of the identified errors are written to
#'   the run log.
#'   @export
checkGeography <- function(Directory, Filename) {
  #Read in geographic definitions if file exists, otherwise error
  #--------------------------------------------------------------
  Filepath <- file.path(Directory, Filename)
  if (file.exists(Filepath)) {
    Geo_df <- read.csv(Filepath, colClasses = "character")
  } else {
    Message <- paste("Missing", Filename, "file in folder", Directory, ".")
    writeLog(Message)
    stop(Message)
  }
  #Check that file has all required fields and extract field attributes
  #--------------------------------------------------------------------
  FieldNames_ <- c("Azone", "Bzone", "Czone", "Marea")
  if (!(all(names(Geo_df) %in% FieldNames_))) {
    Message <- "'geography.csv' is missing some required fields."
    writeLog(Message)
    stop(Message)
  }
  #Check table entries
  #-------------------
  BzoneSpecified <- !all(is.na(Geo_df$Bzone))
  E$BzoneSpecified <- BzoneSpecified
  CzoneSpecified <- !all(is.na(Geo_df$Czone))
  E$CzoneSpecified <- CzoneSpecified
  Messages_ <- character(0)
  #Determine whether entries are correct if Bzones have not been specified
  if (!BzoneSpecified) {
    if (any(duplicated(Geo_df$Azone))) {
      DupAzone <- unique(Geo_df$Azone[duplicated(Geo_df$Azone)])
      Messages_ <- c(
        Messages_, paste0(
          "Duplicated Azone entries (",
          paste(DupAzone, collapse = ", "),
          ") not allowed when Bzones not specified."
        )
      )
    }
  }
  #Determine whether entries are correct if Bzones have been specified and
  #Czones are unspecified
  if (BzoneSpecified & !CzoneSpecified) {
    #Are Bzones completely specified
    if (any(is.na(Geo_df$Bzone))) {
      Messages_ <- c(Messages_,
                     "Either all Bzone entries must be NA or no Bzone entries must be NA.")
    }
    #Are any Bzone names duplicated
    if (any(duplicated(Geo_df$Bzone))) {
      DupBzone <- unique(Geo_df$Bzone[duplicated(Geo_df$Bzone)])
      Messages_ <- c(Messages_, paste0(
        "Duplicated Bzone entries (",
        paste(DupBzone, collapse = ", "),
        ") not allowed."
      ))
    }
    #Are metropolitan area designations consistent
    AzoneMareas_ <- tapply(Geo_df$Marea, Geo_df$Azone, unique)
    AzoneMareas_ <- lapply(AzoneMareas_, function(x) {
      x[x != "None"]
    })
    if (any(unlist(lapply(AzoneMareas_, length)) > 1)) {
      Messages_ <- c(Messages_,
                     "At least one Azone is assigned more than one Marea.")
    }
  }
  #Determine whether entries are correct if Czones have been specified
  if (CzoneSpecified) {
    #Are Czones completely specified
    if (any(is.na(Geo_df$Czone))) {
      Messages_ <- c(Messages_,
                     "Either all Czone entries must be NA or no Czone entries must be NA.")
    }
    #Are any Czone names duplicated
    if (any(duplicated(Geo_df$Czone))) {
      DupCzone <- unique(Geo_df$Czone[duplicated(Geo_df$Czone)])
      Messages_ <- c(Messages_, paste0(
        "Duplicated Czone entries (",
        paste(DupCzone, collapse = ", "),
        ") not allowed."
      ))
    }
    #Are metropolitan area designations consistent
    AzoneMareas_ <- tapply(Geo_df$Marea, Geo_df$Azone, unique)
    AzoneMareas_ <- lapply(AzoneMareas_, function(x) {
      x[x != "None"]
    })
    if (any(unlist(lapply(AzoneMareas_, length)) > 1)) {
      Messages_ <- c(Messages_,
                     "At least one Azone is assigned more than one Marea.")
    }
  }
  #Return messages and
  list(Messages = Messages_, Geo = Geo_df)
}


#DEFINE A FUNCTION TO CREATE AN INDEX FOR READING AND WRITING TO DATASTORE
#=========================================================================
#' Create datastore index.
#'
#' \code{createIndex} creates an index for reading or writing module data to the
#' datastore.
#'
#' This function creates indexing functions which return an index to positions
#' in datasets that correspond to positions in an index field of a table. For
#' example if the index field is 'Azone' in the 'Household' table, this function
#' will return a function that when provided the name of a particular Azone,
#' will return the positions corresponding to that Azone.
#'
#' @param Year A string identifying the year group the table is located in.
#' @param TableName A string identifying the name of the table the index is
#'   being created for.
#' @param IndexField A string identifying the field the index is being created
#'   for.
#' @return A function that creates a vector of positions corresponding to the
#'   location of the supplied value in the index field.
#' @export
createIndex <- function(Name, Table, Year) {
  ValsToIndexBy <-
    readFromTable(Name, Table, Year)
  return(function(IndexVal) {
    which(ValsToIndexBy == IndexVal)
  })
}


#DEFINE A FUNCTION TO PROCESS MODULE INPUTS
#==========================================
#' Check and write module inputs to datastore.
#'
#' \code{processModuleInputs} checks whether specified module inputs meet
#' specifications and load into datastore if OnlyCheck argument is false.
#'
#' This function checks whether all the specified scenario inputs meet
#' specifications. Checks include whether the specified files exist, whether the
#' files include data for all years and specified zones, and whether every data
#' item meets specifications. Data specifications.
#'
#' @param Inp_ls A list which meets standards for specifying input
#'   characteristics.
#' @param ModuleName A string identifying the module name.
#' @param Dir A string identifying the relative path name to the directory where
#'   input files are located.
#' @param OnlyCheck A logical value. If TRUE, the function will only check the
#'   inputs. If FALSE, the function will check the inputs and load the input
#'   data into the datastore.
#' @param Ignore_ A vector of the names of data items that will not be checked
#'   or loaded. If NULL, all data items will be checked and loaded.
#' @return A numeric vector having 3 elements (FileErrors, DataErrors,
#'   DataWarnings). Each element identifies how may data errors or warnings were
#'   found.
#' @export
processModuleInputs <-
  function(Inp_ls, ModuleName, Dir = "inputs", OnlyCheck = TRUE, Ignore_ = NULL) {
    FileName <- ""
    FileErr_ <- character(0)
    for (i in 1:length(Inp_ls)) {
      Spec_ls <- Inp_ls[[i]]
      Spec_ls$MODULE <- ModuleName
      DataErr_ls <-
        list(Errors = character(0), Warnings = character(0))
      #Check for file errors only if not already done
      if (Spec_ls$FILE != FileName) {
        FileName <- Spec_ls$FILE
        #Check that input file exists
        if (!file.exists(file.path(Dir, FileName))) {
          Message <- paste(
            "Input file error.", "File", FileName, "required by",
            ModuleName, "is not present in the 'inputs' directory."
          )
          writeLog(Message)
          FileErr_ <- c(FileErr_, Message)
          next()
        }
        #Load data and check that Geo and Year components are correct
        Data_df <- read.csv(file.path(Dir, FileName), as.is = TRUE)
        GeoYrSpec_df <- do.call(rbind, lapply(E$Years, function(x) {
          Geo_ <- readFromTable(Spec_ls$TABLE, Spec_ls$TABLE, x, Index = NULL)
          data.frame(
            Geo = Geo_,
            Year = rep(as.integer(x), length(Geo_)),
            stringsAsFactors = FALSE
          )
        }))
        GeoYrSpec_df <-
          GeoYrSpec_df[order(GeoYrSpec_df$Year, GeoYrSpec_df$Geo),]
        GeoYrData_df <-
          Data_df[order(Data_df$Year, Data_df$Geo), c("Geo", "Year")]
        if (!all.equal(GeoYrSpec_df, GeoYrData_df)) {
          Message <- paste(
            "Input file error. Error in the 'Geo' and 'Year' fields of the file",
            FileName, "that", ModuleName, "requires."
          )
          writeLog(Message)
          FileErr_ <- c(FileErr_, Message)
          next()
        }
      }
      #Check dataset
      DatasetName <- Spec_ls$NAME
      if (!DatasetName %in% Ignore_) {
        Data_ <- Data_df[[DatasetName]]
        DataCheck_ls <-
          checkDataConsistency(DatasetName, Data_, Spec_ls)
        if (length(DataCheck_ls$Errors) != 0) {
          writeLog(DataCheck_ls$Errors)
          DataErr_ls$Errors <-
            c(DataErr_ls$Errors, DataCheck_ls$Errors)
        }
        if (length(DataCheck_ls$Warnings) != 0) {
          writeLog(DataCheck_ls$Warnings)
          DataErr_ls$Warnings <-
            c(DataErr_ls$Warnings, DataCheck_ls$Warnings)
        }
      }
      #If no errors and OnlyCheck is FALSE, then load the data into the datastore
      if ((length(FileErr_) == 0) &
          (length(DataErr_ls$Errors) == 0) & (OnlyCheck == FALSE)) {
        for (Year in E$Years) {
          DstoreGeo_ <- readFromTable(Spec_ls$TABLE, Spec_ls$TABLE, Year)
          YearData_df <- Data_df[Data_df$Year == Year,]
          DtoWrite_ <-
            YearData_df[[DatasetName]][match(DstoreGeo_, Data_df$Geo)]
          writeToTable(DtoWrite_, Spec_ls, Year, Index = NULL)
        }
      }
    }
    Result_ <- c(
      FileErrors = 0, DataErrors = 0, DataWarnings = 0
    )
    if (length(DataErr_ls$Errors) != 0)
      Result_["DataErrors"] <- length(DataErr_ls$Errors)
    if (length(DataErr_ls$Warnings) != 0)
      Result_["DataWarnings"] <- length(DataErr_ls$Warnings)
    if (length(FileErr_) != 0)
      Result_["FileErrors"] <- length(FileErr_)
    Result_
  }


