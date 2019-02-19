#============
#Initialize.R
#============
#
#<doc>
#
## Initialize Module
#### January 27, 2019
#
#This module reads and processes roadway DVMT and operations inputs to check for inconsistent values which standard VisionEval data checks will not pick up.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#This module checks the values in the following input files for missing values and inconsistencies that the standard VisionEval data checks will not identify:
#
#* region_base_year_hvytrk_dvmt.csv
#
#* marea_base_year_dvmt.csv
#
#* marea_dvmt_split_by_road_class.csv
#
#* marea_operations_deployment.csv
#
#* other_ops_effectiveness.csv
#
#* marea_congestion_charges.csv
#
#The `region_base_year_hvytrk_dvmt.csv` and `marea_base_year_dvmt.csv` files are checked to assure that there is enough information to compute base year urban heavy truck DVMT and base year urban light-duty vehicle DVMT. These values are used in the calculation of vehicle travel on urban area roads which is are used in road performance calculations. The values in the 2 files are also checked for consistency. These inputs enable users to either declare explict values for regional heavy truck DVMT, marea urban heavy truck DVMT, and marea urban light-duty vehicle DVMT, or to specify locations (state and/or urbanized area) which are used for calculating DVMT from per capita rates tabulated for the areas from Highway Statistics data by the LoadDefaultRoadDvmtValues.R script. In addition, a check is made on if the model is likely to be a metropolitan model, not a state model, but a state is specified and state per capita heavy truck DVMT rates are used to calculate regional heavy truck DVMT. The value for StateAbbrLookup in the 'region_base_year_hvytrk_dvmt.csv' file should be NA in metropolitan models rather than a specific state if the regional heavy truck DVMT is not provided because the state rates may not be representative of the metropolitan rates. A warning is issued if this is the case.
#
#If a value, rather than NA, is provided in the `StateAbbrLookup` field of the `region_base_year_hvytrk_dvmt.csv` file, the value must be a standard 2-character postal code for the state.
#
#If a value other than NA is provided in the `UzaNameLookup` field of the `marea_base_year_dvmt.csv` file, it must be a name that is present in the following list of urbanized areas for which per capita rates are available for urban area light-duty vehicle DVMT and for urban area heavy-truck DVMT. Note that if the name of an urbanized area is not found in the list, the user can specify the name of any other urbanized area that is representative of the urbanized area being modeled.
#
#<tab:UzaDvmtNames_ls$Table>
#
#The `marea_dvmt_split_by_road_class.csv` input file specifies the proportions of DVMT by road class for light-duty vehicles, for heavy trucks, and for buses. While this file is not optional, the user may leave entries blank. Where values are not provided, the model computes the splits using data tabulated for urbanized areas from Highway Statistics data by the LoadDefaultRoadDvmtValues.R script. The UzaNameLookup must be specified in the 'marea_base_year_dvmt.csv' for any marea for which complete data are not specified. The procedures check whether values are present for each marea or can be computed using name lookups. If values are provided, the procedures check that the sum of the splits for each vehicle type are equal to 1. If the sum is off by 1% or more, an error is flagged and a message to the log identifies the problem. If the sum is off by less than 1%, the splits are adjusted so that they sum to 1 and a warning message is written to the log. Input values are updated using values calculated from name lookups where necessary.
#
#The `marea_operations_deployment.csv` and `other_ops_effectiveness.csv` are checked for consistency if the `other_ops_effectiveness.csv` file, which is optional, is present. If the `other_ops_effectiveness.csv` file is not present, then the values for the 'OtherFwyOpsDeployProp' and 'OtherArtOpsDeployProp' fields of the `marea_operations_deployment.csv` must be zero. If the `other_ops_effectiveness.csv` file is present but the values for delay reduction for freeways and/or arterials are 0, then the respective freeway and arterial values in the `marea_operations_deployment.csv` file must be 0 as well.
#
#The `marea_congestion_charges.csv` is checked to determine whether congestion charges increase with congestion level (if they are not 0). If higher charges are found at lower levels than at higher levels, warnings are written to the log identifying the issue.
#
#</doc>


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no estimated parameters. The following code documents
#urbanized area names for urbanized area default data.

