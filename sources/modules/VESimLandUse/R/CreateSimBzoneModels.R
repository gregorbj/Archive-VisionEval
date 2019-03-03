#======================
#CreateSimBzoneModels.R
#======================


#<doc>
## CreateSimBzoneModels Module
#### February 3, 2018
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
#* **Area Type**: Category identifying urban nature of the area (center, inner, outer, fringe)
#
#* **Development Type**: Category identifying whether development is characterized by predominantly residential, or employment, or is mixed
#
#* **Housing Units**: Numbers of single-family dwellings and multifamily dwellings in each SimBzone
#
#* **Employment by Sector**: Numbers of retail, service, and other jobs in the SimBzone
#
#* **Pedestrian Network Design**: Design of the transportation network to support non-motorized travel
#
#* **Transit Accessibility**: Level of peak period transit service near the SimBzone
#
### Model Parameter Estimation
#
#The process of developing SimBzones proceeds in a series of steps. Model parameters are developed for each step. In a number of cases the parameters take the form of specific urbanized area or more general profiles.
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
#**Table 1. Median Number of Households and Jobs in a Census Block Group by Location Type**
#
#The total amount of activity in each location type of the Azone is divided by the corresponding numbers in the table to arrive at the number of SimBzones by location type. Fractional remainders are allocated randomly among the SimBzones in each location type to get whole number amounts.
#
#### Assign an Activity Density to Each SimBzone
#
#Activity density (households and jobs per acre) is the key characteristic which drives the synthesis of all SimBzone characteristics. This measure is referred to as D1D in the SLD. The overall activity density of each location type in each Azone is determined by the allocations of households and jobs described above and user inputs on the areal extents of development. The activity density of SimBzones is determined by the overall density and by density distribution characteristics reflective of the area. Density distribution profiles developed for areas as noted above are used in the process.
#
#The distribution of activity density by block group is approximately lognormally distributed. This distribution is related to the overall density of the area. As the overall density increases, the density distribution shifts to the right. This is illustrated in the following figure which shows distributions for 9 urbanized areas having a range of overall densities from the least dense (Atlanta, GA) to the most dense (New York, NY). In each panel of the figure, the probability density of the activity density distribution of block groups in the urbanized area are shown by the solid line. The distribution for all urbanized areas is shown by the dashed line. As can be seen, as the overall density of the urbanized area increases, the density distribution shifts to the right.
#
#<fig:example-uza_d1_distributions.png>
#
#**Figure 1. Distributions of Block Group Activity Density for Selected Urbanized Areas**
#
#The characterization of activity density distributions is simplified by discretizing activity density values. The profile for each area is a combination of the proportion of activity at each level and the average density at each level. Levels for urbanized areas are created by dividing the lognormal distribution of activity density for all urbanized areas in the SLD into 20 equal intervals. Activity density levels for town and for rural areas are established in the same way. The following figure shows the distribution of urbanized area activity by activity density level and the average activity density at each level.
#
#<fig:uza_activity-density_level.png>
#
#**Figure 2. Proportions of Urbanized Area Activity and Average Density by Density Level**
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
#**Figure 3. Distribution of Block Group Jobs to Housing Ratio for Selected Urbanized Areas**
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
#**Figure 4. Diversity Group Proportion of Activity by Density Group, All Urbanized Areas**
#
#Several patterns can be seen in the relationship between activity density and mixing. Ignoring for now the lowest activity density levels, the jobs proportion of activity increases as activity density increases. Jobs dominate at the highest activity densities. This is consistent with the bid rent theory of spatial location. Businesses value higher density (more central) locations more highly than households and so outbid households for those locations. The greatest degree of activity mixing occurs in the 3rd quarter of the density range. There is no clear pattern at the lowest density levels which are represented by a very small number of block groups.
#
#The relationship between activity density and activity mix varies by metropolitan area as illustrated in the following figure which compares values for the 9 example urbanized areas. For example, it can be seen that jobs and housing are much more segregated in the Atlanta area than in the San Francisco-Oakland area.
#
#<fig:example-uza_d2group-prop-act_by_d1group.png>
#
#**Figure 5. Comparison of Distribution of Activity by Diversity and Density for Selected Urbanized Areas**
#
#Profiles illustrated in the preceding figures are developed for each of the urbanized areas listed in the **Initialize** module documentation, for each urbanized area size category, and for towns (as a whole), and rural areas (as a whole). These are used by the **CreateSimBzones** module to assign a activity mix level to each SimBzone based on the activity density of the SimBzone.
#
#### Split SimBzone Activity Between Jobs and Households
#
#The process of splitting the activity of each SimBzone between jobs and households is done in 2 steps. In the first step an initial value for the jobs proportion of activity is selected by sampling from distributions associated with each activity mix level. In the second step, a balancing process is used so that the distribution of jobs and households among SimBzones is consistent with the control totals of jobs and households by Azone and location type.
#
#The 1st step uses tabulations from the SLD of the numbers of block groups by employment proportion for each activity mix level. Those tabulations are converted into proportions of block groups that are then used as sampling distributions from which to choose an initial employment proportion based on the activity mix level of the SimBzone. The following figure shows the probability distributions of jobs proportions by activity mix levels. These are the sample distributions used to determine the initial jobs proportion for SimBzones located in urbanized areas. Similar sampling distributions are tabulated from the SLD for town locations and for rural locations.
#
#<fig:emp-prop-distribution_by_d2group.png>
#
#**Figure 6. Distributions of Jobs Proportions of Total Activity by Activity Mix Level**
#
#In the second step, jobs and household numbers by SimBzone are adjusted to be consistent with control totals by Azone and location type and activity totals by SimBzone. The difference between the control total of jobs and the allocated jobs is allocated as a function of the initial jobs allocations among zones and the respective capacities to accommodate more (or fewer) jobs.
#
#### Assign Destination Accessibility Measure Values to SimBzones
#
#Destination accessibility is a measure of the amount of activity present in the vicinity of each SimBzone. The measure used is the harmonic mean of the population within 5 miles and employment within 2 miles of the SimBzone. This measure was computed for each block group in the SLD using straight line distances between block group centroids. This measure is used instead of destination accessibility measures in the SLD which are auto oriented (for example, jobs within 45 minute travel time) and not very useful for measuring destination accessibility within smaller urbanized areas. The harmonic mean of population and employment was found to be useful for distinguishing *area types*, one of the dimensions in the *place type* system that is implemented in the Bzone synthesis process.
#
#Destination accessibility at the block group level, like the distribution of activity density, is approximately lognormally distributed. As with activity density, the distribution of destination accessibility is related to overall urbanized area density; shifting to the right as overall density increases.
#
#<fig:example-uza_d5_distributions.png>
#
#**Figure 7. Distributions of Destination Accessibility for Selected Urbanized Areas**
#
#The characterization of destination accessibility distributions is simplified by discretizing destination accessibility values. The profile for each area is a combination of the proportion of activity at each level and the average destination accessibility at each level. Levels for urbanized areas are created by dividing the lognormal distribution of destination accessibility for all urbanized areas in the SLD into 20 equal intervals. Destination accessibility levels for town and for rural areas are established in the same way. The following figure shows the distribution of urbanized area activity by destination accessibility level and the average destination accessibility at each level.
#
#<fig:uza_destination-accessibility_level.png>
#
#**Figure 8. Proportions of Urbanized Area Activity and Average Destination Accessibility by Destination Accessibility Level**
#
#Areas are profiled according to the distribution of activity among destination accessibility levels at each activity density level. In this way, the SimBzones created for an area can reasonably reflect observed conditions, and when a scenario having a different overall density is modeled, the joint distribution of activity density and destination accessibility will be a sensible result. The following figure illustrates the destination accessibility distributions by activity density level for 9 example metropolitan areas. It can be seen that except for low activity density levels (for which there are few census block groups) there is a relatively strong relationship between destination accessibility and activity density.
#
#<fig:example-uza_d5group-prop-act_by_d1group.png>
#
#**Figure 9. Activity Proportions by Destination Accessibility Level for Each Density Level for Selected Urbanized Areas**
#
#Profiles illustrated in the preceding figures are developed for each of the urbanized areas listed in the **Initialize** module documentation, for each urbanized area size category, and for towns (as a whole), and rural areas (as a whole). These are used by the **CreateSimBzone** module to assign a destination accessibility level to each SimBzone based on the activity density of the SimBzone.
#
#### Designate Place Types
#
#Place types are a land use classification system which simplifies the characterization of land use patterns. They are used in the estimation of the housing type, employment sector, pedestrian network, and transit access models.  They are used to simplify the management of inputs for land use related policies. There are three dimensions to the place type system. Location type identifies whether the SimBzone is located in an urbanized area (Urban), a smaller urban-type area (Town), or a non-urban area (Rural). Area types identify the relative urban nature of the SimBzone: center, inner, outer, fringe. Development types identify the character of development in the SimBzone: residential (res), employment (emp), mix.
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
#**Figure 10. Area Type and Development Type Designations for Atlanta and Portland Urbanized Areas**
#
#### Model Housing Types
#
#The housing types (single family, multifamily) occupied by households in each SimBzone are modeled and used in combination with a housing choice model to assign housing types to households, and to assign households to SimBzones. This is done for several reasons. First, dwelling type has a significant relationship to several important household transportation characteristics such as auto ownership. Second, modeling housing type provides a mechanism for assigning households to SimBzones (neighborhoods) having characteristics where they're more likely to live. For example, a large higher income household is more likely to live in a single-family dwelling and thus are more likely to live in a lower density neighborhood where single-family dwellings predominate.
#
#The proportion of housing units in multifamily dwellings is modeled as a function of area type and development type which are combined as place types (e.g. center-emp, center-mix, center-res). The model is simply a table of block group percentiles (2% intervals) of the multifamily housing unit proportion by place type. This table is prepared using the area type and development type designations applied to SLD block groups using the area and development type models, and the multifamily housing unit proportion attached to the SLD (see documentation for the VESimLandUseData package). The model uses all the SLD records instead of segmented by urbanized area or location type.
#
#The model is applied to assign multifamily and single family dwelling unit numbers in a SimBzone as follows:
#
#1) Choose the multifamily percentile distribution corresponding to the place type of the SimBzone;
#
#2) Randomly select a percentile from the distribution and return the corresponding multifamily housing unit proportion;
#
#2) Multiply the household total for the SimBzone by the selected proportion and round the result to calculate the number of households in multifamily housing units;
#
#4) Subtract the multifamily housing units from the household total to calculate the number of households in single family dwelling units.
#
#Despite the simplicity of the model, it does a reasonable job of simulating the distributions of multifamily housing unit proportions. This can be seen in the following figure which compares the distributions of observed and simulated multifamily housing proportions in several urbanized areas.
#
#<fig:ua_mf-prop_compare.png>
#
#**Figure 10. Comparison of Observed and Simulated Distributions of Multifamily Housing Proportions for Selected Urbanized Areas**
#
#### Split SimBzone Employment Into Sectors
#
#SimBzone employment is split into 3 sectors (retail, service, other) to enable the calculation of an entropy measure of land use mixing that is used in the forthcoming multimodal household travel module for VisionEval. The model for doing this is similar to the housing split model except that two percentile tables are made; one which tablulates the combined retail and service employment proportion of total employment in the block group, and another which tabulated the retail employment proportion of combined retail and service employment.
#
#As with the housing split model, all of the records in the SLD are used to estimate the model rather than segmenting the model by urbanized area or location type. The SLD 'E5_Ret10' and 'E5_Svc10' variables are used to indentify the numbers of retail and service jobs respectively in each block group, and the 'TotEmp' variable to identify the total number of jobs. The required proportions are calculated from these values. The block group area types and development types are the values calculated using the area and development type models.
#
#The model is applied to calculate the amounts of retail, service, and other jobs in each SimBzone as follows:
#
#1) Choose a percentile distribution of the retail-service proportion of total employment corresponding to the place type of the SimBzone.
#
#2) Randomly select a percentile from the distribution and return the corresponding retail-service job proportion;
#
#3) Multiply the selected proportion by the total employment and round the result to calculate the combined retail and service employment. Subtract from the total to calculate the number of other jobs.
#
#4) Choose a percentile distribution of the retail proportion of retail-service employment corresponding to the place type of the SimBzone.
#
#5) Randomly select a percentile from the distribution and return the corresponding retail job proportion;
#
#6) Multiply the selected proportion by the retail-service employment and round the result to calculate the retail employment and subtract from the retail-service employment to calculate the number of service jobs.
#
#Despite its simplicity, the model produces employment splits which enable entropy measures calculated using them to reasonably represent entropy measures calculated from observed employment. This can be seen in the following figure which compares observed and simulated entropy distributions for 9 example urbanized areas.
#
#<fig:ua_entropy_compare.png>
#
#**Figure 11. Comparison of Observed and Simulated Distributions of Entropy Measures of Land Use Mixing for Selected Urbanized Areas**
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
#The modeling approach for simulating the D3bpo4 measure is a variant of the approach used in the housing and employment split models. However, instead of modeling proportions using tables of percentiles by place type, normalized D3bpo4 values are modeled using these tables. The normalized D3bpo4 value for a zone (block group or SimBzone) is calculated by dividing the zonal value by the average of all zones in the urbanized area the zone is located in. Normalizing values helps to account for differences between urbanized areas and enables the data to be pooled to create a table of values by percentile and place type. For town locations and for rural locations the normalized values are calculated using the town and rural averages respectively.
#
#Tables of normalized D3bpo4 values by percentile and place type are calculated for urban, town, and rural locations. These are used in the same way as the housing and employment split tables are used. The location type of the SimBzone determines which table is used and the place type determines which set of percentiles are used. A percentile value is then selected as random from the selected set. If the SimBzone is located in an urbanized area, the selected normalized value is multiplied by the average for the urbanized area to compute the D3bpo4 value for the SimBzone. If the SimBzone is located in a town location or a rural location the selected value is multiplied by the town or rural average. The following figure compares the results of simulating D3bpo4 values using this approach with values from the SLD for 9 metropolitan areas. The log-transformed D3bpo4 values are shown to aid the comparison. The simplified model process does a reasonable job of reflecting observed values.
#
#<fig:ua_d3bpo4_compare.png>
#
#**Figure 12. Comparison of Observed and Simulated Distributions of D3bpo4 Values for Selected Urbanized Areas**
#
#### Model Transit Accessibility (D4c)
#
#Transit accessibility measures how easily transit service may be accessed from each zone. The SLD includes several transit accessibility measures. The D4c measure is the one used in the forthcoming multimodal household travel module. D4c is a measure of the aggregate frequency of transit service within 0.25 miles of the block group boundary per hour during evening peak period (4:00 PM to 7:00 PM). The measure was calculated by the EPA using Google GTFS data.
#
#The model to simulate D4c is only applied to urban locations. VisionEval does not model transit service and its effects in town or rural locations. The model has two parts. The first part is like the D3bpo4 model in that it uses a table of normalized D4c values by place type and percentile to select a normalized D4c value for a SimBzone which is multiplied by the average D4c value for the urbanized area the SimBzone is located in to calculate the D4c value for the SimBzone. The second model computes the average D4c value for an urbanized area as a function of the overall transit supply for the urbanized area (transit revenue miles) and urbanized area density. Because of limited availability of GTFS data at the time the SLD was being developed, D4c data are only present for about 30% of the urbanized areas included in the SLD. However since the urbanized areas for which data are missing are smaller urbanized areas, data are provided for over 70% of the block groups in the SLD. This provides plenty of datapoints for tabulating normalized values by percentile and place type, but is means that average D4c values are not available for the large majority of urbanized areas.
#
#Simulating D4c values as a function of place type using a table of normalized D4c values by percentile and place type does a reasonably good job of producing a sensible distribution of D4c values for urbanized areas. This can be seen in the following figure which compares log-transformed distributions for observed and simulated values for 8 urbanized areas. It should be noted that data for Jacksonville Florida are not shown, unlike figures presented above. This is because D4c data are missing for Jacksonville.
#
#<fig:ua_d4c_compare1.png>
#
#**Figure 13. Comparison of Observed and Simulated Distributions of D4c Values for Selected Urbanized Areas**
#
#An important goal of this model is to be sensitive to public transit service level (i.e. transit revenue miles). If the amount of transit service in an urbanized area changes, the average D4c value for the urbanized area should change as well. One would expect there to be a general relationship between the density of transit service (e.g. revenue miles per acre) and the average D4c value. This relationship can be calculated directly from the augmented SLD database (which contains transit revenue miles) for the urbanized areas for which D4c values are provided (~ 30% of the urbanized areas). For these urbanized areas, the ratio of average D4c and transit revenue mile density is calculated. This ratio is used in model applications to calculate the average D4c value for an urbanized area from the transit revenue miles and geographic area of the urbanized area. The following figure shows the distribution of values for these urbanized areas.
#
#<fig:ua_d4-supply-ratio_dist.png>
#
#**Figure 14: Distribution of Urbanized Area Ratios of Average D4c to Transit Service Density**
#
#For other urbanized areas a model of the relationship needs to be employed. This is developed from the data for the urbanized area that have recorded D4c values. The following chart plots the values of the log of average D4c against the log of transit revenue miles per acre for these urbanized areas. Plot symbols identify clusters that area described below. It can be seen that while the overall distribution shows no clear relationship, the data appear to be in several clusters and that the data points clustered near the top have an upward-trending relationship. Kmeans cluster analysis was used to split the data into two clusters based on the axis measures. These are shown in the figure by the different plotting symbols.
#
#<fig:ua_ave-d4_vs_rev-mi-density.png>
#
#**Figure 15: Urbanized Area Average D4c vs. Transit Service Density**
#
#A linear model is estimated to fit the data shown in the upper cluster. A summary of the model statistics follows.
#
#<txt:SimBzone_ls$UaProfiles$AveD4cModel_ls$Summary>
#
#This model is used to predict the urbanized area average D4c value if the ratio of average D4c and transit revenue mile density is not available. The following figure compares the simulated D4c distributions for the sample urbanized areas using the modeled average D4c values vs. the values calculated from the SLD. As can be seen, the model-bases values are close the calculated values for some of the areas but depart substantially for a couple.
#
#<fig:ua_d4c_compare2.png>
#
#**Figure 16. Comparison of Simulated Distributions of D4c Values Using Modeled Values of Average D4c for Selected Urbanized Areas**
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
#' @import visioneval
#' @import plot3D
#' @import VESimLandUseData


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
# png("data/uza-size-group_d2group-prop-act_by_d1group.png", width = 700, height = 500)
# DispPal_ <- colorRampPalette(c("black", "yellow"))(10)
# InitPar_ls <- par(mfrow = c(2,3), mar = c(3,4,3,3), oma = c(0, 0, 2.2, 0))
# for (sz in Sz) {
#   ImageDat_D1D2 <- SimBzone_ls$UaProfiles$D2ActProp_Ua_D1D2[[sz]]
#   image2D(ImageDat_D1D2,
#           x = 1:20, y = 1:5,
#           zlim = c(0,1),
#           xlab = "Density Group",
#           ylab = "Diversity Group",
#           col = DispPal_, NAcol = "black",
#           main = sz, axes = FALSE)
#   axis(1)
#   axis(2, at = 1:5,
#        labels = c("Prn\nHH", "Lrg\nHH", "Mix", "Lrg\nJOB", "Prn\nJOB"))
#   rm(ImageDat_D1D2)
# }
# mtext("Activity Proportions by Diversity Group for Each D1D Group\nBy Urbanized Area Size",
#       outer = TRUE, line = -0.5)
# par(InitPar_ls)
# dev.off()
# rm(InitPar_ls, DispPal_)

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
# png("data/uza-size-group_d5group-prop-act_by_d1group.png")
# InitPar_ls <- par(mfrow = c(3,2), mar = c(3,3,3,3), oma = c(0, 0, 2.2, 0))
# for (sz in Sz) {
#   imagePropAct(SimBzone_ls$UaProfiles$D5ActProp_Ua_D1D5[[sz]], main = sz)
# }
# mtext("Activity Proportions by D5 Group for Each D1D Group\nBy Urbanized Area Population Size Group",
#       outer = TRUE, line = -0.5)
# par(InitPar_ls)
# dev.off()
# rm(InitPar_ls)
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


