
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
-4.7359 -1.3363 -0.5991  0.5861 32.2066 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.587e+00  6.696e-03  684.98   <2e-16 ***
HhSize        3.171e-01  8.369e-04  378.87   <2e-16 ***
LogIncome     1.417e-01  6.559e-04  216.03   <2e-16 ***
LogDensity   -3.902e-03  3.344e-04  -11.67   <2e-16 ***
BusEqRevMiPC  1.631e-03  1.302e-05  125.30   <2e-16 ***
Urban         4.585e-02  6.120e-04   74.92   <2e-16 ***
LogDvmt      -2.187e-01  7.177e-04 -304.72   <2e-16 ***
Age0to14     -3.256e-01  9.079e-04 -358.63   <2e-16 ***
Age15to19    -8.740e-02  1.099e-03  -79.55   <2e-16 ***
Age20to29     4.697e-02  9.317e-04   50.41   <2e-16 ***
Age30to54     2.095e-02  7.154e-04   29.28   <2e-16 ***
Age65Plus    -3.506e-02  8.485e-04  -41.32   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2785180  0.2614128  -8.716  < 2e-16 ***
HhSize        0.4590485  0.0385322  11.913  < 2e-16 ***
LogIncome     0.2790926  0.0260033  10.733  < 2e-16 ***
LogDensity    0.0235050  0.0137790   1.706 0.088035 .  
BusEqRevMiPC -0.0038090  0.0005493  -6.934 4.10e-12 ***
Urban         0.0644900  0.0260833   2.472 0.013419 *  
LogDvmt      -0.2546892  0.0313551  -8.123 4.56e-16 ***
Age0to14     -0.3713021  0.0422589  -8.786  < 2e-16 ***
Age15to19    -0.1959697  0.0555804  -3.526 0.000422 ***
Age20to29     0.0930168  0.0428982   2.168 0.030135 *  
Age30to54     0.0649073  0.0309899   2.094 0.036218 *  
Age65Plus    -0.0372652  0.0344149  -1.083 0.278887    
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
-2.9714 -1.2632 -0.5842  0.5359 34.5826 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1535527  0.0044801 1373.52   <2e-16 ***
HhSize       0.3303446  0.0006747  489.63   <2e-16 ***
LogIncome   -0.0237574  0.0005588  -42.51   <2e-16 ***
LogDensity  -0.0377237  0.0001842 -204.79   <2e-16 ***
LogDvmt     -0.0415511  0.0010336  -40.20   <2e-16 ***
Age0to14    -0.3605705  0.0007032 -512.74   <2e-16 ***
Age15to19   -0.1465436  0.0008401 -174.43   <2e-16 ***
Age20to29    0.0241606  0.0006777   35.65   <2e-16 ***
Age30to54   -0.0190169  0.0005360  -35.48   <2e-16 ***
Age65Plus   -0.0301742  0.0006138  -49.16   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.499129   0.159757  -3.124  0.00178 ** 
HhSize       0.145000   0.029147   4.975 6.53e-07 ***
LogIncome    0.057888   0.019817   2.921  0.00349 ** 
LogDensity  -0.034486   0.006877  -5.015 5.31e-07 ***
LogDvmt      0.118212   0.036123   3.272  0.00107 ** 
Age0to14    -0.190510   0.030039  -6.342 2.27e-10 ***
Age15to19    0.021265   0.038480   0.553  0.58052    
Age20to29    0.092786   0.028744   3.228  0.00125 ** 
Age30to54    0.064038   0.021310   3.005  0.00266 ** 
Age65Plus   -0.049860   0.023212  -2.148  0.03171 *  
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
-1.2351 -0.3523 -0.2789 -0.2283 34.1237 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.3307268  0.0247345  255.95   <2e-16 ***
HhSize        0.1105436  0.0042714   25.88   <2e-16 ***
LogIncome    -0.0675510  0.0029040  -23.26   <2e-16 ***
BusEqRevMiPC -0.0022376  0.0000602  -37.17   <2e-16 ***
LogDvmt      -0.1698133  0.0033313  -50.98   <2e-16 ***
Age0to14     -0.1936199  0.0044802  -43.22   <2e-16 ***
Age15to19    -0.1355196  0.0052911  -25.61   <2e-16 ***
Age20to29     0.0788943  0.0044252   17.83   <2e-16 ***
Age30to54     0.0788330  0.0036176   21.79   <2e-16 ***
Age65Plus     0.0490520  0.0043175   11.36   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7702393  0.3801917 -12.547  < 2e-16 ***
HhSize        0.1657055  0.0580484   2.855 0.004309 ** 
LogIncome     0.2003443  0.0431692   4.641 3.47e-06 ***
BusEqRevMiPC -0.0061565  0.0008649  -7.118 1.10e-12 ***
LogDvmt      -0.0394971  0.0496054  -0.796 0.425901    
Age0to14      0.0453430  0.0599528   0.756 0.449462    
Age15to19     0.2072748  0.0717219   2.890 0.003853 ** 
Age20to29     0.2301493  0.0614260   3.747 0.000179 ***
Age30to54     0.1712859  0.0483192   3.545 0.000393 ***
Age65Plus    -0.0755910  0.0613726  -1.232 0.218071    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 32 
Log-likelihood: -1.193e+05 on 20 Df
```

**Nonmetropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.4411 -0.3567 -0.2792 -0.2273 57.2823 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.893100   0.017445  337.81   <2e-16 ***
HhSize       0.242409   0.002575   94.13   <2e-16 ***
LogIncome    0.033462   0.002126   15.74   <2e-16 ***
LogDvmt     -0.387229   0.003253 -119.04   <2e-16 ***
Age0to14    -0.289254   0.002742 -105.50   <2e-16 ***
Age15to19   -0.092278   0.003160  -29.21   <2e-16 ***
Age20to29    0.095833   0.002578   37.17   <2e-16 ***
Age30to54    0.024635   0.002280   10.81   <2e-16 ***
Age65Plus   -0.033794   0.002863  -11.80   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62250    0.27755 -16.654  < 2e-16 ***
HhSize       0.21588    0.04552   4.743 2.11e-06 ***
LogIncome    0.19371    0.03287   5.892 3.81e-09 ***
LogDvmt     -0.12188    0.05765  -2.114 0.034503 *  
Age0to14    -0.05069    0.04527  -1.120 0.262872    
Age15to19    0.18236    0.05279   3.455 0.000551 ***
Age20to29    0.25783    0.04318   5.971 2.36e-09 ***
Age30to54    0.17486    0.03476   5.031 4.88e-07 ***
Age65Plus   -0.18272    0.04441  -4.115 3.88e-05 ***
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
-3.9023 -0.3420 -0.2262 -0.1478 34.7250 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.784  < 2e-16 ***
HhSize        1.345e-02  6.685e-04  20.117  < 2e-16 ***
LogIncome     5.790e-02  1.001e-03  57.864  < 2e-16 ***
LogDensity    4.499e-02  5.879e-04  76.529  < 2e-16 ***
BusEqRevMiPC  1.888e-03  2.542e-05  74.248  < 2e-16 ***
LogDvmt      -9.576e-02  1.005e-03 -95.245  < 2e-16 ***
Urban         3.456e-02  1.076e-03  32.126  < 2e-16 ***
Age15to19    -1.239e-03  1.207e-03  -1.027    0.304    
Age20to29     6.576e-02  1.333e-03  49.342  < 2e-16 ***
Age30to54     4.873e-02  1.262e-03  38.626  < 2e-16 ***
Age65Plus     8.635e-03  1.662e-03   5.194 2.05e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1763741  0.4117908 -10.142  < 2e-16 ***
HhSize        0.5182812  0.0245854  21.081  < 2e-16 ***
LogIncome     0.3443789  0.0403629   8.532  < 2e-16 ***
LogDensity   -0.0394748  0.0214154  -1.843 0.065287 .  
BusEqRevMiPC  0.0097568  0.0008816  11.068  < 2e-16 ***
LogDvmt      -1.0658476  0.0416681 -25.579  < 2e-16 ***
Urban         0.0715767  0.0400020   1.789 0.073562 .  
Age15to19     0.3069973  0.0470227   6.529 6.63e-11 ***
Age20to29     0.1942309  0.0521207   3.727 0.000194 ***
Age30to54     0.3874638  0.0466722   8.302  < 2e-16 ***
Age65Plus    -0.5826584  0.0644627  -9.039  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 21 
Log-likelihood: -3.382e+05 on 22 Df
```

