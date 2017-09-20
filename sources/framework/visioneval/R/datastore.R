#===========
#datastore.R
#===========

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
#' each table and dataset. The listing is stored in the model state file
#' (ModelState.Rda) as the "Datastore" component. This function is run whenever
#' new groups, tables, or datasets are created in the datastore to always keep
#' the listing in the model state file current.
#'
#' @return TRUE if the listing is successfully read from the datastore and
#' written to the model state file.
#' @export
listDatastore <- function() {
  G <- getModelState()
  load(file.path(G$DatastoreName, "DatastoreListing.Rda"))
  DatastoreListing_df <-
    data.frame(DatastoreListing_ls[1:3], stringsAsFactors = FALSE)
  DatastoreListing_df$attributes <- DatastoreListing_ls$attributes
  setModelState(list(Datastore = DatastoreListing_df))
  TRUE
}


#ADD TO THE DATASTORE CONTENTS LISTING
#=====================================
#' Add to the datastore contents listing
#'
#' \code{addListing} adds the information for a new datastore component
#' (i.e. table collection, table, dataset) to the list which keeps track of
#' datastore contents.
#'
#' A list (DatastoreListing_ls) stored in the 'DatastoreListing.Rda' file keeps
#' track of the contents of the datastore. This list has 4 named components as
#' follows:
#' 1) group - an ordered vector of the names of directory paths where the
#' respective components are located. The directory paths use the forward slash
#' (/) to separate directories. The root directory of the datastore is
#' represented by a leading forward slash.
#' 2) name - a vector of names of the datastore component corresponding the
#' group names.
#' 3) groupname - a vector of the complete path names to each datastore
#' component in the datastore. This is a concatenation of the 'group' and 'name'
#' parts.
#' 4) attributes - list of the attributes of each datastore component where
#' each element is a list.
#' This listing is updated whenever a new component is added to the datastore.
#' The information for that component is concatenated to end of each of the
#' elements of the datastore listing.
#'
#' @param DatastoreListing_ls a list having the elements described.
#' @param DataListing_ls a list having four elements that correspond to the
#' elements of the DatastoreListing_ls.
#' @return a list having the same structure as DatastoreListing_ls with the
#' data in DataListing_ls added to it.
#' @export
addListing <-
  function(DatastoreListing_ls, DataListing_ls) {
    for (i in 1:3) {
      DatastoreListing_ls[[i]] <-
        c(DatastoreListing_ls[[i]], DataListing_ls[[i]])
    }
    DatastoreListing_ls[[4]] <-
      c(DatastoreListing_ls[[4]], list(DataListing_ls[[4]]))
    DatastoreListing_ls
  }


#INITIALIZE DATASTORE
#====================
#' Initialize Datastore.
#'
#' \code{initDatastore} creates datastore with starting structure.
#'
#' This function creates the datastore for the model run with the initial
#' structure. The datastore is a nested set of directories and files. The
#' top directory that is named according to the 'DatastoreName' property in the
#' 'run_parameters.json' file. The function creates this directory and several
#' subdirectories including one named 'Global' and one for each year identified
#' in the 'Years' property of the 'run_parameters.json' file. If the datastore
#' directory already exists, the function will remove it and all of its contents
#' before recreating it.
#'
#' @return TRUE if datastore initialization is successful. Calls the
#' listDatastore function which adds a listing of the datastore contents to the
#' model state file.
#' @export
#' @import filesstrings
initDatastore <- function() {
  G <- getModelState()
  DatastoreName <- G$DatastoreName
  #If datastore exists, delete
  if (file.exists(DatastoreName)) {
    dir.remove(DatastoreName)
  }
  #Create datastore
  dir.create(DatastoreName)
  #Initialize the DatastoreListing
  DatastoreListing_ls <-
    list(
      group = "/",
      name = "",
      groupname = "",
      attributes = list(NA)
    )
  #Create global group which stores data that is constant for all geography and
  #all years
  dir.create(file.path(DatastoreName, "Global"))
  DatastoreListing_ls <-
    addListing(DatastoreListing_ls,
               list(group = "/",
                    name = "Global",
                    groupname = "Global",
                    attributes = list(NA)
                    ))
  #Create groups for years
  Years <- getYears()
  for (year in Years) {
    YearGroup <- year
    dir.create(file.path(DatastoreName, YearGroup))
    DatastoreListing_ls <-
      addListing(DatastoreListing_ls,
                 list(group = "/",
                      name = YearGroup,
                      groupname = YearGroup,
                      attributes = list(NA)
                 ))
  }
  #Save the DatastoreListing_df and update the model state file
  save(DatastoreListing_ls,
       file = file.path(DatastoreName, "DatastoreListing.Rda"))
  listDatastore()
  TRUE
}
#initDatastore()

