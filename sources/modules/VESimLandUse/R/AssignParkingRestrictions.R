#===========================
#AssignParkingRestrictions.R
#===========================
#
#<doc>
#
## AssignParkingRestrictions Module
#### February 7, 2018
#
#This module identifies parking restrictions and prices affecting households at their residences, workplaces, and other places they are likely to visit in the urban area. The module takes user inputs on parking restrictions and prices by Bzone and calculates for each household the number of free parking spaces available at the household's residence, which workers pay for parking and whether their payment is part of a *cash-out-buy-back* program, the cost of residential parking for household vehicles that can't be parked in a free space, the cost for workplace parking, and the cost of parking for other activities such as shopping. The parking restriction/cost information is used by other modules in calculating the cost of vehicle ownership and the cost of vehicle use.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#The user provides inputs by Marea and 3 of 4 area types the following information which provide the basis for calculating
#parking restrictions and costs for each household. These include:
#
#- Average number of free parking spaces per single-family dwelling unit
#
#- Average number of free parking spaces per multifamily dwelling unit
#
#- Average number of free parking spaces per group quarters resident
#
#- Proportion of workers working at jobs in the Bzone who pay for parking
#
#- Proportion of worker paid parking in *cash-out_buy-back* program
#
#- Average daily parking cost
#
#The user only provides information for the *center*, *inner*, and *outer* area types. For simplicity it is assumed that there are no parking restrictions or costs in fringe areas.
#
#Free residential parking spaces are applied to each household based on the user inputs for available spaces for the dwelling type of the household and area type of the Bzone where the household resides. If the average number of parking spaces is not an integer, the household is assigned the integer amount of spaces and a possible additional space determined through a random draw with the decimal portion serving as the probability of success. For example, if the average is 1.75 spaces, all households would be assigned at least 1 space and 75% of the households would be assigned 2 spaces. The daily parking cost assigned to the area type of the Bzone where the household resides is assigned to the household to use in vehicle ownership cost calculations.
#
#A worker is assigned as paying or not paying for parking through a random draw with the probability of paying equal to the proportion of paying workers that is input for the area type of the worker's job location. A worker identified as paying for parking is identified as being in a *cash-out-buy-back* program through a random draw with the participation probability being the input value for the area type of the worker's job location. The daily parking cost assigned to the worker's job site area type is assigned to the work to use in vehicle use calculations.
#
#Average daily parking costs for other (non-work) household travel purposes (e.g. shopping) are assigned to households based on their location type and area type. Households in rural and town locations are assigned a value of 0. Households in urban locations are assigned a weighted average value of the parking costs assigned to the area types in the urban area where the proportion of urban retail and service employment in each area type is used as the weighting factor. This cost is adjusted to account for the number of household vehicle trips when the household's vehicle use costs are calculated.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no model parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#' @import visioneval

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
          "CenterPkgSpacesPerSFDU",
          "InnerPkgSpacesPerSFDU",
          "OuterPkgSpacesPerSFDU",
          "CenterPkgSpacesPerMFDU",
          "InnerPkgSpacesPerMFDU",
          "OuterPkgSpacesPerMFDU",
          "CenterPkgSpacesPerGQ",
          "InnerPkgSpacesPerGQ",
          "OuterPkgSpacesPerGQ"),
    FILE = "marea_parking-avail_by_area-type.csv",
      TABLE = "Marea",
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
          "Average number of free parking spaces available to residents of single-family dwelling units in center area type",
          "Average number of free parking spaces available to residents of single-family dwelling units in inner area type",
          "Average number of free parking spaces available to residents of single-family dwelling units in outer area type",
          "Average number of free parking spaces available to residents of multifamily dwelling units in center area type",
          "Average number of free parking spaces available to residents of multifamily dwelling units in inner area type",
          "Average number of free parking spaces available to residents of multifamily dwelling units in outer area type",
          "Average number of free parking spaces available to group quarters residents in center area type",
          "Average number of free parking spaces available to group quarters residents in inner area type",
          "Average number of free parking spaces available to group quarters residents in outer area type"
        )
    ),
    item(
      NAME =
        items(
          "CenterPropWkrPay",
          "InnerPropWkrPay",
          "OuterPropWkrPay",
          "CenterPropCashOut",
          "InnerPropCashOut",
          "OuterPropCashOut"),
      FILE = "marea_parking-cost_by_area-type.csv",
      TABLE = "Marea",
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
          "Proportion of workers who pay for parking in center area type",
          "Proportion of workers who pay for parking in inner area type",
          "Proportion of workers who pay for parking in outer area type",
          "Proportions of workers paying for parking in a cash-out-buy-back program in center area type",
          "Proportions of workers paying for parking in a cash-out-buy-back program in inner area type",
          "Proportions of workers paying for parking in a cash-out-buy-back program in outer area type"
        )
    ),
    item(
      NAME = items(
        "CenterPkgCost",
        "InnerPkgCost",
        "OuterPkgCost"),
      FILE = "marea_parking-cost_by_area-type.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Average daily cost for long-term parking (e.g. paid on monthly basis) in center area type",
        "Average daily cost for long-term parking (e.g. paid on monthly basis) in inner area type",
        "Average daily cost for long-term parking (e.g. paid on monthly basis) in outer area type"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
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
      NAME =
        items(
          "CenterPkgSpacesPerSFDU",
          "InnerPkgSpacesPerSFDU",
          "OuterPkgSpacesPerSFDU",
          "CenterPkgSpacesPerMFDU",
          "InnerPkgSpacesPerMFDU",
          "OuterPkgSpacesPerMFDU",
          "CenterPkgSpacesPerGQ",
          "InnerPkgSpacesPerGQ",
          "OuterPkgSpacesPerGQ"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "parking spaces",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "CenterPropWkrPay",
          "InnerPropWkrPay",
          "OuterPropWkrPay",
          "CenterPropCashOut",
          "InnerPropCashOut",
          "OuterPropCashOut"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "CenterPkgCost",
        "InnerPkgCost",
        "OuterPkgCost"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Bzone",
        "Marea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    ),
    item(
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("center", "inner", "outer", "fringe")
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
      NAME =
        items("RetEmp",
              "SvcEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = items(
        "HhId",
        "Bzone",
        "Marea"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "WkrId",
        "Bzone",
        "Marea"),
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
#' @import visioneval stats
#' @export
AssignParkingRestrictions <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Naming vectors
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Number of households and workers
  NumHh <- length(L$Year$Household$HouseType)
  NumWkr <- length(L$Year$Worker$Bzone)
  #Indexes from Bzone to Households and to Workers
  BzToHh_ <- match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)
  BzToWk_ <- match(L$Year$Worker$Bzone, L$Year$Bzone$Bzone)
  #Initialize lists to hold outputs
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    FreeParkingSpaces = integer(NumHh),
    ParkingUnitCost = numeric(NumHh),
    OtherParkingCost = numeric(NumHh)
  )
  Out_ls$Year$Worker <- list(
    PaysForParking = integer(NumWkr),
    IsCashOut = integer(NumWkr),
    ParkingCost = numeric(NumWkr)
  )

  #Identify location and area types of households and workers
  #----------------------------------------------------------
  #Assign location types
  LocType_Hh <- L$Year$Bzone$LocType[BzToHh_]
  LocType_Wk <- L$Year$Bzone$LocType[BzToWk_]
  #Assign area types
  AreaType_Hh <- L$Year$Bzone$AreaType[BzToHh_]
  AreaType_Wk <- L$Year$Bzone$AreaType[BzToWk_]

  #Calculate parking values at the Bzone level
  #-------------------------------------------
  #Define function to make a matrix of values for related items
  makeValsMaAt <- function(RootName, FringeVal) {
    DataNames_ <- paste0(c("Center", "Inner", "Outer"), RootName)
    Vals_df <- data.frame(
      L$Year$Marea[DataNames_]
    )
    names(Vals_df) <- c("center", "inner", "outer")
    Vals_df$fringe <- FringeVal
    rownames(Vals_df) <- Ma
    as.matrix(Vals_df)
  }
  #Define function to get values from matrix by Marea and area type
  getMaAtVal <- function(Marea, AreaType) Vals_MaAt[Marea, AreaType]
  #Bzone parking spaces per SFDU
  Vals_MaAt <- makeValsMaAt("PkgSpacesPerSFDU", 10)
  PkgSpacesPerSFDU_Bz <-
    setNames(mapply(getMaAtVal, L$Year$Bzone$Marea, L$Year$Bzone$AreaType), Bz)
  rm(Vals_MaAt)
  #Bzone parking spaces per MFDU
  Vals_MaAt <- makeValsMaAt("PkgSpacesPerMFDU", 10)
  PkgSpacesPerMFDU_Bz <-
    setNames(mapply(getMaAtVal, L$Year$Bzone$Marea, L$Year$Bzone$AreaType), Bz)
  rm(Vals_MaAt)
  #Bzone parking spaces per GQ
  Vals_MaAt <- makeValsMaAt("PkgSpacesPerGQ", 10)
  PkgSpacesPerGQ_Bz <-
    setNames(mapply(getMaAtVal, L$Year$Bzone$Marea, L$Year$Bzone$AreaType), Bz)
  rm(Vals_MaAt)
  #Bzone proportion of workers paying
  Vals_MaAt <- makeValsMaAt("PropWkrPay", 0)
  PropWkrPay_Bz <-
    setNames(mapply(getMaAtVal, L$Year$Bzone$Marea, L$Year$Bzone$AreaType), Bz)
  rm(Vals_MaAt)
  #Bzone proportion of paying workers in cash out program
  Vals_MaAt <- makeValsMaAt("PropCashOut", 0)
  PropCashOut_Bz <-
    setNames(mapply(getMaAtVal, L$Year$Bzone$Marea, L$Year$Bzone$AreaType), Bz)
  rm(Vals_MaAt)
  #Bzone parking cost
  Vals_MaAt <- makeValsMaAt("PkgCost", 0)
  PkgCost_Bz <-
    setNames(mapply(getMaAtVal, L$Year$Bzone$Marea, L$Year$Bzone$AreaType), Bz)
  rm(Vals_MaAt)

  #-------------------------------------------------------------------
  #Iterate by Marea to assign parking values to households and workers
  #-------------------------------------------------------------------
  for (ma in Ma) {
    #Indices to Bzones, Households, and Workers in the Marea
    #-------------------------------------------------------
    #Bzone indices
    BzInMa <- L$Year$Bzone$Marea %in% ma
    Bx <- Bz[BzInMa]
    #Household indices
    HhInMa <- L$Year$Household$Marea %in% ma
    HhBx <- L$Year$Household$Bzone[HhInMa]
    HhId_ <- L$Year$Household$HhId[HhInMa]
    #Worker indices
    WkrInMa <- L$Year$Worker$Marea %in% ma
    WkrBx <- L$Year$Worker$Bzone[WkrInMa]
    WkrId_ <- L$Year$Worker$WkrId[WkrInMa]

    #Calculate the number of number of residential parking spaces and cost
    #---------------------------------------------------------------------
    #Calculate number of free parking spaces available to each household
    PkgSp_Hh <- local({
      HouseType_Hh <- L$Year$Household$HouseType[HhInMa]
      AvePkgSp_Hh <- numeric(sum(HhInMa))
      AvePkgSp_Hh[HouseType_Hh == "SF"] <-
        PkgSpacesPerSFDU_Bz[HhBx][HouseType_Hh == "SF"]
      AvePkgSp_Hh[HouseType_Hh == "MF"] <-
        PkgSpacesPerMFDU_Bz[HhBx][HouseType_Hh == "MF"]
      AvePkgSp_Hh[HouseType_Hh == "GQ"] <-
        PkgSpacesPerGQ_Bz[HhBx][HouseType_Hh == "GQ"]
      BasePkgSp_Hh <- floor(AvePkgSp_Hh)
      AddSpProb_Hh <- AvePkgSp_Hh - BasePkgSp_Hh
      BasePkgSp_Hh + as.numeric(runif(sum(HhInMa)) < AddSpProb_Hh)
    })
    #Identify how much household would have to pay for a parking space
    CostPerSpace_Hh <- PkgCost_Bz[HhBx]

    #Calculate parking costs for workers
    #-----------------------------------
    #Identify which workers pay for parking
    PropPay_Wk <- PropWkrPay_Bz[WkrBx]
    DoesPay_Wk <- runif(sum(WkrInMa)) < PropPay_Wk
    #Identify which workers whose parking is cash out buy back
    PropCashOut_Wk <- PropCashOut_Bz[WkrBx]
    IsCashOut_Wk <- (runif(sum(WkrInMa)) < PropCashOut_Wk) & DoesPay_Wk
    #Identify the cost per space
    CostPerSpace_Wk <- PkgCost_Bz[WkrBx]
    CostPerSpace_Wk[!DoesPay_Wk] <- 0
    #Clean up
    rm(PropPay_Wk, PropCashOut_Wk)

    #Other household parking cost
    #----------------------------
    #Calculated as function of inverse of distance to attractions from home and
    #amount of retail and service employment
    OtherPkgCost_Bx <- local({
      #Identify location type
      LocType_Bx <- L$Year$Bzone$LocType[BzInMa]
      #Initialize other parking cost vector as zero
      OtherPkgCost_Bx <- numeric(sum(BzInMa))
      #Calculate an other parking cost for urban dwellers
      IsUrban <- LocType_Bx == "Urban"
      RetSvcEmp_Bx <- with(L$Year$Bzone, RetEmp + SvcEmp)[BzInMa]
      PkgCost_Bx <- PkgCost_Bz[BzInMa]
      OtherPkgCost_Bx[IsUrban] <-
        sum(RetSvcEmp_Bx[IsUrban] * PkgCost_Bx[IsUrban]) / sum(RetSvcEmp_Bx[IsUrban])
      setNames(OtherPkgCost_Bx, Bx)
    })
    #Assign other parking cost to households
    OtherPkgCost_Hh <- OtherPkgCost_Bx[HhBx]

    #Add to Out_ls
    #-------------
    #Write out household values
    Out_ls$Year$Household$FreeParkingSpaces[match(HhId_, L$Year$Household$HhId)] <-
      as.integer(PkgSp_Hh)
    Out_ls$Year$Household$ParkingUnitCost[match(HhId_, L$Year$Household$HhId)] <-
      CostPerSpace_Hh
    Out_ls$Year$Household$OtherParkingCost[match(HhId_, L$Year$Household$HhId)] <-
      OtherPkgCost_Hh
    #Write out worker values
    Out_ls$Year$Worker$PaysForParking[match(WkrId_, L$Year$Worker$WkrId)] <-
      as.integer(DoesPay_Wk)
    Out_ls$Year$Worker$IsCashOut[match(WkrId_, L$Year$Worker$WkrId)] <-
      as.integer(IsCashOut_Wk)
    Out_ls$Year$Worker$ParkingCost[match(WkrId_, L$Year$Worker$WkrId)] <-
      CostPerSpace_Wk

    }

  #Return list of results
  #----------------------
  Out_ls

}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignParkingRestrictions")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "AssignParkingRestrictions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignParkingRestrictions(L)

# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "AssignParkingRestrictions",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
