#===============
#PredictIncome.R
#===============

#<doc>
## PredictIncome Module
#### September 6, 2018
#
#This module predicts the income for each simulated household given the number of workers in each age group and the average per capita income for the Azone where the household resides.
#
### Model Parameter Estimation
#Household income models are estimated for *regular* households and for *group quarters* households.
#
#The household income models are estimated using Census public use microsample (PUMS) data that are compiled into a R dataset (HhData_df) by the 'CreateEstimationDatasets.R' script when the VESimHouseholds package is built. The data that are supplied with the VESimHouseholds package downloaded from the VisionEval repository may be used, but it is preferrable to use data for the region being modeled. How this is done is explained in the documentation for the *CreateEstimationDatasets.R* script.
#
#The household income models are linear regression models in which the dependent variable is a power transformation of income. Power transformation is needed in order to normalize the income data distribution which has a long right-hand tail. The power transform is found which minimizes the skewness of the income distribution. The power transform for *regular* households is:
#
#<txt:HHIncModel_ls$Pow>
#
#The power transform for *group quarters* households is:
#
#<txt:GQIncModel_ls$Pow>
#
#The independent variables for the linear models are power transformed per capita income for the area, the number of workers in each of 4 worker age groups (15-19, 20-29, 30-54, 55-64), and the number of persons in the 65+ age group. In addition, power-transformed per capita income is interacted with each of the 4 worker groups and 65+ age group variable. The summary statistics for the *regular* household model are as follows:
#
#<txt:HHIncModel_ls$Summary>
#
#The summary statistics for the *group quarters* household model are as follows:
#
#<txt:GQIncModel_ls$Summary>
#
#An additional step must be carried out in order to predict household income. Because the linear model does not account for all of the observed variance, and because income is power distribution, the average of the predicted per capita income is less than the average per capita income of the population. To compensate, random variation needs to be added to each household prediction of power-transformed income by randomly selecting from a normal distribution that is centered on the value predicted by the linear model and has a standard deviation that is calculated so as the resulting average per capita income of households match the input value. A binary search process is used to find the suitable standard deviation. Following is the comparison of mean values for the observed *regular* household income for the estimation dataset and the corresponding predicted values for the estimation dataset.
#
#<tab:HHIncModel_ls$MeanCompare>
#
#The following figure compares the distributions of the observed and predicted incomes of *regular* households.
#
#<fig:reg-hh-inc_obs-vs-est_distributions.png>
#
#Following is the comparison of mean values for the observed *group quarters* household income for the estimation dataset and the corresponding predicted values for the estimation dataset.
#
#<tab:GQIncModel_ls$MeanCompare>
#
#The following figure compares the distributions of the observed and predicted incomes of *groups quarters* households.
#
#<fig:gq-hh-inc_obs-vs-est_distributions.png>
#
### How the Module Works
#This module runs at the Azone level. Azone household average per capita income and group quarters average per capita income are user inputs to the model. The other model inputs are in the datastore, having been created by the CreateHouseholds and PredictWorkers modules. Household income is predicted separately for *regular* and *group quarters* households. Per capita income is transformed using the estimated power transform, the model dependent variables are calculated, and the linear model is applied. Random variation is applied so that the per capita mean income for the predicted household income matches the input value.
#

#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This model predicts a household income as a function of the number of workers
#in each age group in the household and the average per capita income for the
#Azone where the household is located. Separate models are estimated for
#regular households and the noninstitutional group quarters population. The
#models are linear regression models where the dependent variable is
#power-transformed income as is the Azone average per capita income. The model
#estimation function uses the 'powerTransform' function from the 'car' package
#to find the power transformation which best normalizes the data.

