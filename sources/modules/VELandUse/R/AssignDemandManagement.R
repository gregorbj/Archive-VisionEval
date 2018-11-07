#========================
#AssignDemandManagement.R
#========================
#
#<doc>
#
## AssignDemandManagement Module
#### November 6, 2018
#
#This module assigns demand management program participation to households and to workers. Households are assigned to individualized marketing program participation. Workers are assigned to employee commute options participation. The module computes the net proportional reduction in household DVMT based on the participation in travel demand management programs.
#
### Model Parameter Estimation
#
#This module has parameters for the proportional reduction in household vehicle miles traveled (VMT) for worker participation in employee commute options (ECO) program and for household participation in an individualized marketing program (IMP). The default VMT reduction values are contained in the *tdm_parameters.csv* file in the *inst/extdata* directory of this package: 9% for IMP, and 5.4% for ECO. Documentation for those values is in the accompanying *tdm_parameters.txt* file.
#
#A model is also estimated to predicts the proportion of household VMT in work tours. The percentage reduction on household VMT as a function of employee commute options programs depends on the number of household workers participating and the proportion of household travel in work tours. A relationship between household size, the number of household workers, and the proportion of household DVMT in work tours is calculated using the *HhTours_df* dataset from the VE2001NHTS package. The following table show the tabulations of total miles, work tour miles, and work tour miles per worker by household size. The proportion of household miles in work tours per household workers is computed from these data.
#
#<tab:TdmModel_ls$PropMilesPerWkr_df>
#
### How the Module Works
#Users provide inputs on the proportion of households residing in each Bzone who participate in individualized marketing programs (IMP) and the proportion of workers working in each Bzone who participate in employee commute options (ECO) programs. These proportions are used in random draws to determine whether a household is an IMP program participant and whether a worker is an ECO program participant. The number of workers is participating is summed for each household.
#
#The proportional reduction in the DVMT of each household is calculated for IMP program participation and ECO program participation and the maximum of those is used. The maximum value is used rather than combining the values of the two programs because it is likely that there is a substantial amount of overlap in what these programs accomplish. The proportional reduction in VMT due to IMP participation is simply the value specified in the *tdm_parameters.csv* file. The proportional reduction in VMT due to ECO participation is product of the proportional reduction in VMT specified in the *tdm_parameters.csv*, the modeled proportion of household VMT in work travel per worker for the household size, and the number of workers who participate.
#
#</doc>

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has parameters for the proportional reduction in household DVMT for
#worker participation in employee commute options program and for household
#participation in individualized marketing program participation. Household VMT
#is reduced based on whether the household is participating in an individualized
#marketing program and whether it has workers participating in ECO programs. If
#the household is participating in an individualized marketing program then no
#additional reduction is credited if any household workers participate in ECO
#programs.

#----------------------------------
#Rates of DVMT reduction by program
#----------------------------------
#The rate of reduction in household VMT for IMP programs is the rate
#found from Oregon studies (9%). The rate of reduction for ECO programs on
#commute VMT is taken from the "Moving Cooler" technical appendix (Table 5.13,
#p. B-54) for medium size urban areas, 5.4%.

#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Parameter",
    TYPE = "character",
    PROHIBIT = "NA",
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME = "Value",
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
TdmParameters_df <-
  processEstimationInputs(
    Inp_ls,
    "tdm_parameters.csv",
    "AssignDemandManagement.R")
PropDvmtReduce_ <- TdmParameters_df$Value
names(PropDvmtReduce_) <- c("ECO", "IMP")
TdmModel_ls <- list(
  PropDvmtReduce = PropDvmtReduce_
)
rm(Inp_ls, TdmParameters_df, PropDvmtReduce_)

#-------------------------------------------------------
#Estimate the proportion of household DVMT in work tours
#-------------------------------------------------------
#The percentage reduction on household VMT as a function of employee commute
#options programs depends on the number of household workers participating and
#the proportion of household travel in work tours. A relationship between
#household size, the number of household workers, and the proportion of
#household DVMT in work tours is calculated using the NHTS 2001 data below. The
#relationship that is computed is the ratio of DVMT per worker to total
#household DVMT by household size.

