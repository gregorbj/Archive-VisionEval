#====================
#Simulate4DMeasures.R
#====================

#<doc>
#
## Simulates4DMeasures Module
#### February 6, 2019
#
#This module calculates several *4D* measures by SimBzone including density, diversity (i.e. mixing of land uses), and pedestrian-orientedn transportation network design. These measures are the same as or are similar to measures included in the Environmental Protection Agency's (EPA) [Smart Location Database](https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide).
#
### Model Parameter Estimation
#
#This module has no parameters. 4D measures are calculated based on Bzone attributes as described in the next section.
#
### How the Module Works
#
#This module calculates 2 development density measures that are named using the names used in the Smart Location Database (SLD): population density (D1B), employment density (D1C). Another density measure, activity density (D1D), is calculated during the process of SimBzone creation by the CreateSimBzones module. These density measures are calculated at the Bzone level. The population, employment, and activity (employment + households) values to calculate these measures come from the products of other modules. The area data comes from user inputs of the unprotected area (measured in acres) in urban (i.e. urbanized) and rural (i.e. not urbanized) portions of each Bzone.
#
#The module calculates 3 development diversity measures which measure the relative heterogeity of land uses in each Bzone. These too are named according to how the SLD names them. D2A_JPHH is the ratio of jobs to households in each Bzone. D2A_WRKEMP is the ratio of workers living in the zone to jobs located in the zone. D2A_EPHHM is an entropy measure calculated from the amount of activity in 4 categories, 3 employment categories (retail, service, other) measured by the number of jobs in the Bzone, and a household category. Entropy is measured on a scale 0 to 1 with 0 corresponding to the situation where only one activity category (or no activity) is present in the Bzone, and 1 corresponding to the situation where there are equal amounts of all activities in the Bzone. Where 2 or more activity categories are present in the Bzone, the entropy of the Bzone is calculated as follows:
#
#  `-sum(R * LogR) / log(NAct)`
#
#where:
#
#- `R` is a vector of the ratio of activity in each activity category divided by the total of all activity
#
#- `LogR` is the natural log of `R` or 0 for activity categories having no activity
#
#- `NAct` is the number of activity categories (i.e. 4)
#
#One pedestrian-oriented transportation network design measure is produced by the module. D3bpo4 is intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile. This is one of the network design measured in the Smart Location database. This measure is D3bpo4 is simulated as a function of the place type of the SimBzone (LocType, AreaType, DevType) and the average D3bpo4 value for the urbanized area (or town or rural area) where the SimBzone is located. A base average value by urbanized area and towns as a whole and rural areas as a whole in the CreateSimBzoneModels module. User inputs adjust the values (e.g. increase average by 50%). The D3bpo4 model estimated by the CreateSimBzoneModels module is used to calculate the SimBzone value.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. 4D measures are calculated based on Bzone
#attributes.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#' @import visioneval

