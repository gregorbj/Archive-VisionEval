#=========================
#AdjustHhVehicleMpgMpkwh.R
#=========================
#This module adjusts the fuel economy and power efficiency of household vehicles
#to reflect roadway congestion.


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
    CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt"
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

  #Identify congestion factors for household-owned vehicles
  #--------------------------------------------------------
  IsMetro_Ve <- L$Year$Household$LocType[HhToVehIdx_Ve] == "Urban"
  MpgCongFactor_Ve <- rep(1, NumVeh)
  MpkwhCongFactor_Ve <- rep(1, NumVeh)
  #ICEV congestion factors
  MpgCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "ICEV"] <- L$Year$Marea$LdIceFactor
  MpkwhCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "ICEV"] <- 1
  #HEV congestion factors
  MpgCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "HEV"] <- L$Year$Marea$LdHevFactor
  MpkwhCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "HEV"] <- 1
  #BEV congestion factors
  MpgCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "BEV"] <- 1
  MpkwhCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "BEV"] <- L$Year$Marea$LdEvFactor
  #PHEV congestion factors
  MpgCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "PHEV"] <- L$Year$Marea$LdHevFactor
  MpkwhCongFactor_Ve[IsMetro_Ve & Powertrain_Ve == "PHEV"] <- L$Year$Marea$LdEvFactor

  #Calculate characteristics of car service vehicles
  #-------------------------------------------------
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
  #Calculate MPG congestion factors
  calcAveCarSvcMpgCongFactor <- function(Type) {
    PtNames_ <- paste0(Type, c("PropIcev", "PropHev"))
    PtProp_ <- CSPwrtnProp_[PtNames_]
    PtProp_ <- PtProp_ / sum(PtProp_)
    CongFactors_ <- c(L$Year$Marea$LdIceFactor, L$Year$Marea$LdHevFactor)
    sum(PtProp_ * CongFactors_)
  }
  MpgCongFactor_Ve[IsMetro_Ve & IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <-
    calcAveCarSvcMpgCongFactor("Auto")
  MpgCongFactor_Ve[IsMetro_Ve & IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"] <-
    calcAveCarSvcMpgCongFactor("LtTrk")
  #Calculate MPKWH congestion factors
  MpkwhCongFactor_Ve[IsMetro_Ve & IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <-
    L$Year$Marea$LdEvFactor
  #Clean up
  rm(CSPwrtnNames_, CSPwrtnProp_ ,calcAveCarSvcMpgCongFactor)

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
  #Identify eco-drive factor
  EcoDriveFactor_Ve <-
    IsEcoDrive_Hh[HhToVehIdx_Ve] * L$Year$Marea$LdvEcoDriveFactor
  #Create eco-drive/speed-smoothing factors and populate with smoothing factors
  IsMetro_Ve <- L$Year$Household$LocType[HhToVehIdx_Ve] == "Urban"
  EcoSmooth_Ve <- rep(1, NumVeh)
  EcoSmooth_Ve[IsMetro_Ve] <- L$Year$Marea$LdvSpdSmoothFactor
  #Substitute eco-drive factor where greater
  EcoSmooth_Ve <- pmax(EcoDriveFactor_Ve, EcoSmooth_Ve)

  #Calculate adjusted MPG and MPKWH
  #--------------------------------
  MPG_Ve <- L$Year$Vehicle$MPG * EcoSmooth_Ve * MpgCongFactor_Ve
  MPKWH_Ve <- L$Year$Vehicle$MPKWH * EcoSmooth_Ve * MpkwhCongFactor_Ve

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

