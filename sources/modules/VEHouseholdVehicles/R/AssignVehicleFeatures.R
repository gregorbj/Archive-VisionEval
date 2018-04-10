#========================
#AssignVehicleFeatures.R
#========================

# This module is a vehicle model from RPAT version.

# This module assigns household vehicle ownership, vehicle types, and ages to
# each household vehicle, based on household, land use,
# and transportation system characteristics. Vehicles are classified as either
# a passenger car (automobile) or a light truck (pickup trucks, sport utility
# vehicles, vans, etc.). A 'Vehicle' table is created which has a record for
# each household vehicle. The type and age of each vehicle owned or leased by
# households is assigned to this table along with the household ID (HhId)to
# enable this table to be joined with the household table.


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
VehOwnModels_ls <-
  list(
    Metro = list(),
    NonMetro = list()
  )

#Model metropolitan households
#--------------------------------

#Model number of vehicles of zero vehicle households
VehOwnModels_ls$Metro$ZeroVeh <- list(
  Drv1 =  "-0.683066027512409 * Intercept + -0.000110405079404259 * Income + 0.000109523364706169 * Htppopdn + -0.0362183493862117 * TranRevMiPC + 1.02639925083899 * Urban + 9.06402787257681e-10 * Income * Htppopdn + 9.50409353343535e-07 * Income * TranRevMiPC + 1.97250624441449e-05 * Income * Urban + 9.62725737852278e-07 * Htppopdn * TranRevMiPC + -5.50575031443288e-05 * Htppopdn * Urban + -0.000119303596393078 * Htppopdn * FwyLaneMiPC + 0.0576992095172837 * TranRevMiPC * FwyLaneMiPC",
  Drv2 = "-1.4293517976947 * Intercept + -6.79093838399447e-05 * Income + 1.41665886075373e-09 * Income * Htppopdn + -3.55383842559826e-05 * Income * OnlyElderly + 1.8466993140076e-06 * Htppopdn * TranRevMiPC",
  Drv3Plus = "-3.49217773065969 * Intercept + -4.90381809989654e-05 * Income + 9.71850941935639e-05 * Htppopdn + 7.30707905255008e-10 * Income * Htppopdn + 0.0755278977577806 * TranRevMiPC * FwyLaneMiPC"
)


#Model number of vehicles of non-zero vehicle households
VehOwnModels_ls$Metro$Lt1Veh <- list(
  Drv1 =  "",
  Drv2 =  "-0.262626375528877 * Intercept + -4.58681084909702e-05 * Income + 5.64785771813055e-05 * Htppopdn + 1.73603587364938 * OnlyElderly + 1.1917191888469e-09 * Income * Htppopdn + 3.34293693717104e-07 * Income * TranRevMiPC + 9.3557681020969e-06 * Income * OnlyElderly + -1.42790321639082e-06 * Htppopdn * TranRevMiPC + -4.75313220359081e-05 * Htppopdn * Urban + -2.71105219349876e-05 * Htppopdn * OnlyElderly + 0.0294466696415345 * TranRevMiPC * Urban + -0.0128985388647686 * OnlyElderly * TranRevMiPC + -1.3804854873109 * OnlyElderly * FwyLaneMiPC",
  Drv3Plus = "0.933669750357049 * Intercept + -1.83215625824184e-05 * Income + 5.20539935712135 * OnlyElderly + 1.66132852613514e-07 * Income * TranRevMiPC + 1.3111834256491e-05 * Income * Urban + -0.000120261225684946 * Income * OnlyElderly + -4.89311638774344e-05 * Urban * Htppopdn + 8.93280811716929e-05 * Htppopdn * FwyLaneMiPC + -0.689141713914993 * Urban * FwyLaneMiPC"
)

VehOwnModels_ls$Metro$Eq1Veh <- list(
  Drv1 =  "0.622159878280685 * Intercept + 0.0232811570547427 * TranRevMiPC + 1.13264996954536e-09 * Income * Htppopdn + -2.76056054149383e-07 * TranRevMiPC * Income + 7.20250709137754e-06 * Income * OnlyElderly + -1.66385909721084e-06 * TranRevMiPC * Htppopdn + -4.53660587597949e-05 * Htppopdn * Urban + 4.08259184719694e-05 * Htppopdn * FwyLaneMiPC + -0.00775538966573374 * TranRevMiPC * OnlyElderly",
  Drv2 =  "0.153082400390944 * Intercept + 5.78895700138807e-06 * Income + 4.02264718027797e-05 * Htppopdn + -0.381431776917538 * Urban + -0.554254682651229 * OnlyElderly + 2.40943544880577e-10 * Income * Htppopdn + 8.177337031634e-06 * Income * Urban + 7.11276258043345e-06 * Income * OnlyElderly + -1.79078088259691e-06 * Htppopdn * TranRevMiPC + -4.94241128932145e-05 * Htppopdn * Urban",
  Drv3Plus = "-1.27880272409382 * Intercept + 7.91127896877896e-06 * Income + -5.76306938765975e-05 * Htppopdn + 5.38360019771969e-10 * Income * Htppopdn + -0.020367512046482 * TranRevMiPC * Urban"
)

VehOwnModels_ls$Metro$Gt1Veh <- list(
  Drv1 =  "-1.74721412860086 * Intercept + 1.60836795971674e-05 * Income + -5.67320500238617e-05 * Htppopdn + -1.02035843794378 * OnlyElderly + -1.18456725053079e-06 * Htppopdn * TranRevMiPC + 4.53069297238042e-05 * Htppopdn * Urban + -0.945719667714273 * Urban * FwyLaneMiPC + 1.10732632310419 * OnlyElderly * FwyLaneMiPC",
  Drv2 =  "-1.96276543220691 * Intercept + 7.56898242720771e-06 * Income + 0.763451405045493 * FwyLaneMiPC + -0.664923337309273 * OnlyElderly + 5.78135381384015e-10 * Income * Htppopdn + -1.26532421138555e-06 * Htppopdn * TranRevMiPC + 2.86474240245699e-05 * Htppopdn * Urban + -0.000155933456154834 * FwyLaneMiPC * Htppopdn + -0.0227377982023876 * TranRevMiPC * Urban",
  Drv3Plus = "-1.00067958301458 * Intercept + -0.000301228344551957 * Htppopdn + -0.0128522840241981 * TranRevMiPC + 2.2049921814377e-09 * Htppopdn * Income"
)


#Model nonmetropolitan households
#--------------------------------
#Model number of vehicles of zero vehicle households
VehOwnModels_ls$NonMetro$ZeroVeh <- list(
  Drv1 =  "-0.764715628588422 * Intercept + -9.48827446956255e-05 * Income + 5.58814902852511e-05 * Htppopdn + 1.55132601403919e-09 * Income * Htppopdn + 3.4451381859651e-05 * Htppopdn * OnlyElderly",
  Drv2 = "-1.97205206585201 * Intercept + -8.50026389808778e-05 * Income + 9.49295735533233e-05 * Htppopdn + -0.750964480544973 * OnlyElderly + 6.90609260578997e-05 * Htppopdn * OnlyElderly",
  Drv3Plus = "-3.18298947122106 * Intercept + -4.99724157628643e-05 * Income + 0.000133417162883283 * Htppopdn"
)


#Model number of vehicles of non-zero vehicle households
VehOwnModels_ls$NonMetro$Lt1Veh <- list(
  Drv1 =  "",
  Drv2 =  "-0.413852820133151 * Intercept + -3.93168014848633e-05 * Income + 4.70561991697599e-05 * Htppopdn + 0.303576772835546 * OnlyElderly + 9.67749108418644e-10 * Income * Htppopdn + 1.53896829737995e-05 * Income * OnlyElderly",
  Drv3Plus = "0.481480595107626 * Intercept + -1.26210114521176e-05 * Income + 9.04571259805652e-05 * Htppopdn + 1.8315332036188 * OnlyElderly"
)

