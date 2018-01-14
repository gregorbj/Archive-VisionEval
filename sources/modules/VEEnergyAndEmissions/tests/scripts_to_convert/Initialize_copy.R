#============
#Initialize.R
#============
#This module reads in user-optional input files on vehicle and fuel
#characteristics, processes them, and saves them to the datastore.

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
#This module has no estimated parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
InitializeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Time frame
  RunFor = "AllYears",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "ElectricityCI",
      FILE = "azone_electricity_carbon_intensity.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Carbon intensity of electricity at point of consumption (grams CO2e per megajoule)",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      FILE = "marea_transit_ave_fuel_carbon_intensity.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuel used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit rail vehicles (grams CO2e per megajoule)"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitEthanolPropGasoline",
          "TransitBiodieselPropDiesel",
          "TransitRngPropCng"
        ),
      FILE = "marea_transit_biofuel_mix.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Ethanol proportion of gasoline used by transit vehicles",
          "Biodiesel proportion of diesel used by transit vehicles",
          "Renewable natural gas proportion of compressed natural gas used by transit vehicles"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropDiesel",
          "VanPropGasoline",
          "VanPropCng",
          "BusPropDiesel",
          "BusPropGasoline",
          "BusPropCng",
          "RailPropDiesel",
          "RailPropGasoline"
        ),
      FILE = "marea_transit_fuel.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of non-electric transit van travel powered by diesel",
          "Proportion of non-electric transit van travel powered by gasoline",
          "Proportion of non-electric transit van travel powered by compressed natural gas",
          "Proportion of non-electric transit bus travel powered by diesel",
          "Proportion of non-electric transit bus travel powered by gasoline",
          "Proportion of non-electric transit bus travel powered by compressed natural gas",
          "Proportion of non-electric transit rail travel powered by diesel",
          "Proportion of non-electric transit rail travel powered by gasoline"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropIcev",
          "VanPropHev",
          "VanPropBev",
          "BusPropIcev",
          "BusPropHev",
          "BusPropBev",
          "RailPropIcev",
          "RailPropHev",
          "RailPropEv"
        ),
      FILE = "marea_transit_powertrain_prop.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of transit van travel using internal combustion engine powertrains",
          "Proportion of transit van travel using hybrid electric powertrains",
          "Proportion of transit van travel using battery electric powertrains",
          "Proportion of transit bus travel using internal combustion engine powertrains",
          "Proportion of transit bus travel using hybrid electric powertrains",
          "Proportion of transit bus travel using battery electric powertrains",
          "Proportion of transit rail travel using internal combustion engine powertrains",
          "Proportion of transit rail travel using hybrid electric powertrains",
          "Proportion of transit rail travel using electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HhFuelCI",
          "CarSvcFuelCI",
          "ComSvcFuelCI",
          "HvyTrkFuelCI",
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      FILE = "region_ave_fuel_carbon_intensity.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuels used by household vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by car service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by commercial service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit rail vehicles (grams CO2e per megajoule)"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "CarSvcAutoPropIcev",
          "CarSvcAutoPropHev",
          "CarSvcAutoPropBev",
          "CarSvcLtTrkPropIcev",
          "CarSvcLtTrkPropHev",
          "CarSvcLtTrkPropBev"
        ),
      FILE = "region_carsvc_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of car service automobile travel powered by internal combustion engine powertrains",
          "Proportion of car service automobile travel powered by hybrid electric powertrains",
          "Proportion of car service automobile travel powered by battery electric powertrains",
          "Proportion of car service light truck travel powered by internal combustion engine powertrains",
          "Proportion of car service light truck travel powered by hybrid electric powertrains",
          "Proportion of car service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "ComSvcAutoPropIcev",
          "ComSvcAutoPropHev",
          "ComSvcAutoPropBev",
          "ComSvcLtTrkPropIcev",
          "ComSvcLtTrkPropHev",
          "ComSvcLtTrkPropBev"
        ),
      FILE = "region_comsvc_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of commercial service automobile travel powered by internal combustion engine powertrains",
          "Proportion of commercial service automobile travel powered by hybrid electric powertrains",
          "Proportion of commercial service automobile travel powered by battery electric powertrains",
          "Proportion of commercial service light truck travel powered by internal combustion engine powertrains",
          "Proportion of commercial service light truck travel powered by hybrid electric powertrains",
          "Proportion of commercial service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HvyTrkPropIcev",
          "HvyTrkPropHev",
          "HvyTrkPropBev"
        ),
      FILE = "region_hvytrk_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of heavy truck travel powered by internal combustion engine powertrains",
          "Proportion of heavy truck travel powered by hybrid electric powertrains",
          "Proportion of heavy truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items(
          "VanPropDiesel",
          "VanPropGasoline",
          "VanPropCng",
          "BusPropDiesel",
          "BusPropGasoline",
          "BusPropCng",
          "RailPropDiesel",
          "RailPropGasoline"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropIcev",
          "VanPropHev",
          "VanPropBev",
          "BusPropIcev",
          "BusPropHev",
          "BusPropBev",
          "RailPropIcev",
          "RailPropHev",
          "RailPropEv"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "CarSvcAutoPropIcev",
          "CarSvcAutoPropHev",
          "CarSvcAutoPropBev",
          "CarSvcLtTrkPropIcev",
          "CarSvcLtTrkPropHev",
          "CarSvcLtTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "ComSvcAutoPropIcev",
          "ComSvcAutoPropHev",
          "ComSvcAutoPropBev",
          "ComSvcLtTrkPropIcev",
          "ComSvcLtTrkPropHev",
          "ComSvcLtTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HvyTrkPropIcev",
          "HvyTrkPropHev",
          "HvyTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items(
          "VanPropDiesel",
          "VanPropGasoline",
          "VanPropCng",
          "BusPropDiesel",
          "BusPropGasoline",
          "BusPropCng",
          "RailPropDiesel",
          "RailPropGasoline"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Proportion of non-electric transit van travel powered by diesel",
          "Proportion of non-electric transit van travel powered by gasoline",
          "Proportion of non-electric transit van travel powered by compressed natural gas",
          "Proportion of non-electric transit bus travel powered by diesel",
          "Proportion of non-electric transit bus travel powered by gasoline",
          "Proportion of non-electric transit bus travel powered by compressed natural gas",
          "Proportion of non-electric transit rail travel powered by diesel",
          "Proportion of non-electric transit rail travel powered by gasoline"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropIcev",
          "VanPropHev",
          "VanPropBev",
          "BusPropIcev",
          "BusPropHev",
          "BusPropBev",
          "RailPropIcev",
          "RailPropHev",
          "RailPropEv"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Proportion of transit van travel using internal combustion engine powertrains",
          "Proportion of transit van travel using hybrid electric powertrains",
          "Proportion of transit van travel using battery electric powertrains",
          "Proportion of transit bus travel using internal combustion engine powertrains",
          "Proportion of transit bus travel using hybrid electric powertrains",
          "Proportion of transit bus travel using battery electric powertrains",
          "Proportion of transit rail travel using internal combustion engine powertrains",
          "Proportion of transit rail travel using hybrid electric powertrains",
          "Proportion of transit rail travel using electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "CarSvcAutoPropIcev",
          "CarSvcAutoPropHev",
          "CarSvcAutoPropBev",
          "CarSvcLtTrkPropIcev",
          "CarSvcLtTrkPropHev",
          "CarSvcLtTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Proportion of car service automobile travel powered by internal combustion engine powertrains",
          "Proportion of car service automobile travel powered by hybrid electric powertrains",
          "Proportion of car service automobile travel powered by battery electric powertrains",
          "Proportion of car service light truck travel powered by internal combustion engine powertrains",
          "Proportion of car service light truck travel powered by hybrid electric powertrains",
          "Proportion of car service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "ComSvcAutoPropIcev",
          "ComSvcAutoPropHev",
          "ComSvcAutoPropBev",
          "ComSvcLtTrkPropIcev",
          "ComSvcLtTrkPropHev",
          "ComSvcLtTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Proportion of commercial service automobile travel powered by internal combustion engine powertrains",
          "Proportion of commercial service automobile travel powered by hybrid electric powertrains",
          "Proportion of commercial service automobile travel powered by battery electric powertrains",
          "Proportion of commercial service light truck travel powered by internal combustion engine powertrains",
          "Proportion of commercial service light truck travel powered by hybrid electric powertrains",
          "Proportion of commercial service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HvyTrkPropIcev",
          "HvyTrkPropHev",
          "HvyTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Proportion of heavy truck travel powered by internal combustion engine powertrains",
          "Proportion of heavy truck travel powered by hybrid electric powertrains",
          "Proportion of heavy truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for Initialize module
