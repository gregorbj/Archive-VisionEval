## VisionEval Model System Design and Users Guide
**Brian Gregor, Oregon Systems Analytics LLC**  
**July 31, 2017**  
**DRAFT**


### 1. Overview
The goal of this project is to define a model system and create a supporting software framework for developing and implementing models that support strategic planning for transportation, land use, and related topics. Strategic planning is a process that is used to determine a future direction and performance goals (in other words a vision) in recognition that conditions are likely to be different in the future than they are today, and that the nature, magnitudes, and effects of future changes are uncertain. Strategic planning is mostly concerned with setting performance goals for what is to be accomplished, rather than how it is to be accomplished. Strategic planning models are analytical tools that provide a computational representation of a social/economic/environmental system for which performance goals are to be developed. The system representation has to be broad enough to address interactions between factors related to the topic of interest. Strategic planning models are more oriented to representing the breadth of relationships between factors, rather than depth in representing those relationships. This enables potential strategies to be analyzed comprehensively and in consideration of future uncertainties.  

This project is the outgrowth of the development of the GreenSTEP model, a model developed to assist the Oregon Department of Transportation (ODOT) and its partners in analyzing alternate transportation and land use strategies for reducing greenhouse gas emissions from light-duty vehicles. ODOT made this model and all of the model estimation files available under an open source license. Subsequently several other modeling tools were built from the original GreenSTEP models and code, with various modifications to serve new purposes. These models include:  
1) [Regional Strategic Planning Model (RSPM)](https://www.oregon.gov/ODOT/TD/OSTI/Pages/scenario_planning.aspx#reg);  
2) [Energy and Emissions Reduction Policy Analysis Tool (EERPAT)](https://www.planning.dot.gov/fhwa_tool/); and,  
3) [Rapid Policy Analysis Tool (RPAT)](https://planningtools.transportation.org/10/travelworks.html).  
In addition, ODOT recognized that the GreenSTEP model platform could serve more general transportation-related strategic planning purposes because it was capable of analyzing and reporting on many types of transportation, land use, and household interactions. However, although ODOT and others found that the model could be modified and expanded to serve new purposes, the design and software implementation did not make it easy to do so. The goal of this project is to correct that limitation by creating a modeling system for building strategic planning models that are extensible and completely open.


### 2. Definitions  

Following are definitions of terms used in this document:  

- **Model System**  
A definition for a set of related models and a software framework for implementing that definition. Models built in the modeling system are related by the domains being modeled (e.g. travel, energy consumption, hydrology, etc.), the 'agents' being modeled (e.g. households, cities, watersheds, etc.), how physical space is represented (e.g. zones, grids, cubes, etc.), how time is represented (e.g. continuouse vs. discrete, independent vs. dependent on past states), and other modeling goals and tradeoffs (e.g. representational detail, degree of coupling, run times, etc.). The model system definition includes specifications for model modules that can be used in the model system, file structure specifications for organizing model parameters and input data necessary for running a model. The software framework for the model system is a library of code that manages the execution of model modules that are designed to work in the model system.  


- **Model**  
A model as used in this document refers to a model such as GreenSTEP that calculates a number of different attributes (e.g. household size, household income, number of autos owned, vehicle-miles traveled, etc.) that are composed of a number of components (submodels) that each calculate one or a few attributes.  


- **Submodel**  
A submodel is the component of a model that calculates one or a few closely related attributes.  


- **Module**  
A module, at its heart, is a collection of data and functions that meet the specifications described in this document and that implement a submodel. Modules also include documentation of the submodel. Modules as made available to users as R packages.


- **Software Framework**  
A software framework is a library of code containing functions that manage the execution of modules. These functions manage all interactions between modules, model system variables, and a datastore.  


- **Datastore**  
A datastore is a file or set of files for storing all of the inputs used by modules and outputs produced by modules.  


### 3. Model System Objectives
The GreenSTEP model and related models are disaggregate strategic planning models. They are disaggregate because, like many modern transportation models, they simulate behavior at the individual household level rather than at a more aggregate 'zonal' level. This enables the assessment of how prospective policies or other changes could have different impacts on different types of households (e.g. low income vs. high income). The models are strategic planning models because they are built to support long-range strategic planning decisions such as community visioning, policy development, and scenario planning. Strategic planning processes most often need to consider a number of possibilities about how the future may unfold and a range of potential actions that might be taken. As a consequence, models built to support strategic planning need to be responsive to a large number of variables and be capable of running quickly so that a large number of runs can be done to explore the decision space. The VisionEval model system supports the development of these types of models. The design objectives for this model system are:  


- **Modularity**  
The model system will allow new capabilities to be added in a plug-and-play fashion so models can be improved and extended and so improvements developed for one model can be easily shared with other models. Models are composed of modules that contain all of the data and functionality needed to calculate what they are intended to calculate.  


- **Loose Coupling**
This objective is closely related to the *modularity* objective. Loose coupling is necessary if modules are to be added to or removed from models in a plug-and-play fashion. Loose coupling means that the parameter estimation for a submodel is independent of the parameter estimation of any other submodel. It also means that there is no direct communication between modules. All communication between modules is carried out through the transfer of data that is mediated by the software framework.  


- **Openness**  
The VisionEval software framework and all modules developed to operate in the framework will be completely open. Being open means more than sharing ones work. It means completely revealing ones work so that others can assess how the module works. All module code, parameters, data, and specifications will be open to inspection and licensed using an open source license (e.g. Apache 2) that allows users to use, modify, and redistribute as they see fit. In addition, modules will provide access to data and code to estimate the model that the module implements. Finally, a module will contain complete documentation that users may use to document the model that the module is a part of.  


- **Geographic Scalability**  
The model system will enable models to be applied at a variety of geographic scales including metropolitan areas of various sizes, states of various sizes, and multi-state regions. Although models are applied at different scales, they share common geographic definitions to enable modules to be more readily shared between models built for the modeling system.  


- **Data Accessibility**  
Model results will be saved in a datastore that is easy to query. Results can be filtered, aggregated, and post-processed to produce desired performance measures.  


- **Regional Calibration Capability**  
Modules will have built in capbilities for estimating and calibrating submodel parameters from regional data when necessary.  


- **Speed and Simplicity**  
Since the intent of the model system is to support the development of strategic planning models, it is important that the models be able to address a large number factors and be able to model a large number of scenarios. For this to occur, the framework needs to run efficiently and modules need to be simple and need to run quickly.  


- **Operating System Independence**
The model system will run on any of the 3 major operating systems; Windows, Apple, or Linux. As is the case with GreenSTEP and related models, the VisionEval model system is written in the R programming language. Well-supported and easily installed R implementations exist for these operating systems. Modules will be distributed as standard R packages that can be compiled on all operating systems. Code that is written in another language may be included in a module package as long as it can be compiled in an R package that is usable on all 3 operating systems.  


- **Preemptive Error Checking**  
The model system will incorporate extensive data checking to identify errors in the model setup and inputs at the very beginning of the model run. Error messages will clearing identify the causes of the errors. The objective of early error checking is to avoid model runtime errors that waste model execution time and are difficult to debug.

### 4. Model System Software Design Approach
The VisionEval software framework uses many of the ideas from the functional programming paradigm to create a modeling system that is modular and robust. The framework is implemented in the R programming language which is largely a functional programming language having a well developed system for managing packages of modules. This section describes how the VisionEval model system incorporates functional programming design ideas and the reason for using the R programming language for implementing those ideas.

#### 4.1 Functional Programming Inspirations for System Design
There are a number of programming paradigms for organizing software and implementing modular system designs. The VisionEval system design is most inspired by the functional programming paradigm. This section describes key characteristics of the functional design paradigm that influence the VisionEval model system design to achieve the design objectives.  

The functional programming paradigm views computing as sequences of data transformations where a functions successively process a data stream with the outputs of one function becoming the inputs of the next. Functions are data processing machines with defined inputs and outputs. Given the same set of inputs, functions always produce the same set of outputs. Although functions have requirements for the data they process, they are not bound to the data in the same way as functions (methods) in the object-oriented programming paradigm. This characteristic of the functional paradigm fits well with the 'loose coupling' objective for the model system where model modules only interact with one another through the transfer of data mediated by the framework software. The design is for each module to act like a function with the framework software calling it, providing the data the module needs, and saving the data that the module produces.

Another key characteristic of the functional programming paradigm is that functions should have no side effects. A function should only change the state of variables within it's scope and should have no effects on the system outside of its scope. The only way that a function interacts with the rest of the program is by returning the result of its calculations to whatever function called it. Such functions are called pure functions. This characteristic makes software more testable, reliable, and maintainable. It is key aspect of the VisionEval model system design. The system is designed so that modules act like pure functions. The only thing that they do is return the results of their calculations to the software framework. They do not make any changes to program variables outside their scope and they do not read from or write to files. This approach makes the framework very robust and modular because code within a module can be changed without affecting any other module.

The framework software itself is also designed to minimize side effects in order to make it more robust and maintainable. Global state variables for a model run are kept to a minimum. Almost all model run state information is kept in the 'ModelState.Rda' file (Section 6.6). A common datastore holds all of the results of model computations. The only side effects in the framework code are reading model definition and input files, reading and writing to the common datastore, and writing to a log file.

A third key characteristic of some functional programming languages is the extensive use of data typing. While compiled languages in general use data typing to check the properness of functions and expressions when a program is compiled, some functional programming languages like Haskell and Elm make extensive use of defining and checking different data types for function inputs and outputs. They also include a type notation system for documenting functions. This makes it easier to check and understand the code. An analogous approach is used in the VisionEval system design. Each module includes specifications for all data that it consumes and all data that it produces. This enables the framework software to check that modules will work properly together and enables a model to be checked thoroughly before it is run so to eliminate run time errors. It also clearly documents to others what data the module uses and what it produces.

#### 4.2 Use of the R Software Environment to Implement the Model System
The VisionEval model system is built in the R programming language for statistical computing and graphics. R is an open-source variant of the S programming language developed at Bell Labs but is more functional in nature than S. Although R was primarily developed to be an interactive programming environment for data analysis, the language has a full set of features that enables it to be used for all steps in the modeling process from data preparation and cleaning through model implementation and output visualization. The language is augmented by thousands of packages supporting data analysis, programming, and visualization. The interactive nature of the language, range of capabilities, and large number of supporting packages enabled the the GreenSTEP model to be developed in an agile manner in a relatively short period of time. At the time, no other programming language had this range of capabilities and the large number of supporting packages. The VisionEval model system uses the R language for the following reasons:   
1) The existing code base for the GreenSTEP model and related models is written in R. Writing the VisionEval software framework in R enables this code base to be moved to the new framework with much less effort than would be required if it had to be rewritten in another programming language.  
2) R is open-source software that is available on all major operating systems so the model system will be operating system independent.
3) R has a very good and well tested package system for packaging modules that is well supported with documentation and build tools. The package system and development tools also include easy-to-use capabilities for documentation, including literate programming. This simplifies the development of the software framework and simplifies the process for module developers to produce complete and well documented modules.  
4) R has the most extensive set of statistical and other data analysis packages available. Because of this, almost any type of model can be estimated using R and therefore, modules can contain not only full documentation of model estimation, but also scripts that allow model estimation to be replicated and rerun using regional data.  
5) R is an interpreted language with capable (and free) integrated development environments. Because the state of objects can be easily queried, the process of building and testing models is simplified. This makes it easier for modelers who don't come from a computer science background to develop models to be deployed in the model system.  
6) Although as an interpreted language, R is slower than compiled languages, most of the core functions are "vectorized" functions that are written in C. This means that R programs can carry out many operations very quickly. In addition, it is relatively easy to call functions written in compiled languages such as C++, C, and Fortran to R so that if a pure R model is not fast enough, portions can be written as functions in a compiled language and linked to the R code.  
7) R has a large user base and so it is relatively easy for users to get answers to programming questions.  

### 5. Model System Layers
The VisionEval model system is composed of 3 layers:  
1) **Model**: The model layer defines the structure of the model and organizes all of the modules into a coherent model. The model layer includes a module run script, model definition files, model input files, and common datastore.   
2) **Modules**: The module layer is the core of a model. Modules contain all of the code and parameters to implement submodels which are the building blocks of models.  
3) **Software Framework**: The software framework layer provides the functionality for controlling a model run, running modules, and interacting with the common datastore.   
These layers are illustrated in Figure 1. Following sections describe the design and specifications for each layer.

**Figure 1. Overview of VisionEval Model System**  
![Framework Diagram](img/framework_overview.png)

A VisionEval model is built from a set of compatible modules, a set of specifications for the model and geography, a set of scenario input files, and a simple R script that initializes and runs the model. Following is a simple example of a model script:

```
#Initialize and check the model
initializeModel(
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = FALSE,
  DatastoreName = NULL,
  SaveDatastore = TRUE
)

#Run modules for all forecast years
for(Year in getYears()) {
  runModule(
    ModuleName = "CreateHouseholds", 
    PackageName = "SimHouseholds",
    RunFor = "AllYears")
  runModule(
    ModuleName = "PredictWorkers",
    PackageName = "SimHouseholds",
    RunFor = "AllYears")
  runModule(
    ModuleName = "PredictLifeCycle",
    PackageName = "SimHouseholds",
    RunFor = "AllYears")
  runModule(
    ModuleName = "PredictIncome",
    PackageName = "SimHouseholds",
    RunFor = "AllYears")
  ...
}


```

A full model run script is shown in Appendix A.   

