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

#utility functions
# items <- function(...) {
#   list(...)
# }
# item <- function(...){
#   list(...)
# }
library(visioneval)


#===================================================================
#SECTION 1: DEFINE ALL THE FUNCTIONS THAT WILL BE PART OF THE MODULE
#===================================================================
#Functions defined in this section of the script implement the module model(s).
#They are run when the module is run. Notice that these functions do not take
#any arguments. That is because the functions refer to data that is part of the
#module environment or will be loaded into the module environment by the
#framework when the module is run. Also notice that the functions assign the
#results to the module environment, rather than returning them to the calling
#environment. This is important so that a module function can use the results of
#another module function, and so that the framework can save results that are
#specified in the module's 'Set' component to the datastore.

#This module contains one function which creates synthetic Bzones and assigns
#development types, Azones, Mareas, unique Bzone IDs, and numbers of households.

#Function that creates simulated Bzones
#--------------------------------------
#This module contains one function which creates synthetic Bzones and assigns
#development types, Azones, Mareas, unique Bzone IDs, and numbers of households.
#The only parameter used by the function is the average number of households per
#blockgroup (AveHhPerBlockGroup) defined in Section 2 of this script. The
#scenario input to the calculations are the household proportions by development
#type for each Azone. The number of households in each Azone and Marea
#designations are pulled from the datastore.
createBzones <- function() {
  #Make matrix of development type proportions by Azone
  Dt <- c("Metropolitan", "Town", "Rural")
  DevTypeProp_AzDt <- cbind(Metropolitan, Town, Rural)
  rownames(DevTypeProp_AzDt) <- Azone
  colnames(DevTypeProp_AzDt) <- Dt
  #Allocate households to development types
  NumHh_Az <- NumHh
  names(NumHh_Az) <- Azone
  Az <- Azone
  DevTypeHh_AzDt <- round(sweep(DevTypeProp_AzDt, 1, NumHh_Az, "*"))
  Remainder_Az <- NumHh_Az - rowSums(DevTypeHh_AzDt)
  Remainder_Ax <- Remainder_Az[Remainder_Az != 0]
  allocateRemainder <- function(Remainder, Ct, Prob_Ct) {
    Sign <- sign(Remainder)
    Remainder <- abs(Remainder)
    Num_Ct <- numeric(length = length(Ct))
    names(Num_Ct) <- Ct
    Allocated_Cx <- table(sample(Ct, Remainder, replace = TRUE, prob = Prob_Ct))
    Num_Ct[names(Allocated_Cx)] <- Allocated_Cx
    Num_Ct * Sign
  }
  if (length(Remainder_Ax) != 0) {
    Ax <- names(Remainder_Ax)
    for (ax in Ax) {
      DevTypeHh_AzDt[ax,Dt] <- DevTypeHh_AzDt[ax,Dt] +
        allocateRemainder(Remainder_Ax[ax], Dt, DevTypeProp_AzDt[ax,Dt])
    }
  }
  #Calculate number of block groups and number of households per block group
  #for each Azone and development type
  NumBlkGrp_AzDt <- round(DevTypeHh_AzDt / AveHhPerBlockGroup)
  NumBlkGrp_Az <- rowSums(NumBlkGrp_AzDt)
  HhPerBlockGroup_AzDt <- ceiling(DevTypeHh_AzDt / NumBlkGrp_AzDt)
  HhPerBlockGroup_AzDt[is.na(HhPerBlockGroup_AzDt)] <- 0
  #Create simulated block groups and associate with metropolitan areas
  Marea_Az <- c(A = "M1", B = "M1", C = "None", D = "None")
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
  NumHh_Bz <- round(rep(Bzone_df$NumHh, Bzone_df$NumZones))
  storage.mode(NumHh_Bz) <- "integer"
  DevType_Bz <- rep(Bzone_df$DevType, Bzone_df$NumZones)
  #Assign the exported values to the Module environment
  assign("Bzone", Bz, envir = Module)
  assign("Azone", Azone_Bz, envir = Module)
  assign("Marea", Marea_Bz, envir = Module)
  assign("NumHh", NumHh_Bz, envir = Module)
  assign("DevType", DevType_Bz, envir = Module)
  #Calculate and assign the total number of Bzones
  #Necessary for calculating a LENGTH attribute used for initializing table
  LENGTH <- numeric(0)
  LENGTH["Bzone"] <- length(Bz)
  assign("LENGTH", LENGTH, envir = Module)
  #Calculate and assign SIZE attributes for 'Bzone', 'Marea', and 'DevType'
  #Necessary for initializing datasets
  SIZE <- numeric(0)
  SIZE["Bzone"] <- max(nchar(Bz))
  SIZE["Azone"] <- max(nchar(Azone_Bz))
  SIZE["Marea"] <- max(nchar(Marea_Bz))
  SIZE["DevType"] <- max(nchar(DevType_Bz))
  assign("SIZE", SIZE, envir = Module)
}

