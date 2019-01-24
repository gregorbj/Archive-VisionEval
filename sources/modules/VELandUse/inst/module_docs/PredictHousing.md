
# PredictHousing Module
### November 6, 2018

This module assigns a housing type, either single-family (SF) or multifamily (MF) to *regular* households based on the respective supplies of SF and MF dwelling units in the housing market to which the household is assigned (i.e. the Azone the household is assigned to) and on household characteristics. It then assigns each household to a Bzone based on the household's housing type and income quartile as well as the supply of housing by type and Bzone (an input) and the distribution of households by income quartile for each Bzone (an input). The module assigns non-institutional group quarters *households* to Bzones based on the supply of group quarters units by Bzone.

## Model Parameter Estimation

A binomial logit model is used to assign housing types to households. The model is estimated using a Census Public Use Microsample (PUMS) dataset (Hh_df) that is prepared by the *CreateEstimationDatasets.R* script in the *VESimHouseholds* package. For more information on the preparation of the *Hh_df* dataset and how to substitute regional data for the default package data, refer to the documentation in the *CreateEstimationDatasets.R* script. The binomial logit model predicts the likelihood that a household will reside in a single-family dwelling as a function of the age group of the head of the household, the ratio of the natural log of the household income to the natural log of the mean household income (log income ratio), the household size, and the interaction of the log income ratio and household size. The age group of the head of household is the oldest age group in the household. The summary statistics for this model are as follows:

```

Call:
glm(formula = makeFormula(StartTerms_), family = binomial, data = EstData_df)

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-4.0393   0.3028   0.4939   0.6561   2.9869  

Coefficients:
                    Estimate Std. Error z value Pr(>|z|)    
(Intercept)         -2.63198    0.21309 -12.352  < 2e-16 ***
HeadAge20to29        0.62155    0.16120   3.856 0.000115 ***
HeadAge30to54        1.99662    0.16002  12.478  < 2e-16 ***
HeadAge55to64        2.82242    0.16241  17.378  < 2e-16 ***
HeadAge65Plus        2.69254    0.16087  16.738  < 2e-16 ***
RelLogIncome         0.97456    0.14899   6.541 6.11e-11 ***
HhSize              -0.41466    0.07295  -5.684 1.31e-08 ***
RelLogIncome:HhSize  0.85572    0.07320  11.690  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 66941  on 66685  degrees of freedom
Residual deviance: 57915  on 66678  degrees of freedom
AIC: 57931

Number of Fisher Scoring iterations: 5

```

The results of applying the binomial logit model are constrained to match the housing *choice* proportions with the dwelling unit proportions by successively adjusting the intercept of the model using a binary search algorithm.

## How the Module Works

The module carries out the following series of calculations to assign a housing type (SF or MF) to each *regular* household and to assign each household to a Bzone location.

1) The proportions of SF and MF dwelling units in the Azone are calculated.

2) The binomial logit is applied to each household in the Azone to determine the household's housing type. The model is applied multiple times using a binary search algorithm to successively adjust the model intercept until the housing type *choice* proportions equal the housing unit proportions in the Azone.

3) The income quartile of each household in the Azone is calculated and a tabulation of households by income quartile and housing type is made.

4) A matrix of the number of housing units by Bzone and housing type is created from the user inputs (e.g. resulting from a land use model or other allocation process). Because the number of housing units may not equal the number of households, the number of units by type and Bzone are adjusted so that the total number by type equals the number of households by housing type.

5) A matrix of the proportions of households by income quartile and Bzone is created from the user inputs (e.g. resulting from Census tabulation with adjustments as deemed appropriate) and the tabulation of housing units by Bzone.

6) An iterative proportional fitting (IPF) process is used to balance the number of housing units over 3 dimensions: Bzone, unit type, and income quartile. Two matrixes are used as margin control totals for the balancing process. The first is the matrix of demand by housing type and income quartile (step #3). The second is a matrix of units by Bzone and housing type (step #4). The seed matrix for the IPF uses the matrix of household proportions by Bzone and income quartile. The IPF is constrained to produce whole numbers.

7) After the number of housing units is allocated to each Bzone, housing type, and income quartile, households are allocated to Bzones to fill those units. This is done by iterating through each housing type and income quartile combination and doing the following: Extracting a vector of units by Bzone for the type and quartile combination;  Using the vector as replication weights to replicate the Bzone names; Randomizing the Bzone name vector; Assigning the randomized Bzone name vector to households matching the type and quartile combination.

