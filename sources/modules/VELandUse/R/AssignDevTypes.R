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
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "dwelling type",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    ),
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "dwelling type",
      NAVALUE = -1,
      PROHIBIT = "",
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
      UNITS = "development type",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural"),
      SIZE = 5
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

  #Return list of results
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(DevType = DevType_)
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
#   ModuleName = "AssignDevTypes",
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
#   ModuleName = "AssignDevTypes",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
