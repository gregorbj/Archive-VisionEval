#=======================
#CalculateAltModeTrips.R
#=======================
#This module calculates transit, walk, and bike trips for households.

library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Load the alternative mode trip models from GreenSTEP
load("inst/extdata/AltModeModels_ls.RData")
#Save the model
#' Alternative mode trip models
#'
#' A list of components describing hurdle models for predicting the numbers of
#' trips by walking, biking, and taking public transportation.
#'
#' @format A list having 'Metro' and 'NonMetro' components. Each component has
#' the following components:
#' Walk: a hurdle model of walk trips having Count and Zero components;
#' Bike: a hurdle model of bike trips having Count and Zero components;
#' Transit: a hurdle model of public transit trips having Count and Zero
#' components;
#' @source GreenSTEP version 3.6 model.
"AltModeModels_ls"
devtools::use_data(AltModeModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateAltModeTripsSpecifications <- list(
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
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("WalkTrips",
              "BikeTrips",
              "TransitTrips"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "daily trips",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Average number of walk trips per day by household members",
          "Average number of bicycle trips per day by household members",
          "Average number of public transit trips per day by household members"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateAltModeTrips module
#'
#' A list containing specifications for the CalculateAltModeTrips module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateAltModeTrips.R script.
"CalculateAltModeTripsSpecifications"
devtools::use_data(CalculateAltModeTripsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates alternative mode trips for each household.

#Define a function to apply a hurdle trip model to calculate household trips
#---------------------------------------------------------------------------
#' Apply a hurdle trip model
#'
#' \code{applyHurdleTripModel} applies a hurdle model to calculate the number
#' of trips for each household.
#'
#' This function takes a list of strings representing an estimated hurdle model
#' and applies it to a data frame that contains data of independent variables
#' for household records. it returns a vector of modeled trips corresponding to
#' the rows of the data frame.
#' @param Data_df a data frame containing the independent variables needed to
#' calculate trips
#' @param Model_ls a list created by the estimateHurdleTripModel which contains
#' 'Count' and 'Zero' model components.
#' @return a numeric vector of the number of trips for each household in the
#' same order as Data_df
applyHurdleTripModel <- function(Data_df, Model_ls) {
  #Add the intercept
  Data_df$Intercept <- 1
  #Calculate zero term
  Odds_ <- exp(eval(parse(text = Model_ls$Zero), envir = Data_df))
  Prob_ <- Odds_ / (1 + Odds_)
  PZero_ <- log(Prob_)
  #Calculate count term
  Mu_ <- exp(eval(parse(text = Model_ls$Count), envir = Data_df))
  PCount_ <- ppois(0, lambda = Mu_, lower.tail = FALSE, log.p = TRUE)
  #Return the number of trips
  exp((PZero_ - PCount_) + log(Mu_))
}

#Main module function that calculates household alternative mode trips
#---------------------------------------------------------------------
#' Main module function to calculate alternative mode trips
#'
#' \code{CalculateAltModeTrips} calculates alternative mode trips for each
#' household.
#'
#' This function calculates walk, bike, and transit tripss for households.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateAltModeTrips <- function(L) {
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
  Hh_df$Intercept <- 1
  TranRevMiPC_Bz <-
    L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Tranmilescap <-
    TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$LogHbppopdn <-
    log1p(L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)])
  Hh_df$LogIncome <- log(Hh_df$Income)
  Hh_df$LogDvmt <- log(Hh_df$Dvmt)
  Hh_df$Hhsize <- Hh_df$HhSize
  Hh_df$VehPerDrvAgePop <- Hh_df$Vehicles / (Hh_df$HhSize - Hh_df$Age0to14)
  Hh_df$Urban <- Hh_df$IsUrbanMixNbrhd

  #Define function to calculate trips
  calcTrips <- function(Mode) {
    Trips_ <- nrow(Hh_df)
    IsMetro_ <- Hh_df$DevType == "Urban"
    Trips_[IsMetro_] <-
      applyHurdleTripModel(Hh_df[IsMetro_,], AltModeModels_ls$Metro[[Mode]])
    Trips_[!IsMetro_] <-
      applyHurdleTripModel(Hh_df[!IsMetro_,], AltModeModels_ls$NonMetro[[Mode]])
    Trips_
  }
  #Calculate trips and return results
  Out_ls <- initDataList()
  Out_ls$Year$Household$WalkTrips = calcTrips("Walk")
  Out_ls$Year$Household$BikeTrips = calcTrips("Bike")
  Out_ls$Year$Household$TransitTrips = calcTrips("Transit")
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
#   ModuleName = "CalculateHouseholdDVMT",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleAge",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
