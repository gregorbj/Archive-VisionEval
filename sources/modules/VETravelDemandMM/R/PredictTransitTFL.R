#================== PredictTransitTFL.R ==================
#
#This module predicts Transit trip frequency (TransitTrips) and average trip length
#(TransitAvgTripDist) for households. It uses the model object in
#data/TransitTFLModel_df.rda and variables and coefficients therein to predict.

#library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#See data-raw/TransitTFLModel_df.R

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#Define the data specifications
#------------------------------
PredictTransitTFLSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify input data
  Inp = items(),

  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items("HHSIZE",
              "WRKCOUNT",
              "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Income"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      #UNITS = "persons",   #?
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("CENSUS_R"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("TRPOPDEN"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      #UNITS = "persons",   #?
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("ZeroVeh"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      #UNITS = "persons",   #?
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),

  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "TransitTrips",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "trips",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "TripDistance_Transit",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "mile",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for PredictTransitTFL module
#'
#' A list containing specifications for the PredictTransitTFL module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
"PredictTransitTFLSpecifications"
devtools::use_data(PredictTransitTFLSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that predicts Transit Trip Frequency and Length for households
#------------------------------------------------------
#' Main module function
#'
#' \code{PredictTransitTFL} predicts Transit Trip Frequency and Length (TFL) for each
#' household in the households dataset using independent variables including
#' household characteristics and 5D built environment variables.
#'
#' This function predicts TransitTFL for each hosuehold in the model region where
#' each household is assigned an TransitTFL. The model objects as a part of the
#' inputs are stored in data frame with two columns: a column for segmentation
#' (e.g., metro, non-metro) and a 'model' column for model object (list-column
#' data structure). The function "nests" the households data frame into a
#' list-column data frame by segments and applies the generic predict() function
#' for each segment to predict TransitTFL for each household. The vectors of HhId
#' and TransitTFL produced by the PredictTransitTFL function are to be stored in the
#' "Household" table.
#'
#' If this table does not exist, the function calculates a LENGTH value for
#' the table and returns that as well. The framework uses this information to
#' initialize the Households table. The function also computes the maximum
#' numbers of characters in the HhId and Azone datasets and assigns these to a
#' SIZE vector. This is necessary so that the framework can initialize these
#' datasets in the datastore. All the results are returned in a list.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module along with:
#' LENGTH: A named integer vector having a single named element, "Household",
#' which identifies the length (number of rows) of the Household table to be
#' created in the datastore.
#' SIZE: A named integer vector having two elements. The first element, "Azone",
#' identifies the size of the longest Azone name. The second element, "HhId",
#' identifies the size of the longest HhId.
#' @import visioneval
#' @import tidyverse
#' @import pscl
#' @export
PredictTransitTFL <- function(L) {
  #TODO: get id_name from L or specification?
  dataset_name <- "Household"
  id_name <- "HhId"

  Bzone_df <- data.frame(L$Year[["Bzone"]])
  stopifnot("data.frame" %in% class(Bzone_df))

  Marea_df <- data.frame(L$Year[["Marea"]])
  stopifnot("data.frame" %in% class(Marea_df))

  D_df <- data.frame(L$Year[[dataset_name]])
  stopifnot("data.frame" %in% class(D_df))
  D_df <- D_df %>%
    mutate(LogIncome=log1p(Income),
           DrvAgePop=HhSize - Age0to14,
           VehPerDriver=ifelse(Drivers==0 || is.na(Drivers), 0, Vehicles/Drivers),
           LifeCycle = as.character(LifeCycle),
           LifeCycle = ifelse(LifeCycle=="01", "Single", LifeCycle),
           LifeCycle = ifelse(LifeCycle %in% c("02"), "Couple w/o children", LifeCycle),
           LifeCycle = ifelse(LifeCycle %in% c("00", "03", "04", "05", "06", "07", "08"), "Couple w/ children", LifeCycle),
           LifeCycle = ifelse(LifeCycle %in% c("09", "10"), "Empty Nester", LifeCycle)
    ) %>%
    left_join(Bzone_df, by="Bzone") %>%
    crossing(Marea_df)

  #D_df <- D_df %>%
  #  crossing(Marea_df, by="Marea")

  #load("data/TransitTFLModel_df.rda")
  Model_df <- TransitTFLModel_df

  # find cols used for segmenting households ("metro" by default)
  SegmentCol_vc <- setdiff(names(Model_df), c("model", "step", "post_func", "bias_adj"))

  # segmenting columns must appear in D_df
  stopifnot(all(SegmentCol_vc %in% names(D_df)))

  Preds <- DoPredictions(Model_df, D_df,
                         dataset_name, id_name, y_name, SegmentCol_vc, combine_preds=FALSE)

  # fill NA with 0s - produced with negative predictions before inversing power transformation
  Preds <- Preds %>%
    mutate(y=ifelse(is.na(y) | y < 0, 0, y))

  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      TransitTrips = -1,
      TransitAvgTripDist = -1
    )
  Out_ls$Year$Household$TransitTrips       <- Preds %>% filter(step==1) %>% pull(y)
  Out_ls$Year$Household$TransitAvgTripDist <- Preds %>% filter(step==2) %>% pull(y)

  #Return the list
  Out_ls
}

#====================
#SECTION 4: TEST CODE
#====================
# model test code is in tests/scripts/test.R