Non-institutionalized group-quarters *households* are assigned randomly to Bzones based on the number of group-quarters *housing units* in each Bzone.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### bzone_dwelling_units.csv
|NAME |TYPE    |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                         |
|:----|:-------|:-----|:--------|:-----------|:--------|:-------------------------------------------------------------------|
|Geo  |        |      |         |Bzones      |         |Must contain a record for each Bzone and model run year.            |
|Year |        |      |         |            |         |Must contain a record for each Bzone and model run year.            |
|SFDU |integer |DU    |NA, < 0  |            |         |Number of single family dwelling units (PUMS codes 01 - 03) in zone |
|MFDU |integer |DU    |NA, < 0  |            |         |Number of multi-family dwelling units (PUMS codes 04 - 09) in zone  |
|GQDU |integer |DU    |NA, < 0  |            |         |Number of qroup quarters population accommodations in zone          |
### bzone_hh_inc_qrtl_prop.csv
|   |NAME        |TYPE   |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                   |
|:--|:-----------|:------|:-----|:--------|:-----------|:--------|:---------------------------------------------------------------------------------------------|
|1  |Geo         |       |      |         |Bzones      |         |Must contain a record for each Bzone and model run year.                                      |
|11 |Year        |       |      |         |            |         |Must contain a record for each Bzone and model run year.                                      |
|4  |HhPropIncQ1 |double |NA    |NA, < 0  |            |         |Proportion of Bzone households (non-group quarters) in 1st quartile of Azone household income |
|5  |HhPropIncQ2 |double |NA    |NA, < 0  |            |         |Proportion of Bzone households (non-group quarters) in 2nd quartile of Azone household income |
|6  |HhPropIncQ3 |double |NA    |NA, < 0  |            |         |Proportion of Bzone households (non-group quarters) in 3rd quartile of Azone household income |
|7  |HhPropIncQ4 |double |NA    |NA, < 0  |            |         |Proportion of Bzone households (non-group quarters) in 4th quartile of Azone household income |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME        |TABLE     |GROUP |TYPE      |UNITS    |PROHIBIT |ISELEMENTOF |
|:-----------|:---------|:-----|:---------|:--------|:--------|:-----------|
|Azone       |Azone     |Year  |character |ID       |         |            |
|Azone       |Bzone     |Year  |character |ID       |         |            |
|Bzone       |Bzone     |Year  |character |ID       |         |            |
|HhPropIncQ1 |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|HhPropIncQ2 |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|HhPropIncQ3 |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|HhPropIncQ4 |Bzone     |Year  |double    |NA       |NA, < 0  |            |
|SFDU        |Bzone     |Year  |integer   |DU       |NA, < 0  |            |
|MFDU        |Bzone     |Year  |integer   |DU       |NA, < 0  |            |
|GQDU        |Bzone     |Year  |integer   |DU       |NA, < 0  |            |
|Azone       |Household |Year  |character |ID       |         |            |
|HhId        |Household |Year  |character |ID       |         |            |
|Income      |Household |Year  |currency  |USD.2010 |NA, < 0  |            |
|HhSize      |Household |Year  |people    |PRSN     |NA, <= 0 |            |
|Workers     |Household |Year  |people    |PRSN     |NA, <= 0 |            |
|Age15to19   |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age20to29   |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age30to54   |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age55to64   |Household |Year  |people    |PRSN     |NA, < 0  |            |
|Age65Plus   |Household |Year  |people    |PRSN     |NA, < 0  |            |
|HhType      |Household |Year  |character |category |         |            |

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

|NAME      |TABLE     |GROUP |TYPE       |UNITS    |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                      |
|:---------|:---------|:-----|:----------|:--------|:--------|:-----------|:----------------------------------------------------------------------------------------------------------------|
|HouseType |Household |Year  |character  |category |         |SF, MF, GQ  |Type of dwelling unit in which the household resides (SF = single family, MF = multi-family, GQ = group quarters |
|Bzone     |Household |Year  |character  |ID       |         |            |ID of Bzone in which household resides                                                                           |
|SF        |Bzone     |Year  |integer    |DU       |NA, < 0  |            |Number of households living in single family dwelling units in zone                                              |
|MF        |Bzone     |Year  |integer    |DU       |NA, < 0  |            |Number of households living in multi-family dwelling units in zone                                               |
|GQ        |Bzone     |Year  |integer    |DU       |NA, < 0  |            |Number of persons living in group quarters in zone                                                               |
|Pop       |Bzone     |Year  |people     |PRSN     |NA, < 0  |            |Population residing in zone                                                                                      |
|NumHh     |Bzone     |Year  |households |HH       |NA, < 0  |            |Number of households (non-group and group quarters) residing in zone                                             |
|NumWkr    |Bzone     |Year  |people     |PRSN     |NA, < 0  |            |Number of workers residing in zone                                                                               |
