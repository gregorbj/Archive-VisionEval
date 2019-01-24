#==============================
#CalculateMpgMpkwhAdjustments.R
#==============================

#<doc>
#
## CalculateMpgMpkwhAdjustments Module
#### January 23, 2019
#
#This module calculates adjustments to fuel economy and electric energy efficiency (for plug-in vehicles) resulting from traffic congestion, speed smoothing (i.e. active traffic management which reduces speed variation), and eco-driving. Eco-driving is the practice of driving in ways that increase fuel economy and reduce carbon emissions.
#
### Model Parameter Estimation
#
#This module calculates adjustments to the average fuel economy of internal combustion engine vehicles and the average electric energy efficiency of plug in vehicles. Adjustments are made in response to congestion, speed smoothing, and eco-driving.
#
##### Model of the Effects of Speed on Fuel Economy
#
#Congestion adjustments use a fuel-speed curve methodology that is based on research by Alex Bigazzi and Kelly Clifton documented in "Refining GreenSTEP: Impacts of Vehicle Technologies and ITS/Operational Improvements on Travel Speed and Fuel Consumption Curves Final Report on Task 1: Advanced Vehicle Fuel-Speed Curves", November 2011. (A copy of this report is included in the inst/extdata/sources directory of this package.) Among other things, this research developed a set of models which calculate adjustments to the average fuel economy of vehicles as a function of the vehicle type (light-duty, heavy-duty), the vehicle powertrain (ICE, HEV, EV), and the road type (freeway, arterial). These models are applied to the results of urban congestion analysis by the CalculateRoadPerformance module (DVMT by road type and congestion level, average speed by road type and congestion level) to calculate proportional adjustments to vehicle fuel economy (or energy efficiency for electric vehicles) that reflect the effects of congestion on different vehicle types and powertrains. Following is a brief summary of the methodology detailed in the report. Note that when the term 'fuel economy' is used in the context of electric vehicles, it means the energy efficiency of the electric vehicle (i.e. miles per kilowatt-hour).
#
#The US Environmental Protection Agency's (EPA) PERE model is used to model the fuel economy and energy efficiency relationships with travel speed for the vehicle types listed above. The PERE model was developed by the EPA to fill in gaps in fuel consumption rate data for advanced technology vehicles that are not addressed by EPA's MOVES model and to help project future emissions. The PERE model takes as inputs driving cycle data (i.e. second-by-second speed and time data reflecting a realistic driving pattern) and general vehicle characteristics and calculates the power requirements of the vehicle over the drive cycle. Power requirements are measured in terms of vehicle-specific power (VSP) which is the power required to move the vehicle divided by the mass of the vehicle. The second-by-second results are aggregated into VSP bins. The PERE model then calculates the energy consumption by VSP based on the powertrain type and the characteristics of the powertrain (e.g. engine displacement). The average fuel economy for the drive cycle is calculated from the energy consumption by VSP bin and the amount of drive time by VSP bin.
#
#145 vehicle configurations for the following 5 vehicle and powertrain types are modeled using the PERE model:
#
#* Light-duty internal combustion engine vehicle (LdIce)
#
#* Light-duty hybrid electric vehicle (LdHev)
#
#* Light-duty electric vehicle (LdEv)
#
#* Light-duty fuel cell vehicle (LdFcv)
#
#* Heavy-duty internal combustion engine vehicle (HdIce)
#
#Note that the fuel cell vehicle type is not currently included in the VisionEval model. Also note that plug-in hybrid electric (PHEV) vehicles are not analyzed. These are treated in VisionEval model as combination HEV and EV vehicles and they have both an MPG rating (similar to HEV) and an MPKWH rating (similar to EV). The HEV and EV adjustment factors are applied to the respective components.
#
#The PERE model is used to model the fuel economy of each of the vehicle configurations using several drive cycles including a number of drive cycles that are incorporated in the MOVES model, EPA test drive cycles used to calculate average fuel economy, and a drive cycle using data collected on 59 probe vehicle runs on a Portland (OR) area freeway. Since each of the drive cycles is associated with an overall average trip speed, the relationship between between average trip speed (rather than instantaneous speed) and fuel consumption by vehicle type and facility type (freeway, arterial) can be determined. This relationship is commonly referred to as a fuel-speed curve (FSC) and is modeled as an exponentiated 4th order polynomial relationship with speed. An iteratively reweighted least squares (IWLS) method was used to fit the model coefficients.
#
#Since VisionEval includes average fuel economy estimates by vehicle type and model year, the FSCs must be transformed to represent the relationship between speed and fuel economy relative to average fuel economy. This is done using reference average speeds corresponding to the EPA test cycles used to estimate average fuel economy. The reference speed of the Highway Fuel Economy Test or HFET (48.2 MPH) is used to normalize freeway FSCs. This corresponds to a speed associated with moderate to heavy freeway congestion (Table 1 of CalculateRoadPerformance module documentation). Normalization is carried out by dividing the exponentiated polynomial expression for the FSC by the value of that expression at the reference speed. A modified method is used to normalize the arterial FSC because the EPA city fuel economy test cycle includes driving on lower speed minor roads as well as arterials so the reference speed is too low to reflect average arterial driving conditions. Instead a reference arterial speed was selected to reflect the same level of arterial congestion as the freeway reference speed (moderate to heavy), 24.4 MPH.
#
#The normalized FSCs are summarized for each of the 5 vehicle types and roadway types by identifying from the sample set of vehicles of the type the vehicles that perform best and worst in congestion on the roadway type. Relative congestion performance is calculated as the percentage difference in fuel economy in congested conditions vs. uncongested conditions. The fuel-speed response is selected within the range by specifying a relative congestion efficiency in the range of 0 to 1 where a value of 0 selects the worst congestion response curve and a value of 1 selects the best congestion response curve. For values in between 0 and 1, the reponse is calculated by linearly interpolating between the worst and best response curves.
#
#Figure 1 illustrates the the effect of congestion on the relative fuel economy of different vehicle types traveling on freeways. Each chart shows the fuel economy response at the lowest congestion efficiency, the highest congestion efficiency, and mid-level congestion efficiency. The curves were generated by applying the speeds from the first column of Table 1 of the CalculateRoadPerformance module documentation. It can be seen from all the LDV plots that there is a considerable amount of variation in congestion response at higher levels of congestion. Looking at the middle congestion efficiency plots it can be seen that relative fuel economy for light-duty ICE vehicles changes little with congestion except at high levels where it declines. The relative fuel economy of light-duty HEVs changes very little across the range of congestion levels. For light-duty EVs, relative fuel economy increases with congstion. Finally, for heavy-duty ICE vehicles, relative fuel economy decreases at a fairly constant rate as congestion increases.
#
#<fig:fwy_fsc-adj_by_vehicle-type.png>
#
#**Figure 1. Fuel Economy Relative to Average by Congestion Level and Vehicle Type on Freeways**
#
#Figure 2 illustrates the the effect of congestion on the relative fuel economy of different vehicle types traveling on arterials. As can be seen, there is a greater response to congestion on arterials than freeways. That is because arterial speeds are slower than freeway speeds and fuel economy declines at an increasing rate as speed decreases. The relative fuel economy of the midpoint congestion efficiency vehicle declines for all vehicle types but the amount of decline is greater for vehicles with ICE powertrains than HEVs and EVs.
#
#<fig:art_fsc-adj_by_vehicle-type.png>
#
#**Figure 2. Fuel Economy Relative to Average by Congestion Level and Vehicle Type on Arterials**
#
#### Speed Smoothing and Eco-driving Model
#
#Speed smoothing through active traffic management and eco-driving practices reduce fuel consumption by reducing acceleration and deceleration losses. The method for calculating the effects is based on research by Bigazzi and Clifton documented in "Refining GreenSTEP: Impacts of Vehicle Technologies and ITS/Operational Improvements on Travel Speed and Fuel Consumption Curves Final Report on Task 2: Incorporation of Operations and ITS Improvements", November 2011." (A copy of this report is included in the inst/extdata/sources directory of this package.) Following is a brief summary of the methodology.
#
#The speed smoothing and eco-driving adjustments to fuel economy only address the effects of reducing speed variation (i.e. reducing acceleration and deceleration events). The methodology does not account for other improvements to fuel economy that eco-driving practices can make such as proper tire inflation, regular maintenance, and reducing the vehicle payload. Moreover, speed smoothing and eco-driving adjustments are only made to vehicles having internal combustion engine powertrains because they are much more affected by acceleration and deceleration losses that HEVs and EVs which use more efficient electric motors to accelerate and which recover energy when decelerating with regenerative braking.
#
#Theoretical maximum improvements in fuel economy with speed-smoothing and eco-driving were calculated by modeling fuel consumption at constant speeds using the PERE model and comparing the results with the drive-cycle results. Table 1 shows the the resulting theoretical maximum improvements in fuel economy by speed for light-duty and heavy-duty ICE vehicles. It can be seen that the lower the speed, the greater the potential for improving fuel economy with speed smoothing.
#
#<tab:MpgMpkwhAdj_ls$SpeedSmoothEffect_df>
#
#**Table 1. Maximum theoretical proportional improvement in fuel economy from speed smoothing by speed**
#
#The fuel economy improvements that are achieveable in practice are substantially less than these maximums. The authors, based on review of the literature, conclude that it is reasonable to expect that speed smoothing through traffic management could achieve 50% of the benefits in Table 1, and that eco-driving could achieve 33% of the benefits on freeways and 21% of the benefits on arterials.
#
#Spline curves are fit to the values in Table 1. These smooth splines are used by the module to estimate the maximum theoretical proportional improvement in fuel economy for any speed. Figure 1 shows the Table 1 values and fitted smooth splines.
#
#<fig:max_speed_smooth_benefit.png>
#
#**Figure 2. Maximum theoretical proportional improvement in fuel economy from speed smoothing by speed**
#
### How the Module Works
#
#### Calculating the effects of modeled speeds on fuel economy
#The module calculates fuel economy adjustments to fuel economy to reflect the effects of modeled travel speeds resulting from congestion. The calculations use marea urban road congestion calculation results from the CalculateRoadPerformance module including DVMT by vehicle type and road class, DVMT by road type and congestion level, and average speed by road type and congestion level. From these data and the congestion model described above, the module computes the proportional adjustments to average MPG and MPKWH by marea and vehicle and powertrain type. The vehicle and powertrain types are the ones identified in the CalculateRoadPerformance module documentation (LdIce, LdHev, LdEv, LdFcv, HdIce). It should be noted that the LdFcv (light-duty fuel cell vehicle) is not a current powertrain option in VisionEval. The steps in the calculation are as follows:
#
#* An array of the modeled average speeds by congestion level for each marea and road class (freeway, arterial, other) is tabulated from the inputs. Since the CalculateRoadPerformance module does not calculate performance of 'other' roads, it is assumed that the speed is constant over all congestion levels (OthSpd in Marea table set by the CalculateRoadPerformance module).
#
#* An array of the proportions of DVMT by congestion level for each marea and road class (freeway, arterial, other) is tabulated from the inputs. Since the CalculateRoadPerformance module does not calculate performance of 'other' roads, it is assumed that DVMT is split uniformly over all congestion levels.
#
#* A list of DVMT proportions by marea and road class by vehicle type (Ldv, HvyTrk, Bus) is tabulated from the inputs.
#
#* For each marea, the average fuel economy adjustment by vehicle powertrain type (LdIce, LdHev, LdEv, HdIce) is calculated as follows:
#
#  * A matrix of fuel economy (FE) adjustments by congestion level and road class is calculated for the marea and powertrain type. For each road class, the relative FSC model coefficients are selected for the vehicle powertrain type and road class. The reference speed for the road class is selected as well. For the 'other' road class, the arterial coefficients are used and the reference speed is the constant speed established for other roads. The relative FSC model is applied to the average speeds by congestion for the road class in the marea to calculate fuel economy (FE) adjustments by congestion level. The result of applying the model to all road classes is a matrix of FE adjustments by congestion level and road class.
#
# * A corresponding matrix of the proportions of DVMT of the corresponding vehicle type (e.g. LdIce = LDV) by congestion level and road class are calculated from the values of DVMT by road class for the vehicle type and the proportions of DVMT by congestion level for each road class.
#
# * The values in the FE adjustment matrix are multiplied by the corresponding values in the DVMT proportions matrix and the results are summed to calculate an average FE adjustment for the vehicle powertrain type in the marea. This average value is used to adjust fuel economy on urban roadways in the marea.
#
# * In addition, an average FE adjustment value for travel at the 'None' congestion level is calculated from the FE adjustments by road class for the 'None' level and the proportions of DVMT for the vehicle type by road class. This average value is used to adjust fuel economy on non-urban roadways in the marea.
#
# * The FE adjustments are outputs to be saved to the datastore for use in the AdjustHhVehicleMpgMpkwh module, CalculateComEnergyAndEmissions module, and CalculatePtranEnergyAndEmissions module.
#
#### Calculating the effects of speed smoothing and eco-driving
#
#The module calculates average proportional improvement in fuel economy (FE) due to active traffic management on urban area freeways and arterials by marea and vehicle type (light-duty, heavy truck, bus). The calculations are sensitive to user inputs on the relative deployment of active traffic management on freeways and arterials by marea ('marea_speed_smooth_ecodrive.csv' file). The potentials for active traffic management on non-urban roads and on roads other than freeways and arterials are not evaluated. The module also calculates the average FE improvement for eco-drivers by marea and vehicle type. The potential benefit for eco-driving on urban area roads is calculated from the modeled speeds and DVMT split by congestion level and road class. The potential on non-urban roads is calculate from the speed data for uncongested roadways. It should also be noted that the the FE benefits only apply to internal combustion engine (ICE) vehicles. Following is a summary of the methodology:
#
#* The calculations use the arrays of speeds and DVMT proportions by marea, congestion level, and road class, and the list of DVMT proportions by marea, road class, and vehicle type described in the previous section.
#
#* The maximum theoretical benefits of speed smoothing and eco-driving for each vehicle type by marea, congestion level, and road class is calculated by applying the smooth-spline models described above to the speed data by marea, congestion level, and road class. For light-duty vehicles, the LdIce model is applied. For heavy trucks and buses, the HdIce model is applied. It is assumed that no-benefits accrue to roads other than freeways and arterials.
#
#* The average fuel economy (FE) benefit of speed smoothing by marea and vehicle type is calculated as follows:
#
#  * The maximum achieveable FE benefits are calculated by multiplying the maximum theoretical benefits by 0.5 (see model estimation section above).
#
#  * The expected FE benefits are calculated by multiplying the maximum achieveable FE benefits for freeways and arterials by the respective user inputs for proportional deployment of speed smoothing on freeways and arterials by marea.
#
#  * The average FE benefits by marea and vehicle type are calculated as a DVMT weighted average of the FE benefits by congestion level and road class for the marea and vehicle type.
#
#* The average FE benefit of eco-driving is calculated for each marea and vehicle type as follows:
#
#  * The achieveable FE benefits for eco-drivers is calculated by multiplying the maximum theoretical benefits for freeways and arterials by 0.33 and 0.21 respectively (see model estimation section).
#
#  * The average achieveable FE benefits for eco-driving on urban roads by marea and vehicle type are calculated as a DVMT weighted average of the FE benefits by congestion level and road class for the marea and vehicle type. The average achieveable FE benefits for eco-driving on non-urban roads is calculated from the FE benefits on uncongested roads by road class and the DVMT by road class.
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

