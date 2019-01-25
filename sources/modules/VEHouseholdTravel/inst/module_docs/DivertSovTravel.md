
# DivertSovTravel Module
### December 20, 2018

This module reduces household single-occupant vehicle (SOV) travel to achieve goals that are inputs to the model. The purpose of this module is to enable users to do 'what if' analysis of the potential of light-weight vehicles (e.g. bicycles, electric bikes, electric scooters) and infrastructure to support their use to reduce SOV travel. The user inputs a goal for diverting a portion of SOV travel within a 20-mile tour distance (round trip distance). The module predicts the amount of each household's DVMT that occurs in SOV tours having round trip distances of 20 miles or less. It also predicts for each household the average length of trips that are in those SOV tours. It then reduces the SOV travel of each household to achieve the overall goal. The reductions are allocated to households as a function of the household's SOV DVMT and the inverse of SOV trip length (described in more detail below). The proportions of diverted DVMT are saved as are the average SOV trip length of diverted DVMT. These datasets are used in the ApplyDvmtReductions module to calculate reductions in household DVMT and to calculate trips to be added to the bike mode category trips. SOV DVMT reduction is only applied to households in urban and town location types (LocTypes) because it is unlikely that actions/services could be provided in rural areas that could significantly divert SOV DVMT to bicyles, electric bicycles, scooters or other similar modes.

## Model Parameter Estimation

This module estimates 2 models. One of them predicts the proportion of household travel occurring in single-occupant vehicle tours that have round trip distances of 20 miles or less. The other predicts the average length of trips in those tours.

Two data frames from the VE2001NHTS package are used to develop these models. The Hh_df data frame includes attributes of households used as dependent variables in the models. The HhTours_df data frame is used to identify qualifying tours. The miles in qualifying tours is summed by household and added to the Hh_df data frame. The number of trips in qualifying tours is also summed by household. The average length of trips in qualifying SOV is calculated from the qualifying DVMT and trips. The average household DVMT model from the CalculateHouseholDvmt model is run to estimate the average DVMT of each survey household. Households having incomplete data (mostly because of missing income data) and zero vehicle households are removed from the dataset resulting in 51,924 household records.

### Model of Proportion of DVMT in Qualifying SOV Tours

The model is estimated in 2 stages. In the first stage, models are estimated to predict the likelihood that a household had no qualifying SOV tours on the survey day, and to predict the amount of DVMT in qualifying tours if there were one or more qualifying tours on the survey day. These two models are then applied stochastically to the survey households 1000 times and the results averaged to arrive at an estimate of the average DVMT in qualifying SOV tours for each household. The average household DVMT model from the CalculateHouseholDvmt module is also run and the ratio of estimated average DVMT in qualifying SOV tours is divided by the estimated average DVMT to arrive at an estimate of the average proportion of household DVMT that is in qualifying tours. In the second step, a linear model of the log odds corresponding to the proportions is estimated. In addition, the median trip length in qualifying tours is calculated.

In the first stage of model development, a binomial logit model is estimated to predict the likelihood that a household had any qualifying SOV tours on the survey day. A linear model is also estimated which predicts the miles of travel in qualifying SOV tours if any. The summary statics for the estimation of the binomial logit model follows. The model accounts for a small proportion of the variability in the data, but all of the independent variables are highly significant. The number of children in the household and if the number of vehicles is less than the number of drivers increase the probability that the household had no qualifying SOV travel on the travel day. The population density of the neighborhood (block group), the number of drivers, and if the household lives in a single-family dwelling decreases the probability that the household had no qualifying SOV travel on the travel day. These effects are sensible.

```

Call:
glm(formula = makeFormula("ZeroSov", IndepVars_), family = binomial, 
    data = TestHh_df)

Deviance Residuals: 
   Min      1Q  Median      3Q     Max  
-1.851  -1.074  -0.858   1.212   2.229  

Coefficients:
                Estimate Std. Error z value Pr(>|z|)    
(Intercept)     1.840056   0.052714  34.907  < 2e-16 ***
LogDensity     -0.160016   0.005235 -30.568  < 2e-16 ***
IsSF           -0.093948   0.023757  -3.955 7.67e-05 ***
Drivers        -0.545541   0.015255 -35.762  < 2e-16 ***
NumChild        0.134328   0.009011  14.908  < 2e-16 ***
NumVehLtNumDvr  0.486979   0.031602  15.410  < 2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 71339  on 51923  degrees of freedom
Residual deviance: 69122  on 51918  degrees of freedom
AIC: 69134

Number of Fisher Scoring iterations: 4

```

