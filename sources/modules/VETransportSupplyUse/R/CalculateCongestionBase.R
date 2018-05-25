#=================
#CalculateCongestionBase.R
#=================
# This module calculates the amount of congestion - automobile,
# light truck, truck, and bus vmt are allocated to freeways, arterials,
# and other roadways.



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
    # Azone variables
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
    # Global variables
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
      NAME = "TranRevMiAdjFactor",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    # Bzone variables
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
    # Marea variables
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    # Marea variables
    item(
      NAME = items(
        "LtVehDvmt",
        "BusDvmt"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Daily vehicle miles travelled by light vehicles",
        "Daily vehicle miles travelled by bus"
      )
    ),
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
        "Fuel efficiency adjustment for light vehicles with internal combustion engine",
        "Fuel efficiency adjustment for buses with internal combustion engine",
        "Fuel efficiency adjustment for heavy trucks with internal combustion engine"
      )
    ),
    item(
      NAME = items(
        "MpKwhAdjLtVehHev",
        "MpKwhAdjLtVehEv",
        "MpKwhAdjBus",
        "MpKwhAdjTruck"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Power efficiency adjustment for light plugin/hybrid electric vehicles",
        "Power efficiency adjustment for light electric vehicles",
        "Power efficiency adjustment for buses with electric power train",
        "Power efficiency adjustment for heavy trucks with electric power train"
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
    ),
    item(
      NAME = "MpKwhAdjHevHh",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Power efficiency adjustment for households with HEV"
    ),
    item(
      NAME = "MpKwhAdjEvHh",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Power efficiency adjustment for households households with EV"
    ),
    # Global variables
    item(
      NAME = "LtVehDvmtFactor",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Light vehicle Dvmt factor"
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
#' @param Model_ls A list of congestion models and parameters required by the models
#' @param DvmtByVehType A data frame of dvmt by vehicle types
#' @param PerCapFwyLnMi A named numeric vector of free way lane miles
#' @param PerCapArtLnMi A named numeric vector of arterial lane miles
#' @param Population A numeric indicating the current year population
#' @param BasePopulation A numeric indicating the base year population
#' @param CongPrice_ClFc A matrix of congestion pricing by congestion level
#' and functional class
#' @param IncdReduc A numeric indicating proportion of incidence reduced by ITS
#' @param FwyArtProp A numeric indicating the proportions of daily VMT for light
#' vehicles that takes place on freeways and arterials
#' @param BusVmtSplit_Fc A data frame indicating the bus vmt split by freeways, arterials
#' and others
#' @param TruckVmtSplit_Fc A data frame indicating the truck vmt split by freeways, arterials
#' and others
#' @param UsePce A logical suggesting whether to convert heavy truck and bus dvmt to
#' passenger car equivalents for congestion calculation. (Default: FALSE)
#' @param ValueOfTime A numeric representing weights on time to model congestion price
#' @param CurrYear A character indicating current run year
#' @return A list containing mpg adjustments, travel time, and travel delay hours
#' by vehicle types.
#' @export
calcCongestion <- function(Model_ls, DvmtByVehType, PerCapFwyLnMi, PerCapArtLnMi,
                           Population, BasePopulation, CongPrice_ClFc,
                           IncdReduc=0, FwyArtProp, BusVmtSplit_Fc, TruckVmtSplit_Fc,
                           UsePce=FALSE, ValueOfTime=16, CurrYear) {


  # Define function to split DVMT by functional class
  #==================================================
  splitDvmtByFc <- function() {
    # Calculate Dvmt by functional class
    FwyArtDvmt <- sum( DvmtByVehType ) * FwyArtProp
    FwyDvmt <- FwyArtDvmt * FwyDvmtRatio
    ArtDvmt <- FwyArtDvmt - FwyDvmt
    Dvmt_Fc <- c( FwyDvmt, ArtDvmt, sum( DvmtByVehType ) - FwyArtDvmt )
    names( Dvmt_Fc ) <- c( "Fwy", "Art", "Other" )
    rm( FwyArtDvmt, FwyDvmt, ArtDvmt )
    # Initialize array to hold results
    Dvmt_TyFc <- array( 0, dim=c(3,3), dimnames=list( Ty, Fc ) )
    # Split Truck Dvmt
    Dvmt_TyFc[ "Truck", ] <- unlist(DvmtByVehType[ "Truck" ] * TruckVmtSplit_Fc)
    # Split Bus Dvmt
    Dvmt_TyFc[ "Bus", ] <- unlist( DvmtByVehType[ "Bus" ] * BusVmtSplit_Fc )
    # Calculate light vehicle DVMT by functional class
    Dvmt_TyFc[ "LtVeh", ] <- Dvmt_Fc - colSums( Dvmt_TyFc )
    # Calculate freeway and arterial demand levels
    FwyDemandLvl <- Dvmt_Fc[ "Fwy" ] / ( PerCapFwyLnMi * Population / 1000 )
    ArtDemandLvl <- Dvmt_Fc[ "Art" ] / ( PerCapArtLnMi * Population / 1000 )
    # Return results
    Dvmt_TyFc <<- Dvmt_TyFc
    Dvmt_Fc <<- Dvmt_Fc
    FwyDemandLvl <<- FwyDemandLvl
    ArtDemandLvl <<- ArtDemandLvl
  }


  # Define function to calculate DVMT by congestion level
  #======================================================
  calcCongPct <- function( Lookup_=Model_ls$CongPct_, Category, Type, Demand ) {
    # Check if appropriate type
    if( !( Category %in% c( "DVMT", "VHT", "Dvmt", "Vht" ) ) ) {
      stop( "Type must be either DVMT, Dvmt or VHT, Vht" )
    }
    if( Category == "DVMT" ) Category <- "Dvmt"
    if( Category == "VHT" ) Category <- "Vht"
    # Check if appropriate type
    if( !( Type %in% c( "Fwy", "Art" ) ) ) {
      stop( "Type must be either Fwy or Art" )
    }
    # Extract the lookup table
    Lookup_LvCl <- Lookup_[[Category]][[Type]]
    DemandRange_ <- as.numeric( rownames( Lookup_LvCl ) )
    # If demand is outside the range, set to minimum or maximum of the range
    if( Demand < min( DemandRange_ ) ) Demand <- min( DemandRange_ )
    if( Demand > max( DemandRange_ ) ) Demand <- max( DemandRange_ )
    # If demand is equal to a lookup value, return the results
    if( as.character( Demand ) %in% rownames( Lookup_LvCl ) ) {
      Pct_Cl <- Lookup_LvCl[ as.character( Demand ), ]
      # Otherwise interpolate to find the value
    } else {
      LowDemand <- round( Demand - 50, -2 )
      HighDemand <- round( Demand + 50, -2 )
      LowPct_Cl <- Lookup_LvCl[ as.character( LowDemand ), ]
      HighPct_Cl <- Lookup_LvCl[ as.character( HighDemand ), ]
      LowWeight <- 1 - ( Demand - LowDemand ) / 100
      HighWeight <- 1 - ( HighDemand - Demand ) / 100
      Pct_Cl <- LowWeight * LowPct_Cl + HighWeight * HighPct_Cl
    }
    # Return the result
    return(Pct_Cl)
  }


  # Define function to calculate DVMT and speeds by congestion level
  #=================================================================
  calcSpeeds <- function() {

    # Calculate DVMT by vehicle type, functional class and congestion level
    #----------------------------------------------------------------------
    # Calculate light vehicle DVMT
    LtVehDvmt_ClFc <- array( 0, dim=c(length(Cl),length(Fc)), dimnames=list(Cl,Fc) )
    LtVehDvmt_ClFc[ ,"Fwy"] <- Dvmt_TyFc["LtVeh","Fwy"] * FwyDvmtPct_Cl / 100
    LtVehDvmt_ClFc[ ,"Art"] <- Dvmt_TyFc["LtVeh","Art"] * ArtDvmtPct_Cl / 100
    LtVehDvmt_ClFc["None","Other"] <- Dvmt_TyFc["LtVeh","Other"]
    # Calculate truck DVMT
    TruckDvmt_ClFc <- array( 0, dim=c(length(Cl),length(Fc)), dimnames=list(Cl,Fc) )
    TruckDvmt_ClFc[ ,"Fwy"] <- Dvmt_TyFc["Truck","Fwy"] * FwyDvmtPct_Cl / 100
    TruckDvmt_ClFc[ ,"Art"] <- Dvmt_TyFc["Truck","Art"] * ArtDvmtPct_Cl / 100
    TruckDvmt_ClFc["None","Other"] <- Dvmt_TyFc["Truck","Other"]
    # Calculate bus DVMT
    BusDvmt_ClFc <- array( 0, dim=c(length(Cl),length(Fc)), dimnames=list(Cl,Fc) )
    BusDvmt_ClFc[ ,"Fwy"] <- Dvmt_TyFc["Bus","Fwy"] * FwyDvmtPct_Cl / 100
    BusDvmt_ClFc[ ,"Art"] <- Dvmt_TyFc["Bus","Art"] * ArtDvmtPct_Cl / 100
    BusDvmt_ClFc["None","Other"] <- Dvmt_TyFc["Bus","Other"]

    # Calculate speeds by vehicle type, functional class, and congestion level
    #-------------------------------------------------------------------------
    # Calculate base travel rates
    BaseSpeeds_ClY <- Model_ls$BaseSpeeds..
    BaseTravelRates_ClY <- 1 / BaseSpeeds_ClY
    # Calculate base recurring and non-recurring delay for freeways and arterials by congestion level
    BaseDelay_ClDc <- array( 0, dim=c( length(Cl), length(Dc) ), dimnames=list( Cl, Dc ) )
    BaseDelay_ClDc[ , "Fwy_Rcr" ] <- BaseTravelRates_ClY[ , "Fwy_Rcr" ] - ( 1 / Model_ls$FreeFlowSpeed.Fc[ "Fwy" ] )
    BaseDelay_ClDc[ , "Art_Rcr" ] <- BaseTravelRates_ClY[ , "Art_Rcr" ] - ( 1 / Model_ls$FreeFlowSpeed.Fc[ "Art" ] )
    BaseDelay_ClDc[ , "Fwy_NonRcr" ] <- BaseTravelRates_ClY[ , "Fwy" ] - BaseTravelRates_ClY[ , "Fwy_Rcr" ]
    BaseDelay_ClDc[ , "Art_NonRcr" ] <- BaseTravelRates_ClY[ , "Art" ] - BaseTravelRates_ClY[ , "Art_Rcr" ]

    # Calculate incident reduction factors
    IncdFactors_ <- c( IncdReduc, 1 - IncdReduc )

    # Calculate the net light vehicle and truck delay considering delay reduction from standard operations programs
    # and the additional delay reduction from other programs
    FwyLtVehDelay_Cl <- ( rowSums( sweep(BaseDelay_ClDc[ , c( "Fwy_Rcr", "Fwy_NonRcr" ) ],
                                         2, IncdFactors_, "*") ) )
    FwyTruckDelay_Cl <- ( rowSums( sweep(BaseDelay_ClDc[ , c( "Fwy_Rcr", "Fwy_NonRcr" ) ],
                                         2, IncdFactors_, "*") ) )
    ArtLtVehDelay_Cl <- ( rowSums( sweep(BaseDelay_ClDc[ , c( "Art_Rcr", "Art_NonRcr" ) ],
                                         2, IncdFactors_, "*") ) )
    ArtTruckDelay_Cl <- ( rowSums( sweep(BaseDelay_ClDc[ , c( "Art_Rcr", "Art_NonRcr" ) ],
                                         2, IncdFactors_, "*") ) )

    # Calculate light vehicle congested speeds
    LtVehCongSpeed_ClFc <- array( 0, dim=c( length(Cl), length(Fc) ), dimnames=list( Cl, Fc ) )
    LtVehCongSpeed_ClFc[ , "Fwy" ] <- 1 / ( ( 1 / Model_ls$FreeFlowSpeed.Fc[ "Fwy" ] ) +
                                               FwyLtVehDelay_Cl )
    LtVehCongSpeed_ClFc[ , "Art" ] <- 1 / ( ( 1 / Model_ls$FreeFlowSpeed.Fc[ "Art" ] ) +
                                               ArtLtVehDelay_Cl )
    LtVehCongSpeed_ClFc[ , "Other" ] <- Model_ls$FreeFlowSpeed.Fc[ "Other" ]
    # Calculate truck congested speeds
    TruckCongSpeed_ClFc <- array( 0, dim=c( length(Cl), length(Fc) ), dimnames=list( Cl, Fc ) )
    TruckCongSpeed_ClFc[ , "Fwy" ] <- 1 / ( ( 1 / Model_ls$FreeFlowSpeed.Fc[ "Fwy" ] ) +
                                               FwyTruckDelay_Cl )
    TruckCongSpeed_ClFc[ , "Art" ] <- 1 / ( ( 1 / Model_ls$FreeFlowSpeed.Fc[ "Art" ] ) +
                                               ArtTruckDelay_Cl )
    TruckCongSpeed_ClFc[ , "Other" ] <- Model_ls$FreeFlowSpeed.Fc[ "Other" ]
    # Calculate bus congested speeds
    # Since normal bus operating speeds on arterials and other are lower than freeflow speed
    BusCongSpeed_ClFc <- TruckCongSpeed_ClFc
    BusCongSpeed_ClFc[ , "Art" ] <- pmin( BusCongSpeed_ClFc[ , "Art" ], Model_ls$BusSpeeds.Fc[ "Art" ] )
    BusCongSpeed_ClFc[ , "Other" ] <- pmin( BusCongSpeed_ClFc[ , "Other" ], Model_ls$BusSpeeds.Fc[ "Other" ] )
    # Calculate vehicle hours of travel considering effects of operations programs
    LtVehHr_ClFc <- LtVehDvmt_ClFc / LtVehCongSpeed_ClFc
    TruckHr_ClFc <- TruckDvmt_ClFc / TruckCongSpeed_ClFc
    BusHr_ClFc <- BusDvmt_ClFc / BusCongSpeed_ClFc
    # Calculate vehicle hours of travel considering only base speeds
    # This is used in the model to split DVMT into freeway and arterial components
    BaseSpeeds_ClFc <- cbind( Model_ls$BaseSpeeds..[,1:2], Other=20 )
    BusBaseSpeeds_ClFc <- BaseSpeeds_ClFc
    BusBaseSpeeds_ClFc[ , "Art" ] <- pmin( BusBaseSpeeds_ClFc[ , "Art" ], Model_ls$BusSpeeds.Fc[ "Art" ] )
    BusBaseSpeeds_ClFc[ , "Other" ] <- pmin( BusBaseSpeeds_ClFc[ , "Other" ], Model_ls$BusSpeeds.Fc[ "Other" ] )
    BaseLtVehHr_ClFc <- LtVehDvmt_ClFc / BaseSpeeds_ClFc
    BaseTruckHr_ClFc <- TruckDvmt_ClFc / BaseSpeeds_ClFc
    BaseBusHr_ClFc <- BusDvmt_ClFc / BusBaseSpeeds_ClFc
    # Calculate average speeds by functional class
    VehHr_Fc <- colSums( LtVehHr_ClFc ) + colSums( TruckHr_ClFc ) + colSums( BusHr_ClFc )
    AveSpeed_Fc <- Dvmt_Fc / VehHr_Fc

    # Return results in a list
    #-------------------------
    list( Dvmt_TyFc=Dvmt_TyFc, AveSpeed_Fc=AveSpeed_Fc, LtVehDvmt_ClFc=LtVehDvmt_ClFc,
          TruckDvmt_ClFc=TruckDvmt_ClFc, BusDvmt_ClFc=BusDvmt_ClFc, LtVehCongSpeed_ClFc=LtVehCongSpeed_ClFc,
          TruckCongSpeed_ClFc=TruckCongSpeed_ClFc, BusCongSpeed_ClFc=BusCongSpeed_ClFc,
          LtVehHr_ClFc=LtVehHr_ClFc, TruckHr_ClFc=TruckHr_ClFc, BusHr_ClFc=BusHr_ClFc,
          BaseLtVehHr_ClFc=BaseLtVehHr_ClFc, BaseTruckHr_ClFc=BaseTruckHr_ClFc, BaseBusHr_ClFc=BaseBusHr_ClFc )

  }


  # Define dimensions
  #==================
  Ty <- c("LtVeh","Truck","Bus") # Vehicle types
  Fc <- c("Fwy","Art","Other") # Function class
  Cl <- c( "None", "Mod", "Hvy", "Sev", "Ext" ) # Congestion level
  Dc <- c( "Fwy_Rcr", "Fwy_NonRcr", "Art_Rcr", "Art_NonRcr" ) # Delay categories

  # Find the change in the Lambda value given the change in population
  #===================================================================
  Lambda <- Model_ls$Lambda.Ma[ "Metro" ]
  predLd <- function( BasePopulation, Population, BaseLd, Intercept=-0.314318, Slope=0.0402095 ) {
    LdChgRatio <- ( Intercept + Slope * log( Population ) ) /
      ( Intercept + Slope * log( BasePopulation ) )
    LdChgRatio * BaseLd
  }
  Lambda <- predLd( BasePopulation, Population, BaseLd=Lambda )

  # Find equilibrium speeds and DVMT considering pricing
  #=====================================================
  # Calculate initial factor to split DVMT into freeway component
  # Data structure and function to track convergence
  FwyDvmt_ <- numeric(0)
  FwyDvmtRatio_ <- numeric(0)
  SpeedRatio_ <- numeric(0)
  notConverged <- function() {
    if( length( FwyDvmt_ ) < 5 ) {
      TRUE
    } else {
      abs( diff( tail( FwyDvmt_, 2 ) ) ) / tail( FwyDvmt_, 1 ) > 0.0001
    }
  }
  MaxItr <- 500
  # Calculate until converged	or iteration limit reached
  i <- 0
  while( notConverged() & (i < MaxItr) ) {
    i <- i + 1
    # Initial computations for the first iteration
    if( i == 1 ) {
      # Calculate initial split
      LnMiRatio <- PerCapFwyLnMi / PerCapArtLnMi
      FwyDvmtRatio <- eval( parse( text=Model_ls$DvmtRatio ) )
      FwyDvmtRatio_ <- c( FwyDvmtRatio_, FwyDvmtRatio )
      splitDvmtByFc()
      FwyDvmt_ <- c( FwyDvmt_, Dvmt_Fc[ "Fwy" ] )
      # Split Dvmt by congestion level without considering congestion pricing
      FwyDvmtPct_Cl <- calcCongPct( Model_ls$CongPct_, "Dvmt", "Fwy", FwyDemandLvl )
      ArtDvmtPct_Cl <- calcCongPct( Model_ls$CongPct_, "Dvmt", "Art", ArtDemandLvl )
    } else {
      # Split Dvmt based on the ratio of speeds
      FwyDvmtRatio_ <- c( FwyDvmtRatio_, Lambda * SpeedRatio )
      FwyDvmtRatio <- mean( FwyDvmtRatio_ )
      splitDvmtByFc()
      FwyDvmt <- Dvmt_Fc[ "Fwy" ]
      FwyDvmt_ <- c( FwyDvmt_, FwyDvmt )
      # Split freeway DVMT into congestion levels considering effect of congestion pricing
      FwyVht <- FwyDvmt / EqAveSpeed_Fc["Fwy"]
      FwyVhtPct_Cl <- calcCongPct( Model_ls$CongPct_, "Vht", "Fwy", FwyDemandLvl )
      FwyVht_Cl <- FwyVht * FwyVhtPct_Cl / 100
      FwyDvmt_Cl <- EqAveSpeed_ClFc[,"Fwy"] * FwyVht_Cl
      FwyDvmtPct_Cl <- 100 * FwyDvmt_Cl / sum( FwyDvmt_Cl )
      # Split arterial DVMT into congestion levels considering effect of congestion pricing
      ArtDvmt <- sum( Dvmt_Fc ) - FwyDvmt
      ArtVht <- ArtDvmt / EqAveSpeed_Fc["Art"]
      ArtVhtPct_Cl <- calcCongPct( Model_ls$CongPct_, "Vht", "Art", ArtDemandLvl )
      ArtVht_Cl <- ArtVht * ArtVhtPct_Cl / 100
      ArtDvmt_Cl <- EqAveSpeed_ClFc[,"Art"] * ArtVht_Cl
      ArtDvmtPct_Cl <- 100 * ArtDvmt_Cl / sum( ArtDvmt_Cl )
    }
    # Calculate average speeds
    SpdCalc_ <- calcSpeeds()
    # Tabulate DVMT by type, congestion level and functional class
    TruckDvmt_ClFc <- SpdCalc_$TruckDvmt_ClFc
    BusDvmt_ClFc <- SpdCalc_$BusDvmt_ClFc
    LtVehDvmt_ClFc <- SpdCalc_$LtVehDvmt_ClFc
    Dvmt_ClFc <- TruckDvmt_ClFc + BusDvmt_ClFc + LtVehDvmt_ClFc
    # Tabulate VHT by type, congestion level and functional class
    TruckHr_ClFc <- SpdCalc_$TruckHr_ClFc
    BusHr_ClFc <- SpdCalc_$BusHr_ClFc
    LtVehHr_ClFc <- SpdCalc_$LtVehHr_ClFc
    # Calculate equivalent vehicle hours considering congestion pricing
    LtVehCost_ClFc <- LtVehHr_ClFc * ValueOfTime + CongPrice_ClFc * SpdCalc_$LtVehDvmt_ClFc
    EqLtVehHr_ClFc <- LtVehCost_ClFc / ValueOfTime
    EqVehHr_ClFc <- EqLtVehHr_ClFc + TruckHr_ClFc + BusHr_ClFc
    # Calculate equivalent speeds considering congestion pricing
    EqAveSpeed_ClFc <- Dvmt_ClFc / EqVehHr_ClFc
    EqAveSpeed_Fc <- colSums( Dvmt_ClFc ) / colSums( EqVehHr_ClFc )
    # Calculate average speeds, the speed ratio and the new split ratio
    SpeedRatio <- EqAveSpeed_Fc["Fwy"] / EqAveSpeed_Fc["Art"]
    SpeedRatio_ <- c( SpeedRatio_, SpeedRatio )
  } # End loop to find equilibrium


  # Calculate fuel economy adjustment factors for speed smoothing and eco-driving
  #==============================================================================

  # Put inputs and model in form for calculations
  #----------------------------------------------
  # Maximum fuel savings (50% of the theoretical maximum)
  MaxIceFuelSavings_SpTy <- as.matrix( Model_ls$SpdSmoothEff.. * 0.5 )
  colnames( MaxIceFuelSavings_SpTy ) <- c( "LtVeh", "Truck" )
  # Proportion of maximum benefit achieved by speed smoothing
  SmoothPropMaxBenefit_Fc <- c( Fwy=Model_ls$SmoothEcoDriveParmVa_ls$FwySmooth[ "Metro", CurrYear ],
                                Art=Model_ls$SmoothEcoDriveParmVa_ls$ArtSmooth[ "Metro", CurrYear ] )
  # Proportion of maximum benefit achieved by eco-driving
  EcoPropMaxBenefit_Fc <- Model_ls$EcoDriveFraction.Ty
  # Proportion of drivers who practice ecodriving
  EcoDriverProp_Ty <- c( LtVeh=Model_ls$SmoothEcoDriveParmVa_ls$LtVehEco[ "Metro", CurrYear ],
                         Truck=Model_ls$SmoothEcoDriveParmVa_ls$TruckEco[ "Metro", CurrYear ] )

  # Determine benefits for light vehicles with ICE engines
  #-------------------------------------------------------
  # Non-ecodriver benefits result from speed smoothing only
  LtVehNonEcoBenefit_SpFc <- outer( MaxIceFuelSavings_SpTy[ , "LtVeh" ], SmoothPropMaxBenefit_Fc, "*" )
  # Ecodriver benefits result from ecodriving unless the speed smoothing benefits are greater
  LtVehEcoBenefit_SpFc <- outer( MaxIceFuelSavings_SpTy[ , "LtVeh" ], EcoPropMaxBenefit_Fc, "*" )
  LtVehEcoBenefit_SpFc[ LtVehNonEcoBenefit_SpFc > LtVehEcoBenefit_SpFc ] <-
    LtVehNonEcoBenefit_SpFc[ LtVehNonEcoBenefit_SpFc > LtVehEcoBenefit_SpFc ]

  # Determine benefits for trucks with ICE engines
  #-----------------------------------------------
  # Since trucks are dealt with in aggregate, smoothing and ecodriving benefits are averaged
  # Benefits of speed smoothing
  TruckNonEcoBenefit_SpFc <- outer( MaxIceFuelSavings_SpTy[ , "Truck" ], SmoothPropMaxBenefit_Fc, "*" )
  # Benefits of ecodriving
  TruckEcoBenefit_SpFc <- outer( MaxIceFuelSavings_SpTy[ , "Truck" ], EcoPropMaxBenefit_Fc, "*" )
  TruckEcoBenefit_SpFc[ TruckNonEcoBenefit_SpFc > TruckEcoBenefit_SpFc ] <-
    TruckNonEcoBenefit_SpFc[ TruckNonEcoBenefit_SpFc > TruckEcoBenefit_SpFc ]
  # Net benefits
  TruckCombBenefit_SpFc <- TruckEcoBenefit_SpFc * EcoDriverProp_Ty[ "Truck" ] +
    TruckNonEcoBenefit_SpFc * ( 1 - EcoDriverProp_Ty[ "Truck" ] )


  # Calculate speed adjustments to fuel & power consumption
  #========================================================

  # Set up for calculating MPG adjustment values
  #---------------------------------------------
  # Indices
  Ce <- c("Low","High")                           # Congestion Efficiency
  FscCoef_ <- c('a0','a1','a2','a3','a4')         # FSC curve fit coefficients
  Av <- c("LdIce","LdHev","LdEv","LdFcv","HdIce") # Advanced vehicles modeled
  # Initialize a vector to store adjustments to Hydrocarbon and Electric driving
  MpgAdj_Ty <- numeric( length( Ty ) )
  names( MpgAdj_Ty ) <- Ty
  MpkwhAdj_Ty <- numeric( length( Ty ) )
  names( MpkwhAdj_Ty ) <- Ty

  # Function to Calculate the fuel economy adjustments from FSC coefficients and a reference speed
  #-----------------------------------------------------------------------------------------------
  calcFeAdj <- function( FscCoef_, Speed_, RefSpeed ) {
    sapply( Speed_, function(x) {
      exp( sum( FscCoef_[-1] * c( x-RefSpeed, x^2-RefSpeed^2, x^3-RefSpeed^3, x^4-RefSpeed^4 ) ) )
    } )
  }

  # Define a function to interpolate adjustment values from a table (used for bus)
  #-------------------------------------------------------------------------------
  interpolate <- function( Spd, Spds_, Vals_ ) {
    # If the speed is greater or less than the range of speeds, return the
    # highest or lowest values respectively
    if( Spd >= max( Spds_ ) | Spd <= min( Spds_ ) ) {
      if( Spd >= max( Spds_ ) ) {
        Val <- Vals_[ which( Spds_ == max( Spds_ ) ) ]
      } else {
        Val <- Vals_[ which( Spds_ == min( Spds_ ) ) ]
      }
      # Otherwise interpolate to find the value
    } else {
      Idx_ <- which( rank( abs( Spds_ - Spd ), ties.method="first" ) <= 2 )
      ValsProp_ <- abs( Spds_[ Idx_ ] - Spd ) / abs( diff( Spds_[ Idx_ ] ) )
      Val <- sum( Vals_[ Idx_ ] * rev( ValsProp_ ) )
    }
    Val
  }

  # Calculate MPG and MPKWH adjustments based on congested speeds
  #--------------------------------------------------------------
  CongEff_Pt <- Model_ls$CongEfficiencyYrPt_ma[ CurrYear, ]
  # Initialize adjustment arrays
  FeAdj_ClFcAv <- array( 0, dim=c(length(Cl),length(Fc),length(Av)), dimnames=list(Cl,Fc,Av) )
  # Calculate freeway adjustments for light vehicles
  for( av in c( "LdIce", "LdHev", "LdEv", "LdFcv" ) ) { 		    # Cycle through vehicles
    FscRows_Ce <- which( Model_ls$AdvVehFsc..$FacilityType=="Fwy" & Model_ls$AdvVehFsc..$AdvVehType==av )
    names( FscRows_Ce ) <- Model_ls$AdvVehFsc..$CongEff[ FscRows_Ce ]
    FeAdj_ClFcAv[ , "Fwy", av ] <-
      unlist( 1 - CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["Low"], FscCoef_ ],
                 Speed_=SpdCalc_$LtVehCongSpeed_ClFc[,"Fwy"],
                 RefSpeed=Model_ls$FwyNormSpd ) +
      unlist( CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["High"], FscCoef_ ],
                 Speed_=SpdCalc_$LtVehCongSpeed_ClFc[,"Fwy"],
                 RefSpeed=Model_ls$FwyNormSpd )
  }
  # Calculate freeway adjustments for trucks
  for( av in c( "HdIce" ) ) { 		    # Cycle through vehicles
    FscRows_Ce <- which( Model_ls$AdvVehFsc..$FacilityType=="Fwy" & Model_ls$AdvVehFsc..$AdvVehType==av )
    names( FscRows_Ce ) <- Model_ls$AdvVehFsc..$CongEff[ FscRows_Ce ]
    FeAdj_ClFcAv[ , "Fwy", av ] <-
      unlist( 1 - CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["Low"], FscCoef_ ],
                 Speed_=SpdCalc_$TruckCongSpeed_ClFc[,"Fwy"],
                 RefSpeed=Model_ls$FwyNormSpd ) +
      unlist( CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["High"], FscCoef_ ],
                 Speed_=SpdCalc_$TruckCongSpeed_ClFc[,"Fwy"],
                 RefSpeed=Model_ls$FwyNormSpd )
  }
  # Calculate arterial adjustments for light vehicles
  for( av in c( "LdIce", "LdHev", "LdEv", "LdFcv" ) ) { 		    # Cycle through vehicles
    FscRows_Ce <- which( Model_ls$AdvVehFsc..$FacilityType=="Art" & Model_ls$AdvVehFsc..$AdvVehType==av )
    names( FscRows_Ce ) <- Model_ls$AdvVehFsc..$CongEff[ FscRows_Ce ]
    FeAdj_ClFcAv[ , "Art", av ] <-
      unlist( 1 - CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["Low"], FscCoef_ ],
                 Speed_=SpdCalc_$LtVehCongSpeed_ClFc[,"Art"],
                 RefSpeed=Model_ls$ArtNormSpd ) +
      unlist( CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["High"], FscCoef_ ],
                 Speed_=SpdCalc_$LtVehCongSpeed_ClFc[,"Art"],
                 RefSpeed=Model_ls$ArtNormSpd )
  }
  # Calculate freeway adjustments for trucks
  for( av in c( "HdIce" ) ) { 		    # Cycle through vehicles
    FscRows_Ce <- which( Model_ls$AdvVehFsc..$FacilityType=="Art" & Model_ls$AdvVehFsc..$AdvVehType==av )
    names( FscRows_Ce ) <- Model_ls$AdvVehFsc..$CongEff[ FscRows_Ce ]
    FeAdj_ClFcAv[ , "Art", av ] <-
      unlist( 1 - CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["Low"], FscCoef_ ],
                 Speed_=SpdCalc_$TruckCongSpeed_ClFc[,"Art"],
                 RefSpeed=Model_ls$ArtNormSpd ) +
      unlist( CongEff_Pt[ av ] ) *
      calcFeAdj( Model_ls$AdvVehFsc..[ FscRows_Ce["High"], FscCoef_ ],
                 Speed_=SpdCalc_$TruckCongSpeed_ClFc[,"Art"],
                 RefSpeed=Model_ls$ArtNormSpd )
  }
  # Calculate other roadway adjustments  (none)
  FeAdj_ClFcAv[,"Other",] <- 1

  # Calculate MPG and MPKWH adjustments by powertrain types
  #--------------------------------------------------------
  Pt <- c( "LdIceEco", "LdIceNonEco", "LdHev", "LdFcv", "LdEv", "TruckIce", "TruckEv", "BusIce", "BusEv" )
  MpgMpkwhAdj_Pt <- numeric( length(Pt) )
  names( MpgMpkwhAdj_Pt ) <- Pt
  # Calculate adjustments for ecodrivers of ICE engine light vehicles
  LtVehEcoAdj_ClFc <- array( 1, dim=c( length(Cl), length(Fc) ), dimnames=list( Cl, Fc ) )
  LtVehEcoAdj_ClFc[ , "Fwy" ] <- 1 + sapply( SpdCalc_$LtVehCongSpeed_ClFc[ , "Fwy" ], function(x) {
    interpolate( x, as.numeric( rownames( LtVehEcoBenefit_SpFc ) ), LtVehEcoBenefit_SpFc[ ,"Fwy" ] ) } )
  LtVehEcoAdj_ClFc[ , "Art" ] <- 1 + sapply( SpdCalc_$LtVehCongSpeed_ClFc[ , "Art" ], function(x) {
    interpolate( x, as.numeric( rownames( LtVehEcoBenefit_SpFc ) ), LtVehEcoBenefit_SpFc[ ,"Art" ] ) } )
  MpgMpkwhAdj_Pt[ "LdIceEco" ] <- sum( FeAdj_ClFcAv[ , , "LdIce" ] * LtVehEcoAdj_ClFc * SpdCalc_$LtVehDvmt_ClFc ) /
    sum( SpdCalc_$LtVehDvmt_ClFc )
  # Calculate adjustments of non-ecodrivers of ICE engine light vehicles
  LtVehNonEcoAdj_ClFc <- array( 1, dim=c( length(Cl), length(Fc) ), dimnames=list( Cl, Fc ) )
  LtVehNonEcoAdj_ClFc[ , "Fwy" ] <- 1 + sapply( SpdCalc_$LtVehCongSpeed_ClFc[ , "Fwy" ], function(x) {
    interpolate( x, as.numeric( rownames( LtVehNonEcoBenefit_SpFc ) ), LtVehNonEcoBenefit_SpFc[ ,"Fwy" ] ) } )
  LtVehNonEcoAdj_ClFc[ , "Art" ] <- 1 + sapply( SpdCalc_$LtVehCongSpeed_ClFc[ , "Art" ], function(x) {
    interpolate( x, as.numeric( rownames( LtVehNonEcoBenefit_SpFc ) ), LtVehNonEcoBenefit_SpFc[ ,"Art" ] ) } )
  MpgMpkwhAdj_Pt[ "LdIceNonEco" ] <- sum( FeAdj_ClFcAv[ , , "LdIce" ] * LtVehNonEcoAdj_ClFc * SpdCalc_$LtVehDvmt_ClFc ) /
    sum( SpdCalc_$LtVehDvmt_ClFc )
  # Calculate adjustments for non-ICE engine light vehicles
  MpgMpkwhAdj_Pt[ "LdHev" ] <- sum( FeAdj_ClFcAv[ , , "LdHev" ] * SpdCalc_$LtVehDvmt_ClFc ) / sum( SpdCalc_$LtVehDvmt_ClFc )
  MpgMpkwhAdj_Pt[ "LdFcv" ] <- sum( FeAdj_ClFcAv[ , , "LdFcv" ] * SpdCalc_$LtVehDvmt_ClFc ) / sum( SpdCalc_$LtVehDvmt_ClFc )
  MpgMpkwhAdj_Pt[ "LdEv" ]  <- sum( FeAdj_ClFcAv[ , , "LdEv" ] * SpdCalc_$LtVehDvmt_ClFc ) / sum( SpdCalc_$LtVehDvmt_ClFc )
  # Calculate adjustments for truck ICE engines
  TruckCombAdj_ClFc <- array( 1, dim=c( length(Cl), length(Fc) ), dimnames=list( Cl, Fc ) )
  TruckCombAdj_ClFc[ , "Fwy" ] <- 1 + sapply( SpdCalc_$TruckCongSpeed_ClFc[ , "Fwy" ], function(x) {
    interpolate( x, as.numeric( rownames( TruckCombBenefit_SpFc ) ), TruckCombBenefit_SpFc[ ,"Fwy" ] ) } )
  TruckCombAdj_ClFc[ , "Art" ] <- 1 + sapply( SpdCalc_$TruckCongSpeed_ClFc[ , "Art" ], function(x) {
    interpolate( x, as.numeric( rownames( TruckCombBenefit_SpFc ) ), TruckCombBenefit_SpFc[ ,"Art" ] ) } )
  MpgMpkwhAdj_Pt[ "TruckIce" ] <- sum( FeAdj_ClFcAv[ , , "HdIce" ] * TruckCombAdj_ClFc * SpdCalc_$TruckDvmt_ClFc ) /
    sum( SpdCalc_$TruckDvmt_ClFc )
  # Set adjustments for truck electric vehicles to 1
  MpgMpkwhAdj_Pt[ "TruckEv" ] <- 1

  # Calculate bus MPG adjustments
  #------------------------------
  # Initialize adjustment array
  BusMpgAdj_ClFc <- array( 0, dim=c( length(Cl), length(Fc) ), dimnames=list( Cl, Fc ) )
  # Calculate freeway adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$FwySpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$FwySpdMpgAdj..[,"Bus"]
  Speeds_ <- SpdCalc_$BusCongSpeed_ClFc[,"Fwy"]
  BusMpgAdj_ClFc[,"Fwy"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate arterial adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$ArtSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$ArtSpdMpgAdj..[,"Bus"]
  Speeds_ <- SpdCalc_$BusCongSpeed_ClFc[,"Art"]
  BusMpgAdj_ClFc[,"Art"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate other road adjustments
  SpeedIdx_ <- as.numeric( rownames( Model_ls$OtherSpdMpgAdj.. ) )
  MpgAdjIdx_ <- Model_ls$OtherSpdMpgAdj..[,"Bus"]
  Speeds_ <- SpdCalc_$BusCongSpeed_ClFc[,"Other"]
  BusMpgAdj_ClFc[,"Other"] <- sapply( Speeds_, function(x) {
    interpolate( x, SpeedIdx_, MpgAdjIdx_ ) } )
  # Calculate overall average adjustment
  MpgMpkwhAdj_Pt[ "BusIce" ] <- sum( BusMpgAdj_ClFc * SpdCalc_$BusDvmt_ClFc ) / sum( SpdCalc_$BusDvmt_ClFc )
  MpgMpkwhAdj_Pt[ "BusEv" ] <- 1


  # Miscellaneous calculations and preparations to return from function
  #====================================================================

  # Calculate vehicle hours and vehicle delay by vehicle type
  #----------------------------------------------------------
  # Calculate light vehicle freeflow travel time
  FfVehHr_Ty <- rep( 0, length(Ty) )
  names( FfVehHr_Ty ) <- Ty
  FfVehHr_Ty[ "LtVeh" ] <- sum( colSums( SpdCalc_$LtVehDvmt_ClFc ) / Model_ls$FreeFlowSpeed.Fc )
  FfVehHr_Ty[ "Truck" ] <- sum( colSums( SpdCalc_$TruckDvmt_ClFc ) / Model_ls$FreeFlowSpeed.Fc )
  FfVehHr_Ty[ "Bus" ] <- sum( colSums( SpdCalc_$BusDvmt_ClFc ) / Model_ls$BusSpeeds.Fc )
  # Calculate vehicle hours of travel
  VehHr_Ty <- c( LtVeh=sum( SpdCalc_$LtVehHr_ClFc ), Truck=sum( SpdCalc_$TruckHr_ClFc ), Bus=sum( SpdCalc_$BusHr_ClFc ) )
  # Calculate vehicle hours of delay
  DelayVehHr_Ty <- VehHr_Ty - FfVehHr_Ty

  # Calculate DVMT and average speed by vehicle type
  #-------------------------------------------------
  # Calculate DVMT
  Dvmt_Ty <- c( LtVeh=sum( SpdCalc_$LtVehDvmt_ClFc ), Truck=sum( SpdCalc_$TruckDvmt_ClFc ),
                Bus=sum( SpdCalc_$BusDvmt_ClFc ) )
  # Calculate average speeds
  AveSpeed_Ty <- Dvmt_Ty / VehHr_Ty

  # Return the result
  list( MpgMpkwhAdj_Pt=MpgMpkwhAdj_Pt, VehHr_Ty=VehHr_Ty, FfVehHr_Ty=FfVehHr_Ty,
        DelayVehHr_Ty=DelayVehHr_Ty, Dvmt_Ty=Dvmt_Ty, AveSpeed_Ty=AveSpeed_Ty,
        LtVehDvmt_ClFc=SpdCalc_$LtVehDvmt_ClFc, TruckDvmt_ClFc=SpdCalc_$TruckDvmt_ClFc,
        BusDvmt_ClFc=SpdCalc_$BusDvmt_ClFc, SpdCalc_=SpdCalc_,
        FeAdj_ClFcAv=FeAdj_ClFcAv, LtVehEcoAdj_ClFc=LtVehEcoAdj_ClFc,
        LtVehNonEcoAdj_ClFc=LtVehNonEcoAdj_ClFc )

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

  if(!is.null(L$Global$Model$LtVehDvmtFactor)){
    LtVehDvmtFactor_Ma <- L$Global$Model$LtVehDvmtFactor
  }

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

  # Sum population by metropolitan area
  #------------------------------------
  Pop_Ma <- sum(PopByPlaceType_vc)
  BasePop_Ma <- sum(BasePopByPlaceType_vc)
  rm(PopByPlaceType_vc, BasePopByPlaceType_vc)

  # Calculate congestion effects
  #=============================

  # Initialize arrays to store results
  VehicleType_vc <- c( "LtVeh", "Truck", "Bus" )
  Marea_vc <- L$Year$Marea$Marea
  FunctionalClass_vc <- c("Fwy", "Art", "Other")
  PowertrainType_vc <- c("LdIceEco", "LdIceNonEco", "LdHev", "LdFcv", "LdEv",
                         "TruckIce", "TruckEv", "BusIce", "BusEv")
  CongestionLevel_vc <- c("None", "Mod", "Hvy", "Sev", "Ext")
  MpgMpkwhAdjByMaPtType_vc <- array( 0, dim=c(length(Marea_vc),length(PowertrainType_vc)), dimnames=list(Marea_vc,PowertrainType_vc) )
  DelayVehHrByMaVehType_vc <- FfVehHrByMaVehType_vc <- AveSpeedByMaVehType_vc <-
    VehHrByMaVehType_vc <- array( 0, dim=c(length(Marea_vc),length(VehicleType_vc)),
                                  dimnames=list(Marea_vc,VehicleType_vc) )

  # Get the DVMT by vehicle type
  DvmtByVehType_vc <- DvmtType_Ma[Marea_vc,]

  # Extract freeway and arterial supply for the metropolitan area
  PerCapFwyLnMi_vc <- L$Year$Marea$FwyLaneMiPC
  PerCapArtLnMi_vc <- L$Year$Marea$ArtLaneMiPC



  # Extract population and ITS factor for the metropolitan area
  Population_vc <- Pop_Ma #just a single value
  BasePopulation_vc <- BasePop_Ma
  Its_Yr <- L$Year$Azone$ITS

  #Make an array of congestion prices
  CongPrice_ClFc <-
    array(0,
          dim = c(length(CongestionLevel_vc), length(FunctionalClass_vc)),
          dimnames = list(CongestionLevel_vc, FunctionalClass_vc))
  CongPrice_ClFc["Sev", "Fwy"] <-
    CongModel_ls$CongPriceParmVa_ma$FwySev["Metro", L$G$Year]
  CongPrice_ClFc["Ext", "Fwy"] <-
    CongModel_ls$CongPriceParmVa_ma$FwyExt["Metro", L$G$Year]
  CongPrice_ClFc["Sev", "Art"] <-
    CongModel_ls$CongPriceParmVa_ma$ArtSev["Metro", L$G$Year]
  CongPrice_ClFc["Ext", "Art"] <-
    CongModel_ls$CongPriceParmVa_ma$ArtExt["Metro", L$G$Year]

  # Calculate the MPG adjustment, travel time and travel delay
  CongResults_ls <- calcCongestion(Model_ls=CongModel_ls, DvmtByVehType=DvmtByVehType_vc,
                                  PerCapFwyLnMi=PerCapFwyLnMi_vc, PerCapArtLnMi=PerCapArtLnMi_vc,
                                  Population=Population_vc, BasePopulation=BasePopulation_vc,
                                  CongPrice_ClFc=CongPrice_ClFc, IncdReduc=Its_Yr, ValueOfTime = 16,
                                  FwyArtProp=L$Global$Model$BaseFwyArtProp,
                                  BusVmtSplit_Fc=BusVmt_Fc_df, TruckVmtSplit_Fc=TruckVmt_Fc_df,
                                  UsePce=FALSE, CurrYear = L$G$Year)

  # Insert results in array
  MpgMpkwhAdjByMaPtType_vc[Marea_vc, ] <- CongResults_ls$MpgMpkwhAdj_Pt
  VehHrByMaVehType_vc[Marea_vc, ] <- CongResults_ls$VehHr_Ty
  AveSpeedByMaVehType_vc[Marea_vc, ] <- CongResults_ls$AveSpeed_Ty
  FfVehHrByMaVehType_vc[Marea_vc, ] <- CongResults_ls$FfVehHr_Ty
  DelayVehHrByMaVehType_vc[Marea_vc, ] <- CongResults_ls$DelayVehHr_Ty

  # Clean up
  rm( DvmtByVehType_vc, PerCapFwyLnMi_vc, PerCapArtLnMi_vc, Population_vc, Its_Yr, CongResults_ls )

  # Calculate MPG adjustment on a household basis
  # Assuming the household VMT outside of metropolitan area is uncongested
  HhMpgMpkwhAdj_Ma <- ( MpgMpkwhAdjByMaPtType_vc[,PowertrainType_vc[1:5]] * LtVehDvmtFactor_Ma ) + ( 1 - LtVehDvmtFactor_Ma )

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()

  #Return the outputs list
  Out_ls$Year <- list(
    Marea = list(
      LtVehDvmt = LtVehDvmt_Ma,
      BusDvmt = BusDvmt_Ma,
      MpgAdjLtVeh = mean(MpgMpkwhAdjByMaPtType_vc[Marea_vc, c("LdIceEco","LdIceNonEco")]),
      MpKwhAdjLtVehHev =  MpgMpkwhAdjByMaPtType_vc[Marea_vc, "LdHev"],
      MpKwhAdjLtVehEv =  MpgMpkwhAdjByMaPtType_vc[Marea_vc, "LdEv"],
      MpgAdjBus = MpgMpkwhAdjByMaPtType_vc[Marea_vc, "BusIce"],
      MpKwhAdjBus = MpgMpkwhAdjByMaPtType_vc[Marea_vc, "BusEv"],
      MpgAdjTruck = MpgMpkwhAdjByMaPtType_vc[Marea_vc, "TruckIce"],
      MpKwhAdjTruck = MpgMpkwhAdjByMaPtType_vc[Marea_vc, "TruckEv"],
      VehHrLtVeh = VehHrByMaVehType_vc[Marea_vc, "LtVeh"],
      VehHrBus = VehHrByMaVehType_vc[Marea_vc, "Bus"],
      VehHrTruck = VehHrByMaVehType_vc[Marea_vc, "Truck"],
      AveSpeedLtVeh = AveSpeedByMaVehType_vc[Marea_vc, "LtVeh"],
      AveSpeedBus = AveSpeedByMaVehType_vc[Marea_vc, "Bus"],
      AveSpeedTruck = AveSpeedByMaVehType_vc[Marea_vc, "Truck"],
      FfVehHrLtVeh = FfVehHrByMaVehType_vc[Marea_vc, "LtVeh"],
      FfVehHrBus = FfVehHrByMaVehType_vc[Marea_vc, "Bus"],
      FfVehHrTruck = FfVehHrByMaVehType_vc[Marea_vc, "Truck"],
      DelayVehHrLtVeh = DelayVehHrByMaVehType_vc[Marea_vc, "LtVeh"],
      DelayVehHrBus = DelayVehHrByMaVehType_vc[Marea_vc, "Bus"],
      DelayVehHrTruck = DelayVehHrByMaVehType_vc[Marea_vc, "Truck"],
      MpgAdjHh = mean(HhMpgMpkwhAdj_Ma[c("LdIceEco","LdIceNonEco")]),
      MpKwhAdjHevHh =  HhMpgMpkwhAdj_Ma["LdHev"],
      MpKwhAdjEvHh =  HhMpgMpkwhAdj_Ma["LdEv"]
    )
  )
  Out_ls$Global <- list(
    Model = list(
      LtVehDvmtFactor = LtVehDvmtFactor_Ma
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
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
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
