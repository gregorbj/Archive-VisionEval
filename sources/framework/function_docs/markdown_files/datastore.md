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
getModelState, getYears, listDatastoreRD


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
getModelState, setModelState


### `readFromTableH5`: Read from an HDF5 (H5) type datastore table.

#### Description


 `readFromTableH5` a visioneval framework datastore connection function
 that reads a dataset from an HDF5 (H5) type datastore table.


#### Usage

```r
readFromTableH5(Name, Table, Group, File = "datastore.h5", Index = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Name```     |     A string identifying the name of the dataset to be read from.
```Table```     |     A string identifying the complete name of the table where the dataset is located.
```Group```     |     a string representation of the name of the datastore group the data is to be read from.
```File```     |     a string representation of the file path of the datastore
```Index```     |     A numeric vector identifying the positions the data is to be written to. NULL if the entire dataset is to be read.

#### Details


 This function reads a dataset from an HDF5 (H5) type datastore table.


#### Value


 A vector of the same type stored in the datastore and specified in
 the TYPE attribute.


#### Calls
checkDataset, readModelState, writeLog


### `readFromTableRD`: Read from an RData (RD) type datastore table.

#### Description


 `readFromTableRD` a visioneval framework datastore connection function
 that reads a dataset from an RData (RD) type datastore table.


#### Usage

```r
readFromTableRD(Name, Table, Group, DstoreLoc = NULL, Index = NULL)
```


#### Arguments

Argument      |Description
------------- |----------------
```Name```     |     A string identifying the name of the dataset to be read from.
```Table```     |     A string identifying the complete name of the table where the dataset is located.
```Group```     |     a string representation of the name of the datastore group the data is to be read from.
```DstoreLoc```     |     a string representation of the file path of the datastore. NULL if the datastore is the directory identified in the 'DatastoreName' property of the model state file.
```Index```     |     A numeric vector identifying the positions the data is to be written to. NULL if the entire dataset is to be read.

#### Details


 This function reads a dataset from an RData (RD) type datastore table.


#### Value


 A vector of the same type stored in the datastore and specified in
 the TYPE attribute.


#### Calls
checkDataset, readModelState, writeLog


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
checkDataset, getModelState, initDatasetRD, readFromTableRD, writeLog