#Define a function to estimate household income model
#----------------------------------------------------
#' Estimate household income model
#'
#' \code{estimateIncomeModel} estimates a linear regression model and provides
#' supportive functions.
#'
#' This function estimates a linear regression model for predicting power-
#' transformed household income as a function of the number of persons in each
#' age group and the power-transformed average per capita income of households
#' residing in the Azone. The function calculates the power which best
#' normalizes the household income distribution of the estimation dataset. The
#' function also defines functions for transforming the input data to use in
#' estimating and applying the model, and for transforming the result of
#' applying the linear regression model.
#'
#' @param Data_df A data frame containing estimation data.
#' @param StartTerms_ A character vector of the terms of the model to be
#' tested in the model. The function estimates the model using these terms
#' and then drops all terms whose p value is greater than 0.05.
#' @return A list which has the following components:
#' Type: a string identifying the type of model ("linear"),
#' Formula: a string representation of the model equation,
#' PrepFun: a function that prepares inputs to be applied in the linear model,
#' OutFun: a function that transforms the result of applying the linear model.
#' Summary: the summary of the linear model estimation results.
#' @import visioneval utils
#' @include CreateEstimationDatasets.R CreateHouseholds.R PredictWorkers.R
#' @export
estimateIncomeModel <- function(Data_df, StartTerms_) {
  #Define function to calculate power transform to minimize skewness
  findPower <- function(Inc_) {
    skewness <- function (x)
    {
      x <- x[!is.na(x)]
      n <- length(x)
      x <- x - mean(x)
      y <- sqrt(n) * sum(x^3)/(sum(x^2)^(3/2))
      y * ((1 - 1/n))^(3/2)
    }
    checkSkewMatch <- function(Pow) {
      skewness(Inc_^Pow)
    }
    binarySearch(checkSkewMatch, c(0.001,1), Target = 0)
  }
  #Calculate income power transformation
  Pow <- round(findPower(Data_df$Income), 3)
  #Define function to prepare inputs for estimating model
  prepIndepVar <- function(In_df) {
    Out_df <- In_df
    Out_df$PowPerCapInc <- In_df$AvePerCapInc ^ Pow
    Out_df$Intercept <- 1
    Out_df
  }
  #Prepare estimation data
  EstData_df <- prepIndepVar(Data_df)
  EstData_df$PowInc <- Data_df$Income ^ Pow
  #Define function to make a model formula
  makeFormula <-
    function(Terms_) {
      FormulaString <-
        paste("PowInc ~ ", paste(Terms_, collapse = "+"))
      as.formula(FormulaString)
    }
  IncModel_LM <-
    lm(makeFormula(StartTerms_), data = EstData_df)
  Coeff_mx <- coefficients(summary(IncModel_LM))
  EndTerms_ <- rownames(Coeff_mx)[Coeff_mx[, "Pr(>|t|)"] <= 0.05]
  if ("(Intercept)" %in% EndTerms_) {
    EndTerms_ <- EndTerms_[-grep("(Intercept)", EndTerms_)]
  }
  IncModel_LM <- lm(makeFormula(EndTerms_), data = EstData_df)
  #Define function to transform model outputs and establish income groups
  transformResult <- function(Result_) {
    Result_[Result_ <= 0] <- 1
    Income_ <- Result_ ^ (1 / Pow)
    MinInc <- min(Income_[Income_ > 0])
    Income_[Income_ < MinInc] <- MinInc
    Income_
  }
  #Return model
  list(
    Type = "linear",
    Formula = makeModelFormulaString(IncModel_LM),
    PrepFun = prepIndepVar,
    OutFun = transformResult,
    Pow = Pow,
    Summary = capture.output(summary(IncModel_LM))
  )
}

#Estimate the household linear income model
#------------------------------------------
#Load the household estimation data
load("data/Hh_df.rda")
#Select regular households and give 0 income households an income of 1
Hh_df <- Hh_df[Hh_df$HhType == "Reg",]
Hh_df$Income[Hh_df$Income == 0] <- 1
#Define the start terms
StartTerms_ <-
  c("PowPerCapInc",
    "Wkr15to19",
    "Wkr20to29",
    "Wkr30to54",
    "Wkr55to64",
    "Age65Plus",
    "PowPerCapInc:Wkr15to19",
    "PowPerCapInc:Wkr20to29",
    "PowPerCapInc:Wkr30to54",
    "PowPerCapInc:Wkr55to64",
    "PowPerCapInc:Age65Plus")
#Estimate the model
HHIncModel_ls <- estimateIncomeModel(Hh_df, StartTerms_)
rm(StartTerms_)

#Estimate the search range for average household income matching
#---------------------------------------------------------------
#The income model produces a result that does not match the average per capita
#income that is the input to the model. This is a consequence of household
#income following a power distribution and the covariance of the linear model
#predictions being much less than the covariance of the observed household
#incomes. To correct this, when the model is applied a binary search algorithm
#is used to calibrate a dispersion parameter that increases the variance of
#model outputs sufficiently to match the average per capita income for the
#Azone. In order for the binary search to be accomplished, a suitable search
#range needs to be specified.
HHIncModel_ls$SearchRange <- c(0, 20)

