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



# TestHh.. <- Hh..
# TestHh..$PropWrkAgePersons <- TestHh..$DrvAgePop / TestHh..$Hhsize
# TestHh..$PropPrimeWorkers <- TestHh..$Age30to54 / TestHh..$Hhsize
# TestHh..$PropYoungWorkers <- ( TestHh..$Age15to19 + TestHh..$Age20to29 ) / TestHh..$Hhsize
# TestHh..$PropOldWorkers <- ( TestHh..$Age55to64 + TestHh..$Age65Plus ) / TestHh..$Hhsize
# TestHh..$PropWorkers <- TestHh..$PropPrimeWorkers + TestHh..$PropYoungWorkers +
#   TestHh..$PropOldWorkers
# TestHh..$PropKids1 <- TestHh..$Age0to14 / TestHh..$Hhsize
# TestHh..$PropKids2 <- ( TestHh..$Age0to14 + TestHh..$Age15to19 ) / TestHh..$Hhsize
# TestHh.. <- TestHh..[ , c( "PropWkDvmt", "PropWorkers", "PropPrimeWorkers",
#                            "PropYoungWorkers", "PropOldWorkers", "OnlyElderly", "Htppopdn", "PropKids1",
#                            "PropKids2", "PropWrkAgePersons", "DrvAgePop" ) ]
# TestHh.. <- TestHh..[ complete.cases( TestHh.. ), ]
# boxplot( TestHh..$PropWkDvmt ~ TestHh..$DrvAgePop )
# tapply( TestHh..$PropWkDvmt, TestHh..$DrvAgePop, mean )
# summary( lm( PropWkDvmt ~ PropWrkAgePersons, data=TestHh.. ) )
# summary( lm( PropWkDvmt ~ OnlyElderly, data=TestHh.. ) )
# summary( lm( PropWkDvmt ~ PropKids1, data=TestHh.. ) )
# summary( lm( PropWkDvmt ~ PropKids2, data=TestHh.. ) )
#
# rm( TestHh.. )
#
# #Test models to predict proportion of DVMT for work for households that had some work travel
# #-------------------------------------------------------------------------------------------
# TestHh.. <- Hh..
# TestHh..$PropWrkAgePersons <- TestHh..$DrvAgePop / TestHh..$Hhsize
# TestHh..$PropPrimeWorkers <- TestHh..$Age30to54 / TestHh..$Hhsize
# TestHh..$PropYoungWorkers <- ( TestHh..$Age15to19 + TestHh..$Age20to29 ) / TestHh..$Hhsize
# TestHh..$PropOldWorkers <- ( TestHh..$Age55to64 + TestHh..$Age65Plus ) / TestHh..$Hhsize
# TestHh..$PropWorkers <- TestHh..$PropPrimeWorkers + TestHh..$PropYoungWorkers +
#   TestHh..$PropOldWorkers
# TestHh..$PropKids1 <- TestHh..$Age0to14 / TestHh..$Hhsize
# TestHh..$PropKids2 <- ( TestHh..$Age0to14 + TestHh..$Age15to19 ) / TestHh..$Hhsize
# TestHh.. <- TestHh..[ , c( "PropWkDvmt", "PropWorkers", "PropPrimeWorkers",
#                            "PropYoungWorkers", "PropOldWorkers", "OnlyElderly", "Htppopdn", "PropKids1",
#                            "PropKids2", "PropWrkAgePersons" ) ]
# TestHh.. <- TestHh..[ complete.cases( TestHh.. ), ]
# TestHh.. <- TestHh..[ TestHh..$PropWkDvmt != 0, ]
# summary( lm( PropWkDvmt ~ PropWrkAgePersons, data=TestHh.. ) )
# summary( lm( PropWkDvmt ~ OnlyElderly, data=TestHh.. ) )
# summary( lm( PropWkDvmt ~ PropKids1, data=TestHh.. ) )
# summary( lm( PropWkDvmt ~ PropKids2, data=TestHh.. ) )
# rm( TestHh.. )
#
# #Calculate the mean proportion of household travel for work
# #----------------------------------------------------------
# MeanWorkDvmtProp <- mean( Hh..$PropWkDvmt, na.rm=TRUE )
# MeanWorkDvmtProp


#============
#PARKING COST
#============

#The effect of parking costs is modeled by calculating an average daily cost for parking. This gets added in with other vehicle costs so that the total budget effects of all vehicle costs can be modeled. Parking costs applied to each household have two components: the cost of parking at work and the cost of parking in conjunction with other travel.

#Assumed labor force participation rate = 0.65

#Define function to identify number of workers who pay parking
#=============================================================

#Notes:
#This function calculates the number of people in each household who pay parking at work and the number of people to have their parking cashed out. This function is associated with the calcParkCostAdj function which calculates the parking cost on a per mile basis. The functions were split to facilitate testing. By doing this split a set of paying parkers can be kept constant while testing the effect of different parking charges. All of the inputs for both functions are arguments to the first function. Then all the arguments are bundled into the list object that is returned. That list object is then the sole input to the calcParkCostAdj. This was done to simplify application and keep the inputs consistent.

