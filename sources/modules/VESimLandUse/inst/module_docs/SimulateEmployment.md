
# SimulateEmployment Module
### February 5, 2019

This module assign workers SimBzone work locations. A worker table is created which identifies a unique worker ID, the household ID the worker is a part of, and the SimBzone, Azone, and Marea of the worker job location.

## Model Parameter Estimation

This module has no parameters. Workers are assigned to Bzone job locations using simple rules as described in the following section.

## How the Module Works

The module operates at the Marea level. The process for allocating workers to jobsites follows the logic of the process used by the 'CreateSimBzones' to calculate jobs and allocating them SimBzones. Since 'CreatesSimBzones' module creates jobs in the Azones of of each Marea based on the number of workers, jobs and workers are balanced. Following the same procedure for allocating workers to jobsites assures that the balance is maintained. Following are the steps in the process carried out for each Marea:

1) For each Azone, workers residing in the Azone are assigned to Rural, Town, or Urban job locations. The numbers assigned to Rural and Town locations are equal to the numbers of Rural and Town jobs in the Azone respectively. The remaining workers are assigned to Urban jobs. The assignment to job location type is made randomly. In other words, the characteristics of the household the worker is a part of and the characteristics of the SimBzone they reside in do not affect the their job location type.

2) For each Azone, workers identified as having Rural and Town job locations are assigned to Rural and Town SimBzone job locations in the Azone. The assignment is random but consistent with the numbers of jobs allocated to each SimBzone.

3) For the whole Marea, workers identified as having Urban job locations are assigned to Urban SimBzone job locations in any of the Urban SimBzones in the Marea. The assignment is random but consistent with the numbers of jobs allocated to each SimBzone.


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

|NAME    |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF        |
|:-------|:---------|:-----|:---------|:--------|:--------|:------------------|
|Azone   |Azone     |Year  |character |ID       |         |                   |
|Marea   |Azone     |Year  |character |ID       |         |                   |
|Bzone   |Bzone     |Year  |character |ID       |         |                   |
|Azone   |Bzone     |Year  |character |ID       |         |                   |
|Marea   |Bzone     |Year  |character |ID       |         |                   |
|TotEmp  |Bzone     |Year  |people    |PRSN     |NA, < 0  |                   |
|LocType |Bzone     |Year  |character |category |NA       |Urban, Town, Rural |
|Workers |Household |Year  |people    |PRSN     |NA, < 0  |                   |
|HhId    |Household |Year  |character |ID       |         |                   |
|Bzone   |Household |Year  |character |ID       |         |                   |
|Azone   |Household |Year  |character |ID       |         |                   |

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

|NAME  |TABLE  |GROUP |TYPE      |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                     |
|:-----|:------|:-----|:---------|:-----|:--------|:-----------|:-------------------------------|
|HhId  |Worker |Year  |character |ID    |NA       |            |Unique household ID             |
|WkrId |Worker |Year  |character |ID    |NA       |            |Unique worker ID                |
|Bzone |Worker |Year  |character |ID    |         |            |Bzone ID of worker job location |
|Azone |Worker |Year  |character |ID    |         |            |Azone ID of worker job location |
|Marea |Worker |Year  |character |ID    |         |            |Marea ID of worker job location |
