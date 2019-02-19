#===================
#AssignVehicleType.R
#===================
#
#<doc>
#
## AssignVehicleType Module
#### November 23, 2018
#
#This module identifies how many household vehicles are light trucks and how many are automobiles. Light trucks include pickup trucks, sport utility vehicles, vans, and any other vehicle not classified as a passenger car. Automobiles are vehicles classified as passenger cars. The crossover vehicle category [blurs the line between light trucks and passenger vehicles](https://www.eia.gov/todayinenergy/detail.php?id=31352). Their classification as light trucks or automobiles depends on the agency doing the classification and purpose of the classification. These vehicles were not a significant portion of the market when the model estimation data were collected and so are not explictly considered. How they are classified is up to the model user who is responsible for specifying the light truck proportion of the vehicle fleet.
#
### Model Parameter Estimation
#
#A binary logit models are estimated to predict the probability that a household vehicle is a light truck. A summary of the estimated model follows. The probability that a vehicle is a light truck increases if:
#
#* The ratio of the number of persons in the household to the number of vehicles in the household increases;
#
#* The number of children in the household increases;
#
#* The ratio of vehicles to drivers increases, especially if the number of vehicles is greater than the number of drivers; and,
#
#* The household lives in a single-family dwelling.
#
#The probability decreases if:
#
#* The household only owns one vehicle;
#
#* The household has low income (less than $20,000 in year 2000 dollars);
#
#* The household lives in a higher density neighborhood; and,
#
#* The household lives in an urban mixed-use neighborhood.
#
#<txt:VehicleTypeModel_ls$Summary>
#
#The model and all of its independent variables are significant, but it only explains a modest proportion of the observed variation in light truck ownership. When the model is applied to the estimation dataset, it correctly predicts the number of light trucks for about 46% of the households. Over predictions and under predictions are approximately equal as shown in the following table.
#
#<tab:VehicleTypeModel_ls$PredictionTest>
#
### How the Module Works
#
#The user inputs the light truck proportion of vehicles observed or assumed each each Azone. The module calls the `applyBinomialModel` function (part of the *visioneval* framework package), passing it the estimated binomial logit model and a data frame of values for the independent variables, and the user-supplied light truck proportion. The `applyBinomialModel` function uses a binary search algorithm to adjust the intercept of the model so that the resulting light truck proportion of all household vehicles in the Azone equals the user input.
#
#</doc>


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
    Summary = capture.output(summary(VehicleTypeModel)),
    RepeatVar = "Vehicles"
  )
}

#Estimate the binomial logit model
#---------------------------------
#Load and select NHTS household data
HhVars_ <-
  c("Houseid", "Hbppopdn", "Hhsize", "Age0to14", "Age15to19", "Hhsize",
    "Income", "Drvrcnt", "Wrkcount", "Hometype", "UrbanDev", "NumAuto",
    "NumLightTruck", "NumVeh")
Hh_df <- VE2001NHTS::Hh_df[, HhVars_]
Hh_df <- Hh_df[complete.cases(Hh_df),]
Hh_df <- Hh_df[Hh_df$NumVeh != 0,]
Hh_df <- Hh_df[Hh_df$Drvrcnt >= 1,]
rm(HhVars_)
#Create independent variables that will be used in estimation
Hh_df$Density <- Hh_df$Hbppopdn
Hh_df$LogDensity <- log(Hh_df$Density)
Hh_df$HhSize <- Hh_df$Hhsize
Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
Hh_df$IsSF <- as.numeric(Hh_df$Hometype %in% c("Single Family", "Mobile Home"))
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$IsUrbanMixNbrhd <- Hh_df$UrbanDev
Hh_df$Vehicles <- Hh_df$NumVeh
Hh_df$VehPerDrvAgePop <- Hh_df$Vehicles / Hh_df$DrvAgePop
Hh_df$VehPerDvr <- Hh_df$Vehicles / Hh_df$Drvrcnt
Hh_df$NumChild <- Hh_df$Age0to14 + Hh_df$Age15to19
Hh_df$NumAdult <- Hh_df$HhSize - Hh_df$NumChild
Hh_df$IsLowIncome <- as.numeric(Hh_df$Income <= 20000)
Hh_df$OnlyOneVeh <- as.numeric(Hh_df$Vehicles == 1)
Hh_df$NumVehGtNumDvr <- as.numeric(Hh_df$Vehicles > Hh_df$Drvrcnt)
Hh_df$NumVehEqNumDvr <- as.numeric(Hh_df$Vehicles == Hh_df$Drvrcnt)
Hh_df$NumVehLtNumDvr <- as.numeric(Hh_df$Vehicles < Hh_df$Drvrcnt)
Hh_df$PrsnPerVeh <- Hh_df$Hhsize / Hh_df$Vehicles
#Create dependent variable matrix of choice proportions
DepVar_mx <- cbind(Hh_df$NumLightTruck, Hh_df$NumAuto)
colnames(DepVar_mx) <- c("LtTrk", "Auto")
#Select independent variables
VehicleTypeModelTerms_ <-
  c(
    "PrsnPerVeh",
    "NumChild",
    "NumVehGtNumDvr",
    "NumVehEqNumDvr",
    "IsSF",
    "OnlyOneVeh",
    "IsLowIncome",
    "LogDensity",
    "IsUrbanMixNbrhd"
  )
#Estimate model
VehicleTypeModel_ls <- estimateVehicleTypeModel(Hh_df, DepVar_mx, VehicleTypeModelTerms_)