The script calls two functions that are defined by the software framework; *initializeModel* and *runModule*. The *initializeModel* function initializes the model environment and model datastore, checks that all necessary modules are installed, and checks whether all module data dependencies can be satisfied. The arguments of the *initializeModel* function identify where key model definition data are found. The *runModule* function, as the name suggests, runs a module. The arguments of the *runModule* function identify the name of the module to be run, the package the module is in, and whether the module should be run for all years, only the base year, or for all years except for the base year. This approach makes it easy for users to combine modules in a 'plug-and-play' fashion. One simply identifies the modules that will be run and the sequence that they will be run in. This is possible in large part for the following reasons:  
1) The modules are loosely coupled. Modules only communicate to one another by passing information to and from the datastore.  
2) The framework establishes standards for key shared aspects of modules including how data attributes are specified and how geography is represented.  
3) Every module includes detailed specifications for the data that are inputs to the module and for the data that are outputs from the module. These data specifications serve as contracts that the framework software enforces.  
  These features and how they are designed are described in detail in following sections.  

### 6. Model Layer Description
The model layer is composed of:  
- The directory (i.e. folder) and file structure for organizing scenario inputs and model parameters;  
- Model parameter files describing the model geography (consistent with standard definitions) and global parameters;  
- The model run script that lists the model execution steps; and,  
- The datastore which stores all of the data produced during the execution of the model.  
Each of these components is described in the following subsections.

#### 6.1. Model Directory Structure  
A model application has a very simple directory structure as shown in the following representation of a directory tree.

```
my_model
|   run_model.R  
|   <ModelState.Rda>  
|   <logXXXX.txt>  
|   <datastore.h5>  
|     
|  
|____defs
|    |   run_parameters.json
|    |   model_parameters.json
|    |   geography.csv  
|    |   units.csv  
|    |   deflators.csv  
|  
|  
|____inputs  
     |   filename.csv  
     |   filename.csv  
     |   ...  
         
```

The overall project directory, named *my_model* in this example, may have any name that is allowed by the operating system the model is being run on. One file is placed in this top level directory by the user, "run_model.R". Three additional files, denoted in the diagram by angled brackets, are created in the course of checking and running the model.

The "run_model.R" file, introduced in the previous section, initializes the model environment and datastore, checks that all necessary packages are installed, checks whether data dependencies can be satisfied, and then runs modules in a specified sequence. Data checks are performed before any modules are run to catch any errors. This saves time and the aggravation that occurs when a model run fails in midstream due to incorrect data inputs or other errors due to incorrect model setup. Data checking in advance is possible because every module includes detailed specifications for its input and output data. All scenario input files are checked against specifications to determine whether the required data exist and are correct. In addition, the state of the datastore is 'simulated' in the order that each module will be run to determine whether the data each module needs will be available in the datastore. After the model has been initialized and all all data checks are satisfactory, the modules are executed in the sequence prescribed in the script. 

The "ModelState.Rda" file is a R binary file that contains a list that holds key variables used in managing the model run. The file is created when the model run is initialized and is updated whenever the state of the datastore changes. Framework functions read this file when necessary to validate data and to determine that datastore read and write operations can be completed successfully. This file is described in more detail in section 6.6.

The "logXXXX.txt" file is a text file that is created when the model is initialized. This log file is used to record model run progress and any error or warning messages. The 'XXXX' part of the name is the date and time when the log file is created.

The "datastore.h5" file is an hdf5 formatted file that contains the central datastore for the model. Its structure is described in detail below. Users may use a different name for this file by specifying the name to be used in "parameters.json" file (see below). 

The "defs" directory contains all of the definition files needed to support the model run. Five files are required to be present in this directory: "run_parameters.json", "model_parameters.json", "geography.csv", "deflators.csv", and "units.csv".   

