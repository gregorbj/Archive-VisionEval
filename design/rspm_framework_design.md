## RSPM Framework Design  
**Brian Gregor, Oregon Systems Analytics LLC**  
**July 29, 2015**
**DRAFT**

###Model Geographic Structure  
One of the objectives of the RSPM framework is to make the statewide and metropolitan models more consistent with how they treat geographic units. The statewide model divides space into counties (or similar divisions such as PUMAs) and metropolitan areas. The metropolitan model divides space into metropolitan divisions and the divisions into districts (which now roughly correspond to census tracts, but could in the future correspond to block groups). In the RSPM framework there would be "divisions" and "districts" for both the statewide and metropolitan implementations. However, while divisions would be explicit geographic units with definite boundaries in all implementations, districts could be either explicit or implicit geographic units. Districts are likely to be explict geographic units in metropolitan models and implicit in statewide models. Implicit districts are synthesized so that their characteristics represent a likely distribution of characteristics given the characteristics of the metropolitan area in which they are situated. This approach would be a variation of current approach of modeling the density and mixed use characteristics of neighborhoods that households reside in implicitly. Synthesizing districts and modeling them implicitly in statewide models will enable all the models to use the same functions for associating households with land use characteristics such as density, place type and building type.  

The following geographic organization is proposed:  
- **Region**: The region is the entire model area. Large-scale characteristics that don't vary across the region are specified at the region level. Examples include fuel prices and model-year vehicle characteristics.  
- **Division**: Divisions are large subdivisions of the region. These are counties in the Oregon GreenSTEP model. They are cities for the RSPM model for the Central Lane MPO. They could also be PUMAs. Divisions are used to represent population and economic characteristics that vary across the region such as demographic forecasts of persons by age group and average per capita income.  
- **Districts**: Districts are subdivisions of divisions. Given that the GreenSTEP travel model has been estimated to use census tract-level population density, districts have been defined to be approximately the size of census tracts. However, with model reestimation, the size of districts could be reduced to be more comparable to census block groups. Districts are used to represent neighborhood characteristics such as population density and mixed land use. In rural counties (i.e. counties that don't have an urbanized area), districts can be used to distinguish small cities from the more rural (sparsely developed) portions of the county.  
- **Metropolitan Areas**: Metropolitan areas are census urbanized areas. The boundaries of metropolitan areas may coincide, but don't have to coincide, with divisions or districts. The main reason for this is that an urbanized area boundary is likely to change over time as the population of the area grows. When districts are explicitly modeled, changes in an urbanized area over time are modeled by specifying changes in the portions of the district land area and households that are assigned to metropolitan vs. non-metropolitan development. When districts are implicitly modeled, they are assigned as metropolitan or non-metropolitan based on portions of the division land area and households assigned to metropolitan vs. non-metropolitan development. Metropolitan areas are used to specify and analyze urbanized area transportation characteristics such as overall transportation supply (transit, highways) and congestion.  

###Modules and Framework  
Model modules are the basic components which model some specific aspect of the region. For example, a model module may model the number of vehicles owned by a household. Another module may model the ages of vehicles owned by the household. Model modules are contained within R packages. A package may include more than one module, but the modules in a package should be related. Model modules must contain all of the functionality and specifications needed to apply the models. These characteristics are described in more detail below.

The framework includes all of the functionality for enabling model modules to work with each other to create an overall model. All interactions between modules occur through persistent data storage. Modules request data inputs, process those inputs, and produce outputs. Those outputs may in turn be requested as inputs by another module. The framework handles all of the interactions between the modules and persistent data storage.  The framework processes a module data request, fetches the data from the persistent data storage, places the requested data in the module execution environment (more on this later), and writes the data produced by the module back to the persistent data storage. The framework also handles other tasks such as:  
- Loading and processing scenario input files based on module specifications for those files;  
- Managing a log which documents execution steps and records messages from modules;  
- Calculating performance measures from data in the persistent data store.  

####Module Design  
All modules are made available in the form of R packages. A package may contain more than one module. The source form of a module is an R script included in the R directory of the source package. The binary form of the module, created when the binary package is built, is an R environment. The characteristics of the source R script and the binary environment are described below.  

The source script must define all of the key functions utilized by the module. There are 3 types of functions: 1) optional functions that suit the needs of the model developer, 2) mandatory functions if one or more model parameters need to be estimated using regional data, 3) required functions.  

