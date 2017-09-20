#================
#initialization.R
#================

#This script defines various functions that are invoked to initialize a model
#run. Several of the functions are also invoked when modules are run.


#INITIALIZE MODEL STATE
#======================
#' Initialize model state.
#'
#' \code{initModelState} loads model run parameters into the model state
#' list in the global workspace and saves as file.
#'
#' This function creates the model state list and loads model run parameters
#' recorded in the 'parameters.json' file into the model state list. It also
#' saves the model state list in a file (ModelState.Rda).
#'
#' @param Dir A string identifying the name of the directory where the global
#' parameters, deflator, and default units files are located. The default value
#' is defs.
#' @param ParamFile A string identifying the name of the global parameters file.
#' The default value is parameters.json.
#' @param DeflatorFile A string identifying the name of the file which contains
#' deflator values by year (e.g. consumer price index). The default value is
#' deflators.csv.
#' @param UnitsFile A string identifying the name of the file which contains
#' default units for complex data types (e.g. currency, distance, speed, etc.).
#' The default value is units.csv.
#' @return TRUE if the model state list is created and file is saved. It creates
#' the model state list and loads parameters recorded in the 'parameters.json'
#' file into the model state lists and saves a model state file.
#' @export
#' @import jsonlite
initModelStateFile <-
  function(Dir = "defs",
           ParamFile = "run_parameters.json",
           DeflatorFile = "deflators.csv",
           UnitsFile = "units.csv") {
  ParamFilePath <- file.path(Dir,  ParamFile)
  DeflatorFilePath <- file.path(Dir, DeflatorFile)
  UnitsFilePath <- file.path(Dir, UnitsFile)
  if (!file.exists(ParamFilePath)) {
    Message <- paste("Missing", ParamFilePath, "file.")
    stop(Message)
  } else {
    ModelState_ls <- fromJSON(ParamFilePath)
    ModelState_ls$LastChanged <- Sys.time()
    ModelState_ls$Deflators <- read.csv(DeflatorFilePath, as.is = TRUE)
    ModelState_ls$Units <- read.csv(UnitsFilePath, as.is = TRUE)
    save(ModelState_ls, file = "ModelState.Rda")
  }
  TRUE
}
#initModelStateFile(Dir = "defs")

#GET MODEL STATE VALUES
#======================
#' Get values from model state list.
#'
#' \code{getModelState} reads components of the list that keeps track of the
#' model state
#'
#' Key variables that are important for managing the model run are stored in a
#' list (ModelState_ls) that is managed in the global environment. This
#' function extracts named components of the list.
#'
#' @param Names_ A string vector of the components to extract from the
#' ModelState_ls list.
#' @param FileName A string that is the file name of the model state file. The
#' default value is ModelState.Rda.
#' @return A list containing the specified components from the model state file.
#' @export
getModelState <- function(Names_ = "All", FileName = "ModelState.Rda") {
  if (file.exists(FileName)) {
    load(FileName)
  }
  if ("ModelState_ls" %in% ls()) State_ls <- get("ModelState_ls")
  if (Names_[1] == "All") {
    return(State_ls)
  } else {
    return(State_ls[Names_])
  }
}


#UPDATE MODEL STATE
#==================
#' Update model state.
#'
#' \code{setModelState} updates the list that keeps track of the model state
#' with list of components to update and resaves in the model state file.
#'
#' Key variables that are important for managing the model run are stored in a
#' list (ModelState_ls) that is in the global workspace and saved in the
#' 'ModelState.Rda' file. This function updates  entries in the model state list
#' with a supplied named list of values, and then saves the results in the file.
#'
#' @param ChangeState_ls A named list of components to change in ModelState_ls
#' @param FileName A string identifying the name of the file that contains
#' the ModelState_ls list. The default name is 'ModelState.Rda'.
#' @return TRUE if the model state list and file are changed.
#' @export
setModelState <-
  function(ChangeState_ls, FileName = "ModelState.Rda") {
    ModelState_ls <- getModelState()
    for (i in 1:length(ChangeState_ls)) {
      ModelState_ls[[names(ChangeState_ls[i])]] <- ChangeState_ls[[i]]
    }
    ModelState_ls$LastChanged <- Sys.time()
    save(ModelState_ls, file = FileName)
    TRUE
  }


#READ MODEL STATE FILE
#=====================
#' Reads values from model state file.
#'
#' \code{readModelState} reads components of the file that saves a copy of the
#' model state
#'
#' The model state is stored in a list (ModelState_ls) that is also saved as a
#' file (ModelState.Rda) whenever the list is updated. This function reads the
#' contents of the ModelState.Rda file.
#'
#' @param Names_ A string vector of the components to extract from the
#' ModelState_ls list.
#' @param FileName A string vector with the full path name of the model state
#' file.
#' @return A list containing the specified components from the model state file.
#' @export
readModelState <- function(Names_ = "All", FileName = "ModelState.Rda") {
  if (file.exists(FileName)) {
    load(FileName)
  }
  if ("ModelState_ls" %in% ls()) State_ls <- get("ModelState_ls")
  if (Names_[1] == "All") {
    return(State_ls)
  } else {
    return(State_ls[Names_])
  }
}


#RETRIEVE YEARS
#==============
#' Retrieve years
#'
#' \code{getYears} reads the Years component from the the model state file.
#'
#' This is a convenience function to make it easier to retrieve the Years
#' component of the model state file. If the Years component includes the base
#' year then order the Years component so that it is first. This ordering is
#' important because some modules calculate future year values by pivoting off
#' of base year values so the base year must be run first.
#'
#' @return A character vector of the model run years.
#' @export
getYears <- function() {
  BaseYear <- unlist(getModelState("BaseYear"))
  Years <- unlist(getModelState("Years"))
  if (BaseYear %in% Years) {
    c(BaseYear, Years[!Years %in% BaseYear])
  } else {
    Years
  }
}