#'
#' A list containing specifications for the Initialize module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{RunFor}{options = AllYears, BaseYear, NoBaseYear}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source Initialize.R script.
"InitializeSpecifications"
devtools::use_data(InitializeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================


#Main function to check and process inputs.
Initialize <- function(L) {
  #Initialize error and warnings message vectors
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Initialize output list with input values
  Out_ls <- L[c("Global", "Year", "BaseYear")]
  #Define function to check and adjust proportions
  checkProps <- function(Names_, Geo) {
    Values_ <- unlist(L$Year[[Geo]][Names_])
    SumDiff <- abs(1 - sum(Values_))
    if (SumDiff > 0.01) {
      Msg <- paste0(
        "Error in input values for ",
        paste(Names_, collapse = ", "),
        ". The sum of these values is off by more than 1%. ",
        "They should add up to 1."
      )
      Errors_ <- c(Errors_, Msg)
    }
    if (SumDiff > 0 & SumDiff < 0.01) {
      Msg <- paste0(
        "Warning regarding input values for ",
        paste(Names_, collapse = ", "),
        ". The sum of these values do not add up to 1 ",
        "but are off by 1% or less so they have been adjusted to add up to 1."
      )
      Warnings_ <- c(Warnings_, Msg)
      Values_ <- Values_ / sum(Values_)
    }
    Values_
  }
  #Check and adjust car service vehicle powertrain proportions
  Names_ <- c("CarSvcAutoPropIcev", "CarSvcAutoPropHev", "CarSvcAutoPropBev")
  Out_ls[["Region"]][Names_] <- checkProps(Names_, "Region")
  Names_ <- c("CarSvcLtTrkPropIcev", "CarSvcLtTrkPropHev", "CarSvcLtTrkPropBev")
  Out_ls[["Region"]][Names_] <- checkProps(Names_, "Region")
  #Check and adjust commercial service vehicle powertrain proportions
  Names_ <- c("ComSvcAutoPropIcev", "ComSvcAutoPropHev", "ComSvcAutoPropBev")
  Out_ls[["Region"]][Names_] <- checkProps(Names_, "Region")
  Names_ <- c("ComSvcLtTrkPropIcev", "ComSvcLtTrkPropHev", "ComSvcLtTrkPropBev")
  Out_ls[["Region"]][Names_] <- checkProps(Names_, "Region")
  #Check heavy truck powertrain proportions
  Names_ <- c("HvyTrkPropIcev", "HvyTrkPropHev", "HvyTrkPropBev")
  Out_ls[["Region"]][Names_] <- checkProps(Names_, "Region")
  #Check transit fuel proportions

  #Check transit powertrain proportions

}




#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
TestDat_ <- testModule(
  ModuleName = "Initialize",
  LoadDatastore = TRUE,
  SaveDatastore = TRUE,
  DoRun = FALSE
)
L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictIncome",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
