#===========
#datastore.R
#===========

#Functions for interacting with the datastore. There are 6 core functions which
#enable interaction with alternative datastore structures: initDatastore,
#initTable, initDataset, readFromTable, writeToTable, listDatastore. At present,
#two alternatives are supported: an HDF5 file datastore and a datastore that
#uses R data files. The names of these key functions has appended a suffix
#corresponding to the datastore type which is declared in the model run
#parameters. The initializeModel then make the appropriate assignments to the
#the basic function names depending on the declared datastore type. In addition
#to these core functions which depend on the datastore, there are several
#functions which call the core functions to move data to and from the datastore
#in order to run modules.


###############################################################################
#                                                                             #
#              IMPLEMENTATION OF DATASTORE USING RDATA FILES                  #
#                                                                             #
###############################################################################

#LIST DATASTORE CONTENTS
#=======================
#' List datastore contents for an RData (RD) type datastore.
#'
#' \code{listDatastoreRD} a visioneval framework datastore connection function
#' that lists the contents of an RData (RD) type datastore.
#'
#' This function lists the contents of a datastore for an RData (RD) type
#' datastore.
#'
#' @param DataListing_ls a list containing named elements describing a new data
#' item being added to the datastore listing and the model state file. The list
#' components are:
#' group - the name of the group (path) the item is being added to;
#' name - the name of the data item (directory or dataset);
#' groupname - the full path to the data item;
#' attributes - a list containing the named attributes of the data item.
#' @return TRUE if the listing is successfully read from the datastore and
#' written to the model state file.
#' @export
listDatastoreRD <- function(DataListing_ls = NULL) {
  #Load the model state file
  if (exists("ModelState_ls")) {
    G <- getModelState()
  } else {
    G <- readModelState()
  }
  #If no Datastore component, get from DatastoreListing.Rda
  if (is.null(G$Datastore)) {
    load(file.path(G$DatastoreName, "DatastoreListing.Rda"))
    Datastore_df <- data.frame(
      group = DatastoreListing_ls$group,
      name = DatastoreListing_ls$name,
      groupname = DatastoreListing_ls$groupname,
      stringsAsFactors = FALSE
    )
    Datastore_df$attributes <- DatastoreListing_ls$attributes
  } else {
    Datastore_df <- G$Datastore
  }
  #Update the datastore listing
  if (!is.null(DataListing_ls)) {
    NewDatastore_df <-
      rbind(
        Datastore_df[,c("group", "name", "groupname")],
        DataListing_ls[c("group", "name", "groupname")])
    NewDatastore_df$attributes <-
      c(Datastore_df$attributes, list(DataListing_ls$attributes))
  } else {
    NewDatastore_df <- Datastore_df
  }
  #Update model state and datastore listing
  setModelState(list(Datastore = NewDatastore_df))
  DatastoreListing_ls <- as.list(NewDatastore_df)
  save(DatastoreListing_ls, file = file.path(G$DatastoreName, "DatastoreListing.Rda"))
  TRUE
}


#INITIALIZE DATASTORE
#====================
#' Initialize Datastore for an RData (RD) type datastore.
#'
#' \code{initDatastoreRD} a visioneval framework datastore connection function
#' that creates a datastore with starting structure for an RData (RD) type
#' datastore.
#'
#' This function creates the datastore for the model run with the initial
#' structure for an RData (RD) type datastore.
#'
#' @return TRUE if datastore initialization is successful. Calls the
#' listDatastore function which adds a listing of the datastore contents to the
#' model state file.
#' @export
#' @import filesstrings stats utils
initDatastoreRD <- function() {
  G <- getModelState()
  DatastoreName <- G$DatastoreName
  #If datastore exists, delete
  if (file.exists(DatastoreName)) {
    dir.remove(DatastoreName)
  }
  #Create datastore
  dir.create(DatastoreName)
  #Initialize the DatastoreListing
  Datastore_df <-
     data.frame(
      group = "/",
      name = "",
      groupname = "",
      attributes = NA,
      stringsAsFactors = FALSE)
  Datastore_df$attributes <- as.list(Datastore_df$attributes)
  setModelState(list(Datastore = Datastore_df))
  #Create global group which stores data that is constant for all geography and
  #all years
  dir.create(file.path(DatastoreName, "Global"))
  listDatastoreRD(
    list(group = "/", name = "Global", groupname = "Global",
         attributes = list(NA))
  )
  #Create groups for years
  Years <- getYears()
  for (year in Years) {
    YearGroup <- year
    dir.create(file.path(DatastoreName, YearGroup))
    listDatastoreRD(
      list(group = "/", name = YearGroup, groupname = YearGroup,
           attributes = list(NA))
    )
  }
  #Return TRUE if successful
  TRUE
}
#initDatastoreRD()


#INITIALIZE TABLE IN DATASTORE
#=============================
#' Initialize table in an RData (RD) type datastore.
#'
#' \code{initTableRD} a visioneval framework datastore connection function
#' initializes a table in an RData (RD) type datastore.
#'
#' This function initializes a table in an RData (RD) type datastore.
#'
#' @param Table a string identifying the name of the table to initialize.
#' @param Group a string representation of the name of the top-level
#' subdirectory the table is to be created in (i.e. either 'Global' or the name
#' of the year).
#' @param Length a number identifying the table length.
#' @return The value TRUE is returned if the function is successful at creating
#'   the table. In addition, the listDatastore function is run to update the
#'   inventory in the model state file. The function stops if the group in which
#'   the table is to be placed does not exist in the datastore and a message is
#'   written to the log.
#' @export
initTableRD <- function(Table, Group, Length) {
  G <- getModelState()
  DatastoreName <- G$DatastoreName
  #Create a directory for the table
  dir.create(file.path(DatastoreName, Group, Table))
  #Update the datastore listing and model state
  listDatastoreRD(
    list(group = paste0("/", Group), name = Table,
         groupname = paste(Group, Table, sep = "/"),
         attributes = list(LENGTH = Length)
    )
  )
  #Return true is successful
  TRUE
}
#initTableRD("Azone", "2010", 3)


