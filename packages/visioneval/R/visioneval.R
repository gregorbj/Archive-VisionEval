#============
#visioneval.r
#============

#This script defines the functions that implement the RSPM framework. The functions will ultimately be deployed in a package. The package name is 'visioneval' because it supports the VisionEval model system.

#These functions serve as the applications programming interface (API) for the RSPM and for the underlying datastore which is an HDF5 format file. The functions which interact with the HDF5 datastore use functions in the 'rhdf5' package to do so. If a decision is made to shift the datastore to a different format (e.g. SQL), the HDF5-specific functions would need to be rewritten to interact with the new format. Some of the model parameters are stored in JSON formatted file. The function use the 'jsonlite' package to read these files.


#LOAD PACKAGES
#=============
library(rhdf5)
library(jsonlite)

items <- function(...) {
  list(...)
}

item <- function(...) {
  list(...)
}
  
  
#DEFINE FUNCTION FOR INITIALIZING THE RUN ENVIRONMENT
#====================================================
#' Initialize run environment.
#' 
#' \code{initEnv} creates an environment and initializes it to store key 
#' information to manage a model run.
#' 
#' This function creates an environment 'E' which is used to keep track of key 
#' information which is used to manage a model run. It is initialized with 
#' values stored in the 'defs/parameters.json' file. At this time the parameters
#' include the scenario name ('Scenario' parameter), scenario description 
#' ('Description' parameter), base year ('BaseYear' parameter), and model run 
#' years ('Years' parameter). Additional parameters may be added in the future.
#' 
#' @return The function has no return value. It creates an environment named 'E'
#'   in the global environment which contains each of the parameters defined in
#'   the 'defs/parameters.json' file. It stops and reports an error if the
#'   'defs/parameters.json' file is not present.
initEnv <- function() {
  E <- new.env()
  if (!file.exists("defs/parameters.json")) {
    Message <- "Missing 'defs/parameters.json' file."
    stop(Message)
  } else {
    Parm <- fromJSON("defs/parameters.json")
    for (name in names(Parm)) {
      E[[name]] <- Parm[[name]]
    }
    E <<- E
  }
}


#DEFINE FUNCTION FOR INITIALIZING THE RUN LOG
#============================================
#' Initialize the run log.
#' 
#' \code{initLog} creates a log (text file) that stores messages generated
#' during a model run.
#' 
#' This function creates a log file that is a text file which stores messages
#' generated during a model run. The name of the log is 'Log <date> <time>'
#' where '<date>' is the initialization date and '<time>' is the initialization
#' time. The log is initialized with the scenario name, scenario description and
#' the date and time of initialization.
#' 
#' @return The function has no return value. It creates a log file in the
#'   working directory and identifies the name of the log file in the run
#'   environment 'E$LogFile'.
initLog <- function() {
  LogInitTime <- as.character(Sys.time())
  LogFile <- paste("Log", gsub(":", "-", LogInitTime), ".txt")
  sink(LogFile, append = TRUE)
  cat(E$Scenario)
  cat("\n")
  cat(E$Description)
  cat("\n")
  cat(LogInitTime)
  cat("\n\n")
  sink()
  assign("LogFile", LogFile, envir = E)
}


