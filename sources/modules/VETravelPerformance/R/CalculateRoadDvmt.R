#===================
#CalculateRoadDvmt.R
#===================

#<doc>
#
## CalculateRoadDvmt Module
#### January 27, 2019
#
#When run for the base year, this module computes several factors used in computing roadway DVMT including factors for calculating commercial service vehicle travel and heavy truck travel. While base year heavy truck DVMT and commercial service vehicle DVMT are calculated directly from inputs and model parameters, future year DVMT is calculated as a function of the declared growth basis which for heavy trucks may be population or income, and for commercial service vehicles may be population, income, or household DVMT. Factors are calculated for each basis. In non-base years, the module uses these factors to compute heavy truck and commercial service DVMT.
#
#In the base year, the module computes factors for allocating light-duty vehicle (LDV) travel demand of marea households and related commercial service vehicle demand to urban roadways in the mareas and to non-urban roadways. These factors are used to compute urban area roadway DVMT which is used in the calculation of urban area congestion. The factors are applied to calculate urban roadway LDV DVMT in non-base years. In addition, the module allocates urban LDV roadway DVMT proportions to households, identifying the proportion of each household's DVMT that takes place on urban area roadways. This proportion is used in the adjustment of the fuel economy of household vehicles as a function of urban area congestion.
#
#Finally, the module adds together the urban LDV DVMT, urban heavy truck DVMT, and public transit DVMT and allocates it to road classes (freeway, arterial, other) for use in congestion calculations by the CalculateTravelPerformance module.
#
### Model Parameter Estimation
#
#This module has no estimated parameters.
#
### How the Module Works
#
#This module calculates several values necessary for calculating urbanized area road performance metrics by the CalculateRoadPerformance module as follows:
#
#* *Calculate heavy truck growth factors*: Base year heavy truck DVMT is calculated for the region and heavy truck DVMT on urbanized area roadways is calculated for each marea in the Initialize module. The ratios of these heavy truck DVMT estimates with base year regional and marea population and with base year regional and marea income are calculated and saved to the datastore. These ratios are used to calculate future year heavy truck DVMT using either future year population or future year income. Whether population or income is used as the basis for calculating heavy truck DVMT is determined by the value of HvyTrkDvmtGrowthBasis in the 'region_base_year_dvmt.csv' input file.
#
#* *Calculate commercial service vehicle growth factors*: Base year commercial service vehicle (light-duty) DVMT is calculated for each marea in the Initialize module. The ratios of commercial service DVMT with base year marea household DVMT, population, and income are calculated and saved to the datastore. These ratios are used to calculate future year commercial service DVMT using future year household DVMT, population, or income. Which is used as a basis for calculating commercial service DVMT is determined by the value of ComSvcDvmtGrowthBasis in the 'region_base_year_dvmt.csv' input file.
#
#* *Calculate ratio of urban light-duty vehicle roadway DVMT to urban light-duty vehicle (LDV) travel demand*: The CalculateHouseholdDvmt module in the VEHouseholdTravel package calculates the DVMT of households irrespective of where that travel occurs. Likewise commercial service vehicle travel that is calculated is the travel associated with households and the employment of household workers. For each marea to calculate the ratio of light-duty urban roadway DVMT to light-duty vehicle travel demand of urban area households (household DVMT, commercial service DVMT, and public transit DVMT) is calculated. This calculation uses the base year urban roadway DVMT calculated by the Initialize module, the modeled base year household DVMT, the base year commercial service DVMT calculated from the modeled base year household DVMT and the 2010 estimate of the ratio of commercial service DVMT to household DVMT calculated by the 'LoadDefaultRoadDvmtValues.R' script, and the base year public transit van DVMT calculated by the AssignTransitService module in the VETransportSupply package.
#
#* *Calculate marea urban base year road DVMT by vehicle type (LDV, heavy truck, bus) and road class (freeway, arterial, other)*: Base year urban roadway LDV DVMT and heavy truck DVMT are calculated as described above. Bus DVMT is calculated by the AssignTransitService module. These respective DVMT quantities are split between road classes using the proportional factors calculated by the Initialize module which either uses user inputs in the 'marea_dvmt_split_by_road_class.csv' file or default values calculated from Highway Statistics data by the LoadDefaultRoadDvmtValues.R script where data is not supplied by the user. For light-duty urban road DVMT, the freeway and arterial proportion of DVMT is combined. The CalculateRoadPerformance module splits this into freeway and arterial components based on operating conditions and prices.
#
#
#</doc>


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
CalculateRoadDvmtSpecifications <- list(
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
      ISELEMENTOF = c("Income", "Population")
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
        "WI", "WY", "DC", "PR", "NA")
    ),
    item(
      NAME = "HvyTrkDvmt",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = "< 0",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ComSvcDvmtGrowthBasis",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = c("HhDvmt", "Income", "Population")
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
          "LdvFwyDvmtProp",
          "LdvArtDvmtProp",
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
        "TownPop",
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
        "TownIncome",
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
        "TownHhDvmt",
        "RuralHhDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LocType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Town", "Rural")
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HvyTrkDvmtIncomeFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      PROHIBIT = "<= 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HvyTrkDvmtPopulationFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = "<= 0",
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
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "ComSvcDvmtIncomeFactor",
        "HvyTrkDvmtIncomeFactor"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = items(
        "ComSvcDvmtPopulationFactor",
        "HvyTrkDvmtPopulationFactor"),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "LdvUrbanRoadProp",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "HvyTrkDvmt",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION = "Average daily vehicle miles of travel on roadways in the region by heavy trucks during the base year. The value for this input may be NA instead of number. In that case, if a state abbreviation is provided, the base year value is calculated from the state per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year population. If the state abbreviation is NA (as for a metropolitan model) the base year value is calculated from metropolitan area per capita rates and metropolitan area population."
    ),
    item(
      NAME =
        items(
          "UrbanLdvDvmt",
          "UrbanHvyTrkDvmt"
        ),
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      DESCRIPTION =
        items(
          "Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by light-duty vehicles during the base year. This value may be omitted if a value for UzaNameLookup is provided so that a value may be computed from the urbanized area per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year urban population.",
          "Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by heavy trucks during he base year. This value may be omitted if a value for UzaNameLookup is provided so that a value may be computed from the urbanized area per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year urban population."
        )
    ),
    item(
      NAME = "HvyTrkDvmtIncomeFactor",
      TABLE = "Region",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/USD",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
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
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Ratio of Region base year heavy truck DVMT to population"
    ),
    item(
      NAME = items(
        "HvyTrkUrbanDvmt",
        "HvyTrkNonUrbanDvmt"),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Region heavy truck daily vehicle miles of travel in urbanized areas",
        "Region heavy truck daily vehicle miles of travel outside of urbanized areas (i.e. in town or rural areas)"
      )
    ),
    item(
      NAME = "ComSvcDvmtHhDvmtFactor",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items(
          "Ratio of Marea base year commercial service DVMT to household DVMT"
        )
    ),
    item(
      NAME = items(
        "ComSvcDvmtIncomeFactor",
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
      NAME = items(
        "ComSvcDvmtPopulationFactor",
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
      NAME = "LdvUrbanRoadProp",
      TABLE = "Marea",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "The proportion of the DVMT of households residing in the marea and associated commercial service DVMT that occurs on urbanized area roadways in the marea"
    ),
    item(
      NAME =
        items("ComSvcUrbanDvmt",
              "ComSvcTownDvmt",
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
        "Commercial service daily vehicle miles of travel associated with Marea town household activity",
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
    ),
    item(
      NAME = items(
        "UrbanHhPropUrbanDvmt",
        "NonUrbanHhPropUrbanDvmt"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Average proportion of urban household DVMT traveled on urban roads in the marea where the household resides",
        "Average proportion of non-urban household DVMT traveled on urban roads in the marea where the household resides")
    ),
    item(
      NAME = "UrbanDvmtProp",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Proportion of household DVMT traveled on urban roads in the marea where the household resides"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateRoadDvmt module
#'
#' A list containing specifications for the CalculateRoadDvmt module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateRoadDvmt.R script.
"CalculateRoadDvmtSpecifications"
usethis::use_data(CalculateRoadDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Main function calculates base year DVMT by vehicle type and by vehicle type
#and road class for each Marea. It also assigns DVMT proportions by vehicle type
#and road class from the default data for the urbanized area if the user hasn't
#supplied inputs for these quantities.

#Assign household DVMT proportion occurring on urban roads
#---------------------------------------------------------
#' Assign household DVMT proportion occurring on urban roads
#'
#' \code{assignHhUrbanDvmtProp} assigns a proportion of the DVMT of each
#' marea household to urban roads in the marea such that the total is consistent
#' with the total household DVMT assigned to urban roadways.
#'
#' This function is called by the CalculateRoadDvmt to assign the proportion of
#' each marea household's DVMT that occurs on urban roadways in the marea. The
#' proportions are calculated to be consistent with the control total calculated
#' for the marea.
#'
#' @param Hh_ls A list containing the characteristics of households used to
#' allocate the proportion of household DVMT occurring on urban area roads. The
#' list must include the marea name for each household
#' @param HhUrbanRoadDvmt_Ma A named numeric vector identifying the total amount
#' of household DVMT in each marea that occurs on urban area roads.
#' @return A numeric vector identifying the proportion of the household DVMT
#' occurring on marea urban roadways.
#' @import visioneval
#' @export
assignHhUrbanDvmtProp <- function(Hh_ls, HhUrbanRoadDvmt_Ma) {
  Ma <- names(HhUrbanRoadDvmt_Ma)
  NumHh <- length(Hh_ls$Dvmt)
  Prop_ <- numeric(NumHh)
  UrbanHhPropUrbanDvmt_Ma <- setNames(numeric(length(Ma)), Ma)
  NonUrbanHhPropUrbanDvmt_Ma <- setNames(numeric(length(Ma)), Ma)
  for (ma in Ma) {
    Dvmt_ <- Hh_ls$Dvmt[Hh_ls$Marea == ma]
    LocType_ <- Hh_ls$LocType[Hh_ls$Marea == ma]
    Prob_ <- as.numeric(LocType_ == "Urban")
    UrbanRoadProp_ <- Prob_ * HhUrbanRoadDvmt_Ma[ma] / sum(Dvmt_ * Prob_)
    HhDvmt_ <- tapply(Dvmt_, LocType_, sum)
    HhUrbanDvmt_ <- tapply(UrbanRoadProp_ * Dvmt_, LocType_, sum)
    Prop_[Hh_ls$Marea == ma] <- UrbanRoadProp_
    UrbanHhPropUrbanDvmt_Ma[ma] <- HhUrbanDvmt_["Urban"] / HhDvmt_["Urban"]
    NonUrbanHhPropUrbanDvmt_Ma[ma] <-
      (sum(HhUrbanDvmt_) - HhUrbanDvmt_["Urban"])  / (sum(HhDvmt_) - HhDvmt_["Urban"])
  }
  list(
    HhUrbanProp_Hh = Prop_,
    UrbanHhPropUrbanDvmt_Ma = UrbanHhPropUrbanDvmt_Ma,
    NonUrbanHhPropUrbanDvmt_Ma = NonUrbanHhPropUrbanDvmt_Ma
  )
}

#Main module function that assigns base year DVMT
#------------------------------------------------
#' Assign base year DVMT by vehicle type and road class for Mareas
#'
#' \code{CalculateRoadDvmt} calculates DVMT on roadways within the
#' urbanized portions of Mareas by vehicle type (light-duty vehicle,
#' heavy truck, bus) and road class (freeway, arterial, other). It computes
#' some other values as explained in the details. It also calls the
#' assignHhUrbanDvmtProp function to assign a proportion of each household's
#' DVMT to urban roadways.
#'
#' This function calculates several values necessary for calculating road
#' performance and vehicle energy consumption and emissions. These include
#' calculating base year daily vehicle miles of travel (DVMT) by vehicle type
#' (light-duty, heavy truck, bus), and jointly by vehicle type and road class
#' (freeway, arterial, other) for roadways in the urbanized proportions in
#' Mareas. The function also computes required parameters used for calculating
#' future year DVMT by vehicle type and road class. The function computes base
#' year heavy truck DVMT and ratios of heavy truck DVMT to total region
#' population and income. The function calculates base year commercial service
#' light-duty vehicle (LDV) DVMT and ratios of that DVMT to population,
#' household DVMT, and income by Marea. The ratio of LDV urbanized area road
#' DVMT to total DVMT of households residing in the urbanized area, commercial
#' service LDV associated with resident households, and public transit LDV DVMT
#' is calculated for each Marea. This ratio is used to calculate future year LDV
#' roadway DVMT from total urbanized area LDV demand.
#'
#' @param L A list containing data defined by the module specification.
#' @return A list containing data produced by the function consistent with the
#' module specifications.
#' @name CalculateBaseRoadDvmt
#' @import visioneval
#' @export
CalculateRoadDvmt <- function(L) {

  #Set up
  #------
  #Copy portions of inputs list to outputs so that outputs exist to meet Set
  #specifications regardless of whether base year or other year
  Out_ls <- list(
    Global = L$Global,
    Year = list(
      Marea = L$Year$Marea
    )
  )
  #Function to remove attributes
  unattr <- function(X_) {
    attributes(X_) <- NULL
    X_
  }
  RoadDvmtModel_ls <- loadPackageDataset("RoadDvmtModel_ls")

  #Extract marea population, income, household DVMT and calculate totals
  #---------------------------------------------------------------------
  Ma <- L$Year$Marea$Marea
  #Population
  UrbanPop_Ma <- L$Year$Marea$UrbanPop
  TownPop_Ma <- L$Year$Marea$TownPop
  RuralPop_Ma <- L$Year$Marea$RuralPop
  Pop_Ma <- UrbanPop_Ma + TownPop_Ma + RuralPop_Ma
  Pop <- sum(Pop_Ma)
  #Income
  UrbanIncome_Ma <- L$Year$Marea$UrbanIncome
  TownIncome_Ma <- L$Year$Marea$TownIncome
  RuralIncome_Ma <- L$Year$Marea$RuralIncome
  Inc_Ma <- UrbanIncome_Ma + TownIncome_Ma + RuralIncome_Ma
  Inc <- sum(Inc_Ma)
  #Household DVMT
  UrbanHhDvmt_Ma <- L$Year$Marea$UrbanHhDvmt
  TownHhDvmt_Ma <- L$Year$Marea$TownHhDvmt
  RuralHhDvmt_Ma <- L$Year$Marea$RuralHhDvmt
  HhDvmt_Ma <- UrbanHhDvmt_Ma + TownHhDvmt_Ma + RuralHhDvmt_Ma

  #Calculate base year urban HvyTrk and LDV roadDVMT and regional HvyTrk DVMT
  #--------------------------------------------------------------------------
  #Only run for base year
  if (L$G$Year == L$G$BaseYear) {
    #Make a data frame of Marea data to use in checks and calculations
    Marea_df <- data.frame(
      Name = L$Global$Marea$Marea,
      LookupName = L$Global$Marea$UzaNameLookup,
      UrbanPop = L$Year$Marea$UrbanPop,
      TotalPop = with(L$Year$Marea, (UrbanPop + TownPop + RuralPop)),
      UrbanHvyTrkDvmt = L$Global$Marea$UrbanHvyTrkDvmt,
      UrbanLdvDvmt = L$Global$Marea$UrbanLdvDvmt
    )
    #Calculate urban road HvyTrk DVMT rates and values using default per capita
    #rate if value has not been specified in inputs
    HasHvyTrkDvmt <- !is.na(Marea_df$UrbanHvyTrkDvmt)
    if (any(!HasHvyTrkDvmt)) {
      Marea_df$UrbanHvyTrkDvmtPC <- Marea_df$UrbanHvyTrkDvmt / Marea_df$UrbanPop
      Marea_df$UrbanHvyTrkDvmtPC[!HasHvyTrkDvmt] <-
        RoadDvmtModel_ls$UzaHvyTrkDvmtPC_Ua[Marea_df$LookupName[!HasHvyTrkDvmt]]
      Marea_df$UrbanHvyTrkDvmt <- with(Marea_df, UrbanHvyTrkDvmtPC * UrbanPop)
      L$Global$Marea$UrbanHvyTrkDvmt <- Marea_df$UrbanHvyTrkDvmt
    }
    rm(HasHvyTrkDvmt)
    #Calculate urban road LDV DVMT rates and values using default per capita
    #rate if value has not been specified in inputs
    HasLdvDvmt <- !is.na(Marea_df$UrbanLdvDvmt)
    if (any(!HasLdvDvmt)) {
      Marea_df$UrbanLdvDvmtPC <- Marea_df$UrbanLdvDvmt / Marea_df$UrbanPop
      Marea_df$UrbanLdvDvmtPC[!HasLdvDvmt] <-
        RoadDvmtModel_ls$UzaLDVDvmtPC_Ua[Marea_df$LookupName[!HasLdvDvmt]]
      Marea_df$UrbanLdvDvmt <- with(Marea_df, UrbanLdvDvmtPC * UrbanPop)
      L$Global$Marea$UrbanLdvDvmt <- Marea_df$UrbanLdvDvmt
    }
    rm(HasLdvDvmt)
    #Check whether region heavy truck data are complete
    RegionHvyTrkDvmt <- L$Global$Region$HvyTrkDvmt
    if (is.na(RegionHvyTrkDvmt)) {
      State <- L$Global$Region$StateAbbrLookup
      if (!is.na(State)) {
        RegionPop <- Pop
        RegionHvyTrkDvmt <- RoadDvmtModel_ls$HvyTrkDvmtPC_St[State] * RegionPop
        rm(RegionPop)
      } else {
        RegionHvyTrkDvmt <- with(Marea_df, sum(UrbanHvyTrkDvmtPC * TotalPop))
      }
      L$Global$Region$HvyTrkDvmt <- RegionHvyTrkDvmt
      rm(State)
    }
    rm(RegionHvyTrkDvmt, Marea_df)
  }
  #Update the values for HvyTrk and LDV DVMT
  Out_ls$Global$Region$HvyTrkDvmt <- L$Global$Region$HvyTrkDvmt
  Out_ls$Global$Marea$UrbanHvyTrkDvmt <- L$Global$Marea$UrbanHvyTrkDvmt
  Out_ls$Global$Marea$UrbanLdvDvmt <- L$Global$Marea$UrbanLdvDvmt

  #Calculate heavy truck prediction factors and DVMT
  #-------------------------------------------------
  #If base year, calculate prediction factors and totals
  if (L$G$Year == L$G$BaseYear) {
    #Calculate values
    UrbanHvyTrkDvmt_Ma <- L$Global$Marea$UrbanHvyTrkDvmt
    HvyTrkDvmtPopulationFactor_Ma <- UrbanHvyTrkDvmt_Ma / UrbanPop_Ma
    HvyTrkDvmtIncomeFactor_Ma <- UrbanHvyTrkDvmt_Ma / UrbanIncome_Ma
    HvyTrkDvmt <- L$Global$Region$HvyTrkDvmt
    HvyTrkUrbanDvmt <- sum(L$Global$Marea$UrbanHvyTrkDvmt)
    HvyTrkDvmtPopulationFactor <- HvyTrkDvmt / Pop
    HvyTrkDvmtIncomeFactor <- HvyTrkDvmt / Inc
    HvyTrkUrbanDvmt_Ma <- unattr(L$Global$Marea$UrbanHvyTrkDvmt)
    #Assign values to outputs list
    Out_ls$Global$Region$HvyTrkDvmtPopulationFactor <- unattr(HvyTrkDvmtPopulationFactor)
    Out_ls$Global$Region$HvyTrkDvmtIncomeFactor <- unattr(HvyTrkDvmtIncomeFactor)
    Out_ls$Global$Marea$HvyTrkDvmtPopulationFactor <- unattr(HvyTrkDvmtPopulationFactor_Ma)
    Out_ls$Global$Marea$HvyTrkDvmtIncomeFactor <- unattr(HvyTrkDvmtIncomeFactor_Ma)
    Out_ls$Year$Region$HvyTrkUrbanDvmt <- unattr(HvyTrkUrbanDvmt)
    Out_ls$Year$Region$HvyTrkNonUrbanDvmt <- unattr(HvyTrkDvmt - HvyTrkUrbanDvmt)
    Out_ls$Year$Marea$HvyTrkUrbanDvmt <- HvyTrkUrbanDvmt_Ma
  #If not base year, calculate values
  } else {
    #Calculate marea heavy truck DVMT
    HvyTrkDvmtGrowthBasis <- L$Global$Region$HvyTrkDvmtGrowthBasis
    if (HvyTrkDvmtGrowthBasis == "Population") {
      HvyTrkUrbanDvmt_Ma <-
        unattr(UrbanPop_Ma * L$Global$Region$HvyTrkDvmtPopulationFactor)
    }
    if (HvyTrkDvmtGrowthBasis == "Income") {
      HvyTrkUrbanDvmt_Ma <-
        unattr(UrbanIncome_Ma * L$Global$Region$HvyTrkDvmtIncomeFactor)
    }
    #Calculate region heavy truck DVMT
    if (HvyTrkDvmtGrowthBasis == "Population") {
      HvyTrkDvmt <- unattr(Pop * L$Global$Region$HvyTrkDvmtPopulationFactor)
    }
    if (HvyTrkDvmtGrowthBasis == "Income") {
      HvyTrkDvmt <- unattr(Inc * L$Global$Region$HvyTrkDvmtIncomeFactor)
    }
    HvyTrkUrbanDvmt <- sum(HvyTrkUrbanDvmt_Ma)
    HvyTrkNonUrbanDvmt <- HvyTrkDvmt - HvyTrkUrbanDvmt
    #Assign values to outputs list
    Out_ls$Year$Marea$HvyTrkUrbanDvmt <- HvyTrkUrbanDvmt_Ma
    Out_ls$Year$Region$HvyTrkUrbanDvmt <- HvyTrkUrbanDvmt
    Out_ls$Year$Region$HvyTrkNonUrbanDvmt <- HvyTrkNonUrbanDvmt
  }

  #Calculate ComSvc prediction factors and DVMT
  #--------------------------------------------
  #If base year, calculate prediction factors and totals
  if (L$G$Year == L$G$BaseYear) {
    #Calculate values
    UrbanComSvcDvmt_Ma <- UrbanHhDvmt_Ma * RoadDvmtModel_ls$ComSvcDvmtFactor
    TownComSvcDvmt_Ma <- TownHhDvmt_Ma * RoadDvmtModel_ls$ComSvcDvmtFactor
    RuralComSvcDvmt_Ma <- RuralHhDvmt_Ma * RoadDvmtModel_ls$ComSvcDvmtFactor
    ComSvcDvmt_Ma <- UrbanComSvcDvmt_Ma + TownComSvcDvmt_Ma + RuralComSvcDvmt_Ma
    ComSvcDvmtFactor_Ma <- rep(RoadDvmtModel_ls$ComSvcDvmtFactor, length(Ma))
    ComSvcDvmtPopulationFactor_Ma <- unattr((UrbanComSvcDvmt_Ma + TownComSvcDvmt_Ma + RuralComSvcDvmt_Ma) / Pop_Ma)
    ComSvcDvmtIncomeFactor_Ma <- unattr((UrbanComSvcDvmt_Ma + TownComSvcDvmt_Ma + RuralComSvcDvmt_Ma) / Inc_Ma)
    #Assign values to outputs list
    Out_ls$Year$Marea$ComSvcUrbanDvmt <- unattr(UrbanComSvcDvmt_Ma)
    Out_ls$Year$Marea$ComSvcTownDvmt <- unattr(TownComSvcDvmt_Ma)
    Out_ls$Year$Marea$ComSvcRuralDvmt <- unattr(RuralComSvcDvmt_Ma)
    Out_ls$Global$Marea$ComSvcDvmtHhDvmtFactor <- ComSvcDvmtFactor_Ma
    Out_ls$Global$Marea$ComSvcDvmtPopulationFactor <- ComSvcDvmtPopulationFactor_Ma
    Out_ls$Global$Marea$ComSvcDvmtIncomeFactor <- ComSvcDvmtIncomeFactor_Ma
  #If not, calculate values
  } else {
    #Calculate values
    ComSvcDvmtGrowthBasis <- L$Global$Region$ComSvcDvmtGrowthBasis
    if (ComSvcDvmtGrowthBasis == "HhDvmt") {
      GrowthFactor_Ma <- L$Global$Marea$ComSvcDvmtHhDvmtFactor
      UrbanGrowthBasis_Ma <- L$Year$Marea$UrbanHhDvmt
      TownGrowthBasis_Ma <- L$Year$Marea$TownHhDvmt
      RuralGrowthBasis_Ma <- L$Year$Marea$RuralHhDvmt
    }
    if (ComSvcDvmtGrowthBasis == "Population") {
      GrowthFactor_Ma <- L$Global$Marea$ComSvcDvmtPopulationFactor
      UrbanGrowthBasis_Ma <- L$Year$Marea$UrbanPop
      TownGrowthBasis_Ma <- L$Year$Marea$TownPop
      RuralGrowthBasis_Ma <- L$Year$Marea$RuralPop
    }
    if (ComSvcDvmtGrowthBasis == "Income") {
      GrowthFactor_Ma <- L$Global$Marea$ComSvcDvmtIncomeFactor
      UrbanGrowthBasis_Ma <- L$Year$Marea$UrbanIncome
      TownGrowthBasis_Ma <- L$Year$Marea$TownIncome
      RuralGrowthBasis_Ma <- L$Year$Marea$RuralIncome
    }
    UrbanComSvcDvmt_Ma <- unattr(GrowthFactor_Ma * UrbanGrowthBasis_Ma)
    TownComSvcDvmt_Ma <- unattr(GrowthFactor_Ma * TownGrowthBasis_Ma)
    RuralComSvcDvmt_Ma <- unattr(GrowthFactor_Ma * RuralGrowthBasis_Ma)
    ComSvcDvmt_Ma <- UrbanComSvcDvmt_Ma + TownComSvcDvmt_Ma + RuralComSvcDvmt_Ma
    #Assign values to outputs list
    Out_ls$Year$Marea$ComSvcUrbanDvmt <- UrbanComSvcDvmt_Ma
    Out_ls$Year$Marea$ComSvcTownDvmt <- TownComSvcDvmt_Ma
    Out_ls$Year$Marea$ComSvcRuralDvmt <- RuralComSvcDvmt_Ma
  }

  #Calculate Marea LDV factors and DVMT
  #------------------------------------
  #If base year, calculate factors and values
  if (L$G$Year == L$G$BaseYear) {
    #Urban roadway LDV DVMT
    UrbanLdvDvmt_Ma <- L$Global$Marea$UrbanLdvDvmt
    #Calculate proportion of marea HH and ComSvc demand on urban roadways
    LdvUrbanRoadProp_Ma <-
      (UrbanLdvDvmt_Ma - L$Year$Marea$VanDvmt) / (HhDvmt_Ma + ComSvcDvmt_Ma)
    #Assign values to outputs list
    Out_ls$Global$Marea$LdvUrbanRoadProp <- unattr(LdvUrbanRoadProp_Ma)
  } else {
    #Calculate total household and commercial service DVMT demand
    DvmtDemand_Ma <- HhDvmt_Ma + UrbanComSvcDvmt_Ma + TownComSvcDvmt_Ma + RuralComSvcDvmt_Ma
    #Calculate LDV road DVMT
    LdvUrbanRoadProp_Ma <- L$Global$Marea$LdvUrbanRoadProp
    UrbanLdvDvmt_Ma <- DvmtDemand_Ma * LdvUrbanRoadProp_Ma + L$Year$Marea$VanDvmt
  }

  #Calculate household proportion of DVMT on urban roads
  #-----------------------------------------------------
  #Total urban road DVMT from marea households
  HhUrbanRoadDvmt_Ma <- HhDvmt_Ma * LdvUrbanRoadProp_Ma
  names(HhUrbanRoadDvmt_Ma) <- Ma
  #Calculate urban DVMT proportion of each household and urban and non-urban household averages
  UrbanDvmtProp_ls <- assignHhUrbanDvmtProp(L$Year$Household, HhUrbanRoadDvmt_Ma)
  Out_ls$Year$Household$UrbanDvmtProp <- UrbanDvmtProp_ls$HhUrbanProp_Hh
  Out_ls$Year$Marea$UrbanHhPropUrbanDvmt <- UrbanDvmtProp_ls$UrbanHhPropUrbanDvmt_Ma
  Out_ls$Year$Marea$NonUrbanHhPropUrbanDvmt <- UrbanDvmtProp_ls$NonUrbanHhPropUrbanDvmt_Ma

  #Calculate DVMT by vehicle type and roadway type
  #-----------------------------------------------
  #Define the DVMT proportions categories
  Dc <-
    c("LdvFwyDvmtProp", "LdvArtDvmtProp", "LdvOthDvmtProp",
      "HvyTrkFwyDvmtProp", "HvyTrkArtDvmtProp", "HvyTrkOthDvmtProp",
      "BusFwyDvmtProp", "BusArtDvmtProp", "BusOthDvmtProp")
  #Make a matrix of proportions
  DvmtProps_MaDc <- as.matrix(data.frame(L$Global$Marea[Dc]))
  rownames(DvmtProps_MaDc) <- Ma
  #Compute DVMT by Marea, vehicle type, and roadway class
  DvmtByType_MaDc <- as.matrix(data.frame(
    LdvFwyDvmtProp = UrbanLdvDvmt_Ma,
    LdvArtDvmtProp = UrbanLdvDvmt_Ma,
    LdvOthDvmtProp = UrbanLdvDvmt_Ma,
    HvyTrkFwyDvmtProp = HvyTrkUrbanDvmt_Ma,
    HvyTrkArtDvmtProp = HvyTrkUrbanDvmt_Ma,
    HvyTrkOthDvmtProp = HvyTrkUrbanDvmt_Ma,
    BusFwyDvmtProp = L$Year$Marea$BusDvmt,
    BusArtDvmtProp = L$Year$Marea$BusDvmt,
    BusOthDvmtProp = L$Year$Marea$BusDvmt
  ))[,Dc]
  DvmtByRoadClass_df <- data.frame(DvmtProps_MaDc * DvmtByType_MaDc)
  names(DvmtByRoadClass_df) <- gsub("Prop", "", names(DvmtByRoadClass_df))
  #Combine LdvFwy and LdvArt (CalculateRoadPerformance will split)
  DvmtByRoadClass_df$LdvFwyArtDvmt <-
    DvmtByRoadClass_df$LdvFwyDvmt + DvmtByRoadClass_df$LdvArtDvmt
  DvmtByRoadClass_df$LdvFwyDvmt <- NULL
  DvmtByRoadClass_df$LdvArtDvmt <- NULL
  #Assign values
  for (nm in names(DvmtByRoadClass_df)) {
    Out_ls$Year$Marea[[nm]] <- unname(DvmtByRoadClass_df[,nm])
  }

  #Return the results
  #------------------
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("CalculateRoadDvmt")

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
#   ModuleName = "CalculateRoadDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# R <- CalculateRoadDvmt(L)

