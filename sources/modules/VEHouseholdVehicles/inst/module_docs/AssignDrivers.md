
# AssignDrivers Module
### September 6, 2018

This module assigns drivers by age group to each household as a function of the numbers of persons and workers by age group, the household income, land use characteristics, and public transit availability. Users may specify the relative driver licensing rate relative to the model estimation data year in order to account for observed or projected changes in licensing rates.

## Model Parameter Estimation

Binary logit models are estimated to predict the probability that a person has a drivers license. Two versions of the model are estimated, one for persons in a metropolitan (i.e. urbanized) area, and another for persons located in non-metropolitan areas. There are different versions because the estimation data have more information about transportation system and land use characteristics for households located in urbanized areas. In both versions, the probability that a person has a drivers license is a function of the age group of the person, whether the person is a worker, the number of persons in the household, the income and squared income of the household, whether the household lives in a single-family dwelling, and the population density of the Bzone where the person lives. In the metropolitan area model, the bus-equivalent transit revenue miles and whether the household resides in an urban mixed-use neighborhood are significant factors. Following are the summary statistics for the metropolitan model:

```

Call:
glm(formula = makeFormula(StartTerms_), family = binomial, data = EstData_df[TrainIdx, 
    ])

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-3.2950   0.1308   0.2094   0.3980   2.7169  

Coefficients:
                  Estimate Std. Error z value Pr(>|z|)    
(Intercept)     -1.806e+01  1.049e+02  -0.172    0.863    
Age15to19        1.716e+01  1.049e+02   0.164    0.870    
Age20to29        1.957e+01  1.049e+02   0.187    0.852    
Age30to54        1.989e+01  1.049e+02   0.190    0.850    
Age55to64        1.975e+01  1.049e+02   0.188    0.851    
Age65Plus        1.916e+01  1.049e+02   0.183    0.855    
Worker           1.279e+00  5.120e-02  24.976   <2e-16 ***
HhSize          -2.614e-01  1.662e-02 -15.732   <2e-16 ***
Income           4.476e-05  1.986e-06  22.544   <2e-16 ***
IncomeSq        -1.873e-10  1.183e-11 -15.834   <2e-16 ***
IsSF             4.313e-01  5.065e-02   8.517   <2e-16 ***
PopDensity      -3.992e-05  3.138e-06 -12.719   <2e-16 ***
IsUrbanMixNbrhd -6.543e-01  5.880e-02 -11.128   <2e-16 ***
TranRevMiPC     -8.024e-03  7.495e-04 -10.706   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 26801  on 31325  degrees of freedom
Residual deviance: 14984  on 31312  degrees of freedom
  (10236 observations deleted due to missingness)
AIC: 15012

Number of Fisher Scoring iterations: 16

```

Following are the summary statistics for the non-metropolitan model:

```

Call:
glm(formula = makeFormula(StartTerms_), family = binomial, data = EstData_df[TrainIdx, 
    ])

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-3.2906   0.1225   0.1774   0.3478   2.5946  

Coefficients:
              Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.946e+01  1.145e+02  -0.170    0.865    
Age15to19    1.852e+01  1.145e+02   0.162    0.871    
Age20to29    2.083e+01  1.145e+02   0.182    0.856    
Age30to54    2.101e+01  1.145e+02   0.184    0.854    
Age55to64    2.103e+01  1.145e+02   0.184    0.854    
Age65Plus    2.036e+01  1.145e+02   0.178    0.859    
Worker       1.620e+00  4.604e-02  35.183   <2e-16 ***
HhSize      -2.290e-01  1.460e-02 -15.690   <2e-16 ***
Income       4.386e-05  1.800e-06  24.362   <2e-16 ***
IncomeSq    -1.997e-10  1.134e-11 -17.601   <2e-16 ***
IsSF         4.398e-01  4.314e-02  10.196   <2e-16 ***
PopDensity  -6.243e-05  3.697e-06 -16.887   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 43448  on 57750  degrees of freedom
Residual deviance: 21811  on 57739  degrees of freedom
  (16595 observations deleted due to missingness)
AIC: 21835

Number of Fisher Scoring iterations: 17

```

The models are estimated using the *Hh_df* (household) and *Per_df* (person) datasets in the VE2001NHTS package. Information about these datasets and how they were developed from the 2001 National Household Travel Survey public use dataset is included in that package.

## How the Module Works

