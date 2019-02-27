
# CalculateComEnergyAndEmissions Module
### January 23, 2019

This module calculates the energy consumption and carbon emissions of heavy trucks and light-duty commercial service vehicles. It does not calculate the values for car service vehicles which are calculated as part of the household emissions. It also does not calculate public transit emissions which are calculated in the CalculatePtranEnergyAndEmissions module.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

This module calculates the energy consumption and carbon emissions production from commercial travel in the following steps:

* Calculate commercial service DVMT propportions by vehicle type and powertrain

* Calculate heavy truck DVMT proportion by powertrain

* Calculate net ecodriving and speed smoothing effects by powertrain

* Identify congestion fuel economy effects by marea and powertrain type

* Calculate adjusted MPG and MPKWH by vehicle type and powertrain

* Calculate carbon intensity by marea and region

* Calculate commercial service vehicle energy consumption and CO2e production

* Calculate heavy truck energy consumption and CO2e production


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### region_comsvc_lttrk_prop.csv
|NAME            |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                              |
|:---------------|:------|:----------|:------------|:-----------|:--------|:------------------------------------------------------------------------|
|Year            |       |           |             |            |         |Must contain a record for each model run year                            |
|ComSvcLtTrkProp |double |proportion |NA, < 0, > 1 |            |         |Regional proportion of commercial service vehicles that are light trucks |
### region_comsvc_veh_mean_age.csv
|NAME                |TYPE |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                   |
|:-------------------|:----|:-----|:--------|:-----------|:--------|:---------------------------------------------|
|Year                |     |      |         |            |         |Must contain a record for each model run year |
|AveComSvcVehicleAge |time |YR    |NA, < 0  |            |         |Average age of commercial service vehicles    |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME                  |TABLE  |GROUP |TYPE      |UNITS      |PROHIBIT     |ISELEMENTOF |
|:---------------------|:------|:-----|:---------|:----------|:------------|:-----------|
|Marea                 |Marea  |Year  |character |ID         |             |            |
|Azone                 |Azone  |Year  |character |ID         |             |            |
|Marea                 |Azone  |Year  |character |ID         |             |            |
|ElectricityCI         |Azone  |Year  |compound  |GM/MJ      |< 0          |            |
|HhAutoFuelCI          |Region |Year  |compound  |GM/MJ      |< 0          |            |
|HhLtTrkFuelCI         |Region |Year  |compound  |GM/MJ      |< 0          |            |
|HvyTrkFuelCI          |Region |Year  |compound  |GM/MJ      |< 0          |            |
|LdvEcoDrive           |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|HvyTrkEcoDrive        |Marea  |Year  |double    |proportion |NA, < 0, > 1 |            |
|LdvSpdSmoothFactor    |Marea  |Year  |double    |proportion |<= 0         |            |
|HvyTrkSpdSmoothFactor |Marea  |Year  |double    |proportion |<= 0         |            |
|LdvEcoDriveFactor     |Marea  |Year  |double    |proportion |<= 0         |            |
|HvyTrkEcoDriveFactor  |Marea  |Year  |double    |proportion |<= 0         |            |
|LdIceFactor           |Marea  |Year  |double    |proportion |<= 0         |            |
|LdHevFactor           |Marea  |Year  |double    |proportion |<= 0         |            |
|LdEvFactor            |Marea  |Year  |double    |proportion |<= 0         |            |
|HdIceFactor           |Marea  |Year  |double    |proportion |<= 0         |            |
|HvyTrkUrbanDvmt       |Region |Year  |compound  |MI/DAY     |<= 0         |            |
|HvyTrkNonUrbanDvmt    |Region |Year  |compound  |MI/DAY     |<= 0         |            |
|ComSvcUrbanDvmt       |Marea  |Year  |compound  |MI/DAY     |NA, < 0      |            |
|ComSvcTownDvmt        |Marea  |Year  |compound  |MI/DAY     |NA, < 0      |            |
|ComSvcRuralDvmt       |Marea  |Year  |compound  |MI/DAY     |NA, < 0      |            |
|HvyTrkUrbanDvmt       |Marea  |Year  |compound  |MI/DAY     |NA, < 0      |            |
|ComSvcAutoPropIcev    |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|ComSvcAutoPropHev     |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|ComSvcAutoPropBev     |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|ComSvcLtTrkPropIcev   |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|ComSvcLtTrkPropHev    |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|ComSvcLtTrkPropBev    |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|HvyTrkPropIcev        |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|HvyTrkPropHev         |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|HvyTrkPropBev         |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|ComSvcLtTrkProp       |Region |Year  |double    |proportion |NA, < 0, > 1 |            |
|AveComSvcVehicleAge   |Region |Year  |time      |YR         |NA, < 0      |            |

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

