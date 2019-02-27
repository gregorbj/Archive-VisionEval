# CreateSimBzones Module
### February 1, 2019

This module synthesizes Bzones and their land use attributes as a function of Azone characteristics as well as data derived from the US Environmental Protection Agency's Smart Location Database (SLD) augmented with US Census housing and household income data, and data from the National Transit Database. Details on these data are included in the VESimLandUseData package. The combined dataset contains a number of land use attributes at the US Census block group level. The goal of Bzone synthesis to generate a set of SimBzones in each Azone that reasonably represent block group land use characteristics given the characteristics of the Azone, the Marea that the Azone is a part of, and scenario inputs provided by the user.

Many of the models and procedures used in Bzone synthesis pivot from profiles developed from these data sources for specific urbanized areas, as well as more general profiles for different urbanized area population size categories, towns, and rural areas. Using these specific and general profiles enables the simulated Bzones (SimBzones) to better represent the areas being modeled and the variety of conditions found in different states. The documentation for the `Initialize` module has a listing of urbanized area profile names.

The models and procedures in this module create SimBzones within each Azone that simulate the land use characteristics of neighborhoods likely to be found in the Azone. The SimBzones are assigned quantities of households and jobs and are attributed with several land use measures in the process. The characteristics are:

* **Location Type**: Identification of whether the SimBzone is located in an urbanized area, a town (i.e. an urban-type area that is not large enough to be urbanized), rural (i.e. dispersed low-density development)

* **Households**: Number of households in each SimBzone

* **Employment**: Number of jobs in each SimBzone

* **Activity Density**: Number of households and jobs per acre

* **Land Use Diversity**: Measures of the degree of mixing of households and jobs

* **Destination Accessibility**: Measures of proximity to households and jobs

* **Area Type and Development Type**: Categories which describe the relative urban nature of the SimBzone (area type) and the character of development in the SimBzone (development type).

* **Employment Split**: Number of retail, service, and other jobs in each SimBzone.

## Model Parameter Estimation

All the model parameters used in simulating SimBzones area estimated by the **CreateSimBzoneModels** module. Refer to that module's documentation for more information.

## How the Module Works

The module creates SimBzones in the following steps:

1) **Calculate the Number of Households by Azone and Location Type**: The number of households by Azone is loaded from the datastore. User-specified proportions of households by location type (urban, town, rural) for each Azone are used to divide the households among location types in each azone in whole numbers.

2) **Calculate the Number of Jobs by Azone and Location Type**: The number of workers by Azone is loaded from the datastore: User-specified proportions of worker work location by location type (urban, town, rural) for each Azone are used to allocate workers by work location among location types. Work locations within the urban portion of an Marea are allocated among the urban portions of Azones associated with the Marea based on user-specified proportions of the urbanized area jobs located in the urban location type of each of the associated Azones.

3) **Create SimBzones by Azone and Location Type**: SimBzones are created to have roughly equal activity totals (households and jobs). The total activity (sum of households and jobs) in each Azone and location type (calculated in the previous step) is divided by median value calculated for block groups of that location type from the SLD data. The *Create SimBzones by Azone and Location Type* section of *CreateSimBzoneModel* module documentation describes this in more detail.

4) **Assign an Activity Density to Each SimBzone**: A model is applied to calculate a likely distribution of SimBzone activity densities for each location type in each Azone. The density distribution is a function of the overall density calculated from user land area inputs for urban and town location types and average density for rural types, and the amount of activity by location type in the Azone. Model parameters vary by location type and urbanized area. The *Assign an Activity Density to Each SimBzone* section of the *CreateSimBzonesModel* module documentation describes these models in more detail. These distributions are used as sampling distributions to assign a preliminary activity density to each SimBzone in the Azone. The SimBzone densities are then adjusted to be consistent with the land area (urban and town) and density (rural) input assumptions.

5) **Assign a Jobs and Housing Mix Level to Each SimBzone**: A household and jobs mixing category (primarily-hh, largely-hh, mixed, largely-jobs, primarily-jobs) is assigned to each SimBzone using the appropriate model described in the *Assign a Jobs and Housing Mix Level to Each SimBzone* section of the *CreateSimBzonesModel* module documentation.

6) **Split SimBzone Activity Between Jobs and Households**: A first-cut split of activity between jobs and housing in each SimBzone is made based on the assigned mix level using the models described in the *Split SimBzone Activity Between Jobs and Households* section of the *CreateSimBzonesModel* module documentation. The jobs and household splits are adjusted so that the control totals by Azone and location type are matched. The mix level designations are adjusted accordingly.

7) **Assign Destination Accessibility Measure Values to SimBzones**: Destination accessibility levels are assigned to SimBzones as a function of SimBzone density levels using the models described in the *Assign Destination Accessibility Measure Values to SimBzones* section of the *CreateSimBzonesModel* module documentation.

8) **Model Housing Types**: Housing types (single family, multifamily) to be occupied by households in each SimBzone are calculated using models described in the *Model Housing Types* section of the *CreateSimBzonesModel* module documentation. These values are used in the *PredictHousing* module to assign a housing type to each household and then assign households to SimBzones as a function of their housing type choice.

9) **Designate Place Types**: Place types simplify the characterization of land use patterns. They are used in the VESimLandUse package modules to simplify the management of inputs for land use related policies. They are also used in the models for splitting employment into sectors and for establish the pedestrian-oriented network design value. There are three dimensions to the place type system. Location type identifies whether the SimBzone is located in an urbanized area (Urban), a smaller urban-type area (Town), or a non-urban area (Rural). Area types identify the relative urban nature of the SimBzone: center, inner, outer, fringe. Development types identify the character of development in the SimBzone: residential, employment, mix. The methods used for designating SimBzone place types are described in detail in the *Designate Place Types* section of the *CreateSimBzonesModel* module documentation.

