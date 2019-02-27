#==================================
#CalculatePtranEnergyAndEmissions.R
#==================================

#<doc>
#
## CalculatePtranEnergyAndEmissions Module
#### January 23, 2019
#
#This module calculates the energy consumption and carbon emissions from public transportation vehicles in urbanized areas. Note that fuel consumption and emissions from car services (e.g. taxi, Uber, Lyft) are calculated in conjunction with the calculation of household vehicle emissions and are attributed to the household.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#This module calculates the energy consumption and carbon emissions production public transit vehicles in urbanized areas in the following steps:
#
#* The energy consumption characteristics (i.e. MPG, MPKWH) by vehicle type (van, bus, rail) and powertrain type (ICEV, HEV, BEV, EV) are loaded (these are default values set up in the version of the 'VEPowertrainAndFuels' package used to represent the vehicles and fuels scenario being modeled).
#
#* Energy consumption and emissions for each vehicle type and marea are calculated by the following steps:
#
#  * Get the DVMT for the vehicle type by marea produced by the 'AssignTransitService' module
#
#  * Allocate DVMT for the type and marea to powertrains using the powertrain proportions that are default values or user inputs ('Initialize' module of 'VEPowertrainsAndFuels' package).
#
#  * Calculate energy consumption for the vehicle type by powertrain type using the DVMT by powertrain type and the energy consumption characteristics (MPG, MPKWH) for the powertrain type. Energy consumption for ICEV and HEV vehicles is calculated in gas gallon equivalents (GGE) while energy consumption for BEV and EV vehicles are in kilowatt hours (KWH). Convert to equivalent megajoule (MJ) values.
#
#  * Get the average carbon intensity of fuels for the vehicle type by marea and the average carbon intensity of electricity production by azone that are either default values or user inputs ('Initialize' module of the 'VEPowertrainsAndFuels' package). Multiply the carbon intensities by energy type and the energy consumption by type and sum to calculate the carbon emissions for the vehicle type by marea.
#
#  * Calculate the average emissions per mile by marea for the vehicle type from the total emissions by marea for the vehicle type and the DVMT for the vehicle type by marea.
#
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#No module parameters are estimated in this module.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculatePtranEnergyAndEmissionsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
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
      NAME = "Marea",
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
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "BusDvmt",
        "RailDvmt",
        "VanDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = "<= 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "BusPropBev",
          "BusPropHev",
          "BusPropIcev",
          "RailPropEv",
          "RailPropHev",
          "RailPropIcev",
          "VanPropBev",
          "VanPropHev",
          "VanPropIcev"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = items(
        "BusGGE",
        "RailGGE",
        "VanGGE"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "energy",
      UNITS = "GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average daily amount of hydrocarbon fuels consumed by bus transit vehicles in urbanized area in gas gallon equivalents",
        "Average daily amount of hydrocarbon fuels consumed by rail transit vehicles in urbanized area in gas gallon equivalents",
        "Average daily amount of hydrocarbon fuels consumed by van transit vehicles in urbanized area in gas gallon equivalents")
    ),
    item(
      NAME = items(
        "BusKWH",
        "RailKWH",
        "VanKWH"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "energy",
      UNITS = "KWH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average daily amount of electricity consumed by bus transit vehicles in urbanized area in kilowatt-hours",
        "Average daily amount of electricity consumed by rail transit vehicles in urbanized area in kilowatt-hours",
        "Average daily amount of electricity consumed by van transit vehicles in urbanized area in kilowatt-hours")
    ),
    item(
      NAME = items(
        "BusCO2e",
        "RailCO2e",
        "VanCO2e"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average daily amount of carbon-dioxide equivalents produced by bus transit vehicles in urbanized area in grams",
        "Average daily amount of carbon-dioxide equivalents produced by rail transit vehicles in urbanized area in grams",
        "Average daily amount of carbon-dioxide equivalents produced by van transit vehicles in urbanized area in grams")
    ),
    item(
      NAME = items(
        "BusCO2eRate",
        "RailCO2eRate",
        "VanCO2eRate"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average amount of carbon-dioxide equivalents produced by bus transit vehicles per mile of travel in urbanized area in grams per mile",
        "Average amount of carbon-dioxide equivalents produced by rail transit vehicles per mile of travel in urbanized area in grams per mile",
        "Average amount of carbon-dioxide equivalents produced by van transit vehicles per mile of travel in urbanized area in grams per mile")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculatePtranEnergyAndEmissions module
#'
#' A list containing specifications for the CalculatePtranEnergyAndEmissions
#' module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculatePtranEnergyAndEmissions.R script.
"CalculatePtranEnergyAndEmissionsSpecifications"
usethis::use_data(CalculatePtranEnergyAndEmissionsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that calculates public transit energy and emissions
#------------------------------------------------------------------------
#' Calculate energy and emissions of public transit vehicle travel.
#'
#' \code{CalculatePtranEnergyAndEmissions} calculates the hydrocarbon and
#' electrical energy consumption of the travel of public transit vehicles.
#'
#' This function calculates the hydrocarbon and electrical energy consumption of
#' the travel of public transit vehicles and the carbon emissions produced.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name CalculatePtranEnergyAndEmissions
#' @import visioneval
#' @export
#'
CalculatePtranEnergyAndEmissions <- function(L) {

  #Set up
  #------
  Ma <- L$Year$Marea$Marea
  Pt <- c("ICEV", "HEV", "BEV")
  Year <- L$G$Year
  EnergyEmissionsDefaults_ls <- loadPackageDataset("PowertrainFuelDefaults_ls")

  #Calculate the transit powertrain characteristics for the year
  #---------------------------------------------------------------
  PtChar_ <- local({
    PtranChar_df <-
      EnergyEmissionsDefaults_ls$TransitPowertrainCharacteristics_df[,-1]
    Years_ <-
      EnergyEmissionsDefaults_ls$TransitPowertrainCharacteristics_df$Year
    apply(PtranChar_df, 2, function(x) {
      approx(Years_, x, as.numeric(Year))$y
    })
  })

  #Define function to calculate energy and emissions for a transit vehicle type
  #----------------------------------------------------------------------------
  calcPtranEE <- function(Type) {
    #Calculate bus DVMT by Marea and powertrain
    Dvmt_Ma <- L$Year$Marea[[paste0(Type, "Dvmt")]]
    names(Dvmt_Ma) <- Ma
    if (Type == "Rail") {
      DvmtProp_MaPt <- as.matrix(data.frame(
        ICEV = L$Year$Marea[["RailPropIcev"]],
        HEV = L$Year$Marea[["RailPropHev"]],
        EV = L$Year$Marea[["RailPropEv"]]
      ))
    } else {
      DvmtProp_MaPt <- as.matrix(data.frame(
        ICEV = L$Year$Marea[[paste0(Type, "PropIcev")]],
        HEV = L$Year$Marea[[paste0(Type, "PropHev")]],
        BEV = L$Year$Marea[[paste0(Type, "PropBev")]]
      ))
    }
    rownames(DvmtProp_MaPt) <- Ma
    Dvmt_MaPt <- sweep(DvmtProp_MaPt, 1, Dvmt_Ma, "*")
    #Calculate energy by Marea and powertrain
    if (Type == "Rail") {
      MpgMpkwh_Pt <- c(
        ICEV = unname(PtChar_["RailIcevMpg"]),
        HEV = unname(PtChar_["RailHevMpg"]),
        EV = unname(PtChar_["RailEvMpkwh"])
      )
    } else {
      MpgMpkwh_Pt <- c(
        ICEV = unname(PtChar_[paste0(Type, "IcevMpg")]),
        HEV = unname(PtChar_[paste0(Type, "HevMpg")]),
        BEV = unname(PtChar_[paste0(Type, "BevMpkwh")])
      )
    }
    Energy_MaPt <- sweep(Dvmt_MaPt, 2, MpgMpkwh_Pt, "/")
    Et <- c("GGE", "KWH")
    Energy_MaEt <- array(0, dim = c(length(Ma), 2), dimnames = list(Ma, Et))
    for (ma in Ma) {
      Energy_MaEt[ma,] <- c(sum(Energy_MaPt[ma, 1:2]), Energy_MaPt[ma,3])
    }
    #Convert energy into megajoules
    EnergyMJ_MaEt <- Energy_MaEt * 0
    for (ma in Ma) {
      EnergyMJ_MaEt[ma,] <- c(
        convertUnits(Energy_MaEt[ma,1], "energy", "GGE", "MJ")$Values,
        convertUnits(Energy_MaEt[ma,2], "energy", "KWH", "MJ")$Values
        )
    }
    #Calculate carbon intensity by fuel type and Marea
    CI_MaEt <- EnergyMJ_MaEt * 0
    CI_MaEt[,2] <- tapply(L$Year$Azone$ElectricityCI, L$Year$Azone$Marea, mean)[Ma]
    CI_MaEt[,1] <- L$Year$Marea[[paste0("Transit", Type, "FuelCI")]]
    #Calculate CO2e emissions
    CO2e_MaEt <- EnergyMJ_MaEt * CI_MaEt
    CO2e_MaEt[is.na(CO2e_MaEt)] <- 0
    CO2e_Ma <- apply(CO2e_MaEt, 1, sum)
    #Calculate CO2e rate
    CO2eRate_Ma <- Dvmt_Ma
    HasDvmt <- Dvmt_Ma != 0
    CO2eRate_Ma[HasDvmt] <- CO2e_Ma[HasDvmt] / Dvmt_Ma[HasDvmt]
    #Return the result
    list(
      Energy = Energy_MaEt,
      CO2e = CO2e_MaEt,
      CO2eRate = CO2eRate_Ma
    )
  }

  #Calculate energy and emissions by transit vehicle type
  #------------------------------------------------------
  BusEE_ls <- calcPtranEE("Bus")
  RailEE_ls <- calcPtranEE("Rail")
  VanEE_ls <- calcPtranEE("Van")

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year <- list()
  Out_ls$Year$Marea <- list(
    BusGGE = BusEE_ls$Energy[,"GGE"],
    RailGGE = RailEE_ls$Energy[,"GGE"],
    VanGGE = VanEE_ls$Energy[,"GGE"],
    BusKWH = BusEE_ls$Energy[,"KWH"],
    RailKWH = RailEE_ls$Energy[,"KWH"],
    VanKWH = VanEE_ls$Energy[,"KWH"],
    BusCO2e = apply(BusEE_ls$CO2e, 1, sum),
    RailCO2e = apply(RailEE_ls$CO2e, 1, sum),
    VanCO2e = apply(VanEE_ls$CO2e, 1, sum),
    BusCO2eRate = BusEE_ls$CO2eRate,
    RailCO2eRate = RailEE_ls$CO2eRate,
    VanCO2eRate = VanEE_ls$CO2eRate
  )
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculatePtranEnergyAndEmissions")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load libraries and test functions
# library(visioneval)
# library(filesstrings)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-RSPM",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "verspm",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "CalculatePtranEnergyAndEmissions",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE,
#   RequiredPackages = "VEPowertrainsAndFuels"
# )
# L <- TestDat_$L
# R <- CalculatePtranEnergyAndEmissions(L)
#
# TestDat_ <- testModule(
#   ModuleName = "CalculatePtranEnergyAndEmissions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RequiredPackages = "VEPowertrainsAndFuels"
# )
