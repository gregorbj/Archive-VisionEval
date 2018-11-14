#=================
#DivertSovTravel.R
#=================
#
#<doc>
#
## DivertSovTravel Module
#### November 13, 2018
#
#This module reduces household single-occupant vehicle (SOV) travel to achieve goals that are inputs to the model. The purpose of this module is to enable users to do 'what if' analysis of the potential of light-weight vehicles (e.g. bicycles, electric bikes, electric scooters) and infrastructure to support their use to reduce SOV travel. The user inputs a goal for diverting a portion of SOV travel within a 20-mile tour distance (round trip distance). The model predicts the proportion of each household's DVMT that occurs in SOV tours having round trip distances of 20 miles or less. It then reduces SOV travel to achieve the overall goal. The reductions are allocated to households as a function of their likelihood to travel by non-automotive modes as calculated by the CalculateAltModeTrips module. The proportions of diverted DVMT are saved and used by the ApplyDvmtReductions module to calculate reductions in household DVMT due to SOV diversion and travel demand management. The module also calculates the number trips per miles of the diverted DVMT. This is used to calculate the added non-auto trips due to the diversion of SOV travel to bikes, electric bikes, scooters and other light-weight vehicles.
#
### Model Parameter Estimation
#
#This module estimates a model which predicts the proportion of household travel occurring in single-occupant vehicle tours that have round trip distances of 20 miles or less. The model is estimated in 2 stages. In the first stage, models are estimated to predict the likelihood that a household had no qualifying SOV tours on the survey day, and to predict the amount of DVMT in qualifying tours if there were one or more qualifying tours on the survey day. These two models are then applied stochastically to the survey households 1000 times and the results averaged to arrive at an estimate of the average DVMT in qualifying SOV tours for each household. The average household DVMT model from the CalculateHouseholDvmt module is also run and the ratio of estimated average DVMT in qualifying SOV tours is divided by the estimated average DVMT to arrive at an estimate of the average proportion of household DVMT that is in qualifying tours. In the second step, a linear model of the log odds corresponding to the proportions is estimated. In addition, the median trip length in qualifying tours is calculated.
#
#Two data frames from the VE2001NHTS package are used to develop these models. The Hh_df data frame includes attributes of households used as dependent variables in the models. The HhTours_df data frame is used to identify qualifying tours. The miles in qualifying tours is summed by household and added to the Hh_df data frame. The average household DVMT model from the CalculateHouseholDvmt model is run to estimate the average DVMT of each survey household. Households having incomplete data (mostly because of missing income data) and zero vehicle households are removed from the dataset resulting in 51,924 household records.
#
#In the first stage of model development, a binomial logit model is estimated to predict the likelihood that a household had any qualifying SOV tours on the survey day. A linear model is also estimated which predicts the miles of travel in qualifying SOV tours if any. The summary statics for the estimation of the binomial logit model follows. The model accounts for a small proportion of the variability in the data, but all of the independent variables are highly significant. The number of children in the household and if the number of vehicles is less than the number of drivers increase the probability that the household had no qualifying SOV travel. The population density of the neighborhood (block group), the number of drivers, and if the household lives in a single-family dwelling decreases the probability that the household had qualifying SOV travel. These effects are sensible.
#
#<txt:SovModel_ls$ZeroSovModel>
#
#The summary statistics for the linear model of qualifying SOV travel if any is shown below. In this model a power transform of the qualifying SOV DVMT is the dependent variable. Power transformation is done to help linearize the relationship since the qualifying SOV DVMT is highly skewed with a long right hand tail. The power transformation is calculated to minimize skewness of the distribution. As with the previous model, this one accounts for a small portion of the observed variability but the independent variables are highly significant. The amount of qualifying SOV DVMT increases with the income of the household, the number of drivers, and the household DVMT. The amount of qualifying SOV DVMT is decreased by the density of the neighborhood, the number of children in the household, and if the number of vehicles is less than the number of drivers.
#
#<txt:SovModel_ls$SovDvmtModel>
#
#The two models were applied jointly (using the estimation dataset) in a stochastic manner 1000 times to simulate that many travel days. In the case of the binomial logit model which predicts the likelihood of no qualifying SOV travel, the predicted probability is compared with a random draw from a uniform distribution in the range 0 to 1 to determine whether the household has any qualifying SOV travel. In the case of the linear model which predicts the amount of qualifying SOV travel, the model predictions are used to estimate the mean of a distribution where the standard deviation of the distribution that is estimated so that the standard deviation of the resulting estimates equals the standard deviation of the observed estimates. With each application of the model, a random value is drawn from a normal distribution described by the modeled mean and the estimated standard deviation. The mean qualifying SOV DVMT for each household is calculated from the results of the 1000 simulations.
#
#The estimated average ratio of qualifying SOV DVMT to household average DVMT is calculated from the simulated results and the estimate of average DVMT calculated from applying the average DVMT model from the CalculateHouseholdDvmt module. A linear model of the estimated ratio is estimate. In this model, the dependent variable is the logit of the ratio (log of the odds ratio) keeps the predicted ratios in the range of 0 to 1 and does a better job of linearizing the relationship. The summary statistics for this model follow. The model explains almost all of the variability and all of the independent variables are highly significant. This is to be expected since the model estimates relationships derived from the two previous models.
#
#<txt:SovModel_ls$SovPropModel$Summary>
#
#The signs of the coefficients are sensible. The ratio of the average qualifying SOV DVMT of the household to the average DVMT of the household increases with:
#
#* Income - because higher income enables more discretionary travel and freedom to travel alone;
#
#* Drivers - because having more drivers increases the probability of solo travel and decreases the need to travel as a passenger;
#
#* Density - because higher density neighborhoods have more activity in close proximity and decrease the need for trip linking of multiple household members; and,
#
#* Single-family dwelling - because living in a single-family dwelling makes it easier to make spur-of-the-moment SOV trips because the vehicle is more accessible and there are usually no worries about finding a good parking space when arriving back home.
#
#The ratio of qualifying SOV DVMT decreases with increasing:
#
#* Number of children - because younger children often need to be taken along to shuttle them to activities or to maintain supervision while running errands;
#
#* Number of vehicles is less than the number of drivers - because when not each driver has a car available it is more likely that they will need to travel together; and,
#
#* Household DVMT - because travel to work establishes a base level of vehicle travel and typically has lower vehicle occupancy than travel for other purposes. Travel beyond work travel is therefore less likely to be SOV travel than work travel and therefore will reduce the SOV DVMT ratio.
#
#Finally, the module calculates the median trip length for SOV tours of 20 miles of less in length from the household tour data. The distribution of trip lengths is shown in the following figure.
#
#<fig:sov_trip_length_dist.png>
#
#The inverse of the median trip length, miles per trip, is saved for use in calculating the increase in bike trips due to the diversion of SOV trips.
#
### How the Module Works
#
#This function calculates the proportional reduction in the DVMT of individual households to meet the user-supplied goal for diverting a proportion of travel in SOV tours 20 miles or less in length to bikes, electric bikes, scooters or other similar modes. The user supplies the diversion goal for each Azone and model year. The following procedural steps are followed to complete the calculation:
#
#* The SOV proportions model described is applied to calculate the proportion of the DVMT of each household that is in qualifying SOV tours (i.e. having lengths of 20 miles or less);
#
#* The total diversion of DVMT in qualifying SOV tours for the Azone is calculated by:
#
#  * Calculating the qualifying SOV tour DVMT of each household by multiplying the modeled proportion of DVMT in qualifying tours by the household DVMT;
#
#  * Summing the qualifying SOV tour DVMT of households in the Azone and multiplying by the diversion goal for the Azone;
#
#* The total DVMT diverted is allocated to households in the Azone as a function of their relative amounts of qualifying SOV travel and alternative modes tripmaking. This is implemented in the following steps:
#
#  * A utility function is defined as follows:
#
#     `U = log(SovDvmt / mean(SovDvmt)) + B * log(AltTrips / mean(AltTrips))`
#
#     Where:
#
#     `SovDvmt` and `mean(SovDvmt)` are the household's qualifying SOV DVMT and the population mean respectively,
#
#     `AltTrips` and `mean(AltTrips)` are the number of the household's alternative mode trips and the population mean respectively, and
#
#     `B` is a parameter that is estimated to keep the maximum proportion of SOV diversion for all households within bounds as explained below.
#
#  * The proportion of total diverted DVMT allocated to each household is `exp(U) / sum(exp(U))` where `exp(U)` is the exponentiated value of the utility for the household and `sum(exp(U))` is the sum of the exponentiated values for all households.
#
#  * The value of `B` is solved such that the maximum proportional diversion for any household is midway between the objective of the Azone and 1. For example, Azone objective is 0.2, the maximum diversion would be 0.6. The value is solved iteratively using a binary search algorithm.
#
#* The DVMT diversion allocated to each household is divided by the average DVMT of each household to calculate the proportion of household DVMT that is diverted. This is the output of the module that gets saved to the datastore.
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(data.table)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#--------------------------------------------
#Set up data and functions to estimate models
#--------------------------------------------
#' @import data.table
#' @importFrom stats as.formula rnorm runif sd ppois quantile

