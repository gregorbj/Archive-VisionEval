#=================
#CalculateCongestionFuture.R
#=================
# This module calculates the amount of congestion - automobile,
# light truck, truck, and bus vmt are allocated to freeways, arterials,
# and other roadways.



library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#Load the alternative mode trip models from GreenSTEP
load("inst/extdata/CongModel_ls.RData")
#Save the model
#' Congestion models and required parameters.
#'
#' A list of components describing congestion models and various parameters
#' required by those models.
#'
#' @format A list having 'Fwy' and 'Art' components. Each component has a
#' logistic model to indicate the level of congestion which are categorized
#' as NonePct, HvyPct, SevPct, and NonePct. This list also contains other
#' parameters that are used in the evaluation of aforementioned models.
#' @source GreenSTEP version ?.? model.
"CongModel_ls"
devtools::use_data(CongModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateCongestionFutureSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    # Azone variables
    item(
      NAME = "ITS",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    # Global variables
    item(
      NAME = "Type",
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("BusVmt","TruckVmt"),
      SIZE = 8
    ),
    item(
      NAME = "PropVmt",
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item(
        "Fwy",
        "Art",
        "Other"
      ),
      TABLE = "Vmt",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseLtVehDvmt",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "BaseFwyArtProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c('NA', '< 0', '> 1'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TranRevMiAdjFactor",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LtVehDvmtFactor",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    # Bzone variables
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      SIZE = 8,
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "DvmtFuture",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    # Marea variables
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 9,
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TruckDvmtFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "FwyLaneMiPCFuture",
        "ArtLaneMiPCFuture",
        "TranRevMiPCFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "BusRevMiFuture",
        "RailRevMiFuture"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    # Marea variables
    item(
      NAME = items(
        "LtVehDvmtFuture",
        "BusDvmtFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Daily vehicle miles travelled by light vehicles",
        "Daily vehicle miles travelled by bus"
      )
    ),
    item(
      NAME = items(
        "MpgAdjLtVehFuture",
        "MpgAdjBusFuture",
        "MpgAdjTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Fuel efficiency adjustment for light vehicles with internal combustion engine",
        "Fuel efficiency adjustment for buses with internal combustion engine",
        "Fuel efficiency adjustment for heavy trucks with internal combustion engine"
      )
    ),
    item(
      NAME = items(
        "MpKwhAdjLtVehHevFuture",
        "MpKwhAdjLtVehEvFuture",
        "MpKwhAdjBusFuture",
        "MpKwhAdjTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Power efficiency adjustment for light plugin/hybrid electric vehicles",
        "Power efficiency adjustment for light electric vehicles",
        "Power efficiency adjustment for buses with electric power train",
        "Power efficiency adjustment for heavy trucks with electric power train"
      )
    ),
    item(
      NAME = items(
        "VehHrLtVehFuture",
        "VehHrBusFuture",
        "VehHrTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Total vehicle travel time for light vehicles",
        "Total vehicle travel time for buses",
        "Total vehicle travel time for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "AveSpeedLtVehFuture",
        "AveSpeedBusFuture",
        "AveSpeedTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Average speed for light vehicles",
        "Average speed for buses",
        "Average speed for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "FfVehHrLtVehFuture",
        "FfVehHrBusFuture",
        "FfVehHrTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Freeflow travel time for light vehicles",
        "Freeflow travel time for buses",
        "Freeflow travel time for heavy trucks"
      )
    ),
    item(
      NAME = items(
        "DelayVehHrLtVehFuture",
        "DelayVehHrBusFuture",
        "DelayVehHrTruckFuture"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "HR",
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Total vehicle delay time for light vehicles",
        "Total vehicle delay time for buses",
        "Total vehicle delay time for heavy trucks"
      )
    ),
    item(
      NAME = "MpgAdjHhFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Fuel efficiency adjustment for households"
    ),
    item(
      NAME = "MpKwhAdjHevHhFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Power efficiency adjustment for households with HEV"
    ),
    item(
      NAME = "MpKwhAdjEvHhFuture",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      SIZE = 0,
      ISELEMENTOF = "",
      DESCRIPTION = "Power efficiency adjustment for households households with EV"
    )
  )
  )

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateCongestionFuture module
#'
#' A list containing specifications for the CalculateCongestionFuture module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateCongestionFuture.R script.
"CalculateCongestionFutureSpecifications"
devtools::use_data(CalculateCongestionFutureSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that calculates the amount of congestion
#------------------------------------------------------------------
#' Function to calculate the amount of congestion.
#'
#' \code{CalculateCongestionFuture} calculates the amount of congestion.
#'
#' Auto, and light truck vmt, truck vmt, and bus vmt are allocated to freeways, arterials,
#' and other roadways. Truck and bus vmt are allocated based on mode-specific data,
#' and auto and light truck vmt are allocated based on a combination of factors
#' and a model that is sensitive to the relative supplies of freeway and arterial
#' lane miles.
#'
#' System-wide ratios of vmt to lane miles for freeways and arterials
#' are used to allocate vmt to congestion levels using congestion levels defined by
#' the Texas Transportation Institute for the Urban Mobility Report. Each freeway and
#' arterial congestion level is associated with an average trip speed for conditions that
#' do and do not include ITS treatment for incident management on the roadway. Overall average
#' speeds by congestion level are calculated based on input assumptions about the degree of
#' incident management. Speed vs. fuel efficiency relationships for light vehicles, trucks,
#' and buses are used to adjust the fleet fuel efficiency averages computed for the region.

#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateCongestionFuture <- function(L) {
  #Set up
  #------
  # Function to rename variables to be consistent with Get specfications
  # of CalculateCongestionFuture

  # Function to add suffix 'Future' at the end of all the variable names
  AddSuffixFuture <- function(x, suffix = "Future"){
    # Check if x is a list
    if(is.list(x)){
      if(length(x) > 0){
        # Check if elements of x is a list
        isElementList <- unlist(lapply(x,is.list))
        # Modify the names of elements that are not the list
        noList <- x[!isElementList]
        if(!identical(names(noList),character(0))){
          names(noList) <- paste0(names(noList),suffix)
        }
        # Repeat the function for elements that are list
        yesList <- lapply(x[isElementList], AddSuffixFuture)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }


  # Function to remove suffix 'Future' from all the variable names
  RemoveSuffixFuture <- function(x, suffix = "Future"){
    # Check if x is a list
    if(is.list(x)){
      if(length(x) > 0){
        # Check if elements of x is a list
        isElementList <- unlist(lapply(x,is.list))
        # Modify the names of elements that are not the list
        noList <- x[!isElementList]
        if(length(noList)>0){
          names(noList) <- gsub(suffix,"",names(noList))
        }
        # Repeat the function for elements that are list
        yesList <- lapply(x[isElementList], RemoveSuffixFuture)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }

  # Modify the input data set
  L <- RemoveSuffixFuture(L)


  #Return the results
  #------------------
  # Call the CalculateTravelDemand function with the new dataset
  Out_ls <- CalculateCongestionBase(L)

  # Add 'Future' suffix to all the variables
  Out_ls <- AddSuffixFuture(Out_ls)
  #Return the outputs list
  return(Out_ls)
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateCongestionFuture",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateCongestionFuture",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "NotBaseYear"
# )
