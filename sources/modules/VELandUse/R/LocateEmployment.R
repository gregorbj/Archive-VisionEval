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
      TOTAL = ""
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
      SIZE = 0
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
      SIZE = 0
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
#' @param EmpDiff An number identifying the total difference in employment
#' where a positive number indicates more workers than employment and a negative
#' number indicates more employment than workers.
#' @param Emp_Bz A named numeric vector identifying the employment of the type
#' in each Bzone.
#' @return A list having two components:
#' BalancedEmp_Bz A named numeric vector giving the employment by Bzone which
#' matches workers, and
#' AdjEmp_Bz A named numeric vector giving the amount of adjustment that was
#' made to the original employment in each Bzone.
adjustEmployment <- function(EmpDiff, Emp_Bz) {
  AdjProbs_Bz <- Emp_Bz / sum(Emp_Bz)
  AdjEmp_Bz <- Emp_Bz * 0
  AdjEmp_ <-
    sample(names(Emp_Bz), abs(EmpDiff), replace = TRUE, prob = AdjProbs_Bz)
  AdjEmp_Bx <- sign(EmpDiff) * table(AdjEmp_)
  AdjEmp_Bz[names(AdjEmp_Bx)] <- AdjEmp_Bx
  list(
    BalancedEmp_Bz = Emp_Bz + AdjEmp_Bz,
    AdjEmp_Bz = AdjEmp_Bz
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
      EmpDiff = TotEmpDiff,
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


#====================
#SECTION 4: TEST CODE
#====================
#The following code is useful for testing and module function development. The
#first part initializes a datastore, loads inputs, and checks that the datastore
#contains the data needed to run the module. The second part produces a list of
#the data the module function will be provided by the framework when it is run.
#This is useful to have when developing the module function. The third part
#runs the whole module to check that everything runs correctly and that the
#module outputs are consistent with specifications. Note that if a module
#requires data produced by another module, the test code for the other module
#must be run first so that the datastore contains the requisite data. Also note
#that it is important that all of the test code is commented out when the
#the package is built.

#1) Test code to set up datastore and return module specifications
#-----------------------------------------------------------------
#The following commented-out code can be run to initialize a datastore, load
#inputs, and check that the datastore contains the data needed to run the
#module. It return the processed module specifications which can be used in
#conjunction with the getFromDatastore function to fetch the list of data needed
#by the module. Note that the following code assumes that all the data required
#to set up a datastore are in the defs and inputs directories in the tests
#directory. All files in the defs directory must have the default names.
#
# Specs_ls <- testModule(
#   ModuleName = "LocateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
#
#2) Test code to create a list of module inputs to use in module function
#------------------------------------------------------------------------
#The following commented-out code can be run to create a list of module inputs
#that may be used in the development of module functions. Note that the data
#will be returned for the first year in the run years specified in the
#run_parameters.json file. Also note that if the RunBy specification is not
#Region, the code will by default return the data for the first geographic area
#in the datastore.
#
# setwd("tests")
# Year <- getYears()[1]
# if (Specs_ls$RunBy == "Region") {
#   L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = NULL)
# } else {
#   GeoCategory <- Specs_ls$RunBy
#   Geo_ <- readFromTable(GeoCategory, GeoCategory, Year)
#   L <- getFromDatastore(Specs_ls, RunYear = Year, Geo = Geo_[1])
#   rm(GeoCategory, Geo_)
# }
# rm(Year)
# setwd("..")
#
#3) Test code to run full module tests
#-------------------------------------
#Run the following commented-out code after the module functions have been
#written to test all aspects of the module including whether the module can be
#run and whether the module will produce results that are consistent with the
#module's Set specifications. It is also important to run this code if one or
#more other modules in the package need the dataset(s) produced by this module.
#
# testModule(
#   ModuleName = "LocateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
