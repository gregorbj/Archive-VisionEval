#=================
#CommonFunctions.R
#=================
#This script defines several functions that are used in common by modules in the
#package.

# Copyright [2017] [AASHTO]
# Based in part on works previously copyrighted by the Oregon Department of
# Transportation and made available under the Apache License, Version 2.0 and
# compatible open-source licenses.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

library(visioneval)

#Function to calculate mean vehicle age from cumulative age distribution
#-----------------------------------------------------------------------
#' Calculate mean vehicle age from cumulative age distribution.
#'
#' \code{findMeanAge} calculates mean age from a cumulative age distribution.
#'
#' This function calculates a mean age from a cumulative age distribution vector
#' where the values of the vector are the cumulative proportions and the names
#' of the vector are the vehicle ages from 0 to 30 years.
#'
#' @param AgeCDF_Ag A named numeric vector where the names are vehicle ages and
#' the values are the proportion of vehicles that age or younger. The names must
#' be an ordered sequence from 0 to 30.
#' @return A numeric value that is the mean vehicle age.
#' @export
#'
findMeanAge <- function(AgeCDF_Ag) {
  Ages_ <- 0:(length(AgeCDF_Ag) - 1)
  AgeProp_Ag <- c(AgeCDF_Ag[1], diff(AgeCDF_Ag))
  sum(AgeProp_Ag * Ages_)
}

#Function to adjust cumulative age distribution to match target mean
#-------------------------------------------------------------------
#' Adjust cumulative age distribution to match target mean.
#'
#' \code{adjustAgeDistribution} Adjusts a cumulative age distribution to match a
#' target mean age.
#'
#' This function adjusts a cumulative age distribution to match a target mean
#' age. The function returns the adjusted cumulative age distribution and the
#' corresponding age distribution. If no target mean value is specified, the
#' function returns the input cumulative age distribution and the corresponding
#' age distribution for that input.
#'
#' @param AgeCDF_Ag A ordered numeric vector where the positions correspond to
#' integer ages from 0 to the length of the vector minus 1.
#' @param TargetMean A number that is the target mean value.
#' @return A numeric value that is the mean vehicle age.
#' @export
#'
adjustAgeDistribution <- function(AgeCDF_Ag, TargetMean = NULL) {
  Ages_ <- 0:(length(AgeCDF_Ag) - 1)
  #Calculate the mean age for the input distribution
  DistMean <- findMeanAge(AgeCDF_Ag)
  #Define a function to adjust the distribution
  calcAdjDist <- function(Shift) {
    if (Shift == 1) {
      AdjCDF_ <- AgeCDF_Ag
    } else {
      AdjAges_ <- Ages_ * Shift
      MaxAge <- max(AdjAges_)
      AdjCDF_ <-
        predict(smooth.spline(AdjAges_, AgeCDF_Ag), 0:floor(MaxAge))$y
      if (tail(AdjCDF_, 1) < 1) {
        AdjCDF_ <- c(AdjCDF_, 1)
      }
    }
    AdjCDF_
  }
  #Define a function to check the mean age (function sent to binary search)
  checkMeanAge <- function(Shift) {
    findMeanAge(calcAdjDist(Shift))
  }
  #Calculate adjusted age distribution
  if (is.null(TargetMean)) {
    Result_ls <-
      list(CumDist = AgeCDF_Ag,
           Dist = c(AgeCDF_Ag[1], diff(AgeCDF_Ag)))
  } else {
    FoundShift <-
      binarySearch(checkMeanAge, c(0.1, 3), Target = TargetMean)
    AdjCumDist_ <- calcAdjDist(FoundShift)
    if (length(AdjCumDist_) > length(Ages_)) {
      AdjCumDist_ <- c(AdjCumDist_[1:max(Ages_)], 1)
    }
    if (length(AdjCumDist_) < length(Ages_)) {
      AdjCumDist_ <- c(AdjCumDist_, rep(1, length(Ages_) - length(AdjCumDist_)))
    }
    Result_ls <-
      list(CumDist = AdjCumDist_,
           Dist = c(AdjCumDist_[1], diff(AdjCumDist_)))
  }
  Result_ls
}