#RETRIEVE DEFAULT UNITS
#======================
#' Retrieve default units for model
#'
#' \code{getUnits} retrieves the default model units for a vector of complex
#' data types.
#'
#' This is a convenience function to make it easier to retrieve the default
#' units for a complex data type (e.g. distance, volume, speed). The default
#' units are the units used to store the complex data type in the datastore.
#'
#' @param Type_ A string vector identifying the complex data type(s).
#' @return A string vector identifying the default units for the complex data
#' type(s) or NA if any of the type(s) are not defined.
#' @export
getUnits <- function(Type_) {
  Units_df <- getModelState()$Units
  Units_ <- Units_df$Units
  names(Units_) <- Units_df$Type
  Result_ <- Units_[Type_]
  if (any(is.na(Result_))) Result_ <- NA
  Result_
}

#getUnits("Bogus")
#getUnits("currency")
#getUnits("area")

#INITIALIZE RUN LOG
#==================
#' Initialize run log.
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
#' @param Suffix A character string appended to the file name for the log file.
#' For example, if the suffix is 'CreateHouseholds', the log file is named
#' 'Log_CreateHouseholds.txt'. The default value is NULL in which case the
#' suffix is the date and time.
#' @return TRUE if the log is created successfully. It creates a log file in the
#'   working directory and identifies the name of the log file in the
#'   model state file.
#' @export
initLog <- function(Suffix = NULL) {
  ModelState_ls <- getModelState()
  LogInitTime <- gsub(" ", "_", as.character(Sys.time()))
  if (!is.null(Suffix)) {
    LogFile <- paste0("Log_", Suffix, ".txt")
  } else {
    LogFile <- paste0("Log_", gsub(":", "_", LogInitTime), ".txt")
  }
  sink(LogFile, append = TRUE)
  cat(ModelState_ls$Scenario)
  cat("\n")
  cat(ModelState_ls$Description)
  cat("\n")
  cat(LogInitTime)
  cat("\n\n")
  sink()
  setModelState(list(LogFile = LogFile))
  TRUE
}
#initLog()


#WRITE TO LOG
#============
#' Write to log.
#'
#' \code{writeLog} writes a message to the run log.
#'
#' This function writes a message in the form of a string to the run log. It
#' logs the time as well as the message to the run log.
#'
#' @param Msg A character string.
#' @param Print logical (default: FALSE). If True Msg will be printed in
#' additon to being added to log
#' @return TRUE if the message is written to the log uccessfully.
#' It appends the time and the message text to the run log.
#' @export
writeLog <- function(Msg = "", Print = FALSE) {
  LogFile <- unlist(getModelState("LogFile"))
  Con <- file(LogFile, open = "a")
  Time <- as.character(Sys.time())
  Content <- paste(Time, ":", Msg, "\n")
  writeLines(Content, Con)
  close(Con)
  if (Print) {
    print(gsub(" \n", "", Content))
  }
}


#LOAD SAVED DATASTORE
#====================
#' Load saved datastore.
#'
#' \code{loadDatastore} copy an existing saved datastore and write information
#' to run environment.
#'
#' This function copies a saved datastore as the working datastore attributes
#' the global list with related geographic information. This function enables
#' scenario variants to be built from a constant set of starting conditions.
#'
#' @param FileToLoad A string identifying the full path name to the saved
#'   datastore. Path name can either be relative to the working directory or
#'   absolute.
#' @param Dir A string identifying the path of the geography definition file (GeoFile),
#'   default to 'defs' relative to the working directory
#' @param GeoFile A string identifying the name of the geography definition file
#'   (see 'readGeography' function) that is consistent with the saved datastore.
#'   The geography definition file must be located in the 'defs' directory.
#' @param SaveDatastore A logical identifying whether an existing datastore
#'   will be saved. It is renamed by appending the system time to the name. The
#'   default value is TRUE.
#' @return TRUE if the datastore is loaded. It copies the saved datastore to
#'   working directory as 'datastore.h5'. If a 'datastore.h5' file already
#'   exists, it first renames that file as 'archive-datastore.h5'. The function
#'   updates information in the model state file regarding the model geography
#'   and the contents of the loaded datastore. If the stored file does not exist
#'   an error is thrown.
#' @export
loadDatastore <- function(FileToLoad, Dir="defs/", GeoFile, SaveDatastore = TRUE) {
  GeoFile <- file.path(Dir, GeoFile)
  G <- getModelState()
  #If data store exists, rename
  DatastoreName <- G$DatastoreName
  if (file.exists(DatastoreName) & SaveDatastore) {
    TimeString <- gsub(" ", "_", as.character(Sys.time()))
    ArchiveDatastoreName <-
      paste0(unlist(strsplit(DatastoreName, "\\."))[1],
            "_", TimeString, ".",
            unlist(strsplit(DatastoreName, "\\."))[2])
    ArchiveDatastoreName <- gsub(":", "-", ArchiveDatastoreName)
    file.copy(DatastoreName, ArchiveDatastoreName)
  }
  if (file.exists(FileToLoad)) {
    file.copy(FileToLoad, DatastoreName)
    Geo_df <- read.csv(GeoFile, colClasses = "character")
    Update_ls <- list()
    Update_ls$BzoneSpecified <- !all(is.na(Geo_df$Bzone))
    Update_ls$CzoneSpecified <- !all(is.na(Geo_df$Czone))
    Update_ls$Geo_df <- Geo_df
    setModelState(Update_ls)
    listDatastore()
  } else {
    Message <- paste("File", FileToLoad, "not found.")
    writeLog(Message)
    stop(Message)
  }
  TRUE
}


