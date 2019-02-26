#============
#validation.R
#============

#This script defines functions that are used to validate data prior to
#reading or writing to the datastore. The functions check whether the datastore
#contains the group/table/dataset requested and whether the data match
#specifications. Unlike the functions defined in the "hdf5.R" script, these
#functions don't directly interact with the datastore. Instead, they rely on the
#datastore listing (Datastore) that is maintained in the model state file.


#CHECK DATASET EXISTENCE
#=======================
#' Check dataset existence
#'
#' \code{checkDataset} a visioneval framework control function that checks
#' whether a dataset exists in the datastore and returns a TRUE or FALSE value
#' with an attribute of the full path to where the dataset should be located in
#' the datastore.
#'
#' This function checks whether a dataset exists. The dataset is identified by
#' its name and the table and group names it is in. If the dataset is not in the
#' datastore, an error is thrown. If it is located in the datastore, the full
#' path name to the dataset is returned.
#'
#' @param Name a string identifying the dataset name.
#' @param Table a string identifying the table the dataset is a part of.
#' @param Group a string or numeric representation of the group the table is a
#' part of.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @return A logical identifying whether the dataset is in the datastore. It has
#' an attribute that is a string of the full path to where the dataset should be
#' in the datastore.
#' @export
checkDataset <- function(Name, Table, Group, DstoreListing_df) {
  Name <- as.character(Name)
  Table <- as.character(Table)
  Group <- as.character(Group)
  #TableName <- checkTable(Table, Group, DstoreListing_df)[[2]]
  DatasetName <- file.path(Group, Table, Name)
  DatasetExists <- DatasetName %in% DstoreListing_df$groupname
  Result <- ifelse (DatasetExists, TRUE, FALSE)
  attributes(Result) <- list(DatasetName = DatasetName)
  Result
}


#GET ATTRIBUTES OF A DATASET
#===========================
#' Get attributes of a dataset
#'
#' \code{getDatasetAttr} a visioneval framework control function that retrieves
#' the attributes for a dataset in the datastore.
#'
#' This function extracts the listed attributes for a specific dataset from the
#' datastore listing.
#'
#' @param Name a string identifying the dataset name.
#' @param Table a string identifying the table the dataset is a part of.
#' @param Group a string or numeric representation of the group the table is a
#' part of.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @return A named list of the dataset attributes.
#' @export
getDatasetAttr <- function(Name, Table, Group, DstoreListing_df) {
  DatasetName <- file.path(Group, Table, Name)
  #checkDataset(Name, Table, Group, DstoreListing_df)[[2]]
  DatasetIdx <- which(DstoreListing_df$groupname == DatasetName)
  DstoreListing_df$attributes[[DatasetIdx]]
}


#CHECK WHETHER TABLE EXISTS
#==========================
#' Check whether table exists in the datastore
#'
#' \code{checkTableExistence} a visioneval framework control function that
#' checks whether a table is present in the datastore.
#'
#' This function checks whether a table is present in the datastore.
#'
#' @param Table a string identifying the table.
#' @param Group a string or numeric representation of the group the table is a
#' part of.
#' @param DstoreListing_df a dataframe which lists the contents of the datastore
#'   as contained in the model state file.
#' @return A logical identifying whether a table is present in the datastore.
#' @export
checkTableExistence <- function(Table, Group, DstoreListing_df) {
  TableName <- file.path(Group, Table)
  TableName %in% DstoreListing_df$groupname
}


#CHECK SPECIFICATION CONSISTENCY
#===============================
#' Check specification consistency
#'
#' \code{checkSpecConsistency} a visioneval framework control function that
#' checks whether the specifications for a dataset are consistent with the data
#' attributes in the datastore.
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
  if (!is.null(Spec_ls$PROHIBIT) & !is.null(DstoreAttr_$PROHIBIT)) {
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
  }
  if (!is.null(Spec_ls$ISELEMENTOF) & !is.null(DstoreAttr_$ISELEMENTOF)) {
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
  }
  list(Errors = Errors_, Warnings = Warnings_)
}


#CHECK DATA TYPE
#===============
#' Check data type
#'
#' \code{checkMatchType} a visioneval framework control function that checks
#' whether the data type of a data vector is consistent with specifications.
#'
#' This function checks whether the data type of a data vector is consistent
#' with a specified data type. An error message is generated if data can't be
#' coerced into the specified data type without the possibility of error or loss
#' of information (e.g. if a double is coerced to an integer). A warning message
#' is generated if the specified type is 'character' but the input data type is
#' 'integer', 'double' or 'logical' since these can be coerced correctly, but
#' that may not be what is intended (e.g. zone names may be input as numbers).
#' Note that some modules may use NA inputs as a flag to identify case when
#' result does not need to match a target. In this case, R will read in the type
#' of data as logical. In this case, the function sets the data type to be the
#' same as the specification for the data type so the function not flag a
#' data type error.
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
  #Because some modules allow NA values as flag instead of target values
  if (all(is.na(Data_))) DataType <- Type
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
#' \code{checkMatchConditions} a visioneval framework control function that
#' checks whether a data vector contains any elements that match a set of
#' conditions.
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
    Cond <- Conditions_[i]
    if (Cond  == "NA") {
      DataChecks_[[i]] <-
        any(is.na(Data_))
    } else {
      TempData_ <- Data_[!is.na(Data_)]
      DataChecks_[[i]] <-
        any(eval(parse(text = paste("TempData_", Cond))))
      rm(TempData_)
    }
  }
  TrueConditions_ <- Conditions_[unlist(DataChecks_)]
  for (Condition in TrueConditions_) {
    Results_ <- c(Results_, makeMessage(Condition))
  }
  Results_
}


