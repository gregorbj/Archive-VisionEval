
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
-4.7371 -1.3363 -0.5990  0.5861 32.2158 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.588e+00  6.696e-03  685.11   <2e-16 ***
HhSize        3.171e-01  8.369e-04  378.91   <2e-16 ***
LogIncome     1.415e-01  6.555e-04  215.92   <2e-16 ***
LogDensity   -3.833e-03  3.342e-04  -11.47   <2e-16 ***
BusEqRevMiPC  1.631e-03  1.302e-05  125.26   <2e-16 ***
Urban         4.590e-02  6.120e-04   75.00   <2e-16 ***
LogDvmt      -2.185e-01  7.168e-04 -304.83   <2e-16 ***
Age0to14     -3.257e-01  9.079e-04 -358.72   <2e-16 ***
Age15to19    -8.747e-02  1.099e-03  -79.61   <2e-16 ***
Age20to29     4.689e-02  9.317e-04   50.33   <2e-16 ***
Age30to54     2.092e-02  7.154e-04   29.25   <2e-16 ***
Age65Plus    -3.505e-02  8.485e-04  -41.31   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2779413  0.2614086  -8.714  < 2e-16 ***
HhSize        0.4593084  0.0385357  11.919  < 2e-16 ***
LogIncome     0.2791104  0.0259858  10.741  < 2e-16 ***
LogDensity    0.0235111  0.0137732   1.707 0.087819 .  
BusEqRevMiPC -0.0038115  0.0005494  -6.938 3.97e-12 ***
Urban         0.0645189  0.0260824   2.474 0.013374 *  
LogDvmt      -0.2549406  0.0313245  -8.139 4.00e-16 ***
Age0to14     -0.3716023  0.0422642  -8.792  < 2e-16 ***
Age15to19    -0.1962102  0.0555833  -3.530 0.000416 ***
Age20to29     0.0929556  0.0428980   2.167 0.030243 *  
Age30to54     0.0648959  0.0309900   2.094 0.036252 *  
Age65Plus    -0.0372965  0.0344150  -1.084 0.278485    
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
-2.9713 -1.2632 -0.5842  0.5359 34.5830 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1532306  0.0044801 1373.45   <2e-16 ***
HhSize       0.3303627  0.0006746  489.73   <2e-16 ***
LogIncome   -0.0237249  0.0005589  -42.45   <2e-16 ***
LogDensity  -0.0377267  0.0001842 -204.84   <2e-16 ***
LogDvmt     -0.0415813  0.0010322  -40.28   <2e-16 ***
Age0to14    -0.3605891  0.0007032 -512.75   <2e-16 ***
Age15to19   -0.1465507  0.0008401 -174.44   <2e-16 ***
Age20to29    0.0241620  0.0006777   35.66   <2e-16 ***
Age30to54   -0.0190170  0.0005360  -35.48   <2e-16 ***
Age65Plus   -0.0301726  0.0006138  -49.16   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498134   0.159756  -3.118  0.00182 ** 
HhSize       0.145154   0.029143   4.981 6.33e-07 ***
LogIncome    0.057989   0.019818   2.926  0.00343 ** 
LogDensity  -0.034523   0.006875  -5.021 5.14e-07 ***
LogDvmt      0.117713   0.036068   3.264  0.00110 ** 
Age0to14    -0.190582   0.030040  -6.344 2.23e-10 ***
Age15to19    0.021192   0.038479   0.551  0.58181    
Age20to29    0.092809   0.028744   3.229  0.00124 ** 
Age30to54    0.064060   0.021310   3.006  0.00265 ** 
Age65Plus   -0.049916   0.023211  -2.151  0.03151 *  
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
-1.2353 -0.3524 -0.2790 -0.2282 34.1261 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.331e+00  2.473e-02  256.02   <2e-16 ***
HhSize        1.107e-01  4.271e-03   25.91   <2e-16 ***
LogIncome    -6.748e-02  2.902e-03  -23.25   <2e-16 ***
BusEqRevMiPC -2.242e-03  6.019e-05  -37.25   <2e-16 ***
LogDvmt      -1.700e-01  3.328e-03  -51.09   <2e-16 ***
Age0to14     -1.938e-01  4.480e-03  -43.26   <2e-16 ***
Age15to19    -1.358e-01  5.291e-03  -25.66   <2e-16 ***
Age20to29     7.882e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.899e-02  3.618e-03   21.84   <2e-16 ***
Age65Plus     4.914e-02  4.317e-03   11.38   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7708824  0.3800941 -12.552  < 2e-16 ***
HhSize        0.1658531  0.0580476   2.857 0.004274 ** 
LogIncome     0.2005139  0.0431463   4.647 3.36e-06 ***
BusEqRevMiPC -0.0061589  0.0008649  -7.121 1.07e-12 ***
LogDvmt      -0.0398563  0.0495602  -0.804 0.421282    
Age0to14      0.0452307  0.0599560   0.754 0.450610    
Age15to19     0.2071859  0.0717232   2.889 0.003869 ** 
Age20to29     0.2301406  0.0614262   3.747 0.000179 ***
Age30to54     0.1712962  0.0483193   3.545 0.000392 ***
Age65Plus    -0.0756264  0.0613725  -1.232 0.217855    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 36 
Log-likelihood: -1.193e+05 on 20 Df
```

**Nonmetropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.4413 -0.3567 -0.2792 -0.2273 57.2813 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.890165   0.017451  337.53   <2e-16 ***
HhSize       0.242322   0.002575   94.10   <2e-16 ***
LogIncome    0.033487   0.002126   15.75   <2e-16 ***
LogDvmt     -0.386664   0.003248 -119.03   <2e-16 ***
Age0to14    -0.289285   0.002742 -105.50   <2e-16 ***
Age15to19   -0.092250   0.003160  -29.20   <2e-16 ***
Age20to29    0.095813   0.002578   37.16   <2e-16 ***
Age30to54    0.024588   0.002280   10.79   <2e-16 ***
Age65Plus   -0.033710   0.002863  -11.77   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62336    0.27758 -16.656  < 2e-16 ***
HhSize       0.21584    0.04551   4.742 2.11e-06 ***
LogIncome    0.19371    0.03288   5.891 3.83e-09 ***
LogDvmt     -0.12168    0.05759  -2.113 0.034607 *  
Age0to14    -0.05069    0.04528  -1.120 0.262891    
Age15to19    0.18237    0.05279   3.455 0.000551 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17485    0.03476   5.031 4.89e-07 ***
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
-3.8989 -0.3420 -0.2262 -0.1478 34.7455 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.849  < 2e-16 ***
HhSize        1.345e-02  6.683e-04  20.130  < 2e-16 ***
LogIncome     5.791e-02  9.999e-04  57.920  < 2e-16 ***
LogDensity    4.498e-02  5.877e-04  76.534  < 2e-16 ***
BusEqRevMiPC  1.887e-03  2.542e-05  74.218  < 2e-16 ***
LogDvmt      -9.582e-02  1.004e-03 -95.428  < 2e-16 ***
Urban         3.458e-02  1.076e-03  32.144  < 2e-16 ***
Age15to19    -1.210e-03  1.207e-03  -1.003    0.316    
Age20to29     6.578e-02  1.333e-03  49.361  < 2e-16 ***
Age30to54     4.877e-02  1.262e-03  38.657  < 2e-16 ***
Age65Plus     8.681e-03  1.662e-03   5.222 1.77e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1730270  0.4117692 -10.134  < 2e-16 ***
HhSize        0.5180025  0.0245814  21.073  < 2e-16 ***
LogIncome     0.3436888  0.0403362   8.521  < 2e-16 ***
LogDensity   -0.0391585  0.0214096  -1.829 0.067398 .  
BusEqRevMiPC  0.0097541  0.0008816  11.065  < 2e-16 ***
LogDvmt      -1.0652368  0.0416216 -25.593  < 2e-16 ***
Urban         0.0718330  0.0400027   1.796 0.072542 .  
Age15to19     0.3071700  0.0470240   6.532 6.48e-11 ***
Age20to29     0.1942151  0.0521237   3.726 0.000195 ***
Age30to54     0.3876949  0.0466783   8.306  < 2e-16 ***
Age65Plus    -0.5822575  0.0644635  -9.032  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 21 
Log-likelihood: -3.381e+05 on 22 Df
```

