#================
#SimulateBzones.R
#================


#======
#SET UP
#======
#Load libraries
library(visioneval)
library(plot3D)

#Load 5Ds data frame
D_df <- readRDS("SimBzoneEst_df.rds")

#Create a list to hold model elements
SimBzone_ls <- list(
  UaProfiles = list(),
  TnProfiles = list(),
  RuProfiles = list(),
  Func = list(),
  Abbr = list()
)


#==================================================
#DEFINE FUNCTIONS USED IN MULTIPLE PLACES IN SCRIPT
#==================================================

#Define function to add a smoothed line to binned values
#-------------------------------------------------------
addSmoothLine <- function(X_, Y_, ...) {
  X_ <- X_[!is.na(Y_)]
  Y_ <- Y_[!is.na(Y_)]
  XY_SS <-smooth.spline(Y_ ~ X_)
  XPred_ <- seq(X_[1], X_[length(X_)], length = length(X_) * 10)
  lines(XPred_, predict(XY_SS, XPred_)$y, ...)
}

#Define a function to plot distributions for an urbanized area and compare with
#the distribution for all urbanized areas
#------------------------------------------------------------------------------
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
#------------------------------------------------------
calcAveDensity <- function(AveDensity_, PropActivity_) {
  sum(1 / sum(PropActivity_ / AveDensity_, na.rm = TRUE), na.rm = TRUE)
}


#=========================================================
#CREATE METROPOLITAN (URBANIZED), TOWN, AND RURAL DATASETS
#=========================================================

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
Tmp_ls <- split(Ua_df[,c("TOTACT", "AC_LAND", "TOTPOP10")], Ua_df$UZA_NAME)
ActDen_Ua <- unlist(lapply(Tmp_ls, function(x){
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Add the calculations to Ua_df
Ua_df$UZA_ACTDEN <- ActDen_Ua[Ua_df$UZA_NAME]
#Calculate activity density by urbanized area size
Tmp_ls <- split(Ua_df[,c("TOTACT", "AC_LAND", "TOTPOP10")], Ua_df$UZA_SIZE)
ActDen_Sz <- unlist(lapply(Tmp_ls, function(x){
  sum(x$TOTACT) / sum(x$AC_LAND)
}))
#Combine the size based calculations with the urbanized area calculations
ActDen_Ua <- c(ActDen_Ua, ActDen_Sz)
rm(ActDen_Sz)
#Add ActDen_Ua to SimBzone_ls
SimBzone_ls$UaProfiles$ActDen_Ua <- ActDen_Ua
rm(Tmp_ls)

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


#==============================================================
#EVALUATE THE DISTRIBUTIONS OF 3D VARIABLES FOR URBANIZED AREAS
#==============================================================

#Plot overall urbanized area log-transformed distributions
#---------------------------------------------------------
#Plot log distributions - these look fairly normal
#D2A_JPHH has some 0 and infinite values so just plot non-zero values for that
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

#Prepare data to compare correlations between 3Ds
#------------------------------------------------
T_df <- Ua_df[,c("D1D", "D2A_JPHH", "D5")]
T_df$LogD1D <- log(T_df$D1D)
T_df$LogD2A_JPHH <- log(T_df$D2A_JPHH)
T_df$LogD5 <- log(T_df$D5)
T_df <- T_df[!is.infinite(T_df$LogD2A_JPHH),]
D1D_ <- T_df$LogD1D
D2A_JPHH_ <- T_df$LogD2A_JPHH
D5_ <- T_df$LogD5

#Present the relationship of diversity with density
#--------------------------------------------------
# plot(D1D_, D2A_JPHH_, pch = ".", xlab = "Log D1D (density)", 
#      ylab = "Log D2A_JPHH (diversity)",
#      main = "Relationship of Diversity with Density")
# Cor <- round(cor(D2A_JPHH_, D1D_), 2)
# Text <- paste("Correlation Coefficient =", Cor)
# text(-6, 9, labels = Text, pos = 4)
# rm(Cor, Text)

#Present the relationship of destination accessibility with density
#------------------------------------------------------------------
# plot(D1D_, D5_, pch = ".", xlab = "Log D1D (density)", 
#      ylab = "Log D5 (destination accessibility)",
#      main = "Relationship of Destination Accessibility with Density")
# Cor <- round(cor(D5_, D1D_), 2)
# Text <- paste("Correlation Coefficient =", Cor)
# text(-6, 13, labels = Text, pos = 4)
# rm(Cor, Text)

#Present the relationship of diversity with destination accessibility
#--------------------------------------------------------------------
# plot(D5_, D2A_JPHH_, pch = ".", xlab = "Log D5 (destination accessibility)", 
#      ylab = "Log D2A_JPHH (diversity)",
#      main = "Relationship of Diversity with Destination Accessibility")
# Cor <- round(cor(D2A_JPHH_, D5_), 2)
# Text <- paste("Correlation Coefficient =", Cor)
# text(1, 9, labels = Text, pos = 4)
# rm(Cor, Text)
# #Clean up
# rm(T_df, D1D_, D2A_JPHH_, D5_)


#===============================================================
#DEFINE AND ANALYZE URBANIZED AREA ACTIVITY DENSITY (D1D) LEVELS
#===============================================================

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
D1DGrpBrk_[1] <- min(Ua_df$D1D)
D1DGrpBrk_[length(D1DGrpBrk_)] <- max(Ua_df$D1D)
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


#==========================================================
#IDENTIFY ACTIVITY DENSITY LEVELS FOR TOWNS AND RURAL AREAS
#==========================================================
#Unlike the urbanized areas, these data will be calculated for town areas and
#for rural areas as a whole.

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
D1DGrpBrk_[1] <- min(Tn_df$D1D)
D1DGrpBrk_[length(D1DGrpBrk_)] <- max(Tn_df$D1D)
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
D1DGrpBrk_[1] <- min(Ru_df$D1D)
D1DGrpBrk_[length(D1DGrpBrk_)] <- max(Ru_df$D1D)
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


#=========================================================================
#DEVELOP A MODEL FOR PREDICTING DENSITY BY BIN FROM URBANIZED AREA DENSITY
#=========================================================================
#The model adjusts the distribution of activity by density group in response to
#a change in the overall density of the urbanized area. This is done by
#iteratively taking a weighted moving average of the activity proportion in each
#bin with the activity proportion in the bin to the left (if overall density
#increases) or to the right (if overall density decreases).

#Define function to adjust density distribution
#----------------------------------------------
#' Adjust area density distribution to match average density target
#' 
#' @param DenDist_ A numeric vector of the proportions of activity by activity 
#' density bin for the area.
#' @param AreaAveDensity_ A numeric vector of the average activity density by
#' activity density bin for the area.
#' @param Target A number specifying the average activity density for the
#' area.
#' @param LocTyAveDensity_ A numeric vector of the average activity density by
#' activity density bin for the location type. For example if the location
#' type is metropolitan, it is the average density distribution for all
#' urbanized areas.
#' @return A data frame having 20 rows and 2 columns: ActProp, the proportion of
#' urbanized activity by activity density bin; and AveDensity, the average
#' density by activity density bin.
adjDenDist <- function(DenDist_, AreaAveDensity_, Target, LocTyAveDensity_) {
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
# calcAveDensity <- function(AveDensity_, PropActivity_) {
#   sum(1 / sum(PropActivity_ / AveDensity_, na.rm = TRUE), na.rm = TRUE)
# }
AdjDenDist_df <- adjDenDist(
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
AdjDenDist_df <- adjDenDist(
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
rm(AdjDenDist_df, calcAveDensity)


#=============================================================================
#ANALYSE RELATIONSHIP OF URBANIZED AREA DIVERSITY (D2A_JPHH) AND DENSITY (D1D)
#=============================================================================
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
DispPal_ <- colorRampPalette(c("black", "yellow"))(10)
png("data/uza_d2group-prop-act_by_d1group.png", width = 480, height = 480)
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
dev.off()
rm(DispPal_)

#Urbanized area proportions of activity by diversity group at each density group
#-------------------------------------------------------------------------------
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
png("data/example-uza_d2group-prop-act_by_d1group.png", width = 600, height = 600)
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
png("data/uza-size-group_d2group-prop-act_by_d1group.png", width = 600, height = 600)
DispPal_ <- colorRampPalette(c("black", "yellow"))(10)
InitPar_ls <- par(mfrow = c(2,3), mar = c(3,3,3,3), oma = c(0, 0, 2.2, 0))
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


#===========================================================================
#ANALYSE RELATIONSHIP OF TOWN & RURAL DIVERSITY (D2A_JPHH) AND DENSITY (D1D)
#===========================================================================

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


#===========================================================================
#URBANIZED RELATIONSHIP OF DESTINATION ACCESSIBILITY (D5) WITH DENSITY (D1D)
#===========================================================================

#Create destination accessibility (D5) levels
#--------------------------------------------
#Determine breaks by dividing log of distribution into 20 equal intervals
D5GrpBrk_ <- local({
  LogD5_ <- log(Ua_df$D5)
  Interval <- diff(range(LogD5_)) / 20
  LogBreaks_ <- min(LogD5_) + 0:20 * Interval
  exp(LogBreaks_)
})
#Make sure the minimum and maximum values bound the breaks
D5GrpBrk_[1] <- min(Ua_df$D5)
D5GrpBrk_[length(D5GrpBrk_)] <- max(Ua_df$D5)
#Identify the destination accessibility group for each block group
D5Grp_ <- cut(Ua_df$D5, breaks = D5GrpBrk_, include.lowest = TRUE)
Ua_df$D5Grp <- D5Grp_
#Calculate the average destination accessibility for each quantile
D5GrpAve_ <- tapply(Ua_df$D5, D5Grp_, mean)
#Calculate total activity in each qualtile
D5GrpTotAct_ <- tapply(Ua_df$TOTACT, D5Grp_, sum)
#Plot the proportion of total activity by group
D5GrpPropAct_ <- D5GrpTotAct_ / sum(D5GrpTotAct_)
png("data/prop_uza_act_by_d5-group.png", width = 480, height = 480)
plot(1:20, D5GrpPropAct_,
     xlab = "Destination Accessibility (D5) Group",
     ylab = "Proportion of Activity (HHs & Jobs)",
     main = "Proportions of Activity by Destination Accesibility Group\nBlock Groups in All Urbanized Areas")
addSmoothLine(1:20, D5GrpPropAct_, lty = 2)
dev.off()
#Plot the group D5 averages
png("data/ave_dest-acc_by_d5-group.png", width = 480, height = 480)
plot(1:20, D5GrpAve_,
     xlab = "Destination Accessibility (D5) Group",
     ylab = "Average Destination Accessibility",
     main = "Average Destination Accessibility by Group\nBlocks Groups in All Urbanized Areas")
addSmoothLine(1:20, D5GrpAve_, lty = 2)
dev.off()
#Clean up
rm(D5GrpBrk_, D5Grp_, D5GrpAve_, D5GrpTotAct_, D5GrpPropAct_)

#Calculate activity jointly by density (D1D) and accessibility (D5) groupings
#----------------------------------------------------------------------------
#Calculate total activity by density group and accessibility group and the
#activity proportions by accessibility group for each density group
#Calculate for all urbanized areas
TotAct_D1D5 <- tapply(Ua_df$TOTACT, list(Ua_df$D1DGrp, Ua_df$D5Grp), sum)
TotAct_D1D5[is.na(TotAct_D1D5)] <- 0
SimBzone_ls$UaProfiles$D5ActProp_D1D5 <- sweep(TotAct_D1D5, 1, rowSums(TotAct_D1D5), "/")
rm(TotAct_D1D5)
#Calculate by urbanized area
D_Ua_df <- split(Ua_df, Ua_df$UZA_NAME)
TotAct_Ua_D1D5 <- lapply(D_Ua_df, function(x) {
  TotAct_D1D5 <- tapply(x$TOTACT, list(x$D1DGrp, x$D5Grp), sum)
  TotAct_D1D5
})
D5ActProp_Ua_D1D5 <- lapply(TotAct_Ua_D1D5, function(x) {
  D5ActProp_D1D5 <- sweep(x, 1, rowSums(x, na.rm = TRUE), "/")
  D5ActProp_D1D5
})
# ActProp_Ua_D5 <- lapply(D_Ua_df, function(x) {
#   TotAct_D5 <- tapply(x$TOTACT, x$D5Grp, sum)
#   TotAct_D5[is.na(TotAct_D5)] <- 0
#   TotAct_D5 / sum(TotAct_D5)
# })
rm(D_Ua_df, TotAct_Ua_D1D5)
#Calculate by urbanized area size group
D_Sz_df <- split(Ua_df, Ua_df$UZA_SIZE)
TotAct_Sz_D1D5 <- lapply(D_Sz_df, function(x) {
  TotAct_D1D5 <- tapply(x$TOTACT, list(x$D1DGrp, x$D5Grp), sum)
  TotAct_D1D5
})
D5ActProp_Sz_D1D5 <- lapply(TotAct_Sz_D1D5, function(x) {
  D5ActProp_D1D5 <- sweep(x, 1, rowSums(x, na.rm = TRUE), "/")
  D5ActProp_D1D5
})
# ActProp_Sz_D5 <- lapply(D_Sz_df, function(x) {
#   TotAct_D5 <- tapply(x$TOTACT, x$D5Grp, sum)
#   TotAct_D5[is.na(TotAct_D5)] <- 0
#   TotAct_D5 / sum(TotAct_D5)
# })
rm(D_Sz_df, TotAct_Sz_D1D5)
#Add size group tabulations to urbanized area list
for (sz in Sz) {
  D5ActProp_Ua_D1D5[[sz]] <- D5ActProp_Sz_D1D5[[sz]]
  #ActProp_Ua_D5[[sz]] <- ActProp_Sz_D5[[sz]]
}
SimBzone_ls$UaProfiles$D5ActProp_Ua_D1D5 <- D5ActProp_Ua_D1D5
rm(D5ActProp_Sz_D1D5, sz, D5ActProp_Ua_D1D5)

#Define function to make an image of proportions of total activity by D1D and D5
#-------------------------------------------------------------------------------
imagePropAct <- function(D5PropAct_D1D5, ...) {
  ImgDat_D1D5 <- D5PropAct_D1D5
  ImgDat_D1D5[is.na(ImgDat_D1D5)] <- 0
  DispPal_ <- colorRampPalette(c("black", "yellow"))(20)
  image2D(ImgDat_D1D5, 
          x = 1:20, y = 1:20,
          zlim = c(0,1),
          col = DispPal_, NAcol = "black",
          xlab = "",
          ylab = "",
          ...)
  title(ylab = "D5 Group", line = 1)
  title(xlab = "D1D Group", line = 1)
}

#Plot relationships of D5 group proportions with D1D group
#---------------------------------------------------------
#Plot D5 group proportions for all urbanized areas
png("data/example-uza_d5group-prop-act_by_d1group.png", width = 600, height = 600)
imagePropAct(SimBzone_ls$UaProfiles$D5ActProp_D1D5,
             main = "Activity Proportions by D5 Group for Each D1D Group\nAll Urbanized Areas")
#Plot D5 group proportions for 9 urbanized areas
InitPar_ls <- par(mfrow = c(3,3), mar = c(3,3,3,3), oma = c(0, 0, 2.2, 0))
for (Ua in UzaToPlot_) {
  imagePropAct(SimBzone_ls$UaProfiles$D5ActProp_Ua_D1D5[[Ua]], main = Ua)
}
mtext("Activity Proportions by D5 Group for Each D1D Group\nFor Selected Urbanized Areas", 
      outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()
rm(Ua, InitPar_ls)
#Plot D5 group proportions for 6 urbanized area size groups
png("data/uza-size-group_d5group-prop-act_by_d1group.png")
InitPar_ls <- par(mfrow = c(3,2), mar = c(3,3,3,3), oma = c(0, 0, 2.2, 0))
for (sz in Sz) {
  imagePropAct(SimBzone_ls$UaProfiles$D5ActProp_Ua_D1D5[[sz]], main = sz)
}
mtext("Activity Proportions by D5 Group for Each D1D Group\nBy Urbanized Area Population Size Group", 
      outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()
rm(InitPar_ls)
rm(imagePropAct)

#Calculate average destination accessibility by destination accessibility group
#------------------------------------------------------------------------------
#Calculate for all urbanized areas
SimBzone_ls$UaProfiles$D5Ave_D5 <- 
  unlist(lapply(split(Ua_df, Ua_df$D5Grp), function(x) {
    sum(x$TOTACT * x$D5) / sum(x$TOTACT)
  }))
#Calculate by urbanized area
Tmp_Ua_df <- split(Ua_df, Ua_df$UZA_NAME)
D5Ave_Ua_D5 <- lapply(Tmp_Ua_df, function(x) {
  unlist(lapply(split(x, x$D5Grp), function(y) {
    sum(y$TOTACT * y$D5) / sum(y$TOTACT)
  }))
})
rm(Tmp_Ua_df)
#Calculate by urbanized area size group
Tmp_Sz_df <- split(Ua_df, Ua_df$UZA_SIZE)
D5Ave_Sz_D5 <- lapply(Tmp_Sz_df, function(x) {
  unlist(lapply(split(x, x$D5Grp), function(y) {
    sum(y$TOTACT * y$D5) / sum(y$TOTACT)
  }))
})
rm(Tmp_Sz_df)
#Add size group tabulations to urbanized area list
for (sz in Sz) {
  D5Ave_Ua_D5[[sz]] <- D5Ave_Sz_D5[[sz]]
}
rm(D5Ave_Sz_D5, sz)
#Save in urbanized profile
SimBzone_ls$UaProfiles$D5Ave_Ua_D5 <- D5Ave_Ua_D5
rm(D5Ave_Ua_D5)


#==============================================================================
#TOWN & RURAL RELATIONSHIP OF DESTINATION ACCESSIBILITY (D5) WITH DENSITY (D1D)
#==============================================================================

#Create town destination accessibility (D5) and D5 group proportions
#-------------------------------------------------------------------
#Determine breaks by dividing log of distribution into 20 equal intervals
D5GrpBrk_ <- local({
  LogD5_ <- log(Tn_df$D5)
  Interval <- diff(range(LogD5_)) / 20
  LogBreaks_ <- min(LogD5_) + 0:20 * Interval
  exp(LogBreaks_)
})
#Make sure the minimum and maximum values bound the breaks
D5GrpBrk_[1] <- min(Tn_df$D5)
D5GrpBrk_[length(D5GrpBrk_)] <- max(Tn_df$D5)
#Identify the destination accessibility group for each block group
D5Grp_ <- cut(Tn_df$D5, breaks = D5GrpBrk_, include.lowest = TRUE)
Tn_df$D5Grp <- D5Grp_
#Calculate the average destination accessibility for each quantile
SimBzone_ls$TnProfiles$D5Ave_D5 <- tapply(Tn_df$D5, D5Grp_, mean)
rm(D5GrpBrk_, D5Grp_)
#Calculate D5 activity proportions by D1D
TotAct_D1D5 <- tapply(Tn_df$TOTACT, list(Tn_df$D1DGrp, Tn_df$D5Grp), sum)
TotAct_D1D5[is.na(TotAct_D1D5)] <- 0
SimBzone_ls$TnProfiles$D5ActProp_D1D5 <- sweep(TotAct_D1D5, 1, rowSums(TotAct_D1D5), "/")
rm(TotAct_D1D5)

#Create rural destination accessibility (D5) and D5 group proportions
#--------------------------------------------------------------------
#Determine breaks by dividing log of distribution into 20 equal intervals
D5GrpBrk_ <- local({
  LogD5_ <- log(Ru_df$D5)
  Interval <- diff(range(LogD5_)) / 20
  LogBreaks_ <- min(LogD5_) + 0:20 * Interval
  exp(LogBreaks_)
})
#Make sure the minimum and maximum values bound the breaks
D5GrpBrk_[1] <- min(Ru_df$D5)
D5GrpBrk_[length(D5GrpBrk_)] <- max(Ru_df$D5)
#Identify the destination accessibility group for each block group
D5Grp_ <- cut(Ru_df$D5, breaks = D5GrpBrk_, include.lowest = TRUE)
Ru_df$D5Grp <- D5Grp_
#Calculate the average destination accessibility for each quantile
SimBzone_ls$RuProfiles$D5Ave_D5 <- tapply(Ru_df$D5, D5Grp_, mean)
rm(D5GrpBrk_, D5Grp_)
#Calculate D5 activity proportions by D1D
TotAct_D1D5 <- tapply(Ru_df$TOTACT, list(Ru_df$D1DGrp, Ru_df$D5Grp), sum)
TotAct_D1D5[is.na(TotAct_D1D5)] <- 0
SimBzone_ls$RuProfiles$D5ActProp_D1D5 <- sweep(TotAct_D1D5, 1, rowSums(TotAct_D1D5), "/")
rm(TotAct_D1D5)


#==============================================================
#DEVELOP MODEL SPLITTING URBANIZED AREA EMPLOYMENT INTO SECTORS
#==============================================================

#Calculate the average retail proportion by urban area
Tmp_Ua_df <- split(Ua_df, Ua_df$UZA_NAME)
RetProp_Ua <- unlist(lapply(Tmp_Ua_df, function(x) {
  sum(x$E5_RET10) / sum(x$EMPTOT)
}))
Tmp_Sz_df <- split(Ua_df, Ua_df$UZA_SIZE)
RetProp_Sz <- unlist(lapply(Tmp_Sz_df, function(x) {
  sum(x$E5_RET10) / sum(x$EMPTOT)
}))
SimBzone_ls$UaProfiles$RetProp_Ua <- c(RetProp_Ua, RetProp_Sz)
rm(Tmp_Ua_df, Tmp_Sz_df, RetProp_Ua, RetProp_Sz)
#Calculate the average service proportion by urban area
Tmp_Ua_df <- split(Ua_df, Ua_df$UZA_NAME)
SvcProp_Ua <- unlist(lapply(Tmp_Ua_df, function(x) {
  sum(x$E5_SVC10) / sum(x$EMPTOT)
}))
Tmp_Sz_df <- split(Ua_df, Ua_df$UZA_SIZE)
SvcProp_Sz <- unlist(lapply(Tmp_Sz_df, function(x) {
  sum(x$E5_SVC10) / sum(x$EMPTOT)
}))
SimBzone_ls$UaProfiles$SvcProp_Ua <- c(SvcProp_Ua, SvcProp_Sz)
rm(Tmp_Ua_df, Tmp_Sz_df, SvcProp_Ua, SvcProp_Sz)

#Create data frame of variables to analyze
Tmp_df <- data.frame(
  RetSvcPropEmp = with(Ua_df, (E5_RET10 + E5_SVC10) / EMPTOT),
  RetPropRetSvcEmp = with(Ua_df, E5_RET10 / (E5_RET10 + E5_SVC10)),
  D1DGrp = Ua_df$D1DGrp,
  D2Grp = Ua_df$D2Grp)

#Split by diversity group
Tmp_D2_df <- split(Tmp_df, Tmp_df$D2Grp)
rm(Tmp_df)

#Create boxplots of retail & service proportion by density group
png("data/ua_retsvc-prop_by_diversity&density.png", width = 480, height = 480)
Opar_ls <- par(mfrow = c(2,3), oma = c(0,0,3,0))
for (d2 in D2) {
  with(Tmp_D2_df[[d2]], 
       boxplot(RetSvcPropEmp ~ D1DGrp, 
               axes = FALSE, 
               xlab = "Density Group",
               main = d2))
  axis(1, at = 1:20, labels = 1:20)
  axis(2)
  box()
  mtext(text = "Retail and Service Proportion of Employment\nBy Diversity and Density Group",
        side = 3, outer = TRUE)
}
par(Opar_ls)
rm(Opar_ls)
dev.off()

#Create boxplots of retail proportion of retail & service employment by density group
png("data/ua_ret-prop_by_diversity&density.png", width = 480, height = 480)
Opar_ls <- par(mfrow = c(2,3), oma = c(0,0,3,0))
for (d2 in D2) {
  with(Tmp_D2_df[[d2]], 
       boxplot(RetPropRetSvcEmp ~ D1DGrp, 
               axes = FALSE, 
               xlab = "Density Group",
               main = d2))
  axis(1, at = 1:20, labels = 1:20)
  axis(2)
  box()
  mtext(text = "Retail Proportion of Retail and Service Employment\nBy Diversity and Density Group",
        side = 3, outer = TRUE)
}
par(Opar_ls)
rm(Opar_ls, d2)
dev.off()

#Calculate average retail and service proportion by density and diversity group
MeanRetSvcProp_D1D2 <- 
  do.call(cbind, lapply(Tmp_D2_df, function(x) {
    X_D1_df <- split(x, x$D1DGrp)
    unlist(lapply(X_D1_df, function(y) {
      mean(y$RetSvcPropEmp, na.rm = TRUE)
    }))
  }))
#Make a smooth trend of the mean
MeanRetSvcProp_D1D2 <- 
  apply(MeanRetSvcProp_D1D2, 2, function(x) {
    X_SS <- smooth.spline(6:19, x[6:19], df = 4)
    predict(X_SS, 1:20)$y
  })
rownames(MeanRetSvcProp_D1D2) <- levels(Ua_df$D1DGrp)
SimBzone_ls$UaProfiles$MeanRetSvcProp_D1D2 <- MeanRetSvcProp_D1D2
rm(MeanRetSvcProp_D1D2)
#Average standard deviation by diversity group
SimBzone_ls$UaProfiles$SdRetSvcProp_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetSvcPropEmp, na.rm = TRUE)
}))

#Calculate average retail proportion of retail and service employment by density
#and diversity group
MeanRetPropRetSvc_D1D2 <- 
  do.call(cbind, lapply(Tmp_D2_df, function(x) {
    X_D1_df <- split(x, x$D1DGrp)
    unlist(lapply(X_D1_df, function(y) {
      mean(y$RetPropRetSvcEmp, na.rm = TRUE)
    }))
  }))
#Make smooth trend of the mean
MeanRetPropRetSvc_D1D2 <- 
  apply(MeanRetPropRetSvc_D1D2, 2, function(x) {
    X_SS <- smooth.spline(6:19, x[6:19], df = 4)
    predict(X_SS, 1:20)$y
  })
rownames(MeanRetPropRetSvc_D1D2) <- levels(Ua_df$D1DGrp)
SimBzone_ls$UaProfiles$MeanRetPropRetSvc_D1D2 <- MeanRetPropRetSvc_D1D2
#Average standard deviation by diversity group
SimBzone_ls$UaProfiles$SdRetPropRetSvc_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetPropRetSvcEmp, na.rm = TRUE)
}))
rm(MeanRetPropRetSvc_D1D2, Tmp_D2_df)