#CHECK IF DATA VALUES ARE IN A SPECIFIED SET OF VALUES
#=====================================================
#' Check if data values are in a specified set of values
#'
#' \code{checkIsElementOf} a visioneval framework control function that checks
#' whether a data vector contains any elements that are not in an allowed set of
#' values.
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
#' \code{checkDataConsistency} a visioneval framework control function that
#' checks whether data to be written to a dataset is consistent with the dataset
#' attributes.
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
  if (!is.null(DstoreAttr_$PROHIBIT)) {
    if (DstoreAttr_$PROHIBIT[1] != "") {
      Message <- checkMatchConditions(
        Data_, DstoreAttr_$PROHIBIT, DatasetName, "PROHIBIT")
      Errors_ <- c(Errors_, Message)
    }
  }
  #Check if all values in ISELEMENTOF
  if (!is.null(DstoreAttr_$ISELEMENTOF)) {
    if (DstoreAttr_$ISELEMENTOF[1] != "") {
      Message <- checkIsElementOf(
        Data_, DstoreAttr_$ISELEMENTOF, DatasetName)
      Errors_ <- c(Errors_, Message)
    }
  }
  #Check if any values in UNLIKELY
  if (!is.null(DstoreAttr_$UNLIKELY)) {
    if (DstoreAttr_$UNLIKELY[1] != "") {
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


#PARSE UNITS SPECIFICATION
#=========================
#' Parse units specification into components and add to specifications list.
#'
#' \code{parseUnitsSpec} a visioneval framework control function that parses the
#' UNITS attribute of a standard Inp, Get, or Set specification for a dataset to
#' identify the units name, multiplier, and year for currency data. Returns a
#' modified specifications list whose UNITS value is only the units name, and
#' includes a MULTIPLIER attribute and YEAR attribute.
#'
#' The UNITS component of a specifications list can encode information in
#' addition to the units name. This includes a value units multiplier and in
#' the case of currency values the year for the currency measurement. The
#' multiplier element can only be expressed in scientific notation where the
#' number before the 'e' can only be 1. If the year element for a currency
#' specification is missing, it is replaced by the model base year which is
#' recorded in the model state file. If this is done, a WARN attribute is added
#' to the specifications list notifying the module developer that there is no
#' year element and the model base year will be used when the module is called.
#' The test module function reads this warning and writes it to the module test
#' log. This way the module developer is made aware of the situation so that it
#' may be corrected if necessary. The model user is not bothered by the warning.
#'
#' @param Spec_ls A standard specifications list for a Inp, Get, or Set item.
#' @param ComponentName A string that is the name of the specifications
#' the the specification comes from (e.g. "Inp", "Get", "Set).
#' @return a list that is a standard specifications list with the addition of
#' a MULTIPLIER component and a YEAR component as well as a modification of the
#' UNIT component. The MULTIPLIER component can have the value of NA, a number,
#' or NaN. The value is NA if the multiplier is missing. It is a number if the
#' multiplier is a valid number. The value is NaN if the multiplier is not a
#' valid number. The YEAR component is a character string that is a 4-digit
#' representation of a year or NA if the component is not a proper year. If the
#' year component is missing from the UNITS specification for currency data,
#' the model base year is substituted. In that case, a WARN attribute is added
#' to the returned specifications list. This is read by the testModule function
#' and written to the module test log to notify the module developer. After the
#' UNITS component has been parsed and the YEAR and MULTIPLIER components
#' extracted, the UNITS component is modified to only be the units name.
#' @export
parseUnitsSpec <-
  function(Spec_ls, ComponentName) {
    #Define function to return a multiplier value from a multiplier string
    #NA if none, NaN if not a properly specified scientic notation (e.g. 1e3)
    getMultiplier <- function(String) {
      if (is.na(String)) {
        Result <- NA
      } else {
        SciTest_ <- as.numeric(unlist(strsplit(String, "e")))
        if (length(SciTest_) != 2 |
            any(is.na(SciTest_)) |
            SciTest_[1] != 1) {
          Result <- NaN
        } else {
          Result <- as.numeric(String)
        }
      }
      Result
    }
    #Define function to return a year value from a year string
    #NA if none or not a correct year
    getYear <- function(String) {
      CurrentString <- unlist(strsplit(as.character(Sys.Date()), "-"))[1]
      if (is.na(as.numeric(String)) | is.na(String)) {
        Result <- NA
      } else {
        if (as.numeric(String) < 1900 | as.numeric(String) > CurrentString) {
          Result <- NA
        } else {
          Result <- String
        }
      }
      Result
    }
    #Split the parts of the units specification
    UnitsSplit_ <- unlist(strsplit(Spec_ls$UNITS, "\\."))
    #The units name is the first element
    Spec_ls$UNITS <- UnitsSplit_[1]
    #If currency type, the year is the 2nd element and multiplier is 3rd element
    if (Spec_ls$TYPE == "currency") {
      if (length(UnitsSplit_) == 1 & ComponentName != "Inp") {
        Year <- getModelState()$BaseYear
        Multiplier <- NA
        Msg <- paste0(
          "Warning note to module developer. The ", ComponentName,
          " specification for dataset ", Spec_ls$NAME, " in table ",
          Spec_ls$TABLE, " does not specify a currency year. ",
          "The model user's base year will be assumed when the module is called. ",
          "If this is not the intended behavior, include the intended currency ",
          "year in the UNITS specification as described in the VisionEval ",
          "module developer documentation."
        )
        attributes(Spec_ls)$WARN <- Msg
        rm(Msg)
      } else {
        Year <- UnitsSplit_[2]
        Multiplier <- UnitsSplit_[3]
      }
    } else {
      Year <- NA
      Multiplier <- UnitsSplit_[2]
    }
    #Process the multiplier element
    Spec_ls$MULTIPLIER <- getMultiplier(Multiplier)
    #Process the year element
    Spec_ls$YEAR <- getYear(Year)
    #Return the result
    Spec_ls
  }
#Test module developer warning if year not specified in UNITS spec for
#currency data in Get or Set specifications
# setwd("tests")
# TestSpec_ls <- item(
#   NAME = "RuralIncome",
#   TABLE = "Marea",
#   GROUP = "BaseYear",
#   TYPE = "currency",
#   UNITS = "USD",
#   PROHIBIT = c("NA", "< 0"),
#   ISELEMENTOF = ""
# )
# parseUnitsSpec(TestSpec_ls, "Get")
# setwd("..")

#RECOGNIZED TYPES AND UNITS ATTRIBUTES FOR SPECIFICATIONS
#========================================================
#' Returns a list of returns a list of recognized data types, the units for each
#' type, and storage mode of each type.
#'
#' \code{Types} a visioneval framework control function that returns a list of
#' returns a list of recognized data types, the units for each type, and storage
#' mode of each type.
#'
#' This function stores a listing of the dataset types recognized by the
#' visioneval framework, the units recognized for each type, and the storage
#' mode used for each type. Types include simple types (e.g. integer, double,
#' character, logical) as well as complex types (e.g. distance, time, mass). For
#' the complex types, units are specified as well. For example for the distance
#' type, allowed units are MI (miles), FT (feet), KM (kilometers), M (meters).
#' The listing includes conversion factors between units of each complex type.
#' The listing also contains the storage mode (i.e. integer, double, character,
#' logical of each type. For simple types, the type and the storage mode are the
#' same).
#'
#' @return A list containing a component for each recognized type. Each
#' component lists the recognized units for the type and the storage mode. There
#' are currently 4 simple types and 10 complex type. The simple types are
#' integer, double, character and logical. The complex types are currency,
#' distance, area, mass, volume, time, speed, vehicle_distance,
#' passenger_distance, and payload_distance.
#' @export
Types <- function(){
  list(
    double = list(units = NA, mode = "double"),
    integer = list(units = NA, mode = "integer"),
    character = list(units = NA, mode = "character"),
    logical = list(units = NA, mode = "logical"),
    compound = list(units = NA, mode = "double"),
    currency = list(
      units = list(
        USD = c(USD = 1)
        ),
      mode = "double"),
    distance = list(
      units = list(
        MI = c(MI = 1, FT = 5280, KM = 1.60934, M = 1609.34),
        FT = c(MI = 0.000189394, FT = 1, KM = 0.0003048, M = 0.3048),
        KM = c(MI = 0.621371, FT = 3280.84, KM = 1, M = 1000),
        M = c(MI = 0.000621371, FT = 3.28084, KM = 0.001, M = 1)),
      mode = "double"),
    area = list(
      units = list(
        SQMI = c(SQMI = 1, ACRE = 640, SQFT = 2.788e+7, SQM = 2.59e+6, HA = 258.999, SQKM = 2.58999 ),
        ACRE = c(SQMI = 0.0015625, ACRE = 1, SQFT = 43560, SQM = 4046.86, HA = 0.404686, SQKM = 0.00404686),
        SQFT = c(SQMI = 3.587e-8, ACRE = 2.2957e-5, SQFT = 1, SQM = 0.092903, HA = 9.2903e-6, SQKM = 9.2903e-8),
        SQM = c(SQMI = 3.861e-7, ACRE = 0.000247105, SQFT = 10.7639, SQM = 1, HA = 1e-4, SQKM = 1e-6),
        HA = c(SQMI = 0.00386102, ACRE = 2.47105, SQFT = 107639, SQM = 0.00386102, HA = 1, SQKM = 0.01),
        SQKM = c(SQMI = 0.386102, ACRE = 247.105, SQFT = 1.076e+7, SQM = 1e+6, HA = 100, SQKM = 1)),
      mode = "double"
    ),
    mass = list(
      units = list(
        LB = c(LB = 1, TON = 0.0005, MT = 0.000453592, KG = 0.453592, GM = 453.592),
        TON = c(LB = 2000, TON = 1, MT = 0.907185, KG = 907.185, GM = 907185),
        MT = c(LB = 2204.62, TON = 1.10231, MT = 1, KG = 1000, GM = 1e+6),
        KG = c(LB = 2.20462, TON = 0.00110231, MT = 0.001, KG = 1, GM = 1000),
        GM = c(LB = 0.00220462, TON = 1.1023e-6, MT = 1e-6, KG = 0.001, GM = 1)),
      mode = "double"
    ),
    volume = list(
      units = list(
        GAL = c(GAL = 1, L = 3.78541),
        L = c(GAL = 0.264172, L = 1)),
      mode = "double"
    ),
    time = list(
      units = list(
        YR = c(YR = 1, DAY = 365, HR = 8760, MIN = 525600, SEC = 3.154e+7),
        DAY = c(YR = 0.00273973, DAY = 1, HR = 24, MIN = 1440, SEC = 86400),
        HR = c(YR = 0.000114155, DAY = 0.0416667, HR = 1, MIN = 60, SEC = 3600),
        MIN = c(YR = 1.9026e-6, DAY = 0.000694444, HR = 0.0166667, MIN = 1, SEC = 60),
        SEC = c(YR = 3.171e-8, DAY = 1.1574e-5, HR = 0.000277778, MIN = 0.0166667, SEC = 1)),
      mode = "double"
    ),
    energy = list(
      units = list(
        KWH = c(KWH = 1, MJ = 3.6, GGE = 0.02967846),
        MJ = c(KWH = 0.277778, MJ = 1, GGE = 0.008244023),
        GGE = c(KWH = 33.69447, MJ = 121.3, GGE = 1)
      ),
      mode = "double"
    ),
    people = list(
      units = list(
        PRSN = c(PRSN = 1)
      ),
      mode = "integer"
    ),
    vehicles = list(
      units = list(
        VEH = c(VEH = 1)
      ),
      mode = "integer"
    ),
    trips = list(
      units = list(
        TRIP = c(TRIP = 1)
      ),
      mode = "integer"
    ),
    households = list(
      units = list(
        HH = c(HH = 1)
      ),
      mode = "integer"
    ),
    employment = list(
      units = list(
        JOB = c(JOB = 1)
      ),
      mode = "integer"
    ),
    activity = list(
      units = list(
        HHJOB = c(HHJOB = 1)
      )
    )
  )
}


#CHECK MEASUREMENT UNITS
#=======================
#' Check measurement units for consistency with recognized units for stated type.
#'
#' \code{checkUnits} a visioneval framework control function that checks the
#' specified UNITS for a dataset for consistency with the recognized units for
#' the TYPE specification for the dataset. It also splits compound units into
#' elements.
#'
#' The visioneval code recognizes 4 simple data types (integer, double, logical,
#' and character) and 9 complex data types (e.g. distance, time, mass).
#' The simple data types can have any units of measure, but the complex data
#' types must use units of measure that are declared in the Types() function. In
#' addition, there is a compound data type that can have units that are composed
#' of the units of two or more complex data types. For example, speed is a
#' compound data type composed of distance divided by speed. With this example,
#' speed in miles per hour would be represented as MI/HR. This function checks
#' the UNITS specification for a dataset for consistency with the recognized
#' units for the given data TYPE. To check the units of a compound data type,
#' the function splits the units into elements and the operators that separate
#' the elements. It identifies the element units, the complex data type for each
#' element and the operators that separate the elements.
#'
#' @param DataType a string which identifies the data type as specified in the
#' TYPE attribute for a data set.
#' @param Units a string identifying the measurement units as specified in the
#' UNITS attribute for a data set after processing with the parseUnitsSpec
#' function.
#' @return A list which contains the following elements:
#' DataType: a string identifying the data type.
#' UnitType: a string identifying whether the units correspond to a 'simple'
#' data type, a 'complex' data type, or a 'compound' data type.
#' Units: a string identifying the units.
#' Elements: a list containing the elements of a compound units. Components of
#' this list are:
#' Types: the complex type of each element,
#' Units: the units of each element,
#' Operators: the operators that separate the units.
#' Errors: a string containing an error message or character(0) if no error.
#' @import stringr
#' @export
checkUnits <- function(DataType, Units) {
  #Define return value template
  Result_ls <- list(
    DataType = DataType,
    UnitType = character(0),
    Units = character(0),
    Elements = list(),
    Errors = character(0)
  )

  #Identify recognized data types and check if DataType is one of them
  DT_ <- names(Types())
  if (!(DataType %in% DT_)) {
    Msg <- paste0(
      "Data type is not a recognized data type. ",
      "Must be one of the following: ",
      paste(DT_, collapse = ", "), ".")
    Result_ls$Errors <- Msg
    return(Result_ls)
  }

  #Check if Units is a character type and has length equal to one
  if (length(Units) != 1 | typeof(Units) != "character") {
    Msg <- paste0(
      "Units value is not correctly specified. ",
      "Must be a string and must not be a vector."
    )
    Result_ls$Errors <- Msg
    Result_ls$Units <- Units
    return(Result_ls)
  }

  #Identify the units type (either simple, complex, or compound)
  UT_ <- character(length(DT_))
  names(UT_) <- DT_
  UT_[DT_ %in% c("double", "integer", "character", "logical")] <- "simple"
  UT_[DT_ %in% "compound"] <- "compound"
  UT_[!UT_ %in% c("simple", "compound")] <- "complex"
  UnitType <- UT_[DataType]
  Result_ls$UnitType <- unname(UnitType)

  #Check Simple Type
  if (UnitType == "simple") {
    #No check necessary, assign units and return the result
    Result_ls$Units <- Units
    return(Result_ls)
  }

  #Check complex type
  if (UnitType == "complex") {
    Result_ls$Units <- Units
    #Check that Units are recognized for the specified data type
    AllowedUnits_ <- names(Types()[[DataType]]$units)
    if (!(Units %in% AllowedUnits_)) {
      Msg <- paste0(
        "Units specified for ", DataType, " are not correctly specified. ",
        "Must be one of the following: ",
        paste(AllowedUnits_, collapse = ", "), ".")
      Result_ls$Errors <- Msg
    }
    #Return the result
    return(Result_ls)
  }

  #Check compound type
  #Define function to identify the data type from a unit
  findTypeFromUnit <- function(Units_) {
    Complex_ls <- Types()[DT_[UT_ == "complex"]]
    AllUnits_ <- unlist(lapply(Complex_ls, function(x) names(x$units)))
    UnitsToTypes_ <- gsub("[0-9]", "", names(AllUnits_))
    names(UnitsToTypes_) <- AllUnits_
    UnitsToTypes_[Units_]
  }
  #Define function to split units from compound type
  splitUnits <- function(Units){
    OperatorLoc_ <- str_locate_all(Units, "[*/]")[[1]][,1]
    Operators_ <- sapply(OperatorLoc_, function(x) substr(Units, x, x))
    UnitParts_ <- unlist(str_split(Units, "[*/]"))
    list(units = unname(UnitParts_),
         types = unname(findTypeFromUnit(UnitParts_)),
         operators = unname(Operators_))
  }
  #Extract the units, types, and operators from the compound units string
  Result_ls$Units <- Units
  Units_ls <- splitUnits(Units)
  Result_ls$Elements$Types <- Units_ls$types
  Result_ls$Elements$Units <- Units_ls$units
  Result_ls$Elements$Operators <- Units_ls$operators
  #Check whether all element units are correct
  UnitsNotFound <- Units_ls$units[is.na(Units_ls$types)]
  if (length(UnitsNotFound) != 0) {
    Msg <- paste0(
      "One or more of the component units of the compound unit ", Units,
      " can't be resolved into units of recognized complex data types. ",
      "The following units elements are not recognized: ",
      paste(UnitsNotFound, collapse = ", "), ".")
    Result_ls$Errors <- Msg
    return(Result_ls)
  }
  #Check whether any duplication of data types for element units
  IsDupType_ <- duplicated(Units_ls$types)
  if (any(IsDupType_)) {
    DupTypes_ <- Units_ls$types[IsDupType_]
    DupUnits_ <- Units_ls$units[Units_ls$types %in% DupTypes_]
    Msg <- paste0(
      "Two or more of the component units of the compound unit ", Units,
      " are units in the same complex data type. ",
      "It does not make sense to have two units of the same complex type ",
      "in the same compound expression. The following units have the same type: ",
      paste(DupUnits_, collapse = ", "), ".")
    Result_ls$Errors <- Msg
    return(Result_ls)
  }
  #Return the result
  return(Result_ls)
}
# checkUnits("double", "person")
# checkUnits("Bogus", "person")
# checkUnits("people", "HH")
# checkUnits("distance", "MI")
# checkUnits("compound", "MI+KM")
# checkUnits("compound", "MI/KM")
# checkUnits("compound", "MI/HR")
# checkUnits("compound", "TRIP/PRSN/DAY")


#CHECK SPECIFICATION TYPE AND UNITS
#==================================
#' Checks the TYPE and UNITS and associated MULTIPLIER and YEAR attributes of a
#' Inp, Get, or Set specification for consistency.
#'
#' \code{checkSpecTypeUnits} a visioneval framework control function that checks
#' correctness of TYPE, UNITS, MULTIPLIER and YEAR attributes of a specification
#' that has been processed with the parseUnitsSpec function.
#'
#' This function checks whether the TYPE and UNITS of a module's specification
#' contain errors. The check is done on a module specification in which the
#' module's UNITS attribute has been parsed by the parseUnitsSpec function to
#' split the name, multiplier, and years parts of the UNITS attribute. The TYPE
#' is checked against the types catalogued in the Types function. The units name
#' in the UNITS attribute is checked against the units names corresponding to
#' each type catalogued in the Types function. The MULTIPLIER is checked to
#' determine whether a value is a valid number, NA, or not a number (NaN). A NA
#' value means that no multiplier was specified (this is OK) a NaN value means
#' that a multiplier that is not a number was specified which is an error. The
#' YEAR attribute is checked to determine whether there is a proper
#' specification if the specified TYPE is currency. If the TYPE is currency, a
#' YEAR must be specified for Get and Set specifications.
#'
#' @param Spec_ls a list for a single specification (e.g. a Get specification
#' for a dataset) that has been processed with the parseUnitsSpec function to
#' split the name, multiplier, and year elements of the UNITS specification.
#' @param SpecGroup a string identifying the group that this specification
#' comes from (e.g. Inp, Get, Set).
#' @param SpecNum a number identifying which specification in the order of the
#' SpecGroup. This is used to identify the subject specification if an error
#' is identified.
#' @return A vector containing messages identifying any errors that are found.
#' @export
checkSpecTypeUnits <- function(Spec_ls, SpecGroup, SpecNum) {
  Errors_ <- character(0)
  Name <- Spec_ls$NAME
  Table <- Spec_ls$TABLE
  Type <- Spec_ls$TYPE
  Units <- Spec_ls$UNITS
  AllowedTypes_ <- names(Types())
  #Check if type is an allowed type
  if (Type %in% AllowedTypes_) {
    #Check if units are correct for the type
    UnitsCheck <- checkUnits(Type, Units)
    if (length(UnitsCheck$Errors) == 0) {
      #Check that there is a valid year specification if type is currency
      if (Type == "currency") {
        if (is.na(Spec_ls$YEAR) & SpecGroup %in% c("Get", "Set")) {
          Msg <-
            paste0("The TYPE specified for the ", SpecGroup, " specification ",
                   "number ", SpecNum, " is 'currency' but the UNITS ",
                   "specification does not  contain a valid year element. ",
                   "A valid year element must be specified so that the ",
                   "framework knows how to convert currency values to and from ",
                   "the proper year for the module. ",
                   "See the user documentation for how to properly specify a ",
                   "year in the UNITS specification.")
          Errors_ <- c(Errors_, Msg)
        }
        if (!is.na(Spec_ls$YEAR) & SpecGroup == "Inp") {
          Msg <-
            paste0("The TYPE specified for the ", SpecGroup, " specification ",
                   "number ", SpecNum, " is 'currency' and the UNITS ",
                   "specification contains a  year element. ",
                   "A year element must NOT be part of the UNITS ",
                   "specification for a ", SpecGroup, " specification because ",
                   "the input file has to specify the nominal year for the ",
                   "input data. For ", SpecGroup, " specifications, the UNITS ",
                   "specification must only include a units name.")
          Errors_ <- c(Errors_, Msg)
        }
      }
      #Check that multiplier is correct
      if (is.nan(Spec_ls$MULTIPLIER) & SpecGroup %in% c("Get", "Set")) {
        Msg <-
          paste0("The UNITS specified for the ", SpecGroup, " specification ",
                 "number ", SpecNum, " does not contain a valid multiplier ",
                 "element. The multiplier element, if present, must use ",
                 "scientific notation with a coefficient of 1. ",
                 "See the user documentation for how to properly specify a ",
                 "multiplier in the UNITS attribute.")
        Errors_ <- c(Errors_, Msg)
      }
      if (!is.na(Spec_ls$MULTIPLIER) & SpecGroup == "Inp") {
        Msg <-
          paste0("The UNITS attribute for the ", SpecGroup, " specification ",
                 "number ", SpecNum, "incorrectly contains a multiplier element. ",
                 "A multiplier element must NOT be part of the UNITS ",
                 "specification for a ", SpecGroup, " specification because ",
                 "the input file has to specify the multiplier for the ",
                 "input data, if there is one. For ", SpecGroup,
                 " specifications, the UNITS specification must only include ",
                 "a units name.")
        Errors_ <- c(Errors_, Msg)
      }
    } else {
      Msg <-
        paste0("UNITS specified for the ", SpecGroup, " specification ",
               "number ", SpecNum, " are incorrect as follows: ",
               UnitsCheck$Errors)
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <-
      paste0("TYPE specified for the ", SpecGroup, " specification ",
             "number ", SpecNum, " has an incorrect type. ",
             "Check user documentation for list of allowed types.")
    Errors_ <- c(Errors_, Msg)
  }
  Errors_
}


#DEFINITION OF BASIC MODULE SPECIFICATIONS REQUIREMENTS
#======================================================
#' List basic module specifications to check for correctness
#'
#' \code{SpecRequirements} a visioneval framework control function that returns
#' a list of basic requirements for module specifications to be used for
#' checking correctness of specifications.
#'
#' This function returns a list of the basic requirements for module
#' specifications. The main components of the list are the components of module
#' specifications: RunBy, NewInpTable, NewSetTable, Inp, Get, Set. For each
#' item of each module specifications component, the list identifies the
#' required data type of the attribute entry and the allowed values for the
#' attribute entry.
#'
#' @return A list comprised of six named components: RunBy, NewInpTable,
#' NewSetTable, Inp, Get, Set. Each main component is a list that has a
#' component for each specification item that has values to be checked. For each
#' such item there is a list having two components: ValueType and ValuesAllowed.
#' The ValueType component identifies the data type that the data entry for the
#' item must have (e.g. character, integer). The ValuesAllowed item identifies
#' what values the item may have.
#' @export
SpecRequirements <- function(){
  list(
    RunFor =
      list(
        ValueType = "character",
        ValuesAllowed = c("AllYears", "BaseYear", "NotBaseYear")
      ),
    RunBy =
      list(
        ValueType = "character",
        ValuesAllowed = c("Region", "Azone", "Bzone", "Czone", "Marea")
      ),
    NewInpTable =
      list(
        TABLE = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        GROUP = list(ValueType = "character",
                     ValuesAllowed = c("Global", "Year"))
      ),
    NewSetTable =
      list(
        TABLE = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        GROUP = list(ValueType = "character",
                     ValuesAllowed = c("Global", "Year"))
      ),
    Inp =
      list(
        NAME = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_]"),
        FILE = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_][.csv]"),
        TABLE = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        GROUP = list(ValueType = "character",
                     ValuesAllowed = c("Global", "Year")),
        TYPE = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_]"),
        UNITS = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        DESCRIPTION = list(ValueType = "character",
                           ValuesAllowed = "[0-9a-zA-Z_]")
      ),
    Get =
      list(
        NAME = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_]"),
        TABLE = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        GROUP = list(ValueType = "character",
                     ValuesAllowed = c("Global", "BaseYear", "Year")),
        TYPE = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_]"),
        UNITS = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]")
      ),
    Set =
      list(
        NAME = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_]"),
        TABLE = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        GROUP = list(ValueType = "character",
                     ValuesAllowed = c("Global", "Year")),
        TYPE = list(ValueType = "character",
                    ValuesAllowed = "[0-9a-zA-Z_]"),
        UNITS = list(ValueType = "character",
                     ValuesAllowed = "[0-9a-zA-Z_]"),
        DESCRIPTION = list(ValueType = "character",
                           ValuesAllowed = "[0-9a-zA-Z_]")
      )
  )
}


