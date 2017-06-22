#==========================
#CalculateUrbanMixMeasure.R
#==========================
#This module calculates an urban mixed-use measure based on the 2001 National
#Household Travel Survey measure of the tract level urban/rural indicator. This
#measure developed by Claritas uses the density of the tract and surrounding
#tracts to identify the urban/rural context of the tract. The categories include
#urban, suburban, second city, town and rural. Mapping of example metropolitan
#areas shows that places shown as urban correspond to central city and inner
#neighborhoods characterized by mixed use, higher levels of urban accessibility,
#and higher levels of walk/bike/transit accessibility.

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

#Define a function to estimate urban mixed-use model
#---------------------------------------------------
#' Estimate urban mixed-use model
#'
#' \code{estimateUrbanMixModel} estimates a binomial logit model for identifying
#' whether a household lives in an urban mixed-use neighborhood.
#'
#' This function estimates a binomial logit model for predicting whether a
#' household is living in an urban mixed-use neighborhood.
#'
#' @param Data_df A data frame containing estimation data.
#' @param StartTerms_ A character vector of the terms of the model to be
#' tested in the model. The function estimates the model using these terms
#' and then drops all terms whose p value is greater than 0.05.
#' @return A list which has the following components:
#' Type: a string identifying the type of model ("binomial"),
#' Formula: a string representation of the model equation,
#' PrepFun: a function that prepares inputs to be applied in the binomial model,
#' OutFun: a function that transforms the result of applying the binomial model.
#' Summary: the summary of the binomial model estimation results.
#' @import visioneval
estimateUrbanMixModel <- function(EstData_df, StartTerms_) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <-
    function(In_df) {
      Out_df <- In_df
      Out_df$Intercept <- 1
      Out_df
    }
  #Define function to make the model formula
  makeFormula <-
    function(StartTerms_) {
      FormulaString <-
        paste("UrbanMix ~ ", paste(StartTerms_, collapse = "+"))
      as.formula(FormulaString)
    }
  #Estimate model
  UrbanMixModel <-
    glm(makeFormula(StartTerms_), family = binomial, data = EstData_df)
  #Return model
  list(
    Type = "binomial",
    Formula = makeModelFormulaString(UrbanMixModel),
    Choices = c(1, 0),
    PrepFun = prepIndepVar,
    Summary = summary(UrbanMixModel)
  )
}

#Estimate the binomial logit model for urban mixed-use
#-----------------------------------------------------
#Create model estimation dataset
Data_df <-
  data.frame(
    UrbanMix = VE2001NHTS::Hh_df$Urban,
    LocalPopDensity = VE2001NHTS::Hh_df$Hbppopdn)
Data_df <- Data_df[!is.na(Data_df$LocalPopDensity),]
#Estimate the model
UrbanMixModel_ls <-
  estimateUrbanMixModel(
    EstData_df = Data_df,
    StartTerms_ = "LocalPopDensity"
  )
#Test a search range for matching proportions
UrbanMixModel_ls$SearchRange <- c(-10, 10)
applyBinomialModel(
  UrbanMixModel_ls,
  Data_df,
  TargetProp = NULL,
  CheckTargetSearchRange = TRUE)
