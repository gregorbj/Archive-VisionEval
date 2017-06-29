#=====================
#Make2001NHTSDataset.R
#=====================
#This module creates a data frame of data from the publically available data
#from the 2001 National Household Travel Survey (NHTS) augmented with data on
#metropolitan area freeway supply and transit supply. The package produces a
#data frame of values by household.

# Copyright [2017] [AASHTO]
# Based largely on works previously copyrighted by the Oregon Department of
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


#=======
#PURPOSE
#=======

#This script processes 2001 NHTS text files to create the household travel
#dataset to be used in model estimation. Data on freeway lane miles and
#bus equivalent transit revenue miles are added. A household dataframe (Hh_df)
#containing travel and other relevant data for each survey household.


#=====
#SETUP
#=====

#Define functions
#----------------

toProperName <- function(X){
          EndX <- nchar(X)
          paste(toupper(substring(X, 1, 1)), tolower(substring(X, 2, EndX)), sep="")
}

toVecFrom1DAry <- function(X_ar){
  X_ <- as.vector(X_ar)
  names(X_) <- names(X_ar)
  X_
}

#Load NHTS household data
#------------------------
#The following commented code was used to develop R dataset from the NHTS
#HHPUB.csv file:
# Hh_df <- read.csv("inst/extdata/HHPUB.csv", as.is = TRUE)
# Keep_ <- c("HOUSEID", "AGE_P1", "AGE_P2", "AGE_P3", "AGE_P4", "AGE_P5", "AGE_P6",
#   "AGE_P7", "AGE_P8", "AGE_P9", "AGE_P10", "AGE_P11", "AGE_P12", "AGE_P13",
#   "AGE_P14", "CENSUS_D", "CENSUS_R", "DRVRCNT", "EXPFLHHN", "EXPFLLHH",
#   "FLGFINCM", "HBHRESDN", "HBHUR", "HBPPOPDN", "HHC_MSA", "HHFAMINC",
#   "HHINCTTL", "HHNUMBIK", "HHR_AGE", "HHR_DRVR", "HHR_RACE", "HHR_SEX",
#   "HHSIZE", "HHVEHCNT", "HOMETYPE", "HTEEMPDN", "HTHRESDN", "HTHUR",
#   "HTPPOPDN", "LIF_CYC", "MSACAT", "MSASIZE", "RAIL", "RATIO16V",
#   "URBAN", "URBRUR", "WRKCOUNT", "CNTTDHH")
# AllTripsHh_ <- Hh_df$HOUSEID[!is.na(Hh_df$EXPFLLHH)]
# Hh_df <- Hh_df[Hh_df$HOUSEID %in% AllTripsHh_, Keep_]
# save(Hh_df, file = "inst/extdata/Hh_df.rda", compress = TRUE)

#Load NHTS household dataset
load("inst/extdata/Hh_df.rda")
names(Hh_df) <- toProperName(names(Hh_df))
Hh_df[Hh_df < 0] <- NA

#Load NHTS vehicle data
#----------------------
#The following commented code was used to develop R dataset from the NHTS
#VEHPUB.csv file:
# Veh_df <- read.csv("inst/extdata/VEHPUB.csv", as.is = TRUE)
# Keep_ <-
#   c("HOUSEID", "VEHID", "BESTMILE", "EIADMPG", "GSCOST", "VEHTYPE", "VEHYEAR",
#     "VEHMILES" )
# Veh_df <-
#   Veh_df[Veh_df$HOUSEID %in% AllTripsHh_, Keep_]
# save(Veh_df, file = "inst/extdata/Veh_df.rda", compress = TRUE)

#Load the NHTS vehicle dataset
load("inst/extdata/Veh_df.rda")
names(Veh_df) <- toProperName(names(Veh_df))
Veh_df$Vehid <- as.character(Veh_df$Vehid)
Veh_df[Veh_df < 0] <- NA

#Load NHTS person data
#---------------------
#The following commented code was used to develop R dataset from the NHTS
#PERPUB.csv file:
# Per_df <- read.csv("inst/extdata/PERPUB.csv", as.is = TRUE)
# Keep_ <-
#   c("HOUSEID", "PERSONID", "COMMDRVR", "NBIKETRP", "NWALKTRP", "USEPUBTR",
#     "WRKDRIVE", "WRKTRANS", "DTGAS")
# Per_df <-
#   Per_df[Per_df$HOUSEID %in% AllTripsHh_, Keep_]
# save(Per_df, file = "inst/extdata/Per_df.rda", compress = TRUE)

#Load the NHTS persons file
load("inst/extdata/Per_df.rda")
names(Per_df) <- toProperName(names(Per_df))
Per_df$Personid <- as.character(Per_df$Personid)
Per_df[Per_df < 0] <- NA

