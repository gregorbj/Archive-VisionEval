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

#Extract NHTS household data
#---------------------------
Hh_df <- read.csv(unzip("inst/extdata/HHPUB.zip"))
names(Hh_df) <- toProperName(names(Hh_df))
Hh_df$Houseid <- as.character(Hh_df$Houseid)
FieldsToKeep_ <-
  c("Houseid", "Age_p1", "Age_p2", "Age_p3", "Age_p4", "Age_p5", "Age_p6",
    "Age_p7", "Age_p8", "Age_p9", "Age_p10", "Age_p11", "Age_p12", "Age_p13",
    "Age_p14", "Census_d", "Census_r", "Drvrcnt", "Expflhhn", "Expfllhh",
    "Flgfincm", "Hbhresdn", "Hbhur", "Hbppopdn", "Hhc_msa", "Hhfaminc",
    "Hhincttl", "Hhnumbik", "Hhr_age", "Hhr_drvr", "Hhr_race", "Hhr_sex",
    "Hhsize", "Hhvehcnt", "Hometype", "Hteempdn", "Hthresdn", "Hthur",
    "Htppopdn", "Lif_cyc", "Msacat", "Msasize", "Numadlt", "Rail", "Ratio16v",
    "Ratio16w", "Ratiowv", "Smplarea", "Smplfirm", "Urban", "Urbrur",
    "Wrkcount", "Cnttdhh")
Hh_df <- Hh_df[, FieldsToKeep_]
#Keep on only household records 100% recording of travel day trips
AllTripsHh_ <- Hh_df$Houseid[!is.na(Hh_df$Expfllhh)]
Hh_df <- Hh_df[Hh_df$Houseid %in% AllTripsHh_,]
rm(FieldsToKeep_)

#Extract NHTS vehicle data
#-------------------------
Veh_df <- read.csv(unzip("inst/extdata/VEHPUB.zip"))
names(Veh_df) <- toProperName(names(Veh_df))
Veh_df$Houseid <- as.character(Veh_df$Houseid)
Veh_df$Vehid <- as.character(Veh_df$Vehid)
FieldsToKeep_ <-
  c("Houseid", "Vehid", "Bestmile", "Best_edt", "Best_flg", "Best_out",
    "Btucost", "Btutcost", "Btuyear",  "Eiadmpg", "Epatmpg", "Expflhhn",
    "Expfllhh", "Fueltype", "Gscost", "Gstotcst", "Gsyrgal", "Hhsize",
    "Hhvehcnt", "Ownunit", "Vehtype", "Vehyear", "Vehmiles" )
Veh_df <- Veh_df[,FieldsToKeep_]
#Keep only records for households with 100% recording of travel day trips
Veh_df <- Veh_df[Veh_df$Houseid %in% AllTripsHh_,]
rm(FieldsToKeep_)

#Extract NHTS person data
#------------------------
Per_df <- read.csv(unzip("inst/extdata/PERPUB.zip"))
names(Per_df) <- toProperName(names(Per_df))
Per_df$Houseid <- as.character(Per_df$Houseid)
Per_df$Personid <- as.character(Per_df$Personid)
FieldsToKeep_ <-
  c("Houseid", "Personid", "Commdrvr", "Nbiketrp", "Nwalktrp", "Usepubtr",
    "Wrkdrive", "Wrktrans", "Dtgas")
Per_df <- Per_df[,FieldsToKeep_]
# Keep only records for households with 100% recording of travel day trips
Per_df <- Per_df[Per_df$Houseid %in% AllTripsHh_,]
rm(FieldsToKeep_)

#Extract NHTS daily trip data
#----------------------------
Dt_df <- read.csv(unzip("inst/extdata/DAYPUB.zip"))
names(Dt_df) <- toProperName(names(Dt_df))
Dt_df$Houseid <- as.character(Dt_df$Houseid)
Dt_df$Vehid <- as.character(Dt_df$Vehid)
Dt_df$Personid <- as.character(Dt_df$Personid)
Dt_df$Tdcaseid <- as.character(Dt_df$Tdcaseid)
FieldsToKeep_ <-
  c("Houseid", "Vehid", "Personid", "Tdcaseid", "Tdtrpnum", "Trpnumsq",
    "Endtime", "Numontrp", "Hh_ontd", "Trphhacc", "Trphhveh", "Trpmiles",
    "Trptrans", "Trvl_min", "Psgr_flg", "Whytrp1s", "Awayhome", "Whyfrom",
    "Whyto", "Whytrp01")
