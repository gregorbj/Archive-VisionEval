
# Simulates4DMeasures Module
### February 6, 2019

This module calculates several *4D* measures by SimBzone including density, diversity (i.e. mixing of land uses), and pedestrian-orientedn transportation network design. These measures are the same as or are similar to measures included in the Environmental Protection Agency's (EPA) [Smart Location Database](https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide).

## Model Parameter Estimation

This module has no parameters. 4D measures are calculated based on Bzone attributes as described in the next section.

## How the Module Works

This module calculates 2 development density measures that are named using the names used in the Smart Location Database (SLD): population density (D1B), employment density (D1C). Another density measure, activity density (D1D), is calculated during the process of SimBzone creation by the CreateSimBzones module. These density measures are calculated at the Bzone level. The population, employment, and activity (employment + households) values to calculate these measures come from the products of other modules. The area data comes from user inputs of the unprotected area (measured in acres) in urban (i.e. urbanized) and rural (i.e. not urbanized) portions of each Bzone.

The module calculates 3 development diversity measures which measure the relative heterogeity of land uses in each Bzone. These too are named according to how the SLD names them. D2A_JPHH is the ratio of jobs to households in each Bzone. D2A_WRKEMP is the ratio of workers living in the zone to jobs located in the zone. D2A_EPHHM is an entropy measure calculated from the amount of activity in 4 categories, 3 employment categories (retail, service, other) measured by the number of jobs in the Bzone, and a household category. Entropy is measured on a scale 0 to 1 with 0 corresponding to the situation where only one activity category (or no activity) is present in the Bzone, and 1 corresponding to the situation where there are equal amounts of all activities in the Bzone. Where 2 or more activity categories are present in the Bzone, the entropy of the Bzone is calculated as follows:

  `-sum(R * LogR) / log(NAct)`

where:

- `R` is a vector of the ratio of activity in each activity category divided by the total of all activity

- `LogR` is the natural log of `R` or 0 for activity categories having no activity

- `NAct` is the number of activity categories (i.e. 4)

One pedestrian-oriented transportation network design measure is produced by the module. D3bpo4 is intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile. This is one of the network design measured in the Smart Location database. This measure is D3bpo4 is simulated as a function of the place type of the SimBzone (LocType, AreaType, DevType) and the average D3bpo4 value for the urbanized area (or town or rural area) where the SimBzone is located. A base average value by urbanized area and towns as a whole and rural areas as a whole in the CreateSimBzoneModels module. User inputs adjust the values (e.g. increase average by 50%). The D3bpo4 model estimated by the CreateSimBzoneModels module is used to calculate the SimBzone value.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### marea_d3bpo4_adj.csv
|NAME           |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                         |
|:--------------|:------|:----------|:--------|:-----------|:--------|:-----------------------------------------------------------------------------------------------------------------------------------|
|Geo            |       |           |         |Mareas      |         |Must contain a record for each Marea and model run year.                                                                            |
|Year           |       |           |         |            |         |Must contain a record for each Marea and model run year.                                                                            |
|UrbanD3bpo4Adj |double |proportion |NA, < 0  |            |         |Proportion of base urban D3bpo4 value as tabulated from the EPA 2010 Smart Location Database for the urbanized portion of the marea |
|TownD3bpo4Adj  |double |proportion |NA, < 0  |            |         |Proportion of base town D3bpo4 value as tabulated from the EPA 2010 Smart Location Database for towns                               |
|RuralD3bpo4Adj |double |proportion |NA, < 0  |            |         |Proportion of base town D3bpo4 value as tabulated from the EPA 2010 Smart Location Database for rural areas                         |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME           |TABLE |GROUP  |TYPE       |UNITS      |PROHIBIT |ISELEMENTOF                  |
|:--------------|:-----|:------|:----------|:----------|:--------|:----------------------------|
|Marea          |Marea |Global |character  |ID         |         |                             |
|UzaProfileName |Marea |Global |character  |ID         |         |                             |
|Marea          |Marea |Year   |character  |ID         |         |                             |
|UrbanD3bpo4Adj |Marea |Year   |double     |proportion |NA, < 0  |                             |
|TownD3bpo4Adj  |Marea |Year   |double     |proportion |NA, < 0  |                             |
|RuralD3bpo4Adj |Marea |Year   |double     |proportion |NA, < 0  |                             |
|Bzone          |Bzone |Year   |character  |ID         |         |                             |
|Marea          |Bzone |Year   |character  |ID         |         |                             |
|TotEmp         |Bzone |Year   |people     |PRSN       |NA, < 0  |                             |
|RetEmp         |Bzone |Year   |people     |PRSN       |NA, < 0  |                             |
|SvcEmp         |Bzone |Year   |people     |PRSN       |NA, < 0  |                             |
|Pop            |Bzone |Year   |people     |PRSN       |NA, <= 0 |                             |
|NumHh          |Bzone |Year   |households |HH         |NA, < 0  |                             |
|NumWkr         |Bzone |Year   |people     |PRSN       |NA, < 0  |                             |
|UrbanArea      |Bzone |Year   |area       |ACRE       |NA, < 0  |                             |
|TownArea       |Bzone |Year   |area       |ACRE       |NA, < 0  |                             |
|RuralArea      |Bzone |Year   |area       |ACRE       |NA, < 0  |                             |
|AreaType       |Bzone |Year   |character  |category   |NA       |center, inner, outer, fringe |
|DevType        |Bzone |Year   |character  |category   |NA       |emp, mix, res                |
|LocType        |Bzone |Year   |character  |category   |NA       |Urban, Town, Rural           |

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

|NAME       |TABLE |GROUP |TYPE     |UNITS                                             |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                                                            |
|:----------|:-----|:-----|:--------|:-------------------------------------------------|:--------|:-----------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|D1B        |Bzone |Year  |compound |PRSN/ACRE                                         |NA, < 0  |            |Gross population density (people/acre) on unprotected (i.e. developable) land in zone (Ref: EPA 2010 Smart Location Database)                                          |
|D1C        |Bzone |Year  |compound |JOB/ACRE                                          |NA, < 0  |            |Gross employment density (jobs/acre) on unprotected land (i.e. developable) land in zone (Ref: EPA 2010 Smart Location Database)                                       |
|D2A_JPHH   |Bzone |Year  |compound |JOB/HH                                            |NA, < 0  |            |Ratio of jobs to households in zone (Ref: EPA 2010 Smart Location Database)                                                                                            |
|D2A_WRKEMP |Bzone |Year  |compound |PRSN/JOB                                          |NA, < 0  |            |Ratio of workers to jobs in zone (Ref: EPA 2010 Smart Location Database)                                                                                               |
|D2A_EPHHM  |Bzone |Year  |double   |employment & household entropy                    |NA, < 0  |            |Employment and household entropy measure for zone considering numbers of households, retail jobs, service jobs, and other jobs (Ref: EPA 2010 Smart Location Database) |
|D3bpo4     |Bzone |Year  |double   |pedestrian-oriented intersections per square mile |NA       |            |Intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile (Ref: EPA 2010 Smart Location Database)                    |
