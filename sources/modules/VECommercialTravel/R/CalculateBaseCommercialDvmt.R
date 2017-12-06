#=============================
#CalculateBaseCommercialDvmt.R
#=============================
#This module calculates base year commercial light-duty vehicle DVMT and
#heavy-duty DVMT. It reads in the basis for calculating future DVMT from base
#year DVMT. This basis can be household DVMT, household income, workers, or
#population. The module computes the ratio corresponding to the specified basis
#and saves it along with the base year DVMT.

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
CalculateBaseCommercialDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Marea",
  #Specify new tables to be created by Inp if any
  #Specify input data
  Inp = items(
    item(
      NAME = "RatioLDComDvmtHhDvmt",
      FILE = "marea_base_year_com_dvmt.csv",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Ratio between light-duty commercial vehicle DVMT (resulting from household and business demand in the metropolitan area) and household DVMT in base year"
    ),
    item(
      NAME = "BaseYearHDComDvmt",
      FILE = "marea_base_year_com_dvmt.csv",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Heavy duty truck DVMT on metropolitan area roads"
    ),
    item(
      NAME = items(
        "LDComDvmtGrowthBasis",
        "HDComDvmtGrowthBasis"),
      FILE = "marea_base_year_com_dvmt.csv",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      SIZE = 10,
      PROHIBIT = "",
      ISELEMENTOF = c("Population", "Income", "Dvmt", "Workers"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Basis for growing commercial light-duty vehicle DVMT",
        "Basis for growing commercial heavy-duty vehicle DVMT")
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "RatioLDComDvmtHhDvmt",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseYearHDComDvmt",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "LDComDvmtGrowthBasis",
        "HDComDvmtGrowthBasis"),
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
        items("LDComDvmtDvmtFactor",
              "HDComDvmtDvmtFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of base year commercial light-duty vehicle DVMT to household DVMT",
          "Ratio of base year commercial heavy-duty vehicle DVMT to household DVMT"
        )
    ),
    item(
      NAME =
        items("LDComDvmtIncomeFactor",
              "HDComDvmtIncomeFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/USD",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of base year commercial light-duty vehicle DVMT to household income",
          "Ratio of base year commercial heavy-duty vehicle DVMT to household income"
        )
    ),
    item(
      NAME =
        items("LDComDvmtPopFactor",
              "HDComDvmtPopFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of base year commercial light-duty vehicle DVMT to population",
          "Ratio of base year commercial heavy-duty vehicle DVMT to population"
        )
    ),
    item(
      NAME =
        items("LDComDvmtWkrFactor",
              "HDComDvmtWkrFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of base year commercial light-duty vehicle DVMT to number of workers",
          "Ratio of base year commercial heavy-duty vehicle DVMT to number of workers"
        )
    ),
    item(
      NAME =
        items("LDComDvmt",
              "HDComDvmt"),
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
#' Specifications list for CalculateBaseCommercialDvmt module
#'
#' A list containing specifications for the CalculateBaseCommercialDvmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{input data specifications}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateBaseCommercialDvmt.R script.
"CalculateBaseCommercialDvmtSpecifications"
devtools::use_data(CalculateBaseCommercialDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates base year commercial light-duty vehicle DVMT and
#heavy-duty vehicle DVMT by metropolitan area. It also calculates ratios between
#DVMT and population, household DVMT, household income, and workers.

#Main module function that calculates base year commercial DVMT
#--------------------------------------------------------------
#' Calculate the base year commercial DVMT and ratios with prospective
#' predictors.
#'
#' \code{CalculateBaseCommercialDvmt} calculate the base year commercial
#' light-duty vehicle and heavy-duty vehicle DVMT and calculate ratios with
#' prospective predictor variables.
#'
#' This function calculates the commercial light-duty DVMT and heavy-duty DVMT
#' for the base year. It also calculates ratios between DVMT and population,
#' household DVMT, household income, and workers.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateBaseCommercialDvmt <- function(L) {

  #Calculate commercial DVMT and ratios
  #------------------------------------
  #Calculate total household DVMT, population, income, and workers
  TotHhDvmt <- sum(L$Year$Household$Dvmt)
  TotPopulation <- sum(L$Year$Household$HhSize)
  TotIncome <- sum(L$Year$Household$Income)
  TotWorkers <- sum(L$Year$Household$Workers)
  #Calculate base year commercial DVMT
  LDComDvmt <- TotHhDvmt * L$BaseYear$Marea$RatioLDComDvmtHhDvmt
  HDComDvmt <- L$BaseYear$Marea$BaseYearHDComDvmt
  #Calculate ratio of commercial DVMT with household DVMT
  LDComDvmtDvmtFactor <- LDComDvmt / TotHhDvmt
  HDComDvmtDvmtFactor <- HDComDvmt / TotHhDvmt
  #Calculate ratio of commercial DVMT with household income
  LDComDvmtIncomeFactor <- LDComDvmt / TotIncome
  HDComDvmtIncomeFactor <- HDComDvmt / TotIncome
  #Calculate ratio of commercial DVMT with population
  LDComDvmtPopFactor <- LDComDvmt / TotPopulation
  HDComDvmtPopFactor <- HDComDvmt / TotPopulation
  #Calculate ratio of commercial DVMT with workers
  LDComDvmtWkrFactor <- LDComDvmt / TotWorkers
  HDComDvmtWkrFactor <- HDComDvmt / TotWorkers

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(
      LDComDvmt = LDComDvmt,
      HDComDvmt = HDComDvmt,
      LDComDvmtDvmtFactor = LDComDvmtDvmtFactor,
      HDComDvmtDvmtFactor = HDComDvmtDvmtFactor,
      LDComDvmtIncomeFactor = LDComDvmtIncomeFactor,
      HDComDvmtIncomeFactor = HDComDvmtIncomeFactor,
      LDComDvmtPopFactor = LDComDvmtPopFactor,
      HDComDvmtPopFactor = HDComDvmtPopFactor,
      LDComDvmtWkrFactor = LDComDvmtWkrFactor,
      HDComDvmtWkrFactor = HDComDvmtWkrFactor
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
#   ModuleName = "CalculateBaseCommercialDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateBaseCommercialDvmt(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateBaseCommercialDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "BaseYear"
# )