#INITIALIZE TABLE IN DATASTORE
#=============================
#' Initialize table in datastore.
#'
#' \code{initTable} initializes a table in the datastore.
#'
#' A table in the datastore is a directory which contains one or more R binary
#' files. Each file is a dataset that is a vector or list. The length of each
#' vector or list must be the same. Thus a table is much like an R data frame
#' which is a list containing equal length vectors that may have different
#' types. If the dataset is a list, then it is like a list column in a
#' dataframe. A table is initialized in the datastore by creating a directory
#' whose name is the table name. The DatastoreListing_ls is updated to include
#' the 'group', 'name', 'groupname', and 'attributes' information for the table.
#' The 'attributes' listing for the table includes one element (LENGTH) that is
#' the length that each dataset in the table must have.
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
initTable <- function(Table, Group, Length) {
  G <- getModelState()
  DatastoreName <- G$DatastoreName
  #Create a directory for the table
  dir.create(file.path(DatastoreName, Group, Table))
  #Update the DatastoreListing
  load(file.path(DatastoreName, "DatastoreListing.Rda"))
  DatastoreListing_ls <-
    addListing(DatastoreListing_ls,
               list(group = paste0("/", Group),
                    name = Table,
                    groupname = paste(Group, Table, sep = "/"),
                    attributes = list(LENGTH = Length)
               ))
  #Save the DatastoreListing_df and update the model state file
  save(DatastoreListing_ls,
       file = file.path(DatastoreName, "DatastoreListing.Rda"))
  listDatastore()
}
#initTable("Azone", "2010", 3)

#INITIALIZE A DATASET IN A TABLE
#===============================
#' Initialize dataset in datastore table.
#'
#' \code{initDataset} initializes a dataset in a table.
#'
#' This function initializes a dataset which must be done before data can be
#' stored. The function writes an empty vector to the table directory specified
#' in the 'TABLE' element of the 'Spec_ls' argument. The type of the vector is
#' determined by the 'TYPE' element of the 'Spec_ls' argument. The vector is
#' saved to the table directory with the prefix of the file name being the
#' 'NAME' property of the 'Spec_ls' argument and the suffix being '.Rda'.
#'
#' @param Spec_ls a list containing the standard module specifications
#'   described in the model system design documentation.
#' @param Group a string representation of the name of the top-level
#' subdirectory the table is to be created in (i.e. either 'Global' or the name
#' of the year).
#' @return TRUE if dataset is successfully initialized. If the identified table
#' does not exist, the function throws an error.
#' @export
initDataset <- function(Spec_ls, Group) {
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
  #Update the DatastoreListing
  load(file.path(G$DatastoreName, "DatastoreListing.Rda"))
  DatastoreListing_ls <-
    addListing(DatastoreListing_ls,
               list(group = paste0("/", Table),
                    name = Spec_ls$NAME,
                    groupname = paste(Table, Spec_ls$NAME, sep = "/"),
                    attributes = Spec_ls
               ))
  #Save the DatastoreListing_df and update the model state file
  save(DatastoreListing_ls,
       file = file.path(G$DatastoreName, "DatastoreListing.Rda"))
  listDatastore()
  TRUE
}
#source("data/test_spec.R")
#initDataset(TestSpec_ls, "2010")


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
#' @param DstoreLoc a string representation of the file path of the datastore.
#' NULL if the datastore is the directory identified in the 'DatastoreName'
#' property of the model state file.
#' @param Index A numeric vector identifying the positions the data is to be
#'   written to. NULL if the entire dataset is to be read.
#' @return A vector of the same type stored in the datastore and specified in
#'   the TYPE attribute.
#' @export
readFromTable <- function(Name, Table, Group, DstoreLoc = NULL, Index = NULL) {
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
  if (is.null(DstoreLoc)) {
    G <- readModelState()
  } else {
    G <- getModelListing(DstoreRef = DstoreLoc)
  }
  #Check that dataset exists to read from
  DatasetExists <- checkDataset(Name, Table, Group, G$Datastore)
  if (DatasetExists) {
    FileName <- paste(Name, "Rda", sep = ".")
    DatasetPath <- file.path(G$DatastoreName, Group, Table, FileName)
  } else {
    Message <-
      paste("Dataset", Name, "in table", Table, "in group", Group, "doesn't exist.")
    stop(Message)
  }
  #Load the dataset
  load(DatasetPath)
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
  #Report out results
  Message <- paste0("Read data ", file.path(Group, Table, Name))
  #writeLog(Message)
  as.vector(Dataset)
}
#readFromTable("Azone", "Azone", "2010")
#readFromTable("Azone", "Azone", "2010", Index = 1:2)