The summary statistics for the linear model of qualifying SOV travel if any is shown below. In this model a power transform of the qualifying SOV DVMT is the dependent variable. Power transformation is done to help linearize the relationship since the qualifying SOV DVMT is highly skewed with a long right hand tail. The power transformation is calculated to minimize skewness of the distribution. As with the previous model, this one accounts for a small portion of the observed variability but the independent variables are highly significant. The amount of qualifying SOV DVMT increases with the income of the household, the number of drivers, and the household DVMT. The amount of qualifying SOV DVMT is decreased by the density of the neighborhood, the number of children in the household, and if the number of vehicles is less than the number of drivers.

```

Call:
lm(formula = PowSovDvmt ~ LogDensity + LogIncome + Drivers + 
    NumChild + NumVehLtNumDvr + LogDvmt, data = TestHh_df)

Residuals:
     Min       1Q   Median       3Q      Max 
-2.26130 -0.50859  0.04234  0.51566  2.62252 

Coefficients:
                Estimate Std. Error t value Pr(>|t|)    
(Intercept)     1.109865   0.067664  16.403  < 2e-16 ***
LogDensity     -0.006851   0.002864  -2.392 0.016752 *  
LogIncome       0.031213   0.008086   3.860 0.000114 ***
Drivers         0.155164   0.011822  13.125  < 2e-16 ***
NumChild       -0.080270   0.005140 -15.617  < 2e-16 ***
NumVehLtNumDvr -0.235920   0.016172 -14.588  < 2e-16 ***
LogDvmt         0.173481   0.022630   7.666 1.83e-14 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.7176 on 28842 degrees of freedom
Multiple R-squared:  0.0714,	Adjusted R-squared:  0.0712 
F-statistic: 369.6 on 6 and 28842 DF,  p-value: < 2.2e-16

```

The two models were applied jointly (using the estimation dataset) in a stochastic manner 1000 times to simulate that many travel days. In the case of the binomial logit model which predicts the likelihood of no qualifying SOV travel, the predicted probability for each simulated day is compared with a random draw from a uniform distribution in the range 0 to 1 to determine whether the household has any qualifying SOV travel. In the case of the linear model which predicts the amount of qualifying SOV travel, the model predictions are used to estimate the mean of a distribution from which a random draw is made. The standard deviation of the distribution is estimated so that the standard deviation of the estimates for the sample household population equals the standard deviation of the observed values for the population. The mean qualifying SOV DVMT for each household is calculated from the results of the 1000 simulations.

The estimated average ratio of qualifying SOV DVMT to household average DVMT is calculated from the simulated results and the estimate of average DVMT calculated from applying the average DVMT model from the CalculateHouseholdDvmt module. A linear model of that ratio is estimated. In this model, the dependent variable is the logit of the ratio (log of the odds ratio). This keeps the predicted ratios in the range of 0 to 1 and does a better job of linearizing the relationship. The summary statistics for this model follow. The model explains almost all of the variability and all of the independent variables are highly significant. This is to be expected since the model estimates relationships derived from the two previous models.

```

Call:
lm(formula = makeFormula(EndTerms_), data = EstData_df)

Residuals:
     Min       1Q   Median       3Q      Max 
-1.34656 -0.03898  0.00362  0.04401  0.31330 

Coefficients:
                     Estimate Std. Error t value Pr(>|t|)    
(Intercept)        -0.6793376  0.0107561  -63.16   <2e-16 ***
LogDensity          0.1888215  0.0013084  144.32   <2e-16 ***
IsSF                0.0608926  0.0008015   75.97   <2e-16 ***
LogIncome           0.0374898  0.0005823   64.38   <2e-16 ***
Drivers             0.4201962  0.0008956  469.19   <2e-16 ***
NumChild           -0.1620233  0.0003725 -434.98   <2e-16 ***
NumVehLtNumDvr     -0.5090277  0.0011471 -443.76   <2e-16 ***
LogDvmt            -0.7179500  0.0033074 -217.07   <2e-16 ***
LogDensity:LogDvmt -0.0280475  0.0003226  -86.93   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.06792 on 51915 degrees of freedom
Multiple R-squared:  0.9788,	Adjusted R-squared:  0.9788 
F-statistic: 3.003e+05 on 8 and 51915 DF,  p-value: < 2.2e-16

```

