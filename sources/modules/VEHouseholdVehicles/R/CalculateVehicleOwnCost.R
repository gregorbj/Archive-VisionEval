#=========================
#CalculateVehicleOwnCost.R
#=========================
#
#<doc>
#
## AssignVehicleType Module
#### November 23, 2018
#
#This module calculates average vehicle ownership cost for each vehicle based on the vehicle type and age using data from the American Automobile Association (AAA). To this are added the cost of parking at the vehicle residence if free parking is not available for all household vehicles. The ownership cost is converted into an average ownership cost per mile by predicting the household DVMT given the number of owned vehicles and splitting the miles equally among the vehicles. Vehicle ownership costs are used by the AdjustVehicleOwnership module to determine whether it would be more cost-effective for a household to substitute the use of car services for one or more of vehicles that they otherwise would own.
#
#The module also assigns pay-as-you-drive (PAYD) insurance to households based on household characteristics and input assumption about the proportion of households who have PAYD insurance. PAYD insurance does not affect the cost of vehicle ownership when determining whether a household will substitute car services for one or more of their vehicles. It does affect the operating cost of the vehicle and determination of whether the amount of vehicle travel fits within the household's vehicle operations budget.
#
### Model Parameter Estimation
#
#Vehicle ownership cost data from the American Automobile Association (AAA) are used along with information on vehicle depreciation rates to develop a model of vehicle ownership cost as a function of vehicle type, vehicle age, and miles driven.
#
#The AAA cost data is described in the *aaa_vehicle_ownership_costs.txt* file in the *inst/extdata* directory of this package. Data are included on insurance, license/registration/taxes, finance, and depreciation (at 3 annual mileage rates) for 7 light duty body types (small sedan, medium sedan, large sedan, small SUV, medium SUV, minivan, and pickup). Data are also included for hybrids and electric vehicles but these are not used in the model because these vehicle types are relatively new (especially electric vehicles) and are not split out by body type. The following table show these data which are for the year [2017](http://exchange.aaa.com/wp-content/uploads/2017/08/17-0013_Your-Driving-Costs-Brochure-2017-FNL-CX-1.pdf).
#
#<tab:VehOwnCost_ls$AAAOwnCost_df>
#
#The AAA data body type values are aggregated into vehicle type (auto, light truck) values by taking the midpoint of the range of values for the body types corresponding to each vehicle type. The values for the 3 sedan body types are aggregated to calculate the auto type value. Likewise, the values for the 4 other body types are aggregated to calculate the light truck type value.
#
#Building an ownership cost model requires additional information because the AAA data only address cost during the first 5 years of a vehicle's life and only 3 levels for annual miles driven whereas the cost model needs to address vehicles up to 30 years old and a continuous range of annual vehicle miles driven. The model is created by combining the AAA data with average vehicle depreciation rate data from the [National Automobile Dealers Association *Used Vehicle Price Report: Age-level Analysis and Forecast, Q3 2013*](https://www.nada.com/b2b/Portals/0/assets/pdf/Q3%20Whitepaper%20Age-level%20Analysis%20and%20Forecast.pdf). This report estimates that light-duty vehicles depreciate at an average rate of 15% per year.
#
#The first step in building a model is to calculate the average vehicle value by year and body type for vehicles having a midrange value for annual mileage (15,000). This starts with calculating the new car value for each of the body types. To do this, the total depreciation for the first five years is calculated by multiplying the reported annual depreciation values by 5 since the AAA data represent annual costs over the first 5 years of the vehicle life. From that, the corresponding new vehicle value is calculated using the assumed annual depreciation rate of 15%. The new vehicle values by vehicle type (auto, light truck) are computed by taking the midpoint of the ranges of the the corresponding body types. The following table shows the estimated 2017 new car prices by body type and vehicle type.
#
#<tab:VehOwnCost_ls$BasePrice_df>
#
#Once the new car value by vehicle type has been calculated, the values by vehicle age are computed by applying the annual depreciation rate. Then the annual depreciation values are computed as the differences in annual vehicle values. The following figure illustrates the annual depreciation for auto and light truck that are driven 15,000 miles per year.
#
#<fig:depreciation_expense.png>
#
#The depreciation models adjusts depreciation to account for the effect of miles driven. As can be seen from the examination of the AAA data, depreciation increases at an increasing rate as annual mileage increases. To account for the effect of miles driven on depreciation, a linear model is estimated to predict the ratio of depreciation at the annual mileage driven to depreciation at 15,000 miles driven. This model is used to adjust the depreciation schedule shown in the figure above. The steps in creating this depreciation adjustment model are as follows:
#
#* The AAA data on depreciation by body type and mileage is aggregated to the vehicle types (auto, light truck) by taking the midpoint of the range of values for the corresponding body types.
#
#* The ratios of annual depreciation to depreciation at 15,000 miles are calculated.
#
#* The relationship between mileage and depreciation ratio is linearized by power-transforming the mileage. Mileage is divided by 1000 to reduce the size of the power-transformed result. The linearizing power transform is estimated using binary search to find the value at which the slopes are equal.
#
#* A linear regression model is estimated to find the slope and intercept of the line describing the relationship between mileage and relative depreciation.
#
#The following figure illustrates the resulting estimated relationship between depreciation and miles driven for 5-year old autos and light trucks.
#
#<fig:depreciation_by_annual_miles.png>
#
#A finance cost model calculates finance cost as a function of the vehicle age. To estimate this model, first the AAA values for finance cost by body type are aggregated to vehicle types. This is done by taking the midpoint values of the body types that correspond to each vehicle type. Since the AAA data represent the first 5 years of a vehicle's life and since auto loans typically have a duration of 5 years, it is assumed that the AAA data represent the average finance cost for a new vehicle. Therefore the annual finance cost for different vehicle can be calculated by multiplying the new car finance cost by the estimated proportion of new car value for the vehicle age. It is important to note that finance cost is the cost of financing the vehicle loan, not the cost of purchasing the car. Depreciation accounts for purchase cost and residual value.
#
#To calculate the cost of insurance, the AAA values for insurance cost by body type are aggregated to vehicle types in the manner described above. Since insurance cost is largely a function of driver characteristics (e.g. age) and weakly related to vehicle value, no adjustments are made to the AAA values as a function of vehicle value.
#
#The module also identifies which households are assigned to pay-as-you-drive (PAYD) insurance to satisfy user input on the proportion of households having that type of insurance. PAYD insurance is limited to 1996 or later model years because it requires OBD-II ports that were made mandatory on all vehicles in that year. This model has no estimated parameters, rather it weights various household characteristics based on judgements regarding the relative value of PAYD insurance to different users based on reviewing the literature. Undoubtedly there are correlations between the factors and therefore potential for double-counting, but substantially more data and study is required to sort out the effects. The characteristics and relative weights are as follows:
#
#* Teen Drivers (2 points) - households with one or more teenage drivers are benefitted by the monitoring and feedback provided by the technology;
#
#* Lower Mileage (3 points) - PAYD insurance is relatively more economical for households that have relatively low annual mileage (less than 15,000 miles per vehicle);
#
#* Older Adult Drivers (2 points) - Households with older adult drivers (30 or older) are more likely to use than households with younger adult drivers;
#
#* Lower Income (2 points) - Lower income households are more likely to use because of the lower costs and ability to moderate behavior to save additional money. Low income threshold is an annual household income of $45,000 in 2005 dollars.
#
#* Auto Proportion (2 points) - Households owning automobiles are more likely to use than households owning light trucks; and,
#
#* In Metropolitan Area (3 points) - Households in metropolitan areas are more likely to use.
#
### How the Module Works
#
#The module loads data on the type and age of each vehicle. It calls the CalculateHouseholdVmt module to calculate average daily vehicle miles traveled for each household. This is converted to annual miles and split equally among household vehicles. The depreciation model is applied to calculate vehicle depreciation cost as a function of the vehicle type, the vehicle age, and annual miles driven. The finance cost model is applied to calculate the finance cost as a function of the vehicle type and age. The insurance cost is calculated as a function of the vehicle type. Vehicle licensing/registration/tax costs are not calculated from the AAA values because these values can vary substantially by state and because they may changed to implement policy objectives. The user provides inputs for flat fees/taxes (i.e. annual cost per vehicle) and ad valorem taxes (i.e. percentage of vehicle value paid in taxes). The flat fees/taxes are applied to each vehicle. The ad valorem taxes are calculated by multiplying the vehicle value, which varies by type and age, by the tax rate. The module also loads household residential parking cost data calculated by the AssignParkingRestrictions module. The household parking costs are split equally among vehicles. Total ownership cost for each vehicle is then calculated by summing the depreciation, finance, insurance, fees/taxes, and parking costs. Total ownership cost is divided by vehicle miles to calculate the cost of ownership per mile of travel.
#
#The module also identifies which households will be assigned PAYD insurance given user inputs on the proportion of households having PAYD insurance. The module identifies which households qualify for PAYD insurance based on whether any of their vehicles are 1996 model year vehicles or later. The vehicle and household characteristics (identified above) are evaluated and points assigned. The total points are calculated for each households. Random sampling is used to choose a number of households to equal the input proportion where the probability that each household is chosen is a function of the ratio of the household weight to the maximum household weight.
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