#Initialize list to hold model and model documentation
#-----------------------------------------------------
SovModel_ls <- list(
)

#Load household data and calculate added variables
#-------------------------------------------------
#Load NHTS household data
Hh_df <- VE2001NHTS::Hh_df
#Add variables to Hh_df
Hh_df$Density <- Hh_df$Hbppopdn
Hh_df$LogDensity <- log(Hh_df$Density)
Hh_df$HhSize <- Hh_df$Hhsize
Hh_df$OnePerHh <- as.numeric(Hh_df$Hhsize == 1)
Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
Hh_df$ZeroVeh <- as.numeric(Hh_df$NumVeh == 0)
Hh_df$OneVeh <- as.numeric(Hh_df$NumVeh == 1)
Hh_df$HouseType <- "MF"
Hh_df$HouseType[Hh_df$Hometype %in% c("Single Family", "Mobile Home")] <- "SF"
Hh_df$HouseType[Hh_df$Hometype == "Dorm"] <- "GQ"
Hh_df$IsSF <- as.numeric(Hh_df$HouseType == "SF")
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$IsUrbanMixNbrhd <- Hh_df$UrbanDev
Hh_df$Vehicles <- Hh_df$NumVeh
Hh_df$VehPerDvr <- Hh_df$Vehicles / Hh_df$Drvrcnt
Hh_df$NumChild <- Hh_df$Age0to14 + Hh_df$Age15to19
Hh_df$NumAdult <- Hh_df$HhSize - Hh_df$NumChild
Hh_df$IsLowIncome <- as.numeric(Hh_df$Income <= 20000)
Hh_df$NumVehGtNumDvr <- as.numeric(Hh_df$Vehicles > Hh_df$Drvrcnt)
Hh_df$NumVehEqNumDvr <- as.numeric(Hh_df$Vehicles == Hh_df$Drvrcnt)
Hh_df$NumVehLtNumDvr <- as.numeric(Hh_df$Vehicles < Hh_df$Drvrcnt)
Hh_df$PrsnPerVeh <- Hh_df$Hhsize / Hh_df$Vehicles
Hh_df$VehPerPop <- Hh_df$NumVeh / Hh_df$Hhsize
Hh_df$Drivers <- Hh_df$Drvrcnt
Hh_df$FwyLaneMiPC <- Hh_df$FwyLnMiPC / 1000
Hh_df$IsMetro <- Hh_df$Msacat %in% c("1", "2")

