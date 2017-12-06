#==================
#AssignVehicleAge.R
#==================
#This module assigns vehicle ages to each household vehicle. A 'Vehicle' table
#Is created which has a record for each household vehicle. The type and age
#of each vehicle owned or leased by households is assigned to this table along
#with the household ID (HhId)to enable this table to be joined with the
#household table.

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

library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This model predicts vehicle age as a function of the vehicle type, household
#income, and census region the household is located in. It uses a tabulation
#of vehicles from the 2001 NHTS to create probability three probability tables.
#The first is a table of the cumulative probability of vehicles by age for each
#vehicle type. This table is used in the model to create vehicle age
#distributions by type based on input assumptions regarding the mean vehicle
#age by type. The second and thirds tables are joint probabilities of vehicles
#by vehicle age and income group. One of these tables applies to automobiles and
#the other applies to light trucks.

#Prepare 2001 NHTS data
#----------------------
#Load 2001 NHTS household and vehicle data
Hh_df <- VE2001NHTS::Hh_df
Veh_df <- VE2001NHTS::Veh_df
#Create a vehicle age variable and cap at 30 years
MaxAge <- 30
Veh_df$VehAge <- 2002 - Veh_df$Vehyear
Veh_df <- Veh_df[Veh_df$VehAge <= MaxAge,]
#Recode the vehicle type field
Veh_df$Type[Veh_df$Type == "LightTruck"] <- "LtTrk"
#Select fields to keep and join household and vehicle datasets
HhVars_ <- c("Houseid", "Census_r", "Expfllhh", "Expflhhn", "IncGrp")
VehVars_ <- c("Houseid", "Type", "VehAge")
Data_df <- merge(Veh_df[VehVars_], Hh_df[HhVars_], "Houseid")
Data_df <- Data_df[complete.cases(Data_df),]
#Create a weighing variable from the household expansion factor
Data_df$Weight <- Data_df$Expfllhh / 100
rm(Hh_df, Veh_df, HhVars_, VehVars_)

#Create joint distributions of vehicles by age and income by type and region
#---------------------------------------------------------------------------
#Tabulate vehicle weights by vehicle age, household income, vehicle type, and
#Census region
TotWt_AgIgTy <-
  tapply(Data_df$Weight, as.list(Data_df[c("VehAge", "IncGrp", "Type")]), sum)
#Calculate joint distribution of proportion of vehicles by age and income for
#each vehicle type
AgeIncJointProp_AgIgTy <-
  sweep(TotWt_AgIgTy, 3, apply(TotWt_AgIgTy, 3, sum), "/")

#Auto Calculations
#-----------------
AutoAgeIncDF_AgIg <- AgeIncJointProp_AgIgTy[,,"Auto"]
AutoAgeIncDF_AgIg <-
  apply(AutoAgeIncDF_AgIg, 2, function(x) {
    smooth.spline(0:MaxAge, x, df=8)$y})
rownames(AutoAgeIncDF_AgIg) <- 0:30
AutoAgeCDF_Ag <- cumsum(rowSums(AutoAgeIncDF_AgIg))

#Light Truck Calculations
#-----------------
LtTrkAgeIncDF_AgIg <- AgeIncJointProp_AgIgTy[,,"LtTrk"]
LtTrkAgeIncDF_AgIg <-
  apply(LtTrkAgeIncDF_AgIg, 2, function(x) {
    smooth.spline(0:MaxAge, x, df=8)$y})
rownames(LtTrkAgeIncDF_AgIg) <- 0:30
LtTrkAgeCDF_Ag <- cumsum(rowSums(LtTrkAgeIncDF_AgIg))

#Save model parameters in a list
#-------------------------------
VehicleAgeModel_ls <-
  list(
    Auto = list(
      AgeCDF_Ag = AutoAgeCDF_Ag,
      AgeIncJointProp_AgIg = AutoAgeIncDF_AgIg
    ),
    LtTrk = list(
      AgeCDF_Ag = LtTrkAgeCDF_Ag,
      AgeIncJointProp_AgIg = LtTrkAgeIncDF_AgIg
    )
  )
rm(MaxAge, TotWt_AgIgTy, AgeIncJointProp_AgIgTy, AutoAgeIncDF_AgIg,
   AutoAgeCDF_Ag, LtTrkAgeIncDF_AgIg, LtTrkAgeCDF_Ag, Data_df)