#----------------------------
#Vehicle ownership cost model
#----------------------------
#Vehicle ownership cost data from the American Automobile Association (AAA) are
#used along with information on vehicle depreciation rates to develop a model of
#vehicle ownership cost as a function of vehicle type, vehicle age, and miles
#driven.

#Create a list for retaining ownership cost model information
#------------------------------------------------------------
VehOwnCost_ls <- list()

#AAA vehicle ownership cost data
#-------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Category",
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "SmallSedan",
      "MediumSedan",
      "LargeSedan",
      "SmallSUV",
      "MediumSUV",
      "Minivan",
      "Pickup"),
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process AAA vehicle ownership cost data
OwnCost_df <-
  processEstimationInputs(
    Inp_ls,
    "aaa_vehicle_ownership_costs.csv",
    "CalculateVehicleOwnCost.R")
rownames(OwnCost_df) <- OwnCost_df$Category
OwnCost_df <- OwnCost_df[,-1]
rm(Inp_ls)
#Save the AAA ownership cost information for documentation purposes
VehOwnCost_ls$AAAOwnCost_df <- OwnCost_df

#Vehicle depreciation rate
#-------------------------
#According to the National Automobile Dealers Association (NADA), the value of
#automobiles and light trucks depreciate at about 15% per year.
#National Automobile Dealers Association (2013),
#NADA Used Vehicle Price Report: Age-level Analysis and Forecast, Q3 2013,
#https://www.nada.com/b2b/Portals/0/assets/pdf/Q3%20Whitepaper%20Age-level%20Analysis%20and%20Forecast.pdf.
DeprRate <- 0.15

