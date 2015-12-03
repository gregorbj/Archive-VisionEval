#================
#hdf5_utilities.R
#================

#This script defines functions for interacting with an HDF5 datastore, including
#listing contents, initializing tables and datasets, writing datasets, and
#reading datasets.


#DEFINE FUNCTION FOR LISTING THE CONTENTS OF THE DATASTORE
#=========================================================
#' List datastore contents.
#'
#' \code{listDatastore} lists the contents of a datastore.
#'
#' This function lists the contents of a datastore including identifying all
#' groups, tables, and datasets. It also lists the attributes associated with
#' each table and dataset. The listing is stored in the run environment as
#' 'E$Datastore'. This function is run whenever the structure or contents of the
#' datastore is changed to always keep the listing in E$Datastore current.
#'
#' @return The function has no return value. It stores the listing in
#'   E$Datastore.
#' @export
listDatastore <- function() {
  H5File <- H5Fopen(E$DatastoreName)
  DS_df <- h5ls(H5File, all = TRUE)
  DS_df$groupname <- paste(DS_df$group, DS_df$name, sep = "/")
  DS_df$groupname <- gsub("^/+", "", DS_df$groupname)
  DS_df <-
    DS_df[, c("group", "name", "groupname", "otype", "num_attrs", "dclass", "dtype")]
  Attr_ls <- list()
  for (i in 1:nrow(DS_df)) {
    if (DS_df$num_attrs[i] == 0) {
      Attr_ls[[i]] <- NA
    } else {
      Item <- paste(DS_df$group[i], DS_df$name[i], sep = "/")
      #Attr_ls[[i]] <- unlist(h5readAttributes(H5File, Item))
      Attr_ls[[i]] <- h5readAttributes(H5File, Item)
    }
  }
  DS_df$attributes <- Attr_ls
  H5Fclose(H5File)
  E$Datastore <- DS_df[,c("group", "name", "groupname", "attributes")]
}


#DEFINE FUNCTION FOR INITIALIZING THE DATASTORE
#==============================================
#' Initialize Datastore.
#'
#' \code{initDatastore} creates datastore with starting structure.
#'
#' This function creates the datastore file for the model run with the initial
#' structure. The file is created in the working directory and is named
#' 'datastore.h5'. If this file already exists it is deleted and a new
#' initialized file is created. Groups are created in the file; one for each
#' model run year and one named 'Global' for storing global values.
#'
#' @return The function has no return value. It calls the 'listDatastore'
#'   function which adds a listing of the datastore contents to the run
#'   environment as 'E$Datastore'.
#' @export
initDatastore <- function() {
  #If data store exists, delete
  DatastoreName <- E$DatastoreName
  if (file.exists(DatastoreName)) {
    file.remove(DatastoreName)
  }
  #Create data store file
  H5File <- H5Fcreate(DatastoreName)
  #Create global group which stores global values
  h5createGroup(H5File, "Global")
  #Create groups for years
  for (year in as.character(E$Years)) {
    YearGroup <- year
    h5createGroup(H5File, YearGroup)
  }
  H5Fclose(H5File)
  listDatastore()
}


