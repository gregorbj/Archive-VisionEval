
# Initialize Module
### November 24, 2018

 This module processes vehicle and fuel characteristics files that model users may optionally supply. When these files are supplied, modules in the package that compute carbon intensities of vehicle travel will use the user-supplied data instead of the datasets that are part of the package (see the LoadDefaultValues.R script). The optional user inputs and purposes of those inputs are:

1. Average carbon intensity of electricity by Azone (azone_electricity_carbon_intensity.csv) - The power generation mix (e.g. coal, natural gas, hydro, wind, solar) can vary substantially from place to place so users can specify different carbon intensities by Azone.

2. Average carbon intensities of transit fuels by transit vehicle type and Marea (marea_transit_ave_fuel_carbon_intensity.csv) - Average carbon intensity by transit vehicle type may be specified for each Marea. This can simplify the process of modeling emissions policies, particularly low carbon fuels policies by bypassing the need to specify fuel types and biofuel mixes. These inputs, if present and not 'NA', supercede other transit inputs.

3. Biofuels proportions of transit fuels by Marea (marea_transit_biofuel_mix.csv) - Transit agencies in different metropolitan areas may have substantially different approaches to using biofuels (e.g. blending biodiesel with diesel). This enables those differences to be accounted for.

4. Transit fuels proportions by transit vehicle type and Marea (marea_transit_fuel.csv) - Transit agencies in different metropolitan areas may use different mixes of fuels for their vehicles (e.g. diesel powered buses vs. CNG powered buses). This enables those differences to be accounted for.

5. Transit powertrain proportions by transit vehicle type and Marea (marea_transit_powertrain_prop.csv) - Transit agencies in different metropolitan areas may have different mixes of vehicle powertrains (e.g. ICEV buses vs. BEV buses). This enables those differences to be accounted for.

6. Average carbon intensities of fuels by vehicle category for the model region (region_ave_fuel_carbon_intensity.csv) - These inputs can be used to simplify emissions inputs calculations by mode (and for transit, vehicle type as well). This can greatly simplify the process of modeling emissions policies such as low-carbon fuel policies. If values are provided for one or more categories, those values will supercede any values that would be calculated from fuel types. If 'NA' values are provided, the model will use fuel-based calculations of carbon intensity.

7. Car service vehicle powertrain proportions by vehicle type for the model region (region_carsvc_powertrain_prop.csv) - These inputs enable users to easily specify different powertrain scenarios for car service vehicles (e.g. what if car services of autonomous electric vehicles are deployed). If values are provided, they supercede the default values.

8. Commercial service vehicle powertrain proportions by vehicle type (region_comsvc_powertrain_prop.csv) - These inputs enable users to easily specify different powertrain scenarios for commercial service vehicles (e.g. what if commercial services use a high proportion of electric vehicles). If values are provided, they supercede the default values.

9. Heavy duty truck powertrain proportions (region_hvytrk_powertrain_prop.csv) - These inputs enable users to easily specify different powertrain scenarios for heavy trucks (e.g. what would the emissions be if the heavy truck fleet transitioned from ICEV to HEV powertrains). If values are provided, they supercede the default values.

Note that there is no ability for the user to specify different inputs for household vehicle powertrains. That is the case because household powertrain proportions are vehicle model year proportions and not fleetwide proportions. The reason for the difference is that the models of household vehicle ownership take into account vehicle age in order to capture the relationship between household income and vehicle age which can have important implications for travel decisions and emissions consequences. This is not the case for other modes where vehicle ownership is not modeled and income is not a consideration. Because the process of producing vehicle model year datasets is complex, the VE approach is to shield users from this task. Likewise there is no ability for the user to specify different vehicle powertrain characteristics (e.g. fuel economy, battery range) for any of the modes and vehicle types. Instead, several VEPowertrainsAndFuels packages are made available to describe scenarios for powertrain characteristics and model year powertrain proportions. For example, one package can represent business-as-usual assumptions and another can represent zero-emissions-vehicle (ZEV) rule assumptions. If the user wishes to tackle the job of developing a custom scenario, they can modify the relevant input files included in the 'inst/extdata' directory of the source package and build the package. The documentation for these input files is included in the directory.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

If one or more of the powertrain or fuel proportions datasets are present, the module evaluates each of the proportions datasets to make sure that totals for a vehicle type add up to 1. If any total diverges by more than 1%, then the module returns an error message. If any total is not exactly 1 but is off by 1% or less, then the module adjusts the proportions to exactly equal 1 and returns a warning message which the framework writes to the log file for the model run.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_electricity_carbon_intensity.csv
This input file is OPTIONAL.

