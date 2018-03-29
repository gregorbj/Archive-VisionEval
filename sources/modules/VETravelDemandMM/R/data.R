
#' list-column data frame (tibble) with estimated model objects for household AADVMT model
#'
#' list-column data frame (tibble) with estimated model objects for household AADVMT model
#' Estimated with the script in data-raw/AADVMTModel_df.R
#'
#' @format The main data frame \code{AADVMTModel_df} has 2 rows and 3 variables:
#' \describe{
#'   \item{metro}{metro or non-metro segment of the AADVMT model}
#'   \item{model}{the model objects stored in list-column of the data frame}
#'   \item{post_func}{the function for post-processing model predictions}
#'   }
#'
#' @examples
#' str(AADVMTModel_df)
#' head(AADVMTModel_df)
#' summary(AADVMTModel_df)
#'
"AADVMTModel_df"

#' list-column data frame (tibble) with estimated model objects for household Biking PMT model
#'
#' list-column data frame (tibble) with estimated model objects for household Biking PMT model
#' Estimated with the script in data-raw/BikePMTModel_df.R
#'
#' @format The main data frame \code{BikePMTModel_df} has 2 rows and 3 variables:
#' \describe{
#'   \item{metro}{metro or non-metro segment of the Biking PMT model}
#'   \item{model}{the model objects stored in list-column of the data frame}
#'   \item{post_func}{the function for post-processing model predictions}
#'   }
#'
#' @examples
#' str(BikePMTModel_df)
#' head(BikePMTModel_df)
#' summary(BikePMTModel_df)
#'
"BikePMTModel_df"

#' list-column data frame (tibble) with estimated model objects for household drivers model
#'
#' list-column data frame (tibble) with estimated model objects for household drivers model
#' Estimated with the script in data-raw/DriversModel.R
#'
#' @format The main data frame \code{DriversModel} has 1 rows and 2 variables:
#' \describe{
#'   \item{model}{the model objects stored in list-column of the data frame}
#'   \item{post_func}{the function for post-processing model predictions}
#'   }
#'
#' @examples
#' str(DriversModel_df)
#' head(DriversModel_df)
#' summary(DriversModel_df)
#'
"DriversModel_df"

#' list-column data frame (tibble) with estimated model objects for household Walking PMT model
#'
#' list-column data frame (tibble) with estimated model objects for household Transit PMT model
#' Estimated with the script in data-raw/TransitPMTModel.R
#'
#' @format The main data frame \code{TransitPMTModel} has 2 rows and 3 variables:
#' \describe{
#'   \item{metro}{metro or non-metro segment of the Transit PMT model}
#'   \item{model}{the model objects stored in list-column of the data frame}
#'   \item{post_func}{the function for post-processing model predictions}
#'   }
#'
#' @examples
#' str(TransitPMTModel_df)
#' head(TransitPMTModel_df)
#' summary(TransitPMTModel_df)
#'
"TransitPMTModel_df"

#' list-column data frame (tibble) with estimated model objects for household vehicles model
#'
#' list-column data frame (tibble) with estimated model objects for household vehicles model
#' Estimated with the script in data-raw/VehiclesModel.R
#'
#' @format The main data frame \code{VehiclesModel} has 1 rows and 2 variables:
#' \describe{
#'   \item{model}{the model objects stored in list-column of the data frames}
#'   \item{post_func}{the function for post-processing model predictions}
#'   }
#'
#' @examples
#' str(VehiclesModel_df)
#' head(VehiclesModel_df)
#' summary(VehiclesModel_df)
#'
"VehiclesModel_df"

#' list-column data frame (tibble) with estimated model objects for household Walking PMT model
#'
#' list-column data frame (tibble) with estimated model objects for household Walking PMT model
#' Estimated with the script in data-raw/WalkPMTModel.R
#'
#' @format The main data frame \code{WalkPMTModel} has 2 rows and 3 variables:
#' \describe{
#'   \item{metro}{metro or non-metro segment of the Walking PMT model}
#'   \item{model}{the model objects stored in list-column of the data frames}
#'   \item{post_func}{the function for post-processing model predictions}
#'   }
#'
#' @examples
#' str(WalkPMTModel_df)
#' head(WalkPMTModel_df)
#' summary(WalkPMTModel_df)
#'
"WalkPMTModel_df"
