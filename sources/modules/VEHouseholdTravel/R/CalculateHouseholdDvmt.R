#========================
#CalculateHouseholdDvmt.R
#========================
#
#<doc>
#
## CalculateHouseholdDvmt Module
#### November 12, 2018
#
#This module models household average daily vehicle miles traveled as a function of household characteristics, vehicle ownership, and attributes of the neighborhood and metropolitan area where the household resides.
#
### Model Parameter Estimation
#
#The estimation of household DVMT models is a five-step process. In the first step, binomial logit models are estimated to predict the likelihood that there is no household DVMT on the travel day. Separate models are estimated for metropolitan and non-metropolitan households. In the second step, linear regression models are estimated which predict power-transformed DVMT for households that have DVMT on the travel day. The DVMT power transformation factor is calculated to normalize the distribution. The linear models and power transformations are estimated separately for metropolitan and non-metropolitan households. In the third step, dispersion factors are estimated for adding variance to the linear models so that the variance of the results equals the observed variance. In the fourth step, the binomial and linear models are applied stochastically to simulate day-to-day variation in DVMT over 1000 days. These simulated results are used to calculate average DVMT and DVMT quantiles (at 5% intervals and 99%) for each household. In the fifth step, linear models are estimated to predict the simulated average DVMT. As with the other models, separate models are estimated for metropolitan and non-metropolitan households. Finally, linear models are estimated to predict the DVMT for each quantile from the average DVMT. Following is a more detailed presentation of these models including model estimation statistics and explanatory tables and figures. More model estimation statistics are included in the 'EstimationStats' component of the 'DvmtModel_ls' object stored in the 'DvmtModel_ls.Rda' file in the 'data' directory of this package.
#
#The binary logit model for predicting the probability that non-metropolitan area households had no DVMT on the travel survey day includes the following terms:
#
#* Drivers - number of drivers in the household
#
#* LogInc - natural log of annual household income ($2001)
#
#* Hbppopdn - density (pop/sq mi) of the census block group
#
#* NumVeh - number of vehicles owned or leased by the household
#
#* ZeroVeh - dummy variable identifying whether the household has no vehicles
#
#* Workers - number of workers in the household
#
#Following are the summary statistics for the non-metropolitan household zero DVMT binary logit model:
#
#<txt:DvmtModel_ls$EstimationStats$NonMetroZeroDvmt_GLM$Summary>
#
#The following table shows correlations between the independent variables of the non-metropolitan model.
#
#<tab:DvmtModel_ls$EstimationStats$NonMetroZeroDvmt_GLM$Correlations>
#
#The metropolitan household zero DVMT binary logit model includes the following terms in addition to the terms in the non-metropolitan household model:
#
#* BusEqRevMiPC - urbanized area per capita bus-equivalent transit revenue miles
#
#* UrbanDev - whether the block group is characterized by urban mixed-use development
#
#Following are the summary statistics for the metropolitan household zero DVMT binary logit model:
#
#<txt:DvmtModel_ls$EstimationStats$MetroZeroDvmt_GLM$Summary>
#
#The following table shows correlations between the independent variables of the metropolitan model.
#
#<tab:DvmtModel_ls$EstimationStats$MetroZeroDvmt_GLM$Correlations>
#
#Linear models for metropolitan and non-metropolitan area households were estimated to predict the power-transformed household travel day DVMT. Power transformation is necessary because the distribution of household travel day DVMT is skewed with a long right-hand tail. The values of the transforming powers were calculated separately for metropolitan and non-metropolitan households. The transforming power was found which minimizes the skewness of the distribution. Skewness was measured using the skewness function from the e1071 package.
#
#The non-metropolitan power transform is:
#
#<txt:DvmtModel_ls$EstimationStats$NonMetroPowDvmt_LM$PowerTransform>
#
#The metropolitan power transform is:
#
#<txt:DvmtModel_ls$EstimationStats$MetroPowDvmt_LM$PowerTransform>
#
#The non-metropolitan linear model of power-transformed household travel day DVMT includes the following terms:
#
#* Drivers - number of drivers in the household
#
#* LogIncome - natural log of annual household income ($2001)
#
#* Hbppopdn - density (pop/sq mi) of the census block group
#
#* NumVeh - number of vehicles owned or leased by the household
#
#* ZeroVeh - dummy variable identifying whether the household has no vehicles
#
#* OneVeh - dummy variable identifying whether the household has only one vehicle
#
#* Workers - number of workers in the household
#
#* Age0to14 - number of persons in the 0 - 14 age group in the household
#
#Following are the summary statistics for non-metropolitan household power-transformed travel day DVMT linear model:
#
#<txt:DvmtModel_ls$EstimationStats$NonMetroPowDvmt_LM$Summary>
#
#The following table shows correlations between the independent variables of the non-metropolitan model.
#
#<tab:DvmtModel_ls$EstimationStats$NonMetroPowDvmt_LM$Correlations>
#
#The metropolitan linear model of power-transformed household travel day DVMT includes the following terms in addition to the terms included in the non-metropolitan household model:
#
#* UrbanDev - whether the block group is urban mixed-use
#
#* FwyLaneMiPC - ratio of freeway lane miles to urbanized area population
#
#Following are the summary statistics for the metropolitan household power-transformed travel day DVMT linear model:
#
#<txt:DvmtModel_ls$EstimationStats$MetroPowDvmt_LM$Summary>
#
#The following table shows correlations between the independent variables of the metropolitan model.
#
#<tab:DvmtModel_ls$EstimationStats$MetroPowDvmt_LM$Correlations>
#
#The models include dummy variables identifying zero-vehicle and one-vehicle households to better capture the observed non-linear relationship between DVMT and vehicle ownership at low levels of vehicle ownership.
#
#The linear model (metropolitan and non-metropolitan) doesn't reproduce the observed variability in household DVMT and so is used to predict the mean values of a normal sampling distribution from which a DVMT value is drawn. The value of the standard deviation of the sampling distribution is estimated using a binary search algorithm so that the observed variation of household DVMT is matched. This is done separately for the metropolitan and non-metropolitan households.
#
#The binomial and linear models are run stochastically in combination 1000 times for each of the households in the estimation dataset to simulate 1000 travel days. The binomial model with sampling is used to determine whether the household has any DVMT on the simulated travel day and the linear model with sampling determines how much DVMT. From these simulated data, the average DVMT and DVMT quantiles (at 5% intervals and 99%) are calculated for each household.
#
#Linear models are estimated to predict power-transformed simulated average household DVMT for non-metropolitan and metropolitan households. The power transformation factors are those described above. The non-metropolitan linear model of power-transformed household average DVMT includes the following terms:
#
#* Drivers - number of drivers in the household
#
#* LogIncome - natural log of annual household income ($2001)
#
#* Hbppopdn - density (pop/sq mi) of the census block group
#
#* NumVeh - number of vehicles owned or leased by the household
#
#* ZeroVeh - dummy variable identifying whether the household has no vehicles
#
#* OneVeh - dummy variable identifying whether the household has only one vehicle
#
#* Workers - number of workers in the household
#
#* Age0to14 - number of persons in the 0 - 14 age group in the household
#
#Following are the summary statistics for non-metropolitan household power-transformed simulated average DVMT linear model:
#
#<txt:DvmtModel_ls$EstimationStats$NonMetroAveDvmt_LM$Summary>
#
#The mean values of the survey DVMT, simulated average DVMT, and predicted average DVMT for the non-metropolitan households are close to one another.
#
#<tab:DvmtModel_ls$EstimationStats$NonMetroAveDvmt_LM$MeanCompare>
#
#The metropolitan linear model of household power-transformed simulated average DVMT includes the following terms in addition to the terms included in the non-metropolitan household model:
#
#* BusEqRevMiPC - urbanized area per capita bus-equivalent transit revenue miles
#
#* UrbanDev - whether the block group is urban mixed-use
#
#* FwyLaneMiPC - ratio of freeway lane miles to urbanized area population
#
#Following are the summary statistics for metropolitan household power-transformed simulated average DVMT linear model:
#
#<txt:DvmtModel_ls$EstimationStats$MetroAveDvmt_LM$Summary>
#
#The mean values of the survey DVMT, simulated average DVMT, and predicted average DVMT for the metropolitan households are close to one another.
#
#<tab:DvmtModel_ls$EstimationStats$MetroAveDvmt_LM$MeanCompare>
#
#The following charts compare the distributions of the household average DVMT for survey households predicted by the linear model with the distributions simulated for the survey households by stochastically applying the binomial and linear models of survey day DVMT. This shows that the linear model of average household DVMT can be substituted for the stochastic simulation. This enables the module to run much faster than would be the case if average DVMT had to be simulated.
#
#<fig:nonmetro_sim-vs-pred_ave_dvmt.png>
#
#<fig:metro_sim-vs-pred_ave_dvmt.png>
#
#Linear models are also estimated to predict each simulated DVMT quantile at 5% intervals and 99%. Models are estimated as 3rd degree polynomials of average DVMT. Models are estimated for each quantile separately for metropolitan and non-metropolitan households. Following are the summary statistics for the estimation of the 95th percentile DVMT model for non-metropolitan households:
#
#<txt:DvmtModel_ls$EstimationStats$NonMetro95thPctlDvmt_LM$Summary>
#
#Following are the summary statistics for the estimation of the 95th percentile DVMT model for metropolitan households:
#
#<txt:DvmtModel_ls$EstimationStats$Metro95thPctlDvmt_LM$Summary>
#
### How the Module Works
#
#This module is run at the region level. It also is a callable module and is called by several other modules.
#
#The metropolitan and non-metropolitan area linear models are used to compute power transformed average DVMT for each metropolitan (urbanized area) and non-metropolitan area household respectively. The inverse powers of the power transform factors are then applied to calculate average DVMT. To eliminate unreasonable predictions, average household DVMT is capped at the 99th percentile value for average DVMT of households in the region.
#
#The module also computes the 95th percentile DVMT for each household from the household average DVMT using the 95th percentile model.
#
#Finally, the module sums up the total DVMT of households located in the metropolitan (urbanized) area and located in the non-metropolitan (rural) area of each Marea.
#
#</doc>


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
#Convert freeway lane mile per capita from values per 1000 population which is
#how is represented in household dataset from the VE2001NHTS package to
#values per person which is how is saved in datastore by VETransportSupply
#package
Hh_df$FwyLaneMiPC <- Hh_df$FwyLnMiPC / 1000

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

