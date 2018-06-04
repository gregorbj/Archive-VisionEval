#========================
#CalculatePolicyVmt.R
#========================
#This module models adjusts the VMT for the policies entered for the scenario.
#The outputs form this module contains 'Policy' as the suffix in their names.

library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================


#Create a list to store models
#-----------------------------
LtVehOwnModels_ls <-
  list(
    Metro = list(),
    NonMetro = list(),
    BaseProp = 0.5
  )

LtVehOwnModels_ls$Metro <- "0.224301815496625 * Intercept + 0.166050639905512 * HhSize + 3.57142278914064e-06 * Income * Age15to19 + 2.48763945892776e-06 * Income * Age30to54 + 1.72004416803589e-06 * Income * Age55to64 + 0.216803801044835 * Age15to19 * VehPerDrvAgePop + 0.164339760946025 * VehPerDrvAgePop * Age20to29 + 0.199173974270093 * Age30to54 * VehPerDrvAgePop + 0.212320927962324 * Age55to64 * VehPerDrvAgePop + 0.14838607575991 * VehPerDrvAgePop * Age65Plus + -0.0140363172283936 * Age20to29 * LogDen + -0.0157422752339548 * Age30to54 * LogDen + -0.0264414267066192 * Age55to64 * LogDen + -0.0247131560053913 * Age65Plus * LogDen"

LtVehOwnModels_ls$NonMetro <- "-0.0864599943963062 * Intercept + 0.156153095288963 * HhSize + 3.20050217503788e-06 * Income * Age15to19 + 2.90847074543147e-06 * Income * Age30to54 + 2.1246470582263e-06 * Income * Age55to64 + 1.35453645467784e-06 * Income * Age65Plus + 0.160401479387148 * Age15to19 * VehPerDrvAgePop + 0.0825910411936799 * VehPerDrvAgePop * Age20to29 + 0.142990220143246 * Age30to54 * VehPerDrvAgePop + 0.127633897466027 * Age55to64 * VehPerDrvAgePop + 0.115087071566911 * Age65Plus * VehPerDrvAgePop + 0.0274359573616246 * Age15to19 * LogDen + 0.0064784210194648 * Age30to54 * LogDen + -0.00820739380602359 * Age55to64 * LogDen + -0.0230144608211162 * Age65Plus * LogDen"

#Save the light vehicle ownership model
#-----------------------------
#' Light Vehicle ownership model
#'
#' A list containing the light vehicle ownership model equation and other information
#' needed to implement the vehicle ownership model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Metro}{Light vehicle ownership model for the metropolitan region}
#'   \item{NonMetro}{Light vehicle ownership model for the non-metropolitan region}
#' }
#' @source AssignVehicleFeatures.R script.
"LtVehOwnModels_ls"
devtools::use_data(LtVehOwnModels_ls, overwrite = TRUE)

# Load the DVMT assignment model
load("data/DvmtLmModels_ls.rda")

# Average single-occupant vehicle (SOV) travel proportion model
AveSovPropModels_ls <- list(
  Model = list(),
  Parm = list()
)

AveSovPropModels_ls$Model <- list(
  LE2 = "0.328446294566977 * Intercept + -1.292763520066e-06 * Income + 0.00295293573543728 * LogDen + -0.128879403810534 * LogSize + 0.0268327189104913 * Urban + -0.0739425861012604 * LogDvmt + 3.57798332516027e-07 * Income * LogDvmt + -0.00319779858045753 * LogDen * LogDvmt + 0.0315434507132454 * LogSize * LogDvmt + -0.00291247496673383 * Urban * LogDvmt + 3.84217505225571e-08 * Income * LogDen + -2.77182626759555e-07 * Income * LogSize + 2.35792547438971e-07 * Income * Urban + 0.00541325257245359 * LogDen * LogSize + -0.00377556306951901 * LogDen * Urban",
  LE5 = "0.532844036048356 * Intercept + -1.19337814542128e-06 * Income + 0.0186918683375028 * LogDen + -0.265779934436473 * LogSize + 0.0851545029673722 * Urban + -0.12269665212336 * LogDvmt + 3.82626652994712e-07 * Income * LogDvmt + -0.00724217169310343 * LogDen * LogDvmt + 0.0651465946327447 * LogSize * LogDvmt + 4.04978223968973e-08 * Income * LogDen + -3.93386882305809e-07 * Income * LogSize + 3.03130807638427e-07 * Income * Urban + 0.00728936038911245 * LogDen * LogSize + -0.0129839941120726 * LogDen * Urban",
  LE10 =  "0.771404025566222 * Intercept + -1.44416348617373e-07 * Income + 0.0340853310599975 * LogDen + -0.359352466232078 * LogSize + 0.317946740274271 * Urban + -0.177198527432801 * LogDvmt + 1.52400454804613e-07 * Income * LogDvmt + -0.00840761150306149 * LogDen * LogDvmt + 0.0860215477782244 * LogSize * LogDvmt + 0.00473360209526263 * Urban * LogDvmt + 1.3653457851028e-08 * Income * LogDen + -2.19736950842657e-07 * Income * LogSize + 3.73774959429662e-07 * Income * Urban + 0.00434150676299963 * LogDen * LogSize + -0.0435916789655519 * LogDen * Urban + 0.00576102484708759 * LogSize * Urban",
  LE15 = "0.932215336123015 * Intercept + 6.93189772777467e-07 * Income + 0.0279651627448513 * LogDen + -0.364101465326497 * LogSize + 0.338404951513788 * Urban + -0.207485449196553 * LogDvmt + -6.45992373057788e-08 * Income * LogDvmt + -0.00523121458606013 * LogDen * LogDvmt + 0.0852672280312197 * LogSize * LogDvmt + 0.0172981324490465 * Urban * LogDvmt + 2.38072302434675e-07 * Income * Urban + -0.0512330284611652 * LogDen * Urban + 0.0177211029086151 * LogSize * Urban",
  LE20 = "1.03813440747041 * Intercept + 2.23043935220942e-06 * Income + 0.0181773794204152 * LogDen + -0.373066033308114 * LogSize + 0.340985557886736 * Urban + -0.223626863114231 * LogDvmt + -3.86469173089692e-07 * Income * LogDvmt + -0.000939460008294598 * LogDen * LogDvmt + 0.0830520334652117 * LogSize * LogDvmt + 0.017139787836247 * Urban * LogDvmt + -5.42893217837851e-08 * Income * LogDen + 2.20042053553929e-07 * Income * LogSize + 1.35410685084978e-07 * Income * Urban + -0.00279875214520305 * LogDen * LogSize + -0.049823470297004 * LogDen * Urban + 0.0098843224716401 * LogSize * Urban"
)

AveSovPropModels_ls$Parm <- list(
  LE2 = c(7.4, 0.5),
  LE5 = c(5.9, 0.47),
  LE10 = c(5.5, 0.475),
  LE15 = c(5.2, 0.49),
  LE20 = c(5.1, 0.5)
)


