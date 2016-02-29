#======
#hdf5.R
#======

#Functions for interacting with an HDF5 datastore, including listing contents,
#initializing tables and datasets, writing datasets, and reading datasets. All
#of the functions except for the createIndex function call functions in the
#rhdf5 package.


#LIST DATASTORE CONTENTS
#=======================
#' List datastore contents.
#'
#' \code{listDatastore} lists the contents of a datastore.
#'
#' This function lists the contents of a datastore including identifying all
#' groups, tables, and datasets. It also lists the attributes associated with
#' each table and dataset. The listing is stored in the global list as
#' 'G$Datastore'. This function is run whenever the structure or contents of the
#' datastore is changed to always keep the listing in G$Datastore current.
#'
#' @return TRUE if the listing is successfully read from the datastore and
#' written to the model state file.
#' @export
#' @import rhdf5
listDatastore <- function() {
  G <- getModelState()
  H5File <- H5Fopen(G$DatastoreName)
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
  AttrToWrite_ <- c("group", "name", "groupname", "attributes")
  setModelState(list(Datastore = DS_df[, AttrToWrite_]))
  TRUE
}


#INITIALIZE DATASTORE
#====================
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
#' @return TRUE if datastore initialization is successful. Calls the
#' listDatastore function which adds a listing of the datastore contents to the
#' model state file.
#' @export
#' @import rhdf5
initDatastore <- function() {
  G <- getModelState()
  #If data store exists, delete
  DatastoreName <- G$DatastoreName
  if (file.exists(DatastoreName)) {
    file.remove(DatastoreName)
  }
  #Create data store file
  H5File <- H5Fcreate(DatastoreName)
  #Create global group which stores data that is constant for all geography and
  #all years
  h5createGroup(H5File, "Global")
  #Create groups for years
  for (year in as.character(G$Years)) {
    YearGroup <- year
    h5createGroup(H5File, YearGroup)
  }
  H5Fclose(H5File)
  listDatastore()
  TRUE
}


#INITIALIZE TABLE IN DATASTORE
#=============================
#' Initialize table in datastore.
#'
#' \code{initDatastoreTable} initializes a table in the datastore.
#'
#' A table in the datastore is a group which contains equal length vectors of
#' data that may have different types. Thus it is much like an R data frame
#' which is a list containing equal length vectors that may have different
#' types. A table is initialized in the datastore by initializing a group whose
#' name is the table name and assigning a 'LENGTH' attribute which specifies the
#' length that all data vectors in the table must have.
#'
#' @param Spec_ls a list containing the standard module 'Set' specifications
#'   described in the model system design documentation.
#' @param Year a string representation of the model run year.
#' @return The value TRUE is returned if the function is successful at creating
#'   the table. In addition, the listDatastore function is run to update the
#'   inventory in the model state file. The function stops if the group in which
#'   the table is to be placed does not exist in the datastore and a message is
#'   written to the log.
#' @export
#' @import rhdf5
initTable <- function(Spec_ls, Year) {
  G <- getModelState()
  Year <- checkYear(Year, G$Datastore)
  if (!is.null(Spec_ls$LENGTH)) {
    Length <- Spec_ls$LENGTH
  } else {
    Message <- paste0("LENGTH specification for table (", Spec_ls$TABLE,
                      ") is not present.")
    writeLog(Message)
    stop(Message)
  }
  NewGroup <- paste(Year, Spec_ls$TABLE, sep = "/")
  H5File <- H5Fopen(G$DatastoreName)
  h5createGroup(H5File, NewGroup)
  H5Group <- H5Gopen(H5File, NewGroup)
  h5writeAttribute(Length, H5Group, "LENGTH")
  H5Gclose(H5Group)
  H5Fclose(H5File)
  listDatastore()
  TRUE
}


