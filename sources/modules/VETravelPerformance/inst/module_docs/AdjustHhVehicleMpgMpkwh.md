
# AdjustHhVehicleMpgMpkwh Module
### January 23, 2019

This module adjusts the fuel economy (MPG) and power efficiency (MPKWH) of household vehicles to reflect the effects of congestion, speed smoothing, and eco-driving that are calculated by the CalculateMpgMpkwhAdjustments module.

## Model Parameter Estimation

This module has no estimated parameters

## How the Module Works

The module adjusts the average MPG and MPKWH of household vehicles, including the car services used, to reflect the effects of congestion, speed smoothing, and eco-driving. The methods are described below. To simplify the presentation, all adjustments are referred to as fuel economy (FE) adjustments.

* **Calculate household vehicle FE adjustments to reflect congestion**: FE adjustments are calculated for each household vehicle as a function of the vehicle powertrain type and the proportion of the household's travel that is assigned to urban roads. If the vehicle powertrain is ICEV, the LdIceFactor is used to calculate MPG adjustments. The urban travel adjustment factor is the marea value and the rural travel adjustment is the regional value. These values are averaged using the urban and non-urban travel proportions for the household. If the vehicle powertrain is HEV, the urban and non-urban LdHevFactor values are used to calculate the MPG adjustment. If the vehicle powertrain is BEV, the urban and non-urban LdEvFactor values are used to calculate the MPKWH adjustment. If the vehicle powertrain is PHEV, the urban and non-urban LdHevFactor values are used to calculate the MPG adjustment and the urban and non-urban LdEvFactor values are used to calculate the MPKWH adjustment.

* **Calculate car service FE adjustments to reflect congestion**: Fleetwide FE adjustments are calculated for car service vehicles. The car service powertrains are classified as ICEV, HEV, and BEV. The relative powertrain proportions for car service autos and light trucks are loaded from the PowertrainFuelDefaults_ls in the PowertrainsAndFuels package version used in the model run. The MPG adjustment factor for car service autos is calculated by averaging the marea LdIceFactor and LdHevFactor values using the scaled ICEV and HEV proportions for automobiles. The MPG adjustment for light-trucks is calculated in a similar fashion. These average MPG adjustment factors are applied to the household vehicles listed as car service according to the vehicle type. The marea value for LdEvFactor is assigned to the MPKWH adjustment factor.

* **Calculate eco-driving adjustments**: Eco-driving households are assigned at random in sufficient numbers to satisfy the 'LdvEcoDrive' proportion specified for the marea in the 'marea_speed_smooth_ecodrive.csv' input file. For the ICEV vehicles owned by the eco-driving households, the eco-drive MPG adjustment factor is calculated by averaging the marea LdvEcoDrive factor and regional LdvEcoDrive factors with urban and non-urban DVMT proportions for the household. Eco-driving adjustments for non-eco-driving household vehicles and non-ICEV vehicles are set equal to 1.

* **Calculate speed smoothing adjustments**: The speed smoothing adjustment for urban travel is the marea LdvSpdSmoothFactor value. The non-urban value is 1. The value for each household is the average of the urban and non-urban speed smoothing adjustments using the household urban and rural travel proportions as the respective weights. The household average values are assigned to the household vehicles. As with eco-driving, the speed smoothing adjustments are only applied to ICEV vehicles.

* **Reconcile eco-driving and speed smoothing adjustments**: The maximum of the eco-driving and speed smoothing adjustments assigned to each vehicle is used to account for the joint effect of eco-driving and speed smoothing.

* **Calculate the joint effect of congestion adjustments and eco-driving & speed smoothing adjustments**: The joint effect of the congestion-related FE adjustment and the eco-driving & speed smoothing adjustment is the product of the two adjustments.

* **Calculate the adjusted MPG and MPKWH**: The MPG assigned to each vehicle is updated by multiplying its value by the MPG adjustment value assigned to the vehicle. Likewise, the MPKWH assigned to each vehicle is updated by multiplying its value by the MPKWH adjustment value assigned to the vehicle.

* **Adjust related vehicle fuel, energy, and emissions values**: The GPM (gallons per mile) values are updated by calculating the reciprocal of the updated MPG values. The ratio of the updated GPM value to the previous GPM value is used to scale the fuel emissions rate (FuelCO2ePM). Likewise the KWHPM (kilowatt-hours per mile) values are updated in the same way and so is the electricity emissions rate (ElecCO2ePM).


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

