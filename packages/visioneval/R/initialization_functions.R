#==========================
#initialization_functions.R
#==========================

#Various functions used to set up the model run environment, log, datastore, etc.


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
#' @export
initEnv <- function(Dir = "defs", ParamFile = "parameters.json") {
  E <- new.env()
  ParamFilePath <- file.path(Dir,  ParamFile)
  if (!file.exists(ParamFilePath)) {
    Message <- paste("Missing", ParamFilePath, "file.")
    stop(Message)
  } else {
    Parm <- fromJSON(ParamFilePath)
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
#' @export
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


#DEFINE FUNCTION FOR LOADING AN EXISTING DATASTORE
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
#' @export
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


#DEFINE FUNCTION FOR READING GEOGRAPHIC SPECIFICATIONS
#=====================================================
#' Check correctness of geographic specifications.
#'
#' \code{readGeography} reads and checks geographic specifications file for
#' model.
#'
#' This function reads the file containing geographic specifications for the
#' model. It calls the checkGeography function. If errors are found in the
#' geographic specifications file, the errors are written to the log file and
#' execution stops. If no errors are found, the geographic specifications are
#' added to the run environment (E$Geo_df).
#'
#' @param Directory A string identifying the path to the geographic
#'   specifications file. Note that don't include the final separator in the
#'   path name 'e.g. not defs/'.
#' @param Filename A string identifying the name of the geographic
#'   specifications file. This is a csv-formatted text file which contains
#'   columns named 'Azone', 'Bzone', 'Czone', and 'Marea'. The 'Azone' column
#'   must have zone names in all rows. The 'Bzone' and 'Czone' columns can be
#'   unspecified (NA in all rows) or may have have unique names in every row.
#'   The 'Marea' column (referring to metropolitan areas) identifies
#'   metropolitan areas corresponding to each Azone or the value 'None' if a
#'   metropolitan area does not occupy any portion of an Azone. The geographic
#'   specifications file must exist in the "defs" directory.
#' @return The value TRUE is returned if the function is successful at reading
#'   the file and the specifications are consistent. It stops if there are any
#'   errors in the specifications. All of the identified errors are written to
#'   the run log. A data frame containing the file entries is added to the run
#'   environment as 'E$Geo_df'.
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
  #Save the geographic data
  E$Geo_df <<- CheckResults_ls$Geo
  TRUE
}


#DEFINE A FUNCTION TO WRITE GEOGRAPHIC INFORMATION TO THE DATASTORE
#==================================================================
#' Initialize datastore geography.
#'
#' \code{initDatastoreGeography} initializes tables and writes datasets to the
#' datastore which describe geographic relationships of the model.
#'
#' This function writes tables to the datastore for each of the geographic
#' levels. These tables are then used during a model run to store values that
#' are either specified in scenario inputs or that are calculated during a model
#' run. The function populates the tables with cross-references between
#' geographic levels. The function reads the model geography from the run
#' environment 'E$Geo_df'. Upon successful completion, the function calls
#' 'listDatastore' to update the datastore listing in the run environment.
#'
#' @return The function returns TRUE if the geographic tables and datasets are
#'   sucessfully written to the datastore.
#' @export
initDatastoreGeography <- function() {
  #Make lists of zone specifications
  Mareas_ <- unique(E$Geo_df$Marea)
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
  Azones_ <- unique(E$Geo_df$Azone)
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
  if(E$BzoneSpecified) {
    Bzones_ <- unique(E$Geo_df$Bzone)
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
  if(E$CzoneSpecified) {
    Czones_ <- unique(E$Geo_df$Czone)
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
  for (Year in E$Years) {
    initDataset(AzoneSpec_ls, Year)
    initDataset(MareaSpec_ls, Year)
    if(E$BzoneSpecified) {
      initDataset(BzoneSpec_ls, Year)
    }
    if(E$CzoneSpecified) {
      initDataset(CzoneSpec_ls, Year)
    }
  }
  #Add zone names to zone tables
  for (Year in E$Years) {
    if (!E$BzoneSpecified & !E$CzoneSpecified) {
      #Write to Azone table
      writeToTable(E$Geo_df$Azone, Index = NULL, AzoneSpec_ls, Year)
      MareaSpec_ls$TABLE = "Azone"
      MareaSpec_ls$LENGTH = nrow(E$Geo_df)
      writeToTable(E$Geo_df$Marea, Index = NULL, MareaSpec_ls, Year)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, Index = NULL, MareaSpec_ls, Year)
    }
    if (E$BzoneSpecified & !E$CzoneSpecified) {
      #Write to Bzone table
      writeToTable(E$Geo_df$Bzone, Index = NULL, BzoneSpec_ls, Year)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(E$Geo_df)
      writeToTable(E$Geo_df$Azone, Index = NULL, AzoneSpec_ls, Year)
      MareaSpec_ls$TABLE = "Bzone"
      MareaSpec_ls$LENGTH = nrow(E$Geo_df)
      writeToTable(E$Geo_df$Marea, Index = NULL, MareaSpec_ls, Year)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, Index = NULL, AzoneSpec_ls, Year)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, Index = NULL, MareaSpec_ls, Year)
    }
    if (E$CzoneSpecified) {
      #Write to Czone table
      writeToTable(E$Geo_df$Czone, Index = NULL, CzoneSpec_ls, Year)
      BzoneSpec_ls$TABLE = "Czone"
      BzoneSpec_ls$LENGTH = nrow(E$Geo_df)
      writeToTable(E$Geo_df$Bzone, Index = NULL, BzoneSpec_ls, Year)
      AzoneSpec_ls$TABLE = "Czone"
      AzoneSpec_ls$LENGTH = nrow(E$Geo_df)
      writeToTable(E$Geo_df$Azone, Index = NULL, AzoneSpec_ls, Year)
      MareaSpec_ls$TABLE = "Czone"
      MareaSpec_ls$LENGTH = nrow(E$Geo_df)
      writeToTable(E$Geo_df$Marea, Index = NULL, MareaSpec_ls, Year)
      #Write to Bzone table
      Geo_df <- E$Geo_df[!duplicated(E$Geo_df$Bzone), c("Azone", "Bzone")]
      BzoneSpec_ls$TABLE = "Bzone"
      BzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Bzone, Index = NULL, BzoneSpec_ls, Year)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Azone, Index = NULL, AzoneSpec_ls, Year)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, Index = NULL, AzoneSpec_ls, Year)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, Index = NULL, MareaSpec_ls, Year)
    }
  }
  #Write to log that complete
  Message <- "Geography sucessfully added to datastore."
  writeLog(Message)
  TRUE
}