#===============================================================
#DEVELOP MODELS SPLITTING TOWN AND RURAL EMPLOYMENT INTO SECTORS
#===============================================================

#Calculate town values
#---------------------
#Retail proportion
SimBzone_ls$TnProfiles$RetProp <- 
  sum(Tn_df$E5_RET10, na.rm = TRUE) / sum(Tn_df$EMPTOT, na.rm = TRUE)
#Service proportion
SimBzone_ls$TnProfiles$SvcProp <- 
  sum(Tn_df$E5_SVC10, na.rm = TRUE) / sum(Tn_df$EMPTOT, na.rm = TRUE)
#Create data frame of variables to analyze
Tmp_df <- data.frame(
  RetSvcPropEmp = with(Tn_df, (E5_RET10 + E5_SVC10) / EMPTOT),
  RetPropRetSvcEmp = with(Tn_df, E5_RET10 / (E5_RET10 + E5_SVC10)),
  D1DGrp = Tn_df$D1DGrp,
  D2Grp = Tn_df$D2Grp)
#Split by diversity group
Tmp_D2_df <- split(Tmp_df, Tmp_df$D2Grp)
rm(Tmp_df)
#Calculate average retail and service proportion by density and diversity group
MeanRetSvcProp_D1D2 <- 
  do.call(cbind, lapply(Tmp_D2_df, function(x) {
    X_D1_df <- split(x, x$D1DGrp)
    unlist(lapply(X_D1_df, function(y) {
      mean(y$RetSvcPropEmp, na.rm = TRUE)
    }))
  }))
#Make a smooth trend of the mean
MeanRetSvcProp_D1D2 <- 
  apply(MeanRetSvcProp_D1D2, 2, function(x) {
    X_SS <- smooth.spline(6:19, x[6:19], df = 4)
    predict(X_SS, 1:20)$y
  })
rownames(MeanRetSvcProp_D1D2) <- levels(Tn_df$D1DGrp)
SimBzone_ls$TnProfiles$MeanRetSvcProp_D1D2 <- MeanRetSvcProp_D1D2
rm(MeanRetSvcProp_D1D2)
#Average standard deviation by diversity group
SimBzone_ls$TnProfiles$SdRetSvcProp_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetSvcPropEmp, na.rm = TRUE)
}))
#Calculate average retail proportion of retail and service employment by density
#and diversity group
MeanRetPropRetSvc_D1D2 <- 
  do.call(cbind, lapply(Tmp_D2_df, function(x) {
    X_D1_df <- split(x, x$D1DGrp)
    unlist(lapply(X_D1_df, function(y) {
      mean(y$RetPropRetSvcEmp, na.rm = TRUE)
    }))
  }))
#Make smooth trend of the mean
MeanRetPropRetSvc_D1D2 <- 
  apply(MeanRetPropRetSvc_D1D2, 2, function(x) {
    X_SS <- smooth.spline(6:19, x[6:19], df = 4)
    predict(X_SS, 1:20)$y
  })
rownames(MeanRetPropRetSvc_D1D2) <- levels(Tn_df$D1DGrp)
SimBzone_ls$TnProfiles$MeanRetPropRetSvc_D1D2 <- MeanRetPropRetSvc_D1D2
#Average standard deviation by diversity group
SimBzone_ls$TnProfiles$SdRetPropRetSvc_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetPropRetSvcEmp, na.rm = TRUE)
}))
rm(MeanRetPropRetSvc_D1D2, Tmp_D2_df)

#Calculate rural values
#----------------------
#Retail proportion
SimBzone_ls$RuProfiles$RetProp <- 
  sum(Ru_df$E5_RET10, na.rm = TRUE) / sum(Ru_df$EMPTOT, na.rm = TRUE)
#Service proportion
SimBzone_ls$RuProfiles$SvcProp <- 
  sum(Ru_df$E5_SVC10, na.rm = TRUE) / sum(Ru_df$EMPTOT, na.rm = TRUE)
#Create data frame of variables to analyze
Tmp_df <- data.frame(
  RetSvcPropEmp = with(Ru_df, (E5_RET10 + E5_SVC10) / EMPTOT),
  RetPropRetSvcEmp = with(Ru_df, E5_RET10 / (E5_RET10 + E5_SVC10)),
  D1DGrp = Ru_df$D1DGrp,
  D2Grp = Ru_df$D2Grp)
#Split by diversity group
Tmp_D2_df <- split(Tmp_df, Tmp_df$D2Grp)
rm(Tmp_df)
#Calculate average retail and service proportion by density and diversity group
MeanRetSvcProp_D1D2 <- 
  do.call(cbind, lapply(Tmp_D2_df, function(x) {
    X_D1_df <- split(x, x$D1DGrp)
    unlist(lapply(X_D1_df, function(y) {
      mean(y$RetSvcPropEmp, na.rm = TRUE)
    }))
  }))
#Make a smooth trend of the mean
MeanRetSvcProp_D1D2 <- 
  apply(MeanRetSvcProp_D1D2, 2, function(x) {
    X_SS <- smooth.spline(6:19, x[6:19], df = 4)
    predict(X_SS, 1:20)$y
  })
