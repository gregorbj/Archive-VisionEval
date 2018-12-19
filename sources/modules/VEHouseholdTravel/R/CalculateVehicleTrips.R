#=======================
#CalculateVehicleTrips.R
#=======================
#
#<doc>
#
## CalculateVehicleTrips Module
#### November 23, 2018
#
#This module calculates average daily vehicle trips for households consistent with the household DVMT. An average trip length model is applied to estimate average length of household trips reflecting the characteristics of the household and the place where they live. The average trip length is divided into the average household DVMT to get an estimate of average number of daily vehicle trips.
#
### Model Parameter Estimation
#
#Metropolitan and non-metropolitan household trip length models are estimated from the Hh_df dataset in the VE2001NHTS package. Separate metropolitan and non-metropolitan models are estimated because the metropolitan model is sensitive to added variables that are not present for non-metropolitan household data. The models are estimated using the records of households that had some light-duty vehicle travel on the survey day.
#
#The models are estimated in 2 steps. In the first step, a linear model is estimated to predict the survey day average trip length. This model is applied stochastically over 1000 days to calculate the average trip length. In the second step, a linear model of the averages is estimated. These steps are described in more detail below.
#
#In the first step, linear models of survey day average vehicle trip length are estimated for metropolitan and non-metropolitan households. Since the distribution of vehicle trip length is highly skewed with a long right-hand tail, the model is estimated for predicting power-transformed values. The power is estimated to minimize the skewness of the distribution. Following is a summary of the estimation statistics for non-metropolitan households:
#
#<txt:VehTrpLenModel_ls$DayModel$NonMetroSummary>
#
#All variables are highly significant and the coefficients have expected signs. Trip lengths increase with the numbers of drivers and non-drivers in the household and the income of the household. The number of drivers in the household has a stronger effect than the number of non-drivers. Trip lengths decrease at higher population densities and if households have fewer vehicles than drivers. The negative coefficients for the interaction of income with drivers and non-drivers indicates that the rate of increase in trip length diminishes as income and the numbers of drivers and non-drivers increase.
#
#The metropolitan model has the same independent variables as the non-metropolitan model and also includes freeway lane-miles per capita and urban mixed-use neighborhood variables. Following is a summary of the estimation statistics for this model:
#
#<txt:VehTrpLenModel_ls$DayModel$MetroSummary>
#
#The coefficients for the variables shared with the non-metropolitan model have the same signs. The added freeway lane-mile and urban mixed-use neighborhood variables are also highly significant and have expected signs. The average vehicle trip length increases with greater freeway lane-miles and decreases in urban mixed-use neighborhoods. The added interaction between density and urban mixed-use has a positive sign which indicates that the rate of decrease in trip length diminishes as density increases.
#
#As can be seen from the statistics, the models predict a small portion of the observed variation in vehicle trip lengths. Because of this and because the model is a model of power-transformed trip length (where trip length has a long right-hand tail), the mean of the modeled values is substantially less than the observed mean. To address this, the modeled predictions are treated as the mean values of distributions for which a standard deviation is calculated that results in a distribution of predicted values that has the same variance as the observed distribution. The model is run 1000 times for each survey household where each time a value is chosen at random from a normal distribution having the modeled mean and the estimated standard deviation. The household average is computed from the results.
#
#In the second step, linear models to predict the simulated averages for metropolitan and non-metropolitan households are estimated. The independent variables in these models are the same as in the survey day models. Following is are the estimation statistics for the metropolitan household model.
#
#<txt:VehTrpLenModel_ls$Metro$Summary>
#
#The high R-squared value indicates that the linear model can be substituted for the synthesis method for predicting the average trip length for households. The following figure illustrates this by comparing the distributions of the values produced by the linear model and the simulated averages.
#
#<fig:metro_veh-trp-len_dist.png>
#
#Following are the estimation statistics for the non-metropolitan household model.
#
#<txt:VehTrpLenModel_ls$NonMetro$Summary>
#
#The high r-squared value indicates that this model is also a suitable substitute for the simulation of average trip length. The following figure shows that the fit of the non-metropolitan model is not as good as the fit of the metropolitan model.
#
#<fig:nonmetro_veh-trp-len_dist.png>
#
#The following table compares the mean modeled values for average DVMT, average trip length, and average daily vehicle trips with average survey values for DVMT, trip length, and vehicle trips. The survey values are capped at the 99th percentile value as are the modeled values. The mean number of trips for the modeled and survey values is calculated by dividing the mean DVMT by the mean trip length. As can be seen, the modeled mean trip length is close to the survey mean. However, since the mean of the modeled average household DVMT is less than the survey day mean DVMT, the modeled average number of vehicle trips is less than the survey mean.
#
#<tab:VehTrpLenModel_ls$TestResults_df>
#
### How the Module Works
#
#The module applies the estimated metropolitan and non-metropolitan average vehicle trip length models to calculate the average vehicle trip length for each household. The metropolitan model is applied to all household located in the urbanized area. The non-metropolitan model is applied to other households. The average number of vehicle trips is calculated for each household by dividing the household DVMT by the average trip length.
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(pscl)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#Initialize list to store vehicle trip length model
#--------------------------------------------------
VehTrpLenModel_ls <- list()