#INITIALIZE A DATASET IN A TABLE
#===============================
#' Initialize dataset in an RData (RD) type datastore table.
#'
#' \code{initDatasetRD} a visioneval framework datastore connection function
#' initializes a dataset in an RData (RD) type datastore table.
#'
#' This function initializes a dataset in an RData (RD) type datastore table.
#'
#' @param Spec_ls a list containing the standard module specifications
#'   described in the model system design documentation.
#' @param Group a string representation of the name of the top-level
#' subdirectory the table is to be created in (i.e. either 'Global' or the name
#' of the year).
#' @return TRUE if dataset is successfully initialized. If the identified table
#' does not exist, the function throws an error.
#' @export
initDatasetRD <- function(Spec_ls, Group) {
  G <- getModelState()
  Table <- paste(Group, Spec_ls$TABLE, sep = "/")
  Name <- Spec_ls$NAME
  DatasetName <- paste(Table, Name, sep = "/")
  #Check whether the table exists and throw error if it does not
  TableExists <- Table %in% G$Datastore$groupname
  if (!TableExists) {
    Msg <- paste0("Specified table - ", Table, " - doesn't exist. ",
                  "The table must be initialized before the dataset can ",
                  "be initialized.")
    writeLog(Msg)
    stop(Msg)
  }
  #Get the table length
  Length <- G$Datastore$attributes[G$Datastore$groupname == Table][[1]]$LENGTH
  #Create an initialized dataset
  Dataset <-
    switch(Types()[[Spec_ls$TYPE]]$mode,
           character = character(Length),
           double = numeric(Length),
           integer = integer(Length),
           logical = logical(Length))
  attributes(Dataset) <- Spec_ls
  #Save the initialized dataset
  DatasetName <- paste(Spec_ls$NAME, "Rda", sep = ".")
  save(Dataset, file = file.path(G$DatastoreName, Table, DatasetName))
  #Update the datastore listing and model state
  listDatastoreRD(
    list(group = paste0("/", Table), name = Spec_ls$NAME,
         groupname = paste(Table, Spec_ls$NAME, sep = "/"),
         attributes = Spec_ls
    )
  )
  #Return TRUE if successful
  TRUE
}
#source("data/test_spec.R")
#initDatasetRD(TestSpec_ls, "2010")


#READ FROM TABLE
#===============
#' Read from an RData (RD) type datastore table.
#'
#' \code{readFromTableRD} a visioneval framework datastore connection function
#' that reads a dataset from an RData (RD) type datastore table.
#'
#' This function reads a dataset from an RData (RD) type datastore table.
#'
#' @param Name A string identifying the name of the dataset to be read from.
#' @param Table A string identifying the complete name of the table where the
#'   dataset is located.
#' @param Group a string representation of the name of the datastore group the
#' data is to be read from.
#' @param DstoreLoc a string representation of the file path of the datastore.
#' NULL if the datastore is the current directory.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to. NULL if the entire dataset is to be read.
#' @return A vector of the same type stored in the datastore and specified in
#'   the TYPE attribute.
#' @export
readFromTableRD <- function(Name, Table, Group, DstoreLoc = NULL, Index = NULL) {
  #Get the directory where the datastore is located from DstoreLoc
  if (is.null(DstoreLoc)) {
    DstoreDir <- ""
  } else {
    ParseDstoreLoc_ <- unlist(strsplit(DstoreLoc, "/"))
    DstoreDir <- paste(ParseDstoreLoc_[-length(ParseDstoreLoc_)], collapse = "/")
  }
  #Load the model state file
  if (DstoreDir == "") {
    G <- getModelState()
  } else {
    G <- readModelState(FileName = file.path(DstoreDir, "ModelState.Rda"))
  }
  #If DstoreLoc is NULL get the name of the datastore from the model state
  if (is.null(DstoreLoc)) DstoreLoc <- G$DatastoreName
  #Check that dataset exists to read from and if so get path to dataset
  DatasetExists <- checkDataset(Name, Table, Group, G$Datastore)
  if (DatasetExists) {
    FileName <- paste(Name, "Rda", sep = ".")
    DatasetPath <- file.path(DstoreLoc, Group, Table, FileName)
  } else {
    Message <-
      paste("Dataset", Name, "in table", Table, "in group", Group, "doesn't exist.")
    stop(Message)
  }
  #Load the dataset
  load(DatasetPath)
  #Save the attributes
  Attr_ls <- attributes(Dataset)
  #Convert NA values
  # NAValue <- as.vector(attributes(Dataset)$NAVALUE)
  # Dataset[Dataset == NAValue] <- NA
  #If there is an Index, check, and use to subset the dataset
  if (!is.null(Index)) {
    TableAttr_ <-
      unlist(G$Datastore$attributes[G$Datastore$groupname == file.path(Group, Table)])
    AllowedLength <- TableAttr_["LENGTH"]
    if (any(Index > AllowedLength)) {
      Message <-
        paste0(
          "One or more specified indicies for reading data from ",
          Table, " exceed ", AllowedLength
        )
      writeLog(Message)
      stop(Message)
    } else {
      Dataset <- Dataset[Index]
    }
  }
  #Return results
  attributes(Dataset) <- NULL
  Dataset
}
#readFromTableRD("Azone", "Azone", "2010")
#readFromTableRD("Azone", "Azone", "2010", Index = 1:2)


