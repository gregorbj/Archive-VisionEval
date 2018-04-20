#================ PredictVehicles.R ================

#This module predicts Vehicles for households. It uses the model object in
#data/VehiclesModel_df.rda (ordered logit model by default) and variables and
#coefficients therein to predict Vehicles.

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#See data-raw/VehiclesModel_df.R

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
PredictVehiclesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items("Age0to14",
              "HhSize",
              "Workers"),
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
      UNITS = "USD.1999",
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
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Azone",
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
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of vehicles owned by the household"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for PredictVehicles module
#'
#' A list containing specifications for the PredictVehicles module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
"PredictVehiclesSpecifications"
devtools::use_data(PredictVehiclesSpecifications, overwrite = TRUE)
rm(PredictVehiclesSpecifications)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#This function predicts the number of Vehicles in each
#household and tallies the total number of Vehicles in the household. It uses
#the model specification in data/VehiclesModel_df.rda

#Main module function that predicts Vehicles by age for each household
#--------------------------------------------------------------------
#' Main module function to predict Vehicles for each household
#'
#' \code{PredictVehicles} predicts the number of Vehicles for each
#' household and tallies the total number of Vehicles for each household.
#'
#' This function predicts the number of Vehicles for each household. It uses
#the model specification in data/VehiclesModel_df.rda
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @import tidyverse
#' @importFrom MASS polr
#' @export
PredictVehicles <- function(L) {
  dataset_name <- "Household"
  id_name <- "HhId"
  y_name <- "Vehicles"

  D_df <- data.frame(L$Year[[dataset_name]])
  stopifnot("data.frame" %in% class(D_df))

  D_df <- D_df %>%
    mutate(LogIncome=log1p(Income),
           DrvAgePop=HhSize - Age0to14,
           LifeCycle = as.character(LifeCycle),
           LifeCycle = ifelse(LifeCycle=="01", "Single", LifeCycle),
           LifeCycle = ifelse(LifeCycle %in% c("02"), "Couple w/o children", LifeCycle),
           LifeCycle = ifelse(LifeCycle %in% c("00", "03", "04", "05", "06", "07", "08"), "Couple w/ children", LifeCycle),
           LifeCycle = ifelse(LifeCycle %in% c("09", "10"), "Empty Nester", LifeCycle)
           )

  #load("data/VehiclesModel_df.rda")
  Preds_lcdf <- VehiclesModel_df

  Preds_lcdf$data <- list(D_df)

  Preds_lcdf <- Preds_lcdf %>%
    mutate(y = map2(model, data, ~predict(.x, .y)))

  # call post_func(y) if post_func column exists
  if ("post_func" %in% names(Preds_lcdf)) {
    Preds_lcdf <- Preds_lcdf %>%
      mutate(y=map2(y, post_func, `.y(.x)`))
  }

  if ("bias_adj" %in% names(Preds_lcdf)) {
    Preds_lcdf <- Preds_lcdf %>%
      mutate(y=map2(y, bias_adj, `*`))
  }

  Preds_df <- Preds_lcdf %>%
    mutate(id=map(data, id_name)) %>%
    unnest(id, y)

  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      Vehicles = -1
  )
  Out_ls$Year$Household$Vehicles <- Preds_df[["y"]]

  #Return the list
  Out_ls
}


#====================
#SECTION 4: TEST CODE
#====================
# model test code is in tests/scripts/test.R