The signs of the coefficients are sensible. The ratio of the average qualifying SOV DVMT of the household to the average DVMT of the household increases with:

* Income - because higher income enables more discretionary travel and freedom to travel alone;

* Drivers - because having more drivers increases the probability of solo travel and decreases the need to travel as a passenger;

* Density - because higher density neighborhoods have more activity in close proximity and decrease the need for trip linking of multiple household members; and,

* Single-family dwelling - because living in a single-family dwelling makes it easier to make spur-of-the-moment SOV trips because the vehicle is more accessible and there are usually no worries about finding a good parking space when arriving back home.

The ratio of qualifying SOV DVMT decreases with increasing:

* Number of children - because younger children often need to be taken along to shuttle them to activities or to maintain supervision while running errands;

* Number of vehicles is less than the number of drivers - because when cars are not available for every driver it is more likely that they will need to travel together; and,

* Household DVMT - because travel to work establishes a base level of vehicle travel and typically has lower vehicle occupancy than travel for other purposes. Travel beyond work travel is therefore less likely to be SOV travel than work travel and therefore will reduce the SOV DVMT ratio.

### Model of Average Length of Trips in Qualifying SOV Tours

A model of the average length in miles of trips in qualifying SOV tours is estimated in 2 stages as well. In the first stage a linear model of average trip length on the survey day is estimated. That model is applied in a simulation of 1000 days of travel and the average for each household are computed from the simulation. In the second stage, a linear model of the simulated averages is estimated. In each stage, separate models are estimated for metropolitan and non-metropolitan households to reflect the effect that freeway supply and urban mixed-use development have on trip length. For all of these models, the dependent variable is a power-transform of the SOV trip length. This is done to minimize the skewness of the distribution to help linearize the relationships. These models are estimated using the household records that have some qualifying SOV DVMT.

Following are the summary estimation statistics for the linear model of the survey day average trip length for metropolitan households. While the model 'explains' a small percentage of the variation in average trip length, all of the terms are highly signficant and the signs of the coefficients are sensible. Average trip lengths increase with the number of drivers, amount of household income, and freeway supply. Average trip lengths decrease with the number of non-drivers, population density, in urban mixed-use neighborhoods, and if the household has fewer vehicles than drivers.

```

Call:
lm(formula = ModelFormula, data = Data_df)

Residuals:
    Min      1Q  Median      3Q     Max 
-1.9708 -0.6204 -0.0698  0.5285  4.2689 

Coefficients:
                  Estimate Std. Error t value Pr(>|t|)    
(Intercept)       1.744916   0.143439  12.165  < 2e-16 ***
Drivers           0.110493   0.013090   8.441  < 2e-16 ***
NonDrivers       -0.025626   0.008247  -3.107  0.00189 ** 
LogIncome         0.041473   0.012274   3.379  0.00073 ***
LogDensity       -0.067438   0.007005  -9.628  < 2e-16 ***
IsUrbanMixNbrhd  -0.074034   0.023593  -3.138  0.00171 ** 
FwyLaneMiPC     211.927204  46.864599   4.522 6.19e-06 ***
NumVehLtNumDvr   -0.227886   0.029579  -7.704 1.44e-14 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.8421 on 9815 degrees of freedom
Multiple R-squared:  0.04731,	Adjusted R-squared:  0.04663 
F-statistic: 69.63 on 7 and 9815 DF,  p-value: < 2.2e-16

```

Following are the summary estimation statistics for the non-metropolitan linear model of survey day average trip length. As with the metropolitan model, this one 'explains' a small percentage of the observed variation in average SOV trip length, but all of the variables are highly significant. The missing the freeway supply and urban mixed-use neighborhood variables that are not available for non-metropolitan areas. It is also missing the non-driver variable which is found to be insignificant at the 5% level.

```

Call:
lm(formula = ModelFormula, data = Data_df)

Residuals:
    Min      1Q  Median      3Q     Max 
-3.3530 -1.2158 -0.2455  0.9487 10.7077 

Coefficients:
                Estimate Std. Error t value Pr(>|t|)    
(Intercept)     1.819918   0.182273   9.985   <2e-16 ***
Drivers         0.168535   0.018669   9.027   <2e-16 ***
LogIncome       0.156181   0.017716   8.816   <2e-16 ***
LogDensity     -0.149261   0.006876 -21.707   <2e-16 ***
NumVehLtNumDvr -0.389550   0.043529  -8.949   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 1.648 on 19021 degrees of freedom
Multiple R-squared:  0.04435,	Adjusted R-squared:  0.04415 
F-statistic: 220.7 on 4 and 19021 DF,  p-value: < 2.2e-16

```

