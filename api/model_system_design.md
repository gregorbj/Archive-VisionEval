## VisionEval Model System Design and Users Guide
**Brian Gregor, Oregon Systems Analytics LLC**  
**February 19, 2019**  
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
A module, at its heart, is a collection of data and functions that meet the specifications described in this document and that implement a submodel. Modules also include documentation of the submodel. Modules as made available to users in R packages. Typically a set of related modules is included in a package.


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
To help ease maintenance of VE, it is recommended to minimize the use of new R libraries, and to reuse R libraries used by existing VE modules when possible.

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
    RunFor = "AllYears",
    RunYear = Year)
  runModule(
    ModuleName = "PredictWorkers",
    PackageName = "SimHouseholds",
    RunFor = "AllYears",
    RunYear = Year)
  runModule(
    ModuleName = "PredictLifeCycle",
    PackageName = "SimHouseholds",
    RunFor = "AllYears",
    RunYear = Year)
  runModule(
    ModuleName = "PredictIncome",
    PackageName = "SimHouseholds",
    RunFor = "AllYears",
    RunYear = Year)
  ...
}


```

A full model run script is shown in Appendix A.   

The script calls two functions that are defined by the software framework; *initializeModel* and *runModule*. The *initializeModel* function initializes the model environment and model datastore, checks that all necessary modules are installed, and checks whether all module data dependencies can be satisfied. The arguments of the *initializeModel* function identify where key model definition data are found. The *runModule* function, as the name suggests, runs a module. The arguments of the *runModule* function identify the name of the module to be run, the package the module is in, and whether the module should be run for all years, only the base year, or for all years except for the base year. This approach makes it easy for users to combine modules in a 'plug-and-play' fashion. One simply identifies the modules that will be run and the sequence that they will be run in. This is possible in large part for the following reasons:  
1) The modules are loosely coupled. Modules only communicate to one another by passing information to and from the datastore or by calling the services of another module. Module calling is described in detail in section 8.1.2.2.
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
|   <datastore>  
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

The "datastore" is a file or directory that contains the central datastore for the model. The VisionEval framework supports multiple types of datastore. Currently, two types are supported. One type stores all data in a single binary [HDF5]() file. With this type, the datastore file is named "datastore.h5". The other type stores datasets in the form of native R data files. Files are stored in a hierarchical directory structure with the top-level directory named "Datastore". The logical structure of these two datastore types are very similar and are described in detail below. Users may use a different name for this file by specifying the name to be used in "parameters.json" file (see below). 

The "defs" directory contains all of the definition files needed to support the model run. Five files are required to be present in this directory: "run_parameters.json", "model_parameters.json", "geography.csv", "deflators.csv", and "units.csv".   

The "run_parameters.json" file contains parameters that define key attributes of the model run and relationships to other model runs. The file is a [JSON-formatted](http://www.json.org/) text file. The JSON format is used for several reasons. First, it provides much flexibility in how parameters may be structured. For example a parameter could be a single value or an array of values. Second, the JSON format is well documented and is very easy to learn how to use. It uses standard punctuation for formatting and, unlike XML, doesn't require learning a [markup language](https://en.wikipedia.org/wiki/Markup_language). Third, files are ordinary text files that can be easily read and edited by a number of different text editors available on all major operating systems. There are also a number of commercial and open source tools that simplify the process of editing and checking JSON-formatted files.  

The "run_parameters.json" file specifies the following parameters:  

- **Model** The name of the model. Example: "Oregon-GreenSTEP".  

- **Scenario** The name of the scenario. Example: "High-Gas-Price".  

- **Description** A short description of the scenario. Example: "Assume tripling of gas prices".   

- **Region** The name of the region being modeled. Example: "Oregon".  

- **BaseYear** The base year for the model. Example: "2015".  

- **Years** An array of all the 'forecast' years that the model will be run for. Example: ["2025", "2050"].  

- **DatastoreName** The name of the datastore. It can be any name that is valid for the operating system. It is recommended that this be named "datastore.h5" for HDF5 datastores and "Datastore" for R data file datastores.  

- **DatastoreType** A 2-letter abbreviation identifying the datastore type: "H5" for HDF5 datastore, "RD" for R data file datastore. The framework uses the DatastoreType abbreviation to choose the functions used to initialize the datastore and interact with it. 

- **DatastoreReferences** This optional parameter is a listing of other datastores that the framework should look for requested data in. This capability to reference other datastores enables users to split their model runs into stages to efficiently manage scenarios. For example, a user may wish to model how several transportation scenarios work with each of a few land use scenarios. To do this, the user could first set up and run the model for each of the land use scenarios. The user could then set up the transportation scenarios and make copies for each of the land use scenarios. Then the user would for each of the transportation scenarios reference the datastore of the land use scenario that it is associated with. Note that referenced datastores must have the same DatastoreType as the model datastore. For example, if the model datastore type is "H5", then all referenced datastores must be "H5" as well. The DatastoreReferences entry would look something like the following (the meaning of the entries is explained below):  
  "DatastoreReferences": {  
    "Global": "../BaseYear/datastore.h5",  
    "2010": "../BaseYear/datastore.h5"  
  }
  
- **Seed** This is a number that modules use as a random seed to make model runs reproducible.

- **RequiredVEPackages** Lists all of the VisionEval packages that contain modules that are called by the model.

The "model_parameters.json" can contain global parameters for a particular model configuration that may be used by multiple modules. For example, a model configuration to be a GreenSTEP model may require some parameters that are not required by a model configuration for an RSPM model. Parameters in this file should not include parameters that are specific to a module or data that would more properly be model inputs. While this file is available to establish global model parameters such as the value of time, it should be used sparingly in order enhance transferrability of modules between different models.

The "geography.csv" file describes all of the geographic relationships for the model and the names of geographic entities in a [CSV-formatted](https://en.wikipedia.org/wiki/Comma-separated_values) text file. The CSV format, like the JSON format is a plain text file. It is used rather than the JSON format because the geographic relationships are best described in table form and the CSV format is made for tabular data. In addition, a number of different open source and commercial spreadsheet and GIS programs can export tabular data in a CSV-formatted files. The structure of the model system geography is described in detail in Section 6.2 below.  

The "units.csv" file describes the default units to be used for storing complex data types in the model. The VisionEval model system keeps track of the types and units of measure of all data that is processed. The model system recognizes 4 primitive data types, a number of complex data types (e.g. currency, distance), and a compound data type. The primitive data types are data types recognized by the R language: 'double', 'integer', 'character', and 'logical'. The complex data types such as 'distance' and 'time' define types of data that have defined measurement units and factors for converting between units. The compound data type combines two or more complex data types whose units are defined in an expression (e.g. MI/HR where MI is the complex unit for miles and HR is the complex unit for hours). The *units.csv* describes the default units used to store complex data types in the datastore. The file structure and an example are described in more detail in Section 6.3 below.

The "deflators.csv" file defines the annual deflator values, such as the consumer price index, that are used to convert currency values between different years for currency demonination. The file structure and an example are described in more detail in Section 6.4 below.

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

  In rural areas, Bzones can be used to distinguish small cities from unincorporated areas. 
  
  Bzones may correspond to actual geographic areas or may be simulated. Bzone simulation greatly reduces model data requirements while still enabling the modeling of land-use-related policies and the effects of land use on various aspects of travel behavior. In VE-RPAT models, Bzones are simulated as *place types* which characterize the intensity and nature of development. In VE-State models, Bzones are synthesized to represent characteristics likely to be found in an actual set of Bzones within each Azone.

- **Mareas**  
Mareas are collections of Azones associated with an urbanized area either because a portion of the urbanized area is located in the Azone or because a substantial proportion of the workers residing in the Azone work at jobs located in the urbanized area. Metropolitan models typically only have one assigned Marea whereas state models may have several. The model system requires that each Azone may be associated with only one Marea. It is also required that all Azones be associated with an Marea. A special Marea named '**None**' is used to apply to Azones that are not associated with any urbanized area. Mareas are used to specify and model urbanized area transportation characteristics such as overall transportation supply (transit, highways) and congestion. They are also used to specify large scale land-use-related characteristics and policies in models that use Bzone synthesis.

Geographical relationships for a model are described in the "geography.csv" file contained in the "defs" directory. This file tabulates the names of each geographic unit (except for Region) and the relationships between them. Each row shows a unique relationship. Where a unit of geography is not explictly defined (i.e. it will be simulated), "NA" values are placed in the table. Appendix B shows examples of the "geography.csv" file where only Azones are specified and where Azones and Bzones are specified. It should be noted that there are no naming conventions for individual zones. The user is free to choose what conventions they will use.

#### 6.3. Data Types, Units, and Currency Deflators

A key feature of the VisionEval model system that enables modules to be bound together into models is a data specifications system. All datasets that a module requires as inputs and datasets that that a module produces must be specified according to requirements. Section 8 describes these specifications in more detail. This section provides an introduction to the TYPE and UNITS specification requirements to provide context for understanding the "units.csv" file in the "defs" directory.

The TYPE attribute for a dataset identifies the data type. The UNITS specification identifies the units of measure. The TYPE and UNITS specifications are related. The TYPE attribute affects the values that may be specified for UNITS attribute and how the framework processes the units values. The model system recognizes 3 categories of data types: 'primitive', 'complex', 'compound'. The 'primitive' category includes the 4 data types recognized by the R language: double, integer, character, and logical. A dataset that is specified as one of these types has no limitations on how the units of measure are specified. The 'complex' category currently includes 13 data types such as currency, distance, and area as shown in the table below. A dataset that is one of these types is limited to specified unit values. For example, the allowed units for the 'distance' type are MI, FT, KM, and M (for mile, foot, kilometer, and meter). The 'compound' category is composed of the compound data type. For compound data, units are represented as an expression involving the units of complex data types. For example, a dataset of vehicle speeds can be specified as having a TYPE that 'compound' and UNITS that are 'MI/HR'. The type is compound because it is made up of two complex types; distance and time. The units are an expression containing distance and time units and the '/' operator. The '*' (multiplication) operator may also be used in the units expression for a compound data type. Appendix C documents all the types and units in more detail. 

Although the complex and compound data types limit what values the units attributes may have, specifying these types enables the framework software to take care of unit conversions between modules and the datastore. For example, say that a model datastore contains a dataset for Bzone population density having units of persons per square mile. In this case the TYPE attribute for the data would be 'compound' and the UNITS would be 'PRSN/SQMI'. If a module which calculates household vehicle travel needs population density measured in persons per acre, the module would specify the UNITS as 'PRSN/ACRE' and the framework would take care of converting the density values from the units used in the datastore to the units requested by the module. This simplifies matters for module developers and reduces the likelihood of errors due to data conversions. 

Although the units specified by a module for a complex data type may be any of the recognized units (e.g. for distance - MI, FT, KM and M), this flexibility does not apply to the datastore. Complex data is stored in the datastore in predefined ways to limit potential confusion and simplify unit conversions. The default units file (units.csv) in the "defs" directory declares the default units to use for storing complex data types in the datastore. This file has two fields named 'Type' and 'Units'. A row is required for each complex data type recognized by the VisionEval system. The listing to date of complex types and the default units in the demonstration models are as follows:

|Type      |Units|Description      |
|----------|-----|-----------------|
|currency  |USD  |U.S. dollars     |
|distance  |MI   |miles            |
|area      |SQMI |square miles     |
|mass      |LB   |pounds           |
|volume    |GAL  |gallons          |
|time      |DAY  |days             |
|energy    |MJ   |megajoules       |
|people    |PRSN |persons          |
|vehicles  |VEH  |vehicles         |
|trips     |TRIP |trips            |
|households|HH   |households       |
|employment|JOB  |jobs             |
|activity  |HHJOB|households & jobs|

For 'currency' data it's not sufficient to convert values to different units, it's also necessary to convert currency values between years to account for the effects of inflation. Because the model parameters estimated in different modules may come from datasets collected in different years, and because model users will most likely want to report currency values in current year terms, it is necessary to convert currency values between years. Currency denominated datasets are stored in the datastore as base year values. When a module needs to use a currency denominated dataset, the framework converts base year values to the year values that the module needs. If a module calculates a currency denominated dataset that is to be saved in the datastore, the framework converts those values from the currency year that the module uses to base year values to save in the datastore. The software framework takes care of the process of converting currency values between years automatically and in a consistent manner. This eliminates the need for model developers to convert currency values. It also allows more flexibility for model users and module developers, and for the evolution of the VisionEval model system with new and improved modules, because it eliminates the need to establish a reference year that is to be used for all modules and models. 

Modules specify the year of a currency dataset using a modifier to the the UNITS specification. This is done by adding a period and 4-digit year to the specification. For example, the UNITS specification for year 2000 dollars would be 'USD.2000'. Note, however, that this convention does not apply to specifications for currency data that is read in from an input file because the model user is free to establish any currency year they choose for currency inputs. In those cases, the year is specified in the input file. This is explained in Section 6.4.

Currency values are converted between years using a deflator series is defined for the model in the "deflators.csv" file in the "defs" directory. This file has 2 columns, 'Year' and 'Value'. Values are needed for all years specified by modules used in a model in addition to the base year and any other years that currency values in input files will be denominated in. For example, if the modules to be used in a model use dollar denominated values for the years 2000 and 2009, the model base year is 2010, and some input data are denominated in 2015 dollars, then at a minimum the "deflators.csv" file must include deflators for those years. A more flexible approach would be to have an annual series of deflators running from the earliest year through the latest year. **Note**: it is not necessary to specify deflators for any future model years (e.g. 2030, 2050). All modules in the model system make calculations in constant (uninflated) dollar terms. Deflators are only used to convert user input values to a constant base and to convert values to the year that is consistent with a module's estimation data.

The UNITS value may also specify a multiplier option for complex and compound data types. This capability exists because modules may use data that are represented in thousands or millions when numbers are very large. For example, freeway and arterial construction costs may be represented in thousands of dollars per mile. A multiplier option is added to a units name by adding a period and then the multiplier expressed in scientific notion where the leading digit must be a 1 (e.g. 1e3 for thousands). For currency units, the multiplier option must follow the year notation. For example, 2010 dollars expressed in thousands would be expressed as 'USD.2010.1e3'. Miles traveled expressed in millions would be 'MI.1e6'.

#### 6.4. Model Inputs

The *inputs* directory contains all of the model inputs for a scenario. A model input file is a table that relates one or more input fields to geographic units and years. Because of the tabular nature of the data, all input files are CSV-formatted text files. The first row of the file contains the headers identifying the data in each column. The columns include each of the data items specified in the input specifications for the module the input file is used for. In addition, the file may be required to have columns labeled **Geo** and **Year** depending on which of the following 4 types the input file is:

* **Inputs apply to the entire region and to all years**: In this case, the input file consists of one data row and each column corresponds to a data item.

* **Inputs apply to parts of the region and to all model years**: In this case, the input file consists of one data row for each geographic area and the file must include a column labeled **Geo** that is used for identifying the geographic areas. For example, if the input file applies to Azones and the model has 10 Azones, the file must have 10 rows in addition to the header. The **Geo** column identifies each of the Azones. Note that only the geographic areas specified in the *geo.csv* may be included in this file. If unlisted geographic areas are included, the model run will stop during initialization and the log will contain messages identifying the error(s).

* **Inputs apply to the entire region but vary by model year**: In this case, the input file consists of one data row for each model year and the file much include a column labeled **Year** that is used for identifying the model years. For example, if the model run parameters specify that the model is to be run for the years 2010 and 2040, the input file must contain 2 rows in addition to the header. The **Year** column identifies each of the model run years. Note that only the specified model run years may be included in this file. If unspecified model run years are included, the model run will stop during initialization and the log will contain messages identifying the error(s).

* **Inputs apply to parts of the region and vary by model year**: In this case the input file consists of one data row for each combination of geographic area and model year. The file must include a **Geo** column and a **Year** column. There must be as many rows as there are combinations of geography and years. For example if an input file applies to Azones and the model specifies 10 Azones and 2 model run years, the file must have 20 rows to accommodate all the combinations in addition to a header row. The **Geo** and **Year** columns may only contain values specified for the model. If they contain any unspecified values, the model run will stop during initialization and the log will contain messages identifying the error(s).

By convention, input file names which include inputs that vary by level of geography, include the level of geography in the input file name. File names should be descriptive. Following are some examples:  
- azone_hh_pop_by_age.csv  
- azone_hhsize_targets.csv  
- bzone_dwelling_units.csv

The name of an input file and the names of all the columns except for the "Geo" and "Year" columns are specified by the module that requires the input data. In addition to specifying the file and column names, the module specifies:  
- The level of geography the inputs are specified for (e.g. Region, Azone, Bzone, Czone, Marea);  
- The data types in each column (e.g. integer, double, currency, compound);  
- The units of the data in each column (e.g. MI, USD); and,  
- Acceptable values for the data in each column.  

The module section describes these specifications in more detail below. Appendix D shows examples of the two types of input files.  

The field names of the input file (other than the "Geo" and "Year" fields) can encode year and unit multiplier information in addition to the name of the data item. This is done by breaking the name into elements with periods (.) separating the elements as follows:  

For 'currency' data type: **Name.Year.Multiplier**. For example, `TotalIncome.2010.1e3` would be the field name for total income in thousands of 2010 dollars.
For all other data types: **Name.Multiplier**. For example, `TotalDvmt.1e6` would be the field name for total daily vehicle miles traveled in millions.

Where: 
**Name** is the dataset name. This must be the same as specified in the module that calls for the input data.  
**Year** is the four-digit representation of the year that the currency values are denominated for. For example if a currency dataset is in 2010 dollars, the 'Year' value would be '2010'. The field name for a currency field must include a 'Year' element.
**Multiplier** is an optional element which identifies the units multiplier. It must be expressed in scientific notation (e.g. 1e3) where the leading digit must be 1. This capability exists to make it easier for users to provide data inputs that may be more conveniently represented with a smaller number of digits and an exponent. For example, annual VMT data for a metropolitan area or state is often represented in thousands or millions.

The the VisionEval framework uses the year and multiplier information to convert the data to be stored in the datastore. All currency values are stored in base year currency units and all values are stored without exponents.

#### 6.5. The Datastore

VisionEval changes the approach to storing model data from that of the GreenSTEP and RSPM models and related models. Those models stored data primarily in R data frames as binary files (rda files). The largest of these files are the simulated household files which store all of the information for all simulated households in an Azone (e.g. counties in GreenSTEP). All the data for households in the Azone are stored in a single data frame where each row corresponds to a record of an individual household and the columns are household attributes. Vehicle data for households are stored as lists in the data frame. This approach had some benefits:  
- Storage and retrieval are part of the R language: one line of code to store a data frame, and one line of code to retrieve;  
- It is easy to apply models to data frames; and  
- Vehicle data can be stored as lists within a household data frame, eliminating the need to join tables.  

The simplicity of this approach helped with getting GreenSTEP from a concept into an operational model quickly. However, several limitations have emerged as GreenSTEP and related models have been used in various applications including:  
- Large amounts of computer memory are required when modeling Azones that have large populations. This necessitates either expanding computer memory or limiting the size of Azones;  
- It is not easy to produce summary statistics from the simulated household files for a region; and  
- The number of non-household data files has proliferated in order to store various aggregations for use in the model and for later summarization.

Finally, because the GreenSTEP/RSPM approach did not define a consistent data model, it does not sufficiently support the goal of modularity, and it does not support the use of alternative datastores. To overcome these limitations the VisionEval model system specifies a consistent datastore design. This design has been implemented in two types of datastores. One uses R binary files within a hierarchical directory structure. The other uses the HDF5 file format for storing model data. The HDF5 file format was developed by the National Center for Supercomputing Applications (NCSA) at the University of Illinois and other contributors to handle extremely large and complex data collections. For example, it is used to store data from particle simulations and climate models. It also is the basis for the new open matrix standard for transportation modeling, [OMX](https://github.com/osPlanning/omx). 

VisionEval datastores are organized in a 'column-oriented' and hierarchical structure illustrated below. The lowest level of the hierarchy are datasets which are vectors of data values. This matches well the data objects (lists and data frames) commonly used in R programs and calculation methods which are commonly vectorized. Datasets in R datastores are R binary files. In HDF5 datastores, they are a portion of the HDF5 file and are called datasets in the HDF5 nomenclature. Datasets are organized in tables which are groups of datasets that all have the length. For example in the diagram below, Azone is a dataset containing the names of each of the Azones, and Age0to14 is a dataset containing the number of people of age 0 to 14 in each each Azone. These datasets and all those listed directly below them are contained in the Azone table. In R datastores, tables are represented by directories. In HDF5 nomenclature they are called groups. Tables that represent values for a particular model run year are grouped together.  The year groups are named with the model run years (e.g. 2010, 2050) and they contain tables for every geographic level as well as 'Household', 'Worker', and 'Vehicle' tables.  Tables that contain datasets whose values don't vary by model run year are contained in the 'Global' group (directory). These include tables of model parameters, geographic tables, and any other table of datasets that apply to all model run years.

```    
|____Global
|    |____Model
|    |        ...
|    |
|    |____Azone
|    |        ...
|    :
|
|____2010  
|    |____Region
|    |        ...
|    |
|    |____Azone
|    |        Azone
|    |        Marea
|    |        Age0to14
|    |        Age15to19
|    |        Age20to29
|    |        Age30to54
|    |        Age55to64
|    |        Age65Plus
|    |        ...
|    |
|    |____Bzone
|    |        ...
|    |
|    |____Marea
|    |        ...
|    |
|    |____Household
|    |        ...
|    |
|    |____Worker
|    |        ...
|    |
|    |____Vehicle
|    |        ...
|    :
|
|
|____2050  
|    |____ ...
|    |        ...
:    :

```

This structure is adequate to store all of the data that are used by the GreenSTEP/RSPM models and their offshoots. It can also be easily expanded to serve new modeling capabilites. For example if a module is added to model building stock, a 'Buildings' table could be added to each 'forecast year' group. In addition, this structure can accommodate matrix data as well as vector data, if a future module makes use of a distance matrix, that matrix could be added to either the 'Global' group or the 'forecast years' groups.  

Note that the Azone table in the diagram includes an Marea dataset. This datasets identifies the Marea associated with each Azone. Every table includes datasets that enable data to be joined between tables. Some are geographic as in the example. Others use other identifiers. For example the Worker table includes a household identifier. Although the tables include the identifiers which enable data to be joined between tables, the VisionEval framework does not include special features for joining datasets that come from different tables. That is done by the module code.

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
- RequireVEPackages: A list of all the VisionEval packages that must be installed in order for the model to run
- LogFile: The file name of the log file  
- Datastore: A data frame containing an inventory of the contents of the datastore  
- Geo_df: A data frame containing the geographic definitions for the model  
- BzoneSpecified: A logical value identifying whether Bzones are specified for the model  
- CzoneSpecified: A logical value identifying whether Czones are specified for the model  
- ModuleCalls_df: A data frame identifying the sequence of 'runModule' function calls and arguments
- ModulesByPackage_df: A data frame identifying the modules located in each of the VisionEval packages required to run the model
- DatasetsByPackage_df: A data frame identifying the datasets located in each of the VisionEval packages required to run the model 

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

When the software framework "runs" a module it does several things. First, it reads in the module data specifications and the main module function which performs the submodel calculations. Then it reads in all the datasets from the datastore that the module specifies. It also reads in the contents of the model state file. It puts these datasets into an input list and then it calls the main module function with this input list as the argument to the function call. This list, which by convention is called 'L', contains 4 components: Global, Year, BaseYear, and G. The Global, Year, and BaseYear components contain lists which are composed of table components which are in turn composed of dataset components. The Global component relates to the 'global' group in the datastore. The Year component relates to the the group in the datastore for the model run year. For example, if the model run year is 2040, the Year component will contain data that is read from the '2040' group in the datastore. The BaseYear component relates to the group in the datastore which represents the base year for the model. For example if the model base year is 2010, the BaseYear component will contain data that is read from the '2010' group in the datastore. The list contains a BaseYear component as well as a Year component because modules may need to compute changes in a dataset between the base year and the model run year. Each of these components will contain a component for each table the the module requests data from. The table component is also a list which then contains components for all the requested datasets. For example, if a module needs the household income ('Income') and household size ('HhSize') datasets from the 'Household' table in the model run year (e.g. 2040), the Year component of 'L' will contain a 'Household' component which will contain an 'Income' component and a 'HhSize' component. The 'G' component of 'L' contains the model state list which contains all the information described in Section 6.6.

If a module calls another module, the list also contains a component named with the alias the module assigns to the called module. This component includes Global, Year, and BaseYear components containing datasets identified in the specifications for the called module. Module calling is explained in detail in section 8.1.2.

When the module executes, it returns a list containing all of the information that the module specifies is to be written to the datastore. By convention, this list is called 'R'. This list also has Global, Year, and BaseYear components which are structured in the same way that 'L' is structured. The table and dataset components of the list also include some attributes (metadata) which are described in Section 8.

### 8. Modules  
All modules are made available in the form of standard R packages that meet framework specifications. Packages may be in source form or installed form. The following presentation refers to the source form of VisionEval packages. When a package is installed (built) the R system runs the scripts in the R directory and saves functions that are defined within and datasets that are saved by the script. The structure of this installed package is not covered by this document with the exception of the *module_docs* directory in the installed package. If the module developer follows the guidelines for module documentation, a *module_docs* directory will be included in the installed package. This will include module documentation in the form of markdown documents.

A package may contain more than one module. The package organization follows the standard organization of R packages. The structure is shown in the following diagram. The components are described below in the order that they are presented in the diagram. The file names are examples.

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
     |____scripts
     |    |   test.R
     |    |   test_functions.R
     |    |   verspm_test.R 
     |    |   vestate_test.R    
     |
     |____verspm
     |    |   logs
	 |    |   |   Log_CreateHouseholds.txt
	 |    |   |   ...
	 |    |
	 |    |   ModelState.Rda
	 |    
     |____vestate
     |    |   ...
     |
     |    ...

```

The *DESCRIPTION* and *NAMESPACE* files are standard files required by the R package system. There are good sources available for describing the required contents of these files ([R Packages](http://r-pkgs.had.co.nz/)), so that will not be done here. Most of the entries in these files can be produced automatically from annotations in the R scripts that will be described next, using freely available tools such as [devtools](https://github.com/hadley/devtools) and [RStudio](https://www.rstudio.com/). The *LICENSE* file contains the text for the Apache 2 license which is the open source license that should be used for VisionEval packages. The accompanying Apache 2 *NOTICE* file is in the *inst* directory.

#### 8.1. The R Directory
The *R* directory is where all the R scripts are placed which define the modules that are included in the package. Each module is defined by a single R script which has the name of the module (and the .R file extension). A module script does 4 things:  
1) It specifies the model and estimates model parameters. Model estimation datasets may be processed by the script or may be loaded from other sources (see below).  
2) It defines all the specifications for data that the module depends on.  
3) It defines all of the functions that implement the submodel.
4) It includes test code used during module development

When a binary (installed) package is built from the source package, each R script is run; estimation datasets are processed, model parameters are saved, module specifications are saved, functions are parsed into a more efficient form. Following section describe the structure of a module R script in more detail. An example of the *AssignTransitService* module script from the *VETransportSupply* package is included in Appendix E.  

