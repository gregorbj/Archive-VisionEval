#====================
#SimulateEmployment.R
#====================

#<doc>
#
## SimulateEmployment Module
#### February 5, 2019
#
#This module assign workers SimBzone work locations. A worker table is created which identifies a unique worker ID, the household ID the worker is a part of, and the SimBzone, Azone, and Marea of the worker job location.
#
### Model Parameter Estimation
#
#This module has no parameters. Workers are assigned to Bzone job locations using simple rules as described in the following section.
#
### How the Module Works
#
#The module operates at the Marea level. The process for allocating workers to jobsites follows the logic of the process used by the 'CreateSimBzones' to calculate jobs and allocating them SimBzones. Since 'CreatesSimBzones' module creates jobs in the Azones of of each Marea based on the number of workers, jobs and workers are balanced. Following the same procedure for allocating workers to jobsites assures that the balance is maintained. Following are the steps in the process carried out for each Marea:
#
#1) For each Azone, workers residing in the Azone are assigned to Rural, Town, or Urban job locations. The numbers assigned to Rural and Town locations are equal to the numbers of Rural and Town jobs in the Azone respectively. The remaining workers are assigned to Urban jobs. The assignment to job location type is made randomly. In other words, the characteristics of the household the worker is a part of and the characteristics of the SimBzone they reside in do not affect the their job location type.
#
#2) For each Azone, workers identified as having Rural and Town job locations are assigned to Rural and Town SimBzone job locations in the Azone. The assignment is random but consistent with the numbers of jobs allocated to each SimBzone.
#
#3) For the whole Marea, workers identified as having Urban job locations are assigned to Urban SimBzone job locations in any of the Urban SimBzones in the Marea. The assignment is random but consistent with the numbers of jobs allocated to each SimBzone.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. Employment is allocated to Bzones based on
#inputs, balancing with number of regional workers, and balancing workers by
#residence and job location as a function of the inverse of distance.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#' @import visioneval