|NAME          |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                        |
|:-------------|:--------|:-----|:--------|:-----------|:--------|:----------------------------------------------------------------------------------|
|Geo           |         |      |         |Azones      |         |Must contain a record for each Azone and model run year.                           |
|Year          |         |      |         |            |         |Must contain a record for each Azone and model run year.                           |
|ElectricityCI |compound |GM/MJ |NA, < 0  |            |         |Carbon intensity of electricity at point of consumption (grams CO2e per megajoule) |
### marea_transit_ave_fuel_carbon_intensity.csv
This input file is OPTIONAL.

|NAME              |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                               |
|:-----------------|:--------|:-----|:--------|:-----------|:--------|:-----------------------------------------------------------------------------------------|
|Geo               |         |      |         |Mareas      |         |Must contain a record for each Marea and model run year.                                  |
|Year              |         |      |         |            |         |Must contain a record for each Marea and model run year.                                  |
|TransitVanFuelCI  |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuel used by transit vans (grams CO2e per megajoule)          |
|TransitBusFuelCI  |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuel used by transit buses (grams CO2e per megajoule)         |
|TransitRailFuelCI |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuel used by transit rail vehicles (grams CO2e per megajoule) |
### marea_transit_biofuel_mix.csv
This input file is OPTIONAL.

|   |NAME                       |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                         |
|:--|:--------------------------|:------|:----------|:------------|:-----------|:--------|:-----------------------------------------------------------------------------------|
|1  |Geo                        |       |           |             |Mareas      |         |Must contain a record for each Marea and model run year.                            |
|11 |Year                       |       |           |             |            |         |Must contain a record for each Marea and model run year.                            |
|5  |TransitEthanolPropGasoline |double |proportion |NA, < 0, > 1 |            |         |Ethanol proportion of gasoline used by transit vehicles                             |
|6  |TransitBiodieselPropDiesel |double |proportion |NA, < 0, > 1 |            |         |Biodiesel proportion of diesel used by transit vehicles                             |
|7  |TransitRngPropCng          |double |proportion |NA, < 0, > 1 |            |         |Renewable natural gas proportion of compressed natural gas used by transit vehicles |
### marea_transit_fuel.csv
This input file is OPTIONAL.

|   |NAME             |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                     |
|:--|:----------------|:------|:----------|:--------|:-----------|:--------|:-------------------------------------------------------------------------------|
|1  |Geo              |       |           |         |Mareas      |         |Must contain a record for each Marea and model run year.                        |
|16 |Year             |       |           |         |            |         |Must contain a record for each Marea and model run year.                        |
|8  |VanPropDiesel    |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit van travel powered by diesel                 |
|9  |VanPropGasoline  |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit van travel powered by gasoline               |
|10 |VanPropCng       |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit van travel powered by compressed natural gas |
|11 |BusPropDiesel    |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit bus travel powered by diesel                 |
|12 |BusPropGasoline  |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit bus travel powered by gasoline               |
|13 |BusPropCng       |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit bus travel powered by compressed natural gas |
|14 |RailPropDiesel   |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit rail travel powered by diesel                |
|15 |RailPropGasoline |double |proportion |< 0, > 1 |            |         |Proportion of non-electric transit rail travel powered by gasoline              |
### marea_transit_powertrain_prop.csv
This input file is OPTIONAL.

|   |NAME         |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                    |
|:--|:------------|:------|:----------|:--------|:-----------|:--------|:------------------------------------------------------------------------------|
|1  |Geo          |       |           |         |Mareas      |         |Must contain a record for each Marea and model run year.                       |
|11 |Year         |       |           |         |            |         |Must contain a record for each Marea and model run year.                       |
|16 |VanPropIcev  |double |proportion |< 0, > 1 |            |         |Proportion of transit van travel using internal combustion engine powertrains  |
|17 |VanPropHev   |double |proportion |< 0, > 1 |            |         |Proportion of transit van travel using hybrid electric powertrains             |
|18 |VanPropBev   |double |proportion |< 0, > 1 |            |         |Proportion of transit van travel using battery electric powertrains            |
|19 |BusPropIcev  |double |proportion |< 0, > 1 |            |         |Proportion of transit bus travel using internal combustion engine powertrains  |
|20 |BusPropHev   |double |proportion |< 0, > 1 |            |         |Proportion of transit bus travel using hybrid electric powertrains             |
|21 |BusPropBev   |double |proportion |< 0, > 1 |            |         |Proportion of transit bus travel using battery electric powertrains            |
|22 |RailPropIcev |double |proportion |< 0, > 1 |            |         |Proportion of transit rail travel using internal combustion engine powertrains |
|23 |RailPropHev  |double |proportion |< 0, > 1 |            |         |Proportion of transit rail travel using hybrid electric powertrains            |
|24 |RailPropEv   |double |proportion |< 0, > 1 |            |         |Proportion of transit rail travel using electric powertrains                   |
### region_ave_fuel_carbon_intensity.csv
This input file is OPTIONAL.

