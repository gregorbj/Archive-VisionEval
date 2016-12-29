# Summary of VisionEval Framework Functions  
The VisionEval software framework is implemented by a number of functions. This document provides a summary overview of those functions and their current development status.  

The framework functions are split into two groups, framework interface functions and framework utility functions. The framework interface functions along with module specifications are the applications programming interface for the VisionEval software framework. These are the functions that developers may use to create model modules and to connect modules together to make a model. There currently are a small number of framework interface functions.  

The framework interface functions call on a number of utility functions which do most of the work of managing the state of a model run, managing the flow of data to and from the model datastore, performing data checks, and logging operations. These utility functions should not be used in modules or model scripts although their use is currently not prohibited because the framework is still under development.

The sections below provide a summary of how these functions are organized. In addition, a brief summary is provided for each function giving the function name, a description of what the function does, a list of other framework functions that function calls, and what additional changes are likely be made to the function before the framework is ready for release. Full documentation of each function is included in the source code.    

## 1. Framework Interface Functions  
There are two groups of framework interface functions:  
1. Model programming functions  
2. Module programming functions  

### 1.1. Model Programming Functions  
Models are programmed in the framework by writing a script which initializes the model and then invokes a set of model modules in some order. There are only two model development functions, 'initializeModel' and 'runModule'

#### initializeModel  
This function initializes a model by initializing a model state file, initializing a log file, initializing the model datastore, reading in the model parameters file, reading in the geography definition file, and initializing geography tables in the datastore.  
**Calls:** initModelStateFile, initLog, initDatastore, readGeography, initDatastoreGeography  
**Changes:** Check that all modules that are called will have the data they require when they are called. Check that all input files specified by called modules are present and are correct. Load all inputs into datastore. Call the loadDatastore function to load an existing datastore if specified in the 'parameters.json' file. The function should also check that the specifications of the modules to be run are consistent with the loaded datastore.  

#### runModule  
This function runs a VisionEval module (i.e. a sub-model)  
**Calls:** processModuleInputs, readFromTable, writeToTable  
**Changes:** Move processing of module inputs to initializeModel  

### 1.2. Module Programming Functions  

#### items & item    
These functions are aliases for the R 'list' function. Data specifications for modules are written as lists. The 'items' and
'item' aliases provide a more natural terminology for writing the specifications.  
**Calls:** Nothing  
**Changes:** None

#### processEstimationInputs  
This function reads in and processes a data file used to estimate module parameters. It checks whether the specified file exists and whether data in the file is consistent with specifications. It produces a list containing the data.  
**Calls:** checkDataConsistency  
**Changes:** None  

#### testModule    
This function is used in module test scripts to run a module and check whether the outputs include all of the outputs that are specified and whether those outputs meet all specifications. If an output is of character type, it checks whether the module produces a corresponding SIZE parameter.  
**Calls:** checkDataConsistency  
**Changes:** Automatic running of test script fails when building a package. Need to determine whether this function is part of the problem.  

#### hasErrors  
This function checks whether the results from testing a module contain any error messages.  
**Calls:** Nothing  
**Changes:** None  

## 2. Utility Functions  
There are four groups of utility functions:  
1. Model state management & reporting functions
2. Model initialization functions  
3. Data validation functions  
4. Datastore functions   

### 2.1. Model State Management & Reporting  
A central premise of the VisionEval framework is to make no use of global variables. To that end, all information that is important for managing a model run is stored in the 'model state file'. This file (ModelState.Rda) is an R binary file that contains a list (ModelState_ls) which contains the model state information. The functions in this group read from and write to the model state file. The group also includes a function for writing to a log file which keeps track of error messages and other messages as a model runs.  

#### setModelState  
This function loads the 'ModelState.Rda' file, updates entries with a supplied named list of values, and resaves the file.  
**Calls:** Nothing  
**Changes:** None  

#### getModelState  
This function reads the 'ModelState.Rda' file and returns a list with all of the contents or just contents that have been specified.  
**Calls:** Nothing  
**Changes:** None    

#### getYears  
This is a convenience function that makes it easier to retrieve the years component of the model state file.  
**Calls:** getModelState  
**Changes:** None  

#### writeLog  
This function writes a log entry, updating the log file.  
**Calls:** getModelState  
**Changes:** None  

### 2.2. Model Initialization Functions  
These are functions that are called when initializing a VisionEval model.    

#### initModelStateFile  
This function initializes the model state file by This function reads in the 'parameters.json' file in the 'defs' directory which is where users specify the model run parameters such as the model run years. The function then calls the setModelState function to create the 'ModelState_ls' list and save the list.  
**Calls:** setModelState  
**Changes:** None  

#### initLog    
This function creates a log file to which error messages and other messages are written during the course of a model run. It puts initial entries in the file (start time, scenario name, description). It adds the file name of the log file to the model state.  
**Calls:** setModelState  
**Changes:** None  

