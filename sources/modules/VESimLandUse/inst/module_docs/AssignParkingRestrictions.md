
# AssignParkingRestrictions Module
### February 7, 2018

This module identifies parking restrictions and prices affecting households at their residences, workplaces, and other places they are likely to visit in the urban area. The module takes user inputs on parking restrictions and prices by Bzone and calculates for each household the number of free parking spaces available at the household's residence, which workers pay for parking and whether their payment is part of a *cash-out-buy-back* program, the cost of residential parking for household vehicles that can't be parked in a free space, the cost for workplace parking, and the cost of parking for other activities such as shopping. The parking restriction/cost information is used by other modules in calculating the cost of vehicle ownership and the cost of vehicle use.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

The user provides inputs by Marea and 3 of 4 area types the following information which provide the basis for calculating
parking restrictions and costs for each household. These include:

- Average number of free parking spaces per single-family dwelling unit

- Average number of free parking spaces per multifamily dwelling unit

- Average number of free parking spaces per group quarters resident

- Proportion of workers working at jobs in the Bzone who pay for parking

- Proportion of worker paid parking in *cash-out_buy-back* program

- Average daily parking cost

The user only provides information for the *center*, *inner*, and *outer* area types. For simplicity it is assumed that there are no parking restrictions or costs in fringe areas.

Free residential parking spaces are applied to each household based on the user inputs for available spaces for the dwelling type of the household and area type of the Bzone where the household resides. If the average number of parking spaces is not an integer, the household is assigned the integer amount of spaces and a possible additional space determined through a random draw with the decimal portion serving as the probability of success. For example, if the average is 1.75 spaces, all households would be assigned at least 1 space and 75% of the households would be assigned 2 spaces. The daily parking cost assigned to the area type of the Bzone where the household resides is assigned to the household to use in vehicle ownership cost calculations.

A worker is assigned as paying or not paying for parking through a random draw with the probability of paying equal to the proportion of paying workers that is input for the area type of the worker's job location. A worker identified as paying for parking is identified as being in a *cash-out-buy-back* program through a random draw with the participation probability being the input value for the area type of the worker's job location. The daily parking cost assigned to the worker's job site area type is assigned to the work to use in vehicle use calculations.

