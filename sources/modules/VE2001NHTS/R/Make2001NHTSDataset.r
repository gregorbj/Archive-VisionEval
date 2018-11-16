#=====================
#Make2001NHTSDataset.R
#=====================
#This module creates a data frame of data from the publically available data
#from the 2001 National Household Travel Survey (NHTS) augmented with data on
#metropolitan area freeway supply and transit supply. The package produces a
#data frame of values by household.

#=======
#PURPOSE
#=======

#This script processes 2001 NHTS text files to create the household travel
#dataset to be used in model estimation. Data on freeway lane miles and
#bus equivalent transit revenue miles are added. A household dataframe (Hh_df)
#containing travel and other relevant data for each survey household.
# library(visioneval)


#==================
#LOAD NHTS DATASETS
#==================

#Define functions
#----------------
#Define function to convert name to proper name (only first letter capitalized)
toProperName <- function(X){
  EndX <- nchar(X)
  paste(toupper(substring(X, 1, 1)), tolower(substring(X, 2, EndX)), sep="")
}

#Define function to convert 1-dimensional array into a named vector
toVecFrom1DAry <- function(X_ar){
  X_ <- as.vector(X_ar)
  names(X_) <- names(X_ar)
  X_
}

#Define function to convert numbers to strings and add leading zeros if
#necessary so that every one has 2 characters (e.g. '1' becomes 01)
doPadNum <- function(Num_) {
  Num_ <- as.character(Num_)
  Num_[nchar(Num_) < 2] <- paste0(0, Num_[nchar(Num_) < 2])
  Num_
}

#Define function to retrieve NHTS dataset from repository, unzip, and read as
#data frame
#----------------------------------------------------------------------------
#' Retrieve data in zip archive from repository
#'
#' \code{getZipDatasetFromRepo} retrieve a zip archive containing a csv file
#' from a repository, unzip, and read as data frame
#'
#' This function retrieves a zip archive containing a csv file from a
#' repository, unzips it, and reads it in as data frame which it returns.
#'
#' @param Repo A string that is the url where the zip archive is located.
#' @param DatasetName The name of the dataset.
#' @return A data frame containing the data in the zip archive.
#' @import utils
getZipDatasetFromRepo <- function(Repo, DatasetName) {
  ZipArchiveFileName <- paste0(DatasetName, ".zip")
  CsvFileName <- paste0(DatasetName, ".csv")
  download.file(file.path(Repo, ZipArchiveFileName), ZipArchiveFileName)
  Data_df <- read.csv(unzip(ZipArchiveFileName), as.is = TRUE)
  file.remove(ZipArchiveFileName, CsvFileName)
  Data_df
}

#Identify NHTS data directory
#----------------------------
#Compressed NHTS 2001 public use datasets are available in the following GitHub
#repository. This may change in the future.
Nhts2001Repo <-
  "https://raw.githubusercontent.com/gregorbj/NHTS2001/master/data"

#Load NHTS household data
#------------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Hh_df.rda")) {
  Hh_df <- getZipDatasetFromRepo(Nhts2001Repo, "HHPUB")
  Keep_ <- c("HOUSEID", "AGE_P1", "AGE_P2", "AGE_P3", "AGE_P4", "AGE_P5",
             "AGE_P6", "AGE_P7", "AGE_P8", "AGE_P9", "AGE_P10", "AGE_P11",
             "AGE_P12", "AGE_P13", "AGE_P14", "CENSUS_D", "CENSUS_R", "DRVRCNT",
             "DRV_P1", "DRV_P2", "DRV_P3", "DRV_P4", "DRV_P5", "DRV_P6",
             "DRV_P7", "DRV_P8", "DRV_P9", "DRV_P10", "DRV_P11", "DRV_P12",
             "DRV_P13", "DRV_P14", "EXPFLHHN", "EXPFLLHH", "FLGFINCM",
             "HBHRESDN", "HBHUR", "HBPPOPDN", "HHC_MSA", "HHFAMINC", "HHINCTTL",
             "HHNUMBIK", "HHR_AGE", "HHR_DRVR", "HHR_RACE", "HHR_SEX", "HHSIZE",
             "HHVEHCNT", "HOMETYPE", "HTEEMPDN", "HTHRESDN", "HTHUR",
             "HTPPOPDN", "LIF_CYC", "MSAPOP", "MSACAT", "MSASIZE", "RAIL",
             "RATIO16V", "URBAN", "URBRUR", "WRKCOUNT", "WKR_P1", "WKR_P2",
             "WKR_P3", "WKR_P4", "WKR_P5", "WKR_P6", "WKR_P7", "WKR_P8",
             "WKR_P9", "WKR_P10", "WKR_P11", "WKR_P12", "WKR_P13", "WKR_P14",
             "CNTTDHH")
  Hh_df <- Hh_df[, Keep_]
  save(Hh_df, file = "data-raw/Hh_df.rda", compress = TRUE)
} else {
  #Otherwise read in from 'data-raw' directory
  load("data-raw/Hh_df.rda")
}
#Identify households that have expansion factor
AllTripsHh_ <- Hh_df$HOUSEID[!is.na(Hh_df$EXPFLLHH)]
#Limit households to those that have expansion factor
Hh_df <- Hh_df[Hh_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Hh_df) <- toProperName(names(Hh_df))
#Convert negative values to NA
Hh_df[Hh_df < 0] <- NA

