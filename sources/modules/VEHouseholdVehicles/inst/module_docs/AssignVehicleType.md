
# AssignVehicleType Module
### November 23, 2018

This module identifies how many household vehicles are light trucks and how many are automobiles. Light trucks include pickup trucks, sport utility vehicles, vans, and any other vehicle not classified as a passenger car. Automobiles are vehicles classified as passenger cars. The crossover vehicle category [blurs the line between light trucks and passenger vehicles](https://www.eia.gov/todayinenergy/detail.php?id=31352). Their classification as light trucks or automobiles depends on the agency doing the classification and purpose of the classification. These vehicles were not a significant portion of the market when the model estimation data were collected and so are not explictly considered. How they are classified is up to the model user who is responsible for specifying the light truck proportion of the vehicle fleet.

## Model Parameter Estimation

A binary logit models are estimated to predict the probability that a household vehicle is a light truck. A summary of the estimated model follows. The probability that a vehicle is a light truck increases if:

* The ratio of the number of persons in the household to the number of vehicles in the household increases;

* The number of children in the household increases;

* The ratio of vehicles to drivers increases, especially if the number of vehicles is greater than the number of drivers; and,

* The household lives in a single-family dwelling.

The probability decreases if:

* The household only owns one vehicle;

* The household has low income (less than $20,000 in year 2000 dollars);

* The household lives in a higher density neighborhood; and,

* The household lives in an urban mixed-use neighborhood.

```

Call:
glm(formula = makeFormula(StartTerms_), family = binomial, data = EstData_df)

Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-3.2093  -0.7703  -0.2093   0.5060   3.6297  

Coefficients:
                 Estimate Std. Error z value Pr(>|z|)    
(Intercept)     -0.280653   0.052778  -5.318 1.05e-07 ***
PrsnPerVeh       0.280447   0.018733  14.971  < 2e-16 ***
NumChild         0.093490   0.009726   9.612  < 2e-16 ***
NumVehGtNumDvr   0.416944   0.035014  11.908  < 2e-16 ***
NumVehEqNumDvr   0.216757   0.029180   7.428 1.10e-13 ***
IsSF             0.372638   0.020487  18.189  < 2e-16 ***
OnlyOneVeh      -0.699185   0.024482 -28.559  < 2e-16 ***
IsLowIncome     -0.269053   0.024296 -11.074  < 2e-16 ***
LogDensity      -0.130321   0.003887 -33.532  < 2e-16 ***
IsUrbanMixNbrhd -0.156379   0.030344  -5.154 2.56e-07 ***
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 66655  on 51781  degrees of freedom
Residual deviance: 60046  on 51772  degrees of freedom
AIC: 93279

Number of Fisher Scoring iterations: 4

```

The model and all of its independent variables are significant, but it only explains a modest proportion of the observed variation in light truck ownership. When the model is applied to the estimation dataset, it correctly predicts the number of light trucks for about 46% of the households. Over predictions and under predictions are approximately equal as shown in the following table.


|Prediction        | Proportion|
|:-----------------|----------:|
|Under Predict     |      0.270|
|Correctly Predict |      0.462|
|Over Predict      |      0.268|

## How the Module Works

The user inputs the light truck proportion of vehicles observed or assumed each each Azone. The module calls the `applyBinomialModel` function (part of the *visioneval* framework package), passing it the estimated binomial logit model and a data frame of values for the independent variables, and the user-supplied light truck proportion. The `applyBinomialModel` function uses a binary search algorithm to adjust the intercept of the model so that the resulting light truck proportion of all household vehicles in the Azone equals the user input.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### azone_lttrk_prop.csv
|NAME      |TYPE   |UNITS      |PROHIBIT       |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                               |
|:---------|:------|:----------|:--------------|:-----------|:--------|:-------------------------------------------------------------------------|
|Geo       |       |           |               |Azones      |         |Must contain a record for each Azone and model run year.                  |
|Year      |       |           |               |            |         |Must contain a record for each Azone and model run year.                  |
|LtTrkProp |double |proportion |NA, <= 0, >= 1 |            |         |Proportion of household vehicles that are light trucks (pickup, SUV, van) |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME            |TABLE     |GROUP |TYPE      |UNITS      |PROHIBIT       |ISELEMENTOF |
|:---------------|:---------|:-----|:---------|:----------|:--------------|:-----------|
|LtTrkProp       |Azone     |Year  |double    |proportion |NA, <= 0, >= 1 |            |
|D1B             |Bzone     |Year  |compound  |PRSN/SQMI  |NA, < 0        |            |
|Bzone           |Bzone     |Year  |character |ID         |               |            |
|HhId            |Household |Year  |character |ID         |               |            |
|Bzone           |Household |Year  |character |ID         |               |            |
|HhSize          |Household |Year  |people    |PRSN       |NA, <= 0       |            |
|Age0to14        |Household |Year  |people    |PRSN       |NA, < 0        |            |
|Age15to19       |Household |Year  |people    |PRSN       |NA, < 0        |            |
|Income          |Household |Year  |currency  |USD.2001   |NA, < 0        |            |
|HouseType       |Household |Year  |character |category   |               |SF, MF, GQ  |
|IsUrbanMixNbrhd |Household |Year  |integer   |binary     |NA             |0, 1        |
|Vehicles        |Household |Year  |vehicles  |VEH        |NA, < 0        |            |
|Drivers         |Household |Year  |people    |PRSN       |NA, < 0        |            |

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

|NAME     |TABLE     |GROUP |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |DESCRIPTION                                                                                                   |
|:--------|:---------|:-----|:--------|:-----|:--------|:-----------|:-------------------------------------------------------------------------------------------------------------|
|NumLtTrk |Household |Year  |vehicles |VEH   |NA, < 0  |            |Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household                  |
|NumAuto  |Household |Year  |vehicles |VEH   |NA, < 0  |            |Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household |