#Load NHTS household data
#------------------------
Hh_df <- VE2001NHTS::Hh_df

#Prepare variables for estimating trip models
#--------------------------------------------
Hh_df$NumVehTrp <- round(Hh_df$PvtVehTrips + Hh_df$ShrVehTrips)
Hh_df$Dvmt <- with(Hh_df, PvtVehDvmt + ShrVehDvmt)
Hh_df$LogIncome <- log(Hh_df$Income)
Hh_df$Density <- Hh_df$Hbppopdn
Hh_df$LogDensity <- log(Hh_df$Hbppopdn)
Hh_df$IsUrbanMixNbrhd <- Hh_df$UrbanDev
Hh_df$HouseType <- "MF"
Hh_df$HouseType[Hh_df$Hometype %in% c("Single Family", "Mobile Home")] <- "SF"
Hh_df$HouseType[Hh_df$Hometype == "Dorm"] <- "GQ"
Hh_df$IsSF <- as.numeric(Hh_df$HouseType == "SF")
Hh_df$Drivers <- Hh_df$Drvrcnt
Hh_df$NonDrivers <- Hh_df$Hhsize - Hh_df$Drivers
Hh_df$Vehicles <- Hh_df$Hhvehcnt
Hh_df$VehPerDvr <- Hh_df$Vehicles / Hh_df$Drivers
Hh_df$VehGtDvr <- with(Hh_df, as.numeric(Vehicles > Drivers))
Hh_df$VehEqDvr <- with(Hh_df, as.numeric(Vehicles == Drivers))
Hh_df$VehLtDvr <- with(Hh_df, as.numeric(Vehicles < Drivers))
Hh_df$HhSize <- Hh_df$Hhsize
Hh_df$FwyLaneMiPC <- Hh_df$FwyLnMiPC / 1000
Hh_df$IsMetro <- Hh_df$Msacat %in% c("1", "2")
Hh_df <- Hh_df[Hh_df$NumVehTrp > 0,]
Hh_df$VehTrpLen <- Hh_df$Dvmt / Hh_df$NumVehTrp
rownames(Hh_df) <- Hh_df$Houseid

#Normalize trip length
#---------------------
#Function to find power which minimizes skew of distribution
findPower <- function(X_) {
  X_ <- X_[!is.na(X_)]
  testPow <- function(Pow) {
    PowX_ <- X_ ^ Pow
    3 * (mean(PowX_) - median(PowX_)) / sd(PowX_)
  }
  binarySearch(testPow, SearchRange_ = c(0.01, 0.99))
}
#Calculate normalizing power for metropolitan households
VehTrpLenModel_ls$MetroPow <- findPower(Hh_df$VehTrpLen[Hh_df$IsMetro])
VehTrpLenModel_ls$NonMetroPow <- findPower(Hh_df$VehTrpLen[!Hh_df$IsMetro])
#Transform
Pow_ <- rep(VehTrpLenModel_ls$NonMetroPow, nrow(Hh_df))
Pow_[Hh_df$IsMetro] <- VehTrpLenModel_ls$MetroPow
Hh_df$PowVehTrpLen <- Hh_df$VehTrpLen ^ Pow_
rm(Pow_)

#Model average household DVMT to aid in evaluating results
#---------------------------------------------------------
#Get DVMT model
load("data/DvmtModel_ls.rda")
#Prepare variables for application of model
Hh_df$ZeroVeh <- as.numeric(Hh_df$NumVeh == 0)
Hh_df$OneVeh <- as.numeric(Hh_df$NumVeh == 1)
Hh_df$Workers <- Hh_df$Wrkcount
Hh_df$Intercept <- 1
#Predict average DVMT
Hh_df$AveDvmt <- NA
Hh_df$AveDvmt[Hh_df$IsMetro] <-
  as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                 envir = Hh_df[Hh_df$IsMetro,])) ^ (1 / DvmtModel_ls$Metro$Pow)
