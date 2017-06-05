#================
#PredictHousing.R
#================
#This module assigns a housing type, either single family (SF) or multifamily
#(MF) to regular households and group quarters (GQ) to non-institutional
#group quarters persons.

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
#This model predicts housing (single family or multifamily) for households
#based on the supply of housing of each type and the demographic and
#income characteristics of the household.

#Define a function to estimate housing choice model
#--------------------------------------------------
#' Estimate housing choice model
#'
#' \code{estimateHousingModel} estimates a binomial logit model for choosing
#' between single family and multifamily housing
#'
#' This function estimates a binomial logit model for predicting housing choice
#' (single family or multifamily) as a function of the supply of housing of
#' these types and the demographic and income characteristics of the household.
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
#' @import visioneval
#Define function to estimate the income model
estimateHousingModel <- function(Data_df, StartTerms_) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <-
    function(In_df) {
      Ah <-
        c("Age15to19",
          "Age20to29",
          "Age30to54",
          "Age55to64",
          "Age65Plus")
      Out_df <-
        data.frame(t(apply(In_df[, Ah], 1, function(x) {
          AgeLvl_ <- 1:5 #Age levels
          HhAgeLvl_ <- rep(AgeLvl_, x)
          HeadOfHh_ <- numeric(5)
          if (max(HhAgeLvl_) < 5) {
            HeadOfHh_[max(HhAgeLvl_)] <- 1
          } else {
            if (all(HhAgeLvl_ == 5)) {
              HeadOfHh_[5] <- 1
            } else {
              NumMidAge <- sum(HhAgeLvl_ %in% c(3, 4))
              NumElderly <- sum(HhAgeLvl_ == 5)
              if (NumMidAge > NumElderly) {
                HeadOfHh_[max(HhAgeLvl_[HhAgeLvl_ < 5])] <- 1
              } else {
                HeadOfHh_[5] <- 1
              }
            }
          }
          HeadOfHh_
        })))
      names(Out_df) <- paste0("Head", Ah)
      Out_df$HhSize <- In_df$HhSize
      Out_df$Income <- In_df$Income
      Out_df$RelLogIncome <- log1p(In_df$Income) / mean(log1p(In_df$Income))
      Out_df$Intercept <- 1
      Out_df
    }
  EstData_df <- prepIndepVar(Data_df)
  EstData_df$SingleFamily <- as.numeric(Data_df$HouseType == "SF")
  #Define function to make the model formula
  makeFormula <-
    function(StartTerms_) {
      FormulaString <-
        paste("SingleFamily ~ ", paste(StartTerms_, collapse = "+"))
      as.formula(FormulaString)
    }
  #Estimate model
  HouseTypeModel <-
    glm(makeFormula(StartTerms_), family = binomial, data = EstData_df)
  #Return model
  list(
    Type = "binomial",
    Formula = makeModelFormulaString(HouseTypeModel),
    Choices = c("SF", "MF"),
    PrepFun = prepIndepVar,
    Summary = summary(HouseTypeModel)
  )
}

#Estimate the binomial logit model
#---------------------------------
#Load the household estimation data
load("data/Hh_df.rda")
#Select regular households
Hh_df <- Hh_df[Hh_df$HhType == "Reg",]
Hh_df$Income[Hh_df$Income == 0] <- 1
#Estimate the housing model
HouseTypeModelTerms_ <-
  c(
    "HeadAge20to29",
    "HeadAge30to54",
    "HeadAge55to64",
    "HeadAge65Plus",
    "RelLogIncome",
    "HhSize",
    "RelLogIncome:HhSize"
  )
HouseTypeModel_ls <- estimateHousingModel(Hh_df, HouseTypeModelTerms_)
rm(HouseTypeModelTerms_, Hh_df)

