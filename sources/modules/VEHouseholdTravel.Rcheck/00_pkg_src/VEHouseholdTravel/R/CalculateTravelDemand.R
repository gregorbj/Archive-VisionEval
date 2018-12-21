#===================
#CalculateTravelDemand.R
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
#' @source CalculateTravelDemand.R script.
"DvmtLmModels_ls"
usethis::use_data(DvmtLmModels_ls, overwrite = TRUE)


#Load PHEV/HEV model data
load("./data/PhevModelData_ls.rda")

#Load default values for Travel Demand module
load("./data/TravelDemandDefaults_ls.rda")


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
      TABLE = "FuelProp",
      GROUP = "Global"
    ),
    item(
      TABLE = "FuelComp",
      GROUP = "Global"
    ),
    item(
      TABLE = "Vmt",
      GROUP = "Global"
    ),
    item(
      TABLE = "PhevRangePropYr",
      GROUP = "Global"
    ),
    item(
      TABLE = "HevPropMpgYr",
      GROUP = "Global"
    ),
    item(
      TABLE = "EvRangePropYr",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "VehType",
      TABLE = "FuelProp",
      GROUP = "Global",
      FILE = "model_fuel_prop_by_veh.csv",
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
      FILE = "model_fuel_prop_by_veh.csv",
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
      FILE = "model_fuel_composition_prop.csv",
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
      FILE = "model_fuel_composition_prop.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The average ethanol proportion in gasoline sold",
        "The average biodiesel proportion in diesel sold"
      )
    ),
    item(
      NAME = "Type",
      TABLE = "Vmt",
      GROUP = "Global",
      FILE = "region_truck_bus_vmt.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("BusVmt","TruckVmt"),
      SIZE = 8,
      DESCRIPTION = "The vehicle types for which the vmt attributes were measured"
    ),
    item(
      NAME = "PropVmt",
      TABLE = "Vmt",
      GROUP = "Global",
      FILE = "region_truck_bus_vmt.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = "The regions proportion of Vmt"
    ),
    item(
      NAME = item(
        "Fwy",
        "Art",
        "Other"
      ),
      TABLE = "Vmt",
      GROUP = "Global",
      FILE = "region_truck_bus_vmt.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The freeway proportion of Vmt",
        "The arterial proportion of Vmt",
        "The proportion of Vmt in rest of the functional classes"
      )
    ),
    item(
      NAME = "ModelYear",
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      FILE = "model_phev_range_prop_mpg_mpkwh.csv",
      TYPE = "character",
      UNITS = "YR",
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = "Year for which data is modeled"
    ),
    item(
      NAME = item(
        "AutoPhevRange",
        "LtTruckPhevRange"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      FILE = "model_phev_range_prop_mpg_mpkwh.csv",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The range of plugin hybrid automobile vehicles in miles",
        "The range of plugin hybrid light truck vehicles in miles"
      )
    ),
    item(
      NAME = item(
        "AutoPropPhev",
        "LtTruckPropPhev"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      FILE = "model_phev_range_prop_mpg_mpkwh.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The proportion of plugin hybrid automobile vehicles of total vehicles",
        "The proportion of plugin hybrid light truck vehicles of total vehicles"
      )
    ),
    item(
      NAME = item(
        "AutoMpg",
        "LtTruckMpg"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      FILE = "model_phev_range_prop_mpg_mpkwh.csv",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The efficiency of plugin hybrid automobile vehicles when operating on gasoline",
        "The efficiency of plugin hybrid light truck vehicles when operating on gasonline"
      )
    ),
    item(
      NAME = item(
        "AutoMpkwh",
        "LtTruckMpkwh"
      ),
      TABLE = "PhevRangePropYr",
      GROUP = "Global",
      FILE = "model_phev_range_prop_mpg_mpkwh.csv",
      TYPE = "compound",
      UNITS = "MI/KWH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The efficiency of plugin hybrid automobile vehicles when operating on electricity",
        "The efficiency of plugin hybrid light truck vehicles when operating on electricity"
      )
    ),
    item(
      NAME = "ModelYear",
      TABLE = "HevPropMpgYr",
      GROUP = "Global",
      FILE = "model_hev_prop_mpg.csv",
      TYPE = "character",
      UNITS = "YR",
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = "Year for which data is modeled"
    ),
    item(
      NAME = item(
        "AutoPropHev",
        "LtTruckPropHev"
      ),
      TABLE = "HevPropMpgYr",
      GROUP = "Global",
      FILE = "model_hev_prop_mpg.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The proportion of hybrid automobile vehicles of total vehicles",
        "The proportion of hybrid light truck vehicles of total vehicles"
      )
    ),
    item(
      NAME = item(
        "AutoHevMpg",
        "LtTruckHevMpg"
      ),
      TABLE = "HevPropMpgYr",
      GROUP = "Global",
      FILE = "model_hev_prop_mpg.csv",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The efficiency of hybrid automobile vehicles when operating on gasoline",
        "The efficiency of hybrid light truck vehicles when operating on gasonline"
      )
    ),
    item(
      NAME = "ModelYear",
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      FILE = "model_ev_range_prop_mpkwh.csv",
      TYPE = "character",
      UNITS = "YR",
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = "Year for which data is modeled"
    ),
    item(
      NAME = item(
        "AutoRange",
        "LtTruckRange"
      ),
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      FILE = "model_ev_range_prop_mpkwh.csv",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The range of electric automobile vehicles in miles",
        "The range of electric light truck vehicles in miles"
      )
    ),
    item(
      NAME = item(
        "AutoPropEv",
        "LtTruckPropEv"
      ),
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      FILE = "model_ev_range_prop_mpkwh.csv",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The proportion of electric automobile vehicles of total vehicles",
        "The proportion of electric light truck vehicles of total vehicles"
      )
    ),
    item(
      NAME = item(
        "AutoMpkwh",
        "LtTruckMpkwh"
      ),
      TABLE = "EvRangePropYr",
      GROUP = "Global",
      FILE = "model_ev_range_prop_mpkwh.csv",
      TYPE = "compound",
      UNITS = "MI/KWH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "The efficiency of electric automobile vehicles",
        "The efficiency of electric light truck vehicles"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    # Bzone variables
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
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    # Household variables
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    # Vehicle variables
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
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
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
    # Marea variables
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
    # Global variables
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
      NAME = "TruckDvmt",
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
      NAME = "EvDvmt",
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
      NAME = "HcDvmt",
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
      DESCRIPTION = "Average daily Co2 equivalent greenhouse gas emissions by
      consumption of fuel"
    ),
    item(
      NAME = "ElecKwh",
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
      NAME = "ElecCo2e",
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
      DESCRIPTION = "Total fuel cost per mile for future"
    ),
    # Vehicle variables
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
    ),
    item(
      NAME = "EvDvmt",
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
      NAME = "HcDvmt",
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
      NAME = "MpKwh",
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
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c("Ice", "Hev", "Phev", "Ev"),
      SIZE = 4,
      DESCRIPTION = "Power train of vehicles"
    ),
    # Global Variables
    item(
      NAME = "Fuel",
      TABLE = "Fuel",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 12,
      ISELEMENTOF = c("ULSD", "Biodiesel", "RFG", "CARBOB", "Ethanol", "Cng", "Electricity"),
      DESCRIPTION = "The fuel type for which the CO2 equivalent emissions are calculated"
    ),
    item(
      NAME = "Intensity",
      TABLE = "Fuel",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Multipliers used to convert fuel use to CO2 equivalent emissions"
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
usethis::use_data(CalculateTravelDemandSpecifications, overwrite = TRUE)


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
#' @name predictAveDvmt
#' @export
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

#Define a function that predicts max and 95th percentile DVMT for each household
#---------------------------------------------------------------------------
#' Function to predict max and 95th percentile DVMT
#'
#' \code{predictMaxDvmt} predicts max and 95th percentile DVMT for each household.
#'
#' This function takes a data frame of households and a list of models which
#' are used to predict the max and 95th percentile daily vehicle miles traveled for each
#' household.
#' @param Hh_df A household data frame consisting of household attributes used to
#' predict average DVMT.
#' @param Model_ls A list of DVMT assignment models.
#' @param Type A string indicating the region type. ("Metro": Default, or "NonMetro")
#' @return A matrix containing maximum and 95th percentile of daily
#' vehicle miles traveled.
#' @name predictMaxDvmt
#' @export
predictMaxDvmt <- function( Hh_df, Model_ls, Type ) {
  # Check if proper Type specified
  if( !( Type %in% c( "Metro", "NonMetro" ) ) ) {
    stop( "Type must be either 'Metro' or 'NonMetro'" )
  }
  # Extract model components for specified type
  DvmtMaxModel <- Model_ls[[Type]]$DvmtMaxModel
  Dvmt95thModel <- Model_ls[[Type]]$Dvmt95thModel
  Pow <- Model_ls[[Type]]$Pow

  # Define Intercept variable
  Intercept <- 1
  DvmtAve_ <- Hh_df$Dvmt
  Hh_df$DvmtAve <- DvmtAve_
  Hh_df$DvmtAveSq <- DvmtAve_ ^ 2
  Hh_df$DvmtAveCu <- DvmtAve_ ^ 3
  DvmtMax_ <- as.vector( eval( parse( text=DvmtMaxModel ), envir=Hh_df ) )
  Dvmt95th_ <- as.vector( eval( parse( text=Dvmt95thModel ), envir=Hh_df ) )
  # Return the result
  return(cbind(DvmtMax=DvmtMax_, Dvmt95th=Dvmt95th_ ))
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
#' @name calculateAdjAveDvmt
#' @export
calculateAdjAveDvmt <- function( Hh_df, Model_ls, Type, BudgetProp, AnnVmtInflator=365, TrnstnProp ) {
  # Calculate the household DVMT without budget considerations
  AveDvmt_ <- predictAveDvmt( Hh_df, Model_ls, Type )
  AveDvmtHh <- AveDvmt_[,1]
  # Put in a small value for AveDvmt if 0 or less to avoid negative or infinite calcs
  AveDvmtHh[ AveDvmtHh <= 0 ] <- 1e-6
  Hh_df$AveDvmt <- AveDvmtHh
  # Calculate base and future average costs per mile
  BaseCostPerMiHh <- Hh_df$BaseCostPerMile
  FutrCostPerMiHh <- Hh_df$FutureCostPerMile
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
#' @name calculateVehDvmt
#' @export
calculateVehDvmt <- function( Hh_df, Vehicles_df ) {
  VehDvmt_ <- Hh_df[match(Vehicles_df$HhId, Hh_df$HhId),"Dvmt"] * Vehicles_df$DvmtProp
  return(VehDvmt = VehDvmt_)
}


#Define a function that identifies HE/PHE vehicles
#---------------------------------------------------------------------------
#' Function to identify HEV/PHEV
#'
#' \code{assignPHEV} identifies HEV/PHEV.
#'
#' This function takes a data frame of households and vehicles, a list of
#' proportional model for identiying PHEVs, and a data frame of expected
#' range of HEVs and PHEVs to identify the powertrains of vehicles.
#'
#' @param Hh_df A household data frame consisting of variables required for calculation.
#' @param Veh_df A vehicle data frame consisting of variables required for calculation.
#' @param PhevRangePropYr_df A data frame consisting of expected range of PHEV.
#' @param CurrYear The year for which the assignment of powertrian should be done.
#' @param PhevPropModel_ls A list of PHEV proportional models
#' @param HevMpgPropYr_df A data frame consisting of expectedrange of HEV.
#' @param OptimProp A numeric value indicating the proportion of vehicles that need
#' to be optimized.
#' @return A list of identifying the powertrain, dvmt, and efficiency of vehicles by
#' powertrain.
#' @name assignPHEV
#' @export
assignPHEV <- function(Hh_df, Veh_df, PhevRangePropYr_df, CurrYear,
                       PhevPropModel_ls, HevMpgPropYr_df, OptimProp = 0){

  # Create array of PHEV input data
  #--------------------------------
  Phev_Yr4Ty <- array( 0, dim=c( nrow( PhevRangePropYr_df ), 4, 2 ),
                       dimnames=list( rownames( PhevRangePropYr_df ),
                                      c( "Range", "PropPhev", "Mpkwh", "Mpg" ), c( "Auto", "LtTrk" ) ) )
  Phev_Yr4Ty[,,1] <- as.matrix( PhevRangePropYr_df[,1:4] )
  Phev_Yr4Ty[,,2] <- as.matrix( PhevRangePropYr_df[,5:8] )

  # Convert PHEV inputs to be indexed by vehicle age
  #-------------------------------------------------
  # Calculate the sequence of years to use to index fleet average MPG
  Years <- rownames( Phev_Yr4Ty )
  StartYear <- as.numeric( CurrYear ) - 32
  if( StartYear < 1975 ) {
    YrSeq_ <- Years[ 1:which( Years == CurrYear ) ]
    NumMissingYr <- 1975 - StartYear
    YrSeq_ <- c( rep( "1975", NumMissingYr ), YrSeq_ )
  } else {
    YrSeq_ <- Years[ which( Years == StartYear ):which( Years == CurrYear ) ]
  }
  # Calculate PHEV data by vehicle age
  Phev_Ag4Ty <- Phev_Yr4Ty[ rev( YrSeq_ ), , ]
  rownames( Phev_Ag4Ty ) <- as.character( 0:32 )

  # Create array of HEV input data
  #-------------------------------
  Hev_Yr2Ty <- array( 0, dim=c( nrow( HevMpgPropYr_df ), 2, 2 ),
                      dimnames=list( rownames( HevMpgPropYr_df ), c( "PropHev", "Mpg" ), c( "Auto", "LtTrk" ) ) )
  Hev_Yr2Ty[,,1] <- as.matrix( HevMpgPropYr_df[,1:2] )
  Hev_Yr2Ty[,,2] <- as.matrix( HevMpgPropYr_df[,3:4] )

  # Convert the HEV inputs to be indexed by vehicle age
  #----------------------------------------------------
  Years <- rownames( Hev_Yr2Ty )
  StartYear <- as.numeric( CurrYear ) - 32
  if( StartYear < 1975 ) {
    YrSeq_ <- Years[ 1:which( Years == CurrYear ) ]
    NumMissingYr <- 1975 - StartYear
    YrSeq_ <- c( rep( "1975", NumMissingYr ), YrSeq_ )
  } else {
    YrSeq_ <- Years[ which( Years == StartYear ):which( Years == CurrYear ) ]
  }
  # Calculate HEV data by vehicle age
  Hev_Ag2Ty <- Hev_Yr2Ty[ rev( YrSeq_ ), , ]
  rownames( Hev_Ag2Ty ) <- as.character( 0:32 )

  # Make vehicle dataframe containing information needed for calculations
  #------------------------------------------------------------------------------
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Veh_df <- merge(Veh_df, Hh_df, by = "HhId", all.x=TRUE, all.y=FALSE, sort = FALSE)
  Veh_df$LogIncome <- log(Veh_df$Income)
  Veh_df$Age <- as.character(as.integer(Veh_df$Age))

  # Identify PHEV thresholds, probabilities and power consumption for each vehicle
  #-------------------------------------------------------------------------------
  InitColumn_ <- numeric( nrow( Veh_df ) )
  Veh_df$PhevRange <- InitColumn_
  Veh_df$PhevRange[ Veh_df$Type == "Auto" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "Auto" ], "Range", "Auto" ]
  Veh_df$PhevRange[ Veh_df$Type == "LtTrk" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "LtTrk" ], "Range", "LtTrk" ]
  Veh_df$PhevPropPhev <- InitColumn_
  Veh_df$PhevPropPhev[ Veh_df$Type == "Auto" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "Auto" ], "PropPhev", "Auto" ]
  Veh_df$PhevPropPhev[ Veh_df$Type == "LtTrk" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "LtTrk" ], "PropPhev", "LtTrk" ]
  Veh_df$PhevMpkwh <- InitColumn_
  Veh_df$PhevMpkwh[ Veh_df$Type == "Auto" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "Auto" ], "Mpkwh", "Auto" ]
  Veh_df$PhevMpkwh[ Veh_df$Type == "LtTrk" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "LtTrk" ], "Mpkwh", "LtTrk" ]
  Veh_df$PhevMpg <- InitColumn_
  Veh_df$PhevMpg[ Veh_df$Type == "Auto" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "Auto" ], "Mpg", "Auto" ]
  Veh_df$PhevMpg[ Veh_df$Type == "LtTrk" ] <-
    Phev_Ag4Ty[ Veh_df$Age[ Veh_df$Type == "LtTrk" ], "Mpg", "LtTrk" ]
  rm( InitColumn_ )

  # Identify HEV probabilities and MPG for each vehicle
  #----------------------------------------------------
  InitColumn_ <- numeric( nrow( Veh_df ) )
  Veh_df$HevPropHev <- InitColumn_
  Veh_df$HevPropHev[ Veh_df$Type == "Auto" ] <-
    Hev_Ag2Ty[ Veh_df$Age[ Veh_df$Type == "Auto" ], "PropHev", "Auto" ]
  Veh_df$HevPropHev[ Veh_df$Type == "LtTrk" ] <-
    Hev_Ag2Ty[ Veh_df$Age[ Veh_df$Type == "LtTrk" ], "PropHev", "LtTrk" ]
  Veh_df$HevMpg <- InitColumn_
  Veh_df$HevMpg[ Veh_df$Type == "Auto" ] <-
    Hev_Ag2Ty[ Veh_df$Age[ Veh_df$Type == "Auto" ], "Mpg", "Auto" ]
  Veh_df$HevMpg[ Veh_df$Type == "LtTrk" ] <-
    Hev_Ag2Ty[ Veh_df$Age[ Veh_df$Type == "LtTrk" ], "Mpg", "LtTrk" ]
  rm( InitColumn_ )

  # Identify PHEVs
  #---------------
  # These are vehicles that will either be PHEVs or EVs
  # Initialize a logical vector to identify PHEVs
  IsPhev_ <- rep( FALSE, nrow( Veh_df ) )
  # PHEVs identified by sampling
  if( any( Veh_df$PhevRange > 0 ) ) {
    IsPhev_ <- unlist( sapply( Veh_df$PhevPropPhev, function(x) {
      sample( c( TRUE, FALSE ), 1, prob=c( x, 1-x ) )
    } ) )
  }
  names(IsPhev_) <- Veh_df$VehId

  # Identify HEVs
  #--------------
  # Non-PHEV/EV vehicles are split into HEV vs. ICE
  # Initialize a logical vector to identify HEVs
  IsHev_ <- rep( FALSE, nrow( Veh_df ) )
  # PHEVs identified by sampling
  IsHev_ <- unlist( sapply( Veh_df$HevPropHev, function(x) {
    sample( c( TRUE, FALSE ), 1, prob=c( x, 1-x ) ) } ) )
  IsHev_ <- IsHev_ & !IsPhev_
  names(IsHev_) <- Veh_df$VehId

  # Adjust vehicle MPG to reflect PHEVs and HEVs
  #---------------------------------------------
  VehMpg_ <- Veh_df$Mileage
  names(VehMpg_) <- Veh_df$VehId
  # Get the MPG values for the plug in hybrids (not including the EV portion)
  VehMpg_[ IsPhev_ ] <- Veh_df$PhevMpg[ IsPhev_ ]
  VehMpg_[ IsHev_ ] <- Veh_df$HevMpg[ IsHev_ ]

  # Optimize allocation of DVMT to minimize fuel consumption
  #---------------------------------------------------------
  if( OptimProp != 0 ) {
    # Identify which households will optimize based on the optimization factor
    Optimize_ <- sample( c( TRUE, FALSE ), length(unique(Veh_df$HhId)), replace=TRUE,
                         prob=c( OptimProp, 1 - OptimProp ) )
    names(Optimize_) <- unique(Veh_df$HhId)
    HhIdOp_ <- names(Optimize_[Optimize_])
    # Make copy of VehMpg_ to use for sorting
    VehMpgOp_ <- VehMpg_
    # Adjust MPG of PHEV to account for electrical operation
    # Use EPA equivalent standard of 33.7 kwh per gallon gas
    # Use overall average vehicle distance traveled to compute
    AveVehDvmt <- mean( Veh_df$Dvmt )
    PropElec_ <- Veh_df$PhevRange / AveVehDvmt
    PropElec_[ PropElec_ > 1 ] <- 1
    VehMpgOp_[ IsPhev_ ] <- VehMpg_[ IsPhev_ ] * ( 1 - PropElec_[ IsPhev_ ] ) +
      Veh_df$PhevMpkwh[ IsPhev_ ] * 33.7 * PropElec_[ IsPhev_ ]
    # Put VehMpgOp_ into list form
    # SplitIndex <- rep( 1:nrow( Data.. ), Data..$Hhvehcnt )
    # VehMpgOp_ <- split( VehMpgOp_, SplitIndex. )
    # Define an optimization function
    doOptimize <- function(x, y) {
      VehDvmt_ <- unlist(x)
      VehMpg_ <- unlist(y)
      # Make VehDvmt2_ to use for ordering purposes
      VehDvmt2_ <- VehDvmt_
      VehDvmt2_[ is.na( VehMpg_ ) ] <- NA
      # Put in small sequenced values for NA values (EV positions will not change)
      VehMpg_[ is.na( VehMpg_ ) ] <- seq( 1:sum( is.na( VehMpg_ ) ) ) / 100
      VehDvmt2_[ is.na( VehDvmt2_ ) ] <- seq( 1:sum( is.na( VehDvmt2_ ) ) ) / 100
      # Return DVMT in the order of MPG
      VehDvmt_[ match( rank( VehMpg_, ties.method="first" ),
                       rank( VehDvmt2_, ties.method="first" ) ) ]
    }
    # Apply the optimization function to the households who optimize
    OptimDvmt_ <- mapply( doOptimize, split(Veh_df$Dvmt, Veh_df$HhId)[HhIdOp_],
                          split(VehMpgOp_, Veh_df$HhId)[HhIdOp_] )
    Veh_df$Dvmt[Optimize_[as.character(Veh_df$HhId)]] <- unlist(OptimDvmt_[HhIdOp_])
  }
  # Recalculate DvmtProp to be consistent with the optimized allocation
  DvmtProp_ <- tapply( Veh_df$Dvmt, INDEX = Veh_df$HhId, FUN = function(x) {
    x / sum(x) } )[unique(Veh_df$HhId)]

  # Calculate proportion of PHEV mileage using electricity
  #-------------------------------------------------------
  # Do only if there is at least one PHEV
  if( sum( IsPhev_ ) >= 1 ) {
    # Make subset of only the PHEV
    Phev_ <- Veh_df[ IsPhev_, ]
    # Select the appropriate distance proportion model for each vehicle
    ModelNames_ <- paste( "PropLE", round( Phev_$PhevRange / 5 ) * 5, sep="" )
    getModel <- function( x ) PhevPropModel_ls[["Metro"]][x]
    Models_ <- mapply( getModel, ModelNames_ )
    Phev_$Model <- Models_
    rm( ModelNames_, getModel )
    # Apply each model by type to calculate distance proportions
    Intercept <- 1
    ElecDvmtProp_ <- by( Phev_, Models_, function(x) {
      Result_ <- eval( parse( text=unique(x$Model) ), envir=x )
      names( Result_ ) <- x$VehId
      Result_ }, simplify=TRUE )
    # Put the proportions calculations into a vector
    ElecDvmtProp <- numeric( nrow( Phev_ ) )
    names( ElecDvmtProp ) <- Phev_$VehId
    for( i in 1:length( ElecDvmtProp_ ) ) {
      Prop_ <- ElecDvmtProp_[[i]]
      Prop_[ Prop_ < 0 ] <- 0
      Prop_[ Prop_ > 1 ] <- 1
      ElecDvmtProp[ names( Prop_ ) ] <- Prop_
    }
  }

  # Calculate the distances powered by electricity and hydrocarbons
  #----------------------------------------------------------------
  # Initialize vector of DVMT assigned to electric grid power
  EvVehDvmt_ <- Veh_df$Dvmt * 0
  names( EvVehDvmt_ ) <- Veh_df$VehId
  # Initialize vector of DVMT assigned to on-board hydrocarbon power
  HcVehDvmt_ <- Veh_df$Dvmt
  names( HcVehDvmt_ ) <- Veh_df$VehId
  # Adjust for PHEVs, if any
  if( sum( IsPhev_ ) >= 1 ) {
    # Calculate the average DVMT powered by electricity
    ElecDvmt_ <- ElecDvmtProp * Phev_$Dvmt
    # Include PHEV calculations in overall results
    EvVehDvmt_[ names( ElecDvmt_ ) ] <- ElecDvmt_
    HcVehDvmt_[ names( ElecDvmt_ ) ] <- HcVehDvmt_[ names( ElecDvmt_ ) ] - ElecDvmt_
    # Clean up
    rm( Phev_, Models_, Intercept, ElecDvmtProp_,
        ElecDvmtProp, Prop_, ElecDvmt_ )
  }

  # Make vectors for miles per gallon and miles per kilowatt hour
  #--------------------------------------------------------------
  VehMpg_ <- Veh_df$Mileage
  VehMpkwh_ <- VehMpg_ * NA
  # Get the MPG values for the PHEVs (not including the EV portion)
  VehMpg_[ IsPhev_ ] <- Veh_df$PhevMpg[ IsPhev_ ]
  # Put Mpkwh values for PHEVs (NA for non-EV)
  VehMpkwh_[ IsPhev_ ] <- Veh_df$PhevMpkwh[ IsPhev_ ]
  # Get the MPG values for the HEVs
  VehMpg_[ IsHev_ ] <- Veh_df$HevMpg[ IsHev_ ]
  names(VehMpg_) <- Veh_df$VehId
  names(VehMpkwh_) <- Veh_df$VehId

  # Make a vector to keep track of powertrain type
  #-----------------------------------------------
  Powertrain_ <- rep( "Ice", length( IsPhev_ ) )
  Powertrain_[ IsPhev_ ] <- "Phev"
  Powertrain_[ IsHev_ ] <- "Hev"
  names(Powertrain_) <- Veh_df$VehId

  # Put the results into list form and return the result
  #-----------------------------------------------------
  DvmtProp_ <- unlist(DvmtProp_)
  names(DvmtProp_) <- Veh_df$VehId
  list( VehDvmt_=Veh_df$Dvmt, DvmtProp_=DvmtProp_, EvVehDvmt_=EvVehDvmt_,
        HcVehDvmt_=HcVehDvmt_, VehMpg_=VehMpg_, VehMpkwh_=VehMpkwh_,
        Powertrain_=Powertrain_ )
}


