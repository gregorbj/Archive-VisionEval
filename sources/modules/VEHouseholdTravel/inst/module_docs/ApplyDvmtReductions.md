
# ApplyDvmtReductions Module
### November 21, 2018

This module applies the computed proportional reductions in household DVMT due to the application of travel demand management programs and the diversion of single-occupant vehicle travel to bicycles, electric bicycles, or other light-weight vehicles. It also computes added bike trips due to the diversion.

## Model Parameter Estimation

This module has no estimated model parameters.

## How the Module Works

The module loads from the datastore the proportional reductions in household DVMT calculated by the AssignDemandManagement module and DivertSovTravel module. It converts the proportional reductions to proportions of DVMT (i.e. 1 - proportional reduction), multiplies them, and multiplies by household DVMT to arrive at a revised household DVMT which is saved to the datastore. It computes the added 'bike' trips that would occur due to the diversion by calculating the diverted SOV travel and dividing by the average SOV trip length.


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

|NAME                 |TABLE     |GROUP |TYPE     |UNITS      |PROHIBIT     |ISELEMENTOF |
|:--------------------|:---------|:-----|:--------|:----------|:------------|:-----------|
|Dvmt                 |Household |Year  |compound |MI/DAY     |NA, < 0      |            |
|PropDvmtDiverted     |Household |Year  |double   |proportion |NA, < 0, > 1 |            |
|AveTrpLenDiverted    |Household |Year  |distance |MI         |NA, < 0      |            |
|PropTdmDvmtReduction |Household |Year  |double   |proportion |NA, < 0, > 1 |            |

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

|NAME          |TABLE     |GROUP |TYPE     |UNITS   |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                    |
|:-------------|:---------|:-----|:--------|:-------|:--------|:-----------|:------------------------------------------------------------------------------|
|Dvmt          |Household |Year  |compound |MI/DAY  |NA, < 0  |            |Average daily vehicle miles traveled by the household in autos or light trucks |
|SovToBikeTrip |Household |Year  |compound |TRIP/YR |NA, < 0  |            |Annual extra trips allocated to bicycle model as a result of SOV diversion     |
