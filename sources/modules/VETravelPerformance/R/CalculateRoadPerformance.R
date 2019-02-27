#==========================
#CalculateRoadPerformance.R
#==========================

#<doc>
#
## CalculateRoadPerformance Module
#### January 23, 2019
#
#This module calculates freeway and arterial congestion level and the amounts of DVMT by congestion level. It also calculates the average speed and delay at each congestion level. In addition, it splits light-duty vehicle (LDV) DVMT between freeways and arterials as a function of relative speeds and congestion prices. The following performance measures are saved to the datastore:
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
#The module uses several estimated models to perform all the calculations. Following are brief descriptions of each model.
#
#### Model of Congestion as a Function of Daily Demand
#
# This module predicts the proportions of freeway DVMT at each of the 5 congestion levels as a function of the ratio of the ratio of total freeway DVMT and total freeway lane-miles. Lookup tables (one for freeways and another for arterials) are created which specify DVMT proportions by congestion level at different aggregate demand-supply ratios. The lookup tables are created using data from the 2009 Urban Mobility Study (UMS) for 90 urbanized areas including the following. These data are included in the inst/extdata directory of the package:
#
#* Average daily freeway vehicle miles traveled in thousands;
#
#* Average daily arterial vehicle miles traveled in thousands;
#
#* Freeway lane miles
#
#* Arterial lane miles
#
#* Percentages of freeway DVMT occurring in each of the 5 congestion levels
#
#* Percentages of arterial DVMT occurring in each of the 5 congestion levels
#
#The steps for creating the lookup tables are as follows:
#
#1. The freeway demand levels and arterial demand levels are calculated for each urbanized area by dividing the respective value of DVMT by the respective number of lane miles. The result is the average daily traffic volume per lane-mile.
#
#2. A lookup table relating the proportions of freeway DVMT by congestion level to freeway demand level is created using a weighted moving averages method. Values are calculated for freeway demand-supply ratios ranging from 6000 vehicles per lane to 24,000 vehicles per lane in 100 vehicle increments. For each demand level, the data for the 10 urbanized areas whose demand-supply ratio is nearest the target level -- 5 below and 5 above -- are chosen. If there are less than 5 below the target then the sample includes all that are below and 5 above. Similarly if there are less then 5 above the sample target. The DVMT proportions for each congestion level are computed as a weighted average of the proportions in the sample where the weights measure how close the demand level of each sample urbanized area is to the target demand level. After weighted averages have been calculated for all freeway demand levels, smoothing splines (5 degrees of freedom) are used to smooth out the values for each congestion level over the range of demand levels. The freeway lookup table is created from the result.
#
#3. A lookup table relating the proportions of arterial DVMT by congestion level to arterial demand-supply ratio is created by the same method used to create the freeway table.
#
#The following figures illustrate the freeway and arterial lookup tables respectively:
#
#<fig:fwy_dvmt_cong_prop.png>
#
#**Figure 1. Freeway DVMT Proportions by Congestion Level and ADT per Lane Ratio**
#
#<fig:art_dvmt_cong_prop.png>
#
#**Figure 2. Arterial DVMT Proportions by Congestion Level and ADT per Lane Ratio**
#
#### Model of Congested Speeds and the Effects of Operations Programs (e.g. ramp metering, signal coordination)
#
#The module calculates expected average speed and delay at each congestion level for freeways and for arterials considering the effects of deploying 4 standards operations programs (freeway ramp metering, freeway incident management, arterial signal coordination, arterial access control) and optional user-defined operations programs (e.g. freeway active traffic management). Several lookup tables are used to estimate speeds, delays, and delay reductions due to operations programs. These tables are based on research by Bigazzi and Clifton documented in the 'Bigazzi_Task-2_Final_Report.pdf' file in the inst/extdata/sources directory of this package.
#
#The following table maps base speeds for freeways and for arterials by congestion level. Base speeds are the expected speeds with no operations program deployments. The columns labeled 'Fwy' and 'Art' in the table show expected base speeds considering both recurring and non-recurring congestion effects. The columns labeled 'Fwy_Rcr' and 'Art_Rcr' show base speeds considering only recurring congestion effects. Recurring congestion effects are the effects of increased traffic density on travel speed not considering the effect of crashes or other incidents that may also occur. Non-recurring congestion effects are the effects of crashes or other incidents on travel speed.
#
#<tab:BaseSpeeds_df>
#
#**Table 1. Base Average Traffic Speed (miles/hour) by Congestion Level**
#
#Average vehicle delay is calculated for each congestion level from the base speeds table. Delay is the difference between the travel rate (the inverse of travel speed) when the roadway is congested and the travel rate when there is no congestion. The following table shows travel delay (hours per mile) by congestion level. Note that this table is laid out differently than the speed table. In the delay table the 'Fwy_Rcr' and 'Art_Rcr' columns show estimated freeway and arterial delays due only to recurring congestion effects. The 'Fwy_NonRcr' and 'Art_NonRcr' columns show estimated delays due only to non-recurring congestion effects. The non-recurring congestion delays are calculated by subtracting the recurring congestion delays from total delay calculated from the speeds table.
#
#<tab:Delay_df>
#
#**Table 2. Base Travel Delay (hours/mile) by Congestion Type and Level**
#
#The model calculates the effects of operations programs on congested speeds by adjusting the recurring and non-recurring delays and then translating delay values back into speeds. The effectiveness of the four common operations programs on reducing recurring and non-recurring delay is documented in the report by Bigazzi and Clifton. The following table shows the average percentage reduction in recurring and non-recurring freeway delay with full deployment of freeway ramp metering.
#
#<tab:Ramp_df>
#
#**Table 3. Percentage Reduction in Delay with Full Deployment of Freeway Ramp Metering**
#
#The following table shows the average percentage reduction in non-recurring freeway delay with full deployment of incident management.
#
#<tab:Incident_df>
#
#**Table 4. Percentage Reduction in Delay with Full Deployment of Freeway Incident Management**
#
#The following table shows the average percentage reduction in arterial recurring delay with full deployment of signal coordination.
#
#<tab:Signal_df>
#
#**Table 5. Percentage Reduction in Delay with Full Deployment of Arterial Signal Coordination**
#
#The following table shows the average percentage reduction in arterial recurring and non-recurring delay with full deployment of access management. Note that recurring delay increases due to increased out-of-direction travel caused by barrier medians but non-recurring delay decreases due to the prevention of crashes by those same barrier medians.
#
#<tab:Access_df>
#
#**Table 6. Percentage Reduction in Delay with Full Deployment of Arterial Access Management**
#
#In addition to these four standard operations programs, the user may specify the deployment of other custom operations programs such as freeway and arterial active traffic management using the 'other_ops_effectiveness.csv' file to specify the percentage reduction in recurring and non-recurring delays expected with full deployment.
#
#In application, the percentage reductions shown in each of these tables is multiplied by the extent of deployment of the respective operations programs (i.e. the proportion of freeway or arterial DVMT affected) to calculate the percentage reductions at the deployment levels specified in the 'marea_operations_deployment.csv' file. The resulting percentage reductions are converted into proportions of base delay (e.g. 10% reduction means delay is 0.9 times base delay). The total effect of all operations programs is calculated by multiplying their respective delay proportions by congestion type and level. For example, the combined effect of a 5% reduction in extreme non-recurring congestion delay due to ramp metering and a 10% reduction in extreme non-recurring congestion delay due to incident management is not 15%. The delay is `0.95 * 0.9` times the base delay, meaning that the percentage reduction is 14.5%.
#
#### Model of the Split of Light-duty Vehicle (LDV) DVMT between Freeways and Arterials
#
#Unlike heavy truck DVMT or bus DVMT, LDV DVMT is not split between freeways and arterials using a fixed ratio. Instead, it is split dynamically as a function of the ratio of the respective average travel speeds and an urbanized area specific factor (lambda).
#
# `FwyDvmt / ArtDvmt = lambda * FwySpeed / ArtSpeed`
#
#A linear model is estimated to calculate the value of lambda that is representative for an urbanized area. The aforementioned Urban Mobility Study data were used to estimate this model. These data include estimates of average freeway speed and average arterial speed by congestion level for each of the 90 urbanized areas as well as freeway and arterial DVMT by congestion level. Overall average freeway speed (and likewise average arterial speed) for each urbanized area is calculated as a weighted average of the speeds by congestion level where the weights are the DVMT by congestion level. From these data, the ratios of freeway and arterial DVMT and freeway and arterial speeds are computed for each of the urbanized areas. The ratios of those ratios is the lambda value for the urbanized area which satisfies the relationship. A model is estimated to predict the likely value of lambda given a few characteristics of the urbanized area. Following is a summary of the estimated model where `LogPop`is the natural log of the urbanized area population and `LnMiRatio` is the ratio of freeway and arterial lane-miles:
#
#<txt:DvmtSplit_LM$Summary>
#
#**Figure 3. Summary Statistics for LDV DVMT Split Model**
#
#As can be seen, both of the independent variables are highly significant. The proportion of DVMT occurring on freeways increases with the urbanized area population and the relative supply of freeway capacity. The following set of plots show the several indicators of model fit.
#
#<fig:lambda_model_plots.png>
#
#**Figure 4. Diagnostic Plots for LDV DVMT Split Model**
#
#The estimated LDV DVMT split model predicts the average lambda relationship given a simple set of predictors. The model accounts for about 70% of the observed variation. As can be seen in Figure 4, there is a substantial amount of residual variation due to relevant attributes unaccounted for in the model (e.g. interchange density) and inaccuracies in the estimation dataset. If the model is applied as is to split freeway and arterial DVMT for an urbanized area, the results will not correspond to observed measurements in almost all cases. This is compensated for by calculating an additive lambda adjustment factor for the urbanized area in the base year so that the modeled LDV DVMT split is the same as the base year split processed by the Initialize module. The process for calculating the lambda adjustment factor is described in the next section. The additive lambda adjustment is equivalent to an additive adjustment to the constant in the model equation to account for other factors not accounted for in the model equation and data inaccuracies.
#
#### Model to Calculate Average Non-urban Road Speed from Average Urban Road Speed
#
#The speed models presented above only address travel on urbanized area roads, but speeds are needed as well for roads outside of urbanized areas because not all household vehicle travel occurs on urbanized area roads. The portion of household travel on urbanized area roadways is calculated by the 'CalculateRoadDvmt' module. This section describes the model developed to calculate the ratio of roadway speeds in non-urbanized (rural) areas and urbanized (urban) areas.
#
#Unfortunately, and surprisingly given the amount of vehicle speed data being collected nowadays, there appears to be no current sources of urban and rural roadway average speeds for the U.S. that can be used to calculate the rural to urban roadway speed ratio. The only source that the author could find to compare average rural and urban speeds is the National Household Travel Survey (NHTS) which provides information on average vehicle trip distances and durations for households living inside and outside of urbanized areas. Table 7 shows the 2017 distance and duration data by census region.
#
#<tab:UrbanRuralAveSpeed_ls$NhtsTripDistTime_df>
#
#**Table 7. 2017 NHTS Average Urban and Rural Household Vehicle Trip Distances (miles) and Durations (minutes)
#
#Average urban and rural household vehicle trip speeds (miles per hour) and the ratio of rural and urban speed averages are calculated from these data. The results are in Table 8. The overall national average ratio is used in the model. Advanced users may customize the module for their region by changing this script to select the ratio for one of the listed regions.
#
#<tab:UrbanRuralAveSpeed_ls$NhtsSpeed_df>
#
#**Table 8. Average Urban and Rural Household Vehicle Trip Speeds (miles per hour) and Speed Ratio**
#
#Unfortunately, the average household vehicle speed ratio is not a clean representation of the rural and urban road speed ratio because rural households travel some on urban roads and urban households travel some on rural roads. However, since the urban road travel proportions of households are calculated by the 'CalculateRoadDvmt' module it is possible to estimate the road speed ratio using the household speed ratio. This is done in the following equations. Equation 1 shows the calculation of rural household speed from the urban travel proportion of rural households, urban road speed, and ratio of rural to urban road speed.
#
#![](rural_household_speed_eq_1.png)
#
#**Equation 1. Calculation of Rural Household Speed**
#
#Where:
#
#* *RHS* = rural household speed
#* *URS* = urban road speed
#* *RHPU* = rural household proportion urban DVMT
#* *RSR* = road speed ratio
#
#If a similar equation is formulated for calculating urban household average vehicle speed and that equation is divided into Equation 1, we get the equation for calculating the ratio of rural to urban household average vehicle speed as shown in Equation 2.
#
#![](household_speed_ratio_eq_2.png)
#
#**Equation 2. Calculation of Household Speed Ratio**
#
#Where:
#
#* *HSR* = household speed ratio
#* *UHPU* = urban household proportion of urban DVMT
#
#Solving for the road speed ratio (RSR) yields Equation 3.
#
#![](road_speed_ratio_eq_3.png)
#
#**Equation 3. Calculation of Road Speed Ratio**
#
#Where:
#
#* *RSR* = road speed ratio
#
#The module applies this function to calculate the rural to urban road speed ratio from the rural to urban household speed ratio derived from the NHTS and the respective proportions of household DVMT on urban roadways for rural and urban households. The ratio, calculated by marea, is then applied to the average urban LDV speed calculated for the marea to derive the average rural LDV speed. Some guards are applied to assure that the results are sensible because some combinations of rural and urban household DVMT proportions (however unlikely) can produce road speed ratios that result in unlikely average rural road speeds.
#
### How the Module Works
#
#This module models traffic congestion in urbanized areas and the effects of congestion on vehicle speeds and delays. In the process, it splits the freeway-arterial light-duty vehicle (LDV) DVMT forecast into freeway and arterial components as a function of the respective speeds and congestion charges on freeways and arterials. Outputs of the module include the following:
#
#* Average speed by marea and vehicle type (LDV, heavy truck, bus) for urban areas
#
#* Total delay by marea and vehicle type for urban areas
#
#* Average congestion charge by marea per vehicle mile
#
#Following are the procedures the module caries out:
#
#* **Calculate lambda**: The model for determining the value of lambda (described above) is applied for each metropolitan area. In addition, if the model run year is not the base year, the marea lambda adjustment values are also loaded. The procedures for calculating the lambda adjustment values in the base year are described below.
#
#* **Calculate speed and delay by congestion level**: The speed and delay models described above are applied to calculate speed and delay by congestion level on urban freeways and arterials in the urban portion of each marea (i.e. the urbanized area) considering the deployment of operations programs.
#
#* **Load and structure data on DVMT and prices**: Urban DVMT data by vehicle type (LDV, heavy truck, bus) and marea is loaded from the datastore and structured to facilitate computation. Similarly congestion pricing data is loaded and structured.
#
#* **Define function to calculate average equivalent speed**: Since both average speeds and pricing affect the balance of LDV DVMT on freeways and arterials, the two need to be represented in equivalent terms. The function which does this does the following to create a composite value for freeways or arterials when supplied the necessary data:
#
# * Daily vehicle hours of travel (DVHT) is calculated by dividing the DVMT by congestion level by the average speed by congestion level and summing the result.
#
# * Congestion pricing is converted into a vehicle time equivalent (i.e. DVHT) by multiplying the DVMT by congestion level by the congestion price by congestion level, summing to calculate total paid by vehicles, and dividing by the value-of-time model parameter.
#
# * The sum of DVHT and the DVHT equivalent of congestion pricing is divided into the DVMT to arrive at the equivalent average speed.
#
#* **Define function to calculate freeway and arterial congestion and split LDV DVMT**: Since relative speeds affect the split of LDV DVMT between freeways and arterials and since those speeds are affected by how the split effects congestion, the calculations are performed iteratively until an equilibrium condition is achieved. That is determined to have happened when the freeway to arterial DVMT ratio changes by less than 0.01% from iteration to iteration. The iterations are started with the assumption that average freeway speeds and average arterial speeds are the respective uncongested speeds (Table 1). The steps in each iteration are as follows:
#
# * The LDV DVMT split model is applied to calculate the freeway and arterial components of LDV DVMT.
#
# * Heavy truck DVMT by road type and bus DVMT by road type are added to the LDV DVMT by road type to calculate total freeway DVMT and total arterial DVMT.
#
# * The freeway-arterial DVMT ratio is calculated and compared with the ratio calculated in the previous iteration. If it differs by less than 0.01% the iterations stop. In the first iteration, the DVMT ratio is compared to 1.
#
# * The freeway and arterial congestion models are used to split freeway DVMT by congestion level and split arterial DVMT by congestion level.
#
# * The average equivalent freeway speed and the average equivalent arterial speed are calculated using the function described above.
#
#* **Calculate lamba adjustment factor if base year**: If the model is being run for the base year, a lambda adjustment factor must be calculated for each marea to calibrate the LDV DVMT split model so that the LDV DVMT split for the base year (see Initialize module) is replicated. A binary search procedure is used to calculate the lambda adjustment factor for each marea. In each iteration of the binary search process, the previously described function to calculate congestion and split LDV DVMT is run and the resulting freeway-arterial ratio of LDV DVMT is compared with the observed base year ratio. The search process continues until the two ratios closely match.
#
#* **Calculate freeway and arterial congestion**: The function to calculate freeway and arterial congestion (described above) is run to calculate freeway and arterial DVMT by congestion level and DVMT by vehicle type and road class.
#
#* **Calculate performance measures**: The module computes several performance measures for each marea. These include average speed by vehicle type, total vehicle hours of delay by vehicle type, and average congestion charge per vehicle mile. These performance measures are module outputs that are written to the datastore. Additional module outputs are freeway LDV DVMT and arterial LDV DVMT for each marea, and the lambda adjustment factors. In addition, the module outputs proportions of freeway and arterial DVMT by congestion level and freeway and arterials speeds by congestion level. Those data are used by the 'CalculateMpgMpkwhAdjustments' module to calculate the effects of urban area congestion on fuel economy and electric vehicle efficiency.
#
#</doc>


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
# proportions of freeway and arterial daily vehicle miles of travel (DVMT)
# in each of 5 congestion levels (none,
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
    Fwy = createLookupTable(FwyDemandLvl_, FwyCongVmtProp_df, c(6000, 24000)),
    Art = createLookupTable(ArtDemandLvl_, ArtCongVmtProp_df, c(2000, 9000))
  )
}

