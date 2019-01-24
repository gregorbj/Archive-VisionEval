#=====================
#BudgetHouseholdDvmt.R
#=====================

#<doc>
#
## BudgetHouseholdDvmt Module
#### January 23, 2019
#
#This module adjusts average household DVMT to keep the quantity within the limit of the household vehicle operating cost budget. A linear regression model is applied to calculate the maximum proportion of income that the household is willing to pay for vehicle operations. This proportion is multiplied by household income (with adjustments explained below) to calculate the maximum amount the household is willing to spend. This is compared to the vehicle operating cost calculated for the household. If the household vehicle operating cost is greater than the maximum amount the household is willing to pay, the household DVMT is reduced to fit within the budget.
#
### Model Parameter Estimation
#
#This section describes the estimation of a model to calculate the maximum proportion of household income a household is willing to pay to operate vehicles used by the household. The model is estimated from aggregate data on consumer expenditures published by the U.S. Bureau of Labor Statistics (BLS) collected in the (Consumer Expenditure Survey). The CES data used to estimate the model are included in the 'ces_vehicle_op-cost.csv' file. Documentation of that file is included in the 'ces_vehicle_op-cost.txt' file. The 'ces.R' R script file contains the code used to download the raw CES dataset from the BLS website and process it to produce the dataset in the 'ces_vehicle_op-cost.csv' file.
#
#The CES data document average household expenditures by expenditure category and demographic category. Transportation expenditure categories are:
#
#* New car and truck purchases
#* Used car and truck purchases
#* Other vehicle purchases
#* Gasoline, other fuels, and motor oil
#* Vehicle finance charges
#* Maintenance and repairs
#* Vehicle insurance
#* Vehicle rental, leases, licenses, and other charges
#* Public and other transportation
#
#Expenditures in the 'gasoline, other fuels, and motor oils', 'matenance and repairs', and 'vehicle rental, leases, licenses, and other charges' categories are used to represent the vehicle operating cost budget. Following are description of costs in these categories:
#
#1. Gasoline and motor oil includes gasoline, diesel fuel, and motor oil.
#
#2. Maintenance and repairs includes tires, batteries, tubes, lubrication, filters, coolant, additives, brake and transmission fluids, oil change, brake work including adjustment, front-end alignment, wheel balancing, steering repair, shock absorber replacement, clutch and transmission repair, electrical system repair, exhaust system repair, body work and painting, motor repair, repair to cooling system, drive train repair, drive shaft and rear-end repair, tire repair, audio equipment, other maintenance and services, and auto repair policies.
#
#3. Vehicle rental, leases, licenses, and other charges includes leased and rented cars, trucks, motorcycles, and aircraft; inspection fees; State and local registration; driver's license fees; parking fees; towing charges; tolls; and automobile service clubs.
#
#Annual average expenditures (in nominal dollars) are tabulated by demographic category. Household income categories were used for estimating the budget model. Table 1 shows the income categories, abbreviations used for them, and midpoint values used in model estimation.
#
#| Abbreviation | Annual Before Tax Income | Midpoint Value |
#|---|---|---|
#| LT5K | Less than $5,000 | $2,499.50 |
#| GE5K_LT10K | $5,000 - $9,999 | $7,499.50 |
#| GE10K_LT15K | $10,000 - $14,999 | $12,499.50 |
#| GE15K_LT20K | $15,000 - $19,999 | $17,499.50 |
#| GE20K_LT30K | $20,000 - $29,999 | $24,999.50 |
#| GE30K_LT40K | $30,000 - $39,999 | $34,999.50 |
#| GE40K_LT50K | $40,000 - $49,999 | $44,999.50 |
#| GE50K_LT70K | $50,000 - $69,999 | $59,999.50 |
#| GE70K_LT80K | $70,000 - $79,999 | $74,999.50 |
#| GE80K_LT100K | $80,000 - $99,999 | $89,999.50 |
#| GE100K_LT120K | $100,000 - $119,999 | $109,999.50 |
#| GE120K_LT150K | $120,000 - $149,999 | $134,999.50 |
#| GE150K | $150,000 or more | $174,999.50 |
#
#**Table 1. CES Income Categories and Abbreviations and Midpoint Values Used in Analysis**
#
#CES data for the years from 2003 to 2015 are used in model estimation. 2003 is the first year that the BLS included income subcategories for incomes greater than $70,000. 2015 was the last year for which data were complete when the data were accessed.
#The ratios of average operating cost to average income are calculated by dividing the average operating cost by the income midpoint value for each income group. Since both operating cost and income are in nominal dollars, the result is the proportion of income spent on vehicle operating cost by income group and year. Figure 1 shows the distribution of values by income group over the period from 2003 to 2015.
#
#<fig:op_cost_prop_by_income.png>
#
#**Figure 1. Proportion of Household Income Spent on Vehicle Operating Cost by Income Group for the Years 2003 - 2015**
#
#The values for the lowest income group look unreasonably high and are dropped from further use in developing the model. The values for the highest income group are also dropped because the actual median income for the group is unknown.
#
#The operating cost proportions are normalized by the median proportion for each income group to enable the data to be pooled to compute the budget limit. Figure 2 shows the normalized values by income group over the period. It can be seen that the normalized values for all but the GE5K_LT10K income group follow the same trajectories and have similar values distributions. These are used to develop the model.
#
#<fig:normalized_op_cost.png>
#
#**Figure 2. Normalized Operating Cost Proportion Trends by Income Group**
#
#The distribution of the pooled normalized operating cost data are shown in Figure 3. The distribution is calculated using the R 'density' kernal density estimation function assuming a gaussian probability density function and a bandwidth which implements the methods of Sheather & Jones (1991). The maximum normalized operating cost ratio is calculated as the value that is 3 standard deviations above the mean. The maximum operating cost ratio for each income group is then calculated by multiplying the median operating cost ratio by this maximum normalized ratio.
#
#<fig:normalized_op_cost_dist.png>
#
#**Figure 3. Probability Distribution of Pooled Normalized Operating Cost Ratios**
#
#A log-log linear model is estimated to predict the maximum operating cost ratio as a function of household income. Table 2 shows the model summary statistics. Figure 4 compares the model with the calculated maximum operating cost ratios.
#
#<txt:OpPropModel_ls$Summary>
#
#**Table 2. Summary Statistics for Log-Log Model of Maximum Operating Cost Ratio**
#
#<fig:max_op_prop_lm.png>
#
#**Figure 4. Comparison of Log-Log Model of Maximum Operating Cost Ratio**
#
#Finally, Figure 5 compares the predicted maximum operating cost ratio for each income group (excluding the lowest income group) with the distributions of operating cost ratios for the period from 2003 to 2015 for each income group.
#
#<fig:max_op_cost_predict_model.png>
#
#**Figure 5. Comparison of Maximum Operating Cost Ratio by Income with Observed Operating Cost Ratios**
#
### How the Module Works
#
#The module calculates the household operating cost budget and adjusts household travel to fit within the budget in the following steps:
#
#* The model for calculating the maximum proportion of household income to be spent on vehicle operating cost is applied.
#
#* Household income adjustments are made for the purpose of calculating the maximum operating cost as follows:
#
#  * For workers in a parking cash-out program, their annual work parking costs (calculated by the 'AssignParkingRestrictions' module) are added to household income.
#
#  * For households assigned to pay-as-you-drive insurance, their annual vehicle insurance cost (calculated by the 'CalculateVehicleOwnCost' module) are added to household income.
#
#  * For households that substitute car service vehicle(s) for owned vehicle(s), the annual ownership cost savings (calculated by the 'AdjustVehicleOwnership' module) are added to household income.
#
#* The adjusted household income is multiplied by the maximum operating cost proportion to calculate the household operating cost budget.
#
#* The CalculateHouseholdDvmt module is run to calculate household DVMT.
#
#* The modeled DVMT is compared to the maximum DVMT that the household would travel given the calculated operating cost budget and the average operating cost per vehicle mile calculated by the 'CalculateVehicleOperatingCost' module. If the modeled DVMT is greater than the DVMT that could be traveled within the household budget, the DVMT which fits the budget is substituted for the modeled DVMT. The ApplyDvmtReductions models are run to adjust household DVMT to account for travel demand management programs and user assumptions regarding diversion of single-occupant vehicle travel to bicycles, electric bicycles, scooters, etc.
#
#* The 'CalculateVehicleTrips' and 'CalculateAltModeTrips' modules are run to calculate the number of household vehicle trips and alternative mode trips (walk, bike, transit) to be consistent with the adjusted DVMT.
#
#</doc>

