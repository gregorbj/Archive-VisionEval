#========================
#CalculateHouseholdDvmt.R
#========================
#This module models household average daily vehicle miles traveled as a function
#of household characteristics, vehicle ownership, and attributes of the
#neighborhood and metropolitan area where they reside.

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


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#The estimation of household DVMT models is a five-step process. In the first
#step, binomial logit models are estimated to predict the likelihood that there
#is household DVMT on the travel day. Separate models are estimated for
#metropolitan and non-metropolitan households. In the second step, linear
#regression models are estimated which predict power-transformed DVMT for
#households that have DVMT on the travel day. DVMT is power transformed to
#normalize. The linear models and power transformations are estimated separately
#for metropolitan and non-metropolitan households. In the third step, dispersion
#factors are estimated for adding variance to the linear models so that the
#variance of the results equals the observed variance. In the fourth step, the
#binomial and linear models are applied stochastically to simulate day-to-day
#variation in DVMT over 1000 days. These sumulated results are used to calculate
#the average DVMT of each household and DVMT by various percentiles. In the
#fifth step, linear models are estimated to predict average DVMT and several
#percentiles of DVMT using the simulated values. As with the other models,
#separate models are estimated for metropolitan and non-metropolitan households.

#Set up data and functions to estimate models
#--------------------------------------------
#Load NHTS household data
Hh_df <- VE2001NHTS::Hh_df
#Identify records used for estimating metropolitan area models
IsMetro_ <- Hh_df$Msacat %in% c("1", "2")
#Add variables to Hh_df
Hh_df$Dvmt <- Hh_df$PvtVehDvmt + Hh_df$ShrVehDvmt
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$ZeroVeh <- as.numeric(Hh_df$NumVeh == 0)
Hh_df$OneVeh <- as.numeric(Hh_df$NumVeh == 1)
Hh_df$DrvAgePop <- Hh_df$Hhsize - Hh_df$Age0to14
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$Drivers <- Hh_df$Drvrcnt

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
simulateDvmt <- function(PowDvmt_, ZeroDvmtProb_, SD, Pow) {
  N <- length(PowDvmt_)
  DvmtFlag_ <- as.numeric(runif(N) > ZeroDvmtProb_)
  PowDvmt_ <- PowDvmt_ + rnorm(length(PowDvmt_), 0, SD)
  PowDvmt_[PowDvmt_ < 0] <- 0
  Dvmt_ <- PowDvmt_ ^ (1 / Pow)
  DvmtFlag_ * Dvmt_
}

#Estimate binomial logit model for zero DVMT probability
#-------------------------------------------------------
#Estimate metropolitan model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "BusEqRevMiPC", "NumVeh",  "ZeroVeh",
    "UrbanDev", "Workers", "Age0to14")
