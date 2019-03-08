#================
#SimulateHousing.R
#================

#<doc>
#
## SimulateHousing Module
#### February 3, 2019
#
#This module assigns a housing type, either single-family (SF) or multifamily (MF) to *regular* households based on the respective supplies of SF and MF dwelling units in the housing market to which the household is assigned (i.e. the Azone the household is assigned to) and on household characteristics. It then assigns each household to a SimBzone based on the household's housing type as well as the supply of housing by type and SimBzone. The module assigns non-institutional group quarters *households* to SimBzones randomly.
#
### Model Parameter Estimation
#
#This module uses the housing choice model estimated by the 'PredictHousing' module in the 'VELandUse' package.
#
### How the Module Works
#
#The module carries out the following series of calculations to assign a housing type (SF or MF) to each *regular* household and to assign each household to a Bzone location.
#
#1) The proportions of SF and MF dwelling units in the Azone are calculated.
#
#2) The housing choice model is applied to each household in the Azone to determine the household's housing type. The model is applied multiple times using a binary search algorithm to successively adjust the model intercept until the housing type *choice* proportions equal the housing unit proportions in the Azone.
#
#3) A matrix of the number of housing units by Bzone and housing type is created from data retrieved from the datastore.
#
#4) Households are randomly assigned to SimBzones based on their housing type and the quantity of housing of each type in each SimBzone.
#
#5) Non-institutionalized group-quarters *households* are assigned randomly to SimBzones.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module uses the housing choice model estimated by the 'PredictHousing' module in the 'VELandUse' package.

#Load the housing choice model from the VELandUse package.
#' @import VELandUse

