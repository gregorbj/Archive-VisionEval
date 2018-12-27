# CreateHouseholds Module
### September 6, 2018

This module creates a *Household* table in the datastore and populates the table with datasets characterizing simulated households. Each entry represents a simulated household. Household datasets are created for the numbers of persons in each of 6 age categories (0-14, 15-19, 20-29, 30-54, 55-64, and 65+) and the total number of persons in the household. Two types of households are created: *regular* households (i.e. not persons in group quarters) and *group quarters* households (i.e. persons in group quarters such as college dormatories). Households are created from Azone level demographic forecasts of the number of persons in each of the 6 age groups for *regular* households and for the group quarters population. In addition, users may optionally specify an average household size and/or the proportion of households that are single person households. The module creates households that matches the age forecast and the optional household size and single person inputs (close but not exact). The module tabulates the number of households created in each Azone.

## Model Parameter Estimation

This model has just one parameter object, a matrix of the probability that a person in each age group is in one of several hundred *regular* household types. The matrix is created by selecting from the PUMS data the records for the most frequently observed household types. The default is to select the household types which account for 99% of all households. Each household type is denoted by the number of persons in each age group in the household. For example, a household that has 2 persons of age 0-14 and 2 persons of age 20-29 would be designated as type *2-0-2-0-0-0*. The numbers represent the number of persons in each of the age groups in the order listed above with the hyphens separating the age groups. These household types comprise the rows of the probability matrix. The columns of the matrix correspond to the 6 age groups. Each column of the matrix sums to 1.

This probability matrix is created from Census public use microsample (PUMS) data that is compiled into a R dataset (HhData_df) when the VESimHouseholds package is built. The data that is supplied with the VESimHouseholds package downloaded from the official VisionEval repository may be used, but it is preferrable to use data for the region being modeled. How this is done is explained in the documentation for the *CreateEstimationDatasets.R* script. The matrix is created by summing the number of persons each each age group and each of the household types using the household weights in the PUMS data. The probability that a person in each age group would be in each of the household type is the number of persons in the household type divided by the total number of persons in the age group.

No model parameters are used to create *group quarters* households because those households are just composed of single persons.

## How the Module Works

For *regular* households, the module uses the matrix of probabilities that a person in each age group is present in the most frequently observed household types along with a forecast of number of persons in each age group to synthesize a likely set of *regular* households. The module starts by assigning the forecast population by age group to household types using the probability matrix that has been estimated. It then carries out the following interative process to create a set of households that is internally consistent and that matches (approximately) the optional inputs for household size and proportion of single-person households:

1) For each household type, the number of households of the type is calculated from the number of persons of each age group assigned to the type. For example if 420 persons age 0-14 and 480 persons age 20-29 are assigned to household type *2-0-2-0-0-0*, that implies either 210 or 240 households of that type. Where the number of households of the type implied by the persons assigned is not consistent as in this example, the mean of the implied number of households is used. In the example, this would be 225 households. This is the *resolved* number of households. For all household types, the resolved number of households is compared to the maximum number of implied households (in this case 225 is compared to 240) if ratio of these values differs from 1 in absolute terms by less than 0.001 for all household types, the iterative process ends.

2) If a household size target has been specified, the average household size for the resolved households is computed. The ratio of the target household size and the average household size for the resolved households is computed. The number of resolved households in household types having sizes greater than the target household size is multiplied by this ratio. For example, if target household size is 2.5 and average household size for the resolved households is 3, th number of household for household types having more than 2.5 persons (i.e. 3 or more persons) would be multiplied by *2.5 / 3*.

3) If a target for the proportion of households that are 1-person households is set, the difference between the number of 1-person households that there should be and the number that have been assigned is calculated. That difference is added across all 1-person household types (e.g. if the difference is 100, since there are 5 1-person household types, 20 is added to each of those types). The difference is substracted across all other household types.

4) Using the resolved number of households of each type (as adjusted to match household size and 1-person household targets), the number of persons in each age group in each household type is computed. Continuing with the example, 225 households in household type *2-0-2-0-0-0* means that there must be 550 persons of age 0-14 and 550 persons of age 20-29 in that household type. This is called the *resolved* population. An updated probability matrix is computed using the resolved population by housing type.

5) The difference between the total number of persons by age group in the resolved population and the forecast number of persons by age group is calculated and that difference is allocated to household types using the updated probability matrix. Then calculation returns to the first iteration step.

After the iterations have been completed, the numbers of households by type are rounded to create whole number amounts. Then individual household records are created for each.

## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_hh_pop_by_age.csv
|NAME      |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                              |
|:---------|:------|:-----|:--------|:-----------|:--------|:------------------------------------------------------------------------|
|Geo       |       |      |         |Azones      |         |Must contain a record for each Azone and model run year.                 |
|Year      |       |      |         |            |         |Must contain a record for each Azone and model run year.                 |
|Age0to14  |people |PRSN  |NA, < 0  |            |         |Household (non-group quarters) population in 0 to 14 year old age group  |
|Age15to19 |people |PRSN  |NA, < 0  |            |         |Household (non-group quarters) population in 15 to 19 year old age group |
|Age20to29 |people |PRSN  |NA, < 0  |            |         |Household (non-group quarters) population in 20 to 29 year old age group |
|Age30to54 |people |PRSN  |NA, < 0  |            |         |Household (non-group quarters) population in 30 to 54 year old age group |
|Age55to64 |people |PRSN  |NA, < 0  |            |         |Household (non-group quarters) population in 55 to 64 year old age group |
|Age65Plus |people |PRSN  |NA, < 0  |            |         |Household (non-group quarters) population in 65 or older age group       |
### azone_hhsize_targets.csv
|   |NAME       |TYPE     |UNITS                    |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                          |
|:--|:----------|:--------|:------------------------|:--------|:-----------|:--------|:--------------------------------------------------------------------|
|1  |Geo        |         |                         |         |Azones      |         |Must contain a record for each Azone and model run year.             |
|11 |Year       |         |                         |         |            |         |Must contain a record for each Azone and model run year.             |
|7  |AveHhSize  |compound |PRSN/HH                  |< 0      |            |         |Average household size of households (non-group quarters)            |
|8  |Prop1PerHh |double   |proportion of households |< 0      |            |         |Proportion of households (non-group quarters) having only one person |
### azone_gq_pop_by_age.csv
|   |NAME         |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                              |
|:--|:------------|:------|:-----|:--------|:-----------|:--------|:--------------------------------------------------------|
|1  |Geo          |       |      |         |Azones      |         |Must contain a record for each Azone and model run year. |
|15 |Year         |       |      |         |            |         |Must contain a record for each Azone and model run year. |
|9  |GrpAge0to14  |people |PRSN  |NA, < 0  |            |         |Group quarters population in 0 to 14 year old age group  |
|10 |GrpAge15to19 |people |PRSN  |NA, < 0  |            |         |Group quarters population in 15 to 19 year old age group |
|11 |GrpAge20to29 |people |PRSN  |NA, < 0  |            |         |Group quarters population in 20 to 29 year old age group |
|12 |GrpAge30to54 |people |PRSN  |NA, < 0  |            |         |Group quarters population in 30 to 54 year old age group |
|13 |GrpAge55to64 |people |PRSN  |NA, < 0  |            |         |Group quarters population in 55 to 64 year old age group |
|14 |GrpAge65Plus |people |PRSN  |NA, < 0  |            |         |Group quarters population in 65 or older age group       |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME         |TABLE |GROUP |TYPE      |UNITS                    |PROHIBIT |ISELEMENTOF |
|:------------|:-----|:-----|:---------|:------------------------|:--------|:-----------|
|Azone        |Azone |Year  |character |ID                       |         |            |
|Marea        |Azone |Year  |character |ID                       |         |            |
|Age0to14     |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|Age15to19    |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|Age20to29    |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|Age30to54    |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|Age55to64    |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|Age65Plus    |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|AveHhSize    |Azone |Year  |compound  |PRSN/HH                  |< 0      |            |
|Prop1PerHh   |Azone |Year  |double    |proportion of households |NA, < 0  |            |
|GrpAge0to14  |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|GrpAge15to19 |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|GrpAge20to29 |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|GrpAge30to54 |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|GrpAge55to64 |Azone |Year  |people    |PRSN                     |NA, < 0  |            |
|GrpAge65Plus |Azone |Year  |people    |PRSN                     |NA, < 0  |            |

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

|NAME      |TABLE     |GROUP |TYPE       |UNITS    |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                  |
|:---------|:---------|:-----|:----------|:--------|:--------|:-----------|:----------------------------------------------------------------------------|
|NumHh     |Azone     |Year  |households |HH       |NA, < 0  |            |Number of households (non-group quarters)                                    |
|NumGq     |Azone     |Year  |people     |PRSN     |NA, < 0  |            |Number of people in non-institutional group quarters                         |
|HhId      |Household |Year  |character  |ID       |         |            |Unique household ID                                                          |
|Azone     |Household |Year  |character  |ID       |         |            |Azone ID                                                                     |
|Marea     |Household |Year  |character  |ID       |         |            |Marea ID                                                                     |
|HhSize    |Household |Year  |people     |PRSN     |NA, <= 0 |            |Number of persons                                                            |
|Age0to14  |Household |Year  |people     |PRSN     |NA, < 0  |            |Persons in 0 to 14 year old age group                                        |
|Age15to19 |Household |Year  |people     |PRSN     |NA, < 0  |            |Persons in 15 to 19 year old age group                                       |
|Age20to29 |Household |Year  |people     |PRSN     |NA, < 0  |            |Persons in 20 to 29 year old age group                                       |
|Age30to54 |Household |Year  |people     |PRSN     |NA, < 0  |            |Persons in 30 to 54 year old age group                                       |
|Age55to64 |Household |Year  |people     |PRSN     |NA, < 0  |            |Persons in 55 to 64 year old age group                                       |
|Age65Plus |Household |Year  |people     |PRSN     |NA, < 0  |            |Persons in 65 or older age group                                             |
|HhType    |Household |Year  |character  |category |         |            |Coded household age composition (e.g. 2-1-0-2-0-0) or Grp for group quarters |