#Load NHTS daily trip data
#-------------------------
# The following commented code was used to develop R dataset from the NHTS
# DAYPUB.csv file:
# Dt_df <- read.csv("inst/extdata/DAYPUB.csv", as.is = TRUE)
# Keep_ <-
#   c("HOUSEID", "VEHID", "PERSONID", "NUMONTRP", "TRPMILES", "TRPTRANS",
#     "TRVL_MIN", "PSGR_FLG", "WHYFROM", "WHYTO")
# Dt_df <-
#   Dt_df[Dt_df$HOUSEID %in% AllTripsHh_, Keep_]
# save(Dt_df, file = "inst/extdata/Dt_df.rda", compress = TRUE)

#Load the NHTS daily trips file
load("inst/extdata/Dt_df.rda")
names(Dt_df) <- toProperName(names(Dt_df))
Dt_df$Vehid <- as.character(Dt_df$Vehid)
Dt_df$Personid <- as.character(Dt_df$Personid)
Dt_df[Dt_df < 0] <- NA


#================
#PROCESS DATASETS
#================

#Calculate the number of persons by age group and add summary to household data
#------------------------------------------------------------------------------
AgeFields_ <-
  c("Age_p1", "Age_p2", "Age_p3", "Age_p4", "Age_p5", "Age_p6", "Age_p7",
    "Age_p8", "Age_p9", "Age_p10", "Age_p11", "Age_p12", "Age_p13", "Age_p14" )
# Set up person age categories
AgeBreaks <- c(0, 14, 19, 29, 54, 64, max(Hh_df[,AgeFields_], na.rm = TRUE))
# Tabulate persons per household by age category
Ages_HhAg <- t(apply( Hh_df[,AgeFields_], 1, function(x) {
  table(cut(x, AgeBreaks, include.lowest=TRUE, right=FALSE))
}))
# Assign tabulations to age category variables
Hh_df$Age0to14  <- Ages_HhAg[,1]
Hh_df$Age15to19 <- Ages_HhAg[,2]
Hh_df$Age20to29 <- Ages_HhAg[,3]
Hh_df$Age30to54 <- Ages_HhAg[,4]
Hh_df$Age55to64 <- Ages_HhAg[,5]
Hh_df$Age65Plus <- Ages_HhAg[,6]
# Clean up
Hh_df[AgeFields_] <- NULL
rm( AgeFields_, AgeBreaks, Ages_HhAg )

#Process household income data
#-----------------------------
#Define income groupings from NHTS code book
#Assume top value of high income group to be 200K
IncGrp_ls <-
  list(
    c(0, 4999),
    c(5000, 9999),
    c(10000, 14999),
    c(15000, 19999),
    c(20000, 24999),
    c(25000, 29999),
    c(30000, 34999),
    c(35000, 39999),
    c(40000, 44999),
    c(45000, 49999),
    c(50000, 54999),
    c(55000, 59999),
    c(60000, 64999),
    c(65000, 69999),
    c(70000, 74999),
    c(75000, 79999),
    c(80000, 99999),
    c(100000, 199999)
  )
#Calculate midpoints in income ranges
MidPtInc_ <- unlist(lapply(IncGrp_ls, mean))
#Assign income values
Hh_df$Income <- MidPtInc_[Hh_df$Hhincttl]
rm(IncGrp_ls, MidPtInc_)
#Assign income group variable
IncBreaks_ <- c( 0, 20000, 40000, 60000, 80000, 100000, 150000 )
Ig <- c( "0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K",
         "100KPlus" )
Hh_df$IncGrp <- cut(Hh_df$Income, IncBreaks_, labels=Ig, include.lowest=TRUE)
rm(IncBreaks_, Ig)

#Create dummy variables for development type
#-------------------------------------------
Hh_df$UrbanDev <- (Hh_df$Hbhur == "U") * 1
Hh_df$TownDev <- (Hh_df$Hbhur == "T") * 1
Hh_df$SuburbanDev <- (Hh_df$Hbhur == "S") * 1
Hh_df$RuralDev <- (Hh_df$Hbhur == "R") * 1
Hh_df$SecondCityDev <- (Hh_df$Hbhur == "C") * 1

#Calculate numbers of household autos and light trucks
#-----------------------------------------------------
#Classify vehicles as Passenger and LightTruck
Veh_df$Type <- rep(NA, nrow(Veh_df))
Veh_df$Type[Veh_df$Vehtype == 1] <- "Auto"
Veh_df$Type[Veh_df$Vehtype %in% c(2, 3, 4)] <- "LightTruck"
#Keep only the vehicles that are autos or light trucks
Veh_df <- Veh_df[Veh_df$Type %in% c("Auto", "LightTruck"),]
#Add auto and light-truck counts to household dataset
NumAuto_Hh <-
  toVecFrom1DAry(
    tapply(Veh_df$Type,
           Veh_df$Houseid,
           function(x) sum(x == "Auto"),
           simplify = TRUE))
NumLightTruck_Hh <-
  toVecFrom1DAry(
    tapply(Veh_df$Type,
           Veh_df$Houseid,
           function(x) sum(x == "LightTruck"),
           simplify = TRUE))
Hh_df$NumAuto <- unname(NumAuto_Hh[Hh_df$Houseid])
Hh_df$NumAuto[is.na(Hh_df$NumAuto)] <- 0
Hh_df$NumLightTruck <- unname(NumLightTruck_Hh[Hh_df$Houseid])
Hh_df$NumLightTruck[is.na(Hh_df$NumLightTruck)] <- 0
rm(NumAuto_Hh, NumLightTruck_Hh)

