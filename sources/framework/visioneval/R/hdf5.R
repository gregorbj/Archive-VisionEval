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
#' @param Group a string representation of the name of the group the table is to
#' be created in.
#' @return The value TRUE is returned if the function is successful at creating
#'   the table. In addition, the listDatastore function is run to update the
#'   inventory in the model state file. The function stops if the group in which
#'   the table is to be placed does not exist in the datastore and a message is
#'   written to the log.
#' @export
#' @import rhdf5
initTable <- function(Table, Group, Length) {
  G <- getModelState()
  NewTable <- paste(Group, Table, sep = "/")
  H5File <- H5Fopen(G$DatastoreName)
  h5createGroup(H5File, NewTable)
  H5Group <- H5Gopen(H5File, NewTable)
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
#' @param Group a string representation of the name of the group the table is to
#' be created in.
#' @return TRUE if dataset is successfully initialized. If the dataset already
#' exists the function throws an error and writes an error message to the log.
#' Updates the model state file.
#' @export
#' @import rhdf5
initDataset <- function(Spec_ls, Group) {
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
  if (!is.null(Spec_ls$PROHIBIT)) {
    h5writeAttribute(Spec_ls$PROHIBIT, H5Data, "PROHIBIT")
  }
  if (!is.null(Spec_ls$ISELEMENTOF)) {
    h5writeAttribute(Spec_ls$ISELEMENTOF, H5Data, "ISELEMENTOF")
  }
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
#' other and to the table length. On successful completion, the function calls
#' 'listDatastore' to update the datastore listing in the run environment.
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
writeToTable <- function(Data_, Spec_ls, Group, Index = NULL) {
  G <- getModelState()
  Name <- Spec_ls$NAME
  Table <- Spec_ls$TABLE
  #Check that dataset exists to write to and attempt to create if not
  DatasetExists <- checkDataset(Name, Table, Group, G$Datastore)
  if (!DatasetExists) {
    initDataset(Spec_ls, Group)
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
#' @param Group a string representation of the name of the datastore group the
#' data is to be read from.
#' @param File a string representation of the file path of the datastore
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to. NULL if the entire dataset is to be read.
#' @return A vector of the same type stored in the datastore and specified in
#'   the TYPE attribute.
#' @export
#' @import rhdf5
readFromTable <- function(Name, Table, Group, File = "datastore.h5", Index = NULL) {
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
  G <- getModelListing(DstoreRef = File)
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
#' @param Group A string identifying the group the table is located in.
#' @return A function that creates a vector of positions corresponding to the
#'   location of the supplied value in the index field.
#' @export
createIndex <- function(Name, Table, Group) {
  ValsToIndexBy <-
    readFromTable(Name, Table, Group)
  return(function(IndexVal) {
    which(ValsToIndexBy == IndexVal)
  })
}


#INITIALIZE DATA LIST
#====================
#' Initialize a list for data transferred to and from datastore
#'
#' \code{initDataList} creates a list to be used for transferring data to and
#' from the datastore.
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


#GET DATA SETS IDENTIFIED IN MODULE SPECIFICATIONS FROM DATASTORE
#================================================================
#' Retrieve data identified in 'Get' specifications from datastore
#'
#' \code{getFromDatastore} retrieves datasets identified in a module's 'Get'
#' specifications from the datastore.
#'
#' This function retrieves from the datastore all of the data sets identified in
#' a module's 'Get' specifications. If the module's specifications include the
#' name of a geographic area, then the function will retrieve the data for that
#' geographic area.
#'
#' @param ModuleSpec_ls a list of module specifications that is consistent with
#' the VisionEval requirements
#' @param Geo a string identifying the name of the geographic area to get the
#' data for. For example, if the module is specified to be run by Azone, then
#' Geo would be the name of a particular Azone.
#' @param RunYear a string identifying the model year being run. The default is
#' the Year object in the global workspace.
#' @return A list containing all the data sets specified in the module's
#' 'Get' specifications for the identified geographic area.
#' @export
getFromDatastore <- function(ModuleSpec_ls, Geo = NULL, RunYear = Year) {
  #Process module Get specifications
  GetSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Get
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
    if (!is.null(Geo)) {
      idxFun <- createIndex(ModuleSpec_ls$RunBy, Table, DstoreGroup)
      index <- idxFun(Geo)
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
        L[[Group]][[Table]][[Name]] <-
          readFromTable(Name, Table, DstoreGroup, File, Index)
        break()
      }
    }
    rm(Spec_ls, Group, Table, Name, DstoreGroup, Files_)
  }
  #Return the list
  L
}


#SAVE DATA SETS RETURNED BY A MODULE IN THE DATASTORE
#====================================================
#' Save the data sets returned by a module in the datastore
#'
#' \code{setInDatastore} saves to the datastore the data returned in a standard
#' list by a module.
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
#' @param Year a string identifying the model run year
#' @param Geo a string identifying the name of the geographic area to get the
#' data for. For example, if the module is specified to be run by Azone, then
#' Geo would be the name of a particular Azone.
#' @return A logical value which is TRUE if the data are successfully saved to
#' the datastore.
#' @export
setInDatastore <-
  function(Data_ls, ModuleSpec_ls, ModuleName, Year, Geo = NULL) {
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
    SetSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Set
    for (i in 1:length(SetSpec_ls)) {
      #Identify datastore save location from specifications
      Spec_ls <- SetSpec_ls[[i]]
      Spec_ls$MODULE <- ModuleName
      Group <- Spec_ls$GROUP
      Table <- Spec_ls$TABLE
      Name <- Spec_ls$NAME
      if (Group == "Global") DstoreGroup <- "Global"
      if (Group == "Year") DstoreGroup <- Year
      #Make an index to the data
      if (!is.null(Geo)) {
        idxFun <- createIndex(ModuleSpec_ls$RunBy, Table, DstoreGroup)
        index <- idxFun(Geo)
      } else {
        Index <- NULL
      }
      #Save the data
      Data_ <- Data_ls[[Group]][[Table]][[Name]]
      if (is.null(Data_)) {
        Message <-
          paste0(
            "setInDatastore got NULL Data_ with arguments Group: ", Group, ", Table: ", Table, ", Name: ", Name
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


#CHECK YEARS AND GEOGRAPHY OF INPUT FILE
#=======================================
#' Check years and geography of input file
#'
#' \code{checkInputYearGeo} checks the 'Year' and 'Geo' columns of an input file
#' to determine whether they are complete and have no duplications.
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
#' \code{findSpec} returns the full dataset specification for defined NAME,
#' TABLE, and GROUP.
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
#' \code{sortGeoTable} returns a data frame whose rows are sorted to match the
#' geography in a specified table in the datastore.
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


#PROCESS MODULE INPUT FILES
#==========================
#' Process module input files
#'
#' \code{processModuleInputs} processes input files identified in a module's
#' 'Inp' specifications in preparation for saving in the datastore.
#'
#' This function processes the input files identified in a module's 'Inp'
#' specifications in preparation for saving the data in the datastore. Several
#' processes are carried out. The existence of each specified input file is
#' checked. Files that are not global, are checked to determine that they have
#' 'Year' and 'Geo' columns. The entries in the 'Year' and 'Geo' columns are
#' checked to make sure they are complete and there are no duplicates. The data
#' in each column are checked against specifications to determine conformance.
#' The function returns a list which contains a list of error messages and a
#' list of the data inputs. The function also writes error messages and warnings
#' to the log file.
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
    FileErr_ <- character(0)
    FileWarn_ <- character(0)
    InpSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Inp

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
    Files_ <- names(SortSpec_ls)
    for (File in Files_) {
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
      #If Group is Year, check that Geo and Year fields are correct
      if (Group  == "Year") {
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
      #Check and load data into list
      DataErr_ls <- list(Errors = character(0), Warnings = character(0))
      for (Name in names(Spec_ls)) {
        ThisSpec_ls <- Spec_ls[[Name]]
        Data_ <- Data_df[[Name]]
        DataCheck_ls <-
          checkDataConsistency(Name, Data_, ThisSpec_ls)
        if (length(DataCheck_ls$Errors) != 0) {
          writeLog(DataCheck_ls$Errors)
          DataErr_ls$Errors <-
            c(DataErr_ls$Errors, DataCheck_ls$Errors)
          next()
        }
        if (length(DataCheck_ls$Warnings) != 0) {
          writeLog(DataCheck_ls$Warnings)
          DataErr_ls$Warnings <-
            c(DataErr_ls$Warnings, DataCheck_ls$Warnings)
        }
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
    }#End loop through input files

    #RETURN THE RESULTS
    list(Errors = FileErr_, Data = Data_ls)
  }


#WRITE PROCESSED INPUTS TO DATASTORE
#===================================
#' Write the datasets in a list of module inputs that have been processed to the
#' datastore.
#'
#' \code{inputsToDatastore} takes a list of processed module input files and
#' writes the datasets to the datastore.
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
        if (Group != "Region") {
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
        for (Name in names(Data_ls[["Global"]][[Table]])) {
          Data_ <- Data_ls[[Group]][[Table]][[Name]]
          Spec_ls <- findSpec(InpSpec_ls, Name, Table, Group)
          Spec_ls$MODULE <- ModuleName
          writeToTable(Data_, Spec_ls, Group)
        }
      }
    }
    #Write Year group tables to datastore
    if (length(Data_ls[["Year"]]) > 0) {
      for (Table in names(Data_ls[["Year"]])) {
        Data_df <-
          data.frame(Data_ls[["Year"]][[Table]], stringsAsFactors = FALSE)
        for (Year in unique(as.character(Data_df$Year))) {
          YrData_df <- Data_df[Data_df$Year == Year,]
          SortData_df <- sortGeoTable(YrData_df, Table, Year)
          FieldsToSave_ <-
            names(SortData_df)[!(names(SortData_df) %in% c("Year", "Geo"))]
          for (Name in FieldsToSave_) {
            Spec_ls <- findSpec(InpSpec_ls, Name, Table, "Year")
            Spec_ls$MODULE <- ModuleName
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
