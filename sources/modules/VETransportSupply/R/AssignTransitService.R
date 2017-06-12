#======================
#AssignTransitService.R
#======================
#This module assigns transit service level to the metropolitan area (Marea) and
#neighborhoods (Bzone). Annual revenue-miles (i.e. transit miles in revenue
#service) by transit mode type are read from input file and then converted to
#bus equivalents using factors derived from urbanized are data from the National
#Transit Database (NTD). This script reads in data taken from the 2015 NTD and
#calculates the conversion factors which are the only model parameters at this
#time. The AssignTransitService function calculates the bus equivalent revenue
#miles for the metropolitan area from inputs for revenue miles by mode type. The
#module also reads in an input file of neighborhood transit service level and
#assigns to Bzones.

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
    UZABusEqRevMile_df = UZABusEqRevMile_df
  )
}

#Estimate public transit model parameters
#----------------------------------------
TransitParam_ls <- estimateTransitModel()
BusEquivalents_df <- TransitParam_ls$BusEquivalents_df
UZABusEqRevMile_df <- TransitParam_ls$UZABusEqRevMile_df
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
devtools::use_data(BusEquivalents_df, overwrite = TRUE)

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
devtools::use_data(UZABusEqRevMile_df, overwrite = TRUE)

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
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
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
      TOTAL = ""
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
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
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
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
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
devtools::use_data(AssignTransitServiceSpecifications, overwrite = TRUE)


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

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(TranRevMiPC = TranRevMiPC_Ma)
  #Return the outputs list
  Out_ls
}


#====================
#SECTION 4: TEST CODE
#====================
#The following code is useful for testing and module function development. The
#first part initializes a datastore, loads inputs, and checks that the datastore
#contains the data needed to run the module. The second part produces a list of
#the data the module function will be provided by the framework when it is run.
#This is useful to have when developing the module function. The third part
#runs the whole module to check that everything runs correctly and that the
#module outputs are consistent with specifications. Note that if a module
#requires data produced by another module, the test code for the other module
#must be run first so that the datastore contains the requisite data. Also note
#that it is important that all of the test code is commented out when the
#the package is built.

#1) Test code to set up datastore and return module specifications
#-----------------------------------------------------------------
#The following commented-out code can be run to initialize a datastore, load
#inputs, and check that the datastore contains the data needed to run the
#module. It return the processed module specifications which can be used in
#conjunction with the getFromDatastore function to fetch the list of data needed
#by the module. Note that the following code assumes that all the data required
#to set up a datastore are in the defs and inputs directories in the tests
#directory. All files in the defs directory must have the default names.
#
# Specs_ls <- testModule(
#   ModuleName = "AssignTransitService",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
#
#2) Test code to create a list of module inputs to use in module function
#------------------------------------------------------------------------
#The following commented-out code can be run to create a list of module inputs
#that may be used in the development of module functions. Note that the data
#will be returned for the first year in the run years specified in the
#run_parameters.json file. Also note that if the RunBy specification is not
#Region, the code will by default return the data for the first geographic area
#in the datastore.
#
# setwd("tests")
# Year <- getYears()[1]
# if (Specs_ls$RunBy == "Region") {
#   L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = NULL)
# } else {
#   GeoCategory <- Specs_ls$RunBy
#   Geo_ <- readFromTable(GeoCategory, GeoCategory, Year)
#   L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = Geo_[1])
#   rm(GeoCategory, Geo_)
# }
# rm(Year)
# setwd("..")
#
#3) Test code to run full module tests
#-------------------------------------
#Run the following commented-out code after the module functions have been
#written to test all aspects of the module including whether the module can be
#run and whether the module will produce results that are consistent with the
#module's Set specifications. It is also important to run this code if one or
#more other modules in the package need the dataset(s) produced by this module.
#
# testModule(
#   ModuleName = "AssignTransitService",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