The travel day models are applied stochastically 1000 times to simulate day-to-day travel and calculate average values. In each simulation, the model predictions are used to estimate the mean of a distribution from which a random draw is made. The standard deviation of the distribution is estimated so that the standard deviation of the estimates for the sample household population equals the standard deviation of the observed values for the population. The values of the 1000 simulations are averaged for each household to calculate the average trip length for trips in qualifying SOV tours.

Linear models are estimated for the simulated average trip lengths. The estimation statistics for the metropolitan and non-metropolitan models follow.

```

Call:
lm(formula = makeFormula(EndTerms_), data = EstData_df)

Residuals:
      Min        1Q    Median        3Q       Max 
-0.220901 -0.034724  0.000128  0.035031  0.197604 

Coefficients:
                  Estimate Std. Error t value Pr(>|t|)    
(Intercept)      2.517e+00  8.731e-03  288.31   <2e-16 ***
Drivers          2.061e-01  7.965e-04  258.81   <2e-16 ***
NonDrivers      -4.682e-02  5.018e-04  -93.30   <2e-16 ***
LogIncome        7.437e-02  7.468e-04   99.58   <2e-16 ***
LogDensity      -1.272e-01  4.270e-04 -297.88   <2e-16 ***
IsUrbanMixNbrhd -1.224e-01  1.436e-03  -85.27   <2e-16 ***
FwyLaneMiPC      3.946e+02  2.851e+00  138.37   <2e-16 ***
VehLtDvr        -4.130e-01  1.800e-03 -229.48   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.05124 on 9815 degrees of freedom
Multiple R-squared:  0.9785,	Adjusted R-squared:  0.9784 
F-statistic: 6.368e+04 on 7 and 9815 DF,  p-value: < 2.2e-16

```

```

Call:
lm(formula = makeFormula(EndTerms_), data = EstData_df)

Residuals:
       Min         1Q     Median         3Q        Max 
-0.0109116 -0.0014552  0.0000265  0.0014896  0.0086802 

Coefficients:
              Estimate Std. Error t value Pr(>|t|)    
(Intercept)  1.106e+00  2.425e-04  4561.3   <2e-16 ***
Drivers      6.357e-03  2.483e-05   256.0   <2e-16 ***
LogIncome    6.137e-03  2.356e-05   260.4   <2e-16 ***
LogDensity  -5.706e-03  9.178e-06  -621.7   <2e-16 ***
VehLtDvr    -1.506e-02  5.790e-05  -260.2   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 0.002192 on 19021 degrees of freedom
Multiple R-squared:  0.9746,	Adjusted R-squared:  0.9746 
F-statistic: 1.828e+05 on 4 and 19021 DF,  p-value: < 2.2e-16

```

## How the Module Works

This function calculates the proportional reduction in the DVMT of individual households to meet the user-supplied goal for diverting a proportion of travel in SOV tours 20 miles or less in length to bikes, electric bikes, scooters or other similar modes. The user supplies the diversion goal for each Azone and model year. SOV DVMT reduction is only applied to households in urban and town location types (LocTypes) because it is unlikely that actions/services could be provided in rural areas that could significantly divert SOV DVMT to bicyles, electric bicycles, scooters or other similar modes. The following procedural steps are followed to complete the calculation:

* The SOV proportions model described is applied to calculate the proportion of the DVMT of each household that is in qualifying SOV tours (i.e. having lengths of 20 miles or less);

* The total diversion of DVMT in qualifying SOV tours (of urban and town households) for the Azone is calculated by:

  * Calculating the qualifying SOV tour DVMT of each household by multiplying the modeled proportion of DVMT in qualifying tours by the household DVMT;

  * Summing the qualifying SOV tour DVMT of urban and town households in the Azone and multiplying by the diversion goal for the Azone;