#Apply average DVMT model to calculate average household DVMT
#------------------------------------------------------------
#Get DVMT model
load("data/DvmtModel_ls.rda")
#Prepare variables for application of model
Hh_df$Intercept <- 1
#Apply the model
IsMetro <- Hh_df$IsMetro
Hh_df$Dvmt <- NA
Hh_df$Dvmt[IsMetro] <-
  as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                 envir = Hh_df[IsMetro,])) ^ (1 / DvmtModel_ls$Metro$Pow)
Hh_df$Dvmt[!IsMetro] <-
  as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                 envir = Hh_df[!IsMetro,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)
Hh_df$LogDvmt <- log(Hh_df$Dvmt)

#Reduce size of dataset and remove incomplete cases
#--------------------------------------------------
Keep_ <- c("Houseid", "Dvmt", "Density", "LogDensity", "HhSize", "Age0to14",
           "Age15to19", "OnePerHh", "DrvAgePop", "IsSF", "Income", "LogIncome",
           "Workers", "IsUrbanMixNbrhd", "Vehicles", "VehPerDvr", "NumChild",
           "NumAdult", "IsLowIncome", "OneVeh", "NumVehGtNumDvr", "HouseType",
           "NumVehEqNumDvr", "NumVehLtNumDvr", "PrsnPerVeh", "VehPerPop",
           "Drivers", "IsMetro", "LogDvmt")