#### loadDatastore  
This function copies a saved datastore and corresponding geography definition file to be the starting datastore. This function enables scenario variants to be built from a constant set of starting conditions.  
**Calls:** getModelState, setModelState, listDatastore, writeLog  
**Changes:** The current function arguments are the name of the datastore to be loaded and the name of the geography definition file. These names should be specified in the 'parameters.json' file and stored in the model state file. The loadDatastore function would then access the values from the model state file. Consistency of the geography file with the loaded datastore needs to be checked.  

#### readGeography  
This function manages the reading of the geographic specifications file, calling geography checking function, and handling errors.  
**Calls:** checkGeography, writeLog, setModelState  
**Changes:** None  

#### checkGeography  
This function reads the geography specifications files and checks the file entries to determine whether they are internally consistent.  
**Calls:** writeLog  
**Changes:** None  

#### initDatastoreGeography  
This function initializes tables in the datastore to store values for all levels of geography for all years.  
**Calls:**  getModelState, initTable, initDataset, writeToTable, writeLog  
**Changes:** None  

#### processModuleInputs    
This function manages the processing of all the scenario input files specified by a module. It checks whether all the specified files exist, whether the files include data for all specified years and zones, and whether every field complies with data specifications.  
**Calls:** writeLog, readFromTable, checkDataConsistency, writeToTable  
**Changes:** The function manages processing data to be put in the 'Global' group in the datastore vs. a specific year group by assigning 'Global' to the local 'Year' variable. The approach is to be changed here and in the 'runModule' function to improve code clarity and to avoid naming conflicts. A variable name other than 'Year' will be used to designate which group inputs will be saved to.  

### 2.3. Data Validation Functions  
These functions are used to perform various validation checks of data. Note that many of these checks are done by referring to 'DstoreListing_df', a data frame which lists a variety of datastore attributes. This data frame is updated every time the datastore is written to. Consequently 'DstoreListing_df' is always up to date and most validation checks can be done quickly by checking specifications against the values in 'DstoreListing_df'.  

#### checkYear  
This function checks whether the datastore has a group for the specified year.  
**Calls:** writeLog
**Changes:** None  

#### checkTable  
This function checks whether the datastore contains a specified table.  
**Calls:** checkYear, writeLog  
**Changes:** None  

#### checkDataset  
This function checks whether a specified dataset in specified table and year groups exists and if so returns the full path name to the dataset in the datastore.  
**Calls:** checkTable, writeLog  
**Changes:** None  

#### getDatasetAttr  
This function extracts the listed attributes of a specified dataset from the datastore listing.  
**Calls:** checkDataset  
**Changes:** None  

#### checkSpecConsistency  
This function checks whether a module 'Get' or 'Set' specifications are consistent with the attributes for that data in the datastore. It does this by comparing the module specifications with the specifications in the datastore listing.
**Calls:** Nothing  
**Changes:** None  

#### checkMatchType  
This function checks whether the datatype of a data vector is consistent with a data type specification.  
**Calls:** Nothing  
**Changes:** None  

#### checkMatchConditions  
This function checks whether any elements of a data vector match any prohibited conditions.  
**Calls:** Nothing  
**Changes:** None  

### 2.4. Datastore Functions
These are functions that are used to interact with the HDF5 datastore such as reading, writing, listing contents, and creating groups. The functions call functions from the Rhdf5 library.

#### listDatastore  
This function lists the contents of a datastore including identifying all groups, tables, and datasets. It also lists the attributes associated with each table and dataset. The listing is saved in the model state file.  
**Calls:** setModelState  
**Changes:** None

#### initDatastore  
This function creates the datastore file for the model run with the initial structure.  
**Calls:** getModelState  
**Changes:** None  

#### initDatastoreTable  
This function creates a group in the HDF5 datastore to house a table. A table is a group containing equal length vectors that may have different types (like a data frame). A table is initialized by creating a group having the table name and setting a LENGTH attribute which is used to ensure that all vectors in the table have the same lengths.  
**Calls:** listDatastore  
**Changes:** None  

#### initDataset
This function initializes a data set in a table. This must be done before any data is written to the data set. Initialization establishes a name for the data set and key attributes associated with the data.  
**Calls:** writeLog, initTable  
**Changes:** None  

#### writeToTable  
This function writes data to a data set in a table. It initializes the data set if it does not already exist. The function enables data to be written to specific positions in the data set. The function converts any NA value to the value specified to be used to represent NA in the data store.   
**Calls:** checkTable, writeLog, initTable, initDataset, getDatasetAttr, checkSpecConsistency, listDatastore  
**Changes:** Remove checking data consistency with the data set attributes. This slows down the write process and is unnecessary because it is up to the module to assure that any data it produces will be consistent with its data specifications.  

#### readFromTable  
This function reads data from a data set in a table. Indexed reads are permitted. The function checks whether the table and data set exist and whether all indexes are within the length of the table. The function converts any value specified as representing NA to NA.  
**Calls:** checkDataset, writeLog  
**Changes:** None  

#### createIndex  
This function creates an indexing function which returns a vector of indexes to positions in the data sets in a table that correspond to an reference field of a table. For example, if the reference field is 'Azone' in the 'Household' table, this function will return a function that when provided the name of a particular Azone, will return the positions corresponding to that Azone.  
**Calls:** readFromTable  
**Changes:** None  
