#================
#initialization.R
#================

#This script defines various functions that are invoked to initialize a model
#run. Several of the functions are also invoked when modules are run.


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
initModelStateFile <- function(Dir = "defs", ParamFile = "run_parameters.json") {
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
                       SIZE = max(nchar(Azones_)),
                       LENGTH = length(Azones_))
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
                         UNITS = "",
                         NAVALUE = "NA",
                         PROHIBIT = "",
                         ISELEMENTOF = "",
                         SIZE = max(nchar(Czones_)),
                         LENGTH = length(Czones_))
  }
  #Initialize geography tables and zone datasets
  for (Year in G$Years) {
    initTable(list(TABLE = "Region", LENGTH = 1), Group = Year)
    initDataset(AzoneSpec_ls, Group = Year)
    initDataset(MareaSpec_ls, Group = Year)
    if(G$BzoneSpecified) {
      initDataset(BzoneSpec_ls, Group = Year)
    }
    if(G$CzoneSpecified) {
      initDataset(CzoneSpec_ls, Group = Year)
    }
  }
  rm(Year)
  #Add zone names to zone tables
  for (Year in G$Years) {
    if (!G$BzoneSpecified & !G$CzoneSpecified) {
      #Write to Azone table
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Group = Year, Index = NULL)
      MareaSpec_ls$TABLE = "Azone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Group = Year, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Group = Year, Index = NULL)
    }
    if (G$BzoneSpecified & !G$CzoneSpecified) {
      #Write to Bzone table
      writeToTable(G$Geo_df$Bzone, BzoneSpec_ls, Group = Year, Index = NULL)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Group = Year, Index = NULL)
      MareaSpec_ls$TABLE = "Bzone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Group = Year, Index = NULL)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, AzoneSpec_ls, Group = Year, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Group = Year, Index = NULL)
    }
    if (G$CzoneSpecified) {
      #Write to Czone table
      writeToTable(G$Geo_df$Czone, CzoneSpec_ls, Group = Year, Index = NULL)
      BzoneSpec_ls$TABLE = "Czone"
      BzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Bzone, BzoneSpec_ls, Group = Year, Index = NULL)
      AzoneSpec_ls$TABLE = "Czone"
      AzoneSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Azone, AzoneSpec_ls, Group = Year, Index = NULL)
      MareaSpec_ls$TABLE = "Czone"
      MareaSpec_ls$LENGTH = nrow(G$Geo_df)
      writeToTable(G$Geo_df$Marea, MareaSpec_ls, Group = Year, Index = NULL)
      #Write to Bzone table
      Geo_df <- G$Geo_df[!duplicated(G$Geo_df$Bzone), c("Azone", "Bzone")]
      BzoneSpec_ls$TABLE = "Bzone"
      BzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Bzone, BzoneSpec_ls, Group = Year, Index = NULL)
      AzoneSpec_ls$TABLE = "Bzone"
      AzoneSpec_ls$LENGTH = nrow(Geo_df)
      writeToTable(Geo_df$Azone, AzoneSpec_ls, Group = Year, Index = NULL)
      #Write to Azone table
      AzoneSpec_ls$TABLE = "Azone"
      AzoneSpec_ls$LENGTH = length(Azones_)
      writeToTable(Azones_, AzoneSpec_ls, Group = Year, Index = NULL)
      #Write to Marea table
      MareaSpec_ls$TABLE = "Marea"
      MareaSpec_ls$LENGTH = length(Mareas_)
      writeToTable(Mareas_, MareaSpec_ls, Group = Year, Index = NULL)
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
#' @param Path A string identifying the relative or absolute path to the
#'   model run script is located.
#' @return A data frame containing information on the calls to 'runModule' in the
#' order of the calls. Each row represents a module call in order. The columns
#' identify the 'ModuleName', the 'PackageName', and the 'TimeFrame'.
#' @export
parseModelScript <- function(FilePath = "run_model.R") {
  Script_ <- readLines(FilePath)
  RunModuleIdx_ <- grep("runModule", Script_)
  StartIdx_ <- sapply(RunModuleIdx_, function(x) {
    OpenParen_ <- grep("\\(", Script_)
    OpenParen_[OpenParen_ >= x][1]
  })
  EndIdx_ <- sapply(RunModuleIdx_, function(x) {
    CloseParen_ <- grep(")", Script_)
    CloseParen_[CloseParen_ >= x][1]
  })
  removeCharacters <-
    function(String,
             ToRemove = c("runModule", " ", "\\(", ")", '\\\"')) {
      for (SubString in ToRemove) {
        String <- gsub(SubString, "", String)
      }
      String
    }
  getArgs <- function(Lines_, StartIdx, EndIdx) {
    Extract_ <-
      unlist(strsplit(
        removeCharacters(paste(Lines_[StartIdx:EndIdx], collapse = " ")),
        ","
      ))
    #Get module name
    ModuleNameIdx <- grep("ModuleName", Extract_)
    if (length(ModuleNameIdx) != 0) {
      ModuleName <- unlist(strsplit(Extract_[ModuleNameIdx], "="))[2]
    } else {
      ModuleName <- Extract_[1]
    }
    #Get package name
    PackageNameIdx <- grep("PackageName", Extract_)
    if (length(PackageNameIdx) != 0) {
      PackageName <- unlist(strsplit(Extract_[PackageNameIdx], "="))[2]
    } else {
      PackageName <- Extract_[2]
    }
    #Get time frame
    TimeFrameIdx <- grep("TimeFrame", Extract_)
    if (length(TimeFrameIdx) != 0) {
      TimeFrame <- unlist(strsplit(Extract_[TimeFrameIdx], "="))[2]
    } else {
      TimeFrame <- Extract_[3]
    }
    #Return vector of results
    c(
      ModuleName = ModuleName,
      PackageName = PackageName,
      TimeFrame = TimeFrame
    )
  }
  ModuleCalls_ls <- list()
  for (i in 1:length(StartIdx_)) {
    ModuleCalls_ls[[i]] <-
      getArgs(Script_, StartIdx_[i], EndIdx_[i])
  }
  data.frame(do.call(rbind, ModuleCalls_ls), stringsAsFactors = FALSE)
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
      return(FALSE)
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
  requireNamespace(PackageName)
  Spec_ls <- eval(parse(text = paste0(PackageName, "::", ModuleName, "Specifications")))
  unloadNamespace(PackageName)
  Spec_ls
}
# Test_ls <-
#   getModuleSpecs(ModuleName = "CreateBzones", PackageName = "vedemo1")
# rm(Test_ls)


