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
#Data specifications must be provided for each data table that is to be read in
#to be used in estimating model parameters. Specifications are stored in lists
#that are defined using the "items" and "item" functions. These functions are
#aliases for the "list" function. Each data table that is to be read
#must have it's own specifications list. This list has a component for each of
#the columns of data that are used in the estimation. Specifications are not
#necessary for data columns that are not used. The following examples show the
#syntax for specifications. The "items" function is used to define the set of
#all specifications for the table. The specifications for each data column are
#demarcated by the "item" function. The following components must be included in
#an item specification:
#NAME = the name of the column specified as a string
#TYPE = the type of data in the column. Can be either "integer", "double",
#"character", or "logical"
#PROHIBIT = value conditions that are not allowed. Each prohibited
#condition is represented as a string. For example, "NA" means that NA values
#are prohibited. Other prohibited conditions are specified by strings that
#encode standard R syntax for comparing values. For example "< 0" means that
#values less than 0 are prohibited. Note that the PROHIBIT specification should
#not be used to specify categorical data. The ISELEMENTOF specification should
#be used instead. When there is more than one prohibited condition, the
#condition strings must be organized in a vector using the "c" function as
#shown in the example below. If there are no prohibited conditions, an empty
#string (i.e. "") must be provided.
#ISELEMENTOF = lists all of the allowed values for categorical data. Multiple
#values are organized in a vector using the "c" function. If no ISELEMENTOF
#specification is needed, an empty string (i.e. "") must be provided.
#UNLIKELY = values that are unlikely to be found in the data (and thus suspect)
#are specified in this component in the same way that prohibited values are
#specified. These are conditions that although not prohibited, require
#additional examination to assure that they are correct. Unlike the other data
#checks, the presence of unlikely values will trigger a warning rather than an
#error. If there are no unlikely conditions, an empty string (i.e. "") must be
#provided.
#TOTAL = specifies a total that the column must sum to. This is most useful
#for checking that values which are proportions (or percentages) add up to 1
#(or 100). If there is no specification for a total, an empty string (i.e. "")
#must be provided.

