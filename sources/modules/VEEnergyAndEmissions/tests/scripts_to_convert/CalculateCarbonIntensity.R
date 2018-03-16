#==========================
#CalculateCarbonIntensity.R
#==========================
#This module calculates the average carbon intensity of vehicle fuels by vehicle
#type, energy type, and year using user inputs if they were supplied or default
#inputs.

# Copyright [2018] [AASHTO]
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
#This module has no estimated model.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateCarbonIntensitySpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "ElectricityCI",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitEthanolPropGasoline",
          "TransitBiodieselPropDiesel",
          "TransitRngPropCng"
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
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
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
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
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
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  ),
  #Specify data to saved in the data store
  Set = items(
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
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuels used by household vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by car service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by commercial service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit rail vehicles (grams CO2e per megajoule)"
        )
    ),
    item(
      NAME = "ElectricityCI",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        "Carbon intensity of electricity at point of consumption (grams CO2e per megajoule)"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateCarbonIntensity module
#'
#' A list containing specifications for the CalculateCarbonIntensity module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateCarbonIntensity.R script.
"CalculateCarbonIntensitySpecifications"
devtools::use_data(CalculateCarbonIntensitySpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function calculates carbon intensity
#------------------------------------------------
#' Calculate energy carbon intensity.
#'
#' \code{CalculateCarbonIntensity} Calculate the average carbon intensity of
#' energy sources uses to power transport vehicles.
#'
#' This function calculates the average carbon intensity of energy sources used
#' to power transport vehicles for different uses and types. Carbon intensity is
#' measured in units of grams of carbon dioxide equivalents per megajoule of
#' energy. For transport vehicles powered by on-board hydrocarbon fuel (e.g.
#' gasoline), the average carbon intensity is calculated by transportation type
#' (e.g. household, commercial service, public transportation) and vehicle type
#' (e.g. light duty vehicle, heavy truck, bus) based on default package values
#' or input values on the types of fuels consumed unless the user has provided
#' input values for carbon intensity. For all travel powered by electricity, the
#' carbon intensity of electric power is calculated for each Azone. This carbon
#' intensity is used to calculate carbon emissions for all transport vehicle
#' travel that is powered by electricity. The default package value is used
#' unless the user has supplied values by Azone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'

CalculateCarbonIntensity <- function(L) {

  #Function to interpolate a value
  interpolateYearValue <- function(Year, Years_, Values_) {
    SplineFit_SS <- smooth.spline(Years_, Values_, df = 6)
    predict(SplineFit_SS, Year)$y
  }

  #Function to interpolate values for a data frame
  interpolateYearValues <- function(Data_df, Year) {
    Years_ <- Data_df$Year
    Fields_ <- names(Data_df)[-which(names(Data_df) == "Year")]
    sapply(Fields_, function(x) {
      interpolateYearValue(
        Year = Year,
        Years_ = Years_,
        Values_ = Data_df[[x]]
      )
    })
  }

  #Initialize outputs list
  Out_ls <- initDataList()
  Out_ls$Year$Azone <- list()
  Out_ls$Year$Marea <- list()
  Out_ls$Year$Region <- list()

  #Calculate average carbon intensity of light-duty vehicle fuels
  #--------------------------------------------------------------
  #Interpolate the carbon intensity of fuels for the model run year
  CarbonIntensity_ <- interpolateYearValues(
    Data_df = EnergyEmissionsDefaults_ls$CarbonIntensity_df,
    Year = as.numeric(L$G$Year)
  )
  #Interpolate biofuel mix values
  BiofuelMix_ <- interpolateYearValues(
    Data_df = EnergyEmissionsDefaults_ls$LdvBiofuelMix_df,
    Year = as.numeric(L$G$Year)
  )
  #Calculate mixed fuel carbon intensity
  LdvFuelCI_ <- c(
    Gasoline = sum(
      CarbonIntensity_[c("Gasoline", "Ethanol")] *
        abs(BiofuelMix_["EthanolPropGasoline"] - c(1,0))
    ),
    Diesel = sum(
      CarbonIntensity_[c("Diesel", "Biodiesel")] *
        abs(BiofuelMix_["BiodieselPropDiesel"] - c(1,0))
    ),
    Cng = sum(
      CarbonIntensity_[c("Cng", "Rng")] *
        abs(BiofuelMix_["RngPropCng"] - c(1,0))
    )
  )


  #Interpolate household auto and light truck fuel proportion values
  HhFuelProp_ <- interpolateYearValues(
    Data_df = EnergyEmissionsDefaults_ls$HhFuel_df,
    Year = as.numeric(L$G$Year)
  )
  #Interpolate car service auto and light truck fuel proportion values
  CarSvcFuelProp_ <- interpolateYearValues(
    Data_df = EnergyEmissionsDefaults_ls$CarSvcFuel_df,
    Year = as.numeric(L$G$Year)
  )
  #Interpolate commercial service auto and light truck fuel proportion values
  ComSvcFuelProp_ <- interpolateYearValues(
    Data_df = EnergyEmissionsDefaults_ls$ComSvcFuel_df,
    Year = as.numeric(L$G$Year)
  )



  #Calculate carbon intensity of electricity
  if (!is.null(L$Year$Azone$ElectricityCI)) {
    Out_ls$Year$Azone$ElectricityCI <- L$Year$Azone$ElectricityCI
  } else {
    Out_ls$Year$Azone$ElectricityCI <-
      rep(CarbonIntensity_["Electricity"], length(L$Year$Azone$Azone))
  }

  #Calculate carbon intensity of fuels used for household vehicle travel
  if (!is.null(L$Year$Region$HhFuelCI)) {
    Out_ls$Year$Region$HhAutoFuelCI <- L$Year$Region$HhFuelCI
    Out_ls$Year$Region$HhLtTrkFuelCI <- L$Year$Region$HhFuelCI
  } else {
    EnergyEmissionsDefaults_ls$HhFuel_df


  }



}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# load("data/EnergyEmissionsDefaults_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "CalculateCarbonIntensity",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateCarbonIntensity(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignHhVehicleDvmtSplit",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
