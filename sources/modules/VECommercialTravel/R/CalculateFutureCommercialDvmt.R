#===============================
#CalculateFutureCommercialDvmt.R
#===============================
#This module calculates future year (and other non-base year) commercial
#light-duty vehicle DVMT and heavy-duty DVMT. DVMT is predicted as a function of
#the values of the predictor variables identified in the
#"marea_base_year_com_dvmt.csv" inputs and the factors for those variables
#calculated in the base year.

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
#This module has no estimated parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateFutureCommercialDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Marea",
  #Specify new tables to be created by Inp if any
  #Specify input data
  Get = items(
    item(
      NAME =
        items("ComSvcDvmtDvmtFactor",
              "HvyTrkDvmtDvmtFactor"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("ComSvcDvmtIncomeFactor",
              "HvyTrkDvmtIncomeFactor"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("ComSvcDvmtPopFactor",
              "HvyTrkDvmtPopFactor"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("ComSvcDvmtWkrFactor",
              "HvyTrkDvmtWkrFactor"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "ComSvcDvmtGrowthBasis",
        "HvyTrkDvmtGrowthBasis"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Population", "Income", "Dvmt", "Workers")
    ),
    item(
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
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
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("ComSvcDvmt",
              "HvyTrkDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Commercial light-duty vehicle DVMT",
          "Commercial heavy-duty vehicle DVMT"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateFutureCommercialDvmt module
#'
#' A list containing specifications for the CalculateFutureCommercialDvmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{input data specifications}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateFutureCommercialDvmt.R script.
"CalculateFutureCommercialDvmtSpecifications"
devtools::use_data(CalculateFutureCommercialDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates future year commercial light-duty vehicle DVMT and
#heavy-duty vehicle DVMT by metropolitan area. Actually it can be used to
#calculate commercial DVMT for any non-base year.

#Main module function that calculates future year commercial DVMT
#----------------------------------------------------------------
#' Calculate the future year commercial DVMT and ratios with prospective
#' predictors.
#'
#' \code{CalculateFutureCommercialDvmt} calculate the future year commercial
#' light-duty vehicle and heavy-duty vehicle DVMT.
#'
#' This function calculates the commercial light-duty DVMT and heavy-duty DVMT
#' for the future year. It may be used to calculate commercial DVMT for any
#' non-base year.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateFutureCommercialDvmt <- function(L) {

  #Calculate commercial light-duty vehicle DVMT
  #--------------------------------------------
  ComSvcPredictorValue <-
    switch(L$BaseYear$Marea$ComSvcDvmtGrowthBasis,
           Dvmt = sum(L$Year$Household$Dvmt),
           Income = sum(L$Year$Household$Income),
           Population = sum(L$Year$Household$HhSize),
           Workers = sum(L$Year$Household$Workers))
  ComSvcPredictorFactor <-
    switch(L$BaseYear$Marea$ComSvcDvmtGrowthBasis,
           Dvmt = L$BaseYear$Marea$ComSvcDvmtDvmtFactor,
           Income = L$BaseYear$Marea$ComSvcDvmtIncomeFactor,
           Population = L$BaseYear$Marea$ComSvcDvmtPopFactor,
           Workers = L$BaseYear$Marea$ComSvcDvmtWkrFactor)
  ComSvcDvmt <- ComSvcPredictorValue * ComSvcPredictorFactor

  #Calculate commercial heavy-duty vehicle DVMT
  #--------------------------------------------
  HvyTrkPredictorValue <-
    switch(L$BaseYear$Marea$HvyTrkDvmtGrowthBasis,
           Dvmt = sum(L$Year$Household$Dvmt),
           Income = sum(L$Year$Household$Income),
           Population = sum(L$Year$Household$HhSize),
           Workers = sum(L$Year$Household$Workers))
  HvyTrkPredictorFactor <-
    switch(L$BaseYear$Marea$HvyTrkDvmtGrowthBasis,
           Dvmt = L$BaseYear$Marea$HvyTrkDvmtDvmtFactor,
           Income = L$BaseYear$Marea$HvyTrkDvmtIncomeFactor,
           Population = L$BaseYear$Marea$HvyTrkDvmtPopFactor,
           Workers = L$BaseYear$Marea$HvyTrkDvmtWkrFactor)
  HvyTrkDvmt <- HvyTrkPredictorValue * HvyTrkPredictorFactor

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(
      ComSvcDvmt = ComSvcDvmt,
      HvyTrkDvmt = HvyTrkDvmt
      )
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
#   ModuleName = "CalculateFutureCommercialDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateFutureCommercialDvmt(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateFutureCommercialDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "BaseYear"
# )
