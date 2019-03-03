#=========================
#SimulateUrbanMixMeasure.R
#=========================

#<doc>
#
## SimulateUrbanMixMeasure Module
#### February 6, 2019
#
#This module simulates an urban mixed-use measure based on the 2001 National Household Travel Survey measure of the tract level urban/rural indicator. This measure developed by Claritas uses the density of the tract and surrounding tracts to identify the urban/rural context of the tract. The categories include urban, suburban, second city, town and rural. Mapping of example metropolitan areas shows that places shown as urban correspond to central city and inner neighborhoods that are typically characterized by mixed use, higher levels of urban accessibility, and higher levels of walk/bike/transit accessibility. Documentation for the measure is included in the 'inst/extdata/sources' directory of this package. Unfortunately this is the only land use measure (other than population density) included in the NHTS. It is used in several models where it is a significant predictor. It should be noted that this measure has no established relationship to the other 4D measures that are simulated by modules in this package.
#
### Model Parameter Estimation
#
#This model uses the binary logit model estimated in the CalculateUrbanMixMeasure module of the VELandUse package. The model calculates the probability that a household is located in an urban mixed-use neighborhood as a function of the population density of the Bzone that household resides in and the housing type of the household. The model is estimated using NHTS household level data. A summary of the model is as follows:
#
#<txt:UrbanMixModel_ls$Summary>
#
#Where:
#
#* LocalPopDensity is the density of the census block group where the household is located in persons per square mile; and
#
#* IsSF is a dummy variable with a value of 1 if the household lives in a single family dwelling and 0 otherwise.
#
#Although the model is estimated at the household level, it is applied at the zonal level as described in the next section.
#
### How the Module Works
#
#The model iterates through model Mareas and assigns the SimBzones in each Marea as being urban-mixed character or not. The result is a vector of 1s and 0s where a value of 1 means that the SimBzone is of urban-mixed character. Users input urban-mix target values for each Marea. Values can be either NA or a number between 0 and 1. If a number is provided, the module will select a number of zones such that the proportion of Marea households in those zones is closest to the the target. If the value is NA, the module will calculate the most likely proportion of households that will be in urban-mixed neighborhoods (SimBzones). Following are the steps in the procedure:
#
#1. The inputs for the procedure are as follows:
#
#   * Matrix of the number of households by SimBzone and dwelling unit type: *Hh_BzHt*
#
#   * Vector of the population density (persons per square mile) by SimBzone: *Den_Bz*
#
#   * Target for the proportion of households in urban-mixed SimBzones: *Target*
#
#2. The total number of households in each SimBzone is calculated: *Hh_Bz*
#
#3. A matrix of probabilities by SimBzone and housing type is calculated by applying the binomial choice model for each combination of SimBone (population density) and housing type: *Prob_BzHt*.
#
#4. A weighted average probability is calculated for each SimBzone using the matrix of households (*Hh_BzHt*) and the matrix of probabilities (*Prob_BzHt*): *Prob_Bz*.
#
#5. If the *Target* value for the Marea is NA, the target is calculated by calculated the expected proportion of households in urban-mixed neighborhoods as follows: *sum(Prob_Bz * Hh_Bz) / sum(Hh_Bz)*
#
#6. SimBzones are identified as urban-mixed by evaluating in descending order of probability, calculating the cumulative proportion of Marea households, and determining which cumulative proportion is closest to the *Target*.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#' @import visioneval
#' @import VELandUse

#Load the urban mixed-use model estimated by the CalculateUrbanMixMeasure
#module in the VELandUse package
#------------------------------------------------------------------------
UrbanMixModel_ls <- VELandUse::UrbanMixModel_ls

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
SimulateUrbanMixMeasureSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "UrbanMixProp",
      FILE = "marea_mix_targets.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Marea target for proportion of households located in mixed-use neighborhoods (or NA if no target)"
    )
  ),
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
      NAME = "UrbanMixProp",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Bzone",
        "Marea"),
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
          "TownPop",
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
          "TownArea",
          "RuralArea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "SQMI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "SFDU",
          "MFDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
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
      NAME = "HhId",
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
    ),
    item(
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Flag identifying whether Bzone is (1) or is not (0) a urban mixed-use neighborhood"
    )
  )
)