The "run_parameters.json" file contains parameters that define key attributes of the model run and relationships to other model runs. The file is a [JSON-formatted](http://www.json.org/) text file. The JSON format is used for several reasons. First, it provides much flexibility in how parameters may be structured. For example a parameter could be a single value or an array of values. Second, the JSON format is well documented and is very easy to learn how to use. It uses standard punctuation for formatting and, unlike XML, doesn't require learning a [markup language](https://en.wikipedia.org/wiki/Markup_language). Third, files are ordinary text files that can be easily read and edited by a number of different text editors available on all major operating systems. There are also a number of commercial and open source tools that simplify the process of editing and checking JSON-formatted files.  

The "run_parameters.json" file specifies the following parameters:  

- **Model** The name of the model. Example: "Oregon-GreenSTEP".  

- **Scenario** The name of the scenario. Example: "High-Gas-Price".  

- **Description** A short description of the scenario. Example: "Assume tripling of gas prices".   

- **Region** The name of the region being modeled. Example: "Oregon".  

- **BaseYear** The base year for the model. Example: "2015".  

- **Years** An array of all the 'forecast' years that the model will be run for. Example: ["2025", "2050"].  

- **DatastoreName** The name of the datastore. It is recommended that this be named "datastore.h5" for all model runs but it can be any name that is valid for the operating system.   

- **DatastoreReferences** This is a listing of other datastores that the framework should look for requested data in. This capability to reference other datastores enables users to split their model runs into stages to efficiently manage scenarios. For example, a user may wish to model how several transportation scenarios work with each of a few land use scenarios. To do this, the user could first set up and run the model for each of the land use scenarios. The user could then set up the transportation scenarios and make copies for each of the land use scenarios. Then the user would for each of the transportation scenarios reference the datastore of the land use scenario that it is associated with. The DatastoreReferences entry would look something like the following (the meaning of the entries is explained below):  
  "DatastoreReferences": {  
    "Global": "../BaseYear/datastore.h5",  
    "2010": "../BaseYear/datastore.h5"  
  }  
  
- **Seed** This is a number that modules use as a random seed to make model runs reproducible.  

The "model_parameters.json" can contain global parameters for a particular model configuration that may be used by multiple modules. For example, a model configuration to be a GreenSTEP model may require some parameters that are not required by a model configuration for an RSPM model. For example, the GreenSTEP model uses a parameter that is the total base year DVMT by light-duty vehicles to calibrate a factor used to compute commercial service vehicle travel. Parameters in this file should not include parameters that are specific to a module or data that would more properly be model inputs. While this file is available to establish global model parameters, it should be used sparingly in order enhance transferrability of modules between different models.

The "geography.csv" file describes all of the geographic relationships for the model and the names of geographic entities in a [CSV-formatted](https://en.wikipedia.org/wiki/Comma-separated_values) text file. The CSV format, like the JSON format is a plain text file. It is used rather than the JSON format because the geographic relationships are best described in table form and the CSV format is made for tabular data. In addition, a number of different open source and commercial spreadsheet and GIS programs can export tabular data in a CSV-formatted files. The structure of the model system geography is described in detail in Section 6.2 below.  

The "units.csv" file describes the default units to be used for storing complex data types in the model. The VisionEval model system keeps track of the types and units of measure of all data that is processed. The model system recognizes 4 primitive data types, a number of complex data types (e.g. currency, distance), and a compound data type. The primitive data types are data types recognized by the R language: 'double', 'integer', 'character', and 'logical'. The complex data types such as 'distance' and 'time' define types of data that have defined measurement units and factors for converting between units. The compound data type combines two or more complex data types whose units are defined in an expression (e.g. MI/HR). The *units.csv* describes the default units used to store complex data types in the datastore. The file structure and an example are described in more detail in Section 6.3 below.

The "deflators.csv" defines the annual deflator values, such as the consumer price index, that are used to convert currency values between different years for currency demonination. The file structure and an example are described in more detail in Section 6.4 below.

The "inputs" directory contains all of the input files for a scenario. All input files are CSV-formatted text files. Each module specifies what input files it needs and names and types of data to be included in the needed files. There are several requirements for the structure of input files. These requirements are described in section 6.5 below.

#### 6.2. Model Geography

The design of the model system includes the specification of a flexible standard for model geography in order to fulfill the objectives of *modularity* and *geographic scalability*. As a standard, it specifies levels of geographical units, their names, their relative sizes, and the hierarchical relationships between them. It is flexible in that it allows geographical boundaries to be determined by the user and it allows the units in some geographical levels to be simulated rather than being tied to actual physical locations. Allowing simulation of one or more geographic levels enables modules to be shared between models that operate at different scales. For example a statewide model and a metropolitan area model could use the same module for assigning households to land development types even though the statewide model lacks the fine scale of geography of the metropolitan model. 

Following is the definition of the geographic structure of the VisionEval model system:  

- **Region**  
The region is the entire model area. Large-scale characteristics that don't vary across the region are specified at the region level. Examples include fuel prices and the carbon intensities of fuels.  


- **Azones**  
Azones are large subdivisions of the region containing populations that are similar in size to those of counties or Census Public Use Microdata Areas (PUMA). The counties used in the GreenSTEP and EERPAT models and metropolitan divisions used in the RSPM are examples of Azones. Azones are used to represent population and economic characteristics that vary across the region such as demographic forecasts of persons by age group and average per capita income. Azones are the only level of geography that is required to represent actual geographic areas and may not be simulated.  


- **Bzones**  
Bzones are subdivisions of Azones that are similar in size to Census Block Groups. The districts used in RSPM models are examples of Bzones. Bzones are used to represent neighborhood characteristics and policies that may be applied differently by neighborhood, for example in the RSPM:  
  - District population density is a variable used in several submodels;  
  - An inventory of housing units by type by district is a land use input; and,  
  - Carsharing inputs are specified by district.  

  In rural areas, Bzones can be used to distinguish small cities from unincorporated areas. Bzones may correspond to actual geographic areas or may be simulated. For example, a submodel of the GreenSTEP model estimates the likely distribution of Census Tract densities for a metropolitan area given an overall population density for the metropolitan area. This submodel will be converted in the model system so that it creates a set of simulated Bzones having densities that represent the likely distribution of Census Tract densities.  


- **Czones**  
Czones are subdivisions of Bzones that describe more detailed land use characteristics such as whether an area is typified by residential development, commercial development, or mixed-use development. These characteristics may be described using a classification system such as the *development type* system, used by the GreenSTEP and RSPM models, or the *place type* system used by the RPAT model. A Czone may be any size, up to and including the Bzone that it is located within. As with Bzones, Czones may correspond to actual geographic areas such as the traffic analysis zones defined for an urban travel demand model. Perhaps more commonly, Czones will be synthesized based on scenario inputs and attributes of the Azones and Bzones they are situated within.  


- **Mareas**  
Mareas are associated with urbanized portions of metropolitan areas. Mareas are used to specify and model urbanized area transportation characteristics such as overall transportation supply (transit, highways) and congestion. A Marea does not exist in a strict hierarchical relationship with Azones and Bzones because the Marea boundary is likely to change over time as the urbanized area population grows. While a Marea will be associated with one or more Azones and Bzones, its boundary may be located inside or outside the boundaries of the Azones and Bzones it is associated with. Czones are used to represent the geographic extent of the Marea and land use characteristics of portions of it. Changes in the urbanized area boundary are modeled as changes in Czone designations.


Geographical relationships for a model are described in the "geography.csv" file contained in the "defs" directory. This file tabulates the names of each geographic unit (except for Region) and the relationships between them. Each row shows a unique relationship. Where a unit of geography is not explictly defined (i.e. it will be simulated), "NA" values are placed in the table. Appendix B shows examples of the "geography.csv" file where only Azones are specified and where Azones and Bzones are specified. It should be noted that there are no naming conventions for individual zones. The user is free to choose what conventions they will use.

#### 6.3. Data Types, Units, and Currency Deflators

A key feature of the VisionEval model system that enables modules to be bound together into models is a data specifications system. All datasets that a module requires as inputs and datasets that that a module produces must be specified according to requirements. Section 8 describes these specifications in more detail. This section provides an introduction to the TYPE and UNITS specification requirements to provide context for understanding the "units.csv" file in the "defs" directory.

The TYPE attribute for a dataset identifies the data type. The UNITS specification identifies the units of measure. The TYPE and UNITS specifications are related. The TYPE attribute affects the values that may be specified for UNITS attribute and how the framework processes the units values. The model system recognizes 3 categories of data types: 'primitive', 'complex', 'compound'. The 'primitive' category includes the 4 data types recognized by the R language: double, integer, character, and logical. A dataset that is specified as one of these types has no limitations on how the units of measure are specified. The 'complex' category currently includes 10 data types: currency, distance, area, mass, volume, time, people, vehicles, trips, and households. A dataset that is one of these types is limited to specified unit values. For example, the allowed units for the 'distance' type are MI, FT, KM, and M (for mile, foot, kilometer, and meter). The 'compound' category is composed of the compound data type. For compound data, units are represented as an expression involving the units of complex data types. For example, a dataset of vehicle speeds can be specified as having a TYPE that 'compound' and UNITS that are 'MI/HR'. The type is compound because it is made up of two complex types; distance and time. The units are an expression containing distance and time units and the '/' operator. The '*' (multiplication) operator may also be used in the units expression for a compound data type. Appendix C documents all the types and units in more detail. 

Although the complex and compound data types limit what values the units attributes may have, specifying these types enables the framework software to take care of unit conversions between modules and the datastore. For example, say that a model datastore contains a dataset for Bzone population density having units of persons per square mile. In this case the TYPE attribute for the data would be 'compound' and the UNITS would be 'PRSN/SQMI'. If a module which calculates household vehicle travel needs population density measured in persons per acre, the module would specify the UNITS as 'PRSN/ACRE' and the framework would take care of converting the density values from the units used in the datastore to the units requested by the module. This simplifies matters for module developers and reduces the likelihood of errors due to data conversions. 

Although the units specified by a module for a complex data type may be any of the recognized units (e.g. for distance - MI, FT, KM and M), this flexibility does not apply to the datastore. Complex data is stored in the datastore in predefined ways to limit potential confusion and simplify unit conversions. The default units file (units.csv) in the "defs" directory declares the default units to use for storing complex data types in the datastore. This file has two fields named 'Type' and 'Units'. A row is required for each complex data type recognized by the VisionEval system. The listing to date of complex types and the default units in the demonstration models are as follows:

|Type      |Units|
|----------|-----|
|currency  |USD  |
|distance  |MI   |
|area      |SQMI |
|mass      |LB   |
|volume    |GAL  |
|time      |DAY  |
|people    |PRSN |
|vehicles  |VEH  |
|trips     |TRIP |
|households|HH   |

For 'currency' data it's not sufficient to convert values to different units, it's also necessary to convert values between years since the value of money changes over time due to inflation. For example, if household income is a variable in a household travel model that was estimated using data from 2000, then when that model is applied to forecast travel in other years, the income data for the forecast years must be deflated to reflect the value in the model estimation year (2000). The software framework takes care of this process if a proper series of deflators are provided and if the units include the currency year (as described below). That information is used to convert currency to and from base year currency values (what is kept in the datastore).

The deflator series is defined for the model in the "deflators.csv" file in the "defs" directory. This file has 2 columns, 'Year' which contains an annual series of years, and 'Value' which contains corresponding deflator values (e.g. consumer price index). The earliest year in the deflator series must be sufficient to cover all of the years specified for modules which use currency data. The latest year must be sufficient to cover the base year and any later years that the model may be run for (excluding future forecast years of course). For example, the 'PredictIncome' module in the 'VESimHouseholds' package was estimated from 2000 Census PUMS data. Those data include household income for the previous year (1999). Therefore the "deflators.csv" file must include deflator values going back to 1999. If the base year for the model is 2010, the deflator series must go up to 2010; and if a later year such as 2015 is to be modeled, the deflator series must go up to that year.

Modules must include the currency year for datasets to be retrieved from the datastore and to be saved to the datastore. This is done by adding a period and 4-digit year to the UNITS attribute. For example, the UNITS specification for year 2000 dollars would be 'USD.2000'. Note, however, that this convention does not apply to specifications for currency data that is read in from input file. In those cases, the year is specified in the input file. This is explained in Section 6.4.

The UNITS value may also specify a multiplier option for complex and compound data types. This capability exists because modules may use data that is represented in thousands or millions when numbers are very large. For example total income and total VMT are often reported in this way. A multiplier option is added to a units name by adding a period and then the multiplier expressed in scientific notion where the leading digit must be a 1 (e.g. 1e3 for thousands). For currency units, the multiplier option must follow the year notation. For example, 2010 dollars expressed in millions would be expressed as 'USD.2010.1e6'. Miles traveled expressed in millions would be 'MI.1e6'.

#### 6.4. Model Inputs
The *inputs* directory contains all of the model inputs for a scenario. A model input file is a table that relates one or more input fields to geographic units and years. Because of the tabular nature of the data, all input files are CSV-formatted text files.  

At present, two types of input files are accommodated. These files differ with respect to whether the specified attribute values vary by 'forecast' year. For example, a file containing input assumptions about the cost of fuel, road use taxes, etc. would have values that vary  by 'forecast' year. In contrast, the files used to specify the characteristics of vehicles of different powertrain types have values that vary by vehicle model year, not 'forecast' year. The structure of these two types of input files, and how their values are organized in the datastore, differ.

All input files that have values which vary by 'forecast' year have at least three columns; two mandatory columns that specify geography ("Geo") and year ("Year"), and one or more data columns. Each row specifies a unique geographic unit and year combination. For example, if a model that has 10 Azones is being run for 2 'forecast' years, then an a table of inputs specified at the Azone level would contain 20 rows (in addition to the header row). The software framework checks these files to make sure that they contain values for all the required combinations of geography and year. 

By convention, input file names which include inputs that vary by level of geography, include the level of geography in the input file name. File names should be descriptive. Following are some examples:  
- azone_hh_pop_by_age.csv  
- azone_hhsize_targets.csv  
- bzone_dwelling_units.csv

Input files that do not vary by 'forecast' year do not have any required columns.

The name of an input file and the names of all the columns except for the "Geo" and "Year" columns are specified by the module that requires the input data. In addition to specifying the file and column names, the module specifies:  
- The level of geography the inputs are specified for (e.g. Azone, Bzone, Czone, Marea);  
- The data types in each column (e.g. integer, double, currency, compound);  
- The units of the data in each column (e.g. MI, USD); and,  
- Acceptable values for the data in each column.  

The module section describes these specifications in more detail below. Appendix D shows examples of the two types of input files.  

The field names of the input file (other than the "Geo" and "Year" fields) can encode year and unit multiplier information in addition to the name of the data item. This is done by breaking the name into elements with periods (.) separating the elements as follows:  

For 'currency' data type: **Name.Year.Multiplier**
For all other data types: **Name.Multiplier**

Where: 
**Name** is the dataset name. This must be the same as specified in the module that calls for the input data.  
**Year** is the four-digit representation of the year that the currency values are denominated for. For example if a currency dataset is in 2010 dollars, the Year value would be 2010'. The field name for a currency field must include a Year element.
**Multiplier** is an optional element which identifies the units multiplier. It must be expressed in scientific notation (e.g. 1e3) where the leading digit must be 1. This capability exists to make it easier for users to provide data inputs that may be more conviently represented with a smaller number of digits and an exponent. For example, annual VMT data for a metropolitan area or state is often represented in thousands or millions.

The the VisionEval framework uses the year and multiplier information to convert the data to be stored in the datastore. All currency values are stored in base year currency units and all values are stored without exponents.

#### 6.5. The Datastore
Currently GreenSTEP/RSPM and related models store data in R binary files (rda files). The largest of these files are the simulated household files which store all of the information for all simulated households in an Azone (e.g. counties in GreenSTEP). All the data for households in the Azone are stored in a data frame where each row corresponds to a record of an individual household and the columns are household attributes. Vehicle data for households are stored as lists in the data frame. This approach had some benefits:  
- Storage and retrieval are part of the R language: one line of code to store a data frame, and one line of code to retrieve;  
- It is easy to apply models to data frames; and  
- Vehicle data can be stored as lists within a household data frame, eliminating the need to join tables.  

The simplicity of this approach helped with getting GreenSTEP from a concept into an operational model quickly. However, several limitations have emerged as GreenSTEP and related models have been used in various applications including:  
- Large amounts of computer memory are required when modeling Azones that have large populations. This necessitates either expanding computer memory or limiting the size of Azones;  
- It is not easy to produce summary statistics from the simulated household files for a region; and  
- The number of non-household data files has proliferated in order to store various aggregations for use in the model and for later summarization.

The VisionEval model system uses the HDF5 file format for storing model data, rather than using R binary files. The HDF5 file format was developed by the National Center for Supercomputing Applications (NCSA) at the University of Illinois and other contributors to handle extremely large and complex data collections. For example, it is used to store data from particle simulations and climate models. It also is the basis for the new open matrix standard for transportation modeling, [OMX](https://github.com/osPlanning/omx).  

The HDF5 format was chosen over SQL databases because it reads and writes data faster than SQL alternatives that were tested. It also provides random data access in a way that is analogous to how data in R data structures can be indexed. Large complex data sets can be randomly accessed by organizing datasets in a hierarchy of groups and by accessing portions of datasets by using indexing. In addition, metadata can be stored as attributes of any data group or data item. Testing showed that the aggregate time for reading data from an HFD5 file, applying a model, and writing the result back to the HDF5 file was competitive with the aggregate time for doing these things using R binary files.

An HDF5 file is organized in groups and datasets. Groups provide the overall structure for organizing data, just as file system provides the structure for organizing files on a computer disk. A `/` indicates the root group. Subgroups are created with names. So for example, data for the year 2050 could be stored in a `/2050` group. Household data for the year 2050 is stored in a `/2050/Household` group. Some groups, like the *Household* group just mentioned, are used to store tabular data in the same way that the existing model stores tabular data in data frames. Just like a data frame, each component (dataset) can store a different type of data than other components, but all datasets must have the same length. The framework enforces the equal length requirement by storing a *LENGTH* attribute with the table group and using this attribute when initializing a new dataset to include in the table. The software framework stores information about the data type contained in a dataset as well as other key attributes that are identified in module specifications. Datasets in tables are accessed by supplying the name of the dataset and the full path name to the table where the dataset is stored (e.g. `/2050/Household/Income` for a household income dataset for the year 2050). Indexes may be used to read and write portions of a dataset. The software framework includes a function that calculates indexes for different geographical units.

The structure of the datastore to implement existing models (GreenSTEP, RSPM, EERPAT, RPAT) is shown in the following diagram which is organized like a directory tree. The first level of the tree denotes groups that are collections of tables. There are two types of groups at this level: the 'Global' group, and 'Year' groups (e.g. 2010, 2050). The 'Global' group is used to store data that is not organized by forecast year. The vehicle characteristics datasets used in the GreenSTEP, RSPM, and EERPAT models are examples. These data are organized by vehicle model year rather than forecast year. The 'Year' groups store datasets that are organized by forecast year. For example, regional cost inputs vary by forecast year. The second level of the tree denotes groups that represent data tables. These groups hold collections of datasets (vectors of data) that hold different types of data but all have the same lengths. Tables in the *Global* group are organized by 'topic' (e.g. HEV vehicle characteristics, EV vehicle characteristics). Tables in 'forecast year' groups include tables for each level of geography as well as 'Households' and 'Vehicles' tables which store attributes of the simulated households and the vehicles they own.

```    
|____Global
|    |____AutoLtTrkMpg
|    |        Year
|    |        Auto
|    |        LtTruck
|    :
|
|____2010  
|    |____Region
|    |        FuelCost
|    |        KwhCost
|    |        VmtTax
|    |        ...
|    |
|    |____Azone
|    |        ...
|    |
|    |____Bzone
|    |        ...
|    |
|    |____Czone
|    |        ...
|    |
|    |____Marea
|    |        ...
|    |
|    |____Households
|    |        ...
|    |
|    |____Vehicles
|    |        ...
|    :
|
|
|____2050  
|    |____ ...
|    |        ...
:    :

```

This structure is adequate to store all of the data that are used by the GreenSTEP/RSPM models and their offshoots. It can also be easily expanded to serve new modeling capabilites. For example if a module is added to model building stock, a 'Buildings' table could be added to each 'forecast year' group. In addition, since HDF5 files can store matrix data as well as vector data, if a future module makes use of a distance matrix, that matrix could be added to either the 'Global' group or the 'forecast years' groups.  

#### 6.6 The Model State File  
The model state file, "ModelState.Rda", maintains a record of all of the model run parameters and an inventory of the contents of the datastore. The software framework functions use this information to control the model run and to perform checks on module and data validity. The model state file contains a list which has the following components:  
- Model: The name of the model  
- Scenario: The name of the scenario  
- Description: A description of the scenario  
- Region: The name of the region being modeled  
- BaseYear: The model base year  
- Years: A list of years the model is being run for  
- DatastoreName: The file name for the datastore  
- Seed: The value to be used for the random seed  
- LastChanged: The date and time of the last change to the model state  
- Deflators: A data frame of deflator values by year  
- Units: A data frame of default units for complex data types  
- LogFile: The file name of the log file  
- Datastore: A data frame containing an inventory of the contents of the datastore  
- Geo_df: A data frame containing the geographic definitions for the model  
- BzoneSpecified: A logical value identifying whether Bzones are specified for the model  
- CzoneSpecified: A logical value identifying whether Czones are specified for the model  
- ModuleCalls_df: A data frame identifying the sequence of 'runModule' function calls and arguments  

The Datastore component is updated every time the data is written to the datastore. This enables framework functions to 'know' the contents of the datastore without having to access the datastore. The Datastore component keeps track of all groups and datasets in the datastore and their attributes such as the length of tables and the specifications of datasets.

### 7. Overview of Module and Software Framework Layer Interactions
Modules are the heart of the VisionEval model system. Modules contain all of the code and parameters to implement submodels that are the building blocks of models. Modules are distributed in standard R packages. A module contains the following components:  
- Data specifications for data that is to be loaded from input files, data that is to be loaded from the datastore, and data that is to be saved to the datastore;  
- Data for all parameters estimated/calibrated for use in the submodel;  
- One or more functions for implementing the submodel;  
- Functions for estimating/calibrating parameters using regional data supplied by the user (if necessary); and,  
- Documentation of the module and of submodel parameter estimation/calibration.  

The software framework provides all of the functionality for managing a model run. This includes: 
- Checking module specifications for consistency with standards;
- Checking input files for compliance with module specifications;
- Processing input files to load the input data into the datastore;
- Simulating the data transactions in a model run to check whether the datastore will contains the data each module needs when the module needs it;
- Loading module packages;  
- 'Running' modules in accordance with the 'run_model.R' script;  
- Fetching from the datastore, data that is required by a module;  
- Saving to the datastore, data that a module produces and specifies is to be saved; and,  
- Converting measurement units and currency years when necessary.

When the software framework "runs" a module it does several things. First, it reads the module data specifications and the main module function which performs the submodel calculations. Then it reads in all the datasets from the datastore that the module specifies. It also reads in the contents of the model state file. It puts these datasets into an input list and then it calls the main module function with this input list as the argument to the function call. This list, which by convention is called 'L', contains 4 components: Global, Year, BaseYear, and G. The Global, Year, and BaseYear components contain lists which are composed of table components which are in turn composed of dataset components. The Global component relates to the 'global' group in the datastore. The Year component relates to the the group in the datastore for the model run year. For example, if the model run year is 2040, the Year component will contain data that is read from the '2040' group in the datastore. The BaseYear component relates to the group in the datastore which represents the base year for the model. For example if the model base year is 2010, the BaseYear component will contain data that is read from the '2010' group in the datastore. The list contains a BaseYear component as well as a Year component because modules may need to compute changes in a dataset between the base year and the model run year. Each of these components will contain a component for each table in the the module requests data from. The table component is also a list which then contains components for all the requested datasets. For example, if a module needs the household income ('Income') and household size ('HhSize') datasets from the 'Household' table in the model run year (e.g. 2040), the Year component of 'L' will contain a 'Household' component which will contain an 'Income' component and a 'HhSize' component.

The 'G' component of 'L' contains the model state list which contains all the information described in Section 6.6.

When the module executes, it return a list containing all of the information that the module specifies is to be written to the datastore. By convention, this list is called 'R'. This list also has Global, Year, and BaseYear components which are structured in the same way that 'L' is structured. The table and dataset components of the list also include some attributes (metadata) which are described in Section 8.

### 8. Modules  
All modules are made available in the form of standard R packages that meet framework specifications. A package may contain more than one module. The package organization follows the standard organization of R packages. The structure is shown in the following diagram. The components are described below in the order that they are presented in the diagram. The file names are examples.

```
VESimHouseholds
|   DESCRIPTION
|   NAMESPACE
|   LICENSE
|     
|
|____R
|    |   CreateHouseholds.R  
|    |   PredictWorkers.R
|    |   CreateEstimationDatasets.R
|    |   ...
|
|
|____inst  
|    |    NOTICE
|    |____extdata  
|         |   pums_households.csv
|         |   pums_households.txt
|         |   pums_persons.csv
|         |   pums_persons.txt
|         |   ...
|         
|
|____tests
|    |____defs
|    |    |   run_parameters.json
|    |    |   model_parameters.json
|    |    |   geography.csv  
|    |    |   units.csv  
|    |    |   deflators.csv  
|    |
|    |____inputs
|    |    |   azone_hh_pop_by_age.csv
|    |    |   azone_gq_pop_by_age.csv
|    |    |   ...
|    |
|    |----scripts
|    |    |   test.R
|    |    |   ...
|
|
|____vignettes
|    |   VESimHouseholds.Rmd
|    |   CreateHouseholds.Rmd
|    |   PredictWorkers.Rmd
|    |   ...
|
|
|____data
|    |   Hh_df.rda
|    |   CreateHouseholdsSpecifications.rda
|    |   HtProb_HtAp.rda
|    |   PredictWorkersSpecifications.rda
|    |   PropHhWkr_HtAg.rda
|    |   ...
|
|
|____man
     |   CreateHouseholds.Rd
     |   PredictWorkers.Rd
     |   ...

```

The *DESCRIPTION* and *NAMESPACE* files are standard files required by the R package system. There are good sources available for describing the required contents of these files ([R Packages](http://r-pkgs.had.co.nz/)), so that will not be done here. Most of the entries in these files can be produced automatically from annotations in the R scripts that will be described next, using freely available tools such as [devtools](https://github.com/hadley/devtools) and [RStudio](https://www.rstudio.com/). The *LICENSE* file contains the text for the Apache 2 license which is the open source license that should be used for VisionEval packages.

#### 8.1. The R Directory
The *R* directory is where all the R scripts are placed which define the modules that are included in the package. Each module is defined by a single R script which has the name of the module (and the .R file extension). A module script does three things:  
1) It defines all of the parameters that are used by the submodel that the module implements. This can be done through simple declarations or through the application of more sophisticated statistical parameter estimation methods.  
2) It defines all the specifications for data that the module depends on.  
3) It defines all of the functions that implement the submodel.  
  Each of these actions is described below. An example of the CreateHouseholds module script from the VESimHouseholds package is included in Appendix E.  

The **parameter definition** section of the module script does several things. First, if any of the data to be used in parameter calculations is contained in files (placed in the 'inst/extdata' directory), the script describes specifications for the data to be read from those files. This is done to assure that the parameters are calculated from correct data. All parameter estimation data input files are CSV-formatted text files located in the "inst/extdata" directory. The data specifications for each file are organized in a list. A separate specification list is provided for each file that is to be read in. The specifications for a file identify the require data columns and the required attributes of those data. Following is an example:

```
PumsHhInp_ls <- items(
  item(
    NAME =
      items("SERIALNO",
            "PUMA5",
            "HWEIGHT",
            "UNITTYPE",
            "PERSONS"),
    TYPE = "integer",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "BLDGSZ",
    TYPE = "integer",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "HINC",
    TYPE = "double",
    PROHIBIT = c("NA"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
```
The meanings of these specifications are as follows:  
- **NAME** This is the name(s) of the data column in the file. The name must be a character string (i.e. surrounded by quotation marks). If multiple columns of the file have the same specifications except for their names, they can listed as in the first item in the example. This method avoids a lot of redundant data entry. Note that the order of specifications does not need to be the same as the order of the columns in the file. Also note that it is OK if the file contains columns that are not specified, as long as it contains all of the columns that are specified. Columns that are not listed are ignored.  
- **TYPE** This the data type of the data contained in the column. Allowable types are the 4 primitive types recognized by the R language (integer, double, character, and logical), the complex types listed in section 6.4, or 'compound'. The type must be a character string.  
- **PROHIBIT** This is a character vector which identifies all prohibited data conditions. For example, the specification for the "PERSONS" data column in the example above is c("NA", "< 0"). This means that there cannot be any values that are undefined (NA) or less than or equal to 0. The symbols that may be used in a PROHIBIT specification are: NA, ==, !=, <, <=, >, >= (i.e. undefined, equal to, not equal to, less than, less than or equal to, greater than, greater than or equal to). Note that prohibited conditions must be represented as character strings. If there is more than one prohibited condition, as in the example, the conditions must be entered as an R vector using the 'c()' function, as shown in the example. The absence of prohibited conditions is represented by an empty character string (i.e. "").  
- **ISELEMENTOF** This is a vector which specifies the set of allowed values. It is used when the input values must be elements of a set of discrete values. The vector describing the set must be of the same type as is specified for the input data. Vectors of elements are entered using the 'c()' function. The absence of a specification for this is represented by an empty character string.  
- **UNLIKELY** This is a vector of conditions that while not prohibited, are not likely to occur. While conditions identified in the PROHIBIT and ISELEMENTOF specifications will produce an error if they are not met (thereby stopping the calculation of parameters), the conditions identified in the UNLIKELY specification will only produce a warning message. Vectors of conditions are entered using the 'c()' function. 
- **TOTAL** This specifies a required total value for the column of data. This is useful if the data represents proportions or percentages and must add up to 1 or 100. The absence of a specification for this is represented by an empty character string.

Note that if more than one module uses the same dataset(s) for parameter estimation, it may be convenient for all data preparation to be carried out by one script which produces one or more R data frames which are saved to the data directory and loaded as needed by module scripts. That is what is done in the VESimHouseholds package. The CreateEstimationDatasets.R script creates and saves the Hh_df dataset which is used in estimating all the models in the package.

The second thing the parameters section of the module script does is define any functions that may be needed to calculate submodel parameters. These functions can be as complex as required to carry out the calculations, but they must be well documented. Function documentation is done using [Roxygen syntax](http://r-pkgs.had.co.nz/man.html).

The third thing the parameters section does is assign the parameters to objects that have the names that will be referenced by the module function or functions which implement the submodel. The value of a parameter object can be produced by a simple assignment (e.g. AveHhSize <- 2.5), by loading a parameter input file, or by calling a function that has been defined to calculate it.

The last thing the parameters section does is save the parameters. The example script in Appendix E shows how this is done. The scripts also show the required form of documentation of the saved parameters. Although the parameters may be saved as data that is internal to the package (usable by package functions but not viewable from the outside), it is recommended that they be 'exported' to make it easier for users to check the values of the parameters if they need to do so. The examples are set up to export the parameters.

The **data specifications** section of the module script provides specifications for the data that is to be read or saved and how it is to be indexed. These specifications are declared in a list that has the following 6 main components:  
- **RunBy** specifies of the level of geography that the model is to be run at. For example, the congestion submodel in the GreenSTEP and RSPM models runs at the Marea level. This specification is used by the software framework to determine how to index data that is read from the datastore and data that is written to the datastore. Acceptable values are "Region", "Azone", "Bzone", "Czone", and "Marea". 
- **NewInpTable** specifies any new tables that need to be created in the datastore to accommodate input data. The following specifications are required for each new input table that is to be created:  
  - TABLE: the name of the table that is to be created; and,
  - GROUP: the type of group the table is to be put into. There are 3 group types: Global, BaseYear, and Year. If 'Global', the table is created in the global group of the datastore. If 'BaseYear' the table is created in the year group for the base year and only in that year group. For example, if the model base year is 2010, the table will be created in the '2010' group. If 'Year', the table will be created in the group for every model run year. For example, if the run years are 2010 and 2040, the table will be created in both the '2010' group and the '2040' group.  
- **NewSetTable** specifies any new tables that need to be created in the datastore to accommodate outputs from the module identified in the 'Set' specifications (see below). The specifications for new 'Set' tables take the same form as the specifications for new input tables. The 'CreateHouseholds' module example in Appendix E includes specifications for creating a new 'Household' table in the datastore.
- **Inp** specifies the scenario input files that need to be read, the data fields that need to be read from the input files, and the attributes of the data fields. The *Inp* component is a list where each component of that list describes a data field. The following specifications are required for each data field:  
  -  NAME: the name of a data item in the input table;  
  -  FILE: the name of the file that contains the table;  
  -  TABLE: the name of the datastore table the item is to be put into;  
  -  GROUP: the type of group where the table is located in the datastore (i.e. Global, Year, BaseYear);
  -  TYPE: the data type (e.g. double, distance, compound);  
  -  UNITS: the measurement units for the data;  
  -  NAVALUE: the value used to represent NA in the datastore;  
  -  SIZE: the maximum number of characters for strings (or 0 for numeric data);  
  -  PROHIBIT: data conditions that are prohibited or "" if not applicable;  
  -  ISELEMENTOF: allowed categorical data values or "" if not applicable;  
  -  UNLIKELY: data conditions that are unlikely or "" if not applicable; and,  
  -  TOTAL: the total for all values (e.g. 1) or "" if not applicable.
  
  The values that may be entered for the TYPE and UNITS attributes are described in Section 6.3. It should be noted that the UNITS attribute must not include 'year' (for 'currency' type) or 'multiplier' information. That information is part of the input file field names instead (where relevant). This is explained in more detail in Section 6.4.  
- **Get** specifies what data items that need to be retrieved from the datastore and what characteristics those data need to have. The *Get* component is a list where each component of that list describes data that is to be retrieved from the datastore. The following specifications are required for each dataset:  
  -  NAME: the name of the dataset to be loaded;  
  -  TABLE: the name of the table that the dataset is a part of;  
  -  GROUP: the type of group where the table is located in the datastore (i.e. Global, Year, BaseYear);  
  -  TYPE: the data type (i.e. double, integer, character, logical);  
  -  UNITS: the measurement units for the data;  
  -  PROHIBIT: data conditions that are prohibited or "" if not applicable;  
  -  ISELEMENTOF: allowed categorical data values or "" if not applicable.  
  
  These elements have the same meanings as described above. Unlike the 'Inp' specifications, the 'Get' specifications for UNITS must include 'year' information for 'currency' types. This is necessary in order for the framework to convert the currency data being requested from the datastore to the year denomination that the module needs. The UNITS attribute may also include a multiplier specification if the module needs the values to be modified in that way. For example, if the module needs VMT in thousands of miles, the UNITS specification would be 'MI.1e3'. Section 6.3 provides more information on how 'year' and 'multiplier' options are added to a UNITS specification.  
- **Set** specifies the attributes of data that is to be saved in the datastore. The following need to be specified for every dataset that is to be saved in the datastore:  
  -  NAME: the name of the data item that is to be saved;  
  -  TABLE: the name of the table that the dataset is a part of;  
  -  GROUP: the type of group where the table is located in the datastore (i.e. Global, Year, BaseYear);  
  -  TYPE: the data type (i.e. double, integer, character, logical);  
  -  UNITS: the measurement units for the data;  
  -  NAVALUE: the value used to represent NA in the datastore;  
  -  PROHIBIT: data conditions that are prohibited or "" if not applicable;  
  -  ISELEMENTOF: allowed categorical data values or "" if not applicable;  
  -  SIZE: the maximum number of characters (or 0 for numeric data).  

  These elements have the same meanings as described above. As with the 'Get' specifications for UNITS, 'year' information must be included for 'currency' types. This is necessary in order for the framework to convert the currency data being produced by the module to the base year denomination that the datastore will contain. The UNITS attribute must also include a multiplier specification if the module outputs are multiplied values such as thousands or millions. For example, if the module produces VMT in thousands of miles, the UNITS specification must be 'MI.1e3'. Section 6.3 provides more information on how 'year' and 'multiplier' options are added to a UNITS specification.
  
  It should be noted that it may not be possible to prespecify the SIZE attribute for a dataset. For example, if a unique household ID is assigned, the SIZE attribute will depend on the number of households and so must be calculated when the module is run. In such a circumstance, the SIZE attribute is omitted and the module function must calculate it and include the calculated value as an attribute of the output dataset. This is shown in the example in Appendix E and is explained below.

The name of the data specifications list must be the concatenation of the name of the module and "Specifications". For example, if the module name is *CreateHouseholds*, then the data specifications list must be named *CreateHouseholdsSpecifications*. This naming convention is very important because it is what the software framework uses to extract the specifications from the package that the module is in.

The **function definitions** section of the module script is used to define all functions that will be used to implement the submodel. One of these functions is the main function that is called by the software framework to run the module. This function must have the same name as the module name. For example, the main function of the 'CreateHouseholds' module is named 'CreateHouseholds' as well. This function must be written to accept one argument, a list, which by convention is named L. This list contains all of the datasets identified in the 'Get' component of the module data specifications. The structure of this list is described in Section 7. The main function returns a list which contains all of the datasets identified in the 'Set' component of the module data specifications and structured as described in Section 7. The software framework function includes a function, 'initDataList', to initialize an outputs list having the proper structure with 'Global', 'Year', and 'BaseYear' components. It is up to the developer to The example 'CreateHouseholds.R' script (Appendix E) shows how the module outputs list is populated with 'table' components and 'dataset' components within 'table' components. For example the following code creates a list component to store datasets that will be put into the 'Household' table (for each model run year group), and then assigns the 'HhId' (household ID) dataset to that list. 

```
Out_ls$Year$Household <- list()
Out_ls$Year$Household$HhId <- paste("HH", 1:NumHh, sep = "-")
#NumHh is the number of households
```

In this example, the SIZE attribute of the 'HhId' dataset will not have been specified in the module 'Set' specifications for the dataset because the maximum number of characters depends on the number of households ('NumHh' in the example). Because the SIZE attribute was not prespecified, it must be specified in the module code. Following is an example of how this is done:

```
attributes(Out_ls$Year$Household$HhId)$SIZE <- max(nchar(Out_ls$Year$Household$HhId))
```

If a new table is being created by a module, as in the case of the example in Appendix E it is required that the module code assign a length attribute to the output list component for the table that is being created. Following is an example:

```
attributes(Out_ls$Year$Household)$LENGTH <- NumHh
#NumHh is the number of households
```

The main function may call other functions as necessary to carry out computations. The main function is responsible for passing to those functions all data they need as inputs. The main function is also responsible for passing any datasets specified in the 'Set' specifications back to the software framework which only recognizes the main function.

All functions must be properly documented using Roxygen syntax.

The last portion of the module script is optional. This part of the script is there to help module developers during module development. All portions of the example script are commented out. This is necessary when the package is built because it will cause errors during package building. More on support for module testing is 
#### 8.2. The inst/extdata Directory
By convention, the 'inst/extdata' directory is the standard place to put external (raw) data files as opposed to R datasets which are placed in the 'data' directory. All the files that are used to calculate model parameters are placed in this directory. Parameter data files must be CSV-formatted text files where the first line of the file is a header of column names. The data included in each parameter file must be consistent with the data specifications described in the R script for the module that uses those data. Each parameter data file should be accompanied by a text file which documents the data contained in the file. This text file should have the same name as the parameter data file but the file extension should be ".txt". The text file should include notes on the file structure, document data sources, and provide any other notes on the data that are important for users to know. 

#### 8.3. The tests Directory
The 'tests' directory contains an R script to run and data to be used to test all the modules in a package. The software framework includes a 'testModule' function that module developers can use to assist module development and testing. The testing script is named 'test.R'. Appendix F includes an example of a test script. Test data mirrors the setup for running a model. A 'defs' directory includes all the files described in Section 6.1. An 'inputs' directory includes all the input files specified by the modules. A datastore file, 'datastore.h5', must be present which contains all the data items identified in the module 'Get' specifications that will not be provided by the input files. The 'VERSPM' directory in the VisionEval GitHub repository includes a test datastore for the Rogue Valley MPO (RVMPO) test area.  

#### 8.4. The vignettes Directory  
Whereas package help files provide basic documentation of package functions and datasets, vignettes provide a vehicle for longer-form documentation of packages and the modules included in packages. Vignettes enable literate programming, where R code is embedded within  a vignette source file and evaluated when that document is compiled into it's final form. R code embedded in a vignette source file can be used to produce tables and graphs that are embedded in the document. This makes vignettes very useful for documenting how submodels are designed and how their parameters are estimated. 

Source files for producing vignettes are composed in R Markdown format text files (Rmd extension). When the package is built, the source files are evaluated and final versions are produced in HTML or PDF formats. The process for preparing vignettes in packages is [well documented.](http://r-pkgs.had.co.nz/vignettes.html)

There is no limit to the number of vignettes that are included in a package, and module developers are encouraged include vignettes that throughly document the submodels that the package implements, but some standard vignettes are required to be included in a package. One vignette is must be included which describes the package as a whole. This vignette identifies the modules included in the package, provides a brief description of each module, any provides any other information about the package and what is included in it. A vignette must be included to document each module contained in the package as well. Appendix F shows an example of a source file for a package vignette and Appendix G shows an example source file for a module vignette.

#### 8.5. The data and man Directories
The 'data' and 'man' directories and the files within them are created automatically when a package is built (i.e. when the sources are compiled into a version that can be used by the R language environment). The 'data' directory contains R binary files for all of the module parameters and specifications. These are created by the save commands in the module scripts. The 'man' directory contains the documentation files for the functions and data that are defined by the module scripts. These documentation files are created from the documentation annotations (in Roxygen format) included in the module scripts.

### 9. Software Framework 
The software framework for the VisionEval model system is implemented by a set of functions contained in the **visioneval** package. The package contains contains standard documentation for all of the functions. Additional documentation which shows the calling relationships between functions is available in a [interactive visualization](https://gregorbj.github.io/VisionEval/website/visioneval_functions.html) in the project repository. This visualization shows the names of the functions as nodes in a network graph with arrows connecting the nodes showing the functions that are called by each function (arrows point from the calling function to the called function). The nodes are colored to show different types of functionality. Functions that are used to create models from modules are colored blue. There are three such functions. Functions that are used in the creation of modules are colored green. There are a dozen of these functions. There are several dozen functions which manage various aspects of the software frame and interactions with the datastore. The latter functions are colored red and the rest are colored yellow. These functions are not intended to be used by module developers or model users. Clicking on a function in the visualization highlights the function and all the arrows connected to it. It also provides summary information about the function including a description of what it does, descriptions of all the function arguments, and a description of the function's return value. Sections 9.1 and 9.2 describe the functions that are the applications programming interfaces (API) for model users and module developers respectively. Readers should refer to the visualization and documentation in the visioneval package if the desire to learn more about functions that are not part of the API.

#### 9.1. API for Model Users  
Three functions are part of the API for model users: 'initializeModel', 'runModule', and 'getYears'. These are explained below in turn.

The 'initializeModel' function prepares the model for running modules. This includes:  
1) Creating the "ModelState.Rda" file that contains global parameters for the model run and variables used to keep track of the state of the datastore and other aspects of the model run (Section 6.6);  
2) Creating a log file that is used to record model status messages such as warning and error messages;  
3) Creating and initializing the model datastore;  
4) Processing the model geography definition file and setting up the appropriate geographic tables in the datastore;  
5) Checking whether all the specified module packages are installed and that all module specifications are correct;  
6) Parsing the "run_model.R" script and simulating the model run to confirm that the datastore will contain the data that each module needs when it is called and that the data specifications are consistent with the module 'Get' specifications;  
7) Checking whether all the scenario input files identified by the specified modules are present, and that the data are consistent with specifications; and,  
8) Loading all the data in the input files into the datastore.

