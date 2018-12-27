#========================
#MakeSimBzoneEstDataset.R
#========================

#<doc>
## MakeSimBzoneEstDataset Module
#### October 31, 2018
#
#This script combines data from the US Census, the EPA Smart Location Database (SLD), and the National Transit Database to prepare a block group dataset for use in estimating the models for synthesizing Bzones for VisionEval models where the Bzone level of geography is synthesized rather than explicitly defined. The script has 4 functions which carry out the operations of loading the 3 datasets and combining them into the final model estimation dataset. These functions are called as necessary. A function is only called if the dataset it creates is not present in the package. As a result, since the default package contains all of the datasets, no processing is done. If the user wishes to change the processing and/or what data is included in the datasets, they would need to remove the datasets in the 'data' directory and rebuild the package.
#
### Housing and Household Income Dataset
#US Census data on the proportions of multifamily and single family households and the median income of households in each block group is downloaded using the US Census data API and the tidycensus package. Note that you need to get a Census API key and 'register' it with your R setup if you have not already done so. You get a Census API key from [https://api.census.gov/data/key_signup.html]. Then execute the following code in the R console: `census_api_key(INSERT CENSUS API KEY HERE, install = TRUE)`. The `getCensusHousingInc` function iterates through each state (and the District of Columbia), downloads numbers of buildings by type and the household median income for each block group. Buildings are combined into 2 types (single-family, multifamily). The single-family type is defined as detached one-family homes and mobile homes. The multifamily includes all other types (which are attached dwellings) except for the boat, RV, van, etc. category which is ignored. The script also downloads the median income for each block group. The year 2015 American Community Survey data are downloaded. This is the earliest year for which these data are available at the block group level through the Census API. Although the data are 5 years after the date of the SLD data, inaccuracies caused by this date mismatch should be small for the purpose of estimating the SimBzone models for the following reasons:
#* Land use and population shifts are relatively slow;
#* The building data are aggregated into 2 types (single-family, multifamily);
#* The building proportions are used in estimating the models; and,
#* The income data are normalized by median income of the region.
#
### Smart Location Database
#The US Environmental Protection Agency's (EPA) [Smart Location Database](https://www.epa.gov/smartgrowth/smart-location-mapping) is the principal source of data used for developing the method for the synthesizing Bzones. The SLD includes a large number of land use and transportation measures at the Census block group level for the year 2010. The large majority of these are measures of the so called *5D* measures that have been found to have significant relationships to personal travel: density, diversity, design, distance to transit, and access to destinations. Several 5D measures are used in estimating the multimodal travel models that will be incorporated into VisionEval in the future. These measures are calculated by modules in the VELandUse package and they need to be calculated by modules in the VESimLandUse package as well. The SLD data used for estimating SimBzone models includes some additional data items that were added to the dataset for estimating the multimodal travel models. These include the amount of population within 5 miles of each block group and the amount of employment within 2 miles of each block group. The population and employment totals were computed based on straight-line distances between block group centroids. These values are used to compute a destination accessibility measure that is the [harmonic mean](https://en.wikipedia.org/wiki/Harmonic_mean) of the two values. This destination accessibility measure is used instead of the measures in the SLD which do not adequately distinguish accessibility in smaller urbanized areas. The harmonic mean of population within 5 miles and employment within 2 miles has been found to be useful in distinguishing area types in urbanized areas of different sizes. The `processSLD` carries out these steps.
#
### National Transit Database (NTD)
#The `processTransitData` function reads in 2010 transit service, agency, and urbanized area files downloaded from the National Transit Database [website](https://www.transit.dot.gov/ntd). These downloaded files are included in the `inst/extdata` directory of this package. The function sums up the annual vehicle miles for fixed-route transit and vehicle revenue miles for fixed route transit by urbanized area. The urbanized area names are checked against the names in the Smart Location Database and are made consistent so that the transit data can be joined with the SLD dataset.
#
### Making the SimBzone Estimation Dataset
#The SimBzone model estimation dataset combines the Census, SLD, and NTD datasets along with the latitudes and longitudes of the block group centroids (used for map documentation of models). The variables are limited to those needed to model Bzone attributes used in the multimodal travel model and other VisionEval modules. The dataset is cleaned to remove block groups that have no activity (i.e. households or jobs) or no land area. Comments in the script provide specifics about cleaning. In addition, some of the 5D measures are recalculated. The density measure (referred to as D1D in the SLD), a measure of households and jobs per acre, is calculated using the land area (excludes water bodies) recorded in the SLD rather than the unprotected land area for the following reasons:
#* The activity density of block groups needs to "add up" to the overall density of the urban area they are a part of;
#* The unprotected land area of the large majority of block groups is equal to the land area; and,
#* A significant number of block groups had no recorded unprotected land area.
#The diversity measure (referred to as D2A_JPHH), the ratio of jobs to housing, is recalculated to assure that it is consistent with the numbers of jobs and households recorded in the SLD. In addition, the entropy measure is recalculated to be consistent with the entropy measure used in the multimodal travel model. This measure is calculated in the same way as the SLD entropy measures but with 3 employment sectors (retail, service, other), rather than 5.
#</doc>