#WRITE TO TABLE
#==============
#' Write to an RData (RD) type datastore table.
#'
#' \code{writeToTableRD} a visioneval framework datastore connection function
#' that writes data to an RData (RD) type datastore table and initializes
#' dataset if needed.
#'
#' This function writes a dataset file to an RData (RD) type datastore table. It
#' initializes the dataset if the dataset does not exist. Enables data to be
#' written to specific location indexes in the dataset.
#'
#' @param Data_ A vector of data to be written.
#' @param Spec_ls a list containing the standard module 'Set' specifications
#'   described in the model system design documentation.
#' @param Group a string representation of the name of the datastore group the
#' data is to be written to.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to.
#' @return TRUE if data is sucessfully written.
#' @export
writeToTableRD <- function(Data_, Spec_ls, Group, Index = NULL) {
  G <- getModelState()
  Name <- Spec_ls$NAME
  Table <- Spec_ls$TABLE
  #Check that dataset exists to write to and attempt to create if not
  DatasetExists <- checkDataset(Name, Table, Group, G$Datastore)
  if (!DatasetExists) {
    GroupName <- paste(Group, Spec_ls$TABLE, sep = "/")
    Length <-
      G$Datastore$attributes[G$Datastore$groupname == GroupName][[1]]$LENGTH
    Dataset <-
      switch(Types()[[Spec_ls$TYPE]]$mode,
             character = character(Length),
             double = numeric(Length),
             integer = integer(Length),
             logical = logical(Length))
    Attr_ls <- Spec_ls
    listDatastoreRD(
      list(group = paste0("/", GroupName), name = Name,
           groupname = paste(GroupName, Name, sep = "/"),
           attributes = Spec_ls
      )
    )
  } else {
    Dataset <- readFromTableRD(Name, Table, Group)
    Attr_ls <- attributes(Dataset)
  }
  #Modify the loaded dataset
  if (is.null(Index)) {
    Dataset <- Data_
  } else {
    if (any(Index > length(Dataset))) {
      Message <-
        paste0(
          "One or more specified indicies for reading data from ",
          file.path(Group, Table, Name), " exceed the length of the dataset."
        )
      writeLog(Message)
      stop(Message)
    } else {
      Dataset[Index] <- Data_
    }
  }
  #Save the dataset
  attributes(Dataset) <- Attr_ls
  DatasetName <- paste0(Name, ".Rda")
  save(Dataset, file = file.path(G$DatastoreName, Group, Table, DatasetName))
  TRUE
}

#readFromTableRD("Azone", "Azone", "2010")
#NewVals_ <- paste0("A", 1:3)
#writeToTableRD(NewVals_, TestSpec_ls, "2010", Index = NULL)
#readFromTableRD("Azone", "Azone", "2010")
#Write an uninitialized dataset
#initTableRD("Bzone", "2010", 10)
#TestSpec_ls$NAME <- "Bzone"
#TestSpec_ls$TABLE <- "Bzone"
#NewVals_ <- paste0("B", 1:10)
#writeToTableRD(NewVals_, TestSpec_ls, "2010")
#readFromTableRD("Bzone", "Bzone", "2010")
#TestSpec_ls$NAME <- "Azone"
#NewVals_ <- c("A1", "A1", "A1", "A1", "A2", "A2", "A2", "A3", "A3", "A3")
#writeToTableRD(NewVals_, TestSpec_ls, "2010")
#readFromTableRD("Azone", "Bzone", "2010")


###############################################################################
#                                                                             #
#              IMPLEMENTATION OF DATASTORE USING HDF5 FILES                   #
#                                                                             #
###############################################################################

