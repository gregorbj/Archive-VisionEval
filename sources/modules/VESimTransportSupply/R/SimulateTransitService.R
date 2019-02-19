#========================
#SimulateTransitService.R
#========================

#<doc>
#
## SimulateTransitService Module
#### February 11, 2019
#
#This module assigns transit service level to the urbanized portion of each Marea and to neighborhoods (SimBzones) within the urbanized area. Annual revenue-miles (i.e. transit miles in revenue service) by transit mode type are read from an input file. The following 8 modes are recognized:
#
#* DR = Demand-responsive
#
#* VP = Vanpool and similar
#
#* MB = Standard motor bus
#
#* RB = Bus rapid transit and commuter bus
#
#* MG = Monorail/automated guideway
#
#* SR = Streetcar/trolley bus/inclined plain
#
#* HR = Heavy Rail/Light Rail
#
#* CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#
#Revenue miles are converted to bus (i.e. MB) equivalents using factors derived from urbanized are data from the National Transit Database (NTD). Bus-equivalent revenue miles are used in models which predict vehicle ownership and household DVMT.
#
#Revenue miles by mode type are also translated (using NTD data) into vehicle miles by 3 vehicle types: van, bus, and rail. Miles by vehicle type are used to calculate public transit energy consumption and emissions.
#
#The module also simulates relative public transit accessibility by Bzone as explained below.
#
### Model Parameter Estimation
#
#Parameters are calculated to convert the revenue miles for each of the 8 recognized public transit modes into bus equivalents, and to convert revenue miles into vehicle miles. Data extracted from the 2015 National Transit Database (NTD) are used to calculate these parameters. Bus equivalent factors for each of the 8 modes is calculated on the basis of the average productivity of each mode as measured by the ratio of passenger miles to revenue miles. The bus-equivalency factor of each mode is the ratio of the average productivity of the mode to the average productivity of the bus (MB) mode. Factors to compute vehicle miles by mode from revenue miles by mode are calculated from the NTD data on revenue miles and deadhead (i.e. out of service) miles. The vehicle mile factor is the sum of revenue and deadhead miles divided by the revenue miles. These factors vary by mode. These model parameters are estimated by the *AssignTransitService* module in the *VETransportSupply* package and are imported into this module.
#
#A model is also estimated to calculate SimBzone transit accessibility which measures how easily transit service may be accessed from each zone. The Smart Location Database includes several transit accessibility measures. The D4c measure is the one used in the forthcoming multimodal household travel module. D4c is a measure of the aggregate frequency of transit service within 0.25 miles of the block group boundary per hour during evening peak period (4:00 PM to 7:00 PM). The D4c simulation model simulates SimBzone D4c values as a function of the level of transit service in the urbanized area, the relationship between the average D4c value for the urbanized area and the level of transit service, and the place types of the SimBzones (where place type is the combination of area type and development type). This model is estimated by the *CreateSimBzoneModels* module in the *VESimLandUse* package and is documented there. It is imported into this module.
#
### How the Module Work
#
#The user supplies data on the annual revenue miles of service by each of the 8 transit modes for each Marea. These revenue miles are converted to bus equivalents using the estimated bus-equivalency factors and summed to calculate total bus-equivalent revenue miles. This value is divided by the urbanized area population of the Marea to compute bus-equivalent revenue miles per capita. This public transit service measure is used in models of household vehicle ownership and household vehicle travel.
#
#The user supplied revenue miles by mode are translated into vehicle miles by mode using the estimated conversion factors. The results are then simplified into 3 vehicle types (Van, Bus, Rail) where the DR and VP modes are assumed to be served by vans, the MB and RB modes are assumed to be served by buses, and the MG, SR, HR, and CR modes are assumed to be served by rail.
#
#</doc>

