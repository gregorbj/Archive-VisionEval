#========================
#AssignVehicleOwnership.R
#========================
#
#<doc>
#
## AssignVehicleOwnership Module
#### November 23, 2018
#
#This module determines the number of vehicles owned or leased by each household as a function of household characteristics, land use characteristics, and transportation system characteristics.
#
### Model Parameter Estimation
#
#The vehicle ownership model is segmented for metropolitan and non-metropolitan households because additional information about transit supply and the presence of urban mixed-use neighborhoods is available for metropolitan households that is not available for non-metropolitan households. There are two models for each segment. A binary logit model is used to predict which households own no vehicles. An ordered logit model is used to predict how many vehicles a household owns if they own any vehicles. The number of vehicles a household may be assigned is 6.
#
#The metropolitan model for determining whether a household owns no vehicles is documented below. As expected, the probability that a household is carless is greater for low income households (less than $20,000), households living in higher density and/or mixed-use neighborhoods, and households living in metropolitan areas having higher levels of transit service. The probability decreases as the number of drivers in the household increases, household income increases, and if the household lives in a single-family dwelling. The number of drivers has the greatest influence on car ownership. The number of workers increases the probability of no vehicle ownership, but since the model includes drivers, this coefficient probably reflects the effect of non-driving workers on vehicle ownership.
#
#<txt:AutoOwnModels_ls$Stats$MetroZeroSummary>
#
#The non-metropolitan model for zero car ownership is shown below. The model terms are the same as for the metropolitan model with the exception of the urban mixed-use and transit supply variables. The signs of the variables are the same as for the metropolitan model and the values are of similar magnitude.
#
#<txt:AutoOwnModels_ls$Stats$NonMetroZeroSummary>
#
#The ordered logit model for the number of vehicles owned by metropolitan households that own at least one vehicle is shown below. Households are likely to own more vehicles if they live in a single-family dwelling, have higher incomes, have more workers, and have more drivers. Households are likely to own fewer vehicles if all household members are elderly, they live in a higher density and/or urban mixed-use neighborhood, they live in a metropolitan area with a higher level of transit service, and if more persons are in the household. The latter result is at surprising at first glance, but since the model also includes the number of drivers and number of workers, the household size coefficient is probably showing the effect of non-drivers non-workers in the household.
#
#<txt:AutoOwnModels_ls$Stats$MetroCountSummary>
#
#The ordered logit model for non-metropolitan household vehicle ownership is described below. The variables are the same as for the metropolitan model with the exception of the urban mixed-use neighborhood and transit variables. The signs of the coefficients are the same and the magnitudes are similar.
#
#<txt:AutoOwnModels_ls$Stats$NonMetroCountSummary>
#
### How the Module Works
#
#For each household, the metropolitan or non-metropolitan binary logit model is run to predict the probability that the household owns no vehicles. A random number is drawn from a uniform distribution in the interval from 0 to 1 and if the result is less than the probability of zero-vehicle ownership, the household is assigned no vehicles. Households that have no drivers are also assigned 0 vehicles. The metropolitan or non-metropolitan ordered logit model is run to predict the number of vehicles owned by the household if they own any.
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(ordinal)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#The vehicle ownership model is segmented for metropolitan and non-metropolitan
#households because additional information about transit supply and the presence
#of urban mixed-use neighborhoods is available for metropolitan households that
#is not available for non-metropolitan households. There are two models for each
#segment. A binary logit model is used to predict which households own no
#vehicles. An ordered logit model is used to predict how many vehicles a
#household owns if they own any vehicles.

#Create model estimation dataset
#-------------------------------
#Load selected data from VE2001NHTS package
Hh_df <- VE2001NHTS::Hh_df
FieldsToKeep_ <-
  c("NumVeh", "Income", "Hbppopdn", "Hhsize", "Hometype", "UrbanDev", "FwyLnMiPC",
    "Wrkcount", "Drvrcnt", "Age0to14", "Age65Plus", "MsaPopDen", "BusEqRevMiPC")
Hh_df <- Hh_df[, FieldsToKeep_]
#Create additional data fields
Hh_df$IsSF <- as.numeric(Hh_df$Hometype %in% c("Single Family", "Mobile Home"))
Hh_df$HhSize <- Hh_df$Hhsize
Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
Hh_df$OnlyElderly <- as.numeric(Hh_df$HhSize == Hh_df$Age65Plus)
Hh_df$LogIncome <- log1p(Hh_df$Income)
Hh_df$LogDensity <- log(Hh_df$Hbppopdn)
Hh_df$ZeroVeh <- as.numeric(Hh_df$NumVeh == 0)
Hh_df$LowInc <- as.numeric(Hh_df$Income <= 20000)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$Drivers <- Hh_df$Drvrcnt
Hh_df$IsUrbanMixNbrhd <- Hh_df$UrbanDev
Hh_df$TranRevMiPC <- Hh_df$BusEqRevMiPC
rm(FieldsToKeep_)

