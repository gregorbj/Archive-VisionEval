
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
-4.7388 -1.3364 -0.5988  0.5861 32.2109 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.587e+00  6.696e-03  685.06   <2e-16 ***
HhSize        3.172e-01  8.369e-04  379.02   <2e-16 ***
LogIncome     1.419e-01  6.561e-04  216.32   <2e-16 ***
LogDensity   -4.010e-03  3.344e-04  -11.99   <2e-16 ***
BusEqRevMiPC  1.630e-03  1.302e-05  125.21   <2e-16 ***
Urban         4.582e-02  6.120e-04   74.87   <2e-16 ***
LogDvmt      -2.192e-01  7.184e-04 -305.11   <2e-16 ***
Age0to14     -3.256e-01  9.078e-04 -358.67   <2e-16 ***
Age15to19    -8.750e-02  1.099e-03  -79.64   <2e-16 ***
Age20to29     4.693e-02  9.317e-04   50.37   <2e-16 ***
Age30to54     2.094e-02  7.154e-04   29.27   <2e-16 ***
Age65Plus    -3.509e-02  8.485e-04  -41.36   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2785502  0.2614170  -8.716  < 2e-16 ***
HhSize        0.4595833  0.0385386  11.925  < 2e-16 ***
LogIncome     0.2797310  0.0260111  10.754  < 2e-16 ***
LogDensity    0.0232402  0.0137823   1.686 0.091752 .  
BusEqRevMiPC -0.0038139  0.0005493  -6.943 3.85e-12 ***
Urban         0.0643887  0.0260837   2.469 0.013566 *  
LogDvmt      -0.2560735  0.0313954  -8.156 3.45e-16 ***
Age0to14     -0.3716249  0.0422618  -8.793  < 2e-16 ***
Age15to19    -0.1963399  0.0555840  -3.532 0.000412 ***
Age20to29     0.0930072  0.0428985   2.168 0.030153 *  
Age30to54     0.0649142  0.0309902   2.095 0.036201 *  
Age65Plus    -0.0373780  0.0344157  -1.086 0.277446    
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
-2.9717 -1.2631 -0.5841  0.5359 34.5836 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1532505  0.0044801 1373.46   <2e-16 ***
HhSize       0.3303951  0.0006745  489.87   <2e-16 ***
LogIncome   -0.0236777  0.0005589  -42.37   <2e-16 ***
LogDensity  -0.0377382  0.0001842 -204.89   <2e-16 ***
LogDvmt     -0.0417201  0.0010322  -40.42   <2e-16 ***
Age0to14    -0.3606106  0.0007032 -512.80   <2e-16 ***
Age15to19   -0.1465611  0.0008401 -174.46   <2e-16 ***
Age20to29    0.0241744  0.0006777   35.67   <2e-16 ***
Age30to54   -0.0190083  0.0005360  -35.46   <2e-16 ***
Age65Plus   -0.0301883  0.0006138  -49.18   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498213   0.159756  -3.119  0.00182 ** 
HhSize       0.145237   0.029136   4.985 6.21e-07 ***
LogIncome    0.058028   0.019817   2.928  0.00341 ** 
LogDensity  -0.034528   0.006876  -5.022 5.13e-07 ***
LogDvmt      0.117608   0.036067   3.261  0.00111 ** 
Age0to14    -0.190631   0.030038  -6.346 2.20e-10 ***
Age15to19    0.021144   0.038478   0.550  0.58266    
Age20to29    0.092806   0.028744   3.229  0.00124 ** 
Age30to54    0.064056   0.021310   3.006  0.00265 ** 
Age65Plus   -0.049913   0.023211  -2.150  0.03153 *  
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
-1.2356 -0.3524 -0.2790 -0.2282 34.1465 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.330e+00  2.473e-02  255.92   <2e-16 ***
HhSize        1.107e-01  4.271e-03   25.91   <2e-16 ***
LogIncome    -6.736e-02  2.904e-03  -23.19   <2e-16 ***
BusEqRevMiPC -2.239e-03  6.019e-05  -37.20   <2e-16 ***
LogDvmt      -1.702e-01  3.333e-03  -51.07   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.23   <2e-16 ***
Age15to19    -1.356e-01  5.291e-03  -25.64   <2e-16 ***
Age20to29     7.880e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.882e-02  3.618e-03   21.79   <2e-16 ***
Age65Plus     4.901e-02  4.318e-03   11.35   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.772448   0.380194 -12.553  < 2e-16 ***
HhSize        0.166063   0.058046   2.861 0.004224 ** 
LogIncome     0.200843   0.043175   4.652 3.29e-06 ***
BusEqRevMiPC -0.006162   0.000865  -7.125 1.04e-12 ***
LogDvmt      -0.040470   0.049615  -0.816 0.414686    
Age0to14      0.045117   0.059949   0.753 0.451690    
Age15to19     0.207078   0.071722   2.887 0.003886 ** 
Age20to29     0.230140   0.061426   3.747 0.000179 ***
Age30to54     0.171312   0.048319   3.545 0.000392 ***
Age65Plus    -0.075684   0.061373  -1.233 0.217511    
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
-2.4411 -0.3567 -0.2792 -0.2273 57.2793 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.890216   0.017451  337.54   <2e-16 ***
HhSize       0.242258   0.002575   94.08   <2e-16 ***
LogIncome    0.033480   0.002126   15.75   <2e-16 ***
LogDvmt     -0.386671   0.003249 -119.03   <2e-16 ***
Age0to14    -0.289282   0.002742 -105.50   <2e-16 ***
Age15to19   -0.092236   0.003160  -29.19   <2e-16 ***
Age20to29    0.095810   0.002578   37.16   <2e-16 ***
Age30to54    0.024601   0.002280   10.79   <2e-16 ***
Age65Plus   -0.033768   0.002863  -11.79   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62336    0.27758 -16.656  < 2e-16 ***
HhSize       0.21586    0.04551   4.744 2.10e-06 ***
LogIncome    0.19375    0.03288   5.893 3.79e-09 ***
LogDvmt     -0.12181    0.05758  -2.116  0.03439 *  
Age0to14    -0.05071    0.04527  -1.120  0.26270    
Age15to19    0.18237    0.05279   3.455  0.00055 ***
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
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", 
    link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-3.9010 -0.3419 -0.2261 -0.1478 34.7797 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.807  < 2e-16 ***
