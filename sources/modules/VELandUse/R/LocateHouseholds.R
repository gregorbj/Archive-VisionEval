#==================
#LocateHouseholds.R
#==================
#This module places households in Bzones based on the household housing type,
#the supply of housing by type by Bzone, the household income, and the
#relative desirability of each Bzone.

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
#This module has no parameters. Households are assigned to Bzones based on an
#algorithm implemented in the LocateHouseholds function.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
LocateHouseholdsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "Weights",
      FILE = "bzone_location_weights.csv",
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
          "SFDU",
          "MFDU",
          "GQDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Weights",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
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
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "SFDU",
          "MFDU",
          "GQDU"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME =
        items(
          "SFDUadj",
          "MFDUadj",
          "GQDUadj"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "DU",
      NAVALUE = -999999,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for LocateHouseholds module
#'
#' A list containing specifications for the LocateHouseholds module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source LocateHouseholds.R script.
"LocateHouseholdsSpecifications"
devtools::use_data(LocateHouseholdsSpecifications, overwrite = TRUE)


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

#Function to adjust supply of dwelling units to match demand
#-----------------------------------------------------------
#' Adjusts supply of housing to match total demand for a housing type
#'
#' \code{adjustHousingSupply} adjusts housing supply in each Bzone so that the
#' total matches housing demand for a housing type
#'
#' Although the function which assigns a housing type to each household closely
#' matches the proportions of housing by type, it does not exactly match the
#' proportions. Furthermore the dwelling unit input numbers may not exactly
#' match the total number of households. For these reasons, the supply of
#' dwelling units by type may not match the demand. This function adjusts the
#' supply so that it matches demand. The units of a type in each Bzone are
#' adjusted in proportion to the total number of units of that type.
#'
#' @param TotUnitDiff An number identifying the total difference in units where
#' a positive number indicates more demand than supply and a negative number
#' indicates more supply than demand.
#' @param Units_Bz A named numeric vector identifying the number of dwelling
#' units of the type in each Bzone.
#' @return A list having two components:
#' BalancedUnits_Bz A named numeric vector giving the number of units by Bzone
#' which matches total demand, and
#' AdjUnits_Bz A named numeric vector giving the amount of adjustment that was
#' made to the original number of units in each Bzone.
adjustHousingSupply <- function(TotUnitDiff, Units_Bz) {
  AdjProbs_Bz <- Units_Bz / sum(Units_Bz)
  AdjUnits_Bz <- Units_Bz * 0
  AdjUnits_ <-
    sample(names(Units_Bz), abs(TotUnitDiff), replace = TRUE, prob = AdjProbs_Bz)
  AdjUnits_Bx <- sign(TotUnitDiff) * table(AdjUnits_)
  AdjUnits_Bz[names(AdjUnits_Bx)] <- AdjUnits_Bx
  list(
    BalancedUnits_Bz = Units_Bz + AdjUnits_Bz,
    AdjUnits_Bz = AdjUnits_Bz
  )
}

#Function to choose Bzone locations for households
#-------------------------------------------------
#' Assigns Bzones for set of households
#'
#' \code{chooseLocations} assigns Bzones to households based on number of
#' dwelling units in each Bzone and Bzone weights.
#'
#' This function assigns Bzone locations to households for a specified housing
#' type. Households are assigned to Bzones in descending order of their
#' incomes (e.g. highest income household gets first choice). The probability
#' that a household is assigned a Bzone is a function of the number of
#' available housing units in each Bzone and attraction weights of each Bzone.
#'
#' @param SortedHhIds_ A character vector of household IDs sorted in descending
#' order of household income.
#' @param Capacity_Bz A numeric named vector of the number of dwelling units
#' in each Bzone named with the Bzone names.
#' @param Weights_Bz A numeric named vector of attraction weights by Bzone
#' named with the Bzone names.
#' @return A named character vector of Bzones named with the corresponding
#' household IDs.
chooseLocations <- function(SortedHhIds_, Capacity_Bz, Weights_Bz) {
  NumHh <- length(SortedHhIds_)
  Choices_Hh <- character(NumHh)
  names(Choices_Hh) <- SortedHhIds_
  Bz <- names(Capacity_Bz)
  for( i in 1:NumHh ) {
    # Calculate probability of each choice based on the number of units and the income weights
    Prob_Bz <- Capacity_Bz * Weights_Bz / sum(Capacity_Bz * Weights_Bz)
    # Choose the index to the corresponding DevTypes. and Districts. vectors
    Choice <- sample(Bz, 1, prob=Prob_Bz)
    # Update the inventory of units
    Capacity_Bz[Choice] <- Capacity_Bz[Choice] - 1
    # Retain the choice
    Choices_Hh[i] <- Choice
  }
  Choices_Hh
}

#Main module function that assigns a Bzone location to each household
#--------------------------------------------------------------------
#' Main module function to assign the Bzone for all households.
#'
#' \code{LocateHouseholds} assigns households to Bzones.
#'
#' This function assigns households to Bzones based on the housing type and
#' income of each household and on the housing supply and location weight of
#' each Bzone.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
LocateHouseholds <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Calculate the number of households
  NumHh <- length(L$Year$Household[[1]])
  #Define a vector of housing types
  Ht <- c("SF", "MF", "GQ")

  #Balance housing supply and demand
  #---------------------------------
  #Calculate the total dwelling unit demand by type
  Demand_Ht <- table(L$Year$Household$HouseType)[Ht]
  #Calculate the total supply of dwelling units by type
  Supply_Ht <-
    c(SF = sum(L$Year$Bzone$SFDU),
      MF = sum(L$Year$Bzone$MFDU),
      GQ = sum(L$Year$Bzone$GQDU))[Ht]
  #Calculate the difference in supply and demand
  UnitsDiff_Ht <- Demand_Ht - Supply_Ht
  #Calculate adjusted SF dwelling units by Bzone
  SFUnits_Bz <- L$Year$Bzone$SFDU
  names(SFUnits_Bz) <- L$Year$Bzone$Bzone
  SFUnits_ls <-
    adjustHousingSupply(
      TotUnitDiff = UnitsDiff_Ht["SF"],
      Units_Bz = SFUnits_Bz
    )
  rm(SFUnits_Bz)
  #Calculate adjusted MF dwelling units by Bzone
  MFUnits_Bz <- L$Year$Bzone$MFDU
  names(MFUnits_Bz) <- L$Year$Bzone$Bzone
  MFUnits_ls <-
    adjustHousingSupply(
      TotUnitDiff = UnitsDiff_Ht["MF"],
      Units_Bz = MFUnits_Bz
    )
  rm(MFUnits_Bz)
  #Calculate adjusted GQ dwelling units by Bzone
  GQUnits_Bz <- L$Year$Bzone$GQDU
  names(GQUnits_Bz) <- L$Year$Bzone$Bzone
  GQUnits_ls <-
    adjustHousingSupply(
      TotUnitDiff = UnitsDiff_Ht["GQ"],
      Units_Bz = GQUnits_Bz
    )
  rm(GQUnits_Bz)

  #Locate households
  #-----------------
  #Create a data frame of households and split by housing type
  HH_df <- data.frame(L$Year$Household, stringsAsFactors = FALSE)
  HH_ls <- split(HH_df, HH_df$HouseType)
  rm(HH_df)
  #Sort by households by income
  HH_ls <- lapply(HH_ls, function(x) x[rev(order(x$Income)),])
  #Create a named vector of Bzone weights
  Weights_Bz <- L$Year$Bzone$Weights
  names(Weights_Bz) <- L$Year$Bzone$Bzone
  #Assign SF households to Bzones
  SFHouseholdBzones_Hh <-
    chooseLocations(
      HH_ls$SF$HhId,
      SFUnits_ls$BalancedUnits_Bz,
      Weights_Bz)
  #Assign MF households to Bzones
  MFHouseholdBzones_Hh <-
    chooseLocations(
      HH_ls$MF$HhId,
      MFUnits_ls$BalancedUnits_Bz,
      Weights_Bz)
  #Assign GQ households to Bzones
  GQHouseholdBzones_Hh <-
    chooseLocations(
      HH_ls$GQ$HhId,
      GQUnits_ls$BalancedUnits_Bz,
      Weights_Bz / Weights_Bz
      )

  #Return list of results
  #----------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(Bzone = character(0))
  Out_ls$Year$Bzone <-
    list(SFDU = integer(0),
         MFDU = integer(0),
         GQDU = integer(0),
         SFDUadj = integer(0),
         MFDUadj = integer(0),
         GQDUadj = integer(0))
  #Combine assignmentments by housing type and put in correct order
  HhBzones_Hh <-
    c(SFHouseholdBzones_Hh,
      MFHouseholdBzones_Hh,
      GQHouseholdBzones_Hh)[L$Year$Household$HhId]
  #Add the household Bzone assignments to the list
  Out_ls$Year$Household$Bzone <- unname(HhBzones_Hh)
  #Add SIZE attribute for the
  attributes(Out_ls$Year$Household$Bzone)$SIZE <- max(nchar(HhBzones_Hh))
  #Add the revised dwelling unit numbers
  Out_ls$Year$Bzone$SFDU <- as.integer(unname(SFUnits_ls$BalancedUnits_Bz))
  Out_ls$Year$Bzone$MFDU <- as.integer(unname(MFUnits_ls$BalancedUnits_Bz))
  Out_ls$Year$Bzone$GQDU <- as.integer(unname(GQUnits_ls$BalancedUnits_Bz))
  #Add the dwelling unit adjustments made to create balanced units
  Out_ls$Year$Bzone$SFDUadj <- as.integer(unname(SFUnits_ls$AdjUnits_Bz))
  Out_ls$Year$Bzone$MFDUadj <- as.integer(unname(MFUnits_ls$AdjUnits_Bz))
  Out_ls$Year$Bzone$GQDUadj <- as.integer(unname(GQUnits_ls$AdjUnits_Bz))
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
#   ModuleName = "LocateHouseholds",
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
#   ModuleName = "LocateHouseholds",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
