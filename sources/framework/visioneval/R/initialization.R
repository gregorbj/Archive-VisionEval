#================
#initialization.R
#================

#This script defines various functions that are invoked to initialize a model
#run.


#UPDATE MODEL STATE
#==================
#' Update model state.
#'
#' \code{setModelState} updates the file that keeps track of the model state
#' with list of components to update
#'
#' Key variables that are important for managing the model run are stored in a
#' list (ModelState_ls) that is saved in the 'ModelState.Rda' file. This
#' function loads the file and updates  entries with a supplied named list of
#' values, and then saves the results in the file.
#'
#' @param ChangeState_ls A named list of components to change in ModelState_ls
#' @param FileName A string identifying the name of the file that contains
#' the ModelState_ls list. The default name is 'ModelState.Rda'.
#' @return TRUE if the model state file is changed.
#' @export
setModelState <- function(ChangeState_ls, FileName = "ModelState.Rda") {
  if (file.exists(FileName)) {
    load(FileName)
  }
  if (!("ModelState_ls" %in% ls())) ModelState_ls <- list()
  for (i in 1:length(ChangeState_ls)) {
    ModelState_ls[[names(ChangeState_ls[i])]] <- ChangeState_ls[[i]]
  }
  save(ModelState_ls, file = "ModelState.Rda")
  TRUE
}


#RETRIEVE MODEL STATE
#====================
#' Retrieve model state.
#'
#' \code{getModelState} reads components of the file that keeps track of the
#' model state
#'
#' Key variables that are important for managing the model run are stored in a
#' list (ModelState_ls) that is saved in the 'ModelState.Rda' file. This
#' function loads the file and extracts named components of the list.
#'
#' @param Names_ A string vector of the components to extract from the
#' ModelState_ls list.
#' @param FileName A string identifying the name of the file that contains
#' the ModelState_ls list. The default name is 'ModelState.Rda'.
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


#RETRIEVE YEARS
#==============
#' Retrieve years
#'
#' \code{getYears} reads the Years component from the the model state file.
#'
#' This is a convenience function to make it easier to retrieve the Years
#' component of the model state file.
#'
#' @return A character vector of the model run years.
#' @export
getYears <- function() {
  unlist(getModelState("Years"))
}


