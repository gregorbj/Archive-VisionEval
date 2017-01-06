#==============
#CreateBzones.R
#==============

#This demonstration module creates simulated Bzones that have a specified
#numbers of households and development types (Metropolitan, Town, Rural). Module
#determines the number of Bzones in each Azone and assigns a unique ID and a
#development type to each. It also calculates the number of households in each
#Bzone such that the proportion of households in each Azone assigned to each
#development type matches assumed input proportions. It also assigns the
#respective Mareas to the simulated Bzones. A Bzone table is created and
#populated with unique IDs, development types, Mareas, Azones, and numbers of
#households.

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

#In this demo module, only one parameter is defined: the average number of
#households per block group. This shows how model parameters can be defined by
#simple assignment statements.

#Create & save a parameter for the average number of households per block group
#------------------------------------------------------------------------------
AveHhPerBlockGroup <- 400
#' Average households per block group
#'
#' A number representing the average number of households per census block.
#'
#' @format A number:
#' \describe{
#'  \item{AveHhPerBlockGroup}{average households per census block group}
#' }
#' @source CreateBzones.R script.
"AveHhPerBlockGroup"
devtools::use_data(AveHhPerBlockGroup, overwrite = TRUE)


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
CreateBzonesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify input data
  Inp = items(
    item(
      NAME =
        items("Metropolitan",
              "Town",
              "Rural"),
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "households",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Metropolitan",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Town",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Rural",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c("Metropolitan", "Town", "Rural")
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateBzones module
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
"CreateBzonesSpecifications"
devtools::use_data(CreateBzonesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateBzones". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#This module only has a main function, CreateBzones. This function creates
#simulated Bzones and assigns development types, Azones, Mareas,
#unique Bzone IDs, and numbers of households.

#Function that creates simulated Bzones
#------------------------------------------
#' Creates a set of simulated Bzones
#'
#' \code{CreateBzones} creates a set of simulated Bzones and assigns
#' development types, Azones, Mareas, unique Bzone IDs, and numbers of
#' households.
#'
#' This function creates a set of simulated Bzones and assigns attributes
#' including the Azone that the Bzone is situated in, the Marea that the Bzone
#' is situated in, the number of households in the Bzone, and the development
#' type (i.e. Metropolitan, Town, Rural) of the Bzone. These data items are
#' vectors that are to be stored in the "Bzone" table. Since this table does not
#' exist, the function calculates a LENGTH value for the table and returns that
#' as well. The framework uses this information to initialize the Bzone table.
#' The function also computes the maximum numbers of characters in the Bzone,
#' Azone, Marea, and DevType datasets and assigns these to a SIZE vector. This
#' is necessary so that the framework can initialize these datasets in the
#' datastore. All results are returned in a list.
#'
#' @param L A list containing the following components that have been read
#' from the datastore:
#' Azone: A character vector of Azone names read from the Azone table.
#' NumHh: A numeric vector of the number of people in each Azone read from the
#' Azone table.
#' Marea: A character vector of Marea names read from the Azone table.
#' Metropolitan: A numeric vector of the proportion of households that are of
#' the Metropolitan development type in each Azone read from the Azone table.
#' Town: A numeric vector of the proportion of households that are of the Town
#' development type in each Azone read from the Azone table.
#' Rural: A numeric vector of the proportion of households that are of the
#' Rural development type in each Azone read from the Azone table.
#' @return A list containing the following components:
#' Bzone: A character vector of the names of the Bzones that is to be assigned
#' to the Bzone table.
#' Azone: A character vector of the names of the Azones associated with each
#' Bzone that is to be assigned to the Bzone table.
#' Marea: A character vector of the names of the Mareas associated with each
#' Bzone that is to be assigned to the Bzone table.
#' DevType: A character vector identifying the development type of each Bzone
#' that is to be assigned to the Bzone table.
#' NumHh: An integer vector identifying the number of households assigned to
#' each Bzone that is to be assigned to the Bzone table.
#' LENGTH: A named integer vector having a single named element, "Bzone",
#' which identifies the length (number of rows) of the Bzone table to be
#' created in the datastore.
#' SIZE: a named numeric vector having four elements. The first element,
#' "Azone", identifies the size of the longest Azone name. The second element,
#' "Bzone", identifies the size of the longest Bzone name. The third element,
#' "Marea", identifies the size of the longest Marea name. The fourth element,
#' "DevType", identifies the size of the longest DevType name.
#' @export
CreateBzones <- function(L) {
  #Make vector of Azone names
  Az <- L$Azone
  #Make matrix of development type proportions by Azone
  Dt <- c("Metropolitan", "Town", "Rural")
  DevTypeProp_AzDt <- cbind(L$Metropolitan, L$Town, L$Rural)
  rownames(DevTypeProp_AzDt) <- Az
  colnames(DevTypeProp_AzDt) <- Dt
  #Define function to assign & tabulate number of households by development type
  tabulateNumHhByDevType <- function(NumHh, Prob) {
    DevType_Hh <- sample(Dt, NumHh_Az[az], replace = TRUE,
                           prob = DevTypeProp_AzDt[az,])
    DevTypeHh_Dt <- table(DevType_Hh)[Dt]
    names(DevTypeHh_Dt) <- Dt
    DevTypeHh_Dt[is.na(DevTypeHh_Dt)] <- 0
    DevTypeHh_Dt
  }
  #Assign the number of households to be in each Azone development type
  NumHh_Az <- L$NumHh
  names(NumHh_Az) <- Az
  DevTypeHh_AzDt <- DevTypeProp_AzDt * 0
  for(az in Az) {
    DevTypeHh_AzDt[az,] <- tabulateNumHhByDevType(NumHh_Az[az],
                                                  DevTypeProp_AzDt[az,])
  }
  #Calculate number of block groups and number of households per block group
  #for each Azone and development type
  NumBlkGrp_AzDt <- round(DevTypeHh_AzDt / AveHhPerBlockGroup)
  storage.mode(NumBlkGrp_AzDt) <- "integer"
  NumBlkGrp_Az <- rowSums(NumBlkGrp_AzDt)
  HhPerBlockGroup_AzDt <- ceiling(DevTypeHh_AzDt / NumBlkGrp_AzDt)
  HhPerBlockGroup_AzDt[is.na(HhPerBlockGroup_AzDt)] <- 0
  storage.mode(HhPerBlockGroup_AzDt) <- "integer"
  #Create simulated block groups and associate with metropolitan areas
  Marea_Az <- L$Marea
  names(Marea_Az) <- L$Azone
  Bzone_df <- expand.grid(dimnames(t(NumBlkGrp_AzDt)), stringsAsFactors = FALSE)
  names(Bzone_df) <- c("DevType", "Azone")
  Bzone_df$NumZones <- as.vector(t(NumBlkGrp_AzDt))
  Bzone_df$NumHh <- as.vector(t(HhPerBlockGroup_AzDt))
  Bzone_df$Marea <- Marea_Az[Bzone_df$Azone]
  Bzone_df <- Bzone_df[Bzone_df$NumZones != 0,]
  #Calculate values to write out of the module
  Bz <- unlist(sapply(names(NumBlkGrp_Az),
                      function(x) paste(x, 1:NumBlkGrp_Az[x], sep = "")),
               use.names = FALSE)
  Azone_Bz <- rep(names(NumBlkGrp_Az), NumBlkGrp_Az)
  Marea_Bz <- rep(Bzone_df$Marea, Bzone_df$NumZones)
  NumHh_Bz <- rep(Bzone_df$NumHh, Bzone_df$NumZones)
  DevType_Bz <- rep(Bzone_df$DevType, Bzone_df$NumZones)
  #Calculate the total number of Bzones. Necessary for calculating a LENGTH
  #attribute used for initializing Bzone table
  LENGTH <- numeric(0)
  LENGTH["Bzone"] <- length(Bz)
  #Calculate and assign SIZE attributes for 'Bzone', 'Marea', and 'DevType'
  #Necessary for initializing datasets in Bzone table
  SIZE <- numeric(0)
  SIZE["Bzone"] <- max(nchar(Bz))
  SIZE["Azone"] <- max(nchar(Azone_Bz))
  SIZE["Marea"] <- max(nchar(Marea_Bz))
  SIZE["DevType"] <- max(nchar(DevType_Bz))
  #Return a list of values to be saved in the datastore
  list(Bzone = Bz,
       Azone = Azone_Bz,
       Marea = Marea_Bz,
       NumHh = NumHh_Bz,
       DevType = DevType_Bz,
       LENGTH = LENGTH,
       SIZE = SIZE)
}