#Save the average single-occupant vehicle (SOV) travel proportion model
#-----------------------------
#' SOV travel proportion model
#'
#' A list containing the SOV DVMT proportion model equation and relevant parameters.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Model}{A list of equations to estimate SOV DVMT with 2, 5, 10, 15, and 20 mile thresholds.}
#'   \item{Parm}{Contains the alpha and beta parameters for the logistic transformation of model equations}
#' }
#' @source CalculatePolicyVmt.R script.
"AveSovPropModels_ls"
devtools::use_data(AveSovPropModels_ls, overwrite = TRUE)

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculatePolicyVmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "CommuteOptions",
      GROUP = "Global"
    ),
    item(
      TABLE = "LightVehiclesInfo",
      GROUP = "Global"
    ),
    item(
      TABLE = "TDMRidesharing",
      GROUP = "Global"
    ),
    item(
      TABLE = "TDMTransit",
      GROUP = "Global"
    ),
    item(
      TABLE = "TDMTransitLevels",
      GROUP = "Global"
    ),
    item(
      TABLE = "TDMVanpooling",
      GROUP = "Global"
    ),
    item(
      TABLE = "TDMWorkschedule",
      GROUP = "Global"
    ),
    item(
      TABLE = "TDMWorkscheduleLevels",
      GROUP = "Global"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME = item(
        "TDMProgram",
        "DataItem"
      ),
      TABLE = "CommuteOptions",
      GROUP = "Global",
      FILE = "region_commute_options.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 31,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "Work based travel demand management program",
        "Levels of participation in the program"
      )
    ),
    item(
      NAME = "DataValue",
      TABLE = "CommuteOptions",
      GROUP = "Global",
      FILE = "region_commute_options.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = "Data values relevant to data items specified in the DataItem column"
    ),
    item(
      NAME = "DataItem",
      TABLE = "LightVehiclesInfo",
      GROUP = "Global",
      FILE = "region_light_vehicles.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 12,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = "Names of the variables"
    ),
    item(
      NAME = "DataValue",
      TABLE = "LightVehiclesInfo",
      GROUP = "Global",
      FILE = "region_light_vehicles.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Value of the variables"
    ),
    item(
      NAME = items(
        "PropWorkParking",
        "PropWorkCharged",
        "PropCashOut",
        "PropOtherCharged"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      FILE = "marea_parking_growth.csv",
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "Proportion of employees that park at work",
        "Proportion of employers that charge for parking",
        "Proportion of employment parking that is converted from being
        free to pay under a 'cash-out buy-back' type of program",
        "Proportion of other parking that is not free"
      )
    ),
    item(
      NAME = "ParkingCost",
      TABLE = "Marea",
      GROUP = "Year",
      FILE = "marea_parking_growth.csv",
      TYPE = "currency",
      UNITS = "USD",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Average daily parking cost"
    ),
    item(
      NAME = "ModelGeo",
      TABLE = "TDMRidesharing",
      GROUP = "Global",
      FILE = "model_tdm_ridesharing.csv",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 3,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = "Model place types"
    ),
    item(
      NAME = "Effectiveness",
      TABLE = "TDMRidesharing",
      GROUP = "Global",
      FILE = "model_tdm_ridesharing.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Effectiveness of ridesharing programs by place types"
    ),
    item(
      NAME = "ModelGeo",
      TABLE = "TDMTransit",
      GROUP = "Global",
      FILE = "model_tdm_transit.csv",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 3,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = "Model place types"
    ),
    item(
      NAME = item(
        "Subsidy0",
        "Subsidy1",
        "Subsidy2",
        "Subsidy3",
        "Subsidy4"
      ),
      TABLE = "TDMTransit",
      GROUP = "Global",
      FILE = "model_tdm_transit.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "Effectiveness of subsidy level 0 in VMT reduction by place types",
        "Effectiveness of subsidy level 1 in VMT reduction by place types",
        "Effectiveness of subsidy level 2 in VMT reduction by place types",
        "Effectiveness of subsidy level 3 in VMT reduction by place types",
        "Effectiveness of subsidy level 4 in VMT reduction by place types"
      )
    ),
    item(
      NAME = "SubsidyLevel",
      TABLE = "TDMTransitLevels",
      GROUP = "Global",
      FILE = "model_tdm_transitlevels.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 8,
      PROHIBIT = c("NA"),
      ISELEMENTOF = paste0("Subsidy",0:4),
      DESCRIPTION = "Levels of subsidy"
    ),
    item(
      NAME = "SubsidyValue",
      TABLE = "TDMTransitLevels",
      GROUP = "Global",
      FILE = "model_tdm_transitlevels.csv",
      TYPE = "currency",
      UNITS = "USD",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Equivalent dollar amount for the level of subsidy"
    ),
    item(
      NAME = "VanpoolingParticipation",
      TABLE = "TDMVanpooling",
      GROUP = "Global",
      FILE = "model_tdm_vanpooling.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 6,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c("Low","Medium","High"),
      DESCRIPTION = "Levels of participation in vanpooling"
    ),
    item(
      NAME = "VMTReduction",
      TABLE = "TDMVanpooling",
      GROUP = "Global",
      FILE = "model_tdm_vanpooling.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Effectiveness in reduction of vmt by different levels of vanpooling programs"
    ),
    item(
      NAME = "WorkSchedulePolicy",
      TABLE = "TDMWorkschedule",
      GROUP = "Global",
      FILE = "model_tdm_workschedule.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 30,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = "Work schedule policy"
    ),
    item(
      NAME = item(
        "Participation0",
        "Participation1",
        "Participation2",
        "Participation3",
        "Participation4",
        "Participation5"
      ),
      TABLE = "TDMWorkschedule",
      GROUP = "Global",
      FILE = "model_tdm_workschedule.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = item(
        "Effectiveness of participation level 0 in VMT reduction by policies",
        "Effectiveness of participation level 1 in VMT reduction by policies",
        "Effectiveness of participation level 2 in VMT reduction by policies",
        "Effectiveness of participation level 3 in VMT reduction by policies",
        "Effectiveness of participation level 4 in VMT reduction by policies",
        "Effectiveness of participation level 5 in VMT reduction by policies"
      )
    ),
    item(
      NAME = "ParticipationLevel",
      TABLE = "TDMWorkscheduleLevels",
      GROUP = "Global",
      FILE = "model_tdm_workschedulelevels.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 15,
      PROHIBIT = c("NA"),
      ISELEMENTOF = paste0("Participation",0:5),
      DESCRIPTION = "Levels of participation in work schedule policies"
    ),
    item(
      NAME = "ParticipationValue",
      TABLE = "TDMWorkscheduleLevels",
      GROUP = "Global",
      FILE = "model_tdm_workschedulelevels.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Proportions of employees participating at the level"
    )
    ),
  #Specify data to be loaded from data store
  Get = items(
    # Load Bzone variables
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 5,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "TransitTrips",
        "VehicleTrips"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "trips",
      UNITS = "TRIP",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DvmtFuture",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanIncome",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "UrbanEmp",
        "UrbanPop"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    #Load Vehicles variables
    item(
      NAME = "HhIdFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 16,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehIdFuture",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 18,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "DvmtFuture",
        "EvDvmtFuture",
        "HcDvmtFuture"
      ),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    #Load Household variables
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 16,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "Age0to14",
        "Age15to19",
        "Age20to29",
        "Age30to54",
        "Age55to64",
        "Age65Plus",
        "HhSize"
      ),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      SIZE = 5,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DvmtFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DvmtPtAdj",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ElecCo2eFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ElecKwhFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "FuelCo2eFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "mass",
      UNITS = "GM",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "FuelGallonsFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GAL/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "FutureCostPerMileFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = items(
        "NumLtTrkFuture",
        "NumAutoFuture"
      ),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
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
      SIZE = 0
    ),
    # Load Income Group variables
    item(
      NAME = "IncomeGroup",
      TABLE = "IncomeGroup",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "Equity",
      TABLE = "IncomeGroup",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    # Load Marea variables
    item(
      NAME = items(
        "FwyLaneMiPCFuture",
        "ArtLaneMiPCFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "TranRevMiPCFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = items(
        "BusRevMiFuture",
        "RailRevMiFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = items(
        "MpgAdjLtVehFuture",
        "MpgAdjBusFuture",
        "MpgAdjTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "MpKwhAdjLtVehEvFuture",
        "MpKwhAdjLtVehHevFuture",
        "MpKwhAdjBusFuture",
        "MpKwhAdjTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "VehHrLtVehFuture",
        "VehHrBusFuture",
        "VehHrTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "AveSpeedLtVehFuture",
        "AveSpeedBusFuture",
        "AveSpeedTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FfVehHrLtVehFuture",
        "FfVehHrBusFuture",
        "FfVehHrTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "DelayVehHrLtVehFuture",
        "DelayVehHrBusFuture",
        "DelayVehHrTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "MpgAdjHhFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "MpgAdjHhFuture",
        "MpKwhAdjEvHhFuture",
        "MpKwhAdjHevHhFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Access",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = 99,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "Walking",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = 99,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    # Load input file variables
    item(
      NAME = item(
        "TDMProgram",
        "DataItem"
      ),
      TABLE = "CommuteOptions",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 31,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DataValue",
      TABLE = "CommuteOptions",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DataItem",
      TABLE = "LightVehiclesInfo",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 12,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DataValue",
      TABLE = "LightVehiclesInfo",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "PropWorkParking",
        "PropWorkCharged",
        "PropCashOut",
        "PropOtherCharged"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ParkingCost",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelGeo",
      TABLE = "TDMRidesharing",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 3,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Effectiveness",
      TABLE = "TDMRidesharing",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelGeo",
      TABLE = "TDMTransit",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 3,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "Subsidy0",
        "Subsidy1",
        "Subsidy2",
        "Subsidy3",
        "Subsidy4"
      ),
      TABLE = "TDMTransit",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "SubsidyLevel",
      TABLE = "TDMTransitLevels",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 8,
      PROHIBIT = c("NA"),
      ISELEMENTOF = paste0("Subsidy",0:4)
    ),
    item(
      NAME = "SubsidyValue",
      TABLE = "TDMTransitLevels",
      GROUP = "Global",
      TYPE = "currency",
      UNITS = "USD.2000",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VanpoolingParticipation",
      TABLE = "TDMVanpooling",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 6,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c("Low","Medium","High")
    ),
    item(
      NAME = "VMTReduction",
      TABLE = "TDMVanpooling",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "WorkSchedulePolicy",
      TABLE = "TDMWorkschedule",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 30,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "Participation0",
        "Participation1",
        "Participation2",
        "Participation3",
        "Participation4",
        "Participation5"
      ),
      TABLE = "TDMWorkschedule",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ParticipationLevel",
      TABLE = "TDMWorkscheduleLevels",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 15,
      PROHIBIT = c("NA"),
      ISELEMENTOF = paste0("Participation",0:5)
    ),
    item(
      NAME = "ParticipationValue",
      TABLE = "TDMWorkscheduleLevels",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    # Load Global variables
    item(
      NAME = "WorkVmtProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      SIZE = 0,
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
      NAME = "VmtCharge",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/MI",
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
      NAME = "AutoCostGrowth",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseCostPerMile",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "USD/MI",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DvmtBudgetProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    # Bzone Variable
    item(
      NAME = item(
        "DvmtPolicy",
        "EvDvmtPolicy",
        "HcDvmtPolicy"
      ),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = item(
        "Average daily vehicle miles traveled",
        "Average daily electric vehicle miles traveled",
        "Average daily ICE vehicle miles traveled")
    ),
    # Household variables
    item(
      NAME = "DvmtPolicy",
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
      NAME = "LtVehiclesPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of light vehicles"
    ),
    item(
      NAME = "LtVehAdjFactorPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Light vehicles adjustment factor"
    ),
    item(
      NAME = "TdmLtVehAdjFactorPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "TDM Light vehicles adjustment factor"
    ),
    item(
      NAME = "TdmAdjFactorPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "TDM adjustment factor"
    ),
    item(
      NAME = "LtVehDvmtPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by light vehicles"
    ),
    item(
      NAME = "FutureCostPerMilePolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "USD/MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total fuel cost per mile"
    ),
    item(
      NAME = "DailyParkingCostPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Daily parking cost"
    ),
    item(
      NAME = "CashOutIncAdjPolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Adjustment to income after cash out"
    ),
    item(
      NAME = "IncomePolicy",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Income after applying policy"
    ),
    # Vehicles variables
    item(
      NAME = item(
        "DvmtPolicy",
        "EvDvmtPolicy",
        "HcDvmtPolicy"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = item("Average daily vehicle miles traveled",
                         "Average daily electric vehicle miles traveled",
                         "Average daily ICE vehicle miles traveled")
    ),
    # Global variables
    item(
      NAME = "CostsPolicy",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "currency",
      UNITS = "USD.2000",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Various policy related energy costs"
    ),
    item(
      NAME = "CostsIdPolicy",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 10,
      DESCRIPTION = "Names of tax/costs"
    )
  )
  )

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculatePolicyVmt module
#'
#' A list containing specifications for the CalculatePolicyVmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculatePolicyVmt.R script.
"CalculatePolicyVmtSpecifications"
devtools::use_data(CalculatePolicyVmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates light vehicle ownership.

#Define a function that calculates light vehicle ownership
#----------------------------------------------------------
#' Function to calculate light vehicle ownership
#'
#' \code{predictLightVehicles} calculates light vehicle ownership.
#'
#' This function takes a data frame of households and a list of models which
#' are used to calculate light vehicle ownership for each
#' household.
#' @param Data_ A household data frame consisting of household attributes used to
#' calculate light vehicle ownership.
#' @param LtVehOwnModels_ A list of light vehicle ownership models.
#' @param Type A string indicating the region type. ("Metro": Default, or "NonMetro")
#' @return An array of integers representing the number of light vehicles for each
#' household.
predictLightVehicles <- function( Data_, LtVehOwnModels_, Type, TargetProp=NA ) {

  # Check target acceptability
  if( !is.na( TargetProp ) ){
    if( TargetProp < 0.2 ) {
      stop( "TargetProp less than 0.2 will create negative numbers" )
    }
  }
  # Check if proper Type specified
  if( !( Type %in% c( "Metro", "NonMetro" ) ) ) {
    stop( "Type must be either 'Metro' or 'NonMetro'" )
  }

  # Extract model components for specified type
  LtVehOwnModel <- LtVehOwnModels_[[Type]]
  if( is.na( TargetProp ) ) {
    TargetProp <- LtVehOwnModels_$BaseProp
  }
  FactorLo <- -1
  FactorMid <- 0
  FactorHi <- 1
  Itr <- 0
  Intercept <- 1

  # Function to test convergence
  notConverged <- function( TargetProp, EstProp ) {
    Diff <- abs( TargetProp - EstProp )
    Diff > 0.0001
  }

  # Function to calculate number of light vehicles
  calcNumLtVeh <- function( Factor ) {
    round( Factor + eval( parse( text=LtVehOwnModel ), envir=Data_ ) )
  }

  # Calculate starting proportion
  LtVeh_ <- calcNumLtVeh( FactorMid )
  EstProp <- mean( LtVeh_ / Data_$DrvAgePop )
  # Continue is there is a target truck proportion to be achieved
  if( !is.na( TargetProp ) ){
    while( notConverged( TargetProp, EstProp ) ) {
      LtVehLo_ <- calcNumLtVeh( FactorLo )
      LtVehMid_ <- calcNumLtVeh( FactorMid )
      LtVehHi_ <- calcNumLtVeh( FactorHi )
      EstPropLo <- mean( LtVehLo_ / Data_$DrvAgePop )
      EstPropMid <- mean( LtVehMid_ / Data_$DrvAgePop )
      EstPropHi <- mean( LtVehHi_ / Data_$DrvAgePop )
      if( TargetProp < EstPropMid ) {
        FactorHi <- FactorMid
        FactorMid <- mean( c( FactorHi, FactorLo ) )
      }
      if( TargetProp > EstPropMid ) {
        FactorLo <- FactorMid
        FactorMid <- mean( c( FactorLo, FactorHi ) )
      }
      EstProp <- EstPropMid
      rm( EstPropLo, EstPropMid, EstPropHi )
      if( Itr > 100 ) break
      Itr <- Itr + 1
    }
  }

  # Return the result
  LtVehMid_

}

#This function calculates proportion of single occupant vehicles.

#Define a function that calculates proportion of single occupant vehicles
#----------------------------------------------------------
#' Function to calculate proportion of single occupant vehicles
#'
#' \code{calcAveSovProp} calculates proportion of single occupant vehicles.
#'
#' This function takes a data frame of households, a distance threshold, and
#' a list of models which are used to calculate proportion of single
#' occupant vehicles for each household.
#' @param Data__ A household data frame consisting of household attributes used to
#' calculate proportion of single occupant vehicles.
#' @param AveSovPropModels_ A list of SOV propotion models.
#' @param Threshold A numeric (miles) for which SOV model should be used
#' @return An array of integers representing the number of single occupant vehicles
calcAveSovProp <- function( Data__, AveSovPropModels_, Threshold ) {

  # Check that Threshold argument is in range
  #------------------------------------------
  if( Threshold < 2 | Threshold > 20 ) {
    stop( "Threshold must be between 2 and 20 miles" )
  }

  # Define function to apply logistic transform to data
  #----------------------------------------------------
  logistic <- function( Data_, A, B ) {
    Data_ <- 1 / ( 1 + exp( -A * ( Data_ - B ) ) ) - ( 0.5 - B )
  }

  # No interpolation if threshold is 5, 10, 15, or 20
  #--------------------------------------------------

  if( Threshold %in% c( 2, 5, 10, 15, 20 ) ) {
    Intercept <- 1
    ListElementName <- paste( "LE", Threshold, sep="" )
    SovPropModel <- AveSovPropModels_$Model[[ ListElementName ]]
    SovProp_ <- as.vector( eval( parse( text=SovPropModel ), envir=Data__ ) )
    Parm1 <- AveSovPropModels_$Parm[[ ListElementName ]][1]
    Parm2 <- AveSovPropModels_$Parm[[ ListElementName ]][2]
    SovProp_ <- logistic( SovProp_, Parm1, Parm2 )
  }

  # Interpolate if threshold is not 5, 10, 15 or 20
  #------------------------------------------------

  if( !( Threshold %in% c( 2, 5, 10, 15, 20 ) ) ) {

    # Identify the levels above and below the threshold range
    Thresholds. <- c( 2, 5, 10, 15, 20 )
    ThresholdDiff_ <- Thresholds. - Threshold
    LowVals_ <- ThresholdDiff_[ ThresholdDiff_ < 0 ]
    LowerBnd <- Thresholds.[ which( ThresholdDiff_ == max( LowVals_ ) ) ]
    HighVals_ <- ThresholdDiff_[ ThresholdDiff_ > 0 ]
    HigherBnd <- Thresholds.[ which( ThresholdDiff_ == min( HighVals_ ) ) ]

    # Predict values for lower bound
    Intercept <- 1
    ListElementName <- paste( "LE", LowerBnd, sep="" )
    SovPropModel <- AveSovPropModels_$Model[[ ListElementName ]]
    LowSovProp_ <- as.vector( eval( parse( text=SovPropModel ), envir=Data__ ) )
    Parm1 <- AveSovPropModels_$Parm[[ ListElementName ]][1]
    Parm2 <- AveSovPropModels_$Parm[[ ListElementName ]][2]
    LowSovProp_ <- logistic( LowSovProp_, Parm1, Parm2 )

    # Predict values for higher bound
    Intercept <- 1
    ListElementName <- paste( "LE", HigherBnd, sep="" )
    SovPropModel <- AveSovPropModels_$Model[[ ListElementName ]]
    HighSovProp_ <- as.vector( eval( parse( text=SovPropModel ), envir=Data__ ) )
    Parm1 <- AveSovPropModels_$Parm[[ ListElementName ]][1]
    Parm2 <- AveSovPropModels_$Parm[[ ListElementName ]][2]
    HighSovProp_ <- logistic( HighSovProp_, Parm1, Parm2 )

    # Interpolate between the low and high bounds
    Prop <- ( Threshold - LowerBnd ) / ( HigherBnd - LowerBnd )
    interpolate <- function( x, y ) {
      Low <- min( x, y )
      High <- max( x, y )
      Low + Prop * ( High - Low )
    }
    SovProp_ <- mapply( interpolate, LowSovProp_, HighSovProp_ )
  }

  # Round up small negative numbers to 0
  SovProp_[ SovProp_ < 0 ] <- 0

  # Return the result
  SovProp_

}

#This function calculates DVMT for light vehicles.

#Define a function that calculates DVMT for light vehicles
#----------------------------------------------------------
#' Function to calculate DVMT for light vehicles
#'
#' \code{calcLtVehDvmt} calculates DVMT for light vehicles.
#'
#' This function takes a data frame of households, a distance threshold,
#' a suitable proportion of total DVMT that should be accounted toward
#' light vehicles, and a list of models which are used to calculate proportion
#' of single occupant vehicles for each household.
#' @param Data_ A household data frame consisting of household attributes used to
#' calculate DVMT for light vehicles.
#' @param AveSovPropModels_ A list of SOV propotion models.
#' @param Threshold A numeric (miles) for which SOV model should be used
#' @param PropSuitable A numeric (proportion) indication the proportion of total DVMT
#' accounted by light vehicles
#' @return A numeric representing the light vehicles DVMT for each household
calcLtVehDvmt <- function( Data_, AveSovPropModels_, Threshold, PropSuitable, Sharing=FALSE ) {

  # Calculate the SOV DVMT
  SovProp_ <- calcAveSovProp( Data_, AveSovPropModels_, Threshold )
  SovDvmt_ <- SovProp_ * Data_$Dvmt

  # Calculate the light vehicle ownership ratio
  LtVehPerDrvAgePop_ <- Data_$LtVehCnt / Data_$DrvAgePop
  if( Sharing ) {
    LtVehPerDrvAgePop_ <- LtVehPerDrvAgePop_ / 0.5
  }
  LtVehPerDrvAgePop_[ LtVehPerDrvAgePop_ > 1 ] <- 1


  # Calculate the light vehicle DVMT
  SovDvmt_ * LtVehPerDrvAgePop_ * PropSuitable

}

#This function identifies households that pays for parking.

#Define a function that identifies households that pays for parking
#----------------------------------------------------------
#' Function to identify households that pays for parking
#'
#' \code{idPayingParkers} identifies households that pays for parking.
#'
#' This function takes a data frame of households and various parameters
#' to identify households that pays for parking.
#'
#' @param Data__ A household data frame consisting of household attributes used to
#' identify households that pays for parking.
#' @param PropWrkPkg A numeric for proportion of employees that park at work
#' @param PropWrkChrgd A numeric for proportion of employers that charge for parking
#' @param PropCashOut A numeric for employment parking that is converted from being
#' free to pay under a “cash-out buy-back” type of program
#' @param PropOthChrgd A numeric for proportion of other parking that is not free
#' @param LabForcePartRate A numeric indicating the labor force participation rate
#' (Default: 0.65)
#' @param PkgCost A numeric for average daily parking cost
#' @param PropWrkTrav A numeric for proportion of employees that travel to work
#' @param WrkDaysPerYear A numeric for number of working days per year
#' @return A list.
idPayingParkers <- function( Data__, PropWrkPkg, PropWrkChrgd, PropCashOut, PropOthChrgd,
                             LabForcePartRate=0.65, PkgCost, PropWrkTrav=0.22, WrkDaysPerYear=260 ) {

  # Calculate number of working age persons that pay parking
  PropOthPkg <- 1 - PropWrkPkg
  PropChrgdPkg <- PropWrkChrgd * PropWrkPkg + PropOthChrgd * PropOthPkg
  PropAvailPkg <- PropWrkChrgd * PropWrkPkg + PropOthPkg
  PropWrkPay <- PropWrkChrgd * PropChrgdPkg / PropAvailPkg
  PropWrkAgePay <- PropWrkPay * LabForcePartRate
  NumWrkAgePer <- sum( Data__$DrvAgePop )
  NumWrkAgePay <- round( PropWrkAgePay * NumWrkAgePer )

  # Calculate number of workers paying parking that are cash-out-buy-back
  NumCashOut <- round( NumWrkAgePay * PropCashOut )

  # Identify which persons pay parking
  WrkHhId_ <- rep( Data__$HhId, Data__$DrvAgePop )
  HhIdPay_ <- sample( WrkHhId_ )[ 1:NumWrkAgePay ]

  # Identify which persons get cash reimbursement for parking
  if( NumCashOut >= 1 ) {
    HhIdCashOut_ <- sample( HhIdPay_ )[ 1:NumCashOut ]
  } else {
    HhIdCashOut_ <- NULL
  }

  # Identify the number of persons in each household who pay for parking
  NumPayers_ <- table(HhIdPay_)
  NumPayers_Hh <- numeric( nrow( Data__ ) )
  names( NumPayers_Hh ) <- Data__$HhId
  NumPayers_Hh[ names(NumPayers_) ] <- NumPayers_

  # Identify the number of persons in each household who get reimbursement
  NumCashOut_Hh <- numeric( nrow( Data__ ) )
  names( NumCashOut_Hh ) <- Data__$HhId
  if( !is.null( HhIdCashOut_ ) ) {
    NumCashout_ <- table(HhIdCashOut_)
    NumCashOut_Hh[ names(NumCashout_) ] <- NumCashout_
  }

  # Return the result
  list( NumPayers_Hh=NumPayers_Hh, NumCashOut_Hh=NumCashOut_Hh,
        PropWrkPkg=PropWrkPkg, PropWrkChrgd=PropWrkChrgd, PropCashOut=PropCashOut,
        PropOthChrgd=PropOthChrgd, LabForcePartRate=0.65, PkgCost=PkgCost,
        PropWrkTrav=0.22, WrkDaysPerYear=260 )

}

#This function calculates adjusted parking costs for households

#Define a function that calculates adjusted parking costs for households
#----------------------------------------------------------
#' Function to calculate adjusted parking costs for households
#'
#' \code{calcParkCostAdj} calculates adjusted parking costs for households.
#'
#' This function takes a data frame of households and a list containing
#' attributes of the households that uses parking to calculate adjusted
#' parking costs for those households.
#' @param Data__ A household data frame consisting of household attributes used to
#' calculate adjusted parking costs for households.
#' @param Park_ A list for the attributes of households that uses parking.
#' @return A list containing the daily parking cost, cash-out income adjustment
#' and parking cost per mile for each household.
calcParkCostAdj <- function( Data__, Park_ ) {

  NumPayers_Hh <- Park_$NumPayers_Hh
  NumCashOut_Hh <- Park_$NumCashOut_Hh
  PropWrkChrgd <- Park_$PropWrkChrgd
  PkgCost <- Park_$PkgCost
  PropOthChrgd <- Park_$PropOthChrgd
  PropWrkPkg <- Park_$PropWrkPkg
  PropWrkTrav <- Park_$PropWrkTrav
  LabForcePartRate <- Park_$LabForcePartRate
  WrkDaysPerYear <- Park_$WrkDaysPerYear

  # Sum the daily work parking costs by household
  WrkPkgCost_Hh <- NumPayers_Hh * PkgCost

  # Add daily parking cost for non-work travel
  OthPkgCost_Hh <- WrkPkgCost_Hh * 0  # Initialize vector
  OthPkgCost_Hh[] <- PkgCost * PropOthChrgd * ( 1 - PropWrkTrav )

  # Add the work daily parking cost to the other daily parking cost
  DailyPkgCost_Hh <- WrkPkgCost_Hh + OthPkgCost_Hh
  DailyPkgCost_Hh[ Data__$Vehicles == 0 ] <- 0

  # Calculate the parking cost per mile
  PkgCostMile_Hh <- numeric( length( DailyPkgCost_Hh ) )
  PkgCostMile_Hh[ DailyPkgCost_Hh > 0 ] <-
    100 * DailyPkgCost_Hh[ DailyPkgCost_Hh > 0 ] / Data__$Dvmt[ DailyPkgCost_Hh > 0 ]

  # Sum the cash out parking income adjustment by household
  CashOutIncAdj_Hh <- NumCashOut_Hh * PkgCost * WrkDaysPerYear

  # Return the result
  list( DailyPkgCost=DailyPkgCost_Hh, CashOutIncAdj=CashOutIncAdj_Hh,
        PkgCostMile=PkgCostMile_Hh )

}


#Main module function that adjusts DVMT
#------------------------------------------------------
#' Function to adjusts DVMT for the policies entered for the scenario
#'
#' \code{CalculatePolicyVmt} adjusts DVMT for the policies entered for
#' the scenario
#'
#' This function recalculates DVMT by placetypes, households, and vehicles.
#' It calculates light vehicles and light vehicles DVMT for households.
#' It also adjusts income after calculating daily parking costs and cash-out
#' income.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculatePolicyVmt <- function(L) {
  #Set up
  #------

  # Function to rename variables to be consistent with Get specfications
  # of CalculatePolicyVmt.

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
        yesList <- lapply(x[isElementList], AddSuffixFuture, suffix = suffix)
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
        yesList <- lapply(x[isElementList], RemoveSuffixFuture, suffix = suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }

  # Modify the input data set
  L <- RemoveSuffixFuture(L)

  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  # Load Household data
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$Urban <- 1

  # Identify metropolitan area
  IsMetro_ <- Hh_df$Urban == 1

  # Collect all the required parameters
  TDMRideSharing <- data.frame(L$Global$TDMRidesharing)
  TDMPrograms <- data.frame(L$Global$CommuteOptions)
  TDMTransitLevels <- data.frame(L$Global$TDMTransitLevels)
  TDMTransit <- data.frame(L$Global$TDMTransit)
  TDMVanpooling <- data.frame(L$Global$TDMVanpooling)
  TDMWorkSchedule <- data.frame(L$Global$TDMWorkschedule)
  TDMWorkScheduleLevels <- data.frame(L$Global$TDMWorkscheduleLevels)
  LightVehiclesInfo <- data.frame(L$Global$LightVehiclesInfo)

  # Apply travel demand management policies
  #========================================
  #Evaluate effectiveness

  #Ridesharing
  TDMRidesharingEffect_At <- TDMRideSharing[,"Effectiveness"] *
    TDMPrograms[TDMPrograms$DataItem == "RidesharingParticipation","DataValue"]
  names(TDMRidesharingEffect_At) <- TDMRideSharing[,"ModelGeo"]

  #Transit
  if(length(TDMTransitLevels$SubsidyValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="TransitSubsidyLevel"]) > 0) {
    minGreaterValue_ <- TDMTransitLevels$SubsidyValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="TransitSubsidyLevel"]
    subsidylevel <- as.character(TDMTransitLevels$SubsidyLevel[minGreaterValue_][which.min(TDMTransitLevels$SubsidyValue[minGreaterValue_])])
  } else {
    subsidylevel <- as.character(TDMTransitLevels$SubsidyLevel[which.max(TDMTransitLevels$SubsidyValue)])
  }

  subsidyhigh <- which(TDMTransitLevels$SubsidyLevel == subsidylevel)
  subsidylow <- subsidyhigh - 1
  subsidyratio <- (TDMTransitLevels[subsidyhigh,"SubsidyValue"] - TDMPrograms$DataValue[TDMPrograms$DataItem == "TransitSubsidyLevel"])/(TDMTransitLevels[subsidyhigh,"SubsidyValue"] - TDMTransitLevels[subsidylow,"SubsidyValue"])
  TDMTransitEffect_At <- TDMTransit[,subsidyhigh+1] - subsidyratio * (TDMTransit[,subsidyhigh+1] - TDMTransit[,subsidylow+1])
  names(TDMTransitEffect_At) <- TDMTransit$ModelGeo

  #Work Schedules
  #Schedule 980
  if(length(TDMWorkScheduleLevels$ParticipationValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="Schedule980Participation"]) > 0) {
    minGreaterValue_ <- TDMWorkScheduleLevels$ParticipationValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="Schedule980Participation"]
    participationlevel <- as.character(TDMWorkScheduleLevels$ParticipationLevel[minGreaterValue_][which.min(TDMWorkScheduleLevels$ParticipationValue[minGreaterValue_])])
  } else {
    participationlevel <- as.character(TDMWorkScheduleLevels$ParticipationLevel[which.max(TDMWorkScheduleLevels$ParticipationValue)])
  }

  participationhigh <- which(TDMWorkScheduleLevels$ParticipationLevel == participationlevel)
  participationlow <- participationhigh - 1
  participationratio <- (TDMWorkScheduleLevels[participationhigh,"ParticipationValue"] - TDMPrograms$DataValue[TDMPrograms$DataItem == "Schedule980Participation"])/(TDMWorkScheduleLevels[participationhigh,"ParticipationValue"] - TDMWorkScheduleLevels[participationlow,"ParticipationValue"])
  TDMSchedule980Effect <- TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="Schedule980",participationhigh+1] - participationratio * (TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="Schedule980",participationhigh+1] - TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="Schedule980",participationlow+1])

  #Schedule 440
  if(length(TDMWorkScheduleLevels$ParticipationValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="Schedule440Participation"]) > 0) {
    minGreaterValue_ <- TDMWorkScheduleLevels$ParticipationValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="Schedule440Participation"]
    participationlevel <- as.character(TDMWorkScheduleLevels$ParticipationLevel[minGreaterValue_][which.min(TDMWorkScheduleLevels$ParticipationValue[minGreaterValue_])])
  } else {
    participationlevel <- as.character(TDMWorkScheduleLevels$ParticipationLevel[which.max(TDMWorkScheduleLevels$ParticipationValue)])
  }

  participationhigh <- which(TDMWorkScheduleLevels$ParticipationLevel == participationlevel)
  participationlow <- participationhigh - 1
  participationratio <- (TDMWorkScheduleLevels[participationhigh,"ParticipationValue"] - TDMPrograms$DataValue[TDMPrograms$DataItem == "Schedule440Participation"])/(TDMWorkScheduleLevels[participationhigh,"ParticipationValue"] - TDMWorkScheduleLevels[participationlow,"ParticipationValue"])
  TDMSchedule440Effect <- TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="Schedule440",participationhigh+1] - participationratio * (TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="Schedule440",participationhigh+1] - TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="Schedule440",participationlow+1])

  #Telecommute 1.5 Days
  if(length(TDMWorkScheduleLevels$ParticipationValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="Telecommute1.5DaysParticipation"]) > 0) {
    minGreaterValue_ <- TDMWorkScheduleLevels$ParticipationValue > TDMPrograms$DataValue[TDMPrograms$DataItem=="Telecommute1.5DaysParticipation"]
    participationlevel <- as.character(TDMWorkScheduleLevels$ParticipationLevel[minGreaterValue_][which.min(TDMWorkScheduleLevels$ParticipationValue[minGreaterValue_])])
  } else {
    participationlevel <- as.character(TDMWorkScheduleLevels$ParticipationLevel[which.max(TDMWorkScheduleLevels$ParticipationValue)])
  }

  participationhigh <- which(TDMWorkScheduleLevels$ParticipationLevel == participationlevel)
  participationlow <- participationhigh - 1
  participationratio <- (TDMWorkScheduleLevels[participationhigh,"ParticipationValue"] - TDMPrograms$DataValue[TDMPrograms$DataItem == "Telecommute1.5DaysParticipation"])/(TDMWorkScheduleLevels[participationhigh,"ParticipationValue"] - TDMWorkScheduleLevels[participationlow,"ParticipationValue"])
  TDMTelecommute1_5DaysEffect <- TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="TelecommuteoneandhalfDays",participationhigh+1] - participationratio * (TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="TelecommuteoneandhalfDays",participationhigh+1] - TDMWorkSchedule[TDMWorkSchedule$WorkSchedulePolicy=="TelecommuteoneandhalfDays",participationlow+1])

  #Total Effectiveness
  TDMScheduleEffect <- TDMSchedule980Effect + TDMSchedule440Effect + TDMTelecommute1_5DaysEffect

  #Vanpooling
  TDMVanpoolEffect <- sum(TDMVanpooling$VMTReduction * TDMPrograms$DataValue[TDMPrograms$TDMProgram == "Vanpooling"])

  #Total effect by Area Type
  TDMEffect_At <- TDMRidesharingEffect_At + TDMTransitEffect_At + TDMScheduleEffect + TDMVanpoolEffect
  #Convert to effect on total VMT using proportion of VMT for work trips
  TDMEffect_At <- TDMEffect_At * L$Global$Model$WorkVmtProp # Set it as a global variable

  #Create a list of reductions for each household
  TdmAdjFactor_Hh <- 1 - TDMEffect_At[unlist(lapply(strsplit(as.character(Hh_df$HhPlaceTypes),"_"),function(x) x[1]))]

  # Calculate the light vehicle adjustment factor
  #==============================================
  # Predict light vehicle ownership
  LtVehOwn_Hh <- rep( 0, nrow( Hh_df ) )
  ###CS Note this is problematic as actual density not calculated - need to use 5D density adjustment from average by place type
  Hh_df$Htppopdn <- 500
  Hh_df$LogDen <- log( Hh_df$Htppopdn )
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$VehPerDrvAgePop <- Hh_df$Vehicles/Hh_df$DrvAgePop
  ModelVar_ <- c( "LogDen", "HhSize", "Income", "Age15to19", "Age20to29", "Age30to54",
                  "Age55to64", "Age65Plus", "VehPerDrvAgePop", "DrvAgePop" )
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  if( any( IsMetro_ ) ) {
    LtVehOwn_Hh[ IsMetro_ ] <- predictLightVehicles( Hh_df[ IsMetro_, ModelVar_ ],
                                                     LtVehOwnModels_=LtVehOwnModels_ls, Type="Metro",
                                                     TargetProp=LightVehiclesInfo$DataValue[LightVehiclesInfo$DataItem=="TargetProp"] )
  }
  if( any( !IsMetro_ ) ) {
    LtVehOwn_Hh[ !IsMetro_ ] <- predictLightVehicles( Hh_df[ !IsMetro_, ModelVar_ ],
                                                      LtVehOwnModels_=LtVehOwnModels_ls, Type="NonMetro",
                                                      TargetProp=LightVehiclesInfo$DataValue[LightVehiclesInfo$DataItem=="TargetProp"] )
  }
  Hh_df$LtVehCnt <- LtVehOwn_Hh
  rm( LtVehOwn_Hh, ModelVar_ )
  Hh_df$LogDen <- NULL

  # Predict light vehicle DVMT
  #---------------------------
  LtVehDvmt_Hh <- Hh_df$Dvmt
  ###CS Note this is problematic as actual density not calculated - need to use 5D density adjustment from average by place type
  Hh_df$LogDen <- log( Hh_df$Htppopdn )
  Hh_df$LogSize <- log( Hh_df$HhSize )
  Hh_df$LogDvmt <- log( Hh_df$Dvmt )
  ModelVar_ <- c( "Income", "LogDen", "LogSize", "Urban", "LogDvmt", "Dvmt", "LtVehCnt",
                  "DrvAgePop" )
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  if( any( IsMetro_ ) ) {
    LtVehDvmt_Hh[ IsMetro_ ] <- calcLtVehDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                               AveSovPropModels_ls,
                                               Threshold=LightVehiclesInfo$DataValue[
                                                 LightVehiclesInfo$DataItem=="Threshold"],
                                               PropSuitable=LightVehiclesInfo$DataValue[
                                                 LightVehiclesInfo$DataItem=="PropSuitable"],
                                               Sharing=FALSE )
  }
  if( any( !IsMetro_ ) ) {
    LtVehDvmt_Hh[ !IsMetro_ ] <- calcLtVehDvmt( Hh_df[ !IsMetro_, ModelVar_ ],
                                                AveSovPropModels_ls,
                                                Threshold=LightVehiclesInfo$DataValue[
                                                  LightVehiclesInfo$DataItem=="Threshold"],
                                                PropSuitable=LightVehiclesInfo$DataValue[
                                                  LightVehiclesInfo$DataItem=="PropSuitable"],
                                                Sharing=FALSE )
  }
  # Calculate adjustment factor
  LtVehAdjFactor_Hh <- ( Hh_df$Dvmt - LtVehDvmt_Hh ) / Hh_df$Dvmt
  LtVehAdjFactor_Hh[ Hh_df$Dvmt == 0 ] <- 1

  # Calculate overall adjustment factor and apply to adjust DVMT
  #-------------------------------------------------------------
  TdmLtVehAdjFactor_Hh <- TdmAdjFactor_Hh * LtVehAdjFactor_Hh
  Hh_df$TdmLtVehAdjFactor <- TdmLtVehAdjFactor_Hh
  Hh_df$TdmAdjFactor <- TdmAdjFactor_Hh
  Hh_df$LtVehAdjFactor_Hh <- LtVehAdjFactor_Hh
  Hh_df$Dvmt <- Hh_df$Dvmt * TdmLtVehAdjFactor_Hh
  rm( TdmAdjFactor_Hh, LtVehAdjFactor_Hh, TdmLtVehAdjFactor_Hh, ModelVar_ )
  Hh_df$LogDen <- NULL
  Hh_df$LogSize <- NULL
  Hh_df$LogDvmt <- NULL

  #Apply parking model to identify parkers and calculate daily parking costs
  #=========================================================================
  Hh_df$DailyPkgCost <- 0
  Hh_df$CashOutIncAdj <- 0
  ModelVar_ <- c( "DrvAgePop", "HhId", "Dvmt", "Vehicles" )
  ParkingAttributes <- c("PropWorkParking", "PropWorkCharged","PropCashOut", "PropOtherCharged", "ParkingCost")
  ParkingCosts_Yr <- data.frame(L$Year$Marea)[,ParkingAttributes]
  #fix seed as model involves sampling
  set.seed(L$G$Seed)
  if( any( IsMetro_ ) ) {
    Parkers_ <- idPayingParkers( Hh_df[ IsMetro_, ModelVar_ ],
                                 PropWrkPkg=ParkingCosts_Yr[,"PropWorkParking"],
                                 PropWrkChrgd=ParkingCosts_Yr[,"PropWorkCharged"],
                                 PropCashOut=ParkingCosts_Yr[,"PropCashOut"],
                                 PropOthChrgd=ParkingCosts_Yr[,"PropOtherCharged"],
                                 PkgCost=ParkingCosts_Yr[,"ParkingCost"],
                                 PropWrkTrav=0.22, WrkDaysPerYear=260 )
    PkgCosts_ <- calcParkCostAdj( Hh_df[ IsMetro_, ModelVar_ ], Parkers_ )
    Hh_df$DailyPkgCost[ IsMetro_ ] <- PkgCosts_$DailyPkgCost
    Hh_df$CashOutIncAdj[ IsMetro_ ] <- PkgCosts_$CashOutIncAdj
    Hh_df$Income[ IsMetro_ ] <- Hh_df$Income[ IsMetro_ ] + PkgCosts_$CashOutIncAdj
    rm( Parkers_, PkgCosts_ )
  }
  rm( ModelVar_ )
  gc()

  #Calculate household travel costs
  #================================

  #Gather cost parameters into costs.
  if(is.null(L$Global$Model$VmtCost)){
    L$Global$Model$VmtCost <- 0
  }
  if(is.null(L$Global$Model$CarbonCost)){
    L$Global$Model$CarbonCost <- 0
  }
  Costs_ <- c(L$Global$Model$FuelCost,
              L$Global$Model$GasTax,
              L$Global$Model$CarbonCost,
              L$Global$Model$VmtCharge,
              L$Global$Model$KwhCost)
  names(Costs_) <- c("FuelCost","GasTax","CarbonCost","VmtCost", "KwhCost")

  #Apply auto operating cost growth
  #This applies to FuelCost and Gas Tax only
  #It does not apply to the separate policy inputs of VmtCost and Carbon Cost
  #Note that CarbonCost is not currently used in the SHRP2C16 model
  Costs_[c("FuelCost","GasTax", "KwhCost")] <- Costs_[c("FuelCost","GasTax", "KwhCost")] *
    L$Global$Model$AutoCostGrowth

  ModelVar_ <- c( "FuelGallons", "FuelCo2e",
                  "ElecCo2e", "ElecKwh", "Income",
                  "Dvmt", "DailyPkgCost", "Vehicles", "HhId" )


  Costs_Hh <- calculateCosts( Hh_df[ , ModelVar_ ], Costs_ )
  Hh_df$FutureCostPerMile <- Costs_Hh$FutrCostPerMi
  rm( Costs_Hh, ModelVar_ )
  gc()

  # Calculate DVMT with new costs
  #==============================
  #Save starting Dvmt for application of adjustments to vehicles
  PrevDvmt_Hh <- Hh_df$Dvmt

  Hh_df$TranRevMiPC <- L$Year$Marea$TranRevMiPC
  Hh_df$FwyLaneMiPC <- L$Year$Marea$FwyLaneMiPC
  Hh_df$BaseCostPerMile <- L$Global$Model$BaseCostPerMile
  ModelVar_ <- c( "Income", "Htppopdn", "Vehicles", "TranRevMiPC",
                  "FwyLaneMiPC", "DrvAgePop", "HhSize", "Age0to14",
                  "Age15to19", "Age20to29", "Age30to54", "Age55to64",
                  "Age65Plus", "Urban", "BaseCostPerMile", "FutureCostPerMile" )

  if( any( IsMetro_ ) ) {
    Hh_df$Dvmt[ IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                   DvmtLmModels_ls,
                                                   "Metro",
                                                   BudgetProp=L$Global$Model$DvmtBudgetProp,
                                                   AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                   TrnstnProp=1 )[[1]]
  }
  if( any( !IsMetro_ ) ) {
    Hh_df$Dvmt[ !IsMetro_ ] <- calculateAdjAveDvmt( Hh_df[ IsMetro_, ModelVar_ ],
                                                    DvmtLmModels_ls,
                                                    "NonMetro",
                                                    BudgetProp=L$Global$Model$DvmtBudgetProp,
                                                    AnnVmtInflator=L$Global$Model$AnnVmtInflator,
                                                    TrnstnProp=1 )[[1]]
  }

  # Adjust for urban form and TDM
  #===============================
  Hh_df$Dvmt <- Hh_df$Dvmt * Hh_df$DvmtPtAdj
  Hh_df$Dvmt <- Hh_df$Dvmt * Hh_df$TdmLtVehAdjFactor

  # Split adjusted DVMT among vehicles
  #===================================
  Vehicles_df <- data.frame(L$Year$Vehicle)
  DvmtAdjFactor_Hh <- Hh_df$Dvmt / PrevDvmt_Hh
  names(DvmtAdjFactor_Hh) <- as.character(Hh_df$HhId)
  Vehicles_df$Dvmt <- Vehicles_df$Dvmt * DvmtAdjFactor_Hh[as.character(Vehicles_df$HhId)]
  Vehicles_df$EvDvmt <- Vehicles_df$EvDvmt * DvmtAdjFactor_Hh[as.character(Vehicles_df$HhId)]
  Vehicles_df$HcDvmt <- Vehicles_df$HcDvmt * DvmtAdjFactor_Hh[as.character(Vehicles_df$HhId)]
  rm( DvmtAdjFactor_Hh)
  gc()

  # Sum up DVMT by place type
  #================================
  DvmtPt_ <- rowsum( Hh_df$Dvmt, Hh_df$HhPlaceTypes)[,1]
  DvmtPt_ <- DvmtPt_[as.character(L$Year$Bzone$Bzone)]
  DvmtPt_[is.na(DvmtPt_)] <- 0
  names(DvmtPt_) <- as.character(L$Year$Bzone$Bzone)

  HhPt_ <- Hh_df$HhPlaceTypes
  names(HhPt_) <- as.character(Hh_df$HhId)

  EvDvmtPt_ <- rowsum(Vehicles_df$EvDvmt, HhPt_[as.character(Vehicles_df$HhId)])[,1]
  EvDvmtPt_ <- EvDvmtPt_[as.character(L$Year$Bzone$Bzone)]
  EvDvmtPt_[is.na(EvDvmtPt_)] <- 0
  names(EvDvmtPt_) <- as.character(L$Year$Bzone$Bzone)

  HcDvmtPt_ <- rowsum(Vehicles_df$HcDvmt, HhPt_[as.character(Vehicles_df$HhId)])[,1]
  HcDvmtPt_ <- HcDvmtPt_[as.character(L$Year$Bzone$Bzone)]
  HcDvmtPt_[is.na(HcDvmtPt_)] <- 0
  names(HcDvmtPt_) <- as.character(L$Year$Bzone$Bzone)


  #Return the results
  Out_ls <- initDataList()
  Out_ls$Year <- list(
    Bzone = list(),
    Household = list(),
    Vehicle = list()
  )
  # Global results
  Out_ls$Global <- list(
    Model = list(
      Costs = Costs_,
      CostsId = names(Costs_)
    )
  )
  # Bzone results
  Out_ls$Year$Bzone <- list(
    Dvmt = DvmtPt_,
    EvDvmt = EvDvmtPt_,
    HcDvmt = HcDvmtPt_
  )
  # Household results
  Out_ls$Year$Household <- list(
    LtVehicles = Hh_df$LtVehCnt,
    LtVehAdjFactor = Hh_df$LtVehAdjFactor_Hh,
    LtVehDvmt = LtVehDvmt_Hh,
    TdmLtVehAdjFactor = Hh_df$TdmLtVehAdjFactor,
    TdmAdjFactor = Hh_df$TdmAdjFactor,
    Dvmt = Hh_df$Dvmt,
    DailyParkingCost = Hh_df$DailyPkgCost,
    CashOutIncAdj = Hh_df$CashOutIncAdj,
    Income = Hh_df$Income,
    FutureCostPerMile = Hh_df$FutureCostPerMile
  )
  # Vehicle results
  Out_ls$Year$Vehicle <-list(
    Dvmt = as.numeric(Vehicles_df$Dvmt),
    EvDvmt = as.numeric(Vehicles_df$EvDvmt),
    HcDvmt = as.numeric(Vehicles_df$HcDvmt)
  )
  Out_ls <- AddSuffixFuture(Out_ls, suffix = "Policy")
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
#   ModuleName = "CalculatePolicyVmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L
# R <- CalculatePolicyVmt(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculatePolicyVmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
