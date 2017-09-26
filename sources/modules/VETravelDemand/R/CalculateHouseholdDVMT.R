#========================
#CalculateHouseholdDVMT.R
#========================
#This module models household average daily vehicle miles traveled as a function
#of household characteristics, vehicle ownership, and attributes of the
#neighborhood and metropolitan area where they reside.

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

#Load average DVMT model from GreenSTEP
load("inst/extdata/DvmtModel_ls.RData")
#Save the model
#' Daily vehicle miles traveled (DVMT) models
#'
#' A list of components describing the average daily vehicle miles traveled
#' models for metropolitan and non-metropolitan areas. The models are linear
#' models which predict average DVMT, 95th percentile DVMT, and maximum DVMT.
#' The models are linear regression models. The average DVMT model predicts
#' average DVMT as a power transform. The 'Pow' component contains the power
#' term for untransforming the model results. The 95th percentile and maximum
#' DVMT models predict the households 95th percentile and maximum daily travel
#' as a function of the household's average DVMT.
#'
#' @format A list having 'Metro' and 'NonMetro' components. Each component has
#' the following components:
#' Pow: factor to untransform the results of the average DVMT model;
#' Ave: the formula for the average DVMT model;
#' Pctl95: the formula for the 95th percentile DVMT model;
#' Max: the formula for the maximum DVMT model.
#' @source GreenSTEP version 3.6 model.
"DvmtModel_ls"
devtools::use_data(DvmtModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateHouseholdDVMTSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  Inp = NULL,
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
      NAME = "TranRevMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "FwyLaneMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
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
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D1B",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/SQMI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
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
      NAME =
        items("Age0to14",
              "Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "development type",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural")
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
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
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
    ),
    item(
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      PROHIBIT = "NA",
      ISELEMENTOF = c(0, 1)
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("Dvmt",
              "Dvmt95th",
              "DvmtMax"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Average daily vehicle miles traveled by the household in autos or light trucks",
          "95th percentile daily vehicle miles traveled by the household in autos or light trucks",
          "Maximum daily vehicle miles traveled by the household in autos or light trucks"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateHouseholdDVMT module
#'
#' A list containing specifications for the CalculateHouseholdDVMT module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateHouseholdDVMT.R script.
"CalculateHouseholdDVMTSpecifications"
devtools::use_data(CalculateHouseholdDVMTSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates average DVMT, 95th percentile day DVMT, and maximum
#DVMT.

#Main module function that calculates vehicle ownership
#------------------------------------------------------
#' Calculate the average household DVMT, 95th percentile household DVMT, and
#' maximum household DVMT.
#'
#' \code{CalculateHouseholdDVMT} calculate the average household DVMT, 95th
#' percentile household DVMT, and maximum household DVMT.
#'
#' This function calculates the average household DVMT, 95th percentile
#' household DVMT, and maximum household DVMT as a function of the household
#' characteristics and the characteristics of the area where the household
#' resides.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateHouseholdDVMT <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Calculate number of households
  NumHh <- length(L$Year$Household[[1]])

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  TranRevMiPC_Bz <-
    L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Tranmilescap <-
    TranRevMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  FwyLaneMiPC_Bz <-
    L$Year$Marea$FwyLaneMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$Fwylnmicap <-
    FwyLaneMiPC_Bz[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$Hhvehcnt <- Hh_df$Vehicles
  Hh_df$Urban <- Hh_df$IsUrbanMixNbrhd
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$LogIncome <- log1p(Hh_df$Income)
  Hh_df$Hbppopdn <-
    L$Year$Bzone$D1B[match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)]
  Hh_df$LowVehOwnership <-
    as.numeric(with(Hh_df, Vehicles / DrvAgePop < 0.25))
  Hh_df$Intercept <- 1

  #Apply the average DVMT model
  #----------------------------
  AveDvmt_ <- numeric(NumHh)
  IsUr_ <- Hh_df$DevType == "Urban"
  AveDvmt_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Ave),
                   envir = Hh_df[IsUr_,])) ^ (1 / DvmtModel_ls$Metro$Pow)
  AveDvmt_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Ave),
                   envir = Hh_df[!IsUr_,])) ^ (1 / DvmtModel_ls$NonMetro$Pow)
  #Limit the household DVMT to be no greater than 99th percentile for the population
  AveDvmt_[AveDvmt_ > quantile(AveDvmt_, 0.99)] <- quantile(AveDvmt_, 0.99)

  #Apply the 95th percentile and maximum DVMT models
  #-------------------------------------------------
  Hh_df$Dvmt <- AveDvmt_
  Hh_df$DvmtSq <- AveDvmt_ ^ 2
  Hh_df$DvmtCu <- AveDvmt_ ^ 3
  Dvmt95th_ <- numeric(NumHh)
  Dvmt95th_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Pctl95),
                   envir = Hh_df[IsUr_,]))
  Dvmt95th_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Pctl95),
                   envir = Hh_df[!IsUr_,]))
  DvmtMax_ <- numeric(NumHh)
  DvmtMax_[IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$Metro$Max),
                   envir = Hh_df[IsUr_,]))
  DvmtMax_[!IsUr_] <-
    as.vector(eval(parse(text = DvmtModel_ls$NonMetro$Max),
                   envir = Hh_df[!IsUr_,]))

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Dvmt = AveDvmt_,
      Dvmt95th = Dvmt95th_,
      DvmtMax = DvmtMax_)
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
#   ModuleName = "CalculateHouseholdDVMT",
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
#   ModuleName = "CalculateHouseholdDVMT",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
