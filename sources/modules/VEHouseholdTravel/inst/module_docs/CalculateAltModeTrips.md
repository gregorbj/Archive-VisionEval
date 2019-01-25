
# CalculateAltModeTrips Module
### November 23, 2018

This module calculates household transit trips, walk trips, and bike trips. The models are sensitive to household DVMT so they are run after all household DVMT adjustments (e.g. to account for cost on household DVMT) are made.

## Model Parameter Estimation

Hurdle models are estimated for calculating the numbers of household transit, walk, and bike trips using the [pscl](https://cran.r-project.org/web/packages/pscl/vignettes/countreg.pdf) package. Separate models are calculated for metropolitan and non-metropolitan households to account for the additional variables available in metropolitan areas.

Following are the estimation statistics for the metropolitan and nonmetropolitan **walk** trip models.

**Metropolitan Walk Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-4.7367 -1.3363 -0.5986  0.5860 32.2104 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.585e+00  6.697e-03  684.66   <2e-16 ***
HhSize        3.170e-01  8.368e-04  378.81   <2e-16 ***
LogIncome     1.418e-01  6.560e-04  216.12   <2e-16 ***
LogDensity   -3.869e-03  3.343e-04  -11.57   <2e-16 ***
BusEqRevMiPC  1.630e-03  1.302e-05  125.24   <2e-16 ***
Urban         4.587e-02  6.120e-04   74.95   <2e-16 ***
LogDvmt      -2.185e-01  7.168e-04 -304.81   <2e-16 ***
Age0to14     -3.255e-01  9.078e-04 -358.59   <2e-16 ***
Age15to19    -8.739e-02  1.099e-03  -79.54   <2e-16 ***
Age20to29     4.688e-02  9.317e-04   50.32   <2e-16 ***
Age30to54     2.090e-02  7.154e-04   29.21   <2e-16 ***
Age65Plus    -3.497e-02  8.485e-04  -41.22   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2808539  0.2614330  -8.724  < 2e-16 ***
HhSize        0.4591285  0.0385284  11.917  < 2e-16 ***
LogIncome     0.2793840  0.0260069  10.743  < 2e-16 ***
LogDensity    0.0234677  0.0137759   1.704 0.088468 .  
BusEqRevMiPC -0.0038119  0.0005494  -6.939 3.96e-12 ***
Urban         0.0644799  0.0260829   2.472 0.013432 *  
LogDvmt      -0.2548614  0.0313175  -8.138 4.02e-16 ***
Age0to14     -0.3713936  0.0422588  -8.789  < 2e-16 ***
Age15to19    -0.1960898  0.0555811  -3.528 0.000419 ***
Age20to29     0.0929566  0.0428979   2.167 0.030241 *  
Age30to54     0.0648686  0.0309899   2.093 0.036330 *  
Age65Plus    -0.0371939  0.0344140  -1.081 0.279796    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 18 
Log-likelihood: -2.475e+06 on 24 Df
```

**Nonmetropolitan Walk Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.9715 -1.2631 -0.5842  0.5359 34.5806 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1534979  0.0044802 1373.49   <2e-16 ***
HhSize       0.3302864  0.0006748  489.43   <2e-16 ***
LogIncome   -0.0238715  0.0005583  -42.76   <2e-16 ***
LogDensity  -0.0377021  0.0001842 -204.72   <2e-16 ***
LogDvmt     -0.0412615  0.0010322  -39.98   <2e-16 ***
Age0to14    -0.3605440  0.0007033 -512.62   <2e-16 ***
Age15to19   -0.1465187  0.0008401 -174.40   <2e-16 ***
Age20to29    0.0241497  0.0006777   35.63   <2e-16 ***
Age30to54   -0.0190265  0.0005360  -35.49   <2e-16 ***
Age65Plus   -0.0301556  0.0006138  -49.13   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498975   0.159757  -3.123  0.00179 ** 
HhSize       0.145039   0.029153   4.975 6.52e-07 ***
LogIncome    0.058052   0.019800   2.932  0.00337 ** 
LogDensity  -0.034518   0.006875  -5.021 5.15e-07 ***
LogDvmt      0.117852   0.036078   3.267  0.00109 ** 
Age0to14    -0.190518   0.030043  -6.341 2.28e-10 ***
Age15to19    0.021231   0.038480   0.552  0.58113    
Age20to29    0.092786   0.028744   3.228  0.00125 ** 
Age30to54    0.064043   0.021310   3.005  0.00265 ** 
Age65Plus   -0.049879   0.023212  -2.149  0.03165 *  
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 16 
Log-likelihood: -4.195e+06 on 20 Df
```

Following are the estimation statistics for the metropolitan and nonmetropolitan **bike** trip models.

**Metropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-1.2354 -0.3524 -0.2790 -0.2282 34.1275 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.3288634  0.0247435  255.78   <2e-16 ***
HhSize        0.1105041  0.0042707   25.88   <2e-16 ***
LogIncome    -0.0673396  0.0029046  -23.18   <2e-16 ***
BusEqRevMiPC -0.0022409  0.0000602  -37.23   <2e-16 ***
LogDvmt      -0.1698886  0.0033274  -51.06   <2e-16 ***
Age0to14     -0.1937229  0.0044800  -43.24   <2e-16 ***
Age15to19    -0.1356508  0.0052912  -25.64   <2e-16 ***
Age20to29     0.0788369  0.0044253   17.82   <2e-16 ***
Age30to54     0.0788564  0.0036175   21.80   <2e-16 ***
Age65Plus     0.0491844  0.0043173   11.39   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.771690   0.380279 -12.548  < 2e-16 ***
HhSize        0.165883   0.058039   2.858 0.004261 ** 
LogIncome     0.200624   0.043176   4.647 3.37e-06 ***
BusEqRevMiPC -0.006160   0.000865  -7.121 1.07e-12 ***
LogDvmt      -0.039985   0.049547  -0.807 0.419668    
Age0to14      0.045224   0.059949   0.754 0.450626    
Age15to19     0.207172   0.071721   2.889 0.003870 ** 
Age20to29     0.230137   0.061426   3.747 0.000179 ***
Age30to54     0.171295   0.048319   3.545 0.000392 ***
Age65Plus    -0.075626   0.061371  -1.232 0.217847    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 39 
Log-likelihood: -1.193e+05 on 20 Df
```

**Nonmetropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.4412 -0.3567 -0.2792 -0.2273 57.2796 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.892971   0.017446  337.79   <2e-16 ***
HhSize       0.242485   0.002576   94.14   <2e-16 ***
LogIncome    0.033144   0.002124   15.60   <2e-16 ***
LogDvmt     -0.386672   0.003249 -119.00   <2e-16 ***
Age0to14    -0.289359   0.002742 -105.53   <2e-16 ***
Age15to19   -0.092253   0.003159  -29.20   <2e-16 ***
Age20to29    0.095920   0.002578   37.20   <2e-16 ***
Age30to54    0.024652   0.002280   10.81   <2e-16 ***
Age65Plus   -0.033779   0.002863  -11.80   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62257    0.27756 -16.654  < 2e-16 ***
HhSize       0.21591    0.04553   4.742 2.11e-06 ***
LogIncome    0.19361    0.03285   5.893 3.79e-09 ***
LogDvmt     -0.12169    0.05759  -2.113 0.034613 *  
Age0to14    -0.05073    0.04528  -1.120 0.262610    
Age15to19    0.18236    0.05279   3.455 0.000551 ***
Age20to29    0.25785    0.04318   5.972 2.35e-09 ***
Age30to54    0.17486    0.03476   5.031 4.88e-07 ***
Age65Plus   -0.18271    0.04441  -4.114 3.88e-05 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 18 
Log-likelihood: -2.874e+05 on 18 Df
```

Following are the estimation statistics for the metropolitan and nonmetropolitan **transit** trip models.

**Metropolitan Transit Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-3.8971 -0.3421 -0.2261 -0.1478 34.7556 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.044e-02 577.557  < 2e-16 ***
HhSize        1.345e-02  6.684e-04  20.129  < 2e-16 ***
LogIncome     5.803e-02  1.001e-03  57.978  < 2e-16 ***
LogDensity    4.498e-02  5.878e-04  76.515  < 2e-16 ***
BusEqRevMiPC  1.886e-03  2.542e-05  74.200  < 2e-16 ***
LogDvmt      -9.579e-02  1.004e-03 -95.392  < 2e-16 ***
Urban         3.456e-02  1.076e-03  32.131  < 2e-16 ***
Age15to19    -1.237e-03  1.207e-03  -1.025    0.305    
Age20to29     6.574e-02  1.333e-03  49.331  < 2e-16 ***
Age30to54     4.873e-02  1.262e-03  38.626  < 2e-16 ***
Age65Plus     8.661e-03  1.662e-03   5.210 1.89e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1866640  0.4118804 -10.165  < 2e-16 ***
HhSize        0.5180477  0.0245821  21.074  < 2e-16 ***
LogIncome     0.3449002  0.0403718   8.543  < 2e-16 ***
LogDensity   -0.0393092  0.0214121  -1.836 0.066382 .  
BusEqRevMiPC  0.0097519  0.0008816  11.062  < 2e-16 ***
LogDvmt      -1.0649706  0.0416183 -25.589  < 2e-16 ***
Urban         0.0716819  0.0400025   1.792 0.073143 .  
Age15to19     0.3068884  0.0470226   6.526 6.74e-11 ***
Age20to29     0.1936787  0.0521172   3.716 0.000202 ***
Age30to54     0.3872058  0.0466704   8.297  < 2e-16 ***
Age65Plus    -0.5823649  0.0644639  -9.034  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 21 
Log-likelihood: -3.381e+05 on 22 Df
```

**Nonmetropolitan Transit Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-6.3355 -0.2401 -0.1567 -0.1048 45.2078 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7699751  0.0105607 641.055  < 2e-16 ***
HhSize       0.0532340  0.0018396  28.939  < 2e-16 ***
LogIncome    0.0587398  0.0012717  46.189  < 2e-16 ***
LogDensity  -0.0124049  0.0004655 -26.647  < 2e-16 ***
LogDvmt     -0.1351744  0.0019872 -68.022  < 2e-16 ***
Age0to14    -0.0083741  0.0018217  -4.597 4.29e-06 ***
Age15to19    0.0236098  0.0020681  11.416  < 2e-16 ***
Age20to29   -0.0322737  0.0021758 -14.833  < 2e-16 ***
Age30to54   -0.0274336  0.0017203 -15.947  < 2e-16 ***
Age65Plus   -0.0709467  0.0027658 -25.651  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.43896    0.35057  -4.105 4.05e-05 ***
HhSize       0.49040    0.06451   7.602 2.92e-14 ***
LogIncome    0.23153    0.04342   5.332 9.73e-08 ***
LogDensity  -0.17525    0.01442 -12.157  < 2e-16 ***
LogDvmt     -1.27394    0.06930 -18.382  < 2e-16 ***
Age0to14     0.25502    0.06337   4.025 5.71e-05 ***
Age15to19    0.38523    0.07126   5.406 6.45e-08 ***
Age20to29    0.07019    0.07214   0.973    0.331    
Age30to54    0.53281    0.05692   9.360  < 2e-16 ***
Age65Plus   -0.60605    0.08593  -7.053 1.75e-12 ***
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
