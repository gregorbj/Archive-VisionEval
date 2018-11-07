
# AssignParkingRestrictions Module
### November 6, 2018

This module identifies parking restrictions and prices affecting households at their residences, workplaces, and other places they are likely to visit in the urban area. The module takes user inputs on parking restrictions and prices by Bzone and calculates for each household the number of free parking spaces available at the household's residence, which workers pay for parking and whether their payment is part of a *cash-out-buy-back* program, the cost of residential parking for household vehicles that can't be parked in a free space, the cost for workplace parking, and the cost of parking for other activities such as shopping. The parking restriction/cost information is used by other modules in calculating the cost of vehicle ownership and the cost of vehicle use.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

The user provides inputs by Bzone which provide the basis for calculating
parking restrictions/costs. These include:

- Average number of free parking spaces per single-family dwelling unit

- Average number of free parking spaces per multifamily dwelling unit

- Average number of free parking spaces per group quarters resident

- Proportion of workers working at jobs in the Bzone who pay for parking

- Proportion of worker paid parking in *cash-out_buy-back* program

- Average daily parking cost

Residential Bzone parking restrictions are applied to each household based on the Bzone and dwelling type of the household and the supplied inputs on the average number of parking spaces per household by Bzone and dwelling type. If the average number of parking spaces is not an integer, the household is assigned the integer amount of spaces and a possible additional space determined through a random draw with the decimal portion serving as the probability of success. For example, if the average is 1.75 spaces, all households would be assigned at least 1 space and 75% of the households would be assigned 2 spaces. The daily parking cost assigned to the Bzone is assigned to the household to use in vehicle ownership cost calculations.

A worker is assigned as paying or not paying for parking through a random draw with the probability of paying equal to the proportion of paying workers that is input for the Bzone of the worker's job location. A worker identified as paying for parking is identified as being in a *cash-out-buy-back* program through a random draw with the participation probability being the input value for the Bzone of the worker's job location. The daily parking cost assigned to the worker's job site Bzone is assigned to the work to use in vehicle use calculations.

Other household parking costs (e.g. shopping) are assigned to households based on the daily parking cost assigned to each Bzone and the assumption that the likelihood that a household would visit the Bzone is directly proportional to the relative number of activities in the Bzone and the inverse of the distance to the Bzone from the household residence Bzone. The activity in the Bzone is measured with the total number of retail and service jobs in the Bzone. As with the LocateEmployment and Calculate4DMeasures modules, a centroid-to-centroid distance matrix is calculated from user supplied data on the latitude and longitude of each Bzone centroid. Next, the number of Bzone attractions is scaled to equal the number of households. Then an iterative proportional fitting process (IPF) is used to allocate households to attractions where the margins are the numbers of households by Bzone and the scaled attractions by Bzone, and the seed matrix is the inverse of the values of the distance matrix. After a balanced matrix has been computed, the proportions of attractions from each residence Bzone to each attraction Bzone is calculated such that the total for each residence Bzone adds to 1. Finally, the average daily parking cost for residents of a Bzone is the sum of the product of the attraction proportion to each Bzone and the daily parking cost in each Bzone. Households are assigned the cost calculated for their Bzone of residence. This cost is adjusted to account for the number of household vehicle trips when the household's vehicle use costs are calculated.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_parking.csv
|NAME             |TYPE     |UNITS          |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                  |
|:----------------|:--------|:--------------|:------------|:-----------|:--------|:--------------------------------------------------------------------------------------------|
|Geo              |         |               |             |Bzones      |         |Must contain a record for each Bzone and model run year.                                     |
|Year             |         |               |             |            |         |Must contain a record for each Bzone and model run year.                                     |
|PkgSpacesPerSFDU |double   |parking spaces |NA, < 0      |            |         |Average number of free parking spaces available to residents of single-family dwelling units |
|PkgSpacesPerMFDU |double   |parking spaces |NA, < 0      |            |         |Average number of free parking spaces available to residents of multifamily dwelling units   |
|PkgSpacesPerGQ   |double   |parking spaces |NA, < 0      |            |         |Average number of free parking spaces available to group quarters residents                  |
|PropWkrPay       |double   |proportion     |NA, < 0, > 1 |            |         |Proportion of workers who pay for parking                                                    |
|PropCashOut      |double   |proportion     |NA, < 0, > 1 |            |         |Proportions of workers paying for parking in a cash-out-buy-back program                     |
|PkgCost          |currency |USD            |NA, < 0      |            |         |Average daily cost for long-term parking (e.g. paid on monthly basis)                        |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME             |TABLE     |GROUP |TYPE       |UNITS          |PROHIBIT     |ISELEMENTOF |
|:----------------|:---------|:-----|:----------|:--------------|:------------|:-----------|
|Bzone            |Bzone     |Year  |character  |ID             |             |            |
|PkgSpacesPerSFDU |Bzone     |Year  |double     |parking spaces |NA, < 0      |            |
|PkgSpacesPerMFDU |Bzone     |Year  |double     |parking spaces |NA, < 0      |            |
|PkgSpacesPerGQ   |Bzone     |Year  |double     |parking spaces |NA, < 0      |            |
|PropWkrPay       |Bzone     |Year  |double     |proportion     |NA, < 0, > 1 |            |
|PropCashOut      |Bzone     |Year  |double     |proportion     |NA, < 0, > 1 |            |
|PkgCost          |Bzone     |Year  |currency   |USD            |NA, < 0      |            |
|NumHh            |Bzone     |Year  |households |HH             |NA, < 0      |            |
|RetEmp           |Bzone     |Year  |people     |PRSN           |NA, < 0      |            |
|SvcEmp           |Bzone     |Year  |people     |PRSN           |NA, < 0      |            |
|Latitude         |Bzone     |Year  |double     |NA             |NA           |            |
|Longitude        |Bzone     |Year  |double     |NA             |NA           |            |
|HouseType        |Household |Year  |character  |category       |             |SF, MF, GQ  |
|Bzone            |Household |Year  |character  |ID             |             |            |
|Bzone            |Worker    |Year  |character  |ID             |             |            |

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
