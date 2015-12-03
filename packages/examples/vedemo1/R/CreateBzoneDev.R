#================
#CreateBzoneDev.R
#================

#This demonstration module creates several Bzone development characteristics
#given the development type of each Bzone (i.e. Metropolitan, Town, Rural) and
#the number of households in each Bzone. The created Bzone characteristics
#include average population density (persons per square mile), and numbers of
#single family detached and multi-family dwellings. For 'metropolitan' type
#Bzones, the module also simulates the distance of the Bzone to the urban area
#core. The latter is calculated in conjunction with the calculation of
#population density so the quantities will be consistent (i.e. density decreases
#with distance from the core).

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

#This module contains two functions. The first function, calcBzoneDistDen,
#assigns a population density to each Bzone. It also assigns a distance from the
#urban core to 'metropolitan' type Bzones. The second function,
#calcBuildingTypes, calculates the number of single-family detached dwelling
#units and the number of multi-family dwelling units in each Bzone.

#Function that simulates Bzone population density and distance from center
#-------------------------------------------------------------------------
#The Bzone population density and distance from the urban core for metropolitan
#Bzones are simulated using population, population density, and distance
#distributions compiled by the U.S. Census Bureau. These distributions, are
#model parameters and may be changed as described in the next section of this
#script. Other parameter values used by this function include the average
#household size and average population densitites for town and rural Bzones. The
#results are population density, measured in units of persons per square mile,
#and distance from the the urban center, measured in miles. These results are
#assigned to the module environment as 'PopDen' and 'DistFromCtr' respectively.
calcBzoneDistDen <- function() {
  #Read miscellaneous parameters
  AveHhSize <- MiscParameters_df["AveHhSize", "Value"]
  AveTownDensity <- MiscParameters_df["AveTownDensity", "Value"]
  AveRuralDensity <- MiscParameters_df["AveRuralDensity", "Value"]
  #Create vectors to store density and distance results
  PopDen_Bz <- rep(NA, length(Bzone))
  storage.mode(PopDen_Bz) <- "double"
  DistFromCtr_Bz <- rep(NA, length(Bzone))
  storage.mode(DistFromCtr_Bz) <- "double"
  #Calculate the average density of towns and rural areas
  PopDen_Bz[DevType == "Town"] <- AveTownDensity
  PopDen_Bz[DevType == "Rural"] <- AveRuralDensity
  #Metropolitan density and distance if any DevType is 'Metropolitan'
  if (any(DevType == "Metropolitan")) {
    #Calculate urbanized area density scale
    UrbDenGrad_ <-
      PopDenByDistance_df$PopDensity[which(PopDenByDistance_df$PopDensity >= 1000)]
    DistIndex_ <- 1:length(UrbDenGrad_)
    UrbPopProp_ <- PopByDistance_df$PopProp[DistIndex_]
    UrbPopProp_ <- UrbPopProp_ / sum(UrbPopProp_)
    #Calculate adjusted density gradient
    harmonicMean <- function( Probs., Values. ) {
      1 / sum( Probs. / Values. )
    }
    NumMetroHh <- sum(NumHh[DevType == "Metropolitan"])
    AveMetroDenTarget <- AveHhSize * NumMetroHh / Area
    AveMetroDen <- harmonicMean(UrbPopProp_, UrbDenGrad_)
    DenAdj <- AveMetroDenTarget / AveMetroDen
    UrbAdjDenGrad_ <- UrbDenGrad_ * DenAdj
    #Calculate adjusted distances
    UrbRadius <- sqrt(Area / pi)
    DistAdj <- UrbRadius / PopByDistance_df$Distance[tail(DistIndex_, 1)]
    UrbAdjDist_ <- DistAdj * PopByDistance_df$Distance[DistIndex_]
    #Choose distance and density for each metropolitan Bzone
    NumMetroBzones <- sum(DevType == "Metropolitan")
    MetroBzoneIdx_ <- sample(DistIndex_, NumMetroBzones, replace = TRUE, prob = UrbPopProp_)
    MetroBzoneDen_ <- UrbAdjDenGrad_[MetroBzoneIdx_]
    MetroBzoneDist_ <- UrbAdjDist_[MetroBzoneIdx_]
    #Assign density and distance values to Bzones
    DistFromCtr_Bz[DevType == "Metropolitan"] <- MetroBzoneDist_
    PopDen_Bz[DevType == "Metropolitan"] <- MetroBzoneDen_
  }
  #Assign the exported values to the Module environment
  assign("DistFromCtr", DistFromCtr_Bz, envir = Module)
  assign("PopDen", PopDen_Bz, envir = Module)
}