#PROCESS MODULE SPECIFICATIONS
#=============================
#' Process module specifications to expand items with multiple names.
#'
#' \code{processModuleSpecs}Function processes a specifications list and
#' expands items that have multiple NAME listings into multiple items.
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
  #Define a function which expands a specification with multiple NAME items
  expandSpec <- function(SpecToExpand_ls) {
    Names_ <- unlist(SpecToExpand_ls$NAME)
    Expanded_ls <- list()
    for (i in 1:length(Names_)) {
      Temp_ls <- SpecToExpand_ls
      Temp_ls$NAME <- Names_[i]
      Expanded_ls <- c(Expanded_ls, list(Temp_ls))
    }
    Expanded_ls
  }
  #Define a function to process a component of a specifications list
  processComponent <- function(Component_ls) {
    Result_ls <- list()
    for (i in 1:length(Component_ls)) {
      Temp_ls <- Component_ls[[i]]
      if (length(Temp_ls$NAME) == 1) {
        Result_ls <- c(Result_ls, list(Temp_ls))
      } else {
        Result_ls <- c(Result_ls, expandSpec(Temp_ls))
      }
    }
    Result_ls
  }
  #Create output list with components
  Out_ls <-
    list(
      RunBy = Spec_ls$RunBy,
      Inp = list(),
      Get = list(),
      Set = list()
    )
  #Process the list components
  Out_ls$Inp <- processComponent(Spec_ls$Inp)
  Out_ls$Get <- processComponent(Spec_ls$Get)
  Out_ls$Set <- processComponent(Spec_ls$Set)
  Out_ls
}
# item <- list
# items <- list
# source("tests/data/test_specs.R")
# Test_ls <- processModuleSpecs(TestSpec_ls)
# rm(item, items, TestSpec_ls, Test_ls)


