# AssignLifeCycle Module
### September 6, 2018

This module assigns a life cycle category to each household. The life cycle categories are similar, but not the same as, those established for the NHTS. The age categories used in VisionEval models are broader than those used by the NHTS to identify children of different ages. As a result it is not possible for the life cycle designations to reflect child ages as they do in the NHTS. Also, adulthood is determined differently in this module. The NHTS uses age 21 as the threshold age for adulthood. This module uses use 20 as nominal age break for adulthood (the 20-29 age group). Moreover, the module identifies some younger persons to be adults in situations where they are likely to be be living independently as adults or emancipated minors. Persons in the 15 to 19 age group are considered adults when there are no older adults (ages 30+) in the household.

## Model Parameter Estimation

This module has no parameters. A set of rules assigns age group categories based on the age of persons and workers in the household.

## How the Module Works

The module uses datasets on the numbers of persons in each household by age category and the numbers of workers by age category. The age categories are 0-14 years, 15-19 years, 20-29 years, 30-54 years, 55-64 years, and 65+ years. However no workers are in the 0-14 year age category. The household life cycle is determined by the number of children in combination with the number of adults and whether the adults are retired. The categories are as follows:
01: one adult, no children
02: 2+ adults, no children
03: one adult, children (corresponds to NHTS 03, 05, and 07)
04: 2+ adults, children (corresponds to NHTS 04, 06, and 08)
09: one adult, retired, no children
10: 2+ adults, retired, no children

Because the 15-19 age category can be ambiguous with regard to adult or child status, the status of persons in that age category in the household is determined based on the presence of older adults in the household. If there are no older persons or only persons aged 20-29 in the household, the age 15-19 persons are considered to be adults. Otherwise they are considered to be children.

The retirement status of adults is determined based on age and worker status. Households are considered to be populated with retired persons if all the adults are in the 65+ age category and there are no workers. If children are present in the household with retired persons, then the life cycle category is 03 or 04 rather than 09 or 10.

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

|NAME      |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |
|:---------|:---------|:-----|:---------|:--------|:--------|:-----------|
|Age0to14  |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age15to19 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age20to29 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age30to54 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age55to64 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age65Plus |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr15to19 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr20to29 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr30to54 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr55to64 |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Wkr65Plus |Household |Year  |people    |PRSN     |NA, < 0  |            |
|HhType    |Household |Year  |character |category |         |            |

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

|NAME      |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF            |DESCRIPTION                                                   |
|:---------|:---------|:-----|:---------|:--------|:--------|:----------------------|:-------------------------------------------------------------|
|LifeCycle |Household |Year  |character |category |         |01, 02, 03, 04, 09, 10 |Household life cycle as defined by 2009 NHTS LIF_CYC variable |
