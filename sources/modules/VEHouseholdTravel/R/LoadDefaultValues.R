#===================
#LoadDefaultValues.R
#===================
#This module processes default carbon intensity of electricity consumption
#for all counties


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
library(visioneval)


#============================================================
#READ IN AND PROCESS DEFAULT VEHICLE AND FUEL CHARACTERISTICS
#============================================================
#Default vehicle, fuel, and carbon intensity assumptions

TravelDemandDefaults_ls <- list()

#----------------
#Carbon intensity
#----------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "State",
    TYPE = "character",
    PROHIBIT = c("NA"),
    ISELEMENTOF = c(
      "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI",
      "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI",
      "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC",
      "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT",
      "VT", "VA", "WA", "WV", "WI", "WY", "DC", "PR", "NA"),
    UNLIKELY = "",
    TOTAL = "",
    DESCRIPTION =
      "Postal code abbreviation of state where the region is located"
  ),
  item(
    NAME = "County",
    TYPE = "character",
    PROHIBIT = c("NA"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = "",
    DESCRIPTION =
      "Name of the county where the region is located"
  ),
  item(
    NAME =
      items("X1990",
            "X1995",
            "X2000",
            "X2005",
            "X2010",
            "X2015",
            "X2020",
            "X2025",
            "X2030",
            "X2035",
            "X2040",
            "X2045",
            "X2050"),
    TYPE = "compound",
    UNITS = "LB/KWH",
    PROHIBIT = c("< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = "",
    DESCRIPTION =
      "The year for which the carbon intensities are calculated"
  )
)
#Load and process data
CarbonIntensity_df <-
  processEstimationInputs(
    Inp_ls,
    "power_co2.csv",
    "LoadDefaultValues.R")
#Add to TravelDemandDefaults_ls and clean up
TravelDemandDefaults_ls$CarbonIntensity_df <- CarbonIntensity_df
rm(Inp_ls, CarbonIntensity_df)

#==========================================================
#DOCUMENT AND SAVE DEFAULT VEHICLE AND FUEL CHARACTERISTICS
#==========================================================

#' Default energy and emissions data
#'
#' A list of dataset containing default assumptions about electricity
#' carbon intensities.
#'
#' @format A list containing 17 data frames:
#' \describe{
#'   \item{CarbonIntensity_df}{a data frame of the carbon intensities of vehicle energy sources by year}
#'     \item{State}{Postal code abbreviation of state where the region is located}
#'     \item{County}{Name of the county where the region is located}
#'     \item{Year}{The year for which the carbon intensities are calculated}
#' }
#' @source LoadDefaultValues.R script.
"TravelDemandDefaults_ls"
usethis::use_data(TravelDemandDefaults_ls, overwrite = TRUE)