If any errors are found during the model initialization process, an error message will be displayed in the console and the initialization process will terminate. Detailed error messages in the log will identify the specific causes of errors. If the initialization proceeds without errors, the user can be assured that the model will run without errors. Following is a typical 'initializeModel' function call in a model run script.  

```  
initializeModel(
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = FALSE,
  DatastoreName = NULL,
  SaveDatastore = TRUE
  )
```    

The function arguments and their meanings are as follows:  
- **ParamDir** A string identifying the relative or absolute path to the directory where the parameter and geography definition files are located. The default value is "defs".  
- **RunParamFile** A string identifying the name of a JSON-formatted text file that contains parameters needed to identify and manage the model run. The default value is "run_parameters.json".  
- **GeoFile** A string identifying the name of a text file in comma-separated values format that contains the geographic specifications for the model. The default value is "geo.csv".  
- **ModelParamFile** A string identifying the name of a JSON-formatted text file that contains global model parameters that are important to a model and may be shared by several modules.  
- **LoadDatastore** A logical identifying whether an existing datastore should be loaded.  
- **DatastoreName** A string identifying the full path name of a datastore to load or NULL if an existing datastore in the working directory is to be loaded.  
- **SaveDatastore** A string identifying whether if an existing datastore in the working directory should be saved rather than removed.  