By convention, the module script is organized into 4 sections reflecting the list above. Following sections 8.1.1 to 8.1.4 explain each module script section in detail. Section 8.1.1 explains how model specification and estimation is handled. Subsection 8.1.1.1 focuses in on the handling of model estimation data which, in some cases, may use specialized scripts. Section 8.1.2 explains how to write module specifications which tell the framework how the module is to be run, what input data are to be processed, what data are to be retrieved from the datastore, and what data are to be saved to the datastore. Subsection 8.1.2.1 focuses in on the *OPTIONAL* specification that module developers can use to enable optional model inputs. Subsection 8.1.2.2 focues in the the *CALL* specification that enables modules to call other modules to perform calculation services. Section 8.1.3 describes how to write a main function and supporting functions to implement a module. Section 8.1.4 explains test code that is commonly included in a module to assist the module developer in the module development process. Finally, Section 8.1.5 explains a special module named *Initialize* that may be included in a package. The purpose of this module is to enable module developers to include specialized input data checks and preparation. 

##### 8.1.1 Model Specification and Estimation
As the name suggests, this section of the script handles tasks related to processing model estimation data, model specification, and model parameter estimation. This should be done in a manner which enables others to understand the structure of the model, the data it is based on, and how parameters are estimated. It should enable others to replicate the process and to test modifications. Typically, model specification and estimation code does 4 things: loading the data to be used, defining functions that carry out key specification and estimation procedures, applying the functions to produce objects that define the model(s), and saving the model objects. 

Models vary in their complexity. In some modules the model may simply be an algorithm with decision rules or asserted parameters. In this case, there is no need to fill out this section of the script. For example, the *AssignLifeCycle* module in the *VESimHouseholds* package assigns lifecycle codes to households using rules regarding the numbers of adults, children, and workers in the household. In cases like this, the model estimation and specification section will be empty. In other cases, models will be quite complex and this section of the script will be extensive. For example, the "CalculateHouseholdDvmt" module does the following in the process of building models and comprises hundreds of lines of code:  
- Estimate a binomial logit model of the probability that a household has any DVMT
- Estimate a linear model of the amount of household DVMT given that a household has any DVMT
- Estimate a dispersion factor for the linear model so that the variance of modeled DVMT matches the observed variance
- Simulate household DVMT 1000 times by stochastically applying the binomial and linear models
- Calculate quantiles of simulated DVMT
- Estimate a linear model of average DVMT using the simulation data
- Estimate models of the DVMT quantiles as a function of the average DVMT  

Model estimation data preparation may also be extensive. Whether it is or not, documenting the data used in building a model and making those data available are key to making the models reproducible and extensible. Moreover, for some modules it is important that model users be able to have model parameters reflect the conditions for their region. For example, the *CreateHouseholds*, *PredictWorkers*, and *PredictIncome* modules use Census public use microdata sample data for the region to estimate parameters. There are several ways that model estimation data can be handled in the VisionEval model system. These are described in detail in Section 8.1.1.1.

The model estimation code should also save objects to use in documenting the modules such as:
1. Model summary statistics such as is produced when a model object (such as a linear model estimated using the *lm* function) is processed by the *summary* function;
2. Data frames, tables, and matrices; and,
3. Graphs or other static data visualizations.

The first two should be saved as objects just like any other object saved to implement a model. It is suggested that these documentation objects be stored in a list along with the model that they document. For example, follow is a portion of the *PredictIncome.R* script which saves (and documents) a list which contains the household income model including documentation of the summary statistics for the model.

```
#Save the household income model
#-------------------------------
#' Household income model
#'
#' A list containing the income model equation and other information needed to
#' implement the household income model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("linear")}
#'   \item{Formula}{makeModelFormulaString(IncModel_LM)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the linear model}
#'   \item{OutFun}{a function that transforms the result of applying the linear model}
#'   \item{Summary}{the summary of the linear model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source PredictIncome.R script.
"HHIncModel_ls"
usethis::use_data(HHIncModel_ls, overwrite = TRUE)
```
The *Summary* component of this list shows the summary statistics for the model. As explained in the module documentation section below, this can be automatically inserted into the module documentation. It is recommended that the *capture.output* function be used rather than the *print* function to capture model summary statistics because the *print* function will insert line numbers. This method can be used to save other text that can then be inserted into module documentation. This example also shows how objects are documented and saved.

It can also be useful to save data frames, tables, matrices to use in the model documentation. These can be saved like any other data object and then inserted as described in the module documentation section.

Graphs or other visualizations are saved in a different manner. If these are saved as an image file in "png" format, they can be inserted into the module documentation. They must be saved to the "data" directory to do so. Following is an example:

```
#Plot comparison of observed and estimated income distributions
png(
  filename = "data/reg-hh-inc_obs-vs-est_distributions.png",
  width = 480,
  height = 480
)
plot(
  density(IncObs_),
  xlim = c(0, 200000),
  xlab = "Annual Dollars ($2000)",
  main = "Distributions of Observed and Predicted Household Income \nRegular Households"
  )
lines(density(IncEst_), lty = 2)
legend("topright", legend = c("Observed", "Predicted"), lty = c(1,2))
dev.off()
```

