
# AssignDevTypes Module
### November 6, 2018

This module assigns households to development types: Urban (located within an urbanized area boundary) and Rural (located outside of an urbanized area boundary).

## Model Parameter Estimation

This module has no parameters. Households are assigned to development types based on input assumptions on the proportions of housing units that are urban by Bzone and housing type.

## How the Module Works

The user specifies the proportion of housing units that are *Urban* (located within an urbanized area boundary) by housing type (SF, MF, GQ) and Bzone. Each household is randomly assigned as *Urban* or *Rural* based on its housing type and Bzone and the urban/rural proportions of housing units of that housing type in that Bzone.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_urban_du_proportions.csv
|NAME          |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                              |
|:-------------|:------|:-----|:--------|:-----------|:--------|:----------------------------------------------------------------------------------------|
|Geo           |       |      |         |Bzones      |         |Must contain a record for each Bzone and model run year.                                 |
|Year          |       |      |         |            |         |Must contain a record for each Bzone and model run year.                                 |
|PropUrbanSFDU |double |NA    |NA, < 0  |            |         |Proportion of single family dwelling units located within the urban portion of the zone  |
|PropUrbanMFDU |double |NA    |NA, < 0  |            |         |Proportion of multi-family dwelling units located within the urban portion of the zone   |
|PropUrbanGQDU |double |NA    |NA, < 0  |            |         |Proportion of group quarters accommodations located within the urban portion of the zone |

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
|Marea         |Marea     |Year  |character |ID       |         |            |
|Bzone         |Bzone     |Year  |character |ID       |         |            |
|Marea         |Bzone     |Year  |character |ID       |         |            |
|PropUrbanSFDU |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|PropUrbanMFDU |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|PropUrbanGQDU |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|HhId          |Household |Year  |character |ID       |         |            |
|HouseType     |Household |Year  |character |category |         |SF, MF, GQ  |
|Bzone         |Household |Year  |character |ID       |         |            |
|HhSize        |Household |Year  |people    |PRSN     |NA, <= 0 |            |
|Income        |Household |Year  |currency  |USD.2010 |NA, < 0  |            |

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

|NAME        |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF  |DESCRIPTION                                                                                               |
|:-----------|:---------|:-----|:---------|:--------|:--------|:------------|:---------------------------------------------------------------------------------------------------------|
|DevType     |Household |Year  |character |category |NA       |Urban, Rural |Development type (Urban or Rural) of the place where the household resides                                |
|Marea       |Household |Year  |character |ID       |         |             |Name of metropolitan area (Marea) that household is in or NA if none                                      |
|UrbanPop    |Bzone     |Year  |people    |PRSN     |NA, < 0  |             |Urbanized area population in the Bzone                                                                    |
|RuralPop    |Bzone     |Year  |people    |PRSN     |NA, < 0  |             |Rural (i.e. non-urbanized area) population in the Bzone                                                   |
|UrbanPop    |Marea     |Year  |people    |PRSN     |NA, < 0  |             |Urbanized area population in the Marea (metropolitan area)                                                |
|RuralPop    |Marea     |Year  |people    |PRSN     |NA, < 0  |             |Rural (i.e. non-urbanized area) population in the Marea (metropolitan area)                               |
|UrbanIncome |Marea     |Year  |currency  |USD.2010 |NA, < 0  |             |Total household income of the urbanized area population in the Marea (metropolitan area)                  |
|RuralIncome |Marea     |Year  |currency  |USD.2010 |NA, < 0  |             |Total household income of the rural (i.e. non-urbanized area) population in the Marea (metropolitan area) |