Hh_df$AveDvmt[!Hh_df$IsMetro] <-
  as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                 envir = Hh_df[!Hh_df$IsMetro,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)
#Cap at 99th percentile
MaxAveDvmt <- quantile(Hh_df$AveDvmt, probs = 0.99, na.rm = TRUE)
Hh_df$AveDvmt[Hh_df$AveDvmt > MaxAveDvmt] <- MaxAveDvmt
rm(DvmtModel_ls, MaxAveDvmt)

#Define function to simulate average trip length
#-----------------------------------------------
simAveVehTrpLen <- function(Data_df, DepVar, IndepVars_, Pow) {
  #Initialize list to hold result
  Out_ls <- list()
  #Make model formula
  ModelFormula <-
    as.formula(paste(DepVar, " ~ ", paste(IndepVars_, collapse = "+")))
  #Estimate linear trip length model
  VehTrpLen_LM <- lm(ModelFormula, data = Data_df)
  #Save summary statistics for documentation
  Out_ls$Summary <- capture.output(summary(VehTrpLen_LM))
  #Predicted trip lengths
  PredVehTrpLen_ <- fitted.values(VehTrpLen_LM)
  #Define function to calculate dispersion factor to match observed variation
  calcDispersonFactor <- function(ObsVals_, EstVals_) {
    ObsSd <- sd(ObsVals_)
    EstSd <- sd(EstVals_)
    N <- length(ObsVals_)
    testSd <- function(SD) {
      RevEstVals_ <- EstVals_ + rnorm(N, 0, SD)
      ObsSd - sd(RevEstVals_)
    }
    binarySearch(testSd, SearchRange_ = sort(c(ObsSd, EstSd)))
  }
  #Calculate dispersion factor
  TrpLenSd <- calcDispersonFactor(Data_df[,DepVar], PredVehTrpLen_)
  #Define function to simulate trip length for random day
  simulateTrpLen <- function(PowTrpLen_, SD, Pow) {
    N <- length(PowTrpLen_)
    AdjPowTrpLen_ <- PowTrpLen_ + rnorm(N, 0, SD)
    AdjPowTrpLen_[AdjPowTrpLen_ < 0] <- 0
    TrpLen_ <- AdjPowTrpLen_ ^ (1 / Pow)
    TrpLen_
  }
  #Set up simulation
  VehTrpLen_HhX <- matrix(0, nrow = nrow(Data_df), ncol = 1000)
  #Run simulation
  for (i in 1:1000) {
    VehTrpLen_HhX[,i] <- simulateTrpLen(PredVehTrpLen_, TrpLenSd, Pow)
  }
  #Calculate average values
  Out_ls$AveVehTrpLen <- rowMeans(VehTrpLen_HhX)
  #Return the result
  Out_ls
}

#Simulate average vehicle trip length for metropolitan households
#----------------------------------------------------------------
#Select metropolitan household dataset
Vars_ <- c("Houseid", "PowVehTrpLen", "HhSize", "LogIncome", "LogDensity",
           "Vehicles", "IsUrbanMixNbrhd", "Drivers", "NonDrivers",
           "FwyLaneMiPC", "VehLtDvr")
MetroHh_df <- Hh_df[Hh_df$IsMetro, Vars_]
MetroHh_df <- MetroHh_df[complete.cases(MetroHh_df),]
#Simulate average vehicle trip length
IndepVars_ <- c("Drivers", "NonDrivers", "LogIncome", "LogDensity",
                "IsUrbanMixNbrhd", "FwyLaneMiPC", "VehLtDvr",
                "LogIncome:Drivers", "LogIncome:NonDrivers",
                "LogDensity:IsUrbanMixNbrhd")
MetroAveTrpLen_ls <-
  simAveVehTrpLen(
    Data_df = MetroHh_df,
    DepVar = "PowVehTrpLen",
    IndepVars_ = IndepVars_,
    Pow = VehTrpLenModel_ls$MetroPow)
