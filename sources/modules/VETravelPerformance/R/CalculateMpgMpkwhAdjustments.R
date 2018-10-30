#==============================
#CalculateMpgMpkwhAdjustments.R
#==============================
#This module calculates adjustments to fuel economy and electric energy economy
#(for plug-in vehicles) resulting from traffic congestion, speed smoothing
#(i.e. active traffic management which reduces speed variation), and ecodriving
#practices.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module calculates adjustments to the average fuel economy of internal
#combustion engine vehicles and the average electric energy efficiency of plug
#in vehicle. Adjustments are made as a function of vehicle speeds using
#"fuel-speed curves" and as a function of speed-smoothing (reduction in speed
#variation) due to active traffic management and/or eco-driving behavior. The
#fuel-speed curve methodology is based on research by Alex Bigazzi and Kelly
#Clifton ("Refining GreenSTEP: Impacts of Vehicle Technologies and
#ITS/Operational Improvements on Travel Speed and Fuel Consumption Curves Final
#Report on Task 1: Advanced Vehicle Fuel-Speed Curves", November 2011). A copy
#of this report is included in the inst/extdata/sources directory. The
#speed-smoothing methodology is also based on research by Bigazzi and Clifton
#("Refining GreenSTEP: Impacts of Vehicle Technologies and ITS/Operational
#Improvements on Travel Speed and Fuel Consumption Curves Final Report on Task
#2: Incorporation of Operations and ITS Improvements", November 2011."). A copy
#of this report is located in the inst/extdata/sources directory of the
#VERoadPerformance package.

#Create list to hold MPG & MPKWH adjustment parameters
#-----------------------------------------------------
MpgMpkwhAdj_ls <- list()

#----------------------------
#Fuel-Speed Curve Adjustments
#----------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "AdvVehType",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = c("LdIce", "LdHev", "LdEv", "LdFcv", "HdIce"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "FacilityType",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = c("Fwy", "Art"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "CongEff",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = c("Low", "High"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("a0", "a1", "a2", "a3", "a4"),
    TYPE = "double",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
VehFSC_df <-
  processEstimationInputs(
    Inp_ls,
    "vehicle_fuel_speed_curves.csv",
    "LoadDefaultValues.R")
#Add to EnergyEmissionsDefaults_ls and clean up
MpgMpkwhAdj_ls$VehFSC_df <- VehFSC_df
#Add freeway and arterial normalization speeds
MpgMpkwhAdj_ls$RefSpeeds_ <- c(
  Fwy = 48.20379,
  Art = 24.43473
)
#Clean up
rm(Inp_ls, VehFSC_df)

#-----------------------------
#Speed Smoothing Effectiveness
#-----------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Speed",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "LdIce",
      "HdIce"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
SpeedSmoothEffect_df <-
  processEstimationInputs(
    Inp_ls,
    "max_smooth_improve.csv",
    "LoadDefaultValues.R")
#Compute smooth splines for values
MpgMpkwhAdj_ls$LdIceSpdSmthEffect_SS <-
  smooth.spline(SpeedSmoothEffect_df$Speed, SpeedSmoothEffect_df$LdIce)
MpgMpkwhAdj_ls$HdIceSpdSmthEffect_SS <-
  smooth.spline(SpeedSmoothEffect_df$Speed, SpeedSmoothEffect_df$HdIce, df = 5)
#Ecodriving fraction of maximum benefit
MpgMpkwhAdj_ls$EcoDriveFraction_Rc <- c(Fwy=0.33, Art=0.21)
#Clean up
rm(Inp_ls, SpeedSmoothEffect_df)

