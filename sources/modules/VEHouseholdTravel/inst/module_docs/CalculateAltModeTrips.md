
# CalculateAltModeTrips Module
### November 12, 2018

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
-4.7375 -1.3363 -0.5989  0.5856 32.2074 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.588e+00  6.696e-03  685.25   <2e-16 ***
HhSize        3.171e-01  8.368e-04  378.90   <2e-16 ***
LogIncome     1.417e-01  6.557e-04  216.08   <2e-16 ***
LogDensity   -3.934e-03  3.343e-04  -11.77   <2e-16 ***
BusEqRevMiPC  1.633e-03  1.301e-05  125.49   <2e-16 ***
Urban         4.586e-02  6.120e-04   74.93   <2e-16 ***
LogDvmt      -2.188e-01  7.172e-04 -305.03   <2e-16 ***
Age0to14     -3.257e-01  9.079e-04 -358.70   <2e-16 ***
Age15to19    -8.743e-02  1.099e-03  -79.58   <2e-16 ***
Age20to29     4.690e-02  9.317e-04   50.34   <2e-16 ***
Age30to54     2.091e-02  7.154e-04   29.23   <2e-16 ***
Age65Plus    -3.500e-02  8.485e-04  -41.25   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2771001  0.2614041  -8.711  < 2e-16 ***
HhSize        0.4593869  0.0385299  11.923  < 2e-16 ***
LogIncome     0.2794790  0.0259921  10.752  < 2e-16 ***
LogDensity    0.0233099  0.0137783   1.692 0.090687 .  
BusEqRevMiPC -0.0038103  0.0005492  -6.938 3.99e-12 ***
Urban         0.0644193  0.0260832   2.470 0.013520 *  
LogDvmt      -0.2556805  0.0313470  -8.156 3.45e-16 ***
Age0to14     -0.3716309  0.0422613  -8.794  < 2e-16 ***
Age15to19    -0.1962155  0.0555814  -3.530 0.000415 ***
Age20to29     0.0929967  0.0428984   2.168 0.030171 *  
Age30to54     0.0648930  0.0309902   2.094 0.036261 *  
Age65Plus    -0.0372712  0.0344146  -1.083 0.278806    
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
-2.9709 -1.2633 -0.5842  0.5359 34.5824 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1532043  0.0044802 1373.43   <2e-16 ***
HhSize       0.3302958  0.0006749  489.40   <2e-16 ***
LogIncome   -0.0238052  0.0005593  -42.56   <2e-16 ***
LogDensity  -0.0377061  0.0001842 -204.71   <2e-16 ***
LogDvmt     -0.0413585  0.0010342  -39.99   <2e-16 ***
Age0to14    -0.3605407  0.0007033 -512.65   <2e-16 ***
Age15to19   -0.1465255  0.0008401 -174.41   <2e-16 ***
Age20to29    0.0241486  0.0006777   35.63   <2e-16 ***
Age30to54   -0.0190243  0.0005360  -35.49   <2e-16 ***
Age65Plus   -0.0301616  0.0006138  -49.14   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498097   0.159756  -3.118  0.00182 ** 
HhSize       0.144813   0.029158   4.967 6.82e-07 ***
LogIncome    0.057707   0.019834   2.910  0.00362 ** 
LogDensity  -0.034466   0.006877  -5.012 5.38e-07 ***
LogDvmt      0.118581   0.036151   3.280  0.00104 ** 
Age0to14    -0.190390   0.030043  -6.337 2.34e-10 ***
Age15to19    0.021362   0.038482   0.555  0.57880    
Age20to29    0.092763   0.028744   3.227  0.00125 ** 
Age30to54    0.064022   0.021311   3.004  0.00266 ** 
Age65Plus   -0.049818   0.023213  -2.146  0.03186 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1297 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.331e+00  2.473e-02  256.04   <2e-16 ***
HhSize        1.106e-01  4.271e-03   25.90   <2e-16 ***
LogIncome    -6.746e-02  2.903e-03  -23.24   <2e-16 ***
BusEqRevMiPC -2.240e-03  6.018e-05  -37.22   <2e-16 ***
LogDvmt      -1.700e-01  3.329e-03  -51.08   <2e-16 ***
Age0to14     -1.938e-01  4.480e-03  -43.25   <2e-16 ***
Age15to19    -1.357e-01  5.291e-03  -25.65   <2e-16 ***
Age20to29     7.881e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.897e-02  3.618e-03   21.83   <2e-16 ***
Age65Plus     4.917e-02  4.317e-03   11.39   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7714994  0.3800806 -12.554  < 2e-16 ***
HhSize        0.1659419  0.0580401   2.859 0.004249 ** 
LogIncome     0.2006671  0.0431520   4.650 3.32e-06 ***
BusEqRevMiPC -0.0061601  0.0008647  -7.124 1.05e-12 ***
LogDvmt      -0.0401508  0.0495699  -0.810 0.417950    
Age0to14      0.0451747  0.0599521   0.754 0.451142    
Age15to19     0.2071446  0.0717203   2.888 0.003874 ** 
Age20to29     0.2301394  0.0614261   3.747 0.000179 ***
Age30to54     0.1712997  0.0483191   3.545 0.000392 ***
Age65Plus    -0.0756418  0.0613714  -1.233 0.217753    
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
-2.4410 -0.3567 -0.2792 -0.2273 57.2926 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.890363   0.017450  337.55   <2e-16 ***
HhSize       0.242494   0.002576   94.15   <2e-16 ***
LogIncome    0.033648   0.002127   15.82   <2e-16 ***
LogDvmt     -0.387317   0.003256 -118.96   <2e-16 ***
Age0to14    -0.289279   0.002742 -105.51   <2e-16 ***
Age15to19   -0.092276   0.003159  -29.21   <2e-16 ***
Age20to29    0.095892   0.002578   37.19   <2e-16 ***
Age30to54    0.024667   0.002280   10.82   <2e-16 ***
Age65Plus   -0.033815   0.002863  -11.81   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62329    0.27759 -16.655  < 2e-16 ***
HhSize       0.21573    0.04553   4.738 2.16e-06 ***
LogIncome    0.19360    0.03290   5.885 3.98e-09 ***
LogDvmt     -0.12138    0.05770  -2.104 0.035421 *  
Age0to14    -0.05059    0.04528  -1.117 0.263882    
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
hurdle(formula = ModelFormula, data = Data_df, dist = "poisson", zero.dist = "binomial", link = "logit")

