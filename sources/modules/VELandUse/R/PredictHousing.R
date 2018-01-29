#================
#PredictHousing.R
#================
#This module assigns a housing type, either single family (SF) or multifamily
#(MF) to regular households and group quarters (GQ) to non-institutional
#group quarters persons. In addition, it assigns each household to a Bzone
#based on the household's housing type and income quartile as well as the
#supply of housing by type and Bzone (an input) and the distribution of
#households by income quartile for each Bzone (an input).

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
#' tested in the model.
#' @return A list which has the following components:
#' Type: a string identifying the type of model ("binomial"),
#' Formula: a string representation of the model equation,
#' PrepFun: a function that prepares inputs to be applied in the binomial model,
#' OutFun: a function that transforms the result of applying the binomial model.
#' Summary: the summary of the binomial model estimation results.
#' @import visioneval stats
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
Hh_df <- VESimHouseholds::Hh_df
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
rm(HouseTypeModelTerms_)

#Estimate the search range for matching target housing proportions
#-----------------------------------------------------------------
#The housing choice model can be adjusted (self-calibrated) to match a target
#single family housing proportion. This uses capabilities in the visioneval
#applyBinomialModel() function and the binarySearch() function to adjust the
#intercept of the model to match the input proportion. To do so the model needs
#to specify a search range.
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
  RunBy = "Region",
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
      TOTAL = "",
      DESCRIPTION =
        items(
          "Number of single family dwelling units (PUMS codes 01 - 03) in zone",
          "Number of multi-family dwelling units (PUMS codes 04 - 09) in zone",
          "Number of qroup quarters population accommodations in zone"
        )
    ),
    item(
      NAME = items(
        "HhPropIncQ1",
        "HhPropIncQ2",
        "HhPropIncQ3",
        "HhPropIncQ4"),
      FILE = "bzone_hh_inc_qrtl_prop.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of Bzone households (non-group quarters) in 1st quartile of Azone household income",
          "Proportion of Bzone households (non-group quarters) in 2nd quartile of Azone household income",
          "Proportion of Bzone households (non-group quarters) in 3rd quartile of Azone household income",
          "Proportion of Bzone households (non-group quarters) in 4th quartile of Azone household income"
        )
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
      NAME = "Azone",
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
      NAME =
        items(
          "HhPropIncQ1",
          "HhPropIncQ2",
          "HhPropIncQ3",
          "HhPropIncQ4"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
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
      NAME = "Azone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
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
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
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
      NAME = "HhType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
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
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ"),
      SIZE = 2,
      DESCRIPTION = "Type of dwelling unit in which the household resides (SF = single family, MF = multi-family, GQ = group quarters"
    ),
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = "ID of Bzone in which household resides"
    ),
    item(
      NAME =
        items(
          "SF",
          "MF",
          "GQ"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Number of households living in single family dwelling units in zone",
          "Number of households living in multi-family dwelling units in zone",
          "Number of persons living in group quarters in zone"
        )
    ),
    item(
      NAME = "Pop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Population residing in zone"
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of households (non-group and group quarters) residing in zone"
    ),
    item(
      NAME = "NumWkr",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of workers residing in zone"
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

#Iterative proportional fitting function used in Bzone allocation
#----------------------------------------------------------------
#' Iterative proportional fitting function.
#'
#' \code{ipf} fits values in array to match margins.
#'
#' This function uses an iterative proportional fitting algorithm to calculate
#' the values in an array to so that specified margin sums are matched. The
#' function was written specifically to meet the needs of balancing housing
#' units by type and household income quartile by Bzone with the housing demand
#' for households by Azone. The function was not written for general use and
#' so does not contain checks to assure that function arguments are proper.
#'
#' @param Seed_ar A array of starting numbers for the calculation. The
#' dimensions of this array must be the same as the dimensions of the desired
#' result and with the dimensions of the margins used at control totals.
#' @param MrgnVals_ls A list of vectors, matrices, or arrays for margin sum
#' control totals. The list needs to provide controls for each margin of the
#' array. For example, in the case of it's use in this module, two matrices are
#' used as control totals to balance a 3-dimensional array of housing units by
#' Bzone, housing type, and household income quartile. One matrix has control
#' totals by Bzone and housing type. The other matrix has control totals by
#' housing type and income quartile. Note that if one or more margins share the
#' same dimension, the totals for the shared dimension must be the same.
#' @param MrgnDims_ls A list of vectors where each vector identifies the
#' dimensions of the 'Seed_ar' that a margin control corresponds to. For example
#' if the 'Seed_ar' has 3 dimensions and a margin control matrix corresponds to
#' the 2nd and 3rd dimensions of the 'Seed_ar' (i.e. the 1st dimension of the
#' control matrix corresponds to the 2nd dimension of the array and the 2nd
#' dimension of the control matrix corresponds to the 3rd dimension of the
#' array), then the entry for that control matrix would be c(2,3). The number
#' of components in 'MrgnDims_ls' and the order of those components must be
#' consistent with 'MrgnVals_ls'.
#' @param RmseTarget A scalar numeric value specifying the maximum root mean square
#' error between the margin control values and the corresponding array sums. The
#' default value is 1e-7.
#' @param MaxIter A scalar numeric value specifying the maximum number of
#' iterations for balancing the array over the specified dimensions.
#' @return An array containing values that meet the margin controls.
#' @import visioneval
#' @export
ipf <-
  function(Seed_ar, MrgnVals_ls, MrgnDims_ls, RmseTarget = 1e-5, MaxIter = 100) {
    #Eliminate zero values in margins
    MrgnVals_ls <-
      lapply(MrgnVals_ls, function(x) {
        x[x = 0] <- 1e-6
        x
      })
    #Starting value for Units_ar
    Units_ar <- Seed_ar
    #Function to sum up Units_ar by margin
    sumArray <- function(MrgnDims_) {
      apply(Units_ar, MrgnDims_, sum)
    }
    #Function to calculate RMSE error
    rmse <- function() {
      #Make a vector of margin values
      MrgnVals_ <- unlist(lapply(MrgnVals_ls, function(x) as.vector(x)))
      MrgnSums_ <- numeric(0)
      for (i in 1:length(MrgnDims_ls)) {
        MrgnSums_ <- c(MrgnSums_, as.vector(sumArray(MrgnDims_ls[[i]])))
      }
      Err_ <- MrgnVals_ - MrgnSums_;
      sqrt(sum(Err_^2) / (length(Err_)))
    }
    #Balance unit match or iterations exceeded
    NumIter <- 0
    RmseErr <- rmse()
    while (RmseErr > RmseTarget & NumIter < MaxIter) {
      for (i in 1:length(MrgnDims_ls)) {
        MrgnSum_ar <- sumArray(MrgnDims_ls[[i]])
        MrgnAdj_ar <- MrgnVals_ls[[i]] / MrgnSum_ar
        Units_ar <- sweep(Units_ar, MrgnDims_ls[[i]], MrgnAdj_ar, "*")
        Units_ar[Units_ar == 0] <- 1e-6
      }
      RmseErr <- rmse()
      NumIter <- NumIter + 1
    }
    list(Units_ar = Units_ar, NumIter = NumIter, MaxIter = MaxIter, RmseErr = RmseErr)
  }

#Main module function that assigns housing type and Bzone for each household
#---------------------------------------------------------------------------
#' Main module function that assigns the housing type and Bzone for each
#' household.
#'
#' \code{PredictHousing} predicts the housing type and Bzone for each household.
#'
#' This function predicts the housing choice of each household. It uses the
#' estimated models of binomial choice model for determining the probability
#' that the housing choice for each household is single family (SF) vs.
#' multifamily (MF). The group quarters population is assigned to group quarters
#' (GQ). After the housing choice is assigned, the household is assigned to a
#' Bzone based on the input assumptions of:
#' 1) housing supply by type for each Bzone
#' 2) distribution of households by income quartile for each Bzone
#' Housing demand by Bzone, type, and income quartile is balanced allocated
#' by iterative proportional fitting. Households are assigned randomly to Bzones
#' based on their housing choice and income quartile and the balanced quantity
#' of housing in each Bzone by income quartile and housing type.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval stats
#' @export
PredictHousing <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Initialize a vector to store housing type
  HouseType_Hh <- character(length(L$Year$Household$HhId))
  names(HouseType_Hh) <- L$Year$Household$HhId
  #Identify which households are group quarters
  IsGQ_Hh <- L$Year$Household$HhType == "Grp"
  HouseType_Hh[IsGQ_Hh] <- "GQ"

  #Predict housing type for each household
  #---------------------------------------
  #Make data frame of household variables and split by Azone
  Hh_df_Az <-
    split(
      data.frame(L$Year$Household)[!IsGQ_Hh,],
      L$Year$Household$Azone[!IsGQ_Hh]
    )
  Az <- names(Hh_df_Az)
  for (az in Az) {
    #Calculate the single family housing proportion
    SFDU <- sum(L$Year$Bzone$SFDU[L$Year$Bzone$Azone == az])
    MFDU <- sum(L$Year$Bzone$MFDU[L$Year$Bzone$Azone == az])
    PropSFDU <- SFDU / (SFDU + MFDU)
    #Predict housing type
    HouseType_ <- applyBinomialModel(
      HouseTypeModel_ls,
      Hh_df_Az[[az]],
      TargetProp = PropSFDU
    )
    Hh_df_Az[[az]]$HouseType <- HouseType_
    names(HouseType_) <- Hh_df_Az[[az]]$HhId
    HouseType_Hh[names(HouseType_)] <- HouseType_
    rm(SFDU, MFDU, PropSFDU, HouseType_)
  }

  #Tabulate households by house type, income quartile, and Azone
  #-------------------------------------------------------------
  #Calculate regional income quartiles for households
  IncQBreaks_ <-
    quantile(L$Year$Household$Income[!IsGQ_Hh], c(0, 0.25, 0.5, 0.75, 1))
  Iq <- c("IncQ1", "IncQ2", "IncQ3", "IncQ4")
  #Create overall vector to keep results
  IncQ_Hh <- character(length(L$Year$Household$HhId))
  names(IncQ_Hh) <- L$Year$Household$HhId
  IncQ_Hh[IsGQ_Hh] <- "NA"
  #Calculate income quartile of each household
  for (az in Az) {
    Hh_df_Az[[az]]$IncQ <-
      cut(Hh_df_Az[[az]]$Income,
          breaks = IncQBreaks_,
          labels = Iq,
          include.lowest = TRUE)
    IncQ_ <- as.character(Hh_df_Az[[az]]$IncQ)
    names(IncQ_) <- Hh_df_Az[[az]]$HhId
    IncQ_Hh[names(IncQ_)] <- IncQ_
    rm(IncQ_)
  }
  rm(az, IncQBreaks_)
  #Tabulate households by house type and income quartile by Azone
  Ht <- c("SF", "MF")
  HhTab_HtIq_Az <-
    lapply(Hh_df_Az, function(x) table(x$HouseType, x$IncQ)[Ht,Iq])

  #Tabulate housing unit inputs by Bzone and housing type
  #------------------------------------------------------
  InitUnits_BzHt <-
    as.matrix(data.frame(L$Year$Bzone[c("SFDU", "MFDU")]))
  rownames(InitUnits_BzHt) <- L$Year$Bzone$Bzone
  colnames(InitUnits_BzHt) <- Ht

  #Tabulate input assumptions of household income distribution for each Bzone
  #--------------------------------------------------------------------------
  #Extract matrix of input assumptions of Bzone unit proportions by income
  HhIqProp_BzIq <-
    cbind(IncQ1 = L$Year$Bzone$HhPropIncQ1,
          IncQ2 = L$Year$Bzone$HhPropIncQ2,
          IncQ3 = L$Year$Bzone$HhPropIncQ3,
          IncQ4 = L$Year$Bzone$HhPropIncQ4)
  Bz <- L$Year$Bzone$Bzone
  rownames(HhIqProp_BzIq) <- Bz
  #Make sure that rows add to 1
  HhIqProp_BzIq <- t(apply(HhIqProp_BzIq, 1, function(x) x / sum(x)))

  #Balance housing units with housing demand and assign households to locations
  #----------------------------------------------------------------------------
  #Each Azone is a housing market. The number of housing units by type and
  #income quartile for Bzones in the Azone is balanced with the number of
  #households by house type and income quartile. Iterative proportional fitting
  #(IPF) is used to balance housing units over 3 dimensions: Bzone, unit type,
  #and income quartile. Two matrixes are used as margin control totals for the
  #balancing process. The first is a matrix of demand by housing type and income
  #quartile which is calculated above by Azone (HhTab_HtIq_Az). The second is a
  #matrix of units by Bzone and housing type. This matrix is created by scaling
  #the number of input units by Bzone and housing type to match the demand by
  #housing type. Scaled values are converted to whole numbers in the process.
  #The seed matrix for the IPF uses the input assumptions for proportion of
  #households by type (bzone_hh_inc_qrtl_prop.csv input file) to arrive at a
  #balanced distribution of households by income for each Bzone that reflects
  #household income differences among Bzones. After units are allocated to
  #Bzones to match the number of units demanded by households, each household is
  #assigned to a Bzone. This is done by iterating through each housing type and
  #income quartile combination and:
  #1) Extract the vector of units by Bzone for the type/quartile combination,
  #2) Using the vector as replication weights to replicate the Bzone names
  #3) Randomize the Bzone name vector
  #4) Assign the randomized Bzone name vector to households matching the
  #type/quartile combination.
  #Allocate households to Bzones
  #Create vector of household assignments to Bzones
  Bzone_Hh <- character(length(L$Year$Household$HhId))
  names(Bzone_Hh) <- L$Year$Household$HhId
  #Assign households to Bzones by Azone
  for (az in Az) {
    #Create matrices of margin totals
    #--------------------------------
    #Identify Bzones located in the Azone
    Bx <- L$Year$Bzone$Bzone[L$Year$Bzone$Azone == az]
    #Extract the unit demand by type and income quartile for households in Azone
    UnitDemand_HtIq <- HhTab_HtIq_Az[[az]]
    UnitDemand_Ht <- rowSums(UnitDemand_HtIq)
    #Extract the initial number of housing units by type for Bzones in Azone
    InitUnits_BxHt <- InitUnits_BzHt[Bx,]
    #Calculate the initial Bzone proportions of units for each type
    BxPropUnits_BxHt <- sweep(InitUnits_BxHt, 2, colSums(InitUnits_BxHt), "/")
    #Calculate matrix of unit demand by Bzone and type
    UnitDemand_BxHt <- sweep(BxPropUnits_BxHt, 2, UnitDemand_Ht, "*")
    #Convert to whole numbers
    UnitDemand_BxHt <- round(UnitDemand_BxHt)
    UnitDiff_Ht <- UnitDemand_Ht - colSums(UnitDemand_BxHt)
    for (i in 1:2) {
      UnitDiff_By <- table(
        sample(Bx, abs(UnitDiff_Ht[i]), replace = TRUE, prob = BxPropUnits_BxHt[,i]))
      UnitDemand_BxHt[names(UnitDiff_By), i] <-
        UnitDemand_BxHt[names(UnitDiff_By), i] + sign(UnitDiff_Ht[i]) * UnitDiff_By
      rm(UnitDiff_By)
    }
    rm(i, BxPropUnits_BxHt)

    #Create seed array for IPF balancing of units by Bzone, type, and income
    #-----------------------------------------------------------------------
    HhIqProp_BxIq <- HhIqProp_BzIq[Bx,]
    Seed_BxHtIq <-
      array(1, dim = c(length(Bx), length(Ht), length(Iq)), dimnames = list(Bx,Ht,Iq))
    for (bx in Bx) {
      Seed_BxHtIq[bx,,] <- outer(UnitDemand_BxHt[bx,], HhIqProp_BxIq[bx,])
    }
    Seed_BxHtIq[Seed_BxHtIq == 0] <- 1e-6

    #Balance unit demand for each Bzone by unit type and income quartile
    #-------------------------------------------------------------------
    #Use IPF to allocate unit demand to Bzones, unit types, and income quartile
    Ipf_ls <-
      ipf(Seed_BxHtIq,
          MrgnVals_ls = list(UnitDemand_BxHt, UnitDemand_HtIq),
          MrgnDims_ls = list(c(1,2), c(2,3)))
    Units_BxHtIq <- Ipf_ls$Units_ar
    if (Ipf_ls$NumIter == Ipf_ls$MaxIter) {
      Msg <-
        paste0("Warning for PredictHousing module. ",
               "Balancing of housing units by Bzone, housing type,",
               "and income quartile in Azone ", az,
               " went to maximum number of iterations (", Ipf_ls$MaxIter,
               ") without achieving RMSE criterion for margin control totals. ",
               " RMSE error achieved was ", Ipf_ls$RmseErr, ".")
      writeLog(Msg)
      rm(Msg)
    }
    rm(Seed_BxHtIq, UnitDemand_BxHt, Ipf_ls)
    #Convert allocation to whole numbers
    Units_BxHtIq <- round(Units_BxHtIq)
    Units_HtIq <- apply(Units_BxHtIq, c(2,3), sum)
    UnitDiff_HtIq <-  UnitDemand_HtIq - Units_HtIq
    BxPropUnits_BxHtIq <- sweep(Units_BxHtIq, c(2,3), Units_HtIq, "/")
    for (ht in Ht) {
      for (iq in Iq) {
        UnitDiff_By <- table(
          sample(Bx, abs(UnitDiff_HtIq[ht,iq]), replace = TRUE, prob = BxPropUnits_BxHtIq[,ht,iq]))
        Units_BxHtIq[names(UnitDiff_By),ht,iq] <-
          Units_BxHtIq[names(UnitDiff_By),ht,iq] + sign(UnitDiff_HtIq[ht,iq]) * UnitDiff_By
        rm(UnitDiff_By)
      }
    }
    rm(UnitDiff_HtIq, BxPropUnits_BxHtIq, ht, iq)
    #Assign Bzones to households based on housing type and income quartile
    #---------------------------------------------------------------------
    Hh_df_Az$Bzone <- ""
    for (ht in Ht) {
      for (iq in Iq) {
        Bzone_ <- sample(rep(Bx, Units_BxHtIq[,ht,iq]))
        IsHh_ <-
          with(Hh_df_Az[[az]], HouseType == ht & IncQ == iq)
        Hh_df_Az[[az]]$Bzone[IsHh_] <- Bzone_
        rm(Bzone_, IsHh_)
      }
    }
    #Put results in Bzone_Hh
    Bzone_Hx <- Hh_df_Az[[az]]$Bzone
    names(Bzone_Hx) <- Hh_df_Az[[az]]$HhId
    Bzone_Hh[names(Bzone_Hx)] <- Bzone_Hx
    rm(Bzone_Hx)
  }

  #Assign group quarters households to Bzones
  #------------------------------------------
  #Iterate through Azones to assign Bzones
  for (az in Az) {
    #Get inventory of group quarters units by Bzone
    GQUnits_Bx <- L$Year$Bzone$GQDU[L$Year$Bzone$Azone == az]
    Bx <- L$Year$Bzone$Bzone[L$Year$Bzone$Azone == az]
    names(GQUnits_Bx) <- Bx
    #Calculate demand
    GQUnitDemand <- sum(IsGQ_Hh[L$Year$Household$Azone == az])
    #Scale Bzone demand to match overall demand
    GQUnitDemand_Bx <- round(GQUnitDemand * GQUnits_Bx / sum(GQUnits_Bx))
    UnitDiff <- GQUnitDemand - sum(GQUnitDemand_Bx)
    UnitDiff_By <-
      table(sample(Bx, abs(UnitDiff), replace = TRUE,
                   prob = GQUnitDemand_Bx / sum(GQUnitDemand_Bx)))
    GQUnitDemand_Bx[names(UnitDiff_By)] <-
      GQUnitDemand_Bx[names(UnitDiff_By)] + UnitDiff_By * sign(UnitDiff)
    #Assign group quarters units in Bzones to group quarters households
    Bzone_Hx <- sample(rep(Bx, GQUnitDemand_Bx))
    names(Bzone_Hx) <-
      L$Year$Household$HhId[IsGQ_Hh & L$Year$Household$Azone == az]
    Bzone_Hh[names(Bzone_Hx)] <- Bzone_Hx
  }

  #Tabulate households, population, workers, and units by Bzone
  #------------------------------------------------------------
  Bz <- L$Year$Bzone$Bzone
  NumHh_Bz <- tapply(Bzone_Hh, Bzone_Hh, length)[Bz]
  Pop_Bz <- tapply(L$Year$Household$HhSize, Bzone_Hh, sum)[Bz]
  NumWkr_Bz <- tapply(L$Year$Household$Workers, Bzone_Hh, sum)[Bz]
  SF_Bz <- tapply(HouseType_Hh == "SF", Bzone_Hh, sum)[Bz]
  MF_Bz <- tapply(HouseType_Hh == "MF", Bzone_Hh, sum)[Bz]
  GQ_Bz <- tapply(HouseType_Hh == "GQ", Bzone_Hh, sum)[Bz]

  #Return list of results
  #----------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(Bzone = character(0),
         HouseType = character(0))
  Out_ls$Year$Bzone <-
    list(SF = integer(0),
         MF = integer(0),
         GQ = integer(0),
         Pop = integer(0),
         NumHh = integer(0),
         NumWkr = integer(0))
  #Add the household Bzone assignments to the list
  Out_ls$Year$Household$Bzone <- unname(Bzone_Hh)
  #Add SIZE attribute for the household Bzone assignments
  attributes(Out_ls$Year$Household$Bzone)$SIZE <- max(nchar(Bzone_Hh))
  #Add the household housing type assignments to the list
  Out_ls$Year$Household$HouseType <- unname(HouseType_Hh)
  #Add the dwelling unit demand numbers by Bzone
  Out_ls$Year$Bzone$SF <- as.integer(unname(SF_Bz))
  Out_ls$Year$Bzone$MF <- as.integer(unname(MF_Bz))
  Out_ls$Year$Bzone$GQ <- as.integer(unname(GQ_Bz))
  #Add the population, households, and workers by Bzone
  Out_ls$Year$Bzone$Pop <- as.integer(unname(Pop_Bz))
  Out_ls$Year$Bzone$NumHh <- as.integer(unname(NumHh_Bz))
  Out_ls$Year$Bzone$NumWkr <- as.integer(unname(NumWkr_Bz))
  #Return the outputs list
  Out_ls

  #Return the Out_ls
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
#   ModuleName = "PredictHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