Dt_df <- Dt_df[,FieldsToKeep_]
# Keep only records for households with 100% recording of travel day trips
Dt_df <- Dt_df[Dt_df$Houseid %in% AllTripsHh_,]


#===============================
#CALCULATE HOUSEHOLD PERSON AGES
#===============================

#Calculate the number of persons by age group and add summary to household data
#------------------------------------------------------------------------------
AgeFields_ <-
  c("Age_p1", "Age_p2", "Age_p3", "Age_p4", "Age_p5", "Age_p6", "Age_p7",
    "Age_p8", "Age_p9", "Age_p10", "Age_p11", "Age_p12", "Age_p13", "Age_p14" )
# Set up person age categories
AgeBreaks <- c(0, 14, 19, 29, 54, 64, max(Hh_df[,AgeFields_]))
# Tabulate persons per household by age category
Ages_HhAg <- t(apply( Hh_df[,AgeFields_], 1, function(x) {
  x[x < 0] <- NA
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
rm( AgeFields_, AgeBreaks, Ages_HhAg )


#==========================
#CALCULATE HOUSEHOLD TRAVEL
#==========================

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
Dvmt_Hh <- tapply(Dt_df$Trpmiles[UseRecord_], Dt_df$Houseid[UseRecord_], sum)
Hh_df$Dvmt <- Dvmt_Hh[match(Hh_df$Houseid, names(Dvmt_Hh))]

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
    tapply(TourVmt_[TourVmt_ <= TourLen & IsSovTour_],
           TourHhId_[TourVmt_ <= TourLen & IsSovTour_], sum)
  SovTour_Hh <- numeric(nrow(Hh_df))
  names(SovTour_Hh) <- Hh_df$Houseid
  SovTour_Hh[names(SovTour_)] <- SovTour_
  NaHhNames_ <- unique(substr(names(IsNaTourVmt_)[IsNaTourVmt_], 1, 9))
  SovTour_Hh[NaHhNames_] <- NA
  SovTour_Hh / Hh_df$Dvmt
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
  tapply(Dt_df$Trpmiles[UseRecord_], Dt_df$Houseid[UseRecord_], sum)
Hh_df$ZeroVehPassDvmt <-
  ZeroVehPassDvmt_Hh[match(Hh_df$Houseid, names(ZeroVehPassDvmt_Hh))]
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
#After the previous step to attach DVMT to the household records, 8872 of the
#60521 household records have NA values for DVMT. 3950 of the 8872 households
#have no records in the day travel dataset. Since all of the households in this
#household dataset are "100 percent households" (all household adults were
#interviewed) then these might be households that took no trips on the travel
#day. 55% of these have only elderly persons in the household. 61% have only one
#person in the household and another 30% have only two persons. Based on these
#consideration, it is assumed that the DVMT for these 3950 households is in fact
#0.4622 of the remaining 4922 households that have NA values have all person
#trips listed as passenger or as traveling on a non-personal mode. The DVMT for
#these households is also identified as 0. That leaves 300 households having a
#NA value for DVMT.

#Identify the households having NA values for Dvmt
#-------------------------------------------------
NaHh_ <- Hh_df$Houseid[is.na(Hh_df$Dvmt)]
# There are 8872 of them
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
#Notes:
#Zero DVMT households are important for model estimation because:
#- They affect the overall mean
#- They tend to have significantly different characteristics than other households
#- Their travel does not fit into a continuous travel distribution when
#  transformed with a power function (see below)
Hh_df$ZeroDvmt <- "N"
Hh_df$ZeroDvmt[Hh_df$Dvmt == 0] <- "Y"
Hh_df$ZeroDvmt[is.na(Hh_df$Dvmt)] <- NA
Hh_df$ZeroDvmt <- as.factor(Hh_df$ZeroDvmt)
table(Hh_df$ZeroDvmt, Hh_df$Urban)

#Create dummy variables for land development type
#------------------------------------------------
Hh_df$Urban <- (Hh_df$Hthur == "U") * 1
Hh_df$Town <- (Hh_df$Hthur == "T") * 1
Hh_df$Suburban <- (Hh_df$Hthur == "S") * 1
Hh_df$Rural <- (Hh_df$Hthur == "R") * 1
Hh_df$City <- (Hh_df$Hthur == "C") * 1


#====================
#PROCESS VEHICLE DATA
#====================

#Correct auto ownership variable
#-------------------------------
# The NHTS datasets miscodes the Ratio16v variable (ratio of persons over 16 to
# vehicles) for households having zero vehicles as 0 (it should be infinite).
# The fouls up the model estimation. A variable of vehicles per persons of
# driving age (reciprocal of Ratio16v) is created and the zero vehicle
# households for this variable are properly coded.
VehPerDrvAgePop_ <- 1 / Hh_df$Ratio16v
VehPerDrvAgePop_[Hh_df$Hhvehcnt == 0] <- 0
VehPerDrvAgePop_[is.infinite(VehPerDrvAgePop_)] <- NA
Hh_df$VehPerDrvAgePop <- VehPerDrvAgePop_
rm(VehPerDrvAgePop_)

#Add gas cost variable from vehicle dataset
#------------------------------------------
#The average gas cost per vehicle mile (Gscostmile) is computed for each
#household that has data for this variable. This is used in the household DVMT
#model. About a third of the households have sufficient information to permit
#gas costs to be calculated. Gscostmile is calculated both as a simple average
#of the values for each vehicle and as an mileage weighted average.

#Make a dataset of the necessary variables
FieldsToKeep_ <- c("Houseid", "Vehid", "Vehtype", "Eiadmpg", "Gscost", "Bestmile")
Veh_df <- Veh_df[, FieldsToKeep_]
#Convert all negative values to NA values
Veh_df[Veh_df < 0] <- NA
#Classify vehicles as Passenger and LightTruck
Veh_df$Type <- rep(NA, nrow(Veh_df))
Veh_df$Type[Veh_df$Vehtype == 1] <- "Auto"
Veh_df$Type[Veh_df$Vehtype %in% c(2, 3, 4)] <- "LightTruck"
#Keep only the vehicles that are autos or light trucks
Veh_df <- Veh_df[Veh_df$Type %in% c("Auto", "LightTruck"),]
#Calculate household average Gscostmile weighted by vehicle mileage
Veh_ls <- split(Veh_df, Veh_df$Houseid)
HhAveMpg_Hh <- unlist(lapply(Veh_ls, function(x) {
  Mpg_ <- x$Eiadmpg
  Miles_ <- x$Bestmile
  Mpg_[is.na(Mpg_)] <- 0
  Miles_[is.na(Miles_)] <- 0
  Miles_[Mpg_ == 0] <- 0
  Mpg_[Miles_ == 0] <- 0
  sum(Mpg_ * Miles_) / sum(Miles_)
}))
Hh_df$AveMpg <- HhAveMpg_Hh[match(Hh_df$Houseid, names(HhAveMpg_Hh))]
Gscost_Hh <-
  tapply(Veh_df$Gscost, Veh_df$Houseid, function(x) mean(x, na.rm=TRUE))
Hh_df$Gscost <- Gscost_Hh[match(Hh_df$Houseid, names(Gscost_Hh))]
Hh_df$Gscostmile <- Hh_df$Gscost / Hh_df$AveMpg
#Calculate the gas cost per mile (Gscostmile2) for each vehicle (cents per mile)
Veh_df$Gscostmile2 <- Veh_df$Gscost / Veh_df$Eiadmpg
# Calculate household average Gscostmile and average of household vehicle Gscostmile
# 20,488 households have averages thus calculated
Gscostmile2_Hh <-
  tapply(Veh_df$Gscostmile2, Veh_df$Houseid, function(x) mean(x, na.rm=TRUE))
Hh_df$Gscostmile2 <- Gscostmile2_Hh[match(Hh_df$Houseid, names(Gscostmile2_Hh))]
rm(FieldsToKeep_, Gscostmile2_Hh, Veh_ls, HhAveMpg_Hh, Gscost_Hh)

#Add total annual vehicle mileage data to household dataset
#----------------------------------------------------------
#Notes:
#Best annual mileage estimates were prepared for about 20,000 of the households
HhBestmile_ <-
  unlist(tapply(Veh_df$Bestmile, Veh_df$Houseid, function(x) {
    if(all(!is.na(x))) sum(x)}))
Hh_df$Totmiles <- HhBestmile_[match(Hh_df$Houseid, names(HhBestmile_))]


#===================
#PROCESS PERSON DATA
#===================

#Replace person values with NA where appropriate
Per_df[Per_df < 0] <- NA
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


#=======================================
#ADD THE HIGHWAY AND TRANSIT SUPPLY DATA
#=======================================

#Add the highway supply data
#---------------------------
#Change Hhc_msa to character variable to link up highway data properly
Hh_df$Hhc_msa <- as.character(Hh_df$Hhc_msa)
#Load data file
Hwy2001_df <-
  read.csv("inst/extdata/HighwayStatistics2.csv",
           colClasses = c(rep("character", 2), rep("numeric", 8)))
#Sum quantities by Msa Code
RoadMi_Mc <- tapply(Hwy2001_df$RoadMiles, Hwy2001_df$MsaCode, sum)
Pop_Mc <- tapply(Hwy2001_df$Population, Hwy2001_df$MsaCode, sum)
FwyLnMi_Mc <- tapply(Hwy2001_df$FwyLaneMi, Hwy2001_df$MsaCode, sum)
Area_Mc <- tapply(Hwy2001_df$Area, Hwy2001_df$MsaCode, sum)
# Calculate per capita quantities (per 1000s population)
RoadMiCap_Mc <- RoadMi_Mc / Pop_Mc
FwyLnMiCap_Mc <- FwyLnMi_Mc / Pop_Mc
# Calculate urbanized area density
MsaPopdn_Mc <- 1000 * Pop_Mc / Area_Mc
# Add to household data set
Hh_df$Roadmicap <- RoadMiCap_Mc[Hh_df$Hhc_msa]
Hh_df$Fwylnmicap <- FwyLnMiCap_Mc[Hh_df$Hhc_msa]
Hh_df$MsaPopdn <- MsaPopdn_Mc[Hh_df$Hhc_msa]
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
Hh_df$BusEqRevMiPC <- BusEqRevMiPC_[Hh_df$Hhc_msa]
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
Hh_df$Hbhresdn[Hh_df$Hbhresdn < 0] <- NA
Hh_df$Hbhur[Hh_df$Hbhur == "-9"] <- NA
Hh_df$Hbppopdn[Hh_df$Hbppopdn < 0] <- NA
#Make a factor variable for family income
Hh_df$Hhfamincc <- Hh_df$Hhfaminc
Hh_df$Hhfamincc[Hh_df$Hhfaminc < 0] <- NA
Hh_df$Hhfamincc <- factor(Hh_df$Hhfamincc)
#Make a ratio variable for family income
Hh_df$Hhfaminc[Hh_df$Hhfaminc < 0] <- NA
MidPtValues_ <-
  c(2500, 7500, 12500, 17500, 22500, 27500, 32500, 37500, 42500, 47500, 52500,
    57500, 62500, 67500, 72500, 77500, 90000, 120000)
Hh_df$Hhfaminc <- MidPtValues_[Hh_df$Hhfaminc]
#Make a factor variable for total household income
Hh_df$Hhincttlc <- Hh_df$Hhincttl
Hh_df$Hhincttlc[Hh_df$Hhincttl < 0] <- NA
Hh_df$Hhincttlc <- factor(Hh_df$Hhincttlc)
#Make a ratio variable for total household income
Hh_df$Hhincttl[ Hh_df$Hhincttl < 0 ] <- NA
MidPtValues_ <-
  c(2500, 7500, 12500, 17500, 22500, 27500, 32500, 37500, 42500, 47500, 52500,
    57500, 62500, 67500, 72500, 77500, 90000, 120000)
Hh_df$Hhincttl <- MidPtValues_[Hh_df$Hhincttl]
Hh_df$Hhr_drvr <- factor(Hh_df$Hhr_drvr, labels = c("Yes", "No"))
Hh_df$Hhr_race <- factor( Hh_df$Hhr_race )
Hh_df$Hhr_sex <- factor( Hh_df$Hhr_sex, labels = c( "Male", "Female" ) )
Hh_df$Hometype[Hh_df$Hometype < 0] <- NA
Hh_df$Hometype <-
  factor(Hh_df$Hometype,
         labels = c("Single Family", "Duplex", "Attached", "Multi-family",
                    "Mobile Home", "Dorm", "Other"))
Hh_df$Hteempdn[Hh_df$Hteempdn < 0] <- NA
Hh_df$Hthresdn[Hh_df$Hthresdn < 0] <- NA
Hh_df$Hthur[Hh_df$Hthur == "-9"] <- NA
Hh_df$Htppopdn[Hh_df$Htppopdn < 0] <- NA
Hh_df$Lif_cyc[Hh_df$Lif_cyc < 0] <- NA
Hh_df$Lif_cyc <- factor(Hh_df$Lif_cyc)
Hh_df$Msacat <- factor(Hh_df$Msacat)
Hh_df$Msasize <- factor(Hh_df$Msasize)
Hh_df$Rail <- factor(Hh_df$Rail)
Hh_df$Smplarea <- factor(Hh_df$Smplarea)
Hh_df$Smplfirm <- factor(Hh_df$Smplfirm)
Hh_df$Urbrur <- factor(Hh_df$Urbrur)
#Add large household size variable (useful in connection with life cycle variable)
Hh_df$Largehh <- Hh_df$Hhsize * 0
Hh_df$Largehh[Hh_df$Hhsize > 3] <- 1
Hh_df$Largehh <- factor(Hh_df$Largehh, labels = c("Small", "Large"))
#Remove unneeded variables
VarsToRm_ <-
  c("Age_p1", "Age_p2", "Age_p3", "Age_p4", "Age_p5", "Age_p6", "Age_p7",
    "Age_p8", "Age_p9", "Age_p10", "Age_p11", "Age_p12", "Age_p13", "Age_p14")
for (var in VarsToRm_) Hh_df[[var]] <- NULL
#Clean up workspace
rm(Dt_df, Per_df, Veh_df, AllTripsHh_, Dvmt_Hh, HhBestmile_, HhWkTourVmt_,
   IsVehicle_, MidPtValues_, NumVeh_Dt, var, VarsToRm_, WasNotPsgr_,
   calcTourVmtProp, toProperName)


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
#'   \item{Hhfaminc}{Total HH income last 12 months}
#'   \item{Hhincttl}{Total income all HH members}
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
#'   \item{Numadlt}{Number of adults in HH}
#'   \item{Rail}{Rail (subway) category}
#'   \item{Ratio16v}{Ratio - HH members (16+) to vehicles}
#'   \item{Ratio16w}{Ratio - HH adults (16+) to workers}
#'   \item{Ratiowv}{Ratio of HH workers to vehicles}
#'   \item{Smplarea}{Add-on area where HH resides}
#'   \item{Smplfirm}{Firm collecting the data}
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
#'   \item{Town}{Flag identifying whether household lived in a 'Town' area}
#'   \item{Suburban}{Flag identifying whether household lived in a 'Suburban' area}
#'   \item{Rural}{Flag identifying whether household lived in a 'Rural' area}
#'   \item{City}{Flag identifying whether household lived in a 'City' area}
#'   \item{VehPerDrvAgePop}{Ratio of household vehicles and driving-age persons}
#'   \item{AveMpg}{Average MPG of household vehicles}
#'   \item{Gscost}{Average cost of gasoline per gallon}
#'   \item{Gscostmile}{Average cost of gasoline per mile of household vehicle travel}
#'   \item{Gscostmile2}{Average cost of gasoline per mile using EIA derived miles per equivalent-gallon}
#'   \item{Totmiles}{Total annual household miles calculated from best estimate of annual vehicle miles 'BESTMILE'}
#'   \item{Numcommdrvr}{Number of commercial drivers in household}
#'   \item{Nbiketrp}{Number of bike trips on travel survey day}
#'   \item{Nwalktrp}{Number of walk trips on travel survey day}
#'   \item{Usepubtr}{Whether any household members used public transportation on travel survey day}
#'   \item{Numwrkdrvr}{Number of persons whose work requires driving a vehicle}
#'   \item{Roadmicap}{Ratio of urbanized area road miles to thousands of persons}
#'   \item{Fwylnmicap}{Ratio of urbanized area freeway lane miles to thousands of persons}
#'   \item{MsaPopdn}{Urbanized area population density in persons per square mile}
#'   \item{BusEqRevMiPC}{Annual bus equivalent transit revenue miles per capita}
#'   \item{Hhfamincc}{Household family income category variable}
#'   \item{Hhincttlc}{Total household income category variable}
#'   \item{Largehh}{Flag identifying whether household size is large}
#' }
#' @source 2001 National Household Travel Survey, Highway Statistics (2001),
#' National Transit Database (2002), and Make2001NHTSDataset.R script.
"Hh_df"
devtools::use_data(Hh_df, overwrite = TRUE)
rm(Hh_df)

