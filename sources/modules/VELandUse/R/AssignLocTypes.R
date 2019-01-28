#==================
#AssignLocTypes.R
#==================
#
#<doc>
#
## AssignLocTypes Module
#### November 22, 2018
#
#This module assigns households to location types: Urban (located within an urbanized area boundary), Town (located in a smaller urban area that does not have enough population to qualify as an urbanized area), and Rural (located in an area characterized by low density dispersed development).
#
### Model Parameter Estimation
#
#This module has no parameters. Households are assigned to development types based on input assumptions on the proportions of housing units that are urban or town by Bzone and housing type.
#
### How the Module Works
#
#The user specifies the proportion of housing units that are *Urban* (located within an urbanized area boundary) or *Town* (located within a smaller urban area) by housing type (SF, MF, GQ) and Bzone. Each household is randomly assigned as *Urban*, *Town*, or *Rural* based on its housing type and Bzone and the urban/town/rural proportions of housing units of that housing type in that Bzone.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. Households are assigned to development types
#based on input assumptions on the proportions of housing units that are urban
#by Bzone and housing type.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignLocTypesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "PropUrbanSFDU",
          "PropUrbanMFDU",
          "PropUrbanGQDU",
          "PropTownSFDU",
          "PropTownMFDU",
          "PropTownGQDU"),
      FILE = "bzone_urban-town_du_proportions.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of single family dwelling units located within the urban portion of the zone",
          "Proportion of multi-family dwelling units located within the urban portion of the zone",
          "Proportion of group quarters accommodations located within the urban portion of the zone",
          "Proportion of single family dwelling units located within the town portion of the zone",
          "Proportion of multi-family dwelling units located within the town portion of the zone",
          "Proportion of group quarters accommodations located within the town portion of the zone"
        )
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
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
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
          "PropUrbanSFDU",
          "PropUrbanMFDU",
          "PropUrbanGQDU",
          "PropTownSFDU",
          "PropTownMFDU",
          "PropTownGQDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    ),
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "LocType",
      TABLE = "Household",
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
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = "Name of metropolitan area (Marea) that household is in or NA if none"
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Urbanized area population in the Bzone"
    ),
    item(
      NAME = "TownPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Town (i.e. urban but non-urbanized area) population in the Bzone"
    ),
    item(
      NAME = "RuralPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Rural (i.e. not urbanized and not town) population in the Bzone"
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Urbanized area population in the Marea"
    ),
    item(
      NAME = "TownPop",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Town (i.e. urban but non-urbanized area) in the Marea"
    ),
    item(
      NAME = "RuralPop",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Rural (i.e. not urbanized and not town) population in the Marea"
    ),
    item(
      NAME = "UrbanIncome",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total household income of the urbanized area population in the Marea"
    ),
    item(
      NAME = "TownIncome",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total household income of the town (i.e. urban but non-urbanized area) population in the Marea"
    ),
    item(
      NAME = "RuralIncome",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total household income of the rural (i.e. not urbanized and not town) population in the Marea"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignLocTypes module
#'
#' A list containing specifications for the AssignLocTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignLocTypes.R script.
"AssignLocTypesSpecifications"
usethis::use_data(AssignLocTypesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns a location type - Urban, Town, and Rural - to each household
#based on the household's housing type and Bzone and the proportion of the
#housing units of the housing type in the Bzone that are located in the urban
#area.

#Main module function that assigns a location type to each household
#-------------------------------------------------------------------
#' Main module function to assign a location type to each household.
#'
#' \code{AssignLocTypes} assigns a location type to each household.
#'
#' This function assigns a location type to each household based on the
#' household housing type and Bzone and input assumptions about the proportions
#' of housing units by housing type and Bzone that are urban or town.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval stats
#' @export
AssignLocTypes <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Calculate the number of households
  NumHh <- length(L$Year$Household[[1]])
  #Define a vector of development types
  Lt <- c("Urban", "Town", "Rural")
  #Define a vector of housing types
  Ht <- c("SF", "MF", "GQ")
  #Define a vector of Bzones
  Bz <- L$Year$Bzone$Bzone
  #Define a vector of Mareas
  Ma <- L$Year$Marea$Marea

  #Assign location types
  #---------------------
  #Create an array of location type proportions by Bzone and location type for
  #each housing type
  Props_BzHtLt <-
    array(NA, dim = c(length(Bz), length(Ht), length(Lt)),
          dimnames = list(Bz, Ht, Lt))
  Props_BzHtLt[,,"Urban"] <-
    with(L$Year$Bzone, cbind(PropUrbanSFDU, PropUrbanMFDU, PropUrbanGQDU))
  Props_BzHtLt[,,"Town"] <-
    with(L$Year$Bzone, cbind(PropTownSFDU, PropTownMFDU, PropTownGQDU))
  Props_BzHtLt[,,"Rural"] <-
    1 - Props_BzHtLt[,,"Urban"] + Props_BzHtLt[,,"Town"]
  #Define a function to do a whole number splitting according to proportions
  splitInt <- function(Props_, Tot) {
    SplitAll_ <- Props_ * Tot
    SplitInt_ <- round(SplitAll_)
    Rem <- sum(SplitAll_ - SplitInt_)
    if (Rem != 0) {
      RemTab_ <- table(
        sample(1:length(Props_), abs(Rem), replace = TRUE, prob = Props_)
      )
      SplitInt_[as.numeric(names(RemTab_))] <-
        SplitInt_[as.numeric(names(RemTab_))] + sign(Rem) * RemTab_
    }
    SplitInt_
  }
  #Calculate dwelling units by Bzone and housing type
  DU_BzHt <- table(L$Year$Household$Bzone, L$Year$Household$HouseType)[Bz,Ht]
  #Calculate dwelling units by Bzone, housing type and location type
  DU_BzHtLt <- sweep(Props_BzHtLt, c(1,2), DU_BzHt, splitInt)
  #Function to assign a location type to a set of households
  assignLocType <- function(HouseID_, NumDU_Lt) {
    Lt <- names(NumDU_Lt)
    LocType_ <- sample(rep(Lt, NumDU_Lt))
    names(LocType_) <- HouseID_
    LocType_
  }
  #Assign location type to all households
  LocType_Hh <- rep(NA, length(L$Year$Household$HhId))
  names(LocType_Hh) <- L$Year$Household$HhId
  for (bz in Bz) {
    for (ht in Ht) {
      HouseID_ <- with(L$Year$Household, HhId[Bzone == bz & HouseType == ht])
      NumDU_Lt <- DU_BzHtLt[bz,ht,]
      LocType_Hx <- assignLocType(HouseID_ = HouseID_, NumDU_Lt = NumDU_Lt)
      LocType_Hh[names(LocType_Hx)] <- unname(LocType_Hx)
    }
  }
  #Calculate population by Bzone and location type
  #-----------------------------------------------
  Pop_BzLt <- array(0, dim = c(length(Bz), length(Lt)), dimnames = list(Bz,Lt))
  Pop_BxLx <-
    tapply(L$Year$Household$HhSize, list(L$Year$Household$Bzone, LocType_Hh), sum)
  Pop_BzLt[rownames(Pop_BxLx), colnames(Pop_BxLx)] <- Pop_BxLx
  Pop_BzLt[is.na(Pop_BzLt)] <- 0

  #Calculate urban and rural population and total household income by Marea
  #------------------------------------------------------------------------
  #Vector of Mareas
  Ma <- L$Year$Marea$Marea
  #Identify Marea of households
  Marea_Hh <-
    L$Year$Bzone$Marea[(match(L$Year$Household$Bzone, L$Year$Bzone$Bzone))]
  #Sum up population by Marea and location type
  Pop_MaLt <- array(0, dim = c(length(Ma), length(Lt)), dimnames = list(Ma,Lt))
  Pop_MxLx <- tapply(L$Year$Household$HhSize, list(Marea_Hh, LocType_Hh), sum)
  Pop_MaLt[rownames(Pop_MxLx), colnames(Pop_MxLx)] <- Pop_MxLx
  Pop_MaLt[is.na(Pop_MaLt)] <- 0
  #Sum up income by Marea and location type
  Income_MaLt <- array(0, dim = c(length(Ma), length(Lt)), dimnames = list(Ma,Lt))
  Income_MxLx <- tapply(L$Year$Household$Income, list(Marea_Hh, LocType_Hh), sum)
  Income_MaLt[rownames(Income_MxLx), colnames(Income_MxLx)] <- Income_MxLx
  Income_MaLt[is.na(Income_MaLt)] <- 0

  #Return list of results
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household$LocType <- LocType_Hh
  Out_ls$Year$Household$Marea <- Marea_Hh
  attributes(Out_ls$Year$Household$Marea)$SIZE <-
    max(nchar(Marea_Hh[!is.na(Marea_Hh)]))
  Out_ls$Year$Bzone <-
    list(
      UrbanPop = unname(Pop_BzLt[Bz,"Urban"]),
      TownPop  = unname(Pop_BzLt[Bz,"Town"]),
      RuralPop = unname(Pop_BzLt[Bz,"Rural"])
    )
  Out_ls$Year$Marea <-
    list(
      UrbanPop = unname(Pop_MaLt[Ma,"Urban"]),
      TownPop  = unname(Pop_MaLt[Ma,"Town"]),
      RuralPop = unname(Pop_MaLt[Ma,"Rural"]),
      UrbanIncome = unname(Income_MaLt[Ma,"Urban"]),
      TownIncome  = unname(Income_MaLt[Ma,"Town"]),
      RuralIncome = unname(Income_MaLt[Ma,"Rural"])
    )
  Out_ls
}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignLocTypes")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
# library(fields)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-RSPM",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "verspm",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "AssignLocTypes",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- AssignLocTypes(TestDat_)