#Calculate annual depreciation cost by vehicle age and vehicle type
#------------------------------------------------------------------
#Identify the body types assigned to each vehicle type
AutoBodyTypes_ <- c("SmallSedan", "MediumSedan", "LargeSedan")
LtTrkBodyTypes_ <- c("SmallSUV", "MediumSUV", "Minivan", "Pickup")
#Depreciation by body type
Depr_MiBt <- as.matrix(OwnCost_df[
  c("Depreciation10KPerYear", "Depreciation15KPerYear", "Depreciation20KPerYear"),
  c(AutoBodyTypes_ , LtTrkBodyTypes_)
])
rownames(Depr_MiBt) <- c("10K", "15K", "20K")
#Calculate baseline (15K annual miles) depreciation for 5 years
BaseDepr_Bt <- unlist(Depr_MiBt["15K",]) * 5
#Calculate the proportion of new value after 5 years assuming 15% dep. rate
Dep5YrProp <- (1 - DeprRate) ^ 5
#Calculate the new price given 15% depreciation by year
BasePrice_Bt <- BaseDepr_Bt / (1 - Dep5YrProp)
#Calculate the base price by vehicle type as the midpoint of the body types
BasePrice_Vt <- c(
  Auto = mean(range(BasePrice_Bt[AutoBodyTypes_])),
  LtTrk = mean(range(BasePrice_Bt[LtTrkBodyTypes_]))
)
#Document base price in a table
VehOwnCost_ls$BasePrice_df <- data.frame(
  Body = names(c(BasePrice_Bt, BasePrice_Vt)),
  Price = paste0("$",
                 formatC(c(BasePrice_Bt, BasePrice_Vt), format = "f", digits = 0, big.mark = ","))
)
#Calculate proportion of new car value by age given 15% depreciation rate
Ag <- 1:31
PropNewValue_Ag <- sapply(Ag, function(x) (1 - DeprRate)^(x - 1))
#Calculate car value by vehicle age and vehicle type
Value_AgVt <- outer(PropNewValue_Ag, BasePrice_Vt, "*")
#Calculate depreciation by vehicle age and vehicle type
Depr_AgVt <- round(-apply(Value_AgVt, 2, diff))
#Document depreciation by year
png("data/depreciation_expense.png", width = 480, height = 480)
matplot(Depr_AgVt, type = "l", lty = c(1,2), col = "black",
        xlab = "Vehicle Age (years)", ylab = "Depreciation (2017 dollars)",
        main = "Average Auto and Light Truck Depreciation\nBy Vehicle Age")
legend("topright", legend = c("Auto", "Light Truck"), lty = c(1,2))
dev.off()
#Save car value and annual depreciation expense by age and vehicle type
VehOwnCost_ls$Value_AgVt <- Value_AgVt
VehOwnCost_ls$Depr_AgVt <- Depr_AgVt