#Create a list to save all of the model estimation summary statistics
#--------------------------------------------------------------------
EstimationStats_ls <- list()

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
#Save metropolitan model estimation statistics
EstimationStats_ls$MetroZeroDvmt_GLM <- list(
  Description = "Binomial logit model to predict the probability that a metropolitan (urbanized area) household has no DVMT on travel day",
  Summary = capture.output(summary(MetroZeroDvmt_GLM)),
  Anova = capture.output(anova(MetroZeroDvmt_GLM, test = "Chisq")),
  Correlations = round(cor(TestHh_df[, IndepVars_]), 2)
)
rm(IndepVars_, TestHh_df)
#Estimate nonmetropolitan model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "Workers",
    "Age0to14")
TestHh_df <- Hh_df[!IsMetro_, c("ZeroDvmt", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
NonMetroZeroDvmt_GLM <-
  glm(makeFormula("ZeroDvmt", IndepVars_), family=binomial, data = TestHh_df)
#Save non-metropolitan model estimation statistics
EstimationStats_ls$NonMetroZeroDvmt_GLM <- list(
  Description = "Binomial logit model to predict the probability that a non-metropolitan household has no DVMT on travel day",
  Summary = capture.output(summary(NonMetroZeroDvmt_GLM)),
  Anova = capture.output(anova(NonMetroZeroDvmt_GLM, test = "Chisq")),
  Correlations = round(cor(TestHh_df[, IndepVars_]), 2)
)
rm(IndepVars_, TestHh_df)

#Estimate linear model of DVMT for households that have DVMT
#-----------------------------------------------------------
#Find metropolitan and non-metropolitan DVMT power transforms
MetroPow <- findPower(Hh_df$Dvmt[IsMetro_])
NonMetroPow <- findPower(Hh_df$Dvmt[!IsMetro_])
#Estimate metropolitan model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "UrbanDev", "Age0to14", "FwyLaneMiPC")
TestHh_df <- Hh_df[IsMetro_ & Hh_df$ZeroDvmt == "N", c("Dvmt", IndepVars_)]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ MetroPow
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
MetroPowDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
#Save metropolitan household linear model estimation statistics
EstimationStats_ls$MetroPowDvmt_LM <- list(
  Description = "Linear regression model to predict power-transformed household DVMT for metropolitan (urbanized area) households recording DVMT on the travel day",
  PowerTransform = capture.output(MetroPow),
  Summary = capture.output(summary(MetroPowDvmt_LM)),
  Correlations = round(cor(TestHh_df[, IndepVars_]), 2)
)
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
#Save non-metropolitan household linear model estimation statistics
EstimationStats_ls$NonMetroPowDvmt_LM <- list(
  Description = "Linear regression model to predict power-transformed household DVMT for non-metropolitan households recording DVMT on the travel day",
  PowerTransform = capture.output(NonMetroPow),
  Summary = capture.output(summary(NonMetroPowDvmt_LM)),
  Correlations = round(cor(TestHh_df[, IndepVars_]), 2)
)
rm(IndepVars_, TestHh_df)

#Estimate disperson factor to match observed distribution of Metropolitan DVMT
#-----------------------------------------------------------------------------
#Prepare metropolitan household data frame
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "UrbanDev", "Age0to14", "FwyLaneMiPC")
TestHh_df <- Hh_df[IsMetro_ & Hh_df$ZeroDvmt == "N", c("Dvmt", IndepVars_)]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ MetroPow
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
#Calculate metropolitan observed and estimated power-transformed DVMT
ObsPowDvmt_ <- TestHh_df$Dvmt ^ MetroPow
EstPowDvmt_ <- predict(MetroPowDvmt_LM, newdata = TestHh_df)
#Calculate metropolitan dispersion factor
MetroSD <- calcDispersonFactor(ObsPowDvmt_, EstPowDvmt_)
#Save metropolitan dispersion model estimation statistics
RevEstPowDvmt_ <- EstPowDvmt_ + rnorm(length(EstPowDvmt_), 0, MetroSD)
EstimationStats_ls$MetroDispersionFactor <- list(
  Factor = MetroSD,
  ObsMeanDvmt = mean(TestHh_df$Dvmt),
  EstMeanDvmt = mean(RevEstPowDvmt_[RevEstPowDvmt_ > 0] ^ (1 / MetroPow))
)
rm(IndepVars_, TestHh_df, ObsPowDvmt_, EstPowDvmt_, RevEstPowDvmt_)
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
#Save nonmetropolitan dispersion model estimation statistics
RevEstPowDvmt_ <- EstPowDvmt_ + rnorm(length(EstPowDvmt_), 0, NonMetroSD)
EstimationStats_ls$NonMetroDispersionFactor <- list(
  Factor = NonMetroSD,
  ObsMeanDvmt = mean(TestHh_df$Dvmt),
  EstMeanDvmt = mean(RevEstPowDvmt_[RevEstPowDvmt_ > 0] ^ (1 / NonMetroPow))
)
rm(IndepVars_, TestHh_df, ObsPowDvmt_, EstPowDvmt_, RevEstPowDvmt_)

#Simulate household DVMT over many days
#--------------------------------------
#Simulate 1000 days of DVMT for metropolitan households
Vars_ <-
  c("Houseid", "Drivers", "LogIncome", "Hbppopdn", "BusEqRevMiPC", "NumVeh",
    "ZeroVeh", "OneVeh", "Workers", "UrbanDev", "Age0to14", "FwyLaneMiPC", "Dvmt")
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
    "Workers", "UrbanDev", "Age0to14", "BusEqRevMiPC", "FwyLaneMiPC")