#DEFINE FUNCTION FOR INITIALIZING A TABLE IN THE DATASTORE
#=========================================================
#' Initialize table in datastore.
#'
#' \code{initDatastoreTable} initializes a table in the datastore.
#'
#' A table in the datastore is a group which contains equal length vectors of
#' data that may have different types. Thus is is much like an R data frame
#' which is a list containing equal length vectors that may have different
#' types. A table is initialized in the datastore by initializing a group whose
#' name is the table name and assigning a 'LENGTH' attribute which specifies the
#' length that all data vectors in the table must have.
#'
#' @param Spec_ls a list containing the standard module 'Set' specifications. It
#'   has the following components: MODULE The name of the module that is
#'   creating the data. NAME The name of the dataset TABLE The name of the table
#'   the dataset is in TYPE The data type for the data ("integer", "double",
#'   "character", "logical"). UNITS The measurement units for the data. NAVALUE
#'   The value that is used to represent NA values in the dataset. PROHIBIT A
#'   vector which describes prohibited data values. ISELEMENTOF A vector which
#'   identifies allowed categorical values. SIZE The maximum number of
#'   characters that can be stored in an entry for character data. Value for
#'   non-character type data should be 0.
#' @param Year a string representation of the model run year.
#' @return The value TRUE is returned if the function is successful at creating
#'   the table. In addition, the 'listDatastore' function is run to update the
#'   inventory in the run environment. The function stops if the group in which
#'   the table is to be placed does not exist in the datastore and a message is
#'   written to the log.
#' @export
initTable <- function(Spec_ls, Year) {
  Year <- checkYear(Year, E$Datastore)
  if (!is.null(Spec_ls$LENGTH)) {
    Length <- Spec_ls$LENGTH
  } else if (!is.null(Module[["LENGTH"]][Spec_ls$TABLE])) {
    Length <- Module[["LENGTH"]][Spec_ls$TABLE]
  } else {
    Message <- paste0("LENGTH specification for table (", Spec_ls$TABLE,
                      ") is not present.")
    writeLog(Message)
    stop(Message)
  }
  NewGroup <- paste(Year, Spec_ls$TABLE, sep = "/")
  H5File <- H5Fopen(E$DatastoreName)
  h5createGroup(H5File, NewGroup)
  H5Group <- H5Gopen(H5File, NewGroup)
  h5writeAttribute(Length, H5Group, "LENGTH")
  H5Gclose(H5Group)
  H5Fclose(H5File)
  listDatastore()
  TRUE
}


#DEFINE A FUNCTION TO INITIALIZE A DATASET IN A TABLE
#====================================================
#' Initialize dataset in datastore table.
#'
#' \code{initDataset} initializes a dataset in a table.
#'
#' This function initializes a dataset which must be done before data can be
#' stored. Initialization establishes a name for the dataset and key attributes
#' associated with the data.
#'
#' @param Spec_ls a list containing the standard module 'Set' specifications. It
#'   has the following components: MODULE The name of the module that is
#'   creating the data. NAME The name of the dataset TABLE The name of the table
#'   the dataset is in TYPE The data type for the data ("integer", "double",
#'   "character", "logical"). UNITS The measurement units for the data. NAVALUE
#'   The value that is used to represent NA values in the dataset. PROHIBIT A
#'   vector which describes prohibited data values. ISELEMENTOF A vector which
#'   identifies allowed categorical values. SIZE The maximum number of
#'   characters that can be stored in an entry for character data. Value for
#'   non-character type data should be 0. LENGTH The number of rows in the
#'   table.
#' @param Year a string representation of the model run year.
#' @return The function has no return value. If the function is successful, the
#'   dataset is initialized. If the dataset already exists or the table doesn't
#'   exist, the function throws an error and writes an error message to the log.
#' @export
initDataset <- function(Spec_ls, Year) {
  Table <- paste(Year, Spec_ls$TABLE, sep = "/")
  Name <- Spec_ls$NAME
  DatasetName <- paste(Table, Name, sep = "/")
  #Initialize table if it does not exist
  if (!(Table %in% E$Datastore$groupname)) {
    Message <-
      paste("Table", Table, "has not been created in the datastore.",
            "Attempting to create.")
    writeLog(Message)
    initTable(Spec_ls, Year)
  }
  #Check if the dataset already exists
  DatasetExists <- DatasetName %in% E$Datastore$groupname
  if (DatasetExists) {
    Message <- paste(
      "Dataset", Name, "already exists in table",
      Table, "-- stopping dataset initialization."
    )
    writeLog(Message)
    warning(Message)
    return(FALSE)
  }
  #Read SIZE specification or throw error if doesn't exist
  if (!is.null(Spec_ls$SIZE)) {
    Size <- Spec_ls$SIZE
  } else if (!is.null(Module[["SIZE"]][Name])) {
    Size <- Module[["SIZE"]][Name]
  } else {
    Message <- paste0("SIZE specification for dataset (", Name,
                      ") is not present.")
    writeLog(Message)
    stop(Message)
  }
  #Create the dataset
  Length <- unlist(h5readAttributes(E$DatastoreName, Table))["LENGTH"]
  Chunck <- ifelse(Length > 1000, 100, 1)
  H5File <- H5Fopen(E$DatastoreName)
  h5createDataset(
    H5File, DatasetName, dims = Length,
    storage.mode = Spec_ls$TYPE, size = Size + 1,
    chunk = Chunck, level = 7
  )
  H5Data <- H5Dopen(H5File, DatasetName)
  h5writeAttribute(Spec_ls$MODULE, H5Data, "MODULE")
  h5writeAttribute(Spec_ls$NAVALUE, H5Data, "NAVALUE")
  h5writeAttribute(Spec_ls$UNITS, H5Data, "UNITS")
  h5writeAttribute(Size, H5Data, "SIZE")
  h5writeAttribute(Spec_ls$TYPE, H5Data, "TYPE")
  h5writeAttribute(Spec_ls$PROHIBIT, H5Data, "PROHIBIT")
  h5writeAttribute(Spec_ls$ISELEMENTOF, H5Data, "ISELEMENTOF")
  H5Dclose(H5Data)
  H5Fclose(H5File)
  #Update datastore inventory
  listDatastore()
}