#Check that low target can be matched with search range
Target <- 0.01
LowResult_ <- applyBinomialModel(
  UrbanMixModel_ls,
  Data_df,
  TargetProp = Target
)
Result <- round(table(LowResult_) / length(LowResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, LowResult_, Result)
#Check that high target can be matched with search range
Target <- 0.99
HighResult_ <- applyBinomialModel(
  UrbanMixModel_ls,
  Data_df,
  TargetProp = Target
)
Result <- round(table(HighResult_) / length(HighResult_), 2)
paste("Target =", Target, "&", "Result =", Result[2])
rm(Target, HighResult_, Result)
rm(Data_df)

#Save the urban mixed-use model
#------------------------------
#' Urban mixed-use model
#'
#' A list containing the model equation and other information needed to
#' implement the urban mixed-use model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Type}{a string identifying the type of model ("binomial")}
#'   \item{Formula}{makeModelFormulaString(UrbanMixModel)}
#'   \item{PrepFun}{a function that prepares inputs to be applied in the model}
#'   \item{Summary}{the summary of the binomial logit model estimation results}
#'   \item{SearchRange}{a two-element vector specifying the range of search values}
#' }
#' @source CalculateUrbanMixMeasure.R script.
"UrbanMixModel_ls"
devtools::use_data(UrbanMixModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateUrbanMixMeasureSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Bzone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "MixUseProp",
      FILE = "bzone_urban-mixed-use_prop.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
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
          "UrbanPop",
          "RuralPop"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "UrbanArea",
          "RuralArea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "SQMI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "IsUrbanMixNbrhd",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c(0, 1),
      SIZE = 1
    )
  )
)


