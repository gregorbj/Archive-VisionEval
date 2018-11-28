#=================
#CreateSimBzones.R
#=================

#<doc>
## CreateSimBzones Module
#### November 25, 2018
#
#This module synthesizes Bzones and their land use attributes as a function of Azone characteristics as well as data derived from the US Environmental Protection Agency's Smart Location Database (SLD) augmented with US Census housing and household income data, and data from the National Transit Database. Details on these data are included in the VESimLandUseData package. The combined dataset contains a number of land use attributes at the US Census block group level. The goal of Bzone synthesis to generate a set of SimBzones in each Azone that reasonably represent block group land use characteristics given the characteristics of the Azone, the Marea that the Azone is a part of, and scenario inputs provided by the user.
#
#Many of the models and procedures used in Bzone synthesis pivot from profiles developed from these data sources for specific urbanized areas, as well as more general profiles for different urbanized area population size categories, towns, and rural areas. Using these specific and general profiles enables the simulated Bzones (SimBzones) to better represent the areas being modeled and the variety of conditions found in different states. Following is a listing of the urbanized areas for which profiles have been developed. Note that urbanized areas that cross state lines are split into the individual state components. This is done to faciliate the development of state models and to better reflect the characteristics of the urbanized area characteristics in each state.
#
#<tab:SimBzone_ls$Docs$UzaNames_df>
#
#The model user identifies the urbanized area name (from the table) corresponding to each Marea in the model. If an urbanized area being modeled is not listed in the table, the user may substitute the name of an urbanized area that has similar characteristics, or may specify one of the following names representing urbanized areas of different sizes measured by the total number of households and jobs:
#
#SzBrk_ <- c(0, 5e4, 1e5, 5e5, 1e6, 5e6, max(TotAct_Ua))
Sz <- c("small", "medium-small", "medium", "medium-large", "large", "very-large")

#* **small**: 0 - 50,000 households and jobs
#
#* **medium-small**: 50,001 - 100,000 households and jobs
#
#* **medium**: 100,001 - 500,000 households and jobs
#
#* **medium-large**: 500,001 - 1,000,000 households and jobs
#
#* **large**: 1,000,001 - 5,000,000 households and jobs
#
#* **very-large**: More than 5,000,000 households and jobs
#
#The models and procedures in this module create SimBzones within each Azone that simulate the land use characteristics of neighborhoods likely to be found in the Azone. The simulated characteristics include:
#
#* **Location Type**: Identification of whether the SimBzone is located in an urbanized area, a town (i.e. an urban-type area that is not large enough to be urbanized), rural (i.e. dispersed low-density development)
#
#* **Households**: Number of households in each SimBzone
#
#* **Employment**: Number of jobs in each SimBzone
#
### Model Parameter Estimation
#
#The process of developing SimBzones proceed in a series of steps. Model parameters are developed for each step. In a number of cases the parameters take the form of specific urbanized area or more general profiles.
#
#### Calculate the Number of Households by Azone and Location Type
#
#This procedure is driven by user inputs and does not have any model parameters. The user specifies the proportions of households by location type (urban, town, rural) for each Azone. These proportions are used to calculate the number of households in the Azone that are assigned to each location type.
#
#### Calculate the Number of Jobs by Azone and Location Type
#
#This procedure is driven by user inputs and does not have any model parameters. The user specifies where workers residing in the Azone work in terms of the proportional distribution of location types. Furthermore, the user specifies the proportion of urbanized area jobs in the Marea that the Azone is associated with that are in the Azone.
#
#### Create SimBzones by Azone and Location Type
#
#SimBzones are created to have roughly equal activity totals (households and jobs). The total activity in each Azone and location type is divided by median value calculated for block groups of that location type from the SLD data. The following table shows the median values by location type:
#
#<tab:SimBzone_ls$Docs$MedianActivity_df>
#
#The total amount of activity in each location type of the Azone is divided by the corresponding numbers in the table to arrive at the number of SimBzones by location type. Fractional remainders are allocated randomly among the SimBzones in each location type to get whole number amounts.
#
### How the Module Works
#

##</doc>

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
#Load libraries
library(visioneval)
library(plot3D)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#------------------------------
#SET UP DATA TO ESTIMATE MODELS
#------------------------------
#Load NHTS household data
D_df <- VESimLandUseData::SimLandUseData_df
#Create a list to hold model elements
SimBzone_ls <- list(
  UaProfiles = list(),
  TnProfiles = list(),
  RuProfiles = list(),
  Func = list(),
  Abbr = list(),
  Docs = list()
)

#--------------------------------------------------
#DEFINE FUNCTIONS USED IN MULTIPLE PLACES IN SCRIPT
#--------------------------------------------------
#Function to add a smoothed line to binned values
addSmoothLine <- function(X_, Y_, ...) {
  X_ <- X_[!is.na(Y_)]
  Y_ <- Y_[!is.na(Y_)]
  XY_SS <-smooth.spline(Y_ ~ X_)
  XPred_ <- seq(X_[1], X_[length(X_)], length = length(X_) * 10)
  lines(XPred_, predict(XY_SS, XPred_)$y, ...)
}
#Function to plot distributions for an urbanized area
plotDist <- function(UZA_NAME, VarName, LogTransform = TRUE, ...) {
  UzaDen <- round(ActDen_Ua[UZA_NAME], 1)
  Title <- paste0(UZA_NAME, "\n", "(Ave ", UzaDen, " HH & Jobs per acre)")
  if (LogTransform) {
    Dat_ <- log(Ua_df[,VarName])
    Xlim_ <- range(Dat_[!is.infinite(Dat_)])
    Var_ <- Dat_[Ua_df$UZA_NAME == UZA_NAME]
    Var_ <- Var_[!is.infinite(Var_)]
  } else {
    Dat_ <- Ua_df[,VarName]
    Xlim_ <- range(Dat_)
    Var_ <- Dat_[Ua_df$UZA_NAME == UZA_NAME]
  }
  plot(density(Var_), xlim = Xlim_, main = Title, ...)
  lines(density(Dat_), lty = 2)
}
#Function to calculate average density using group data
calcAveDensity <- function(AveDensity_, PropActivity_) {
  sum(1 / sum(PropActivity_ / AveDensity_, na.rm = TRUE), na.rm = TRUE)
}

#---------------------------------------------------------
#CREATE METROPOLITAN (URBANIZED), TOWN, AND RURAL DATASETS
#---------------------------------------------------------

#Split into urbanized area, town, and rural datasets
#---------------------------------------------------
#Identify places having NA in name
PlaceName_ <- unlist(lapply(strsplit(D_df$UZA_NAME, ","), function(x) {
  x[1]
}))
#Calculate area population and activity
TotPop_Ua <- tapply(D_df$TOTPOP10, D_df$UA_NAME, sum)
#Create dataset for urbanized areas having populations >= 50,000
Ua_df <- D_df[D_df$UA_NAME %in% names(TotPop_Ua)[TotPop_Ua >= 50000],]
#Create dataset for towns: named places having populations < 50,000
Tn_df <- D_df[!(D_df$UA_NAME %in% names(TotPop_Ua)[TotPop_Ua >= 50000]) & (PlaceName_ != "NA"),]
#Create dataset for rural areas: unnamed places
Ru_df <- D_df[PlaceName_ == "NA",]
#Clean up
rm(PlaceName_, TotPop_Ua)