#DEFINE A FUNCTION FOR WRITING A DATA ITEM TO A DATASTORE TABLE
#==============================================================
#' Write to table.
#'
#' \code{writeToTable} writes data to table and initializes dataset if needed.
#'
#' This function writes data to a dataset in a table. It initializes the dataset
#' if the dataset does not exist. Enables data to be written to specific
#' location indexes in the dataset. The function makes several checks prior to
#' attempting to write to the datastore including : the desired table exists in
#' the datastore, the input data is a vector, the data and index conform to each
#' other and to the table length, the type, size, and units of the data match
#' the datastore specifications. On successful completion, the function calls
#' 'listDatastore' to update the datastore listing in the run environment.
#'
#' @param Data A vector of data to be written.
#' @param Spec_ls a list containing the standard module 'Set' specifications. It
#'   has the following components: MODULE The name of the module that is
#'   creating the data. NAME The name of the dataset TABLE The name of the table
#'   the dataset is in TYPE The data type for the data ("integer", "double",
#'   "character", "logical"). UNITS The measurement units for the data. NAVALUE
#'   The value that is used to represent NA values in the dataset. PROHIBIT A
#'   vector which describes prohibited data values. ISELEMENTOF A vector which
#'   identifies allowed categorical values. SIZE The maximum number of
#'   characters that can be stored in an entry for character data. Value for
#'   non-character type data should be 0. LENGTH The number of rows in the
#'   table.
#' @param Year a string representation of the model run year.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to.
#' @return The function returns TRUE if data is sucessfully written.
#' @export
writeToTable <- function(Data_, Spec_ls, Year, Index = NULL) {
  Name <- Spec_ls$NAME
  Table <- Spec_ls$TABLE
  #Check that table exists to write to and attempt to create if not
  TableCheck <- checkTable(Table, Year, E$Datastore, ThrowError = FALSE)
  if (!TableCheck[[1]]) {
    Message <-
      paste("Table", Table, "has not been created in the datastore.",
            "Attempting to create.")
    writeLog(Message)
    initTable(Spec_ls, Year)
  }
  #Check that dataset exists to write to and attempt to create if not
  DatasetCheck <- checkDataset(Name, Table, Year, E$Datastore, ThrowError = FALSE)
  if (!DatasetCheck[[1]]) {
    Message <-
      paste("Dataset", Name, "has not been initialized in the datastore.",
            "Attempting to initialize.")
    writeLog(Message)
    initDataset(Spec_ls, Year)
  }
  #Check that data is a vector
  if (!is.vector(Data_)) {
    Message <-
      paste0("Data ", Name, " does not conform to ", Table, ". Must be a vector.")
    writeLog(Message)
    stop(Message)
  }
  #Check whether the data is consistent with datastore attributes
  DstoreAttr_ls <- getDatasetAttr(Name, Table, Year, E$Datastore)
  SpecCheck_ls <- checkSpecConsistency(Spec_ls, DstoreAttr_ls)
  if (length(SpecCheck_ls$Errors) != 0) {
    writeLog(SpecCheck_ls$Errors)
    stop("Specifications of data to be written don't conform with datastore specifications.")
  }
  if (length(SpecCheck_ls$Warnings) != 0) {
    writeLog(SpecCheck_ls$Warnings)
  }
  DataCheck_ls <- checkDataConsistency(Name, Data_, DstoreAttr_ls)
  if (length(DataCheck_ls$Errors) != 0) {
    writeLog(DataCheck_ls$Errors)
    stop("Data to be written doesn't conform with datastore specifications.")
  }
  if (length(DataCheck_ls$Warnings) != 0) {
    writeLog(DataCheck_ls$Warnings)
  }
  #Check that the data conforms to the table if not indexed write
  TableAttr_ <-
    unlist(E$Datastore$attributes[E$Datastore$groupname == file.path(Year, Table)])
  AllowedLength <- TableAttr_["LENGTH"]
  if (is.null(Index) & (length(Data_) != AllowedLength)) {
    Message <-
      paste0(Name, " doesn't conform to", Table, ". must have length = ",
             AllowedLength)
    writeLog(Message)
    stop(Message)
  }
  #Check that if there is an index, the length is equal to the length of Data
  if (!is.null(Index) & (length(Data_) != length(Index))) {
    Message <-
      paste0("Length of Data vector and length of Index vector don't match.")
    writeLog(Message)
    stop(Message)
  }
  #Check that indices conform to table if indexed write
  if (any(Index > AllowedLength)) {
    Message <-
      paste0("One or more specified indicies for writing data to ", Table,
             " exceed ", AllowedLength)
    writeLog(Message)
    stop(Message)
  }
  #Write the dataset
  Data_[is.na(Data_)] <- Spec_ls$NAVALUE
  DatasetName <- file.path(Year, Table, Name)
  if (is.null(Index)) {
    h5write(Data_, file = E$DatastoreName, name = DatasetName)
  } else {
    h5write(Data_, file = E$DatastoreName, name = DatasetName, index = list(Index))
  }
  #Update datastore inventory
  listDatastore()
  TRUE
}


