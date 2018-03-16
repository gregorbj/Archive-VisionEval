#=======
#units.R
#=======

#This script contains data and functions for converting between units of
#measure, magnitudes, and currency years.


#CONVERT MEASUREMENT UNITS
#=========================
#' Convert values between units of measure.
#'
#' \code{convertUnits} a visioneval framework control function that
#' converts values between different units of measure for complex and compound
#' data types recognized by the visioneval code.
#'
#' The visioneval code recognizes 4 simple data types (integer, double, logical,
#' and character) and 9 complex data types (e.g. distance, time, mass). The
#' simple data types can have any units of measure, but the complex data types
#' must use units of measure that are declared in the Types() function. In
#' addition, there is a compound data type that can have units that are composed
#' of the units of two or more complex data types. For example, speed is a
#' compound data type composed of distance divided by speed. With this example,
#' speed in miles per hour would be represented as MI/HR. This function converts
#' a vector of values from one unit of measure to another unit of measure. For
#' compound data type it combines multiple unit conversions. The framework
#' converts units based on the default units declared in the 'units.csv' model
#' definition file and in UNITS specifications declared in modules.
#'
#' @param Values_ a numeric vector of values to convert from one unit to another.
#' @param DataType a string identifying the data type.
#' @param FromUnits a string identifying the units of measure of the Values_.
#' @param ToUnits a string identifying the units of measure to convert the
#' Values_ to. If the ToUnits are 'default' the Values_ are converted to the
#' default units for the model.
#' @return A list containing the converted values and additional information as
#' follows:
#' Values - a numeric vector containing the converted values.
#' FromUnits - a string representation of the units converted from.
#' ToUnits - a string representation of the units converted to.
#' Errors - a string containing an error message or character(0) if no errors.
#' Warnings - a string containing a warning message or character(0) if no
#' warning.
#' @export
convertUnits <-
  function(Values_, DataType, FromUnits, ToUnits = "default") {
    #Define return value template
    Result_ls <- list(
      Values = Values_,
      FromUnits = FromUnits,
      ToUnits = ToUnits,
      Errors = character(0),
      Warnings = character(0)
    )
    #Check FromUnits
    FromUnits_ls <- checkUnits(DataType, FromUnits)
    #Exit if there are errors in FromUnits
    if (length(FromUnits_ls$Errors) != 0) {
      Msg <- paste0(
        "Can't convert units because of error in FromUnits argument (",
        FromUnits, ") as follows: ",
        FromUnits_ls$Errors)
      Result_ls$Errors <- Msg
      return(Result_ls)
    }
    #Exit if the FromUnits are simple
    if (FromUnits_ls$UnitType == "simple") {
      Msg <- paste0(
        "Can't convert units because FromUnits (", FromUnits, ") ",
        "are 'simple' type units. Only 'complex' and 'compound' units ",
        "have specified units that may be converted.")
      Result_ls$Errors <- Msg
      return(Result_ls)
    }
    #Check ToUnits if not 'default'
    if (ToUnits != "default") {
      ToUnits_ls <- checkUnits(DataType, ToUnits)
      #Exit if there are errors in ToUnits
      if (length(ToUnits_ls$Errors) != 0) {
        Msg <- paste0(
          "Can't convert units because of error in ToUnits argument (",
          ToUnits, ") as follows: ",
          ToUnits_ls$Errors)
        Result_ls$Errors <- Msg
        return(Result_ls)
      }
      #Exit if ToUnits are simple
      if (ToUnits_ls$UnitType == "simple") {
        Msg <- paste0(
          "Can't convert units because ToUnits (", ToUnits, ") ",
          "are 'simple' type units. Only 'complex' and 'compound' units ",
          "have specified units that may be converted.")
        Result_ls$Errors <- Msg
        return(Result_ls)
      }
    }
    #Get the ToUnits information if ToUnits is 'default'
    if (ToUnits == "default") {
      ToUnits_ls <- list(
        DataType = DataType,
        UnitType = FromUnits_ls$UnitType,
        Units = character(0),
        Elements = list(),
        Errors = character(0)
      )
      if (ToUnits_ls$UnitType == "complex") {
        ToUnits_ls$Units <- getUnits(ToUnits_ls$DataType)
      }
      if (ToUnits_ls$UnitType == "compound") {
        ToUnits_ls$Elements$Types <- FromUnits_ls$Elements$Types
        ToUnits_ls$Elements$Units <- getUnits(FromUnits_ls$Elements$Types)
        ToUnits_ls$Elements$Operators <- FromUnits_ls$Elements$Operators
        makeUnitExpr <- function(Units_, Ops_) {
          UnitIdx_ <- seq(1, 2*length(Units_) - 1, by = 2)
          OpIdx_ <- seq(2, 2*length(Ops_), by = 2)
          Result_ <- character(length(UnitIdx_) + length(OpIdx_))
          Result_[UnitIdx_] <- Units_
          Result_[OpIdx_] <- Ops_
          paste(Result_, collapse = "")
        }
        ToUnits_ls$Units <-
          makeUnitExpr(ToUnits_ls$Elements$Units, ToUnits_ls$Elements$Operators)
      }
      ToUnits <- ToUnits_ls$Units
      Result_ls$ToUnits <- ToUnits
    }
    #If UnitType is "complex" convert units and exit
    if (FromUnits_ls$UnitType == "complex") {
      Factor <- Types()[[DataType]]$units[[FromUnits]][ToUnits]
      Result_ls$Values <- Values_ * Factor
      return(Result_ls)
    }
    #If UnitType is "compound", determine if conversion possible
    #Return error if not.
    compareCompoundUnits <- function(From_ls, To_ls) {
      IsDiffLength <-
        (length(From_ls$Elements$Units) != length(To_ls$Elements$Units)) |
        (length(From_ls$Elements$Operators) != length(To_ls$Elements$Operators))
      if (IsDiffLength) {
        return(FALSE)
      } else {
        IsDiffTypes <- !all(From_ls$Elements$Types == To_ls$Elements$Types)
        IsDiffOps <- !all(From_ls$Elements$Operators == To_ls$Elements$Operators)
        if (IsDiffTypes | IsDiffOps) {
          return(FALSE)
        } else {
          return(TRUE)
        }
      }
    }
    CanConvert <- compareCompoundUnits(FromUnits_ls, ToUnits_ls)
    if (!CanConvert) {
      Msg <- paste0(
        "Can't convert units because FromUnits (", FromUnits, ") ",
        "and ToUnits (", ToUnits, ") are not comparable.")
      Result_ls$Errors <- Msg
      return(Result_ls)
    }
    #If is convertible, then convert values and return result
    calcConversionFactor <- function(From_ls, To_ls) {
      Num <- length(From_ls$Elements$Units)
      Formula <- character(0)
      for(i in 1:Num) {
        Type <- From_ls$Elements$Types[i]
        FromUnit <- From_ls$Elements$Units[i]
        ToUnit <- To_ls$Elements$Units[i]
        Factor <- Types()[[Type]]$units[[FromUnit]][ToUnit]
        if (i != Num) {
          Op <- From_ls$Elements$Operators[i]
          Formula <- paste(Formula, Factor, Op)
        } else {
          Formula <- paste(Formula, Factor)
        }
      }
      eval(parse(text = Formula))
    }
    Factor <- calcConversionFactor(FromUnits_ls, ToUnits_ls)
    Result_ls$Values <- Values_ * Factor
    Result_ls
  }