#Create list to hold MPG & MPKWH adjustment parameters
#-----------------------------------------------------
MpgMpkwhAdj_ls <- list()

#----------------------------
#Fuel-Speed Curve Adjustments
#----------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "AdvVehType",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = c("LdIce", "LdHev", "LdEv", "LdFcv", "HdIce"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "FacilityType",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = c("Fwy", "Art"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "CongEff",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = c("Low", "High"),
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("a0", "a1", "a2", "a3", "a4"),
    TYPE = "double",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
VehFSC_df <-
  processEstimationInputs(
    Inp_ls,
    "vehicle_fuel_speed_curves.csv",
    "LoadDefaultValues.R")
#Add to EnergyEmissionsDefaults_ls and clean up
MpgMpkwhAdj_ls$VehFSC_df <- VehFSC_df
#Add freeway and arterial normalization speeds
MpgMpkwhAdj_ls$RefSpeeds_ <- c(
  Fwy = 48.20379,
  Art = 24.43473
)

#Illustrate relationships of fuel economy adjustments with congestion
#--------------------------------------------------------------------
#Define function to calculate fuel economy adjustments
calcAdjBySpd <- function(AdvVehType, FacilityType, Speeds_) {
  #Function to extract coefficients for vehicle and facility type
  getFscCoeff <- function(){
    D_df <- MpgMpkwhAdj_ls$VehFSC_df
    WhichRows_ <- which(D_df$AdvVehType == AdvVehType & D_df$FacilityType == FacilityType)
    CoeffNames_ <- c("a1", "a2", "a3", "a4")
    Coeff_df <- D_df[WhichRows_, CoeffNames_]
    rownames(Coeff_df) <- c("Low", "High")
    as.matrix(Coeff_df)
  }
  #Function to calculate ajustments for one set of coefficients
  calcLowOrHighCoeffAdj <- function(Coeff_) {
    sapply(Speeds_, function(x) {
      SpdTerms_ <-
        c(x, x^2, x^3, x^4) - c(RefSpd, RefSpd^2, RefSpd^3, RefSpd^4)
      exp(sum(Coeff_ * SpdTerms_))
    })
  }
  #Calculate low, high, and weighted average values
  RefSpd <- MpgMpkwhAdj_ls$RefSpeeds_[FacilityType]
  LowVals_ <- calcLowOrHighCoeffAdj(getFscCoeff()["Low",])
  HighVals_ <- calcLowOrHighCoeffAdj(getFscCoeff()["High",])
  MidVals_ <- (LowVals_ + HighVals_) / 2
  #Return matrix of values
  cbind(
    Low = LowVals_,
    Mid = MidVals_,
    High = HighVals_
  )
}
#Calculate fuel economy adjustments for different vehicle types, facility types,
#and speeds by congestion level
Spd_ls <- list(
  Fwy = c(None = 60, Mod = 50.4, Hvy = 44, Sev = 34.3, Ext = 23.5),
  Art = c(None = 30, Mod = 24.9, Hvy = 23.5, Sev = 22.3, Ext = 20.6)
)
Cl <- c("None", "Mod", "Hvy", "Sev", "Ext")
Ft <- c("Fwy", "Art")
Vt <- c("LdIce", "LdHev", "LdEv", "HdIce")
FSC_ls <- list()
for(ft in Ft) {
  FSC_ls[[ft]] <- list()
  for (vt in Vt) {
    FSC_ls[[ft]][[vt]] <- calcAdjBySpd(vt, ft, Spd_ls[[ft]])
  }
}
#Define function to plot results for a facility type
plotFEAdj <- function(FacilityType, ...) {
  Titles_ <- c("Light-duty ICE", "Light-duty HEV", "Light-duty EV", "Heavy-duty ICE")
  names(Titles_) <- Vt
  Opar_ls <- par(mfrow = c(2,2))
  for(vt in Vt) {
    matplot(FSC_ls[[FacilityType]][[vt]][Cl,], type = "l",
            xlab = "Congestion Level",
            ylab = "MPG Adjustment",
            main = Titles_[vt],
            axes = FALSE,
            ...)
    box()
    axis(2)
    axis(1, at = 1:5, labels = Cl)
    legend("bottomleft", legend = c("High CE", "Mid CE", "Low CE"),
           lty = c(3,2,1), col = c(3,2,1), bty = "n")
  }
  par(Opar_ls)
}
#Plot adjustment comparisons for freeways
png("data/fwy_fsc-adj_by_vehicle-type.png", width = 600, height = 600)
plotFEAdj("Fwy", ylim = c(0.2, 1.2))
dev.off()
#Plot adjustment comparisons for arterials
png("data/art_fsc-adj_by_vehicle-type.png", width = 600, height = 600)
plotFEAdj("Art", ylim = c(0.65, 1.3))
dev.off()