There are many ways that a module developer can code the model specification and parameter estimation procedures. However this is done, the code should be well organized and commented so that it is understandable to reviewers. All code should follow the VisionEval coding guidelines. In addition, it is highly recommended that code be grouped into functions to aid understandability and reduce unnecessary code repetition which can lead to errors. Complex functions should be well documented. Function documentation is done using [Roxygen syntax](http://r-pkgs.had.co.nz/man.html). Following is an example of the code which estimates a housing choice model (single-family vs. multifamily) in the *PredictHousing* module of the *VELandUse* package.  

```
#Define a function to estimate housing choice model
#--------------------------------------------------
#' Estimate housing choice model
#'
#' \code{estimateHousingModel} estimates a binomial logit model for choosing
#' between single family and multifamily housing
#'
#' This function estimates a binomial logit model for predicting housing choice
#' (single family or multifamily) as a function of the supply of housing of
#' these types and the demographic and income characteristics of the household.
#'
#' @param Data_df A data frame containing estimation data.
#' @param StartTerms_ A character vector of the terms of the model to be
#' tested in the model.
#' @return A list which has the following components:
#' Type: a string identifying the type of model ("binomial"),
#' Formula: a string representation of the model equation,
#' PrepFun: a function that prepares inputs to be applied in the binomial model,
#' OutFun: a function that transforms the result of applying the binomial model.
#' Summary: the summary of the binomial model estimation results.
#' @import visioneval stats
#Define function to estimate the income model
estimateHousingModel <- function(Data_df, StartTerms_) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <-
    function(In_df) {
      Ah <-
        c("Age15to19",
          "Age20to29",
          "Age30to54",
          "Age55to64",
          "Age65Plus")
      Out_df <-
        data.frame(t(apply(In_df[, Ah], 1, function(x) {
          AgeLvl_ <- 1:5 #Age levels
          HhAgeLvl_ <- rep(AgeLvl_, x)
          HeadOfHh_ <- numeric(5)
          if (max(HhAgeLvl_) < 5) {
            HeadOfHh_[max(HhAgeLvl_)] <- 1
          } else {
            if (all(HhAgeLvl_ == 5)) {
              HeadOfHh_[5] <- 1
            } else {
              NumMidAge <- sum(HhAgeLvl_ %in% c(3, 4))
              NumElderly <- sum(HhAgeLvl_ == 5)
              if (NumMidAge > NumElderly) {
                HeadOfHh_[max(HhAgeLvl_[HhAgeLvl_ < 5])] <- 1
              } else {
                HeadOfHh_[5] <- 1
              }
            }
          }
          HeadOfHh_
        })))
      names(Out_df) <- paste0("Head", Ah)
      Out_df$HhSize <- In_df$HhSize
      Out_df$Income <- In_df$Income
      Out_df$RelLogIncome <- log1p(In_df$Income) / mean(log1p(In_df$Income))
      Out_df$Intercept <- 1
      Out_df
    }
  EstData_df <- prepIndepVar(Data_df)
  EstData_df$SingleFamily <- as.numeric(Data_df$HouseType == "SF")
  #Define function to make the model formula
  makeFormula <-
    function(StartTerms_) {
      FormulaString <-
        paste("SingleFamily ~ ", paste(StartTerms_, collapse = "+"))
      as.formula(FormulaString)
    }
  #Estimate model
  HouseTypeModel <-
    glm(makeFormula(StartTerms_), family = binomial, data = EstData_df)
  #Return model
  list(
    Type = "binomial",
    Formula = makeModelFormulaString(HouseTypeModel),
    Choices = c("SF", "MF"),
    PrepFun = prepIndepVar,
    Summary = summary(HouseTypeModel)
  )
}

#Estimate the binomial logit model
#---------------------------------
#Load the household estimation data
Hh_df <- VESimHouseholds::Hh_df
#Select regular households
Hh_df <- Hh_df[Hh_df$HhType == "Reg",]
Hh_df$Income[Hh_df$Income == 0] <- 1
#Estimate the housing model
HouseTypeModelTerms_ <-
  c(
    "HeadAge20to29",
    "HeadAge30to54",
    "HeadAge55to64",
    "HeadAge65Plus",
    "RelLogIncome",
    "HhSize",
    "RelLogIncome:HhSize"
  )
HouseTypeModel_ls <- estimateHousingModel(Hh_df, HouseTypeModelTerms_)
rm(HouseTypeModelTerms_)
```

As can be seen in this example, most of the code defines and documents a function which estimates a binomial choice model given a estimation dataset and a list of model variable names. This function does a number of things including transforming estimation data, creating a model formulation from the list of independent variables, estimating the variables, and returning a list of model components. After the function is defined, it is applied using the model estimation data and a specified list of independent variables. This approach to model specification and estimation makes it easy for a module developer to try out different model specifications, measuring their relative performance, and documenting the results.

The approach used in this example takes advantage of some helper functions in the framework software. The *makeModelFormulaString* function takes an R model formula object and converts it into a string representation. When the model is applied in the module, the string is parsed and evaluated with a data frame of independent variables. This provides a compact way to store a model and a fast way to apply it. Several other framework functions assist with applying models in this form. The *applyBinomialModel* applies a binomial logit model. The *applyLinearModel* applies a linear regression model. Both of these functions enable the models to self calibrate to match an input target. For example, the *PredictHousing* module adjusts the constant of the model so that the proportions of households in single-family vs. multifamily dwelling units matches the housing supply in the area. The *applyBinomialModel* does this efficiently by calling the *binarySearch* function which implements a binary search algorithm.

Module developers are not limited to using the previous approach to specifying and implementing a model. Most if not all R functions that estimate models also have companion prediction functions to apply the estimated model to a new set of data. This is often the simplest and best way to apply a model. One drawback of this approach, however, is that the object that is returned by the model estimation function and that is used in making a prediction is often very large because it includes a copy of all of the estimation data and datasets used to calculate model statistics. If the model estimation datasets are very large, this will pose a problem for keeping the module package in a central repository. In that case, the module code needs to remove parts of the model object that are not necessary for prediction. For example, the *AssignVehicleOwnership* module in the *VEHouseholdVehicles* package uses an ordered logit model to predict household auto ownership for households owning one or more vehicles. The model is estimated using data from the 2001 NHTS so the model object returned by the estimation function (*clm* in the *ordinal* package) is large. Portions of the model object not needed by the corresponding prediction function are removed. It is often a matter of trial and error to find out how much can be removed from the model object without adversely affecting the prediction function.

```
#Model number of vehicles of non-zero vehicle households
EstData_df <- EstData_df[EstData_df$ZeroVeh == 0,]
EstData_df$VehOrd <- EstData_df$NumVeh
EstData_df$VehOrd[EstData_df$VehOrd > 6] <- 6
EstData_df$VehOrd <- ordered(EstData_df$VehOrd)
AutoOwnModels_ls$Metro$Count <-
  clm(
    VehOrd ~ Workers + LogIncome + DrvAgePop + HhSize + OnlyElderly + IsSF +
      IsUrbanMixNbrhd + LogDensity + TranRevMiPC,
    data = EstData_df,
    threshold = "equidistant"
  )
#Trim down model
AutoOwnModels_ls$Metro$Count[c("fitted.values", "model", "y")] <- NULL
```

After a model has been estimated, the model objects which embody the model need to be saved as part of the package. There is a standard way of doing this which is illustrated in the following example of saving the model in the *PredictHousing* module. The housing prediction model object is a list called 'HouseTypeModel_ls'. This list is saved in the 'data' directory of the package. By saving the model object in the 'data' directory, it can be addressed directly in the module function that applies the model. Note how documentation is handled.

```
#Save the housing choice model
#-----------------------------
#' Housing choice model
#'
#' A list containing the housing choice model equation and other information
#' needed to implement the housing choice model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("binomial")}
#'   \item{Formula}{makeModelFormulaString(HouseTypeModel)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the model}
#'   \item{Summary}{the summary of the binomial logit model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source PredictHousing.R script.
"HouseTypeModel_ls"
usethis::use_data(HouseTypeModel_ls, overwrite = TRUE)

```

The *use_data* function in the *usethis* package saves the data and documention correctly in the package and simplifies the procedure for doing so.

Although model estimation code is usually included in the module script, in some instances it may be more understandable to estimate the models for several modules in one script. This is what is done in the *CreateSimBzoneModels.R* script in the *VESimLandUse* package. This script estimates all the models for modules in the package. Model estimation is handled this way because the same model estimation dataset is used for all the models and the models build upon each other. Including all the model estimations in one file makes it easier to code and easier to review.

###### 8.1.1.1 Model Estimation Datasets
Model estimation datasets may be read in from several sources. If model estimation data are large and are used by multiple modules located in different packages, then they may be housed in their own package. This is the case with the 2001 NHTS data which are in the *VE2001NHTS* package. The estimation data in the package can be directly addressed in the model estimation code using the standard 'PackageName::DatasetName' notation as shown in the following example:  

```
Hh_df <- VE2001NHTS::Hh_df
```

If estimation data are retrieved from another package as in this case, the DESCRIPTION file for the package must list the package from which the data are retrieved in the *Imports* section. For example, the Imports section of the VEHouseholdTravel package reads as follows. The VE2001NHTS package is listed as are other packages that this package relies on.

```
Imports:
    visioneval,
    devtools,
    VE2001NHTS,
    data.table
```
    
If estimation data is to be shared among several modules that are all within the same package, then all the data preparation can be done in one script which is run first when the package is built. This approach is used in the *VESimHouseholds* package. The *CreateEstimationDatasets.R* script loads and processes a Census public use microdata sample dataset that is used in estimating models in 3 modules that are in the package (*CreateHouseholds*, *PredictWorkers*, *PredictIncome*). When, as in this case, a separate script is used to prepare the estimation data for several modules in the package, the data are saved in the data directory of the package and the other scripts load the dataset from that directory. The following extracts shows how a processed PUMS household dataset (a data frame named Hh_df) is saved in the CreateEstimationDatasets.R script. The lines starting with `#'` are data documentation in [roxygen2](https://cran.r-project.org/web/packages/roxygen2/vignettes/roxygen2.html) form. Although data documentation can be tedious, especially for large datasets, it is should always be done and is an important aspect of the VisionEval model system.

```
#' Household data from Census PUMS
#'
#' A household dataset containing the data used for estimating the
#' CreateHouseholds, PredictWorkers, PredictLifeCycle, PredictIncome, and
#' PredictHouseType modules derived from from year 2000 PUMS data for Oregon.
#'
#' @format A data frame with 65988 rows and 17 variables (there may be a
#' different number of rows if PUMS datasets are used for different areas):
#' \describe{
#'   \item{Age0to14}{number of persons in 0 to 14 age group}
#'   \item{Age15to19}{number of persons in 15 to 19 age group}
#'   \item{Age20to29}{number of persons in 20 to 29 age group}
#'   \item{Age30to54}{number of persons in 30 to 54 age group}
#'   \item{Age55to64}{number of persons in 55 to 64 age group}
#'   \item{Age65Plus}{number of persons 65 years or older}
#'   \item{Wkr15to19}{number of workers in 15 to 19 age group}
#'   \item{Wkr20to29}{number of workers in 20 to 29 age group}
#'   \item{Wkr30to54}{number of workers in 30 to 54 age group}
#'   \item{Wkr55to64}{number of workers in 55 to 64 age group}
#'   \item{Wkr65Plus}{number of workers 65 years or older}
#'   \item{AvePerCapInc}{average per capita income of PUMA, nominal $}
#'   \item{HouseType}{housing type (SF = single family, MF = multifamily)}
#'   \item{Income}{annual household income, nominal 1999$}
#'   \item{HhSize}{number of persons in household}
#'   \item{HhType}{household type (Reg = regular household, Grp = group quarters)}
#'   \item{HhWeight}{household sample weight}
#' }
#' @source CreateEstimationDatasets.R script.
"Hh_df"
devtools::use_data(Hh_df, overwrite = TRUE)
rm(Hh_df)
```

If as in this case, one script processes the estimation data for use by several modules, it is important that the data processing script be run prior to the other scripts when the package is built. Otherwise the processed estimation data will not be available to the module packages that need it. Managing the order of package script processing is handled by the *Collate* section of the package *DESCRIPTION* file. Following is an example from the *VESimHouseholds* package:

```
Collate: 
    'CreateEstimationDatasets.R'
    'CreateHouseholds.R'
    'PredictWorkers.R'
    'PredictIncome.R'
    'AssignLifeCycle.R'
```

The best way to establish the proper collation (i.e. ordering) of script execution is to carry out model estimation through the definition and invocation of a function, and to have an *@include* statement which lists the estimation data processing script in the function documentation using [Roxygen syntax](http://r-pkgs.had.co.nz/man.html). When the package documentation is compiled, the *Collate* section of the package *DESCRIPTION* file will be filled out properly. Following is an example of function documentation containing a *@include* statement from the *CreateHouseholds.R* module script in the *VESimHouseholds* package:

```
#Define a function to estimate household size proportion parameters
#------------------------------------------------------------------
#' Calculate proportions of households by household size
#'
#' \code{calcHhAgeTypes} creates a matrix of household types and age
#' probabilities.
#'
#' This function produces a matrix of probabilities that a person in one of six
#' age groups is in one of many household types where each household type is
#' determined by the number of persons in each age category.
#'
#' @param HhData_df A dataframe of household estimation data as produced by the
#' CreateEstimationDatasets.R script.
#' @param Threshold A number between 0 and 1 identifying the percentile
#' cutoff for determining the most prevalent households.
#' @return A matrix where the rows are the household types and the columns are
#' the age categories and the values are the number of persons.
#' @include CreateEstimationDatasets.R
#' @export
```

If model estimation data are only used by a single module, then the processing code should be included in the module script. 

There are several places where model estimation datasets may be located depending on the size of the datasets, whether the datasets were preprocessed using other tools or scripts, and whether the intention of the module developer is to enable model users to customize model estimation to reflect data for the region where the model is to be applied.

For some modules, it is desirable that model parameters be estimated to reflect data for the region where the model is to be applied. This is the case for the *CreateHouseholds*, *PredictWorkers*, and *PredictIncome* modules in the *VESimHouseholds* package because household and worker age compositions and income distributions are likely to vary by region. For modules like these, the estimation data should be included in the 'inst/extdata' directory of the package in the form of CSV-formatted text files. The data files should be accompanied by text files having the same names but with a '.txt' extension rather than a '.csv' extension. The purpose of the text files is to document the corresponding data files so that model users will know how to obtain and prepare datasets for their region that can be used in model estimation. For example, the 'inst/extdata' directory of the *VESimHouseholds* package contains the following files: 'pums_households.csv', 'pums_households.txt', 'pums_persons.csv', and 'pums_persons.txt'.

If a module's estimation datasets are to be loaded from 'csv' files in the 'inst/extdata' directory, then the module code should include procedures to check those data for correctness to assure that the model parameters will be estimated correctly. The framework includes as function, *processEstimationInputs*, to assist with this task. The *processEstimationInputs* function has 3 arguments: *Inp_ls*, *FileName*, and *ModuleName*. *ModuleName* is the name of the module that is doing the processing. The sole purpose of this argument is to identify the module in any error messages that are written to the log. *FileName* is the name of the file in the 'inst/extdata' directory to be processed. *Inp_ls* is a list of data specifications that are used in checking the correctness of the data. This is explained in more detail below. The *processEstimationInputs* function returns a data frame which contains the data in the specified file, if those data have no errors. Following is an example of how the *processEstimationInputs* function is used:

```
Hh_df <- processEstimationInputs(
    Inp_ls = PumsHhInp_ls,
    FileName = "pums_households.csv",
    ModuleName = "CreateEstimationDatasets")
```

Before the estimation data may be checked, the script must describe specifications for the data. The structure of the specifications is best described using an example. The following code snippet is from the *CreateEstimationDatasets.R* script:

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
    PROHIBIT = c("NA", "< 0"),
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
- **NAME** This is the name(s) of the data column in the file. The name must be a character string (i.e. surrounded by quotation marks). If multiple columns of the file have the same specifications except for their names, they can listed as in the first item in the example. This method avoids a lot of redundant specifications. Note that the order of specifications does not need to be the same as the order of the columns in the file. Also note that it is OK if the file contains columns that are not specified, as long as it contains all of the columns that are specified. Columns that are not listed are ignored.  
- **TYPE** This the data type of the data contained in the column. Allowable types are the 4 primitive types recognized by the R language (integer, double, character, and logical), the complex types listed in section 6.4, or 'compound'. The type must be a character string.  
- **PROHIBIT** This is a character vector which identifies all prohibited data conditions. For example, the specification for the "PERSONS" data column in the example above is c("NA", "< 0"). This means that there cannot be any values that are undefined (NA) or less than 0. The symbols that may be used in a PROHIBIT specification are: NA, ==, !=, <, <=, >, >= (i.e. undefined, equal to, not equal to, less than, less than or equal to, greater than, greater than or equal to). Note that prohibited conditions must be represented as character strings. If there is more than one prohibited condition, as in the example, the conditions must be entered as an R vector using the 'c()' function, as shown in the example. The absence of prohibited conditions is represented by an empty character string (i.e. "").  
- **ISELEMENTOF** This is a vector which specifies the set of allowed values. It is used when the input values must be elements of a set of discrete values. The vector describing the set must be of the same type as is specified for the input data. Vectors of elements are entered using the 'c()' function. For example, if the entries in a column of data could only have the values 'urban' or 'rural', then the specification owould be written as c("urban", "rural"). The absence of a specification for this is represented by an empty character string.  
- **UNLIKELY** This is a vector of conditions that while not prohibited, are not likely to occur. While conditions identified in the PROHIBIT and ISELEMENTOF specifications will produce an error if they are not met (thereby stopping the calculation of parameters), the conditions identified in the UNLIKELY specification will only produce a warning message. Vectors of conditions are entered using the 'c()' function. 
- **TOTAL** This specifies a required total value for the column of data. This is useful if the data represents proportions or percentages and must add up to 1 or 100. The absence of a specification for this is represented by an empty character string.

In some instances it is impractical to include the model estimation data as files in the 'inst/extdata' directory, and not necessary for model users to provide regional model estimation data. If, for example, the source data has confidential elements, it may be necessary to preprocess the data to anonymize it before including in the package; or the source data may be too large to include as a text file in the package. In these cases, source data may be processed outside of the package and then the processed datasets included in the package as datasets in R binary files. If that is done, the binary data files should be placed in a directory named 'data-raw' in the package.

For large datasets, it is also possible to have them stored remotely and to have the module code retrieve them from remote storage. This is what is done in the *Make2001NHTSDataset.r* script in the *VE2001NHTS* package. Zip archives of the public use datasets for the 2001 National Household Travel Survey are stored in a GitHub repository (https://github.com/gregorbj/NHTS2001). There are 4 zip archive files stored in the 'data' directory of the repository: DAYPUB.zip, HHPUB.zip, PERPUB.zip, and VEHPUB.zip. Each zip archive contains a compressed 'csv' formatted text file containing the data of interest. Because the process  of downloading and unzipping some of the files takes an appreciable amount of time, the script checks whether that has already been done (by the presence of a file in the 'data-raw' directory). If it has not been done, the script calls a function which handles the downloading, unzipping, and reading of the file. It also cleans up temporary files created when the zip archive was downloaded and unzipped. 

If a module is to download datafiles from remote storage, the module developer will need to write R code to handle the requisite tasks. The framework does not build in any functionality to do this. The coding is not complicated as the following example of commented snippets of code from the *Make2001NHTSDataset.r* script illustrate. The first section of code identifies the address of the data repository. The second section defines a function which handles downloading, unzipping, and reading a dataset stored in the repository, and cleaning up temporary files created in the process. The third section applies the handler function to download NHTS public use household data (HHPUB), selects relevant data fields, and saves those data as an R binary file to the 'data-raw' directory. If the R binary file already exists, the data are not downloaded from the repository but are loaded from the saved file instead.

```
#Identify the code repository. Note that in order to access data
#files from a GitHub repository, the beginning of the address must 
#be 'raw.githubusercontent.com' not 'github.com'
Nhts2001Repo <-
  "https://raw.githubusercontent.com/gregorbj/NHTS2001/master/data"
  
#Define a function to handle retrieving a zipped dataset from the
#repository, unzipping it, reading the unzipped file, and cleaning
#up temporary files
getZipDatasetFromRepo <- function(Repo, DatasetName) {
  ZipArchiveFileName <- paste0(DatasetName, ".zip")
  CsvFileName <- paste0(DatasetName, ".csv")
  download.file(file.path(Repo, ZipArchiveFileName), ZipArchiveFileName)
  Data_df <- read.csv(unzip(ZipArchiveFileName), as.is = TRUE)
  file.remove(ZipArchiveFileName, CsvFileName)
  Data_df
}

#Download NHTS 2001 public use household data from repository and 
#process if it has not already been done
if (!file.exists("data-raw/Hh_df.rda")) {
  Hh_df <- getZipDatasetFromRepo(Nhts2001Repo, "HHPUB")
  Keep_ <- c("HOUSEID", "AGE_P1", "AGE_P2", "AGE_P3", "AGE_P4", "AGE_P5", "AGE_P6",
             "AGE_P7", "AGE_P8", "AGE_P9", "AGE_P10", "AGE_P11", "AGE_P12", "AGE_P13",
             "AGE_P14", "CENSUS_D", "CENSUS_R", "DRVRCNT", "EXPFLHHN", "EXPFLLHH",
             "FLGFINCM", "HBHRESDN", "HBHUR", "HBPPOPDN", "HHC_MSA", "HHFAMINC",
             "HHINCTTL", "HHNUMBIK", "HHR_AGE", "HHR_DRVR", "HHR_RACE", "HHR_SEX",
             "HHSIZE", "HHVEHCNT", "HOMETYPE", "HTEEMPDN", "HTHRESDN", "HTHUR",
             "HTPPOPDN", "LIF_CYC", "MSACAT", "MSASIZE", "RAIL", "RATIO16V",
             "URBAN", "URBRUR", "WRKCOUNT", "CNTTDHH")
  Hh_df <- Hh_df[, Keep_]
  save(Hh_df, file = "data-raw/Hh_df.rda", compress = TRUE)
} else {
  load("data-raw/Hh_df.rda")
}
```

##### 8.1.2 Module Specifications

The module specifications section of the module script provides specifications that are used by the framework in a number of ways. The specifications:  
- Identify the level of geography that the model is to be run at;
- Describe all the data to be loaded from input files and enable unit conversions;
- Describe all the data that the module needs from the datastore in order to run;
- Describe all the data that the module produces that needs to be saved to the datastore;
- Identify other modules the module needs to call in order to do its calculations;
- Allow the framework to check and load all input files before any modules are run;
- Allow the framework to check that modules are compatible with one another in terms of the data that they produce and consume;
- Allow the sequence of model steps (module calls) to be simulated to check whether each module will have the data it needs when it is run; and,
- Provide detailed documentation about all data that is produced by a model run.  

These specifications are declared in a list that is similar to the list for specifying model estimation data described in Section 8.1.1.1. A full example is shown in Appendix E. Following is a skeleton of a module specifications list for a module whose name is *MyModule*. The name of the specifications list must be the concatenation of the module name and *Specifications*, so in this example the name is *MyModuleSpecifications*. Note that the functions *items* and *item* are aliases for the R *list* function. Their purpose is to make the specifications easier to read.  
```
MyModuleSpecifications <- list(
  RunBy = ...,
  NewInpTable = items(
    item(
      ...
    ),
    item(
      ...
    )
  ),
  NewSetTable = items(
    item(
      ...
    ),
    item(
      ...
    )
  ),
  Inp = items(
    item(
      ...
    ),
    item(
      ...
    )
  ),
  Get = items(
     item(
      ...
    ),
    item(
      ...
    )
  ),
  Set = items(
    item(
      ...
    ),
    item(
      ...
    )
  ),
  Call = items(
     item(
      ...
    ),
    item(
      ...
    )
  )
)
```  
Following are detailed descriptions and examples of each component of the specifications list.  

The **RunBy** component specifies the level of geography that the model is to be run at. For example, the congestion submodel in the GreenSTEP and RSPM models runs at the Marea level. This specification is used by the software framework to determine how to index data that is read from the datastore and data that is written to the datastore. Acceptable values are "Region", "Azone", "Bzone", and "Marea". The *RunBy* specification looks like the following example:

```
RunBy = "Marea",
```

The **NewInpTable** and **NewSetTable** components specify any new tables that need to be created in the datastore to accommodate input data or data produced by a module respectively. The following specifications are required for each new table that is to be created.  
- TABLE: the name of the table that is to be created; and,
- GROUP: the type of group the table is to be put into. There are 3 group types: *Global*, *BaseYear*, and *Year*. If *Global*, the table is created in the global group of the datastore. If *BaseYear* the table is created in the year group for the base year and only in that year group. For example, if the model base year is 2010, the table will be created in the *2010* group. If *Year*, the table will be created in the group for every model run year. For example, if the run years are 2010 and 2040, the table will be created in both the *2010* group and the *2040* group.  
Following is an example of a *NewSetTable* specification for creating a Vehicle table in each model run year group.  
```
NewSetTable = items(
  item(
    TABLE = "Vehicle",
    GROUP = "Year"
  )
),
```
  
The **Inp** component specifies all model inputs that the module requires. Each item in the list describes one or more data fields in an input file. Each item must have the following attributes (except for the OPTIONAL attribute):  
-  NAME: the names of one or more data fields in the input file, and the names used for the datasets when they are loaded into the datastore. The names must match corresponding column names with the exception that column names in input files may contain *year* and *multiplier* modifiers as described in Section 6.4.;  
-  FILE: the name of the file that contains the data fields;  
-  TABLE: the name of the datastore table the datasets will be put into;  
-  GROUP: the type of group where the table is located in the datastore (i.e. Global, Year, BaseYear);
-  TYPE: the data type (e.g. double, distance, compound);  
-  UNITS: the measurement units for the data;  
-  NAVALUE: the value used to represent NA (i.e. missing value) in the datastore;  
-  SIZE: the maximum number of characters for character data (or 0 for numeric data);  
-  PROHIBIT: data values that are prohibited or "" if not applicable (see Section 8.1.1.1 for explanation);  
-  ISELEMENTOF: allowed categorical data values or "" if not applicable (see Section 8.1.1.1 for explanation);  
-  UNLIKELY: data conditions that are unlikely or "" if not applicable (see Section 8.1.1.1 for explanation);  
-  TOTAL: the total for all values (e.g. 1) or "" if not applicable;  
-  DESCRIPTION: descriptions of the data corresponding to the names in the NAME attribute; and,  
-  OPTIONAL: optional specification which identifies whether dataset is optional (see section 8.1.2.1)  
Following is an example of the *Inp* component for the *PredictHousingSpecifications* in the *VELandUse* package. The *Inp* specifications include two items. Each item lists one or more field names (i.e. column names in the input file) in the NAME attribute. Multiple field names can be listed in an item if all the other attributes except for DESCRIPTION are the same for all the fields. The descriptions in the DESCRIPTION attribute must correspond in order to the dataset names in the NAME attribute in order for them to be stored correctly in the datastore. The values that may be entered for the TYPE and UNITS attributes are described in Section 6.3. It should be noted that the UNITS attribute must not include 'year' (for 'currency' type) or 'multiplier' information. That information is part of the input file field names instead (where relevant). This is explained in more detail in Section 6.4. The framework uses the information in the *Inp* to read the input files, check whether the data are correct, and save the data to the correct location in the datastore.     
```
Inp = items(
  item(
    NAME =
      items(
        "SFDU",
        "MFDU",
        "GQDU"),
    FILE = "bzone_dwelling_units.csv",
    TABLE = "Bzone",
    GROUP = "Year",
    TYPE = "integer",
    UNITS = "DU",
    NAVALUE = -1,
    SIZE = 0,
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = "",
    DESCRIPTION =
      items(
        "Number of single family dwelling units (PUMS codes 01 - 03) in zone",
        "Number of multi-family dwelling units (PUMS codes 04 - 09) in zone",
        "Number of qroup quarters population accommodations in zone"
      )
  ),
  item(
    NAME = items(
      "HhPropIncQ1",
      "HhPropIncQ2",
      "HhPropIncQ3",
      "HhPropIncQ4"),
    FILE = "bzone_hh_inc_qrtl_prop.csv",
    TABLE = "Bzone",
    GROUP = "Year",
    TYPE = "double",
    UNITS = "NA",
    NAVALUE = -1,
    SIZE = 0,
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = "",
    DESCRIPTION =
      items(
        "Proportion of Bzone households (non-group quarters) in 1st quartile of Azone household income",
        "Proportion of Bzone households (non-group quarters) in 2nd quartile of Azone household income",
        "Proportion of Bzone households (non-group quarters) in 3rd quartile of Azone household income",
        "Proportion of Bzone households (non-group quarters) in 4th quartile of Azone household income"
      )
  )
),
```
  
The **Get** component contains one or more items that identify data that the module need to have retrieved from the datastore. Note that the *Get* component must identify all datasets the module requires (other than those that are included in the package), including those specified in the *Inp* component. The datasets identified in the *Inp* component are not automatically made available to the module. Each item in the *Get* component specifies attributes for one or more related datasets as follows:  
-  NAME: the names of one or more datasets to be loaded;  
-  TABLE: the name of the table that the datasets are located in;  
-  GROUP: the type of group where the table is located in the datastore (i.e. Global, Year, BaseYear);  
-  TYPE: the data type (e.g. double, distance, compound);  
-  UNITS: the measurement units for the data;  
-  PROHIBIT: data values that are prohibited or "" if not applicable (see Section 8.1.1.1 for explanation);  
-  ISELEMENTOF: allowed categorical data values or "" if not applicable (see Section 8.1.1.1 for explanation); and,
-  OPTIONAL: optional specification which identifies whether dataset is optional (see section 8.1.2.1)  
Unlike the 'Inp' specifications, the 'Get' specifications for UNITS must include 'year' information for 'currency' types. This is necessary in order for the framework to convert the currency data being requested from the datastore to the year denomination that the module needs. The UNITS attribute may also include a multiplier specification if the module needs the values to be modified in that way. For example, if the module needs VMT in thousands of miles, the UNITS specification would be 'MI.1e3'. Section 6.3 provides more information on how 'year' and 'multiplier' options are added to a UNITS specification. Following is an example of the *Get* component of the *AssignRoadMilesSpecifications* in the *VETransportSupply* package.   
```
Get = items(
  item(
    NAME = "Marea",
    TABLE = "Marea",
    GROUP = "Year",
    TYPE = "character",
    UNITS = "ID",
    PROHIBIT = "",
    ISELEMENTOF = ""
  ),
  item(
    NAME =
      items(
        "FwyLaneMi",
        "ArtLaneMi"),
    TABLE = "Marea",
    GROUP = "Year",
    TYPE = "distance",
    UNITS = "MI",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = ""
  ),
  item(
    NAME = "Marea",
    TABLE = "Bzone",
    GROUP = "Year",
    TYPE = "character",
    UNITS = "ID",
    PROHIBIT = "",
    ISELEMENTOF = ""
  ),
  item(
    NAME = "UrbanPop",
    TABLE = "Bzone",
    GROUP = "Year",
    TYPE = "people",
    UNITS = "PRSN",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = ""
  )
),
```  

The **Set** component contains one or more items describing datasets to be saved in the datastore. Each item in the *Set* component specifies attributes for one or more related datasets as follows:  
-  NAME: the names of one or more datasets to be saved;  
-  TABLE: the name of the table that the datasets are to be saved in;  
-  GROUP: the type of group where the table is located in the datastore (i.e. Global, Year, BaseYear);  
-  TYPE: the data type (e.g. double, distance, compound);  
-  UNITS: the measurement units for the data;  
-  NAVALUE: the value used to represent NA in the datastore;  
-  PROHIBIT: data values that are prohibited or "" if not applicable (see Section 8.1.1.1 for explanation);  
-  ISELEMENTOF: allowed categorical data values or "" if not applicable (see Section 8.1.1.1 for explanation);  
-  SIZE: the maximum number of characters for character data (or 0 for numeric data); and,
-  DESCRIPTION: descriptions of the data corresponding to the names in the NAME attribute  
The requirements for the UNITS attribute are the same as described above for *Get* component items. Following is an example of the *Set* component of the *AssignRoadMilesSpecifications* in the *VETransportSupply* package.   
```
Set = items(
  item(
    NAME = "FwyLaneMiPC",
    TABLE = "Marea",
    GROUP = "Year",
    TYPE = "compound",
    UNITS = "MI/PRSN",
    NAVALUE = -1,
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    SIZE = 0,
    DESCRIPTION = "Ratio of urbanized area freeway and expressway lane-miles to urbanized area population"
  )
)
```  
It should be noted that it may not be possible to prespecify the SIZE attribute for a dataset. For example, if a unique household ID is assigned, the SIZE attribute will depend on the number of households and so must be calculated when the module is run. In such a circumstance, the SIZE attribute is omitted from the item and the module function must calculate it and include the calculated value as an attribute of the output dataset. The following code snippet from the *CreateHouseholds* module code in the *VESimHouseholds* package shows how this is done. In this example, the list of data that the module function returns is named *Out_ls*. The household ID (*HhId*) dataset is in the *Household* table of the *Year* group. The R *attributes* function is called to set the SIZE attribute of the *HhId* dataset equal to the maximum of the number of characters in each of the entries in the dataset.  
```  
attributes(Out_ls$Year$Household$HhId)$SIZE <- max(nchar(Out_ls$Year$Household$HhId))  
```  

The last component in the the module specifications list is the **Call** component. This is an optional component of the module specifications and is included if the module calls any other modules or if the module may be called by other modules. Following are *Call* component examples. The first is an example for a module that may be called. The second is an example for a module which calls another module. Section 8.1.2.2 explains module calling in detail.  
```
#Call component for a module that may be called
Call = TRUE

#Call component for a module that calls another module
Call = items(
  CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt"
)
```

###### 8.1.2.1 OPTIONAL Attribute  
Module developers can use the OPTIONAL attribute to identify optional inputs or data to be retrieved from the datastore. This enables modules to be written to respond to optional inputs. For example, in the GreenSTEP and RSPM models, users may provide inputs on the average carbon intensity of fuels (grams CO2e per megajoule) by model run year. This allows users to model a scenario where state regulations require the average carbon intensity of fuels to be reduced over time. If the user supplies those data, the models calculate carbon emissions using those inputs. If not, the model calculates emissions using data on the carbon intensities of different fuel types and the mix of those fuel types.  

If the OPTIONAL attribute for an item is missing, then the item is not optional. If the OPTIONAL attribute is not missing but is set equal to *FALSE* then the item is not optional as well. Only when the OPTIONAL attribute is present and set equal to *TRUE* does the framework regard the item as optional (`OPTIONAL = TRUE`).  

If an input (*Inp*) item is identified as optional, the framework checks whether the identified input file is present. If the file is present, then the framework will process the data and load it into the datastore. Otherwise the item is ignored. Note that optional inputs can't be combined with non-optional inputs in the same file. This will cause an error. Also not that since the framework does not automatically supply inputs to the module, there must be optional *Get* items corresponding to the optional *Inp* items. When the framework sees an optional *Get* item, it checks the datastore to see whether the optional dataset(s) are present. If so, it retrieves them.  

###### 8.1.2.2 CALL Specification

If same calculation code needs to be executed a number of times, it is best to define a function to encapsulate the code and then call the function whenever the calculation needs to be carried out. This reduces errors and code maintenance hassles. Likewise, module code duplication is reduced in the VisionEval model system by allowing modules to call other modules for their calculation services. For example, the *BudgetHouseholdDvmt* module in the *VETravelPerformance* package calls the *CalculateAltModeTrips* module in the *VEHouseholdTravel* package to recalculate trips by alternate modes (walk, bike, transit) to reflect budget-adjusted household DVMT. Calling a module is more involved than just calling the function that carries out the module's calculations because the module function will not work unless it is supplied with the datasets identified in its *Get* specifications. Of course the calling module could include those specifications in its own specifications, but that would create a significant potential for coding errors and maintenance problems (e.g. if the called module is module is modified at a later time). For this reason the software design includes functionality for calling modules in a simple manner which leaves the data management details to the framework behind the scenes.  

A module's call status is specified in the *Call* component of the module specifications. There are 3 possibilities for a module's call status. First, a module may be called by other modules. In this case the specification is `Call = TRUE`. Second, the module may call other modules. In this case the call specification is a list that identifies each of the modules that are called, assigning a reference to the module to an alias (i.e. *alias = module*) as shown in the following example:  
```
Call = items(
  CalcDvmt = "CalculateHouseholdDvmt",
  ReduceDvmt = "ApplyDvmtReductions",
  CalcVehTrips = "CalculateVehicleTrips",
  CalcAltTrips = "CalculateAltModeTrips"
)
```
The *alias* is the name that the called module will be referred to by the calling module code. The *module* is the name of the called module. The VisionEval framework software identifies which package the module resides in from the *ModulesByPackage_df* table in the *ModelState_ls* list. It is also possible to hard code the package name in the call definition. For example the *CalcDvmt* alias could be assign to `VEHouseholdTravel::CalculateHouseholdDvmt`. This is discouraged, however, because doing so limits the ability to maintain different versions of packages that have module modifications.  
```
Call = items(
  CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt"
)
```  
The third possibility is that a module may not be called and calls no other modules. In that case a *Call* component is not included in the module specifications.

There are some important restrictions to module calling. First, a module that may be called cannot call another module. If this restriction did not exist, there could be deeply nested module calls which could make debugging and understanding how a model works very difficult. Second, a module that may be called cannot have any inputs (i.e. *Inp* component). The reason for this restriction is that the function of called modules is to provide calculation services and those are hidden from model users. Unless a called module was also called directly in the model run script, there would be no way model user would know to supply input files without diving into the details about the module doing the calling. 

The framework does the following when a module is run which calls one or more other modules. For each of the modules that are called, the framework:  
1) Reads the 'Get' specifications for the called module, gets the datasets from the datastore, puts them in the standard list structure, and adds to the list that will be returned to the calling module as a component whose name is the assigned alias. In the example above, the retrieved datasets would be in a component named "CalcDvmt".  
2) Creates a list which holds the values of the called module functions. Each called module function is a component of the list whose name is the assigned alias. In the example above, this function list would have one component named "CalcDvmt" which contains the value of the CalculateHouseholdDVMT function.  
3) The framework passes these two lists to the calling module when it is run. Thus the calling module function must be written to accept two arguments rather than one.  

The calling module code invokes the called module by calling it from the function list that the framework passes it and passing to it the data it needs from the data list. Following from the example above, if the data list is called 'L' and the function list is called 'M', then the *CalculateHouseholdDVMT* module function would be called in the *AssignHhVehiclePowertrain* module as follows:  
```
M$CalcDvmt(L$CalcDvmt)
```

##### 8.1.3 Module Function

The **function definitions** section of the module script is used to define all functions that will be used to implement the module. One of these functions is the main function that is called by the software framework to run the module. This function must have the same name as the module name. For example, the main function of the *CreateHouseholds* module is named *CreateHouseholds* as well. This function must be written to accept one argument, a list, which by convention is named L if the module calls no other modules, and two arguments (as explained in the previous section) if the module calls other modules. This list contains all of the datasets identified in the *Get* component of the module data specifications. The structure of this list is described in Section 7. The main function returns a list which contains all of the datasets identified in the *Set* component of the module data specifications and structured as described in Section 7. The software framework includes a function, *initDataList*, to initialize an outputs list having the proper structure with *Global*, *Year*, and *BaseYear* components. The module code will fill in each component with components for each of the specified tables and datasets within those tables. Following is a simple example from the *AssignTransitService* module in the *VETransportSupply* package. First, here are the module's *Set* items to provide context for the module code:  
```
Set = items(
  item(
    NAME = "TranRevMiPC",
    TABLE = "Marea",
    GROUP = "Year",
    TYPE = "compound",
    UNITS = "MI/PRSN",
    NAVALUE = -1,
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    SIZE = 0,
    DESCRIPTION = "Ratio of bus-equivalent revenue-miles (i.e. revenue-miles at the same productivity - passenger miles per revenue mile - as standard bus) to urbanized area population"
  )
)
```
The *AssignTransitService* function returns one dataset called *TranRevMiPc*. This dataset will be placed in the *Marea* table in the *Year* group (i.e. in the group for each model run year). Following is the function definition:  
```
AssignTransitService <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of modes
  Md <- as.character(BusEquivalents_df$Mode)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea

  #Calculate bus equivalent revenue miles
  #--------------------------------------
  #Make table of revenue miles by Marea
  RevMi_df <- data.frame(L$Year$Marea[paste0(Md, "RevMi")])
  colnames(RevMi_df) <- Md
  rownames(RevMi_df) <- Ma
  RevMi_MaMd <- as.matrix(RevMi_df)
  #Calculate the bus equivalent revenue miles
  BusEq_Md <- BusEquivalents_df$BusEquivalents
  names(BusEq_Md) <- Md
  BusEqRevMi_Ma <-
    rowSums(sweep(RevMi_MaMd, 2, BusEq_Md, "*"))[Ma]

  #Calculate the bus equivalent revenue miles per capita
  #-----------------------------------------------------
  #Calculate population in the urbanized area
  UrbanPop_Ma <-
    tapply(L$Year$Bzone$UrbanPop, L$Year$Bzone$Marea, sum)[Ma]
  #Calculate Marea bus equivalent revenue miles per capita
  TranRevMiPC_Ma <- BusEqRevMi_Ma / UrbanPop_Ma

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(TranRevMiPC = TranRevMiPC_Ma)
  #Return the outputs list
  Out_ls
}
```

A module should include procedures as necessary to check for errors in output datasets. In most cases this won't be necessary if the module passes tests during development because the framework checks that all datasets passed to the module meet the module's specifications. However there may be conditions where some combinations of acceptable inputs produce unacceptable outputs. In such cases, the module code should check for unacceptable outputs and if found, report those to the framework for reporting to the model user and stopping the model run. The module should not stop the model run. Instead it composes a descriptive error message and adds it to an *Errors* component of the module outputs list. If there is more than one error, the *Errors* component will be a vector of error messages. The framework writes the error message(s) to the model run log and stops model execution.  

Warnings are handled in a similar way. If the module code is checks for warning conditions (i.e. model execution should not be stopped but users should be about the condition) and finds any, it composes a warning message that is added to a *Warnings* component of the module outputs list. The framework writes warnings messages to the model run log.  

The functionality for processing module errors and warnings is used primarily by *Initialize* modules as explained in Section 8.1.5.  

##### 8.1.4 Module Documentation

It is recommended that module documentation be included at the top of the module script file if possible to make it easier to review and analyze the module. A standardized approach has been developed to do this that produces documentation in [markdown](https://en.wikipedia.org/wiki/Markdown) format that can be viewed as a web page or converted to other formats for printing. At the end of the module script the *documentModule* function like this `documentModule("PredictIncome")`. The *documentModule* parses the module script, extracts the documentation block at the head of the file and inserts any text, tables, or figures that are saved by the script and inserted into the documentation using special *tags* as explained below. In addition, the *documentModule* function reads the module specifications and creates formatted tables showing module inputs, datasets used, and datasets produced. The documentation file(s) are then saved to a *model_docs* directory in the *inst/extdata* directory which is in turn a directory in the installed package. The *documentModule* function is called at the end of the script because the rest of the script must be executed to produce the datasets that are inserted into the documentation file. Following is an example of what a documentation block looks like.

```
#<doc>
## PredictIncome Module
#### September 6, 2018
#
#This module predicts the income for each simulated household given the number of workers in each age group and the average per capita income for the Azone where the household resides.
#
### Model Parameter Estimation
#Household income models are estimated for *regular* households and for *group quarters* households.
#
#The household income models are estimated using Census public use microsample (PUMS) data that are compiled into a R dataset (HhData_df) by the 'CreateEstimationDatasets.R' script when the VESimHouseholds package is built. The data that are supplied with the VESimHouseholds package downloaded from the VisionEval repository may be used, but it is preferrable to use data for the region being modeled. How this is done is explained in the documentation for the *CreateEstimationDatasets.R* script.
#
#The household income models are linear regression models in which the dependent variable is a power transformation of income. Power transformation is needed in order to normalize the income data distribution which has a long right-hand tail. The power transform is found which minimizes the skewness of the income distribution. The power transform for *regular* households is:
#
#<txt:HHIncModel_ls$Pow>
#
#The power transform for *group quarters* households is:
#
#<txt:GQIncModel_ls$Pow>
#
#The independent variables for the linear models are power transformed per capita income for the area, the number of workers in each of 4 worker age groups (15-19, 20-29, 30-54, 55-64), and the number of persons in the 65+ age group. In addition, power-transformed per capita income is interacted with each of the 4 worker groups and 65+ age group variable. The summary statistics for the *regular* household model are as follows:
#
#<txt:HHIncModel_ls$Summary>
#
#The summary statistics for the *group quarters* household model are as follows:
#
#<txt:GQIncModel_ls$Summary>
#
#An additional step must be carried out in order to predict household income. Because the linear model does not account for all of the observed variance, and because income is power distribution, the average of the predicted per capita income is less than the average per capita income of the population. To compensate, random variation needs to be added to each household prediction of power-transformed income by randomly selecting from a normal distribution that is centered on the value predicted by the linear model and has a standard deviation that is calculated so as the resulting average per capita income of households match the input value. A binary search process is used to find the suitable standard deviation. Following is the comparison of mean values for the observed *regular* household income for the estimation dataset and the corresponding predicted values for the estimation dataset.
#
#<tab:HHIncModel_ls$MeanCompare>
#
#The following figure compares the distributions of the observed and predicted incomes of *regular* households.
#
#<fig:reg-hh-inc_obs-vs-est_distributions.png>
#
#Following is the comparison of mean values for the observed *group quarters* household income for the estimation dataset and the corresponding predicted values for the estimation dataset.
#
#<tab:GQIncModel_ls$MeanCompare>
#
#The following figure compares the distributions of the observed and predicted incomes of *groups quarters* households.
#
#<fig:gq-hh-inc_obs-vs-est_distributions.png>
#
### How the Module Works
#This module runs at the Azone level. Azone household average per capita income and group quarters average per capita income are user inputs to the model. The other model inputs are in the datastore, having been created by the CreateHouseholds and PredictWorkers modules. Household income is predicted separately for *regular* and *group quarters* households. Per capita income is transformed using the estimated power transform, the model dependent variables are calculated, and the linear model is applied. Random variation is applied so that the per capita mean income for the predicted household income matches the input value.
#

#</doc>

```

There are several things to note about this example. The first is that all text in the block is commented out (preceded by #). Since R doesn't support block comments, each line must be commented. It may not look this way in the example because of word wrapping, but every line is commented. Second, the start and end of the documentation block are denoted by matching `<doc>` and `</doc>` tags. The parser uses these to extract the documentation from the script. After the document has been extracted, the leading comments are stripped off, resulting in markdown-formatted text. The other comment (#) symbols in the text are actually markdown formatting to identify headings of different levels. Documentation can include any standard markdown formatting such as emphasis, links, and tables. In addition, the documentation can include special tags as shown in the example. Three types of tags are available:

* `<txt:xxxx>` inserts a block of text that is contained in the referenced object. For example the `<txt:GQIncModel_ls$Summary>` tag in the example will insert summary statistics for the group quarters income model.

* `<tab:xxxx>` inserts data that can be presented in table for such as a data frame. For example the `<tab:HHIncModel_ls$MeanCompare>` tag in the example will insert a table which compares observed and estimated mean values.

* `<fig:xxxx>` creates a markdown reference to an image file so that it will be show in the proper place when the markdown is displayed in a browser or converted to another document form. For example the `<fig:reg-hh-inc_obs-vs-est_distributions.png>` tag in the example will insert a figure which compares observed and estimated income distributions when the markdown is displayed.

It is helpful to include test code in the module script to aid with module development. The framework includes a *testModule* function to assist with module testing. This function is described in detail in Section 9.2.1. Testing requires having sample input files containing datasets specified by the modules *Inp* specifications. These are stored in the 'inputs' directory of the 'tests' directory. The 'tests' directory also must contain a 'defs' directory which contains all the required model definitions files (see Section 6.1). Finally, the 'tests' directory must contain a datastore of the type specified in the 'run_parameters.json' file, which contains all of the datasets specified in the modules *Get* specifications. In the first stage of module testing, the module specifications are checked, all input files are checked, the presence of all required data is checked, and an input list (L) is returned for use in module development. For this test, the *DoRun* argument of the *testModule* function needs to be set to *FALSE*. After the module code has been written, the module is tested again to check whether the module code is working correctly and that it returns results that are consistent with the *Set* specifications for the module. For this test, the *DoRun* argument of the *testModule* function must be *TRUE*. After the module has been tested, it is important to comment out all the testing code in the script because it must not be run when the package is built. Following is an example of testing code in a module that has been commented out.  


##### 8.1.5 Initialize Module
Although the framework performs several checks on module input data based on the module specifications, there will be times when additional checks of inputs will be necessary and possibly transformations as well. For example, several datasets could have proportions data that must add up to 1 across the datasets. For example, 4 input datasets for the *PredictHousing* module of the *VELandUse** package give the proportions of households in each Bzone that are in each of 4 income quartiles for the Azone that the Bzones are located in. These inputs should be checked to assure that the sum of all quartile proportions for each Bzone adds up to one. If any sums are not close to 1, then the model user needs to be alerted to the fact so that they can correct the input file. If all the sums are close to 1 but some are not exactly 1 (due to rounding errors in preparing inputs), the inputs should be automatically adjusted to equal 1 before they are saved in the datastore. If a module developer needs to establish more complex checks and transformations like this, they do so in a special module that they name *Initialize*. 

In the *Initialize* module, the module specifications identify all of the input datasets that need to be checked. This is done in same manner as described in Section 8.1.2. The module specifications will not have *Get* or *Set* components since the only purpose of the *Initialize* module is to process inputs. There can only be one *Initialize* module in a package and so all inputs that need additional checking, regardless of which module in the package will use them, need to be processed in the *Initialize* module. Datasets that are listed in the *Inp* specifications of the *Initialize* module must not be included in the *Inp* specifications of any other module in the package.   

When a model is intialized by the *initializeModel* function in the *run_model.R* script (Section 5 and Appendix A), each of the module packages that will be run by the script is checked for the presence of an *Initialize* module. Any that are found are added to a list of modules that require input processing. When the *initializeModel* function processes the inputs for an *Initialize* module it does so in two steps. In the first step, it performs the standard input processing that is done for all modules (input files are read and datasets are checked for completeness and correctness). The output of this checking process is a standard outputs list with *Global*, *BaseYear*, and *Year* components. In the second step, the framework calls the *Initialize* module function and passes it the outputs list from the first step. The *Initialize* module does whatever enhanced data checking and transformation is necessary and returns an outputs list having the same structure as the inputs list with the addition of *Errors* and *Warnings* components (see Section 8.1.3). Several of the VisionEval packages include *Initialize* modules and can be used as examples.

#### 8.2. The inst/extdata Directory
By convention, the 'inst/extdata' directory is the standard place to put external (raw) data files as opposed to R datasets which are placed in the 'data' directory. This is where most model estimation data is kept. Section 8.1.1.1 provides a detailed explanation. The directory should include a subdirectory named 'sources' to hold reports or other external documentation if needed.

#### 8.3. The tests Directory
The 'tests' directory contains R scripts and the results of module tests. The *scripts* directory contains all the scripts used to carry out module tests. The directory also contains subdirectories for each of the model types the module is to be tested with (e.g VE-RSPM, VE-State, VE-RPAT). Two approaches are available for handing module data that includes input files the module uses, all the *defs* files, and a datastore which contains all the datasets used by the module aside from those in the input files. These data can be included in the package or they may be kept in a central repository. If they are included in the package, they must be placed in the directory for the corresponding model. This is necessary to avoid conflicts in the test data for different models. The scripts directory includes a testing script which runs the tests on all modules in a package for a particular module. For example, the script for testing modules in a VE-State application is named *vestate_test.R*. The scripts directory also includes a *test.R* script which calls the individual model test scripts for automated package testing. If the centralized data testing approach is used, a *test_functions.R* script needs to be included. This includes functions needed to support the centralized test data approach. The test process is still not finalized. In the future this functionality will be included in the framework software. Following is an example of a test script using the central data approach:

```
#vestate_test.R
#--------------

#Load packages and test functions
library(visioneval)
library(filesstrings)
source("tests/scripts/test_functions.R")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-State",
  DatastoreName = "Datastore.tar",
  LoadDatastore = FALSE,
  TestDocsDir = "vestate",
  ClearLogs = TRUE,
  # SaveDatastore = TRUE
  SaveDatastore = FALSE
)

#Define the module tests
Tests_ls <- list(
  list(ModuleName = "CreateHouseholds", LoadDatastore = FALSE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "PredictWorkers", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignLifeCycle", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "PredictIncome", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)

```

Section 9.2.1 provides more information on using the *testModule* function.

### 9. Software Framework 
The software framework for the VisionEval model system is implemented by a set of functions contained in the **visioneval** package. These functions are classified in four groups: user, developer, control, and datastore. Model *user* functions are those used to write scripts to run VisionEval models. Section 9.1 describes how these are used. Appendix G contains full documentation of model user functions. The package contains contains standard documentation for all of the functions. Module *developer* functions are those that module developers may call in their module code or that otherwise aid in module developing and testing. Section 9.2 describes the most important module development functions and Appendix H includes full documentation of all the functions. Most of the functions in the VisionEval framework are functions that *control* the initialization of a VisionEval model run and the execution of VisionEval modules. These functions are internal to the VisionEval software framework and are not to be used by model users or module developers. Section 9.3 provides an overview of these functions and Appendix I includes full function documentation. The remaining functions are functions which directly interact with the model datastore. Section 9.4 provides an overview of these functions and Appendix J provides full documentation.

Additional documentation which shows the calling relationships between functions is available in a [interactive visualization](https://gregorbj.github.io/VisionEval/website/visioneval_functions.html). This visualization shows the names of the functions as nodes in a network graph with arrows connecting the nodes showing the functions that are called by each function (arrows point from the calling function to the called function). The nodes are colored-coded to indicate the function groups: blue indicates model *user* functions, green indicates module *developer* functions, yellow indicates framework *control* functions, and red indicates *datastore* interaction functions. Clicking on a function in the visualization highlights the function and all the arrows connected to it. It also provides summary information about the function including a description of what it does, descriptions of all the function arguments, and a description of the function's return value.

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
- **ModuleName** A string identifying the module name.  
- **ParamDir** A string identifying the location of the directory where the run parameters, model parameters, and geography definition files are located. The default value is defs. This directory should be located in the tests directory.
- **RunParamFile** A string identifying the name of the run parameters file. The default value is run_parameters.json.
- **GeoFile** A string identifying the name of the file which contains geography definitions.
- **ModelParamFile** A string identifying the name of the file which contains model parameters. The default value is model_parameters.json.
- **LoadDatastore** A logical value identifying whether to load an existing datastore. If TRUE, it loads the datastore whose name is identified in the run_parameters.json file. If FALSE it initializes a new datastore.
- **SaveDatastore** A logical value identifying whether the module outputs will be written to the datastore. If TRUE the module outputs are written to the datastore. If FALSE the outputs are not written to the datastore.
- **DoRun** A logical value identifying whether the module should be run. If FALSE, the function will initialize a datastore, check specifications, and load inputs but will not run the module. It will return the list of module inputs. This is described in more detail below. If TRUE, the module will be run and results will be checked for consistency with the module's 'Set' specifications.
- **RunFor** A string identifying whether to run the module for all years (AllYears), only the base year (BaseYear), or for all years except the base year (NotBaseYear)
- **StopOnErr** A logical value indicating whether model execution should be stopped if the module transmits one or more error messages or whether execution should continue with the next module. The default value is TRUE. This is how error handling will ordinarily proceed during a model run. A value of FALSE is used when 'Initialize' modules in packages are run during model initialization. These 'Initialize' modules are used to check and preprocess inputs. For this purpose, the module will identify any errors in the input data, the 'initializeModel' function will collate all the data errors and print them to the log.
- **RequiredPackages** A string vector identifying any other VisionEval packages that the module calls modules from or access datasets from.
- **TestGeoName** A string identifying the name of a geographic area to return the data for. If the DoRun argument is FALSE, the function returns a list containing all the data the module requests. It will only return the data for one geographic area in the set identified in the RunBy specification. For example if the RunBy specification is Marea, the function will return the list of data for only one Marea. This argument can be used to specify which geographic area the data is to be returned for. Otherwise the data for the first area identified in the datastore is returned.

If the DoRun argument is TRUE, the module will be run and there will be no return value. The module will run for all geographic areas and the outputs will be checked for consistency with the module's *Set* specifications. If that argument is FALSE, the return value of the function is a list containing the data identified in the module's *Get* specifications. That setting is useful for module development in order to create the all the data needed to assist with module programming. It is used in conjunction with the 'getFromDatastore' function to create the dataset that will be provided by the framework. The example module script in Appendix E shows how this aspect of the 'testModule' function can be used by module developers to make the development of their code easier. The function also writes out messages to the console and to the log as the testing proceeds. These messages include the time when each test starts and when it ends. When a key test fails, requiring a fix before other tests can be run, execution stops and an error message is written to the console. Detailed error messages are also written to the log.

##### 9.2.2. Functions to Assist Specification Writing
As was explained above in Sections 4.1 and 8.1, the VisionEval model system uses data specifications to help assure that modules can work properly with one another. The data specifications are saved as attributes for each dataset that are saved to the datastore by a module. The specifications are checked for consistency for each dataset a module requests to be retrieved from the datastore. A couple of functions assist a module developer with identifying datasets that registered modules produce and for retrieving 'Get' specifications for the datasets the developer's module will use.

The 'item' and 'items' functions are used to organize specifications in the module script. They are aliases of the R language 'list' function.  

The 'readVENameRegistry' function returns a list containing the specifications for all datasets that registered modules save to the datastore. This list contains two components. The components are data frames containing the specifications for all datasets identified in the 'Inp' and 'Set' of registered modules. Each data frame row lists the specifications for a dataset as well as the module which produces the dataset and the package the module is in. This function is useful to developers for:  
- Avoiding dataset naming conflicts with other modules; and,  
- Identifying datasets produced by other modules that can be used in module calculations.  

At the present time, the 'readVENameRegistry' function has fairly rudimentary functionality. The only argument, 'NameRegistryDir', allows the user to specify the local directory where the name registry is located. In the future, the function will read the registry from the remote repository where VisionEval modules are stored. Also, the function will also be modified to enable the module developer to search for datasets based on keywords, module names, package names, and keywords.

The 'getRegisteredGetSpecs' function helps the module developer to write 'Get' specifications that are consistent with the specifications of registered datasets. This function returns a data frame containing the 'Get' specifications for specified datasets. The function arguments are as follows:  
- **Names_** A character vector of the dataset names to get specifications for.  
- **Tables_** A character vector of the tables that the datasets are a part of.  
- **Groups_** A character vector of the groups that the tables are a part of.  
- **NameRegistryDir** A string identifying the path to the directory where the name registry file is located.  

At the present time, the function returns a data frame which contains the 'Get' specifications for each requested dataset. It is up to the module developer to put the information into the proper form in the module script. In the future, the function will be modified to return the 'Get' specifications in list form that may be copied into a module script.  

##### 9.2.3. Utility Functions for Implementing Modules  
Many submodels of the GreenSTEP and RSPM models are linear or binomial logit models. Several of the binary logit model implementations adjust the constant to match specified input proportions. For example, the light truck model enables model users to specify a future light truck proportion and the model will adjust the constant to match that proportion. Likewise, several linear models adjust a dispersion parameter to match a specified population mean. This is done for example in the household income model to match future per capita income projections. The adjustments are made with the use of a binary search algorithm. The following three functions simplify the implementation of those models in the VisionEval model system.  

The 'applyLinearModel' function applies a linear model and optionally adjusts the model to match a target mean value. It has the following arguments:  
- **Model_ls** A list which contains the following components: 1) Type - which has a value of 'linear'; 2) Formula - a string representation of the model equation; 3) PrepFun - a function which prepares the input data frame for the model application. If no preparation, this element of the list should not be present or should be set equal to NULL; 4) SearchRange - a two-element numeric vector which specifies the acceptable search range to use when determining the dispersion factor. 5) OutFun a function that is applied to transform the results of applying the linear model. For example to untransform a power-transformed variable. If no transformation is necessary, this element of the list should not be present or should be set equal to NULL.  
- **Data_df** A data frame containing the data required for applying the model.  
- **TargetMean** A number identifying a target mean value to be achieved or NULL if there is no target.  
- **CheckTargetSearchRange** A logical identifying whether the function is to only check whether the specified 'SearchRange' for the model will produce acceptable values (i.e. no NA or NaN values). If FALSE (the default), the function will run the model and will not check the target search range.   

