#============
#Initialize.R
#============

#<doc>
## Initialize Module
#### November 27, 2018
#
#Modules in the VESimLandUse package synthesize Bzones and their land use attributes as a function of Azone characteristics as well as data derived from the US Environmental Protection Agency's Smart Location Database (SLD) augmented with US Census housing and household income data, and data from the National Transit Database. Details on these data are included in the VESimLandUseData package. The combined dataset contains a number of land use attributes at the US Census block group level. The goal of Bzone synthesis to generate a set of SimBzones in each Azone that reasonably represent block group land use characteristics given the characteristics of the Azone, the Marea that the Azone is a part of, and scenario inputs provided by the user.
#
#Many of the models and procedures used in Bzone synthesis pivot from profiles developed from these data sources for specific urbanized areas, as well as more general profiles for different urbanized area population size categories, towns, and rural areas. Using these specific and general profiles enables the simulated Bzones (SimBzones) to better represent the areas being modeled and the variety of conditions found in different states. Following is a listing of the urbanized areas for which profiles have been developed. Note that urbanized areas that cross state lines are split into the individual state components. This is done to faciliate the development of state models and to better reflect the characteristics of the urbanized area characteristics in each state.
#
#It is incumbent on the model user to identify the name of the urbanized area profile that will be used for each of the Mareas in the model. This module reads in the names assigned in the "marea_uza_profile_names.csv" file and checks their validity. If any are invalid, input processing will stop and error messages will be written to the log identifying the problem names. The following table identifies the names that may be used.
#
#<tab:UzaProfileNames_ls$Names_df>
#
#Note that at the bottom of the table are 6 generic names for urbanized areas of different sizes. If an urbanized area being modeled is not listed in the table, the user may substitute one of these generic names, or may use the name of a different urbanized area that the user believes has similar characteristics. The generic categories represent urbanized areas of different sizes measured by the total numbers of households and jobs in the area as follows:
#
#* **small**: 0 - 50,000 households and jobs
#
#* **medium-small**: 50,001 - 100,000 households and jobs
#
#* **medium**: 100,001 - 500,000 households and jobs
#
#* **medium-large**: 500,001 - 1,000,000 households and jobs
#
#* **large**: 1,000,001 - 5,000,000 households and jobs
#
#* **very-large**: More than 5,000,000 households and jobs
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

UzaProfileNames_ls <- list()

#Make a vector of acceptable urbanized area profile names
#--------------------------------------------------------
AllNames_ <- VESimLandUseData::SimLandUseData_df$UZA_NAME
LocType_ <- VESimLandUseData::SimLandUseData_df$LocType
UzaNames_ <- sort(unique(AllNames_[LocType_ == "Urban"]))
UzaNames_ <-
  c(UzaNames_,
    "small", "medium-small", "medium", "medium-large", "large", "very-large")
UzaProfileNames_ls$Names <- UzaNames_

#Create a table of urbanized area names to use for documentation
#---------------------------------------------------------------
#Make a matrix having 3 columns
UzaNamesPad_ <- c(UzaNames_, rep("", 3 - (length(UzaNames_) %% 3)))
UzaNames_mx <- matrix(UzaNamesPad_, ncol = 3, byrow = TRUE)
#Make a data frame having 3 columns of the names
UzaProfileNames_ls$Names_df <- data.frame(UzaNames_mx)
names(UzaProfileNames_ls$Names_df) <- c("Column 1", "Column 2", "Column 3")
rm(AllNames_, LocType_, UzaNames_, UzaNamesPad_, UzaNames_mx)

