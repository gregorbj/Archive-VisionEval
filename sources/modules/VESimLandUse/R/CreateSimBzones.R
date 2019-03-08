#=================
#CreateSimBzones.R
#=================

#<doc>
## CreateSimBzones Module
#### February 1, 2019
#
#This module synthesizes Bzones and their land use attributes as a function of Azone characteristics as well as data derived from the US Environmental Protection Agency's Smart Location Database (SLD) augmented with US Census housing and household income data, and data from the National Transit Database. Details on these data are included in the VESimLandUseData package. The combined dataset contains a number of land use attributes at the US Census block group level. The goal of Bzone synthesis to generate a set of SimBzones in each Azone that reasonably represent block group land use characteristics given the characteristics of the Azone, the Marea that the Azone is a part of, and scenario inputs provided by the user.
#
#Many of the models and procedures used in Bzone synthesis pivot from profiles developed from these data sources for specific urbanized areas, as well as more general profiles for different urbanized area population size categories, towns, and rural areas. Using these specific and general profiles enables the simulated Bzones (SimBzones) to better represent the areas being modeled and the variety of conditions found in different states. The documentation for the `Initialize` module has a listing of urbanized area profile names.
#
#The models and procedures in this module create SimBzones within each Azone that simulate the land use characteristics of neighborhoods likely to be found in the Azone. The SimBzones are assigned quantities of households and jobs and are attributed with several land use measures in the process. The characteristics are:
#
#* **Location Type**: Identification of whether the SimBzone is located in an urbanized area, a town (i.e. an urban-type area that is not large enough to be urbanized), rural (i.e. dispersed low-density development)
#
#* **Households**: Number of households in each SimBzone
#
#* **Employment**: Number of jobs in each SimBzone
#
#* **Activity Density**: Number of households and jobs per acre
#
#* **Land Use Diversity**: Measures of the degree of mixing of households and jobs
#
#* **Destination Accessibility**: Measures of proximity to households and jobs
#
#* **Area Type and Development Type**: Categories which describe the relative urban nature of the SimBzone (area type) and the character of development in the SimBzone (development type).
#
#* **Employment Split**: Number of retail, service, and other jobs in each SimBzone.
#
### Model Parameter Estimation
#
#All the model parameters used in simulating SimBzones area estimated by the **CreateSimBzoneModels** module. Refer to that module's documentation for more information.
#
### How the Module Works
#
#The module creates SimBzones in the following steps:
#
#1) **Calculate the Number of Households by Azone and Location Type**: The number of households by Azone is loaded from the datastore. User-specified proportions of households by location type (urban, town, rural) for each Azone are used to divide the households among location types in each azone in whole numbers.
#
#2) **Calculate the Number of Jobs by Azone and Location Type**: The number of workers by Azone is loaded from the datastore: User-specified proportions of worker work location by location type (urban, town, rural) for each Azone are used to allocate workers by work location among location types. Work locations within the urban portion of an Marea are allocated among the urban portions of Azones associated with the Marea based on user-specified proportions of the urbanized area jobs located in the urban location type of each of the associated Azones.
#
#3) **Create SimBzones by Azone and Location Type**: SimBzones are created to have roughly equal activity totals (households and jobs). The total activity (sum of households and jobs) in each Azone and location type (calculated in the previous step) is divided by median value calculated for block groups of that location type from the SLD data. The *Create SimBzones by Azone and Location Type* section of *CreateSimBzoneModel* module documentation describes this in more detail.
#
#4) **Assign an Activity Density to Each SimBzone**: A model is applied to calculate a likely distribution of SimBzone activity densities for each location type in each Azone. The density distribution is a function of the overall density calculated from user land area inputs for urban and town location types and average density for rural types, and the amount of activity by location type in the Azone. Model parameters vary by location type and urbanized area. The *Assign an Activity Density to Each SimBzone* section of the *CreateSimBzonesModel* module documentation describes these models in more detail. These distributions are used as sampling distributions to assign a preliminary activity density to each SimBzone in the Azone. The SimBzone densities are then adjusted to be consistent with the land area (urban and town) and density (rural) input assumptions.
#
#5) **Assign a Jobs and Housing Mix Level to Each SimBzone**: A household and jobs mixing category (primarily-hh, largely-hh, mixed, largely-jobs, primarily-jobs) is assigned to each SimBzone using the appropriate model described in the *Assign a Jobs and Housing Mix Level to Each SimBzone* section of the *CreateSimBzonesModel* module documentation.
#
#6) **Split SimBzone Activity Between Jobs and Households**: A first-cut split of activity between jobs and housing in each SimBzone is made based on the assigned mix level using the models described in the *Split SimBzone Activity Between Jobs and Households* section of the *CreateSimBzonesModel* module documentation. The jobs and household splits are adjusted so that the control totals by Azone and location type are matched. The mix level designations are adjusted accordingly.
#
#7) **Assign Destination Accessibility Measure Values to SimBzones**: Destination accessibility levels are assigned to SimBzones as a function of SimBzone density levels using the models described in the *Assign Destination Accessibility Measure Values to SimBzones* section of the *CreateSimBzonesModel* module documentation.
#
#8) **Model Housing Types**: Housing types (single family, multifamily) to be occupied by households in each SimBzone are calculated using models described in the *Model Housing Types* section of the *CreateSimBzonesModel* module documentation. These values are used in the *PredictHousing* module to assign a housing type to each household and then assign households to SimBzones as a function of their housing type choice.
#
#9) **Designate Place Types**: Place types simplify the characterization of land use patterns. They are used in the VESimLandUse package modules to simplify the management of inputs for land use related policies. They are also used in the models for splitting employment into sectors and for establish the pedestrian-oriented network design value. There are three dimensions to the place type system. Location type identifies whether the SimBzone is located in an urbanized area (Urban), a smaller urban-type area (Town), or a non-urban area (Rural). Area types identify the relative urban nature of the SimBzone: center, inner, outer, fringe. Development types identify the character of development in the SimBzone: residential, employment, mix. The methods used for designating SimBzone place types are described in detail in the *Designate Place Types* section of the *CreateSimBzonesModel* module documentation.
#
#10) **Split SimBzone Employment Into Sectors**: SimBzone employment is split between 3 sectors (retail, service, other). This is done for the purpose of enabling the calculation of an entropy measure of land use mixing that is used in the forthcoming multimodal household travel for VisionEval (described below). The models described in the *Split SimBzone Employment Into Sectors* section of the *CreateSimBzonesModel* module documentation are applied to carry out the splits. The entropy measure is calculated in the same way as the `D2a_EpHHm` measure is calculated in the Smart Location Database (SLD) with the exception that only 3 employment sectors are used instead of 5. The calculations are described in Table 5 of SLD [users guide](https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide).
#
#11) **Model Pedestrian-Oriented Network Design (D3bpo4)**: The D3pbo4 pedestrian-oriented network design measure described in the SLD users guide is assigned to each SimBzone using models described in the *Model Pedestrian-Oriented Network Design (D3bpo4)* section of the *CreateSimBzonesModel* module documentation.
#
#
##</doc>

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
#Load libraries
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

#All models and parameters used by this module are estimated by the
#CreateSimBzoneModels module.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#' @import visioneval