#SIMULATE DATA STORE TRANSACTIONS
#================================
#' Create simulation of datastore transactions.
#'
#' \code{simDataTransactions}Function loads all module specifications in order
#' and creates a simulated listing of the data which is in the datastore and
#' the requests of data from the datastore.
#'
#' This function steps through a data frame of module calls as produced by
#' 'parseModelScript', loads and processes the module specifications, and
#' organizes the specifications in a list which represents the data which is in
#' the datastore at each step, and the data which is requested from the
#' datastore at each step. The list includes the identification of groups,
#' tables, and data sets, data set attributes, and the relative order when a
#' data set is placed in the data set and when it is requested from the data
#' set. The function also collects all of the 'Inp' components of all modules
#' into one list to facilitate processing all inputs during model
#' initialization.
#'
#' @param ModuleCalls_df A data frame of module calls as produced by the
#' 'parseModelScript' function.
#' @return A list having 3 components: Inp, Dstore, Get. Inp is a list of all
#' of the module 'Inp' specifications. Dstore is a list organized as the
#' datastore would be organized with the exception that numbered year groups
#' are represented by a 'BaseYear' and a 'Year' group.
#' @export
simDataTransactions <- function(ModuleCalls_df) {
  #Load model state
  G <- getModelState()
  #Initialize outputs list
  Out_ls <-
    list(Inp = list(),
         Get = list(),
         Dstore = list(
           Global = list(),
           BaseYear = list(),
           Year = list()
         ))
  #Initialize errors vector
  Errors_ <- character(0)
  #Add datastore listing information
  Datastore_df <- G$Datastore
  for (i in 1:nrow(Datastore_df)) {
    Names_ <- unlist(strsplit(Datastore_df$groupname[i], "/"))
    if (length(Names_) == 3) {
      #Identify GROUP, TABLE, and NAME
      if (Names_[1] == "Global") {
        GROUP <- Names_[1]
      } else {
        if (Names_[1] == G$BaseYear) {
          GROUP <- "BaseYear"
        } else {
          GROUP <- "Year"
        }
      }
      TABLE <- Names_[2]
      #Add TABLE component if does not exist
      if (is.null(Out_ls$Dstore[[GROUP]][[TABLE]])) {
        Out_ls$Dstore[[GROUP]][[TABLE]] <- list()
      }
      #Create NAME component and add attributes
      NAME <- Names_[3]
      Attr_ls <- getDatasetAttr(Names_[3], Names_[2], Names_[1], Datastore_df)
      CREATOR <- "Initialization"
      Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]] <-
        list(CREATOR = CREATOR,
             ORDER = 0,
             TYPE = Attr_ls$TYPE,
             UNITS = Attr_ls$UNITS,
             NAVALUE = Attr_ls$NAVALUE,
             PROHIBIT = Attr_ls$PROHIBIT,
             ISELEMENTOF = Attr_ls$ISELEMENTOF)
    }
  }
  #Iterate through module calls and process specifications
  for (i in 1:nrow(ModuleCalls_df)) {
    Module <- ModuleCalls_df$ModuleName[i]
    Package <- ModuleCalls_df$PackageName[i]
    InSpec_ls <-
      getModuleSpecs(Module, Package)
    Spec_ls <- processModuleSpecs(InSpec_ls)
    ###Process INP Specifications###
    for (j in 1:length(Spec_ls$Inp)) {
      Ls <- Spec_ls$Inp[[j]]
      GROUP <- Ls$GROUP
      TABLE <- Ls$TABLE
      NAME <- Ls$NAME
      Ls$MODULE <- paste(Package, Module, sep = "/")
      Out_ls$Inp <- c(Out_ls$Inp, list(Ls))
      #Add TABLE component if does not exist
      if (is.null(Out_ls$Dstore[[GROUP]][[TABLE]])) {
        Out_ls$Dstore[[GROUP]][[TABLE]] <- list()
      }
      #If dataset NAME already exists, make an error message
      if (!is.null(Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]])) {
        CREATOR <- Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]]$CREATOR
        ErrMsg <-
          paste0("Input processing for module '", Module,
                 "' in package '", Package,
                 "' will overwrite data set '", GROUP, "/", TABLE, "/", NAME,
                 "that was created by '", CREATOR)
        Errors_ <- c(Errors_, ErrMsg)
      } else {
        #Otherwise create NAME component and add attributes
        CREATOR <- paste(Package, Module, sep = "/")
        Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]] <-
          list(CREATOR = CREATOR,
               ORDER = 0,
               TYPE = Ls$TYPE,
               UNITS = Ls$UNITS,
               NAVALUE = Ls$NAVALUE,
               PROHIBIT = Ls$PROHIBIT,
               ISELEMENTOF = Ls$ISELEMENTOF)
      }
      rm(Ls, GROUP, TABLE, NAME, CREATOR)
    }
    rm(j)
    ###Process GET Specifications###
    for (j in 1:length(Spec_ls$Get)) {
      Ls <- Spec_ls$Get[[j]]
      Ls$REQUESTOR <- paste(Package, Module, sep = "/")
      Ls$ORDER <- i
      Out_ls$Get <- c(Out_ls$Get, list(Ls))
      rm(Ls)
    }
    rm(j)
    ###Process SET Specifications###
    for (j in 1:length(Spec_ls$Set)) {
      Ls <- Spec_ls$Set[[j]]
      GROUP <- Ls$GROUP
      TABLE <- Ls$TABLE
      NAME <- Ls$NAME
      #Add TABLE component if does not exist
      if (is.null(Out_ls$Dstore[[GROUP]][[TABLE]])) {
        Out_ls$Dstore[[GROUP]][[TABLE]] <- list()
      }
      #If dataset NAME already exists, make an error message
      if (!is.null(Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]])) {
        CREATOR <- Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]]$CREATOR
        ErrMsg <-
          paste0("Input processing for module '", Module,
                 "' in package '", Package,
                 "' will overwrite data set '", GROUP, "/", TABLE, "/", NAME,
                 "that was created by '", CREATOR)
        Errors_ <- c(Errors_, ErrMsg)
      } else {
        #Otherwise create NAME component and add attributes
        CREATOR <- paste(Package, Module, sep = "/")
        Out_ls$Dstore[[GROUP]][[TABLE]][[NAME]] <-
          list(CREATOR = CREATOR,
               ORDER = i,
               TYPE = Ls$TYPE,
               UNITS = Ls$UNITS,
               NAVALUE = Ls$NAVALUE,
               PROHIBIT = Ls$PROHIBIT,
               ISELEMENTOF = Ls$ISELEMENTOF)
      }
      rm(Ls, GROUP, TABLE, NAME, CREATOR)
    }
    rm(j)
  }
  list(Out = Out_ls, Err = Errors_)
}

