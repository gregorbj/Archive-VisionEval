#================
#PredictWorkers.R
#================
#This module assigns workers by age to households and to noninstitutional group
#quarters population. It is a simple model which predicts workers as a function
#of the household type and age composition. There is no responsiveness to jobs
#or how changes in the job market and demographics might change the worker age
#composition.

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


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#The worker model predicts workers as a function of the household type:
#i.e. the number of persons in each of 6 age groups in the household. It is a
#simple stochastic model where the probability that a person in an age group in
#a household type is a worker is the ratio of workers to persons in that age
#group and household type. For the noninstitutionalized group quarters
#population, the probability is the ratio of workers to persons by age group.

#Define a function to estimate worker model parameters
#-----------------------------------------------------
#' Calculate worker model parameters
#'
#' \code{calcWorkerProportions} creates a matrix of proportions of persons who
#' are workers by household type and age group for regular households and for
#' the noninstitutionalized group quarters population.
#'
#' This function creates a matrix of proportions of persons who are workers by
#' household type and age group for regular households and for the
#' noninstitutionalized group quarters population. The rows are named by the
#' household type names which for regular households are strings with the
#' number of persons by age group separated by hyphens and is Grp for the
#' noninstitutionalized group quarters population. These names correspond to
#' values in the HhType dataset in the Household table of the datastore.
#'
#' @param HhData_df A dataframe of household estimation data as produced by the
#' CreateEstimationDatasets.R script.
#' @return A matrix of the proportions of persons who are workers by household
#' type and age group. Where the row names are the household type (HhType)
#' names and the column names are the age group names.
#' @include CreateEstimationDatasets.R CreateHouseholds.R
#' @export
calcWorkerProportions <- function(HhData_df) {
  GQ_df <- HhData_df[HhData_df$HhType == "Grp",]
  Hh_df <- HhData_df[HhData_df$HhType == "Reg",]
  load("data/HtProb_HtAp.rda")
  Ag <-
    c("Age0to14",
      "Age15to19",
      "Age20to29",
      "Age30to54",
      "Age55to64",
      "Age65Plus")
  Wk <- gsub("Age", "Wkr", Ag[-1])
  # #Calculate the worker proportions by age group
  # NumWkr_Wk <- colSums(Hh_df[,Wk]) + colSums(GQ_df[,Wk])
  # PropWkr_Wk <- NumWkr_Wk / sum(NumWkr_Wk)
  #Create vector of household type names
  HhType_ <-
    apply(Hh_df[, Ag], 1, function(x)
      paste(x, collapse = "-"))
  #Limit Hh_df to selected household types
  Hh_df <- Hh_df[HhType_ %in% rownames(HtProb_HtAp),]
  SelHhType_ <- HhType_[HhType_ %in% rownames(HtProb_HtAp)]
  #Apply household weights to persons by age
  WtHhPop_df <- sweep(Hh_df[, c(Ag, Wk)], 1, Hh_df$HhWeight, "*")
  #Tabulate persons by age group and worker group by household type
  HhAgWkTab_ls <- lapply(WtHhPop_df, function(x) {
    tapply(x, SelHhType_, function(x)
      sum(as.numeric(x)))
  })
  HhAgWkTab_df <- data.frame(do.call(cbind, HhAgWkTab_ls))
  #Calculate the proportion of persons by age who are workers by household type
  PropHhWkr_HtAg <-
    as.matrix(HhAgWkTab_df[,Wk]) / as.matrix(HhAgWkTab_df[,Ag[-1]])
  PropHhWkr_HtAg[is.nan(PropHhWkr_HtAg)] <- 0
  colnames(PropHhWkr_HtAg) <- Ag[-1]
  #Calculate the proportion of group quarters persons by age who are workers
  PropGQWkr_Ag <- colSums(GQ_df[,Wk]) / colSums(GQ_df[,Ag[-1]])
  #Add the group quarters proportions to the household matrix
  PropHhWkr_HtAg <- rbind(PropHhWkr_HtAg, Grp = PropGQWkr_Ag)
  #Return matrix of proportions
  PropHhWkr_HtAg
}

