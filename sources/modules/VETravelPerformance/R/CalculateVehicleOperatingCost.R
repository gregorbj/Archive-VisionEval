#==================================
#CalculateHhVehicleOperatingCosts.R
#==================================
#This module calculates vehicle operating costs per mile of travel and uses
#those costs to determine the proportional split of DVMT among household
#vehicles. The module also calculates the average out-of-pocket costs per mile
#of vehicle by household, as well as the cost of social and environmental
#impacts, and road use taxes per mile of vehicle travel.
#
#Household DVMT is split among household vehicles as a function of the composite
#cost per mile of using each vehicle available to the household (includes car
#service vehicles as well as owned vehicles). Composite costs include both
#out-of-pocket costs as well as the value of travel time.
#
#The value of travel time per mile is calculated as the sum of the average
#travel rate and the average vehicle access time per mile multiplied by the
#value of time specified for the model. The average travel rate is the same for
#owned and car service vehicles as is calculated by the CalculateRoadPerformance
#module. The average vehicle access rate is calculated from the average access
#time per trip, a user input that varies by vehicle access type (Own, LowCarSvc,
#HighCarSvc), and the ratio to household trips to household DVMT.
#
#Out-of-pocket costs include elements that are shared by owned vehicles and car
#service vehicles and costs that different. Shared costs include the cost of
#fuel and electricity to power the vehicles, the cost of road use taxes (fuel,
#VMT, congestion), climate cost (i.e. carbon taxes), and any other social costs
#that are passed to the car user (user input specifies the portions of climate
#costs and social costs that are passed to users). Road use taxes include
#plug-in vehicle surcharge tax to achieve parity with fuel taxes based on user
#input. Owned vehicles have several added out-of-pocket costs including the cost
#of vehicle maintenance/repair/tires, parking, and pay-as-you-drive insurance.
#Car service vehicles have the charge per mile to use the car service (a user
#input).
#
#The module calculates the weighted average out-of-pocket cost per mile of
#vehicle travel from the out-of-pocket cost by vehicle and the DVMT proportion
#by vehicle. The module likewise computes the average cost impact of climate and
#other social costs (paid and unpaid) per mile of the household's travel, and
#the road use taxes paid per mile of household travel.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#------------------------------------------------------------
#Establish deflators to convert all money values to same year
#------------------------------------------------------------
#Load table of deflators
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = c("2007", "2010", "2012", "2017"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "Value",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process climate change cost data
#Cost data are in year 2010 dollars
Deflators_df <-
  processEstimationInputs(
    Inp_ls,
    "deflators.csv",
    "CalculateVehicleOperatingCost.R")
Deflators_Yr <- Deflators_df$Value
names(Deflators_Yr) <- Deflators_df$Year
rm(Inp_ls, Deflators_df)


#-----------------------------------------------
#Vehicle maintenance, repair and tire cost model
#-----------------------------------------------
#Vehicle operating cost data from the American Automobile Association (AAA) and
#from the Bureau of Labor Statistics (BLS) are used to estimate a model of
#vehicle maintenance, repair, and tire cost by vehicle type and age.

#AAA vehicle maintenance, repair, and tire cost data
#---------------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "VehicleType",
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = c(
      "SmallSedan",
      "MediumSedan",
      "LargeSedan",
      "SmallSUV",
      "MediumSUV",
      "Minivan",
      "PickupTruck",
      "HybridCar",
      "ElectricCar"
    ),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "CentsPerMile",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process AAA vehicle maintenance, repair, and tire cost data
#Cost data are for the year 2017
AAAOpCost_df <-
  processEstimationInputs(
    Inp_ls,
    "aaa_vehicle_operating_costs.csv",
    "CalculateVehicleOperatingCost.R")
AAAOpCost_ <- c(
  AutoIcev = mean(AAAOpCost_df$CentsPerMile[AAAOpCost_df$VehicleType %in% c("SmallSedan", "MediumSedan", "LargeSedan")]),
  LtTrkIcev = mean(AAAOpCost_df$CentsPerMile[AAAOpCost_df$VehicleType %in% c("SmallSUV", "MediumSUV", "Minivan", "PickupTruck")]),
  Hev = AAAOpCost_df$CentsPerMile[AAAOpCost_df$VehicleType == "HybridCar"],
  Bev = AAAOpCost_df$CentsPerMile[AAAOpCost_df$VehicleType == "ElectricCar"]
)
#Convert from cents per mile to dollars per mile
AAAOpCost_ <- AAAOpCost_ / 100
rm(Inp_ls, AAAOpCost_df)

#BLS vehicle maintenance, repair, and tire cost data
#---------------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "VehicleAge",
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = c(
      "Age0to5",
      "Age6to10",
      "Age11to15",
      "Age16to20",
      "Age21to25",
      "Age26Plus",
      "Average"
    ),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "DollarsPerYear",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process BLS vehicle maintenance, repair, and tire cost data
#Cost data are for the year 2012
BLSOpCost_df <-
  processEstimationInputs(
    Inp_ls,
    "bls_vehicle_operating_costs.csv",
    "CalculateVehicleOperatingCost.R")
BLSOpCost_ <- BLSOpCost_df$DollarsPerYear
names(BLSOpCost_) <- BLSOpCost_df$VehicleAge
#Normalize values by average age
BLSOpCost_ <- (BLSOpCost_ / BLSOpCost_["Average"])[-which(names(BLSOpCost_) == "Average")]
rm(Inp_ls, BLSOpCost_df)

#Model maintenance, repair and tires as a function of vehicle age and type
#-------------------------------------------------------------------------
#Create table of annual cost by age and vehicle type ($2012)
VehCost_AgTy <- outer(BLSOpCost_, AAAOpCost_)
#Convert to 2010 dollar values
VehCost_AgTy <- VehCost_AgTy * Deflators_Yr["2010"] / Deflators_Yr["2017"]

#------------------------------------------------
#Externality cost (i.e. social costs) assumptions
#------------------------------------------------

#Climate change costs
#--------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = "NA",
    ISELEMENTOF = c(
      "2010", "2015", "2020", "2025", "2030",
      "2035", "2040", "2045", "2050"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "DiscRate5Pct",
      "DiscRate3Pct",
      "DiscRate2.5Pct",
      "HighImpact"),
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process climate change cost data
#Cost data are in year 2007 dollars
CO2eCost_df <-
  processEstimationInputs(
    Inp_ls,
    "co2e_costs.csv",
    "CalculateVehicleOperatingCost.R")
CO2eCost_ <- CO2eCost_df$DiscRate3Pct
names(CO2eCost_) <- CO2eCost_df$Year
rm(Inp_ls, CO2eCost_df)

#Convert to 2010 dollar values
CO2eCost_ <- CO2eCost_ * Deflators_Yr["2010"] / Deflators_Yr["2007"]

#Other externality costs
#-----------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "CostCategory",
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = c(
      "AirPollution", "OtherResource", "EnergySecurity", "Safety", "Noise"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "UnitCost",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process other externality cost data
#Cost data are in year 2010 dollars
OtherExtCost_df <-
  processEstimationInputs(
    Inp_ls,
    "ldv_externality_costs.csv",
    "CalculateVehicleOperatingCost.R")
OtherExtCost_ <- OtherExtCost_df$UnitCost
names(OtherExtCost_) <- OtherExtCost_df$CostCategory
rm(Inp_ls, OtherExtCost_df)

#---------------------------------
#Save the default cost assumptions
#---------------------------------
#Combine values into a list
OpCosts_ls <- list(
  VehCost_AgTy = VehCost_AgTy,
  CO2eCost_ = CO2eCost_,
  OtherExtCost_ = OtherExtCost_
)

#' Vehicle operations costs
#'
#' A list containing vehicle operations cost items for maintenance, repair,
#' tires, greenhouse gas emissions costs, and other social costs.
#'
#' @format A list containing the following three components:
#' \describe{
#'   \item{VehCost_AgTy}{a matrix of annual vehicle maintenance, repair and tire costs by vehicle type and age category in 2010 dollars}
#'   \item{CO2eCost_}{a vector of greenhouse gas emissions costs by forecast year in 2010 dollars per metric ton of carbon dioxide equivalents}
#'   \item{OtherExtCost_}{a vector of other social costs by cost category. Values are in 2010 dollars per vehicle mile except for EnergySecurity which is in 2010 dollars per gasoline equivalent gallon}
#' }
#' @source CalculateVehicleOperatingCost.R script.
"OpCosts_ls"
usethis::use_data(OpCosts_ls, overwrite = TRUE)
rm(VehCost_AgTy, AAAOpCost_, BLSOpCost_, CO2eCost_, Deflators_Yr, OtherExtCost_)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateVehicleOperatingCostSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  Inp = items(
    item(
      NAME =
        items(
          "OwnedVehAccessTime",
          "HighCarSvcAccessTime",
          "LowCarSvcAccessTime"),
      FILE = "azone_vehicle_access_times.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "MIN",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average amount of time in minutes required for access to and egress from a household-owned vehicle for a trip",
          "Average amount of time in minutes required for access to and egress from a high service level car service for a trip",
          "Average amount of time in minutes required for access to and egress from a low service level car service for a trip"
        )
    ),
    item(
      NAME = items(
        "FuelCost",
        "PowerCost"),
      FILE = "azone_fuel_power_cost.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Retail cost of fuel per gas gallon equivalent in dollars",
        "Retail cost of electric power per kilowatt-hour in dollars"
      )
    ),
    item(
      NAME = items(
        "FuelTax",
        "VmtTax"),
      FILE = "azone_veh_use_taxes.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Tax per gas gallon equivalent of fuel in dollars",
        "Tax per mile of vehicle travel in dollars"
      )
    ),
    item(
      NAME = "PevSurchgTaxProp",
      FILE = "azone_veh_use_taxes.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Proportion of equivalent gas tax per mile paid by hydrocarbon fuel consuming vehicles to be charged to plug-in electric vehicles per mile of travel powered by electricity"
    ),
    item(
      NAME = items(
        "PropClimateCostPaid",
        "PropOtherExtCostPaid"),
      FILE = "region_prop_externalities_paid.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of climate change costs paid by users (i.e. ratio of carbon taxes to climate change costs)",
        "Proportion of other social costs paid by users")
    )
  ),
  #Specify new tables to be created by Set if any
  #Specify input data
  Get = items(
    item(
      NAME = "ValueOfTime",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "PropClimateCostPaid",
        "PropOtherExtCostPaid"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
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
      NAME = "AveLdvSpd",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AveCongPrice",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "OwnedVehAccessTime",
          "HighCarSvcAccessTime",
          "LowCarSvcAccessTime"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "MIN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FuelCost",
        "PowerCost"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FuelTax",
        "VmtTax"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PevSurchgTaxProp",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "HighCarSvcCost",
          "LowCarSvcCost"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
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
      NAME = "HasPaydIns",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1)
    ),
    item(
      NAME = "VehicleTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "OtherParkingCost",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Marea",
        "HhId",
        "VehId"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
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
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc")
    ),
    item(
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("ICEV", "HEV", "PHEV", "BEV", "NA")
    ),
    item(
      NAME = "GPM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GGE/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "KWHPM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ElecDvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "FuelCO2ePM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ElecCO2ePM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "InsCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ParkingCost",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "IsCashOut",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1)
    ),
    item(
      NAME = "PaysForParking",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1)
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "AveVehCostPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average out-of-pocket cost in dollars per mile of vehicle travel"
    ),
    item(
      NAME = "AveSocEnvCostPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average cost in dollars of the social and environmental impacts per mile of vehicle travel"
    ),
    item(
      NAME = "AveRoadUseTaxPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average road use taxes in dollars collected per mile of vehicle travel"
    ),
    item(
      NAME = "DvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Proportion of household DVMT allocated to vehicle"
    ),
    item(
      NAME = "AveGPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GGE/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average gasoline equivalent gallons per mile of household vehicle travel"
    ),
    item(
      NAME = "AveKWHPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average kilowatt-hours per mile of household vehicle travel"
    ),
    item(
      NAME = "AveCO2ePM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average grams of carbon-dioxide equivalents produced per mile of household vehicle travel"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateVehicleOperatingCost module
#'
#' A list containing specifications for the CalculateVehicleOperatingCost module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#'  \item{Call}{list of modules called by the module}
#' }
#' @source CalculateVehicleOperatingCost.R script.
"CalculateVehicleOperatingCostSpecifications"
usethis::use_data(CalculateVehicleOperatingCostSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that calculates vehicle operating costs
#------------------------------------------------------------
#' Calculate vehicle operating costs.
#'
#' \code{CalculateVehicleOperatingCost} calculates vehicle operating costs and
#' determines how household DVMT is split between vehicles.
#'
#' This function calculates vehicle operating costs, splits household DVMT
#' between vehicles, and calculates household average vehicle operating cost,
#' social/environmental impact cost, and road use taxes per mile of household
#' vehicle travel.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'
CalculateVehicleOperatingCost <- function(L) {

  #Index to match household data with vehicle data
  HhToVehIdx_Ve <- match(L$Year$Vehicle$HhId, L$Year$Household$HhId)

  #Calculate vehicle cost components
  #---------------------------------
  #Calculate maintenance, repair, tire cost per mile (only for owned vehicles)
  MRTCostRate_Ve <- local({
    NumVeh <- length(L$Year$Vehicle$VehId)
    #Categorize by vehicle age group
    VehAgeGroup_Ve <-
      cut(L$Year$Vehicle$Age,
          breaks = c(0, 5, 10, 15, 20, 25, max(L$Year$Vehicle$Age)),
          labels = FALSE, include.lowest = TRUE)
    #Categorize vehicle type
    MRTType_Ve <- character(length(NumVeh))
    MRTType_Ve[with(L$Year$Vehicle, Powertrain == "BEV")] <- "Bev"
    MRTType_Ve[with(L$Year$Vehicle, Powertrain == "HEV")] <- "Hev"
    MRTType_Ve[with(L$Year$Vehicle, Powertrain == "PHEV")] <- "Hev"
    MRTType_Ve[with(L$Year$Vehicle, Powertrain == "ICEV" & Type == "Auto")] <- "AutoIcev"
    MRTType_Ve[with(L$Year$Vehicle, Powertrain == "ICEV" & Type == "LtTrk")] <- "LtTrkIcev"
    MRTType_Ve[with(L$Year$Vehicle, VehicleAccess != "Own")] <- NA
    MRTTypeIdx_Ve <- match(MRTType_Ve, colnames(OpCosts_ls$VehCost_AgTy))
    #Get annual maintenance, repair, tire cost
    MRTCostRate_Ve <- OpCosts_ls$VehCost_AgTy[cbind(VehAgeGroup_Ve, MRTTypeIdx_Ve)]
    MRTCostRate_Ve[is.na(MRTCostRate_Ve)] <- 0
    unname(MRTCostRate_Ve)
  })

  #Calculate energy cost rate (fuel and electric power)
  NetGPM_Ve <- L$Year$Vehicle$GPM * (1 - L$Year$Vehicle$ElecDvmtProp)
  NetKWHPM_Ve <- L$Year$Vehicle$KWHPM * L$Year$Vehicle$ElecDvmtProp
  EnergyCostRate_Ve <- local({
    FuelCostRate_Ve <- NetGPM_Ve * L$Year$Azone$FuelCost
    ElecCostRate_Ve <- NetKWHPM_Ve * L$Year$Azone$PowerCost
    unname(FuelCostRate_Ve + ElecCostRate_Ve)
  })

  #Road use taxes
  RoadUseCostRate_Ve <- local({
    FuelTax_Ve <- L$Year$Azone$FuelTax * L$Year$Vehicle$GPM
    PevChrg <- mean(FuelTax_Ve) * L$Year$Azone$PevSurchgTaxProp
    ElecProp_Ve <- L$Year$Vehicle$ElecDvmtProp
    VmtTax <- L$Year$Azone$VmtTax
    CongPrice <- L$Year$Marea$AveCongPrice
    unname(VmtTax + ElecProp_Ve * PevChrg + (1 - ElecProp_Ve) * FuelTax_Ve + CongPrice)
  })

  #Average CO2e per mile
  CO2ePM_Ve <-
    with(L$Year$Vehicle, FuelCO2ePM * (1 - ElecDvmtProp) + ElecCO2ePM * ElecDvmtProp)
  #Climate impacts cost per mile
  ClimateImpactsRate_Ve <- local({
    #Calculate CO2e cost per metric ton for year
    CO2eCost_ <- OpCosts_ls$CO2eCost_
    Years_ <- as.numeric(names(CO2eCost_))
    CO2eCost_SS <- smooth.spline(Years_, CO2eCost_)
    CO2eCost <- predict(CO2eCost_SS, as.numeric(L$G$Year))$y
    unname(CO2ePM_Ve * CO2eCost / 1e6)
  })
  #Climate costs paid
  ClimateCostRate_Ve <- ClimateImpactsRate_Ve * L$Year$Region$PropClimateCostPaid

  #Other social impacts cost per mile
  SocialImpactsRate_Ve <- local({
    #Calculate energy security cost (convert cost per gallon to cost per mile)
    ESCost <- OpCosts_ls$OtherExtCost_["EnergySecurity"]
    ESCost_Ve <-
      ESCost * L$Year$Vehicle$GPM * (1 - L$Year$Vehicle$ElecDvmtProp)
    #Calculate other social costs (is function of miles)
    OtherSocialCost <- sum(OpCosts_ls$OtherExtCost_) - ESCost
    #Sum social costs per mile
    unname(ESCost_Ve + OtherSocialCost)
  })
  #Social costs paid
  SocialCostRate_Ve <- SocialImpactsRate_Ve * L$Year$Region$PropOtherExtCostPaid

  #Parking cost
  ParkingCostRate_Ve <- local({
    #Calculate work parking cost for each household
    WrkPkgCost_Hh <-
      with(L$Year$Worker, tapply(ParkingCost * PaysForParking, HhId, sum))[L$Year$Household$HhId]
    WrkPkgCost_Hh[is.na(WrkPkgCost_Hh)] <- 0
    #Retrieve other parking cost for each household
    OthPkgCost_Hh <- L$Year$Household$OtherParkingCost
    #Scale by normalized number of vehicle trips
    OthPkgCost_Hh <-
      OthPkgCost_Hh * with(L$Year$Household, VehicleTrips / mean(VehicleTrips))
    #Sum daily parking cost and calculate cost per mile
    PkgCost_Hh <- WrkPkgCost_Hh + OthPkgCost_Hh
    PkgCostRate_Hh <- PkgCost_Hh / L$Year$Household$Dvmt
    #Assign values to owned household vehicles
    ParkingCostRate_Ve <- PkgCostRate_Hh[HhToVehIdx_Ve]
    ParkingCostRate_Ve[L$Year$Vehicle$VehicleAccess != "Own"] <- 0
    unname(ParkingCostRate_Ve)
  })

  #PAYD insurance cost
  PaydInsCostRate_Ve <- local({
    HasPaydIns_Hh <- L$Year$Household$HasPaydIns
    InsCost_Ve <- L$Year$Vehicle$InsCost
    InsCost_Hh <-
      tapply(InsCost_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
    InsCostRate_Hh <- HasPaydIns_Hh * InsCost_Hh / L$Year$Household$Dvmt / 365
    unname(InsCostRate_Hh[HhToVehIdx_Ve])
  })

  #Car service cost
  CarSvcCostRate_Ve <- local({
    VehAccType_Ve <- L$Year$Vehicle$VehicleAccess
    CarSvcCostRate_Ve <- rep(0, length(VehAccType_Ve))
    CarSvcCostRate_Ve[VehAccType_Ve == "LowCarSvc"] <- L$Year$Azone$LowCarSvcCost
    CarSvcCostRate_Ve[VehAccType_Ve == "HighCarSvc"] <- L$Year$Azone$HighCarSvcCost
    unname(CarSvcCostRate_Ve)
  })

  #Calculate value of time per mile
  TTCostRate_Ve <- local({
    #Running time rate of travel
    RunTimeRate <- 1 / L$Year$Marea$AveLdvSpd
    #Access time equivalent rate of travel
    TripsPerDvmt_Ve <- with(L$Year$Household, VehicleTrips / Dvmt)[HhToVehIdx_Ve]
    AccTimePerTrip_Ve <- c(
      Own = unname(L$Year$Azone$OwnedVehAccessTime / 60),
      HighCarSvc = unname(L$Year$Azone$HighCarSvcAccessTime / 60),
      LowCarSvc = unname(L$Year$Azone$LowCarSvcAccessTime / 60)
    )[L$Year$Vehicle$VehicleAccess]
    AccTimeRate_Ve <- TripsPerDvmt_Ve * AccTimePerTrip_Ve
    #Calculate value of time per mile
    unname((RunTimeRate + AccTimeRate_Ve) * L$Global$Model$ValueOfTime)
  })

  #Calculate the proportion of household DVMT of each vehicle
  #----------------------------------------------------------
  DvmtProp_Ve <- local({
    #Calculate composite cost (sum of out-of-pocket and travel time costs)
    CompositeCostRate_Ve <-
      MRTCostRate_Ve + EnergyCostRate_Ve + RoadUseCostRate_Ve +
      ClimateCostRate_Ve + SocialCostRate_Ve + ParkingCostRate_Ve +
      PaydInsCostRate_Ve + CarSvcCostRate_Ve + TTCostRate_Ve
    #Split costs by household in order of household listings in vehicle table
    HhSeq_ <- 1:length(L$Year$Household$HhId)
    CompositeCostRate_ls <- split(CompositeCostRate_Ve, HhSeq_[HhToVehIdx_Ve])
    #Calculate DVMT proportions
    DvmtProp_Ve <- unlist(lapply(CompositeCostRate_ls, function(x) {
      (1 / x) / sum(1 / x)
    }))
    unname(DvmtProp_Ve)
  })

  #Calculate average household costs, impacts, taxes per mile
  #----------------------------------------------------------
  #Calculate average out-of-pocket costs per mile by household
  AveVehCostPM_Hh <- local({
    VehCostPM_Ve <-
      MRTCostRate_Ve + EnergyCostRate_Ve + RoadUseCostRate_Ve +
      ClimateCostRate_Ve + SocialCostRate_Ve + ParkingCostRate_Ve +
      PaydInsCostRate_Ve + CarSvcCostRate_Ve
    tapply(VehCostPM_Ve * DvmtProp_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  })
  #Calculate average social and environmental impacts costs per mile by household
  AveSocEnvCostPM_Hh <- local({
    SocEnvCostPM_Ve <- ClimateImpactsRate_Ve + SocialImpactsRate_Ve
    tapply(SocEnvCostPM_Ve * DvmtProp_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  })
  #Calculate average road use taxes per mile
  AveRoadUseTaxPM_Hh <-
    tapply(RoadUseCostRate_Ve * DvmtProp_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  #Calculate average fuel consumption per mile
  GPM_Hh <-
    tapply(NetGPM_Ve * DvmtProp_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  #Calculate average electricity consumption per mile
  KWHPM_Hh <-
    tapply(NetKWHPM_Ve * DvmtProp_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  #Calculate average greenhouse gas emissions per mile
  AveCO2ePM_Hh <-
    tapply(CO2ePM_Ve * DvmtProp_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    AveVehCostPM = AveVehCostPM_Hh,
    AveSocEnvCostPM = AveSocEnvCostPM_Hh,
    AveRoadUseTaxPM = AveRoadUseTaxPM_Hh,
    AveGPM = GPM_Hh,
    AveKWHPM = KWHPM_Hh,
    AveCO2ePM = AveCO2ePM_Hh
  )
  Out_ls$Year$Vehicle <- list(
    DvmtProp = DvmtProp_Ve
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
#   ModuleName = "CalculateVehicleOperatingCost",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateVehicleOperatingCost(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleOperatingCost",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