#INITIALIZE A DATASET IN A TABLE
#===============================
#' Initialize dataset in datastore table.
#'
#' \code{initDataset} initializes a dataset in a table.
#'
#' This function initializes a dataset which must be done before data can be
#' stored. Initialization establishes a name for the dataset and key attributes
#' associated with the data. Function calls initTable if the table the
#' dataset is to be placed in has not been initialized.
#'
#' @param Spec_ls a list containing the standard module 'Set' specifications
#'   described in the model system design documentation.
#' @param Year a string representation of the model run year.
#' @return TRUE if dataset is successfully initialized. If the dataset already
#' exists the function throws an error and writes an error message to the log.
#' Updates the model state file.
#' @export
#' @import rhdf5
initDataset <- function(Spec_ls, Year) {
  G <- getModelState()
  Table <- paste(Year, Spec_ls$TABLE, sep = "/")
  Name <- Spec_ls$NAME
  DatasetName <- paste(Table, Name, sep = "/")
  #Initialize table if it does not exist
  if (!(Table %in% G$Datastore$groupname)) {
    Message <-
      paste("Table", Table, "has not been created in the datastore.",
            "Attempting to create.")
    writeLog(Message)
    initTable(Spec_ls, Year)
    G <- getModelState()
  }
  #Check if the dataset already exists
  DatasetExists <- DatasetName %in% G$Datastore$groupname
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
  } else {
    Message <- paste0("SIZE specification for dataset (", Name,
                      ") is not present.")
    writeLog(Message)
    stop(Message)
  }
  #Create the dataset
  Length <- unlist(h5readAttributes(G$DatastoreName, Table))["LENGTH"]
  Chunck <- ifelse(Length > 1000, 100, 1)
  H5File <- H5Fopen(G$DatastoreName)
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
  TRUE
}


#WRITE TO TABLE
#==============
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
#' @param Data_ A vector of data to be written.
#' @param Spec_ls a list containing the standard module 'Set' specifications
#'   described in the model system design documentation.
#' @param Year a string representation of the model run year.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to.
#' @return TRUE if data is sucessfully written. Updates model state file.
#' @export
#' @import rhdf5
writeToTable <- function(Data_, Spec_ls, Year, Index = NULL) {
  G <- getModelState()
  Name <- Spec_ls$NAME
  Table <- Spec_ls$TABLE
  #Check that table exists to write to and attempt to create if not
  TableCheck <- checkTable(Table, Year, G$Datastore, ThrowError = FALSE)
  if (!TableCheck[[1]]) {
    Message <-
      paste("Table", Table, "has not been created in the datastore.",
            "Attempting to create.")
    writeLog(Message)
    initTable(Spec_ls, Year)
    G <- getModelState()
  }
  #Check that dataset exists to write to and attempt to create if not
  DatasetCheck <- checkDataset(Name, Table, Year, G$Datastore, ThrowError = FALSE)
  if (!DatasetCheck[[1]]) {
    Message <-
      paste("Dataset", Name, "has not been initialized in the datastore.",
            "Attempting to initialize.")
    writeLog(Message)
    initDataset(Spec_ls, Year)
    G <- getModelState()
  }
  #Check that data is a vector
  if (!is.vector(Data_)) {
    Message <-
      paste0("Data ", Name, " does not conform to ", Table, ". Must be a vector.")
    writeLog(Message)
    stop(Message)
  }
  #Check whether the data is consistent with datastore attributes
  DstoreAttr_ls <- getDatasetAttr(Name, Table, Year, G$Datastore)
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
    unlist(G$Datastore$attributes[G$Datastore$groupname == file.path(Year, Table)])
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
    h5write(Data_, file = G$DatastoreName, name = DatasetName)
  } else {
    h5write(Data_, file = G$DatastoreName, name = DatasetName, index = list(Index))
  }
  #Update datastore inventory
  listDatastore()
  TRUE
}


#READ FROM TABLE
#===============
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
#' @import rhdf5
readFromTable <- function(Name, Table, Year, Index = NULL) {
  G <- getModelState()
  #Check that dataset exists to read from
  DatasetCheck <- checkDataset(Name, Table, Year, G$Datastore, ThrowError = TRUE)
  DatasetName <- DatasetCheck[[2]]
  #If there is an Index, check that it is in bounds
  if (!is.null(Index)) {
    TableAttr_ <-
      unlist(G$Datastore$attributes[G$Datastore$groupname == file.path(Year, Table)])
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
    Data_ <- h5read(G$DatastoreName, DatasetName, read.attributes = TRUE)
  } else {
    Data_ <-
      h5read(G$DatastoreName, DatasetName, index = list(Index), read.attributes = TRUE)
  }
  #Convert NA values
  NAValue <- as.vector(attributes(Data_)$NAVALUE)
  Data_[Data_ == NAValue] <- NA
  #Report out results
  Message <- paste0("Read data ", DatasetName)
  writeLog(Message)
  as.vector(Data_)
}


#CREATE A DATASTORE INDEX
#========================
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
#' @param Name A string identifying the dataset the index is being created
#'   for.
#' @param Table A string identifying the name of the table the index is
#'   being created for.
#' @param Year A string identifying the year group the table is located in.
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
