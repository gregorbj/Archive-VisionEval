#=============================
#CalculateHhEnergyAndEmissions
#=============================
#This module calculates the consumption of vehicle fuels and electricity
#consumed by each household vehicle and the corresponding greenhouse gas
#emissions. Vehicle fuel consumption is in gasoline-equivalent gallons,
#electricity consumption in kilowatt-hours, and greenhouse gas emissions in
#carbon-dioxide equivalents.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#-------------------------------------------------------
#Model proportions of PHEV travel powered by electricity
#-------------------------------------------------------
#This model estimates the proportions of plug-in hybrid electric vehicle (PHEV)
#travel powered by electricity. The model assumes that a PHEV will be fully
#charged once per day and that the vehicle will be powered by electricity up to
#the specified battery range. Travel exceeding the battery range will be powered
#by gasoline. It is also assumed that travel will vary from day to day so that
#the proportion of travel powered by electricity will not be the ratio of the
#battery range and average daily vehicle miles of travel (DVMT). For example,
#if a household has a PHEV whose battery range is greater than the average DVMT
#for the vehicle, not all of the vehicle travel will be powered by electricity
#because there will be some days when the vehicle is driven beyond the vehicle's
#battery range. To estimate the proportion of a PHEV travel powered by
#electricity, it is assumed that the variation in the vehicle's DVMT is the same
#as the variation in household DVMT as simulated by the CalculateHouseholdDvmt
#module in the VEHouseholdTravel package. That module includes polynomial
#regression models for calculating DVMT percentiles (from 5% to 95% at 5%
#intervals) as a function of the average household DVMT. There are separate
#models for metropolitan and non-metropolitan households. A PHEV power model
#is estimated by first generating lookup tables relating average DVMT to DVMT
#percentiles. The model function then takes an average DVMT and a battery range
#and calculates the proportion of travel powered by electricity.

#Define function to calculate electric proportion of travel
#----------------------------------------------------------
calcElectricProp <- function(Dvmt, Range, MareaType) {
  #Select the DVMT percentile models for the metropolitan area type
  PctlModels_ls <- VEHouseholdTravel::DvmtModel_ls[[MareaType]][-c(1,2)]
  #Calculate DVMT by pecentile
  Dvmt_df <- data.frame(
    Intercept = 1,
    Dvmt = Dvmt,
    DvmtSq = Dvmt^2,
    DvmtCu = Dvmt^3
  )
  DvmtByPctl_ <- unlist(lapply(PctlModels_ls, function(x) {
    eval(parse(text = x), envir = Dvmt_df) }))
  DvmtByPctl_[DvmtByPctl_ < 0] <- 0
  #Create a smooth spline model of the prediction
  Pctl_ <- c(seq(5, 95, 5), 99)
  Pctl_SS <- smooth.spline(Pctl_, DvmtByPctl_)
  #Calculate the percentile corresponding to the battery range
  Range_SS <- smooth.spline(DvmtByPctl_, Pctl_)
  RangePctl <- predict(Range_SS, Range)$y
  #Define function to integrate
  predPctl <- function(Vals_) {
    predict(Pctl_SS, Vals_)$y
  }
  #Integrate DVMT above and below the range
  DvmtBelow <- integrate(predPctl, 0, RangePctl)$value
  DvmtAbove <- integrate(predPctl, RangePctl, 100)$value
  #Calculate proportion of DVMT powered by electricity
  ElecDvmt <- DvmtBelow + Range * (100 - RangePctl)
  ElecProp <- ElecDvmt / (DvmtBelow + DvmtAbove)
  min(ElecProp, 1)
}

