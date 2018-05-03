#=====================
#BudgetHouseholdDvmt.R
#=====================
#This module adjusts average household DVMT to keep the quantity within
#household operating cost limits. The limit for each household is calculated in
#several steps. First, the proportion of the household's income that may be
#spent on vehicle operating costs is calculated using a model that is explained
#below. This is called the budget proportion. Then an adjusted household income
#for budget calculation purposes is calculated by adding the annual cost of
#insurance for households subscribing to payd-as-you-drive (PAYD) insurance,
#cash-out parking payments for workers who work at an employer that has
#cash-out-buy-back parking, and any vehicle ownership cost savings for
#households that substitute high level car service for one or more household
#vehicles. The adjusted household income is muliplied by the budget proportion
#and divided by the average vehicle operating cost per mile for the household
#to determine the maximum household DVMT that fits within the household budget.
#The household DVMT is then set at the lesser of this budget maximum or the
#modeled household DVMT.
#
#The budget proportion model is estimated using data from the Bureau of Labor's
#consumer expenditure survey for the years from 2003 to 2015. The data used
#are the nominal dollar expenditures by household income category and year
#by transportation category. The values for the operating cost categories
#(gas and oil, and maintenance and repair) are summed and then divided by the
#midpoint value for each income category to calculate the budget proportion for
#each income group and each year. From this the mean value is computed for each
#income group. The budget proportions for each income group and year are
#divided by the mean values by income group to normalize values. The standard
#deviation for the combined normalized values is computed and value of 3
#deviations above the mean is set as the maximum normalized value. The mean
#values by income group are multiplied by this normalized maximum to derive a
#budget proportion maximum by income group. A smoothed splines model of the
#budget proportion as a function of income is then estimated from the calculated
#budget proportion maximums. This model is used to calculate the budget
#proportion for a household based on the household income. The minimum and
#maximum values of the calculated budget proportion maximums are used as
#constraints to avoid unreasonable results for very low incomes and very high
#incomes.


#=================================
#Packages used in code development
#=================================
#Load other packages that this module uses using CALL function
library(VEHouseholdTravel)
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#Load data on consumer expenditures on transportation
#----------------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = items(
      "SeriesID",
      "ExpenseCategory",
      "IncomeGroup"),
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "BottomIncome",
      "TopIncome",
      "Y2003",
      "Y2004",
      "Y2005",
      "Y2006",
      "Y2007",
      "Y2008",
      "Y2009",
      "Y2010",
      "Y2011",
      "Y2012",
      "Y2013",
      "Y2014",
      "Y2015"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process transportation expenditure data
Exp_df <-
  processEstimationInputs(
    Inp_ls,
    "ces-trans-exp-by-category-income-2003to2015.csv",
    "BudgetHouseholdDvmt.R")
rm(Inp_ls)

#Evaluate vehicle operating costs as proportion of income
#--------------------------------------------------------
#Calculate the midpoint income values for each income group
MidInc_ <- (Exp_df$BottomIncome + Exp_df$TopIncome) / 2
#Calculate expenses as proportion of income
Yr <- paste0("Y", 2003:2015)
ExpProp_df <- Exp_df
ExpProp_df[,Yr] <- sweep(Exp_df[,Yr], 1, MidInc_, "/")
#Split expenditure proportions data frame by expense category
ExpProp_ls <- split(ExpProp_df[,Yr], ExpProp_df$ExpenseCategory)
#Convert each component data frame to a matrix
Ig <- ExpProp_df$IncomeGroup[1:13]
ExpProp_ls <- lapply(ExpProp_ls, function(x) {
  x <- as.matrix(x)
  rownames(x) <- Ig
  colnames(x) <- 2003:2015
  x
})
#Sum operating cost category matrices to get operating cost by income and year
#These are gas and oil, and maintenance and repair
#Note that insurance and financing are considered part of ownership cost in the
#model
OpProp_IgYr <- ExpProp_ls[["Gas/Oil"]] + ExpProp_ls[["Maintenance/Repair"]]
#Calculate the mean and maximum operating cost proportions for each income group
MeanOpProp_Ig <- apply(OpProp_IgYr, 1, mean)
MaxOpProp_Ig <- apply(OpProp_IgYr, 1, max)
#Plot the values, note that the curves look like an inverse distribution
#The values for the lowest income group are unreasonably high
Inc_ <- MidInc_[1:13]
# Ylim_ <- c(0, max(MaxOpProp_Ig))
# plot(Inc_, MeanOpProp_Ig, type = "l")
# lines(Inc_, MaxOpProp_Ig, col = "red")
#Drop the lowest income group (< $5,000) value
Inc_ <- Inc_[-1]
OpProp_IgYr <- OpProp_IgYr[-1,]
MeanOpProp_Ig <- MeanOpProp_Ig[-1]
#Normalize operating cost proportions and evaluate distribution of whole
#normalized set
NormOpProp_IgYr <- sweep(OpProp_IgYr, 1, MeanOpProp_Ig, "/")
NormOpProp_ <- as.vector(NormOpProp_IgYr)
# plot(density(NormOpProp_))
#Calculate a maximum normalized operating proportion that is 3 sd above the mean
MaxRatio <- 1 + 3 * sd(NormOpProp_)
#Calculate the maximum operating proportion for each income group
MaxOpProp_Ig = MeanOpProp_Ig * MaxRatio
#Estimate a smooth spline model of the maximum operating cost proportion
MaxOpProp_SS <- smooth.spline(Inc_, MaxOpProp_Ig, df = 10)
#Plot the maximum operating proportion and the smooth spline model value
# plot(Inc_, MaxOpProp_Ig, type = "l")
# lines(Inc_, predict(MaxOpProp_SS)$y, col = "red")
#Calculate the maximum value for low income households
MaxValue <- max(predict(MaxOpProp_SS)$y)
#Calculate the minimum values for high income households
MinValue <- min(predict(MaxOpProp_SS)$y)

