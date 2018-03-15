#==========================
#AssignHhVehicleDvmtSplit.R
#==========================
#This module identifies how average DVMT is split among vehicles in the
#household.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(data.table)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#A linear model is estimated that predicts the difference in the proportion
#of miles traveled by a household vehicle and the proportion that would be
#expected if travel was equal on all household vehicles.

#Prepare data to estimate model
#------------------------------
#Load 2001 NHTS vehicle data
Veh_df <- VE2001NHTS::Veh_df
Hh_df <- VE2001NHTS::Hh_df
#Calculate vehicle age
Veh_df$Age <- max(Veh_df$Vehyear, na.rm = TRUE) - Veh_df$Vehyear
#Split by household
VehByHh_ls <- split(Veh_df, Veh_df$Houseid)
#Check for complete variables of interest
AnyBestmileNA_ <-
  unlist(lapply(VehByHh_ls, function(x) {
    any(is.na(x$Bestmile))
  }))
AnyEiadmpgNA_ <-
  unlist(lapply(VehByHh_ls, function(x) {
    any(is.na(x$Eiadmpg))
  }))
AnyTypeNA_ <-
  unlist(lapply(VehByHh_ls, function(x) {
    any(is.na(x$Type))
  }))
AnyAgeNA_ <-
  unlist(lapply(VehByHh_ls, function(x) {
    any(is.na(x$Age))
  }))
#Remove all households that have any missing records
HasNA_ <- AnyBestmileNA_ | AnyEiadmpgNA_ | AnyTypeNA_ | AnyAgeNA_
VehByHh_ls <- VehByHh_ls[!HasNA_]
rm(AnyBestmileNA_, AnyEiadmpgNA_, AnyTypeNA_, AnyAgeNA_, HasNA_)
#Remove households that have only one vehicle (no need to predict for those)
NumVeh_Hh <- unlist(lapply(VehByHh_ls, nrow))
VehByHh_ls <- VehByHh_ls[NumVeh_Hh >= 2]
rm(NumVeh_Hh)
#Add VMT proportions and predictor variables
# Difference between household VMT proportion and expected (equal) proportion
# Ratio of mean age of other vehicles in household to age of vehicle
# Ratio of mean MPG of other vehicles in household to MPG of vehicle
VehByHh_ls <-
  lapply(VehByHh_ls, function(x) {
    #Number of vehicles in household
    NumVeh <- nrow(x)
    x$NumVeh <- NumVeh
    #VMT proportions
    x$VmtProp <- x$Bestmile / sum(x$Bestmile)
    #Difference between VMT proportions and equal proportions
    x$VmtPropDiff <- x$VmtProp - (1 / nrow(x))
    #Calculation of mean age of vehicles excluding the subject vehicle
    XMeanAge_ <- numeric(NumVeh)
    for (i in 1:NumVeh) {
      XMeanAge_[i] <- mean(x$Age[-i]) + 1
    }
    #Ratio of subject vehicles age to mean of other vehicles ages
    x$AgeRatio <- XMeanAge_ / (x$Age + 1)
    #Calculation of mean MPG of vehicles excluding the subject vehicle
    XMeanMpg_ <- numeric(NumVeh)
    for (i in 1:NumVeh) {
      XMeanMpg_[i] <- mean(x$Eiadmpg[-1])
    }
    #Ratio of subject vehicles MPG to mean of other vehicles MPG
    x$MpgRatio <- x$Eiadmpg / XMeanMpg_
    #Identify whether is a light truck
    x$IsLtTrk <- as.numeric(x$Type == "LightTruck")
    #Return the result
    x
  })

#Estimate a linear model of DVMT proportions
#-------------------------------------------
#Identify model variables
Vars_ <-
  c("Houseid", "VmtProp", "VmtPropDiff", "AgeRatio", "IsLtTrk", "MpgRatio", "NumVeh")
#Create a data frame of vehicle observations for model estimation
VmtPropData_df <- do.call(rbind, VehByHh_ls)[, Vars_]
VmtPropData_df$LogAgeRatio <- log(VmtPropData_df$AgeRatio)
VmtPropData_df$LogMpgRatio <- log(VmtPropData_df$MpgRatio)
VmtPropData_df$NumWkr <- Hh_df$Wrkcount[match(VmtPropData_df$Houseid, Hh_df$Houseid)]
VmtPropData_df$WkrVeh <-
  with(VmtPropData_df,
       cut(NumWkr / NumVeh,
           breaks = c(0, 0.99, 1.01, max(NumWkr / NumVeh)),
           labels = c("WkrLTVeh", "WkrEQVeh", "WkrGTVeh"),
           include.lowest = TRUE))
VmtPropData_df$LogIncome <- log(Hh_df$Income)[match(VmtPropData_df$Houseid, Hh_df$Houseid)]
#Estimate model of difference in proportions from equal proportions
# AgeRatio: ratio of mean age of other household vehicles to age of vehicle
# IsLtTrk: 1 if vehicle is light truck and 0 if is automobile
# MpgRatio: ratio of vehicle MPG to mean MPG of other household vehicles
#Other variables were tested but found to not have much improvement in the
#proportion of variance explained.
Test_df <- VmtPropData_df[!is.na(VmtPropData_df$LogIncome),]
VmtProp_LM <-
  lm(VmtProp ~
       LogAgeRatio +
       LogAgeRatio:LogIncome +
       IsLtTrk:LogIncome +
       LogMpgRatio +
       LogMpgRatio:LogIncome +
       NumVeh,
     data = Test_df)