#Estimate the congestion model (lookup tables)
#---------------------------------------------
#Create proportions table
CongestedProportions_ls <- estimateCongestionModel()
#Document the DVMT proportions by congestion level for freeways
png("data/fwy_dvmt_cong_prop.png", height = 360, width = 480)
Opar_ls <- par(mar = c(4,4,3,2))
Props_mx <- CongestedProportions_ls$Fwy
matplot(as.numeric(rownames(Props_mx)), Props_mx, type = "l",
        xlab = "Average Daily Traffic Per Lane", ylab = "Proportion of DVMT")
legend("topright", lty = 1:5, col = 1:5, legend = colnames(Props_mx), bty = "n",
       title = "Congestion Level")
par(Opar_ls)
dev.off()
#Document the DVMT proportions by congestion level for arterials
png("data/art_dvmt_cong_prop.png", height = 360, width = 480)
Opar_ls <- par(mar = c(4,4,3,2))
Props_mx <- CongestedProportions_ls$Art
matplot(as.numeric(rownames(Props_mx)), Props_mx, type = "l",
        xlab = "Average Daily Traffic Per Lane", ylab = "Proportion of DVMT")
legend("topright", lty = 1:5, col = 1:5, legend = colnames(Props_mx), bty = "n",
       title = "Congestion Level")