The optional functions are whatever the module developer determines are necessary to implement the model. These functions can be organized and written in whatever way the developer determines is best, with the following restrictions:  
- Function documentation must be complete and must use Roxygen syntax;  
- Objects created by functions which are to be used as inputs to other functions must be assigned to the enclosing environment (i.e. by using `<<-` assignment operator); and  
- All coding needs to follow the coding guidelines so that the functions can be more easily understood by others.  

If the model requires that one or more parameters be estimated using regional data, then the source script must include one or more functions which will read in user-supplied regional data, compute the required parameter(s), and return the parameter(s) to the enclosing environment. With these models, as opposed to models requiring no estimation of parameters, the model users download the source package, rather than the built binary package. They then prepare their regional data according to instructions included with the package and save it in the `inst/extdata` directory in the package. When they build the binary package, for example by using functionality in RStudio, the model estimation functions are invoked and the necessary regional model parameters are computed. This customized binary package is then used in the model implementation.

One of the required functions is the `main` function. This is the function that is invoked by the framework to run the model. The `main` function orchestrates all of the model procedures, calling other model functions as necessary. This function also returns all of the outputs that the framework is to save to the data store. As with other functions, the `main` function assigns all results to be saved to the enclosing environment.

The other required function is the `buildModel` function. This function establishes an R environment and populates it with all of the information needed to run the model. An R environment is used as a container for the model information for several reasons. First, like a list, it can store many types of information, including functions, and the framework can copy information to it and retrieve information from it. Keeping all of the model information in one object simplifies memory management. Once the model has finished executing and all of the results have been retrieved, the environment can be removed from memory. Second, unlike a list, an environment provides a namespace for functions that are assigned to it. This is very useful because if all the function inputs are in the environment, the function will be able to access those inputs by their names. The environment acts as a useful container for the exchange of information between functions that are part of the module as well as data from the data store. This is why all model functions are required to pass data that is to be used again (either temporarily by other functions or permanently in the data store) by assigning it to the enclosing environment. The `buildModel` function does the following things:  
- Creates the environment that will hold all of the model components;  
- Identifies names and specifications of scenario input files that must be processed and added to the data store;  
- Assigns the environment of all the model functions to be the model environment;  
- If the model requires, it runs model estimation functions and assigns the estimated parameters to the model environment;
- Assigns the `main` function to the model environment;
- Identifies what information needs to be retrieved from the data store in order to run the model;  
- Identifies what information is to be saved in the data store, and metadata for that information;  
- Identifies the geographic level to be used for iteration (e.g. Division would make the model run one division at a time).  

####Framework Services  
A model that is run in the framework will be a straight-forward R script that will call modules in a sequential manner. More complicated execution sequences can also be established by using loops and conditional evaluation. Modules are called by the framework `runModel` function which takes as arguments the name of the module and the name of the package where the module is located. A model script might look something like the following:  
```  
initializeModel(Name = "High Gas Price", Years = c(2010, 2035, 2050))  
runModel("SynthesizeHh", Package = "HH")  
runModel("PredictWkr", Package = "HH")  
runModel("PredictInc", Package = "HH")  
runModel("PredictAuto", Package = "Auto")  
runModel("PredictDvmt", Package = "Travel")  
```  

One service that the framework will provide is to initialize and check the model. Following are the main actions carried out by the service:  
1) Create the data store and its structure;  
2) Check whether all of the identified packages are available (i.e. installed). If not, then identify packages that need to be installed in order to run the model;  
3) Load each module and process scenario input files to add information to the data store as required (more on this below);  
4) Make a list of all the inputs required by by each module from the data store and all of the module outputs saved to the data store and check whether the inputs required by each module will be available when the module is run.  