#-----------------------------------------------------
#Save the model parameters for adjusting MPG and MPkWh
#-----------------------------------------------------
#' MPG and MPkWh adjustment parameters
#'
#' Parameters for adjusting vehicle fuel economy (MPG) for internal combustion
#' engines and electrical energy economy (MPkWh) for plug-in vehicles based
#' on the distribution of vehicle speeds, the deployment of speed-smoothing
#' traffic operations, and eco-driving techniques.
#'
#' @format A list of dataframes and vectors
#' \describe{
#'   \item{VehFSC_df}{a data frame of coefficients for calculating fuel-speed curves for different vehicle types, powertrains, roadways, and congestion efficiency levels},
#'   \item{FwyNormSpd}{the freeway speed corresponding to average fuel economy ratings}
#'   \item{ArtNormSpd}{the arterial speed corresponding to average fuel economy ratings}
#'   \item{SpeedSmoothEffect_df}{a data frame of coeffients of maximum speed smoothing effectiveness in reducing fuel consumption by speed for light duty and for heavy duty internal combustion engine vehicles}
#'   \item{EcoDriveFraction_Rc}{a vector of values identifying the maximum fraction of fuel savings that can be had with ecodriving on freeways and on arterials}
#' }
#' @source CalculateMpgMpkwhAdjustments.R script.
"MpgMpkwhAdj_ls"
usethis::use_data(MpgMpkwhAdj_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateMpgMpkwhAdjustmentsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "FwySmooth",
          "ArtSmooth",
          "LdvEcoDrive",
          "HvyTrkEcoDrive"
        ),
      FILE = "marea_speed_smooth_ecodrive.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Fractional deployment of speed smoothing traffic management on freeways, where 0 is no deployment and 1 is the full potential fuel savings",
          "Fractional deployment of speed smoothing traffic management on arterials, where 0 is no deployment and 1 is the full potential fuel savings",
          "Eco-driving penetration for light-duty vehicles; the fraction of vehicles from 0 to 1",
          "Eco-driving penetration for heavy-duty vehicles; the fraction of vehicles from 0 to 1"
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
      NAME =
        items(
          "FwySmooth",
          "ArtSmooth"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
      ),
    item(
      NAME =
        items(
          "LdvFwyDvmt",
          "LdvArtDvmt",
          "LdvOthDvmt",
          "HvyTrkFwyDvmt",
          "HvyTrkArtDvmt",
          "HvyTrkOthDvmt",
          "BusFwyDvmt",
          "BusArtDvmt",
          "BusOthDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyNoneCongSpeed",
        "FwyModCongSpeed",
        "FwyHvyCongSpeed",
        "FwySevCongSpeed",
        "FwyExtCongSpeed",
        "ArtNoneCongSpeed",
        "ArtModCongSpeed",
        "ArtHvyCongSpeed",
        "ArtSevCongSpeed",
        "ArtExtCongSpeed",
        "OthSpd"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyDvmtPropNoneCong",
        "FwyDvmtPropModCong",
        "FwyDvmtPropHvyCong",
        "FwyDvmtPropSevCong",
        "FwyDvmtPropExtCong",
        "ArtDvmtPropNoneCong",
        "ArtDvmtPropModCong",
        "ArtDvmtPropHvyCong",
        "ArtDvmtPropSevCong",
        "ArtDvmtPropExtCong"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = items(
        "LdvSpdSmoothFactor",
        "HvyTrkSpdSmoothFactor",
        "BusSpdSmoothFactor",
        "LdvEcoDriveFactor",
        "HvyTrkEcoDriveFactor",
        "BusEcoDriveFactor",
        "LdIceFactor",
        "LdHevFactor",
        "LdEvFactor",
        "LdFcvFactor",
        "HdIceFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to speed smoothing",
          "Proportional adjustment of heavy truck internal combustion engine (ICE) vehicle MPG due to speed smoothing",
          "Proportional adjustment of bus internal combustion engine (ICE) vehicle MPG due to speed smoothing",
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to eco-driving",
          "Proportional adjustment of heavy truck internal combustion engine (ICE) vehicle MPG due to eco-driving",
          "Proportional adjustment of bus internal combustion engine (ICE) vehicle MPG due to eco-driving",
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to congestion",
          "Proportional adjustment of light-duty hybrid-electric vehicle (HEV) MPG due to congestion",
          "Proportional adjustment of light-duty battery electric vehicle (EV) MPkWh due to congestion",
          "Proportional adjustment of light-duty fuel cell vehicle (FCV) MPkWh due to congestion",
          "Proportional adjustment of heavy-duty internal combustion engine (ICE) vehicle MPG due to congestion")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateMpgMpkwhAdjustments module
#'
#' A list containing specifications for the CalculateCarbonIntensity module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateMpgMpkwhAdjustments.R script.
"CalculateMpgMpkwhAdjustmentsSpecifications"
usethis::use_data(CalculateMpgMpkwhAdjustmentsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates factors for adjusting the fuel economy (MPG) and
#electric energy efficiency (MPkWh) of vehicles of different type in different
#Mareas as due to speed smoothing (i.e. reducing speed variation as a result of
#active traffic management measures), eco-driving behavior, and roadway
#congestion.

#Main module function that calculates MPG/MPkWh adjustment factors
#-----------------------------------------------------------------
#' Main function to calculate MPG/MPkWh adjustment factors.
#'
#' \code{CalculateMpgMpkwhAdjustments} calculates MPG and MPkWh adjustment
#' factors for the effects of speed smoothing, eco-driving, and congestion.
#'
#' This function calculates factors for adjusting the fuel economy (MPG) and
#' electric energy efficiency (MPkWh) of vehicles of different type in different
#' Mareas as due to speed smoothing (i.e. reducing speed variation as a result
#' of active traffic management measures), eco-driving behavior, and roadway
#' congestion.
#'
#' @param L A list containing data requested by the module from the datastore.
#' @return A list containing data identified in the module Set specifications.
#' @name CalculateMpgMpkwhAdjustments
#' @import visioneval stats
#' @export
CalculateMpgMpkwhAdjustments <- function(L) {
  #------
  #SET UP
  #------
  #Create indexing vectors
  Ma <- L$Year$Marea$Marea
  Cl <- c("None", "Mod", "Hvy", "Sev", "Ext")
  Rc <- c("Fwy", "Art", "Oth")
  #Load energy and emissions defaults
  EnergyEmissionsDefaults_ls <- VEPowertrainsAndFuels::PowertrainFuelDefaults_ls

  #Create arrays of speeds and congested DVMT proportions by Marea, congestion
  #level, and road class, and DVMT proportion by road class by vehicle type
  #---------------------------------------------------------------------------
  #Speed Array
  Speed_MaClRc <-
    array(0, dim = c(length(Ma), length(Cl), length(Rc)), dimnames = list(Ma, Cl, Rc))
  Speed_MaClRc[,,"Fwy"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("Fwy", Cl, "CongSpeed")]))
  Speed_MaClRc[,,"Art"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("Art", Cl, "CongSpeed")]))
  Speed_MaClRc[,,"Oth"] <- L$Year$Marea$OthSpd
  #Congested DVMT proportions
  CongProp_MaClRc <-
    array(0, dim = c(length(Ma), length(Cl), length(Rc)), dimnames = list(Ma, Cl, Rc))
  CongProp_MaClRc[,,"Fwy"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("FwyDvmtProp", Cl, "Cong")]))
  CongProp_MaClRc[,,"Art"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("ArtDvmtProp", Cl, "Cong")]))
  CongProp_MaClRc[,,"Oth"] <- 0.2
  #Calculate DVMT proportions by road class for each vehicle type
  DvmtNames_ <- c("FwyDvmt", "ArtDvmt", "OthDvmt")
  Vt <- c("Ldv", "HvyTrk", "Bus")
  DvmtProp_ls <- lapply(Vt, function(x) {
    Dvmt_MaRc <- as.matrix(data.frame(L$Year$Marea[paste0(x, DvmtNames_)]))
    rownames(Dvmt_MaRc) <- Ma
    colnames(Dvmt_MaRc) <- c("Fwy", "Art", "Oth")
    sweep(Dvmt_MaRc, 1, rowSums(Dvmt_MaRc), "/")
  })
  names(DvmtProp_ls) <- Vt

  #-------------------------------------------------------------------------
  #CALCULATE MAXIMUM SPEED-SMOOTH/ECO-DRIVE FACTORS AT EACH CONGESTION LEVEL
  #-------------------------------------------------------------------------
  #Calculates speed smoothing maximum factors by road class for a given vehicle
  #type based on the estimated congested speeds
  calcMaxSpdSmAdj <- function(vt) {
    #Choose the speed smoothing factor model
    if (vt == "Ldv"){
      SpdSm_SS <- MpgMpkwhAdj_ls$LdIceSpdSmthEffect_SS
    } else {
      SpdSm_SS <- MpgMpkwhAdj_ls$HdIceSpdSmthEffect_SS
    }
    #Apply speed smoothing factor model to speeds by congestion level
    SpdSmMaxFactor_MaClRc <- Speed_MaClRc * 0
    for (ma in Ma) {
      Speed_ClRc <- Speed_MaClRc[ma,,]
      SpdSmFactor_ClRc <- apply(Speed_ClRc, 2, function(x) {
        predict(SpdSm_SS, x)$y })
      SpdSmFactor_ClRc[,"Oth"] <- 0
      SpdSmMaxFactor_MaClRc[ma,,] <- SpdSmFactor_ClRc
    }
    #Return the result
    SpdSmMaxFactor_MaClRc
  }
  #Calculate the speed smoothing maximum factors by vehicle type
  SpdSmMaxFactors_ls <- lapply(Vt, calcMaxSpdSmAdj)
  names(SpdSmMaxFactors_ls) <- Vt

  #-----------------------------------------------------
  #CALCULATE SPEED SMOOTHING ADJUSTMENTS BY VEHICLE TYPE
  #-----------------------------------------------------
  #Function calculates average speed smoothing adjustment by vehicle type
  calcAveSpdSmAdj <- function(vt, ma) {
    #Calculate DVMT proportions by Cl and Rc for each Marea
    DvmtProp_Rc <- DvmtProp_ls[[vt]][ma,]
    DvmtProp_ClRc <-
      sweep(CongProp_MaClRc[ma,,], 2, DvmtProp_Rc, "*")
    #Calculate freeway and arterial smoothing fractions
    SmoothFractions_Rc <- c(
      Fwy = L$Year$Marea$FwySmooth[L$Year$Marea$Marea == ma],
      Art = L$Year$Marea$ArtSmooth[L$Year$Marea$Marea == ma],
      Oth = 0
    ) * 0.5
    #Calculate the smoothing factors from the maximum values for the vehicle
    #type and the smoothing fractions
    SpdSmMaxFactor_ClRc <- SpdSmMaxFactors_ls[[vt]][ma,,]
    SpdSmFactor_ClRc <-
      sweep(SpdSmMaxFactor_ClRc, 2, SmoothFractions_Rc, "*") + 1
    #Calculate the weighted average factor
    sum(SpdSmFactor_ClRc * DvmtProp_ClRc)
  }
  AveSmoothFactors_MaVt <-
    array(1, dim = c(length(Ma), length(Vt)), dimnames = list(Ma, Vt))
  for (ma in Ma) {
    AveSmoothFactors_MaVt[ma,] <- sapply(Vt, function(x) calcAveSpdSmAdj(x, ma))
  }

  #-------------------------------------------------
  #CALCULATE ECO-DRIVING ADJUSTMENTS BY VEHICLE TYPE
  #-------------------------------------------------
  #Define function to calculate the average ecodriving adjustment by vehicle type
  calcAveEcoDrAdj <- function(vt, ma) {
    #Calculate DVMT proportions by Cl and Rc for each Marea
    DvmtProp_Rc <- DvmtProp_ls[[vt]][ma,]
    DvmtProp_ClRc <-
      sweep(CongProp_MaClRc[ma,,], 2, DvmtProp_Rc, "*")
    #Calculate the eco-driving benefits
    MaxBenefitFraction_Rc <- MpgMpkwhAdj_ls$EcoDriveFraction_Rc
    MaxBenefitFraction_Rc <- c(MaxBenefitFraction_Rc, Oth = 0)
    SpdSmMaxFactor_ClRc <- SpdSmMaxFactors_ls[[vt]][ma,,]
    EcoDrFactor_ClRc <-
        sweep(SpdSmMaxFactor_ClRc, 2, MaxBenefitFraction_Rc, "*") + 1
    #Calculate weighted average factor
    sum(DvmtProp_ClRc * EcoDrFactor_ClRc)
  }
  AveEcoDriveFactors_MaVt <-
    array(1, dim = c(length(Ma), length(Vt)), dimnames = list(Ma, Vt))
  for (ma in Ma) {
    AveEcoDriveFactors_MaVt[ma,Vt[1:2]] <-
      sapply(Vt[1:2], function(x) calcAveEcoDrAdj(x, ma))
  }

  #-----------------------------------------------------------
  #CALCULATE CONGESTION ADJUSTMENTS BY VEHICLE/POWERTRAIN TYPE
  #-----------------------------------------------------------
  #Function to calculate adjustments for a vehicle/powertrain and road type
  calcAdjByCl <- function(LowCoeff_, HighCoeff_, CongEff, Speeds_, RefSpd) {
    #Function to calculate ajustments for one set of coefficients
    calcLowOrHighCoeffAdj <- function(Coeff_) {
      sapply(Speeds_, function(x) {
        SpdTerms_ <-
          c(x, x^2, x^3, x^4) - c(RefSpd, RefSpd^2, RefSpd^3, RefSpd^4)
        exp(sum(Coeff_ * SpdTerms_))
      })
    }
    #Calculate low, high, and weighted average values
    LowVals_ <- calcLowOrHighCoeffAdj(LowCoeff_)
    HighVals_ <- calcLowOrHighCoeffAdj(HighCoeff_)
    LowVals_ * (1 - CongEff) + HighVals_ * CongEff
  }

  #Function to calculate average adjustment for a vehicle/powertrain type
  #----------------------------------------------------------------------
  calcMpgMpkwhAdj <- function(VehPtType, Marea) {
    CoeffNames_ <- c("a1", "a2", "a3", "a4")
    if (VehPtType %in% c("LdIce", "LdHev", "LdEv", "LdFcv")) {
      VehType <- "Ldv"
    } else {
      VehType <- "HvyTrk"
    }
    #Get speeds by congestion level and road class by Marea
    Speed_ClRc <- Speed_MaClRc[Marea,,]
    #Initialize an adjustments matrix by congestion level and road class
    Adj_ClRc <- Speed_ClRc * 0
    Adj_ClRc[,"Oth"] <- 1
    #Iterate by road class and calculate adjustments
    for (ft in c("Fwy", "Art")) {
      #Make matrix of coefficients
      Coeff_mx <-
        subset(MpgMpkwhAdj_ls$VehFSC_df,
               AdvVehType == VehPtType & FacilityType == ft)[,CoeffNames_]
      rownames(Coeff_mx) <-
        subset(MpgMpkwhAdj_ls$VehFSC_df,
                AdvVehType == VehPtType & FacilityType == ft)[,"CongEff"]
      #Get the congestion efficiency level
      YearIdx <-
        which(EnergyEmissionsDefaults_ls$CongestionEfficiency_df$Year == L$G$Year)
      CongEff <-
        EnergyEmissionsDefaults_ls$CongestionEfficiency_df[YearIdx, VehPtType]
      #Get the reference speed
      RefSpd <- MpgMpkwhAdj_ls$RefSpeeds_[ft]
      #Calculate adjustments by congestion level
      Adj_ClRc[,ft] <-
        calcAdjByCl(Coeff_mx["Low",], Coeff_mx["High",], CongEff, Speed_ClRc[,ft], RefSpd)
    }
    #Calculate weighted average value
    DvmtProp_Rc <- DvmtProp_ls[[VehType]][Marea,]
    DvmtProp_ClRc <-
      sweep(CongProp_MaClRc[Marea,,], 2, DvmtProp_Rc, "*")
    sum(DvmtProp_ClRc * Adj_ClRc)
  }

  #Calculate congestion adjustments by Marea and vehicle/powertrain type
  #---------------------------------------------------------------------
  # Initialize a vector to store adjustments to Hydrocarbon and Electric driving
  Vp <- c("LdIce", "LdHev", "LdEv", "LdFcv", "HdIce")
  MpgMpkwhAdj_MaVp <-
    array(1, dim = c(length(Ma), length(Vp)), dimnames = list(Ma, Vp))
  for (ma in Ma) {
    MpgMpkwhAdj_MaVp[ma,] <- sapply(Vp, function(x) calcMpgMpkwhAdj(x, ma))
  }

  #------------------
  #RETURN THE RESULTS
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Marea <- list(
    LdvSpdSmoothFactor = AveSmoothFactors_MaVt[,"Ldv"],
    HvyTrkSpdSmoothFactor = AveSmoothFactors_MaVt[,"HvyTrk"],
    BusSpdSmoothFactor = AveSmoothFactors_MaVt[,"Bus"],
    LdvEcoDriveFactor = AveEcoDriveFactors_MaVt[,"Ldv"],
    HvyTrkEcoDriveFactor = AveEcoDriveFactors_MaVt[,"HvyTrk"],
    BusEcoDriveFactor = AveEcoDriveFactors_MaVt[,"Bus"],
    LdIceFactor = MpgMpkwhAdj_MaVp[,"LdIce"],
    LdHevFactor = MpgMpkwhAdj_MaVp[,"LdHev"],
    LdEvFactor = MpgMpkwhAdj_MaVp[,"LdEv"],
    LdFcvFactor = MpgMpkwhAdj_MaVp[,"LdFcv"],
    HdIceFactor = MpgMpkwhAdj_MaVp[,"HdIce"]
  )
  Out_ls
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# load("data/EnergyEmissionsDefaults_ls.rda")
# attach(EnergyEmissionsDefaults_ls)
# TestDat_ <- testModule(
#   ModuleName = "CalculateMpgMpkwhAdjustments",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# TestOut_ls <- CalculateMpgMpkwhAdjustments(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# load("data/EnergyEmissionsDefaults_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "CalculateMpgMpkwhAdjustments",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
# setwd("tests")
# untar("Datastore.tar")
# setwd("..")