VehTrpLenModel_ls$DayModel <- list(
  MetroSummary = MetroAveTrpLen_ls$Summary
)
#Recalculate power transform from the average values
VehTrpLenModel_ls$MetroPow <- findPower(MetroAveTrpLen_ls$AveVehTrpLen)
rm(Vars_, IndepVars_)

#Simulate average vehicle trip length for nonmetropolitan households
#-------------------------------------------------------------------
#Select metropolitan household dataset
Vars_ <- c("Houseid", "PowVehTrpLen", "HhSize", "LogIncome", "LogDensity",
           "Vehicles", "Drivers", "NonDrivers", "VehLtDvr")
NonMetroHh_df <- Hh_df[!Hh_df$IsMetro, Vars_]
NonMetroHh_df <- NonMetroHh_df[complete.cases(NonMetroHh_df),]
#Simulate average vehicle trip length
IndepVars_ <- c("Drivers", "NonDrivers", "LogIncome", "LogDensity",
                "VehLtDvr", "LogIncome:Drivers", "LogIncome:NonDrivers")
NonMetroAveTrpLen_ls <-
  simAveVehTrpLen(
    Data_df = NonMetroHh_df,
    DepVar = "PowVehTrpLen",
    IndepVars_ = IndepVars_,
    Pow = VehTrpLenModel_ls$NonMetroPow)
VehTrpLenModel_ls$DayModel$NonMetroSummary <- NonMetroAveTrpLen_ls$Summary
#Recalculate power transform from the average values
VehTrpLenModel_ls$NonMetroPow <- findPower(NonMetroAveTrpLen_ls$AveVehTrpLen)
rm(Vars_, IndepVars_)
rm(simAveVehTrpLen)

#Define function to estimate model of simulated average values
#-------------------------------------------------------------
estimateVehTrpLenModel <- function(Data_df, StartTerms_, Pow) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <- function(In_df) {
    Out_df <- In_df
    Out_df$LogDensity <- log1p(In_df$Density)
    Out_df$LogIncome <- log1p(In_df$Income)
    Out_df$NonDrivers <- In_df$HhSize - In_df$Drivers
    Out_df$VehLtDvr <- as.numeric(In_df$Vehicles < In_df$Drivers)
    Out_df$Intercept <- 1
    Out_df
  }
  #Prepare estimation data
  EstData_df <- prepIndepVar(Data_df)
  EstData_df$PowVehTrpLen <- Data_df$VehTrpLen ^ Pow
  #Define function to make a model formula
  makeFormula <-
    function(Terms_) {
      FormulaString <-
        paste("PowVehTrpLen ~ ", paste(Terms_, collapse = "+"))
      as.formula(FormulaString)
    }
  VehTrpLenModel_LM <-
    lm(makeFormula(StartTerms_), data = EstData_df)
  Coeff_mx <- coefficients(summary(VehTrpLenModel_LM))
  EndTerms_ <- rownames(Coeff_mx)[Coeff_mx[, "Pr(>|t|)"] <= 0.05]
  if ("(Intercept)" %in% EndTerms_) {
    EndTerms_ <- EndTerms_[-grep("(Intercept)", EndTerms_)]
  }
  VehTrpLenModel_LM <- lm(makeFormula(EndTerms_), data = EstData_df)
  #Define function to transform model outputs
  transformResult <- function(Result_) {
    Result_ ^ (1 / Pow)
  }
  #Return model
  list(
    Type = "linear",
    Formula = makeModelFormulaString(VehTrpLenModel_LM),
    PrepFun = prepIndepVar,
    OutFun = transformResult,
    Summary = capture.output(summary(VehTrpLenModel_LM))
  )
}

#Estimate linear model for metropolitan household trip length
#------------------------------------------------------------
Vars_ <- c("Houseid", "HhSize", "Income", "Density", "Vehicles", "Drivers",
           "IsUrbanMixNbrhd", "FwyLaneMiPC")
MetroHh_df <- Hh_df[Hh_df$IsMetro, Vars_]
MetroHh_df <- MetroHh_df[complete.cases(MetroHh_df),]
MetroHh_df$VehTrpLen <- MetroAveTrpLen_ls$AveVehTrpLen
VehTrpLenModel_ls$Metro <- estimateVehTrpLenModel(
  Data_df = MetroHh_df,
  StartTerms_ = c(
    "Drivers", "NonDrivers", "LogIncome", "LogDensity", "IsUrbanMixNbrhd",
    "FwyLaneMiPC", "VehLtDvr", "LogIncome:Drivers", "LogIncome:NonDrivers",
    "LogDensity:IsUrbanMixNbrhd"),
  Pow = VehTrpLenModel_ls$MetroPow)
