#==========================
#AssignCarSvcAvailability.R
#==========================
#
#<doc>
#
## AssignCarSvcAvailability Module
#### February 7, 2019
#
#This module assigns car service availability levels (Low, High) to Bzones and households. Car services include taxis, car sharing services (e.g. Car-To-Go, Zipcar), and future automated taxi services. A high car service level is one that has access times that are competitive with private car use, where access time is the time to get to the vehicle (or to wait for the vehicle to arrive) and the time to get from the vehicle to the destination (including the time to park the vehicle). High level of car service is considered to increase household car availability similar to owning a car. Where a high level of car service is available a household may use the car service rather than own a vehicle if the cost of using the car service is lower than the cost of owning a vehicle. Low level car service does not have competitive access time and is not considered as increasing household car availability or substituting for owning a vehicle.
#
### Model Parameter Estimation
#
#This module has no model parameters.
#
### How the Module Works
#
#The user specifies the proportion of activity (employment and households) served with a high level of car service by marea and area type. The module assigns high level car service to Bzones in each Marea and area type in the following steps:
#
#1. The proportion of total activity in each of the Bzones is calculated
#
#2. The Bzones are ordered in descending order of activity density assuming that higher density zones are more likely to have high service than lower density zones.
#
#3. The cumulative sum of activity proportion is calculated in the order determined in #2.
#
#4. The threshold where the cumulative sum is closest to the user defined proportion of activity served is identified.
#
#5. The Bzones in the order up to the threshold are identified.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no model parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#' @import visioneval

#Define the data specifications
#------------------------------
AssignCarSvcAvailabilitySpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = items(
        "CenterPropHighCarSvc",
        "InnerPropHighCarSvc",
        "OuterPropHighCarSvc",
        "FringePropHighCarSvc"),
      FILE = "marea_carsvc_availability.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of activity in center area type that is served by high level car service (i.e. service competitive with household owned car)",
        "Proportion of activity in inner area type that is served by high level car service (i.e. service competitive with household owned car)",
        "Proportion of activity in outer area type that is served by high level car service (i.e. service competitive with household owned car)",
        "Proportion of activity in fringe area type that is served by high level car service (i.e. service competitive with household owned car)"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "CenterPropHighCarSvc",
        "InnerPropHighCarSvc",
        "OuterPropHighCarSvc",
        "FringePropHighCarSvc"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Bzone",
        "Marea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "D1D",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HHJOB/ACRE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("center", "inner", "outer", "fringe")
    ),
    item(
      NAME = "Bzone",
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
        NAME = "CarSvcLevel",
        TABLE = "Bzone",
        GROUP = "Year",
        TYPE = "character",
        UNITS = "category",
        NAVALUE = "NA",
        SIZE = 4,
        PROHIBIT = "",
        ISELEMENTOF = c("Low", "High"),
        DESCRIPTION = "Level of car service availability. High means access is competitive with household owned car. Low is not competitive."
      ),
    item(
      NAME = "CarSvcLevel",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      SIZE = 4,
      PROHIBIT = "",
      ISELEMENTOF = c("Low", "High"),
      DESCRIPTION = "Level of car service availability. High means access is competitive with household owned car. Low is not competitive."
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignCarSvcAvailability module
#'
#' A list containing specifications for the AssignCarSvcCharacteristics module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignCarSvcAvailability.R script.
"AssignCarSvcAvailabilitySpecifications"
usethis::use_data(AssignCarSvcAvailabilitySpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns the car service level available in the Bzone of each
#household to the household.

#Main module function that assigns car service level to each household
#---------------------------------------------------------------------
#' Main module function to assign car service level to each household.
#'
#' \code{AssignCarSvcAvailability} assigns the car service level to each
#' household based on the Bzone where the household is located.
#'
#' This function assigns the car service level to each household based on the
#' Bzone where the household is located.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignCarSvcAvailability
#' @import visioneval stats
#' @export
AssignCarSvcAvailability <- function(L) {
  #Set up
  #------
  #Set random seed
  set.seed(L$G$Seed)
  #Identify naming vectors
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Make matrix of proportion high level car service by Marea and area type
  PropHiSvc_MaAt <- cbind(
    center = L$Year$Marea$CenterPropHighCarSvc,
    inner = L$Year$Marea$InnerPropHighCarSvc,
    outer = L$Year$Marea$OuterPropHighCarSvc,
    fringe = L$Year$Marea$FringePropHighCarSvc
  )
  rownames(PropHiSvc_MaAt) <- L$Year$Marea$Marea
  #Initialize high car service Bzone vector
  CarSvcLevel_Bz <- setNames(rep("Low", length(Bz)), Bz)

  #Iterate through Mareas and identify car service level by SimBzone
  #-----------------------------------------------------------------
  for (ma in Ma) {
    BzInMa <- L$Year$Bzone$Marea == ma
    Bx <- Bz[BzInMa]
    #Make a data frame of Bzone data to use and split by area type
    Fields_ <- c("Bzone", "NumHh", "TotEmp", "D1D", "AreaType")
    Bx_df <- data.frame(
      lapply(L$Year$Bzone[Fields_], function(x) x[BzInMa]),
      stringsAsFactors = FALSE
    )
    Bx_At_df <- split(Bx_df, Bx_df$AreaType)
    #Define function to return names of Bzones with high level car service
    getHiLvlBzones <- function(D_df, PropAct) {
      if (PropAct > 0) {
        D_df$PropTotAct <- (D_df$NumHh + D_df$TotEmp) / sum(D_df$NumHh + D_df$TotEmp)
        D1DOrder_ <- rev(order(D_df$D1D))
        CumSumOrder_ <- cumsum(D_df$PropTotAct[D1DOrder_])
        TargetDiff_ <- abs(CumSumOrder_ - PropAct)
        Cutoff <- which(TargetDiff_ == min(TargetDiff_))
        unname(D_df$Bzone[D1DOrder_[1:Cutoff]])
      } else {
        character(0)
      }
    }
    #Iterate through area types and determine high service zones
    Ax <- names(Bx_At_df)
    HiBzones_ <- do.call(c, sapply(Ax, function(x) {
      getHiLvlBzones(Bx_At_df[[x]], PropHiSvc_MaAt[ma,x])
    }))
    CarSvcLevel_Bz[HiBzones_] <- "High"
    rm(BzInMa, Bx, Fields_, Bx_df, Bx_At_df, Ax, HiBzones_)
  }

  #Return list of results
  #----------------------
  #Initialize output vectors
  Out_ls <- initDataList()
  #Assign car service levels
  Out_ls$Year$Bzone$CarSvcLevel <- CarSvcLevel_Bz
  Out_ls$Year$Household$CarSvcLevel <-
    CarSvcLevel_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  #Return result
  Out_ls
}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignCarSvcAvailability")

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
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "AssignCarSvcAvailability",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignCarSvcAvailability(L)

# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "AssignCarSvcAvailability",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
