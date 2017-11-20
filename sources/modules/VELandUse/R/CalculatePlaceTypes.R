#================
#CalculatePlaceTypes.R
#================
# This module calculates place types for households and firms. There are thirteen place types which
# comprise of a combination of four area types (urban core, close-in community, suburban, and rural)
# and five development categories (residential, commercial, mixed-use, transit-oriented development, and
# greenfield)

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

## Suggest to do : Household allocation model estimation
load("./data/HhAllocationModelCoeff.rda")
HhAllocationModelCoeff_df <- HhAllocationModelCoeff
rm(HhAllocationModelCoeff)

# Save the household allocation model coefficients
#--------------------------------------------------
#' Household Allocation Model
#'
#' A data.frame containing coefficients of variables needed to
#' implement household allocation model
#'
#' @format A data.frame having the following components
#' \describe{
#'   \item{CHID}{a numeric indicating a area type}
#'   \item{CHDESC}{a string indicating a area type (City, Rural, Suburban, Town, and Urban)}
#'   \item{VAR}{a string indicating the variable names (ASC, Singleton, Children, CoupleNoKids,
#'   OnlyElderly, HhIncome1000)}
#'   \item{COEFF}{a numeric value for coefficients}
#' }
#' @source CalculatePlaceTypes.R script.
"HhAllocationModelCoeff_df"
devtools::use_data(HhAllocationModelCoeff_df, overwrite = TRUE)

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculatePlaceTypesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "Pop",
          "Emp"),
      FILE = "bzone_pop_emp_prop.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = 2,
      DESCRIPTION =
        items(
          "Proportion of Bzone Population in the entire Azone",
          "Proportion of Bzone Employment in the entire Azone"
        )
      )
  ),
  #Specify data to be loaded from data store
  Get = items(
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
        items("Pop",
              "Emp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item("HhId"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Age0to14",
              "Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
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
      NAME = item("Income"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.1999",
      NAVALUE = -1,
      PROHIBIT = c("NA","< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        item("naics"),
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "naics",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "esizecat",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "numbus",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "businesses",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "emp",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "employees",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "DrvLevels",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Drv1", "Drv2", "Drv3Plus"),
      UNLIKELY = "",
      DESCRIPTION = "The number of people who can drive"
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      DESCRIPTION = "A list of place types as assigned to the households"
    ),
    item(
      NAME = "EmpPlaceTypes",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      DESCRIPTION = "A list of place types as assigned to the businesses"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculatePlaceTypes module
#'
#' A list containing specifications for the CalculatePlaceTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculatePlaceTypes.R script.
"CalculatePlaceTypesSpecifications"
devtools::use_data(CalculatePlaceTypesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================



# Function to add structure to households
#----------------------------------------------
#' Add structure to households
#'
#' \code{addHhldStructure} adds detail structure to
#' the households.
#'
#' The function takes a data.frame of households in a region and adds
#' variables required by HhldAllocationModel.
#'
#' @param Hhld A data.frame of households containing population by age
#' group.
#' @return A data.frame of households with added variables
#'
#' @export
addHhldStructure <- function(Hhld) {
  # Define the age groups
  Ag <- c(
    "Age0to14",
    "Age15to19",
    "Age20to29",
    "Age30to54",
    "Age55to64",
    "Age65Plus"
    )

  # Calculate the driving age population
  Hhld$DrvAgePop <- rowSums(Hhld[, Ag[-1]])

  rm(Ag)

  # Add a variable identifying driver population levels
  DrvLevels_ <- c(0, 1, 2, max(Hhld$DrvAgePop))
  DrvLevelsName_ <- c("Drv1", "Drv2", "Drv3Plus")
  Hhld$DrvLevels <- as.character(cut(Hhld$DrvAgePop,
                                     breaks = DrvLevels_,
                                     labels = DrvLevelsName_))
  rm(DrvLevels_, DrvLevelsName_)

  # Add a variable identifying households having only elderly persons
  Hhld$OnlyElderly <- as.numeric( Hhld$DrvAgePop == Hhld$Age65Plus )

  # Add a variable identifying households having children
  Hhld$Children <- as.numeric( Hhld$Age0to14 > 0 )

  # Add a variable identifying households having only one working age person
  Hhld$Singleton <- as.numeric( Hhld$Age0to14 == 0 & Hhld$Age65Plus == 0 & Hhld$HhSize == 1 )

  # Add a variable identifying households having two people, no kids <15
  Hhld$CoupleNoKids <- as.numeric( Hhld$Age0to14 == 0 & Hhld$Age65Plus == 0 & Hhld$HhSize == 2 )

  return(Hhld)
}

# Function to make prediction from a logit model
#----------------------------------------------
#' Make prediction from a multinomial logit model
#'
#' \code{predictLogit} function makes prediction given a set of data
#' and corresponding coefficients
#'
#' The function takes a data.frame of model data and coefficient data
#' that are required in making prediction of the type of area or development
#' for a household
#' @param ModelData A data.frame model data containing all the necessary variables.
#' @param ModelCoeffs A data.frame of coefficients of the variables required by the model.
#' @return An array of predictions
#'
#' @export
predictLogit <- function(ModelData,ModelCoeffs){
  # Get the total number of choices
  NumChoices_ <- max(ModelCoeffs$CHID)

  # Initialize utility variabe names
  UtilVars_ <- ""

  # Get variable names
  VarNames_ <- colnames(ModelData)

  # Get the probability of making each choice
  for(choice in 1:NumChoices_)
  {
    # Get the model coefficients
    SubCoeffs_ <- ModelCoeffs[ModelCoeffs$CHID==choice,]

    # Create a utility name
    Var_ <- paste0("eutil_", choice)
    # Append the utility name
    UtilVars_ <- c(UtilVars_, Var_)

    # Use only the variables that have the coefficients
    UseVars_ <- VarNames_[match(SubCoeffs_$VAR, VarNames_)]

    # Order the model coefficients as observed in the model data
    SubCoeffs_ <- SubCoeffs_[match(UseVars_, SubCoeffs_$VAR), ]

    # Calculate the odds
    if(length(UseVars_) > 1){
      ModelData[,Var_] <- exp(rowSums(sweep(ModelData[ ,UseVars_], MARGIN = 2,
                                            STATS = SubCoeffs_$COEFF, FUN = "*")))
    } else {
      ModelData[ ,Var_] <- exp(ModelData[,UseVars_] * SubCoeffs_$COEFF)
    }

  } #end for
  UtilVars_ <- UtilVars_[-1]

  # Create a cumulative probability distribution from the model
  ModelData[ ,UtilVars_] <- data.frame(prop.table(as.matrix(ModelData[ ,UtilVars_]), margin = 1))
  Utils_ <- as.matrix(ModelData[ ,UtilVars_])
  Utils_  <- apply(Utils_, 1, cumsum)
  ModelData[ ,UtilVars_] <- data.frame(t(Utils_))

  # Generate a uniform random variable
  ModelData$temprand <- runif(nrow(ModelData))

  # Initialize the prediction
  ModelData$simchoice <- 0

  # Make prediction based on the random variable generated
  for(choice in 1:NumChoices_){
    if(choice == 1){
      ModelData$simchoice[ModelData$temprand < ModelData[ ,UtilVars_[choice]]] <- choice
    } else {
      ModelData$simchoice[ModelData$temprand >= ModelData[ ,UtilVars_[choice-1]] & ModelData$temprand < ModelData[,UtilVars_[choice]]] <- choice
    }
  }

  # Remove unnecessary variables
  rm(NumChoices_, UtilVars_, choice, SubCoeffs_, Var_, Utils_, VarNames_)

  return(ModelData$simchoice)
}

# Function to run a logit model iteratively
#----------------------------------------------
#' Run a logit model iteratively
#'
#' \code{runLogit} function iteratively runs a logit model
#' to match a given target.
#'
#' The function takes a data.frame of model data and coefficient data to run a
#' a logit model and
#' for a household
#' @param HhldPop A data.frame containing population by for each household by age groups.
#' @param ModelData A data.frame model data containing all the necessary variables.
#' @param ModelCoeffs A data.frame of coefficients of the variables required by the model.
#' @param TargetPop An array target population to be matched by the logit model.
#' @param MaxIter Maximum number of iteration to run the logit model (Default: 10).
#' @param QuitCriteria The quitting criteria for the logit model (Default: 4000).
#' @return An array of predictions
#'
#' @export
runLogit <- function(HhldPop = NULL, ModelData = NULL, ModelCoeffs = NULL, TargetPop = NULL,
                     TargetGroups = NULL, MaxIter = 10, QuitCriteria = 4000){
  if(is.null(ModelData)){
    stop("No model data found. The function runLogit requires a model data.")
  } else if(is.null(ModelCoeffs)){
    stop("No model coefficients found. The function runLogit requires a data
         containing model coefficients.")
  } else if(is.null(TargetPop) | is.null(TargetGroups)){
    stop("No model targets found. The function runLogit requires an arrray of
         targets to match the output of logit model.")
  } else if(MaxIter < 0){
    stop("The runLogit function at least needs to run for 1 iteration.")
  }

  # Loop through the number of iterations
  for(iter in seq_len(MaxIter)){
    # Make prediction
    ModelPrediction_ <- predictLogit(ModelData, ModelCoeffs)

    # Assign targets using the predictions
    ModelPrediction <- TargetGroups[ModelPrediction_]

    # Calculate model population by targets
    ModelPop_ <- rowSums(rowsum(HhldPop, ModelPrediction))

    # Remove NAs
    ModelPop_[is.na(ModelPop_)] <- 0

    # Reorder the model population to match the target population
    ModelPop_ <- ModelPop_[names(TargetPop)]

    # Verify the quitting criteria
    if(sum(abs(TargetPop - ModelPop_)) < QuitCriteria){
      break
    }

    # Make adjustments to model constants
    ASC_adjust <- log(TargetPop/ModelPop_)
    ModelCoeffs$COEFF[ModelCoeffs$VAR == "ASC"] <- ASC_adjust[TargetGroups] +
      ModelCoeffs$COEFF[ModelCoeffs$VAR == "ASC"]
  }

  # Remove unnecessary variables
  rm(iter, ModelPrediction_, ModelPop_, ASC_adjust)

  return(ModelPrediction)
}

#Main module function that assigns place-types (Bzone) to households and firms
#---------------------------------------------------------------------------
#' Main module function that assigns the place-types (Bzone) to each
#' household and firm.
#'
#' \code{CalculatePlaceTypes} assigns place-types to each household and firm.
#'
#' This function allocates place-types to households and firms. It uses the
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
#' @import visioneval
#' @export
CalculatePlaceTypes <- function(L) {
  # Set up
  #-----------
  # Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  # Get the houhold data into a data.frame
  Hhlds <- cbind.data.frame(L$Year$Household)

  # Get the age groups
  Ag <- grep("^Ag", colnames(Hhlds), value = TRUE)

  #Calculate total population, households, and employment.
  TotalPop <- sum(colSums(Hhlds[ ,Ag]))
  TotalHhld <- nrow(Hhlds)
  TotalEmp <- sum(L$Year$Business$emp)

  # Calculate the place type population and employment proportions
  TotalPop_Pt <- TotalPop * L$Year$Bzone$Pop
  TotalEmp_Pt <- TotalEmp * L$Year$Bzone$Emp
  names(TotalPop_Pt) <- L$Year$Bzone$Bzone
  names(TotalEmp_Pt) <- L$Year$Bzone$Bzone

  # Round population to a whole number
  TotalPop_Pt <- round(TotalPop_Pt)

  # Correct the rounding error
  if(sum(TotalPop_Pt) != TotalPop) {
    PopDiff <- TotalPop - sum(TotalPop_Pt)
    Sign <- sign(PopDiff)
    Probs_Pt <- TotalPop_Pt / sum(TotalPop_Pt)
    PopDiff_ <- sample(L$Year$Bzone$Bzone, abs(PopDiff), replace = TRUE, prob = Probs_Pt)
    PopDiff_Pt <- Sign * table(PopDiff_)[ L$Year$Bzone$Bzone ]
    names(PopDiff_Pt) <- L$Year$Bzone$Bzone
    PopDiff_Pt[ is.na(PopDiff_Pt) ] <- 0
    TotalPop_Pt_attr <- attributes(TotalPop_Pt)
    TotalPop_Pt <- TotalPop_Pt + PopDiff_Pt
    attributes(TotalPop_Pt) <- TotalPop_Pt_attr
    rm(PopDiff, Sign, Probs_Pt, PopDiff_, PopDiff_Pt, TotalPop_Pt_attr)
  }
  # Further correction of rounding error
  if(any(TotalPop_Pt < 0)) {
    PopDiff <- sum(TotalPop_Pt[ TotalPop_Pt < 0 ])
    TotalPop_Pt[ TotalPop_Pt < 0 ] <- 0
    Probs_Pt <- TotalPop_Pt / sum(TotalPop_Pt)
    PopDiff_ <- sample(L$Year$Bzone$Bzone, abs(PopDiff), replace = TRUE, prob = Probs_Pt)
    PopDiff_Pt <- table(PopDiff_)[ L$Year$Bzone$Bzone ]
    names(PopDiff_Pt) <- L$Year$Bzone$Bzone
    PopDiff_Pt[ is.na(PopDiff_Pt) ] <- 0
    TotalPop_Pt_attr <- attributes(TotalPop_Pt)
    TotalPop_Pt <- TotalPop_Pt - PopDiff_Pt
    attributes(TotalPop_Pt) <- TotalPop_Pt_attr
    rm(PopDiff, Probs_Pt, PopDiff_, PopDiff_Pt, TotalPop_Pt_attr)
  }

  # Round employment to a whole number
  TotalEmp_Pt <- round(TotalEmp_Pt)

  # Correct the rounding error
  if(sum(TotalEmp_Pt) != TotalEmp) {
    EmpDiff <- TotalEmp - sum(TotalEmp_Pt)
    Sign <- sign(EmpDiff)
    Probs_Pt <- TotalEmp_Pt / sum(TotalEmp_Pt)
    EmpDiff_ <- sample(L$Year$Bzone$Bzone, abs(EmpDiff), replace = TRUE, prob = Probs_Pt)
    EmpDiff_Pt <- Sign * table(EmpDiff_)[ L$Year$Bzone$Bzone ]
    names(EmpDiff_Pt) <- L$Year$Bzone$Bzone
    EmpDiff_Pt[ is.na(EmpDiff_Pt) ] <- 0
    TotalEmp_Pt_attr <- attributes(TotalEmp_Pt)
    TotalEmp_Pt <- TotalEmp_Pt + EmpDiff_Pt
    attributes(TotalEmp_Pt) <- TotalEmp_Pt_attr
    rm(EmpDiff, Sign, Probs_Pt, EmpDiff_, EmpDiff_Pt, TotalEmp_Pt_attr)
  }
  # Further correction of rounding error
  if(any(TotalEmp_Pt < 0)) {
    EmpDiff <- sum(TotalEmp_Pt[ TotalEmp_Pt < 0 ])
    TotalEmp_Pt[ TotalEmp_Pt < 0 ] <- 0
    Probs_Pt <- TotalEmp_Pt / sum(TotalEmp_Pt)
    EmpDiff_ <- sample(L$Year$Bzone$Bzone, abs(EmpDiff), replace = TRUE, prob = Probs_Pt)
    EmpDiff_Pt <- table(EmpDiff_)[ L$Year$Bzone$Bzone ]
    names(EmpDiff_Pt) <- L$Year$Bzone$Bzone
    EmpDiff_Pt[ is.na(EmpDiff_Pt) ] <- 0
    TotalEmp_Pt_attr <- attributes(TotalEmp_Pt)
    TotalEmp_Pt <- TotalEmp_Pt - EmpDiff_Pt
    attributes(TotalEmp_Pt) <- TotalEmp_Pt_attr
    rm(EmpDiff, Probs_Pt, EmpDiff_, EmpDiff_Pt, TotalEmp_Pt_attr)
  }

  # Assign employment locations randomly to the place types
  Prob_Pt <- TotalEmp_Pt / sum(TotalEmp_Pt)
  Prob_Pt[Prob_Pt < 0]  <- 0
  Emp_Pt <- sample(L$Year$Bzone$Bzone, length(L$Year$Business$emp), replace = TRUE, prob = Prob_Pt)

  ## Get the area and location types
  PlaceTypes <- do.call(rbind.data.frame, strsplit(L$Year$Bzone$Bzone, "_", fixed = TRUE))
  colnames(PlaceTypes) <- c("At", "DevT")
  PlaceTypes$At <- as.character(PlaceTypes$At)
  PlaceTypes$DevT <- as.character(PlaceTypes$DevT)

  # Calculate area type targets for the Hhld allocation (Works only with thirteen placetypes)
  Target_At <- rowsum(TotalPop_Pt, PlaceTypes$At)[,1]
  # Replace zero values with a small value
  Target_At[Target_At == 0] <- 1

  # Initialize population by area types
  TotalPop_At <- Target_At * 0
  AreaTypes <- names(TotalPop_At)

  # Apply HHAllocationModel
  # Create all the variables that are required for simulating the choice

  # Add structure to the household data.frame
  Hhlds <- addHhldStructure(Hhld = Hhlds)
  Hhlds$ASC <- 1
  Hhlds$HhIncome1000 <- Hhlds$Income/1E3

  ModelVar_ <- c("ASC",
                 "Singleton",
                 "Children",
                 "CoupleNoKids",
                 "OnlyElderly",
                 "HhIncome1000")

  ModelCoeffs_At_Correspondence <- c("CIC", "Rur", "Sub", "Rur", "UC")

  # Assign area types to households
  Hhlds$AreaType <- runLogit(HhldPop = Hhlds[ ,Ag], ModelData = Hhlds[ ,ModelVar_],
                             ModelCoeffs = HhAllocationModelCoeff_df, TargetPop = Target_At,
                            TargetGroups = ModelCoeffs_At_Correspondence)


  browser()
  # Reassign any housholds assigned to an area where there should be zero
  Target_AtR <- rowsum(TotalPop_Pt, PlaceTypes$At)[,1]
  Hhlds$AreaType[Hhlds$AreaType == names(Target_AtR[Target_AtR == 0])] <- names(Target_AtR[which.max(Target_AtR)])[1]

  # Assign development types to households: draw randomly for each area type
  # Calculate development type targets for the hh allocation
  #
  Target_Pt <- Target_At[PlaceTypes$At]
  Prob_Pt <- TotalPop_Pt/Target_Pt
  names(Prob_Pt) <- PlaceTypes$At

  for(At in AreaTypes){
    if(sum(Prob_Pt[PlaceTypes$At == At]) > 0){
      Hhlds$DevType[Hhlds$AreaType == At] <- sample(PlaceTypes$DevT[PlaceTypes$At == At], sum(Hhlds$AreaType == At),
                                                    replace = TRUE, prob = Prob_Pt[PlaceTypes$At == At])
    }
  }

  # Assign place type based on area type and development type
  Hhlds$PlaceType <- paste0(Hhlds$AreaType,"_",Hhlds$DevType)
  Hhlds$PlaceType[Hhlds$AreaType == "Rur"] <- "Rur"

  # Average Density
  ## Should this be a calculate average for the region (by CS from older RPAT)?
  Hhlds$Htppopdn <- 500 # AG Is this a model parameter?

  ## Should this be 0 for rural? Or are we just using an average for both density and this var and then adjusting using 5D values? (By CS from older RPAT)
  Hhlds$Urban <- 1 # AG Is this a model parameter?

  # Calculate the natural log of density
  Hhlds$LogDen <- log(Hhlds$Htppopdn)

  # Update TotalPop_Pt and TotalEmp_Pt so they reflect actual assigned population and employment rather than input proportions.
  TotalPop_Pt[L$Year$Bzone$Bzone] <- rowSums(rowsum(Hhlds[ ,Ag], Hhlds$PlaceType))[L$Year$Bzone$Bzone]
  TotalPop_Pt[is.na(TotalPop_Pt)] <- 0

  TotalEmp_Pt[L$Year$Bzone$Bzone] <- rowsum(L$Year$Business$emp, Emp_Pt)[,1][L$Year$Bzone$Bzone]
  TotalEmp_Pt[is.na(TotalEmp_Pt)] <- 0

  # Sum income by development type
  TotalIncome_Pt <- rep(0, length(L$Year$Bzone$Bzone))
  names(TotalIncome_Pt) <- L$Year$Bzone$Bzone
  TotalIncome_Pt[L$Year$Bzone$Bzone] <- rowsum(Hhlds$Income, Hhlds$PlaceType)[,1][L$Year$Bzone$Bzone]
  TotalIncome_Pt[is.na(TotalIncome_Pt)] <- 0

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()


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

