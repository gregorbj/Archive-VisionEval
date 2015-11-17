#=====================
#make_TDM_module.r
#=====================

#This script demonstrates the basic elements of a module for the RSPM framework. The active functions in the script are derived from functions that are part of the GreenSTEP/RSPM model. The 'idEcoWorkers' function identifies the number of workers in each household who participate in strong employee commute options programs. The 'idImpHouseholds' function identifies whether a household is a participant in an individualize marketing program (i.e. a target travel demand management program). Following are important characteristics of the script:

#* The two active functions are defined first in the script. Note that these functions are commented in a particular fashion to show what has been changed from the functions in the GreenSTEP/RSPM models. Lines that start with '###' are lines which are in the original functions but are commented out because they don't work within the framework. Lines that end in '###' are code that has been added to replace the original or otherwise make the function work within the framework. By examining the code, you can see that it is fairly straightforward to modify functions to operate in the framework. In most cases the changes reflect the fact that the data the function operates on data vectors in the execution environment, rather than on data frames that are passed to the functions. It is important to note how these functions return their results. This is done by explicitly assigning the output to the execution environment which is named 'Module' (and should only be named 'Module').

#* At the bottom of the script is a function named 'buildModule' which creates the module object. After the function has been defined, it is invoked and the return value assigned to an object that is the name of the module. In this case the module is named 'IdTdmHouseholds', For this demo script, the 'IdTdmHouseholds' object is saved as a binary file in a folder named 'modules' with a file name that is the same as the module name. In the RSPM framework, the module would reside in a package instead. A more detailed description of the contents of the 'buildModule' function follows:

#The 'buildModule' function creates an environment named 'Module' and all the information needed for the module to operate in the framework is added to this environment in the same way that information is added to a list. Following are notes on the key elements. These are numbered as the comments which separate the function into blocks of code are numbered.
#1. The first line, 'Module <- new.env()', creates the environment. This line will be the same in all modules.
#2. The active functions are assigned to the 'Module' environment. The execution environment for these functions is set to be the 'Module'.
#3. A main function is defined which calls the active functions in the desired order. Note that these functions need to be called by their full module name, rather than just the function name: e.g. 'Module$idEcoWorkers' and not 'idEcoWorkers'. Also, note that since each function returns its results to the created environment, functions can use the outputs of preceding functions in their calculations. Once the main function has been defined, its environment is set to be the 'Module' environment.
#4. All model parameters (as opposed to inputs) are defined in this code block. If the developer wants to make it possible for users to establish their own parameters, they would define a function to do so and call it here.
#5. Although some modules might be run on all records of a dataset at once, most will be run iteratively on subsets of the data. The assignment to 'RunBy' establishes the level of geography that is iterated over. For example, in this script it is set to 'Marea' so the script will iterate over metropolitan areas to run.
#6. Scenario inputs files and their characteristics are identified in the 'Inp' portion of the module. 'Inp' is a list which has as many components are there are input files to be loaded. In this case, since there is only one file to be loaded, there is only one component named 'TDM'. Developers can name these components whatever they wish. Each file component contains 3 components in turn named 'File', 'GeoLvl', and 'Fields'. The 'File' component identifies the name of the file to be loaded. The 'GeoLvl' component identify the geography level that the input file is organized by. In this case, the input file contains 'Marea' (metropolitan area) scenario data. The 'Fields' component is a list which identifies each data field and describes essential characteristics. Each of the components is named using the field name that appears in the input file. The essential characteristics of each field are contained in a list that contains the following assignments:
#  * TYPE - the data type for the field ("integer", "double", "character", or "logical")
#  * UNITS - the units of measure for the field (if the field is unitless, the value should be "None")
#  * NAVALUE - the value that will be used to code NA values in the datastore (since that datastore can't store NA itself)
#  * PROHIBIT - a vector of conditions which describe prohibited input values (e.g. "< 0" means no negative numbers allowed)
#  * UNLIKELY - a vector of conditions which describe unlikely (but not prohibited) input values that the user is advised to check for correctness
#7. Data that is to be loaded from the datastore (as opposed to scenario input files) is identified in the 'Module' component named 'Get'. This component identifies all of the data to be loaded organized by table in the datastore. In this case, it contains 2 components, 'Marea' and 'Household' because it need data to be loaded from each of these tables. Data to be loaded from the 'Marea' table include 'PropWrkEco' and 'ImpPropGoal', while data to be loaded from the 'Household' table include 'Houseid', 'DrvAgePop', 'Htppopdn', and 'Urban'. For each dataset there is a list of key attributes to be checked to determine whether the data meets specifications for the module. These include TYPE (the data type), UNITS (the units of measure), and PROHIBIT (the specifications of prohibited values). The framework checks whether the data in the datastore meets these specifications. It will identify an error if the TYPE and PROHIBIT specifications are not consistent. It will identify a warning if the UNITS are not consistent.
#8. Results of functions that are executed by the module are assigned to the module environment. Some of these results may be saved to the datastore. The 'Set' component of 'Module' identifies the results to be saved and their key attributes to be saved with them. 'Set' is a list that is organized in the same way as 'Get', by table and then by dataset in each table. Key attributes (TYPE, UNITS, NAVALUE, PROHIBIT, SIZE) are defined for each dataset. The first four of these are described above. The last, SIZE, identifies the maximum number of characters for 'character' type data. Since the datastore stores character data in fixed-length records, the SIZE attribute has to identify a size that will be adequate to store all possible entries. It is incumbent on the module developer to determine what that will be. Non-character data is assigned a SIZE value of 0.
#9. The 'Module' environment is returned from the function.


