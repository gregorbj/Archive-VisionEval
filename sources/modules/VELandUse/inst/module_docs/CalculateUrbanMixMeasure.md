
# CalculateUrbanMixMeasure Module
### November 6, 2018

This module calculates an urban mixed-use measure based on the 2001 National Household Travel Survey measure of the tract level urban/rural indicator. This measure developed by Claritas uses the density of the tract and surrounding tracts to identify the urban/rural context of the tract. The categories include urban, suburban, second city, town and rural. Mapping of example metropolitan areas shows that places shown as urban correspond to central city and inner neighborhoods characterized by mixed use, higher levels of urban accessibility, and higher levels of walk/bike/transit accessibility.

## Model Parameter Estimation

A binary logit model is used to calculate the probability that a household is located in an urban mixed-use neighborhood as a function of the population density of the Bzone that household resides in and the housing type of the household.

This model is estimated using a household dataset prepared from 2001 National Household Travel Survey public use datasets by the VE2001NHTS package. The HhData_df data frame is loaded from that package and used to estimate the model. Following are the summary statistics for the estimated model:

```

Call:
glm(formula = makeFormula(StartTerms_), family = binomial, data = EstData_df)

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-2.7300  -0.2690  -0.2233  -0.1863   2.8505  

Coefficients:
                  Estimate Std. Error z value Pr(>|z|)    
(Intercept)     -3.865e+00  4.508e-02 -85.729  < 2e-16 ***
LocalPopDensity  2.522e-04  2.753e-06  91.618  < 2e-16 ***
IsSF            -1.929e-01  4.074e-02  -4.734  2.2e-06 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 41217  on 60499  degrees of freedom
Residual deviance: 23154  on 60497  degrees of freedom
AIC: 23160

Number of Fisher Scoring iterations: 6

```

The results of applying the binomial logit model are optionally constrained to match a target proportion that the user may input for the Bzone. This is done by successively adjusting the intercept of the model using a binary search algorithm.

## How the Module Works

For each household in each Bzone, the binomial logit model predicts the probability that the household resides in an urban mixed-use neighborhood. Random sampling using the probability determines whether the household is identified as residing in an urban mixed-use neighborhood. If a target proportion for the Bzone has been supplied by the user, the model is run repeatedly for households in the Bzone using a binary search algorithm to adjust the model intercept so that the modeled proportion is equal to the target.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_urban-mixed-use_prop.csv
|NAME       |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                         |
|:----------|:------|:----------|:--------|:-----------|:--------|:---------------------------------------------------------------------------------------------------|
|Geo        |       |           |         |Bzones      |         |Must contain a record for each Bzone and model run year.                                            |
|Year       |       |           |         |            |         |Must contain a record for each Bzone and model run year.                                            |
|MixUseProp |double |proportion |< 0, > 1 |            |         |Target for proportion of households located in mixed-use neighborhoods in zone (or NA if no target) |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME       |TABLE     |GROUP |TYPE       |UNITS      |PROHIBIT |ISELEMENTOF |
|:----------|:---------|:-----|:----------|:----------|:--------|:-----------|
|Bzone      |Bzone     |Year  |character  |ID         |         |            |
|NumHh      |Bzone     |Year  |households |HH         |NA, < 0  |            |
|UrbanPop   |Bzone     |Year  |people     |PRSN       |NA, <= 0 |            |
|TownPop    |Bzone     |Year  |people     |PRSN       |NA, <= 0 |            |
|RuralPop   |Bzone     |Year  |people     |PRSN       |NA, <= 0 |            |
|UrbanArea  |Bzone     |Year  |area       |SQMI       |NA, < 0  |            |
|TownArea   |Bzone     |Year  |area       |SQMI       |NA, < 0  |            |
|RuralArea  |Bzone     |Year  |area       |SQMI       |NA, < 0  |            |
|MixUseProp |Bzone     |Year  |double     |proportion |< 0, > 1 |            |
|Bzone      |Household |Year  |character  |ID         |         |            |
|HhId       |Household |Year  |character  |ID         |         |            |
|HouseType  |Household |Year  |character  |category   |         |SF, MF, GQ  |

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

|NAME            |TABLE     |GROUP |TYPE    |UNITS  |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                             |
|:---------------|:---------|:-----|:-------|:------|:--------|:-----------|:---------------------------------------------------------------------------------------|
|IsUrbanMixNbrhd |Household |Year  |integer |binary |NA       |0, 1        |Flag identifying whether household is (1) or is not (0) in urban mixed-use neighborhood |
