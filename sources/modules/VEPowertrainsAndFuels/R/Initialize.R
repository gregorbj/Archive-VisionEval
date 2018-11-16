#============
#Initialize.R
#============
# This module processes optional vehicle and fuel characteristics files that
# model users my optionally supply. When these files are supplied, modules in
# the package that compute carbon intensities of vehicle travel will use the
# user- supplied data instead of the datasets that are part of the package (see
# the LoadDefaultValues.R script). The optional user inputs include:
# 1) Average carbon intensity of electricity by Azone
# 2) Average carbon intensities of transit fuels by transit vehicle type
# 3) Biofuels proportions of transit fuels
# 4) Transit fuels proportions by transit vehicle type and Marea
# 5) Transit powertrain proportions by transit vehicle type and Marea
# 6) Average carbon intensities of fuels by vehicle category
# 7) Car service vehicle powertrain proportions by vehicle type
# 8) Commercial service vehicle powertrain proportions by vehicle type
# 9) Heavy duty truck powertrain proportions
# If one or more of the powertrain or fuel proportions datasets are present, the
# module evaluates each of the proportions datasets to make sure that totals for
# a vehicle type add up to 1. If any total diverges by more than 1%, then the
# module returns an error message. If any total is not exactly 1 but is off by
# 1% or less, then the module adjusts the proportions to exactly equal 1 and
# returns a warning message.

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no estimated parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
InitializeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "ElectricityCI",
      FILE = "azone_electricity_carbon_intensity.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Carbon intensity of electricity at point of consumption (grams CO2e per megajoule)",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      FILE = "marea_transit_ave_fuel_carbon_intensity.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuel used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit rail vehicles (grams CO2e per megajoule)"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitEthanolPropGasoline",
          "TransitBiodieselPropDiesel",
          "TransitRngPropCng"
        ),
      FILE = "marea_transit_biofuel_mix.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Ethanol proportion of gasoline used by transit vehicles",
          "Biodiesel proportion of diesel used by transit vehicles",
          "Renewable natural gas proportion of compressed natural gas used by transit vehicles"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropDiesel",
          "VanPropGasoline",
          "VanPropCng",
          "BusPropDiesel",
          "BusPropGasoline",
          "BusPropCng",
          "RailPropDiesel",
          "RailPropGasoline"
        ),
      FILE = "marea_transit_fuel.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of non-electric transit van travel powered by diesel",
          "Proportion of non-electric transit van travel powered by gasoline",
          "Proportion of non-electric transit van travel powered by compressed natural gas",
          "Proportion of non-electric transit bus travel powered by diesel",
          "Proportion of non-electric transit bus travel powered by gasoline",
          "Proportion of non-electric transit bus travel powered by compressed natural gas",
          "Proportion of non-electric transit rail travel powered by diesel",
          "Proportion of non-electric transit rail travel powered by gasoline"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropIcev",
          "VanPropHev",
          "VanPropBev",
          "BusPropIcev",
          "BusPropHev",
          "BusPropBev",
          "RailPropIcev",
          "RailPropHev",
          "RailPropEv"
        ),
      FILE = "marea_transit_powertrain_prop.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of transit van travel using internal combustion engine powertrains",
          "Proportion of transit van travel using hybrid electric powertrains",
          "Proportion of transit van travel using battery electric powertrains",
          "Proportion of transit bus travel using internal combustion engine powertrains",
          "Proportion of transit bus travel using hybrid electric powertrains",
          "Proportion of transit bus travel using battery electric powertrains",
          "Proportion of transit rail travel using internal combustion engine powertrains",
          "Proportion of transit rail travel using hybrid electric powertrains",
          "Proportion of transit rail travel using electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HhFuelCI",
          "CarSvcFuelCI",
          "ComSvcFuelCI",
          "HvyTrkFuelCI",
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      FILE = "region_ave_fuel_carbon_intensity.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuels used by household vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by car service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by commercial service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit rail vehicles (grams CO2e per megajoule)"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "CarSvcAutoPropIcev",
          "CarSvcAutoPropHev",
          "CarSvcAutoPropBev",
          "CarSvcLtTrkPropIcev",
          "CarSvcLtTrkPropHev",
          "CarSvcLtTrkPropBev"
        ),
      FILE = "region_carsvc_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of car service automobile travel powered by internal combustion engine powertrains",
          "Proportion of car service automobile travel powered by hybrid electric powertrains",
          "Proportion of car service automobile travel powered by battery electric powertrains",
          "Proportion of car service light truck travel powered by internal combustion engine powertrains",
          "Proportion of car service light truck travel powered by hybrid electric powertrains",
          "Proportion of car service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "ComSvcAutoPropIcev",
          "ComSvcAutoPropHev",
          "ComSvcAutoPropBev",
          "ComSvcLtTrkPropIcev",
          "ComSvcLtTrkPropHev",
          "ComSvcLtTrkPropBev"
        ),
      FILE = "region_comsvc_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of commercial service automobile travel powered by internal combustion engine powertrains",
          "Proportion of commercial service automobile travel powered by hybrid electric powertrains",
          "Proportion of commercial service automobile travel powered by battery electric powertrains",
          "Proportion of commercial service light truck travel powered by internal combustion engine powertrains",
          "Proportion of commercial service light truck travel powered by hybrid electric powertrains",
          "Proportion of commercial service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HvyTrkPropIcev",
          "HvyTrkPropHev",
          "HvyTrkPropBev"
        ),
      FILE = "region_hvytrk_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of heavy truck travel powered by internal combustion engine powertrains",
          "Proportion of heavy truck travel powered by hybrid electric powertrains",
          "Proportion of heavy truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for Initialize module
