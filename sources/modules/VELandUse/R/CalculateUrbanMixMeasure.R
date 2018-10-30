#==========================
#CalculateUrbanMixMeasure.R
#==========================
#This module calculates an urban mixed-use measure based on the 2001 National
#Household Travel Survey measure of the tract level urban/rural indicator. This
#measure developed by Claritas uses the density of the tract and surrounding
#tracts to identify the urban/rural context of the tract. The categories include
#urban, suburban, second city, town and rural. Mapping of example metropolitan
#areas shows that places shown as urban correspond to central city and inner
#neighborhoods characterized by mixed use, higher levels of urban accessibility,
#and higher levels of walk/bike/transit accessibility.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#Define a function to estimate urban mixed-use model
#---------------------------------------------------
#' Estimate urban mixed-use model
#'
#' \code{estimateUrbanMixModel} estimates a binomial logit model for identifying
#' whether a household lives in an urban mixed-use neighborhood.
#'
#' This function estimates a binomial logit model for predicting whether a
#' household is living in an urban mixed-use neighborhood.
#'
#' @param EstData_df A data frame containing estimation data.
#' @param StartTerms_ A character vector of the terms of the model to be
#' tested in the model. The function estimates the model using these terms
#' and then drops all terms whose p value is greater than 0.05.
#' @return A list which has the following components:
#' Type: a string identifying the type of model ("binomial"),
#' Formula: a string representation of the model equation,
#' PrepFun: a function that prepares inputs to be applied in the binomial model,
#' OutFun: a function that transforms the result of applying the binomial model.
#' Summary: the summary of the binomial model estimation results.
#' @import visioneval stats
estimateUrbanMixModel <- function(EstData_df, StartTerms_) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <-
    function(In_df) {
      Out_df <- In_df
      Out_df$Intercept <- 1
      Out_df
    }
  #Define function to make the model formula
  makeFormula <-
    function(StartTerms_) {
      FormulaString <-
        paste("UrbanMix ~ ", paste(StartTerms_, collapse = "+"))
      as.formula(FormulaString)
    }
  #Estimate model
  UrbanMixModel <-
    glm(makeFormula(StartTerms_), family = binomial, data = EstData_df)
  #Return model
  list(
    Type = "binomial",
    Formula = makeModelFormulaString(UrbanMixModel),
    Choices = c(1, 0),
    PrepFun = prepIndepVar,
    Summary = summary(UrbanMixModel)
  )
}

#Estimate the binomial logit model for urban mixed-use
#-----------------------------------------------------
#Create model estimation dataset
NhtsHometype_ <- VE2001NHTS::Hh_df$Hometype
HouseType_ <- rep("SF", length(NhtsHometype_))
HouseType_[NhtsHometype_ == "Dorm"] <- "GQ"
HouseType_[NhtsHometype_ %in% c("Duplex", "Multi-family", "Other")] <- "MF"
Data_df <-
  data.frame(
    UrbanMix = VE2001NHTS::Hh_df$UrbanDev,
    LocalPopDensity = VE2001NHTS::Hh_df$Hbppopdn,
    IsSF = as.numeric(HouseType_ == "SF"))
Data_df <- Data_df[complete.cases(Data_df),]
rm(NhtsHometype_, HouseType_)
#Estimate the model
UrbanMixModel_ls <-
  estimateUrbanMixModel(
    EstData_df = Data_df,
    StartTerms_ = c("LocalPopDensity", "IsSF")
  )
#Test a search range for matching proportions
UrbanMixModel_ls$SearchRange <- c(-10, 10)
applyBinomialModel(
  UrbanMixModel_ls,
  Data_df,
  TargetProp = NULL,
  CheckTargetSearchRange = TRUE)
#Check that low target can be matched with search range
Target <- 0.01
LowResult_ <- applyBinomialModel(
  UrbanMixModel_ls,
  Data_df,
  TargetProp = Target
)
Result <- round(table(LowResult_) / length(LowResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, LowResult_, Result)
#Check that high target can be matched with search range
Target <- 0.99
HighResult_ <- applyBinomialModel(
  UrbanMixModel_ls,
  Data_df,
  TargetProp = Target
)
Result <- round(table(HighResult_) / length(HighResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, HighResult_, Result)
rm(Data_df)

#Save the urban mixed-use model
#------------------------------
#' Urban mixed-use model
#'
#' A list containing the model equation and other information needed to
#' implement the urban mixed-use model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("binomial")}
#'   \item{Formula}{makeModelFormulaString(UrbanMixModel)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the model}
#'   \item{Summary}{the summary of the binomial logit model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source CalculateUrbanMixMeasure.R script.
"UrbanMixModel_ls"
usethis::use_data(UrbanMixModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateUrbanMixMeasureSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "MixUseProp",
      FILE = "bzone_urban-mixed-use_prop.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Target for proportion of households located in mixed-use neighborhoods in zone (or NA if no target)"
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
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "UrbanPop",
          "RuralPop"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "UrbanArea",
          "RuralArea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "SQMI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "MixUseProp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
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
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Flag identifying whether household is (1) or is not (0) in urban mixed-use neighborhood"
    )
  )
)


#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateUrbanMixMeasure module
#'
#' A list containing specifications for the Calculate4DMeasures module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateUrbanMixMeasure.R script.
"CalculateUrbanMixMeasureSpecifications"
usethis::use_data(CalculateUrbanMixMeasureSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module calculates several 4D measures by Bzone including density,
#diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#and destination accessibility.


#Main module function that calculates urban mix use measure for households
#-------------------------------------------------------------------------
#' Main module function that calculates the urban mix measure for each household.
#'
#' \code{CalculateUrbanMixMeasure} calculates the urban mix measure for each
#' household.
#'
#' This module calculates whether each household is located in an urban
#' mixed-use neighborhood based on Bzone density and Bzone input proportion
#' targets.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name CalculateUrbanMixMeasure
#' @import visioneval
#' @export
CalculateUrbanMixMeasure <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Create Bzone name vector
  Bz <- L$Year$Bzone$Bzone
  #Create data frame of Bzone data
  Bz_df <- data.frame(L$Year$Bzone)
  #Create data frame of Household data
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$IsSF <- with(Hh_df, as.numeric(HouseType == "SF"))

  #Calculate urban mix-use probability
  #-----------------------------------
  #Population density
  Bz_df$LocalPopDensity <-
    with(Bz_df, (UrbanPop + RuralPop) / (UrbanArea + RuralArea))
  Bz_df$LocalPopDensity[is.na(Bz_df$LocalPopDensity)] <- 0
  Hh_df$LocalPopDensity <-
    Bz_df$LocalPopDensity[match(Hh_df$Bzone, Bz_df$Bzone)]
  Hh_df$MixUseProp <-
    Bz_df$MixUseProp[match(Hh_df$Bzone, Bz_df$Bzone)]
  Data_df <- split(Hh_df[, c("LocalPopDensity", "IsSF", "MixUseProp")], Hh_df$Bzone)
  #Predict urban mixed use measure
  UrbanMix_ls <-
    lapply(Data_df, function(x) {
      if (any(is.na(x$MixUseProp))) {
        applyBinomialModel(UrbanMixModel_ls, x)
      } else {
        applyBinomialModel(UrbanMixModel_ls, x, TargetProp = x$MixUseProp[1])
      }
    })

  #Produce output list of results
  #------------------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      IsUrbanMixNbrhd = as.integer(do.call(c, UrbanMix_ls))
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
# TestDat_ <- testModule(
#   ModuleName = "CalculateUrbanMixMeasure",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateUrbanMixMeasure",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
