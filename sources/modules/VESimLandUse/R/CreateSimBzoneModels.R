#======================
#CreateSimBzoneModels.R
#======================

#<doc>
## CreateSimBzoneModels Module
#### December 16, 2018
#
#This module estimates all the models for synthesizing Bzones and their land use attributes as a function of Azone characteristics as well as data derived from the US Environmental Protection Agency's Smart Location Database (SLD) augmented with US Census housing and household income data, and data from the National Transit Database. Details on these data are included in the VESimLandUseData package. The combined dataset contains a number of land use attributes at the US Census block group level. The goal of Bzone synthesis to generate a set of SimBzones in each Azone that reasonably represent block group land use characteristics given the characteristics of the Azone, the Marea that the Azone is a part of, and scenario inputs provided by the user.
#
#Many of the models and procedures used in Bzone synthesis pivot from profiles developed from these data sources for specific urbanized areas, as well as more general profiles for different urbanized area population size categories, towns, and rural areas. Using these specific and general profiles enables the simulated Bzones (SimBzones) to better represent the areas being modeled and the variety of conditions found in different states. The documentation for the `Initialize` module has a listing of urbanized area profile names.
#
#The models estimated by this module support the synthesis of SimBzones within each Azone that simulate the land use characteristics of neighborhoods likely to be found in the Azone. The SimBzones are assigned quantities of households and jobs and are attributed with several land use measures in the process. The characteristics are:
#
#* **Location Type**: Identification of whether the SimBzone is located in an urbanized area, a town (i.e. an urban-type area that is not large enough to be urbanized), rural (i.e. dispersed low-density development)
#
#* **Households**: Number of households in each SimBzone
#
#* **Employment**: Number of jobs in each SimBzone
#
#* **Activity Density**: Number of households and jobs per acre
#
#* **Land Use Diversity**: Measures of the degree of mixing of households and jobs
#
#* **Destination Accessibility**: Measures of proximity to households and jobs
#
#* **Area Type**: Category identifying relative activity density and destination accessibility
#
#* **Development Type**: Category identifying whether development is characterized residential, employment, or mixed
#
#* **Housing Units**: Numbers of single-family dwellings and multifamily dwellings in each SimBzone
#
#* **Network Design**: Design of the transportation network to support non-motorized travel
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
#### Assign an Activity Density to Each SimBzone
#
#Activity density (households and jobs per acre) is the key characteristic which drives the synthesis of all SimBzone characteristics. This measure is referred to as D1D in the SLD. The overall activity density of each location type in each Azone is determined by the allocations of households and jobs described above and user inputs on the areal extents of development. The activity density of SimBzones is determined by the overall density and by density distribution characteristics reflective of the area. Density distribution profiles developed for areas as noted above are used in the process.
#
#The distribution of activity density by block group is approximately lognormally distributed. This distribution is related to the overall density of the area. As the overall density increases, the density distribution shifts to the right. This is illustrated in the following figure which shows distributions for 9 urbanized areas having a range of overall densities from the least dense (Atlanta, GA) to the most dense (New York, NY). In each panel of the figure, the probability density of the activity density distribution of block groups in the urbanized area are shown by the solid line. The distribution for all urbanized areas is shown by the dashed line. As can be seen, as the overall density of the urbanized area increases the density distribution shifts to the right.
#
#<fig:example-uza_d1_distributions.png>
#
#The characterization of activity density distributions is simplified by discretizing activity density values. The profile for each area is a combination of the proportion of activity at each level and the average density at each level. Levels for urbanized areas are created by dividing the lognormal distribution of activity density for all urbanized areas in the SLD into 20 equal intervals. Activity density levels for town and for rural areas are established in the same way. The following figure shows the distribution of urbanized area activity by activity density level and the average activity density at each level.
#
#<fig:uza_activity-density_level.png>
#
#Profiles like those show in the figure are developed for each of the urbanized areas listed above, for each urbanized area size category, for towns (as a whole), and for rural areas (as a whole).
#
#The model adjusts the profile for an area as a function of the overall activity density of the area. This is a 2-step mechanistic process. In the first step, the proportions of activity in each level are adjusted until the overall density for the area calculated from the proportion of activity in each level and the average density of each level is within 1% of the target density. The proportion of activity at each level is adjusted in a series of increments by calculating a weighted average of the proportion at each level and the proportion at each level to the right or left. In each increment, 99% of the level value is added to 1% of the adjacent level value and then the results are divided by the sum of all level values so that the proportions for all levels sum to 1. When the overall density is within 10% of the target density, the weights are changed to 99.9% and 0.1%. In this way, the distribution of activity by density level is smoothly shifted to the right or left. In the second step, the average density of all levels is adjusted so that the target density is matched exactly.
#
#Activity density profiles are developed from the SLD for each of the urbanized areas documented in the **Initialize** module, as well as each urbanized area size category, for towns (as a whole), and rural areas (as a whole).
#
#### Assign a Jobs and Housing Mix Level to Each SimBzone
#
#The ratio of jobs to housing (D2A_JPHH in the SLD) at the block group level, like the distribution of activity density, is approximately lognormally distributed. However, unlike the activity density distribution, the distribution of the jobs to housing ratio has no apparent relationship with the overall activity density of the area. Is can be seen in the following figure which compares distributions for 9 urbanized areas.
#
#<fig:example-uza_d2_distributions.png>
#
#As can be seen from the figure, the distributions for all of the areas are very similar to the distribution for all urbanized areas. There are, however, some differences that need to be accounted for. For example, the distribution of for the Portland (Oregon) urbanized area is more compressed with a much higher peak at the center of the distribution. This indicates that the jobs to housing ratio is closer to 1 for a much larger portion of block groups in that urbanized area than in other urbanized areas. The distribution for the San Francisco - Oakland urbanized area is similar. On the other hand, the distribution for the Dallas - Fort Worth - Arlington urbanized area is more spread out, indicating more segregation of jobs and households at the block group level.
#
#Differences among urbanized areas are accounted for by developing individual area profiles. As with activity density, these profiles are simplified by discretizing the D2A_JPHH variable into the following 5 activity mix levels:
#
#* **primarily-hh**: greater than 4 households per job
#
#* **largely-hh**: less than 4 households to 2 households per job
#
#* **mixed**: less than 2 households per job to 2 jobs per household
#
#* **largely-job**: greater than 2 jobs per household to 4 jobs per household
#
#* **primarily-job**: greater than 4 jobs per household
#
#Areas are profiled according to the distribution of activity among activity mix levels at each activity density level. In this way, the SimBzones created for an area can reasonably reflect observed conditions, and when a scenario having a different overall density is modeled, the joint distribution of activity density and mix will be a sensible result. The following figure illustrates the activity mix distributions by activity density level for urbanized areas as a whole. This figure is a visual representation of a matrix where the rows correspond to activity mix levels and the columns correspond to activity density levels. The values in each cell of the matrix are the proportion of activity at the activity density level that is in the activity mix level (values in each column sum to 1). The value of each cell is represented by the color where yellow represents the highest proportion and black the lowest.
#
#<fig:uza_d2group-prop-act_by_d1group.png>
#
#Several patterns in the relationship between activity density and mixing. Ignoring for now the lowest activity density levels, the jobs proportion of activity increases as activity density increases. Jobs dominate at the highest activity densities. This is consistent with the bid rent theory of spatial location. Businesses value higher density (more central) locations more highly than households and so outbid households for those locations. The greatest degree of activity mixing occurs in the 3rd quarter of the density range. There is no clear pattern at the lowest density levels which are represented by a very small number of block groups.
#
#the relationship between activity density and activity mix varies by metropolitan area as illustrated in the following figure which compares values for the 9 example urbanized areas. For example, it can be seen that jobs and housing are much more segregated in the Atlanta area than in the San Francisco-Oakland area.
#
#<fig:example-uza_d2group-prop-act_by_d1group.png>
#
#Profiles illustrated in the preceding figures are developed for each of the urbanized areas listed in the **Initialize** module documentation, for each urbanized area size category, and for towns (as a whole), and rural areas (as a whole). These are used by the **CreateSimBzones** module to assign a activity mix level to each SimBzone based on the activity density of the SimBzone.
#
#### Split SimBzone Activity Between Jobs and Households
#
#The process of splitting the activity of each SimBzone between jobs and households is done in 2 steps. In the first step an initial value for the jobs proportion of activity is selected by sampling from distributions associated with each activity mix level. In the second step, a balancing process is used so that the distribution of jobs and households among SimBzones in an area is consistent with the control totals of jobs and households by Azone and location type.
#
#The 1st step uses tabulations from the SLD of the numbers of block groups by employment proportion for each activity mix level. Those tabulations are converted into proportions of block groups that are then used as sampling distributions from which to choose an initial employment proportion based on the activity mix level of the SimBzone. The following figure shows the probability distributions of jobs proportions by activity mix levels. These are the sample distributions used to determine the initial jobs proportion for SimBzones located in urbanized areas. Similar sampling distributions are tabulated from the SLD for town locations and for rural locations.
#
#<fig:emp-prop-distribution_by_d2group.png>
#
#In the second step, jobs and household numbers by SimBzone are adjusted to be consistent with control totals by Azone and location type and activity totals by SimBzone.
#
#### Assign Destination Accessibility Measure Values to SimBzones
#
#Destination accessibility is a measure of the amount of activity present in the vicinity of each SimBzone. The measure used is the harmonic mean of the population within 5 miles and employment within 2 miles of the SimBzone. This measure was computed for each block group in the SLD using straight line distances between block group centroids. This measure is used instead of destination accessibility measures in the SLD which are auto oriented (for example, jobs within 45 minute travel time) and not very useful for measuring destination accessibility within smaller urbanized areas. The harmonic mean of population and employment was found to be useful for distinguishing *area types*, one of the dimensions in the *place type* system that will be implemented in the Bzone synthesis process.
#
#Destination accessibility at the block group level, like the distribution of activity density, is approximately lognormally distributed. As with activity density, the distribution of destination accessibility is related to overall urbanized area density; shifting to the right as overall density increases.
#
#<fig:example-uza_d5_distributions.png>
#
#The characterization of destination accessibility distributions is simplified by discretizing destination accessibility values. The profile for each area is a combination of the proportion of activity at each level and the average destination accessibility at each level. Levels for urbanized areas are created by dividing the lognormal distribution of destination accessibility for all urbanized areas in the SLD into 20 equal intervals. Destination accessibility levels for town and for rural areas are established in the same way. The following figure shows the distribution of urbanized area activity by destination accessibility level and the average destination accessibility at each level.
#
#<fig:uza_destination-accessibility_level.png>
#
#Areas are profiled according to the distribution of activity among destination accessibility levels at each activity density level. In this way, the SimBzones created for an area can reasonably reflect observed conditions, and when a scenario having a different overall density is modeled, the joint distribution of activity density and destination accessibility will be a sensible result. The following figure illustrates the destination accessibility distributions by activity density level for 9 example metropolitan areas. It can be seen that except for low activity density levels (for which there are few census block groups) there is a relatively strong relationship between destination accessibility and activity density.
#
#<fig:example-uza_d5group-prop-act_by_d1group.png>
#
#Profiles illustrated in the preceding figures are developed for each of the urbanized areas listed in the **Initialize** module documentation, for each urbanized area size category, and for towns (as a whole), and rural areas (as a whole). These are used by the **CreateSimBzone** module to assign a destination accessibility level to each SimBzone based on the activity density of the SimBzone.
#
#### Split SimBzone Employment Into Sectors
#
#SimBzone employment is split into 3 sectors (retail, service, other) to enable the calculation of an entropy measure of land use mixing that is used in the forthcoming multimodal household travel for VisionEval. A model is developed to carry out the splits for each SimBzone as a function of the activity density and mixing levels assigned to the SimBzone. This model is carried out in two steps. In the first step, the combined proportion of retail and service employment is determined. In the second step, the retail proportion of retail and service employment is determined. It is clear from graphing the relationship of retail and service proportions with density and mix, that while there are some trends, there is a very large amount of variability. The following figure shows the distribution of the combined retail and service proportion at different density and mixing levels.
#
#<fig:ua_retsvc-prop_by_diversity&density.png>
#
#The relationship is even less clear for the retail proportion of retail and service employment as shown in the following figure.
#
#<fig:ua_ret-prop_by_diversity&density.png>
#
#Because of the high degree of variability and limited number of predictive variables that may be employed, a very simple model structure is used. The mean values by density are calculated for each mix level and smoothed using splines with 4 degrees of freedom. In addition, the standard deviation of values at each mix level is computed. This is done for both model steps. In each step, the model randomly selects a proportion from a normal distribution described by the mean and standard deviation. The following figure shows the mean values for the retail and service proportion of employment by density and mix level.
#
#<fig:ua_mean_ret-svc-prop_by_diversity&density.png>
#
#The following figure shows the mean values for the retail proportion of retail and service employment by density and mix level.
#
#<fig:ua_mean_ret-prop_by_diversity&density.png>
#
#### Model Housing Types
#
#The housing types (single family, multifamily) occupied by households in each SimBzone are modeled and used in combination with a housing choice model to assign housing types to households, and to assign households to SimBzones. This is done for several reasons. First, dwelling type has a significant relationship to several important household transportation characteristics such as auto ownership. Second, modeling housing type provides a mechanism for assigning households to SimBzones (neighborhoods) having characteristics where they're more likely to live. For example, a large higher income household is more likely to live in a single-family dwelling and thus are more likely to live in a lower density neighborhood where single-family dwellings predominate.
#
#The proportion of housing units in multifamily dwellings is modeled as a function of SimBzone activity density. The following set of boxplots show the distributions of the multifamily dwelling proportions by activity density level for metropolitan, town, and rural areas. In general, the multifamily dwelling unit proportion increases with increased density. This is particularly evident for metropolitan areas where the multifamily proportion increases greatly at activity density levels beyond the midrange.
#
#<fig:mf-prop_by_loctype&density.png>
#
#The boxplots also show that the distribution of values (extent and skewness) varies by activity density. Given the complexity of the distributions and information limitations of the Bzone synthesis process, the multifamily proportions model has a simple design to capture central tendencies and variance patterns. The design is similar to the boxplot representation. Multifamily dwellings at each activity density level and for each location type are split into 8 quantiles. Each quantile has an associated range of multifamily proportions. The model selects a multifamily proportion for a SimBzone by selecting the corresponding set of quantiles corresponding to the location type and activity density level of the SimBzone. Then a quantile is randomly selected and a multifamily proportion is randomly selected within the range of the chosen quantile.
#
#
#### Designate Place Types
#
#Place types simplify the characterization of land use patterns. They are used in the VESimLandUse package modules to simplify the management of inputs for land use related policies. There are three dimensions to the place type system. Location type identifies whether the SimBzone is located in an urbanized area (Metropolitan), a smaller urban-type area (Town), or a non-urban area (Rural). Area types identify the relative urban nature of the SimBzone: center, inner, outer, fringe. Development types identify the character of development in the SimBzone: residential, employment, mix.
#
#Area types are designated based on a combination of activity density and destination accessibility levels. Each is split into 4 levels. Area type is determined by 16 combinations of those levels. Following are the activity density level definitions:
#
#* Very Low (VL): 0 to 0.5 households and jobs per acre
#
#* Low (L): Greater than 0.5 to 5 households and jobs per acre
#
#* Moderate (M): Greater than 5 to 10 households and jobs per acrea
#
#* High (H): Greater than 10 households and jobs per acre
#
#Following are the destination accessiblity level definitions:
#
#* Very Low (VL): 0 to 2,000 units
#
#* Low (L): Greater than 2,000 units to 10,000 units
#
#* Moderate (M): Greater than 10,000 units to 50,000 units
#
#* High (H): Greater than 50,000 units
#
#The following table classifies area types by activity density levels and destination accessibility levels. Rows in the table represent activity density levels and columns represent destination accessibility levels.
#
# |          | Very Low | Low    | Moderate | High   |
# |----------|----------|--------|----------|--------|
# | Very Low | fringe   | fringe | outer    | outer  |
# | Low      | fringe   | outer  | outer    | inner  |
# | Moderate | outer    | outer  | inner    | inner  |
# | High     | outer    | inner  | center   | center |
#
#Development type is determined by collapsing the mix levels from 5 to 3 as follow:
#
# | Development Type | Mix Levels                  |
# |------------------|-----------------------------|
# | mix              | mixed                       |
# | res              | primarily-hh & largely-hh   |
# | emp              | primarily-job & largely-job |
#
# The following maps show how the area type and development type categories apply to the Atlanta and Portland urbanized areas based on block group data in the SLD.
#
#<fig:ua_place-type_examples.png>
#
#### Model Pedestrian-Oriented Network Design (D3bpo4)
#
#Pedestrian-oriented network design can significantly affect the amount of walking and other non-auto oriented trip making. Having a suitable measure can be an important indicator. It can also be used as a predictor variable of non-auto mode travel as it is in the forthcoming multimodal travel model. The D3bpo4 measure of pedestrian-oriented network design measure in the SLD is used for this purpose and the **CreateSimBzones** module needs to include a process for assigning reasonable values of this measure to SimBzones.
#
#D3bpo4 is a measure of intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile. The SLD users guide defines pedestrian-oriented facilities as follows:
#
#* Any arterial or local street having a speed category of 6 (between 21 and 30 mph) where car travel is permitted in both directions.
#
#* Any arterial or local street having a speed category of 7 or lower (less than 21 mph).
#
#* Any local street having a speed category of 6 (between 21 and 30 mph).
#
#* Any pathway or trail on which automobile travel is not permitted (speed category 8).
#
#* For all of the above, pedestrians must be permitted on the link.
#
#* For all of the above, controlled access highways, tollways, highway ramps, ferries, parking lot roads, tunnels, and facilities having four or more lanes of travel in a single direction (implied eight lanes bi-directional) are excluded.
#
#This model is implemented using several datasets for each urbanized area in the database (see **Initialize** model documentation for details), for urbanized area size categories, and for towns in aggregate, and and rural areas in aggregate. The model has two steps. The first step is used to determine whether a SimBzone will have a D3bpo4 value of zero. The second step is used to determine what the D3bpo4 value is if it is not zero. This 2-step approach is used because a significant proportion (~ 10%) of block groups in the SLD have a zero value and because the distribution of values is highly skewed so transformation is required in order to develop normal sampling distributions.
#
#The parameters for the first model step (to determine if D3bpo4 is 0) are tables of the zero proportions for named urbanized areas, urbanized area size category, towns (as a whole), and rural areas (as a whole) tabulated from the SLD. Two tabulations are done. One of these is a tabulation for the location as a whole (e.g. the proportion of block groups in Seattle having a 0 value). The other is a tabulation for the location by place type where place types are combinations of area types and development types (12 in total). For many of the urbanized areas, there are missing values for one or more place types. Values are imputed for these by taking a weighted average of the values for all other urbanized areas where the weights measure how close the overall value of each urbanized area is to the overall value of the urbanized area for with a missing place value is calculated. From these tabulations, the ratio of the zero proportion by place type for each location to the zero proportion for the location is calculated. Calculation of this ratio enables the model to respond to user inputs for performance goals. For example, the user may specify a scenario where the proportion of neighborhoods having no pedestrian-oriented intersections cut in half. The model will use this input and the relative 0 ratios that have been calculated for the location to calculate what the 0 proportions would be by place type (assuming that the same proportional changes are made across the board by place type).
#
#The parameters for the second model step (to determine D3bpo4 if it is not 0) are tables of average D3pbo4 values for the same locations as above. Overall averages by location and averages by location and place type are calculated. Averages are weighted by block group activity. Because the distribution of D3bpo4 values is highly skewed, with a long right-hand tail, the averages are calculated for power-transformed values. Transformation powers are calculated for each location type (urban, town, rural). Missing values in the place type by location table are imputed using the method described above. The following figure compares the distributions of power-transformed averages by place type for urbanized areas as a whole. As can be seen from the figure, as expected, values drop as one moves from urban centers to fringe areas. The decline is greater for employment development types than for residential. For the residential areas, the D3bpo4 values for inner neighborhoods are as high as for center neighborhoods.
#
#<fig:ua_pwr-transform-d3_dist_by_place-type.png>
#
#From these tabulations, the ratio of the power-transformed average density by place type for each location to the power-transformed average density for the location is calculated. Calculation of this ratio enables the model to respond to user inputs for performance goals. For example, the user may specify a scenario where the average D3bpo4 value is doubled. The model will use this input, power transform it and calculate the power-transfomed values by place type.
#
#In addition to computing the power-transformed average values by location and place type, the standard deviation of the power-transformed D3bpo4 values is computed by location type (urban, town, rural) and place type. The power-transformed average for the location and place type along with the standard deviation by location type and place type parameterize a normal sampling distribution for a location and place type from which a sample is drawn to be the selected power-transformed D3bpo4 value that is applied if the value is not 0.
#
#The following figure compares the results of modeling the D3bpo4 values using the estimated parameters with values from the SLD for 9 metropolitan areas. The power-transformed D3bpo4 values are shown. The simplified model process does a reasonable job of replicating observed values.
#
#<fig:ua_d3bpo4-test_.png>
#
#The following shows the results of testing the model using Atlanta urbanized area data with reducing the 0 proportion in half and doubling the average D3bpo4 value for the urbanized area. Power-transformed D3bpo4 distributions are shown.
#
#<fig:atlanta_D3_test.png>
#
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
#Load libraries
library(visioneval)
library(plot3D)


