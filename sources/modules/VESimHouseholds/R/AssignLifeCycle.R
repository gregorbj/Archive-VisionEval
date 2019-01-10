#=================
#AssignLifeCycle.R
#=================

#<doc>
## AssignLifeCycle Module
#### September 6, 2018
#
#This module assigns a life cycle category to each household. The life cycle categories are similar, but not the same as, those established for the NHTS. The age categories used in VisionEval models are broader than those used by the NHTS to identify children of different ages. As a result it is not possible for the life cycle designations to reflect child ages as they do in the NHTS. Also, adulthood is determined differently in this module. The NHTS uses age 21 as the threshold age for adulthood. This module uses use 20 as nominal age break for adulthood (the 20-29 age group). Moreover, the module identifies some younger persons to be adults in situations where they are likely to be be living independently as adults or emancipated minors. Persons in the 15 to 19 age group are considered adults when there are no older adults (ages 30+) in the household.
#
### Model Parameter Estimation
#
#This module has no parameters. A set of rules assigns age group categories based on the age of persons and workers in the household.
#
### How the Module Works
#
#The module uses datasets on the numbers of persons in each household by age category and the numbers of workers by age category. The age categories are 0-14 years, 15-19 years, 20-29 years, 30-54 years, 55-64 years, and 65+ years. However no workers are in the 0-14 year age category. The household life cycle is determined by the number of children in combination with the number of adults and whether the adults are retired. The categories are as follows:
#01: one adult, no children
#02: 2+ adults, no children
#03: one adult, children (corresponds to NHTS 03, 05, and 07)
#04: 2+ adults, children (corresponds to NHTS 04, 06, and 08)
#09: one adult, retired, no children
#10: 2+ adults, retired, no children
#
#Because the 15-19 age category can be ambiguous with regard to adult or child status, the status of persons in that age category in the household is determined based on the presence of older adults in the household. If there are no older persons or only persons aged 20-29 in the household, the age 15-19 persons are considered to be adults. Otherwise they are considered to be children.
#
#The retirement status of adults is determined based on age and worker status. Households are considered to be populated with retired persons if all the adults are in the 65+ age category and there are no workers. If children are present in the household with retired persons, then the life cycle category is 03 or 04 rather than 09 or 10.
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


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
      ISELEMENTOF = c("01", "02", "03", "04", "09", "10"),
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
usethis::use_data(AssignLifeCycleSpecifications, overwrite = TRUE)
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
#' @include CreateEstimationDatasets.R CreateHouseholds.R PredictWorkers.R PredictIncome.R
#' @name AssignLifeCycle
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
  #Identify child and adult status by age category
  Ag <- c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus")
  HhByAge_mx <- as.matrix(Hh_df[,Ag])
  StatusByAge_mx <- t(apply(HhByAge_mx, 1, function(x) {
    HasPeople_Ag <- x != 0
    Status_Ag <- c(
      Age0to14 = "Child",
      Age15to19 = "Child",
      Age20to29 = "Adult",
      Age30to54 = "Adult",
      Age55to64 = "Adult",
      Age65Plus = "Adult"
    )
    HasNoOlderAdults <- sum(Status_Ag[HasPeople_Ag] == "Adult") == 0
    HasYoungAdult <- HasPeople_Ag["Age15to19"]
    if (HasNoOlderAdults & HasYoungAdult) Status_Ag["Age15to19"] <- "Adult"
    Status_Ag
  }))
  #Tabulate numbers of persons, adults, children, workers, and retirement age
  #persons
  HhSize_ <- rowSums(HhByAge_mx)
  NumAdults_ <- rowSums(HhByAge_mx * as.numeric(StatusByAge_mx == "Adult"))
  NumChildren_ <- rowSums(HhByAge_mx * as.numeric(StatusByAge_mx == "Child"))
  NumWorkers_ <-
    rowSums(Hh_df[,c("Wkr15to19", "Wkr20to29", "Wkr30to54", "Wkr55to64", "Wkr65Plus")])
  NumRetireAge_ <- HhByAge_mx[, "Age65Plus"]
  #Identify retired households
  IsRetired_ <- (HhSize_ == NumRetireAge_) & (NumWorkers_ == 0)
  #Determine life cycle
  LifeCycle_ <- character(NumHh)
  #01: one adult, no children
  LifeCycle_[(NumChildren_ == 0) & (NumAdults_ == 1) & !IsRetired_] <- "01"
  #02: 2+ adults, no children
  LifeCycle_[(NumChildren_ == 0) & (NumAdults_ > 1) & !IsRetired_] <- "02"
  #03: one adult, children (corresponds to NHTS 03, 05, and 07)
  LifeCycle_[(NumChildren_ >= 1) & (NumAdults_ == 1)] <- "03"
  #04: 2+ adults, children (corresponds to NHTS 04, 06, and 08)
  LifeCycle_[(NumChildren_ >= 1) & (NumAdults_ > 1)] <- "04"
  #09: one adult, retired, no children
  LifeCycle_[(NumChildren_ == 0) & (NumAdults_ == 1) & IsRetired_] <- "09"
  #10: 2+ adults, retired, no children
  LifeCycle_[(NumChildren_ == 0) & (NumAdults_ > 1) & IsRetired_] <- "10"
  #Assign the results to the outputs list and return the list
  Out_ls$Year$Household$LifeCycle <- LifeCycle_
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignLifeCycle")

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
