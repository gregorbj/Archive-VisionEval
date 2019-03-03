
# AssignCarSvcAvailability Module
### February 7, 2019

This module assigns car service availability levels (Low, High) to Bzones and households. Car services include taxis, car sharing services (e.g. Car-To-Go, Zipcar), and future automated taxi services. A high car service level is one that has access times that are competitive with private car use, where access time is the time to get to the vehicle (or to wait for the vehicle to arrive) and the time to get from the vehicle to the destination (including the time to park the vehicle). High level of car service is considered to increase household car availability similar to owning a car. Where a high level of car service is available a household may use the car service rather than own a vehicle if the cost of using the car service is lower than the cost of owning a vehicle. Low level car service does not have competitive access time and is not considered as increasing household car availability or substituting for owning a vehicle.

## Model Parameter Estimation

This module has no model parameters.

## How the Module Works

The user specifies the proportion of activity (employment and households) served with a high level of car service by marea and area type. The module assigns high level car service to Bzones in each Marea and area type in the following steps:

1. The proportion of total activity in each of the Bzones is calculated

2. The Bzones are ordered in descending order of activity density assuming that higher density zones are more likely to have high service than lower density zones.

3. The cumulative sum of activity proportion is calculated in the order determined in #2.

4. The threshold where the cumulative sum is closest to the user defined proportion of activity served is identified.

5. The Bzones in the order up to the threshold are identified.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### marea_carsvc_availability.csv
|NAME                 |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                             |
|:--------------------|:------|:----------|:--------|:-----------|:--------|:---------------------------------------------------------------------------------------------------------------------------------------|
|Geo                  |       |           |         |Mareas      |         |Must contain a record for each Marea and model run year.                                                                                |
|Year                 |       |           |         |            |         |Must contain a record for each Marea and model run year.                                                                                |
|CenterPropHighCarSvc |double |proportion |< 0, > 1 |            |         |Proportion of activity in center area type that is served by high level car service (i.e. service competitive with household owned car) |
|InnerPropHighCarSvc  |double |proportion |< 0, > 1 |            |         |Proportion of activity in inner area type that is served by high level car service (i.e. service competitive with household owned car)  |
|OuterPropHighCarSvc  |double |proportion |< 0, > 1 |            |         |Proportion of activity in outer area type that is served by high level car service (i.e. service competitive with household owned car)  |
|FringePropHighCarSvc |double |proportion |< 0, > 1 |            |         |Proportion of activity in fringe area type that is served by high level car service (i.e. service competitive with household owned car) |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME                 |TABLE     |GROUP |TYPE       |UNITS      |PROHIBIT |ISELEMENTOF                  |
|:--------------------|:---------|:-----|:----------|:----------|:--------|:----------------------------|
|Marea                |Marea     |Year  |character  |ID         |         |                             |
|CenterPropHighCarSvc |Marea     |Year  |double     |proportion |< 0, > 1 |                             |
|InnerPropHighCarSvc  |Marea     |Year  |double     |proportion |< 0, > 1 |                             |
|OuterPropHighCarSvc  |Marea     |Year  |double     |proportion |< 0, > 1 |                             |
|FringePropHighCarSvc |Marea     |Year  |double     |proportion |< 0, > 1 |                             |
|Bzone                |Bzone     |Year  |character  |ID         |         |                             |
|Marea                |Bzone     |Year  |character  |ID         |         |                             |
|NumHh                |Bzone     |Year  |households |HH         |NA, < 0  |                             |
|TotEmp               |Bzone     |Year  |people     |PRSN       |NA, < 0  |                             |
|D1D                  |Bzone     |Year  |compound   |HHJOB/ACRE |NA, < 0  |                             |
|AreaType             |Bzone     |Year  |character  |category   |NA       |center, inner, outer, fringe |
|Bzone                |Household |Year  |character  |ID         |         |                             |

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

|NAME        |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                           |
|:-----------|:---------|:-----|:---------|:--------|:--------|:-----------|:---------------------------------------------------------------------------------------------------------------------|
|CarSvcLevel |Bzone     |Year  |character |category |         |Low, High   |Level of car service availability. High means access is competitive with household owned car. Low is not competitive. |
|CarSvcLevel |Household |Year  |character |category |         |Low, High   |Level of car service availability. High means access is competitive with household owned car. Low is not competitive. |