#Compare observed and estimated distributions
#--------------------------------------------
IncObs_ <- Hh_df$Income
HHIncomeTarget <- mean(IncObs_)
IncEst_ <- applyLinearModel(
  HHIncModel_ls,
  Hh_df,
  TargetMean = HHIncomeTarget,
  CheckTargetSearchRange = FALSE
)
#Compare observed and estimated means
MeanCompare_df <- data.frame(
  Dollars = c(
    "Observed" = round(mean(IncObs_)),
    "Estimated" = round(mean(IncEst_))
  )
)
HHIncModel_ls$MeanCompare <- MeanCompare_df
#Plot comparison of observed and estimated income distributions
png(
  filename = "data/reg-hh-inc_obs-vs-est_distributions.png",
  width = 480,
  height = 480
)
plot(
  density(IncObs_),
  xlim = c(0, 200000),
  xlab = "Annual Dollars ($2000)",
  main = "Distributions of Observed and Predicted Household Income \nRegular Households"
  )
lines(density(IncEst_), lty = 2)
legend("topright", legend = c("Observed", "Predicted"), lty = c(1,2))
dev.off()
#Clean up
rm(Hh_df, IncObs_, HHIncomeTarget, MeanCompare_df)

#Save the household income model
#-------------------------------
#' Household income model
#'
#' A list containing the income model equation and other information needed to
#' implement the household income model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("linear")}
#'   \item{Formula}{makeModelFormulaString(IncModel_LM)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the linear model}
#'   \item{OutFun}{a function that transforms the result of applying the linear model}
#'   \item{Summary}{the summary of the linear model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source PredictIncome.R script.
"HHIncModel_ls"
usethis::use_data(HHIncModel_ls, overwrite = TRUE)

#Estimate the group quarters linear income model
#-----------------------------------------------
#Load the household estimation data
load("data/Hh_df.rda")
Hh_df <- Hh_df[Hh_df$HhType == "Grp",]
Hh_df$Income[Hh_df$Income == 0] <- 1
#Define the start terms
StartTerms_ <-
  c("PowPerCapInc",
    "Wkr15to19",
    "Wkr20to29",
    "Wkr30to54",
    "Wkr55to64",
    "Age65Plus",
    "PowPerCapInc:Wkr15to19",
    "PowPerCapInc:Wkr20to29",
    "PowPerCapInc:Wkr30to54",
    "PowPerCapInc:Wkr55to64",
    "PowPerCapInc:Age65Plus")
#Estimate the model
GQIncModel_ls <- estimateIncomeModel(Hh_df, StartTerms_)
rm(StartTerms_)

#Estimate the search range for average group quarters income matching
#--------------------------------------------------------------------
#The income model produces a result that does not match the average per capita
#income that is the input to the model. This is a consequence of household
#income following a power distribution and the covariance of the linear model
#predictions being much less than the covariance of the observed household
#incomes. To correct this, when the model is applied a binary search algorithm
#is used to calibrate a dispersion parameter that increases the variance of
#model outputs sufficiently to match the average per capita income for the
#Azone. In order for the binary search to be accomplished, a suitable search
#range needs to be specified.
GQIncModel_ls$SearchRange <- c(0, 20)

#Compare observed and estimated distributions
#--------------------------------------------
IncObs_ <- Hh_df$Income
HHIncomeTarget <- mean(IncObs_)
IncEst_ <- applyLinearModel(
  GQIncModel_ls,
  Hh_df,
  TargetMean = HHIncomeTarget,
  CheckTargetSearchRange = FALSE
)
#Compare observed and estimated means
MeanCompare_df <- data.frame(
  Dollars = c(
    "Observed" = round(mean(IncObs_)),
    "Estimated" = round(mean(IncEst_))
  )
)
GQIncModel_ls$MeanCompare <- MeanCompare_df
#Plot comparison of observed and estimated income distributions
png(
  filename = "data/gq-hh-inc_obs-vs-est_distributions.png",
  width = 480,
  height = 480
)
plot(
  density(IncObs_),
  xlim = c(0, 60000),
  xlab = "Annual Dollars ($2000)",
  main = "Distributions of Observed and Predicted Household Income \nGroup Quarters Households"
)
lines(density(IncEst_), lty = 2)
legend("topright", legend = c("Observed", "Predicted"), lty = c(1,2))
dev.off()
#Clean up
rm(Hh_df, IncObs_, HHIncomeTarget, MeanCompare_df)