#Define a function that identifies electric vehicles
#---------------------------------------------------------------------------
#' Function to identify electric vehicles
#'
#' \code{assignEv} identifies electric vehicles.
#'
#' This function takes a data frame of households and vehicles, and a data frame consisting
#' of expected range of electric vehicles to identify purely electric vehicles from
#' HEV/PHEV.
#'
#' @param Hh_df A household data frame consisting of variables required for calculation.
#' @param Veh_df A vehicle data frame consisting of variables required for calculation.
#' @param EvRangePropYr_df A data frame consisting of expected range of EV.
#' @param UseMaxDvmtCriterion A logical to indicated whether to use max dvmt criteria.
#' @return A list of identifying the powertrain, dvmt, and efficiency of vehicles by
#' powertrain.
#' @name assignEv
#' @export
assignEv <- function( Hh_df, Veh_df, EvRangePropYr_df,
                      CurrYear, UseMaxDvmtCriterion=FALSE ) {

  # Create arrays of EV input data
  #-------------------------------
  # Create an array of EV range and proportion data by year and vehicle type
  Ev_Yr3Ty <- array( 0, dim=c( nrow( EvRangePropYr_df ), 3, 2 ),
                     dimnames=list( rownames( EvRangePropYr_df ), c( "Range", "PropEv", "Mpkwh" ),
                                    c( "Auto", "LtTruck" ) ) )
  Ev_Yr3Ty[,,1] <- as.matrix( EvRangePropYr_df[,1:3] )
  Ev_Yr3Ty[,,2] <- as.matrix( EvRangePropYr_df[,4:6] )

  # Convert EV inputs to be indexed by vehicle age
  #-----------------------------------------------
  # Calculate the sequence of years to use to index fleet average MPG
  Years <- rownames( Ev_Yr3Ty )
  StartYear <- as.numeric( CurrYear ) - 32
  if( StartYear < 1975 ) {
    YrSeq_ <- Years[ 1:which( Years == CurrYear ) ]
    NumMissingYr <- 1975 - StartYear
    YrSeq_ <- c( rep( "1975", NumMissingYr ), YrSeq_ )
  } else {
    YrSeq_ <- Years[ which( Years == StartYear ):which( Years == CurrYear ) ]
  }
  # Calculate EV data by vehicle age
  Ev_Ag3Ty <- Ev_Yr3Ty[ rev( YrSeq_ ), , ]
  rownames( Ev_Ag3Ty ) <- as.character( 0:32 )

  # Make vehicle dataframe containing information needed for calculations
  #------------------------------------------------------------------------------
  Veh_df$Dvmt95 <- Hh_df[match(Veh_df$HhId, Hh_df$HhId), "Dvmt95"] * Veh_df$DvmtProp

  # Identify EV thresholds, market penetration, and power consumption
  #------------------------------------------------------------------
  Veh_df$Age <- as.character(as.integer(Veh_df$Age))
  InitColumn_ <- numeric( nrow(Veh_df ) )
  Veh_df$EvRange <- InitColumn_
  Veh_df$EvRange[Veh_df$Type == "Auto" ] <-
     Ev_Ag3Ty[Veh_df$Age[Veh_df$Type == "Auto" ], "Range", "Auto" ]
  Veh_df$EvRange[Veh_df$Type == "LtTrk" ] <-
     Ev_Ag3Ty[Veh_df$Age[Veh_df$Type == "LtTrk" ], "Range", "LtTruck" ]
  Veh_df$EvPropEv <- InitColumn_
  Veh_df$EvPropEv[Veh_df$Type == "Auto" ] <-
     Ev_Ag3Ty[Veh_df$Age[Veh_df$Type == "Auto" ], "PropEv", "Auto" ]
  Veh_df$EvPropEv[Veh_df$Type == "LtTrk" ] <-
     Ev_Ag3Ty[Veh_df$Age[Veh_df$Type == "LtTrk" ], "PropEv", "LtTruck" ]
  Veh_df$EvMpkwh <- InitColumn_
  Veh_df$EvMpkwh[Veh_df$Type == "Auto" ] <-
     Ev_Ag3Ty[Veh_df$Age[Veh_df$Type == "Auto" ], "Mpkwh", "Auto" ]
  Veh_df$EvMpkwh[Veh_df$Type == "LtTrk" ] <-
     Ev_Ag3Ty[Veh_df$Age[Veh_df$Type == "LtTrk" ], "Mpkwh", "LtTruck" ]
  rm( InitColumn_ )

  # Identify EVs
  #-------------
  # Identify PHEVs whose 95th percentile travel is less than the EV range
  IsEvCandidate_ <- (Veh_df$Dvmt95 <= Veh_df$EvRange ) & (Veh_df$Powertrain == "Phev" )
  # Select EVs from candidate vehicles
  IsEv_ <- logical( length( IsEvCandidate_ ) )
  if( any( IsEvCandidate_ ) ) {
    IsEv_[ IsEvCandidate_ ] <- unlist(
      sapply(Veh_df$EvPropEv[ IsEvCandidate_ ], function(x) {
        sample( c( TRUE, FALSE ), 1, prob=c( x, 1-x ) )
      } ) )
  }

  # Adjust values for EVs
  #----------------------
  # EVs have no MPG
 Veh_df$Mileage[ IsEv_ ] <- NA
  # All the mileage driven is EV mileage
 Veh_df$EvDvmt[ IsEv_ ] <- Veh_df$EvDvmt[ IsEv_ ] + Veh_df$HcDvmt[ IsEv_ ]
  # None of the mileage uses hydrocarbon fuel
 Veh_df$HcDvmt[ IsEv_ ] <- 0
  # EV MPKWH are the appropriate EV values
 Veh_df$Mpkwh[ IsEv_ ] <-Veh_df$EvMpkwh[ IsEv_ ]
  # Classify powertrain for EVs
 Veh_df$Powertrain[ IsEv_ ] <- "Ev"

  # Put the results into list form and return the result
  #-----------------------------------------------------
  EvDvmt_ <- Veh_df$EvDvmt
  HcDvmt_ <- Veh_df$HcDvmt
  VehMpg_ <- Veh_df$Mileage
  Mpkwh_ <- Veh_df$Mpkwh
  Powertrain_ <- Veh_df$Powertrain
  list( EvDvmt_=EvDvmt_, HcDvmt_=HcDvmt_, VehMpg_=VehMpg_,
        Mpkwh_=Mpkwh_, Powertrain_=Powertrain_ )
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
#' @name calculateAveFuelCo2e
#' @export
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

#Define a function that calculates average Co2 equivalent gas emissions
#---------------------------------------------------------------------------
#' Function to calculate average Co2 equivalent gas emissions for electricity
#' consumed by vehicle type
#'
#' \code{calculateAveElectricityCo2e} calculates average Co2 equivalent gas emissions
#' by vehicle and fuel type.
#'
#' This function uses the composition of fuel and the proportion of fuel used
#' by vehicle type to calculate the average Co2 equivalent gas emissions for
#' a specific forecast year.
#' @param ForecastYear An integer indicating the forecast year.
#' @param PowerCo2Ft A data frame containing the intensity of carbon by fuel types and electricity.
#' @param OutputType A string indicating the units of the output. ("MetricTons":Default or "Pounds")
#' @return A named array indicating the average Co2 equivalent gas emissions by vehicle type.
#' @name calculateAveElectricityCo2e
#' @export
calculateAveElectricityCo2e <- function( ForecastYear = NULL, PowerCo2Ft = NULL,
                                         OutputType="MetricTons" ) {
  # Check that OutputType is proper values
  #---------------------------------------
  if( !( OutputType %in% c( "MetricTons", "Pounds" ) ) ) {
    stop( "OutputType must be MetricTons or Pounds" )
  }
  if(is.null(ForecastYear) | is.null(PowerCo2Ft)) {
    stop( "Missing arguments to the function" )
  }

  # Calculate average electricity CO2e per KWh
  if( OutputType == "MetricTons" ) {
    PowerCo2e_ <- PowerCo2Ft[PowerCo2Ft$Fuel == "Electricity", "Intensity"] / 1000000
  }
  if( OutputType == "Pounds" ) {
    PowerCo2e_ <- PowerCo2Ft[PowerCo2Ft$Fuel == "Electricity", "Intensity"] * 2.20462262 / 1000
  }

  # Return the result
  #------------------
  return(PowerCo2e_)
}

#Define a function that calculates average Co2 equivalent gas emissions for vehicles
#---------------------------------------------------------------------------
#' Function to calculate average Co2 equivalent gas emissions for fuels and
#' electricity for the households and the vehicles
#'
#' \code{calculateVehFuelElectricCo2} calculates average Co2 equivalent gas emissions
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
#' by vehicle type per gallon of fuel.
#' @param AveElectricCo2e A numeric indicating the average Co2 equivalent gas emissions
#' per Kwh of electricity.
#' @return A list containing assignment of gas emissions.
#' @name calculateVehFuelElectricCo2
#' @export
calculateVehFuelElectricCo2 <- function(Hh_df, Vehicles_df, AveFuelCo2e, AveElectricCo2e) {

  # Calculate fuel consumption & CO2e for households with vehicles
  #---------------------------------------------------------------
  # Idx. <- rep( 1:sum(HasVeh.Hh), Data..$Hhvehcnt[ HasVeh.Hh ] )
  HcDvmt_ <- Vehicles_df$HcDvmt
  Mpg_ <- Vehicles_df$Mileage
  VehType_ <- as.character(Vehicles_df$Type)
  FuelGallons_ <- as.numeric(HcDvmt_ / Mpg_)
  FuelCo2e_ <- FuelGallons_ * AveFuelCo2e[ VehType_ ]
  FuelGallonsHh <- rowsum(FuelGallons_, Vehicles_df$HhId, na.rm = TRUE)[,1]
  FuelCo2eHh <- rowsum(FuelCo2e_, Vehicles_df$HhId, na.rm = TRUE)[,1]

  # Calculate electricity consumption & CO2e for households with vehicles
  #----------------------------------------------------------------------
  EvDvmt_ <- Vehicles_df$EvDvmt
  Mpkwh_ <- Vehicles_df$Mpkwh
  ElecKwh_ <- as.numeric(EvDvmt_ / Mpkwh_)
  ElecCo2e_ <- ElecKwh_ * AveElectricCo2e
  ElecKwhHh <- rowsum(ElecKwh_, Vehicles_df$HhId, na.rm = TRUE)[,1]
  ElecCo2eHh <- rowsum(ElecCo2e_, Vehicles_df$HhId, na.rm = TRUE)[,1]

  # Calculate totals in order to compute proportions and average rates
  #-------------------------------------------------------------------
  TotHcDvmt <- sum( HcDvmt_, na.rm=TRUE )
  TotEvDvmt <- sum( EvDvmt_, na.rm=TRUE )
  TotFuelGallons <- sum( FuelGallonsHh )
  TotFuelCo2e <- sum( FuelCo2eHh )
  TotElecKwh <- sum( ElecKwhHh )
  TotElecCo2e <- sum( ElecCo2eHh )

  # Calculate proportions and rates for zero-car households
  #--------------------------------------------------------
  PropHcDvmt <- TotHcDvmt / ( TotHcDvmt + TotEvDvmt )
  AveGpm <- TotFuelGallons / TotHcDvmt
  AveFuelCo2eRate <- TotFuelCo2e / TotHcDvmt
  if( TotEvDvmt == 0 ) {
    AveKwhpm <- 0
    AveElecCo2eRate <- 0
  } else {
    AveKwhpm <- TotElecKwh / TotEvDvmt
    AveElecCo2eRate <- TotElecCo2e / TotEvDvmt
  }

  # Calculate consumption and emissions for zero-car households
  #------------------------------------------------------------
  ZcHcDvmtHh <- Hh_df[Hh_df$ZeroVeh==1, "Dvmt"] * PropHcDvmt
  ZcEvDvmtHh <- Hh_df[Hh_df$ZeroVeh==1, "Dvmt"] * ( 1 - PropHcDvmt )
  ZcFuelGallonsHh <- ZcHcDvmtHh * AveGpm
  ZcFuelCo2eHh <- ZcHcDvmtHh * AveFuelCo2eRate
  ZcElecKwhHh <- ZcEvDvmtHh * AveKwhpm
  ZcElecCo2eHh <- ZcEvDvmtHh * AveElecCo2eRate

  # Combine all household data together
  #------------------------------------
  AllFuelGallonsHh <- numeric( nrow( Hh_df ) )
  AllFuelGallonsHh[Hh_df$ZeroVeh!=1] <- FuelGallonsHh
  AllFuelGallonsHh[Hh_df$ZeroVeh==1] <- ZcFuelGallonsHh
  AllFuelCo2eHh <- numeric( nrow( Hh_df ) )
  AllFuelCo2eHh[Hh_df$ZeroVeh!=1] <- FuelCo2eHh
  AllFuelCo2eHh[Hh_df$ZeroVeh==1] <- ZcFuelCo2eHh
  AllElecKwhHh <- numeric( nrow( Hh_df ) )
  AllElecKwhHh[ Hh_df$ZeroVeh!=1 ] <- ElecKwhHh
  AllElecKwhHh[ Hh_df$ZeroVeh==1 ] <- ZcElecKwhHh
  AllElecCo2eHh <- numeric( nrow( Hh_df ) )
  AllElecCo2eHh[ Hh_df$ZeroVeh!=1 ] <- ElecCo2eHh
  AllElecCo2eHh[ Hh_df$ZeroVeh==1 ] <- ZcElecCo2eHh

  # Return the result
  #------------------
  list( FuelGallons=AllFuelGallonsHh, FuelCo2e=AllFuelCo2eHh,
        ElecKwh=AllElecKwhHh, ElecCo2e=AllElecCo2eHh)
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
#' @name calculateCosts
#' @export
calculateCosts <- function( Hh_df, Costs, NonPrivateFactor=5 ) {
  # Calculate total daily fuel cost
  FuelCostHh <- Hh_df$FuelGallons * Costs[ "FuelCost" ]
  # Calculate total daily electricity cost
  PowerCostHh <- Hh_df$ElecKwh * Costs[ "KwhCost" ]
  # Calculate gas tax cost
  GasTaxCostHh <- Hh_df$FuelGallons * Costs[ "GasTax" ]
  # Calculate total daily carbon cost
  CarbonCostHh <- ( Hh_df$FuelCo2e + Hh_df$ElecCo2e ) * Costs[ "CarbonCost" ]
  # Calculate total daily VMT cost
  VmtCostHh <- Hh_df$Dvmt * Costs[ "VmtCost" ]
  # Calculate total vehicle cost
  BaseCostHh <- FuelCostHh + PowerCostHh + GasTaxCostHh + CarbonCostHh + VmtCostHh
  TotCostHh <- BaseCostHh + Hh_df$DailyPkgCost
  # Calculate the average cost per mile for households that have vehicles and DVMT
  HasVehHh <- Hh_df$Vehicles >= 1
  # Added this constraint to protect against really small values
  HasDvmtHh <- Hh_df$Dvmt > 0.5
  AveBaseCostMile <- mean( BaseCostHh[ HasVehHh & HasDvmtHh ] / Hh_df$Dvmt[ HasVehHh & HasDvmtHh ] )
  # Calculate vehicle costs for zero vehicle households and households that have no DVMT
  HasNoVehOrNoDvmtHh <- !HasVehHh | !HasDvmtHh
  TotCostHh[ HasNoVehOrNoDvmtHh  ] <- Hh_df$Dvmt[ HasNoVehOrNoDvmtHh ] * 5 * AveBaseCostMile
  FuelCostHh[ HasNoVehOrNoDvmtHh ] <- 0
  PowerCostHh[ HasNoVehOrNoDvmtHh ] <- 0
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
  list( FuelCost=FuelCostHh, PowerCost=PowerCostHh,
        GasTaxCost=GasTaxCostHh, CarbonCost=CarbonCostHh,
        VmtCost=VmtCostHh, TotCost=TotCostHh,
        FutrCostPerMi=FutrCostPerMileHh)
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
#' @name CalculateTravelDemand
#' @import visioneval
#' @export
CalculateTravelDemand <- function(L) {
  #Set up
  #------
  #Fix seed
  set.seed(L$G$Seed)

  # Get the household data frame
  Hh_df <- data.frame(L$Year$Household, stringsAsFactors = FALSE)

  # Assign household attributes
  ######AG to CS/BS Average Density
  ###AG to CS/BS should this be a calculated average for the region?
  Hh_df$Htppopdn <- 500
  ###AG to CS/BS should this be 0 for rural? Or are we just using an average for both density and this var and then adjusting using 5D values?
  Hh_df$FwyLaneMiPC <- L$Year$Marea$FwyLaneMiPC
  Hh_df$TranRevMiPC <- L$Year$Marea$TranRevMiPC
  Hh_df$Urban <- 1
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$ZeroVeh <- 0
  Hh_df$ZeroVeh[Hh_df$Vehicles==0] <- 1
  Hh_df$Carshare <- 0

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
                                                 DvmtLmModels_ls, "Metro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                 TrnstnProp=1 )[[1]]
  }
  if( any( !IsMetro_ ) ) {
    Hh_df$Dvmt[ !IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                    DvmtLmModels_ls, "NonMetro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                    TrnstnProp=1 )[[1]]
  }

  # Calculae Max and 95th percentile DVMT
  #--------------------------------------
  ModelVar_ <- c("HhId","Dvmt")

  Hh_df$Dvmt95 <- 0
  if( any( IsMetro_ ) ) {
    MaxDvmt_ <- predictMaxDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                   DvmtLmModels_ls, "Metro")
    Hh_df$Dvmt95[ IsMetro_ ] <- MaxDvmt_[,2]
  }
  if( any( !IsMetro_ ) ) {
    MaxDvmt_ <- predictMaxDvmt( Hh_df[ !IsMetro_, ModelVar_ ],
                                DvmtLmModels_ls, "NonMetro")
    Hh_df$Dvmt95[ !IsMetro_ ] <- MaxDvmt_[,2]
  }

  # Assign vehicle DVMT
  #====================

  # Assign vehicle mileage to household vehicles
  Vehicles_df <- data.frame(L$Year$Vehicle, stringsAsFactors = FALSE)
  Vehicles_df$Dvmt <- calculateVehDvmt( Hh_df[,c("HhId","Dvmt")], Vehicles_df )

  # Identify HEVs & PHEVs
  #======================

  #Apply HEV/PHEV model
  HhVar_ <- c(
    "HhId",
    "Vehicles",
    "Carshare",
    "Income",
    "Htppopdn",
    "HhSize",
    "Age0to14",
    "Age65Plus",
    "TranRevMiPC",
    "Urban"
  )

  VehVar_ <- c(
    "HhId",
    "VehId",
    "Type",
    "Age",
    "Mileage",
    "Dvmt"
  )

  HasVeh_Hh <- Hh_df$Vehicles > 0

  PhevRangePropYr_df <- data.frame(L$Global$PhevRangePropYr)
  rownames(PhevRangePropYr_df) <- as.character(PhevRangePropYr_df$ModelYear)
  PhevRangePropYr_df$ModelYear <- NULL
  RangeNames_ <- grep("Range", colnames(PhevRangePropYr_df), value = TRUE)
  PhevRangePropYr_df[,RangeNames_] <- apply(PhevRangePropYr_df[,RangeNames_], 2, as.integer)
  PhevRangePropYr_df <- PhevRangePropYr_df[,  c("AutoPhevRange" , "AutoPropPhev", "AutoMpkwh",
                                                "AutoMpg", "LtTruckPhevRange", "LtTruckPropPhev",
                                                "LtTruckMpkwh", "LtTruckMpg") ]

  HevPropMpgYr_df <- data.frame(L$Global$HevPropMpgYr)
  rownames(HevPropMpgYr_df) <- as.character(HevPropMpgYr_df$ModelYear)
  HevPropMpgYr_df$ModelYear <- NULL
  HevPropMpgYr_df <- HevPropMpgYr_df[, c("AutoPropHev", "AutoHevMpg", "LtTruckPropHev", "LtTruckHevMpg")]

  EvRangePropYr_df <- data.frame(L$Global$EvRangePropYr)
  rownames(EvRangePropYr_df) <- as.character(EvRangePropYr_df$ModelYear)
  EvRangePropYr_df$ModelYear <- NULL
  RangeNames_ <- grep("Range", colnames(EvRangePropYr_df), value = TRUE)
  EvRangePropYr_df[,RangeNames_] <- apply(EvRangePropYr_df[,RangeNames_], 2, as.integer)
  EvRangePropYr_df <- EvRangePropYr_df[, c("AutoRange", "AutoPropEv", "AutoMpkwh", "LtTruckRange",
                                           "LtTruckPropEv", "LtTruckMpkwh")]

  PhevResults_ <- assignPHEV(Hh_df = Hh_df[HasVeh_Hh, HhVar_],
                             Veh_df = Vehicles_df[, VehVar_],
                             PhevRangePropYr_df = PhevRangePropYr_df,
                             PhevPropModel_ls = PhevModelData_ls$PhevMilePropModel_ls,
                             HevMpgPropYr_df = HevPropMpgYr_df,
                             OptimProp = PhevModelData_ls$OptimPropYr_ar[L$G$Year],
                             CurrYear = L$G$Year)

  #Update vehicle data
  Vehicles_df$Dvmt <- PhevResults_$VehDvmt_
  Vehicles_df$DvmtProp <- PhevResults_$DvmtProp_
  Vehicles_df$EvDvmt <- NA
  Vehicles_df$EvDvmt <- PhevResults_$EvVehDvmt_
  Vehicles_df$HcDvmt <- NA
  Vehicles_df$HcDvmt <- PhevResults_$HcVehDvmt_
  Vehicles_df$Mileage <- PhevResults_$VehMpg_
  Vehicles_df$Mpkwh <- NA
  Vehicles_df$Mpkwh <- PhevResults_$VehMpkwh_
  Vehicles_df$Mpkwh[is.na(Vehicles_df$Mpkwh)] <- 0
  Vehicles_df$Powertrain <- NA
  Vehicles_df$Powertrain <- PhevResults_$Powertrain_

  rm(PhevResults_, HhVar_, VehVar_)
  gc()

  # Identify EVs
  #===============
  #Apply EV model
  HhVar_ <- c(
    "HhId",
    "Vehicles",
    "Dvmt95"
  )

  VehVar_ <- c(
    "HhId",
    "VehId",
    "Type",
    "Age",
    "Mileage",
    "Dvmt",
    "DvmtProp",
    "Mpkwh",
    "EvDvmt",
    "HcDvmt",
    "Powertrain"
  )

  HasVeh_Hh <- Hh_df$Vehicles > 0
  HasDvmt_Hh <- Hh_df$Dvmt > 0

  EvResults_ <- assignEv(Hh_df = Hh_df[HasVeh_Hh & HasDvmt_Hh, HhVar_],
                         Veh_df = Vehicles_df[, VehVar_],
                         EvRangePropYr_df = EvRangePropYr_df,
                         CurrYear = L$G$Year)

  Vehicles_df$EvDvmt <- EvResults_$EvDvmt_
  Vehicles_df$HcDvmt <- EvResults_$HcDvmt_
  Vehicles_df$Mileage <- EvResults_$VehMpg_
  Vehicles_df$Mpkwh <- EvResults_$Mpkwh_
  Vehicles_df$Powertrain <- EvResults_$Powertrain_
  rm(EvResults_, HasVeh_Hh, HasDvmt_Hh, HhVar_, VehVar_)
  gc()

  # Calculate fuel consumption and CO2e production
  #=============================================================

  # Calculate average fuel CO2e per gallon
  #---------------------------------------
  FuelProp <- data.frame(L$Global$FuelProp, stringsAsFactors = FALSE)
  FuelComp <- data.frame(L$Global$FuelComp, stringsAsFactors = FALSE)
  FuelCo2Ft <- data.frame(L$Global$Fuel, stringsAsFactors = FALSE)
  AveFuelCo2e_ <- calculateAveFuelCo2e( L$G$Year, FuelProp=FuelProp, FuelComp=FuelComp,
                                        FuelCo2Ft=FuelCo2Ft,
                                   MJPerGallon=121, OutputType="MetricTons" )

  # Calculate average electricity CO2e per KWh
  #---------------------------------------------
  if(!"Electricity" %in% L$Global$Fuel$Fuel){
    if(!exists("TravelDemandDefaults_ls")){
      TravelDemandDefaults_ls <- VEHouseholdTravel::TravelDemandDefaults_ls
    }
    CI_df <- TravelDemandDefaults_ls$CarbonIntensity_df
    RegionName_ <- strsplit(L$G$Region, " ")[[1]]
    StateCode_ <- L$G$State
    CI_ <- NA
    for(Name_ in RegionName_){
      Index_ <- (CI_df$County %in% Name_) &
                (CI_df$State %in% StateCode_)
      CI_ <- CI_df[Index_,paste0("X",L$G$Year)]
      if(length(CI_) < 1) CI_ <- NA
      if(!is.na(CI_)) break
    }
    if(is.na(CI_)) CI_ <- 0.75 # Default value
    CI_ <- convertUnits(CI_, DataType = "compound",
                        FromUnits = "LB/KWH",
                        ToUnits = "GM/MJ")
    L$Global$Fuel$Fuel <- c(L$Global$Fuel$Fuel, "Electricity")
    L$Global$Fuel$Intensity <- c(L$Global$Fuel$Intensity,  CI_$Values[1])
    FuelCo2Ft <- data.frame(L$Global$Fuel, stringsAsFactors = FALSE)
    rm(CI_df, RegionName_, StateCode_, CI_)
  }
  AveElectricCo2e_ <- calculateAveElectricityCo2e( L$G$Year, PowerCo2Ft=FuelCo2Ft,
                                                   OutputType="MetricTons" )

  # Calculate consumption and production at a household level
  #----------------------------------------------------------

  ModelVar_ <- c("HhId" ,"Mileage", "Mpkwh", "Type", "EvDvmt", "HcDvmt")
  FuelElecCo2e_ <- calculateVehFuelElectricCo2(Hh_df[, c("ZeroVeh","HhId", "Dvmt")],
                                           Vehicles_df[ , ModelVar_ ],
                                           AveFuelCo2e=AveFuelCo2e_,
                                           AveElectricCo2e = AveElectricCo2e_ )
  Hh_df$FuelGallons <- FuelElecCo2e_$FuelGallons
  Hh_df$FuelCo2e <- FuelElecCo2e_$FuelCo2e
  Hh_df$ElecKwh <- FuelElecCo2e_$ElecKwh
  Hh_df$ElecCo2e <- FuelElecCo2e_$ElecCo2e
  rm( AveFuelCo2e_, AveElectricCo2e_, FuelElecCo2e_ )
  rm( ModelVar_ )
  gc()

  #Calculate household travel costs
  #================================

  # Calculate all household costs
  #------------------------------

  # assume zero parking cost at this point
  Hh_df$DailyPkgCost <- 0
  if(is.null(L$Global$Model$VmtCost)){
    L$Global$Model$VmtCost <- 0
  }
  if(is.null(L$Global$Model$CarbonCost)){
    L$Global$Model$CarbonCost <- 0
  }
  # gathers cost parameters into costs.
  Costs_ <- c(L$Global$Model$FuelCost,
              L$Global$Model$KwhCost,
              L$Global$Model$GasTax,
              L$Global$Model$CarbonCost,
              L$Global$Model$VmtCost)
  names(Costs_) <- c("FuelCost", "KwhCost","GasTax","CarbonCost","VmtCost")
  ModelVar_ <- c("HhId", "FuelGallons", "FuelCo2e", "ElecKwh", "ElecCo2e", "Dvmt", "DailyPkgCost", "Vehicles" )
  Costs_ <- calculateCosts( Hh_df[ , ModelVar_ ], Costs = Costs_)
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
                                                   DvmtLmModels_ls, "Metro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                   TrnstnProp=1 )[[1]]
  }
  if( any( !IsMetro_ ) ) {
    Hh_df$Dvmt[ !IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                    DvmtLmModels_ls, "NonMetro", BudgetProp=L$Global$Model$DvmtBudgetProp, AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                    TrnstnProp=1 )[[1]]
  }

  # Split adjusted DVMT among vehicles
  #-----------------------------------
  DvmtAdjFactorHh <- Hh_df$Dvmt / PrevDvmtHh
  names(DvmtAdjFactorHh) <- as.character(Hh_df$HhId)
  Vehicles_df$Dvmt <- Vehicles_df$Dvmt * DvmtAdjFactorHh[as.character(Vehicles_df$HhId)]
  Vehicles_df$EvDvmt <- Vehicles_df$EvDvmt * DvmtAdjFactorHh[as.character(Vehicles_df$HhId)]
  Vehicles_df$HcDvmt <- Vehicles_df$HcDvmt * DvmtAdjFactorHh[as.character(Vehicles_df$HhId)]
  rm( DvmtAdjFactorHh)
  gc()

  # Sum up DVMT by development type
  #================================

  DvmtPt_ <- rowsum( Hh_df$Dvmt, Hh_df$HhPlaceTypes, reorder = FALSE)[,1]
  DvmtPt_ <- DvmtPt_[as.character(L$Year$Bzone$Bzone)]
  DvmtPt_[is.na(DvmtPt_)] <- 0
  names(DvmtPt_) <- as.character(L$Year$Bzone$Bzone)

  EvDvmtPt_ <- rowsum( Vehicles_df$EvDvmt, Hh_df$HhPlaceTypes[match(Vehicles_df$HhId, Hh_df$HhId)], reorder = FALSE)[,1]
  EvDvmtPt_ <- EvDvmtPt_[as.character(L$Year$Bzone$Bzone)]
  EvDvmtPt_[is.na(EvDvmtPt_)] <- 0
  names(EvDvmtPt_) <- as.character(L$Year$Bzone$Bzone)

  HcDvmtPt_ <- rowsum( Vehicles_df$HcDvmt, Hh_df$HhPlaceTypes[match(Vehicles_df$HhId, Hh_df$HhId)], reorder = FALSE)[,1]
  HcDvmtPt_ <- HcDvmtPt_[as.character(L$Year$Bzone$Bzone)]
  HcDvmtPt_[is.na(HcDvmtPt_)] <- 0
  names(HcDvmtPt_) <- as.character(L$Year$Bzone$Bzone)

  #CALCULATE HEAVY TRUCK VMT
  #=========================
  # AG: Do not know the reason for multiplying base dvmt by 1000
  BaseLtVehDvmt_ <- L$Global$Model$BaseLtVehDvmt * 1000
  TruckBusDvmtParam_ <- data.frame(L$Global$Vmt)
  PropVmt_ <- TruckBusDvmtParam_[TruckBusDvmtParam_$Type=="TruckVmt", "PropVmt"]
  BaseTruckDvmt_ <- BaseLtVehDvmt_ / (1 - PropVmt_) * PropVmt_

  # Load data summaries
  #--------------------
  BaseIncomeByPlaceType_ <- IncomeByPlaceType_ <- L$Year$Bzone$UrbanIncome

  # Load base year income
  if(L$G$Year != L$G$BaseYear){
    BaseIncomeByPlaceType_ <- L$BaseYear$Bzone$UrbanIncome
  }

  # Calculate truck VMT by metropolitan area
  #-----------------------------------------
  # Calculate growth in total percapita income from base year
  # Calculate change in income
  BaseIncome_ <- sum(BaseIncomeByPlaceType_)
  FutureIncome_ <- sum(IncomeByPlaceType_)
  IncomeGrowth_ <- FutureIncome_/BaseIncome_
  # Calculate truck DVMT
  TruckDvmt_ <- IncomeGrowth_ * L$Global$Model$TruckVmtGrowthMultiplier * BaseTruckDvmt_
  rm(BaseLtVehDvmt_, TruckBusDvmtParam_, PropVmt_, BaseTruckDvmt_,
     BaseIncomeByPlaceType_, IncomeByPlaceType_,
     BaseIncome_, FutureIncome_, IncomeGrowth_)
  gc()



  #Return the results
  Out_ls <- initDataList()
  Out_ls$Year <- list(
    Marea = list(),
    Bzone = list(),
    Household = list(),
    Vehicle = list()
  )
  # Azone results
  Out_ls$Year$Marea <- list(
    TruckDvmt = TruckDvmt_
  )
  # Bzone results
  Out_ls$Year$Bzone <- list(
    Dvmt = DvmtPt_,
    EvDvmt = EvDvmtPt_,
    HcDvmt = HcDvmtPt_
  )
  # Household results
  Out_ls$Year$Household <- list(
    Dvmt = Hh_df$Dvmt,
    FuelGallons = Hh_df$FuelGallons,
    FuelCo2e = Hh_df$FuelCo2e,
    ElecKwh = Hh_df$ElecKwh,
    ElecCo2e = Hh_df$ElecCo2e,
    DailyParkingCost = Hh_df$DailyPkgCost,
    FutureCostPerMile = Hh_df$FutureCostPerMile
  )
  # Vehicle results
    Out_ls$Year$Vehicle <-list(
      Dvmt = as.numeric(Vehicles_df$Dvmt),
      EvDvmt = as.numeric(Vehicles_df$EvDvmt),
      HcDvmt = as.numeric(Vehicles_df$HcDvmt),
      MpKwh = as.numeric(Vehicles_df$Mpkwh),
      Powertrain = as.character(Vehicles_df$Powertrain)
    )
  # Global results
    Out_ls$Global$Fuel <- list(
      Fuel = as.character(FuelCo2Ft$Fuel),
      Intensity = as.numeric(FuelCo2Ft$Intensity)
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
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
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