#Estimate model to adjust depreciation to account for vehicle mileage
#--------------------------------------------------------------------
#Calculate proportional rate of depreciation relative to base
Depr_MiVt <- cbind(
  Auto = apply(Depr_MiBt[,AutoBodyTypes_], 1, function(x) mean(range(x))),
  LtTrk = apply(Depr_MiBt[,LtTrkBodyTypes_], 1, function(x) mean(range(x)))
)
DeprProp_MiVt <- sweep(Depr_MiVt, 2, Depr_MiVt[2,], "/")
#Define function to model depreciation adjustment as function of mileage
estDeprAdjModel <- function(Depr_, Mi_) {
  #Function to calculate linearizing power
  findPower <- function() {
    checkPower <- function(Pow) {
      PowMi_ <- Mi_ ^ Pow
      unname(diff(diff(Depr_) / diff(PowMi_)))
    }
    binarySearch(checkPower, c(1,5), Target = 0)
  }
  #Calculate power and transform mileage
  Pow <- findPower()
  #Data frame of estimation data
  Data_df <- data.frame(
    Depr = Depr_,
    PowMi = Mi_ ^ Pow
  )
  #Estimate model
  Depr_LM <- lm(Depr ~ PowMi, data = Data_df)
  #Create summary text which combines model summary with power transform
  Summary_ <- c(
    paste("Power Transform:", Pow),
    capture.output(summary(Depr_LM))
    )
  #Return the results
  list(
    Pow = Pow,
    Coeff = coefficients(Depr_LM),
    Summary = Summary_
  )
}
#Estimate and save depreciation adjustment models for autos and light trucks
VehOwnCost_ls$DeprAdjModel_ls <- list(
  Auto = estDeprAdjModel(DeprProp_MiVt[,"Auto"], c(10, 15, 20)),
  LtTrk = estDeprAdjModel(DeprProp_MiVt[,"LtTrk"], c(10, 15, 20))
)

#Define function to calculate vehicle depreciation
#-------------------------------------------------
#' Calculate vehicle depreciation
#'
#' \code{calcVehDepr} calculates vehicle depreciation given vehicle type, age,
#' and annual mileage
#'
#' This function calculates the annual depreciation cost (in 2017 dollars) of
#' vehicles as a function of the vehicle type (Auto, LtTrk), age, and annual
#' mileage. A base depreciation value is calculated using the depreciation cost
#' matrix (VehOwnCost_ls$Depr_AgVt) calculated from AAA data in the module
#' script. The base depreciation is a function of vehicle type and age. The
#' base depreciation is adjusted based on the vehicle's annual mileage using the
#' depreciation adjustment models (VehOwnCost_ls$DeprAdjModel_ls). The models,
#' one for each vehicle type (Auto, LtTrk) are quadratic polynomials with
#' minimum values at 10,000 miles so the minimum vehicle VMT is constrained to
#' 10,000 miles for use in the model.
#'
#' @param Type_ A character vector of vehicle types (Auto, LtTrk)
#' @param Age_ A numeric vector of vehicle ages
#' @param Vmt_ A numeric vector of the annual vehicle miles traveled for the
#' vehicles
#' @return A numeric vector of annual depreciation cost in 2017 dollars
#' @export
#'
calcVehDepr <- function(Type_, Age_, Vmt_) {
  #Calculate index to the vehicle depreciation model table
  TypeToIndex <- c(Auto = 1, LtTrk = 2)
  DeprIdx_mx <- cbind(
    pmin(as.integer(Age_) + 1, 30),
    TypeToIndex[Type_]
  )
  #Apply the index to calculate base vehicle depreciation
  BaseDepr_Ve <- with(VehOwnCost_ls, Depr_AgVt[DeprIdx_mx])
  #Put depreciation adjustment model coefficients into matrix
  Coeff_mx <- rbind(
    Auto = VehOwnCost_ls$DeprAdjModel_ls[["Auto"]]$Coeff,
    LtTrk = VehOwnCost_ls$DeprAdjModel_ls[["LtTrk"]]$Coeff
  )[Type_,]
  #Scale the Vmt to form of depreciation adjustment model
  Mi_ <- Vmt_ / 1000
  #Power transform the mileage
  Pow_Vt <- c(
    Auto = VehOwnCost_ls$DeprAdjModel_ls$Auto$Pow,
    LtTrk = VehOwnCost_ls$DeprAdjModel_ls$LtTrk$Pow
    )
  PowMi_ <- Mi_ ^ (Pow_Vt[Type_])
  #Create model input matrix
  Inp_mx <- cbind(rep(1, length(PowMi_)), PowMi_)
  #Apply the depreciation adjustment model to calculate adjustment factors
  DeprAdj_Ve <- rowSums(Coeff_mx * Inp_mx)
  #Multiply the base depreciation by mileage adjustment factors for result
  BaseDepr_Ve * DeprAdj_Ve
}

#Document model for adjusting depreciation to account for mileage
#----------------------------------------------------------------
Vmt_ <- seq(5000, 30000, 1000)
AutoDep_ <- calcVehDepr(
  rep("Auto", length(Vmt_)),
  Age_ <- rep(5, length(Vmt_)),
  Vmt_
)
LtTrkDep_ <- calcVehDepr(
  rep("LtTrk", length(Vmt_)),
  Age_ <- rep(5, length(Vmt_)),
  Vmt_
)
png("data/depreciation_by_annual_miles.png", width = 480, height = 480)
plot(Vmt_, AutoDep_, type = "l", ylim = range(c(AutoDep_, LtTrkDep_)),
     xlab = "Annual Miles", ylab = "Annual Depreciation (2017 dollars)",
     main = "Annual Depreciation by Annual Miles Driven\n5-Year Old Auto and Light Truck")
