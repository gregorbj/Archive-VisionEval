#=================
#DivertSovTravel.R
#=================
#This module reduces household single-occupant vehicle (SOV) travel to achieve
#goals that are inputs to the model. The purpose of this module is to enable
#users to do 'what if' analysis of the potential of light-weight vehicles (e.g.
#bicycles, electric bikes, electric scooters) and infrastructure to support
#their use to reduce SOV travel. The user inputs a goal for diverting a portion
#of SOV travel within a 20-mile tour distance (round trip distance). The model
#predicts the proportion of each household's DVMT that occurs in SOV tours
#having round trip distances of 20 miles or less. It then reduces SOV travel to
#achieve the overall goal. The reductions are allocated to households as a
#function of their likelihood to travel by bicycle using the bicycle trips
#forecasts calculated by the CalculateAltModeTrips module.



#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(data.table)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module estimates a model which predicts the proportion of household travel
#occurring in single-occupant vehicle tours that have round trip distances of 20
#miles or less. The model is estimated in 3 stages. In the first stage, models
#are estimated from the household data of the SOV travel: binomial logit model
#of the probability that there was no SOV travel, binomial logit model of the
#probability that there was all SOV travel, linear model of the SOV travel
#proportion is there was some but not all SOV travel. In the linear model the
#dependent variable is power-transformed. The power which minimizes the skew of
#the data is calculated. The linear model has much less variation than is
#observed so a dispersion term is estimated to match the variation. In the
#second stage, the three models are applied to every household in the estimation
#dataset one thousand times to simulate daily travel variation. Mean values for
#each household are calculated from the simulated results. In the 3rd step, a
#linear model is estimated to predict the power-transformed simulated mean
#values. This model is saved along with the transformation power.

#Set up data and functions to estimate models
#--------------------------------------------
#' @import data.table
#' @importFrom stats as.formula rnorm runif sd ppois quantile

#Load NHTS household data
Hh_df <- VE2001NHTS::Hh_df
#Add variables to Hh_df
Hh_df$Dvmt <- Hh_df$PvtVehDvmt + Hh_df$ShrVehDvmt
Hh_df$OneVeh <- as.numeric(Hh_df$NumVeh == 1)
Hh_df$VehPerPop <- Hh_df$NumVeh / Hh_df$Hhsize
Hh_df$OnePerHh <- as.numeric(Hh_df$Hhsize == 1)
#Load NHTS tour data
HhTours_df <- VE2001NHTS::HhTours_df
HhTours_dt <- data.table(HhTours_df[,c("Houseid", "Distance", "Persons")])
rm(HhTours_df)
#Sum up SOV tour distances within 20 miles by household
SovTour_dt <-
  HhTours_dt[Distance <= 20 & Persons == 1, sum(Distance), by = Houseid]
Hh_df$Sov20MiDvmt <-
  SovTour_dt$V1[match(Hh_df$Houseid, SovTour_dt$Houseid)]
Hh_df$Sov20MiDvmt[is.na(Hh_df$Sov20MiDvmt)] <- 0
rm(SovTour_dt)
rm(HhTours_dt)
#Remove incomplete cases with respect to some predictor variables
Vars_ <-
  c("Dvmt", "Hbppopdn", "NumVeh", "OneVeh", "UrbanDev", "RuralDev", "Age0to14",
    "Hhsize")
Hh_df <- Hh_df[complete.cases(Hh_df[,Vars_]),]
rm(Vars_)
#Only keep cases for households having vehicles and some household DVMT
Hh_df <- Hh_df[Hh_df$NumVeh > 0 & Hh_df$Dvmt > 0,]
#Calculate SOV DVMT proportions
Hh_df$Sov20DvmtProp <- Hh_df$Sov20MiDvmt / Hh_df$Dvmt
Hh_df <- Hh_df[Hh_df$Sov20DvmtProp <= 1,]

#Define functions used in estimations
#------------------------------------
#Function to make a model formula
makeFormula <-
  function(DepVar, IndepVars_) {
    FormulaString <-
      paste(DepVar, "~", paste(IndepVars_, collapse = "+"))
    as.formula(FormulaString)
  }