#WRITE TO TABLE
#==============
#' Write to table.
#'
#' \code{writeToTable} writes data to table and initializes dataset if needed.
#'
#' This function writes a dataset file to a table directory. It initializes the
#' dataset if the dataset does not exist. Enables data to be written to specific
#' location indexes in the dataset.
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
  #Read in the saved dataset
  Dataset <- readFromTable(Name, Table, Group)
  #Convert NA values
  # Data_[is.na(Data_)] <- Spec_ls$NAVALUE
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
      Dataset[Index] <- Data_[Index]
    }
  }
  #Save the dataset
  DatasetName <- paste0(Name, ".Rda")
  save(Dataset, file = file.path(G$DatastoreName, Group, Table, DatasetName))
  TRUE
}
#readFromTable("Azone", "Azone", "2010")
#NewVals_ <- paste0("A", 1:3)
#writeToTable(NewVals_, TestSpec_ls, "2010", Index = NULL)
#readFromTable("Azone", "Azone", "2010")
#Write an uninitialized dataset
#initTable("Bzone", "2010", 10)
#TestSpec_ls$NAME <- "Bzone"
#TestSpec_ls$TABLE <- "Bzone"
#NewVals_ <- paste0("B", 1:10)
#writeToTable(NewVals_, TestSpec_ls, "2010")
#readFromTable("Bzone", "Bzone", "2010")
#TestSpec_ls$NAME <- "Azone"
#NewVals_ <- c("A1", "A1", "A1", "A1", "A2", "A2", "A2", "A3", "A3", "A3")
#writeToTable(NewVals_, TestSpec_ls, "2010")
#readFromTable("Azone", "Bzone", "2010")

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
#AzoneIndex <- createIndex("Azone", "Bzone", "2010")
#Az <- c("A1", "A2", "A3")
#for (az in Az) print(readFromTable("Bzone", "Bzone", "2010", Index = AzoneIndex(az)))


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
  #GetSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Get
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
    if (!is.null(Geo)) {
      idxFun <- createIndex(ModuleSpec_ls$RunBy, Table, DstoreGroup)
      Index <- idxFun(Geo)
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
    #SetSpec_ls <- processModuleSpecs(ModuleSpec_ls)$Set
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
      if (!is.null(Geo)) {
        idxFun <- createIndex(ModuleSpec_ls$RunBy, Table, DstoreGroup)
        Index <- idxFun(Geo)
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
