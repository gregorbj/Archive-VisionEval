#=====================
#Calculate4DMeasures.R
#=====================

#<doc>
#
## Calculate4DMeasures Module
#### November 6, 2018
#
#This module calculates several *4D* measures by Bzone including density, diversity (i.e. mixing of land uses), transportation network design, and destination accessibility. These measures are the same as or are similar to measures included in the Environmental Protection Agency's (EPA) [Smart Location Database](https://www.epa.gov/smartgrowth/smart-location-database-technical-documentation-and-user-guide).
#
### Model Parameter Estimation
#
#This module has no parameters. 4D measures are calculated based on Bzone attributes as described in the next section.
#
### How the Module Works
#
#This module calculates 3 development density measures that are named using the names used in the Smart Location Database (SLD): population density (D1B), employment density (D1C), and activity density (D1D). These density measures are calculated at the Bzone level. The population, employment, and activity (employment + households) values to calculate these measures come from the products of other modules. The area data comes from user inputs of the unprotected area (measured in acres) in urban (i.e. urbanized) and rural (i.e. not urbanized) portions of each Bzone.
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
#The module also calculates a destination accessibility measure (D5) which is the harmonic mean of jobs within 2 miles and population within 5 miles of the Bzone centroid. The calculation uses the simplifying assumption that all jobs and all households in a Bzone are located at the Bzone centroid. The straight line distances between all Bzone centroids are calculated from the latitudes and longitudes of the centroids that are provided by the user. For each Bzone, tabulations are made of the number of jobs located in Bzones whose centroids are within 2 miles and the population located in Bzones whose centroids are within 5 miles of the Bzone centroid. The D5 measure for the Bzone is calculated as follows:
#
#  `2 * EmpIn2Mi * PopIn5Mi / (EmpIn2Mi + PopIn5Mi)`
#
#where:
#
#- `EmpIn2Mi` is the total number of jobs in Bzones whose centroids are located within 2 miles (straight line distance) of the centroid of the subject Bzone.
#
#- `PopIn5Mi` is the total population in Bzones whose centroids are located within 5 miles (straight-line distance) of the centroid of the subject Bzone.
#
#One transportation network design measures is produced by the module. D3bpo4 is intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile. This is one of the network design measured in the Smart Location database. Users may pivot off of information from the SLD or may compute the measure using GIS. The SLD calculated values using NAVTEQ (now part of Here) network. The SLD users guide defines pedestrian-oriented facilities as follows:
#
#- Any arterial or local street having a speed category of 6 (between 21 and 30 mph) where car travel is permitted in both directions.
#
#- Any arterial or local street having a speed category of 7 or lower (less than 21 mph).
#
#- Any local street having a speed category of 6 (between 21 and 30 mph).
#
#- Any pathway or trail on which automobile travel is not permitted (speed category 8).
#
#- For all of the above, pedestrians must be permitted on the link.
#
#- For all of the above, controlled access highways, tollways, highway ramps, ferries, parking lot roads, tunnels, and facilities having four or more lanes of travel in a single direction (implied eight lanes bi-directional) are excluded.
#
#</doc>


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module has no parameters. 4D measures are calculated based on Bzone
#attributes.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
Calculate4DMeasuresSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME =
        items(
          "UrbanArea",
          "RuralArea"),
      FILE = "bzone_unprotected_area.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Area that is Urban and unprotected (i.e. developable) within the zone",
          "Area that is Rural and unprotected (i.e. developable) within the zone"
        )
    ),
    item(
      NAME = "D3apo",
      FILE = "bzone_network_design.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "pedestrian-oriented links per square mile",
      NAVALUE = -9999,
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Network density in terms of facility miles of pedestrian-oriented links per square mile (Ref: EPA 2010 Smart Location Database)"
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
    ),
    item(
      NAME = "D3bmm4",
      FILE = "bzone_network_design.csv",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "multimodal intersections per square mile",
      NAVALUE = -9999,
      SIZE = 0,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Intersection density in terms of multi-modal intersections having four or more legs per square mile (Ref: EPA 2010 Smart Location Database)"
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
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "households",
      UNITS = "HH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumWkr",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "UrbanArea",
          "RuralArea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
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
      NAME = "D1D",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "HHJOB/ACRE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Gross activity density (employment + households) on unprotected land in zone (Ref: EPA 2010 Smart Location Database)"
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
      NAME = "D5",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Destination accessibility of zone calculated as harmonic mean of jobs within 2 miles and population within 5 miles"
    )
  )
)