#DEFINE FUNCTION FOR WRITING A MESSAGE TO THE LOG
#================================================
#' Writes message to run log.
#' 
#' \code{writeLog} writes a message to the run log.
#' 
#' This function writes a message in the form of a string to the run log. It
#' logs the time as well as the message to the run log.
#' 
#' @param Msg A character string.
#' @return The function has no return value. It appends the time and the message
#'   text to the run log.
writeLog <- function(Msg = "") {
  Con <- file(E$LogFile, open = "a")
  Time <- as.character(Sys.time())
  Content <- paste(Time, ":", Msg, "\n")
  writeLines(Content, Con)
  close(Con)
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


#Define function for loading an existing datastore
#=================================================
#' Load an existing saved datastore.
#' 
#' \code{loadDatastore} copy an existing saved datastore and write information
#' to run environment.
#' 
#' This function copies a saved datastore as 'datastore.h5' in the working
#' directory and attributes the run environment with related geographic
#' information. This function will most often be used during module development
#' to start off with a datastore which contains the data needed to run a module.
#' It may also be used to run scenario variants off of a constant set of
#' starting conditions.
#' 
#' @param FileToLoad A string identifying the full path name to the saved
#'   datastore. Path name can either be relative to the working directory or
#'   absolute.
#' @param GeoFile A string identifying the name of the geography definition file
#'   (see 'readGeography' function) that is consistent with the saved datastore.
#'   The geography definition file must be located in the 'defs' directory.
#' @return The function has no return value. It copies the saved datastore to
#'   working directory as 'datastore.h5'. If a 'datastore.h5' file already
#'   exists, it first renames that file as 'archive-datastore.h5'. The function
#'   copies the geographic definitions to the run environment. It also puts a
#'   listing of the contents in 'E$Datastore'. If the stored file does not exist
#'   an error is thrown.
loadDatastore <- function(FileToLoad, GeoFile) {
  GeoFile <- paste0("defs/", GeoFile)
  #If data store exists, rename
  DatastoreName <- E$DatastoreName
  if (file.exists(DatastoreName)) {
    file.rename(DatastoreName, paste("archive", DatastoreName, sep = "-"))
  }
  if (file.exists(FileToLoad)) {
    file.copy(FileToLoad, DatastoreName)
    Geo_df <- read.csv(GeoFile, colClasses = "character")
    E$BzoneSpecified <- !all(is.na(Geo_df$Bzone))
    E$Geo_df <- Geo_df
    listDatastore()
  } else {
    Message <- paste("File", FileToLoad, "not found.")
    writeLog(Message)
    stop(Message)
  }
}

  
#DEFINE FUNCTION FOR CHECKING GEOGRAPHIC SPECIFICATIONS
#======================================================
#' Check correctness of geographic specifications.
#' 
#' \code{readGeography} reads and checks geographic specifications file for
#' model.
#' 
#' This function reads the file containing geographic specifications for the
#' model and checks the file entries to determine whether they are internally
#' consistent.
#' 
#' @param Filename A string identifying the name of the geographic
#'   specifications file. This is a csv-formatted text file which contains
#'   columns named 'Azone', 'Bzone', and 'Marea'. The 'Azone' column must have
#'   zone names in all rows. The 'Bzone' column can be unspecified (NA in all
#'   rows) or may have have unique names in every row. The 'Marea' column
#'   (referring to metropolitan areas) identifies metropolitan areas
#'   corresponding to each Azone or the value 'None' if a metropolitan area does
#'   not occupy any portion of an Azone. The geographic specifications file must
#'   exist in the "defs" directory.
#' @return The value TRUE is returned if the function is successful at reading
#'   the file and the specifications are consistent. It stops if there are any
#'   errors in the specifications. All of the identified errors are written to
#'   the run log. A data frame containing the file entries is added to the run
#'   environment as 'E$Geo_df'.
readGeography <- function(Filename) {
  #Read in geographic definitions if file exists, otherwise error
  #--------------------------------------------------------------
  Filepath <- paste0("defs/", Filename)
  if (file.exists(Filepath)) {
    Geo_df <- read.csv(Filepath, colClasses = "character")
  } else {
    Message <- paste("Missing", Filename, "file in folder 'defs'.")
    writeLog(Message)
    stop(Message)
  }
  #Check that file has all required fields and extract field attributes
  #--------------------------------------------------------------------
  FieldNames_ <- c("Azone", "Bzone", "Marea")
  if (!(all(names(Geo_df) %in% FieldNames_))) {
    Message <- "'geography.csv' is missing some required fields."
    writeLog(Message)
    stop(Message)
  }
  #Check table entries
  #-------------------
  BzoneSpecified <- !all(is.na(Geo_df$Bzone))
  E$BzoneSpecified <- BzoneSpecified
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
  #Determine whether entries are correct if Bzones have been specified
  if (BzoneSpecified) {
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
    if (any(unlist(lapply(AzoneMareas_, length)) > 1)) {
      Messages_ <- c(Messages_,
                     "At least one Azone is assigned more than one Marea")
    }
  }
  #Notify if any table tests fail
  if (length(Messages_) > 0) {
    for (message in Messages_) {
      writeLog(message)
    }
    stop(paste0("One or more errors in ", Filename, ". See log for details."))
  } else {
    writeLog("Geographical indices successfully read.")
  }
  #Save the geographic data
  E$Geo_df <<- Geo_df
  TRUE
}


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
  E$Datastore <- DS_df
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
#' @param Group A string identifying the complete name of the datastore group
#'   where the table is to be located.
#' @param Name The name of the table to be created.
#' @param LENGTH The required length of all data vectors to be stored in the
#'   table.
#' @return The value TRUE is returned if the function is successful at creating
#'   the table. In addition, the 'listDatastore' function is run to update the
#'   inventory in the run environment. The function stops if the group in which
#'   the table is to be placed does not exist in the datastore and a message is
#'   written to the log.
initDatastoreTable <- function(Group, Name, LENGTH) {
  if (Group %in% E$Datastore$groupname) {
    NewGroup <- paste(Group, Name, sep = "/")
    H5File <- H5Fopen(E$DatastoreName)
    h5createGroup(H5File, NewGroup)
    H5Group <- H5Gopen(H5File, NewGroup)
    h5writeAttribute(LENGTH, H5Group, "LENGTH")
    H5Gclose(H5Group)
    H5Fclose(H5File)
    listDatastore()
    TRUE
  } else {
    Message <-
      paste("Group", Group, "has not been created in the datastore.")
    writeLog(Message)
    stop(Message)
  }
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
#' @param Table A string identifying the complete name of the table where the
#'   dataset will be located.
#' @param Name The name of the dataset to be created.
#' @param NAVALUE The value that is used to represent NA values in the dataset.
#' @param UNITS The measurement units for the data.
#' @param TYPE The data type for the data ("integer", "double", "character").
#' @param SIZE The maximum number of characters that can be stored in an entry
#'   for character data. Value for non-character type data should be 0.
#' @param PROHIBIT A vector which describes prohibited data values.
#' @return The function has no return value. If the function is successful, the
#'   dataset is initialized. If the dataset already exists or the table doesn't
#'   exist, the function throws an error and writes an error message to the log.
initDataset <-
  function(Table, Name, NAVALUE, UNITS, TYPE, SIZE, PROHIBIT = "") {
    DatasetName <- paste(Table, Name, sep = "/")
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
    #Check that table exists to write to
    if (!(Table %in% E$Datastore$groupname)) {
      Message <-
        paste("Table", Table, "has not been created in the datastore.")
      writeLog(Message)
      stop(Message)
    }
    #Create the dataset
    Length <-
      unlist(h5readAttributes(E$DatastoreName, Table))["LENGTH"]
    Chunck <- ifelse(Length > 1000, 100, 1)
    H5File <- H5Fopen(E$DatastoreName)
    h5createDataset(
      H5File, DatasetName, dims = Length,
      storage.mode = TYPE, size = SIZE + 1,
      chunk = Chunck, level = 7
    )
    H5Data <- H5Dopen(H5File, DatasetName)
    h5writeAttribute(NAVALUE, H5Data, "NAVALUE")
    h5writeAttribute(UNITS, H5Data, "UNITS")
    h5writeAttribute(SIZE, H5Data, "SIZE")
    h5writeAttribute(TYPE, H5Data, "TYPE")
    h5writeAttribute(PROHIBIT, H5Data, "PROHIBIT")
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
#' This function writes data to a dataset in a table. It initializes the dataset if the dataset does not exist. Enables data to be written to specific location indexes in the dataset. The function makes several checks prior to attempting to write to the datastore including : the desired table exists in the datastore, the input data is a vector, the data and index conform to each other and to the table length, the type, size, and units of the data match the datastore specifications. On successful completion, the function calls 'listDatastore' to update the datastore listing in the run environment.
#' 
#' @param Data A vector of data to be written.
#' @param Table A string identifying the complete name of the table where the
#'   dataset is located.
#' @param Name A string identifying the name of the dataset to be written to.
#' @param Index A numeric vector identifying the positions the data is to be written to.
#' @param NAVALUE The value that is used to represent NA values in the dataset.
#' @param UNITS A string identifying the measurement units for the data ("None" if no units).
#' @param TYPE A string identifying the data type for the data ("integer", "double", "character").
#' @param SIZE A number identifying the maximum number of characters that can be stored in an entry
#'   for character data. 0 for non-character data.
#' @param PROHIBIT A vector of strings which identify prohibited data values.
#' @return The function returns TRUE if data is sucessfully written.
writeToTable <- function(Data, Table, Name, Index = NULL,
                         NAVALUE, UNITS, TYPE, SIZE = 0, PROHIBIT = "") {
  DatasetName <- paste(Table, Name, sep = "/")
  DatasetExists <- DatasetName %in% E$Datastore$groupname
  #Check that Table exists to write to
  if (!(Table %in% E$Datastore$groupname)) {
    Message <-
      paste("Table", Table, "has not been created in the datastore.")
    writeLog(Message)
    stop(Message)
  }
  #Check that data is a vector
  if (!is.vector(Data)) {
    Message <-
      paste0("Data ", Name, " does not conform to ", Table, ". Must be a vector.")
    writeLog(Message)
    stop(Message)
  }
  #Check that the data conforms to the table if not indexed write
  TableAttr_ <-
    unlist(E$Datastore$attributes[E$Datastore$groupname == Table])
  AllowedLength <- TableAttr_["LENGTH"]
  if (is.null(Index) & (!is.null(dim(Data))) & (length(Data) != AllowedLength)) {
    Message <-
      paste0(Name, " doesn't conform to", Table, ". must have length = ", AllowedLength)
    writeLog(Message)
    stop(Message)
  }
  #Check that if there is an index, the length is equal to the length of Data
  if (!is.null(Index) & (length(Data) != length(Index))) {
    Message <-
      paste0("Length of Data vector and length of Index vector don't match.")
    writeLog(Message)
    stop(Message)
  }
  #Check that indices conform to table if indexed write
  if (any(Index > AllowedLength)) {
    Message <-
      paste0("One or more specified indicies for writing data to ", Table, " exceed ", AllowedLength)
    writeLog(Message)
    stop(Message)
  }
  #If dataset exists, check that values are consistent
  if (DatasetExists) {
    DatasetAttr_ <- unlist(E$Datastore[E$Datastore$groupname == DatasetName, "attributes"],
                           recursive = FALSE)
    if (typeof(Data) != unlist(DatasetAttr_["TYPE"])) {
      Message <- paste0(
        "The storage mode of the data (",
        typeof(Data),
        ") does not match the storage mode of datastore (",
        DatasetAttr_["TYPE"],
        ") for dataset ",
        DatasetName
      )
      writeLog(Message)
      stop(Message)
    }
    MaxSize <- max(nchar(Data))
    if ((typeof(Data) == "character") &
        (MaxSize > unlist(DatasetAttr_["SIZE"]))) {
      Message <- paste0(
        "Attempting to write character data of length (",
        MaxSize,
        ") which is longer than specified in datastore (",
        DatasetAttr_["SIZE"],
        ") for dataset ",
        DatasetName
      )
      writeLog(Message)
      stop(Message)
    }
    if (UNITS != unlist(DatasetAttr_["UNITS"])) {
      Message <- paste0(
        "Specified UNITS (",
        UNITS,
        ") are not different than specified in datastore (",
        DatasetAttr_["UNITS"],
        ") for dataset ",
        DatasetName
      )
      writeLog(Message)
      warning(Message)
    }
  }
  #Create dataset if it does not already exist in the datastore
  if (!DatasetExists) {
    initDataset(
      Table = Table, Name = Name, NAVALUE = NAVALUE,
      UNITS = UNITS, TYPE = TYPE, SIZE = SIZE, PROHIBIT = PROHIBIT
    )
  }
  #Write the dataset
  Data[is.na(Data)] <- NAVALUE
  if (is.null(Index)) {
    h5write(Data, file = E$DatastoreName, name = DatasetName)
  } else {
    h5write(Data, file = E$DatastoreName, name = DatasetName, index = list(Index))
  }
  #Update datastore inventory
  listDatastore()
  TRUE
}


#WRITE A FUNCTION TO READ AN ITEM FROM A DATASTORE TABLE
#=======================================================
#' Read from table.
#' 
#' \code{readFromTable} writes data to table and initializes dataset if needed.
#' 
#' This function reads datasets from a table. Indexed reads are permitted. The
#' function checks whether the table and dataset exist and whether all specified
#' indices are within the length of the table. The function converts any values
#' equal to the NAVALUE attribute to NA.
#' 
#' @param Data A vector of data to be written.
#' @param Table A string identifying the complete name of the table where the 
#'   dataset is located.
#' @param Name A string identifying the name of the dataset to be written to.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to. NULL if the entire dataset is to be read.
#' @return A vector of the same type stored in the datastore and specified in
#'   the TYPE attribute.
readFromTable <- function(Table, Name, Index = NULL) {
  DataName <- paste(Table, Name, sep = "/")
  #Check that table and dataset exist
  if (!(Table %in% E$Datastore$groupname)) {
    Message <- paste0("Table (",
                      Table,
                      ") is not found in the datastore.")
    writeLog(Message)
    stop(Message)
  }
  if (!(DataName %in% E$Datastore$groupname)) {
    Message <- paste0("Dataset (",
                      DataName,
                      ") is not found in the datastore.")
    writeLog(Message)
    stop(Message)
  }
  #If there is an Index, check that it is in bounds
  if (!is.null(Index)) {
    TableAttr_ <-
      unlist(E$Datastore$attributes[E$Datastore$groupname == Table])
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
    Data_ <- h5read(E$DatastoreName, DataName, read.attributes = TRUE)
  } else {
    Data_ <-
      h5read(E$DatastoreName, DataName, index = list(Index), read.attributes = TRUE)
  }
  #Convert NA values
  NAValue <- as.vector(attributes(Data_)$NAVALUE)
  Data_[Data_ == NAValue] <- NA
  #Report out results
  Message <- paste0("Read data ", DataName)
  writeLog(Message)
  as.vector(Data_)
}


#DEFINE A FUNCTION TO WRITE GEOGRAPHIC INFORMATION TO THE DATASTORE
#==================================================================
#' Initialize datastore geography.
#' 
#' \code{initDatastoreGeography} initializes tables and writes datasets to the datastore which describe geographic relationships of the model.
#' 
#' This function writes tables to the datastore for each of the geographic levels. These tables are then used during a model run to store values that are either specified in scenario inputs or that are calculated during a model run. The function populates the tables with cross-references between geographic levels. The function reads the model geography from the run environment 'E$Geo_df'. Upon successful completion, the function calls 'listDatastore' to update the datastore listing in the run environment.
#' 
#' @return The function returns TRUE if the geographic tables and datasets are sucessfully written to the datastore.
initDatastoreGeography <- function() {
  #Write geography when Bzones unspecified
  if (!E$BzoneSpecified) {
    for (year in E$Years) {
      #Make and populate Azone table
      initDatastoreTable(year, "Azone", length(E$Geo_df$Azone))
      writeToTable(
        Data = E$Geo_df$Azone, Table = paste0(year, "/Azone"), Name = "Azone", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(E$Geo_df$Azone))
      )
      writeToTable(
        Data = E$Geo_df$Marea, Table = paste0(year, "/Azone"), Name = "Marea", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(E$Geo_df$Marea))
      )
      #Make and populate Marea table
      Marea_ <- unique(E$Geo_df$Marea)
      initDatastoreTable(year, "Marea", length(Marea_))
      writeToTable(
        Data = Marea_, Table = paste0(year, "/Marea"), Name = "Marea", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Marea_))
      )
    }
  }
  #Write geography when Bzones specified
  if (E$BzoneSpecified) {
    for (year in E$Years) {
      #Make and populate Azone table
      Azone_ <- unique(E$Geo_df$Azone)
      initDatastoreTable(year, "Azone", length(Azone_))
      writeToTable(
        Data = Azone_, Table = paste0(year, "/Azone"), Name = "Azone", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Azone_))
      )
      Tmp_ <- unique(paste(E$Geo_df$Azone, E$Geo_df$Marea, sep=";"))
      Tmp_mx <- do.call(rbind, strsplit(Tmp_, ";"))
      Marea_ <- Tmp_mx[match(Tmp_mx[,1], Azone_),2]
      writeToTable(
        Data = Marea_, Table = paste0(year, "/Azone"), Name = "Marea", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Marea_))
      )
      #Make and populate Bzone table
      Bzone_ <- E$Geo_df$Bzone
      Azone_ <- E$Geo_df$Azone
      Marea_ <- E$Geo_df$Marea
      initDatastoreTable(year, "Bzone", length(Bzone_))
      writeToTable(
        Data = Bzone_, Table = paste0(year, "/Bzone"), Name = "Bzone", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Bzone_))
      )
      writeToTable(
        Data = Azone_, Table = paste0(year, "/Bzone"), Name = "Azone", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Azone_))
      )
      writeToTable(
        Data = Marea_, Table = paste0(year, "/Bzone"), Name = "Marea", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Marea_))
      )
      #Make and populate Marea table
      Marea_ <- unique(E$Geo_df$Marea)
      initDatastoreTable(year, "Marea", length(Marea_))
      writeToTable(
        Data = Marea_, Table = paste0(year, "/Marea"), Name = "Marea", 
        Index = NULL, NAVALUE = "NA", UNITS = "None", TYPE = "character",
        SIZE = max(nchar(Marea_))
      )
    }
  }
  #Write to log that complete
  Message <- "Geography sucessfully added to datastore."
  writeLog(Message)
  TRUE
}  
  