#Load NHTS vehicle data
#----------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Veh_df.rda")) {
  Veh_df <- getZipDatasetFromRepo(Nhts2001Repo, "VEHPUB")
  Keep_ <-
    c("HOUSEID", "VEHID", "BESTMILE", "EIADMPG", "GSCOST", "VEHTYPE", "VEHYEAR",
      "VEHMILES" )
  Veh_df <- Veh_df[, Keep_]
  save(Veh_df, file = "data-raw/Veh_df.rda", compress = TRUE)
} else {
  load("data-raw/Veh_df.rda")
}
#Only include vehicle data for households that have expansion factor
Veh_df <- Veh_df[Veh_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Veh_df) <- toProperName(names(Veh_df))
#Convert Vehid to character
Veh_df$Vehid <- as.character(Veh_df$Vehid)
#Convert negative values to NA
Veh_df[Veh_df < 0] <- NA

#Load NHTS person data
#---------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Per_df.rda")) {
  Per_df <- getZipDatasetFromRepo(Nhts2001Repo, "PERPUB")
  Keep_ <-
    c("HOUSEID", "PERSONID", "COMMDRVR", "NBIKETRP", "NWALKTRP", "USEPUBTR",
      "WRKDRIVE", "WRKTRANS", "WORKER", "DTGAS", "DISTTOWK", "DRIVER", "R_AGE",
      "R_SEX")
  Per_df <- Per_df[, Keep_]
  save(Per_df, file = "data-raw/Per_df.rda", compress = TRUE)
} else {
  load("data-raw/Per_df.rda")
}
#Only include person data for households that have expansion factor
Per_df <- Per_df[Per_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Per_df) <- toProperName(names(Per_df))
#Create a unique person ID
Per_df$Personid <- paste0(Per_df$Houseid, doPadNum(Per_df$Personid))
#Convert negative values to NA
Per_df[Per_df < 0] <- NA

#Load NHTS daily trip data
#-------------------------
#Download data from repository and process if it has not already been done
if (!file.exists("data-raw/Dt_df.rda")) {
  Dt_df <- getZipDatasetFromRepo(Nhts2001Repo, "DAYPUB")
  Keep_ <-
    c("HOUSEID", "TDCASEID", "VEHID", "VEHUSED", "TRPHHVEH","PERSONID",
      "NUMONTRP", "TRPTRANS", "TRPMILES", "TRVL_MIN", "DWELTIME", "PSGR_FLG",
      "WHYFROM", "WHYTO", "VEHTYPE")
  Dt_df <- Dt_df[, Keep_]
  save(Dt_df, file = "data-raw/Dt_df.rda", compress = TRUE)
} else {
  load("data-raw/Dt_df.rda")
}
#Only include trip data for households that have expansion factor
Dt_df <- Dt_df[Dt_df$HOUSEID %in% AllTripsHh_,]
#Convert field names to proper names
names(Dt_df) <- toProperName(names(Dt_df))
#Convert Vehid to character
Dt_df$Vehid <- as.character(Dt_df$Vehid)
#Create a unique person ID
Dt_df$Personid <- paste0(Dt_df$Houseid, doPadNum(Dt_df$Personid))
#Convert negative values to NA
Dt_df[Dt_df < 0] <- NA


