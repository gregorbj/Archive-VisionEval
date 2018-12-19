
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
-4.7374 -1.3362 -0.5992  0.5861 32.2161 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.585e+00  6.697e-03  684.73   <2e-16 ***
HhSize        3.171e-01  8.369e-04  378.91   <2e-16 ***
LogIncome     1.417e-01  6.559e-04  216.11   <2e-16 ***
LogDensity   -3.913e-03  3.343e-04  -11.70   <2e-16 ***
BusEqRevMiPC  1.630e-03  1.302e-05  125.23   <2e-16 ***
Urban         4.586e-02  6.120e-04   74.93   <2e-16 ***
LogDvmt      -2.185e-01  7.165e-04 -304.89   <2e-16 ***
Age0to14     -3.256e-01  9.079e-04 -358.69   <2e-16 ***
Age15to19    -8.746e-02  1.099e-03  -79.61   <2e-16 ***
Age20to29     4.691e-02  9.317e-04   50.34   <2e-16 ***
Age30to54     2.094e-02  7.154e-04   29.27   <2e-16 ***
Age65Plus    -3.509e-02  8.485e-04  -41.35   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2805853  0.2614318  -8.723  < 2e-16 ***
HhSize        0.4594548  0.0385352  11.923  < 2e-16 ***
LogIncome     0.2795512  0.0260023  10.751  < 2e-16 ***
LogDensity    0.0233324  0.0137785   1.693 0.090381 .  
BusEqRevMiPC -0.0038139  0.0005494  -6.942 3.86e-12 ***
Urban         0.0644189  0.0260834   2.470 0.013521 *  
LogDvmt      -0.2552852  0.0313141  -8.152 3.57e-16 ***
Age0to14     -0.3716683  0.0422635  -8.794  < 2e-16 ***
Age15to19    -0.1962990  0.0555836  -3.532 0.000413 ***
Age20to29     0.0930135  0.0428984   2.168 0.030142 *  
Age30to54     0.0649277  0.0309902   2.095 0.036162 *  
Age65Plus    -0.0373755  0.0344157  -1.086 0.277478    
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
-2.9712 -1.2632 -0.5842  0.5359 34.5814 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1533114  0.0044802 1373.45   <2e-16 ***
HhSize       0.3302918  0.0006749  489.43   <2e-16 ***
LogIncome   -0.0238360  0.0005588  -42.66   <2e-16 ***
LogDensity  -0.0377031  0.0001842 -204.72   <2e-16 ***
LogDvmt     -0.0413017  0.0010328  -39.99   <2e-16 ***
Age0to14    -0.3605497  0.0007034 -512.62   <2e-16 ***
Age15to19   -0.1465228  0.0008401 -174.40   <2e-16 ***
Age20to29    0.0241475  0.0006777   35.63   <2e-16 ***
Age30to54   -0.0190272  0.0005360  -35.50   <2e-16 ***
Age65Plus   -0.0301549  0.0006138  -49.13   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498394   0.159756  -3.120  0.00181 ** 
HhSize       0.144979   0.029155   4.973 6.60e-07 ***
LogIncome    0.057921   0.019817   2.923  0.00347 ** 
LogDensity  -0.034507   0.006875  -5.019 5.19e-07 ***
LogDvmt      0.118044   0.036100   3.270  0.00108 ** 
Age0to14    -0.190466   0.030045  -6.339 2.31e-10 ***
Age15to19    0.021272   0.038481   0.553  0.58041    
Age20to29    0.092785   0.028744   3.228  0.00125 ** 
Age30to54    0.064043   0.021310   3.005  0.00265 ** 
Age65Plus   -0.049873   0.023212  -2.149  0.03167 *  
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
-1.2353 -0.3524 -0.2790 -0.2282 34.1276 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.3291945  0.0247423  255.81   <2e-16 ***
HhSize        0.1105273  0.0042711   25.88   <2e-16 ***
LogIncome    -0.0674407  0.0029038  -23.23   <2e-16 ***
BusEqRevMiPC -0.0022403  0.0000602  -37.22   <2e-16 ***
LogDvmt      -0.1697391  0.0033261  -51.03   <2e-16 ***
Age0to14     -0.1937625  0.0044802  -43.25   <2e-16 ***
Age15to19    -0.1356565  0.0052912  -25.64   <2e-16 ***
Age20to29     0.0788740  0.0044252   17.82   <2e-16 ***
Age30to54     0.0788945  0.0036176   21.81   <2e-16 ***
Age65Plus     0.0491127  0.0043174   11.38   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.771484   0.380271 -12.548  < 2e-16 ***
HhSize        0.165867   0.058044   2.858 0.004269 ** 
LogIncome     0.200570   0.043166   4.646 3.38e-06 ***
BusEqRevMiPC -0.006159   0.000865  -7.121 1.07e-12 ***
LogDvmt      -0.039886   0.049526  -0.805 0.420615    
Age0to14      0.045228   0.059953   0.754 0.450618    
Age15to19     0.207179   0.071722   2.889 0.003869 ** 
Age20to29     0.230141   0.061426   3.747 0.000179 ***
Age30to54     0.171299   0.048319   3.545 0.000392 ***
Age65Plus    -0.075638   0.061373  -1.232 0.217789    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 39 
Log-likelihood: -1.193e+05 on 20 Df
```

**Nonmetropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.4412 -0.3567 -0.2792 -0.2273 57.2853 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.891321   0.017449  337.64   <2e-16 ***
HhSize       0.242469   0.002576   94.14   <2e-16 ***
LogIncome    0.033401   0.002126   15.71   <2e-16 ***
LogDvmt     -0.386846   0.003251 -118.98   <2e-16 ***
Age0to14    -0.289375   0.002742 -105.54   <2e-16 ***
Age15to19   -0.092257   0.003159  -29.20   <2e-16 ***
Age20to29    0.095898   0.002578   37.20   <2e-16 ***
Age30to54    0.024639   0.002280   10.81   <2e-16 ***
Age65Plus   -0.033753   0.002863  -11.79   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62302    0.27758 -16.655  < 2e-16 ***
HhSize       0.21582    0.04553   4.740 2.14e-06 ***
LogIncome    0.19361    0.03288   5.889 3.89e-09 ***
LogDvmt     -0.12150    0.05764  -2.108  0.03502 *  
Age0to14    -0.05068    0.04528  -1.119  0.26308    
Age15to19    0.18239    0.05279   3.455  0.00055 ***
Age20to29    0.25783    0.04318   5.971 2.36e-09 ***
Age30to54    0.17485    0.03476   5.031 4.89e-07 ***
Age65Plus   -0.18268    0.04441  -4.114 3.89e-05 ***
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
-3.8999 -0.3421 -0.2262 -0.1478 34.7311 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.043e-02 577.712  < 2e-16 ***
HhSize        1.342e-02  6.684e-04  20.086  < 2e-16 ***
LogIncome     5.790e-02  1.000e-03  57.871  < 2e-16 ***
LogDensity    4.498e-02  5.879e-04  76.504  < 2e-16 ***
BusEqRevMiPC  1.887e-03  2.542e-05  74.238  < 2e-16 ***
LogDvmt      -9.566e-02  1.004e-03 -95.278  < 2e-16 ***
Urban         3.456e-02  1.076e-03  32.129  < 2e-16 ***
Age15to19    -1.226e-03  1.207e-03  -1.016     0.31    
Age20to29     6.576e-02  1.333e-03  49.346  < 2e-16 ***
Age30to54     4.875e-02  1.262e-03  38.642  < 2e-16 ***
Age65Plus     8.655e-03  1.662e-03   5.206 1.93e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1817230  0.4118335 -10.154  < 2e-16 ***
HhSize        0.5179369  0.0245807  21.071  < 2e-16 ***
LogIncome     0.3441480  0.0403574   8.528  < 2e-16 ***
LogDensity   -0.0393922  0.0214149  -1.839 0.065846 .  
BusEqRevMiPC  0.0097556  0.0008816  11.066  < 2e-16 ***
LogDvmt      -1.0641418  0.0416044 -25.578  < 2e-16 ***
Urban         0.0716410  0.0400018   1.791 0.073302 .  
Age15to19     0.3070160  0.0470215   6.529 6.61e-11 ***
Age20to29     0.1940340  0.0521181   3.723 0.000197 ***
Age30to54     0.3875429  0.0466728   8.303  < 2e-16 ***
Age65Plus    -0.5825570  0.0644610  -9.037  < 2e-16 ***
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
-6.3333 -0.2401 -0.1567 -0.1048 45.2141 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7693488  0.0105616  640.94  < 2e-16 ***
HhSize       0.0532451  0.0018396   28.94  < 2e-16 ***
LogIncome    0.0588421  0.0012726   46.24  < 2e-16 ***
LogDensity  -0.0124062  0.0004655  -26.65  < 2e-16 ***
LogDvmt     -0.1352631  0.0019883  -68.03  < 2e-16 ***
Age0to14    -0.0083988  0.0018218   -4.61 4.02e-06 ***
Age15to19    0.0235966  0.0020681   11.41  < 2e-16 ***
Age20to29   -0.0322862  0.0021757  -14.84  < 2e-16 ***
Age30to54   -0.0274324  0.0017203  -15.95  < 2e-16 ***
Age65Plus   -0.0709515  0.0027659  -25.65  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44477    0.35060  -4.121 3.77e-05 ***
HhSize       0.49044    0.06451   7.602 2.91e-14 ***
LogIncome    0.23244    0.04346   5.349 8.86e-08 ***
LogDensity  -0.17525    0.01442 -12.157  < 2e-16 ***
LogDvmt     -1.27463    0.06934 -18.382  < 2e-16 ***
Age0to14     0.25486    0.06337   4.022 5.77e-05 ***
Age15to19    0.38513    0.07126   5.404 6.50e-08 ***
Age20to29    0.07009    0.07214   0.972    0.331    
Age30to54    0.53281    0.05692   9.360  < 2e-16 ***
Age65Plus   -0.60604    0.08593  -7.053 1.75e-12 ***
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
