#======================
#CalculateParkingCost.R
#======================
#This module calculates household parking costs for work and non-work trips.

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

#===========================================
#MODEL PROPORTION OF HOUSEHOLD DVMT FOR WORK
#===========================================

#Notes:
#The work parking costs and employee commute options models require estimates of the miles traveled for work purposes. This section estimates a model for predicting the proportion of household DVMT that is for work.
#Several model were tested for predicting the proportion of household DVMT in work tours. All of the models were dismal in their performance. One would think that at least there would be some difference among households that only had elderly persons, or households that had more kids, but the explanatory value is very small. The script below shows several tests. The R-squared values are trivial. For this reason, an overall mean value is used for all households.

#Test models to predict proportion of DVMT for work
#--------------------------------------------------



TestHh.. <- Hh..
TestHh..$PropWrkAgePersons <- TestHh..$DrvAgePop / TestHh..$Hhsize
TestHh..$PropPrimeWorkers <- TestHh..$Age30to54 / TestHh..$Hhsize
TestHh..$PropYoungWorkers <- ( TestHh..$Age15to19 + TestHh..$Age20to29 ) / TestHh..$Hhsize
TestHh..$PropOldWorkers <- ( TestHh..$Age55to64 + TestHh..$Age65Plus ) / TestHh..$Hhsize
TestHh..$PropWorkers <- TestHh..$PropPrimeWorkers + TestHh..$PropYoungWorkers +
  TestHh..$PropOldWorkers
TestHh..$PropKids1 <- TestHh..$Age0to14 / TestHh..$Hhsize
TestHh..$PropKids2 <- ( TestHh..$Age0to14 + TestHh..$Age15to19 ) / TestHh..$Hhsize
TestHh.. <- TestHh..[ , c( "PropWkDvmt", "PropWorkers", "PropPrimeWorkers",
                           "PropYoungWorkers", "PropOldWorkers", "OnlyElderly", "Htppopdn", "PropKids1",
                           "PropKids2", "PropWrkAgePersons", "DrvAgePop" ) ]
TestHh.. <- TestHh..[ complete.cases( TestHh.. ), ]
boxplot( TestHh..$PropWkDvmt ~ TestHh..$DrvAgePop )
tapply( TestHh..$PropWkDvmt, TestHh..$DrvAgePop, mean )
summary( lm( PropWkDvmt ~ PropWrkAgePersons, data=TestHh.. ) )
summary( lm( PropWkDvmt ~ OnlyElderly, data=TestHh.. ) )
summary( lm( PropWkDvmt ~ PropKids1, data=TestHh.. ) )
summary( lm( PropWkDvmt ~ PropKids2, data=TestHh.. ) )

rm( TestHh.. )

#Test models to predict proportion of DVMT for work for households that had some work travel
#-------------------------------------------------------------------------------------------
TestHh.. <- Hh..
TestHh..$PropWrkAgePersons <- TestHh..$DrvAgePop / TestHh..$Hhsize
TestHh..$PropPrimeWorkers <- TestHh..$Age30to54 / TestHh..$Hhsize
TestHh..$PropYoungWorkers <- ( TestHh..$Age15to19 + TestHh..$Age20to29 ) / TestHh..$Hhsize
TestHh..$PropOldWorkers <- ( TestHh..$Age55to64 + TestHh..$Age65Plus ) / TestHh..$Hhsize
TestHh..$PropWorkers <- TestHh..$PropPrimeWorkers + TestHh..$PropYoungWorkers +
  TestHh..$PropOldWorkers
TestHh..$PropKids1 <- TestHh..$Age0to14 / TestHh..$Hhsize
TestHh..$PropKids2 <- ( TestHh..$Age0to14 + TestHh..$Age15to19 ) / TestHh..$Hhsize
TestHh.. <- TestHh..[ , c( "PropWkDvmt", "PropWorkers", "PropPrimeWorkers",
                           "PropYoungWorkers", "PropOldWorkers", "OnlyElderly", "Htppopdn", "PropKids1",
                           "PropKids2", "PropWrkAgePersons" ) ]