It is important to note that the 'Model_ls' argument is a list that must contain the components listed above. Also, the 'CheckTargetSearchRange' argument must NOT be set equal TRUE in the call in the module function. Setting it equal to TRUE is only useful during model estimation to help set the target search range values.  

The function returns a  vector of numeric values for each record of the input data frame if the model is being run, or if the function is run to only check the target search range, a summary of predicted values when the model is run with dispersion set at the high value of the search range.

The 'applyBinomialModel' function applies a binomial model and optionally adjusts the model to match a target proportion. It has the following arguments which are similar to those of the 'applyLinearModel' function:  
- **Model_ls** A list which contains the following components: 1) Type - which has a value of 'binomial'; 2) Formula - a string representation of the model equation; 3) Choices - a two-element vector listing the choice set. The first element is the choice that the binary logit model equation predicts the odds of; 4) PrepFun - a function which prepares the input data frame for the model application. If no preparation, this element of the list should not be present or should be set equal to NULL; 5) SearchRange - a two-element numeric vector which specifies the acceptable search range to use when determining the factor for adjusting the model constant.  
- **Data_df** A data frame containing the data required for applying the model.  
- **TargetProp** A number identifying a target proportion for the default choice to be achieved for the input data or NULL if there is no target proportion to be achieved.  
- **CheckTargetSearchRange** A logical identifying whether the function is to only check whether the specified 'SearchRange' for the model will produce acceptable values (i.e. no NA or NaN values). If FALSE (the default), the function will run the model and will not check the target search range.  

- **ApplyRandom** A logical value which determines how the binomial choice is made. The binomial choice model returns a probability that modeled selection is chosen. For example a housing type model could predict the probability that a household lives in a single-family home. If the *ApplyRandom* argument is TRUE, the function takes a sample from a uniform distribution from 0 to 1 and if the value is less than the probability the modeled choice is selected. Otherwise the alternate choice is selected. If the *ApplyRandom* argument is FALSE the modeled choice is selected if the modeled probability is greater than 0.5.

- **ReturnProbs** A logical value which if TRUE returns the modeled choice probabilities instead of the modeled choices.

The function returns a vector of choice values for each record of the input data frame if the neither the *CheckTargetSearchRange* or *ReturnProbs* arguments are TRUE. If the *ReturnProbs* argument is TRUE the choice probabilities are returned. If the *CheckTargetSearchRange* argument is TRUE the function is run to only check the target search range, a two-element vector identifying if the search range produces NA or NaN values.  

The third function, 'binarySearch', is called by the 'applyLinearModel' function if the value of the 'TargetMean' argument is not NULL, and called by the 'applyBinomialModel' function if the value of the 'TargetProp' argument is not NULL. Module developers may find this function to be useful in their own module implementation code. The arguments of the function are:  
- **Function** A function which returns a value which is compared to the Target argument. The function must take as its first argument a value which from the SearchRange_. It must return a value that may be compared to the Target value.  
- **SearchRange_** A two element numeric vector which has the lowest and highest values of the parameter range within which the search will be carried out.
- **...** One or more optional arguments for the Function.  
- **Target** A numeric value that is compared with the return value of the 'Function'.  
- **MaxIter** An integer specifying the maximum number of iterations for the search to attempt in order to match the 'Target' within the specified 'Tolerance'.  
- **Tolerance** A numeric value specifying the proportional difference between the 'Target' and the return value of the Function to determine when the search is complete.  

The function returns a value within the 'SearchRange_' for the function parameter which matches the target value.

Developers can refer to the source code for the 'applyLinearModel' and 'applyBinomialModel' functions to help understand how to use this function.

##### 9.2.4. Module Documentation Function
Section 8.1.4 describes how module documentation is to be included in the module script. The 'documentModule' prepares formatted documentation from the script documentation. Refer to that section for more details.

### Appendix A: Example Model Run Script  
```
#===========
#run_model.R
#===========

#This script demonstrates the VisionEval framework for the RSPM model.

#Load libraries
#--------------
library(visioneval)

#Initialize model
#----------------
initializeModel(
  ParamDir = "defs",
  RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json",
  LoadDatastore = FALSE,
  DatastoreName = NULL,
  SaveDatastore = TRUE
  )  

#Run all demo module for all years
#---------------------------------
for(Year in getYears()) {
  runModule(ModuleName = "CreateHouseholds", 
            PackageName = "VESimHouseholds",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "PredictWorkers", 
            PackageName = "VESimHouseholds",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "AssignLifeCycle", 
            PackageName = "VESimHouseholds",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "PredictIncome", 
            PackageName = "VESimHouseholds",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "PredictHousing", 
            PackageName = "VESimHouseholds",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "LocateHouseholds",
            PackageName = "VELandUse",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "LocateEmployment",
            PackageName = "VELandUse",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "AssignDevTypes",
            PackageName = "VELandUse",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "Calculate4DMeasures",
            PackageName = "VELandUse",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "CalculateUrbanMixMeasure",
            PackageName = "VELandUse",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "AssignTransitService",
            PackageName = "VETransportSupply",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "AssignRoadMiles",
            PackageName = "VETransportSupply",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "AssignVehicleOwnership",
            PackageName = "VEVehicleOwnership",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "CalculateHouseholdDVMT",
            PackageName = "VETravelDemand",
            RunFor = "AllYears",
            RunYear = Year)
  runModule(ModuleName = "CalculateAltModeTrips",
            PackageName = "VETravelDemand",
            RunFor = "AllYears",
            RunYear = Year)
}
```  

### Appendix B: Geography Specification File (geography.csv) Examples  
**Figure A1. Example of a geography.csv file that only specifies Azones**  
![Azone](img/azone_geo_file.png)  

**Figure A2. Example of geography.csv file that specifies Azones and Bzones**   
![Azone Bzone](img/azone_bzone_geo_file.png)  

### Appendix C: Recognized Data Types and Units  
Recognized Data Types and Units are defined in the 'Types' function. The definition also includes the factors for converting between units. This function definition is listed below:

```
$double
$double$units
[1] NA

$double$mode
[1] "double"


$integer
$integer$units
[1] NA

$integer$mode
[1] "integer"


$character
$character$units
[1] NA

$character$mode
[1] "character"


$logical
$logical$units
[1] NA

$logical$mode
[1] "logical"


$compound
$compound$units
[1] NA

$compound$mode
[1] "double"


$currency
$currency$units
$currency$units$USD
USD 
  1 


$currency$mode
[1] "double"


$distance
$distance$units
$distance$units$MI
        MI         FT         KM          M 
   1.00000 5280.00000    1.60934 1609.34000 

$distance$units$FT
         MI          FT          KM           M 
0.000189394 1.000000000 0.000304800 0.304800000 

$distance$units$KM
         MI          FT          KM           M 
   0.621371 3280.840000    1.000000 1000.000000 

$distance$units$M
         MI          FT          KM           M 
0.000621371 3.280840000 0.001000000 1.000000000 


$distance$mode
[1] "double"


$area
$area$units
$area$units$SQMI
       SQMI        ACRE        SQFT         SQM          HA        SQKM 
1.00000e+00 6.40000e+02 2.78800e+07 2.59000e+06 2.58999e+02 2.58999e+00 

$area$units$ACRE
       SQMI        ACRE        SQFT         SQM          HA        SQKM 
1.56250e-03 1.00000e+00 4.35600e+04 4.04686e+03 4.04686e-01 4.04686e-03 

$area$units$SQFT
      SQMI       ACRE       SQFT        SQM         HA       SQKM 
3.5870e-08 2.2957e-05 1.0000e+00 9.2903e-02 9.2903e-06 9.2903e-08 

$area$units$SQM
       SQMI        ACRE        SQFT         SQM          HA        SQKM 
3.86100e-07 2.47105e-04 1.07639e+01 1.00000e+00 1.00000e-04 1.00000e-06 

$area$units$HA
       SQMI        ACRE        SQFT         SQM          HA        SQKM 
3.86102e-03 2.47105e+00 1.07639e+05 3.86102e-03 1.00000e+00 1.00000e-02 

$area$units$SQKM
       SQMI        ACRE        SQFT         SQM          HA        SQKM 
3.86102e-01 2.47105e+02 1.07600e+07 1.00000e+06 1.00000e+02 1.00000e+00 


$area$mode
[1] "double"


$mass
$mass$units
$mass$units$LB
         LB         TON          MT          KG          GM 
1.00000e+00 5.00000e-04 4.53592e-04 4.53592e-01 4.53592e+02 

$mass$units$TON
         LB         TON          MT          KG          GM 
2.00000e+03 1.00000e+00 9.07185e-01 9.07185e+02 9.07185e+05 

$mass$units$MT
         LB         TON          MT          KG           M 
2.20462e+03 1.10231e+00 1.00000e+00 1.00000e+03 1.00000e+06 

$mass$units$KG
         LB         TON          MT          KG          GM 
2.20462e+00 1.10231e-03 1.00000e-03 1.00000e+00 1.00000e+03 

$mass$units$GM
         LB         TON          MT          KG          GM 
2.20462e-03 1.10230e-06 1.00000e-06 1.00000e-03 1.00000e+00 


$mass$mode
[1] "double"


$volume
$volume$units
$volume$units$GAL
    GAL       L 
1.00000 3.78541 

$volume$units$L
     GAL        L 
0.264172 1.000000 


$volume$mode
[1] "double"


$time
$time$units
$time$units$YR
      YR      DAY       HR      MIN      SEC 
       1      365     8760   525600 31540000 

$time$units$DAY
         YR         DAY          HR         MIN         SEC 
2.73973e-03 1.00000e+00 2.40000e+01 1.44000e+03 8.64000e+04 

$time$units$HR
         YR         DAY          HR         MIN         SEC 
1.14155e-04 4.16667e-02 1.00000e+00 6.00000e+01 3.60000e+03 

$time$units$MIN
         YR         DAY          HR         MIN         SEC 
1.90260e-06 6.94444e-04 1.66667e-02 1.00000e+00 6.00000e+01 

$time$units$SEC
         YR         DAY          HR         MIN         SEC 
3.17100e-08 1.15740e-05 2.77778e-04 1.66667e-02 1.00000e+00 


$time$mode
[1] "double"


$energy
$energy$units
$energy$units$KWH
       KWH         MJ        GGE 
1.00000000 3.60000000 0.02967846 

$energy$units$MJ
        KWH          MJ         GGE 
0.277778000 1.000000000 0.008244023 

$energy$units$GGE
      KWH        MJ       GGE 
 33.69447 121.30000   1.00000 


$energy$mode
[1] "double"


$people
$people$units
$people$units$PRSN
PRSN 
   1 


$people$mode
[1] "integer"


$vehicles
$vehicles$units
$vehicles$units$VEH
VEH 
  1 


$vehicles$mode
[1] "integer"


$trips
$trips$units
$trips$units$TRIP
TRIP 
   1 


$trips$mode
[1] "integer"


$households
$households$units
$households$units$HH
HH 
 1 


$households$mode
[1] "integer"


$employment
$employment$units
$employment$units$JOB
JOB 
  1 


$employment$mode
[1] "integer"


$activity
$activity$units
$activity$units$HHJOB
HHJOB 
    1 

```  

### Appendix D: Scenario Input File Examples  
**Figure B1. Example of input file to be loaded into 'Global' group**  
*NOTE: Heavy lines denote rows that are hidden to shorten the display*  
![Global Input](img/global_input_file.png)  

**Figure B2. Example of input file to be loaded into 'forecast year' group**  
![Forecast Year Input](img/forecast_year_input_file.png)  

### Appendix E: Example Module Script from the VETransportSupply Package

