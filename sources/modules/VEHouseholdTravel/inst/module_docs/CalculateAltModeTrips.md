
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
-4.7387 -1.3363 -0.5989  0.5862 32.2166 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.587e+00  6.696e-03  684.98   <2e-16 ***
HhSize        3.172e-01  8.369e-04  379.00   <2e-16 ***
LogIncome     1.419e-01  6.561e-04  216.28   <2e-16 ***
LogDensity   -3.948e-03  3.344e-04  -11.81   <2e-16 ***
BusEqRevMiPC  1.631e-03  1.302e-05  125.34   <2e-16 ***
Urban         4.585e-02  6.120e-04   74.92   <2e-16 ***
LogDvmt      -2.191e-01  7.184e-04 -305.04   <2e-16 ***
Age0to14     -3.256e-01  9.078e-04 -358.66   <2e-16 ***
Age15to19    -8.751e-02  1.099e-03  -79.64   <2e-16 ***
Age20to29     4.692e-02  9.317e-04   50.36   <2e-16 ***
Age30to54     2.095e-02  7.154e-04   29.29   <2e-16 ***
Age65Plus    -3.512e-02  8.485e-04  -41.39   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2792453  0.2614226  -8.719  < 2e-16 ***
HhSize        0.4596747  0.0385392  11.927  < 2e-16 ***
LogIncome     0.2798387  0.0260111  10.758  < 2e-16 ***
LogDensity    0.0232575  0.0137791   1.688  0.09143 .  
BusEqRevMiPC -0.0038134  0.0005493  -6.942 3.85e-12 ***
Urban         0.0643980  0.0260833   2.469  0.01355 *  
LogDvmt      -0.2562923  0.0313965  -8.163 3.27e-16 ***
Age0to14     -0.3716885  0.0422624  -8.795  < 2e-16 ***
Age15to19    -0.1964186  0.0555848  -3.534  0.00041 ***
Age20to29     0.0930283  0.0428987   2.169  0.03012 *  
Age30to54     0.0649375  0.0309904   2.095  0.03613 *  
Age65Plus    -0.0374375  0.0344162  -1.088  0.27669    
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
-2.9712 -1.2632 -0.5842  0.5359 34.5820 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1534713  0.0044802 1373.49   <2e-16 ***
HhSize       0.3303354  0.0006748  489.51   <2e-16 ***
LogIncome   -0.0237957  0.0005586  -42.60   <2e-16 ***
LogDensity  -0.0377183  0.0001842 -204.76   <2e-16 ***
LogDvmt     -0.0414490  0.0010328  -40.13   <2e-16 ***
Age0to14    -0.3605589  0.0007032 -512.72   <2e-16 ***
Age15to19   -0.1465365  0.0008401 -174.42   <2e-16 ***
Age20to29    0.0241529  0.0006777   35.64   <2e-16 ***
Age30to54   -0.0190261  0.0005360  -35.49   <2e-16 ***
Age65Plus   -0.0301507  0.0006137  -49.13   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498882   0.159757  -3.123  0.00179 ** 
HhSize       0.144963   0.029152   4.973 6.60e-07 ***
LogIncome    0.057930   0.019809   2.924  0.00345 ** 
LogDensity  -0.034486   0.006877  -5.015 5.31e-07 ***
LogDvmt      0.118111   0.036091   3.273  0.00107 ** 
Age0to14    -0.190507   0.030039  -6.342 2.27e-10 ***
Age15to19    0.021271   0.038480   0.553  0.58042    
Age20to29    0.092797   0.028744   3.228  0.00124 ** 
Age30to54    0.064058   0.021310   3.006  0.00265 ** 
Age65Plus   -0.049910   0.023209  -2.150  0.03152 *  
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
-1.2356 -0.3524 -0.2790 -0.2282 34.1388 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.330e+00  2.474e-02  255.90   <2e-16 ***
HhSize        1.107e-01  4.271e-03   25.92   <2e-16 ***
LogIncome    -6.732e-02  2.904e-03  -23.18   <2e-16 ***
BusEqRevMiPC -2.238e-03  6.018e-05  -37.19   <2e-16 ***
LogDvmt      -1.703e-01  3.333e-03  -51.08   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.23   <2e-16 ***
Age15to19    -1.357e-01  5.291e-03  -25.64   <2e-16 ***
Age20to29     7.882e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.884e-02  3.618e-03   21.80   <2e-16 ***
Age65Plus     4.900e-02  4.318e-03   11.35   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7722776  0.3801883 -12.552  < 2e-16 ***
HhSize        0.1660388  0.0580463   2.860 0.004230 ** 
LogIncome     0.2008101  0.0431769   4.651 3.31e-06 ***
BusEqRevMiPC -0.0061617  0.0008648  -7.125 1.04e-12 ***
LogDvmt      -0.0404155  0.0496324  -0.814 0.415475    
Age0to14      0.0451343  0.0599487   0.753 0.451520    
Age15to19     0.2070883  0.0717223   2.887 0.003885 ** 
Age20to29     0.2301420  0.0614263   3.747 0.000179 ***
Age30to54     0.1713139  0.0483195   3.545 0.000392 ***
Age65Plus    -0.0756841  0.0613736  -1.233 0.217512    
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
-2.4414 -0.3567 -0.2792 -0.2273 57.2731 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.892085   0.017447  337.72   <2e-16 ***
HhSize       0.242517   0.002575   94.17   <2e-16 ***
LogIncome    0.033356   0.002125   15.70   <2e-16 ***
LogDvmt     -0.386921   0.003249 -119.10   <2e-16 ***
Age0to14    -0.289267   0.002742 -105.51   <2e-16 ***
Age15to19   -0.092276   0.003159  -29.21   <2e-16 ***
Age20to29    0.095820   0.002578   37.17   <2e-16 ***
Age30to54    0.024577   0.002279   10.78   <2e-16 ***
Age65Plus   -0.033616   0.002863  -11.74   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62272    0.27756 -16.655  < 2e-16 ***
HhSize       0.21591    0.04553   4.743 2.11e-06 ***
LogIncome    0.19366    0.03286   5.893 3.80e-09 ***
LogDvmt     -0.12175    0.05761  -2.113 0.034558 *  
Age0to14    -0.05069    0.04527  -1.120 0.262897    
Age15to19    0.18236    0.05279   3.455 0.000551 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17484    0.03476   5.031 4.89e-07 ***
Age65Plus   -0.18266    0.04440  -4.114 3.89e-05 ***
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
-3.8996 -0.3420 -0.2262 -0.1478 34.7525 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.813  < 2e-16 ***
HhSize        1.353e-02  6.686e-04  20.239  < 2e-16 ***
LogIncome     5.805e-02  1.001e-03  58.010  < 2e-16 ***
LogDensity    4.493e-02  5.880e-04  76.414  < 2e-16 ***
BusEqRevMiPC  1.887e-03  2.542e-05  74.226  < 2e-16 ***
LogDvmt      -9.609e-02  1.007e-03 -95.450  < 2e-16 ***
Urban         3.455e-02  1.076e-03  32.122  < 2e-16 ***
Age15to19    -1.269e-03  1.207e-03  -1.051    0.293    
Age20to29     6.575e-02  1.333e-03  49.339  < 2e-16 ***
Age30to54     4.875e-02  1.262e-03  38.644  < 2e-16 ***
Age65Plus     8.616e-03  1.662e-03   5.183 2.19e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1753933  0.4117674 -10.140  < 2e-16 ***
HhSize        0.5186684  0.0245904  21.092  < 2e-16 ***
LogIncome     0.3449375  0.0403699   8.544  < 2e-16 ***
LogDensity   -0.0395835  0.0214157  -1.848 0.064552 .  
BusEqRevMiPC  0.0097616  0.0008815  11.074  < 2e-16 ***
LogDvmt      -1.0676065  0.0417205 -25.589  < 2e-16 ***
Urban         0.0716112  0.0400027   1.790 0.073429 .  
Age15to19     0.3065892  0.0470244   6.520 7.04e-11 ***
Age20to29     0.1938971  0.0521199   3.720 0.000199 ***
Age30to54     0.3875008  0.0466733   8.302  < 2e-16 ***
Age65Plus    -0.5828490  0.0644605  -9.042  < 2e-16 ***
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
-6.3380 -0.2401 -0.1567 -0.1049 45.2304 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7697416  0.0105609 641.020  < 2e-16 ***
HhSize       0.0532612  0.0018395  28.954  < 2e-16 ***
LogIncome    0.0588227  0.0012720  46.243  < 2e-16 ***
LogDensity  -0.0124287  0.0004656 -26.694  < 2e-16 ***
LogDvmt     -0.1352792  0.0019869 -68.085  < 2e-16 ***
Age0to14    -0.0083565  0.0018217  -4.587 4.49e-06 ***
Age15to19    0.0235919  0.0020681  11.407  < 2e-16 ***
Age20to29   -0.0323137  0.0021757 -14.852  < 2e-16 ***
Age30to54   -0.0274461  0.0017202 -15.955  < 2e-16 ***
Age65Plus   -0.0709375  0.0027658 -25.648  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44031    0.35058  -4.108 3.99e-05 ***
HhSize       0.49051    0.06451   7.604 2.88e-14 ***
LogIncome    0.23218    0.04344   5.345 9.03e-08 ***
LogDensity  -0.17544    0.01442 -12.168  < 2e-16 ***
LogDvmt     -1.27472    0.06929 -18.396  < 2e-16 ***
Age0to14     0.25532    0.06336   4.030 5.59e-05 ***
Age15to19    0.38513    0.07126   5.404 6.51e-08 ***
Age20to29    0.06992    0.07214   0.969    0.332    
Age30to54    0.53259    0.05692   9.357  < 2e-16 ***
Age65Plus   -0.60573    0.08593  -7.049 1.80e-12 ***
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
