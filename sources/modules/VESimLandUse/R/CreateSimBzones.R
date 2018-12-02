#=================
#CreateSimBzones.R
#=================

#<doc>
## CreateSimBzones Module
#### December 2, 2018
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
#8) **Split SimBzone Employment Into Sectors**: SimBzone employment is split between 3 sectors (retail, service, other). This is done for the purpose of enabling the calculation of an entropy measure of land use mixing that is used in the forthcoming multimodal household travel for VisionEval (described below). The models described in the *Split SimBzone Employment Into Sectors* section of the *CreateSimBzonesModel* module documentation are applied to carry out the splits. The entropy measure is calculated in the same way as the `D2a_EpHHm` measure is calculated in the Smart Location Database (SLD) with the exception that only 3 employment sectors are used instead of 5. The calculations are described in Table 5 of SLD [users guide](https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide).
#
#9) **Model Housing Types**: Housing types (single family, multifamily) to be occupied by households in each SimBzone are calculated using models described in the *Model Housing Types* section of the *CreateSimBzonesModel* module documentation. These values are used in the *PredictHousing* module to assign a housing type to each household and then assign households to SimBzones as a function of their housing type choice.
#
#10) **Designate Place Types**: Place types simplify the characterization of land use patterns. They are used in the VESimLandUse package modules to simplify the management of inputs for land use related policies. There are three dimensions to the place type system. Location type identifies whether the SimBzone is located in an urbanized area (Metropolitan), a smaller urban-type area (Town), or a non-urban area (Rural). Area types identify the relative urban nature of the SimBzone: center, inner, outer, fringe. Development types identify the character of development in the SimBzone: residential, employment, mix. The methods used for designating SimBzone place types are described in detail in the *Designate Place Types* section of the *CreateSimBzonesModel* module documentation.
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
      NAME = "NumJob",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "employment",
      UNITS = "JOB",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of jobs allocated to SimBzone"
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
#' \code{splitIntegers}
splitIntegers <- function(Tot, Props_) {
  Ints_ <- round(Tot * Props_)
  Diff <- Tot - sum(Ints_)
  if (Diff != 0) {
    for (i in 1:abs(Diff)) {
      IdxToChg <- sample(1:length(Props_), 1, prob = Props_)
      Ints_[IdxToChg] <- Ints_[IdxToChg] + sign(Diff)
    }
  }
  unname(Ints_)
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
#' @param NumWkr_Az A numeric vector of the total number of workers residing in each
#' Azone.
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
      Bzones_df$D1Lvl <- NA
      Bzones_df$ActivityDensity <- NA
      Bzones_df$D2Lvl <- NA
      Bzones_df$NumHh <- NA
      Bzones_df$NumJob <- NA
      Bzones_df$D5Lvl <- NA
      Bzones_df$D5 <- NA
      Bzones_df$AreaType <- NA
      Bzones_df$DevType <- NA
      Bzones_Az_df[[az]] <- Bzones_df
    }
    Bzones_df <- do.call(rbind, Bzones_Az_df)
    rownames(Bzones_df) <- NULL
    Bzones_df
  }