#=================================
#Packages used in code development
#=================================
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
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = "NA",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "LT5K",
      "GE5K_LT10K",
      "GE10K_LT15K",
      "GE15K_LT20K",
      "GE20K_LT30K",
      "GE30K_LT40K",
      "GE40K_LT50K",
      "GE50K_LT70K",
      "GE70K_LT80K",
      "GE80K_LT100K",
      "GE100K_LT120K",
      "GE120K_LT150K",
      "GE150K"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process vehicle operations cost data
Exp_df <-
  processEstimationInputs(
    Inp_ls,
    "ces_vehicle_op-cost.csv",
    "BudgetHouseholdDvmt.R")
Exp_YrIg <- as.matrix(Exp_df[,-1])
rownames(Exp_YrIg) <- Exp_df$Year
rm(Exp_df, Inp_ls)

#Evaluate vehicle operating costs as proportion of income
#--------------------------------------------------------
#Calculate the midpoint income values for each income group
FloorInc_ <- c(0, 5, 10, 15, 20, 30, 40, 50, 70, 80, 100, 120, 150)* 1000
TopInc_ <- c(FloorInc_[-1] - 1, 199999)
MidInc_ <- (FloorInc_ + TopInc_) / 2
rm(FloorInc_, TopInc_)
#Calculate ratio of expenditures to income
OpProp_YrIg <- sweep(Exp_YrIg, 2, MidInc_, "/")
rm(Exp_YrIg)
#Transpose matrix
OpProp_IgYr <- t(OpProp_YrIg)
#Calculate the mean and maximum operating cost proportions for each income group
MedianOpProp_Ig <- apply(OpProp_IgYr, 1, median)
#Plot the values, note that the curves look like an inverse distribution
#The values for the lowest income group are unreasonably high and the highest
#are unreasonably low
png("data/op_cost_prop_by_income.png", width = 480, height = 480)
Opar_ls <- par(las = 3, mar=c(8.1,5.1,3.1,2.1))
boxplot(OpProp_YrIg,
        ylab = "Vehicle Operating Cost\nProportion of Income")
