#=======================
#CalculateVehicleTrips.R
#=======================
#This module calculates vehicle trips for households.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(pscl)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Load NHTS household data
#------------------------
Hh_df <- VE2001NHTS::Hh_df

#Estimate the average household DVMT for NHTS households
#-------------------------------------------------------
#Identify metropolitan households
IsMetro_ <- Hh_df$Msacat %in% c("1", "2")
#Get DVMT model
load("data/DvmtModel_ls.rda")
#Prepare variables for application of model
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$ZeroVeh <- as.numeric(Hh_df$NumVeh == 0)
Hh_df$OneVeh <- as.numeric(Hh_df$NumVeh == 1)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$Drivers <- Hh_df$Drvrcnt
Hh_df$Intercept <- 1
#Apply the model
Hh_df$Dvmt <- NA
Hh_df$Dvmt[IsMetro_] <-
  as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                 envir = Hh_df[IsMetro_,])) ^ (1 / DvmtModel_ls$Metro$Pow)
Hh_df$Dvmt[!IsMetro_] <-
  as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                 envir = Hh_df[!IsMetro_,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)

#Prepare variables for estimating trip models
#--------------------------------------------
Hh_df$NumVehTrp <- round(Hh_df$PvtVehTrips + Hh_df$ShrVehTrips)
Hh_df$LogDvmt <- log(Hh_df$Dvmt)
Hh_df$LogDensity <- log(Hh_df$Hbppopdn)
Hh_df$NonDrivers <- Hh_df$Hhsize - Hh_df$Drivers
Hh_df$HhSize <- Hh_df$Hhsize

#Define function to make model formula strings for hurdle model
#--------------------------------------------------------------
#' Make hurdle model formula strings
#'
#' \code{makeHurdleStrings} makes strings which describe the zero and count
#' model components of the hurdle model.
#'
#' The Hurdle regression models that are used to calculate trips are stored as
#' text strings. This follows the approach used in other modules. The
#' 'makeHurdleStrings' function creates text strings for the zero trip and count
#' model components of an estimated Hurdle model object and outputs them in a
#' list. The function takes one argument, a hurdle model object created by the
#' 'hurdle' function. It returns a list having two components: 'Count' which
#' contains a string representation of the count model component, and 'Zero'
#' which contains a string representation of the zero model component.
#' @param HurdleModel_ls a list returned by the application of the 'hurdle'
#' function in the 'pscl' package
#' @return a list having two components: 'Count' which contains a string
#' representation of the count model component, and 'Zero' which contains a
#' string representation of the zero model component.
makeHurdleStrings <- function(HurdleModel_ls) {
  Coeff. <- coefficients(HurdleModel_ls)
  #Make formula string for count model
  CountCoeff. <- Coeff.[grep("count", names(Coeff.))]
  names(CountCoeff.) <- gsub("count_", "", names(CountCoeff.))
  names(CountCoeff.)[1] <- "Intercept"
  CountFormula <- paste(paste(CountCoeff., names(CountCoeff.), sep = " * "), collapse = " + ")
  #Make formula string for zero model
  ZeroCoeff. <- Coeff.[grep("zero", names(Coeff.))]
  names(ZeroCoeff.) <- gsub("zero_", "", names(ZeroCoeff.))
  names(ZeroCoeff.)[1] <- "Intercept"
  ZeroFormula <- paste(paste(ZeroCoeff., names(ZeroCoeff.), sep = " * "), collapse = " + ")
  #Return the formulas in a list
  list(Count = CountFormula, Zero = ZeroFormula)
}

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

#Estimate vehicle trip models
#----------------------------
#Select metropolitan households
Vars_ <- c("NumVehTrp", "HhSize", "LogIncome", "LogDensity",
           "BusEqRevMiPC", "Urban", "LogDvmt", "Drivers", "NonDrivers")
