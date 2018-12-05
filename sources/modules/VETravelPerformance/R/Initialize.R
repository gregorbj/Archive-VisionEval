#============
#Initialize.R
#============
#
#<doc>
#
## Initialize Module
#### November 24, 2018
#
#This module reads and processes roadway DVMT and operations inputs.
#
#The following input files are optional. If these data are not provided, the model calculates values based on default data included with the package and processed by the `LoadDefaultRoadDvmtValues.R` script.
#
#*
#The optional roadway DVMT inputs allow users to specify base year roadway DVMT by vehicle type and how the DVMT by type splits across road classes.
#
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#
#
#</doc>



#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
#library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no estimated parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
InitializeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "OtherOpsEffectiveness",
      GROUP = "Global",
      LENGTH = 5
    )
  ),
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "StateAbbrLookup",
      FILE = "region_base_year_hvytrk_dvmt.csv",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      SIZE = 2,
      PROHIBIT = "",
      ISELEMENTOF = c(
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI",
        "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI",
        "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC",
        "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT",
        "VT", "VA", "WA", "WV", "WI", "WY", "DC", "PR", "NA"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Postal code abbreviation of state where the region is located",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmtGrowthBasis",
      FILE = "region_base_year_hvytrk_dvmt.csv",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      SIZE = 10,
      PROHIBIT = "",
      ISELEMENTOF = c("Income", "Population"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Factor used to grow heavy truck DVMT from base year value",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmt",
      FILE = "region_base_year_hvytrk_dvmt.csv",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Average daily vehicle miles of travel on roadways in the region by heavy trucks during he base year",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmtUrbanProp",
      FILE = "region_base_year_hvytrk_dvmt.csv",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Proportion of Region heavy truck daily vehicle miles of travel occurring on urbanized area roadways",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "UzaNameLookup",
      FILE = "marea_base_year_dvmt.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      SIZE = 50,
      PROHIBIT = "",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Name of urbanized area in default tables corresponding to the Marea"
    ),
    item(
      NAME = "ComSvcDvmtGrowthBasis",
      FILE = "marea_base_year_dvmt.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      SIZE = 10,
      PROHIBIT = "",
      ISELEMENTOF = c("HhDvmt", "Income", "Population"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Factor used to grow commercial service vehicle DVMT in Marea from base year value"
    ),
    item(
      NAME = "HvyTrkDvmtGrowthBasis",
      FILE = "marea_base_year_dvmt.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      SIZE = 10,
      PROHIBIT = "",
      ISELEMENTOF = c("Income", "Population"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Factor used to grow heavy truck DVMT from base year value"
    ),
    item(
      NAME =
        items(
          "UrbanLdvDvmt",
          "UrbanHvyTrkDvmt"
        ),
      FILE = "marea_base_year_dvmt.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by light-duty vehicles during the base year",
          "Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by heavy trucks during he base year"
        )
    ),
    item(
      NAME =
        items(
          "LdvFwyArtDvmtProp",
          "LdvOthDvmtProp",
          "HvyTrkFwyDvmtProp",
          "HvyTrkArtDvmtProp",
          "HvyTrkOthDvmtProp",
          "BusFwyDvmtProp",
          "BusArtDvmtProp",
          "BusOthDvmtProp"
        ),
      FILE = "marea_dvmt_split_by_road_class.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeway or arterial roadways",
          "Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways",
          "Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
          "Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
          "Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways",
          "Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
          "Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
          "Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occuring on other roadways"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "RampMeterDeployProp",
        "IncidentMgtDeployProp",
        "SignalCoordDeployProp",
        "AccessMgtDeployProp",
        "OtherFwyOpsDeployProp",
        "OtherArtOpsDeployProp"),
      FILE = "marea_operations_deployment.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of freeway DVMT affected by ramp metering deployment",
        "Proportion of freeway DVMT affected by incident management deployment",
        "Proportion of arterial DVMT affected by signal coordination deployment",
        "Proportion of arterial DVMT affected by access management deployment",
        "Proportion of freeway DVMT affected by deployment of other user-defined freeway operations measures",
        "Proportion of arterial DVMT affected by deployment of other user-defined arterial operations measures"
      )
    ),
    item(
      NAME = "Level",
      FILE = "other_ops_effectiveness.csv",
      TABLE = "OtherOpsEffectiveness",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "NA",
      SIZE = 4,
      PROHIBIT = "",
      ISELEMENTOF = c("None", "Mod", "Hvy", "Sev", "Ext"),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Congestion levels: None = none, Mod = moderate, Hvy = heavy, Sev = severe, Ext = extreme",
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "Art_Rcr",
        "Art_NonRcr",
        "Fwy_Rcr",
        "Fwy_NonRcr"),
      FILE = "other_ops_effectiveness.csv",
      TABLE = "OtherOpsEffectiveness",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = "-1",
      SIZE = 0,
      PROHIBIT = c("< 0", "> 100"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Percentage reduction of recurring arterial delay that would occur with full deployment of other user-defined arterial operations measures",
        "Percentage reduction of non-recurring arterial delay that would occur with full deployment of other user-defined arterial operations measures",
        "Percentage reduction of recurring freeway delay that would occur with full deployment of other user-defined freeway operations measures",
        "Percentage reduction of non-recurring freeway delay that would occur with full deployment of other user-defined freeway operations measures"
      ),
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "FwyNoneCongChg",
        "FwyModCongChg",
        "FwyHvyCongChg",
        "FwySevCongChg",
        "FwyExtCongChg",
        "ArtNoneCongChg",
        "ArtModCongChg",
        "ArtHvyCongChg",
        "ArtSevCongChg",
        "ArtExtCongChg"),
      FILE = "marea_congestion_charges.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of no congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of moderate congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of heavy congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of severe congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of extreme congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of no congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of moderate congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of heavy congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of severe congestion",
        "Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of extreme congestion"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for Initialize module