#Save the data specifications list
#---------------------------------
#' Specifications list for SimulateUrbanMixMeasure module
#'
#' A list containing specifications for the SimulateUrbanMixMeasure module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source SimulateUrbanMixMeasure.R script.
"SimulateUrbanMixMeasureSpecifications"
usethis::use_data(SimulateUrbanMixMeasureSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module calculates several 4D measures by Bzone including density,
#diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#and destination accessibility.

#Function to identify Bzones that are urban mix
#----------------------------------------------
#' Identify urban mix Bzones
#'
#' \code{idUrbanMixBzones} identifies Bzones that are urban mix and Bzones
#' that are not.
#'
#' This function identifies which Bzones in an Marea are urban mixed use and
#' those that are not as a function of the Bzone population density and the mix
#' of single family and multifamily dwellings. The UrbanMixModel estimated by
#' the CalculateUrbanMixMeasure module in the VELand use package is used to
#' estimate the probability for single family households and the probability for
#' multifamily dwellings in each Bzone. A weighted average probability is
#' calculated for each Bzone where the numbers of single family and multifamily
#' dwellings are the weights. The descending order of probability is determined
#' and the minimum number of zones in that order necessary to meet the target is
#' determined. Those zones are classified as urban mixed use. If a numerical
#' target is not specified, the function calculates an expected proportion of
#' households using the zonal weighted probabilities.
#'
#' @param Hh_BzHt a numeric matrix of the number of households by Bzone and by
#' housing type. The rownames of the matrix are the Bzone names. The column
#' names are the housing type names: SFDU (single family dwelling unit), MFDU
#' (multifamily dwelling unit)
#' @param Den_Bz a named numeric vector of the population density (persons per
#' square mile) of each Bzone. The names of the vector are the Bzone names.
#' @param Target a target for the proportion of households in the Marea who live
#' in urban mixed neighborhoods.
#' @return a named numeric vector which has a value of 1 for Bzones that are
#' are identified as being urban mix and 0 for Bzones that are not. The names of
#' the vector are the Bzone names.
#' @export
idUrbanMixBzones <- function(Hh_BzHt, Den_Bz, Target) {
  Bz <- names(Den_Bz)
  Hh_BzHt <- Hh_BzHt[Bz,]
  Hh_Bz <- rowSums(Hh_BzHt)
  #Calculate probabilities by Bzone for SF and Mf
  Prob_BzHt <- 0 * Hh_BzHt
  Prob_BzHt[,"SFDU"] <-
    applyBinomialModel(
      Model_ls = UrbanMixModel_ls,
      Data_df = data.frame(LocalPopDensity = Den_Bz, IsSF = 1),
      ReturnProbs = TRUE)
  Prob_BzHt[,"MFDU"] <-
    applyBinomialModel(
      Model_ls = UrbanMixModel_ls,
      Data_df = data.frame(LocalPopDensity = Den_Bz, IsSF = 0),
      ReturnProbs = TRUE)
  #Calculate weighted average probability
  Prob_Bz <- rowSums(Hh_BzHt * Prob_BzHt) / Hh_Bz
  Prob_Bz[Hh_Bz == 0] <- 0
  names(Prob_Bz) <- Bz
  #Calculate the proportion of households in each Bzone
  HhProp_Bz <- Hh_Bz / sum(Hh_Bz)
  names(HhProp_Bz) <- Bz
  #If target is NA, calculate the proportion of households in mixed use
  if (is.na(Target)) {
    Target <- sum(Prob_Bz * Hh_Bz) / sum(Hh_Bz)
  }
  #Select the Bzones
  DescOrd_ <- rev(order(Prob_Bz))
  CumProp_Bz <- cumsum(HhProp_Bz[DescOrd_])
  DistFromTarget_Bz <- abs(CumProp_Bz - Target)
  Cutoff <- which(DistFromTarget_Bz == min(DistFromTarget_Bz))
  UrbanMixBzones_ <- names(DistFromTarget_Bz)[1:Cutoff]
  UrbanMix_Bz <- setNames(integer(length(Bz)), Bz)
  UrbanMix_Bz[UrbanMixBzones_] <- 1
  #Return the result
  UrbanMix_Bz
}

#Main module function that calculates urban mix use measure for households
#-------------------------------------------------------------------------
#' Main module function that calculates the urban mix measure for each household.
#'
#' \code{SimulateUrbanMixMeasure} calculates the urban mix measure for each
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
SimulateUrbanMixMeasure <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Name vectors
  Bz <- L$Year$Bzone$Bzone
  Ma <- L$Year$Marea$Marea

  #Iterate by Marea and identify urban mix designation for all SimBzones
  #---------------------------------------------------------------------
  #Make matrix of households by Bzone and house type
  NumHh_BzHt <- with(L$Year$Bzone, cbind(SFDU, MFDU))
  rownames(NumHh_BzHt) <- L$Year$Bzone$Bzone
  #Make vector of population density by Bzone
  PopDen_Bz <- with(L$Year$Bzone, {
    (UrbanPop + TownPop + RuralPop) / (UrbanArea + TownArea + RuralArea)
    })
  names(PopDen_Bz) <- L$Year$Bzone$Bzone
  #Initialize a vector to store the results
  UrbanMix_Bz <- setNames(integer(length(Bz)), Bz)
  #Identify urban mix value for SimBzones in each Marea
  for (ma in Ma) {
    #Create selections of Bzones Marea
    BzInMa <- L$Year$Bzone$Marea == ma
    #Identify urban mix Bzones in the Marea
    UrbMix_Bx <- idUrbanMixBzones(
      Hh_BzHt = NumHh_BzHt[BzInMa,],
      Den_Bz = PopDen_Bz[BzInMa],
      Target = L$Year$Marea$UrbanMixProp[L$Year$Marea$Marea == ma])
    #Assign to results
    UrbanMix_Bz[names(UrbMix_Bx)] <- UrbMix_Bx
    rm(BzInMa, UrbMix_Bx)
  }
  rm(ma, NumHh_BzHt, PopDen_Bz)

  #Prepare outputs
  #---------------
  #Initialize outputs list
  Out_ls <- initDataList()
  Out_ls$Year$Bzone$IsUrbanMixNbrhd <- as.integer(UrbanMix_Bz)
  Out_ls$Year$Household$IsUrbanMixNbrhd <-
    as.integer(UrbanMix_Bz[L$Year$Household$Bzone])
  #Return the result
  Out_ls

}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("SimulateUrbanMixMeasure")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
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
#   ModuleName = "SimulateUrbanMixMeasure",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L
# R <- SimulateUrbanMixMeasure(L)
#
# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "SimulateUrbanMixMeasure",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