#CHECK A MODULE SPECIFICATION
#============================
#' Checks a module specifications for completeness and for incorrect entries
#'
#' \code{checkSpec} a visioneval framework control function that checks a single
#' module specification for completeness and for proper values.
#'
#' This function checks whether a single module specification (i.e. the
#' specification for a single dataset contains the minimum required
#' attributes and that the values of the attributes are correct.
#'
#' @param Spec_ls a list containing the specifications for a single item in
#' a module specifications list.
#' @param SpecGroup a string identifying the specifications group the
#' specification is in (e.g. RunBy, NewInpTable, NewSetTable, Inp, Get, Set).
#' This is used in the error messages to identify which specification has
#' errors.
#' @param SpecNum an integer identifying which specification in the
#' specifications group has errors.
#' @return A vector containing messages identifying any errors that are found.
#' @import stringr
#' @export
checkSpec <- function(Spec_ls, SpecGroup, SpecNum) {
  Require_ls <- SpecRequirements()[[SpecGroup]]
  Errors_ <- character(0)
  #Define function to check one specification requirement
  #ReqName argument is the requirement name (e.g. TYPE). Is NULL for RunBy
  #specification group.
  checkRequirement <-
    function(ReqName = NULL){
      if (is.null(ReqName)) {
        Spec <- Spec_ls
        Req_ls <- Require_ls
        Name <- ""
      } else {
        Spec <- Spec_ls[[ReqName]]
        Req_ls <- Require_ls[[ReqName]]
        Name <- paste0(ReqName, " ")
      }
      Errors_ <- character(0)
      if (length(Spec) == 0) {
        Msg <-
          paste0("Value of the ", Name, " attribute of the ", SpecGroup,
                 " specification number ", SpecNum, " is missing. ",
                 "The attribute must have a value.")
        Errors_ <- c(Errors_, Msg)
      } else {
        if (is.na(Spec)) {
          Msg <-
            paste0("Value of the ", Name, " attribute of the ", SpecGroup,
                   " specification number ", SpecNum, " is NA. ",
                   "The attribute must have a value.")
          Errors_ <- c(Errors_, Msg)
        } else {
          if (typeof(Spec) != Req_ls$ValueType) {
            Msg <-
              paste0("The type of the ", Name, " attribute of the ", SpecGroup,
                     " specification number ", SpecNum, " is incorrect. ",
                     "The attribute must be a ", Req_ls$ValueType, " type.")
            Errors_ <- c(Errors_, Msg)
          }
          if (!any(str_detect(Spec, Req_ls$ValuesAllowed))) {
            Msg <-
              paste0("The value of the ", Name, "attribute of the ", SpecGroup,
                     " specification number ", SpecNum, " is incorrect. ",
                     "The attribute value must be one of the following: ",
                     paste(Req_ls$ValuesAllowed, collapse = ", "), ".")
            Errors_ <- c(Errors_, Msg)
          }
        }
        Errors_
      }
    }
  #Check a specification
  if (SpecGroup %in% c("RunBy", "RunFor")) {
    Errors_ <- c(Errors_, checkRequirement())
  } else {
    for (nm in names(Require_ls)) {
      Errors_ <- c(Errors_, checkRequirement(nm))
    }
    if (SpecGroup %in% c("Inp", "Get", "Set")) {
      Errors_ <- c(Errors_, checkSpecTypeUnits(Spec_ls, SpecGroup, SpecNum))
    }
  }
  Errors_
}