```
#======================
#AssignTransitService.R
#======================

#<doc>
#
## AssignTransitService Module
#### November 5, 2018
#
#This module assigns transit service level to the metropolitan area (Marea) and neighborhoods (Bzones). Annual revenue-miles (i.e. transit miles in revenue service) by transit mode type are read from an input file. The following 8 modes are recognized:
#* DR = Demand-responsive
#* VP = Vanpool and similar
#* MB = Standard motor bus
#* RB = Bus rapid transit and commuter bus
#* MG = Monorail/automated guideway
#* SR = Streetcar/trolley bus/inclined plain
#* HR = Heavy Rail/Light Rail
#* CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#
#Revenue miles are converted to bus (i.e. MB) equivalents using factors derived from urbanized are data from the National Transit Database (NTD). Bus-equivalent revenue miles are used in models which predict vehicle ownership and household DVMT.
#
#Revenue miles by mode type are also translated (using NTD data) into vehicle miles by 3 vehicle types: van, bus, and rail. Miles by vehicle type are used to calculate public transit energy consumption and emissions.
#
#The module also reads in user supplied data on relative public transit accessibility by Bzone as explained below.
#
### Model Parameter Estimation
#
#Parameters are calculated to convert the revenue miles for each of the 8 recognized public transit modes into bus equivalents, and to convert revenue miles into vehicle miles. Data extracted from the 2015 National Transit Database (NTD) are used to calculate these parameters. The extracted datasets are in the *2015_Service.csv* and *2015_Agency_information.csv* files in the *inst/extdata* directory of this package. These files contain information about transit service and transit service providers located within urbanized areas. Documentation of the data are contained in the accompanying *2015_Service.txt* and *2015_Agency_information.txt* files.
#
#Bus equivalent factors for each of the 8 modes is calculated on the basis of the average productivity of each mode as measured by the ratio of passenger miles to revenue miles. The bus-equivalency factor of each mode is the ratio of the average productivity of the mode to the average productivity of the bus (MB) mode.
#
#Factors to compute vehicle miles by mode from revenue miles by mode are calculated from the NTD data on revenue miles and deadhead (i.e. out of service) miles. The vehicle mile factor is the sum of revenue and deadhead miles divided by the revenue miles. These factors vary by mode.
#
### How the Module Work
#
#The user supplies data on the annual revenue miles of service by each of the 8 transit modes for the Marea. These revenue miles are converted to bus equivalents using the estimated bus-equivalency factors and summed to calculate total bus-equivalent revenue miles. This value is divided by the urbanized area population of the Marea to compute bus-equivalent revenue miles per capita. This public transit service measure is used in models of household vehicle ownership and household vehicle travel.
#
#The user supplied revenue miles by mode are translated into vehicle miles by mode using the estimated conversion factors. The results are then simplified into 3 vehicle types (Van, Bus, Rail) where the DR and VP modes are assumed to be served by vans, the MB and RB modes are assumed to be served by buses, and the MG, SR, HR, and CR modes are assumed to be served by rail.
#
#The user also supplies information on the aggregate frequency of peak period transit service within 0.25 miles of the Bzone boundary per hour during evening peak period. This is the *D4c* measure included in the Environmental Protection Agency's (EPA) [Smart Location Database] (https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide). Following is the description of the measure from the user guide:
#>EPA analyzed GTFS data to calculate the frequency of service for each transit route between 4:00 and 7:00 PM on a weekday. Then, for each block group, EPA identified transit routes with service that stops within 0.4 km (0.25 miles). Finally EPA summed total aggregate service frequency by block group. Values for this metric are expressed as service frequency per hour of service.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#Describe specifications for transit data files
#----------------------------------------------
#Transit agency data
AgencyInp_ls <- items(
  item(
    NAME =
      items("AgencyID",
            "PrimaryUZA",
            "Population"),
    TYPE = "integer",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "UZAName",
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Transit service data
ServiceInp_ls <- items(
  item(
    NAME =
      items("RevenueMiles",
            "DeadheadMiles",
            "PassengerMiles"),
    TYPE = "double",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AgencyID",
            "AgencyName",
            "Mode",
            "TimePeriod"),
    TYPE = "character",
    PROHIBIT = "",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Define function to estimate public transit model parameters
#-----------------------------------------------------------
#' Estimate public transit model parameters.
#'
#' \code{estimateTransitModel} estimates transit model parameters.
#'
#' This function estimates transit model parameters from 2015 National Transit
#' Database information on transit agencies and service levels. The function
#' calculates factors for converting annual revenue miles by transit mode to
#' total bus-equivalent revenue miles. It also calculates factors to convert
#' revenue miles by mode into vehicle miles by mode.
#'
#' @return A list containing the following elements:
#' BusEquivalents_df: factors to convert revenue miles by mode into bus
#' equivalents,
#' UZABusEqRevMile_df: data on bus equivalent revenue miles by urbanized area,
#' VehMiFactors_df: factors to convert revenue miles by mode into vehicle miles
#' by mode.
#' @name estimateTransitModel
#' @import stats
#' @export
estimateTransitModel <- function() {
  #Read in and process transit datasets
  #------------------------------------
  #Read in transit agency datasets
  Agency_df <-
    processEstimationInputs(
      AgencyInp_ls,
      "2015_Agency_information.csv",
      "AssignTransitService.R")
  #Read in transit service datasets
  Service_df <-
    processEstimationInputs(
      ServiceInp_ls,
      "2015_Service.csv",
      "AssignTransitService.R")
  #Select only rows with annual totals
  Service_df <- Service_df[Service_df$TimePeriod == "Annual Total",]
  #Select only rows for service in urbanized areas
  Service_df <- Service_df[Service_df$AgencyID %in% Agency_df$AgencyID,]

  #Define combined modes and create index datasets
  #-----------------------------------------------
  CombinedCode_ls <-
    list(
      DR = c("DR", "DT"),
      VP = c("VP", "PB"),
      MB = c("MB"),
      RB = c("RB", "CB"),
      MG = c("MG"),
      SR = c("SR", "TB", "IP"),
      HR = c("LR", "HR", "AR"),
      CR = c("CR", "YR", "CC", "TR")
    )
  CombinedCode_ <-
    c(DR = "DR", DT = "DR", VP = "VP", PB = "VP", MB = "MB", RB = "RB", CB = "RB",
      MG = "MG", SR = "SR", TB = "SR", IP = "SR", LR = "HR", HR = "HR", AR = "HR",
      CR = "CR", YR = "CR", CC = "CR", TR = "CR"
    )
  Cm <- c("DR", "VP", "MB", "RB", "MG", "SR", "HR", "CR")

  #Calculate bus equivalency factors
  #---------------------------------
  #Calculate productivity measure
  Service_df$Productivity <-
    Service_df$PassengerMiles / Service_df$RevenueMiles
  #Calculate the average productivity by mode
  AveProductivity_Md <-
    tapply(Service_df$Productivity, Service_df$Mode, mean, na.rm = TRUE)
  #Calculate bus equivalency of different modes
  BusEquiv_Md <- AveProductivity_Md / AveProductivity_Md["MB"]
  #Calculate average productivity by combined mode
  BusEquiv_Cm <- unlist(lapply(CombinedCode_ls, function(x) {
    mean(BusEquiv_Md[x])
  }))
  #Create data frame with mode names and equivalency factors
  BusEquiv_df <-
    data.frame(
      Mode = names(BusEquiv_Cm),
      BusEquivalents = unname(BusEquiv_Cm)
    )

  #Calculate revenue miles to total vehicle mile factors by mode
  #-------------------------------------------------------------
  #Convert DeadheadMiles for mode DT from NA to 0
  Service_df$DeadheadMiles[Service_df$Mode == "DT"] <- 0
  #Create data frame of complete cases of revenue miles and deadhead miles
  Veh_df <- Service_df[, c("Mode", "RevenueMiles", "DeadheadMiles")]
  Veh_df <- Veh_df[complete.cases(Veh_df),]
  #Calculate total revenue miles by combined mode
  RevMi_Md <- tapply(Veh_df$RevenueMiles, Veh_df$Mode, sum)
  RevMi_Cm <- unlist(lapply(CombinedCode_ls, function(x) {
    sum(RevMi_Md[x])
  }))
  #Calculate total deadhead miles by combined mode
  DeadMi_Md <- tapply(Veh_df$DeadheadMiles, Veh_df$Mode, sum)
  DeadMi_Cm <- unlist(lapply(CombinedCode_ls, function(x) {
    sum(DeadMi_Md[x])
  }))
  #Calculate vehicle mile factors by combined mode
  VehMiFactors_Cm <- (RevMi_Cm + DeadMi_Cm) / RevMi_Cm
  VehMiFactors_df <-
    data.frame(
      Mode = names(VehMiFactors_Cm),
      VehMiFactors = unname(VehMiFactors_Cm)
    )

  #Calculate bus equivalent transit service by urbanized area
  #----------------------------------------------------------
  #Attach urbanized area code to service data
  Service_df$UzaCode <- Agency_df$PrimaryUZA[match(Service_df$AgencyID, Agency_df$AgencyID)]
  Service_df$UzaName <- Agency_df$UZAName[match(Service_df$AgencyID, Agency_df$AgencyID)]
  #Tabulate vehicle revenue miles by urbanized area and mode
  RevMi_UnMd <-
    tapply(Service_df$RevenueMiles,
           list(Service_df$UzaName, Service_df$Mode),
           sum)
  RevMi_UnMd[is.na(RevMi_UnMd)] <- 0
  #Summarize by combined mode
  RevMi_UnCm <- t(apply(RevMi_UnMd, 1, function(x) {
    tapply(x, CombinedCode_[colnames(RevMi_UnMd)], sum, na.rm = TRUE)[Cm]
  }))
  #Sum up the bus-equivalent revenue miles by urbanized area
  BusEqRevMi_Un <-
    rowSums(sweep(RevMi_UnCm, 2, BusEquiv_Cm, "*"))
  #Tabulate population by urbanized area
  UzaPop_Un <- Agency_df$Population[!duplicated(Agency_df$PrimaryUZA)]
  names(UzaPop_Un) <- Agency_df$UZAName[!duplicated(Agency_df$PrimaryUZA)]
  UzaPop_Un <- UzaPop_Un[names(BusEqRevMi_Un)]
  UzaPop_Un <- UzaPop_Un[names(BusEqRevMi_Un)]
  #Calculate bus-equivalent revenue miles per capita
  BusEqRevMiPC_Un <- BusEqRevMi_Un / UzaPop_Un
  #Create data frame of urbanized area bus revenue mile equivalency
  UZABusEqRevMile_df <-
    Service_df[!duplicated(Service_df$UzaName), c("UzaCode", "UzaName")]
  rownames(UZABusEqRevMile_df) <- UZABusEqRevMile_df$UzaName
  UZABusEqRevMile_df <- UZABusEqRevMile_df[names(BusEqRevMi_Un),]
  UZABusEqRevMile_df$BusEqRevMi <- unname(BusEqRevMi_Un)
  UZABusEqRevMile_df$UzaPop <- unname(UzaPop_Un)
  UZABusEqRevMile_df$BusEqRevMiPC <- unname(BusEqRevMiPC_Un)
  rownames(UZABusEqRevMile_df) <- NULL

  #Return the results
  #------------------
  list(
    BusEquivalents_df = BusEquiv_df,
    UZABusEqRevMile_df = UZABusEqRevMile_df,
    VehMiFactors_df = VehMiFactors_df
  )
}

#Estimate public transit model parameters
#----------------------------------------
TransitParam_ls <- estimateTransitModel()
BusEquivalents_df <- TransitParam_ls$BusEquivalents_df
UZABusEqRevMile_df <- TransitParam_ls$UZABusEqRevMile_df
VehMiFactors_df <- TransitParam_ls$VehMiFactors_df
rm(AgencyInp_ls)
rm(ServiceInp_ls)

#Save the bus equivalency factors
#--------------------------------
#' Bus equivalency factors
#'
#' Bus revenue mile equivalency factors to convert revenue miles for various
#' modes to bus-equivalent revenue miles.
#'
#' @format A data frame with 8 rows and 2 variables containing factors for
#' converting revenue miles of various modes to bus equivalent revenue miles.
#' Mode names are 2-character codes corresponding to consolidated mode types.
#' Consolidated mode types represent modes that have similar characteristics and
#' bus equivalency values. The consolidate mode codes and their meanings are as
#' follows:
#' DR = Demand-responsive
#' VP = Vanpool and similar
#' MB = Standard motor bus
#' RB = Bus rapid transit and commuter bus
#' MG = Monorail/automated guideway
#' SR = Streetcar/trolley bus/inclined plain
#' HR = Heavy Rail/Light Rail
#' CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#'
#' \describe{
#'   \item{Mode}{abbreviation for consolidated mode}
#'   \item{BusEquivalents}{numeric factor for converting revenue miles to bus equivalents}
#' }
#' @source AssignTransitService.R script.
"BusEquivalents_df"
usethis::use_data(BusEquivalents_df, overwrite = TRUE)

#Save the vehicle mile factors
#-----------------------------
#' Revenue miles to vehicle miles conversion factors
#'
#' Vehicle mile factors convert revenue miles for various modes to vehicle
#' miles for those modes.
#'
#' @format A data frame with 8 rows and 2 variables containing factors for
#' converting revenue miles of various modes to vehicle miles.
#' Mode names are 2-character codes corresponding to consolidated mode types.
#' Consolidated mode types represent modes that have similar characteristics and
#' bus equivalency values. The consolidate mode codes and their meanings are as
#' follows:
#' DR = Demand-responsive
#' VP = Vanpool and similar
#' MB = Standard motor bus
#' RB = Bus rapid transit and commuter bus
#' MG = Monorail/automated guideway
#' SR = Streetcar/trolley bus/inclined plain
#' HR = Heavy Rail/Light Rail
#' CR = Commuter Rail/Hybrid Rail/Cable Car/Aerial Tramway
#'
#' \describe{
#'   \item{Mode}{abbreviation for consolidated mode}
#'   \item{VehMiFactors}{numeric factors for converting revenue miles to
#'   vehicle miles}
#' }
#' @source AssignTransitService.R script.
"VehMiFactors_df"
usethis::use_data(VehMiFactors_df, overwrite = TRUE)

#Save the urbanized area bus equivalency data
#--------------------------------------------
#' Urbanized area bus equivalent revenue mile data for 2015
#'
#' Urbanized area data from the 2015 National Transit Database (NTD) related to
#' the calculation of bus equivalent revenue miles and per capita values.
#'
#' @format A data frame with 439 rows and 5 variables containing urbanized area
#' data on bus equivalent revenue miles
#'
#' \describe{
#'   \item{UzaCode}{integer code corresponding to 5-digit code used in the NTD}
#'   \item{UzaName}{urbanized area name}
#'   \item{BusEqRevMi}{annual bus equivalent revenue miles in the urbanized area}
#'   \item{UzaPop}{urbanized area population}
#'   \item{BusEqRevMiPC}{annual bus equivalent revenue miles per capita in the urbanized area}
#' }
#' @source AssignTransitService.R script.
"UZABusEqRevMile_df"
usethis::use_data(UZABusEqRevMile_df, overwrite = TRUE)

#Clean up
rm(TransitParam_ls)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignTransitServiceSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "DRRevMi",
          "VPRevMi",
          "MBRevMi",
          "RBRevMi",
          "MGRevMi",
          "SRRevMi",
          "HRRevMi",
          "CRRevMi"),
      FILE = "marea_transit_service.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/YR",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        list(
          "Annual revenue-miles of demand-responsive public transit service",
          "Annual revenue-miles of van-pool and similar public transit service",
          "Annual revenue-miles of standard bus public transit service",
          "Annual revenue-miles of rapid-bus and commuter bus public transit service",
          "Annual revenue-miles of monorail and automated guideway public transit service",
          "Annual revenue-miles of streetcar and trolleybus public transit service",
          "Annual revenue-miles of light rail and heavy rail public transit service",
          "Annual revenue-miles of commuter rail, hybrid rail, cable car, and aerial tramway public transit service"
        )
    ),
    item(
      NAME = "D4c",
      FILE = "bzone_transit_service.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "aggregate peak period transit service",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period (Ref: EPA 2010 Smart Location Database)"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "DRRevMi",
          "VPRevMi",
          "MBRevMi",
          "RBRevMi",
          "MGRevMi",
          "SRRevMi",
          "HRRevMi",
          "CRRevMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "TranRevMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN/YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of annual bus-equivalent revenue-miles (i.e. revenue-miles at the same productivity - passenger miles per revenue mile - as standard bus) to urbanized area population"
    ),
    item(
      NAME =
        items(
          "VanDvmt",
          "BusDvmt",
          "RailDvmt"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Total daily miles traveled by vans of various sizes to provide demand responsive, vanpool, and similar services.",
        "Total daily miles traveled by buses of various sizes to provide bus service of various types.",
        "Total daily miles traveled by light rail, heavy rail, commuter rail, and similar types of vehicles."
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignTransitService module
#'
#' A list containing specifications for the AssignTransitService module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignTransitService.R script.
"AssignTransitServiceSpecifications"
usethis::use_data(AssignTransitServiceSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the annual bus equivalent revenue miles per capita for
#the urbanized area from the number of annual revenue miles for different
#public transit modes and the urban area population.

#Main module function that calculates bus equivalent revenue miles per capita
#----------------------------------------------------------------------------
#' Calculate bus equivalent revenue miles per capita by Marea.
#'
#' \code{AssignTransitService} calculate bus equivalent revenue miles per capita.
#'
#' This function calculates bus equivalent revenue miles per capita for each
#' Marea.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignTransitService
#' @import visioneval
#' @export
AssignTransitService <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of modes
  Md <- as.character(BusEquivalents_df$Mode)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea

  #Calculate bus equivalent revenue miles
  #--------------------------------------
  #Make table of revenue miles by Marea
  RevMi_df <- data.frame(L$Year$Marea[paste0(Md, "RevMi")])
  colnames(RevMi_df) <- Md
  rownames(RevMi_df) <- Ma
  RevMi_MaMd <- as.matrix(RevMi_df)
  #Calculate the bus equivalent revenue miles
  BusEq_Md <- BusEquivalents_df$BusEquivalents
  names(BusEq_Md) <- Md
  BusEqRevMi_Ma <-
    rowSums(sweep(RevMi_MaMd, 2, BusEq_Md, "*"))[Ma]

  #Calculate the bus equivalent revenue miles per capita
  #-----------------------------------------------------
  #Calculate population in the urbanized area
  UrbanPop_Ma <-
    tapply(L$Year$Bzone$UrbanPop, L$Year$Bzone$Marea, sum)[Ma]
  #Calculate Marea bus equivalent revenue miles per capita
  TranRevMiPC_Ma <- BusEqRevMi_Ma / UrbanPop_Ma

  #Calculate vehicle miles by vehicle type
  #---------------------------------------
  #Make vector of vehicle miles factors conforming with RevMi_df
  VehMiFactors_Md <- VehMiFactors_df$VehMiFactors
  names(VehMiFactors_Md) <- VehMiFactors_df$Mode
  VehMiFactors_Md <- VehMiFactors_Md[names(RevMi_df)]
  #Calculate daily vehicle miles by Marea and mode
  VehMi_MaMd <- as.matrix(sweep(RevMi_df, 2, VehMiFactors_Md, "*")) / 365
  #Define correspondence between modes and vehicle types
  ModeToVehType_ <- c(
    DR = "Van",
    VP = "Van",
    MB = "Bus",
    RB = "Bus",
    MG = "Rail",
    SR = "Rail",
    HR = "Rail",
    CR = "Rail"
  )
  ModeToVehType_ <- ModeToVehType_[colnames(VehMi_MaMd)]
  VehMi_df <-
    data.frame(
      t(
        apply(VehMi_MaMd, 1, function(x) {
          tapply(x, ModeToVehType_, sum) })
        )
      )

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(TranRevMiPC = TranRevMiPC_Ma,
         VanDvmt = VehMi_df$Van,
         BusDvmt = VehMi_df$Bus,
         RailDvmt = VehMi_df$Rail)
  #Return the outputs list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignTransitService")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# library(filesstrings)
# library(visioneval)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-RSPM",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "verspm",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "AssignTransitService",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignTransitService(L)
```  

### Appendix F: Example Test Script from the VESimHouseholds Package  
```
#vestate_test.R
#--------------

#Load packages and test functions
library(visioneval)
library(filesstrings)
source("tests/scripts/test_functions.R")

#Define test setup parameters
TestSetup_ls <- list(
  TestDataRepo = "../Test_Data/VE-State",
  DatastoreName = "Datastore.tar",
  LoadDatastore = FALSE,
  TestDocsDir = "vestate",
  ClearLogs = TRUE,
  # SaveDatastore = TRUE
  SaveDatastore = FALSE
)

#Define the module tests
Tests_ls <- list(
  list(ModuleName = "CreateHouseholds", LoadDatastore = FALSE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "PredictWorkers", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "AssignLifeCycle", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE),
  list(ModuleName = "PredictIncome", LoadDatastore = TRUE, SaveDatastore = TRUE, DoRun = TRUE)
)

#Set up, run tests, and save test results
setUpTests(TestSetup_ls)
doTests(Tests_ls, TestSetup_ls)
saveTestResults(TestSetup_ls)
```  

### Appendix G: VisionEval Model User Functions


### `getYears`: Retrieve years

#### Description


 `getYears` a visioneval framework model user function that reads the
 Years component from the the model state file.


#### Usage

```r
getYears()
```


#### Details


 This is a convenience function to make it easier to retrieve the Years
 component of the model state file which lists all of the specified model run
 years. If the Years component includes the base year, then the returned
 vector of years places the base year first in the order. This ordering is
 important because some modules calculate future year values by pivoting off
 of base year values so the base year must be run first.


#### Value


 A character vector of the model run years.


#### Calls
getModelState


### `initializeModel`: Initialize model.

#### Description


 `initializeModel` a visioneval framework model user function
 that initializes a VisionEval model, loading all parameters and inputs, and
 making checks to ensure that model can run successfully.


#### Usage

```r
initializeModel(ParamDir = "defs",
  RunParamFile = "run_parameters.json", GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json", LoadDatastore = FALSE,
  DatastoreName = NULL, SaveDatastore = TRUE)
```


#### Arguments

Argument      |Description
------------- |----------------
```ParamDir```     |     A string identifying the relative or absolute path to the directory where the parameter and geography definition files are located. The default value is "defs".
```RunParamFile```     |     A string identifying the name of a JSON-formatted text file that contains parameters needed to identify and manage the model run. The default value is "run_parameters.json".
```GeoFile```     |     A string identifying the name of a text file in comma-separated values format that contains the geographic specifications for the model. The default value is "geo.csv".
```ModelParamFile```     |     A string identifying the name of a JSON-formatted text file that contains global model parameters that are important to a model and may be shared by several modules.
```LoadDatastore```     |     A logical identifying whether an existing datastore should be loaded.
```DatastoreName```     |     A string identifying the full path name of a datastore to load or NULL if an existing datastore in the working directory is to be loaded.
```SaveDatastore```     |     A string identifying whether if an existing datastore in the working directory should be saved rather than removed.

#### Details


 This function does several things to initialize the model environment and
 datastore including:
 1) Initializing a file that is used to keep track of the state of key model
 run variables and the datastore;
 2) Initializes a log to which messages are written;
 3) Creates the datastore and initializes its structure, reads in and checks
 the geographic specifications and initializes the geography in the datastore,
 or loads an existing datastore if one has been identified;
 4) Parses the model run script to identify the modules in their order of
 execution and checks whether all the identified packages are installed and
 the modules exist in the packages;
 5) Checks that all data requested from the datastore will be available when
 it is requested and that the request specifications match the datastore
 specifications;
 6) Checks all of the model input files to determine whether they they are
 complete and comply with specifications.


#### Value


 None. The function prints to the log file messages which identify
 whether or not there are errors in initialization. It also prints a success
 message if initialization has been successful.


#### Calls
assignDatastoreFunctions, checkDataset, checkModuleExists, checkModuleSpecs, getModelState, getModuleSpecs, initDatastoreGeography, initLog, initModelStateFile, inputsToDatastore, loadDatastore, loadModelParameters, parseModelScript, processModuleInputs, processModuleSpecs, readGeography, readModelState, setModelState, simDataTransactions, writeLog


### `readDatastoreTables`: Read multiple datasets from multiple tables in datastores

#### Description


 `readDatastoreTables` a visioneval framework model user function that
 reads datasets from one or more tables in a specified group in one or more
 datastores


#### Usage

```r
readDatastoreTables(Tables_ls, Group, DstoreLocs_, DstoreType)
```


#### Arguments

Argument      |Description
------------- |----------------
```Tables_ls```     |     a named list where the name of each component is the name of a table in a datastore group and the value is a string vector of the names of the datasets to be retrieved.
```Group```     |     a string that is the name of the group to retrieve the table datasets from.
```DstoreLocs_```     |     a string vector identifying the paths to all of the datastores to extract the datasets from. Each entry must be the full relative path to a datastore (e.g. 'tests/Datastore').
```DstoreType```     |     a string identifying the type of datastore (e.g. 'RD', 'H5'). Note

#### Details


 This function can read multiple datasets in one or more tables in a group.
 More than one datastore my be specified so that if datastore references are
 used in a model run, datasets from the referenced datastores may be queried
 as well. Note that the capability for querying multiple datastores is only
 for the purpose of querying datastores for a single model scenario. This
 capability should not be used to compare multiple scenarios. The function
 does not segregate datasets by datastore. Attempting to use this function to
 compare multiple scenarios could produce unpredictable results.


#### Value


 A named list having two components. The 'Data' component is a list
 containing the datasets from the datastores where the name of each component
 of the list is the name of a table from which identified datasets are
 retrieved and the value is a data frame containing the identified datasets.
 The 'Missing' component is a list which identifies the datasets that are
 missing in each table.


#### Calls
checkDataset, checkTableExistence, readModelState


### `runModule`: Run module.

#### Description


 `runModule` a visioneval framework model user function that
 runs a module.


#### Usage

```r
runModule(ModuleName, PackageName, RunFor, RunYear, StopOnErr = TRUE)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleName```     |     A string identifying the name of a module object.
```PackageName```     |     A string identifying the name of the package the module is a part of.
```RunFor```     |     A string identifying whether to run the module for all years "AllYears", only the base year "BaseYear", or for all years except the base year "NotBaseYear".
```RunYear```     |     A string identifying the run year.
```StopOnErr```     |     A logical identifying whether model execution should be stopped if the module transmits one or more error messages or whether execution should continue with the next module. The default value is TRUE. This is how error handling will ordinarily proceed during a model run. A value of FALSE is used when 'Initialize' modules in packages are run during model initialization. These 'Initialize' modules are used to check and preprocess inputs. For this purpose, the module will identify any errors in the input data, the 'initializeModel' function will collate all the data errors and print them to the log.

#### Details


 This function runs a module for a specified year.


#### Value


 None. The function writes results to the specified locations in the
 datastore and prints a message to the console when the module is being run.


#### Calls
createGeoIndexList, getFromDatastore, getModelState, processModuleSpecs, setInDatastore, writeLog

### Appendix H: VisionEval Module Developer Functions


### `addErrorMsg`: Add an error message to the results list

#### Description


 `addErrorMsg` a visioneval framework module developer function that adds
 an error message to the Errors component of the module results list that is
 passed back to the framework.


#### Usage

```r
addErrorMsg(ResultsListName, ErrMsg)
```


#### Arguments

Argument      |Description
------------- |----------------
```ResultsListName```     |     the name of the results list given as a character string
```ErrMsg```     |     a character string that contains the error message

#### Details


 This function is a convenience function for module developers for passing
 error messages back to the framework. The preferred method for handling
 errors in module execution is for the module to handle the error by passing
 one or more error messages back to the framework. The framework will then
 write error messages to the log and stop execution. Error messages are
 stored in a component of the returned list called Errors. This component is
 a string vector where each element is an error message. The addErrorMsg will
 create the Error component if it does not already exist and will add an error
 message to the vector.


#### Value


 None. The function modifies the results list by adding an error
 message to the Errors component of the results list. It creates the Errors
 component if it does not already exist.


#### Calls



### `addWarningMsg`: Add a warning message to the results list

#### Description


 `addWarningMsg` a visioneval framework module developer function that
 adds an warning message to the Warnings component of the module results list
 that is passed back to the framework.


#### Usage

```r
addWarningMsg(ResultsListName, WarnMsg)
```


#### Arguments

Argument      |Description
------------- |----------------
```ResultsListName```     |     the name of the results list given as a character string
```WarnMsg```     |     a character string that contains the warning message

#### Details


 This function is a convenience function for module developers for passing
 warning messages back to the framework. The preferred method for handling
 warnings in module execution is for the module to handle the warning by
 passing one or more warning messages back to the framework. The framework
 will then write warning messages to the log and stop execution. Warning
 messages are stored in a component of the returned list called Warnings. This
 component is a string vector where each element is an warning message. The
 addWarningMsg will create the Warning component if it does not already exist
 and will add a warning message to the vector.


#### Value


 None. The function modifies the results list by adding a warning
 message to the Warnings component of the results list. It creates the
 Warnings component if it does not already exist.


#### Calls



### `applyBinomialModel`: Applies an estimated binomial model to a set of input values.

#### Description


 `applyBinomialModel` a visioneval framework module developer function
 that applies an estimated binomial model to a set of input data.


#### Usage

```r
applyBinomialModel(Model_ls, Data_df, TargetProp = NULL,
  CheckTargetSearchRange = FALSE, ApplyRandom = TRUE,
  ReturnProbs = FALSE)
```


#### Arguments

Argument      |Description
------------- |----------------
```Model_ls```     |     a list which contains the following components: 'Type' which has a value of 'binomial'; 'Formula' a string representation of the model equation; 'Choices' a two-element vector listing the choice set. The first element is the choice that the binary logit model equation predicts the odds of; 'PrepFun' a function which prepares the input data frame for the model application. If no preparation, this element of the list should not be present or should be set equal to NULL; 'SearchRange' a two-element numeric vector which specifies the acceptable search range to use when determining the factor for adjusting the model constant. 'RepeatVar' a string which identifies the name of a field to use for repeated draws of the model. This is used in the case where for example the input data is households and the output is vehicles and the repeat variable is the number of vehicles in the household. 'ApplyRandom' a logical identifying whether the results will be affected by random draws (i.e. if a random number in range 0 - 1 is less than the computed probability) or if a probability cutoff is used (i.e. if the computed probability is greater then 0.5). This is an optional component. If it isn't present, the function runs with ApplyRandom = TRUE.
```Data_df```     |     a data frame containing the data required for applying the model.
```TargetProp```     |     a number identifying a target proportion for the default choice to be achieved for the input data or NULL if there is no target proportion to be achieved.
```CheckTargetSearchRange```     |     a logical identifying whether the function is to only check whether the specified 'SearchRange' for the model will produce acceptable values (i.e. no NA or NaN values). If FALSE (the default), the function will run the model and will not check the target search range.
```ApplyRandom```     |     a logical identifying whether the outcome will be be affected by random draws (i.e. if a random number in range 0 - 1 is less than the computed probability) or if a probability cutoff is used (i.e. if the computed probability is greater than 0.5)
```ReturnProbs```     |     a logical identifying whether to return the calculated probabilities rather than the assigned results. The default value is FALSE.

#### Details


 The function calculates the result of applying a binomial logit model to a
 set of input data. If a target proportion (TargetProp) is specified, the
 function calls the 'binarySearch' function to calculate an adjustment to
 the constant of the model equation so that the population proportion matches
 the target proportion. The function will also test whether the target search
 range specified for the model will produce acceptable values.


#### Value


 a vector of choice values for each record of the input data frame if
 the model is being run, or if the function is run to only check the target
 search range, a two-element vector identifying if the search range produces
 NA or NaN values.


#### Calls
binarySearch


### `applyLinearModel`: Applies an estimated linear model to a set of input values.

#### Description


 `applyLinearModel` a visioneval framework module developer function that
 applies an estimated linear model to a set of input data.


#### Usage

```r
applyLinearModel(Model_ls, Data_df, TargetMean = NULL,
  CheckTargetSearchRange = FALSE)
```


#### Arguments

