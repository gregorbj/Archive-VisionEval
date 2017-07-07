#==========================
#CreateEstimationDatasets.R
#==========================
#The models in the CreateHouseholds, PredictWorkers, PredictIncome, and
#PredictHousing modules are estimated from Census Public Use Microdata Sample
#household and person data. This script reads in the data files and creates the
#datasets needed to estimate these models.

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

#Describe specifications for input data files
#--------------------------------------------
#PUMS household data
PumsHhInp_ls <- items(
  item(
    NAME =
      items("SERIALNO",
            "PUMA5",
            "HWEIGHT",
            "UNITTYPE",
            "PERSONS"),
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "BLDGSZ",
    TYPE = "integer",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "HINC",
    TYPE = "double",
    PROHIBIT = c("NA"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#PUMS person data
PumsPerInp_ls <- items(
  item(
    NAME =
      items("SERIALNO",
            "AGE",
            "WRKLYR",
            "MILITARY"),
    TYPE = "integer",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "INCTOT",
    TYPE = "double",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in the datasets
#--------------------
#Read in PUMS housing data file
Hh_df <-
  processEstimationInputs(
    PumsHhInp_ls,
    "pums_households.csv",
    "CreateEstimationDatasets.R")
rm(PumsHhInp_ls)
#Read in PUMS person data file
Per_df <-
  processEstimationInputs(
    PumsPerInp_ls,
    "pums_persons.csv",
    "CreateEstimationDatasets.R")
rm(PumsPerInp_ls)

#Add number of persons by age group to household data
#----------------------------------------------------
#Calculate age group for each person and identify if worker
Ag <-
  c(
    "Age0to14",
    "Age15to19",
    "Age20to29",
    "Age30to54",
    "Age55to64",
    "Age65Plus"
  )
AgeGroup_ <-
  cut(Per_df$AGE, c(0, 14, 19, 29, 54, 64, 200), labels = Ag, include.lowest = TRUE)
IsWkr_ <- as.numeric(Per_df$WRKLYR == 1)
AgeWkr_df <- data.frame(AgeGroup = AgeGroup_, Worker = IsWkr_)
#Tabulate persons and workers by age group in each household
AgeGroup_ls <- split(AgeWkr_df, Per_df$SERIALNO)
AgeGroupTab_df <-
  data.frame(do.call(rbind, lapply(AgeGroup_ls, function(x) table(x$AgeGroup))))
WorkerTab_df <-
  data.frame(do.call(rbind, lapply(AgeGroup_ls, function(x) {
    tapply(x$Worker, x$AgeGroup, sum)
  })))
WorkerTab_df[is.na(WorkerTab_df)] <- 0
names(WorkerTab_df) <- gsub("Age", "Wkr", names(WorkerTab_df))
WorkerTab_df <- WorkerTab_df[,-1] #Remove persons 14 years or younger
rm(AgeGroup_, IsWkr_, AgeGroup_ls, AgeWkr_df)

#Add Group and Worker tabulations to Hh_df
#-----------------------------------------
for( nm in names(AgeGroupTab_df)) {
  Hh_df[[nm]] <- AgeGroupTab_df[as.character(Hh_df$SERIALNO), nm]
}
rm(nm, AgeGroupTab_df)
for( nm in names(WorkerTab_df)) {
  Hh_df[[nm]] <- WorkerTab_df[as.character(Hh_df$SERIALNO), nm]
}
rm(nm, WorkerTab_df)

#Process group quarters population
#---------------------------------
#Remove institutionalized group quarters population
Hh_df <- Hh_df[Hh_df$UNITTYPE != 1,]
#Add personal income data for noninstitutionalized group quarters population
GQId_ <- Hh_df$SERIALNO[Hh_df$UNITTYPE == 2]
GQInc_ <- Per_df$INCTOT[match(GQId_, Per_df$SERIALNO)]
Hh_df$HINC[Hh_df$UNITTYPE == 2] <- GQInc_
rm(GQId_, GQInc_, Per_df)
#Remove records with HINC equals NA
Hh_df <- Hh_df[!is.na(Hh_df$HINC),]
#Set negative household income to 0
Hh_df$HINC[Hh_df$HINC < 0] <- 0

#Clean household records
#-----------------------
#Remove zero person households
Hh_df <- Hh_df[Hh_df$PERSONS > 0,]
#Where HWEIGHT = 0, set to 1
Hh_df$HWEIGHT[Hh_df$HWEIGHT == 0] <- 1
#Remove any households that might only have persons 14 or younger
Hh_df <- Hh_df[!(rowSums(Hh_df[, Ag[-1]]) == 0 ), ]
rm(Ag)

#Calculate PUMA average per capita income and add to household data frame
#------------------------------------------------------------------------
#Split household data frame by PUMA5
HhPuma_ls_df <- split(Hh_df, Hh_df$PUMA5)
#Calculate average per capita income for each PUMA
AvePerCapInc_Pu <-
  unlist(lapply(HhPuma_ls_df, function(x) {
    sum(x$HWEIGHT * x$HINC / x$PERSONS) / sum(x$HWEIGHT)
  }))
#Add average per capita income to the household data frame
Hh_df$AvePerCapInc <- AvePerCapInc_Pu[as.character(Hh_df$PUMA5)]
#Clean up
rm(HhPuma_ls_df, AvePerCapInc_Pu)

#Add housing type variable to household data
#-------------------------------------------
Ht <- c("SF", "MF", "OTH")
Hh_df$HouseType <-
  cut(
    Hh_df$BLDGSZ,
    breaks = c(0, 3, 9, 10),
    include.lowest = TRUE,
    labels = Ht
  )
rm(Ht)
Hh_df$HouseType[is.na(Hh_df$HouseType)] <- "OTH"

#Rename household data fields and remove unneeded fields
#-------------------------------------------------------
#Household income is referred to as "Income"
Hh_df$Income <- Hh_df$HINC
#Household size is referred to as "HhSize"
Hh_df$HhSize <- Hh_df$PERSONS
#Household weight is referred to as "HhWeight"
Hh_df$HhWeight <- Hh_df$HWEIGHT
#Household Type
Hh_df$HhType <- "Reg"
Hh_df$HhType[Hh_df$UNITTYPE == 2] <- "Grp"
#Remove fields not needed
Hh_df$SERIALNO <- NULL
Hh_df$PUMA5 <- NULL
Hh_df$HWEIGHT <- NULL
Hh_df$PERSONS <- NULL
Hh_df$BLDGSZ <- NULL
Hh_df$HINC <- NULL
Hh_df$UNITTYPE <- NULL

#Save the household dataset
#--------------------------
#' Household data from Census PUMS
#'
#' A household dataset containing the data used for estimating the
#' CreateHouseholds, PredictWorkers, PredictLifeCycle, PredictIncome, and
#' PredictHouseType modules derived from from year 2000 PUMS data for Oregon.
#'
#' @format A data frame with 65988 rows and 17 variables (there may be a
#' different number of rows if PUMS datasets are used for different areas):
#' \describe{
#'   \item{Age0to14}{number of persons in 0 to 14 age group}
#'   \item{Age15to19}{number of persons in 15 to 19 age group}
#'   \item{Age20to29}{number of persons in 20 to 29 age group}
#'   \item{Age30to54}{number of persons in 30 to 54 age group}
#'   \item{Age55to64}{number of persons in 55 to 64 age group}
#'   \item{Age65Plus}{number of persons 65 years or older}
#'   \item{Wkr15to19}{number of workers in 15 to 19 age group}
#'   \item{Wkr20to29}{number of workers in 20 to 29 age group}
#'   \item{Wkr30to54}{number of workers in 30 to 54 age group}
#'   \item{Wkr55to64}{number of workers in 55 to 64 age group}
#'   \item{Wkr65Plus}{number of workers 65 years or older}
#'   \item{AvePerCapInc}{average per capita income of PUMA, nominal $}
#'   \item{HouseType}{housing type (SF = single family, MF = multifamily)}
#'   \item{Income}{annual household income, nominal 1999$}
#'   \item{HhSize}{number of persons in household}
#'   \item{HhType}{household type (Reg = regular household, Grp = group quarters)}
#'   \item{HhWeight}{household sample weight}
#' }
#' @source CreateEstimationDatasets.R script.
"Hh_df"
devtools::use_data(Hh_df, overwrite = TRUE)
rm(Hh_df)