#Load libraries for module development
library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Models used by this module are estimated by the *AssignTransitService* module in the *VETransportSupply* package and the *CreateSimBzoneModels* module in the *VESimLandUse* package.
#
#Load and save the bus equivalency factors
#-----------------------------------------
#' @import VETransportSupply
#
#Import bus equivalency factors
BusEquivalents_df <- VETransportSupply::BusEquivalents_df
#Save the bus equivalency factors
#' Bus equivalency factors
#'
#' Bus revenue mile equivalency factors to convert revenue miles for various
#' modes to bus-equivalent revenue miles.
#'
#' @format A data frame with 8 rows and 2 variables containing factors for
#' converting revenue miles of various modes to bus equivalent revenue miles.
#' Mode names are 2-character codes corresponding to consolidated mode types.
#' Consolidated mode types represent modes that have similar characteristics and
#' bus equivalency values. The consolidate mode codes and their meanings are as
#' follows:
#' DR = Demand-responsive
#' VP = Vanpool and similar
#' MB = Standard motor bus
#' RB = Bus rapid transit and commuter bus
#' MG = Monorail/automated guideway
#' SR = Streetcar/trolley bus/inclined plain
#' HR = Heavy Rail/Light Rail
#' CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#'
#' \describe{
#'   \item{Mode}{abbreviation for consolidated mode}
#'   \item{BusEquivalents}{numeric factor for converting revenue miles to bus equivalents}
#' }
#' @source AssignTransitService.R script.
"BusEquivalents_df"
usethis::use_data(BusEquivalents_df, overwrite = TRUE)

#Load and save the vehicle mile factors
#--------------------------------------
#' @import VETransportSupply
#
#Load the vehicle mile factors
VehMiFactors_df <- VETransportSupply::VehMiFactors_df
#Save the vehicle mile factors
#' Revenue miles to vehicle miles conversion factors
#'
#' Vehicle mile factors convert revenue miles for various modes to vehicle
#' miles for those modes.
#'
#' @format A data frame with 8 rows and 2 variables containing factors for
#' converting revenue miles of various modes to vehicle miles.
#' Mode names are 2-character codes corresponding to consolidated mode types.
#' Consolidated mode types represent modes that have similar characteristics and
#' bus equivalency values. The consolidate mode codes and their meanings are as
#' follows:
#' DR = Demand-responsive
#' VP = Vanpool and similar
#' MB = Standard motor bus
#' RB = Bus rapid transit and commuter bus
#' MG = Monorail/automated guideway
#' SR = Streetcar/trolley bus/inclined plain
#' HR = Heavy Rail/Light Rail
#' CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#'
#' \describe{
#'   \item{Mode}{abbreviation for consolidated mode}
#'   \item{VehMiFactors}{numeric factors for converting revenue miles to
#'   vehicle miles}
#' }
#' @source AssignTransitService.R script.
"VehMiFactors_df"
usethis::use_data(VehMiFactors_df, overwrite = TRUE)

