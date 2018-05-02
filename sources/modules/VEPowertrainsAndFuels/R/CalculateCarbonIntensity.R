#==========================
#CalculateCarbonIntensity.R
#==========================
#This module calculates the average carbon intensity of fuels (grams CO2e per
#megajoule) by transportation mode. It also calculates the carbon intensity of
#electricity. It checks for optional input data from users. If those data are
#available, it uses them to calculate carbon intensities. Where not available,
#it calculates carbon intensities from package data.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#No module parameters are estimated in this module.

#Load PowertrainFuelDefaults_ls to make it available as a global
#variable
load("./data/PowertrainFuelDefaults_ls.rda")

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateCarbonIntensitySpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
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
      NAME = "ElectricityCI",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitEthanolPropGasoline",
          "TransitBiodieselPropDiesel",
          "TransitRngPropCng"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
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
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
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
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  ),
  Set = items(
    item(
      NAME = "ElectricityCI",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        "Carbon intensity of electricity at point of consumption (grams CO2e per megajoule)"
    ),
    item(
      NAME =
        items(
          "HhAutoFuelCI",
          "HhLtTrkFuelCI",
          "CarSvcAutoFuelCI",
          "CarSvcLtTrkFuelCI",
          "ComSvcAutoFuelCI",
          "ComSvcLtTrkFuelCI",
          "HvyTrkFuelCI"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuels used by household automobiles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by household light trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by car service automobiles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by car service light trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by commercial service automobiles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by commercial service light trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)"
        )
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuel used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit rail vehicles (grams CO2e per megajoule)"
        )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateCarbonIntensity module
