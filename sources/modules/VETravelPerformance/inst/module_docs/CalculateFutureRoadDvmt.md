
# CalculateFutureRoadDvmt Module
### January 6, 2019

This module calculates future (non-base) year roadway DVMT by marea, vehicle type (light-duty, heavy truck, bus) and roadway class (freeway, arterial, other). These values are inputs to the CalculateRoadPerformance module which calculates congestion, trip speeds, and delays on urbanized area roadways. Although 'Future' is in the name of the module, it may also be used to model years prior to the base year.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

The module performs the following calculations:

* Marea urban heavy truck DVMT is calculated based on the HvyTrkDvmtGrowthBasis that is declared in the 'region_base_year_dvmt.csv' file, the marea factors calculated for that growth basis by the CalculateBaseRoadDvmt module, and the marea values for the growth basis (e.g. marea urban population if the growth basis is population). The urban heavy truck DVMT is the the DVMT occurring on roadways in the urbanized area.

* Region heavy truck DVMT is calculated based on the HvyTrkDvmtGrowthBasis that is declared in the 'region_base_year_dvmt.csv' file, the region factor calculated for that growth basis by the CalculateBaseRoadDvmt module, and the region value for the growth basis (e.g. region population if the growth basis is population). The region urban heavy truck DVMT is calculated by summing the marea urban heavy truck DVMT. The region non-urban heavy truck DVMT is calculated as the difference between the region heavy truck DVMT and the region urban heavy truck DVMT. The region urban and non-urban heavy truck DVMT is the DVMT occurring on urban (urbanized area) and non-urban roadways.

* Marea commercial light-duty DVMT is calculated for urban, town and rural locations. Unlike heavy truck DVMT, this is not DVMT on roadways. Instead it is the DVMT that is associated with the populations of households (both in terms of households and workers) residing in those locations. Commercial service DVMT is calculated at the marea level based on the ComSvcDvmtGrowthBasis that is declared in the 'region_base_year_dvmt.csv' file (HhDvmt, Population, Income) and the marea factors calculated for that growth basis by the CalculateBaseRoadDvmt module, and the marea values for the growth basis (e.g. marea urban population if the growth basis is population).

* Marea light-duty vehicle DVMT on urban roadways is calculated from by summing total LDV travel demand of urban households and associated commercial service vehicle travel, along with public transit van travel (computed by the AssignTransitService module in the VETransportSupply package). The total demand is multiplied by the LdvRoadDvmtLdvDemandRatio calculated in the CalculateBaseRoadDvmt module to convert total urban demand to urban roadway DVMT.

* Marea urban roadway DVMT by vehicle type and road class is calculated from the heavy truck urban road DVMT, light-duty vehicle urban road DVMT, bus urban road DVMT (calculated by the AssignTransitService module) and the freeway, arterial, and other road DVMT proportions by vehicle type. The DVMT proportions by road class and vehicle type are user inputs in the 'marea_dvmt_split_by_road_class.csv' file or are calculated from default (Highway Statistics) data by the Initialize module when not supplied by the user. For light-duty vehicles, the freeway and arterial proportions are combined. The CalculateRoadPerformance module calculates the split of light-duty vehicle DVMT between freeways and arterials as a function of congestion, speed, and congestion pricing.



