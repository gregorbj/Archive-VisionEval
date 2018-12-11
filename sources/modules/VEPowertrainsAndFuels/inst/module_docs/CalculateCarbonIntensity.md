
# CalculateCarbonIntensity Module
### November 24, 2018

This module calculates the average carbon intensity of fuels (grams CO2e per megajoule) by transportation mode and vehicle type. The transportation modes and vehicle types are:

|Mode               |Vehicle Types           |
|-------------------|------------------------|
|Household          |automobile, light truck |
|Car Service        |automobile, light truck |
|Commercial Service |automobile, light truck |
|Heavy Truck        |heavy truck             |
|Public Transit     |van, bus, rail          |

Average fuel carbon intensities for public transit vehicles are calculated by Marea. The average fuel carbon intensities for the other mode vehicles are calculated for the entire model region. The module also calculates the average carbon intensity of electricity at the Azone level.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

If carbon intensities are provided as user inputs, those carbon intensities are used. If carbon intensity values are not provided, the module calculates the values using fuels information including the fuel type proportions, the biofuel mix proportions, and the fuel carbon intensity values. The fuel mix proportions are multiplied by the biofuel mix proportions to arrive a the proportions of fuel by all categories. These proportions are used as weights to calculate that average carbon intensity from the fuel carbon intensity values.


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

|NAME                       |TABLE  |GROUP |TYPE      |UNITS      |PROHIBIT     |ISELEMENTOF |
|:--------------------------|:------|:-----|:---------|:----------|:------------|:-----------|
|Azone                      |Azone  |Year  |character |ID         |             |            |
|Marea                      |Marea  |Year  |character |ID         |             |            |
|ElectricityCI              |Azone  |Year  |compound  |GM/MJ      |< 0          |            |
|TransitEthanolPropGasoline |Marea  |Year  |double    |proportion |< 0, > 1     |            |
|TransitBiodieselPropDiesel |Marea  |Year  |double    |proportion |< 0, > 1     |            |
|TransitRngPropCng          |Marea  |Year  |double    |proportion |< 0, > 1     |            |
|VanPropDiesel              |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|VanPropGasoline            |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|VanPropCng                 |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|BusPropDiesel              |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|BusPropGasoline            |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|BusPropCng                 |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|RailPropDiesel             |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|RailPropGasoline           |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|HhFuelCI                   |Region |Year  |compound  |GM/MJ      |< 0          |            |
|CarSvcFuelCI               |Region |Year  |compound  |GM/MJ      |< 0          |            |
|ComSvcFuelCI               |Region |Year  |compound  |GM/MJ      |< 0          |            |
|HvyTrkFuelCI               |Region |Year  |compound  |GM/MJ      |< 0          |            |
|TransitVanFuelCI           |Region |Year  |compound  |GM/MJ      |< 0          |            |
|TransitBusFuelCI           |Region |Year  |compound  |GM/MJ      |< 0          |            |
|TransitRailFuelCI          |Region |Year  |compound  |GM/MJ      |< 0          |            |
|TransitVanFuelCI           |Marea  |Year  |compound  |GM/MJ      |< 0          |            |
|TransitBusFuelCI           |Marea  |Year  |compound  |GM/MJ      |< 0          |            |
|TransitRailFuelCI          |Marea  |Year  |compound  |GM/MJ      |< 0          |            |

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

|NAME              |TABLE  |GROUP |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                          |
|:-----------------|:------|:-----|:--------|:-----|:--------|:-----------|:----------------------------------------------------------------------------------------------------|
|ElectricityCI     |Azone  |Year  |compound |GM/MJ |< 0      |            |Carbon intensity of electricity at point of consumption (grams CO2e per megajoule)                   |
|HhAutoFuelCI      |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by household automobiles (grams CO2e per megajoule)           |
|HhLtTrkFuelCI     |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by household light trucks (grams CO2e per megajoule)          |
|CarSvcAutoFuelCI  |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by car service automobiles (grams CO2e per megajoule)         |
|CarSvcLtTrkFuelCI |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by car service light trucks (grams CO2e per megajoule)        |
|ComSvcAutoFuelCI  |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by commercial service automobiles (grams CO2e per megajoule)  |
|ComSvcLtTrkFuelCI |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by commercial service light trucks (grams CO2e per megajoule) |
|HvyTrkFuelCI      |Region |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)                    |
|TransitVanFuelCI  |Marea  |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuel used by transit vans (grams CO2e per megajoule)                     |
|TransitBusFuelCI  |Marea  |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuel used by transit buses (grams CO2e per megajoule)                    |
|TransitRailFuelCI |Marea  |Year  |compound |GM/MJ |< 0      |            |Average carbon intensity of fuel used by transit rail vehicles (grams CO2e per megajoule)            |