#Create lookup tables of electric proportions and lookup function
#----------------------------------------------------------------
#Define ranges of DVMT (Vm) and vehicle ranges (Rg)
Vm <- seq(5, 200, 5)
Rg <- seq(5, 150, 5)
#Define a function to smooth the values in the lookup tables
smoothLookup <- function(ElecProp_VmRg) {
  for (i in 1:length(Rg)) {
    Props_Vm <- ElecProp_VmRg[,i]
    SS <- smooth.spline(Vm, Props_Vm, df = 4)
    ElecProp_VmRg[,i] <- predict(SS, Vm)$y
  }
  for (i in 1:length(Vm)) {
    Props_Rg <- ElecProp_VmRg[i,]
    SS <- smooth.spline(Rg, Props_Rg, df = 4)
    ElecProp_VmRg[i,] <- predict(SS, Rg)$y
  }
  ElecProp_VmRg <- round(ElecProp_VmRg, 3)
  ElecProp_VmRg[ElecProp_VmRg > 1] <- 1
  ElecProp_VmRg
}
#Create a list to hold lookup tables and lookup function
PhevElecProp_ls <- list()
#Create lookup table for metropolitan areas
ElecProp_VmRg <- sapply(Rg, function(x) {
  sapply(Vm, function(y) {
    calcElectricProp(y, x, "Metro")
  })
})
PhevElecProp_ls$Metro_VmRg <- smoothLookup(ElecProp_VmRg)
rm(ElecProp_VmRg)
#Create lookup table for non-metropolitan areas
ElecProp_VmRg <- sapply(Rg, function(x) {
  sapply(Vm, function(y) {
    calcElectricProp(y, x, "NonMetro")
  })
})
PhevElecProp_ls$NonMetro_VmRg <- smoothLookup(ElecProp_VmRg)
rm(ElecProp_VmRg)
#Define function to look up an electric proportion from DVMT and range values
PhevElecProp_ls$getElecProp <-
  function(Dvmt, Range, MareaType, Prop_ls = PhevElecProp_ls) {
    Dvmt[Dvmt < 5] <- 5
    Dvmt[Dvmt > 200] <- 200
    Range[Range < 5] <- 5
    Range[Range > 150] <- 150
    Prop_ls[[paste0(MareaType, "_VmRg")]][round(Dvmt / 5), round(Range / 5)]
  }
rm(Vm, Rg, smoothLookup, calcElectricProp)