#READ GEOGRAPHIC SPECIFICATIONS
#==============================
#' Read geographic specifications.
#'
#' \code{readGeography} reads the geographic specifications file for the
#' model.
#'
#' This function manages the reading and error checking of geographic
#' specifications for the model. It calls the checkGeography function to check
#' for errors in the specifications. The checkGeography function reads in the
#' file and checks for errors. It returns a list of any errors that are found
#' and a data frame containing the geographic specifications. If errors are
#' found, the functions writes the errors to a log file and stops model
#' execution. If there are no errors, the function adds the geographic in the
#' geographic specifications file, the errors are written to the log file and
#' execution stops. If no errors are found, the geographic specifications are
#' added to the model state file.
#'
#' @param Dir A string identifying the path to the geographic
#'   specifications file. Note: don't include the final separator in the
#'   path name 'e.g. not defs/'.
#' @param GeoFile A string identifying the name of the geographic
#'   specifications file. This is a csv-formatted text file which contains
#'   columns named 'Azone', 'Bzone', 'Czone', and 'Marea'. The 'Azone' column
#'   must have zone names in all rows. The 'Bzone' and 'Czone' columns can be
#'   unspecified (NA in all rows) or may have have unique names in every row.
#'   The 'Marea' column (referring to metropolitan areas) identifies
#'   metropolitan areas corresponding to the most detailed level of specified
#'   geography (or 'None' no metropolitan area occupies any portion of the
#'   zone.
#' @return The value TRUE is returned if the function is successful at reading
#'   the file and the specifications are consistent. It stops if there are any
#'   errors in the specifications. All of the identified errors are written to
#'   the run log. A data frame containing the file entries is added to the
#'   model state file as Geo_df'.
#' @export
readGeography <- function(Dir = "defs", GeoFile = "geo.csv") {
  #Check for errors in the geographic definitions file
  CheckResults_ls <- checkGeography(Dir, GeoFile)
  #Notify if any errors
  Messages_ <- CheckResults_ls$Messages
  if (length(Messages_) > 0) {
    for (message in Messages_) {
      writeLog(message)
    }
    stop(paste0("One or more errors in ", GeoFile, ". See log for details."))
  } else {
    writeLog("Geographical indices successfully read.")
  }
  #Update the model state file
  setModelState(CheckResults_ls$Update)
  TRUE
}


#CHECK GEOGRAPHIC SPECIFICATIONS
#===============================
#' Check geographic specifications.
#'
#' \code{checkGeography} checks geographic specifications file for
#' model.
#'
#' This function reads the file containing geographic specifications for the
#' model and checks the file entries to determine whether they are internally
#' consistent. This function is called by the readGeography function.
#'
#' @param Directory A string identifying the path to the geographic
#'   specifications file.
#' @param Filename A string identifying the name of the geographic
#'   specifications file.
#' @return A list having two components. The first component, 'Messages',
#' contains a string vector of error messages. It has a length of 0 if there are
#' no error messages. The second component, 'Update', is a list of components to
#' update in the model state file. The components of this list include: Geo, a
#' data frame that contains the geographic specifications; BzoneSpecified, a
#' logical identifying whether Bzones are specified; and CzoneSpecified, a
#' logical identifying whether Czones are specified.
#' @export
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
  CzoneSpecified <- !all(is.na(Geo_df$Czone))
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
  Update_ls <- list(Geo_df = Geo_df, BzoneSpecified = BzoneSpecified,
                    CzoneSpecified = CzoneSpecified)
  list(Messages = Messages_, Update = Update_ls)
}


#INITIALIZE DATASTORE GEOGRAPHY
#==============================
#' Initialize datastore geography.
#'
#' \code{initDatastoreGeography} initializes tables and writes datasets to the
#' datastore which describe geographic relationships of the model.
#'
#' This function writes tables to the datastore for each of the geographic
#' levels. These tables are then used during a model run to store values that
#' are either specified in scenario inputs or that are calculated during a model
#' run. The function populates the tables with cross-references between
#' geographic levels. The function reads the model geography (Geo_df) from the
#' model state file. Upon successful completion, the function calls the
#' listDatastore function to update the datastore listing in the global list.
#'
#' @return The function returns TRUE if the geographic tables and datasets are
#'   sucessfully written to the datastore.
#' @export
initDatastoreGeography <- function() {
  G <- getModelState()
  #Make lists of zone specifications
  Mareas_ <- unique(G$Geo_df$Marea)
  MareaSpec_ls <- list(MODULE = "visioneval",
                       NAME = "Marea",
                       TABLE = "Marea",
                       TYPE = "character",
                       UNITS = "",
                       NAVALUE = "NA",
                       PROHIBIT = "",
                       ISELEMENTOF = "",
                       SIZE = max(nchar(Mareas_)),
                       LENGTH = length(Mareas_))
  Azones_ <- unique(G$Geo_df$Azone)
  AzoneSpec_ls <- list(MODULE = "visioneval",
                       NAME = "Azone",
                       TABLE = "Azone",
                       TYPE = "character",
                       UNITS = "",
                       NAVALUE = "NA",
                       PROHIBIT = "",
                       ISELEMENTOF = "",
                       SIZE = max(nchar(Azones_)))
  if(G$BzoneSpecified) {
    Bzones_ <- unique(G$Geo_df$Bzone)
    BzoneSpec_ls <- list(MODULE = "visioneval",
                         NAME = "Bzone",
                         TABLE = "Bzone",
                         TYPE = "character",
                         UNITS = "",
                         NAVALUE = "NA",
                         PROHIBIT = "",
                         ISELEMENTOF = "",
                         SIZE = max(nchar(Bzones_)))
  }
  if(G$CzoneSpecified) {
    Czones_ <- unique(G$Geo_df$Czone)
    CzoneSpec_ls <- list(MODULE = "visioneval",
                         NAME = "Czone",
                         TABLE = "Czone",
                         TYPE = "character",
                         UNITS = "",
                         NAVALUE = "NA",
                         PROHIBIT = "",
                         ISELEMENTOF = "",
                         SIZE = max(nchar(Czones_)))
  }
  #Initialize geography tables and zone datasets
  GroupNames <- c("Global", G$Years)
  for (GroupName in GroupNames) {
    initTable(Table = "Region", Group = GroupName, Length = 1)
    initTable(Table = "Azone", Group = GroupName, Length = length(Azones_))
    initDataset(AzoneSpec_ls, Group = GroupName)
    initTable(Table = "Marea", Group = GroupName, Length = length(Mareas_))
    initDataset(MareaSpec_ls, Group = GroupName)
    if(G$BzoneSpecified) {
      initTable(Table = "Bzone", Group = GroupName, Length = length(Bzones_))
      initDataset(BzoneSpec_ls, Group = GroupName)
    }
    if(G$CzoneSpecified) {
      initTable(Table = "Czone", Group = GroupName, Length = length(Czones_))
      initDataset(CzoneSpec_ls, Group = GroupName)
    }
  }
  rm(GroupName)
  #Add zone names to zone tables
  for (GroupName in GroupNames) {
    if (!G$BzoneSpecified & !G$CzoneSpecified) {
      #Write to Azone table
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Group = GroupName, Index = NULL)
      MareaSpec_ls$TABLE = "Azone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Group = GroupName, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Group = GroupName, Index = NULL)
    }
    if (G$BzoneSpecified & !G$CzoneSpecified) {
      #Write to Bzone table
      writeToTable(G$Geo_df$Bzone, BzoneSpec_ls, Group = GroupName, Index = NULL)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Group = GroupName, Index = NULL)
      MareaSpec_ls$TABLE = "Bzone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Group = GroupName, Index = NULL)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, AzoneSpec_ls, Group = GroupName, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Group = GroupName, Index = NULL)
    }
    if (G$CzoneSpecified) {
      #Write to Czone table
      writeToTable(G$Geo_df$Czone, CzoneSpec_ls, Group = GroupName, Index = NULL)
      BzoneSpec_ls$TABLE = "Czone"
      BzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Bzone, BzoneSpec_ls, Group = GroupName, Index = NULL)
      AzoneSpec_ls$TABLE = "Czone"
      AzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Group = GroupName, Index = NULL)
      MareaSpec_ls$TABLE = "Czone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Group = GroupName, Index = NULL)
      #Write to Bzone table
      Geo_df <- G$Geo_df[!duplicated(G$Geo_df$Bzone), c("Azone", "Bzone")]
      BzoneSpec_ls$TABLE = "Bzone"
      BzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Bzone, BzoneSpec_ls, Group = GroupName, Index = NULL)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Azone, AzoneSpec_ls, Group = GroupName, Index = NULL)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, AzoneSpec_ls, Group = GroupName, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Group = GroupName, Index = NULL)
    }
  }
  #Write to log that complete
  Message <- "Geography sucessfully added to datastore."
  writeLog(Message)
  TRUE
}


