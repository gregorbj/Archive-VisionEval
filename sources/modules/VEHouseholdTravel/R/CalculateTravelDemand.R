#===================
#CalculateTravelDemand.R
#===================

#This module calculates average daily vehicle miles traveld for households. It also
#calculates average DVMT, daily consumption of fuel (in gallons), and average daily
#Co2 equivalent greenhouse emissions for all vehicles.


# Copyright [2017] [AASHTO]
# Based in part on works previously copyrighted by the Oregon Department of
# Transportation and made available under the Apache License, Version 2.0 and
# compatible open-source licenses.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
DvmtModels_ls <-
  list(
    Metro = list(),
    NonMetro = list()
  )

#Model metropolitan households
#--------------------------------

#Dvmt assignment models
DvmtModels_ls$Metro$Pow <- 0.18
DvmtModels_ls$Metro <- list(
  DvmtAveModel =  "0.648385696907611 * Intercept + 0.107316286790836 * LogIncome + -3.16022048698694e-06 * Htppopdn + 0.0579707838751504 * Vehicles + -0.589935044482247 * ZeroVeh + -0.000176072677256818 * TranRevMiPC + 0.0336732396115549 * FwyLaneMiPC + 0.0856778669446854 * DrvAgePop + -0.0767968906327059 * Age65Plus + -0.0612625221264959 * Urban + -1.15438441866039e-07 * Htppopdn * TranRevMiPC",
  Dvmt95thModel = "7.81647021585773 * Intercept + 3.06391786253308 * DvmtAve + -0.00758871626395843 * DvmtAveSq + 1.83095401204896e-05 * DvmtAveCu",
  DvmtMaxModel = "50.0119160585495 * Intercept + 5.27906929219219 * DvmtAve + -0.0139035520622472 * DvmtAveSq + 3.0685749202889e-05 * DvmtAveCu"
)