As the name suggests, the 'runModule' function runs a module. Following is an example of how it is invoked:  
```
runModule(ModuleName = "CreateHouseholds", 
          PackageName = "VESimHouseholds",
          RunFor = "AllYears",
          RunYear = Year)
```  

The function arguments and their meanings are as follows:  
- **ModuleName** A string identifying the name of a module object.  
- **PackageName** A string identifying the name of the package the module is a part of.  
- **RunFor** A string identifying whether to run the module for all years (AllYears), only the base year (BaseYear), or for all years except the base year (NotBaseYear).
- **RunYear** A string identifying the run year.

The *runModule* function runs the named module within the *runModule* function environment. This is a significant improvement over how functions that implement the submodels in the current GreenSTEP (RSPM, EERPAT, RPAT) are run. In these models, functions are run in the the global environment. As a consequence, the global environment collects objects that increase the potential for name conflicts if care is not taken to keep it clean. By running modules within the *runModule* function environment, no changes are made to the global environment and all objects that are created in the process vanish when the *runModule* function completes the work of running the module.   

Modules can be run for multiple years by running them in a loop which iterates through all of the years identified in the 
'Years' parameter specified in the "run_parameters.json" file (Section 6.1). Section 5 shows an example of using such a loop. Rather than hard code the model run years in the loop, the user can use the 'getYears' function to query and return the vector of years.

#### 9.2. API for Module Developers
The VisionEval API for module developers currently includes 10 functions. These are presented below in 3 groups:  
- Key module script functions;  
- Functions to help developers write specifications that are consistent with other modules; and,  
- Functions that developers may use to simplify model implementation.  

##### 9.2.1. Key Module Script Functions  
Four functions are almost always used in module scripts.

Module specifications are written as nested R lists that are structured in a particular way (Section 8). Rather than use the 'list' function to define the list structure, two alias functions - 'item' and 'items' - are used to define the structure. An example of how these functions are used is shown in Appendix E. Although modules will run if the 'list' function is used instead, it is highly recommended that 'item' and 'items' be used to maintain a consistent style for all modules.

The 'processEstimationInputs' function must be used if a module includes procedures for estimating model parameter(s) from regional data (Section 8). This function is used to check that the data supplied to calculate the regional parameter(s) are consistent with specifications. The function arguments are as follows:  
- **Inp_ls** A list that describes the specifications for the estimation file. This list must meet the framework standards for specification description.  
- **FileName** A string identifying the file name. This is the file name without any path information. The file must located in the "inst/extdata" directory of the package.  
- **ModuleName** A string identifying the name of the module the estimation data is being used in.

The function returns a data frame containing the estimation inputs if all the supplied specifications are met. If any of the specifications are not met, an error is thrown and details regarding the specification error(s) are written to the console.

The 'testModule' function is an essential tool for testing that the module will work correctly in the VisionEval model system. The test module function tests a module with a test setup that mimics a model run. A test datastore needs to be present unless no data from other modules is needed (i.e. all data used by the module is supplied by input data). All inputs required by the module must be present, and all the standard model definitions files included in the "defs" directory (Section 6.1) must be present as well. When this function is invoked, the following tests are done on a module:  
- Checks whether module specifications are proper;  
- Checks whether test module inputs are consistent with the module 'Inp' specifications and that they can be loaded into a test datastore;  
- Checks whether the test datastore with the loaded inputs contains all the data needed for the module to run;
- Checks whether the module will run without error; and,  
- Checks whether the outputs of the module are consistent with the module 'Set' specifications.

The function arguments are as follows:
- **ModuleName A string identifying the module name.  
- **ParamDir** A string identifying the location of the directory where the run parameters, model parameters, and geography definition files are located. The default value is defs. This directory should be located in the tests directory.
- **RunParamFile** A string identifying the name of the run parameters file. The default value is run_parameters.json.
- **GeoFile** A string identifying the name of the file which contains geography definitions.
- **ModelParamFile** A string identifying the name of the file which contains model parameters. The default value is model_parameters.json.
- **LoadDatastore** A logical value identifying whether to load an existing datastore. If TRUE, it loads the datastore whose name is identified in the run_parameters.json file. If FALSE it initializes a new datastore.
- **SaveDatastore** A logical value identifying whether the module outputs will be written to the datastore. If TRUE the module outputs are written to the datastore. If FALSE the outputs are not written to the datastore.
- **DoRun** A logical value identifying whether the module should be run. If FALSE, the function will initialize a datastore, check specifications, and load inputs but will not run the module. If TRUE, the module will be run and results will be checked for consistency with the module's 'Set' specifications.

but will return the list of module specifications. That setting is useful for module development in order to create the all the data needed to assist with module programming. It is used in conjunction with the getFromDatastore function to create the dataset that will be provided by the framework. The default value for this parameter is TRUE. In that case, the module will be run and the results will checked for consistency with the Set specifications.