#Test
# convertUnits(1:10, "energy", "M", "MI")
# convertUnits(1:10, "distance", "meters", "miles")
# convertUnits(1:10, "distance", "M", "miles")
# convertUnits(1:10, "double", "revenue-miles", "vehicle-miles")
# convertUnits(1:10, "distance", "M", "MI")
# convertUnits(1:10, "distance", "M", "M")
# convertUnits(1:10, "compound", "MI/HR", "TON/MI")
# convertUnits(1:10, "compound", "MI/HR", "KM/SEC")
# convertUnits(1:10, "compound", "MI/HR", "FT/SEC")
# convertUnits(1:10, "mass", "MT")
# convertUnits(1:10, "compound", "GM/MI")
# convertUnits(1:10, "compound", "MT*KM/YR")


#CONVERT BETWEEN DIFFERENT MEASUREMENT MAGNITUDES
#================================================
#' Convert values between different magnitudes.
#'
#' \code{convertMagnitude} a visioneval framework control function that
#' converts values between different magnitudes such as between dollars and
#' thousands of dollars.
#'
#' The visioneval framework stores all quantities in single units to be
#' unambiguous about the data contained in the datastore. For example,  total
#' income for a region would be stored in dollars rather than in thousands of
#' dollars or millions of dollars. However, often inputs for large quantities
#' are expressed in thousands or millions. Also submodels may be estimated using
#' values expressed in multiples, or they might produce results that are
#' multiples. Where that is the case, the framework enables model users and
#' developers to encode the data multiplier in the input file field name or the
#' UNITS specification. The framework functions then use that information to
#' convert units to and from the single units stored in the datastore. This
#' function implements the conversion. The multiplier must be specified in
#' scientific notation used in R with the additional constraint that the digit
#' term must be 1. For example, a multiplier of 1000 would be represented as
#' 1e3. The multiplier is separated from the units name by a period (.). For
#' example if the units of a dataset to be retrieved from the datastore are
#' thousands of miles, the UNITS specification would be written as 'MI.1e3'.
#'
#' @param Values_ a numeric vector of values to convert from one unit to another.
#' @param FromMagnitude a number or string identifying the magnitude of the
#' units of the input Values_.
#' @param ToMagnitude a number or string identifying the magnitude to convert
#' the Values_ to.
#' @return A numeric vector of values corresponding the the input Values_ but
#' converted from the magnitude identified in the FromMagnitude argument to the
#' magnitude identified in the ToMagnitude argument. If either the FromMagnitude
#' or the ToMagnitude arguments is NA, the original Values_ are returned. The
#' Converted attribute of the returned values is FALSE. Otherwise the conversion
#' is done and the Converted attribute of the returned values is TRUE.
#' @export
convertMagnitude <-
  function(Values_, FromMagnitude, ToMagnitude) {
    if (is.na(FromMagnitude) | is.na(ToMagnitude)) {
      Result_ <- Values_
      attributes(Result_) <- c(attributes(Values_), list(Converted = FALSE))
    } else {
      From <- as.numeric(FromMagnitude)
      To <- as.numeric(ToMagnitude)
      Result_ <- Values_ * From / To
      attributes(Result_) <- c(attributes(Values_), list(Converted = TRUE))
    }
    Result_
  }

