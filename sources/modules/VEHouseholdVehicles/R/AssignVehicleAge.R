#==================
#AssignVehicleAge.R
#==================
#
#<doc>
#
## AssignVehicleAge Module
#### September 7, 2018
#
#This module assigns vehicle ages to each household vehicle. Vehicle age is assigned as a function of the vehicle type (auto or light truck), household income, and assumed mean vehicle age by vehicle type and Azone. Car service vehicles are assigned an age based on input assumptions with no distinction between vehicle type.
#
### Model Parameter Estimation
#
#The models are estimated using the *Hh_df* (household) and *Veh_df* (vehicle) datasets in the VE2001NHTS package. Information about these datasets and how they were developed from the 2001 National Household Travel Survey public use dataset is included in that package. For each vehicle type (auto, light truck), tabulations are made of cumulative proportions of vehicles by age (i.e. proportion of vehicles less than or equal to the age) and the joint proportion of vehicles by age and income group. For these tabulations, the maximum vehicle age was set at 30 years. This ignores about 1.5% of the vehicle records.
#
#The following figure shows the cumulative proportions of vehicles by vehicle age.
#
#<fig:cum_age_props_by_veh-type.png>
#
#The following figure compares the age proportions of automobiles by income group. It can be seen that as income decreases, the age distribution shifts towards older vehicles. The 6 income groups are $0 to $20,000, $20,000 to $40,000, $40,000 to $60,000, $60,000 to $80,000, $80,000 to $100,000, $100,000 plus.
#
#<fig:auto_age_props_by_inc.png>
#
#The following figure compares the age proportions of light trucks by income group. As with automobiles, as increases, the age distributions shifts to older vehicles.
#
#<fig:lttrk_age_props_by_inc.png>
#
### How the Module Works
#
#The module auto and light truck vehicle age distributions which match user inputs for mean auto age and mean light truck age. The module adjusts the cumulative age distribution to match a target mean age. This is done by either expanding the age interval (i.e. a year is 10% longer) if the mean age increases, or compressing the age interval if the mean age decreases. A binary search function is used to determine the amount of expansion or compression of the estimated age distribution is necessary in order to match the input mean age. The age distribution for the vehicles is derived from the adjusted cumulative age distribution.
#
#Once the age distribution for a vehicle type has been determined, the module calculates vehicle age distributions by household income group. It takes marginal distributions of vehicles by age and vehicles by household income group along with a seed matrix of the joint probability distribution of vehicles by age and income group, and then uses iterative proportional fitting to adjust the joint probabilities to match the margins. The age probability by income group is calculated from the joint probability matrix. These probabilities are then used as sampling distributions to determine the age of each household vehicle as a function of the vehicle type and the household income.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This model predicts vehicle age as a function of the vehicle type, household
#income, and census region the household is located in. It uses a tabulation
#of vehicles from the 2001 NHTS to create two probability tables for each
#vehicle type. The first is a table of the cumulative probability of vehicles by
#age. This table is used in the model to create vehicle age distributions by
#type based on input assumptions regarding the mean vehicle age by type. The
#second tables is the joint probabilities of vehicles by vehicle age and income
#group.

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

#Create joint distributions of vehicles by age and income by type
#----------------------------------------------------------------
#Tabulate vehicle weights by vehicle age, household income, vehicle type
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
#------------------------
LtTrkAgeIncDF_AgIg <- AgeIncJointProp_AgIgTy[,,"LtTrk"]
LtTrkAgeIncDF_AgIg <-
  apply(LtTrkAgeIncDF_AgIg, 2, function(x) {
    smooth.spline(0:MaxAge, x, df=8)$y})
rownames(LtTrkAgeIncDF_AgIg) <- 0:30
LtTrkAgeCDF_Ag <- cumsum(rowSums(LtTrkAgeIncDF_AgIg))

#Document vehicle age proportions
#--------------------------------
#Cumulate age proportions
png("data/cum_age_props_by_veh-type.png", height = 480, width = 480)
plot(0:30, AutoAgeCDF_Ag, type = "l", xlab = "Vehicle Age (years)",
     ylab = "Proportion of Vehicles",
     main = "Cumulative Proportion of Vehicles by Age")
lines(0:30, LtTrkAgeCDF_Ag, lty = 2)
legend("bottomright", lty = c(1,2), legend = c("Auto", "Light Truck"),
       bty = "n")
dev.off()
#Document auto age proportions by household income group
png("data/auto_age_props_by_inc.png", height = 480, width = 480)
Temp_AgIg <- sweep(AutoAgeIncDF_AgIg, 2, colSums(AutoAgeIncDF_AgIg), "/")
matplot(Temp_AgIg, type = "l", xlab = "Vehicle Age (years)",
        ylab = "Proportion of Vehicles",
        main = "Proportions of Automobiles by Age by Household Income")
legend("topright", lty = 1:6, col = 1:6, legend = colnames(AutoAgeIncDF_AgIg))
rm(Temp_AgIg)
dev.off()
#Document light truck age proportions by household income group
png("data/lttrk_age_props_by_inc.png", height = 480, width = 480)
Temp_AgIg <- sweep(LtTrkAgeIncDF_AgIg, 2, colSums(LtTrkAgeIncDF_AgIg), "/")
matplot(Temp_AgIg, type = "l", xlab = "Vehicle Age (years)",
        ylab = "Proportion of Vehicles",
        main = "Proportions of Light Trucks by Age by Household Income")