#Define the data specifications
#------------------------------
CreateSimBzonesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Bzone",
      GROUP = "Year"
    )
  ),
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UzaProfileName",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumWkr",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "PropMetroHh",
        "PropTownHh",
        "PropRuralHh"
      ),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "PropWkrInMetroJobs",
        "PropWkrInTownJobs",
        "PropWkrInRuralJobs",
        "PropMetroJobs"
      ),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "MetroLandArea",
        "TownLandArea"
      ),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "RuralAveDensity",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HHJOB/ACRE",
      PROHIBIT = c("NA", "< 0"),
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
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = "Unique ID for SimBzone"
    ),
    item(
      NAME = "Azone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = "Azone that SimBzone is located in"
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = "Marea associated with Azone that SimBzone is located in"
    ),
    item(
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural"),
      SIZE = 5,
      DESCRIPTION = "Location type (Urban, Town, Rural) of the place where the household resides"
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of households allocated to the SimBzone"
    ),
    item(
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp",
              "OthEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Total number of jobs in zone",
          "Number of jobs in retail sector in zone",
          "Number of jobs in service sector in zone",
          "Number of jobs in other than the retail and service sectors in zone"
        )
    ),
    item(
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = c("center", "inner", "outer", "fringe"),
      SIZE = 6,
      DESCRIPTION = "Area type (center, inner, outer, fringe) of the Bzone"
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = c("emp", "mix", "res"),
      SIZE = 5,
      DESCRIPTION = "Location type (Urban, Town, Rural) of the Bzone"
    ),
    item(
      NAME = "D1D",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HHJOB/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Gross activity density (employment + households) on unprotected land in zone (Ref: EPA 2010 Smart Location Database)"
    ),
    item(
      NAME = "D5",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Destination accessibility of zone calculated as harmonic mean of jobs within 2 miles and population within 5 miles"
    ),
    item(
      NAME =
        items(
          "UrbanArea",
          "TownArea",
          "RuralArea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Area that is Urban and unprotected (i.e. developable) within the zone",
          "Area that is Town and unprotected (i.e. developable) within the zone",
          "Area that is Rural and unprotected (i.e. developable) within the zone"
        )
    ),
    item(
      NAME =
        items(
          "SFDU",
          "MFDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Number of single family dwelling units (PUMS codes 01 - 03) in zone",
          "Number of multi-family dwelling units (PUMS codes 04 - 09) in zone"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateSimBzones module
#'
#' A list containing specifications for the CreateSimBzones module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{NewSetTable}{new table to be created for datasets specified in the
#'  'Set' specifications}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateSimBzones.R script.
"CreateSimBzonesSpecifications"
usethis::use_data(CreateSimBzonesSpecifications, overwrite = TRUE)
rm(CreateSimBzonesSpecifications)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#------------------------------
#PROCESS FOR CREATING SIMBZONES
#------------------------------
#SimBzones approximate Census block groups. They are created to have
#approximately equal amounts of total activity (number of households and jobs)
#consistent with control totals for the Azone. These control totals are the
#numbers of households and jobs by location type. The user specifies by Azone,
#the proportions of Azone households by location type. Those proportions are
#used to allocate numbers of households to location types in the Azone. The user
#also specifies the proportions of resident Azone workers by location type job
#location. In addition the proportion of Marea jobs in the Azone is a user user
#input. These data are used to calculate the number of jobs by Azone and
#location type. Households and jobs by location type are summed to determine the
#total amount of activity by Azone and location type. SimBzones are created for
#each location type in each Azone.

#Define function to allocate integer quantities among categories
#---------------------------------------------------------------
#' Allocate integer quantities among categories
#'
#' \code{splitIntegers} splits a total value into a vector of whole numbers to
#' reflect input vector of proportions
#'
#' This function splits an input total into a vector of whole numbers to reflect
#' an input vector of proportions. If the input total is not an integer, the
#' value is rounded and converted to an integer.
#'
#' @param Tot a number that is the total value to be split into a vector of
#' whole numbers corresponding to the input proportions. If Tot is not an
#' integer, its value is rounded and converted to an integer.
#' @param Props_ a numeric vector of proportions used to split the total value.
#' The values should add up to approximately 1. The function will adjust so that
#' the proportions do add to 1.
#' @return a numeric vector of whole numbers corresponding to the Props_
#' argument which sums to the Tot.
#' @export
splitIntegers <- function(Tot, Props_) {
  #Convert Tot into an integer
  if (!is.integer(Tot)) {
    Tot <- as.integer(round(Tot))
  }
  #If Tot is 0, return vector of zeros
  if (Tot == 0) {
    integer(length(Props_))
  } else {
    #Make sure that Props_ sums exactly to 1
    Props_ <- Props_ / sum(Props_)
    #Make initial whole number split
    Ints_ <- round(Tot * Props_)
    #Determine the difference between the initial split and the total
    Diff <- Tot - sum(Ints_)
    #Allocate the difference
    if (Diff != 0) {
      for (i in 1:abs(Diff)) {
        IdxToChg <- sample(1:length(Props_), 1, prob = Props_)
        Ints_[IdxToChg] <- Ints_[IdxToChg] + sign(Diff)
      }
    }
    unname(Ints_)
  }
}

#Define function to calculate number of households by location type
#------------------------------------------------------------------
#' Calculate number of households by location type
#'
#' \code{calcNumHhByLocType} calculates the number of households by location
#' type for a set of Azones.
#'
#' This function calculates the number of households by location type for a
#' set of Azones as a function of the total number of households by Azone and
#' user inputs on the proportions of households by location type and Azone.
#' Location types are metropolitan (i.e. urbanized area), town (i.e. urban areas
#' that are not urbanized), and rural.
#'
#' @param NumHh_Az A numeric vector of the total number of households in each
#' Azone.
#' @param PropRuralHh_Az A numeric vector identifying the proportion of
#'   households in each Azone that are located in rural locations.
#' @param PropTownHh_Az A numeric vector identifying the proportion of
#'   households in each Azone that are located in town locations.
#' @param PropMetroHh_Az A numeric vector identifying the proportion of
#'   households in each Azone that are located in metropolitan locations.
#' @param Az A character vector of Azone names.
#' @return A list having 3 named components (Rural, Town, Metropolitan) where
#' each component is a numeric vector identifying the number of households in
#' the respective location type in each Azone.
#' @export
calcNumHhByLocType <-
  function(NumHh_Az, PropRuralHh_Az, PropTownHh_Az, PropMetroHh_Az, Az) {
    HhProp_AzLt <- cbind(
      Rural = PropRuralHh_Az,
      Town = PropTownHh_Az,
      Urban = PropMetroHh_Az)
    Hh_AzLt <- t(apply(cbind(NumHh_Az, HhProp_AzLt), 1, function(x) {
      splitIntegers(x[1], x[2:4])}))
    colnames(Hh_AzLt) <- colnames(HhProp_AzLt)
    rownames(Hh_AzLt) <- Az
    #Return as list
    #--------------
    list(
      Rural = Hh_AzLt[,"Rural"],
      Town = Hh_AzLt[,"Town"],
      Urban = Hh_AzLt[,"Urban"]
    )
  }

#Define function to calculate the number of jobs by Azone location type
#----------------------------------------------------------------------
#' Calculate number of jobs by location type
#'
#' \code{calcNumJobsByLocType} calculates the number of jobs by location type
#' for a set of Azones
#'
#' This function calculates the number of jobs by location type for a set of
#' Azones as a function of the total number of workers by Azone and user inputs
#' on the proportions of jobs by location type (metropolitan, town, rural) and
#' Azone. In addition, the user specifies the proportional allocation of jobs
#' among the metropolitan portions of Azones that make up an Marea. The function
#' logic is based on the assumption that Azone workers having jobs in town and
#' rural locations, will work within the Azone where they reside but that
#' workers having metropolitan jobs may work in a different Azone portion of the
#' metropolitan area which includes their Azone.
#'
#' @param NumWkr_Az A numeric vector of the total number of workers residing in
#' each Azone.
#' @param PropWkrInRuralJobs_Az A numeric vector of the proportions of workers
#'   in each Azone that have jobs located in rural locations.
#' @param PropWkrInTownJobs_Az A numeric vector of the proportions of workers in
#'   each Azone that have jobs located in town locations.
#' @param PropWkrInMetroJobs_Az A numeric vector of the proportions of workers
#'   in each Azone that have jobs located in metropolitan locations.
#' @param PropMetroJobs_Az A numeric vector identifying the proportion of
#' metropolitan jobs for the Marea that the Azone is a part of that are located
#' in the metropolitan portion of the Azone.
#' @param Marea_Az A character vector identifying the Marea associated with each
#' Azone.
#' @param Az A character vector of Azone names.
#' @return A list having 3 named components (Rural, Town, Metropolitan) where
#'   each component is a numeric vector identifying the number of jobs in the
#'   respective location type in each Azone.
#' @export
calcNumJobsByLocType <-
  function(NumWkr_Az, PropWkrInRuralJobs_Az, PropWkrInTownJobs_Az,
           PropWkrInMetroJobs_Az, PropMetroJobs_Az, Marea_Az, Az) {

    #Initial allocation of jobs within Azones
    #----------------------------------------
    JobProp_AzLt <- cbind(
      Rural = PropWkrInRuralJobs_Az,
      Town = PropWkrInTownJobs_Az,
      Metropolitan = PropWkrInMetroJobs_Az)
    Jobs_AzLt <- t(apply(cbind(NumWkr_Az, JobProp_AzLt), 1, function(x) {
      splitIntegers(x[1], x[2:4])
    }))
    colnames(Jobs_AzLt) <- colnames(JobProp_AzLt)
    rownames(Jobs_AzLt) <- Az

    #Reallocate metropolitan jobs among Azones in the Marea
    #------------------------------------------------------
    #Create data frame of metropolitan data
    Metro_df <- data.frame(
      Jobs = Jobs_AzLt[,"Metropolitan"],
      PropMetroJobs = PropMetroJobs_Az,
      Marea = Marea_Az,
      Azone = Az
    )
    #Split by metropolitan area
    Metro_Ma_df <- split(Metro_df, Metro_df$Marea)
    #Allocate metropolitan jobs among Azones in Marea
    MetroJobs_Az <- unlist(lapply(Metro_Ma_df, function(x) {
      splitIntegers(sum(x$Jobs), x$PropMetroJobs)
    }), use.names = FALSE)
    names(MetroJobs_Az) <- unlist(lapply(Metro_Ma_df, function(x) x$Azone))
    MetroJobs_Az <- MetroJobs_Az[Az]

    #Return as list
    #--------------
    list(
      Rural = Jobs_AzLt[,"Rural"],
      Town = Jobs_AzLt[,"Town"],
      Urban = MetroJobs_Az
    )
  }

#Define function to allocate activity to SimBzones
#-------------------------------------------------
#' Create SimBzones and allocate total activity among them
#'
#' \code{allocateActivityToSimBzones} creates a whole number of SimBzones to
#' accommodate total activity (households and jobs) given a median SimBzone size
#' for the location type. Allocates activity to the SimBzones.
#'
#' This function creates a numeric vector containing amounts of activity (jobs
#' and households). The number of SimBzones is determined by the total activity
#' and the median SimBzone size for the location type. Total activity is
#' allocated among the SimBzones in equal proportions using the splitIntegers
#' function. This function is called by initSimBzones function.
#'
#' @param Activity a number that is the total number of households and jobs
#' assigned to a location type in an Azone.
#' @param LocType a string identifying the location type (Urban, Town, or Rural).
#' @return A numeric vector containing whole number values representing the
#' amount of activity (households and jobs) in each SimBzone.
#' @export
allocateActivityToSimBzones <- function(Activity, LocType) {
  Size <- switch(LocType,
                 Rural = SimBzone_ls$RuProfiles$MedianSimBzoneSize,
                 Town = SimBzone_ls$TnProfiles$MedianSimBzoneSize,
                 Urban = SimBzone_ls$UaProfiles$MedianSimBzoneSize)
  NumZones <- round(Activity / Size)
  Props <- rep(Size / Activity, NumZones)
  if (Activity < Size) {
    unname(Activity)
  } else {
    splitIntegers(Activity, Props)
  }
}

#Define function to initialize SimBzones
#---------------------------------------
#' Creates SimBzones to accommodate the activity assigned to a set of Azones.
#'
#' \code{initSimBzones} creates a set of SimBzones which accomodates the
#' activity assigned to location types in Azones.
#'
#' This function creates a set of SimBzones for a set of Azones which
#' accommodates the activity (households and jobs) assigned to each location
#' type (Urban, Town, Rural) in each of the Azones. It calls the
#' allocateActivity function to create a vector of SimBzones activity amounts to
#' accommodate the total activity assigned to to a location type in an Azone. It
#' creates a data frame which in addition to containing the activity allocation,
#' assigns a unique ID to each SimBzone and also identifies the Azone and Marea
#' the SimBzone is in. It also identifies the location type (LocType) of each
#' SimBzone.
#'
#' @param RuralActivity_Az a numeric vector identifying the amount of activity
#' assigned to the rural location type in each Azone.
#' @param TownActivity_Az a numeric vector identifying the amount of activity
#' assigned to the town location type in each Azone.
#' @param UrbanActivity_Az a numeric vector identifying the amount of activity
#' assigned to the urban location type in each Azone.
#' @param Az a character vector identifying the name of each Azone.
#' @param Marea_Az a character vector identifying the name of the Marea that
#' each Azone is associated with.
#' @return A data frame containing Bzone names, Azone names, Marea names,
#' LocType, and activity, where each row represents a SimBzone.
initSimBzones <-
  function(RuralActivity_Az, TownActivity_Az, UrbanActivity_Az, Az, Marea_Az) {
    #Naming vector for location types
    Lt <- c("Rural", "Town", "Urban")
    #Function to create Bzone codes from vector of integers
    intsToCodes <- function(Ints_) {
      MaxChar <- max(nchar(Ints_))
      unlist(sapply(Ints_, function(x) {
        Leading0s <- rep("0", MaxChar - nchar(x))
        paste(c(Leading0s, x), collapse = "")
      }))
    }
    #Create list of Bzone data frames by Azone
    Bzones_Az_df <- list()
    for (az in Az) {
      Bzones_df <- rbind(
        data.frame(
          Activity = allocateActivityToSimBzones(RuralActivity_Az[az], "Rural"),
          LocType = "Rural"
        ),
        data.frame(
          Activity = allocateActivityToSimBzones(TownActivity_Az[az], "Town"),
          LocType = "Town"
        ),
        data.frame(
          Activity = allocateActivityToSimBzones(UrbanActivity_Az[az], "Urban"),
          LocType = "Urban"
        )
      )
      Bzones_df <- Bzones_df[Bzones_df$Activity != 0,]
      Bzones_df$Bzone <- paste0(az, intsToCodes(1:nrow(Bzones_df)))
      Bzones_df$Azone <- az
      Bzones_df$Marea <- Marea_Az[az]
      Bzones_Az_df[[az]] <- Bzones_df
    }
    Bzones_df <- do.call(rbind, Bzones_Az_df)
    Bzones_df$LocType <- as.character(Bzones_df$LocType)
    rownames(Bzones_df) <- NULL
    Bzones_df
  }

#Function to adjust density distributions to match average density target
#------------------------------------------------------------------------
#' Determine the activity density (households and jobs per acre) for a set of
#' SimBzones assigned to a location type in an Azone.
#'
#' \code{calcDensityDistribution} calculates the activity density (households
#' and jobs per acre) for each SimBzone assigned to a location type in an Azone.
#'
#' This function calculates the activity density (households and jobs per acre)
#' for each SimBzone assigned to a location type in an Azone. The densities are
#' calculated so that the overall average density of all the SimBzones equals
#' the average activity density for the total activity and land area assigned to
#' the location type. SimBzones are also assign activity density levels which
#' are used in models to assign destination accessibility and activity diversity.
#'
#' @param Activity_Bz A numeric vector of the amount of activity assigned to
#' each SimBzone for SimBzones assigned to a location type in an Azone.
#' @param LocType A string identifying the location type (Urban, Town, Rural)
#' that the SimBzones are assigned to.
#' @param TargetArea A number identifying the area in acres that is assigned
#' to accommodate the activity in the location type in the Azone. A value must
#' be supplied if the LocType is Urban or Town and not supplied if the LocType
#' is Rural.
#' @param TargetDensity A number identifying the average density of activity
#' (households and jobs per acre) in the LocType in the Azone. A value must be
#' supplied if the LocType is Rural and not supplied if the LocType is Urban or
#' Town.
#' @param UzaProfileName A string identifying the name of the urbanized area
#' profile associated with the Marea. A value must be provided if the LocType
#' is Urban.
#' @return A data frame with columns identifying activity density, activity
#' density level, and area of each SimBzone.
#' @export
calcDensityDistribution <-
  function(Activity_Bz,
           LocType,
           TargetArea = NULL,
           TargetDensity = NULL,
           UzaProfileName = NULL) {
    #Get initial values for density distribution, and average density by level
    #-------------------------------------------------------------------------
    #If LocType is Rural
    if (LocType == "Rural") {
      if(is.null(TargetDensity)) {
        stop("TargetDensity must be supplied if LocType is Rural")
      }
      DenDist_D1 <- SimBzone_ls$RuProfiles$D1DGrp_ls$PropActivity
      AveDensity_D1 <- SimBzone_ls$RuProfiles$D1DGrp_ls$AveDensity
      D1LvlBrk_ <- SimBzone_ls$RuProfiles$D1DGrpBrk_
      #Set target density to 0.01 if is less than 0.01
      if (TargetDensity < 0.01) TargetDensity <- 0.01
    }
    #If LocType is Town
    if (LocType == "Town") {
      if (is.null(TargetArea)) {
        stop("TargetArea must be supplied if LocType is Town")
      }
      TargetDensity <- sum(Activity_Bz) / TargetArea
      DenDist_D1 <- SimBzone_ls$TnProfiles$D1DGrp_ls$PropActivity
      AveDensity_D1 <- SimBzone_ls$TnProfiles$D1DGrp_ls$AveDensity
      D1LvlBrk_ <- SimBzone_ls$TnProfiles$D1DGrpBrk_
    }
    #If LocType is Urban
    if (LocType == "Urban") {
      if (is.null(TargetArea)) {
        stop("TargetArea must be supplied if LocType is Urban")
      }
      TargetDensity <- sum(Activity_Bz) / TargetArea
      DenDist_D1 <-
        SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[[UzaProfileName]]$PropActivity
      DenDist_D1[is.na(DenDist_D1)] <- 0
      AveDensity_D1 <-
        SimBzone_ls$UaProfiles$D1DGrp_Ua_ls[[UzaProfileName]]$AveDensity
      AveDensity_D1[is.na(AveDensity_D1)] <-
        SimBzone_ls$UaProfiles$D1DGrp_ls$AveDensity[is.na(AveDensity_D1)]
      D1LvlBrk_ <- SimBzone_ls$UaProfiles$D1DGrpBrk_
    }
    #Initial calculation of average density
    AveDensity <- sum(1 / sum(DenDist_D1 / AveDensity_D1))

    #Adjust distribution and density to match target
    #-----------------------------------------------
    #Define a function to make an incremental adjustment in density distribution
    makeAdj <- function(DenDist_D1, TargetDensity, AveDensity, AdjProp){
      if (TargetDensity > AveDensity) {
        ShiftDist_D1 <- c(0, DenDist_D1[-length(DenDist_D1)])
      } else {
        ShiftDist_D1 <- c(DenDist_D1[-1], 0)
      }
      AdjDenDist_D1 <- (1 - AdjProp) * DenDist_D1 + AdjProp * ShiftDist_D1
      AdjDenDist_D1 / sum(AdjDenDist_D1)
    }
    #Make incremental adjustments until target is approximately achieved
    while (abs(1 - (TargetDensity / AveDensity)) > 0.01) {
      TargetDiff <- abs(TargetDensity - AveDensity)
      if (TargetDiff > 0.1) {
        DenDist_D1 <- makeAdj(DenDist_D1, TargetDensity, AveDensity, 0.01)
      } else {
        DenDist_D1 <- makeAdj(DenDist_D1, TargetDensity, AveDensity, 0.001)
      }
      AveDensity <- sum(1 / sum(DenDist_D1 / AveDensity_D1))
    }
    #Make final adjustments to density bin averages
    AveDensity_D1 <- AveDensity_D1 * TargetDensity / AveDensity

    #Apply the average density to SimBzones
    #--------------------------------------
    ActProp_Bz <-Activity_Bz / sum(Activity_Bz)
    InitD1Lvl_Bz <-
      sample(names(DenDist_D1), length(Activity_Bz), replace = TRUE, prob = DenDist_D1)
    AveDensity_Bz <- AveDensity_D1[InitD1Lvl_Bz]

    #Adjust SimBzone density to be consistent with target area
    #---------------------------------------------------------
    #Calculate target area for rural
    if (LocType == "Rural") {
      TargetArea <- sum(Activity_Bz) / TargetDensity
    }
    #Reconcile with target area
    Area_Bz <- Activity_Bz / AveDensity_Bz
    AreaDiff <- TargetArea - sum(Area_Bz)
    if (AreaDiff >= 0) {
      Area_Bz <- Area_Bz + AreaDiff * Area_Bz / sum(Area_Bz)
    } else {
      MinArea_Bz <- Activity_Bz / max(D1LvlBrk_)
      Area_Bz <- Area_Bz + AreaDiff * Area_Bz / sum(Area_Bz)
      TooMuch_Bz <- Area_Bz < MinArea_Bz
      while (any(TooMuch_Bz)) {
        AreaDiff <- TargetArea - sum(Area_Bz)
        Area_Bz[!TooMuch_Bz] <-
          Area_Bz[!TooMuch_Bz] + AreaDiff * Area_Bz[!TooMuch_Bz] / sum(Area_Bz[!TooMuch_Bz] )
        TooMuch_Bz <- Area_Bz < MinArea_Bz
        Area_Bz[TooMuch_Bz] <- MinArea_Bz[TooMuch_Bz]
      }
    }
    AveDensity_Bz <- Activity_Bz / Area_Bz
    D1Lvl_Bz <- cut(AveDensity_Bz, D1LvlBrk_)

    #Return the results
    #------------------
    list(
      D1Lvl = D1Lvl_Bz,
      ActivityDensity = AveDensity_Bz,
      Area = Activity_Bz / AveDensity_Bz
    )
  }

#Define function to assign diversity group and numbers of jobs and households
#----------------------------------------------------------------------------
#' Assign diversity group and numbers of jobs and households
#'
#' \code{calcDiversity} assigns a diversity group for each SimBzone and splits
#' activity into numbers of jobs and households.
#'
#' This function assigns a diversity group to each SimBzone based on the
#' density profile of the area, the modeled relationship of the
#' distribution of activity between diversity groups at each density level. The
#' 5 diversity groups are primarily-household, largely-household, mixed,
#' largely-employment, and primarily-employment. In the case of urbanized areas,
#' the distribution of activity by diversity group vs. density group
#' relationship is the modeled relationship from the Smart Location Database.
#' Average urbanized area values are substituted for density groups missing from
#' the values for the urbanized area. The proportions are used as sampling
#' distributions for assigning a diversity group to each SimBzone. The
#' employment split of activity is modeled using the estimated frequencies of
#' employment proportions by diversity group. The employment proportions are
#' adjusted so that the total number of jobs equals the input control total.
#'
#' @param Act_Bz A numeric vector of the total activity assigned to each
#' SimBzone.
#' @param ActDenLvl_Bz A character vector of the activity density level assigned
#' to each SimBzone where activity density is measured as the number of jobs and
#' households per acre.
#' @param TotEmp A number specifying the total number of jobs in the area.
#' @param D2ActProp_D1D2 A numeric matrix which specifies the proportions of
#' activity in each diversity group by density group. The rows of the matrix
#' represent density groups and the columns represent diversity groups.
#' @param EmpProp_D2_ls a list having five components, one for each diversity
#' level. Each component is a list with two components. The 'Values' component
#' is a numeric vector which specifies values for the employment proportions for
#' a number of bins. The 'Probs' component is a numeric vector identifying the
#' probability of each bin.
#' @param LocTyD2ActProp_D1D2 A numeric matrix which specifies the proportions of
#' activity in each diversity group by density group for the location type.
#' For example if the location type is metropolitan, it is the proportions
#' matrix for all urbanized areas.
#' @return A list having 3 components as follows:
#' D2Lvl - a character vector identifying the diversity level of each SimBzone,
#' NumHh - a numeric vector identifying the number of households in each SimBzone
#' TotEmp - a numeric vector identifying the number of jobs in each SimBzone,
#' @export
calcDiversity <-
  function(Act_Bz, ActDenLvl_Bz, TotEmp, D2ActProp_D1D2, EmpProp_D2_ls,
           LocTyD2ActProp_D1D2) {
    #Function to fill in values for densities that are missing
    #Define function to fill in missing activity proportions
    fillMissingUaActProp <- function(AreaActProp_mx, LocTypeActProp_mx) {
      NaRows_ <- apply(AreaActProp_mx, 1, function(x) all(is.na(x)))
      AreaActProp_mx[NaRows_,] <- LocTypeActProp_mx[NaRows_,]
      AreaActProp_mx[is.na(AreaActProp_mx)] <- 0
      AreaActProp_mx
    }
    #Create D2 activity proportions sampling matrix
    D2ActProp_D1D2 <- fillMissingUaActProp(D2ActProp_D1D2, LocTyD2ActProp_D1D2)
    #Assign diversity levels
    D2Grp_Bz <- unname(sapply(ActDenLvl_Bz, function(x) {
      sample(colnames(D2ActProp_D1D2), 1, prob = D2ActProp_D1D2[x,])
    }))
    #Calculate initial number of jobs by Bzone based on diversity level
    EmpProp_Bz <- sapply(D2Grp_Bz, function(x) {
      Sample_ls <- EmpProp_D2_ls[[x]]
      sample(Sample_ls$Values, 1, prob = Sample_ls$Probs)
    })
    Jobs_Bz <- unname(round(Act_Bz * EmpProp_Bz))
    #Define function to adjust jobs
    calcJobAdj <- function(TargetJobs, Jobs_Bz, Act_Bz){
      JobDiff <- TargetJobs - sum(Jobs_Bz)
      JobsProp_Bz <- Jobs_Bz / sum(Jobs_Bz)
      if (JobDiff > 0) {
        Cap_Bz <- Act_Bz - Jobs_Bz
        CapProp_Bz <- Cap_Bz / sum(Cap_Bz)
        Prob_Bz <- JobsProp_Bz * CapProp_Bz / sum(JobsProp_Bz * CapProp_Bz)
        JobAdj_Bz <- splitIntegers(abs(JobDiff), Prob_Bz)
        return(Jobs_Bz + pmin(JobAdj_Bz, Cap_Bz))
      }
      if (JobDiff < 0) {
        Prob_Bz <- JobsProp_Bz / sum(JobsProp_Bz)
        JobAdj_Bz <- splitIntegers(abs(JobDiff), Prob_Bz)
        return(Jobs_Bz - pmin(JobAdj_Bz, Jobs_Bz))
      }
    }
    #Adjust jobs to match total employment
    while (sum(Jobs_Bz) != TotEmp) {
      Jobs_Bz <- calcJobAdj(TotEmp, Jobs_Bz, Act_Bz)
    }
    #Calculate numbers of households by Bzone
    NumHh_Bz <- Act_Bz - Jobs_Bz
    #Return the result
    list(
      D2Lvl = D2Grp_Bz,
      NumHh = NumHh_Bz,
      TotEmp = Jobs_Bz
    )
  }

#Define function to assign destination accessibility
#---------------------------------------------------
#' Calculate destination accessibility value and level.
#
#' \code{assignDestAccess} assign destination accessibility level and value.
#'
#' This function assigns a destination accessibility level and value to
#' SimBzones. Destination accessibility is a measure of the proximity of each
#' SimBzone to population and jobs. This measure is described in detail in the
#' documentation for the CreateSimBzoneModels.R script. The module assigns a
#' destination accessibility value and corresponding destination accessibility
#' level.
#'
#' @param D1Lvl_Bz A numeric vector of activity density level by SimBzone.
#' @param LocType A string identifying the location type
#' @param AreaD5ActProp_D1D5 A numeric matrix of the destination accessibility
#' probabilities at each density level for the specific area
#' @param LocTypeD5ActProp_D1D5 A numeric matrix of the destination accessibility
#' probabilities at each density level for the location type. Is NULL for Town
#' and Rural location types
#' @param D5Ave_D5 A numeric vector identifying the average destination
#' accessibility at each destination accessibility level
#' @return A list containing 2 components: D5Lvl a character vector identifying
#' the destination accessibility level of each SimBzone; D5 a numeric vector
#' containing the destination accessibility level for each SimBzone
#' @export
assignDestAccess <-
  function(D1Lvl_Bz, LocType, AreaD5ActProp_D1D5, LocTypeD5ActProp_D1D5, D5Ave_D5) {
    #Function to fill in values for densities that are missing
    #Define function to fill in missing activity proportions
    fillMissingUaD5Prop <- function(AreaD5Prop_mx, LocTypeD5Prop_mx) {
      NaRows_ <- apply(AreaD5Prop_mx, 1, function(x) all(is.na(x)))
      AreaD5Prop_mx[NaRows_,] <- LocTypeD5Prop_mx[NaRows_,]
      AreaD5Prop_mx[is.na(AreaD5Prop_mx)] <- 0
      AreaD5Prop_mx
    }
    #Create D5 activity proportions sampling matrix
    if (LocType == "Urban") {
      D5Prop_D1D5 <- fillMissingUaD5Prop(AreaD5ActProp_D1D5, LocTypeD5ActProp_D1D5)
    } else {
      D5Prop_D1D5 <- AreaD5ActProp_D1D5
    }
    #Assign D5 level
    D5Lvl_Bz <- sapply(D1Lvl_Bz, function(x) {
      sample(1:ncol(D5Prop_D1D5), 1, prob = D5Prop_D1D5[x,])
    })
    #Assign D5 value
    D5_Bz <- D5Ave_D5[D5Lvl_Bz]
    #Return a list with the levels and values
    list(
      D5Lvl = names(D5Ave_D5)[D5Lvl_Bz],
      D5 = unname(D5_Bz)
    )
  }

#Calculate place types
#---------------------
#' Assigns an area type and development type to each SimBzone.
#'
#' \code{calcPlaceTypes} assigns an area type and development type to each
#' SimBzone.
#'
#' Place types simplify the characterization of land use patterns. They are used
#' in the VESimLandUse package modules to simplify the management of inputs for
#' land use related policies. There are three dimensions to the place type
#' system. Location type identifies whether the SimBzone is located in an
#' urbanized area (Metropolitan), a smaller urban-type area (Town), or a
#' non-urban area (Rural). Area types identify the relative urban nature of the
#' SimBzone: center, inner, outer, fringe. Development types identify the
#' character of development in the SimBzone: residential, employment, mix. This
#' function identifies the area type and development type of each SimBzone as a
#' function of the activity density, destination accessibility, and diversity
#' level of the SimBzone.
#'
#' @param ActDen_Bz a numeric vector identifying the activity density of each
#' SimBzone.
#' @param D5_Bz a numeric vector identifying the destination accessibility of
#' each SimBzone.
#' @param D2Grp_Bz a character vector identifying the diversity level of each
#' SimBzone.
#' @return A data frame identifying the area type and development type of each
#' SimBzone.
#' @export
calcPlaceTypes <- function(ActDen_Bz, D5_Bz, D2Grp_Bz) {
  #Function to calculate density levels used in area type
  calcDensityLvls <- function(ActDen_Bz) {
    Values_Bz <- ActDen_Bz
    Brks_ <- c(0, 0.5, 5, 10, max(Values_Bz))
    Cut_ <- cut(Values_Bz, Brks_, labels = FALSE, include.lowest = TRUE)
    Labels_ <- c("VL", "L", "M", "H")
    Labels_[Cut_]
  }
  #Function to calculate destination accessibility levels used in area type
  calcDestAccessLvls <- function(D5_Bz) {
    Values_Bz <- D5_Bz
    Brks_ <- c(0, 2e3, 1e4, 5e4, max(Values_Bz))
    Cut_ <- cut(Values_Bz, Brks_, labels = FALSE, include.lowest = TRUE)
    Labels_ <- c("VL", "L", "M", "H")
    Labels_[Cut_]
  }
  #Function to calculate area type
  calcAreaType <- function(ActDen_Bz, D5_Bz) {
    N <- length(ActDen_Bz)
    #Calculate density levels
    Den_Bz <- calcDensityLvls(ActDen_Bz)
    #Calculate destination accessibility levels
    Dest_Bz <- calcDestAccessLvls(D5_Bz)
    #Define area types in matrix
    AreaType_mx <- rbind(
      c("fringe", "fringe", "outer", "outer"),
      c("fringe", "outer", "outer", "inner"),
      c("outer", "outer", "inner", "inner"),
      c("outer", "inner", "center", "center")
    )
    rownames(AreaType_mx) <- c("VL", "L", "M", "H")
    colnames(AreaType_mx) <- c("VL", "L", "M", "H")
    #Assign area types
    AreaType_mx[cbind(Den_Bz, Dest_Bz)]
  }
  #Function to calculate development type
  calcDevelopmentType <- function(D2Grp_Bz) {
    DevType_Bz <- character(length(D2Grp_Bz))
    DevType_Bz[D2Grp_Bz == "mixed"] <- "mix"
    DevType_Bz[D2Grp_Bz %in% c("primarily-hh", "largely-hh")] <- "res"
    DevType_Bz[D2Grp_Bz %in% c("largely-job", "primarily-job")] <- "emp"
    DevType_Bz
  }
  #Return list of area type and development type
  list(
    AreaType = calcAreaType(ActDen_Bz, D5_Bz),
    DevType = calcDevelopmentType(D2Grp_Bz)
  )
}

#Define function to split housing
#--------------------------------
#' Split SimBzone housing into single family and multifamily.
#'
#' \code{splitHousing} splits the total number of households in each SimBzone
#' into single family and multifamily components.
#'
#' This function splits the total number of households in each SimBzone into
#' single family and multifamily components using the housing split model
#' estimated and documented in the 'CreateSimBzoneModel' module.
#'
#' @param Hh_ a numeric vector identifying the total number of households in
#' each SimBzones
#' @param PlaceType_ a character vector identifying the place type of each
#' SimBzone where place type is the concatenation of AreaType and DevType with
#' a period '.' separator.
#' @param MFProp_PtQt a numeric matrix of multifamily housing proportions by
#' place type and quantile created by the 'CreateSimBzoneModel' module.
#' @return A data frame identifying the numbers of single family dwelling units
#' and multifamily dwelling units in each SimBzone.
#' @export
splitHousing <- function(Hh_, PlaceType_, MFProp_PtQt) {
  MfProp_ <- sapply(PlaceType_, function(x) {
    sample(MFProp_PtQt[x,], 1)})
  MfDu_ <- round(Hh_ * MfProp_)
  SfDu_ <- Hh_ - MfDu_
  data.frame(
    MFDU = as.integer(MfDu_),
    SFDU = as.integer(SfDu_)
  )
}

#Define function to split employment
#-----------------------------------
#' Split SimBzone employment into retail, service, and other components.
#'
#' \code{splitEmployment} splits the total employment of each SimBzone into
#' retail, service, and other components.
#'
#' This function splits the employment of each SimBzone in a set of SimBzones
#' into retail, service, and other components.
#'
#' @param TotEmp_ A numeric vector identifying the total number of jobs assigned
#' to each SimBzone.
#' @param PlaceType_ A character vector identifying the place type of each
#' SimBzone where the place type designation is a concatenation of area type and
#' development type joined by a period ('.').
#' @param RetSvcProp_PtQt A matrix of the quantiles of retail and service
#' employment proportion of total employment by place type and quantile. See the
#' documentation for the CreateSimBzoneModels.R script for more information.
#' @param RetProp_PtQt A matrix of the quantiles of retail employment proportion
#'   of retail and service employment by place type and quantile. See the
#'   documentation for the CreateSimBzoneModels.R script for more information.
#' @return A data frame identifying the numbers of retail, service, and other
#' jobs located in each SimBzone.
#' @export
splitEmployment <- function(TotEmp_, PlaceType_, RetSvcProp_PtQt, RetProp_PtQt) {
  RetSvcProp_ <- sapply(PlaceType_, function(x) {
    sample(RetSvcProp_PtQt[x,], 1)})
  RetSvcEmp_ <- round(TotEmp_ * RetSvcProp_)
  RetProp_ <- sapply(PlaceType_, function(x) {
    sample(RetProp_PtQt[x,], 1)
  })
  RetEmp_ <- round(RetSvcEmp_ * RetProp_)
  SvcEmp_ <- RetSvcEmp_ - RetEmp_
  OthEmp_ <- TotEmp_ - RetSvcEmp_
  data.frame(
    RetEmp = as.integer(RetEmp_),
    SvcEmp = as.integer(SvcEmp_),
    OthEmp = as.integer(OthEmp_)
  )
}


#Main module function that creates a set of SimBzones
#----------------------------------------------------
#' Create SimBzones.
#'
#' \code{CreateSimBzones} creates SimBzones assigned to each Azone to
#' accommodate projected households and jobs in each Azone.
#'
#' This function creates SimBzones assigned to each Azone to accommodate
#' projected households and jobs in each Azone and to reflect likely
#' distribution of characteristics for activity density, mixing of jobs and
#' households, and destination accessibility. The module also identifies the
#' location type, area type, and development type of each SimBzone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CreateSimBzones <- function(L) {

  #Setup
  #-----
  #Define abbreviation vectors
  Az <- L$Year$Azone$Azone
  Marea_Az <- L$Year$Azone$Marea
  names(Marea_Az) <- L$Year$Azone$Azone
  Lt <- c("Urban", "Town", "Rural")
  #Identify UzaProfileNames
  UzaProfileName_Ma <- L$Global$Marea$UzaProfileName
  names(UzaProfileName_Ma) <- L$Global$Marea$Marea
  UzaProfileName_Az <- UzaProfileName_Ma[L$Year$Azone$Marea]
  names(UzaProfileName_Az) <- L$Year$Azone$Azone
  #Set random seed
  set.seed(L$G$Seed)
  #Load model data
  SimBzone_ls <- loadPackageDataset("SimBzone_ls")

  #Allocate households to location types
  #-------------------------------------
  Hh_Lt_Az <- calcNumHhByLocType(
    NumHh_Az = L$Year$Azone$NumHh,
    PropRuralHh_Az = L$Year$Azone$PropRuralHh,
    PropTownHh_Az = L$Year$Azone$PropTownHh,
    PropMetroHh_Az = L$Year$Azone$PropMetroHh,
    Az = Az
    )

  #Allocate jobs to location types and Azones
  #------------------------------------------
  Jobs_Lt_Az <- calcNumJobsByLocType(
    NumWkr_Az = L$Year$Azone$NumWkr,
    PropWkrInRuralJobs_Az = L$Year$Azone$PropWkrInRuralJobs,
    PropWkrInTownJobs_Az = L$Year$Azone$PropWkrInTownJobs,
    PropWkrInMetroJobs_Az = L$Year$Azone$PropWkrInMetroJobs,
    PropMetroJobs_Az = L$Year$Azone$PropMetroJobs,
    Marea_Az = L$Year$Azone$Marea,
    Az = Az
    )

  #Create a data frame of SimBzones
  #--------------------------------
  Bzones_df <- initSimBzones(
    RuralActivity_Az = Hh_Lt_Az$Rural + Jobs_Lt_Az$Rural,
    TownActivity_Az = Hh_Lt_Az$Town + Jobs_Lt_Az$Town,
    UrbanActivity_Az = Hh_Lt_Az$Urban + Jobs_Lt_Az$Urban,
    Az = Az,
    Marea_Az = Marea_Az
  )

  #Assign activity density level and activity density
  #--------------------------------------------------
  #Initialize Bzone values
  Bzones_df$D1Lvl <- NA
  Bzones_df$ActivityDensity <- NA
  Bzones_df$Area <- NA
  #Calculate values
  for (az in Az) {
    for (lt in Lt) {
      if (lt == "Urban") {
        TargetArea <- L$Year$Azone$MetroLandArea[L$Year$Azone$Azone == az]
        TargetDensity <- NULL
        UzaProfileName <- UzaProfileName_Az[az]
      }
      if (lt == "Town") {
        TargetArea <- L$Year$Azone$TownLandArea[L$Year$Azone$Azone == az]
        TargetDensity <- NULL
        UzaProfileName <- NULL
      }
      if (lt == "Rural") {
        TargetArea <- NULL
        TargetDensity <- L$Year$Azone$RuralAveDensity[L$Year$Azone$Azone == az]
        UzaProfileName <- NULL
      }
      Select_ <- Bzones_df$Azone == az & Bzones_df$LocType == lt
      if (any(Select_)) {
        Bz_df <- Bzones_df[Bzones_df$Azone == az & Bzones_df$LocType == lt,]
        D1D_ls <- calcDensityDistribution(
          Activity_Bz = Bz_df$Activity,
          LocType = lt,
          TargetArea = TargetArea,
          TargetDensity = TargetDensity,
          UzaProfileName = UzaProfileName
        )
        Bzones_df$D1Lvl[Select_] <- as.character(D1D_ls$D1Lvl)
        Bzones_df$ActivityDensity[Select_] <- D1D_ls$ActivityDensity
        Bzones_df$Area[Select_] <- D1D_ls$Area
        rm(TargetArea, TargetDensity, UzaProfileName, Select_, Bz_df, D1D_ls)
      }
    }
  }
  #Calculate area by location type
  calcAreaByLocType <- function(Type, LocType_, Area_) {
    LocTypeArea_ <- numeric(length(LocType_))
    LocTypeArea_[LocType_ == Type] <- Area_[LocType_ == Type]
    LocTypeArea_
  }
  Bzones_df$UrbanArea <-
    calcAreaByLocType("Urban", Bzones_df$LocType, Bzones_df$Area)
  Bzones_df$TownArea <-
    calcAreaByLocType("Town", Bzones_df$LocType, Bzones_df$Area)
  Bzones_df$RuralArea <-
    calcAreaByLocType("Rural", Bzones_df$LocType, Bzones_df$Area)

  #Assign mixing level and numbers of households and jobs
  #------------------------------------------------------
  #Initialize Bzone values
  Bzones_df$D2Lvl <- NA
  Bzones_df$NumHh <- NA
  Bzones_df$TotEmp <- NA
  #Calculate values
  for (az in Az) {
    for (lt in Lt) {
      if (lt == "Urban") {
        UzaProfileName <- UzaProfileName_Az[az]
        D2ActProp_D1D2 <-
          SimBzone_ls$UaProfiles$D2ActProp_Ua_D1D2[[UzaProfileName]]
        EmpProp_D2_ls <- SimBzone_ls$UaProfiles$EmpProp_D2_ls
        LocTyD2ActProp_D1D2 <- SimBzone_ls$UaProfiles$D2ActProp_D1D2
        rm(UzaProfileName)
      }
      if (lt == "Town") {
        D2ActProp_D1D2 <- SimBzone_ls$TnProfiles$D2ActProp_D1D2
        EmpProp_D2_ls <- SimBzone_ls$TnProfiles$EmpProp_D2_ls
        LocTyD2ActProp_D1D2 <- SimBzone_ls$TnProfiles$D2ActProp_D1D2
      }
      if (lt == "Rural") {
        D2ActProp_D1D2 <- SimBzone_ls$RuProfiles$D2ActProp_D1D2
        EmpProp_D2_ls <- SimBzone_ls$RuProfiles$EmpProp_D2_ls
        LocTyD2ActProp_D1D2 <- SimBzone_ls$RuProfiles$D2ActProp_D1D2
      }
      Select_ <- Bzones_df$Azone == az & Bzones_df$LocType == lt
      if (any(Select_)) {
        Bz_df <- Bzones_df[Select_,]
        D2_ls <- calcDiversity(
          Act_Bz = Bz_df$Activity,
          ActDenLvl_Bz = Bz_df$D1Lvl,
          TotEmp = Jobs_Lt_Az[[lt]][az],
          D2ActProp_D1D2,
          EmpProp_D2_ls,
          LocTyD2ActProp_D1D2
          )
        Bzones_df$D2Lvl[Select_] <- as.character(D2_ls$D2Lvl)
        Bzones_df$NumHh[Select_] <- D2_ls$NumHh
        Bzones_df$TotEmp[Select_] <- D2_ls$TotEmp
        rm(D2ActProp_D1D2, EmpProp_D2_ls, LocTyD2ActProp_D1D2, Select_, Bz_df, D2_ls)
      }
    }
  }

  #Assign destination accessibility values
  #---------------------------------------
  #Initialize Bzone values
  Bzones_df$D5Lvl <- NA
  Bzones_df$D5 <- NA
  #Calculate values
  for (az in Az) {
    for (lt in Lt) {
      if (lt == "Urban") {
        UzaProfileName <- UzaProfileName_Az[az]
        AreaD5ActProp_D1D5 <-
          SimBzone_ls$UaProfiles$D5ActProp_Ua_D1D5[[UzaProfileName]]
        LocTypeD5ActProp_D1D5 <- SimBzone_ls$UaProfiles$D5ActProp_D1D5
        D5Ave_D5 <- SimBzone_ls$UaProfiles$D5Ave_D5
        rm(UzaProfileName)
      }
      if (lt == "Town") {
        AreaD5ActProp_D1D5 <- SimBzone_ls$TnProfiles$D5ActProp_D1D5
        LocTypeD5ActProp_D1D5 <- NULL
        D5Ave_D5 <- SimBzone_ls$TnProfiles$D5Ave_D5
      }
      if (lt == "Rural") {
        AreaD5ActProp_D1D5 <- SimBzone_ls$RuProfiles$D5ActProp_D1D5
        LocTypeD5ActProp_D1D5 <- NULL
        D5Ave_D5 <- SimBzone_ls$RuProfiles$D5Ave_D5
      }
      Select_ <- Bzones_df$Azone == az & Bzones_df$LocType == lt
      if (any(Select_)) {
        Bz_df <- Bzones_df[Bzones_df$Azone == az & Bzones_df$LocType == lt,]
        D5_ls <- assignDestAccess(
          D1Lvl_Bz = Bz_df$D1Lvl,
          LocType = lt,
          AreaD5ActProp_D1D5,
          LocTypeD5ActProp_D1D5,
          D5Ave_D5
        )
        Bzones_df$D5Lvl[Select_] <- as.character(D5_ls$D5Lvl)
        Bzones_df$D5[Select_] <- D5_ls$D5
        rm(AreaD5ActProp_D1D5, LocTypeD5ActProp_D1D5, D5Ave_D5, Select_, Bz_df, D5_ls)
      }
    }
  }

  #Calculate area type and development type
  #----------------------------------------
  #Initialize Bzone values
  Bzones_df$AreaType <- NA
  Bzones_df$DevType <- NA
  #Calculate values
  for (az in Az) {
    for (lt in Lt) {
      Select_ <- Bzones_df$Azone == az & Bzones_df$LocType == lt
      if (any(Select_)) {
        Bz_df <- Bzones_df[Bzones_df$Azone == az & Bzones_df$LocType == lt,]
        Types_ls <- calcPlaceTypes(
          ActDen_Bz = Bz_df$ActivityDensity,
          D5_Bz = Bz_df$D5,
          D2Grp_Bz = Bz_df$D2Lvl
        )
        Bzones_df$AreaType[Select_] <- Types_ls$AreaType
        Bzones_df$DevType[Select_] <- Types_ls$DevType
        rm(Select_, Bz_df, Types_ls)
      }
    }
  }

  #Calculate number of single-family and multifamily dwelling units
  #----------------------------------------------------------------
  #Make place type variable
  PlaceType_ <- paste(Bzones_df$AreaType, Bzones_df$DevType, sep = ".")
  #Split housing
  DuSim_df <-
    splitHousing(Bzones_df$NumHh, PlaceType_, SimBzone_ls$HousingSplit$MFProp_PtQt)
  Bzones_df[c("MFDU", "SFDU")] <- DuSim_df[c("MFDU", "SFDU")]
  rm(DuSim_df)

  #Calculate employment split
  #--------------------------
  #Initialize Bzone values
  Bzones_df$RetEmp <- NA
  Bzones_df$SvcEmp <- NA
  Bzones_df$OthEmp <- NA
  #Calculate values
  EmpSplit_ls <- splitEmployment(
    TotEmp_ = Bzones_df$TotEmp,
    PlaceType_ = with(Bzones_df, paste(AreaType, DevType, sep = ".")),
    RetSvcProp_PtQt = SimBzone_ls$EmpSplit$RetSvcProp_PtQt,
    RetProp_PtQt = SimBzone_ls$EmpSplit$RetProp_PtQt)
  Bzones_df[c("RetEmp", "SvcEmp", "OthEmp")] <- EmpSplit_ls[c("RetEmp", "SvcEmp", "OthEmp")]
  rm(EmpSplit_ls)

  #Return results
  #--------------
  #Build the list of outputs
  Out_ls <- initDataList()
  Out_ls$Year$Bzone <- list()
  attributes(Out_ls$Year$Bzone)$LENGTH <- nrow(Bzones_df)
  Out_ls$Year$Bzone$Bzone <- Bzones_df$Bzone
  Out_ls$Year$Bzone$Azone <- Bzones_df$Azone
  Out_ls$Year$Bzone$Marea <- Bzones_df$Marea
  Out_ls$Year$Bzone$LocType <- as.character(Bzones_df$LocType)
  Out_ls$Year$Bzone$NumHh <- Bzones_df$NumHh
  Out_ls$Year$Bzone$TotEmp <- Bzones_df$TotEmp
  Out_ls$Year$Bzone$RetEmp <- Bzones_df$RetEmp
  Out_ls$Year$Bzone$SvcEmp <- Bzones_df$SvcEmp
  Out_ls$Year$Bzone$OthEmp <- Bzones_df$OthEmp
  Out_ls$Year$Bzone$D1D <- Bzones_df$ActivityDensity
  Out_ls$Year$Bzone$D5 <- Bzones_df$D5
  Out_ls$Year$Bzone$UrbanArea <- Bzones_df$UrbanArea
  Out_ls$Year$Bzone$TownArea <- Bzones_df$TownArea
  Out_ls$Year$Bzone$RuralArea <- Bzones_df$RuralArea
  Out_ls$Year$Bzone$AreaType <- Bzones_df$AreaType
  Out_ls$Year$Bzone$DevType <- Bzones_df$DevType
  Out_ls$Year$Bzone$SFDU <- Bzones_df$SFDU
  Out_ls$Year$Bzone$MFDU <- Bzones_df$MFDU
  #Add SIZE attributes for Bzone, Azone, Marea
  attributes(Out_ls$Year$Bzone$Bzone)$SIZE <- max(nchar(Bzones_df$Bzone))
  attributes(Out_ls$Year$Bzone$Azone)$SIZE <- max(nchar(Bzones_df$Azone))
  attributes(Out_ls$Year$Bzone$Marea)$SIZE <- max(nchar(Bzones_df$Marea))
  #Return the list
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CreateSimBzones")

#Test code to perform additional checks on input files. Return input list
#(TestDat_) to use for developing the CreateSimBzones function.
#-------------------------------------------------------------------------------
#Load packages and test functions
# library(filesstrings)
# library(visioneval)
# source("tests/scripts/test_functions.R")
#
# #Define test setup parameters
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
#
# #Define the module tests
# Tests_ls <- list(
#   list(ModuleName = "CreateSimBzones.R", LoadDatastore = FALSE, SaveDatastore = TRUE, DoRun = TRUE)
# )

# #Set up, run tests, and save test results
# setUpTests(TestSetup_ls)

#Return test dataset
# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "CreateSimBzones",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CreateSimBzones(TestDat_$L)

# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "CreateSimBzones",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
