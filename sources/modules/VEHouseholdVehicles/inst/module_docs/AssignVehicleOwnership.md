
# AssignVehicleOwnership Module
### November 23, 2018

This module determines the number of vehicles owned or leased by each household as a function of household characteristics, land use characteristics, and transportation system characteristics.

## Model Parameter Estimation

The vehicle ownership model is segmented for metropolitan and non-metropolitan households because additional information about transit supply and the presence of urban mixed-use neighborhoods is available for metropolitan households that is not available for non-metropolitan households. There are two models for each segment. A binary logit model is used to predict which households own no vehicles. An ordered logit model is used to predict how many vehicles a household owns if they own any vehicles. The number of vehicles a household may be assigned is 6.

The metropolitan model for determining whether a household owns no vehicles is documented below. As expected, the probability that a household is carless is greater for low income households (less than $20,000), households living in higher density and/or mixed-use neighborhoods, and households living in metropolitan areas having higher levels of transit service. The probability decreases as the number of drivers in the household increases, household income increases, and if the household lives in a single-family dwelling. The number of drivers has the greatest influence on car ownership. The number of workers increases the probability of no vehicle ownership, but since the model includes drivers, this coefficient probably reflects the effect of non-driving workers on vehicle ownership.

```

Call:
glm(formula = ZeroVeh ~ Workers + LowInc + LogIncome + IsSF + 
    Drivers + IsUrbanMixNbrhd + LogDensity + TranRevMiPC, family = binomial, 
    data = EstData_df)

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-2.7069  -0.2152  -0.0628  -0.0332   4.4914  

Coefficients:
                 Estimate Std. Error z value Pr(>|z|)    
(Intercept)      1.347976   0.766875   1.758   0.0788 .  
Workers          0.432869   0.061513   7.037 1.96e-12 ***
LowInc           0.759137   0.125686   6.040 1.54e-09 ***
LogIncome       -0.366476   0.066661  -5.498 3.85e-08 ***
IsSF            -0.682829   0.086989  -7.850 4.17e-15 ***
Drivers         -3.193416   0.090087 -35.448  < 2e-16 ***
IsUrbanMixNbrhd  0.839238   0.093167   9.008  < 2e-16 ***
LogDensity       0.239777   0.039492   6.072 1.27e-09 ***
TranRevMiPC      0.014992   0.001327  11.299  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 12200.1  on 19630  degrees of freedom
Residual deviance:  5159.1  on 19622  degrees of freedom
AIC: 5177.1

Number of Fisher Scoring iterations: 8

```

The non-metropolitan model for zero car ownership is shown below. The model terms are the same as for the metropolitan model with the exception of the urban mixed-use and transit supply variables. The signs of the variables are the same as for the metropolitan model and the values are of similar magnitude.

```

Call:
glm(formula = ZeroVeh ~ Workers + LowInc + LogIncome + IsSF + 
    Drivers + LogDensity, family = binomial, data = EstData_df)

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-2.7362  -0.1636  -0.0262  -0.0190   6.3244  

Coefficients:
            Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.52758    0.79801   8.180 2.84e-16 ***
Workers      0.32080    0.07781   4.123 3.74e-05 ***
LowInc       0.56568    0.13351   4.237 2.26e-05 ***
LogIncome   -0.65297    0.07470  -8.741  < 2e-16 ***
IsSF        -0.77947    0.08803  -8.854  < 2e-16 ***
Drivers     -4.11347    0.09972 -41.248  < 2e-16 ***
LogDensity   0.13658    0.02565   5.324 1.01e-07 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 10952  on 34081  degrees of freedom
Residual deviance:  4448  on 34075  degrees of freedom
AIC: 4462

Number of Fisher Scoring iterations: 9

```

The ordered logit model for the number of vehicles owned by metropolitan households that own at least one vehicle is shown below. Households are likely to own more vehicles if they live in a single-family dwelling, have higher incomes, have more workers, and have more drivers. Households are likely to own fewer vehicles if all household members are elderly, they live in a higher density and/or urban mixed-use neighborhood, they live in a metropolitan area with a higher level of transit service, and if more persons are in the household. The latter result is at surprising at first glance, but since the model also includes the number of drivers and number of workers, the household size coefficient is probably showing the effect of non-drivers non-workers in the household.