|NAME                        |TABLE  |GROUP |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                                                   |
|:---------------------------|:------|:-----|:--------|:-----|:--------|:-----------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------|
|ComSvcUrbanGGE              |Marea  |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by commercial service vehicles associated with urban household activity in gas gallon equivalents          |
|ComSvcNonUrbanGGE           |Marea  |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by commercial service vehicles associated with rural and town household activity in gas gallon equivalents |
|HvyTrkUrbanGGE              |Marea  |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by heavy trucks on urbanized area roadways in the Marea in gas gallon equivalents                          |
|ComSvcUrbanKWH              |Marea  |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by commercial service vehicles associated with urban household activity in kilowatt-hours                        |
|ComSvcNonUrbanKWH           |Marea  |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by commercial service vehicles associated with rural and town household activity in kilowatt-hours               |
|HvyTrkUrbanKWH              |Marea  |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by heavy trucks on urbanized area roadways in the Marea in kilowatt-hours                                        |
|ComSvcUrbanCO2e             |Marea  |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by commercial service vehicles associated with urban household activity in grams                  |
|ComSvcNonUrbanCO2e          |Marea  |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by commercial service vehicles associated with rural and town household activity in grams         |
|HvyTrkUrbanCO2e             |Marea  |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by heavy trucks on urbanized area roadways in the Marea in grams                                  |
|ComSvcAveUrbanAutoCO2eRate  |Marea  |Year  |compound |GM/MI |< 0      |            |Average amount of carbon-dioxide equivalents produced by commercial service automobiles per mile of travel on urbanized area roadways in grams per mile       |
|ComSvcAveUrbanLtTrkCO2eRate |Marea  |Year  |compound |GM/MI |< 0      |            |Average amount of carbon-dioxide equivalents produced by commercial service light trucks per mile of travel on urbanized area roadways in grams per mile      |
|HvyTrkAveUrbanCO2eRate      |Marea  |Year  |compound |GM/MI |< 0      |            |Average amount of carbon-dioxide equivalents produced by heavy trucks per mile of travel on urbanized area roadways in grams per mile                         |
|HvyTrkNonUrbanGGE           |Region |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by heavy trucks on rural and town roadways in the Region in gas gallon equivalents                         |
|HvyTrkUrbanGGE              |Region |Year  |energy   |GGE   |NA, < 0  |            |Average daily amount of hydrocarbon fuels consumed by heavy trucks on urbanized area roadways in the Region in gas gallon equivalents                         |
|HvyTrkNonUrbanKWH           |Region |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by heavy trucks on rural and town roadways in the Region in kilowatt-hours                                       |
|HvyTrkUrbanKWH              |Region |Year  |energy   |KWH   |NA, < 0  |            |Average daily amount of electricity consumed by heavy trucks on urbanized area roadways in the Region in kilowatt-hours                                       |
|HvyTrkNonUrbanCO2e          |Region |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by heavy trucks on rural and town roadways in the Region in grams                                 |
|HvyTrkUrbanCO2e             |Region |Year  |mass     |GM    |NA, < 0  |            |Average daily amount of carbon-dioxide equivalents produced by heavy trucks on urbanized area roadways in the Region in grams                                 |