#WRITE A FUNCTION TO READ AN ITEM FROM A DATASTORE TABLE
#=======================================================
#' Read from table.
#'
#' \code{readFromTable} reads a dataset from a table.
#'
#' This function reads datasets from a table. Indexed reads are permitted. The
#' function checks whether the table and dataset exist and whether all specified
#' indices are within the length of the table. The function converts any values
#' equal to the NAVALUE attribute to NA.
#'
#' @param Name A string identifying the name of the dataset to be read from.
#' @param Table A string identifying the complete name of the table where the
#'   dataset is located.
#' @param Year a string representation of the model run year.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to. NULL if the entire dataset is to be read.
#' @return A vector of the same type stored in the datastore and specified in
#'   the TYPE attribute.
#' @export
readFromTable <- function(Name, Table, Year, Index = NULL) {
  #Check that dataset exists to read from
  DatasetCheck <- checkDataset(Name, Table, Year, E$Datastore, ThrowError = TRUE)
  DatasetName <- DatasetCheck[[2]]
  #If there is an Index, check that it is in bounds
  if (!is.null(Index)) {
    TableAttr_ <-
      unlist(E$Datastore$attributes[E$Datastore$groupname == file.path(Year, Table)])
    AllowedLength <- TableAttr_["LENGTH"]
    if (any(Index > AllowedLength)) {
      Message <-
        paste0(
          "One or more specified indicies for reading data from ",
          Table, " exceed ", AllowedLength
        )
      writeLog(Message)
      stop(Message)
    }
  }
  #Read data
  if (is.null(Index)) {
    Data_ <- h5read(E$DatastoreName, DatasetName, read.attributes = TRUE)
  } else {
    Data_ <-
      h5read(E$DatastoreName, DatasetName, index = list(Index), read.attributes = TRUE)
  }
  #Convert NA values
  NAValue <- as.vector(attributes(Data_)$NAVALUE)
  Data_[Data_ == NAValue] <- NA
  #Report out results
  Message <- paste0("Read data ", DatasetName)
  writeLog(Message)
  as.vector(Data_)
}