#Save the vehicle age model
#--------------------------
#' Vehicle age model
#'
#' A list containing the vehicle age model probability tables
#' needed to implement the vehicle age model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Auto$AgeCDF_Ag}{a vector of cumulative probability of autos by age}
#'   \item{Auto$AgeIncJointProp_AgIg}{a matrix of the joint probability of autos by age and household income}
#'   \item{LtTrk$AgeCDF_Ag}{a vector of cumulative probability of light trucks by age}
#'   \item{LtTrk$AgeIncJointProp_AgIg}{a matrix of the joint probability of light trucks by age and household income}
#' }
#' @source AssignVehicleAge.R script.
"VehicleAgeModel_ls"
devtools::use_data(VehicleAgeModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleAgeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = items(
        "AutoMeanAge",
        "LtTrkMeanAge"
      ),
      FILE = "azone_hh_veh_mean_age.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 5", ">= 14"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Mean age of automobiles owned or leased by households.",
        "Mean age of light trucks owned or leased by households."
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "AutoMeanAge",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LtTrkMeanAge",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "<= 0"),
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
      NAME = items(
        "NumLtTrk",
        "NumAuto"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk"),
      SIZE = 5,
      DESCRIPTION = "Vehicle body type: Auto = automobile, LtTrk = light trucks (i.e. pickup, SUV, Van)"
    ),
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Vehicle age in years"
    )
  )
  #Specify call status of module
  #Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignVehicleAge module