Average daily parking costs for other (non-work) household travel purposes (e.g. shopping) are assigned to households based on their location type and area type. Households in rural and town locations are assigned a value of 0. Households in urban locations are assigned a weighted average value of the parking costs assigned to the area types in the urban area where the proportion of urban retail and service employment in each area type is used as the weighting factor. This cost is adjusted to account for the number of household vehicle trips when the household's vehicle use costs are calculated.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### marea_parking-avail_by_area-type.csv
|NAME                   |TYPE   |UNITS          |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                      |
|:----------------------|:------|:--------------|:--------|:-----------|:--------|:----------------------------------------------------------------------------------------------------------------|
|Geo                    |       |               |         |Mareas      |         |Must contain a record for each Marea and model run year.                                                         |
|Year                   |       |               |         |            |         |Must contain a record for each Marea and model run year.                                                         |
|CenterPkgSpacesPerSFDU |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to residents of single-family dwelling units in center area type |
|InnerPkgSpacesPerSFDU  |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to residents of single-family dwelling units in inner area type  |
|OuterPkgSpacesPerSFDU  |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to residents of single-family dwelling units in outer area type  |
|CenterPkgSpacesPerMFDU |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to residents of multifamily dwelling units in center area type   |
|InnerPkgSpacesPerMFDU  |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to residents of multifamily dwelling units in inner area type    |
|OuterPkgSpacesPerMFDU  |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to residents of multifamily dwelling units in outer area type    |
|CenterPkgSpacesPerGQ   |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to group quarters residents in center area type                  |
|InnerPkgSpacesPerGQ    |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to group quarters residents in inner area type                   |
|OuterPkgSpacesPerGQ    |double |parking spaces |NA, < 0  |            |         |Average number of free parking spaces available to group quarters residents in outer area type                   |
### marea_parking-cost_by_area-type.csv
|   |NAME              |TYPE     |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                  |
|:--|:-----------------|:--------|:----------|:------------|:-----------|:--------|:--------------------------------------------------------------------------------------------|
|1  |Geo               |         |           |             |Mareas      |         |Must contain a record for each Marea and model run year.                                     |
|19 |Year              |         |           |             |            |         |Must contain a record for each Marea and model run year.                                     |
|10 |CenterPropWkrPay  |double   |proportion |NA, < 0, > 1 |            |         |Proportion of workers who pay for parking in center area type                                |
|11 |InnerPropWkrPay   |double   |proportion |NA, < 0, > 1 |            |         |Proportion of workers who pay for parking in inner area type                                 |
|12 |OuterPropWkrPay   |double   |proportion |NA, < 0, > 1 |            |         |Proportion of workers who pay for parking in outer area type                                 |
|13 |CenterPropCashOut |double   |proportion |NA, < 0, > 1 |            |         |Proportions of workers paying for parking in a cash-out-buy-back program in center area type |
|14 |InnerPropCashOut  |double   |proportion |NA, < 0, > 1 |            |         |Proportions of workers paying for parking in a cash-out-buy-back program in inner area type  |
|15 |OuterPropCashOut  |double   |proportion |NA, < 0, > 1 |            |         |Proportions of workers paying for parking in a cash-out-buy-back program in outer area type  |
|16 |CenterPkgCost     |currency |USD        |NA, < 0      |            |         |Average daily cost for long-term parking (e.g. paid on monthly basis) in center area type    |
|17 |InnerPkgCost      |currency |USD        |NA, < 0      |            |         |Average daily cost for long-term parking (e.g. paid on monthly basis) in inner area type     |
|18 |OuterPkgCost      |currency |USD        |NA, < 0      |            |         |Average daily cost for long-term parking (e.g. paid on monthly basis) in outer area type     |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME                   |TABLE     |GROUP |TYPE       |UNITS          |PROHIBIT     |ISELEMENTOF                  |
|:----------------------|:---------|:-----|:----------|:--------------|:------------|:----------------------------|
|Marea                  |Marea     |Year  |character  |ID             |             |                             |
|CenterPkgSpacesPerSFDU |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|InnerPkgSpacesPerSFDU  |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|OuterPkgSpacesPerSFDU  |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|CenterPkgSpacesPerMFDU |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|InnerPkgSpacesPerMFDU  |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|OuterPkgSpacesPerMFDU  |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|CenterPkgSpacesPerGQ   |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|InnerPkgSpacesPerGQ    |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|OuterPkgSpacesPerGQ    |Marea     |Year  |double     |parking spaces |NA, < 0      |                             |
|CenterPropWkrPay       |Marea     |Year  |double     |proportion     |NA, < 0, > 1 |                             |
|InnerPropWkrPay        |Marea     |Year  |double     |proportion     |NA, < 0, > 1 |                             |
|OuterPropWkrPay        |Marea     |Year  |double     |proportion     |NA, < 0, > 1 |                             |
|CenterPropCashOut      |Marea     |Year  |double     |proportion     |NA, < 0, > 1 |                             |
|InnerPropCashOut       |Marea     |Year  |double     |proportion     |NA, < 0, > 1 |                             |
|OuterPropCashOut       |Marea     |Year  |double     |proportion     |NA, < 0, > 1 |                             |
|CenterPkgCost          |Marea     |Year  |currency   |USD            |NA, < 0      |                             |
|InnerPkgCost           |Marea     |Year  |currency   |USD            |NA, < 0      |                             |
|OuterPkgCost           |Marea     |Year  |currency   |USD            |NA, < 0      |                             |
|Bzone                  |Bzone     |Year  |character  |ID             |             |                             |
|Marea                  |Bzone     |Year  |character  |ID             |             |                             |
|LocType                |Bzone     |Year  |character  |category       |NA           |Urban, Town, Rural           |
|AreaType               |Bzone     |Year  |character  |category       |NA           |center, inner, outer, fringe |
|NumHh                  |Bzone     |Year  |households |HH             |NA, < 0      |                             |
|RetEmp                 |Bzone     |Year  |people     |PRSN           |NA, < 0      |                             |
|SvcEmp                 |Bzone     |Year  |people     |PRSN           |NA, < 0      |                             |
|HouseType              |Household |Year  |character  |category       |             |SF, MF, GQ                   |
|HhId                   |Household |Year  |character  |ID             |             |                             |
|Bzone                  |Household |Year  |character  |ID             |             |                             |
|Marea                  |Household |Year  |character  |ID             |             |                             |
|WkrId                  |Worker    |Year  |character  |ID             |             |                             |
|Bzone                  |Worker    |Year  |character  |ID             |             |                             |
|Marea                  |Worker    |Year  |character  |ID             |             |                             |

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

|NAME              |TABLE     |GROUP |TYPE     |UNITS          |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                                   |
|:-----------------|:---------|:-----|:--------|:--------------|:--------|:-----------|:---------------------------------------------------------------------------------------------------------------------------------------------|
|FreeParkingSpaces |Household |Year  |integer  |parking spaces |NA, < 0  |            |Number of free parking spaces available to the household                                                                                      |
|ParkingUnitCost   |Household |Year  |currency |USD            |NA, < 0  |            |Daily cost for long-term parking (e.g. paid on monthly basis)                                                                                 |
|OtherParkingCost  |Household |Year  |currency |USD            |NA, < 0  |            |Daily cost for parking at shopping locations or other locations of paid parking not including work (not adjusted for number of vehicle trips) |
|PaysForParking    |Worker    |Year  |integer  |binary         |         |0, 1        |Does worker pay for parking: 1 = yes, 0 = no                                                                                                  |
|IsCashOut         |Worker    |Year  |integer  |binary         |         |0, 1        |Is worker paid parking in cash-out-buy-back program: 1 = yes, 0 = no                                                                          |
|ParkingCost       |Worker    |Year  |currency |USD            |NA, < 0  |            |Daily cost for long-term parking (e.g. paid on monthly basis)                                                                                 |