#Create and save household and group quarters worker proportions
#---------------------------------------------------------------
load("data/Hh_df.rda")
PropHhWkr_HtAg <- calcWorkerProportions(Hh_df)
#' Worker proportions
#'
#' A dataset that contains proportion of workers by age group by household
#' type for the regular household population and proportion of workers by age
#' group for noninstitutional group quarters population.
#'
#' @format A a matrix of the proportion of persons in age group who are workers
#' for each household type.:
#' @source PredictWorkers.R script.
"PropHhWkr_HtAg"
devtools::use_data(PropHhWkr_HtAg, overwrite = TRUE)
rm(calcWorkerProportions, Hh_df)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
PredictWorkersSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = "HhType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("Wkr15to19",
              "Wkr20to29",
              "Wkr30to54",
              "Wkr55to64",
              "Wkr65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items("Workers in 15 to 19 year old age group",
              "Workers in 20 to 29 year old age group",
              "Workers in 30 to 54 year old age group",
              "Workers in 55 to 64 year old age group",
              "Workers in 65 or older age group")
    ),
    item(
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total workers"
    ),
    item(
      NAME = "NumWkr",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of workers residing in the zone"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for PredictWorkers module
#'
#' A list containing specifications for the PredictWorkers module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source PredictWorkers.R script.
"PredictWorkersSpecifications"
devtools::use_data(PredictWorkersSpecifications, overwrite = TRUE)
rm(PredictWorkersSpecifications)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function predicts the number of workers in each of 6 age groups in each
#household and tallies the total number of workers in the household. It uses
#the matrix of worker proportions by household type and age group as choice
#probabilities for determining the number of workers by age group for each
#household.

#Main module function that predicts workers by age for each household
#--------------------------------------------------------------------
#' Main module function to predict workers by age for each household
#'
#' \code{PredictWorkers} predicts the number of workers by age group for each
#' household and tallies the total number of workers for each household.
#'
#' This function predicts the number of workers for each household. Household
#' workers are assigned to 5 age groups: 15-19, 20-29, 30-54, 55-64, and 65Plus.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
PredictWorkers <- function(L) {
  #Define dimension name vectors
  Ag <-
    c("Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus")
  Wk <- gsub("Age", "Wkr", Ag)
  Az <- L$Year$Azone$Azone
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Calculate total number of households
  NumHh <- length(L$Year$Household$HhType)
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Workers = integer(NumHh),
      Wkr15to19 = integer(NumHh),
      Wkr20to29 = integer(NumHh),
      Wkr30to54 = integer(NumHh),
      Wkr55to64 = integer(NumHh),
      Wkr65Plus = integer(NumHh)
    )
  Out_ls$Year$Azone <-
    list(
      NumWkr = integer(length(L$Year$Azone))
    )
  #Define function to predict workers for a household age group
  getNumWkr <- function(N, P) {
    as.integer(sum(sample(c(1,0), size = N, replace = TRUE, prob = c(P, 1-P))))
  }
  #Iterate through age groups and predict workers by age
  for (i in 1:length(Ag)) {
    NumPrsn_ <- L$Year$Household[[Ag[i]]]
    Probs_ <- PropHhWkr_HtAg[L$Year$Household$HhType, Ag[i]]
    DoPredict_ <- NumPrsn_ > 0 & Probs_ > 0
    Out_ls$Year$Household[[Wk[i]]][DoPredict_] <-
      mapply(getNumWkr, NumPrsn_[DoPredict_], Probs_[DoPredict_])
    rm(NumPrsn_, Probs_, DoPredict_)
  }
  rm(i)
  #Calculate the total number of workers
  Out_ls$Year$Household$Workers <-
    mapply(sum,
           Out_ls$Year$Household$Wkr15to19,
           Out_ls$Year$Household$Wkr20to29,
           Out_ls$Year$Household$Wkr30to54,
           Out_ls$Year$Household$Wkr55to64,
           Out_ls$Year$Household$Wkr65Plus)
  #Calculate the total number of workers by Azone
  Out_ls$Year$Azone$NumWkr <-
    tapply(Out_ls$Year$Household$Workers, L$Year$Household$Azone, sum)[Az]
  #Return the results
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
#   ModuleName = "PredictWorkers",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictWorkers",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