As described above, modules are responsible for describing the scenario inputs that are needed to run the module. The modules do not process the inputs, they only describe the inputs according to standards and the framework initialization and checking service does the processing. Following is an an example of how the inputs for a module might be specified. Note that in this example, the module environment is named `Model` and that components of environments, as with lists, are established using the `$` notation. Also note that the example follows the naming guidelines in the coding standards.  
```
Model$Inp_ls <- list()
Model$Inp_ls$InpFile <- "pop_age_inputs.csv"
Model$Inp_ls$GeoLvl <- "Division"
Model$Inp_ls$Field_ls <- list()
Model$Inp_ls$Field_ls$Age0to14   <- list(Type = "integer", Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age15to19  <- list(Type = "integer", Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age20to29  <- list(Type = "integer", Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age35to54  <- list(Type = "integer", Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age55to64  <- list(Type = "integer", Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age65Plus  <- list(Type = "integer", Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$HhSize     <- list(Type = "double", Prohibit = c("< 1"))
Model$Inp_ls$Field_ls$Prop1PerHh <- list(Type = "double", Prohibit = c("<= 0", "> 1"))

```
In this example, the inputs are in a file named "pop_age_inputs.csv". The inputs are provided at the division level. The data fields particular to this input file are listed, along with the type of each input and the identification of prohibited values. The model initialization and checking service checks whether the input file exists, and if so, checks that it has the proper structure and that the values meet the specifications established by the module. All input files for the framework have the same structure. They are csv-formatted text files and they have 2 required columns in addition to the fields specified by the module:  
1) **ArealUnit** - identifies the geography for each record. For example if the geographic level of the inputs is division, then the 'ArealUnit' column will have division names.  
2) **Year** - identifies the year for each record.  
The initialization and checking service checks whether the listed areal units are consistent with the model geography and are complete. It also checks whether the listed years are consistent with the model specifications and whether there are inputs for all model years.

After the initialization and checking is done, modules are run according to the model script. The `runModel` function iterates according to the specified iteration level and with each iteration:  
- Loads the data required by the module from the data store into the module environment;  
- Calls the main function to run the module; and  
- Extracts the specified outputs from the module environment and saves them to the data store.  

###Data Store Description
####Overview of the Problem to be Solved  
Currently GreenSTEP/RSPM and related models store data in R binary files (RData files). The largest of these files are the synthetic household files which store all of the information for each synthetic household. There is a file for each model division (e.g. counties in GreenSTEP). All the household data for a division are stored in a data frame where each row corresponds to a record of an individual household and the columns are household attributes. Vehicle data for households are stored as lists in the data frame. This approach has had some advantages:  
- Storage and retrieval are part of the language: one line of code to store a data frame, and one line of code to retrieve;  
- It is easy to apply models to data frames; and  
- Vehicle data can be stored as lists within a household data frame, eliminating the need to join tables.  

The simplicity of this approach helped with getting GreenSTEP from a concept into an operational model quickly. However, several limitations have emerged as GreenSTEP and the EERPAT model have been used in various applications including:  
- Requiring large amounts of computer memory when modeling divisions having large populations (e.g. King County Washington). This necessitates either expanding computer memory or limiting the size of divisions;  
- The system time to add an attribute increases as the number of attibutes increase;  
- It is not easy to produce summary statistics from the synthetic household files; and  
- The number of non-household data files has proliferated in order to store various aggregations for use in the model and for later summarization.

These limitations are a consequence of using data frames and storing them as binary objects. One consequence of using R binary objects is that the whole object needs to be loaded into memory, even though in most cases only a portion of the data are needed for a calculation. The memory footprint increases as the number of household attributes increases. Moreover, calculations can end up increasing the memory requirements as multiple copies are made. The impact of this was reduced in later versions of GreenSTEP by sending only the needed data frame components to model functions. Other improvements might be made by using newer packages like dplyr and data.table.  

The use of data frames also introduces time penalties. As more attributes are added to a data frame and its size grows, the amount of time necessary to save and retrieve the data frame from disk increases. In addition, the amount of time required to add attributes to the data frame in memory increases.  

The memory problem has been overcome to some extent by storing the household data for divisions (counties) in separate data frames. This, along with limiting the data sent to model functions enabled Oregon GreenSTEP model to be run out to the year 2050 on a computer with a modest amount of memory (4 GB). However, the splitting of household data among a number of data frames greatly complicates the process of producting summary statistics from the outputs. This makes it necessary to load multiple files sequentially to extract the desired information and accumulate in an intermediate data structure before you can compute the desired statistic. Because this is a cumbersome process, an outputs script has been developed for GreenSTEP which produces a number of output arrays which then can be used to calculate a variety of statistics. While this has been a workable solution, it has required a significant amount of maintenance when the model changes and/or users request other statistics.  