#LOAD MODEL PARAMETERS
#=====================
#' Load model global parameters file into datastore.
#'
#' \code{loadModelParameters} reads the 'model_parameters.json' file and
#' stores the contents in the 'Global/Model' group of the datastore.
#'
#' This function reads the 'model_parameters.json' file in the 'defs' directory
#' which contains parameters specific to a model rather than to a module. These
#' area parameters that may be used by any module. Parameters are specified by
#' name, value, and data type. The function creates a 'Model' group in the
#' 'Global' group and stores the values of the appropriate type in the 'Model'
#' group.
#'
#' @param ModelParamFile A string identifying the name of the parameter file.
#' The default value is 'model_parameters.json'.
#' @return The function returns TRUE if the model parameters file exists and
#' its values are sucessfully written to the datastore.
#' @export
loadModelParameters <- function(ModelParamFile = "model_parameters.json") {
  G <- getModelState()
  writeLog("Loading model parameters file.")
  ParamFile <- file.path("defs", ModelParamFile)
  if (!file.exists(ParamFile)) {
    ErrorMsg <- "Model parameters file (model_parameters.json) is missing."
    writeLog(ErrorMsg)
    return(FALSE)
  } else {
    Param_df <- fromJSON(ParamFile)
    Group <- "Global"
    initTable(Table = "Model", Group = "Global", Length = 1)
    for (i in 1:nrow(Param_df)) {
      Type <- Param_df$TYPE[i]
      if (Type == "character") {
        Value <- Param_df$VALUE[i]
      } else {
        Value <- as.numeric(Param_df$VALUE[i])
      }
      Spec_ls <-
        list(NAME = Param_df$NAME[i],
             TABLE = "Model",
             TYPE = Type,
             UNITS = Param_df$UNITS[i],
             NAVALUE = ifelse(Param_df$TYPE[i] == "character", "NA", -9999),
             SIZE = ifelse(Param_df$TYPE[i] == "character",
                           nchar(Param_df$VALUE[i]),
                           0),
             LENGTH = 1,
             MODULE = G$Model)
      writeToTable(Value, Spec_ls, Group = "Global", Index = NULL)
      rm(Spec_ls, Type, Value)
    }
  }
}