#Create a list of recognized urbanized area names and data frame to display
#--------------------------------------------------------------------------
UzaDvmtNames_ls <- list()
#Create a vector of urbanized area names ordered by state and name
load("data/RoadDvmtModel_ls.rda")
Ua <- names(RoadDvmtModel_ls$UzaLDVDvmtPC_Ua)
Ua_mx <- do.call(rbind, strsplit(Ua, "/"))
UzaNames_ <- Ua[order(Ua_mx[,2], Ua_mx[,1])]
UzaDvmtNames_ls$Names <- UzaNames_
rm(Ua, Ua_mx)
#Make a matrix having 3 columns
UzaNamesPad_ <- c(UzaNames_, rep("", 3 - (length(UzaNames_) %% 3)))
UzaNames_mx <- matrix(UzaNamesPad_, ncol = 3, byrow = TRUE)
#Make a data frame having 3 columns of the names
UzaDvmtNames_df <- data.frame(UzaNames_mx)
names(UzaDvmtNames_df) <- c("Column 1", "Column 2", "Column 3")
UzaDvmtNames_ls$Table <- UzaDvmtNames_df
rm(UzaNames_, UzaNamesPad_, UzaNames_mx, UzaDvmtNames_df)

#Save the urbanized area names list
#----------------------------------
#' Urbanized area names list
#'
#' A list containing the names of urbanized areas included in the profiles of
#' urbanized area DVMT characteristics.
#'
#' @format A list containing 2 components:
#' \describe{
#'  \item{Names}{a vector of urbanized area names sorted by state and name}
#'  \item{Table}{a 3-column data frame of the names to include in documentation}
#' }
#' @source Initialize.R script.
"UzaDvmtNames_ls"
usethis::use_data(UzaDvmtNames_ls, overwrite = TRUE)


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
      FILE = "region_base_year_dvmt.csv",
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
        "VT", "VA", "WA", "WV", "WI", "WY", "DC", "PR", NA),
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Postal code abbreviation of state where the region is located. It is recommended that the value be NA if the model is not a state model (i.e. is a model for a metropolitan area). See the module documentation for details."
    ),
    item(
      NAME = "HvyTrkDvmtGrowthBasis",
      FILE = "region_base_year_dvmt.csv",
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
        "Factor used to grow heavy truck DVMT from base year value"
    ),
    item(
      NAME = "HvyTrkDvmt",
      FILE = "region_base_year_dvmt.csv",
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
      DESCRIPTION = "Average daily vehicle miles of travel on roadways in the region by heavy trucks during the base year. The value for this input may be NA instead of number. In that case, if a state abbreviation is provided, the base year value is calculated from the state per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year population. If the state abbreviation is NA (as for a metropolitan model) the base year value is calculated from metropolitan area per capita rates and metropolitan area population."
    ),
    item(
      NAME = "ComSvcDvmtGrowthBasis",
      FILE = "region_base_year_dvmt.csv",
      TABLE = "Region",
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
      NAME = "UzaNameLookup",
      FILE = "marea_base_year_dvmt.csv",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      SIZE = 50,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Name(s) of urbanized area(s) in default tables corresponding to the Marea(s). This may be omitted if values are provided for both UrbanLdvDvmt and UrbanHvyTrkDvmt. The name(s) must be consistent with names in the urbanized area names in the default data. See module documentation for a listing."
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
          "Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by light-duty vehicles during the base year. This value may be omitted if a value for UzaNameLookup is provided so that a value may be computed from the urbanized area per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year urban population.",
          "Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by heavy trucks during he base year. This value may be omitted if a value for UzaNameLookup is provided so that a value may be computed from the urbanized area per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year urban population."
        )
    ),
    item(
      NAME =
        items(
          "LdvFwyDvmtProp",
          "LdvArtDvmtProp",
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
          "Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
          "Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
          "Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways",
          "Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
          "Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
          "Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways",
          "Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
          "Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
          "Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occuring on other roadways"
        )
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
      PROHIBIT = c("< 0", "> 1", "NA"),
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
      UNITS = "percentage",
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
#' @name Initialize
#' @import visioneval
#' @export
Initialize <- function(L) {

  #------
  #Set up
  #------
  #Initialize error and warnings message vectors
  Errors_ <- character(0)
  Warnings_ <- character(0)
  #Initialize output list with input values
  Out_ls <- L[c("Errors", "Warnings", "Data")]

  #--------------------------------------
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

  #-----------------------------------------------
  #Define function to check and adjust proportions
  #-----------------------------------------------
  checkProps <- function(FieldNames_, UzaNames_, Ua, TypeName) {
    Err_ <- character(0)
    Warn_ <- character(0)
    Values_df <- data.frame(L$Data$Global$Marea[FieldNames_])
    for (i in 1:nrow(Values_df)) {
      Marea <- L$Data$Global$Marea$Geo[i]
      if (Marea != "None") {
        HasUzaName <- UzaNames_[i] %in% Ua
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
        if (!HasAllVals & HasUzaName) {
          Vals_ <- RoadDvmtModel_ls$UzaRcProps_UaVtRc[UzaNames_[i], TypeName,]
          if (TypeName == "LDV") {
            Values_df[i, "LdvFwyDvmtProp"] <- Vals_["Fwy"]
            Values_df[i, "LdvArtDvmtProp"] <- Vals_["Art"]
            Values_df[i, "LdvOthDvmtProp"] <- Vals_["Oth"]
          }
          if (TypeName == "HvyTrk") {
            Values_df[i, "HvyTrkFwyDvmtProp"] <- Vals_["Fwy"]
            Values_df[i, "HvyTrkArtDvmtProp"] <- Vals_["Art"]
            Values_df[i, "HvyTrkOthDvmtProp"] <- Vals_["Oth"]
          }
          if (TypeName == "Bus") {
            Values_df[i, "BusFwyDvmtProp"] <- Vals_["Fwy"]
            Values_df[i, "BusArtDvmtProp"] <- Vals_["Art"]
            Values_df[i, "BusOthDvmtProp"] <- Vals_["Oth"]
          }
        }
      } else {
        Values_df[i,] <- 0
      }
    }
    list(
      Values_ls = as.list(Values_df),
      Errors = Err_,
      Warnings = Warn_
    )
  }

  #-----------------------------------------------------------
  #Check and adjust roadway DVMT proportions for vehicle types
  #-----------------------------------------------------------
  #Extract the urbanized area names and the allowed names
  UzaNames_ <- L$Data$Global$Marea$UzaNameLookup
  Ua <- rownames(RoadDvmtModel_ls$UzaRcProps_UaVtRc)
  #Check the light-duty vehicle DVMT proportions by road class
  FieldNames_ <- c("LdvFwyDvmtProp", "LdvArtDvmtProp", "LdvOthDvmtProp")
  if (all(FieldNames_ %in% names(Out_ls$Data$Global$Marea))) {
    CheckResults_ls <-
      checkProps(FieldNames_, UzaNames_, Ua, "LDV")
    Out_ls$Data$Global$Marea[FieldNames_] <- CheckResults_ls$Values_ls
    Errors_ <- c(Errors_, CheckResults_ls$Errors)
    Warnings_ <- c(Warnings_, CheckResults_ls$Warnings)
  } else {
    Msg <- paste0(
      "The 'marea_dvmt_split_by_road_class.csv' input file is present but ",
      "does not contain all the required light-duty vehicle fields. The ",
      "required fields are 'LdvFwyDvmtProp', 'LdvArtDvmtProp' and 'LdvOthDvmtProp'."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Check the heavy truck DVMT proportions by road class
  FieldNames_ <- c("HvyTrkFwyDvmtProp", "HvyTrkArtDvmtProp", "HvyTrkOthDvmtProp")
  if (all(FieldNames_ %in% names(Out_ls$Data$Global$Marea))) {
    CheckResults_ls <-
      checkProps(FieldNames_, UzaNames_, Ua, "HvyTrk")
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
      checkProps(FieldNames_, UzaNames_, Ua, "Bus")
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

  #---------------------------------------------------------------------
  #Check region and marea base year heavy truck DVMT and light-duty DVMT
  #---------------------------------------------------------------------
  #Identify which year values correspond to base year in Get data
  IsBaseYear <- L$Get$Year$Marea$Year == getModelState("BaseYear")
  #Make a data frame of Marea data to use in checks and calculations
  Marea_df <- data.frame(
    Name = L$Data$Global$Marea$Geo,
    LookupName = L$Data$Global$Marea$UzaNameLookup,
    UrbanHvyTrkDvmt = L$Data$Global$Marea$UrbanHvyTrkDvmt,
    UrbanLdvDvmt = L$Data$Global$Marea$UrbanLdvDvmt
  )
  #Identify whether there is an Marea called 'None'
  IsNone <- Marea_df$Name == "None"
  #If any IsNone, then check whether urban heavy truck and LDV DVMT are NA
  #substitute 0 if so and warn
  if (any(IsNone)) {
    if (is.na(Marea_df[IsNone, "UrbanHvyTrkDvmt"])) {
      Marea_df[IsNone, "UrbanHvyTrkDvmt"] <- 0
      Msg <- paste0(
        "Warning for the 'marea_base_year_dvmt.csv' input file. ",
        "The value for 'UrbanHvyTrkDvmt' for Marea 'None' must be 0, ",
        "because 'None' represents areas that have no urbanized area. ",
        "The value in the file is NA or missing and 0 will be substituted ",
        "when the data is loaded into the datastore."
      )
      Errors_ <- c(Errors_, Msg)
      rm(Msg)
    }
    if (is.na(Marea_df[IsNone, "UrbanLdvDvmt"])) {
      Marea_df[IsNone, "UrbanLdvDvmt"] <- 0
      Msg <- paste0(
        "Warning for the 'marea_base_year_dvmt.csv' input file. ",
        "The value for 'UrbanLdvDvmt' for Marea 'None' must be 0, ",
        "because 'None' represents areas that have no urbanized area. ",
        "The value in the file is NA or missing and 0 will be substituted ",
        "when the data is loaded into the datastore."
      )
      Errors_ <- c(Errors_, Msg)
      rm(Msg)
    }
  }
  #If any IsNone, then check whether urban heavy truck and LDV DVMT are a value
  #other than 0 and error if so
  if (any(IsNone)) {
    if (Marea_df[IsNone, "UrbanHvyTrkDvmt"] != 0) {
      Msg <- paste0(
        "Error in the 'marea_base_year_dvmt.csv' input file. ",
        "The value for 'UrbanHvyTrkDvmt' for Marea 'None' must be 0, ",
        "because 'None' represents areas that have no urbanized area."
      )
      Errors_ <- c(Errors_, Msg)
      rm(Msg)
    }
    if (Marea_df[IsNone, "UrbanLdvDvmt"] != 0) {
      Msg <- paste0(
        "Error in the 'marea_base_year_dvmt.csv' input file. ",
        "The value for 'UrbanLdvDvmt' for Marea 'None' must be 0, ",
        "because 'None' represents areas that have no urbanized area."
      )
      Errors_ <- c(Errors_, Msg)
      rm(Msg)
    }
  }
  #Check whether the urbanized area names are recognized
  Ua <- names(RoadDvmtModel_ls$UzaHvyTrkDvmtPC_Ua)
  IsValidLookup <- Marea_df$LookupName %in% Ua
  #Check whether marea heavy truck DVMT data are complete
  HasHvyTrkDvmt <- !is.na(Marea_df$UrbanHvyTrkDvmt)
  FullySpecdHvyTrk <- IsValidLookup | HasHvyTrkDvmt
  if (any(!FullySpecdHvyTrk)) {
    Msg <- paste0(
      "The 'marea_base_year_dvmt.csv' file is incomplete. For each Marea, either ",
      "an urbanized area name must be provided in the 'UzaNameLookup' field or ",
      "DVMT values must be provided in the the 'UrbanHvyTrkDvmt' field for the Marea."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Check whether marea light-duty vehicle DVMT data are complete
  HasLdvDvmt <- !is.na(Marea_df$UrbanLdvDvmt)
  FullySpecdLdv <- IsValidLookup | HasLdvDvmt
  if (any(!FullySpecdLdv)) {
    Msg <- paste0(
      "The 'marea_base_year_dvmt.csv' file is incomplete. For each Marea, either ",
      "an urbanized area name must be provided in the 'UzaNameLookup' field or ",
      "DVMT values must be provided in the the 'UrbanLdvDvmt' field for the Marea."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Check whether region heavy truck data are complete
  RegionHvyTrkDvmt <- L$Data$Global$Region$HvyTrkDvmt
  State <- L$Data$Global$Region$StateAbbrLookup
  if (is.na(RegionHvyTrkDvmt) & is.na(State) & !all(FullySpecdHvyTrk)) {
    Msg <- paste0(
      "Region heavy truck DVMT can't be calculated from data in the ",
      "'region_base_year_hvytrk_dvmt.csv' file and the 'marea_base_year_dvmt.csv ",
      "files. Either a value needs to be provided in the 'HvyTrkDvmt' field of ",
      "'region_base_year_dvmt.csv' file or the state abbreviation must be ",
      "provided in the 'StateAbbrLookup' field of that file, or ",
      "complete information needs to be provided in the ",
      "'marea_base_year_dvmt.csv' file. ",
      "Consult error messages in the log for additional details."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  #Flag a warning if not a state model but state abbreviation provided
  State <- L$Data$Global$Region$StateAbbrLookup
  if (!any(IsNone) & !is.na(State)) {
    Msg <- paste0(
      "Because there is no Marea name of 'None', this looks to be a ",
      "metropolitan model rather than a state model. ",
      "There could be mismatch of regional and urban area heavy truck DVMT ",
      "because a state name abbreviation has been specified in the ",
      "StateAbbrLookup field of the 'region_base_year_dvmt.csv' file ",
      "rather than NA. Because of that, if regional heavy truck DVMT has not ",
      "been specified, it will be calculated from the state per capita heavy ",
      "truck DVMT rate and the regional population for the model. ",
      "This may not be representative for the region and will ",
      "affect all future year heavy truck DVMT calculations for the region. ",
      "It is suggested that you either specify a region heavy truck DVMT ",
      "value, or that you set the value of the StateAbbrLookup field as NA. ",
      "In the latter case, the regional heavy truck DVMT will be computed from ",
      "the Marea per capita rates of heavy truck DVMT and the Marea total ",
      "population."
    )
    Warnings_ <- c(Warnings_, Msg)
    rm(Msg)
  }

  #--------------------------------------------------------------
  #Check that operations programs are not applied in marea "None"
  #--------------------------------------------------------------
  #Deployment proportion must be 0 for marea "None"
  OpsNames_ <- c(
    "RampMeterDeployProp", "IncidentMgtDeployProp", "SignalCoordDeployProp",
    "AccessMgtDeployProp", "OtherFwyOpsDeployProp", "OtherArtOpsDeployProp"
  )
  Ma <- L$Data$Year$Marea$Geo
  if (any(Ma == "None")) {
    NoneOpsProp_df <- data.frame(L$Data$Year$Marea[OpsNames_])[Ma == "None",]
    HasNon0Ops_ <- apply(NoneOpsProp_df, 1, function(x) any(x != 0))
    if (any(HasNon0Ops_)) {
      Msg <- paste0(
        "Error in the 'marea_operations_deployment.csv' input file. ",
        "Values for marea 'None' must be 0 because the effects of operations ",
        "programs are only analyzed for urbanized areas and the 'None' marea ",
        "contains no urbanized areas."
      )
      Errors_ <- c(Errors_, Msg)
      rm(Msg)
    }
    rm(NoneOpsProp_df, HasNon0Ops_)
  }
  rm(OpsNames_, Ma)

  #------------------------------------------------
  #Check consistency of other operations deployment
  #------------------------------------------------
  HasOthOpsEff <- !is.null(L$Data$Global$OtherOpsEffectiveness)
  if (HasOthOpsEff) {
    OthOps_ls <- L$Data$Global$OtherOpsEffectiveness
    HasNoArtOthOpsEff <-
      all(OthOps_ls$Art_Rcr == 0) & all(OthOps_ls$Art_NonRcr == 0)
    HasNoFwyOthOpsEff <-
      all(OthOps_ls$Fwy_Rcr == 0) & all(OthOps_ls$Fwy_NonRcr == 0)
  } else {
    HasNoArtOthOpsEff <- TRUE
    HasNoFwyOthOpsEff <- TRUE
  }
  OthFwyOps <- L$Data$Year$Marea$OtherFwyOpsDeployProp
  OthArtOps <- L$Data$Year$Marea$OtherArtOpsDeployProp
  if (any(OthFwyOps != 0) & HasNoFwyOthOpsEff) {
    Msg <- paste0(
      "There are values for 'OtherFwyOpsDeployProp' in the ",
      "'marea_operations_deployment.csv' input file that are not 0, ",
      "but either the 'other_ops_effectiveness.csv' optional input file is not ",
      "present or all the values in the 'Fwy_Rcr' and 'Fwy_NonRcr' fields ",
      "of that file are 0. This inconsistency must be corrected. Unless you ",
      "are sure of what you are doing, it is recommended that the ",
      "'other_ops_effectiveness.csv' file not be provided and that the values for ",
      "'OtherFwyOpsDeployProp' in the 'marea_operations_deployment.csv' be 0."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  if (any(OthArtOps != 0) & HasNoArtOthOpsEff) {
    Msg <- paste0(
      "There are values for 'OtherArtOpsDeployProp' in the ",
      "'marea_operations_deployment.csv' input file that are not 0, ",
      "but either the 'other_ops_effectiveness.csv' optional input file is not ",
      "present or all the values in the 'Art_Rcr' and 'Art_NonRcr' fields ",
      "of that file are 0. This inconsistency must be corrected. Unless you ",
      "are sure of what you are doing, it is recommended that the ",
      "'other_ops_effectiveness.csv' file not be provided and that the values for ",
      "'OtherArtOpsDeployProp' in the 'marea_operations_deployment.csv' be 0."
    )
    Errors_ <- c(Errors_, Msg)
    rm(Msg)
  }
  rm(HasOthOpsEff, HasNoArtOthOpsEff, HasNoFwyOthOpsEff, OthFwyOps, OthArtOps)

  #---------------------------------------------------------------
  #Check that congestion charges increase with congestion severity
  #---------------------------------------------------------------
  #Make data frames of congestion charges ordered by congestion level
  CongLvlNames_ <- c("None", "Mod", "Hvy", "Sev", "Ext")
  ArtCongChgNames_ <- paste0("Art", CongLvlNames_, "CongChg")
  FwyCongChgNames_ <- paste0("Fwy", CongLvlNames_, "CongChg")
  ArtCongChg_df <- data.frame(L$Data$Year$Marea[ArtCongChgNames_])
  FwyCongChg_df <- data.frame(L$Data$Year$Marea[FwyCongChgNames_])
  #Check that arterial congestion charges increase with congestion level
  if (any(apply(ArtCongChg_df, 1, function(x) any(diff(x) < 0)))) {
    Msg <- paste0(
      "Some arterial congestion charges are lower at higher congestion levels ",
      "than at lower congestion levels. Is this what you intend?"
    )
    Warnings_ <- c(Warnings_, Msg)
    rm(Msg)
  }
  #Check that freeway congestion charges increase with congestion level
  if (any(apply(FwyCongChg_df, 1, function(x) any(diff(x) < 0)))) {
    Msg <- paste0(
      "Some freeway congestion charges are lower at higher congestion levels ",
      "than at lower congestion levels. Is this what you intend?"
    )
    Warnings_ <- c(Warnings_, Msg)
    rm(Msg)
  }
  rm(CongLvlNames_, ArtCongChgNames_, FwyCongChgNames_, ArtCongChg_df, FwyCongChg_df)

  #--------------------------------------------
  #Add Errors and Warnings to Out_ls and return
  #--------------------------------------------
  Out_ls$Errors <- Errors_
  Out_ls$Warnings <- Warnings_
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("Initialize")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# #Load libraries and test functions
# library(visioneval)
# library(filesstrings)
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
# # setUpTests(TestSetup_ls)
# #Run test module
# TestDat_ <- testModule(
#   ModuleName = "Initialize",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_
# R <- Initialize(L)