# Test_df <- parseModelScript("tests/data/run_model.R")
# Test_ls <- simDataTransactions(Test_df)


#CHECK SIMULATED DATASTORE TRANSACTIONS FOR CONSISTENCY
#======================================================
#' Check the simulation of datastore transactions.
#'
#' \code{checkSimTransactions}Function checks the list which simulates datastore
#' transactions created by the 'simDataTransactions' function for consistency
#' between requests for data in 'Get' specifications with data that would be
#' present in the datastore when the Get requests are made.
#'
#' This function evaluates the simulated datastore transactions list created by
#' the 'simDataTransactions' function for consistency between requests for data
#' in 'Get' specifications with data that would be present in the datastore when
#' the Get requests are made. The consistency checks are:
#' 1. Whether the requested data set would be in the datastore
#' 2. Whether the requested data set would be in the datastore prior to when the
#' request is made.
#' 3. Whether the specifications of the data in the datastore are consistent
#' with the specifications for the data that are requested.
#' The function returns a list which contains the results of all data checks.
#' Each component is a list that contains the results of the checks for one
#' dataset. The component identifies the package and module requesting the
#' dataset (Module), the name of the group/table/dataset being checked
#' (Dataset), whether there are any errors (HasErrors), error messages if there
#' are any errors (Errors), whether there are any warnings (HasWarnings), and
#' warning messages if there are any warnings (Warnings).
#'
#' @param Transactions_ls A list as produced by the 'simDataTransactions'
#' function.
#' @return A list containing the results of each dataset check.
#' @export
checkSimTransactions <- function(Transactions_ls) {
  Check_ls <- list()
  Get_ls <- Transactions_ls$Out$Get
  Dstore_ls <- Transactions_ls$Out$Dstore
  for (i in 1:length(Get_ls)) {
    Check_ls[[i]] <- list()
    Err_ <- character(0)
    Warn_ <- character(0)
    GROUP <- Get_ls[[i]]$GROUP
    TABLE <- Get_ls[[i]]$TABLE
    NAME <- Get_ls[[i]]$NAME
    ORDER <- Get_ls[[i]]$NAME
    REQUESTOR <- Get_ls[[i]]$REQUESTOR
    Check_ls[[i]]$Module <- REQUESTOR
    Check_ls[[i]]$Dataset <- paste(GROUP, TABLE, NAME, sep = "/")
    if (is.null(Dstore_ls[[GROUP]][[TABLE]][[NAME]])) {
      Message <-
        paste0("Package/module ", REQUESTOR, " has Get specification for data ",
               GROUP, "/", TABLE, "/", NAME,
               " that will not be in the datastore.")
      Err_ <- c(Err_, Message)
      rm(Message)
    } else {
      CREATOR <- Dstore_ls[[GROUP]][[TABLE]][[NAME]]$CREATOR
      if (ORDER <= Dstore_ls[[GROUP]][[TABLE]][[NAME]]$ORDER) {
        Message <-
          paste0("Package/module ", REQUESTOR, " has Get specification for data ",
                 GROUP, "/", TABLE, "/", NAME,
                 " that will only present in the datastore after it is requested. ",
                 "Package/module ", CREATOR,
                 " which supplies the dataset needs to be run before this module.")
        Err_ <- c(Err_, Message)
        rm(Message)
      } else {
        AttrToCheck_ <- c("TYPE", "UNITS", "PROHIBIT", "ISELEMENTOF")
        GetAttr_ls <- Get_ls[[i]][AttrToCheck_]
        DstoreAttr_ls <-
          Dstore_ls[[GROUP]][[TABLE]][[NAME]][AttrToCheck_]
        SpecCheck_ls <-
          checkSpecConsistency(GetAttr_ls, DstoreAttr_ls)
        if (length(SpecCheck_ls$Errors != 0)) {
          Message <-
            paste0("Package/module ", REQUESTOR, " has Get specification for data ",
                   GROUP, "/", TABLE, "/", NAME,
                   " that is not consistent with Set specification of package/module ",
                   CREATOR, " as follows.")
          Err_ <- c(Err_, Message, SpecCheck_ls$Errors)
          rm(Message)
        }
        if (length(SpecCheck_ls$Warnings != 0)) {
          Message <-
            paste0("Package/module ", REQUESTOR, " has Get specification for data UNITS ",
                   GROUP, "/", TABLE, "/", NAME,
                   " that is not consistent with Set specification of package/module ",
                   CREATOR, " as follows.")
          Warn_ <- c(Warn_, Message, SpecCheck_ls$Warnings)
          rm(Message)
        }
        rm(AttrToCheck_, GetAttr_ls, DstoreAttr_ls, SpecCheck_ls)
      }
      rm(CREATOR)
    }
    if (length(Err_) == 0) {
      Check_ls[[i]]$HasErrors <- FALSE
    } else {
      Check_ls[[i]]$HasErrors <- TRUE
      Check_ls[[i]]$Errors <- Err_
    }
    if (length(Warn_) == 0) {
      Check_ls[[i]]$HasWarnings <- FALSE
    } else {
      Check_ls[[i]]$HasWarnings <- TRUE
      Check_ls[[i]]$Warnings <- Warn_
    }
    rm(GROUP, TABLE, NAME, ORDER, REQUESTOR)
  }
  Check_ls
}


