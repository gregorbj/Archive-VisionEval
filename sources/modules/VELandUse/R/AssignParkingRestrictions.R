#===========================
#AssignParkingRestrictions.R
#===========================
#This module assigns residential and employment parking restrictions.
#Residential parking restrictions are specified by the average number of free
#parking spaces available to households by Bzone and the average daily long-term
#parking cost. The average number of free parking spaces is specified separately
#for single family dwellings and multifamily dwellings. Parking restrictions are
#assigned to households. These restrictions are used in the calculation of
#household vehicle ownership cost and the adjustment of vehicle ownership as a
#consequence of those costs (by other modules). Parking restrictions at
#employment locations are established as the proportion of workers who have to
#pay for parking, the average daily long-term parking cost by Bzone, and the
#proportion of paid worker parking that is made available on a cash-out-buy-back
#basis. Worker parking costs are applied to households based on the Bzone
#parking restrictions and what Bzones the household workers are located in.
#These costs are treated as part of the household vehicle use cost and are used
#in other modules to adjust household vehicle travel as a function of budget
#constraints.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no model parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignParkingRestrictionsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "PkgSpacesPerSFDU",
          "PkgSpacesPerMFDU",
          "PkgSpacesPerGQ"),
      FILE = "bzone_parking.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "parking spaces",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average number of free parking spaces available to residents of single-family dwelling units",
          "Average number of free parking spaces available to residents of multifamily dwelling units",
          "Average number of free parking spaces available to group quarters residents"
        )
    ),
    item(
      NAME =
        items(
          "PropWkrPay",
          "PropCashOut"),
      FILE = "bzone_parking.csv",
      TABLE = "Bzone",
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
          "Proportion of workers who pay for parking",
          "Proportions of workers paying for parking in a cash-out-buy-back program"
        )
    ),
    item(
      NAME = "PkgCost",
      FILE = "bzone_parking.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Average daily cost for long-term parking (e.g. paid on monthly basis)"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "PkgSpacesPerSFDU",
          "PkgSpacesPerMFDU",
          "PkgSpacesPerGQ"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "parking spaces",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "PropWkrPay",
          "PropCashOut"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "PkgCost",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "RetEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "SvcEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "Latitude",
          "Longitude"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -9999,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    ),
    item(
      NAME = "Bzone",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "FreeParkingSpaces",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "parking spaces",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of free parking spaces available to the household"
    ),
    item(
      NAME = "ParkingUnitCost",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Daily cost for long-term parking (e.g. paid on monthly basis)"
    ),
    item(
      NAME = "OtherParkingCost",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Daily cost for parking at shopping locations or other locations of paid parking not including work (not adjusted for number of vehicle trips)"
    ),
    item(
      NAME = "PaysForParking",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Does worker pay for parking: 1 = yes, 0 = no"
    ),
    item(
      NAME = "IsCashOut",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Is worker paid parking in cash-out-buy-back program: 1 = yes, 0 = no"
    ),
    item(
      NAME = "ParkingCost",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Daily cost for long-term parking (e.g. paid on monthly basis)"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignParkingRestrictions module
#'
#' A list containing specifications for the AssignParkingRestrictions module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignParkingRestrictions.R script.
"AssignParkingRestrictionsSpecifications"
usethis::use_data(AssignParkingRestrictionsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns parking restrictions to households. This includes
#restrictions on parking household vehicles and restrictions on parking vehicles
#at the household workers places of work. The function identifies the number of
#free parking spaces the household may use, the charge for household parking per
#vehicle if they exceed the number of free spaces, how many household workers
#pay for parking, the charge they have to pay, and the amount of the work
#parking charges that are 'cash-out-buy-back'. The module also calculates a
#simple placeholder value for other daily parking charges (e.g. paying for
#parking at shopping). These are calculated as a weighted average of daily
#parking cost in each Bzone weighted by the portion of total aggregate activity
#in the region that is in each Bzone (D1D measure calculated by the
#Calculate4DMeasures module)

#Main module function that assigns parking restrictions to each household
#------------------------------------------------------------------------
#' Main module function to assign parking restrictions to each household.
#'
#' \code{AssignParkingRestrictions} assigns parking restrictions to each
#' household including residential parking restrictions and worker parking
#' restrictions.
#'
#' This function assigns parking restrictions to households. This includes
#' restrictions on parking household vehicles and restrictions on parking
#' vehicles at the household workers places of work. The function identifies the
#' number of free parking spaces the household may use, the charge for household
#' parking per vehicle if they exceed the number of free spaces, how many
#' household workers pay for parking, the charge they have to pay, and the
#' amount of the work parking charges that are 'cash-out-buy-back'.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignParkingRestrictions
#' @import visioneval stats fields
#' @export
AssignParkingRestrictions <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  BzToHh_ <- match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)
  BzToWk_ <- match(L$Year$Worker$Bzone, L$Year$Bzone$Bzone)
  NumHh <- length(BzToHh_)
  NumWkr <- length(BzToWk_)

  #Calculate the number of number of residential parking spaces and cost
  #---------------------------------------------------------------------
  #Calculate number of free parking spaces available to each household
  PkgSp_Hh <- local({
    HouseType_Hh <- L$Year$Household$HouseType
    AvePkgSp_Hh <- numeric(NumHh)
    AvePkgSp_Hh[HouseType_Hh == "SF"] <-
      L$Year$Bzone$PkgSpacesPerSFDU[BzToHh_][HouseType_Hh == "SF"]
    AvePkgSp_Hh[HouseType_Hh == "MF"] <-
      L$Year$Bzone$PkgSpacesPerMFDU[BzToHh_][HouseType_Hh == "MF"]
    AvePkgSp_Hh[HouseType_Hh == "GQ"] <-
      L$Year$Bzone$PkgSpacesPerGQ[BzToHh_][HouseType_Hh == "GQ"]
    BasePkgSp_Hh <- floor(AvePkgSp_Hh)
    AddSpProb_Hh <- AvePkgSp_Hh - BasePkgSp_Hh
    BasePkgSp_Hh + as.numeric(runif(NumHh) < AddSpProb_Hh)
  })
  #Identify how much household would have to pay for a parking space
  CostPerSpace_Hh <- L$Year$Bzone$PkgCost[BzToHh_]

  #Calculate parking costs for workers
  #-----------------------------------
  #Identify which workers pay for parking
  PropPay_Wk <- L$Year$Bzone$PropWkrPay[BzToWk_]
  DoesPay_Wk <- runif(NumWkr) < PropPay_Wk
  #Identify which workers whose parking is cash out buy back
  PropCashOut_Wk <- L$Year$Bzone$PropCashOut[BzToWk_]
  IsCashOut_Wk <- (runif(NumWkr) < PropCashOut_Wk) & DoesPay_Wk
  #Identify the cost per space
  CostPerSpace_Wk <- L$Year$Bzone$PkgCost[BzToWk_]
  CostPerSpace_Wk[!DoesPay_Wk] <- 0
  #Clean up
  rm(PropPay_Wk, PropCashOut_Wk)

  #Other household parking cost
  #----------------------------
  #Calculated as function of inverse of distance to attractions from home and
  #amount of retail and service employment
  OtherPkgCost_Bz <- local({
    #Calculate distances between Bzones
    LngLat_df <-
      data.frame(
        lng = L$Year$Bzone$Longitude,
        lat = L$Year$Bzone$Latitude)
    Dist_BzBz <- rdist.earth(LngLat_df, LngLat_df, miles = TRUE, R = 6371)
    diag(Dist_BzBz) <- 0
    diag(Dist_BzBz) <- apply(Dist_BzBz, 1, function(x) min(x[x != 0]) / 2)
    #Create attraction term to determine relative attractiveness to non-work trips
    Attr_Bz <- L$Year$Bzone$RetEmp + L$Year$Bzone$SvcEmp
    Attr_Bz[Attr_Bz == 0] <- 1
    #Create production term
    NumHh_Bz <- L$Year$Bzone$NumHh
    #Scale relative attractions to equal number of households
    Attr_Bz <- sum(NumHh_Bz) * Attr_Bz / sum(Attr_Bz)
    #Calculate relative attractiveness
    Attr_BzBz <-
      ipf(1 / Dist_BzBz, list(NumHh_Bz, Attr_Bz), list(1, 2))$Units_ar
    #Calculate attraction probabilities
    AttrProb_BzBz <- sweep(Attr_BzBz, 1, rowSums(Attr_BzBz), "/")
    #Calculate the weighted parking cost
    rowSums(sweep(AttrProb_BzBz, 2, L$Year$Bzone$PkgCost, "*"))
  })
  #Assign other parking cost to households
  OtherPkgCost_Hh <- OtherPkgCost_Bz[BzToHh_]

  #Return list of results
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    FreeParkingSpaces = as.integer(PkgSp_Hh),
    ParkingUnitCost = CostPerSpace_Hh,
    OtherParkingCost = OtherPkgCost_Hh
  )
  Out_ls$Year$Worker <- list(
    PaysForParking = as.integer(DoesPay_Wk),
    IsCashOut = as.integer(IsCashOut_Wk),
    ParkingCost = CostPerSpace_Wk
  )
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
#   ModuleName = "AssignParkingRestrictions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignParkingRestrictions(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignParkingRestrictions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

