#============
#visioneval.R
#============

#This script defines the main functions that implement the VisionEval framework
#and are intended to be exported. This script will include additional functions
#that will check a model for consistency and completeness.


#DEFINE A FUNCTION TO INITIALIZE A MODEL
#=======================================
#' Initialize a VisionEval model.
#'
#' \code{initializeModel}Function initializes a VisionEval model given the
#' location of files that establish model parameters and geography.
#'
#' This function does several things to initialize the model environment and
#' datastore including: initializing an environment named E in the global
#' environment that is used to keep track of key variables and the state of the
#' datastore, initializes a log to which messages are written, creates the
#' datastore and initializes its structure, reads in and checks the geographic
#' specifications, and initializes the geography in the datastore.
#'
#' @param Dir A string identifying the relative or absolute path to the
#'   directory where the parameter and geography definition files are located.
#' @param ParamFile A string identifying the name of a JSON-formatted text file
#'   that contains parameters needed by the framework in order to set up the
#'   working environment.
#' @param GeoFile A string identifying the name of a text file in
#'   comma-separated values format that contains the geographic specifications
#'   for the model.
#' @return None
#' @export
initializeModel <- function(Dir = "defs", ParamFile = "parameters.json",
                            GeoFile = "geo.csv") {
  initEnv(Dir = Dir, ParamFile = ParamFile)
  initLog()
  initDatastore()
  readGeography(Dir = Dir, GeoFile = GeoFile)
  initDatastoreGeography()
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
#' @param PackageName A string identifying the name of the package the module is
#'   a part of.
#' @param Year A string identifying the run year.
#' @param IgnoreInp_ A string vector identifying the names of any inputs
#'   specified by the module that are to be ignored.
#' @param IgnoreSet_ A string vector identifying the names of any data items in
#'   the module's 'Set' specifications that are to be ignored.
#' @return None. The function writes results to the specified locations in the
#'   datastore.
#' @export

runModule <- function(ModuleName, PackageName, Year, IgnoreInp_ = NULL, IgnoreSet_ = NULL) {
  #Log and print starting message
  Message <- paste("Starting module", ModuleName)
  writeLog(Message)
  print(Message)
  #Load the package and module
  requireNamespace(PackageName)
  Module <<- eval(parse(text = paste0(PackageName, "::", ModuleName, "()")))
  #Module <- eval(parse(text = paste0(PackageName, "::", ModuleName, "()")))
  #Load inputs
  processModuleInputs(Module$Inp, ModuleName, Dir = "inputs",
                      OnlyCheck = FALSE, Ignore_ = IgnoreInp_)
  #Run procedure if RunBy = All
  if (Module$RunBy == "All") {
    #Read inputs
    for (i in 1:length(Module$Get)) {
      Spec_ls <- Module$Get[[i]]
      Name <- Spec_ls$NAME
      Table <- Spec_ls$TABLE
      Data_ <- readFromTable(Name, Table, Year, Index = NULL)
      assign(Name, Data_, envir = Module)
    }
    #Run module
    Module$main()
    #Write results to datastore
    Sets_ <- sapply(Module$Set, function(x) x$NAME)
    SetSpecs_ls <- Module$Set[!(Sets_ %in% IgnoreSet_)]
    for (i in 1:length(SetSpecs_ls)) {
      Spec_ls <- SetSpecs_ls[[i]]
      Spec_ls$MODULE <- Module$Name
      Name <- Spec_ls$NAME
      writeToTable(Module[[Name]], Spec_ls, Year, Index = NULL)
    }
  } else {
    #Create index function for each Get specification
    GetIdx_ <- lapply(Module$Get, function(x) {
      createIndex(Module$RunBy, x$TABLE, Year)
    })
    #Create index function for each Set specifications that is not ignored
    Sets_ <- sapply(Module$Set, function(x) x$NAME)
    SetSpecs_ls <- Module$Set[!(Sets_ %in% IgnoreSet_)]
    SetIdx_ <- lapply(SetSpecs_ls, function(x) {
      createIndex(Module$RunBy, x$TABLE, Year)
    })
    RunByNames <- readFromTable(Name = Module$RunBy, Table = Module$RunBy, Year)
    for (ByName in RunByNames) {
      for (i in 1:length(Module$Get)) {
        Spec_ls <- Module$Get[[i]]
        Idx_ <- GetIdx_[[i]](ByName)
        Data_ <- readFromTable(Spec_ls$NAME, Spec_ls$TABLE, Year, Index = Idx_)
        assign(Spec_ls$NAME, Data_, envir = Module)
      }
      #Run module
      Module$main()
      #Write results to datastore
      for (i in 1:length(SetSpecs_ls)) {
        Spec_ls <- SetSpecs_ls[[i]]
        Spec_ls$MODULE <- Module$Name
        Name <- Spec_ls$NAME
        Idx_ <- SetIdx_[[i]](ByName)
        writeToTable(Module[[Name]], Spec_ls, Year, Index = Idx_)
      }
    }
  }
  rm("Module", envir = .GlobalEnv)
  unloadNamespace(PackageName)
  #gc()
}


#DEFINE A FUNCTION TO READ THE CONTENTS OF A MODULE
#==================================================
#' Read module contents.
#'
#' \code{readModule} reads the contents of a module and identifies whether any
#' components are missing.
#'
#' This function reads the contents of a module and identifies any components
#' are missing.
#'
#' @param ModuleName A string identifying the module name.
#' @param Package A string identifying the package that contains the module.
#' @return A list containing 2 components. The first is named 'Messages_' and is
#'   a list of error and warning messages. If this list is empty, then no errors
#'   or warnings were found. Each error or warning that is found relating to a
#'   component of the Module is stored in a component with the module name. The
#'   second component of this list is named 'Contents_' and is a list containing
#'   contents of the Module that are useful for checking the model. The
#'   components include 'ModuleName', 'PackageName', 'Inp', 'Get', and 'Set'.
#' @export
readModule <- function(ModuleName, PackageName) {
  Result_ <- list()
  Result_$Messages_ <- list()
  Result_$Contents_ <- list()
  Result_$Contents_$ModuleName <- ModuleName
  Result_$Contents_$PackageName <- PackageName
  #Check if package exists and return error message if it does not
  PackageExists <- require(PackageName, character.only = TRUE)
  if (!PackageExists) {
    Message <- paste("Package", PackageName, "has not been installed.")
    Result_$Messages_$Package <- Message
    return(Result_)
  }
  #Check if module exists and return error message if it does not
  ModuleExists <- ModuleName %in% ls(paste("package", PackageName, sep=":"))
  if (!ModuleExists) {
    Message <- paste("Module", ModuleName, "is not present in package.",
                     PackageName)
    Result_$Messages_$Module <- Message
    detach(paste("package", PackageName, sep=":"), character.only = TRUE)
    return(Result_)
  }
  #Load the module if it exists
  Module <- eval(parse(text = paste0(ModuleName, "()")))
  #Check if the module name property exists and if corresponds to ModuleName
  if (is.null(Module$Name)) {
    Message <- paste("Module", ModuleName, "is missing the 'Name' component.")
    Result_$Messages_$Name <- Message
  } else if (Module$Name != ModuleName) {
    Message <- paste("Module Name component is", Module$Name,
                     "but ModelName is", ModuleName)
    Result_$Messages_$Name <- Message
  }
  #Check whether there is a 'main' component
  if (is.null(Module$main)) {
    Message <- paste("Module", ModuleName, "is missing the 'Main' component.")
    Result_$Messages_$main <- Message
  }
  #Check whether there is an Inp component and get if there is
  if (is.null(Module$Inp)) {
    Message <- paste("Module", ModuleName, "is missing the 'Inp' component.")
    Result_$Messages_$Inp <- Message
  } else {
    Result_$Contents_$Inp <- Module$Inp
  }
  #Check whether there is a Get component and get if there is
  if (is.null(Module$Get)) {
    Message <- paste("Module", ModuleName, "is missing the 'Get' component.")
    Results_$Messages_$Get <- Message
  } else {
    Result_$Contents_$Get <- Module$Get
  }
  #Check whether there is a Set component and get if there is
  if (is.null(Module$Set)) {
    Message <- paste("Module", ModuleName, "is missing the 'Set' component.")
    Results_$Messages_$Set <- Message
  } else {
    Result_$Contents_$Set <- Module$Set
  }
  detach(paste("package", PackageName, sep=":"), character.only = TRUE)
  return(Result_)
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
#' @param PackageName A string identifying the name of the package where the
#'   module resides.
#' @param Year A string identifying the model run year.
#' @return A list having 2 components, Errors and Warnings. Each component is a
#'   vector of error and warning messages respectively. If their lengths are 0,
#'   there are no errors or warnings.
#' @export
checkModuleDependencies <- function(ModuleName, PackageName, Year) {
  Get_ls <- readModule(ModuleName, PackageName)$Contents$Get
  Errors_ <- character(0)
  Warnings_ <- character(0)
  for (i in 1:length(Get_ls)) {
    Name <- Get_ls[[i]][["NAME"]]
    Table <- Get_ls[[i]][["TABLE"]]
    Check <- checkDataset(Name, Table, Year, E$Datastore, ThrowError = TRUE)
    if (!Check[[1]]) {
      Message <- paste(
        "Dataset", Name, "in table", Table, "required by module",
        ModuleName, "is not present in datastore.")
      writeLog(Message)
      Errors_ <- c(Errors_, Message)
    } else {
      DstoreAttr_ <- getDatasetAttr(Name, Table, Year, E$Datastore)
      SpecCheck_ls <- checkSpecConsistency(Get_ls[[i]], DstoreAttr_)
      if (length(SpecCheck_ls$Errors) != 0) {
        Message <- SpecCheck_ls$Errors
        writeLog(Message)
        Errors_ <- c(Errors_, Message)
      }
      if (length(SpecCheck_ls$Warnings) != 0) {
        Message <- SpecCheck_ls$Warnings
        writeLog(Message)
        Warnings_ <- c(Warnings_, Message)
      }
    }
  }
  list(Errors = Errors_, Warnings = Warnings_)
}
