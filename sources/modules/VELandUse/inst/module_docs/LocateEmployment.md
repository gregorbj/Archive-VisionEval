
# LocateEmployment Module
### November 6, 2018

This module places employment in Bzones based on input assumptions of employment by type and Bzone. The model adjusts the employment numbers to balance with the number of workers in the region. The module creates a worker table and assigns workers to Bzone employment locations as a function of the number of jobs in each Bzone and the inverse of distance between residence and employment Bzones.

## Model Parameter Estimation

This module has no parameters. Regional employment is allocated to Bzones based on user inputs and is scaled to match the number of workers in the region. Workers are assigned a Bzone work location as a function of the number of jobs in each Bzone and the inverse of distance between residence and employment Bzones.

## How the Module Works

The module creates a worker table in the datastore where each entry is a worker identified by a worker ID, the ID of the household it belongs to, and the Bzone where the worker's job is located, along with a few other attributes identified below. The following computations are carried out in order to identify the Bzone identified as the worker's job site:

1) The number of workers by residence Bzone is tabulated.

2) The number of jobs by Bzone and category (retail, service, total) is a user input. Those input values are scaled if necessary so that the total number of jobs equals the total number of workers.

3) A matrix of distances between Bzones are calculated from the latitude and longitude positions of the Bzone centroids that are input by the user.

4) An iterative proportional fitting (IPF) process is used to create a balanced matrix of the number of workers in each residence zone and employment zone pair. The IPF margins are the tabulations of workers by Bzone (step #1) and jobs by Bzone (step #2). The IPF seed matrix is the inverse of the values of the distance matrix (step #3).

5) Create a dataset of workers identifying their residence locations and assign them a work location by randomly assigning them to Bzones as constrained by the allocation of workers to jobs (step #4).

6) Identify the Azone and Marea of the worker job location and the distance from home to work.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_employment.csv
|NAME   |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                              |
|:------|:------|:-----|:--------|:-----------|:--------|:--------------------------------------------------------|
|Geo    |       |      |         |Bzones      |         |Must contain a record for each Bzone and model run year. |
|Year   |       |      |         |            |         |Must contain a record for each Bzone and model run year. |
|TotEmp |people |PRSN  |NA, < 0  |            |         |Total number of jobs in zone                             |
|RetEmp |people |PRSN  |NA, < 0  |            |         |Number of jobs in retail sector in zone                  |
|SvcEmp |people |PRSN  |NA, < 0  |            |         |Number of jobs in service sector in zone                 |
### bzone_lat_lon.csv
|   |NAME      |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                              |
|:--|:---------|:------|:-----|:--------|:-----------|:--------|:--------------------------------------------------------|
|1  |Geo       |       |      |         |Bzones      |         |Must contain a record for each Bzone and model run year. |
|11 |Year      |       |      |         |            |         |Must contain a record for each Bzone and model run year. |
|4  |Latitude  |double |NA    |NA       |            |         |Latitude in decimal degrees of the centroid of the zone  |
|5  |Longitude |double |NA    |NA       |            |         |Longitude in decimal degrees of the centroid of the zone |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME      |TABLE     |GROUP |TYPE      |UNITS |PROHIBIT |ISELEMENTOF |
|:---------|:---------|:-----|:---------|:-----|:--------|:-----------|
|Bzone     |Bzone     |Year  |character |ID    |         |            |
|Azone     |Bzone     |Year  |character |ID    |         |            |
|Marea     |Bzone     |Year  |character |ID    |         |            |
|TotEmp    |Bzone     |Year  |people    |PRSN  |NA, < 0  |            |
|RetEmp    |Bzone     |Year  |people    |PRSN  |NA, < 0  |            |
|SvcEmp    |Bzone     |Year  |people    |PRSN  |NA, < 0  |            |
|NumWkr    |Azone     |Year  |people    |PRSN  |NA, < 0  |            |
|Workers   |Household |Year  |people    |PRSN  |NA, < 0  |            |
|HhId      |Household |Year  |character |ID    |         |            |
|Bzone     |Household |Year  |character |ID    |         |            |
|Latitude  |Bzone     |Year  |double    |NA    |NA       |            |
|Longitude |Bzone     |Year  |double    |NA    |NA       |            |

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

|NAME           |TABLE  |GROUP |TYPE      |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                             |
|:--------------|:------|:-----|:---------|:-----|:--------|:-----------|:---------------------------------------------------------------------------------------|
|TotEmp         |Bzone  |Year  |people    |PRSN  |NA, < 0  |            |Total number of jobs in zone                                                            |
|RetEmp         |Bzone  |Year  |people    |PRSN  |NA, < 0  |            |Number of jobs in retail sector in zone                                                 |
|SvcEmp         |Bzone  |Year  |people    |PRSN  |NA, < 0  |            |Number of jobs in service sector in zone                                                |
|HhId           |Worker |Year  |character |ID    |NA       |            |Unique household ID                                                                     |
|WkrId          |Worker |Year  |character |ID    |NA       |            |Unique worker ID                                                                        |
|Bzone          |Worker |Year  |character |ID    |         |            |Bzone ID of worker job location                                                         |
|Azone          |Worker |Year  |character |ID    |         |            |Azone ID of worker job location                                                         |
|Marea          |Worker |Year  |character |ID    |         |            |Marea ID of worker job location                                                         |
|DistanceToWork |Worker |Year  |distance  |MI    |NA, <= 0 |            |Distance from home to work assuming location at Bzone centroid and 'Manhattan' distance |