Finally, as the model has been developed and revised, a number of data sets have been created and are saved to disk either for later use in model calculations or to produce performance measures. This has been done on an ad hoc basis and without overall organizing principles.  

####Proposed Solution  
The proposed solution is to use the HDF5 file format for storing model data. This file format was developed by the National Center for Supercomputing Applications (NCSA) at the University of Illinois and other contributors to handle extremely large and complex data collections. For example, it is used to store data from particle simulations and climate models. It also is the basis for the new open matrix standard for transportation modeling, [OMX](https://github.com/osPlanning/omx).  

Prior to pursuing the HDF5 approach, several attempts were made to use SQL databases as a substitute for R binary files. In all cases, SQL approaches were found to take considerably more time than the current approach. Moreover, SQL databases are much more complex than is needed to serve as a data store for the RSPM framework. The RSPM does not need to query data based on multiple attributes, it only needs to extract conforming vectors of selected attributes which are then very efficiently processed by R language functions. 

The HDF5 format and tools provide random data access in a way that is better scaled to the needs of the RSPM framework. Large complex data sets can be randomly accessed by organizing datasets in a heirarchy of groups and by accessing portions of datasets by using indexing. In addition, metadata can be stored as attributes of any data group or data item. Preliminary tests indicate that the aggregate time for reading data from an HFD5 file, applying a model, and writing the result back to the HDF5 file is competitive with the aggregate time for doing these things using R binary files. 

An HDF5 file is composed of groups and datasets. Groups provide the overall structure for organizing data, just a file system provides the structure for organizing files on a computer disk. A '/' indicates the root group. Subgroups are created with names. So for example, model inputs could be stored in a '/inputs' group and model outputs in a '/outputs' group. Groups may have attributes which can be used to provide metadata about the group. Data are stored within groups in multidimensional arrays. These arrays can contain many types of data, including binary data. These datasets may also have attributes which store metadata about the dataset (e.g. identifying the units of measure). Datasets in an HDF5 array are accessed using the full path to the dataset. For example, to access a parking inputs array named 'parking', the address would be '/inputs/parking'. Data within a dataset can be accessed by indexing. This enables portions of the dataset to be read or written.

A 'virtual data frame' can be easily implemented in the HDF5 data format. Data frames are a special form of list in which the components have equal lengths so that they can represent a two-dimensional table or matrix. Each component represents a column in the table. However, unlike a matrix, the components can store different types of data. A data frame in an HDF5 file can be represented by a group. For example, a data frame of household level information named 'Household_df' could be represented in an HDF5 file by a group named '/Household'. A household income attribute in the data frame, Household_df$Income, would be stored as a vector in the HDF5 file, '/Household/Income'. 

A limitation of the HDF5 format is that the datasets need to initialized at their full dimensions. In other words, once a dataset is established, it is not possible to expand the dataset. While this can make the programming a little more cumbersome than it would be if datasets could be expanded, it is not a significant limitation. For example, it is necessary to know how many households there are before a household attribute dataset can be initialized. This does not limit your ability to add attributes to an HDF5 'virtual data frame' because each attribute is represented by its own vector dataset.

####Proposed structure  
Following is the proposed grouping structure for the HDF5. Note that the inputs for all years would be stored together while the outputs are stored by year. The example is for a model that is run for the years 2010 and 2035. 
```
\  
    \Inputs  
        \Region  
        \Division  
        \District  
        \MetroArea  
    \Outputs  
        \2010  
            \Households  
            \Vehicles (unless stored as lists in Households)  
            \Employers  
            \CommercialVehicles  
            \Region  
            \Division  
            \District  
            \MetroArea  
        \2035  
            \Households  
            \Vehicles (unless stored as lists in Households)  
            \Employers  
            \CommercialVehicles  
            \Region  
            \Division  
            \District  
            \MetroArea  
```            
This structure should be adequate to store all of the information which are used by the GreenSTEP/RSPM models and their offshoots. This structure can easily be expanded to serve new modeling capabilites. For example if a module is added to model building stock, a 'Buildings' group could be added. In addition, if a future module makes use of a matrix such as a travel time matrix, a group could be added to store the matrix.