Argument      |Description
------------- |----------------
```Model_ls```     |     a list which contains the following components: 'Type' which has a value of 'linear'; 'Formula' a string representation of the model equation; 'PrepFun' a function which prepares the input data frame for the model application. If no preparation, this element of the list should not be present or should be set equal to NULL; 'SearchRange' a two-element numeric vector which specifies the acceptable search range to use when determining the dispersion factor. 'OutFun' a function that is applied to transform the results of applying the linear model. For example to untransform a power-transformed variable. If no transformation is necessary, this element of the list should not be present or should be set equal to NULL.
```Data_df```     |     a data frame containing the data required for applying the model.
```TargetMean```     |     a number identifying a target mean value to be achieved  or NULL if there is no target.
```CheckTargetSearchRange```     |     a logical identifying whether the function is to only check whether the specified 'SearchRange' for the model will produce acceptable values (i.e. no NA or NaN values). If FALSE (the default), the function will run the model and will not check the target search range.

#### Details


 The function calculates the result of applying a linear regression model to a
 set of input data. If a target mean value (TargetMean) is specified, the
 function calculates a standard deviation of a sampling distribution which
 is applied to linear model results. For each value returned by the linear
 model, a sample is drawn from a normal distribution where the mean value of
 the distribution is the linear model result and the standard deviation of the
 distibution is calculated by the binary search to match the population mean
 value to the target mean value. This process is meant to be applied to linear
 model where the dependent variable is power transformed. Applying the
 sampling distribution to the linear model results increases the dispersion
 of results to match the observed dispersion and also matches the mean values
 of the untransformed results. This also enables the model to be applied to
 situations where the mean value is different than the observed mean value.


#### Value


 a vector of numeric values for each record of the input data frame if
 the model is being run, or if the function is run to only check the target
 search range, a summary of predicted values when the model is run with
 dispersion set at the high value of the search range.


#### Calls
binarySearch


### `binarySearch`: Binary search function to find a parameter which achieves a target value.

#### Description


 `binarySearch` a visioneval framework module developer function that
 uses a binary search algorithm to find the value of a function parameter for
 which the function achieves a target value.


#### Usage

```r
binarySearch(Function, SearchRange_, ..., Target = 0, DoWtAve = TRUE,
  MaxIter = 100, Tolerance = 1e-04)
```


#### Arguments

Argument      |Description
------------- |----------------
```Function```     |     a function which returns a value which is compared to the 'Target' argument. The function must take as its first argument a value which from the 'SearchRange_'. It must return a value that may be compared to the 'Target' value.
```SearchRange_```     |     a two element numeric vector which has the lowest and highest values of the parameter range within which the search will be carried out.
```...```     |     one or more optional arguments for the 'Function'.
```Target```     |     a numeric value that is compared with the return value of the 'Function'.
```DoWtAve```     |     a logical indicating whether successive weighted averaging is to be done. This is useful for getting stable results for stochastic calculations.
```MaxIter```     |     an integer specifying the maximum number of iterations to all the search to attempt.
```Tolerance```     |     a numeric value specifying the proportional difference between the 'Target' and the return value of the 'Function' to determine when the search is complete.

#### Details


 A binary search algorithm is used by several modules to calibrate the
 intercept of a binary logit model to match a specified proportion or to
 calibrate a dispersion parameter for a linear model to match a mean value.
 This function implements a binary search algorithm in a consistent manner to
 be used in all modules that need it. It is written to work with stochastic
 models which by their nature don't produce the same outputs given the same
 inputs and so will not converge reliably. To deal with the stochasticity,
 this function uses a successive averaging  approach to smooth out the effect
 of stochastic variation on reliable convergence. Rather than use the results
 of a single search iteration to determine the next value range to use in the
 search, a weighted average of previous values is used with the more recent
 values being weighted more heavily.


#### Value


 the value in the 'SearchRange_' for the function parameter which
 matches the target value.


#### Calls



### `checkModuleOutputs`: Check module outputs for consistency with specifications

#### Description


 `checkModuleOutputs` a visioneval framework module developer function
 that checks output list produced by a module for consistency with the
 module's specifications.


#### Usage

```r
checkModuleOutputs(Data_ls, ModuleSpec_ls, ModuleName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_ls```     |     A list of all the datasets returned by a module in the standard list form required by the VisionEval model system.
```ModuleSpec_ls```     |     A list of module specifications in the standard list form required by the VisionEval model system.
```ModuleName```     |     A string identifying the name of the module.

#### Details


 This function is used to check whether the output list produced by a module
 is consistent with the module's specifications. If there are any
 specifications for creating tables, the function checks whether the output
 list contains the table(s), if the LENGTH attribute of the table(s) are
 present, and if the LENGTH attribute(s) are consistent with the length of the
 datasets to be saved in the table(s). Each of the datasets in the output list
 are checked against the specifications. These include checking that the
 data type is consistent with the specified type and whether all values are
 consistent with PROHIBIT and ISELEMENTOF conditions. For character types,
 a check is made to ensure that a SIZE attribute exists and that the size
 is sufficient to store all characters.


#### Value


 A character vector containing a list of error messages or having a
 length of 0 if there are no error messages.


#### Calls
checkDataConsistency, processModuleSpecs


### `documentModule`: Produces markdown documentation for a module

#### Description


 `documentModule` a visioneval framework module developer function
 that creates a vignettes directory if one does not exist and produces
 module documentation in markdown format which is saved in the vignettes
 directory.


#### Usage

```r
documentModule(ModuleName)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleName```     |     A string identifying the name of the module (e.g. 'CalculateHouseholdDvmt')

#### Details


 This function produces documentation for a module in markdown format. A
 'vignettes' directory is created if it does not exist and the markdown file
 and any associated resources such as image files are saved in that directory.
 The function is meant to be called within and at the end of the module
 script. The documentation is created from a commented block within the
 module script which is enclosed by the opening tag, <doc>, and the closing
 tag, </doc>. (Note, these tags must be commented along with all the other
 text in the block). This commented block may also include tags which identify
 resources to include within the documentation. These tags identify the
 type of resource and the name of the resource which is located in the 'data'
 directory. A colon (:) is used to separate the resource type and resource
 name identifiers. For example:
 <txt:DvmtModel_ls$EstimationStats$NonMetroZeroDvmt_GLM$Summary>
 is a tag which will insert text which is located in a component of the
 DvmtModel_ls list that is saved as an rdata file in the 'data' directory
 (i.e. data/DvmtModel_ls.rda). The following 3 resource types are recognized:
 * txt - a vector of strings which are inserted as lines of text in a code block
 * fig - a png file which is inserted as an image
 * tab - a matrix or data frame which is inserted as a table
 The function also reads in the module specifications and creates
 tables that document user input files, data the module gets from the
 datastore, and the data the module produces that is saved in the datastore.
 This function is intended to be called in the R script which defines the
 module. It is placed near the end of the script (after the portions of the
 script which estimate module parameters and define the module specifications)
 so that it is run when the package is built. It may not properly in other
 contexts.


#### Value


 None. The function has the side effects of creating a 'vignettes'
 directory if one does not exist, copying identified 'fig' resources to the
 'vignettes' directory, and saving the markdown documentation file to the
 'vignettes' directory. The markdown file is named with the module name and
 has a 'md' suffix.


#### Calls
expandSpec, processModuleSpecs


### `getRegisteredGetSpecs`: Returns Get specifications for registered datasets.

#### Description


 `getRegisteredGetSpecs` a visioneval framework module developer function
 that returns a data frame of Get specifications for datasets in the
 VisionEval name registry.


#### Usage

```r
getRegisteredGetSpecs(Names_, Tables_, Groups_, NameRegistryDir = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Names_```     |     A character vector of the dataset names to get specifications for.
```Tables_```     |     A character vector of the tables that the datasets are a part of.
```Groups_```     |     A character vector of the groups that the tables are a part of.
```NameRegistryDir```     |     a string identifying the path to the directory where the name registry file is located.

#### Details


 The VisionEval name registry (VENameRegistry.json) keeps track of the
 dataset names created by all registered modules by reading in datasets
 specified in the module Inp specifications or by returning calculated
 datasets as specified in the module Set specifications. This function
 reads in the name registry and returns Get specifications for identified
 datasets.


#### Value


 A data frame containing the Get specifications for the identified
 datasets.


#### Calls



### `initDataList`: Initialize a list for data transferred to and from datastore

#### Description


 `initDataList` a visioneval framework module developer function that
 creates a list to be used for transferring data to and from the datastore.


#### Usage

```r
initDataList()
```


#### Details


 This function initializes a list to store data that is transferred from
 the datastore to a module or returned from a module to be saved in the
 datastore. The list has 3 named components (Global, Year, and BaseYear). This
 is the standard structure for data being passed to and from a module and the
 datastore.


#### Value


 A list that has 3 named list components: Global, Year, BaseYear


#### Calls



### `item`: Alias for list function.

#### Description


 `item` a visioneval framework module developer function that is an alias
 for the list function whose purpose is to make module specifications easier
 to read.


#### Usage

```r
item()
```


#### Details


 This function defines an alternate name for list. It is used in module
 specifications to identify data items in the Inp, Get, and Set portions of
 the specifications.


#### Value


 a list.


#### Calls



### `items`: Alias for list function.

#### Description


 `items` a visioneval framework module developer function that is
 an alias for the list function whose purpose is to make module specifications
 easier to read.


#### Usage

```r
items()
```


#### Details


 This function defines an alternate name for list. It is used in module
 specifications to identify a group of data items in the Inp, Get, and Set
 portions of the specifications.


#### Value


 a list.


#### Calls



### `loadPackageDataset`: Load a VisionEval package dataset

#### Description


 `loadPackageDataset` a visioneval framework module developer function
 which loads a dataset identified by name from the VisionEval package
 containing the dataset.


#### Usage

```r
loadPackageDataset(DatasetName)
```


#### Arguments

Argument      |Description
------------- |----------------
```DatasetName```     |     A string identifying the name of the dataset.

#### Details


 This function is used to load a dataset identified by name from the
 VisionEval package which contains the dataset. Using this function is the
 preferred alternative to hard-wiring the loading using package::dataset
 notation because it enables users to switch between module versions contained
 in different packages. For example, there may be different versions of the
 VEPowertrainsAndFuels package which have different default assumptions about
 light-duty vehicle powertrain mix and characteristics by model year. Using
 this function, the module developer only needs to identify the dataset name.
 The function uses DatasetsByPackage_df data frame in the model state list
 to identify the package which contains the dataset. It then retrieves and
 returns the dataset


#### Value


 The identified dataset.


#### Calls
getModelState


### `makeModelFormulaString`: Makes a string representation of a model equation.

#### Description


 `makeModelFormulaString` a visioneval framework module developer
 function that creates a string equivalent of a model equation.


#### Usage

```r
makeModelFormulaString(EstimatedModel)
```


#### Arguments

Argument      |Description
------------- |----------------
```EstimatedModel```     |     the return value of the 'lm' or 'glm' functions.

#### Details


 The return values of model estimation functions such as 'lm' and 'glm'
 contain a large amount of information in addition to the parameter estimates
 for the specified model. This is particularly the case when the estimation
 dataset is large. Most of this information is not needed to apply the model
 and including it can add substantially to the size of a package that includes
 several estimated models. All that is really needed to implement an estimated
 model is an equation of the model terms and estimated coefficients. This
 function creates a string representation of the model equation.


#### Value


 a string expression of the model equation.


#### Calls



### `processEstimationInputs`: Load estimation data

#### Description


 `processEstimationInputs` a visioneval framework module developer
 function that checks whether specified model estimation data meets
 specifications and returns the data in a data frame.


#### Usage

```r
processEstimationInputs(Inp_ls, FileName, ModuleName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Inp_ls```     |     A list that describes the specifications for the estimation file. This list must meet the framework standards for specification description.
```FileName```     |     A string identifying the file name. This is the file name without any path information. The file must located in the "inst/extdata" directory of the package.
```ModuleName```     |     A string identifying the name of the module the estimation data is being used in.

#### Details


 This function is used to check whether a specified CSV-formatted data file
 used in model estimation is correctly formatted and contains acceptable
 values for all the datasets contained within. The function checks whether the
 specified file exists in the "inst/extdata" directory. If the file does not
 exist, the function stops and transmits a standard error message that the
 file does not exist. If the file does exist, the function reads the file into
 the data frame and then checks whether it contains the specified columns and
 that the data meets all specifications. If any of the specifications are not
 met, the function stops and transmits an error message. If there are no
 data errors the function returns a data frame containing the data in the
 file.


#### Value


 A data frame containing the estimation data according to
 specifications with data types consistent with specifications and columns
 not specified removed. Execution stops if any errors are found. Error
 messages are printed to the console. Warnings are also printed to the console.


#### Calls
checkDataConsistency, expandSpec, Types


### `readVENameRegistry`: Reads the VisionEval name registry.

#### Description


 `readVENameRegistry` a visioneval framework module developer function
 that reads the VisionEval name registry and returns a list of data frames
 containing the Inp and Set specifications.


#### Usage

