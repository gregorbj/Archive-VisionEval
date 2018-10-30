#=======================
#CalculateBaseRoadDvmt.R
#=======================
#This module calculates base year roadway DVMT by vehicle type (light-duty,
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
CalculateBaseRoadDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
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
      NAME = "StateAbbrLookup",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = c(
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID",
        "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS",
        "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK",
        "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV",
        "WI", "WY", "DC", "PR", "NA"),
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmt",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmtUrbanProp",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
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
      NAME = "UzaNameLookup",
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
      NAME = "UrbanLdvDvmt",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UrbanHvyTrkDvmt",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
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
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "VanDvmt",
        "BusDvmt",
        "RailDvmt"),
      TABLE = "Marea",
      GROUP = "BaseYear",
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
      GROUP = "BaseYear",
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
      GROUP = "BaseYear",
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
      GROUP = "BaseYear",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "HvyTrkDvmtUrbanProp",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = "Proportion of Region heavy truck daily vehicle miles of travel occurring on urbanized area roadways"
    ),
    item(
      NAME = "HvyTrkDvmtIncomeFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      NAVALUE = -1,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of Region base year heavy truck DVMT to household income"
    ),
    item(
      NAME = "HvyTrkDvmtPopulationFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of Region base year heavy truck DVMT to population"
    ),
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
      NAME = "ComSvcDvmtHhDvmtFactor",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of Marea base year commercial service DVMT to household DVMT"
        )
    ),
    item(
      NAME =
        items("ComSvcDvmtIncomeFactor",
              "HvyTrkDvmtIncomeFactor"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of base year commercial service vehicle DVMT to household income",
          "Ratio of base year heavy truck DVMT to household income"
        )
    ),
    item(
      NAME =
        items("ComSvcDvmtPopulationFactor",
              "HvyTrkDvmtPopulationFactor"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of base year commercial service vehicle DVMT to population",
          "Ratio of base year heavy truck DVMT to population"
        )
    ),
    item(
      NAME = "LdvRoadDvmtLdvDemandRatio",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "ratio",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio between light-duty vehicle (LDV) daily vehicle miles of travel (DVMT) on urbanized area roadways in the Marea to the total LDV DVMT of households residing in the urbanized area, the commercial service vehicle travel related to household demand, and LDV public transit DVMT."
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
      NAVALUE = -1,
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeway or arterial roadways",
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
#' Specifications list for CalculateBaseRoadDvmt module
#'
#' A list containing specifications for the CalculateBaseRoadDvmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateBaseRoadDvmt.R script.
"CalculateBaseRoadDvmtSpecifications"
usethis::use_data(CalculateBaseRoadDvmtSpecifications, overwrite = TRUE)


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
#' @name CalculateBaseRoadDvmt
#' @import visioneval
#' @export
CalculateBaseRoadDvmt <- function(L) {
  #Set up
  #------
  Out_ls <- initDataList()
  Out_ls$Global$Region <- list()
  Out_ls$Global$Marea <- list()
  Out_ls$Year$Region <- list()
  Out_ls$Year$Marea <- list()

  #Calculate Region HvyTrk factors and DVMT if region table was input
  #------------------------------------------------------------------
  #Check if Region HvyTrk data exists
  HasRegionHvyTrk <- !is.null(L$Global$Region$HvyTrkDvmtGrowthBasis)
  #If the Region HvyTrk data exists, calculate HvyTrk factors and DVMT
  if (HasRegionHvyTrk) {
    Pop <- sum(unlist(L$BaseYear$Marea[c("RuralPop", "UrbanPop")]))
    Inc <- sum(unlist(L$BaseYear$Marea[c("RuralIncome", "UrbanIncome")]))
    State <- L$Global$Region$StateAbbrLookup
    HvyTrkDvmt <- L$Global$Region$HvyTrkDvmt
    HvyTrkUrbanProp <- L$Global$Region$HvyTrkDvmtUrbanProp
    if (!is.na(HvyTrkDvmt)) {
      HvyTrkDvmtPopulationFactor <- HvyTrkDvmt / Pop
      HvyTrkDvmtIncomeFactor <- HvyTrkDvmt / Inc
    } else {
      HvyTrkDvmtPopulationFactor <- RoadDvmtModel_ls$HvyTrkDvmtPC_St[State]
      HvyTrkDvmt <- HvyTrkDvmtPopulationFactor * Pop
      HvyTrkDvmtIncomeFactor <- HvyTrkDvmt / Inc
    }
    if (is.na(HvyTrkUrbanProp)) {
      HvyTrkUrbanProp <- RoadDvmtModel_ls$HvyTrkDvmtUrbanProp_St[State]
    }
    Out_ls$Global$Region$HvyTrkDvmtUrbanProp <-
      unname(HvyTrkUrbanProp)
    Out_ls$Global$Region$HvyTrkDvmtPopulationFactor <-
      unname(HvyTrkDvmtPopulationFactor)
    Out_ls$Global$Region$HvyTrkDvmtIncomeFactor <-
      unname(HvyTrkDvmtIncomeFactor)
    Out_ls$Year$Region$HvyTrkUrbanDvmt <-
      unname(HvyTrkDvmt * HvyTrkUrbanProp)
    Out_ls$Year$Region$HvyTrkRuralDvmt <-
      unname(HvyTrkDvmt * (1 - HvyTrkUrbanProp))
  #If not, then save NA values as flags that there are no factors to use
  } else {
    Out_ls$Global$Region$HvyTrkDvmtUrbanProp <- NA
    Out_ls$Global$Region$HvyTrkDvmtPopulationFactor <- NA
    Out_ls$Global$Region$HvyTrkDvmtIncomeFactor <- NA
    Out_ls$Year$Region$HvyTrkUrbanDvmt <- NA
    Out_ls$Year$Region$HvyTrkRuralDvmt <- NA
  }

  #Calculate ComSvc DVMT and prediction ratios
  #-------------------------------------------
  Ma <- L$BaseYear$Marea$Marea
  Pop_Ma <- L$BaseYear$Marea$UrbanPop + L$BaseYear$Marea$RuralPop
  Inc_Ma <- L$BaseYear$Marea$UrbanIncome + L$BaseYear$Marea$RuralIncome
  #Calculate ComSvc DVMT and prediction ratios
  UrbanHhDvmt_Ma <- L$BaseYear$Marea$UrbanHhDvmt
  RuralHhDvmt_Ma <- L$BaseYear$Marea$RuralHhDvmt
  HhDvmt_Ma <- UrbanHhDvmt_Ma + RuralHhDvmt_Ma
  UrbanComSvcDvmt_Ma <- UrbanHhDvmt_Ma * RoadDvmtModel_ls$ComSvcDvmtFactor
  RuralComSvcDvmt_Ma <- RuralHhDvmt_Ma * RoadDvmtModel_ls$ComSvcDvmtFactor
  Out_ls$Year$Marea$ComSvcUrbanDvmt <- UrbanComSvcDvmt_Ma
  Out_ls$Year$Marea$ComSvcRuralDvmt <- RuralComSvcDvmt_Ma
  Out_ls$Global$Marea$ComSvcDvmtHhDvmtFactor <-
    rep(RoadDvmtModel_ls$ComSvcDvmtFactor, length(Ma))
  Out_ls$Global$Marea$ComSvcDvmtPopulationFactor <-
    unname((UrbanComSvcDvmt_Ma + RuralComSvcDvmt_Ma) / Pop_Ma)
  Out_ls$Global$Marea$ComSvcDvmtIncomeFactor <-
    unname((UrbanComSvcDvmt_Ma + RuralComSvcDvmt_Ma) / Inc_Ma)
  rm(Pop_Ma, Inc_Ma)

  #Calculate Marea LDV factors and DVMT
  #------------------------------------
  #Calculate LDV DVMT demand components and total
  VanDvmt_Ma <- L$BaseYear$Marea$VanDvmt
  TotUrbanLdvDvmt_Ma <- UrbanHhDvmt_Ma + UrbanComSvcDvmt_Ma + VanDvmt_Ma
  #Calculate LDV road DVMT
  UrbanLdvDvmt_Ma <- numeric(length(Ma))
  UrbanPop_Ma <- L$BaseYear$Marea$UrbanPop
  for (i in 1:length(Ma)) {
    UrbanLdvDvmt_Ma[i] <- L$Global$Marea$UrbanLdvDvmt[i]
    if (is.na(UrbanLdvDvmt_Ma[i])) {
      UaName <- L$Global$Marea$UzaNameLookup[i]
      UrbanLdvDvmt_Ma[i] <-
        UrbanPop_Ma[i] * RoadDvmtModel_ls$UzaLDVDvmtPC_Ua[UaName]
      rm(UaName)
    }
  }
  rm(UrbanPop_Ma)
  #Calculate LDV road DVMT ratio
  Out_ls$Global$Marea$LdvRoadDvmtLdvDemandRatio <-
    UrbanLdvDvmt_Ma / TotUrbanLdvDvmt_Ma

  #Calculate Marea heavy truck base year DVMT and prediction factors
  #-----------------------------------------------------------------
  #Calculate heavy truck DVMT
  HvyTrkUrbanDvmt_Ma <- numeric(length(Ma))
  UrbanPop_Ma <- L$BaseYear$Marea$UrbanPop
  for (i in 1:length(Ma)) {
    HvyTrkUrbanDvmt_Ma[i] <- L$Global$Marea$UrbanHvyTrkDvmt[i]
    if (is.na(HvyTrkUrbanDvmt_Ma[i])) {
      UaName <- L$Global$Marea$UzaNameLookup[i]
      HvyTrkUrbanDvmt_Ma[i] <-
        UrbanPop_Ma[i] * RoadDvmtModel_ls$UzaHvyTrkDvmtPC_Ua[UaName]
      rm(UaName)
    }
  }
  #Calculate heavy-truck DVMT prediction factors
  HvyTrkDvmtPopulationFactor_Ma <- HvyTrkUrbanDvmt_Ma / UrbanPop_Ma
  HvyTrkDvmtIncomeFactor_Ma <- HvyTrkUrbanDvmt_Ma / L$BaseYear$Marea$UrbanIncome
  rm(UrbanPop_Ma)
  #Save the results
  Out_ls$Year$Marea$HvyTrkUrbanDvmt <- HvyTrkUrbanDvmt_Ma
  Out_ls$Global$Marea$HvyTrkDvmtPopulationFactor <-
    unname(HvyTrkDvmtPopulationFactor_Ma)
  Out_ls$Global$Marea$HvyTrkDvmtIncomeFactor <-
    unname(HvyTrkDvmtIncomeFactor_Ma)

  #Extract roadway DVMT proportions vehicle type
  #---------------------------------------------
  #Define the DVMT proportions categories
  Dc <-
    c("LdvFwyArtDvmtProp", "LdvOthDvmtProp",
      "HvyTrkFwyDvmtProp", "HvyTrkArtDvmtProp", "HvyTrkOthDvmtProp",
      "BusFwyDvmtProp", "BusArtDvmtProp", "BusOthDvmtProp")
  #Check whether the DVMT proportions data are present either all will be
  #present or none will be present
  HasPropsData <- !is.null(L$Global$Marea[[Dc[1]]])
  #If proportions data exist, extract it
  if (HasPropsData) {
    DvmtProps_MaDc <- as.matrix(data.frame(L$Global$Marea[Dc]))
  #Otherwise get from default data
  } else {
    DvmtProps_MaDc <-
      array(0, dim = c(length(Ma), length(Dc)), dimnames = list(Ma, Dc))
    for (i in 1:length(Ma)) {
      UaName <- L$Global$Marea$UzaNameLookup[i]
      #Assign Ldv roadway proportions
      DvmtProps_MaDc[i, "LdvFwyArtDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"LDV", c("Fwy", "Art")])
      DvmtProps_MaDc[i, "LdvOthDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"LDV", "Oth"])
      #Assign HvyTrk roadway proportions
      DvmtProps_MaDc[i, "HvyTrkFwyDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"HvyTrk", "Fwy"])
      DvmtProps_MaDc[i, "HvyTrkArtDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"HvyTrk", "Art"])
      DvmtProps_MaDc[i, "HvyTrkOthDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"HvyTrk", "Oth"])
      #Assign Bus roadway proportions
      DvmtProps_MaDc[i, "BusFwyDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"Bus", "Fwy"])
      DvmtProps_MaDc[i, "BusArtDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"Bus", "Art"])
      DvmtProps_MaDc[i, "BusOthDvmtProp"] <-
        sum(RoadDvmtModel_ls$UzaRcProps_UaVtRc[UaName,"Bus", "Oth"])
    }
  }
  #Save the values
  for (dc in Dc) {
    Out_ls$Global$Marea[[dc]] <- unname(DvmtProps_MaDc[,dc])
  }

  #Calculate base year DVMT by vehicle type and roadway type
  #---------------------------------------------------------
  #Compute DVMT by Marea, vehicle type, and roadway class
  DvmtByType_MaDc <- as.matrix(data.frame(
    LdvFwyArtDvmtProp = UrbanLdvDvmt_Ma,
    LdvOthDvmtProp = UrbanLdvDvmt_Ma,
    HvyTrkFwyDvmtProp = HvyTrkUrbanDvmt_Ma,
    HvyTrkArtDvmtProp = HvyTrkUrbanDvmt_Ma,
    HvyTrkOthDvmtProp = HvyTrkUrbanDvmt_Ma,
    BusFwyDvmtProp = L$BaseYear$Marea$BusDvmt,
    BusArtDvmtProp = L$BaseYear$Marea$BusDvmt,
    BusOthDvmtProp = L$BaseYear$Marea$BusDvmt
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
#   ModuleName = "CalculateBaseRoadDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "BaseYear"
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
