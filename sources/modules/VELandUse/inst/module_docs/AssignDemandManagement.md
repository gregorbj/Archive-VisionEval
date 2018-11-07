
# AssignDemandManagement Module
### November 6, 2018

This module assigns demand management program participation to households and to workers. Households are assigned to individualized marketing program participation. Workers are assigned to employee commute options participation. The module computes the net proportional reduction in household DVMT based on the participation in travel demand management programs.

## Model Parameter Estimation

This module has parameters for the proportional reduction in household vehicle miles traveled (VMT) for worker participation in employee commute options (ECO) program and for household participation in an individualized marketing program (IMP). The default VMT reduction values are contained in the *tdm_parameters.csv* file in the *inst/extdata* directory of this package: 9% for IMP, and 5.4% for ECO. Documentation for those values is in the accompanying *tdm_parameters.txt* file.

A model is also estimated to predicts the proportion of household VMT in work tours. The percentage reduction on household VMT as a function of employee commute options programs depends on the number of household workers participating and the proportion of household travel in work tours. A relationship between household size, the number of household workers, and the proportion of household DVMT in work tours is calculated using the *HhTours_df* dataset from the VE2001NHTS package. The following table show the tabulations of total miles, work tour miles, and work tour miles per worker by household size. The proportion of household miles in work tours per household workers is computed from these data.


|Household_Size | Total_Miles| Work_Tour_Miles| Work_Miles_Per_Worker| Prop._Per_Worker|     N|
|:--------------|-----------:|---------------:|---------------------:|----------------:|-----:|
|1              |      339180|          114973|                114973|            0.339| 10762|
|2              |     1136703|          422083|                211041|            0.186| 20360|
|3              |      633049|          268833|                 89611|            0.142|  8407|
|4              |      655437|          256457|                 64114|            0.098|  7596|
|5              |      291590|           99794|                 19959|            0.068|  3045|
|6              |       94630|           30584|                  5097|            0.054|   897|
|7              |       25835|            7939|                  1134|            0.044|   229|
|8              |       15087|            5637|                   642|            0.043|   142|

## How the Module Works
Users provide inputs on the proportion of households residing in each Bzone who participate in individualized marketing programs (IMP) and the proportion of workers working in each Bzone who participate in employee commute options (ECO) programs. These proportions are used in random draws to determine whether a household is an IMP program participant and whether a worker is an ECO program participant. The number of workers is participating is summed for each household.

The proportional reduction in the DVMT of each household is calculated for IMP program participation and ECO program participation and the maximum of those is used. The maximum value is used rather than combining the values of the two programs because it is likely that there is a substantial amount of overlap in what these programs accomplish. The proportional reduction in VMT due to IMP participation is simply the value specified in the *tdm_parameters.csv* file. The proportional reduction in VMT due to ECO participation is product of the proportional reduction in VMT specified in the *tdm_parameters.csv*, the modeled proportion of household VMT in work travel per worker for the household size, and the number of workers who participate.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_travel_demand_mgt.csv
|NAME    |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                           |
|:-------|:------|:----------|:------------|:-----------|:--------|:-----------------------------------------------------------------------------------------------------|
|Geo     |       |           |             |Bzones      |         |Must contain a record for each Bzone and model run year.                                              |
|Year    |       |           |             |            |         |Must contain a record for each Bzone and model run year.                                              |
|EcoProp |double |proportion |NA, < 0, > 1 |            |         |Proportion of workers working in Bzone who participate in strong employee commute options program     |
|ImpProp |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in Bzone who participate in strong individualized marketing program |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME    |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT     |ISELEMENTOF |
|:-------|:---------|:-----|:---------|:----------|:------------|:-----------|
|Bzone   |Bzone     |Year  |character |ID         |             |            |
|EcoProp |Bzone     |Year  |double    |proportion |NA, < 0, > 1 |            |
|ImpProp |Bzone     |Year  |double    |proportion |NA, < 0, > 1 |            |
|Bzone   |Household |Year  |character |ID         |             |            |
|HhId    |Household |Year  |character |ID         |             |            |
|HhSize  |Household |Year  |people    |PRSN       |NA, < 0      |            |
|Workers |Household |Year  |people    |PRSN       |NA, < 0      |            |
|HhId    |Worker    |Year  |character |ID         |             |            |
|Bzone   |Worker    |Year  |character |ID         |             |            |

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

|NAME                 |TABLE     |GROUP |TYPE    |UNITS      |PROHIBIT     |ISELEMENTOF |DESCRIPTION                                                                                                                     |
|:--------------------|:---------|:-----|:-------|:----------|:------------|:-----------|:-------------------------------------------------------------------------------------------------------------------------------|
|IsIMP                |Household |Year  |integer |binary     |             |0, 1        |Identifies whether household is participant in travel demand management individualized marketing program (IMP): 1 = yes, 0 = no |
|PropTdmDvmtReduction |Household |Year  |double  |proportion |NA, < 0, > 1 |            |Proportional reduction in household DVMT due to participation in travel demand management programs                              |
|IsECO                |Worker    |Year  |integer |binary     |             |0, 1        |Identifies whether worker is a participant in travel demand management employee commute options program: 1 = yes, 0 = no        |