#Temporary code for development
#------------------------------
library(visioneval)
library(tidycensus)
library(stringr)


#======================================================================
#Function to process census block group housing types and median income
#======================================================================
#' Process census block group housing and median income data downloaded using
#' the Census API.
#'
#' \code{processCensusHousingInc} processes Census block group housing and
#' median income data for states and the District of Columbia in the United
#' States downloaded using the Census API.
#'
#' This function processes block group level data for numbers of dwelling units
#' by type and household median income that has been downloaded using the Census
#' API. Housing units groups are aggregated into to categories, single-family
#' and multifamily. Single family units include all detached dwelling units.
#' Multifamily include all other dwelling units. Note to use this function, you
#' must have a Census API key. You need to get a Census API key from this
#' website: https://api.census.gov/data/key_signup.html Then uncomment the
#' following line of code and insert the key where indicated
#' census_api_key(INSERT CENSUS API KEY HERE, install = TRUE)
#'
#' @param Data_df A data frame produced the get_acs function in the tidycensus
#' package.
#' @param BldSzVars_ A string vector identifying the names of the building
#' size variables in the ACS dataset.
#' @param IncVar A string identifying the name of the median income variable in
#' the ACS dataset.
#' @return A data frame containing the following components:
#' GeoID - Census block group ID
#' Total - Total number of dwelling units
#' NumSF - Number of single-family dwelling units
#' NumMF - Number of multifamily dwelling units
#' PropSF - Proportion of dwelling units that are single family
#' PropMF - Proportion of dwelling units that are multifamily
#' MedianInc - Median household income
#' @export
#' @import tidycensus utils
processCensusHousingInc <- function(Data_df, BldSzVars_, IncVar) {
  BldgData_df <- Data_df[Data_df$variable %in% substr(BldSzVars_, 1, 10),]
  Bldg_BgSz <- matrix(BldgData_df$estimate, ncol = 11, byrow = TRUE)
  Tot_Bg <- Bldg_BgSz[,1]
  SF_Bg <- rowSums(Bldg_BgSz[,2:3])
  MF_Bg <- rowSums(Bldg_BgSz[,4:10])
  MedianInc_ <- Data_df[Data_df$variable %in% substr(IncVar, 1, 10),]$estimate
  data.frame(
    GeoID = as.character(matrix(Data_df$GEOID, ncol = 12, byrow = TRUE)[,1]),
    Total = Tot_Bg,
    NumSF = SF_Bg,
    NumMF = MF_Bg,
    PropSF = SF_Bg / Tot_Bg,
    PropMF = MF_Bg / Tot_Bg,
    MedianInc = MedianInc_
  )
}


