#===================
#AssignVehicleType.R
#===================
#This module identifies how many household vehicles are light trucks and how
#many are automobiles. Automobiles are vehicles classified as passenger cars and not as
#light trucks (pickup trucks, sport utility vehicles, vans)


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This model predicts vehicle type (auto or light truck) for household
#vehicles based on characteristics of the household, the place where the
#household resides, the number of vehicles it owns, and areawide targets for
#light truck ownership.

#Define a function to estimate vehicle type choice model
#-------------------------------------------------------
#' Estimate vehicle type choice model
#'
#' \code{estimateVehicleTypeModel} estimates a binomial logit model for choosing
#' between light trucks and automobiles.
#'
#' This function estimates a binomial logit model for predicting vehicle type
#' choice (automobile or light truck) as a function of the characteristics of
#' the household, the number of vehicles it owns, the place where the household
#' resides, and targets for light-truck ownership.
#'
#' @param EstData_df A data frame containing estimation data.
#' @param Counts_mx A numeric matrix of counts of household light trucks and
#' automobiles for each household.
#' @param StartTerms_ A character vector of the terms of the model to be
#' tested in the model. The function estimates the model using these terms
#' and then drops all terms whose p value is greater than 0.05.
#' @return A list which has the following components:
#' Type: a string identifying the type of model ("binomial"),
#' Formula: a string representation of the model equation,
#' PrepFun: a function that prepares inputs to be applied in the binomial model,
#' OutFun: a function that transforms the result of applying the binomial model.
#' Summary: the summary of the binomial model estimation results.
#' @import visioneval
#Define function to estimate the income model
estimateVehicleTypeModel <- function(EstData_df, Counts_mx, StartTerms_) {
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
        paste("Counts_mx ~ ", paste(StartTerms_, collapse = "+"))
      as.formula(FormulaString)
    }
  #Estimate model
  VehicleTypeModel <-
    glm(makeFormula(StartTerms_), family = binomial, data = EstData_df)
  #Return model
  list(
    Type = "binomial",
    Formula = makeModelFormulaString(VehicleTypeModel),
    Choices = c("LtTrk", "Auto"),
    PrepFun = prepIndepVar,
    Summary = summary(VehicleTypeModel),
    RepeatVar = "Vehicles"
  )
}

#Estimate the binomial logit model
#---------------------------------
#Load and select NHTS household data
Hh_df <- VE2001NHTS::Hh_df
HhVars_ <-
  c("Houseid", "Hbppopdn", "Hhsize", "Age0to14", "Income", "Wrkcount",
    "Hometype", "UrbanDev", "TownDev", "SuburbanDev", "RuralDev", "SecondCityDev",
    "NumAuto", "NumLightTruck", "NumVeh")
Hh_df <- Hh_df[,HhVars_]
Hh_df <- Hh_df[,HhVars_]
Hh_df <- Hh_df[complete.cases(Hh_df),]
Hh_df <- Hh_df[Hh_df$NumVeh != 0,]
rm(HhVars_)
#Create independent variables that will be used in estimation
Hh_df$Density <- Hh_df$Hbppopdn
Hh_df$LogDensity <- log(Hh_df$Density)
Hh_df$HhSize <- Hh_df$Hhsize
Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
Hh_df$IsSF <- as.numeric(Hh_df$Hometype %in% c("Single Family", "Mobile Home"))
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$LogDensity <- log(Hh_df$Hbppopdn)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$IsUrbanMixNbrhd <- Hh_df$UrbanDev
Hh_df$Vehicles <- Hh_df$NumVeh
Hh_df$VehPerDrvAgePop <- Hh_df$Vehicles / Hh_df$DrvAgePop

#Create dependent variable matrix of choice proportions
Veh_df <- VE2001NHTS::Veh_df[,c("Houseid", "Type")]
NumLtTrk_Hh <-
  tapply(Veh_df$Type == "LightTruck", Veh_df$Houseid, sum)[Hh_df$Houseid]
NumAuto_Hh <- Hh_df$Vehicles - NumLtTrk_Hh
DepVar_mx <- cbind(NumLtTrk_Hh, NumAuto_Hh)
colnames(DepVar_mx) <- c("LtTrk", "Auto")
rm(NumLtTrk_Hh, NumAuto_Hh)

#Select independent variables
VehicleTypeModelTerms_ <-
  c(
    "Density",
    "Age0to14",
    "DrvAgePop",
    "IsSF",
    "LogIncome",
    "IsUrbanMixNbrhd",
    "Vehicles",
    "VehPerDrvAgePop",
    "Workers"
  )
#Estimate model
VehicleTypeModel_ls <- estimateVehicleTypeModel(Hh_df, DepVar_mx, VehicleTypeModelTerms_)
#Model summary
VehicleTypeModel_ls$Summary

#Check the model
#---------------
#Model will be run using household data applied as many times as there are
#vehicles in the household
#Predict values, sum number of predicted and observed light trucks by households
Pred <- applyBinomialModel(VehicleTypeModel_ls, Hh_df)
ObsLtTrk_Hh <-
  tapply(Veh_df$Type == "LightTruck", Veh_df$Houseid, sum)[Hh_df$Houseid]