#Define the data specifications
#------------------------------
Simulate4DMeasuresSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = items(
        "UrbanD3bpo4Adj",
        "TownD3bpo4Adj",
        "RuralD3bpo4Adj"
      ),
      FILE = "marea_d3bpo4_adj.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of base urban D3bpo4 value as tabulated from the EPA 2010 Smart Location Database for the urbanized portion of the marea",
        "Proportion of base town D3bpo4 value as tabulated from the EPA 2010 Smart Location Database for towns",
        "Proportion of base town D3bpo4 value as tabulated from the EPA 2010 Smart Location Database for rural areas"
        )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UzaProfileName",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
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
        "UrbanD3bpo4Adj",
        "TownD3bpo4Adj",
        "RuralD3bpo4Adj"
      ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
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
      NAME = "Pop",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
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
      NAME = "NumWkr",
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
          "UrbanArea",
          "TownArea",
          "RuralArea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE",
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "DevType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("emp", "mix", "res")
    ),
    item(
      NAME = "LocType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "D1B",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Gross population density (people/acre) on unprotected (i.e. developable) land in zone (Ref: EPA 2010 Smart Location Database)"
    ),
    item(
      NAME = "D1C",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "JOB/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Gross employment density (jobs/acre) on unprotected land (i.e. developable) land in zone (Ref: EPA 2010 Smart Location Database)"
    ),
    item(
      NAME = "D2A_JPHH",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "JOB/HH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of jobs to households in zone (Ref: EPA 2010 Smart Location Database)"
    ),
    item(
      NAME = "D2A_WRKEMP",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "PRSN/JOB",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of workers to jobs in zone (Ref: EPA 2010 Smart Location Database)"
    ),
    item(
      NAME = "D2A_EPHHM",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "employment & household entropy",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Employment and household entropy measure for zone considering numbers of households, retail jobs, service jobs, and other jobs (Ref: EPA 2010 Smart Location Database)"
    ),
    item(
      NAME = "D3bpo4",
      FILE = "bzone_network_design.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "pedestrian-oriented intersections per square mile",
      NAVALUE = -9999,
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile (Ref: EPA 2010 Smart Location Database)"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for Simulate4DMeasures module
#'
#' A list containing specifications for the Simulate4DMeasures module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source Simulate4DMeasures.R script.
"Simulate4DMeasuresSpecifications"
usethis::use_data(Simulate4DMeasuresSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module calculates several 4D measures by Bzone including density,
#diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#and destination accessibility.

#Function to simulate the D3bpo4 value
#-------------------------------------
#' Function which simulates D3bpo4 values for SimBzones
#'
#' \code{simulateD3bpo4} simulates D3bpo4 values for SimBzones
#'
#' This function simulates pedestrian network design measure, D3bpo4, as defined
#' by the U.S. Environmental Protection Agency (EPA) in the Smart Location
#' Database (SLD). SLD documentation is included in the inst/extdata/sources
#' directory of the VESimLandUseData package. In short, D3bpo4 is a measure of
#' 'intersection density in terms of pedestrian-oriented intersections having
#' four or more legs per square mile'. D3bpo4 is simulated as a function of the
#' place type of the SimBzone (LocType, AreaType, DevType) and the average
#' D3bpo4 value for the urbanized area (or town or rural area) where the
#' SimBzone is located. A base average value by urbanized area and towns as a
#' whole and rural areas as a whole in the CreateSimBzoneModels module. User
#' inputs adjust the values (e.g. increase average by 50%). The D3bpo4
#' model estimated by the CreateSimBzoneModels module is used to calculate the
#' SimBzone value.
#'
#' @param AveD3bpo4_ a numeric vector identifying for all the SimBzones_ the
#' average D3bpo4 value for the place where each SimBzone is located. For
#' urban locations it is the urbanized area. For town and rural places it is the
#' average value for towns and rural places respectively.
#' @param PlaceType_ a character vector identifying for all the SimBzones_ the
#' place type for each SimBzone. Place type is created by concatenating the
#' AreaType and DevType designations using a period (.) separator.
#' @param NormD3bpo4_PtQt a numeric matrix which tabulates normalized D3bpo4
#' values by place type and quantile. See the CreateSimBzoneModels
#' documentation.
#' @return A numeric vector containing D3bpo4 values for the SimBzones.
#' @export
simulateD3bpo4 <- function(AveD3bpo4_, PlaceType_, NormD3bpo4_PtQt) {
  NormD3bpo4_ <- sapply(PlaceType_, function(x) {
    sample(NormD3bpo4_PtQt[x,], 1)})
  NormD3bpo4_ * AveD3bpo4_
}


#Main module function that simulates 4D measures
#------------------------------------------------
#' Main module function that simulates 4D measures for each Bzone.
#'
#' \code{Simulate4DMeasures} simulates 4D measures for each Bzone.
#'
#' This module simulates several 4D measures by Bzone including density,
#' diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#' and destination accessibility.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name Simulate4DMeasures
#' @import visioneval
#' @export
Simulate4DMeasures <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define a vector of Bzones
  Bz <- L$Year$Bzone$Bzone
  #Create data frame of Bzone data
  D_df <- data.frame(L$Year$Bzone)
  D_df$Area <- D_df$UrbanArea + D_df$TownArea + D_df$RuralArea

  #Calculate density measures
  #--------------------------
  #Population density
  D1B_ <- with(D_df, Pop / Area)
  #Employment density
  D1C_ <- with(D_df, TotEmp / Area)

  #Calculate diversity measures
  #----------------------------
  #Ratio of employment to households
  D2A_JPHH_ <- with(D_df, TotEmp / NumHh)
  D2A_JPHH_[is.na(D2A_JPHH_) | is.infinite(D2A_JPHH_)] <- 0
  #Ratio of workers to employment
  D2A_WRKEMP_ <- with(D_df, NumWkr / TotEmp)
  D2A_WRKEMP_[is.na(D2A_WRKEMP_) | is.infinite(D2A_WRKEMP_)] <- 0
  #Employment and household entropy
  D_df$OthEmp <- with(D_df, TotEmp - RetEmp - SvcEmp)
  D_df$TotAct <- with(D_df, TotEmp + NumHh)
  calcEntropyTerm <- function(ActName) {
    Act_ <- D_df[[ActName]]
    ActRatio_ <- Act_ / D_df$TotAct
    LogActRatio_ <- ActRatio_ * 0
    LogActRatio_[Act_ != 0] <- log(Act_[Act_ != 0] / D_df$TotAct[Act_ != 0])
    ActRatio_ * LogActRatio_
  }
  E_df <- data.frame(
    Hh = calcEntropyTerm("NumHh"),
    Ret = calcEntropyTerm("RetEmp"),
    Svc = calcEntropyTerm("SvcEmp"),
    Oth = calcEntropyTerm("OthEmp")
  )
  A_ <- rowSums(E_df)
  N_ = apply(E_df, 1, function(x) sum(x != 0))
  D2A_EPHHM_ <- -A_ / log(N_)
  rm(E_df, A_, N_)

  #Calculate pedestrian network design measure
  #-------------------------------------------
  IsRural <- D_df$LocType == "Rural"
  IsTown <- D_df$LocType == "Town"
  IsUrban <- D_df$LocType == "Urban"
  #Calculate base average D3bpo4
  D_df$BaseD3 <- NA
  D_df$BaseD3[IsRural] <- rep(SimBzone_ls$RuProfiles$AveD3bpo4, sum(IsRural))
  D_df$BaseD3[IsTown] <- rep(SimBzone_ls$TnProfiles$AveD3bpo4, sum(IsTown))
  UzaName_ <-
    L$Global$Marea$UzaProfileName[match(D_df$Marea[IsUrban], L$Global$Marea$Marea)]
  D_df$BaseD3[IsUrban] <- SimBzone_ls$UaProfiles$AveD3bpo4_Ua[UzaName_]
  #Calculate D3 adjustment
  D3Adj_MaLt <-
    with(L$Year$Marea, cbind(UrbanD3bpo4Adj, TownD3bpo4Adj, RuralD3bpo4Adj))
  rownames(D3Adj_MaLt) <- L$Year$Marea$Marea
  colnames(D3Adj_MaLt) <- c("Urban", "Town", "Rural")
  getD3Adj <- function(Marea, LocType) D3Adj_MaLt[Marea, LocType]
  D_df$D3Adj <- mapply(getD3Adj, D_df$Marea, D_df$LocType)
  #Calculate D3bpo4
  D_df$D3bpo4 <- NA
  D_df$PlaceType <- with(D_df, paste(AreaType, DevType, sep = "."))
  D_df$D3bpo4[IsRural] <- simulateD3bpo4(
    AveD3bpo4_ = D_df$BaseD3[IsRural] * D_df$D3Adj[IsRural],
    PlaceType_ = D_df$PlaceType[IsRural],
    NormD3bpo4_PtQt = SimBzone_ls$RuProfiles$NormD3bpo4_PtQt
    )
  D_df$D3bpo4[IsTown] <- simulateD3bpo4(
    AveD3bpo4_ = D_df$BaseD3[IsTown] * D_df$D3Adj[IsTown],
    PlaceType_ = D_df$PlaceType[IsTown],
    NormD3bpo4_PtQt = SimBzone_ls$TnProfiles$NormD3bpo4_PtQt
  )
  D_df$D3bpo4[IsUrban] <- simulateD3bpo4(
    AveD3bpo4_ = D_df$BaseD3[IsUrban] * D_df$D3Adj[IsUrban],
    PlaceType_ = D_df$PlaceType[IsUrban],
    NormD3bpo4_PtQt = SimBzone_ls$UaProfiles$NormD3bpo4_PtQt
  )

  #Return list of results
  #----------------------
  #Initialize list
  Out_ls <- initDataList()
  #Populate with results
  Out_ls$Year$Bzone <- list(
    D1B = D1B_,
    D1C = D1C_,
    D2A_JPHH = D2A_JPHH_,
    D2A_WRKEMP = D2A_WRKEMP_,
    D2A_EPHHM = D2A_EPHHM_,
    D3bpo4 = D_df$D3bpo4
  )
  #Return the results
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("Simulate4DMeasures")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load packages and test functions
# library(filesstrings)
# library(visioneval)
# source("tests/scripts/test_functions.R")
# #Set up test environment
# load("data/SimBzone_ls.rda")
# TestSetup_ls <- list(
#   TestDataRepo = "../Test_Data/VE-State",
#   DatastoreName = "Datastore.tar",
#   LoadDatastore = TRUE,
#   TestDocsDir = "vestate",
#   ClearLogs = TRUE,
#   # SaveDatastore = TRUE
#   SaveDatastore = FALSE
# )
#setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "Simulate4DMeasures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- Simulate4DMeasures(L)
#
# load("data/SimBzone_ls.Rda")
# TestDat_ <- testModule(
#   ModuleName = "Simulate4DMeasures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