#====================================================
#Function to load and process smart location database
#====================================================
#' Read in and process Smart Location Databse (SLD)
#'
#' \code{processSLD} reads in an augmented Smart Location Database in the form
#' of a 'tibble' and processes it.
#'
#' This function reads in an augmented version of the Smart Location Database
#' used in the estimation of the multi-modal travel model by Liming Wang et.al.
#' The number of columns are reduced to those that will be used in the
#' estimation of land use simulation modules. In addition, the records are
#' limited to records for census block groups located in states and the District
#' of Columbia. A destination accessibility measure is calculated as well.
#'
#' @return A data frame containing the following components:
#' GEOID10 - Census block group 12-digit FIPS code in 2010
#' SFIPS - State FIPS code
#' TOTPOP10 - Population, 2010
#' HH - Households (occupied housing units), 2010
#' EMPTOT - Total employment, 2010
#' E5_RET10 - Retail jobs within a 5-tier employment classification scheme
#' E5_SVC10 - Service jobs within a 5-tier employment classification scheme
#' AC_TOT - Total geometric area of the block group
#' AC_LAND - Total land area in acres
#' AC_UNPR - Total land area in acres that is not protected from development
#' D1D - Gross activity density (employment + HUs) on unprotected land
#' D2A_JPHH - Jobs per household
#' D3bpo4 - Intersection density in terms of pedestrian-oriented intersections
#' having four or more legs per square mile
#' D4c - Aggregate frequency of transit service within 0.25 miles of block group
#' boundary per hour during evening peak period
#' TOTPOP10_5 - Population within 5 miles of block group centroid
#' EMPTOT_2 - Jobs within 2 miles of block group centroid
#' UA_NAME - Urbanized area name
#' D5 - Destination accessibility measure that is the harmonic mean of
#' TOTPOP10_5 and EMPTOT_2
#' @export
processSLD <- function() {
  #Load augmented SLD dataset developed for the multimodal travel model
  SLD_tb <- readRDS("inst/extdata/SLD_tb.rds")
  #Remove records for territories
  TerrFips_ <- c("60", "66", "69", "72")
  SLD_tb <- SLD_tb[!(SLD_tb$SFIPS %in% TerrFips_),]
  #Fields to keep
  #--------------
  KeepFields_ <- c(
    "GEOID10", #Census block group 12-digit FIPS code
    "SFIPS", #State FIPS code
    "TOTPOP10", #Total block group population in 2010
    "HH", #Number of households in block group
    "EMPTOT", #Total number of jobs in block group in 2010
    "E5_RET10", #Total number of retail jobs in block group in 2010
    "E5_SVC10", #Total number of service jobs in block group in 2010
    "AC_TOT", #Total area in acres in the block group
    "AC_LAND", #Total land area in acres in the block group
    "AC_UNPR",  #Total unprotected land area in acres in the block group
    "D1D", #Gross activity density (employment + HUs) on unprotected land
    "D2A_JPHH", #Jobs per household
    "D3bpo4", #Intersection density of pedestrian-oriented intersections having four or more legs per square mile
    "D4c", #Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period
    "TOTPOP10_5", #Total population within 5 miles of block group centroid
    "EMPTOT_2", #Total employment within 2 miles of block group centroid
    "UA_NAME" #US Census urbanized area name
  )
  SLD_df <- data.frame(SLD_tb[,KeepFields_])
  #Calculate regional accessibility measure, D5
  SLD_df$D5 <- with(SLD_df, 2 * EMPTOT_2 * TOTPOP10_5 / (EMPTOT_2 + TOTPOP10_5))
  #If D5 equals 0, set D5 equal to 1
  SLD_df$D5[SLD_df$D5 == 0] <- 1
  #Remove substitute single hyphens for double hyphens
  SLD_df$UA_NAME <- gsub("--", "-", SLD_df$UA_NAME)
  #Return the result
  SLD_df
}


