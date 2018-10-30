#==================
#LocateEmployment.R
#==================
#This module places employment in Bzones based on input assumptions of
#employment by type and Bzone. The model adjusts the employment numbers to
#balance with the number of workers in the region. The module assigns workers
#to jobs as a function of the number of jobs in each Bzone and the inverse of
#distance between residence and employment Bzones. An iterative proportional
#fitting process is used to allocate the number of workers between each pair of
#Bzones. A worker table is created and workers are assigned randomly to
#employment Bzones based on the balanced matrix of number of workers by
#residence and employment Bzones.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(fields)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. Employment is allocated to Bzones based on
#inputs, balancing with number of regional workers, and balancing workers by
#residence and job location as a function of the inverse of distance.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
LocateEmploymentSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Worker",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp"),
      FILE = "bzone_employment.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Total number of jobs in zone",
          "Number of jobs in retail sector in zone",
          "Number of jobs in service sector in zone"
        )
    ),
    item(
      NAME =
        items(
          "Latitude",
          "Longitude"),
      FILE = "bzone_lat_lon.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -9999,
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Latitude in decimal degrees of the centroid of the zone",
          "Longitude in decimal degrees of the centroid of the zone"
        )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = items(
        "Bzone",
        "Azone",
        "Marea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumWkr",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Workers",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
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
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("TotEmp",
              "RetEmp",
              "SvcEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Total number of jobs in zone",
          "Number of jobs in retail sector in zone",
          "Number of jobs in service sector in zone"
        )
    ),
    item(
      NAME =
        items("HhId",
              "WkrId"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID",
              "Unique worker ID")
    ),
    item(
      NAME = items(
        "Bzone",
        "Azone",
        "Marea"),
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "",
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Bzone ID of worker job location",
        "Azone ID of worker job location",
        "Marea ID of worker job location")
    ),
    item(
      NAME = "DistanceToWork",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Distance from home to work assuming location at Bzone centroid and 'Manhattan' distance"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for LocateEmployment module
#'
#' A list containing specifications for the LocateEmployment module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source LocateEmployment.R script.
"LocateEmploymentSpecifications"
usethis::use_data(LocateEmploymentSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module places employment in Bzones based on input assumptions of
#employment by type and Bzone. The model adjusts the employment numbers to
#balance with the number of workers in the region. The module assigns workers
#to jobs as a function of the number of jobs in each Bzone and the inverse of
#distance between residence and employment Bzones. An iterative proportional
#fitting process is used to allocate the number of workers between each pair of
#Bzones. A worker table is created and workers are assigned randomly to
#employment Bzones based on the balanced matrix of number of workers by
#residence and employment Bzones.

#Function to adjust employment to match workers
#----------------------------------------------
#' Adjusts Bzone employment to match workers
#'
#' \code{adjustEmployment} adjusts Bzone employment by type so that total
#' employment matches total workers.
#'
#' The function adjusts the input values of employment by type and Bzone so that
#' the total amount of employment for the region equals the total number of
#' workers for the region.
#'
#' @param EmpTarget An number identifying the total number of jobs to be
#' matched.
#' @param Emp_ A numeric vector identifying the employment in each Bzone.
#' @param Names A character vector identifying names corresponding to the
#' Emp_ argument vector if any.
#' @return A integer vector of the number of jobs by Bzone which sums to the
#' total. The positions correspond to the positions of the input vector of jobs
#' by Bzone.
#' @name adjustEmployment
#' @export
adjustEmployment <- function(EmpTarget, Emp_, Names = NULL) {
  EmpProbs_ <- Emp_ / sum(Emp_)
  EmpBase_ <- floor(Emp_)
  EmpDiff <- EmpTarget - sum(EmpBase_)
  EmpAdd_ <- Emp_ * 0
  EmpDiff_Tbl <-
    table(sample(1:(length(Emp_)), abs(EmpDiff), replace = TRUE, prob = EmpProbs_))
  EmpAdd_[as.numeric(names(EmpDiff_Tbl))] <- EmpDiff_Tbl
  RevEmp_ <- EmpBase_ + (sign(EmpDiff) * EmpAdd_)
  if (!is.null(Names)) names(RevEmp_) <- Names
  RevEmp_
}

#Main module function that assigns workers to Bzone employment locations
#-----------------------------------------------------------------------
#' Main module function to assign employment by type to Bzones.
#'
#' \code{LocateEmployment} assigns workers to Bzones.
#'
#' This function assigns workers to Bzone employment based on inputs of
#' employment by type by Bzone, adjustment of employment to equal regionwide
#' total of workers, and identify Bzone employment location for each worker as
#' a function of the number of jobs in each Bzone and the inverse of distance
#' between Bzones.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name LocateEmployment
#' @import visioneval fields
#' @export
LocateEmployment <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  Bz <- L$Year$Bzone$Bzone

  #Balance employment and workers
  #------------------------------
  #Calculate the total number of workers for the region
  TotWkr <- sum(L$Year$Azone$NumWkr)
  #Calculate the total employment for the region
  TotEmp <- sum(L$Year$Bzone$TotEmp)
  #Calculate the difference between total workers and total employment
  TotEmpDiff <- TotWkr - TotEmp
  #Make initial adjustment of total employment by Bzone
  TotEmp_Bz <- L$Year$Bzone$TotEmp
  names(TotEmp_Bz) <- L$Year$Bzone$Bzone
  TotEmp_Bz <- adjustEmployment(EmpTarget = TotWkr, Emp_ = TotEmp_Bz, Names = Bz)

  #Balance work productions and attractions
  #----------------------------------------
  #Calculate distances between Bzones
  LngLat_df <-
    data.frame(
      lng = L$Year$Bzone$Longitude,
      lat = L$Year$Bzone$Latitude)
  Dist_BzBz <- rdist.earth(LngLat_df, LngLat_df, miles = TRUE, R = 6371)
  diag(Dist_BzBz) <- apply(Dist_BzBz, 1, function(x) min(x[x != 0]))
  rownames(Dist_BzBz) <- Bz
  colnames(Dist_BzBz) <- Bz
  #Tabulate workers by residence Bzone
  Wkr_Bz <- tapply(L$Year$Household$Workers, L$Year$Household$Bzone, sum)[Bz]
  Wkr_Bz[is.na(Wkr_Bz)] <- 0

  #Allocate workers by origin and destination using IPF
  #----------------------------------------------------
  #Use IPF with seed matrix that is inverse of distance between Bzones
  WkrOD_BzBz <-
    ipf(1 / Dist_BzBz, list(Wkr_Bz, TotEmp_Bz), list(1, 2))$Units_ar
  rownames(WkrOD_BzBz) <- Bz
  colnames(WkrOD_BzBz) <- Bz
  #Resolve fractional workers
  for (i in 1:nrow(WkrOD_BzBz)) {
    WkrOD_BzBz[i,] <- adjustEmployment(Wkr_Bz[i], WkrOD_BzBz[i,])
  }

  #Final adjustments to employment by Bzone
  #----------------------------------------
  #Total employment by Bzone
  TotEmp_Bz <- colSums(WkrOD_BzBz)
  #Calculate retail and service employment by Bzone
  RetEmp_Bz <-
    round(TotEmp_Bz * (L$Year$Bzone$RetEmp / L$Year$Bzone$TotEmp))
  SvcEmp_Bz <-
    round(TotEmp_Bz * L$Year$Bzone$SvcEmp / L$Year$Bzone$TotEmp)

  #Create worker table
  #-------------------
  #Identify households having workers
  Use <- L$Year$Household$Workers != 0
  #Create IDs for worker table
  HhId_ <- with(L$Year$Household, rep(HhId[Use], Workers[Use]))
  WkrId_ <-
    with(L$Year$Household,
         paste(
           rep(HhId[Use], Workers[Use]),
           unlist(sapply(Workers[Use], function(x) 1:x)),
           sep = "-"))
  #Identify worker job location Bzone
  ResBzone_ <- with(L$Year$Household, rep(Bzone[Use], Workers[Use]))
  WrkBzone_ <- character(TotWkr)
  for (bz in Bz) {
    WrkBzone_[ResBzone_ == bz] <- sample(rep(Bz, WkrOD_BzBz[bz,]))
  }
  #Identify distance to work
  DistToWork_ <- Dist_BzBz[cbind(ResBzone_, WrkBzone_)]
  #Identify work Azone
  WrkAzone_ <-
    L$Year$Bzone$Azone[match(WrkBzone_, L$Year$Bzone$Bzone)]
  #Identify work Marea
  WrkMarea_ <-
    L$Year$Bzone$Marea[match(WrkBzone_, L$Year$Bzone$Bzone)]

  #Return list of results
  #----------------------
  #Initialize output list
  Out_ls <- initDataList()
  #Add the employment by Bzone
  Out_ls$Year$Bzone$TotEmp <- as.integer(unname(TotEmp_Bz))
  Out_ls$Year$Bzone$RetEmp <- as.integer(unname(RetEmp_Bz))
  Out_ls$Year$Bzone$SvcEmp <- as.integer(unname(SvcEmp_Bz))
  #Create the worker table
  Out_ls$Year$Worker <- list()
  attributes(Out_ls$Year$Worker)$LENGTH <- sum(L$Year$Household$Workers)
  #Add the worker datasets
  Out_ls$Year$Worker$HhId <- HhId_
  attributes(Out_ls$Year$Worker$HhId)$SIZE <- max(nchar(HhId_))
  Out_ls$Year$Worker$WkrId <- WkrId_
  attributes(Out_ls$Year$Worker$WkrId)$SIZE <- max(nchar(WkrId_))
  Out_ls$Year$Worker$Bzone <- WrkBzone_
  attributes(Out_ls$Year$Worker$Bzone)$SIZE <- max(nchar(WrkBzone_))
  Out_ls$Year$Worker$Azone <- WrkAzone_
  attributes(Out_ls$Year$Worker$Azone)$SIZE <- max(nchar(WrkAzone_))
  Out_ls$Year$Worker$Marea <- WrkMarea_
  attributes(Out_ls$Year$Worker$Marea)$SIZE <- max(nchar(WrkMarea_))
  Out_ls$Year$Worker$DistanceToWork <- DistToWork_
  #Return the outputs list
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
#   ModuleName = "LocateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- LocateEmployment(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "LocateEmployment",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