#Function to adjust density distributions to match average density target
#------------------------------------------------------------------------
#' Adjust area density distribution to match average density target
#'
#' \code{calcDensityDistribution} calculates for an area, such as an urbanized
#' area, the proportions of activity by density group and the average density by
#' density group to match an overall area density target.
#'
#' This function calculates for an area, such as an urbanized area, the
#' proportions of activity by density group and the average density by density
#' group to match an overall area density target.
#'
#' @param DenDist_ A numeric vector of the model proportions of activity by
#' activity density bin for the area.
#' @param AreaAveDensity_ A numeric vector of the model average activity density
#' by activity density bin for the area.
#' @param Target A number specifying the average activity density for the
#' area measured in numbers of households and jobs per acre.
#' @param LocTyAveDensity_ A numeric vector of the average activity density by
#' activity density bin for the location type. For example if the location
#' type is metropolitan, it is the average density distribution for all
#' urbanized areas.
#' @return A data frame having 20 rows and 2 columns: ActProp, the proportion of
#' urbanized activity by activity density bin; and AveDensity, the average
#' density by activity density bin.
#' @export
calcDensityDistribution <-
  function(Activity_Bz,
           Azone_Bz,
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
      ActivityDensity = AveDensity_Bz
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
#' @param ActDenGrp_Bz A character vector of the activity density group assigned
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
#' @param MixTarget A number specifying a target for the proportion of activity
#' in mixed diversity group or NULL if no target is specified.
#' @return A list having 3 components as follows:
#' D2Grp - a character vector identifying the diversity group of each SimBzone,
#' Jobs - a numeric vector identifying the number of jobs in each SimBzone,
#' HHs - a numeric vector identifying the number of households in each SimBzone
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
    #Calculate number of jobs by Bzone
    EmpProp_Bz <- sapply(D2Grp_Bz, function(x) {
      Sample_ls <- EmpProp_D2_ls[[x]]
      sample(Sample_ls$Values, 1, prob = Sample_ls$Probs)
    })
    Jobs_Bz <- unname(round(Act_Bz * EmpProp_Bz))
    #Adjust jobs to match inputs
    TargetJobs <- TotEmp
    JobDiff <- TargetJobs - sum(Jobs_Bz)
    calcJobAdj <- function(JobDiff, Jobs_Bz, Act_Bz){
      JobsProp_Bz <- Jobs_Bz / sum(Jobs_Bz)
      CapProp_Bz <- (Act_Bz - Jobs_Bz) / (sum(Act_Bz) - sum(Jobs_Bz))
      Prob_Bz <- JobsProp_Bz * CapProp_Bz / sum(JobsProp_Bz * CapProp_Bz)
      sign(JobDiff) * splitIntegers(abs(JobDiff), Prob_Bz)
    }
    if (JobDiff > 0) {
      Jobs_Bz <- Jobs_Bz + calcJobAdj(JobDiff, Jobs_Bz, Act_Bz)
      TooHigh <- Jobs_Bz > Act_Bz
      while (any(TooHigh)) {
        JobDiff <- sum(Jobs_Bz[Jobs_Bz > Act_Bz])
        Jobs_Bz[Jobs_Bz > Act_Bz] <- Act_Bz[Jobs_Bz > Act_Bz]
        Jobs_Bz[!TooHigh] <-
          Jobs_Bz[!TooHigh] + calcJobAdj(JobDiff, Jobs_Bz[!TooHigh], Act_Bz[!TooHigh])
        TooHigh <- Jobs_Bz > Act_Bz
      }
    }
    if (JobDiff < 0) {
      Jobs_Bz <- Jobs_Bz + calcJobAdj(JobDiff, Jobs_Bz, Act_Bz)
      TooLow <- Jobs_Bz < 0
      while (any(TooLow)) {
        JobDiff <- sum(Jobs_Bz[Jobs_Bz < 0])
        Jobs_Bz[Jobs_Bz < 0] <- 0
        Jobs_Bz[!TooLow] <-
          Jobs_Bz[!TooLow] + calcJobAdj(JobDiff, Jobs_Bz[!TooLow], Act_Bz[!TooLow])
        TooLow <- Jobs_Bz < 0
      }
    }
    #Calculate numbers of households by Bzone
    NumHh_Bz <- Act_Bz - Jobs_Bz
    #Return the result
    list(
      D2Lvl = D2Grp_Bz,
      NumHh = NumHh_Bz,
      NumJob = Jobs_Bz
    )
  }