#Save the model of the maximimum operating cost proportion of income
#-------------------------------------------------------------------
BudgetModel_ls <- list(
  MaxOpProp_SS = MaxOpProp_SS,
  MaxValue = MaxValue,
  MinValue = MinValue
)
#' Household vehicle operating cost budget model
#'
#' A smooth spline model to predict the maximum operating cost budget as a function of income and a maximum value to use for very low income households.
#'
#' @format A list:
#' \describe{
#'   \item{MaxOpProp_SS}{a smooth spline model to predict the maximum operating cost proportion of income}
#'   \item{MaxValue}{a scalar value that is the maximum proportion}
#' }
#' @source BudgetHouseholdDvmt.R script.
"BudgetModel_ls"
devtools::use_data(BudgetModel_ls, overwrite = TRUE)
rm(Exp_df, ExpProp_ls, NormOpProp_IgYr, OpProp_IgYr, ExpProp_df, Inc_,
   Ig, MaxOpProp_Ig, MaxRatio, MeanOpProp_Ig, MidInc_, NormOpProp_, Yr,
   MaxOpProp_SS, MaxValue, MinValue)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
BudgetHouseholdDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Marea",
  #Specify new tables to be created by Inp if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural")
    ),
    item(
      NAME = "AveVehCostPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "OwnCostSavings",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HasPaydIns",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1)
    ),
    item(
      NAME = "AveGPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GGE/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AveKWHPM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "AveCO2ePM",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "IsCashOut",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1)
    ),
    item(
      NAME = "ParkingCost",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PaysForParking",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1)
    ),
    item(
      NAME = "HhId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "InsCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by the household in autos or light trucks"
    ),
    item(
      NAME = "UrbanHhDvmt",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled in autos or light trucks by households residing in the urbanized portion of the Marea"
    ),
    item(
      NAME = "RuralHhDvmt",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled in autos or light trucks by households residing in the non-urbanized portion of the Marea"
    ),
    item(
      NAME = "DailyGGE",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GGE/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Gasoline equivalent gallons consumed per day by household vehicle travel"
    ),
    item(
      NAME = "DailyKWH",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "KWH/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Kilowatt-hours consumed per day by household vehicle travel"
    ),
    item(
      NAME = "DailyCO2e",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Grams of carbon-dioxide equivalents produced per day by household vehicle travel"
    ),
    item(
      NAME =
        items("WalkTrips",
              "BikeTrips",
              "TransitTrips"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average number of walk trips per year by household members",
        "Average number of bicycle trips per year by household members",
        "Average number of public transit trips per year by household members"
      )
    ),
    item(
      NAME = "VehicleTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "TRIP/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average number of vehicle trips per day by household members"
    )
  ),
  #Specify call status of module
  Call = items(
    CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt",
    ReduceDvmt = "VEHouseholdTravel::ApplyDvmtReductions",
    CalcVehTrips = "VEHouseholdTravel::CalculateVehicleTrips",
    CalcAltTrips = "VEHouseholdTravel::CalculateAltModeTrips"
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for BudgetHouseholdDvmt module
#'
#' A list containing specifications for the BudgetHouseholdDvmt module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#'  \item{Call}{modules that are called by the module}
#' }
#' @source BudgetHouseholdDvmt.R script.
"BudgetHouseholdDvmtSpecifications"
devtools::use_data(BudgetHouseholdDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates household DVMT and adjusts it based on vehicle travel
#costs to fit within the household budget. It also computes household vehicle
#trips and alternative mode trips. Urban and rural DVMT are recalculated.

#Main module function that calculates vehicle travel
#---------------------------------------------------
#' Calculate household DVMT and adjusts based on budget and calculates trips
#'
#' \code{BudgetHouseholdDvmt} calculate the average household DVMT, adjusts it
#' to fit within the household budget, and calculates vehicle trips and
#' alternative mode trips.
#'
#' This function calculates the average household DVMT and adjusts it to fit
#' within the household budget. Using the adjusted DVMT and other
#' characteristics, the module also calculates household vehicle trips and
#' alternative mode trips. It also recalculates urban and rural DVMT.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @param M A list the module functions of modules called by this module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
BudgetHouseholdDvmt <- function(L, M) {

  #Calculate household budget proportion of income
  #-----------------------------------------------
  BudgetProp_Hh <- with(BudgetModel_ls, {
    Prop_ <- predict(MaxOpProp_SS, L$Year$Household$Income)$y
    Prop_[Prop_ > MaxValue] <- MaxValue
    Prop_[Prop_ < MinValue] <- MinValue
    Prop_
  })

  #Calculate adjusted household income for calculating vehicle operations budget
  #-----------------------------------------------------------------------------
  AdjIncome_Hh <- local({
    #Cash out parking adjustments
    CashOutAdj_Wk <-
      with(L$Year$Worker, ParkingCost * IsCashOut * PaysForParking)
    CashOutAdj_Hh <-
      tapply(CashOutAdj_Wk, L$Year$Worker$HhId, sum)[L$Year$Household$HhId]
    CashOutAdj_Hh[is.na(CashOutAdj_Hh)] <- 0
    #Pay as you drive insurance adjustment
    InsCost_Hh <-
      tapply(L$Year$Vehicle$InsCost, L$Year$Vehicle$HhId, sum)[L$Year$Household$HhId]
    InsCostAdj_Hh <- InsCost_Hh * L$Year$Household$HasPaydIns
    #Ownership cost savings (for households substituting car service)
    OwnCostSavings_Hh <- L$Year$Household$OwnCostSavings
    #Sum the household income and adjustments
    L$Year$Household$Income + OwnCostSavings_Hh + CashOutAdj_Hh +
      InsCostAdj_Hh
  })

  #Apply the DVMT model and TDM and SOV reductions
  #-----------------------------------------------
  #Run the household DVMT model
  Dvmt_Hh <- M$CalcDvmt(L$CalcDvmt)$Year$Household$Dvmt
  #Reduce DVMT to account for TDM and SOV reductions
  L$ReduceDvmt$Year$Household$Dvmt <- Dvmt_Hh
  Dvmt_Hh <- M$ReduceDvmt(L$ReduceDvmt)$Year$Household$Dvmt

  #Calculate the budget-adjusted household DVMT
  #--------------------------------------------
  Adj_ls <- local({
    #Calculate budget based on the adjusted income
    VehOpBudget_Hh <- AdjIncome_Hh * BudgetProp_Hh
    #Calculate the DVMT which fits in budget given DVMT cost per mile
    BudgetDvmt_Hh <- VehOpBudget_Hh / L$Year$Household$AveVehCostPM / 365
    #Adjusted DVMT is the minimum of the 'budget' DVMT and 'modeled' DVMT
    AdjDvmt_Hh <- pmin(BudgetDvmt_Hh, Dvmt_Hh)
    #Establish a lower minimum to avoid zero values
    MinDvmt <- quantile(AdjDvmt_Hh, 0.01)
    AdjDvmt_Hh[AdjDvmt_Hh < MinDvmt] <- MinDvmt
    #Calculate adjusted urban and rural DVMT for the Marea
    IsUbz_Hh <- L$Year$Household$DevType == "Urban"
    UrbanDvmt <- sum(AdjDvmt_Hh[IsUbz_Hh])
    RuralDvmt <- sum(AdjDvmt_Hh[!IsUbz_Hh])
    #Return list of results
    list(
      Dvmt_Hh = AdjDvmt_Hh,
      UrbanDvmt = UrbanDvmt,
      RuralDvmt = RuralDvmt
    )
  })

  #Calculate household vehicle trips and alternative mode trips
  #------------------------------------------------------------
  #Calculate vehicle trips
  L$CalcVehTrips$Year$Household$Dvmt <- Adj_ls$Dvmt_Hh
  VehicleTrips_Hh <- M$CalcVehTrips(L$CalcVehTrips)$Year$Household$VehicleTrips
  #Calculate alternative mode trips
  L$CalcAltTrips$Year$Household$Dvmt <- Adj_ls$Dvmt_Hh
  AltTrips_ls <- M$CalcAltTrips(L$CalcAltTrips)$Year$Household



  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    Dvmt = Adj_ls$Dvmt_Hh,
    DailyGGE = Adj_ls$Dvmt_Hh * L$Year$Household$AveGPM,
    DailyKWH = Adj_ls$Dvmt_Hh * L$Year$Household$AveKWHPM,
    DailyCO2e = Adj_ls$Dvmt_Hh * L$Year$Household$AveCO2ePM,
    VehicleTrips = VehicleTrips_Hh,
    WalkTrips = AltTrips_ls$WalkTrips,
    BikeTrips = AltTrips_ls$BikeTrips,
    TransitTrips = AltTrips_ls$TransitTrips)
  Out_ls$Year$Marea <- list(
    UrbanHhDvmt = Adj_ls$UrbanDvmt,
    RuralHhDvmt = Adj_ls$RuralDvmt)
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
#   ModuleName = "BudgetHouseholdDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# M <- TestDat_$M
# R <- BudgetHouseholdDvmt(L, M)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "BudgetHouseholdDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