HhSize        1.357e-02  6.686e-04  20.289  < 2e-16 ***
LogIncome     5.814e-02  1.001e-03  58.095  < 2e-16 ***
LogDensity    4.488e-02  5.881e-04  76.311  < 2e-16 ***
BusEqRevMiPC  1.885e-03  2.542e-05  74.158  < 2e-16 ***
LogDvmt      -9.622e-02  1.007e-03 -95.566  < 2e-16 ***
Urban         3.454e-02  1.076e-03  32.105  < 2e-16 ***
Age15to19    -1.266e-03  1.207e-03  -1.049    0.294    
Age20to29     6.576e-02  1.333e-03  49.350  < 2e-16 ***
Age30to54     4.876e-02  1.262e-03  38.651  < 2e-16 ***
Age65Plus     8.615e-03  1.662e-03   5.182  2.2e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1739860  0.4117565 -10.137  < 2e-16 ***
HhSize        0.5187666  0.0245913  21.096  < 2e-16 ***
LogIncome     0.3452815  0.0403730   8.552  < 2e-16 ***
LogDensity   -0.0399626  0.0214195  -1.866 0.062082 .  
BusEqRevMiPC  0.0097531  0.0008816  11.063  < 2e-16 ***
LogDvmt      -1.0680961  0.0417252 -25.598  < 2e-16 ***
Urban         0.0714419  0.0400036   1.786 0.074118 .  
Age15to19     0.3066685  0.0470258   6.521 6.97e-11 ***
Age20to29     0.1940239  0.0521230   3.722 0.000197 ***
Age30to54     0.3875023  0.0466751   8.302  < 2e-16 ***
Age65Plus    -0.5827040  0.0644619  -9.040  < 2e-16 ***
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
-6.3331 -0.2401 -0.1567 -0.1048 45.2187 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7689425  0.0105621 640.872  < 2e-16 ***
HhSize       0.0531881  0.0018392  28.919  < 2e-16 ***
LogIncome    0.0588839  0.0012726  46.270  < 2e-16 ***
LogDensity  -0.0124233  0.0004656 -26.684  < 2e-16 ***
LogDvmt     -0.1352186  0.0019861 -68.082  < 2e-16 ***
Age0to14    -0.0083752  0.0018217  -4.597 4.28e-06 ***
Age15to19    0.0236213  0.0020681  11.422  < 2e-16 ***
Age20to29   -0.0323146  0.0021757 -14.853  < 2e-16 ***
Age30to54   -0.0274517  0.0017202 -15.959  < 2e-16 ***
Age65Plus   -0.0709873  0.0027659 -25.665  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44721    0.35061  -4.128 3.66e-05 ***
HhSize       0.48950    0.06450   7.589 3.23e-14 ***
LogIncome    0.23248    0.04346   5.350 8.81e-08 ***
LogDensity  -0.17532    0.01442 -12.161  < 2e-16 ***
LogDvmt     -1.27349    0.06927 -18.385  < 2e-16 ***
Age0to14     0.25534    0.06337   4.029 5.60e-05 ***
Age15to19    0.38549    0.07127   5.409 6.34e-08 ***
Age20to29    0.06986    0.07214   0.968    0.333    
Age30to54    0.53262    0.05692   9.357  < 2e-16 ***
Age65Plus   -0.60597    0.08593  -7.052 1.76e-12 ***
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