Include_ <- c("FwyLaneMiPC", "BusEqRevMiPC")
Hh_df <- Hh_df[, c(Keep_, Include_)]
Hh_df <- Hh_df[complete.cases(Hh_df[, Keep_]),]
#Only keep cases for households having vehicles
Hh_df <- Hh_df[Hh_df$Vehicles > 0,]
#Clean up
rm(DvmtModel_ls, Include_, IsMetro, Keep_)

#Calculate mileage in SOV tours having lengths 20 miles or shorter
#-----------------------------------------------------------------
#Load NHTS tour data
HhTours_df <- VE2001NHTS::HhTours_df
HhTours_dt <- data.table(HhTours_df[,c("Houseid", "Distance", "Persons", "Trips")])
rm(HhTours_df)
#Select SOV tours with distances of 20 miles or less
SovTour_dt <- HhTours_dt[Distance <= 20 & Persons == 1,]
#Calculate median trip length in SOV tours 20 miles or less
SovTripLength_ <- SovTour_dt$Distance / SovTour_dt$Trips
SovTripLength <- round(median(SovTripLength_), 2)
SovModel_ls$TripsPerMile <- 1 / SovTripLength
png("data/sov_trip_length_dist.png", width = 480, height = 480)
plot(density(SovTripLength_, width = 2),
     xlab = "Trip Length (miles)", ylab = "Probability Density",
     main = "Trip Length Distribution of SOV Tours <= 20 Miles")
abline(v = SovTripLength, lty = 2)
text(SovTripLength, 0.2, pos = 4,
     labels = paste("Median =", round(SovTripLength, 1), "miles"))
dev.off()
#Sum up SOV tour distances within 20 miles by household
SovTourByHh_dt <- SovTour_dt[, sum(Distance), by = Houseid]
Hh_df$Sov20MiDvmt <- SovTourByHh_dt$V1[match(Hh_df$Houseid, SovTourByHh_dt$Houseid)]
Hh_df$Sov20MiDvmt[is.na(Hh_df$Sov20MiDvmt)] <- 0
Hh_df$ZeroSov <- as.numeric(Hh_df$Sov20MiDvmt == 0)
#Clean up
rm(HhTours_dt, SovTour_dt, SovTourByHh_dt, SovTripLength_, SovTripLength)

