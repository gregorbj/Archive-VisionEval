#================ PredictBikePMT.R ================

#This module predicts BikePMT for households. It uses the model object in
#data/BikePMTModel_df.rda and variables and coefficients therein to predict
#BikePMT.

#library(visioneval)
#library(tidyverse)
#library(splines)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#See data-raw/BikePMTModel_df.R

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
PredictBikePMTSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  ##Specify input data
  #Inp = items(
    # item(
    #   NAME = "CENSUS_R",
    #   FILE = "marea_census_r.csv",
    #   TABLE = "Marea",
    #   GROUP = "Year",
    #   TYPE = "character",
    #   UNITS = "category",
    #   PROHIBIT = "",
    #   ISELEMENTOF = c("NE", "S", "W", "MW"),
    #   SIZE = 2
    # ),
  #   item(
  #     NAME = "metro",
  #     FILE = "marea_metro.csv",
  #     TABLE = "Marea",
  #     GROUP = "Year",
  #     TYPE = "character",
  #     UNITS = "category",
  #     PROHIBIT = "",
  #     ISELEMENTOF = c("metro", "non_metro"),
  #     SIZE = 9
  #   )
  # ),
  #Specify data to be loaded from data store
  Get = items(
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
      NAME ="AADVMT",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("HhSize",
              "Workers",
              "Drivers",
              "Age0to14",
              "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2009",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "LifeCycle",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c("00", "01", "02", "03", "04", "09", "10"),
      SIZE = 2
    ),
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D1B",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "D2A_WRKEMP",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/JOB",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "D2A_EPHHM",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "employment & household entropy",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "D3bpo4",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "pedestrian-oriented intersections per square mile",
      NAVALUE = -9999,
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D4c",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "aggregate peak period transit service",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "D5",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "metro",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("metro", "non_metro"),
      SIZE = 9
    ),
    item(
      NAME = "CENSUS_R",
      #FILE = "marea_census_r.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("NE", "S", "W", "MW"),
      SIZE = 2
    ),
    item(
      NAME = "FwyLaneMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "TranRevMiPC",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  ),

  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "BikePMT",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for PredictBikePMT module
#'
#' A list containing specifications for the PredictBikePMT module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
"PredictBikePMTSpecifications"
devtools::use_data(PredictBikePMTSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function that predicts BikePMT for households
#------------------------------------------------------
#' Main module function
#'
#' \code{PredictBikePMT} predicts BikePMT for each household in the households
#' dataset using independent variables including household characteristics
#' and 5D built environment variables.
#'
#' This function predicts BikePMT for each hosuehold in the model region where
#' each household is assigned an BikePMT. The model objects as a part of the
#' inputs are stored in data frame with two columns: a column for segmentation
#' (e.g., metro, non-metro) and a 'model' column for model object (list-column
#' data structure). The function "nests" the households data frame into a
#' list-column data frame by segments and applies the generic predict() function
#' for each segment to predict BikePMT for each household. The vectors of HhId
#' and BikePMT produced by the PredictBikePMT function are to be stored in the
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
PredictBikePMT <- function(L) {
  #TODO: get id_name from L or specification?
  dataset_name <- "Household"
  id_name <- "HhId"
  y_name <- "BikePMT"

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

  #load("data/BikePMTModel_df.rda")
  Model_df <- BikePMTModel_df

  # find cols used for segmenting households ("metro" by default)
  SegmentCol_vc <- setdiff(names(Model_df), c("model", "step", "post_func", "bias_adj"))

  # segmenting columns must appear in D_df
  stopifnot(all(SegmentCol_vc %in% names(D_df)))

  Preds <- DoPredictions(Model_df, D_df,
                 dataset_name, id_name, y_name, SegmentCol_vc)

  # fill NA with 0s - produced with negative predictions before inversing power transformation
  Preds <- Preds %>%
    mutate(y=ifelse(is.na(y) | y < 0, 0, y))

  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      BikePMT = -1
    )
  Out_ls$Year$Household$BikePMT <- Preds[["y"]]

  #Return the list
  Out_ls
}

#====================
#SECTION 4: TEST CODE
#====================
# model test code is in tests/scripts/test.R
