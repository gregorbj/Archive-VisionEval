#=========================
#AdjustHhVehicleMpgMpkwh.R
#=========================

#<doc>
#
## AdjustHhVehicleMpgMpkwh Module
#### January 23, 2019
#
#This module adjusts the fuel economy (MPG) and power efficiency (MPKWH) of household vehicles to reflect the effects of congestion, speed smoothing, and eco-driving that are calculated by the CalculateMpgMpkwhAdjustments module.
#
### Model Parameter Estimation
#
#This module has no estimated parameters
#
### How the Module Works
#
#The module adjusts the average MPG and MPKWH of household vehicles, including the car services used, to reflect the effects of congestion, speed smoothing, and eco-driving. The methods are described below. To simplify the presentation, all adjustments are referred to as fuel economy (FE) adjustments.
#
#* **Calculate household vehicle FE adjustments to reflect congestion**: FE adjustments are calculated for each household vehicle as a function of the vehicle powertrain type and the proportion of the household's travel that is assigned to urban roads. If the vehicle powertrain is ICEV, the LdIceFactor is used to calculate MPG adjustments. The urban travel adjustment factor is the marea value and the rural travel adjustment is the regional value. These values are averaged using the urban and non-urban travel proportions for the household. If the vehicle powertrain is HEV, the urban and non-urban LdHevFactor values are used to calculate the MPG adjustment. If the vehicle powertrain is BEV, the urban and non-urban LdEvFactor values are used to calculate the MPKWH adjustment. If the vehicle powertrain is PHEV, the urban and non-urban LdHevFactor values are used to calculate the MPG adjustment and the urban and non-urban LdEvFactor values are used to calculate the MPKWH adjustment.
#
#* **Calculate car service FE adjustments to reflect congestion**: Fleetwide FE adjustments are calculated for car service vehicles. The car service powertrains are classified as ICEV, HEV, and BEV. The relative powertrain proportions for car service autos and light trucks are loaded from the PowertrainFuelDefaults_ls in the PowertrainsAndFuels package version used in the model run. The MPG adjustment factor for car service autos is calculated by averaging the marea LdIceFactor and LdHevFactor values using the scaled ICEV and HEV proportions for automobiles. The MPG adjustment for light-trucks is calculated in a similar fashion. These average MPG adjustment factors are applied to the household vehicles listed as car service according to the vehicle type. The marea value for LdEvFactor is assigned to the MPKWH adjustment factor.
#
#* **Calculate eco-driving adjustments**: Eco-driving households are assigned at random in sufficient numbers to satisfy the 'LdvEcoDrive' proportion specified for the marea in the 'marea_speed_smooth_ecodrive.csv' input file. For the ICEV vehicles owned by the eco-driving households, the eco-drive MPG adjustment factor is calculated by averaging the marea LdvEcoDrive factor and regional LdvEcoDrive factors with urban and non-urban DVMT proportions for the household. Eco-driving adjustments for non-eco-driving household vehicles and non-ICEV vehicles are set equal to 1.
#
#* **Calculate speed smoothing adjustments**: The speed smoothing adjustment for urban travel is the marea LdvSpdSmoothFactor value. The non-urban value is 1. The value for each household is the average of the urban and non-urban speed smoothing adjustments using the household urban and rural travel proportions as the respective weights. The household average values are assigned to the household vehicles. As with eco-driving, the speed smoothing adjustments are only applied to ICEV vehicles.
#
#* **Reconcile eco-driving and speed smoothing adjustments**: The maximum of the eco-driving and speed smoothing adjustments assigned to each vehicle is used to account for the joint effect of eco-driving and speed smoothing.
#
#* **Calculate the joint effect of congestion adjustments and eco-driving & speed smoothing adjustments**: The joint effect of the congestion-related FE adjustment and the eco-driving & speed smoothing adjustment is the product of the two adjustments.
#
#* **Calculate the adjusted MPG and MPKWH**: The MPG assigned to each vehicle is updated by multiplying its value by the MPG adjustment value assigned to the vehicle. Likewise, the MPKWH assigned to each vehicle is updated by multiplying its value by the MPKWH adjustment value assigned to the vehicle.
#
#* **Adjust related vehicle fuel, energy, and emissions values**: The GPM (gallons per mile) values are updated by calculating the reciprocal of the updated MPG values. The ratio of the updated GPM value to the previous GPM value is used to scale the fuel emissions rate (FuelCO2ePM). Likewise the KWHPM (kilowatt-hours per mile) values are updated in the same way and so is the electricity emissions rate (ElecCO2ePM).
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AdjustHhVehicleMpgMpkwhSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = items(
        "LdvEcoDriveFactor",
        "LdIceFactor",
        "LdHevFactor",
        "LdEvFactor"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = "<= 0",
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
      NAME = "Marea",
      TABLE = "Azone",
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
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    ),
    item(
      NAME = items(
        "Vehicles",
        "NumAuto",
        "NumLtTrk"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanDvmtProp",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      NAME =
        items("HhId",
              "VehId"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
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
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("ICEV", "HEV", "PHEV", "BEV", "NA")
    ),
    item(
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc")
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
      NAME = "GPM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GGE/MI",
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
      NAME = "KWHPM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "MPGe",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ElecDvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "FuelCO2ePM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ElecCO2ePM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "MPG",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average miles of vehicle travel powered by fuel per gasoline equivalent gallon"
    ),
    item(
      NAME = "GPM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GGE/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average gasoline equivalent gallons per mile of vehicle travel powered by fuel"
    ),
    item(
      NAME = "MPKWH",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/KWH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average miles of vehicle travel powered by electricity per kilowatt-hour"
    ),
    item(
      NAME = "KWHPM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average kilowatt-hours per mile of vehicle travel powered by electricity"
    ),
    item(
      NAME = "MPGe",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average miles of vehicle travel per gasoline equivalent gallon (fuel and electric powered)"
    ),
    item(
      NAME = "ElecDvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average miles of vehicle travel per gasoline equivalent gallon (fuel and electric powered)"
    ),
    item(
      NAME = "FuelCO2ePM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average grams of carbon-dioxide equivalents produced per mile of travel powered by fuel"
    ),
    item(
      NAME = "ElecCO2ePM",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average grams of carbon-dioxide equivalents produced per mile of travel powered by electricity"
    ),
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
    )
  ),
  #Specify call status of module
  Call = items(
    CalcDvmt = "CalculateHouseholdDvmt"
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AdjustHhVehicleMpgMpkwh module
#'
#' A list containing specifications for the AdjustHhVehicleMpgMpkwh module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AdjustHhVehicleMpgMpkwh.R script.
"AdjustHhVehicleMpgMpkwhSpecifications"
usethis::use_data(AdjustHhVehicleMpgMpkwhSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function adjusts the energy efficiency and emissions of household vehicles
#to reflect roadway congestion, speed smoothing, and ecodriving.

#Main module function that adjusts energy efficiency of household vehicles
#-------------------------------------------------------------------------
#' Adjust energy efficiency and emissions rates of vehicles used by households.
#'
#' \code{AdjustHhVehicleMpgMpkwh} adjusts the energy efficiency and emissions of
#' vehicles used by households.
#'
#' This function adjusts the energy efficiency and emissions of
#' vehicles used by households as a consequence of roadway congestion, speed
#' smoothing, and ecodriving.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @param M A list the module functions of modules called by this module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AdjustHhVehicleMpgMpkwh
#' @import visioneval
#' @export
#'
AdjustHhVehicleMpgMpkwh <- function(L, M) {

  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Match index from households to vehicles
  HhToVehIdx_Ve <- match(L$Year$Vehicle$HhId, L$Year$Household$HhId)
  #Number of vehicles
  NumVeh <- length(L$Year$Vehicle$VehId)
  #Powertrains of vehicles
  Powertrain_Ve <- L$Year$Vehicle$Powertrain
  #Load energy and emissions defaults
  EnergyEmissionsDefaults_ls <- loadPackageDataset("PowertrainFuelDefaults_ls")

  #Identify congestion factors for household-owned vehicles
  #--------------------------------------------------------
  UrbanProp_Ve <- L$Year$Household$UrbanDvmtProp[HhToVehIdx_Ve]
  MpgCongFactor_Ve <- rep(1, NumVeh)
  MpkwhCongFactor_Ve <- rep(1, NumVeh)
  #Function to calculate congestion factors to apply to vehicles
  calcVehCongFactor <- function(FactorName, UrbanProp_) {
    UrbanFactor <- L$Year$Marea[[FactorName]]
    NonUrbanFactor <- L$Year$Region[[FactorName]]
    UrbanFactor * UrbanProp_ + NonUrbanFactor * (1 - UrbanProp_)
  }
  #ICEV congestion factors
  MpgCongFactor_Ve[Powertrain_Ve == "ICEV"] <-
    calcVehCongFactor("LdIceFactor", UrbanProp_Ve[Powertrain_Ve == "ICEV"])
  MpkwhCongFactor_Ve[Powertrain_Ve == "ICEV"] <- 1
  #HEV congestion factors
  MpgCongFactor_Ve[Powertrain_Ve == "HEV"] <-
    calcVehCongFactor("LdHevFactor", UrbanProp_Ve[Powertrain_Ve == "HEV"])
  MpkwhCongFactor_Ve[Powertrain_Ve == "HEV"] <- 1
  #BEV congestion factors
  MpgCongFactor_Ve[Powertrain_Ve == "BEV"] <- 1
  MpkwhCongFactor_Ve[Powertrain_Ve == "BEV"] <-
    calcVehCongFactor("LdEvFactor", UrbanProp_Ve[Powertrain_Ve == "BEV"])
  #PHEV congestion factors
  MpgCongFactor_Ve[Powertrain_Ve == "PHEV"] <-
    calcVehCongFactor("LdHevFactor", UrbanProp_Ve[Powertrain_Ve == "PHEV"])
  MpkwhCongFactor_Ve[Powertrain_Ve == "PHEV"] <-
    calcVehCongFactor("LdEvFactor", UrbanProp_Ve[Powertrain_Ve == "PHEV"])

  #Calculate congestion factors for car service vehicles assigned to households
  #----------------------------------------------------------------------------
  #Identify which vehicles are car service
  IsCarSvc_Ve <- L$Year$Vehicle$VehicleAccess != "Own"
  #Retrieve car service powertrain proportions
  CSPwrtnNames_ <-
    c("AutoPropIcev", "AutoPropHev", "AutoPropBev",
      "LtTrkPropIcev", "LtTrkPropHev", "LtTrkPropBev")
  CSPwrtnProp_ <- numeric(length(CSPwrtnNames_))
  names(CSPwrtnProp_) <- CSPwrtnNames_
  for (nm in CSPwrtnNames_) {
    if (!is.null(L$Year$Region[[paste0("CarSvc", nm)]])) {
      CSPwrtnProp_[nm] <- L$Year$Region[[paste0("CarSvc", nm)]]
    } else {
      CSPwrtnProp_[nm] <- approx(
        EnergyEmissionsDefaults_ls$CarSvcPowertrain_df$Year,
        EnergyEmissionsDefaults_ls$CarSvcPowertrain_df[[nm]],
        L$G$Year
      )$y
    }
  }
  #Function to calculate MPG adjustment factor by vehicle type
  calcAveCarSvcMpgCongFactor <- function(Type) {
    PtNames_ <- paste0(Type, c("PropIcev", "PropHev"))
    PtProp_ <- CSPwrtnProp_[PtNames_]
    PtProp_ <- PtProp_ / sum(PtProp_)
    Factors_ <- with(L$Year$Marea, c(LdIceFactor, LdHevFactor))
    sum(PtProp_ * Factors_)
  }
  #Calculate MPG adjustment factors for car service autos
  Sel_ <- IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"
  MpgCongFactor_Ve[Sel_] <- calcAveCarSvcMpgCongFactor("Auto")
  #Calculate MPG adjustment factors for car service light trucks
  Sel_ <- IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"
  MpgCongFactor_Ve[Sel_] <- calcAveCarSvcMpgCongFactor("LtTrk")
  rm(Sel_, calcAveCarSvcMpgCongFactor)
  #Calculate MPKWH adjustment factor by vehicle type
  MpkwhCongFactor_Ve[IsCarSvc_Ve] <- L$Year$Marea$LdEvFactor
  #Clean up
  rm(CSPwrtnNames_, CSPwrtnProp_)

  #Identify eco-driving and speed smoothing factors to adjust MPG & MPKWH
  #----------------------------------------------------------------------
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
  #Create matrix of urban and non-urban DVMT proportions of households
  UrbanDrProp_HhX <- cbind(
    Urban = L$Year$Household$UrbanDvmtProp,
    NonUrban = 1 - L$Year$Household$UrbanDvmtProp
  )
  #Calculate eco-drive factor for households
  EcoDrFactor_ <- c(
    Urban = L$Year$Marea$LdvEcoDriveFactor,
    NonUrban = L$Year$Region$LdvEcoDriveFactor)
  EcoDrFactor_Hh <- rowSums(sweep(UrbanDrProp_HhX, 2, EcoDrFactor_, "*"))
  EcoDrFactor_Hh[!IsEcoDrive_Hh] <- 1
  #Assign eco-drive factor to vehicles
  EcoDriveFactor_Ve <- EcoDrFactor_Hh[HhToVehIdx_Ve]
  rm(EcoDrFactor_, EcoDrFactor_Hh)
  #Calculate speed-smoothing factors and apply to vehicles
  SpdSmFactor_ <- c(
    Urban = L$Year$Marea$LdvSpdSmoothFactor,
    NonUrban = 1
  )
  SpdSmFactor_Hh <- rowSums(sweep(UrbanDrProp_HhX, 2, SpdSmFactor_, "*"))
  #Assign speed smooth factor to vehicles
  SpdSmFactor_Ve <- SpdSmFactor_Hh[HhToVehIdx_Ve]
  rm(SpdSmFactor_, SpdSmFactor_Hh)
  #Create a combined eco-drive speed smooth that is the maximum improvement
  EcoSmooth_Ve <- pmax(EcoDriveFactor_Ve, SpdSmFactor_Ve)
  #Set eco-smooth factor of non-ICE vehicles to 1
  EcoSmooth_Ve[Powertrain_Ve != "ICEV"] <- 1
  rm(EcoDriveFactor_Ve, SpdSmFactor_Ve)

  #Calculate adjusted MPG and MPKWH
  #--------------------------------
  MPG_Ve <- L$Year$Vehicle$MPG * EcoSmooth_Ve * MpgCongFactor_Ve
  MPKWH_Ve <- L$Year$Vehicle$MPKWH * MpkwhCongFactor_Ve

  #Adjust fuel consumption, electricity consumption, and GHG per mile
  #------------------------------------------------------------------
  #Calculate the adjusted GPM
  GPM_Ve <- 1 / MPG_Ve
  GPM_Ve[MPG_Ve == 0] <- 0
  #Calculate the ratio of adjusted to unadjusted GPM
  GPMRatio_Ve <- GPM_Ve / L$Year$Vehicle$GPM
  GPMRatio_Ve[L$Year$Vehicle$GPM == 0] <- 0
  #Adjust carbon intensity per mile by GPM ratio
  FuelCO2ePM_Ve <- L$Year$Vehicle$FuelCO2ePM * GPMRatio_Ve
  #Calculate adjusted kilowatt-hours per mile
  KWHPM_Ve <- 1 / MPKWH_Ve
  KWHPM_Ve[MPKWH_Ve == 0] <- 0
  #Calculate the ratio of adjusted to unadjusted KWHPM
  KWHRatio_Ve <- KWHPM_Ve / L$Year$Vehicle$KWHPM
  KWHRatio_Ve[L$Year$Vehicle$KWHPM == 0] <- 0
  #Calculate carbon intensity for elect ricity consumption
  ElecCO2ePM_Ve <- L$Year$Vehicle$ElecCO2ePM * KWHRatio_Ve

  #Calculate MPGe
  #--------------
  ElecDvmtProp_Ve <- L$Year$Vehicle$ElecDvmtProp
  MPGe_Ve <-
    MPG_Ve * (1 - ElecDvmtProp_Ve) +
    convertUnits(MPKWH_Ve, "compound", "MI/KWH", "MI/GGE")$Values * ElecDvmtProp_Ve

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list(
    MPG = MPG_Ve,
    GPM = GPM_Ve,
    MPKWH = MPKWH_Ve,
    KWHPM = KWHPM_Ve,
    MPGe = MPGe_Ve,
    FuelCO2ePM = FuelCO2ePM_Ve,
    ElecCO2ePM = ElecCO2ePM_Ve,
    ElecDvmtProp = ElecDvmtProp_Ve
  )
  Out_ls$Year$Household <- list(
    IsEcoDrive = as.integer(IsEcoDrive_Hh)
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
#   ModuleName = "AdjustHhVehicleMpgMpkwh",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# M <- TestDat_$M
# TestOut_ls <- AdjustHhVehicleMpgMpkwh(L, M)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AdjustHhVehicleMpgMpkwh",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
#
# setwd("tests")
# untar("Datastore.tar")
# setwd("..")

