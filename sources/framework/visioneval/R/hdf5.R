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
#' @param RunYear a string identifying the model year being run. The default is
#' the Year object in the global workspace.
#' @param Geo a string identifying the name of the geographic area to get the
#' data for. For example, if the module is specified to be run by Azone, then
#' Geo would be the name of a particular Azone.
#' @return A list containing all the data sets specified in the module's
#' 'Get' specifications for the identified geographic area.
#' @export
getFromDatastore <- function(ModuleSpec_ls, RunYear, Geo = NULL) {
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
                       getDatasetAttr(Name, Table, RunYear, G$Datastore)$UNITS,
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
      Type <- Spec_ls$TYPE
      if (Group == "Global") DstoreGroup <- "Global"
      if (Group == "Year") DstoreGroup <- Year
      #Make an index to the data
      if (!is.null(Geo)) {
        idxFun <- createIndex(ModuleSpec_ls$RunBy, Table, DstoreGroup)
        index <- idxFun(Geo)
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
          #Modify units spec to reflect units consistent with defaults for
          #datastore
          Spec_ls$UNITS <- attributes(Data_)$UNITS
          writeToTable(Data_, Spec_ls, Group)
        }
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
          SortData_df <- sortGeoTable(YrData_df, Table, Year)
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
