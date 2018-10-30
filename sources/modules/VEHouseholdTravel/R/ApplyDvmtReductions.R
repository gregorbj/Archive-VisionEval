#=======================
#ApplyDvmtReductions.R
#=======================
#This module applies the computed proportional reductions in household DVMT due
#to the application of travel demand management programs and the diversion of
#single-occupant vehicle travel to bicycles, electric bicycles, or other
#light-weight vehicles. The AssignDemandManagement module assigns travel demand
#management programs to workers and households (based on user inputs regarding
#assumed participation rates) and calculates the proportional reduction in
#household DVMT from the programs. The DivertSovTravel module models the amount
#of SOV travel of households and diverts some of that travel to light-weight
#vehicle travel (bikes, electric bikes, etc.) based on user input goals for
#diversion, the amount of household SOV travel and the propensity of the
#household to use other modes. It calculates proportion of each household travel
#that is diverted. The ApplyTravelReductions module gets the DVMT diversions
#that these modules calculated and placed in the datastore and adjusts the
#household DVMT accordingly, saving the adjusted household DVMT.


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
ApplyDvmtReductionsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PropDvmtDiverted",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PropTdmDvmtReduction",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by the household in autos or light trucks"
    )
  ),
  #Specify call status of module
  Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for the ApplyDvmtReductions module.
#'
#' A list containing specifications for the ApplyDvmtReductions module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source ApplyDvmtReductions.R script.
"ApplyDvmtReductionsSpecifications"
usethis::use_data(ApplyDvmtReductionsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates

#Main module function that applies DVMT reductions to household DVMT
#-------------------------------------------------------------------
#' Apply DVMT reductions to household DVMT.
#'
#' \code{ApplyDvmtReductions} applies the DVMT reductions calculated for travel
#' demand management and single-occupant vehicle (SOV) travel diversion to
#' adjust household travel.
#'
#' This function takes the proportional reductions in household DVMT calculated
#' by the AssignDemandManagement module and the DivertSOV travel module and
#' applies them to adjust the household DVMT to account for the reductions.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name ApplyDvmtReductions
#' @import visioneval
#' @export
ApplyDvmtReductions <- function(L) {

  #Calculate adjusted DVMT
  #-----------------------
  #Adjustment due to travel demand management programs
  TdmAdj_Hh <- 1 - L$Year$Household$PropTdmDvmtReduction
  #Adjustment due to diversion of SOV travel to light-weight vehicles
  SovDivertAdj_Hh <- 1 - L$Year$Household$PropDvmtDiverted
  #Adjusted household DVMT
  AdjDvmt_Hh <- L$Year$Household$Dvmt * TdmAdj_Hh * SovDivertAdj_Hh

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(Dvmt = AdjDvmt_Hh)
  #Return the outputs list
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
#   ModuleName = "ApplyDvmtReductions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- ApplyDvmtReductions(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "ApplyDvmtReductions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

