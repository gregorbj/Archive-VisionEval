#============
#visioneval.R
#============

#This script defines the main functions that implement the VisionEval framework
#and are intended to be exported.


#INITIALIZE MODEL
#================
#' Initialize model.
#'
#' \code{initializeModel}Function initializes a VisionEval model, loading all
#' parameters and inputs, and making checks to ensure that model can run
#' successfully.
#'
#' This function does several things to initialize the model environment and
#' datastore including:
#' 1) Initializing a file that is used to keep track of the state of key model
#' run variables and the datastore;
#' 2) Initializes a log to which messages are written;
#' 3) Creates the datastore and initializes its structure, reads in and checks
#' the geographic specifications and initializes the geography in the datastore,
#' or loads an existing datastore if one has been identified;
#' 4) Parses the model run script to identify the modules in their order of
#' execution and checks whether all the identified packages are installed and
#' the modules exist in the packages;
#' 5) Checks that all data requested from the datastore will be available when
#' it is requested and that the request specifications match the datastore
#' specifications;
#' 6) Checks all of the model input files to determine whether they they are
#' complete and comply with specifications.
#'
#' @param ParamDir A string identifying the relative or absolute path to the
#'   directory where the parameter and geography definition files are located.
#'   The default value is "defs".
#' @param RunParamFile A string identifying the name of a JSON-formatted text
#' file that contains parameters needed to identify and manage the model run.
#' The default value is "run_parameters.json".
#' @param GeoFile A string identifying the name of a text file in
#' comma-separated values format that contains the geographic specifications
#' for the model. The default value is "geo.csv".
#' @param ModelParamFile A string identifying the name of a JSON-formatted text
#' file that contains global model parameters that are important to a model and
#' may be shared by several modules.
#' @param DatastoreToLoad NULL or a string identifying the relative or absolute
#' path to a datastore to be copied to serve as the starting datastore for the
#' model run. The default value is NULL (no datastore will be copied).
#' @return None. The function prints to the log file messages which identify
#' whether or not there are errors in initialization. It also prints a success
#' message if initialization has been successful.
#' @export
initializeModel <-
  function(ParamDir = "defs",
           RunParamFile = "run_parameters.json",
           GeoFile = "geo.csv",
           ModelParamFile = "model_parameters.json",
           DatastoreToLoad = NULL) {
    #Initialize model state and log files
    #------------------------------------
    initModelStateFile(Dir = ParamDir, ParamFile = RunParamFile)
    initLog()
    #Initialize geography and load model parameters
    #----------------------------------------------
    if (is.null(DatastoreToLoad)) {
      initDatastore()
      readGeography(Dir = ParamDir, GeoFile = GeoFile)
      initDatastoreGeography()
      loadModelParameters(ModelParamFile = ModelParamFile)
      #Or load existing model datastore
    } else {
      loadDatastore(FileToLoad = DatastoreToLoad, GeoFile = GeoFile)
    }
    #Parse script to make table of all the module calls & check whether present
    #--------------------------------------------------------------------------
    ModuleCalls_df <- parseModelScript(FilePath = "run_model.R")
    #Check that all module packages are installed and all modules are present
    ModuleCheck <- checkModulesExist(ModuleCalls_df = ModuleCalls_df)
    #Make data transactions simulation list
    #--------------------------------------
    Transactions_ls <-
      simDataTransactions(ModuleCalls_df = ModuleCalls_df)
    #Check simulated transactions
    #----------------------------
    #Check whether modules are overwriting data items
    if (length(Transactions_ls$Err) != 0) {
      ErrorMsg <-
        paste("One or more modules will overwrite dataset created by other modules.",
              "Check log for details.")
      writeLog(Transactions_ls$Err)
      stop(ErrorMsg)
    }
    #Check data transactions
    Check_ls <- checkSimTransactions(Transactions_ls = Transactions_ls)
    HasErrors_ <- unlist(lapply(Check_ls, function(x) x$HasErrors))
    HasWarnings_ <- unlist(lapply(Check_ls, function(x) x$HasWarnings))
    if (any(HasWarnings_)) {
      WarningMsg_ <-
        do.call(c, lapply(Check_ls[HasWarnings_], function(x) x$Warnings))
      writeLog(WarningMsg_)
      warning("Data transactions check has one or more warnings. Check log for listing.")
    }
    if (any(HasErrors_)) {
      ErrorMsg_ <-
        do.call(c, lapply(Check_ls[HasErrors_], function(x) x$Errors))
      writeLog(ErrorMsg_)
      stop("Data transactions check has one or more errors! Check log for listing.")
    }
    #Load inputs into datastore
    #--------------------------
    AllInp_ls <- Transactions_ls$Out$Inp
    #First check whether there are errors
    InpCheck_ls <-
      processModuleInputs(Inp_ls = AllInp_ls, Dir = "inputs", OnlyCheck = TRUE)
    #If there are no errors then load all the inputs
    if (InpCheck_ls["FileErrors"] == 0 & InpCheck_ls["DataErrors"] == 0) {
      processModuleInputs(Inp_ls = AllInp_ls, Dir = "inputs", OnlyCheck = FALSE)
    } else {
      ErrorMsg <-
        paste("There are one or more errors in scenario input files.",
              "Check log for details.")
      stop(ErrorMsg)
    }
    #If no errors print out message
    #------------------------------
    SuccessMsg <- "Model successfully initialized."
    writeLog(SuccessMsg)
    print(SuccessMsg)
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
#' @return None. The function writes results to the specified locations in the
#'   datastore and prints a message to the console when the module is being run.
#' @export

runModule <- function(ModuleName, PackageName, Year) {
  #Log and print starting message
  #------------------------------
  Message <- paste("Starting module", ModuleName)
  writeLog(Message)
  print(Message)
  #Load the package and module
  #---------------------------
  Function <- paste0(PackageName, "::", ModuleName)
  Specs <- paste0(PackageName, "::", ModuleName, "Specifications")
  requireNamespace(PackageName)
  M <- list()
  M$Func <- eval(parse(text = Function))
  M$Specs <- processModuleSpecs(eval(parse(text = Specs)))
  #Read the model run state
  #------------------------
  G <- getModelState()
  G$Year <- Year
  #Run procedure if RunBy = Region
  #-------------------------------
  if (M$Specs$RunBy == "Region") {
    #Initialize list that will be passed to module
    L <- list()
    #Add the model run state to the input list
    L$G <- G
    #Fetch data identified in Get specs
    for (i in 1:length(M$Specs$Get)) {
      Spec_ls <- M$Specs$Get[[i]]
      #Identify Group, Table and Name to get data from
      if (Spec_ls$GROUP == "Global") Group <- "Global"
      if (Spec_ls$GROUP == "BaseYear") Group <- G$BaseYear
      if (Spec_ls$GROUP == "Year") Group <- Year
      Table <- Spec_ls$TABLE
      Name <- Spec_ls$NAME
      #Fetch the data and add to the input list
      Data_ <- readFromTable(Name, Table, Group)
      L[[Name]] <- Data_
    }
    #Run module and assign return value to list (R)
    R <- M$Func(L)
    #Write results to datastore
    SetSpecs_ls <- M$Specs$Set
    for (i in 1:length(SetSpecs_ls)) {
      Spec_ls <- SetSpecs_ls[[i]]
      #Identify the Group, Table and Name to assign to
      if (Spec_ls$GROUP == "Global") Group <- "Global"
      if (Spec_ls$GROUP == "BaseYear") Group <- G$BaseYear
      if (Spec_ls$GROUP == "Year") Group <- Year
      Table <- Spec_ls$TABLE
      Name <- Spec_ls$NAME
      #Assign a MODULE attribute to the specifications
      Spec_ls$MODULE <- ModuleName
      #Assign table LENGTH and data SIZE attributes
      if (is.null(Spec_ls$LENGTH) & !is.null(R$LENGTH[Table])) {
        Spec_ls$LENGTH <- R$LENGTH[Table]
      }
      if (is.null(Spec_ls$SIZE) & !is.null(R$SIZE[Name])) {
        Spec_ls$SIZE <- R$SIZE[Name]
      }
      #Write the dataset
      writeToTable(Data_ = R[[Name]],
                   Spec_ls = Spec_ls,
                   Group = Group,
                   Index = NULL)
    }
    #Run procedure by geographic area
    #--------------------------------
  } else {
    #Create index function for each Get specification
    GetIdx_ <- lapply(M$Specs$Get, function(x) {
      if (x$GROUP == "Global") Group <- "Global"
      if (x$GROUP == "BaseYear") Group <- G$BaseYear
      if (x$GROUP == "Year") Group <- Year
      createIndex(M$Specs$RunBy, x$TABLE, Group)
    })
    #Create index function for each Set specifications that is not ignored
    SetIdx_ <- lapply(M$Specs$Set, function(x) {
      if (x$GROUP == "Global") Group <- "Global"
      if (x$GROUP == "BaseYear") Group <- G$BaseYear
      if (x$GROUP == "Year") Group <- Year
      createIndex(M$Specs$RunBy, x$TABLE, Year)
    })
    #Get vector of geography names to run by
    RunByNames <- readFromTable(Name = M$Specs$RunBy, Table = M$Specs$RunBy, Year)
    #Run for each geographic area
    for (ByName in RunByNames) {
      #Initialize list that will be passed to module
      L <- list()
      #Add the model run state to the input list
      L$G <- G
      #Make list of module inputs specified by Get specs
      for (i in 1:length(M$Specs$Get)) {
        Spec_ls <- M$Specs$Get[[i]]
        #Identify Group, Table and Name to get data from
        if (Spec_ls$GROUP == "Global") Group <- "Global"
        if (Spec_ls$GROUP == "BaseYear") Group <- G$BaseYear
        if (Spec_ls$GROUP == "Year") Group <- Year
        Table <- Spec_ls$TABLE
        Name <- Spec_ls$NAME
        #Generate the position index
        Idx_ <- GetIdx_[[i]](ByName)
        #Read the data and assign to the list
        Data_ <- readFromTable(Name, Table, Group, Index = Idx_)
        L[[Name]] <- Data_
      }
      #Run module and assign return value to list (R)
      R <- M$Func(L)
      #Write results to datastore
      for (i in 1:length(M$Specs$Set)) {
        Spec_ls <- M$Specs$Set[[i]]
        #Identify the Group, Table and Name to assign to
        if (Spec_ls$GROUP == "Global") Group <- "Global"
        if (Spec_ls$GROUP == "BaseYear") Group <- G$BaseYear
        if (Spec_ls$GROUP == "Year") Group <- Year
        Table <- Spec_ls$TABLE
        Name <- Spec_ls$NAME
        #Assign a MODULE attribute to the specifications
        Spec_ls$MODULE <- ModuleName
        #Generate the position index
        Idx_ <- SetIdx_[[i]](ByName)
        #Assign table LENGTH and data SIZE attributes
        if (is.null(Spec_ls$LENGTH) & !is.null(R$LENGTH[Table])) {
          Spec_ls$LENGTH <- R$LENGTH[Table]
        }
        if (is.null(Spec_ls$SIZE) & !is.null(R$SIZE[Name])) {
          Spec_ls$SIZE <- R$SIZE[Name]
        }
        #Write the dataset
        writeToTable(Data_ = R[[Name]],
                     Spec_ls = Spec_ls,
                     Group = Group,
                     Index = Idx_)
      }
    }
  }
  unloadNamespace(PackageName)
}