#Clean up
rm(Inp_ls, VehFSC_df, calcAdjBySpd, Spd_ls, Cl, Ft, Vt, FSC_ls, plotFEAdj)

#-----------------------------
#Speed Smoothing Effectiveness
#-----------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Speed",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = items(
      "LdIce",
      "HdIce"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
SpeedSmoothEffect_df <-
  processEstimationInputs(
    Inp_ls,
    "max_smooth_improve.csv",
    "LoadDefaultValues.R")
MpgMpkwhAdj_ls$SpeedSmoothEffect_df <- SpeedSmoothEffect_df
#Compute smooth splines for values
MpgMpkwhAdj_ls$LdIceSpdSmthEffect_SS <-
  smooth.spline(SpeedSmoothEffect_df$Speed, SpeedSmoothEffect_df$LdIce)
MpgMpkwhAdj_ls$HdIceSpdSmthEffect_SS <-
  smooth.spline(SpeedSmoothEffect_df$Speed, SpeedSmoothEffect_df$HdIce, df = 5)
#Plot values and smooth splines
png("data/max_speed_smooth_benefit.png", height = 480, width = 480)
Spd_ <- 20:60
plot(SpeedSmoothEffect_df$Speed, SpeedSmoothEffect_df$LdIce, ylim = c(0,1),
     xlab = "Speed (miles / hour)", ylab = "Proportional Improvement")