#Estimate the search range for matching target housing proportions
#-----------------------------------------------------------------
#The housing choice model can be adjusted (self-calibrated) to match a target
#single family housing proportion. This uses capabilities in the visioneval
#applyBinomialModel() function and the binarySearch() function to adjust the
#intercept of the model to match the input proportion. To do so the model needs
#to specify a search range.
load("data/Hh_df.rda")
#Select regular households
Hh_df <- Hh_df[Hh_df$HhType == "Reg",]
Hh_df$Income[Hh_df$Income == 0] <- 1
#Check search range of values to use
HouseTypeModel_ls$SearchRange <- c(-10, 10)
applyBinomialModel(
  HouseTypeModel_ls,
  Hh_df,
  TargetProp = NULL,
  CheckTargetSearchRange = TRUE)
#Check that low target can be matched with search range
Target <- 0.01
LowResult_ <- applyBinomialModel(
  HouseTypeModel_ls,
  Hh_df,
  TargetProp = Target
)
Result <- round(table(LowResult_) / length(LowResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, LowResult_, Result)
#Check that high target can be matched with search range
Target <- 0.99
HighResult_ <- applyBinomialModel(
  HouseTypeModel_ls,
  Hh_df,
  TargetProp = Target
)
Result <- round(table(HighResult_) / length(HighResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, HighResult_, Result)
rm(Hh_df)

#Save the housing choice model
#-----------------------------
#' Housing choice model
#'
#' A list containing the housing choice model equation and other information
#' needed to implement the housing choice model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("binomial")}
#'   \item{Formula}{makeModelFormulaString(HouseTypeModel)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the model}
#'   \item{Summary}{the summary of the binomial logit model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source PredictHousing.R script.
"HouseTypeModel_ls"
devtools::use_data(HouseTypeModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
PredictHousingSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "SFDU",
          "MFDU",
          "GQDU"),
      FILE = "bzone_dwelling_units.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
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
          "SFDU",
          "MFDU",
          "GQDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
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
      UNITS = "USD.1999",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
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
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "dwelling type",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ"),
      SIZE = 2
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for PredictHousing module
#'
#' A list containing specifications for the PredictHousing module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source PredictHousing.R script.
"PredictHousingSpecifications"
devtools::use_data(PredictHousingSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function predicts the housing type each household. It uses the estimated
#binomial choice model for determining the probability that the housing choice
#for each household is single family (SF) vs. multifamily (MF). The group
#quarters population is assigned to group quarters (GQ).

#Main module function that predicts the housing type for each household
#----------------------------------------------------------------------
#' Main module function to predict the housing type for all households.
#'
#' \code{PredictWorkers} predicts the housing type for all households.
#'
#' This function predicts the housing choice of each household. It uses the
#' estimated models of binomial choice model for determining the probability
#' that the housing choice for each household is single family (SF) vs.
#' multifamily (MF). The group quarters population is assigned to group quarters
#' (GQ).
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
PredictHousing <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Calculate the single family housing proportion
  SFDU <- sum(L$Year$Bzone$SFDU)
  MFDU <- sum(L$Year$Bzone$MFDU)
  PropSFDU <- SFDU / (SFDU + MFDU)
  #Identify which households are group quarters
  IsGQ <- L$Year$Household$HhType == "Grp"
  #Initialize output list
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      HouseType = character(length(L$Year$Household[[1]]))
    )
  #Add housing type for group quarters
  #-----------------------------------
  Out_ls$Year$Household$HouseType[IsGQ] <- "GQ"
  #Add housing type for regular households
  #---------------------------------------
  #Make data frame of variables in used housing model
  Hh_df <- data.frame(L$Year$Household)
  Hh_df <- Hh_df[!IsGQ,]
  #Predict housing type
  HouseType_ <- applyBinomialModel(
    HouseTypeModel_ls,
    Hh_df,
    TargetProp = PropSFDU
  )
  #Add to the outputs
  Out_ls$Year$Household$HouseType[!IsGQ] <- HouseType_
  table(Out_ls$Year$Household$HouseType)
  #Return the Out_ls
  #-----------------
  Out_ls
}