par(Opar_ls)
rm(Opar_ls)
dev.off()
#Normalize operating cost proportions by median for each income group
#Exclude the lowest and highest income groups
Exclude <- -c(1,length(MidInc_))
NormOpProp_IgYr <- sweep(OpProp_IgYr[Exclude,], 1, MedianOpProp_Ig[Exclude], "/")
#Plot the normalized values by year and income group
png("data/normalized_op_cost.png", width = 480, height = 480)
Col_ <- rainbow(12)
matplot(2003:2015, t(NormOpProp_IgYr), type = "b", pch = 20, lty = 1, col = Col_,
        xlab = "Year", ylab = "Ratio with Income Group Median", bg = "gray")
legend("bottomright", pch = 20, col = Col_, bty = "n",
       legend = rownames(NormOpProp_IgYr), cex = 0.8)
rm(Col_)
dev.off()
#Calculate density distribution of the normalized operations costs
NormOpProp_ <- as.vector(NormOpProp_IgYr[-1,])
rm(NormOpProp_IgYr)
DensityNormOpProp_ls <- density(as.vector(NormOpProp_), bw = "SJ")
png("data/normalized_op_cost_dist.png", width = 480, height = 480)
plot(DensityNormOpProp_ls)
dev.off()
#Calculate a maximum normalized ratio
#MaxRatio <- max(DensityNormOpProp_ls$x)
MaxRatio <- 1 + 3 * sd(NormOpProp_)
rm(NormOpProp_, DensityNormOpProp_ls)
#Calculate the maximum operating proportion for each income group
MaxOpProp_Ig = MedianOpProp_Ig * MaxRatio
#Estimate a model of the maximum operating proportion
LogMaxProp <- log(MaxOpProp_Ig)
LogInc <- log(MidInc_)
MaxOpProp_LM <- lm(LogMaxProp ~ LogInc)
png("data/max_op_prop_lm.png", width = 480, height = 480)
plot(LogInc, LogMaxProp, xlab = "Natural Log of Income",
     ylab = "Natural Log of Maximum Operating Cost Proportion")
abline(MaxOpProp_LM, col = "red", lty = 2)
dev.off()
rm(MaxOpProp_Ig, LogMaxProp, LogInc)
#Calculate the maximum operations proportion by income
MaxPredOpProp_Ig <-
  exp(predict(MaxOpProp_LM, newdata = data.frame(LogInc = log(MidInc_))))
#Plot the median operating proportion and the smooth spline model value of maximum
png("data/max_op_cost_predict_model.png", width = 480, height = 480)
Opar_ls <- par(las = 3, mar=c(8.1,5.1,3.1,2.1))
boxplot(OpProp_YrIg[,-1],
        ylab = "Vehicle Operating Cost\nProportion of Income")
lines(1:length(MaxPredOpProp_Ig[-1]), MaxPredOpProp_Ig[-1], col = "blue", type = "b", lty = 2)
legend("topright", col = "blue", lty = 2, bty = "n", legend = "Maximum Proportion", pch = 1, pt.bg = "white")
par(Opar_ls)
rm(Opar_ls, OpProp_IgYr, OpProp_YrIg)
dev.off()
#Calculate the maximum values for low income households
MaxValue <- max(MaxPredOpProp_Ig)
#Document maximum ratio and maximum value
MaxVals_df <-
  data.frame(MaxRatio = round(MaxRatio, 2), MaxProp = round(MaxValue, 2))


