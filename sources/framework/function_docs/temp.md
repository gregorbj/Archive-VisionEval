# `writeToTableRD`: Write to an RData (RD) type datastore table.

## Description


 `writeToTableRD` a visioneval framework datastore connection function
 that writes data to an RData (RD) type datastore table and initializes
 dataset if needed.


## Usage

```r
writeToTableRD(Data_, Spec_ls, Group, Index = NULL)
```


## Arguments

Argument      |Description
------------- |----------------
```Data_```     |     A vector of data to be written.
```Spec_ls```     |     a list containing the standard module 'Set' specifications described in the model system design documentation.
```Group```     |     a string representation of the name of the datastore group the data is to be written to.
```Index```     |     A numeric vector identifying the positions the data is to be written to.

## Details


 This function writes a dataset file to an RData (RD) type datastore table. It
 initializes the dataset if the dataset does not exist. Enables data to be
 written to specific location indexes in the dataset.


## Value


 TRUE if data is sucessfully written.