#Revise total vehicle count and compute ratio with driving age persons
#---------------------------------------------------------------------
#Make total vehicles (Hhvehcnt) equal to numbers of autos and light trucks
Hh_df$NumVeh <- Hh_df$NumAuto + Hh_df$NumLightTruck
#Calculate ratio of vehicles to driving age persons
DrvAgePop_ <- with(Hh_df, Hhsize - Age0to14)
VehPerDrvAgePop_ <- Hh_df$NumVeh / DrvAgePop_
Hh_df$VehPerDrvAgePop <- VehPerDrvAgePop_
rm(DrvAgePop_, VehPerDrvAgePop_)

#Add total annual vehicle mileage data to household dataset
#----------------------------------------------------------
#Best annual mileage estimates were prepared for about 20,000 of the households
HhBestmile_ <-
  unlist(tapply(Veh_df$Bestmile, Veh_df$Houseid, function(x) {
    if(all(!is.na(x))) sum(x)}))
#Add to Hh_df (note use of match is much faster than indexing using names)
Hh_df$Totmiles <- unname(HhBestmile_[match(Hh_df$Houseid, names(HhBestmile_))])
rm(HhBestmile_)

#Calculate household average Gscostmile weighted by vehicle mileage
#------------------------------------------------------------------
#Split vehicle dataset by household
Veh_ls <- split(Veh_df, Veh_df$Houseid)
#Calculate average MPG of household vehicles
HhAveMpg_Hh <- unlist(lapply(Veh_ls, function(x) {
  Mpg_ <- x$Eiadmpg
  Miles_ <- x$Bestmile
  Mpg_[is.na(Mpg_)] <- 0
  Miles_[is.na(Miles_)] <- 0
  Miles_[Mpg_ == 0] <- 0
  Mpg_[Miles_ == 0] <- 0
  sum(Mpg_ * Miles_) / sum(Miles_)
}))
#Add results to Hh_df
Hh_df$AveMpg <- unname(HhAveMpg_Hh[match(Hh_df$Houseid, names(HhAveMpg_Hh))])
#Calculate average gas cost (cents/gallon) for households
Gscost_Hh <-
  toVecFrom1DAry(
    tapply(Veh_df$Gscost, Veh_df$Houseid, function(x) mean(x, na.rm=TRUE)))
Hh_df$Gscost <- unname(Gscost_Hh[match(Hh_df$Houseid, names(Gscost_Hh))])
#Calculate average gas cost per mile (cents/mile) of travel by household
Hh_df$Gscostmile <- with(Hh_df, Gscost / AveMpg)
#Calculate the gas cost per mile (Gscostmile2) for each vehicle (cents per mile)
Veh_df$Gscostmile2 <- with(Veh_df, Gscost / Eiadmpg)
#Average vehicle gas cost per mile by household
Gscostmile2_Hh <-
  toVecFrom1DAry(
    tapply(Veh_df$Gscostmile2, Veh_df$Houseid, function(x) mean(x, na.rm=TRUE)))
Hh_df$Gscostmile2 <-
  unname(Gscostmile2_Hh[match(Hh_df$Houseid, names(Gscostmile2_Hh))])
rm(Gscostmile2_Hh, Veh_ls, HhAveMpg_Hh, Gscost_Hh)

#Tabulate daily vehicle travel from the day trip data and add to the household data
#----------------------------------------------------------------------------------
#Daily vehicle travel in personal vehicles is tabulated for each household. For
#these purposes, personal vehicle travel is defined to include all modes that
#are most likely to be owned by households: car, van, SUV,  pickup truck, other
#truck, RV, motorcycle. Vehicle travel is only summed for person trips where the
#person is identified as a driver in order to avoid double counting. A separate
#tabulation is made of vehicle travel by households that own no vehicles. For
#these purposes, taxicabs are included in the definition of personal vehicle
#travel. This is important in order to model the effect of carsharing (for no
#vehicle households, carsharing tends to increase vehicle travel).

#Tabulate private vehicle travel where not a passenger and speed is reasonable
#-----------------------------------------------------------------------------
#Make filters for selecting the proper records
WasNotPsgr_ <- Dt_df$Psgr_flg == 2
WasPrivateVeh_ <- Dt_df$Trptrans %in% 1:7
WasRecorded_ <- Dt_df$Trpmiles > 0
NotTooFast_ <- Dt_df$Trpmiles / Dt_df$Trvl_min < 1.5
UseRecord_ <- WasNotPsgr_ & WasPrivateVeh_ & WasRecorded_ & NotTooFast_
#Tabulate vehicle miles by household
Dvmt_Hh <-
  toVecFrom1DAry(
    tapply(Dt_df$Trpmiles[UseRecord_], Dt_df$Houseid[UseRecord_], sum))
Hh_df$Dvmt <- unname(Dvmt_Hh[match(Hh_df$Houseid, names(Dvmt_Hh))])

