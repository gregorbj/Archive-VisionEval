#======================
#AssignTransitService.R
#======================

#<doc>
#
## AssignTransitService Module
#### November 5, 2018
#
#This module assigns transit service level to the metropolitan area (Marea) and neighborhoods (Bzones). Annual revenue-miles (i.e. transit miles in revenue service) by transit mode type are read from an input file. The following 8 modes are recognized:
#* DR = Demand-responsive
#* VP = Vanpool and similar
#* MB = Standard motor bus
#* RB = Bus rapid transit and commuter bus
#* MG = Monorail/automated guideway
#* SR = Streetcar/trolley bus/inclined plain
#* HR = Heavy Rail/Light Rail
#* CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#
#Revenue miles are converted to bus (i.e. MB) equivalents using factors derived from urbanized are data from the National Transit Database (NTD). Bus-equivalent revenue miles are used in models which predict vehicle ownership and household DVMT.
#
#Revenue miles by mode type are also translated (using NTD data) into vehicle miles by 3 vehicle types: van, bus, and rail. Miles by vehicle type are used to calculate public transit energy consumption and emissions.
#
#The module also reads in user supplied data on relative public transit accessibility by Bzone as explained below.
#
### Model Parameter Estimation
#
#Parameters are calculated to convert the revenue miles for each of the 8 recognized public transit modes into bus equivalents, and to convert revenue miles into vehicle miles. Data extracted from the 2015 National Transit Database (NTD) are used to calculate these parameters. The extracted datasets are in the *2015_Service.csv* and *2015_Agency_information.csv* files in the *inst/extdata* directory of this package. These files contain information about transit service and transit service providers located within urbanized areas. Documentation of the data are contained in the accompanying *2015_Service.txt* and *2015_Agency_information.txt* files.
#
#Bus equivalent factors for each of the 8 modes is calculated on the basis of the average productivity of each mode as measured by the ratio of passenger miles to revenue miles. The bus-equivalency factor of each mode is the ratio of the average productivity of the mode to the average productivity of the bus (MB) mode.
#
#Factors to compute vehicle miles by mode from revenue miles by mode are calculated from the NTD data on revenue miles and deadhead (i.e. out of service) miles. The vehicle mile factor is the sum of revenue and deadhead miles divided by the revenue miles. These factors vary by mode.
#
### How the Module Work
#
#The user supplies data on the annual revenue miles of service by each of the 8 transit modes for the Marea. These revenue miles are converted to bus equivalents using the estimated bus-equivalency factors and summed to calculate total bus-equivalent revenue miles. This value is divided by the urbanized area population of the Marea to compute bus-equivalent revenue miles per capita. This public transit service measure is used in models of household vehicle ownership and household vehicle travel.
#
#The user supplied revenue miles by mode are translated into vehicle miles by mode using the estimated conversion factors. The results are then simplified into 3 vehicle types (Van, Bus, Rail) where the DR and VP modes are assumed to be served by vans, the MB and RB modes are assumed to be served by buses, and the MG, SR, HR, and CR modes are assumed to be served by rail.
#
#The user also supplies information on the aggregate frequency of peak period transit service within 0.25 miles of the Bzone boundary per hour during evening peak period. This is the *D4c* measure included in the Environmental Protection Agency's (EPA) [Smart Location Database] (https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide). Following is the description of the measure from the user guide:
#>EPA analyzed GTFS data to calculate the frequency of service for each transit route between 4:00 and 7:00 PM on a weekday. Then, for each block group, EPA identified transit routes with service that stops within 0.4 km (0.25 miles). Finally EPA summed total aggregate service frequency by block group. Values for this metric are expressed as service frequency per hour of service.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#Describe specifications for transit data files
#----------------------------------------------
#Transit agency data
AgencyInp_ls <- items(
  item(
    NAME =
      items("AgencyID",
            "PrimaryUZA",
            "Population"),
    TYPE = "integer",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "UZAName",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Transit service data
ServiceInp_ls <- items(
  item(
    NAME =
      items("RevenueMiles",
            "DeadheadMiles",
            "PassengerMiles"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AgencyID",
            "AgencyName",
            "Mode",
            "TimePeriod"),
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Define function to estimate public transit model parameters
#-----------------------------------------------------------
#' Estimate public transit model parameters.
#'
#' \code{estimateTransitModel} estimates transit model parameters.
#'
#' This function estimates transit model parameters from 2015 National Transit
#' Database information on transit agencies and service levels. The function
#' calculates factors for converting annual revenue miles by transit mode to
#' total bus-equivalent revenue miles. It also calculates factors to convert
#' revenue miles by mode into vehicle miles by mode.
#'
#' @return A list containing the following elements:
#' BusEquivalents_df: factors to convert revenue miles by mode into bus
#' equivalents,
#' UZABusEqRevMile_df: data on bus equivalent revenue miles by urbanized area,
#' VehMiFactors_df: factors to convert revenue miles by mode into vehicle miles
#' by mode.
#' @name estimateTransitModel
#' @import stats
#' @export
estimateTransitModel <- function() {
  #Read in and process transit datasets
  #------------------------------------
  #Read in transit agency datasets
  Agency_df <-
    processEstimationInputs(
      AgencyInp_ls,
      "2015_Agency_information.csv",
      "AssignTransitService.R")
  #Read in transit service datasets
  Service_df <-
    processEstimationInputs(
      ServiceInp_ls,
      "2015_Service.csv",
      "AssignTransitService.R")
  #Select only rows with annual totals
  Service_df <- Service_df[Service_df$TimePeriod == "Annual Total",]
  #Select only rows for service in urbanized areas
  Service_df <- Service_df[Service_df$AgencyID %in% Agency_df$AgencyID,]

  #Define combined modes and create index datasets
  #-----------------------------------------------
  CombinedCode_ls <-
    list(
      DR = c("DR", "DT"),
      VP = c("VP", "PB"),
      MB = c("MB"),
      RB = c("RB", "CB"),
      MG = c("MG"),
      SR = c("SR", "TB", "IP"),
      HR = c("LR", "HR", "AR"),
      CR = c("CR", "YR", "CC", "TR")
    )
  CombinedCode_ <-
    c(DR = "DR", DT = "DR", VP = "VP", PB = "VP", MB = "MB", RB = "RB", CB = "RB",
      MG = "MG", SR = "SR", TB = "SR", IP = "SR", LR = "HR", HR = "HR", AR = "HR",
      CR = "CR", YR = "CR", CC = "CR", TR = "CR"
    )
  Cm <- c("DR", "VP", "MB", "RB", "MG", "SR", "HR", "CR")

  #Calculate bus equivalency factors
  #---------------------------------
  #Calculate productivity measure
  Service_df$Productivity <-
    Service_df$PassengerMiles / Service_df$RevenueMiles
  #Calculate the average productivity by mode
  AveProductivity_Md <-
    tapply(Service_df$Productivity, Service_df$Mode, mean, na.rm = TRUE)
  #Calculate bus equivalency of different modes
  BusEquiv_Md <- AveProductivity_Md / AveProductivity_Md["MB"]
  #Calculate average productivity by combined mode
  BusEquiv_Cm <- unlist(lapply(CombinedCode_ls, function(x) {
    mean(BusEquiv_Md[x])
  }))
  #Create data frame with mode names and equivalency factors
  BusEquiv_df <-
    data.frame(
      Mode = names(BusEquiv_Cm),
      BusEquivalents = unname(BusEquiv_Cm)
    )

  #Calculate revenue miles to total vehicle mile factors by mode
  #-------------------------------------------------------------
  #Convert DeadheadMiles for mode DT from NA to 0
  Service_df$DeadheadMiles[Service_df$Mode == "DT"] <- 0
  #Create data frame of complete cases of revenue miles and deadhead miles
  Veh_df <- Service_df[, c("Mode", "RevenueMiles", "DeadheadMiles")]
  Veh_df <- Veh_df[complete.cases(Veh_df),]
  #Calculate total revenue miles by combined mode
  RevMi_Md <- tapply(Veh_df$RevenueMiles, Veh_df$Mode, sum)
  RevMi_Cm <- unlist(lapply(CombinedCode_ls, function(x) {
    sum(RevMi_Md[x])
  }))
  #Calculate total deadhead miles by combined mode
  DeadMi_Md <- tapply(Veh_df$DeadheadMiles, Veh_df$Mode, sum)
  DeadMi_Cm <- unlist(lapply(CombinedCode_ls, function(x) {
    sum(DeadMi_Md[x])
  }))
  #Calculate vehicle mile factors by combined mode
  VehMiFactors_Cm <- (RevMi_Cm + DeadMi_Cm) / RevMi_Cm
  VehMiFactors_df <-
    data.frame(
      Mode = names(VehMiFactors_Cm),
      VehMiFactors = unname(VehMiFactors_Cm)
    )

  #Calculate bus equivalent transit service by urbanized area
  #----------------------------------------------------------
  #Attach urbanized area code to service data
  Service_df$UzaCode <- Agency_df$PrimaryUZA[match(Service_df$AgencyID, Agency_df$AgencyID)]
  Service_df$UzaName <- Agency_df$UZAName[match(Service_df$AgencyID, Agency_df$AgencyID)]
  #Tabulate vehicle revenue miles by urbanized area and mode
  RevMi_UnMd <-
    tapply(Service_df$RevenueMiles,
           list(Service_df$UzaName, Service_df$Mode),
           sum)
  RevMi_UnMd[is.na(RevMi_UnMd)] <- 0
  #Summarize by combined mode
  RevMi_UnCm <- t(apply(RevMi_UnMd, 1, function(x) {
    tapply(x, CombinedCode_[colnames(RevMi_UnMd)], sum, na.rm = TRUE)[Cm]
  }))
  #Sum up the bus-equivalent revenue miles by urbanized area
  BusEqRevMi_Un <-
    rowSums(sweep(RevMi_UnCm, 2, BusEquiv_Cm, "*"))
  #Tabulate population by urbanized area
  UzaPop_Un <- Agency_df$Population[!duplicated(Agency_df$PrimaryUZA)]
  names(UzaPop_Un) <- Agency_df$UZAName[!duplicated(Agency_df$PrimaryUZA)]
  UzaPop_Un <- UzaPop_Un[names(BusEqRevMi_Un)]
  UzaPop_Un <- UzaPop_Un[names(BusEqRevMi_Un)]
  #Calculate bus-equivalent revenue miles per capita
  BusEqRevMiPC_Un <- BusEqRevMi_Un / UzaPop_Un
  #Create data frame of urbanized area bus revenue mile equivalency
  UZABusEqRevMile_df <-
    Service_df[!duplicated(Service_df$UzaName), c("UzaCode", "UzaName")]
  rownames(UZABusEqRevMile_df) <- UZABusEqRevMile_df$UzaName
  UZABusEqRevMile_df <- UZABusEqRevMile_df[names(BusEqRevMi_Un),]
  UZABusEqRevMile_df$BusEqRevMi <- unname(BusEqRevMi_Un)
  UZABusEqRevMile_df$UzaPop <- unname(UzaPop_Un)
  UZABusEqRevMile_df$BusEqRevMiPC <- unname(BusEqRevMiPC_Un)
  rownames(UZABusEqRevMile_df) <- NULL

  #Return the results
  #------------------
  list(
    BusEquivalents_df = BusEquiv_df,
    UZABusEqRevMile_df = UZABusEqRevMile_df,
    VehMiFactors_df = VehMiFactors_df
  )
}

#Estimate public transit model parameters
#----------------------------------------
TransitParam_ls <- estimateTransitModel()
BusEquivalents_df <- TransitParam_ls$BusEquivalents_df
UZABusEqRevMile_df <- TransitParam_ls$UZABusEqRevMile_df
VehMiFactors_df <- TransitParam_ls$VehMiFactors_df
rm(AgencyInp_ls)
rm(ServiceInp_ls)

#Save the bus equivalency factors
#--------------------------------
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

#Save the vehicle mile factors
#-----------------------------
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

#Save the urbanized area bus equivalency data
#--------------------------------------------
#' Urbanized area bus equivalent revenue mile data for 2015
#'
#' Urbanized area data from the 2015 National Transit Database (NTD) related to
#' the calculation of bus equivalent revenue miles and per capita values.
#'
#' @format A data frame with 439 rows and 5 variables containing urbanized area
#' data on bus equivalent revenue miles
#'
#' \describe{
#'   \item{UzaCode}{integer code corresponding to 5-digit code used in the NTD}
#'   \item{UzaName}{urbanized area name}
#'   \item{BusEqRevMi}{annual bus equivalent revenue miles in the urbanized area}
#'   \item{UzaPop}{urbanized area population}
#'   \item{BusEqRevMiPC}{annual bus equivalent revenue miles per capita in the urbanized area}
#' }
#' @source AssignTransitService.R script.
"UZABusEqRevMile_df"
usethis::use_data(UZABusEqRevMile_df, overwrite = TRUE)

#Clean up
rm(TransitParam_ls)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignTransitServiceSpecifications <- list(
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
      PROHIBIT = c("NA", "< 0"),
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
    ),
    item(
      NAME = "D4c",
      FILE = "bzone_transit_service.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "aggregate peak period transit service",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period (Ref: EPA 2010 Smart Location Database)"
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
      PROHIBIT = c("NA", "< 0"),
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
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignTransitService module
#'
#' A list containing specifications for the AssignTransitService module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignTransitService.R script.
"AssignTransitServiceSpecifications"
usethis::use_data(AssignTransitServiceSpecifications, overwrite = TRUE)


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
#' \code{AssignTransitService} calculate bus equivalent revenue miles per capita.
#'
#' This function calculates bus equivalent revenue miles per capita for each
#' Marea.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignTransitService
#' @import visioneval
#' @export
AssignTransitService <- function(L) {
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

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(TranRevMiPC = TranRevMiPC_Ma,
         VanDvmt = VehMi_df$Van,
         BusDvmt = VehMi_df$Bus,
         RailDvmt = VehMi_df$Rail)
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignTransitService")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# library(filesstrings)
# library(visioneval)
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
#   ModuleName = "AssignTransitService",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignTransitService(L)
