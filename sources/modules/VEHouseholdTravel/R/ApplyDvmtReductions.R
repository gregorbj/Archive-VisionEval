#=====================
#ApplyDvmtReductions.R
#=====================
#
#<doc>
#
## ApplyDvmtReductions Module
#### November 21, 2018
#
#This module applies the computed proportional reductions in household DVMT due to the application of travel demand management programs and the diversion of single-occupant vehicle travel to bicycles, electric bicycles, or other light-weight vehicles. It also computes added bike trips due to the diversion.
#
### Model Parameter Estimation
#
#This module has no estimated model parameters.
#
### How the Module Works
#
#The module loads from the datastore the proportional reductions in household DVMT calculated by the AssignDemandManagement module and DivertSovTravel module. It converts the proportional reductions to proportions of DVMT (i.e. 1 - proportional reduction), multiplies them, and multiplies by household DVMT to arrive at a revised household DVMT which is saved to the datastore. It computes the added 'bike' trips that would occur due to the diversion by calculating the diverted SOV travel and dividing by the average SOV trip length.
#
#</doc>


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
      NAME = "AveTrpLenDiverted",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
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
    ),
    item(
      NAME = "SovToBikeTrip",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual extra trips allocated to bicycle model as a result of SOV diversion"
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

  #Calculate extra bike trip adjustment
  #------------------------------------
  #Daily miles diverted
  SovMilesDivert_Hh <- L$Year$Household$PropDvmtDiverted * L$Year$Household$Dvmt
  #Yearly trips diverted
  SovToBikeTrip_Hh <- 365 * SovMilesDivert_Hh / L$Year$Household$AveTrpLenDiverted

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(Dvmt = AdjDvmt_Hh,
         SovToBikeTrip = SovToBikeTrip_Hh)
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("ApplyDvmtReductions")

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