#'
#' A list containing specifications for the CalculateCarbonIntensity module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateCarbonIntensity.R script.
"CalculateCarbonIntensitySpecifications"
devtools::use_data(CalculateCarbonIntensitySpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the average carbon intensity of fuels (grams CO2e per
#megajoule) by transportation mode. It also calculates the carbon intensity of
#electricity. It checks for optional input data from users. If those data are
#available, it uses them to calculate carbon intensities. Where not available,
#it calculates carbon intensities from package data.

#Function to determine whether data is present
#---------------------------------------------
#' Determine whether a list component contains data
#'
#' \code{DataPresent} determines whether a list component contains data.
#'
#' Function determines whether a list component contains data if it is not NULL
#' or NA
#'
#' @param List a list that is to be checked for the presence of the component
#' @param ComponentName a string that is the name of the component
#' @return A logical value that is FALSE if the named component is not present
#' in the list or if the value of the component is NA. Otherwise the value is
#' TRUE.
#' @export
DataPresent <- function(List, ComponentName) {
  if (!is.list(List)) stop("First argument must be a list")
  if (!is.null(List[[ComponentName]])) {
    Component <- List[[ComponentName]]
    if (!(is.atomic(Component))) {
      stop("Component must be a vector or single value")
    }
    ifelse(all(is.na(Component)), FALSE, TRUE)
  } else {
    FALSE
  }
}

#Function to interpolate a value
#-------------------------------
#' Interpolate a value from a series for a specified year
#'
#' \code{interpolate} finds a value for a specified year from a vector of
#' values and a corresponding vector of years.
#'
#' Function determines determines the value for a specified year by
#' interpolation using a vector of values and a corresponding vector of years.
#' Smooth splines are used for interpolation.
#'
#' @param Values_ a vector of values that is numeric or may coerced into
#' numeric values
#' @param Years_ a numeric or string vector of years corresponding to the vector
#' of values
#' @param Year a numeric or string value for the year to calculate for.
#' @return A numeric value interpolated for the specified year.
#' @export
#' @importFrom stats smooth.spline
interpolate <- function(Values_, Years_, Year) {
  Values_ <- as.numeric(Values_)
  Years_ <- as.numeric(Years_)
  Year <- as.numeric(Year)
  if (length(Values_) != length(Years_)) {
    stop("Values_ and Years_ must have the same length.")
  }
  if (length(Year) != 1) stop("Year must be a single year.")
  if (Year < min(Years_) | Year > max(Years_)) {
    stop("Year is outside the range of Years_.")
  }
  predict(
    smooth.spline(Years_, Values_),
    Year
  )$y
}

#Function to interpolate a set of values in a dataframe
#------------------------------------------------------
#' Calculate a set of interpolated values for a specified year
#'
#' \code{interpolateDfVals} calculates a set of interpolated values, one for
#' each field in the data frame.
#'
#' Function interpolates values for each field in a data frame.
#'
#' @param Vals_df a data frame of values that are numeric or may coerced into
#' numeric values, and also includes a field named 'Year'.
#' @param Year a numeric or string value for the year to calculate for.
#' @return A vector of numeric values interpolated for the specified year.
#' @export
interpolateDfVals <- function(Vals_df, Year) {
  sapply(names(Vals_df)[names(Vals_df) != "Year"], function(x) {
    interpolate(Vals_df[[x]], Vals_df$Year, Year)
  })
}

#Function to filter vector based on name
#---------------------------------------
#' Filter named, vector, list, data frame, or matrix based on names containing
#' key 'words'
#'
#' \code{filterOnNames} selects portion of a vector, list, data frame, or
#' matrix whose names (colnames in case of matrix) contain the all the 'words'
#' in the supplied vector of 'words'.
#'
#'This function filters a named vector, list, data frame or matrix based on
#'whether a vector of key 'words' are in all the names.
#'
#' @param Data_misc a named vector, list, data frame, or matrix
#' @param Filter_ a string vector of 'words' to find in the names
#' @param Remove_ a string vector of 'words' to remove from the names after the
#' filtering has been completed.
#' @return An object of same class as the input with the only the elements or
#' columns that contain all the key 'words'
#' @export
filterOnNames <- function(Data_misc, Filter_, Remove_ = NULL) {
  if (is.vector(Data_misc) & !is.list(Data_misc)) {
    Class <- "vector"
  } else {
    Class <- class(Data_misc)
  }
  Names_ <- switch(
    Class,
    vector = names(Data_misc),
    matrix = colnames(Data_misc),
    data.frame = names(Data_misc),
    list = names(Data_misc)
    )
  WhichNames_ <-
    sapply(Filter_, function(x) {
      grep(x, Names_)
    })
  if (is.list(WhichNames_)) {
    WhichNames_ <- Reduce(intersect, WhichNames_)
  }
  Data_misc <- switch(
    Class,
    vector = Data_misc[unique(WhichNames_)],
    matrix = Data_misc[, unique(WhichNames_)],
    data.frame = Data_misc[, unique(WhichNames_)],
    list = Data_misc[unique(WhichNames_)]
  )
  if (!is.null(Remove_)) {
    Names_ <- switch(
      Class,
      vector = names(Data_misc),
      matrix = colnames(Data_misc),
      data.frame = names(Data_misc),
      list = names(Data_misc)
    )
    for (Remove in Remove_) {
      Names_ <- gsub(Remove, "", Names_)
    }
    if (Class == "matrix") {
      colnames(Data_misc) <- Names_
    } else {
      names(Data_misc) <- Names_
    }
  }
  Data_misc
}

#Function to calculate average fuel carbon intensity
#---------------------------------------------------
#' Calculate average fuel carbon intensity of a transportation mode and type
#'
#' \code{calcAverageFuelCI} calculates the average carbon intensity of fuels
#' used by a transportation mode and type considering the carbon intensities of
#' the base fuels, biofuel mixtures, and the proportions of fuels used.
#'
#' The function calculates the average carbon intensity of fuels used by a
#' transportation mode (e.g. household, car service, commercial service, public
#' transit, freight) and type (e.g. auto, light truck, van, bus, rail, heavy
#' truck). The average carbon intensity is calculated from the base fuel mix
#' for the mode and type (e.g. gasoline, diesel, compressed natural gas), the
#' mix of biofuels used for the mode and type (e.g. ethanol mix in gasoline),
#' and the mix of powertrains geared to the different base fuel types (e.g.
#' proportion of light-duty vehicles that run on gasoline vs. the proportion
#' running on diesel).
#'
#' @param FuelCI_ a named numeric vector of carbon intensity of fuel types where
#' the values are grams of carbon dioxide equivalents per megajoule and the
#' names are Gasoline, Diesel, Cng (compressed natural gas), Lng (liquified
#' natural gas), Ethanol, Biodiesel, and Rng (renewable natural gas).
#' @param FuelProp_ a named vector of fuel proportions used by the mode and
#' type, or in the case of transit with multiple metropolitan area data, a
#' matrix of fuel proportions by type and metropolitan area. The names must be
#' the names of the base fuel types consistent with the names used in FuelCI_
#' although only the names of fuels used by the mode and type need to be
#' included.
#' @param BiofuelProp_ a named vector of the biofuel proportions of base fuels,
#' or in the case of transit with multiple metropolitan area data, a matrix
#' of biofuel proportions by type and metropolitan area. The names must be in
#' form of the biofuel name concatenated with 'Prop' and concatenated with the
#' base fuel name (e.g. EthanolPropGasoline).
calcAverageFuelCI <- function(FuelCI_, FuelProp_, BiofuelProp_) {
  #Extract base fuel and biofuel names
  if (is.matrix(BiofuelProp_)) {
    SplitNames_ <- strsplit(colnames(BiofuelProp_), "Prop")
  } else {
    SplitNames_ <- strsplit(names(BiofuelProp_), "Prop")
  }
  BiofuelNames_ <-
    unlist(lapply(SplitNames_, function(x) x[1]))
  FuelNames_ <-
    unlist(lapply(SplitNames_, function(x) x[2]))
  #Calculate carbon intensity of combined fuel and biofuel
  if (is.matrix(BiofuelProp_)) {
    CombiFuelCI_ <-  sweep(1 - BiofuelProp_, 2, FuelCI_[FuelNames_], "*") +
      sweep(BiofuelProp_, 2, FuelCI_[BiofuelNames_], "*")
    colnames(CombiFuelCI_) <- FuelNames_
  } else {
    CombiFuelCI_ <-
    FuelCI_[FuelNames_] * (1 - BiofuelProp_) + FuelCI_[BiofuelNames_] * BiofuelProp_
  }
  #Calculate weighted average fuel carbon intensity
  if (is.matrix(CombiFuelCI_)) {
    CombiFuelCI_ <- CombiFuelCI_[, colnames(FuelProp_)]
    Result_ <- rowSums(CombiFuelCI_ * FuelProp_)
  } else {
    CombiFuelCI_ <- CombiFuelCI_[names(FuelProp_)]
    Result_ <- sum(CombiFuelCI_ * FuelProp_)
  }
  #Return the result
  Result_
}

#Main module function that manages the calculation of carbon intensity
#---------------------------------------------------------------------
#' Main function to implement the calculation of carbon intensity.
#'
#' \code{CalculateCarbonIntensity} manages the calculation of fuel and
#' electricity carbon intensities by transportation mode.
#'
#' This function manages the calculation of average fuel carbon intensity for
#' each modeled transportation mode. Household vehicle, commercial service
#' vehicle, car service vehicle, and heavy truck average fuel carbon intensities
#' are calculated at the region level. Transit van, transit bus, and transit
#' rail average fuel carbon intensities are calculated at the Marea level.
#' Electricity carbon intensity is calculated at the Azone level. This function
#' calls functions which calculate carbon intensity for each mode.
#'
#' @param L A list containing data from preprocessing supplied optional input
#' files returned by the processModuleInputs function. This list has two
#' components: Errors and Data.
#' @return A list that is the same as the input list with an additional
#' Warnings component.
#' @import visioneval
#' @export
CalculateCarbonIntensity <- function(L) {
  #Initialize output list
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Region <- list()
  Out_ls$Year$Azone <- list()
  Out_ls$Year$Marea <- list()
  Year <- L$G$Year

  #Get carbon intensity of fuels and electricity for the year
  #----------------------------------------------------------
  CI_ <- interpolateDfVals(PowertrainFuelDefaults_ls$CarbonIntensity_df, Year)
  ElectricityCI <- CI_["Electricity"]
  AllFuelCI_ <- CI_[names(CI_) != "Electricity"]
  rm(CI_)

  #Electricity carbon intensity
  #----------------------------
  if (DataPresent(L$Year$Azone, "ElectricityCI")) {
    Out_ls$Year$Azone$ElectricityCI <- L$Year$Azone$ElectricityCI
  } else {
    NumAzones <- length(L$Year$Azone$Azone)
    ElectricityCI <- interpolate(
      PowertrainFuelDefaults_ls$CarbonIntensity_df$Electricity,
      PowertrainFuelDefaults_ls$CarbonIntensity_df$Year,
      Year
    )
    Out_ls$Year$Azone$ElectricityCI <- rep(ElectricityCI, NumAzones)
  }

  #Light-duty vehicle fuel carbon intensity
  #----------------------------------------
  #Biofuel mix
  BiofuelMix_ <-
    interpolateDfVals(PowertrainFuelDefaults_ls$LdvBiofuelMix_df, Year)
  #Household vehicle carbon intensity
  if (DataPresent(L$Year$Region, "HhFuelCI")) {
    Out_ls$Year$Region$HhAutoFuelCI <- L$Year$Region$HhFuelCI
    Out_ls$Year$Region$HhLtTrkFuelCI <- L$Year$Region$HhFuelCI
  } else {
    HhFuelProp_ <-
      interpolateDfVals(PowertrainFuelDefaults_ls$HhFuel_df, Year)
    Out_ls$Year$Region$HhAutoFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(HhFuelProp_, "Auto", Remove_ = "AutoProp"),
      BiofuelProp_ = BiofuelMix_)
    Out_ls$Year$Region$HhLtTrkFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(HhFuelProp_, "LtTrk", Remove_ = "LtTrkProp"),
      BiofuelProp_ = BiofuelMix_)
    rm(HhFuelProp_)
  }
  #Car service vehicle fuel carbon intensity
  if (DataPresent(L$Year$Region, "CarSvcFuelCI")) {
    Out_ls$Year$Region$CarSvcAutoFuelCI <- L$Year$Region$CarSvcFuelCI
    Out_ls$Year$Region$CarSvcLtTrkFuelCI <- L$Year$Region$CarSvcFuelCI
  } else {
    CarSvcFuelProp_ <-
      interpolateDfVals(PowertrainFuelDefaults_ls$CarSvcFuel_df, Year)
    Out_ls$Year$Region$CarSvcAutoFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(CarSvcFuelProp_, "Auto", Remove_ = "AutoProp"),
      BiofuelProp_ = BiofuelMix_)
    Out_ls$Year$Region$CarSvcLtTrkFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(CarSvcFuelProp_, "LtTrk", Remove_ = "LtTrkProp"),
      BiofuelProp_ = BiofuelMix_)
    rm(CarSvcFuelProp_)
  }
  #Commercial service vehicle fuel carbon intensity
  if (DataPresent(L$Year$Region, "ComSvcFuelCI")) {
    Out_ls$Year$Region$ComSvcAutoFuelCI <- L$Year$Region$ComSvcFuelCI
    Out_ls$Year$Region$ComSvcLtTrkFuelCI <- L$Year$Region$ComSvcFuelCI
  } else {
    ComSvcFuelProp_ <-
      interpolateDfVals(PowertrainFuelDefaults_ls$ComSvcFuel_df, Year)
    Out_ls$Year$Region$ComSvcAutoFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(ComSvcFuelProp_, "Auto", Remove_ = "AutoProp"),
      BiofuelProp_ = BiofuelMix_)
    Out_ls$Year$Region$ComSvcLtTrkFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(ComSvcFuelProp_, "LtTrk", Remove_ = "LtTrkProp"),
      BiofuelProp_ = BiofuelMix_)
    rm(ComSvcFuelProp_)
  }
  #Clean up
  rm(BiofuelMix_)

  #Heavy truck fuel carbon intensity
  #---------------------------------
  #Biofuel mix
  BiofuelMix_ <-
    interpolateDfVals(PowertrainFuelDefaults_ls$HvyTrkBiofuelMix_df, Year)
  #Heavy truck fuel carbon intensity
  if (DataPresent(L$Year$Region, "HvyTrkFuelCI")) {
    Out_ls$Year$Region$HvyTrkFuelCI <- L$Year$Region$HvyTrkFuelCI
  } else {
    HvyTrkFuelProp_ <-
      interpolateDfVals(PowertrainFuelDefaults_ls$HvyTrkFuel_df, Year)
    Out_ls$Year$Region$HvyTrkFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = filterOnNames(HvyTrkFuelProp_, "Prop", Remove_ = "Prop"),
      BiofuelProp_ = BiofuelMix_)
    rm(HvyTrkFuelProp_)
  }
  #Clean up
  rm(BiofuelMix_)

  #Transit fuel carbon intensity
  #-----------------------------
  NumMarea <- length(L$Year$Marea$Marea)
  #Biofuel mix
  BiofuelDataNames_ <- c(
    "TransitEthanolPropGasoline",
    "TransitBiodieselPropDiesel",
    "TransitRngPropCng")
  if (all(sapply(BiofuelDataNames_, function(x) DataPresent(L$Year$Marea, x)))) {
    BiofuelMix_mx <-
      as.matrix(data.frame(filterOnNames(L$Year$Marea, BiofuelDataNames_)))
    colnames(BiofuelMix_mx) <- gsub("Transit", "", colnames(BiofuelMix_mx))
  } else {
    BiofuelMix_ <-
      interpolateDfVals(PowertrainFuelDefaults_ls$TransitBiofuelMix_df, Year)
    BiofuelMix_mx <- do.call(rbind, rep(list(BiofuelMix_), NumMarea))
    rm(BiofuelMix_)
  }
  rm(BiofuelDataNames_)
  #Transit van fuel carbon intensity
  FuelPropNames_ <- c("VanPropDiesel", "VanPropGasoline", "VanPropCng")
  if (all(sapply(FuelPropNames_, function(x) DataPresent(L$Year$Marea, x)))) {
    VanFuelProp_mx <-
      as.matrix(
        data.frame(
          filterOnNames(L$Year$Marea, FuelPropNames_, Remove_ = "VanProp")))
  } else {
    VanFuelProp_ <-
      filterOnNames(
        interpolateDfVals(PowertrainFuelDefaults_ls$TransitFuel_df, Year),
        "Van", Remove_ = "VanProp")
    VanFuelProp_mx <- do.call(rbind, rep(list(VanFuelProp_), NumMarea))
    rm(VanFuelProp_)
  }
  if (DataPresent(L$Year$Marea, "TransitVanFuelCI")) {
    Out_ls$Year$Marea$TransitVanFuelCI <- L$Year$Marea$TransitVanFuelCI
  } else {
    Out_ls$Year$Marea$TransitVanFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = VanFuelProp_mx,
      BiofuelProp_ = BiofuelMix_mx)
  }
  rm(FuelPropNames_, VanFuelProp_mx)
  #Transit bus fuel carbon intensity
  FuelPropNames_ <- c("BusPropDiesel", "BusPropGasoline", "BusPropCng")
  if (all(sapply(FuelPropNames_, function(x) DataPresent(L$Year$Marea, x)))) {
    BusFuelProp_mx <-
      as.matrix(
        data.frame(
          filterOnNames(L$Year$Marea, FuelPropNames_, Remove_ = "BusProp")))
  } else {
    BusFuelProp_ <-
      filterOnNames(
        interpolateDfVals(PowertrainFuelDefaults_ls$TransitFuel_df, Year),
        "Bus", Remove_ = "BusProp")
    BusFuelProp_mx <- do.call(rbind, rep(list(BusFuelProp_), NumMarea))
    rm(BusFuelProp_)
  }
  if (DataPresent(L$Year$Marea, "TransitBusFuelCI")) {
    Out_ls$Year$Marea$TransitBusFuelCI <- L$Year$Marea$TransitBusFuelCI
  } else {
    Out_ls$Year$Marea$TransitBusFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = BusFuelProp_mx,
      BiofuelProp_ = BiofuelMix_mx)
  }
  rm(FuelPropNames_, BusFuelProp_mx)
  #Transit rail carbon intensity
  FuelPropNames_ <- c("RailPropDiesel", "RailPropGasoline")
  if (all(sapply(FuelPropNames_, function(x) DataPresent(L$Year$Marea, x)))) {
    RailFuelProp_mx <-
      as.matrix(
        data.frame(
          filterOnNames(L$Year$Marea, FuelPropNames_, Remove_ = "RailProp")))
    } else {
    RailFuelProp_ <-
      filterOnNames(
        interpolateDfVals(
          PowertrainFuelDefaults_ls$TransitFuel_df, Year),
        "RailProp", Remove_ = "RailProp")
    RailFuelProp_mx <- do.call(rbind, rep(list(RailFuelProp_), NumMarea))
    rm(RailFuelProp_)
  }
  if (DataPresent(L$Year$Marea, "TransitRailFuelCI")) {
    Out_ls$Year$Marea$TransitRailFuelCI <- L$Year$Marea$TransitRailFuelCI
  } else {
    Out_ls$Year$Marea$TransitRailFuelCI <- calcAverageFuelCI(
      FuelCI_ = AllFuelCI_,
      FuelProp_ = RailFuelProp_mx,
      BiofuelProp_ = BiofuelMix_mx)
  }
  rm(FuelPropNames_, RailFuelProp_mx)

  #Return the results
  #------------------
  Out_ls
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# load("data/PowertrainFuelDefaults_ls.rda")
# attach(PowertrainFuelDefaults_ls)
# TestDat_ <- testModule(
#   ModuleName = "CalculateCarbonIntensity",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# TestOut_ls <- CalculateCarbonIntensity(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# load("data/PowertrainFuelDefaults_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "CalculateCarbonIntensity",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
# setwd("tests")
# untar("Datastore.tar")
# setwd("..")

