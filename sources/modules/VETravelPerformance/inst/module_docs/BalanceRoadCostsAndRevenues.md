
# BalanceRoadCostsAndRevenues Module
### January 23, 2019

This module calculates an extra mileage tax ($ per vehicle mile traveled) for household vehicles needed to make up any difference in the cost of constructing, maintaining, and operating roadways and the revenues from fuel, VMT, and congestion taxes.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

The module calculates the additional cost per vehicle mile of household travel required to pay for roadway costs attributable to household vehicle travel. The steps are as follows:

* The cost of adding freeway and arterial lane miles is calculated only if the model year is later than the base year. The difference between the freeway lane miles for the model year and for the base year is calculated for each marea. The total for all mareas is calculated but negative differences are ignored. In other words, no cost is attributed to the removal of freeway lane miles and the removal of freeway lane miles in one marea does not offset the cost of adding freeway lane miles in another marea. The same calculation is performed for arterial lane miles.

* It is assumed that changes in lane miles calculated for the period between the model year and the base year are made in equal increments over that time period. The changes are divided by the number of years to get the annual change in freeway lane miles and the annual change in arterial lane miles. The annual changes are multiplied by the respective costs per lane mile to get the annual cost for adding freeway lane miles and for adding arterial lane miles. These are summed.

* The proportion of the annual lane mile cost attributable to household vehicle travel is calculated by dividing total household DVMT by the sum of total household DVMT, commercial service vehicle DVMT, and car-equivalent heavy truck DVMT. The car-equivalent heavy truck DVMT is calculated by multiplying heavy truck DVMT by the passenger car equivalent factor ('HvyTrkPCE') that is a user input which reflects the relative road capacity demands of heavy trucks (e.g. 3 means one heavy truck is equivalent to 3 cars.)

* The cost of adding lane miles per mile of household travel is calculated by multiplying the annual lane mile addition cost by the proportion attributable to households and dividing by the household annual VMT (i.e. DVMT * 365).

* Other road costs per mile are calculated by summing the costs supplied by users for 'RoadBaseModCost' (modernization costs such as realignment but excluding adding lane miles), 'RoadPresOpMaintCost' (road preservation, operations, and maintenance), and 'RoadOtherCost' (administration, planning, travel demand management, etc.)

* The total cost per vehicle mile for households is calculated by summing the added lane mile cost rate and other road cost rate.

* The average road taxes collected per household vehicle mile are calculated as a weighted average of the average road tax per mile of each household (calculated by the 'CalculateVehicleOperatingCost' module) using the household DVMT (calculated by the 'BudgetHouseholdDvmt' module) as the weight.

* The difference between the total cost per vehicle mile and the average road taxes collected per vehicle mile is the extra VMT tax ('ExtraVmtTax'). If road tax collections exceed costs, the value of the extra VMT tax is set equal to 0.



## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### region_road_cost.csv
|NAME                |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                                                       |
|:-------------------|:--------|:-----|:--------|:-----------|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Year                |         |      |         |            |         |Must contain a record for each model run year                                                                                                                                     |
|RoadBaseModCost     |currency |USD   |NA, < 0  |            |         |Average base modernization cost per light-duty vehicle mile traveled (dollars per vehicle mile). Base modernization includes roadway improvements exclusive of addition of lanes. |
|RoadPresOpMaintCost |currency |USD   |NA, < 0  |            |         |Average road preservation, operations, and maintenance cost per light-duty vehicle mile traveled (dollars per vehicle mile).                                                      |
|RoadOtherCost       |currency |USD   |NA, < 0  |            |         |Average other road cost (e.g. administration, planning, project development, safety) per light-duty vehicle mile traveled (dollars per vehicle mile).                             |
|FwyLnMiCost         |currency |USD   |NA, < 0  |            |         |Average cost to build one freeway lane-mile (dollars per lane-mile)                                                                                                               |
|ArtLnMiCost         |currency |USD   |NA, < 0  |            |         |Average cost to build one arterial lane-mile (dollars per lane-mile)                                                                                                              |
|HvyTrkPCE           |double   |ratio |NA, < 0  |            |         |Passenger car equivalent (PCE) for heavy trucks. PCE indicates the number of light-duty vehicles a heavy truck is equivalent to in calculating road capacity.                     |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME                |TABLE     |GROUP    |TYPE      |UNITS  |PROHIBIT |ISELEMENTOF |
|:-------------------|:---------|:--------|:---------|:------|:--------|:-----------|
|RoadBaseModCost     |Region    |Year     |currency  |USD    |NA, < 0  |            |
|RoadPresOpMaintCost |Region    |Year     |currency  |USD    |NA, < 0  |            |
|RoadOtherCost       |Region    |Year     |currency  |USD    |NA, < 0  |            |
|FwyLnMiCost         |Region    |Year     |currency  |USD    |NA, < 0  |            |
|ArtLnMiCost         |Region    |Year     |currency  |USD    |NA, < 0  |            |
|HvyTrkPCE           |Region    |Year     |double    |ratio  |NA, < 0  |            |
|HvyTrkUrbanDvmt     |Region    |Year     |compound  |MI/DAY |NA, < 0  |            |
|HvyTrkNonUrbanDvmt  |Region    |Year     |compound  |MI/DAY |NA, < 0  |            |
|Marea               |Marea     |Year     |character |ID     |         |            |
|ComSvcUrbanDvmt     |Marea     |Year     |compound  |MI/DAY |NA, < 0  |            |
|ComSvcTownDvmt      |Marea     |Year     |compound  |MI/DAY |NA, < 0  |            |
|ComSvcRuralDvmt     |Marea     |Year     |compound  |MI/DAY |NA, < 0  |            |
|FwyLaneMi           |Marea     |BaseYear |distance  |MI     |NA, < 0  |            |
|ArtLaneMi           |Marea     |BaseYear |distance  |MI     |NA, < 0  |            |
|FwyLaneMi           |Marea     |Year     |distance  |MI     |NA, < 0  |            |
|ArtLaneMi           |Marea     |Year     |distance  |MI     |NA, < 0  |            |
|AveRoadUseTaxPM     |Household |Year     |currency  |USD    |NA, < 0  |            |
|Dvmt                |Household |Year     |compound  |MI/DAY |NA, < 0  |            |

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

|NAME        |TABLE  |GROUP |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                             |
|:-----------|:------|:-----|:--------|:-----|:--------|:-----------|:---------------------------------------------------------------------------------------------------------------------------------------|
|ExtraVmtTax |Region |Year  |currency |USD   |NA, < 0  |            |Added vehicle mile tax for household vehicle use to pay for any deficit between road costs and road revenues (dollars per vehicle mile) |