VehOwnModels_ls$NonMetro$Eq1Veh <- list(
  Drv1 =  "0.97339495471904 * Intercept + -9.71792328180977e-06 * Income + -2.84379049251932e-05 * Htppopdn + 0.254612141830117 * OnlyElderly + 1.49373110013838e-09 * Income * Htppopdn + 6.46030086496407e-06 * Income * OnlyElderly + -2.75839770071071e-05 * Htppopdn * OnlyElderly",
  Drv2 =  "0.244148864158161 * Intercept + 2.21438456787939e-06 * Income + -5.87127032906745e-05 * Htppopdn + -0.362435899095522 * OnlyElderly + 1.28716650265866e-09 * Income * Htppopdn + 7.83539837773637e-06 * Income * OnlyElderly + -5.57742722741945e-05 * Htppopdn * OnlyElderly",
  Drv3Plus = "-1.08784722177374 * Intercept + 7.31474110901786e-06 * Income + -5.23190355127079e-05 * Htppopdn"
)

VehOwnModels_ls$NonMetro$Gt1Veh <- list(
  Drv1 =  "-1.50974586088385 * Intercept + 1.97797131824946e-05 * Income + -0.000101101429017305 * Htppopdn + -0.502532799087163 * OnlyElderly + -8.9312428414856e-05 * Htppopdn * OnlyElderly",
  Drv2 =  "-1.2918177391397 * Intercept + 9.12997143307265e-06 * Income + -0.000127456736295507 * Htppopdn + -0.588810459958171 * OnlyElderly + -6.49054938175107e-05 * Htppopdn * OnlyElderly",
  Drv3Plus = "-1.89372144360687 * Intercept + 1.03322804417105e-05 * Income + -0.000128048150374047 * Htppopdn"
)



#Save the vehicle ownership model
#-----------------------------
#' Vehicle ownership model
#'
#' A list containing the vehicle ownership model equation and other information
#' needed to implement the vehicle ownership model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Metro}{a list containing four models for metropolitan areas: a Zero
#'   component model and three separate models for non-zero component}
#'   \item{NonMetro}{a list containing four models for non-metropolitan areas: a
#'   Zero component model and three separate models for non-zero component}
#' }
#' @source AssignVehicleFeatures.R script.
"VehOwnModels_ls"
devtools::use_data(VehOwnModels_ls, overwrite = TRUE)

# Model LtTrk Ownership
#-------------------------

# LtTrk ownership model
LtTruckModels_ls <- list(OwnModel = "-0.786596031795022 * Intercept + 5.0096283625617e-06 * Income + -0.151743860056697 * LogDen + -0.19343908057384 * Urban + 0.600876902111923 * Hhvehcnt + 0.287299051164498 * HhSize + 1.74355011513854e-06 * Income * HhSize + -3.79266132566609e-06 * Income * Hhvehcnt + -0.0862684834097631 * Hhvehcnt * HhSize")

#Save the light truck ownership model
#-----------------------------
#' Light truck ownership model
#'
#' A list containing the light truck ownership model equation.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{OwnModel}{The light truck ownership model}
#' }
#' @source AssignVehicleFeatures.R script.
"LtTruckModels_ls"
devtools::use_data(LtTruckModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleFeaturesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #---------------------------
  NewInpTable = items(
    item(
      TABLE = "Vehicles",
      GROUP = "Global"
    ),
    item(
      TABLE = "Gt1Prop",
      GROUP = "Global"
    ),
    item(
      TABLE = "Lt1Prop",
      GROUP = "Global"
    ),
    item(
      TABLE = "VehAgeCumProp",
      GROUP = "Global"
    ),
    item(
      TABLE = "VehAgeTypeProp",
      GROUP = "Global"
    ),
    item(
      TABLE = "VehicleMpgProp",
      GROUP = "Global"
    )
  ),
  NewSetTable = items(
    item(
      TABLE = "Vehicle",
      GROUP = "Year"
    )
  ),
  #---------------------------
  #Specify new tables to be created by Inp if any
  Inp = items(
    item(
      NAME = "Region",
      FILE = "region_lt1_veh_prop.csv",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Metro","NonMetro"),
      SIZE = 8,
      DESCRIPTION = "Lt1 region type"
    ),
    item(
      NAME = "DrvAgePop",
      FILE = "region_lt1_veh_prop.csv",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Lt1 driver age population"
    ),
    item(
      NAME = "NumVeh",
      FILE = "region_lt1_veh_prop.csv",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Lt1 number of vehicles"
    ),
    item(
      NAME = "Prob",
      FILE = "region_lt1_veh_prop.csv",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Distribution of number of vehicles when the number of
      vehicles in a household is less than driver population of the household"
    ),
    item(
      NAME = "Region",
      FILE = "region_gt1_veh_prop.csv",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Metro","NonMetro"),
      SIZE = 8,
      DESCRIPTION = "Gt1 region type"
    ),
    item(
      NAME = "DrvAgePop",
      FILE = "region_gt1_veh_prop.csv",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Gt1 driver age population"
    ),
    item(
      NAME = "NumVeh",
      FILE = "region_gt1_veh_prop.csv",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Gt1 number of vehicles"
    ),
    item(
      NAME = "Prob",
      FILE = "region_gt1_veh_prop.csv",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Distribution of number of vehicles when the number of
      vehicles in a household is greater than driver population of the household"
    ),
    item(
      NAME = "VehAge",
      FILE = "region_veh_cumprop_by_vehage.csv",
      TABLE = "VehAgeCumProp",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Age of vehicles"
    ),
    item(
      NAME = items(
        "AutoCumProp",
        "LtTruckCumProp"),
      FILE = "region_veh_cumprop_by_vehage.csv",
      TABLE = "VehAgeCumProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = items("cumulative probability distribution of Auto by age",
                          "cumulative probability distribution of LtTruck by age")
    ),
    item(
      NAME = "VehAge",
      FILE = "region_veh_prop_by_vehage_vehtype_inc.csv",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Age of vehicles"
    ),
    item(
      NAME = "IncGrp",
      FILE = "region_veh_prop_by_vehage_vehtype_inc.csv",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus"),
      SIZE = 9,
      DESCRIPTION = "Income Groups"
    ),
    item(
      NAME = "VehType",
      FILE = "region_veh_prop_by_vehage_vehtype_inc.csv",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = c("Auto", "LtTruck"),
      SIZE = 7,
      DESCRIPTION = "Types of Vehicle"
    ),
    item(
      NAME = "Prop",
      FILE = "region_veh_prop_by_vehage_vehtype_inc.csv",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Distribution of vehicles by age and type of vehicles, and the
      income group of the household"
    ),
    item(
      NAME = items(
        "AutoMpg",
        "LtTruckMpg",
        "TruckMpg",
        "BusMpg",
        "TrainMpg"
      ),
      FILE = "region_veh_mpg_by_year.csv",
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Miles per gallon for automobiles",
        "Miles per gallon for light trucks",
        "Miles per gallon for trucks",
        "Miles per gallon for buses",
        "Miles per gallon for trains")
    ),
    item(
      NAME = "ModelYear",
      FILE = "region_veh_mpg_by_year.csv",
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Years for which the efficiency of vehicle are measured."
    ),
    item(
      NAME = items(
        "Veh1Value",
        "Veh2Value",
        "Veh3Value",
        "Veh4Value",
        "Veh5PlusValue"
      ),
      FILE = "region_veh_mpg_dvmt_prop.csv",
      TABLE = "VehicleMpgProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "The proportion assignment of mileage for 1 vehicle housholds.",
        "The proportion assignment of mileage for 2 vehicle housholds.",
        "The proportion assignment of mileage for 3 vehicle housholds.",
        "The proportion assignment of mileage for 4 vehicle housholds.",
        "The proportion assignment of mileage for 5 plus vehicle housholds.")
    ),
    item(
      NAME = items(
        "Veh1Prob",
        "Veh2Prob",
        "Veh3Prob",
        "Veh4Prob",
        "Veh5PlusProb"
      ),
      FILE = "region_veh_mpg_dvmt_prop.csv",
      TABLE = "VehicleMpgProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      TOTAL = 1,
      DESCRIPTION = items(
        "The probability distribution of mileage assignment for 1 vehicle households.",
        "The probability distribution of mileage assignment for 2 vehicle households.",
        "The probability distribution of mileage assignment for 3 vehicle households.",
        "The probability distribution of mileage assignment for 4 vehicle households.",
        "The probability distribution of mileage assignment for 5 plus vehicle households.")
    )
  ),
  #---------------------------
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    # Marea variables
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
      NAME = items(
        "TranRevMiPC",
        "FwyLaneMiPC"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    # Bzone variables
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
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
    # Household variables
    item(
      NAME =
        items("HhId",
              "Azone",
              "Marea"),
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
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "Age0to14",
          "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBITED = "NA"
    ),
    item(
      NAME = "DrvLevels",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBITED = "NA",
      ISELEMENTOF = c("Drv1", "Drv2", "Drv3Plus")
    ),
    # Global variables
    item(
      NAME = "Region",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Metro","NonMetro"),
      SIZE = 8
    ),
    item(
      NAME = "DrvAgePop",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumVeh",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Prob",
      TABLE = "Lt1Prop",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Region",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Metro","NonMetro"),
      SIZE = 8
    ),
    item(
      NAME = "DrvAgePop",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumVeh",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Prob",
      TABLE = "Gt1Prop",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LtTruckProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehAge",
      TABLE = "VehAgeCumProp",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "AutoCumProp",
        "LtTruckCumProp"),
      TABLE = "VehAgeCumProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehAge",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "IncGrp",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus")
    ),
    item(
      NAME = "VehType",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = c("Auto", "LtTruck")
    ),
    item(
      NAME = "Prop",
      TABLE = "VehAgeTypeProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = items(
        "Veh1Value",
        "Veh2Value",
        "Veh3Value",
        "Veh4Value",
        "Veh5PlusValue"
      ),
      TABLE = "VehicleMpgProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Veh1Prob",
        "Veh2Prob",
        "Veh3Prob",
        "Veh4Prob",
        "Veh5PlusProb"
      ),
      TABLE = "VehicleMpgProp",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      TOTAL = 1)
  ),
  #---------------------------
  #Specify data to saved in the data store
  Set = items(
    # Vehicle variables
    item(
      NAME =
        items("HhId",
              "VehId",
              "Azone",
              "Marea"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID",
              "Unique vehicle ID",
              "Azone ID",
              "Marea ID")
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk"),
      SIZE = 5,
      DESCRIPTION = "Vehicle body type: Auto = automobile, LtTrk = light trucks (i.e. pickup, SUV, Van)"
    ),
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
      NAME = "Mileage",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "<0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Mileage of vehicles (automobiles and light truck)"
    ),
    item(
      NAME = "DvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = "Proportion of average household DVMT"
    ),
    # Household variables
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of automobiles and light trucks owned or leased by the household"
    ),
    item(
      NAME = items(
        "NumLtTrk",
        "NumAuto"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household",
        "Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignVehicleFeatures module
#'
#' A list containing specifications for the AssignVehicleFeatures module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignVehicleFeatures.R script.
"AssignVehicleFeaturesSpecifications"
devtools::use_data(AssignVehicleFeaturesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

# Function to predict vehicle ownership by region type to match
# the target proportion.
#--------------------------------------------------------
#' Predict vehicle ownership to match the target proportion for a specific
#' region type.
#'
#' \code{predictVehicleOwnership} Predict vehicle ownership to match the
#' target proportion for a specific region type.
#'
#' This function predicts the number of vehicles and the ratio of number of vehicles
#' to the driving age population (ownership ratio).
#'
#' @param Hh_df A household data frame consisting of household attributes.
#' @param ModelType A list of vehicle ownership models.
#' @param  VehProp A list of data frame consisting of distribution of number
#' of vehicles by driving age population for each region type.
#' @param Type A string indicating the region type ("Metro": Default, or "NonMetro")
#' @return A list containing number of vehicles and ownership ratio for each household
#' @export
#'
predictVehicleOwnership <- function( Hh_df, ModelType=VehOwnModels_ls, VehProp = NA, Type="Metro" ) {
  # Define vehicle categories
  VehicleCategory <- c( "Zero", "Lt1", "Eq1", "Gt1" )
  # Define driver levels
  DriverLevels <- c( "Drv1", "Drv2", "Drv3Plus" )
  # Check if proper type specified
  if( !( Type %in% c( "Metro", "NonMetro" ) ) ) {
    stop( "Type must be either 'Metro' or 'NonMetro'" )
  }
  # Extract model components for specified type
  ZeroVehModel <- ModelType[[Type]]$ZeroVeh
  Lt1VehModel <- ModelType[[Type]]$Lt1Veh
  Eq1VehModel <- ModelType[[Type]]$Eq1Veh
  Gt1VehModel <- ModelType[[Type]]$Gt1Veh
  VehProp_ <- VehProp[[Type]]
  # Define an intercept value
  Intercept <- 1
  # Apply the zero vehicle ownership model
  ZeroVehResults_ <- numeric( nrow( Hh_df ) )
  for( dl in DriverLevels ) {
    ZeroVehResults_[ Hh_df$DrvLevel == dl ] <-
      eval( parse( text=ZeroVehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
  }
  ZeroVehOdds_ <- exp( ZeroVehResults_ )
  ZeroVehProbs_ <- ZeroVehOdds_ / (1 + ZeroVehOdds_)
  # Apply the less than one vehicle ownership model
  # Note if DrvLevel == Drv1, then Lt1 can't be true
  Lt1VehResults_ <- numeric( nrow( Hh_df ) )
  Lt1VehResults_[ Hh_df$DrvLevel == "Drv1" ] <- NA
  for( dl in DriverLevels ) {
    if(Lt1VehModel[[dl]]!=""){
      Lt1VehResults_[ Hh_df$DrvLevel == dl ] <-
        eval( parse( text=Lt1VehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
    }
  }
  Lt1VehOdds_ <- exp( Lt1VehResults_ )
  Lt1VehProbs_ <- Lt1VehOdds_ / (1 + Lt1VehOdds_)
  Lt1VehProbs_[ Hh_df$DrvLevel == "Drv1" ] <- 0
  # Apply the equal to one vehicle ownership model
  Eq1VehResults_ <- numeric( nrow( Hh_df ) )
  for( dl in DriverLevels ) {
    Eq1VehResults_[ Hh_df$DrvLevel == dl ] <-
      eval( parse( text=Eq1VehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
  }
  Eq1VehOdds_ <- exp( Eq1VehResults_ )
  Eq1VehProbs_ <- Eq1VehOdds_ / (1 + Eq1VehOdds_)
  # Apply the greater than one vehicle ownership model
  Gt1VehResults_ <- numeric( nrow( Hh_df ) )
  for( dl in DriverLevels ) {
    Gt1VehResults_[ Hh_df$DrvLevel == dl ] <-
      eval( parse( text=Gt1VehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
  }
  Gt1VehOdds_ <- exp( Gt1VehResults_ )
  Gt1VehProbs_ <- Gt1VehOdds_ / (1 + Gt1VehOdds_)
  # Combine probability vectors into one matrix
  VehProbs2d <- cbind( ZeroVehProbs_, Lt1VehProbs_, Eq1VehProbs_, Gt1VehProbs_ )
  # Calculate a vehicle choice
  Hh_df$VehChoice <- VehicleCategory[ apply( VehProbs2d, 1, function(x) {
    sample( 1:4, 1, replace=FALSE, prob=x )
  } ) ]
  # Calculate number of vehicles
  NumVeh_ <- numeric( nrow( Hh_df ) )

  NumVeh_[Hh_df$VehChoice == "Zero"] <- 0
  NumVeh_[Hh_df$VehChoice == "Eq1"] <- Hh_df$DrvAgePop[Hh_df$VehChoice == "Eq1"]

  ## Calculate number of vehicles ofr Lt1
  VehChoice <- "Lt1"
  VehProbsNdNv <- VehProp_[[VehChoice]]

  ### Calculate if the driver age population is found in the table
  CheckCondition1 <- Hh_df$VehChoice == "Lt1"
  CheckCondition2 <- (Hh_df$VehChoice == "Lt1") & (as.character(Hh_df$DrvAgePop) %in% as.character(VehProbsNdNv$Lt1DrvAgePop))

  # Modify the sampling function
  customSample <- function(x, ...){
    if(length(x) < 2){
      return(x)
    } else {
      return(sample(x,...))
    }
  }


  if(any(CheckCondition1)){
    NumVeh_[CheckCondition1] <- round(Hh_df$DrvAgePop[CheckCondition1]/2)
  }
  if(any(CheckCondition2)){
    NumVeh_[CheckCondition2] <- sapply(Hh_df$DrvAgePop[CheckCondition2], function(x) customSample(VehProbsNdNv$Lt1NumVeh[VehProbsNdNv$Lt1DrvAgePop == x], 1, prob = VehProbsNdNv$Lt1Prob[VehProbsNdNv$Lt1DrvAgePop==x]))
  }

  ## Calculate number of vehicles ofr Gt1
  VehChoice <- "Gt1"
  VehProbsNdNv <- VehProp_[[VehChoice]]

  ### Calculate if the driver age population is found in the table
  CheckCondition1 <- Hh_df$VehChoice == "Gt1"
  CheckCondition2 <- (Hh_df$VehChoice == "Gt1") & (as.character(Hh_df$DrvAgePop) %in% as.character(VehProbsNdNv$Gt1DrvAgePop))


  if(any(CheckCondition1)){
    NumVeh_[CheckCondition1] <- round(Hh_df$DrvAgePop[CheckCondition1]/2)
  }
  if(any(CheckCondition2)){
    NumVeh_[CheckCondition2] <- sapply(Hh_df$DrvAgePop[CheckCondition2], function(x) customSample(VehProbsNdNv$Gt1NumVeh[VehProbsNdNv$Gt1DrvAgePop == x], 1, prob = VehProbsNdNv$Gt1Prob[VehProbsNdNv$Gt1DrvAgePop==x]))
  }

  # Calculate vehicle ownership ratio
  VehRatio_ <- NumVeh_ / Hh_df$DrvAgePop
  # Return results in a list
  list( VehRatio = as.numeric(VehRatio_), NumVeh = as.integer(NumVeh_) )
}

# Function to predict vehicle type (auto or light truck) for household vehicles
#-----------------------------------------------------------------------------
#' Predict vehicle type (automobile or light truck) for household vehicles.
#'
#' \code{predictVehicleOwnership} Predict vehicle type (automobile or light truck)
#' for household vehicles.
#'
#' This function predict vehicle type (automobile or light truck)
#' for household vehicles based on characterisitics of the household, the place where
#' the household resides, the number of vehicles it owns, and areawide targets for
#' light truck ownership.
#'
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param ModelType A list of light truck ownership model.
#' @param  TruckProp A numeric indicating the target proportion for light truck
#' ownership.
#' @return A list containing vehicle types for each household.
#' @export
#'
predictLtTruckOwn <- function( Hh_df, ModelType=LtTruckModels_ls, TruckProp=NA) {

  # Setup values
  OwnModel <- ModelType$OwnModel
  Hh_df$LogDen <- log( Hh_df$Htppopdn )
  TargetTruckProp <- TruckProp
  LtTruckFactorLo <- -100
  LtTruckFactorMd <- 0
  LtTruckFactorHi <- 100
  Itr <- 0
  Intercept <- 1

  # Function to test convergence
  notConverged <- function( TruckProp, EstTruckProp ) {
    Diff <- abs( TruckProp - EstTruckProp )
    return(Diff > 0.0001)
  }

  # Function to calculate probabilities
  calcVehProbs <- function( Factor ) {
    LtTruckResults_ <- Factor + eval( parse( text=OwnModel ), envir=Hh_df )
    LtTruckOdds_ <- exp( LtTruckResults_ )
    return(LtTruckOdds_ / (1 + LtTruckOdds_))
  }

  # Calculate starting proportion
  LtTruckProbsMd_ <- calcVehProbs( LtTruckFactorMd )
  EstTruckProp <- sum( Hh_df$Hhvehcnt * LtTruckProbsMd_ ) / sum( Hh_df$Hhvehcnt )
  # Continue is there is a target truck proportion to be achieved
  if( !is.na( TruckProp ) ){
    while( notConverged( TruckProp, EstTruckProp ) ) {
      LtTruckProbsLo_ <- calcVehProbs( LtTruckFactorLo )
      LtTruckProbsMd_ <- calcVehProbs( LtTruckFactorMd )
      LtTruckProbsHi_ <- calcVehProbs( LtTruckFactorHi )
      EstTruckPropLo <- sum( Hh_df$Hhvehcnt * LtTruckProbsLo_ ) /
        sum( Hh_df$Hhvehcnt )
      EstTruckPropMd <- sum( Hh_df$Hhvehcnt * LtTruckProbsMd_ ) /
        sum( Hh_df$Hhvehcnt )
      EstTruckPropHi <- sum( Hh_df$Hhvehcnt * LtTruckProbsHi_ ) /
        sum( Hh_df$Hhvehcnt )
      if( TruckProp < EstTruckPropMd ) {
        LtTruckFactorHi <- LtTruckFactorMd
        LtTruckFactorMd <- mean( c( LtTruckFactorHi, LtTruckFactorLo ) )
      }
      if( TruckProp > EstTruckPropMd ) {
        LtTruckFactorLo <- LtTruckFactorMd
        LtTruckFactorMd <- mean( c( LtTruckFactorLo, LtTruckFactorHi ) )
      }
      EstTruckProp <- EstTruckPropMd
      rm( EstTruckPropLo, EstTruckPropMd, EstTruckPropHi )
      if( Itr > 100 ) break
      Itr <- Itr + 1
    }
  }

  # Assign vehicles by type to each household
  VehType_ <- apply( cbind( Hh_df$Hhvehcnt, LtTruckProbsMd_ ), 1, function(x) {
    NumVeh <- x[1]
    Prob <- x[2]
    sample( c( "LtTruck", "Auto" ), NumVeh, replace=TRUE,
            prob=c( Prob, 1-Prob ) )
  } )
  # Return the result
  return(VehType_)
}

#Function which calculates vehicle type distributions by income group
#-------------------------------------------------------------------
#' Calculate vehicle type distributions by income group.
#'
#' \code{calcVehPropByIncome} Calculates vehicle type distributions by
#' household income group.
#'
#' This function calculates vehicle type distributions by household
#' income group. It takes the the number of vehicles, vehicle types, and
#' income groups of each household and calculates the marginal distribution
#' of the vehicle types.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @return A data frame containing the distribution of vehicle types by income
#' groups.
#' @import reshape2
#' @export
#'
calcVehPropByIncome <- function( Hh_df ) {
  VehTabByIg <- table( rep( Hh_df$IncGrp, Hh_df$Hhvehcnt ), unlist( Hh_df$VehType ) )
  VehIgPropByIg <- sweep( VehTabByIg, 2, colSums( VehTabByIg ), "/" )
  VehIgPropByIg <- as.data.frame(VehIgPropByIg)
  VehIgPropByIg <- reshape2::dcast(VehIgPropByIg, Var1~Var2, value.var = "Freq", fill = 0)
  colnames(VehIgPropByIg)[1] <- "IncGrp"
  return(VehIgPropByIg)
}

#Function to adjust cumulative age distribution to match target ratio
#-------------------------------------------------------------------
#' Adjust cumulative age distribution to match target ratio
#'
#' \code{adjAgeDistribution} Adjusts a cumulative age distribution to match a
#' target ratio.
#'
#' This function adjusts a cumulative age distribution to match a target ratio.
#' The function returns the adjusted cumulative age distribution and the
#' corresponding age distribution.
#'
#' @param CumDist A named numeric vector where the names are vehicle ages and
#' the values are the proportion of vehicles that age or younger. The names must
#' be an ordered sequence from 0 to 32.
#' @param AdjRatio A number that is the target ratio value.
#' @return A numeric vector of adjusted distribution.
#' @import stats
#' @export
#'
adjAgeDistribution <- function( CumDist, AdjRatio ) {
  # Calculate the length of the original distribution
  DistLength <- length( CumDist )
  # If 95th percentile age increases, add more ages on the right side of the distribution
  # to enable the distribution to be expanded in that direction
  if( AdjRatio > 1 ) CumDist <- c( CumDist, rep(1,8) )
  # Calculate vehicle ages for the distribution
  Ages_ <- 0:( length( CumDist ) - 1 )
  MaxAge <- Ages_[ length( Ages_ ) ]
  # Find decimal year which is equal to 95th percentile
  LowerIndex <- max( which( CumDist < 0.95 ) )
  UpperIndex <- LowerIndex + 1
  LowerValue <- CumDist[ LowerIndex ]
  UpperValue <- CumDist[ UpperIndex ]
  YearFraction <- ( 0.95 - LowerValue ) / ( UpperValue - LowerValue )
  Year95 <- Ages_[ LowerIndex ] + YearFraction
  # Calculate the adjustment in years
  Target95 <- Year95 * AdjRatio
  LowerShiftRatio <- Target95 / Year95
  UpperShiftRatio <- ( MaxAge - Target95 ) / ( MaxAge - Year95 )
  LowerAdjAges_ <- Ages_[ 0:LowerIndex ] * LowerShiftRatio
  UpperAgeSeq_ <- ( Ages_[ UpperIndex ]:MaxAge )
  UpperAdjAges_ <- MaxAge - rev( UpperAgeSeq_ - UpperAgeSeq_[1] ) * UpperShiftRatio
  AdjAges_ <- c( LowerAdjAges_, UpperAdjAges_ )
  # Calculate new cumulative proportions
  AdjCumDist <- CumDist
  for( i in 2:( length( AdjCumDist ) - 1 ) ) {
    LowerIndex <- max( which( AdjAges_ < Ages_[i] ) )
    UpperIndex <- LowerIndex + 1
    AdjProp <- ( Ages_[i] - AdjAges_[ LowerIndex ] ) /
      ( AdjAges_[ UpperIndex ] - AdjAges_[ LowerIndex ] )
    LowerValue <- CumDist[ LowerIndex ]
    UpperValue <- CumDist[ UpperIndex ]
    AdjCumDist[i] <- LowerValue + AdjProp * ( UpperValue - LowerValue )
  }
  # Smooth out the cumulative distribution
  LowIdx <- 1
  HiIdx <- length( AdjCumDist )
  SmoothTransition_ <- smooth.spline( LowIdx:HiIdx, AdjCumDist[LowIdx:HiIdx], df=4 )$y
  AdjCumDist[ LowIdx:HiIdx ] <- SmoothTransition_
  # Convert cumulative distribution to regular distribution
  AdjDist_ <- AdjCumDist
  for( i in length( AdjDist_ ):2 ) {
    AdjDist_[i] <- AdjDist_[i] - AdjDist_[i-1]
  }
  # Truncate to original distribution length
  AdjDist_ <- AdjDist_[ 1:DistLength ]
  # Adjust so that sum of distribution exactly equals 1
  AdjDist_ <- AdjDist_ * ( 1 / sum( AdjDist_ ) )
  # Return result
  return(AdjDist_)
}

#Function which calculates vehicle age distributions by income group
#-------------------------------------------------------------------
#' Calculate vehicle age distributions by income group.
#'
#' \code{calcVehAgePropByInc} Calculates vehicle age distributions by
#' household income group.
#'
#' This function calculates vehicle age distributions by household income group.
#' It takes marginal distributions of vehicles by age and households by income
#' group along with a data frame of the joint probability distribution of
#' vehicles by age and income group, and then uses iterative proportional
#' fitting to adjust the joint probabilities to match the margins. The
#' probabilities by income group are calculated from the fitted joint
#' probability matrix. The age margin is the proportional distribution of
#' vehicles by age calculated by adjusting the cumulative age distribution
#' for autos or light trucks to match a target mean age. The income
#' margin is the proportional distribution of vehicles by household income group
#' ($0-20K, $20K-40K, $40K-60K, $60K-80K, $80K-100K, $100K or more) calculated
#' from the modeled household values.
#'
#' @param VehAgIgProp A numeric vector of joint probabilities of vehicle by
#' age and income group.
#' @param AgeGrp A numeric vector indicating the vehicle ages.
#' @param  AgeMargin A named numeric vector indicating the marginal distribution
#' of vehicle by age.
#' @param IncGrp A character vector indicating the income groups.
#' @param IncMargin A named numeric vecotr indicating the marginal distribution
#' of vehicle by income groups.
#' @param MaxIter A numeric indicating maximum number of iterations. (Default: 100)
#' @param Closure A numeric indicating the tolerance level for conversion. (Default: 1e-3)
#' @return A numeric vector of joint probabilities of vehicle by age and income group.
#' @export
#'
calcVehAgePropByInc <- function(VehAgIgProp, AgeGrp, AgeMargin, IncGrp, IncMargin, MaxIter=100, Closure=0.001){
  # Replace margin values of zero with 0.001
  if( any( AgeMargin ==0 ) ){
    AgeMargin[ AgeMargin ==0 ] <- 0.0001
  }
  if( any( IncMargin ==0 ) ){
    IncMargin[ IncMargin ==0 ] <- 0.0001
  }
  # Make sure sum of each margin is equal to 1
  AgeMargin <- AgeMargin * ( 1 / sum( AgeMargin ) )
  IncMargin <- IncMargin * ( 1 / sum( IncMargin ) )
  # Set initial values
  Iter <- 0
  MarginChecks <- c( 1, 1 )
  # Iteratively proportion matrix until closure or iteration criteria are met
  while( ( any( MarginChecks > Closure ) ) & ( Iter < MaxIter ) ) {
    AgeSums <- rowsum( VehAgIgProp, group = AgeGrp )[,1]
    AgeCoeff <- AgeMargin / AgeSums
    VehAgIgProp <- AgeCoeff[as.character(AgeGrp)]*VehAgIgProp
    MarginChecks[1] <- sum(abs( 1 - AgeCoeff ))
    IncSums <- rowsum( VehAgIgProp, group = IncGrp )[,1]
    IncCoeff <- IncMargin / IncSums
    VehAgIgProp <- IncCoeff[as.character(IncGrp)]*VehAgIgProp
    MarginChecks[2] <- sum(abs( 1 - IncCoeff ))
    Iter <- Iter + 1
  }
  # Compute proportions for each income group
  IncSums <- rowsum(VehAgIgProp, group = IncGrp)[,1]
  VehAgIgProp <- VehAgIgProp/IncSums[as.character(IncGrp)]
  return(VehAgIgProp)
}

# Function to calculate vehicle type and age for each household
#--------------------------------------------------------
#' Calculate vehicle type and age for each household.
#'
#' \code{calcVehicleAges} Calculates vehicle type and age for each household.
#'
#' This function calculates the vehicle type and age for households. The function
#' uses characteristics of houshold and target marginal proportions to calculate
#' vehicle type and age.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param VProp A list consisting of a cumulative distribution of vehicle age by
#' vehicle type and a joint distribution of vehicle age, type and income group of
#' the household.
#' @param AdjRatio A number that is the target ratio value.
#' @return A list containing the vehicle types and ages for each household.
#' @import reshape2
#' @export
#'
calcVehicleAges <- function(Hh_df, VProp=NULL, AdjRatio = c(Auto = 1, LtTruck = 1)){

  # Compute the vehicle age distribution by income and type
  #--------------------------------------------------------
  # Calculate the distribution of vehicle types by income
  VehPropByInc <- calcVehPropByIncome( Hh_df )
  # Compute the age margin
  AgeType <- colnames( VProp$VehCumPropByAge[,-1] )
  VehPropByAge <- VProp$VehCumPropByAge
  # Adjust the age distribution
  AdjVehProp <- lapply(AgeType, function(x) adjAgeDistribution(VehPropByAge[, x],
                                                                  AdjRatio = AdjRatio[x]))
  names(AdjVehProp) <- AgeType
  VehPropByAge[,AgeType] <- data.frame(AdjVehProp)
  # Compute the age distribution by income and type
  VehPropByAgeIncGrpType <- VProp$VehPropByAgeIncGrpType

  VehPropByAgeIncGrpType <- reshape2::dcast(VehPropByAgeIncGrpType, ...~VehType, value.var = "Prop", fill = 0)

  VehPropByAgeInc_ <- do.call(cbind, lapply(AgeType, function(x) calcVehAgePropByInc(VehAgIgProp = VehPropByAgeIncGrpType[,x], AgeGrp = VehPropByAgeIncGrpType[,"VehAge"], AgeMargin = VehPropByAge[,x], IncGrp = VehPropByAgeIncGrpType[,"IncGrp"], IncMargin = VehPropByInc[,x])))
  VehPropByAgeIncGrpType[,c("Auto","LtTruck")] <- VehPropByAgeInc_


  # Apply ages to vehicles
  #-----------------------
  # Identify the number of autos and light trucks by income group
  NumLtTrucks_ <- sapply( Hh_df$VehType, function(x) sum( x == "LtTruck" ) )
  NumAutos_ <- Hh_df$Hhvehcnt - NumLtTrucks_
  NumLtTruckSamplesByInc <- tapply( NumLtTrucks_, Hh_df$IncGrp, sum )
  NumAutoSamplesByInc <- tapply( NumAutos_, Hh_df$IncGrp, sum )
  # Create age samples for light trucks by income group
  LtTruckSamplesByInc <- lapply(levels(VehPropByAgeIncGrpType$IncGrp),
                                function(x) sample(VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "VehAge"], NumLtTruckSamplesByInc[x], replace = TRUE, prob = VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "LtTruck"]))

  names(LtTruckSamplesByInc) <- levels(VehPropByAgeIncGrpType$IncGrp)
  # Create age samples for autos by income group
  AutoSamplesByInc <- lapply(levels(VehPropByAgeIncGrpType$IncGrp),
                             function(x) sample(VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "VehAge"], NumAutoSamplesByInc[x], replace = TRUE, prob = VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "Auto"]))

  names(AutoSamplesByInc) <- levels(VehPropByAgeIncGrpType$IncGrp)
  # Associate light truck and auto ages with each household
  LtTruckAges_ <- as.list( rep( NA, nrow( Hh_df ) ) )
  for( ig in levels(VehPropByAgeIncGrpType$IncGrp) ) {
    IsIncGrp_ <- Hh_df$IncGrp == ig
    HasLtTrucks_ <- NumLtTrucks_ != 0
    GetsAges_ <- IsIncGrp_ & HasLtTrucks_
    LtTruckAges_[ GetsAges_ ] <- split( LtTruckSamplesByInc[[ig]],
                                        rep( 1:sum( GetsAges_ ), NumLtTrucks_[ GetsAges_ ] ) )
  }
  # Associate auto ages with each household
  AutoAges_ <- as.list( rep( NA, nrow( Hh_df ) ) )
  for( ig in levels(VehPropByAgeIncGrpType$IncGrp) ) {
    IsIncGrp_ <- Hh_df$IncGrp == ig
    HasAuto_ <- NumAutos_ != 0
    GetsAges_ <- IsIncGrp_ & HasAuto_
    AutoAges_[ GetsAges_ ] <- split( AutoSamplesByInc[[ig]],
                                     rep( 1:sum( GetsAges_ ), NumAutos_[ GetsAges_ ] ) )
  }

  # Return the result
  #------------------
  # Combine auto and light truck lists
  VehAge_ <- mapply( c, LtTruckAges_, AutoAges_ )
  VehAge_ <- lapply( VehAge_, function(x) x[ !is.na(x) ] )
  # Make list of vehicle types correspond to ages list
  VehType_ <- apply( cbind( NumLtTrucks_, NumAutos_ ), 1, function(x) {
    rep( c( "LtTruck", "Auto" ), x ) } )
  # Return result as a list
  return(list( VehType = VehType_, VehAge = VehAge_ ))
}

# Function to assign mileage to vehicles in a household
#--------------------------------------------------------
#' Assignes mileage to vehicles in a household
#'
#' \code{assignFuelEconomy} Assignes mileage to vehicles in a household.
#'
#' This function assigns mileage to vehicles in a household based on type
#' age of the vehicles.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param VehMpgYr A data frame of mileage of vehicles by type and year.
#' @param CurrentYear A integer indicating the current year.
#' @return A numeric vector that indicates the mileage of vehicles.
#' @export
#'
assignFuelEconomy <- function( Hh_df, VehMpgYr=NULL, CurrentYear ) {
  # Calculate the sequence of years to use to index fleet average MPG
  if(is.null(VehMpgYr)){
    stop("The function needs mpg data on vehicles.")
  }
  Years <- as.character(VehMpgYr[,"Year"])
  rownames(VehMpgYr) <- Years
  StartYear <- as.numeric( CurrentYear ) - 32
  if( StartYear < 1975 ) {
    YrSeq_ <- Years[ 1:which( Years == CurrentYear ) ]
    NumMissingYr <- 1975 - StartYear
    YrSeq_ <- c( rep( "1975", NumMissingYr ), YrSeq_ )
  } else {
    YrSeq_ <- Years[ which( Years == StartYear ):which( Years == CurrentYear ) ]
  }
  # Calculate auto and light truck MPG by vehicle age
  VehMpgByAge <- VehMpgYr[rev(YrSeq_),]
  rownames( VehMpgByAge ) <- as.character( 0:32 )
  # Combine into vector and assign fuel economy to household vehicles
  VehType_ <- unlist(Hh_df$VehType)
  VehAge_ <- as.character(unlist(Hh_df$VehAge))
  VehMpg_ <- numeric(length(VehType_))
  VehMpg_[VehType_ == "Auto"] <- VehMpgByAge[VehAge_[VehType_ == "Auto"], "Auto"]
  VehMpg_[VehType_ == "LtTruck"] <- VehMpgByAge[VehAge_[VehType_ == "LtTruck"], "LtTruck"]
  # Split back into a list
  ListIndex_ <- rep( 1:nrow(Hh_df), Hh_df$Hhvehcnt )
  VehMpg_ <- split( VehMpg_, ListIndex_ )
  # Return the result
  return(VehMpg_)
}

# Function to assign VMT proportion to household vehicles
#--------------------------------------------------------
#' Assign VMT proportion to household vehicles.
#'
#' \code{apportionDvmt} Assign VMT proportion to household vehicles.
#'
#' This function assigns VMT proportions to household vehicles based on the
#' number of vehicles in the household and the probability distribution of proportion of
#' miles traveled by those vehicles.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param DvmtProp A data frame of distribution of VMT proportion by number of
#' vehicles in a household.
#' @return A list containing number of vehicles and ownership ratio for each household
#' @export
#'
apportionDvmt <- function( Hh_df, DvmtProp=NULL ) {
  if(is.null(DvmtProp)){
    stop("Probability distribution of mileage proportion assignment
         for n vehicle household is required.")
  }
  # Create a list that stores the output of vehicle DVMT proportions
  VehDvmtPropOutput_ <- lapply( 1:nrow( Hh_df ), function(x) numeric(0) )
  # Nc is a vector of the classes of number of household vehicles
  Nc <- sort( unique( Hh_df$Hhvehcnt ) )
  # Iterate through each number class, get the subset of the data
  # Calculate the vehicle proportions, assign the results to the VehDvmtPropOutput_
  for( nc in Nc ) {
    # Make a subset of the input data
    DataSub_ <- Hh_df[ Hh_df$Hhvehcnt == nc, ]
    # Create a list to store the results for this subset
    VehDvmtProp_ <- lapply( seq_along(DataSub_$HhId), function(x) numeric(nc) )
    # Simplified process where there are only 1 or 2 vehicles in the household
    if( nc <= 2 ) {
      # If there is only one vehicle, then the DVMT proportion is 1
      if( nc == 1 ) {
        VehDvmtProp_ <- lapply( VehDvmtProp_, function(x) x <- 1 )
      } else {
        # If there are 2 vehicles, then sample to get 1st proportion
        # the 2nd proportion is 1 minus the 1st proportion
        # Extract the 2Veh matrix of DvmtProp_
        DvmtProp2d <- DvmtProp[,c("Veh2Value","Veh2Prob")]
        # Calculate the number of samples to be made
        NumSamples <- nrow(DataSub_)
        # Create a matrix to put the results into
        VehDvmtProp2d <- matrix( 0, nrow=NumSamples, ncol=nc )
        # Sample from the probabilities to get the 1st set of values
        VehDvmtProp2d[,1] <- sample( DvmtProp2d[,"Veh2Value"], NumSamples,
                                      replace=TRUE, prob=DvmtProp2d[,"Veh2Prob"] )
        # Calculate 2nd set of values
        VehDvmtProp2d[,2] <- 1 - VehDvmtProp2d[,1]
        # Put the values into the list
        for( i in 1:NumSamples ) VehDvmtProp_[[i]] <- VehDvmtProp2d[i,]
      }
      # General process for 3 or more vehicles in households
    } else {
      # Identify the class name to use to extract the appropriate proportion
      # distribution
      if( nc >= 5 ) {
        VehClassName <- "Veh5Plus"
      } else {
        VehClassName <- paste("Veh",  nc, sep="" )
      }
      # Extract the appropriate proportion distribution from DvmtProp_
      Var_ <- paste0(VehClassName, c("Value","Prob"))
      DvmtProp2d <- DvmtProp[, Var_]
      # Calculate the number of samples to be made
      NumSamples <- nrow(DataSub_)
      # Create a matrix to put the results into
      VehDvmtProp2d <- matrix( 0, nrow=NumSamples, ncol=nc )
      # Sample from probabilities to create values for 1st vehicle
      VehDvmtProp2d[,1] <- sample( DvmtProp2d[,Var_[1]], NumSamples, replace=TRUE,
                                    prob=DvmtProp2d[,Var_[2]] )
      # Iterate through each next vehicle to calculate DVMT proportion
      for( i in 2:nc ) {
        # Iterate through each row of the matrix
        VehDvmtProp2d[,i] <- apply( VehDvmtProp2d, 1, function(x) {
          # The remaining proportion can't be more than 1 minus the
          # sum of the existing proportions
          # Round to make sure that logic checks are correct
          RemProb <- round( 1 - sum(x), 2 )
          # If this is the last row, then the result has to be RemProb
          if( i == nc ) {
            Result <- RemProb
            # Otherwise calculate remaining probability
          } else {
            # If the RemProb is 0 then the result must be 0
            if( RemProb == 0 ) {
              Result <- 0
            } else {
              # If the RemProb is 0.05 then the result must be 0.05
              if( RemProb == 0.05 ) {
                Result <- 0.05
                # Otherwise sample from a limited sample frame
              } else {
                # Identify limited sample values and probabilities
                IsPossProb_ <- DvmtProp2d[,Var_[1]] <= RemProb
                Values_ <- DvmtProp2d[ IsPossProb_, Var_[1] ]
                Prob_ <- DvmtProp2d[ IsPossProb_, Var_[2] ]
                Result <- sample( Values_, 1, replace=TRUE, Prob_ )
              }
            }
          }
          # Return the result for the row which is put into the matrix column
          Result } )
      }
      # Put the results of the matrix into the the list for the vehicle number class
      for( i in 1:NumSamples ) VehDvmtProp_[[i]] <- VehDvmtProp2d[i,]
    }
    # Put the values into the correct locations in the overall output list
    VehDvmtPropOutput_[ Hh_df$Hhvehcnt == nc ] <- VehDvmtProp_
  }
  # Return the overall output list
  return(VehDvmtPropOutput_)
}

#This function generates various .

#Main module function that calculates vehicle features
#------------------------------------------------------
#' Create vehicle table and populate with vehicle type, age, and mileage records.
#'
#' \code{AssignVehicleFeatures} create vehicle table and populate with
#' vehicle type, age, and mileage records.
#'
#' This function creates the 'Vehicle' table in the datastore and populates it
#' with records of vehicle types, ages, mileage, and mileage proportions
#' along with household IDs.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @import stats
#' @export
AssignVehicleFeatures <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Calculate number of households
  NumHh <- length(L$Year$Household[[1]])

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$OnlyElderly <- as.numeric(Hh_df$HhSize == Hh_df$Age65Plus)
  # Hh_df$LowInc <- as.numeric(Hh_df$Income <= 20000)
  # Hh_df$LogIncome <- log(Hh_df$Income)
  # Classify households according to income group
  MaxInc <- max( Hh_df$Income )
  IncBreaks_ <- c( 0, 20000, 40000, 60000, 80000, 100000, MaxInc )
  Ig <- c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus")
  names(IncBreaks_) <- Ig
  Hh_df$IncGrp <- cut( Hh_df$Income, breaks=IncBreaks_, labels=Ig, include.lowest=TRUE )


  ######AG to CS/BS Average Density
  ###AG to CS/BS should this be a calculated average for the region?
  Hh_df$Htppopdn <- 500
  ###AG to CS/BS should this be 0 for rural? Or are we just using an average for both density and this var and then adjusting using 5D values?
  Hh_df$Urban <- 1
  # Calculate the natural log of density
  Hh_df$LogDen <- log( Hh_df$Htppopdn )
  # Density_ <- L$Year$Bzone$D1B[match(L$Year$Household$HhPlaceTypes, L$Year$Bzone$Bzone)]
  # Hh_df$LogDensity <- log(Density_)
  FwyLaneMiPC_Bz <- L$Year$Marea$FwyLaneMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]*1000 # To match RPAT numbers
  Hh_df$FwyLaneMiPC <- FwyLaneMiPC_Bz[match(L$Year$Household$HhPlaceTypes, L$Year$Bzone$Bzone)]
  TranRevMiPC_Bz <- L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$TranRevMiPC <- TranRevMiPC_Bz[match(L$Year$Household$HhPlaceTypes, L$Year$Bzone$Bzone)]

  Lt1VehProp <- data.frame(L$Global$Lt1Prop)
  Gt1VehProp <- data.frame(L$Global$Gt1Prop)

  # Gather vehicle proportions for Lt1 and Gt1
  VehProp <- list(
    Metro = list(),
    NonMetro = list()
  )

  VehProp$Metro$Lt1 <- Lt1VehProp[Lt1VehProp$Region == "Metro", -1]
  VehProp$Metro$Gt1 <- Gt1VehProp[Gt1VehProp$Region == "Metro", -1]
  VehProp$NonMetro$Lt1 <- Lt1VehProp[Lt1VehProp$Region == "NonMetro", -1]
  VehProp$NonMetro$Gt1 <- Gt1VehProp[Gt1VehProp$Region == "NonMetro", -1]

  # Gather vehicle proportions for vehicle types, income groups, etc..
  VehPropByGroups <- list()
  VehPropByGroups$VehCumPropByAge <- data.frame(list(VehAge = L$Global$VehAgeCumProp$VehAge,
                                                     Auto = L$Global$VehAgeCumProp$AutoCumProp,
                                                     LtTruck = L$Global$VehAgeCumProp$LtTruckCumProp))
  VehPropByGroups$VehPropByAgeIncGrpType <- data.frame(list(VehAge = L$Global$VehAgeTypeProp$VehAge,
                                                            IncGrp = L$Global$VehAgeTypeProp$IncGrp,
                                                            VehType = L$Global$VehAgeTypeProp$VehType,
                                                            Prop = L$Global$VehAgeTypeProp$Prop))
  # Relevel the income groups
  VehPropByGroups$VehPropByAgeIncGrpType$IncGrp <- reorder(VehPropByGroups$VehPropByAgeIncGrpType$IncGrp,IncBreaks_[as.character(VehPropByGroups$VehPropByAgeIncGrpType$IncGrp)],FUN = max)


  rm(IncBreaks_, MaxInc, Ig)
  # Identify metropolitan area
  IsMetro_ <- Hh_df$Urban == 1

  # Initialize Hhvehcnt and VehPerDrvAgePop variables
  Hh_df$Hhvehcnt <- 0
  Hh_df$VehPerDrvAgePop <- 0

  #Run the model
  #-------------

  # Predict ownership for metropolitan households if any exist
  if(any(IsMetro_)){
    ModelVar_ <- c( "Income", "Htppopdn", "TranRevMiPC", "Urban",
                    "FwyLaneMiPC", "OnlyElderly", "DrvLevels", "DrvAgePop")
    MetroVehOwn_ <- predictVehicleOwnership( Hh_df[IsMetro_, ModelVar_],
                                   ModelType = VehOwnModels_ls, VehProp = VehProp,
                                   Type="Metro")
    rm(ModelVar_)
  }
  # Predict ownership for nonmetropolitan households if any exist
  if(any(!IsMetro_)){
    ModelVar_ <- c( "Income", "Htppopdn", "OnlyElderly", "DrvLevels", "DrvAgePop" )
    NonMetroVehOwn_ <- predictVehicleOwnership(Hh_df[IsMetro_, ModelVar_],
                                               ModelType = VehOwnModels_ls, VehProp = VehProp,
                                               Type="NonMetro")
    rm(ModelVar_)
  }

  # Assign values to SynPop.. and return the result
  if( any(IsMetro_) ) {
    Hh_df$Hhvehcnt[ IsMetro_ ] <- MetroVehOwn_$NumVeh
    Hh_df$VehPerDrvAgePop[ IsMetro_ ] <- MetroVehOwn_$VehRatio
  }
  if( any(!IsMetro_) ) {
    Hh_df$Hhvehcnt[ !IsMetro_ ] <- NonMetroVehOwn_$NumVeh
    Hh_df$VehPerDrvAgePop[ !IsMetro_ ] <- NonMetroVehOwn_$VehRatio
  }
  # Clean up
  if( exists( "MetroVehOwn_" ) ) rm( MetroVehOwn_ )
  if( exists( "NonMetroVehOwn_" ) ) rm( NonMetroVehOwn_ )

  # Calculate vehicle types, ages, and initial fuel economy
  #========================================================

  # Predict light truck ownership and vehicle ages
  #-----------------------------------------------
  # Apply vehicle type model
  ModelVar_ <- c( "Income", "Htppopdn", "Urban", "Hhvehcnt", "HhSize" )
  #light truck proportion is a single value in parameters_
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  Hh_df$VehType <- predictLtTruckOwn( Hh_df[ , ModelVar_ ], ModelType=LtTruckModels_ls,
                                         TruckProp=L$Global$Model$LtTruckProp )
  rm( ModelVar_ )
  # Apply vehicle age model
  ModelVar_ <- c( "IncGrp", "Hhvehcnt", "VehType" )
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  VehTypeAgeResults_ <- calcVehicleAges(Hh_df = Hh_df[, ModelVar_], VProp = VehPropByGroups)
  rm( ModelVar_ )
  # Add type and age model results
  Hh_df$VehType[ Hh_df$Hhvehcnt == 0 ] <- NA
  Hh_df$VehAge <- VehTypeAgeResults_$VehAge
  Hh_df$VehAge[ Hh_df$Hhvehcnt == 0 ] <- NA
  rm( VehTypeAgeResults_ )

  # Assign initial fuel economy
  #----------------------------
  # Assign fuel economy to vehicles
  HhHasVeh <- Hh_df$Hhvehcnt > 0
  Hh_df$VehMpg <- NA
  ModelVar_ <- c( "VehType", "VehAge", "Hhvehcnt" )
  VehMpgYr <- cbind(Year = as.integer(L$Global$Vehicles$ModelYear), Auto = L$Global$Vehicles$AutoMpg, LtTruck = L$Global$Vehicles$LtTruckMpg)
  Hh_df$VehMpg[HhHasVeh] <- assignFuelEconomy( Hh_df[HhHasVeh, ModelVar_],
                                                     VehMpgYr = VehMpgYr, CurrentYear = L$G$Year)
  rm( ModelVar_ )

  # Assign vehicle mileage proportions to household vehicles
  Hh_df$DvmtProp <- NA
  ModelVar_ <- c("Hhvehcnt", "HhId")
  DvmtProp_ <- data.frame(Veh1Value = L$Global$VehicleMpgProp$Veh1Value,
                         Veh1Prob = L$Global$VehicleMpgProp$Veh1Prob,
                         Veh2Value = L$Global$VehicleMpgProp$Veh2Value,
                         Veh2Prob = L$Global$VehicleMpgProp$Veh2Prob,
                         Veh3Value = L$Global$VehicleMpgProp$Veh3Value,
                         Veh3Prob = L$Global$VehicleMpgProp$Veh3Prob,
                         Veh4Value = L$Global$VehicleMpgProp$Veh4Value,
                         Veh4Prob = L$Global$VehicleMpgProp$Veh4Prob,
                         Veh5PlusValue = L$Global$VehicleMpgProp$Veh5PlusValue,
                         Veh5PlusProb = L$Global$VehicleMpgProp$Veh5PlusProb)
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  Hh_df$DvmtProp[ HhHasVeh ] <- apportionDvmt( Hh_df[ HhHasVeh, ModelVar_],
                                                   DvmtProp=DvmtProp_ )
  rm( ModelVar_ )

  # Count the number of vehicle types per houshold
  #------------------------------------------------

  Hh_df$NumAuto <- unlist(lapply(Hh_df$VehType,function(x) sum(x=="Auto")))
  Hh_df$NumAuto[is.na(Hh_df$NumAuto)] <- 0L
  Hh_df$NumLtTruck <- Hh_df$Hhvehcnt - Hh_df$NumAuto




  #Return the results
  #------------------
  #Identify households having vehicles
  Use <- Hh_df$Hhvehcnt != 0
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list()
  attributes(Out_ls$Year$Vehicle)$LENGTH <- sum(Hh_df$Hhvehcnt)
  Out_ls$Year$Vehicle$HhId <-
    with(L$Year$Household, rep(HhId[Use], Hh_df$Hhvehcnt[Use]))
  attributes(Out_ls$Year$Vehicle$HhId)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$HhId))
  Out_ls$Year$Vehicle$VehId <-
    with(Hh_df,
         paste(rep(HhId[Use], Hhvehcnt[Use]),
               unlist(sapply(Hhvehcnt[Use], function(x) 1:x)),
               sep = "-"))
  attributes(Out_ls$Year$Vehicle$VehId)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$VehId))
  Out_ls$Year$Vehicle$Azone <-
    with(L$Year$Household, rep(Azone[Use], Hh_df$Hhvehcnt[Use]))
  attributes(Out_ls$Year$Vehicle$Azone)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$Azone))
  Out_ls$Year$Vehicle$Marea <-
    with(L$Year$Household, rep(Marea[Use], Hh_df$Hhvehcnt[Use]))
  attributes(Out_ls$Year$Vehicle$Marea)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$Marea))
  Out_ls$Year$Vehicle$Type <- unlist(Hh_df$VehType[Use])
  Out_ls$Year$Vehicle$Type[Out_ls$Year$Vehicle$Type=="LtTruck"] <- "LtTrk"
  attributes(Out_ls$Year$Vehicle$Type)$SIZE <- max(nchar(Out_ls$Year$Vehicle$Type))
  Out_ls$Year$Vehicle$Age <- unlist(Hh_df$VehAge[Use])
  Out_ls$Year$Vehicle$Mileage <- unlist(Hh_df$VehMpg[Use])
  Out_ls$Year$Vehicle$DvmtProp <- unlist(Hh_df$DvmtProp[Use])

  Out_ls$Year$Household <-
    list(NumLtTrk = Hh_df$NumLtTruck,
         NumAuto = Hh_df$NumAuto,
         Vehicles = Hh_df$Hhvehcnt)


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
#   ModuleName = "AssignVehicleFeatures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