#PROCESS MODULE INPUTS
#=====================
#' Check input files and load into datastore if correct.
#'
#' \code{processModuleInputs} checks whether specified module inputs meet
#' specifications and load into datastore if OnlyCheck argument is false.
#'
#' This function checks whether all the specified scenario inputs meet
#' specifications. Checks include whether the specified files exist, whether the
#' files include data for all years and specified zones, and whether every data
#' item meets specifications. Data specifications.
#'
#' @param Inp_ls A list which meets standards for specifying input
#' characteristics.
#' @param ModuleName A string identifying the module name.
#' @param Dir A string identifying the relative path name to the directory where
#'   input files are located.
#' @param OnlyCheck A logical value. If TRUE, the function will only check the
#'   inputs. If FALSE, the function will check the inputs and load the input
#'   data into the datastore.
#' @return A numeric vector having 3 elements (FileErrors, DataErrors,
#'   DataWarnings). Each element identifies how may data errors or warnings were
#'   found.
#' @export
processModuleInputs <-
  function(Inp_ls, Dir = "inputs", OnlyCheck = TRUE, Ignore_ = NULL) {
    G <- getModelState()
    FileName <- ""
    FileErr_ <- character(0)
    for (i in 1:length(Inp_ls)) {
      Spec_ls <- Inp_ls[[i]]
      DataErr_ls <-
        list(Errors = character(0), Warnings = character(0))
      #Check for file errors only if not already done
      if (Spec_ls$FILE != FileName) {
        FileName <- Spec_ls$FILE
        #Check that input file exists
        if (!file.exists(file.path(Dir, FileName))) {
          Message <- paste(
            "Input file error.", "File", FileName, "required by",
            ModuleName, "is not present in the 'inputs' directory."
          )
          writeLog(Message)
          FileErr_ <- c(FileErr_, Message)
          next()
        }
      }
      #Load data
      Data_df <- read.csv(file.path(Dir, FileName), as.is = TRUE)
      #Check the specifications for GROUP
      Group <- Spec_ls$GROUP
      if (!(Group %in% c("Global", "BaseYear", "Year"))) {
        Message <- paste0(
          "Specified 'GROUP' (", Group, ") does not have allowed value",
          " which must be either 'Global', 'BaseYear', or 'Year'."
        )
        writeLog(Message)
        FileErr_ <- c(FileErr_,Message)
        next()
      }
      #If is a 'Year' group table, check whether geography & year entries are correct
      if (Group == "Year") {
        GeoYrSpec_df <- do.call(rbind, lapply(G$Years, function(x) {
          Geo_ <- readFromTable(Spec_ls$TABLE, Spec_ls$TABLE, x, Index = NULL)
          data.frame(
            Geo = Geo_,
            Year = rep(as.integer(x), length(Geo_)),
            stringsAsFactors = FALSE
          )
        }))
        GeoYrSpec_df <-
          GeoYrSpec_df[order(GeoYrSpec_df$Year, GeoYrSpec_df$Geo),]
        GeoYrData_df <-
          Data_df[order(Data_df$Year, Data_df$Geo), c("Geo", "Year")]
        if (!all.equal(GeoYrSpec_df, GeoYrData_df)) {
          Message <- paste(
            "Input file error. Error in the 'Geo' and 'Year' fields of the file",
            FileName, "that", ModuleName, "requires."
          )
          writeLog(Message)
          FileErr_ <- c(FileErr_, Message)
          next()
        }
      }
      #If is a 'BaseYear' group table, check whether geography entries are correct
      if (Group == "BaseYear") {
        GeoSpec_ <-
          readFromTable(Spec_ls$TABLE, Spec_ls$TABLE, G$BaseYear, Index = NULL)
        GeoData_ <- Data_df$Geo
        HasMissingGeo_ <- any(!(GeoData_ %in% GeoSpec_))
        HasExtraGeo_ <- any(!(GeoSpec_ %in% GeoData_))
        if (HasMissingGeo_ | HasExtraGeo_) {
          Message <- paste(
            "Input file error. Error in the 'Geo' field of the file",
            FileName, "that", ModuleName, "requires."
          )
          writeLog(Message)
          FileErr_ <- c(FileErr_, Message)
          next()
        }
      }
      #Check dataset
      DatasetName <- Spec_ls$NAME
      if (!DatasetName %in% Ignore_) {
        Data_ <- Data_df[[DatasetName]]
        DataCheck_ls <-
          checkDataConsistency(DatasetName, Data_, Spec_ls)
        if (length(DataCheck_ls$Errors) != 0) {
          writeLog(DataCheck_ls$Errors)
          DataErr_ls$Errors <-
            c(DataErr_ls$Errors, DataCheck_ls$Errors)
        }
        if (length(DataCheck_ls$Warnings) != 0) {
          writeLog(DataCheck_ls$Warnings)
          DataErr_ls$Warnings <-
            c(DataErr_ls$Warnings, DataCheck_ls$Warnings)
        }
      }
      #If no errors and OnlyCheck is FALSE, then load the data into the datastore
      if ((length(FileErr_) == 0) &
          (length(DataErr_ls$Errors) == 0) & (OnlyCheck == FALSE)) {
        if (Group == "Global") {
          DtoWrite_ <- Data_df[,DatasetName]
          Spec_ls$LENGTH <- length(DtoWrite_)
          writeToTable(DtoWrite_, Spec_ls, Group)
        }
        if (Group == "BaseYear") {
          DstoreGeo_ <- readFromTable(Spec_ls$TABLE, Spec_ls$TABLE, G$BaseYear)
          DtoWrite_ <-
            YearData_df[[DatasetName]][match(DstoreGeo_, Data_df$Geo)]
          writeToTable(DtoWrite_, Spec_ls, G$BaseYear)
        }
        if (Group == "Year") {
          for (Year in G$Years) {
            DstoreGeo_ <- readFromTable(Spec_ls$TABLE, Spec_ls$TABLE, Year)
            YearData_df <- Data_df[Data_df$Year == Year,]
            DtoWrite_ <-
              YearData_df[[DatasetName]][match(DstoreGeo_, Data_df$Geo)]
            writeToTable(DtoWrite_, Spec_ls, Year)
          }
        }
      }
    }
    Result_ <- c(
      FileErrors = 0, DataErrors = 0, DataWarnings = 0
    )
    if (length(DataErr_ls$Errors) != 0)
      Result_["DataErrors"] <- length(DataErr_ls$Errors)
    if (length(DataErr_ls$Warnings) != 0)
      Result_["DataWarnings"] <- length(DataErr_ls$Warnings)
    if (length(FileErr_) != 0)
      Result_["FileErrors"] <- length(FileErr_)
    Result_
  }