#Calculate activity size category for urbanized areas
#----------------------------------------------------
TotAct_Ua <- tapply(Ua_df$TOTACT, Ua_df$UA_NAME, sum)
SzBrk_ <- c(0, 5e4, 1e5, 5e5, 1e6, 5e6, max(TotAct_Ua))
Sz <- c("small", "medium-small", "medium", "medium-large", "large", "very-large")
SzGrp_Ua <- cut(TotAct_Ua, SzBrk_, labels = Sz, include.lowest = TRUE)
names(SzGrp_Ua) <- names(TotAct_Ua)
Ua_df$UZA_SIZE <- SzGrp_Ua[match(Ua_df$UA_NAME, names(SzGrp_Ua))]
rm(TotAct_Ua, SzBrk_, SzGrp_Ua)
#Add size names to SimBzone_ls
SimBzone_ls$Abbr$Sz <- Sz

#Calculate overall urbanized area activity density
#-------------------------------------------------
#Calculate activity density by urbanized area
ActDen_Ua <- unlist(lapply(split(Ua_df, Ua_df$UZA_NAME), function(x){
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Add the calculations to Ua_df
Ua_df$UZA_ACTDEN <- ActDen_Ua[Ua_df$UZA_NAME]
#Calculate activity density by urbanized area size
ActDen_Sz <- unlist(lapply(split(Ua_df, Ua_df$UZA_SIZE), function(x){
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Combine the size based calculations with the urbanized area calculations
ActDen_Ua <- c(ActDen_Ua, ActDen_Sz)
rm(ActDen_Sz)
#Add ActDen_Ua to SimBzone_ls
SimBzone_ls$UaProfiles$ActDen_Ua <- ActDen_Ua

#Identify selected urbanized areas to use in comparison plots
#------------------------------------------------------------
UzaToPlot_ <- c(
  "Atlanta, GA",
  "Jacksonville, FL",
  "Cincinnati, OH",
  "Dallas-Fort Worth-Arlington, TX",
  "Baltimore, MD",
  "Denver-Aurora, CO",
  "Portland, OR",
  "San Francisco-Oakland, CA",
  "New York-Newark, NY"
)

#Create a table of urbanized area names to use for documentation
#---------------------------------------------------------------
#Make a sorted vector of urbanized area names
SimBzone_ls$UaProfiles$UzaNames <- sort(unique(Ua_df$UZA_NAME))
#Make a matrix having 3 columns
UzaNamesPad_ <- c(
  SimBzone_ls$UaProfiles$UzaNames,
  rep("", 3 - (length(SimBzone_ls$UaProfiles$UzaNames) %% 3)))
UzaNames_mx <- matrix(UzaNamesPad_, ncol = 3, byrow = TRUE)
#Make a data frame having 3 columns of the names
SimBzone_ls$Docs$UzaNames_df <-
  data.frame(UzaNames_mx)
names(SimBzone_ls$Docs$UzaNames_df) <- c("Column 1", "Column 2", "Column 3")
rm(UzaNamesPad_, UzaNames_mx)

#------------------------------
#PROCESS FOR CREATING SIMBZONES
#------------------------------
#SimBzones approximate Census block groups. They are created to have
#approximately equal amounts of total activity (number of households and jobs)
#consistent with control totals for the Azone. These control totals are the
#numbers of households and jobs by location type. The user specifies by Azone,
#the proportions of Azone households by location type. Those proportions are
#used to allocate numbers of households to location types in the Azone. The user
#also specifies the proportions of resident Azone workers by location type job
#location. In addition the proportion of Marea jobs in the Azone is a user user
#input. These data are used to calculate the number of jobs by Azone and
#location type. Households and jobs by location type are summed to determine the
#total amount of activity by Azone and location type. SimBzones are created for
#each location type in each Azone.

#Define function to allocate integer quantities among categories
#---------------------------------------------------------------
#' Allocate integer quantities among categories
#'
#' \code{splitIntegers}
splitIntegers <- function(Tot, Props_) {
  Ints_ <- round(Tot * Props_)
  Diff <- Tot - sum(Ints_)
  if (Diff != 0) {
    for (i in 1:abs(Diff)) {
      IdxToChg <- sample(1:length(Props_), 1, prob = Props_)
      Ints_[IdxToChg] <- Ints_[IdxToChg] + sign(Diff)
    }
  }
  Ints_
}

#Define function to calculate number of households by location type
#------------------------------------------------------------------
#' Calculate number of households by location type
#'
#' \code{calcNumHhByLocType} calculates the number of households by location
#' type for a set of Azones.
#'
#' This function calculates the number of households by location type for a
#' set of Azones as a function of the total number of households by Azone and
#' user inputs on the proportions of households by location type and Azone.
#' Location types are metropolitan (i.e. urbanized area), town (i.e. urban areas
#' that are not urbanized), and rural.
#'
#' @param NumHh_Az A numeric vector of the total number of households in each
#' Azone.
#' @param PropRuralHh_Az A numeric vector identifying the proportion of
#'   households in each Azone that are located in rural locations.
#' @param PropTownHh_Az A numeric vector identifying the proportion of
#'   households in each Azone that are located in town locations.
#' @param PropMetroHh_Az A numeric vector identifying the proportion of
#'   households in each Azone that are located in metropolitan locations.
#' @return A list having 3 named components (Rural, Town, Metropolitan) where
#' each component is a numeric vector identifying the number of households in
#' the respective location type in each Azone.
#' @export
calcNumHhByLocType <-
  function(NumHh_Az, PropRuralHh_Az, PropTownHh_Az, PropMetroHh_Az) {
    HhProp_AzLt <- cbind(
      Rural = PropRuralHh_Az,
      Town = PropTownHh_Az,
      Metropolitan = PropMetroHh_Az)
    Hh_AzLt <- t(apply(cbind(NumHh_Az, HhProp_AzLt), 1, function(x) {
      splitIntegers(x[1], x[2:4])}))
    list(
      Rural = Hh_AzLt[,"Rural"],
      Town = Hh_AzLt[,"Town"],
      Metropolitan = Hh_AzLt[,"Metropolitan"]
    )
  }

calcNumHhByLocType(
  NumHh_Az = c(3048, 5033, 4511),
  PropRuralHh_Az = c(0.15, 0.25, 0.4),
  PropTownHh_Az = c(0.25, 0.05, 0.4),
  PropMetroHh_Az = c(0.6, 0.7, 0.2)
)

#Define function to calculate the number of jobs by Azone location type
#----------------------------------------------------------------------
#' Calculate number of jobs by location type
#'
#' \code{calcNumJobsByLocType} calculates the number of jobs by location type
#' for a set of Azones
#'
#' This function calculates the number of jobs by location type for a set of
#' Azones as a function of the total number of workers by Azone and user inputs
#' on the proportions of jobs by location type (metropolitan, town, rural) and
#' Azone. In addition, the user specifies the proportional allocation of jobs
#' among the metropolitan portions of Azones that make up an Marea. The function
#' logic is based on the assumption that Azone workers having jobs in town and
#' rural locations, will work within the Azone where they reside but that
#' workers having metropolitan jobs may work in a different Azone portion of the
#' metropolitan area which includes their Azone.
#'
#' @param NumWkr_Az A numeric vector of the total number of workers residing in each
#' Azone.
#' @param PropWkrInRuralJobs_Az A numeric vector of the proportions of workers
#'   in each Azone that have jobs located in rural locations.
#' @param PropWkrInTownJobs_Az A numeric vector of the proportions of workers in
#'   each Azone that have jobs located in town locations.
#' @param PropWkrInMetroJobs_Az A numeric vector of the proportions of workers
#'   in each Azone that have jobs located in metropolitan locations.
#' @param PropMetroJobs_Az A numeric vector identifying the proportion of
#' metropolitan jobs for the Marea that the Azone is a part of that are located
#' in the metropolitan portion of the Azone.
#' @param Marea_Az A character vector identifying the Marea associated with each
#' Azone.
#' @return A list having 3 named components (Rural, Town, Metropolitan) where
#'   each component is a numeric vector identifying the number of jobs in the
#'   respective location type in each Azone.
#' @export
calcNumJobsByLocType <-
  function(NumWkr_Az, PropWkrInRuralJobs_Az, PropWkrInTownJobs_Az,
           PropWkrInMetroJobs_Az, PropMetroJobs_Az, Marea_Az) {
    #Initial allocation of jobs within Azones
    #----------------------------------------
    JobProp_AzLt <- cbind(
      Rural = PropWkrInRuralJobs_Az,
      Town = PropWkrInTownJobs_Az,
      Metropolitan = PropWkrInMetroJobs_Az)
    Jobs_AzLt <- t(apply(cbind(NumWkr_Az, JobProp_AzLt), 1, function(x) {
      splitIntegers(x[1], x[2:4])
    }))
    #Reallocate metropolitan jobs among Azones in the Marea
    #------------------------------------------------------
    #Create data frame of metropolitan data
    Metro_df <- data.frame(
      Jobs = Jobs_AzLt[,"Metropolitan"],
      PropMetroJobs = PropMetroJobs_Az,
      Marea = Marea_Az
    )
    #Split by metropolitan area
    Metro_Ma_df <- split(Metro_df, Metro_df$Marea)
    #Allocate metropolitan jobs among Azones in Marea
    MetroJobs_Az <- unlist(lapply(Metro_Ma_df, function(x) {
      splitIntegers(sum(x$Jobs), x$PropMetroJobs)
    }))
    #Return as list
    #--------------
    list(
      Rural = Jobs_AzLt[,"Rural"],
      Town = Jobs_AzLt[,"Town"],
      Metropolitan = unname(MetroJobs_Az)
    )
  }

Tmp_ls <- calcNumJobsByLocType(
  NumWkr_Az = c(3048, 5033, 4511, 4687),
  PropWkrInRuralJobs_Az = c(0.15, 0.25, 0.4, 0.5),
  PropWkrInTownJobs_Az = c(0.25, 0.05, 0.4, 0.5),
  PropWkrInMetroJobs_Az = c(0.6, 0.7, 0.2, 0),
  PropMetroJobs_Az = c(0.5, 0.5, 0, 0),
  Marea_Az = c("A", "A", "A", "None")
)

#Calculate the median amount of activity by Census block group
#-------------------------------------------------------------
#Assign median SimBzone size as median value by location type
SimBzone_ls$UaProfiles$MedianSimBzoneSize <- median(Ua_df$TOTACT)
SimBzone_ls$TnProfiles$MedianSimBzoneSize <- median(Tn_df$TOTACT)
SimBzone_ls$RuProfiles$MedianSimBzoneSize <- median(Ru_df$TOTACT)
#Document the median values
SimBzone_ls$Docs$MedianActivity_df <- data.frame(
  LocationType = c("Urban", "Town", "Rural"),
  MedianActivityAmount = c(
    median(Ua_df$TOTACT),
    median(Tn_df$TOTACT),
    median(Ru_df$TOTACT)
  )
)
names(SimBzone_ls$Docs$MedianActivity_df) <-
  c("Location Type", "Median Activity Amount")

save(SimBzone_ls, file = "data/SimBzone_ls.rda")



#--------------------------------------------------------------
#EVALUATE THE DISTRIBUTIONS OF 3D VARIABLES FOR URBANIZED AREAS
#--------------------------------------------------------------

#Plot overall urbanized area log-transformed distributions
#---------------------------------------------------------
#Plot log distributions (excluding 0 and infinity)
png("data/urbanized_d1-d2-d5_distributions.png", width = 480, height = 480)
InitPar_ls <- par(mfrow = c(2,2), oma = c(0,0,3,0))
with(Ua_df, {
  plot(density(log(D1D)),
       xlab = "Log of Jobs & HHs Per Acre",
       main = "Density of Jobs & HHs\n(D1D)")
  plot(density(log(D2A_JPHH[D2A_JPHH != 0 & !is.infinite(D2A_JPHH)])),
       xlab = "Log of Jobs / HHs",
       main = "Diversity: Jobs-Housing Ratio\n(D2A_JPHH)")
  plot(density(log(D5)),
       xlab = "Log of Accessibility\n(see text)",
       main = "Destination Accessibility\n(D5)")
  mtext("Distributions of Census Block Group 3D Measures for All Urbanized Areas",
        side = 3, outer = TRUE)
})
par(InitPar_ls)
rm(InitPar_ls)
dev.off()

#Plot activity density (D1D) distribution for selected urbanized areas
#---------------------------------------------------------------------
png("data/example-uza_d1_distributions.png", width = 600, height = 600)
InitPar_ls <- par(mfrow = c(3,3), oma = c(0, 0, 2.2, 0))
for (Ua in UzaToPlot_) {
  plotDist(Ua, "D1D", ylim = c(0, 0.8), xlab = "Natural log of D1D")
}
mtext("Block Group Activity Density Distribution (D1D) for Selected Urbanized Areas\nCompared to Distribution for All Urbanized Areas (dashed line)", outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()

#Plot diversity (D2A_JPHH) distribution for selected urbanized areas
#-------------------------------------------------------------------
png("data/example-uza_d2_distributions.png", width = 600, height = 600)
InitPar_ls <- par(mfrow = c(3,3), oma = c(0, 0, 2.2, 0))
for (Ua in UzaToPlot_[order(ActDen_Ua[UzaToPlot_])]) {
  plotDist(Ua, "D2A_JPHH", ylim = c(0, 0.35), xlab = "Natural log of D2A_JPHH")
}
mtext("Block Group Activity Diversity Distribution (D2A_JPHH) for Selected Urbanized Areas\nCompared to Distribution for All Urbanized Areas (dashed line)", outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()

#Plot destination accessibility (D5) distribution for selected urbanized areas
#-----------------------------------------------------------------------------
png("data/example-uza_d5_distributions.png", width = 600, height = 600)
InitPar_ls <- par(mfrow = c(3,3), oma = c(0, 0, 2.2, 0))
for (Ua in UzaToPlot_[order(ActDen_Ua[UzaToPlot_])]) {
  plotDist(Ua, "D5", ylim = c(0, 0.5), xlab = "Natural log of D5")
}
mtext("Block Group Destination Accessibility Distribution (D5) for Selected Urbanized Areas\nCompared to Distribution for All Urbanized Areas (dashed line)", outer = TRUE, line = -0.5)
par(InitPar_ls)
#Clean up
rm(Ua, InitPar_ls)
dev.off()


#---------------------------------------------------------------
#DEFINE AND ANALYZE URBANIZED AREA ACTIVITY DENSITY (D1D) LEVELS
#---------------------------------------------------------------

#Define activity density levels
#------------------------------
#Determine breaks by dividing log of D1D into 20 equal intervals
D1DGrpBrk_ <- local({
  LogD1D_ <- log(Ua_df$D1D)
  Interval <- diff(range(LogD1D_)) / 20
  LogBreaks_ <- min(LogD1D_) + 0:20 * Interval
  exp(LogBreaks_)
})
#Make sure the minimum and maximum values bound the breaks
D1DGrpBrk_[1] <- 0
D1DGrpBrk_[length(D1DGrpBrk_)] <- max(Ua_df$D1D)
#Save the breaks in SimBzone_ls$UaProfiles
SimBzone_ls$UaProfiles$D1DGrpBrk_ <- D1DGrpBrk_
#Identify the density group for each block group
D1DGrp_ <- cut(Ua_df$D1D, breaks = D1DGrpBrk_, include.lowest = TRUE)
#Calculate the average density for each quantile
D1DGrpAve_ <- unlist(lapply(split(Ua_df, D1DGrp_), function(x) {
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Calculate total activity in each quantile
D1DGrpTotAct_ <- tapply(Ua_df$TOTACT, D1DGrp_, sum)
#Add D1DGrp to Ua_df
Ua_df$D1DGrp <- D1DGrp_
#Calculate the proportion of total activity by group
D1DGrpPropAct_ <- D1DGrpTotAct_ / sum(D1DGrpTotAct_)
#Create a list to save the urbanized area D1D group data
D1DGrp_ls <- list(
  AveDensity = D1DGrpAve_,
  PropActivity = D1DGrpPropAct_
)

#Plot activity proportions and average density by density group
#--------------------------------------------------------------
#Plot the proportion of total activity by group
png("data/prop_uza_act_by_d1-group.png")
plot(1:20, D1DGrpPropAct_,
     xlab = "Activity Density (D1D) Group",
     ylab = "Proportion of Activity (HHs & Jobs)",
     main = "Proportions of Activity by Activity Density Group\nBlock Groups in All Urbanized Areas")
addSmoothLine(1:20, D1DGrpPropAct_, lty = 2)
dev.off()
#Plot the group D1D averages
png("data/ave_den_by_d1-group.png")
plot(1:20, D1DGrpAve_,
     xlab = "Activity Density (D1D) Group",
     ylab = "Average Density (HHs + Jobs per Acre)",
     main = "Average Activity Density by Activity Density Group\nBlocks Groups in All Urbanized Areas")
addSmoothLine(1:20, D1DGrpAve_, lty = 2)
dev.off()
#Clean up
rm(D1DGrpBrk_, D1DGrp_, D1DGrpTotAct_, D1DGrpAve_, D1DGrpPropAct_)

#Calculate activity density bin information for urbanized areas
#--------------------------------------------------------------
#Split data by urbanized area
D_Ua_df <- split(Ua_df, Ua_df$UZA_NAME)
#Calculate average density and proportion of activity by density group
D1DGrp_Ua_ls <- lapply(D_Ua_df, function(x) {
  GrpSplit_ls <- split(x, x$D1DGrp)
  list(
    AveDensity =
      unlist(lapply(GrpSplit_ls, function(x) sum(x$TOTACT) / sum(x$AC_LAND))),
    PropActivity =
      tapply(x$TOTACT, x$D1DGrp, sum) / sum(x$TOTACT)
  )
})
rm(D_Ua_df)
#Split data by urbanized area size category
D_Sz_df <- split(Ua_df, Ua_df$UZA_SIZE)
#Calculate average density and proportion of activity by density group
D1DGrp_Sz_ls <- lapply(D_Sz_df, function(x) {
  GrpSplit_ls <- split(x, x$D1DGrp)
  list(
    AveDensity =
      unlist(lapply(GrpSplit_ls, function(x) sum(x$TOTACT) / sum(x$AC_LAND))),
    PropActivity =
      tapply(x$TOTACT, x$D1DGrp, sum) / sum(x$TOTACT)
  )
})
#Add generic urbanized areas by size to urbanized area list
for (sz in Sz) {
  D1DGrp_Ua_ls[[sz]] <- D1DGrp_Sz_ls[[sz]]
}
rm(D_Sz_df, D1DGrp_Sz_ls, sz)

#Save the tabulation in SimBzone_ls
#----------------------------------
SimBzone_ls$UaProfiles$D1DGrp_ls <- D1DGrp_ls
SimBzone_ls$UaProfiles$D1DGrp_Ua_ls <- D1DGrp_Ua_ls
rm(D1DGrp_ls, D1DGrp_Ua_ls)


#----------------------------------------------------------
#IDENTIFY ACTIVITY DENSITY LEVELS FOR TOWNS AND RURAL AREAS
#----------------------------------------------------------
#Unlike the urbanized areas, these data are calculated for town areas as a
#whole and and for rural areas as a whole.

#Define town activity density levels
#------------------------------------
#Limit data to records above 1st percentile and below 99th percentile to remove
#outliers
Tn_df <- Tn_df[Tn_df$D1D > quantile(Tn_df$D1D, 0.01),]
Tn_df <- Tn_df[Tn_df$D1D < quantile(Tn_df$D1D, 0.99),]
#Determine breaks by dividing log of D1D into 20 equal intervals
D1DGrpBrk_ <- local({
  LogD1D_ <- log(Tn_df$D1D)
  Interval <- diff(range(LogD1D_)) / 20
  LogBreaks_ <- min(LogD1D_) + 0:20 * Interval
  exp(LogBreaks_)
})
#Make sure the minimum and maximum values bound the breaks
D1DGrpBrk_[1] <- 0
D1DGrpBrk_[length(D1DGrpBrk_)] <- max(Tn_df$D1D)
#Save the breaks in SimBzone_ls$UaProfiles
SimBzone_ls$TnProfiles$D1DGrpBrk_ <- D1DGrpBrk_
#Identify the density group for each block group
D1DGrp_ <- cut(Tn_df$D1D, breaks = D1DGrpBrk_, include.lowest = TRUE)

#Calculate average density and proportion of activity for each town level
#------------------------------------------------------------------------
#Calculate the average density for each quantile
D1DGrpAve_ <- unlist(lapply(split(Tn_df, D1DGrp_), function(x) {
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Calculate total activity in each quantile
D1DGrpTotAct_ <- tapply(Tn_df$TOTACT, D1DGrp_, sum)
#Add D1DGrp to Tn_df
Tn_df$D1DGrp <- D1DGrp_
#Calculate the proportion of total activity by group
D1DGrpPropAct_ <- D1DGrpTotAct_ / sum(D1DGrpTotAct_)
#Save the town activity proportions and average density by group
SimBzone_ls$TnProfiles$D1DGrp_ls <- list(
  AveDensity = D1DGrpAve_,
  PropActivity = D1DGrpPropAct_
)
rm(D1DGrpBrk_, D1DGrp_, D1DGrpAve_, D1DGrpTotAct_, D1DGrpPropAct_)

#Define rural activity density levels
#------------------------------------
#Limit data to records above 1st percentile and below 99th percentile to remove
#outliers
Ru_df <- Ru_df[Ru_df$D1D > quantile(Ru_df$D1D, 0.01),]
Ru_df <- Ru_df[Ru_df$D1D < quantile(Ru_df$D1D, 0.99),]
#Determine breaks by dividing log of D1D into 20 equal intervals
D1DGrpBrk_ <- local({
  LogD1D_ <- log(Ru_df$D1D)
  Interval <- diff(range(LogD1D_)) / 20
  LogBreaks_ <- min(LogD1D_) + 0:20 * Interval
  exp(LogBreaks_)
})
#Make sure the minimum and maximum values bound the breaks
D1DGrpBrk_[1] <- 0
D1DGrpBrk_[length(D1DGrpBrk_)] <- max(Ru_df$D1D)
#Save the breaks in SimBzone_ls$UaProfiles
SimBzone_ls$RuProfiles$D1DGrpBrk_ <- D1DGrpBrk_
#Identify the density group for each block group
D1DGrp_ <- cut(Ru_df$D1D, breaks = D1DGrpBrk_, include.lowest = TRUE)

#Calculate average density and proportion of activity for each rural level
#-------------------------------------------------------------------------
#Calculate the average density for each quantile
D1DGrpAve_ <- unlist(lapply(split(Ru_df, D1DGrp_), function(x) {
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Calculate total activity in each quantile
D1DGrpTotAct_ <- tapply(Ru_df$TOTACT, D1DGrp_, sum)
#Add D1DGrp to Ru_df
Ru_df$D1DGrp <- D1DGrp_
#Calculate the proportion of total activity by group
D1DGrpPropAct_ <- D1DGrpTotAct_ / sum(D1DGrpTotAct_)
#Save the town activity proportions and average density by group
SimBzone_ls$RuProfiles$D1DGrp_ls <- list(
  AveDensity = D1DGrpAve_,
  PropActivity = D1DGrpPropAct_
)
rm(D1DGrpBrk_, D1DGrp_, D1DGrpAve_, D1DGrpTotAct_, D1DGrpPropAct_)


#-----------------------------------------
#FUNCTIONS FOR PREDICTING SIMBZONE DENSITY
#-----------------------------------------
#Two functions are used to The model adjusts the distribution of activity by density group in response to
#a change in the overall density of the urbanized area. This is done by
#iteratively taking a weighted moving average of the activity proportion in each
#bin with the activity proportion in the bin to the left (if overall density
#increases) or to the right (if overall density decreases).

#Define function to calculate density distribution
#-------------------------------------------------
#' Adjust area density distribution to match average density target
#'
#' \code{calcDensityDistribution} calculates for an area, such as an urbanized
#' area, the proportions of activity by density group and the average density by
#' density group to match an overall area density target.
#'
#' This function calculates for an area, such as an urbanized area, the
#' proportions of activity by density group and the average density by density
#' group to match an overall area density target. The calculation process begins
#' with distributions of the proportions of activity and average density by
#' density group estimated for the area from the Smart Location Database. If the
#' average density is missing for one or more density groups, the averages for
#' the type of area are inserted for the missing values. For example, if the
#' area is an urbanized area, the average values for all urbanized areas are
#' used. The function then in small increments, adjusts the proportion of
#' activity in each bin as a weighted average of the value of the bin and the
#' value of the bin to the right or left. If the target density is greater than
#' the overall density for the area at the start, the value of the bin to the
#' left is uses. The reverse is the case if the target is less than the starting
#' density for the area. In each iteration, the 99% of the bin value is added to
#' 1% of the adjacent bin value and then the results are divided by the sum of
#' all bin values. When the overall density is within 10% of the target density,
#' 99.9% of the bin value is added to 0.1% of the adjacent bin value. When the
#' overall density is within 1% of the target density, the adjustment of
#' activity proportions ends, and the average density of each bin is adjusted so
#' that the overall density equals the target.
#'
#' @param DenDist_ A numeric vector of the model proportions of activity by
#' activity density bin for the area.
#' @param AreaAveDensity_ A numeric vector of the model average activity density
#' by activity density bin for the area.
#' @param Target A number specifying the average activity density for the
#' area measured in numbers of households and jobs per acre.
#' @param LocTyAveDensity_ A numeric vector of the average activity density by
#' activity density bin for the location type. For example if the location
#' type is metropolitan, it is the average density distribution for all
#' urbanized areas.
#' @return A data frame having 20 rows and 2 columns: ActProp, the proportion of
#' urbanized activity by activity density bin; and AveDensity, the average
#' density by activity density bin.
#' @export
calcDensityDistribution <-
  function(DenDist_, AreaAveDensity_, Target, LocTyAveDensity_) {
    #Fill in NA values in DenDist_ and AveDensity_
    DenDist_[is.na(DenDist_)] <- 0
    AreaAveDensity_[is.na(AreaAveDensity_)] <-
      LocTyAveDensity_[is.na(AreaAveDensity_)]
    #Define function to calculate overall average density
    calcAveDensity <- function(AveDensity_, PropActivity_) {
      sum(1 / sum(PropActivity_ / AveDensity_, na.rm = TRUE), na.rm = TRUE)
    }
    #Initial calculation of average density
    AveDensity <- calcAveDensity(AreaAveDensity_, DenDist_)
    #Define a function to make an incremental adjustment in density distribution
    makeAdj <- function(DenDist_, AdjProp){
      if (Target > AveDensity) {
        ShiftDist_ <- c(0, DenDist_[-length(DenDist_)])
      } else {
        ShiftDist_ <- c(DenDist_[-1], 0)
      }
      AdjDenDist_ <- (1 - AdjProp) * DenDist_ + AdjProp * ShiftDist_
      AdjDenDist_ / sum(AdjDenDist_)
    }
    #Make incremental adjustments until target is approximately achieved
    while (abs(1 - (Target / AveDensity)) > 0.01) {
      TargetDiff <- abs(Target - AveDensity)
      if (TargetDiff > 0.1) {
        DenDist_ <- makeAdj(DenDist_, 0.01)
      } else {
        DenDist_ <- makeAdj(DenDist_, 0.001)
      }
      AveDensity <- calcAveDensity(AreaAveDensity_, DenDist_)
    }
    #Make final adjustments to density bin averages
    AreaAveDensity_ <- AreaAveDensity_ * Target / AveDensity
    #Return data frame of density distribution and average density
    data.frame(
      ActProp = DenDist_,
      AveDensity = AreaAveDensity_
    )
  }

#Test function with Portland increasing to density of New York
#-------------------------------------------------------------
AdjDenDist_df <- calcDensityDistribution(
  SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$PropActivity,
  SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$AveDensity,
  SimBzone_ls$UaProfiles$ActDen_Ua["New York-Newark, NY"],
  SimBzone_ls$UaProfiles$D1DGrp_ls$AveDensity)
calcAveDensity(AdjDenDist_df$AveDensity, AdjDenDist_df$ActProp)
SimBzone_ls$UaProfiles$ActDen_Ua["New York-Newark, NY"]
#Plot comparison of density distributions
png("data/test_density_adjustment_up.png", width = 600, height = 600)
plot(SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$PropActivity,
     xlab = "Activity Density (D1D) Group",
     ylab = "Proportion of Activity (HHs & Jobs)",
     main = "Test of Adjusting Urbanized Area Average Activity Density (D1D) Upward\nPortland (OR) Activity Density -> New York (NY) Activity Density")
addSmoothLine(1:20, SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$PropActivity)
points(1:20, AdjDenDist_df$ActProp, col="red")
addSmoothLine(1:20, AdjDenDist_df$ActProp, col="red")
points(1:20, SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["New York-Newark, NY"]]$PropActivity, col = "green")
addSmoothLine(1:20, SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["New York-Newark, NY"]]$PropActivity, col = "green")
legend("topleft", lty = 1, col = c("black", "red", "green"), bty = "n",
       legend = c("Portland Density", "Portland at New York Density", "New York Density"))
dev.off()
rm(AdjDenDist_df)

#Test function with with Portland decreasing to density of Atlanta
#-----------------------------------------------------------------
AdjDenDist_df <- calcDensityDistribution(
  SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$PropActivity,
  SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$AveDensity,
  SimBzone_ls$UaProfiles$ActDen_Ua["Atlanta, GA"],
  SimBzone_ls$UaProfiles$D1DGrp_ls$AveDensity)
calcAveDensity(AdjDenDist_df$AveDensity, AdjDenDist_df$ActProp)
SimBzone_ls$UaProfiles$ActDen_Ua["Atlanta, GA"]
#Plot comparison of density distributions
png("data/test_density_adjustment_down.png", width = 600, height = 600)
plot(SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$PropActivity,
     xlab = "Activity Density (D1D) Group",
     ylab = "Proportion of Activity (HHs & Jobs)",
     main = "Test of Adjusting Urbanized Area Average Activity Density (D1D) Downward\nPortland (OR) Activity Density -> Atlanta Activity Density")
addSmoothLine(1:20, SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Portland, OR"]]$PropActivity)
points(1:20, AdjDenDist_df$ActProp, col="red")
addSmoothLine(1:20, AdjDenDist_df$ActProp, col="red")
points(1:20, SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Atlanta, GA"]]$PropActivity, col = "green")
addSmoothLine(1:20, SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[["Atlanta, GA"]]$PropActivity, col = "green")
legend("topleft", lty = 1, col = c("black", "red", "green"), bty = "n",
       legend = c("Portland Density", "Portland at Atlanta Density", "Atlanta Density"))
dev.off()
#Clean up
rm(AdjDenDist_df)

#Test function for towns by increasing density by 20% and decreasing by 20%
#--------------------------------------------------------------------------
# StartActDen <-
#   with(SimBzone_ls$TnProfiles$D1DGrp_ls,
#        calcAveDensity(AveDensity, PropActivity))
# AdjDenDist_df <-
#   with(SimBzone_ls$TnProfiles$D1DGrp_ls,
#        calcDensityDistribution(PropActivity, AveDensity, 1.2 * StartActDen,
#          AveDensity))
# EndActDen <- calcAveDensity(AdjDenDist_df$AveDensity, AdjDenDist_df$ActProp)
# EndActDen / StartActDen
# AdjDenDist_df <-
#   with(SimBzone_ls$TnProfiles$D1DGrp_ls,
#        calcDensityDistribution(PropActivity, AveDensity, 0.8 * StartActDen,
#                                AveDensity))
# EndActDen <- calcAveDensity(AdjDenDist_df$AveDensity, AdjDenDist_df$ActProp)
# EndActDen / StartActDen
# rm(StartActDen, AdjDenDist_df, EndActDen)

#Test function for rural by increasing density by 20% and decreasing by 20%
#--------------------------------------------------------------------------
# StartActDen <-
#   with(SimBzone_ls$RuProfiles$D1DGrp_ls,
#        calcAveDensity(AveDensity, PropActivity))
# AdjDenDist_df <-
#   with(SimBzone_ls$RuProfiles$D1DGrp_ls,
#        calcDensityDistribution(PropActivity, AveDensity, 1.2 * StartActDen,
#                                AveDensity))
# EndActDen <- calcAveDensity(AdjDenDist_df$AveDensity, AdjDenDist_df$ActProp)
# EndActDen / StartActDen
# AdjDenDist_df <-
#   with(SimBzone_ls$RuProfiles$D1DGrp_ls,
#        calcDensityDistribution(PropActivity, AveDensity, 0.8 * StartActDen,
#                                AveDensity))
# EndActDen <- calcAveDensity(AdjDenDist_df$AveDensity, AdjDenDist_df$ActProp)
# EndActDen / StartActDen
# rm(StartActDen, AdjDenDist_df, EndActDen)


#-----------------------------------------------------------------------------
#ANALYSE RELATIONSHIP OF URBANIZED AREA DIVERSITY (D2A_JPHH) AND DENSITY (D1D)
#-----------------------------------------------------------------------------
#Although the correlation between block group activity diversity (D2A_JPHH) and
#density (D1D) is weak, there are relationships at an aggregate level that are
#useful to capture. For example, urbanized areas characterized by very high
#density levels tend to have high ratios to jobs to households.

#Identify diversity group levels
#-------------------------------
#5 diversity group levels are defined from a lowest level where households
#dominate to the highest level where jobs dominate. The middle level has the
#most balance where the ratio of jobs to households and the inverse ratio does
#not exceed 2:1.
D2GrpBrk_ <- c(
  min(Ua_df$D2A_JPHH), 0.25, 0.5, 2, 4, max(Ua_df$D2A_JPHH)
)
D2 <- c("primarily-hh", "largely-hh", "mixed", "largely-job", "primarily-job")
SimBzone_ls$Abbr$D2 <- D2
D2Grp_ <- cut(Ua_df$D2A_JPHH, D2GrpBrk_, labels = D2, include.lowest = TRUE)
Ua_df$D2Grp <- D2Grp_
rm(D2GrpBrk_, D2Grp_)

#Calculate proportions of activity by diversity group for each density group
#All urbanized areas
#---------------------------------------------------------------------------
TotAct_D1D2 <- with(Ua_df, tapply(TOTACT, list(D1DGrp, D2Grp), sum))
TotAct_D1D2[is.na(TotAct_D1D2)] <- 0
D2ActProp_D1D2 <- sweep(TotAct_D1D2, 1, rowSums(TotAct_D1D2), "/")
png("data/uza_d2group-prop-act_by_d1group.png", width = 500, height = 500)
DispPal_ <- colorRampPalette(c("black", "yellow"))(10)
image2D(D2ActProp_D1D2,
        x = 1:20, y = 1:5,
        xlab = "Density Group",
        ylab = "Diversity Group",
        zlim = c(0,1),
        col = DispPal_, NAcol = "black",
        axes = FALSE,
        main = "Diversity Group Proportion of Activity by Density Group\nFor Urbanized Areas")
axis(1)
axis(2, at = 1:5, labels = D2)
rm(DispPal_)
dev.off()

#Urbanized area proportions of activity by diversity group at each density group
#-------------------------------------------------------------------------------
#Calculate the relationship for all urbanized areas
TotAct_D1D2 <- with(Ua_df, tapply(TOTACT, list(D1DGrp, D2Grp), sum))
SimBzone_ls$UaProfiles$D2ActProp_D1D2 <-
  sweep(TotAct_D1D2, 1, rowSums(TotAct_D1D2, na.rm = TRUE), "/")
rm(TotAct_D1D2)
#Calculate relationship for each urbanized area
Tmp_Ua_df <- split(Ua_df, Ua_df$UZA_NAME)
D2ActProp_Ua_D1D2 <- lapply(Tmp_Ua_df, function(x) {
  TotAct_D1D2 <- tapply(x$TOTACT, list(x$D1DGrp, x$D2Grp), sum)
  D2ActProp_D1D2 <-
    sweep(TotAct_D1D2, 1, rowSums(TotAct_D1D2, na.rm = TRUE), "/")
  D2ActProp_D1D2[is.nan(D2ActProp_D1D2)] <- 0
  D2ActProp_D1D2
})
ActProp_Ua_D2 <- lapply(Tmp_Ua_df, function(x) {
  TotAct_D2 <- tapply(x$TOTACT, x$D2Grp, sum)
  TotAct_D2[is.na(TotAct_D2)] <- 0
  TotAct_D2 / sum(TotAct_D2)
})
rm(Tmp_Ua_df)
#Calculate relationship for each urbanized area size group
Tmp_Sz_df <- split(Ua_df, Ua_df$UZA_SIZE)
D2ActProp_Sz_D1D2 <- lapply(Tmp_Sz_df, function(x) {
  TotAct_D1D2 <- tapply(x$TOTACT, list(x$D1DGrp, x$D2Grp), sum)
  D2ActProp_D1D2 <-
    sweep(TotAct_D1D2, 1, rowSums(TotAct_D1D2, na.rm = TRUE), "/")
  D2ActProp_D1D2[is.nan(D2ActProp_D1D2)] <- 0
  D2ActProp_D1D2
})
ActProp_Sz_D2 <- lapply(Tmp_Sz_df, function(x) {
  TotAct_D2 <- tapply(x$TOTACT, x$D2Grp, sum)
  TotAct_D2[is.na(TotAct_D2)] <- 0
  TotAct_D2 / sum(TotAct_D2)
})
rm(Tmp_Sz_df)
#Add urbanized area size group tabulations to urbanized area list
for (sz in Sz) {
  D2ActProp_Ua_D1D2[[sz]] <- D2ActProp_Sz_D1D2[[sz]]
  ActProp_Ua_D2[[sz]] <- ActProp_Sz_D2[[sz]]
}
#Save in SimBzone_ls
SimBzone_ls$UaProfiles$D2ActProp_Ua_D1D2 <- D2ActProp_Ua_D1D2
rm(TotAct_D1D2, ActProp_Ua_D2, D2ActProp_D1D2, D2ActProp_Ua_D1D2,
   D2ActProp_Sz_D1D2, ActProp_Sz_D2, sz)

#Compare diversity patterns for selected metropolitan areas
#----------------------------------------------------------
png("data/example-uza_d2group-prop-act_by_d1group.png", width = 700, height = 600)
DispPal_ <- colorRampPalette(c("black", "yellow"))(10)
InitPar_ls <- par(mfrow = c(3,3), mar = c(4,4,3,3), oma = c(0, 0, 2.2, 0))
for (Ua in UzaToPlot_) {
  ImageDat_D1D2 <- SimBzone_ls$UaProfiles$D2ActProp_Ua_D1D2[[Ua]]
  image2D(ImageDat_D1D2,
          x = 1:20, y = 1:5,
          zlim = c(0,1),
          xlab = "Density Group",
          ylab = "Diversity Group",
          col = DispPal_, NAcol = "black",
          main = Ua, axes = FALSE)
  axis(1)
  axis(2, at = 1:5,
       labels = c("Prn\nHH", "Lrg\nHH", "Mix", "Lrg\nJOB", "Prn\nJOB"))
  rm(ImageDat_D1D2)
}
mtext("Activity Proportions by Diversity Group for Each D1D Group\nFor Selected Urbanized Areas",
      outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()
rm(Ua, InitPar_ls, DispPal_)

#Compare diversity patterns by urbanized area size group
#-------------------------------------------------------
png("data/uza-size-group_d2group-prop-act_by_d1group.png", width = 700, height = 500)
DispPal_ <- colorRampPalette(c("black", "yellow"))(10)
InitPar_ls <- par(mfrow = c(2,3), mar = c(3,4,3,3), oma = c(0, 0, 2.2, 0))
for (sz in Sz) {
  ImageDat_D1D2 <- SimBzone_ls$UaProfiles$D2ActProp_Ua_D1D2[[sz]]
  image2D(ImageDat_D1D2,
          x = 1:20, y = 1:5,
          zlim = c(0,1),
          xlab = "Density Group",
          ylab = "Diversity Group",
          col = DispPal_, NAcol = "black",
          main = sz, axes = FALSE)
  axis(1)
  axis(2, at = 1:5,
       labels = c("Prn\nHH", "Lrg\nHH", "Mix", "Lrg\nJOB", "Prn\nJOB"))
  rm(ImageDat_D1D2)
}
mtext("Activity Proportions by Diversity Group for Each D1D Group\nBy Urbanized Area Size",
      outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()
rm(InitPar_ls, DispPal_)

#Calculate distribution of job proportions by diversity level
#------------------------------------------------------------
#The proportion of block group activity that is jobs is calculated as a more
#useful diversity measure to use to allocate SimBzone activity between jobs and
#households. For each diversity level, distributions of the jobs proportion of
#activity is calculated. These distributions will be sampling distributions.
TotAct_ <- Ua_df$TOTACT
PropEmp_ <- Ua_df$EMPTOT / TotAct_
SimBzone_ls$UaProfiles$EmpProp_D2_ls <- list()
for (d2 in D2) {
  DoSelect_ <- as.character(Ua_df$D2Grp) == d2
  PropEmpToPlot_ <- rep(PropEmp_[DoSelect_], TotAct_[DoSelect_])
  Tmp_HS <- hist(PropEmpToPlot_, plot = FALSE)
  SimBzone_ls$UaProfiles$EmpProp_D2_ls[[d2]] <- list(
    Values = Tmp_HS$mids,
    Probs = Tmp_HS$counts / sum(Tmp_HS$counts)
  )
  rm(DoSelect_, PropEmpToPlot_, Tmp_HS)
}
rm(d2)
#Plot the distribution of proportion of employment by diversity level
png("data/emp-prop-distribution_by_d2group.png", width = 600, height = 600)
Opar_ls <- par(mfrow = c(2,3), oma = c(0,0,3,0))
for (d2 in D2) {
  DoSelect_ <- as.character(Ua_df$D2Grp) == d2
  PropEmpToPlot_ <- rep(PropEmp_[DoSelect_], TotAct_[DoSelect_])
  hist(PropEmpToPlot_, freq = FALSE,
       xlab = "Jobs Proportion",
       main = d2)
  rm(DoSelect_, PropEmpToPlot_)
}
mtext(
  text = paste0("Distribution Block Group Activity by Job Proportion of Activity\n",
                "By Jobs-Household Ratio Level"),
  side = 3, line = 0, outer = TRUE)
par(Opar_ls)
dev.off()
rm(PropEmp_, TotAct_, Opar_ls, d2)

#---------------------------------------------------------------------------
#ANALYSE RELATIONSHIP OF TOWN & RURAL DIVERSITY (D2A_JPHH) AND DENSITY (D1D)
#---------------------------------------------------------------------------

#Identify town diversity group levels
#------------------------------------
D2GrpBrk_ <- c(
  min(Tn_df$D2A_JPHH), 0.25, 0.5, 2, 4, max(Tn_df$D2A_JPHH)
)
D2Grp_ <- cut(Tn_df$D2A_JPHH, D2GrpBrk_, labels = D2, include.lowest = TRUE)
Tn_df$D2Grp <- D2Grp_

#Calculate town proportions of activity by diversity group for each density group
#--------------------------------------------------------------------------------
TotAct_D1D2 <- with(Tn_df, tapply(TOTACT, list(D1DGrp, D2Grp), sum))
TotAct_D1D2[is.na(TotAct_D1D2)] <- 0
SimBzone_ls$TnProfiles$D2ActProp_D1D2 <- sweep(TotAct_D1D2, 1, rowSums(TotAct_D1D2), "/")
rm(TotAct_D1D2, D2GrpBrk_, D2Grp_)

#Calculate town distribution of job proportions by diversity level
#-----------------------------------------------------------------
TotAct_ <- Tn_df$TOTACT
PropEmp_ <- Tn_df$EMPTOT / TotAct_
SimBzone_ls$TnProfiles$EmpProp_D2_ls <- list()
for (d2 in D2) {
  DoSelect_ <- as.character(Tn_df$D2Grp) == d2
  PropEmpToPlot_ <- rep(PropEmp_[DoSelect_], TotAct_[DoSelect_])
  Tmp_HS <- hist(PropEmpToPlot_, plot = FALSE)
  SimBzone_ls$TnProfiles$EmpProp_D2_ls[[d2]] <- list(
    Values = Tmp_HS$mids,
    Probs = Tmp_HS$counts / sum(Tmp_HS$counts)
  )
  rm(DoSelect_, PropEmpToPlot_, Tmp_HS)
}
rm(d2, TotAct_, PropEmp_)

#Identify rural diversity group levels
#-------------------------------------
D2GrpBrk_ <- c(
  min(Ru_df$D2A_JPHH), 0.25, 0.5, 2, 4, max(Ru_df$D2A_JPHH)
)
D2Grp_ <- cut(Ru_df$D2A_JPHH, D2GrpBrk_, labels = D2, include.lowest = TRUE)
Ru_df$D2Grp <- D2Grp_

#Calculate rural proportions of activity by diversity group for each density group
#---------------------------------------------------------------------------------
TotAct_D1D2 <- with(Ru_df, tapply(TOTACT, list(D1DGrp, D2Grp), sum))
TotAct_D1D2[is.na(TotAct_D1D2)] <- 0
SimBzone_ls$RuProfiles$D2ActProp_D1D2 <- sweep(TotAct_D1D2, 1, rowSums(TotAct_D1D2), "/")
rm(TotAct_D1D2, D2GrpBrk_, D2Grp_)

#Calculate rural distribution of job proportions by diversity level
#------------------------------------------------------------------
TotAct_ <- Ru_df$TOTACT
PropEmp_ <- Ru_df$EMPTOT / TotAct_
SimBzone_ls$RuProfiles$EmpProp_D2_ls <- list()
for (d2 in D2) {
  DoSelect_ <- as.character(Ru_df$D2Grp) == d2
  PropEmpToPlot_ <- rep(PropEmp_[DoSelect_], TotAct_[DoSelect_])
  Tmp_HS <- hist(PropEmpToPlot_, plot = FALSE)
  SimBzone_ls$RuProfiles$EmpProp_D2_ls[[d2]] <- list(
    Values = Tmp_HS$mids,
    Probs = Tmp_HS$counts / sum(Tmp_HS$counts)
  )
  rm(DoSelect_, PropEmpToPlot_, Tmp_HS)
}
rm(d2, TotAct_, PropEmp_)

#-----------------------------------------------------------
#ASSIGNING DIVERSITY LEVEL AND NUMBERS OF JOB AND HOUSEHOLDS
#-----------------------------------------------------------

#Define function to assign diversity group and numbers of jobs and households
#----------------------------------------------------------------------------
#' Assign diversity group and numbers of jobs and households
#'
#' \code{calcDiversity} assigns a diversity group for each SimBzone and splits
#' activity into numbers of jobs and households.
#'
#' This function assigns a diversity group to each SimBzone based on the
#' density profile of the area, the modeled relationship of the
#' distribution of activity between diversity groups at each density level. The
#' 5 diversity groups are primarily-household, largely-household, mixed,
#' largely-employment, and primarily-employment. In the case of urbanized areas,
#' the distribution of activity by diversity group vs. density group
#' relationship is the modeled relationship from the Smart Location Database.
#' Average urbanized area values are substituted for density groups missing from
#' the values for the urbanized area. The proportions are used as sampling
#' distributions for assigning a diversity group to each SimBzone. The
#' employment split of activity is modeled using the estimated frequencies of
#' employment proportions by diversity group. The employment proportions are
#' adjusted so that the total number of jobs equals the input control total.
#'
#' @param Act_Bz A numeric vector of the total activity assigned to each
#' SimBzone.
#' @param ActDenGrp_Bz A character vector of the activity density group assigned
#' to each SimBzone where activity density is measured as the number of jobs and
#' households per acre.
#' @param TotEmp A number specifying the total number of jobs in the area.
#' @param D2ActProp_D1D2 A numeric matrix which specifies the proportions of
#' activity in each diversity group by density group. The rows of the matrix
#' represent density groups and the columns represent diversity groups.
#' @param EmpProp_D2_ls a list having five components, one for each diversity
#' level. Each component is a list with two components. The 'Values' component
#' is a numeric vector which specifies values for the employment proportions for
#' a number of bins. The 'Probs' component is a numeric vector identifying the
#' probability of each bin.
#' @param LocTyD2ActProp_D1D2 A numeric matrix which specifies the proportions of
#' activity in each diversity group by density group for the location type.
#' For example if the location type is metropolitan, it is the proportions
#' matrix for all urbanized areas.
#' @param MixTarget A number specifying a target for the proportion of activity
#' in mixed diversity group or NULL if no target is specified.
#' @return A list having 3 components as follows:
#' D2Grp - a character vector identifying the diversity group of each SimBzone,
#' Jobs - a numeric vector identifying the number of jobs in each SimBzone,
#' HHs - a numeric vector identifying the number of households in each SimBzone
#' @export
calcDiversity <-
  function(Act_Bz, ActDen_Bz, TotEmp, D2ActProp_D1D2, EmpProp_D2_ls,
           LocTyD2ActProp_D1D2, MixTarget = NULL) {
    #Function to fill in values for densities that are missing


  }
#Create D2 activity proportions sampling matrix
D2ActProp_D1D2 <-
  fillMissingUaActProp(
    Ds_ls$D2ActProp_Ua_D1D2[[UzaName]], Ds_ls$D2ActProp_D1D2)
#Assign diversity values to Bzones
for (az in Az) {
  SimBzone_df <- SimBzone_Az_df[[az]]
  #Assign diversity levels
  D2Grp_Bz <- sapply(SimBzone_df$D1Grp, function(x) {
    sample(colnames(D2ActProp_D1D2), 1, prob = D2ActProp_D1D2[x,])
  })
  #Calculate numbers of jobs by Bzone
  EmpProp_Bz <- sapply(D2Grp_Bz, function(x) {
    Sample_ls <- Ds_ls$EmpProp_D2_ls[[x]]
    sample(Sample_ls$Values, 1, prob = Sample_ls$Probs)
  })
  Jobs_Bz <- unname(round(SimBzone_df$Activity * EmpProp_Bz))
  #Adjust jobs to match inputs
  TargetJobs <- TotJobs_Az[az]
  JobDiff <- TargetJobs - sum(Jobs_Bz)
  JobsProp_Bz <- Jobs_Bz / sum(Jobs_Bz)
  JobsAdj_Bx <- table(
    sample(1:nrow(SimBzone_df), abs(JobDiff), replace = TRUE, prob = JobsProp_Bz)
  )
  AdjJobs_Bz <- Jobs_Bz
  AdjIdx_ <- as.numeric(names(JobsAdj_Bx))
  AdjJobs_Bz[AdjIdx_] <- Jobs_Bz[AdjIdx_] + sign(JobDiff) * JobsAdj_Bx
  if(any(AdjJobs_Bz > SimBzone_df$Activity)) {
    AdjJobs_Bz[AdjJobs_Bz > SimBzone_df$Activity] <-
      SimBzone_df$Activity[AdjJobs_Bz > SimBzone_df$Activity]
  }
  #Calculate numbers of households by Bzone
  HHs_Bz <- SimBzone_df$Activity - AdjJobs_Bz
  #Calculate Jobs - HHs ratio
  D2A_JPHH_Bz <- AdjJobs_Bz / HHs_Bz
  #Assign values to SimBzones
  SimBzone_Az_df[[az]]$D2Grp <- D2Grp_Bz
  SimBzone_Az_df[[az]]$Jobs <- AdjJobs_Bz
  SimBzone_Az_df[[az]]$HHs <- HHs_Bz
  SimBzone_Az_df[[az]]$`D2A_JPHH` <- D2A_JPHH_Bz
}




#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CreateSimBzonesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Bzone",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME = ,
      FILE =  ,
      TABLE =  ,
      GROUP =  ,
      TYPE =  ,
      UNITS =  ,
      NAVALUE =  ,
      SIZE =  ,
      PROHIBIT =  ,
      ISELEMENTOF =  ,
      UNLIKELY =  ,
      TOTAL =  ,
      DESCRIPTION =
    ),
    item(
      NAME = ,
      FILE =  ,
      TABLE =  ,
      GROUP =  ,
      TYPE =  ,
      UNITS =  ,
      NAVALUE =  ,
      SIZE =  ,
      PROHIBIT =  ,
      ISELEMENTOF =  ,
      UNLIKELY =  ,
      TOTAL =  ,
      DESCRIPTION =
    ),
    item(
      NAME = ,
      FILE =  ,
      TABLE =  ,
      GROUP =  ,
      TYPE =  ,
      UNITS =  ,
      NAVALUE =  ,
      SIZE =  ,
      PROHIBIT =  ,
      ISELEMENTOF =  ,
      UNLIKELY =  ,
      TOTAL =  ,
      DESCRIPTION =
    ),

  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = ,
      TABLE = ,
      GROUP = ,
      TYPE = ,
      UNITS = ,
      PROHIBIT = ,
      ISELEMENTOF =
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = ,
      TABLE = ,
      GROUP = ,
      TYPE = ,
      UNITS = ,
      NAVALUE = ,
      PROHIBIT = ,
      ISELEMENTOF = ,
      SIZE = ,
      DESCRIPTION =
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateSimBzones module
#'
#' A list containing specifications for the CreateSimBzones module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{NewSetTable}{new table to be created for datasets specified in the
#'  'Set' specifications}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateSimBzones.R script.
"CreateSimBzonesSpecifications"
devtools::use_data(CreateSimBzonesSpecifications, overwrite = TRUE)
rm(CreateSimBzonesSpecifications)