# idPayingParkers <- function( Data.., PropWrkPkg, PropWrkChrgd, PropCashOut, PropOthChrgd,
#                              LabForcePartRate=0.65, PkgCost, PropWrkTrav=0.22, WrkDaysPerYear=260 ) {
#
#   # Calculate number of working age persons that pay parking
#   PropOthPkg <- 1 - PropWrkPkg
#   PropChrgdPkg <- PropWrkChrgd * PropWrkPkg + PropOthChrgd * PropOthPkg
#   PropAvailPkg <- PropWrkChrgd * PropWrkPkg + PropOthPkg
#   PropWrkPay <- PropWrkChrgd * PropChrgdPkg / PropAvailPkg
#   PropWrkAgePay <- PropWrkPay * LabForcePartRate
#   NumWrkAgePer <- sum( Data..$DrvAgePop )
#   NumWrkAgePay <- round( PropWrkAgePay * NumWrkAgePer )
#
#   # Calculate number of workers paying parking that are cash-out-buy-back
#   NumCashOut <- round( NumWrkAgePay * PropCashOut )
#
#   # Identify which persons pay parking
#   WrkHhId. <- rep( Data..$Houseid, Data..$DrvAgePop )
#   HhIdPay. <- sample( WrkHhId. )[ 1:NumWrkAgePay ]
#
#   # Identify which persons get cash reimbursement for parking
#   if( NumCashOut >= 1 ) {
#     HhIdCashOut. <- sample( HhIdPay. )[ 1:NumCashOut ]
#   } else {
#     HhIdCashOut. <- NULL
#   }
#
#   # Identify the number of persons in each household who pay for parking
#   NumHhPayers. <- tapply( HhIdPay., HhIdPay., function(x) length(x) )
#   NumPayers.Hh <- numeric( nrow( Data.. ) )
#   names( NumPayers.Hh ) <- Data..$Houseid
#   NumPayers.Hh[ names( NumHhPayers. ) ] <- NumHhPayers.
#
#   # Identify the number of persons in each household who get reimbursement
#   NumCashOut.Hh <- numeric( nrow( Data.. ) )
#   names( NumCashOut.Hh ) <- Data..$Houseid
#   if( !is.null( HhIdCashOut. ) ) {
#     NumHhCashOut. <- tapply( HhIdCashOut., HhIdCashOut., function(x) length(x) )
#     NumCashOut.Hh[ names( NumHhCashOut. ) ] <- NumHhCashOut.
#   }
#
#   # Return the result
#   list( NumPayers.Hh=NumPayers.Hh, NumCashOut.Hh=NumCashOut.Hh,
#         PropWrkPkg=PropWrkPkg, PropWrkChrgd=PropWrkChrgd, PropCashOut=PropCashOut,
#         PropOthChrgd=PropOthChrgd, LabForcePartRate=0.65, PkgCost=PkgCost,
#         PropWrkTrav=0.22, WrkDaysPerYear=260 )
#
# }
#
# save( idPayingParkers, file="model/idPayingParkers.RData" )
#
#
# #Define a function to calculate parking cost on a daily basis
# #============================================================
#
# calcParkCostAdj <- function( Data.., Park_ ) {
#
#   NumPayers.Hh <- Park_$NumPayers.Hh
#   NumCashOut.Hh <- Park_$NumCashOut.Hh
#   PropWrkChrgd <- Park_$PropWrkChrgd
#   PkgCost <- Park_$PkgCost
#   PropOthChrgd <- Park_$PropOthChrgd
#   PropWrkPkg <- Park_$PropWrkPkg
#   PropWrkTrav <- Park_$PropWrkTrav
#   LabForcePartRate <- Park_$LabForcePartRate
#   WrkDaysPerYear <- Park_$WrkDaysPerYear
#
#   # Sum the daily work parking costs by household
#   WrkPkgCost.Hh <- NumPayers.Hh * PkgCost
#
#   # Add daily parking cost for non-work travel
#   OthPkgCost.Hh <- WrkPkgCost.Hh * 0  # Initialize vector
#   OthPkgCost.Hh[] <- PkgCost * PropOthChrgd * ( 1 - PropWrkTrav )
#
#   # Add the work daily parking cost to the other daily parking cost
#   DailyPkgCost.Hh <- WrkPkgCost.Hh + OthPkgCost.Hh
#   DailyPkgCost.Hh[ Data..$Hhvehcnt == 0 ] <- 0
#
#   # Calculate the parking cost per mile
#   PkgCostMile.Hh <- numeric( length( DailyPkgCost.Hh ) )
#   PkgCostMile.Hh[ DailyPkgCost.Hh > 0 ] <-
#     100 * DailyPkgCost.Hh[ DailyPkgCost.Hh > 0 ] / Data..$Dvmt[ DailyPkgCost.Hh > 0 ]
#
#   # Sum the cash out parking income adjustment by household
#   CashOutIncAdj.Hh <- NumCashOut.Hh * PkgCost * WrkDaysPerYear
#
#   # Return the result
#   list( DailyPkgCost=DailyPkgCost.Hh, CashOutIncAdj=CashOutIncAdj.Hh,
#         PkgCostMile=PkgCostMile.Hh )
#
# }
#
# save( calcParkCostAdj, file="model/calcParkCostAdj.RData" )


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------



#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
