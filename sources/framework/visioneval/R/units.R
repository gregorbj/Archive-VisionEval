#=======
#units.R
#=======

#This script contains data and functions for converting between units of
#measure, magnitudes, and currency years.


#CONVERT MEASUREMENT UNITS
#=========================
#' Convert values between units of measure.
#'
#' \code{convertUnits} converts values between different units of measure for
#' complex data types recognized by the visioneval code.
#'
#' The visioneval code recognizes 4 simple data types (integer, double, logical,
#' and character) and 10 complex data types such as distance, mass, speed, etc.
#' The simple data types can have any units of measure, but the complex data
#' types must use units of measure that are declared in the Types() function.
#' This function contains factors for any two units of measure of a complex data
#' type. This function converts the values of a complex data type between two
#' units of measure.
#'
#' @param Values_ a numeric vector of values to convert from one unit to another.
#' @param DataType a string identifying the data type.
#' @param FromUnits a string identifying the units of measure of the Values_.
#' @param ToUnits a string identifying the units of measure to convert the
#' Values_ to.
#' @return A numeric vector of values corresponding the the input Values_. If
#' the DataType is not one of the identified complex types or if the FromUnits
#' or ToUnits are not recognized, the input vector Values_ is returned. In this
#' case, the Converted attribute of the returned values is FALSE. If the
#' DataType is a recognized complex type and the FromUnits and ToUnits are
#' recognized, the returned values are in the units of the ToUnits. In this case
#' the Converted attribute of the returned values is TRUE.
#' @export
convertUnits <-
  function(Values_, DataType, FromUnits, ToUnits) {
    Units_ls <- Types()
    #Check whether DataType is supported
    SupportedUnits_ <-
      names(Types())[!(names(Types()) %in% c("integer", "double", "character", "logical"))]
    if (DataType %in% SupportedUnits_) {
      U_ls <- Types()[[DataType]]$units
      CanConvert <-
        (FromUnits %in% names(U_ls)) & (ToUnits %in% names(U_ls))
      if (CanConvert) {
        if (FromUnits == ToUnits) {
          Result_ <- Values_
          attributes(Result_) <- c(attributes(Values_), list(Converted = FALSE))
        } else {
          Result_ <- Values_ * U_ls[[FromUnits]][ToUnits]
          attributes(Result_) <- c(attributes(Values_), list(Converted = TRUE))
        }
      } else {
        Result_ <- Values_
        attributes(Result_) <- c(attributes(Values_), list(Converted = FALSE))
      }
    } else {
      Result_ <- Values_
      attributes(Result_) <- c(attributes(Values_), list(Converted = FALSE))
    }
    Result_
  }

#Test
# convertUnits(1:10, "energy", "M", "MI")
# convertUnits(1:10, "distance", "meters", "miles")
# convertUnits(1:10, "distance", "M", "miles")
# convertUnits(1:10, "distance", "M", "MI")
# convertUnits(1:10, "distance", "M", "M")
# convertUnits(1, "mass", "TON", "MT") * convertUnits(1, "distance", "MI", "KM")
# convertUnits(1, "mass", "MT", "TON") * convertUnits(1, "distance", "KM", "MI")


#CONVERT BETWEEN DIFFERENT MEASUREMENT MAGNITUDES
#================================================
#' Convert values between different magnitudes.
#'
#' \code{convertMagnitude} converts values between different magnitudes such as
#' between dollars and thousands of dollars.
#'
#' The visioneval framework stores all quantities in single units to be
#' unambiguous about the data contained in the datastore. For example,  total
#' income for a region would be stored in dollars rather than in thousands
#' of dollars or millions of dollars. However, often inputs for large quantities
#' are expressed in thousands or millions. Also submodels may be estimated using
#' values expressed in multiples, or they might produce results that are
#' multiples. Where that is the case, the framework enables model users and
#' developers to encode the data multiplier in the input file field name or the
#' UNITS specification. The framework functions then use that information to
#' convert units to and from the single units stored in the datastore. This
#' function implements the conversion.
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
#' \code{deflateCurrency} converts currency values between different years of
#' measure.
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
