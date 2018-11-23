
# CalculateAltModeTrips Module
### November 12, 2018

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
-4.7345 -1.3362 -0.5987  0.5861 32.2118 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.586e+00  6.697e-03  684.89   <2e-16 ***
HhSize        3.170e-01  8.368e-04  378.81   <2e-16 ***
LogIncome     1.416e-01  6.555e-04  216.02   <2e-16 ***
LogDensity   -3.877e-03  3.343e-04  -11.60   <2e-16 ***
BusEqRevMiPC  1.632e-03  1.302e-05  125.41   <2e-16 ***
Urban         4.588e-02  6.120e-04   74.97   <2e-16 ***
LogDvmt      -2.182e-01  7.154e-04 -305.00   <2e-16 ***
Age0to14     -3.255e-01  9.078e-04 -358.59   <2e-16 ***
Age15to19    -8.739e-02  1.099e-03  -79.54   <2e-16 ***
Age20to29     4.686e-02  9.317e-04   50.29   <2e-16 ***
Age30to54     2.089e-02  7.154e-04   29.20   <2e-16 ***
Age65Plus    -3.497e-02  8.485e-04  -41.22   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2791204  0.2614177  -8.718  < 2e-16 ***
HhSize        0.4588967  0.0385222  11.913  < 2e-16 ***
LogIncome     0.2789843  0.0259863  10.736  < 2e-16 ***
LogDensity    0.0235411  0.0137744   1.709 0.087441 .  
BusEqRevMiPC -0.0038074  0.0005493  -6.932 4.15e-12 ***
Urban         0.0645254  0.0260825   2.474 0.013365 *  
LogDvmt      -0.2541550  0.0312604  -8.130 4.28e-16 ***
Age0to14     -0.3712352  0.0422557  -8.785  < 2e-16 ***
Age15to19    -0.1959636  0.0555794  -3.526 0.000422 ***
Age20to29     0.0929152  0.0428977   2.166 0.030313 *  
Age30to54     0.0648504  0.0309898   2.093 0.036381 *  
Age65Plus    -0.0371561  0.0344137  -1.080 0.280280    
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
-2.9708 -1.2632 -0.5842  0.5359 34.5831 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1534152  0.0044802 1373.48   <2e-16 ***
HhSize       0.3303181  0.0006749  489.41   <2e-16 ***
LogIncome   -0.0238084  0.0005589  -42.60   <2e-16 ***
LogDensity  -0.0377146  0.0001842 -204.71   <2e-16 ***
LogDvmt     -0.0413947  0.0010336  -40.05   <2e-16 ***
Age0to14    -0.3605769  0.0007034 -512.59   <2e-16 ***
Age15to19   -0.1465325  0.0008401 -174.41   <2e-16 ***
Age20to29    0.0241520  0.0006777   35.64   <2e-16 ***
Age30to54   -0.0190222  0.0005360  -35.49   <2e-16 ***
Age65Plus   -0.0301625  0.0006138  -49.14   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498755   0.159757  -3.122  0.00180 ** 
HhSize       0.144691   0.029158   4.962 6.97e-07 ***
LogIncome    0.057685   0.019819   2.911  0.00361 ** 
LogDensity  -0.034429   0.006878  -5.006 5.57e-07 ***
LogDvmt      0.118792   0.036123   3.288  0.00101 ** 
Age0to14    -0.190244   0.030049  -6.331 2.43e-10 ***
Age15to19    0.021421   0.038481   0.557  0.57776    
Age20to29    0.092754   0.028744   3.227  0.00125 ** 
Age30to54    0.064015   0.021311   3.004  0.00267 ** 
Age65Plus   -0.049801   0.023212  -2.145  0.03191 *  
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
-1.2352 -0.3523 -0.2790 -0.2282 34.1232 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.330e+00  2.474e-02  255.89   <2e-16 ***
HhSize        1.105e-01  4.271e-03   25.88   <2e-16 ***
LogIncome    -6.748e-02  2.903e-03  -23.25   <2e-16 ***
BusEqRevMiPC -2.241e-03  6.018e-05  -37.23   <2e-16 ***
LogDvmt      -1.697e-01  3.322e-03  -51.08   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.23   <2e-16 ***
Age15to19    -1.357e-01  5.291e-03  -25.65   <2e-16 ***
Age20to29     7.880e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.895e-02  3.618e-03   21.82   <2e-16 ***
Age65Plus     4.920e-02  4.317e-03   11.40   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7708853  0.3801826 -12.549  < 2e-16 ***
HhSize        0.1657812  0.0580344   2.857 0.004282 ** 
LogIncome     0.2004647  0.0431480   4.646 3.38e-06 ***
BusEqRevMiPC -0.0061579  0.0008648  -7.121 1.07e-12 ***
LogDvmt      -0.0396845  0.0494723  -0.802 0.422463    
Age0to14      0.0452898  0.0599477   0.755 0.449956    
Age15to19     0.2072246  0.0717203   2.889 0.003860 ** 
Age20to29     0.2301341  0.0614261   3.747 0.000179 ***
Age30to54     0.1712859  0.0483189   3.545 0.000393 ***
Age65Plus    -0.0756010  0.0613709  -1.232 0.217997    
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
-2.4409 -0.3568 -0.2792 -0.2273 57.2896 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.892032   0.017447  337.71   <2e-16 ***
HhSize       0.242533   0.002576   94.16   <2e-16 ***
LogIncome    0.033405   0.002126   15.71   <2e-16 ***
LogDvmt     -0.387031   0.003252 -119.00   <2e-16 ***
Age0to14    -0.289532   0.002742 -105.59   <2e-16 ***
Age15to19   -0.092290   0.003159  -29.21   <2e-16 ***
Age20to29    0.095853   0.002578   37.18   <2e-16 ***
Age30to54    0.024656   0.002280   10.82   <2e-16 ***
Age65Plus   -0.033781   0.002863  -11.80   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62273    0.27757 -16.654  < 2e-16 ***
HhSize       0.21571    0.04553   4.737 2.16e-06 ***
LogIncome    0.19349    0.03287   5.886 3.96e-09 ***
LogDvmt     -0.12118    0.05764  -2.102 0.035525 *  
Age0to14    -0.05064    0.04529  -1.118 0.263492    
Age15to19    0.18245    0.05279   3.456 0.000548 ***
Age20to29    0.25781    0.04318   5.971 2.36e-09 ***
Age30to54    0.17484    0.03476   5.030 4.90e-07 ***
Age65Plus   -0.18264    0.04441  -4.113 3.91e-05 ***
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
-3.8956 -0.3420 -0.2262 -0.1478 34.7492 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.043e-02 577.710  < 2e-16 ***
HhSize        1.344e-02  6.683e-04  20.117  < 2e-16 ***
LogIncome     5.791e-02  9.999e-04  57.914  < 2e-16 ***
LogDensity    4.498e-02  5.878e-04  76.523  < 2e-16 ***
BusEqRevMiPC  1.888e-03  2.542e-05  74.260  < 2e-16 ***
LogDvmt      -9.562e-02  1.002e-03 -95.409  < 2e-16 ***
Urban         3.458e-02  1.076e-03  32.145  < 2e-16 ***
Age15to19    -1.236e-03  1.207e-03  -1.024    0.306    
Age20to29     6.571e-02  1.333e-03  49.310  < 2e-16 ***
Age30to54     4.871e-02  1.261e-03  38.614  < 2e-16 ***
Age65Plus     8.657e-03  1.662e-03   5.208 1.91e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1794675  0.4118292 -10.149  < 2e-16 ***
HhSize        0.5179299  0.0245805  21.071  < 2e-16 ***
LogIncome     0.3438067  0.0403384   8.523  < 2e-16 ***
LogDensity   -0.0393000  0.0214115  -1.835 0.066437 .  
BusEqRevMiPC  0.0097635  0.0008815  11.076  < 2e-16 ***
LogDvmt      -1.0633046  0.0415406 -25.597  < 2e-16 ***
Urban         0.0717464  0.0400026   1.794 0.072886 .  
Age15to19     0.3068402  0.0470220   6.525 6.78e-11 ***
Age20to29     0.1934313  0.0521157   3.712 0.000206 ***
Age30to54     0.3870916  0.0466696   8.294  < 2e-16 ***
Age65Plus    -0.5823557  0.0644644  -9.034  < 2e-16 ***
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
-6.3312 -0.2401 -0.1568 -0.1049 45.2104 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7698557  0.0105609 641.032  < 2e-16 ***
HhSize       0.0532320  0.0018396  28.936  < 2e-16 ***
LogIncome    0.0588127  0.0012726  46.216  < 2e-16 ***
LogDensity  -0.0124193  0.0004657 -26.670  < 2e-16 ***
LogDvmt     -0.1352597  0.0019893 -67.993  < 2e-16 ***
Age0to14    -0.0084388  0.0018219  -4.632 3.62e-06 ***
Age15to19    0.0235964  0.0020681  11.409  < 2e-16 ***
Age20to29   -0.0323023  0.0021757 -14.847  < 2e-16 ***
Age30to54   -0.0274323  0.0017203 -15.946  < 2e-16 ***
Age65Plus   -0.0709466  0.0027659 -25.651  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44029    0.35057  -4.108 3.98e-05 ***
HhSize       0.49044    0.06451   7.602 2.91e-14 ***
LogIncome    0.23233    0.04345   5.347 8.96e-08 ***
LogDensity  -0.17546    0.01442 -12.167  < 2e-16 ***
LogDvmt     -1.27502    0.06939 -18.375  < 2e-16 ***
Age0to14     0.25450    0.06337   4.016 5.92e-05 ***
Age15to19    0.38514    0.07126   5.405 6.50e-08 ***
Age20to29    0.07009    0.07214   0.972    0.331    
Age30to54    0.53289    0.05692   9.361  < 2e-16 ***
Age65Plus   -0.60595    0.08592  -7.052 1.76e-12 ***
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

