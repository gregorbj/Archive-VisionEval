#==========================
#CalculateRoadPerformance.R
#==========================

#<doc>
#
## CalculateRoadPerformance Module
#### November 24, 2018
#
#This module splits light-duty vehicle (LDV) daily vehicle miles of travel DVHT between freeways and arterials as a function of relative speeds and congestion prices. Speeds and prices are combined to calculate an average 'effective' speed for freeways and for arterials. The ratio of freeway and arterial 'effective' speeds and a split factor calculated for the metropolitan area are used to split the LDV DVMT. Iteration is used to find an equilibrium split value. In addition to the LDV freeway DVMT and arterial DVMT, the following performance measures are saved to the datastore:
#
#* Average freeway speed by congestion level;
#
#* Average arterial speed by congestion level;
#
#* Average freeway delay by congestion level;
#
#* Average arterial delay by congestion level;
#
#* Freeway DVMT proportions by congestion level;
#
#* Arterial DVMT proportions by congestion level;
#
#* Average amount paid per mile in congestion pricing fees; and,
#
#* Vehicle hours of delay by vehicle type.
#
### Model Parameter Estimation
#
#Several models are estimated
#
#### Estimate Congestion Lookup Table
#
# Lookup tables are created that are used by the module to calculate the proportions of freeway and arterial daily vehicle miles of travel (DVMT) and daily vehicle hours of travel (DVHT) in each of 5 congestion levels (none, moderate, heavy, severe, extreme) as a function of freeway average daily traffic (ADT) per lane and arterial ADT per lane respectively. The lookup tables are created using the following Urban Mobility Study (UMS) data for 90 urbanized areas that are used in the calculations:
#
#* Average daily freeway vehicle miles traveled in thousands;
#
#* Average daily arterial vehicle miles traveled in thousands;
#
#* Freeway lane miles
#
#* Arterial lane miles
#
#* Percentages of freeway DVMT occurring in 5 congestion levels
#
#* Percentages of arterial DVMT occurring in 5 congestion levels
#
#* Average freeway speeds for travel at each of the 5 congestion levels
#
#* Average arterial speeds for travel at each of the 5 congestion levels
#
#The steps for creating the lookup tables are as follows:
#
#1. Freeway demand levels and arterial demand levels are calculated for each urbanized area by dividing the respective value of DVMT by the respective number of lane miles. The result is the average daily traffic volume per lane-mile.
#
#2. A lookup table relating the proportions of freeway DVMT by congestion level to freeway demand level is created through the calculation of weighted moving averages. Values are calculated for for freeway demand levels ranging from 6000 vehicles per lane to 24,000 vehicles per lane in 100 vehicle increments. For each demand level, the data for the 10 urbanized areas whose demand level is nearest the target demand level (5 below and 5 above are chosen). If there are less than 5 below the target then the sample includes all that are below and 5 above. Similarly if there are less then 5 above the sample target. The DVMT proportions for each congestion level are computed as a weighted average of the proportions in the sample where the weights measure how close the demand level of each sample urbanized area is to the target demand level. After weighted averages have been calculated for all freeway demand levels, smoothing splines (5 degrees of freedom) are used to smooth out the values for each congestion level over the range of demand levels.
#
#3. A lookup table relating the proportions of arterial DVMT by congestion level to arterial demand level is created by the same method used to create the freeway table.
#
#4. The proportions of freeway DVHT (daily vehicle hours of travel) by congestion level is computed for each urbanized area by dividing the freeway DVMT by congestion by the average speed by congestion level. The proportions of arterial DVHT by congestion level are computed in the same way.
#
#5. Freeway and arterial lookup tables for of the proportions of DVHT by congestion level by demand level are calculated in the same manner at the DVMT lookup tables.
#
#The following figures illustrate the 4 lookup tables:
#
#<fig:fwy_dvmt_cong_prop.png>
#
#<fig:art_dvmt_cong_prop.png>
#
#<fig:fwy_dvht_cong_prop.png>
#
#<fig:art_dvht_cong_prop.png>
#
#### Urbanized Area Base Speeds and Operational Adjustments
#
#Based on research by Bigazzi and Clifton. The speeds modeled above include the
#effects of ITS/operations strategies that are in place in urban areas. In order
#to calculate the effects of operations at various levels, base speed estimates
#which are not influenced by operations improvements need to be used as the
#starting point. Bigazzi and Clifton made the calculations and these are
#included in the data directory. Speeds are reduced based on assumed deployment
#levels relative to average levels, estimated maximum reductions possible by
#congestion category, facility type, congestion type (recurring vs. incident),
#and assumed deployment relative to the average for a metropolitan area of the
#size.

#
#
### How the Module Works
#
#
#</doc>



#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
#library(visioneval)


