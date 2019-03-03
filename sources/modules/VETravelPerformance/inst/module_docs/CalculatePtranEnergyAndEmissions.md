
# CalculatePtranEnergyAndEmissions Module
### January 23, 2019

This module calculates the energy consumption and carbon emissions from public transportation vehicles in urbanized areas. Note that fuel consumption and emissions from car services (e.g. taxi, Uber, Lyft) are calculated in conjunction with the calculation of household vehicle emissions and are attributed to the household.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

This module calculates the energy consumption and carbon emissions production public transit vehicles in urbanized areas in the following steps:

* The energy consumption characteristics (i.e. MPG, MPKWH) by vehicle type (van, bus, rail) and powertrain type (ICEV, HEV, BEV, EV) are loaded (these are default values set up in the version of the 'VEPowertrainAndFuels' package used to represent the vehicles and fuels scenario being modeled).

* Energy consumption and emissions for each vehicle type and marea are calculated by the following steps:

  * Get the DVMT for the vehicle type by marea produced by the 'AssignTransitService' module

  * Allocate DVMT for the type and marea to powertrains using the powertrain proportions that are default values or user inputs ('Initialize' module of 'VEPowertrainsAndFuels' package).

  * Calculate energy consumption for the vehicle type by powertrain type using the DVMT by powertrain type and the energy consumption characteristics (MPG, MPKWH) for the powertrain type. Energy consumption for ICEV and HEV vehicles is calculated in gas gallon equivalents (GGE) while energy consumption for BEV and EV vehicles are in kilowatt hours (KWH). Convert to equivalent megajoule (MJ) values.

  * Get the average carbon intensity of fuels for the vehicle type by marea and the average carbon intensity of electricity production by azone that are either default values or user inputs ('Initialize' module of the 'VEPowertrainsAndFuels' package). Multiply the carbon intensities by energy type and the energy consumption by type and sum to calculate the carbon emissions for the vehicle type by marea.

  * Calculate the average emissions per mile by marea for the vehicle type from the total emissions by marea for the vehicle type and the DVMT for the vehicle type by marea.



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

|NAME              |TABLE |GROUP |TYPE      |UNITS      |PROHIBIT     |ISELEMENTOF |
|:-----------------|:-----|:-----|:---------|:----------|:------------|:-----------|
|Marea             |Marea |Year  |character |ID         |             |            |
|Azone             |Azone |Year  |character |ID         |             |            |
|Marea             |Azone |Year  |character |ID         |             |            |
|ElectricityCI     |Azone |Year  |compound  |GM/MJ      |< 0          |            |
|TransitVanFuelCI  |Marea |Year  |compound  |GM/MJ      |< 0          |            |
|TransitBusFuelCI  |Marea |Year  |compound  |GM/MJ      |< 0          |            |
|TransitRailFuelCI |Marea |Year  |compound  |GM/MJ      |< 0          |            |
|BusDvmt           |Marea |Year  |compound  |MI/DAY     |<= 0         |            |
|RailDvmt          |Marea |Year  |compound  |MI/DAY     |<= 0         |            |
|VanDvmt           |Marea |Year  |compound  |MI/DAY     |<= 0         |            |
|BusPropBev        |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|BusPropHev        |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|BusPropIcev       |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|RailPropEv        |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|RailPropHev       |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|RailPropIcev      |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|VanPropBev        |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|VanPropHev        |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |
|VanPropIcev       |Marea |Year  |double    |proportion |NA, < 0, > 1 |            |

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

|NAME         |TABLE |GROUP |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                           |
|:------------|:-----|:-----|:--------|:-----|:--------|:-----------|:-------------------------------------------------------------------------------------------------------------------------------------|
|BusGGE       |Marea |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by bus transit vehicles in urbanized area in gas gallon equivalents                |
|RailGGE      |Marea |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by rail transit vehicles in urbanized area in gas gallon equivalents               |
|VanGGE       |Marea |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by van transit vehicles in urbanized area in gas gallon equivalents                |
|BusKWH       |Marea |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by bus transit vehicles in urbanized area in kilowatt-hours                              |
|RailKWH      |Marea |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by rail transit vehicles in urbanized area in kilowatt-hours                             |
|VanKWH       |Marea |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by van transit vehicles in urbanized area in kilowatt-hours                              |
|BusCO2e      |Marea |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by bus transit vehicles in urbanized area in grams                        |
|RailCO2e     |Marea |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by rail transit vehicles in urbanized area in grams                       |
|VanCO2e      |Marea |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by van transit vehicles in urbanized area in grams                        |
|BusCO2eRate  |Marea |Year  |compound |GM/MI |NA, < 0  |            |Average amount of carbon-dioxide equivalents produced by bus transit vehicles per mile of travel in urbanized area in grams per mile  |
|RailCO2eRate |Marea |Year  |compound |GM/MI |NA, < 0  |            |Average amount of carbon-dioxide equivalents produced by rail transit vehicles per mile of travel in urbanized area in grams per mile |
|VanCO2eRate  |Marea |Year  |compound |GM/MI |NA, < 0  |            |Average amount of carbon-dioxide equivalents produced by van transit vehicles per mile of travel in urbanized area in grams per mile  |