If the DoRun argument is TRUE, the module will be run and there will be no return value. If that argument is FALSE, the return value of the function is a list containing the module specifications. That setting is useful for module development in order to create the all the data needed to assist with module programming. It is used in conjunction with the 'getFromDatastore' function to create the dataset that will be provided by the framework. The example module script in Appendix E shows how this aspect of the 'testModule' function can be used by module developers to make the development of their code easier. The function also writes out messages to the console and to the log as the testing proceeds. These messages include the time when each test starts and when it ends. When a key test fails, requiring a fix before other tests can be run, execution stops and an error message is written to the console. Detailed error messages are also written to the log.

##### 9.2.2. Functions to Assist Specification Writing
As was explained above in Sections 4.1 and 8.1, the VisionEval model system uses data specifications to 


Details for these functions and all of the other functions in the in the software framework are included in the *visioneval* package.  

### Appendix A: geography.csv file examples  
**Figure A1. Example of geography.csv file that only specifies Azones**  
![Azone](img/azone_geo_file.png)  

**Figure A2. Example of geography.csv file that specifies Azones and Bzones**   
![Azone Bzone](img/azone_bzone_geo_file.png)  

### Appendix B: scenario input file examples  
**Figure B1. Example of input file to be loaded into 'Global' group** 
*NOTE: Heavy lines denote rows that are hidden to shorten the display*
![Global Input](img/global_input_file.png)  

**Figure B2. Example of input file to be loaded into 'forecast year' group**  
![Forecast Year Input](img/forecast_year_input_file.png)  