# convertMagnitude(1:10, 1e3, 1)
# convertMagnitude(1:10, "1e3", "1")
# convertMagnitude(1:10, "1e-6", "1e-3")
# convertMagnitude(1:10, "1e-6", NA)
# convertMagnitude(1:10, NA, "1e-3")


#CONVERT CURRENCY VALUES TO DIFFERENT YEARS OF MEASURE
#=====================================================
#' Convert currency values to different years.
#'
#' \code{deflateCurrency} a visioneval framework control function that
#' converts currency values between different years of measure.
#'
#' The visioneval framework stores all currency values in the base year real
#' currency (e.g. dollar) values. However, currency inputs may be in different
#' nominal year currency. Also modules may be estimated using different nominal
#' year currency data. For example, the original vehicle travel model in
#' GreenSTEP used 2001 NHTS data while the newer model uses 2009 NHTS data. The
#' framework enables model uses to specify the currency year in the field name
#' of an input file that contains currency data. Likewise, the currency year can
#' be encoded in the UNIT attributes for a modules Get and Set specifications.
#' The framework converts dollars to and from specified currency year values and
#' base year real dollar values. The model uses a set of deflator values that
#' the user inputs for the region to make the adjustments. These values are
#' stored in the model state list.
#'
#' @param Values_ a numeric vector of values to convert from one currency year
#' to another.
#' @param FromYear a number or string identifying the currency year of the input
#' Values_.
#' @param ToYear a number or string identifying the currency year to convert the
#' Values_ to.
#' @return A numeric vector of values corresponding the the input Values_ but
#' converted from the currency year identified in the FromYear argument to the
#' currency year identified in the ToYear argument. If either the FromYear or
#' the ToYear arguments is unaccounted for in the deflator series, the original
#' Values_ are returned with a Converted attribute of FALSE. Otherwise the
#' conversion is done and the Converted attribute of the returned values is TRUE.
#' @export
deflateCurrency <-
  function(Values_, FromYear, ToYear) {
    Deflators_df <- getModelState()$Deflators
    Years_ <- as.character(Deflators_df$Year)
    Idx_ <- Deflators_df$Value
    names(Idx_) <- Years_
    FromYear <- as.character(FromYear)
    ToYear <- as.character(ToYear)
    #Check that FromYear and ToYear are accounted for in Idx_Yr
    if (!(FromYear %in% Years_) | !(ToYear %in% Years_)) {
      Result_ <- Values_
      attributes(Result_) <- c(attributes(Values_), list(Converted = FALSE))
    } else {
      #Calculate deflated values
      FromIdx <- Idx_[FromYear]
      ToIdx <- Idx_[ToYear]
      Result_ <- Values_ * ToIdx / FromIdx
      attributes(Result_) <- c(attributes(Values_), list(Converted = TRUE))
    }
    Result_
  }


# deflateCurrency(1:10, "1999", "2016")
# deflateCurrency(1:10, 1999, 2016)
# deflateCurrency(1:10, 2016, 1999)
# deflateCurrency(1:10, 1998, 2016)
# deflateCurrency(1:10, 1999, 2017)