#Define function to assign destination accessibility
#---------------------------------------------------
#' \code{assignDestAccess} assign destination accessibility level and value.
#'
#' This function assigns a destination accessibility level and value to SimBzones.
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
  Az <- L$Year$Azone$Azone
  Marea_Az <- L$Year$Azone$Marea
  names(Marea_Az) <- L$Year$Azone$Azone
  load("data/SimBzone_ls.Rda")
  Lt <- c("Urban", "Town", "Rural")
  UzaProfileName_Ma <- L$Global$Marea$UzaProfileName
  names(UzaProfileName_Ma) <- L$Global$Marea$Marea
  UzaProfileName_Az <- UzaProfileName_Ma[L$Year$Azone$Marea]
  names(UzaProfileName_Az) <- L$Year$Azone$Azone

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

  #Create a list of SimBzones by Azone
  #-----------------------------------
  Bzones_df <- initSimBzones(
    RuralActivity_Az = Hh_Lt_Az$Rural + Jobs_Lt_Az$Rural,
    TownActivity_Az = Hh_Lt_Az$Town + Jobs_Lt_Az$Town,
    UrbanActivity_Az = Hh_Lt_Az$Urban + Jobs_Lt_Az$Urban,
    Az = Az,
    Marea_Az = Marea_Az
  )

  #Assign activity density level and activity density
  #--------------------------------------------------
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
          Azone_Bz = Bz_df$Azone,
          LocType = lt,
          TargetArea = TargetArea,
          TargetDensity = TargetDensity,
          UzaProfileName = UzaProfileName
        )
        Bzones_df$D1Lvl[Select_] <- as.character(D1D_ls$D1Lvl)
        Bzones_df$ActivityDensity[Select_] <- D1D_ls$ActivityDensity
        rm(TargetArea, TargetDensity, UzaProfileName, Select_, Bz_df, D1D_ls)
      }
    }
  }

  #Assign mixing level and numbers of households and jobs
  #------------------------------------------------------
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
        Bz_df <- Bzones_df[Bzones_df$Azone == az & Bzones_df$LocType == lt,]
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
        Bzones_df$NumJob[Select_] <- D2_ls$NumJob
        rm(D2ActProp_D1D2, EmpProp_D2_ls, LocTyD2ActProp_D1D2, Select_, Bz_df, D2_ls)
      }
    }
  }

  #Assign destination accessibility values
  #---------------------------------------
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
# source("tests/scripts/test_functions.R")
# #Set up test data
# setUpTests(list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = FALSE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE
# ))
# #Return test dataset
# TestDat_ <- testModule(
#   ModuleName = "CreateSimBzones",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- Initialize(TestDat_)

#Test code to check everything including running the module and checking whether
#the code runs completely and produces desired results
#-------------------------------------------------------------------------------
# source("tests/scripts/test_functions.R")
# #Set up test data
# setUpTests(list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE
# ))
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )


#================
#CODE HOLDING PEN
#================

# #Split employment into retail, service, and other
# #------------------------------------------------
# for (az in Az) {
#   for (lt in Lt) {
#     if (lt == "Urban") {
#       UzaProfileName <- UzaProfileName_Az[az]
#       RetProp <- SimBzone_ls$UaProfiles$RetProp_Ua[UzaProfileName]
#       SvcProp <- SimBzone_ls$UaProfiles$SvcProp_Ua[UzaProfileName]
#       EmpSplitModel_ls <- list(
#         MeanRetSvcProp_D1D2 = SimBzone_ls$UaProfiles$MeanRetSvcProp_D1D2,
#         SdRetSvcProp_D2 = SimBzone_ls$UaProfiles$SdRetSvcProp_D2,
#         MeanRetPropRetSvc_D1D2 = SimBzone_ls$UaProfiles$MeanRetPropRetSvc_D1D2,
#         SdRetPropRetSvc_D2 = SimBzone_ls$UaProfiles$SdRetPropRetSvc_D2
#       )
#       rm(UzaProfileName)
#     }
#     if (lt == "Town") {
#       RetProp <- SimBzone_ls$TnProfiles$RetProp
#       SvcProp <- SimBzone_ls$TnProfiles$SvcProp
#       EmpSplitModel_ls <- list(
#         MeanRetSvcProp_D1D2 = SimBzone_ls$TnProfiles$MeanRetSvcProp_D1D2,
#         SdRetSvcProp_D2 = SimBzone_ls$TnProfiles$SdRetSvcProp_D2,
#         MeanRetPropRetSvc_D1D2 = SimBzone_ls$TnProfiles$MeanRetPropRetSvc_D1D2,
#         SdRetPropRetSvc_D2 = SimBzone_ls$TnProfiles$SdRetPropRetSvc_D2
#       )
#     }
#     if (lt == "Rural") {
#       RetProp <- SimBzone_ls$RuProfiles$RetProp
#       SvcProp <- SimBzone_ls$RuProfiles$SvcProp
#       EmpSplitModel_ls <- list(
#         MeanRetSvcProp_D1D2 = SimBzone_ls$RuProfiles$MeanRetSvcProp_D1D2,
#         SdRetSvcProp_D2 = SimBzone_ls$RuProfiles$SdRetSvcProp_D2,
#         MeanRetPropRetSvc_D1D2 = SimBzone_ls$RuProfiles$MeanRetPropRetSvc_D1D2,
#         SdRetPropRetSvc_D2 = SimBzone_ls$RuProfiles$SdRetPropRetSvc_D2
#       )
#     }
#     Select_ <- Bzones_df$Azone == az & Bzones_df$LocType == lt
#     if (any(Select_)) {
#       Bz_df <- Bzones_df[Bzones_df$Azone == az & Bzones_df$LocType == lt,]
#       EmpSector_ls <- splitEmployment(
#         Emp_Bz = Bz_df$NumJob,
#         D1DGrp_Bz = Bz_df$D1Lvl,
#         D2Grp_Bz = Bz_df$D2Lvl,
#         RetProp,
#         SvcProp,
#         EmpSplitModel_ls
#       )
#       Bzones_df$RetJob[Select_] <- EmpSector_ls$RetEmp
#       Bzones_df$SvcJob[Select_] <- EmpSector_ls$SvcEmp
#       Bzones_df$OthJob[Select_] <- EmpSector_ls$OthEmp
#       rm(RetProp, SvcProp, EmpSplitModel_ls, Select_, Bz_df, EmpSector_ls)
#     }
#   }
# }

