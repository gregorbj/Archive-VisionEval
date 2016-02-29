#============
#visioneval.R
#============

#This script defines the main functions that implement the VisionEval framework
#and are intended to be exported.


#INITIALIZE MODEL
#================
#' Initialize model.
#'
#' \code{initializeModel}Function initializes a VisionEval model given the
#' location of files that establish model parameters and geography.
#'
#' This function does several things to initialize the model environment and
#' datastore including: initializing a file that is used to keep track of the
#' state of key model run variables and the datastore, initializes a log to
#' which messages are written, creates the datastore and initializes its
#' structure, reads in and checks the geographic specifications, and initializes
#' the geography in the datastore. <TO DO: ENABLE LOADING OF EXISTING DATASTORE,
#' CHECK WHETHER ALL SPECIFIED PACKAGES EXIST, WHETHER SPECIFIED INPUT FILES
#' EXIST AND CONTENTS ARE CORRECT, AND WHETHER ALL DATA DEPENDENCIES WIL BE
#' SATISFIED.>
#'
#' @param Dir A string identifying the relative or absolute path to the
#'   directory where the parameter and geography definition files are located.
#'   The default value is "defs".
#' @param ParamFile A string identifying the name of a JSON-formatted text file
#'   that contains global parameters needed by the framework in order to set up
#'   the working environment. The default value is "parameters.json".
#' @param GeoFile A string identifying the name of a text file in
#'   comma-separated values format that contains the geographic specifications
#'   for the model. The default value is "geo.csv".
#' @return None
#' @export
initializeModel <- function(Dir = "defs", ParamFile = "parameters.json",
                            GeoFile = "geo.csv") {
  initModelStateFile(Dir = Dir, ParamFile = ParamFile)
  initLog()
  initDatastore()
  readGeography(Dir = Dir, GeoFile = GeoFile)
  initDatastoreGeography()
}


#RUN MODULE
#==========
#' Run module.
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

runModule <- function(ModuleName, PackageName, Year, IgnoreInp_ = NULL,
                      IgnoreSet_ = NULL) {
  #Log and print starting message
  Message <- paste("Starting module", ModuleName)
  writeLog(Message)
  print(Message)
  #Load the package and module
  requireNamespace(PackageName)
  M <- list()
  M$Func <- eval(parse(text = paste0(PackageName, "::", ModuleName)))
  M$Specs <- eval(parse(text = paste0(PackageName, "::", ModuleName, "Specifications")))
  #Load inputs
  processModuleInputs(M$Specs$Inp, ModuleName, Dir = "inputs",
                      OnlyCheck = FALSE, Ignore_ = IgnoreInp_)
  #Run procedure if RunBy = Region
  if (M$Specs$RunBy == "Region") {
    #Read inputs
    L <- list()
    DataNames_ <- character(0)
    for (i in 1:length(M$Specs$Get)) {
      Spec_ls <- M$Specs$Get[[i]]
      IsGlobalTable <- unlist(strsplit(Spec_ls$TABLE, "/"))[1] == "Global"
      if (IsGlobalTable) {
        Spec_ls$TABLE <- unlist(strsplit(Spec_ls$TABLE, "/"))[2]
        Year <- "Global"
      }
      Name <- Spec_ls$NAME
      DataNames_[i] <- Name
      Table <- Spec_ls$TABLE
      Data_ <- readFromTable(Name, Table, Year)
      L[[i]] <- Data_
    }
    names(L) <- DataNames_
    #Run module and assign return value to list (R)
    R <- M$Func(L)
    #Write results to datastore
    Sets_ <- sapply(M$Specs$Set, function(x) x$NAME)
    SetSpecs_ls <- M$Specs$Set[!(Sets_ %in% IgnoreSet_)]
    for (i in 1:length(SetSpecs_ls)) {
      Spec_ls <- SetSpecs_ls[[i]]
      Spec_ls$MODULE <- ModuleName
      Name <- Spec_ls$NAME
      Table <- Spec_ls$TABLE
      if (is.null(Spec_ls$LENGTH) & !is.null(R$LENGTH[Table])) {
        Spec_ls$LENGTH <- R$LENGTH[Table]
      }
      if (is.null(Spec_ls$SIZE) & !is.null(R$SIZE[Name])) {
        Spec_ls$SIZE <- R$SIZE[Name]
      }
      writeToTable(R[[Name]], Spec_ls, Year, Index = NULL)
    }
  } else {
    #Create index function for each Get specification
    GetIdx_ <- lapply(M$Specs$Get, function(x) {
      createIndex(M$Specs$RunBy, x$TABLE, Year)
    })
    #Create index function for each Set specifications that is not ignored
    Sets_ <- sapply(M$Specs$Set, function(x) x$NAME)
    SetSpecs_ls <- M$Specs$Set[!(Sets_ %in% IgnoreSet_)]
    SetIdx_ <- lapply(SetSpecs_ls, function(x) {
      createIndex(M$Specs$RunBy, x$TABLE, Year)
    })
    RunByNames <- readFromTable(Name = M$Specs$RunBy, Table = M$Specs$RunBy, Year)
    for (ByName in RunByNames) {
      L <- list()
      DataNames_ <- character(0)
      for (i in 1:length(M$Specs$Get)) {
        Spec_ls <- M$Specs$Get[[i]]
        IsGlobalTable <- unlist(strsplit(Spec_ls$TABLE, "/"))[1] == "Global"
        if (IsGlobalTable) {
          Spec_ls$TABLE <- unlist(strsplit(Spec_ls$TABLE, "/"))[2]
          Year <- "Global"
        }
        Idx_ <- GetIdx_[[i]](ByName)
        Name <- Spec_ls$NAME
        DataNames_[i] <- Name
        Table <- Spec_ls$TABLE
        Data_ <- readFromTable(Name, Table, Year, Index = Idx_)
        L[[i]] <- Data_
      }
      names(L) <- DataNames_
      #Run module and assign return value to list (R)
      R <- M$Func(L)
      #Write results to datastore
      for (i in 1:length(SetSpecs_ls)) {
        Spec_ls <- SetSpecs_ls[[i]]
        Spec_ls$MODULE <- ModuleName
        Name <- Spec_ls$NAME
        Idx_ <- SetIdx_[[i]](ByName)
        Table <- Spec_ls$TABLE
        if (is.null(Spec_ls$LENGTH) & !is.null(R$LENGTH[Table])) {
          Spec_ls$LENGTH <- R$LENGTH[Table]
        }
        if (is.null(Spec_ls$SIZE) & !is.null(R$SIZE[Name])) {
          Spec_ls$SIZE <- R$SIZE[Name]
        }
        writeToTable(R[[Name]], Spec_ls, Year, Index = Idx_)
      }
    }
  }
  unloadNamespace(PackageName)
}