lines(Vmt_, LtTrkDep_, lty = 2)
legend("topleft", legend = c("Auto", "Light Truck"), lty = c(1,2))
dev.off()

#Calculate financing cost by vehicle age and type
#------------------------------------------------
#Calculate average new finance cost for autos and light trucks
FinCost_ <- unlist(OwnCost_df["Finance",])
FinCost_Vt <- c(
  Auto = mean(range(FinCost_[AutoBodyTypes_])),
  LtTrk = mean(range(FinCost_[LtTrkBodyTypes_]))
)
#Calculate finance cost by vehicle age
VehOwnCost_ls$FinCost_AgVt <- outer(PropNewValue_Ag, FinCost_Vt, "*")


#Calculate insurance cost by vehicle type
#----------------------------------------
#Note, vehicle insurance cost is not strongly related to vehicle value. It is
#mostly related to driver characteristics.
VehOwnCost_ls$InsCost_Vt <- c(
  Auto = mean(range(unlist(OwnCost_df["Insurance", AutoBodyTypes_]))),
  LtTrk = mean(range(unlist(OwnCost_df["Insurance", LtTrkBodyTypes_])))
)

#Clean up
rm(Depr_AgVt, Depr_MiBt, Depr_MiVt, DeprProp_MiVt, OwnCost_df, Value_AgVt,
   Ag, Age_, AutoBodyTypes_, AutoDep_, BaseDepr_Bt, BasePrice_Bt, BasePrice_Vt,
   Dep5YrProp, DeprRate, FinCost_, FinCost_Vt, LtTrkBodyTypes_, LtTrkDep_,
   PropNewValue_Ag, Vmt_, estDeprAdjModel)

#Save the vehicle ownership cost model
#-------------------------------------
#' Vehicle ownership cost model
#'
#' A list containing data and estimated model for calculating vehicle
#' depreciation and financing cost.
#'
#' @format A list containing the following four components:
#' \describe{
#'   \item{Depr_AgVt}{a matrix of annual depreciation cost by vehicle age and type in 2017 dollars}
#'   \item{DeprAdjModel_ls}{a containing model coefficients for calculating adjustments to annual depreciation based on annual miles driven and vehicle type (Auto, LtTrk)}
#'   \item{FinCost_AgVt}{a matrix of annual financing cost by vehicle age and type in 2017 dollars}
#'   \item{InsCost_Vt}{a vector of annual insurance cost by vehicle type in 2017 dollars}
#' }
#' @source AdjustVehicleOwnership.R script.
"VehOwnCost_ls"
usethis::use_data(VehOwnCost_ls, overwrite = TRUE)

#---------------------------------
#Pay-as-you-drive insurance choice
#---------------------------------

#Define PAYD weights
#-------------------
#Define the relative weights for choosing which households are most likely to
#use PAYD insurance. Following are the weighting factors:
#HasTeenDrv - households with one or more teenage drivers are more likely to have
#because of the advantage for monitoring and providing feedback on teenage
#driver behavior.
#LowerMileage - PAYD insurance is relatively more economical for households that
#have relatively low annual mileage (less than 15,000 miles per vehicle).
#OlderDrvProp - Households with older drivers (30 or older) are more likely to
#use than households with younger drivers.
#LowerIncome - Lower income households are more likely to use because of the lower
#costs and ability to moderate behavior to save additional money. Low income
#threshold is an annual household income of $45,000 in 2005 dollars.
#AutoProp - Households owning automobiles are more likely than households
#owning light trucks (i.e. sport-utility, pickup, van) to use PAYD
#InMetroArea - Households in metropolitan areas are more likely to use PAYD
PaydWts_ <- c(
  HasTeenDrv = 2,
  LowerMileage = 3,
  OlderDrvProp = 2,
  LowerIncome = 2,
  AutoProp = 2,
  InMetroArea = 3)

