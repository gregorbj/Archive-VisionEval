#=================
#CalculateCongestionBase.R
#=================
# This module calculates the amount of congestion - automobile,
# light truck, truck, and bus vmt are allocated to freeways, arterials,
# and other roadways.

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
#Load the alternative mode trip models from GreenSTEP
load("inst/extdata/CongModel_ls.RData")
#Save the model
#' Congestion models and required parameters.
#'
#' A list of components describing congestion models and various parameters
#' required by those models.
#'
#' @format A list having 'Fwy' and 'Art' components. Each component has a
#' logistic model to indicate the level of congestion which are categorized
#' as NonePct, HvyPct, SevPct, and NonePct. This list also contains other
#' parameters that are used in the evaluation of aforementioned models.
#' @source GreenSTEP version ?.? model.
"CongModel_ls"
devtools::use_data(CongModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateCongestionBaseSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "ITS",
      FILE = "azone_its_prop.csv",
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
      DESCRIPTION = "Proportion of the freeway and arterial networks with ITS for
      incident reduction"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "ITS",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Type",
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("BusVmt","TruckVmt"),
      SIZE = 8
    ),
    item(
      NAME = "PropVmt",
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "Fwy",
        "Art",
        "Other"
      ),
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseLtVehDvmt",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseFwyArtProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c('NA', '< 0', '> 1'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 9,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TruckDvmt",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyLaneMiPC",
        "ArtLaneMiPC",
        "TranRevMiPC"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "BusRevMi",
        "RailRevMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TranRevMiAdjFactor",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = items(
        "MpgAdjLtVeh",
        "MpgAdjBus",
        "MpgAdjTruck"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Fuel efficiency adjustment for light vehicles",
        "Fuel efficiency adjustment for buses",
        "Fuel efficiency adjustment for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "VehHrLtVeh",
        "VehHrBus",
        "VehHrTruck"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Total vehicle travel time for light vehicles",
        "Total vehicle travel time for buses",
        "Total vehicle travel time for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "AveSpeedLtVeh",
        "AveSpeedBus",
        "AveSpeedTruck"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Average speed for light vehicles",
        "Average speed for buses",
        "Average speed for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "FfVehHrLtVeh",
        "FfVehHrBus",
        "FfVehHrTruck"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Freeflow travel time for light vehicles",
        "Freeflow travel time for buses",
        "Freeflow travel time for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "DelayVehHrLtVeh",
        "DelayVehHrBus",
        "DelayVehHrTruck"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Total vehicle delay time for light vehicles",
        "Total vehicle delay time for buses",
        "Total vehicle delay time for heavy trucks"
      )
    ),
    item(
      NAME = "MpgAdjHh",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Fuel efficiency adjustment for households"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateCongestionBase module
#'
#' A list containing specifications for the CalculateCongestionBase module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateCongestionBase.R script.
"CalculateCongestionBaseSpecifications"
devtools::use_data(CalculateCongestionBaseSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Define a function that calculates the MPG adjustment, travel time and travel delay
#---------------------------------------------------------------------------
#' Function that calculates the MPG adjustment, travel time and travel delay
#'
#' \code{calcCongestion} calculates the MPG adjustment, travel time and travel delay
#' due to congestion.
#'
#' This function takes a list of congestion models, dvmt by vehicle types, freeway
#' and arterial lane miles, population, and other information to calculate
#' adjustments to fuel efficiency, travel time, and travel delay.
#' @param Model_ls A list of congestion models
#' @param DvmtByVehType A data.frame of dvmt by vehicle types
#' @param PerCapFwyLnMi A named numeric vector of free way lane miles
#' @param PerCapArtLnMi A named numeric vector of arterial lane miles
#' @param Population A numeric indicating the population
#' @param IncdReduc A numeric indicating proportion of incidence reduced by ITS
#' @param FwyArtProp A numeric indicating the proportions of daily VMT for light
#' vehicles that takes place on freeways and arterials
#' @param BusVmtSplit_Fc A data.frame indicating the bus vmt split by freeways, arterials
#' and others
#' @param TruckVmtSplit_Fc A data.frame indicating the truck vmt split by freeways, arterials
#' and others
#' @param UsePce A logical suggesting whether to convert heavy truck and bus dvmt to
#' passenger car equivalents for congestion calculation. (Default: FALSE)
#' @return A list containing mpg adjustments, travel time, and travel delay hours
#' by vehicle types.
#' @export
calcCongestion <- function( Model_ls, DvmtByVehType, PerCapFwyLnMi, PerCapArtLnMi, Population, IncdReduc=0, FwyArtProp, BusVmtSplit_Fc, TruckVmtSplit_Fc, UsePce=FALSE ) {

  VehType <- c("LtVeh","Truck","Bus")
  Fc <- c("Fwy","Art","Other")
  Cl <- c( "None", "Mod", "Hvy", "Sev", "Ext" )

  # Split DVMT between freeways, arterials and other roads
  #-------------------------------------------------------
  DvmtByFcType <- array( 0, dim=c(3,3),
                      dimnames=list( VehType, Fc ) )
  # Split Light vehicle DVMT
  LtVehFwyArtDvmt <- DvmtByVehType[ "LtVeh" ] * FwyArtProp
  LnMiRatio <- PerCapFwyLnMi / PerCapArtLnMi
  Intercept <- 1
  FwyArtDvmtRatio <- eval( parse( text=Model_ls$DvmtRatio ) )
  FwyDvmt <- LtVehFwyArtDvmt * FwyArtDvmtRatio / ( 1 + FwyArtDvmtRatio )
  ArtDvmt <- LtVehFwyArtDvmt - FwyDvmt
  DvmtByFcType[ "LtVeh", "Fwy" ] <- FwyDvmt
  DvmtByFcType[ "LtVeh", "Art" ] <- ArtDvmt
  DvmtByFcType["LtVeh", "Other"] <- DvmtByVehType[ "LtVeh" ] - LtVehFwyArtDvmt
  rm( LtVehFwyArtDvmt, LnMiRatio, Intercept, FwyArtDvmtRatio, FwyDvmt, ArtDvmt )
  # Split Truck Dvmt
  DvmtByFcType[ "Truck", ] <- unlist( DvmtByVehType[ "Truck" ] * TruckVmtSplit_Fc )
  # Split Bus Dvmt
  DvmtByFcType[ "Bus", ] <- unlist( DvmtByVehType[ "Bus" ] * BusVmtSplit_Fc )

  # Calculate volumes by functional class in passenger car equivalents
  #-------------------------------------------------------------------
  if( UsePce ) {
    PceDevmtByFc <- colSums( sweep( DvmtByFcType, 1, Model_ls$Pce.Ty, "*" ) )
  } else {
    PceDevmtByFc <- colSums( DvmtByFcType )
  }

  # Calculate freeway DVMT proportions by congestion level
  #-------------------------------------------------------
  FwyDvmtPctByCl <- numeric( length(Cl) )
  names( FwyDvmtPctByCl ) <- Cl
  Intercept <- 1
  FwyDemandLvl <- PceDevmtByFc[ "Fwy" ] / ( PerCapFwyLnMi * Population / 1000 )
  FwyDvmtPctByCl[ "None" ] <- eval( parse( text=Model_ls$Fwy$NonePct ) )
  if( FwyDvmtPctByCl[ "None" ] < 0 ) FwyDvmtPctByCl[ "None" ] <- 0
  FwyDvmtPctByCl[ "Hvy" ] <- eval( parse( text=Model_ls$Fwy$HvyPct ) )
  FwyDvmtPctByCl[ "Sev" ] <- eval( parse( text=Model_ls$Fwy$SevPct ) )
  FwyDvmtPctByCl[ "Ext" ] <- eval( parse( text=Model_ls$Fwy$ExtPct ) )
  FwyDvmtPctByCl[ "Mod" ] <- 100 - sum( FwyDvmtPctByCl )
  if( FwyDvmtPctByCl[ "Mod" ] < 0 ) FwyDvmtPctByCl[ "Mod" ] <- 0
  if( sum( FwyDvmtPctByCl ) > 100 ) FwyDvmtPctByCl <- 100 * FwyDvmtPctByCl / sum( FwyDvmtPctByCl )

  # Calculate arterial DVMT proportions by congestion level
  #-------------------------------------------------------
  ArtDvmtPctByCl <- numeric( length(Cl) )
  names( ArtDvmtPctByCl ) <- Cl
  ArtDemandLvl <- PceDevmtByFc[ "Art" ] / ( PerCapArtLnMi * Population / 1000 )
  Intercept <- 1
  ArtDvmtPctByCl[ "None" ] <- eval( parse( text=Model_ls$Art$NonePct ) )
  if( ArtDvmtPctByCl[ "None" ] < 0 ) ArtDvmtPctByCl[ "None" ] <- 0
  ArtDvmtPctByCl[ "Hvy" ] <- eval( parse( text=Model_ls$Art$HvyPct ) )
  ArtDvmtPctByCl[ "Sev" ] <- eval( parse( text=Model_ls$Art$SevPct ) )
  ArtDvmtPctByCl[ "Ext" ] <- eval( parse( text=Model_ls$Art$ExtPct ) )
  ArtDvmtPctByCl[ "Mod" ] <- 100 - sum( ArtDvmtPctByCl )
  if( ArtDvmtPctByCl[ "Mod" ] < 0 ) ArtDvmtPctByCl[ "Mod" ] <- 0
  if( sum( ArtDvmtPctByCl ) > 100 ) ArtDvmtPctByCl <- 100 * ArtDvmtPctByCl / sum( ArtDvmtPctByCl )

  # Calculate DVMT by vehicle type, functional class and congestion level
  #----------------------------------------------------------------------
  # Calculate light vehicle DVMT
  LtVehDvmtByClFc <- array( 0, dim=c(length(Cl),length(Fc)), dimnames=list(Cl,Fc) )
  LtVehDvmtByClFc[ ,"Fwy"] <- DvmtByFcType["LtVeh","Fwy"] * FwyDvmtPctByCl / 100
  LtVehDvmtByClFc[ ,"Art"] <- DvmtByFcType["LtVeh","Art"] * ArtDvmtPctByCl / 100
  LtVehDvmtByClFc["None","Other"] <- DvmtByFcType["LtVeh","Other"]
  # Calculate truck DVMT
  TruckDvmtByClFc <- array( 0, dim=c(length(Cl),length(Fc)), dimnames=list(Cl,Fc) )
  TruckDvmtByClFc[ ,"Fwy"] <- DvmtByFcType["Truck","Fwy"] * FwyDvmtPctByCl / 100
  TruckDvmtByClFc[ ,"Art"] <- DvmtByFcType["Truck","Art"] * ArtDvmtPctByCl / 100
  TruckDvmtByClFc["None","Other"] <- DvmtByFcType["Truck","Other"]
  # Calculate bus DVMT
  BusDvmtByClFc <- array( 0, dim=c(length(Cl),length(Fc)), dimnames=list(Cl,Fc) )
  BusDvmtByClFc[ ,"Fwy"] <- DvmtByFcType["Bus","Fwy"] * FwyDvmtPctByCl / 100
  BusDvmtByClFc[ ,"Art"] <- DvmtByFcType["Bus","Art"] * ArtDvmtPctByCl / 100
  BusDvmtByClFc["None","Other"] <- DvmtByFcType["Bus","Other"]

  # Calculate congested speeds by congestion level and roadway type
  #----------------------------------------------------------------
  # Calculate incident reduction factors
  IncdFactors_ <- c( IncdReduc, 1 - IncdReduc )
  # Calculate average freeway speeds by congestion level
  FwySpeedByClCc <- cbind( Model_ls$Speeds$FwyRcr, Model_ls$Speeds$FwyNonRcr )
  FwySpeedByCl <- rowSums( sweep( FwySpeedByClCc, 2, IncdFactors_, "*" ) )
  # Calculate average arterial speeds by congestion level
  ArtSpeedByClCc <- cbind( Model_ls$Speeds$ArtRcr, Model_ls$Speeds$ArtNonRcr )
  ArtSpeedByCl <- rowSums( sweep( ArtSpeedByClCc, 2, IncdFactors_, "*" ) )
  # Make an array of congested speeds by congestion level and functional class
  CongSpeedByClFc <- cbind( FwySpeedByCl, ArtSpeedByCl, Model_ls$FreeFlowSpeed.Fc["Other"] )
  colnames( CongSpeedByClFc ) <- Fc
  # Make separate array of bus congested speeds
  # Since normal bus operating speeds on arterials and other are lower than freeflow speed
  BusCongSpeedByClFc <- CongSpeedByClFc
  BusCongSpeedByClFc[ , "Art" ] <- pmin( CongSpeedByClFc[ , "Art" ], Model_ls$BusSpeeds.Fc[ "Art" ] )
  BusCongSpeedByClFc[ , "Other" ] <- pmin( CongSpeedByClFc[ , "Other" ], Model_ls$BusSpeeds.Fc[ "Other" ] )

  # Set up for calculating MPG adjustment values
  #---------------------------------------------
  # Define a function to interpolate adjustment values from table
  interpolate <- function( Spd, Spds_, Vals_ ) {
    SpdDiff_ <- 1 - Spd / Spds_
    Idx_ <- which( rank( abs( SpdDiff_ ) ) <= 2 )
    Vals_ <- Vals_[ Idx_ ]
    Spds_ <- Spds_[ Idx_ ]
    sum( Vals_ * rev( abs( Spds_ - Spd ) / 5 ) )
  }
  # Initialize a vector to store adjustments
  MpgAdjByVehType <- numeric( length( VehType ) )
  names( MpgAdjByVehType ) <- VehType

  # Calculate light vehicle MPG adjustments
  #----------------------------------------
  # Initialize adjustment array
  LtVehMpgAdjByClFc <- CongSpeedByClFc * 0
  # Calculate freeway adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$FwySpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$FwySpdMpgAdj..[,"LtVeh"]
  Speeds_ <- round( CongSpeedByClFc[,"Fwy"] )
  LtVehMpgAdjByClFc[,"Fwy"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate arterial adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$ArtSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$ArtSpdMpgAdj..[,"LtVeh"]
  Speeds_ <- round( CongSpeedByClFc[,"Art"] )
  LtVehMpgAdjByClFc[,"Art"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate other road adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$OtherSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$OtherSpdMpgAdj..[,"LtVeh"]
  Speeds_ <- round( CongSpeedByClFc[,"Other"] )
  LtVehMpgAdjByClFc[,"Other"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate overall average adjustment
  MpgAdjByVehType[ "LtVeh" ] <- sum( LtVehMpgAdjByClFc * LtVehDvmtByClFc ) / sum( LtVehDvmtByClFc )

  # Calculate truck MPG adjustments
  #--------------------------------
  # Initialize adjustment array
  TruckMpgAdjByClFc <- CongSpeedByClFc * 0
  # Calculate freeway adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$FwySpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$FwySpdMpgAdj..[,"Truck"]
  Speeds_ <- round( CongSpeedByClFc[,"Fwy"] )
  TruckMpgAdjByClFc[,"Fwy"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate arterial adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$ArtSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$ArtSpdMpgAdj..[,"Truck"]
  Speeds_ <- round( CongSpeedByClFc[,"Art"] )
  TruckMpgAdjByClFc[,"Art"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate other road adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$OtherSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$OtherSpdMpgAdj..[,"Truck"]
  Speeds_ <- round( CongSpeedByClFc[,"Other"] )
  TruckMpgAdjByClFc[,"Other"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate overall average adjustment
  MpgAdjByVehType[ "Truck" ] <- sum( TruckMpgAdjByClFc * TruckDvmtByClFc ) / sum( TruckDvmtByClFc )

  # Calculate bus MPG adjustments
  #------------------------------
  # Initialize adjustment array
  BusMpgAdjByClFc <- BusCongSpeedByClFc * 0
  # Calculate freeway adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$FwySpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$FwySpdMpgAdj..[,"Bus"]
  Speeds_ <- round( BusCongSpeedByClFc[,"Fwy"] )
  BusMpgAdjByClFc[,"Fwy"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate arterial adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$ArtSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$ArtSpdMpgAdj..[,"Bus"]
  Speeds_ <- round( BusCongSpeedByClFc[,"Art"] )
  BusMpgAdjByClFc[,"Art"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate other road adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$OtherSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$OtherSpdMpgAdj..[,"Bus"]
  Speeds_ <- round( BusCongSpeedByClFc[,"Other"] )
  BusMpgAdjByClFc[,"Other"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate overall average adjustment
  MpgAdjByVehType[ "Bus" ] <- sum( BusMpgAdjByClFc * BusDvmtByClFc ) / sum( BusDvmtByClFc )

  # Calculate total vehicle travel time by vehicle type
  #----------------------------------------------------
  VehHrByVehType <- numeric( length( VehType ) )
  names( VehHrByVehType ) <- VehType
  VehHrByVehType[ "LtVeh" ] <- sum( LtVehDvmtByClFc / CongSpeedByClFc )
  VehHrByVehType[ "Truck" ] <- sum( TruckDvmtByClFc / CongSpeedByClFc )
  VehHrByVehType[ "Bus" ] <- sum( BusDvmtByClFc / BusCongSpeedByClFc )

  # Calculate average speed
  #------------------------
  AveSpeedByVehType <- DvmtByVehType / VehHrByVehType

  # Calculate vehicle delay by vehicle type
  #----------------------------------------
  # Calculate light vehicle freeflow travel time
  FfVehHrByVehType <- VehHrByVehType * 0
  FfVehHrByVehType[ "LtVeh" ] <- sum( colSums( LtVehDvmtByClFc ) / Model_ls$FreeFlowSpeed.Fc )
  FfVehHrByVehType[ "Truck" ] <- sum( colSums( TruckDvmtByClFc ) / Model_ls$FreeFlowSpeed.Fc )
  FfVehHrByVehType[ "Bus" ] <- sum( colSums( BusDvmtByClFc ) / Model_ls$BusSpeeds.Fc )
  # Calculate vehicle hours of delay
  DelayVehHrByVehType <- VehHrByVehType - FfVehHrByVehType

  # Return the result
  list( MpgAdjByVehType=MpgAdjByVehType, VehHrByVehType=VehHrByVehType, AveSpeedByVehType=AveSpeedByVehType,
        FfVehHrByVehType=FfVehHrByVehType, DelayVehHrByVehType=DelayVehHrByVehType )

}


#Main module function that calculates the amount of congestion
#------------------------------------------------------------------
#' Function to calculate the amount of congestion.
#'
#' \code{CalculateCongestionBase} calculates the amount of congestion.
#'
#' Auto, and light truck vmt, truck vmt, and bus vmt are allocated to freeways, arterials,
#' and other roadways. Truck and bus vmt are allocated based on mode-specific data,
#' and auto and light truck vmt are allocated based on a combination of factors
#' and a model that is sensitive to the relative supplies of freeway and arterial
#' lane miles.
#'
#' System-wide ratios of vmt to lane miles for freeways and arterials
#' are used to allocate vmt to congestion levels using congestion levels defined by
#' the Texas Transportation Institute for the Urban Mobility Report. Each freeway and
#' arterial congestion level is associated with an average trip speed for conditions that
#' do and do not include ITS treatment for incident management on the roadway. Overall average
#' speeds by congestion level are calculated based on input assumptions about the degree of
#' incident management. Speed vs. fuel efficiency relationships for light vehicles, trucks,
#' and buses are used to adjust the fleet fuel efficiency averages computed for the region.

#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateCongestionBase <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  #Get the inputs

  #Get the bus and truck vmt proportions and functional class splits
  TruckBusDvmtParm_df <- data.frame(L$Global$Vmt)
  BusVmt_Fc_df <- TruckBusDvmtParm_df[ TruckBusDvmtParm_df$Type == "BusVmt",c("Fwy","Art","Other") ]
  TruckVmt_Fc_df <- TruckBusDvmtParm_df[ TruckBusDvmtParm_df$Type == "TruckVmt",c("Fwy","Art","Other") ]

  # Calculating the effects of congestion
  # Load data summaries
  #--------------------

  # Load population
  PopByPlaceType_vc <- BasePopByPlaceType_vc <- as.numeric(L$Year$Bzone$UrbanPop)
  names(PopByPlaceType_vc) <- names(BasePopByPlaceType_vc) <- L$Year$Bzone$Bzone

  # Variable to check year run
  isBaseYear <- L$G$Year == L$G$BaseYear
  if(!isBaseYear){
    BasePopByPlaceType_vc <- as.numeric(L$BaseYear$Bzone$UrbanPop)
    names(BasePopByPlaceType_vc) <- L$BaseYear$Bzone$Bzone
  }
  PopChangeRatioByPt_vc <- PopByPlaceType_vc / BasePopByPlaceType_vc
  PopChangeRatioByPt_vc[ is.na( PopChangeRatioByPt_vc ) ] <- 0

  # Calculate bus DVMT by metropolitan area
  #----------------------------------------
  # Calculate bus DVMT
  BusDvmt_Ma <- L$Year$Marea$BusRevMi * L$Global$Model$TranRevMiAdjFactor / 365

  # Calculate light vehicle DVMT for the metropolitan area
  #-------------------------------------------------------
  # Sum light vehicle DVMT
  HhDvmt <- sum(L$Year$Bzone$Dvmt)

  # Need to do something here to handle different run types
  # If this is an ELESNP run, calculate factor to convert HhDvmt to metropolitan road light vehicle DVMT
  BaseLtVehDvmt_Ma <- L$Global$Model$BaseLtVehDvmt
  LtVehDvmtFactor_Ma <- BaseLtVehDvmt_Ma * 1000 / HhDvmt

  # If other runtype then we have to find a way to load LtVehDvmtFactor_Ma
  # instead of calculating

  # Factor household light vehicle DVMT to produce metropolitan road light vehicle DVMT
  LtVehDvmt_Ma <- HhDvmt * LtVehDvmtFactor_Ma
  # Clean up
  rm(HhDvmt)

  # Calculate total DVMT by metropolitan area
  #------------------------------------------
  DvmtType_Ma <- cbind( LtVeh=LtVehDvmt_Ma, Truck=L$Year$Marea$TruckDvmt, Bus=BusDvmt_Ma )
  rownames(DvmtType_Ma) <- L$Year$Marea$Marea
  rm(LtVehDvmt_Ma, BusDvmt_Ma )

  # Sum population by metropolitan area
  #------------------------------------
  Pop_Ma <- sum(PopByPlaceType_vc)
  rm(PopByPlaceType_vc, BasePopByPlaceType_vc)

  # Calculate congestion effects
  #=============================

  # Initialize arrays to store results
  VehicleType_vc <- c( "LtVeh", "Truck", "Bus" )
  Marea_vc <- L$Year$Marea$Marea
  MpgAdjByMaVehType_vc <- array( 0, dim=c(length(Marea_vc),length(VehicleType_vc)), dimnames=list(Marea_vc,VehicleType_vc) )
  DelayVehHrByMaVehType_vc <- FfVehHrByMaVehType_vc <- AveSpeedByMaVehType_vc <- VehHrByMaVehType_vc <- MpgAdjByMaVehType_vc

  # Get the DVMT by vehicle type
  DvmtByVehType_vc <- DvmtType_Ma[Marea_vc,]

  # Extract freeway and arterial supply for the metropolitan area
  PerCapFwyLnMi_vc <- L$Year$Marea$FwyLaneMiPC
  PerCapArtLnMi_vc <- L$Year$Marea$ArtLaneMiPC



  # Extract population and ITS factor for the metropolitan area
  Population_vc <- Pop_Ma #just a single value
  Its_Yr <- L$Year$Azone$ITS

  # Calculate the MPG adjustment, travel time and travel delay
  CongResults_ls <- calcCongestion( Model_ls=CongModel_ls, DvmtByVehType=DvmtByVehType_vc,
                                  PerCapFwyLnMi=PerCapFwyLnMi_vc, PerCapArtLnMi=PerCapArtLnMi_vc,
                                  Population=Population_vc, IncdReduc=Its_Yr,
                                  FwyArtProp=L$Global$Model$BaseFwyArtProp,
                                  BusVmtSplit_Fc=BusVmt_Fc_df, TruckVmtSplit_Fc=TruckVmt_Fc_df,
                                  UsePce=FALSE)

  # Insert results in array
  MpgAdjByMaVehType_vc[Marea_vc, ] <- CongResults_ls$MpgAdjByVehType
  VehHrByMaVehType_vc[Marea_vc, ] <- CongResults_ls$VehHrByVehType
  AveSpeedByMaVehType_vc[Marea_vc, ] <- CongResults_ls$AveSpeedByVehType
  FfVehHrByMaVehType_vc[Marea_vc, ] <- CongResults_ls$FfVehHrByVehType
  DelayVehHrByMaVehType_vc[Marea_vc, ] <- CongResults_ls$DelayVehHrByVehType

  # Clean up
  rm( DvmtByVehType_vc, PerCapFwyLnMi_vc, PerCapArtLnMi_vc, Population_vc, Its_Yr, CongResults_ls )

  # Calculate MPG adjustment on a household basis
  # Assuming the household VMT outside of metropolitan area is uncongested
  HhMpgAdj_Ma <- ( MpgAdjByMaVehType_vc[,"LtVeh"] * LtVehDvmtFactor_Ma ) + ( 1 - LtVehDvmtFactor_Ma )

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()

  #Return the outputs list
  Out_ls$Year <- list(
    Marea = list(
      MpgAdjLtVeh = MpgAdjByMaVehType_vc[Marea_vc, "LtVeh"],
      MpgAdjBus = MpgAdjByMaVehType_vc[Marea_vc, "Bus"],
      MpgAdjTruck = MpgAdjByMaVehType_vc[Marea_vc, "Truck"],
      VehHrLtVeh = VehHrByMaVehType_vc[Marea_vc, "LtVeh"],
      VehHrBus = VehHrByMaVehType_vc[Marea_vc, "Bus"],
      VehHrTruck = VehHrByMaVehType_vc[Marea_vc, "Truck"],
      AveSpeedLtVeh = AveSpeedByMaVehType_vc[Marea_vc, "LtVeh"],
      AveSpeedBus = AveSpeedByMaVehType_vc[Marea_vc, "Bus"],
      AveSpeedTruck = AveSpeedByMaVehType_vc[Marea_vc, "Truck"],
      FfVehHrLtVeh = AveSpeedByMaVehType_vc[Marea_vc, "LtVeh"],
      FfVehHrBus = AveSpeedByMaVehType_vc[Marea_vc, "Bus"],
      FfVehHrTruck = AveSpeedByMaVehType_vc[Marea_vc, "Truck"],
      DelayVehHrLtVeh = DelayVehHrByMaVehType_vc[Marea_vc, "LtVeh"],
      DelayVehHrBus = DelayVehHrByMaVehType_vc[Marea_vc, "Bus"],
      DelayVehHrTruck = DelayVehHrByMaVehType_vc[Marea_vc, "Truck"],
      MpgAdjHh = as.numeric(HhMpgAdj_Ma)
    )
  )
  return(Out_ls)
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateCongestionBase",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateCongestionBase",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
