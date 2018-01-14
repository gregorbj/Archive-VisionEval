#========================
#AssignVehicleOwnership.R
#========================
#This module assigns household vehicle ownership based on household, land use,
#and transportation system characteristics.

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
FieldsToKeep_ <-
  c("NumVeh", "Income", "Hbppopdn", "Hhsize", "Hometype", "UrbanDev", "FwyLnMiPC",
    "Wrkcount", "Age0to14", "Age65Plus", "MsaPopDen", "BusEqRevMiPC")
Hh_df <- VE2001NHTS::Hh_df[, FieldsToKeep_]
#Create additional data fields
Hh_df$IsSF <- as.numeric(Hh_df$Hometype %in% c("Single Family", "Mobile Home"))
Hh_df$HhSize <- Hh_df$Hhsize
Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
Hh_df$OnlyElderly <- as.numeric(Hh_df$HhSize == Hh_df$Age65Plus)
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$LogDensity <- log(Hh_df$Hbppopdn)
Hh_df$ZeroVeh <- as.numeric(Hh_df$NumVeh == 0)
Hh_df$LowInc <- as.numeric(Hh_df$Income <= 20000)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$IsUrbanMixNbrhd <- Hh_df$UrbanDev
Hh_df$TranRevMiPC <- Hh_df$BusEqRevMiPC
rm(FieldsToKeep_)

#Create a list to store models
#-----------------------------
AutoOwnModels_ls <-
  list(
    Metro = list(),
    NonMetro = list()
  )

#Model metropolitan households
#-----------------------------
#Make metropolitan household estimation dataset
Terms_ <-
  c("IsSF", "IsUrbanMixNbrhd", "Workers", "DrvAgePop", "TranRevMiPC", "LogIncome",
    "HhSize", "LogDensity", "OnlyElderly", "LowInc", "NumVeh", "ZeroVeh",
    "FwyLnMiPC")
EstData_df <- Hh_df[!is.na(Hh_df$TranRevMiPC), Terms_]
EstData_df <- EstData_df[complete.cases(EstData_df),]
rm(Terms_)
#Model zero vehicle households
AutoOwnModels_ls$Metro$Zero <-
  glm(
    ZeroVeh ~ Workers + LowInc + LogIncome + IsSF + DrvAgePop +
      IsUrbanMixNbrhd + LogDensity + TranRevMiPC,
    data = EstData_df,
    family = binomial
  )
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
    VehOrd ~ Workers + LogIncome + DrvAgePop + HhSize + OnlyElderly + IsSF +
      IsUrbanMixNbrhd + LogDensity + TranRevMiPC,
    data = EstData_df,
    threshold = "equidistant"
  )
#Trim down model
AutoOwnModels_ls$Metro$Count[c("fitted.values", "model", "y")] <- NULL

#Model nonmetropolitan households
#--------------------------------
#Make non-metropolitan household estimation dataset
Terms_ <-
  c("IsSF", "Workers", "DrvAgePop", "LogIncome", "HhSize",
    "LogDensity", "OnlyElderly", "LowInc", "NumVeh", "ZeroVeh")
EstData_df <- Hh_df[is.na(Hh_df$TranRevMiPC), Terms_]
EstData_df <- EstData_df[complete.cases(EstData_df),]
rm(Terms_)
#Model zero vehicle households
AutoOwnModels_ls$NonMetro$Zero <-
  glm(
    ZeroVeh ~ Workers + LowInc + LogIncome + IsSF + DrvAgePop + LogDensity + OnlyElderly,
    data = EstData_df,
    family = binomial
  )
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
    VehOrd ~ Workers + LogIncome + DrvAgePop + HhSize + OnlyElderly + IsSF + LogDensity,
    data = EstData_df,
    threshold = "equidistant"
  )
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
devtools::use_data(AutoOwnModels_ls, overwrite = TRUE)


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
      NAME = "Workers",
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
      NAME =
        items(
          "Age0to14",
          "Age65Plus"),
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
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBITED = "NA",
      ISELEMENTOF = c("Urban", "Rural")
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
      DESCRIPTION = "Number of automobiles and light trucks owned or leased by the household"
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
devtools::use_data(AssignVehicleOwnershipSpecifications, overwrite = TRUE)


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
#' @import visioneval
#' @import ordinal
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
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$OnlyElderly <- as.numeric(Hh_df$HhSize == Hh_df$Age65Plus)
  Hh_df$LowInc <- as.numeric(Hh_df$Income <= 20000)
  Hh_df$LogIncome <- log(Hh_df$Income)
  Density_ <- L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$LogDensity <- log(Density_)
  TranRevMiPC_Bz <- L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$TranRevMiPC <- TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]

  #Run the model
  #-------------
  NoVehicleProb_ <- numeric(NumHh)
  NoVehicleProb_[Hh_df$DevType == "Urban"] <-
    predict(AutoOwnModels_ls$Metro$Zero,
            newdata = Hh_df[Hh_df$DevType == "Urban",],
            type = "response")
  NoVehicleProb_[Hh_df$DevType == "Rural"] <-
    predict(AutoOwnModels_ls$NonMetro$Zero,
            newdata = Hh_df[Hh_df$DevType == "Rural",],
            type = "response")
  Vehicles_ <- integer(NumHh)
  Vehicles_[Hh_df$DevType == "Urban"] <-
    as.integer(predict(AutoOwnModels_ls$Metro$Count,
            newdata = Hh_df[Hh_df$DevType == "Urban",],
            type = "class")$fit)
  Vehicles_[Hh_df$DevType == "Rural"] <-
    as.integer(predict(AutoOwnModels_ls$NonMetro$Count,
            newdata = Hh_df[Hh_df$DevType == "Rural",],
            type = "class")$fit)
  Vehicles_[NoVehicleProb_ >= runif(NumHh)] <- 0

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(Vehicles = Vehicles_)
  #Return the outputs list
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
#   ModuleName = "AssignVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