#Make a variable to identify home-to-home tours
#----------------------------------------------
HomeStart_ <- Dt_df$Whyfrom
HomeStart_[HomeStart_ != 1] <- 0
TourNum_ <- unlist(tapply(HomeStart_, Dt_df$Houseid, cumsum))
Padding_ <- rep("0", length(TourNum_))
Padding_[nchar(TourNum_) == 2] <- ""
TourId_ <- paste(Dt_df$Houseid, Padding_, TourNum_, sep="")
rm(HomeStart_, Padding_)

#Calculate mileage in short SOV tours
#------------------------------------
#Calculate total vehicle miles in each home-to-home tour
IsVehicle_ <- as.numeric(Dt_df$Vehid) > 0
TrpVmt_ <- Dt_df$Trpmiles * as.numeric(IsVehicle_)
TrpVmt_[TourNum_ == 0] <- NA # NA for non-home-to-home tours
TourVmt_ <- tapply(TrpVmt_[UseRecord_] , TourId_[UseRecord_] , sum)
IsNaTourVmt_ <- is.na(TourVmt_) # Identify which records are NA
TourVmt_ <- TourVmt_[!IsNaTourVmt_] # Remove the NA records
#Identify single occupancy vehicle tours
IsSov_ <- IsVehicle_ & (Dt_df$Numontrp == 1)
IsSovTour_ <- tapply(IsSov_[UseRecord_], TourId_[UseRecord_], function(x) all(x))
IsSovTour_ <- IsSovTour_[!IsNaTourVmt_]
#Identify households that have SOV tours
TourHhId_ <- substr(names(TourVmt_), 1, 9)
#Sum up SOV tour mileage less than specified lengths by household
calcTourVmtProp <- function(TourLen) {
  SovTour_ <-
    toVecFrom1DAry(
      tapply(TourVmt_[TourVmt_ <= TourLen & IsSovTour_],
           TourHhId_[TourVmt_ <= TourLen & IsSovTour_], sum))
  SovTour_Hh <- numeric(nrow(Hh_df))
  names(SovTour_Hh) <- Hh_df$Houseid
  SovTour_Hh[names(SovTour_)] <- SovTour_
  NaHhNames_ <- unique(substr(names(IsNaTourVmt_)[IsNaTourVmt_], 1, 9))
  SovTour_Hh[NaHhNames_] <- NA
  unname(SovTour_Hh) / Hh_df$Dvmt
}
#Calculate proportions of household DVMT in SOV categories and add to Hh_df
Hh_df$PropSovDvmtLE2 <- calcTourVmtProp(2)
Hh_df$PropSovDvmtLE5 <- calcTourVmtProp(5)
Hh_df$PropSovDvmtLE10 <- calcTourVmtProp(10)
Hh_df$PropSovDvmtLE15 <- calcTourVmtProp(15)
Hh_df$PropSovDvmtLE20 <- calcTourVmtProp(20)
#Clean up workspace
rm(TrpVmt_, TourVmt_, IsNaTourVmt_, IsSov_, IsSovTour_, TourHhId_)

#Calculate work trip mileage proportions
#---------------------------------------
#Identify work tours
WorkCodes_ <- c(11, 12, 13, 14)
IsWork_ <- (Dt_df$Whyfrom %in% WorkCodes_) | (Dt_df$Whyto %in% WorkCodes_)
IsWorkTour_ <- tapply(IsWork_, TourId_, function(x) any(x))
#Calculate total vehicle miles in each home-to-home tour
TrpVmt_ <- Dt_df$Trpmiles * as.numeric(IsVehicle_)
TrpVmt_[TourNum_ == 0] <- NA # NA for non-home-to-home tours
TourVmt_ <- tapply(TrpVmt_[UseRecord_] , TourId_[UseRecord_] , sum)
WkTourVmt_ <- TourVmt_[IsWorkTour_]
IsNaWkTourVmt_ <- is.na(WkTourVmt_) # Identify which records are NA
WkTourVmt_ <- WkTourVmt_[!IsNaWkTourVmt_] # Remove NA records
#Identify households that have work tours
WkTourHhId_ <- substr(names(WkTourVmt_), 1, 9)
#Sum work tour DVMT by household
HhWkTourVmt_ <- tapply(WkTourVmt_, WkTourHhId_, sum)
#Put results in a vector that conforms with Hh_df
WkTourVmt_Hh <- numeric(nrow( Hh_df))
names(WkTourVmt_Hh) <- Hh_df$Houseid
WkTourVmt_Hh[names(HhWkTourVmt_)] <- HhWkTourVmt_
#Set values as NA for households with ambiguous tours
NaHhNames_ <- unique(substr(names(IsNaWkTourVmt_)[IsNaWkTourVmt_], 1, 9))
WkTourVmt_Hh[NaHhNames_] <- NA
WkTourVmt_Hh <- WkTourVmt_Hh[!is.na(names(WkTourVmt_Hh))]
#Calculate the proportion of household DVMT that is part of a work tour and put in Hh_df
Hh_df$PropWkDvmt <- WkTourVmt_Hh / Hh_df$Dvmt
#Clean up workspace
rm(TourNum_, TourId_, WorkCodes_, IsWork_, IsWorkTour_, TrpVmt_, TourVmt_,
   WkTourVmt_, IsNaWkTourVmt_, WkTourHhId_, WkTourVmt_Hh, NaHhNames_ )