The module iterates through each age group excluding the 0-14 year age group and creates a temporary set of person records for households in the region. For each household there are as many person records as there are persons in the age group in the household. A worker status attribute is added to each record based on the number of workers in the age group in the household. For example, if a household has 2 persons and 1 worker in the 20-29 year age group, one of the records would have its worker status attribute equal to 1 and the other would have its worker status attribute equal to 0. The person records are also populated with the household characteristics used in the model. The binomial logit model is applied to the person records to determine the probability that each person is a driver. The driver status of each person is determined by random draws with the modeled probability determining the likelihood that the person is determined to be a driver. The resulting number of drivers in the age group is then tabulated by household.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### region_hh_driver_adjust_prop.csv
This input file is OPTIONAL.

|NAME             |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                    |
|:----------------|:------|:----------|:--------|:-----------|:--------|:----------------------------------------------------------------------------------------------|
|Year             |       |           |         |            |         |Must contain a record for each model run year                                                  |
|Drv15to19AdjProp |double |proportion |NA, < 0  |            |> 1.5    |Target proportion of unadjusted model number of drivers 15 to 19 years old (1 = no adjustment) |
|Drv20to29AdjProp |double |proportion |NA, < 0  |            |> 1.5    |Target proportion of unadjusted model number of drivers 20 to 29 years old (1 = no adjustment) |
|Drv30to54AdjProp |double |proportion |NA, < 0  |            |> 1.5    |Target proportion of unadjusted model number of drivers 30 to 54 years old (1 = no adjustment) |
|Drv55to64AdjProp |double |proportion |NA, < 0  |            |> 1.5    |Target proportion of unadjusted model number of drivers 55 to 64 years old (1 = no adjustment) |
|Drv65PlusAdjProp |double |proportion |NA, < 0  |            |> 1.5    |Target proportion of unadjusted model number of drivers 65 or older (1 = no adjustment)        |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME             |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT |ISELEMENTOF        |
|:----------------|:---------|:-----|:---------|:----------|:--------|:------------------|
|Drv15to19AdjProp |Region    |Year  |double    |proportion |NA, < 0  |                   |
|Drv20to29AdjProp |Region    |Year  |double    |proportion |NA, < 0  |                   |
|Drv30to54AdjProp |Region    |Year  |double    |proportion |NA, < 0  |                   |
|Drv55to64AdjProp |Region    |Year  |double    |proportion |NA, < 0  |                   |
|Drv65PlusAdjProp |Region    |Year  |double    |proportion |NA, < 0  |                   |
|Marea            |Marea     |Year  |character |ID         |         |                   |
|TranRevMiPC      |Marea     |Year  |compound  |MI/PRSN/YR |NA, < 0  |                   |
|Bzone            |Bzone     |Year  |character |ID         |         |                   |
|D1B              |Bzone     |Year  |compound  |PRSN/SQMI  |NA, < 0  |                   |
|Marea            |Household |Year  |character |ID         |         |                   |
|Bzone            |Household |Year  |character |ID         |         |                   |
|HhId             |Household |Year  |character |ID         |         |                   |
|Age15to19        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age20to29        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age30to54        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age55to64        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age65Plus        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Wkr15to19        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Wkr20to29        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Wkr30to54        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Wkr55to64        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Wkr65Plus        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Income           |Household |Year  |currency  |USD.2001   |NA, < 0  |                   |
|HhSize           |Household |Year  |people    |PRSN       |NA, <= 0 |                   |
|HouseType        |Household |Year  |character |category   |         |SF, MF, GQ         |
|IsUrbanMixNbrhd  |Household |Year  |integer   |binary     |NA       |0, 1               |
|LocType          |Household |Year  |character |category   |NA       |Urban, Town, Rural |

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

|NAME          |TABLE     |GROUP |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                            |
|:-------------|:---------|:-----|:------|:-----|:--------|:-----------|:------------------------------------------------------|
|Drv15to19     |Household |Year  |people |PRSN  |NA, < 0  |            |Number of drivers 15 to 19 years old                   |
|Drv20to29     |Household |Year  |people |PRSN  |NA, < 0  |            |Number of drivers 20 to 29 years old                   |
|Drv30to54     |Household |Year  |people |PRSN  |NA, < 0  |            |Number of drivers 30 to 54 years old                   |
|Drv55to64     |Household |Year  |people |PRSN  |NA, < 0  |            |Number of drivers 55 to 64 years old                   |
|Drv65Plus     |Household |Year  |people |PRSN  |NA, < 0  |            |Number of drivers 65 or older                          |
|Drivers       |Household |Year  |people |PRSN  |NA, < 0  |            |Number of drivers in household                         |
|DrvAgePersons |Household |Year  |people |PRSN  |NA, < 0  |            |Number of people 15 year old or older in the household |
