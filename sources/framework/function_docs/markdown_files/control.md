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


### `doProcessGetSpec`: Filters Get specifications list based on OPTIONAL specification attributes.

#### Description


 `doProcessGetSpec` a visioneval framework control function that filters
 out Get specifications whose OPTIONAL specification attribute is TRUE but the
 specified dataset is not included in the corresponding Inp specifications nor
 is it present in the datastore.


#### Usage

```r
doProcessGetSpec(GetSpecs_ls, DstoreListing_df, RunYears_)
```


#### Arguments

Argument      |Description
------------- |----------------
```GetSpecs_ls```     |     A standard specifications list for Get specifications.
```DstoreListing_df```     |     A standard datastore listing dataframe.
```RunYears_```     |     A string vector of the model run years.

#### Details


 A Get specification component may have an OPTIONAL specification whose value
 is TRUE. If so, and if the specified dataset will be created by processing
 the corresponding Inp specifications or if the dataset is already present in
 the datastore then the get specification needs to be processed. This function
 checks whether the OPTIONAL specification is present, whether its value is
 TRUE, and whether the dataset will be created by processing the corresponding
 Inp specifications or if it exists in the datastore for all model run years.
 If all of these are true, then the get specification needs to be processed.
 The get specification also needs to be processed if it is not optional. A
 specification is not optional if the OPTIONAL attribute is not present or if
 it is present and the value is not TRUE. The function returns a list of all
 the Get specifications that meet these criteria.


#### Value


 A list containing the Get specification components that meet the
 criteria of either not being optional or being optional and the specified
 input file is present.


#### Calls
checkDataset


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



### `doProcessSetSpec`: Filters Set specifications list based on OPTIONAL specification attributes.

#### Description


 `doProcessSetSpec` a visioneval framework control function that filters
 out Set specifications whose OPTIONAL specification attribute is TRUE but the
 specified dataset is not included in the corresponding Get specifications.


#### Usage

```r
doProcessSetSpec(SetSpecs_ls, ProcessedGetSpecs_ls)
```


#### Arguments

Argument      |Description
------------- |----------------
```SetSpecs_ls```     |     A standard specifications list for Set specifications.
```ProcessedGetSpecs_ls```     |     A processed specifications of Get specifications that has been processed by the 'doProcessGetSpec' to remove all OPTIONAL specifications that will not be processed.

#### Details


 A Set specification component may have an OPTIONAL specification whose value
 is TRUE. If so, and if the specified dataset is included in the corresponding
 Get specifications then the Set specification component needs to be
 processed. This function checks whether the OPTIONAL specification is
 present, whether its value is TRUE, and whether the dataset will be created
 by processing the corresponding Get specifications. If all of these are true,
 then the Set specification needs to be processed. The Set specification also
 needs to be processed if it is not optional. A specification is not optional
 if the OPTIONAL attribute is not present or if it is present and the value is
 not TRUE. The function returns a list of all the Set specifications that meet
 these criteria. It is important to note that optional Set specifications only
 exist to enable modules to do additional processing of input data. For
 example, to adjust proportions so that they exactly equal 1. In this general
 use case, optional input datasets are loaded, then they are retrieved from
 the datastore, processed, and then resaved to the datastore.


#### Value


 A list containing the Set specification components that meet the
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
expandSpec(SpecToExpand_ls)
```


#### Arguments

Argument      |Description
------------- |----------------
```SpecToExpand_ls```     |     A standard specifications list for a specification whose NAME attribute has multiple values.

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
getFromDatastore(ModuleSpec_ls, RunYear, Geo = NULL, GeoIndex_ls = NULL)
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
getModelState(Names_ = "All", FileName = "ModelState.Rda")
```


#### Arguments

Argument      |Description
------------- |----------------
```Names_```     |     A string vector of the components to extract from the ModelState_ls list.
```FileName```     |     A string that is the file name of the model state file. The default value is ModelState.Rda.

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
parseUnitsSpec(Spec_ls)
```


#### Arguments

Argument      |Description
------------- |----------------
```Spec_ls```     |     A standard specifications list for a Inp, Get, or Set item.

#### Details


 The UNITS component of a specifications list can encode information in
 addition to the units name. This includes a value units multiplier and in
 the case of currency values the year for the currency measurement. The
 multiplier element can only be expressed in scientific notation where the
 number before the 'e' can only be 1.


#### Value


 a list that is a standard specifications list with the addition of
 a MULTIPLIER component and a YEAR component as well as a modification of the
 UNIT component. The MULTIPLIER component can have the value of NA, a number,
 or NaN. The value is NA if the multiplier is missing. It is a number if the
 multiplier is a valid number. The value is NaN if the multiplier is not a
 valid number. The YEAR component is a character string that is a 4-digit
 representation of a year or NA if the component is missing or not a proper
 year. The UNITS component is modified to only be the units name.


#### Calls



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
doProcessGetSpec, doProcessInpSpec, doProcessSetSpec, expandSpec, readModelState


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