#Tabulate private vehicle travel of zero-vehicle households as a passenger
#-------------------------------------------------------------------------
#Identify number of household vehicles
NumVeh_Dt <- Hh_df$Hhvehcnt[match(Dt_df$Houseid, Hh_df$Houseid)]
#Make additional filters for selecting the proper records
#Include taxicab in the definition of private vehicles
WasPrivateVeh_ <- Dt_df$Trptrans %in% c(1:7, 22)
WasNoVehHhTravel_ <- NumVeh_Dt == 0
WasPsgr_ <- Dt_df$Psgr_flg == 1
UseRecord_ <-
  WasNoVehHhTravel_ & WasPsgr_ & WasPrivateVeh_ & WasRecorded_ & NotTooFast_
#Tabulate vehicle miles of passenger travel by zero vehicle households
ZeroVehPassDvmt_Hh <-
  toVecFrom1DAry(
    tapply(Dt_df$Trpmiles[UseRecord_], Dt_df$Houseid[UseRecord_], sum))
Hh_df$ZeroVehPassDvmt <-
  unname(ZeroVehPassDvmt_Hh[match(Hh_df$Houseid, names(ZeroVehPassDvmt_Hh))])
#Clean up
rm(WasPrivateVeh_, WasRecorded_, NotTooFast_, WasNoVehHhTravel_, WasPsgr_,
   UseRecord_, ZeroVehPassDvmt_Hh )

#Calculate walk and bike trip mileage
#------------------------------------
WasWalkOrBikeTrp_ <- Dt_df$Trptrans %in% c(25, 26)
TrpMiles_ <- Dt_df$Trpmiles
TrpMiles_[TrpMiles_ < 0] <- NA
WalkBikeMiles_Hx <-
  tapply(TrpMiles_[WasWalkOrBikeTrp_], Dt_df$Houseid[WasWalkOrBikeTrp_], sum)
WalkBikeMiles_Hh <- numeric(nrow(Hh_df))
names(WalkBikeMiles_Hh) <- Hh_df$Houseid
WalkBikeMiles_Hh[names(WalkBikeMiles_Hx)] <- WalkBikeMiles_Hx
Hh_df$WalkBikeMiles <- WalkBikeMiles_Hh
rm(WasWalkOrBikeTrp_, TrpMiles_, WalkBikeMiles_Hx, WalkBikeMiles_Hh)

#Examine household day trip records that have no "usable" DVMT
#-------------------------------------------------------------
#Identify the households having NA values for Dvmt
NaHh_ <- Hh_df$Houseid[is.na(Hh_df$Dvmt)]
# There are 8899 of them
length(NaHh_)

#Evaluate households that have no day trip records (3950)
#--------------------------------------------------------
DtHh_ <- unique(Dt_df$Houseid)
NoDtHh_ <- Hh_df$Houseid[!(Hh_df$Houseid %in% DtHh_)]
#55% percent of the no day trip households only have persons over 65 years old
OnlyElderly_Hh <- Hh_df$Age65Plus == Hh_df$Hhsize
sum(NoDtHh_ %in% Hh_df$Houseid[OnlyElderly_Hh]) / length(NoDtHh_)
# 61% have only one person in the household and 30% have two persons in the household
table(Hh_df$Hhsize[Hh_df$Houseid %in% NoDtHh_]) / length(NoDtHh_)
# These records will be coded with zero because it is reasonable to believe that
# the households took no trips on the survey day
Hh_df$Dvmt[Hh_df$Houseid %in% NoDtHh_] <- 0

#Evaluate households that do have some day trip records
#------------------------------------------------------
#Make a subset of the day trip data for the NA households having day trip data
NaHh2_ <- NaHh_[!(NaHh_ %in% NoDtHh_)]
NotUseDt_df <- Dt_df[Dt_df$Houseid %in% NaHh2_,]
NotUseDt_df$WasPrivateVeh <- NotUseDt_df$Trptrans %in% c(1:7, 22)
# Split the dataset
NotUseDt_ls <- split(NotUseDt_df, NotUseDt_df$Houseid)
# Identify households where all trips were as passengers or non-private vehicle
# These will all be identified as having zero VMT
WasAllPsgr_ <- unlist(lapply(NotUseDt_ls, function(x) {
  all(x$Psgr_flg %in% c(-1, 1))
}))
AllPsgrHh_ <- names(WasAllPsgr_)[WasAllPsgr_]
Hh_df$Dvmt[Hh_df$Houseid %in% AllPsgrHh_] <- 0
# Clean up
rm(NaHh_, DtHh_, NoDtHh_, OnlyElderly_Hh, NaHh2_, NotUseDt_df, NotUseDt_ls,
   WasAllPsgr_, AllPsgrHh_)

