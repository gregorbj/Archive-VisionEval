
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
-4.7382 -1.3362 -0.5992  0.5862 32.2167 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.588e+00  6.696e-03  685.25   <2e-16 ***
HhSize        3.173e-01  8.370e-04  379.07   <2e-16 ***
LogIncome     1.418e-01  6.557e-04  216.19   <2e-16 ***
LogDensity   -3.996e-03  3.344e-04  -11.95   <2e-16 ***
BusEqRevMiPC  1.633e-03  1.301e-05  125.51   <2e-16 ***
Urban         4.583e-02  6.120e-04   74.88   <2e-16 ***
LogDvmt      -2.191e-01  7.179e-04 -305.13   <2e-16 ***
Age0to14     -3.258e-01  9.079e-04 -358.86   <2e-16 ***
Age15to19    -8.756e-02  1.099e-03  -79.69   <2e-16 ***
Age20to29     4.691e-02  9.317e-04   50.35   <2e-16 ***
Age30to54     2.096e-02  7.154e-04   29.30   <2e-16 ***
Age65Plus    -3.515e-02  8.485e-04  -41.43   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2771765  0.2614042  -8.711  < 2e-16 ***
HhSize        0.4595425  0.0385428  11.923  < 2e-16 ***
LogIncome     0.2793455  0.0259963  10.746  < 2e-16 ***
LogDensity    0.0233298  0.0137813   1.693 0.090481 .  
BusEqRevMiPC -0.0038077  0.0005492  -6.933 4.11e-12 ***
Urban         0.0644329  0.0260834   2.470 0.013501 *  
LogDvmt      -0.2555707  0.0313783  -8.145 3.80e-16 ***
Age0to14     -0.3718146  0.0422690  -8.796  < 2e-16 ***
Age15to19    -0.1963536  0.0555855  -3.532 0.000412 ***
Age20to29     0.0929756  0.0428982   2.167 0.030208 *  
Age30to54     0.0649320  0.0309902   2.095 0.036150 *  
Age65Plus    -0.0374199  0.0344162  -1.087 0.276915    
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
-2.9714 -1.2631 -0.5841  0.5358 34.5837 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1532117  0.0044801 1373.45   <2e-16 ***
HhSize       0.3303995  0.0006745  489.85   <2e-16 ***
LogIncome   -0.0236908  0.0005586  -42.41   <2e-16 ***
LogDensity  -0.0377396  0.0001842 -204.88   <2e-16 ***
LogDvmt     -0.0416790  0.0010310  -40.43   <2e-16 ***
Age0to14    -0.3606046  0.0007032 -512.83   <2e-16 ***
Age15to19   -0.1465631  0.0008401 -174.46   <2e-16 ***
Age20to29    0.0241703  0.0006777   35.67   <2e-16 ***
Age30to54   -0.0190117  0.0005360  -35.47   <2e-16 ***
Age65Plus   -0.0301801  0.0006138  -49.17   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498100   0.159756  -3.118  0.00182 ** 
HhSize       0.145176   0.029138   4.982 6.28e-07 ***
LogIncome    0.058032   0.019809   2.930  0.00339 ** 
LogDensity  -0.034514   0.006876  -5.019 5.19e-07 ***
LogDvmt      0.117590   0.036022   3.264  0.00110 ** 
Age0to14    -0.190615   0.030036  -6.346 2.21e-10 ***
Age15to19    0.021177   0.038478   0.550  0.58206    
Age20to29    0.092812   0.028744   3.229  0.00124 ** 
Age30to54    0.064063   0.021310   3.006  0.00265 ** 
Age65Plus   -0.049926   0.023210  -2.151  0.03147 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1328 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.331e+00  2.473e-02  256.01   <2e-16 ***
HhSize        1.107e-01  4.272e-03   25.91   <2e-16 ***
LogIncome    -6.748e-02  2.903e-03  -23.25   <2e-16 ***
BusEqRevMiPC -2.239e-03  6.017e-05  -37.20   <2e-16 ***
LogDvmt      -1.701e-01  3.331e-03  -51.06   <2e-16 ***
Age0to14     -1.939e-01  4.481e-03  -43.27   <2e-16 ***
Age15to19    -1.358e-01  5.291e-03  -25.66   <2e-16 ***
Age20to29     7.882e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.901e-02  3.618e-03   21.84   <2e-16 ***
Age65Plus     4.908e-02  4.318e-03   11.37   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7712147  0.3801215 -12.552  < 2e-16 ***
HhSize        0.1659045  0.0580510   2.858 0.004264 ** 
LogIncome     0.2005837  0.0431553   4.648 3.35e-06 ***
BusEqRevMiPC -0.0061589  0.0008646  -7.123 1.06e-12 ***
LogDvmt      -0.0399998  0.0495981  -0.806 0.419967    
Age0to14      0.0451899  0.0599590   0.754 0.451042    
Age15to19     0.2071578  0.0717240   2.888 0.003874 ** 
Age20to29     0.2301381  0.0614262   3.747 0.000179 ***
Age30to54     0.1713027  0.0483195   3.545 0.000392 ***
Age65Plus    -0.0756500  0.0613737  -1.233 0.217721    
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
-2.4414 -0.3567 -0.2792 -0.2273 57.2765 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.889676   0.017452  337.49   <2e-16 ***
HhSize       0.242290   0.002575   94.09   <2e-16 ***
LogIncome    0.033354   0.002125   15.70   <2e-16 ***
LogDvmt     -0.386250   0.003244 -119.07   <2e-16 ***
Age0to14    -0.289223   0.002742 -105.49   <2e-16 ***
Age15to19   -0.092249   0.003160  -29.20   <2e-16 ***
Age20to29    0.095772   0.002578   37.15   <2e-16 ***
Age30to54    0.024567   0.002280   10.78   <2e-16 ***
Age65Plus   -0.033683   0.002863  -11.76   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62348    0.27758 -16.656  < 2e-16 ***
HhSize       0.21585    0.04551   4.743 2.10e-06 ***
LogIncome    0.19368    0.03286   5.893 3.79e-09 ***
LogDvmt     -0.12161    0.05751  -2.115  0.03447 *  
Age0to14    -0.05068    0.04527  -1.119  0.26298    
Age15to19    0.18237    0.05279   3.455  0.00055 ***
Age20to29    0.25782    0.04318   5.971 2.36e-09 ***
Age30to54    0.17485    0.03476   5.031 4.89e-07 ***
Age65Plus   -0.18269    0.04441  -4.114 3.89e-05 ***
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
-3.9008 -0.3420 -0.2262 -0.1478 34.7647 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.029e+00  1.043e-02 577.970  < 2e-16 ***
HhSize        1.349e-02  6.683e-04  20.177  < 2e-16 ***
LogIncome     5.803e-02  1.000e-03  58.019  < 2e-16 ***
LogDensity    4.488e-02  5.881e-04  76.321  < 2e-16 ***
BusEqRevMiPC  1.887e-03  2.542e-05  74.262  < 2e-16 ***
LogDvmt      -9.612e-02  1.006e-03 -95.538  < 2e-16 ***
Urban         3.454e-02  1.076e-03  32.110  < 2e-16 ***
Age15to19    -1.195e-03  1.207e-03  -0.990    0.322    
Age20to29     6.583e-02  1.333e-03  49.399  < 2e-16 ***
Age30to54     4.882e-02  1.262e-03  38.698  < 2e-16 ***
Age65Plus     8.676e-03  1.662e-03   5.219  1.8e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1675986  0.4117071 -10.123  < 2e-16 ***
HhSize        0.5180539  0.0245819  21.075  < 2e-16 ***
LogIncome     0.3442928  0.0403486   8.533  < 2e-16 ***
LogDensity   -0.0398580  0.0214188  -1.861 0.062760 .  
BusEqRevMiPC  0.0097730  0.0008814  11.088  < 2e-16 ***
LogDvmt      -1.0672169  0.0416967 -25.595  < 2e-16 ***
Urban         0.0715049  0.0400036   1.787 0.073863 .  
Age15to19     0.3073511  0.0470257   6.536 6.33e-11 ***
Age20to29     0.1946543  0.0521280   3.734 0.000188 ***
Age30to54     0.3880776  0.0466833   8.313  < 2e-16 ***
Age65Plus    -0.5822609  0.0644597  -9.033  < 2e-16 ***
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
-6.3364 -0.2401 -0.1567 -0.1048 45.2298 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7687662  0.0105623 640.841  < 2e-16 ***
HhSize       0.0532056  0.0018392  28.928  < 2e-16 ***
LogIncome    0.0588393  0.0012720  46.256  < 2e-16 ***
LogDensity  -0.0124297  0.0004656 -26.698  < 2e-16 ***
LogDvmt     -0.1350677  0.0019832 -68.106  < 2e-16 ***
Age0to14    -0.0083631  0.0018217  -4.591 4.41e-06 ***
Age15to19    0.0236085  0.0020681  11.415  < 2e-16 ***
Age20to29   -0.0323334  0.0021757 -14.861  < 2e-16 ***
Age30to54   -0.0274569  0.0017202 -15.962  < 2e-16 ***
Age65Plus   -0.0709831  0.0027659 -25.664  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44865    0.35063  -4.132 3.60e-05 ***
HhSize       0.48966    0.06450   7.591 3.17e-14 ***
LogIncome    0.23207    0.04344   5.343 9.15e-08 ***
LogDensity  -0.17539    0.01442 -12.165  < 2e-16 ***
LogDvmt     -1.27215    0.06917 -18.393  < 2e-16 ***
Age0to14     0.25548    0.06337   4.032 5.54e-05 ***
Age15to19    0.38537    0.07127   5.407 6.39e-08 ***
Age20to29    0.06973    0.07214   0.967    0.334    
Age30to54    0.53253    0.05692   9.356  < 2e-16 ***
Age65Plus   -0.60585    0.08593  -7.051 1.78e-12 ***
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
