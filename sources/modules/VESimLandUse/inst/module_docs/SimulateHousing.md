
# SimulateHousing Module
### February 3, 2019

This module assigns a housing type, either single-family (SF) or multifamily (MF) to *regular* households based on the respective supplies of SF and MF dwelling units in the housing market to which the household is assigned (i.e. the Azone the household is assigned to) and on household characteristics. It then assigns each household to a SimBzone based on the household's housing type as well as the supply of housing by type and SimBzone. The module assigns non-institutional group quarters *households* to SimBzones randomly.

## Model Parameter Estimation

This module uses the housing choice model estimated by the 'PredictHousing' module in the 'VELandUse' package.

## How the Module Works

The module carries out the following series of calculations to assign a housing type (SF or MF) to each *regular* household and to assign each household to a Bzone location.

1) The proportions of SF and MF dwelling units in the Azone are calculated.

2) The housing choice model is applied to each household in the Azone to determine the household's housing type. The model is applied multiple times using a binary search algorithm to successively adjust the model intercept until the housing type *choice* proportions equal the housing unit proportions in the Azone.

3) A matrix of the number of housing units by Bzone and housing type is created from data retrieved from the datastore.

4) Households are randomly assigned to SimBzones based on their housing type and the quantity of housing of each type in each SimBzone.

5) Non-institutionalized group-quarters *households* are assigned randomly to SimBzones.


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

|NAME            |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT |ISELEMENTOF                  |
|:---------------|:---------|:-----|:---------|:----------|:--------|:----------------------------|
|Marea           |Marea     |Year  |character |ID         |         |                             |
|Azone           |Azone     |Year  |character |ID         |         |                             |
|PropGQPopCenter |Azone     |Year  |double    |proportion |< 0, > 1 |                             |
|PropGQPopInner  |Azone     |Year  |double    |proportion |< 0, > 1 |                             |
|PropGQPopOuter  |Azone     |Year  |double    |proportion |< 0, > 1 |                             |
|PropGQPopFringe |Azone     |Year  |double    |proportion |< 0, > 1 |                             |
|Bzone           |Bzone     |Year  |character |ID         |         |                             |
|Azone           |Bzone     |Year  |character |ID         |         |                             |
|Marea           |Bzone     |Year  |character |ID         |         |                             |
|SFDU            |Bzone     |Year  |integer   |DU         |NA, < 0  |                             |
|MFDU            |Bzone     |Year  |integer   |DU         |NA, < 0  |                             |
|LocType         |Bzone     |Year  |character |category   |NA       |Urban, Town, Rural           |
|AreaType        |Bzone     |Year  |character |category   |NA       |center, inner, outer, fringe |
|Azone           |Household |Year  |character |ID         |         |                             |
|HhId            |Household |Year  |character |ID         |         |                             |
|Income          |Household |Year  |currency  |USD.2010   |NA, < 0  |                             |
|HhSize          |Household |Year  |people    |PRSN       |NA, <= 0 |                             |
|Workers         |Household |Year  |people    |PRSN       |NA, <= 0 |                             |
|Age15to19       |Household |Year  |people    |PRSN       |NA, < 0  |                             |
|Age20to29       |Household |Year  |people    |PRSN       |NA, < 0  |                             |
|Age30to54       |Household |Year  |people    |PRSN       |NA, < 0  |                             |
|Age55to64       |Household |Year  |people    |PRSN       |NA, < 0  |                             |
|Age65Plus       |Household |Year  |people    |PRSN       |NA, < 0  |                             |
|HhType          |Household |Year  |character |category   |         |                             |

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

|NAME        |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF        |DESCRIPTION                                                                                                      |
|:-----------|:---------|:-----|:---------|:--------|:--------|:------------------|:----------------------------------------------------------------------------------------------------------------|
|HouseType   |Household |Year  |character |category |         |SF, MF, GQ         |Type of dwelling unit in which the household resides (SF = single family, MF = multi-family, GQ = group quarters |
|Bzone       |Household |Year  |character |ID       |         |                   |ID of Bzone in which household resides                                                                           |
|LocType     |Household |Year  |character |category |NA       |Urban, Town, Rural |Location type (Urban, Town, Rural) of the place where the household resides                                      |
|Pop         |Bzone     |Year  |people    |PRSN     |NA, < 0  |                   |Total population residing in Bzone                                                                               |
|UrbanPop    |Bzone     |Year  |people    |PRSN     |NA, < 0  |                   |Urban LocType population residing in Bzone                                                                       |
|TownPop     |Bzone     |Year  |people    |PRSN     |NA, < 0  |                   |Town LocType population residing in Bzone                                                                        |
|RuralPop    |Bzone     |Year  |people    |PRSN     |NA, < 0  |                   |Rural LocType population residing in Bzone                                                                       |
|NumWkr      |Bzone     |Year  |people    |PRSN     |NA, < 0  |                   |Number of workers residing in zone                                                                               |
|UrbanPop    |Marea     |Year  |people    |PRSN     |NA, < 0  |                   |Urbanized area population in the Marea                                                                           |
|TownPop     |Marea     |Year  |people    |PRSN     |NA, < 0  |                   |Town (i.e. urban but non-urbanized area) in the Marea                                                            |
|RuralPop    |Marea     |Year  |people    |PRSN     |NA, < 0  |                   |Rural (i.e. not urbanized and not town) population in the Marea                                                  |
|UrbanIncome |Marea     |Year  |currency  |USD.2010 |NA, < 0  |                   |Total household income of the urbanized area population in the Marea                                             |
|TownIncome  |Marea     |Year  |currency  |USD.2010 |NA, < 0  |                   |Total household income of the town (i.e. urban but non-urbanized area) population in the Marea                   |
|RuralIncome |Marea     |Year  |currency  |USD.2010 |NA, < 0  |                   |Total household income of the rural (i.e. not urbanized and not town) population in the Marea                    |