#Create a list to store models
#-----------------------------
AutoOwnModels_ls <-
  list(
    Metro = list(),
    NonMetro = list(),
    Stats = list()
  )

#Model metropolitan households
#-----------------------------
#Make metropolitan household estimation dataset
Terms_ <-
  c("IsSF", "IsUrbanMixNbrhd", "Workers", "Drivers", "TranRevMiPC", "LogIncome",
    "HhSize", "LogDensity", "OnlyElderly", "LowInc", "NumVeh", "ZeroVeh",
    "FwyLnMiPC")
EstData_df <- Hh_df[!is.na(Hh_df$TranRevMiPC), Terms_]
EstData_df <- EstData_df[complete.cases(EstData_df),]
rm(Terms_)
#Model zero vehicle households
AutoOwnModels_ls$Metro$Zero <-
  glm(
    ZeroVeh ~ Workers + LowInc + LogIncome + IsSF + Drivers + IsUrbanMixNbrhd +
      LogDensity + TranRevMiPC,
    data = EstData_df,
    family = binomial
  )
AutoOwnModels_ls$Stats$MetroZeroSummary <-
  capture.output(summary(AutoOwnModels_ls$Metro$Zero))
AutoOwnModels_ls$Stats$MetroZeroAnova <-
  capture.output(anova(AutoOwnModels_ls$Metro$Zero, test = "Chisq"))
#Trim down model
AutoOwnModels_ls$Metro$Zero[c("residuals", "fitted.values",
                              "linear.predictors", "weights",
                              "prior.weights", "y", "model",
                              "data")] <- NULL
#Model number of vehicles of non-zero vehicle households
EstData_df <- EstData_df[EstData_df$ZeroVeh == 0,]
EstData_df$VehOrd <- EstData_df$NumVeh
EstData_df$VehOrd[EstData_df$VehOrd > 6] <- 6
EstData_df$VehOrd <- ordered(EstData_df$VehOrd)
AutoOwnModels_ls$Metro$Count <-
  clm(
    VehOrd ~ Workers + LogIncome + Drivers + HhSize + OnlyElderly + IsSF +
      IsUrbanMixNbrhd + LogDensity + TranRevMiPC,
    data = EstData_df,
    threshold = "equidistant"
  )
AutoOwnModels_ls$Stats$MetroCountSummary <-
  capture.output(summary(AutoOwnModels_ls$Metro$Count))
#Trim down model
AutoOwnModels_ls$Metro$Count[c("fitted.values", "model", "y")] <- NULL

#Model non-metropolitan households
#---------------------------------
#Make non-metropolitan household estimation dataset
Terms_ <-
  c("IsSF", "Workers", "Drivers", "LogIncome", "HhSize", "LogDensity",
    "OnlyElderly", "LowInc", "NumVeh", "ZeroVeh")
EstData_df <- Hh_df[is.na(Hh_df$TranRevMiPC), Terms_]
EstData_df <- EstData_df[complete.cases(EstData_df),]
#Remove 2 cases with 10 workers in household. Including them in the model
#estimation causes probabilities close to zero which reduces the reliability of
#the estimated model
EstData_df <- EstData_df[EstData_df$Workers != 10,]
rm(Terms_)
#Model zero vehicle households
AutoOwnModels_ls$NonMetro$Zero <-
  glm(
    ZeroVeh ~ Workers + LowInc + LogIncome + IsSF + Drivers + LogDensity,
    data = EstData_df,
    family = binomial
  )
AutoOwnModels_ls$Stats$NonMetroZeroSummary <-
  capture.output(summary(AutoOwnModels_ls$NonMetro$Zero))
AutoOwnModels_ls$Stats$NonMetroZeroAnova <-
  capture.output(anova(AutoOwnModels_ls$NonMetro$Zero, test = "Chisq"))
#Trim down model
AutoOwnModels_ls$NonMetro$Zero[c("residuals", "fitted.values",
                              "linear.predictors", "weights",
                              "prior.weights", "y", "model",
                              "data")] <- NULL
