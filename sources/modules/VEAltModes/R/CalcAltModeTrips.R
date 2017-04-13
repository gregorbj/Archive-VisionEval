#==================
#CalcAltModeTrips.R
#==================
#This module calculates transit, walk, and bike trips for households.

library(visioneval)
library(pscl)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This section estimates hurdle models for transit, walk and bike trip-making

#Load and prep data for estimating models
#----------------------------------------
#Load data
load("inst/extdata/MetroHh_df.RData")
load("inst/extdata/NonMetroHh_df.RData")
#Add variables to metropolitan household dataset
MetroHh_df$LogIncome <- log(MetroHh_df$Hhincttl)
MetroHh_df$Dvmt <- MetroHh_df$DvmtAve
MetroHh_df$LogDvmt <- log(MetroHh_df$Dvmt)
MetroHh_df$LogHbppopdn <- log(MetroHh_df$Hbppopdn)
MetroHh_df$DrvAgePop <- MetroHh_df$Hhsize - MetroHh_df$Age0to14
MetroHh_df$VehPerDrvAgePop <- MetroHh_df$Hhvehcnt / MetroHh_df$DrvAgePop
#Add variables to non-metropolitan household dataset
NonMetroHh_df$LogIncome <- log(NonMetroHh_df$Hhincttl)
NonMetroHh_df$Dvmt <- NonMetroHh_df$DvmtAve
NonMetroHh_df$LogDvmt <- log(NonMetroHh_df$Dvmt)
NonMetroHh_df$LogHbppopdn <- log(NonMetroHh_df$Hbppopdn)
NonMetroHh_df$DrvAgePop <- NonMetroHh_df$Hhsize - NonMetroHh_df$Age0to14
NonMetroHh_df$VehPerDrvAgePop <- NonMetroHh_df$Hhvehcnt / NonMetroHh_df$DrvAgePop
#Select the data used for metropolitan model estimation
ModelVar. <- c("Houseid", "Hhincttl", "Hbppopdn", "Urban","Hbhur", "Hhsize",
               "Hhvehcnt", "Age0to14", "Age15to19", "Age20to29",  "Age30to54",
               "Age55to64", "Age65Plus", "DrvAgePop", "VehPerDrvAgePop",
               "NumWalkTrp", "NumBikeTrp",  "NumTransitTrp", "Fwylnmicap",
               "Tranmilescap", "Dvmt", "LogDvmt", "LogIncome",
               "LogHbppopdn", "Hhc_msa")
MetroHh_df <- MetroHh_df[ , ModelVar.]
rm(ModelVar.)
#Adding meaningful names for identified metropolitan areas
HbhurNames. <-
  c(C="Second City", R="Rural", S="Suburban", T="Town", U="Urban Center")
MetroHh_df$PlaceType <- HbhurNames.[MetroHh_df$Hbhur]
MetroNameLookup. <-
  c("0520"="Atlanta", "0640"="Austin", "1280"="Buffalo", "1122"="Boston",
    "1520"="Charlotte", "1602"="Chicago", "1642"="Cincinnati",
    "1692"="Cleveland", "1840"="Columbus", "1922"="Dallas", "2082"="Denver",
    "2162"="Detroit", "3000"="Grand Rapids", "3120"="Greensboro",
    "3280"="Hartford", "3320"="Honolulu", "3362"="Houston",
    "3480"="Indianapolis", "3600"="Jacksonville", "3760"="Kansas City",
    "4120"="Las Vegas", "4472"="Los Angeles", "4520"="Louisville",
    "4920"="Memphis", "4992"="Miami", "5082"="Milwaukee", "5120"="Minneapolis",
    "5360"="Nashville", "5560"="New Orleans", "5602"="New York",
    "5720"="Norfolk", "5880"="Oklahoma City", "5960"="Orlando",
    "6162"="Philadelphia", "6200"="Phoenix", "6280"="Pittsburgh",
    "6442"="Portland", "6480"="Providence", "6640"="Raleigh",
    "6840"="Rochester", "6922"="Sacramento", "7040"="St. Louis",
    "7160"="Salt Lake City", "7240"="San Antonio", "7320"="San Diego",
    "7362"="San Francisco", "7602"="Seattle", "8280"="Tampa",
    "8872"="Washington", "8960"="West Palm Beach")
MetroHh_df$MsaName <- MetroNameLookup.[MetroHh_df$Hhc_msa]
rm(HbhurNames., MetroNameLookup.)
#Select the data used in non-metropolitan models and select complete cases
ModelVar. <- c("Houseid", "Hhincttl", "Hbppopdn", "Hbhur", "Hhsize",
               "Hhvehcnt", "Age0to14", "Age15to19", "Age20to29",  "Age30to54",
               "Age55to64", "Age65Plus", "DrvAgePop", "VehPerDrvAgePop",
               "NumWalkTrp", "NumBikeTrp",  "NumTransitTrp", "Dvmt",
               "LogDvmt", "LogIncome", "LogHbppopdn")
NonMetroHh_df <- NonMetroHh_df[ , ModelVar.]
NonMetroHh_df <- NonMetroHh_df[complete.cases(NonMetroHh_df), ]
rm(ModelVar.)