#Function which estimates building type split based on population density
#------------------------------------------------------------------------
#This function calculates the number of single-family detached dwellings and
#multifamily dwellings in each Bzone. This is done using a toy model which
#relates the proportion of multifamily dwellings to population density. The
#results are the numbers of single-family detached dwellings and multifamily
#detached dwellings in each Bzone. These are assigned to the module environment
#as 'SfdNum' and 'MfdNum' respectively.
calcBuildingTypes <- function() {
  HhDen_Bz <- PopDen / MiscParameters_df["AveHhSize", "Value"]
  MfProp_Bz <- (HhDen_Bz - 500) / 8000
  MfProp_Bz[MfProp_Bz < 0] <- 0
  MfProp_Bz[MfProp_Bz > 1] <- 1
  SfProp_Bz <- 1 - MfProp_Bz
  SfdNum_Bz <- round(NumHh * SfProp_Bz)
  storage.mode(SfdNum_Bz) <- "integer"
  MfdNum_Bz <- NumHh - SfdNum_Bz
  storage.mode(MfdNum_Bz) <- "integer"
  #Assign the exported values to the Module environment
  assign("SfdNum", SfdNum_Bz, envir = Module)
  assign("MfdNum", MfdNum_Bz, envir = Module)
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

#In this demonstration module, parameters are created by reading in data files
#that are stored in the "inst/extdata" directory. These are all comma-separated
#values (csv) formatted text files. This will be the most common form for these
#files because they are easily edited and easily read into R. Documentation for
#each file is included with the file. The corresponding documentation file has
#the same name as the data file, but the file extension is 'txt'. One or more of
#these files may be altered using regional data to customize the module for the
#region.

#Read in parameter data sets
#---------------------------
PopByDistance_df <- read.csv("inst/extdata/pop_by_distance.csv", as.is = TRUE)
PopDenByDistance_df <- read.csv("inst/extdata/pop_density_by_distance.csv", as.is = TRUE)
MiscParameters_df <- read.csv("inst/extdata/misc_parameters.csv", as.is = TRUE, row.names = 1)


#==============================
#SECTION 3: BUILDING THE MODULE
#==============================
#There are two steps to building a module. The first step is to define a
#'buildModule' function that, when run, creates an environment that contains all
#components needed by the framework to run the module. The second step runs the
#buildModule function and assigns the resulting environment to an object named
#'CreateBzoneDevModule'. Then a function named 'CreateBzoneDev' is defined that
#returns this environment object when it is called. It is this function that is
#exported.
#
#The buildModule function does the following 10 things in order to create a proper module environment:
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
buildModule <- function() {
  #1. Create an environment to hold the module components
  Module <- new.env()
  #2. Module name
  #<Replace with the name of your module.>
  Module$Name <- "CreateBzoneDev"
  #3. Add functions and assign their environments to be 'Module'
  Module$calcBzoneDistDen <- calcBzoneDistDen
  environment(Module$calcBzoneDistDen) <- Module
  Module$calcBuildingTypes <- calcBuildingTypes
  environment(Module$calcBuildingTypes) <- Module
  #4. Define a main function which calls the other functions.
  Module$main <- function() {
    Module$calcBzoneDistDen()
    Module$calcBuildingTypes()
  }
  #5. Assigns model parameters
  Module$PopByDistance_df <- PopByDistance_df
  Module$PopDenByDistance_df <- PopDenByDistance_df
  Module$MiscParameters_df <- MiscParameters_df
  #6. Identify the level of geography that is iterated over when running the module
  Module$RunBy <- "Marea"
  #7. Identify scenario input file specifications
  Module$Inp <- items(
    item(
      NAME = "Area",
      FILE = "marea_area.csv",
      TABLE = "Marea",
      TYPE = "double",
      UNITS = "square miles",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    )
  )
  #8. Identify data to be loaded from data store
  Module$Get <- items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Area",
      TABLE = "Marea",
      TYPE = "double",
      UNITS = "square miles",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "none",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    )
  )
  #9. Identify data to store
  Module$Set <- items(
    item(
      NAME = "DistFromCtr",
      TABLE = "Bzone",
      TYPE = "double",
      UNITS = "miles",
      NAVALUE = -1,
      PROHIBIT = c("< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "PopDen",
      TABLE = "Bzone",
      TYPE = "double",
      UNITS = "persons per square mile",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "SfdNum",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "dwelling units",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "MfdNum",
      TABLE = "Bzone",
      TYPE = "integer",
      UNITS = "dwelling units",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
  #10. Return the Module object
  Module
}

#Run the buildModule function
#----------------------------
CreateBzoneDevModule <- buildModule()
#' Build the module.
#'
#' \code{CreateBzoneDev} produces the module that will simulate various
#' development characteristics of Bzones.
#'
#' This function produces the module that will simulate various Bzone
#' development characteristics when it is run.
#' @export
CreateBzoneDev <- function() {
  CreateBzoneDevModule
}