#Model number of vehicles of non-zero vehicle households
EstData_df <- EstData_df[EstData_df$ZeroVeh == 0,]
EstData_df$VehOrd <- EstData_df$NumVeh
EstData_df$VehOrd[EstData_df$VehOrd > 6] <- 6
EstData_df$VehOrd <- ordered(EstData_df$VehOrd)
AutoOwnModels_ls$NonMetro$Count <-
  clm(
    VehOrd ~ Workers + LogIncome + Drivers + HhSize + OnlyElderly + IsSF +
      LogDensity,
    data = EstData_df,
    threshold = "equidistant"
  )
AutoOwnModels_ls$Stats$NonMetroCountSummary <-
  capture.output(summary(AutoOwnModels_ls$NonMetro$Count))
#Trim down model
AutoOwnModels_ls$NonMetro$Count[c("fitted.values", "model", "y")] <- NULL
#Clean up
rm(Hh_df, EstData_df)

#Save the auto ownership model
#-----------------------------
#' Auto ownership model
#'
#' A list containing the auto ownership model equation and other information
#' needed to implement the auto ownership model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Metro}{a list containing two models for metropolitan areas: a Zero
#'   component that is a binomial logit model for determining which households
#'   own no vehicles and a Count component that is an ordered logit model for
#'   determining how many vehicles a household who has vehicles owns}
#'   \item{NonMetro}{a list containing two models for non-metropolitan areas: a
#'   Zero component that is a binomial logit model for determining which households
#'   own no vehicles and a Count component that is an ordered logit model for
#'   determining how many vehicles a household who has vehicles owns}
#' }
#' @source AssignVehicleOwnership.R script.
"AutoOwnModels_ls"
usethis::use_data(AutoOwnModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleOwnershipSpecifications <- list(
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
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "Age65Plus",
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
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of automobiles and light trucks owned or leased by the household including high level car service vehicles available to driving-age persons"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignVehicleOwnership module
#'
#' A list containing specifications for the AssignVehicleOwnership module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignVehicleOwnership.R script.
"AssignVehicleOwnershipSpecifications"
usethis::use_data(AssignVehicleOwnershipSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns the number of vehicles a household owns.

#Main module function that calculates vehicle ownership
#------------------------------------------------------
#' Calculate the number of vehicles owned by the household.
#'
#' \code{AssignVehicleOwnership} calculate the number of vehicles owned by each
#' household.
#'
#' This function calculates the number of vehicles owned by each household
#' given the characteristic of the household and the area where it resides.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignVehicleOwnership
#' @import visioneval ordinal
#' @export
AssignVehicleOwnership <- function(L) {
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
  Hh_df$IsSF <- as.numeric(Hh_df$HouseType == "SF")
  Hh_df$OnlyElderly <- as.numeric(Hh_df$HhSize == Hh_df$Age65Plus)
  Hh_df$LowInc <- as.numeric(Hh_df$Income <= 20000)
  Hh_df$LogIncome <- log1p(Hh_df$Income)
  Density_ <- L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$LogDensity <- log(Density_)
  TranRevMiPC_Bz <- L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$TranRevMiPC <- TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]

  #Run the model
  #-------------
  #Probability no vehicles
  NoVehicleProb_ <- numeric(NumHh)
  NoVehicleProb_[Hh_df$LocType == "Urban"] <-
    predict(AutoOwnModels_ls$Metro$Zero,
            newdata = Hh_df[Hh_df$LocType == "Urban",],
            type = "response")
  NoVehicleProb_[Hh_df$LocType %in% c("Town", "Rural")] <-
    predict(AutoOwnModels_ls$NonMetro$Zero,
            newdata = Hh_df[Hh_df$LocType %in% c("Town", "Rural"),],
            type = "response")
  #Vehicle counts
  Vehicles_ <- integer(NumHh)
  Vehicles_[Hh_df$LocType == "Urban"] <-
    as.integer(predict(AutoOwnModels_ls$Metro$Count,
            newdata = Hh_df[Hh_df$LocType == "Urban",],
            type = "class")$fit)
  Vehicles_[Hh_df$LocType %in% c("Town", "Rural")] <-
    as.integer(predict(AutoOwnModels_ls$NonMetro$Count,
            newdata = Hh_df[Hh_df$LocType %in% c("Town", "Rural"),],
            type = "class")$fit)
  #Set count to zero for households modeled as having no vehicles
  Vehicles_[NoVehicleProb_ >= runif(NumHh)] <- 0
  #Set count to zero for households having no drivers
  Vehicles_[L$Year$Household$Drivers == 0] <- 0

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(Vehicles = Vehicles_)
  #Return the outputs list
  Out_ls
}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignVehicleOwnership")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
# library(ordinal)
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
#   ModuleName = "AssignVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignVehicleOwnership(L)
#
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore =TRUE,
#   DoRun = TRUE
# )