#FUNCTION TO IDENTIFY THE NUMBER OF PARTICIPATING ECO WORKERS IN EACH HOUSEHOLD
#==============================================================================
#' Identify the number of ECO participating workers in each household.
#'
#' \code{idEcoWorkers} identifies the number of workers in each household who
#' work for an employer who has a strong employee commute options (ECO) program.
#'
#' This function identifies the number of workers in each household who work for
#' an employer who has a strong employee commute options (ECO) program. It does
#' this based on a metropolitan area present day estimate or future year goal
#' for the proportion of metropolitan area employees 'PropWrkEco' who work for
#' employers who have strong employee commute option programs (e.g. transit
#' pass, guaranteed ride home, carpool preferred parking, etc.). Since the
#' GreenSTEP/RSPM model does not identify workers, only working age persons, the
#' function multiplies 'PropWrkEco' by the average labor force participation
#' rate ('LabForcePartRate') which is set at 0.65 to get the proportion of
#' working age persons who work at employers having strong ECO programs. This
#' then used to calculate the number of working age persons at strong ECO
#' employers. A random sample of this size is drawn from all working age persons
#' and tabulated by household to identify the number of ECO workers in each
#' household.
#'
#' @return A vector identifying the number of ECO workers in each household. The result is assigned to 'NumEco' in the module environment.
#'
###idEcoWorkers <- function( Data.., PropWrkEco, LabForcePartRate=0.65 ) {
idEcoWorkers <- function() {
  if (PropWrkEco == 0) {
    NumEco.Hh <- numeric(length(Houseid)) ###Short circuit calc when none
  } else {
    # Calculate number of working age persons that are in ECO program
    PropWrkAgeEco <- PropWrkEco * LabForcePartRate
    ###NumWrkAgePer <- sum( Data..$DrvAgePop )
    NumWrkAgePer <- sum(DrvAgePop) ###
    NumWrkAgeEco <- round( PropWrkAgeEco * NumWrkAgePer )
    # Identify which persons are in ECO program
    ###WrkHhId. <- rep( Data..$Houseid, Data..$DrvAgePop )
    WrkHhId. <- rep( Houseid, DrvAgePop ) ###
    HhIdEco. <- sample( WrkHhId. )[ 1:NumWrkAgeEco ]
    # Identify the number of persons in each household who are in ECO program
    NumHhEco. <- tapply( HhIdEco., HhIdEco., function(x) length(x) )
    ###NumEco.Hh <- numeric( nrow( Data.. ) )
    NumEco.Hh <- numeric(length(Houseid)) ###
    ###names( NumEco.Hh ) <- Data..$Houseid
    names( NumEco.Hh ) <- Houseid ###
    NumEco.Hh[ names( NumHhEco. ) ] <- NumHhEco.
  }
  # Return the result
  ###NumEco.Hh
  storage.mode(NumEco.Hh) <- "integer" ###
  assign("NumEco", NumEco.Hh, envir = Module) ###
}