#LIST DATASTORE CONTENTS
#=======================
#' List datastore contents for an HDF5 (H5) type datastore.
#'
#' \code{listDatastoreH5} a visioneval framework datastore connection function
#' that lists the contents of an HDF5 (H5) type datastore.
#'
#' This function lists the contents of a datastore for an HDF5 (H5) type
#' datastore.
#'
#' @return TRUE if the listing is successfully read from the datastore and
#' written to the model state file.
#' @export
#' @import rhdf5
listDatastoreH5 <- function() {
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
#' Initialize Datastore for an HDF5 (H5) type datastore.
#'
#' \code{initDatastoreH5} a visioneval framework datastore connection function
#' that creates datastore with starting structure for an HDF5 (H5) type
#' datastore.
#'
#' This function creates the datastore for the model run with the initial
#' structure for an HDF5 (H5) type datastore.
#'
#' @return TRUE if datastore initialization is successful. Calls the
#' listDatastore function which adds a listing of the datastore contents to the
#' model state file.
#' @export
#' @import rhdf5
initDatastoreH5 <- function() {
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
  listDatastoreH5()
  TRUE
}


#INITIALIZE TABLE IN DATASTORE
#=============================
#' Initialize table in an HDF5 (H5) type datastore.
#'
#' \code{initTableH5} a visioneval framework datastore connection function that
#' initializes a table in an HDF5 (H5) type datastore.
#'
#' This function initializes a table in an HDF5 (H5) type datastore.
#'
#' @param Table a string identifying the name of the table to initialize.
#' @param Group a string representation of the name of the group the table is to
#' be created in.
#' @param Length a number identifying the table length.
#' @return The value TRUE is returned if the function is successful at creating
#'   the table. In addition, the listDatastore function is run to update the
#'   inventory in the model state file. The function stops if the group in which
#'   the table is to be placed does not exist in the datastore and a message is
#'   written to the log.
#' @export
#' @import rhdf5
initTableH5 <- function(Table, Group, Length) {
  G <- getModelState()
  NewTable <- paste(Group, Table, sep = "/")
  H5File <- H5Fopen(G$DatastoreName)
  h5createGroup(H5File, NewTable)
  H5Group <- H5Gopen(H5File, NewTable)
  h5writeAttribute(Length, H5Group, "LENGTH")
  H5Gclose(H5Group)
  H5Fclose(H5File)
  listDatastoreH5()
  TRUE
}


#INITIALIZE A DATASET IN A TABLE
#===============================
#' Initialize dataset in an HDF5 (H5) type datastore table.
#'
#' \code{initDatasetH5} a visioneval framework datastore connection function
#' that initializes a dataset in an HDF5 (H5) type datastore table.
#'
#' This function initializes a dataset in an HDF5 (H5) type datastore table.
#'
#' @param Spec_ls a list containing the standard module 'Set' specifications
#'   described in the model system design documentation.
#' @param Group a string representation of the name of the group the table is to
#' be created in.
#' @return TRUE if dataset is successfully initialized. If the dataset already
#' exists the function throws an error and writes an error message to the log.
#' Updates the model state file.
#' @export
#' @import rhdf5
initDatasetH5 <- function(Spec_ls, Group) {
  G <- getModelState()
  Table <- paste(Group, Spec_ls$TABLE, sep = "/")
  Name <- Spec_ls$NAME
  DatasetName <- paste(Table, Name, sep = "/")
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
  Chunk <- ifelse(Length > 1000, 100, 1)
  StorageMode <- Types()[[Spec_ls$TYPE]]$mode
  H5File <- H5Fopen(G$DatastoreName)
  h5createDataset(
    H5File, DatasetName, dims = Length,
    storage.mode = StorageMode, size = Size + 1,
    chunk = Chunk, level = 7
  )
  H5Data <- H5Dopen(H5File, DatasetName)
  h5writeAttribute(Spec_ls$MODULE, H5Data, "MODULE")
  h5writeAttribute(Spec_ls$NAVALUE, H5Data, "NAVALUE")
  h5writeAttribute(Spec_ls$UNITS, H5Data, "UNITS")
  h5writeAttribute(Size, H5Data, "SIZE")
  h5writeAttribute(Spec_ls$TYPE, H5Data, "TYPE")
  if (!is.null(Spec_ls$PROHIBIT)) {
    h5writeAttribute(Spec_ls$PROHIBIT, H5Data, "PROHIBIT")
  }
  if (!is.null(Spec_ls$ISELEMENTOF)) {
    h5writeAttribute(Spec_ls$ISELEMENTOF, H5Data, "ISELEMENTOF")
  }
  if (!is.null(Spec_ls$DESCRIPTION)) {
    h5writeAttribute(Spec_ls$DESCRIPTION, H5Data, "DESCRIPTION")
  }
  H5Dclose(H5Data)
  H5Fclose(H5File)
  #Update datastore inventory
  listDatastoreH5()
  TRUE
}


#READ FROM TABLE
#===============
#' Read from an HDF5 (H5) type datastore table.
#'
#' \code{readFromTableH5} a visioneval framework datastore connection function
#' that reads a dataset from an HDF5 (H5) type datastore table.
#'
#' This function reads a dataset from an HDF5 (H5) type datastore table.
#'
#' @param Name A string identifying the name of the dataset to be read from.
#' @param Table A string identifying the complete name of the table where the
#'   dataset is located.
#' @param Group a string representation of the name of the datastore group the
#' data is to be read from.
#' @param File a string representation of the file path of the datastore
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to. NULL if the entire dataset is to be read.
#' @return A vector of the same type stored in the datastore and specified in
#'   the TYPE attribute.
#' @export
#' @import rhdf5
readFromTableH5 <- function(Name, Table, Group, File = NULL, Index = NULL) {
  #Get the directory where the datastore is located from File
  if (is.null(File)) {
    DstoreDir <- ""
  } else {
    ParseDstoreLoc_ <- unlist(strsplit(File, "/"))
    DstoreDir <- paste(ParseDstoreLoc_[-length(ParseDstoreLoc_)], collapse = "/")
  }
  #Load the model state file
  if (DstoreDir == "") {
    G <- getModelState()
  } else {
    G <- readModelState(FileName = file.path(DstoreDir, "ModelState.Rda"))
  }
  #If File is NULL get the name of the datastore from the model state
  if (is.null(File)) File <- G$DatastoreName
  #Check that dataset exists to read from
  DatasetExists <- checkDataset(Name, Table, Group, G$Datastore)
  if (DatasetExists) {
    DatasetName <- file.path(Group, Table, Name)
  } else {
    Message <-
      paste("Dataset", Name, "in table", Table, "in group", Group, "doesn't exist.")
    stop(Message)
  }
  #If there is an Index, check that it is in bounds
  if (!is.null(Index)) {
    TableAttr_ <-
      unlist(G$Datastore$attributes[G$Datastore$groupname == file.path(Group, Table)])
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
    Data_ <- h5read(File, DatasetName, read.attributes = TRUE)
  } else {
    Data_ <-
      h5read(File, DatasetName, index = list(Index), read.attributes = TRUE)
  }
  #Convert NA values
  NAValue <- as.vector(attributes(Data_)$NAVALUE)
  Data_[Data_ == NAValue] <- NA
  #Return results
  as.vector(Data_)
}


#WRITE TO TABLE
#==============
#' Write to an RData (RD) type datastore table.
#'
#' \code{writeToTableRD} a visioneval framework datastore connection function
#' that writes data to an RData (RD) type datastore table and initializes
#' dataset if needed.
#'
#' This function writes a dataset file to an RData (RD) type datastore table. It
#' initializes the dataset if the dataset does not exist. Enables data to be
#' written to specific location indexes in the dataset.
#'
#' @param Data_ A vector of data to be written.
#' @param Spec_ls a list containing the standard module 'Set' specifications
#'   described in the model system design documentation.
#' @param Group a string representation of the name of the datastore group the
#' data is to be written to.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to.
#' @return TRUE if data is sucessfully written. Updates model state file.
#' @export
#' @import rhdf5
writeToTableH5 <- function(Data_, Spec_ls, Group, Index = NULL) {
  G <- getModelState()
  Name <- Spec_ls$NAME
  Table <- Spec_ls$TABLE
  #Check that dataset exists to write to and attempt to create if not
  DatasetExists <- checkDataset(Name, Table, Group, G$Datastore)
  if (!DatasetExists) {
    initDatasetH5(Spec_ls, Group)
    G <- getModelState()
  }
  #Write the dataset
  if (is.null(Data_)) {
    Message <-
      paste0(
        "writeToTable passed NULL Data_ "
      )
    writeLog(Message)
    stop(Message)
  }
  Data_[is.na(Data_)] <- Spec_ls$NAVALUE
  DatasetName <- file.path(Group, Table, Name)
  if (is.null(Index)) {
    h5write(Data_, file = G$DatastoreName, name = DatasetName)
  } else {
    h5write(Data_, file = G$DatastoreName, name = DatasetName, index = list(Index))
  }
  #Update datastore inventory
  listDatastoreH5()
  TRUE
}


###############################################################################
#                                                                             #
#                 COMMON DATASTORE INTERACTION FUNCTIONS                      #
#                                                                             #
###############################################################################

#ASSIGN DATASTORE INTERACTION FUNCTIONS
#======================================
#' Assign datastore interaction functions
#'
#' \code{assignDatastoreFunctions} a visioneval framework control function that
#' assigns the values of the functions for interacting with the datastore to the
#' functions for the declared datastore type.
#'
#' The visioneval framework can work with different types of datastores. For
#' example a datastore which stores datasets in an HDF5 file or a datastore
#' which stores datasets as RData files in a directory hierarchy. This function
#' reads the 'DatastoreType' parameter from the model state file and then
#' assigns the common datastore interaction functions the values of the
#' functions for the declared datastore type.
#'
#' @param DstoreType A string identifying the datastore type.
#' @return None. The function assigns datastore interactions functions to the
#' first position of the search path.
#' @export
assignDatastoreFunctions <- function(DstoreType) {
  AllowedDstoreTypes_ <- c("RD", "H5")
  DstoreFuncs_ <-
    c("initDatastore", "initTable", "initDataset", "readFromTable",
      "writeToTable", "listDatastore")
  if (DstoreType %in% AllowedDstoreTypes_) {
    for(DstoreFunc in DstoreFuncs_) {
      assign(DstoreFunc, get(paste0(DstoreFunc, DstoreType)), pos = 1)
    }
  } else {
    Msg <-
      paste0("Specified 'DatastoreType' in the 'run_parameters.json' file - ",
             DstoreType, " - is not a recognized type. ",
             "Recognized datastore types are: ",
             paste(AllowedDstoreTypes_, collapse = ", "), ".")
    stop(Msg)
  }
}


#CREATE A DATASTORE INDEX LIST
#=============================
#' Create a list of geographic indices for all tables in a datastore.
#'
#' \code{createGeoIndexList} a visioneval framework control function that
#' creates a list containing the geographic indices for tables in the operating
#' datastore for identified tables.
#'
#' This function takes a 'Get' or 'Set' specifications list for a module and the
#' 'RunBy' specification and returns a list which has a component for each table
#' identified in the specifications. Each component includes all geographic
#' datasets for the table.
#'
#' @param Specs_ls A 'Get' or 'Set' specifications list for a module.
#' @param RunBy The value of the RunBy specification for a module.
#' @param RunYear A string identifying the model year that is being run.
#' @return A list that contains a component for each table identified in the
#' specifications in which each component includes all the geographic datasets
#' for the table represented by the component.
#' @export
createGeoIndexList <-
  function(Specs_ls, RunBy, RunYear) {
    G <- getModelState()
    #Make data frame of all tables and groups
    TablesToIndex_df <-
      do.call(
        rbind,
        lapply(Specs_ls, function(x) {
          data.frame(Table = x$TABLE, Group = x$GROUP, stringsAsFactors = FALSE)
        })
      )
    #Replace Group name with appropriate year if necessary
    TablesToIndex_df$Group[TablesToIndex_df$Group == "Year"] <- RunYear
    TablesToIndex_df$Group[TablesToIndex_df$Group == "BaseYear"] <- G$BaseYear
    #Remove duplicates
    TablesToIndex_df <- unique(TablesToIndex_df)
    #Don't create and index for any global tables that are not geographic
    DoCreateIndex_ <-
      !(
        TablesToIndex_df$Group == "Global" &
          !(TablesToIndex_df$Table %in% c("Marea", "Azone", "Bzone", "Czone"))
        )
    TablesToIndex_df <- TablesToIndex_df[DoCreateIndex_,]
    #Turn data frame in list by group
    TablesToIndex_ls <- split(TablesToIndex_df$Table, TablesToIndex_df$Group)
    TablesToIndex_ls <- lapply(TablesToIndex_ls, function(x) {
      if (!(RunBy %in% x)) x <- c(RunBy, x)
      x
    })
    #Iterate through groups and tables and create indexes
    Index_ls <- list()
    for (nm in names(TablesToIndex_ls)) {
      Index_ls[[nm]] <- list()
      for(tab in TablesToIndex_ls[[nm]]) {
        Index_ls[[nm]][[tab]] <- list()
        if (tab == "Marea") {
          Index_ls[[nm]]$Marea$Marea <- readFromTable("Marea", "Marea", nm)
        } else {
          Index_ls[[nm]][[tab]]$Marea <- readFromTable("Marea", tab, nm)
          Index_ls[[nm]][[tab]]$Azone <- readFromTable("Azone", tab, nm)
        }
      }
    }
    Index_ls
  }


#CREATE A DATASTORE INDEX
#========================
#' Create datastore index.
#'
#' \code{createIndex} a visioneval framework control function that creates an
#' index for reading or writing module data to the datastore.
#'
#' This function creates indexing functions which return an index to positions
#' in datasets that correspond to positions in an index field of a table. For
#' example if the index field is 'Azone' in the 'Household' table, this function
#' will return a function that when provided the name of a particular Azone,
#' will return the positions corresponding to that Azone.
#'
#' @param Table A string identifying the name of the table the index is being
#'   created for.
#' @param Group A string identifying the name of the group where the table is
#' located in the datastore.
#' @param RunBy A string identifying the level of geography the module is being
#'   run at (e.g. Azone).
#' @param Geo A string identifying the geographic unit to create the index for
#'   (e.g. the name of a particular Azone).
#' @param GeoIndex_ls a list of geographic indices used to determine the
#'   positions to extract from a dataset corresponding to the specified
#'   geography.
#' @return A function that creates a vector of positions corresponding to the
#'   location of the supplied value in the index field.
#' @export
createGeoIndex <- function(Table, Group, RunBy, Geo, GeoIndex_ls) {
  if (Table == "Marea") {
    #Identify the Marea from the 'RunBy' table
    GeoIdxNames_ <- GeoIndex_ls[[Group]][[RunBy]][[RunBy]]
    Marea <-
      GeoIndex_ls[[Group]][[RunBy]]$Marea[GeoIdxNames_ == Geo]
    GeoIdxNames_ <- GeoIndex_ls[[Group]]$Marea$Marea
    Idx_ <- which(GeoIdxNames_ == Marea)
  } else {
    #Get the index from the table
    GeoIdxNames_ <- GeoIndex_ls[[Group]][[Table]][[RunBy]]
    Idx_ <- which(GeoIdxNames_ == Geo)
  }
  Idx_
}


#GET DATA SETS IDENTIFIED IN MODULE SPECIFICATIONS FROM DATASTORE
#================================================================
#' Retrieve data identified in 'Get' specifications from datastore
#'
#' \code{getFromDatastore} a visioneval framework control function that
#' retrieves datasets identified in a module's 'Get' specifications from the
#' datastore.
#'
#' This function retrieves from the datastore all of the data sets identified in
#' a module's 'Get' specifications. If the module's specifications include the
#' name of a geographic area, then the function will retrieve the data for that
#' geographic area.
#'
#' @param ModuleSpec_ls a list of module specifications that is consistent with
#' the VisionEval requirements
#' @param RunYear a string identifying the model year being run. The default is
#' the Year object in the global workspace.
#' @param Geo a string identifying the name of the geographic area to get the
#' data for. For example, if the module is specified to be run by Azone, then
#' Geo would be the name of a particular Azone.
#' @param GeoIndex_ls a list of geographic indices used to determine the
#' positions to extract from a dataset corresponding to the specified geography.
#' @return A list containing all the data sets specified in the module's
#' 'Get' specifications for the identified geographic area.
#' @export
getFromDatastore <- function(ModuleSpec_ls, RunYear, Geo = NULL, GeoIndex_ls = NULL) {
  GetSpec_ls <- ModuleSpec_ls$Get
  #Make a list to hold the retrieved data
  L <- initDataList()
  #Add the model state and year to the list
  G <- getModelState()
  G$Year <- RunYear
  L$G <- G
  #Get data specified in list
  for (i in 1:length(GetSpec_ls)) {
    Spec_ls <- GetSpec_ls[[i]]
    Group <- Spec_ls$GROUP
    Table <- Spec_ls$TABLE
    Name <- Spec_ls$NAME
    Type <- Spec_ls$TYPE
    #Identify datastore files and groups to get data from
    if (Group == "Global") {
      DstoreGroup <- "Global"
      if (!is.null(G$DatastoreReferences$Global)) {
        Files_ <- c(G$DatastoreName, G$DatastoreReferences$Global)
      } else {
        Files_ <- G$DatastoreName
      }
    }
    if (Group == "BaseYear") {
      DstoreGroup <- G$BaseYear
      if (G$BaseYear %in% G$Years) {
        Files_ <- G$DatastoreName
      } else {
        Files_ <- G$DatastoreReferences[[G$BaseYear]]
      }
    }
    if (Group == "Year") {
      DstoreGroup <- RunYear
      if (!is.null(G$DatastoreReferences[[RunYear]])) {
        Files_ <- c(G$DatastoreName, G$DatastoreReferences[[RunYear]])
      } else {
        Files_ <- G$DatastoreName
      }
    }
    #Add table component to list if does not exist
    if (is.null(L[[Group]][[Table]])) {
      L[[Group]][[Table]] <- list()
      # attributes(L[[Group]][[Table]]) <-
      #   list(LENGTH = getTableLength(Table, DstoreGroup, G$Datastore))
    }
    #Make an index to the data
    DoCreateIndex <-
      !is.null(Geo) &
      !(Group == "Global" & !(Table %in% c("Marea", "Azone", "Bzone", "Czone")))
    if (DoCreateIndex) {
      Index <-
        createGeoIndex(Table, DstoreGroup, ModuleSpec_ls$RunBy, Geo, GeoIndex_ls)
    } else {
      Index <- NULL
    }
    #Fetch the data and add to the input list
    getModelListing <- function(DstoreRef) {
      SplitRef_ <- unlist(strsplit(DstoreRef, "/"))
      RefHead <- paste(SplitRef_[-length(SplitRef_)], collapse = "/")
      if (RefHead == "") {
        ModelStateFile <- "ModelState.Rda"
      } else {
        ModelStateFile <- paste(RefHead, "ModelState.Rda", sep = "/")
      }
      readModelState(FileName = ModelStateFile)
    }
    for (File in Files_) {
      DstoreListing_ls <- getModelListing(DstoreRef = File)$Datastore
      DatasetExists <- checkDataset(Name, Table, DstoreGroup, DstoreListing_ls)
      if (DatasetExists) {
        Data_ <- readFromTable(Name, Table, DstoreGroup, File, Index)
        #Convert currency
        if (Type == "currency") {
          FromYear <- G$BaseYear
          ToYear <- Spec_ls$YEAR
          if (FromYear != ToYear) {
            Data_ <- deflateCurrency(Data_, FromYear, ToYear)
            rm(FromYear, ToYear)
          }
        }
        #Convert units
        SimpleTypes_ <- c("integer", "double", "character", "logical")
        ComplexTypes_ <- names(Types())[!(names(Types()) %in% SimpleTypes_)]
        if (Type %in% ComplexTypes_) {
          AttrGroup <- switch(
            Group,
            Year = RunYear,
            BaseYear = G$BaseYear,
            Global = "Global"
          )
          Conversion_ls <-
          convertUnits(Data_, Type,
                       getDatasetAttr(Name, Table, AttrGroup, DstoreListing_ls)$UNITS,
                       Spec_ls$UNITS)
          Data_ <- Conversion_ls$Values
          rm(AttrGroup, Conversion_ls)
        }
        rm(SimpleTypes_, ComplexTypes_)
        #Convert magnitude
        Data_ <- convertMagnitude(Data_, 1, Spec_ls$MULTIPLIER)
        #Add data to list
        L[[Group]][[Table]][[Name]] <- Data_
        #When data successfully retrieved, break out of loop searching Files_
        break()
      }
    }
    rm(Spec_ls, Group, Table, Name, Type, DstoreGroup, Files_)
  }
  #Return the list
  L
}


#SAVE DATA SETS RETURNED BY A MODULE IN THE DATASTORE
#====================================================
#' Save the data sets returned by a module in the datastore
#'
#' \code{setInDatastore} a visioneval framework control function saves to the
#' datastore the data returned in a standard list by a module.
#'
#' This function saves to the datastore the data sets identified in a module's
#' 'Set' specifications and included in the list returned by the module. If a
#' particular geographic area is identified, the data are saved to the positions
#' in the data sets in the datastore corresponding to the identified geographic
#' area.
#'
#' @param Data_ls a list containing the data to be saved. The list is organized
#' by group, table, and data set.
#' @param ModuleSpec_ls a list of module specifications that is consistent with
#' the VisionEval requirements
#' @param ModuleName a string identifying the name of the module (used to document
#' the module creating the data in the datastore)
#' @param GeoIndex_ls a list of geographic indices used to determine the
#' positions to extract from a dataset corresponding to the specified geography.
#' @param Year a string identifying the model run year
#' @param Geo a string identifying the name of the geographic area to get the
#' data for. For example, if the module is specified to be run by Azone, then
#' Geo would be the name of a particular Azone.
#' @return A logical value which is TRUE if the data are successfully saved to
#' the datastore.
#' @export
setInDatastore <-
  function(Data_ls, ModuleSpec_ls, ModuleName, Year, Geo = NULL, GeoIndex_ls = NULL) {
    #Get the model state
    G <- getModelState()
    #Make any specified tables
    if (!is.null(ModuleSpec_ls$NewSetTable)) {
      TableSpec_ls <- ModuleSpec_ls$NewSetTable
      for (i in 1:length(TableSpec_ls)) {
        Table <- TableSpec_ls[[i]]$TABLE
        Group <- TableSpec_ls[[i]]$GROUP
        if (Group == "Global") DstoreGroup <- "Global"
        if (Group == "Year") DstoreGroup <- Year
        TableExists <- checkTableExistence(Table, DstoreGroup, G$Datastore)
        if (!TableExists) {
          Length <- attributes(Data_ls[[Group]][[Table]])$LENGTH
          initTable(Table, DstoreGroup, Length)
          rm(Table, Group, DstoreGroup, TableExists, Length)
        } else {
          rm(Table, Group, DstoreGroup, TableExists)
        }
      }
    }
    #Process module Set specifications
    SetSpec_ls <- ModuleSpec_ls$Set
    for (i in 1:length(SetSpec_ls)) {
      #Identify datastore save location from specifications
      Spec_ls <- SetSpec_ls[[i]]
      Spec_ls$MODULE <- ModuleName
      Group <- Spec_ls$GROUP
      Table <- Spec_ls$TABLE
      Name <- Spec_ls$NAME
      Type <- Spec_ls$TYPE
      if (Group == "Global") DstoreGroup <- "Global"
      if (Group == "Year") DstoreGroup <- Year
      #Make an index to the data
      DoCreateIndex <-
        !is.null(Geo) &
        !(Group == "Global" & !(Table %in% c("Marea", "Azone", "Bzone", "Czone")))
      if (DoCreateIndex) {
        Index <-
          createGeoIndex(Table, DstoreGroup, ModuleSpec_ls$RunBy, Geo, GeoIndex_ls)
      } else {
        Index <- NULL
      }
      #Transform and save the data
      Data_ <- Data_ls[[Group]][[Table]][[Name]]
      if (!is.null(Data_)) {
        #Convert currency
        if (Type == "currency") {
          FromYear <- Spec_ls$YEAR
          ToYear <- G$BaseYear
          if (FromYear != ToYear) {
            Data_ <- deflateCurrency(Data_, FromYear, ToYear)
            rm(FromYear, ToYear)
          }
        }
        #Convert units
        SimpleTypes_ <- c("integer", "double", "character", "logical")
        ComplexTypes_ <- names(Types())[!(names(Types()) %in% SimpleTypes_)]
        if (Type %in% ComplexTypes_) {
          FromUnits <- Spec_ls$UNITS
          Conversion_ls <- convertUnits(Data_, Type, FromUnits)
          Data_ <- Conversion_ls$Values
          #Change units specification to reflect default datastore units
          Spec_ls$UNITS <- Conversion_ls$ToUnits
          rm(FromUnits, Conversion_ls)
        }
        rm(SimpleTypes_, ComplexTypes_)
        #Convert magnitude
        Data_ <- convertMagnitude(Data_, Spec_ls$MULTIPLIER, 1)
      } else {
        Message <-
          paste0(
            "setInDatastore got NULL Data_ with arguments Group: ",
            Group, ", Table: ", Table, ", Name: ", Name
          )
        writeLog(Message)
        stop(Message)
      }
      if (!is.null(attributes(Data_)$SIZE)) {
        Spec_ls$SIZE <- attributes(Data_)$SIZE
      }
      writeToTable(Data_, Spec_ls, DstoreGroup, Index)
      rm(Spec_ls, Group, Table, Name, Data_)
    }
    TRUE
  }


#WRITE PROCESSED INPUTS TO DATASTORE
#===================================
#' Write the datasets in a list of module inputs that have been processed to the
#' datastore.
#'
#' \code{inputsToDatastore} a visioneval framework control function that takes a
#' list of processed module input files and writes the datasets to the
#' datastore.
#'
#' This function takes a processed list of input datasets specified by a module
#' created by the application of the 'processModuleInputs' function and writes
#' the datasets in the list to the datastore.
#'
#' @param Inputs_ls a list processes module inputs as created by the
#' 'processModuleInputs' function.
#' @param ModuleSpec_ls a list of module specifications that is consistent with
#' the VisionEval requirements.
#' @param ModuleName a string identifying the name of the module (used to
#' document the dataset in the datastore).
#' @return A logical indicating successful completion. Most of the outputs of
#' the function are the side effects of writing data to the datastore.
#' @export
inputsToDatastore <-
  function(Inputs_ls, ModuleSpec_ls, ModuleName) {
    G <- getModelState()
    #Make sure the inputs are error free
    if (length(Inputs_ls$Errors) != 0) {
      Msg <-
        paste0(
          "Unable to write module inputs for module '", ModuleName, "'. ",
          "There are one or more errors in the inputs or input specifications."
        )
      stop(Msg)
    }
    #Set up processing
    Errors_ <- character(0)
    Data_ls <- Inputs_ls$Data
    InpSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Inp
    #Set up new tables
    if (!is.null(ModuleSpec_ls$NewInpTable)) {
      TableSpec_ls <- ModuleSpec_ls$NewInpTable
      for (i in 1:length(TableSpec_ls)) {
        Table <- TableSpec_ls[[i]]$TABLE
        Group <- TableSpec_ls[[i]]$GROUP
        if (Group != "Global") {
          Msg <-
            paste0(
              "NewInpTable specification error for module '", ModuleName, "'. ",
              "New input tables can only be made in the 'Global' group. "
            )
          Errors_ <- c(Errors_, Msg)
        }
        Length <- length(Data_ls[[Group]][[Table]][[1]])
        initTable(Table, Group, Length)
      }
    }
    #Write Global group tables to datastore
    if (length(Data_ls[["Global"]]) > 0) {
      for (Table in names(Data_ls[["Global"]])) {
        if (Table %in% c("Azone", "Bzone", "Czone", "Marea")) {
          Data_df <-
            data.frame(Data_ls[["Global"]][[Table]], stringsAsFactors = FALSE)
          Units_ls <- lapply(Data_df, function(x) unname(attributes(x)$UNITS))
          SortData_df <- sortGeoTable(Data_df, Table, "Global")
          FieldsToSave_ <-
            names(SortData_df)[!(names(SortData_df) %in% "Geo")]
          for (Name in FieldsToSave_) {
            Spec_ls <- findSpec(InpSpec_ls, Name, Table, "Global")
            Spec_ls$MODULE <- ModuleName
            #Modify units spec to reflect units consistent with defaults for
            #datastore
            Spec_ls$UNITS <- Units_ls[[Name]]
            writeToTable(SortData_df[[Name]], Spec_ls, "Global")
            rm(Spec_ls)
          }
          rm(SortData_df, FieldsToSave_, Data_df, Units_ls)
        } else {
          for (Name in names(Data_ls[["Global"]][[Table]])) {
            Data_ <- Data_ls[["Global"]][[Table]][[Name]]
            Spec_ls <- findSpec(InpSpec_ls, Name, Table, "Global")
            Spec_ls$MODULE <- ModuleName
            #Modify units spec to reflect units consistent with defaults for
            #datastore
            Spec_ls$UNITS <- attributes(Data_)$UNITS
            writeToTable(Data_, Spec_ls, "Global")
          }
        }
      }
    }
    #Write BaseYear group tables to datastore
    if (length(Data_ls[["BaseYear"]]) > 0) {
      for (Table in names(Data_ls[["BaseYear"]])) {
        Data_df <-
          data.frame(Data_ls[["BaseYear"]][[Table]], stringsAsFactors = FALSE)
        Units_ls <- lapply(Data_df, function(x) unname(attributes(x)$UNITS))
        Year <- G$BaseYear
        SortData_df <- sortGeoTable(Data_df, Table, Year)
        FieldsToSave_ <-
          names(SortData_df)[!(names(SortData_df) %in% "Geo")]
        for (Name in FieldsToSave_) {
          Spec_ls <- findSpec(InpSpec_ls, Name, Table, "BaseYear")
          Spec_ls$MODULE <- ModuleName
          #Modify units spec to reflect units consistent with defaults for
          #datastore
          Spec_ls$UNITS <- Units_ls[[Name]]
          writeToTable(SortData_df[[Name]], Spec_ls, Year)
          rm(Spec_ls)
        }
        rm(Year, SortData_df, FieldsToSave_, Data_df, Units_ls)
      }
    }
    #Write Year group tables to datastore
    if (length(Data_ls[["Year"]]) > 0) {
      for (Table in names(Data_ls[["Year"]])) {
        Data_df <-
          data.frame(Data_ls[["Year"]][[Table]], stringsAsFactors = FALSE)
        Units_ls <- lapply(Data_df, function(x) unname(attributes(x)$UNITS))
        for (Year in unique(as.character(Data_df$Year))) {
          YrData_df <- Data_df[Data_df$Year == Year,]
          if (Table != "Region") {
            SortData_df <- sortGeoTable(YrData_df, Table, Year)
          } else {
            SortData_df <- YrData_df
          }
          FieldsToSave_ <-
            names(SortData_df)[!(names(SortData_df) %in% c("Year", "Geo"))]
          for (Name in FieldsToSave_) {
            Spec_ls <- findSpec(InpSpec_ls, Name, Table, "Year")
            Spec_ls$MODULE <- ModuleName
            #Modify units spec to reflect units consistent with defaults for
            #datastore
            Spec_ls$UNITS <- Units_ls[[Name]]
            writeToTable(SortData_df[[Name]], Spec_ls, Year)
            rm(Spec_ls)
          }
          rm(YrData_df, SortData_df, FieldsToSave_)
        }
        rm(Data_df)
      }
    }
    TRUE
  }
