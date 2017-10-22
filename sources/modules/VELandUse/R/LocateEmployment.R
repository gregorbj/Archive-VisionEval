#==================
#LocateEmployment.R
#==================
#This module places employment in Bzones based on input assumptions of
#employment by type and Bzone. The model adjusts the employment numbers to
#balance with the number of workers in the region.

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
#This module has no parameters. Employment is allocated to Bzones based on
#inputs and balancing with number of regional workers.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
LocateEmploymentSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp"),
      FILE = "bzone_employment.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Total number of jobs in zone",
          "Number of jobs in retail sector in zone",
          "Number of jobs in service sector in zone"
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
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp"),
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
          "Number of jobs in service sector in zone"
        )
    ),
    item(
      NAME =
        items("TotEmpAdj",
              "RetEmpAdj",
              "SvcEmpAdj"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -999999,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Difference between modeled TotEmp and input TotEmp in zone",
          "Difference between modeled RetEmp and input RetEmp in zone",
          "Difference between modeled SvcEmp and input SvcEmp in zone"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for LocateEmployment module
#'
#' A list containing specifications for the LocateEmployment module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source LocateEmployment.R script.
"LocateEmploymentSpecifications"
devtools::use_data(LocateEmploymentSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function locates households in Bzones based on the housing type of each
#household, the supply of housing of that housing type in each Bzone, the
#income of the household, and the Bzone location weight of each household.
#First housing supply and demand are balanced to assure that there are
#sufficient housing units of each type in the Azone. Then households are ordered
#by income from highest to lowest. Each household is assign a Bzone in that
#order. The probability of a household being assigned to a Bzone is a function
#of the supply of housing of the type in the Bzone and the location weight of
#the Bzone. After a household has been assigned to a Bzone, the housing
#inventory of the Bzone is decremented and the next household is then assigned.

#Function to adjust employment to match workers
#----------------------------------------------
#' Adjusts Bzone employment to match workers
#'
#' \code{adjustEmployment} adjusts Bzone employment by type so that total
#' employment matches total workers.
#'
#' The function adjusts the input values of employment by type and Bzone so that
#' the total amount of employment for the region equals the total number of
#' workers for the region.
#'
#' @param EmpTarget An number identifying the total number of jobs so that each
#' worker has a job.
#' @param Emp_Bz A named numeric vector identifying the employment of the type
#' in each Bzone.
#' @return A list having two components:
#' BalancedEmp_Bz A named numeric vector giving the employment by Bzone which
#' matches workers, and
#' AdjEmp_Bz A named numeric vector giving the amount of adjustment that was
#' made to the original employment in each Bzone.
adjustEmployment <- function(EmpTarget, Emp_Bz) {
  EmpProbs_Bz <- Emp_Bz / sum(Emp_Bz)
  RevEmp_Bz <- Emp_Bz * 0
  RevEmp_ <-
    sample(names(Emp_Bz), EmpTarget, replace = TRUE, prob = EmpProbs_Bz)
  RevEmp_Bx <- table(RevEmp_)
  RevEmp_Bz[names(RevEmp_Bx)] <- RevEmp_Bx
  list(
    BalancedEmp_Bz = RevEmp_Bz,
    AdjEmp_Bz = RevEmp_Bz - Emp_Bz
  )
}

#Main module function that assigns employment by type to Bzones
#--------------------------------------------------------------
#' Main module function to assign employment by type to Bzones.
#'
#' \code{LocateHouseholds} assigns employment by type to Bzones.
#'
#' This function assigns employment by type to Bzones based on inputs of
#' employment by type by Bzone with adjustment of employment to equal region-
#' wide total of workers.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
LocateEmployment <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  #Balance employment and workers
  #------------------------------
  #Calculate the total number of workers for the region
  TotWkr <- sum(L$Year$Azone$NumWkr)
  #Calculate the total employment for the region
  TotEmp <- sum(L$Year$Bzone$TotEmp)
  #Calculate the difference between total workers and total employment
  TotEmpDiff <- TotWkr - TotEmp
  #Calculate adjusted total employment by Bzone
  TotEmp_Bz <- L$Year$Bzone$TotEmp
  names(TotEmp_Bz) <- L$Year$Bzone$Bzone
  TotEmp_ls <-
    adjustEmployment(
      EmpTarget = TotWkr,
      Emp_Bz = TotEmp_Bz
    )
  #Calculate adjusted retail employment by Bzone
  RetEmp_Bz <- L$Year$Bzone$RetEmp
  names(RetEmp_Bz) <- L$Year$Bzone$Bzone
  RetEmpRatio_Bz <- RetEmp_Bz / TotEmp_Bz
  RetEmp_ls <- list(
    BalancedEmp_Bz = round(TotEmp_ls$BalancedEmp_Bz * RetEmpRatio_Bz),
    AdjEmp_Bz = round(TotEmp_ls$AdjEmp_Bz * RetEmpRatio_Bz)
  )
  rm(RetEmp_Bz,  RetEmpRatio_Bz)
  #Calculate adjusted service employment by Bzone
  SvcEmp_Bz <- L$Year$Bzone$SvcEmp
  names(SvcEmp_Bz) <- L$Year$Bzone$Bzone
  SvcEmpRatio_Bz <- SvcEmp_Bz / TotEmp_Bz
  SvcEmp_ls <- list(
    BalancedEmp_Bz = round(TotEmp_ls$BalancedEmp_Bz * SvcEmpRatio_Bz),
    AdjEmp_Bz = round(TotEmp_ls$AdjEmp_Bz * SvcEmpRatio_Bz)
  )
  rm(SvcEmp_Bz,  SvcEmpRatio_Bz)

  #Return list of results
  #----------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Bzone <-
    list(TotEmp = integer(0),
         RetEmp = integer(0),
         SvcEmp = integer(0),
         TotEmpAdj = integer(0),
         RetEmpAdj = integer(0),
         SvcEmpAdj = integer(0))
  #Add the revised employment by Bzone
  Out_ls$Year$Bzone$TotEmp <- as.integer(unname(TotEmp_ls$BalancedEmp_Bz))
  Out_ls$Year$Bzone$RetEmp <- as.integer(unname(RetEmp_ls$BalancedEmp_Bz))
  Out_ls$Year$Bzone$SvcEmp <- as.integer(unname(SvcEmp_ls$BalancedEmp_Bz))
  #Add the employment adjustments by Bzone
  Out_ls$Year$Bzone$TotEmpAdj <- as.integer(unname(TotEmp_ls$AdjEmp_Bz))
  Out_ls$Year$Bzone$RetEmpAdj <- as.integer(unname(RetEmp_ls$AdjEmp_Bz))
  Out_ls$Year$Bzone$SvcEmpAdj <- as.integer(unname(SvcEmp_ls$AdjEmp_Bz))
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
#   ModuleName = "LocateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "LocateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