MetroHh_df <- Hh_df[IsMetro_, Vars_]
MetroHh_df <- MetroHh_df[complete.cases(MetroHh_df),]
#Estimate metropolitan vehicle trip model
MetroVehTripModel_HM <-
  hurdle(NumVehTrp ~ NonDrivers + Drivers + LogIncome + LogDensity + Urban +
           BusEqRevMiPC + LogDvmt,
         data = MetroHh_df,
         dist = "poisson", zero.dist = "binomial", link = "logit")
rm(Vars_, MetroHh_df)
#Select non-metropolitan households
Vars_ <- c("NumVehTrp", "HhSize", "LogIncome", "LogDensity",
           "LogDvmt", "Drivers", "NonDrivers")
NonMetroHh_df <- Hh_df[!IsMetro_, Vars_]
NonMetroHh_df <- NonMetroHh_df[complete.cases(NonMetroHh_df),]
#Estimate walk model
NonMetroVehTripModel_HM <-
  hurdle(NumVehTrp ~ NonDrivers + Drivers + LogIncome + LogDensity + LogDvmt,
         data = NonMetroHh_df,
         dist = "poisson", zero.dist = "binomial", link = "logit")

#Save alternative mode trip models
#---------------------------------
#Put models in a list
VehTripModels_ls <- list(
  Metro = makeHurdleStrings(MetroVehTripModel_HM),
  NonMetro = makeHurdleStrings(NonMetroVehTripModel_HM)
)
#Save the model
#' Household vehicle trip models
#'
#' A list of components describing hurdle models for predicting the numbers of
#' household vehicle trips.
#'
#' @format A list having 'Metro' and 'NonMetro' components. Each component
#' contains a string representing a hurdle model for computing household trips;
#' @source CalculateVehicleTrips.R script.
"VehTripModels_ls"
devtools::use_data(VehTripModels_ls, overwrite = TRUE)

rm(DvmtModel_ls, Hh_df, MetroVehTripModel_HM, NonMetroHh_df,
   NonMetroVehTripModel_HM, IsMetro_, Vars_, makeHurdleStrings)

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateVehicleTripsSpecifications <- list(
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
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural")
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
      NAME = "Drivers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
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
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "VehicleTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average number of vehicle trips per day by household members"
    )
  ),
  #Make module callable
  Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateVehicleTrips module
#'
#' A list containing specifications for the CalculateVehicleTrips module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateVehicleTrips.R script.
"CalculateVehicleTripsSpecifications"
devtools::use_data(CalculateVehicleTripsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates vehicle trips for each household.

#Main module function that calculates household vehicle trips
#------------------------------------------------------------
#' Main module function to calculate household vehicle trips
#'
#' \code{CalculateVehicleTrips} calculates vehicle trips for each household.
#'
#' This function calculates vehicle trips for households.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateVehicleTrips <- function(L) {

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$Intercept <- 1
  Hh_df$BusEqRevMiPC <-
    L$Year$Marea$TranRevMiPC[match(L$Year$Household$Marea, L$Year$Marea$Marea)]
  Hh_df$LogDensity <-
    log1p(L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)])
  Hh_df$LogIncome <- log(Hh_df$Income)
  Hh_df$LogDvmt <- log(Hh_df$Dvmt)
  Hh_df$Urban <- Hh_df$IsUrbanMixNbrhd
  Hh_df$NonDrivers <- Hh_df$HhSize - Hh_df$Drivers

  #Define function to calculate trips
  calcTrips <- function() {
    Trips_ <- nrow(Hh_df)
    IsMetro_ <- Hh_df$DevType == "Urban"
    Trips_[IsMetro_] <-
      applyHurdleTripModel(Hh_df[IsMetro_,], VehTripModels_ls$Metro)
    Trips_[!IsMetro_] <-
      applyHurdleTripModel(Hh_df[!IsMetro_,], VehTripModels_ls$NonMetro)
    Trips_
  }
  #Calculate trips and return results
  Out_ls <- initDataList()
  Out_ls$Year$Household$VehicleTrips = calcTrips()
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
#   ModuleName = "CalculateVehicleTrips",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateVehicleTrips(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleTrips",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