#============================================
#SET UP DATA AND FUNCTIONS TO ESTIMATE MODELS
#============================================

#--------------------------
#LOAD MODEL ESTIMATION DATA
#--------------------------
D_df <- VESimLandUseData::SimLandUseData_df
#Create a list to hold model elements
SimBzone_ls <- list(
  UaProfiles = list(),
  TnProfiles = list(),
  RuProfiles = list(),
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
#Create dataset for urbanized areas having populations >= 50,000
Ua_df <- D_df[D_df$LocType == "Urban",]
#Create dataset for towns: named places having populations < 50,000
Tn_df <- D_df[D_df$LocType == "Town",]
#Create dataset for rural areas: unnamed places
Ru_df <- D_df[D_df$LocType == "Rural",]

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


#=============================================================
#CALCULATE THE MEDIAN AMOUNT OF ACTIVITY BY CENSUS BLOCK GROUP
#=============================================================
#
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


#=======================================
#EVALUATE ACTIVITY DENSITY DISTRIBUTIONS
#=======================================

#------------------------------------------------------
#EVALUATE URBANIZED AREA ACTIVITY DENSITY DISTRIBUTIONS
#------------------------------------------------------

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

#Define activity density levels for urbanized areas
#--------------------------------------------------
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

#Plot urbanized area activity proportions and average density by density level
#-----------------------------------------------------------------------------
#Plot the proportion of total activity and average density by level
png("data/uza_activity-density_level.png", width = 800, height = 480)
InitPar_ls <- par(mfrow = c(1,2), oma = c(0, 0, 2.2, 0))
plot(1:20, D1DGrpPropAct_,
     xlab = "Activity Density (D1D) Level",
     ylab = "Proportion of Activity (HHs & Jobs)",
     main = "Proportions of Urbanized Area Activity")
addSmoothLine(1:20, D1DGrpPropAct_, lty = 2)
plot(1:20, D1DGrpAve_,
     xlab = "Activity Density (D1D) Level",
     ylab = "Average Density (HHs + Jobs per Acre)",
     main = "Average Activity Density")
addSmoothLine(1:20, D1DGrpAve_, lty = 2)
mtext(text = "Urbanized Area Activity Density Levels", side = 3, line = 0.5,
      outer = TRUE, cex = 1.5)
rm(InitPar_ls)
dev.off()

#Calculate activity density level information for urbanized areas
#----------------------------------------------------------------
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
#Clean up
rm(D1DGrpBrk_, D1DGrp_, D1DGrpTotAct_, D1DGrpAve_, D1DGrpPropAct_)


#--------------------------------------------
#EVALUATE TOWN ACTIVITY DENSITY DISTRIBUTIONS
#--------------------------------------------

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


#---------------------------------------------
#EVALUATE RURAL ACTIVITY DENSITY DISTRIBUTIONS
#---------------------------------------------

#Define rural activity density levels
#------------------------------------
#Limit data to records above 1st percentile and below 95th percentile to remove
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


#=============================================================================
#ANALYSE RELATIONSHIP OF URBANIZED AREA DIVERSITY (D2A_JPHH) AND DENSITY (D1D)
#=============================================================================

#----------------------------------------------
#ANALYZE URBANIZED AREA DIVERSITY RELATIONSHIPS
#----------------------------------------------

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
rm(ActProp_Ua_D2, D2ActProp_D1D2, D2ActProp_Ua_D1D2,
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

#Calculate urbanized area distribution of job proportions by diversity level
#---------------------------------------------------------------------------
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


#------------------------------------
#ANALYZE TOWN DIVERSITY RELATIONSHIPS
#------------------------------------

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


#------------------------------------
#ANALYZE TOWN DIVERSITY RELATIONSHIPS
#------------------------------------

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


#=========================================================================
#ANALYZE RELATIONSHIP OF DESTINATION ACCESSIBILITY (D5) WITH DENSITY (D1D)
#=========================================================================

#--------------------------------------------------------------
#ANALYZE URBANIZED AREA DESTINATION ACCESSIBILITY RELATIONSHIPS
#--------------------------------------------------------------

#Plot diversity (D5) distribution for selected urbanized areas
#-------------------------------------------------------------
png("data/example-uza_d5_distributions.png", width = 600, height = 600)
InitPar_ls <- par(mfrow = c(3,3), oma = c(0, 0, 2.2, 0))
for (Ua in UzaToPlot_[order(ActDen_Ua[UzaToPlot_])]) {
  plotDist(Ua, "D5", ylim = c(0, 0.35), xlab = "Natural log of Destination Accessibility")
}
mtext("Block Group Destination Accessibility Distribution (D5) for Selected Urbanized Areas\nCompared to Distribution for All Urbanized Areas (dashed line)", outer = TRUE, line = -0.5)
par(InitPar_ls)
dev.off()

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
#Plot the proportion of total activity and average destination accessibility by level
png("data/uza_destination-accessibility_level.png", width = 800, height = 480)
InitPar_ls <- par(mfrow = c(1,2), oma = c(0, 0, 2.2, 0))
plot(1:20, D5GrpPropAct_,
     xlab = "Destination Accessibility (D5) Level",
     ylab = "Proportion of Activity (HHs & Jobs)",
     main = "Proportions of Urbanized Area Activity")
addSmoothLine(1:20, D5GrpPropAct_, lty = 2)
plot(1:20, D5GrpAve_,
     xlab = "Destination Accessibility (D5) Group",
     ylab = "Average Destination Accessibility",
     main = "Average Destination Accessibility")
addSmoothLine(1:20, D5GrpAve_, lty = 2)
mtext(text = "Urbanized Area Destination Accessibility Levels", side = 3, line = 0.5,
      outer = TRUE, cex = 1.5)
rm(InitPar_ls)
dev.off()

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


#-------------------------------------------------------------------
#ANALYZE TOWN AND RURAL AREA DESTINATION ACCESSIBILITY RELATIONSHIPS
#-------------------------------------------------------------------

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


#====================================================
#DEVELOP MODELS FOR SPLITTING EMPLOYMENT INTO SECTORS
#====================================================

#---------------------------------------------
#DEVELOP URBANIZED AREA EMPLOYMENT SPLIT MODEL
#---------------------------------------------

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
#Plot the smooth trend
png("data/ua_mean_ret-svc-prop_by_diversity&density.png", width = 480, height = 360)
matplot(MeanRetSvcProp_D1D2, type = "l",
        xlab = "Activity Density (D1D) Level",
        ylab = "Retail & Service Employment Proportion",
        main = "Average Retail & Service Employment Proportion\nBy Density Level and Mix Level")
legend("bottom", lty = 1:5, col = 1:5, ncol = 2, bty = "n",
       legend = colnames(MeanRetSvcProp_D1D2))
dev.off()
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
#Plot the smooth trend
png("data/ua_mean_ret-prop_by_diversity&density.png", width = 480, height = 360)
matplot(MeanRetPropRetSvc_D1D2, type = "l",
        xlab = "Activity Density (D1D) Level",
        ylab = "Retail Proportion of Retail & Service Employment",
        main = "Average Retail Proportion of Retail & Service Employment\nBy Density Level and Mix Level")
legend("bottom", lty = 1:5, col = 1:5, ncol = 2, bty = "n",
       legend = colnames(MeanRetPropRetSvc_D1D2))
dev.off()
#Average standard deviation by diversity group
SimBzone_ls$UaProfiles$SdRetPropRetSvc_D2 <- unlist(lapply(Tmp_D2_df, function(x) {
  sd(x$RetPropRetSvcEmp, na.rm = TRUE)
}))
rm(MeanRetPropRetSvc_D1D2, Tmp_D2_df)


#------------------------------------
#DEVELOP TOWN EMPLOYMENT SPLIT MODELS
#------------------------------------

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


#-------------------------------------
#DEVELOP RURAL EMPLOYMENT SPLIT MODELS
#-------------------------------------

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


#===========================
#DEVELOP HOUSING SPLIT MODEL
#===========================

#Investigate relationship of multifamily proportions with activity density
#-------------------------------------------------------------------------
#Make a boxplot of multifamily dwelling unit proportion by activity density
#level and location type
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


#===============================
#DEVELOP PLACE TYPE DESIGNATIONS
#===============================

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

# #Make map backgrounds for displaying place types
# #-----------------------------------------------
# #Do this only if base maps don't exist in inst/extdata
# UzaToMap_ <- c("Atlanta, GA", "Portland, OR")
# BaseMapFiles_ <-
#   sapply(UzaToMap_, function(x) paste0("inst/extdata/", gsub(", ", "_", x), ".rds"))
# if (!all(file.exists(BaseMapFiles_))) {
#   library(OpenStreetMap)
#   #Function to convert downloaded open street map to a raster for display
#   osmToRaster <- function(OSM_ls) {
#     x <- OSM_ls$tiles[[1]]
#     xres <- x$xres
#     yres <- x$yres
#     list(
#       image = as.raster(matrix(x$colorData,nrow=xres,byrow=TRUE)),
#       xleft = x$bbox$p1[1] - .5*abs(x$bbox$p1[1]-x$bbox$p2[1])/yres,
#       ybottom =  x$bbox$p2[2] + .5*abs(x$bbox$p1[2]-x$bbox$p2[2])/xres,
#       xright = x$bbox$p2[1] - .5*abs(x$bbox$p1[1]-x$bbox$p2[1])/yres,
#       ytop = x$bbox$p1[2] + .5*abs(x$bbox$p1[2]-x$bbox$p2[2])/xres
#     )
#   }
#   #Function to download open street map for urbanized area and save
#   saveUaOSM <- function(UaName) {
#     #Get location information for block groups in urbanized area
#     Data_df <- Ua_df[Ua_df$UZA_NAME == UaName, c("LAT", "LNG")]
#     #Download the map
#     UaMapOsm <- openmap(
#       upperLeft = with(Data_df, c(max(LAT), min(LNG))),
#       lowerRight = with(Data_df, c(min(LAT), max(LNG)))
#     )
#     #Reproject to geographic coordinates
#     UaMap <- openproj(UaMapOsm, projection = "+proj=longlat")
#     #Convert to raster list
#     UaRasterMap <- osmToRaster(UaMap)
#     #Save as file
#     FileName <- paste0("data/", gsub(", ", "_", UaName), ".rds")
#     saveRDS(UaRasterMap, file = FileName)
#   }
#   #Iterate through urban areas and save base map files
#   for (ua in UzaToMap_) {
#     saveUaOSM(ua)
#   }
#   rm(osmToRaster, saveUaOSM, ua)
# }
# rm(BaseMapFiles_)

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
  FileName <- paste0("inst/extdata/", gsub(", ", "_", UaName), ".rds")
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
  FileName <- paste0("inst/extdata/", gsub(", ", "_", UaName), ".rds")
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

#Map area types and development types for 2 urbanized areas
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
rm(mapAreaType, mapDevType)


#=================================================
#DEVELOP MODEL OF NETWORK DESIGN VARIABLE (D3BPO4)
#=================================================

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
findPower <- function(Dat_) {
  skewness <- function (x)
  {
    x <- x[!is.na(x)]
    n <- length(x)
    x <- x - mean(x)
    y <- sqrt(n) * sum(x^3)/(sum(x^2)^(3/2))
    y * ((1 - 1/n))^(3/2)
  }
  checkSkewMatch <- function(Pow) {
    skewness(Dat_^Pow)
  }
  binarySearch(checkSkewMatch, c(0.001,1), Target = 0)
}
#Determine the power transform to best normalize the distribution of values
D3bpo4_ <- with(Tmp_df, D3bpo4[!IsZero])
D3Pow <- findPower(D3bpo4_)
# png("data/ua_pwr-transform-d3_dist.png", width = 480, height = 480)
# plot(density(D3bpo4_ ^ D3Pow), xlab = "Power-Transformed D3bpo4",
#      ylab = "Probability Density",
#      main = "Distribution of Block Group Power-Transformed D3bpo4")
# dev.off()
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
  #Set WtAveD3 to AveTarget is not NULL
  if (!is.null(AveTarget)){
    WtAveD3 <- AveTarget
  }
  #Set PropZeroD3 if PropZeroTarget is not NULL
  if (!is.null(PropZeroTarget)) {
    PropZeroD3 <- PropZeroTarget
  }
  #Retrieve model values consistent with area name
  if (AreaName %in% c("Town", "Rural")) {
    if (AreaName == "Town") {
      if (is.null(AveTarget)) {
        WtAveD3 <- SimBzone_ls$TnProfiles$WtAveD3
      }
      if (is.null(PropZeroTarget)) {
        PropZeroD3 <- SimBzone_ls$TnProfiles$PropZeroD3
      }
      RelPowWtAveD3_Pt <- SimBzone_ls$TnProfiles$RelPowWtAveD3_Pt
      RelPropZeroD3_Pt <- SimBzone_ls$TnProfiles$RelPropZeroD3_Pt
      PowWtSdD3_Pt <- SimBzone_ls$TnProfiles$PowWtSdD3_Pt
      D3Pow <- SimBzone_ls$TnProfiles$D3Pow
    } else {
      if (is.null(AveTarget)) {
        WtAveD3 <- SimBzone_ls$RuProfiles$WtAveD3
      }
      if (is.null(PropZeroTarget)) {
        PropZeroD3 <- SimBzone_ls$RuProfiles$PropZeroD3
      }
      RelPowWtAveD3_Pt <- SimBzone_ls$RuProfiles$RelPowWtAveD3_Pt
      RelPropZeroD3_Pt <- SimBzone_ls$RuProfiles$RelPropZeroD3_Pt
      PowWtSdD3_Pt <- SimBzone_ls$RuProfiles$PowWtSdD3_Pt
      D3Pow <- SimBzone_ls$RuProfiles$D3Pow
    }
  } else {
    if (is.null(AveTarget)) {
      WtAveD3 <- SimBzone_ls$UaProfiles$WtAveD3_Ua[AreaName]
    }
    if (is.null(PropZeroTarget)) {
      PropZeroD3 <- SimBzone_ls$UaProfiles$PropZeroD3[AreaName]
    }
    RelPowWtAveD3_Pt <- SimBzone_ls$UaProfiles$RelPowWtAveD3_UaPt[AreaName,]
    RelPropZeroD3_Pt <- SimBzone_ls$UaProfiles$RelPropZeroD3_UaPt[AreaName,]
    PowWtSdD3_Pt <- SimBzone_ls$UaProfiles$PowWtSdD3_Pt
    D3Pow <- SimBzone_ls$UaProfiles$D3Pow
  }
  if (!is.null(AveTarget)) WtAveD3 <- AveTarget
  if (!is.null(PropZeroTarget)) PropZeroD3 <- PropZeroTarget
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

#Test for Atlanta, halving 0 proportion and doubling average value
#-----------------------------------------------------------------
UzaName <- "Atlanta, GA"
ZeroProp <- SimBzone_ls$UaProfiles$PropZeroD3_Ua["Atlanta, GA"]
AveVal <- SimBzone_ls$UaProfiles$WtAveD3_Ua["Atlanta, GA"]
AtlD3_ <- calcD3bpo4(
  AreaType_Bz = Ua_df$AreaType[Ua_df$UZA_NAME == UzaName],
  DevType_Bz = Ua_df$DevType[Ua_df$UZA_NAME == UzaName],
  AreaName = UzaName,
  AveTarget <- NULL,
  PropZeroTarget <- NULL)
AtlD3Alt_ <- calcD3bpo4(
  AreaType_Bz = Ua_df$AreaType[Ua_df$UZA_NAME == UzaName],
  DevType_Bz = Ua_df$DevType[Ua_df$UZA_NAME == UzaName],
  AreaName = UzaName,
  AveTarget <- 2 * AveVal,
  PropZeroTarget <- ZeroProp / 2)
png("data/atlanta_D3_test.png", width = 500, height = 400)
plot(density(AtlD3_ ^ SimBzone_ls$UaProfiles$D3Pow),
     xlab = "Power-Transformed D3bpo4 Values",
     ylab = "Probability Density",
     main = "Effect on D3bpo4 Distribution of Halving 0 Proportion\nAnd Doubling Average Value")
lines(density(AtlD3Alt_ ^ SimBzone_ls$UaProfiles$D3Pow), col = "red")
LegendText_ <- c(
  paste0("Zero Prop. = ", round(ZeroProp, 2), "\n", "Ave. D3bpo4 = ", round(AveVal, 1)),
  paste0("Zero Prop. = ", round(ZeroProp / 2, 2), "\n", "Ave. D3bpo4 = ", round(AveVal * 2, 1))
)
legend("topleft", lty = 1, col = 1:2, legend = LegendText_, bty = "n")
dev.off()
rm(UzaName, ZeroProp, AveVal, AtlD3_, AtlD3Alt_, LegendText_)


#====================================
#SAVE MODEL PARAMETERS AND MODEL DATA
#====================================

#Save model parameters
#---------------------
#' SimBzone model parameters
#'
#' A list containing various parameters for SimBzone models
#'
#' @format A list having the following components:
#' \describe{
#'   \item{UaProfiles}{a list containing profiles for urbanized areas}
#'   \item{TnProfiles}{a list containing profiles for towns}
#'   \item{RuProfiles}{a list containing profiles for rural areas}
#'   \item{Abbr}{a list containing dimension naming vectors}
#'   \item{Docs}{a list containing miscellaneous model documentation objects}
#' }
#' @source CreateSimBzoneModels.R script.
"SimBzone_ls"
usethis::use_data(SimBzone_ls, overwrite = TRUE)

#Save place type related data values computed in the script
#----------------------------------------------------------
#Keep calculated block group values of location, area, and development types and
#levels for density, mixing, and destination accessibility measures
Keep_ <-
  c("GEOID10", "LocType", "D1DGrp", "D2Grp", "D5Grp", "AreaType", "DevType")
UsaBlkGrpTypes_df <- rbind(Ua_df[,Keep_], Tn_df[,Keep_], Ru_df[,Keep_])
#' Measures of land use types and levels for block groups
#'
#' A data frame containing values of for land use types and levels for land use
#' density, mixing, and destination accessibility measures corresponding to
#' block groups in the VESimLandUseData::SimLandUseData_df data frame
#'
#' @format A data frame having the following components:
#' \describe{
#'   \item{GEOID10}{a string that identifies the unique block group ID}
#'   \item{LocType}{a string that identifies the location type}
#'   \item{D1DGrp}{a factor that identifies the activity density level}
#'   \item{D2Grp}{a factor that identifies the land use mixing level}
#'   \item{D5Grp}{a factor that identifies the destination accessibility level}
#'   \item{AreaType}{a string that identifies the area type}
#'   \item{DevType}{a string that identifies the development type}
#' }
#' @source CreateSimBzoneModels.R script.
"UsaBlkGrpTypes_df"
usethis::use_data(UsaBlkGrpTypes_df, overwrite = TRUE)

#Clean up workspace
#------------------
rm(list=ls(all=TRUE))


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CreateSimBzoneModels")

