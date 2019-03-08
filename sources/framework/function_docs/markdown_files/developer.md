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