#PARSE MODEL SCRIPT
#==================
#' Parse model script.
#'
#' \code{parseModel}Function reads and parses the model script to identify the
#' sequence of module calls and the associated call arguments.
#'
#' This function reads in the model run script and parses the script to
#' identify the sequence of module calls. It extracts each call to 'runModule'
#' and identifies the values assigned to the function arguments. It creates a
#' list of the calls with their arguments in the order of the calls in the
#' script.
#'
#' @param FilePath A string identifying the relative or absolute path to the
#'   model run script is located.
#' @param TestMode A logical identifying whether the function is to run in test
#' mode. When in test mode the function returns the parsed script but does not
#' change the model state or write results to the log.
#' @return A data frame containing information on the calls to 'runModule' in the
#' order of the calls. Each row represents a module call in order. The columns
#' identify the 'ModuleName', the 'PackageName', and the 'RunFor' value.
#' @export
parseModelScript <-
  function(FilePath = "run_model.R",
           TestMode = FALSE) {
    if (!TestMode) {
      writeLog("Parsing model script")
    }
    if (!file.exists(FilePath)) {
      Msg <-
        paste0("Specified model script file (", FilePath, ") does not exist.")
      stop(Msg)
    }
    Script <- paste(readLines(FilePath), collapse = " ")
    RunModuleCalls_ <- unlist(strsplit(Script, "runModule"))[-1]
    if (length(RunModuleCalls_) == 0) {
      Msg <- "Specified script contains no 'runModule' function calls."
      stop(Msg)
    }
    Errors_ <- character(0)
    addError <- function(Error) {
      Errors_ <<- c(Errors_, Error)
    }
    #Utility function to remove spaces from string
    removeSpaces <- function(String) {
      gsub(" ", "", String)
    }
    #Utility function to clean up string
    cleanString <- function(String) {
      ToRemove = c(" ", "\\(", ")", '\\\"')
      for (SubString in ToRemove) {
        String <- gsub(SubString, "", String)
      }
      String
    }
    #Utility function to extract the arguments part of a function call
    extractArgsString <- function(String) {
      substring(String,
                regexpr("\\(", String),
                regexpr("\\)", String))
    }
    #Utility function to extract the value of a named argument
    getNamedArgumentValue <-
      function(ArgString, ArgName) {
        CommaPos <- regexpr(",", ArgString)
        if (CommaPos > 0) {
          ArgValue <-
            substring(ArgString,
                      regexpr("=", ArgString) + 1,
                      CommaPos - 1)
        } else {
          ArgValue <-
            substring(ArgString,
                      regexpr("=", ArgString) + 1,
                      nchar(ArgString))
        }
        cleanString(ArgValue)
      }
    #Utility function to extract the value of an unnamed argument
    getUnnamedArgumentValue <-
      function(ArgString) {
        ArgStringTrim <-
          substring(ArgString,
                    regexpr("\\\"", ArgString) + 1,
                    nchar(ArgString))
        cleanString(substring(ArgStringTrim,
                              1,
                              regexpr("\\\"", ArgStringTrim)))
      }
    #Function to extract the name and value of an argument from a string
    getArg <-
      function(ArgsString, ArgPos) {
        ArgString <- removeSpaces(ArgsString[ArgPos])
        #Define standard argument names
        ArgNames_ <-
          c("ModuleName", "PackageName", "RunFor", "Year")
        #Check whether any of the argument names is in the ArgString
        ArgNameCheck_ <-
          sapply(ArgNames_, function(x) {
            ArgName <- paste0(x, "=")
            regexpr(ArgName, ArgString)
          }) > 0
        if (any(ArgNameCheck_)) {
          ArgName <- names(ArgNameCheck_)[ArgNameCheck_]
          ArgValue <- getNamedArgumentValue(ArgString, ArgName)
        } else {
          ArgName <- ArgNames_[ArgPos]
          ArgValue <- getUnnamedArgumentValue(ArgString)
        }
        list(ArgName = ArgName, ArgValue = ArgValue)
      }
    #Function to extract all the arguments of runModule function call
    getArgs <-
      function(String) {
        PrelimArgs_ <- unlist(strsplit(extractArgsString(String), ","))
        Args_ls <-
          list(ModuleName = NULL,
               PackageName = NULL,
               RunFor = NULL)
        for (i in 1:length(PrelimArgs_)) {
          Arg_ls <- getArg(PrelimArgs_, i)
          Args_ls[[Arg_ls$ArgName]] <- Arg_ls$ArgValue
        }
        unlist(Args_ls)
      }
    #Iterate through RunModuleCalls_ and extract the arguments
    Args_ls <- list()
    for (i in 1:length(RunModuleCalls_)) {
      Args_ <- getArgs(RunModuleCalls_[i])
      #Error if not all mandatory arguments are matched
      if (length(Args_) != 4) {
        Msg <- paste0("runModule call #",
                      i,
                      " has improperly specified arguments.")
        addError(Msg)
      }
      #Add to list
      Args_ls[[i]] <- Args_
    }
    #If there are any errors, print error message
    if (length(Errors_) != 0) {
      if (!TestMode) {
        writeLog("One or more 'runModule' function calls have errors as follows:")
        writeLog(Errors_)
      }
      stop(
        "One or more errors in model run script. Must fix before model initialization can be completed."
      )
    } else {
      ModuleCalls_df <-
        data.frame(do.call(rbind, Args_ls), stringsAsFactors = FALSE)
      if (TestMode) {
        ModuleCalls_df
      } else {
        writeLog("Success parsing model script")
        setModelState(list(ModuleCalls_df = ModuleCalls_df))
      }
    }
  }


#CHECK MODULE AVAILABILITY
#=========================
#' Check whether required modules are present.
#'
#' \code{checkModulesExist}Function checks whether all required module
#' packages are installed and whether listed modules are present in the
#' packages.
#'
#' This function takes a listing of module calls and checks whether all of the
#' listed packages are installed on the computer and whether the named modules
#' are in the packages. If modules are all present, then the function returns
#' TRUE, otherwise it identifies the missing packages and modules to the log and
#' returns FALSE.
#'
#' @param ModuleCalls_df A listing of modules called in the 'run_model.R' script
#' as created by the 'parseModelScript' function.
#' @return TRUE if all packages and modules are present and FALSE if not.
#' @export
checkModulesExist <- function(ModuleCalls_df) {
  #Get listing of installed packages
  InstalledPkg_mx <- installed.packages()
  #Check whether all packages are installed
  NeededPkg_ <- unique(ModuleCalls_df$PackageName)
  NeededPkgExist_ <- NeededPkg_ %in% rownames(InstalledPkg_mx)
  MissingPkg_ <- NeededPkg_[!NeededPkgExist_]
  #If not all are present then return FALSE and write error to log
  if (!all(NeededPkgExist_)) {
    Message <-
      paste0("Required packages (",
             paste(MissingPkg_, collapse = ", "),
             ") must be installed before the model may be run.")
    writeLog(Message)
    return(FALSE)
    #Otherwise check that all named modules are present in the packages
  } else {
    ModuleCalls_ls_df <- split(ModuleCalls_df, ModuleCalls_df$PackageName)
    ModuleCheck_ls <-
      lapply(ModuleCalls_ls_df, function(x) {
        PkgName <- x$PackageName[1]
      PkgData_ <- data(package=PkgName)$results[,"Item"]
        PkgModules_ <- PkgData_[grep("Specifications", PkgData_)]
        PkgModules_ <- gsub("Specifications", "", PkgModules_)
        Calls_ <- x$ModuleName
        HasModule_ <- Calls_ %in% PkgModules_
        names(HasModule_) <- Calls_
        HasModule_
      })
    MissingModule_ls <- lapply(ModuleCheck_ls, function(x) names(x)[!x])
    HasMissing <- any(unlist(lapply(MissingModule_ls, length)) > 0)
    #If not all modules are present then return FALSE and write error to log
    if (HasMissing) {
      for (i in 1:length(MissingModule_ls)) {
        Pkg <- names(MissingModule_ls)[i]
        Module_ <- MissingModule_ls[[i]]
        Message <-
          paste0("Required modules (",
                 paste(Module_, collapse = ", "),
                 ") are missing from package ",
                 Pkg)
        writeLog(Message)
      }
      Msg <-
        paste0("One or more modules are missing from the specified packages. ",
               "This must be corrected before model can be run. ",
               "Details can be found in the log.")
      stop(Msg)
    #Otherwise return TRUE because all packages and modules are accounted for
    } else {
      return(TRUE)
    }
  }
}
#Test code
#---------
# #Define temporary writeLog function
# writeLog <- print
# #Test call for packages that don't exist
# checkModulesExist(read.csv("tests/data/module_call_test1_df.csv", as.is = TRUE))
# #Test call for modules that don't exist in package
# checkModulesExist(read.csv("tests/data/module_call_test2_df.csv", as.is = TRUE))
# #Test call where there are no missing packages or modules
# checkModulesExist(read.csv("tests/data/module_call_test3_df.csv", as.is = TRUE))
# #Remove temporary writeLog function
# rm(writeLog)