#Save the PAYD weights
#---------------------
#' Household attributes weights for PAYD insurance
#'
#' Identifies household attributes associated with higher probability of PAYD
#' insurance and the relative weights of those attributes.
#'
#' @format A named vector of weights used for determining household weight for selecting PAYD insurance
#' \describe{
#'   \item{HasTeenDrv}{weight for households having one or more teenage drivers},
#'   \item{LowerMileage}{weight for households driving lower mileage (< 15,000 per vehicle)}
#'   \item{OlderDrvProp}{weight for proportion of drivers in the household who are 30 or older}
#'   \item{LowerIncome}{weight for lower income households (< 45,000 year 2005 dollars)}
#'   \item{AutoProp}{weight for automobile proportion of vehicles owned by household}
#'   \item{InMetroArea}{weight for household being located in a metropolitan (urbanized) area}
#' }
#' @source CalculateVehicleOwnCost.R script.
"PaydWts_"
usethis::use_data(PaydWts_, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateVehicleOwnCostSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "VehOwnFlatRateFee",
      FILE = "azone_hh_veh_own_taxes.csv",
      TABLE = "Azone",
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
        "Annual flat rate tax per vehicle in dollars"
    ),
    item(
      NAME = "VehOwnAdValoremTax",
      FILE = "azone_hh_veh_own_taxes.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Annual proportion of vehicle value paid in taxes"
    ),
    item(
      NAME = "PaydHhProp",
      FILE = "azone_payd_insurance_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Proportion of households in the Azone who have pay-as-you-drive insurance for their vehicles"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "VehOwnFlatRateFee",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehOwnAdValoremTax",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PaydHhProp",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
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
      NAME = "VehId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "VehicleAccess",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("Own", "LowCarSvc", "HighCarSvc")
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk")
    ),
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "FreeParkingSpaces",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "parking spaces",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ParkingUnitCost",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Drivers",
        "Drv15to19",
        "Drv20to29",
        "Drv30to54",
        "Drv55to64",
        "Drv65Plus"
      ),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2005",
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
      NAME = items(
        "NumLtTrk",
        "NumAuto"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "OwnCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual cost of vehicle ownership including depreciation, financing, insurance, taxes, and residential parking in dollars"
    ),
    item(
      NAME = "OwnCostPerMile",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual cost of vehicle ownership per mile of vehicle travel (dollars per mile)"
    ),
    item(
      NAME = "InsCost",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2017",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Annual vehicle insurance cost in dollars"
    ),
    item(
      NAME = "HasPaydIns",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Identifies whether household has pay-as-you-drive insurance for vehicles: 1 = Yes, 0 = no"
    )
  ),
  #Specify call status of module
  Call = items(
    CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt"
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateVehicleOwnCost module
#'
#' A list containing specifications for the CalculateVehicleOwnCost module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#'  \item{Call}{alias and name of module to be called}
#' }
#' @source CalculateVehicleOwnCost.R script.
"CalculateVehicleOwnCostSpecifications"
usethis::use_data(CalculateVehicleOwnCostSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module calculates average vehicle ownership cost for each vehicle based on
#the vehicle type and age using data from the American Automobile Association
#(AAA). To this are added the cost of parking at the vehicle residence if free
#parking is not available for all household vehicles. The ownership cost is
#converted into an average ownership cost per mile by predicting the household
#DVMT given the number of owned vehicles and splitting the miles equally among
#the vehicles.


#Function to calculate vehicle finance cost
#------------------------------------------
#' Calculate vehicle finance cost
#'
#' \code{calcVehFin} calculates vehicle finance cost given vehicle type and age
#'
#' This function calculates the annual financing cost (in 2017 dollars) of
#' vehicles as a function of the vehicle type (Auto, LtTrk) and age using the ,
#' and annual finance cost matrix (VehOwnCost_ls$FinCost_AgVt) calculated from
#' AAA data in the module script.
#'
#' @param Type_ A character vector of vehicle types (Auto, LtTrk)
#' @param Age_ A numeric vector of vehicle ages
#' vehicles
#' @return A numeric vector of annual finance cost in 2017 dollars
#' @name calcVehFin
#' @export
calcVehFin <- function(Type_, Age_) {
  #Calculate index to the vehicle finance model table
  TypeToIndex <- c(Auto = 1, LtTrk = 2)
  FinIdx_mx <- cbind(
    pmin(as.integer(Age_) + 1, 30),
    TypeToIndex[Type_]
  )
  #Apply the index to calculate vehicle finance cost
  with(VehOwnCost_ls, FinCost_AgVt[FinIdx_mx])
}

#Function to calculate vehicle Ad valorem tax
#--------------------------------------------
#' Calculate vehicle Ad valorem tax
#'
#' \code{calcAdValoremTax} calculates vehicle Ad valorem tax given vehicle type
#' and age
#'
#' This function calculates the annual Ad valorem tax (in 2017 dollars) of
#' vehicles as a function of the vehicle type (Auto, LtTrk) and age using the ,
#' and annual vehicle value matrix (VehOwnCost_ls$Value_AgVt) calculated from
#' AAA data in the module script, and input Ad valorem tax rate.
#'
#' @param Type_ A character vector of vehicle types (Auto, LtTrk)
#' @param Age_ A numeric vector of vehicle ages
#' vehicles
#' @param TaxRate A numeric value that is the annual Ad valorem tax rate in
#' dollars of tax per dollar of vehicle value
#' @return A numeric vector of annual Ad valorem tax cost in 2017 dollars
#' @name calcAdValoremTax
#' @export
calcAdValoremTax <- function(Type_, Age_, TaxRate) {
  #Calculate index to the vehicle value model table
  TypeToIndex <- c(Auto = 1, LtTrk = 2)
  ValueIdx_mx <- cbind(
    pmin(as.integer(Age_) + 1, 30),
    TypeToIndex[Type_]
  )
  #Apply the index to calculate vehicle finance cost
  with(VehOwnCost_ls, Value_AgVt[ValueIdx_mx]) * TaxRate
}

#Define function to assign PAYD propensity weights to households
#-----------------------------------------------------------------------
#' Assign pay-as-you-drive insurance propensity weights to households
#'
#' \code{calcPaydWeights} Calculates household weight that reflect the relative
#' propensity of a household to purchase pay-as-you-drive insurance based on the
#' household characteristics
#'
#' Household PAYD propensity weights are assigned based on the presence of
#' teenager drivers, whether the average annual vehicle mileage is low,
#' the proportion of older drivers in the household,  whether household income
#' is relatively low, the proportion of household vehicles that are autos, and
#' whether the household lives in a metropolitan area. All household vehicles
#' must be a 1996 or later model year.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A numeric vector of weights assigned to each household
idPaydHh <- function(L) {
  #Set up
  #------
  set.seed(L$G$Seed)
  NumHh <- length(L$Year$Household$HhId)
  NumPayd <- round(NumHh * L$Year$Azone$PaydHhProp)

  #Identify qualifying househouseholds
  #----------------------------------------------------------------------------
  #Household qualifies if all household vehicles are later than 1995 model year
  AgeThreshold <- as.numeric(L$G$Year) - 1996
  Qualifies_Hh <-
    tapply(L$Year$Vehicle$Age, L$Year$Vehicle$HhId, function(x) {
      any(x >= AgeThreshold)
    })[L$Year$Household$HhId]
  Qualifies_Hh[L$Year$Household$Vehicles == 0] <- FALSE

  #Identify PAYD households
  #------------------------
  if (sum(Qualifies_Hh) <= NumPayd) {
  #Return all qualifying households if less than or equal to NumPayd
    HasPaydIns_Hh <- as.integer(Qualifies_Hh)
  } else {
  #Otherwise calculate PAYD weights and choose based on weights
    Weight_Hh <- rep(1, length(L$Year$Household$HhId))
    #Add weight for teenage drivers
    Weight_Hh <- local({
      HasTeenDrv_Hh <- with(L$Year$Household, Drv15to19 > 0)
      Weight_Hh + HasTeenDrv_Hh * PaydWts_["HasTeenDrv"]
    })
    #Add weight for average annual vehicle miles is less than 15,000
    Weight_Hh <- local({
      VmtPerVeh_Hh <- with(L$Year$Household, 365 * Dvmt / Vehicles)
      VmtPerVeh_Hh[is.na(VmtPerVeh_Hh)] <- 0
      LowerMileage_Hh <- VmtPerVeh_Hh < 15000
      Weight_Hh + LowerMileage_Hh * PaydWts_["LowerMileage"]
    })
    #Add weight for the proportion of drivers 30 or older
    Weight_Hh <- local({
      OlderDrvProp_Hh <-
        with(L$Y$Household, (Drivers - Drv15to19 - Drv20to29) / Drivers)
      OlderDrvProp_Hh[is.na(OlderDrvProp_Hh)] <- 0
      Weight_Hh + OlderDrvProp_Hh * PaydWts_["OlderDrvProp"]
    })
    #Add weight for lower income households
    Weight_Hh <- local({
      LowerIncome_Hh <- L$Year$Household$Income < 45000
      Weight_Hh + LowerIncome_Hh * PaydWts_["LowerIncome"]
    })
    #Add weight for the proportion of vehicles that are autos
    Weight_Hh <- local({
      AutoProp_Hh <- with(L$Year$Household, NumAuto / Vehicles)
      AutoProp_Hh[is.na(AutoProp_Hh)] <- 0
      Weight_Hh + AutoProp_Hh * PaydWts_["AutoProp"]
    })
    #Add weight for households that are located within a metropolitan area
    Weight_Hh <- local({
      InMetroArea <- L$Y$Household$LocType == "Urban"
      Weight_Hh + PaydWts_["InMetroArea"]
    })
    #Use weights to identify PAYD households
    HasPaydIns_Hh <- integer(NumHh)
    HhIdx_ <- (1:NumHh)[Qualifies_Hh]
    Wts_ <- Weight_Hh[Qualifies_Hh]
    PaydIdx_ <- sample(HhIdx_, NumPayd, prob = Wts_ / max(Wts_))
    HasPaydIns_Hh[PaydIdx_] <- 1L
  }
  #Return the result where only qualifying households have weights
  unname(HasPaydIns_Hh)
}

#Main module function to calculate household vehicle ownership cost
#------------------------------------------------------------------
#' Calculate household vehicle ownership cost
#'
#' \code{CalculateVehicleOwnCost} calculates the average annual cost of
#' ownership and per mile cost of each household vehicle
#'
#' This function calculates the average annual ownership cost for each household
#' vehicle. It also calculates what that cost works out to on a per mile basis
#' by calculating average daily household DVMT given the number of household
#' vehicles owned, splitting the DVMT evenly among household vehicles, and
#' calculating the average per mile cost.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @param M A list the module functions of modules called by this module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name CalculateVehicleOwnCost
#' @import visioneval
#' @export
CalculateVehicleOwnCost <- function(L,M) {
  #Estimate the household DVMT
  Dvmt_ls <- M$CalcDvmt(L$CalcDvmt)
  Dvmt_Hh <- Dvmt_ls$Year$Household$Dvmt
  L$Year$Household$Dvmt <- Dvmt_Hh

  #Create an index between the household data and vehicle table
  HasVeh <- L$Year$Household$Vehicles > 0
  DataID_ <-
    with(L$Year$Household,
         paste(
           rep(HhId[HasVeh], Vehicles[HasVeh]),
           unlist(sapply(Vehicles[HasVeh], function(x) 1:x)),
           sep = "-"
         ))
  DatOrd <- match(DataID_, L$Year$Vehicle$VehId)

  #Calculate annual household VMT per vehicle
  NumVeh_Hh <- L$Year$Household$Vehicles
  AnnVmtPerVeh_ <-
    rep(365 * Dvmt_Hh[HasVeh] / NumVeh_Hh[HasVeh], NumVeh_Hh[HasVeh])
  AnnVmt_Ve <- rep(NA, length(L$Year$Vehicle$VehId))
  AnnVmt_Ve[DatOrd] <- AnnVmtPerVeh_

  #Identify vehicles that are car service vehicles
  IsCarSvc <- L$Year$Vehicle$VehicleAccess != "Own"

  #Calculate annual depreciation cost
  DeprCost_Ve <-
    calcVehDepr(L$Year$Vehicle$Type, L$Year$Vehicle$Age, AnnVmt_Ve)
  DeprCost_Ve[IsCarSvc] <- 0

  #Calculate annual financing cost
  FinCost_Ve <-
    calcVehFin(L$Year$Vehicle$Type, L$Year$Vehicle$Age)
  FinCost_Ve[IsCarSvc] <- 0

  #Calculate annual insurance cost
  InsCost_Ve <- VehOwnCost_ls$InsCost_Vt[L$Year$Vehicle$Type]
  InsCost_Ve[IsCarSvc] <- 0

  #Calculate annual taxes
  TaxCost_Ve <- L$Year$Azone$VehOwnFlatRateFee +
    calcAdValoremTax(
      L$Year$Vehicle$Type,
      L$Year$Vehicle$Age,
      L$Year$Azone$VehOwnAdValoremTax)
  TaxCost_Ve[IsCarSvc] <- 0

  #Calculate residential parking cost
  NumPaidPkgSp_ <-
    pmax(0, with(L$Year$Household, Vehicles[HasVeh] - FreeParkingSpaces[HasVeh]))
  AnnUnitPkgCost_ <- L$Year$Household$ParkingUnitCost[HasVeh] * 365
  AveAnnVehPkgCost_ <-
    rep(NumPaidPkgSp_ * AnnUnitPkgCost_ / NumVeh_Hh[HasVeh], NumVeh_Hh[HasVeh])
  PkgCost_Ve <- numeric(length(TaxCost_Ve))
  PkgCost_Ve[DatOrd] <- AveAnnVehPkgCost_
  PkgCost_Ve[IsCarSvc] <- 0

  #Calculate total ownership cost
  TotCost_Ve <- DeprCost_Ve + FinCost_Ve + InsCost_Ve + TaxCost_Ve + PkgCost_Ve
  TotCostPerMi_Ve <- TotCost_Ve / AnnVmt_Ve
  TotCostPerMi_Ve[is.na(TotCostPerMi_Ve)] <- 0

  #Assign PAYD insurance
  HasPaydIns_Hh <- idPaydHh(L)

  #Return the results
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list(
    OwnCost = TotCost_Ve,
    OwnCostPerMile = TotCostPerMi_Ve,
    InsCost = InsCost_Ve
  )
  Out_ls$Year$Household <- list(
    HasPaydIns = HasPaydIns_Hh
  )
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculateVehicleOwnCost")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleOwnCost",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# M <- TestDat_$M
# TestOut_ls <- CalculateVehicleOwnCost(L, M)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleOwnCost",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