#------------------------------------
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
findPower <- function(X_) {
  X_ <- X_[!is.na(X_)]
  testPow <- function(Pow) {
    PowX_ <- X_ ^ Pow
    3 * (mean(PowX_) - median(PowX_)) / sd(PowX_)
  }
  binarySearch(testPow, SearchRange_ = c(0.01, 0.99))
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

#--------------------------------------------------------------
#Estimate model of DVMT in SOV tours 20 miles or less in length
#--------------------------------------------------------------

#Estimate model of probability of zero SovDvmtLe20Mi on the survey
#-----------------------------------------------------------------
#Create model estimation dataset
IndepVars_ <- c("LogDensity", "IsSF", "Drivers", "NumChild", "NumVehLtNumDvr")
TestHh_df <- Hh_df[,c("ZeroSov", IndepVars_)]
#Estimate binomial logit model
ZeroSov_GLM <-
  glm(makeFormula("ZeroSov", IndepVars_), family = binomial, data = TestHh_df)
# summary(ZeroSov_GLM)
# cor(TestHh_df[,IndepVars_])
#Save the model summary
SovModel_ls$ZeroSovModel <- capture.output(summary(ZeroSov_GLM))
#Get the predicted probabilities
ZeroSovProb_ <- predict(ZeroSov_GLM, type = "response")
#Clean up
rm(IndepVars_, TestHh_df, ZeroSov_GLM)

#Estimate model of SovDvmtLe20Mi when not equal to 0
#---------------------------------------------------
#Create model estimation dataset
IndepVars_ <- c("LogDensity", "IsSF", "LogIncome", "Drivers", "NumChild",
                "NumVehLtNumDvr", "LogDvmt")
TestHh_df <- Hh_df[, IndepVars_]
TestHh_df$SovDvmt <- Hh_df$Sov20MiDvmt
TestHh_df <- TestHh_df[TestHh_df$SovDvmt != 0,]
#Normalize dependent variable
Pow <- findPower(TestHh_df$SovDvmt)
TestHh_df$PowSovDvmt <- TestHh_df$SovDvmt ^ Pow
#Estimate linear model for power transformed dependent variable
SovDvmt_LM <-
  lm(PowSovDvmt ~ LogDensity +
       LogIncome +
       Drivers +
       NumChild +
       NumVehLtNumDvr +
       LogDvmt,
     data = TestHh_df)
# summary(SovDvmt_LM)
#Save the model summary
SovModel_ls$SovDvmtModel <- capture.output(summary(SovDvmt_LM))
#Calculate dispersion factor to match observed variation
SD <- calcDispersonFactor(TestHh_df$PowSovDvmt, predict(SovDvmt_LM))
# lines(density(predict(PropSov_LM) + rnorm(nrow(TestHh_df), 0, SD)), col = "orange")
#Predict values for entire dataset
TestHh_df <- Hh_df[,IndepVars_]
PowSovDvmt_ <- predict(SovDvmt_LM, newdata = TestHh_df)
#Clean up
rm(IndepVars_, TestHh_df, SovDvmt_LM)

#Simulate SovDvmtLe20Mi 1000 times & compute mean value by household
#-------------------------------------------------------------------
#Define function
simulateSovDvmt <- function(PowSovDvmt_, ZeroSovProb_, SD, Pow) {
  N <- length(PowSovDvmt_)
  IsZero <- runif(N) < ZeroSovProb_
  AdjPowSovDvmt_ <- PowSovDvmt_ + rnorm(N, 0, SD)
  AdjPowSovDvmt_[AdjPowSovDvmt_ < 0] <- 0
  SovDvmt_ <- AdjPowSovDvmt_ ^ (1 / Pow)
  SovDvmt_[IsZero] <- 0
  SovDvmt_
}
#Set up simulation
HhSovDvmt_HhX <- matrix(0, nrow = length(PowSovDvmt_), ncol = 1000)
#Run simulation
for (i in 1:1000) {
  HhSovDvmt_HhX[,i] <-
    simulateSovDvmt(PowSovDvmt_, ZeroSovProb_, SD, Pow)
}
#Calculate mean value
MeanSovDvmt_Hh <- rowMeans(HhSovDvmt_HhX)
#Clean up
rm(HhSovDvmt_HhX, i, Pow, PowSovDvmt_, SD, ZeroSovProb_, simulateSovDvmt,
   findPower, calcDispersonFactor)

#-----------------------------------------------
#Model ratio of average SOV DVMT to average DVMT
#-----------------------------------------------
#A model is developed to predict the ratio of average SOV DVMT in tours less
#than or equal to 20 miles in length and the average DVMT of the household. The
#ratio in the estimation dataset is modeled values of mean DVMT and mean
#Sov20MiDvmt. The ratio is converted to the equivalent logit form. A linear
#model of the logit is estimated.

#Calculate the ratio, constrain maximum values, calculate logit transform
#------------------------------------------------------------------------
#Calculate the ratio
Hh_df$SovDvmtRatio <- MeanSovDvmt_Hh / Hh_df$Dvmt
#Cap at the 99.9th percentile
MaxRatio <- quantile(Hh_df$SovDvmtRatio, probs = 0.999)
Hh_df$SovDvmtRatio[Hh_df$SovDvmtRatio > MaxRatio] <- MaxRatio
rm(MaxRatio)

#Define a function to estimate the SOV proportion
#------------------------------------------------
Data_df <- Hh_df
estimateSovPropModel <- function(Data_df, StartTerms_) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <- function(In_df) {
    Out_df <- In_df
    Out_df$LogDensity <- log(In_df$Density)
    Out_df$LogIncome <- log(In_df$Income)
    Out_df$LogDvmt <- log(In_df$Dvmt)
    Out_df$NumChild <- In_df$Age0to14 + In_df$Age15to19
    Out_df$NumVehLtNumDvr <- as.numeric(In_df$Vehicles < In_df$Drivers)
    Out_df$IsSF <- as.numeric(In_df$HouseType == "SF")
    Out_df$Intercept <- 1
    Out_df
  }
  #Prepare estimation data
  EstData_df <- prepIndepVar(Data_df)
  EstData_df$SovLogOdds <-  with(Data_df, log(SovDvmtRatio / (1 - SovDvmtRatio)))
  #Define function to make a model formula
  makeFormula <-
    function(Terms_) {
      FormulaString <-
        paste("SovLogOdds ~ ", paste(Terms_, collapse = "+"))
      as.formula(FormulaString)
    }
  SovModel_LM <-
    lm(makeFormula(StartTerms_), data = EstData_df)
  Coeff_mx <- coefficients(summary(SovModel_LM))
  EndTerms_ <- rownames(Coeff_mx)[Coeff_mx[, "Pr(>|t|)"] <= 0.05]
  if ("(Intercept)" %in% EndTerms_) {
    EndTerms_ <- EndTerms_[-grep("(Intercept)", EndTerms_)]
  }
  SovModel_LM <- lm(makeFormula(EndTerms_), data = EstData_df)
  #Define function to transform model outputs and establish income groups
  transformResult <- function(Result_) {
    Odds_ <- exp(Result_)
    Odds_ / (1 + Odds_)
  }
  #Return model
  list(
    Type = "linear",
    Formula = makeModelFormulaString(SovModel_LM),
    PrepFun = prepIndepVar,
    OutFun = transformResult,
    Summary = capture.output(summary(SovModel_LM))
  )
}