#Save the group quarters income model
#------------------------------------
#' Group quarters income model
#'
#' A list containing the income model equation and other information needed to
#' implement the group quarters income model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("linear")}
#'   \item{Formula}{makeModelFormulaString(IncModel_LM)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the linear model}
#'   \item{OutFun}{a function that transforms the result of applying the linear model}
#'   \item{Summary}{the summary of the linear model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source PredictIncome.R script.
"GQIncModel_ls"
usethis::use_data(GQIncModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
PredictIncomeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "HHIncomePC",
          "GQIncomePC"),
      FILE = "azone_per_cap_inc.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        list("Average annual per capita income of households (non-group quarters)",
             "Average annual per capita income of group quarters population")
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
      NAME =
        items(
          "HHIncomePC",
          "GQIncomePC"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.1999",
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
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "HhType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Wkr15to19",
              "Wkr20to29",
              "Wkr30to54",
              "Wkr55to64",
              "Age65Plus"),
      TABLE = "Household",
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.1999",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total annual household (non-qroup & group quarters) income"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for PredictIncome module
#'
#' A list containing specifications for the PredictIncome module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source PredictIncome.R script.
"PredictIncomeSpecifications"
usethis::use_data(PredictIncomeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function predicts the annual income of each household. It uses the
#estimated models of regular household income and group quarters income along
#with inputs for average per capita income for households and for group quarters.

#Main module function that predicts income for each household
#------------------------------------------------------------
#' Main module function to predict income for regular households and persons
#' living in noninstitutional group quarters.
#'
#' \code{PredictIncome} predicts the income of regular households and persons
#' living in noninstitutional group quarters.
#'
#' This function predicts the of each household. It uses the estimated models of
#' regular household income and group quarters income along with inputs for
#' average per capita income for households and for group quarters.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name PredictIncome
#' @import visioneval
#' @export
PredictIncome <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Make vector to select which records are group quarters population
  IsGroupQuarters_ <- L$Year$Household$HhType == "Grp"
  #Calculate the number of regular and group quarters households
  NumHH <- sum(!IsGroupQuarters_)
  NumGQ <- sum(IsGroupQuarters_)
  #Initialize output list
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Income = integer(NumHH + NumGQ)
    )
  #Predict income for regular households
  #-------------------------------------
  #Create data frame for regular households
  Data_df <-
    data.frame(L$Year$Household)[!IsGroupQuarters_,]
  #Add Azone average per capita income to data frame
  Data_df$AvePerCapInc <- L$Year$Azone$HHIncomePC
  #Calculate average household income target to match
  HHIncomeTarget <-
    L$Year$Azone$HHIncomePC * sum(Data_df$HhSize) / nrow(Data_df)
  #Predict the income for regular households
  Out_ls$Year$Household$Income[!IsGroupQuarters_] <-
    applyLinearModel(
    HHIncModel_ls,
    Data_df,
    TargetMean = HHIncomeTarget,
    CheckTargetSearchRange = FALSE)
  #Predict income for persons in noninstitutional group quarters
  #-------------------------------------------------------------
  #Only run group quarters model if there is a group quarters population
  if (sum(IsGroupQuarters_) > 0) {
    #Create data frame for group quarters persons
    Data_df <-
      data.frame(L$Year$Household)[IsGroupQuarters_,]
    #Add Azone average per capita income to data frame
    Data_df$AvePerCapInc <- L$Year$Azone$GQIncomePC
    #Calculate average household income target to match
    #is the same as the average per capita income because household size is 1
    GQIncomeTarget <- L$Year$Azone$GQIncomePC
    #Predict the income for noninstitutional group quarters population
    Out_ls$Year$Household$Income[IsGroupQuarters_] <-
      applyLinearModel(
        GQIncModel_ls,
        Data_df,
        TargetMean = GQIncomeTarget,
        CheckTargetSearchRange = FALSE)
  }
  #Return the result
  #-----------------
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("PredictIncome")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(visioneval)
# library(filesstrings)
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
#   ModuleName = "PredictIncome",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- PredictIncome(TestDat_)