### Appendix C: example module script from vedemo1 package  
```
#==================
#CreateHouseholds.R
#==================

#This demonstration module creates simulated households for a model where
#geography is minimally specified, i.e. where only Azones and Mareas are
#specified. Simulated households are created using a household size distribution
#for the model area and Azone populations. The module creates a dataset of
#household sizes. A 'Households' table is initialized and populated with the
#household size dataset. Azone locations and household IDs are also added to the
#Household table.

library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Functions and statements in this section of the script define all of the
#parameters used by the module. Parameters are module inputs that are constant
#for all model runs. Parameters can be put in whatever form that the module
#developer determines works best (e.g. vector, matrix, array, data frame, list,
#etc.). Parameters may be defined in several ways including: 1. By statements
#included in this section (e.g. HhSize <- 2.5); 2. By reading in a data file
#from the "inst/extdata" directory; and, 3. By applying a function which
#estimates the parameters using data in the "inst/extdata" directory.

#Each parameter object is saved so that it will be in the namespace of module
#functions. Parameter objects are exported to make it easier for users to
#inspect the parameters being used by a module. Every parameter object must
#also be documented properly (using roxygen2 format). The code below shows
#how to document and save a parameter object.

#This module demo shows how a function can be used to estimate parameters. When
#this approach is used, all input data for parameter estimation must be placed
#in the "inst/extdata" directory of the package. The function is written to load
#the data into a suitable data structure that is then used to estimate the
#needed parameters. This approach enables model builders to substitute regional
#data for the default data that comes with the package. The source of the
#default data is documented in the "inst/extdata" directory. The module vignette
#describes how regional data can be substituted for default data. When the
#package is built, the module will include regionally estimated parameters. The
#example below is a trivial one which reads in a file of numbers of households
#by household size and calculates he proportions of households by household
#size. Most of the function is error checking. Functions that calculate
#parameters should not be exported.

#Describe specifications for data that is to be used in estimating parameters
#----------------------------------------------------------------------------
#Household size data
HouseholdSizesInp_ls <- items(
  item(
    NAME = "Size",
    TYPE = "integer",
    PROHIBIT = c("NA", "<= 0", "> 7"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  ),
  item(
    NAME = "Number",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  )
)

#Define a function to estimate household size proportion parameters
#------------------------------------------------------------------
#' Calculate proportions of households by household size
#'
#' \code{calcHhSizeProp} calculates the proportions of households by household
#' size from the number of households by household size.
#'
#' This function produces a data frame listing the proportions of households
#' by household size from a data frame that lists the numbers of households by
#' household size. The rows of the data frame are put in order of ascending
#' household size.
#'
#' @param HouseholdSizesInp_ls A list containing the specifications for
#' the estimation data contained in "household_sizes.csv".
#' @return A data frame having two columns names "Size" and "Proportion" that
#' contains data on the proportions of households in households having sizes
#' between 1 and 7 persons per household.
calcHhSizeProp <- function(Inp_ls = HouseholdSizesInp_ls) {
  #Check and load household size estimation data
  HhSizes_df <- processEstimationInputs(Inp_ls,
                                        "household_sizes.csv",
                                        "CreateHouseholds")
  #Put the rows in order of household size
  HhSizes_df <- HhSizes_df[order(HhSizes_df$Size),]
  #Calculate proportions of households by size
  Proportion <- HhSizes_df$Number / sum(HhSizes_df$Number)
  #Return a data frame containing household size proportions
  data.frame(Size = HhSizes_df$Size, Proportion = Proportion)
}

#Create and save household size proportions parameters
#-----------------------------------------------------
HhSizeProp_df = calcHhSizeProp()
#' Household size proportions
#'
#' A dataset containing the proportions of households by household size.
#'
#' @format A data frame with 7 rows and 2 variables:
#' \describe{
#'  \item{Size}{household size}
#'  \item{Proportion}{proportion of households in household size category}
#' }
#' @source CreateHouseholds.R script.
"HhSizeProp_df"
devtools::use_data(HhSizeProp_df, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#This section creates a list of data specifications for input files, data to be
#loaded from the datastore, and outputs to be saved to the datastore. It also
#identifies the level of geography that is iterated over. For example, a
#congestion module could be applied by Marea. The name that is given to this
#list is the name of the module concatenated with "Specifications". In this
#case, the name is "CreateHouseholdsSpecifications".
#
#The specifications list is saved and exported so that it will be in the
#namespace of the package and can be read by visioneval functions. The
#specifications list must be documented properly (using roxygen2 format) In
#order for it to be exported. The code below shows how to properly define,
#document, and save a module specifications list.

#The components of the specifications list are as follows:

#RunBy: This is the level of geography that the module is to be applied at.
#Acceptable values are "Region", "Azone", "Bzone", "Czone", and "Marea".

#Inp: A list of scenario inputs that are to be read from files and loaded into
#the datastore. The following need to be specified for every data item (i.e.
#column in a table):
#  NAME: the name of a data item in the input table;
#  FILE: the name of the file that contains the table;
#  TABLE: the name of the datastore table the item is to be put into;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  SIZE: the maximum number of characters (or 0 for numeric data)
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  UNLIKELY: data conditions that are unlikely or "" if not applicable;
#  TOTAL: the total for all values (e.g. 1) or NA if not applicable.

#Get: Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#  NAME: the name of the dataset to be loaded;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable.

#Set: Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#  NAME: the name of the data item that is to be saved;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  SIZE: the maximum number of characters (or 0 for numeric data).

#Define the data specifications
#------------------------------
CreateHouseholdsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify input data
  Inp = items(
    item(
      NAME = "Population",
      FILE = "azone_population.csv",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Population",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "households",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Household",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateHouseholds module
#'
#' A list containing specifications for the CreateHouseholds module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateHouseholds.R script.
"CreateHouseholdsSpecifications"
devtools::use_data(CreateHouseholdsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateHouseholds". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#This module only has a main function, CreateHouseholds. This function
#creates household-level datasets for household size (HhSize),
#household ID (HhId), and Azone (Azone). It uses a dataframe of household size
#proportions and Azone populations in carrying out the calculations.

#Function that creates simulated households
#------------------------------------------
#' Creates a set of simulated households
#'
#' \code{CreateHouseholds} creates a set of simulated households that each have
#' a unique household ID, an Azone to which it is assigned, and a household
#' size (number of people in the household).
#'
#' This function creates a set of simulated households where each household is
#' assigned a household size, an Azone, and a unique ID. These data items are
#' vectors that are to be stored in the "Household" table. Since this table does
#' not exist, the function calculates a LENGTH value for the table and returns
#' that as well. The framework uses this information to initialize the
#' Households table. The function also computes the maximum numbers of
#' characters in the HhId and Azone datasets and assigns these to a SIZE vector.
#' This is necessary so that the framework can initialize these datasets in the
#' datastore. All the results are returned in a list.
#'
#' @param L A list containing the following components:
#' Azone: A character vector of Azone names read from the Azone table.
#' Population: A numeric vector of the number of people in each Azone read from
#' the Azone table.
#' @return A list containing the following components:
#' HhSize: An integer vector of the calculated sizes of the simulated households
#' that is to be assigned to the Household table.
#' Azone: A character vector of the names of the Azones the simulated households
#' are assigned to that is to be assigned to the Household table.
#' HhId: A character vector identifying the unique ID for each household that is
#' to be assigned to the Household table.
#' NumHh: An integer vector identifying the number of households assigned to
#' each Azone that is to be assigned to the Azone table.
#' LENGTH: A named integer vector having a single named element, "Household",
#' which identifies the length (number of rows) of the Household table to be
#' created in the datastore.
#' SIZE: A named integer vector having two elements. The first element, "Azone",
#' identifies the size of the longest Azone name. The second element, "HhId",
#' identifies the size of the longest HhId.
#' @export
#CreateHouseholds <- function(L, P = CreateHouseholdsParameters) {
CreateHouseholds <- function(L) {
  #Calculate average household size
  #AveHhSize <- sum(P$HhSizeProp_df$Size * P$HhSizeProp_df$Proportion)
  AveHhSize <- sum(HhSizeProp_df$Size * HhSizeProp_df$Proportion)
  #Define function to simulate households by size in a population
  SimHh <- function(Pop, AveHhSize) {
    InitNumHh <- ceiling(Pop / AveHhSize) + 100
    #InitHh_ <-
    #  sample(P$HhSizeProp_df$Size, InitNumHh, replace = TRUE,
    #         prob = P$HhSizeProp_df$Proportion)
    InitHh_ <-
      sample(HhSizeProp_df$Size, InitNumHh, replace = TRUE,
             prob = HhSizeProp_df$Proportion)
    Error_ <- abs(cumsum(InitHh_) - Pop)
    Hh_ <- InitHh_[1:(which(Error_ == min(Error_)))[1]]
    if (sum(Hh_) < Pop) {
      Hh_ <- c(Hh_, Pop - sum(Hh_))
    }
    if (sum(Hh_) > Pop) {
      PopDiff <- sum(Hh_) - Pop
      Hh_ <- Hh_[-which(Hh_ == PopDiff)[1]]
    }
    Hh_
  }
  #Create household sizes of households for all Azones and put in list
  HhSize_ls <- list()
  for (i in 1:length(L$Azone)) {
    Az <- L$Azone[i]
    Pop <- L$Population[i]
    HhSize_ls[[Az]] <- SimHh(Pop, AveHhSize)
  }
  #Create vector of household IDs
  HhId_ <- unlist(sapply(names(HhSize_ls),
                         function(x) paste(x, 1:length(HhSize_ls[[x]]), sep = "")),
                  use.names = FALSE)
  #Calculate LENGTH attribute for Household table
  LENGTH <- numeric(0)
  LENGTH["Household"] <- sum(sapply(HhSize_ls, length))
  #Calculate SIZE attributes for 'Azone' and 'HhId'
  SIZE <- numeric(0)
  SIZE["Azone"] <- max(nchar(L$Azone))
  SIZE["HhId"] <- max(nchar(HhId_))
  #Return a list of values to be saved in the datastore
  list(
    HhSize = unlist(HhSize_ls, use.names = FALSE),
    Azone = rep(L$Azone, unlist(lapply(HhSize_ls, length))),
    HhId = HhId_,
    NumHh = unlist(lapply(HhSize_ls, length), use.names = FALSE),
    LENGTH = LENGTH,
    SIZE = SIZE
    )
}
```
### Appendix D: example module script from vedemo1 package  
```
#==============
#CreateBzones.R
#==============

#This demonstration module creates simulated Bzones that have a specified
#numbers of households and development types (Metropolitan, Town, Rural). The 
#module determines the number of Bzones in each Azone and assigns a unique ID
#and a development type to each. It also calculates the number of households 
#in each Bzone such that the proportion of households in each Azone assigned 
#to each development type matches assumed input proportions. It also assigns 
#the respective Mareas to the simulated Bzones. A Bzone table is created and
#populated with unique IDs, development types, Mareas, Azones, and numbers of
#households.

library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Functions and statements in this section of the script define all of the
#parameters used by the module. Parameters are module inputs that are constant
#for all model runs. Parameters can be put in whatever form that the module
#developer determines works best (e.g. vector, matrix, array, data frame, list,
#etc.). Parameters may be defined in several ways including: 1. By statements
#included in this section (e.g. HhSize <- 2.5); 2. By reading in a data file
#from the "inst/extdata" directory; and, 3. By applying a function which
#estimates the parameters using data in the "inst/extdata" directory.

#Each parameter object is saved so that it will be in the namespace of module
#functions. Parameter objects are exported to make it easier for users to
#inspect the parameters being used by a module. Every parameter object must
#also be documented properly (using roxygen2 format). The code below shows
#how to document and save a parameter object.

#In this demo module, only one parameter is defined: the average number of
#households per block group. This shows how model parameters can be defined by
#simple assignment statements.

#Create & save a parameter for the average number of households per block group
#------------------------------------------------------------------------------
AveHhPerBlockGroup <- 400
#' Average households per block group
#'
#' A number representing the average number of households per census block.
#'
#' @format A number:
#' \describe{
#'  \item{AveHhPerBlockGroup}{average households per census block group}
#' }
#' @source CreateBzones.R script.
"AveHhPerBlockGroup"
devtools::use_data(AveHhPerBlockGroup, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#This section creates a list of data specifications for input files, data to be
#loaded from the datastore, and outputs to be saved to the datastore. It also
#identifies the level of geography that is iterated over. For example, a
#congestion module could be applied by Marea. The name that is given to this
#list is the name of the module concatenated with "Specifications". In this
#case, the name is "CreateHouseholdsSpecifications".
#
#The specifications list is saved and exported so that it will be in the
#namespace of the package and can be read by visioneval functions. The
#specifications list must be documented properly (using roxygen2 format) In
#order for it to be exported. The code below shows how to properly define,
#document, and save a module specifications list.

#The components of the specifications list are as follows:

#RunBy: This is the level of geography that the module is to be applied at.
#Acceptable values are "Region", "Azone", "Bzone", "Czone", and "Marea".

#Inp: A list of scenario inputs that are to be read from files and loaded into
#the datastore. The following need to be specified for every data item (i.e.
#column in a table):
#  NAME: the name of a data item in the input table;
#  FILE: the name of the file that contains the table;
#  TABLE: the name of the datastore table the item is to be put into;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  SIZE: the maximum number of characters (or 0 for numeric data)
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  UNLIKELY: data conditions that are unlikely or "" if not applicable;
#  TOTAL: the total for all values (e.g. 1) or NA if not applicable.

#Get: Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#  NAME: the name of the dataset to be loaded;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable.

#Set: Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#  NAME: the name of the data item that is to be saved;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  SIZE: the maximum number of characters (or 0 for numeric data).

#Define the data specifications
#------------------------------
CreateBzonesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify input data
  Inp = items(
    item(
      NAME = "Metropolitan",
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    ),
    item(
      NAME = "Town",
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    ),
    item(
      NAME = "Rural",
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Azone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Metropolitan",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Town",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Rural",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c("Metropolitan", "Town", "Rural")
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "none",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateBzones module
#'
#' A list containing specifications for the CreateHouseholds module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateHouseholds.R script.
"CreateBzonesSpecifications"
devtools::use_data(CreateBzonesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateBzones". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#This module only has a main function, CreateBzones. This function creates
#simulated Bzones and assigns development types, Azones, Mareas,
#unique Bzone IDs, and numbers of households.

#Function that creates simulated Bzones
#------------------------------------------
#' Creates a set of simulated Bzones
#'
#' \code{CreateBzones} creates a set of simulated Bzones and assigns
#' development types, Azones, Mareas, unique Bzone IDs, and numbers of
#' households.
#'
#' This function creates a set of simulated Bzones and assigns attributes
#' including the Azone that the Bzone is situated in, the Marea that the Bzone
#' is situated in, the number of households in the Bzone, and the development
#' type (i.e. Metropolitan, Town, Rural) of the Bzone. These data items are
#' vectors that are to be stored in the "Bzone" table. Since this table does not
#' exist, the function calculates a LENGTH value for the table and returns that
#' as well. The framework uses this information to initialize the Bzone table.
#' The function also computes the maximum numbers of characters in the Bzone,
#' Azone, Marea, and DevType datasets and assigns these to a SIZE vector. This
#' is necessary so that the framework can initialize these datasets in the
#' datastore. All results are returned in a list.
#'
#' @param L A list containing the following components that have been read
#' from the datastore:
#' Azone: A character vector of Azone names read from the Azone table.
#' NumHh: A numeric vector of the number of people in each Azone read from the
#' Azone table.
#' Marea: A character vector of Marea names read from the Azone table.
#' Metropolitan: A numeric vector of the proportion of households that are of
#' the Metropolitan development type in each Azone read from the Azone table.
#' Town: A numeric vector of the proportion of households that are of the Town
#' development type in each Azone read from the Azone table.
#' Rural: A numeric vector of the proportion of households that are of the
#' Rural development type in each Azone read from the Azone table.
#' @return A list containing the following components:
#' Bzone: A character vector of the names of the Bzones that is to be assigned
#' to the Bzone table.
#' Azone: A character vector of the names of the Azones associated with each
#' Bzone that is to be assigned to the Bzone table.
#' Marea: A character vector of the names of the Mareas associated with each
#' Bzone that is to be assigned to the Bzone table.
#' DevType: A character vector identifying the development type of each Bzone
#' that is to be assigned to the Bzone table.
#' NumHh: An integer vector identifying the number of households assigned to
#' each Bzone that is to be assigned to the Bzone table.
#' LENGTH: A named integer vector having a single named element, "Bzone",
#' which identifies the length (number of rows) of the Bzone table to be
#' created in the datastore.
#' SIZE: a named numeric vector having four elements. The first element,
#' "Azone", identifies the size of the longest Azone name. The second element,
#' "Bzone", identifies the size of the longest Bzone name. The third element,
#' "Marea", identifies the size of the longest Marea name. The fourth element,
#' "DevType", identifies the size of the longest DevType name.
#' @export
CreateBzones <- function(L) {
  #Make vector of Azone names
  Az <- L$Azone
  #Make matrix of development type proportions by Azone
  Dt <- c("Metropolitan", "Town", "Rural")
  DevTypeProp_AzDt <- cbind(L$Metropolitan, L$Town, L$Rural)
  rownames(DevTypeProp_AzDt) <- Az
  colnames(DevTypeProp_AzDt) <- Dt
  #Define function to assign & tabulate number of households by development type
  tabulateNumHhByDevType <- function(NumHh, Prob) {
    DevType_Hh <- sample(Dt, NumHh_Az[az], replace = TRUE,
                           prob = DevTypeProp_AzDt[az,])
    DevTypeHh_Dt <- table(DevType_Hh)[Dt]
    names(DevTypeHh_Dt) <- Dt
    DevTypeHh_Dt[is.na(DevTypeHh_Dt)] <- 0
    DevTypeHh_Dt
  }
  #Assign the number of households to be in each Azone development type
  NumHh_Az <- L$NumHh
  names(NumHh_Az) <- Az
  DevTypeHh_AzDt <- DevTypeProp_AzDt * 0
  for(az in Az) {
    DevTypeHh_AzDt[az,] <- tabulateNumHhByDevType(NumHh_Az[az],
                                                  DevTypeProp_AzDt[az,])
  }
  #Calculate number of block groups and number of households per block group
  #for each Azone and development type
  NumBlkGrp_AzDt <- round(DevTypeHh_AzDt / AveHhPerBlockGroup)
  storage.mode(NumBlkGrp_AzDt) <- "integer"
  NumBlkGrp_Az <- rowSums(NumBlkGrp_AzDt)
  HhPerBlockGroup_AzDt <- ceiling(DevTypeHh_AzDt / NumBlkGrp_AzDt)
  HhPerBlockGroup_AzDt[is.na(HhPerBlockGroup_AzDt)] <- 0
  storage.mode(HhPerBlockGroup_AzDt) <- "integer"
  #Create simulated block groups and associate with metropolitan areas
  Marea_Az <- L$Marea
  names(Marea_Az) <- L$Azone
  Bzone_df <- expand.grid(dimnames(t(NumBlkGrp_AzDt)), stringsAsFactors = FALSE)
  names(Bzone_df) <- c("DevType", "Azone")
  Bzone_df$NumZones <- as.vector(t(NumBlkGrp_AzDt))
  Bzone_df$NumHh <- as.vector(t(HhPerBlockGroup_AzDt))
  Bzone_df$Marea <- Marea_Az[Bzone_df$Azone]
  Bzone_df <- Bzone_df[Bzone_df$NumZones != 0,]
  #Calculate values to write out of the module
  Bz <- unlist(sapply(names(NumBlkGrp_Az),
                      function(x) paste(x, 1:NumBlkGrp_Az[x], sep = "")),
               use.names = FALSE)
  Azone_Bz <- rep(names(NumBlkGrp_Az), NumBlkGrp_Az)
  Marea_Bz <- rep(Bzone_df$Marea, Bzone_df$NumZones)
  NumHh_Bz <- rep(Bzone_df$NumHh, Bzone_df$NumZones)
  DevType_Bz <- rep(Bzone_df$DevType, Bzone_df$NumZones)
  #Calculate the total number of Bzones. Necessary for calculating a LENGTH
  #attribute used for initializing Bzone table
  LENGTH <- numeric(0)
  LENGTH["Bzone"] <- length(Bz)
  #Calculate and assign SIZE attributes for 'Bzone', 'Marea', and 'DevType'
  #Necessary for initializing datasets in Bzone table
  SIZE <- numeric(0)
  SIZE["Bzone"] <- max(nchar(Bz))
  SIZE["Azone"] <- max(nchar(Azone_Bz))
  SIZE["Marea"] <- max(nchar(Marea_Bz))
  SIZE["DevType"] <- max(nchar(DevType_Bz))
  #Return a list of values to be saved in the datastore
  list(Bzone = Bz,
       Azone = Azone_Bz,
       Marea = Marea_Bz,
       NumHh = NumHh_Bz,
       DevType = DevType_Bz,
       LENGTH = LENGTH,
       SIZE = SIZE)
}
```
### Appendix E: example module script from vedemo1 package    
```
#================
#CreateBzoneDev.R
#================

#This demonstration module creates several Bzone development characteristics
#given the development type of each Bzone (i.e. Metropolitan, Town, Rural) and
#the number of households in each Bzone. The created Bzone characteristics
#include average population density (persons per square mile), and numbers of
#single family detached and multi-family dwellings. For 'metropolitan' type
#Bzones, the module also simulates the distance of the Bzone to the urban area
#core. The latter is calculated in conjunction with the calculation of
#population density so the quantities will be consistent (i.e. density decreases
#with distance from the core).

library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Functions and statements in this section of the script define all of the
#parameters used by the module. Parameters are module inputs that are constant
#for all model runs. Parameters can be put in whatever form that the module
#developer determines works best (e.g. vector, matrix, array, data frame, list,
#etc.). Parameters may be defined in several ways including: 1. By statements
#included in this section (e.g. HhSize <- 2.5); 2. By reading in a data file
#from the "inst/extdata" directory; and, 3. By applying a function which
#estimates the parameters using data in the "inst/extdata" directory.

#Each parameter object is saved so that it will be in the namespace of module
#functions. Parameter objects are exported to make it easier for users to
#inspect the parameters being used by a module. Every parameter object must
#also be documented properly (using roxygen2 format). The code below shows
#how to document and save a parameter object.

#In this demonstration module, parameters are created by reading in data files
#that are stored in the "inst/extdata" directory. These are all comma-separated
#values (csv) formatted text files. This will be the most common form for these
#files because they are easily edited and easily read into R. Documentation for
#each file is included with the file. The corresponding documentation file has
#the same name as the data file, but the file extension is 'txt'. One or more of
#these files may be altered using regional data to customize the module for the
#region.

#Describe specifications for data that is to be used in estimating the model
#---------------------------------------------------------------------------
#Data on the proportion of population by distance from urban area core
PopByDistanceInp_ls <- items(
  item(
    NAME = "Distance",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  ),
  item(
    NAME = "PopProp",
    TYPE = "double",
    PROHIBIT = c("NA", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  )
)
#Data on population density by distance from urban area core
PopDenByDistanceInp_ls <- items(
  item(
    NAME = "Distance",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  ),
  item(
    NAME = "PopDensity",
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  )
)
#Data on miscellaneous parameters
MiscDevParametersInp_ls <- items(
  item(
    NAME = "Parameter",
    TYPE = "Character",
    PROHIBIT = c("NA"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  ),
  item(
    NAME = "Value",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = NA
  )
)

#Read in, check and save population by distance parameters
#---------------------------------------------------------
PopByDistance_df <- processEstimationInputs(PopByDistanceInp_ls,
                                            "pop_by_distance.csv",
                                            "CreateBzoneDev")
#' Population proportions by distance
#'
#' A dataset containing the proportions of urbanized area population by distance
#' from the urban center rounded to nearest whole mile.
#'
#' @format A data frame with 40 rows and 2 variables:
#' \describe{
#'  \item{Distance}{distance from urban center, in miles}
#'  \item{PopProp}{proportion of urbanized area population}
#' }
#' @source CreateBzonesDev.R script.
"PopByDistance_df"
devtools::use_data(PopByDistance_df, overwrite = TRUE)

#Read in, check and save population density by distance parameters
#-----------------------------------------------------------------
PopDenByDistance_df <- processEstimationInputs(PopDenByDistanceInp_ls,
                                               "pop_density_by_distance.csv",
                                               "CreateBzoneDev")
#' Population density by distance
#'
#' A dataset containing the average census block group population density by
#' distance from the urban center rounded to nearest whole mile.
#'
#' @format A data frame with 40 rows and 2 variables:
#' \describe{
#'  \item{Distance}{distance from urban center, in miles}
#'  \item{PopDensity}{population density, in persons per square mile}
#' }
#' @source CreateBzonesDev.R script.
"PopDenByDistance_df"
devtools::use_data(PopDenByDistance_df, overwrite = TRUE)

#Read in, check and save miscellaneous parameters
#------------------------------------------------
MiscDevParameters_df <- processEstimationInputs(MiscDevParametersInp_ls,
                                                "misc_dev_parameters.csv",
                                                "CreateBzoneDev")
#' Miscellaneous Bzone development model parameters
#'
#' A dataset containing parameters for average household size, average town
#' population density, and average rural population density.
#'
#' @format A data frame with 3 rows and 2 variables:
#' \describe{
#'  \item{Parameter}{name of the parameter}
#'  \item{Value}{value of the parameter}
#' }
#' @source CreateBzonesDev.R script.
"MiscDevParameters_df"
devtools::use_data(MiscDevParameters_df, overwrite = TRUE)



#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#This section creates a list of data specifications for input files, data to be
#loaded from the datastore, and outputs to be saved to the datastore. It also
#identifies the level of geography that is iterated over. For example, a
#congestion module could be applied by Marea. The name that is given to this
#list is the name of the module concatenated with "Specifications". In this
#case, the name is "CreateBzoneDevSpecifications".
#
#The specifications list is saved and exported so that it will be in the
#namespace of the package and can be read by visioneval functions. The
#specifications list must be documented properly (using roxygen2 format) In
#order for it to be exported. The code below shows how to properly define,
#document, and save a module specifications list.

#The components of the specifications list are as follows:

#RunBy: This is the level of geography that the module is to be applied at.
#Acceptable values are "Region", "Azone", "Bzone", "Czone", and "Marea".

#Inp: A list of scenario inputs that are to be read from files and loaded into
#the datastore. The following need to be specified for every data item (i.e.
#column in a table):
#  NAME: the name of a data item in the input table;
#  FILE: the name of the file that contains the table;
#  TABLE: the name of the datastore table the item is to be put into;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  SIZE: the maximum number of characters (or 0 for numeric data)
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  UNLIKELY: data conditions that are unlikely or "" if not applicable;
#  TOTAL: the total for all values (e.g. 1) or NA if not applicable.

#Get: Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#  NAME: the name of the dataset to be loaded;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable.

#Set: Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#  NAME: the name of the data item that is to be saved;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  SIZE: the maximum number of characters (or 0 for numeric data).

#Define the data specifications
#------------------------------
CreateBzoneDevSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Marea",
  #Specify input data
  Inp = items(
    item(
      NAME = "Area",
      FILE = "marea_area.csv",
      TABLE = "Marea",
      TYPE = "double",
      UNITS = "square miles",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Area",
      TABLE = "Marea",
      TYPE = "double",
      UNITS = "square miles",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "none",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "DistFromCtr",
      TABLE = "Bzone",
      TYPE = "double",
      UNITS = "miles",
      NAVALUE = -1,
      PROHIBIT = c("< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "PopDen",
      TABLE = "Bzone",
      TYPE = "double",
      UNITS = "persons per square mile",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "SfdNum",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "dwelling units",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "MfdNum",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "dwelling units",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateBzoneDev module
#'
#' A list containing specifications for the CreateHouseholds module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateHouseholds.R script.
"CreateBzoneDevSpecifications"
devtools::use_data(CreateBzoneDevSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateBzoneDev". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#This module contains two functions in addition to the main function. The first
#function, calcBzoneDistDen, assigns a population density to each Bzone.
#It also assigns a distance from the urban core to 'metropolitan' type Bzones.
#The second function, calcBuildingTypes, calculates the number of single-family
#detached dwelling units and the number of multi-family dwelling units in each
#Bzone.

#Note that since the calcBzoneDistDen and calcBuildingTypes functions are
#defined outside of the main function (CreateBzoneDev), these functions don't
#have access to variables within the scope of the main function and therefore
#all their necessary inputs must be passed to them. This is done by passing
#a list, L, that contains all of the inputs.

#Function that simulates Bzone population density and distance from center
#-------------------------------------------------------------------------
#' Simulate Bzone density and distance characteristics
#'
#' \code{calcBzoneDistDen} simulates the population density of all Bzones
#' and distance from the urban core for Bzones whose DevType is "Metropolitan".
#'
#' The Bzone population density and distance from the urban core for
#' metropolitan Bzones are simulated using population, population density, and
#' distance distributions compiled by the U.S. Census Bureau.
#'
#' @param L A list containing the following components that have been read
#' from the datastore:
#' Bzone: A character vector of Bzone names read from the Bzone table.
#' DevType: A character vector identifying the development type of each Bzone
#' read from the Bzone table.
#' NumHh: A integer vector of the number of households in each Bzone read from
#' the Bzone table.
#' Area: A number identifying the geographic area of the metropolitan area read
#' from the Marea table.
#' @return A list containing the following components:
#' DistFromCtr: A numeric vector of the distance of each Bzone from the urban
#' area center.
#' PopDen: A numeric vector of the population density of each Bzone.
#' @export
calcBzoneDistDen <- function(L) {
  #Read miscellaneous parameters
  MiscParameters_ <- MiscDevParameters_df$Value
  names(MiscParameters_) <- MiscDevParameters_df$Parameter
  AveHhSize <- MiscParameters_["AveHhSize"]
  AveTownDensity <- MiscParameters_["AveTownDensity"]
  AveRuralDensity <- MiscParameters_["AveRuralDensity"]
  #Create vectors to store density and distance results
  Bz <- L$Bzone
  PopDen_Bz <- numeric(length(Bz))
  DistFromCtr_Bz <- numeric(length(Bz)) * NA
  #Calculate the average density of towns and rural areas
  PopDen_Bz[L$DevType == "Town"] <- AveTownDensity
  PopDen_Bz[L$DevType == "Rural"] <- AveRuralDensity
  #Metropolitan density and distance if any DevType is 'Metropolitan'
  if (any(L$DevType == "Metropolitan")) {
    #Calculate urbanized area density scale
    UrbDenGrad_ <-
      PopDenByDistance_df$PopDensity[which(PopDenByDistance_df$PopDensity >= 1000)]
    DistIndex_ <- 1:length(UrbDenGrad_)
    UrbPopProp_ <- PopByDistance_df$PopProp[DistIndex_]
    UrbPopProp_ <- UrbPopProp_ / sum(UrbPopProp_)
    #Calculate adjusted density gradient
    harmonicMean <- function( Probs., Values. ) {
      1 / sum( Probs. / Values. )
    }
    NumMetroHh <- sum(L$NumHh[L$DevType == "Metropolitan"])
    AveMetroDenTarget <- AveHhSize * NumMetroHh / L$Area
    AveMetroDen <- harmonicMean(UrbPopProp_, UrbDenGrad_)
    DenAdj <- AveMetroDenTarget / AveMetroDen
    UrbAdjDenGrad_ <- UrbDenGrad_ * DenAdj
    #Calculate adjusted distances
    UrbRadius <- sqrt(L$Area / pi)
    DistAdj <- UrbRadius / PopByDistance_df$Distance[tail(DistIndex_, 1)]
    UrbAdjDist_ <- DistAdj * PopByDistance_df$Distance[DistIndex_]
    #Choose distance and density for each metropolitan Bzone
    NumMetroBzones <- sum(L$DevType == "Metropolitan")
    MetroBzoneIdx_ <- sample(DistIndex_, NumMetroBzones, replace = TRUE,
                             prob = UrbPopProp_)
    MetroBzoneDen_ <- UrbAdjDenGrad_[MetroBzoneIdx_]
    MetroBzoneDist_ <- UrbAdjDist_[MetroBzoneIdx_]
    #Assign density and distance values to Bzones
    DistFromCtr_Bz[L$DevType == "Metropolitan"] <- MetroBzoneDist_
    PopDen_Bz[L$DevType == "Metropolitan"] <- MetroBzoneDen_
  }
  #Return the results in a list
  list(
    DistFromCtr = DistFromCtr_Bz,
    PopDen = PopDen_Bz
  )
}

#Function which estimates building type split based on population density
#------------------------------------------------------------------------
#' Simulate Bzone dwelling types.
#'
#' \code{calcBuildingTypes} calculates the number of single-family dwellings and
#' the number of multifamily dwelling units in each Bzone.
#'
#' This function calculates the number of single-family detached dwellings and
#' multifamily dwellings in each Bzone. This is done using a toy model which
#' relates the proportion of multifamily dwellings to population density. The
#' results are the numbers of single-family detached dwellings and multifamily
#' detached dwellings in each Bzone.
#'
#' @param L A list containing the following components that have been either
#' read from the datastore or produced by the application of the
#' calcBzoneDistDen function:
#' PopDen: A numeric vector of the population density of each Bzone produced by
#' the calcBzoneDistDen function.
#' NumHh: An integer vector of the number of households in each Bzone read from
#' the Bzone table.
#' @return A list containing the following components:
#' SfdNum: An integer vector of the number of households living in single-family
#' dwellings in each Bzone.
#' MfdNum: An integer vector of the number of households living in multifamily
#' dwellings in each Bzone.
#' @export
calcBuildingTypes <- function(L) {
  #Read miscellaneous parameters
  MiscParameters_ <- MiscDevParameters_df$Value
  names(MiscParameters_) <- MiscDevParameters_df$Parameter
  HhDen_Bz <- L$PopDen / MiscParameters_["AveHhSize"]
  MfProp_Bz <- (HhDen_Bz - 500) / 8000
  MfProp_Bz[MfProp_Bz < 0] <- 0
  MfProp_Bz[MfProp_Bz > 1] <- 1
  SfProp_Bz <- 1 - MfProp_Bz
  SfdNum_Bz <- round(L$NumHh * SfProp_Bz)
  storage.mode(SfdNum_Bz) <- "integer"
  MfdNum_Bz <- L$NumHh - SfdNum_Bz
  storage.mode(MfdNum_Bz) <- "integer"
  #Return the results in a list
  list(
    SfdNum = SfdNum_Bz,
    MfdNum = MfdNum_Bz
  )
}

#The main function, CreateBzoneDev
#---------------------------------
#' Calculate Bzone development characteristics
#'
#' \code{CreateBzoneDev} is the main function of the CreateBzoneDev module that
#' calls the calcBzoneDistDen and calcBuildingTypes functions to calculate
#' Bzone development characteristics.
#'
#' This is the main function for the CreateBzoneDev module. It is a wrapper for
#' the calcBzoneDistDen and calcBuildingTypes functions which do all of the
#' work of calculating Bzone development characteristics including distance from
#' the urban area center, population density, number of households in single-
#' family dwellings, and number of households in multifamily dwellings.
#'
#' @param L A list containing the following components that have been read from
#' the datastore:
#' Bzone: A character vector of Bzone names read from the Bzone table.
#' DevType: A character vector identifying the development type of each Bzone
#' read from the Bzone table.
#' NumHh: A integer vector of the number of households in each Bzone read from
#' the Bzone table.
#' Area: A number identifying the geographic area of the metropolitan area read
#' from the Marea table.
#' @return A list containing the following components:
#' DistFromCtr: A numeric vector of the distance of each Bzone from the urban
#' area center.
#' PopDen: A numeric vector of the population density of each Bzone.
#' SfdNum: An integer vector of the number of households living in single-family
#' dwellings in each Bzone.
#' MfdNum: An integer vector of the number of households living in multifamily
#' dwellings in each Bzone.
#' @export
CreateBzoneDev <- function(L) {
  #Calculate Bzone densities and distances and combine with the input list
  L <- c(L, calcBzoneDistDen(L))
  #Calculate Bzone building types and combine with the input list
  L <- c(L, calcBuildingTypes(L))
  #Return a list of values to be saved in the datastore
  L[c("DistFromCtr", "PopDen", "SfdNum", "MfdNum")]
}
```
### Appendix F: example vignette source file 
```
---
title: "Using the CreateHouseholds Module"
author: "Brian Gregor"
date: "`r Sys.Date()`"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Using the CreateHouseholds Module}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

The **CreateHouseholds** module creates a set of households reflecting a household size distribution that is representable for the region. The module creates a "Household" table and populates it with several attributes including *HhId* (unique household ID), *Azone* (Azone household is located in), and *HhSize* (number of people in the household. The module also tabulates the number of households in each Azone and adds the counts to the Azone table as *NumHh*. The model is run in the framework with the following command:  

```{r, eval=FALSE}  
runModule(ModuleName = "CreateHouseholds", PackageName = "vedemo1",  
             Year = XXXX, IgnoreInp_ = NULL, IgnoreSet_ = NULL) 