#Save the model of the maximimum operating cost proportion of income
#-------------------------------------------------------------------
#Create a list which implements the operation cost proportions model
OpPropModel_ls <-   list(
  Type = "linear",
  Formula = makeModelFormulaString(MaxOpProp_LM),
  PrepFun = function(Inc_) data.frame(LogInc = log1p(Inc_), Intercept = 1),
  OutFun = function(Result_) pmin(exp(Result_), 0.75),
  Summary = capture.output(summary(MaxOpProp_LM)),
  MaxVals_df = MaxVals_df
)
rm(MaxPredOpProp_Ig, MedianOpProp_Ig, MidInc_, MaxRatio, MaxValue)
rm(MaxOpProp_LM, MaxVals_df)
#' Household vehicle operating cost proportion of income model
#'
#' A list in the format required by the applyLinearModel function. The list
#' implements a linear model which predicts the maximum proportion of income
#' that a household is willing to spend on vehicle operating costs.
#'
#' @format A list:
#' \describe{
#'   \item{Type}{a string identifying the model type}
#'   \item{Formula}{a string specifying the model formula}
#'   \item{PrepFun}{a function to transform function input (i.e. income)}
#'   \item{OutFun}{a function to transform model output (i.e. to produce proportion)}
#'   \item{Summary}{summary statistics of linear model}
#' }
#' @source BudgetHouseholdDvmt.R script.
"OpPropModel_ls"
usethis::use_data(OpPropModel_ls, overwrite = TRUE)


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
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
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
      NAME = items(
        "UrbanHhDvmt",
        "RuralHhDvmt",
        "TownHhDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average daily vehicle miles traveled in autos or light trucks by households residing in urban locations of the Marea",
        "Average daily vehicle miles traveled in autos or light trucks by households residing in rural locations of the Marea",
        "Average daily vehicle miles traveled in autos or light trucks by households residing in town locations of the Marea")
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
    CalcDvmt = "CalculateHouseholdDvmt",
    ReduceDvmt = "ApplyDvmtReductions",
    CalcVehTrips = "CalculateVehicleTrips",
    CalcAltTrips = "CalculateAltModeTrips"
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
usethis::use_data(BudgetHouseholdDvmtSpecifications, overwrite = TRUE)


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
#' @name BudgetHouseholdDvmt
#' @import visioneval
#' @export
BudgetHouseholdDvmt <- function(L, M) {

  #Calculate household budget proportion of income
  #-----------------------------------------------
  BudgetProp_Hh <- applyLinearModel(OpPropModel_ls, L$Year$Household$Income)

  #Calculate adjusted household income for calculating vehicle operations budget
  #-----------------------------------------------------------------------------
  AdjIncome_Hh <- local({
    #Cash out parking adjustments
    CashOutAdj_Wk <-
      with(L$Year$Worker, ParkingCost * IsCashOut * PaysForParking)
    CashOutAdj_Hh <-
      tapply(CashOutAdj_Wk, L$Year$Worker$HhId, sum)[L$Year$Household$HhId]
    CashOutAdj_Hh <- 365 * CashOutAdj_Hh #Convert daily to annual
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

  #Apply the DVMT model
  #-----------------------------------------------
  #Run the household DVMT model
  Dvmt_Hh <- M$CalcDvmt(L$CalcDvmt)$Year$Household$Dvmt

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
    #Reduce DVMT to account for TDM and SOV reductions
    L$ReduceDvmt$Year$Household$Dvmt <- AdjDvmt_Hh
    AdjDvmt_Hh <- M$ReduceDvmt(L$ReduceDvmt)$Year$Household$Dvmt
    #Calculate adjusted urban and rural DVMT for the Marea
    UrbanDvmt <- sum(AdjDvmt_Hh[L$Year$Household$LocType == "Urban"])
    RuralDvmt <- sum(AdjDvmt_Hh[L$Year$Household$LocType == "Rural"])
    TownDvmt <- sum(AdjDvmt_Hh[L$Year$Household$LocType == "Town"])
    #Return list of results
    list(
      Dvmt_Hh = AdjDvmt_Hh,
      UrbanDvmt = UrbanDvmt,
      TownDvmt = TownDvmt,
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
    TownHhDvmt = Adj_ls$TownDvmt,
    RuralHhDvmt = Adj_ls$RuralDvmt)
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("BudgetHouseholdDvmt")

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