#' #Define function to split employment into sectors
#' #------------------------------------------------
#' #' \code{splitEmployment} split SimBzone employment into sectors.
#' #'
#' #' This function splits SimBzone employment into retail, service, and other
#' #' employment sectors and match the split for the overall area being modeled.
#' #'
#' #' @param Emp_Bz A numeric vector of total employment by SimBzone.
#' #' @param D1DGrp_Bz A character vector identifying the activity density group
#' #' of each SimBzone.
#' #' @param D2Grp_Bz A character vector identifying the activity diversity group
#' #' of each SimBzone.
#' #' @param RetProp A number identifying the proportion of employment in the area
#' #' that is retail employment.
#' #' @param SvcProp A number identifying the proportion of employment in the area
#' #' that is service employment.
#' #' @param Model_ls A list containing all the estimated model information for
#' #' implementing the employment split model.
#' #' @return A list containing 3 components: RetEmp (the number of retail sector
#' #' jobs), SvcEmp (the number of service sector jobs), OthEmp (the number of
#' #' other sector jobs)
#' #' @export
#' splitEmployment <-
#'   function(Emp_Bz, D1DGrp_Bz, D2Grp_Bz, RetProp, SvcProp, EmpSplitModel_ls){
#'     NBz <- length(Emp_Bz)
#'     RetEmp <- round(sum(Emp_Bz) * RetProp)
#'     SvcEmp <- round(sum(Emp_Bz) * SvcProp)
#'     RetSvcEmp <- RetEmp + SvcEmp
#'     #Define function to adjust sector employment by zone to match total
#'     matchBzEmp <- function(TotSectorEmp, SectorEmp_Bz) {
#'       EmpDiff <- TotSectorEmp - sum(SectorEmp_Bz)
#'       SectorEmpProp_Bz <- SectorEmp_Bz / sum(SectorEmp_Bz)
#'       BzIdx_ <- 1:length(SectorEmp_Bz)
#'       EmpAdj_tb <- table(sample(BzIdx_, abs(EmpDiff), replace = TRUE, prob = SectorEmpProp_Bz))
#'       SectorEmp_Bz[as.numeric(names(EmpAdj_tb))] <-
#'         SectorEmp_Bz[as.numeric(names(EmpAdj_tb))] + sign(EmpDiff) * EmpAdj_tb
#'       SectorEmp_Bz[SectorEmp_Bz < 0] <- 0
#'       SectorEmp_Bz
#'     }
#'     #Sample to determine initial retail & service proportion of employment
#'     MeanRetSvcProp_Bz <- EmpSplitModel_ls$MeanRetSvcProp_D1D2[cbind(D1DGrp_Bz, D2Grp_Bz)]
#'     SdRetSvcProp_Bz <- EmpSplitModel_ls$SdRetSvcProp_D2[D2Grp_Bz]
#'     RetSvcProp_Bz <- rnorm(NBz, MeanRetSvcProp_Bz, SdRetSvcProp_Bz)
#'     RetSvcProp_Bz[RetSvcProp_Bz <= 0] <- RetProp + SvcProp
#'     #Scale to keep range in 0 to 1
#'     MeanRetSvcProp <- mean(RetSvcProp_Bz)
#'     UpperAdj <- (1 - MeanRetSvcProp) / (max(RetSvcProp_Bz) - MeanRetSvcProp)
#'     IsUpper_ <- RetSvcProp_Bz > MeanRetSvcProp
#'     RetSvcProp_Bz[IsUpper_] <-
#'       MeanRetSvcProp + (RetSvcProp_Bz[IsUpper_] - MeanRetSvcProp) * UpperAdj
#'     LowerAdj <- (MeanRetSvcProp) / (MeanRetSvcProp - min(RetSvcProp_Bz))
#'     IsLower_ <- RetSvcProp_Bz < MeanRetSvcProp
#'     RetSvcProp_Bz[IsLower_] <-
#'       MeanRetSvcProp + (RetSvcProp_Bz[IsLower_] - MeanRetSvcProp) * LowerAdj
#'     #Calculate retail & service employment and other employment
#'     RetSvcEmp_Bz <- round(Emp_Bz * RetSvcProp_Bz)
#'     while (sum(RetSvcEmp_Bz) != RetSvcEmp) {
#'       RetSvcEmp_Bz <- matchBzEmp(RetSvcEmp, RetSvcEmp_Bz)
#'       RetSvcEmp_Bz[RetSvcEmp_Bz > Emp_Bz] <- Emp_Bz[RetSvcEmp_Bz > Emp_Bz]
#'     }
#'     OthEmp_Bz <- Emp_Bz - RetSvcEmp_Bz
#'     #Calculate retail proportion of retail & service employment
#'     MeanRetPropRetSvc_Bz <-
#'       EmpSplitModel_ls$MeanRetPropRetSvc_D1D2[cbind(D1DGrp_Bz, D2Grp_Bz)]
#'     SdRetPropRetSvc_Bz <- EmpSplitModel_ls$SdRetPropRetSvc_D2[D2Grp_Bz]
#'     RetPropRetSvc_Bz <- rnorm(NBz, MeanRetPropRetSvc_Bz, SdRetPropRetSvc_Bz)
#'     RetPropRetSvc_Bz[RetPropRetSvc_Bz <= 0] <- RetProp / (RetProp + SvcProp)
#'     RetPropRetSvc_Bz[RetPropRetSvc_Bz > 1] <- 1
#'     SvcPropRetSvc_Bz <- 1 - RetPropRetSvc_Bz
#'     #Calculate retail and service employment
#'     RetEmp_Bz <- round(RetPropRetSvc_Bz * RetSvcEmp_Bz)
#'     while (sum(RetEmp_Bz) != RetEmp) {
#'       RetEmp_Bz <- matchBzEmp(RetEmp, RetEmp_Bz)
#'       RetEmp_Bz[RetEmp_Bz > RetSvcEmp_Bz] <- RetSvcEmp_Bz[RetEmp_Bz > RetSvcEmp_Bz]
#'     }
#'     SvcEmp_Bz <- RetSvcEmp_Bz - RetEmp_Bz
#'     #Return the result
#'     list(
#'       RetEmp = as.integer(RetEmp_Bz),
#'       SvcEmp = as.integer(SvcEmp_Bz),
#'       OthEmp = as.integer(OthEmp_Bz)
#'     )
#'   }
#'
#' #Define function to calculate entropy measure of diversity
#' #---------------------------------------------------------
#' #' \code{calcActivityEntropy} calculate entropy measure of SimBzone activity.
#' #'
#' #' This function calculates an entropy measure of activity diversity for each
#' #' SimBzone based on the numbers of households, retail jobs, service jobs, and
#' #' other jobs in the SimBzone.
#' #'
#' #' @param Hh_Bz A numeric vector of the number of households by SimBzone.
#' #' @param RetEmp_Bz A numeric vector of the number of retail jobs by SimBzone.
#' #' @param SvcEmp_Bz A numeric vector of the number of service jobs by SimBzone.
#' #' @param OthEmp_Bz A numeric vector of the number of other jobs by SimBzone.
#' #' @return A numeric vector containing the entropy measure of activity diversity
#' #' for each SimBzone.
#' #' @export
#' calcEntropy <- function(Hh_Bz, RetEmp_Bz, SvcEmp_Bz, OthEmp_Bz) {
#'   TotAct_Bz <- Hh_Bz + RetEmp_Bz + SvcEmp_Bz + OthEmp_Bz
#'   Tmp_df <- data.frame(
#'     TotAct = TotAct_Bz,
#'     NumHh = Hh_Bz,
#'     RetEmp = RetEmp_Bz,
#'     SvcEmp = SvcEmp_Bz,
#'     OthEmp = OthEmp_Bz
#'   )
#'   calcEntropyTerm <- function(AcRuame) {
#'     Act_ <- Tmp_df[[AcRuame]]
#'     ActRatio_ <- Act_ / Tmp_df$TotAct
#'     LogActRatio_ <- ActRatio_ * 0
#'     LogActRatio_[Act_ != 0] <- log(Act_[Act_ != 0] / Tmp_df$TotAct[Act_ != 0])
#'     ActRatio_ * LogActRatio_
#'   }
#'   E_df <- data.frame(
#'     Hh = calcEntropyTerm("NumHh"),
#'     Ret = calcEntropyTerm("RetEmp"),
#'     Svc = calcEntropyTerm("SvcEmp"),
#'     Oth = calcEntropyTerm("OthEmp")
#'   )
#'   A_ <- rowSums(E_df)
#'   N_ = apply(E_df, 1, function(x) sum(x != 0))
#'   -A_ / log(N_)
#' }
#'
#'
#' #Define a function to calculate the housing split for each SimBzone
#' #------------------------------------------------------------------
#' calculateHousingUnitsByType <-
#'   function(Hh_Bz, D1DGrp_Bz, D5Grp_Bz, D1Qntl_mx) {
#'     N <- length(Hh_Bz)
#'     #Choose quantile for each SimBzone
#'     Qntl_Bz <- sample(1:8, N, replace = TRUE)
#'     #Make matrix of value range for each SimBzone
#'     Range_Bz2 <- cbind(
#'       Min = D1Qntl_mx[cbind(D1DGrp_Bz, Qntl_Bz)],
#'       Max = D1Qntl_mx[cbind(D1DGrp_Bz, Qntl_Bz + 1)]
#'     )
#'     #Select a random value in range for each SimBzone
#'     MFProp_Bz <- t(apply(Range_Bz2, 1, function(x) runif(1, x[1], x[2])))
#'     #Calculate numbers of multifamily and single-family units each SimBzone
#'     MFDU_ <- round(Hh_Bz * MFProp_Bz)
#'     SFDU_ <- Hh_Bz - MFDU_
#'     #Return a list of the results
#'     list(
#'       SFDU = SFDU_,
#'       MFDU = MFDU_,
#'       PropMF = MFDU_ / (MFDU_ + SFDU_)
#'     )
#'   }
#'
#'
#' #Define a function to assign a D3bpo4 value to SimBzones
#' #-------------------------------------------------------
#' #Function is applied to location types within an Azone
#' calcD3bpo4 <- function(
#'   AreaType_Bz, DevType_Bz, AreaName, AveTarget = NULL, PropZeroTarget = NULL) {
#'   N <- length(AreaType_Bz)
#'   #Set WtAveD3 to AveTarget is not NULL
#'   if (!is.null(AveTarget)){
#'     WtAveD3 <- AveTarget
#'   }
#'   #Set PropZeroD3 if PropZeroTarget is not NULL
#'   if (!is.null(PropZeroTarget)) {
#'     PropZeroD3 <- PropZeroTarget
#'   }
#'   #Retrieve model values consistent with area name
#'   if (AreaName %in% c("Town", "Rural")) {
#'     if (AreaName == "Town") {
#'       if (is.null(AveTarget)) {
#'         WtAveD3 <- SimBzone_ls$TnProfiles$WtAveD3
#'       }
#'       if (is.null(PropZeroTarget)) {
#'         PropZeroD3 <- SimBzone_ls$TnProfiles$PropZeroD3
#'       }
#'       RelPowWtAveD3_Pt <- SimBzone_ls$TnProfiles$RelPowWtAveD3_Pt
#'       RelPropZeroD3_Pt <- SimBzone_ls$TnProfiles$RelPropZeroD3_Pt
#'       PowWtSdD3_Pt <- SimBzone_ls$TnProfiles$PowWtSdD3_Pt
#'       D3Pow <- SimBzone_ls$TnProfiles$D3Pow
#'     } else {
#'       if (is.null(AveTarget)) {
#'         WtAveD3 <- SimBzone_ls$RuProfiles$WtAveD3
#'       }
#'       if (is.null(PropZeroTarget)) {
#'         PropZeroD3 <- SimBzone_ls$RuProfiles$PropZeroD3
#'       }
#'       RelPowWtAveD3_Pt <- SimBzone_ls$RuProfiles$RelPowWtAveD3_Pt
#'       RelPropZeroD3_Pt <- SimBzone_ls$RuProfiles$RelPropZeroD3_Pt
#'       PowWtSdD3_Pt <- SimBzone_ls$RuProfiles$PowWtSdD3_Pt
#'       D3Pow <- SimBzone_ls$RuProfiles$D3Pow
#'     }
#'   } else {
#'     if (is.null(AveTarget)) {
#'       WtAveD3 <- SimBzone_ls$UaProfiles$WtAveD3_Ua[AreaName]
#'     }
#'     if (is.null(PropZeroTarget)) {
#'       PropZeroD3 <- SimBzone_ls$UaProfiles$PropZeroD3[AreaName]
#'     }
#'     RelPowWtAveD3_Pt <- SimBzone_ls$UaProfiles$RelPowWtAveD3_UaPt[AreaName,]
#'     RelPropZeroD3_Pt <- SimBzone_ls$UaProfiles$RelPropZeroD3_UaPt[AreaName,]
#'     PowWtSdD3_Pt <- SimBzone_ls$UaProfiles$PowWtSdD3_Pt
#'     D3Pow <- SimBzone_ls$UaProfiles$D3Pow
#'   }
#'   if (!is.null(AveTarget)) WtAveD3 <- AveTarget
#'   if (!is.null(PropZeroTarget)) PropZeroD3 <- PropZeroTarget
#'   #Create the place type names
#'   PlaceType_Bz <- paste(AreaType_Bz, DevType_Bz, sep = ".")
#'   #Identify the SimBzones that have a value of zero
#'   PropZeroD3_Pt <- PropZeroD3 * RelPropZeroD3_Pt
#'   PropZeroD3_Bz <- PropZeroD3_Pt[PlaceType_Bz]
#'   IsZero_Bz <- runif(N) < PropZeroD3_Bz
#'   #Calculate a D3bpo4 values
#'   PowWtAveD3_Pt <- RelPowWtAveD3_Pt * WtAveD3 ^ D3Pow
#'   PowWtAveD3_Bz <- PowWtAveD3_Pt[PlaceType_Bz]
#'   PowWtSdD3_Bz <- PowWtSdD3_Pt[PlaceType_Bz]
#'   PowD3_Bz <- rnorm(N, PowWtAveD3_Bz, PowWtSdD3_Bz)
#'   PowD3_Bz[IsZero_Bz] <- 0
#'   #Return the result
#'   PowD3_Bz ^ (1 / D3Pow)
#' }
#'
#' #Test the D3bpo model for selected urbanized areas
#' #-------------------------------------------------
#' png("data/ua_d3bpo4-test_.png", height = 600, width = 600)
#' Opar_ls <- par(mfrow = c(3,3), oma = c(0,0,3,0))
#' plotCompareD3 <- function(UzaName) {
#'   PtTest_ <- calcD3bpo4(
#'     AreaType_Bz = Ua_df$AreaType[Ua_df$UZA_NAME == UzaName],
#'     DevType_Bz = Ua_df$DevType[Ua_df$UZA_NAME == UzaName],
#'     AreaName = UzaName,
#'     AveTarget <- NULL,
#'     PropZeroTarget <- NULL)
#'   plot(density(PtTest_ ^ D3Pow), main = UzaName)
#'   lines(density((Ua_df$D3bpo4[Ua_df$UZA_NAME == UzaName]) ^ D3Pow), lty = 2)
#' }
#' for (ua in UzaToPlot_) {
#'   plotCompareD3(ua)
#' }
#' mtext(
#'   text = paste0("Distribution of Modeled (solid line) and Observed (dashed line) D3bpo4 Values",
#'                 "\nFor Selected Metropolitan Areas"),
#'   side = 3,
#'   outer = TRUE
#' )
#' par(Opar_ls)
#' dev.off()