PredLtTrk_Hh <-
  tapply(Pred == "LtTrk", rep(Hh_df$Houseid, Hh_df$Vehicles), sum)[Hh_df$Houseid]
#Table of predicted vs. observed number of trucks
Tab <- table(PredLtTrk_Hh, ObsLtTrk_Hh)
#Compare ratio of correctly predicted households vs. total households
sum(diag(Tab)) / sum(Tab)
#Compare ratio of correctly predicted households by number of light trucks
diag(Tab)[1:7] / rowSums(Tab[1:7,1:7])
#Clean up
rm(VehicleTypeModelTerms_, ObsLtTrk_Hh, PredLtTrk_Hh, Tab, Pred, DepVar_mx)

#Estimate the search range for matching target housing proportions
#-----------------------------------------------------------------
#The housing choice model can be adjusted (self-calibrated) to match a target
#single family housing proportion. This uses capabilities in the visioneval
#applyBinomialModel() function and the binarySearch() function to adjust the
#intercept of the model to match the input proportion. To do so the model needs
#to specify a search range.
#Check search range of values to use
VehicleTypeModel_ls$SearchRange <- c(-10, 10)
applyBinomialModel(
  VehicleTypeModel_ls,
  Hh_df,
  TargetProp = NULL,
  CheckTargetSearchRange = TRUE)
#Check that low target can be matched with search range
Target <- 0.01
LowResult_ <- applyBinomialModel(
  VehicleTypeModel_ls,
  Hh_df,
  TargetProp = Target
)
Result <- round(table(LowResult_) / length(LowResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, LowResult_, Result)
#Check that high target can be matched with search range
Target <- 0.99
HighResult_ <- applyBinomialModel(
  VehicleTypeModel_ls,
  Hh_df,
  TargetProp = Target
)
Result <- round(table(HighResult_) / length(HighResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, HighResult_, Result)
rm(Hh_df, Veh_df)

#Save the vehicle type choice model
#----------------------------------
#' Vehicle type choice model
#'
#' A list containing the vehicle type choice model equation and other information
#' needed to implement the vehicle type choice model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("binomial")}
#'   \item{Formula}{makeModelFormulaString(VehicleTypeModel)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the model}
#'   \item{Summary}{the summary of the binomial logit model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source AssignVehicleType.R script.
"VehicleTypeModel_ls"
usethis::use_data(VehicleTypeModel_ls, overwrite = TRUE)

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleTypeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "LtTrkProp",
      FILE = "azone_lttrk_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Proportion of household vehicles that are light trucks (pickup, SUV, van)"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "LtTrkProp",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<= 0", ">= 1"),
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
      TABLE = "Bzone",
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
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Age0to14",
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
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "NA",
      ISELEMENTOF = c(0, 1)
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = items(
        "NumLtTrk",
        "NumAuto"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household",
        "Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignVehicleType module
#'
#' A list containing specifications for the AssignVehicleType module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignVehicleType.R script.
"AssignVehicleTypeSpecifications"
usethis::use_data(AssignVehicleTypeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns the numbers of automobiles and light trucks to each
#household.

#Main module function that identifies number of household autos and light trucks
#-------------------------------------------------------------------------------
#' Assign number of autos and light trucks for each household.
#'
#' \code{AssignVehicleType} assigns the numbers of autos and light trucks in
#' each household.
#'
#' This function assigns the numbers of autos and light trucks in each
#' household.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignVehicleType
#' @import visioneval
#' @export
AssignVehicleType <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Bzones
  Bz <- L$Year$Bzone$Bzone

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Data_df <- data.frame(L$Year$Household)
  Data_df$Density <-
    L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Data_df$DrvAgePop <- Data_df$HhSize - Data_df$Age0to14
  Data_df$VehPerDrvAgePop <- Data_df$Vehicles / Data_df$DrvAgePop
  Data_df$IsSF <- as.numeric(Data_df$HouseType == "SF")
  Data_df$LogIncome <- log(Data_df$Income)
  #Identify households that have vehicles
  HasVeh_Hh <- Data_df$Vehicles != 0

  #Run the model
  #-------------
  VehType_Hx <-
    applyBinomialModel(
      VehicleTypeModel_ls,
      Data_df[HasVeh_Hh,],
      TargetProp = L$Year$Azone$LtTrkProp
    )

  #Tabulate autos and light trucks by household
  #--------------------------------------------
  HhId_Hx <-
    rep(Data_df$HhId[HasVeh_Hh], Data_df$Vehicles[HasVeh_Hh])
  NumLtTrk_Hx <- tapply(VehType_Hx == "LtTrk", HhId_Hx, sum)
  NumAuto_Hx <- tapply(VehType_Hx == "Auto", HhId_Hx, sum)
  NumLtTrk_Hh <- NumLtTrk_Hx[Data_df$HhId]
  NumLtTrk_Hh[is.na(NumLtTrk_Hh)] <- 0
  NumAuto_Hh <- NumAuto_Hx[Data_df$HhId]
  NumAuto_Hh[is.na(NumAuto_Hh)] <- 0

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(NumLtTrk = NumLtTrk_Hh,
         NumAuto = NumAuto_Hh)
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
#   ModuleName = "AssignVehicleType",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleType",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