Pearson residuals:
    Min      1Q  Median      3Q     Max 
-3.8978 -0.3420 -0.2262 -0.1478 34.7281 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.960  < 2e-16 ***
HhSize        1.342e-02  6.683e-04  20.078  < 2e-16 ***
LogIncome     5.789e-02  1.000e-03  57.884  < 2e-16 ***
LogDensity    4.496e-02  5.879e-04  76.477  < 2e-16 ***
BusEqRevMiPC  1.888e-03  2.542e-05  74.299  < 2e-16 ***
LogDvmt      -9.580e-02  1.005e-03 -95.352  < 2e-16 ***
Urban         3.457e-02  1.076e-03  32.137  < 2e-16 ***
Age15to19    -1.210e-03  1.207e-03  -1.002    0.316    
Age20to29     6.574e-02  1.333e-03  49.334  < 2e-16 ***
Age30to54     4.873e-02  1.262e-03  38.628  < 2e-16 ***
Age65Plus     8.700e-03  1.662e-03   5.233 1.66e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1681666  0.4117361 -10.123  < 2e-16 ***
HhSize        0.5178589  0.0245798  21.068  < 2e-16 ***
LogIncome     0.3439284  0.0403435   8.525  < 2e-16 ***
LogDensity   -0.0395487  0.0214150  -1.847 0.064780 .  
BusEqRevMiPC  0.0097697  0.0008814  11.084  < 2e-16 ***
LogDvmt      -1.0657712  0.0416439 -25.592  < 2e-16 ***
Urban         0.0716566  0.0400021   1.791 0.073242 .  
Age15to19     0.3072125  0.0470231   6.533 6.44e-11 ***
Age20to29     0.1940008  0.0521222   3.722 0.000198 ***
Age30to54     0.3873982  0.0466743   8.300  < 2e-16 ***
Age65Plus    -0.5820614  0.0644616  -9.030  < 2e-16 ***
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
-6.3323 -0.2401 -0.1568 -0.1048 45.2018 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7691635  0.0105619 640.906  < 2e-16 ***
HhSize       0.0532387  0.0018396  28.940  < 2e-16 ***
LogIncome    0.0589214  0.0012735  46.269  < 2e-16 ***
LogDensity  -0.0124124  0.0004656 -26.659  < 2e-16 ***
LogDvmt     -0.1354239  0.0019913 -68.007  < 2e-16 ***
Age0to14    -0.0083596  0.0018217  -4.589 4.46e-06 ***
Age15to19    0.0235968  0.0020681  11.410  < 2e-16 ***
Age20to29   -0.0322849  0.0021758 -14.839  < 2e-16 ***
Age30to54   -0.0274228  0.0017203 -15.941  < 2e-16 ***
Age65Plus   -0.0709583  0.0027659 -25.655  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44688    0.35060  -4.127 3.68e-05 ***
HhSize       0.49039    0.06451   7.601 2.93e-14 ***
LogIncome    0.23317    0.04349   5.362 8.23e-08 ***
LogDensity  -0.17532    0.01442 -12.160  < 2e-16 ***
LogDvmt     -1.27606    0.06945 -18.373  < 2e-16 ***
Age0to14     0.25526    0.06336   4.028 5.61e-05 ***
Age15to19    0.38514    0.07126   5.405 6.50e-08 ***
Age20to29    0.07015    0.07214   0.972    0.331    
Age30to54    0.53292    0.05692   9.362  < 2e-16 ***
Age65Plus   -0.60609    0.08592  -7.054 1.74e-12 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1 

Number of iterations in BFGS optimization: 21 
Log-likelihood: -2.818e+05 on 20 Df
```

## How the Module Works

The module loads from the datastore the proportional reductions in household DVMT calculated by the AssignDemandManagement module and DivertSovTravel module. It converts the proportional reductions to proportions of DVMT (i.e. 1 - proportional reduction), multiplies them, and multiplies by household DVMT to arrive at a revised household DVMT which is saved to the datastore.


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
