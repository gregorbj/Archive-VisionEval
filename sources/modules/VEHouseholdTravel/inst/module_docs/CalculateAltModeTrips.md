
# CalculateAltModeTrips Module
### November 23, 2018

This module calculates household transit trips, walk trips, and bike trips. The models are sensitive to household DVMT so they are run after all household DVMT adjustments (e.g. to account for cost on household DVMT) are made.

## Model Parameter Estimation

Hurdle models are estimated for calculating the numbers of household transit, walk, and bike trips using the [pscl](https://cran.r-project.org/web/packages/pscl/vignettes/countreg.pdf) package. Separate models are calculated for metropolitan and non-metropolitan households to account for the additional variables available in metropolitan areas.

Following are the estimation statistics for the metropolitan and nonmetropolitan **walk** trip models.

**Metropolitan Walk Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-4.7361 -1.3363 -0.5990  0.5861 32.2112 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.586e+00  6.697e-03  684.75   <2e-16 ***
HhSize        3.170e-01  8.368e-04  378.83   <2e-16 ***
LogIncome     1.417e-01  6.558e-04  216.06   <2e-16 ***
LogDensity   -3.911e-03  3.343e-04  -11.70   <2e-16 ***
BusEqRevMiPC  1.631e-03  1.302e-05  125.28   <2e-16 ***
Urban         4.586e-02  6.120e-04   74.93   <2e-16 ***
LogDvmt      -2.183e-01  7.161e-04 -304.88   <2e-16 ***
Age0to14     -3.255e-01  9.078e-04 -358.56   <2e-16 ***
Age15to19    -8.739e-02  1.099e-03  -79.54   <2e-16 ***
Age20to29     4.695e-02  9.317e-04   50.40   <2e-16 ***
Age30to54     2.095e-02  7.154e-04   29.28   <2e-16 ***
Age65Plus    -3.507e-02  8.485e-04  -41.33   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2804004  0.2614307  -8.723  < 2e-16 ***
HhSize        0.4592563  0.0385266  11.920  < 2e-16 ***
LogIncome     0.2794878  0.0259983  10.750  < 2e-16 ***
LogDensity    0.0233392  0.0137783   1.694 0.090283 .  
BusEqRevMiPC -0.0038133  0.0005493  -6.942 3.88e-12 ***
Urban         0.0644162  0.0260834   2.470 0.013526 *  
LogDvmt      -0.2550664  0.0312897  -8.152 3.59e-16 ***
Age0to14     -0.3714067  0.0422563  -8.789  < 2e-16 ***
Age15to19    -0.1961174  0.0555801  -3.529 0.000418 ***
Age20to29     0.0930616  0.0428987   2.169 0.030057 *  
Age30to54     0.0649268  0.0309902   2.095 0.036164 *  
Age65Plus    -0.0373426  0.0344153  -1.085 0.277896    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 18 
Log-likelihood: -2.475e+06 on 24 Df
```

**Nonmetropolitan Walk Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.9710 -1.2633 -0.5842  0.5358 34.5840 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1531760  0.0044801 1373.44   <2e-16 ***
HhSize       0.3303842  0.0006746  489.78   <2e-16 ***
LogIncome   -0.0237051  0.0005588  -42.42   <2e-16 ***
LogDensity  -0.0377373  0.0001842 -204.84   <2e-16 ***
LogDvmt     -0.0416332  0.0010316  -40.36   <2e-16 ***
Age0to14    -0.3606088  0.0007033 -512.75   <2e-16 ***
Age15to19   -0.1465602  0.0008401 -174.45   <2e-16 ***
Age20to29    0.0241653  0.0006777   35.66   <2e-16 ***
Age30to54   -0.0190128  0.0005360  -35.47   <2e-16 ***
Age65Plus   -0.0301809  0.0006138  -49.17   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498030   0.159756  -3.117  0.00182 ** 
HhSize       0.144987   0.029142   4.975 6.52e-07 ***
LogIncome    0.057865   0.019814   2.920  0.00350 ** 
LogDensity  -0.034470   0.006878  -5.012 5.39e-07 ***
LogDvmt      0.118076   0.036047   3.276  0.00105 ** 
Age0to14    -0.190453   0.030041  -6.340 2.30e-10 ***
Age15to19    0.021283   0.038479   0.553  0.58019    
Age20to29    0.092794   0.028744   3.228  0.00125 ** 
Age30to54    0.064043   0.021310   3.005  0.00265 ** 
Age65Plus   -0.049868   0.023211  -2.148  0.03168 *  
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 16 
Log-likelihood: -4.195e+06 on 20 Df
```

Following are the estimation statistics for the metropolitan and nonmetropolitan **bike** trip models.

**Metropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-1.2354 -0.3524 -0.2790 -0.2282 34.1314 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.329e+00  2.474e-02  255.82   <2e-16 ***
HhSize        1.105e-01  4.271e-03   25.87   <2e-16 ***
LogIncome    -6.753e-02  2.903e-03  -23.26   <2e-16 ***
BusEqRevMiPC -2.238e-03  6.019e-05  -37.18   <2e-16 ***
LogDvmt      -1.696e-01  3.324e-03  -51.02   <2e-16 ***
Age0to14     -1.936e-01  4.480e-03  -43.21   <2e-16 ***
Age15to19    -1.355e-01  5.291e-03  -25.61   <2e-16 ***
Age20to29     7.888e-02  4.425e-03   17.82   <2e-16 ***
Age30to54     7.883e-02  3.618e-03   21.79   <2e-16 ***
Age65Plus     4.903e-02  4.318e-03   11.36   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7718109  0.3802624 -12.549  < 2e-16 ***
HhSize        0.1659078  0.0580380   2.859 0.004255 ** 
LogIncome     0.2006398  0.0431603   4.649 3.34e-06 ***
BusEqRevMiPC -0.0061602  0.0008649  -7.122 1.06e-12 ***
LogDvmt      -0.0400134  0.0494942  -0.808 0.418833    
Age0to14      0.0452167  0.0599464   0.754 0.450678    
Age15to19     0.2071644  0.0717196   2.889 0.003870 ** 
Age20to29     0.2301482  0.0614262   3.747 0.000179 ***
Age30to54     0.1713036  0.0483194   3.545 0.000392 ***
Age65Plus    -0.0756494  0.0613728  -1.233 0.217717    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 32 
Log-likelihood: -1.193e+05 on 20 Df
```

**Nonmetropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.4412 -0.3567 -0.2792 -0.2273 57.2824 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.889407   0.017452  337.46   <2e-16 ***
HhSize       0.242333   0.002575   94.11   <2e-16 ***
LogIncome    0.033419   0.002126   15.72   <2e-16 ***
LogDvmt     -0.386453   0.003246 -119.06   <2e-16 ***
Age0to14    -0.289363   0.002742 -105.53   <2e-16 ***
Age15to19   -0.092280   0.003160  -29.21   <2e-16 ***
Age20to29    0.095761   0.002578   37.14   <2e-16 ***
Age30to54    0.024594   0.002280   10.79   <2e-16 ***
Age65Plus   -0.033741   0.002863  -11.78   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62359    0.27759 -16.656  < 2e-16 ***
HhSize       0.21580    0.04551   4.742 2.12e-06 ***
LogIncome    0.19365    0.03287   5.891 3.83e-09 ***
LogDvmt     -0.12149    0.05753  -2.112  0.03471 *  
Age0to14    -0.05069    0.04528  -1.119  0.26296    
Age15to19    0.18239    0.05279   3.455  0.00055 ***
Age20to29    0.25781    0.04318   5.971 2.36e-09 ***
Age30to54    0.17484    0.03476   5.031 4.89e-07 ***
Age65Plus   -0.18269    0.04441  -4.114 3.89e-05 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 18 
Log-likelihood: -2.874e+05 on 18 Df
```

Following are the estimation statistics for the metropolitan and nonmetropolitan **transit** trip models.

**Metropolitan Transit Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-3.9005 -0.3421 -0.2262 -0.1478 34.7194 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.044e-02 577.671  < 2e-16 ***
HhSize        1.345e-02  6.685e-04  20.119  < 2e-16 ***
LogIncome     5.787e-02  1.000e-03  57.845  < 2e-16 ***
LogDensity    4.500e-02  5.879e-04  76.550  < 2e-16 ***
BusEqRevMiPC  1.887e-03  2.542e-05  74.246  < 2e-16 ***
LogDvmt      -9.556e-02  1.003e-03 -95.246  < 2e-16 ***
Urban         3.456e-02  1.076e-03  32.133  < 2e-16 ***
Age15to19    -1.256e-03  1.207e-03  -1.041    0.298    
Age20to29     6.572e-02  1.333e-03  49.316  < 2e-16 ***
Age30to54     4.871e-02  1.262e-03  38.610  < 2e-16 ***
Age65Plus     8.605e-03  1.662e-03   5.176 2.27e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1819960  0.4118346 -10.155  < 2e-16 ***
HhSize        0.5181754  0.0245840  21.078  < 2e-16 ***
LogIncome     0.3439422  0.0403518   8.524  < 2e-16 ***
LogDensity   -0.0393710  0.0214144  -1.839 0.065984 .  
BusEqRevMiPC  0.0097575  0.0008815  11.069  < 2e-16 ***
LogDvmt      -1.0634599  0.0415757 -25.579  < 2e-16 ***
Urban         0.0716295  0.0400015   1.791 0.073346 .  
Age15to19     0.3067591  0.0470208   6.524 6.85e-11 ***
Age20to29     0.1937585  0.0521147   3.718 0.000201 ***
Age30to54     0.3871856  0.0466671   8.297  < 2e-16 ***
Age65Plus    -0.5829331  0.0644628  -9.043  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 21 
Log-likelihood: -3.382e+05 on 22 Df
```

**Nonmetropolitan Transit Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-6.3335 -0.2401 -0.1567 -0.1048 45.2094 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7688133  0.0105623 640.844  < 2e-16 ***
HhSize       0.0531929  0.0018393  28.920  < 2e-16 ***
LogIncome    0.0588439  0.0012724  46.247  < 2e-16 ***
LogDensity  -0.0124325  0.0004657 -26.699  < 2e-16 ***
LogDvmt     -0.1351009  0.0019849 -68.064  < 2e-16 ***
Age0to14    -0.0083964  0.0018218  -4.609 4.05e-06 ***
Age15to19    0.0236117  0.0020681  11.417  < 2e-16 ***
Age20to29   -0.0323345  0.0021757 -14.862  < 2e-16 ***
Age30to54   -0.0274500  0.0017202 -15.957  < 2e-16 ***
Age65Plus   -0.0709712  0.0027659 -25.659  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44880    0.35063  -4.132 3.60e-05 ***
HhSize       0.48973    0.06451   7.592 3.15e-14 ***
LogIncome    0.23227    0.04345   5.346 8.98e-08 ***
LogDensity  -0.17546    0.01442 -12.168  < 2e-16 ***
LogDvmt     -1.27281    0.06923 -18.385  < 2e-16 ***
Age0to14     0.25506    0.06337   4.025 5.70e-05 ***
Age15to19    0.38531    0.07127   5.407 6.42e-08 ***
Age20to29    0.06975    0.07214   0.967    0.334    
Age30to54    0.53264    0.05692   9.357  < 2e-16 ***
Age65Plus   -0.60587    0.08593  -7.051 1.77e-12 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 21 
Log-likelihood: -2.818e+05 on 20 Df
```

## How the Module Works

This module is run after all household DVMT adjustments are made due to cost, travel demand management, and light-weight vehicle (e.g. bike, scooter) diversion, so that alternative mode travel reflects the result of those influences. The alternative mode trip models are run and the results are saved.


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
|Marea           |Household |Year  |character |ID         |         |                   |
|Bzone           |Household |Year  |character |ID         |         |                   |
|Age0to14        |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age15to19       |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age20to29       |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age30to54       |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age55to64       |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|Age65Plus       |Household |Year  |people    |PRSN       |NA, < 0  |                   |
|LocType         |Household |Year  |character |category   |NA       |Urban, Town, Rural |
|HhSize          |Household |Year  |people    |PRSN       |NA, <= 0 |                   |
|Income          |Household |Year  |currency  |USD.2001   |NA, < 0  |                   |
|Vehicles        |Household |Year  |vehicles  |VEH        |NA, < 0  |                   |
|IsUrbanMixNbrhd |Household |Year  |integer   |binary     |NA       |0, 1               |
|Dvmt            |Household |Year  |compound  |MI/DAY     |NA, < 0  |                   |

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

|NAME         |TABLE     |GROUP |TYPE     |UNITS   |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                          |
|:------------|:---------|:-----|:--------|:-------|:--------|:-----------|:--------------------------------------------------------------------|
|WalkTrips    |Household |Year  |compound |TRIP/YR |NA, < 0  |            |Average number of walk trips per year by household members           |
|BikeTrips    |Household |Year  |compound |TRIP/YR |NA, < 0  |            |Average number of bicycle trips per year by household members        |
|TransitTrips |Household |Year  |compound |TRIP/YR |NA, < 0  |            |Average number of public transit trips per year by household members |