**Nonmetropolitan Transit Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-6.3339 -0.2401 -0.1567 -0.1049 45.2210 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7688818  0.0105622 640.861  < 2e-16 ***
HhSize       0.0532170  0.0018393  28.933  < 2e-16 ***
LogIncome    0.0588901  0.0012727  46.273  < 2e-16 ***
LogDensity  -0.0124200  0.0004655 -26.679  < 2e-16 ***
LogDvmt     -0.1352264  0.0019862 -68.083  < 2e-16 ***
Age0to14    -0.0083843  0.0018217  -4.602 4.18e-06 ***
Age15to19    0.0236046  0.0020681  11.414  < 2e-16 ***
Age20to29   -0.0323188  0.0021757 -14.855  < 2e-16 ***
Age30to54   -0.0274480  0.0017202 -15.956  < 2e-16 ***
Age65Plus   -0.0709727  0.0027659 -25.660  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44804    0.35062  -4.130 3.63e-05 ***
HhSize       0.48988    0.06451   7.594 3.09e-14 ***
LogIncome    0.23262    0.04346   5.353 8.67e-08 ***
LogDensity  -0.17531    0.01442 -12.160  < 2e-16 ***
LogDvmt     -1.27374    0.06927 -18.389  < 2e-16 ***
Age0to14     0.25519    0.06337   4.027 5.65e-05 ***
Age15to19    0.38527    0.07127   5.406 6.44e-08 ***
Age20to29    0.06981    0.07214   0.968    0.333    
Age30to54    0.53262    0.05692   9.357  < 2e-16 ***
Age65Plus   -0.60593    0.08593  -7.052 1.77e-12 ***
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