#Check the model
#---------------
#Apply the model to household data applied as many times as there are vehicles
#in the household to predict the numbers of light trucks and automobiles.
#Household light truck predictions to observed numbers of light trucks. Tabulate
#the proportion of households with the correct number of light truck
#predictions, the proportion of households for which the number of light trucks
#is under predicted, and the proportion of households for which the number of
#light trucks is over predicted
VehicleTypeModel_ls$PredictionTest <- local({
  #Predict values, sum number of predicted and observed light trucks by households
  Pred <- applyBinomialModel(VehicleTypeModel_ls, Hh_df)
  ObsLtTrk_Hh <- Hh_df$NumLightTruck
  PredLtTrk_Hh <-
    tapply(Pred == "LtTrk", rep(Hh_df$Houseid, Hh_df$Vehicles), sum)[Hh_df$Houseid]
  #Table of predicted vs. observed number of trucks
  Tab <- table(PredLtTrk_Hh, ObsLtTrk_Hh)
  #Calculate the proportions of correctly predicted, underpredicted, and
  #overpredicted number of light trucks in households
  PredResults_ <- c(
    sum(upper.tri(Tab) * Tab),
    sum(diag(Tab)),
    sum(lower.tri(Tab) * Tab)
  )
  data.frame(
    Prediction = c("Under Predict", "Correctly Predict", "Over Predict"),
    Proportion = round(PredResults_ / sum(Tab), 3)
  )
})
#Clean up
rm(VehicleTypeModelTerms_, DepVar_mx)

#Estimate the search range for matching target housing proportions
#-----------------------------------------------------------------
#The housing choice model can be adjusted (self-calibrated) to match a target
#single family housing proportion. This uses capabilities in the visioneval
#applyBinomialModel() function and the binarySearch() function to adjust the
#intercept of the model to match the input proportion. To do so the model needs
#to specify a search range.
#Check search range of values to use
VehicleTypeModel_ls$SearchRange <- c(-10, 10)
# applyBinomialModel(
#   VehicleTypeModel_ls,
#   Hh_df,
#   TargetProp = NULL,
#   CheckTargetSearchRange = TRUE)
#Check that low target can be matched with search range
Target <- 0.01
LowResult_ <- applyBinomialModel(
  VehicleTypeModel_ls,
  Hh_df,
  TargetProp = Target
)
Result <- round(table(LowResult_) / length(LowResult_), 2)
#paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, LowResult_, Result)
#Check that high target can be matched with search range
Target <- 0.99
HighResult_ <- applyBinomialModel(
  VehicleTypeModel_ls,
  Hh_df,
  TargetProp = Target
)
Result <- round(table(HighResult_) / length(HighResult_), 2)
#paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, HighResult_, Result)
rm(Hh_df)

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
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "LtTrkProp",
      FILE = "azone_hh_lttrk_prop.csv",
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
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
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
      NAME = items(
        "Bzone",
        "Azone"),
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
      NAME = items(
        "Bzone",
        "Azone"),
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
      NAME = items(
        "Age0to14",
        "Age15to19"),
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
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

  #Iterate through Azones to estimate model matching Azone light-truck average
  #---------------------------------------------------------------------------
  NumLtTrk_Hh <- with(L$Year$Household, setNames(numeric(length(HhId)), HhId))
  NumAuto_Hh <- with(L$Year$Household, setNames(numeric(length(HhId)), HhId))
  Az <- L$Year$Azone$Az
  for (az in Az) {
    #Set up data frame of household data needed for model
    Use <- L$Year$Household$Azone == az & L$Year$Household$Vehicles > 0
    Data_df <- data.frame(lapply(L$Year$Household, function(x) x[Use]))
    #Add variables needed for vehicle type model
    Data_df$PrsnPerVeh <- Data_df$HhSize / Data_df$Vehicles
    Data_df$NumChild <- Data_df$Age0to14 + Data_df$Age15to19
    Data_df$NumVehGtNumDvr <- as.numeric(Data_df$Vehicles > Data_df$Drivers)
    Data_df$NumVehEqNumDvr <- as.numeric(Data_df$Vehicles == Data_df$Drivers)
    Data_df$IsSF <- as.numeric(Data_df$HouseType == "SF")
    Data_df$OnlyOneVeh <- as.numeric(Data_df$Vehicles == 1)
    Data_df$IsLowIncome <- as.numeric(Data_df$Income <= 20000)
    Data_df$Density <- L$Year$Bzone$D1B[match(Data_df$Bzone, L$Year$Bzone$Bzone)]
    Data_df$Density[Data_df$Density == 0] <- 1e-6
    Data_df$LogDensity <- log(Data_df$Density)
    #Run the model
    VehType_Hx <-
      applyBinomialModel(
        VehicleTypeModel_ls,
        Data_df,
        TargetProp = L$Year$Azone$LtTrkProp[L$Year$Azone$Azone == az]
      )
    #Tabulate autos and light trucks by household
    HhId_Hx <- rep(Data_df$HhId, Data_df$Vehicles)
    NumLtTrk_Hx <- tapply(VehType_Hx == "LtTrk", HhId_Hx, sum)
    NumAuto_Hx <- tapply(VehType_Hx == "Auto", HhId_Hx, sum)
    NumLtTrk_Hh[names(NumLtTrk_Hx)] <- NumLtTrk_Hx
    NumAuto_Hh[names(NumAuto_Hx)] <- NumAuto_Hx
  }

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(NumLtTrk = unname(NumLtTrk_Hh),
         NumAuto = unname(NumAuto_Hh))
  #Return the outputs list
  Out_ls
}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignVehicleType")

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
#   ModuleName = "AssignVehicleType",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignVehicleType(L)
#
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleType",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