#GET MODULE SPECIFICATIONS
#=========================
#' Retrieve module specifications from a package
#'
#' \code{getModuleSpecs}Function retrieves the specifications list for a module
#' and returns the specifications list.
#'
#' This function loads the specifications for a module in a package. It returns
#' the specifications list.
#'
#' @param ModuleName A string identifying the name of the module.
#' @param PackageName A string identifying the name of the package that the
#' module is in.
#' @return A specifications list that is the same as the specifications list
#' defined for the module in the package.
#' @export
getModuleSpecs <- function(ModuleName, PackageName) {
  eval(parse(text = paste0(PackageName, "::", ModuleName, "Specifications")))
}
# Test_ls <-
#   getModuleSpecs(ModuleName = "CreateBzones", PackageName = "vedemo1")
# rm(Test_ls)


#EXPAND SPECIFICATION
#====================
#' Expand a Inp, Get, or Set specification so that is can be used by other
#' functions to process inputs and to read from or write to the datastore.
#'
#' \code{expandSpec} takes a Inp, Get, or Set specification and processes it to
#' be in a form that can be used by other functions which use the specification
#' in processing inputs or reading from or writing to the datastore. The
#' parseUnitsSpec function is called to parse the UNITS attribute to extract
#' name, multiplier, and year values. When the specification has multiple
#' values for the NAME attribute, the function creates a specification for each
#' name value.
#'
#' The VisionEval design allows module developers to assign multiple values to
#' the NAME attributes of a Inp, Get, or Set specification where the other
#' attributes for those named datasets (or fields) are the same. This greatly
#' reduces duplication and the potential for error in writing module
#' specifications. However, other functions that check or use the specifications
#' are not capable of handling specifications which have NAME attributes
#' containing multiple values. This function expands a specification with
#' multiple values for a  NAME attribute into multiple specifications, each with
#' a single value for the NAME attribute. In addition, the function calls the
#' parseUnitsSpec function to extract multiplier and year information from the
#' value of the UNITS attribute. See that function for details.
#'
#' @param SpecToExpand_ls A standard specifications list for a specification
#' whose NAME attribute has multiple values.
#' @return A list of standard specifications lists which has a component for
#' each value in the NAME attribute of the input specifications list.
#' @export
#Define a function which expands a specification with multiple NAME items
expandSpec <- function(SpecToExpand_ls) {
  SpecToExpand_ls <- parseUnitsSpec(SpecToExpand_ls)
  Names_ <- unlist(SpecToExpand_ls$NAME)
  Expanded_ls <- list()
  for (i in 1:length(Names_)) {
    Temp_ls <- SpecToExpand_ls
    Temp_ls$NAME <- Names_[i]
    Expanded_ls <- c(Expanded_ls, list(Temp_ls))
  }
  Expanded_ls
}


#PROCESS MODULE SPECIFICATIONS
#=============================
#' Process module specifications to expand items with multiple names.
#'
#' \code{processModuleSpecs}Function processes a full module specifications list,
#' expanding all elements in the Inp, Get, and Set components by parsing the
#' UNITS attributes and duplicating every specification which has multiple
#' values for the NAME attribute.
#'
#' This function process a module specification list. If any of the
#' specifications include multiple listings of data sets (i.e. fields) in a
#' table, this function expands the listing to establish a separate
#' specification for each data set.
#'
#' @param Spec_ls A specifications list.
#' @return A standard specifications list with expansion of the multiple item
#' specifications.
#' @export
processModuleSpecs <- function(Spec_ls) {
  #Define a function to process a component of a specifications list
  processComponent <- function(Component_ls, ComponentGroup) {
    Result_ls <- list()
    for (i in 1:length(Component_ls)) {
      Temp_ls <- Component_ls[[i]]
      Result_ls <- c(Result_ls, expandSpec(Temp_ls))
    }
    Result_ls
  }
  #Process the list components and return the results
  Out_ls <- list()
  Out_ls$RunBy <- Spec_ls$RunBy
  if (!is.null(Spec_ls$NewInpTable)) {
    Out_ls$NewInpTable <- Spec_ls$NewInpTable
  }
  if (!is.null(Spec_ls$NewSetTable)) {
    Out_ls$NewSetTable <- Spec_ls$NewSetTable
  }
  if (!is.null(Spec_ls$Inp)) {
    Out_ls$Inp <- processComponent(Spec_ls$Inp)
  }
  if (!is.null(Spec_ls$Get)) {
    Out_ls$Get <- processComponent(Spec_ls$Get)
  }
  if (!is.null(Spec_ls$Set)) {
    Out_ls$Set <- processComponent(Spec_ls$Set)
  }
  Out_ls
}