#Load and save the D4c model parameters
#--------------------------------------
#' @import VESimLandUse
#
#Make a list to store model components
D4cModels_ls <- list()
#Load D4c percentiles by place type
D4cModels_ls$NormD4_PtQt <- VESimLandUse::SimBzone_ls$UaProfiles$NormD4_PtQt
#Load D4 supply ratios
D4cModels_ls$D4SupplyRatio_Ua <- VESimLandUse::SimBzone_ls$UaProfiles$D4SupplyRatio_Ua
#Load linear model to predict urbanized area average D4c value
D4cModels_ls$AveD4cModel_ls <- VESimLandUse::SimBzone_ls$UaProfiles$AveD4cModel_ls
#Save the D4c models
#' D4c simulation models
#'
#' Models to predict average D4c value for urbanized area and to the predict the
#' D4c values for SimBzones from the urbanized area average and from the
#' SimBzones place types.
#'
#' @format a list containing 3 components
#'
#' \describe{
#'   \item{NormD4_PtQt}{matrix of normalized D4c values by place type and quantile}
#'   \item{D4SupplyRatio_Ua}{numeric vector of urbanized area average D4c values by urbanized area}
#'   \item{AveD4cModel_ls}{list containing components for linear model to predict urbanized area average D4c model}
#' }
#' @source SimulateTransitService.R script
"D4cModels_ls"
usethis::use_data(D4cModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
SimulateTransitServiceSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "DRRevMi",
          "VPRevMi",
          "MBRevMi",
          "RBRevMi",
          "MGRevMi",
          "SRRevMi",
          "HRRevMi",
          "CRRevMi"),
      FILE = "marea_transit_service.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/YR",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        list(
          "Annual revenue-miles of demand-responsive public transit service",
          "Annual revenue-miles of van-pool and similar public transit service",
          "Annual revenue-miles of standard bus public transit service",
          "Annual revenue-miles of rapid-bus and commuter bus public transit service",
          "Annual revenue-miles of monorail and automated guideway public transit service",
          "Annual revenue-miles of streetcar and trolleybus public transit service",
          "Annual revenue-miles of light rail and heavy rail public transit service",
          "Annual revenue-miles of commuter rail, hybrid rail, cable car, and aerial tramway public transit service"
        )
    )
  ),
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
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "DRRevMi",
          "VPRevMi",
          "MBRevMi",
          "RBRevMi",
          "MGRevMi",
          "SRRevMi",
          "HRRevMi",
          "CRRevMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/YR",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UzaProfileName",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("center", "inner", "outer", "fringe")
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("emp", "mix", "res")
    ),
    item(
      NAME = "UrbanArea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TotEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "TranRevMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of annual bus-equivalent revenue-miles (i.e. revenue-miles at the same productivity - passenger miles per revenue mile - as standard bus) to urbanized area population"
    ),
    item(
      NAME =
        items(
          "VanDvmt",
          "BusDvmt",
          "RailDvmt"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Total daily miles traveled by vans of various sizes to provide demand responsive, vanpool, and similar services.",
        "Total daily miles traveled by buses of various sizes to provide bus service of various types.",
        "Total daily miles traveled by light rail, heavy rail, commuter rail, and similar types of vehicles."
        )
    ),
    item(
      NAME = "D4c",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "aggregate peak period transit service",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period (Ref: EPA 2010 Smart Location Database)"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for SimulateTransitService module
#'
#' A list containing specifications for the SimulateTransitService module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source SimulateTransitService.R script.
"SimulateTransitServiceSpecifications"
usethis::use_data(SimulateTransitServiceSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the annual bus equivalent revenue miles per capita for
#the urbanized area from the number of annual revenue miles for different
#public transit modes and the urban area population.

#Main module function that calculates bus equivalent revenue miles per capita
#----------------------------------------------------------------------------
#' Calculate bus equivalent revenue miles per capita by Marea.
#'
#' \code{SimulateTransitService} calculate bus equivalent revenue miles per capita.
#'
#' This function calculates bus equivalent revenue miles per capita for each
#' Marea.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name SimulateTransitService
#' @import visioneval
#' @export
SimulateTransitService <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of modes
  Md <- as.character(BusEquivalents_df$Mode)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea

  #Calculate bus equivalent revenue miles
  #--------------------------------------
  #Make table of revenue miles by Marea
  RevMi_df <- data.frame(L$Year$Marea[paste0(Md, "RevMi")])
  colnames(RevMi_df) <- Md
  rownames(RevMi_df) <- Ma
  if (any(rownames(RevMi_df) == "None")) RevMi_df["None",] <- 0
  RevMi_MaMd <- as.matrix(RevMi_df)
  #Calculate the bus equivalent revenue miles
  BusEq_Md <- BusEquivalents_df$BusEquivalents
  names(BusEq_Md) <- Md
  BusEqRevMi_Ma <-
    rowSums(sweep(RevMi_MaMd, 2, BusEq_Md, "*"))[Ma]

  #Calculate the bus equivalent revenue miles per capita
  #-----------------------------------------------------
  #Calculate population in the urbanized area
  UrbanPop_Ma <-
    tapply(L$Year$Bzone$UrbanPop, L$Year$Bzone$Marea, sum)[Ma]
  #Calculate Marea bus equivalent revenue miles per capita
  TranRevMiPC_Ma <- BusEqRevMi_Ma / UrbanPop_Ma
  TranRevMiPC_Ma[is.na(TranRevMiPC_Ma)] <- 0

  #Calculate vehicle miles by vehicle type
  #---------------------------------------
  #Make vector of vehicle miles factors conforming with RevMi_df
  VehMiFactors_Md <- VehMiFactors_df$VehMiFactors
  names(VehMiFactors_Md) <- VehMiFactors_df$Mode
  VehMiFactors_Md <- VehMiFactors_Md[names(RevMi_df)]
  #Calculate daily vehicle miles by Marea and mode
  VehMi_MaMd <- as.matrix(sweep(RevMi_df, 2, VehMiFactors_Md, "*")) / 365
  #Define correspondence between modes and vehicle types
  ModeToVehType_ <- c(
    DR = "Van",
    VP = "Van",
    MB = "Bus",
    RB = "Bus",
    MG = "Rail",
    SR = "Rail",
    HR = "Rail",
    CR = "Rail"
  )
  ModeToVehType_ <- ModeToVehType_[colnames(VehMi_MaMd)]
  VehMi_df <-
    data.frame(
      t(
        apply(VehMi_MaMd, 1, function(x) {
          tapply(x, ModeToVehType_, sum) })
        )
      )
  VehMi_df[is.na(VehMi_df)] <- 0

  #Calculate Marea urban average D4c
  #---------------------------------
  #Get estimated average D4c values where exist
  UaName_Ma <- setNames(L$Global$Marea$UzaProfileName, Ma)
  AveD4c_Ma <- setNames(numeric(length(Ma)), Ma)
  for (ma in Ma) {
    AveD4c_Ma[ma] <- D4cModels_ls$D4SupplyRatio_Ua[UaName_Ma[ma]]
  }
  #Identify Mareas having no average D4c values
  MaNoD4c_ <- Ma[Ma != "None" & is.na(AveD4c_Ma)]
  #Model average D4c values for Mareas where values are missing
  AveD4c_Mx <- local({
    TranRevMi_Mx <- BusEqRevMi_Ma[MaNoD4c_]
    UrbanAcres_Mx <- with(L$Year$Bzone, tapply(UrbanArea, Marea, sum))[MaNoD4c_]
    TotAct_Mx <- with(L$Year$Bzone, tapply(NumHh + TotEmp, Marea, sum))[MaNoD4c_]
    TranRevMiPerAc_Mx <- TranRevMi_Mx / UrbanAcres_Mx
    AveD1D_Mx <- TotAct_Mx / UrbanAcres_Mx
    Data_df <- data.frame(
        TranRevMiPerAc = TranRevMiPerAc_Mx,
        AveD1D = AveD1D_Mx)
    AveD4c_Mx <- applyLinearModel(D4cModels_ls$AveD4cModel_ls, Data_df)
    AveD4c_Mx[TranRevMi_Mx == 0] <- 0
    AveD4c_Mx
  })
  AveD4c_Ma[MaNoD4c_] <- AveD4c_Mx
  if (any(names(AveD4c_Ma) == "None")) AveD4c_Ma["None"] <- 0

  #Calculate SimBzone D4c values
  #-----------------------------
  PlaceType_Bz <- with(L$Year$Bzone, paste(AreaType, DevType, sep = "."))
  NormD4_Bz <- sapply(PlaceType_Bz, function(x) {
      sample(D4cModels_ls$NormD4_PtQt[x,], 1)})
  D4c_Bz <- NormD4_Bz * AveD4c_Ma[L$Year$Bzone$Marea]

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(TranRevMiPC = TranRevMiPC_Ma,
         VanDvmt = VehMi_df$Van,
         BusDvmt = VehMi_df$Bus,
         RailDvmt = VehMi_df$Rail)
  Out_ls$Year$Bzone$D4c <- D4c_Bz
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("SimulateTransitService")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# library(filesstrings)
# library(visioneval)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "SimulateTransitService",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- SimulateTransitService(L)
#
# TestDat_ <- testModule(
#   ModuleName = "SimulateTransitService",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