#Save the data specifications list
#---------------------------------
#' Specifications list for Calculate4DMeasures module
#'
#' A list containing specifications for the Calculate4DMeasures module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source Calculate4DMeasures.R script.
"Calculate4DMeasuresSpecifications"
usethis::use_data(Calculate4DMeasuresSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This module calculates several 4D measures by Bzone including density,
#diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#and destination accessibility.

#Function to sum values for block groups within specified distances
#-----------------------------------------------------------------
#' Sum values for block groups within specified distances
#'
#' \code{sumValsInDist} sums specified values for block groups whose centroids
#' are located within a specified distance cutoff.
#'
#' This function sums for each block group, a set of block group values of
#' all the block groups whose centroids are within the specified distance of
#' the the block group.
#'
#' @param DistCutoff A numeric value in miles specifying the straight line
#' distance in miles to use as the distance threshold.
#' @param DataToSum_ A numeric vector of the block group values to sum
#' corresponding to all Bzones.
#' @param Lat_ A numeric vector of the latitudes of the block group centroids
#' in the same order as DataToSum_.
#' @param Lng_ A numeric vector of the longitudes of the block group centroids
#' in the same order as DataToSum_.
#' @return A numeric vector of the sums of the values in DataToSum_ for block
#' groups within the DistanceCutoff of each Bzone.
#' @import geosphere
#' @import fields
sumValsInDist <- function(DistCutoff, DataToSum_, Lat_, Lng_){
  #Number of Bzones
  NumBzone <- length(DataToSum_)
  #Matrix centroid coordinates
  Coord_mx <- cbind(lng = Lng_, lat = Lat_)
  #Calculate longitude and latitude ranges corresponding to the maximum distance
  BufferDist <- DistCutoff * 1609.34  #Maximum distance in meters
  North <- 0
  South <- -180
  East <- 90
  West <- -90
  MinLng_ <- geosphere::destPoint(Coord_mx, West, BufferDist)[,1]
  MaxLng_ <- geosphere::destPoint(Coord_mx, East, BufferDist)[,1]
  MinLat_ <- geosphere::destPoint(Coord_mx, South, BufferDist)[,2]
  MaxLat_ <- geosphere::destPoint(Coord_mx, North, BufferDist)[,2]
  #Define function to sum values for Bzones whose centroids are within the
  #specified distance cutoff of a Bzone specified by it's position in the inputs
  sumValsInDist <- function(BzonePos) {
    Idx_ <- which(
      (Lat_ > MinLat_[BzonePos]) &
      (Lat_ < MaxLat_[BzonePos]) &
      (Lng_ > MinLng_[BzonePos]) &
      (Lng_ < MaxLng_[BzonePos])
    )
    DestLngLat_df <-
      data.frame(lng = Lng_[Idx_], lat = Lat_[Idx_])
    OrigLngLat_df <-
      data.frame(lng = Lng_[BzonePos], lat = Lat_[BzonePos])
    Dist_ <-
      fields::rdist.earth(DestLngLat_df, OrigLngLat_df, miles = TRUE, R = 6371)
    Data_ <- DataToSum_[Idx_]
    sum(Data_[Dist_ <= DistCutoff])
  }
  #Iterate through the Bzones and calculate the values
  Sums_ <- numeric(NumBzone)
  for (i in 1:NumBzone) {
    Sums_[i] <- sumValsInDist(i)
  }
  #Return the result
  Sums_
}

#Main module function that calculates 4D measures
#------------------------------------------------
#' Main module function that calculates 4D measures for each Bzone.
#'
#' \code{Calculate4DMeasures} calculates 4D measures for each Bzone.
#'
#' This module calculates several 4D measures by Bzone including density,
#' diversity (i.e. mixing of land uses), design (i.e. multimodal network design),
#' and destination accessibility.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
Calculate4DMeasures <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define a vector of Bzones
  Bz <- L$Year$Bzone$Bzone
  #Create data frame of Bzone data
  D_df <- data.frame(L$Year$Bzone)
  D_df$Area <- D_df$UrbanArea + D_df$RuralArea

  #Calculate density measures
  #--------------------------
  #Population density
  D1B_ <- with(D_df, Pop / Area)
  #Employment density
  D1C_ <- with(D_df, TotEmp / Area)
  #Activity density
  D1D_ <- with(D_df, (TotEmp + NumHh) / Area)

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

  #Calculate destination accessibilty term
  #---------------------------------------
  #Calculate employment within 2 miles
  EmpIn2Mi_ <-
    sumValsInDist(DistCutoff = 2,
                  DataToSum_ = D_df$TotEmp,
                  Lat_ = D_df$Latitude ,
                  Lng_ = D_df$Longitude)
  #Calculate population within 5 miles
  PopIn5Mi_ <-
    sumValsInDist(DistCutoff = 5,
                  DataToSum_ = D_df$Pop,
                  Lat_ = D_df$Latitude ,
                  Lng_ = D_df$Longitude)
  #Calculate regional destination access measure using harmonic mean
  D5_ <- 2 * EmpIn2Mi_ * PopIn5Mi_ / (EmpIn2Mi_ + PopIn5Mi_)

  #Return list of results
  #----------------------
  #Initialize list
  Out_ls <- initDataList()
  #Populate with results
  Out_ls$Year$Bzone <- list(
    D1B = D1B_,
    D1C = D1C_,
    D1D = D1D_,
    D2A_JPHH = D2A_JPHH_,
    D2A_WRKEMP = D2A_WRKEMP_,
    D2A_EPHHM = D2A_EPHHM_,
    D5 = D5_
  )
  #Return the results
  Out_ls
}


#===============================================================
#SECTION 4: MODULE DOCUMENTATION AND AUXILLIARY DEVELOPMENT CODE
#===============================================================
#Run module automatic documentation
#----------------------------------
documentModule("Calculate4DMeasures")

#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "Calculate4DMeasures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "Calculate4DMeasures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