#Household size data
HouseholdSizesInp_ls <- items(
  item(
    NAME = "Size",
    TYPE = "integer",
    PROHIBIT = c("NA", "<= 0", "> 7"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "Number",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
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
#' @param Inp_ls A list containing the specifications for
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
#the datastore. The list is structured in the same way as the specifications
#list for estimation data described above. A specification must be provided for
#each column of an input file other than the "Geo" and "Year" columns of the
#file. If more than one column of the file has the same specifications, they can
#be included in one specification as described and shown below. The following
#components need to be included in each specification:
#NAME = a string representation of the name of a data item in the input file.
#This is also the name that will be used for the dataset in the datastore. If
#the data in more than one column of the input file has the same specifications,
#multiple names can be listed in this component. An example is shown in the
#CreateBzones.R script.
#FILE = a string representation of the name of the file that contains the table.
#This is just the name of the file, not the full path name for the file. All
#input files are stored in the "inputs" directory.
#TABLE = a string representation of the name of the datastore table the item is
#to be put into. This may be either a table that the module creates or a table
#that another module has created.
#GROUP = a string representation of the name of the group which contains the
#table in the datastore. There are 3 possible values: "Global", "BaseYear", and
#"Year". If "Global" is specified, the table is located in the 'Global' group
#which applies to all model run years. If "BaseYear" is specified, the table in
#located in the year group (e.g. '2010') for the year that is identified as the
#base year in the run parameters for the model. If "Year" is specified, the
#table is located in the year group for the year that the model is being run
#for (e.g. if the model is being run for the year 2050, the group would be
#'2050').
#TYPE = a string representation of the data type: i.e. "double", "integer",
#character, logical).
#UNITS = a string identifying the the measurement units for the data
#(e.g. "persons per square mile");
#NAVALUE = the value that will be used to represent NA in the datastore. NA
#values can't be stored directly in the HDF5 datastore. Therefore in order
#to store NA values, a value needs to be defined to represent it. That value
#needs to be a value that would not be calculated by the module. For example,
#a negative number might be used to represent an NA value when all values for
#the dataset will be 0 or a positive number.
#SIZE = the maximum number of characters that character type data will have. If
#the data is not character type, the value must be 0.
#PROHIBIT = one or more strings that identify data conditions that are
#prohibited. The syntax for identifying these is the same as that described in
#Section 1 of this script. If there are no prohibited conditions, an empty
#string (i.e. "") must be provided.
#ISELEMENTOF = one or more strings that identify allowed values for categorical
#data. The syntax for identifying these is the same as that described in Section
#1 of this script. If no ISELEMENTOF specification is needed, an empty string
#must be provided.
#UNLIKELY = one or more strings that identify unlikely conditions. The syntax is
#the same as that described in Section 1 of this script. If no UNLIKELY
#specification is needed, and empty string must be provided.
#TOTAL = specifies a total that the column must sum to. This is most useful
#for checking that values which are proportions (or percentages) add up to 1
#(or 100). If there is no specification for a total, an empty string (i.e. "")
#must be provided.

#Get: Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#NAME = a string representation of the name of the dataset to be loaded from the
#datastore. If multiple datasets are to be loaded from the same table and the
#specifications for all the datasets are the same, a list of all the datasets
#may be specified as described above.
#TABLE = a string representation of the the name of the table that the dataset
#is a part of.
#GROUP = a string representation of the name of the group which contains the
#table in the datastore. There are 3 possible values: "Global", "BaseYear", and
#"Year". If "Global" is specified, the table is located in the 'Global' group
#which applies to all model run years. If "BaseYear" is specified, the table in
#located in the year group (e.g. '2010') for the year that is identified as the
#base year in the run parameters for the model. If "Year" is specified, the
#table is located in the year group for the year that the model is being run
#for (e.g. if the model is being run for the year 2050, the group would be
#'2050').
#TYPE = a string representation of the data type of the dataset
#(i.e. "double", "integer", "character", "logical").
#UNITS = a string representation of the measurement units for the data.
#PROHIBIT = one or more strings that identify data conditions that are
#prohibited. The syntax for identifying these is the same as that described in
#Section 1 of this script. If there are no prohibited conditions, an empty
#string (i.e. "") must be provided.
#ISELEMENTOF = one or more strings that identify allowed values for categorical
#data. The syntax for identifying these is the same as that described in Section
#1 of this script. If no ISELEMENTOF specification is needed, an empty string
#must be provided.

#Set: Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#Get: Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#NAME = a string representation of the name of the dataset to be saved to in the
#datastore. If multiple datasets are to be saved into the same table and the
#specifications for all the datasets are the same, a list of all the datasets
#may be specified as described above.
#TABLE = a string representation of the the name of the table that the dataset
#is a part of.
#GROUP = a string representation of the name of the group which contains the
#table in the datastore. There are 3 possible values: "Global", "BaseYear", and
#"Year". If "Global" is specified, the table is located in the 'Global' group
#which applies to all model run years. If "BaseYear" is specified, the table in
#located in the year group (e.g. '2010') for the year that is identified as the
#base year in the run parameters for the model. If "Year" is specified, the
#table is located in the year group for the year that the model is being run
#for (e.g. if the model is being run for the year 2050, the group would be
#'2050').
#TYPE = a string representation of the data type of the dataset
#(i.e. "double", "integer", "character", "logical").
#UNITS = a string representation of the measurement units for the data.
#PROHIBIT = one or more strings that identify data conditions that are
#prohibited. The syntax for identifying these is the same as that described in
#Section 1 of this script. If there are no prohibited conditions, an empty
#string (i.e. "") must be provided.
#ISELEMENTOF = one or more strings that identify allowed values for categorical
#data. The syntax for identifying these is the same as that described in Section
#1 of this script. If no ISELEMENTOF specification is needed, an empty string
#must be provided.
#SIZE = An optional attribute identifying the the maximum number of characters
#that character type data may have. If the module will calculate the number of
#characters then this attribute may be omitted. If the data is not character
#type, the value must be 0.

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
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Population",
      TABLE = "Azone",
      GROUP = "Year",
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
      GROUP = "Year",
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
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
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




