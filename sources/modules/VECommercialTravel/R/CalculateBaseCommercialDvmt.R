#=============================
#CalculateBaseCommercialDvmt.R
#=============================
#This module calculates base year commercial service vehicle DVMT and
#heavy truck DVMT. It reads in the basis for calculating future DVMT from base
#year DVMT. This basis can be household DVMT, household income, workers, or
#population. The module computes the ratio corresponding to the specified basis
#and saves it along with the base year DVMT.

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


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
      NAME = "RatioComSvcDvmtHhDvmt",
      FILE = "marea_base_year_comsvc_dvmt.csv",
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
      NAME = "ComSvcDvmtGrowthBasis",
      FILE = "marea_base_year_comsvc_dvmt.csv",
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
      DESCRIPTION = "Basis for growing commercial service vehicle DVMT"
    ),
    item(
      NAME = "BaseYearHvyTrkDvmt",
      FILE = "marea_base_year_hvytrk_dvmt.csv",
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
      NAME = "HvyTrkDvmtGrowthBasis",
      FILE = "marea_base_year_hvytrk_dvmt.csv",
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
      DESCRIPTION = "Basis for growing commercial service vehicle DVMT"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "RatioComSvcDvmtHhDvmt",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseYearHvyTrkDvmt",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ComSvcDvmtGrowthBasis",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Population", "Income", "Dvmt", "Workers")
    ),
    item(
      NAME = "HvyTrkDvmtGrowthBasis",
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
        items("ComSvcDvmtDvmtFactor",
              "HvyTrkDvmtDvmtFactor"),
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
          "Ratio of base year commercial service vehicle DVMT to household DVMT",
          "Ratio of base year heavy truck DVMT to household DVMT"
        )
    ),
    item(
      NAME =
        items("ComSvcDvmtIncomeFactor",
              "HvyTrkDvmtIncomeFactor"),
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
          "Ratio of base year commercial service vehicle DVMT to household income",
          "Ratio of base year heavy truck DVMT to household income"
        )
    ),
    item(
      NAME =
        items("ComSvcDvmtPopFactor",
              "HvyTrkDvmtPopFactor"),
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
          "Ratio of base year commercial service vehicle DVMT to population",
          "Ratio of base year heavy truck DVMT to population"
        )
    ),
    item(
      NAME =
        items("ComSvcDvmtWkrFactor",
              "HvyTrkDvmtWkrFactor"),
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
          "Ratio of base year commercial service vehicle DVMT to number of workers",
          "Ratio of base year heavy truck DVMT to number of workers"
        )
    ),
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
          "Commercial service DVMT",
          "Heavy truck DVMT"
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
  ComSvcDvmt <- TotHhDvmt * L$BaseYear$Marea$RatioComSvcDvmtHhDvmt
  HvyTrkDvmt <- L$BaseYear$Marea$BaseYearHvyTrkDvmt
  #Calculate ratio of commercial DVMT with household DVMT
  ComSvcDvmtDvmtFactor <- ComSvcDvmt / TotHhDvmt
  HvyTrkDvmtDvmtFactor <- HvyTrkDvmt / TotHhDvmt
  #Calculate ratio of commercial DVMT with household income
  ComSvcDvmtIncomeFactor <-  ComSvcDvmt / TotIncome
  HvyTrkDvmtIncomeFactor <- HvyTrkDvmt / TotIncome
  #Calculate ratio of commercial DVMT with population
  ComSvcDvmtPopFactor <- ComSvcDvmt / TotPopulation
  HvyTrkDvmtPopFactor <- HvyTrkDvmt / TotPopulation
  #Calculate ratio of commercial DVMT with workers
  ComSvcDvmtWkrFactor <- ComSvcDvmt / TotWorkers
  HvyTrkDvmtWkrFactor <- HvyTrkDvmt / TotWorkers

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(
      ComSvcDvmt = ComSvcDvmt,
      HvyTrkDvmt = HvyTrkDvmt,
      ComSvcDvmtDvmtFactor = ComSvcDvmtDvmtFactor,
      HvyTrkDvmtDvmtFactor = HvyTrkDvmtDvmtFactor,
      ComSvcDvmtIncomeFactor = ComSvcDvmtIncomeFactor,
      HvyTrkDvmtIncomeFactor = HvyTrkDvmtIncomeFactor,
      ComSvcDvmtPopFactor = ComSvcDvmtPopFactor,
      HvyTrkDvmtPopFactor = HvyTrkDvmtPopFactor,
      ComSvcDvmtWkrFactor = ComSvcDvmtWkrFactor,
      HvyTrkDvmtWkrFactor = HvyTrkDvmtWkrFactor
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