#Sum work tour distance and non-work tour distance by household
#--------------------------------------------------------------
#A data frame is created which calculates household vehicle tour information
#by household including tabulations of total tour mileage, work tour mileage,
#work tour mileage per worker, number of workers, and household size
TourMiles_df <- local({
  NhtsTours_df <- VE2001NHTS::HhTours_df
  NhtsHouseholds_df <- VE2001NHTS::Hh_df
  IsHhVehTour_ <- with(NhtsTours_df, Mode %in% c("Auto", "LtTrk"))
  VehTours_df <- NhtsTours_df[IsHhVehTour_,]
  TourMiles_Hh <-
    with(VehTours_df, tapply(Distance, Houseid, sum))
  Hh <- names(TourMiles_Hh)
  WorkTourMiles_Hh <-
    with(VehTours_df, tapply(Distance * IncludesWork, Houseid, sum))[Hh]
  NonWorkTourMiles_Hh <-
    with(VehTours_df, tapply(Distance * !IncludesWork, Houseid, sum))[Hh]
  NumWkr_ <- NhtsHouseholds_df$Wrkcount
  names(NumWkr_) <- NhtsHouseholds_df$Houseid
  NumWkr_Hh <- NumWkr_[Hh]
  LifeCycle_ <- NhtsHouseholds_df$Lif_cyc
  names(LifeCycle_) <- NhtsHouseholds_df$Houseid
  HhSize_ <- NhtsHouseholds_df$Hhsize
  names(HhSize_) <- NhtsHouseholds_df$Houseid
  HhSize_Hh <- HhSize_[Hh]
  data.frame(
    Houseid = Hh,
    Total = unname(TourMiles_Hh),
    Work = unname(WorkTourMiles_Hh),
    WorkPerWorker = unname(WorkTourMiles_Hh / HhSize_[Hh]),
    NumWkr = NumWkr_Hh,
    HhSize = HhSize_Hh
  )
})

#Split household tour summary data frame by household size
#---------------------------------------------------------
#Create vector of household size category
HhSizeCat_ <- TourMiles_df$HhSize
#Assign households with more than 8 persons to 8
#table(HhSizeCat_)
HhSizeCat_[HhSizeCat_ > 8] <- 8
#Split tour data frame by household size category
TourMiles_ls <- split(TourMiles_df, HhSizeCat_)
#Sum values by household size category and put results in matrix
TourMiles_SzX <- do.call(rbind, lapply(TourMiles_ls, function(x) {
  c(Total = sum(x$Total), Work = sum(x$Work), WorkPerWorker = sum(x$WorkPerWorker), N = nrow(x))
}))

#Calculate ratio of work DVMT per worker to total household DVMT by household size
#---------------------------------------------------------------------------------
PropMilesPerWkr_Sz <- TourMiles_SzX[,"WorkPerWorker"] / TourMiles_SzX[,"Total"]
#PropMilesPerWkr_Sz
#plot(1:8, PropMilesPerWkr_Sz, type = "b")
TdmModel_ls$PropMilesPerWkr <- PropMilesPerWkr_Sz
#Make table to document
TdmModel_ls$PropMilesPerWkr_df <- data.frame(
  "Household_Size" = rownames(TourMiles_SzX),
  "Total_Miles" = round(TourMiles_SzX[,"Total"]),
  "Work_Tour_Miles" = round(TourMiles_SzX[,"Work"]),
  "Work_Miles_Per_Worker" = round(TourMiles_SzX[,"WorkPerWorker"]),
  "Prop._Per_Worker" = round(unname(PropMilesPerWkr_Sz), 3),
  "N" = TourMiles_SzX[,"N"]
  )
rm(TourMiles_df, TourMiles_ls, TourMiles_SzX, HhSizeCat_, PropMilesPerWkr_Sz)

#-----------------------
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
          "EcoProp",
          "ImpProp"),
      FILE = "bzone_travel_demand_mgt.csv",
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
          "Proportion of workers working in Bzone who participate in strong employee commute options program",
          "Proportion of households residing in Bzone who participate in strong individualized marketing program")
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
      NAME = items(
          "EcoProp",
          "ImpProp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
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
#' \code{AssignParkingRestrictions} assigns households and workers to
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
#' @import visioneval stats
#' @export
AssignDemandManagement <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  BzToHh_ <- match(L$Year$Household$Bzone, L$Year$Bzone$Bzone)
  BzToWk_ <- match(L$Year$Worker$Bzone, L$Year$Bzone$Bzone)
  NumHh <- length(BzToHh_)
  NumWkr <- length(BzToWk_)

  #Assign IMP and ECO participation
  #--------------------------------
  #Assign households to IMP participation
  IsIMP_Hh <- runif(NumHh) < L$Year$Bzone$ImpProp[BzToHh_]
  #Assign workers to ECO participation
  IsECO_Wk <- runif(NumWkr) < L$Year$Bzone$EcoProp[BzToWk_]
  #Tabulate the number of ECO participating workers by household
  NumEcoWkr_Hh <-
    tapply(IsECO_Wk, L$Year$Worker$HhId, sum)[L$Year$Household$HhId]
  NumEcoWkr_Hh[is.na(NumEcoWkr_Hh)] <- 0

  #Calculate household DVMT proportional reduction
  #-----------------------------------------------
  #Calculate the proportion of household DVMT that worker DVMT per worker
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
# TestDat_ <- testModule(
#   ModuleName = "AssignDemandManagement",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignDemandManagement",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