#Make a variable which identifies households that did no travel
#--------------------------------------------------------------
Hh_df$ZeroDvmt <- "N"
Hh_df$ZeroDvmt[Hh_df$Dvmt == 0] <- "Y"
Hh_df$ZeroDvmt[is.na(Hh_df$Dvmt)] <- NA
Hh_df$ZeroDvmt <- as.factor(Hh_df$ZeroDvmt)

#Add person travel data to the household records
#-----------------------------------------------
#Split the person data
Per_ls <- split(Per_df, Per_df$Houseid)
#Sum person data to the household level
Numcommdrvr_Hh <- unlist(lapply(Per_ls, function(x) {
  sum(x$Commdrvr == 1, na.rm=TRUE)}))
Nbiketrp_Hh <- unlist(lapply(Per_ls, function(x) {
  sum(x$Nbiketrp, na.rm=TRUE)}))
Nwalktrp_Hh <- unlist(lapply(Per_ls, function(x) {
  sum(x$Nwalktrp, na.rm=TRUE)}))
Usepubtr_Hh <- unlist(lapply(Per_ls, function(x) {
  any(x$Usepubtr == 1)}))
Numwrkdrvr_Hh <- unlist(lapply(Per_ls, function(x) {
  sum(x$Wrkdrive == 1, na.rm=TRUE)}))
#Add the person data to the household data
Hh_df$Numcommdrvr <- Numcommdrvr_Hh[Hh_df$Houseid]
Hh_df$Nbiketrp <- Nbiketrp_Hh[Hh_df$Houseid]
Hh_df$Nwalktrp <- Nwalktrp_Hh[Hh_df$Houseid]
Hh_df$Usepubtr <- Usepubtr_Hh[Hh_df$Houseid]
Hh_df$Numwrkdrvr <- Numwrkdrvr_Hh[Hh_df$Houseid]
#Clean up
rm(Per_ls, Numcommdrvr_Hh, Nbiketrp_Hh, Nwalktrp_Hh, Usepubtr_Hh, Numwrkdrvr_Hh)

#Add the highway supply data
#---------------------------
#Change Hhc_msa to character variable to link up highway data properly
Hh_df$Hhc_msa <- as.character(Hh_df$Hhc_msa)
#Load data file
Hwy2001_df <-
  read.csv("inst/extdata/HighwayStatistics2.csv",
           colClasses = c(rep("character", 2), rep("numeric", 8)))
#Sum quantities by Msa Code
RoadMi_Mc <- toVecFrom1DAry(tapply(Hwy2001_df$RoadMiles, Hwy2001_df$MsaCode, sum))
Pop_Mc <- toVecFrom1DAry(tapply(Hwy2001_df$Population, Hwy2001_df$MsaCode, sum))
FwyLnMi_Mc <- toVecFrom1DAry(tapply(Hwy2001_df$FwyLaneMi, Hwy2001_df$MsaCode, sum))
Area_Mc <- toVecFrom1DAry(tapply(Hwy2001_df$Area, Hwy2001_df$MsaCode, sum))
# Calculate per capita quantities (per 1000s population)
RoadMiCap_Mc <- RoadMi_Mc / Pop_Mc
FwyLnMiCap_Mc <- FwyLnMi_Mc / Pop_Mc
# Calculate urbanized area density
MsaPopdn_Mc <- 1000 * Pop_Mc / Area_Mc
# Add to household data set
Hh_df$RoadMiPC <- unname(RoadMiCap_Mc[Hh_df$Hhc_msa])
Hh_df$FwyLnMiPC <- unname(FwyLnMiCap_Mc[Hh_df$Hhc_msa])
Hh_df$MsaPopDen <- unname(MsaPopdn_Mc[Hh_df$Hhc_msa])
# Clean up workspace
rm(RoadMi_Mc, Pop_Mc, FwyLnMi_Mc, Area_Mc, RoadMiCap_Mc, FwyLnMiCap_Mc,
   MsaPopdn_Mc, Hwy2001_df)

#Add the transit supply data
#---------------------------
#Load the data file
Transit2001_df <- read.csv("inst/extdata/uza_bus_eq_rev_mi.csv", as.is = TRUE)
Transit2001_df$MSACode <- as.character(Transit2001_df$MSACode)
Transit2001_df$MSACode[Transit2001_df$MSACode == "520"] <- "0520"
Transit2001_df$MSACode[Transit2001_df$MSACode == "640"] <- "0640"
Transit2001_df$UZAName <- as.character(Transit2001_df$UZAName)
#Add per capita transit bus equivalent revenue miles to household data
IsIdentifiedUZA_ <- !is.na(Transit2001_df$MSACode)
BusEqRevMiPC_ <- Transit2001_df$BusEqRevMiPC[IsIdentifiedUZA_]
names(BusEqRevMiPC_) <- Transit2001_df$MSACode[IsIdentifiedUZA_]
Hh_df$BusEqRevMiPC <- unname(BusEqRevMiPC_[Hh_df$Hhc_msa])
#Set West Palm Beach to be same as Miami because the areas are included
#together in the NTD transit data
Hh_df$BusEqRevMiPC[Hh_df$Hhc_msa == "8960"] <- BusEqRevMiPC_["4992"]