#================================
#Function to process transit data
#================================
#' Process transit data.
#'
#' \code{processTransitData} reads in 2010 public transit datasets from the
#' National Transit Database and calculates vehicle miles and vehicle revenue
#' miles for fixed-route transit services by urbanized area.
#'
#' This function reads transit service, agency, and urbanized area files from
#' the National Transit Database for 2010 and creates a dataset of vehicle miles
#' and vehicle revenue miles for fixed route transit by urbanized area. The
#' urbanized area names are checked against the names in the Smart Location
#' Database and are made consistent.
#'
#' @return A data frame containing the following components:
#' UaName - Urbanized area names corresponding to names in the Smart Location
#' Database
#' VehicleMiles - Annual vehicle miles of fixed-route transit service in the
#' urbanized area
#' RevenueMiles - Annual vehicle revenue miles of fixed-route transit service in
#' the urbanized area
#' @export
#' @import stringr
processTransitData <- function() {
  #--------------------
  #Process service data
  #--------------------
  Service_df <- read.csv("inst/extdata/2010_Service.csv", as.is = TRUE)
  FieldsToKeep_ <-
    c(
      "Trs_Id",
      "Mode_Cd",
      "Service_Cd",
      "Time_Period_Desc",
      "Vehicle_Or_Train_Miles",
      "Vehicle_Or_Train_Rev_Miles"
    )
  Service_df <- Service_df[,FieldsToKeep_]
  Service_df$Time_Period_Desc <- str_trim(Service_df$Time_Period_Desc)
  Service_df <-
    Service_df[grep("Annual Total", Service_df$Time_Period_Desc),]
  #Convert numbers
  rmCommas <- function(X_) gsub(",", "", X_, fixed = TRUE)
  Service_df$Vehicle_Or_Train_Miles <-
    as.numeric(rmCommas(Service_df$Vehicle_Or_Train_Miles))
  Service_df$Vehicle_Or_Train_Rev_Miles <-
    as.numeric(rmCommas(Service_df$Vehicle_Or_Train_Rev_Miles))
  #Only keep records for fixed-route urban transit
  ModesToKeep_ <- c(
    "HR", #Heavy Rail,
    "CR", #Commuter Rail,
    "LR", #Light Rail,
    "SR", #Streetcar,
    "MG", #Monorail/Automated Guideway,
    "CC", #Cable Car,
    "YR", #Hybrid Rail,
    "IP", #Inclined Plain,
    "MB", #Bus,
    "TB", #TrolleyBus,
    "CB", #Commuter Bus,
    "RB"  #Bus Rapid Transit
  )
  Service_df <- Service_df[Service_df$Mode_Cd %in% ModesToKeep_,]
  rm(FieldsToKeep_, ModesToKeep_, rmCommas)
  #-------------------
  #Process agency data
  #-------------------
  #Load agency information
  Agency_df <- read.csv("inst/extdata/2010_Agency_Information.csv", as.is = TRUE)
  FieldsToKeep_ <-
    c(
      "Trs_Id",
      "City_Nm",
      "State_Desc",
      "Company_Nm"
    )
  Agency_df <- Agency_df[, FieldsToKeep_]
  Agency_df$State_Desc <- str_trim(Agency_df$State_Desc)
  #Remove Puerto Rico and Virgin Islands
  KeepStates_ <- !(Agency_df$State_Desc %in% c("PR", "Virgin Islands"))
  Agency_df <- Agency_df[KeepStates_,]
  rm(KeepStates_)
  #Load urbanized area information and add to agency information
  Uza_df <- read.csv("inst/extdata/2010_transit_uza_data.csv", as.is = TRUE)
  Agency_df$Ua_Name <-
    Uza_df$Urbanized.Area[match(Agency_df$Trs_Id, Uza_df$ID)]
  rm(FieldsToKeep_, Uza_df)
  #-------------------------------------------------------
  #Correspond NTD urbanized areas with SLD urbanized areas
  #-------------------------------------------------------
  #Load SLD data
  SLD_df <- readRDS("inst/extdata/SLD_df.rds")
  #Identify urbanized area names to be renamed to be consistent with SLD
  Rename_ <- local({
    #Make vectors of urbanized area names from SLD and NTD
    UA_NAME_ <- unique(SLD_df$UA_NAME) #SLD names
    Ua_Name_ <- unique(Agency_df$Ua_Name) #NTD names
    #Identify NTD names that don't match SLD names
    MissingNames_ <- Ua_Name_[!(Ua_Name_ %in% UA_NAME_)]
    MissingNames_ls <- strsplit(MissingNames_, ", ")
    names(MissingNames_ls) <- MissingNames_
    #Find as many corresponding names as possible using only the urbanized area name
    Tmp_ls <- lapply(MissingNames_ls, function(x) {
      UA_NAME_[grep(x[1], UA_NAME_)]
    })
    #Identify found names
    FoundNames_ls <- Tmp_ls[unlist(lapply(Tmp_ls, length)) == 1]
    #Identify names when multiple matches
    MultiNames_ls <- list(
      `Albany, NY` = "Albany-Schenectady, NY",
      `Cumberland, MD--WV` = "Cumberland, MD-WV-PA",
      `Danville, VA` = "Danville, VA-NC",
      `Louisville, KY-IN` = "Louisville/Jefferson County, KY-IN",
      `Reno, NV` = "Reno, NV-CA",
      `Honolulu, HI` = "Urban Honolulu, HI",
      `Las Vegas, NV` = "Las Vegas-Henderson, NV"
    )
    #Identify names when none found
    NoneFound_ <- names(Tmp_ls)[unlist(lapply(Tmp_ls, length)) == 0]
    NoneFound_ls <- list(
      `Aberdeen-Havre de Grace-Bel Air, MD` = "Aberdeen-Bel Air South-Bel Air North, MD",
      `Allentown-Bethlehem, PA-NJ` = "Allentown, PA-NJ",
      `Atascadero-El Paso de Robles (Paso Robles), CA` = "El Paso de Robles (Paso Robles)-Atascadero, CA",
      `Bonita Springs-Naples, FL` = "Bonita Springs, FL",
      `Brooksville, FL` = "Spring Hill, FL",
      `Gulfport-Biloxi, MS` = "Gulfport, MS",
      `Indio-Cathedral City-Palm Springs, CA` = "Indio-Cathedral City, CA",
      `Kennewick-Richland, WA` = "Kennewick-Pasco, WA",
      `Los Angeles-Long Beach-Santa Ana, CA` = "Los Angeles-Long Beach-Anaheim, CA",
      `North Port-Punta Gorda, FL` = "North Port-Port Charlotte, FL",
      `Seaside-Monterey-Marina, CA` = "Seaside-Monterey, CA",
      `South Lyon-Howell-Brighton, MI` = "South Lyon-Howell, MI",
      `Vero Beach-Sebastian, FL` = "Sebastian-Vero Beach South-Florida Ridge, FL",
      `Victorville-Hesperia-Apple Valley, CA` = "Victorville-Hesperia, CA",
      `Wildwood-North Wildwood-Cape May, NJ` = NA
    )
    #Put together a vector of all the corresponding names
    c(unlist(FoundNames_ls), unlist(MultiNames_ls), unlist(NoneFound_ls))
  })
  #Modify the urbanized area name entries for these names
  for (nm in names(Rename_)) {
    Agency_df$Ua_Name[Agency_df$Ua_Name == nm] <- Rename_[nm]
  }
  rm(Rename_, nm)
  #-------------------------------------------------------------------------------
  #Calculate fixed route transit vehicle miles and revenue miles by urbanized area
  #-------------------------------------------------------------------------------
  #Add the urbanized area to the service data
  Service_df$Ua_Name <-
    Agency_df$Ua_Name[match(Service_df$Trs_Id, Agency_df$Trs_Id)]
  #Delete 6 records having no urbanized area name
  Service_df <- Service_df[!is.na(Service_df$Ua_Name),]
  #Calculate vehicle miles by urbanized area
  VehicleMiles_Ua <-
    with(Service_df, tapply(Vehicle_Or_Train_Miles, Ua_Name, sum, na.rm = TRUE))
  #Calculate revenue miles by urbanized area
  RevenueMiles_Ua <-
    with(Service_df, tapply(Vehicle_Or_Train_Rev_Miles, Ua_Name, sum, na.rm = TRUE))
  #Combine into a data frame
  Transit_df <- data.frame(
    UaName = names(VehicleMiles_Ua),
    VehicleMiles = unname(VehicleMiles_Ua),
    RevenueMiles = unname(RevenueMiles_Ua)
  )
  #Return the result
  Transit_df
}


