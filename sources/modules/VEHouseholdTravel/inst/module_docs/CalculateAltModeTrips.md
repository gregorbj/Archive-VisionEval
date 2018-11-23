
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
-4.7356 -1.3363 -0.5991  0.5860 32.2157 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.586e+00  6.697e-03  684.79   <2e-16 ***
HhSize        3.170e-01  8.368e-04  378.83   <2e-16 ***
LogIncome     1.418e-01  6.560e-04  216.19   <2e-16 ***
LogDensity   -3.898e-03  3.343e-04  -11.66   <2e-16 ***
BusEqRevMiPC  1.632e-03  1.302e-05  125.41   <2e-16 ***
Urban         4.587e-02  6.120e-04   74.94   <2e-16 ***
LogDvmt      -2.186e-01  7.168e-04 -304.96   <2e-16 ***
Age0to14     -3.257e-01  9.079e-04 -358.73   <2e-16 ***
Age15to19    -8.739e-02  1.099e-03  -79.54   <2e-16 ***
Age20to29     4.694e-02  9.317e-04   50.39   <2e-16 ***
Age30to54     2.096e-02  7.154e-04   29.30   <2e-16 ***
Age65Plus    -3.508e-02  8.485e-04  -41.35   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2802156  0.2614298  -8.722  < 2e-16 ***
HhSize        0.4592796  0.0385247  11.922  < 2e-16 ***
LogIncome     0.2796889  0.0260061  10.755  < 2e-16 ***
LogDensity    0.0233320  0.0137767   1.694 0.090345 .  
BusEqRevMiPC -0.0038119  0.0005493  -6.940 3.92e-12 ***
Urban         0.0644134  0.0260833   2.470 0.013529 *  
LogDvmt      -0.2555157  0.0313218  -8.158 3.41e-16 ***
Age0to14     -0.3716541  0.0422613  -8.794  < 2e-16 ***
Age15to19    -0.1961492  0.0555800  -3.529 0.000417 ***
Age20to29     0.0930748  0.0428988   2.170 0.030034 *  
Age30to54     0.0649493  0.0309903   2.096 0.036101 *  
Age65Plus    -0.0373734  0.0344155  -1.086 0.277503    
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
-2.9712 -1.2632 -0.5842  0.5359 34.5829 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1532917  0.0044801 1373.46   <2e-16 ***
HhSize       0.3303387  0.0006747  489.62   <2e-16 ***
LogIncome   -0.0237732  0.0005587  -42.55   <2e-16 ***
LogDensity  -0.0377165  0.0001842 -204.81   <2e-16 ***
LogDvmt     -0.0414774  0.0010323  -40.18   <2e-16 ***
Age0to14    -0.3605813  0.0007033 -512.69   <2e-16 ***
Age15to19   -0.1465411  0.0008401 -174.43   <2e-16 ***
Age20to29    0.0241585  0.0006777   35.65   <2e-16 ***
Age30to54   -0.0190186  0.0005360  -35.48   <2e-16 ***
Age65Plus   -0.0301703  0.0006138  -49.15   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498301   0.159756  -3.119  0.00181 ** 
HhSize       0.145092   0.029148   4.978 6.43e-07 ***
LogIncome    0.057999   0.019813   2.927  0.00342 ** 
LogDensity  -0.034525   0.006875  -5.022 5.11e-07 ***
LogDvmt      0.117790   0.036073   3.265  0.00109 ** 
Age0to14    -0.190522   0.030044  -6.341 2.28e-10 ***
Age15to19    0.021223   0.038480   0.552  0.58127    
Age20to29    0.092795   0.028744   3.228  0.00125 ** 
Age30to54    0.064049   0.021310   3.006  0.00265 ** 
Age65Plus   -0.049891   0.023212  -2.149  0.03160 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1277 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.330e+00  2.474e-02  255.84   <2e-16 ***
HhSize        1.105e-01  4.271e-03   25.87   <2e-16 ***
LogIncome    -6.741e-02  2.904e-03  -23.21   <2e-16 ***
BusEqRevMiPC -2.237e-03  6.018e-05  -37.17   <2e-16 ***
LogDvmt      -1.698e-01  3.327e-03  -51.03   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.23   <2e-16 ***
Age15to19    -1.355e-01  5.291e-03  -25.61   <2e-16 ***
Age20to29     7.889e-02  4.425e-03   17.83   <2e-16 ***
Age30to54     7.885e-02  3.618e-03   21.80   <2e-16 ***
Age65Plus     4.903e-02  4.318e-03   11.36   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7718497  0.3802246 -12.550  < 2e-16 ***
HhSize        0.1659230  0.0580350   2.859 0.004250 ** 
LogIncome     0.2006869  0.0431722   4.649 3.34e-06 ***
BusEqRevMiPC -0.0061602  0.0008648  -7.123 1.05e-12 ***
LogDvmt      -0.0401175  0.0495480  -0.810 0.418130    
Age0to14      0.0451729  0.0599536   0.753 0.451171    
Age15to19     0.2071543  0.0717193   2.888 0.003872 ** 
Age20to29     0.2301491  0.0614262   3.747 0.000179 ***
Age30to54     0.1713079  0.0483195   3.545 0.000392 ***
Age65Plus    -0.0756575  0.0613730  -1.233 0.217670    
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
-2.4411 -0.3568 -0.2792 -0.2273 57.2891 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.891153   0.017449  337.62   <2e-16 ***
HhSize       0.242347   0.002575   94.10   <2e-16 ***
LogIncome    0.033332   0.002126   15.68   <2e-16 ***
LogDvmt     -0.386590   0.003249 -118.97   <2e-16 ***
Age0to14    -0.289353   0.002742 -105.53   <2e-16 ***
Age15to19   -0.092234   0.003160  -29.19   <2e-16 ***
Age20to29    0.095871   0.002578   37.19   <2e-16 ***
Age30to54    0.024625   0.002280   10.80   <2e-16 ***
Age65Plus   -0.033753   0.002863  -11.79   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62301    0.27758 -16.655  < 2e-16 ***
HhSize       0.21574    0.04552   4.739 2.15e-06 ***
LogIncome    0.19355    0.03287   5.888 3.91e-09 ***
LogDvmt     -0.12132    0.05761  -2.106 0.035220 *  
Age0to14    -0.05064    0.04528  -1.118 0.263440    
Age15to19    0.18243    0.05279   3.456 0.000549 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17484    0.03476   5.030 4.89e-07 ***
Age65Plus   -0.18267    0.04441  -4.113 3.90e-05 ***
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
-3.8965 -0.3421 -0.2262 -0.1478 34.6927 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.028e+00  1.044e-02 577.692  < 2e-16 ***
HhSize        1.335e-02  6.681e-04  19.984  < 2e-16 ***
LogIncome     5.791e-02  1.001e-03  57.874  < 2e-16 ***
LogDensity    4.501e-02  5.878e-04  76.566  < 2e-16 ***
BusEqRevMiPC  1.888e-03  2.542e-05  74.295  < 2e-16 ***
LogDvmt      -9.565e-02  1.004e-03 -95.253  < 2e-16 ***
Urban         3.457e-02  1.076e-03  32.141  < 2e-16 ***
Age15to19    -1.174e-03  1.207e-03  -0.972    0.331    
Age20to29     6.579e-02  1.333e-03  49.364  < 2e-16 ***
Age30to54     4.876e-02  1.262e-03  38.650  < 2e-16 ***
Age65Plus     8.682e-03  1.662e-03   5.223 1.76e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1809634  0.4118274 -10.152  < 2e-16 ***
HhSize        0.5171817  0.0245714  21.048  < 2e-16 ***
LogIncome     0.3442963  0.0403644   8.530  < 2e-16 ***
LogDensity   -0.0391814  0.0214123  -1.830 0.067272 .  
BusEqRevMiPC  0.0097685  0.0008814  11.083  < 2e-16 ***
LogDvmt      -1.0642069  0.0416124 -25.574  < 2e-16 ***
Urban         0.0717325  0.0400009   1.793 0.072929 .  
Age15to19     0.3075667  0.0470199   6.541  6.1e-11 ***
Age20to29     0.1942401  0.0521184   3.727 0.000194 ***
Age30to54     0.3875683  0.0466727   8.304  < 2e-16 ***
Age65Plus    -0.5823106  0.0644594  -9.034  < 2e-16 ***
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
-6.3327 -0.2401 -0.1567 -0.1048 45.2268 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7691611  0.0105618 640.909  < 2e-16 ***
HhSize       0.0532252  0.0018395  28.935  < 2e-16 ***
LogIncome    0.0588297  0.0012724  46.237  < 2e-16 ***
LogDensity  -0.0124038  0.0004655 -26.647  < 2e-16 ***
LogDvmt     -0.1351865  0.0019867 -68.047  < 2e-16 ***
Age0to14    -0.0084155  0.0018218  -4.619 3.85e-06 ***
Age15to19    0.0235966  0.0020681  11.410  < 2e-16 ***
Age20to29   -0.0323041  0.0021757 -14.848  < 2e-16 ***
Age30to54   -0.0274409  0.0017202 -15.952  < 2e-16 ***
Age65Plus   -0.0709810  0.0027659 -25.663  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44590    0.35060  -4.124 3.72e-05 ***
HhSize       0.49005    0.06451   7.596 3.04e-14 ***
LogIncome    0.23218    0.04345   5.344 9.10e-08 ***
LogDensity  -0.17520    0.01441 -12.155  < 2e-16 ***
LogDvmt     -1.27364    0.06928 -18.383  < 2e-16 ***
Age0to14     0.25489    0.06337   4.022 5.76e-05 ***
Age15to19    0.38522    0.07127   5.405 6.47e-08 ***
Age20to29    0.06995    0.07214   0.970    0.332    
Age30to54    0.53275    0.05692   9.359  < 2e-16 ***
Age65Plus   -0.60608    0.08593  -7.053 1.75e-12 ***
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
