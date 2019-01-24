# PredictWorkers Module
### September 6, 2018

This module assigns workers by age to households and to noninstitutional group quarters population. It is a simple model which predicts workers as a function of the age composition of household members. There is no responsiveness to jobs or how changes in the job market and demographics might change the worker age composition, but the user may use optional inputs to exogenously adjust relative employment rates by age group, Azone, and year. These optional input values specify by age group, Azone, and year the proportions of persons in the age group and Azone who are workers relative to the proportions in the model estimation year.

## Model Parameter Estimation
This model has just one parameter object, a matrix of the probability that a person in each age group in a specified household type is a worker. The defined household types are the same as the types defined for the CreateHouseholds module.

This probability matrix is created from Census public use microsample (PUMS) data that is compiled by the CreateEstimationDatasets.R script into a R dataset (HhData_df) when the VESimHouseholds package is built. The data that is supplied with the VESimHouseholds package downloaded from the official VisionEval repository may be used, but it is preferrable to use data for the region being modeled. How this is done is explained in the documentation for the *CreateEstimationDatasets.R* script.

To calculate this probability matrix, the numbers of workers by age group and household type and the numbers of persons by age group and household type are tabulated (weighted by the household weights in the PUMS data). The probability that a person is a worker is calculated by dividing the worker tabulation by the population tabulation.

## How the Module Works
The number of workers in each age group of each household is determined through random sampling using the probability for the age group and household type. For example, if a household is of the type *2-0-2-0-0-0*, and the probability that a person of age 20-29 in this household type is a worker is 0.7, then two random samples are taken for this household with a probability of success of 0.7 to determine the number of workers in this age group in the household.

If the user has supplied optional inputs for the ratio of employment for the age group in the forecast year relative to the year of the model estimation dataset, that input is multiplied by the estimated worker probability to determine the sampling probability. For example, if the year of the model estimation data is 2000 and the forecast year is 2010, and if the user specifies that the employment rate of 20-29 year olds in 2010 was 95% of the employment rate of that age group in 2000, then the worker probability in the example above (0.7) is multiplied by 0.95 to calculate the sampling probability.

## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_relative_employment.csv
This input file is OPTIONAL.

|NAME         |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                           |
|:------------|:------|:----------|:--------|:-----------|:--------|:-------------------------------------------------------------------------------------|
|Geo          |       |           |         |Azones      |         |Must contain a record for each Azone and model run year.                              |
|Year         |       |           |         |            |         |Must contain a record for each Azone and model run year.                              |
|RelEmp15to19 |double |proportion |< 0      |            |         |Ratio of workers to persons age 15 to 19 in model year vs. in estimation data year    |
|RelEmp20to29 |double |proportion |< 0      |            |         |Ratio of workers to persons age 20 to 29 in model year vs. in estimation data year    |
|RelEmp30to54 |double |proportion |< 0      |            |         |Ratio of workers to persons age 30 to 54 in model year vs. in estimation data year    |
|RelEmp55to64 |double |proportion |< 0      |            |         |Ratio of workers to persons age 55 to 64 in model year vs. in estimation data year    |
|RelEmp65Plus |double |proportion |< 0      |            |         |Ratio of workers to persons age 65 or older in model year vs. in estimation data year |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME         |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT |ISELEMENTOF |
|:------------|:---------|:-----|:---------|:----------|:--------|:-----------|
|Age0to14     |Household |Year  |people    |PRSN       |NA, < 0  |            |
|Age15to19    |Household |Year  |people    |PRSN       |NA, < 0  |            |
|Age20to29    |Household |Year  |people    |PRSN       |NA, < 0  |            |
|Age30to54    |Household |Year  |people    |PRSN       |NA, < 0  |            |
|Age55to64    |Household |Year  |people    |PRSN       |NA, < 0  |            |
|Age65Plus    |Household |Year  |people    |PRSN       |NA, < 0  |            |
|RelEmp15to19 |Azone     |Year  |double    |proportion |< 0      |            |
|RelEmp20to29 |Azone     |Year  |double    |proportion |< 0      |            |
|RelEmp30to54 |Azone     |Year  |double    |proportion |< 0      |            |
|RelEmp55to64 |Azone     |Year  |double    |proportion |< 0      |            |
|RelEmp65Plus |Azone     |Year  |double    |proportion |< 0      |            |
|HhType       |Household |Year  |character |category   |         |            |
|Azone        |Household |Year  |character |ID         |         |            |
|Azone        |Azone     |Year  |character |ID         |         |            |

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

|NAME      |TABLE     |GROUP |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                            |
|:---------|:---------|:-----|:------|:-----|:--------|:-----------|:--------------------------------------|
|Wkr15to19 |Household |Year  |people |PRSN  |NA, < 0  |            |Workers in 15 to 19 year old age group |
|Wkr20to29 |Household |Year  |people |PRSN  |NA, < 0  |            |Workers in 20 to 29 year old age group |
|Wkr30to54 |Household |Year  |people |PRSN  |NA, < 0  |            |Workers in 30 to 54 year old age group |
|Wkr55to64 |Household |Year  |people |PRSN  |NA, < 0  |            |Workers in 55 to 64 year old age group |
|Wkr65Plus |Household |Year  |people |PRSN  |NA, < 0  |            |Workers in 65 or older age group       |
|Workers   |Household |Year  |people |PRSN  |NA, < 0  |            |Total workers                          |
|NumWkr    |Azone     |Year  |people |PRSN  |NA, < 0  |            |Number of workers residing in the zone |