#DEFINE A FUNCTION TO CHECK ALL MODULE INPUT FILES
#=================================================
#' Check module inputs.
#' 
#' \code{checkModuleInputs} manages the checking of module scenario input files.
#' 
#' This function manages the checking of scenario inputs required by a module.
#' Modules specify what inputs they need; the file names, the geographic level
#' of the data, the data fields, and the attributes of the data stored in the
#' data fields. A module may specify more than one scenario input file. This
#' function manages the checking of inputs of all these files and collates all
#' of the errors and warnings that are found with the inputs. It writes all of
#' the errors and warnings to the log.
#' 
#' @param ModuleName A string identifying the module whose scenario inputs are
#'   to be checked.
#' @return A list having 2 components, Errors and Warnings. Each component is a
#'   vector of error and warning messages respectively. If their lengths are 0,
#'   there are no errors or warnings.
checkModuleInputs <- function(ModuleName) {
  Model <- get(ModuleName)
  InputSpecs_df <- data.frame(do.call(rbind, Model$Inp))
  InputSpecs_ls <- split(InputSpecs_df, unlist(InputSpecs_df$FILE))
  ModuleResults_ <- list(Errors = character(0),
                         Warnings = character(0))
  for (Spec_ in InputSpecs_) {
    Results_ <- checkInputFile(Spec_)
    ModuleResults_$Errors <-
      c(ModuleResults_$Errors, Results_$Errors)
    ModuleResults_$Warnings <-
      c(ModuleResults_$Warnings, Results_$Warnings)
  }
  if (length(ModuleResults_$Errors > 0)) {
    Message <- paste(
      "Input files for module", ModuleName,
      "have one or more errors that must be fixed before running the module.",
      "The errors are as follows:"
    )
    writeLog(Message)
    for (i in 1:length(ModuleResults_$Errors)) {
      writeLog(ModuleResults_$Errors[i])
    }
  } else {
    Message <- paste("Input files for module", ModuleName,
                     "have no errors.")
    writeLog(Message)
  }
  if (length(ModuleResults_$Warnings > 0)) {
    Message <- paste(
      "Input files for module", ModuleName,
      "have one or more values that should be checked.",
      "The module can be run, but are the values as intended?",
      "The potentially incorrect values are as follows:"
    )
    writeLog(Message)
    for (i in 1:length(ModuleResults_$Warnings)) {
      writeLog(ModuleResults_$Warnings[i])
    }
  } else {
    Message <- paste("Input files for module", ModuleName,
                     "have no warnings.")
    writeLog(Message)
  }
  ModuleResults_
}

