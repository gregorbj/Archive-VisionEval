
# SimulateTransitService Module
### February 11, 2019

This module assigns transit service level to the urbanized portion of each Marea and to neighborhoods (SimBzones) within the urbanized area. Annual revenue-miles (i.e. transit miles in revenue service) by transit mode type are read from an input file. The following 8 modes are recognized:

* DR = Demand-responsive

* VP = Vanpool and similar

* MB = Standard motor bus

* RB = Bus rapid transit and commuter bus

* MG = Monorail/automated guideway

* SR = Streetcar/trolley bus/inclined plain

* HR = Heavy Rail/Light Rail

* CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway

Revenue miles are converted to bus (i.e. MB) equivalents using factors derived from urbanized are data from the National Transit Database (NTD). Bus-equivalent revenue miles are used in models which predict vehicle ownership and household DVMT.

Revenue miles by mode type are also translated (using NTD data) into vehicle miles by 3 vehicle types: van, bus, and rail. Miles by vehicle type are used to calculate public transit energy consumption and emissions.

The module also simulates relative public transit accessibility by Bzone as explained below.

## Model Parameter Estimation

Parameters are calculated to convert the revenue miles for each of the 8 recognized public transit modes into bus equivalents, and to convert revenue miles into vehicle miles. Data extracted from the 2015 National Transit Database (NTD) are used to calculate these parameters. Bus equivalent factors for each of the 8 modes is calculated on the basis of the average productivity of each mode as measured by the ratio of passenger miles to revenue miles. The bus-equivalency factor of each mode is the ratio of the average productivity of the mode to the average productivity of the bus (MB) mode. Factors to compute vehicle miles by mode from revenue miles by mode are calculated from the NTD data on revenue miles and deadhead (i.e. out of service) miles. The vehicle mile factor is the sum of revenue and deadhead miles divided by the revenue miles. These factors vary by mode. These model parameters are estimated by the *AssignTransitService* module in the *VETransportSupply* package and are imported into this module.

A model is also estimated to calculate SimBzone transit accessibility which measures how easily transit service may be accessed from each zone. The Smart Location Database includes several transit accessibility measures. The D4c measure is the one used in the forthcoming multimodal household travel module. D4c is a measure of the aggregate frequency of transit service within 0.25 miles of the block group boundary per hour during evening peak period (4:00 PM to 7:00 PM). The D4c simulation model simulates SimBzone D4c values as a function of the level of transit service in the urbanized area, the relationship between the average D4c value for the urbanized area and the level of transit service, and the place types of the SimBzones (where place type is the combination of area type and development type). This model is estimated by the *CreateSimBzoneModels* module in the *VESimLandUse* package and is documented there. It is imported into this module.

## How the Module Work

The user supplies data on the annual revenue miles of service by each of the 8 transit modes for each Marea. These revenue miles are converted to bus equivalents using the estimated bus-equivalency factors and summed to calculate total bus-equivalent revenue miles. This value is divided by the urbanized area population of the Marea to compute bus-equivalent revenue miles per capita. This public transit service measure is used in models of household vehicle ownership and household vehicle travel.

The user supplied revenue miles by mode are translated into vehicle miles by mode using the estimated conversion factors. The results are then simplified into 3 vehicle types (Van, Bus, Rail) where the DR and VP modes are assumed to be served by vans, the MB and RB modes are assumed to be served by buses, and the MG, SR, HR, and CR modes are assumed to be served by rail.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### marea_transit_service.csv
|NAME    |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                              |
|:-------|:--------|:-----|:--------|:-----------|:--------|:--------------------------------------------------------------------------------------------------------|
|Geo     |         |      |         |Mareas      |         |Must contain a record for each Marea and model run year.                                                 |
|Year    |         |      |         |            |         |Must contain a record for each Marea and model run year.                                                 |
|DRRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of demand-responsive public transit service                                         |
|VPRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of van-pool and similar public transit service                                      |
|MBRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of standard bus public transit service                                              |
|RBRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of rapid-bus and commuter bus public transit service                                |
|MGRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of monorail and automated guideway public transit service                           |
|SRRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of streetcar and trolleybus public transit service                                  |
|HRRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of light rail and heavy rail public transit service                                 |
|CRRevMi |compound |MI/YR |< 0      |            |         |Annual revenue-miles of commuter rail, hybrid rail, cable car, and aerial tramway public transit service |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME           |TABLE |GROUP  |TYPE       |UNITS    |PROHIBIT |ISELEMENTOF                  |
|:--------------|:-----|:------|:----------|:--------|:--------|:----------------------------|
|Marea          |Marea |Year   |character  |ID       |         |                             |
|Marea          |Bzone |Year   |character  |ID       |         |                             |
|DRRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|VPRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|MBRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|RBRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|MGRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|SRRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|HRRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|CRRevMi        |Marea |Year   |compound   |MI/YR    |< 0      |                             |
|UzaProfileName |Marea |Global |character  |ID       |         |                             |
|UrbanPop       |Bzone |Year   |people     |PRSN     |NA, < 0  |                             |
|AreaType       |Bzone |Year   |character  |category |NA       |center, inner, outer, fringe |
|DevType        |Bzone |Year   |character  |category |NA       |emp, mix, res                |
|UrbanArea      |Bzone |Year   |area       |ACRE     |NA, < 0  |                             |
|NumHh          |Bzone |Year   |households |HH       |NA, < 0  |                             |
|TotEmp         |Bzone |Year   |people     |PRSN     |NA, < 0  |                             |

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

|NAME        |TABLE |GROUP |TYPE     |UNITS                                 |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                                                                  |
|:-----------|:-----|:-----|:--------|:-------------------------------------|:--------|:-----------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|TranRevMiPC |Marea |Year  |compound |MI/PRSN/YR                            |NA, < 0  |            |Ratio of annual bus-equivalent revenue-miles (i.e. revenue-miles at the same productivity - passenger miles per revenue mile - as standard bus) to urbanized area population |
|VanDvmt     |Marea |Year  |compound |MI/DAY                                |NA, < 0  |            |Total daily miles traveled by vans of various sizes to provide demand responsive, vanpool, and similar services.                                                             |
|BusDvmt     |Marea |Year  |compound |MI/DAY                                |NA, < 0  |            |Total daily miles traveled by buses of various sizes to provide bus service of various types.                                                                                |
|RailDvmt    |Marea |Year  |compound |MI/DAY                                |NA, < 0  |            |Total daily miles traveled by light rail, heavy rail, commuter rail, and similar types of vehicles.                                                                          |
|D4c         |Bzone |Year  |double   |aggregate peak period transit service |NA, < 0  |            |Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period (Ref: EPA 2010 Smart Location Database)                 |