TestHh_df <- Hh_df[IsMetro_, c("Houseid", "Dvmt", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
TestHh_df$DayDvmt <- TestHh_df$Dvmt
TestHh_df$Dvmt <- MetroAveDvmt_Hh[TestHh_df$Houseid]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ MetroPow
MetroAveDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
#Compute predicted average DVMT for metropolitan households
PredDvmt_ <- predict(MetroAveDvmt_LM, newdata = TestHh_df)^(1/MetroPow)
#Compare population means
MeanCompare_df <- data.frame(
  "Miles" = c(
    "Survey Day DVMT" = mean(TestHh_df$DayDvmt),
    "Simulated Average DVMT" = mean(TestHh_df$Dvmt),
    "Predicted Average DVMT" = mean(PredDvmt_)
  )
)
#Save metropolitan household average DVMT model summary statistics
EstimationStats_ls$MetroAveDvmt_LM <- list(
  Description = "Linear regression model to predict power-transformed household average DVMT for metropolitan (urbanized area) households",
  PowerTransform = capture.output(MetroPow),
  Summary = capture.output(summary(MetroAveDvmt_LM)),
  MeanCompare = MeanCompare_df
)
#Compare metropolitan simulated average DVMT with predicted average DVMT
png(
  filename = "data/metro_sim-vs-pred_ave_dvmt.png",
  width = 480,
  height = 480
)
plot(
  density(TestHh_df$Dvmt),
  xlim=c(0, 200),
  xlab = "Miles",
  main = "Distributions of Simulated and Predicted Average DVMT \nMetropolitan Households"
)
lines(density(predict(MetroAveDvmt_LM, newdata = TestHh_df)^(1/MetroPow)), lty = 2)
legend("topright", legend = c("Simulated", "Predicted"), lty = c(1,2))
dev.off()
rm(IndepVars_, TestHh_df, PredDvmt_, MeanCompare_df)

#Estimate non-metropolitan household model
IndepVars_ <-
  c("Drivers", "LogIncome", "Hbppopdn", "NumVeh", "ZeroVeh", "OneVeh",
    "Workers", "Age0to14")
TestHh_df <- Hh_df[!IsMetro_, c("Houseid", "Dvmt", IndepVars_)]
TestHh_df <- TestHh_df[complete.cases(TestHh_df),]
TestHh_df$DayDvmt <- TestHh_df$Dvmt
TestHh_df$Dvmt <- NonMetroAveDvmt_Hh[TestHh_df$Houseid]
TestHh_df$PowDvmt <- TestHh_df$Dvmt ^ NonMetroPow
NonMetroAveDvmt_LM <-
  lm(makeFormula("PowDvmt", IndepVars_), data = TestHh_df)
#Compute predicted average DVMT for non-metropolitan households
PredDvmt_ <- predict(NonMetroAveDvmt_LM, newdata = TestHh_df)^(1/NonMetroPow)
#Compare population means
MeanCompare_df <- data.frame(
  "Miles" = c(
    "Survey Day DVMT" = mean(TestHh_df$DayDvmt),
    "Simulated Average DVMT" = mean(TestHh_df$Dvmt),
    "Predicted Average DVMT" = mean(PredDvmt_)
  )
)
#Save non-metropolitan household average DVMT model summary statistics
EstimationStats_ls$NonMetroAveDvmt_LM <- list(
  Description = "Linear regression model to predict power-transformed household average DVMT for non-metropolitan households",
  PowerTransform = capture.output(NonMetroPow),
  Summary = capture.output(summary(NonMetroAveDvmt_LM)),
  MeanCompare = MeanCompare_df
)
#Compare non-metropolitan simulated average DVMT with predicted average DVMT
png(
  filename = "data/nonmetro_sim-vs-pred_ave_dvmt.png",
  width = 480,
  height = 480
)
plot(
  density(TestHh_df$Dvmt),
  xlim=c(0, 200),
  xlab = "Miles",
  main = "Distributions of Simulated and Predicted Average DVMT \nNon-metropolitan Households"
)
lines(density(predict(NonMetroAveDvmt_LM, newdata = TestHh_df)^(1/NonMetroPow)), lty = 2)
legend("topright", legend = c("Simulated", "Predicted"), lty = c(1,2))
dev.off()
rm(IndepVars_, TestHh_df, PredDvmt_, MeanCompare_df)

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
#Save the summary statistics for the 95th percentile metropolitan DVMT model
TestHh_df[["PctlDvmt"]] <- MetroDvmtQuants_HhX[,"95%"]
Dvmt95_LM <- lm(PctlDvmt ~ Dvmt + DvmtSq + DvmtCu, data = TestHh_df)
EstimationStats_ls$Metro95thPctlDvmt_LM <- list(
  Summary = capture.output(summary(Dvmt95_LM))
)
rm(TestHh_df, Pctl, Dvmt95_LM)

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
#Save the summary statistics for the 95th percentile non-metropolitan DVMT model
TestHh_df[["PctlDvmt"]] <- NonMetroDvmtQuants_HhX[,"95%"]
Dvmt95_LM <- lm(PctlDvmt ~ Dvmt + DvmtSq + DvmtCu, data = TestHh_df)
EstimationStats_ls$NonMetro95thPctlDvmt_LM <- list(
  Summary = capture.output(summary(Dvmt95_LM))
)
rm(TestHh_df, Pctl, Dvmt95_LM)

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
#Add the estimation statistics to the list
DvmtModel_ls$EstimationStats <- EstimationStats_ls
#Save the models
#' Daily vehicle miles traveled (DVMT) models
#'
#' A list of components used to predict the average household DVMT and several
#' DVMT quantiles at 5% intervals as well as the 99th pecentile. The models are
#' linear regression models. The average DVMT model predicts average DVMT as a
#' power transform. The 'Pow' component contains the power term for
#' untransforming the model results. The percentile DVMT models predict the
#' household DVMT at variou percentiles as a function of the household's average
#' DVMT. This list also includes an 'EstimationStats' component which documents
#' model estimation statistics for these models as well as the intermediate
#' models that were used to create these final models.
#'
#' @format A list having 'Metro' and 'NonMetro' components. Each component has
#' the following components:
#' Pow: factor to untransform the results of the average DVMT model;
#' Ave: the formula for the average DVMT model;
#' Pctl85: the formula for the 85th percentile DVMT model;
#' Pctl95: the formula for the 95th percentile DVMT model;
#' Pctl99: the formula for the 99th percentile DVMT model;
#' Pctl100: the formula for the 100th percentile DVMT model.
#' In addition, the 'EstimationStats' component of the list documents model
#' estimation statistics for the final models as well as intermediate models
#' used in developing the final models.
#' @source CalculateHouseholdDVMT.R
"DvmtModel_ls"
usethis::use_data(DvmtModel_ls, overwrite = TRUE)

#Clean Up
#--------
rm(
  Hh_df, MetroDvmtQuants_HhX, NonMetroDvmtQuants_HhX, IsMetro_, MetroAveDvmt_Hh,
  MetroAveDvmt_LM, MetroPctlMdl_ls, MetroPow, NonMetroAveDvmt_Hh,
  NonMetroAveDvmt_LM, NonMetroPctlMdl_ls, NonMetroPow, calcDispersonFactor,
  findPower, makeFormula, simulateDvmt, EstimationStats_ls
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
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
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
      NAME = items(
        "UrbanHhDvmt",
        "TownHhDvmt",
        "RuralHhDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average daily vehicle miles traveled in autos or light trucks by households residing in the urbanized portion of the Marea",
        "Average daily vehicle miles traveled in autos or light trucks by households residing in town (urban but not urbanized) portion of the Marea",
        "Average daily vehicle miles traveled in autos or light trucks by households residing in the rural (non-urban) portion of the Marea")
    )
  ),
  #Make module callable
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
usethis::use_data(CalculateHouseholdDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates average DVMT, 95th percentile day DVMT, and maximum
#DVMT.

#Main module function that calculates vehicle travel
#---------------------------------------------------
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
#' @name CalculateHouseholdDvmt
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
  #Assign the DvmtModel_ls so that it is in scope when module is called
  if(!exists("DvmtModel_ls")){
    DvmtModel_ls <- loadPackageDataset("DvmtModel_ls")
  }

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  TranRevMiPC_Bz <-
    L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$BusEqRevMiPC <-
    TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  FwyLaneMiPC_Bz <-
    L$Year$Marea$FwyLaneMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$FwyLaneMiPC <-
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
  IsUr_ <- Hh_df$LocType == "Urban"
  AveDvmt_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                   envir = Hh_df[IsUr_,])) ^ (1 / DvmtModel_ls$Metro$Pow)
  AveDvmt_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                   envir = Hh_df[!IsUr_,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)
  #Replace NaN values (model predicts below zero)
  AveDvmt_[is.na(AveDvmt_)] <- quantile(AveDvmt_[!is.na(AveDvmt_)], 0.01)
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
  #--------------------
  tabulateMareaDvmt <- function(LocType) {
    IsType <- Hh_df$LocType == LocType
    Dvmt_Ma <- setNames(numeric(length(Ma)), Ma)
    if (any(IsType)) {
      Dvmt_Mx <- tapply(Hh_df$Dvmt[IsType], Hh_df$Marea[IsType], sum)
      Dvmt_Ma[names(Dvmt_Mx)] <- Dvmt_Mx
      Dvmt_Ma[is.na(Dvmt_Ma)] <- 0
      Dvmt_Ma
    } else {
      Dvmt_Ma
    }
  }
  UrbanDvmt_Ma <- tabulateMareaDvmt("Urban")
  TownDvmt_Ma <- tabulateMareaDvmt("Town")
  RuralDvmt_Ma <- tabulateMareaDvmt("Rural")

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Dvmt = AveDvmt_,
      Dvmt95th = Dvmt95th_)
  Out_ls$Year$Marea <-
    list(UrbanHhDvmt = UrbanDvmt_Ma,
         TownHhDvmt = TownDvmt_Ma,
         RuralHhDvmt = RuralDvmt_Ma)
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculateHouseholdDvmt")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load libraries and test functions
# library(filesstrings)
# library(visioneval)
# library(data.table)
# library(pscl)
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
#   ModuleName = "CalculateHouseholdDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L
# R <- CalculateHouseholdDvmt(L)
#
# TestDat_ <- testModule(
#   ModuleName = "CalculateHouseholdDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
