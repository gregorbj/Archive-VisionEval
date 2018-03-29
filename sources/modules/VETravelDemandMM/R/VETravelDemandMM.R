#' \code{VETravelDemandMM} package
#'
#' Simulate Multi-Modal Travel Demand for Households
#'
#' See the README on
#' \href{https://github.com/gregorbj/VisionEval/sources/modules/VETravelDemandMM}{GitHub}
#'
#' @docType package
#' @name VETravelDemandMM
NULL

## quiets concerns of R CMD check re: non-standard evaluation via tidyverse
## per suggestion of Hadley Wickham (https://stackoverflow.com/a/12429344/688693)
if(getRversion() >= "2.15.1")  utils::globalVariables(c("AADVMTModel_df",
                                                        "Age0to14",
                                                        "BikePMTModel_df",
                                                        "BikeTFLModel_df",
                                                        "Drivers",
                                                        "DriversModel_df",
                                                        "HhSize",
                                                        "Income",
                                                        "LifeCycle",
                                                        "TransitPMTModel_df",
                                                        "TransitTFLModel_df",
                                                        "Vehicles",
                                                        "VehiclesModel_df",
                                                        "WalkPMTModel_df",
                                                        "WalkTFLModel_df",
                                                        "bias_adj",
                                                        "data",
                                                        "model",
                                                        "post_func",
                                                        "predict",
                                                        "step",
                                                        "y",
                                                        "y_name"
                                                        ))

# set the default stringsAsFactors option to FALSE
options(stringsAsFactors=FALSE)