**Nonmetropolitan Transit Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-6.3343 -0.2401 -0.1568 -0.1048 45.1947 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7701465  0.0105604 641.091  < 2e-16 ***
HhSize       0.0532041  0.0018394  28.925  < 2e-16 ***
LogIncome    0.0588541  0.0012726  46.246  < 2e-16 ***
LogDensity  -0.0124245  0.0004656 -26.683  < 2e-16 ***
LogDvmt     -0.1353755  0.0019896 -68.040  < 2e-16 ***
Age0to14    -0.0083377  0.0018217  -4.577 4.72e-06 ***
Age15to19    0.0236186  0.0020681  11.420  < 2e-16 ***
Age20to29   -0.0323003  0.0021757 -14.846  < 2e-16 ***
Age30to54   -0.0274372  0.0017202 -15.950  < 2e-16 ***
Age65Plus   -0.0709581  0.0027659 -25.655  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.43684    0.35055  -4.099 4.15e-05 ***
HhSize       0.48996    0.06451   7.595 3.07e-14 ***
LogIncome    0.23242    0.04346   5.348 8.87e-08 ***
LogDensity  -0.17539    0.01442 -12.164  < 2e-16 ***
LogDvmt     -1.27544    0.06939 -18.380  < 2e-16 ***
Age0to14     0.25546    0.06336   4.032 5.54e-05 ***
Age15to19    0.38532    0.07126   5.407 6.41e-08 ***
Age20to29    0.06999    0.07214   0.970    0.332    
Age30to54    0.53276    0.05692   9.359  < 2e-16 ***
Age65Plus   -0.60596    0.08592  -7.052 1.76e-12 ***
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
