
# AdjustVehicleOwnership Module
### November 23, 2018

This module adjusts household vehicle ownership based on a comparison of the cost of owning a vehicle per mile of travel compared to the cost per mile of using a car service where the level of service is high. The determination of whether car services are substituted for ownership also depends on input assumptions regarding the average likelihood that an owner would substitute car services for a household vehicle.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

The module loads car service cost and substitution probability datasets that are inputs to the CreateVehicleTable module, car service service levels that are inputs from the AssignCarSvcAvailability module, and household vehicle ownership cost data that are outputs of the CalculateVehicleOwnCost module. The module compares the vehicle ownership cost per mile of travel for all vehicles of households living in zones where there is a high level of car service with the cost per mile of using a car service. The module flags all all vehicles where car service is high and the car service use cost is lower than the ownership cost. For those flagged vehicles, the module randomly changes their status from ownership to car service where the probability of change is the substitution probability. For example, if the user believes that only a quarter of light truck owners would substitute car services for owning a light truck (because car services wouldn't enable them to use their light truck as they intend, such as towing a trailer), then the substitution probability would be 0.25. For vehicles where it is determined that car services will substitute for a household vehicle, then the vehicle status is changed from 'Own' to 'HighCarSvc' and the ownership and insurance costs are changed as well. The household's vehicle totals are changed as well.


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
|Azone               |Azone     |Year  |character |ID         |             |                           |
|HighCarSvcCost      |Azone     |Year  |currency  |USD        |NA, < 0      |                           |
|LowCarSvcCost       |Azone     |Year  |currency  |USD        |NA, < 0      |                           |
|AveCarSvcVehicleAge |Azone     |Year  |time      |YR         |NA, < 0      |                           |
|LtTrkCarSvcSubProp  |Azone     |Year  |double    |proportion |NA, < 0, > 1 |                           |
|AutoCarSvcSubProp   |Azone     |Year  |double    |proportion |NA, < 0, > 1 |                           |
|HhId                |Household |Year  |character |ID         |             |                           |
|Vehicles            |Household |Year  |vehicles  |VEH        |NA, < 0      |                           |
|NumLtTrk            |Household |Year  |vehicles  |VEH        |NA, < 0      |                           |
|NumAuto             |Household |Year  |vehicles  |VEH        |NA, < 0      |                           |
|CarSvcLevel         |Household |Year  |character |category   |             |Low, High                  |
|Azone               |Vehicle   |Year  |character |ID         |NA           |                           |
|HhId                |Vehicle   |Year  |character |ID         |NA           |                           |
|VehId               |Vehicle   |Year  |character |ID         |NA           |                           |
|VehicleAccess       |Vehicle   |Year  |character |category   |             |Own, LowCarSvc, HighCarSvc |
|Type                |Vehicle   |Year  |character |category   |NA           |Auto, LtTrk                |
|Age                 |Vehicle   |Year  |time      |YR         |NA, < 0      |                           |
|OwnCost             |Vehicle   |Year  |currency  |USD        |NA, < 0      |                           |
|OwnCostPerMile      |Vehicle   |Year  |currency  |USD        |NA, < 0      |                           |
|InsCost             |Vehicle   |Year  |currency  |USD        |NA, < 0      |                           |

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

|NAME           |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF                |DESCRIPTION                                                                                                                                                                                                                                |
|:--------------|:---------|:-----|:---------|:--------|:--------|:--------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Age            |Vehicle   |Year  |time      |YR       |NA, < 0  |                           |Vehicle age in years                                                                                                                                                                                                                       |
|VehicleAccess  |Vehicle   |Year  |character |category |         |Own, LowCarSvc, HighCarSvc |Identifier whether vehicle is owned by household (Own), if vehicle is low level car service (LowCarSvc), or if vehicle is high level car service (HighCarSvc)                                                                              |
|OwnCost        |Vehicle   |Year  |currency  |USD      |NA, < 0  |                           |Annual cost of vehicle ownership including depreciation, financing, insurance, taxes, and residential parking in dollars                                                                                                                   |
|OwnCostPerMile |Vehicle   |Year  |currency  |USD      |NA, < 0  |                           |Annual cost of vehicle ownership per mile of vehicle travel (dollars per mile)                                                                                                                                                             |
|InsCost        |Vehicle   |Year  |currency  |USD      |NA, < 0  |                           |Annual vehicle insurance cost in dollars                                                                                                                                                                                                   |
|SwitchToCarSvc |Vehicle   |Year  |integer   |binary   |         |0, 1                       |Identifies whether a vehicle was switched from owned to car service                                                                                                                                                                        |
|OwnCostSavings |Household |Year  |currency  |USD      |NA, < 0  |                           |Annual vehicle ownership cost (depreciation, finance, insurance, taxes) savings in dollars resulting from substituting the use of car services for a household vehicle                                                                     |
|OwnCost        |Household |Year  |currency  |USD      |NA, < 0  |                           |Annual household vehicle ownership cost (depreciation, finance, insurance, taxes) savings in dollars                                                                                                                                       |
|Vehicles       |Household |Year  |vehicles  |VEH      |NA, < 0  |                           |Number of automobiles and light trucks owned or leased by the household including high level car service vehicles available to driving-age persons                                                                                         |
|NumLtTrk       |Household |Year  |vehicles  |VEH      |NA, < 0  |                           |Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household                                                                                                                                               |
|NumAuto        |Household |Year  |vehicles  |VEH      |NA, < 0  |                           |Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household                                                                                                                              |
|NumHighCarSvc  |Household |Year  |vehicles  |VEH      |NA, < 0  |                           |Number of high level service car service vehicles available to the household (difference between number of vehicles owned by the household and number of driving age persons for households having availability of high level car services |
