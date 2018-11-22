#===================
#CalculateInducedDemand.R
#===================

#This module calculates average daily vehicle miles traveld for households. It also
#calculates average DVMT, daily consumption of fuel (in gallons), and average daily
#Co2 equivalent greenhouse emissions for all vehicles.



library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateInducedDemandSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "Trips",
      GROUP = "Global"
    ),
    item(
      TABLE = "BzoneElasticities",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "IncomeGroup",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME = "Mode",
      TABLE = "Trips",
      GROUP = "Global",
      FILE = "region_trips_per_cap.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 7,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto","Transit"),
      DESCRIPTION = "Type of modes used for the trips"
    ),
    item(
      NAME = "Trips",
      TABLE = "Trips",
      GROUP = "Global",
      FILE = "region_trips_per_cap.csv",
      TYPE = "trips",
      UNITS = "TRIP",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Regional average number of trips per capita"
    ),
    item(
      NAME = items(
        "Density",
        "Diversity",
        "Design",
        "Regional_Accessibility",
        "Distance_to_Transit"
      ),
      TABLE = "Bzone",
      GROUP = "Global",
      FILE = "model_place_type_relative_values.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Proportional population density relative to a regional average",
        "Proportional land use mix relative to a regional average",
        "Proportional intersection street density relative to a regional average",
        "Proportional job accessibility by auto relative to a regional average",
        "Proportional distance to nearest transit stop relative to a regional average"
      )
    ),
    item(
      NAME = "Parameters",
      TABLE = "BzoneElasticities",
      GROUP = "Global",
      FILE = "model_place_type_elasticities.csv",
      TYPE = "character",
      UNITS = "category",
      SIZE = 22,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Density", "Diversity", "Design", "Regional_Accessibility",
                      "Distance_to_Transit"),
      DESCRIPTION = "Name of the parameters for which elasticities are measured"
    ),
    item(
      NAME = items(
        "VMT",
        "VehicleTrips",
        "TransitTrips",
        "Walking"
      ),
      TABLE = "BzoneElasticities",
      GROUP = "Global",
      FILE = "model_place_type_elasticities.csv",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Vehicle miles traveled elasticity",
        "Vehicle trips elasticity",
        "Transit trips elasticity",
        "Walking elasticity"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanEmp",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanPop",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanEmp",
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Mode",
      TABLE = "Trips",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 7,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto","Transit")
    ),
    item(
      NAME = "Trips",
      TABLE = "Trips",
      GROUP = "Global",
      TYPE = "trips",
      UNITS = "TRIP",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 5,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      SIZE = 5,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Density",
        "Diversity",
        "Design",
        "Regional_Accessibility",
        "Distance_to_Transit"
      ),
      TABLE = "Bzone",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Parameters",
      TABLE = "BzoneElasticities",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      SIZE = 22,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Density", "Diversity", "Design", "Regional_Accessibility",
                      "Distance_to_Transit")
    ),
    item(
      NAME = items(
        "VMT",
        "VehicleTrips",
        "TransitTrips",
        "Walking"
      ),
      TABLE = "BzoneElasticities",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      SIZE = 0,
      PROHIBIT = c("NA"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000",
      NAVALUE = -1,
      PROHIBIT = c("NA","< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = ""
    ),
    item(
      NAME = "DvmtFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "DvmtFuture",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by automobiles"
    ),
    item(
      NAME = "DvmtPtAdj",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Dvmt adjustment by place types"
    ),
    item(
      NAME = "DvmtFuture",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Average daily vehicle miles traveled by automobiles"
    ),
    item(
      NAME = "Access",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = 99,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Growth in job access"
    ),
    item(
      NAME = "IncomeGroup",
      TABLE = "IncomeGroup",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = c("NA"),
      ISELEMENTOF = c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus"),
      SIZE = 9,
      DESCRIPTION = "Income group levels"
    ),
    item(
      NAME = "Equity",
      TABLE = "IncomeGroup",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = 99,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Growth in equity by income group"
    ),
    item(
      NAME = "VehicleTrips",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "trips",
      UNITS = "TRIP",
      NAVALUE = -1,
      PROHIBIT = c("NA" , "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Policy adjusted vehicle trips"
    ),
    item(
      NAME = "TransitTrips",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "trips",
      UNITS = "TRIP",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Policy adjusted transit trips"
    ),
    item(
      NAME = "Walking",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multiplier",
      NAVALUE = 99,
      PROHIBIT = c("NA"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Growth in walking"
    )
  ),
  #Module is callable
  Call = TRUE
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateInducedDemand module
#'
#' A list containing specifications for the CalculateInducedDemand module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateInducedDemand.R script.
"CalculateInducedDemandSpecifications"
usethis::use_data(CalculateInducedDemandSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
# This function calculates various attributes of daily travel for the
# households and the vehicles.


#Main module function calculates various attributes of travel demand
#------------------------------------------------------------
#' Calculate various attributes of travel demands for each household
#' and vehicle using future data
#'
#' \code{CalculateInducedDemand} calculate various attributes of travel
#' demands for each household and vehicle using future data
#'
#' This function calculates dvmt by placetypes, households, and vehicles.
#' It also calculates fuel gallons consumed, total fuel cost, and Co2 equivalent
#' gas emission for each household using future data.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateInducedDemand <- function(L) {
  #Set up
  #------

  # Function to add suffix 'Future' at the end of all the variable names
  AddSuffixFuture <- function(x, suffix = "Future"){
    # Check if x is a list
    if(is.list(x)){
      if(length(x) > 0){
        # Check if elements of x is a list
        isElementList <- unlist(lapply(x,is.list))
        # Modify the names of elements that are not the list
        noList <- x[!isElementList]
        if(!identical(names(noList),character(0))){
          names(noList) <- paste0(names(noList),suffix)
        }
        # Repeat the function for elements that are list
        yesList <- lapply(x[isElementList], AddSuffixFuture, suffix = suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }


  # Function to remove suffix 'Future' from all the variable names
  RemoveSuffixFuture <- function(x, suffix = "Future"){
    # Check if x is a list
    if(is.list(x)){
      if(length(x) > 0){
        # Check if elements of x is a list
        isElementList <- unlist(lapply(x,is.list))
        # Modify the names of elements that are not the list
        noList <- x[!isElementList]
        if(length(noList)>0){
          names(noList) <- gsub(suffix,"",names(noList))
        }
        # Repeat the function for elements that are list
        yesList <- lapply(x[isElementList], RemoveSuffixFuture, suffix = suffix)
        x <- unlist(list(noList,yesList), recursive = FALSE)
        return(x)
      }
      return(x)
    }
    return(NULL)
  }

  # Modify the input data set
  L <- RemoveSuffixFuture(L)

  #Fix seed
  set.seed(L$G$Seed)

  # Calculate Pop and Emp growth
  PopGrowthByPt <- L$Year$Bzone$UrbanPop - L$BaseYear$Bzone$UrbanPop
  EmpGrowthByPt <- L$Year$Bzone$UrbanEmp - L$BaseYear$Bzone$UrbanEmp
  PlaceTypeGrowthByPt <- rbind(PopGrowthByPt,EmpGrowthByPt)

  PlaceTypeValuesByPtD <- data.frame(L$Global$Bzone)
  PlaceTypeElasticitiesByD <- data.frame(L$Global$BzoneElasticities)
  #Percentage Change in D Value Compared to Regional Average
  #(Negative Value indicates D's are worse than regional average, Positive value means D is better than regional average)
  PlaceTypeValuesByPtD[,as.character(PlaceTypeElasticitiesByD$Parameters)] <- PlaceTypeValuesByPtD[,as.character(PlaceTypeElasticitiesByD$Parameters)] - 1



  #Apply Elasticities to Determine Change in VMT Per Place Type
  PlaceTypeDDiscountByPt <- matrix(0,nrow=4,ncol=13,dimnames=list(colnames(PlaceTypeElasticitiesByD)[-1],PlaceTypeValuesByPtD$Bzone))
  for(i in 1:4){
    PlaceTypePercentChangeByPtD <- PlaceTypeElasticitiesByD[,i+1] * t(PlaceTypeValuesByPtD[,-1])
    colnames(PlaceTypePercentChangeByPtD) <- PlaceTypeValuesByPtD[,1]
    PlaceTypePercentChangeByPtD <- PlaceTypePercentChangeByPtD + 1
    PlaceTypeDDiscountByPt[i,] <- apply(PlaceTypePercentChangeByPtD,2,prod)
  }

  # Calculate just regional accessibility percent change
  AccessiblityPercentChangeByPt <- -1 * PlaceTypeValuesByPtD[,"Regional_Accessibility"] * PlaceTypeElasticitiesByD[PlaceTypeElasticitiesByD$Parameters=="Regional_Accessibility","VMT"]
  names(AccessiblityPercentChangeByPt) <- PlaceTypeValuesByPtD$Bzone

  # Load Household Data file
  Hh_df <- data.frame(L$Year$Household)
  IncBreaks_ <- c(0, 20000, 40000, 60000, 80000, 100000, max(Hh_df$Income))
  IncLabels_ <- c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus")
  Hh_df$IncGrp <- cut(Hh_df$Income, breaks = IncBreaks_, labels = IncLabels_, include.lowest = TRUE)
  rm(IncBreaks_, IncLabels_)

  #Calc Income by PlaceTpye and Group
  Hh_df$HhPlaceTypes <- factor(Hh_df$HhPlaceTypes, levels = L$Year$Bzone$Bzone)
  IncGrpByPt <- table(Hh_df$IncGrp, Hh_df$HhPlaceTypes)

  # Determine VMT, Vehicle Trips and Transit Trips per Capita per total of people and jobs
  VMTPerCapita <- sum(Hh_df$Dvmt)/(sum(L$Year$Bzone$UrbanPop) + sum(L$Year$Bzone$UrbanEmp))
  TripsPerCapita <- as.matrix(L$Global$Trips$Trips, ncol=1)
  rownames(TripsPerCapita) <- L$Global$Trips$Mode
  colnames(TripsPerCapita) <- "Trips"

  TripsPerCapita <- TripsPerCapita * sum(L$Year$Bzone$UrbanPop)/(sum(L$Year$Bzone$UrbanPop) + sum(L$Year$Bzone$UrbanEmp))

  #Determine Growth in VMT, Vehicle Trips, Transit Trips, Job Access, and Walking Per Place Type
  #Growth in VMT Per Place Type For Population= (Population) X (VMT Per Capita) X Total D Discount
  #Growth in VMT Per Place Type For Employment= (Employment) X (VMT Per Capita) X Total D Discount
  PlaceTypeVMTGrowthByPt <- rowSums(apply(PlaceTypeGrowthByPt,1,"*",PlaceTypeDDiscountByPt["VMT",] - 1) * VMTPerCapita)
  VehicleTripsByPt <- rowSums(apply(PlaceTypeGrowthByPt,1,"*",PlaceTypeDDiscountByPt["VehicleTrips",]) * TripsPerCapita["Auto",])
  TransitTripsByPt <- rowSums(apply(PlaceTypeGrowthByPt,1,"*",PlaceTypeDDiscountByPt["TransitTrips",]) * TripsPerCapita["Transit",])
  WalkingByMa <- sum(apply(PlaceTypeGrowthByPt,1,"*",PlaceTypeDDiscountByPt["Walking",] - 1))/sum(PlaceTypeGrowthByPt)
  AccessByMa <- sum(apply(PlaceTypeGrowthByPt,1,"*",AccessiblityPercentChangeByPt))/sum(PlaceTypeGrowthByPt)
  EquityByIg <- colSums(apply(IncGrpByPt[,L$Year$Bzone$Bzone],1,"*",AccessiblityPercentChangeByPt))/rowSums(IncGrpByPt)

  #Calculate factors to adjust hh Dvmt by Place Type
  DvmtByPt <- L$Year$Bzone$UrbanPop * 0
  names(DvmtByPt) <- L$Year$Bzone$Bzone
  DvmtByPt[L$Year$Bzone$Bzone] <- tapply(Hh_df$Dvmt, Hh_df$HhPlaceTypes, sum)[L$Year$Bzone$Bzone]
  DvmtAdjByPt <- PlaceTypeVMTGrowthByPt / DvmtByPt + 1
  DvmtAdjByPt[is.na(DvmtAdjByPt)] <- 1
  DvmtAdjByPt[DvmtAdjByPt<0.01] <- 0.01

  #Update Dvmt
  Hh_df$DvmtPtAdj <- DvmtAdjByPt [ as.character(Hh_df$HhPlaceTypes) ]	 #need as.character else it uses factor levels to index into DvmtAdjByPt
  Hh_df$Dvmt <- Hh_df$Dvmt * Hh_df$DvmtPtAdj

  #Recalculate Dvmt tabulation with adjusted Dvmt
  DvmtByPt[L$Year$Bzone$Bzone] <- tapply( Hh_df$Dvmt, Hh_df$HhPlaceTypes, sum )[L$Year$Bzone$Bzone]
  DvmtByPt[is.na(DvmtByPt)] <- 0

  #Return the results
  #------------------
  Out_ls <- initDataList()

  Out_ls$Year <- list(
    Bzone = list(),
    Household = list(),
    IncomeGroup = list(),
    Marea = list()
  )

  # Marea results
  Out_ls$Year$Marea <- list(
    Walking = WalkingByMa,
    Access = AccessByMa
  )
  # Bzone results
  Out_ls$Year$Bzone <- list(
    DvmtFuture = DvmtByPt,
    VehicleTrips = VehicleTripsByPt,
    TransitTrips = TransitTripsByPt
  )
  # Household results
  Out_ls$Year$Household <- list(
    DvmtFuture = Hh_df$Dvmt,
    DvmtPtAdj = Hh_df$DvmtPtAdj
  )
  # Vehicle results
  Out_ls$Year$IncomeGroup <-list(
    IncomeGroup = names(EquityByIg),
    Equity = EquityByIg
  )
  # Calculate length attribute of IncomeGroup
  attributes(Out_ls$Year$IncomeGroup)$LENGTH <- length(EquityByIg)

  #Return the outputs list
  return(Out_ls)
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateInducedDemand",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L
# R <- CalculateInducedDemand(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateInducedDemand",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