rownames(MeanRetSvcProp_D1D2) <- levels(Ru_df$D1DGrp)
SimBzone_ls$RuProfiles$MeanRetSvcProp_D1D2 <- MeanRetSvcProp_D1D2
rm(MeanRetSvcProp_D1D2)
#Average standard deviation by diversity group
SimBzone_ls$RuProfiles$SdRetSvcProp_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetSvcPropEmp, na.rm = TRUE)
}))
#Calculate average retail proportion of retail and service employment by density
#and diversity group
MeanRetPropRetSvc_D1D2 <- 
  do.call(cbind, lapply(Tmp_D2_df, function(x) {
    X_D1_df <- split(x, x$D1DGrp)
    unlist(lapply(X_D1_df, function(y) {
      mean(y$RetPropRetSvcEmp, na.rm = TRUE)
    }))
  }))
#Make smooth trend of the mean
MeanRetPropRetSvc_D1D2 <- 
  apply(MeanRetPropRetSvc_D1D2, 2, function(x) {
    X_SS <- smooth.spline(6:19, x[6:19], df = 4)
    predict(X_SS, 1:20)$y
  })
rownames(MeanRetPropRetSvc_D1D2) <- levels(Ru_df$D1DGrp)
SimBzone_ls$RuProfiles$MeanRetPropRetSvc_D1D2 <- MeanRetPropRetSvc_D1D2
#Average standard deviation by diversity group
SimBzone_ls$RuProfiles$SdRetPropRetSvc_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetPropRetSvcEmp, na.rm = TRUE)
}))
rm(MeanRetPropRetSvc_D1D2, Tmp_D2_df)


#============================================================
#DEFINE FUNCTIONS TO IMPLEMENT EMPLOYMENT SECTOR SPLIT MODELS
#============================================================
#The split of retail and service employment is determined by sampling from the
#estimated distributions of retail and service proportions by mix and density.
#Retail and service allocations are adjusted to match the overall proportions
#for the location. Another function calculates the entropy mix measure.

#Define function to split employment into sectors
#------------------------------------------------
#' \code{splitEmployment} split SimBzone employment into sectors.
#'
#' This function splits SimBzone employment into retail, service, and other
#' employment sectors and match the split for the overall area being modeled.
#'
#' @param Emp_Bz A numeric vector of total employment by SimBzone.
#' @param LocTy A string identifying the location type of the area (i.e.
#' metropolitan, town, rural)
#' @param D1DGrp_Bz A character vector identifying the activity density group
#' of each SimBzone.
#' @param D2Grp_Bz A character vector identifying the activity diversity group
#' of each SimBzone.
#' @param RetProp A number identifying the proportion of employment in the area
#' that is retail employment.
#' @param SvcProp A number identifying the proportion of employment in the area
#' that is service employment.
#' @param Model_ls A list containing all the estimated model information for
#' implementing the employment split model.
#' @return A list containing 3 components: RetEmp (the number of retail sector
#' jobs), SvcEmp (the number of service sector jobs), OthEmp (the number of
#' other sector jobs)
#' @export
splitEmployment <- 
  function(Emp_Bz, LocTy, D1DGrp_Bz, D2Grp_Bz, RetProp, SvcProp, EmpSplitModel_ls) {
    NBz <- length(Emp_Bz)
    RetEmp <- round(sum(Emp_Bz) * RetProp)
    SvcEmp <- round(sum(Emp_Bz) * SvcProp)
    RetSvcEmp <- RetEmp + SvcEmp
    #Define function to adjust sector employment by zone to match total
    matchBzEmp <- function(TotSectorEmp, SectorEmp_Bz) {
      EmpDiff <- TotSectorEmp - sum(SectorEmp_Bz)
      SectorEmpProp_Bz <- SectorEmp_Bz / sum(SectorEmp_Bz)
      BzIdx_ <- 1:length(SectorEmp_Bz)
      EmpAdj_tb <- table(sample(BzIdx_, abs(EmpDiff), replace = TRUE, prob = SectorEmpProp_Bz))
      SectorEmp_Bz[as.numeric(names(EmpAdj_tb))] <- 
        SectorEmp_Bz[as.numeric(names(EmpAdj_tb))] + sign(EmpDiff) * EmpAdj_tb
      SectorEmp_Bz[SectorEmp_Bz < 0] <- 0
      SectorEmp_Bz
    }
    #Sample to determine initial retail & service proportion of employment
    MeanRetSvcProp_Bz <- EmpSplitModel_ls$MeanRetSvcProp_D1D2[cbind(D1DGrp_Bz, D2Grp_Bz)]
    SdRetSvcProp_Bz <- EmpSplitModel_ls$SdRetSvcProp_D2[D2Grp_Bz]
    RetSvcProp_Bz <- rnorm(NBz, MeanRetSvcProp_Bz, SdRetSvcProp_Bz)
    #Scale to keep range in 0 to 1
    MeanRetSvcProp <- mean(RetSvcProp_Bz)
    UpperAdj <- (1 - MeanRetSvcProp) / (max(RetSvcProp_Bz) - MeanRetSvcProp)
    IsUpper_ <- RetSvcProp_Bz > MeanRetSvcProp
    RetSvcProp_Bz[IsUpper_] <- 
      MeanRetSvcProp + (RetSvcProp_Bz[IsUpper_] - MeanRetSvcProp) * UpperAdj
    LowerAdj <- (MeanRetSvcProp) / (MeanRetSvcProp - min(RetSvcProp_Bz))
    IsLower_ <- RetSvcProp_Bz < MeanRetSvcProp
    RetSvcProp_Bz[IsLower_] <-
      MeanRetSvcProp + (RetSvcProp_Bz[IsLower_] - MeanRetSvcProp) * LowerAdj
    #Calculate retail & service employment and other employment
    RetSvcEmp_Bz <- round(Emp_Bz * RetSvcProp_Bz)
    while (sum(RetSvcEmp_Bz) != RetSvcEmp) {
      RetSvcEmp_Bz <- matchBzEmp(RetSvcEmp, RetSvcEmp_Bz)
      RetSvcEmp_Bz[RetSvcEmp_Bz > Emp_Bz] <- Emp_Bz[RetSvcEmp_Bz > Emp_Bz]
    }
    OthEmp_Bz <- Emp_Bz - RetSvcEmp_Bz
    #Calculate retail and service proportions of retail & service employment
    MeanRetPropRetSvc_Bz <- 
      EmpSplitModel_ls$MeanRetPropRetSvc_D1D2[cbind(D1DGrp_Bz, D2Grp_Bz)]
    SdRetPropRetSvc_Bz <- EmpSplitModel_ls$SdRetPropRetSvc_D2[D2Grp_Bz]
    RetPropRetSvc_Bz <- rnorm(NBz, MeanRetPropRetSvc_Bz, SdRetPropRetSvc_Bz)
    RetPropRetSvc_Bz[RetPropRetSvc_Bz < 0] <- 0
    RetPropRetSvc_Bz[RetPropRetSvc_Bz > 1] <- 1
    SvcPropRetSvc_Bz <- 1 - RetPropRetSvc_Bz
    #Calculate retail and service employment
    RetEmp_Bz <- round(RetPropRetSvc_Bz * RetSvcEmp_Bz)
    while (sum(RetEmp_Bz) != RetEmp) {
      RetEmp_Bz <- matchBzEmp(RetEmp, RetEmp_Bz)
      RetEmp_Bz[RetEmp_Bz > RetSvcEmp_Bz] <- RetSvcEmp_Bz[RetEmp_Bz > RetSvcEmp_Bz]
    }
    SvcEmp_Bz <- RetSvcEmp_Bz - RetEmp_Bz
    #Return the result
    list(
      RetEmp = as.integer(RetEmp_Bz),
      SvcEmp = as.integer(SvcEmp_Bz),
      OthEmp = as.integer(OthEmp_Bz)
    )
  }

#Define function to calculate entropy measure of diversity
#---------------------------------------------------------
#' \code{calcActivityEntropy} calculate entropy measure of SimBzone activity.
#'
#' This function calculates an entropy measure of activity diversity for each
#' SimBzone based on the numbers of households, retail jobs, service jobs, and
#' other jobs in the SimBzone.
#'
#' @param Hh_Bz A numeric vector of the number of households by SimBzone.
#' @param RetEmp_Bz A numeric vector of the number of retail jobs by SimBzone.
#' @param SvcEmp_Bz A numeric vector of the number of service jobs by SimBzone.
#' @param OthEmp_Bz A numeric vector of the number of other jobs by SimBzone.
#' @return A numeric vector containing the entropy measure of activity diversity
#' for each SimBzone.
#' @export
calcEntropy <- function(Hh_Bz, RetEmp_Bz, SvcEmp_Bz, OthEmp_Bz) {
  TotAct_Bz <- Hh_Bz + RetEmp_Bz + SvcEmp_Bz + OthEmp_Bz
  Tmp_df <- data.frame(
    TotAct = TotAct_Bz,
    NumHh = Hh_Bz,
    RetEmp = RetEmp_Bz,
    SvcEmp = SvcEmp_Bz,
    OthEmp = OthEmp_Bz
  )
  calcEntropyTerm <- function(AcRuame) {
    Act_ <- Tmp_df[[AcRuame]]
    ActRatio_ <- Act_ / Tmp_df$TotAct
    LogActRatio_ <- ActRatio_ * 0
    LogActRatio_[Act_ != 0] <- log(Act_[Act_ != 0] / Tmp_df$TotAct[Act_ != 0])
    ActRatio_ * LogActRatio_
  }
  E_df <- data.frame(
    Hh = calcEntropyTerm("NumHh"),
    Ret = calcEntropyTerm("RetEmp"),
    Svc = calcEntropyTerm("SvcEmp"),
    Oth = calcEntropyTerm("OthEmp")
  )
  A_ <- rowSums(E_df)
  N_ = apply(E_df, 1, function(x) sum(x != 0))
  -A_ / log(N_)
}

#Function to create urbanized area test dataset for testing employment split
#---------------------------------------------------------------------------
#This function takes the name of an urbanized area, identifies the counties
#where the urbanized area is located, and makes datasets where counties are
#Azones
createAzoneTestData <- function(AreaName) {
  if (AreaName %in% D_df$UZA_NAME) {
    Counties_ <- 
      unique(substr(D_df$GEOID10[D_df$UZA_NAME == AreaName], 1, 5))
  } else {
    if (AreaName %in% D_df$STATE) {
      Counties_ <- 
        unique(substr(D_df$GEOID10[D_df$STATE == AreaName], 1, 5))
    } else {
      return()
    }
  }
  getCountyData <- function(Data_df, Counties_) {
    Data_df[substr(Data_df$GEOID10, 1, 5) %in% Counties_,]
  }
  getFunctionData <- function(LocType) {
    if (LocType == "Metropolitan") {
      Tmp_df <- getCountyData(Ua_df, Counties_)
    }
    if (LocType == "Town") {
      Tmp_df <- getCountyData(Ru_df, Counties_)
    }
    if (LocType == "Rural") {
      Tmp_df <- getCountyData(Ru_df, Counties_)
    }
    list(
      Emp_Bz = Tmp_df$EMPTOT,
      LocTy = LocType,
      D1DGrp_Bz = Tmp_df$D1DGrp,
      D2Grp_Bz = Tmp_df$D2Grp,
      RetProp = with(Tmp_df, sum(E5_RET10, na.rm = TRUE) / sum(EMPTOT, na.rm = TRUE)),
      SvcProp = with(Tmp_df, sum(E5_SVC10, na.rm = TRUE) / sum(EMPTOT, na.rm = TRUE)),
      HH_Bz = Tmp_df$HH,
      Ret_Bz = Tmp_df$E5_RET10,
      Svc_Bz = Tmp_df$E5_SVC10,
      D2A_EPHHM = Tmp_df$D2A_EPHHM
    )
  }
  list(
    Metropolitan = getFunctionData("Metropolitan"),
    Town = getFunctionData("Town"),
    Rural = getFunctionData("Rural")
  )
}

#Define function to test employment split by metropolitan area
#-------------------------------------------------------------
testEmploymentSplit <- function(AreaName, LocType) {
  #Make test dataset
  TestData_ls <- createAzoneTestData(AreaName)
  #Get the model data to use
  ProfileName <- switch(LocType,
    Metropolitan = "UaProfiles",
    Town = "RuProfiles",
    Rural = "RuProfiles"
  )
  EmpSplitModel_ls <- list(
    MeanRetSvcProp_D1D2 = SimBzone_ls[[ProfileName]]$MeanRetSvcProp_D1D2,
    SdRetSvcProp_D2 = SimBzone_ls[[ProfileName]]$SdRetSvcProp_D2,
    MeanRetPropRetSvc_D1D2 = SimBzone_ls[[ProfileName]]$MeanRetPropRetSvc_D1D2,
    SdRetPropRetSvc_D2 = SimBzone_ls[[ProfileName]]$SdRetPropRetSvc_D2
  )
  #Run the employment split model
  Out_ls <- splitEmployment(
    Emp_Bz = TestData_ls[[LocType]]$Emp_Bz, 
    LocTy = TestData_ls[[LocType]]$LocTy, 
    D1DGrp_Bz = TestData_ls[[LocType]]$D1DGrp_Bz, 
    D2Grp_Bz = TestData_ls[[LocType]]$D2Grp_Bz, 
    RetProp = TestData_ls[[LocType]]$RetProp, 
    SvcProp = TestData_ls[[LocType]]$SvcProp, 
    EmpSplitModel_ls = EmpSplitModel_ls
  )
  #Calculate entropy
  Entropy_ <- calcEntropy(
    Hh_Bz = TestData_ls[[LocType]]$HH_Bz, 
    RetEmp_Bz = Out_ls$RetEmp, 
    SvcEmp_Bz = Out_ls$SvcEmp, 
    OthEmp_Bz = Out_ls$OthEmp
  )  
  #Plot comparison
  library(gridExtra)
  library(gridBase)
  library(grid)
  Opar_ls <- par(mfrow = c(2,2), oma = c(0, 0, 3, 0))
  plot(density(log1p(TestData_ls[[LocType]]$Ret_Bz)),
       lty = 2,
       xlab = "Log Retail Proportion",
       ylab = "Probability Density",
       main = "Retail Employment")
  lines(density(log1p(Out_ls$RetEmp)))
  plot(density(log1p(TestData_ls[[LocType]]$Svc_Bz)),
       lty = 2,
       xlab = "Log Service Proportion",
       ylab = "Probability Density",
       main = "Service Employment")
  lines(density(log1p(Out_ls$SvcEmp)))
  plot(density(TestData_ls[[LocType]]$D2A_EPHHM),
       lty = 2,
       xlab = "Entropy",
       ylab = "Probability Density",
       main = "Entropy")
  lines(density(Entropy_))
  EmpComp_df <- data.frame(
    Sector = c("Retail", "Service", "Other"),
    Observed = c(
      sum(TestData_ls[[LocType]]$Ret_Bz),
      sum(TestData_ls[[LocType]]$Svc_Bz),
      sum(TestData_ls[[LocType]]$Emp_Bz)
    ),
    Modeled = c(
      sum(Out_ls$RetEmp),
      sum(Out_ls$SvcEmp),
      sum(unlist(Out_ls))
    )
  )
  rownames(EmpComp_df) <- NULL
  plot.new()              ## suggested by @Josh
  vps <- baseViewports()
  pushViewport(vps$figure) ##   I am in the space of the autocorrelation plot
  vp1 <-plotViewport(c(1.8,1,0,1)) ## create new vp with margins, you play with this values 
  p<- grid.table(EmpComp_df, rows = NULL)
  print(p,vp = vp1)
  mtext(text = paste0(
    "Employment and Entropy Comparisons for ", 
    LocType, " Portions of ", AreaName, " Area Counties\n",
    "Dashed line = observed (SLD) | Solid line = modeled"),
        outer = TRUE, side = 3)
  par(Opar_ls)
  rm(Opar_ls)
}