|   |NAME              |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                      |
|:--|:-----------------|:--------|:-----|:--------|:-----------|:--------|:------------------------------------------------------------------------------------------------|
|1  |Year              |         |      |         |            |         |Must contain a record for each model run year                                                    |
|25 |HhFuelCI          |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by household vehicles (grams CO2e per megajoule)          |
|26 |CarSvcFuelCI      |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by car service vehicles (grams CO2e per megajoule)        |
|27 |ComSvcFuelCI      |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by commercial service vehicles (grams CO2e per megajoule) |
|28 |HvyTrkFuelCI      |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)                |
|29 |TransitVanFuelCI  |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by transit vans (grams CO2e per megajoule)                |
|30 |TransitBusFuelCI  |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by transit buses (grams CO2e per megajoule)               |
|31 |TransitRailFuelCI |compound |GM/MJ |< 0      |            |         |Average carbon intensity of fuels used by transit rail vehicles (grams CO2e per megajoule)       |
### region_carsvc_powertrain_prop.csv
This input file is OPTIONAL.

|   |NAME                |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                    |
|:--|:-------------------|:------|:----------|:------------|:-----------|:--------|:----------------------------------------------------------------------------------------------|
|1  |Year                |       |           |             |            |         |Must contain a record for each model run year                                                  |
|32 |CarSvcAutoPropIcev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of car service automobile travel powered by internal combustion engine powertrains  |
|33 |CarSvcAutoPropHev   |double |proportion |NA, < 0, > 1 |            |         |Proportion of car service automobile travel powered by hybrid electric powertrains             |
|34 |CarSvcAutoPropBev   |double |proportion |NA, < 0, > 1 |            |         |Proportion of car service automobile travel powered by battery electric powertrains            |
|35 |CarSvcLtTrkPropIcev |double |proportion |NA, < 0, > 1 |            |         |Proportion of car service light truck travel powered by internal combustion engine powertrains |
|36 |CarSvcLtTrkPropHev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of car service light truck travel powered by hybrid electric powertrains            |
|37 |CarSvcLtTrkPropBev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of car service light truck travel powered by battery electric powertrains           |
### region_comsvc_powertrain_prop.csv
This input file is OPTIONAL.

|   |NAME                |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                           |
|:--|:-------------------|:------|:----------|:------------|:-----------|:--------|:-----------------------------------------------------------------------------------------------------|
|1  |Year                |       |           |             |            |         |Must contain a record for each model run year                                                         |
|38 |ComSvcAutoPropIcev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of commercial service automobile travel powered by internal combustion engine powertrains  |
|39 |ComSvcAutoPropHev   |double |proportion |NA, < 0, > 1 |            |         |Proportion of commercial service automobile travel powered by hybrid electric powertrains             |
|40 |ComSvcAutoPropBev   |double |proportion |NA, < 0, > 1 |            |         |Proportion of commercial service automobile travel powered by battery electric powertrains            |
|41 |ComSvcLtTrkPropIcev |double |proportion |NA, < 0, > 1 |            |         |Proportion of commercial service light truck travel powered by internal combustion engine powertrains |
|42 |ComSvcLtTrkPropHev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of commercial service light truck travel powered by hybrid electric powertrains            |
|43 |ComSvcLtTrkPropBev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of commercial service light truck travel powered by battery electric powertrains           |
### region_hvytrk_powertrain_prop.csv
This input file is OPTIONAL.

|   |NAME           |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                        |
|:--|:--------------|:------|:----------|:------------|:-----------|:--------|:----------------------------------------------------------------------------------|
|1  |Year           |       |           |             |            |         |Must contain a record for each model run year                                      |
|44 |HvyTrkPropIcev |double |proportion |NA, < 0, > 1 |            |         |Proportion of heavy truck travel powered by internal combustion engine powertrains |
|45 |HvyTrkPropHev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of heavy truck travel powered by hybrid electric powertrains            |
|46 |HvyTrkPropBev  |double |proportion |NA, < 0, > 1 |            |         |Proportion of heavy truck travel powered by battery electric powertrains           |

## Datasets Used by the Module
This module uses no datasets that are in the datastore.

## Datasets Produced by the Module
This module produces no datasets to store in the datastore.
