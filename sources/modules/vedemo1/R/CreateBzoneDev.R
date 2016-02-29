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

#In this demonstration module, parameters are created by reading in data files
#that are stored in the "inst/extdata" directory. These are all comma-separated
#values (csv) formatted text files. This will be the most common form for these
#files because they are easily edited and easily read into R. Documentation for
#each file is included with the file. The corresponding documentation file has
#the same name as the data file, but the file extension is 'txt'. One or more of
#these files may be altered using regional data to customize the module for the
#region.

#Describe specifications for data that is to be used in estimating the model
#---------------------------------------------------------------------------
#Data on the proportion of population by distance from urban area core
PopByDistanceInp_ls <- items(
  item(
    NAME = "Distance",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "PopProp",
    TYPE = "double",
    PROHIBIT = c("NA", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Data on population density by distance from urban area core
PopDenByDistanceInp_ls <- items(
  item(
    NAME = "Distance",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "PopDensity",
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Data on miscellaneous parameters
MiscDevParametersInp_ls <- items(
  item(
    NAME = "Parameter",
    TYPE = "Character",
    PROHIBIT = c("NA"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "Value",
    TYPE = "double",
    PROHIBIT = c("NA", "<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Read in, check and save population by distance parameters
#---------------------------------------------------------
PopByDistance_df <- processEstimationInputs(PopByDistanceInp_ls,
                                            "pop_by_distance.csv",
                                            "CreateBzoneDev")
#' Population proportions by distance
#'
#' A dataset containing the proportions of urbanized area population by distance
#' from the urban center rounded to nearest whole mile.
#'
#' @format A data frame with 40 rows and 2 variables:
#' \describe{
#'  \item{Distance}{distance from urban center, in miles}
#'  \item{PopProp}{proportion of urbanized area population}
#' }
#' @source CreateBzonesDev.R script.
"PopByDistance_df"
devtools::use_data(PopByDistance_df, overwrite = TRUE)

#Read in, check and save population density by distance parameters
#-----------------------------------------------------------------
PopDenByDistance_df <- processEstimationInputs(PopDenByDistanceInp_ls,
                                               "pop_density_by_distance.csv",
                                               "CreateBzoneDev")
#' Population density by distance
#'
#' A dataset containing the average census block group population density by
#' distance from the urban center rounded to nearest whole mile.
#'
#' @format A data frame with 40 rows and 2 variables:
#' \describe{
#'  \item{Distance}{distance from urban center, in miles}
#'  \item{PopDensity}{population density, in persons per square mile}
#' }
#' @source CreateBzonesDev.R script.
"PopDenByDistance_df"
devtools::use_data(PopDenByDistance_df, overwrite = TRUE)

#Read in, check and save miscellaneous parameters
#------------------------------------------------
MiscDevParameters_df <- processEstimationInputs(MiscDevParametersInp_ls,
                                                "misc_dev_parameters.csv",
                                                "CreateBzoneDev")
#' Miscellaneous Bzone development model parameters
#'
#' A dataset containing parameters for average household size, average town
#' population density, and average rural population density.
#'
#' @format A data frame with 3 rows and 2 variables:
#' \describe{
#'  \item{Parameter}{name of the parameter}
#'  \item{Value}{value of the parameter}
#' }
#' @source CreateBzonesDev.R script.
"MiscDevParameters_df"
devtools::use_data(MiscDevParameters_df, overwrite = TRUE)



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
CreateBzoneDevSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Marea",
  #Specify input data
  Inp = items(
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
      TOTAL = ""
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
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
  ),
  #Specify data to saved in the data store
  Set = items(
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
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateBzoneDev module
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
"CreateBzoneDevSpecifications"
devtools::use_data(CreateBzoneDevSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateBzoneDev". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#This module contains two functions in addition to the main function. The first
#function, calcBzoneDistDen, assigns a population density to each Bzone.
#It also assigns a distance from the urban core to 'metropolitan' type Bzones.
#The second function, calcBuildingTypes, calculates the number of single-family
#detached dwelling units and the number of multi-family dwelling units in each
#Bzone.

#Note that since the calcBzoneDistDen and calcBuildingTypes functions are
#defined outside of the main function (CreateBzoneDev), these functions don't
#have access to variables within the scope of the main function and therefore
#all their necessary inputs must be passed to them. This is done by passing
#a list, L, that contains all of the inputs.

#Function that simulates Bzone population density and distance from center
#-------------------------------------------------------------------------
#' Simulate Bzone density and distance characteristics
#'
#' \code{calcBzoneDistDen} simulates the population density of all Bzones
#' and distance from the urban core for Bzones whose DevType is "Metropolitan".
#'
#' The Bzone population density and distance from the urban core for
#' metropolitan Bzones are simulated using population, population density, and
#' distance distributions compiled by the U.S. Census Bureau.
#'
#' @param L A list containing the following components that have been read
#' from the datastore:
#' Bzone: A character vector of Bzone names read from the Bzone table.
#' DevType: A character vector identifying the development type of each Bzone
#' read from the Bzone table.
#' NumHh: A integer vector of the number of households in each Bzone read from
#' the Bzone table.
#' Area: A number identifying the geographic area of the metropolitan area read
#' from the Marea table.
#' @return A list containing the following components:
#' DistFromCtr: A numeric vector of the distance of each Bzone from the urban
#' area center.
#' PopDen: A numeric vector of the population density of each Bzone.
#' @export
calcBzoneDistDen <- function(L) {
  #Read miscellaneous parameters
  MiscParameters_ <- MiscDevParameters_df$Value
  names(MiscParameters_) <- MiscDevParameters_df$Parameter
  AveHhSize <- MiscParameters_["AveHhSize"]
  AveTownDensity <- MiscParameters_["AveTownDensity"]
  AveRuralDensity <- MiscParameters_["AveRuralDensity"]
  #Create vectors to store density and distance results
  Bz <- L$Bzone
  PopDen_Bz <- numeric(length(Bz))
  DistFromCtr_Bz <- numeric(length(Bz)) * NA
  #Calculate the average density of towns and rural areas
  PopDen_Bz[L$DevType == "Town"] <- AveTownDensity
  PopDen_Bz[L$DevType == "Rural"] <- AveRuralDensity
  #Metropolitan density and distance if any DevType is 'Metropolitan'
  if (any(L$DevType == "Metropolitan")) {
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
    NumMetroHh <- sum(L$NumHh[L$DevType == "Metropolitan"])
    AveMetroDenTarget <- AveHhSize * NumMetroHh / L$Area
    AveMetroDen <- harmonicMean(UrbPopProp_, UrbDenGrad_)
    DenAdj <- AveMetroDenTarget / AveMetroDen
    UrbAdjDenGrad_ <- UrbDenGrad_ * DenAdj
    #Calculate adjusted distances
    UrbRadius <- sqrt(L$Area / pi)
    DistAdj <- UrbRadius / PopByDistance_df$Distance[tail(DistIndex_, 1)]
    UrbAdjDist_ <- DistAdj * PopByDistance_df$Distance[DistIndex_]
    #Choose distance and density for each metropolitan Bzone
    NumMetroBzones <- sum(L$DevType == "Metropolitan")
    MetroBzoneIdx_ <- sample(DistIndex_, NumMetroBzones, replace = TRUE,
                             prob = UrbPopProp_)
    MetroBzoneDen_ <- UrbAdjDenGrad_[MetroBzoneIdx_]
    MetroBzoneDist_ <- UrbAdjDist_[MetroBzoneIdx_]
    #Assign density and distance values to Bzones
    DistFromCtr_Bz[L$DevType == "Metropolitan"] <- MetroBzoneDist_
    PopDen_Bz[L$DevType == "Metropolitan"] <- MetroBzoneDen_
  }
  #Return the results in a list
  list(
    DistFromCtr = DistFromCtr_Bz,
    PopDen = PopDen_Bz
  )
}

#Function which estimates building type split based on population density
#------------------------------------------------------------------------
#' Simulate Bzone dwelling types.
#'
#' \code{calcBuildingTypes} calculates the number of single-family dwellings and
#' the number of multifamily dwelling units in each Bzone.
#'
#' This function calculates the number of single-family detached dwellings and
#' multifamily dwellings in each Bzone. This is done using a toy model which
#' relates the proportion of multifamily dwellings to population density. The
#' results are the numbers of single-family detached dwellings and multifamily
#' detached dwellings in each Bzone.
#'
#' @param L A list containing the following components that have been either
#' read from the datastore or produced by the application of the
#' calcBzoneDistDen function:
#' PopDen: A numeric vector of the population density of each Bzone produced by
#' the calcBzoneDistDen function.
#' NumHh: An integer vector of the number of households in each Bzone read from
#' the Bzone table.
#' @return A list containing the following components:
#' SfdNum: An integer vector of the number of households living in single-family
#' dwellings in each Bzone.
#' MfdNum: An integer vector of the number of households living in multifamily
#' dwellings in each Bzone.
#' @export
calcBuildingTypes <- function(L) {
  #Read miscellaneous parameters
  MiscParameters_ <- MiscDevParameters_df$Value
  names(MiscParameters_) <- MiscDevParameters_df$Parameter
  HhDen_Bz <- L$PopDen / MiscParameters_["AveHhSize"]
  MfProp_Bz <- (HhDen_Bz - 500) / 8000
  MfProp_Bz[MfProp_Bz < 0] <- 0
  MfProp_Bz[MfProp_Bz > 1] <- 1
  SfProp_Bz <- 1 - MfProp_Bz
  SfdNum_Bz <- round(L$NumHh * SfProp_Bz)
  storage.mode(SfdNum_Bz) <- "integer"
  MfdNum_Bz <- L$NumHh - SfdNum_Bz
  storage.mode(MfdNum_Bz) <- "integer"
  #Return the results in a list
  list(
    SfdNum = SfdNum_Bz,
    MfdNum = MfdNum_Bz
  )
}

#The main function, CreateBzoneDev
#---------------------------------
#' Calculate Bzone development characteristics
#'
#' \code{CreateBzoneDev} is the main function of the CreateBzoneDev module that
#' calls the calcBzoneDistDen and calcBuildingTypes functions to calculate
#' Bzone development characteristics.
#'
#' This is the main function for the CreateBzoneDev module. It is a wrapper for
#' the calcBzoneDistDen and calcBuildingTypes functions which do all of the
#' work of calculating Bzone development characteristics including distance from
#' the urban area center, population density, number of households in single-
#' family dwellings, and number of households in multifamily dwellings.
#'
#' @param L A list containing the following components that have been read from
#' the datastore:
#' Bzone: A character vector of Bzone names read from the Bzone table.
#' DevType: A character vector identifying the development type of each Bzone
#' read from the Bzone table.
#' NumHh: A integer vector of the number of households in each Bzone read from
#' the Bzone table.
#' Area: A number identifying the geographic area of the metropolitan area read
#' from the Marea table.
#' @return A list containing the following components:
#' DistFromCtr: A numeric vector of the distance of each Bzone from the urban
#' area center.
#' PopDen: A numeric vector of the population density of each Bzone.
#' SfdNum: An integer vector of the number of households living in single-family
#' dwellings in each Bzone.
#' MfdNum: An integer vector of the number of households living in multifamily
#' dwellings in each Bzone.
#' @export
CreateBzoneDev <- function(L) {
  #Calculate Bzone densities and distances and combine with the input list
  L <- c(L, calcBzoneDistDen(L))
  #Calculate Bzone building types and combine with the input list
  L <- c(L, calcBuildingTypes(L))
  #Return a list of values to be saved in the datastore
  L[c("DistFromCtr", "PopDen", "SfdNum", "MfdNum")]
}