rm(Vars_)

#Estimate linear model for nonmetropolitan household trip length
#---------------------------------------------------------------
Vars_ <- c("Houseid", "HhSize", "Income", "Density", "Vehicles", "Drivers")
NonMetroHh_df <- Hh_df[!Hh_df$IsMetro, Vars_]
NonMetroHh_df <- NonMetroHh_df[complete.cases(NonMetroHh_df),]
NonMetroHh_df$VehTrpLen <- NonMetroAveTrpLen_ls$AveVehTrpLen
VehTrpLenModel_ls$NonMetro <- estimateVehTrpLenModel(
  Data_df = NonMetroHh_df,
  StartTerms_ = c(
    "Drivers", "NonDrivers", "LogIncome", "LogDensity", "VehLtDvr",
    "LogIncome:Drivers", "LogIncome:NonDrivers"),
  Pow = VehTrpLenModel_ls$NonMetroPow)
rm(Vars_)
rm(estimateVehTrpLenModel)

#Evaluate model results
#----------------------
#Define function to cap maximum
capMaxVals <- function(Vals_) {
  MaxVal <- quantile(Vals_, probs = 0.99)
  Vals_[Vals_ > MaxVal] <- MaxVal
  Vals_
}
#Predict average trip length
Hh_df$AveVehTrpLen <- NA
Hh_df[MetroHh_df$Houseid, "AveVehTrpLen"] <-
  capMaxVals(applyLinearModel(VehTrpLenModel_ls$Metro, MetroHh_df))
Hh_df[NonMetroHh_df$Houseid, "AveVehTrpLen"] <-
  capMaxVals(applyLinearModel(VehTrpLenModel_ls$NonMetro, NonMetroHh_df))
#Prepare table of results summaries
VehTrpLenModel_ls$TestResults_df <-
  data.frame(local({
    Tmp_df <- Hh_df[, c("AveDvmt", "AveVehTrpLen", "Dvmt", "VehTrpLen", "NumVehTrp")]
    Tmp_df <- Tmp_df[complete.cases(Tmp_df),]
    Tmp_df$AveDailyVehTrp <- with(Tmp_df, AveDvmt / AveVehTrpLen)
    Model_ <- round(c(
      DVMT = mean(Tmp_df$AveDvmt),
      `Trip Length` = mean(Tmp_df$AveVehTrpLen),
      Trips = mean(Tmp_df$AveDvmt) / mean(Tmp_df$AveVehTrpLen)
    ), 1)
    Survey_ <- round(c(
      `DVMT (miles)` = mean(capMaxVals(Tmp_df$Dvmt)),
      `Trip Length (miles)` = mean(capMaxVals(Tmp_df$VehTrpLen)),
      Trips = mean(capMaxVals(Tmp_df$Dvmt)) / mean(capMaxVals(Tmp_df$VehTrpLen))
    ), 1)
    Compare_mx <- rbind(Model_, Survey_)
    rownames(Compare_mx) <- c("Model Means", "Survey Means")
    data.frame(Compare_mx)
  }))
names(VehTrpLenModel_ls$TestResults_df) <-
  c("DVMT (miles)", "Trip Length (miles)", "Trips")
#Plot comparison of model and simulated values for metropolitan households
png("data/metro_veh-trp-len_dist.png", width = 480, height = 480)
plot(density(Hh_df$AveVehTrpLen[Hh_df$IsMetro], na.rm = TRUE),
     xlab = "Average Vehicle Trip Length (miles)",
     ylab = "Probability Density",
     main = paste0(
       "Metropolitan Household Average Trip Length Distribution",
       "\nLinear Model of Simulation vs. Simulation"))
lines(density(MetroAveTrpLen_ls$AveVehTrpLen), col = "red")
legend("topright", lty = 1, col = c(1,2), bty = "n",
       legend = c("Linear Model", "Simulation"))
dev.off()
#Plot comparison of model and simulated values for nonmetropolitan households
png("data/nonmetro_veh-trp-len_dist.png", width = 480, height = 480)
plot(density(Hh_df$AveVehTrpLen[!Hh_df$IsMetro], na.rm = TRUE),
     xlab = "Average Vehicle Trip Length (miles)",
     ylab = "Probability Density",
     main = paste0(
       "Non-metropolitan Household Average Trip Length Distribution",
       "\nLinear Model of Simulation vs. Simulation"))