#=======================================================================
#Create the dataset to use for estimating models for simulating land use
#=======================================================================
#' Create the dataset to use for estimating land use simulation models.
#'
#' \code{createSimLandUseDataset} reads in the Census, Smart Location Database,
#' and Transit datasets and creates the dataset that is used for estimating
#' land use simulation models.
#'
#' This function reads in the Census, Smart Location Database, and Transit
#' datasets and creates the dataset that is used for estimating land use
#' simulation models.
#'
#' @return A data frame containing the following components:
#' GEOID10 - Census block group 12-digit FIPS code
#' SFIPS - State FIPS code
#' TOTPOP10 - Population, 2010
#' HH - Households (occupied housing units), 2010
#' EMPTOT - Total employment, 2010
#' E5_RET10 - Retail jobs within a 5-tier employment classification scheme
#' E5_SVC10 - Service jobs within a 5-tier employment classification scheme
#' AC_TOT - Total geometric area of the census block group
#' AC_LAND - Total land area in acres
#' AC_UNPR - Total land area in acres that is not protected from development
#' D1D - Ratio of gross activity (employment + HUs) to land area
#' D2A_JPHH - Jobs per household calculated from EMPTOT and HH
#' D3bpo4 - Intersection density in terms of pedestrian-oriented intersections
#' having four or more legs per square mile
#' D4c - Aggregate frequency of transit service within 0.25 miles of block group
#' boundary per hour during evening peak period
#' TOTPOP10_5 - Population within 5 miles of block group centroid
#' EMPTOT_2 - Total employment within 2 miles of block group centroid
#' UA_NAME - Census urbanized area name
#' D5 - Destination accessibility measure that is the harmonic mean of
#' TOTPOP10_5 and EMPTOT_2
#' STATE - Postal code for state
#' UZA_NAME - Urbanized area name separated by state
#' LAT - Latitude of block group centroid
#' LNG - Longitude of block group centroid
#' TOTACT - Total number of jobs and households
#' D1D_SLD - Ratio of gross activity (employment + HUs) to unprotected land area
#' D2A_JPHH_SLD - Jobs per household included in the SLD
#' D2A_EPHHM - Employment and household entropy
#' PropSF - Proportion of households living in single-family dwellings
#' PropMF - Proportion of households living in multifamily dwellings
#' MedianInc - Median income of households
#' TransitVehMi - Annual fixed-route transit vehicle miles in urbanized area
#' TransitRevMi - Annual fixed-route transit vehicle revenue miles in urbanized
#' area
#' LocType - Location type (Urban, Town, Rural)
#' @export
createSimLandUseDataset <- function() {
  D_df <- readRDS("inst/extdata/SLD_df.rds")
  #Add state abbreviation
  StFips_df <- readRDS("inst/extdata/StateFIPS_df.rds")
  D_df$SFIPS <- as.character(D_df$SFIPS)
  D_df$STATE <- StFips_df$Abbr[match(D_df$SFIPS, StFips_df$Fips)]
  rm(StFips_df)
  #Identify individual state components of urbanized areas
  #so that parts of urbanized areas split between states can be addressed alone
  UzaName_ <- unlist(lapply(strsplit(D_df$UA_NAME, ","), function(x) x[1]))
  D_df$UZA_NAME <- paste(UzaName_, D_df$STATE, sep = ", ")
  rm(UzaName_)
  #Add the latitude and longitude of the block group centroids
  load("inst/extdata/BlkGrpCtr_df.Rda")
  D_df$LAT <- BlkGrpCtr_df$lat[match(D_df$GEOID10, BlkGrpCtr_df$GeoId)]
  D_df$LNG <- BlkGrpCtr_df$lng[match(D_df$GEOID10, BlkGrpCtr_df$GeoId)]
  #Remove records for New York UZA that have no activity and no land
  D_df <- D_df[D_df$AC_LAND != 0,]
  #Remove records that have NA values for D5
  D_df <- D_df[!is.na(D_df$D5),]
  #Calculate total activity
  D_df$TOTACT <- with(D_df, HH + EMPTOT)
  #Remove records that have no total activity
  D_df <- D_df[D_df$TOTACT >= 1,]
  #Recalculate D1D using land area rather than unprotected land area so that
  #average density values can be calculated using consistent data and compared to
  #overall urbanized area density.
  D_df$D1D_SLD <- D_df$D1D
  D_df$D1D <- with(D_df, TOTACT / AC_LAND)
  #Recalculate D2A_JPHH
  D_df$D2A_JPHH_SLD <- D_df$D2A_JPHH
  D_df$D2A_JPHH <- with(D_df, EMPTOT / HH)
  #Calculate entropy measure (D2A_EPHHM) consistent with variables used in
  #VELandUse and VESimLandUse packages which only distinguish retail, service,
  #and other employment whereas SLD uses 5 employment categories
  calcEntropy <- function(Hh_Bz, RetEmp_Bz, SvcEmp_Bz, OthEmp_Bz) {
    TotAct_Bz <- Hh_Bz + RetEmp_Bz + SvcEmp_Bz + OthEmp_Bz
    Tmp_df <- data.frame(
      TotAct = TotAct_Bz,
      NumHh = Hh_Bz,
      RetEmp = RetEmp_Bz,
      SvcEmp = SvcEmp_Bz,
      OthEmp = OthEmp_Bz
    )
    calcEntropyTerm <- function(ActName) {
      Act_ <- Tmp_df[[ActName]]
      ActRatio_ <- Act_ / Tmp_df$TotAct
      LogActRatio_ <- ActRatio_ * 0
      LogActRatio_[Act_ != 0] <- log(Act_[Act_ != 0] / Tmp_df$TotAct[Act_ != 0])
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
    -A_ / log(N_)
  }
  D_df$D2A_EPHHM <- calcEntropy(
    Hh_Bz = D_df$HH,
    RetEmp_Bz = D_df$E5_RET10,
    SvcEmp_Bz = D_df$E5_SVC10,
    OthEmp_Bz = with(D_df, EMPTOT - E5_RET10 - E5_SVC10)
  )
  #Combine census data
  CensusBlkGrp_df <- readRDS("inst/extdata/CensusHouseTypeInc_df.rds")
  D_df$PropSF <- CensusBlkGrp_df$PropSF[match(D_df$GEOID10, CensusBlkGrp_df$GeoID)]
  D_df$PropMF <- CensusBlkGrp_df$PropMF[match(D_df$GEOID10, CensusBlkGrp_df$GeoID)]
  D_df$MedianInc <- CensusBlkGrp_df$MedianInc[match(D_df$GEOID10, CensusBlkGrp_df$GeoID)]
  #Add the transit data
  Transit_df <- readRDS("inst/extdata/Transit_df.rds")
  D_df$TransitVehMi <-
    Transit_df$VehicleMiles[match(D_df$UA_NAME, Transit_df$UaName)]
  D_df$TransitRevMi <-
    Transit_df$RevenueMiles[match(D_df$UA_NAME, Transit_df$UaName)]
  #Identify places having NA in name
  PlaceName_ <- unlist(lapply(strsplit(D_df$UZA_NAME, ","), function(x) {
    x[1]
  }))
  #Calculate area population
  TotPop_Ua <- tapply(D_df$TOTPOP10, D_df$UA_NAME, sum)
  #Identify location types from names and total population
  D_df$LocType <- "Town"
  D_df$LocType[D_df$UA_NAME %in% names(TotPop_Ua)[TotPop_Ua >= 40000]] <- "Urban"
  D_df$LocType[PlaceName_ == "NA"] <- "Rural"
  #Return the result
  D_df
}

#====================================================================
#Do the data processing to create the sim land use estimation dataset
#====================================================================
#Process Census housing and income data if not already done
#----------------------------------------------------------
if (!file.exists("inst/extdata/CensusHouseTypeInc_df.rds"))  {
  #Define a vector of state abbreviations
  States_ <-
    c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI",
      "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN",
      "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH",
      "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA",
      "WV", "WI", "WY")
  #Define the variable names to retrieve
  BldSzVars_ <- c(
    "B25024_001E", "B25024_002E", "B25024_003E", "B25024_004E",
    "B25024_005E",  "B25024_006E",  "B25024_007E",  "B25024_008E",
    "B25024_009E",  "B25024_010E",  "B25024_011E")
  IncVar <- "B19013_001E"
  CensusBlkGrp_ls <- list()
  for (St in States_) {
    #Download data from Census
    Census_df <-
      get_acs(geography = "block group",
              variables = c(BldSzVars_, IncVar),
              state = St,
              year = 2015)
    #Process Census download
    CensusBlkGrp_ls[[St]] <-
      processCensusHousingInc(Census_df, BldSzVars_, IncVar)
  }
  #Combine into a data frame
  CensusBlkGrp_df <- do.call(rbind, CensusBlkGrp_ls)
  CensusBlkGrp_df$State <- rep(States_, unlist(lapply(CensusBlkGrp_ls, nrow)))
  rownames(CensusBlkGrp_df) <- NULL
  #Save the dataset and clean up
  saveRDS(CensusBlkGrp_df, "inst/extdata/CensusHouseTypeInc_df.rds")
  rm(States_, BldSzVars_, IncVar, CensusBlkGrp_ls, St, CensusBlkGrp_df)
}
#Process the Smart Location Database if not already done
#-------------------------------------------------------
if (!file.exists("inst/extdata/SLD_df.rds"))  {
  saveRDS(processSLD(), "inst/extdata/SLD_df.rds")
}
#Process transit data if not already done
#----------------------------------------
if (!file.exists("inst/extdata/Transit_df.rds"))  {
  saveRDS(processTransitData(), "inst/extdata/Transit_df.rds")
}
#Process and save the sim land use model estimation data if not already done
#---------------------------------------------------------------------------
#' Land use simulation model estimation dataset
#'
#' A data frame containing data used for estimating land use simulation models.
#'
#' @format A data frame having the following components:
#' \describe{
#'   \item{GEOID10}{Census block group 12-digit FIPS code}
#'   \item{SFIPS}{State FIPS code}
#'   \item{TOTPOP10}{Population, 2010}
#'   \item{HH}{Households (occupied housing units), 2010}
#'   \item{EMPTOT}{Total employment, 2010}
#'   \item{E5_RET10}{Retail jobs within a 5-tier employment classification scheme}
#'   \item{E5_SVC10}{Service jobs within a 5-tier employment classification scheme}
#'   \item{AC_TOT}{Total geometric area of the census block group}
#'   \item{AC_LAND}{Total land area in acres}
#'   \item{AC_UNPR}{Total land area in acres that is not protected from development}
#'   \item{D1D}{Ratio of gross activity (employment + HUs) to land area}
#'   \item{D2A_JPHH}{Jobs per household calculated from EMPTOT and HH}
#'   \item{D3bpo4}{Intersection density in terms of pedestrian-oriented intersections having four or more legs per square mile}
#'   \item{D4c}{Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period}
#'   \item{TOTPOP10_5}{Population within 5 miles of block group centroid}
#'   \item{EMPTOT_2}{Total employment within 2 miles of block group centroid}
#'   \item{UA_NAME}{Census urbanized area name}
#'   \item{D5}{Destination accessibility measure that is the harmonic mean of TOTPOP10_5 and EMPTOT_2}
#'   \item{STATE}{Postal code for state}
#'   \item{UZA_NAME}{Urbanized area name separated by state}
#'   \item{LAT}{Latitude of block group centroid}
#'   \item{LNG}{Longitude of block group centroid}
#'   \item{TOTACT}{Total number of job and households}
#'   \item{D1D_SLD}{Ratio of gross activity (employment + HUs) to unprotected land area}
#'   \item{D2A_JPHH_SLD}{Jobs per household included in the SLD}
#'   \item{D2A_EPHHM}{Employment and household entropy}
#'   \item{PropSF}{Proportion of households living in single-family dwellings}
#'   \item{PropMF}{Proportion of households living in multifamily dwellings}
#'   \item{MedianInc}{Median income of households}
#'   \item{TransitVehMi}{Annual fixed-route transit vehicle miles in urbanized area}
#'   \item{TransitRevMi}{Annual fixed-route transit vehicle revenue miles in urbanized area}
#'   \item{LocType}{Location type (Urban, Town, Rural)}
#' }
#' @source MakeSimBzoneEstDataset.R script.
"SimLandUseData_df"
if (!file.exists("data/SimLandUseData_df.rda"))  {
  SimLandUseData_df <- createSimLandUseDataset()
  usethis::use_data(SimLandUseData_df, overwrite = TRUE)
}


#====================
#Module documentation
#====================
#Run module automatic documentation
#----------------------------------
visioneval::documentModule("MakeSimBzoneEstDataset")
