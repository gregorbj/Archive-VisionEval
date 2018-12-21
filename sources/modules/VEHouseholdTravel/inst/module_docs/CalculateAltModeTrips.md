
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
-4.7386 -1.3363 -0.5993  0.5858 32.2056 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.588e+00  6.696e-03  685.17   <2e-16 ***
HhSize        3.172e-01  8.370e-04  378.96   <2e-16 ***
LogIncome     1.417e-01  6.559e-04  216.09   <2e-16 ***
LogDensity   -3.965e-03  3.344e-04  -11.86   <2e-16 ***
BusEqRevMiPC  1.629e-03  1.302e-05  125.16   <2e-16 ***
Urban         4.584e-02  6.120e-04   74.90   <2e-16 ***
LogDvmt      -2.188e-01  7.178e-04 -304.87   <2e-16 ***
Age0to14     -3.256e-01  9.078e-04 -358.63   <2e-16 ***
Age15to19    -8.746e-02  1.099e-03  -79.60   <2e-16 ***
Age20to29     4.696e-02  9.317e-04   50.41   <2e-16 ***
Age30to54     2.094e-02  7.154e-04   29.27   <2e-16 ***
Age65Plus    -3.507e-02  8.485e-04  -41.34   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2776206  0.2614083  -8.713  < 2e-16 ***
HhSize        0.4595262  0.0385379  11.924  < 2e-16 ***
LogIncome     0.2795363  0.0260013  10.751  < 2e-16 ***
LogDensity    0.0232714  0.0137819   1.689 0.091307 .  
BusEqRevMiPC -0.0038150  0.0005494  -6.944 3.81e-12 ***
Urban         0.0643951  0.0260837   2.469 0.013557 *  
LogDvmt      -0.2557503  0.0313715  -8.152 3.57e-16 ***
Age0to14     -0.3715558  0.0422605  -8.792  < 2e-16 ***
Age15to19    -0.1962613  0.0555828  -3.531 0.000414 ***
Age20to29     0.0930454  0.0428987   2.169 0.030086 *  
Age30to54     0.0649201  0.0309902   2.095 0.036183 *  
Age65Plus    -0.0373594  0.0344155  -1.086 0.277683    
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
-2.9705 -1.2632 -0.5842  0.5359 34.5829 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1531232  0.0044802 1373.41   <2e-16 ***
HhSize       0.3303271  0.0006748  489.49   <2e-16 ***
LogIncome   -0.0237849  0.0005590  -42.55   <2e-16 ***
LogDensity  -0.0377181  0.0001842 -204.74   <2e-16 ***
LogDvmt     -0.0413985  0.0010323  -40.10   <2e-16 ***
Age0to14    -0.3605771  0.0007034 -512.63   <2e-16 ***
Age15to19   -0.1465391  0.0008401 -174.42   <2e-16 ***
Age20to29    0.0241461  0.0006777   35.63   <2e-16 ***
Age30to54   -0.0190273  0.0005360  -35.50   <2e-16 ***
Age65Plus   -0.0301531  0.0006138  -49.13   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.497868   0.159756  -3.116  0.00183 ** 
HhSize       0.144782   0.029155   4.966 6.83e-07 ***
LogIncome    0.057729   0.019821   2.913  0.00358 ** 
LogDensity  -0.034445   0.006878  -5.008 5.50e-07 ***
LogDvmt      0.118465   0.036074   3.284  0.00102 ** 
Age0to14    -0.190314   0.030047  -6.334 2.39e-10 ***
Age15to19    0.021387   0.038481   0.556  0.57837    
Age20to29    0.092787   0.028744   3.228  0.00125 ** 
Age30to54    0.064043   0.021310   3.005  0.00265 ** 
Age65Plus   -0.049858   0.023210  -2.148  0.03170 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1325 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.3309855  0.0247295  256.01   <2e-16 ***
HhSize        0.1106349  0.0042717   25.90   <2e-16 ***
LogIncome    -0.0675227  0.0029033  -23.26   <2e-16 ***
BusEqRevMiPC -0.0022417  0.0000602  -37.24   <2e-16 ***
LogDvmt      -0.1699416  0.0033311  -51.02   <2e-16 ***
Age0to14     -0.1936930  0.0044801  -43.23   <2e-16 ***
Age15to19    -0.1357105  0.0052913  -25.65   <2e-16 ***
Age20to29     0.0788575  0.0044253   17.82   <2e-16 ***
Age30to54     0.0789887  0.0036176   21.83   <2e-16 ***
Age65Plus     0.0491159  0.0043175   11.38   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7714058  0.3801431 -12.552  < 2e-16 ***
HhSize        0.1659229  0.0580495   2.858 0.004259 ** 
LogIncome     0.2006233  0.0431624   4.648 3.35e-06 ***
BusEqRevMiPC -0.0061602  0.0008651  -7.121 1.07e-12 ***
LogDvmt      -0.0400555  0.0495939  -0.808 0.419280    
Age0to14      0.0452116  0.0599499   0.754 0.450755    
Age15to19     0.2071586  0.0717219   2.888 0.003873 ** 
Age20to29     0.2301463  0.0614261   3.747 0.000179 ***
Age30to54     0.1713010  0.0483193   3.545 0.000392 ***
Age65Plus    -0.0756449  0.0613727  -1.233 0.217744    
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 36 
Log-likelihood: -1.193e+05 on 20 Df
```

**Nonmetropolitan Bike Trip Model**
```

