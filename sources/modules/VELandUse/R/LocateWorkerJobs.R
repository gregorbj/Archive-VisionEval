#==================
#LocateWorkerJobs.R
#==================
#This module creates a Worker table and places workers in Bzones. Worker
#assignment to Bzones is done randomly.

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
#This module has no parameters. Workers are assigned randomly to Bzones
#consistent with the number of jobs in each Bzone.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
LocateWorkerJobsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Worker",
      GROUP = "Year"
    )
  ),
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "TotEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("HhId",
              "WkrId",
              "Bzone"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID",
              "Unique worker ID",
              "Bzone ID of worker job location")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for LocateWorkerJobs module
#'
#' A list containing specifications for the LocateWorkerJobs module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{NewSetTable}{specifications for new table created by module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source LocateWorkerJobs.R script.
"LocateWorkerJobsSpecifications"
devtools::use_data(LocateWorkerJobsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function creates a Worker table and creates datasets identifying the
#household ID, worker ID, and Bzone of the job location of each worker

#Main module function that assigns workers to job locations
#----------------------------------------------------------
#' Main module function to assign workers to job locations.
#'
#' \code{LocateHouseholds} assigns workers to job locations.
#'
#' This function assigns workers to Bzone job locations. Workers are assigned
#' randomly to job locations consistent with the number of total jobs in the
#' location.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
LocateWorkerJobs <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  #Return table and datasets
  #-------------------------
  #Identify households having workers
  Use <- L$Year$Household$Workers != 0
  #Initialize output list
  Out_ls <- initDataList()
  #Populate
  Out_ls$Year$Worker <- list()
  attributes(Out_ls$Year$Worker)$LENGTH <- sum(L$Year$Household$Workers)
  Out_ls$Year$Worker$HhId <-
    with(L$Year$Household, rep(HhId[Use], Workers[Use]))
  attributes(Out_ls$Year$Worker$HhId)$SIZE <- max(nchar(Out_ls$Year$Worker$HhId))
  Out_ls$Year$Worker$WkrId <-
    with(L$Year$Household,
         paste(
           rep(HhId[Use], Workers[Use]),
           unlist(sapply(Workers[Use], function(x) 1:x)),
           sep = "-"))
  attributes(Out_ls$Year$Worker$WkrId)$SIZE <- max(nchar(Out_ls$Year$Worker$WkrId))
  Out_ls$Year$Worker$Bzone <- sample(with(L$Year$Bzone, rep(Bzone, TotEmp)))
  attributes(Out_ls$Year$Worker$Bzone)$SIZE <- max(nchar(Out_ls$Year$Worker$Bzone))
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
#   ModuleName = "LocateWorkerJobs",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "LocateWorkerJobs",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