#CHECK THE SPECIFICATIONS FOR A MODULE
#=====================================
#' Checks all module specifications for completeness and for incorrect entries
#'
#' \code{checkModuleSpecs} a visioneval framework control function that checks
#' all module specifications for completeness and for proper values.
#'
#' This function iterates through all the specifications for a module and
#' calls the checkSpec function to check each specification for completeness and
#' for proper values.
#'
#' @param Specs_ls a module specifications list.
#' @param ModuleName a string identifying the name of the module. This is used in
#' the error messages to identify which module has errors.
#' @return A vector containing messages identifying any errors that are found.
#' @export
checkModuleSpecs <- function(Specs_ls, ModuleName) {
  Errors_ <- character(0)
  #Check RunFor
  #------------
  if (!is.null(Specs_ls$RunFor)) {
    Err_ <- checkSpec(Specs_ls$RunFor, "RunFor", 1)
    if (length(Err_) != 0) {
      Msg <-
        paste0(
          "'RunFor' specification for module '", ModuleName,
          "' has one or more errors as follows.")
      Errors_ <- c(Errors_, Msg, Err_)
    }
  }
  #Check RunBy
  #-----------
  Err_ <- checkSpec(Specs_ls$RunBy, "RunBy", 1)
  if (length(Err_) != 0) {
    Msg <-
      paste0(
        "'RunBy' specification for module '", ModuleName,
        "' has one or more errors as follows.")
    Errors_ <- c(Errors_, Msg, Err_)
  }
  rm(Err_)
  #Check NewInpTable if component exists
  #-------------------------------------
  if (!is.null(Specs_ls$NewInpTable)) {
    Err_ <- character(0)
    for (i in 1:length(Specs_ls$NewInpTable)) {
      Err_ <-
        c(Err_, checkSpec(Specs_ls$NewInpTable[[i]], "NewInpTable", i))
    }
    if (length(Err_) != 0) {
      Msg <-
        paste0(
          "'NewInpTable' specification for module '", ModuleName,
          "' has one or more errors as follows.")
      Errors_ <- c(Errors_, Msg, Err_)
    }
    rm(Err_)
  }
  #Check NewSetTable if component exists
  #-------------------------------------
  if (!is.null(Specs_ls$NewSetTable)) {
    Err_ <- character(0)
    for (i in 1:length(Specs_ls$NewSetTable)) {
      Err_ <-
        c(Err_, checkSpec(Specs_ls$NewSetTable[[i]], "NewSetTable", i))
    }
    if (length(Err_) != 0) {
      Msg <-
        paste0(
          "'NewSetTable' specification for module '", ModuleName,
          "' has one or more errors as follows.")
      Errors_ <- c(Errors_, Msg, Err_)
    }
    rm(Err_)
  }
  #Check Inp specifications if component exists
  #--------------------------------------------
  if (!is.null(Specs_ls$Inp)) {
    Err_ <- character(0)
    for (i in 1:length(Specs_ls$Inp)) {
      Err_ <-
        c(Err_, checkSpec(Specs_ls$Inp[[i]], "Inp", i))
    }
    if (length(Err_) != 0) {
      Msg <-
        paste0(
          "'Inp' specification for module '", ModuleName,
          "' has one or more errors as follows.")
      Errors_ <- c(Errors_, Msg, Err_)
    }
    rm(Err_)
  }
  #Check Get specifications
  #------------------------
  if (!is.null(Specs_ls$Get)) {
    Err_ <- character(0)
    for (i in 1:length(Specs_ls$Get)) {
      Err_ <-
        c(Err_, checkSpec(Specs_ls$Get[[i]], "Get", i))
    }
    if (length(Err_) != 0) {
      Msg <-
        paste0(
          "'Get' specification for module '", ModuleName,
          "' has one or more errors as follows.")
      Errors_<- c(Errors_, Msg, Err_)
    }
    rm(Err_)
  }
  #Check Set specifications
  #------------------------
  if (!is.null(Specs_ls$Set)) {
    Err_ <- character(0)
    for (i in 1:length(Specs_ls$Set)) {
      Err_ <-
        c(Err_, checkSpec(Specs_ls$Set[[i]], "Set", i))
    }
    if (length(Err_) != 0) {
      Msg <-
        paste0(
          "'Set' specification for module '", ModuleName,
          "' has one or more errors as follows.")
      Errors_<- c(Errors_, Msg, Err_)
    }
    rm(Err_)
  }
  #Check Call specifications
  #-------------------------
  if (!is.null(Specs_ls$Call)) {
    if (!is.list(Specs_ls$Call)) {
      #If it is not a list check that the value is not something other than TRUE
      if (Specs_ls$Call != TRUE) {
        Msg <-
          paste0(
            "'Call' specification for module '", ModuleName,
            "' is incorrect. If it is not NULL, its value must be TRUE ",
            "or be a list which identifies the the modules to be called."
          )
        Errors_ <- c(Errors_, Msg)
      } else {
      #If the value is TRUE, check that there is not an 'Inp' specification
        if (!is.null(Specs_ls$Inp)) {
          Msg <-
            paste0(
              "Inconsistency between 'Call' and 'Inp' specifications for module '",
              ModuleName, "'. The 'Call' specification is TRUE, ",
              "identifying this as a module to be called by other ",
              "modules rather than a module that is run by the 'runModule' function. ",
              "Modules that are called by other modules must not have 'Inp' ",
              "specifications because no inputs are processed for modules ",
              "that are called by other modules."
            )
        }
      }
    } else {
    #If it is a list, check that the module calls are correctly formatted
      for (name in names(Specs_ls$Call)) {
        Value <- Specs_ls$Call[[name]]
        if (!is.character(Value)) {
          Msg <-
            paste0(
              "'Call' specification for module '", ModuleName,
              "' is incorrect. The value for '", name, "' is not a string."
            )
          Errors_ <- c(Errors_, Msg)
        } else {
          Value_ <- unlist(strsplit(Value, "::"))
          if (length(Value_) != 2) {
            Msg <-
              paste0(
                "'Call' specification for module '", ModuleName,
                "' is incorrect. The value for '", name,
                "' is not formatted correctly. ",
                "It must be formatted like PackageName::ModuleName ",
                "where 'PackageName' is the name of a package and ",
                "'ModuleName' is the name of a module."
              )
            Errors_ <- c(Errors_, Msg)
          }
        }
      }

    }
  }

  #Return errors
  #-------------
  if (length(Errors_) != 0) {
    Msg <- paste0(
      "Module ", ModuleName, " has one or more errors as follow:"
    )
    Errors_ <- c(Msg, Errors_)
  }
  Errors_
}