#SIMULATE DATA STORE TRANSACTIONS
#================================
#' Create simulation of datastore transactions.
#'
#' \code{simDataTransactions}Function loads all module specifications in order
#' (by run year) and creates a simulated listing of the data which is in the
#' datastore and the requests of data from the datastore and checks whether
#' tables will be present to put datasets in and that datasets will be present
#' that data is to be retrieved from.
#'
#' This function creates a list of the datastore listings for the working
#' datastore and for all datastore references. The list includes a 'Global'
#' component, in which 'Global' references are simulated, components for each
#' model run year, in which 'Year' references are simulated, and if the base
#' year is not one of the run years, a base year component, in which base year
#' references are simulated. For each model run year the function steps through
#' a data frame of module calls as produced by 'parseModelScript', and loads and
#' processes the module specifications in order: adds 'NewInpTable' references,
#' adds 'Inp' dataset references, checks whether references to datasets
#' identified in 'Get' specifications are present, adds 'NewSetTable' references,
#' and adds 'Set' dataset references. The function compiles a vector of error
#' and warning messages. Error messages are made if: 1) a 'NewInpTable' or
#' 'NewSetTable' specification of a module would create a new table for a table
#' that already exists; 2) a dataset identified by a 'Get' specification would
#' not be present in the working datastore or any referenced datastores; 3) the
#' 'Get' specifications for a dataset would not be consistent with the
#' specifications for the dataset in the datastore. The function compiles
#' warnings if a 'Set' specification will cause existing data in the working
#' datastore to be overwritten. The function writes warning and error messages
#' to the log and stops program execution if there are any errors.
#'
#' @param ModuleCalls_df A data frame of module calls as produced by the
#' 'parseModelScript' function.
#' @return There is no return value. The function has the side effect of
#' writing messages to the log and stops program execution if there are any
#' errors.
#' @export
simDataTransactions <- function(ModuleCalls_df) {
  G <- getModelState()

  #Initialize errors and warnings vectors
  #--------------------------------------
  Errors_ <- character(0)
  addError <- function(Msg) {
    Errors_ <<- c(Errors_, Msg)
  }
  Warnings_ <- character(0)
  addWarning <- function(Msg) {
    Warnings_ <<- c(Warnings_, Msg)
  }

  #Make a list to store the working datastore and all referenced datastores
  #------------------------------------------------------------------------
  RunYears_ <- getYears()
  BaseYear <- G$BaseYear
  if (BaseYear %in% RunYears_) {
    Years_ <- RunYears_
  } else {
    Years_ <- c(BaseYear, RunYears_)
  }
  Dstores_ls <-
    list(
      Global = list()
    )
  for (Year in Years_) Dstores_ls[[Year]] <- list()

  #Add the working datastore inventory to the datastores list
  #----------------------------------------------------------
  Dstores_ls[["Global"]][[G$DatastoreName]] <- G$Datastore
  for (Year in RunYears_) {
    Dstores_ls[[Year]][[G$DatastoreName]] <- G$Datastore
  }

  #Function to get datastore inventory corresponding to datastore reference
  #------------------------------------------------------------------------
  getInventoryRef <- function(DstoreRef) {
    SplitRef_ <- unlist(strsplit(DstoreRef, "/"))
    RefHead <- paste(SplitRef_[-length(SplitRef_)], collapse = "/")
    paste(RefHead, "ModelState.Rda", sep = "/")
  }

  #Get datastore inventories for datastore references
  #--------------------------------------------------
  if (!is.null(G$DatastoreReferences)) {
    RefNames_ <- names(G$DatastoreReferences)
    for (Name in RefNames_) {
      Refs_ <- G$DatastoreReferences[[Name]]
      for (Ref in Refs_) {
        if (file.exists(Ref)) {
          Dstores_ls[[Name]][[Ref]] <-
            readModelState("Datastore", FileName = getInventoryRef(Ref))
        } else {
          Msg <-
            paste0("The file '", Ref,
                   "' included in the 'DatastoreReferences' in the ",
                   "'run_parameters.json' file is not present.")
          addError(Msg)
        }
      }
    }
  }

  #Define function to add table reference to datastore inventory
  #-------------------------------------------------------------
  addTableRef <- function(Dstore_df, TableSpec_) {
    Group <- TableSpec_$GROUP
    if (Group == "Year") Group <- Year
    Table <- TableSpec_$TABLE
    #Check if table already exists
    HasTable <- checkTableExistence(Table, Group, Dstore_df)
    #If table exists then error, otherwise add reference to table
    if (HasTable) {
      Msg <-
        paste0("Error: MakeInpTable specification for module '", TableSpec_$MODULE,
               "' will create an input table '", Table,
               "' that already exists in the working datastore.")
      addError(Msg)
      return()
    } else {
      NewDstore_df <- data.frame(
        group = c(Dstore_df$group, paste0("/", Group)),
        name = c(Dstore_df$name, Table),
        groupname = c(Dstore_df$groupname, paste0(Group, "/", Table)),
        stringsAsFactors = FALSE
      )
    }
    NewDstore_df$attributes <- c(Dstore_df$attributes, list(TableSpec_))
    NewDstore_df
  }

  #Define function to add dataset reference to datastore inventory
  #---------------------------------------------------------------
  addDatasetRef <- function(Dstore_df, DatasetSpec_) {
    Group <- DatasetSpec_$GROUP
    if (Group == "Year") Group <- Year
    Table <- DatasetSpec_$TABLE
    Name <- DatasetSpec_$NAME
    #Check if dataset already exists
    HasDataset <- checkDataset(Name, Table, Group, Dstore_df)
    #If dataset exists then warn and check consistency of specifications
    if (HasDataset) {
      #Add warning that existing dataset will be overwritten
      Msg <-
        paste0("Module '", Module, "' will overwrite dataset '", Name,
               "' in table '", Table, "'.")
      addWarning(Msg)
      #Check attributes are consistent
      DstoreDatasetAttr_ls <-
        getDatasetAttr(Name, Table, Group, Dstore_df)
      AttrConsistency_ls <-
        checkSpecConsistency(DatasetSpec_, DstoreDatasetAttr_ls)
      if (length(AttrConsistency_ls$Errors != 0)) {
        addError(AttrConsistency_ls$Errors)
      }
      return(Dstore_df)
    } else {
      NewDstore_df <- data.frame(
        group = c(Dstore_df$group, paste0("/", Group)),
        name = c(Dstore_df$name, Name),
        groupname = c(Dstore_df$groupname, paste0(Group, "/", Table, "/", Name)),
        stringsAsFactors = FALSE
      )
      NewDstore_df$attributes <-
        c(Dstore_df$attributes,
          list(DatasetSpec_[c("NAVALUE", "SIZE", "TYPE", "UNITS")]))
      NewDstore_df
    }
  }

  #Iterate through run years and modules to simulate model run
  #-----------------------------------------------------------
  for (Year in RunYears_) {
    #Iterate through module calls
    for (i in 1:nrow(ModuleCalls_df)) {
      Module <- ModuleCalls_df$ModuleName[i]
      Package <- ModuleCalls_df$PackageName[i]
      RunFor <- ModuleCalls_df$RunFor[i]
      if (RunFor == "BaseYear" & Year != "BaseYear") break()
      if (RunFor == "NotBaseYear" & Year == "BaseYear") break()
      ModuleSpecs_ls <- processModuleSpecs(getModuleSpecs(Module, Package))

      #Add 'Inp' table references to the working datastore inventory
      #-------------------------------------------------------------
      if (!is.null(ModuleSpecs_ls$NewInpTable)) {
        for (j in 1:length(ModuleSpecs_ls$NewInpTable)) {
          Spec_ls <- ModuleSpecs_ls$NewInpTable[[j]]
          Spec_ls$MODULE <- Module
          if (Spec_ls[["GROUP"]] == "Global") {
            RefGroup <- "Global"
          } else {
            RefGroup <- Year
          }
          Dstore_df <- Dstores_ls[[RefGroup]][[G$DatastoreName]]
          if (!((RefGroup == "Global") & (Year != RunYears_[1]))) {
            Dstores_ls[[RefGroup]][[G$DatastoreName]] <-
            addTableRef(Dstore_df, Spec_ls)
          }
          rm(Spec_ls, RefGroup, Dstore_df)
        }
        rm(j)
      }

      #Add 'Inp' dataset references to the working datastore inventory
      #---------------------------------------------------------------
      if (!is.null(ModuleSpecs_ls$Inp)) {
        for (j in 1:length(ModuleSpecs_ls$Inp)) {
          Spec_ls <- ModuleSpecs_ls$Inp[[j]]
          Spec_ls$MODULE <- Module
          if (Spec_ls[["GROUP"]] == "Global") {
            RefGroup <- "Global"
          } else {
            RefGroup <- Year
          }
          Dstore_df <- Dstores_ls[[RefGroup]][[G$DatastoreName]]
          if (!((RefGroup == "Global") & (Year != RunYears_[1]))) {
            Dstores_ls[[RefGroup]][[G$DatastoreName]] <-
              addDatasetRef(Dstore_df, Spec_ls)
          }
          rm(Spec_ls, RefGroup, Dstore_df)
        }
        rm(j)
      }

      #Check for presence of 'Get' dataset references in datastore inventory
      #---------------------------------------------------------------------
      if (!is.null(ModuleSpecs_ls$Get)) {
        for (j in 1:length(ModuleSpecs_ls$Get)) {
          Spec_ls <- ModuleSpecs_ls$Get[[j]]
          Group <- Spec_ls[["GROUP"]]
          Table <- Spec_ls[["TABLE"]]
          Name <- Spec_ls[["NAME"]]
          if (Group == "Global") {
            Group <- "Global"
          }
          if (Group == "BaseYear") {
            Group <- G$BaseYear
          }
          if (Group == "Year") {
            Group <- Year
          }
          DatasetFound <- FALSE
          for (k in 1:length(Dstores_ls[[Group]])) {
            Dstore_df <- Dstores_ls[[Group]][[k]]
            DatasetInDstore <- checkDataset(Name, Table, Group, Dstore_df)
            if (!DatasetInDstore) {
              next()
            } else {
              DatasetFound <- TRUE
              DstoreAttr_ <- getDatasetAttr(Name, Table, Group, Dstore_df)
              AttrConsistency_ls <-
                checkSpecConsistency(Spec_ls, DstoreAttr_)
              if (length(AttrConsistency_ls$Errors != 0)) {
                addError(AttrConsistency_ls$Errors)
              }
              rm(DstoreAttr_, AttrConsistency_ls)
            }
            rm(Dstore_df, DatasetInDstore)
          }
          if (!DatasetFound) {
            Msg <-
              paste0("Module '", Module,
                     "' has a 'Get' specification for dataset '", Name,
                     "' in table '", Table,
                     "' that will not be present in the working datastore or ",
                     "any referenced datastores when it is needed.")
            addError(Msg)
          }
        }
      }

      #Add 'Set' table references to the working datastore inventory
      #-------------------------------------------------------------
      if (!is.null(ModuleSpecs_ls$NewSetTable)) {
        for (j in 1:length(ModuleSpecs_ls$NewSetTable)) {
          Spec_ls <- ModuleSpecs_ls$NewSetTable[[j]]
          Spec_ls$MODULE <- Module
          if (Spec_ls[["GROUP"]] == "Global") {
            RefGroup <- "Global"
          } else {
            RefGroup <- Year
          }
          Dstore_df <- Dstores_ls[[RefGroup]][[G$DatastoreName]]
          Dstores_ls[[RefGroup]][[G$DatastoreName]] <-
            addTableRef(Dstore_df, Spec_ls)
          rm(Spec_ls, RefGroup, Dstore_df)
        }
      }

      #Add 'Set' dataset references to the working datastore inventory
      #---------------------------------------------------------------
      if (!is.null(ModuleSpecs_ls$Set)) {
        for (j in 1:length(ModuleSpecs_ls$Set)) {
          Spec_ls <- ModuleSpecs_ls$Set[[j]]
          Spec_ls$MODULE <- Module
          if (Spec_ls[["GROUP"]] == "Global") {
            Group <- "Global"
          } else {
            Group <- Year
          }
          Dstore_df <- Dstores_ls[[Group]][[G$DatastoreName]]
          Dstores_ls[[Group]][[G$DatastoreName]] <-
            addDatasetRef(Dstore_df, Spec_ls)
          rm(Spec_ls, Group, Dstore_df)
        }
      }

      rm(Module, Package, ModuleSpecs_ls)
    } #End for loop through module calls
  } #End for loop through years

  writeLog("Simulating model run.")
  if (length(Warnings_) != 0) {
    Msg <-
      paste0("Model run simulation had one or more warnings. ",
             "Datasets will be be overwritten when the model runs. ",
             "Check that this is what it intended. ")
    writeLog(Msg)
    writeLog(Warnings_)
  }
  if (length(Errors_) == 0) {
    writeLog("Model run simulation completed without identifying any errors.")
  } else {
    Msg <-
      paste0("Model run simulation has found one or more errors. ",
             "The following errors must be corrected before the model may be run.")
    writeLog(Msg)
    writeLog(Errors_)
    stop(paste(Msg, "Check log for details."))
  }
}