#==========================================
#SECTION 1A: LOAD URBAN MOBILITY STUDY DATA
#==========================================
#Specify Estimation Data
#-----------------------
UmsInp_ls <- items(
  item(
    NAME = "Area",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("FwyDvmt000",
            "ArtDvmt000"),
    TYPE = "double",
    PROHIBIT = c("<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("FwyLnMi",
            "ArtLnMi"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("FwyVmtModPct",
            "FwyVmtHvyPct",
            "FwyVmtSevPct",
            "FwyVmtExtPct",
            "ArtVmtModPct",
            "ArtVmtHvyPct",
            "ArtVmtSevPct",
            "ArtVmtExtPct"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("FwyAveModSpd",
            "FwyAveHvySpd",
            "FwyAveSevSpd",
            "FwyAveExtSpd",
            "ArtAveModSpd",
            "ArtAveHvySpd",
            "ArtAveSevSpd",
            "ArtAveExtSpd"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Pop000",
            "SqMi"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in Urban Mobility Study datasets
#-------------------------------------
Ums_df <-
  processEstimationInputs(
    UmsInp_ls,
    "ums_2009.csv",
    "CalculateRoadPerformance.R")
rm(UmsInp_ls)

#===================================================================
#SECTION 1B: ESTIMATE AND SAVE CONGESTION LOOKUP TABLES AND FUNCTION
#===================================================================
# Lookup tables are created that are used by the module to calculated the
# proportions of freeway and arterial daily vehicle miles of travel (DVMT) and
# daily vehicle hours of travel (DVHT) in each of 5 congestion levels (none,
# moderate, heavy, severe, extreme) as a function of freeway average daily
# traffic (ADT) per lane and arterial ADT per lane respectively.
# The lookup tables are created using the following Urban Mobility Study (UMS)
# data for 90 urbanized areas that are used in the calculations:
# 1) Average daily freeway vehicle miles traveled in thousands
# 2) Average daily arterial vehicle miles traveled in thousands
# 3) Freeway lane miles
# 4) Arterial lane miles
# 5) Percentages of freeway DVMT occurring in 5 congestion levels
# 6) Percentages of arterial DVMT occurring in 5 congestion levels
# 7) Average freeway speeds for travel at each of the 5 congestion levels
# 8) Average arterial speeds for travel at each of the 5 congestion levels

#Define function to estimate congestion model
#--------------------------------------------
estimateCongestionModel <- function() {
  # Calculate urbanized area freeway and arterial demand levels
  #------------------------------------------------------------
  # Demand levels are calculated as the ratio of DVMT to lane-miles. The units are
  # average daily traffic (ADT) per lane
  FwyDvmt_ <- 1000 * Ums_df$FwyDvmt000
  FwyDemandLvl_ <- FwyDvmt_ / Ums_df$FwyLnMi
  ArtDvmt_ <- 1000 * Ums_df$ArtDvmt000
  ArtDemandLvl_ <- ArtDvmt_ / Ums_df$ArtLnMi

  # Calculate percentages of freeway and arterial DVMT by congestion level
  #-----------------------------------------------------------------------
  # UMS data includes the percentages of freeway and arterial DVMT occurring at
  # each of the congestion levels. These are extracted into data frames.

  # Freeway DVMT proportions by congestion level and metropolitan area
  FwyCongVmtPct_df <-
    Ums_df[, c("FwyVmtModPct", "FwyVmtHvyPct", "FwyVmtSevPct", "FwyVmtExtPct")]
  names(FwyCongVmtPct_df) <- c("Mod", "Hvy", "Sev", "Ext")
  FwyCongVmtPct_df <-
    cbind(None = 100 - rowSums(FwyCongVmtPct_df), FwyCongVmtPct_df)
  FwyCongVmtProp_df <- FwyCongVmtPct_df / 100
  rm(FwyCongVmtPct_df)

  # Proportions of arterial DVMT by congestion level and metropolitan area
  ArtCongVmtPct_df <-
    Ums_df[, c("ArtVmtModPct", "ArtVmtHvyPct", "ArtVmtSevPct", "ArtVmtExtPct")]
  names(ArtCongVmtPct_df) <- c("Mod", "Hvy", "Sev", "Ext")
  ArtCongVmtPct_df <-
    cbind(None = 100 - rowSums(ArtCongVmtPct_df), ArtCongVmtPct_df)
  ArtCongVmtProp_df <- ArtCongVmtPct_df / 100

  # Calculate percentages of freeway and arterial DVHT by congestion level
  #-----------------------------------------------------------------------
  # Urbanized area DVHT by congestion level is calculated from the percentages of
  # DVMT by congestion level, total DVMT, and average speeds by congestion level.

  # Freeway DVMT by congestion level and metropolitan area
  FwyCongVmt_df <- sweep(FwyCongVmtProp_df, 1, FwyDvmt_, "*")
  # Average freeway speeds by congestion level and metropolitan area
  AveFwySpds_df <-
    Ums_df[, c("FwyAveModSpd", "FwyAveHvySpd", "FwyAveSevSpd", "FwyAveExtSpd")]
  names(AveFwySpds_df) <- c("Mod", "Hvy", "Sev", "Ext")
  AveFwySpds_df <- cbind(None = 60, AveFwySpds_df)
  # Freeway DVHT by congestion level and metropolitan area
  FwyCongVht_df <- FwyCongVmt_df / AveFwySpds_df
  # Proportions of freeway DVHT by congestion level for each metropolitan area
  FwyCongVhtProp_df <-
    data.frame(t(apply(FwyCongVht_df, 1, function(x) x/sum(x))))
  # Clean up
  rm(FwyCongVmt_df, AveFwySpds_df, FwyCongVht_df)

  # Arterial DVMT by congestion level and metropolitan area
  ArtCongVmt_df <- sweep(ArtCongVmtProp_df, 1, ArtDvmt_, "*")
  # Average arterial speeds by congestion level and metropolitan area
  AveArtSpds_df <-
    Ums_df[, c("ArtAveModSpd", "ArtAveHvySpd", "ArtAveSevSpd", "ArtAveExtSpd")]
  names(AveArtSpds_df) <- c("Mod", "Hvy", "Sev", "Ext")
  AveArtSpds_df <- cbind(None=30, AveArtSpds_df)
  # Arterial DVHT by congestion level and metropolitan area
  ArtCongVht_df <- ArtCongVmt_df / AveArtSpds_df
  # Proportions of arterial DVHT by congestion level for each metropolitan area
  ArtCongVhtProp_df <-
    data.frame(t(apply(ArtCongVht_df, 1, function(x) x/sum(x))))

  # Define function to calculate a lookup table of congestion proportions
  #----------------------------------------------------------------------
  createLookupTable <- function(MetroDmdLvls_, MetroProps_df, DmdLvlRng_) {
    #Set up
    #------
    # Define the series of demand levels to calculate values for
    Lvls_ <- seq(DmdLvlRng_[1], DmdLvlRng_[2], by = 100)
    # Name MetroDmdLvls_ with their positions so that information is preserved
    names(MetroDmdLvls_) <- 1:length(MetroDmdLvls_)

    #Define function to choose the metropolitan area sample
    #------------------------------------------------------
    idSample <- function(Lvl) {
      # Sort the DmdLvls_
      DmdLvls_ <- sort(MetroDmdLvls_)
      # Find the closest Lvl in DmdLvls_ to the input Lvl
      if(Lvl < min(DmdLvls_)) {
        IdxLvl <- min(DmdLvls_)
      } else { if(Lvl > max(DmdLvls_)) {
        IdxLvl <- max(DmdLvls_)
      } else {
        IdxLvl <-
          DmdLvls_[which(abs(DmdLvls_ - Lvl) == min(abs(DmdLvls_ - Lvl)))]
      }
      }
      # Find a range of Lvls around the IdxLvl to make a sample
      # 5 above and 5 below unless closer to beginning or end of DmdLvls_ vector
      LvlIndex <- which(DmdLvls_ == IdxLvl)
      if(LvlIndex >= 6 & ((length(DmdLvls_) - LvlIndex) >= 6)) {
        Sample_ <- DmdLvls_[(LvlIndex - 5):(LvlIndex + 5)]
      }
      if(LvlIndex < 6) {
        Sample_ <- DmdLvls_[1:(LvlIndex + 5)]
      }
      if((length(DmdLvls_) - LvlIndex) < 6) {
        Sample_ <- DmdLvls_[(LvlIndex - 5):(length(DmdLvls_))]
      }
      # Calculate sample weights based on proportional deviance from input Lvl
      Weights_ <- 1 - abs(Sample_ - Lvl) / Lvl
      # Create a list identifying which of the original Lvls are in the sample
      # and what their respective weights are
      Weights_
    }

    #Calculate the weighted averages for each demand level in the range
    #------------------------------------------------------------------
    AveVals_ls <- list()
    for(Lvl in Lvls_) {
      Weights_ <- idSample(Lvl)
      MetroSample_df <- MetroProps_df[as.numeric(names(Weights_)), ]
      AveVals_ls[[as.character(Lvl)]] <-
        unlist(
          lapply(MetroSample_df, function(x) {
            weighted.mean(x, Weights_)}
          )
        )
      rm(Weights_, MetroSample_df)
    }
    AveVals_df <- data.frame(do.call(rbind, AveVals_ls))

    #Smooth out the results for each congestion level using spline smoothing
    #-----------------------------------------------------------------------
    SmoothAveVals_mx <- apply(AveVals_df, 2, function(x) {
      Smooth_ <- smooth.spline(Lvls_, x, df=5)
      predict(Smooth_ )$y } )
    rownames(SmoothAveVals_mx) <- Lvls_
    SmoothAveVals_mx
  }

  #Calculate freeway and arterial congested DVMT and DVHT tables
  #-------------------------------------------------------------
  list(
    DVMT = list(
      Fwy = createLookupTable(FwyDemandLvl_, FwyCongVmtProp_df, c(6000, 24000)),
      Art = createLookupTable(ArtDemandLvl_, ArtCongVmtProp_df, c(2000, 9000))
    ),
    DVHT = list(
      Fwy = createLookupTable(FwyDemandLvl_, FwyCongVhtProp_df, c(6000, 24000)),
      Art = createLookupTable(ArtDemandLvl_, ArtCongVhtProp_df, c(2000, 9000))
    )
  )
}

#Estimate the congestion model (lookup tables)
#---------------------------------------------
#Create proportions table
CongestedProportions_ls <- estimateCongestionModel()
#Document the DVMT proportions by congestion level for freeways
png("data/fwy_dvmt_cong_prop.png", height = 360, width = 480)
Props_mx <- CongestedProportions_ls$DVMT$Fwy
matplot(as.numeric(rownames(Props_mx)), Props_mx, type = "l",
        xlab = "Average Daily Traffic Per Lane", ylab = "Proportion of DVMT",
        main = "Freeway DVMT Split by Congestion Level")
legend("topright", lty = 1:5, col = 1:5, legend = colnames(Props_mx), bty = "n")
dev.off()
#Document the DVMT proportions by congestion level for arterials
png("data/art_dvmt_cong_prop.png", height = 360, width = 480)
Props_mx <- CongestedProportions_ls$DVMT$Art
matplot(as.numeric(rownames(Props_mx)), Props_mx, type = "l",
        xlab = "Average Daily Traffic Per Lane", ylab = "Proportion of DVMT",
        main = "Arterial DVMT Split by Congestion Level")
legend("topright", lty = 1:5, col = 1:5, legend = colnames(Props_mx), bty = "n")
dev.off()
#Document the DVHT proportions by congestion level for freeways
png("data/fwy_dvht_cong_prop.png", height = 360, width = 480)
Props_mx <- CongestedProportions_ls$DVHT$Fwy
matplot(as.numeric(rownames(Props_mx)), Props_mx, type = "l",
        xlab = "Average Daily Traffic Per Lane", ylab = "Proportion of DVHT",
        main = "Freeway DVHT Split by Congestion Level")
legend("topright", lty = 1:5, col = 1:5, legend = colnames(Props_mx), bty = "n")
dev.off()
#Document the DVHT proportions by congestion level for arterials
png("data/art_dvht_cong_prop.png", height = 360, width = 480)
Props_mx <- CongestedProportions_ls$DVHT$Art
matplot(as.numeric(rownames(Props_mx)), Props_mx, type = "l",
        xlab = "Average Daily Traffic Per Lane", ylab = "Proportion of DVHT",
        main = "Arterial DVHT Split by Congestion Level")
legend("topright", lty = 1:5, col = 1:5, legend = colnames(Props_mx), bty = "n")
dev.off()

rm(estimateCongestionModel)

#Save the congestion lookup tables
#---------------------------------
#' Congestion lookup tables of proportions of VMT and VHT by congestion level
#' for freeways and arterials by demand level (average ADT per lane)
#'
#' Bus revenue mile equivalency factors to convert revenue miles for various
#' modes to bus-equivalent revenue miles.
#'
#' @format A list of matrices. The list has two components, Vmt and Vht, that
#' contain lookup tables for VMT and VHT proportions by congestion level,
#' respectively. Each component has two components, Fwy and Art, that contains
#' the lookup tables for freeways and arterials respectively. Each table is a
#' matrix containing 5 columns corresponding the 5 congestion levels (none,
#' moderate, heavy, severe, extreme). The rows correspond to demand levels with
#' the rownames specifying the demand levels. The values are proportions by
#' congestion level. The values in each row sum to 1.
#'
#' @source CalculateCongestion.R script.
"CongestedProportions_ls"
usethis::use_data(CongestedProportions_ls, overwrite = TRUE)


#---------------------------------------------------------
#Function that calculates DVMT or DVHT by congestion level
#---------------------------------------------------------
#' Calculate DVMT or DVHT by congestion level.
#'
#' \code{CalculateCongestion} splits input DVMT or DVHT into the amounts in
#' each of 5 congestion levels:none, moderate, heavy, severe, and extreme.
#'
#' This function splits input DVMT or DVHT into amounts by congestion level
#' (none, moderate, heavy, severe, and extreme) as a function of the ratio of
#' DVMT to lane-miles. The lookup tables in CongestedProportions_ls are used
#' to lookup proportions by congestion level. The input DVMT or DVHT are
#' split with these proportions and the split values are returned.
#'
#' @param MeasureType a string having the value 'DVMT' or 'DVHT' depending on
#' whether daily vehicle miles of travel (DVMT) or daily vehicle hours of travel
#' is to be split into congestion levels.
#' @param RoadType a string having the value 'Fwy' or 'Art' depending on whether
#' congestion is to be calculated for freeways (Fwy) or arterial roadways (Art).
#' @param LaneMi a number identifying the number of lane-miles for the roadway
#' type.
#' @param DVMT a number identifying the daily vehicle miles of travel on the
#' roadway type.
#' @param DVHT a number identifying the daily vehicle hours of travel on the
#' roadway type. Note that a value is required for this argument only if the
#' MeasureType is 'DVHT'.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name calculateCongestion
#' @import visioneval
#' @export
calculateCongestion <-
  function(MeasureType, RoadType, LaneMi, DVMT, DVHT = NULL) {
    #Check that DVHT value is provided if MeasureType is DVHT
    if (MeasureType == "DVHT" & is.null(DVHT)) {
      stop("MeasureType is 'DVHT' but the values of DVHT is NULL.")
    }
    #Extract the lookup table
    Lookup_LvCl <-
      CongestedProportions_ls[[MeasureType]][[RoadType]]
    #Calculate roadway demand
    Demand <- DVMT / LaneMi
    #Constrain the lookup to the table range
    Demand_ <- as.numeric(rownames(Lookup_LvCl))
    if (Demand < min(Demand_)) Demand <- min(Demand_)
    if (Demand > max(Demand_)) Demand <- max(Demand_)
    #Extract the values
    CongProps_ <- apply(Lookup_LvCl, 2, function(x) {
      approx(Demand_, x, Demand)$y
    })
    #Make sure values add exactly to 1
    CongProps_ <- CongProps_ / sum(CongProps_)
    #Split DVMT or DVHT into congested components
    if (MeasureType == "DVMT") {
      DVMT * CongProps_
    } else {
      DVHT * CongProps_
    }
  }


#========================================================================
#SECTION 1C: ESTIMATE AND SAVE METROPOLITAN SPEED PARAMETERS AND FUNCTION
#========================================================================
#Based on research by Bigazzi and Clifton. The speeds modeled above include the
#effects of ITS/operations strategies that are in place in urban areas. In order
#to calculate the effects of operations at various levels, base speed estimates
#which are not influenced by operations improvements need to be used as the
#starting point. Bigazzi and Clifton made the calculations and these are
#included in the data directory. Speeds are reduced based on assumed deployment
#levels relative to average levels, estimated maximum reductions possible by
#congestion category, facility type, congestion type (recurring vs. incident),
#and assumed deployment relative to the average for a metropolitan area of the
#size.

#----------------------------------------------------------
#Load and base speeds (assuming no operations improvements)
#----------------------------------------------------------
BaseSpeedInp_ls <- items(
  item(
    NAME = "Level",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Fwy",
            "Art",
            "Fwy_Rcr",
            "Art_Rcr"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
BaseSpeeds_df <-   processEstimationInputs(
  BaseSpeedInp_ls,
  "base_speeds.csv",
  "CalculateSpeeds.R")
row.names(BaseSpeeds_df) <- BaseSpeeds_df$Level
BaseSpeeds_df <- BaseSpeeds_df[,-1]
rm(BaseSpeedInp_ls)

#' Base arterial and freeway speeds by congestion level
#'
#' Base speeds on freeways and arterials by congestion level
#'
#' @format A data frame with 5 rows and 4 columns. Row names are congestion
#' level names(None, Mod, Hvy, Sev, Ext):
#' \describe{
#'   \item{Fwy}{average freeway speed in miles per hours by congestion level
#'   considering the effects of recurring and incident-related congestion}
#'   \item{Art}{average arterial speed in miles per hours by congestion level
#'   considering the effects of recurring and incident-related congestion}
#'   \item{Fwy_Rcr}{average freeway speed in miles per hours by congestion level
#'   considering only the effects of recurring congestion}
#'   \item{Art_Rcr}{average arterial speed in miles per hours by congestion
#'   level considering the effects of recurring and incident-related congestion}
#'   }
#' @source CalculateSpeeds.R script.
"BaseSpeeds_df"
usethis::use_data(BaseSpeeds_df, overwrite = TRUE)


#----------------------------------------------------
#Calculate and save recurring and non-recurring delay
#----------------------------------------------------
BaseTravelRate_mx <- 1 / as.matrix(BaseSpeeds_df)
Delay_mx <- sweep(BaseTravelRate_mx, 2, BaseTravelRate_mx[1,], "-")
Delay_df <- data.frame(
  Fwy_Rcr = Delay_mx[,"Fwy_Rcr"],
  Fwy_NonRcr = Delay_mx[,"Fwy"] - Delay_mx[,"Fwy_Rcr"],
  Art_Rcr = Delay_mx[,"Art_Rcr"],
  Art_NonRcr = Delay_mx[,"Art"] - Delay_mx[,"Art_Rcr"]
)
rm(BaseTravelRate_mx, Delay_mx)

#' Freeway and arterial recurring and non-recurring delay by congestion level
#'
#' Freeway and arterial recurring and non-recurring delay by congestion level
#'
#' @format A data frame with 5 rows and 4 columns. Row names are congestion
#' level names(None, Mod, Hvy, Sev, Ext):
#' \describe{
#'   \item{Fwy_Rcr}{freeway recurring delay in hours per mile by congestion
#'   level}
#'   \item{Fwy_NonRcr}{freeway non-recurring (incident) delay in hours per mile
#'   by congestion level}
#'   \item{Art_Rcr}{arterial recurring delay in hours per mile by congestion
#'   level}
#'   \item{Art_NonRcr}{arterial non-recurring (incident) delay in hours per mile
#'   by congestion level}
#'   }
#' @source CalculateSpeeds.R script.
"Delay_df"
usethis::use_data(Delay_df, overwrite = TRUE)


#-------------------------------------------
#Load and save ramp metering delay reduction
#-------------------------------------------
RampMeteringInp_ls <- items(
  item(
    NAME = "Level",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Fwy_Rcr",
            "Fwy_NonRcr",
            "Art_Rcr",
            "Art_NonRcr"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
Ramp_df <-   processEstimationInputs(
  RampMeteringInp_ls,
  "ramp_metering.csv",
  "CalculateSpeeds.R")
row.names(Ramp_df) <- Ramp_df$Level
Ramp_df <- Ramp_df[,-1]
rm(RampMeteringInp_ls)

#' Delay reduction due to ramp metering
#'
#' Percentage reduction in recurring and non-recurring (incident) delay from
#' ramp metering at full deployment.
#'
#' @format A data frame with 5 rows and 4 columns. Row names are congestion
#' level names(None, Mod, Hvy, Sev, Ext):
#' \describe{
#'   \item{Fwy_Rcr}{percentage reduction in freeway recurring congestion delay
#'   by congestion level}
#'   \item{Fwy_NonRcr}{percentage reduction in freeway non-recurring congestion
#'   delay by congestion level}
#'   \item{Art_Rcr}{percentage reduction in arterial recurring congestion delay
#'   by congestion level}
#'   \item{Art_NonRcr}{percentage reduction in arterial non-recurring congestion
#'   delay by congestion level}
#'   }
#' @source CalculateSpeeds.R script.
"Ramp_df"
usethis::use_data(Ramp_df, overwrite = TRUE)


#-------------------------------------------------
#Load and save incident management delay reduction
#-------------------------------------------------
IncidentManagementInp_ls <- items(
  item(
    NAME = "Level",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Fwy_Rcr",
            "Fwy_NonRcr",
            "Art_Rcr",
            "Art_NonRcr"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
Incident_df <-   processEstimationInputs(
  IncidentManagementInp_ls,
  "incident_management.csv",
  "CalculateSpeeds.R")
row.names(Incident_df) <- Incident_df$Level
Incident_df <- Incident_df[,-1]
rm(IncidentManagementInp_ls)

#' Delay reduction due to incident management
#'
#' Percentage reduction in recurring and non-recurring (incident) delay from
#' incident management at full deployment.
#'
#' @format A data frame with 5 rows and 4 columns. Row names are congestion
#' level names(None, Mod, Hvy, Sev, Ext):
#' \describe{
#'   \item{Fwy_Rcr}{percentage reduction in freeway recurring congestion delay
#'   by congestion level}
#'   \item{Fwy_NonRcr}{percentage reduction in freeway non-recurring congestion
#'   delay by congestion level}
#'   \item{Art_Rcr}{percentage reduction in arterial recurring congestion delay
#'   by congestion level}
#'   \item{Art_NonRcr}{percentage reduction in arterial non-recurring congestion
#'   delay by congestion level}
#'   }
#' @source CalculateSpeeds.R script.
"Incident_df"
usethis::use_data(Incident_df, overwrite = TRUE)


#------------------------------------------------
#Load and save signal progression delay reduction
#------------------------------------------------
SignalCoordinationInp_ls <- items(
  item(
    NAME = "Level",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Fwy_Rcr",
            "Fwy_NonRcr",
            "Art_Rcr",
            "Art_NonRcr"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
Signal_df <-   processEstimationInputs(
  SignalCoordinationInp_ls,
  "signal_coordination.csv",
  "CalculateSpeeds.R")
row.names(Signal_df) <- Signal_df$Level
Signal_df <- Signal_df[,-1]
rm(SignalCoordinationInp_ls)

#' Delay reduction due to signal coordination
#'
#' Percentage reduction in recurring and non-recurring (incident) delay from
#' signal coordination at full deployment.
#'
#' @format A data frame with 5 rows and 4 columns. Row names are congestion
#' level names(None, Mod, Hvy, Sev, Ext):
#' \describe{
#'   \item{Fwy_Rcr}{percentage reduction in freeway recurring congestion delay
#'   by congestion level}
#'   \item{Fwy_NonRcr}{percentage reduction in freeway non-recurring congestion
#'   delay by congestion level}
#'   \item{Art_Rcr}{percentage reduction in arterial recurring congestion delay
#'   by congestion level}
#'   \item{Art_NonRcr}{percentage reduction in arterial non-recurring congestion
#'   delay by congestion level}
#'   }
#' @source CalculateSpeeds.R script.
"Signal_df"
usethis::use_data(Signal_df, overwrite = TRUE)


#--------------------------------------
#Load access management delay reduction
#--------------------------------------
AccessManagementInp_ls <- items(
  item(
    NAME = "Level",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Fwy_Rcr",
            "Fwy_NonRcr",
            "Art_Rcr",
            "Art_NonRcr"),
    TYPE = "double",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
Access_df <-   processEstimationInputs(
  AccessManagementInp_ls,
  "access_management.csv",
  "CalculateSpeeds.R")
row.names(Access_df) <- Access_df$Level
Access_df <- Access_df[,-1]
rm(AccessManagementInp_ls)

#' Delay reduction due to access management
#'
#' Percentage reduction in recurring and non-recurring (incident) delay from
#' access management using median barriers at full deployment.
#'
#' @format A data frame with 5 rows and 4 columns. Row names are congestion
#' level names(None, Mod, Hvy, Sev, Ext):
#' \describe{
#'   \item{Fwy_Rcr}{percentage reduction in freeway recurring congestion delay
#'   by congestion level}
#'   \item{Fwy_NonRcr}{percentage reduction in freeway non-recurring congestion
#'   delay by congestion level}
#'   \item{Art_Rcr}{percentage reduction in arterial recurring congestion delay
#'   by congestion level}
#'   \item{Art_NonRcr}{percentage reduction in arterial non-recurring congestion
#'   delay by congestion level}
#'   }
#' @source CalculateSpeeds.R script.
"Access_df"
usethis::use_data(Access_df, overwrite = TRUE)


#-----------------------------------
#Define function to calculate speeds
#-----------------------------------
#' Calculate speeds and delay by road class and congestion level.
#'
#' \code{calculateSpeeds} Calculate and speeds and delay by road class and
#' congestion level.
#'
#' This function calculates roadway speeds and delay by road class and
#' congestion level in consideration of the effects of reductions in delay due
#' to the deployment of operations measures.
#'
#' @param OpsDeployment_ a numeric vector identifying the proportional degree of
#' roadway operations programs (ramp metering, incident management, signal
#' coordination, accessmanagement, other) where 0 means no deployment and
#' 1 means deployment covering the entire road system.
#' @param OtherOpsEffects_mx a numeric matrix of percentage delay reductions
#' for user-defined freeway and arterial operations programs by congestion
#' level.
#' @return A list containing two matrices. The first is a matrix of average
#' speed (miles per hour) by congestion level and road class. The second is a
#' matrix of delay hours per vehicle mile by congestion level and road class.
#' @name calculateSpeeds
#' @import visioneval
#' @import stats
#' @export
calculateSpeeds <- function(OpsDeployment_, OtherOpsEffects_mx = NULL) {
  #Calculate recurring and non-recurring (incident-related) delay
  BaseTravelRate_mx <- 1 / as.matrix(BaseSpeeds_df)
  Delay_mx <-
    sweep(BaseTravelRate_mx, 2, BaseTravelRate_mx[1,], "-")
  BaseDelay_mx <- cbind(
    Fwy_Rcr = Delay_mx[,"Fwy_Rcr"],
    Fwy_NonRcr = Delay_mx[,"Fwy"] - Delay_mx[,"Fwy_Rcr"],
    Art_Rcr = Delay_mx[,"Art_Rcr"],
    Art_NonRcr = Delay_mx[,"Art"] - Delay_mx[,"Art_Rcr"]
  )
  rm(Delay_mx)
  #Calculate operations management delay reduction effects
  RampFactor_mx <-
    1 - OpsDeployment_["RampMeterDeployProp"] * as.matrix(Ramp_df) / 100
  IncidentFactor_mx <-
    1 - OpsDeployment_["IncidentMgtDeployProp"] * as.matrix(Incident_df) / 100
  SignalFactor_mx <-
    1 - OpsDeployment_["SignalCoordDeployProp"] * as.matrix(Signal_df) / 100
  AccessFactor_mx <-
    1 - OpsDeployment_["AccessMgtDeployProp"] * as.matrix(Access_df) / 100
  #Calculate joint effect
  DelayFactor_mx <-
    RampFactor_mx * IncidentFactor_mx * SignalFactor_mx * AccessFactor_mx
  if (!is.null(OtherOpsEffects_mx)) {
    OtherOpsDeploy_ <-
      rep(OpsDeployment_[c("OtherFwyOpsDeployProp", "OtherArtOpsDeployProp")], each = 2)
    OtherOpsFactor_mx <-
      1 - sweep(OtherOpsEffects_mx, 2, OtherOpsDeploy_, "*") / 100
    DelayFactor_mx <- DelayFactor_mx * OtherOpsFactor_mx
  }
  #Calculate adjusted delay
  AdjDelay_mx <- BaseDelay_mx * DelayFactor_mx
  Delay_mx <- cbind(
    Fwy = rowSums(AdjDelay_mx[,c("Fwy_Rcr", "Fwy_NonRcr")]),
    Art = rowSums(AdjDelay_mx[,c("Art_Rcr", "Art_NonRcr")])
  )
  #Calculate adjusted speed
  AdjTravelRate_mx <-
    sweep(Delay_mx, 2, BaseTravelRate_mx["None",c("Fwy", "Art")], "+")
  Speed_mx <- 1 / AdjTravelRate_mx
  #Return the results
  list(
    Speed = Speed_mx,
    Delay = Delay_mx
  )
}


#===============================================================
#SECTION 1D: ESTIMATE AND SAVE FREEWAY/ARTERIAL DVMT SPLIT MODEL
#===============================================================
#Light-duty vehicle DVMT is split between freeways and arterials as a function
#of the ratio of the respective average travel speeds and a calibration factor.
#The calibration factor is calculated for all metropolitan areas included in
#the Urban Mobility Study dataset. In addition, a regression model is estimated
#to calculate values for unlisted metropolitan areas and to calculate future
#values as the metropolitan area grows.

#Create matrices of freeway and arterial DVMT proportions by congestion level
#----------------------------------------------------------------------------
#Function to create matrix of DVMT proportions by area and congestion level
calcCongProps <- function(Fields_, Names_) {
  CongProp_mx <- as.matrix(Ums_df[,Fields_]) / 100
  colnames(CongProp_mx) <- names(Fields_)
  CongProp_mx <- cbind(None = 1 - rowSums(CongProp_mx), CongProp_mx)
  rownames(CongProp_mx) <- Names_
  CongProp_mx
}
#Freeway DVMT proportions by area and congestion level
FwyCongProp_MaCl <- calcCongProps(
  Fields_ = c(Mod = "FwyVmtModPct",
              Hvy = "FwyVmtHvyPct",
              Sev = "FwyVmtSevPct",
              Ext = "FwyVmtExtPct"),
  Names_ <- Ums_df$Area
)
#Arterial DVMT proportions by area and congestion level
ArtCongProp_MaCl <- calcCongProps(
  Fields_ = c(Mod = "ArtVmtModPct",
              Hvy = "ArtVmtHvyPct",
              Sev = "ArtVmtSevPct",
              Ext = "ArtVmtExtPct"),
  Names_ <- Ums_df$Area
)
rm(calcCongProps)

#Create matrices of freeway and arterial speeds by congestion level
#------------------------------------------------------------------
#Function to create matrix of speeds by area and congestion level
calcCongSpeeds <- function(Fields_, Names_, FfSpeed) {
  CongSpeeds_mx <- as.matrix(Ums_df[,Fields_])
  colnames(CongSpeeds_mx) <- names(Fields_)
  CongSpeeds_mx <- cbind(None = FfSpeed, CongSpeeds_mx)
  rownames(CongSpeeds_mx) <- Names_
  CongSpeeds_mx
}
# Average freeway speeds by area and congestion level
AveFwySpds_MaCl <- calcCongSpeeds(
  Fields_ <- c(Mod = "FwyAveModSpd",
               Hvy = "FwyAveHvySpd",
               Sev = "FwyAveSevSpd",
               Ext = "FwyAveExtSpd"),
  Names_ = Ums_df$Area,
  FfSpeed = 60
)
# Average freeway speeds by area and congestion level
AveArtSpds_MaCl <- calcCongSpeeds(
  Fields_ <- c(Mod = "ArtAveModSpd",
               Hvy = "ArtAveHvySpd",
               Sev = "ArtAveSevSpd",
               Ext = "ArtAveExtSpd"),
  Names_ = Ums_df$Area,
  FfSpeed = 30
)
rm(calcCongSpeeds)

#Compute metropolitan factors for computing DVMT ratio from average speed ratio
#------------------------------------------------------------------------------
#Define function to calculate average speed
calcAveSpd <- function(DvmtProp_MaCl, TotDvmt_Ma, AveSpd_MaCl) {
  Dvmt_MaCl <- sweep(DvmtProp_MaCl, 1, TotDvmt_Ma, "*")
  Dvht_MaCl <- Dvmt_MaCl / AveSpd_MaCl
  rowSums(Dvmt_MaCl) / rowSums(Dvht_MaCl)
}
#Calculate average speeds and ratio of freeway to arterial average speed
FwyAveSpeed_Ma <-
  calcAveSpd(FwyCongProp_MaCl, Ums_df$FwyDvmt000, AveFwySpds_MaCl)
ArtAveSpeed_Ma <-
  calcAveSpd(ArtCongProp_MaCl, Ums_df$ArtDvmt000, AveArtSpds_MaCl)
SpeedRatio_Ma <- FwyAveSpeed_Ma / ArtAveSpeed_Ma
rm(FwyAveSpeed_Ma, FwyCongProp_MaCl, AveFwySpds_MaCl,
   ArtAveSpeed_Ma, ArtCongProp_MaCl, AveArtSpds_MaCl)
#Calculate ratio of freeway to arterial DVMT
DvmtRatio_Ma <- with(Ums_df, FwyDvmt000 / ArtDvmt000)
#Calculate factor to compute DVMT ratio from average speed ratio
Lambda_Ma <- DvmtRatio_Ma / SpeedRatio_Ma
rm(DvmtRatio_Ma, SpeedRatio_Ma)

#Estimate model for calculating DVMT split factor
#------------------------------------------------
#A linear model for calculating the computed 'Lambda' values is estimated using
#independent variables available in the urban mobility study data. Several model
#specifications were tested. The best performing model (having the highest
#adjusted R-squared value) includes as independent variables the natural log of
#population and the ratio of freeway lane miles to arterial lane miles.
Lambda_df <- data.frame(
  Lambda = Lambda_Ma,
  Pop = Ums_df$Pop000 * 1000,
  SqMi = Ums_df$SqMi,
  LogPop = log(Ums_df$Pop000 * 1000),
  LnMiRatio = with(Ums_df, FwyLnMi / ArtLnMi),
  PopSqMi = with(Ums_df, 1000 * Pop000 / SqMi),
  FwyLnMi = Ums_df$FwyLnMi,
  ArtLnMi = Ums_df$ArtLnMi,
  FwyLnMiPC = with(Ums_df, 1e-3 * FwyLnMi / Pop000),
  ArtLnMiPC = with(Ums_df, 1e-3 * ArtLnMi / Pop000),
  FwyLnMiSqMi = with(Ums_df, FwyLnMi / SqMi),
  ArtLnMiSqMi = with(Ums_df, ArtLnMi / SqMi),
  LnMiSqMi = with(Ums_df, (FwyLnMi + ArtLnMi) / SqMi)
)
DvmtSplit_LM <-  lm(Lambda ~ LogPop + LnMiRatio, data = Lambda_df)
#summary(DvmtSplit_LM)
#plot(DvmtSplit_LM)
#plot(Lambda_Ma, fitted(DvmtSplit_LM))
#abline(0, 1, col = "red")
#cor(Lambda_df[,c("LogPop", "LnMiRatio")])
rm(Lambda_df, Ums_df)

#Save the model for calculating factor for splitting DVMT based on speeds
#------------------------------------------------------------------------
#' DVMT split factor model
#'
#' A linear model for calculating the factor used to calculate the ratio of
#' freeway DVMT to arterial DVMT from the ratio of freeway average speed to
#' arterial average speed.
#'
#' @format A linear model object
#' \describe{
#'   \item{DvmtSplit_LM}{a linear model object}
#' }
#' @source CalculateRoadPerformance.R script.
"DvmtSplit_LM"
usethis::use_data(DvmtSplit_LM, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateRoadPerformanceSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
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
      NAME = "UrbanPop",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
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
      NAME = items(
        "RampMeterDeployProp",
        "IncidentMgtDeployProp",
        "SignalCoordDeployProp",
        "AccessMgtDeployProp",
        "OtherFwyOpsDeployProp",
        "OtherArtOpsDeployProp"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Level",
      TABLE = "OtherOpsEffectiveness",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("None", "Mod", "Hvy", "Sev", "Ext"),
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "Art_Rcr",
        "Art_NonRcr",
        "Fwy_Rcr",
        "Fwy_NonRcr"),
      TABLE = "OtherOpsEffectiveness",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 100"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "LdvFwyArtDvmt",
          "LdvOthDvmt",
          "HvyTrkFwyDvmt",
          "HvyTrkArtDvmt",
          "HvyTrkOthDvmt",
          "BusFwyDvmt",
          "BusArtDvmt",
          "BusOthDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyNoneCongChg",
        "FwyModCongChg",
        "FwyHvyCongChg",
        "FwySevCongChg",
        "FwyExtCongChg",
        "ArtNoneCongChg",
        "ArtModCongChg",
        "ArtHvyCongChg",
        "ArtSevCongChg",
        "ArtExtCongChg"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ValueOfTime",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanArea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "SQMI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = items(
        "LdvFwyDvmt",
        "LdvArtDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
        "Light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways")
    ),
    item(
      NAME = items(
        "FwyNoneCongSpeed",
        "FwyModCongSpeed",
        "FwyHvyCongSpeed",
        "FwySevCongSpeed",
        "FwyExtCongSpeed",
        "ArtNoneCongSpeed",
        "ArtModCongSpeed",
        "ArtHvyCongSpeed",
        "ArtSevCongSpeed",
        "ArtExtCongSpeed",
        "OthSpd",
        "AveLdvSpd"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      NAVALUE = -1,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average freeway speed (miles per hour) when there is no congestion",
        "Average freeway speed (miles per hour) when congestion is moderate",
        "Average freeway speed (miles per hour) when congestion is heavy",
        "Average freeway speed (miles per hour) when congestion is severe",
        "Average freeway speed (miles per hour) when congestion is extreme",
        "Average arterial speed (miles per hour) when there is no congestion",
        "Average arterial speed (miles per hour) when congestion is moderate",
        "Average arterial speed (miles per hour) when congestion is heavy",
        "Average arterial speed (miles per hour) when congestion is severe",
        "Average arterial speed (miles per hour) when congestion is extreme",
        "Average speed (miles per hour) on other roadways",
        "Average light-duty vehicle speed (miles per hour) on all roadways weighted by the proportions of light-duty vehicle travel")
    ),
    item(
      NAME = items(
        "FwyNoneCongDelay",
        "FwyModCongDelay",
        "FwyHvyCongDelay",
        "FwySevCongDelay",
        "FwyExtCongDelay",
        "ArtNoneCongDelay",
        "ArtModCongDelay",
        "ArtHvyCongDelay",
        "ArtSevCongDelay",
        "ArtExtCongDelay"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HR/MI",
      NAVALUE = -1,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average freeway delay (hours per mile) occurring when there is no congestion",
        "Average freeway delay (hours per mile) occurring when congestion is moderate",
        "Average freeway delay (hours per mile) occurring when congestion is heavy",
        "Average freeway delay (hours per mile) occurring when congestion is severe",
        "Average freeway delay (hours per mile) occurring when congestion is extreme",
        "Average arterial delay (hours per mile) occurring when there is no congestion",
        "Average arterial delay (hours per mile) occurring when congestion is moderate",
        "Average arterial delay (hours per mile) occurring when congestion is heavy",
        "Average arterial delay (hours per mile) occurring when congestion is severe",
        "Average arterial delay (hours per mile) occurring when congestion is extreme")
    ),
    item(
      NAME = items(
        "FwyDvmtPropNoneCong",
        "FwyDvmtPropModCong",
        "FwyDvmtPropHvyCong",
        "FwyDvmtPropSevCong",
        "FwyDvmtPropExtCong",
        "ArtDvmtPropNoneCong",
        "ArtDvmtPropModCong",
        "ArtDvmtPropHvyCong",
        "ArtDvmtPropSevCong",
        "ArtDvmtPropExtCong"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Proportion of freeway DVMT occurring when there is no congestion",
        "Proportion of freeway DVMT occurring when congestion is moderate",
        "Proportion of freeway DVMT occurring when congestion is heavy",
        "Proportion of freeway DVMT occurring when congestion is severe",
        "Proportion of freeway DVMT occurring when congestion is extreme",
        "Proportion of arterial DVMT occurring when there is no congestion",
        "Proportion of arterial DVMT occurring when congestion is moderate",
        "Proportion of arterial DVMT occurring when congestion is heavy",
        "Proportion of arterial DVMT occurring when congestion is severe",
        "Proportion of arterial DVMT occurring when congestion is extreme")
    ),
    item(
      NAME = "AveCongPrice",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average price paid (dollars per mile) in congestion fees"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateRoadPerformance module
#'
#' A list containing specifications for the CalculateRoadPerformance module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateRoadPerformance.R script.
"CalculateRoadPerformanceSpecifications"
usethis::use_data(CalculateRoadPerformanceSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#' Calculate road performance measures
#'
#' \code{CalculateRoadPerformance} calculates freeway and arterial daily vehicle
#' miles of travel (DVMT) by congestion level, freeway and arterial speeds and
#' delays by congestion level, and the split of light-duty vehicle DVMT between
#' freeways and arterials.
#'
#' This function splits freeway DVMT by congestion level based on the ratio of
#' DVMT to lane miles using a lookup table. Arterial DVMT is split into
#' congestion levels in the same manner. Freeway speeds and arterial speeds
#' by congestion level are calculated given the user-specified deployments of
#' operations measures (e.g. ramp metering, incident management, signal
#' coordination, access management). The function likewise calculates delay rate
#' (hours per mile) by congestion level. User-specified congestion prices are
#' converted into equivalent vehicle hours of travel (VHT) based using the
#' user-defined value-of-time parameter. The sum of actual VHT and these
#' equivalent VHT are divided by total DVMT to calculate an average equivalent
#' speed. Light-duty vehicle DVMT is split between freeways and arterials based
#' on the ratio of freeway and arterial average equivalent speeds and a
#' parameter that is calculated from the DVMT split model. These calculations
#' are repeated until an equilibrium value is found (i.e. the DVMT split ratio
#' changes by less than 0.01% from one iteration to the next).
#'
#' @param L A list containing data defined by the module specification.
#' @return A list containing data produced by the function consistent with the
#' module specifications.
#' @name CalculateRoadPerformance
#' @import visioneval
#' @export
CalculateRoadPerformance <- function(L) {

  #Set up
  #------
  #Define naming vectors for Mareas and congestion levels
  Ma <- L$Year$Marea$Marea
  Cl <- c("None", "Mod", "Hvy", "Sev", "Ext")
  #Define default speed for other roads (not freeway or arterial)
  OthSpeed <- 25

  #Calculate Lambda value for metropolitan area
  #--------------------------------------------
  DvmtSplitData_df <- data.frame(
    LogPop = log(sum(L$Year$Marea$UrbanPop)),
    LnMiRatio = L$Year$Marea$FwyLaneMi / L$Year$Marea$ArtLaneMi
  )
  Lambda_Ma <- unname(predict(DvmtSplit_LM, newdata = DvmtSplitData_df))
  names(Lambda_Ma) <- Ma
  rm(DvmtSplitData_df)

  #Calculate speed and delay by congestion level and metropolitan area
  #-------------------------------------------------------------------
  #Create matrix of user-defined other operations effects
  OtherOpsEffects_mx <- cbind(
    Fwy_Rcr = L$Global$OtherOpsEffectiveness$Fwy_Rcr,
    Fwy_NonRcr = L$Global$OtherOpsEffectiveness$Fwy_NonRcr,
    Art_Rcr = L$Global$OtherOpsEffectiveness$Art_Rcr,
    Art_NonRcr = L$Global$OtherOpsEffectiveness$Art_NonRcr
  )
  rownames(OtherOpsEffects_mx) <- L$Global$OtherOpsEffectiveness$Level
  #Calculate speed and delay by Marea and congestion level
  SpeedAndDelay_ls <- list()
  OpsDeployNames_ <- c(
    "RampMeterDeployProp",
    "IncidentMgtDeployProp",
    "SignalCoordDeployProp",
    "AccessMgtDeployProp",
    "OtherFwyOpsDeployProp",
    "OtherArtOpsDeployProp")
  OpsDeployment_MaOp <- do.call(cbind, L$Year$Marea[OpsDeployNames_])
  rownames(OpsDeployment_MaOp) <- Ma
  for (ma in Ma) {
    SpeedAndDelay_ls[[ma]] <-
      calculateSpeeds(OpsDeployment_MaOp[ma,], OtherOpsEffects_mx)
  }
  #Convert to matrices
  FwySpeed_MaCl <- do.call(rbind, lapply(SpeedAndDelay_ls, function(x) {
    x$Speed[,"Fwy"]
  }))
  ArtSpeed_MaCl <- do.call(rbind, lapply(SpeedAndDelay_ls, function(x) {
    x$Speed[,"Art"]
  }))
  FwyDelay_MaCl <- do.call(rbind, lapply(SpeedAndDelay_ls, function(x) {
    x$Delay[,"Fwy"]
  }))
  ArtDelay_MaCl <- do.call(rbind, lapply(SpeedAndDelay_ls, function(x) {
    x$Delay[,"Art"]
  }))

  #Make matrices of DVMT by metropolitan area, vehicle type and road class
  #-----------------------------------------------------------------------
  #Light-duty vehicle DVMT
  LdvDvmt_MaRx <-
    do.call(cbind, L$Year$Marea[c("LdvFwyArtDvmt", "LdvOthDvmt")])
  colnames(LdvDvmt_MaRx) <- c("FwyArt", "Oth")
  rownames(LdvDvmt_MaRx) <- Ma
  #Heavy-duty vehicle DVMT
  HvyTrkDvmt_MaRc <-
    do.call(cbind, L$Year$Marea[c("HvyTrkFwyDvmt", "HvyTrkArtDvmt", "HvyTrkOthDvmt")])
  colnames(HvyTrkDvmt_MaRc) <- c("Fwy", "Art", "Oth")
  rownames(HvyTrkDvmt_MaRc) <- Ma
  #Bus DVMT
  BusDvmt_MaRc <-
    do.call(cbind, L$Year$Marea[c("BusFwyDvmt", "BusArtDvmt", "BusOthDvmt")])
  colnames(BusDvmt_MaRc) <- c("Fwy", "Art", "Oth")
  rownames(BusDvmt_MaRc) <- Ma

  #Create matrices of freeway and arterial congestion prices, and VOT
  #------------------------------------------------------------------
  FwyPrices_MaCl <- do.call(cbind, L$Year$Marea[paste0("Fwy", Cl, "CongChg")])
  rownames(FwyPrices_MaCl) <- Ma
  ArtPrices_MaCl <- do.call(cbind, L$Year$Marea[paste0("Art", Cl, "CongChg")])
  rownames(ArtPrices_MaCl) <- Ma
  VOT <- L$Global$Model$ValueOfTime

  #Create matrix of freeway and arterial lane miles
  #------------------------------------------------
  LaneMi_MaRc <- do.call(cbind, L$Year$Marea[c("FwyLaneMi", "ArtLaneMi")])
  rownames(LaneMi_MaRc) <- Ma
  colnames(LaneMi_MaRc) <- c("Fwy", "Art")

  #Define function to calculate average speed including price adjustments
  #----------------------------------------------------------------------
  calcAveSpeed <- function(Dvmt_Cl, Speed_Cl, Price_Cl, VOT) {
    Dvht <- sum(Dvmt_Cl / Speed_Cl)
    DvhtEq <- sum(Dvmt_Cl * Price_Cl / VOT)
    sum(Dvmt_Cl) / (Dvht + DvhtEq)
  }

  #Define function to split freeway & arterial LDV DVMT
  #----------------------------------------------------
  splitLdvDvmt <- function(LdvDvmt_, AveFwySpd, AveArtSpd, Lambda) {
    DvmtRatio <- Lambda * AveFwySpd / AveArtSpd
    FwyDvmt <- unname(LdvDvmt_["FwyArt"] * DvmtRatio / (1 + DvmtRatio))
    ArtDvmt <- unname(LdvDvmt_["FwyArt"] - FwyDvmt)
    c(Fwy = FwyDvmt, Art = ArtDvmt, Oth = LdvDvmt_["Oth"])
  }

  #Define function to balance freeway and arterial DVMT
  #----------------------------------------------------
  balanceFwyArtDvmt <- function(ma) {
    #Initialize values
    LastDvmtRatio <- 0
    FwyAveSpeed <- 60
    ArtAveSpeed <- 30
    #Iterate to find solution
    for (i in 1:100) {
      LdvDvmt_Rc <-
        splitLdvDvmt(LdvDvmt_MaRx[ma,], FwyAveSpeed, ArtAveSpeed, Lambda_Ma[ma])
      Dvmt_Rc <-
        LdvDvmt_Rc + HvyTrkDvmt_MaRc[ma,] + BusDvmt_MaRc[ma,]
      FwyDvmt_Cl <-
        calculateCongestion("DVMT", "Fwy", LaneMi_MaRc[ma,"Fwy"], Dvmt_Rc["Fwy"])
      FwyAveSpeed <-
        calcAveSpeed(FwyDvmt_Cl, FwySpeed_MaCl[ma,], FwyPrices_MaCl[ma,], VOT)
      ArtDvmt_Cl <-
        calculateCongestion("DVMT", "Art", LaneMi_MaRc[ma,"Art"], Dvmt_Rc["Art"])
      ArtAveSpeed <-
        calcAveSpeed(ArtDvmt_Cl, ArtSpeed_MaCl[ma,], ArtPrices_MaCl[ma,], VOT)
      DvmtRatio <- sum(FwyDvmt_Cl) / sum(ArtDvmt_Cl)
      if(abs(1 - LastDvmtRatio / DvmtRatio) < 0.0001) break()
      LastDvmtRatio <- DvmtRatio
    }
    list(LdvDvmt = LdvDvmt_Rc,
         FwyDvmt = FwyDvmt_Cl,
         ArtDvmt = ArtDvmt_Cl)
  }

  #Iterate through metropolitan areas and perform DVMT balancing
  #-------------------------------------------------------------
  BalanceResults_ls <- list()
  for(ma in Ma) {
    BalanceResults_ls[[ma]] <- balanceFwyArtDvmt(ma)
  }

  #Calculate daily average light-duty vehicle speed
  #------------------------------------------------
  #Calculate average speed by metropolitan area and road class
  AveLdvSpd_MaRc <-
    array(0, dim = c(length(Ma), 3), dimnames = list(Ma, c("Fwy", "Art", "Oth")))
  for (ma in Ma) {
    FwySpd_Cl <- SpeedAndDelay_ls[[ma]]$Speed[,"Fwy"]
    FwyDvmt_Cl <- BalanceResults_ls[[ma]]$FwyDvmt
    AveLdvSpd_MaRc[ma, "Fwy"] <- sum(FwySpd_Cl * FwyDvmt_Cl / sum(FwyDvmt_Cl))
    rm(FwySpd_Cl, FwyDvmt_Cl)
    ArtSpd_Cl <- SpeedAndDelay_ls[[ma]]$Speed[,"Art"]
    ArtDvmt_Cl <- BalanceResults_ls[[ma]]$ArtDvmt
    AveLdvSpd_MaRc[ma, "Art"] <- sum(ArtSpd_Cl * ArtDvmt_Cl / sum(ArtDvmt_Cl))
    rm(ArtSpd_Cl, ArtDvmt_Cl)
    AveLdvSpd_MaRc[ma, "Oth"] <- OthSpeed
  }
  #Calculate overall average speed by metropolitan area
  LdvDvmt_MaRc <-
    do.call(rbind, lapply(BalanceResults_ls, function(x) x$LdvDvmt))
  LdvDvmtProp_MaRc <- sweep(LdvDvmt_MaRc, 1, rowSums(LdvDvmt_MaRc), "/")
  AveLdvSpd_Ma <- rowSums(AveLdvSpd_MaRc * LdvDvmtProp_MaRc)

  #Calculate performance measures
  #------------------------------
  Out_ls <- initDataList()
  Out_ls$Year$Marea <- list()
  #LDV freeway DVMT and arterial DVMT
  Out_ls$Year$Marea$LdvFwyDvmt <-
    unname(unlist(lapply(BalanceResults_ls, function(x) x$LdvDvmt["Fwy"])))
  Out_ls$Year$Marea$LdvArtDvmt <-
    unname(unlist(lapply(BalanceResults_ls, function(x) x$LdvDvmt["Art"])))
  #Average freeway speed by congestion level
  Data_ls <-
    as.list(data.frame(
      do.call(rbind, lapply(SpeedAndDelay_ls, function(x) x$Speed[,"Fwy"]))
    ))
  names(Data_ls) <- paste0("Fwy", names(Data_ls), "CongSpeed")
  Out_ls$Year$Marea <- c(Out_ls$Year$Marea, Data_ls); rm(Data_ls)
  #Average arterial speed by congestion level
  Data_ls <-
    as.list(data.frame(
      do.call(rbind, lapply(SpeedAndDelay_ls, function(x) x$Speed[,"Art"]))
    ))
  names(Data_ls) <- paste0("Art", names(Data_ls), "CongSpeed")
  Out_ls$Year$Marea <- c(Out_ls$Year$Marea, Data_ls); rm(Data_ls)
  #Average other road speed
  Out_ls$Year$Marea$OthSpd <- OthSpeed
  #Average light-duty vehicle speed
  Out_ls$Year$Marea$AveLdvSpd <- unname(AveLdvSpd_Ma)
  #Average freeway delay by congestion level
  Data_ls <-
    as.list(data.frame(
      do.call(rbind, lapply(SpeedAndDelay_ls, function(x) x$Delay[,"Fwy"]))
    ))
  names(Data_ls) <- paste0("Fwy", names(Data_ls), "CongDelay")
  Out_ls$Year$Marea <- c(Out_ls$Year$Marea, Data_ls); rm(Data_ls)
  #Average arterial delay by congestion level
  Data_ls <-
    as.list(data.frame(
      do.call(rbind, lapply(SpeedAndDelay_ls, function(x) x$Delay[,"Art"]))
    ))
  names(Data_ls) <- paste0("Art", names(Data_ls), "CongDelay")
  Out_ls$Year$Marea <- c(Out_ls$Year$Marea, Data_ls); rm(Data_ls)
  #Proportion of freeway DVMT by congestion level
  FwyDvmt_MaCl <-
    do.call(rbind, lapply(BalanceResults_ls, function(x) x$FwyDvmt))
  Data_ls <-
    as.list(data.frame(sweep(FwyDvmt_MaCl, 1, rowSums(FwyDvmt_MaCl), "/")))
  names(Data_ls) <- paste0("FwyDvmtProp", names(Data_ls), "Cong")
  Out_ls$Year$Marea <- c(Out_ls$Year$Marea, Data_ls); rm(Data_ls)
  #Proportion of arterial DVMT by congestion level
  ArtDvmt_MaCl <-
    do.call(rbind, lapply(BalanceResults_ls, function(x) x$ArtDvmt))
  Data_ls <-
    as.list(data.frame(sweep(ArtDvmt_MaCl, 1, rowSums(ArtDvmt_MaCl), "/")))
  names(Data_ls) <- paste0("ArtDvmtProp", names(Data_ls), "Cong")
  Out_ls$Year$Marea <- c(Out_ls$Year$Marea, Data_ls); rm(Data_ls)
  #Average congestion cost per mile
  AveCongPrice_Ma <-
    (rowSums(FwyPrices_MaCl * FwyDvmt_MaCl) + rowSums(ArtPrices_MaCl * ArtDvmt_MaCl)) /
    sum(FwyDvmt_MaCl + ArtDvmt_MaCl)
  Out_ls$Year$Marea$AveCongPrice <- AveCongPrice_Ma
  #Return the result
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
#   ModuleName = "CalculateRoadPerformance",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "BaseYear"
# )
# L <- TestDat_$L
# R <- CalculateRoadPerformance(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateRoadPerformance",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "BaseYear"
# )


