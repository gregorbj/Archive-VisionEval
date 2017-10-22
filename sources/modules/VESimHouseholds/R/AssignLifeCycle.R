#=================
#AssignLifeCycle.R
#=================
#This module assigns a life cycle category to each household. The life cycle
#categories are similar, but not the same as, those established for the NHTS.
#Unlike the NHTS, the lifecycle categories used in VisionEval models do not
#distinguish between children of different ages. Also, the VisionEval categories
#use age 20 as the breakpoint between the child and adult categories while the
#NHTS uses age 21 for the breakpoint. The VisionEval age breakpoints are set
#to correspond to 5-year age cohorts used in standard demographic predictions.
#The numbering of the categories corresponds to the NHTS categories with the
#exception that the child categories are combined. There is an added category
#for children in non-institutional group quarters (e.g. in college). Other
#non-institutional group quarters persons are treated as either an adult with
#no children. Following are the categories:
#00: child in non-institutional group quarters
#01: one adult, no children
#02: 2+ adults, no children
#03: one adult, children (corresponds to NHTS 03, 05, and 07)
#04: 2+ adults, children (corresponds to NHTS 04, 06, and 08)
#09: one adult, retired, no children
#10: 2+ adults, retired, no children

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

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. A set of rules assigns age group categories
#based on the age of persons and workers in the household.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignLifeCycleSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items("Age0to14",
              "Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Wkr15to19",
              "Wkr20to29",
              "Wkr30to54",
              "Wkr55to64",
              "Wkr65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "HhType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "LifeCycle",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = c("00", "01", "02", "03", "04", "09", "10"),
      SIZE = 2,
      DESCRIPTION = "Household life cycle as defined by 2009 NHTS LIF_CYC variable"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignLifeCycle module
#'
#' A list containing specifications for the AssignLifeCycle module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignLifeCycle.R script.
"AssignLifeCycleSpecifications"
devtools::use_data(AssignLifeCycleSpecifications, overwrite = TRUE)
rm(AssignLifeCycleSpecifications)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns the life cycle category for each household as described
#at the top of each file.

#Main module function that assigns life cycle category to each household
#-----------------------------------------------------------------------
#' Main module function to assign life cycle category to each household
#'
#' \code{AssignLifeCycle} assigns the life cycle category to each household
#' based on the numbers of adults in the household, whether children are in the
#' household, and whether the adults are retired.
#'
#' This function assigns the life cycle category to each household based on the
#' numbers of adults in the household, whether children are in the household,
#' and whether the adults are retired.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
AssignLifeCycle <- function(L) {
  #Convert inputs to data frame
  Hh_df <- data.frame(L$Year$Household)
  #Calculate total number of households
  NumHh <- nrow(Hh_df)
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Household <-
    list(
      LifeCycle = character(NumHh)
    )
  #Identify child, adult, and retired age categories
  Ag <- c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus")
  HhSize_ <- rowSums(Hh_df[,Ag])
  Child <- c("Age0to14", "Age15to19")
  Adult <- c("Age20to29", "Age30to54", "Age55to64", "Age65Plus")
  Retired <- "Age65Plus"
  #Identify worker categories
  Worker <- c("Wkr15to19", "Wkr20to29", "Wkr30to54", "Wkr55to64", "Wkr65Plus")
  #Determine if there are children
  HasChildren_ <- rowSums(Hh_df[,Child]) > 0
  #Determine if there is only one adult
  OnlyOneAdult_ <- rowSums(Hh_df[,Adult]) == 1
  #Determine if adults are retired
  IsRetired_ <-
    rowSums(Hh_df[,Adult]) == Hh_df[,Retired] & rowSums(Hh_df[,Worker]) == 0
  #Determine if group quarters
  IsGrpQtr_ <- Hh_df$HhType == "Grp"
  #Determine life cycle
  LifeCycle_ <- character(NumHh)
  LifeCycle_[!HasChildren_ & OnlyOneAdult_ & !IsRetired_] <- "01"
  LifeCycle_[!HasChildren_ & !OnlyOneAdult_ & !IsRetired_] <- "02"
  LifeCycle_[HasChildren_ & OnlyOneAdult_] <- "03"
  LifeCycle_[HasChildren_ & !OnlyOneAdult_ & !IsGrpQtr_] <- "04"
  LifeCycle_[HasChildren_ & !OnlyOneAdult_ & IsGrpQtr_] <- "00"
  LifeCycle_[!HasChildren_ & OnlyOneAdult_ & IsRetired_] <- "09"
  LifeCycle_[!HasChildren_ & !OnlyOneAdult_ & IsRetired_] <- "10"
  #Assign the results to the outputs list and return the list
  Out_ls$Year$Household$LifeCycle <- LifeCycle_
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
#   ModuleName = "AssignLifeCycle",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignLifeCycle",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
