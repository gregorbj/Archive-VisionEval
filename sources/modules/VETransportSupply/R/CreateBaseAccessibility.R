#=================
#CreateBaseAccessibility.R
#=================
#This module assigns freeway and arterial lane-miles to metropolitan areas
#(Marea) and calculate freeway and arterial lane-miles per capita.
#This module also assigns bus and rail revenue miles per capita to
# metropolitan areas (Marea) and calculate bus and rail lane-miles.



library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no estimation models and no parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CreateBaseAccessibilitySpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      FILE = "marea_lane_miles.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Lane-miles of roadways functionally classified as freeways or expressways in the urbanized portion of the metropolitan area",
          "Lane-miles of roadways functionally classified as arterials (but not freeways or expressways) in the urbanized portion of the metropolitan area")
    ),
    item(
      NAME =
        items(
          "BusRevMiPC",
          "RailRevMiPC"),
      FILE = "marea_rev_miles_pc.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      SIZE = 0,
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Annual bus revenue miles per capita for the region",
          "Annual rail revenue miles per capita for the region")
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "BusRevMiPC",
        "RailRevMiPC"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = items(
        "FwyLaneMiPC",
        "ArtLaneMiPC"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Ratio of urbanized area freeway and expressway lane-miles to urbanized area population",
        "Ratio of urbanized area arterial lane-miles to urbanized area population")
    ),
    item(
      NAME = "TranRevMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Transit revenue miles per capita for the region"),
    item(
      NAME = items(
        "BusRevMi",
        "RailRevMi"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Bus revenue miles for the region",
        "Rail revenue miles for the region")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateBaseAccessibility module
#'
#' A list containing specifications for the CreateBaseAccessibility module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateBaseAccessibility.R script.
"CreateBaseAccessibilitySpecifications"
devtools::use_data(CreateBaseAccessibilitySpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the freeway lane-miles per capita for the urbanized
#area from the number of freeway lane-miles and the urban area population.
#It also calculates the bus and rail revenue miles for the urbanized
#area from the number of bus and rail revenue miles per capita
#and the urban area population.

#Main module function that calculates freeway lane-miles per capita
#------------------------------------------------------------------
#' Calculate freeway lane-miles per capita by Marea and
#' calculate bus and rail revenue miles by Marea.
#'
#' \code{CreateBaseAccessibility} calculate freeway and arterial lane-miles per capita, and
#' bus and rail rev-miles.
#'
#' This function calculates freeway and arterial lane-miles per capita, and
#' bus and rail rev-miles for each Marea.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CreateBaseAccessibility <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea

  #Calculate the freeway lane-miles per capita
  #-------------------------------------------
  #Calculate freeway lane-miles
  FwyLaneMi_Ma <- L$Year$Marea$FwyLaneMi
  #Calculate population in the urbanized area
  UrbanPop_Ma <-
    tapply(L$Year$Bzone$UrbanPop, L$Year$Bzone$Marea, sum)[Ma]
  #Calculate freeway lane-miles per capita
  FwyLaneMiPC_Ma <- FwyLaneMi_Ma / UrbanPop_Ma

  #Calculate the arterial lane-miles per capita
  #-------------------------------------------
  #Calculate arterial lane-miles
  ArtLaneMi_Ma <- L$Year$Marea$ArtLaneMi
  #Calculate arterial lane-miles per capita
  ArtLaneMiPC_Ma <- ArtLaneMi_Ma / UrbanPop_Ma

  #Calculate the bus rev-miles
  #-------------------------------------------
  #Calculate bus rev-miles per capita
  BusRevMiPC_Ma <- L$Year$Marea$BusRevMiPC
  #Calculate bus rev-miles
  BusRevMi_Ma <- BusRevMiPC_Ma * UrbanPop_Ma

  #Calculate the rail rev-miles
  #-------------------------------------------
  #Calculate rail rev-miles per capita
  RailRevMiPC_Ma <- L$Year$Marea$RailRevMiPC
  #Calculate bus rev-miles
  RailRevMi_Ma <- RailRevMiPC_Ma * UrbanPop_Ma

  #Calculate the transit rev-miles per capita
  #-------------------------------------------
  TranRevMiPC_Ma <- BusRevMiPC_Ma + RailRevMiPC_Ma

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(
      FwyLaneMiPC = FwyLaneMiPC_Ma,
      ArtLaneMiPC = ArtLaneMiPC_Ma,
      TranRevMiPC = TranRevMiPC_Ma,
      BusRevMi = BusRevMi_Ma,
      RailRevMi = RailRevMi_Ma
    )
  #Return the outputs list
  Out_ls
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CreateBaseAccessibility",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CreateBaseAccessibility",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