Call:
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-2.4413 -0.3568 -0.2792 -0.2273 57.2829 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.889023   0.017453  337.42   <2e-16 ***
HhSize       0.242494   0.002575   94.16   <2e-16 ***
LogIncome    0.033506   0.002126   15.76   <2e-16 ***
LogDvmt     -0.386660   0.003247 -119.07   <2e-16 ***
Age0to14    -0.289462   0.002742 -105.57   <2e-16 ***
Age15to19   -0.092305   0.003159  -29.21   <2e-16 ***
Age20to29    0.095777   0.002578   37.15   <2e-16 ***
Age30to54    0.024583   0.002279   10.79   <2e-16 ***
Age65Plus   -0.033653   0.002863  -11.75   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62367    0.27760 -16.656  < 2e-16 ***
HhSize       0.21579    0.04553   4.740 2.14e-06 ***
LogIncome    0.19360    0.03288   5.889 3.90e-09 ***
LogDvmt     -0.12134    0.05757  -2.108  0.03507 *  
Age0to14    -0.05068    0.04529  -1.119  0.26306    
Age15to19    0.18239    0.05279   3.455  0.00055 ***
Age20to29    0.25780    0.04318   5.970 2.37e-09 ***
Age30to54    0.17483    0.03476   5.030 4.90e-07 ***
Age65Plus   -0.18264    0.04440  -4.113 3.90e-05 ***
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
-3.9039 -0.3420 -0.2262 -0.1478 34.7402 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.929  < 2e-16 ***
HhSize        1.350e-02  6.686e-04  20.197  < 2e-16 ***
LogIncome     5.791e-02  1.000e-03  57.888  < 2e-16 ***
LogDensity    4.495e-02  5.880e-04  76.443  < 2e-16 ***
BusEqRevMiPC  1.886e-03  2.542e-05  74.201  < 2e-16 ***
LogDvmt      -9.586e-02  1.006e-03 -95.309  < 2e-16 ***
Urban         3.455e-02  1.076e-03  32.119  < 2e-16 ***
Age15to19    -1.270e-03  1.207e-03  -1.052    0.293    
Age20to29     6.573e-02  1.333e-03  49.326  < 2e-16 ***
Age30to54     4.872e-02  1.262e-03  38.618  < 2e-16 ***
Age65Plus     8.621e-03  1.662e-03   5.186 2.15e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1697345  0.4117357 -10.127  < 2e-16 ***
HhSize        0.5187379  0.0245911  21.095  < 2e-16 ***
LogIncome     0.3443083  0.0403561   8.532  < 2e-16 ***
LogDensity   -0.0397736  0.0214187  -1.857 0.063317 .  
BusEqRevMiPC  0.0097489  0.0008816  11.058  < 2e-16 ***
LogDvmt      -1.0665200  0.0416838 -25.586  < 2e-16 ***
Urban         0.0715008  0.0400023   1.787 0.073870 .  
Age15to19     0.3066990  0.0470240   6.522 6.93e-11 ***
Age20to29     0.1941055  0.0521219   3.724 0.000196 ***
Age30to54     0.3874032  0.0466723   8.300  < 2e-16 ***
Age65Plus    -0.5827612  0.0644626  -9.040  < 2e-16 ***
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
-6.3335 -0.2402 -0.1568 -0.1048 45.2152 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7687068  0.0105625 640.824  < 2e-16 ***
HhSize       0.0532457  0.0018395  28.945  < 2e-16 ***
LogIncome    0.0588701  0.0012727  46.257  < 2e-16 ***
LogDensity  -0.0124306  0.0004657 -26.695  < 2e-16 ***
LogDvmt     -0.1351725  0.0019863 -68.054  < 2e-16 ***
Age0to14    -0.0084310  0.0018218  -4.628  3.7e-06 ***
Age15to19    0.0235865  0.0020681  11.405  < 2e-16 ***
Age20to29   -0.0323318  0.0021757 -14.861  < 2e-16 ***
Age30to54   -0.0274427  0.0017202 -15.953  < 2e-16 ***
Age65Plus   -0.0709363  0.0027658 -25.647  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.45042    0.35064  -4.136 3.53e-05 ***
HhSize       0.49048    0.06451   7.603 2.89e-14 ***
LogIncome    0.23273    0.04346   5.355 8.55e-08 ***
LogDensity  -0.17550    0.01442 -12.170  < 2e-16 ***
LogDvmt     -1.27393    0.06928 -18.389  < 2e-16 ***
Age0to14     0.25459    0.06337   4.018 5.88e-05 ***
Age15to19    0.38499    0.07126   5.402 6.58e-08 ***
Age20to29    0.06978    0.07214   0.967    0.333    
Age30to54    0.53267    0.05692   9.358  < 2e-16 ***
Age65Plus   -0.60577    0.08593  -7.050 1.79e-12 ***
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
