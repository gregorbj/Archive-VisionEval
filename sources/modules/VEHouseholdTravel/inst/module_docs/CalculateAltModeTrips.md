
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
-4.7376 -1.3363 -0.5987  0.5858 32.2123 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.586e+00  6.697e-03  684.76   <2e-16 ***
HhSize        3.170e-01  8.368e-04  378.85   <2e-16 ***
LogIncome     1.418e-01  6.560e-04  216.14   <2e-16 ***
LogDensity   -3.859e-03  3.343e-04  -11.55   <2e-16 ***
BusEqRevMiPC  1.631e-03  1.302e-05  125.29   <2e-16 ***
Urban         4.590e-02  6.120e-04   75.00   <2e-16 ***
LogDvmt      -2.186e-01  7.169e-04 -304.90   <2e-16 ***
Age0to14     -3.255e-01  9.078e-04 -358.59   <2e-16 ***
Age15to19    -8.742e-02  1.099e-03  -79.57   <2e-16 ***
Age20to29     4.688e-02  9.317e-04   50.32   <2e-16 ***
Age30to54     2.090e-02  7.154e-04   29.22   <2e-16 ***
Age65Plus    -3.499e-02  8.485e-04  -41.24   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2805329  0.2614322  -8.723  < 2e-16 ***
HhSize        0.4594219  0.0385300  11.924  < 2e-16 ***
LogIncome     0.2796987  0.0260046  10.756  < 2e-16 ***
LogDensity    0.0233631  0.0137744   1.696 0.089862 .  
BusEqRevMiPC -0.0038142  0.0005493  -6.943 3.83e-12 ***
Urban         0.0644516  0.0260826   2.471 0.013471 *  
LogDvmt      -0.2556245  0.0313279  -8.160 3.36e-16 ***
Age0to14     -0.3715488  0.0422589  -8.792  < 2e-16 ***
Age15to19    -0.1962645  0.0555821  -3.531 0.000414 ***
Age20to29     0.0929914  0.0428984   2.168 0.030181 *  
Age30to54     0.0648868  0.0309902   2.094 0.036279 *  
Age65Plus    -0.0372805  0.0344146  -1.083 0.278686    
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
-2.9709 -1.2632 -0.5842  0.5359 34.5828 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1533175  0.0044802 1373.46   <2e-16 ***
HhSize       0.3303210  0.0006749  489.46   <2e-16 ***
LogIncome   -0.0237953  0.0005590  -42.57   <2e-16 ***
LogDensity  -0.0377174  0.0001842 -204.72   <2e-16 ***
LogDvmt     -0.0414023  0.0010331  -40.08   <2e-16 ***
Age0to14    -0.3605731  0.0007034 -512.62   <2e-16 ***
Age15to19   -0.1465335  0.0008401 -174.42   <2e-16 ***
Age20to29    0.0241539  0.0006777   35.64   <2e-16 ***
Age30to54   -0.0190211  0.0005360  -35.48   <2e-16 ***
Age65Plus   -0.0301652  0.0006138  -49.15   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498486   0.159756  -3.120  0.00181 ** 
HhSize       0.144739   0.029155   4.964 6.89e-07 ***
LogIncome    0.057694   0.019821   2.911  0.00361 ** 
LogDensity  -0.034431   0.006879  -5.006 5.57e-07 ***
LogDvmt      0.118678   0.036109   3.287  0.00101 ** 
Age0to14    -0.190294   0.030046  -6.333 2.40e-10 ***
Age15to19    0.021394   0.038481   0.556  0.57823    
Age20to29    0.092757   0.028744   3.227  0.00125 ** 
Age30to54    0.064017   0.021311   3.004  0.00266 ** 
Age65Plus   -0.049806   0.023212  -2.146  0.03190 *  
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
-1.2356 -0.3524 -0.2790 -0.2282 34.1415 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.329e+00  2.474e-02  255.82   <2e-16 ***
HhSize        1.106e-01  4.271e-03   25.90   <2e-16 ***
LogIncome    -6.726e-02  2.904e-03  -23.16   <2e-16 ***
BusEqRevMiPC -2.241e-03  6.019e-05  -37.23   <2e-16 ***
LogDvmt      -1.701e-01  3.328e-03  -51.12   <2e-16 ***
Age0to14     -1.938e-01  4.480e-03  -43.25   <2e-16 ***
Age15to19    -1.357e-01  5.291e-03  -25.65   <2e-16 ***
Age20to29     7.883e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.886e-02  3.618e-03   21.80   <2e-16 ***
Age65Plus     4.915e-02  4.317e-03   11.38   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7725057  0.3802248 -12.552  < 2e-16 ***
HhSize        0.1660417  0.0580390   2.861 0.004225 ** 
LogIncome     0.2008321  0.0431717   4.652 3.29e-06 ***
BusEqRevMiPC -0.0061623  0.0008649  -7.125 1.04e-12 ***
LogDvmt      -0.0404086  0.0495529  -0.815 0.414806    
Age0to14      0.0451262  0.0599472   0.753 0.451590    
Age15to19     0.2070876  0.0717205   2.887 0.003884 ** 
Age20to29     0.2301395  0.0614263   3.747 0.000179 ***
Age30to54     0.1713087  0.0483192   3.545 0.000392 ***
Age65Plus    -0.0756698  0.0613717  -1.233 0.217585    
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
-2.4410 -0.3567 -0.2792 -0.2273 57.2849 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.890966   0.017449  337.61   <2e-16 ***
HhSize       0.242517   0.002576   94.16   <2e-16 ***
LogIncome    0.033470   0.002126   15.74   <2e-16 ***
LogDvmt     -0.386927   0.003251 -119.02   <2e-16 ***
Age0to14    -0.289471   0.002742 -105.57   <2e-16 ***
Age15to19   -0.092295   0.003159  -29.21   <2e-16 ***
Age20to29    0.095842   0.002578   37.17   <2e-16 ***
Age30to54    0.024651   0.002280   10.81   <2e-16 ***
Age65Plus   -0.033797   0.002863  -11.80   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62312    0.27758 -16.655  < 2e-16 ***
HhSize       0.21578    0.04553   4.740 2.14e-06 ***
LogIncome    0.19359    0.03288   5.888 3.90e-09 ***
LogDvmt     -0.12138    0.05761  -2.107 0.035121 *  
Age0to14    -0.05067    0.04528  -1.119 0.263156    
Age15to19    0.18241    0.05279   3.455 0.000549 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17485    0.03476   5.031 4.89e-07 ***
Age65Plus   -0.18267    0.04441  -4.114 3.90e-05 ***
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
-3.8965 -0.3420 -0.2262 -0.1478 34.7474 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.044e-02 577.628  < 2e-16 ***
HhSize        1.349e-02  6.685e-04  20.174  < 2e-16 ***
LogIncome     5.802e-02  1.001e-03  57.986  < 2e-16 ***
LogDensity    4.498e-02  5.878e-04  76.523  < 2e-16 ***
BusEqRevMiPC  1.887e-03  2.542e-05  74.213  < 2e-16 ***
LogDvmt      -9.585e-02  1.004e-03 -95.427  < 2e-16 ***
Urban         3.458e-02  1.076e-03  32.145  < 2e-16 ***
Age15to19    -1.254e-03  1.207e-03  -1.039    0.299    
Age20to29     6.572e-02  1.333e-03  49.318  < 2e-16 ***
Age30to54     4.872e-02  1.261e-03  38.618  < 2e-16 ***
Age65Plus     8.650e-03  1.662e-03   5.203 1.96e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1834470  0.4118517 -10.158  < 2e-16 ***
HhSize        0.5182825  0.0245853  21.081  < 2e-16 ***
LogIncome     0.3447841  0.0403658   8.541  < 2e-16 ***
LogDensity   -0.0392260  0.0214105  -1.832 0.066938 .  
BusEqRevMiPC  0.0097553  0.0008815  11.066  < 2e-16 ***
LogDvmt      -1.0654061  0.0416278 -25.594  < 2e-16 ***
Urban         0.0718093  0.0400023   1.795 0.072634 .  
Age15to19     0.3067230  0.0470232   6.523  6.9e-11 ***
Age20to29     0.1936000  0.0521180   3.715 0.000203 ***
Age30to54     0.3871743  0.0466706   8.296  < 2e-16 ***
Age65Plus    -0.5824753  0.0644638  -9.036  < 2e-16 ***
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
-6.3321 -0.2401 -0.1568 -0.1049 45.2014 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7695404  0.0105613 640.974  < 2e-16 ***
HhSize       0.0532209  0.0018396  28.931  < 2e-16 ***
LogIncome    0.0588363  0.0012727  46.229  < 2e-16 ***
LogDensity  -0.0124261  0.0004657 -26.683  < 2e-16 ***
LogDvmt     -0.1352293  0.0019886 -68.003  < 2e-16 ***
Age0to14    -0.0084063  0.0018218  -4.614 3.95e-06 ***
Age15to19    0.0236069  0.0020681  11.415  < 2e-16 ***
Age20to29   -0.0322988  0.0021757 -14.845  < 2e-16 ***
Age30to54   -0.0274331  0.0017203 -15.947  < 2e-16 ***
Age65Plus   -0.0709449  0.0027659 -25.650  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44318    0.35059  -4.116 3.85e-05 ***
HhSize       0.49030    0.06451   7.600 2.96e-14 ***
LogIncome    0.23249    0.04346   5.349 8.82e-08 ***
LogDensity  -0.17549    0.01442 -12.169  < 2e-16 ***
LogDvmt     -1.27457    0.06936 -18.376  < 2e-16 ***
Age0to14     0.25478    0.06337   4.021 5.80e-05 ***
Age15to19    0.38523    0.07126   5.406 6.45e-08 ***
Age20to29    0.07010    0.07214   0.972    0.331    
Age30to54    0.53285    0.05692   9.361  < 2e-16 ***
Age65Plus   -0.60593    0.08592  -7.052 1.76e-12 ***
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