#'
#' A list containing specifications for the Initialize module.
#'
#' @format A list containing 5 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{RunFor}{options = AllYears, BaseYear, NoBaseYear}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source Initialize.R script.
"InitializeSpecifications"
usethis::use_data(InitializeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Main function processes optional user energy and emissions inputs that have
#been preprocessed by the processModuleInputs function. The Initialize function
#checks datasets that specify fuel type or powertrain type proportions to
#determine whether they sum to 1. If the sum for a dataset differs from 1 by
#more than 1%, then the function returns an error message identifying the
#problem dataset. If the sum differs from 1 but the difference is 1% or less
#it is assumed that the difference is due to rounding errors and function
#adjusts the proportions so that they equal 1. In this case, a warning message
#is returned as well that the framework will write to the log.

#Main module function that checks and adjusts optional proportions inputs
#------------------------------------------------------------------------
#' Check and adjust fuel and powertrain proportions inputs.
#'
#' \code{Initialize} checks optional fuel and powertrains proportions datasets
#' to determine whether they each sum to 1, creates error and warning messages,
#' and makes adjustments if necessary.
#'
#' This function processes optional user energy and emissions inputs that have
#' been preprocessed by the processModuleInputs function. It checks datasets
#' that specify fuel type or powertrain type proportions to determine whether
#' they sum to 1. If the sum for a dataset differs from 1 by more than 1%, then
#' the function returns an error message identifying the problem dataset. If the
#' sum differs from 1 but the difference is 1% or less it is assumed that the
#' difference is due to rounding errors and function adjusts the proportions so
#' that they equal 1. In this case, a warning message is returned as well that
#' the framework will write to the log.
#'
#' @param L A list containing data from preprocessing supplied optional input
#' files returned by the processModuleInputs function. This list has two
#' components: Errors and Data.
#' @return A list that is the same as the input list with an additional
#' Warnings component.
#' @name Initialize
#' @import visioneval
#' @export
Initialize <- function(L) {
  #Set up
  #------
  #Initialize error and warnings message vectors
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Initialize output list with input values
  Out_ls <- L
  #Define function to check for NA values
  checkNA <- function(Names_, Geo) {
    Values_ls <- L$Data$Year[[Geo]][Names_]
    AllNA <- all(is.na(unlist(Values_ls)))
    AnyNA <- any(is.na(unlist(Values_ls)))
    NoNA <- !AnyNA
    SomeNotAllNA <- AnyNA & !AllNA
    list(None = NoNA, SomeNotAll = SomeNotAllNA)
  }
  #Define function to check and adjust proportions
  checkProps <- function(Names_, Geo) {
    Values_ls <- L$Data$Year[[Geo]][Names_]
    #If more than one year, then need to evaluate multiple values
    if (length(Values_ls[[1]]) > 1) {
      Values_mx <- do.call(cbind, Values_ls)
      SumDiff_ <- abs(1 - rowSums(Values_mx))
      if (any(SumDiff_ > 0.01)) {
        Msg <- paste0(
          "Error in input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of values for a year is off by more than 1%. ",
          "They should add up to 1."
        )
        Errors_ <<- c(Errors_, Msg)
      }
      if (any(SumDiff_ > 0 & SumDiff_ < 0.01)) {
        Msg <- paste0(
          "Warning regarding input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of the values for a year do not add up to 1 ",
          "but are off by 1% or less so they have been adjusted to add up to 1."
        )
        Warnings_ <<- c(Warnings_, Msg)
        Values_mx <- sweep(Values_mx, 1, rowSums(Values_mx), "/")
        for (nm in colnames(Values_mx)) {
          Values_ls[[nm]] <- Values_mx[,nm]
        }
      }
    #Otherwise only need to evaluate single values
    } else {
      Values_ <- unlist(Values_ls)
      SumDiff <- abs(1 - sum(Values_))
      if (SumDiff > 0.01) {
        Msg <- paste0(
          "Error in input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of these values is off by more than 1%. ",
          "They should add up to 1."
        )
        Errors_ <<- c(Errors_, Msg)
      }
      if (SumDiff > 0 & SumDiff < 0.01) {
        Msg <- paste0(
          "Warning regarding input values for ",
          paste(Names_, collapse = ", "),
          ". The sum of these values do not add up to 1 ",
          "but are off by 1% or less so they have been adjusted to add up to 1."
        )
        Warnings_ <<- c(Warnings_, Msg)
        Values_ <- Values_ / sum(Values_)
        for (nm in names(Values_)) {
          Values_ls[[nm]] <- Values_[nm]
        }
      }
    }
    Values_ls
  }

  #Check and adjust car service vehicle powertrain proportions
  #-----------------------------------------------------------
  Names_ <- c("CarSvcAutoPropIcev", "CarSvcAutoPropHev", "CarSvcAutoPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Region))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Region")
  } else {
    Msg <- paste0(
      "region_carsvc_powertrain_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }
  Names_ <- c("CarSvcLtTrkPropIcev", "CarSvcLtTrkPropHev", "CarSvcLtTrkPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Region))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Region")
  } else {
    Msg <- paste0(
      "region_carsvc_powertrain_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check and adjust commercial service vehicle powertrain proportions
  #------------------------------------------------------------------
  Names_ <- c("ComSvcAutoPropIcev", "ComSvcAutoPropHev", "ComSvcAutoPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Region))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Region")
  } else {
    Msg <- paste0(
      "region_comsvc_powertrain_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }
  Names_ <- c("ComSvcLtTrkPropIcev", "ComSvcLtTrkPropHev", "ComSvcLtTrkPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Region))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Region")
  } else {
    Msg <- paste0(
      "region_comsvc_powertrain_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check heavy truck powertrain proportions
  #----------------------------------------
  Names_ <- c("HvyTrkPropIcev", "HvyTrkPropHev", "HvyTrkPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Region))) {
    Out_ls$Data$Year$Region[Names_] <- checkProps(Names_, "Region")
  } else {
    Msg <- paste0(
      "region_hvytrk_powertrain_prop.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check transit van fuel proportions
  #----------------------------------
  Names_ <- c("VanPropDiesel", "VanPropGasoline", "VanPropCng")
  if (all(Names_ %in% names(Out_ls$Data$Year$Marea))) {
    HasNA <- checkNA(Names_, "Marea")
    if (HasNA$None) {
      Out_ls$Data$Year$Marea[Names_] <- checkProps(Names_, "Marea")
    }
    if (HasNA$SomeNotAll) {
      Msg <- paste0(
        "The 'Van' fields in the marea_transit_fuel.csv input file ",
        "are not complete. They must all have data values, or all must be NA."
      )
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <- paste0(
      "marea_transit_fuel.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check transit bus fuel proportions
  #----------------------------------
  Names_ <- c("BusPropDiesel", "BusPropGasoline", "BusPropCng")
  if (all(Names_ %in% names(Out_ls$Data$Year$Marea))) {
    HasNA <- checkNA(Names_, "Marea")
    if (HasNA$None) {
      Out_ls$Data$Year$Marea[Names_] <- checkProps(Names_, "Marea")
    }
    if (HasNA$SomeNotAll) {
      Msg <- paste0(
        "The 'Bus' fields in the marea_transit_fuel.csv input file ",
        "are not complete. They must all have data values, or all must be NA."
      )
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <- paste0(
      "marea_transit_fuel.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check transit rail fuel proportions
  #-----------------------------------
  Names_ <- c("RailPropDiesel", "RailPropGasoline")
  if (all(Names_ %in% names(Out_ls$Data$Year$Marea))) {
    HasNA <- checkNA(Names_, "Marea")
    if (HasNA$None) {
      Out_ls$Data$Year$Marea[Names_] <- checkProps(Names_, "Marea")
    }
    if (HasNA$SomeNotAll) {
      Msg <- paste0(
        "The 'Rail' fields in the marea_transit_fuel.csv input file ",
        "are not complete. They must all have data values, or all must be NA."
      )
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <- paste0(
      "marea_transit_fuel.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check transit van powertrain proportions
  #----------------------------------------
  Names_ <- c("VanPropIcev", "VanPropHev", "VanPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Marea))) {
    HasNA <- checkNA(Names_, "Marea")
    if (HasNA$None) {
      Out_ls$Data$Year$Marea[Names_] <- checkProps(Names_, "Marea")
    }
    if (HasNA$SomeNotAll) {
      Msg <- paste0(
        "The 'Van' fields in the marea_transit_powertrain_prop.csv input file ",
        "are not complete. They must all have data values, or all must be NA."
      )
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <- paste0(
      "marea_transit_fuel.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check transit bus powertrain proportions
  #----------------------------------------
  Names_ <- c("BusPropIcev", "BusPropHev", "BusPropBev")
  if (all(Names_ %in% names(Out_ls$Data$Year$Marea))) {
    HasNA <- checkNA(Names_, "Marea")
    if (HasNA$None) {
      Out_ls$Data$Year$Marea[Names_] <- checkProps(Names_, "Marea")
    }
    if (HasNA$SomeNotAll) {
      Msg <- paste0(
        "The 'Bus' fields in the marea_transit_powertrain_prop.csv input file ",
        "are not complete. They must all have data values, or all must be NA."
      )
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <- paste0(
      "marea_transit_fuel.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Check transit rail powertrain proportions
  #-----------------------------------------
  Names_ <- c("RailPropIcev", "RailPropHev", "RailPropEv")
  if (all(Names_ %in% names(Out_ls$Data$Year$Marea))) {
    HasNA <- checkNA(Names_, "Marea")
    if (HasNA$None) {
      Out_ls$Data$Year$Marea[Names_] <- checkProps(Names_, "Marea")
    }
    if (HasNA$SomeNotAll) {
      Msg <- paste0(
        "The 'Rail' fields in the marea_transit_powertrain_prop.csv input file ",
        "are not complete. They must all have data values, or all must be NA."
      )
      Errors_ <- c(Errors_, Msg)
    }
  } else {
    Msg <- paste0(
      "marea_transit_fuel.csv input file is present but not complete"
    )
    Errors_ <- c(Errors_, Msg)
  }

  #Add Errors and Warnings to Out_ls and return
  #--------------------------------------------
  Out_ls$Errors <- Errors_
  Out_ls$Warnings <- Warnings_
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
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- Initialize(TestDat_)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )

