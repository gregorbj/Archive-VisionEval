#============
#Initialize.R
#============
# This module processes optional roadway DVMT and operations inputs. The
# optional roadway DVMT inputs allow users to specify base year roadway DVMT
# by vehicle type and how the DVMT by type splits across road classes. If these
# data are not provided, the model calculates values based on default data.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
library(visioneval)


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
      TABLE = "Fuel",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "Fuel",
      TABLE = "Fuel",
      GROUP = "Global",
      FILE = "model_fuel_co2.csv",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      SIZE = 12,
      ISELEMENTOF = c("ULSD", "Biodiesel", "RFG", "CARBOB", "Ethanol", "Cng", "Electricity"),
      DESCRIPTION = "The fuel type for which the CO2 equivalent emissions are calculated"
    ),
    item(
      NAME = "Intensity",
      TABLE = "Fuel",
      GROUP = "Global",
      FILE = "model_fuel_co2.csv",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Multipliers used to convert fuel use to CO2 equivalent emissions"
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

  #Check if Power Co2 value is in the model_fuel_co2.csv
  #------------------------------------------------------
  if(!"Electricity" %in% L$Global$Fuel$Fuel){
    Msg <- paste("The value of carbon intensity for Electricity",
                  "is not supplied in 'model_fuel_co2.csv' so",
                  "using the default values for carbon intensity")
    Warnings_ <- c(Warnings_, Msg)
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
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
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
#   DoRun = TRUE,
#   RunFor = "NotBaseYear")

