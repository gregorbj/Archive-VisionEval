
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
-4.7371 -1.3362 -0.5990  0.5862 32.2156 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.587e+00  6.696e-03  684.95   <2e-16 ***
HhSize        3.171e-01  8.369e-04  378.92   <2e-16 ***
LogIncome     1.416e-01  6.557e-04  216.03   <2e-16 ***
LogDensity   -3.881e-03  3.343e-04  -11.61   <2e-16 ***
BusEqRevMiPC  1.636e-03  1.301e-05  125.73   <2e-16 ***
Urban         4.588e-02  6.120e-04   74.96   <2e-16 ***
LogDvmt      -2.186e-01  7.170e-04 -304.89   <2e-16 ***
Age0to14     -3.257e-01  9.079e-04 -358.71   <2e-16 ***
Age15to19    -8.746e-02  1.099e-03  -79.60   <2e-16 ***
Age20to29     4.690e-02  9.317e-04   50.34   <2e-16 ***
Age30to54     2.094e-02  7.154e-04   29.27   <2e-16 ***
Age65Plus    -3.508e-02  8.485e-04  -41.34   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2790726  0.2614186  -8.718  < 2e-16 ***
HhSize        0.4593179  0.0385351  11.919  < 2e-16 ***
LogIncome     0.2792401  0.0259930  10.743  < 2e-16 ***
LogDensity    0.0234511  0.0137759   1.702 0.088694 .  
BusEqRevMiPC -0.0038050  0.0005491  -6.929 4.23e-12 ***
Urban         0.0644830  0.0260828   2.472 0.013427 *  
LogDvmt      -0.2550416  0.0313291  -8.141 3.93e-16 ***
Age0to14     -0.3715918  0.0422636  -8.792  < 2e-16 ***
Age15to19    -0.1962083  0.0555831  -3.530 0.000416 ***
Age20to29     0.0929803  0.0428981   2.167 0.030199 *  
Age30to54     0.0649105  0.0309901   2.095 0.036210 *  
Age65Plus    -0.0373262  0.0344153  -1.085 0.278107    
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
-2.9711 -1.2633 -0.5841  0.5359 34.5826 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1534879  0.0044802 1373.50   <2e-16 ***
HhSize       0.3303220  0.0006747  489.56   <2e-16 ***
LogIncome   -0.0237988  0.0005587  -42.60   <2e-16 ***
LogDensity  -0.0377156  0.0001842 -204.76   <2e-16 ***
LogDvmt     -0.0414332  0.0010328  -40.12   <2e-16 ***
Age0to14    -0.3605753  0.0007034 -512.65   <2e-16 ***
Age15to19   -0.1465373  0.0008401 -174.42   <2e-16 ***
Age20to29    0.0241545  0.0006777   35.64   <2e-16 ***
Age30to54   -0.0190193  0.0005360  -35.48   <2e-16 ***
Age65Plus   -0.0301722  0.0006138  -49.16   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498933   0.159757  -3.123  0.00179 ** 
HhSize       0.144932   0.029150   4.972 6.63e-07 ***
LogIncome    0.057883   0.019811   2.922  0.00348 ** 
LogDensity  -0.034482   0.006876  -5.015 5.32e-07 ***
LogDvmt      0.118236   0.036098   3.275  0.00106 ** 
Age0to14    -0.190410   0.030045  -6.337 2.34e-10 ***
Age15to19    0.021309   0.038481   0.554  0.57974    
Age20to29    0.092780   0.028744   3.228  0.00125 ** 
Age30to54    0.064029   0.021311   3.005  0.00266 ** 
Age65Plus   -0.049835   0.023212  -2.147  0.03180 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1312 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.330e+00  2.473e-02  255.91   <2e-16 ***
HhSize        1.107e-01  4.271e-03   25.91   <2e-16 ***
LogIncome    -6.745e-02  2.903e-03  -23.24   <2e-16 ***
BusEqRevMiPC -2.235e-03  6.016e-05  -37.15   <2e-16 ***
LogDvmt      -1.700e-01  3.328e-03  -51.08   <2e-16 ***
Age0to14     -1.938e-01  4.480e-03  -43.24   <2e-16 ***
Age15to19    -1.356e-01  5.291e-03  -25.64   <2e-16 ***
Age20to29     7.882e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.884e-02  3.618e-03   21.79   <2e-16 ***
Age65Plus     4.903e-02  4.318e-03   11.36   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7714269  0.3801797 -12.550  < 2e-16 ***
HhSize        0.1659000  0.0580455   2.858 0.004262 ** 
LogIncome     0.2005961  0.0431549   4.648 3.35e-06 ***
BusEqRevMiPC -0.0061588  0.0008645  -7.124 1.05e-12 ***
LogDvmt      -0.0399911  0.0495553  -0.807 0.419667    
Age0to14      0.0452030  0.0599542   0.754 0.450874    
Age15to19     0.2071621  0.0717224   2.888 0.003872 ** 
Age20to29     0.2301415  0.0614262   3.747 0.000179 ***
Age30to54     0.1713018  0.0483194   3.545 0.000392 ***
Age65Plus    -0.0756433  0.0613729  -1.233 0.217755    
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
-2.4410 -0.3567 -0.2792 -0.2273 57.2899 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.892863   0.017446  337.79   <2e-16 ***
HhSize       0.242403   0.002575   94.12   <2e-16 ***
LogIncome    0.033319   0.002125   15.68   <2e-16 ***
LogDvmt     -0.386874   0.003251 -118.99   <2e-16 ***
Age0to14    -0.289411   0.002742 -105.55   <2e-16 ***
Age15to19   -0.092276   0.003160  -29.21   <2e-16 ***
Age20to29    0.095855   0.002578   37.18   <2e-16 ***
Age30to54    0.024656   0.002280   10.82   <2e-16 ***
Age65Plus   -0.033828   0.002863  -11.81   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62257    0.27756 -16.654  < 2e-16 ***
HhSize       0.21579    0.04552   4.740 2.13e-06 ***
LogIncome    0.19358    0.03287   5.890 3.87e-09 ***
LogDvmt     -0.12149    0.05762  -2.109  0.03499 *  
Age0to14    -0.05068    0.04528  -1.119  0.26303    
Age15to19    0.18240    0.05279   3.455  0.00055 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17485    0.03476   5.031 4.89e-07 ***
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
-3.8987 -0.3420 -0.2262 -0.1478 34.7479 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.043e-02 577.764  < 2e-16 ***
HhSize        1.346e-02  6.684e-04  20.139  < 2e-16 ***
LogIncome     5.795e-02  1.000e-03  57.946  < 2e-16 ***
LogDensity    4.496e-02  5.878e-04  76.488  < 2e-16 ***
BusEqRevMiPC  1.889e-03  2.541e-05  74.331  < 2e-16 ***
LogDvmt      -9.586e-02  1.004e-03 -95.429  < 2e-16 ***
Urban         3.456e-02  1.076e-03  32.132  < 2e-16 ***
Age15to19    -1.214e-03  1.207e-03  -1.006    0.314    
Age20to29     6.579e-02  1.333e-03  49.365  < 2e-16 ***
Age30to54     4.877e-02  1.262e-03  38.661  < 2e-16 ***
Age65Plus     8.664e-03  1.662e-03   5.212 1.87e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1773011  0.4117928 -10.144  < 2e-16 ***
HhSize        0.5180275  0.0245819  21.074  < 2e-16 ***
LogIncome     0.3440441  0.0403468   8.527  < 2e-16 ***
LogDensity   -0.0393359  0.0214123  -1.837 0.066199 .  
BusEqRevMiPC  0.0097825  0.0008813  11.100  < 2e-16 ***
LogDvmt      -1.0653838  0.0416316 -25.591  < 2e-16 ***
Urban         0.0717128  0.0400029   1.793 0.073023 .  
Age15to19     0.3071333  0.0470241   6.531 6.52e-11 ***
Age20to29     0.1942009  0.0521221   3.726 0.000195 ***
Age30to54     0.3876785  0.0466769   8.306  < 2e-16 ***
Age65Plus    -0.5824153  0.0644622  -9.035  < 2e-16 ***
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
-6.3320 -0.2401 -0.1568 -0.1048 45.1927 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7699909  0.0105607 641.058   <2e-16 ***
HhSize       0.0532011  0.0018395  28.922   <2e-16 ***
LogIncome    0.0587987  0.0012724  46.212   <2e-16 ***
LogDensity  -0.0124122  0.0004656 -26.659   <2e-16 ***
LogDvmt     -0.1352333  0.0019885 -68.007   <2e-16 ***
Age0to14    -0.0084007  0.0018218  -4.611    4e-06 ***
Age15to19    0.0236124  0.0020681  11.417   <2e-16 ***
Age20to29   -0.0322994  0.0021757 -14.845   <2e-16 ***
Age30to54   -0.0274337  0.0017203 -15.947   <2e-16 ***
Age65Plus   -0.0709612  0.0027659 -25.656   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.43871    0.35056  -4.104 4.06e-05 ***
HhSize       0.49005    0.06451   7.597 3.04e-14 ***
LogIncome    0.23204    0.04345   5.341 9.25e-08 ***
LogDensity  -0.17532    0.01442 -12.160  < 2e-16 ***
LogDvmt     -1.27442    0.06936 -18.375  < 2e-16 ***
Age0to14     0.25484    0.06337   4.022 5.78e-05 ***
Age15to19    0.38522    0.07126   5.406 6.46e-08 ***
Age20to29    0.07000    0.07214   0.970    0.332    
Age30to54    0.53285    0.05692   9.361  < 2e-16 ***
Age65Plus   -0.60607    0.08592  -7.054 1.74e-12 ***
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
