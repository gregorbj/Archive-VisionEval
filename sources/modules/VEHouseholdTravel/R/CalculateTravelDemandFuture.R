#===================
#CalculateTravelDemandFuture.R
#===================

#This module calculates average daily vehicle miles traveld for households. It also
#calculates average DVMT, daily consumption of fuel (in gallons), and average daily
#Co2 equivalent greenhouse emissions for all vehicles.


# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
## Current implementation
### The current version implements the models used in the RPAT (GreenSTEP)
### ecosystem.



## Future Development
## Use estimation data set to create models


#Load Dvmt assignment models
load("./data/DvmtLmModels_ls.rda")

#Load PHEV/HEV model data
load("./data/PhevModelData_ls.rda")

#Load default values for Travel Demand module
load("./data/TravelDemandDefaults_ls.rda")

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateTravelDemandFutureSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = "UrbanIncome",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanIncome",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "currency",
      UNITS = "USD.2000",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "HhId",
        "HhPlaceTypes"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Age0to14",
        "Age15to19",
        "Age20to29",
        "Age30to54",
        "Age55to64",
        "Age65Plus"
      ),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehiclesFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    # Vehicle variables
    item(
      NAME = items("HhIdFuture",
                   "VehIdFuture"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AgeFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "MileageFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TypeFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      SIZE = 7,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk")
    ),
    item(
      NAME = "DvmtPropFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyLaneMiPCFuture",
        "TranRevMiPCFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseCostPerMile",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DvmtBudgetProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AnnVmtInflator",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "DAYS",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "FuelCost",
        "GasTax"
      ),
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "KwhCost",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/KWH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Fuel",
      TABLE = "Fuel",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 12,
      ISELEMENTOF = c("ULSD", "Biodiesel", "RFG", "CARBOB", "Ethanol", "Cng", "Electricity")
    ),
    item(
      NAME = "Intensity",
      TABLE = "Fuel",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehType",
      TABLE = "FuelProp",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 7,
      ISELEMENTOF = c("Auto", "LtTruck", "Bus", "Truck")
    ),
    item(
      NAME = item(
        "PropDiesel",
        "PropCng",
        "PropGas"
      ),
      TABLE = "FuelProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehType",
      TABLE = "FuelComp",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 7,
      ISELEMENTOF = c("Auto", "LtTruck", "Bus", "Truck")
    ),
    item(
      NAME = item(
        "GasPropEth",
        "DieselPropBio"
      ),
      TABLE = "FuelComp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseLtVehDvmt",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseFwyArtProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c('NA', '< 0', '> 1'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TruckVmtGrowthMultiplier",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Type",
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("BusVmt","TruckVmt"),
      SIZE = 8
    ),
    item(
      NAME = "PropVmt",
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "Fwy",
        "Art",
        "Other"
      ),
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "YR",
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoPhevRange",
        "LtTruckPhevRange"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoPropPhev",
        "LtTruckPropPhev"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoMpg",
        "LtTruckMpg"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoMpkwh",
        "LtTruckMpkwh"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/KWH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      TABLE = "HevPropMpgYr",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "YR",
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoPropHev",
        "LtTruckPropHev"
      ),
      TABLE = "HevPropMpgYr",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoHevMpg",
        "LtTruckHevMpg"
      ),
      TABLE = "HevPropMpgYr",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "YR",
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoRange",
        "LtTruckRange"
      ),
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoPropEv",
        "LtTruckPropEv"
      ),
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "AutoMpkwh",
        "LtTruckMpkwh"
      ),
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/KWH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    # Marea variables
    item(
      NAME = "TruckDvmtFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by trucks"
    ),
    # Bzone variables
    item(
      NAME = "DvmtFuture",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled"
    ),
    item(
      NAME = "EvDvmtFuture",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by electric vehicles"
    ),
    item(
      NAME = "HcDvmtFuture",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by ICE vehicles"
    ),
    # Household variables
    item(
      NAME = "DvmtFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled"
    ),
    item(
      NAME = "FuelGallonsFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GAL/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily fuel consumption in gallons"
    ),
    item(
      NAME = "FuelCo2eFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily Co2 equivalent greenhouse gass emissions"
    ),
    item(
      NAME = "ElecKwhFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily fuel consumption in gallons"
    ),
    item(
      NAME = "ElecCo2eFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily Co2 equivalent greenhouse gas emissions by
      consumption of electricity"
    ),
    item(
      NAME = "DailyParkingCostFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily parking cost"
    ),
    item(
      NAME = "FutureCostPerMileFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total fuel cost per mile"
    ),
    # Vehicle variables
    item(
      NAME = "DvmtFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled"
    ),
    item(
      NAME = "EvDvmtFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by electric vehicles"
    ),
    item(
      NAME = "HcDvmtFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by ICE vehicles"
    ),
    item(
      NAME = "MpKwhFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/KWH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Power efficiency of electric vehicles"
    ),
    item(
      NAME = "PowertrainFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c("Ice", "Hev", "Phev", "Ev"),
      SIZE = 4,
      DESCRIPTION = "Power train of vehicles"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateTravelDemandFuture module
#'
#' A list containing specifications for the CalculateTravelDemandFuture module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateTravelDemandFuture.R script.
"CalculateTravelDemandFutureSpecifications"
usethis::use_data(CalculateTravelDemandFutureSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
# This function calculates various attributes of daily travel for the
# households and the vehicles.


#Main module function calculates various attributes of travel demand
#------------------------------------------------------------
#' Calculate various attributes of travel demands for each household
#' and vehicle using future data
#'
#' \code{CalculateTravelDemandFuture} calculate various attributes of travel
#' demands for each household and vehicle using future data
#'
#' This function calculates dvmt by placetypes, households, and vehicles.
#' It also calculates fuel gallons consumed, total fuel cost, and Co2 equivalent
#' gas emission for each household using future data.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name CalculateTravelDemandFuture
#' @import visioneval
#' @export
CalculateTravelDemandFuture <- function(L) {
  #Set up
  #------
  # Function to rename variables to be consistent with Get specfications
  # of CalculateTravelDemand.

  # Function to add suffix 'Future' at the end of all the variable names
  AddSuffixFuture <- function(x, suffix = "Future"){
    # Check if x is a list
    if(is.list(x)){
      if(length(x) > 0){
        # Check if elements of x is a list
        isElementList <- unlist(lapply(x,is.list))
        # Modify the names of elements that are not the list
        noList <- x[!isElementList]
        if(!identical(names(noList),character(0))){
          names(noList) <- paste0(names(noList),suffix)
        }
        # Repeat the function for elements that are list
        yesList <- lapply(x[isElementList], AddSuffixFuture, suffix=suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }


  # Function to remove suffix 'Future' from all the variable names
  RemoveSuffixFuture <- function(x, suffix = "Future"){
    # Check if x is a list
    if(is.list(x)){
      if(length(x) > 0){
        # Check if elements of x is a list
        isElementList <- unlist(lapply(x,is.list))
        # Modify the names of elements that are not the list
        noList <- x[!isElementList]
        if(length(noList)>0){
          names(noList) <- gsub(suffix,"",names(noList))
        }
        # Repeat the function for elements that are list
        yesList <- lapply(x[isElementList], RemoveSuffixFuture, suffix=suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }

  # Modify the input data set
  L <- RemoveSuffixFuture(L)


  #Return the results
  #------------------
  # Call the CalculateTravelDemand function with the new dataset
  Out_ls <- CalculateTravelDemand(L)

  # Add 'Future' suffix to all the variables
  Out_ls <- AddSuffixFuture(Out_ls)
  #Return the outputs list
  return(Out_ls)
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateTravelDemandFuture",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateTravelDemandFuture(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateTravelDemandFuture",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