#================
#MODEL TEST CODE
#================

# #Define a function to test the housing split for a place
# #-------------------------------------------------------
# testHousingSplit <- function(Data_df, LocType, PlaceName) {
#   #Get the model data to use
#   ProfileName <- switch(LocType,
#                         Metropolitan = "UaProfiles",
#                         Town = "RuProfiles",
#                         Rural = "RuProfiles"
#   )
#   #Apply the model
#   DU_ls <- calculateHousingUnitsByType(
#     Hh_Bz = Data_df$HH,
#     D1DGrp_Bz = Data_df$D1DGrp,
#     D5Grp_Bz = Data_df$D5Grp,
#     D1Qntl_mx = SimBzone_ls[[ProfileName]]$D1Qntl_mx
#   )
#   #Calculate estimated and observed numbers of multifamily units
#   NumMF_D1Ty <- cbind(
#     Est = tapply(DU_ls$MFDU, Data_df$D1DGrp, sum, na.rm = TRUE),
#     Obs = round(tapply(with(Data_df, HH * PropMF), Data_df$D1DGrp, sum, na.rm = TRUE)))
#   #Calculate estimated and observed numbers of single-family units
#   NumSF_D1Ty <- cbind(
#     Est = tapply(DU_ls$SFDU, Data_df$D1DGrp, sum, na.rm = TRUE),
#     Obs = round(tapply(with(Data_df, HH * PropSF), Data_df$D1DGrp, sum, na.rm = TRUE)))
#   #Calculate multifamily proportion
#   PropMF_D1Ty <- NumMF_D1Ty / (NumMF_D1Ty + NumSF_D1Ty)
#   #Plot comparison of numbers of multifamily dwellings by density level
#   matplot(NumMF_D1Ty, type = "l", lty = c(1,2), col = "black",
#           xlab = "Density Level", ylab = "Multifamily Dwelling Units",
#           main = paste0(PlaceName, "\nMultifamily Units"))
#   legend("topleft", legend = c("Model", "Observed"), bty = "n", lty = c(1, 2))
#   #Plot comparison of multifamily dwelling unit proportions by density level
#   matplot(PropMF_D1Ty, type = "l", lty = c(1,2), col = "black",
#           xlab = "Density Level", ylab = "Multifamily Proportion",
#           main = paste0(PlaceName, "\nMultifamily Proportion"))
#   legend("topleft", legend = c("Model", "Observed"), bty = "n", lty = c(1, 2))
# }
#
# #Test model for different location types and states
# #--------------------------------------------------
# #All areas
# png("data/housing-split_by_loctype_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3,2))
# testHousingSplit(Ua_df, "Metropolitan", "Metropolitan")
# testHousingSplit(Tn_df, "Town", "Town")
# testHousingSplit(Ru_df, "Rural", "Rural")
# par(Opar_ls)
# dev.off()
# #Oregon
# png("data/housing-split_by_loctype_or_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3,2))
# testHousingSplit(Ua_df[Ua_df$STATE == "OR",], "Metropolitan", "Oregon Metropolitan")
# testHousingSplit(Tn_df[Tn_df$STATE == "OR",], "Town", "Oregon Town")
# testHousingSplit(Ru_df[Ru_df$STATE == "OR",], "Rural", "Oregon Rural")
# par(Opar_ls)
# dev.off()
# #Washington
# png("data/housing-split_by_loctype_wa_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3,2))
# testHousingSplit(Ua_df[Ua_df$STATE == "WA",], "Metropolitan", "Washington Metropolitan")
# testHousingSplit(Tn_df[Tn_df$STATE == "WA",], "Town", "Washington Town")
# testHousingSplit(Ru_df[Ru_df$STATE == "WA",], "Rural", "Washington Rural")
# par(Opar_ls)
# dev.off()
# #Ohio
# png("data/housing-split_by_loctype_oh_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3,2))
# testHousingSplit(Ua_df[Ua_df$STATE == "OH",], "Metropolitan", "Ohio Metropolitan")
# testHousingSplit(Tn_df[Tn_df$STATE == "OH",], "Town", "Ohio Town")
# testHousingSplit(Ru_df[Ru_df$STATE == "OH",], "Rural", "Ohio Rural")
# par(Opar_ls)
# dev.off()
# #Urbanized area comparisons
# png("data/housing-split_by_ua1-ua3_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3, 2))
# for (ua in UzaToPlot_[1:3]) {
#   testHousingSplit(Ua_df[Ua_df$UZA_NAME == ua, ], "Metropolitan", ua)
# }
# par(Opar_ls)
# dev.off()
# png("data/housing-split_by_ua4-ua6_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3, 2))
# for (ua in UzaToPlot_[4:6]) {
#   testHousingSplit(Ua_df[Ua_df$UZA_NAME == ua, ], "Metropolitan", ua)
# }
# par(Opar_ls)
# dev.off()
# png("data/housing-split_by_ua7-ua9_test.png", height = 480, width = 480)
# Opar_ls <- par(mfrow = c(3, 2))
# for (ua in UzaToPlot_[7:9]) {
#   testHousingSplit(Ua_df[Ua_df$UZA_NAME == ua, ], "Metropolitan", ua)
# }
# par(Opar_ls)
# dev.off()