#CHECK YEARS AND GEOGRAPHY OF INPUT FILE
#=======================================
#' Check years and geography of input file
#'
#' \code{checkInputYearGeo} a visioneval framework control function that checks
#' the 'Year' and 'Geo' columns of an input file to determine whether they are
#' complete and have no duplications.
#'
#' This function checks the 'Year' and 'Geo' columns of an input file to
#' determine whether there are records for all run years specified for the
#' model and for all geographic areas for the level of geography. It also checks
#' for redundant year and geography entries.
#'
#' @param Year_ the vector extract of the 'Year' column from the input data.
#' @param Geo_ the vector extract of the 'Geo' column from the input data.
#' @param Group a string identifying the 'GROUP' specification for the data sets
#' contained in the input file.
#' @param Table a string identifying the 'TABLE' specification for the data sets
#' contained in the input file.
#' @return A list containing the results of the check. The list has two
#' mandatory components and two optional components. 'CompleteInput' is a
#' logical that identifies whether records are present for all years and
#' geographic areas. 'DupInput' identifies where are any redundant year and
#' geography entries. If 'CompleteInput' is FALSE, the list contains a
#' 'MissingInputs' component that is a string identifying the missing year and
#' geography records. If 'DupInput' is TRUE, the list contains a component that
#' is a string identifying the duplicated year and geography records.
#' @export
checkInputYearGeo <- function(Year_, Geo_, Group, Table) {
  Result_ls <- list()
  G <- getModelState()
  #Make a vector of required year and geography combinations
  if (Group == "Year") {
    Required_df <-
      expand.grid(G$Years, unique(G$Geo_df[[Table]]), stringsAsFactors = FALSE)
  }
  names(Required_df) <- c("Year", "Geo")
  RequiredNames_ <- sort(paste(Required_df$Year, Required_df$Geo, sep = "/"))
  #Make a vector of year and geography combinations in the inputs
  InputNames_ <- sort(paste(Year_, Geo_, sep = "/"))
  #Check that there are missing records
  CompleteInputCheck_ <- RequiredNames_ %in% InputNames_
  Result_ls$CompleteInput <- all(CompleteInputCheck_)
  if (!all(CompleteInputCheck_)) {
    MissingNames_ <- RequiredNames_[!CompleteInputCheck_]
    Result_ls$MissingInputs <-
      paste(MissingNames_, collapse = ", ")
  }
  #Check whether there are duplicated records
  DuplicatedInputCheck_ <- duplicated(InputNames_)
  Result_ls$DupInput <- any(DuplicatedInputCheck_)
  if (any(DuplicatedInputCheck_)) {
    DuplicateNames_ <- InputNames_[DuplicatedInputCheck_]
    Result_ls$DuplicatedInputs <-
      paste(DuplicateNames_, collapse = ", ")
  }
  #Return the result
  Result_ls
}