#Function to find a power transform that minimizes skewness of distribution
findPower <- function(Dvmt_) {
  skewness <- function (x, na.rm = FALSE, type = 3)
  {
    if (any(ina <- is.na(x))) {
      if (na.rm)
        x <- x[!ina]
      else return(NA)
    }
    if (!(type %in% (1:3)))
      stop("Invalid 'type' argument.")
    n <- length(x)
    x <- x - mean(x)
    y <- sqrt(n) * sum(x^3)/(sum(x^2)^(3/2))
    if (type == 2) {
      if (n < 3)
        stop("Need at least 3 complete observations.")
      y <- y * sqrt(n * (n - 1))/(n - 2)
    }
    else if (type == 3)
      y <- y * ((1 - 1/n))^(3/2)
    y
  }
  PowSeq_ <- seq(0.01, 0.99, 0.01)
  Dvmt_ <- Dvmt_[Dvmt_ != 0]
  Skew_ <- sapply(PowSeq_, function(x) skewness(Dvmt_ ^ x))
  PowSeq_[which(abs(Skew_) == min(abs(Skew_)))]
}
#Function to calculate dispersion factor to match observed variation
calcDispersonFactor <- function(ObsVals_, EstVals_) {
  ObsSd <- sd(ObsVals_)
  EstSd <- sd(EstVals_)
  N <- length(ObsVals_)
  testSd <- function(SD) {
    RevEstVals_ <- EstVals_ + rnorm(N, 0, SD)
    ObsSd - sd(RevEstVals_)
  }
  binarySearch(testSd, SearchRange_ = sort(c(ObsSd, EstSd)))
}
#Simulate household DVMT
simulatePropSovDvmt <- function(PowPropSov_, ZeroSovProb_, AllSovProb_, SD, Pow) {
  N <- length(PowPropSov_)
  ZeroFlag_ <- as.numeric(runif(N) < ZeroSovProb_)
  AllFlag_ <- as.numeric(runif(N) < AllSovProb_)
  AdjPowPropSov_ <- PowPropSov_ + rnorm(N, 0, SD)
  while (any(AdjPowPropSov_ < 0 | AdjPowPropSov_ > 1)) {
    IsLTZero_ <- AdjPowPropSov_ < 0
    IsGTOne_ <- AdjPowPropSov_ > 1
    AdjPowPropSov_[IsLTZero_] <-
      PowPropSov_[IsLTZero_] + rnorm(sum(IsLTZero_), 0, SD)
    AdjPowPropSov_[IsGTOne_] <-
      PowPropSov_[IsGTOne_] + rnorm(sum(IsGTOne_), 0, SD)
  }
  PropSov_ <- PowPropSov_ ^ (1 / Pow)
  PropSov_[ZeroFlag_ & !AllFlag_] <- 0
  PropSov_[AllFlag_] <- 1
  PropSov_
}

#Estimate model of probability of zero SOV DVMT on the survey
#------------------------------------------------------------
#Create model estimation dataset
IndepVars_ <-
  c("Hbppopdn", "NumVeh", "OneVeh", "Age0to14", "RuralDev", "VehPerPop", "OnePerHh")
TestHh_df <- Hh_df[,IndepVars_]
TestHh_df$ZeroSov <- as.numeric(Hh_df$Sov20DvmtProp == 0)
#Estimate binomial logit model
ZeroSov_GLM <-
    glm(makeFormula("ZeroSov", IndepVars_), family = binomial, data = TestHh_df)
# summary(ZeroSov_GLM)
#Get the predicted probabilities
ZeroSovProb_ <- predict(ZeroSov_GLM, type = "response")
#Clean up
rm(IndepVars_, TestHh_df, ZeroSov_GLM)

#Estimate models of all SOV DVMT
#-------------------------------
#Create model estimation dataset
IndepVars_ <-
  c("NumVeh", "Age0to14", "RuralDev", "VehPerPop", "OnePerHh")
TestHh_df <- Hh_df[,IndepVars_]
TestHh_df$AllSov <- as.numeric(Hh_df$Sov20DvmtProp == 1)
#Estimate binomial logit model
AllSov_GLM <-
  glm(makeFormula("AllSov", IndepVars_), family = binomial, data = TestHh_df)
# summary(AllSov_GLM)
#Get the predicted probabilities
AllSovProb_ <- predict(AllSov_GLM, type = "response")
#Clean up
rm(IndepVars_, TestHh_df, AllSov_GLM)

#Estimate model of SOV DVMT proportion when some but not all SOV DVMT
#--------------------------------------------------------------------
#Create model estimation dataset
IndepVars_ <-
  c("NumVeh", "Age0to14", "RuralDev", "VehPerPop", "OnePerHh")