* The total DVMT diverted is allocated to urban and town households in the Azone as a function of their relative amounts of qualifying SOV travel and the inverse of the average length of trips in qualifying tours. In other words, it is assumed that households having more qualifying SOV travel and households having shorter SOV trips will be more likely to divert SOV travel. This is implemented in the following steps:

  * A utility function is defined as follows:

     `U = log(SovDvmt / mean(SovDvmt)) + B * log(TripLength / mean(TripLength))`

     Where:

     `SovDvmt` and `mean(SovDvmt)` are the household's qualifying SOV DVMT and the population mean respectively,

     `TripLength` and `mean(TripLength)` are the household's average qualifying SOV trip length and the population mean respectively, and

     `B` is a parameter that is estimated to keep the maximum proportion of SOV diversion for all households within bounds as explained below.

  * The proportion of total diverted DVMT allocated to each household is `exp(U) / sum(exp(U))` where `exp(U)` is the exponentiated value of the utility for the household and `sum(exp(U))` is the sum of the exponentiated values for all households.

  * The value of `B` is solved such that the maximum proportional diversion for any household is midway between the objective of the Azone and 1. For example, if the Azone objective is 0.2, the maximum diversion would be 0.6. The value is solved iteratively using a binary search algorithm.

* The DVMT diversion allocated to each household is divided by the average DVMT of each household to calculate the proportion of household DVMT that is diverted. The DVMT diversion of rural households is set at 0. This and the average trip length by household are outputs to be saved in the datastore.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_prop_sov_dvmt_diverted.csv
|NAME                |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                                                            |
|:-------------------|:------|:----------|:------------|:-----------|:--------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Geo                 |       |           |             |Azones      |         |Must contain a record for each Azone and model run year.                                                                                                                               |
|Year                |       |           |             |            |         |Must contain a record for each Azone and model run year.                                                                                                                               |
|PropSovDvmtDiverted |double |Proportion |NA, < 0, > 1 |            |         |Goals for the proportion of household DVMT in single occupant vehicle tours with round-trip distances of 20 miles or less be diverted to bicycling or other slow speed modes of travel |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME                |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT     |ISELEMENTOF        |
|:-------------------|:---------|:-----|:---------|:----------|:------------|:------------------|
|Marea               |Marea     |Year  |character |ID         |             |                   |
|FwyLaneMiPC         |Marea     |Year  |compound  |MI/PRSN    |NA, < 0      |                   |
|Azone               |Azone     |Year  |character |ID         |             |                   |
|PropSovDvmtDiverted |Azone     |Year  |double    |Proportion |NA, < 0, > 1 |                   |
|Bzone               |Bzone     |Year  |character |ID         |             |                   |
|D1B                 |Bzone     |Year  |compound  |PRSN/SQMI  |NA, < 0      |                   |
|Marea               |Household |Year  |character |ID         |             |                   |
|Azone               |Household |Year  |character |ID         |             |                   |
|Bzone               |Household |Year  |character |ID         |             |                   |
|Dvmt                |Household |Year  |compound  |MI/DAY     |NA, < 0      |                   |
|Vehicles            |Household |Year  |vehicles  |VEH        |NA, < 0      |                   |
|HhSize              |Household |Year  |people    |PRSN       |NA, < 0      |                   |
|Age0to14            |Household |Year  |people    |PRSN       |NA, < 0      |                   |
|Age15to19           |Household |Year  |people    |PRSN       |NA, < 0      |                   |
|Drivers             |Household |Year  |people    |PRSN       |NA, < 0      |                   |
|Income              |Household |Year  |currency  |USD.2001   |NA, < 0      |                   |
|LocType             |Household |Year  |character |category   |NA           |Urban, Town, Rural |
|IsUrbanMixNbrhd     |Household |Year  |integer   |binary     |NA           |0, 1               |
|HouseType           |Household |Year  |character |category   |             |SF, MF, GQ         |

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

|NAME              |TABLE     |GROUP |TYPE     |UNITS      |PROHIBIT     |ISELEMENTOF |DESCRIPTION                                                                                                       |
|:-----------------|:---------|:-----|:--------|:----------|:------------|:-----------|:-----------------------------------------------------------------------------------------------------------------|
|PropDvmtDiverted  |Household |Year  |double   |proportion |NA, < 0, > 1 |            |Proportion of household DVMT diverted to bicycling, electric bikes, or other 'low-speed' travel modes             |
|AveTrpLenDiverted |Household |Year  |distance |MI         |NA, < 0      |            |Average length in miles of vehicle trips diverted to bicycling, electric bikes, or other 'low-speed' travel modes |
