#=================
#ReportRPATMetrics.R
#=================
# This module calculates and reports various performance metrics. These
# performance metrics include environment and energey impacts, financial
# and economic impacts, and community impacts.

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

load("inst/extdata/TruckBusAgeDist_.RData")
#Save Truck and Bus age distribution data
#-----------------------------
#' Truck and Bus age distribution data
#'
#' A matrix of age distribution for trucks and buses
#'
#' @format A matrix with two columns containing:
#' \describe{
#'   \item{Truck}{age distribution for trucks}
#'   \item{Bus}{age distribution for buses}
#' }
#' @source CalculateTravelDemand.R script.
"TruckBusAgeDist_mx"
devtools::use_data(TruckBusAgeDist_mx, overwrite = TRUE)
#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
ReportRPATMetricsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "AccidentRates",
      GROUP = "Global"
    ),
    item(
      TABLE = "TransportationSupplyCost",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "FuelType",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME = "SupplyClass",
      TABLE = "TransportationSupplyCost",
      GROUP = "Global",
      FILE = "model_transportation_costs.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = c("Freeway", "Arterial", "Bus", "Rail"),
      DESCRIPTION = "The class of transportation supply"
    ),
    item(
      NAME = items(
        "CapCosts",
        "OpCosts",
        "Fare"
      ),
      TABLE = "TransportationSupplyCost",
      GROUP = "Global",
      FILE = "model_transportation_costs.csv",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Transportation infrastructure investments",
        "Transportation operating costs",
        "Transit fair revenue"
      )
    ),
    item(
      NAME = "Accident",
      TABLE = "AccidentRates",
      GROUP = "Global",
      FILE = "model_accident_rates.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = c("Fatal", "Injury", "Property"),
      DESCRIPTION = "The severity/type of accidents"
    ),
    item(
      NAME = "Rate",
      TABLE = "AccidentRates",
      GROUP = "Global",
      FILE = "model_accident_rates.csv",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "The rate at which accidents happen"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    # Gather household data
    # Gather Bzone data
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 5,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 5,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TransitTrips",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "trips",
      UNITS = "TRIP",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DvmtPolicy",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    # Gather Marea data
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 9,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "MpgAdjHhPolicy",
        "MpgAdjLtVehPolicy",
        "MpgAdjTruckPolicy",
        "MpgAdjBusPolicy"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 9,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "LtVehDvmtPolicy",
        "TruckDvmtFuture",
        "BusDvmtPolicy"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 9,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "RailRevMiFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "BusRevMiPC",
        "RailRevMiPC"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyLaneMiPCFuture",
        "ArtLaneMiPCFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "TranRevMiPCFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = items(
        "BusRevMiFuture",
        "RailRevMiFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    # Gather Global data
    item(
      NAME = "CostsPolicy",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "currency",
      UNITS = "USD.2000",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "CostsIdPolicy",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 10
    ),
    item(
      NAME = "AnnVmtInflator",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TranRevMiAdjFactor",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA"),
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
      NAME = items(
        "AutoMpg",
        "LtTruckMpg",
        "TruckMpg",
        "BusMpg",
        "TrainMpg"
      ),
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "SupplyClass",
      TABLE = "TransportationSupplyCost",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = c("Freeway", "Arterial", "Bus", "Rail")
    ),
    item(
      NAME = items(
        "CapCosts",
        "OpCosts",
        "Fare"
      ),
      TABLE = "TransportationSupplyCost",
      GROUP = "Global",
      TYPE = "currency",
      UNITS = "USD.2000",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Accident",
      TABLE = "AccidentRates",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = c("Fatal", "Injury", "Property")
    ),
    item(
      NAME = "Rate",
      TABLE = "AccidentRates",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    # Gather Household data
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = c("NA"),
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
      NAME = "DvmtPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
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
      NAME = "DailyParkingCostPolicy",
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
    # Gather Vehicle data
    item(
      NAME = "HhIdFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehIdFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = c("NA"),
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
      NAME = "DvmtPolicy",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    # Save Bzone variables
    item(
      NAME = "EmissionsMetric",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MT/DAY",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "The amount of greenhouse gas emissions per day by place-types"
    ),
    item(
      NAME = "FuelMetric",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GAL/DAY",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "The amount of fuel consumed per day by place-types"
    ),
    item(
      NAME = "CostsMetric",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/DAY",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "The annual traveler cost (fuel + charges)"
    ),
    # Set Household variables
    item(
      NAME = "FuelGallonsMetric",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GAL/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily fuel consumption in gallons after policy"
    ),
    item(
      NAME = "FuelCo2eMetric",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily Co2 equivalent greenhouse gass emissions after policy"
    ),
    item(
      NAME = "FutureCostPerMileMetric",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total fuel cost per mile after policy"
    ),
    item(
      NAME = "TotalCostMetric",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total fuel cost after policy"
    ),
    # Set Marea variables
    item(
      NAME = "RailPowerMetric",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual power consumption by rail"
    ),
    item(
      NAME = items(
        "TruckFuelMetric",
        "BusFuelMetric"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GAL/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Annual truck fuel consumption",
        "Annual bus fuel consumption"
      )
    ),
    item(
      NAME = items(
        "TruckCo2eMetric",
        "BusCo2eMetric",
        "RailCo2eMetric"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MT/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Annual greenhouse gas emissions by truck",
        "Annual greenhouse gas emissions by bus",
        "Annual greenhouse gas emissions by rail"
      )
    ),
    item(
      NAME = items(
        "HighwayCostMetric",
        "TransitCapCostMetric",
        "TransitOpCostMetric",
        "TransitRevenueMetric"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Regional highway infrastructure costs",
        "Regional transit infrastructure costs",
        "Regional transit operating costs",
        "Annual fare revenue"
      )
    ),
    item(
      NAME = items(
        "FatalIncidentMetric",
        "InjuryIncidentMetric",
        "PropertyDamageMetric"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Number of fatal incidents",
        "Number of incidents with injuries",
        "Amount of incidents with property damage"
      )
    ),
    # Set FuelType variables
    item(
      NAME = "FuelTypeMetric",
      TABLE = "FuelType",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 9,
      DESCRIPTION = "The types of fuel"
    ),
    item(
      NAME = items(
        "TruckConsumptionMetric",
        "BusConsumptionMetric"
      ),
      TABLE = "FuelType",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GAL/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Annual truck fuel consumption by fuel type",
        "Annual bus fuel consumption by fuel type"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for ReportRPATMetrics module
#'
#' A list containing specifications for the ReportRPATMetrics module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source ReportRPATMetrics.R script.
"ReportRPATMetricsSpecifications"
devtools::use_data(ReportRPATMetricsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Function to adjust cumulative age distribution to match target ratio for heavy vehicles
#-------------------------------------------------------------------
#' Adjust cumulative age distribution to match target ratio for heavy vehicles
#'
#' \code{adjustHvyVehAgeDistribution} Adjusts a cumulative age distribution to match a
#' target ratio for heavy vehicles.
#'
#' This function adjusts a cumulative age distribution to match a target ratio.
#' The function returns the adjusted cumulative age distribution and the
#' corresponding age distribution.
#'
#' @param CumDist_ A named numeric vector where the names are vehicle ages and
#' the values are the proportion of vehicles that age or younger. The names must
#' be an ordered sequence from 0 to 32.
#' @param AdjRatio A number that is the target ratio value.
#' @return A numeric vector of adjusted distribution.
#' @import stats
#' @export
adjustHvyVehAgeDistribution <- function( CumDist_, AdjRatio ) {
  Ages_ <- 0:( length( CumDist_ ) - 1 )
  MaxAge <- Ages_[ length( Ages_ ) ]
  # Find decimal year which is equal to 95th percentile
  LowerIndex <- max( which( CumDist_ < 0.95 ) )
  UpperIndex <- LowerIndex + 1
  LowerValue <- CumDist_[ LowerIndex ]
  UpperValue <- CumDist_[ UpperIndex ]
  YearFraction <- ( 0.95 - LowerValue ) / ( UpperValue - LowerValue )
  Year95 <- Ages_[ LowerIndex ] + YearFraction
  # Calculate the adjustment in years
  Target95 <- Year95 * AdjRatio
  LowerShiftRatio <- Target95 / Year95
  UpperShiftRatio <- ( MaxAge - Target95 ) / ( MaxAge - Year95 )
  LowerAdjAges_ <- Ages_[ 0:LowerIndex ] * LowerShiftRatio
  UpperAgeSeq. <- ( Ages_[ UpperIndex ]:MaxAge )
  UpperAdjAges_ <- MaxAge - rev( UpperAgeSeq. - UpperAgeSeq.[1] ) * UpperShiftRatio
  AdjAges_ <- c( LowerAdjAges_, UpperAdjAges_ )
  # Calculate new cumulative proportions
  AdjCumDist_ <- CumDist_
  for( i in 2:( length( AdjCumDist_ ) - 1 ) ) {
    LowerIndex <- max( which( AdjAges_ < Ages_[i] ) )
    UpperIndex <- LowerIndex + 1
    AdjProp <- ( Ages_[i] - AdjAges_[ LowerIndex ] ) /
      ( AdjAges_[ UpperIndex ] - AdjAges_[ LowerIndex ] )
    LowerValue <- CumDist_[ LowerIndex ]
    UpperValue <- CumDist_[ UpperIndex ]
    AdjCumDist_[i] <- LowerValue + AdjProp * ( UpperValue - LowerValue )
  }
  # Convert cumulative distribution to regular distribution
  AdjDist_ <- AdjCumDist_
  for( i in length( AdjDist_ ):2 ) {
    AdjDist_[i] <- AdjDist_[i] - AdjDist_[i-1]
  }
  AdjDist_
}

# Function to assign mileage to heavy vehicles
#--------------------------------------------------------
#' Assignes mileage to heavy vehicles
#'
#' \code{assignHvyVehFuelEconomy} Assignes mileage to heavy vehicles.
#'
#' This function assigns mileage to heavy vehicles like truck or bus.
#'
#' @param AgeDist_Ag Age distribution of vehicle type.
#' @param Mpg__Yr A data frame of mileage of vehicles by type and year.
#' @param Type A string identifying the type of vehicle ("Truck" or "Bus").
#' @param CurrentYear A integer indicating the current year.
#' @return A numeric vector that indicates the mileage of vehicles.
#' @export
#'
assignHvyVehFuelEconomy <- function( AgeDist_Ag, Mpg__Yr=TrkBusMpg__Yr, Type, CurrYear ) {
  # Calculate the sequence of years to use to index fleet average MPG
  Mpg_Yr <- unlist( Mpg__Yr[ , Type ] )
  Years <- names( Mpg_Yr ) <- rownames( Mpg__Yr )
  StartYear <- as.numeric( CurrYear ) - 32
  if( StartYear < 1975 ) {
    YrSeq_ <- Years[ 1:which( Years == CurrYear ) ]
    NumMissingYr <- 1975 - StartYear
    YrSeq_ <- c( rep( "1975", NumMissingYr ), YrSeq_ )
  } else {
    YrSeq_ <- Years[ which( Years == StartYear ):which( Years == CurrYear ) ]
  }
  # Calculate auto and light truck MPG by vehicle age
  VehMpg_Ag <- rev( Mpg_Yr[ YrSeq_ ] )
  names( VehMpg_Ag ) <- as.character( 0:32 )
  # Compute weighted average
  VehMpg <- sum( VehMpg_Ag * AgeDist_Ag )
  # Return the result
  VehMpg
}



#Main module function that calculates metrics
#------------------------------------------------------------------
#' Function to calculate performance metrics.
#'
#' \code{ReportRPATMetrics} calculates performance metrics.
#'
#' This function calculates and tabulates various performance metrics
#' that ranges from environmental and energy impacts, financial and
#' economic impacts, and community impacts.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval VEHouseholdTravel
#' @export
ReportRPATMetrics <- function(L) {
  #Set up
  #------

  # Function to rename variables to be consistent with Get specfications
  # of ReportRPATMetrics

  # Function to add suffix 'Future' at the end of all the variable names
  AddSuffix <- function(x, suffix = "Future"){
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
        yesList <- lapply(x[isElementList], AddSuffix, suffix = suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }


  # Function to remove suffix 'Future' from all the variable names
  RemoveSuffix <- function(x, suffix = "Future"){
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
        yesList <- lapply(x[isElementList], RemoveSuffix, suffix = suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }

  # Modify the input data set
  L <- RemoveSuffix(L)
  L <- RemoveSuffix(L, suffix = "Policy")

  #

  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  #Get the inputs

  #Load the population
  Pop_Pt <- L$Year$Bzone$UrbanPop
  names(Pop_Pt) <- L$Year$Bzone$Bzone
  # Load results from previous model steps
  HhMpgAdj_Ma <- L$Year$Marea$MpgAdjHh
  MpgAdj_MaTy <- cbind(LtVeh=L$Year$Marea$MpgAdjLtVeh, Truck=L$Year$Marea$MpgAdjTruck, Bus=L$Year$Marea$MpgAdjBus)
  rownames(MpgAdj_MaTy) <- "Metro"
  Dvmt_MaTy <- cbind(LtVeh=L$Year$Marea$LtVehDvmt, Truck=L$Year$Marea$TruckDvmt, Bus=L$Year$Marea$BusDvmt)
  rownames(Dvmt_MaTy) <- "Metro"
  Costs_ <- L$Global$Model$Costs
  names(Costs_) <- L$Global$Model$CostsId

  # Load houshold data
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$ZeroVeh <- Hh_df$Vehicles==0
  Hh_df$Urban <- 1

  # Load vehicle data
  Vehicle_df <- data.frame(L$Year$Vehicle)

  IsMetro_ <- Hh_df$Urban == 1

  # Change the vehicle fuel economy due to congestion
  #--------------------------------------------------
  if( any( IsMetro_ ) ) {
    MpgAdj <- HhMpgAdj_Ma
    Vehicle_df$Mileage <- Vehicle_df$Mileage * MpgAdj
  }

  # Calculate average fuel CO2e per gallon
  #---------------------------------------
  FuelProp <- data.frame(L$Global$FuelProp)
  FuelComp <- data.frame(L$Global$FuelComp)
  FuelCo2Ft <- data.frame(L$Global$Fuel)
  AveFuelCo2e_ <- VEHouseholdTravel::calculateAveFuelCo2e( L$G$Year, FuelProp=FuelProp, FuelComp=FuelComp,
                                        FuelCo2Ft=FuelCo2Ft,
                                        MJPerGallon=121, OutputType="MetricTons" )

  # Calculate consumption and production at a household level
  #----------------------------------------------------------
  ModelVar_ <- c("HhId" ,"Mileage", "Type", "Dvmt")
  FuelCo2e_ <- VEHouseholdTravel::calculateVehFuelCo2(Hh_df[, c("ZeroVeh","HhId", "Dvmt")], Vehicle_df[ , ModelVar_ ], AveFuelCo2e=AveFuelCo2e_ )
  Hh_df$FuelGallons <- FuelCo2e_$FuelGallons
  Hh_df$FuelCo2e <- FuelCo2e_$FuelCo2e
  rm( AveFuelCo2e_, FuelCo2e_ )
  rm( ModelVar_ )
  gc()

  #Performance Metrics	Emissions.Pt.Rdata	Greenhouse Gas and Criteria Emissions	Environment and Energy Impacts
  #Performance Metrics	Fuel.Pt.Rdata	Fuel Consumption	Environment and Energy Impacts

  Pt <- as.character(L$Year$Bzone$Bzone)
  #Tabulate Co2e
  Emissions_Pt <- Pop_Pt * 0
  Emissions_Pt[Pt] <- tapply( Hh_df$FuelCo2e, Hh_df$HhPlaceTypes, sum )[Pt]
  Emissions_Pt[is.na(Emissions_Pt)] <- 0

  #Tabulate Fuel
  Fuel_Pt <- Pop_Pt * 0
  Fuel_Pt[Pt] <- tapply( Hh_df$FuelGallons, Hh_df$HhPlaceTypes, sum )[Pt]
  Fuel_Pt[is.na(Fuel_Pt)] <- 0


  # Calculate household travel costs
  #---------------------------------
  Hh_df$DailyPkgCost <- Hh_df$DailyParkingCost
  Hh_df$DailyParkingCost <- NULL
  ModelVar_ <- c( "FuelGallons", "FuelCo2e", "Dvmt", "DailyPkgCost", "Vehicles" )
  Costs_ <- VEHouseholdTravel::calculateCosts( Hh_df[ , ModelVar_ ], Costs_)
  Hh_df$FutureCostPerMile <- Costs_$FutrCostPerMi
  Hh_df$TotalCost <- Costs_$TotCost
  rm( Costs_, ModelVar_ )
  gc()

  #Performance Metrics	Costs.Pt.Rdata	Annual Traveler Cost (fuel and travel time)	Financial and Economic Impacts
  #Tabulate Costs
  Costs_Pt <- Pop_Pt * 0
  Costs_Pt[Pt] <- tapply( Hh_df$TotalCost, Hh_df$HhPlaceTypes, sum )[Pt] * L$Global$Model$AnnVmtInflator
  Costs_Pt[is.na(Costs_Pt)] <- 0

  #Clean up
  rm ( HhMpgAdj_Ma )

  #CALCULATE METROPOLITAN AREA HEAVY VEHICLE CONSUMPTION AND EMISSIONS
  #===================================================================

  # Calculate truck and bus age distributions
  #------------------------------------------
  # Calculate the truck age distribution
  TruckAgProp_Ag <- adjustHvyVehAgeDistribution( TruckBusAgeDist_mx[ , "Truck" ],
                                                 AdjRatio=1 )
  # Calculate bus age distribution
  BusAgProp_Ag <- adjustHvyVehAgeDistribution( TruckBusAgeDist_mx[ , "Bus" ],
                                               AdjRatio=1 )

  # Calculate truck and bus fuel economy
  #-------------------------------------
  # Calculate truck fuel economy
  VehicleMpg_Yr <- data.frame(RemoveSuffix(L$Global$Vehicles, suffix = "Mpg"))
  ModelYear <- as.character(as.integer(VehicleMpg_Yr$ModelYear))
  VehicleMpg_Yr <- as.matrix(VehicleMpg_Yr[,c("Truck","Bus","Train","Auto","LtTruck")])
  rownames(VehicleMpg_Yr) <- ModelYear

  TruckMpg <- assignHvyVehFuelEconomy( TruckAgProp_Ag, Mpg__Yr=VehicleMpg_Yr[,c("Truck","Bus")],
                                       Type="Truck", CurrYear=as.character(L$G$Year) )
  # Calculate bus fuel economy
  BusMpg <- assignHvyVehFuelEconomy( BusAgProp_Ag, Mpg__Yr=VehicleMpg_Yr[,c("Truck","Bus")], Type="Bus",
                                     CurrYear=as.character(L$G$Year) )
  # Adjust truck and bus fuel economy to account for congestion
  TruckMpg_Ma <- TruckMpg * MpgAdj_MaTy[,"Truck"]
  BusMpg_Ma <- BusMpg * MpgAdj_MaTy[,"Bus"]
  # Clean up
  rm( TruckAgProp_Ag, BusAgProp_Ag, TruckMpg, BusMpg )

  # Calculate truck fuel consumption by fuel type
  #----------------------------------------------
  # Calculate overall fuel consumption
  TruckFuel_Ma <- Dvmt_MaTy[,"Truck"] / TruckMpg_Ma
  rm( TruckMpg_Ma )
  # Calculate fuel consumption by type
  Ft <- c("ULSD", "Biodiesel", "Gasoline", "Ethanol", "CNG")
  TruckFuelProp_Ft <- numeric(5)
  names( TruckFuelProp_Ft ) <- Ft
  TruckFuelProp_ <- FuelProp[FuelProp$VehType=="Truck",]
  TruckFuelComp_ <- FuelComp[FuelProp$VehType=="Truck",]
  TruckFuelProp_Ft[ "ULSD" ] <- TruckFuelProp_[ ,"PropDiesel" ] * ( 1 - TruckFuelComp_[ ,"DieselPropBio" ] )
  TruckFuelProp_Ft[ "Biodiesel" ] <- TruckFuelProp_[ ,"PropDiesel" ] * ( TruckFuelComp_[ ,"DieselPropBio" ] )
  TruckFuelProp_Ft[ "Gasoline" ] <- TruckFuelProp_[ ,"PropGas" ] *	( 1 - TruckFuelComp_[ ,"GasPropEth" ] )
  TruckFuelProp_Ft[ "Ethanol" ] <- TruckFuelProp_[ ,"PropGas" ] * ( TruckFuelComp_[ ,"GasPropEth" ] )
  TruckFuelProp_Ft[ "CNG" ] <- ( TruckFuelProp_[ ,"PropCng" ] )
  TruckFuel_MaFt <- outer( TruckFuel_Ma, TruckFuelProp_Ft, "*" )
  rm( TruckFuelProp_, TruckFuelComp_, TruckFuelProp_Ft )

  # Calculate Bus Fuel Consumption and Emissions
  #---------------------------------------------
  # Calculate overall fuel consumption
  BusFuel_Ma <- Dvmt_MaTy[,"Bus"] / BusMpg_Ma
  rm( BusMpg_Ma )
  # Calculate fuel consumption by type
  BusFuelProp_Ft <- numeric(5)
  names( BusFuelProp_Ft ) <- Ft
  BusFuelProp_ <- FuelProp[FuelProp$VehType=="Bus",]
  BusFuelComp_ <- FuelComp[FuelProp$VehType=="Bus",]
  BusFuelProp_Ft[ "ULSD" ] <- BusFuelProp_[ ,"PropDiesel" ] * ( 1 - BusFuelComp_[ ,"DieselPropBio" ] )
  BusFuelProp_Ft[ "Biodiesel" ] <- BusFuelProp_[ ,"PropDiesel" ] * ( BusFuelComp_[ ,"DieselPropBio" ] )
  BusFuelProp_Ft[ "Gasoline" ] <- BusFuelProp_[ ,"PropGas" ] *	( 1 - BusFuelComp_[ ,"GasPropEth" ] )
  BusFuelProp_Ft[ "Ethanol" ] <- BusFuelProp_[ ,"PropGas" ] * ( BusFuelComp_[ ,"GasPropEth" ] )
  BusFuelProp_Ft[ "CNG" ] <- ( BusFuelProp_[ ,"PropCng" ] )
  BusFuel_MaFt <- outer( BusFuel_Ma, BusFuelProp_Ft, "*" )
  rm( BusFuelProp_, BusFuelComp_, BusFuelProp_Ft )

  # Calculate emissions per gallon of fuel consumed
  #------------------------------------------------
  FuelCo2_Ft <- numeric(5)
  names( FuelCo2_Ft ) <- Ft
  FuelCo2_Ft[ "ULSD" ] <- FuelCo2Ft[ FuelCo2Ft$Fuel=="ULSD", "Intensity" ]
  FuelCo2_Ft[ "Biodiesel" ] <- FuelCo2Ft[ FuelCo2Ft$Fuel=="Biodiesel", "Intensity"]
  if( L$G$Year == "1990" ) {
    FuelCo2_Ft[ "Gasoline" ] <- FuelCo2Ft[ FuelCo2Ft$Fuel=="RFG", "Intensity"]
  } else {
    FuelCo2_Ft[ "Gasoline" ] <- FuelCo2Ft[ FuelCo2Ft$Fuel=="CARBOB", "Intensity"]
  }
  FuelCo2_Ft[ "Ethanol" ] <- FuelCo2Ft[ FuelCo2Ft$Fuel=="Ethanol", "Intensity"]
  FuelCo2_Ft[ "CNG" ] <- FuelCo2Ft[ FuelCo2Ft$Fuel=="Cng", "Intensity"]

  # Calculate truck and bus emissions
  #----------------------------------
  # Calculate truck emissions
  MjPerGallon <- 121
  TruckMj_MaTy <- TruckFuel_MaFt * MjPerGallon
  TruckCo2e_MaTy <- sweep( TruckMj_MaTy, 2, FuelCo2_Ft, "*" ) / 1000000
  TruckCo2e_Ma <- rowSums( TruckCo2e_MaTy )
  rm( TruckMj_MaTy, TruckCo2e_MaTy )
  # Calculate bus emissions
  BusMj_MaTy <- BusFuel_MaFt * MjPerGallon
  BusCo2e_MaTy <- sweep( BusMj_MaTy, 2, FuelCo2_Ft, "*" ) / 1000000
  BusCo2e_Ma <- rowSums( BusCo2e_MaTy )
  rm( BusMj_MaTy, BusCo2e_MaTy, FuelCo2_Ft )

  # Calculate rail emissions
  #-------------------------
  # Calculate DVMT and power consumed
  RailRevMi_Ma <- as.numeric(L$Year$Marea$RailRevMi)

  RailDvmt_Ma <- RailRevMi_Ma * L$Global$Model$TranRevMiAdjFactor / 365
  RailPower_Ma <- RailDvmt_Ma / VehicleMpg_Yr[L$G$Year,"Train"]
  # Calculate average emissions per kwh by metropolitan area
  #######hardcoded value - do we need to caclulate this or should we just stop at RailPower_Ma?
  PowerCo2_Ma <- 1.4
  # Calculate total emissions by metropolitan area
  RailCo2e_Ma <- RailPower_Ma * PowerCo2_Ma / 2204.62262
  rm( RailDvmt_Ma, PowerCo2_Ma )


  #CALCULATE COST BASED PERFORMANCE METRICS
  #===================================================================

  #Performance Metrics	HighwayCost.Ma.Rdata	Regional Infrastructure Costs for Highway	Financial and Economic Impacts
  #Performance Metrics	TransitCapCost.Ma.Rdata	Regional Infrastructure Costs for Transit	Financial and Economic Impacts
  #Performance Metrics	TransitOpCost.Ma.Rdata	Annual Transit Operating Cost	Financial and Economic Impacts

  #Load the existing and future transportation supply
  #--------------------------------------------------
  FwyLnMiCap_Ma <- L$Year$Marea$FwyLaneMiPC
  ArtLnMiCap_Ma <- L$Year$Marea$ArtLaneMiPC
  #Future supply summaries - transit
  BusRevMi_Ma <- L$Year$Marea$BusRevMi
  RailRevMi_Ma <- L$Year$Marea$RailRevMi
  #Future transit trips
  TransitTrips_Pt <- L$Year$Bzone$TransitTrips
  names(TransitTrips_Pt) <- as.character(L$Year$Bzone$Bzone)

  #Calculate the freeway capital costs
  #-----------------------------------
  SupplyCosts_Ma <- data.frame(L$Global$TransportationSupplyCost)
  BaseFwyLnMi <- L$BaseYear$Marea$FwyLaneMi
  FutureFwyLnMi <- FwyLnMiCap_Ma * sum(Pop_Pt) / 1000
  FwyLnMiGrowth <- FutureFwyLnMi - BaseFwyLnMi
  FwyLnMiCost <- as.numeric(SupplyCosts_Ma [SupplyCosts_Ma$SupplyClass=="Freeway","CapCosts"] * FwyLnMiGrowth)

  #Calculate the arterial capital costs
  #-----------------------------------
  BaseArtLnMi <- L$BaseYear$Marea$ArtLaneMi
  FutureArtLnMi <- ArtLnMiCap_Ma * sum(Pop_Pt) / 1000
  ArtLnMiGrowth <- FutureArtLnMi - BaseArtLnMi
  ArtLnMiCost <- as.numeric(SupplyCosts_Ma [SupplyCosts_Ma$SupplyClass=="Arterial","CapCosts"] * ArtLnMiGrowth)

  #Calculate total highway costs
  #-----------------------------
  HighwayCost_Ma <- FwyLnMiCost + ArtLnMiCost

  #Calculate transit capital and operating costs
  #---------------------------------------------
  #Calculation is per trip and there are costs for bus and rail trips
  #Assume that trips are in proportion to revenue miles operated
  #Costs are in terms of just additional trips due to growth
  BusShare <- as.numeric(BusRevMi_Ma / (BusRevMi_Ma + RailRevMi_Ma))
  RailShare <- 1 - BusShare
  TransitCosts <- BusShare * SupplyCosts_Ma[SupplyCosts_Ma$SupplyClass=="Bus",c("CapCosts", "OpCosts", "Fare")] + RailShare * SupplyCosts_Ma[SupplyCosts_Ma$SupplyClass=="Rail",c("CapCosts", "OpCosts", "Fare")]
  TransitTrips <- sum(TransitTrips_Pt)

  #Annual capital cost (converted from daily to annual using AnnVmtInflator)
  TransitCapCost_Ma <- TransitCosts["CapCosts"] * TransitTrips * L$Global$Model$AnnVmtInflator
  #Annual operating cost (converted from daily to annual using AnnVmtInflator)
  TransitOpCost_Ma <- TransitCosts["OpCosts"] * TransitTrips * L$Global$Model$AnnVmtInflator
  #Annual fare revenue (converted from daily to annual using AnnVmtInflator)
  TransitRevenue_Ma <- TransitCosts["Fare"] * TransitTrips * L$Global$Model$AnnVmtInflator


  #CALCULATE Livability and Health (Accidents) Performance Metrics
  #===================================================================

  #Performance Metrics	Live.Pt.Rdata	Livability (FTA Criteria)	Community Impacts
  #Performance Metrics	Health.Pt.Rdata	Public Health Impacts and Costs	Community Impacts

  #Livability
  #####Need algorithm for this metric

  #Calculate accidents
  AccidentRates <- cbind(Rate=L$Global$AccidentRates$Rate)
  rownames(AccidentRates) <- L$Global$AccidentRates$Accident
  Dvmt_Pt <- L$Year$Bzone$Dvmt
  names(Dvmt_Pt) <- L$Year$Bzone$Bzone
  AnnVmtMillions_Ma <- sum(Dvmt_Pt) * L$Global$Model$AnnVmtInflator / 100e6
  Accidents_As <- round(AnnVmtMillions_Ma * AccidentRates,0)


  # Clean up
  gc()
  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()

  #Return the outputs list
  Out_ls$Year <- list(
    Bzone = list(
      Emissions = Emissions_Pt,
      Fuel = Fuel_Pt,
      Costs = Costs_Pt
    ),
    Household = list(
      FuelGallons = Hh_df$FuelGallons,
      FuelCo2e = Hh_df$FuelCo2e,
      FutureCostPerMile = Hh_df$FutureCostPerMile,
      TotalCost = Hh_df$TotalCost
    ),
    Marea = list(
      TruckFuel = TruckFuel_Ma,
      BusFuel = BusFuel_Ma,
      TruckCo2e = TruckCo2e_Ma,
      BusCo2e = BusCo2e_Ma,
      RailPower = RailPower_Ma,
      RailCo2e = RailCo2e_Ma,
      HighwayCost = HighwayCost_Ma,
      TransitCapCost = TransitCapCost_Ma[, "CapCosts"],
      TransitOpCost = TransitOpCost_Ma[, "OpCosts"],
      TransitRevenue = TransitRevenue_Ma[, "Fare"],
      FatalIncident = Accidents_As["Fatal",],
      InjuryIncident = Accidents_As["Injury",],
      PropertyDamage = Accidents_As["Property",]
    ),
    FuelType = list(
      FuelType = as.character(Ft),
      TruckConsumption = as.numeric(TruckFuel_MaFt),
      BusConsumption = as.numeric(BusFuel_MaFt)
    )
  )

  Out_ls <- AddSuffix(Out_ls, suffix = "Metric")
  attributes(Out_ls$Year$FuelType)$LENGTH <- length(Ft)

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
#   ModuleName = "ReportRPATMetrics",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "ReportRPATMetrics",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
