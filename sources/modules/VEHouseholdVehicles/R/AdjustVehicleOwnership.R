#========================
#AdjustVehicleOwnership.R
#========================
#
#<doc>
#
## AdjustVehicleOwnership Module
#### November 23, 2018
#
#This module adjusts household vehicle ownership based on a comparison of the cost of owning a vehicle per mile of travel compared to the cost per mile of using a car service where the level of service is high. The determination of whether car services are substituted for ownership also depends on input assumptions regarding the average likelihood that an owner would substitute car services for a household vehicle.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#The module loads car service cost and substitution probability datasets that are inputs to the CreateVehicleTable module, car service service levels that are inputs from the AssignCarSvcAvailability module, and household vehicle ownership cost data that are outputs of the CalculateVehicleOwnCost module. The module compares the vehicle ownership cost per mile of travel for all vehicles of households living in zones where there is a high level of car service with the cost per mile of using a car service. The module flags all all vehicles where car service is high and the car service use cost is lower than the ownership cost. For those flagged vehicles, the module randomly changes their status from ownership to car service where the probability of change is the substitution probability. For example, if the user believes that only a quarter of light truck owners would substitute car services for owning a light truck (because car services wouldn't enable them to use their light truck as they intend, such as towing a trailer), then the substitution probability would be 0.25. For vehicles where it is determined that car services will substitute for a household vehicle, then the vehicle status is changed from 'Own' to 'HighCarSvc' and the ownership and insurance costs are changed as well. The household's vehicle totals are changed as well.
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
#This module has no estimated model parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AdjustVehicleOwnershipSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items(
          "HighCarSvcCost",
          "LowCarSvcCost"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AveCarSvcVehicleAge",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "LtTrkCarSvcSubProp",
          "AutoCarSvcSubProp"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
        "Vehicles",
        "NumLtTrk",
        "NumAuto"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "CarSvcLevel",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Low", "High")
    ),
    item(
      NAME = "HhId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc")
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk")
    ),
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "OwnCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "OwnCostPerMile",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "InsCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Vehicle age in years"
    ),
    item(
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc"),
      SIZE = 10,
      DESCRIPTION = "Identifier whether vehicle is owned by household (Own), if vehicle is low level car service (LowCarSvc), or if vehicle is high level car service (HighCarSvc)"
    ),
    item(
      NAME = "OwnCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual cost of vehicle ownership including depreciation, financing, insurance, taxes, and residential parking in dollars"
    ),
    item(
      NAME = "OwnCostPerMile",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual cost of vehicle ownership per mile of vehicle travel (dollars per mile)"
    ),
    item(
      NAME = "InsCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual vehicle insurance cost in dollars"
    ),
    item(
      NAME = "SwitchToCarSvc",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Identifies whether a vehicle was switched from owned to car service"
    ),
    item(
      NAME = "OwnCostSavings",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual vehicle ownership cost (depreciation, finance, insurance, taxes) savings in dollars resulting from substituting the use of car services for a household vehicle"
    ),
    item(
      NAME = "OwnCost",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual household vehicle ownership cost (depreciation, finance, insurance, taxes) savings in dollars"
    ),
    item(
      NAME = items(
        "Vehicles",
        "NumLtTrk",
        "NumAuto",
        "NumHighCarSvc"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Number of automobiles and light trucks owned or leased by the household including high level car service vehicles available to driving-age persons",
        "Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household",
        "Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household",
        "Number of high level service car service vehicles available to the household (difference between number of vehicles owned by the household and number of driving age persons for households having availability of high level car services"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AdjustVehicleOwnership module
#'
#' A list containing specifications for the AdjustVehicleOwnership module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AdjustVehicleOwnership.R script.
"AdjustVehicleOwnershipSpecifications"
usethis::use_data(AdjustVehicleOwnershipSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module adjusts household vehicle ownership based on a comparison of the
#cost of owning a vehicle per mile of travel compared to the cost per mile of
#using a car service where the level of service is high. The determination of
#whether car services are substituted for ownership also depends on input
#assumptions regarding the average likelihood that an owner would substitute
#car services for a household vehicle. The user inputs the likelihood by vehicle
#type. For example, if the user believes that a quarter of light truck owners
#would not substitute car services for owning a light truck because of how they
#use their light truck (e.g. pulling a recreational trailer, rough road travel,
#etc.), then the substitition probability would be 0.75. When it is determined
#that car services will substitute for a household vehicle, then the vehicle
#status is changed from 'Own' to 'HighCarSvc' and the ownership and insurance
#costs are changed as well. The household's vehicle totals are changed as well.

#Main module function to adjust household vehicle ownership
#----------------------------------------------------------
#' Adjust household vehicle ownership when car service cost is less.
#'
#' \code{AdjustVehicleOwnership} adjusts household vehicle ownership by
#' substituting use of car service when the level of car service is high and
#' when cost per mile to use car service is less than the cost per mile to
#' own vehicle
#'
#' This function calculates the ownership cost per mile for household vehicles
#' and compares with the cost per mile to use car service vehicles if the level
#' of car service is high. If ownership is more costly for a vehicle,
#' substitution is determined by random draw using the car service substitution
#' probability for the vehicle type. If a substitution is made, the vehicle
#' access status is changed from 'Own' to 'HighCarSvc'. The ownership cost is
#' changed to 0 as is the insurance cost. The household vehicle inventory is
#' also updated.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AdjustVehicleOwnership
#' @import visioneval
#' @export
#'
AdjustVehicleOwnership <- function(L) {
  #Set the seed for random draws
  set.seed(L$G$Seed)

  #Identify the vehicles that will be changed from owned to car service
  #--------------------------------------------------------------------
  #Identify the car service level corresponding to each vehicle
  NumVeh <- length(L$Year$Vehicle$VehId)
  CarSvcLvl_Ve <-
    L$Year$Household$CarSvcLevel[match(L$Year$Vehicle$HhId, L$Year$Household$HhId)]
  #Identify candidates for swapping owned vehicle for car services
  IsOwnedVeh <- L$Year$Vehicle$VehicleAccess == "Own"
  IsHighCS <- CarSvcLvl_Ve == "High"
  CSIsLess <- L$Year$Azone$HighCarSvcCost < L$Year$Vehicle$OwnCostPerMile
  IsCandidate <- IsOwnedVeh & IsHighCS & CSIsLess
  #Get the change probabilities
  CandidateTypes_ <- L$Year$Vehicle$Type[IsCandidate]
  ChangeProb_<- c(
    Auto = L$Year$Azone$AutoCarSvcSubProp,
    LtTrk = L$Year$Azone$LtTrkCarSvcSubProp
    )[CandidateTypes_]
  #Make vector to identify vehicles to change
  DoChange <- logical(NumVeh)
  DoChange[IsCandidate] <- runif(length(ChangeProb_)) < ChangeProb_

  #Modify vehicle values to reflect change to change in ownership
  #--------------------------------------------------------------
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <-
    L$Year$Vehicle[c("Age", "VehicleAccess", "OwnCost", "OwnCostPerMile", "InsCost")]
  Out_ls$Year$Vehicle$Age[DoChange] <- L$Year$Azone$AveCarSvcVehicleAge
  Out_ls$Year$Vehicle$VehicleAccess[DoChange] <- "HighCarSvc"
  Out_ls$Year$Vehicle$OwnCost[DoChange] <- 0
  Out_ls$Year$Vehicle$OwnCostPerMile[DoChange] <- 0
  Out_ls$Year$Vehicle$SwitchToCarSvc <- as.integer(DoChange)

  #Tabulate household values to reflect changes
  #--------------------------------------------
  Out_ls$Year$Household <- list()
  VehCat_Ve <- L$Year$Vehicle$Type
  VehCat_Ve[Out_ls$Year$Vehicle$VehicleAccess == "HighCarSvc"] <- "HighCarSvc"
  VehCat_Ve[Out_ls$Year$Vehicle$VehicleAccess == "LowCarSvc"] <- "LowCarSvc"
  Out_ls$Year$Household$NumAuto <-
    tapply(VehCat_Ve == "Auto", L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  Out_ls$Year$Household$NumLtTrk <-
    tapply(VehCat_Ve == "LtTrk", L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  Out_ls$Year$Household$NumHighCarSvc <-
    tapply(VehCat_Ve == "HighCarSvc", L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  Out_ls$Year$Household$Vehicles <-
    with(Out_ls$Year$Household, NumAuto + NumLtTrk + NumHighCarSvc)
  Out_ls$Year$Household$OwnCost <-
    tapply(Out_ls$Year$Vehicle$OwnCost, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  Out_ls$Year$Household$OwnCostSavings <-
    tapply(L$Year$Vehicle$OwnCost * DoChange, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]

  #Return the outputs list
  #-----------------------
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AdjustVehicleOwnership")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AdjustVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AdjustVehicleOwnership(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AdjustVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