lines(density(NonMetroAveTrpLen_ls$AveVehTrpLen), col = "red")
legend("topright", lty = 1, col = c(1,2), bty = "n",
       legend = c("Linear Model", "Simulation"))
dev.off()


#Clean up
rm(capMaxVals, MetroHh_df, NonMetroHh_df, Hh_df, findPower, MetroAveTrpLen_ls,
   NonMetroAveTrpLen_ls)

#Save the model
#' Household vehicle trip length models
#'
#' A list of components describing linear models which predict average vehicle
#' trip length by household.
#'
#' @format A list having the following 5 components:
#' Pow: estimated power for minimizing skew of trip length distribution;
#' DayModel: Summary estimation statistics for linear models of household trip
#' lengths on the survey day;
#' Metro: Linear model of average trip length based on simulated averages for
#' metropolitan households;
#' NonMetro: Linear model of average trip length based on simulated averaged for
#' non-metropolitan households;
#' TestResults_df: Data frame showing summary statistics for average DVMT, trip
#' length, daily vehicle trips, and daily vehicle trips per driver;
#' contains a string representing a hurdle model for computing household trips.
#' @source CalculateVehicleTrips.R script.
"VehTrpLenModel_ls"
usethis::use_data(VehTrpLenModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateVehicleTripsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  Inp = NULL,
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = "FwyLaneMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D1B",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/SQMI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
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
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Drivers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "NA",
      ISELEMENTOF = c(0, 1)
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
  #Specify data to saved in the data store
  Set = items(
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
    ),
    item(
      NAME = "AveVehTripLen",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average household vehicle trip length in miles"
    )
  ),
  #Make module callable
  Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateVehicleTrips module
#'
#' A list containing specifications for the CalculateVehicleTrips module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateVehicleTrips.R script.
"CalculateVehicleTripsSpecifications"
usethis::use_data(CalculateVehicleTripsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates vehicle trips for each household.

#Main module function that calculates household vehicle trips
#------------------------------------------------------------
#' Main module function to calculate household vehicle trips
#'
#' \code{CalculateVehicleTrips} calculates vehicle trips for each household.
#'
#' This function calculates vehicle trips for households.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name CalculateVehicleTrips
#' @import visioneval
#' @export
CalculateVehicleTrips <- function(L) {

  #Assign VehTrpLenModel_ls within function so it is in scope for module call
  if(!exists("VehTrpLenModel_ls")){
    VehTrpLenModel_ls <- VEHouseholdTravel::VehTrpLenModel_ls
  }

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$Intercept <- 1
  Hh_df$FwyLaneMiPC <-
    L$Year$Marea$FwyLaneMiPC[match(L$Year$Household$Marea, L$Year$Marea$Marea)]
  Hh_df$Density <-
    L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$NonDrivers <- Hh_df$HhSize - Hh_df$Drivers
  Hh_df$VehLtDvr <- with(Hh_df, as.numeric(Vehicles < Drivers))
  IsMetro <- Hh_df$LocType == "Urban"

  #Apply the average trip length model
  #-----------------------------------
  #Initialize vector to store trip length results
  AveTrpLen_Hh <- rep(NA, nrow(Hh_df))
  #Model average trip length for metropolitan households
  AveTrpLen_Hh[IsMetro] <-
    applyLinearModel(VehTrpLenModel_ls$Metro, Hh_df[IsMetro,])
  #Model average trip length for non-metropolitan households
  AveTrpLen_Hh[!IsMetro] <-
    applyLinearModel(VehTrpLenModel_ls$NonMetro, Hh_df[!IsMetro,])
  #Cap the maximum value at the 99th percentile value
  MaxAveTrpLen <- quantile(AveTrpLen_Hh, probs = 0.99)
  AveTrpLen_Hh[AveTrpLen_Hh > MaxAveTrpLen] <- MaxAveTrpLen

  #Calculate the average number of vehicle trips
  #---------------------------------------------
  VehicleTrips_Hh <- Hh_df$Dvmt / AveTrpLen_Hh

  #Return results
  #--------------
  Out_ls <- initDataList()
  Out_ls$Year$Household$VehicleTrips = VehicleTrips_Hh
  Out_ls$Year$Household$AveVehTripLen = AveTrpLen_Hh
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculateVehicleTrips")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleTrips",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateVehicleTrips(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleTrips",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