TestHh_df <- Hh_df[,IndepVars_]
TestHh_df$PropSov <- Hh_df$Sov20DvmtProp
TestHh_df <- TestHh_df[!(round(TestHh_df$PropSov, 3) %in% c(0,1)),]
#Normalize dependent variable
Pow <- findPower(TestHh_df$PropSov)
TestHh_df$PowPropSov <- TestHh_df$PropSov ^ Pow
#Estimate binomial logit model for power transformed dependent variable
PropSov_LM <-
  lm(makeFormula("PowPropSov", IndepVars_), data = TestHh_df)
# summary(PropSov_LM)
#Calculate dispersion factor to match observed variation
# plot(density(TestHh_df$PowPropSov))
# lines(density(predict(PropSov_LM)), col = "red")
SD <- calcDispersonFactor(TestHh_df$PowPropSov, predict(PropSov_LM))
# lines(density(predict(PropSov_LM) + rnorm(nrow(TestHh_df), 0, SD)), col = "orange")
#Predict values for entire dataset
IndepVars_ <-
  c("NumVeh", "Age0to14", "RuralDev", "VehPerPop", "OnePerHh")
TestHh_df <- Hh_df[,IndepVars_]
PowPropSov_ <- predict(PropSov_LM, newdata = TestHh_df)
#Clean up
rm(IndepVars_, TestHh_df, PropSov_LM)

#Simulate SOV DVMT proportion 1000 times & compute mean value by household
#-------------------------------------------------------------------------
#Set up simulation
IndepVars_ <-
  c("NumVeh", "Age0to14", "RuralDev", "VehPerPop", "OnePerHh")
TestHh_df <- Hh_df[,IndepVars_]
HhSovProp_HhX <- matrix(0, nrow = nrow(TestHh_df), ncol = 1000)
#Run simulation
for (i in 1:1000) {
  HhSovProp_HhX[,i] <-
    simulatePropSovDvmt(PowPropSov_, ZeroSovProb_, AllSovProb_, SD, Pow)
}
#Calculate mean value
MeanSovProp_Hh <- rowMeans(HhSovProp_HhX)
#Clean up
rm(IndepVars_, TestHh_df, HhSovProp_HhX, PowPropSov_, ZeroSovProb_, AllSovProb_,
   SD, i)

#Estimate linear model of mean SOV DVMT proportion
#-------------------------------------------------
#Create model estimation dataset
IndepVars_ <-
  c("Hbppopdn", "NumVeh", "OneVeh", "Age0to14", "RuralDev", "OnePerHh")
TestHh_df <- Hh_df[,IndepVars_]
TestHh_df$PowPropSov <- MeanSovProp_Hh ^ Pow
#Estimate the model
PropSov_LM <-
  lm(makeFormula("PowPropSov", IndepVars_), data = TestHh_df)
# summary(PropSov_LM)
# PredSovProp_Hh <- predict(PropSov_LM) ^ (1 / Pow)
# MeanIs1_ <- MeanSovProp_Hh == 1
# plot(density(MeanSovProp_Hh[!MeanIs1_]))
# lines(density(PredSovProp_Hh[!MeanIs1_]), col = "red")

#Save the models
#---------------
#Make a list which contains the power transform and the model
SovModel_ls <-
  list(
    Pow = Pow,
    Prop = makeModelFormulaString(PropSov_LM)
  )