10) **Split SimBzone Employment Into Sectors**: SimBzone employment is split between 3 sectors (retail, service, other). This is done for the purpose of enabling the calculation of an entropy measure of land use mixing that is used in the forthcoming multimodal household travel for VisionEval (described below). The models described in the *Split SimBzone Employment Into Sectors* section of the *CreateSimBzonesModel* module documentation are applied to carry out the splits. The entropy measure is calculated in the same way as the `D2a_EpHHm` measure is calculated in the Smart Location Database (SLD) with the exception that only 3 employment sectors are used instead of 5. The calculations are described in Table 5 of SLD [users guide](https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide).

11) **Model Pedestrian-Oriented Network Design (D3bpo4)**: The D3pbo4 pedestrian-oriented network design measure described in the SLD users guide is assigned to each SimBzone using models described in the *Model Pedestrian-Oriented Network Design (D3bpo4)* section of the *CreateSimBzonesModel* module documentation.



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

|NAME               |TABLE |GROUP  |TYPE       |UNITS      |PROHIBIT     |ISELEMENTOF |
|:------------------|:-----|:------|:----------|:----------|:------------|:-----------|
|Marea              |Marea |Global |character  |ID         |             |            |
|UzaProfileName     |Marea |Global |character  |ID         |             |            |
|Marea              |Azone |Year   |character  |ID         |             |            |
|Azone              |Azone |Year   |character  |ID         |             |            |
|NumHh              |Azone |Year   |households |HH         |NA, < 0      |            |
|NumWkr             |Azone |Year   |people     |PRSN       |NA, < 0      |            |
|PropMetroHh        |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|PropTownHh         |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|PropRuralHh        |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|PropWkrInMetroJobs |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|PropWkrInTownJobs  |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|PropWkrInRuralJobs |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|PropMetroJobs      |Azone |Year   |double     |proportion |NA, < 0, > 1 |            |
|MetroLandArea      |Azone |Year   |area       |ACRE       |NA, < 0      |            |
|TownLandArea       |Azone |Year   |area       |ACRE       |NA, < 0      |            |
|RuralAveDensity    |Azone |Year   |compound   |HHJOB/ACRE |NA, < 0      |            |

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

|NAME      |TABLE |GROUP |TYPE       |UNITS      |PROHIBIT |ISELEMENTOF                  |DESCRIPTION                                                                                                          |
|:---------|:-----|:-----|:----------|:----------|:--------|:----------------------------|:--------------------------------------------------------------------------------------------------------------------|
|Bzone     |Bzone |Year  |character  |ID         |         |                             |Unique ID for SimBzone                                                                                               |
|Azone     |Bzone |Year  |character  |ID         |         |                             |Azone that SimBzone is located in                                                                                    |
|Marea     |Bzone |Year  |character  |ID         |         |                             |Marea associated with Azone that SimBzone is located in                                                              |
|LocType   |Bzone |Year  |character  |category   |NA       |Urban, Town, Rural           |Location type (Urban, Town, Rural) of the place where the household resides                                          |
|NumHh     |Bzone |Year  |households |HH         |NA, < 0  |                             |Number of households allocated to the SimBzone                                                                       |
|TotEmp    |Bzone |Year  |people     |PRSN       |NA, < 0  |                             |Total number of jobs in zone                                                                                         |
|RetEmp    |Bzone |Year  |people     |PRSN       |NA, < 0  |                             |Number of jobs in retail sector in zone                                                                              |
|SvcEmp    |Bzone |Year  |people     |PRSN       |NA, < 0  |                             |Number of jobs in service sector in zone                                                                             |
|OthEmp    |Bzone |Year  |people     |PRSN       |NA, < 0  |                             |Number of jobs in other than the retail and service sectors in zone                                                  |
|AreaType  |Bzone |Year  |character  |category   |NA       |center, inner, outer, fringe |Area type (center, inner, outer, fringe) of the Bzone                                                                |
|DevType   |Bzone |Year  |character  |category   |NA       |emp, mix, res                |Location type (Urban, Town, Rural) of the Bzone                                                                      |
|D1D       |Bzone |Year  |compound   |HHJOB/ACRE |NA, < 0  |                             |Gross activity density (employment + households) on unprotected land in zone (Ref: EPA 2010 Smart Location Database) |
|D5        |Bzone |Year  |double     |NA         |NA, < 0  |                             |Destination accessibility of zone calculated as harmonic mean of jobs within 2 miles and population within 5 miles   |
|UrbanArea |Bzone |Year  |area       |ACRE       |NA, < 0  |                             |Area that is Urban and unprotected (i.e. developable) within the zone                                                |
|TownArea  |Bzone |Year  |area       |ACRE       |NA, < 0  |                             |Area that is Town and unprotected (i.e. developable) within the zone                                                 |
|RuralArea |Bzone |Year  |area       |ACRE       |NA, < 0  |                             |Area that is Rural and unprotected (i.e. developable) within the zone                                                |
|SFDU      |Bzone |Year  |integer    |DU         |NA, < 0  |                             |Number of single family dwelling units (PUMS codes 01 - 03) in zone                                                  |
|MFDU      |Bzone |Year  |integer    |DU         |NA, < 0  |                             |Number of multi-family dwelling units (PUMS codes 04 - 09) in zone                                                   |