```r
readVENameRegistry(NameRegistryDir = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```NameRegistryDir```     |     a string identifying the path to the directory where the name registry file is located.

#### Details


 The VisionEval name registry (VENameRegistry.json) keeps track of the
 dataset names created by all registered modules by reading in datasets
 specified in the module Inp specifications or by returning calculated
 datasets as specified in the module Set specifications. This function reads
 the VisionEval name registry and returns a list of data frames containing the
 registered Inp and Set specifications.


#### Value


 A list having two components: Inp and Set. Each component is a data
 frame containing the respective Inp and Set specifications of registered
 modules.


#### Calls



### `testModule`: Test module

#### Description


 `testModule` a visioneval framework module developer function that sets
 up a test environment and tests a module.


#### Usage

```r
testModule(ModuleName, ParamDir = "defs",
  RunParamFile = "run_parameters.json", GeoFile = "geo.csv",
  ModelParamFile = "model_parameters.json", LoadDatastore = FALSE,
  SaveDatastore = TRUE, DoRun = TRUE, RunFor = "AllYears",
  StopOnErr = TRUE, RequiredPackages = NULL, TestGeoName = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleName```     |     A string identifying the module name.
```ParamDir```     |     A string identifying the location of the directory where the run parameters, model parameters, and geography definition files are located. The default value is defs. This directory should be located in the tests directory.
```RunParamFile```     |     A string identifying the name of the run parameters file. The default value is run_parameters.json.
```GeoFile```     |     A string identifying the name of the file which contains geography definitions.
```ModelParamFile```     |     A string identifying the name of the file which contains model parameters. The default value is model_parameters.json.
```LoadDatastore```     |     A logical value identifying whether to load an existing datastore. If TRUE, it loads the datastore whose name is identified in the run_parameters.json file. If FALSE it initializes a new datastore.
```SaveDatastore```     |     A logical value identifying whether the module outputs will be written to the datastore. If TRUE the module outputs are written to the datastore. If FALSE the outputs are not written to the datastore.
```DoRun```     |     A logical value identifying whether the module should be run. If FALSE, the function will initialize a datastore, check specifications, and load inputs but will not run the module but will return the list of module specifications. That setting is useful for module development in order to create the all the data needed to assist with module programming. It is used in conjunction with the getFromDatastore function to create the dataset that will be provided by the framework. The default value for this parameter is TRUE. In that case, the module will be run and the results will checked for consistency with the Set specifications.
```RunFor```     |     A string identifying what years the module is to be tested for. The value must be the same as the value that is used when the module is run in a module. Allowed values are 'AllYears', 'BaseYear', and 'NotBaseYear'.
```StopOnErr```     |     A logical identifying whether model execution should be stopped if the module transmits one or more error messages or whether execution should continue with the next module. The default value is TRUE. This is how error handling will ordinarily proceed during a model run. A value of FALSE is used when 'Initialize' modules in packages are run during model initialization. These 'Initialize' modules are used to check and preprocess inputs. For this purpose, the module will identify any errors in the input data, the 'initializeModel' function will collate all the data errors and print them to the log.
```RequiredPackages```     |     A character vector identifying any packages that must be installed in order to test the module because the module either has a soft reference to a module in the package (i.e. the Call spec only identifies the name of the module being called) or a soft reference to a dataset in the module (i.e. only identifies the name of the dataset). The default value is NULL.
```TestGeoName```     |     A character vector identifying the name of the geographic area for which data is to be loaded. This argument has effect only if the DoRun argument is FALSE. It enables the module developer to choose the geographic area data is to be loaded for when developing a module that is run for geography other than the region. For example if a module is run at the Azone level, the user can specify the name of the Azone that data is to be loaded for. If the name is misspecified an error will be flagged.

#### Details


 This function is used to set up a test environment and test a module to check
 that it can run successfully in the VisionEval model system. The function
 sets up the test environment by switching to the tests directory and
 initializing a model state list, a log file, and a datastore. The user may
 use an existing datastore rather than initialize a new datastore. The use
 case for loading an existing datastore is where a package contains several
 modules that run in sequence. The first module would initialize a datastore
 and then subsequent modules use the datastore that is modified by testing the
 previous module. When run this way, it is also necessary to set the
 SaveDatastore argument equal to TRUE so that the module outputs will be
 saved to the datastore. The function performs several tests including
 checking whether the module specifications are written properly, whether
 the the test inputs are correct and complete and can be loaded into the
 datastore, whether the datastore contains all the module inputs identified in
 the Get specifications, whether the module will run, and whether all of the
 outputs meet the module's Set specifications. The latter check is carried out
 in large part by the checkModuleOutputs function that is called.


#### Value


 If DoRun is FALSE, the return value is a list containing the module
 specifications. If DoRun is TRUE, there is no return value. The function
 writes out messages to the console and to the log as the testing proceeds.
 These messages include the time when each test starts and when it ends.
 When a key test fails, requiring a fix before other tests can be run,
 execution stops and an error message is written to the console. Detailed
 error messages are also written to the log.


#### Calls
assignDatastoreFunctions, checkDataset, checkModuleOutputs, checkModuleSpecs, createGeoIndexList, getFromDatastore, getModelState, getYears, initDatastoreGeography, initLog, initModelStateFile, inputsToDatastore, loadDatastore, loadModelParameters, processModuleInputs, processModuleSpecs, readGeography, readModelState, setInDatastore, setModelState, writeLog


### Appendix I: VisionEval Framework Control Functions


### `assignDatastoreFunctions`: Assign datastore interaction functions

#### Description


 `assignDatastoreFunctions` a visioneval framework control function that
 assigns the values of the functions for interacting with the datastore to the
 functions for the declared datastore type.


#### Usage

```r
assignDatastoreFunctions(DstoreType)
```


#### Arguments

Argument      |Description
------------- |----------------
```DstoreType```     |     A string identifying the datastore type.

#### Details


 The visioneval framework can work with different types of datastores. For
 example a datastore which stores datasets in an HDF5 file or a datastore
 which stores datasets as RData files in a directory hierarchy. This function
 reads the 'DatastoreType' parameter from the model state file and then
 assigns the common datastore interaction functions the values of the
 functions for the declared datastore type.


#### Value


 None. The function assigns datastore interactions functions to the
 first position of the search path.


#### Calls



### `checkDataConsistency`: Check data consistency with specification

#### Description


 `checkDataConsistency` a visioneval framework control function that
 checks whether data to be written to a dataset is consistent with the dataset
 attributes.


#### Usage

```r
checkDataConsistency(DatasetName, Data_, DstoreAttr_)
```


#### Arguments

Argument      |Description
------------- |----------------
```DatasetName```     |     A string identifying the dataset that is being checked.
```Data_```     |     A vector of values that may be of type integer, double, character, or logical.
```DstoreAttr_```     |     A named list where the components are the attributes of a dataset.

#### Details


 This function compares characteristics of data to be written to a dataset to
 the dataset attributes to determine whether they are consistent.


#### Value


 A list containing two components, Errors and Warnings. If no
 inconsistencies are found, both components will have zero-length character
 vectors. If there are one or more inconsistencies, then these components
 will hold vectors of error and warning messages. Mismatch between UNITS
 will produce a warning message. All other inconsistencies will produce
 error messages.


#### Calls
checkIsElementOf, checkMatchConditions, checkMatchType


### `checkDataset`: Check dataset existence

#### Description


 `checkDataset` a visioneval framework control function that checks
 whether a dataset exists in the datastore and returns a TRUE or FALSE value
 with an attribute of the full path to where the dataset should be located in
 the datastore.


#### Usage

```r
checkDataset(Name, Table, Group, DstoreListing_df)
```


#### Arguments

Argument      |Description
------------- |----------------
```Name```     |     a string identifying the dataset name.
```Table```     |     a string identifying the table the dataset is a part of.
```Group```     |     a string or numeric representation of the group the table is a part of.
```DstoreListing_df```     |     a dataframe which lists the contents of the datastore as contained in the model state file.

#### Details


 This function checks whether a dataset exists. The dataset is identified by
 its name and the table and group names it is in. If the dataset is not in the
 datastore, an error is thrown. If it is located in the datastore, the full
 path name to the dataset is returned.


#### Value


 A logical identifying whether the dataset is in the datastore. It has
 an attribute that is a string of the full path to where the dataset should be
 in the datastore.


#### Calls



### `checkGeography`: Check geographic specifications.

#### Description


 `checkGeography` a visioneval framework control function that checks
 geographic specifications file for model.


#### Usage

```r
checkGeography(Directory, Filename)
```


#### Arguments

Argument      |Description
------------- |----------------
```Directory```     |     A string identifying the path to the geographic specifications file.
```Filename```     |     A string identifying the name of the geographic specifications file.

#### Details


 This function reads the file containing geographic specifications for the
 model and checks the file entries to determine whether they are internally
 consistent. This function is called by the readGeography function.


#### Value


 A list having two components. The first component, 'Messages',
 contains a string vector of error messages. It has a length of 0 if there are
 no error messages. The second component, 'Update', is a list of components to
 update in the model state file. The components of this list include: Geo, a
 data frame that contains the geographic specifications; BzoneSpecified, a
 logical identifying whether Bzones are specified; and CzoneSpecified, a
 logical identifying whether Czones are specified.


#### Calls
writeLog


### `checkInputYearGeo`: Check years and geography of input file

#### Description


 `checkInputYearGeo` a visioneval framework control function that checks
 the 'Year' and 'Geo' columns of an input file to determine whether they are
 complete and have no duplications.


#### Usage

```r
checkInputYearGeo(Year_, Geo_, Group, Table)
```


#### Arguments

Argument      |Description
------------- |----------------
```Year_```     |     the vector extract of the 'Year' column from the input data.
```Geo_```     |     the vector extract of the 'Geo' column from the input data.
```Group```     |     a string identifying the 'GROUP' specification for the data sets contained in the input file.
```Table```     |     a string identifying the 'TABLE' specification for the data sets contained in the input file.

#### Details


 This function checks the 'Year' and 'Geo' columns of an input file to
 determine whether there are records for all run years specified for the
 model and for all geographic areas for the level of geography. It also checks
 for redundant year and geography entries.


#### Value


 A list containing the results of the check. The list has two
 mandatory components and two optional components. 'CompleteInput' is a
 logical that identifies whether records are present for all years and
 geographic areas. 'DupInput' identifies where are any redundant year and
 geography entries. If 'CompleteInput' is FALSE, the list contains a
 'MissingInputs' component that is a string identifying the missing year and
 geography records. If 'DupInput' is TRUE, the list contains a component that
 is a string identifying the duplicated year and geography records.


#### Calls
getModelState


### `checkIsElementOf`: Check if data values are in a specified set of values

#### Description


 `checkIsElementOf` a visioneval framework control function that checks
 whether a data vector contains any elements that are not in an allowed set of
 values.


#### Usage

```r
checkIsElementOf(Data_, SetElements_, DataName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_```     |     A vector of data of type integer, double, character, or logical.
```SetElements_```     |     A vector of allowed values.
```DataName```     |     A string identifying the field name of the data being compared (used for composing message identifying non-compliant fields).

#### Details


 This function is used to check whether categorical data values are consistent
 with the defined set of allowed values.


#### Value


 A character vector of messages which identify the data field and the
 condition that is not met. A zero-length vector is returned if none of the
 conditions are met.


#### Calls



### `checkMatchConditions`: Check values with conditions.

#### Description


 `checkMatchConditions` a visioneval framework control function that
 checks whether a data vector contains any elements that match a set of
 conditions.


#### Usage

```r
checkMatchConditions(Data_, Conditions_, DataName, ConditionType)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_```     |     A vector of data of type integer, double, character, or logical.
```Conditions_```     |     A character vector of valid R comparison expressions or an empty vector if there are no conditions.
```DataName```     |     A string identifying the field name of the data being compared (used for composing message identifying non-compliant fields).
```ConditionType```     |     A string having a value of either "PROHIBIT" or "UNLIKELY", the two data specifications which use conditions.

#### Details


 This function checks whether any of the values in a data vector match one or
 more conditions. The conditions are specified in a character vector where
 each element is either "NA" (to match for the existence of NA values) or a
 character representation of a valid R comparison expression for comparing
 each element with a specified value (e.g. "< 0", "> 1", "!= 10"). This
 function is used both for checking for the presence of prohibited values and
 for the presence of unlikely values.


#### Value


 A character vector of messages which identify the data field and the
 condition that is not met. A zero-length vector is returned if none of the
 conditions are met.


#### Calls



### `checkMatchType`: Check data type

#### Description


 `checkMatchType` a visioneval framework control function that checks
 whether the data type of a data vector is consistent with specifications.


#### Usage

```r
checkMatchType(Data_, Type, DataName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_```     |     A data vector.
```Type```     |     A string identifying the specified data type.
```DataName```     |     A string identifying the field name of the data being compared (used for composing message identifying non-compliant fields).

#### Details


 This function checks whether the data type of a data vector is consistent
 with a specified data type. An error message is generated if data can't be
 coerced into the specified data type without the possibility of error or loss
 of information (e.g. if a double is coerced to an integer). A warning message
 is generated if the specified type is 'character' but the input data type is
 'integer', 'double' or 'logical' since these can be coerced correctly, but
 that may not be what is intended (e.g. zone names may be input as numbers).
 Note that some modules may use NA inputs as a flag to identify case when
 result does not need to match a target. In this case, R will read in the type
 of data as logical. In this case, the function sets the data type to be the
 same as the specification for the data type so the function not flag a
 data type error.


#### Value


 A list having 2 components, Errors and Warnings. If no error or
 warning is identified, both components will contain a zero-length character
 string. If either an error or warning is identified, the relevant component
 will contain a character string that identifies the data field and the type
 mismatch.


#### Calls



### `checkModuleExists`: Check whether a module required to run a model is present

#### Description


 `checkModuleExists` a visioneval framework control function that checks
 whether a module required to run a model is present.


#### Usage

```r
checkModuleExists(ModuleName, PackageName,
  InstalledPkgs_ = rownames(installed.packages()), CalledBy = NA)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleName```     |     A string identifying the module name.
```PackageName```     |     A string identifying the package name.
```InstalledPkgs_```     |     A string vector identifying the names of packages that are installed.
```CalledBy```     |     A string vector having two named elements. The value of the 'Module' element is the name of the calling module. The value of the 'Package' element is the name of the package that the calling module is in.

#### Details


 This function takes a specified module and package, checks whether the
 package has been installed and whether the module is in the package. The
 function returns an error message is the package is not installed or if
 the module is not present in the package. If the module has been called by
 another module the value of the 'CalledBy' argument will be used to identify
 the calling module as well so that the user understands where the call is
 coming from.


#### Value


 TRUE if all packages and modules are present and FALSE if not.


#### Calls



### `checkModuleSpecs`: Checks all module specifications for completeness and for incorrect entries

#### Description


 `checkModuleSpecs` a visioneval framework control function that checks
 all module specifications for completeness and for proper values.


#### Usage

```r
checkModuleSpecs(Specs_ls, ModuleName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Specs_ls```     |     a module specifications list.
```ModuleName```     |     a string identifying the name of the module. This is used in the error messages to identify which module has errors.

#### Details


 This function iterates through all the specifications for a module and
 calls the checkSpec function to check each specification for completeness and
 for proper values.


#### Value


 A vector containing messages identifying any errors that are found.


#### Calls
checkSpec


### `checkSpec`: Checks a module specifications for completeness and for incorrect entries

#### Description


 `checkSpec` a visioneval framework control function that checks a single
 module specification for completeness and for proper values.


#### Usage

```r
checkSpec(Spec_ls, SpecGroup, SpecNum)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     a list containing the specifications for a single item in a module specifications list.
```SpecGroup```     |     a string identifying the specifications group the specification is in (e.g. RunBy, NewInpTable, NewSetTable, Inp, Get, Set). This is used in the error messages to identify which specification has errors.
```SpecNum```     |     an integer identifying which specification in the specifications group has errors.

#### Details


 This function checks whether a single module specification (i.e. the
 specification for a single dataset contains the minimum required
 attributes and that the values of the attributes are correct.


#### Value


 A vector containing messages identifying any errors that are found.


#### Calls
checkSpecTypeUnits, SpecRequirements


### `checkSpecConsistency`: Check specification consistency

#### Description


 `checkSpecConsistency` a visioneval framework control function that
 checks whether the specifications for a dataset are consistent with the data
 attributes in the datastore.


#### Usage

```r
checkSpecConsistency(Spec_ls, DstoreAttr_)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     a list of data specifications consistent with a module "Get" or "Set" specifications.
```DstoreAttr_```     |     a named list where the components are the attributes of a dataset.

#### Details


 This function compares the specifications for a dataset identified in a
 module "Get" or "Set" are consistent with the attributes for that data in the
 datastore.


#### Value


 A list containing two components, Errors and Warnings. If no
 inconsistencies are found, both components will have zero-length character
 vectors. If there are one or more inconsistencies, then these components
 will hold vectors of error and warning messages. Mismatch between UNITS
 will produce a warning message. All other inconsistencies will produce
 error messages.


#### Calls



### `checkSpecTypeUnits`: Checks the TYPE and UNITS and associated MULTIPLIER and YEAR attributes of a
 Inp, Get, or Set specification for consistency.

#### Description


 `checkSpecTypeUnits` a visioneval framework control function that checks
 correctness of TYPE, UNITS, MULTIPLIER and YEAR attributes of a specification
 that has been processed with the parseUnitsSpec function.


#### Usage

```r
checkSpecTypeUnits(Spec_ls, SpecGroup, SpecNum)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     a list for a single specification (e.g. a Get specification for a dataset) that has been processed with the parseUnitsSpec function to split the name, multiplier, and year elements of the UNITS specification.
```SpecGroup```     |     a string identifying the group that this specification comes from (e.g. Inp, Get, Set).
```SpecNum```     |     a number identifying which specification in the order of the SpecGroup. This is used to identify the subject specification if an error is identified.

#### Details


 This function checks whether the TYPE and UNITS of a module's specification
 contain errors. The check is done on a module specification in which the
 module's UNITS attribute has been parsed by the parseUnitsSpec function to
 split the name, multiplier, and years parts of the UNITS attribute. The TYPE
 is checked against the types catalogued in the Types function. The units name
 in the UNITS attribute is checked against the units names corresponding to
 each type catalogued in the Types function. The MULTIPLIER is checked to
 determine whether a value is a valid number, NA, or not a number (NaN). A NA
 value means that no multiplier was specified (this is OK) a NaN value means
 that a multiplier that is not a number was specified which is an error. The
 YEAR attribute is checked to determine whether there is a proper
 specification if the specified TYPE is currency. If the TYPE is currency, a
 YEAR must be specified for Get and Set specifications.


#### Value


 A vector containing messages identifying any errors that are found.


#### Calls
checkUnits, Types


### `checkTableExistence`: Check whether table exists in the datastore

#### Description


 `checkTableExistence` a visioneval framework control function that
 checks whether a table is present in the datastore.


#### Usage

```r
checkTableExistence(Table, Group, DstoreListing_df)
```


#### Arguments

Argument      |Description
------------- |----------------
```Table```     |     a string identifying the table.
```Group```     |     a string or numeric representation of the group the table is a part of.
```DstoreListing_df```     |     a dataframe which lists the contents of the datastore as contained in the model state file.

#### Details


 This function checks whether a table is present in the datastore.


#### Value


 A logical identifying whether a table is present in the datastore.


#### Calls



### `checkUnits`: Check measurement units for consistency with recognized units for stated type.

#### Description


 `checkUnits` a visioneval framework control function that checks the
 specified UNITS for a dataset for consistency with the recognized units for
 the TYPE specification for the dataset. It also splits compound units into
 elements.


#### Usage

```r
checkUnits(DataType, Units)
```


#### Arguments

Argument      |Description
------------- |----------------
```DataType```     |     a string which identifies the data type as specified in the TYPE attribute for a data set.
```Units```     |     a string identifying the measurement units as specified in the UNITS attribute for a data set after processing with the parseUnitsSpec function.

#### Details


 The visioneval code recognizes 4 simple data types (integer, double, logical,
 and character) and 9 complex data types (e.g. distance, time, mass).
 The simple data types can have any units of measure, but the complex data
 types must use units of measure that are declared in the Types() function. In
 addition, there is a compound data type that can have units that are composed
 of the units of two or more complex data types. For example, speed is a
 compound data type composed of distance divided by speed. With this example,
 speed in miles per hour would be represented as MI/HR. This function checks
 the UNITS specification for a dataset for consistency with the recognized
 units for the given data TYPE. To check the units of a compound data type,
 the function splits the units into elements and the operators that separate
 the elements. It identifies the element units, the complex data type for each
 element and the operators that separate the elements.


#### Value


 A list which contains the following elements:
 DataType: a string identifying the data type.
 UnitType: a string identifying whether the units correspond to a 'simple'
 data type, a 'complex' data type, or a 'compound' data type.
 Units: a string identifying the units.
 Elements: a list containing the elements of a compound units. Components of
 this list are:
 Types: the complex type of each element,
 Units: the units of each element,
 Operators: the operators that separate the units.
 Errors: a string containing an error message or character(0) if no error.


#### Calls
Types


### `convertMagnitude`: Convert values between different magnitudes.

#### Description


 `convertMagnitude` a visioneval framework control function that
 converts values between different magnitudes such as between dollars and
 thousands of dollars.


#### Usage

```r
convertMagnitude(Values_, FromMagnitude, ToMagnitude)
```


#### Arguments

Argument      |Description
------------- |----------------
```Values_```     |     a numeric vector of values to convert from one unit to another.
```FromMagnitude```     |     a number or string identifying the magnitude of the units of the input Values_.
```ToMagnitude```     |     a number or string identifying the magnitude to convert the Values_ to.

#### Details


 The visioneval framework stores all quantities in single units to be
 unambiguous about the data contained in the datastore. For example,  total
 income for a region would be stored in dollars rather than in thousands of
 dollars or millions of dollars. However, often inputs for large quantities
 are expressed in thousands or millions. Also submodels may be estimated using
 values expressed in multiples, or they might produce results that are
 multiples. Where that is the case, the framework enables model users and
 developers to encode the data multiplier in the input file field name or the
 UNITS specification. The framework functions then use that information to
 convert units to and from the single units stored in the datastore. This
 function implements the conversion. The multiplier must be specified in
 scientific notation used in R with the additional constraint that the digit
 term must be 1. For example, a multiplier of 1000 would be represented as
 1e3. The multiplier is separated from the units name by a period (.). For
 example if the units of a dataset to be retrieved from the datastore are
 thousands of miles, the UNITS specification would be written as 'MI.1e3'.


#### Value


 A numeric vector of values corresponding the the input Values_ but
 converted from the magnitude identified in the FromMagnitude argument to the
 magnitude identified in the ToMagnitude argument. If either the FromMagnitude
 or the ToMagnitude arguments is NA, the original Values_ are returned. The
 Converted attribute of the returned values is FALSE. Otherwise the conversion
 is done and the Converted attribute of the returned values is TRUE.


#### Calls



### `convertUnits`: Convert values between units of measure.

#### Description


 `convertUnits` a visioneval framework control function that
 converts values between different units of measure for complex and compound
 data types recognized by the visioneval code.


#### Usage

```r
convertUnits(Values_, DataType, FromUnits, ToUnits = "default")
```


#### Arguments

Argument      |Description
------------- |----------------
```Values_```     |     a numeric vector of values to convert from one unit to another.
```DataType```     |     a string identifying the data type.
```FromUnits```     |     a string identifying the units of measure of the Values_.
```ToUnits```     |     a string identifying the units of measure to convert the Values_ to. If the ToUnits are 'default' the Values_ are converted to the default units for the model.

#### Details


 The visioneval code recognizes 4 simple data types (integer, double, logical,
 and character) and 9 complex data types (e.g. distance, time, mass). The
 simple data types can have any units of measure, but the complex data types
 must use units of measure that are declared in the Types() function. In
 addition, there is a compound data type that can have units that are composed
 of the units of two or more complex data types. For example, speed is a
 compound data type composed of distance divided by speed. With this example,
 speed in miles per hour would be represented as MI/HR. This function converts
 a vector of values from one unit of measure to another unit of measure. For
 compound data type it combines multiple unit conversions. The framework
 converts units based on the default units declared in the 'units.csv' model
 definition file and in UNITS specifications declared in modules.


#### Value


 A list containing the converted values and additional information as
 follows:
 Values - a numeric vector containing the converted values.
 FromUnits - a string representation of the units converted from.
 ToUnits - a string representation of the units converted to.
 Errors - a string containing an error message or character(0) if no errors.
 Warnings - a string containing a warning message or character(0) if no
 warning.


#### Calls
checkUnits, getUnits, Types


### `createGeoIndex`: Create datastore index.

#### Description


 `createIndex` a visioneval framework control function that creates an
 index for reading or writing module data to the datastore.


#### Usage

```r
createGeoIndex(Table, Group, RunBy, Geo, GeoIndex_ls)
```


#### Arguments

Argument      |Description
------------- |----------------
```Table```     |     A string identifying the name of the table the index is being created for.
```Group```     |     A string identifying the name of the group where the table is located in the datastore.
```RunBy```     |     A string identifying the level of geography the module is being run at (e.g. Azone).
```Geo```     |     A string identifying the geographic unit to create the index for (e.g. the name of a particular Azone).
```GeoIndex_ls```     |     a list of geographic indices used to determine the positions to extract from a dataset corresponding to the specified geography.

#### Details


 This function creates indexing functions which return an index to positions
 in datasets that correspond to positions in an index field of a table. For
 example if the index field is 'Azone' in the 'Household' table, this function
 will return a function that when provided the name of a particular Azone,
 will return the positions corresponding to that Azone.


#### Value


 A function that creates a vector of positions corresponding to the
 location of the supplied value in the index field.


#### Calls



### `createGeoIndexList`: Create a list of geographic indices for all tables in a datastore.

#### Description


 `createGeoIndexList` a visioneval framework control function that
 creates a list containing the geographic indices for tables in the operating
 datastore for identified tables.


#### Usage

```r
createGeoIndexList(Specs_ls, RunBy, RunYear)
```


#### Arguments

Argument      |Description
------------- |----------------
```Specs_ls```     |     A 'Get' or 'Set' specifications list for a module.
```RunBy```     |     The value of the RunBy specification for a module.
```RunYear```     |     A string identifying the model year that is being run.

#### Details


 This function takes a 'Get' or 'Set' specifications list for a module and the
 'RunBy' specification and returns a list which has a component for each table
 identified in the specifications. Each component includes all geographic
 datasets for the table.


#### Value


 A list that contains a component for each table identified in the
 specifications in which each component includes all the geographic datasets
 for the table represented by the component.


#### Calls
getModelState


### `deflateCurrency`: Convert currency values to different years.

#### Description


 `deflateCurrency` a visioneval framework control function that
 converts currency values between different years of measure.


#### Usage

```r
deflateCurrency(Values_, FromYear, ToYear)
```


#### Arguments

Argument      |Description
------------- |----------------
```Values_```     |     a numeric vector of values to convert from one currency year to another.
```FromYear```     |     a number or string identifying the currency year of the input Values_.
```ToYear```     |     a number or string identifying the currency year to convert the Values_ to.

#### Details


 The visioneval framework stores all currency values in the base year real
 currency (e.g. dollar) values. However, currency inputs may be in different
 nominal year currency. Also modules may be estimated using different nominal
 year currency data. For example, the original vehicle travel model in
 GreenSTEP used 2001 NHTS data while the newer model uses 2009 NHTS data. The
 framework enables model uses to specify the currency year in the field name
 of an input file that contains currency data. Likewise, the currency year can
 be encoded in the UNIT attributes for a modules Get and Set specifications.
 The framework converts dollars to and from specified currency year values and
 base year real dollar values. The model uses a set of deflator values that
 the user inputs for the region to make the adjustments. These values are
 stored in the model state list.


#### Value


 A numeric vector of values corresponding the the input Values_ but
 converted from the currency year identified in the FromYear argument to the
 currency year identified in the ToYear argument. If either the FromYear or
 the ToYear arguments is unaccounted for in the deflator series, the original
 Values_ are returned with a Converted attribute of FALSE. Otherwise the
 conversion is done and the Converted attribute of the returned values is TRUE.


#### Calls
getModelState


### `doProcessInpSpec`: Filters Inp specifications list based on OPTIONAL specification attributes.

#### Description


 `doProcessInpSpec` a visioneval framework control function that filters
 out Inp specifications whose OPTIONAL specification attribute is TRUE but the
 specified input file is not present.


#### Usage

```r
doProcessInpSpec(InpSpecs_ls, InputDir = "inputs")
```


#### Arguments

Argument      |Description
------------- |----------------
```InpSpecs_ls```     |     A standard specifications list for Inp specifications.
```InputDir```     |     The path to the input directory.

#### Details


 An Inp specification component may have an OPTIONAL specification whose value
 is TRUE. If so, and if the specified input file is present, then the input
 specification needs to be processed. This function checks whether the
 OPTIONAL specification is present, whether its value is TRUE, and whether the
 file exists. If all of these are true, then the input specification needs to
 be processed. The input specification also needs to be processed if it is
 not optional. A specification is not optional if the OPTIONAL attribute is
 not present or if it is present and the value is not TRUE. The function
 returns a list of all the Inp specifications that meet these criteria.


#### Value


 A list containing the Inp specification components that meet the
 criteria of either not being optional or being optional and the specified
 input file is present.


#### Calls



### `expandSpec`: Expand a Inp, Get, or Set specification so that is can be used by other
 functions to process inputs and to read from or write to the datastore.

#### Description


 `expandSpec` a visioneval framework control function that takes a Inp,
 Get, or Set specification and processes it to be in a form that can be used
 by other functions which use the specification in processing inputs or
 reading from or writing to the datastore. The parseUnitsSpec function is
 called to parse the UNITS attribute to extract name, multiplier, and year
 values. When the specification has multiple values for the NAME attribute,
 the function creates a specification for each name value.


#### Usage

```r
expandSpec(SpecToExpand_ls, ComponentName)
```


#### Arguments

Argument      |Description
------------- |----------------
```SpecToExpand_ls```     |     A standard specifications list for a specification whose NAME attribute has multiple values.
```ComponentName```     |     A string that is the name of the specifications that the specification is a part of (e.g. "Inp", "Get", "Set").

#### Details


 The VisionEval design allows module developers to assign multiple values to
 the NAME attributes of a Inp, Get, or Set specification where the other
 attributes for those named datasets (or fields) are the same. This greatly
 reduces duplication and the potential for error in writing module
 specifications. However, other functions that check or use the specifications
 are not capable of handling specifications which have NAME attributes
 containing multiple values. This function expands a specification with
 multiple values for a  NAME attribute into multiple specifications, each with
 a single value for the NAME attribute. In addition, the function calls the
 parseUnitsSpec function to extract multiplier and year information from the
 value of the UNITS attribute. See that function for details.


#### Value


 A list of standard specifications lists which has a component for
 each value in the NAME attribute of the input specifications list.


#### Calls
parseUnitsSpec


### `findSpec`: Find the full specification corresponding to a defined NAME, TABLE, and GROUP

#### Description


 `findSpec` a visioneval framework control function that returns the full
 dataset specification for defined NAME, TABLE, and GROUP.


#### Usage

```r
findSpec(Specs_ls, Name, Table, Group)
```


#### Arguments

Argument      |Description
------------- |----------------
```Specs_ls```     |     a standard specifications list for 'Inp', 'Get', or 'Set'
```Name```     |     a string for the name of the dataset
```Table```     |     a string for the table that the dataset resides in
```Group```     |     a string for the generic group that the table resides in

#### Details


 This function finds and returns the full specification from a specifications
 list whose NAME, TABLE and GROUP values correspond to the Name, Table, and
 Group argument values. The specifications list must be in standard format and
 must be for only 'Inp', 'Get', or 'Set' specifications.


#### Value


 A list containing the full specifications for the dataset


#### Calls



### `getDatasetAttr`: Get attributes of a dataset

#### Description


 `getDatasetAttr` a visioneval framework control function that retrieves
 the attributes for a dataset in the datastore.


#### Usage

```r
getDatasetAttr(Name, Table, Group, DstoreListing_df)
```


#### Arguments

Argument      |Description
------------- |----------------
```Name```     |     a string identifying the dataset name.
```Table```     |     a string identifying the table the dataset is a part of.
```Group```     |     a string or numeric representation of the group the table is a part of.
```DstoreListing_df```     |     a dataframe which lists the contents of the datastore as contained in the model state file.

#### Details


 This function extracts the listed attributes for a specific dataset from the
 datastore listing.


#### Value


 A named list of the dataset attributes.


#### Calls



### `getFromDatastore`: Retrieve data identified in 'Get' specifications from datastore

#### Description


 `getFromDatastore` a visioneval framework control function that
 retrieves datasets identified in a module's 'Get' specifications from the
 datastore.


#### Usage

```r
getFromDatastore(ModuleSpec_ls, RunYear, Geo = NULL,
  GeoIndex_ls = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleSpec_ls```     |     a list of module specifications that is consistent with the VisionEval requirements
```RunYear```     |     a string identifying the model year being run. The default is the Year object in the global workspace.
```Geo```     |     a string identifying the name of the geographic area to get the data for. For example, if the module is specified to be run by Azone, then Geo would be the name of a particular Azone.
```GeoIndex_ls```     |     a list of geographic indices used to determine the positions to extract from a dataset corresponding to the specified geography.

#### Details


 This function retrieves from the datastore all of the data sets identified in
 a module's 'Get' specifications. If the module's specifications include the
 name of a geographic area, then the function will retrieve the data for that
 geographic area.


#### Value


 A list containing all the data sets specified in the module's
 'Get' specifications for the identified geographic area.


#### Calls
checkDataset, convertMagnitude, convertUnits, createGeoIndex, deflateCurrency, getDatasetAttr, getModelState, initDataList, readModelState, Types


### `getModelState`: Get values from model state list.

#### Description


 `getModelState` a visioneval framework control function that reads
 components of the list that keeps track of the model state.


#### Usage

```r
getModelState(Names_ = "All")
```


#### Arguments

Argument      |Description
------------- |----------------
```Names_```     |     A string vector of the components to extract from the ModelState_ls list.

#### Details


 Key variables that are important for managing the model run are stored in a
 list (ModelState_ls) that is managed in the global environment. This
 function extracts named components of the list.


#### Value


 A list containing the specified components from the model state file.


#### Calls



### `getModuleSpecs`: Retrieve module specifications from a package

#### Description


 `getModuleSpecs` a visioneval framework control function that retrieves
 the specifications list for a module and returns the specifications list.


#### Usage

```r
getModuleSpecs(ModuleName, PackageName)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleName```     |     A string identifying the name of the module.
```PackageName```     |     A string identifying the name of the package that the module is in.

#### Details


 This function loads the specifications for a module in a package. It returns
 the specifications list.


#### Value


 A specifications list that is the same as the specifications list
 defined for the module in the package.


#### Calls



### `getUnits`: Retrieve default units for model

#### Description


 `getUnits` a visioneval framework control function that retrieves the
 default model units for a vector of complex data types.


#### Usage

```r
getUnits(Type_)
```


#### Arguments

Argument      |Description
------------- |----------------
```Type_```     |     A string vector identifying the complex data type(s).

#### Details


 This is a convenience function to make it easier to retrieve the default
 units for a complex data type (e.g. distance, volume, speed). The default
 units are the units used to store the complex data type in the datastore.


#### Value


 A string vector identifying the default units for the complex data
 type(s) or NA if any of the type(s) are not defined.


#### Calls
getModelState


### `initDatastoreGeography`: Initialize datastore geography.

#### Description


 `initDatastoreGeography` a visioneval framework control function that
 initializes tables and writes datasets to the datastore which describe
 geographic relationships of the model.


#### Usage

```r
initDatastoreGeography()
```


#### Details


 This function writes tables to the datastore for each of the geographic
 levels. These tables are then used during a model run to store values that
 are either specified in scenario inputs or that are calculated during a model
 run. The function populates the tables with cross-references between
 geographic levels. The function reads the model geography (Geo_df) from the
 model state file. Upon successful completion, the function calls the
 listDatastore function to update the datastore listing in the global list.


#### Value


 The function returns TRUE if the geographic tables and datasets are
 sucessfully written to the datastore.


#### Calls
getModelState, writeLog


### `initLog`: Initialize run log.

#### Description


 `initLog` a visioneval framework control function that creates a log
 (text file) that stores messages generated during a model run.


#### Usage

```r
initLog(Suffix = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Suffix```     |     A character string appended to the file name for the log file. For example, if the suffix is 'CreateHouseholds', the log file is named 'Log_CreateHouseholds.txt'. The default value is NULL in which case the suffix is the date and time.

#### Details


 This function creates a log file that is a text file which stores messages
 generated during a model run. The name of the log is 'Log <date> <time>'
 where '<date>' is the initialization date and '<time>' is the initialization
 time. The log is initialized with the scenario name, scenario description and
 the date and time of initialization.


#### Value


 TRUE if the log is created successfully. It creates a log file in the
 working directory and identifies the name of the log file in the
 model state file.


#### Calls
getModelState, setModelState


### `initModelStateFile`: Initialize model state.

#### Description


 `initModelState` a visioneval framework control function that loads
 model run parameters into the model state list in the global workspace and
 saves as file.


#### Usage

```r
initModelStateFile(Dir = "defs", ParamFile = "run_parameters.json",
  DeflatorFile = "deflators.csv", UnitsFile = "units.csv")
```


#### Arguments

Argument      |Description
------------- |----------------
```Dir```     |     A string identifying the name of the directory where the global parameters, deflator, and default units files are located. The default value is defs.
```ParamFile```     |     A string identifying the name of the global parameters file. The default value is parameters.json.
```DeflatorFile```     |     A string identifying the name of the file which contains deflator values by year (e.g. consumer price index). The default value is deflators.csv.
```UnitsFile```     |     A string identifying the name of the file which contains default units for complex data types (e.g. currency, distance, speed, etc.). The default value is units.csv.

#### Details


 This function creates the model state list and loads model run parameters
 recorded in the 'parameters.json' file into the model state list. It also
 saves the model state list in a file (ModelState.Rda).


#### Value


 TRUE if the model state list is created and file is saved. It creates
 the model state list and loads parameters recorded in the 'parameters.json'
 file into the model state lists and saves a model state file.


#### Calls



### `inputsToDatastore`: Write the datasets in a list of module inputs that have been processed to the
 datastore.

#### Description


 `inputsToDatastore` a visioneval framework control function that takes a
 list of processed module input files and writes the datasets to the
 datastore.


#### Usage

```r
inputsToDatastore(Inputs_ls, ModuleSpec_ls, ModuleName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Inputs_ls```     |     a list processes module inputs as created by the 'processModuleInputs' function.
```ModuleSpec_ls```     |     a list of module specifications that is consistent with the VisionEval requirements.
```ModuleName```     |     a string identifying the name of the module (used to document the dataset in the datastore).

#### Details


 This function takes a processed list of input datasets specified by a module
 created by the application of the 'processModuleInputs' function and writes
 the datasets in the list to the datastore.


#### Value


 A logical indicating successful completion. Most of the outputs of
 the function are the side effects of writing data to the datastore.


#### Calls
findSpec, getModelState, processModuleSpecs, sortGeoTable


### `loadDatastore`: Load saved datastore.

#### Description


 `loadDatastore` a visioneval framework control function that copies an
 existing saved datastore and writes information to run environment.


#### Usage

```r
loadDatastore(FileToLoad, Dir = "defs/", GeoFile, SaveDatastore = TRUE)
```


#### Arguments

Argument      |Description
------------- |----------------
```FileToLoad```     |     A string identifying the full path name to the saved datastore. Path name can either be relative to the working directory or absolute.
```Dir```     |     A string identifying the path of the geography definition file (GeoFile), default to 'defs' relative to the working directory
```GeoFile```     |     A string identifying the name of the geography definition file (see 'readGeography' function) that is consistent with the saved datastore. The geography definition file must be located in the 'defs' directory.
```SaveDatastore```     |     A logical identifying whether an existing datastore will be saved. It is renamed by appending the system time to the name. The default value is TRUE.

#### Details


 This function copies a saved datastore as the working datastore attributes
 the global list with related geographic information. This function enables
 scenario variants to be built from a constant set of starting conditions.


#### Value


 TRUE if the datastore is loaded. It copies the saved datastore to
 working directory as 'datastore.h5'. If a 'datastore.h5' file already
 exists, it first renames that file as 'archive-datastore.h5'. The function
 updates information in the model state file regarding the model geography
 and the contents of the loaded datastore. If the stored file does not exist
 an error is thrown.


#### Calls
getModelState, setModelState, writeLog


### `loadModelParameters`: Load model global parameters file into datastore.

#### Description


 `loadModelParameters` a visioneval framework control function reads the
 'model_parameters.json' file and stores the contents in the 'Global/Model'
 group of the datastore.


#### Usage

```r
loadModelParameters(ModelParamFile = "model_parameters.json")
```


#### Arguments

Argument      |Description
------------- |----------------
```ModelParamFile```     |     A string identifying the name of the parameter file. The default value is 'model_parameters.json'.

#### Details


 This function reads the 'model_parameters.json' file in the 'defs' directory
 which contains parameters specific to a model rather than to a module. These
 area parameters that may be used by any module. Parameters are specified by
 name, value, and data type. The function creates a 'Model' group in the
 'Global' group and stores the values of the appropriate type in the 'Model'
 group.


#### Value


 The function returns TRUE if the model parameters file exists and
 its values are sucessfully written to the datastore.


#### Calls
getModelState, writeLog


### `parseInputFieldNames`: Parse field names of input file to separate out the field name, currency
 year, and multiplier.

#### Description


 `parseInputFieldNames` a visioneval framework control function that
 parses the field names of an input file to separate out the field name,
 currency year (if data is currency type), and value multiplier.


#### Usage

```r
parseInputFieldNames(FieldNames_, Specs_ls, FileName)
```


#### Arguments

Argument      |Description
------------- |----------------
```FieldNames_```     |     A character vector containing the field names of an input file.
```Specs_ls```     |     A list of specifications for fields in the input file.
```FileName```     |     A string identifying the name of the file that the field names are from. This is used for writing error messages.

#### Details


 The field names of input files can be used to encode more information than
 the name itself. It can also encode the currency year for currency type data
 and also if the values are in multiples (e.g. thousands of dollars). For
 currency type data it is mandatory that the currency year be specified so
 that the data can be converted to base year currency values (e.g. dollars in
 base year dollars). The multiplier is optional, but needless to say, it can
 only be applied to numeric data. The function returns a list with a component
 for each field. Each component identifies the field name, year, multiplier,
 and error status for the result of parsing the field name. If the field name
 was parsed successfully, the error status is character(0). If the field name
 was not successfully parsed, the error status contains an error message,
 identifying the problem.


#### Value


 A named list with one component for each field. Each component is a list
 having 4 named components: Error, Name, Year, Multiplier. The Error
 component has a value of character(0) if there are no errors or a character
 vector of error messages if there are errors. The Name component is a string
 with the name of the field. The Year component is a string with the year
 component if the data type is currency or NA if the data type is not currency
 or if the Year component has an invalid value. The Multiplier is a number if
 the multiplier component is present and is valid. It is NA if there is no
 multiplier component and NaN if the multiplier is invalid. Each component of
 the list is named with the value of the Name component (i.e. the field name
 without the year and multiplier elements.)


#### Calls
getModelState


### `parseModelScript`: Parse model script.

#### Description


 `parseModel` a visioneval framework control function that reads and
 parses the model script to identify the sequence of module calls and the
 associated call arguments.


#### Usage

```r
parseModelScript(FilePath = "run_model.R", TestMode = FALSE)
```


#### Arguments

Argument      |Description
------------- |----------------
```FilePath```     |     A string identifying the relative or absolute path to the model run script is located.
```TestMode```     |     A logical identifying whether the function is to run in test mode. When in test mode the function returns the parsed script but does not change the model state or write results to the log.

#### Details


 This function reads in the model run script and parses the script to
 identify the sequence of module calls. It extracts each call to 'runModule'
 and identifies the values assigned to the function arguments. It creates a
 list of the calls with their arguments in the order of the calls in the
 script.


#### Value


 A data frame containing information on the calls to 'runModule' in the
 order of the calls. Each row represents a module call in order. The columns
 identify the 'ModuleName', the 'PackageName', and the 'RunFor' value.


#### Calls
setModelState, writeLog


### `parseUnitsSpec`: Parse units specification into components and add to specifications list.

#### Description


 `parseUnitsSpec` a visioneval framework control function that parses the
 UNITS attribute of a standard Inp, Get, or Set specification for a dataset to
 identify the units name, multiplier, and year for currency data. Returns a
 modified specifications list whose UNITS value is only the units name, and
 includes a MULTIPLIER attribute and YEAR attribute.


#### Usage

```r
parseUnitsSpec(Spec_ls, ComponentName)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     A standard specifications list for a Inp, Get, or Set item.
```ComponentName```     |     A string that is the name of the specifications the the specification comes from (e.g. "Inp", "Get", "Set).

#### Details


 The UNITS component of a specifications list can encode information in
 addition to the units name. This includes a value units multiplier and in
 the case of currency values the year for the currency measurement. The
 multiplier element can only be expressed in scientific notation where the
 number before the 'e' can only be 1. If the year element for a currency
 specification is missing, it is replaced by the model base year which is
 recorded in the model state file. If this is done, a WARN attribute is added
 to the specifications list notifying the module developer that there is no
 year element and the model base year will be used when the module is called.
 The test module function reads this warning and writes it to the module test
 log. This way the module developer is made aware of the situation so that it
 may be corrected if necessary. The model user is not bothered by the warning.


#### Value


 a list that is a standard specifications list with the addition of
 a MULTIPLIER component and a YEAR component as well as a modification of the
 UNIT component. The MULTIPLIER component can have the value of NA, a number,
 or NaN. The value is NA if the multiplier is missing. It is a number if the
 multiplier is a valid number. The value is NaN if the multiplier is not a
 valid number. The YEAR component is a character string that is a 4-digit
 representation of a year or NA if the component is not a proper year. If the
 year component is missing from the UNITS specification for currency data,
 the model base year is substituted. In that case, a WARN attribute is added
 to the returned specifications list. This is read by the testModule function
 and written to the module test log to notify the module developer. After the
 UNITS component has been parsed and the YEAR and MULTIPLIER components
 extracted, the UNITS component is modified to only be the units name.


#### Calls
getModelState


### `processModuleInputs`: Process module input files

#### Description


 `processModuleInputs` a visioneval framework control function that
 processes input files identified in a module's 'Inp' specifications in
 preparation for saving in the datastore.


#### Usage

```r
processModuleInputs(ModuleSpec_ls, ModuleName, Dir = "inputs")
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleSpec_ls```     |     a list of module specifications that is consistent with the VisionEval requirements.
```ModuleName```     |     a string identifying the name of the module (used to document module in error messages).
```Dir```     |     a string identifying the relative path to the directory where the model inputs are contained.

#### Details


 This function processes the input files identified in a module's 'Inp'
 specifications in preparation for saving the data in the datastore. Several
 processes are carried out. The existence of each specified input file is
 checked. Any file whose corresponding 'GROUP' specification is 'Year', is
 checked to determine that it has 'Year' and 'Geo' columns. The entries in the
 'Year' and 'Geo' columns are checked to make sure they are complete and there
 are no duplicates. Any file whose 'GROUP' specification is 'Global' or
 'BaseYear' and whose 'TABLE' specification is a geographic specification
 other than 'Region' is checked to determine if it has a 'Geo' column and the
 entries are checked for completeness. The data in each column are checked
 against specifications to determine conformance. The function returns a list
 which contains a list of error messages and a list of the data inputs. The
 function also writes error messages and warnings to the log file.


#### Value


 A list containing the results of the input processing. The list has
 two components. The first (Errors) is a vector of identified file and data
 errors. The second (Data) is a list containing the data in the input files
 organized in the standard format for data exchange with the datastore.


#### Calls
checkDataConsistency, checkInputYearGeo, convertMagnitude, convertUnits, deflateCurrency, getModelState, initDataList, parseInputFieldNames, Types, writeLog


### `processModuleSpecs`: Process module specifications to expand items with multiple names.

#### Description


 `processModuleSpecs` a visioneval framework control function that
 processes a full module specifications list, expanding all elements in the
 Inp, Get, and Set components by parsing the UNITS attributes and duplicating
 every specification which has multiple values for the NAME attribute.


#### Usage

```r
processModuleSpecs(Spec_ls)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     A specifications list.

#### Details


 This function process a module specification list. If any of the
 specifications include multiple listings of data sets (i.e. fields) in a
 table, this function expands the listing to establish a separate
 specification for each data set.


#### Value


 A standard specifications list with expansion of the multiple item
 specifications.


#### Calls
doProcessInpSpec, expandSpec, getModelState


### `readGeography`: Read geographic specifications.

#### Description


 `readGeography` a visioneval framework control function that reads the
 geographic specifications file for the model.


#### Usage

```r
readGeography(Dir = "defs", GeoFile = "geo.csv")
```


#### Arguments

Argument      |Description
------------- |----------------
```Dir```     |     A string identifying the path to the geographic specifications file. Note: don't include the final separator in the path name 'e.g. not defs/'.
```GeoFile```     |     A string identifying the name of the geographic specifications file. This is a csv-formatted text file which contains columns named 'Azone', 'Bzone', 'Czone', and 'Marea'. The 'Azone' column must have zone names in all rows. The 'Bzone' and 'Czone' columns can be unspecified (NA in all rows) or may have have unique names in every row. The 'Marea' column (referring to metropolitan areas) identifies metropolitan areas corresponding to the most detailed level of specified geography (or 'None' no metropolitan area occupies any portion of the zone.

#### Details


 This function manages the reading and error checking of geographic
 specifications for the model. It calls the checkGeography function to check
 for errors in the specifications. The checkGeography function reads in the
 file and checks for errors. It returns a list of any errors that are found
 and a data frame containing the geographic specifications. If errors are
 found, the functions writes the errors to a log file and stops model
 execution. If there are no errors, the function adds the geographic in the
 geographic specifications file, the errors are written to the log file and
 execution stops. If no errors are found, the geographic specifications are
 added to the model state file.


#### Value


 The value TRUE is returned if the function is successful at reading
 the file and the specifications are consistent. It stops if there are any
 errors in the specifications. All of the identified errors are written to
 the run log. A data frame containing the file entries is added to the
 model state file as Geo_df'.


#### Calls
checkGeography, setModelState, writeLog


### `readModelState`: Reads values from model state file.

#### Description


 `readModelState` a visioneval framework control function that reads
 components of the file that saves a copy of the model state.


#### Usage

```r
readModelState(Names_ = "All", FileName = "ModelState.Rda")
```


#### Arguments

Argument      |Description
------------- |----------------
```Names_```     |     A string vector of the components to extract from the ModelState_ls list.
```FileName```     |     A string vector with the full path name of the model state file.

#### Details


 The model state is stored in a list (ModelState_ls) that is also saved as a
 file (ModelState.Rda) whenever the list is updated. This function reads the
 contents of the ModelState.Rda file.


#### Value


 A list containing the specified components from the model state file.


#### Calls



### `setInDatastore`: Save the data sets returned by a module in the datastore

#### Description


 `setInDatastore` a visioneval framework control function saves to the
 datastore the data returned in a standard list by a module.


#### Usage

```r
setInDatastore(Data_ls, ModuleSpec_ls, ModuleName, Year, Geo = NULL,
  GeoIndex_ls = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_ls```     |     a list containing the data to be saved. The list is organized by group, table, and data set.
```ModuleSpec_ls```     |     a list of module specifications that is consistent with the VisionEval requirements
```ModuleName```     |     a string identifying the name of the module (used to document the module creating the data in the datastore)
```Year```     |     a string identifying the model run year
```Geo```     |     a string identifying the name of the geographic area to get the data for. For example, if the module is specified to be run by Azone, then Geo would be the name of a particular Azone.
```GeoIndex_ls```     |     a list of geographic indices used to determine the positions to extract from a dataset corresponding to the specified geography.

#### Details


 This function saves to the datastore the data sets identified in a module's
 'Set' specifications and included in the list returned by the module. If a
 particular geographic area is identified, the data are saved to the positions
 in the data sets in the datastore corresponding to the identified geographic
 area.


#### Value


 A logical value which is TRUE if the data are successfully saved to
 the datastore.


#### Calls
checkTableExistence, convertMagnitude, convertUnits, createGeoIndex, deflateCurrency, getModelState, Types, writeLog


### `setModelState`: Update model state.

#### Description


 `setModelState` a visioneval framework control function that updates the
 list that keeps track of the model state with list of components to update
 and resaves in the model state file.


#### Usage

```r
setModelState(ChangeState_ls, FileName = "ModelState.Rda")
```


#### Arguments

Argument      |Description
------------- |----------------
```ChangeState_ls```     |     A named list of components to change in ModelState_ls
```FileName```     |     A string identifying the name of the file that contains the ModelState_ls list. The default name is 'ModelState.Rda'.

#### Details


 Key variables that are important for managing the model run are stored in a
 list (ModelState_ls) that is in the global workspace and saved in the
 'ModelState.Rda' file. This function updates  entries in the model state list
 with a supplied named list of values, and then saves the results in the file.


#### Value


 TRUE if the model state list and file are changed.


#### Calls
getModelState


### `simDataTransactions`: Create simulation of datastore transactions.

#### Description


 `simDataTransactions` a visioneval framework control function that loads
 all module specifications in order (by run year) and creates a simulated
 listing of the data which is in the datastore and the requests of data from
 the datastore and checks whether tables will be present to put datasets in
 and that datasets will be present that data is to be retrieved from.


#### Usage

```r
simDataTransactions(AllSpecs_ls)
```


#### Arguments

Argument      |Description
------------- |----------------
```AllSpecs_ls```     |     A list containing the processed specifications of all of the modules run by model script in the order that the modules are called with duplicated module calls removed. Information about each module call is a component of the list in the order of the module calls. Each component is composed of 3 components: 'ModuleName' contains the name of the module, 'PackageName' contains the name of the package the module is in, and 'Specs' contains the processed specifications of the module. The 'Get' specification component includes the 'Get' specifications of all modules that are called by the module.

#### Details


 This function creates a list of the datastore listings for the working
 datastore and for all datastore references. The list includes a 'Global'
 component, in which 'Global' references are simulated, components for each
 model run year, in which 'Year' references are simulated, and if the base
 year is not one of the run years, a base year component, in which base year
 references are simulated. For each model run year the function steps through
 a data frame of module calls as produced by 'parseModelScript', and loads and
 processes the module specifications in order: adds 'NewInpTable' references,
 adds 'Inp' dataset references, checks whether references to datasets
 identified in 'Get' specifications are present, adds 'NewSetTable' references,
 and adds 'Set' dataset references. The function compiles a vector of error
 and warning messages. Error messages are made if: 1) a 'NewInpTable' or
 'NewSetTable' specification of a module would create a new table for a table
 that already exists; 2) a dataset identified by a 'Get' specification would
 not be present in the working datastore or any referenced datastores; 3) the
 'Get' specifications for a dataset would not be consistent with the
 specifications for the dataset in the datastore. The function compiles
 warnings if a 'Set' specification will cause existing data in the working
 datastore to be overwritten. The function writes warning and error messages
 to the log and stops program execution if there are any errors.


#### Value


 There is no return value. The function has the side effect of
 writing messages to the log and stops program execution if there are any
 errors.


#### Calls
checkDataset, checkSpecConsistency, checkTableExistence, getDatasetAttr, getModelState, getModuleSpecs, getYears, processModuleSpecs, readModelState, writeLog


### `sortGeoTable`: Sort a data frame so that the order of rows matches the geography in a
 datastore table.

#### Description


 `sortGeoTable` a visioneval framework control function that returns a
 data frame whose rows are sorted to match the geography in a specified table
 in the datastore.


#### Usage

```r
sortGeoTable(Data_df, Table, Group)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_df```     |     a data frame that contains a 'Geo' field containing the names of the geographic areas to sort by and any number of additional data fields.
```Table```     |     a string for the table that is to be matched against.
```Group```     |     a string for the generic group that the table resides in.

#### Details


 This function sorts the rows of a data frame that the 'Geo' field in the
 data frame matches the corresponding geography names in the specified table
 in the datastore. The function returns the sorted table.


#### Value


 The data frame which has been sorted to match the order of geography
 in the specified table in the datastore.


#### Calls



### `SpecRequirements`: List basic module specifications to check for correctness

#### Description


 `SpecRequirements` a visioneval framework control function that returns
 a list of basic requirements for module specifications to be used for
 checking correctness of specifications.


#### Usage

```r
SpecRequirements()
```


#### Details


 This function returns a list of the basic requirements for module
 specifications. The main components of the list are the components of module
 specifications: RunBy, NewInpTable, NewSetTable, Inp, Get, Set. For each
 item of each module specifications component, the list identifies the
 required data type of the attribute entry and the allowed values for the
 attribute entry.


#### Value


 A list comprised of six named components: RunBy, NewInpTable,
 NewSetTable, Inp, Get, Set. Each main component is a list that has a
 component for each specification item that has values to be checked. For each
 such item there is a list having two components: ValueType and ValuesAllowed.
 The ValueType component identifies the data type that the data entry for the
 item must have (e.g. character, integer). The ValuesAllowed item identifies
 what values the item may have.


#### Calls



### `Types`: Returns a list of returns a list of recognized data types, the units for each
 type, and storage mode of each type.

#### Description


 `Types` a visioneval framework control function that returns a list of
 returns a list of recognized data types, the units for each type, and storage
 mode of each type.


#### Usage

```r
Types()
```


#### Details


 This function stores a listing of the dataset types recognized by the
 visioneval framework, the units recognized for each type, and the storage
 mode used for each type. Types include simple types (e.g. integer, double,
 character, logical) as well as complex types (e.g. distance, time, mass). For
 the complex types, units are specified as well. For example for the distance
 type, allowed units are MI (miles), FT (feet), KM (kilometers), M (meters).
 The listing includes conversion factors between units of each complex type.
 The listing also contains the storage mode (i.e. integer, double, character,
 logical of each type. For simple types, the type and the storage mode are the
 same).


#### Value


 A list containing a component for each recognized type. Each
 component lists the recognized units for the type and the storage mode. There
 are currently 4 simple types and 10 complex type. The simple types are
 integer, double, character and logical. The complex types are currency,
 distance, area, mass, volume, time, speed, vehicle_distance,
 passenger_distance, and payload_distance.


#### Calls



### `writeLog`: Write to log.

#### Description


 `writeLog` a visioneval framework control function that writes a message
 to the run log.


#### Usage

```r
writeLog(Msg = "", Print = FALSE)
```


#### Arguments

Argument      |Description
------------- |----------------
```Msg```     |     A character string.
```Print```     |     logical (default: FALSE). If True Msg will be printed in additon to being added to log

#### Details


 This function writes a message in the form of a string to the run log. It
 logs the time as well as the message to the run log.


#### Value


 TRUE if the message is written to the log uccessfully.
 It appends the time and the message text to the run log.


#### Calls
getModelState


### `writeVENameRegistry`: Writes module Inp and Set specifications to the VisionEval name registry.

#### Description


 `writeVENameRegistry` a visioneval framework control function that
 writes module Inp and Set specifications to the VisionEval name registry.


#### Usage

```r
writeVENameRegistry(ModuleName, PackageName, NameRegistryDir = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```ModuleName```     |     a string identifying the module name.
```PackageName```     |     a string identifying the package name.
```NameRegistryDir```     |     a string identifying the path to the directory where the name registry file is located.

#### Details


 The VisionEval name registry (VENameRegistry.json) keeps track of the
 dataset names created by all registered modules by reading in datasets
 specified in the module Inp specifications or by returning calculated
 datasets as specified in the module Set specifications. This functions adds
 the Inp and Set specifications for a module to the registry. It removes any
 existing entries for the module first.


#### Value


 TRUE if successful. Has a side effect of updating the VisionEval
 name registry.


#### Calls
getModuleSpecs, processModuleSpecs, readVENameRegistry


### Appendix J: VisionEval Framework Datastore Functions


### `initDatasetH5`: Initialize dataset in an HDF5 (H5) type datastore table.

#### Description


 `initDatasetH5` a visioneval framework datastore connection function
 that initializes a dataset in an HDF5 (H5) type datastore table.


#### Usage

```r
initDatasetH5(Spec_ls, Group)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     a list containing the standard module 'Set' specifications described in the model system design documentation.
```Group```     |     a string representation of the name of the group the table is to be created in.

#### Details


 This function initializes a dataset in an HDF5 (H5) type datastore table.


#### Value


 TRUE if dataset is successfully initialized. If the dataset already
 exists the function throws an error and writes an error message to the log.
 Updates the model state file.


#### Calls
getModelState, listDatastoreH5, Types, writeLog


### `initDatasetRD`: Initialize dataset in an RData (RD) type datastore table.

#### Description


 `initDatasetRD` a visioneval framework datastore connection function
 initializes a dataset in an RData (RD) type datastore table.


#### Usage

```r
initDatasetRD(Spec_ls, Group)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     a list containing the standard module specifications described in the model system design documentation.
```Group```     |     a string representation of the name of the top-level subdirectory the table is to be created in (i.e. either 'Global' or the name of the year).

#### Details


 This function initializes a dataset in an RData (RD) type datastore table.


#### Value


 TRUE if dataset is successfully initialized. If the identified table
 does not exist, the function throws an error.


#### Calls
getModelState, listDatastoreRD, Types, writeLog


### `initDatastoreH5`: Initialize Datastore for an HDF5 (H5) type datastore.

#### Description


 `initDatastoreH5` a visioneval framework datastore connection function
 that creates datastore with starting structure for an HDF5 (H5) type
 datastore.


#### Usage

```r
initDatastoreH5()
```


#### Details


 This function creates the datastore for the model run with the initial
 structure for an HDF5 (H5) type datastore.


#### Value


 TRUE if datastore initialization is successful. Calls the
 listDatastore function which adds a listing of the datastore contents to the
 model state file.


#### Calls
getModelState, listDatastoreH5


### `initDatastoreRD`: Initialize Datastore for an RData (RD) type datastore.

#### Description


 `initDatastoreRD` a visioneval framework datastore connection function
 that creates a datastore with starting structure for an RData (RD) type
 datastore.


#### Usage

```r
initDatastoreRD()
```


#### Details


 This function creates the datastore for the model run with the initial
 structure for an RData (RD) type datastore.


#### Value


 TRUE if datastore initialization is successful. Calls the
 listDatastore function which adds a listing of the datastore contents to the
 model state file.


#### Calls
getModelState, getYears, listDatastoreRD, setModelState


### `initTableH5`: Initialize table in an HDF5 (H5) type datastore.

#### Description


 `initTableH5` a visioneval framework datastore connection function that
 initializes a table in an HDF5 (H5) type datastore.


#### Usage

```r
initTableH5(Table, Group, Length)
```


#### Arguments

Argument      |Description
------------- |----------------
```Table```     |     a string identifying the name of the table to initialize.
```Group```     |     a string representation of the name of the group the table is to be created in.
```Length```     |     a number identifying the table length.

#### Details


 This function initializes a table in an HDF5 (H5) type datastore.


#### Value


 The value TRUE is returned if the function is successful at creating
 the table. In addition, the listDatastore function is run to update the
 inventory in the model state file. The function stops if the group in which
 the table is to be placed does not exist in the datastore and a message is
 written to the log.


#### Calls
getModelState, listDatastoreH5


### `initTableRD`: Initialize table in an RData (RD) type datastore.

#### Description


 `initTableRD` a visioneval framework datastore connection function
 initializes a table in an RData (RD) type datastore.


#### Usage

```r
initTableRD(Table, Group, Length)
```


#### Arguments

Argument      |Description
------------- |----------------
```Table```     |     a string identifying the name of the table to initialize.
```Group```     |     a string representation of the name of the top-level subdirectory the table is to be created in (i.e. either 'Global' or the name of the year).
```Length```     |     a number identifying the table length.

#### Details


 This function initializes a table in an RData (RD) type datastore.


#### Value


 The value TRUE is returned if the function is successful at creating
 the table. In addition, the listDatastore function is run to update the
 inventory in the model state file. The function stops if the group in which
 the table is to be placed does not exist in the datastore and a message is
 written to the log.


#### Calls
getModelState, listDatastoreRD


### `listDatastoreH5`: List datastore contents for an HDF5 (H5) type datastore.

#### Description


 `listDatastoreH5` a visioneval framework datastore connection function
 that lists the contents of an HDF5 (H5) type datastore.


#### Usage

```r
listDatastoreH5()
```


#### Details


 This function lists the contents of a datastore for an HDF5 (H5) type
 datastore.


#### Value


 TRUE if the listing is successfully read from the datastore and
 written to the model state file.


#### Calls
getModelState, setModelState


### `listDatastoreRD`: List datastore contents for an RData (RD) type datastore.

#### Description


 `listDatastoreRD` a visioneval framework datastore connection function
 that lists the contents of an RData (RD) type datastore.


#### Usage

```r
listDatastoreRD(DataListing_ls = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```DataListing_ls```     |     a list containing named elements describing a new data item being added to the datastore listing and the model state file. The list components are: group - the name of the group (path) the item is being added to; name - the name of the data item (directory or dataset); groupname - the full path to the data item; attributes - a list containing the named attributes of the data item.

#### Details


 This function lists the contents of a datastore for an RData (RD) type
 datastore.


#### Value


 TRUE if the listing is successfully read from the datastore and
 written to the model state file.


#### Calls
getModelState, readModelState, setModelState


### `readFromTableH5`: Read from an HDF5 (H5) type datastore table.

#### Description


 `readFromTableH5` a visioneval framework datastore connection function
 that reads a dataset from an HDF5 (H5) type datastore table.


#### Usage

```r
readFromTableH5(Name, Table, Group, File = NULL, Index = NULL,
  ReadAttr = FALSE)
```


#### Arguments

Argument      |Description
------------- |----------------
```Name```     |     A string identifying the name of the dataset to be read from.
```Table```     |     A string identifying the complete name of the table where the dataset is located.
```Group```     |     a string representation of the name of the datastore group the data is to be read from.
```File```     |     a string representation of the file path of the datastore
```Index```     |     A numeric vector identifying the positions the data is to be written to. NULL if the entire dataset is to be read.
```ReadAttr```     |     A logical identifying whether to return the attributes of the stored dataset. The default value is FALSE.

#### Details


 This function reads a dataset from an HDF5 (H5) type datastore table.


#### Value


 A vector of the same type stored in the datastore and specified in
 the TYPE attribute.


#### Calls
checkDataset, getModelState, readModelState, writeLog


### `readFromTableRD`: Read from an RData (RD) type datastore table.

#### Description


 `readFromTableRD` a visioneval framework datastore connection function
 that reads a dataset from an RData (RD) type datastore table.


#### Usage

```r
readFromTableRD(Name, Table, Group, DstoreLoc = NULL, Index = NULL,
  ReadAttr = FALSE)
```


#### Arguments

Argument      |Description
------------- |----------------
```Name```     |     A string identifying the name of the dataset to be read from.
```Table```     |     A string identifying the complete name of the table where the dataset is located.
```Group```     |     a string representation of the name of the datastore group the data is to be read from.
```DstoreLoc```     |     a string representation of the file path of the datastore. NULL if the datastore is the current directory.
```Index```     |     A numeric vector identifying the positions the data is to be written to. NULL if the entire dataset is to be read.
```ReadAttr```     |     A logical identifying whether to return the attributes of the stored dataset. The default value is FALSE.

#### Details


 This function reads a dataset from an RData (RD) type datastore table.


#### Value


 A vector of the same type stored in the datastore and specified in
 the TYPE attribute.


#### Calls
checkDataset, getModelState, readModelState, writeLog


### `writeToTableH5`: Write to an RData (RD) type datastore table.

#### Description


 `writeToTableRD` a visioneval framework datastore connection function
 that writes data to an RData (RD) type datastore table and initializes
 dataset if needed.


#### Usage

```r
writeToTableH5(Data_, Spec_ls, Group, Index = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_```     |     A vector of data to be written.
```Spec_ls```     |     a list containing the standard module 'Set' specifications described in the model system design documentation.
```Group```     |     a string representation of the name of the datastore group the data is to be written to.
```Index```     |     A numeric vector identifying the positions the data is to be written to.

#### Details


 This function writes a dataset file to an RData (RD) type datastore table. It
 initializes the dataset if the dataset does not exist. Enables data to be
 written to specific location indexes in the dataset.


#### Value


 TRUE if data is sucessfully written. Updates model state file.


#### Calls
checkDataset, getModelState, initDatasetH5, listDatastoreH5, writeLog


### `writeToTableRD`: Write to an RData (RD) type datastore table.

#### Description


 `writeToTableRD` a visioneval framework datastore connection function
 that writes data to an RData (RD) type datastore table and initializes
 dataset if needed.


#### Usage

```r
writeToTableRD(Data_, Spec_ls, Group, Index = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Data_```     |     A vector of data to be written.
```Spec_ls```     |     a list containing the standard module 'Set' specifications described in the model system design documentation.
```Group```     |     a string representation of the name of the datastore group the data is to be written to.
```Index```     |     A numeric vector identifying the positions the data is to be written to.

#### Details


 This function writes a dataset file to an RData (RD) type datastore table. It
 initializes the dataset if the dataset does not exist. Enables data to be
 written to specific location indexes in the dataset.


#### Value


 TRUE if data is sucessfully written.


#### Calls
checkDataset, getModelState, listDatastoreRD, readFromTableRD, Types, writeLog