#FIND SPECIFICATION CORRESPONDING TO A NAME, TABLE, AND GROUP
#============================================================
#' Find the full specification corresponding to a defined NAME, TABLE, and GROUP
#'
#' \code{findSpec} a visioneval framework control function that returns the full
#' dataset specification for defined NAME, TABLE, and GROUP.
#'
#' This function finds and returns the full specification from a specifications
#' list whose NAME, TABLE and GROUP values correspond to the Name, Table, and
#' Group argument values. The specifications list must be in standard format and
#' must be for only 'Inp', 'Get', or 'Set' specifications.
#'
#' @param Specs_ls a standard specifications list for 'Inp', 'Get', or 'Set'
#' @param Name a string for the name of the dataset
#' @param Table a string for the table that the dataset resides in
#' @param Group a string for the generic group that the table resides in
#' @return A list containing the full specifications for the dataset
#' @export
findSpec <- function(Specs_ls, Name, Table, Group) {
  SpecIdx <- which(unlist(lapply(Specs_ls, function(x) {
    x$NAME == Name & x$TABLE == Table & x$GROUP == Group
  })))
  Specs_ls[[SpecIdx]]
}


#SORT DATA FRAME TO MATCH ORDER OF GEOGRAPHY IN DATASTORE TABLE
#==============================================================
#' Sort a data frame so that the order of rows matches the geography in a
#' datastore table.
#'
#' \code{sortGeoTable} a visioneval framework control function that returns a
#' data frame whose rows are sorted to match the geography in a specified table
#' in the datastore.
#'
#' This function sorts the rows of a data frame that the 'Geo' field in the
#' data frame matches the corresponding geography names in the specified table
#' in the datastore. The function returns the sorted table.
#'
#' @param Data_df a data frame that contains a 'Geo' field containing the names
#' of the geographic areas to sort by and any number of additional data fields.
#' @param Table a string for the table that is to be matched against.
#' @param Group a string for the generic group that the table resides in.
#' @return The data frame which has been sorted to match the order of geography
#' in the specified table in the datastore.
#' @export
sortGeoTable <- function(Data_df, Table, Group) {
  if (!("Geo" %in% names(Data_df))) {
    Msg <-
      paste0(
        "Data frame does not have a 'Geo' field. ",
        "A 'Geo' field must be included in order for the table to be sorted ",
        "to match the geography of the specified table in the datastore."
      )
    stop(Msg)
  }
  DstoreNames_ <- readFromTable(Table, Table, Group)
  Order_ <- match(DstoreNames_, Data_df$Geo)
  Data_df[Order_,]
}


#PARSE INPUT FILE FIELD NAMES
#============================
#' Parse field names of input file to separate out the field name, currency
#' year, and multiplier.
#'
#' \code{parseInputFieldNames} a visioneval framework control function that
#' parses the field names of an input file to separate out the field name,
#' currency year (if data is currency type), and value multiplier.
#'
#' The field names of input files can be used to encode more information than
#' the name itself. It can also encode the currency year for currency type data
#' and also if the values are in multiples (e.g. thousands of dollars). For
#' currency type data it is mandatory that the currency year be specified so
#' that the data can be converted to base year currency values (e.g. dollars in
#' base year dollars). The multiplier is optional, but needless to say, it can
#' only be applied to numeric data. The function returns a list with a component
#' for each field. Each component identifies the field name, year, multiplier,
#' and error status for the result of parsing the field name. If the field name
#' was parsed successfully, the error status is character(0). If the field name
#' was not successfully parsed, the error status contains an error message,
#' identifying the problem.
#'
#' @param FieldNames_ A character vector containing the field names of an
#' input file.
#' @param Specs_ls A list of specifications for fields in the input file.
#' @param FileName A string identifying the name of the file that the field
#' names are from. This is used for writing error messages.
#' @return A named list with one component for each field. Each component is a list
#' having 4 named components: Error, Name, Year, Multiplier. The Error
#' component has a value of character(0) if there are no errors or a character
#' vector of error messages if there are errors. The Name component is a string
#' with the name of the field. The Year component is a string with the year
#' component if the data type is currency or NA if the data type is not currency
#' or if the Year component has an invalid value. The Multiplier is a number if
#' the multiplier component is present and is valid. It is NA if there is no
#' multiplier component and NaN if the multiplier is invalid. Each component of
#' the list is named with the value of the Name component (i.e. the field name
#' without the year and multiplier elements.)
#' @export
parseInputFieldNames <-
  function(FieldNames_, Specs_ls, FileName) {
    #Define function to return a multiplier value from a multiplier string
    #NA if none, NaN if not a properly specified scientic notation (e.g. 1e3)
    getMultiplier <- function(String) {
      if (is.na(String)) {
        Result <- NA
      } else {
        SciTest_ <- as.numeric(unlist(strsplit(String, "e")))
        if (length(SciTest_) != 2 |
            any(is.na(SciTest_)) |
            SciTest_[1] != 1) {
          Result <- NaN
        } else {
          Result <- as.numeric(String)
        }
      }
      Result
    }
    #Define function to return a year value from a year string
    #NA if none or not a correct year
    getYear <- function(String) {
      CurrentString <- unlist(strsplit(as.character(Sys.Date()), "-"))[1]
      if (is.na(as.numeric(String)) | is.na(String)) {
        Result <- NA
      } else {
        if (as.numeric(String) < 1900 | as.numeric(String) > CurrentString) {
          Result <- NA
        } else {
          Result <- String
        }
      }
      Result
    }
    #Make a list to store results
    Fields_ls <- list()
    #Make an index to the specified field names
    SpecdNames_ <- unlist(lapply(Specs_ls, function(x) x$NAME))
    for (i in 1:length(FieldNames_)) {
      Fields_ls[[i]] <- list()
      FieldName <- FieldNames_[i]
      Fields_ls[[i]]$Error <- character(0)
      #Split the parts of the units specification
      NameSplit_ <- unlist(strsplit(FieldName, "\\."))
      #The field name is the first element
      Name <- NameSplit_[1]
      Fields_ls[[i]]$Name <- Name
      #If the field name is "Geo" or "Year" move on to next field
      if (Name %in% c("Geo", "Year")) next()
      #Check that the parsed name is one of the specified field names
      if (!(Name %in% SpecdNames_)) {
        Fields_ls[[i]]$Year <- NA
        Fields_ls[[i]]$Multiplier <- NA
        Msg <-
          paste0("Field name ", FieldName, " does not parse to a name that ",
                 "can be recognized as one of the names specified for the ",
                 "input file ", FileName)
        Fields_ls[[i]]$Error <- c(Fields_ls[[i]]$Error, Msg)
        rm(Msg)
        next()
      }
      #Decode the Year and Multiplier portions
      FieldType <- Specs_ls[[which(SpecdNames_ == Name)]]$TYPE
      if (FieldType == "currency") {
        Fields_ls[[i]]$Year <- getYear(NameSplit_[2])
        Fields_ls[[i]]$Multiplier <- getMultiplier(NameSplit_[3])
      } else {
        Fields_ls[[i]]$Year <- NA
        Fields_ls[[i]]$Multiplier <- getMultiplier(NameSplit_[2])
      }
      #If currency type, check that value is correct or give an error
      if (FieldType == "currency") {
        AllowedYears_ <- as.character(getModelState()$Deflators$Year)
        if (is.na(Fields_ls[[i]]$Year)) {
          Msg <-
            paste0("Field name ", FieldName, " in input file ", FileName,
                   " has a specification TYPE of currency, but the parsed year ",
                   "component is missing or is not a valid year. ",
                   "See documentation for details on how to properly name ",
                   "a field name that has a year component. ")
          Fields_ls[[i]]$Error <- c(Fields_ls[[i]]$Error, Msg)
          rm(Msg)
        } else {
          if (!(Fields_ls[[i]]$Year %in% AllowedYears_)) {
            Msg <-
              paste0("Field name ", FieldName, " in input file ", FileName,
                     " has a specification TYPE of currency, but the parsed year ",
                     "component is not one for which there is a deflator. ",
                     "If the year component is correct, then the deflators file ",
                     "must be corrected to include a deflator for the year. ",
                     "See documentation for details on the deflator file requirements.")
            Fields_ls[[i]]$Error <- c(Fields_ls[[i]]$Error, Msg)
            rm(Msg)
          }
        }
      }
      #Check whether multiplier is correct or give an error
      if (is.nan(Fields_ls[[i]]$Multiplier)) {
        Msg <-
          paste0("Field name ", FieldName, " in input file ", FileName,
                 " has parsed multiplier component that is not valid. ",
                 "See documentation for details on how to properly name ",
                 "a field name that has a multiplier component. ")
        Fields_ls[[i]]$Error <- c(Fields_ls[[i]]$Error, Msg)
        rm(Msg)
      }
    }
    names(Fields_ls) <- unlist(lapply(Fields_ls, function(x) x$Name))
    Fields_ls
  }

