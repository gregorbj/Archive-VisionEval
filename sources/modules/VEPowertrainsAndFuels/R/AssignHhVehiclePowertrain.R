#=========================
#AssignVehiclePowertrain.R
#=========================
#This module assigns powertrain types to household vehicles. The powertrain
#types are internal combustion engine vehicle (ICEV), hybrid electric vehicle
#(HEV), plug-in hybrid electric vehicle (PHEV), and battery electric vehicles
#(BEV). Assignment of powertrains is done by vehicle type (Auto, LtTrk) and
#model year. For each type and model year, vehicles of that type and model
#year are assigned powertrains in the order of BEV, PHEV, HEV, and ICEV. The
#assignment of BEV is conditional on the whether the 95th percentile DVMT for
#the vehicle is within the battery range of the vehicle and whether charging the
#vehicle is possible at the residence. Charging possibilities are determined by
#household based on the housing type and charging availability by housing type
#by azone in the azone_charging_availability.csv input file. Charging
#availability is specified as a proportion of housing units that have chargers
#or could have chargers installed. It is assumed that if charging is available
#for a household, then all vehicles in the household have charging available. If
#there are not enough qualifying vehicles to match the charging and battery
#range assumptions, then the number of BEVs that can't be assigned are
#designated as PHEVs. The range criterion is not used in assigning PHEVs, but
#the charging criterion is. The PHEV designation is only assigned to vehicles
#where residential charging is available. If there are not enough qualifying
#vehicles, then the number of PHEVs that can't be assigned to a vehicle are
#designated as HEVs. There are no qualifications for HEVs and ICEVs and their
#numbers are assigned randomly to vehicles that have no assignment. Vehicle DVMT
#is a consideration for determining qualification for BEVs and for determining
#the proportion of the travel of PHEVs that is powered by electricity, however
#DVMT has not yet been assigned to vehicles at the time when this module is run
#because the assignment of DVMT depends on the availability of unit costs (i.e.
#cost per mile) and that depends on the fuel economy, power efficiency, and
#GHG emissions of each vehicle. What is done to get vehicle DVMT in this module
#is to take total household DVMT and divide it equally among all vehicles owned
#by the household. Given the powertrain designations, vehicle DVMT, and several
#other inputs, the module computes the MPG and MPKWH of each vehicle and adjusts
#it for ecodriving, speed smoothing, and congestion effects. It also computes
#GHG emissions per mile. The module also computes these quantities for car
#service vehicles assigned to each household.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#The MPG and MPkWh of household vehicles by looking up values from tables in
#the PowertrainFuelDefaults_ls created by the LoadDefaultValues module, and
#adjusting those values for the effects of travel speed. Carbon emissions rates
#are calculated based on the MPG or MPkWh of the vehicle and the average carbon
#intensity of fuel or electricity. The situation is more complicated for PHEVs
#because they comsume both fuel and electricity and the proportion of travel
#powered by each will differ depending on how much travel is powered by fuel
#vs electricity. A model is estimated to calculate those proportions.