#Save the urbanized area profile names list
#------------------------------------------
#' Urbanized area profile names list
#'
#' A list containing the names of urbanized areas included in the profiles of
#' urbanized area land use characteristics.
#'
#' @format A list containing 2 components:
#' \describe{
#'  \item{Names}{a sorted vector of urbanized area names}
#'  \item{Inp}{a 3-column data frame of the names to include in documentation}
#' }
#' @source Initialize.R script.
"UzaProfileNames_ls"
usethis::use_data(UzaProfileNames_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
InitializeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "UzaProfileName",
      FILE = "marea_uza_profile_names.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      SIZE = 100,
      PROHIBIT = "",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Name of a specific urbanized area for the urbanized area profile to use in SimBzone creation or one of the following: small, medium-small, medium, medium-large, large, very-large"
    ),
    item(
      NAME = items(
        "PropMetroHh",
        "PropTownHh",
        "PropRuralHh"
      ),
      FILE = "azone_hh_loc_type_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of households residing in the metropolitan (i.e. urbanized) part of the Azone",
        "Proportion of households residing in towns (i.e. urban-like but not urbanized) in the Azone",
        "Proportion of households residing in rural (i.e. not urbanized or town) parts of the Azone"
      )
    ),
    item(
      NAME = items(
        "PropWkrInMetroJobs",
        "PropWkrInTownJobs",
        "PropWkrInRuralJobs",
        "PropMetroJobs"
      ),
      FILE = "azone_wkr_loc_type_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of workers residing in the Azone who work at jobs in the metropolitan (i.e. urbanized) area associated with the Azone",
        "Proportion of workers residing in the Azone who work at jobs in towns (i.e. urban-like but not urbanized) in the Azone",
        "Proportion of workers residing in the Azone who work at jobs in rural (i.e. not urbanized or town) parts of the Azone",
        "Proportion of the jobs of the metropolitan area that the Azone is associated with that are located in the metropolitan portion of the Azone"
      )
    ),
    item(
      NAME = items(
        "MetroLandArea",
        "TownLandArea"
      ),
      FILE = "azone_loc_type_land_area.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "SQMI",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Land area (excluding large water bodies and large tracts of undevelopable land) in the metropolitan (i.e. urbanized) portion of the Azone",
        "Land area (excluding large water bodies and large tracts of undevelopable land) in towns (i.e. urban-like but not urbanized) in the Azone"
      )
    ),
    item(
      NAME = "RuralAveDensity",
      FILE = "azone_loc_type_land_area.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HHJOB/ACRE",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = c("> 0.5"),
      TOTAL = "",
      DESCRIPTION = items(
        "Average activity density (households and jobs per acre) of rural (i.e. not metropolitan or town) portions of the Azone not including large waterbodies or large tracts of agricultural lands, forest lands, or otherwise protected lands"
      )
    )
  )
)
#Save the data specifications list
#---------------------------------
#' Specifications list for Initialize module
#'
#' A list containing specifications for the Initialize module.
#'
#' @format A list containing 2 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#' }
#' @source Initialize.R script.
"InitializeSpecifications"
usethis::use_data(InitializeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that checks whether urbanized area name is correct
#-----------------------------------------------------------------------
#' Check and adjust fuel and powertrain proportions inputs.
#'
#' \code{Initialize} checks optional fuel and powertrains proportions datasets
#' to determine whether they each sum to 1, creates error and warning messages,
#' and makes adjustments if necessary.
#'
#' This function processes optional user energy and emissions inputs that have
#' been preprocessed by the processModuleInputs function. It checks datasets
#' that specify fuel type or powertrain type proportions to determine whether
#' they sum to 1. If the sum for a dataset differs from 1 by more than 1%, then
#' the function returns an error message identifying the problem dataset. If the
#' sum differs from 1 but the difference is 1% or less it is assumed that the
#' difference is due to rounding errors and function adjusts the proportions so
#' that they equal 1. In this case, a warning message is returned as well that
#' the framework will write to the log.
#'
#' @param L A list containing data from preprocessing supplied optional input
#' files returned by the processModuleInputs function. This list has two
#' components: Errors and Data.
#' @return A list that is the same as the input list with an additional
#' Warnings component.
#' @import visioneval
#' @export
Initialize <- function(L) {

  #Set up
  #------
  #Initialize error and warnings message vectors
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Initialize output list with input values
  Out_ls <- L

  #Define function to check and adjust proportions
  #-----------------------------------------------
  checkProps <- function(Names_, Geo) {
    Values_ls <- L$Data$Year[[Geo]][Names_]
    #If more than one year, then need to evaluate multiple values
    if (length(Values_ls[[1]]) > 1) {
      Values_mx <- do.call(cbind, Values_ls)
      SumDiff_ <- abs(1 - rowSums(Values_mx))
      if (any(SumDiff_ > 0.01)) {
        Msg <- paste0(
          "Error in input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of values for a year is off by more than 1%. ",
          "They should add up to 1."
        )
        Errors_ <<- c(Errors_, Msg)
      }
      if (any(SumDiff_ > 0 & SumDiff_ < 0.01)) {
        Msg <- paste0(
          "Warning regarding input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of the values for a year do not add up to 1 ",
          "but are off by 1% or less so they have been adjusted to add up to 1."
        )
        Warnings_ <<- c(Warnings_, Msg)
        Values_mx <- sweep(Values_mx, 1, rowSums(Values_mx), "/")
        for (nm in colnames(Values_mx)) {
          Values_ls[[nm]] <- Values_mx[,nm]
        }
      }
      #Otherwise only need to evaluate single values
    } else {
      Values_ <- unlist(Values_ls)
      SumDiff <- abs(1 - sum(Values_))
      if (SumDiff > 0.01) {
        Msg <- paste0(
          "Error in input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of these values is off by more than 1%. ",
          "They should add up to 1."
        )
        Errors_ <<- c(Errors_, Msg)
      }
      if (SumDiff > 0 & SumDiff < 0.01) {
        Msg <- paste0(
          "Warning regarding input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of these values do not add up to 1 ",
          "but are off by 1% or less so they have been adjusted to add up to 1."
        )
        Warnings_ <<- c(Warnings_, Msg)
        Values_ <- Values_ / sum(Values_)
        for (nm in names(Values_)) {
          Values_ls[[nm]] <- Values_[nm]
        }
      }
    }
    Values_ls
  }

  #Check and adjust household location type proportions
  #----------------------------------------------------
  Names_ <- c("PropMetroHh", "PropTownHh", "PropRuralHh")
  if (all(Names_ %in% names(Out_ls$Data$Year$Azone))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Azone")
  } else {
    Msg <- paste0(
      "azone_hh_loc_type_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }
  rm(Names_)

  #Check and adjust worker location type proportions
  #-------------------------------------------------
  Names_ <- c("PropWkrInMetroJobs", "PropWkrInTownJobs", "PropWkrInRuralJobs")
  if (all(Names_ %in% names(Out_ls$Data$Year$Azone))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Azone")
  } else {
    Msg <- paste0(
      "azone_hh_loc_type_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }
  rm(Names_)

  #Check each assigned UzaProfileName for consistency
  #--------------------------------------------------
  UzaNames_ <- UzaProfileNames_ls$Names
  Marea_ <- L$Data$Global$Marea$Geo
  UzaProfileName_ <- L$Data$Global$Marea$UzaProfileName
  for (i in 1:length(Marea_)) {
    Marea <- Marea_[i]
    UzaProfileName <- UzaProfileName_[i]
    if (Marea != "None") {
      if (!(UzaProfileName %in% UzaNames_)) {
        ErrMsg <- paste0(
          "The urbanized area profile name - ", UzaProfileName,
          " - assigned to Marea - ", Marea, "does not exist. ",
          "Read the documentation for this (Initialize) module to see a list."
        )
        Errors_ <- c(Errors_, ErrMsg)
      }
    }
  }

  #Add Errors and Warnings to Out_ls and return
  #--------------------------------------------
  Out_ls$Errors <- Errors_
  Out_ls$Warnings <- Warnings_
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("Initialize")

#Test code to perform additional checks on input files. Return input list
#(TestDat_) to use for developing the Initialize function.
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
# #Return test dataset
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- Initialize(TestDat_)

#Test code to check everything including running the module and checking whether
#the code runs completely and produces desired results
#-------------------------------------------------------------------------------
# source("tests/scripts/test_functions.R")
#Set up test data
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