# items <- item <- list
# Specs_ls <-
#   items(
#     item(
#       NAME = "TotHhPop",
#       TYPE = "double",
#       UNITS = "persons"
#     ),
#     item(
#       NAME = "TotHhIncome",
#       TYPE = "currency",
#       UNITS = "USD"
#     )
#   )
# FieldNames_ <- c("Geo", "Year", "TotHhPop.1e3", "TotHhIncome.2000")
# temp_ls <- parseInputFieldNames(FieldNames_, Specs_ls, "test.csv")
# FieldNames_ <- c("Geo", "Year", "TotHhPop.1000", "TotHhIncome.1998.1000")
# temp_ls <- parseInputFieldNames(FieldNames_, Specs_ls, "test.csv")
# FieldNames_ <- c("Geo", "Year", "TotHhPop.1000", "TotHhIncome.hello.1000")
# parseInputFieldNames(FieldNames_, Specs_ls, "test.csv")
# unlist(lapply(temp_ls, function(x) x$Error))


#PROCESS MODULE INPUT FILES
#==========================
#' Process module input files
#'
#' \code{processModuleInputs} a visioneval framework control function that
#' processes input files identified in a module's 'Inp' specifications in
#' preparation for saving in the datastore.
#'
#' This function processes the input files identified in a module's 'Inp'
#' specifications in preparation for saving the data in the datastore. Several
#' processes are carried out. The existence of each specified input file is
#' checked. Any file whose corresponding 'GROUP' specification is 'Year', is
#' checked to determine that it has 'Year' and 'Geo' columns. The entries in the
#' 'Year' and 'Geo' columns are checked to make sure they are complete and there
#' are no duplicates. Any file whose 'GROUP' specification is 'Global' or
#' 'BaseYear' and whose 'TABLE' specification is a geographic specification
#' other than 'Region' is checked to determine if it has a 'Geo' column and the
#' entries are checked for completeness. The data in each column are checked
#' against specifications to determine conformance. The function returns a list
#' which contains a list of error messages and a list of the data inputs. The
#' function also writes error messages and warnings to the log file.
#'
#' @param ModuleSpec_ls a list of module specifications that is consistent with
#' the VisionEval requirements.
#' @param ModuleName a string identifying the name of the module (used to document
#' module in error messages).
#' @param Dir a string identifying the relative path to the directory where the
#' model inputs are contained.
#' @return A list containing the results of the input processing. The list has
#' two components. The first (Errors) is a vector of identified file and data
#' errors. The second (Data) is a list containing the data in the input files
#' organized in the standard format for data exchange with the datastore.
#' @export
processModuleInputs <-
  function(ModuleSpec_ls, ModuleName, Dir = "inputs") {
    G <- getModelState()
    InpSpec_ls <- ModuleSpec_ls$Inp

    #ORGANIZE THE SPECIFICATIONS BY INPUT FILE AND NAME
    SortSpec_ls <- list()
    for (i in 1:length(InpSpec_ls)) {
      Spec_ls <- InpSpec_ls[[i]]
      File <- Spec_ls$FILE
      Name <- Spec_ls$NAME
      if (is.null(SortSpec_ls[[File]])) {
        SortSpec_ls[[File]] <- list()
      }
      SortSpec_ls[[File]][[Name]] <- Spec_ls
      rm(Spec_ls, File, Name)
    }
    #Initialize a list to store all the input data
    Data_ls <- initDataList()

    #ITERATE THROUGH SORTED SPECIFICATIONS AND LOAD DATA INTO LIST
    FileErr_ls <- list()
    FileWarn_ls <- list()
    Files_ <- names(SortSpec_ls)
    for (File in Files_) {
      #Initialize FileErr_ and FileWarn_
      FileErr_ <- character(0)
      FileWarn_ <- character(0)
      #Extract the specifications
      Spec_ls <- SortSpec_ls[[File]]
      #Check that file exists
      if (!file.exists(file.path(Dir, File))) {
        Msg <-
          paste(
            "Input file error.", "File '", File, "' required by '",
            ModuleName, "' is not present in the 'inputs' directory."
          )
        FileErr_ <- c(FileErr_, Msg)
        next()
      }
      #Read in the data file
      Data_df <- read.csv(file.path(Dir, File), as.is = TRUE)
      
      # Remove the Byte order mark that sometimes appears in the beginning of
      # UTF-8 files on Windows.  Byte Order Mark can't be saved in this
      # windows encoded text file so I include it as raw
      # The real solution is to use read.csv with fileEncoding='UTF-8-BOM'
      # but that requires knowing the encoding of the CSV file ahead of time
      # The BOM is \uEFBBBF or rawToChar(as.raw(c(0xef, 0xbb, 0xbf)))
      # but it gets converted to 0xef 0x2e 0x2e when it is read in on a 
      # machine using WIN1252 locale.  
      # See https://stackoverflow.com/questions/39593637/dealing-with-byte-order-mark-bom-in-r
      bom <- rawToChar(as.raw(c(0xef, 0x2e, 0x2e)))
      names(Data_df) <- stringr::str_replace(names(Data_df), bom, "")
      
      #Parse the field names of the data file
      ParsedNames_ls <- parseInputFieldNames(names(Data_df), Spec_ls, File)
      ParsingErrors_ <- unlist(lapply(ParsedNames_ls, function(x) x$Error))
      names(Data_df) <- names(ParsedNames_ls)
      if (length(ParsingErrors_) != 0) {
        writeLog(
          c("Input file field name errors as follows:", ParsingErrors_))
        FileErr_ <- c(FileErr_, ParsingErrors_)
      } else {
        rm(ParsingErrors_)
      }
      #Identify the group and table the data is to be placed in
      Group <- unique(unlist(lapply(Spec_ls, function(x) x$GROUP)))
      if (length(Group) != 1) {
        Msg <-
          paste0(
            "Input specification error for module '", ModuleName,
            "' for input file '", File, "'. ",
            "All datasets must have the same 'Group' specification."
          )
        FileErr_ <- c(FileErr_, Msg)
        Group <- Group[1]
      }
      Table <- unique(unlist(lapply(Spec_ls, function(x) x$TABLE)))
      if (length(Table) != 1) {
        Msg <-
          paste0(
            "Input specification error for module '", ModuleName,
            "' for input file '", File, "'. ",
            "All datasets must have the same 'Table' specification."
          )
        FileErr_ <- c(FileErr_, Msg)
        Table <- Table[1]
      }
      #Add Table and table attributes to data list if not already there
      if (is.null(Data_ls[[Group]][[Table]])) {
        Data_ls[[Group]][[Table]] <- list()
      }
      #If Group is Year and Table is not Region, check Geo and Year fields
      if (Group  == "Year" & Table != "Region") {
        #Check that there are 'Year' and 'Geo' fields
        HasYearField <- "Year" %in% names(Data_df)
        HasGeoField <- "Geo" %in% names(Data_df)
        if (!(HasYearField & HasGeoField)) {
          Msg <-
            paste0(
              "Input file error for module '", ModuleName,
              "' for input file '", File, "'. ",
              "'Group' specification is 'Year' or 'RunYear' ",
              "but the input file is missing required 'Year' ",
              "and/or 'Geo' fields."
            )
          FileErr_ <- c(FileErr_, Msg)
          next()
        }
        #Check that the file thas inputs for all years and geographic units
        #If so, save Year and Geo to table
        CorrectYearGeo <-
          checkInputYearGeo(Data_df$Year, Data_df$Geo, Group, Table)
        if (CorrectYearGeo$CompleteInput & !CorrectYearGeo$DupInput) {
          Data_ls[[Group]][[Table]]$Year <- Data_df$Year
          Data_ls[[Group]][[Table]]$Geo <- Data_df$Geo
        } else {
          if (!CorrectYearGeo$CompleteInput) {
            Msg <-
              paste0(
                "Input file error for module '", ModuleName,
                "' for input file '", File, "'. ",
                "Is missing inputs for the following Year/", Table,
                " combinations: ", CorrectYearGeo$MissingInputs
              )
            FileErr_ <- c(FileErr_, Msg)
          }
          if(CorrectYearGeo$DupInput){
            Msg <-
              paste0(
                "Input file error for module '", ModuleName,
                "' for input file '", File, "'. ",
                "Has duplicate inputs for the following Year/", Table,
                " combinations: ", CorrectYearGeo$DuplicatedInputs
              )
            FileErr_ <- c(FileErr_, Msg)
          }
          next()
        }
      }
      #If Group is BaseYear or Global, and if Table is Azone, Bzone, Czone, or
      #Marea, check that geography is complete and correct
      if (Group %in% c("BaseYear", "Global") &
          Table %in% c("Azone", "Bzone", "Czone", "Marea")) {
        #Check that there is a 'Geo' field
        HasGeoField <- "Geo" %in% names(Data_df)
        if (!HasGeoField) {
          Msg <-
            paste0(
              "Input file error for module '", ModuleName,
              "' for input file '", File, "'. ",
              "'Table' specification is ", Table,
              " but the input file is missing required 'Geo' field."
            )
          FileErr_ <- c(FileErr_, Msg)
          next()
        }
        #Check that the 'Geo' field is complete and not duplicated
        GeoDuplicated <- any(duplicated(Data_df$Geo))
        GeoIncomplete <- any(!(G$Geo_df[[Table]] %in% Data_df$Geo))
        if (GeoDuplicated | GeoIncomplete) {
          if (GeoDuplicated) {
            DupGeo_ <- unique(Data_df$Geo[GeoDuplicated])
            Msg <-
              paste0(
                "Input file error for module '", ModuleName,
                "' for input file '", File, "'. ",
                "Has duplicate inputs for the following geographic areas: ",
                paste(DupGeo_)
              )
            FileErr_ <- c(FileErr_, Msg)
            rm(DupGeo_)
          }
          if (GeoIncomplete) {
            IncompleteGeo_ <- G$Geo_df[[Table]][GeoIncomplete]
            Msg <-
              paste0(
                "Input file error for module '", ModuleName,
                "' for input file '", File, "'.",
                "Is missing inputs for the following geographic areas: ",
                paste(IncompleteGeo_)
              )
            FileErr_ <- c(FileErr_, Msg)
            rm(IncompleteGeo_)
          }
          next()
        } else {
          Data_ls[[Group]][[Table]]$Geo <- Data_df$Geo
        }
      }
      #If Group is Year and Table is Region, check years are complete
      if (Group  == "Year" & Table == "Region") {
        #Check that there is a 'Year' field
        HasYearField <- "Year" %in% names(Data_df)
        if (!HasYearField) {
          Msg <-
            paste0(
              "Input file error for module '", ModuleName,
              "' for input file '", File, "'. ",
              "'Table' specification is ", Table,
              " but the input file is missing required 'Year' field."
            )
          FileErr_ <- c(FileErr_, Msg)
          next()
        }
        #Check that the 'Year' field is complete and not duplicated
        YearDuplicated <- any(duplicated(Data_df$Year))
        YearIncomplete <- any(!(G$Years %in% Data_df$Year))
        if (YearDuplicated | YearIncomplete) {
          if (YearDuplicated) {
            DupYear_ <- unique(Data_df$Year[YearDuplicated])
            Msg <-
              paste0(
                "Input file error for module '", ModuleName,
                "' for input file '", File, "'. ",
                "Has duplicate inputs for the following years: ",
                paste(DupYear_)
              )
            FileErr_ <- c(FileErr_, Msg)
            rm(DupYear_)
          }
          if (YearIncomplete) {
            IncompleteYear_ <- G$Years[YearIncomplete]
            Msg <-
              paste0(
                "Input file error for module '", ModuleName,
                "' for input file '", File, "'.",
                "Is missing inputs for the following years: ",
                paste(IncompleteYear_)
              )
            FileErr_ <- c(FileErr_, Msg)
            rm(IncompleteYear_)
          }
          next()
        } else {
          Data_ls[[Group]][[Table]]$Year <- Data_df$Year
        }
      }
      #Check and load data into list
      DataErr_ls <- list(Errors = character(0), Warnings = character(0))
      for (Name in names(Spec_ls)) {
        ThisSpec_ls <- Spec_ls[[Name]]
        Data_ <- Data_df[[Name]]
        DataCheck_ls <-
          checkDataConsistency(Name, Data_, ThisSpec_ls)
        if (length(DataCheck_ls$Errors) != 0) {
          DataErr_ls$Errors <-
            c(DataErr_ls$Errors, DataCheck_ls$Errors)
          next()
        }
        if (length(DataCheck_ls$Warnings) != 0) {
          DataErr_ls$Warnings <-
            c(DataErr_ls$Warnings, DataCheck_ls$Warnings)
        }
        #Convert currency
        if (ThisSpec_ls$TYPE == "currency") {
          FromYear <- ParsedNames_ls[[Name]]$Year
          ToYear <- G$BaseYear
          if (!is.na(FromYear) &  FromYear != ToYear) {
            Data_ <- deflateCurrency(Data_, FromYear, ToYear)
            rm(FromYear, ToYear)
          }
        }
        #Convert units
        SimpleTypes_ <- c("integer", "double", "character", "logical")
        ComplexTypes_ <- names(Types())[!(names(Types()) %in% SimpleTypes_)]
        if (ThisSpec_ls$TYPE %in% ComplexTypes_) {
          FromUnits <- ThisSpec_ls$UNITS
          Conversion_ls <- convertUnits(Data_, ThisSpec_ls$TYPE, FromUnits)
          Data_ <- Conversion_ls$Values
          #Update UNITS to reflect datastore units
          ThisSpec_ls$UNITS <- Conversion_ls$ToUnits
          rm(FromUnits, Conversion_ls)
        }
        rm(SimpleTypes_, ComplexTypes_)
        #Convert magnitude
        Multiplier <- ParsedNames_ls[[Name]]$Multiplier
        if (!is.na(Multiplier)) {
          Data_ <- convertMagnitude(Data_, Multiplier, 1)
        }
        rm(Multiplier)
        #Assign UNITS attribute to Data_ because storage units may be different
        #than the input data UNITS
        attributes(Data_) <- list(UNITS = ThisSpec_ls$UNITS)
        #Assign Data_ to Data_ls
        Data_ls[[Group]][[Table]][[Name]] <- Data_
      }
      if (length(DataErr_ls$Errors) != 0) {
        Msg <-
          paste0(
            "Input file error for module '", ModuleName,
            "' for input file '", File, "'. ",
            "Has one or more errors in the data inputs as follows:"
          )
        FileErr_ <- c(FileErr_, Msg, DataErr_ls$Errors)
        writeLog(FileErr_)
      }
      FileErr_ls <- c(FileErr_ls, FileErr_)
      if (length(DataErr_ls$Warnings) != 0) {
        Msg <-
          paste0(
            "Input file warnings for module '", ModuleName,
            "' for input file '", File, "'. ",
            "Has one or more warnings for the data inputs as follows:"
          )
        FileWarn_ <- c(FileWarn_, Msg, DataErr_ls$Warnings)
        writeLog(FileWarn_)
      }
      FileWarn_ls <- c(FileWarn_ls, FileWarn_)
    }#End loop through input files

    #RETURN THE RESULTS
    list(
      Errors = unlist(FileErr_ls),
      Warnings = unlist(FileWarn_ls),
      Data = Data_ls)
  }