#FUNCTION TO IDENTIFY WHETHER HOUSEHOLDS PARTICIPATE IN IMP
#==========================================================
#' Identify households participating in IMP.
#'
#' \code{idEcoWorkers} identifies whether households participate in
#' individualized marketing programs (IMP).
#'
#' This function identifies which households participate in individualized
#' marketing programs (IMP) which are travel demand programs focused on
#' individualized or localized outreach rather than broadcast outreach. The
#' total number of households identified as IMP households is based a
#' metropolitan area present day estimate or future year goal for the proportion
#' of households who participate. The households who are candidates for
#' participating are limited to those who live in neighborhoods having densities
#' exceeding a density threshold ('DenThrshold') and are characterized by mixed
#' uses ('MixRequired'). A random sample of candidate households is chosen to
#' achieve the total number of IMP households or if he total number exceeds the
#' number of candidate households, all candidates are chosen.
#'
#' @return A vector identifying whether each household is a participant where
#'   the value 1 means participating and the value 0 means not participating.
#'   The result is assigned to 'ImpHh' in the module environment.
#'
###idImpHouseholds <- function( Data.., ImpPropGoal, DenThrshold=4000, MixRequired=TRUE ) {
idImpHouseholds <- function() {
  if (ImpPropGoal == 0) {
    ImpHh. <- numeric(length(Houseid)) ###Short circuit calc when none
  } else {
    # Identify numeric goal and candidates
    ###NumHh <- nrow( Data.. )
    NumHh <- length(Houseid) ###
    NumImpHh <- NumHh * ImpPropGoal
    # Identify candidates
    if( MixRequired ) {
      ###IsCandidate. <- Data..$Htppopdn >= DenThrshold & Data..$Urban == 1
      IsCandidate. <- Htppopdn >= DenThrshold & Urban == 1 ###
    } else {
      ###IsCandidate. <- Data..$Htppopdn >= DenThrshold
      IsCandidate. <- Htppopdn >= DenThrshold ###
    }
    NumCandidates <- sum( IsCandidate. )
    # Identify the IMP households
    if( NumCandidates <= NumImpHh ) {
      ImpHh. <- IsCandidate. * 1
    } else {
      ###CandidateHhId. <- Data..$Houseid[ IsCandidate. ]
      CandidateHhId. <- Houseid[ IsCandidate. ] ###
      CandidateHhId. <- sample( CandidateHhId. )[ 1:NumImpHh ]
      ImpHh. <- numeric( NumHh )
      ###ImpHh.[ Data..$Houseid %in% CandidateHhId. ] <- 1
      ImpHh.[ Houseid %in% CandidateHhId. ] <- 1 ###
    }
  }
  # Return the result
  #list( ImpHh=ImpHh., NumImpHh=NumImpHh, NumCandidates=NumCandidates )
  storage.mode(ImpHh.) <- "integer" ###
  assign("ImpHh", ImpHh., envir = Module) ###
}