#=========================================
#IDENTIFY PROPER VARIABLE TYPES AND VALUES
#=========================================

#Convert group variables to factors and replace values with NA where appropriate
#-------------------------------------------------------------------------------
Hh_df$Census_d <-
  factor(Hh_df$Census_d,
         labels = c("New England", "Middle Atlantic", "East North Central",
                    "West North Central", "South Atlantic", "East South Central",
                    "West South Central", "Mountain", "Pacific"))
Hh_df$Census_r <-
  factor(Hh_df$Census_r,
         labels = c("Northeast", "Midwest", "South", "West"))
Hh_df$Flgfincm <-
  factor(Hh_df$Flgfincm,
         levels = c("-7", "-8", "-9", "1", "2"),
         labels = c("Refused", "Don't Know", "Not Ascertained", "Yes", "No"))
Hh_df$Hhr_drvr <- factor(Hh_df$Hhr_drvr, labels = c("Yes", "No"))
Hh_df$Hhr_race <- factor( Hh_df$Hhr_race )
Hh_df$Hhr_sex <- factor( Hh_df$Hhr_sex, labels = c( "Male", "Female" ) )
Hh_df$Hometype <-
  factor(Hh_df$Hometype,
         labels = c("Single Family", "Duplex", "Attached", "Multi-family",
                    "Mobile Home", "Dorm", "Other"))
Hh_df$Lif_cyc <- factor(Hh_df$Lif_cyc)
Hh_df$Msacat <- factor(Hh_df$Msacat)
Hh_df$Msasize <- factor(Hh_df$Msasize)
Hh_df$Rail <- factor(Hh_df$Rail)
Hh_df$Urbrur <- factor(Hh_df$Urbrur)
#Add large household size variable (useful in connection with life cycle variable)
Hh_df$LargeHh <- Hh_df$Hhsize * 0
Hh_df$LargeHh[Hh_df$Hhsize > 3] <- 1
Hh_df$LargeHh <- factor(Hh_df$LargeHh, labels = c("Small", "Large"))
#Clean up workspace
rm(Dt_df, Per_df, Dvmt_Hh, HhWkTourVmt_, IsVehicle_, NumVeh_Dt, WasNotPsgr_,
   calcTourVmtProp, toProperName, toVecFrom1DAry, BusEqRevMiPC_,
   IsIdentifiedUZA_, Transit2001_df)


