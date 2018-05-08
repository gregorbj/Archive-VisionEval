#===================
#CalculateTravelDemandFuture.R
#===================

#This module calculates average daily vehicle miles traveld for households. It also
#calculates average DVMT, daily consumption of fuel (in gallons), and average daily
#Co2 equivalent greenhouse emissions for all vehicles.


library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
## Current implementation
### The current version implements the models used in the RPAT (GreenSTEP)
### ecosystem.



## Future Development
## Use estimation data set to create models


#Create a list to store models
#-----------------------------
DvmtLmModels_ls <-
  list(
    Metro = list(),
    NonMetro = list()
  )

#Model metropolitan households
#--------------------------------

#Dvmt assignment models
DvmtLmModels_ls$Metro <- list(
  Pow = 0.18,
  DvmtAveModel =  "0.648385696907611 * Intercept + 0.107316286790836 * LogIncome + -3.16022048698694e-06 * Htppopdn + 0.0579707838751504 * Vehicles + -0.589935044482247 * ZeroVeh + -0.000176072677256818 * TranRevMiPC + 0.0336732396115549 * FwyLaneMiPC + 0.0856778669446854 * DrvAgePop + -0.0767968906327059 * Age65Plus + -0.0612625221264959 * Urban + -1.15438441866039e-07 * Htppopdn * TranRevMiPC",
  Dvmt95thModel = "7.81647021585773 * Intercept + 3.06391786253308 * DvmtAve + -0.00758871626395843 * DvmtAveSq + 1.83095401204896e-05 * DvmtAveCu",
  DvmtMaxModel = "50.0119160585495 * Intercept + 5.27906929219219 * DvmtAve + -0.0139035520622472 * DvmtAveSq + 3.0685749202889e-05 * DvmtAveCu"
)




#Model nonmetropolitan households
#--------------------------------
#Dvmt assignment models
DvmtLmModels_ls$NonMetro <- list(
  Pow = 0.15,
  DvmtAveModel =   "0.82181397246347 * Intercept + 0.0738448153337949 * LogIncome + 0.0324723925210455 * Vehicles + -0.469682614857031 * ZeroVeh + 0.0116516830902325 * DrvAgePop + 0.00895835172329192 * Age0to14 + 0.0291167103525845 * Age15to19 + -5.79611062581841e-06 * Htppopdn + 0.0895171401046532 * Age20to29 + 0.0813624511951732 * Age30to54 + 0.0740207846059698 * Age55to64 + 0.0238611249431384 * Age65Plus + -1.42740338749305e-06 * Htppopdn * Age20to29 + -2.80938849412057e-06 * Htppopdn * Age30to54 + -3.07443537261759e-06 * Htppopdn * Age55to64 + -2.65964935441766e-06 * Htppopdn * Age65Plus",
  Dvmt95thModel = "15.866574827187 * Intercept + 3.06631274984306 * DvmtAve + -0.00234096496645993 * DvmtAveSq + 1.61936595851656e-06 * DvmtAveCu",
  DvmtMaxModel = "80.7996943524395 * Intercept + 6.27896645459 * DvmtAve + -0.00688249433543409 * DvmtAveSq + 4.66416294868692e-06 * DvmtAveCu"
)




#Save Dvmt assignment models
#-----------------------------
#' Dvmt assignment model
#'
#' A list containing the Dvmnt assignment model equation and other information
#' needed to implement the Dvmnt assignment model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Metro}{a list containing three models for metropolitan areas: average, 95th
#'   percentile, and max Dvmt assignment models}
#'   \item{NonMetro}{a list containing three models for non-metropolitan areas: average, 95th
#'   percentile, and max Dvmt assignment models}
#' }
#' @source CalculateTravelDemandFuture.R script.
"DvmtLmModels_ls"
devtools::use_data(DvmtLmModels_ls, overwrite = TRUE)


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
        "GasTax",
        "CarbonCost",
        "VmtCost"
      ),
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/GAL",
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
      SIZE = 10,
      ISELEMENTOF = c("ULSD", "Biodiesel", "RFG", "CARBOB", "Ethanol", "Cng")
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
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
    )
  ),
  #Module is callable
  Call = TRUE
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
devtools::use_data(CalculateTravelDemandFutureSpecifications, overwrite = TRUE)


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
        yesList <- lapply(x[isElementList], AddSuffixFuture)
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
        yesList <- lapply(x[isElementList], RemoveSuffixFuture)
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