```
formula: 
VehOrd ~ Workers + LogIncome + Drivers + HhSize + OnlyElderly + IsSF + IsUrbanMixNbrhd + LogDensity + TranRevMiPC
data:    EstData_df

 link  threshold   nobs  logLik    AIC      niter max.grad cond.H 
 logit equidistant 17794 -14662.10 29346.20 7(0)  4.54e-11 9.7e+05

Coefficients:
                  Estimate Std. Error z value Pr(>|z|)    
Workers          0.2402913  0.0263983   9.103  < 2e-16 ***
LogIncome        0.5090310  0.0257440  19.773  < 2e-16 ***
Drivers          2.3220340  0.0376671  61.646  < 2e-16 ***
HhSize          -0.0635976  0.0156797  -4.056 4.99e-05 ***
OnlyElderly     -0.4343603  0.0575421  -7.549 4.40e-14 ***
IsSF             0.7784887  0.0422429  18.429  < 2e-16 ***
IsUrbanMixNbrhd -0.2344384  0.0482043  -4.863 1.15e-06 ***
LogDensity      -0.2022960  0.0127091 -15.917  < 2e-16 ***
TranRevMiPC     -0.0031226  0.0005294  -5.899 3.66e-09 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Threshold coefficients:
            Estimate Std. Error z value
threshold.1  7.68088    0.29013   26.47
spacing      2.99870    0.02662  112.65
```

The ordered logit model for non-metropolitan household vehicle ownership is described below. The variables are the same as for the metropolitan model with the exception of the urban mixed-use neighborhood and transit variables. The signs of the coefficients are the same and the magnitudes are similar.

```
formula: 
VehOrd ~ Workers + LogIncome + Drivers + HhSize + OnlyElderly + IsSF + LogDensity
data:    EstData_df

 link  threshold   nobs  logLik    AIC      niter max.grad cond.H 
 logit equidistant 32796 -30632.66 61283.32 7(0)  1.78e-10 4.8e+04

Coefficients:
             Estimate Std. Error z value Pr(>|z|)    
Workers      0.291080   0.018607  15.643  < 2e-16 ***
LogIncome    0.513030   0.017744  28.913  < 2e-16 ***
Drivers      2.083690   0.026662  78.151  < 2e-16 ***
HhSize      -0.059411   0.011301  -5.257 1.46e-07 ***
OnlyElderly -0.352559   0.037467  -9.410  < 2e-16 ***
IsSF         0.710680   0.035003  20.303  < 2e-16 ***
LogDensity  -0.167458   0.006486 -25.818  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Threshold coefficients:
            Estimate Std. Error z value
threshold.1  7.81783    0.18654   41.91
spacing      2.68819    0.01687  159.37
```

## How the Module Works

For each household, the metropolitan or non-metropolitan binary logit model is run to predict the probability that the household owns no vehicles. A random number is drawn from a uniform distribution in the interval from 0 to 1 and if the result is less than the probability of zero-vehicle ownership, the household is assigned no vehicles. Households that have no drivers are also assigned 0 vehicles. The metropolitan or non-metropolitan ordered logit model is run to predict the number of vehicles owned by the household if they own any.


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

|NAME            |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT |ISELEMENTOF        |
|:---------------|:---------|:-----|:---------|:----------|:--------|:------------------|
|Marea           |Marea     |Year  |character |ID         |         |                   |
|TranRevMiPC     |Marea     |Year  |compound  |MI/PRSN/YR |NA, < 0  |                   |
|Marea           |Bzone     |Year  |character |ID         |         |                   |
|Bzone           |Bzone     |Year  |character |ID         |         |                   |
|D1B             |Bzone     |Year  |compound  |PRSN/SQMI  |NA, < 0  |                   |
|Bzone           |Household |Year  |character |ID         |         |                   |
|Workers         |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Drivers         |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Income          |Household |Year  |currency  |USD.2001   |NA, < 0  |                   |
|HouseType       |Household |Year  |character |category   |         |SF, MF, GQ         |
|HhSize          |Household |Year  |people    |PRSN       |NA, <= 0 |                   |
|Age65Plus       |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|IsUrbanMixNbrhd |Household |Year  |integer   |binary     |NA       |0, 1               |
|LocType         |Household |Year  |character |category   |NA       |Urban, Town, Rural |

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

|NAME     |TABLE     |GROUP |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                                                        |
|:--------|:---------|:-----|:--------|:-----|:--------|:-----------|:--------------------------------------------------------------------------------------------------------------------------------------------------|
|Vehicles |Household |Year  |vehicles |VEH   |NA, < 0  |            |Number of automobiles and light trucks owned or leased by the household including high level car service vehicles available to driving-age persons |
