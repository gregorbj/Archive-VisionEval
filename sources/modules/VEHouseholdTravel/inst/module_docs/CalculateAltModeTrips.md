
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
-4.7391 -1.3362 -0.5992  0.5861 32.2143 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   4.591e+00  6.695e-03  685.71   <2e-16 ***
HhSize        3.173e-01  8.370e-04  379.12   <2e-16 ***
LogIncome     1.417e-01  6.556e-04  216.16   <2e-16 ***
LogDensity   -4.020e-03  3.344e-04  -12.02   <2e-16 ***
BusEqRevMiPC  1.631e-03  1.302e-05  125.30   <2e-16 ***
Urban         4.581e-02  6.120e-04   74.86   <2e-16 ***
LogDvmt      -2.195e-01  7.193e-04 -305.18   <2e-16 ***
Age0to14     -3.257e-01  9.078e-04 -358.73   <2e-16 ***
Age15to19    -8.758e-02  1.099e-03  -79.71   <2e-16 ***
Age20to29     4.690e-02  9.317e-04   50.34   <2e-16 ***
Age30to54     2.095e-02  7.154e-04   29.29   <2e-16 ***
Age65Plus    -3.514e-02  8.485e-04  -41.42   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -2.2740988  0.2613793  -8.700  < 2e-16 ***
HhSize        0.4596076  0.0385466  11.923  < 2e-16 ***
LogIncome     0.2792424  0.0259909  10.744  < 2e-16 ***
LogDensity    0.0233209  0.0137824   1.692 0.090631 .  
BusEqRevMiPC -0.0038103  0.0005493  -6.937 4.01e-12 ***
Urban         0.0644272  0.0260836   2.470 0.013510 *  
LogDvmt      -0.2560257  0.0314416  -8.143 3.86e-16 ***
Age0to14     -0.3716243  0.0422647  -8.793  < 2e-16 ***
Age15to19    -0.1963820  0.0555863  -3.533 0.000411 ***
Age20to29     0.0929569  0.0428981   2.167 0.030241 *  
Age30to54     0.0649184  0.0309901   2.095 0.036188 *  
Age65Plus    -0.0374076  0.0344161  -1.087 0.277071    
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
-2.9707 -1.2632 -0.5842  0.5359 34.5828 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.1533444  0.0044802 1373.47   <2e-16 ***
HhSize       0.3303300  0.0006747  489.60   <2e-16 ***
LogIncome   -0.0238172  0.0005582  -42.67   <2e-16 ***
LogDensity  -0.0377152  0.0001842 -204.79   <2e-16 ***
LogDvmt     -0.0413904  0.0010308  -40.15   <2e-16 ***
Age0to14    -0.3605649  0.0007032 -512.71   <2e-16 ***
Age15to19   -0.1465419  0.0008401 -174.43   <2e-16 ***
Age20to29    0.0241497  0.0006777   35.64   <2e-16 ***
Age30to54   -0.0190232  0.0005360  -35.49   <2e-16 ***
Age65Plus   -0.0301633  0.0006138  -49.14   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept) -0.498471   0.159757  -3.120  0.00181 ** 
HhSize       0.145002   0.029150   4.974 6.54e-07 ***
LogIncome    0.058033   0.019794   2.932  0.00337 ** 
LogDensity  -0.034505   0.006875  -5.019 5.19e-07 ***
LogDvmt      0.117820   0.036022   3.271  0.00107 ** 
Age0to14    -0.190493   0.030042  -6.341 2.28e-10 ***
Age15to19    0.021284   0.038481   0.553  0.58020    
Age20to29    0.092805   0.028744   3.229  0.00124 ** 
Age30to54    0.064052   0.021310   3.006  0.00265 ** 
Age65Plus   -0.049885   0.023211  -2.149  0.03162 *  
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
-1.2354 -0.3524 -0.2790 -0.2282 34.1311 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.333e+00  2.471e-02  256.25   <2e-16 ***
HhSize        1.107e-01  4.272e-03   25.92   <2e-16 ***
LogIncome    -6.754e-02  2.902e-03  -23.27   <2e-16 ***
BusEqRevMiPC -2.240e-03  6.019e-05  -37.23   <2e-16 ***
LogDvmt      -1.704e-01  3.337e-03  -51.06   <2e-16 ***
Age0to14     -1.937e-01  4.480e-03  -43.25   <2e-16 ***
Age15to19    -1.358e-01  5.291e-03  -25.67   <2e-16 ***
Age20to29     7.880e-02  4.425e-03   17.81   <2e-16 ***
Age30to54     7.900e-02  3.618e-03   21.84   <2e-16 ***
Age65Plus     4.908e-02  4.318e-03   11.37   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.7706258  0.3799618 -12.556  < 2e-16 ***
HhSize        0.1658869  0.0580548   2.857 0.004271 ** 
LogIncome     0.2005361  0.0431470   4.648 3.36e-06 ***
BusEqRevMiPC -0.0061589  0.0008648  -7.121 1.07e-12 ***
LogDvmt      -0.0400015  0.0496897  -0.805 0.420805    
Age0to14      0.0452368  0.0599517   0.755 0.450517    
Age15to19     0.2071688  0.0717246   2.888 0.003872 ** 
Age20to29     0.2301366  0.0614261   3.747 0.000179 ***
Age30to54     0.1712989  0.0483194   3.545 0.000392 ***
Age65Plus    -0.0756408  0.0613735  -1.232 0.217775    
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
-2.4414 -0.3568 -0.2792 -0.2273 57.2897 

