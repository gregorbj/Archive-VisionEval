#===============
#PredictIncome.R
#===============
#This module predicts the income for each simulated household given the
#number of workerss in each age group and the average per capita income for the
#Azone where the household resides.


#=================================
#Packages used in code development
#=================================
#The following commented lines of code are in the script for code development
#purposes only. Uncomment them if needed to work on the script. Recomment when
#done.
# library(visioneval)
# library(car)


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
#' @import visioneval car
#' @include CreateEstimationDatasets.R CreateHouseholds.R PredictWorkers.R
#' @export
estimateIncomeModel <- function(Data_df, StartTerms_) {
  #Calculate income power transformation
  Pow <-
    car::powerTransform(
      Income ~ 1,
      weights = Data_df$HhWeight,
      data = Data_df)$lambda
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
    Summary = summary(IncModel_LM)
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
rm(StartTerms_, Hh_df)

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
devtools::use_data(HHIncModel_ls, overwrite = TRUE)

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
rm(StartTerms_, Hh_df)

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
devtools::use_data(GQIncModel_ls, overwrite = TRUE)


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
devtools::use_data(PredictIncomeSpecifications, overwrite = TRUE)


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
  if(any(IsGroupQuarters_)){
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


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictIncome",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictIncome",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
