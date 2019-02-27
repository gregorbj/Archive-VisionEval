
# CreateVehicleTable Module
### September 10, 2018

This module creates a vehicle table and populates it with household ID and geography fields.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

This module initializes the 'Vehicle' table and populates it with the household ID (HhId), vehicle ID (VehID), Azone ID (Azone), Marea ID (Marea), and vehicle access type (VehicleAccess) datasets. The Vehicle table has a record for every vehicle owned by the household. If there are more driving age persons than vehicles in the household, there is also a record for each driving age person for which there is no vehicle. The VehicleAccess designation is Own for each vehicle owned by a household. The designation is either LowCarSvc or HighCarSvc for each record corresponding to difference between driving age persons and owned vehicles. It is LowCarSvc if the household is in a Bzone having a low level of car service and HighCarSvc if the Bzone car service level is high.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_carsvc_characteristics.csv
|NAME                |TYPE     |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                                                                        |
|:-------------------|:--------|:----------|:------------|:-----------|:--------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Geo                 |         |           |             |Azones      |         |Must contain a record for each Azone and model run year.                                                                                                                                           |
|Year                |         |           |             |            |         |Must contain a record for each Azone and model run year.                                                                                                                                           |
|HighCarSvcCost      |currency |USD        |NA, < 0      |            |         |Average cost in dollars per mile for travel by high service level car service exclusive of the cost of fuel, road use taxes, and carbon taxes (and any other social costs charged to vehicle use). |
|LowCarSvcCost       |currency |USD        |NA, < 0      |            |         |Average cost in dollars per mile for travel by low service level car service exclusive of the cost of fuel, road use taxes, and carbon taxes (and any other social costs charged to vehicle use).  |
|AveCarSvcVehicleAge |time     |YR         |NA, < 0      |            |         |Average age of car service vehicles in years                                                                                                                                                       |
|LtTrkCarSvcSubProp  |double   |proportion |NA, < 0, > 1 |            |         |The proportion of light-truck owners who would substitute a less-costly car service option for owning their light truck                                                                            |
|AutoCarSvcSubProp   |double   |proportion |NA, < 0, > 1 |            |         |Th proportion of automobile owners who would substitute a less-costly car service option for owning their automobile                                                                               |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME          |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |
|:-------------|:---------|:-----|:---------|:--------|:--------|:-----------|
|HhId          |Household |Year  |character |ID       |         |            |
|Azone         |Household |Year  |character |ID       |         |            |
|Marea         |Household |Year  |character |ID       |         |            |
|NumLtTrk      |Household |Year  |vehicles  |VEH      |NA, < 0  |            |
|NumAuto       |Household |Year  |vehicles  |VEH      |NA, < 0  |            |
|Vehicles      |Household |Year  |vehicles  |VEH      |NA, < 0  |            |
|DrvAgePersons |Household |Year  |people    |PRSN     |NA, < 0  |            |
|CarSvcLevel   |Household |Year  |character |category |         |Low, High   |

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

|NAME          |TABLE   |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF                |DESCRIPTION                                                                                                                                                   |
|:-------------|:-------|:-----|:---------|:--------|:--------|:--------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|
|HhId          |Vehicle |Year  |character |ID       |         |                           |Unique household ID                                                                                                                                           |
|VehId         |Vehicle |Year  |character |ID       |         |                           |Unique vehicle ID                                                                                                                                             |
|Azone         |Vehicle |Year  |character |ID       |         |                           |Azone ID                                                                                                                                                      |
|Marea         |Vehicle |Year  |character |ID       |         |                           |Marea ID                                                                                                                                                      |
|VehicleAccess |Vehicle |Year  |character |category |         |Own, LowCarSvc, HighCarSvc |Identifier whether vehicle is owned by household (Own), if vehicle is low level car service (LowCarSvc), or if vehicle is high level car service (HighCarSvc) |
|Type          |Vehicle |Year  |character |category |NA       |Auto, LtTrk                |Vehicle body type: Auto = automobile, LtTrk = light trucks (i.e. pickup, SUV, Van)                                                                            |