#=======================================
#LOAD METROPOLITAN ROAD AND TRANSIT DATA
#=======================================

#Describe specifications for road supply data file
#-------------------------------------------------
RoadInp_ls <- items(
  item(
    NAME = items(
      "MsaCode",
      "UrbanizedArea"),
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "RoadMiles",
      "TotalDvmt",
      "Population",
      "Area",
      "Density",
      "RoadMileCap",
      "FwyMiles",
      "FwyLaneMi"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in road supply data
#------------------------
Hwy2001_df <-
  processEstimationInputs(
    RoadInp_ls,
    "highway_statistics.csv",
    "Make2001NHTSDataset")
rm(RoadInp_ls)

#Describe specifications for transit supply data file
#----------------------------------------------------
TransitInp_ls <- items(
  item(
    NAME = items(
      "UZAName",
      "MSACode"),
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "BusEqRevMi",
      "UZAPop",
      "BusEqRevMiPC"),
    TYPE = "double",
    PROHIBIT = "< 0",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in transit supply data
#---------------------------
Transit2001_df <-
  processEstimationInputs(
    TransitInp_ls,
    "uza_bus_eq_rev_mi.csv",
    "Make2001NHTSDataset")
rm(TransitInp_ls)


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
# Create a matrix of the age fields
Ages_HhPr <- as.matrix(Hh_df[,AgeFields_])
# Tabulate persons per household by age category
Ages_HhAg <- t(apply(Ages_HhPr, 1, function(x) {
  table(cut(x, AgeBreaks, include.lowest=TRUE, right=FALSE))
}))
# Assign tabulations to age category variables
Hh_df$Age0to14  <- Ages_HhAg[,1]
Hh_df$Age15to19 <- Ages_HhAg[,2]
Hh_df$Age20to29 <- Ages_HhAg[,3]
Hh_df$Age30to54 <- Ages_HhAg[,4]
Hh_df$Age55to64 <- Ages_HhAg[,5]
Hh_df$Age65Plus <- Ages_HhAg[,6]

#Calculate the number of drivers by age group and add summary to household data
#------------------------------------------------------------------------------
DrvFields_ <-
  c("Drv_p1", "Drv_p2", "Drv_p3", "Drv_p4", "Drv_p5", "Drv_p6", "Drv_p7",
    "Drv_p8", "Drv_p9", "Drv_p10", "Drv_p11", "Drv_p12", "Drv_p13", "Drv_p14" )
# Create a matrix of driver fields with 1 for driver and NA for non-driver
Drvs_HhPr <- as.matrix(Hh_df[,DrvFields_])
Drvs_HhPr[Drvs_HhPr != 1] <- NA
# Tabulate drivers per household by age category
Drvs_HhAg <- t(apply(Ages_HhPr * Drvs_HhPr, 1, function(x) {
  table(cut(x, AgeBreaks, include.lowest=TRUE, right=FALSE))
}))
# Assign tabulations to age category variables
Hh_df$Drv15to19 <- Drvs_HhAg[,2]
Hh_df$Drv20to29 <- Drvs_HhAg[,3]
Hh_df$Drv30to54 <- Drvs_HhAg[,4]
Hh_df$Drv55to64 <- Drvs_HhAg[,5]
Hh_df$Drv65Plus <- Drvs_HhAg[,6]

#Calculate the number of workers by age group and add summary to household data
#------------------------------------------------------------------------------
WkrFields_ <-
  c("Wkr_p1", "Wkr_p2", "Wkr_p3", "Wkr_p4", "Wkr_p5", "Wkr_p6", "Wkr_p7",
    "Wkr_p8", "Wkr_p9", "Wkr_p10", "Wkr_p11", "Wkr_p12", "Wkr_p13", "Wkr_p14" )
# Create a matrix of worker fields with 1 for worker and NA for non-worker
Wkrs_HhPr <- as.matrix(Hh_df[,WkrFields_])
Wkrs_HhPr[Wkrs_HhPr != 1] <- NA
# Tabulate workers per household by age category
Wkrs_HhAg <- t(apply(Ages_HhPr * Wkrs_HhPr, 1, function(x) {
  table(cut(x, AgeBreaks, include.lowest=TRUE, right=FALSE))
}))
# Assign tabulations to age category variables
Hh_df$Wkr15to19 <- Wkrs_HhAg[,2]
Hh_df$Wkr20to29 <- Wkrs_HhAg[,3]
Hh_df$Wkr30to54 <- Wkrs_HhAg[,4]
Hh_df$Wkr55to64 <- Wkrs_HhAg[,5]
Hh_df$Wkr65Plus <- Wkrs_HhAg[,6]

#Clean up temporary files from age tabulations
#----------------------------------------------
Hh_df[AgeFields_] <- NULL
Hh_df[DrvFields_] <- NULL
Hh_df[WkrFields_] <- NULL
rm(AgeFields_, AgeBreaks, Ages_HhAg, Drvs_HhAg, Wkrs_HhAg)

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
#Daily vehicle and non-vehicle travel in personal vehicles is tabulated for each
#household. The following code identifies tours for each person in each
#household and sums up the distance, travel time, and dwell time for each tour.
#It also notes several other tour characteristics including, whether the tour
#starts at home and whether it ends at home, number of trips in the tour, the
#vehicle ID of the vehicle used, the mode, the type of vehicle, whether a
#household vehicle was used, the types of destinations along the tour, and the
#distance to work from home of the person. It also includes a 'tour signature'
#which is the sequence of starting and ending trip activity codes and vehicle
#ID. This signature is used to match up tours in the household. If more than one
#person had the same tour signature, the duplicate tours are eliminated, the
#number of persons on the tour is recorded, and the maximum distance to work of
#persons on the tour is recorded. From these tour records, tabulations are made
#by household of the VMT of travel using household vehicles, VMT of travel using
#non-household vehicles (excluding public transit vehicles), PMT of walk travel,
#PMT of bicycle travel, and PMT of public transit travel. School bus travel is
#included as public transit travel. See code below for more details.

#Define function to process person tours
getPersonTours <- function(PTrp_df, replaceNA = FALSE) {
  if (replaceNA) {
    WhyFrom_ <- PTrp_df$Whyfrom
    WhyTo_ <- PTrp_df$Whyto
    NaIdx_ <- which(is.na(WhyFrom_))
    for (i in NaIdx_) {
      if (i == 1) {
        WhyFrom_[i] <- 1
      } else {
        WhyToLag <- WhyTo_[i - 1]
        if (!is.na(WhyToLag) & WhyToLag == 1) {
          WhyFrom_[i] <- 1
        } else {
          WhyFrom_[i] <- 0
        }
      }
    }
    PTrp_df$Whyfrom <- WhyFrom_
  }
  Tours_ls <- split(PTrp_df, cumsum(PTrp_df$Whyfrom == 1))
  do.call(rbind, lapply(Tours_ls, function(x) {
    data.frame(
      Houseid = x$Houseid[1],
      Distance = sum(x$Trpmiles, na.rm = TRUE),
      TravelTime = sum(x$Trvl_min, na.rm = TRUE),
      DwellTime = sum(x$Dweltime, na.rm = TRUE),
      StartHome = x$Whyfrom[1] == 1,
      EndHome = tail(x$Whyto,1) == 1,
      Trips = nrow(x),
      Persons = max(x$Numontrp),
      Vehid = x$Vehused[1],
      Trptrans = x$Trptrans[1],
      Vehtype = x$Vehtype[1],
      HhVehUsed = x$Trphhveh[1],
      Whyto = paste(x$Whyto, collapse = "-"),
      Disttowk = Per_df$Disttowk[Per_df$Personid == x$Personid[1]],
      Signature =
        paste(paste(c(rbind(x$Whyfrom, x$Whyto)), collapse = ""), x$Vehid[1], sep = "-")
    )
  }))
}
#Define function to process household tours, removing duplicated person tour info
getHouseholdTours <- function(HTrp_df) {
  PTrp_ls <- split(HTrp_df, HTrp_df$Personid)
  PTours_df <- do.call(rbind, lapply(PTrp_ls, function(x) {
    if (any(is.na(x$Whyfrom))) {
      getPersonTours(x, TRUE)
    } else {
      getPersonTours(x)
    }
  } ))
  HTours_ls <- split(PTours_df, PTours_df$Signature)
  HTours_df <- do.call(rbind, lapply(HTours_ls, function(x) {
    y <- x[1,]
    if (any(!is.na(x$Disttowk))) {
      y$Disttowk <- max(x$Disttowk, na.rm = TRUE)
    } else {
      y$Disttowk <- NA
    }
    y
  }))
  HTours_df[, -which(names(HTours_df) == "Signature")]
}
#Create data frame of tours by household if not already created
#It takes a long time to create the data frame of tours and so the code to do so
#should not be run unless a completed tour dataset has not been created or if
#the code is changed
if (file.exists("data-raw/ToursByHh_df.Rda")) {
  load("data-raw/ToursByHh_df.Rda")
} else {
  HTrp_ls <- split(Dt_df, Dt_df$Houseid)
  ToursByHh_ls <- lapply(HTrp_ls, getHouseholdTours)
  ToursByHh_df <- do.call(rbind, ToursByHh_ls)
  rownames(ToursByHh_df) <- NULL
  ToursByHh_df$Houseid <- as.character(ToursByHh_df$Houseid)
  ToursByHh_df$Whyto <- as.character(ToursByHh_df$Whyto)
  save(ToursByHh_df, file = "data-raw/ToursByHh_df.Rda")
  rm(HTrp_ls, ToursByHh_ls)
}
#Make a copy of household tour data frame to further refine
HhTours_df <- ToursByHh_df
#Limit to complete cases
FieldsToCheck_ <-
  c("Houseid", "Distance", "TravelTime", "DwellTime", "StartHome", "EndHome",
    "Trips", "Persons", "Trptrans", "Whyto")
IsComplete_ <-
  complete.cases(HhTours_df[, FieldsToCheck_])
HhTours_df <- HhTours_df[IsComplete_,]
rm(FieldsToCheck_, IsComplete_)
#Limit to 99th percentile for Distance, TravelTime, and DwellTime
IsInLimits_ <-
  with(HhTours_df,
       Distance != 0 & Distance <= quantile(Distance, 0.99) &
         TravelTime != 0 & TravelTime <= quantile(TravelTime, 0.99) &
         DwellTime != 0 & DwellTime <= quantile(DwellTime, 0.99)
  )
HhTours_df <- HhTours_df[IsInLimits_,]
rm(IsInLimits_)
#Limit to sensible trip speeds
Speeds_ <- with(HhTours_df, 60 * Distance / TravelTime)
IsInLimits_ <-
  Speeds_ >= quantile(Speeds_, 0.005) & Speeds_ <= quantile(Speeds_, 0.995)
HhTours_df <- HhTours_df[IsInLimits_,]
rm(Speeds_, IsInLimits_)
#Add a Mode variable
HhTours_df <- HhTours_df[HhTours_df$Trptrans > 0 & HhTours_df$Trptrans != 91,]
HhTours_df <- HhTours_df[,]
Modes_ <- c("1" = "Auto", "2" = "LtTrk", "3" = "LtTrk", "4" = "LtTrk",
            "5" = "OthTrk", "6" = "RV", "7" = "Motorcycle", "8" = "Airplane",
            "9" = "Airplane", "10" = "Bus", "11" = "Bus", "12" = "SchoolBus",
            "13" = "Bus", "14" = "Bus", "15" = "Train", "16" = "Train",
            "17" = "Subway", "18" = "StreetCar", "19" = "Boat", "20" = "Boat",
            "21" = "Boat", "22" = "Taxi", "23" = "Taxi", "24" = "Taxi",
            "25" = "Bicycle", "26" = "Walk")
HhTours_df$Mode <- Modes_[as.character(HhTours_df$Trptrans)]
rm(Modes_)
#Add a flag for whether tour has a work purpose
IncludesWork_ <-
  sapply(HhTours_df$Whyto, function(x) {
    any(unlist(strsplit(x, "-")) %in% c("10", "11", "12", "13", "14"))
  })
HhTours_df$IncludesWork <- unname(IncludesWork_)
rm(IncludesWork_)

#Tabulate household travel
#-------------------------
#Travel in household vehicles
IsPvtVehTravel_ <-
  HhTours_df$Mode %in% c("Auto", "LtTrk", "OthTrk", "RV", "Motorcycle") & HhTours_df$HhVehUsed == 1
PvtVehDvmt_Hh <- unlist(tapply(HhTours_df$Distance[IsPvtVehTravel_], HhTours_df$Houseid[IsPvtVehTravel_], sum))
PvtVehTrips_Hh <- unlist(tapply(HhTours_df$Trips[IsPvtVehTravel_], HhTours_df$Houseid[IsPvtVehTravel_], sum))
# sum(PvtVehDvmt_Hh)
# sum(PvtVehDvmt_Hh) / nrow(HhTours_df)
# summary(PvtVehDvmt_Hh / PvtVehTrips_Hh)
Hh_df$PvtVehDvmt <- as.vector(PvtVehDvmt_Hh[Hh_df$Houseid])
Hh_df$PvtVehDvmt[is.na(Hh_df$PvtVehDvmt)] <- 0
Hh_df$PvtVehTrips <- as.vector(PvtVehTrips_Hh[Hh_df$Houseid])
Hh_df$PvtVehTrips[is.na(Hh_df$PvtVehTrips)] <- 0
rm(IsPvtVehTravel_, PvtVehDvmt_Hh, PvtVehTrips_Hh)
#Travel in non-household 'shared' vehicles
IsShrVehTravel_ <-
  HhTours_df$Mode %in% c("Taxi") |
  (HhTours_df$Mode %in% c("Auto", "LtTrk", "OthTrk", "RV", "Motorcycle") & (HhTours_df$HhVehUsed == 2))
ShrVehDvmt_Hh <- unlist(tapply(HhTours_df$Distance[IsShrVehTravel_], HhTours_df$Houseid[IsShrVehTravel_], sum))
ShrVehTrips_Hh <- unlist(tapply(HhTours_df$Trips[IsShrVehTravel_], HhTours_df$Houseid[IsShrVehTravel_], sum))
# sum(ShrVehDvmt_Hh)
# sum(ShrVehDvmt_Hh) / nrow(HhTours_df)
Hh_df$ShrVehDvmt <- as.vector(ShrVehDvmt_Hh[Hh_df$Houseid])
Hh_df$ShrVehDvmt[is.na(Hh_df$ShrVehDvmt)] <- 0
Hh_df$ShrVehTrips <- as.vector(ShrVehTrips_Hh[Hh_df$Houseid])
Hh_df$ShrVehTrips[is.na(Hh_df$ShrVehTrips)] <- 0
rm(IsShrVehTravel_, ShrVehDvmt_Hh, ShrVehTrips_Hh)
#Travel by walking
IsWalkTravel_ <- HhTours_df$Mode == "Walk"
WalkDpmt_Hh <-
  with(HhTours_df,
       unlist(tapply((Distance * Persons)[IsWalkTravel_], HhTours_df$Houseid[IsWalkTravel_], sum)))
# sum(WalkDpmt_Hh)
# sum(WalkDpmt_Hh) / nrow(HhTours_df)
Hh_df$WalkDpmt <- as.vector(WalkDpmt_Hh[Hh_df$Houseid])
Hh_df$WalkDpmt[is.na(Hh_df$WalkDpmt)] <- 0
rm(IsWalkTravel_, WalkDpmt_Hh)
#Travel by bicycling
IsBicycleTravel_ <- HhTours_df$Mode == "Bicycle"
BicycleDpmt_Hh <- unlist(tapply(HhTours_df$Distance[IsBicycleTravel_], HhTours_df$Houseid[IsBicycleTravel_], sum))
# sum(BicycleDpmt_Hh)
# sum(BicycleDpmt_Hh) / nrow(HhTours_df)
Hh_df$BikeDpmt <- as.vector(BicycleDpmt_Hh[Hh_df$Houseid])
Hh_df$BikeDpmt[is.na(Hh_df$BikeDpmt)] <- 0
rm(IsBicycleTravel_, BicycleDpmt_Hh)
#Travel using public transportation
IsTransitTravel_ <- HhTours_df$Mode %in% c("Bus", "SchoolBus", "Train", "Subway", "StreetCar")
TransitDpmt_Hh <- unlist(tapply(HhTours_df$Distance[IsTransitTravel_], HhTours_df$Houseid[IsTransitTravel_], sum))
# sum(TransitDpmt_Hh)
# sum(TransitDpmt_Hh) / nrow(HhTours_df)
Hh_df$TransitDpmt <- as.vector(TransitDpmt_Hh[Hh_df$Houseid])
Hh_df$TransitDpmt[is.na(Hh_df$TransitDpmt)] <- 0
TransitTrips_Hh <-
  unlist(tapply(HhTours_df$Trips[IsTransitTravel_], HhTours_df$Houseid[IsTransitTravel_], sum))
Hh_df$TransitTrips <- as.vector(TransitTrips_Hh[Hh_df$Houseid])
Hh_df$TransitTrips[is.na(Hh_df$TransitTrips)] <- 0
rm(IsTransitTravel_, TransitDpmt_Hh, TransitTrips_Hh)

#Identifies households that did no private or shared vehicle travel
#------------------------------------------------------------------
Hh_df$ZeroDvmt <- "N"
Hh_df$ZeroDvmt[Hh_df$PvtVehDvmt == 0 & Hh_df$ShrVehDvmt == 0] <- "Y"
Hh_df$ZeroDvmt <- as.factor(Hh_df$ZeroDvmt)

#Process person driver status, worker status, and age
#----------------------------------------------------
#Driver status 1 = driver, 0 = non-driver
Per_df$Driver[(Per_df$Driver != 1) & !is.na(Per_df$Driver)] <- 0
#Convert Worker to 1 for worker and 0 for non-worker
Per_df$Worker[(Per_df$Worker != 1) & !is.na(Per_df$Worker)] <- 0
#Assign age category
AgeBreaks <- c(0, 14, 19, 29, 54, 64, max(Per_df$R_age, na.rm = TRUE))
AgeGroups_ <-
  c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus")
Per_df$AgeGroup <- cut(Per_df$R_age, AgeBreaks, AgeGroups_)
rm(AgeBreaks, AgeGroups_)

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
# Hwy2001_df <-
#   read.csv("data-raw/HighwayStatistics2.csv",
#            colClasses = c(rep("character", 2), rep("numeric", 8)))
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
# Transit2001_df <- read.csv("data-raw/uza_bus_eq_rev_mi.csv", as.is = TRUE)
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
rm(Dt_df, toProperName, toVecFrom1DAry)


#==========================
#SAVE THE HOUSEHOLD DATASET
#==========================
#' Household travel from the 2001 National Household Travel Survey
#'
#' A household dataset containing the data used for estimating VisionEval
#' travel models derived from the 2001 National Household Travel Survey, USDOT
#' Highway Statistics reports, and the National Transit Database.
#'
#' @format A data frame with 60521 rows and 86 variables
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
#'   \item{Msapop}{Number of persons residing in the MSA}
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
#'   \item{Drv15to19}{Number of drivers 15 to 19 in household}
#'   \item{Drv20to29}{Number of drivers 20 to 29 in household}
#'   \item{Drv30to54}{Number of drivers 30 to 54 in household}
#'   \item{Drv55to64}{Number of drivers 55 to 64 in household}
#'   \item{Drv65Plus}{Number of drivers 65 or older in household}
#'   \item{Wkr15to19}{Number of workers 15 to 19 in household}
#'   \item{Wkr20to29}{Number of workers 20 to 29 in household}
#'   \item{Wkr30to54}{Number of workers 30 to 54 in household}
#'   \item{Wkr55to64}{Number of workers 55 to 64 in household}
#'   \item{Wkr65Plus}{Number of workers 65 or older in household}
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
#'   \item{PvtVehDvmt}{Household vehicle miles of travel on survey day using household (i.e. private) vehicles}
#'   \item{PvtVehTrips}{Household vehicle trips on survey day using household (i.e. private) vehicles}
#'   \item{ShrVehDvmt}{Household vehicle miles of travel on survey day using non-household (i.e. shared) vehicles}
#'   \item{ShrVehTrips}{Household vehicle trips on survey day using non-household (i.e. shared) vehicles}
#'   \item{WalkDpmt}{Household person miles of walking on survey day}
#'   \item{BikeDpmt}{Household person miles of bicycling on survey day}
#'   \item{TransitDpmt}{Household person miles of public transit travel on survey day}
#'   \item{TransitTrips}{Household transit trips on survey day}
#'   \item{ZeroDvmt}{Flag identifying whether household had no DVMT on survey day}
#'   \item{Numcommdrvr}{Number of commercial drivers in household}
#'   \item{Nbiketrp}{Number of bike trips in past week}
#'   \item{Nwalktrp}{Number of walk trips in past week}
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
usethis::use_data(Hh_df, overwrite = TRUE)
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
usethis::use_data(Veh_df, overwrite = TRUE)
rm(Veh_df)


#=====================
#SAVE THE TOUR DATASET
#=====================
#' Household tour dataset from the 2001 National Household Travel Survey
#'
#' A dataset of household tours (shared person tours) derived from the 2001
#' National Household Travel Survey and used in the estimation of several
#' VisionEval models.
#'
#'  @format A data frame with 154270 rows and 16 columns.
#'  \describe{
#'    \item{Houseid}{Unique household ID}
#'    \item{Distance}{Total distance in miles of the tour}
#'    \item{TravelTime}{Total time in minutes spent traveling on the tour}
#'    \item{DwellTime}{Total time in minutes spent at activities on the tour}
#'    \item{StartHome}{Logical identifying if the tour started at home}
#'    \item{EndHome}{Logical identifying if the tour ended at home}
#'    \item{Trips}{Number of trips in the tour}
#'    \item{Persons}{Number of persons on the tour}
#'    \item{Vehid}{Unique ID for vehicle in household}
#'    \item{Trptrans}{Mode of transportation (see 2001 NHTS codebook for TRPTRANS)}
#'    \item{Vehtype}{Type of vehicle used (see 2001 NHTS codebook for VEHTYPE)}
#'    \item{HhVehUsed}{Whether household vehicle used (1=yes, 2=no)}
#'    \item{Whyto}{String contenating successive activity codes at trip end (see 2001 NHTS codebook for WHYTO)}
#'    \item{Disttowk}{Distance from home to work for the person on the tour who works farthest from home}
#'    \item{Mode}{Simplified travel mode category (see script for definitions)}
#'    \item{IncludesWork}{Logical identifying whether tour includes a work activity (codes 10, 11, 12, 13, 14)}
#'  }
#'  @source 2001 National Household Travel Survey and Make2001NHTSDataset.R script.
"HhTours_df"
usethis::use_data(HhTours_df, overwrite = TRUE)
rm(HhTours_df)


#=======================
#SAVE THE PERSON DATASET
#=======================
#' Person dataset from the 2001 National Household Travel Survey
#'
#' A dataset of person characteristics derived from the 2001 National Household
#' Travel Survey and used in the estimation of several VisionEval models.
#'
#'  @format A data frame with 144884 rows and 14 columns.
#'  \describe{
#'    \item{Houseid}{Unique household ID}
#'    \item{Personid}{Unique ID of person in household}
#'    \item{Commdrvr}{Person is a commercial driver}
#'    \item{Nbiketrp}{Number of bike trips in past week}
#'    \item{Nwalktrp}{Number of walk trips in past week}
#'    \item{Usepubtr}{Used public transit on travel day}
#'    \item{Wrkdrive}{Job requires driving a motor vehicle}
#'    \item{Wrktrans}{Transportation mode to work last week}
#'    \item{Worker}{Person has job (1=yes, 0=no)}
#'    \item{Dtgas}{Price of gasoline}
#'    \item{Disttowk}{Distance to work in miles}
#'    \item{Driver}{Driver status (1=driver, 0=non-driver)}
#'    \item{R_age}{Age}
#'    \item{R_sex}{Sex}
#'    \item{AgeGroup}{AgeGroup: Age0to14, Age15to19, Age20to29, Age30to54, Age55to64, Age65Plus}
#'  }
#'  @source 2001 National Household Travel Survey and Make2001NHTSDataset.R script.
"Per_df"
usethis::use_data(Per_df, overwrite = TRUE)
rm(Per_df)
