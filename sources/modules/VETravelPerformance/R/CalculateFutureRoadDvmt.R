#=========================
#CalculateFutureRoadDvmt.R
#=========================
#This module calculates future year roadway DVMT by vehicle type (light-duty,
#heavy truck, bus) and the distribution of roadway DVMT by vehicle type to
#roadway classes (freeway, arterial, other).


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(stringr)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#The estimated model parameters for this module are created in the
#LoadDefaultValues.R script.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateFutureRoadDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "HvyTrkDvmtUrbanProp",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HvyTrkDvmtGrowthBasis",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = c("Income", "Population"),
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmtIncomeFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      PROHIBIT = "<= 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HvyTrkDvmtPopulationFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = "<= 0",
      ISELEMENTOF = ""
    ),
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
      NAME = "ComSvcDvmtGrowthBasis",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = c("HhDvmt", "Income", "Population")
    ),
    item(
      NAME = "HvyTrkDvmtGrowthBasis",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = c("Income", "Population")
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
          "BusOthDvmtProp"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "ComSvcDvmtHhDvmtFactor",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = "<= 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("ComSvcDvmtIncomeFactor",
              "HvyTrkDvmtIncomeFactor"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("ComSvcDvmtPopulationFactor",
              "HvyTrkDvmtPopulationFactor"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LdvRoadDvmtLdvDemandRatio",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "ratio",
      PROHIBIT = c("NA", "<= 0"),
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
        "VanDvmt",
        "BusDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "RuralPop",
        "UrbanPop"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "RuralIncome",
        "UrbanIncome"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "UrbanHhDvmt",
        "RuralHhDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = items(
        "HvyTrkUrbanDvmt",
        "HvyTrkRuralDvmt"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Base year Region heavy truck daily vehicle miles of travel in urbanized areas",
        "Base year Region heavy truck daily vehicle miles of travel in rural (i.e. non-urbanized) areas")
    ),
    item(
      NAME =
        items("ComSvcUrbanDvmt",
              "ComSvcRuralDvmt",
              "HvyTrkUrbanDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Commercial service daily vehicle miles of travel associated with Marea urbanized household activity",
        "Commercial service daily vehicle miles of travel associated with Marea rural household activity",
        "Heavy truck daily vehicle miles of travel on urbanized area roadways in the Marea"
      )
    ),
    item(
      NAME =
        items(
          "LdvFwyArtDvmt",
          "LdvOthDvmt",
          "HvyTrkFwyDvmt",
          "HvyTrkArtDvmt",
          "HvyTrkOthDvmt",
          "BusFwyDvmt",
          "BusArtDvmt",
          "BusOthDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeway or arterial roadways",
        "Light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways",
        "Heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
        "Heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
        "Heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways",
        "Bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways",
        "Bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways",
        "Bus daily vehicle miles of travel in the urbanized portion of the Marea occuring on other roadways"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateFutureRoadDvmt module
#'
#' A list containing specifications for the CalculateFutureRoadDvmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateFutureRoadDvmt.R script.
"CalculateFutureRoadDvmtSpecifications"
usethis::use_data(CalculateFutureRoadDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Main function calculates base year DVMT by vehicle type and by vehicle type
#and road class for each Marea. It also assigns DVMT proportions by vehicle type
#and road class from the default data for the urbanized area if the user hasn't
#supplied inputs for these quantities.

#Main module function that assigns base year DVMT
#------------------------------------------------
#' Assign base year DVMT by vehicle type and road class for Mareas
#'
#' \code{CalculateBaseRoadDvmt} calculates base year DVMT on roadways within the
#' urbanized portions of Mareas by vehicle type (light-duty vehicle,
#' heavy truck, bus) and road class (freeway, arterial, other). It computes
#' some other values as explained in the details.
#'
#' This function calculates several values necessary for calculating road
#' performance and vehicle energy consumption and emissions. These include
#' calculating base year daily vehicle miles of travel (DVMT) by vehicle type
#' (light-duty, heavy truck, bus), and jointly by vehicle type and road class
#' (freeway, arterial, other) for roadways in the urbanized proportions in
#' Mareas. The function also computes required parameters used for calculating
#' future year DVMT by vehicle type and road class. If region-level inputs have
#' been provided (region_base_year_hvytrk_dvmt.csv), the function computes base
#' year heavy truck DVMT and ratios of heavy truck DVMT to total region
#' population and income. The function calculates base year commercial service
#' light-duty vehicle (LDV) DVMT and ratios of that DVMT to population, and
#' income by Marea. If the user has not provided a base year input for LDV DVMT
#' on urbanized area roads in an Marea, that DVMT is calculated based on the
#' base year urbanized area population and default values of LDV DVMT per capita
#' for the urbanized area. The ratio of LDV urbanized area road DVMT to total
#' DVMT of households residing in the urbanized area, commercial service LDV
#' associated with resident households, and public transit LDV DVMT is
#' calculated for each Marea. This ratio is used to calculate future year LDV
#' roadway DVMT from total urbanized area LDV demand. If the user has not
#' provided base year urbanized area heavy truck roadway DVMT for an Marea, the
#' function computes that value using a default value of heavy truck DVMT per
#' capita for the urbanized area and the base year urbanized area population.
#' The ratios of urbanized area heavy truck road DVMT to urbanized area
#' population and urbanized area income are calculated to use in calculating
#' future year heavy truck DVMT. If the user has not provided inputs for the
#' DVMT proportions of each vehicle type by road class, the function calculates
#' those proportions from default data for the urbanized area. Using those DVMT
#' proportions, the function computes urbanized area roadway DVMT by vehicle
#' type and road class.
#'
#' @param L A list containing data defined by the module specification.
#' @return A list containing data produced by the function consistent with the
#' module specifications.
#' @name CalculateFutureRoadDvmt
#' @import visioneval
#' @export
CalculateFutureRoadDvmt <- function(L) {
  #Set up
  #------
  Out_ls <- initDataList()
  Out_ls$Year$Region <- list()
  Out_ls$Year$Marea <- list()

  #Calculate Region HvyTrk DVMT if region table was input
  #------------------------------------------------------
  #Check if Region HvyTrk data exists
  HvyTrkDvmtGrowthBasis <- L$Global$Region$HvyTrkDvmtGrowthBasis
  HasRegionHvyTrk <- !is.null(HvyTrkDvmtGrowthBasis)
  #If the Region HvyTrk data exists, calculate Region urban HvyTrk DVMT
  if (HasRegionHvyTrk) {
    Pop <- sum(unlist(L$Year$Marea[c("RuralPop", "UrbanPop")]))
    Inc <- sum(unlist(L$Year$Marea[c("RuralIncome", "UrbanIncome")]))
    if (HvyTrkDvmtGrowthBasis == "Population") {
      HvyTrkDvmt <- Pop * L$Global$Region$HvyTrkDvmtPopulationFactor
    }
    if (HvyTrkDvmtGrowthBasis == "Income") {
      HvyTrkDvmt <- Inc * L$Global$Region$HvyTrkDvmtIncomeFactor
    }
    HvyTrkUrbanDvmt <- HvyTrkDvmt * L$Global$Region$HvyTrkDvmtUrbanProp
    HvyTrkRuralDvmt <- HvyTrkDvmt - HvyTrkUrbanDvmt
    Out_ls$Year$Region$HvyTrkUrbanDvmt <- HvyTrkUrbanDvmt
    Out_ls$Year$Region$HvyTrkRuralDvmt <- HvyTrkRuralDvmt
    rm(HvyTrkDvmtGrowthBasis, Pop, Inc, HvyTrkDvmt)
  #If not, then save NA values
  } else {
    Out_ls$Year$Region$HvyTrkUrbanDvmt <- NA
    Out_ls$Year$Region$HvyTrkRuralDvmt <- NA
  }

  #Calculate ComSvc DVMT
  #---------------------
  Ma <- L$Year$Marea$Marea
  ComSvcDvmtGrowthBasis_Ma <- L$Global$Marea$ComSvcDvmtGrowthBasis
  ComSvcUrbanDvmt_Ma <- numeric(length(Ma))
  ComSvcRuralDvmt_Ma <- numeric(length(Ma))
  IsDvmtBasis_Ma <- ComSvcDvmtGrowthBasis_Ma == "HhDvmt"
  IsPopBasis_Ma <- ComSvcDvmtGrowthBasis_Ma == "Population"
  IsIncBasis_Ma <- ComSvcDvmtGrowthBasis_Ma == "Income"
  if (any(IsDvmtBasis_Ma)) {
    ComSvcUrbanDvmt_Ma[IsDvmtBasis_Ma] <-
      L$Year$Marea$UrbanHhDvmt[IsDvmtBasis_Ma] *
      L$Global$Marea$ComSvcDvmtHhDvmtFactor[IsDvmtBasis_Ma]
    ComSvcRuralDvmt_Ma[IsDvmtBasis_Ma] <-
      L$Year$Marea$RuralHhDvmt[IsDvmtBasis_Ma] *
      L$Global$Marea$ComSvcDvmtHhDvmtFactor[IsDvmtBasis_Ma]
  }
  if (any(IsPopBasis_Ma)) {
    ComSvcUrbanDvmt_Ma[IsPopBasis_Ma] <-
      L$Year$Marea$UrbanPop[IsPopBasis_Ma] *
      L$Global$Marea$ComSvcDvmtPopulationFactor[IsPopBasis_Ma]
    ComSvcRuralDvmt_Ma <-
      L$Year$Marea$RuralPop[IsPopBasis_Ma] *
      L$Global$Marea$ComSvcDvmtPopulationFactor[IsPopBasis_Ma]
  }
  if (any(IsIncBasis_Ma)) {
    ComSvcUrbanDvmt_Ma[IsIncBasis_Ma] <-
      L$Year$Marea$UrbanIncome[IsIncBasis_Ma] *
      L$Global$Marea$ComSvcDvmtIncomeFactor[IsIncBasis_Ma]
    ComSvcRuralDvmt_Ma[IsIncBasis_Ma] <-
      L$Year$Marea$RuralIncome[IsIncBasis_Ma] *
      L$Global$Marea$ComSvcDvmtIncomeFactor[IsIncBasis_Ma]
  }
  rm(ComSvcDvmtGrowthBasis_Ma, IsDvmtBasis_Ma, IsPopBasis_Ma, IsIncBasis_Ma)
  Out_ls$Year$Marea$ComSvcUrbanDvmt <- unname(ComSvcUrbanDvmt_Ma)
  Out_ls$Year$Marea$ComSvcRuralDvmt <- unname(ComSvcRuralDvmt_Ma)

  #Calculate Marea LDV DVMT
  #------------------------
  #Calculate total urban area LDV DVMT demand
  VanDvmt_Ma <- L$Year$Marea$VanDvmt
  TotLdvDvmt_Ma <-
    L$Year$Marea$UrbanHhDvmt + ComSvcUrbanDvmt_Ma + VanDvmt_Ma
  #Calculate LDV road DVMT
  LdvRoadDvmt_Ma <- TotLdvDvmt_Ma * L$Global$Marea$LdvRoadDvmtLdvDemandRatio
  rm(VanDvmt_Ma, TotLdvDvmt_Ma)

  #Calculate Marea heavy truck DVMT
  #--------------------------------
  #Calculate quantities without region controls
  HvyTrkDvmtGrowthBasis_Ma <- L$Global$Marea$HvyTrkDvmtGrowthBasis
  HvyTrkUrbanDvmt_Ma <- numeric(length(Ma))
  IsPopBasis_Ma <- HvyTrkDvmtGrowthBasis_Ma == "Population"
  IsIncBasis_Ma <- HvyTrkDvmtGrowthBasis_Ma == "Income"
  if (any(IsPopBasis_Ma)) {
    HvyTrkUrbanDvmt_Ma <-
      L$Year$Marea$UrbanPop * L$Global$Marea$HvyTrkDvmtPopulationFactor
  }
  if (any(IsIncBasis_Ma)) {
    HvyTrkUrbanDvmt_Ma <-
      L$Year$Marea$UrbanIncome * L$Global$Marea$HvyTrkDvmtIncomeFactor
  }
  rm(HvyTrkDvmtGrowthBasis_Ma, IsPopBasis_Ma, IsIncBasis_Ma)
  #Adjust quantities if there are regional controls
  if (HasRegionHvyTrk) {
    HvyTrkUrbanDvmt_Ma <-
      HvyTrkUrbanDvmt * HvyTrkUrbanDvmt_Ma / sum(HvyTrkUrbanDvmt_Ma)
  }
  #Output results
  Out_ls$Year$Marea$HvyTrkUrbanDvmt <- unname(HvyTrkUrbanDvmt_Ma)

  #Calculate Marea urban roadway DVMT by vehicle type and road class
  #-----------------------------------------------------------------
  #Get the roadway DVMT proportions by vehicle type and road class
  Dc <-
    c("LdvFwyArtDvmtProp", "LdvOthDvmtProp",
      "HvyTrkFwyDvmtProp", "HvyTrkArtDvmtProp", "HvyTrkOthDvmtProp",
      "BusFwyDvmtProp", "BusArtDvmtProp", "BusOthDvmtProp")
  DvmtProps_MaDc <- as.matrix(data.frame(L$Global$Marea[Dc]))
  #Compute DVMT by Marea, vehicle type, and roadway class
  DvmtByType_MaDc <- as.matrix(data.frame(
    LdvFwyArtDvmtProp = unname(LdvRoadDvmt_Ma),
    LdvOthDvmtProp = unname(LdvRoadDvmt_Ma),
    HvyTrkFwyDvmtProp = unname(HvyTrkUrbanDvmt_Ma),
    HvyTrkArtDvmtProp = unname(HvyTrkUrbanDvmt_Ma),
    HvyTrkOthDvmtProp = unname(HvyTrkUrbanDvmt_Ma),
    BusFwyDvmtProp = unname(L$Year$Marea$BusDvmt),
    BusArtDvmtProp = unname(L$Year$Marea$BusDvmt),
    BusOthDvmtProp = unname(L$Year$Marea$BusDvmt)
  ))[,Dc]
  Dvmt_MaDc <- DvmtProps_MaDc * DvmtByType_MaDc
  colnames(Dvmt_MaDc) <- gsub("Prop", "", colnames(Dvmt_MaDc))
  #Assign values
  for (nm in colnames(Dvmt_MaDc)) {
    Out_ls$Year$Marea[[nm]] <- unname(Dvmt_MaDc[,nm])
  }

  #Return the results
  #------------------
  Out_ls
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# load("data/RoadDvmtModel_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "CalculateFutureRoadDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L
# R <- CalculateBaseRoadDvmt(L)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "CalculateBaseRoadDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "BaseYear"
# )