InputSpecs_ <- Module$Inp
prepInputSpecs <- function(InputSpecs_) {
  InputSpecs_df <- data.frame(do.call(rbind, InputSpecs_))
  InputSpecs_ls <- split(InputSpecs_df, unlist(InputSpecs_df$FILE))

}

#DEFINE A FUNCTION TO CHECK INPUT FILE FOR CORRECTNESS
#=====================================================
#' Check scenario input file.
#' 
#' \code{checkInputFile} checks whether specified input file exists and whether 
#' the values meet specifications.
#' 
#' This function checks whether the specified scenario input file exists and 
#' whether all of the values meet specifications including: whether values exist
#' for all years and for all geographic entities for the specified level of
#' geography, whether all specified data fields are in the file, whether the
#' data types are consistent with specifications, whether any prohibited data
#' values are present in the data, and whether any unlikely values are present
#' in the data. The function calls two other functions to carry out the checking
#' of data types ('compareDatatypeToSpec') and prohibited and unlikely values
#' ('checkValues').
#' 
#' @param Module A module object. A module is an environment which contains 
#'   specified components with specified names.
#' @param InputName A string identifying the input name. A module may specify 
#'   that any number of scenario input files be loaded. These inputs are 
#'   specified in the 'Inp' component of the module. Each input is described by 
#'   a separate named component. This argument is the name of the component.
#' @return A list having 2 components, Errors and Warnings. Each component is a 
#'   vector of error and warning messages respectively. If their lengths are 0, 
#'   there are no errors or warnings.
Spec_ <- InputSpecs_ls[[1]]
checkInputFile <- function(Inp_) {
  FileName <- Inp_$FILE[[1]]
  InputPath <- paste("inputs", FileName, sep = "/")
  Warnings_ <- character(0)
  Errors_ <- character(0)
  #Check that file exists
  if (!file.exists(InputPath)) {
    Message <- paste("Scenario input file", FileName,
                     "does not exist in the inputs folder.")
    Errors_ <- c(Errors_, Message)
    return(list(Errors = Errors_, Warnings = Warnings_))
  }
  #Load the data
  Inp_df <- read.csv(InputPath, as.is = TRUE)
  #Check that has all required field names
  RequiredFields <- c("Geo", "Year", names(Inp_$Fields))
  HasFields <- RequiredFields %in% names(Inp_df)
  if (!all(HasFields)) {
    MissingFields <- paste(RequiredFields[!HasFields], collapse = " & ")
    Message <-
      paste(Inp_$File, "is missing", MissingFields, "fields")
    Errors_ <- c(Errors_, Message)
    return(list(Errors = Errors_, Warnings = Warnings_))
  }
  #Check that there are records for each run year
  Years_ <- unique(Inp_df$Year)
  if (!all(E$Years %in% Years_)) {
    Message <- paste("Years in", Inp_ls$InpFile,
                     "not consistent with scenario specification.")
    Errors_ <- c(Errors_, Message)
    return(list(Errors = Errors_, Warnings = Warnings_))
  }
  #Check that Geo field has proper values for each year
  GeoLvl <- Inp_$GeoLvl
  GeoVals_ <- unique(E$Geo_df[[GeoLvl]])
  GeoVals_ <- GeoVals_[!is.na(GeoVals_)]
  GeoErrors <- 0
  for (year in E$Years) {
    InpVals_ <- Inp_df$Geo[Inp_df$Year == year]
    if (!all(GeoVals_ %in% InpVals_) |
        !all(InpVals_ %in% GeoVals_)) {
      GeoErrors <- GeoErrors + 1
      Message <- paste(
        "One or more geographic entries for",
        GeoLvl, "for year", year,
        "in input file", FileName,
        "do not correspond to scenario specification."
      )
      Errors_ <- c(Errors_, Message)
    }
  }
  #Convert values that may have been coded using the NAVALUE to NA
  for (i in 1:nrow(Inp_)) {
    NAVALUE <- unlist(Inp_[i, "NAVALUE"])
    Field <- unlist(Inp_[i, "NAME"])
    ChangeToNA <- Inp_df[[Field]] == NAVALUE
    Inp_df[[Field]][ChangeToNA] <- NA
  }
  #Check that the types of data are acceptable
  for (i in 1:nrow(Inp_)) {
    SpecDataType <- unlist(Inp_[i, "TYPE"])
    Field <- unlist(Inp_[i, "NAME"])
    DataCheck_ <-
      compareDatatypeToSpec(Inp_df[[Field]], SpecDataType, Field)
    Errors_ <- c(Errors_, DataCheck_$Error)
    Warnings_ <- c(Warnings_, DataCheck_$Warning)
  }
  #Check whether data fields have prohibited values
  for (i in 1:nrow(Inp_)) {
    ProhibitSpec <- unlist(Inp_[i, "PROHIBIT"])
    Field <- unlist(Inp_[i, "NAME"])
    Errors_ <- c(Errors_,
                 checkValues(Inp_df[[Field]], ProhibitSpec, Field))
  }
  #Check whether data fields have unlikely values
  for (i in 1:nrow(Inp_)) {
    UnlikelySpec <- unlist(Inp_[i, "UNLIKELY"])
    Field <- unlist(Inp_[i, "NAME"])
    Warnings_ <- c(Warnings_,
                   checkValues(Inp_df[[,Field]], UnlikelySpec, Field))
  }
  #Check whether data fields have unlikely values
  for (i in 1:nrow(Inp_)) {
    UnlikelySpec <- unlist(Inp_[i, "UNLIKELY"])
    Field <- unlist(Inp_[i, "NAME"])
    Warnings_ <- c(Warnings_,
                   checkValues(Inp_df[[,Field]], UnlikelySpec, Field))
  }
  #Return the result
  return(list(Errors = Errors_, Warnings = Warnings_))
}