#Load PowertrainFuelDefaults_ls to make it available as a global variable
load("./data/PowertrainFuelDefaults_ls.rda")


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
  #Create a smooth spline model of the prediction of DVMT by percentile
  Pctl_ <- c(seq(5, 95, 5), 99)
  Pctl_SS <- smooth.spline(Pctl_, DvmtByPctl_)
  #Calculate the percentile corresponding to the battery range
  Range_SS <- smooth.spline(DvmtByPctl_, Pctl_)
  RangePctl <- predict(Range_SS, Range)$y
  #Define function to get a prediction from the DVMT percentile smooth spline model
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
usethis::use_data(PhevElecProp_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignHhVehiclePowertrainSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = items(
        "PropSFChargingAvail",
        "PropMFChargingAvail",
        "PropGQChargingAvail"),
      FILE = "azone_charging_availability.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of single-family dwellings in Azone that have PEV charging facilties installed or able to be installed",
        "Proportion of multi-family dwelling units in Azone that have PEV charging facilities available",
        "Proportion of group quarters dwelling units in Azone that have PEV charging facilities available"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = items(
        "HhAutoFuelCI",
        "HhLtTrkFuelCI",
        "CarSvcAutoFuelCI",
        "CarSvcLtTrkFuelCI"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
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
      NAME = "Marea",
      TABLE = "Marea",
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
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "PropSFChargingAvail",
        "PropMFChargingAvail",
        "PropGQChargingAvail"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
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
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
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
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc")
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c("ICEV", "HEV", "PHEV", "BEV", "NA"),
      SIZE = 4,
      DESCRIPTION = "Vehicle powertrain type: ICEV = internal combustion engine vehicle, HEV = hybrid electric vehicle, PHEV = plug-in hybrid electric vehicle, BEV = battery electric vehicle, NA = not applicable because is a car service vehicle"
    ),
    item(
      NAME = "BatRng",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Miles of travel possible on fully charged battery"
    ),
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
    )
  ),
  #Specify call status of module
  Call = items(
    CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt",
    ReduceDvmt = "VEHouseholdTravel::ApplyDvmtReductions"
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignHhVehiclePowertrain module
#'
#' A list containing specifications for the AssignHhVehiclePowertrain module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignHhVehiclePowertrain.R script.
"AssignHhVehiclePowertrainSpecifications"
usethis::use_data(AssignHhVehiclePowertrainSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns powertrain types and several powertrain characteristics
#to household vehicles including:
#Powertrain - ICEV, HEV, PHEV, or BEV
#MPG - fuel economy for the vehicle powertrain, type, and model year for travel
#that is powered by gasoline or other fuel. It is 0 for BEV.
#MPKWH - electric energy efficiency for the vehicle powertrain, type, and model
#year for travel that is powered by stored electricity. It is 0 for ICEV and
#HEV.
#MPGe - Miles per gasoline equivalent gallon for all vehicles where travel using
#stored electricity is converted into gasoline gallon equivalents (based on
#energy content) and the average is calculated by weighting by the proportions
#of vehicle travel using stored electricity and not using stored electricity.
#The proportion of travel using electricity is calculated by split average DVMT
#equally across all household vehicles and comparing to the battery range of the
#vehicle.
#BatRng - The battery range of the vehicle in miles.

#Main module function that household vehicle powertrain type
#-----------------------------------------------------------
#' Assign powertrain types to household vehicles.
#'
#' \code{AssignHhVehiclePowertrain} assigns the powertrain type to each household
#' vehicle.
#'
#' This function assigns the powertrain type (ICEV, HEV, PHEV, BEV) to each
#' household vehicle.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @param M A list the module functions of modules called by this module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignHhVehiclePowertrain
#' @import visioneval VEHouseholdTravel stats
#' @export
#'
AssignHhVehiclePowertrain <- function(L, M) {

  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  if(!exists("PowertrainFuelDefaults_ls")){
    PowertrainFuelDefaults_ls <- VEPowertrainsAndFuels::PowertrainFuelDefaults_ls
  }
  #Match index from households to vehicles
  HhToVehIdx_Ve <- match(L$Year$Vehicle$HhId, L$Year$Household$HhId)

  #Set up matrices of vehicle powertrain data for owned vehicles
  #-------------------------------------------------------------
  #Define naming vectors for vehicle types, powertrains, and model years
  Ty <- c("Auto", "LtTrk")
  Pt <- c("ICEV", "HEV", "PHEV", "BEV") #Powertrains
  My <- as.character(PowertrainFuelDefaults_ls$HhPowertrain_df$ModelYear)
  #Create array of auto and light truck powertrain proportions by model year
  Prop_MyPtTy <-
    array(0,
          dim = c(length(My), length(Pt), length(Ty)),
          dimnames = list(My, Pt, Ty))
  Cols_ <- c("PropIcev", "PropHev", "PropPhev", "PropBev")
  Prop_MyPtTy[,,"Auto"] <-
    as.matrix(PowertrainFuelDefaults_ls$HhPowertrain_df[, paste0("Auto", Cols_)])
  Prop_MyPtTy[,,"LtTrk"] <-
    as.matrix(PowertrainFuelDefaults_ls$HhPowertrain_df[, paste0("LtTrk", Cols_)])
  rm(Cols_)

  #Calculate DVMT per vehicle and 95th percentile DVMT per vehicle
  #---------------------------------------------------------------
  #Used to determine which vehicles qualify as BEV and also the proportion of
  #PHEV mileage powered by electricity
  #Run the household DVMT model
  Dvmt_ls <- M$CalcDvmt(L$CalcDvmt)
  #Calculate ratio of 95th percentile DVMT to average
  Dvmt95thFactor_Hh <- with(Dvmt_ls$Year$Household, Dvmt95th / Dvmt)
  #Reduce DVMT to account for TDM and SOV reductions
  L$ReduceDvmt$Year$Household$Dvmt <- Dvmt_ls$Year$Household$Dvmt
  Dvmt_Hh <- M$ReduceDvmt(L$ReduceDvmt)$Year$Household$Dvmt
  #Calculate DVMT of owned vehicles assuming that all household DVMT is split
  #equally over owned vehicles
  Dvmt_Ve <- local({
    NumOwned_Hh <- with(L$Year$Household, NumAuto + NumLtTrk)
    DvmtPerOwnedVeh_Hh <- Dvmt_Hh / NumOwned_Hh
    DvmtPerOwnedVeh_Hh[NumOwned_Hh == 0] <- 0
    Dvmt_Ve <- DvmtPerOwnedVeh_Hh[HhToVehIdx_Ve]
    Dvmt_Ve[L$Year$Vehicle$VehicleAccess != "Own"] <- 0
    Dvmt_Ve
  })
  #Calculate 95th percentile DVMT by vehicle
  Dvmt95th_Ve <- Dvmt_Ve * Dvmt95thFactor_Hh[HhToVehIdx_Ve]

  #Make powertrain characteristics data frame
  #------------------------------------------
  Char_df <- PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df
  rownames(Char_df) <- Char_df$ModelYear

  #Assign vehicle powertrains, MPG, MPKWH, and battery range to owned vehicles
  #---------------------------------------------------------------------------
  #Initialize vector of results
  NumVeh <- length(L$Year$Vehicle$HhId)
  Powertrain_Ve <- character(NumVeh)
  MPG_Ve <- numeric(NumVeh)
  MPKWH_Ve <- numeric(NumVeh)
  BatRng_Ve <- numeric(NumVeh)
  #Convert vehicle age to vehicle model year
  ModelYear_Ve <- as.integer(L$G$Year) - as.integer(L$Year$Vehicle$Age)
  ModelYear_Ve[ModelYear_Ve < min(as.integer(My))] <- min(as.integer(My))
  ModelYear_Ve <- as.character(ModelYear_Ve)
  #Identify availability of charging at home
  ChargeAvail_Ve <- local({
    ChargeAvailProb_ <- c(
      SF = L$Year$Azone$PropSFChargingAvail,
      MF = L$Year$Azone$PropMFChargingAvail,
      GQ = L$Year$Azone$PropGQChargingAvail
    )
    ChargeAvailProb_Hh <- ChargeAvailProb_[L$Year$Household$HouseType]
    ChargeAvail_Hh <- runif(length(ChargeAvailProb_Hh)) < ChargeAvailProb_Hh
    ChargeAvail_Hh[HhToVehIdx_Ve]
  })
  #Iterate through vehicle types and model years and assign powertrains, MPG,
  #MPKWH, and battery range for owned household vehicles
  for (ty in Ty) {
    for (my in unique(ModelYear_Ve)) {
      IsSelection_Ve <-
        L$Year$Vehicle$Type == ty & ModelYear_Ve == my & L$Year$Vehicle$VehicleAccess == "Own"
      #Tabulate number of vehicles by powertrain
      NumSelVeh <- sum(IsSelection_Ve)
      NumVeh_Pt <- local({
        Prop_Pt <- Prop_MyPtTy[my,Pt,ty]
        NumVeh_Pt <- floor(NumSelVeh * Prop_Pt)
        VehDiff <- NumSelVeh - sum(NumVeh_Pt)
        if (VehDiff > 0) { #whole number of vehicles by powertrain
          VehDiff_Pt <- 0 * NumVeh_Pt
          VehDiffTab_Px <-
            table(sample(Pt, VehDiff, replace = TRUE, Prop_Pt))
          VehDiff_Pt[names(VehDiffTab_Px)] <- VehDiffTab_Px
          NumVeh_Pt <- NumVeh_Pt + VehDiff_Pt
        }
        NumVeh_Pt
      })
      #Assign powertrains to selected vehicles
      PwrtrnSel_ <- local({
        #Create vector of vehicles to be assigned powertrains
        PwrtrnSel_ <- character(NumSelVeh)
        #Identify vector positions with correct charging and battery range
        CanCharge_ <- ChargeAvail_Ve[IsSelection_Ve]
        InBatRng_ <-
          Dvmt95th_Ve[IsSelection_Ve] <= Char_df[my, paste0(ty, "BevRange")]
        #First assign BEV and reclass BEV that can't be assigned to PHEV
        CanBeBev_ <- CanCharge_ & InBatRng_
        NumBev <- NumVeh_Pt["BEV"]
        if (NumBev > 0) {
          if (sum(CanBeBev_) <= NumBev) {
            PwrtrnSel_[CanBeBev_] <- "BEV"
            NewNumBev <- sum(CanBeBev_)
            NumVeh_Pt["BEV"] <- NewNumBev
            NumVeh_Pt["PHEV"] <- NumVeh_Pt["PHEV"] + NumBev - NewNumBev
          } else {
            PwrtrnSel_[sample(which(CanBeBev_), NumBev)] <- "BEV"
          }
          AvailToSel_ <- PwrtrnSel_ == ""
        }
        #Then assign PHEV and reclass PHEV than can't be assigned to HEV
        NumPhev <- NumVeh_Pt["PHEV"]
        AvailToSel_ <- PwrtrnSel_ == ""
        if (NumPhev > 0) {
          if (sum(CanCharge_ & AvailToSel_) <= NumPhev) {
            PwrtrnSel_[CanCharge_ & AvailToSel_] <- "PHEV"
            NewNumPhev <- sum(CanCharge_ & AvailToSel_)
            NumVeh_Pt["PHEV"] <- NewNumPhev
            NumVeh_Pt["HEV"] <- NumVeh_Pt["HEV"] + NumPhev - NewNumPhev
          } else {
            PwrtrnSel_[sample(which(CanCharge_ & AvailToSel_), NumPhev)] <- "PHEV"
          }
        }
        #Then assign HEV and ICEV
        AvailToSel_ <- PwrtrnSel_ == ""
        NumHev <- NumVeh_Pt["HEV"]
        PwrtrnSel_[sample(which(AvailToSel_), NumHev)] <- "HEV"
        PwrtrnSel_[PwrtrnSel_ == ""] <- "ICEV"
        #Return the result
        PwrtrnSel_
      })
      #Calculate the MPG, MPKWH, and battery range for each vehicle
      MPG_Pt <- numeric(length(Pt))
      names(MPG_Pt) <- Pt
      MPG_Pt[c("ICEV", "HEV", "PHEV")] <-
        unlist(Char_df[my, paste0(ty, c("IcevMpg", "HevMpg", "PhevMpg"))])
      MPKWH_Pt <- numeric(length(Pt))
      names(MPKWH_Pt) <- Pt
      MPKWH_Pt[c("PHEV", "BEV")] <-
        unlist(Char_df[my, paste0(ty, c("PhevMpkwh", "BevMpkwh"))])
      BatRng_Pt <- numeric(length(Pt))
      names(BatRng_Pt) <- Pt
      BatRng_Pt[c("PHEV", "BEV")] <-
        unlist(Char_df[my, paste0(ty, c("PhevRange", "BevRange"))])
      #Return the results for the vehicle type and model year
      Powertrain_Ve[IsSelection_Ve] <- PwrtrnSel_
      MPG_Ve[IsSelection_Ve] <- MPG_Pt[PwrtrnSel_]
      MPKWH_Ve[IsSelection_Ve] <- MPKWH_Pt[PwrtrnSel_]
      BatRng_Ve[IsSelection_Ve] <- BatRng_Pt[PwrtrnSel_]
      #Clean up
      rm(MPG_Pt, MPKWH_Pt, BatRng_Pt, PwrtrnSel_, IsSelection_Ve, NumSelVeh, NumVeh_Pt)
    }
  }

  #Calculate the proportion of DVMT that is electric
  #-------------------------------------------------
  ElecDvmtProp_Ve <- local({
    IsPhev_Ve <- Powertrain_Ve == "PHEV"
    IsMetro_Ve <- L$Year$Household$DevType[HhToVehIdx_Ve] == "Urban"
    ElecDvmtProp_Ve <- numeric(NumVeh)
    if (sum((IsPhev_Ve & IsMetro_Ve) >= 1)) {
      ElecDvmtProp_Ve[IsPhev_Ve & IsMetro_Ve] <-
        mapply(
          PhevElecProp_ls$getElecProp,
          Dvmt_Ve[IsPhev_Ve & IsMetro_Ve],
          BatRng_Ve[IsPhev_Ve & IsMetro_Ve],
          "Metro")
    }
    if (sum((IsPhev_Ve & !IsMetro_Ve) >= 1)) {
      ElecDvmtProp_Ve[IsPhev_Ve & !IsMetro_Ve] <-
        mapply(
          PhevElecProp_ls$getElecProp,
          Dvmt_Ve[IsPhev_Ve & !IsMetro_Ve],
          BatRng_Ve[IsPhev_Ve & !IsMetro_Ve],
          "NonMetro")
    }
    IsEv_Ve <- Powertrain_Ve == "BEV"
    if (sum(IsEv_Ve >= 1)) {
      ElecDvmtProp_Ve[IsEv_Ve] <- 1
    }
    ElecDvmtProp_Ve
  })

  #Calculate characteristics of car service vehicles
  #-------------------------------------------------
  #Identify which vehicles are car service
  IsCarSvc_Ve <- L$Year$Vehicle$VehicleAccess != "Own"
  #Set powertrain to "NA" because there is no specific powertrain used
  Powertrain_Ve[IsCarSvc_Ve] <- "NA"
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
        PowertrainFuelDefaults_ls$CarSvcPowertrain_df$Year,
        PowertrainFuelDefaults_ls$CarSvcPowertrain_df[[nm]],
        L$G$Year
      )$y
    }
  }
  #Get the average powertrain characteristics for car service vehicles by type
  CarSvcChar_ <- local({
    CarSvcMaxAge <- max(as.integer(L$Year$Vehicle$Age[IsCarSvc_Ve]))
    Year <- as.integer(L$G$Year)
    CarSvcMY_ <- as.character((Year - CarSvcMaxAge):Year)
    CarSvcChar_df <- Char_df[CarSvcMY_,]
    unlist(lapply(CarSvcChar_df, function(x) mean(x, na.rm = TRUE)))
  })
  #Calculate average MPG by vehicle type
  calcAveCarSvcMpg <- function(Type) {
    PtNames_ <- paste0(Type, c("PropIcev", "PropHev"))
    PtProp_ <- CSPwrtnProp_[PtNames_]
    PtProp_ <- PtProp_ / sum(PtProp_)
    MpgNames_ <- paste0(Type, c("IcevMpg", "HevMpg"))
    Mpg_ <- CarSvcChar_[MpgNames_]
    sum(PtProp_ * Mpg_)
  }
  MPG_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <- calcAveCarSvcMpg("Auto")
  MPG_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"] <- calcAveCarSvcMpg("LtTrk")
  #Calculate average MPKWH by vehicle type
  calcAveCarSvcMpkwh <- function(Type) {
    PtName <- paste0(Type, "PropBev")
    PtProp <- CSPwrtnProp_[[PtName]]
    if (PtProp == 0) {
      0
    } else {
      CarSvcChar_[paste0(Type, "BevMpkwh")]
    }
  }
  MPKWH_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <- calcAveCarSvcMpkwh("Auto")
  MPKWH_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"] <- calcAveCarSvcMpkwh("LtTrk")
  #Calculate the proportion of DVMT that is powered by electricity
  calcCarSvcElecProp <- function(Type) {
    PtNames_ <- paste0(Type, c("PropIcev", "PropHev", "PropBev"))
    PtProp_ <- CSPwrtnProp_[PtNames_]
    PtProp_[3] / sum(PtProp_)
  }
  ElecDvmtProp_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <-
    calcCarSvcElecProp("Auto")
  ElecDvmtProp_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"] <-
    calcCarSvcElecProp("LtTrk")
  #Clean up
  rm(CarSvcChar_, calcAveCarSvcMpg, calcAveCarSvcMpkwh, calcCarSvcElecProp)

  #Calculate fuel consumption, electricity consumption, and GHG per mile
  #---------------------------------------------------------------------
  #Calculate gallons per mile and megajoules per mile
  GPM_Ve <- 1 / MPG_Ve
  GPM_Ve[MPG_Ve == 0] <- 0
  MJPM_Ve <- convertUnits(GPM_Ve, "compound", "GGE/MI", "MJ/MI")$Values
  #Calculate fuel carbon intensity for fuel consumption
  FuelCI_Ve <- numeric(NumVeh)
  FuelCI_Ve[!IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <-
    L$Year$Region$HhAutoFuelCI
  FuelCI_Ve[!IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"] <-
    L$Year$Region$HhLtTrkFuelCI
  FuelCI_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "Auto"] <-
    L$Year$Region$CarSvcAutoFuelCI
  FuelCI_Ve[IsCarSvc_Ve & L$Year$Vehicle$Type == "LtTrk"] <-
    L$Year$Region$CarSvcLtTrkFuelCI
  #Calculate carbon intensity per mile for fuel consuming vehicles
  FuelCO2ePM_Ve <- MJPM_Ve * FuelCI_Ve
  rm(MJPM_Ve, FuelCI_Ve)
  #Calculate kilowatt-hours per mile and megajoules per mile
  KWHPM_Ve <- 1 / MPKWH_Ve
  KWHPM_Ve[MPKWH_Ve == 0] <- 0
  MJPM_Ve <- convertUnits(KWHPM_Ve, "compound", "KWH/MI", "MJ/MI")$Values
  #Calculate carbon intensity for electricity consumption
  ElecCO2ePM_Ve <- MJPM_Ve * L$Year$Azone$ElectricityCI

  #Calculate MPGe
  #--------------
  MPGe_Ve <-
    MPG_Ve * (1 - ElecDvmtProp_Ve) +
    convertUnits(MPKWH_Ve, "compound", "MI/KWH", "MI/GGE")$Values * ElecDvmtProp_Ve

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list(
    Powertrain = Powertrain_Ve,
    BatRng = BatRng_Ve,
    MPG = MPG_Ve,
    GPM = GPM_Ve,
    MPKWH = MPKWH_Ve,
    KWHPM = KWHPM_Ve,
    MPGe = MPGe_Ve,
    FuelCO2ePM = FuelCO2ePM_Ve,
    ElecCO2ePM = ElecCO2ePM_Ve,
    ElecDvmtProp = ElecDvmtProp_Ve
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
# load("data/PowertrainFuelDefaults_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "AssignHhVehiclePowertrain",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# M <- TestDat_$M
# TestOut_ls <- AssignHhVehiclePowertrain(L, M)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignHhVehiclePowertrain",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
#
# setwd("tests")
# untar("Datastore.tar")
# setwd("..")

