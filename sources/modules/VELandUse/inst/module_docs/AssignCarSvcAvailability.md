
# AssignCarSvcAvailability Module
### November 6, 2018

This module reads in and assigns car service availability in Bzones. Car services include taxis, car sharing services (e.g. Car-To-Go, Zipcar), and future automated taxi services. A user input file identifies which Bzones have high or low levels of service. A high car service level is one that has access times that are competitive with private car use. This means that the time it takes for a taxi service to pick up a passenger or that time it takes to get to a car share car is not much longer than the time to get to and from a vehicle owned by a household, especially when considering that a car service may be able to drop off the passengers at the destination, or may have preferential parking, thus avoiding time to park a private vehicle and walk to the destination. High level of car service is considered to increase household car availability similar to owning a car. Low level car service does not have competitive access time and is not considered as increasing household car availability.

## Model Parameter Estimation

This module has no model parameters.

## How the Module Works

The user specifies the level of car service availability (Low or High) by Bzone. The module assigns that level to each household based on the Bzone the household resides in.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_carsvc_availability.csv
|NAME        |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                           |
|:-----------|:---------|:--------|:--------|:-----------|:--------|:---------------------------------------------------------------------------------------------------------------------|
|Geo         |          |         |         |Bzones      |         |Must contain a record for each Bzone and model run year.                                                              |
|Year        |          |         |         |            |         |Must contain a record for each Bzone and model run year.                                                              |
|CarSvcLevel |character |category |         |Low, High   |         |Level of car service availability. High means access is competitive with household owned car. Low is not competitive. |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME        |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |
|:-----------|:---------|:-----|:---------|:--------|:--------|:-----------|
|CarSvcLevel |Bzone     |Year  |character |category |         |Low, High   |
|Bzone       |Bzone     |Year  |character |ID       |         |            |
|Bzone       |Household |Year  |character |ID       |         |            |

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
|CarSvcLevel |Household |Year  |character |category |         |Low, High   |Level of car service availability. High means access is competitive with household owned car. Low is not competitive. |