TestHh.. <- TestHh..[ complete.cases( TestHh.. ), ]
TestHh.. <- TestHh..[ TestHh..$PropWkDvmt != 0, ]
summary( lm( PropWkDvmt ~ PropWrkAgePersons, data=TestHh.. ) )
summary( lm( PropWkDvmt ~ OnlyElderly, data=TestHh.. ) )
summary( lm( PropWkDvmt ~ PropKids1, data=TestHh.. ) )
summary( lm( PropWkDvmt ~ PropKids2, data=TestHh.. ) )
rm( TestHh.. )

#Calculate the mean proportion of household travel for work
#----------------------------------------------------------
MeanWorkDvmtProp <- mean( Hh..$PropWkDvmt, na.rm=TRUE )
MeanWorkDvmtProp


#============
#PARKING COST
#============

#The effect of parking costs is modeled by calculating an average daily cost for parking. This gets added in with other vehicle costs so that the total budget effects of all vehicle costs can be modeled. Parking costs applied to each household have two components: the cost of parking at work and the cost of parking in conjunction with other travel.

#Assumed labor force participation rate = 0.65

#Define function to identify number of workers who pay parking
#=============================================================

#Notes:
#This function calculates the number of people in each household who pay parking at work and the number of people to have their parking cashed out. This function is associated with the calcParkCostAdj function which calculates the parking cost on a per mile basis. The functions were split to facilitate testing. By doing this split a set of paying parkers can be kept constant while testing the effect of different parking charges. All of the inputs for both functions are arguments to the first function. Then all the arguments are bundled into the list object that is returned. That list object is then the sole input to the calcParkCostAdj. This was done to simplify application and keep the inputs consistent.

idPayingParkers <- function( Data.., PropWrkPkg, PropWrkChrgd, PropCashOut, PropOthChrgd,
                             LabForcePartRate=0.65, PkgCost, PropWrkTrav=0.22, WrkDaysPerYear=260 ) {

  # Calculate number of working age persons that pay parking
  PropOthPkg <- 1 - PropWrkPkg
  PropChrgdPkg <- PropWrkChrgd * PropWrkPkg + PropOthChrgd * PropOthPkg
  PropAvailPkg <- PropWrkChrgd * PropWrkPkg + PropOthPkg
  PropWrkPay <- PropWrkChrgd * PropChrgdPkg / PropAvailPkg
  PropWrkAgePay <- PropWrkPay * LabForcePartRate
  NumWrkAgePer <- sum( Data..$DrvAgePop )
  NumWrkAgePay <- round( PropWrkAgePay * NumWrkAgePer )

  # Calculate number of workers paying parking that are cash-out-buy-back
  NumCashOut <- round( NumWrkAgePay * PropCashOut )

  # Identify which persons pay parking
  WrkHhId. <- rep( Data..$Houseid, Data..$DrvAgePop )
  HhIdPay. <- sample( WrkHhId. )[ 1:NumWrkAgePay ]

  # Identify which persons get cash reimbursement for parking
  if( NumCashOut >= 1 ) {
    HhIdCashOut. <- sample( HhIdPay. )[ 1:NumCashOut ]
  } else {
    HhIdCashOut. <- NULL
  }

  # Identify the number of persons in each household who pay for parking
  NumHhPayers. <- tapply( HhIdPay., HhIdPay., function(x) length(x) )
  NumPayers.Hh <- numeric( nrow( Data.. ) )
  names( NumPayers.Hh ) <- Data..$Houseid
  NumPayers.Hh[ names( NumHhPayers. ) ] <- NumHhPayers.

  # Identify the number of persons in each household who get reimbursement
  NumCashOut.Hh <- numeric( nrow( Data.. ) )
  names( NumCashOut.Hh ) <- Data..$Houseid
  if( !is.null( HhIdCashOut. ) ) {
    NumHhCashOut. <- tapply( HhIdCashOut., HhIdCashOut., function(x) length(x) )
    NumCashOut.Hh[ names( NumHhCashOut. ) ] <- NumHhCashOut.
  }

  # Return the result
  list( NumPayers.Hh=NumPayers.Hh, NumCashOut.Hh=NumCashOut.Hh,
        PropWrkPkg=PropWrkPkg, PropWrkChrgd=PropWrkChrgd, PropCashOut=PropCashOut,
        PropOthChrgd=PropOthChrgd, LabForcePartRate=0.65, PkgCost=PkgCost,
        PropWrkTrav=0.22, WrkDaysPerYear=260 )

}