#Save the PHEV electric proportion lookup tables and lookup function
#-------------------------------------------------------------------
#' PHEV electric travel proportion lookup tables and lookup function
#'
#' Lookup metropolitan and non-metropolitan tables identifying the proportion of
#' travel by vehicle DVMT and vehicle battery range and a function for
#' extracting values from the tables.
#'
#' @format A list of lookup table matrices and a lookup function
#' \describe{
#'   \item{Metro_VmRg}{a matrix of electric power proportions by DVMT and battery range for metropolitan areas},
#'   \item{NonMetro_VmRg}{a matrix of electric power proportions by DVMT and battery range for non-metropolitan areas}
#'   \item{getElecProp}{a function to get a value from a lookup table}
#' }
#' @source CalculateHhEnergyAndEmissions.R script.
"PhevElecProp_ls"
devtools::use_data(PhevElecProp_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateHhEnergyAndEmissionsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Marea",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
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
      NAME = "Azone",
      TABLE = "Azone",
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
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "HhAutoFuelCI",
          "HhLtTrkFuelCI"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("ICEV", "HEV", "PHEV", "BEV")
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
      NAME = "MPG",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "MPKWH",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/KWH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LdvEcoDrive",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "LdvSpdSmoothFactor",
        "LdvEcoDriveFactor",
        "LdIceFactor",
        "LdHevFactor",
        "LdEvFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = "<= 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "IsEcoDrive",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = c("NA"),
      ISELEMENTOF = c(0, 1),
      OPTIONAL = TRUE
    ),
    item(
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural")
    ),
    item(
      NAME = "BatRng",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = "IsEcoDrive",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Flag identifying whether drivers in household are eco-drivers"
    ),
    item(
      NAME = "GGE",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "energy",
      UNITS = "GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily amount of hydrocarbon fuels consumed in gas gallon equivalents"
    ),
    item(
      NAME = "GGE",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "energy",
      UNITS = "GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily amount of hydrocarbon fuels consumed in gas gallon equivalents"
    ),
    item(
      NAME = "KWH",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "energy",
      UNITS = "KWH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily amount of electricity consumed in kilowatt-hours"
    ),
    item(
      NAME = "KWH",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "energy",
      UNITS = "KWH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily amount of electricity consumed in kilowatt-hours"
    ),
    item(
      NAME = "CO2e",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily amount of carbon-dioxide equivalents produced in grams"
    ),
    item(
      NAME = "CO2e",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily amount of carbon-dioxide equivalents produced in grams"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateHouseholdEnergyAndEmissions module
#'
#' A list containing specifications for the CalculateHouseholdEnergyAndEmissions
#' module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateHhEnergyAndEmissions.R script.
"CalculateHhEnergyAndEmissionsSpecifications"
devtools::use_data(CalculateHhEnergyAndEmissionsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the energy consumption and carbon emissions production
#from household vehicle travel. Fuel consumption is calculated in gasoline
#gallon equivalent. Electricity consumption is calculated in kilowatt hours.
#Vehicle average MPG and MPkWh is adjusted to account for eco-driving, speed
#smoothing, and congestion. Households are assigned to be eco-driving households
#or not if that has not already been done. The module assumes that all vehicle
#travel by households in the urbanized area are affected by congestion for the
#purpose of adjusting MPG and MPkWh of their vehicles, while none of the travel
#of households located outside of urbanized areas is affected. This is a
#necessary simplification because the model currently does not estimate the
#proportions of household travel inside and outside of urbanized areas. Carbon
#emissions are calculated in carbon dioxide equivents (CO2e) using the carbon
#intensities calculated by the CalculateCarbonIntensity module. The vehicle
#energy and emissions are summed by household.

#Main module function that calculates household vehicle energy and emissions
#---------------------------------------------------------------------------
#' Calculate energy and emissions of household vehicle travel.
#'
#' \code{CalculateHhEnergyAndEmissions} calculates the hydrocarbon and
#' electrical energy consumption of the travel of each household vehicle and the
#' carbon emissions produced.
#'
#' This function calculates the hydrocarbon and electrical energy consumption of
#' the travel of each household vehicle and the carbon emissions produced. It
#' assigns households to be eco-driving households or not if that hasn't been
#' done before.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'
CalculateHhEnergyAndEmissions <- function(L) {

  #Set up
  #------
  #Set random seed
  set.seed(L$G$Seed)
  #Set up vector to match household characteristics to vehicle table
  VehToHhMatch_Ve <- match(L$Year$Vehicle$HhId, L$Year$Household$HhId)
  #Calculate number of vehicles
  NumVeh <- length(L$Year$Vehicle$Marea)
  #Identify which vehicles are metropolitan and non-metropolitan
  MareaType_Ve <- rep("Metro", length(L$Year$Vehicle$Marea))
  MareaType_Ve[L$Year$Household$DevType[VehToHhMatch_Ve] == "Rural"] <-
    "NonMetro"
  IsMetro_ <- MareaType_Ve == "Metro"

  #Calculate the proportion of vehicle DVMT powered by electricity
  #---------------------------------------------------------------
  ElecDvmtProp_Ve <- local({
    Powertrain_Ve <- L$Year$Vehicle$Powertrain
    BatRng_Ve <- L$Year$Vehicle$BatRng
    ElecDvmtProp_Ve <- numeric(NumVeh)
    IsPhev_ <- Powertrain_Ve == "PHEV"
    if (sum((IsPhev_ & IsMetro_) >= 1)) {
      ElecDvmtProp_Ve[IsPhev_ & IsMetro_] <-
        mapply(
          PhevElecProp_ls$getElecProp,
          L$Year$Vehicle$Dvmt[IsPhev_ & IsMetro_],
          L$Year$Vehicle$BatRng[IsPhev_ & IsMetro_],
          "Metro")
    }
    if (sum((IsPhev_ & !IsMetro_) >= 1)) {
      ElecDvmtProp_Ve[IsPhev_ & !IsMetro_] <-
        mapply(
          PhevElecProp_ls$getElecProp,
          L$Year$Vehicle$Dvmt[IsPhev_ & !IsMetro_],
          L$Year$Vehicle$BatRng[IsPhev_ & !IsMetro_],
          "NonMetro")
    }
    IsEv_ <- Powertrain_Ve == "BEV"
    if (sum(IsEv_ >= 1)) {
      ElecDvmtProp_Ve[IsEv_] <- 1
    }
    ElecDvmtProp_Ve
  })

  #Identify eco-driving and speed smoothing factors
  #------------------------------------------------
  #If eco-driving households haven't been identified, do so
  if (is.null(L$Year$Household$IsEcoDrive)) {
    EcoDriveProb <- L$Year$Marea$LdvEcoDrive
    NumHh <- length(L$Year$Household$HhId)
    IsEcoDrive_Hh <-
      sample(c(1, 0), NumHh, replace = TRUE, prob = c(EcoDriveProb, 1 - EcoDriveProb))
    rm(EcoDriveProb, NumHh)
  } else {
    IsEcoDrive_Hh <- L$Year$Household$IsEcoDrive
  }
  #Identify all vehicles of eco-driving households as eco-drive
  IsEcoDr_Ve <- IsEcoDrive_Hh[VehToHhMatch_Ve] == 1
  #Calculate joint eco-drive and speed-smoothing factors
  EcoSmooth_Ve <- rep(1, length(IsEcoDr_Ve))
  EcoSmooth_Ve[IsMetro_] <- L$Year$Marea$LdvSpdSmoothFactor
  EcoSmooth_Ve[IsEcoDr_Ve] <- L$Year$Marea$LdvEcoDriveFactor

  #Identify congestion factors
  #---------------------------
  MpgCongFactor_Ve <- MpkwhCongFactor_Ve <- rep(1, NumVeh)
  Powertrain_Ve <- L$Year$Vehicle$Powertrain
  #ICEV congestion factors
  MpgCongFactor_Ve[IsMetro_ & Powertrain_Ve == "ICEV"] <- L$Year$Marea$LdIceFactor
  MpkwhCongFactor_Ve[IsMetro_ & Powertrain_Ve == "ICEV"] <- 1
  #HEV congestion factors
  MpgCongFactor_Ve[IsMetro_ & Powertrain_Ve == "HEV"] <- L$Year$Marea$LdHevFactor
  MpkwhCongFactor_Ve[IsMetro_ & Powertrain_Ve == "HEV"] <- 1
  #BEV congestion factors
  MpgCongFactor_Ve[IsMetro_ & Powertrain_Ve == "BEV"] <- 1
  MpkwhCongFactor_Ve[IsMetro_ & Powertrain_Ve == "BEV"] <- L$Year$Marea$LdEvFactor
  #PHEV congestion factors
  MpgCongFactor_Ve[IsMetro_ & Powertrain_Ve == "PHEV"] <- L$Year$Marea$LdHevFactor
  MpkwhCongFactor_Ve[IsMetro_ & Powertrain_Ve == "PHEV"] <- L$Year$Marea$LdEvFactor

  #Calculate adjusted MPG and MPKWH
  #--------------------------------
  MPG_Ve <- L$Year$Vehicle$MPG
  MPG_Ve[MPG_Ve == 0] <- NA
  MPKWH_Ve <- L$Year$Vehicle$MPKWH
  MPKWH_Ve[MPKWH_Ve == 0] <- NA
  AdjMpg_Ve <- MPG_Ve * EcoSmooth_Ve * MpgCongFactor_Ve
  AdjMpkwh_Ve <- MPKWH_Ve * EcoSmooth_Ve * MpkwhCongFactor_Ve

  #Calculate vehicle fuel/energy consumption
  #-----------------------------------------
  GGE_Ve <- L$Year$Vehicle$Dvmt * (1 - ElecDvmtProp_Ve) / AdjMpg_Ve
  GGE_Ve[is.na(GGE_Ve)] <- 0
  FuelMJ_Ve <- convertUnits(GGE_Ve, "compound", "GGE", "MJ")$Values
  KWH_Ve <- L$Year$Vehicle$Dvmt * ElecDvmtProp_Ve / AdjMpkwh_Ve
  KWH_Ve[is.na(KWH_Ve)] <- 0
  ElecMJ_Ve <- convertUnits(KWH_Ve, "compound", "KWH", "MJ")$Values

  #Calculate vehicle carbon emissions
  #----------------------------------
  #Calculate hydrocarbon fuel CO2e in grams
  FuelCO2e_Ve <- numeric(NumVeh)
  FuelCO2e_Ve[L$Year$Vehicle$Type == "Auto"] <-
    FuelMJ_Ve[L$Year$Vehicle$Type == "Auto"] * L$Year$Region$HhAutoFuelCI
  FuelCO2e_Ve[L$Year$Vehicle$Type == "LtTrk"] <-
    FuelMJ_Ve[L$Year$Vehicle$Type == "LtTrk"] * L$Year$Region$HhLtTrkFuelCI
  FuelCO2e_Ve[is.na(FuelCO2e_Ve)] <- 0
  #Calculate electricity CO2e in grams
  ElecCI_Ve <-
    L$Year$Azone$ElectricityCI[match(L$Year$Vehicle$Azone, L$Year$Azone$Azone)]
  ElecCO2e_Ve <- ElecMJ_Ve * ElecCI_Ve
  #Calculate total CO2e in grams
  CO2e_Ve <- FuelCO2e_Ve + ElecCO2e_Ve

  #Calculate household fuel/energy consumption and carbon emissions
  #----------------------------------------------------------------
  GGE_Hh <- tapply(GGE_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  GGE_Hh[is.na(GGE_Hh)] <- 0
  KWH_Hh <- tapply(KWH_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  KWH_Hh[is.na(KWH_Hh)] <- 0
  CO2e_Hh <- tapply(CO2e_Ve, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
  CO2e_Hh[is.na(CO2e_Hh)] <- 0

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    IsEcoDrive = as.integer(IsEcoDrive_Hh),
    GGE = as.vector(GGE_Hh),
    KWH = as.vector(KWH_Hh),
    CO2e = as.vector(CO2e_Hh)
  )
  Out_ls$Year$Vehicle <- list(
    GGE = GGE_Ve,
    KWH = KWH_Ve,
    CO2e = CO2e_Ve
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
# load("data/EnergyEmissionsDefaults_ls.rda")
# attach(EnergyEmissionsDefaults_ls)
# TestDat_ <- testModule(
#   ModuleName = "CalculateHhEnergyAndEmissions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# TestOut_ls <- CalculateHhEnergyAndEmissions(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# load("data/EnergyEmissionsDefaults_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "CalculateHhEnergyAndEmissions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
# setwd("tests")
# untar("Datastore.tar")
# setwd("..")