lines(Spd_, predict(MpgMpkwhAdj_ls$LdIceSpdSmthEffect_SS, Spd_)$y)
points(SpeedSmoothEffect_df$Speed, SpeedSmoothEffect_df$HdIce, col = "red")
lines(Spd_, predict(MpgMpkwhAdj_ls$HdIceSpdSmthEffect_SS, Spd_)$y, col = "red", lty = 2)
legend("topright", col = c(1,2), lty = c(1,2), bty = "n",
       legend = c("LdIce", "HdIce"))
dev.off()
#Ecodriving fraction of maximum benefit
MpgMpkwhAdj_ls$EcoDriveFraction_Rc <- c(Fwy=0.33, Art=0.21)
#Clean up
rm(Inp_ls, SpeedSmoothEffect_df, Spd_)

#-----------------------------------------------------
#Save the model parameters for adjusting MPG and MPkWh
#-----------------------------------------------------
#' MPG and MPkWh adjustment parameters
#'
#' Parameters for adjusting vehicle fuel economy (MPG) for internal combustion
#' engines and electrical energy economy (MPkWh) for plug-in vehicles based
#' on the distribution of vehicle speeds, the deployment of speed-smoothing
#' traffic operations, and eco-driving techniques.
#'
#' @format A list of dataframes and vectors
#' \describe{
#'   \item{VehFSC_df}{a data frame of coefficients for calculating fuel-speed curves for different vehicle types, powertrains, roadways, and congestion efficiency levels},
#'   \item{FwyNormSpd}{the freeway speed corresponding to average fuel economy ratings}
#'   \item{ArtNormSpd}{the arterial speed corresponding to average fuel economy ratings}
#'   \item{SpeedSmoothEffect_df}{a data frame of coeffients of maximum speed smoothing effectiveness in reducing fuel consumption by speed for light duty and for heavy duty internal combustion engine vehicles}
#'   \item{EcoDriveFraction_Rc}{a vector of values identifying the maximum fraction of fuel savings that can be had with ecodriving on freeways and on arterials}
#' }
#' @source CalculateMpgMpkwhAdjustments.R script.
"MpgMpkwhAdj_ls"
usethis::use_data(MpgMpkwhAdj_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateMpgMpkwhAdjustmentsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "FwySmooth",
          "ArtSmooth",
          "LdvEcoDrive",
          "HvyTrkEcoDrive"
        ),
      FILE = "marea_speed_smooth_ecodrive.csv",
      TABLE = "Marea",
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
        items(
          "Fractional deployment of speed smoothing traffic management on freeways, where 0 is no deployment and 1 is the full potential fuel savings",
          "Fractional deployment of speed smoothing traffic management on arterials, where 0 is no deployment and 1 is the full potential fuel savings",
          "Eco-driving penetration for light-duty vehicles; the fraction of vehicles from 0 to 1",
          "Eco-driving penetration for heavy-duty vehicles; the fraction of vehicles from 0 to 1"
        )
    )
  ),
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
      NAME =
        items(
          "FwySmooth",
          "ArtSmooth"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
      ),
    item(
      NAME =
        items(
          "LdvFwyDvmt",
          "LdvArtDvmt",
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
        "OthSpd"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
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
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = items(
        "LdvSpdSmoothFactor",
        "HvyTrkSpdSmoothFactor",
        "BusSpdSmoothFactor",
        "LdvEcoDriveFactor",
        "HvyTrkEcoDriveFactor",
        "BusEcoDriveFactor",
        "LdIceFactor",
        "LdHevFactor",
        "LdEvFactor",
        "LdFcvFactor",
        "HdIceFactor"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to speed smoothing",
          "Proportional adjustment of heavy truck internal combustion engine (ICE) vehicle MPG due to speed smoothing",
          "Proportional adjustment of bus internal combustion engine (ICE) vehicle MPG due to speed smoothing",
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to eco-driving",
          "Proportional adjustment of heavy truck internal combustion engine (ICE) vehicle MPG due to eco-driving",
          "Proportional adjustment of bus internal combustion engine (ICE) vehicle MPG due to eco-driving",
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to congestion",
          "Proportional adjustment of light-duty hybrid-electric vehicle (HEV) MPG due to congestion",
          "Proportional adjustment of light-duty battery electric vehicle (EV) MPkWh due to congestion",
          "Proportional adjustment of light-duty fuel cell vehicle (FCV) MPkWh due to congestion",
          "Proportional adjustment of heavy-duty internal combustion engine (ICE) vehicle MPG due to congestion")
    ),
    item(
      NAME = items(
        "LdvEcoDriveFactor",
        "HvyTrkEcoDriveFactor",
        "BusEcoDriveFactor",
        "LdIceFactor",
        "LdHevFactor",
        "LdEvFactor",
        "LdFcvFactor",
        "HdIceFactor"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG due to eco-driving in uncongested conditions",
          "Proportional adjustment of heavy truck internal combustion engine (ICE) vehicle MPG due to eco-driving in uncongested conditions",
          "Proportional adjustment of bus internal combustion engine (ICE) vehicle MPG due to eco-driving in uncongested conditions",
          "Proportional adjustment of light-duty internal combustion engine (ICE) vehicle MPG in uncongested conditions",
          "Proportional adjustment of light-duty hybrid-electric vehicle (HEV) MPG in uncongested conditions",
          "Proportional adjustment of light-duty battery electric vehicle (EV) MPkWh in uncongested conditions",
          "Proportional adjustment of light-duty fuel cell vehicle (FCV) MPkWh in uncongested conditions",
          "Proportional adjustment of heavy-duty internal combustion engine (ICE) vehicle MPG in uncongested conditions")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateMpgMpkwhAdjustments module
#'
#' A list containing specifications for the CalculateCarbonIntensity module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateMpgMpkwhAdjustments.R script.
"CalculateMpgMpkwhAdjustmentsSpecifications"
usethis::use_data(CalculateMpgMpkwhAdjustmentsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates factors for adjusting the fuel economy (MPG) and
#electric energy efficiency (MPkWh) of vehicles of different type in different
#Mareas as due to speed smoothing (i.e. reducing speed variation as a result of
#active traffic management measures), eco-driving behavior, and roadway
#congestion.

#Main module function that calculates MPG/MPkWh adjustment factors
#-----------------------------------------------------------------
#' Main function to calculate MPG/MPkWh adjustment factors.
#'
#' \code{CalculateMpgMpkwhAdjustments} calculates MPG and MPkWh adjustment
#' factors for the effects of speed smoothing, eco-driving, and congestion.
#'
#' This function calculates factors for adjusting the fuel economy (MPG) and
#' electric energy efficiency (MPkWh) of vehicles of different type in different
#' Mareas as due to speed smoothing (i.e. reducing speed variation as a result
#' of active traffic management measures), eco-driving behavior, and roadway
#' congestion.
#'
#' @param L A list containing data requested by the module from the datastore.
#' @return A list containing data identified in the module Set specifications.
#' @name CalculateMpgMpkwhAdjustments
#' @import visioneval stats
#' @export
CalculateMpgMpkwhAdjustments <- function(L) {
  #------
  #SET UP
  #------
  #Create indexing vectors
  Ma <- L$Year$Marea$Marea
  Cl <- c("None", "Mod", "Hvy", "Sev", "Ext")
  Rc <- c("Fwy", "Art", "Oth")
  #Load energy and emissions defaults
  EnergyEmissionsDefaults_ls <- loadPackageDataset("PowertrainFuelDefaults_ls")

  #Create arrays of speeds and congested DVMT proportions by Marea, congestion
  #level, and road class, and DVMT proportion by road class by vehicle type
  #---------------------------------------------------------------------------
  #Note that since there is no model for congestion on 'other' roads, the speed
  #for those roads is set to be the L$Year$Marea$OthSpd for all congestion
  #levels and the DVMT proportions are divided equally among all congestion
  #levels
  #Speed Array
  Speed_MaClRc <-
    array(0, dim = c(length(Ma), length(Cl), length(Rc)), dimnames = list(Ma, Cl, Rc))
  Speed_MaClRc[,,"Fwy"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("Fwy", Cl, "CongSpeed")]))
  Speed_MaClRc[,,"Art"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("Art", Cl, "CongSpeed")]))
  Speed_MaClRc[,,"Oth"] <- L$Year$Marea$OthSpd
  #Congested DVMT proportions
  CongProp_MaClRc <-
    array(0, dim = c(length(Ma), length(Cl), length(Rc)), dimnames = list(Ma, Cl, Rc))
  CongProp_MaClRc[,,"Fwy"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("FwyDvmtProp", Cl, "Cong")]))
  CongProp_MaClRc[,,"Art"] <-
    as.matrix(data.frame(L$Year$Marea[paste0("ArtDvmtProp", Cl, "Cong")]))
  CongProp_MaClRc[,,"Oth"] <- array(0.2, dim = c(length(Ma), 5))
  #Calculate DVMT proportions by road class for each vehicle type
  DvmtNames_ <- c("FwyDvmt", "ArtDvmt", "OthDvmt")
  Vt <- c("Ldv", "HvyTrk", "Bus")
  DvmtProp_ls <- lapply(Vt, function(x) {
    Dvmt_MaRc <- as.matrix(data.frame(L$Year$Marea[paste0(x, DvmtNames_)]))
    rownames(Dvmt_MaRc) <- Ma
    colnames(Dvmt_MaRc) <- c("Fwy", "Art", "Oth")
    sweep(Dvmt_MaRc, 1, rowSums(Dvmt_MaRc), "/")
  })
  names(DvmtProp_ls) <- Vt

  #-------------------------------------------------------------------------
  #CALCULATE MAXIMUM SPEED-SMOOTH/ECO-DRIVE FACTORS AT EACH CONGESTION LEVEL
  #-------------------------------------------------------------------------
  #Calculates speed smoothing maximum factors by road class for a given vehicle
  #type based on the estimated congested speeds
  calcMaxSpdSmAdj <- function(vt) {
    #Choose the speed smoothing factor model
    if (vt == "Ldv"){
      SpdSm_SS <- MpgMpkwhAdj_ls$LdIceSpdSmthEffect_SS
    } else {
      SpdSm_SS <- MpgMpkwhAdj_ls$HdIceSpdSmthEffect_SS
    }
    #Apply speed smoothing factor model to speeds by congestion level
    SpdSmMaxFactor_MaClRc <- Speed_MaClRc * 0
    for (ma in Ma) {
      Speed_ClRc <- Speed_MaClRc[ma,,]
      SpdSmFactor_ClRc <- apply(Speed_ClRc, 2, function(x) {
        predict(SpdSm_SS, x)$y })
      SpdSmFactor_ClRc[,"Oth"] <- 0
      SpdSmMaxFactor_MaClRc[ma,,] <- SpdSmFactor_ClRc
    }
    #Return the result
    SpdSmMaxFactor_MaClRc
  }
  #Calculate the speed smoothing maximum factors by vehicle type
  SpdSmMaxFactors_ls <- lapply(Vt, calcMaxSpdSmAdj)
  names(SpdSmMaxFactors_ls) <- Vt

  #-----------------------------------------------------
  #CALCULATE SPEED SMOOTHING ADJUSTMENTS BY VEHICLE TYPE
  #-----------------------------------------------------
  #Function calculates average speed smoothing adjustment by vehicle type
  calcAveSpdSmAdj <- function(vt, ma) {
    #Calculate DVMT proportions by Cl and Rc for each Marea
    DvmtProp_Rc <- DvmtProp_ls[[vt]][ma,]
    DvmtProp_ClRc <-
      sweep(CongProp_MaClRc[ma,,], 2, DvmtProp_Rc, "*")
    #Calculate freeway and arterial smoothing fractions
    SmoothFractions_Rc <- c(
      Fwy = L$Year$Marea$FwySmooth[L$Year$Marea$Marea == ma],
      Art = L$Year$Marea$ArtSmooth[L$Year$Marea$Marea == ma],
      Oth = 0
    ) * 0.5
    #Calculate the smoothing factors from the maximum values for the vehicle
    #type and the smoothing fractions
    SpdSmMaxFactor_ClRc <- SpdSmMaxFactors_ls[[vt]][ma,,]
    SpdSmFactor_ClRc <-
      sweep(SpdSmMaxFactor_ClRc, 2, SmoothFractions_Rc, "*") + 1
    #Calculate the weighted average factor
    sum(SpdSmFactor_ClRc * DvmtProp_ClRc)
  }
  #Calculate average speed smooth factors by marea and vehicle type
  AveSmoothFactors_MaVt <-
    array(1, dim = c(length(Ma), length(Vt)), dimnames = list(Ma, Vt))
  for (ma in Ma) {
    AveSmoothFactors_MaVt[ma,] <- sapply(Vt, function(x) calcAveSpdSmAdj(x, ma))
  }

  #-------------------------------------------------
  #CALCULATE ECO-DRIVING ADJUSTMENTS BY VEHICLE TYPE
  #-------------------------------------------------
  #Define function to calculate the average ecodriving adjustment by vehicle type
  calcAveEcoDrAdj <- function(vt, ma) {
    #Calculate DVMT proportions by Cl and Rc for each Marea
    DvmtProp_Rc <- DvmtProp_ls[[vt]][ma,]
    DvmtProp_ClRc <-
      sweep(CongProp_MaClRc[ma,,], 2, DvmtProp_Rc, "*")
    #Calculate the eco-driving benefits
    MaxBenefitFraction_Rc <- MpgMpkwhAdj_ls$EcoDriveFraction_Rc
    MaxBenefitFraction_Rc <- c(MaxBenefitFraction_Rc, Oth = 0)
    SpdSmMaxFactor_ClRc <- SpdSmMaxFactors_ls[[vt]][ma,,]
    EcoDrFactor_ClRc <-
        sweep(SpdSmMaxFactor_ClRc, 2, MaxBenefitFraction_Rc, "*") + 1
    #Calculate weighted average factor for urban areas and average uncongested value
    #for rural areas.
    c(
      WtAve = sum(DvmtProp_ClRc * EcoDrFactor_ClRc),
      Ff = sum(DvmtProp_Rc * EcoDrFactor_ClRc["None",])
    )
  }
  #Calculate average eco-drive factors by marea and vehicle type
  EcoDrive_ls <- list()
  for (ma in Ma) {
    EcoDrive_ls[[ma]] <- sapply(Vt, function(x) calcAveEcoDrAdj(x, ma))
  }
  AveEcoDriveFactors_MaVt <- do.call(rbind, lapply(EcoDrive_ls, function(x) x["WtAve",]))
  AveEcoDriveFactorsFf_MaVt <- do.call(rbind, lapply(EcoDrive_ls, function(x) x["Ff",]))
  AveEcoDriveFactorsFf_Vt <- apply(AveEcoDriveFactorsFf_MaVt, 2, min)
  rm(EcoDrive_ls, AveEcoDriveFactorsFf_MaVt)

  #-----------------------------------------------------------
  #CALCULATE CONGESTION ADJUSTMENTS BY VEHICLE/POWERTRAIN TYPE
  #-----------------------------------------------------------
  #Function to calculate adjustments for a vehicle/powertrain and road type
  calcAdjByCl <- function(LowCoeff_, HighCoeff_, CongEff, Speeds_, RefSpd) {
    #Function to calculate ajustments for one set of coefficients
    calcLowOrHighCoeffAdj <- function(Coeff_) {
      sapply(Speeds_, function(x) {
        SpdTerms_ <-
          c(x, x^2, x^3, x^4) - c(RefSpd, RefSpd^2, RefSpd^3, RefSpd^4)
        exp(sum(Coeff_ * SpdTerms_))
      })
    }
    #Calculate low, high, and weighted average values
    LowVals_ <- calcLowOrHighCoeffAdj(LowCoeff_)
    HighVals_ <- calcLowOrHighCoeffAdj(HighCoeff_)
    LowVals_ * (1 - CongEff) + HighVals_ * CongEff
  }

  #Function to extract the adjustment model coefficients
  #-----------------------------------------------------
  getModelCoeff <- function(VehPtType, ft) {
    CoeffNames_ <- c("a1", "a2", "a3", "a4")
    Coeff_mx <-
      subset(MpgMpkwhAdj_ls$VehFSC_df,
             AdvVehType == VehPtType & FacilityType == ft)[,CoeffNames_]
    rownames(Coeff_mx) <-
      subset(MpgMpkwhAdj_ls$VehFSC_df,
             AdvVehType == VehPtType & FacilityType == ft)[,"CongEff"]
    Coeff_mx
  }

  #Function to calculate average adjustment for a vehicle/powertrain type
  #----------------------------------------------------------------------
  calcMpgMpkwhAdj <- function(VehPtType, Marea) {
    if (VehPtType %in% c("LdIce", "LdHev", "LdEv", "LdFcv")) {
      VehType <- "Ldv"
    } else {
      VehType <- "HvyTrk"
    }
    #Get speeds by congestion level and road class by Marea
    Speed_ClRc <- Speed_MaClRc[Marea,,]
    #Initialize an adjustments matrix by congestion level and road class
    Adj_ClRc <- Speed_ClRc * 0
    #Reference speeds
    RefSpd_ <- c(
      MpgMpkwhAdj_ls$RefSpeeds_,
      Oth = L$Year$Marea$OthSpd
    )
    #Iterate by road class and calculate adjustments
    for (ft in c("Fwy", "Art", "Oth")) {
      #Get model coefficients and reference speed
      if (ft == "Oth") {
        Coeff_mx <- getModelCoeff(VehPtType, "Art")
        RefSpd <- MpgMpkwhAdj_ls$RefSpeeds_["Art"]
      } else {
        Coeff_mx <- getModelCoeff(VehPtType, ft)
        RefSpd <- MpgMpkwhAdj_ls$RefSpeeds_[ft]
      }
      #Get the congestion efficiency level
      YearIdx <-
        which(EnergyEmissionsDefaults_ls$CongestionEfficiency_df$Year == L$G$Year)
      CongEff <-
        EnergyEmissionsDefaults_ls$CongestionEfficiency_df[YearIdx, VehPtType]
      #Get the reference speed

      #Calculate adjustments by congestion level
      Adj_ClRc[,ft] <-
        calcAdjByCl(Coeff_mx["Low",], Coeff_mx["High",], CongEff, Speed_ClRc[,ft], RefSpd_[ft])
    }
    #Calculate weighted average value for urban areas and uncongested average for rural areas
    DvmtProp_Rc <- DvmtProp_ls[[VehType]][Marea,]
    DvmtProp_ClRc <-
      sweep(CongProp_MaClRc[Marea,,], 2, DvmtProp_Rc, "*")
    c(
      WtAve = sum(DvmtProp_ClRc * Adj_ClRc),
      Ff = sum(DvmtProp_Rc * Adj_ClRc["None",])
    )
  }

  #Calculate congestion adjustments by Marea and vehicle/powertrain type
  #---------------------------------------------------------------------
  # Initialize a vector to store adjustments to Hydrocarbon and Electric driving
  Vp <- c("LdIce", "LdHev", "LdEv", "LdFcv", "HdIce")
  Adj_ls <- list()
  for (ma in Ma) {
    Adj_ls[[ma]] <- sapply(Vp, function(x) calcMpgMpkwhAdj(x, ma))
  }
  MpgMpkwhAdj_MaVp <- do.call(rbind, lapply(Adj_ls, function(x) x["WtAve",]))
  MpgMpkwhAdjFf_MaVp <- do.call(rbind, lapply(Adj_ls, function(x) x["Ff",]))
  MpgMpkwhAdjFf_Vp <- apply(MpgMpkwhAdjFf_MaVp, 2, min)

  #------------------
  #RETURN THE RESULTS
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Marea <- list(
    LdvSpdSmoothFactor = AveSmoothFactors_MaVt[,"Ldv"],
    HvyTrkSpdSmoothFactor = AveSmoothFactors_MaVt[,"HvyTrk"],
    BusSpdSmoothFactor = AveSmoothFactors_MaVt[,"Bus"],
    LdvEcoDriveFactor = AveEcoDriveFactors_MaVt[,"Ldv"],
    HvyTrkEcoDriveFactor = AveEcoDriveFactors_MaVt[,"HvyTrk"],
    BusEcoDriveFactor = AveEcoDriveFactors_MaVt[,"Bus"],
    LdIceFactor = MpgMpkwhAdj_MaVp[,"LdIce"],
    LdHevFactor = MpgMpkwhAdj_MaVp[,"LdHev"],
    LdEvFactor = MpgMpkwhAdj_MaVp[,"LdEv"],
    LdFcvFactor = MpgMpkwhAdj_MaVp[,"LdFcv"],
    HdIceFactor = MpgMpkwhAdj_MaVp[,"HdIce"]
  )
  Out_ls$Year$Region <- list(
    LdvEcoDriveFactor = AveEcoDriveFactorsFf_Vt["Ldv"],
    HvyTrkEcoDriveFactor = AveEcoDriveFactorsFf_Vt["HvyTrk"],
    BusEcoDriveFactor = AveEcoDriveFactorsFf_Vt["Bus"],
    LdIceFactor = MpgMpkwhAdjFf_Vp["LdIce"],
    LdHevFactor = MpgMpkwhAdjFf_Vp["LdHev"],
    LdEvFactor = MpgMpkwhAdjFf_Vp["LdEv"],
    LdFcvFactor = MpgMpkwhAdjFf_Vp["LdFcv"],
    HdIceFactor = MpgMpkwhAdjFf_Vp["HdIce"]
  )
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculateMpgMpkwhAdjustments")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateMpgMpkwhAdjustments",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# TestOut_ls <- CalculateMpgMpkwhAdjustments(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateMpgMpkwhAdjustments",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