save( idPayingParkers, file="model/idPayingParkers.RData" )


#Define a function to calculate parking cost on a daily basis
#============================================================

calcParkCostAdj <- function( Data.., Park_ ) {

  NumPayers.Hh <- Park_$NumPayers.Hh
  NumCashOut.Hh <- Park_$NumCashOut.Hh
  PropWrkChrgd <- Park_$PropWrkChrgd
  PkgCost <- Park_$PkgCost
  PropOthChrgd <- Park_$PropOthChrgd
  PropWrkPkg <- Park_$PropWrkPkg
  PropWrkTrav <- Park_$PropWrkTrav
  LabForcePartRate <- Park_$LabForcePartRate
  WrkDaysPerYear <- Park_$WrkDaysPerYear

  # Sum the daily work parking costs by household
  WrkPkgCost.Hh <- NumPayers.Hh * PkgCost

  # Add daily parking cost for non-work travel
  OthPkgCost.Hh <- WrkPkgCost.Hh * 0  # Initialize vector
  OthPkgCost.Hh[] <- PkgCost * PropOthChrgd * ( 1 - PropWrkTrav )

  # Add the work daily parking cost to the other daily parking cost
  DailyPkgCost.Hh <- WrkPkgCost.Hh + OthPkgCost.Hh
  DailyPkgCost.Hh[ Data..$Hhvehcnt == 0 ] <- 0

  # Calculate the parking cost per mile
  PkgCostMile.Hh <- numeric( length( DailyPkgCost.Hh ) )
  PkgCostMile.Hh[ DailyPkgCost.Hh > 0 ] <-
    100 * DailyPkgCost.Hh[ DailyPkgCost.Hh > 0 ] / Data..$Dvmt[ DailyPkgCost.Hh > 0 ]

  # Sum the cash out parking income adjustment by household
  CashOutIncAdj.Hh <- NumCashOut.Hh * PkgCost * WrkDaysPerYear

  # Return the result
  list( DailyPkgCost=DailyPkgCost.Hh, CashOutIncAdj=CashOutIncAdj.Hh,
        PkgCostMile=PkgCostMile.Hh )

}

save( calcParkCostAdj, file="model/calcParkCostAdj.RData" )


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateHouseholdDVMTSpecifications <- list(
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
      NAME = "FwyLaneMiPC",
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("Dvmt",
              "Dvmt95th",
              "DvmtMax"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Average daily vehicle miles traveled by the household in autos or light trucks",
          "95th percentile daily vehicle miles traveled by the household in autos or light trucks",
          "Maximum daily vehicle miles traveled by the household in autos or light trucks"
        )
    )
  ),
  Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateHouseholdDVMT module