#Save the model
#' Model of proportion of household average DVMT in single-occupant vehicle
#' tours having round-trip distances of 20 miles or less.
#'
#' A list having two components: Pow - the power transform of the SOV DVMT
#' proportion, and Prop - a string representation of the model formula.
#'
#' @format A list having two components:
#' Pow: the power transform of the SOV DVMT proportion;
#' Prop: a string representation of the model formula;
#' @source DivertSovTravel.R
"SovModel_ls"
devtools::use_data(SovModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
DivertSovTravelSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = item(
    item(
      NAME = "PropSovDvmtDiverted",
      FILE = "azone_prop_sov_dvmt_diverted.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "Proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Goals for the proportion of household DVMT in single occupant vehicle tours with round-trip distances of 20 miles or less be diverted to bicycling or other slow speed modes of travel"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = "PropSovDvmtDiverted",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "Proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D1B",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/SQMI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Age0to14",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BikeTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "WalkTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TransitTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "PropDvmtDiverted",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Proportion of household DVMT diverted to bicycling, electric bikes, or other 'low-speed' travel modes"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for DivertSovTravel module
#'
#' A list containing specifications for the DivertSovTravel module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source DivertSovTravel.R script.
"DivertSovTravelSpecifications"
devtools::use_data(DivertSovTravelSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the proportion of SOV travel occurring in tours having
#round-trip distances of 20 miles or less to meet diversion goals input by the
#model user. The function calculates the total amount of diversion for the
#Azone, the amount of SOV travel within the 20 mile tour distance range for each
#household, and the allocation of the reduction to households. The reduction is
#allocated to households as a function of their SOV travel and their predicted
#alternative modes tripmaking.

#Main module function that calculates proportion DVMT diverted
#-------------------------------------------------------------
#' Assign household DVMT to household vehicles.
#'
#' \code{DivertSovTravel} calculates the proportion of household DVMT that is
#' diverted to meet Azone SOV diversion goals.
#'
#' This function calculates the proportion of household DVMT that is diverted to
#' meet Azone SOV diversion goals. It calculates the amount of SOV travel
#' of each households that is in tours having round-trip distances of 20 miles
#' or less. Based on that calculation, it calculates the total DVMT to be
#' diverted. It then allocates the DVMT to be diverted as a function of the
#' household's alternative mode trip making, assuming that households that are
#' predicted to make more alternative mode trips would be more likely to make
#' additional diversions. Finally, it calculates the proportion of DVMT diverted
#' for each household.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
DivertSovTravel <- function(L) {
  #Set up household variables to apply SOV model
  #---------------------------------------------
  Hh_df <- data.frame(L$Year$Household, stringsAsFactors = FALSE)
  Hh_df$Hbppopdn <-
    L$Year$Bzone$D1B[match(Hh_df$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$NumVeh <- Hh_df$Vehicles
  Hh_df$RuralDev <- as.numeric(Hh_df$DevType == "Rural")
  Hh_df$OneVeh <- as.numeric(Hh_df$Vehicles == 1)
  Hh_df$OnePerHh <- as.numeric(Hh_df$HhSize == 1)
  Hh_df$Intercept <- 1

  #Calculate proportions of household DVMT in SOV tours
  #------------------------------------------
  PowSovProp_ <- eval(parse(text = SovModel_ls$Prop), envir = Hh_df)
  SovProp_ <- PowSovProp_ ^ (1 / SovModel_ls$Pow)

  #Calculate total DVMT to be diverted
  #-----------------------------------
  TotDvmt <- sum(L$Year$Household$Dvmt)
  TotSovDvmt <- sum(L$Year$Household$Dvmt * SovProp_)
  SovDiversionProp <- L$Year$Azone$PropSovDvmtDiverted
  TotSovDvmtDiverted <- TotSovDvmt * SovDiversionProp

  #Allocate the DVMT diversion to households
  #-----------------------------------------
  #Calculate diversion and alt trips values to use as allocation factors
  SovDvmt_ <- L$Year$Household$Dvmt * SovProp_
  AltTrips_ <- with(L$Year$Household, WalkTrips + BikeTrips + TransitTrips)
  #Define function to check if AltTrip scaling keeps max diversion in bounds
  checkMaxDiversion <- function(B) {
    U_ <-  log(SovDvmt_ / mean(SovDvmt_)) + B * log(AltTrips_ / mean(AltTrips_))
    SovDvmtDiverted_ <- TotSovDvmtDiverted * exp(U_) / sum(exp(U_))
    SovDiversionProp_ <- SovDvmtDiverted_ / SovDvmt_
    MaxDiversionProp - max(SovDiversionProp_)
  }
  #Set maximum bounds halfway between average and 1 and calculate AltTrip scaling
  MaxDiversionProp <- (SovDiversionProp + 1) / 2
  B <- binarySearch(checkMaxDiversion, c(0, 1), DoWtAve = TRUE, Tolerance = 0.01)
  #Allocate SOV DVMT diversion to households
  U_ <-  log(SovDvmt_ / mean(SovDvmt_)) + B * log(AltTrips_ / mean(AltTrips_))
  SovDvmtDiverted_ <- TotSovDvmtDiverted * exp(U_) / sum(exp(U_))
  #Calculate the proportion of household DVMT that is diverted
  PropDvmtDiverted_ <- SovDvmtDiverted_ / L$Year$Household$Dvmt

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(PropDvmtDiverted = PropDvmtDiverted_)
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
#   ModuleName = "DivertSovTravel",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- DivertSovTravel(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "DivertSovTravel",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