Count model coefficients (truncated poisson with log link):
             Estimate Std. Error z value Pr(>|z|)    
(Intercept)  5.891542   0.017448  337.66   <2e-16 ***
HhSize       0.242371   0.002575   94.11   <2e-16 ***
LogIncome    0.033052   0.002124   15.56   <2e-16 ***
LogDvmt     -0.386155   0.003244 -119.02   <2e-16 ***
Age0to14    -0.289251   0.002742 -105.50   <2e-16 ***
Age15to19   -0.092267   0.003160  -29.20   <2e-16 ***
Age20to29    0.095822   0.002578   37.17   <2e-16 ***
Age30to54    0.024606   0.002280   10.79   <2e-16 ***
Age65Plus   -0.033706   0.002863  -11.77   <2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -4.62290    0.27757 -16.655  < 2e-16 ***
HhSize       0.21575    0.04552   4.739 2.15e-06 ***
LogIncome    0.19346    0.03285   5.890 3.87e-09 ***
LogDvmt     -0.12116    0.05753  -2.106  0.03519 *  
Age0to14    -0.05061    0.04528  -1.118  0.26364    
Age15to19    0.18241    0.05279   3.455  0.00055 ***
Age20to29    0.25781    0.04318   5.971 2.36e-09 ***
Age30to54    0.17483    0.03476   5.030 4.90e-07 ***
Age65Plus   -0.18265    0.04441  -4.113 3.90e-05 ***
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
-3.9031 -0.3419 -0.2262 -0.1478 34.7830 

Count model coefficients (truncated poisson with log link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)   6.031e+00  1.043e-02 578.250  < 2e-16 ***
HhSize        1.358e-02  6.687e-04  20.313  < 2e-16 ***
LogIncome     5.799e-02  9.998e-04  58.000  < 2e-16 ***
LogDensity    4.487e-02  5.881e-04  76.288  < 2e-16 ***
BusEqRevMiPC  1.886e-03  2.542e-05  74.206  < 2e-16 ***
LogDvmt      -9.632e-02  1.008e-03 -95.555  < 2e-16 ***
Urban         3.453e-02  1.076e-03  32.102  < 2e-16 ***
Age15to19    -1.277e-03  1.207e-03  -1.058     0.29    
Age20to29     6.576e-02  1.333e-03  49.350  < 2e-16 ***
Age30to54     4.877e-02  1.262e-03  38.661  < 2e-16 ***
Age65Plus     8.620e-03  1.662e-03   5.185 2.16e-07 ***
Zero hurdle model coefficients (binomial with logit link):
               Estimate Std. Error z value Pr(>|z|)    
(Intercept)  -4.1538209  0.4115950 -10.092  < 2e-16 ***
HhSize        0.5191123  0.0245957  21.106  < 2e-16 ***
LogIncome     0.3440299  0.0403364   8.529  < 2e-16 ***
LogDensity   -0.0400498  0.0214203  -1.870 0.061524 .  
BusEqRevMiPC  0.0097592  0.0008815  11.071  < 2e-16 ***
LogDvmt      -1.0696977  0.0417817 -25.602  < 2e-16 ***
Urban         0.0714077  0.0400042   1.785 0.074260 .  
Age15to19     0.3065175  0.0470274   6.518 7.13e-11 ***
Age20to29     0.1941155  0.0521254   3.724 0.000196 ***
Age30to54     0.3877585  0.0466790   8.307  < 2e-16 ***
Age65Plus    -0.5827711  0.0644604  -9.041  < 2e-16 ***
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
-6.3371 -0.2401 -0.1568 -0.1048 45.2152 

Count model coefficients (truncated poisson with log link):
              Estimate Std. Error z value Pr(>|z|)    
(Intercept)  6.7693421  0.0105616 640.941  < 2e-16 ***
HhSize       0.0532251  0.0018394  28.936  < 2e-16 ***
LogIncome    0.0587222  0.0012713  46.189  < 2e-16 ***
LogDensity  -0.0124087  0.0004655 -26.656  < 2e-16 ***
LogDvmt     -0.1350090  0.0019839 -68.054  < 2e-16 ***
Age0to14    -0.0083785  0.0018217  -4.599 4.24e-06 ***
Age15to19    0.0235907  0.0020681  11.407  < 2e-16 ***
Age20to29   -0.0323264  0.0021757 -14.858  < 2e-16 ***
Age30to54   -0.0274423  0.0017202 -15.953  < 2e-16 ***
Age65Plus   -0.0709728  0.0027659 -25.660  < 2e-16 ***
Zero hurdle model coefficients (binomial with logit link):
            Estimate Std. Error z value Pr(>|z|)    
(Intercept) -1.44423    0.35061  -4.119 3.80e-05 ***
HhSize       0.49018    0.06451   7.599 2.99e-14 ***
LogIncome    0.23125    0.04341   5.327 9.99e-08 ***
LogDensity  -0.17526    0.01442 -12.158  < 2e-16 ***
LogDvmt     -1.27220    0.06919 -18.388  < 2e-16 ***
Age0to14     0.25516    0.06337   4.027 5.65e-05 ***
Age15to19    0.38505    0.07126   5.403 6.55e-08 ***
Age20to29    0.06976    0.07214   0.967    0.334    
Age30to54    0.53271    0.05692   9.359  < 2e-16 ***
Age65Plus   -0.60603    0.08593  -7.052 1.76e-12 ***
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