legend("topright", lty = 1:6, col = 1:6, legend = colnames(LtTrkAgeIncDF_AgIg))
rm(Temp_AgIg)
dev.off()

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
usethis::use_data(VehicleAgeModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleAgeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
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
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
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
      NAME = "Azone",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc")
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
      NAME = "AveCarSvcVehicleAge",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
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
usethis::use_data(AssignVehicleAgeSpecifications, overwrite = TRUE)


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
#' @name findMeanAge
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
#' @name adjustAgeDistribution
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
#' It takes marginal distributions of vehicles by age and vehicles by household
#' income group along with a seed matrix of the joint probability distribution
#' of vehicles by age and income group, and then uses iterative proportional
#' fitting to adjust the joint probabilities to match the margins. The
#' probabilities by income group are calculated from the fitted joint
#' probability matrix. The seed matrix is the joint age and income distribution
#' for autos or light trucks in the VehicleAgeModel_ls (AgeIncJointProp_AgIg).
#' The age margin is the proportional distribution of vehicles by age calculated
#' by adjusting the cumulative age distribution for autos or light trucks in the
#' VehicleAgeModel_ls (AgeCDF_AgTy) to match a target mean age. The income
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
#' @name calcAgeDistributionByInc
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
#' @name AssignVehicleAge
#' @import visioneval
#' @export
#'
AssignVehicleAge <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Create index to match household records with vehicle records
  HhToVehIdx_Ve <- match(L$Year$Vehicle$HhId, L$Year$Household$HhId)

  #Create an income group datase
  #-----------------------------
  Ig <- c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus")
  L$Year$Vehicle$IncGrp <-
    as.character(
      with(L$Year$Household,
           cut(Income,
               breaks = c(c(0, 20, 40, 60, 80, 100) * 1000, max(Income)),
               labels = Ig,
               include.lowest = TRUE))[HhToVehIdx_Ve]
    )

  #Iterate by Azone and assign vehicle age
  #---------------------------------------
  NumVeh <- length(L$Year$Vehicle$VehId)
  Age_Ve <- rep(NA, NumVeh)
  names(Age_Ve) <- L$Year$Vehicle$VehId
  Az <- L$Year$Azone$Azone
  for (az in Az) {
    #Create owned vehicle data frame
    UseOwn <- with(L$Year$Vehicle, Azone == az & VehicleAccess == "Own")
    AutoMeanAge <- with(L$Year$Azone, AutoMeanAge[Azone == az])
    LtTrkMeanAge <- with(L$Year$Azone, LtTrkMeanAge[Azone == az])
    #Create data frame of data to use
    Fields_ <- c("VehId", "Type", "IncGrp")
    Own_df <-
      data.frame(lapply(L$Year$Vehicle[Fields_], function(x) x[UseOwn]), stringsAsFactors = FALSE)
    Own_df$Age <- NA
    #Calculate income group proportions by vehicle type
    NumVeh_IgTy <- with(Own_df, table(IncGrp, Type))
    IncProp_IgTy <- sweep(NumVeh_IgTy, 2, colSums(NumVeh_IgTy), "/")
    #Calculate cumulative age distributions by type
    AutoAgeProp_Ag <-
      adjustAgeDistribution(
        VehicleAgeModel_ls$Auto$AgeCDF_Ag,
        AutoMeanAge)$Dist
    LtTrkAgeProp_Ag <-
      adjustAgeDistribution(
        VehicleAgeModel_ls$LtTrk$AgeCDF_Ag,
        LtTrkMeanAge)$Dist
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
    #Assign ages for automobiles
    for (ig in Ig) {
      Ages_ <-
        sample(
          0:30,
          NumVeh_IgTy[ig, "Auto"],
          replace = TRUE,
          prob = AutoAgePropByInc_AgIg[,ig])
      Own_df$Age[Own_df$IncGrp == ig & Own_df$Type == "Auto"] <- Ages_
    }
    #Assign ages for light trucks
    for (ig in Ig) {
      Ages_ <-
        sample(
          0:30,
          NumVeh_IgTy[ig, "LtTrk"],
          replace = TRUE,
          prob = LtTrkAgePropByInc_AgIg[,ig])
      Own_df$Age[Own_df$IncGrp == ig & Own_df$Type == "LtTrk"] <- Ages_
    }
    #Add vehicle age for owned vehicles in Azone
    Age_Ve[Own_df$VehId] <- Own_df$Age
    #Add car service average vehicle age
    CarSvcAge <- with(L$Year$Azone, AveCarSvcVehicleAge[Azone == az])
    CarSvcVehId_ <-
      with(L$Year$Vehicle, VehId[Azone == az & VehicleAccess != "Own"])
    Age_Ve[CarSvcVehId_] <- CarSvcAge
  }

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle$Age <- unname(Age_Ve)
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignVehicleAge")

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
#   TestDataRepo = "../Test_Data/VE-RSPM",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "verspm",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleAge",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignVehicleAge(L)
#
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleAge",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