#===========================
#DEVELOP HOUSING SPLIT MODEL
#===========================
#Make dataset for developing model
#---------------------------------
Fields_ <-
  c("HH", "PropSF", "PropMF", "AreaType", "DevType", "UZA_NAME")
Tmp_df <- rbind(Ua_df[,Fields_], Tn_df[,Fields_], Ru_df[,Fields_])
rm(Fields_)
Tmp_df$PlaceType <- with(Tmp_df, paste(AreaType, DevType, sep = "."))

#Calculate multi-family housing proportions by quantile and place type
#---------------------------------------------------------------------
MFProp_PtQt <- do.call(rbind, tapply(Tmp_df$PropMF, Tmp_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))

#Define function to split housing and apply to dataset
#-----------------------------------------------------
#Define function to split employment
splitHousing <- function(Hh_, PlaceType_) {
  MfProp_ <- sapply(PlaceType_, function(x) {
    sample(MFProp_PtQt[x,], 1)})
  MfDu_ <- round(Hh_ * MfProp_)
  SfDu_ <- Hh_ - MfDu_
  data.frame(
    MfDu = MfDu_,
    SfDu = SfDu_,
    MfProp = MfProp_
  )
}
#Split housing
DuSim_df <- splitHousing(Tmp_df$HH, Tmp_df$PlaceType)

