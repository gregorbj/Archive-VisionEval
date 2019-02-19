#=============================
#BalanceRoadCostsAndRevenues.R
#=============================

#<doc>
#
## BalanceRoadCostsAndRevenues Module
#### January 23, 2019
#
#This module calculates an extra mileage tax ($ per vehicle mile traveled) for household vehicles needed to make up any difference in the cost of constructing, maintaining, and operating roadways and the revenues from fuel, VMT, and congestion taxes.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#The module calculates the additional cost per vehicle mile of household travel required to pay for roadway costs attributable to household vehicle travel. The steps are as follows:
#
#* The cost of adding freeway and arterial lane miles is calculated only if the model year is later than the base year. The difference between the freeway lane miles for the model year and for the base year is calculated for each marea. The total for all mareas is calculated but negative differences are ignored. In other words, no cost is attributed to the removal of freeway lane miles and the removal of freeway lane miles in one marea does not offset the cost of adding freeway lane miles in another marea. The same calculation is performed for arterial lane miles.
#
#* It is assumed that changes in lane miles calculated for the period between the model year and the base year are made in equal increments over that time period. The changes are divided by the number of years to get the annual change in freeway lane miles and the annual change in arterial lane miles. The annual changes are multiplied by the respective costs per lane mile to get the annual cost for adding freeway lane miles and for adding arterial lane miles. These are summed.
#
#* The proportion of the annual lane mile cost attributable to household vehicle travel is calculated by dividing total household DVMT by the sum of total household DVMT, commercial service vehicle DVMT, and car-equivalent heavy truck DVMT. The car-equivalent heavy truck DVMT is calculated by multiplying heavy truck DVMT by the passenger car equivalent factor ('HvyTrkPCE') that is a user input which reflects the relative road capacity demands of heavy trucks (e.g. 3 means one heavy truck is equivalent to 3 cars.)
#
#* The cost of adding lane miles per mile of household travel is calculated by multiplying the annual lane mile addition cost by the proportion attributable to households and dividing by the household annual VMT (i.e. DVMT * 365).
#
#* Other road costs per mile are calculated by summing the costs supplied by users for 'RoadBaseModCost' (modernization costs such as realignment but excluding adding lane miles), 'RoadPresOpMaintCost' (road preservation, operations, and maintenance), and 'RoadOtherCost' (administration, planning, travel demand management, etc.)
#
#* The total cost per vehicle mile for households is calculated by summing the added lane mile cost rate and other road cost rate.
#
#* The average road taxes collected per household vehicle mile are calculated as a weighted average of the average road tax per mile of each household (calculated by the 'CalculateVehicleOperatingCost' module) using the household DVMT (calculated by the 'BudgetHouseholdDvmt' module) as the weight.
#
#* The difference between the total cost per vehicle mile and the average road taxes collected per vehicle mile is the extra VMT tax ('ExtraVmtTax'). If road tax collections exceed costs, the value of the extra VMT tax is set equal to 0.
#
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#No module parameters are estimated in this module.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
BalanceRoadCostsAndRevenuesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "RoadBaseModCost",
          "RoadPresOpMaintCost",
          "RoadOtherCost"),
      FILE = "region_road_cost.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average base modernization cost per light-duty vehicle mile traveled (dollars per vehicle mile). Base modernization includes roadway improvements exclusive of addition of lanes.",
          "Average road preservation, operations, and maintenance cost per light-duty vehicle mile traveled (dollars per vehicle mile).",
          "Average other road cost (e.g. administration, planning, project development, safety) per light-duty vehicle mile traveled (dollars per vehicle mile)."
        )
    ),
    item(
      NAME =
        items(
          "FwyLnMiCost",
          "ArtLnMiCost"),
      FILE = "region_road_cost.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average cost to build one freeway lane-mile (dollars per lane-mile)",
          "Average cost to build one arterial lane-mile (dollars per lane-mile)"
        )
    ),
    item(
      NAME = "HvyTrkPCE",
      FILE = "region_road_cost.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "ratio",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Passenger car equivalent (PCE) for heavy trucks. PCE indicates the number of light-duty vehicles a heavy truck is equivalent to in calculating road capacity."
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items(
          "RoadBaseModCost",
          "RoadPresOpMaintCost",
          "RoadOtherCost"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "FwyLnMiCost",
          "ArtLnMiCost"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HvyTrkPCE",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "ratio",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "HvyTrkUrbanDvmt",
        "HvyTrkNonUrbanDvmt"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
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
      NAME =
        items("ComSvcUrbanDvmt",
              "ComSvcTownDvmt",
              "ComSvcRuralDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AveRoadUseTaxPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
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
    )
  ),
  Set = items(
    item(
      NAME = "ExtraVmtTax",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Added vehicle mile tax for household vehicle use to pay for any deficit between road costs and road revenues (dollars per vehicle mile)"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for BalanceRoadCostsAndRevenues module
#'
#' A list containing specifications for the BalanceRoadCostsAndRevenues
#' module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source BalanceRoadCostsAndRevenues.R script.
"BalanceRoadCostsAndRevenuesSpecifications"
usethis::use_data(BalanceRoadCostsAndRevenuesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that calculates household VMT
#--------------------------------------------------
#' Calculate household VMT tax to balance road costs and revenues.
#'
#' \code{BalanceRoadCostsAndRevenues} calculates an extra VMT tax needed to
#' balance road costs and road revenues.
#'
#' This function calculates roadway costs that are attributable to households.
#' It compares those costs with the road tax revenues (fuel tax, equivalent tax
#' paid by plug-in vehicles, VMT tax, and congestion charges) and identifies
#' whether the road tax revenues are sufficient to cover costs. If not, it
#' calculates an extra VMT tax rate to cover the costs.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name BalanceRoadCostsAndRevenues
#' @import visioneval
#' @export
#'
BalanceRoadCostsAndRevenues <- function(L) {

  #Calculate household road costs per vehicle mile
  #-----------------------------------------------
  RoadCostPerVehMi <- local({
    Year <- as.numeric(L$G$Year)
    BaseYear <- as.numeric(L$G$BaseYear)
    if (Year > BaseYear) {
      NumYear <- Year - BaseYear
      #Calculate changes in lane miles between year and base year
      FwyLnMiDiff_Ma <- L$Year$Marea$FwyLaneMi - L$BaseYear$Marea$FwyLaneMi
      ArtLnMiDiff_Ma <- L$Year$Marea$ArtLaneMi - L$BaseYear$Marea$ArtLaneMi
      #Set decreases to 0
      FwyLnMiDiff_Ma[FwyLnMiDiff_Ma < 0] <- 0
      ArtLnMiDiff_Ma[ArtLnMiDiff_Ma < 0] <- 0
      #Calculate annual change
      AnnAddFwyLnMi <- sum(FwyLnMiDiff_Ma) / NumYear
      AnnAddArtLnMi <- sum(ArtLnMiDiff_Ma) / NumYear
      #Calculate annual cost
      AnnLnMiAddCost <-
        AnnAddFwyLnMi * L$Year$Region$FwyLnMiCost + AnnAddArtLnMi * L$Year$Region$ArtLnMiCost
      #Calculate portion of lane mile construction cost allocated to household travel
      HhDvmt <- sum(L$Year$Household$Dvmt)
      ComSvcDvmt <-
        with(L$Year$Marea, sum(ComSvcUrbanDvmt, ComSvcTownDvmt, ComSvcRuralDvmt))
      HvyTrkEqDvmt <-
        with(L$Year$Region, HvyTrkPCE * (HvyTrkUrbanDvmt + HvyTrkNonUrbanDvmt))
      HhCostProp <- HhDvmt / (HhDvmt + ComSvcDvmt + HvyTrkEqDvmt)
      #Calculate household lane-mile add cost rate
      LnMiAddCostRate <- (AnnLnMiAddCost * HhCostProp) / (HhDvmt * 365)
    } else {
      LnMiAddCostRate <- 0
    }
    #Calculate total of mileage based costs
    OtherRoadCostRate <-
      with(L$Year$Region, RoadBaseModCost + RoadPresOpMaintCost + RoadOtherCost)
    #Calculate total household road cost per vehicle mile
    LnMiAddCostRate + OtherRoadCostRate
  })

  #Compare road costs per mile to road revenue per mile and export difference
  #--------------------------------------------------------------------------
  #Calculate the average tax rate paid
  AveTaxRate <- with(L$Year$Household, sum(AveRoadUseTaxPM * Dvmt) / sum(Dvmt))
  #Calculate the difference with road cost but set to zero if negative
  ExtraVmtTax <- max((RoadCostPerVehMi - AveTaxRate), 0)

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Region$ExtraVmtTax <- ExtraVmtTax
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("BalanceRoadCostsAndRevenues")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load libraries and test functions
# library(visioneval)
# library(filesstrings)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-RSPM",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "verspm",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "BalanceRoadCostsAndRevenues",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- BalanceRoadCostsAndRevenues(L)

# TestDat_ <- testModule(
#   ModuleName = "BalanceRoadCostsAndRevenues",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

