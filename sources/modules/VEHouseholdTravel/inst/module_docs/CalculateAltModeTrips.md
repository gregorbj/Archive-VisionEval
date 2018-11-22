
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
-4.7382 -1.3362 -0.5988  0.5861 32.2172 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.588e+00  6.696e-03  685.24   <2e-16 ***
HhSize        3.172e-01  8.369e-04  379.02   <2e-16 ***
LogIncome     1.417e-01  6.555e-04  216.16   <2e-16 ***
LogDensity   -4.010e-03  3.344e-04  -11.99   <2e-16 ***
BusEqRevMiPC  1.633e-03  1.301e-05  125.44   <2e-16 ***
Urban         4.582e-02  6.120e-04   74.87   <2e-16 ***
LogDvmt      -2.189e-01  7.171e-04 -305.26   <2e-16 ***
Age0to14     -3.256e-01  9.078e-04 -358.65   <2e-16 ***
Age15to19    -8.752e-02  1.099e-03  -79.65   <2e-16 ***
Age20to29     4.690e-02  9.317e-04   50.34   <2e-16 ***
Age30to54     2.095e-02  7.154e-04   29.28   <2e-16 ***
Age65Plus    -3.513e-02  8.485e-04  -41.41   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2774345  0.2614081  -8.712  < 2e-16 ***
HhSize        0.4596362  0.0385360  11.927  < 2e-16 ***
LogIncome     0.2795697  0.0259874  10.758  < 2e-16 ***
LogDensity    0.0231983  0.0137812   1.683  0.09231 .  
BusEqRevMiPC -0.0038117  0.0005492  -6.940 3.91e-12 ***
Urban         0.0643657  0.0260837   2.468  0.01360 *  
LogDvmt      -0.2559642  0.0313440  -8.166 3.18e-16 ***
Age0to14     -0.3716441  0.0422606  -8.794  < 2e-16 ***
Age15to19    -0.1964046  0.0555842  -3.533  0.00041 ***
Age20to29     0.0930171  0.0428986   2.168  0.03014 *  
Age30to54     0.0649367  0.0309904   2.095  0.03614 *  
Age65Plus    -0.0374473  0.0344162  -1.088  0.27656    
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
-2.9709 -1.2633 -0.5842  0.5359 34.5810 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1534174  0.0044802 1373.47   <2e-16 ***
HhSize       0.3302659  0.0006749  489.34   <2e-16 ***
LogIncome   -0.0238649  0.0005589  -42.70   <2e-16 ***
LogDensity  -0.0376985  0.0001842 -204.67   <2e-16 ***
LogDvmt     -0.0412418  0.0010339  -39.89   <2e-16 ***
Age0to14    -0.3605268  0.0007033 -512.60   <2e-16 ***
Age15to19   -0.1465175  0.0008402 -174.39   <2e-16 ***
Age20to29    0.0241374  0.0006777   35.62   <2e-16 ***
Age30to54   -0.0190324  0.0005360  -35.51   <2e-16 ***
Age65Plus   -0.0301491  0.0006138  -49.12   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498743   0.159757  -3.122  0.00180 ** 
HhSize       0.144823   0.029159   4.967 6.81e-07 ***
LogIncome    0.057791   0.019821   2.916  0.00355 ** 
LogDensity  -0.034471   0.006876  -5.013 5.36e-07 ***
LogDvmt      0.118508   0.036142   3.279  0.00104 ** 
Age0to14    -0.190388   0.030044  -6.337 2.34e-10 ***
Age15to19    0.021364   0.038482   0.555  0.57879    
Age20to29    0.092782   0.028744   3.228  0.00125 ** 
Age30to54    0.064033   0.021310   3.005  0.00266 ** 
Age65Plus   -0.049834   0.023212  -2.147  0.03180 *  
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
-1.2356 -0.3524 -0.2790 -0.2282 34.1347 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.331e+00  2.473e-02  256.01   <2e-16 ***
HhSize        1.106e-01  4.271e-03   25.90   <2e-16 ***
LogIncome    -6.754e-02  2.902e-03  -23.27   <2e-16 ***
BusEqRevMiPC -2.239e-03  6.017e-05  -37.21   <2e-16 ***
LogDvmt      -1.700e-01  3.328e-03  -51.08   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.23   <2e-16 ***
Age15to19    -1.357e-01  5.291e-03  -25.65   <2e-16 ***
Age20to29     7.881e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.899e-02  3.618e-03   21.84   <2e-16 ***
Age65Plus     4.908e-02  4.318e-03   11.37   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7721563  0.3801149 -12.555  < 2e-16 ***
HhSize        0.1660383  0.0580412   2.861 0.004227 ** 
LogIncome     0.2007783  0.0431414   4.654 3.26e-06 ***
BusEqRevMiPC -0.0061616  0.0008647  -7.126 1.04e-12 ***
LogDvmt      -0.0403745  0.0495410  -0.815 0.415088    
Age0to14      0.0451376  0.0599458   0.753 0.451466    
Age15to19     0.2070878  0.0717213   2.887 0.003884 ** 
Age20to29     0.2301383  0.0614263   3.747 0.000179 ***
Age30to54     0.1713132  0.0483195   3.545 0.000392 ***
Age65Plus    -0.0756865  0.0613735  -1.233 0.217497    
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
-2.4413 -0.3567 -0.2792 -0.2273 57.2867 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.892199   0.017447  337.72   <2e-16 ***
HhSize       0.242537   0.002576   94.17   <2e-16 ***
LogIncome    0.033490   0.002126   15.75   <2e-16 ***
LogDvmt     -0.387351   0.003255 -119.02   <2e-16 ***
Age0to14    -0.289325   0.002742 -105.53   <2e-16 ***
Age15to19   -0.092309   0.003159  -29.22   <2e-16 ***
Age20to29    0.095866   0.002578   37.19   <2e-16 ***
Age30to54    0.024648   0.002280   10.81   <2e-16 ***
Age65Plus   -0.033774   0.002863  -11.80   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62283    0.27757 -16.655  < 2e-16 ***
HhSize       0.21589    0.04553   4.742 2.12e-06 ***
LogIncome    0.19368    0.03288   5.891 3.85e-09 ***
LogDvmt     -0.12178    0.05768  -2.111 0.034743 *  
Age0to14    -0.05070    0.04528  -1.120 0.262836    
Age15to19    0.18235    0.05279   3.454 0.000552 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17485    0.03476   5.031 4.88e-07 ***
Age65Plus   -0.18270    0.04441  -4.114 3.89e-05 ***
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
-3.9006 -0.3420 -0.2262 -0.1478 34.7602 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.030e+00  1.043e-02 577.995  < 2e-16 ***
HhSize        1.354e-02  6.686e-04  20.246  < 2e-16 ***
LogIncome     5.792e-02  9.997e-04  57.938  < 2e-16 ***
LogDensity    4.491e-02  5.881e-04  76.365  < 2e-16 ***
BusEqRevMiPC  1.888e-03  2.542e-05  74.259  < 2e-16 ***
LogDvmt      -9.594e-02  1.005e-03 -95.473  < 2e-16 ***
Urban         3.454e-02  1.076e-03  32.114  < 2e-16 ***
Age15to19    -1.275e-03  1.207e-03  -1.057    0.291    
Age20to29     6.573e-02  1.333e-03  49.325  < 2e-16 ***
Age30to54     4.874e-02  1.262e-03  38.639  < 2e-16 ***
Age65Plus     8.598e-03  1.662e-03   5.172 2.32e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1665342  0.4116977 -10.120  < 2e-16 ***
HhSize        0.5186630  0.0245900  21.092  < 2e-16 ***
LogIncome     0.3435738  0.0403294   8.519  < 2e-16 ***
LogDensity   -0.0398231  0.0214184  -1.859 0.062985 .  
BusEqRevMiPC  0.0097695  0.0008814  11.084  < 2e-16 ***
LogDvmt      -1.0659624  0.0416466 -25.595  < 2e-16 ***
Urban         0.0714860  0.0400031   1.787 0.073935 .  
Age15to19     0.3064792  0.0470241   6.517 7.15e-11 ***
Age20to29     0.1936830  0.0521178   3.716 0.000202 ***
Age30to54     0.3874180  0.0466722   8.301  < 2e-16 ***
Age65Plus    -0.5829816  0.0644607  -9.044  < 2e-16 ***
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
-6.3340 -0.2400 -0.1568 -0.1048 45.1789 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7698395  0.0105609 641.030  < 2e-16 ***
HhSize       0.0532377  0.0018396  28.940  < 2e-16 ***
LogIncome    0.0588583  0.0012729  46.240  < 2e-16 ***
LogDensity  -0.0124161  0.0004656 -26.666  < 2e-16 ***
LogDvmt     -0.1354148  0.0019911 -68.009  < 2e-16 ***
Age0to14    -0.0083554  0.0018217  -4.587  4.5e-06 ***
Age15to19    0.0236029  0.0020681  11.413  < 2e-16 ***
Age20to29   -0.0322895  0.0021757 -14.841  < 2e-16 ***
Age30to54   -0.0274239  0.0017203 -15.941  < 2e-16 ***
Age65Plus   -0.0709253  0.0027658 -25.644  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44068    0.35058  -4.109 3.97e-05 ***
HhSize       0.49061    0.06451   7.605 2.85e-14 ***
LogIncome    0.23269    0.04347   5.353 8.63e-08 ***
LogDensity  -0.17535    0.01442 -12.162  < 2e-16 ***
LogDvmt     -1.27628    0.06944 -18.379  < 2e-16 ***
Age0to14     0.25507    0.06336   4.026 5.68e-05 ***
Age15to19    0.38500    0.07126   5.403 6.56e-08 ***
Age20to29    0.07004    0.07214   0.971    0.332    
Age30to54    0.53286    0.05692   9.361  < 2e-16 ***
Age65Plus   -0.60598    0.08592  -7.053 1.76e-12 ***
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
