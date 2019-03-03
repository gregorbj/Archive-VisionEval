#Define function to allocate integer quantities among categories
#---------------------------------------------------------------
#' Allocate integer quantities among categories
#'
#' \code{splitIntegers} splits a total value into a vector of whole numbers to
#' reflect input vector of proportions
#'
#' This function splits an input total into a vector of whole numbers to reflect
#' an input vector of proportions. If the input total is not an integer, the
#' value is rounded and converted to an integer.
#'
#' @param Tot a number that is the total value to be split into a vector of
#' whole numbers corresponding to the input proportions. If Tot is not an
#' integer, its value is rounded and converted to an integer.
#' @param Props_ a numeric vector of proportions used to split the total value.
#' The values should add up to approximately 1. The function will adjust so that
#' the proportions do add to 1.
#' @return a numeric vector of whole numbers corresponding to the Props_
#' argument which sums to the Tot.
#' @export
splitIntegers <- function(Tot, Props_) {
  #Convert Tot into an integer
  if (!is.integer(Tot)) {
    Tot <- as.integer(round(Tot))
  }
  #If Tot is 0, return vector of zeros
  if (Tot == 0) {
    integer(length(Props_))
  } else {
    #Make sure that Props_ sums exactly to 1
    Props_ <- Props_ / sum(Props_)
    #Make initial whole number split
    Ints_ <- round(Tot * Props_)
    #Determine the difference between the initial split and the total
    Diff <- Tot - sum(Ints_)
    #Allocate the difference
    if (Diff != 0) {
      for (i in 1:abs(Diff)) {
        IdxToChg <- sample(1:length(Props_), 1, prob = Props_)
        Ints_[IdxToChg] <- Ints_[IdxToChg] + sign(Diff)
      }
    }
    unname(Ints_)
  }
}