#INITIALIZE MODEL STATE
#======================
#' Initialize model state.
#'
#' \code{initModelStateFile} loads model run parameters into the model state
#' file that is used to keep track of the model state.
#'
#' This function creates the model state file and loads model run parameters
#' recorded in the 'parameters.json' file into the model state file.
#'
#' @param Dir A string identifying the name of the directory where the global
#' parameters file is located. The default value is "defs".
#' @param ParamFile A string identifying the name of the global parameters file.
#' The default value is "parameters.json".
#' @return TRUE if the model state file is created. It creates the model state
#' file and loads parameters recorded in the 'parameters.json' file into the
#' model state file.
#' @export
#' @import jsonlite
initModelStateFile <- function(Dir = "defs", ParamFile = "parameters.json") {
  ParamFilePath <- file.path(Dir,  ParamFile)
  if (!file.exists(ParamFilePath)) {
    Message <- paste("Missing", ParamFilePath, "file.")
    stop(Message)
  } else {
    Parm <- fromJSON(ParamFilePath)
    setModelState(Parm)
  }
  TRUE
}


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
#' @return TRUE if the log is created successfully. It creates a log file in the
#'   working directory and identifies the name of the log file in the
#'   model state file.
#' @export
initLog <- function() {
  ModelState_ls <- getModelState()
  LogInitTime <- gsub(" ", "_", as.character(Sys.time()))
  LogFile <- paste0("Log", gsub(":", "_", LogInitTime), ".txt")
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
#' @return TRUE if the message is written to the log uccessfully.
#' It appends the time and the message text to the run log.
#' @export
writeLog <- function(Msg = "") {
  LogFile <- unlist(getModelState("LogFile"))
  Con <- file(LogFile, open = "a")
  Time <- as.character(Sys.time())
  Content <- paste(Time, ":", Msg, "\n")
  writeLines(Content, Con)
  close(Con)
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
#' @param GeoFile A string identifying the name of the geography definition file
#'   (see 'readGeography' function) that is consistent with the saved datastore.
#'   The geography definition file must be located in the 'defs' directory.
#' @return TRUE if the datastore is loaded. It copies the saved datastore to
#'   working directory as 'datastore.h5'. If a 'datastore.h5' file already
#'   exists, it first renames that file as 'archive-datastore.h5'. The function
#'   updates information in the model state file regarding the model geography
#'   and the contents of the loaded datastore. If the stored file does not exist
#'   an error is thrown.
#' @export
loadDatastore <- function(FileToLoad, GeoFile) {
  GeoFile <- paste0("defs/", GeoFile)
  G <- getModelState()
  #If data store exists, rename
  DatastoreName <- G$DatastoreName
  if (file.exists(DatastoreName)) {
    file.rename(DatastoreName, paste("archive", DatastoreName, sep = "-"))
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
                       UNITS = "None",
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
                       UNITS = "None",
                       NAVALUE = "NA",
                       PROHIBIT = "",
                       ISELEMENTOF = "",
                       SIZE = max(nchar(Azones_)),
                       LENGTH = length(Azones_))
  if(G$BzoneSpecified) {
    Bzones_ <- unique(G$Geo_df$Bzone)
    BzoneSpec_ls <- list(MODULE = "visioneval",
                         NAME = "Bzone",
                         TABLE = "Bzone",
                         TYPE = "character",
                         UNITS = "None",
                         NAVALUE = "NA",
                         PROHIBIT = "",
                         ISELEMENTOF = "",
                         SIZE = max(nchar(Bzones_)),
                         LENGTH = length(Bzones_))
  }
  if(G$CzoneSpecified) {
    Czones_ <- unique(G$Geo_df$Czone)
    Czone <- length(Czones_)
    CzoneSpec_ls <- list(MODULE = "visioneval",
                         NAME = "Czone",
                         TABLE = "Czone",
                         TYPE = "character",
                         UNITS = "None",
                         NAVALUE = "NA",
                         PROHIBIT = "",
                         ISELEMENTOF = "",
                         SIZE = max(nchar(Czones_)),
                         LENGTH = length(Czones_))
  }
  #Initialize geography tables and zone datasets
  for (Year in G$Years) {
    initTable(list(TABLE = "Region", LENGTH = 1), Year)
    initDataset(AzoneSpec_ls, Year)
    initDataset(MareaSpec_ls, Year)
    if(G$BzoneSpecified) {
      initDataset(BzoneSpec_ls, Year)
    }
    if(G$CzoneSpecified) {
      initDataset(CzoneSpec_ls, Year)
    }
  }
  rm(Year)
  #Add zone names to zone tables
  for (Year in G$Years) {
    if (!G$BzoneSpecified & !G$CzoneSpecified) {
      #Write to Azone table
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Year, Index = NULL)
      MareaSpec_ls$TABLE = "Azone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Year, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Year, Index = NULL)
    }
    if (G$BzoneSpecified & !G$CzoneSpecified) {
      #Write to Bzone table
      writeToTable(G$Geo_df$Bzone, BzoneSpec_ls, Year, Index = NULL)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Year, Index = NULL)
      MareaSpec_ls$TABLE = "Bzone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Year, Index = NULL)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, AzoneSpec_ls, Year, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Year, Index = NULL)
    }
    if (G$CzoneSpecified) {
      #Write to Czone table
      writeToTable(G$Geo_df$Czone, CzoneSpec_ls, Year, Index = NULL)
      BzoneSpec_ls$TABLE = "Czone"
      BzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Bzone, BzoneSpec_ls, Year, Index = NULL)
      AzoneSpec_ls$TABLE = "Czone"
      AzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Year, Index = NULL)
      MareaSpec_ls$TABLE = "Czone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Year, Index = NULL)
      #Write to Bzone table
      Geo_df <- G$Geo_df[!duplicated(G$Geo_df$Bzone), c("Azone", "Bzone")]
      BzoneSpec_ls$TABLE = "Bzone"
      BzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Bzone, BzoneSpec_ls, Year, Index = NULL)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Azone, AzoneSpec_ls, Year, Index = NULL)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, AzoneSpec_ls, Year, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Year, Index = NULL)
    }
  }
  #Write to log that complete
  Message <- "Geography sucessfully added to datastore."
  writeLog(Message)
  TRUE
}
