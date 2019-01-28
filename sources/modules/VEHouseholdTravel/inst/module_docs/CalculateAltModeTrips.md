
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
-4.7363 -1.3364 -0.5989  0.5861 32.2132 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.587e+00  6.696e-03  684.92   <2e-16 ***
HhSize        3.170e-01  8.368e-04  378.82   <2e-16 ***
LogIncome     1.417e-01  6.558e-04  216.05   <2e-16 ***
LogDensity   -3.857e-03  3.343e-04  -11.54   <2e-16 ***
BusEqRevMiPC  1.633e-03  1.302e-05  125.47   <2e-16 ***
Urban         4.589e-02  6.120e-04   74.97   <2e-16 ***
LogDvmt      -2.185e-01  7.168e-04 -304.89   <2e-16 ***
Age0to14     -3.256e-01  9.078e-04 -358.62   <2e-16 ***
Age15to19    -8.739e-02  1.099e-03  -79.54   <2e-16 ***
Age20to29     4.691e-02  9.317e-04   50.35   <2e-16 ***
Age30to54     2.093e-02  7.154e-04   29.25   <2e-16 ***
Age65Plus    -3.502e-02  8.485e-04  -41.28   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2793005  0.2614212  -8.719  < 2e-16 ***
HhSize        0.4592103  0.0385263  11.919  < 2e-16 ***
LogIncome     0.2794072  0.0259957  10.748  < 2e-16 ***
LogDensity    0.0234283  0.0137744   1.701 0.088969 .  
BusEqRevMiPC -0.0038101  0.0005493  -6.937 4.01e-12 ***
Urban         0.0644650  0.0260828   2.472 0.013453 *  
LogDvmt      -0.2552108  0.0313187  -8.149 3.67e-16 ***
Age0to14     -0.3714654  0.0422584  -8.790  < 2e-16 ***
Age15to19    -0.1961172  0.0555804  -3.529 0.000418 ***
Age20to29     0.0930120  0.0428984   2.168 0.030144 *  
Age30to54     0.0649039  0.0309901   2.094 0.036230 *  
Age65Plus    -0.0372785  0.0344147  -1.083 0.278713    
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
-2.9711 -1.2632 -0.5842  0.5359 34.5808 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1534755  0.0044802 1373.48   <2e-16 ***
HhSize       0.3302560  0.0006749  489.35   <2e-16 ***
LogIncome   -0.0238922  0.0005586  -42.77   <2e-16 ***
LogDensity  -0.0376924  0.0001841 -204.68   <2e-16 ***
LogDvmt     -0.0411890  0.0010332  -39.87   <2e-16 ***
Age0to14    -0.3605333  0.0007034 -512.56   <2e-16 ***
Age15to19   -0.1465124  0.0008402 -174.39   <2e-16 ***
Age20to29    0.0241410  0.0006777   35.62   <2e-16 ***
Age30to54   -0.0190293  0.0005360  -35.50   <2e-16 ***
Age65Plus   -0.0301561  0.0006138  -49.13   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498891   0.159757  -3.123  0.00179 ** 
HhSize       0.144937   0.029158   4.971 6.67e-07 ***
LogIncome    0.057936   0.019811   2.924  0.00345 ** 
LogDensity  -0.034507   0.006875  -5.020 5.18e-07 ***
LogDvmt      0.118156   0.036118   3.271  0.00107 ** 
Age0to14    -0.190425   0.030047  -6.337 2.34e-10 ***
Age15to19    0.021302   0.038482   0.554  0.57988    
Age20to29    0.092778   0.028744   3.228  0.00125 ** 
Age30to54    0.064029   0.021311   3.005  0.00266 ** 
Age65Plus   -0.049834   0.023213  -2.147  0.03181 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1247 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.330e+00  2.473e-02  255.92   <2e-16 ***
HhSize        1.105e-01  4.271e-03   25.89   <2e-16 ***
LogIncome    -6.742e-02  2.903e-03  -23.22   <2e-16 ***
BusEqRevMiPC -2.240e-03  6.018e-05  -37.22   <2e-16 ***
LogDvmt      -1.699e-01  3.328e-03  -51.07   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.24   <2e-16 ***
Age15to19    -1.357e-01  5.291e-03  -25.64   <2e-16 ***
Age20to29     7.885e-02  4.425e-03   17.82   <2e-16 ***
Age30to54     7.899e-02  3.618e-03   21.83   <2e-16 ***
Age65Plus     4.915e-02  4.317e-03   11.38   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7718610  0.3801668 -12.552  < 2e-16 ***
HhSize        0.1659550  0.0580368   2.859 0.004243 ** 
LogIncome     0.2007064  0.0431595   4.650 3.31e-06 ***
BusEqRevMiPC -0.0061606  0.0008648  -7.124 1.05e-12 ***
LogDvmt      -0.0401912  0.0495493  -0.811 0.417287    
Age0to14      0.0451737  0.0599488   0.754 0.451127    
Age15to19     0.2071366  0.0717197   2.888 0.003875 ** 
Age20to29     0.2301445  0.0614262   3.747 0.000179 ***
Age30to54     0.1713056  0.0483193   3.545 0.000392 ***
Age65Plus    -0.0756540  0.0613721  -1.233 0.217684    
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
-2.4411 -0.3567 -0.2792 -0.2273 57.2923 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.893215   0.017445  337.81   <2e-16 ***
HhSize       0.242475   0.002576   94.14   <2e-16 ***
LogIncome    0.033273   0.002125   15.65   <2e-16 ***
LogDvmt     -0.387001   0.003254 -118.94   <2e-16 ***
Age0to14    -0.289403   0.002742 -105.55   <2e-16 ***
Age15to19   -0.092268   0.003159  -29.20   <2e-16 ***
Age20to29    0.095937   0.002578   37.21   <2e-16 ***
Age30to54    0.024687   0.002280   10.83   <2e-16 ***
Age65Plus   -0.033853   0.002863  -11.82   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62252    0.27756 -16.654  < 2e-16 ***
HhSize       0.21582    0.04553   4.740 2.14e-06 ***
LogIncome    0.19357    0.03287   5.889 3.88e-09 ***
LogDvmt     -0.12153    0.05766  -2.108 0.035064 *  
Age0to14    -0.05069    0.04529  -1.119 0.262985    
Age15to19    0.18238    0.05279   3.455 0.000551 ***
Age20to29    0.25784    0.04318   5.971 2.35e-09 ***
Age30to54    0.17486    0.03476   5.031 4.88e-07 ***
Age65Plus   -0.18271    0.04441  -4.114 3.89e-05 ***
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
-3.8968 -0.3421 -0.2262 -0.1478 34.7303 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.043e-02 577.711  < 2e-16 ***
HhSize        1.344e-02  6.683e-04  20.109  < 2e-16 ***
LogIncome     5.794e-02  1.000e-03  57.922  < 2e-16 ***
LogDensity    4.500e-02  5.877e-04  76.559  < 2e-16 ***
BusEqRevMiPC  1.888e-03  2.542e-05  74.275  < 2e-16 ***
LogDvmt      -9.576e-02  1.004e-03 -95.372  < 2e-16 ***
Urban         3.457e-02  1.076e-03  32.141  < 2e-16 ***
Age15to19    -1.225e-03  1.207e-03  -1.015     0.31    
Age20to29     6.575e-02  1.333e-03  49.336  < 2e-16 ***
Age30to54     4.873e-02  1.262e-03  38.630  < 2e-16 ***
Age65Plus     8.654e-03  1.662e-03   5.206 1.93e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1787741  0.4118118 -10.147  < 2e-16 ***
HhSize        0.5179044  0.0245805  21.070  < 2e-16 ***
LogIncome     0.3441221  0.0403513   8.528  < 2e-16 ***
LogDensity   -0.0391606  0.0214101  -1.829   0.0674 .  
BusEqRevMiPC  0.0097673  0.0008814  11.081  < 2e-16 ***
LogDvmt      -1.0648682  0.0416150 -25.589  < 2e-16 ***
Urban         0.0717683  0.0400021   1.794   0.0728 .  
Age15to19     0.3070223  0.0470223   6.529 6.61e-11 ***
Age20to29     0.1938194  0.0521177   3.719   0.0002 ***
Age30to54     0.3873099  0.0466712   8.299  < 2e-16 ***
Age65Plus    -0.5824865  0.0644630  -9.036  < 2e-16 ***
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
-6.3322 -0.2400 -0.1568 -0.1048 45.1857 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7700308  0.0105606 641.062  < 2e-16 ***
HhSize       0.0532253  0.0018396  28.933  < 2e-16 ***
LogIncome    0.0587849  0.0012724  46.199  < 2e-16 ***
LogDensity  -0.0123951  0.0004655 -26.627  < 2e-16 ***
LogDvmt     -0.1352913  0.0019901 -67.981  < 2e-16 ***
Age0to14    -0.0083929  0.0018218  -4.607 4.08e-06 ***
Age15to19    0.0236070  0.0020681  11.415  < 2e-16 ***
Age20to29   -0.0322694  0.0021758 -14.831  < 2e-16 ***
Age30to54   -0.0274214  0.0017203 -15.940  < 2e-16 ***
Age65Plus   -0.0709477  0.0027659 -25.651  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.43907    0.35056  -4.105 4.04e-05 ***
HhSize       0.49046    0.06451   7.602 2.90e-14 ***
LogIncome    0.23203    0.04345   5.340 9.28e-08 ***
LogDensity  -0.17518    0.01441 -12.153  < 2e-16 ***
LogDvmt     -1.27516    0.06941 -18.372  < 2e-16 ***
Age0to14     0.25476    0.06337   4.021 5.81e-05 ***
Age15to19    0.38510    0.07126   5.404 6.51e-08 ***
Age20to29    0.07019    0.07214   0.973    0.331    
Age30to54    0.53296    0.05692   9.363  < 2e-16 ***
Age65Plus   -0.60621    0.08592  -7.055 1.72e-12 ***
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