#Plot comparison of observed and simulated multifamily housing proportions
#-------------------------------------------------------------------------
png("data/ua_mf-prop_compare.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(3,3))
for (ua in UzaToPlot_) {
  plot(density(Tmp_df$PropMF[Tmp_df$UZA_NAME == ua], na.rm = TRUE, bw = "SJ"), main = ua)
  lines(density(DuSim_df$MfProp[Tmp_df$UZA_NAME == ua], na.rm = TRUE, bw = "SJ"), lty = 2, col = "red")
  legend("topright", legend = c("Observed", "Simulated"), lty = 1:2, col = 1:2, bty = "n")
}
par(Opar_ls)
rm(Opar_ls)
dev.off()

#Save the multi-family housing proportions table
#-----------------------------------------------
SimBzone_ls$HousingSplit$MFProp_PtQt <- MFProp_PtQt
rm(Tmp_df, MFProp_PtQt, splitHousing, DuSim_df)


#===================================================================
#DEVELOP MODEL TO SPLIT EMPLOYMENT INTO SECTORS TO CALCULATE ENTROPY
#===================================================================
#Make dataset for developing model
#---------------------------------
Fields_ <-
  c("E5_RET10", "E5_SVC10", "EMPTOT", "HH", "AreaType", "DevType", "D2A_EPHHM",
    "UZA_NAME")
Tmp_df <- rbind(Ua_df[,Fields_], Tn_df[,Fields_], Ru_df[,Fields_])
rm(Fields_)
Tmp_df$RetEmp <- Tmp_df$E5_RET10
Tmp_df$SvcEmp <- Tmp_df$E5_SVC10
Tmp_df$RetSvcEmp <- with(Tmp_df, RetEmp + SvcEmp)
Tmp_df$TotEmp <- Tmp_df$EMPTOT
Tmp_df$RetSvcEmpProp <- with(Tmp_df, RetSvcEmp / Tmp_df$TotEmp)
Tmp_df$RetPropRetSvcEmp <- with(Tmp_df, RetEmp / RetSvcEmp)
Tmp_df$PlaceType <- with(Tmp_df, paste(AreaType, DevType, sep = "."))

#Calculate retail and service employment proportions by quantile and place type
#------------------------------------------------------------------------------
#Calculate retail service proportion of total employment quantiles by place type
RetSvcProp_PtQt <- do.call(rbind, tapply(Tmp_df$RetSvcEmpProp, Tmp_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))
#Calculate retail proportion of retail and service employment quantiles by place type
RetProp_PtQt <- do.call(rbind, tapply(Tmp_df$RetPropRetSvcEmp, Tmp_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))

#Define function to split employment and apply to dataset
#--------------------------------------------------------
#Define function to split employment
splitEmployment <- function(TotEmp_, PlaceType_) {
  RetSvcProp_ <- sapply(PlaceType_, function(x) {
    sample(RetSvcProp_PtQt[x,], 1)})
  RetSvcEmp_ <- TotEmp_ * RetSvcProp_
  OthEmp_ <- TotEmp_ - RetSvcEmp_
  RetProp_ <- sapply(PlaceType_, function(x) {
    sample(RetProp_PtQt[x,], 1)
  })
  RetEmp_ <- RetSvcEmp_ * RetProp_
  SvcEmp_ <- RetSvcEmp_ - RetEmp_
  data.frame(
    RetEmp = RetEmp_,
    SvcEmp = SvcEmp_,
    OthEmp = OthEmp_
  )
}
#Split employment
#----------------
EmpSim_df <- splitEmployment(Tmp_df$TotEmp, Tmp_df$PlaceType)

#Calculate entropy with simulated employment split and compare with observed
#---------------------------------------------------------------------------
#Define function to calculate entropy
calcEntropy <- function(In_df) {
  TotAct_ <- rowSums(In_df)
  calcEntropyTerm <- function(Act_) {
    ActRatio_ <- Act_ / TotAct_
    LogActRatio_ <- ActRatio_ * 0
    LogActRatio_[Act_ != 0] <- log(Act_[Act_ != 0] / TotAct_[Act_ != 0])
    ActRatio_ * LogActRatio_
  }
  E_df <- data.frame(lapply(In_df, function(x) calcEntropyTerm(x)))
  A_ <- rowSums(E_df)
  N_ = apply(E_df, 1, function(x) sum(x != 0))
  -A_ / log(N_)
}
#Calculate entropy with simulated employment split
Act_df <- EmpSim_df
Act_df$Hh <- Tmp_df$HH
rm(EmpSim_df)
SimEntropy_ <- calcEntropy(Act_df)
#Plot comparison of simulated entropy
png("data/ua_entropy_compare.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(3,3))
for (ua in UzaToPlot_) {
  plot(density(Tmp_df$D2A_EPHHM[Tmp_df$UZA_NAME == ua], bw = "SJ"), main = ua)
  lines(density(SimEntropy_[Tmp_df$UZA_NAME == ua], bw = "SJ"), lty = 2, col = "red")
  legend(0.5, 0, legend = c("Observed", "Simulated"), lty = 1:2, col = 1:2,
         xjust = 0.5, yjust = 0, bty = "n")
}
par(Opar_ls)
rm(Opar_ls)
dev.off()

#Save the proportions tables
#---------------------------
SimBzone_ls$EmpSplit$RetSvcProp_PtQt <- RetSvcProp_PtQt
SimBzone_ls$EmpSplit$RetProp_PtQt <- RetProp_PtQt
rm(Tmp_df, RetSvcProp_PtQt, RetProp_PtQt, splitEmployment, calcEntropy, Act_df,
   SimEntropy_)


#============================================================
#DEVELOP MODEL OF PEDESTRIAN NETWORK DESIGN VARIABLE (D3BPO4)
#============================================================

#---------------------------------
#DEVELOP MODEL FOR URBAN LOCATIONS
#---------------------------------

#Make dataset for developing model
#---------------------------------
Fields_ <-
  c("D3bpo4", "AreaType", "DevType", "UZA_NAME", "UZA_SIZE")
Tmp_df <- Ua_df[,Fields_]
rm(Fields_)
Tmp_df$PlaceType <- with(Tmp_df, paste(AreaType, DevType, sep = "."))

#Calculate a normalized D3bpo4 value
#-----------------------------------
#Split the dataset by urbanized area
Tmp_Ua_df <- split(Tmp_df, Tmp_df$UZA_NAME)
#Calculate the urbanized area average and normalized values
Tmp_Ua_df <- lapply(Tmp_Ua_df, function(x) {
  x$AveD3bpo4 <- mean(x$D3bpo4)
  x$NormD3bpo4 <- x$D3bpo4 / x$AveD3bpo4
  x$NormD3bpo4[is.na(x$NormD3bpo4)] <- 0
  x
})
Tmp_df <- do.call(rbind, Tmp_Ua_df)
rm(Tmp_Ua_df)

#Calculate normalized proportions by quantile and place type
#-----------------------------------------------------------
NormD3bpo4_PtQt <- do.call(rbind, tapply(Tmp_df$NormD3bpo4, Tmp_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))

#Define function to simulate the D3bpo4 value
#--------------------------------------------
simulateD3bpo4 <- function(AveD3bpo4_, PlaceType_, NormD3bpo4_PtQt) {
  NormD3bpo4_ <- sapply(PlaceType_, function(x) {
    sample(NormD3bpo4_PtQt[x,], 1)})
  NormD3bpo4_ * AveD3bpo4_
}
#Simulate values
SimD3bpo4_ <- simulateD3bpo4(Tmp_df$AveD3bpo4, Tmp_df$PlaceType, NormD3bpo4_PtQt)

#Plot comparison of simulated and observed D3bpo4
#------------------------------------------------
png("data/ua_d3bpo4_compare.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(3,3))
for (ua in UzaToPlot_) {
  plot(density(log1p(Tmp_df$D3bpo4[Tmp_df$UZA_NAME == ua]), bw = 0.1), main = ua)
  lines(density(log1p(SimD3bpo4_[Tmp_df$UZA_NAME == ua]), bw = 0.1), lty = 2, col = "red")
  legend("topright", legend = c("Observed", "Simulated"), lty = 1:2, col = 1:2, bty = "n")
}
par(Opar_ls)
rm(Opar_ls)
dev.off()

#Save the quantiles and urban area averages
#------------------------------------------
#Save the quantiles
SimBzone_ls$UaProfiles$NormD3bpo4_PtQt <- NormD3bpo4_PtQt
#Calculate and save average D3bpo4 by urbanized area
SimBzone_ls$UaProfiles$AveD3bpo4_Ua <- c(
  tapply(Tmp_df$D3bpo4, Tmp_df$UZA_NAME, mean),
  tapply(Tmp_df$D3bpo4, Tmp_df$UZA_SIZE, mean)
)
#Clean up
rm(Tmp_df, NormD3bpo4_PtQt, SimD3bpo4_)

#--------------------------------
#DEVELOP MODEL FOR TOWN LOCATIONS
#--------------------------------

#Make dataset for developing model
#---------------------------------
Fields_ <-
  c("D3bpo4", "TOTACT", "AreaType", "DevType")
Tmp_df <- Tn_df[,Fields_]
rm(Fields_)
Tmp_df$PlaceType <- with(Tmp_df, paste(AreaType, DevType, sep = "."))
#Calculate a normalized D3bpo4 value
Tmp_df$AveD3bpo4 <- mean(Tmp_df$D3bpo4)
Tmp_df$NormD3bpo4 <- Tmp_df$D3bpo4 / Tmp_df$AveD3bpo4

#Calculate normalized proportions by percentile and place type
#-------------------------------------------------------------
NormD3bpo4_PtQt <- do.call(rbind, tapply(Tmp_df$NormD3bpo4, Tmp_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))

#Save the quantiles and town average
#-----------------------------------
#Save the quantiles
SimBzone_ls$TnProfiles$NormD3bpo4_PtQt <- NormD3bpo4_PtQt
#Calculate and save average D3bpo4
SimBzone_ls$TnProfiles$AveD3bpo4 <- Tmp_df$AveD3bpo4[1]
#Clean up
rm(Tmp_df, NormD3bpo4_PtQt)

#---------------------------------
#DEVELOP MODEL FOR RURAL LOCATIONS
#---------------------------------

#Make dataset for developing model
#---------------------------------
Fields_ <-
  c("D3bpo4", "TOTACT", "AreaType", "DevType")
Tmp_df <- Ru_df[,Fields_]
rm(Fields_)
Tmp_df$PlaceType <- with(Tmp_df, paste(AreaType, DevType, sep = "."))
#Calculate a normalized D3bpo4 value
Tmp_df$AveD3bpo4 <- mean(Tmp_df$D3bpo4)
Tmp_df$NormD3bpo4 <- Tmp_df$D3bpo4 / Tmp_df$AveD3bpo4

#Calculate normalized proportions by percentile and place type
#-------------------------------------------------------------
#Calculate normalized proportions, note there are no 'center' area types
NormD3bpo4_PtQt <- do.call(rbind, tapply(Tmp_df$NormD3bpo4, Tmp_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))
#Rural locations don't have center area types and are unlikely to but to handle
#the case that a model might, assign the inner place type values to center area
#type values
NormD3bpo4_PtQt <- rbind(
  NormD3bpo4_PtQt,
  center.emp = NormD3bpo4_PtQt["inner.emp",],
  center.mix = NormD3bpo4_PtQt["inner.mix",],
  center.res = NormD3bpo4_PtQt["inner.res",]
)

#Save the quantiles and rural average
#------------------------------------
#Save the quantiles
SimBzone_ls$RuProfiles$NormD3bpo4_PtQt <- NormD3bpo4_PtQt
#Calculate and save average D3bpo4
SimBzone_ls$RuProfiles$AveD3bpo4 <- Tmp_df$AveD3bpo4[1]
#Clean up
rm(Tmp_df, NormD3bpo4_PtQt)


#=================================================
#DEVELOP MODEL OF ACCESS TO TRANSIT VARIABLE (D4C)
#=================================================

#Create D4 analysis dataset for urbanized areas
#----------------------------------------------
KeepVars_ <- c(
  "UA_NAME", "TransitRevMi", "D4c", "TOTACT", "AreaType", "DevType", "AC_LAND", "D1D")
#Limit to records that have D4c and TransitVehMi data
D4_df <- Ua_df[!(is.na(Ua_df$D4c)) & !(is.na(Ua_df$TransitVehMi)), KeepVars_]
rm(KeepVars_)
names(D4_df) <-
  c("UaName", "TranRevMi", "D4c", "TotAct", "AreaType", "DevType", "AcLand", "D1D")
#Identify which D4 values are 0 and remove urbanized areas that have all 0 values
Is0D4 <- D4_df$D4c == 0
All0D4_Ua <- tapply(Is0D4, D4_df$UaName, all)
RemoveUaName_ <- names(All0D4_Ua[All0D4_Ua])
D4_df <- D4_df[!(D4_df$UaName %in% RemoveUaName_),]
#Add a place type variable
D4_df$PlaceType <- with(D4_df, paste(AreaType, DevType, sep = "."))
rm(Is0D4, All0D4_Ua, RemoveUaName_)

#Calculate and add urbanized area statistics to D4_df
#-----------------------------------------------------
#Split the dataset by urbanized area
D4_Ua_df <- split(D4_df, D4_df$UaName)
#Calculate urbanized area statistics
D4_Ua_df <- lapply(D4_Ua_df, function(x) {
  x$TranRevMiPerAc <- x$TranRevMi[1] / sum(x$AcLand)
  x$AveD4c <- sum(x$D4c * x$AcLand) / sum(x$AcLand)
  x$AveD1D <- sum(x$TotAct) / sum(x$AcLand)
  x$NormD4c <- x$D4c / x$AveD4c
  x
})
#Rebuild D4_df with the urbanized area statistics
D4_df <- do.call(rbind, D4_Ua_df)

#Calculate quantiles of normalized D4c values by place type
#----------------------------------------------------------
#Calculate quantiles by place type
NormD4_PtQt <- do.call(rbind, tapply(D4_df$NormD4c, D4_df$PlaceType, function(x) {
  quantile(x, probs = seq(0, 1, 0.02), na.rm = TRUE)
}))
#Add quantiles to SimBzone_ls
SimBzone_ls$UaProfiles$NormD4_PtQt <- NormD4_PtQt

#Define function to simulate the D4c value
#-----------------------------------------
#Define function to simulate D4c as a function of the average D4c value for the
#urbanized area and the place type
simulateD4c <- function(AveD4c_, PlaceType_, NormD4_PtQt) {
  NormD4_ <- sapply(PlaceType_, function(x) {
    sample(NormD4_PtQt[x,], 1)})
  NormD4_ * AveD4c_
}

#Simulate values for the dataset and compare with SLD values
#-----------------------------------------------------------
SimD4c_ <- simulateD4c(D4_df$AveD4c, D4_df$PlaceType, NormD4_PtQt)
#Identify urbanized areas to compare
UaToPlot_ <- c("Atlanta, GA", "Cincinnati, OH-KY-IN",
               "Dallas-Fort Worth-Arlington, TX",
               "Baltimore, MD", "Denver-Aurora, CO",
               "Portland, OR-WA", "San Francisco-Oakland, CA",
               "New York-Newark, NY-NJ-CT")
#Plot comparisons
png("data/ua_d4c_compare1.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(3,3))
for (ua in UaToPlot_[UaToPlot_ %in% D4_df$UaName]) {
  plot(density(log1p(D4_df$D4c[D4_df$UaName == ua]), bw = 0.05), main = ua)
  lines(density(log1p(SimD4c_[D4_df$UaName == ua]), bw = 0.05), lty = 2, col = "red")
  legend("topright", legend = c("Observed", "Simulated"), lty = 1:2, col = 1:2, bty = "n")
}
par(Opar_ls)
rm(Opar_ls)
dev.off()

#Create dataset for estimating model to predict average D4c
#----------------------------------------------------------
#Create a data frame of urbanized area characteristics to use in model
Fields_ <- c("UaName", "TranRevMiPerAc", "AveD4c", "AveD1D")
UaD4_df <- do.call(rbind, lapply(D4_Ua_df, function(x) x[1, Fields_]))
#Compute natural logs of variables to be used in model
UaD4_df$LogTranRevMiPerAc <- log(UaD4_df$TranRevMiPerAc)
UaD4_df$LogAveD4c <- log(UaD4_df$AveD4c)
UaD4_df$LogAveD1D <- log(UaD4_df$AveD1D)

#Calculate the relationship of average D4c to transit revenue mile density
#-------------------------------------------------------------------------
#Add a supply ratio variable which is the ratio of AveD4c and TranRevMiPerAc
#This enables urbanized area AveD4c to be predicted from the TranRevMiPerAc
UaD4_df$D4SupplyRatio <- UaD4_df$AveD4c / UaD4_df$TranRevMiPerAc
#Show the distribution of ratio values
png("data/ua_d4-supply-ratio_dist.png", width = 400, height = 400)
plot(density(UaD4_df$D4SupplyRatio, bw = "SJ"), xlab = "AveD4c / RevMiPerAc",
     ylab = "Probability Density", main = "")
dev.off()
#Create a vector of urbanized area supply ratios for all urbanized areas
#Put NA if there isn't a ratio
Uza_df <- do.call(rbind, lapply(split(Ua_df, Ua_df$UZA_NAME), function(x) {
  x[1,c("UA_NAME", "UZA_NAME")]
}))
D4SupplyRatio_Ua <- UaD4_df$D4SupplyRatio[match(Uza_df$UA_NAME, UaD4_df$UaName)]
names(D4SupplyRatio_Ua) <- Uza_df$UZA_NAME
#Add D4 supply ratio to SimBzone_ls
SimBzone_ls$UaProfiles$D4SupplyRatio_Ua <- D4SupplyRatio_Ua
rm(Uza_df, D4SupplyRatio_Ua)

#Use cluster analysis to identify useful dataset to model AveD4c
#---------------------------------------------------------------
#K-means cluster analysis to split into 2 clusters
set.seed(1)
D4_KM <- kmeans(UaD4_df[,c("LogTranRevMiPerAc", "LogAveD4c")], 2, nstart = 20)
#Assign cluster values to urbanized area data frame
UaD4_df$Cluster <- D4_KM$cluster
#Identify the cluster that will be used. This is the top cluster (i.e. has a
#higher mean value for LogAveD4c)
ClusMeanLogAveD4c <- D4_KM$centers[,"LogAveD4c"]
UseClus <- which(ClusMeanLogAveD4c == max(ClusMeanLogAveD4c))
rm(D4_KM, ClusMeanLogAveD4c)

#Estimate model of LogAveD4c
#---------------------------
#Create data frame for estimating linear model
LmDat_df <-
  UaD4_df[UaD4_df$Cluster == UseClus, c("LogTranRevMiPerAc", "LogAveD4c", "LogAveD1D")]
#Estimate model
AveD4c_LM <- lm(LogAveD4c ~ LogTranRevMiPerAc * LogAveD1D, data = LmDat_df)
#Plot the data, highlight used cluster, show regression line
png("data/ua_ave-d4_vs_rev-mi-density.png", width = 400, height = 400)
Pch_ <- rep(4, nrow(UaD4_df))
Pch_[UaD4_df$Cluster == UseClus] <- 16
with(UaD4_df, plot(LogTranRevMiPerAc, LogAveD4c, pch = Pch_))
abline(coefficients(AveD4c_LM)[1:2])
dev.off()
rm(Pch_)

#Predict the average AveD4c values and compare D4c simulation results
#--------------------------------------------------------------------
#Predict average
PredLogAveD4c_ <- predict(AveD4c_LM, newdata = UaD4_df)
PredAveD4c_ <- exp(PredLogAveD4c_)
names(PredAveD4c_) <- UaD4_df$UaName
#Add to block group dataset
D4_df$PredAveD4c <- PredAveD4c_[D4_df$UaName]
#Simulate values
SimPredD4c_ <- simulateD4c(D4_df$PredAveD4c, D4_df$PlaceType, NormD4_PtQt)
#Plot comparison
png("data/ua_d4c_compare2.png", height = 600, width = 600)
Opar_ls <- par(mfrow = c(3,3))
for (ua in UaToPlot_[UaToPlot_ %in% D4_df$UaName]) {
  plot(density(log1p(D4_df$D4c[D4_df$UaName == ua]), bw = 0.05), main = ua)
  lines(density(log1p(SimD4c_[D4_df$UaName == ua]), bw = 0.05), lty = 2, col = "red")
  lines(density(log1p(SimPredD4c_[D4_df$UaName == ua]), bw = 0.05), lty = 3, col = "blue")
  legend("topright", legend = c("Observed", "Simulated w/ Observed Ave.", "Simulated w/ Modeled Ave."), lty = 1:2, col = 1:2, bty = "n")
}
par(Opar_ls)
rm(Opar_ls)
dev.off()

#Save the model to predict AveD4c
#--------------------------------
#Create a list which implements the operation cost proportions model
AveD4cModel_ls <- list(
  Type = "linear",
  Formula = makeModelFormulaString(AveD4c_LM),
  PrepFun = function(In_df) {
    data.frame(
      LogTranRevMiPerAc = max(log(In_df$TranRevMiPerAc), -100),
      LogAveD1D = log(In_df$AveD1D),
      Intercept = 1)
  },
  OutFun = function(Result_) exp(Result_),
  Summary = capture.output(summary(AveD4c_LM))
)
#Add model to SimBzone_ls
SimBzone_ls$UaProfiles$AveD4cModel_ls <- AveD4cModel_ls


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
#'   \item{EmpSplit}{a list containing two matrices of employment proportions by placetype and quantile}
#'   \item{HousingSplit}{a list containing a matrix of multi-family dwelling unit proportions by placetype and quantile}
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



#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CreateSimBzoneModels")

