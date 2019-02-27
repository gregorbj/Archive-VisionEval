#===================
#SimulateRoadMiles.R
#===================

#<doc>
#
## SimulateRoadMiles Module
#### February 11, 2019
#
#This module assigns freeway and arterial lane-miles to metropolitan areas (Marea) and calculates freeway lane-miles per capita.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#Users provide inputs on the numbers of freeway lane-miles and arterial lane-miles by Marea and year. In addition to saving these inputs, the module loads the urbanized area population of each Marea and year from the datastore and computes the value of freeway lane-miles per capita. This relative roadway supply measure is used by several other modules.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. Households are assigned to Bzones based on an
#algorithm implemented in the LocateHouseholds function.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
SimulateRoadMilesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      FILE = "marea_lane_miles.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Lane-miles of roadways functionally classified as freeways or expressways in the urbanized portion of the metropolitan area",
          "Lane-miles of roadways functionally classified as arterials (but not freeways or expressways) in the urbanized portion of the metropolitan area")
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
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "FwyLaneMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of urbanized area freeway and expressway lane-miles to urbanized area population"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for SimulateRoadMiles module
#'
#' A list containing specifications for the SimulateRoadMiles module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source SimulateRoadMiles.R script.
"SimulateRoadMilesSpecifications"
usethis::use_data(SimulateRoadMilesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the freeway lane-miles per capita for the urbanized
#area from the number of freeway lane-miles and the urban area population.

#Main module function that calculates freeway lane-miles per capita
#------------------------------------------------------------------
#' Calculate freeway lane-miles per capita by Marea.
#'
#' \code{SimulateRoadMiles} calculate freeway lane-miles per capita.
#'
#' This function calculates freeway lane-miles per capita for each Marea.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name SimulateRoadMiles
#' @import visioneval
#' @export
SimulateRoadMiles <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea

  #Calculate the freeway lane-miles per capita
  #-------------------------------------------
  #Calculate freeway lane-miles
  FwyLaneMi_Ma <- L$Year$Marea$FwyLaneMi
  #Calculate population in the urbanized area
  UrbanPop_Ma <-
    tapply(L$Year$Bzone$UrbanPop, L$Year$Bzone$Marea, sum)[Ma]
  #Calculate freeway lane-miles per capita
  FwyLaneMiPC_Ma <- FwyLaneMi_Ma / UrbanPop_Ma
  FwyLaneMiPC_Ma[UrbanPop_Ma == 0] <- 0

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(FwyLaneMiPC = FwyLaneMiPC_Ma)
  #Return the outputs list
  Out_ls
}



#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("SimulateRoadMiles")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# library(filesstrings)
# library(visioneval)
# library(fields)
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
#   ModuleName = "SimulateoadMiles",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- SimulateRoadMiles(L)