|NAME            |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT |ISELEMENTOF  |
|:---------------|:---------|:-----|:---------|:----------|:--------|:------------|
|Marea           |Marea     |Year  |character |ID         |         |             |
|TranRevMiPC     |Marea     |Year  |compound  |MI/PRSN/YR |NA, < 0  |             |
|Marea           |Bzone     |Year  |character |ID         |         |             |
|Bzone           |Bzone     |Year  |character |ID         |         |             |
|D1B             |Bzone     |Year  |compound  |PRSN/SQMI  |NA, < 0  |             |
|Marea           |Household |Year  |character |ID         |         |             |
|Bzone           |Household |Year  |character |ID         |         |             |
|Age0to14        |Household |Year  |people    |PRSN       |NA, < 0  |             |
|Age15to19       |Household |Year  |people    |PRSN       |NA, < 0  |             |
|Age20to29       |Household |Year  |people    |PRSN       |NA, < 0  |             |
|Age30to54       |Household |Year  |people    |PRSN       |NA, < 0  |             |
|Age55to64       |Household |Year  |people    |PRSN       |NA, < 0  |             |
|Age65Plus       |Household |Year  |people    |PRSN       |NA, < 0  |             |
|DevType         |Household |Year  |character |category   |NA       |Urban, Rural |
|HhSize          |Household |Year  |people    |PRSN       |NA, <= 0 |             |
|Income          |Household |Year  |currency  |USD.2001   |NA, < 0  |             |
|Vehicles        |Household |Year  |vehicles  |VEH        |NA, < 0  |             |
|IsUrbanMixNbrhd |Household |Year  |integer   |binary     |NA       |0, 1         |
|Dvmt            |Household |Year  |compound  |MI/DAY     |NA, < 0  |             |

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