#Estimate the SOV DVMT proportions model
#---------------------------------------
#Define the start terms
StartTerms_ <-
  c("LogDensity",
    "IsSF",
    "LogIncome",
    "Drivers",
    "NumChild",
    "NumVehLtNumDvr",
    "LogDvmt",
    "LogDvmt:LogDensity")
#Estimate the model
SovModel_ls$SovPropModel <- estimateSovPropModel(Hh_df, StartTerms_)
rm(StartTerms_)
SovModel_ls$SovPropModel$Summary

#Save the model
#' Model of proportion of household average DVMT in single-occupant vehicle
#' tours having round-trip distances of 20 miles or less.
#'
#' A list having components to describe or document the model for predicting the
#' proportion of household DVMT in tours having round-trip distances of 20 miles
#' or less.
#'
#' @format A list having four components:
#' MedianTripLength: the median length in miles of trips in qualifying tours;
#' ZeroSovModel: summary statistics for the model to predict the likelihood that
#' a household has no qualifying tours on the survey day;
#' SovDvmtModel: summary statistics for the model to predict miles of travel in
#' qualifying tours if there is some travel in qualifying tours;
#' SovPropModel: a list that describes and documents a linear model for
#' predicting the proportion of average DVMT in qualifying tours.
#' @source DivertSovTravel.R
"SovModel_ls"
usethis::use_data(SovModel_ls, overwrite = TRUE)


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
      NAME = items(
        "Age0to14",
        "Age15to19"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Drivers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
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
usethis::use_data(DivertSovTravelSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

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
  Hh_df$Density <-
    L$Year$Bzone$D1B[match(Hh_df$Bzone, L$Year$Bzone$Bzone)]

  #Calculate proportions of household DVMT in SOV tours
  #------------------------------------------
  SovProp_ <- applyLinearModel(SovModel_ls$SovPropModel, Hh_df)

  #Calculate total DVMT to be diverted
  #-----------------------------------
  #TotDvmt <- sum(L$Year$Household$Dvmt)
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


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("DivertSovTravel")

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
