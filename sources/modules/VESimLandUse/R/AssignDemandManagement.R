#========================
#AssignDemandManagement.R
#========================
#
#<doc>
#
## AssignDemandManagement Module
#### February 10, 2019
#
#This module assigns demand management program participation to households and to workers. Households are assigned to individualized marketing program participation. Workers are assigned to employee commute options participation. The module computes the net proportional reduction in household DVMT based on the participation in travel demand management programs.
#
### Model Parameter Estimation
#
#This module uses the model parameters estimated by the AssignDemandMangement module in the VELandUse package. These include parameters for the proportional reduction in household vehicle miles traveled (VMT) for worker participation in employee commute options (ECO) program and for household participation in an individualized marketing program (IMP). The default VMT reduction values are contained in the *tdm_parameters.csv* file in the *inst/extdata* directory of the VELandUse package: 9% for IMP, and 5.4% for ECO. Documentation for those values is in the accompanying *tdm_parameters.txt* file of that package.
#
#A model is also estimated to predict the proportion of household VMT in work tours. The percentage reduction in household VMT as a function of employee commute options programs depends on the number of household workers participating and the proportion of household travel in work tours. A relationship between household size, the number of household workers, and the proportion of household DVMT in work tours is calculated using the *HhTours_df* dataset from the VE2001NHTS package. The following table show the tabulations of total miles, work tour miles, and work tour miles per worker by household size. The proportion of household miles in work tours per household workers is computed from these data.
#
#<tab:TdmModel_ls$PropMilesPerWkr_df>
#
### How the Module Works
#Users provide inputs on the proportion of households residing in each Marea and area type who participate in individualized marketing programs (IMP) and the proportion of workers working in each Marea and area type who participate in employee commute options (ECO) programs. These proportions are used in random draws to determine whether a household is an IMP program participant and whether a worker is an ECO program participant. The number of workers is participating is summed for each household.
#
#The proportional reduction in the DVMT of each household is calculated for IMP program participation and ECO program participation and the maximum of those is used. The maximum value is used rather than combining the values of the two programs because it is likely that there is a substantial amount of overlap in what these programs accomplish. The proportional reduction in VMT due to IMP participation is simply the value specified in the *tdm_parameters.csv* file. The proportional reduction in VMT due to ECO participation is product of the proportional reduction in VMT specified in the *tdm_parameters.csv*, the modeled proportion of household VMT in work travel per worker for the household size, and the number of workers who participate.
#
#</doc>

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module uses model parameter estimated by the AssignDemandManagement module
#in the VELandUse package. It has parameters for the proportional reduction in
#household DVMT for worker participation in employee commute options program and
#for household participation in individualized marketing program participation.
#Household VMT is reduced based on whether the household is participating in an
#individualized marketing program and whether it has workers participating in
#ECO programs. If the household is participating in an individualized marketing
#program then no additional reduction is credited if any household workers
#participate in ECO programs.
#' @import visioneval
#' @import VELandUse

#Load the TDM model data from the VELandUse package
#--------------------------------------------------
TdmModel_ls <- VELandUse::TdmModel_ls