#Define a function to estimate hurdle model and return string representation
#---------------------------------------------------------------------------
#' Estimate hurdle trip model and return string representation
#'
#' \code{estimateHurdleTripModel} estimates a hurdle trip model and returns a
#' string representation of that model
#'
#' This function estimates a hurdle model of trips for a specified mode
#' (transit, walk, bike) and development type. It returns a string
#' representation of the model.
#'
#' @param Formula A model formula.
#' @param Data_df A data frame containing the estimation data
#' @return A list containing two named string components. The 'Count' component
#' contains a string representation of the count model. The 'Zero' component
#' contains a string representation of the zero model.
#' @import pscl
estimateHurdleTripModel <-
  function(Formula, Data_df) {
    EstModel_ls <-
      hurdle(Formula,
             data = Data_df,
             dist = "poisson",
             zero.dist = "binomial",
             link = "logit")
    Coeff. <- coefficients(EstModel_ls)
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

#Define model formulae
#---------------------
Formula_ls <- list()
Formula_ls$Metro <-
  list(
    Walk = formula(
      NumWalkTrp ~ Hhsize + LogIncome + VehPerDrvAgePop + LogHbppopdn +
        Tranmilescap + Urban + LogDvmt
    ),
    Bike = formula(
      NumBikeTrp ~ Hhsize + Tranmilescap +
        Dvmt | Age0to14 + Age15to19 + Age20to29 + Age30to54 +
        Tranmilescap + Dvmt
    ),
    Transit = formula(
      NumTransitTrp ~ Age0to14 + Age15to19 + Age20to29 +
        Age30to54 +  Age55to64 + VehPerDrvAgePop + Urban +
        Dvmt |
        Age20to29 + Age30to54 +  Age65Plus +
        VehPerDrvAgePop + LogHbppopdn + Tranmilescap + Urban +
        LogDvmt
    )
  )
Formula_ls$NonMetro <-
  list(
    Walk = formula(
      NumWalkTrp ~ Hhsize + LogIncome + VehPerDrvAgePop +
        LogHbppopdn + LogDvmt
    ),
    Bike = formula(
      NumBikeTrp ~ Hhsize + Dvmt |
        Age0to14 + Age15to19 + Age20to29 + Age30to54 +
        Dvmt
    ),
    Transit = formula(
      NumTransitTrp ~ Hhsize + VehPerDrvAgePop + LogIncome +
        Dvmt |
        LogIncome + Age0to14 + Age20to29 + Age30to54 + Age55to64 +
        VehPerDrvAgePop + LogHbppopdn +
        LogDvmt
    )
  )

#Estimate models and save in list
#--------------------------------
AltModeModels_ls <- list()
AltModeModels_ls$Metro <-
  list(
    Walk = estimateHurdleTripModel(Formula_ls$Metro$Walk, MetroHh_df),
    Bike = estimateHurdleTripModel(Formula_ls$Metro$Bike, MetroHh_df),
    Transit = estimateHurdleTripModel(Formula_ls$Metro$Transit, MetroHh_df))
AltModeModels_ls$NonMetro <-
  list(
    Walk = estimateHurdleTripModel(Formula_ls$NonMetro$Walk, NonMetroHh_df),
    Bike = estimateHurdleTripModel(Formula_ls$NonMetro$Bike, NonMetroHh_df),
    Transit = estimateHurdleTripModel(Formula_ls$NonMetro$Transit, NonMetroHh_df))
#' Alternative model trip models
#'
#' A list of string representations for all alternative mode trip models
#'
#' @format A list having 'Metro' and 'NonMetro' components. Each component has
#' 'Walk', 'Bike' and 'Transit' components.
#' @source CalcAltModeTrips.R script.
"AltModeModels_ls"
devtools::use_data(AltModeModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalcAltModeTripsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  Inp = NULL,
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Metropolitan", "Town", "Rural")
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
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Hhsize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Hhincttl",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "dollars per year",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehPerDrvAgePop",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "vehicles per driving age person",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Htppopdn",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "persons per square mile",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Tranmilescap",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "annual transit revenue-miles per capita",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Urban",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "flag",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "average daily vehicle miles traveled",
      PROHIBIT = c("< 0", "> 1"),
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
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalcAltModeTrips module
#'
#' A list containing specifications for the CalcAltModeTrips module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalcAltModeTrips.R script.
"CalcAltModeTripsSpecifications"
devtools::use_data(CalcAltModeTripsSpecifications, overwrite = TRUE)


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
#' @export
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
#' \code{CalcAltModeTrips} calculates alternative mode trips for each
#' household.
#'
#' This function calculates walk, bike, and transit tripss for households.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @export
CalcAltModeTrips <- function(L) {
  #Prepare inputs
  D_df <- data.frame(L$Year$Household)
  D_df$Income <- L$Year$Household$Hhincttl
  D_df$Hbppopdn <- L$Year$Household$Htppopdn
  D_df$LogIncome <- log(D_df$Income)
  D_df$LogDvmt <- log(D_df$Dvmt)
  D_df$LogHbppopdn <- log(D_df$Hbppopdn)
  #Define function to calculate trips
  calcTrips <- function(Mode) {
    Trips_ <- nrow(D_df)
    IsMetro <- D_df$DevType == "Metropolitan"
    Trips_[IsMetro] <-
      applyHurdleTripModel(D_df[IsMetro,], AltModeModels_ls$Metro[[Mode]])
    Trips_[!IsMetro] <-
      applyHurdleTripModel(D_df[!IsMetro,], AltModeModels_ls$NonMetro[[Mode]])
    Trips_
  }
  #Calculate trips and return results
  Out_ls <- initDataList()
  Out_ls$Year$Household$WalkTrips = calcTrips("Walk")
  Out_ls$Year$Household$BikeTrips = calcTrips("Bike")
  Out_ls$Year$Household$TransitTrips = calcTrips("Transit")
  Out_ls
}