#FUNCTION TO BUILD THE MODULE
#============================
#' Build the module.
#'
#' \code{buildModule} builds the module that will carry out the models for
#' identifying ECO workers and IMP households.
#'
#' This function builds the module that will carry out the models for
#' identifying ECO workers and IMP households. This is done by creating an
#' environment in which the functions, parameters and specifications are
#' assigned as described above.
buildModule <- function() {
  #1. Create an environment to hold the module components
  Module <- new.env()
  #2. Add functions and assign their environments to be 'Module'
  Module$idEcoWorkers <- idEcoWorkers
  environment(Module$idEcoWorkers) <- Module
  Module$idImpHouseholds <- idImpHouseholds
  environment(Module$idImpHouseholds) <- Module
  #3. Define a main function which calls the other functions
  Module$main <- function() {
    Module$idEcoWorkers()
    Module$idImpHouseholds()
  }
  #4. Define model parameters
  Module$LabForcePartRate <- 0.65
  Module$DenThrshold <- 4000
  Module$MixRequired <- TRUE
  #5. Identify the level of geography that is iterated over when running the module
  Module$RunBy <- "Marea"
  #6. Identify scenario input files and characteristics
  Module$Inp <- items(
    item(
         NAME = "PropWrkEco",
         FILE = "mdt.csv",
         GEO = "Marea",
         TYPE = "double",
         UNITS = "None",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0", "> 1"),
         ISELEMENTOF = NULL,
         UNLIKELY = NULL,
         TOTAL = NULL
        ),
    item(
         NAME = "ImpPropGoal",
         FILE = "tdm.csv",
         GEO = "Marea",
         TYPE = "double",
         UNITS = "None",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0", "> 1"),
         ISELEMENTOF = NULL,
         UNLIKELY = NULL,
         TOTAL = NULL
        ),
    item(
      NAME = "PropWrkEco",
      FILE = "tdm.csv",
      GEO = "Marea",
      TYPE = "double",
      UNITS = "None",
      NAVALUE = -9999,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = NULL,
      UNLIKELY = NULL,
      TOTAL = NULL
    ),
    item(
      NAME = "ImpPropGoal",
      FILE = "mdt.csv",
      GEO = "Marea",
      TYPE = "double",
      UNITS = "None",
      NAVALUE = -9999,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = NULL,
      UNLIKELY = NULL,
      TOTAL = NULL
    )
  )
  #7. Identify data to be loaded from data store
  Module$Get <- items(
    item(
         NAME = "PropWrkEco",
         TABLE = "Marea",
         TYPE = "double",
         UNITS = "None",
         PROHIBIT = c("NA", "< 0", "> 1")
         ISELEMENTOF = NULL,
    ),
    item(
         NAME = "ImpPropGoal",
         TABLE = "Marea",
         TYPE = "double",
         UNITS = "None",
         PROHIBIT = c("NA", "< 0", "> 1")
         ISELEMENTOF = NULL,
    ),
    item(
         NAME = "Houseid",
         TABLE = "Household",
         TYPE = "character",
         UNITS = "None",
         PROHIBIT = "NA"
         ISELEMENTOF = NULL,
    ),
    item(
         NAME = "DrvAgePop",
         TABLE = "Household",
         TYPE = "integer",
         UNITS = "Persons",
         PROHIBIT = c("NA", "< 0")
         ISELEMENTOF = NULL,
    ),
    item(
         NAME = "Htppopdn",
         TABLE = "Household",
         TYPE = "double",
         UNITS = "Persons Per Square Mile",
         PROHIBIT = c("NA", "< 0")
         ISELEMENTOF = NULL,
    ),
    item(
         NAME = "Urban",
         TABLE = "Household",
         TYPE = "integer",
         UNITS = "Persons Per Square Mile",
         PROHIBIT = c("NA", "< 0", "> 1")
         ISELEMENTOF = NULL,
    )
  )
  #8. Identify data to store
  Module$Set <- items(
    item(
         NAME = "NumEco",
         TABLE = "Household",
         TYPE = "integer",
         UNITS = "Persons",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0"),
         ISELEMENTOF = NULL,
         SIZE = 0
        ),
    item(
         NAME = "ImpHh",
         TABLE = "Household",
         TYPE = "integer",
         UNITS = "None",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0", "> 1"),
         ISELEMENTOF = NULL,
         SIZE = 0
        )
  )
  #9. Return the Module object
  Module
}
IdTdmHouseholds <- buildModule()
save(IdTdmHouseholds, file = "modules/IdTdmHouseholds.RData")
rm(buildModule, idEcoWorkers, idImpHouseholds, IdTdmHouseholds)
