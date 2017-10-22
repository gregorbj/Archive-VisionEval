#==================
#AssignDevTypes.R
#==================
#This module assigns development types - Urban and Rural - to households based
#on input values on the proportions of housing units that are within the
#urban area by Bzone and housing type.

# Copyright [2017] [AASHTO]
# Based in part on works previously copyrighted by the Oregon Department of
# Transportation and made available under the Apache License, Version 2.0 and
# compatible open-source licenses.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

library(visioneval)

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
AssignDevTypesSpecifications <- list(
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
          "PropUrbanGQDU"),
      FILE = "bzone_urban_du_proportions.csv",
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
          "Proportion of group quarters accommodations located within the urban portion of the zone"
        )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
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
          "PropUrbanGQDU"),
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
      UNITS = "dwelling type",
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural"),
      SIZE = 5,
      DESCRIPTION = "Development type (Urban or Rural) of the place where the household resides"
    ),
    item(
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "NA",
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
      DESCRIPTION = "Population in the Urban development type portion of the zone"
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
      DESCRIPTION = "Population in the Rural development type portion of the zone"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignDevTypes module
#'
#' A list containing specifications for the AssignDevTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignDevTypes.R script.
"AssignDevTypesSpecifications"
devtools::use_data(AssignDevTypesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns a development type - Urban and Rural - to each household
#based on the household's housing type and Bzone and the proportion of the
#housing units of the housing type in the Bzone that are located in the urban
#area.

# TestDat_ <- testModule(
#   ModuleName = "AssignDevTypes",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Main module function that assigns a development type to each household
#----------------------------------------------------------------------
#' Main module function to assign a development type to each household.
#'
#' \code{AssignDevTypes} assigns a development type to each household.
#'
#' This function assigns a development type to each household based on the
#' household housing type and Bzone and input assumptions about the proportion
#' of housing units by housing type and Bzone that are urban.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
AssignDevTypes <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Calculate the number of households
  NumHh <- length(L$Year$Household[[1]])
  #Define a vector of development types
  Dt <- c("Urban", "Rural")
  #Define a vector of housing types
  Ht <- c("SF", "MF", "GQ")
  #Define a vector of Bzones
  Bz <- L$Year$Bzone$Bzone

  #Assign development types
  #------------------------
  #Create matrix of urban proportions by Bzone and housing type
  PropNames <- c("PropUrbanSFDU", "PropUrbanMFDU", "PropUrbanGQDU")
  UrbanProp_BzHt <- as.matrix(data.frame(L$Year$Bzone[PropNames]))
  rm(PropNames)
  colnames(UrbanProp_BzHt) <- Ht
  rownames(UrbanProp_BzHt) <- Bz
  #Identify urban probability for each household
  UrbanProb_ <-
    UrbanProp_BzHt[cbind(L$Year$Household$Bzone, L$Year$Household$HouseType)]
  #Sample to identify development type
  DevType_ <- rep("Rural", NumHh)
  DevType_[runif(NumHh) <= UrbanProb_] <- "Urban"
  #Identify Marea
  Marea_ <-
    L$Year$Bzone$Marea[(match(L$Year$Household$Bzone, L$Year$Bzone$Bzone))]
  Marea_[DevType_ == "Rural"] <- "None"

  #Calculate urban and rural population by Bzone
  #---------------------------------------------
  Pop_BzDt <-
    tapply(L$Year$Household$HhSize,
           list(L$Year$Household$Bzone, DevType_),
           sum)[Bz,Dt]
  Pop_BzDt[is.na(Pop_BzDt)] <- 0

  #Return list of results
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household$DevType <- DevType_
  Out_ls$Year$Household$Marea <- Marea_
  attributes(Out_ls$Year$Household$Marea)$SIZE <-
    max(nchar(Marea_[!is.na(Marea_)]))
  Out_ls$Year$Bzone <-
    list(
      UrbanPop = unname(Pop_BzDt[,"Urban"]),
      RuralPop = unname(Pop_BzDt[,"Rural"])
    )
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
#   ModuleName = "AssignDevTypes",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignDevTypes",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

