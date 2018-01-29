### Appendix G: VisionEval User Functions


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
initializeModel(ParamDir = "defs", RunParamFile = "run_parameters.json",
  GeoFile = "geo.csv", ModelParamFile = "model_parameters.json",
  LoadDatastore = FALSE, DatastoreName = NULL, SaveDatastore = TRUE)
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
assignDatastoreFunctions, checkModuleExists, checkModuleSpecs, getModelState, getModuleSpecs, initDatastoreGeography, initLog, initModelStateFile, inputsToDatastore, loadDatastore, loadModelParameters, parseModelScript, processModuleInputs, processModuleSpecs, readGeography, readModelState, setModelState, simDataTransactions, writeLog


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


