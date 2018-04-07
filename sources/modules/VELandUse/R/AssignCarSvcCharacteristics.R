#=============================
#AssignCarSvcCharacteristics.R
#=============================
#This module reads in and assigns car service characteristics to Bzones. Car
#services include taxis (with human drivers or under automated control) and car
#sharing services (e.g. Car-To-Go, Zipcar), and future automated taxi services.
#A user input file identifies which Bzones have high or low levels of service. A
#high car service level is one that has access times that are competitive with
#private car use. This means that the time it takes for a taxi service to pick
#up a passenger or that time it takes to get to a car share car is not much
#longer than the time to get to and from a vehicle owned by a household. High
#level of car service is considered to increase household car availability and
#affects the amount of household DVMT. Low level car service does not have
#competitive access time and is not considered as increasing household car
#availability. Low level car service characteristics determine what a household
#living in an area with low level service will pay for their vehicle travel.
#User inputs also determine car service characteristics at the Azone level. The
#average access time and the average cost per mile at the two service levels.
#These values are used to calculate the cost of using car services to determine
#what households might choose to use a car service instead of owning one or more
#vehicles, and to determine the relative utility of car services compared to
#owned cars to determine how car service availability affects household DVMT.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no model parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignCarSvcCharacteristicsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "CarSvcLevel",
      FILE = "bzone_carsvc_availability.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      SIZE = 4,
      PROHIBIT = "",
      ISELEMENTOF = c("Low", "High"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Level of car service availability. High means access is competitive with household owned car. Low is not competitive."
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "CarSvcLevel",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      SIZE = 4,
      PROHIBIT = "",
      ISELEMENTOF = c("Low", "High")
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
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
#' Specifications list for AssignCarSvcCharacteristics module
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
#' @source AssignCarSvcCharacteristics.R script.
"AssignCarSvcCharacteristicsSpecifications"
devtools::use_data(AssignCarSvcCharacteristicsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns the car service level available in the Bzone of each
#household to the household.

#Main module function that assigns car service level to each household
#---------------------------------------------------------------------
#' Main module function to assign car service level to each household.
#'
#' \code{AssignCarSvcCharacteristics} assigns the car service level to each
#' household based on the Bzone where the household is located.
#'
#' This function assigns the car service level to each household based on the
#' Bzone where the household is located.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval stats
#' @export
AssignCarSvcCharacteristics <- function(L) {

  #Assign car service level to each household
  #------------------------------------------
  #Match index vector of Bzone to Households
  BzToHh_ <- match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)
  #Assign car service level to households
  CarSvcLevel_Hh <- L$Year$Bzone$CarSvcLevel[BzToHh_]

  #Return list of results
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    CarSvcLevel = CarSvcLevel_Hh
  )
  Out_ls
}

#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignCarSvcCharacteristics",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignCarSvcCharacteristics(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignCarSvcCharacteristics",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