#'
#' A list containing specifications for the Initialize module.
#'
#' @format A list containing 2 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#' }
#' @source Initialize.R script.
"InitializeSpecifications"
usethis::use_data(InitializeSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Main function processes optional user roadway DVMT parameters, checking whether
#they have inconsistencies and returns those that have values (i.e. not NA).

#Main module function that checks optional roadway DVMT parameters
#-----------------------------------------------------------------
#' Check and optional roadway base year DVMT parameters for consistency.
#'
#' \code{Initialize} checks optional roadway base year DVMT parameters for
#' consistency and returns those that have values (i.e. not NA). Errors are
#' returned for inconsistent values.
#'
#' This function processes optional user roadway base year DVMT inputs to check
#' that values are consistent. Errors are returned for inconsistent values.
#' The script checks whether proportions data that should sum to 1 does, whether
#' urbanized area lookup names are in the urbanized area table, and whether
#' base year DVMT data have consistent values.
#'
#' @param L A list containing data from preprocessing supplied optional input
#' files returned by the processModuleInputs function. This list has two
#' components: Errors and Data.
#' @return A list that is the same as the input list with an additional
#' Warnings component.
#' @import visioneval
#' @export
Initialize <- function(L) {

  #Set up
  #------
  #Initialize error and warnings message vectors
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Initialize output list with input values
  Out_ls <- L

  #Define function to check for NA values
  #--------------------------------------
  checkNA <- function(Names_, Geo) {
    Values_ls <- L$Data$Year[[Geo]][Names_]
    AllNA <- all(is.na(unlist(Values_ls)))
    AnyNA <- any(is.na(unlist(Values_ls)))
    NoNA <- !AnyNA
    SomeNotAllNA <- AnyNA & !AllNA
    list(None = NoNA, SomeNotAll = SomeNotAllNA)
  }

  #Define function to check and adjust proportions
  #-----------------------------------------------
  checkProps <- function(FieldNames_, UzaNames_, TypeName) {
    Err_ <- character(0)
    Warn_ <- character(0)
    Values_df <- data.frame(L$Data$Global$Marea[FieldNames_])
    for (i in 1:nrow(Values_df)) {
      Marea <- L$Data$Global$Marea$Geo[i]
      HasUzaName <- !(UzaNames_[i] %in% c(NA, ""))
      HasAllVals <- all(!(unlist(Values_df[i,]) %in% c(NA, "")))
      Complete <- HasUzaName | HasAllVals
      if (!Complete) {
        Msg <- paste0(
          "The 'marea_dvmt_split_by_road_class.csv' file has errors for ",
          TypeName, " inputs for Marea ", Marea, ". The DVMT inputs need to ",
          "be complete or they need to be omitted and a valid 'UzaNameLookup' ",
          "must be provided in the 'marea_base_year_dvmt.csv file'."
        )
        Err_ <- c(Err_, Msg)
        rm(Msg)      }
      if (HasAllVals) {
        SumDiff <- abs(1 - sum(Values_df[i,]))
        if (SumDiff >= 0.01) {
          Msg <- paste0(
            "Error in input values for ", TypeName, " inputs for Marea ", Marea,
            ". The sum of values is off by more than 1%. They should add up to 1."
          )
          Err_ <- c(Err_, Msg)
        }
        if (SumDiff > 0 & SumDiff < 0.01) {
          Msg <- paste0(
            "Warning regarding input values for ", TypeName, " inputs for Marea ", Marea,
            ". The sum of the values do not add up to 1 but are off by 1% or ",
            "less so they have been adjusted to add up to 1."
          )
          Warn_ <- c(Warn_, Msg)
          rm(Msg)
          Values_df[i,] <- Values_df[i,] / sum(Values_df[i,])
        }
      }
    }
    list(
      Values_ls = as.list(Values_df),
      Errors = Err_,
      Warnings = Warn_
    )
  }

  #Check consistency of Region base year heavy truck DVMT
  #------------------------------------------------------
  if (!is.null(L$Data$Global$Region)) {
    #Extract state abbreviation, population, and DVMT values
    State <- L$Data$Global$Region$StateAbbrLookup
    TrkDvmt <- L$Data$Global$Region$HvyTrkDvmt
    UrbanProp <- L$Data$Global$Region$HvyTrkDvmtUrbanProp
    #Check whether the inputs have values
    HasState <- !is.na(State) & State != ""
    HasTrkDvmt <- !is.na(TrkDvmt) & TrkDvmt != ""
    HasUrbanProp <- !is.na(UrbanProp) & UrbanProp != ""
    #Check completeness
    if (!HasState & (!HasTrkDvmt | !HasUrbanProp)) {
      Msg <- paste0(
        "The 'region_base_year_hvytrk_dvmt.csv' file is incomplete. A value ",
        "for 'StateAbbrLookup' must be provided if no value is provided for ",
        "'HvyTrkDvmt' or for 'HvyTrkDvmtUrbanProp'."
      )
      Errors_ <- c(Errors_, Msg)
      rm(Msg)
    }
    #Set missing values to NA values in the outputs and clean up
    if (!HasState) {
      Out_ls$Data$Global$Region$StateAbbrLookup <- NA
    }
    if (!HasTrkDvmt) {
      Out_ls$Data$Global$Region$HvyTrkDvmt <- NA
    }
    if (!HasTrkDvmt) {
      Out_ls$Data$Global$Region$HvyTrkDvmtUrbanProp <- NA
    }
    rm(State, TrkDvmt, HasState, HasTrkDvmt, HasUrbanProp)
  }

  #Check consistency of Marea base year DVMT
  #-----------------------------------------
  #Extract values
  UzaName <- L$Data$Global$Marea$UzaNameLookup
  LdvDvmt <- L$Data$Global$Marea$UrbanLdvDvmt
  TrkDvmt <- L$Data$Global$Marea$UrbanHvyTrkDvmt
  #Check whether the inputs have values
  HasUzaName <- !is.na(UzaName) & UzaName != ""
  HasLdvDvmt <- !is.na(LdvDvmt) & LdvDvmt != ""
  HasTrkDvmt <- !is.na(TrkDvmt) & TrkDvmt != ""
  #Check whether urbanized area names are correct
  Ua <- names(RoadDvmtModel_ls$UzaLDVDvmtPC_Ua)
  if (any(HasUzaName) & !all(UzaName[HasUzaName] %in% Ua)) {
    Wrong_ <- UzaName[HasUzaName][!(UzaName[HasUzaName] %in% Ua)]
    Msg <- paste0(
      "The 'marea_base_year_dvmt.csv' file has errors. The following urbanized ",
      "area names listed in the 'UzaNameLookup' field are not recognized ",
      "urbanized area names -- ", paste(Wrong_, collapse = ", "),
      " -- Check the VERoadPerformance package documentation to find the list ",
      "of recognized names."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg, Wrong_)
  }
  #Check that required inputs are provided for all Mareas
  if (any(!(HasLdvDvmt & HasTrkDvmt) & !HasUzaName)) {
    Msg <- paste0(
      "The 'marea_base_year_dvmt.csv' file is incomplete. For each Marea, either ",
      "an urbanized area name must be provided in the 'UzaNameLookup' field or ",
      "DVMT values must be provided in the 'UrbanLdvDvmt' and the ",
      "'UrbanHvyTrkDvmt' fields for the Marea."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Set all missing values as NA
  Out_ls$Data$Global$Marea$UzaNameLookup[UzaName == ""] <- NA
  Out_ls$Data$Global$Marea$UrbanLdvDvmt[LdvDvmt == ""] <- NA
  Out_ls$Data$Global$Marea$UrbanHvyTrkDvmt[TrkDvmt == ""] <- NA
  rm(UzaName, LdvDvmt, TrkDvmt, HasUzaName, HasLdvDvmt, HasTrkDvmt, Ua)

  #Check and adjust roadway DVMT proportions for vehicle types
  #-----------------------------------------------------------
  #Extra the urbanized area names and the allowed names
  UzaNames_ <- L$Data$Global$Marea$UzaNameLookup
  Ua <- names(RoadDvmtModel_ls$UzaLDVDvmtPC_Ua)
  #Check the light-duty vehicle DVMT proportions by road class
  FieldNames_ <- c("LdvFwyArtDvmtProp", "LdvOthDvmtProp")
  if (all(FieldNames_ %in% names(Out_ls$Data$Global$Marea))) {
    CheckResults_ls <-
      checkProps(FieldNames_, UzaNames_, "Ldv")
    Out_ls$Data$Global$Marea[FieldNames_] <- CheckResults_ls$Values_ls
    Errors_ <- c(Errors_, CheckResults_ls$Errors)
    Warnings_ <- c(Warnings_, CheckResults_ls$Warnings)
  } else {
    Msg <- paste0(
      "The 'marea_dvmt_split_by_road_class.csv' input file is present but ",
      "does not contain all the required light-duty vehicle fields. The ",
      "required fields are 'LdvFwyArtDvmtProp' and 'LdvOthDvmtProp'."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Check the heavy truck DVMT proportions by road class
  FieldNames_ <- c("HvyTrkFwyDvmtProp", "HvyTrkArtDvmtProp", "HvyTrkOthDvmtProp")
  if (all(FieldNames_ %in% names(Out_ls$Data$Global$Marea))) {
    CheckResults_ls <-
      checkProps(FieldNames_, UzaNames_, "HvyTrk")
    Out_ls$Data$Global$Marea[FieldNames_] <- CheckResults_ls$Values_ls
    Errors_ <- c(Errors_, CheckResults_ls$Errors)
    Warnings_ <- c(Warnings_, CheckResults_ls$Warnings)
  } else {
    Msg <- paste0(
      "The 'marea_dvmt_split_by_road_class.csv' input file is present but ",
      "does not contain all the required heavy truck fields. The ",
      "required fields are 'HvyTrkFwyDvmtProp', 'HvyTrkArtDvmtProp', and ",
      "'HvyTrkOthDvmtProp'."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Check the bus DVMT proportions by road class
  FieldNames_ <- c("BusFwyDvmtProp", "BusArtDvmtProp", "BusOthDvmtProp")
  if (all(FieldNames_ %in% names(Out_ls$Data$Global$Marea))) {
    CheckResults_ls <-
      checkProps(FieldNames_, UzaNames_, "Bus")
    Out_ls$Data$Global$Marea[FieldNames_] <- CheckResults_ls$Values_ls
    Errors_ <- c(Errors_, CheckResults_ls$Errors)
    Warnings_ <- c(Warnings_, CheckResults_ls$Warnings)
  } else {
    Msg <- paste0(
      "The 'marea_dvmt_split_by_road_class.csv' input file is present but ",
      "does not contain all the required bus fields. The required fields are ",
      "'BusFwyDvmtProp', 'BusArtDvmtProp', and 'BusOthDvmtProp'."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }

  #Add Errors and Warnings to Out_ls and return
  #--------------------------------------------
  Out_ls$Errors <- Errors_
  Out_ls$Warnings <- Warnings_
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
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- Initialize(TestDat_)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )

