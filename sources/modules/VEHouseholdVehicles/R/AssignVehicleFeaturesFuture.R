#========================
#AssignVehicleFeaturesFuture.R
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
#' @source AssignVehicleFeaturesFuture.R script.
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
#' @source AssignVehicleFeaturesFuture.R script.
"LtTruckModels_ls"
devtools::use_data(LtTruckModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleFeaturesFutureSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #---------------------------
  #Specify new tables to be created by Set if any
  #Specify input data (similar to the assignvehiclefeatures module from this package)
  #Specify data to be loaded from data store
  Get = items(
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
        "TranRevMiPCFuture",
        "FwyLaneMiPCFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
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
    item(
      NAME =
        items("HhIdFuture",
              "VehIdFuture",
              "AzoneFuture",
              "MareaFuture"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID using future data",
              "Unique vehicle ID using future data",
              "Azone ID using future data",
              "Marea ID using future data")
    ),
    item(
      NAME = "VehiclesFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of automobiles and light trucks owned or leased by the household
       using future data"
    ),
    item(
      NAME = "TypeFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk"),
      SIZE = 5,
      DESCRIPTION = "Vehicle body type: Auto = automobile, LtTrk = light trucks (i.e. pickup, SUV, Van) using future data"
    ),
    item(
      NAME = "AgeFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Vehicle age in years using future data"
    ),
    item(
      NAME = items(
        "NumLtTrkFuture",
        "NumAutoFuture"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household using future data",
        "Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household using future data"
      )
    ),
    item(
      NAME = "MileageFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "<0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Mileage of vehicles (automobiles and light truck) using future data"
    ),
    item(
      NAME = "DvmtPropFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = "Proportion of average household DVMT using future data"
    )
  )
  )

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignVehicleFeaturesFuture module
#'
#' A list containing specifications for the AssignVehicleFeaturesFuture module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignVehicleFeaturesFuture.R script.
"AssignVehicleFeaturesFutureSpecifications"
devtools::use_data(AssignVehicleFeaturesFutureSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that calculates vehicle features
#------------------------------------------------------
#' Create vehicle table and populate with vehicle type, age, and mileage records.
#'
#' \code{AssignVehicleFeaturesFuture} populate vehicle table with
#' vehicle type, age, and mileage records using future data.
#'
#' This function populates vehicle table with records of
#' vehicle types, ages, mileage, and mileage proportions
#' along with household IDs using future data.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @import stats
#' @export
AssignVehicleFeaturesFuture <- function(L) {
  #Set up
  #------
  # Function to rename variables to be consistent with Get specfications
  # of AssignVehicleFeatures.

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
  # Call the AssignVehicleFeatures function with the new dataset
  Out_ls <- AssignVehicleFeatures(L)

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
#   ModuleName = "AssignVehicleFeaturesFuture",
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