#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateUrbanMixMeasure module
#'
#' A list containing specifications for the Calculate4DMeasures module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source Calculate4DMeasures.R script.
"Calculate4DMeasuresSpecifications"
devtools::use_data(Calculate4DMeasuresSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module calculates several 4D measures by Bzone including density,
#diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#and destination accessibility.

#Function to sum values for block groups within specified distances
#-----------------------------------------------------------------
#' Sum values for block groups within specified distances
#'
#' \code{sumValsInDist} sums specified values for block groups whose centroids
#' are located within a specified distance cutoff.
#'
#' This function sums for each block group, a set of block group values of
#' all the block groups whose centroids are within the specified distance of
#' the the block group.
#'
#' @param DistCutoff A numeric value in miles specifying the straight line
#' distance in miles to use as the distance threshold.
#' @param DataToSum_ A numeric vector of the block group values to sum
#' corresponding to all Bzones.
#' @param Lat_ A numeric vector of the latitudes of the block group centroids
#' in the same order as DataToSum_.
#' @param Lng_ A numeric vector of the longitudes of the block group centroids
#' in the same order as DataToSum_.
#' @return A numeric vector of the sums of the values in DataToSum_ for block
#' groups within the DistanceCutoff of each Bzone.
#' @import geosphere
#' @import fields
sumValsInDist <- function(DistCutoff, DataToSum_, Lat_, Lng_){
  #Number of Bzones
  NumBzone <- length(DataToSum_)
  #Matrix centroid coordinates
  Coord_mx <- cbind(lng = Lng_, lat = Lat_)
  #Calculate longitude and latitude ranges corresponding to the maximum distance
  BufferDist <- DistCutoff * 1609.34  #Maximum distance in meters
  North <- 0
  South <- -180
  East <- 90
  West <- -90
  MinLng_ <- geosphere::destPoint(Coord_mx, West, BufferDist)[,1]
  MaxLng_ <- geosphere::destPoint(Coord_mx, East, BufferDist)[,1]
  MinLat_ <- geosphere::destPoint(Coord_mx, South, BufferDist)[,2]
  MaxLat_ <- geosphere::destPoint(Coord_mx, North, BufferDist)[,2]
  #Define function to sum values for Bzones whose centroids are within the
  #specified distance cutoff of a Bzone specified by it's position in the inputs
  sumValsInDist <- function(BzonePos) {
    Idx_ <- which(
      (Lat_ > MinLat_[BzonePos]) &
      (Lat_ < MaxLat_[BzonePos]) &
      (Lng_ > MinLng_[BzonePos]) &
      (Lng_ < MaxLng_[BzonePos])
    )
    DestLngLat_df <-
      data.frame(lng = Lng_[Idx_], lat = Lat_[Idx_])
    OrigLngLat_df <-
      data.frame(lng = Lng_[BzonePos], lat = Lat_[BzonePos])
    Dist_ <-
      fields::rdist.earth(DestLngLat_df, OrigLngLat_df, miles = TRUE, R = 6371)
    Data_ <- DataToSum_[Idx_]
    sum(Data_[Dist_ <= DistCutoff])
  }
  #Iterate through the Bzones and calculate the values
  Sums_ <- numeric(NumBzone)
  for (i in 1:NumBzone) {
    Sums_[i] <- sumValsInDist(i)
  }
  #Return the result
  Sums_
}

#Main module function that calculates 4D measures
#------------------------------------------------
#' Main module function that calculates 4D measures for each Bzone.
#'
#' \code{Calculate4DMeasures} calculates 4D measures for each Bzone.
#'
#' This module calculates several 4D measures by Bzone including density,
#' diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#' and destination accessibility.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
Calculate4DMeasures <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define a vector of Bzones
  Bz <- L$Year$Bzone$Bzone
  #Create data frame of Bzone data
  D_df <- data.frame(L$Year$Bzone)
  D_df$Area <- D_df$UrbanArea + D_df$RuralArea

  #Calculate density measures
  #--------------------------
  #Population density
  D1B_ <- with(D_df, Pop / Area)
  #Employment density
  D1C_ <- with(D_df, TotEmp / Area)
  #Activity density
  D1D_ <- with(D_df, (TotEmp + NumHh) / Area)

  #Calculate diversity measures
  #----------------------------
  #Ratio of employment to households
  D2A_JPHH_ <- with(D_df, TotEmp / NumHh)
  #Ratio of workers to employment
  D2A_WRKEMP_ <- with(D_df, NumWkr / TotEmp)
  #Employment and household entropy
  D_df$OthEmp <- with(D_df, TotEmp - RetEmp - SvcEmp)
  D_df$TotAct <- with(D_df, TotEmp + NumHh)
  calcEntropyTerm <- function(ActName) {
    Act_ <- D_df[[ActName]]
    ActRatio_ <- Act_ / D_df$TotAct
    LogActRatio_ <- ActRatio_ * 0
    LogActRatio_[Act_ != 0] <- log(Act_[Act_ != 0] / D_df$TotAct[Act_ != 0])
    ActRatio_ * LogActRatio_
  }
  E_df <- data.frame(
    Hh = calcEntropyTerm("NumHh"),
    Ret = calcEntropyTerm("RetEmp"),
    Svc = calcEntropyTerm("SvcEmp"),
    Oth = calcEntropyTerm("OthEmp")
  )
  A_ <- rowSums(E_df)
  N_ = apply(E_df, 1, function(x) sum(x != 0))
  D2A_EPHHM_ <- -A_ / log(N_)
  rm(E_df, A_, N_)

  #Calculate destination accessibilty term
  #---------------------------------------
  #Calculate employment within 2 miles
  EmpIn2Mi_ <-
    sumValsInDist(DistCutoff = 2,
                  DataToSum_ = D_df$TotEmp,
                  Lat_ = D_df$Latitude ,
                  Lng_ = D_df$Longitude)
  #Calculate population within 5 miles
  PopIn5Mi_ <-
    sumValsInDist(DistCutoff = 5,
                  DataToSum_ = D_df$Pop,
                  Lat_ = D_df$Latitude ,
                  Lng_ = D_df$Longitude)
  #Calculate regional destination access measure using harmonic mean
  D5_ <- 2 * EmpIn2Mi_ * PopIn5Mi_ / (EmpIn2Mi_ + PopIn5Mi_)

  #Return list of results
  #----------------------
  #Initialize list
  Out_ls <- initDataList()
  #Populate with results
  Out_ls$Year$Bzone <- list(
    D1B = D1B_,
    D1C = D1C_,
    D1D = D1D_,
    D2A_JPHH = D2A_JPHH_,
    D2A_WRKEMP = D2A_WRKEMP_,
    D2A_EPHHM = D2A_EPHHM_,
    D5 = D5_
  )
  #Return the results
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
#   ModuleName = "Calculate4DMeasures",
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
#   ModuleName = "Calculate4DMeasures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