|NAME                |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT     |ISELEMENTOF                |
|:-------------------|:---------|:-----|:---------|:----------|:------------|:--------------------------|
|CarSvcAutoPropIcev  |Region    |Year  |double    |proportion |NA, < 0, > 1 |                           |
|CarSvcAutoPropHev   |Region    |Year  |double    |proportion |NA, < 0, > 1 |                           |
|CarSvcAutoPropBev   |Region    |Year  |double    |proportion |NA, < 0, > 1 |                           |
|CarSvcLtTrkPropIcev |Region    |Year  |double    |proportion |NA, < 0, > 1 |                           |
|CarSvcLtTrkPropHev  |Region    |Year  |double    |proportion |NA, < 0, > 1 |                           |
|CarSvcLtTrkPropBev  |Region    |Year  |double    |proportion |NA, < 0, > 1 |                           |
|LdvEcoDriveFactor   |Region    |Year  |double    |proportion |<= 0         |                           |
|LdIceFactor         |Region    |Year  |double    |proportion |<= 0         |                           |
|LdHevFactor         |Region    |Year  |double    |proportion |<= 0         |                           |
|LdEvFactor          |Region    |Year  |double    |proportion |<= 0         |                           |
|Marea               |Marea     |Year  |character |ID         |             |                           |
|LdvEcoDrive         |Marea     |Year  |double    |proportion |NA, < 0, > 1 |                           |
|LdvSpdSmoothFactor  |Marea     |Year  |double    |proportion |<= 0         |                           |
|LdvEcoDriveFactor   |Marea     |Year  |double    |proportion |<= 0         |                           |
|LdIceFactor         |Marea     |Year  |double    |proportion |<= 0         |                           |
|LdHevFactor         |Marea     |Year  |double    |proportion |<= 0         |                           |
|LdEvFactor          |Marea     |Year  |double    |proportion |<= 0         |                           |
|Marea               |Azone     |Year  |character |ID         |             |                           |
|Azone               |Azone     |Year  |character |ID         |             |                           |
|HhId                |Household |Year  |character |ID         |NA           |                           |
|IsEcoDrive          |Household |Year  |integer   |binary     |NA           |0, 1                       |
|LocType             |Household |Year  |character |category   |NA           |Urban, Town, Rural         |
|Vehicles            |Household |Year  |vehicles  |VEH        |NA, < 0      |                           |
|NumAuto             |Household |Year  |vehicles  |VEH        |NA, < 0      |                           |
|NumLtTrk            |Household |Year  |vehicles  |VEH        |NA, < 0      |                           |
|Dvmt                |Household |Year  |compound  |MI/DAY     |NA, < 0      |                           |
|UrbanDvmtProp       |Household |Year  |double    |proportion |NA, < 0, > 1 |                           |
|Marea               |Vehicle   |Year  |character |ID         |             |                           |
|Azone               |Vehicle   |Year  |character |ID         |             |                           |
|HhId                |Vehicle   |Year  |character |ID         |NA           |                           |
|VehId               |Vehicle   |Year  |character |ID         |NA           |                           |
|Type                |Vehicle   |Year  |character |category   |NA           |Auto, LtTrk                |
|Powertrain          |Vehicle   |Year  |character |category   |             |ICEV, HEV, PHEV, BEV, NA   |
|VehicleAccess       |Vehicle   |Year  |character |category   |             |Own, LowCarSvc, HighCarSvc |
|MPG                 |Vehicle   |Year  |compound  |MI/GGE     |NA, < 0      |                           |
|GPM                 |Vehicle   |Year  |compound  |GGE/MI     |NA, < 0      |                           |
|MPKWH               |Vehicle   |Year  |compound  |MI/KWH     |NA, < 0      |                           |
|KWHPM               |Vehicle   |Year  |compound  |KWH/MI     |NA, < 0      |                           |
|MPGe                |Vehicle   |Year  |compound  |MI/GGE     |NA, < 0      |                           |
|ElecDvmtProp        |Vehicle   |Year  |double    |proportion |NA, < 0, > 1 |                           |
|FuelCO2ePM          |Vehicle   |Year  |compound  |GM/MI      |NA, < 0      |                           |
|ElecCO2ePM          |Vehicle   |Year  |compound  |GM/MI      |NA, < 0      |                           |

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

|NAME         |TABLE     |GROUP |TYPE     |UNITS      |PROHIBIT     |ISELEMENTOF |DESCRIPTION                                                                                    |
|:------------|:---------|:-----|:--------|:----------|:------------|:-----------|:----------------------------------------------------------------------------------------------|
|MPG          |Vehicle   |Year  |compound |MI/GGE     |NA, < 0      |            |Average miles of vehicle travel powered by fuel per gasoline equivalent gallon                 |
|GPM          |Vehicle   |Year  |compound |GGE/MI     |NA, < 0      |            |Average gasoline equivalent gallons per mile of vehicle travel powered by fuel                 |
|MPKWH        |Vehicle   |Year  |compound |MI/KWH     |NA, < 0      |            |Average miles of vehicle travel powered by electricity per kilowatt-hour                       |
|KWHPM        |Vehicle   |Year  |compound |KWH/MI     |NA, < 0      |            |Average kilowatt-hours per mile of vehicle travel powered by electricity                       |
|MPGe         |Vehicle   |Year  |compound |MI/GGE     |NA, < 0      |            |Average miles of vehicle travel per gasoline equivalent gallon (fuel and electric powered)     |
|ElecDvmtProp |Vehicle   |Year  |double   |proportion |NA, < 0, > 1 |            |Average miles of vehicle travel per gasoline equivalent gallon (fuel and electric powered)     |
|FuelCO2ePM   |Vehicle   |Year  |compound |GM/MI      |NA, < 0      |            |Average grams of carbon-dioxide equivalents produced per mile of travel powered by fuel        |
|ElecCO2ePM   |Vehicle   |Year  |compound |GM/MI      |NA, < 0      |            |Average grams of carbon-dioxide equivalents produced per mile of travel powered by electricity |
|IsEcoDrive   |Household |Year  |integer  |binary     |NA           |0, 1        |Flag identifying whether drivers in household are eco-drivers                                  |