png("data/or-ua_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("OR", "Metropolitan")
dev.off()
png("data/or-tn_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("OR", "Town")
dev.off()
png("data/or-ru_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("OR", "Rural")
dev.off()

png("data/atlanta-ua_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Atlanta, GA", "Metropolitan")
dev.off()
png("data/atlanta-tn_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Atlanta, GA", "Town")
dev.off()
png("data/atlanta-ru_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Atlanta, GA", "Rural")
dev.off()

png("data/portland-ua_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Portland, OR", "Metropolitan")
dev.off()
png("data/portland-tn_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Portland, OR", "Town")
dev.off()
png("data/portland-ru_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Portland, OR", "Rural")
dev.off()

png("data/salem-ua_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Salem, OR", "Metropolitan")
dev.off()
png("data/salem-tn_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Salem, OR", "Town")
dev.off()
png("data/salem-ru_emp-split_test.png", height = 480, width = 480)
testEmploymentSplit("Salem, OR", "Rural")
dev.off()


#===========================
#DEVELOP HOUSING SPLIT MODEL
#===========================

#Investigate relationship of multifamily proportions
#---------------------------------------------------
#The following boxplots show that the multifamily proportion increases by large
#percentages as activity density group increases beyond the midrange. The
#boxplots also show that the distribution of values (extent and skewness) varies
#by activity density. Given the complexity of the distributions of multifamily
#housing proportions, it was decided to model multifamily proportions by
#tabulating the quantiles for each density level for each location type. The
#multifamily proportion for a SimBzone is determined random choice of a quantile
#and then randomly choosing a value within the range of the chosen quantile.
boxplotMFProp <- function(Data_df, ...) {
  PropMF_ <- Data_df$PropMF
  D1DGrp_ <- as.integer(Data_df$D1DGrp)
  D5Grp_ <- as.integer(Data_df$D5Grp)
  boxplot(PropMF_ ~ D1DGrp_, ...)
}
png("data/mf-prop_by_loctype&density.png", width = 480, height = 480)
Opar_ls <- par(mfrow = c(2,2), oma = c(0,0,2,0))
boxplotMFProp(Ua_df, xlab = "Activity Density Level", 
              ylab = "Multifamily Proportion",
              main = "Metropolitan")
boxplotMFProp(Ru_df, xlab = "Activity Density Level", 
              ylab = "Multifamily Proportion",
              main = "Town")
boxplotMFProp(Ru_df, xlab = "Activity Density Level", 
              ylab = "Multifamily Proportion",
              main = "Rural")
mtext(text = "Multifamily Housing Proportion vs. Density Level by Location Type", side = 3,
      outer = TRUE)
par(Opar_ls)
dev.off()
rm(boxplotMFProp)

#Calculate multifamily quantiles as function of density by location type
#-----------------------------------------------------------------------
#Define function to do the calculations
calcMFProps <- function(Data_df) {
  PropMF_ <- Data_df$PropMF
  D1DGrp_ <- Data_df$D1DGrp
  D5Grp_ <- Data_df$D5Grp
  #Calculate quantiles
  D1Qntl_mx <- do.call(rbind, tapply(PropMF_, D1DGrp_, function(x) {
    quantile(x, prob = seq(0, 1, length.out = 9), na.rm = TRUE)
  }))
  D1Qntl_mx[is.na(D1Qntl_mx)] <- 0
  #Return the results
  D1Qntl_mx
}
#Add to the area profiles
SimBzone_ls$UaProfiles$D1Qntl_mx <- calcMFProps(Ua_df)
SimBzone_ls$TnProfiles$D1Qntl_mx <- calcMFProps(Tn_df)
SimBzone_ls$RuProfiles$D1Qntl_mx <- calcMFProps(Ru_df)

#Define a function to calculate the housing split for each SimBzone
#------------------------------------------------------------------
calculateHousingUnitsByType <- 
  function(Hh_Bz, D1DGrp_Bz, D5Grp_Bz, D1Qntl_mx) {
    N <- length(Hh_Bz)
    #Choose quantile for each SimBzone
    Qntl_Bz <- sample(1:8, N, replace = TRUE)
    #Make matrix of value range for each SimBzone
    Range_Bz2 <- cbind(
      Min = D1Qntl_mx[cbind(D1DGrp_Bz, Qntl_Bz)],
      Max = D1Qntl_mx[cbind(D1DGrp_Bz, Qntl_Bz + 1)]
    )
    #Select a random value in range for each SimBzone
    MFProp_Bz <- t(apply(Range_Bz2, 1, function(x) runif(1, x[1], x[2])))
    #Calculate numbers of multifamily and single-family units each SimBzone
    MFDU_ <- round(Hh_Bz * MFProp_Bz)
    SFDU_ <- Hh_Bz - MFDU_
    #Return a list of the results
    list(
      SFDU = SFDU_,
      MFDU = MFDU_,
      PropMF = MFDU_ / (MFDU_ + SFDU_)
    )
  }

#Define a function to test the housing split for a place
#-------------------------------------------------------
testHousingSplit <- function(Data_df, LocType, PlaceName) {
  #Get the model data to use
  ProfileName <- switch(LocType,
                        Metropolitan = "UaProfiles",
                        Town = "RuProfiles",
                        Rural = "RuProfiles"
  )
  #Apply the model
  DU_ls <- calculateHousingUnitsByType(
    Hh_Bz = Data_df$HH,
    D1DGrp_Bz = Data_df$D1DGrp,
    D5Grp_Bz = Data_df$D5Grp,
    D1Qntl_mx = SimBzone_ls[[ProfileName]]$D1Qntl_mx
  )
  #Calculate estimated and observed numbers of multifamily units
  NumMF_D1Ty <- cbind(
    Est = tapply(DU_ls$MFDU, Data_df$D1DGrp, sum, na.rm = TRUE),
    Obs = round(tapply(with(Data_df, HH * PropMF), Data_df$D1DGrp, sum, na.rm = TRUE)))
  #Calculate estimated and observed numbers of single-family units
  NumSF_D1Ty <- cbind(
    Est = tapply(DU_ls$SFDU, Data_df$D1DGrp, sum, na.rm = TRUE),
    Obs = round(tapply(with(Data_df, HH * PropSF), Data_df$D1DGrp, sum, na.rm = TRUE)))
  #Calculate multifamily proportion
  PropMF_D1Ty <- NumMF_D1Ty / (NumMF_D1Ty + NumSF_D1Ty)
  #Plot comparison of numbers of multifamily dwellings by density level
  matplot(NumMF_D1Ty, type = "l", lty = c(1,2), col = "black",
          xlab = "Density Level", ylab = "Multifamily Dwelling Units", 
          main = paste0(PlaceName, "\nMultifamily Units"))
  legend("topleft", legend = c("Model", "Observed"), bty = "n", lty = c(1, 2))
  #Plot comparison of multifamily dwelling unit proportions by density level
  matplot(PropMF_D1Ty, type = "l", lty = c(1,2), col = "black",
          xlab = "Density Level", ylab = "Multifamily Proportion", 
          main = paste0(PlaceName, "\nMultifamily Proportion"))
  legend("topleft", legend = c("Model", "Observed"), bty = "n", lty = c(1, 2))
}

#Test model for different location types and states
#--------------------------------------------------
#All areas
png("data/housing-split_by_loctype_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3,2))
testHousingSplit(Ua_df, "Metropolitan", "Metropolitan")
testHousingSplit(Tn_df, "Town", "Town")
testHousingSplit(Ru_df, "Rural", "Rural")
par(Opar_ls)
dev.off()
#Oregon
png("data/housing-split_by_loctype_or_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3,2))
testHousingSplit(Ua_df[Ua_df$STATE == "OR",], "Metropolitan", "Oregon Metropolitan")
testHousingSplit(Tn_df[Tn_df$STATE == "OR",], "Town", "Oregon Town")
testHousingSplit(Ru_df[Ru_df$STATE == "OR",], "Rural", "Oregon Rural")
par(Opar_ls)
dev.off()
#Washington
png("data/housing-split_by_loctype_wa_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3,2))
testHousingSplit(Ua_df[Ua_df$STATE == "WA",], "Metropolitan", "Washington Metropolitan")
testHousingSplit(Tn_df[Tn_df$STATE == "WA",], "Town", "Washington Town")
testHousingSplit(Ru_df[Ru_df$STATE == "WA",], "Rural", "Washington Rural")
par(Opar_ls)
dev.off()
#Ohio
png("data/housing-split_by_loctype_oh_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3,2))
testHousingSplit(Ua_df[Ua_df$STATE == "OH",], "Metropolitan", "Ohio Metropolitan")
testHousingSplit(Tn_df[Tn_df$STATE == "OH",], "Town", "Ohio Town")
testHousingSplit(Ru_df[Ru_df$STATE == "OH",], "Rural", "Ohio Rural")
par(Opar_ls)
dev.off()
#Urbanized area comparisons
png("data/housing-split_by_ua1-ua3_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3, 2))
for (ua in UzaToPlot_[1:3]) {
  testHousingSplit(Ua_df[Ua_df$UZA_NAME == ua, ], "Metropolitan", ua)
}
par(Opar_ls)
dev.off()
png("data/housing-split_by_ua4-ua6_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3, 2))
for (ua in UzaToPlot_[4:6]) {
  testHousingSplit(Ua_df[Ua_df$UZA_NAME == ua, ], "Metropolitan", ua)
}
par(Opar_ls)
dev.off()
png("data/housing-split_by_ua7-ua9_test.png", height = 480, width = 480)
Opar_ls <- par(mfrow = c(3, 2))
for (ua in UzaToPlot_[7:9]) {
  testHousingSplit(Ua_df[Ua_df$UZA_NAME == ua, ], "Metropolitan", ua)
}
par(Opar_ls)
dev.off()


#===============================
#DEVELOP PLACE TYPE DESIGNATIONS
#===============================
#Place types simplify the characterization of land use patterns. They are used
#in the VESimLandUse package modules to simplify the management of inputs for
#land-use-related policies. There are three dimensions to the place type system.
#Location type identifies whether the SimBzone is located in an urbanized area 
#(Metropolitan), a smaller urban area (Town), or a non-urban area (Rural). Area
#types classify the 

#Function to calculate density levels used in area type
#------------------------------------------------------
calcDensityLvls <- function(ActDen_Bz) {
  Values_Bz <- ActDen_Bz
  #Brks_ <- c(0, 0.1, 1, 5, max(Values_Bz))
  #Brks_ <- c(0, 0.5, 2, 8, max(Values_Bz))
  Brks_ <- c(0, 0.5, 5, 10, max(Values_Bz))
  Cut_ <- cut(Values_Bz, Brks_, labels = FALSE, include.lowest = TRUE)
  Labels_ <- c("VL", "L", "M", "H")
  Labels_[Cut_]
}

#Function to calculate destination accessibility levels used in area type
#------------------------------------------------------------------------
calcDestAccessLvls <- function(D5_Bz) {
  Values_Bz <- D5_Bz
  #Brks_ <- c(0, 1e3, 5e3, 2e4, max(Values_Bz))
  Brks_ <- c(0, 2e3, 1e4, 5e4, max(Values_Bz))
  Cut_ <- cut(Values_Bz, Brks_, labels = FALSE, include.lowest = TRUE)
  Labels_ <- c("VL", "L", "M", "H")
  Labels_[Cut_]
}

#Function to calculate area type
#-------------------------------
calcAreaType <- 
  function(ActDen_Bz, D5_Bz) {
    N <- length(ActDen_Bz)
    #Calculate density levels
    Den_Bz <- calcDensityLvls(ActDen_Bz)
    #Calculate destination accessibility levels
    Dest_Bz <- calcDestAccessLvls(D5_Bz)
    #Define area types in matrix
    AreaType_mx <- rbind(
      c("fringe", "fringe", "outer", "outer"),
      c("fringe", "outer", "outer", "inner"),
      c("outer", "outer", "inner", "inner"),
      c("outer", "inner", "center", "center")
    )
    rownames(AreaType_mx) <- c("VL", "L", "M", "H")
    colnames(AreaType_mx) <- c("VL", "L", "M", "H")
    #Assign area types
    AreaType_mx[cbind(Den_Bz, Dest_Bz)]
  }

#Function to calculate development type
#--------------------------------------
calcDevelopmentType <- function(D2Grp_Bz) {
  DevType_Bz <- character(length(D2Grp_Bz))
  DevType_Bz[D2Grp_Bz == "mixed"] <- "mix"
  DevType_Bz[D2Grp_Bz %in% c("primarily-hh", "largely-hh")] <- "res"
  DevType_Bz[D2Grp_Bz %in% c("largely-job", "primarily-job")] <- "emp"
  DevType_Bz
}

#Calculate area and development types for block groups
#-----------------------------------------------------
#Area type
Ua_df$AreaType <- calcAreaType(Ua_df$D1D, Ua_df$D5)
Tn_df$AreaType <- calcAreaType(Tn_df$D1D, Tn_df$D5)
Ru_df$AreaType <- calcAreaType(Ru_df$D1D, Ru_df$D5)
#Development type
Ua_df$DevType <- calcDevelopmentType(Ua_df$D2Grp)
Tn_df$DevType <- calcDevelopmentType(Tn_df$D2Grp)
Ru_df$DevType <- calcDevelopmentType(Ru_df$D2Grp)
#Create a joined dataset typle along with positions and other data
Fields_ <- c("GEOID10", "STATE", "UZA_NAME", "LAT", "LNG", "TOTACT", "D2Grp", "AreaType", "DevType")
Pt_df <- rbind(Ua_df[,Fields_], Ru_df[,Fields_], Ru_df[,Fields_])
rm(Fields_)

#Make map backgrounds for displaying place types
#-----------------------------------------------
#Do this only if base maps don't exist
UzaToMap_ <- c("Atlanta, GA", "Portland, OR")
BaseMapFiles_ <- 
  sapply(UzaToMap_, function(x) paste0("data/", gsub(", ", "_", x), ".rds"))
if (!all(file.exists(BaseMapFiles_))) {
  library(OpenStreetMap)
  #Function to convert downloaded open street map to a raster for display
  osmToRaster <- function(OSM_ls) {
    x <- OSM_ls$tiles[[1]]
    xres <- x$xres
    yres <- x$yres
    list(
      image = as.raster(matrix(x$colorData,nrow=xres,byrow=TRUE)),
      xleft = x$bbox$p1[1] - .5*abs(x$bbox$p1[1]-x$bbox$p2[1])/yres,
      ybottom =  x$bbox$p2[2] + .5*abs(x$bbox$p1[2]-x$bbox$p2[2])/xres,
      xright = x$bbox$p2[1] - .5*abs(x$bbox$p1[1]-x$bbox$p2[1])/yres,
      ytop = x$bbox$p1[2] + .5*abs(x$bbox$p1[2]-x$bbox$p2[2])/xres
    )
  }
  #Function to download open street map for urbanized area and save
  saveUaOSM <- function(UaName) {
    #Get location information for block groups in urbanized area
    Data_df <- Ua_df[Ua_df$UZA_NAME == UaName, c("LAT", "LNG")]
    #Download the map
    UaMapOsm <- openmap(
      upperLeft = with(Data_df, c(max(LAT), min(LNG))),
      lowerRight = with(Data_df, c(min(LAT), max(LNG)))
    )
    #Reproject to geographic coordinates
    UaMap <- openproj(UaMapOsm, projection = "+proj=longlat")
    #Convert to raster list
    UaRasterMap <- osmToRaster(UaMap)
    #Save as file
    FileName <- paste0("data/", gsub(", ", "_", UaName), ".rds")
    saveRDS(UaRasterMap, file = FileName)
  }
  #Iterate through urban areas and save base map files
  for (ua in UzaToMap_) {
    saveUaOSM(ua)
  }
  rm(osmToRaster, saveUaOSM, ua)
}
rm(BaseMapFiles_)

#Define function to map area types
#---------------------------------
mapAreaType <- function(UaName, ...) {
  #Get block group positions and assigned area types
  Data_df <- Ua_df[Ua_df$UZA_NAME == UaName, c("LAT", "LNG", "AreaType")]
  #Initial plot to set up bounds and labels
  plot(Data_df$LNG, Data_df$LAT, type = "n",
       xlab = "Longitude", ylab = "Latitude",
       main = paste("Area Type for", UaName))
  #Load background map raster image
  FileName <- paste0("data/", gsub(", ", "_", UaName), ".rds")
  UaRaster_ls <- readRDS(FileName)
  #Plot the background map
  # with(UaRaster_ls, plot(xleft, ytop, xlim = c(xleft, xright), ylim = c(ybottom, ytop)))
  rasterImage(
    UaRaster_ls[[1]],
    UaRaster_ls[[2]],
    UaRaster_ls[[3]],
    UaRaster_ls[[4]],
    UaRaster_ls[[5]])
  #Plot the area types as colored points
  AreaPalette_ <-  c(center = "tomato",
                     inner = "royalblue", 
                     outer = "limegreen",
                     fringe = "goldenrod")
  Col_ <- unname(AreaPalette_[Data_df$AreaType])
  points(Data_df$LNG, Data_df$LAT, pch = 20, col = Col_, ...)
  #Add the legend
  legend("bottomleft", legend = names(AreaPalette_), pch = 20, col = AreaPalette_)
}

#Define function to map development types
#----------------------------------------
mapDevType <- function(UaName, ...) {
  #Get block group positions and assigned area types
  Data_df <- Ua_df[Ua_df$UZA_NAME == UaName, c("LAT", "LNG", "DevType")]
  #Initial plot to set up bounds and labels
  plot(Data_df$LNG, Data_df$LAT, type = "n",
       xlab = "Longitude", ylab = "Latitude",
       main = paste("Development Type for", UaName))
  #Load background map raster image
  FileName <- paste0("uabasemaps/", gsub(", ", "_", UaName), ".rds")
  UaRaster_ls <- readRDS(FileName)
  #Plot the background map
  # with(UaRaster_ls, plot(xleft, ytop, xlim = c(xleft, xright), ylim = c(ybottom, ytop)))
  rasterImage(
    UaRaster_ls[[1]],
    UaRaster_ls[[2]],
    UaRaster_ls[[3]],
    UaRaster_ls[[4]],
    UaRaster_ls[[5]])
  #Plot the area types as colored points
  DevPalette_ <- c(
    emp = "tomato", 
    mix = "royalblue",
    res = "limegreen"
  )
  Col_ <- unname(DevPalette_[Data_df$DevType])
  points(Data_df$LNG, Data_df$LAT, pch = 20, col = Col_, ...)
  #Add the legend
  legend("bottomleft", legend = names(DevPalette_), pch = 20, col = DevPalette_)
}

#Map area types and development types for 3 urbanized areas
#----------------------------------------------------------
png("data/ua_place-type_examples.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(2,2))
UaNames_ <- c("Atlanta, GA", "Portland, OR")
for (ua in UaNames_) {
  mapAreaType(ua)
  mapDevType(ua)
}
par(Opar_ls)
rm(Opar_ls, UaNames_, ua)
dev.off()


#==================
#D3 VARIABLES MODEL
#==================
#This model is implemented using several datasets for each area where areas are
#urbanized areas, urbanized area size groups, towns in aggregate, and rural
#areas in aggregate. The model has two components. The first component is used
#to determine whether a SimBzone will have a D3bpo4 value of zero. The second
#component is used to determine what the D3bpo4 value is if non-zero. This
#2-step approach is used because a significant proportion (~ 10%) of block 
#groups have a zero value and because the distribution of values is highly
#skewed so transformation is warranted in order to develop sampling
#distributions. The user may optionally provide target values for the zero
#proportion for each area and the average D3bpo4 value for each area. The model
#assigns corresponding zero proportions to each place type in each area. This
#assignment of zero proportions by place type is explained below. Random
#sampling using those place type proportions is used to determine whether a
#SimBzone has a D3bpo4 value of 0. For SimBzones that have non-zero values, the
#model assigns corresponding target average D3bpo4 value for each place type in
#each area. The target mean value for an area (e.g. urbanized area) and place
#type along with an estimated standard deviation for the area and place type
#form the basis for a power-transformed sampling distribution from which a
#transformed D3bpo4 value is chosen for each SimBzone of that place type. The
#selected value is untransformed to produce the D3bpo4 value assigned to the
#SimBzone. The translation of the area (e.g. urbanized area) value into place
#type values for the area is accomplished using estimated ratios of place type
#values to the overall area value. These ratios are computed for the zero
#proportions and for the D3bpo4 values.

#Define place type dimnames
#--------------------------
#Area type
At <- c("center", "inner", "outer", "fringe")
#Development type
Dt <- c("emp", "mix", "res")
#Place type
Pt <- apply(expand.grid(At, Dt), 1, function(x) paste(x, collapse = "."))

#Create D3 analysis dataset for urbanized areas
#----------------------------------------------
VarNm_ <- 
  c("UZA_NAME", "UZA_SIZE", "STATE", "D3bpo4", "TOTACT", "AreaType", "DevType")
Tmp_df <- Ua_df[,VarNm_]
Tmp_df$IsZero <- Tmp_df$D3bpo4 == 0
Tmp_df$PlaceType <- paste(Tmp_df$AreaType, Tmp_df$DevType, sep = ".")
Tmp_Ua_df <- split(Tmp_df, Tmp_df$UZA_NAME)
Tmp_Sz_df <- split(Tmp_df, Tmp_df$UZA_SIZE)

#Calculate the zero D3bpo4 proportion of activity by area
#--------------------------------------------------------
PropZeroD3_Ua <- unlist(lapply(Tmp_Ua_df, function(x) {
  sum(x$TOTACT * as.numeric(x$IsZero), na.rm = TRUE) / sum(x$TOTACT, na.rm = TRUE)
}))
PropZeroD3_Sz <- unlist(lapply(Tmp_Sz_df, function(x) {
  sum(x$TOTACT * as.numeric(x$IsZero), na.rm = TRUE) / sum(x$TOTACT, na.rm = TRUE)
}))

#Calculate the zero D3bpo4 proportions by area and place type
#------------------------------------------------------------
#Urbanized area calculations
PropZeroD3_UaPt <- do.call(rbind, lapply(Tmp_Ua_df, function(x) {
  PropZeroD3_Pt <- rep(NA, length(Pt))
  names(PropZeroD3_Pt) <- Pt
  PropZero_BY <- by(x, x$PlaceType, function(y) {
    sum(y$TOTACT * as.numeric(y$IsZero), na.rm = TRUE) / sum(y$TOTACT, na.rm = TRUE)
  })
  PropZeroD3_Pt[names(PropZero_BY)] <- PropZero_BY
  PropZeroD3_Pt
}))
#Urbanized area size group calculations
PropZeroD3_SzPt <- do.call(rbind, lapply(Tmp_Sz_df, function(x) {
  PropZeroD3_Pt <- rep(NA, length(Pt))
  names(PropZeroD3_Pt) <- Pt
  PropZero_BY <- by(x, x$PlaceType, function(y) {
    sum(y$TOTACT * as.numeric(y$IsZero), na.rm = TRUE) / sum(y$TOTACT, na.rm = TRUE)
  })
  PropZeroD3_Pt[names(PropZero_BY)] <- PropZero_BY
  PropZeroD3_Pt
}))

#Calculate the weighted average (non-zero) D3bpo4 value by area
#--------------------------------------------------------------
#Define function to calculate power transform to minimize skewness
findPower <- function(Inc_) {
  skewness <- function (x)
  {
    x <- x[!is.na(x)]
    n <- length(x)
    x <- x - mean(x)
    y <- sqrt(n) * sum(x^3)/(sum(x^2)^(3/2))
    y * ((1 - 1/n))^(3/2)
  }
  checkSkewMatch <- function(Pow) {
    skewness(Inc_^Pow)
  }
  binarySearch(checkSkewMatch, c(0.001,1), Target = 0)
}
#Determine the power transform to best normalize the distribution of values
D3bpo4_ <- with(Tmp_df, D3bpo4[!IsZero])
D3Pow <- findPower(D3bpo4_)
png("data/ua_pwr-transform-d3_dist.png", width = 480, height = 480)
plot(density(D3bpo4_ ^ D3Pow), xlab = "Power-Transformed D3bpo4",
     ylab = "Probability Density",
     main = "Distribution of Block Group Power-Transformed D3bpo4")
dev.off()
#Calculate the average D3bpo4 by urbanized area
PowWtAveD3_Ua <- unlist(lapply(Tmp_Ua_df, function(x) {
  D3bpo4_ <- x$D3bpo4[!x$IsZero]
  PowD3bpo4_ <- D3bpo4_ ^ D3Pow
  TotAct_ <- x$TOTACT[!x$IsZero]
  PowWtAveD3 <- 
    sum(PowD3bpo4_ * TotAct_ / sum(TotAct_, na.rm = TRUE), na.rm = TRUE)
  PowWtAveD3
}))
WtAveD3_Ua <- PowWtAveD3_Ua ^ (1 / D3Pow)
#Calculate the average D3bpo4 by size group
PowWtAveD3_Sz <- unlist(lapply(Tmp_Sz_df, function(x) {
  D3bpo4_ <- x$D3bpo4[!x$IsZero]
  PowD3bpo4_ <- D3bpo4_ ^ D3Pow
  TotAct_ <- x$TOTACT[!x$IsZero]
  PowWtAveD3 <- 
    sum(PowD3bpo4_ * TotAct_ / sum(TotAct_, na.rm = TRUE), na.rm = TRUE)
  PowWtAveD3
}))
WtAveD3_Sz <- PowWtAveD3_Sz ^ (1 / D3Pow)

#Tabulate the transformed mean D3bpo4 value by urbanized area and place type
#---------------------------------------------------------------------------
#Calculate activity-weighted block group average by urbanized area and place type
PowWtAveD3_UaPt <- do.call(rbind, lapply(Tmp_Ua_df, function(x) {
  X_df <- data.frame(
    PowD3bpo4 = x$D3bpo4[!x$IsZero] ^ D3Pow,
    TotAct = x$TOTACT[!x$IsZero],
    PlaceType = x$PlaceType[!x$IsZero]
  )
  PowWtAveD3_Pt <- rep(NA, length(Pt))
  names(PowWtAveD3_Pt) <- Pt
  PowWtAveD3_BY <- by(X_df, X_df$PlaceType, function(y) {
    sum((y$PowD3bpo4 * y$TotAct) / sum(y$TotAct, na.rm = TRUE), na.rm = TRUE)
  })
  PowWtAveD3_Pt[names(PowWtAveD3_BY)] <- PowWtAveD3_BY
  PowWtAveD3_Pt
}))
#Calculate activity-weighted block group average by size and place type
PowWtAveD3_SzPt <- do.call(rbind, lapply(Tmp_Sz_df, function(x) {
  X_df <- data.frame(
    PowD3bpo4 = x$D3bpo4[!x$IsZero] ^ D3Pow,
    TotAct = x$TOTACT[!x$IsZero],
    PlaceType = x$PlaceType[!x$IsZero]
  )
  PowWtAveD3_Pt <- rep(NA, length(Pt))
  names(PowWtAveD3_Pt) <- Pt
  PowWtAveD3_BY <- by(X_df, X_df$PlaceType, function(y) {
    sum((y$PowD3bpo4 * y$TotAct) / sum(y$TotAct, na.rm = TRUE), na.rm = TRUE)
  })
  PowWtAveD3_Pt[names(PowWtAveD3_BY)] <- PowWtAveD3_BY
  PowWtAveD3_Pt
}))
png("data/ua_pwr-transform-d3_dist_by_place-type.png", width = 480, height = 480)
Opar_ls <- par(las = 2, mar = c(7, 4, 3, 1))
boxplot(PowWtAveD3_UaPt, notch = TRUE,
        ylab = "Power-Transformed D3bpo4",
        main = "Distribution of Power-Transformed D3bpo4 by Place Type")
par(Opar_ls)
dev.off()

#Impute values where urbanized area place type values are NA
#-----------------------------------------------------------
#Values for urbanized area place type NA values are imputed by taking the
#weighted average of the non-NA place type values for other urbanized areas
#where the weights are a function of the difference between the overall average
#D3bpo4 value for the urbanized area and the other urbanized areas
#Define function to impute values
WtgVals_ <- PowWtAveD3_Ua
Vals_ <- PowWtAveD3_UaPt[,1]
imputeValues <- function(Vals_, WtgVals_) {
  #Function to calculate weight matrix
  calcWts <- function(WtgVals_) {
    Dist_mx <- abs(outer(WtgVals_, WtgVals_, "-"))
    MinDist_ <- apply(Dist_mx, 1, function(x) min(x[x != 0]))
    Wts_mx <- sweep(1 / Dist_mx, 1, MinDist_, "*")
    Wts_mx[is.infinite(Wts_mx)] <- 0 
    Wts_mx
  }
  #Function to compute weighted average
  wtAve <- function(Vals_, Wts_) {
    sum(Vals_ * Wts_ / sum(Wts_, na.rm = TRUE), na.rm = TRUE)
  }
  #Impute values
  Wts_mx <- calcWts(WtgVals_)
  NaIdx_ <- which(is.na(Vals_))
  Imp_ <- sapply(NaIdx_, function(x) {
    wtAve(Vals_, Wts_mx[x,])
  })
  Vals_[NaIdx_] <- Imp_
  Vals_
}
#Impute values for PowWtAveD3_UaPt
PowWtAveD3_UaPt <- apply(PowWtAveD3_UaPt, 2, function(x) imputeValues(x, PowWtAveD3_Ua))
#Impute values for PropZeroD3_UaPt
PropZeroD3_UaPt <- apply(PropZeroD3_UaPt, 2, function(x) imputeValues(x, PropZeroD3_Ua))
PropZeroD3_UaPt[PropZeroD3_Ua == 0,] <- 0

#Calculate the relative place type values for urbanized areas
#------------------------------------------------------------
#Combine the individual urbanized area and urbanized size data
PowWtAveD3_UaPt <- rbind(PowWtAveD3_UaPt, PowWtAveD3_SzPt)
rm(PowWtAveD3_SzPt)
PropZeroD3_UaPt <- rbind(PropZeroD3_UaPt, PropZeroD3_SzPt)
rm(PropZeroD3_SzPt)
PowWtAveD3_Ua <- c(PowWtAveD3_Ua, PowWtAveD3_Sz)
rm(PowWtAveD3_Sz)
PropZeroD3_Ua <- c(PropZeroD3_Ua, PropZeroD3_Sz)
rm(PropZeroD3_Sz)
#Calculate ratio of urbanized area values by place type and urbanized area mean
RelPowWtAveD3_UaPt <- sweep(PowWtAveD3_UaPt, 1, PowWtAveD3_Ua, "/")
RelPropZeroD3_UaPt <- sweep(PropZeroD3_UaPt, 1, PropZeroD3_Ua, "/")
RelPropZeroD3_UaPt[is.nan(RelPropZeroD3_UaPt)] <- 0

#Calculate the standard deviation of the urbanized means by place type
#---------------------------------------------------------------------
Tmp_Pt_df <- split(Tmp_df[!Tmp_df$IsZero,], Tmp_df$PlaceType[!Tmp_df$IsZero])
PowWtAveD3_Pt <- unlist(lapply(Tmp_Pt_df, function(x) {
  PowD3bpo4_ <- x$D3bpo4 ^ D3Pow
  Keep <- PowD3bpo4_ < quantile(PowD3bpo4_, probs = 0.99)
  sum(PowD3bpo4_[Keep] * x$TOTACT[Keep] / sum(x$TOTACT[Keep], na.rm = TRUE), 
      na.rm = TRUE)
}))[Pt]
PowWtVarD3_Pt <- sapply(names(PowWtAveD3_Pt), function(x) {
  PowD3bpo4_ <- Tmp_Pt_df[[x]]$D3bpo4 ^ D3Pow
  Keep <- PowD3bpo4_ < quantile(PowD3bpo4_, probs = 0.99)
  PowD3bpo4_ <- PowD3bpo4_[Keep]
  TotAct_ <- Tmp_Pt_df[[x]]$TOTACT[Keep]
  Wts_ <- TotAct_ / sum(TotAct_, na.rm = TRUE)
  PowWtAveD3 <- PowWtAveD3_Pt[x]
  sum(Wts_ * (PowD3bpo4_ - PowWtAveD3)^2, na.rm = TRUE)
})
PowWtSdD3_Pt <- sqrt(PowWtVarD3_Pt)
rm(PowWtAveD3_Pt, PowWtVarD3_Pt)

#Add the urbanized area D3bpo4 values to the SimBzone_ls
#-------------------------------------------------------
SimBzone_ls$UaProfiles$WtAveD3_Ua <- WtAveD3_Ua
SimBzone_ls$UaProfiles$PropZeroD3_Ua <- PropZeroD3_Ua
SimBzone_ls$UaProfiles$RelPowWtAveD3_UaPt <- RelPowWtAveD3_UaPt
SimBzone_ls$UaProfiles$RelPropZeroD3_UaPt <- RelPropZeroD3_UaPt
SimBzone_ls$UaProfiles$PowWtSdD3_Pt <- PowWtSdD3_Pt
SimBzone_ls$UaProfiles$D3Pow <- D3Pow
rm(WtAveD3_Ua, PropZeroD3_Ua, RelPowWtAveD3_UaPt, RelPropZeroD3_UaPt, PowWtSdD3_Pt)
rm(Tmp_df, Tmp_Ua_df, Tmp_Sz_df)

#Calculate D3bpo4 values for town and rural areas
#------------------------------------------------
#Define function for calculating values
calcD3Values <- function(Data_df) {
  #Data for analysis
  VarNm_ <- 
    c("STATE", "D3bpo4", "TOTACT", "AreaType", "DevType")
  Tmp_df <- Data_df[,VarNm_]
  Tmp_df$IsZero <- Tmp_df$D3bpo4 == 0
  Tmp_df$PlaceType <- paste(Tmp_df$AreaType, Tmp_df$DevType, sep = ".")
  Tmp_Pt_df <- split(Tmp_df, Tmp_df$PlaceType)
  #Calculate overall zero proportion
  PropZeroD3 <- 
    with(Tmp_df, 
         sum(TOTACT * as.numeric(IsZero), na.rm = TRUE) / sum(TOTACT, na.rm = TRUE)
    )
  #Calculate the zero proportion by place type
  PropZeroD3_Pt <- unlist(lapply(Tmp_Pt_df, function(x) {
    sum(x$TOTACT * as.numeric(x$IsZero), na.rm = TRUE) / sum(x$TOTACT, na.rm = TRUE)
  }))
  #Calculate the relative zero proportion
  RelPropZeroD3_Pt <- PropZeroD3_Pt / PropZeroD3
  #Determine the power transform to best normalize the distribution of values
  D3bpo4_ <- with(Tmp_df, D3bpo4[!IsZero])
  D3Pow <- findPower(D3bpo4_)
  PowD3bpo4_ <- D3bpo4_ ^ D3Pow
  #Calculate the average D3bpo4 for all towns
  TotAct_ <- with(Tmp_df, TOTACT[!IsZero])
  PowWtAveD3 <- sum(PowD3bpo4_ * TotAct_ / sum(TotAct_, na.rm = TRUE), na.rm = TRUE)
  WtAveD3 <- PowWtAveD3 ^ (1 / D3Pow)
  #Calculate activity-weighted block group average by place type
  PowWtAveD3_Pt <- unlist(lapply(Tmp_Pt_df, function(x) {
    PowD3bpo4_ <- x$D3bpo4[!x$IsZero] ^ D3Pow
    TotAct_ <- x$TOTACT[!x$IsZero]
    Keep <- PowD3bpo4_ < quantile(PowD3bpo4_, probs = 0.99)
    sum(PowD3bpo4_[Keep] * TotAct_[Keep] / sum(TotAct_[Keep], na.rm = TRUE), 
        na.rm = TRUE)
  }))[Pt]
  names(PowWtAveD3_Pt) <- Pt
  PowWtAveD3_Pt[is.na(PowWtAveD3_Pt)] <- 0
  #Calculate the relative place type average
  RelPowWtAveD3_Pt <- PowWtAveD3_Pt / PowWtAveD3
  #Calculate the standard deviation of the place type average
  PowWtVarD3_Pt <- sapply(names(PowWtAveD3_Pt), function(x) {
    PowD3bpo4_ <- Tmp_Pt_df[[x]]$D3bpo4 ^ D3Pow
    Keep <- PowD3bpo4_ < quantile(PowD3bpo4_, probs = 0.99)
    PowD3bpo4_ <- PowD3bpo4_[Keep]
    TotAct_ <- Tmp_Pt_df[[x]]$TOTACT[Keep]
    Wts_ <- TotAct_ / sum(TotAct_, na.rm = TRUE)
    PowWtAveD3 <- PowWtAveD3_Pt[x]
    sum(Wts_ * (PowD3bpo4_ - PowWtAveD3)^2, na.rm = TRUE)
  })[Pt]
  names(PowWtVarD3_Pt) <- Pt
  PowWtSdD3_Pt <- sqrt(PowWtVarD3_Pt)
  #Add the town D3bpo4 values to the SimBzone_ls
  list(
    WtAveD3 = WtAveD3,
    PropZeroD3 = PropZeroD3,
    RelPowWtAveD3_Pt = RelPowWtAveD3_Pt,
    RelPropZeroD3_Pt = RelPropZeroD3_Pt,
    PowWtSdD3_Pt = PowWtSdD3_Pt,
    D3Pow = D3Pow
  )
}
#Calculate town values and add to SimBzone_ls
TownD3_ls <- calcD3Values(Tn_df)
SimBzone_ls$TnProfiles$WtAveD3 <- TownD3_ls$WtAveD3
SimBzone_ls$TnProfiles$PropZeroD3 <- TownD3_ls$PropZeroD3
SimBzone_ls$TnProfiles$RelPowWtAveD3_Pt <- TownD3_ls$RelPowWtAveD3_Pt
SimBzone_ls$TnProfiles$RelPropZeroD3_Pt <- TownD3_ls$RelPropZeroD3_Pt
SimBzone_ls$TnProfiles$PowWtSdD3_Pt <- TownD3_ls$PowWtSdD3_Pt
SimBzone_ls$TnProfiles$D3Pow <- TownD3_ls$D3Pow
rm(TownD3_ls)
#Calculate rural values and add to SimBzone_ls
RuralD3_ls <- calcD3Values(Ru_df)
SimBzone_ls$RuProfiles$WtAveD3 <- RuralD3_ls$WtAveD3
SimBzone_ls$RuProfiles$PropZeroD3 <- RuralD3_ls$PropZeroD3
SimBzone_ls$RuProfiles$RelPowWtAveD3_Pt <- RuralD3_ls$RelPowWtAveD3_Pt
SimBzone_ls$RuProfiles$RelPropZeroD3_Pt <- RuralD3_ls$RelPropZeroD3_Pt
SimBzone_ls$RuProfiles$PowWtSdD3_Pt <- RuralD3_ls$PowWtSdD3_Pt
SimBzone_ls$RuProfiles$D3Pow <- RuralD3_ls$D3Pow
rm(RuralD3_ls)

#Define a function to assign a D3bpo4 value to SimBzones
#-------------------------------------------------------
#Function is applied to location types within an Azone
calcD3bpo4 <- function(
  AreaType_Bz, DevType_Bz, AreaName, AveTarget = NULL, PropZeroTarget = NULL) {
  N <- length(AreaType_Bz)
  #Retrieve model values consistent with area name
  if (AreaName %in% c("Town", "Rural")) {
    if (AreaName == "Town") {
      WtAveD3 <- SimBzone_ls$TnProfiles$WtAveD3
      PropZeroD3 <- SimBzone_ls$TnProfiles$PropZeroD3
      RelPowWtAveD3_Pt <- SimBzone_ls$TnProfiles$RelPowWtAveD3_Pt
      RelPropZeroD3_Pt <- SimBzone_ls$TnProfiles$RelPropZeroD3_Pt
      PowWtSdD3_Pt <- SimBzone_ls$TnProfiles$PowWtSdD3_Pt
    } else {
      WtAveD3 <- SimBzone_ls$RuProfiles$WtAveD3
      PropZeroD3 <- SimBzone_ls$RuProfiles$PropZeroD3
      RelPowWtAveD3_Pt <- SimBzone_ls$RuProfiles$RelPowWtAveD3_Pt
      RelPropZeroD3_Pt <- SimBzone_ls$RuProfiles$RelPropZeroD3_Pt
      PowWtSdD3_Pt <- SimBzone_ls$RuProfiles$PowWtSdD3_Pt
    }
  } else {
    WtAveD3 <- SimBzone_ls$UaProfiles$WtAveD3_Ua[AreaName]
    PropZeroD3 <- SimBzone_ls$UaProfiles$PropZeroD3_Ua[AreaName]
    RelPowWtAveD3_Pt <- SimBzone_ls$UaProfiles$RelPowWtAveD3_UaPt[AreaName,]
    RelPropZeroD3_Pt <- SimBzone_ls$UaProfiles$RelPropZeroD3_UaPt[AreaName,]
    PowWtSdD3_Pt <- SimBzone_ls$UaProfiles$PowWtSdD3_Pt
  }
  if (!is.null(AveTarget)) WtAveD3 <- AveTarget
  if (!is.null(PropZeroTarget)) PropZeroD3 <- PropZeroTarget
  #Power transform
  D3Pow <- SimBzone_ls$UaProfiles$D3Pow
  #Create the place type names
  PlaceType_Bz <- paste(AreaType_Bz, DevType_Bz, sep = ".")
  #Identify the SimBzones that have a value of zero
  PropZeroD3_Pt <- PropZeroD3 * RelPropZeroD3_Pt
  PropZeroD3_Bz <- PropZeroD3_Pt[PlaceType_Bz]
  IsZero_Bz <- runif(N) < PropZeroD3_Bz
  #Calculate a D3bpo4 values
  PowWtAveD3_Pt <- RelPowWtAveD3_Pt * WtAveD3 ^ D3Pow
  PowWtAveD3_Bz <- PowWtAveD3_Pt[PlaceType_Bz]
  PowWtSdD3_Bz <- PowWtSdD3_Pt[PlaceType_Bz]
  PowD3_Bz <- rnorm(N, PowWtAveD3_Bz, PowWtSdD3_Bz)
  PowD3_Bz[IsZero_Bz] <- 0
  #Return the result
  PowD3_Bz ^ (1 / D3Pow)
}

#Test the D3bpo model for selected urbanized areas
#-------------------------------------------------
png("data/ua_d3bpo4-test_.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(3,3), oma = c(0,0,3,0))
plotCompareD3 <- function(UzaName) {
  PtTest_ <- calcD3bpo4(
    AreaType_Bz = Ua_df$AreaType[Ua_df$UZA_NAME == UzaName],
    DevType_Bz = Ua_df$DevType[Ua_df$UZA_NAME == UzaName],
    AreaName = UzaName,
    AveTarget <- NULL,
    PropZeroTarget <- NULL)
  plot(density(PtTest_ ^ D3Pow), main = UzaName)
  lines(density((Ua_df$D3bpo4[Ua_df$UZA_NAME == UzaName]) ^ D3Pow), lty = 2)
}
for (ua in UzaToPlot_) {
  plotCompareD3(ua)
}
mtext(
  text = paste0("Distribution of Modeled (solid line) and Observed (dashed line) D3bpo4 Values",
                "\nFor Selected Metropolitan Areas"),
  side = 3,
  outer = TRUE
)
par(Opar_ls)
dev.off()

#Test the D3bpo model for town and rural areas
#---------------------------------------------
png("data/tn&ru_d3bpo4-test.png", height = 600, width = 480)
Opar_ls <- par(mfrow = c(2,1), oma = c(0,0,3,0))
plotCompareD3 <- function(AreaName) {
  if (AreaName == "Town") {
    Tmp_df <- Tn_df
  }
  if (AreaName == "Rural") {
    Tmp_df <- Ru_df
  }
  PtTest_ <- calcD3bpo4(
    AreaType_Bz = Tmp_df$AreaType,
    DevType_Bz = Tmp_df$DevType,
    AreaName = AreaName,
    AveTarget <- NULL,
    PropZeroTarget <- NULL)
  plot(density(PtTest_ ^ D3Pow, na.rm = TRUE), main = AreaName)
  lines(density((Tmp_df$D3bpo4) ^ D3Pow, na.rm = TRUE), lty = 2)
}
plotCompareD3("Town")
plotCompareD3("Rural")
mtext(
  text = paste0("Distribution of Modeled (solid line) and Observed (dashed line) D3bpo4 Values",
                "\nFor Town and Rural Areas"),
  side = 3,
  outer = TRUE
)
par(Opar_ls)
dev.off()

#Clean up
#--------
rm(Opar_ls, PowWtAveD3_UaPt, PropZeroD3_UaPt, Pt_df, T_df)
rm(Tmp_Pt_df, D1D_, D2, D2A_JPHH_, D3bpo4_, D3Pow, D5_, PowWtAveD3_Ua)
rm(ua, UzaToMap_, Vals_, VarNm_, WtAveD3_Sz, WtgVals_)

#==================
#D4 VARIABLES MODEL
#==================
#Approach is to have a 2-step model. One step determines whether a Bzone has
#a D4c value of 0. The other step determines what the D4c value for a Bzone is
#if it is not 0. There are few variables to base the model on. Relevant ones
#are:
#* Transit revenue miles: higher service should result in higher D4c
#* Density: higher transit service more likely to be provided to higher density
#* Design: higher design neighborhoods more likely to be served by transit
#* Accessibility: higher transit service more likely for higher accessibility
#The total amount of activity (households and employment) in the zone also has
#an effect, but the nature of the effect is not clear and would depend on the
#interaction with other variables. This is resolved in the model by making the
#prediction variable the ratio of D4c to total activity.
#
#Create D4 analysis dataset for urbanized areas
#----------------------------------------------
KeepVars_ <- 
  c("UA_NAME", "STATE", "TransitRevMi", "D4c", "TOTACT", "AreaType", "DevType", 
    "UZA_SIZE", "AC_LAND", "D1D", "D5", "D2Grp", "D3bpo4")
D4_df <- Ua_df[!(is.na(Ua_df$D4c)) & !(is.na(Ua_df$TransitVehMi)), KeepVars_]
rm(KeepVars_)
names(D4_df) <- 
  c("UaName", "State", "RevMi", "D4", "TotAct", "AreaType", "DevType", 
    "UaSize", "AcLand", "D1", "D5", "D2Grp", "D3")
#Identify which D4 values are 0 and remove urbanized areas that have all 0
Is0D4 <- D4_df$D4 == 0
All0D4_Ua <- tapply(Is0D4, D4_df$UaName, all)
RemoveUaName_ <- names(All0D4_Ua[All0D4_Ua])
Is0D4 <- Is0D4[!(D4_df$UaName %in% RemoveUaName_)]
D4_df <- D4_df[!(D4_df$UaName %in% RemoveUaName_),]
rm(All0D4_Ua, RemoveUaName_)
#Place type
D4_df$PlaceType <- paste(D4_df$AreaType, D4_df$DevType, sep = ".")
#Area in square miles
D4_df$SqMi <- D4_df$AcLand / 640
#Calculate ratio of D4 to area and to activity
D4_df$D4PerSqMi <- with(D4_df, D4 / SqMi)
D4_df$D4PerAct <- with(D4_df, D4 / TotAct)

#Calculate urbanized area statistics
#-----------------------------------
UaD4_df <- data.frame(
  UaTotAct = tapply(D4_df$TotAct, D4_df$UaName, sum),
  UaTotSqMi = tapply(D4_df$SqMi, D4_df$UaName, sum),
  UaRevMi = tapply(D4_df$RevMi, D4_df$UaName, function(x) x[1])
)
#Calculate activity in served block groups (i.e. D4 != 0)
UaD4_df$UaSvcAct <- tapply(D4_df$TotAct[!Is0D4], D4_df$UaName[!Is0D4], sum)
UaD4_df$UaPropActSvc <- with(UaD4_df, UaSvcAct / UaTotAct)
#Calculate revenue miles per total activity and per serviced activity
UaD4_df$UaRevMiPerTotAct <- UaD4_df$UaRevMi / UaD4_df$UaTotAct
UaD4_df$UaRevMiPerSvcAct <- UaD4_df$UaRevMi / UaD4_df$UaSvcAct
#Calculate area of served block groups
UaD4_df$UaSvcSqMi <- 
  tapply(D4_df$AcLand[!Is0D4], D4_df$UaName[!Is0D4], sum) / 640
UaD4_df$UaPropSqMiSvc <- with(UaD4_df, UaSvcSqMi / UaTotSqMi)
#Calculate revenue miles per total square miles and per serviced square miles
UaD4_df$UaRevMiPerTotSqMi <- UaD4_df$UaRevMi / UaD4_df$UaTotSqMi
UaD4_df$UaRevMiPerSvcSqMi <- UaD4_df$UaRevMi / UaD4_df$UaSvcSqMi
#Calculate activity weighted average D variables for entire urbanized area
DNames_ <- c("D1", "D3", "D4", "D5")
Tmp_Ua_df <- split(D4_df, D4_df$UaName)
for (dn in DNames_) {
  UaD4_df[[paste0("UaTotAve", dn)]] <- unlist(lapply(Tmp_Ua_df, function(x) {
    sum(x[[dn]] * x$TotAct / sum(x$TotAct))}))
}
#Calculate activity weighted average D variables for served urbanized area
DNames_ <- c("D1", "D3", "D4", "D5")
Tmp_Ua_df <- split(D4_df[!Is0D4,], D4_df$UaName[!Is0D4])
for (dn in DNames_) {
  UaD4_df[[paste0("UaSvcAve", dn)]] <- unlist(lapply(Tmp_Ua_df, function(x) {
    sum(x[[dn]] * x$TotAct / sum(x$TotAct))}))
}
#Calculate ratio of average D4 to revenue miles per square mile
UaD4_df$UaTotAveD4PerRevMiPerSqMi <- 
  with(UaD4_df, UaTotAveD4 / UaRevMiPerTotSqMi)
UaD4_df$UaSvcAveD4PerRevMiPerSqMi <- 
  with(UaD4_df, UaSvcAveD4 / UaRevMiPerSvcSqMi)
#Calculate ratio of average D4 to service square miles
UaD4_df$UaSvcAveD4PerSqMi <- with(UaD4_df, UaSvcAveD4 / UaSvcSqMi)

png("data/sorted_ua_d4-revmi-sqmi.png", width = 480, height = 480)
plot(sort(tapply(D4_df$AveD4PeakRevMiSqMi, D4_df$UaName, unique)),
     ylab = "D4PeakRevMiSqMi",
     main = "D4PeakRevMiSqMi by Urbanized Area, Sorted")
dev.off()

#Linear model of dependent variable: log of D4 normalized by zone area
#---------------------------------------------------------------------
D3Pow <- findPower(D4_df$D3[D4_df$D3 != 0])
UaToBg_ <- match(D4_df$UaName, rownames(UaD4_df))
Test_df <- data.frame(
  LogD4PerSqMi = log(D4_df$D4PerSqMi),
  LogUaSvcAveD4PerRevMiPerSqMi = log(UaD4_df$UaSvcAveD4PerRevMiPerSqMi[UaToBg_]),
  LogUaRevMiPerSvcSqMi = log(UaD4_df$UaRevMiPerSvcSqMi[UaToBg_]),
  LogUaSvcAveD4PerSqMi = log(UaD4_df$UaSvcAveD4PerSqMi[UaToBg_]),
  Is0D4 = as.numeric(Is0D4),
  PropActSvc = UaD4_df$UaPropActSvc[UaToBg_],
  LogD1 = log(D4_df$D1),
  PowD3 = D4_df$D3 ^ D3Pow,
  LogD5 = log(D4_df$D5),
  D2Grp = D4_df$D2Grp
)
#Specify and estimate the model
Test_LM <- lm(LogD4PerSqMi ~
                LogUaSvcAveD4PerRevMiPerSqMi +
                LogUaRevMiPerSvcSqMi +
                LogUaSvcAveD4PerSqMi +
                LogD1 +
                PowD3 +
                LogD5 + 
                LogD5:LogD1 +
                D2Grp,
              data = Test_df[!Is0D4,])
png("d4_lm_plots.png", width = 600, height = 600)
plot(Test_LM)
dev.off()
sink("data/d4_lm_summary.txt")
summary(Test_LM)
sink()
#cor(Test_df[, 2:7])

#Model to predict probability that D4c is zero
#---------------------------------------------
Test_GLM <- glm(Is0D4 ~
                  PropActSvc +
                  LogUaRevMiPerSvcSqMi +
                  LogD1 +
                  PowD3 +
                  LogD5 + 
                  LogD5:LogD1,
                family = binomial,
                data = Test_df)
sink("data/d4_glm_summary.txt")
summary(Test_GLM)
sink()

#Test Model
#----------
NObs <- nrow(Test_df)
Est_ <- runif(NObs) < Test_GLM$fitted.values
Comp_df <- data.frame(
  Obs = Test_df$Is0D4,
  Est = as.numeric(Est_),
  UaName = D4_df$UaName,
  State = D4_df$State
)
table(Comp_df$Obs)
table(Comp_df$Est)
with(Comp_df, table(Obs, Est))
PropIs0D4_Ua2 <- 
  do.call(rbind, lapply(split(Comp_df, Comp_df$UaName), function(x) {
    c(
      Obs = sum(x$Obs) / length(x$Obs),
      Est = sum(x$Est) / length(x$Est)
    )
  })) 
with(data.frame(PropIs0D4_Ua2), plot(Obs, Est))
abline(0, 1, lty = 2)
UaProp0_LM <- lm(Est ~ Obs, data = data.frame(PropIs0D4_Ua2))
abline(UaProp0_LM)



#Test Model
#----------
#Predict values
predictD4 <- function(D4_LM, D4_GLM, NewData_df) {
  Est_ <- predict(D4_LM, newdata = NewData_df)
  Prob_ <- predict(D4_GLM, type = "response", newdata = NewData_df)
  IsNot0D4_ <- runif(length(Prob_)) > Prob_
  Est_ *  as.numeric(IsNot0D4_)
}
obsD4 <- function(Obs_) {
  Obs_[is.infinite(Obs_)] <- 0
  Obs_
}
Comp_df <- data.frame(
  Obs = obsD4(Test_df$LogD4PerSqMi),
  Est = predictD4(Test_LM, Test_GLM, Test_df),
  UaName = D4_df$UaName,
  State = D4_df$State
)
sink("data/compare_D4_lm_stats.txt")
cat("Observed (SLD) Values for LogD4SqMi\n")
summary(Comp_df$Obs)
cat("\n")
cat("Modeled Values for LogD4SqMi\n")
summary(Comp_df$Est)
sink()
#Scatterplot of observed and estimated values
png("data/D4_obs-vs-est_scatterplot.png", width = 480, height = 480)
plot(Comp_df$Obs, Comp_df$Est, xlab = "Observed LogD4SqMi",
     ylab = "Modeled LogD4SqMi")
abline(0, 1, col = "red")
dev.off()
#Compare urbanized area mean values
CompMeans_Ua2 <- 
  do.call(rbind, lapply(split(Comp_df, Comp_df$UaName), function(x) {
    c(Obs = mean(x$Obs), Est = mean(x$Est))}))
png("data/est-vs-obs-d4_ua-means.png", width = 480, height = 480)
with(data.frame(CompMeans_Ua2), 
     plot(Obs, Est, xlab = "Observed", ylab = "Modeled",
          main = "Urbanized Area Average LogD4SqMi",
          pch = 20, col = "darkgrey", cex = 1.5)
     )
abline(0, 1, lty = 2)
AveD4_LM <- lm(Est ~ Obs, data = data.frame(CompMeans_Ua2))
abline(AveD4_LM)
legend("bottomright", lty = c(1, 3), bty = "n",
       legend = c("Modeled ~ Observed", "1:1 slope"))
dev.off()
rm(CompMeans_Ua2)
#Compare overall distributions
png("data/est-vs-obs_dists_all-ua.png", width = 480, height = 480)
plot(density(Comp_df$Est),
     main = paste0("Probability Distributions of Modeled and Observed LogD4SqMi",
                   "\nFor all Urbanized Area Block Groups"))
lines(density(Comp_df$Obs), lty = 2)
legend("topleft", lty = c(1, 2), bty = "n", legend = c("Modeled", "Observed"))
dev.off()
#Function to plot comparative distributions for up to 9 urbanized areas
multiDistCompare <- 
  function(UaToPlot_, Obs_Ua, Est_Ua, UaNames_Ua, Title = "") {
    Opar_ls <- par(mfrow = c(3,3), oma = c(0,0,3,0))
    for (nm in UaToPlot_) {
      IsUa <- UaNames_Ua == nm
      plot(density(Est_Ua[IsUa]), xlab = "log(D4c / SqMi)",
           main = nm)
      lines(density(Obs_Ua[IsUa]), lty = 2)
      lines(density(Est_Ua[IsUa]))
    }
    mtext(text = Title, side = 3, outer = TRUE)
    par(Opar_ls)
  }
#Compare distributions for selection of medium urbanized areas
png("data/est-vs-obs_dists_med-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Bakersfield, CA",
    "Durham, NC",
    "Eugene, OR",
    "Madison, WI",
    "Medford, OR",
    "New Haven, CT",
    "Olympia-Lacey, WA",
    "Salem, OR",
    "Spokane, WA"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                "For Section of Medium Metropolitan Areas")
)
dev.off()
#Compare distributions for selection of medium-large urbanized areas  
png("data/est-vs-obs_dists_med-lrg-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Albuquerque, NM",
    "Birmingham, AL",
    "Bridgeport-Stamford, CT-NY",
    "Buffalo, NY",
    "Nashville-Davidson, TN",
    "Providence, RI-MA",
    "Raleigh, NC",
    "Rochester, NY",
    "Salt Lake City-West Valley City, UT"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Medium-Large Metropolitan Areas")
)
dev.off()
#Compare distributions for selection of large metropolitan areas
png("data/est-vs-obs_dists_lrg-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Atlanta, GA",
    "Baltimore, MD",
    "Boston, MA-NH-RI",
    "Cincinnati, OH-KY-IN",
    "Dallas-Fort Worth-Arlington, TX",
    "Denver-Aurora, CO",
    "Portland, OR-WA",
    "Sacramento, CA",
    "Seattle, WA"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Large Metropolitan Areas")
)
dev.off()
#Compare distributions for selection of very large metropolitan areas
png("data/est-vs-obs_dists_vry-lrg-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Philadelphia, PA-NJ-DE-MD",
    "Chicago, IL-IN",
    "Los Angeles-Long Beach-Anaheim, CA",
    "New York-Newark, NY-NJ-CT"   
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Very Large Metropolitan Areas")
)
dev.off()
#Compare distributions for first selection of states
png("data/est-vs-obs_dists_state1.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "CA",
    "CO",
    "FL",
    "GA",
    "IL",
    "IN",
    "KY",
    "MA",
    "MD"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$State,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of States")
)
dev.off()
#Compare distributions for 2nd selection of states
png("data/est-vs-obs_dists_state2.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "MI",
    "MN",
    "MO",
    "NJ",
    "NV",
    "NY",
    "OH",
    "OR",
    "PA"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$State,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of States")
)
dev.off()
#Compare distributions for 3rd selections of states
png("data/est-vs-obs_dists_state3.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "TX",
    "VA",
    "WA",
    "WI"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$State,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of States")
)
dev.off()

#Model to predict probability that D4c is zero
#---------------------------------------------
D4_df$LogPeakRevMiSqMi <- log(D4_df$PeakRevMiSqMi)
D3Pow <- findPower(D4_df$D3[D4_df$D3 != 0])
UaToBg_ <- match(D4_df$UaName, rownames(UaD4_df))

Test_df <- data.frame(
  Is0D4 = as.numeric(Is0D4),
  PropActSvc = UaD4_df$UaPropActSvc[UaToBg_],
  LogUaRevMiPerSvcSqMi = log(UaD4_df$UaRevMiPerSvcSqMi[UaToBg_]),
  LogD1 = log(D4_df$D1),
  PowD3 = D4_df$D3 ^ D3Pow,
  LogD5 = log(D4_df$D5),
  D2Grp = D4_df$D2Grp
)

Test_GLM <- glm(Is0D4 ~
                PropActSvc +
                LogUaRevMiPerSvcSqMi +
                LogD1 +
                PowD3 +
                LogD5 + 
                LogD5:LogD1,
               family = binomial,
              data = Test_df)
summary(Test_GLM)

#Test Model
#----------
NObs <- nrow(Test_df)
Est_ <- runif(NObs) < Test_GLM$fitted.values
Comp_df <- data.frame(
  Obs = Test_df$Is0D4,
  Est = as.numeric(Est_),
  UaName = D4_df$UaName,
  State = D4_df$State
)
table(Comp_df$Obs)
table(Comp_df$Est)
with(Comp_df, table(Obs, Est))
PropIs0D4_Ua2 <- 
  do.call(rbind, lapply(split(Comp_df, Comp_df$UaName), function(x) {
    c(
      Obs = sum(x$Obs) / length(x$Obs),
      Est = sum(x$Est) / length(x$Est)
    )
  })) 
with(data.frame(PropIs0D4_Ua2), plot(Obs, Est))
abline(0, 1, lty = 2)
UaProp0_LM <- lm(Est ~ Obs, data = data.frame(PropIs0D4_Ua2))
abline(UaProp0_LM)

#=================
#SIMBZONE CREATION
#=================

#Make a list containing all of the estimated distributions
#---------------------------------------------------------
Ds_ls <- list(
  D1DGrp_ls =  D1DGrp_ls,
  D1DGrp_Ua_ls = D1DGrp_Ua_ls,
  ActProp_Ua_D2 = ActProp_Ua_D2,
  ActProp_Ua_D5 = ActProp_Ua_D5,
  D2ActProp_D1D2 = D2ActProp_D1D2,
  D2ActProp_Ua_D1D2 = D2ActProp_Ua_D1D2,
  EmpProp_D2_ls = EmpProp_D2_ls,
  D5ActProp_D1D5 = D5ActProp_D1D5,
  D5ActProp_Ua_D1D5 = D5ActProp_Ua_D1D5,
  D5Ave_D5 = D5Ave_D5,
  D5Ave_Ua_D5 = D5Ave_Ua_D5
)

saveRDS(Ds_ls, file = "Ds_ls.rds")

#Define function to create Bzones
#--------------------------------
createUbzBzones <- 
  function(TotHHs_Az, TotJobs_Az, ActDen_Az, UzaName, ActPerBzone = 750) {
    set.seed(1)
    Az <- names(TotHHs_Az)
    #----------------------------------------
    #Create zones to accommodate all activity
    #----------------------------------------
    TotAct_Az <- TotHHs_Az + TotJobs_Az
    SimBzone_Az_df <- lapply(TotAct_Az, function(x) {
      NumZones <- round(x / ActPerBzone)
      RemAct <- x - NumZones * ActPerBzone
      BzName_Bz <- paste0("B", 1:NumZones)
      BzAct_Bz <- rep(ActPerBzone, NumZones)
      if (RemAct != 0) {
        RemAllocation_tb <- table(sample(1:NumZones, abs(RemAct), replace = TRUE))
        Idx_ <- as.numeric(names(RemAllocation_tb))
        Vals_ <- as.vector(RemAllocation_tb)
        BzAct_Bz[Idx_] <- BzAct_Bz[Idx_] + Vals_ * sign(RemAct)
      }
      data.frame(
        Bzone = BzName_Bz,
        Activity = BzAct_Bz
      )
    })
    #Add Azone name onto front of Bzone name
    for (az in Az) {
      SimBzone_Az_df[[az]]$Bzone <- paste0(az, SimBzone_Az_df[[az]]$Bzone)
    }
    #--------------------------------
    #Assign density levels and values
    #--------------------------------
    #Calculate density distributions by Azone
    ActDen_Az_df <- lapply(ActDen_Az, function(x) {
      ActDen_df <- adjDenDist(
        UzaAveDensity_ = Ds_ls$D1DGrp_Ua_ls[[UzaName]]$AveDensity,
        DenDist_ = Ds_ls$D1DGrp_Ua_ls[[UzaName]]$PropActivity,
        Target = x,
        AveDensity_ = Ds_ls$D1DGrp_ls$AveDensity
      )
    })
    #Assign density level and average density to zones
    for (az in Az) {
      D1Grp_Bz <- sample(1:20, nrow(SimBzone_Az_df[[az]]), replace = TRUE,
                         ActDen_Az_df[[az]]$ActProp)
      ActDen_Bz <- ActDen_Az_df[[az]]$AveDensity[D1Grp_Bz]
      #Adjust density to meet target
      Activity_Bz <- SimBzone_Az_df[[az]]$Activity
      AveDensity <- sum(Activity_Bz) / sum(Activity_Bz * 1 / ActDen_Bz)
      ActDen_Bz <- ActDen_Bz * ActDen_Az[az] / AveDensity
      SimBzone_Az_df[[az]]$D1Grp <- D1Grp_Bz
      SimBzone_Az_df[[az]]$D1D <- ActDen_Bz
      rm(D1Grp_Bz, ActDen_Bz, Activity_Bz, AveDensity)
    }
    rm(ActDen_Az_df)
    #----------------------------------------------------------------------
    #Functions to assist diversity and destination accessibility assignment
    #----------------------------------------------------------------------
    #Define function to fill in missing activity proportions
    fillMissingUaActProp <- function(UaActProp_mx, ActProp_mx) {
      NaRows_ <- apply(UaActProp_mx, 1, function(x) all(is.na(x)))
      UaActProp_mx[NaRows_,] <- ActProp_mx[NaRows_,]
      UaActProp_mx[is.na(UaActProp_mx)] <- 0
      UaActProp_mx
    }
    #Define function to identify urbanized area size category
    idSizeCategory <- function(TotActivity) {
      SzBrk_ <- c(0, 5e4, 1e5, 5e5, 1e6, 5e6, 1e9)
      Sz <- c("small", "medium-small", "medium", "medium-large", "large", "very-large")
      as.character(cut(TotActivity, SzBrk_, labels = Sz, include.lowest = TRUE))
    }
    #--------------------------------------------------------
    #Assign diversity level and calculate households and jobs
    #--------------------------------------------------------
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
    #--------------------------------------
    #Assign Destination Accessibility Level
    #--------------------------------------
    #Calculate total urbanized activity and identify size group
    # TotAct <- sum(TotHHs_Az) + sum(TotJobs_Az) 
    # UaSizeGrp <- idSizeCategory(TotAct)
    #Create D5 activity proportions sampling matrix
    # D5ActProp_D1D5 <- 
    #   fillMissingUaActProp(
    #     Ds_ls$D5ActProp_Ua_D1D5[[UzaName]], Ds_ls$D5ActProp_Ua_D1D5[[UaSizeGrp]])
    D5ActProp_D1D5 <- 
      fillMissingUaActProp(
        Ds_ls$D5ActProp_Ua_D1D5[[UzaName]], Ds_ls$D5ActProp_D1D5)
    #Create vector of D5 averages by activity density level
    D5Ave_D5 <- Ds_ls$D5Ave_Ua_D5[[UzaName]]
    #D5SzGrpAve_D5 <- Ds_ls$D5Ave_Ua_D5[[UaSizeGrp]]
    #D5Ave_D5[is.nan(D5Ave_D5)] <- D5SzGrpAve_D5[is.nan(D5Ave_D5)]
    D5Ave_D5[is.nan(D5Ave_D5)] <- Ds_ls$D5Ave_D5[is.nan(D5Ave_D5)]
    #Fill in missing values as moving average
    D5Ave_D5[is.nan(D5Ave_D5)] <- 0
    D5MovAve_D5 <- 
      (c(D5Ave_D5[-1], max(D5Ave_D5)) + c(min(D5Ave_D5), D5Ave_D5[1:19])) / 2
    D5Ave_D5[D5Ave_D5 == 0] <- D5MovAve_D5[D5Ave_D5 == 0]
    #Iterate through Azones to assign destination accessibility
    for (az in Az) {
      SimBzone_df <- SimBzone_Az_df[[az]]
      #Assign D5Grp
      D5Grp_Bz <- sapply(SimBzone_df$D1Grp, function(x) {
        sample(1:ncol(D5ActProp_D1D5), 1, prob = D5ActProp_D1D5[x,])
      })
      SimBzone_Az_df[[az]]$D5Grp <- D5Grp_Bz
      #Assign D5 value
      D5_Bz <- D5Ave_D5[D5Grp_Bz]
      SimBzone_Az_df[[az]]$D5 <- D5_Bz
    }
    #------------------
    #Return the results
    #------------------
    SimBzone_Az_df
  }

#Define function to create test Azone inputs
#-------------------------------------------
#This function takes the data for an urbanized area and splits it at the county
#level considering counties to be Azones. It then produces each of the required
#inputs at the Azone level.
createAzoneTestData <- function(UzaName) {
  Uza_df <- Ua_df[Ua_df$UZA_NAME == UzaName,]
  Azone_Bg <- 
    paste0("A", sapply(Uza_df$GEOID10, function(x) substr(x, 1, 5)))
  TotJobs_Az <- tapply(Uza_df$EMPTOT, Azone_Bg, sum)
  TotHHs_Az <- tapply(Uza_df$HH, Azone_Bg, sum)
  TotAct_Az <- tapply(Uza_df$TOTACT, Azone_Bg, sum)
  TotAcLand_Az <- tapply(Uza_df$AC_LAND, Azone_Bg, sum)
  ActDen_Az <- TotAct_Az / TotAcLand_Az
  list(
    TotJobs_Az = TotJobs_Az,
    TotHHs_Az = TotHHs_Az,
    ActDen_Az = ActDen_Az
  )
}

#Define function to tabulate activity by group(s)
tabSimBzoneAct <- function(SimBzones_Az_df, VarNames, VarDimnames) {
  SimB_df <- do.call(rbind, SimBzones_Az_df)
  if (length(VarNames) == 1) {
    Act_ <- numeric(length(VarDimnames))
    names(Act_) <- VarDimnames
    TabAct_ <- tapply(SimB_df$Activity, SimB_df[[VarNames]], sum)
    Act_[names(TabAct_)] <- TabAct_
    Act_[is.na(Act_)] <- 0
    return(Act_)
  }
  if (length(VarNames) == 2) {
    Act_mx <- matrix(0, nrow = length(VarDimnames[[1]]), ncol = length(VarDimnames[[2]]))
    dimnames(Act_mx) <- VarDimnames
    TabAct_mx <- with(SimB_df, tapply(Activity, as.list(SimB_df[VarNames]), sum))
    Idx_mx <- as.matrix(expand.grid(rownames(TabAct_mx), colnames(TabAct_mx)))
    Act_mx[Idx_mx] <- as.vector(TabAct_mx)
    Act_mx[is.na(Act_mx)] <- 0
    return(Act_mx)
  }
  stop("Can't tabulate by more than 2 VarNames")
}

#Define function to summarize SimBzone activity
summarizeSimBzones <- function(SimBzones_Az_df) {
  D1Names <- as.character(1:20)
  D5Names <- as.character(1:20)
  D2Names <- 
    c("primarily-hh", "largely-hh", "mixed", "largely-job", "primarily-job")
  Act_D1 <- tabSimBzoneAct(SimBzones_Az_df, "D1Grp", D1Names)
  PropAct_D1 <- Act_D1 / sum(Act_D1)
  Act_D2 <- tabSimBzoneAct(SimBzones_Az_df, "D2Grp", D2Names)
  PropAct_D2 <- Act_D2 / sum(Act_D2)
  Act_D5 <- tabSimBzoneAct(SimBzones_Az_df, "D5Grp", D5Names)
  PropAct_D5 <- Act_D5 / sum(Act_D5)
  Act_D1D2 <- tabSimBzoneAct(SimBzones_Az_df, c("D1Grp", "D2Grp"), list(D1Names, D2Names))
  D2PropAct_D1D2 <- sweep(Act_D1D2, 1, rowSums(Act_D1D2), "/")
  D2PropAct_D1D2[is.na(D2PropAct_D1D2)] <- 0
  Act_D1D5 <- tabSimBzoneAct(SimBzones_Az_df, c("D1Grp", "D5Grp"), list(D1Names, D5Names))
  D5PropAct_D1D5 <- sweep(Act_D1D5, 1, rowSums(Act_D1D5), "/")
  D5PropAct_D1D5[is.na(D5PropAct_D1D5)] <- 0
  list(
    PropAct_D1 = PropAct_D1,
    PropAct_D2 = PropAct_D2,
    PropAct_D5 = PropAct_D5,
    PropAct_D1D2 = D2PropAct_D1D2,
    PropAct_D1D5 = D5PropAct_D1D5
  )
}

#Define function to collate observed urbanized area values
collateUbzSummaries <- function(Ds_ls, UaName) {
  PropAct_D1 <- Ds_ls$D1DGrp_Ua_ls[[UaName]]$PropActivity
  PropAct_D1[is.na(PropAct_D1)] <- 0
  PropAct_D2 <- Ds_ls$ActProp_Ua_D2[[UaName]]
  PropAct_D2[is.na(PropAct_D2)] <- 0
  PropAct_D5 <- Ds_ls$ActProp_Ua_D5[[UaName]]
  PropAct_D5[is.na(PropAct_D5)] <- 0
  PropAct_D1D2 <- D2ActProp_Ua_D1D2[[UaName]]
  PropAct_D1D2[is.na(PropAct_D1D2)] <- 0
  PropAct_D1D5 <- D5ActProp_Ua_D1D5[[UaName]]
  PropAct_D1D5[is.na(PropAct_D1D5)] <- 0
  list(
    PropAct_D1 = PropAct_D1,
    PropAct_D2 = PropAct_D2,
    PropAct_D5 = PropAct_D5,
    PropAct_D1D2 = PropAct_D1D2,
    PropAct_D1D5 = PropAct_D1D5
  )
}

#Comparison vector plot
vectorCompare <- function(Est_ls, Obs_ls, VectorName, ...) {
  Obs_ <- Obs_ls[[VectorName]]
  Est_ <- Est_ls[[VectorName]]
  Ylim_ <- range(c(Obs_, Est_))
  Xlab_ <- names(Obs_)
  Xvals_ <- 1:length(Xlab_)
  plot(Xvals_, Obs_, axes = FALSE, ylim = Ylim_, type = "p", 
       ylab = "Proportion of Urbanized Area Activity",
       ...)
  box()
  axis(2)
  axis(1, at = Xvals_, labels = Xlab_)
  lines(Xvals_, Obs_)
  points(Xvals_, Est_, col = "red")
  lines(Xvals_, Est_, col = "red")
  legend("topleft", legend = c("Observed", "Simulated"), lty = 1, col = c("black", "red"))
}

#Function to compare observed and estimated density, diversity, and destination accessibility proportions
compareObsEst1 <- function(Obs_ls, Est_ls, UaName) {
  Opar_ls <- par(mfrow = c(2,2), oma = c(0,0,3,0))
  vectorCompare(Est_ls, Obs_ls, "PropAct_D1", 
                xlab = "Density (D1D) Category",
                main = "Density")
  vectorCompare(Est_ls, Obs_ls, "PropAct_D2", 
                xlab = "Diversity (D2A_JPHH) Category",
                main = "Diversity")
  vectorCompare(Est_ls, Obs_ls, "PropAct_D5", 
                xlab = "Destination Accessibility (D5) Category",
                main = "Destination Accessibility")
  mtext(text = paste(UaName, "Comparison of Density, Diversity, and Destination Accessibility Activity Proportions"), 
        side = 3, outer = TRUE)
  par(Opar_ls)
}

#Function to compare joint distributions
compareObsEst2 <- function(Obs_ls, Est_ls, UaName) {
  Opar_ls <- par(mfrow = c(2,2), oma = c(0,0,3,0))
  Rng_ <- 
    range(c(as.vector(Obs_ls$PropAct_D1D2), as.vector(Est_ls$PropAct_D1D2)))
  DispPal_ <- colorRampPalette(c("black", "yellow"))(20)
  image2D(Obs_ls$PropAct_D1D2, 
          x = 1:20, y = 1:5,
          xlab = "D1D Group", ylab = "D2 Group",
          zlim = Rng_,
          col = DispPal_, NAcol = "black",
          main = paste("Observed Diversity Proportions\nBy Density group"),
          cex.main = 1)
  image2D(Est_ls$PropAct_D1D2, 
          x = 1:20, y = 1:5,
          xlab = "D1D Group", ylab = "D2 Group",
          zlim = Rng_,
          col = DispPal_, NAcol = "black",
          main = paste("Synthesized Diversity Proportions\nBy Density group"),
          cex.main = 1)
  Rng_ <- 
    range(c(as.vector(Obs_ls$PropAct_D1D5), as.vector(Est_ls$PropAct_D1D5)))
  DispPal_ <- colorRampPalette(c("black", "yellow"))(20)
  image2D(Obs_ls$PropAct_D1D5, 
          x = 1:20, y = 1:20,
          xlab = "D1D Group", ylab = "D5 Group",
          zlim = Rng_,
          col = DispPal_, NAcol = "black",
          main = paste("Observed Destination Accessibility Proportions\nBy Density group"),
          cex.main = 1)
  image2D(Est_ls$PropAct_D1D5, 
          x = 1:20, y = 1:20,
          xlab = "D1D Group", ylab = "D5 Group",
          zlim = Rng_,
          col = DispPal_, NAcol = "black",
          main = paste("Synthesized Destination Accessibility Proportions\nBy Density group"),
          cex.main = 1)
  mtext(text = paste(UaName, "Comparison of Diversity Proportions and Destination Accessibility Proportions by Density Group"), 
        side = 3, outer = TRUE)
  par(Opar_ls)
}

#Function to simulate for urbanized area and compare with observed values
simulateAndCompare <- function(UzaName) {
  UzaTestData_ls <- createAzoneTestData(UzaName)
  SimBzones_Az_df <- 
    createUbzBzones(
      TotHHs_Az = UzaTestData_ls$TotHHs_Az, 
      TotJobs_Az = UzaTestData_ls$TotJobs_Az, 
      ActDen_Az = UzaTestData_ls$ActDen_Az, 
      UzaName = UzaName, 
      ActPerBzone = 750)
  
  Est_ls <- summarizeSimBzones(SimBzones_Az_df)
  Obs_ls <- collateUbzSummaries(Ds_ls, UzaName)
  compareObsEst1(Obs_ls, Est_ls, UzaName)
  compareObsEst2(Obs_ls, Est_ls, UzaName)
}

#Simulate and compare several urbanized areas
simulateAndCompare("Atlanta, GA")
simulateAndCompare("Jacksonville, FL")
simulateAndCompare("Cincinnati, OH")
simulateAndCompare("Dallas--Fort Worth--Arlington, TX")
simulateAndCompare("Baltimore, MD")
simulateAndCompare("Denver--Aurora, CO")
simulateAndCompare("Portland, OR")
simulateAndCompare("San Francisco--Oakland, CA")
simulateAndCompare("New York--Newark, NY")