#Save the TDM model data
#-----------------------
#' Travel demand management models
#'
#' A list of components used to predict the reduction in household DVMT as a
#' consequence of participation in individualized marketing programs and
#' employee commute options programs
#'
#' @format A list containing two vectors:
#' \describe{
#'  \item{PropDvmtReduce}{named vector of the proportional reduction in DVMT due to TDM program participation (names are ECO and IMP)}
#'  \item{PropMilesPerWkr}{named vector of the ratio of work tour DVMT per worker to total DVMT (names are household size 1 to 8)}
#'  }
#' @source AssignDemandManagement.R
"TdmModel_ls"
usethis::use_data(TdmModel_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignDemandManagementSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = items(
          "CenterEcoProp",
          "InnerEcoProp",
          "OuterEcoProp",
          "FringeEcoProp",
          "CenterImpProp",
          "InnerImpProp",
          "OuterImpProp",
          "FringeImpProp"),
      FILE = "marea_travel-demand-mgt_by_area-type.csv",
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
          "Proportion of workers working in center area type in Marea who participate in strong employee commute options program",
          "Proportion of workers working in inner area type in Marea who participate in strong employee commute options program",
          "Proportion of workers working in outer area type in Marea who participate in strong employee commute options program",
          "Proportion of workers working in fringe area type in Marea who participate in strong employee commute options program",
          "Proportion of households residing in center area type in Marea who participate in strong individualized marketing program",
          "Proportion of households residing in inner area type in Marea who participate in strong individualized marketing program",
          "Proportion of households residing in outer area type in Marea who participate in strong individualized marketing program",
          "Proportion of households residing in fringe area type in Marea who participate in strong individualized marketing program"
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
      NAME = items(
        "CenterEcoProp",
        "InnerEcoProp",
        "OuterEcoProp",
        "FringeEcoProp",
        "CenterImpProp",
        "InnerImpProp",
        "OuterImpProp",
        "FringeImpProp"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
      NAME = "AreaType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("center", "inner", "outer", "fringe")
    ),
    item(
      NAME = items(
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
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
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
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "Marea",
        "Bzone"),
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
      NAME = "IsIMP",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Identifies whether household is participant in travel demand management individualized marketing program (IMP): 1 = yes, 0 = no"
    ),
    item(
      NAME = "PropTdmDvmtReduction",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = "NA",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Proportional reduction in household DVMT due to participation in travel demand management programs"
    ),
    item(
      NAME = "IsECO",
      TABLE = "Worker",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "binary",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c(0, 1),
      SIZE = 0,
      DESCRIPTION = "Identifies whether worker is a participant in travel demand management employee commute options program: 1 = yes, 0 = no"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignDemandManagement module
#'
#' A list containing specifications for the AssignDemandManagement module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignDemandManagement.R script.
"AssignDemandManagementSpecifications"
usethis::use_data(AssignDemandManagementSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns participation in travel demand management (TDM) programs
#to households and workers. Based on the assignments, it calculates the
#proportion decrease in household daily vehicle miles traveled (DVMT) due to
#program participation.

#Main module function that determines TDM participation and effect on DVMT
#-------------------------------------------------------------------------
#' Main module function to assign TDM participation and effect on DVMT.
#'
#' \code{AssignDemandManagement} assigns households and workers to
#' participation in TDM programs and calculates the proportional reduction in
#' household DVMT due to this participation.
#'
#' This function assigns households and workers to participation in TDM programs
#' and calculates the proportional reduction in household DVMT due to this
#' participation.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name AssignDemandManagement
#' @import visioneval stats
#' @export
AssignDemandManagement <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Naming vectors
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Number of households and workers
  NumHh <- length(L$Year$Household$HhId)
  NumWkr <- length(L$Year$Worker$HhId)
  #Indexes from Bzone to Households and to Workers
  BzToHh_ <- match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)
  BzToWk_ <- match(L$Year$Worker$Bzone, L$Year$Bzone$Bzone)
  #Initialize lists to hold outputs
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    IsIMP = integer(NumHh)
  )
  Out_ls$Year$Worker <- list(
    PropTdmDvmtReduction = integer(NumWkr),
    IsECO = integer(NumWkr)
  )
  #Identify area type of households and workers
  AreaType_Hh <- L$Year$Bzone$AreaType[BzToHh_]
  AreaType_Wk <- L$Year$Bzone$AreaType[BzToWk_]

  #Put ECO and IMP participation proportions in matrices
  #-----------------------------------------------------
  #ECO participation proportion
  ECO_MaAt <- cbind(
    center = L$Year$Marea$CenterEcoProp,
    inner = L$Year$Marea$InnerEcoProp,
    outer = L$Year$Marea$OuterEcoProp,
    fringe = L$Year$Marea$FringeEcoProp
  )
  rownames(ECO_MaAt) <- L$Year$Marea$Marea
  #IMP participation proportion
  IMP_MaAt <- cbind(
    center = L$Year$Marea$CenterImpProp,
    inner = L$Year$Marea$InnerImpProp,
    outer = L$Year$Marea$OuterImpProp,
    fringe = L$Year$Marea$FringeImpProp
  )
  rownames(IMP_MaAt) <- L$Year$Marea$Marea

  #---------------------------------------------------
  #Iterate through Mareas and assign TDM participation
  #---------------------------------------------------

  #Assign IMP participation
  #------------------------
  #Assign IMP proportions to households
  ImpProp_Hh <-
    mapply(function(x,y) IMP_MaAt[x,y], L$Year$Household$Marea, AreaType_Hh)
  #Assign households to IMP participation
  IsIMP_Hh <- as.integer(runif(NumHh) < ImpProp_Hh)

  #Assign ECO participation
  #------------------------
  #Assign ECO proportions to workers
  EcoProp_Wk <-
    mapply(function(x,y) ECO_MaAt[x,y], L$Year$Worker$Marea, AreaType_Wk)
  #Assign workers to ECO participation
  IsECO_Wk <- as.integer(runif(NumWkr) < EcoProp_Wk)
  #Tabulate the number of ECO participating workers by household
  NumEcoWkr_Hx <- tapply(IsECO_Wk, L$Year$Worker$HhId, sum)
  NumEcoWkr_Hh <- integer(NumHh)
  NumEcoWkr_Hh[match(names(NumEcoWkr_Hx), L$Year$Household$HhId)] <- NumEcoWkr_Hx
  NumEcoWkr_Hh[is.na(NumEcoWkr_Hh)] <- 0

  #Calculate household DVMT proportional reduction
  #-----------------------------------------------
  #Calculate the proportion of household DVMT that is worker DVMT per worker
  HhSizeIdx_ <- L$Year$Household$HhSize
  HhSizeIdx_[HhSizeIdx_ > 8] <- 8
  PropMilesPerWkr_Hh <- TdmModel_ls$PropMilesPerWkr[HhSizeIdx_]
  #Calculate the proportional reduction in DVMT due to ECO participation
  EcoDvmtReduction_Hh <-
    PropMilesPerWkr_Hh * NumEcoWkr_Hh * TdmModel_ls$PropDvmtReduce["ECO"]
  #Calculate the proportional reduction in DVMT due to IMP participation
  ImpDvmtReduction_Hh <- IsIMP_Hh * TdmModel_ls$PropDvmtReduce["IMP"]
  #Reduction is the maximum of the ECO and IMP reductions
  TdmDvmtReduction_Hh <- pmax(EcoDvmtReduction_Hh, ImpDvmtReduction_Hh)

  #Return list of results
  #----------------------
  Out_ls <- initDataList()
  Out_ls$Year$Household <- list(
    IsIMP = as.integer(IsIMP_Hh),
    PropTdmDvmtReduction = TdmDvmtReduction_Hh
  )
  Out_ls$Year$Worker <- list(
    IsECO = as.integer(IsECO_Wk)
  )
  Out_ls
}

#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("AssignDemandManagement")

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
#   TestDataRepo = "../Test_Data/VE-RSPM",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "verspm",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
# setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "AssignDemandManagement",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- AssignDemandManagement(L)

# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "AssignDemandManagement",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

