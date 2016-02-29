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
      TOTAL = ""
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