#Define the data specifications
#------------------------------
SimulateEmploymentSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Worker",
      GROUP = "Year"
    )
  ),
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = items(
        "Azone",
        "Marea"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Bzone",
        "Azone",
        "Marea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TotEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    ),
    item(
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Bzone",
        "Azone"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("HhId",
              "WkrId"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID",
              "Unique worker ID")
    ),
    item(
      NAME = items(
        "Bzone",
        "Azone",
        "Marea"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Bzone ID of worker job location",
        "Azone ID of worker job location",
        "Marea ID of worker job location")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for SimulateEmployment module
#'
#' A list containing specifications for the SimulateEmployment module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source SimulateEmployment.R script.
"SimulateEmploymentSpecifications"
usethis::use_data(SimulateEmploymentSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module places workers in SimBzone job locations based on the number of
#jobs in rural and town locations of the Azone where the workers reside and the
#number of jobs in urban locations of the Marea where the workers reside.

#Main module function that assigns workers to Bzone employment locations
#-----------------------------------------------------------------------
#' Main module function to assign employment by type to Bzones.
#'
#' \code{SimulateEmployment} assigns workers to Bzones.
#'
#' This function assigns workers to Bzone employment based on inputs of
#' employment by type by Bzone, adjustment of employment to equal regionwide
#' total of workers, and identify Bzone employment location for each worker as
#' a function of the number of jobs in each Bzone and the inverse of distance
#' between Bzones.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name SimulateEmployment
#' @import visioneval
#' @export
SimulateEmployment <- function(L) {

  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  Ma <- unique(L$Year$Azone$Marea)
  Lt <- c("Urban", "Town", "Rural")
  #Initialize output list
  Out_ls <- initDataList()
  #Create the worker table
  NumWkr <- sum(L$Year$Household$Workers)
  Out_ls$Year$Worker <- list()
  attributes(Out_ls$Year$Worker)$LENGTH <- NumWkr
  #Initialize the worker datasets
  Out_ls$Year$Worker$HhId <- character(NumWkr)
  Out_ls$Year$Worker$WkrId <- character(NumWkr)
  Out_ls$Year$Worker$Bzone <- character(NumWkr)
  Out_ls$Year$Worker$Azone <- character(NumWkr)
  Out_ls$Year$Worker$Marea <- character(NumWkr)

  #----------------------------------------------
  #Iterate through Mareas and create Worker table
  #----------------------------------------------
  WriteStartIdx <- 1
  for (ma in Ma) {

    #Extract data frames of datasets to work with
    #--------------------------------------------
    Az <- L$Year$Azone$Azone[L$Year$Azone$Marea == ma]
    Hh_ls <- lapply(L$Year$Household, function(x) {
      x[L$Year$Household$Azone %in% Az]})
    Bzone_ls <- lapply(L$Year$Bzone, function(x) {
      x[L$Year$Bzone$Azone %in% Az]})

    #Create a list of workers
    #------------------------
    Worker_ls <- list()
    #Identify households having workers
    Use <- Hh_ls$Workers != 0
    #Create IDs for worker table
    Worker_ls$HhId <- with(Hh_ls, rep(HhId[Use], Workers[Use]))
    Worker_ls$WkrId <-
      with(Hh_ls,
           paste(
             rep(HhId[Use], Workers[Use]),
             unlist(sapply(Workers[Use], function(x) 1:x)),
             sep = "-"))
    #Identify the worker residence Azone
    Worker_ls$ResAzone <- with(Hh_ls, rep(Azone[Use], Workers[Use]))

    #Identify SimBzone work location
    #-------------------------------
    #Bzone_df <- data.frame(L$Year$Bzone)
    #Tabulate Azone employment by location type
    TotEmp_AzLt <- array(0, dim = c(length(Az), 3), dimnames = list(Az, Lt))
    TotEmp_AxLx <- with(Bzone_ls, tapply(TotEmp, list(Azone, LocType), sum))
    TotEmp_AzLt[rownames(TotEmp_AxLx),colnames(TotEmp_AxLx)] <- TotEmp_AxLx
    TotEmp_AzLt[is.na(TotEmp_AzLt)] <- 0
    rm(TotEmp_AxLx)
    #Tabulate workers by Azone
    NumWkr_Az <- with(Hh_ls, tapply(Workers, Azone, sum))
    #Tabulate worker job location types by Azone and location type
    NumWkr_AzLt <- t(sapply(Az, function(x) {
      Wkr_Lt <- c(Urban = 0, Town = TotEmp_AzLt[x,"Town"], Rural = TotEmp_AzLt[x,"Rural"])
      Wkr_Lt["Urban"] <- NumWkr_Az[x] - sum(Wkr_Lt)
      Wkr_Lt
    }))
    #Identify work location type
    Worker_ls$LocType <- character(length(Worker_ls$HhId))
    for (az in Az) {
      IsAz <- Worker_ls$ResAzone == az
      Worker_ls$LocType[IsAz] <-
        sample(rep(colnames(NumWkr_AzLt), NumWkr_AzLt[az,]))
    }

    #Assign work SimBzones for Town and Rural workers
    #------------------------------------------------
    Worker_ls$Bzone <- character(length(Worker_ls$HhId))
    for (az in Az) {
      for (lt in c("Town", "Rural")) {
        if (NumWkr_AzLt[az,lt] > 0) {
          Bx <- with(Bzone_ls, Bzone[Azone == az & LocType == lt])
          Emp_Bx <- with(Bzone_ls, TotEmp[Azone == az & LocType == lt])
          Worker_ls$Bzone[Worker_ls$ResAzone == az & Worker_ls$LocType == lt] <-
            sample(rep(Bx, Emp_Bx))
          rm(Bx, Emp_Bx)
        }
      }
    }

    #Assign work SimBzones for Urban workers
    #---------------------------------------
    if (sum(NumWkr_AzLt[,"Urban"]) > 0) {
      Bx <- Bzone_ls$Bzone[Bzone_ls$LocType == "Urban"]
      Emp_Bx <- Bzone_ls$TotEmp[Bzone_ls$LocType == "Urban"]
      Worker_ls$Bzone[Worker_ls$LocType == "Urban"] <- sample(rep(Bx, Emp_Bx))
      rm(Bx, Emp_Bx)
    }

    #Identify Azone and Marea
    #------------------------
    #Identify work Azone
    Worker_ls$Azone <-
      L$Year$Bzone$Azone[match(Worker_ls$Bzone, L$Year$Bzone$Bzone)]
    #Identify work Marea
    Worker_ls$Marea <-
      L$Year$Bzone$Marea[match(Worker_ls$Bzone, L$Year$Bzone$Bzone)]

    #Add to Out_ls
    #-------------
    WriteEndIdx <- WriteStartIdx + length(Worker_ls$HhId) - 1
    Out_ls$Year$Worker$HhId[WriteStartIdx:WriteEndIdx] <- Worker_ls$HhId
    Out_ls$Year$Worker$WkrId[WriteStartIdx:WriteEndIdx] <- Worker_ls$WkrId
    Out_ls$Year$Worker$Bzone[WriteStartIdx:WriteEndIdx] <- Worker_ls$Bzone
    Out_ls$Year$Worker$Azone[WriteStartIdx:WriteEndIdx] <- Worker_ls$Azone
    Out_ls$Year$Worker$Marea[WriteStartIdx:WriteEndIdx] <- Worker_ls$Marea
    WriteStartIdx <- WriteEndIdx + 1
  }

  #Return list of results
  #----------------------
  #Add the dataset length attributes
  attributes(Out_ls$Year$Worker$HhId)$SIZE <- max(nchar(Out_ls$Year$Worker$HhId))
  attributes(Out_ls$Year$Worker$WkrId)$SIZE <- max(nchar(Out_ls$Year$Worker$WkrId))
  attributes(Out_ls$Year$Worker$Bzone)$SIZE <- max(nchar(Out_ls$Year$Worker$Bzone))
  attributes(Out_ls$Year$Worker$Azone)$SIZE <- max(nchar(Out_ls$Year$Worker$Azone))
  attributes(Out_ls$Year$Worker$Marea)$SIZE <- max(nchar(Out_ls$Year$Worker$Marea))
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("SimulateEmployment")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
#setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "SimulateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   TestGeoName = "Portland"
# )
# L <- TestDat_$L
# R <- SimulateEmployment(L)

# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "SimulateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
