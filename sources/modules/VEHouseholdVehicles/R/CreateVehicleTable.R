#====================
#CreateVehicleTable.R
#====================
#This module creates a vehicle table and populates it with household ID and
#geography fields

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


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module does not include any models


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CreateVehicleTableSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Vehicle",
      GROUP = "Year"
    )
  ),
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items("HhId",
              "Azone",
              "Marea"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("HhId",
              "VehId",
              "Azone",
              "Marea"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID",
              "Unique vehicle ID",
              "Azone ID",
              "Marea ID")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateVehicleTable module
#'
#' A list containing specifications for the CreateVehicleTable module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{NewSetTable}{table to be created}
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateVehicleTable.R script.
"CreateVehicleTableSpecifications"
devtools::use_data(CreateVehicleTableSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function initializes the 'Vehicle' table and populates it with the
#household ID (HhId), vehicle ID (VehID), and Azone datasets

#Main module function to create vehicle table with HhId and Azone datasets
#-------------------------------------------------------------------------
#' Create vehicle table and populate with HhId and Azone datasets.
#'
#' \code{CreateVehicleTable} create the vehicle table and populate with HhId
#' and Azone datasets.
#'
#' This function creates the 'Vehicle' table in the datastore and populates it
#' with HhId and Azone datasets.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'
CreateVehicleTable <- function(L) {
  #Identify households having vehicles
  Use <- L$Year$Household$Vehicles != 0
  #Create output list of results
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list()
  attributes(Out_ls$Year$Vehicle)$LENGTH <- sum(L$Year$Household$Vehicles)
  Out_ls$Year$Vehicle$HhId <-
    with(L$Year$Household, rep(HhId[Use], Vehicles[Use]))
  attributes(Out_ls$Year$Vehicle$HhId)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$HhId))
  Out_ls$Year$Vehicle$VehId <-
    with(L$Year$Household,
         paste(rep(HhId[Use], Vehicles[Use]),
               unlist(sapply(Vehicles[Use], function(x) 1:x)),
               sep = "-"))
  attributes(Out_ls$Year$Vehicle$VehId)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$VehId))
  Out_ls$Year$Vehicle$Azone <-
    with(L$Year$Household, rep(Azone[Use], Vehicles[Use]))
  attributes(Out_ls$Year$Vehicle$Azone)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$Azone))
  Out_ls$Year$Vehicle$Marea <-
    with(L$Year$Household, rep(Marea[Use], Vehicles[Use]))
  attributes(Out_ls$Year$Vehicle$Marea)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$Marea))
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
#   ModuleName = "CreateVehicleTable",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CreateVehicleTable",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