TestHh_df <- Hh_df[IsMetro_, c("ZeroDvmt", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
MetroZeroDvmt_GLM <-
  glm(makeFormula("ZeroDvmt", IndepVars_), family=binomial, data = TestHh_df)
# summary(MetroZeroDvmt_GLM)
# anova(NonMetroZeroDvmt_GLM, test = "Chisq")
rm(IndepVars_, TestHh_df)
#Estimate nonmetropolitan model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "Workers",
    "Age0to14")
TestHh_df <- Hh_df[!IsMetro_, c("ZeroDvmt", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
NonMetroZeroDvmt_GLM <-
  glm(makeFormula("ZeroDvmt", IndepVars_), family=binomial, data = TestHh_df)
# summary(NonMetroZeroDvmt_GLM)
# anova(NonMetroZeroDvmt_GLM, test = "Chisq")
rm(IndepVars_, TestHh_df)

#Estimate linear model of DVMT for households that have DVMT
#-----------------------------------------------------------
#Find metropolitan and non-metropolitan DVMT power transforms
MetroPow <- findPower(Hh_df$Dvmt[IsMetro_])
NonMetroPow <- findPower(Hh_df$Dvmt[!IsMetro_])
#Estimate metropolitan model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "UrbanDev", "Age0to14")
TestHh_df <- Hh_df[IsMetro_ & Hh_df$ZeroDvmt == "N", c("Dvmt", IndepVars_)]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ MetroPow
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
MetroPowDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
# summary(MetroPowDvmt_LM)
rm(IndepVars_, TestHh_df)
#Estimate non-metropolitan model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "Age0to14")
TestHh_df <- Hh_df[!IsMetro_ & Hh_df$ZeroDvmt == "N", c("Dvmt", IndepVars_)]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ NonMetroPow
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
NonMetroPowDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
# summary(NonMetroPowDvmt_LM)
rm(IndepVars_, TestHh_df)

#Estimate disperson factor to match observed distribution of Metropolitan DVMT
#-----------------------------------------------------------------------------
#Prepare metropolitan household data frame
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "UrbanDev", "Age0to14")
TestHh_df <- Hh_df[IsMetro_ & Hh_df$ZeroDvmt == "N", c("Dvmt", IndepVars_)]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ MetroPow
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
#Calculate metropolitan observed and estimated power-transformed DVMT
ObsPowDvmt_ <- TestHh_df$Dvmt ^ MetroPow
EstPowDvmt_ <- predict(MetroPowDvmt_LM, newdata = TestHh_df)
#Calculate metropolitan dispersion factor
MetroSD <- calcDispersonFactor(ObsPowDvmt_, EstPowDvmt_)
#Test metropolitan dispersion factor
# RevEstPowDvmt_ <- EstPowDvmt_ + rnorm(length(EstPowDvmt_), 0, MetroSD)
# plot(density(ObsPowDvmt_))
# lines(density(RevEstPowDvmt_), col = "red")
# mean(TestHh_df$Dvmt)
# mean(RevEstPowDvmt_[RevEstPowDvmt_ > 0] ^ (1 / MetroPow))
rm(IndepVars_, TestHh_df, ObsPowDvmt_, EstPowDvmt_)
#Prepare nonmetropolitan household data frame
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "Age0to14")
TestHh_df <- Hh_df[!IsMetro_ & Hh_df$ZeroDvmt == "N", c("Dvmt", IndepVars_)]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ NonMetroPow
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
#Calculate metropolitan observed and estimated power-transformed DVMT
ObsPowDvmt_ <- TestHh_df$Dvmt ^ NonMetroPow
EstPowDvmt_ <- predict(NonMetroPowDvmt_LM, newdata = TestHh_df)
#Calculate metropolitan dispersion factor
NonMetroSD <- calcDispersonFactor(ObsPowDvmt_, EstPowDvmt_)
#Test metropolitan dispersion factor
# RevEstPowDvmt_ <- EstPowDvmt_ + rnorm(length(EstPowDvmt_), 0, NonMetroSD)
# plot(density(ObsPowDvmt_))
# lines(density(RevEstPowDvmt_), col = "red")
# mean(TestHh_df$Dvmt)
# mean(RevEstPowDvmt_[RevEstPowDvmt_ > 0] ^ (1 / NonMetroPow))
rm(IndepVars_, TestHh_df, ObsPowDvmt_, EstPowDvmt_)

#Simulate household DVMT over many days
#--------------------------------------
#Simulate 1000 days of DVMT for metropolitan households
Vars_ <-
  c("Houseid", "Drivers", "LogIncome", "Hbppopdn", "BusEqRevMiPC", "NumVeh",
    "ZeroVeh", "OneVeh", "Workers", "UrbanDev", "Age0to14", "Dvmt")
TestHh_df <- Hh_df[IsMetro_, Vars_]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
ZeroDvmtProb_ <-
  predict(MetroZeroDvmt_GLM, newdata = TestHh_df, type = "response")
EstPowDvmt_ <- predict(MetroPowDvmt_LM, newdata = TestHh_df)
MetroHhDvmt_HhX <- matrix(0, nrow = length(EstPowDvmt_), ncol = 1000)
rownames(MetroHhDvmt_HhX) <- TestHh_df$Houseid
for (i in 1:1000) {
  MetroHhDvmt_HhX[,i] <-
    simulateDvmt(EstPowDvmt_, ZeroDvmtProb_, MetroSD, MetroPow)
}
rm(Vars_, TestHh_df, ZeroDvmtProb_, EstPowDvmt_, i)
#Simulate 1000 days of DVMT for non-metropolitan households
Vars_ <-
  c("Houseid", "Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh",
    "OneVeh", "Workers", "Age0to14", "Dvmt")
TestHh_df <- Hh_df[!IsMetro_, Vars_]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
ZeroDvmtProb_ <-
  predict(NonMetroZeroDvmt_GLM, newdata = TestHh_df, type = "response")
EstPowDvmt_ <- predict(NonMetroPowDvmt_LM, newdata = TestHh_df)
NonMetroHhDvmt_HhX <- matrix(0, nrow = length(EstPowDvmt_), ncol = 1000)
rownames(NonMetroHhDvmt_HhX) <- TestHh_df$Houseid
for (i in 1:1000) {
  NonMetroHhDvmt_HhX[,i] <-
    simulateDvmt(EstPowDvmt_, ZeroDvmtProb_, NonMetroSD, NonMetroPow)
}
rm(Vars_, TestHh_df, ZeroDvmtProb_, EstPowDvmt_, i, MetroPowDvmt_LM,
   MetroSD, MetroZeroDvmt_GLM, NonMetroPowDvmt_LM, NonMetroSD,
   NonMetroZeroDvmt_GLM)

#Calculate mean and quantile values
#----------------------------------
QuantBreaks_ <- c(seq(0, 0.95, 0.05), 0.99)
MetroDvmtQuants_HhX <-
  t(apply(MetroHhDvmt_HhX, 1, function(x) {
    quantile(x, QuantBreaks_)
  }))
MetroAveDvmt_Hh <- rowMeans(MetroHhDvmt_HhX)
NonMetroDvmtQuants_HhX <-
  t(apply(NonMetroHhDvmt_HhX, 1, function(x) {
    quantile(x, QuantBreaks_)
  }))
NonMetroAveDvmt_Hh <- rowMeans(NonMetroHhDvmt_HhX)
rm(MetroHhDvmt_HhX, NonMetroHhDvmt_HhX)

#Estimate linear models of average DVMT
#--------------------------------------
#Estimate metropolitan household model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "UrbanDev", "Age0to14")
TestHh_df <- Hh_df[IsMetro_, c("Houseid", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
TestHh_df$Dvmt <- MetroAveDvmt_Hh[TestHh_df$Houseid]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ MetroPow
MetroAveDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
# summary(MetroAveDvmt_LM)
# plot(density(TestHh_df$PowDvmt))
# lines(density(predict(MetroAveDvmt_LM, newdata = TestHh_df)), col="red")
# plot(TestHh_df$PowDvmt, predict(MetroAveDvmt_LM, newdata = TestHh_df))
rm(IndepVars_, TestHh_df)
#Estimate non-metropolitan household model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "Age0to14")
TestHh_df <- Hh_df[!IsMetro_, c("Houseid", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
TestHh_df$Dvmt <- NonMetroAveDvmt_Hh[TestHh_df$Houseid]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ NonMetroPow
NonMetroAveDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
# summary(NonMetroAveDvmt_LM)
# plot(density(TestHh_df$PowDvmt))
# lines(density(predict(NonMetroAveDvmt_LM, newdata = TestHh_df)), col="red")
# plot(TestHh_df$PowDvmt, predict(NonMetroAveDvmt_LM, newdata = TestHh_df))
rm(IndepVars_, TestHh_df)

#Estimate linear models of DVMT percentiles as function of average DVMT
#----------------------------------------------------------------------
#Estimate metropolitan percentile DVMT models
TestHh_df <- data.frame(Dvmt = MetroAveDvmt_Hh)
TestHh_df$DvmtSq <- TestHh_df$Dvmt ^ 2
TestHh_df$DvmtCu <- TestHh_df$Dvmt ^ 3
MetroPctlMdl_ls <- list()
for (Pctl in as.character(c(seq(5, 95, 5), 99))) {
  TestHh_df[["PctlDvmt"]] <- MetroDvmtQuants_HhX[,paste0(Pctl, "%")]
  MetroPctlMdl_ls[[paste0("Pctl", Pctl)]] <-
    makeModelFormulaString(
      lm(PctlDvmt ~ Dvmt + DvmtSq + DvmtCu, data = TestHh_df))
}
rm(TestHh_df, Pctl)
#Estimate non-metropolitan percentile DVMT models
TestHh_df <- data.frame(Dvmt = NonMetroAveDvmt_Hh)
TestHh_df$DvmtSq <- TestHh_df$Dvmt ^ 2
TestHh_df$DvmtCu <- TestHh_df$Dvmt ^ 3
NonMetroPctlMdl_ls <- list()
for (Pctl in as.character(c(seq(5, 95, 5), 99))) {
  TestHh_df[["PctlDvmt"]] <- NonMetroDvmtQuants_HhX[,paste0(Pctl, "%")]
  NonMetroPctlMdl_ls[[paste0("Pctl", Pctl)]] <-
    makeModelFormulaString(
      lm(PctlDvmt ~ Dvmt + DvmtSq + DvmtCu, data = TestHh_df))
}
rm(TestHh_df, Pctl)

#Save the models
#---------------
#Make a list of all models to be saved
DvmtModel_ls <- list(Metro = list(), NonMetro = list())
DvmtModel_ls$Metro$Pow <- MetroPow
DvmtModel_ls$Metro$Ave <- makeModelFormulaString(MetroAveDvmt_LM)
for (nm in names(MetroPctlMdl_ls)) {
  DvmtModel_ls$Metro[[nm]] <- MetroPctlMdl_ls[[nm]]
}
rm(nm)
DvmtModel_ls$NonMetro$Pow <- NonMetroPow
DvmtModel_ls$NonMetro$Ave <- makeModelFormulaString(NonMetroAveDvmt_LM)
for (nm in names(NonMetroPctlMdl_ls)) {
  DvmtModel_ls$NonMetro[[nm]] <- NonMetroPctlMdl_ls[[nm]]
}
rm(nm)
#Save the models
#' Daily vehicle miles traveled (DVMT) models
#'
#' A list of components used to predict the average and several pecentiles
#' (85th, 95th, 99th, 100th) of daily vehicle miles traveled for households.
#' The models are linear regression models. The average DVMT model predicts
#' average DVMT as a power transform. The 'Pow' component contains the power
#' term for untransforming the model results. The percentile DVMT models
#' predict the household DVMT at variou percentiles as a function of the
#' household's average DVMT.
#'
#' @format A list having 'Metro' and 'NonMetro' components. Each component has
#' the following components:
#' Pow: factor to untransform the results of the average DVMT model;
#' Ave: the formula for the average DVMT model;
#' Pctl85: the formula for the 85th percentile DVMT model;
#' Pctl95: the formula for the 95th percentile DVMT model;
#' Pctl99: the formula for the 99th percentile DVMT model;
#' Pctl100: the formula for the 100th percentile DVMT model.
#' @source CalculateHouseholdDVMT.R
"DvmtModel_ls"
devtools::use_data(DvmtModel_ls, overwrite = TRUE)

#Clean Up
#--------
rm(
  Hh_df, MetroDvmtQuants_HhX, NonMetroDvmtQuants_HhX, IsMetro_, MetroAveDvmt_Hh,
  MetroAveDvmt_LM, MetroPctlMdl_ls, MetroPow, NonMetroAveDvmt_Hh,
  NonMetroAveDvmt_LM, NonMetroPctlMdl_ls, NonMetroPow, calcDispersonFactor,
  findPower, makeFormula, simulateDvmt
  )


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateHouseholdDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  Inp = NULL,
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
      NAME = "TranRevMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN/YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "FwyLaneMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "Workers",
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
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
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "NA",
      ISELEMENTOF = c(0, 1)
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by the household in autos or light trucks"
    ),
    item(
      NAME = "UrbanHhDvmt",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled in autos or light trucks by households residing in the urbanized portion of the Marea"
    ),
    item(
      NAME = "RuralHhDvmt",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled in autos or light trucks by households residing in the non-urbanized portion of the Marea"
    )
  ),
  Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateHouseholdDvmt module
#'
#' A list containing specifications for the CalculateHouseholdDvmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateHouseholdDvmt.R script.
"CalculateHouseholdDvmtSpecifications"
devtools::use_data(CalculateHouseholdDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates average DVMT, 95th percentile day DVMT, and maximum
#DVMT.

#Main module function that calculates vehicle ownership
#------------------------------------------------------
#' Calculate the average household DVMT, 95th percentile household DVMT, and
#' maximum household DVMT.
#'
#' \code{CalculateHouseholdDvmt} calculate the average household DVMT, 95th
#' percentile household DVMT, and maximum household DVMT.
#'
#' This function calculates the average household DVMT, 95th percentile
#' household DVMT, and maximum household DVMT as a function of the household
#' characteristics and the characteristics of the area where the household
#' resides.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateHouseholdDvmt <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Calculate number of households
  NumHh <- length(L$Year$Household[[1]])

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  TranRevMiPC_Bz <-
    L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Tranmilescap <-
    TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  FwyLaneMiPC_Bz <-
    L$Year$Marea$FwyLaneMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Fwylnmicap <-
    FwyLaneMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$NumVeh <- Hh_df$Vehicles
  Hh_df$ZeroVeh <- as.numeric(Hh_df$Vehicles == 0)
  Hh_df$OneVeh <- as.numeric(Hh_df$Vehicles == 1)
  Hh_df$UrbanDev <- Hh_df$IsUrbanMixNbrhd
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$LogIncome <- log1p(Hh_df$Income)
  Hh_df$Hbppopdn <-
    L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$Intercept <- 1

  #Apply the average DVMT model
  #----------------------------
  AveDvmt_ <- numeric(NumHh)
  IsUr_ <- Hh_df$DevType == "Urban"
  AveDvmt_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                   envir = Hh_df[IsUr_,])) ^ (1 / DvmtModel_ls$Metro$Pow)
  AveDvmt_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                   envir = Hh_df[!IsUr_,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)
  #Limit the household DVMT to be no greater than 99th percentile for the population
  AveDvmt_[AveDvmt_ > quantile(AveDvmt_, 0.99)] <- quantile(AveDvmt_, 0.99)

  #Apply the 95th percentile model
  #-------------------------------
  Hh_df$Dvmt <- AveDvmt_
  Hh_df$DvmtSq <- AveDvmt_ ^ 2
  Hh_df$DvmtCu <- AveDvmt_ ^ 3
  Dvmt95th_ <- numeric(NumHh)
  Dvmt95th_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Pctl95),
                   envir = Hh_df[IsUr_,]))
  Dvmt95th_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Pctl95),
                   envir = Hh_df[!IsUr_,]))

  #Sum the DVMT by Marea
  #---------------------
  Dvmt_MaDt <-
    tapply(Hh_df$Dvmt, list(Hh_df$Marea, Hh_df$DevType), sum)

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Dvmt = AveDvmt_,
      Dvmt95th = Dvmt95th_)
  Out_ls$Year$Marea <-
    list(UrbanHhDvmt = unname(Dvmt_MaDt[Ma,"Urban"]),
         RuralHhDvmt = unname(Dvmt_MaDt[Ma,"Rural"]))
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
#   ModuleName = "CalculateHouseholdDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateHouseholdDvmt(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateHouseholdDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