par(Opar_ls)
dev.off()

rm(estimateCongestionModel)

#Save the congestion lookup tables
#---------------------------------
#' Congestion lookup tables of proportions of DVMT by congestion level
#' for freeways and arterials by demand to supply ratio (average DVMT per lane-mile)
#'
#' @format A list of matrices. The list has two components, Fwy and Art, that
#'   are lookup tables for DVMT by congestion level for freeways and arterials
#'   respectively. Each table is a matrix containing 5 columns corresponding the
#'   5 congestion levels (None, Mod, Hvy, Sev, Ext). The rows correspond to
#'   demand to supply ratios with the rownames specifying the ratios. The values
#'   are proportions by congestion level. The values in each row sum to 1.
#'
#' @source CalculateCongestion.R script.
"CongestedProportions_ls"
usethis::use_data(CongestedProportions_ls, overwrite = TRUE)


#---------------------------------------------------------
#Function that calculates DVMT or DVHT by congestion level
#---------------------------------------------------------
#' Calculate DVMT or DVHT by congestion level.
#'
#' \code{CalculateCongestion} splits input DVMT into the amounts in
#' each of 5 congestion levels:None, Mod, Hvy, Sev, Ext.
#'
#' This function splits input DVMT into amounts by congestion level
#' (none, moderate, heavy, severe, and extreme) as a function of the ratio of
#' DVMT to lane-miles. The lookup tables in CongestedProportions_ls are used
#' to lookup proportions by congestion level. The input DVMT is
#' split with these proportions and the split values are returned.
#'
#' @param RoadType a string having the value 'Fwy' or 'Art' depending on whether
#' congestion is to be calculated for freeways (Fwy) or arterial roadways (Art).
#' @param LaneMi a number identifying the number of lane-miles for the roadway
#' type.
#' @param DVMT a number identifying the daily vehicle miles of travel on the
#' roadway type.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name calculateCongestion
#' @import visioneval
#' @export
calculateCongestion <-
  function(RoadType, LaneMi, DVMT) {
    #Extract the lookup table
    Lookup_LvCl <-
      CongestedProportions_ls[[RoadType]]
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
    #Split DVMT into congested components
    DVMT * CongProps_
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
  LogPop = log1p(Ums_df$Pop000 * 1000),
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
DvmtSplit_LM$Summary <- capture.output(summary(DvmtSplit_LM))
png("data/lambda_model_plots.png", width = 600, height = 600)
Opar_ls <- par(mfrow = c(2,2))
plot(DvmtSplit_LM)
par(Opar_ls)
dev.off()
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


#=========================================================================
#SECTION 1E: ESTIMATE FACTORS FOR CALCULATING AVERAGE NON-URBAN ROAD SPEED
#=========================================================================
#The road speed model only estimates urban road speeds (i.e. road speeds in the
#urbanized area) as a function of road supply and vehicle demand. The average
#non-urban road speed in an marea is estimated by scaling the urban road speed.
#The speed scaling factor is calculated from 2017 NHTS data for average vehicle
#trip distances and durations for urban and rural households along with the
#proportions of urban and non-urban household DVMT on urban roadways.

#Load 2017 NHTS data on urban and rural household trip distances and speeds
NhtsTripDistTimeInp_ls <- items(
  item(
    NAME = "Region",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("UrbanTripLength",
            "RuralTripLength",
            "UrbanTripDuration",
            "RuralTripDuration"),
    TYPE = "double",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
NhtsTripDistTime_df <-   processEstimationInputs(
  NhtsTripDistTimeInp_ls,
  "urban_rural_trip_length_duration.csv",
  "CalculateRoadPerformance.R")
Rg <- NhtsTripDistTime_df$Region
#Calculate urban and rural speed
NhtsSpeed_df <- data.frame(
  UrbanSpeed = setNames(with(NhtsTripDistTime_df, 60 * UrbanTripLength / UrbanTripDuration), Rg),
  RuralSpeed = setNames(with(NhtsTripDistTime_df, 60 * RuralTripLength / RuralTripDuration), Rg)
)
NhtsSpeed_df$SpeedRatio <- with(NhtsSpeed_df, RuralSpeed / UrbanSpeed)
#Put in list
UrbanRuralAveSpeed_ls <- list(
  NhtsTripDistTime_df = NhtsTripDistTime_df,
  NhtsSpeed_df = NhtsSpeed_df,
  SpeedRatio = NhtsSpeed_df["All", "SpeedRatio"]
)
rm(NhtsTripDistTimeInp_ls, NhtsTripDistTime_df, Rg, NhtsSpeed_df)

#Save urban-rural household average speed ratio
#----------------------------------------------
#' Urban-rural average household speed ratio
#'
#' The ratio of average speed of vehicle trips by households residing in urban
#' areas (i.e. in urbanized areas) to average speed of vehicle trips by
#' households residing in rural areas (i.e. not in urbanized areas)
#'
#' @format A list
#' \describe{
#'   \item{NhtsTripDistTime_df}{data frame containing urban and rural household
#'   average vehicle trip distance (miles) and trip time (minutes) by census
#'   region}
#'   \item{NhtsSpeed_df}{data frame containing urban and rural household
#'   average vehicle trip speed (miles/hour) and ratio of rural to urban
#'   average speed}
#'   \item{UrbanRuralHouseholdSpeedRatio}{a number that is the average speed
#'   ratio used in the model to calculate rural speed from urban speed}
#' }
#' @source CalculateRoadPerformance.R script.
"UrbanRuralAveSpeed_ls"
usethis::use_data(UrbanRuralAveSpeed_ls, overwrite = TRUE)


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
      NAME = "StateAbbrLookup",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = c(
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI",
        "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI",
        "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC",
        "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT",
        "VT", "VA", "WA", "WV", "WI", "WY", "DC", "PR", NA)
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
    ),
    item(
      NAME =
        items(
          "LdvFwyDvmtProp",
          "LdvArtDvmtProp"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LambdaAdj",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "constant",
      PROHIBIT = "",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "UrbanHhPropUrbanDvmt",
        "NonUrbanHhPropUrbanDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      TYPE = "compound",
      UNITS = "MI/DAY",
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
        "LdvAveSpeed",
        "HvyTrkAveSpeed",
        "BusAveSpeed",
        "NonUrbanAveSpeed"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      NAVALUE = -1,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average speed (miles per hour) of light-duty vehicle travel on urban area roads",
        "Average speed (miles per hour) of heavy truck travel on urban area roads",
        "Average speed (miles per hour) of bus travel on urban area roads",
        "Average speed (miles per hour) of vehicle travel on non-urban area roads")
    ),
    item(
      NAME = items(
        "LdvTotDelay",
        "HvyTrkTotDelay",
        "BusTotDelay"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HR/MI",
      NAVALUE = -1,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Total light-duty vehicle delay (hours per mile) on urban area roads",
        "Total urban light-duty vehicle delay (hours per mile) on urban area roads",
        "Total urban light-duty vehicle delay (hours per mile) on urban area roads")
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
      NAME = "LambdaAdj",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "constant",
      NAVALUE = -999,
      PROHIBIT = "",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Constant to adjust the modeled lambda parameter to match base year freeway and arterial LDV proportions"
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
  Vt <- c("Ldv", "HvyTrk", "Bus")
  Rc <- c("Fwy", "Art", "Oth")
  #Define default speed for other roads (not freeway or arterial)
  OthSpeed <- 20
  #Initialize outputs list
  Out_ls <- initDataList()
  Out_ls$Global$Marea <- list()
  Out_ls$Year$Marea <- list()
  #Function to remove attributes
  unattr <- function(X_) {
    attributes(X_) <- NULL
    X_
  }

  #Calculate Lambda value for metropolitan areas
  #---------------------------------------------
  #Calculate Lambda
  DvmtSplitData_df <- data.frame(
    LogPop = log1p(sum(L$Year$Marea$UrbanPop)),
    LnMiRatio = L$Year$Marea$FwyLaneMi / L$Year$Marea$ArtLaneMi
  )
  Lambda_Ma <- unname(predict(DvmtSplit_LM, newdata = DvmtSplitData_df))
  names(Lambda_Ma) <- Ma
  Lambda_Ma[Ma == "None"] <- NA
  #Load Lambda adjustments if they exist
  if (!is.null(L$Global$Marea$LambdaAdj)) {
    LambdaAdj_Ma <- L$Global$Marea$LambdaAdj
    names(LambdaAdj_Ma) <- Ma
    #Also save to Out_ls so Set specifications are satisfied
    Out_ls$Global$Marea$LambdaAdj <- L$Global$Marea$LambdaAdj
  }
  rm(DvmtSplitData_df)

  #Calculate speed and delay by congestion level and metropolitan area
  #-------------------------------------------------------------------
  #Create matrix of user-defined other operations effects
  if (!is.null(L$Global$OtherOpsEffectiveness)) {
    OtherOpsEffects_mx <- cbind(
      Fwy_Rcr = L$Global$OtherOpsEffectiveness$Fwy_Rcr,
      Fwy_NonRcr = L$Global$OtherOpsEffectiveness$Fwy_NonRcr,
      Art_Rcr = L$Global$OtherOpsEffectiveness$Art_Rcr,
      Art_NonRcr = L$Global$OtherOpsEffectiveness$Art_NonRcr
    )
    rownames(OtherOpsEffects_mx) <- L$Global$OtherOpsEffectiveness$Level
  } else {
    OtherOpsEffects_mx <- array(
      0,
      dim = c(5, 4),
      dimnames = list(
        c("None", "Mod", "Hvy", "Sev", "Ext"),
        c("Art_Rcr", "Art_NonRcr", "Fwy_Rcr", "Fwy_NonRcr")
      ))
  }
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
  calcAveEqSpeed <- function(Dvmt_Cl, Speed_Cl, Price_Cl, VOT) {
    Dvht <- sum(Dvmt_Cl / Speed_Cl)
    DvhtEq <- sum(Dvmt_Cl * Price_Cl / VOT)
    sum(Dvmt_Cl) / (Dvht + DvhtEq)
  }

  #Define function to split freeway & arterial LDV DVMT
  #----------------------------------------------------
  splitLdvDvmt <- function(LdvDvmt_, AveFwySpd, AveArtSpd, Lambda, LambdaAdj) {
    DvmtRatio <- (Lambda + LambdaAdj) * AveFwySpd / AveArtSpd
    FwyDvmt <- unname(LdvDvmt_["FwyArt"] * DvmtRatio / (1 + DvmtRatio))
    ArtDvmt <- unname(LdvDvmt_["FwyArt"] - FwyDvmt)
    SplitLdvDvmt_ <- c(FwyDvmt, ArtDvmt, LdvDvmt_["Oth"])
    names(SplitLdvDvmt_) <- c("Fwy", "Art", "Oth")
    SplitLdvDvmt_
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
      #Split LDV DVMT
      LdvDvmt_Rc <-
        splitLdvDvmt(LdvDvmt_MaRx[ma,], FwyAveSpeed, ArtAveSpeed, Lambda_Ma[ma], LambdaAdj_Ma[ma])
      #Add heavy truck and bus DVMT to calculate total
      Dvmt_Rc <-
        LdvDvmt_Rc + HvyTrkDvmt_MaRc[ma,] + BusDvmt_MaRc[ma,]
      #Calculate DVMT ratio, compare to last, and terminate if change is very small
      DvmtRatio <- Dvmt_Rc["Fwy"] / Dvmt_Rc["Art"]
      if(abs(1 - LastDvmtRatio / DvmtRatio) < 0.0001) break()
      LastDvmtRatio <- DvmtRatio
      #Split DVMT into congestion levels
      FwyDvmt_Cl <-
        calculateCongestion("Fwy", LaneMi_MaRc[ma,"Fwy"], Dvmt_Rc["Fwy"])
      ArtDvmt_Cl <-
        calculateCongestion("Art", LaneMi_MaRc[ma,"Art"], Dvmt_Rc["Art"])
      #Calculate equivalent average speed
      FwyAveSpeed <-
        calcAveEqSpeed(FwyDvmt_Cl, FwySpeed_MaCl[ma,], FwyPrices_MaCl[ma,], VOT)
      ArtAveSpeed <-
        calcAveEqSpeed(ArtDvmt_Cl, ArtSpeed_MaCl[ma,], ArtPrices_MaCl[ma,], VOT)
    }
    Dvmt_VtRc <- rbind(
      Ldv = LdvDvmt_Rc,
      HvyTrk = HvyTrkDvmt_MaRc[ma,],
      Bus = BusDvmt_MaRc[ma,]
    )
    rownames(Dvmt_VtRc) <- c("Ldv", "HvyTrk", "Bus")
    colnames(Dvmt_VtRc) <- c("Fwy", "Art", "Oth")
    list(Dvmt_VtRc = Dvmt_VtRc,
         FwyDvmt_Cl = FwyDvmt_Cl,
         ArtDvmt_Cl = ArtDvmt_Cl)
  }

  #If base year calculate LambdaAdj factor to match input ratio of freeway and
  #arterial DVMT
  #---------------------------------------------------------------------------
  if (L$G$Year == L$G$BaseYear) {
    #Initialize LambdaAdj
    LambdaAdj_Ma <- numeric(length(Ma))
    names(LambdaAdj_Ma) <- Ma
    if (any(names(LambdaAdj_Ma) == "None")) LambdaAdj_Ma["None"] <- NA
    #Calculate input ratio of freeway to arterial DVMT
    FwyArtTargetRatio_Ma <- with(L$Global$Marea, LdvFwyDvmtProp / LdvArtDvmtProp)
    names(FwyArtTargetRatio_Ma) <- Ma
    FwyArtTargetRatio_Ma["None"] <- NA
    #Define function to find LambdaAdj to match target ratio
    checkMatchLdvSplit <- function(Adj) {
      LambdaAdj_Ma[ma] <<- Adj
      FwyArtResults_ <- balanceFwyArtDvmt(ma)$Dvmt_VtRc["Ldv", 1:2]
      FwyArtRatio <- FwyArtResults_[1] / FwyArtResults_[2]
      FwyArtTargetRatio <- FwyArtTargetRatio_Ma[ma]
      FwyArtRatio - FwyArtTargetRatio
    }
    #Use binary search to find LambdaAdj factor for each marea
    for (ma in Ma[Ma != "None"]) {
      LambdaAdj_Ma[ma] <-
        binarySearch(checkMatchLdvSplit, c(-1, 1), DoWtAve = TRUE, Tolerance = 0.01)
    }
    #Add to outputs list
    Out_ls$Global$Marea$LambdaAdj <- unattr(LambdaAdj_Ma)
  }

  #Run model to balance DVMT between freeways and arterials
  #--------------------------------------------------------
  BalanceResults_ls <- sapply(Ma, function(x) list())
  for (ma in Ma[Ma != "None"]) {
    #Calculate the balanced DVMT
    BalanceResults_ls[[ma]] <- balanceFwyArtDvmt(ma)
  }
  if (any(Ma == "None")) {
    Vt <- c("Ldv", "HvyTrk", "Bus")
    Cl <- c("None", "Mod", "Hvy", "Sev", "Ext")
    BalanceResults_ls$None <- list(
      Dvmt_VtRc = array(0, dim = c(length(Vt), length(Rc)), dimnames = list(Vt,Rc)),
      FwyDvmt_Cl = setNames(numeric(length(Cl)), Cl),
      ArtDvmt_Cl = setNames(numeric(length(Cl)), Cl)
    )
  }

  #Calculate average vehicle speed by metropolitan area and road class
  #-------------------------------------------------------------------
  #Define function to calculate average speed
  calcAveSpd <- function(Dvmt_Cl, Spd_Cl) {
    sum(Dvmt_Cl * Spd_Cl) / sum(Dvmt_Cl)
  }
  #Set up matrix to hold average speed
  AveSpeed_MaRc <-
    array(0, dim = c(length(Ma), 3), dimnames = list(Ma, c("Fwy", "Art", "Oth")))
  #Iterate through mareas and calculate averages
  for (ma in Ma[Ma != "None"]) {
    AveSpeed_MaRc[ma, "Fwy"] <- calcAveSpd(
      Dvmt_Cl = BalanceResults_ls[[ma]]$FwyDvmt_Cl,
      Spd_Cl = SpeedAndDelay_ls[[ma]]$Speed[,"Fwy"]
      )
    AveSpeed_MaRc[ma, "Art"] <- calcAveSpd(
      Dvmt_Cl = BalanceResults_ls[[ma]]$ArtDvmt_Cl,
      Spd_Cl = SpeedAndDelay_ls[[ma]]$Speed[,"Art"]
    )
    AveSpeed_MaRc[ma, "Oth"] <- OthSpeed
  }
  if (any(Ma == "None")) {
    AveSpeed_MaRc["None",] <- NA
  }

  #Calculate average vehicle delay by metropolitan area and road class
  #-------------------------------------------------------------------
  #Define function to calculate average delay per vehicle mile
  calcAveDly <- function(Dvmt_Cl, Spd_Cl) {
    Rate_Cl <- 1 / Spd_Cl
    Delay_Cl <- Rate_Cl - Rate_Cl[1]
    sum(Dvmt_Cl * Delay_Cl) / sum(Dvmt_Cl)
  }
  #Set up matrix to hold average delay
  AveDelay_MaRc <-
    array(0, dim = c(length(Ma), 3), dimnames = list(Ma, c("Fwy", "Art", "Oth")))
  #Iterate through mareas and calculate averages
  for (ma in Ma[Ma != "None"]) {
    AveDelay_MaRc[ma, "Fwy"] <- calcAveDly(
      Dvmt_Cl = BalanceResults_ls[[ma]]$FwyDvmt_Cl,
      Spd_Cl = SpeedAndDelay_ls[[ma]]$Speed[,"Fwy"]
    )
    AveDelay_MaRc[ma, "Art"] <- calcAveDly(
      Dvmt_Cl = BalanceResults_ls[[ma]]$ArtDvmt_Cl,
      Spd_Cl = SpeedAndDelay_ls[[ma]]$Speed[,"Art"]
    )
    AveDelay_MaRc[ma, "Oth"] <- 0
  }
  if (any(Ma == "None")) {
    AveDelay_MaRc["None",] <- NA
  }

  #Calculate average speed and total vehicle delay by marea and vehicle type
  #-------------------------------------------------------------------------
  #Initialize average speed array
  Vt <- c("Ldv", "HvyTrk", "Bus")
  AveSpeed_MaVt <- array(
    0,
    dim = c(length(Ma), 3),
    dimnames = list(Ma, Vt))
  #Initialize vehicle delay array
  VehDelay_MaVt <- array(
    0,
    dim = c(length(Ma), 3),
    dimnames = list(Ma, Vt))
  #Iterate by marea and calculate average speed and total delay
  for (ma in Ma[Ma != "None"]) {
    Dvmt_VtRc <- BalanceResults_ls[[ma]]$Dvmt_VtRc
    AveSpd_Rc <- AveSpeed_MaRc[ma,]
    AveSpeed_MaVt[ma,] <-
      rowSums(sweep(Dvmt_VtRc, 2, AveSpd_Rc, "*")) / rowSums(Dvmt_VtRc)
    AveDelay_Rc <- AveDelay_MaRc[ma,]
    VehDelay_MaVt[ma,] <-
      rowSums(sweep(Dvmt_VtRc, 2, AveDelay_Rc, "*"))
  }
  if (any(Ma == "None")) {
    AveSpeed_MaVt["None",] <- NA
    VehDelay_MaVt["None",] <- NA
  }
  #Remove NaN (because no DVMT of type)
  AveSpeed_MaVt <- apply(AveSpeed_MaVt, 2, function(x) {
    x[is.nan(x)] <- max(x[!is.nan(x)], na.rm = TRUE)
    x
  })
  #Create 1-d matrix is AveSpeed_MaVt or VehDelay_MaVt are vectors
  AveSpeed_MaVt <-
    array(AveSpeed_MaVt, dim = c(length(Ma), 3), dimnames = list(Ma, Vt))
  VehDelay_MaVt <-
    array(VehDelay_MaVt, dim = c(length(Ma), 3), dimnames = list(Ma, Vt))

  #Calculate average vehicle speed for non-urban roads
  #---------------------------------------------------
  #Define function to calculate the rural to urban average road speed ratio
  calcUrbRurHhSpeedRatio <- function() {
    UHPU_ <- L$Year$Marea$UrbanHhPropUrbanDvmt
    RHPU_ <- L$Year$Marea$NonUrbanHhPropUrbanDvmt
    HSR <- UrbanRuralAveSpeed_ls$SpeedRatio
    setNames((HSR * UHPU_ + RHPU_) / ((1 - RHPU_) - HSR * (1 - UHPU_)), Ma)
  }
  #Calculate speed ratio
  RoadSpeedRatio_Ma <- calcUrbRurHhSpeedRatio()
  #Calculate non-urban road speeds
  if (length(Ma) > 1) {
    NonUrbanAveSpeed_Ma <- RoadSpeedRatio_Ma * AveSpeed_MaVt[,"Ldv"]
  } else {
    NonUrbanAveSpeed_Ma <- RoadSpeedRatio_Ma * AveSpeed_MaVt["Ldv"]
  }
  #Constrain average non-urban speed to be in reasonable bounds
  NonUrbanAveSpeed_Ma[NonUrbanAveSpeed_Ma > 60] <- 60
  #If any marea is named 'None', assign maximum non-urban speed
  if (any(Ma == "None")) {
    MaxSpeed <- max(NonUrbanAveSpeed_Ma, na.rm = TRUE)
    NonUrbanAveSpeed_Ma["None"] <- MaxSpeed
    rm(MaxSpeed)
  }

  #Proportions of freeway and arterial DVMT by congestion level
  #------------------------------------------------------------
  Cl <- c("None", "Mod", "Hvy", "Sev", "Ext")
  #Proportion of freeway DVMT by congestion level
  FwyDvmt_MaCl <-
    do.call(rbind, lapply(BalanceResults_ls, function(x) x$FwyDvmt_Cl))[Ma,]
  FwyDvmt_MaCl <-
    array(FwyDvmt_MaCl, dim = c(length(Ma), length(Cl)), dimnames = list(Ma, Cl))
  FwyDvmtPropByLevel_MaCl <- sweep(FwyDvmt_MaCl, 1, rowSums(FwyDvmt_MaCl), "/")
  FwyDvmtPropByLevel_MaCl[is.na(FwyDvmtPropByLevel_MaCl)] <- 0
  FwyDvmtPropByLevel_ls <- as.list(data.frame(FwyDvmtPropByLevel_MaCl))
  names(FwyDvmtPropByLevel_ls) <-
    paste0("FwyDvmtProp", names(FwyDvmtPropByLevel_ls), "Cong")
  #Proportion of arterial DVMT by congestion level
  ArtDvmt_MaCl <-
    do.call(rbind, lapply(BalanceResults_ls, function(x) x$ArtDvmt_Cl))[Ma,]
  ArtDvmt_MaCl <-
    array(ArtDvmt_MaCl, dim = c(length(Ma), length(Cl)), dimnames = list(Ma, Cl))
  ArtDvmtPropByLevel_MaCl <- sweep(ArtDvmt_MaCl, 1, rowSums(ArtDvmt_MaCl), "/")
  ArtDvmtPropByLevel_MaCl[is.na(ArtDvmtPropByLevel_MaCl)] <- 0
  ArtDvmtPropByLevel_ls <- as.list(data.frame(ArtDvmtPropByLevel_MaCl))
  names(ArtDvmtPropByLevel_ls) <-
    paste0("ArtDvmtProp", names(ArtDvmtPropByLevel_ls), "Cong")

  #Calculate average congestion cost per mile
  #------------------------------------------
  AveCongPrice_Ma <-
    (rowSums(FwyPrices_MaCl * FwyDvmt_MaCl) + rowSums(ArtPrices_MaCl * ArtDvmt_MaCl)) /
    sum(FwyDvmt_MaCl + ArtDvmt_MaCl)

  #Freeway and arterial speeds by congestion level
  #-----------------------------------------------
  #Average freeway speed by congestion level
  FwySpdByLevel_ls <-
    as.list(data.frame(
      do.call(rbind, lapply(SpeedAndDelay_ls, function(x) x$Speed[,"Fwy"]))
    ))
  names(FwySpdByLevel_ls) <- paste0("Fwy", names(FwySpdByLevel_ls), "CongSpeed")
  #Average arterial speed by congestion level
  ArtSpdByLevel_ls <-
    as.list(data.frame(
      do.call(rbind, lapply(SpeedAndDelay_ls, function(x) x$Speed[,"Art"]))
    ))
  names(ArtSpdByLevel_ls) <- paste0("Art", names(ArtSpdByLevel_ls), "CongSpeed")

  #Save performance measures
  #-------------------------
  #LDV DVMT by road class
  Out_ls$Year$Marea$LdvFwyDvmt <-
    unattr(unlist(lapply(BalanceResults_ls, function(x) x$Dvmt_VtRc["Ldv", "Fwy"])))
  Out_ls$Year$Marea$LdvArtDvmt <-
    unname(unlist(lapply(BalanceResults_ls, function(x) x$Dvmt_VtRc["Ldv", "Art"])))
  #Average speed by vehicle type
  Out_ls$Year$Marea$LdvAveSpeed <- AveSpeed_MaVt[,"Ldv"]
  Out_ls$Year$Marea$HvyTrkAveSpeed <- AveSpeed_MaVt[,"HvyTrk"]
  Out_ls$Year$Marea$BusAveSpeed <- AveSpeed_MaVt[,"Bus"]
  #Average non-urban speed
  Out_ls$Year$Marea$NonUrbanAveSpeed <- NonUrbanAveSpeed_Ma
  #Total freeway delay by vehicle type
  Out_ls$Year$Marea$LdvTotDelay <- VehDelay_MaVt[,"Ldv"]
  Out_ls$Year$Marea$HvyTrkTotDelay <- VehDelay_MaVt[,"HvyTrk"]
  Out_ls$Year$Marea$BusTotDelay <- VehDelay_MaVt[,"Bus"]
  #Average congestion cost per mile
  Out_ls$Year$Marea$AveCongPrice <- AveCongPrice_Ma
  #Add list of freeway DVMT proportions by congestion level
  Out_ls$Year$Marea <-
    c(Out_ls$Year$Marea, FwyDvmtPropByLevel_ls); rm(FwyDvmtPropByLevel_ls)
  #Add list of arterial DVMT proportions by congestion level
  Out_ls$Year$Marea <-
    c(Out_ls$Year$Marea, ArtDvmtPropByLevel_ls); rm(ArtDvmtPropByLevel_ls)
  #Add list of speed by freeway congestion level
  Out_ls$Year$Marea <-
    c(Out_ls$Year$Marea, FwySpdByLevel_ls); rm(FwySpdByLevel_ls)
  #Add list of speed by arterial congestion level
  Out_ls$Year$Marea <-
    c(Out_ls$Year$Marea, ArtSpdByLevel_ls); rm(ArtSpdByLevel_ls)
  #Average other road speed
  Out_ls$Year$Marea$OthSpd <- OthSpeed
  #Return the result
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculateRoadPerformance")

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
# # setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "CalculateRoadPerformance",
#   LoadDatastore = TRUE,
#   SaveDatastore = FALSE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateRoadPerformance(L)
#
# TestDat_ <- testModule(
#   ModuleName = "CalculateRoadPerformance",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "BaseYear"
# )
#
# TestDat_ <- testModule(
#   ModuleName = "CalculateRoadPerformance",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "NotBaseYear"
# )