#DEFINE A FUNCTION WHICH CHECKS DATA VALUES AGAINST A CONDITION
#==============================================================
#' Check values against conditions.
#' 
#' \code{checkValues} checks whether a data vector contains any elements that
#' match a set of conditions.
#' 
#' This function checks whether any of the values in a data vector match one or
#' more conditions. The conditions are specified in a character vector where
#' each element is either "NA" (to match for the existence of NA values) or a
#' character representation of a valid R comparison expression for comparing
#' each element with a specified value (e.g. "< 0", "> 1", "!= 10").
#' 
#' @param Data_ A vector of data of type integer, double, character, or logical.
#' @param Conditions_ A character vector of valid R comparison expressions or an
#'   empty vector if there are no conditions.
#' @param DataName A string identifying the field name of the data being
#'   compared (used for composing message identifying non-compliant fields).
#' @return A character vector of messages which identify the data field and the
#'   condition that is not met. A zero-length vector is returned if none of the
#'   conditions are met.
checkValues <- function(Data_, Conditions_, DataName) {
  if (length(Conditions_) == 0) {
    return(character(0))
  }
  makeMessage <- function(Cond) {
    paste0("Data in field '", DataName,
           "' includes values matching condition (",
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


#DEFINE A FUNCTION WHICH CHECKS DATA TYPES
#=========================================
#' Compare data type with specification.
#' 
#' \code{compareDatatypeToSpec} checks whether the data type of a data vector is
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
compareDatatypeToSpec <- function(Data_, Type, DataName) {
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


#DEFINE A FUNCTION TO LOAD AN INPUT FILE
#=======================================
#' Load input file into datastore.
#' 
#' \code{loadInputFile} loads the data contained in an input file into the
#' datastore.
#' 
#' This function loads the data contained in an input file into the datastore.
#' The function calls the 'checkInputFile' function to check for any errors and
#' if not then copies the data into the datastore. It calls the 'readFromTable'
#' function to create an index to match the data in the file with the geographic
#' ordering in the relevant datastore table. It calls the 'writeToTable'
#' function to initialize the dataset with the specified attributes and to write
#' the data to the table using the index to put it in the correct positions.
#' 
#' @param Module A module object. A module is an environment which contains 
#'   specified components with specified names.
#' @param InputName A string identifying the input name. A module may specify 
#'   that any number of scenario input files be loaded. These inputs are 
#'   specified in the 'Inp' component of the module. Each input is described by 
#'   a separate named component. This argument is the name of the component.
#' @return None. A message is written to the run log.
loadInputFile <- function(Module, InputName) {
  Inp_ <- Module$Inp[[InputName]]
  FileName <- Inp_$File
  InputPath <- paste("inputs", Inp_$File, sep = "/")
  InputCheck_ <- checkInputFile(Module, InputName)
  if (length(InputCheck_$Errors) > 0) {
    Message <- paste("Errors in", InputName, "file.",
                     "Correct and check file before attempting to load.")
    writeLog(Message)
    stop(Message)
  } else {
    #Load the data
    Inp_df <- read.csv(InputPath, as.is = TRUE)
    #Add the data to the datastore
    GeoLvl <- Inp_$GeoLvl
    for (Field in names(Inp_$Fields)) {
      for (Year in E$Years) {
        DsGeo_ <- readFromTable(Table = paste(Year, GeoLvl, sep = "/"),
                                Name = GeoLvl)
        Data_ <- Inp_df[[Field]][Inp_df$Year == Year]
        Idx <- match(Inp_df[["Geo"]][Inp_df$Year == Year], DsGeo_)
        if (Inp_$Fields[[Field]]$TYPE == "character") {
          MaxNchar <- max(nchar(Data_))
        } else {
          MaxNchar <- 0
        }
        writeToTable(
          Data = Data_,
          Table = paste(Year, GeoLvl, sep = "/"),
          Name = Field,
          Index = Idx,
          NAVALUE = Inp_$Fields[[Field]]$NAVALUE,
          UNITS = Inp_$Fields[[Field]]$UNITS,
          TYPE = Inp_$Fields[[Field]]$TYPE,
          SIZE = MaxNchar,
          PROHIBIT = Inp_$Fields[[Field]]$PROHIBIT
        )
      }
    }
    Message <-
      paste("Data in", InputName, "file added to datastore.")
    writeLog(Message)
  }
}


#DEFINE A FUNCTION TO CHECK PRESENCE OF MODULE DATA DEPENDENCIES IN THE DATASTORE
#================================================================================
#' Check module data dependencies.
#' 
#' \code{checkModuleDependencies} checks if datastore contains data required by
#' module.
#' 
#' This function checks whether the datastore contains the data needed for a
#' module to run. The module specifications identify all of the datasets
#' required to run a module including the dataset name, the name of the table
#' where the dataset is located, and the data attributes that affect whether the
#' module is likely to run correctly (i.e. TYPE, PROHIBIT), and the attribute
#' which determines whether the measurement units are consistent (UNITS).
#' 
#' @param ModuleName A string identifying the name of a module object.
#' @param Year A string identifying the model run year.
#' @return A list having 2 components, Errors and Warnings. Each component is a 
#'   vector of error and warning messages respectively. If their lengths are 0, 
#'   there are no errors or warnings.
checkModuleDependencies <- function(ModuleName, Year) {
  Module <- get(ModuleName)
  Tables_ <- names(Module$Get)
  Errors_ <- character(0)
  Warnings_ <- character(0)
  for (Table in Tables_) {
    Datasets_ <- names(Module$Get[[Table]])
    for (Dataset in Datasets_) {
      DataName <- paste(Year, Table, Dataset, sep = "/")
      if (!(DataName %in% E$Datastore[["groupname"]])) {
        #If the dataset does not exist, flag an error
        Message <- paste0(
          "Dataset ", DataName, " requested by ",
          ModuleName, " is not present in the datastore."
        )
        Errors_ <- c(Errors_, Message)
      } else {
        #If the dataset does exist, check the specifications
        DatastoreSpec <-
          E$Datastore[["attributes"]][E$Datastore[["groupname"]] == DataName][[1]]
        ModuleSpec <- Module$Get[[Table]][[Dataset]]
        if (ModuleSpec$TYPE != DatastoreSpec$TYPE) {
          Message <- paste0(
            "TYPE mismatch for ", DataName,
            ". Module ", ModuleName, "asks for TYPE = ",
            ModuleSpec$TYPE, ". Datastore contains TYPE = ",
            DatastoreSpec$TYPE, "."
          )
          Errors_ <- c(Errors_, Message)
        }
        if (ModuleSpec$UNITS != DatastoreSpec$UNITS) {
          Message <- paste0(
            "UNITS mismatch for ", DataName,
            ". Module ", ModuleName, "asks for UNITS = ",
            ModuleSpec$UNITS, ". Datastore contains UNITS = ",
            DatastoreSpec$UNITS, "."
          )
          Warnings_ <- c(Warnings_, Message)
        }
        if (!all(ModuleSpec$PROHIBIT %in% DatastoreSpec$PROHIBIT)) {
          MissingIdx <-
            which(!(ModuleSpec$PROHIBIT %in% DatastoreSpec$PROHIBIT))
          Missing <-
            paste(ModuleSpec$PROHIBIT[MissingIdx], collapse = " & ")
          Message <- paste0(
            "PROHIBIT mismatch for ", DataName,
            ". Module ", ModuleName, " specifies '", Missing,
            "' as prohibited values but the datastore does not."
          )
          Errors_ <- c(Errors_, Message)
        }
      }
    }
  }
  list(Errors = Errors_, Warnings = Warnings_)
}


#DEFINE A FUNCTION TO CREATE AN INDEX FOR READING AND WRITING TO DATASTORE
#=========================================================================
#' Create datastore index.
#' 
#' \code{createIndex} creates an index for reading or writing module data to the
#' datastore.
#' 
#' This function creates indexing functions with return an index to positions in
#' datasets which correspond to positions in an index field of a table. For
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
createIndex <- function(Year, TableName, IndexField) {
  if (file.path(Year, TableName, IndexField) %in% E$Datastore$groupname) {
    ValsToIndexBy <-
      readFromTable(file.path(Year, TableName), IndexField)
    return(function(IndexVal) {
      which(ValsToIndexBy == IndexVal)
    })
  } else {
    XRefTable <- file.path(Year, IndexField)
    XRefValues <- readFromTable(XRefTable, TableName)
    names(XRefValues) <- readFromTable(XRefTable, IndexField)
    ValsToIndexBy <-
      readFromTable(file.path(Year, TableName), TableName)
    return(function(IndexVal) {
      which(ValsToIndexBy == XRefValues[IndexVal])
    })
  }
}

#DEFINE A FUNCTION TO RUN A MODULE
#=================================
#' Run a module.
#' 
#' \code{runModule} runs a model module.
#' 
#' This function runs a module for  a specified year.
#' 
#' @param ModuleName A string identifying the name of a module object.
#' @param Year A string identifying the run year.
#' @return None. The function writes results to the specified locations in the
#'   datastore.
runModule <- function(ModuleName, Year) {
  #Log and print starting message
  Message <- paste("Starting module", ModuleName)
  writeLog(Message)
  print(Message)
  #Load the module and create a working environment (Module)
  load(paste0("modules/", ModuleName, ".RData"))
  Module <- get(ModuleName)
  #Identify the input tables, datasets, and functions to create indexes
  InTables_ <- names(Module$Get)
  InDatasets_ <-
    lapply(as.list(InTables_), function(x)
      names(Module$Get[[x]]))
  names(InDatasets_) <- InTables_
  #Identify the output tables and datasets
  OutTables_ <- names(Module$Set)
  OutDatasets_ <-
    lapply(as.list(OutTables_), function(x)
      names(Module$Set[[x]]))
  names(OutDatasets_) <- OutTables_
  #Creating indexes
  Message <- "Creating indexes"
  writeLog(Message)
  print(Message)
  InIdxFunc_ <- sapply(InTables_, function(x) {
    createIndex(Year = Year, Table = x, IndexField = Module$RunBy)
  })
  OutIdxFunc_ <- sapply(OutTables_, function(x) {
    createIndex(Year = Year, Table = x, IndexField = Module$RunBy)
  })
  #Initialize output datasets
  for (Table in OutTables_) {
    for (Dataset in OutDatasets_[[Table]]) {
      initDataset(
        Table = file.path(Year, Table), Name = Dataset,
        NAVALUE = Module$Set[[Table]][[Dataset]][["NAVALUE"]],
        UNITS = Module$Set[[Table]][[Dataset]][["UNITS"]],
        TYPE = Module$Set[[Table]][[Dataset]][["TYPE"]],
        SIZE = Module$Set[[Table]][[Dataset]][["SIZE"]],
        PROHIBIT = Module$Set[[Table]][[Dataset]][["PROHIBIT"]]
      )
    }
  }
  #Iterate through each geographic area: load data, run model, save results
  RunByNames <-
    readFromTable(file.path(Year, Module$RunBy), Module$RunBy)
  for (Name in RunByNames) {
    #Load all inputs
    Message <- paste("Reading data for", Name)
    writeLog(Message)
    print(Message)
    for (Table in InTables_) {
      Idx_ <- InIdxFunc_[[Table]](Name)
      for (Dataset in InDatasets_[[Table]]) {
        assign(Dataset,
               readFromTable(file.path(Year, Table), Dataset, Idx_),
               envir = Module)
      }
      rm(Idx_)
    }
    #Run model
    Message <- paste("Running models for", Name)
    writeLog(Message)
    print(Message)
    Module$main()
    #Save all outputs
    Message <- paste("Writing results for", Name)
    writeLog(Message)
    print(Message)
    for (Table in OutTables_) {
      Idx_ <- OutIdxFunc_[[Table]](Name)
      for (Dataset in OutDatasets_[[Table]]) {
        writeToTable(
          Data = Module[[Dataset]],
          Table = file.path(Year, Table), Name = Dataset,
          Index = Idx_,
          NAVALUE = Module$Set[[Table]][[Dataset]][["NAVALUE"]],
          UNITS = Module$Set[[Table]][[Dataset]][["UNITS"]],
          TYPE = Module$Set[[Table]][[Dataset]][["TYPE"]],
          SIZE = Module$Set[[Table]][[Dataset]][["SIZE"]],
          PROHIBIT = Module$Set[[Table]][[Dataset]][["PROHIBIT"]]
        )
      }
    }
  }
  #Remove the module
  rm(Module)
  rm(list = ModuleName)
  gc()
  gc()
} 


