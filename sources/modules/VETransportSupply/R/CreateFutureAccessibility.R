#=================
#CreateFutureAccessibility.R
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
CreateFutureAccessibilitySpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
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
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
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
      NAME =
        items(
          "FwyLaneMi",
          "ArtLaneMi"),
      TABLE = "Marea",
      GROUP = "BaseYear",
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
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "BaseYear",
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
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "FwyLaneMiGrowth",
          "ArtLaneMiGrowth"),
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "BusRevMiPCGrowth",
        "RailRevMiPCGrowth"),
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = items(
        "FwyLaneMiPCFuture",
        "ArtLaneMiPCFuture"),
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
      NAME = "TranRevMiPCFuture",
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
        "BusRevMiFuture",
        "RailRevMiFuture"),
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
#' Specifications list for CreateFutureAccessibility module
#'
#' A list containing specifications for the CreateFutureAccessibility module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateFutureAccessibility.R script.
"CreateFutureAccessibilitySpecifications"
devtools::use_data(CreateFutureAccessibilitySpecifications, overwrite = TRUE)


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
#' \code{CreateFutureAccessibility} calculate freeway and arterial lane-miles per capita, and
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
CreateFutureAccessibility <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea
  #Define vector of Mareas in base year
  BaseMA <- L$BaseYear$Marea$Marea

  #Calculate the freeway lane-miles per capita
  #-------------------------------------------
  #Calculate freeway lane-miles
  FwyLaneMi_Ma <- L$BaseYear$Marea$FwyLaneMi
  #Calculate population in the urbanized area
  UrbanPop_Ma <-
    tapply(L$Year$Bzone$UrbanPop, L$Year$Bzone$Marea, sum)[Ma]
  #Calculate base population in the urbanized area
  BaseUrbanPop_Ma <-
    tapply(L$BaseYear$Bzone$UrbanPop, L$BaseYear$Bzone$Marea, sum)[BaseMA]
  #Calculate the metropolitan population growth proportion
  UrbanPopChange_Ma <- max((UrbanPop_Ma/BaseUrbanPop_Ma) - 1,0)

  #Calculate the growth in freeway lane-miles
  FwyLaneMiGrowth <- UrbanPopChange_Ma * L$Global$Model$FwyLaneMiGrowth * FwyLaneMi_Ma
  #Calculate freeway lane-miles per capita
  FwyLaneMiPC_Ma <- 1000 * (FwyLaneMi_Ma + FwyLaneMiGrowth) / UrbanPop_Ma

  #Calculate the arterial lane-miles per capita
  #-------------------------------------------
  #Calculate arterial lane-miles
  ArtLaneMi_Ma <- L$BaseYear$Marea$ArtLaneMi
  #Calculate the growth in areterial lane-miles
  ArtLaneMiGrowth <- UrbanPopChange_Ma * L$Global$Model$ArtLaneMiGrowth * ArtLaneMi_Ma
  #Calculate arterial lane-miles per capita
  ArtLaneMiPC_Ma <- 1000 * (ArtLaneMi_Ma + ArtLaneMiGrowth) / UrbanPop_Ma

  #Calculate the bus rev-miles
  #-------------------------------------------
  #Calculate bus rev-miles per capita
  BusRevMiPC_Ma <- L$BaseYear$Marea$BusRevMiPC
  #Calculate bus rev-miles
  BusRevMi_Ma <- BusRevMiPC_Ma * UrbanPop_Ma * L$Global$Model$BusRevMiPCGrowth

  #Calculate the rail rev-miles
  #-------------------------------------------
  #Calculate rail rev-miles per capita
  RailRevMiPC_Ma <- L$BaseYear$Marea$RailRevMiPC
  #Calculate bus rev-miles
  RailRevMi_Ma <- RailRevMiPC_Ma * UrbanPop_Ma * L$Global$Model$RailRevMiPCGrowth

  #Calculate the transit rev-miles per capita
  #-------------------------------------------
  TranRevMiPC_Ma <- (BusRevMi_Ma + RailRevMi_Ma)/UrbanPop_Ma

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Marea <-
    list(
      FwyLaneMiPCFuture = FwyLaneMiPC_Ma,
      ArtLaneMiPCFuture = ArtLaneMiPC_Ma,
      TranRevMiPCFuture = TranRevMiPC_Ma,
      BusRevMiFuture = BusRevMi_Ma,
      RailRevMiFuture = RailRevMi_Ma
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
#   ModuleName = "CreateFutureAccessibility",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CreateFutureAccessibility",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