#===================================
#SECTION 2: DEFINE MODULE PARAMETERS
#===================================
#Functions and statements in this section of the script define all of the
#parameters used by the module. Parameters are module inputs that are constant
#for all model runs. Parameters can be put in whatever form that the module
#developer determines works best (e.g. vector, matrix, array, data frame, list,
#etc.). Parameters may be defined in several ways including: 1. By statements
#included in this section (e.g. HhSize <- 2.5); 2. By reading in a data file
#from the "inst/extdata" directory; and, 3. By applying a function which
#estimates the parameters using data in the "inst/extdata" directory.

#In this demo module, only one parameter is defined: the average number of
#households per block group. This shows how model parameters can be defined by
#simple assignment statements.

#Define average number of households per block group
#---------------------------------------------------
AveHhPerBlockGroup <- 400


#==============================
#SECTION 3: BUILDING THE MODULE
#==============================
#There are two steps to building a module. The first step is to define a
#'buildModule' function that, when run, creates an environment that contains all
#components needed by the framework to run the module. The second step runs the
#buildModule function and assigns the resulting environment to an object named
#'CreateBzoneModule'. Then a function named 'CreateBzone' is defined that
#returns this environment object when it is called. It is this function that is
#exported.
#
#The buildModule function does the following 10 things in order to create a
#proper module environment:
#1. Creates an environment named 'Module'.
#2. Assigns the name of the module to the environment.
#3. Assigns the functions that implement the module to the environment .
#4. Defines a function named 'main' which calls each of the module functions in
#the order in which they need to be called when the module is run.
#5. Assigns all the module parameters to the environment.
#6. Identifies the level of geography over at which the module is to be applied.
#7. Identifies scenario inputs that are to be read from files and loaded into
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
#8. Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#  NAME: the name of the dataset to be loaded;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable.
#9. Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#  NAME: the name of the data item that is to be saved;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  SIZE: the maximum number of characters (or 0 for numeric data).
#10. Return the Module object

#Define the buildModule() function
#---------------------------------
#' Build the module.
#'
#' \code{buildModule} builds the module that will carry out the demo models.
#'
#' This function builds the module when it is run. The module is created as an
#' environment which contains all of the necessary elements.
buildModule <- function() {
  #1. Create an environment to hold the module components
  Module <- new.env()
  #2. Module name
  #<Replace with the name of your module.>
  Module$Name <- "CreateBzones"
  #3. Add functions and assign their environments to be 'Module'
  Module$createBzones <- createBzones
  environment(Module$createBzones) <- Module
  #4. Define a main function which calls the other functions.
  Module$main <- function() {
    Module$createBzones()
  }
  #5. Assigns model parameters
  Module$AveHhPerBlockGroup <- AveHhPerBlockGroup
  #6. Identify the level of geography that is iterated over when running the module
  Module$RunBy <- "All"
  #7. Identify scenario input file specifications
  Module$Inp <- items(
    item(
      NAME = "Metropolitan",
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    ),
    item(
      NAME = "Town",
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    ),
    item(
      NAME = "Rural",
      FILE = "devtype_proportions.csv",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    )
  )
  #8. Identify data to be loaded from data store
  Module$Get <- items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Azone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Metropolitan",
      TABLE = "Azone",
      TYPE = "double",
      UNITS = "none",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Town",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Rural",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    )
  )
  #9. Identify data to store
  Module$Set <- items(
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c("Metropolitan", "Town", "Rural")
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "none",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
  #10. Return the Module object
  Module
}

#Run the buildModule function
#----------------------------
CreateBzoneModule <- buildModule()
#' Build the module.
#'
#' \code{CreateBzones} builds the module that will carry out the creation of Bzones.
#'
#' This function builds the module when it is run. The module is created as an
#' environment which contains all of the necessary elements.
#' @export
CreateBzones <- function() {
  CreateBzoneModule
}