## User Inputs
This module has no user input requirements.

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME                       |TABLE  |GROUP  |TYPE      |UNITS      |PROHIBIT |ISELEMENTOF                |
|:--------------------------|:------|:------|:---------|:----------|:--------|:--------------------------|
|HvyTrkDvmtGrowthBasis      |Region |Global |character |ID         |         |Income, Population         |
|ComSvcDvmtGrowthBasis      |Region |Global |character |ID         |         |HhDvmt, Income, Population |
|HvyTrkDvmtIncomeFactor     |Region |Global |compound  |MI/USD     |<= 0     |                           |
|HvyTrkDvmtPopulationFactor |Region |Global |compound  |MI/PRSN    |<= 0     |                           |
|Marea                      |Marea  |Global |character |ID         |         |                           |
|LdvFwyDvmtProp             |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|LdvArtDvmtProp             |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|LdvOthDvmtProp             |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|HvyTrkFwyDvmtProp          |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|HvyTrkArtDvmtProp          |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|HvyTrkOthDvmtProp          |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|BusFwyDvmtProp             |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|BusArtDvmtProp             |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|BusOthDvmtProp             |Marea  |Global |double    |proportion |< 0, > 1 |                           |
|ComSvcDvmtHhDvmtFactor     |Marea  |Global |double    |proportion |<= 0     |                           |
|ComSvcDvmtIncomeFactor     |Marea  |Global |compound  |MI/USD     |NA, < 0  |                           |
|HvyTrkDvmtIncomeFactor     |Marea  |Global |compound  |MI/USD     |NA, < 0  |                           |
|ComSvcDvmtPopulationFactor |Marea  |Global |compound  |MI/PRSN    |NA, < 0  |                           |
|HvyTrkDvmtPopulationFactor |Marea  |Global |compound  |MI/PRSN    |NA, < 0  |                           |
|LdvRoadDvmtLdvDemandRatio  |Marea  |Global |double    |ratio      |NA, <= 0 |                           |
|Marea                      |Marea  |Year   |character |ID         |         |                           |
|VanDvmt                    |Marea  |Year   |compound  |MI/DAY     |NA, < 0  |                           |
|BusDvmt                    |Marea  |Year   |compound  |MI/DAY     |NA, < 0  |                           |
|RuralPop                   |Marea  |Year   |people    |PRSN       |NA, < 0  |                           |
|TownPop                    |Marea  |Year   |people    |PRSN       |NA, < 0  |                           |
|UrbanPop                   |Marea  |Year   |people    |PRSN       |NA, < 0  |                           |
|RuralIncome                |Marea  |Year   |currency  |USD        |NA, < 0  |                           |
|TownIncome                 |Marea  |Year   |currency  |USD        |NA, < 0  |                           |
|UrbanIncome                |Marea  |Year   |currency  |USD        |NA, < 0  |                           |
|UrbanHhDvmt                |Marea  |Year   |compound  |MI/DAY     |NA, < 0  |                           |
|TownHhDvmt                 |Marea  |Year   |compound  |MI/DAY     |NA, < 0  |                           |
|RuralHhDvmt                |Marea  |Year   |compound  |MI/DAY     |NA, < 0  |                           |

## Datasets Produced by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

DESCRIPTION - A description of the data.

|NAME               |TABLE  |GROUP |TYPE     |UNITS  |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                              |
|:------------------|:------|:-----|:--------|:------|:--------|:-----------|:------------------------------------------------------------------------------------------------------------------------|
|HvyTrkUrbanDvmt    |Region |Year  |compound |MI/DAY |<= 0     |            |Base year Region heavy truck daily vehicle miles of travel in urbanized areas                                            |
|HvyTrkNonUrbanDvmt |Region |Year  |compound |MI/DAY |<= 0     |            |Base year Region heavy truck daily vehicle miles of travel in rural and town (i.e. non-urbanized) areas                  |
|ComSvcUrbanDvmt    |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Commercial service daily vehicle miles of travel associated with Marea urbanized household activity                      |
|ComSvcTownDvmt     |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Commercial service daily vehicle miles of travel associated with Marea town household activity                           |
|ComSvcRuralDvmt    |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Commercial service daily vehicle miles of travel associated with Marea rural household activity                          |
|HvyTrkUrbanDvmt    |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Heavy truck daily vehicle miles of travel on urbanized area roadways in the Marea                                        |
|LdvFwyArtDvmt      |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeway or arterial roadways |
|LdvOthDvmt         |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways               |
|HvyTrkFwyDvmt      |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways                    |
|HvyTrkArtDvmt      |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways           |
|HvyTrkOthDvmt      |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways              |
|BusFwyDvmt         |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways                            |
|BusArtDvmt         |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways                   |
|BusOthDvmt         |Marea  |Year  |compound |MI/DAY |NA, < 0  |            |Bus daily vehicle miles of travel in the urbanized portion of the Marea occuring on other roadways                       |