#Model nonmetropolitan households
#--------------------------------
#Dvmt assignment models
DvmtModels_ls$Metro$Pow <- 0.15
DvmtModels_ls$NonMetro <- list(
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
#' @source CalculateTravelDemand.R script.
"DvmtModels_ls"
devtools::use_data(DvmtModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateTravelDemandSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "Fuel",
      GROUP = "Global"
    ),
    item(
      TABLE = "FuelProp",
      GROUP = "Global"
    ),
    item(
      TABLE = "FuelComp",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "Fuel",
      TABLE = "Fuel",
      GROUP = "Global",
      FILE = "region_fuel_co2.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 10,
      ISELEMENTOF = c("ULSD", "Biodiesel", "RFG", "CARBOB", "Ethanol", "Cng"),
      DESCRIPTION = "The fuel type for which the CO2 equivalent emissions are calculated"
    ),
    item(
      NAME = "Intensity",
      TABLE = "Fuel",
      GROUP = "Global",
      FILE = "region_fuel_co2.csv",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Multipliers used to convert fuel use to CO2 equivalent emissions"
    ),
    item(
      NAME = "VehType",
      TABLE = "FuelProp",
      GROUP = "Global",
      FILE = "region_fuel_prop_by_veh.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 7,
      ISELEMENTOF = c("Auto", "LtTruck", "Bus", "Truck"),
      DESCRIPTION = "The road vehicle types that VERPAT represents"
    ),
    item(
      NAME = item(
        "PropDiesel",
        "PropCng",
        "PropGas"
      ),
      TABLE = "FuelProp",
      GROUP = "Global",
      FILE = "region_fuel_prop_by_veh.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The proportion of fleet that uses diesel",
        "The proportion of fleet that uses cng",
        "The proportion of fleet that uses gasoline"
      )
    ),
    item(
      NAME = "VehType",
      TABLE = "FuelComp",
      GROUP = "Global",
      FILE = "region_fuel_composition_prop.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 7,
      ISELEMENTOF = c("Auto", "LtTruck", "Bus", "Truck"),
      DESCRIPTION = "The road vehicle types that VERPAT represents"
    ),
    item(
      NAME = item(
        "GasPropEth",
        "DieselPropBio"
      ),
      TABLE = "FuelComp",
      GROUP = "Global",
      FILE = "region_fuel_composition_prop.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The average ethanol proportion in gasoline sold",
        "The average biodiesel proportion in diesel sold"
      )
    )
  ),
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
      UNITS = "USD.1999",
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("HhId",
                   "VehId"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Mileage",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      SIZE = 7,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk")
    ),
    item(
      NAME = "DvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyLaneMiPC",
        "TranRevMiPC"
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
      NAME = "TrnstnProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Dvmt",
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
      NAME = "Dvmt",
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
      NAME = "FuelGallons",
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
      NAME = "FuelCo2e",
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
      NAME = "DailyParkingCost",
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
      NAME = "FutureCostPerMile",
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
      NAME = "Dvmt",
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
#' Specifications list for CalculateTravelDemand module
#'
#' A list containing specifications for the CalculateTravelDemand module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateTravelDemand.R script.
"CalculateTravelDemandSpecifications"
devtools::use_data(CalculateTravelDemandSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
# This function calculates various attributes of daily travel for the
# households and the vehicles.


#Define a function that predicts average DVMT for each household
#---------------------------------------------------------------------------
#' Function to predict average DVMT
#'
#' \code{predictAveDvmt} predicts average DVMT for each household.
#'
#' This function takes a data frame of households and a list of models which
#' are used to predict the average daily vehicle miles traveled for each
#' household.
#' @param Hh_df A household data frame consisting of household attributes used to
#' predict average DVMT.
#' @param Model_ls A list of DVMT assignment models.
#' @param Type A string indicating the region type. ("Metro": Default, or "NonMetro")
#' @return A matrix containing average, maximum, and 95th percentile of daily
#' vehicle miles traveled.
predictAveDvmt <- function( Hh_df, Model_ls, Type ) {
  # Check if proper Type specified
  if( !( Type %in% c( "Metro", "NonMetro" ) ) ) {
    stop( "Type must be either 'Metro' or 'NonMetro'" )
  }
  # Extract model components for specified type
  DvmtAveModel <- Model_ls[[Type]]$DvmtAveModel
  DvmtMaxModel <- Model_ls[[Type]]$DvmtMaxModel
  Dvmt95thModel <- Model_ls[[Type]]$Dvmt95thModel
  Pow <- Model_ls[[Type]]$Pow
  # Make log income transform
  Hh_df$Income[ Hh_df$Income <= 0 ] <- 1
  Hh_df$LogIncome <- log( Hh_df$Income )
  Hh_df$ZeroVeh <- as.numeric( Hh_df$Vehicles < 1 )
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  # Boost vehicle ownership by 0.05 for carshare households

  ##########
  ## AG to CS: What is carshare? Is it the same as automobile share (auto vs LtTruck)
  Hh_df$Vehicles[ Hh_df$Carshare == 1 ] <-
    Hh_df$Vehicles[ Hh_df$Carshare == 1 ] + 0.05
  # Define an intercept variable
  Intercept <- 1
  # Apply the DVMT models
  PowDvmtAve_ <- as.vector( eval( parse( text=DvmtAveModel ), envir=Hh_df ) )
  PowDvmtAve_[ PowDvmtAve_ < 0 ] <- 0
  DvmtAve_ <- PowDvmtAve_ ^ (1/Pow)
  Hh_df$DvmtAve <- DvmtAve_
  Hh_df$DvmtAveSq <- DvmtAve_ ^ 2
  Hh_df$DvmtAveCu <- DvmtAve_ ^ 3
  DvmtMax_ <- as.vector( eval( parse( text=DvmtMaxModel ), envir=Hh_df ) )
  Dvmt95th_ <- as.vector( eval( parse( text=Dvmt95thModel ), envir=Hh_df ) )
  # Return the result
  return(cbind( DvmtAve=DvmtAve_, DvmtMax=DvmtMax_, Dvmt95th=Dvmt95th_ ))
}

#Define a function that calculates and adjusts DVMT under budget considerations
#---------------------------------------------------------------------------
#' Function to calculate and adjust DVMT
#'
#' \code{calculateAdjAveDvmt} calculates DVMT for each household and adjusts it
#' under budget consideration and annual VMT inflation.
#'
#' This function takes a data frame of households and a list of models which
#' are used to predict the average daily vehicle miles traveled for each
#' household (w/o budget consideration). These vehicle miles are then adjusted
#' after considering the budget allocated towards travel.
#' @param Hh_df A household data frame consisting of household attributes used to
#' predict average DVMT.
#' @param Model_ls A list of DVMT assignment models.
#' @param Type A string indicating the region type. ("Metro": Default, or "NonMetro")
#' @param BudgetProp A numeric signifying the proportion of budget allocated towards travel.
#' @param AnnVmtInflator A numeric indicating annual VMT inflator.
#' @param TrnstnProp A numeric indicating the transportation proportion.
#' @return A list containing adjusted average DVMT and budget for each household.
calculateAdjAveDvmt <- function( Hh_df, Model_ls, Type, BudgetProp, AnnVmtInflator=365, TrnstnProp ) {
  # Calculate the household DVMT without budget considerations
  AveDvmtHh <- predictAveDvmt( Hh_df, Model_ls, Type )[,1]
  # Put in a small value for AveDvmt if 0 or less to avoid negative or infinite calcs
  AveDvmtHh[ AveDvmtHh <= 0 ] <- 1e-6
  Hh_df$AveDvmt <- AveDvmtHh
  # Calculate base and future average costs per mile
  BaseCostPerMiHh <- Hh_df$BaseCostPerMile
  FutrCostPerMiHh <- Hh_df$BaseCostPerMile
  # Calculate household budget
  BudgetHh <- Hh_df$Income * BudgetProp / AnnVmtInflator
  # Adjust budget with insurance adjustment if that data is provided
  if( !is.null( Hh_df$InsBudgetAdj ) ) {
    InsBudgetAdjHh <- Hh_df$InsBudgetAdj
    BudgetHh <- BudgetHh - InsBudgetAdjHh
  }
  # Calculate the threshold budget cost per mile
  ThshldCostPerMiHh <- BudgetHh / AveDvmtHh
  # Make sure that the base DVMT does not exceed the budget
  BaseExceedsBudget <- ThshldCostPerMiHh < BaseCostPerMiHh
  AveDvmtHh[ BaseExceedsBudget ] <- BudgetHh[ BaseExceedsBudget ] /
    BaseCostPerMiHh[ BaseExceedsBudget ]
  ThshldCostPerMiHh[ BaseExceedsBudget ] <- BaseCostPerMiHh[ BaseExceedsBudget ]
  # Calculate parameters for computing DVMT transitions in price function
  TrnstnPriceRangeHh <- ( ThshldCostPerMiHh - BaseCostPerMiHh ) * TrnstnProp
  LwTrnstnCostPerMiHh <- ThshldCostPerMiHh - TrnstnPriceRangeHh
  HiTrnstnCostPerMiHh <- ThshldCostPerMiHh + TrnstnPriceRangeHh
  CostScaleHh <- pi / TrnstnPriceRangeHh
  TrnstnDvmtRangeHh <- ( AveDvmtHh - BudgetHh / HiTrnstnCostPerMiHh ) / 2
  DvmtScaleHh <- TrnstnDvmtRangeHh / ( cosh( 1.2 * pi ) - cosh( 0 ) )
  # Identify the portion of the curves that costs are in
  Below <- FutrCostPerMiHh < LwTrnstnCostPerMiHh
  LowTr <- FutrCostPerMiHh >= LwTrnstnCostPerMiHh &
    FutrCostPerMiHh <= ThshldCostPerMiHh
  HiTr <- FutrCostPerMiHh > ThshldCostPerMiHh &
    FutrCostPerMiHh <= HiTrnstnCostPerMiHh
  Above <- FutrCostPerMiHh > HiTrnstnCostPerMiHh
  # Calculate the adjusted DVMT
  AdjDvmtHh <- numeric( nrow( Hh_df ) )
  AdjDvmtHh[Below] <- AveDvmtHh[Below]
  AdjDvmtHh[Above] <- BudgetHh[Above] / FutrCostPerMiHh[Above]
  AdjDvmtHh[LowTr] <- AveDvmtHh[LowTr] +
    ( 1 - cosh( ( FutrCostPerMiHh[LowTr] - LwTrnstnCostPerMiHh[LowTr] )
                * CostScaleHh[LowTr] ) ) * DvmtScaleHh[LowTr]
  AdjDvmtHh[HiTr] <- BudgetHh[HiTr] / FutrCostPerMiHh[HiTr] +
    ( 1 - cosh( ( HiTrnstnCostPerMiHh[HiTr] - FutrCostPerMiHh[HiTr] )
                * CostScaleHh[HiTr] ) ) * DvmtScaleHh[HiTr]
  # If future cost per mile equals base cost per mile use base DVMT
  AdjDvmtHh[ FutrCostPerMiHh == BaseCostPerMiHh ] <-
    AveDvmtHh[ FutrCostPerMiHh == BaseCostPerMiHh ]
  # Return the results
  list( AdjDvmt=AdjDvmtHh, BaseDvmt=AveDvmtHh, Budget=BudgetHh,
        BelowTrnstn=Below, LowTrnstn=LowTr, HiTrnstn=HiTr, AboveTrnstn=Above )
}

#Define a function that calculates DVMT for all vehicles
#---------------------------------------------------------------------------
#' Function to calculate DVMT for all vehicles
#'
#' \code{calculateVehDvmt} calculates daily vehicle miles traveled for each vehicle in
#' a household.
#'
#' This function takes a data frame of households and vehicles, and assigns the household
#' average DVMT to the vehicles.
#'
#' @param Hh_df A household data frame consisting average DVMT and household id.
#' @param Vehicles_df A vehicle data frame consisting of variables used for DVMT assignment.
#' @return A numeric vector of DVMT.
calculateVehDvmt <- function( Hh_df, Vehicles_df ) {
  VehDvmt_ <- Hh_df[match(Vehicles_df$HhId, Hh_df$HhId),"Dvmt"] * Vehicles_df$DvmtProp
  return(VehDvmt = VehDvmt_)
}

#Define a function that calculates average Co2 equivalent gas emissions
#---------------------------------------------------------------------------
#' Function to calculate average Co2 equivalent gas emissions for fuels by
#' vehicle type
#'
#' \code{calculateAveFuelCo2e} calculates average Co2 equivalent gas emissions
#' by vehicle and fuel type.
#'
#' This function uses the composition of fuel and the proportion of fuel used
#' by vehicle type to calculate the average Co2 equivalent gas emissions for
#' a specific forecast year.
#' @param ForecastYear An integer indicating the forecast year.
#' @param FuelProp A data frame consisting of fuel proportion used by vehicle types.
#' @param FuelComp A data frame consisting of composition of fuels.
#' @param FuelCo2Ft A data frame containing the intensity of carbon by fuel types.
#' @param MJPerGallon A numeric indicating the energy per gallon of fuel. (Default: 121)
#' @param OutputType A string indicating the units of the output. ("MetricTons":Default or "Pounds")
#' @return A named array indicating the average Co2 equivalent gas emissions by vehicle type.
calculateAveFuelCo2e <- function( ForecastYear = NULL, FuelProp = NULL, FuelComp = NULL,
                                  FuelCo2Ft = NULL, MJPerGallon = 121, OutputType="MetricTons" ) {
  # Check that OutputType is proper values
  #---------------------------------------
  if( !( OutputType %in% c( "MetricTons", "Pounds" ) ) ) {
    stop( "OutputType must be MetricTons or Pounds" )
  }
  if(is.null(ForecastYear) | is.null(FuelProp)| is.null(FuelComp) | is.null(FuelCo2Ft)) {
    stop( "Missing arguments to the function" )
  }
  AutoIndex <- FuelProp$VehType == "Auto"
  LtTrkIndex <- FuelProp$VehType == "LtTruck"
  AutoCompIndex <- FuelComp$VehType == "Auto"
  LtTrkCompIndex <- FuelComp$VehType == "LtTruck"
  # Calculate average
  #------------------
  # Calculate auto fuel proportions
  AutoPropDieselBlend <- FuelProp[ AutoIndex, "PropDiesel" ]
  AutoPropCng <- FuelProp[ AutoIndex, "PropCng" ]
  AutoPropGasBlend <-  FuelProp[ AutoIndex, "PropGas" ]
  AutoPropEthanol <- AutoPropGasBlend *  FuelComp[ AutoCompIndex, "GasPropEth" ]
  AutoPropGas <- AutoPropGasBlend - AutoPropEthanol
  AutoPropBiodiesel <- AutoPropDieselBlend * FuelComp[ AutoCompIndex, "DieselPropBio" ]
  AutoPropDiesel <- AutoPropDieselBlend - AutoPropBiodiesel
  rm( AutoPropDieselBlend, AutoPropGasBlend )
  # Calculate light truck fuel proportions
  LtTrkPropDieselBlend <- FuelProp[ LtTrkIndex, "PropDiesel" ]
  LtTrkPropCng <- FuelProp[ LtTrkIndex, "PropCng" ]
  LtTrkPropGasBlend <-  FuelProp[ LtTrkIndex, "PropGas" ]
  LtTrkPropEthanol <- LtTrkPropGasBlend *  FuelComp[ LtTrkCompIndex, "GasPropEth" ]
  LtTrkPropGas <- LtTrkPropGasBlend - LtTrkPropEthanol
  LtTrkPropBiodiesel <- LtTrkPropDieselBlend * FuelComp[ LtTrkCompIndex, "DieselPropBio" ]
  LtTrkPropDiesel <- LtTrkPropDieselBlend - LtTrkPropBiodiesel
  rm( LtTrkPropDieselBlend, LtTrkPropGasBlend )
  # Get correct gasoline type value for the year
  if( ForecastYear == "1990" ) {
    GasCo2e <- FuelCo2Ft[ FuelCo2Ft$Fuel == "RFG", "Intensity"]
  } else {
    GasCo2e <- FuelCo2Ft[ FuelCo2Ft$Fuel == "CARBOB", "Intensity"]
  }
  # Calculate the average auto fuel carbon intensity
  AutoCo2e <- ( AutoPropGas * GasCo2e ) +
    ( AutoPropCng * FuelCo2Ft[ FuelCo2Ft$Fuel == "Cng", "Intensity"] ) +
    ( AutoPropEthanol * FuelCo2Ft[ FuelCo2Ft$Fuel == "Ethanol", "Intensity"] ) +
    ( AutoPropDiesel * FuelCo2Ft[ FuelCo2Ft$Fuel == "ULSD", "Intensity"] ) +
    ( AutoPropBiodiesel * FuelCo2Ft[ FuelCo2Ft$Fuel == "Biodiesel", "Intensity"] )
  if( OutputType == "MetricTons" ) {
    AutoCo2e <- AutoCo2e * MJPerGallon / 1000000
  }
  if( OutputType == "Pounds" ) {
    AutoCo2e <- AutoCo2e * MJPerGallon * 2.20462262 / 1000
  }
  # Calculate the average light truck fuel carbon intensity
  LtTrkCo2e <- ( LtTrkPropGas * GasCo2e ) +
    ( LtTrkPropCng * FuelCo2Ft[ FuelCo2Ft$Fuel == "Cng", "Intensity"] ) +
    ( LtTrkPropEthanol * FuelCo2Ft[ FuelCo2Ft$Fuel == "Ethanol", "Intensity"] ) +
    ( LtTrkPropDiesel * FuelCo2Ft[ FuelCo2Ft$Fuel == "ULSD", "Intensity"] ) +
    ( LtTrkPropBiodiesel * FuelCo2Ft[ FuelCo2Ft$Fuel == "Biodiesel", "Intensity"] )
  if( OutputType == "MetricTons" ) {
    LtTrkCo2e <- LtTrkCo2e * MJPerGallon / 1000000
  }
  if( OutputType == "Pounds" ) {
    LtTrkCo2e <- LtTrkCo2e * MJPerGallon * 2.20462262 / 1000
  }

  # Return the result
  #------------------
  return(c( Auto=AutoCo2e, LtTrk=LtTrkCo2e ))
}

#Define a function that calculates average Co2 equivalent gas emissions for vehicles
#---------------------------------------------------------------------------
#' Function to calculate average Co2 equivalent gas emissions for fuels for
#' the households and the vehicles
#'
#' \code{calculateVehFuelCo2} calculates average Co2 equivalent gas emissions
#' for the households and the vehicles.
#'
#' This function uses Dvmt and fuel efficiency of the vehicles, along with
#' the average Co2 equivalent gas emissions by vehicle type to assign
#' emissions to the vehicles.
#' @param Hh_df A household data frame consisting of household attributes used to
#' assign Co2 equivalent emissions.
#' @param Vehicles_df A vehicle data frame consisting of vehicle attributes used to
#' assign Co2 equivalent emissions.
#' @param AveFuelCo2e A named array indicating the average Co2 equivalent gas emissions
#' by vehicle type.
#' @return A list containing assignment of gas emissions.
calculateVehFuelCo2 <- function(Hh_df, Vehicles_df, AveFuelCo2e) {

  # Calculate fuel consumption & CO2e for households with vehicles
  #---------------------------------------------------------------
  # Idx. <- rep( 1:sum(HasVeh.Hh), Data..$Hhvehcnt[ HasVeh.Hh ] )
  Dvmt_ <- Vehicles_df$Dvmt
  Mpg_ <- Vehicles_df$Mileage
  VehType_ <- as.character(Vehicles_df$Type)
  FuelGallons_ <- as.numeric(Dvmt_ / Mpg_)
  FuelCo2e_ <- FuelGallons_ * AveFuelCo2e[ VehType_ ]
  FuelGallonsHh <- rowsum(FuelGallons_, Vehicles_df$HhId)[,1]
  FuelCo2eHh <- rowsum(FuelCo2e_, Vehicles_df$HhId)[,1]

  # Calculate totals in order to compute proportions and average rates
  #-------------------------------------------------------------------
  TotDvmt <- sum(Dvmt_)
  TotFuelGallons <- sum(FuelGallonsHh)
  TotFuelCo2e <- sum(FuelCo2eHh)

  # Calculate proportions and rates for zero-car households
  #--------------------------------------------------------
  AveGpm <- TotFuelGallons / TotDvmt
  AveFuelCo2eRate <- TotFuelCo2e / TotDvmt

  # Calculate consumption and emissions for zero-car households
  #------------------------------------------------------------
  ZeroVehDvmtHh <- Hh_df[Hh_df$ZeroVeh==1, "Dvmt"]
  names(ZeroVehDvmtHh) <- Hh_df[Hh_df$ZeroVeh==1, "HhId"]
  ZeroVehFuelGallonsHh <- ZeroVehDvmtHh * AveGpm
  ZeroVehFuelCo2eHh <- ZeroVehDvmtHh * AveFuelCo2eRate

  # Combine all household data together
  #------------------------------------
  AllFuelGallonsHh <- numeric( nrow( Hh_df ) )
  AllFuelGallonsHh[Hh_df$ZeroVeh!=1] <- FuelGallonsHh
  AllFuelGallonsHh[Hh_df$ZeroVeh==1] <- ZeroVehFuelGallonsHh
  AllFuelCo2eHh <- numeric( nrow( Hh_df ) )
  AllFuelCo2eHh[Hh_df$ZeroVeh!=1] <- FuelCo2eHh
  AllFuelCo2eHh[Hh_df$ZeroVeh==1] <- ZeroVehFuelCo2eHh

  # Return the result
  #------------------
  list( FuelGallons=AllFuelGallonsHh, FuelCo2e=AllFuelCo2eHh )
}

#Define a function that calculates total fuel cost per mile
#---------------------------------------------------------------------------
#' Function to calculate total fuel cost per mile for the households
#'
#' \code{calculateCosts} calculates total fuel cost per mile for the
#' households.
#'
#' This function uses fuel cost, gas tax, carbon cost, and vehicle miles traveled
#' by vehicles of the households to calculate total fuel cost per mile.
#' @param Hh_df A household data frame consisting of household attributes used to
#' caolculate total fuel cost per mile.
#' @param Costs A named numeric consisting of the costs, and/or tax  information.
#' @param NonPrivateFactor A numeric.
#' @return A list containing various fuel costs.
calculateCosts <- function( Hh_df, Costs, NonPrivateFactor=5 ) {
  # Calculate total daily fuel cost
  FuelCostHh <- Hh_df$FuelGallons * Costs[ "FuelCost" ]
  # Calculate gas tax cost
  GasTaxCostHh <- Hh_df$FuelGallons * Costs[ "GasTax" ]
  # Calculate total daily carbon cost
  CarbonCostHh <- ( Hh_df$FuelCo2e ) * Costs[ "CarbonCost" ]
  # Calculate total daily VMT cost
  VmtCostHh <- Hh_df$Dvmt * Costs[ "VmtCost" ]
  # Calculate total vehicle cost
  BaseCostHh <- FuelCostHh + GasTaxCostHh + CarbonCostHh + VmtCostHh
  TotCostHh <- BaseCostHh + Hh_df$DailyPkgCost
  # Calculate the average cost per mile for households that have vehicles and DVMT
  HasVehHh <- Hh_df$Vehicles >= 1
  HasDvmtHh <- Hh_df$Dvmt > 0
  AveBaseCostMile <- mean( BaseCostHh[ HasVehHh & HasDvmtHh ] / Hh_df$Dvmt[ HasVehHh & HasDvmtHh ] )
  # Calculate vehicle costs for zero vehicle households and households that have no DVMT
  HasNoVehOrNoDvmtHh <- !HasVehHh | !HasDvmtHh
  TotCostHh[ HasNoVehOrNoDvmtHh  ] <- Hh_df$Dvmt[ HasNoVehOrNoDvmtHh ] * 5 * AveBaseCostMile
  FuelCostHh[ HasNoVehOrNoDvmtHh ] <- 0
  GasTaxCostHh[ HasNoVehOrNoDvmtHh ] <- 0
  CarbonCostHh[ HasNoVehOrNoDvmtHh ] <- 0
  VmtCostHh[ HasNoVehOrNoDvmtHh ] <- 0
  # Calculate the average cost per mile
  FutrCostPerMileHh <- TotCostHh / Hh_df$Dvmt
  # Calculate average cost per mile for households with no vehicles or no DVMT
  FutrCostPerMileHh[ HasNoVehOrNoDvmtHh ] <- 5 * AveBaseCostMile
  # Reduce average cost per mile where it is out of the norm
  Cost95th <- quantile( FutrCostPerMileHh, prob=0.95 )
  FutrCostPerMileHh[ FutrCostPerMileHh > Cost95th ] <- Cost95th
  # Return the result
  list( FuelCost=FuelCostHh, GasTaxCost=GasTaxCostHh,
        CarbonCost=CarbonCostHh, VmtCost=VmtCostHh,
        TotCost=TotCostHh, FutrCostPerMi=FutrCostPerMileHh)
}

#Main module function calculates various attributes of travel demand
#------------------------------------------------------------
#' Calculate various attributes of travel demands for each household
#' and vehicle.
#'
#' \code{CalculateTravelDemand} calculate various attributes of travel
#' demands for each household and vehicle.
#'
#' This function calculates dvmt by placetypes, households, and vehicles.
#' It also calculates fuel gallons consumed, total fuel cost, and Co2 equivalent
#' gas emission for each household.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateTravelDemand <- function(L) {
  #Set up
  #------
  #Fix seed
  set.seed(L$G$Seed)

  # Get the household data frame
  Hh_df <- data.frame(L$Year$Household)

  # Assign household attributes
  ######AG to CS/BS Average Density
  ###AG to CS/BS should this be a calculated average for the region?
  Hh_df$Htppopdn <- 500
  ###AG to CS/BS should this be 0 for rural? Or are we just using an average for both density and this var and then adjusting using 5D values?
  Hh_df$FwyLaneMiPC <- L$Year$Marea$FwyLaneMiPC*1e3
  Hh_df$TranRevMiPC <- L$Year$Marea$TranRevMiPC
  Hh_df$Urban <- 1
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$ZeroVeh <- 0
  Hh_df$ZeroVeh[Hh_df$Vehicles==0] <- 1

  # Identify metropolitan area
  IsMetro_ <- Hh_df$Urban == 1

  #1st DVMT calculation (no adjustment for costs)
  #==============================================

  # Calculate the average DVMT
  #---------------------------
  ModelVar_ <- c( "Income", "Htppopdn", "Vehicles", "TranRevMiPC",
                  "FwyLaneMiPC", "DrvAgePop", "HhSize", "Age0to14",
                  "Age15to19", "Age20to29", "Age30to54", "Age55to64",
                  "Age65Plus", "Urban", "BaseCostPerMile", "FutureCostPerMile" )
  # Assume a base and future cost of 4 cents per mile
  # so that budget constraints don't impinge on the amount of vehicle travel
  Hh_df$BaseCostPerMile <- L$Global$Model$BaseCostPerMile
  Hh_df$FutureCostPerMile <- L$Global$Model$BaseCostPerMile
  Hh_df$Dvmt <- 0

  if( any( IsMetro_ ) ) {
    Hh_df$Dvmt[ IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                 DvmtModels_ls, "Metro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                 TrnstnProp=L$Global$Model$TrnstnProp )[[1]]
  }
  if( any( !IsMetro_ ) ) {
    Hh_df$Dvmt[ !IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                    DvmtModels_ls, "NonMetro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                    TrnstnProp=L$Global$Model$TrnstnProp )[[1]]
  }

  # Assign vehicle DVMT
  #====================

  # Assign vehicle mileage to household vehicles
  Vehicles_df <- data.frame(L$Year$Vehicle)
  Vehicles_df$Dvmt <- calculateVehDvmt( Hh_df[,c("HhId","Dvmt")], Vehicles_df )

  # Calculate fuel consumption and CO2e production
  #=============================================================

  # Calculate average fuel CO2e per gallon
  #---------------------------------------
  FuelProp <- data.frame(L$Global$FuelProp)
  FuelComp <- data.frame(L$Global$FuelComp)
  FuelCo2Ft <- data.frame(L$Global$Fuel)
  AveFuelCo2e_ <- calculateAveFuelCo2e( L$G$Year, FuelProp=FuelProp, FuelComp=FuelComp,
                                        FuelCo2Ft=FuelCo2Ft,
                                   MJPerGallon=121, OutputType="MetricTons" )

  # Calculate consumption and production at a household level
  #----------------------------------------------------------

  ModelVar_ <- c("HhId" ,"Mileage", "Type", "Dvmt")
  FuelCo2e_ <- calculateVehFuelCo2(Hh_df[, c("ZeroVeh","HhId", "Dvmt")], Vehicles_df[ , ModelVar_ ], AveFuelCo2e=AveFuelCo2e_ )
  Hh_df$FuelGallons <- FuelCo2e_$FuelGallons
  Hh_df$FuelCo2e <- FuelCo2e_$FuelCo2e
  rm( AveFuelCo2e_, FuelCo2e_ )
  rm( ModelVar_ )
  gc()

  #Calculate household travel costs
  #================================

  # Calculate all household costs
  #------------------------------

  # assume zero parking cost at this point
  Hh_df$DailyPkgCost <- 0
  # gathers cost parameters into costs.
  Costs_ <- c(L$Global$Model$FuelCost,
              L$Global$Model$GasTax,
              L$Global$Model$CarbonCost,
              L$Global$Model$VmtCost)
  names(Costs_) <- c("FuelCost","GasTax","CarbonCost","VmtCost")
  ModelVar_ <- c( "FuelGallons", "FuelCo2e", "Dvmt", "DailyPkgCost", "Vehicles" )
  Costs_ <- calculateCosts( Hh_df[ , ModelVar_ ], Costs_)
  Hh_df$FutureCostPerMile <- Costs_$FutrCostPerMi
  rm( Costs_, ModelVar_ )
  gc()

  # Calculate DVMT with new costs and reallocate to vehicles
  #=========================================================

  # Recalculate DVMT
  #-----------------
  PrevDvmtHh <- Hh_df$Dvmt
  ModelVar_ <- c( "Income", "Htppopdn", "Vehicles", "TranRevMiPC", "FwyLaneMiPC", "DrvAgePop",
                  "HhSize", "Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus",
                  "Urban", "BaseCostPerMile", "FutureCostPerMile" )
  if( any( IsMetro_ ) ) {
    Hh_df$Dvmt[ IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                   DvmtModels_ls, "Metro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                   TrnstnProp=L$Global$Model$TrnstnProp )[[1]]
  }
  if( any( !IsMetro_ ) ) {
    Hh_df$Dvmt[ !IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                    DvmtModels_ls, "NonMetro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                    TrnstnProp=L$Global$Model$TrnstnProp )[[1]]
  }

  # Split adjusted DVMT among vehicles
  #-----------------------------------
  DvmtAdjFactorHh <- Hh_df$Dvmt / PrevDvmtHh
  names(DvmtAdjFactorHh) <- as.character(Hh_df$HhId)
  Vehicles_df$Dvmt <- Vehicles_df$Dvmt * DvmtAdjFactorHh[as.character(Vehicles_df$HhId)]
  rm( DvmtAdjFactorHh)
  gc()

  # Sum up DVMT by development type
  #================================

  DvmtPt_ <- rowsum( Hh_df$Dvmt, Hh_df$HhPlaceTypes)[,1]
  DvmtPt_ <- DvmtPt_[as.character(L$Year$Bzone$Bzone)]
  DvmtPt_[is.na(DvmtPt_)] <- 0
  names(DvmtPt_) <- as.character(L$Year$Bzone$Bzone)

  #Return the results
  Out_ls <- initDataList()
  Out_ls$Year <- list(
    Bzone = list(),
    Household = list(),
    Vehicle = list()
  )
  # Bzone results
  Out_ls$Year$Bzone <- list(
    Dvmt = DvmtPt_
  )
  # Household results
  Out_ls$Year$Household <- list(
    Dvmt = Hh_df$Dvmt,
    FuelGallons = Hh_df$FuelGallons,
    FuelCo2e = Hh_df$FuelCo2e,
    DailyParkingCost = Hh_df$DailyPkgCost,
    FutureCostPerMile = Hh_df$FutureCostPerMile
  )
  # Vehicle results
    Out_ls$Year$Vehicle <-list(
      Dvmt = as.numeric(Vehicles_df$Dvmt)
    )
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
#   ModuleName = "CalculateTravelDemand",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateTravelDemand(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateTravelDemand",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