HouseTypeModel_ls <- VELandUse::HouseTypeModel_ls

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
usethis::use_data(HouseTypeModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
SimulateHousingSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
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
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "PropGQPopCenter",
        "PropGQPopInner",
        "PropGQPopOuter",
        "PropGQPopFringe"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "Bzone",
        "Azone",
        "Marea"),
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
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    ),
    item(
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("center", "inner", "outer", "fringe")
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
      NAVALUE = "",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = "ID of Bzone in which household resides"
    ),
    item(
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural"),
      SIZE = 5,
      DESCRIPTION = "Location type (Urban, Town, Rural) of the place where the household resides"
    ),
    item(
      NAME = items(
        "Pop",
        "UrbanPop",
        "TownPop",
        "RuralPop"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Total population residing in Bzone",
        "Urban LocType population residing in Bzone",
        "Town LocType population residing in Bzone",
        "Rural LocType population residing in Bzone"
        )
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
    ),
    item(
      NAME = items(
        "UrbanPop",
        "TownPop",
        "RuralPop"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Urbanized area population in the Marea",
        "Town (i.e. urban but non-urbanized area) in the Marea",
        "Rural (i.e. not urbanized and not town) population in the Marea"
        )
    ),
    item(
      NAME = items(
        "UrbanIncome",
        "TownIncome",
        "RuralIncome"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Total household income of the urbanized area population in the Marea",
        "Total household income of the town (i.e. urban but non-urbanized area) population in the Marea",
        "Total household income of the rural (i.e. not urbanized and not town) population in the Marea"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for SimulateHousing module
#'
#' A list containing specifications for the SimulateHousing module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source SimulateHousing.R script.
"SimulateHousingSpecifications"
usethis::use_data(SimulateHousingSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function predicts the housing type each household. It uses the estimated
#binomial choice model for determining the probability that the housing choice
#for each household is single family (SF) vs. multifamily (MF). The group
#quarters population is assigned to group quarters (GQ).

#Define function to allocate integer quantities among categories
#---------------------------------------------------------------
#' Allocate integer quantities among categories
#'
#' \code{splitIntegers} splits a total value into a vector of whole numbers to
#' reflect input vector of proportions
#'
#' This function splits an input total into a vector of whole numbers to reflect
#' an input vector of proportions. If the input total is not an integer, the
#' value is rounded and converted to an integer.
#'
#' @param Tot a number that is the total value to be split into a vector of
#' whole numbers corresponding to the input proportions. If Tot is not an
#' integer, its value is rounded and converted to an integer.
#' @param Props_ a numeric vector of proportions used to split the total value.
#' The values should add up to approximately 1. The function will adjust so that
#' the proportions do add to 1.
#' @return a numeric vector of whole numbers corresponding to the Props_
#' argument which sums to the Tot.
splitIntegers <- function(Tot, Props_) {
  #Convert Tot into an integer
  if (!is.integer(Tot)) {
    Tot <- as.integer(round(Tot))
  }
  #If Tot is 0, return vector of zeros
  if (Tot == 0) {
    integer(length(Props_))
  } else {
    #Make sure that Props_ sums exactly to 1
    Props_ <- Props_ / sum(Props_)
    #Make initial whole number split
    Ints_ <- round(Tot * Props_)
    #Determine the difference between the initial split and the total
    Diff <- Tot - sum(Ints_)
    #Allocate the difference
    if (Diff != 0) {
      for (i in 1:abs(Diff)) {
        IdxToChg <- sample(1:length(Props_), 1, prob = Props_)
        Ints_[IdxToChg] <- Ints_[IdxToChg] + sign(Diff)
      }
    }
    unname(Ints_)
  }
}

#Main module function that assigns housing type and Bzone for each household
#---------------------------------------------------------------------------
#' Main module function that assigns the housing type and Bzone for each
#' household.
#'
#' \code{SimulateHousing} predicts the housing type and Bzone for each household.
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
#' @name SimulateHousing
#' @import visioneval stats
#' @export
SimulateHousing <- function(L) {

  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Initialize output list
  Out_ls <- initDataList()
  #Add household Bzone assignment list
  Out_ls$Year$Household$Bzone <- character(length(L$Year$Household$HhId))
  Out_ls$Year$Household$HouseType <- character(length(L$Year$Household$HhId))

  #---------------------------------------------------------------
  #Iterate through Azones and Make Household Assignments to Bzones
  #---------------------------------------------------------------
  Az <- L$Year$Azone$Azone

  for (az in Az) {

    #Initialize for Azone
    #--------------------
    HhInAz <- L$Year$Household$Azone == az
    BzInAz <- L$Year$Bzone$Azone == az
    IsAz <- L$Year$Azone$Azone == az
    Bzones_ <- L$Year$Bzone$Bzone[BzInAz]
    AreaType_ <- L$Year$Bzone$AreaType[BzInAz]
    HhId_ <- L$Year$Household$HhId[HhInAz]
    #Initialize a vector to store housing type
    HouseType_Hh <- character(sum(HhInAz))
    names(HouseType_Hh) <- L$Year$Household$HhId[HhInAz]
    #Identify which households are group quarters
    IsGQ_Hh <- L$Year$Household$HhType[HhInAz] == "Grp"
    HouseType_Hh[IsGQ_Hh] <- "GQ"

    #Predict housing type for each household
    #---------------------------------------
    HouseType_ <- local({
      #Load the housing choice model
      HouseTypeModel_ls <- loadPackageDataset("HouseTypeModel_ls")
      #Make data frame of household variables and split by Azone
      Hh_df <- data.frame(lapply(L$Year$Household, function(x) {
        x[HhInAz]}))[!IsGQ_Hh,]
      #Calculate the total single family and multifamily units
      SFDU <- sum(L$Year$Bzone$SFDU[BzInAz])
      MFDU <- sum(L$Year$Bzone$MFDU[BzInAz])
      #Predict single family housing probability
      SFProb_ <- applyBinomialModel(
        HouseTypeModel_ls,
        Hh_df,
        ReturnProbs = TRUE
      )
      #Initialize housetype vector
      NumHh <- length(SFProb_)
      HouseType_ <- rep("SF", NumHh)
      #Order household positions in ascending single family probability
      IdxOrd_ <- (1:NumHh)[order(SFProb_)]
      #Assign the lowest probability households equal to number MF supply to MF
      if (MFDU > 0) {
        HouseType_[IdxOrd_[1:MFDU]] <- "MF"
      }
      #Populate HouseType_Hh vector with results
      names(HouseType_) <- Hh_df$HhId
      #Return the results
      HouseType_
    })
    HouseType_Hh[names(HouseType_)] <- HouseType_
    rm(HouseType_)

    #Tabulate housing unit inputs by Bzone and housing type
    #------------------------------------------------------
    Du_BzHt <- cbind(
      L$Year$Bzone$SFDU[BzInAz],
      L$Year$Bzone$MFDU[BzInAz]
    )
    rownames(Du_BzHt) <- L$Year$Bzone$Bzone[BzInAz]
    colnames(Du_BzHt) <- c("SF", "MF")

    #Assign households to SimBzones based on housing type
    #----------------------------------------------------
    Bzone_Hh <- character(length(HouseType_Hh))
    for (ht in c("SF", "MF")) {
      Bzone_ <- sample(rep(rownames(Du_BzHt), Du_BzHt[,ht]))
      IsHh_ <- HouseType_Hh == ht
      Bzone_Hh[IsHh_] <- Bzone_
      rm(Bzone_, IsHh_)
    }
    rm(Du_BzHt)

    #Assign group quarters households to SimBzones
    #---------------------------------------------
    #Sum group quarters population
    GQPop <- sum(IsGQ_Hh)
    #Allocate group quarters population if not 0
    if (GQPop > 0) {
      #Get the GQ proportions by area type
      GQProps_ <- c(
        center = L$Year$Azone$PropGQPopCenter[IsAz],
        inner = L$Year$Azone$PropGQPopInner[IsAz],
        outer = L$Year$Azone$PropGQPopOuter[IsAz],
        fringe = L$Year$Azone$PropGQPopFringe[IsAz])
      #Determine whether can be used
      UseAtProps <- FALSE
      if (!is.null(GQProps_)) {
        if (!any(is.na(GQProps_))) {
          UseAtProps <- TRUE
        }
      }
      #Allocate GQ population to SimBzones if there are area type proportions
      if (UseAtProps) {
        GQPop_At <- splitIntegers(GQPop, GQProps_)
        At <- c("center", "inner", "outer", "fringe")
        names(GQPop_At) <- At
        GQBzones_ <- sample(unlist(sapply(At, function(x) {
          sample(Bzones_[AreaType_ == x],
                 GQPop_At[x],
                 replace = TRUE)
        })))
        Bzone_Hh[IsGQ_Hh] <- unname(GQBzones_)
        rm(GQProps_, UseAtProps, GQPop_At, At, GQBzones_)
      } else {
        GQBzones_ <- unname(sample(Bzones_, GQPop, replace = TRUE))
        Bzone_Hh[IsGQ_Hh] <- unname(GQBzones_)
        rm(GQProps_, UseATProps, GQBzones_)
      }
    }

    #Add to Out_ls
    #-------------
    #Add HouseType and Bzone to outputs
    Out_ls$Year$Household$Bzone[match(HhId_, L$Year$Household$HhId)]  <- Bzone_Hh
    Out_ls$Year$Household$HouseType[match(HhId_, L$Year$Household$HhId)]  <- HouseType_Hh

    #Clean up
    rm(HhInAz, BzInAz, IsAz, Bzones_, AreaType_, HouseType_Hh, IsGQ_Hh, Bzone_Hh)

  }

  #Assign LocType to households
  #----------------------------
  Out_ls$Year$Household$LocType <-
    L$Year$Bzone$LocType[match(Out_ls$Year$Household$Bzone, L$Year$Bzone$Bzone)]

  #Tabulate population and workers at Bzone level
  #----------------------------------------------
  Bz <- L$Year$Bzone$Bzone
  Pop_Bz <- setNames(rep(0, length(Bz)), Bz)
  Pop_Bx <- tapply(L$Year$Household$HhSize, Out_ls$Year$Household$Bzone, sum)
  Pop_Bz[names(Pop_Bx)] <- Pop_Bx
  UrbanPop_Bz <- Pop_Bz
  UrbanPop_Bz[L$Year$Bzone$LocType != "Urban"] <- 0
  TownPop_Bz <- Pop_Bz
  TownPop_Bz[L$Year$Bzone$LocType != "Town"] <- 0
  RuralPop_Bz <- Pop_Bz
  RuralPop_Bz[L$Year$Bzone$LocType != "Rural"] <- 0
  NumWkr_Bz <- setNames(rep(0, length(Bz)), Bz)
  NumWkr_Bx <- tapply(L$Year$Household$Workers, Out_ls$Year$Household$Bzone, sum)
  NumWkr_Bz[names(NumWkr_Bx)] <- NumWkr_Bx

  #Tabulate population and income at Marea level
  #---------------------------------------------
  Ma <- L$Year$Marea$Marea
  #Marea population by LocType
  calcMareaPop <- function(LocTypePop_Bz) {
    LocTypePop_Ma <- setNames(numeric(length(Ma)), Ma)
    LocTypePop_Mx <- tapply(LocTypePop_Bz, L$Year$Bzone$Marea, sum)
    LocTypePop_Ma[names(LocTypePop_Mx)] <- LocTypePop_Mx
    LocTypePop_Ma
  }
  UrbanPop_Ma <- calcMareaPop(UrbanPop_Bz)
  TownPop_Ma <- calcMareaPop(TownPop_Bz)
  RuralPop_Ma <- calcMareaPop(RuralPop_Bz)
  #Sum income by Bzone
  Income_Bz <- setNames(numeric(length(Bz)), Bz)
  Income_Bx <- tapply(L$Year$Household$Income, Out_ls$Year$Household$Bzone, sum)
  Income_Bz[names(Income_Bx)] <- Income_Bx
  #Sum income by LocType and Marea
  Lt <- c("Urban", "Town", "Rural")
  Income_MaLt <-
    tapply(Income_Bz, list(L$Year$Bzone$Marea, L$Year$Bzone$LocType), sum)[Ma,Lt]
  Income_MaLt[is.na(Income_MaLt)] <- 0

  #Return list of results
  #----------------------
  #Add SIZE attribute for the household Bzone assignments
  attributes(Out_ls$Year$Household$Bzone)$SIZE <-
    max(nchar(Out_ls$Year$Household$Bzone))
  #Add the household housing type assignments to the list
  #Add the population and workers by Bzone
  Out_ls$Year$Bzone$Pop <- as.integer(unname(Pop_Bz))
  Out_ls$Year$Bzone$UrbanPop <- as.integer(unname(UrbanPop_Bz))
  Out_ls$Year$Bzone$TownPop <- as.integer(unname(TownPop_Bz))
  Out_ls$Year$Bzone$RuralPop <- as.integer(unname(RuralPop_Bz))
  Out_ls$Year$Bzone$NumWkr <- as.integer(unname(NumWkr_Bz))
  #Add the population and income by LocType for Mareas
  Out_ls$Year$Marea$UrbanPop <- as.integer(UrbanPop_Ma)
  Out_ls$Year$Marea$TownPop <- as.integer(TownPop_Ma)
  Out_ls$Year$Marea$RuralPop <- as.integer(RuralPop_Ma)
  Out_ls$Year$Marea$UrbanIncome <- Income_MaLt[,"Urban"]
  Out_ls$Year$Marea$TownIncome <- Income_MaLt[,"Town"]
  Out_ls$Year$Marea$RuralIncome <- Income_MaLt[,"Rural"]
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("SimulateHousing")

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
#   ModuleName = "SimulateHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "BaseYear"
# )
# L <- TestDat_$L
#R <- SimulateHousing(L)
#
# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "SimulateHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