```
```
where the a four-digit year value is substituted for `XXXX`. Most often the Year argument will be input programmatically. The IgnoreInp_ and IgnoreSet_ arguments will ignore any specified 'input' and/or 'set' specifications identified by the specification names. This option is provided to allow knowledgeable users to substitute for specified inputs and/or outputs. It should only be used with extreme caution.

The *CreateHouseholds* module must be run before the *CreateBzones* and *CreateBzoneDev* modules are run. The module is run for the entire model area at once (the RunBy component is assigned the value "Region"). This is done because the full set of households must be created in order to determine how many rows the *Households* table will have. This needs to be determined in order to initialize the table.

The *CreateHouseholds* module depends on one scenario input that is provided at the Azone level. The input file must be named "azone_population.csv" and must be located in the "inputs" directory of the model run setup. An example is included in the "tests/data" directory of this package. The structure of the file is as follows:

```{r, echo=FALSE, results='asis'}
AzonePop_df <- read.csv("../tests/data/azone_population.csv", as.is = TRUE)
pander::pandoc.table(AzonePop_df)
```
```   
The column names for the file must be as shown. Rows need to exist for all Azones and all years for which the model will be run. The data in the *Population* column must be integer values and and thousands separators may not be used.

This module uses one model parameter file (*household_sizes.csv*) that is located in the "inst/extdata" directory of this package. The accompanying *household_sizes.txt* file describes the source and structure of that file. A substitute for that file (with the same name and structure) may be used instead to modify the module so that it is more representative of the region and/or base year for the model deployment. If you wish to do this, you must obtain the source package. Then modify the *household_sizes.csv* file, making certain that the modifications are consistent with the specifications described in the *household_sizes.txt* file. Then build the package to create a binary version. The best way to do this is using the RStudio IDE for R development along with the *devtools* package. RStudio is free and it along with *devtools* has everything you need to easily create a binary package from a source package. The `devtools::build(binary = TRUE)` will take care of things. For more information about R packages, I recommend referring to Hadley Wickham's book, *R Packages*, and/or to his [website](http://r-pkgs.had.co.nz/).

```