#'
#' A list containing specifications for the CalculateHouseholdDVMT module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateHouseholdDVMT.R script.
"CalculateHouseholdDVMTSpecifications"
devtools::use_data(CalculateHouseholdDVMTSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates average DVMT, 95th percentile day DVMT, and maximum
#DVMT.

#Main module function that calculates vehicle ownership
#------------------------------------------------------
#' Calculate the average household DVMT, 95th percentile household DVMT, and
#' maximum household DVMT.
#'
#' \code{CalculateHouseholdDVMT} calculate the average household DVMT, 95th
#' percentile household DVMT, and maximum household DVMT.
#'
#' This function calculates the average household DVMT, 95th percentile
#' household DVMT, and maximum household DVMT as a function of the household
#' characteristics and the characteristics of the area where the household
#' resides.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateHouseholdDVMT <- function(L) {
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
  TranRevMiPC_Bz <-
    L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Tranmilescap <-
    TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  FwyLaneMiPC_Bz <-
    L$Year$Marea$FwyLaneMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Fwylnmicap <-
    FwyLaneMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$Hhvehcnt <- Hh_df$Vehicles
  Hh_df$Urban <- Hh_df$IsUrbanMixNbrhd
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$LogIncome <- log1p(Hh_df$Income)
  Hh_df$Hbppopdn <-
    L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$LowVehOwnership <-
    as.numeric(with(Hh_df, Vehicles / DrvAgePop < 0.25))
  Hh_df$Intercept <- 1

  #Apply the average DVMT model
  #----------------------------
  AveDvmt_ <- numeric(NumHh)
  IsUr_ <- Hh_df$DevType == "Urban"
  AveDvmt_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                   envir = Hh_df[IsUr_,])) ^ (1 / DvmtModel_ls$Metro$Pow)
  AveDvmt_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                   envir = Hh_df[!IsUr_,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)
  #Limit the household DVMT to be no greater than 99th percentile for the population
  AveDvmt_[AveDvmt_ > quantile(AveDvmt_, 0.99)] <- quantile(AveDvmt_, 0.99)

  #Apply the 95th percentile and maximum DVMT models
  #-------------------------------------------------
  Hh_df$Dvmt <- AveDvmt_
  Hh_df$DvmtSq <- AveDvmt_ ^ 2
  Hh_df$DvmtCu <- AveDvmt_ ^ 3
  Dvmt95th_ <- numeric(NumHh)
  Dvmt95th_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Pctl95),
                   envir = Hh_df[IsUr_,]))
  Dvmt95th_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Pctl95),
                   envir = Hh_df[!IsUr_,]))
  DvmtMax_ <- numeric(NumHh)
  DvmtMax_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Max),
                   envir = Hh_df[IsUr_,]))
  DvmtMax_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Max),
                   envir = Hh_df[!IsUr_,]))

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Dvmt = AveDvmt_,
      Dvmt95th = Dvmt95th_,
      DvmtMax = DvmtMax_)
  #Return the outputs list
  Out_ls
}


#====================
#SECTION 4: TEST CODE
#====================
#The following code is useful for testing and module function development. The
#first part initializes a datastore, loads inputs, and checks that the datastore
#contains the data needed to run the module. The second part produces a list of
#the data the module function will be provided by the framework when it is run.
#This is useful to have when developing the module function. The third part
#runs the whole module to check that everything runs correctly and that the
#module outputs are consistent with specifications. Note that if a module
#requires data produced by another module, the test code for the other module
#must be run first so that the datastore contains the requisite data. Also note
#that it is important that all of the test code is commented out when the
#the package is built.

#1) Test code to set up datastore and return module specifications
#-----------------------------------------------------------------
#The following commented-out code can be run to initialize a datastore, load
#inputs, and check that the datastore contains the data needed to run the
#module. It return the processed module specifications which can be used in
#conjunction with the getFromDatastore function to fetch the list of data needed
#by the module. Note that the following code assumes that all the data required
#to set up a datastore are in the defs and inputs directories in the tests
#directory. All files in the defs directory must have the default names.
#
# Specs_ls <- testModule(
#   ModuleName = "CalculateHouseholdDVMT",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
#
#2) Test code to create a list of module inputs to use in module function
#------------------------------------------------------------------------
#The following commented-out code can be run to create a list of module inputs
#that may be used in the development of module functions. Note that the data
#will be returned for the first year in the run years specified in the
#run_parameters.json file. Also note that if the RunBy specification is not
#Region, the code will by default return the data for the first geographic area
#in the datastore.
#
# setwd("tests")
# Year <- getYears()[1]
# if (Specs_ls$RunBy == "Region") {
#   L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = NULL)
# } else {
#   GeoCategory <- Specs_ls$RunBy
#   Geo_ <- readFromTable(GeoCategory, GeoCategory, Year)
#   L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = Geo_[1])
#   rm(GeoCategory, Geo_)
# }
# rm(Year)
# setwd("..")
#
#3) Test code to run full module tests
#-------------------------------------
#Run the following commented-out code after the module functions have been
#written to test all aspects of the module including whether the module can be
#run and whether the module will produce results that are consistent with the
#module's Set specifications. It is also important to run this code if one or
#more other modules in the package need the dataset(s) produced by this module.
#
# testModule(
#   ModuleName = "CalculateHouseholdDVMT",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