#'
#' A list containing specifications for the AssignVehicleAge module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{NewSetTable}{table to be created}
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignVehicleAge.R script.
"AssignVehicleAgeSpecifications"
devtools::use_data(AssignVehicleAgeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Function to calculate mean vehicle age from cumulative age distribution
#-----------------------------------------------------------------------
#' Calculate mean vehicle age from cumulative age distribution.
#'
#' \code{findMeanAge} calculates mean age from a cumulative age distribution.
#'
#' This function calculates a mean age from a cumulative age distribution vector
#' where the values of the vector are the cumulative proportions and the names
#' of the vector are the vehicle ages from 0 to 30 years.
#'
#' @param AgeCDF_Ag A named numeric vector where the names are vehicle ages and
#' the values are the proportion of vehicles that age or younger. The names must
#' be an ordered sequence from 0 to 30.
#' @return A numeric value that is the mean vehicle age.
#' @export
#'
findMeanAge <- function(AgeCDF_Ag) {
  Ages_ <- as.numeric(names(AgeCDF_Ag))
  AgeProp_Ag <- c(AgeCDF_Ag[1], diff(AgeCDF_Ag))
  sum(AgeProp_Ag * Ages_)
}

#Function to adjust cumulative age distribution to match target mean
#-------------------------------------------------------------------
#' Adjust cumulative age distribution to match target mean.
#'
#' \code{adjustAgeDistribution} Adjusts a cumulative age distribution to match a
#' target mean age.
#'
#' This function adjusts a cumulative age distribution to match a target mean
#' age. The function returns the adjusted cumulative age distribution and the
#' corresponding age distribution. If no target mean value is specified, the
#' function returns the input cumulative age distribution and the corresponding
#' age distribution for that input.
#'
#' @param AgeCDF_Ag A named numeric vector where the names are vehicle ages and
#' the values are the proportion of vehicles that age or younger. The names must
#' be an ordered sequence from 0 to 30.
#' @param TargetMean A number that is the target mean value.
#' @return A numeric value that is the mean vehicle age.
#' @export
#'
adjustAgeDistribution <- function(AgeCDF_Ag, TargetMean = NULL) {
  #Vector of vehicle ages
  Ages_ <- as.numeric(names(AgeCDF_Ag))
  if (!all.equal(Ages_, 0:30)) {
    Msg <- paste0(
      "Errors in names of AgeCDF_Ag. ",
      "Function expects names to be an ordered sequence from 0 to 30."
    )
    stop(Msg)
  }
  #Calculate the mean age for the input distribution
  DistMean <- findMeanAge(AgeCDF_Ag)
  #Define a function to calculate adjusted distribution
  calcAdjDist <- function(Shift) {
    CumShift_ <- cumsum(rep(Shift, 31))
    AdjAges_ <- CumShift_ + Ages_
    AdjCDF_Ag <-
      predict(smooth.spline(AdjAges_, AgeCDF_Ag), Ages_)$y
    names(AdjCDF_Ag) <- Ages_
    AdjCDF_Ag / max(AdjCDF_Ag)
  }
  #Define a function to check the mean age (function sent to binary search)
  checkMeanAge <- function(Shift) {
    findMeanAge(calcAdjDist(Shift))
  }
  #Calculate adjusted age distribution
  if (is.null(TargetMean)) {
    Result_ls <-
      list(CumDist = AgeCDF_Ag,
           Dist = c(AgeCDF_Ag[1], diff(AgeCDF_Ag)))
  } else {
    FoundShift <-
      binarySearch(checkMeanAge, c(-0.75, 1), Target = TargetMean)
    AdjCumDist_ <- calcAdjDist(FoundShift)
    Result_ls <-
      list(CumDist = AdjCumDist_,
           Dist = c(AdjCumDist_[1], diff(AdjCumDist_)))
  }
  Result_ls
}

#Function which calculates vehicle age distributions by income group
#-------------------------------------------------------------------
#' Calculate vehicle age distributions by income group.
#'
#' \code{calcAgeDistributionByInc} Calculates vehicle age distributions by
#' household income group.
#'
#' This function calculates vehicle age distributions by household income group.
#' It takes marginal distributions of vehicles by age and households by income
#' group along with a seed matrix of the joint probability distribution of
#' vehicles by age and income group, and then uses iterative proportional
#' fitting to adjust the joint probabilities to match the margins. The
#' probabilities by income group are calculated from the fitted joint
#' probability matrix. The seed matrix is the joint age and income distribution
#' for autos or light trucks in the VehicleAgeModel_ls (AgeIncJointProp_AgIg).
#' The age margin is the proportional distribution of vehicles by age calculated
#' by adjusting the cumulative age distribution for autos or light trucks in
#' the VehicleAgeModel_ls (AgeCDF_AgTy) to match a target mean age. The income
#' margin is the proportional distribution of vehicles by household income group
#' ($0-20K, $20K-40K, $40K-60K, $60K-80K, $80K-100K, $100K or more) calculated
#' from the modeled household values.
#'
#' @param Seed_AgIg A numeric matrix of the joint probabilities of vehicles
#' by age and income group.
#' @param Margin_Ag A numeric vector of vehicle age probabilities.
#' @param Margin_Ig A numeric vector of vehicle household income probabilities.
#' @param MaxIter A numeric value specifying the maximum number of iterations
#' the iterative proportional fitting process will undertake.
#' @param Closure A numeric value specifying the maximum allowed difference
#' between any margin value and corresponding sum of values of the joint
#' probability matrix.
#' @return A numeric value that is the mean vehicle age.
#' @export
#'
calcAgeDistributionByInc <-
  function(Seed_AgIg, Margin_Ag, Margin_Ig, MaxIter=100, Closure=0.0001) {
    #Replace margin values of zero with 0.0001
    if (any(Margin_Ag == 0)) {
      Margin_Ag[Margin_Ag == 0] <- 0.0001
    }
    if (any(Margin_Ig == 0)) {
      Margin_Ig[Margin_Ig == 0] <- 0.0001
    }
    #Make sure sum of each margin is equal to 1
    Margin_Ag <- Margin_Ag * (1 / sum(Margin_Ag))
    Margin_Ig <- Margin_Ig * (1 / sum(Margin_Ig))
    # Set initial values
    VehAgIgProp_AgIg <- Seed_AgIg
    Iter <- 0
    MarginChecks <- c(1, 1)
    #Iteratively proportion matrix until closure or iteration criteria are met
    while((any(MarginChecks > Closure)) & (Iter < MaxIter)) {
      Sums_Ag <- rowSums(VehAgIgProp_AgIg)
      Coeff_Ag <- Margin_Ag / Sums_Ag
      VehAgIgProp_AgIg <- sweep(VehAgIgProp_AgIg, 1, Coeff_Ag, "*")
      MarginChecks[1] <- max(abs(1 - Coeff_Ag))
      Sums_Ig <- colSums(VehAgIgProp_AgIg)
      Coeff_Ig <- Margin_Ig / Sums_Ig
      VehAgIgProp_AgIg <- sweep(VehAgIgProp_AgIg, 2, Coeff_Ig, "*")
      MarginChecks[2] <- max(abs(1 - Coeff_Ig))
      Iter <- Iter + 1
    }
    #Return the age proportions by income group
    sweep(VehAgIgProp_AgIg, 2, colSums(VehAgIgProp_AgIg), "/")
  }

#Main module function to create and populate vehicle table of types and ages
#---------------------------------------------------------------------------
#' Create vehicle table and populate with vehicle type and age records.
#'
#' \code{AssignVehicleAge} create the vehicle table and populate with vehicle
#' age and type records.
#'
#' This function creates the 'Vehicle' table in the datastore and populates it
#' with records of vehicle types and ages along with household IDs.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'
AssignVehicleAge <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  #Make vehicle records
  #--------------------
  #Make vector to match order of vehicle data to vehicle table
  HasVeh <- L$Year$Household$Vehicles > 0
  DataID_ <-
    with(L$Year$Household,
         paste(
           rep(HhId[HasVeh], Vehicles[HasVeh]),
           unlist(sapply(Vehicles[HasVeh], function(x) 1:x)),
           sep = "-"
         ))
  DatOrd <- match(DataID_, L$Year$Vehicle$VehId)
  #Create an income group dataset
  Ig <- c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus")
  IncGrp_Hh <-
    as.character(
      with(L$Year$Household,
           cut(Income,
               breaks = c(c(0, 20, 40, 60, 80, 100) * 1000, max(Income)),
               labels = Ig,
               include.lowest = TRUE))
    )
  IncGrp_ <- rep(IncGrp_Hh[HasVeh], L$Year$Household$Vehicles[HasVeh])[DatOrd]
  #Create vehicle type dataset
  Data_df <- data.frame(L$Year$Household[c("NumLtTrk", "NumAuto")])[HasVeh,]
  Type_ <-
    do.call(c, apply(Data_df, 1, function(x) {
      c(rep("LtTrk", x["NumLtTrk"]), rep("Auto", x["NumAuto"]))}))[DatOrd]
  Age_ <- integer(length(DataID_))

  #Calculate vehicle age distributions
  #-----------------------------------
  #Calculate income group proportions by vehicle type
  NumVeh_IgTy <- table(IncGrp_, Type_)
  IncProp_IgTy <- sweep(NumVeh_IgTy, 2, colSums(NumVeh_IgTy), "/")
  #Calculate cumulative age distributions by type
  AutoAgeProp_Ag <-
    adjustAgeDistribution(
      VehicleAgeModel_ls$Auto$AgeCDF_Ag,
      L$Year$Azone$AutoMeanAge)$Dist
  LtTrkAgeProp_Ag <-
    adjustAgeDistribution(
      VehicleAgeModel_ls$LtTrk$AgeCDF_Ag,
      L$Year$Azone$LtTrkMeanAge)$Dist
  #Calculate age distributions by income group
  AutoAgePropByInc_AgIg <-
    calcAgeDistributionByInc(
      VehicleAgeModel_ls$Auto$AgeIncJointProp_AgIg,
      AutoAgeProp_Ag,
      IncProp_IgTy[,"Auto"]
    )
  LtTrkAgePropByInc_AgIg <-
    calcAgeDistributionByInc(
      VehicleAgeModel_ls$LtTrk$AgeIncJointProp_AgIg,
      LtTrkAgeProp_Ag,
      IncProp_IgTy[,"LtTrk"]
    )

  #Sample vehicle ages and assign to vehicles
  #------------------------------------------
  #Assign ages for automobiles
  for (ig in Ig) {
    Ages_ <-
      sample(
        0:30,
        NumVeh_IgTy[ig, "Auto"],
        replace = TRUE,
        prob = AutoAgePropByInc_AgIg[,ig])
    Age_[IncGrp_ == ig & Type_ == "Auto"] <- Ages_
  }
  #Assign ages for light trucks
  for (ig in Ig) {
    Ages_ <-
      sample(
        0:30,
        NumVeh_IgTy[ig, "LtTrk"],
        replace = TRUE,
        prob = LtTrkAgePropByInc_AgIg[,ig])
    Age_[IncGrp_ == ig & Type_ == "LtTrk"] <- Ages_
  }

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list()
  attributes(Out_ls$Year$Vehicle)$LENGTH <- length(DataID_)
  Out_ls$Year$Vehicle$Type <- Type_
  Out_ls$Year$Vehicle$Age <- Age_
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
#   ModuleName = "AssignVehicleAge",
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