#==========================
#SAVE THE HOUSEHOLD DATASET
#==========================
#' Household travel from the 2001 National Household Travel Survey
#'
#' A household dataset containing the data used for estimating VisionEval
#' travel models derived from the 2001 National Household Travel Survey, USDOT
#' Highway Statistics reports, and the National Transit Database.
#'
#' @format A data frame with 60521 rows and 88 variables
#' \describe{
#'   \item{Houseid}{Unique household ID}
#'   \item{Census_d}{Household Census division}
#'   \item{Census_r}{Household Census region}
#'   \item{Drvrcnt}{Count of drivers in household}
#'   \item{Expflhhn}{HH Weight-100 percent completed - NATL}
#'   \item{Expfllhh}{HH Weight-100 percent completed}
#'   \item{Flgfincm}{Incomes of all HH members included}
#'   \item{Hbhresdn}{Housing units per sq mile - Block group}
#'   \item{Hbhur}{Urban / Rural indicator - Block group}
#'   \item{Hbppopdn}{Population per sq mile - Block group}
#'   \item{Hhc_msa}{MSA / CMSA code for HH}
#'   \item{Hhfaminc}{Total HH income last 12 months (category)}
#'   \item{Hhincttl}{Total income all HH members (category)}
#'   \item{Hhnumbik}{Number of full size bicycles in HH}
#'   \item{Hhr_age}{Respondent age}
#'   \item{Hhr_drvr}{Driver status of HH respondent}
#'   \item{Hhr_race}{Race of HH respondent}
#'   \item{Hhr_sex}{Gender of HH respondent}
#'   \item{Hhsize}{Count of HH members}
#'   \item{Hhvehcnt}{Count of vehicles in HH}
#'   \item{Hometype}{Type of housing unit}
#'   \item{Hteempdn}{Workers per square mile living in Tract}
#'   \item{Hthresdn}{Housing units per sq mile - Tract level}
#'   \item{Hthur}{Urban / Rural indicator - Tract level}
#'   \item{Htppopdn}{Population per sq mile - Tract level}
#'   \item{Lif_cyc}{HH Life Cycle}
#'   \item{Msacat}{MSA category}
#'   \item{Msasize}{MSA size}
#'   \item{Rail}{Rail (subway) category}
#'   \item{Ratio16v}{Ratio - HH members (16+) to vehicles}
#'   \item{Urban}{Household in urbanized area}
#'   \item{Urbrur}{Household in urban/rural area}
#'   \item{Wrkcount}{Count of HH members with jobs}
#'   \item{Cnttdhh}{Sum of all travel period person trips}
#'   \item{Age0to14}{Number of persons age 0 to 14 in household}
#'   \item{Age15to19}{Number of persons age 15 to 19 in household}
#'   \item{Age20to29}{Number of persons age 20 to 29 in household}
#'   \item{Age30to54}{Number of persons age 30 to 54 in household}
#'   \item{Age55to64}{Number of persons age 55 to 64 in household}
#'   \item{Age65Plus}{Number of persons age 65 or older in household}
#'   \item{Income}{Household income}
#'   \item{IncGrp}{Household income group}
#'   \item{UrbanDev}{Flag identifying whether household lived in an 'Urban' area}
#'   \item{TownDev}{Flag identifying whether household lived in a 'Town' area}
#'   \item{SuburbanDev}{Flag identifying whether household lived in a 'Suburban' area}
#'   \item{RuralDev}{Flag identifying whether household lived in a 'Rural' area}
#'   \item{SecondCityDev}{Flag identifying whether household lived in a 'Second City' area}
#'   \item{NumAuto}{Number of automobiles owned}
#'   \item{NumLightTruck}{Number of light trucks owned}
#'   \item{NumVeh}{Number of vehicles (autos and light trucks) owned}
#'   \item{VehPerDrvAgePop}{Ratio of household vehicles and driving-age persons}
#'   \item{Totmiles}{Total annual household miles calculated from best estimate of annual vehicle miles 'BESTMILE'}
#'   \item{AveMpg}{Average MPG of household vehicles}
#'   \item{Gscost}{Average cost of gasoline per gallon}
#'   \item{Gscostmile}{Average cost of gasoline per mile of household vehicle travel}
#'   \item{Gscostmile2}{Average cost of gasoline per mile using EIA derived miles per equivalent-gallon}
#'   \item{Dvmt}{Household vehicle miles of travel on survey day}
#'   \item{PropSovDvmtLE2}{Proportion of DVMT in single-occupant vehicle tours less than or equal to 2 miles}
#'   \item{PropSovDvmtLE5}{Proportion of DVMT in single-occupant vehicle tours less than or equal to 5 miles}
#'   \item{PropSovDvmtLE10}{Proportion of DVMT in single-occupant vehicle tours less than or equal to 10 miles}
#'   \item{PropSovDvmtLE15}{Proportion of DVMT in single-occupant vehicle tours less than or equal to 15 miles}
#'   \item{PropSovDvmtLE20}{Proportion of DVMT in single-occupant vehicle tours less than or equal to 20 miles}
#'   \item{PropWkDvmt}{Proportion of DVMT in work tours}
#'   \item{ZeroVehPassDvmt}{DVMT as passenger for zero-vehicle households}
#'   \item{WalkBikeMiles}{Miles traveled by walking or bicycling}
#'   \item{ZeroDvmt}{Flag identifying whether household had no DVMT on survey day}
#'   \item{Numcommdrvr}{Number of commercial drivers in household}
#'   \item{Nbiketrp}{Number of bike trips on travel survey day}
#'   \item{Nwalktrp}{Number of walk trips on travel survey day}
#'   \item{Usepubtr}{Whether any household members used public transportation on travel survey day}
#'   \item{Numwrkdrvr}{Number of persons whose work requires driving a vehicle}
#'   \item{RoadMiPC}{Ratio of urbanized area road miles to thousands of persons}
#'   \item{FwyLnMiPC}{Ratio of urbanized area freeway lane miles to thousands of persons}
#'   \item{MsaPopDen}{Urbanized area population density in persons per square mile}
#'   \item{BusEqRevMiPC}{Annual bus equivalent transit revenue miles per capita}
#'   \item{LargeHh}{Flag identifying whether household size is large}
#' }
#' @source 2001 National Household Travel Survey, Highway Statistics (2001),
#' National Transit Database (2002), and Make2001NHTSDataset.R script.
"Hh_df"
devtools::use_data(Hh_df, overwrite = TRUE)
rm(Hh_df)


#========================
#SAVE THE VEHICLE DATASET
#========================
#' Vehicle dataset from the 2001 National Household Travel Survey
#'
#' A vehicle dataset containing the data used for estimating VisionEval
#' vehicle models derived from the 2001 National Household Travel Survey.
#'
#' @format A data frame with 112697 rows and 10 variables
#' \describe{
#'   \item{Houseid}{Unique household ID}
#'   \item{Vehid}{Unique ID for vehicle in household}
#'   \item{Bestmile}{Best estimate of annual miles}
#'   \item{Eiadmpg}{EIA derived miles per equivalent-gallon}
#'   \item{Gscost}{Estimated Fuel cost (cents per gallon)}
#'   \item{Vehtype}{Type of vehicle}
#'   \item{Vehyear}{Vehicle year - derived}
#'   \item{Vehmiles}{Miles vehicle driven last 12 months}
#'   \item{Type}{Auto or light truck}
#'   \item{Gscostmile2}{Estimated gas cost per mile of travel}
#' }
#' @source 2001 National Household Travel Survey and Make2001NHTSDataset.R script.
"Veh_df"
devtools::use_data(Veh_df, overwrite = TRUE)
rm(Veh_df)