summary(VmtProp_LM)
#Examine model results
# summary(VmtProp_LM)
#Create a model formula
VmtSplitModel <- makeModelFormulaString(VmtProp_LM)
#Define function to predict model
predictVmtProp <- function(VmtSplitModel, Data_df) {
  Data_df$Intercept <- 1
  eval(parse(text = VmtSplitModel), envir = Data_df)
}
#Predict and compare distribution
PredProp_ <- predictVmtProp(VmtSplitModel, Test_df)
#Check that prediction matches prediction method of lm
# sum(round(PredProp_,7) != round(predict(VmtProp_LM),7))
#Define function which adjusts a set of predictions for a household to sum to 1
adjProps <- function(PredProp_) {
  PredProp_[PredProp_ < 0] <- 0.01
  PredProp_[PredProp_ > 1] <- 0.99
  PredProp_ / sum(PredProp_)
}
#Compare model with adjustments
#Test the results
# VmtPropByHh_ls <- split(PredProp_, Test_df$Houseid)
# AdjProp_ <- unlist(lapply(VmtPropByHh_ls, function(x) adjProps(x)))
# plot(density(PredProp_), xlim = c(-0.05, 1.05), col = "blue")
# lines(density(VmtPropData_df$VmtProp), col = "darkgrey")
# lines(density(AdjProp_), col = "red")
# mean(AdjProp_) / mean(Test_df$VmtProp)
# var(AdjProp_) / var(Test_df$VmtProp)
# Test_df$VmtProp <- AdjProp_
# lm(VmtProp ~
#      LogAgeRatio + LogMpgRatio + NumVeh + LogAgeRatio:LogIncome +
#      LogIncome:IsLtTrk + LogIncome:LogMpgRatio, data = Test_df)
# VmtProp_LM
#Clean up
rm(Hh_df, Veh_df, VmtPropData_df, PredProp_, Vars_, VehByHh_ls, VmtProp_LM,
   adjProps, predictVmtProp, Test_df)

#Save the household vehicle DVMT split model
#-------------------------------------------
#' Household vehicle DVMT split model
#'
#' A string representation of the estimated linear model which splits DVMT among
#' household vehicles.
#'
#' @format A string:
#' \describe{
#'   \item{VmtSplitModel}{a string representation of the estimated linear model
#'   which splits DVMT among household vehicles}
#' }
#' @source AssignHhVehicleDvmtSplit.R script.
"VmtSplitModel"
devtools::use_data(VmtSplitModel, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignHhVehicleDvmtSplitSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
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
      NAME = "HhId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk")
    ),
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "MPGe",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "DvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Proportion of average household DVMT"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignHhVehicleDvmtSplit module
#'
#' A list containing specifications for the AssignHhVehicleDvmtSplit module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignHhVehicleDvmtSplit.R script.
"AssignHhVehicleDvmtSplitSpecifications"
devtools::use_data(AssignHhVehicleDvmtSplitSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the proportions of household VMT by household
#vehicle.

#Main module function that calculates household vehicle VMT proportions
#----------------------------------------------------------------------
#' Calculate the proportion of household VMT carried by each household vehicle.
#'
#' \code{AssignHhVehicleDvmtSplit} calculate proportions of household DVMT
#' allocated to each household.
#'
#' This function calculates how household VMT is split among household
#' vehicles. The proportion of household VMT allocated to each vehicle is
#' calculated.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @import data.table
#' @export
AssignHhVehicleDvmtSplit <- function(L) {
  #Set up data to apply model
  #--------------------------
  #Add log income and number of vehicles to vehicle data
  L$Year$Vehicle$LogIncome <-
    with(L$Year$Household,
         log1p(Income)[match(L$Year$Vehicle$HhId, HhId)])
  L$Year$Vehicle$NumVeh <-
    with(L$Year$Household,
         Vehicles[match(L$Year$Vehicle$HhId, HhId)])
  #Create a data table
  Veh_dt <- as.data.table(L$Year$Vehicle)
  #Add light truck variable
  Veh_dt[,IsLtTrk := as.numeric(Type == "LtTrk"),]
  #Add log age ratio
  Veh_dt[,AgePlus1 := Age + 1,]
  Veh_dt[,LogAgeRatio := 1]
  calcAgeRatios <-
    function(Age) {
      sapply(1:length(Age), function(x) log(mean(Age[-x]) / Age[x]))
    }
  Veh_dt[NumVeh > 1, LogAgeRatio := list(calcAgeRatios(AgePlus1)), by = HhId]
  #Add log MPG ratio
  Veh_dt[,LogMpgRatio := 1]
  calcMpgRatios <-
    function(Mpg) {
      sapply(1:length(Mpg), function(x) log(Mpg[x] / mean(Mpg[-x])))
    }
  Veh_dt[NumVeh > 1, LogMpgRatio := list(calcMpgRatios(MPGe)), by = HhId]
  #Add the intercept
  Veh_dt[, Intercept := 1]

  #Apply the model to calculate proportions
  #----------------------------------------
  #Run model to calculate the initial proportions
  Veh_dt[, VmtProp := eval(parse(text = VmtSplitModel), envir = .SD)]
  #Adjust proportions to change out-of-bounds values and sum to 1
  adjProps <- function(PredProp_) {
    PredProp_[PredProp_ < 0] <- 0.01
    PredProp_[PredProp_ > 1] <- 0.99
    PredProp_ / sum(PredProp_)
  }
  Veh_dt[, VmtProp := adjProps(VmtProp), by = HhId]

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <-
    list(
      DvmtProp = Veh_dt$VmtProp)
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
#   ModuleName = "AssignHhVehicleDvmtSplit",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignHhVehicleDvmtSplit(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignHhVehicleDvmtSplit",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
