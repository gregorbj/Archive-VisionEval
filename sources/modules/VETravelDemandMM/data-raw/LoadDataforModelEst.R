#' This script load necessary data for model estimation In addition to the two
#' major datasets in NHTS2009 and SLD package, it reads a few additional data
#' sets in inst/extdata:
#'
#'     - confidential residence block group for households in NHTS 2009
#'       (in hhctbg.csv)
#'     - Table HM71 and HM72 from HPMS
#'     - UZA transit system stats from National Transit Database
#'     - list of Urban Area and its name from the Census Beauru
#'     - Place types derived from EPA's Smart Location Database
#'
#' You will not be able to run this script unless you have a copy of the
#' confidential residence block group for households in NHTS 2009, which we are
#' not able to share due to the confidentiality agreement.

library(NHTS2009)
library(SLD)
library(tidyverse)
library(readxl)
library(stringr)
library(readr)

## load confidential block group location of households & look up in SLD
hhctbg <- read_csv("inst/extdata/hhctbg.csv", col_types=cols(HOUSEID='c', HHBG10='c'))
hhctbg.geoid <- hhctbg %>%
  filter(HHBG10 != '-9') %>%
  mutate(GEOID10=paste0(HHSTFIPS10, HHCNTYFP10, HHCT10, HHBG10)) %>%
  dplyr::select(HOUSEID, GEOID10)

Hh_df <- Hh_df %>% left_join(hhctbg.geoid, by="HOUSEID")

# 2015 NTD system wide operation and services time series (prepared by Brian Gregor)
NTD_df <- read_excel("inst/extdata/NTD-TS2.2.xlsx",
                      sheet="UZA Totals-20", col_names=T, skip=2)

NTD_df <- NTD_df %>% dplyr::select(UZA, UZAVehOp=VehOp,
                UZAVehAv=VehAv, UZAAVRM=AVRM,
                UZAAVRH=AVRH, UZAULPT=ULPT,
                UZAPM=PM, UZAAVRHPC=AVRHPC)

#fix ua names to be consistent with those in Census
NTD_df <- NTD_df %>%
  mutate(UZA2=str_replace_all(UZA, "-", "--"),
         UZA2 = dplyr::recode(UZA2,
                                  "Aberdeen--Havre de Grace-Bel Air, MD"="Aberdeen--Bel Air South--Bel Air North, MD",
                                  "Albany, NY" = "Albany--Schenectady, NY",
                                  "Allentown--Bethlehem, PA--NJ" = "Allentown, PA--NJ" ,
                                  "Augusta--Richmond County, GA--SC" = "Augusta--Richmond County, GA--SC"  ,
                                  "Benton Harbor--St. Joseph, MI" = "Benton Harbor--St. Joseph--Fair Plain, MI" ,
                                  "Bonita Springs--Naples, FL" = "Bonita Springs, FL" ,
                                  #"Brooksville, FL"
                                  "Cumberland, MD----WV" = "Cumberland, MD--WV--PA" ,
                                  #"Danville, IL", ##??
                                  "Daytona Beach--Port Orange, FL" = "Palm Coast--Daytona Beach--Port Orange, FL" ,
                                  "El Centro, CA" = "El Centro--Calexico, CA" ,
                                  "Fayetteville--Springdale, AR" = "Fayetteville--Springdale--Rogers, AR--MO" ,
                                  "Fort Walton Beach, FL" = "Fort Walton Beach--Navarre--Wright, FL" ,
                                  #Galveston, TX,
                                  "Gulfport--Biloxi, MS" = "Gulfport, MS" ,
                                  "Honolulu, HI" = "Urban Honolulu, HI" ,
                                  "Indio--Cathedral City--Palm Springs, CA" = "Indio--Cathedral City, CA" ,
                                  "Kennewick--Richland, WA" = "Kennewick--Pasco, WA" ,
                                  "Kenosha, WI" = "Kenosha, WI--IL" ,
                                  "Las Vegas, NV" = "Las Vegas--Henderson, NV" ,
                                  "Leesburg--Eustis, FL" = "Leesburg--Eustis--Tavares, FL" ,
                                  "Los Angeles--Long Beach--Santa Ana, CA" = "Los Angeles--Long Beach--Anaheim, CA" ,
                                  "Louisville, KY--IN" = "Louisville/Jefferson County, KY--IN" ,
                                  "Minneapolis--St. Paul, MN" = "Minneapolis--St. Paul, MN--WI" ,
                                  "Monessen, PA" = "Monessen--California, PA" ,
                                  "Myrtle Beach, SC" = "Myrtle Beach--Socastee, SC--NC" ,
                                  "North Port--Punta Gorda, FL" = "North Port--Port Charlotte, FL" ,
                                  "Norwich--New London, CT" = "Norwich--New London, CT--RI" ,
                                  "Poughkeepsie--Newburgh, NY" = "Poughkeepsie--Newburgh, NY--NJ" ,
                                  "Raleigh, NC" = "Raleigh--Durham, NC" ,
                                  "Reno, NV" = "Reno, NV--CA" ,
                                  #"Sandusky, OH"
                                  "Salt Lake City, UT" = "Salt Lake City--West Valley City, UT" ,
                                  "Seaside--Monterey--Marina, CA" = "Seaside--Monterey, CA" ,
                                  "South Lyon--Howell--Brighton, MI" = "South Lyon--Howell, MI" ,
                                  "Spokane, WA--ID" = "Spokane, WA" ,
                                  #"St. Charles, MD"
                                  "Vero Beach--Sebastian, FL" = "Sebastian--Vero Beach South--Florida Ridge, FL" ,
                                  "Victorville--Hesperia--Apple Valley, CA" = "Victorville--Hesperia, CA" ,
                                  "Westminster, MD" = "Westminster--Eldersburg, MD"
                                  )
         )

SLD_df <- SLD_df %>% left_join(NTD_df, by=c("UA_NAME"="UZA2"))

## load HPMS DATA
process_hm_df <- function(df) {
  df <- df %>%
    mutate(UZA=ifelse(is.na(UZA), "", UZA),
           State=ifelse(is.na(State), "", State)) %>%
    filter(tolower(UZA) != "total" & !startsWith(tolower(UZA), "for footnotes"))

  # fill UZA
  while (any(nchar(trimws(df$UZA))==0)) {
    df <- df %>%
      mutate(UZA=ifelse(nchar(trimws(UZA))==0, dplyr::lag(UZA, n=1), UZA))
  }

  df <- df %>%
    mutate(UZA=trimws(UZA)) %>%
    arrange(desc(pop1000)) %>%
    group_by(UZA) %>%
    mutate(State=trimws(State),
           States=paste(State, collapse="-"),
           States=str_replace(States, "^-", ""),
           UZAState=paste(UZA, States, sep=" ")
    ) %>%
    ungroup() %>%
    filter(!is.na(States), States != "NA", nchar(States)!=0)

  ## Florence AL-SC are kept as two separate UAs by the Census
  florence <- df %>%
    filter(UZA=="Florence", State != "") %>%
    mutate(UZAState=paste(UZA, State, sep=" "))

  df <- df %>% group_by(UZAState) %>%
    slice(1) %>%
    ungroup

  df <- df %>%
    filter(UZA != "Florence") %>%
    bind_rows(florence)

  df %>% dplyr::select(-c(UZA, State, States))

}

hm71 <- NULL
for (sheet in 1:9) {
  hm71.1 <- readxl::read_excel("inst/extdata/hm71.xls", sheet = sheet, col_names = FALSE, skip = 14)
  names(hm71.1) <- c("UZA", "State", "pop1000",
                     "interstate_freeway_miles", "other_freeway_miles",
                     "principal_arterial_miles", "minor_arterial_miles",
                     "collector_miles", "local_miles", "total_miles",
                     "interstate_dvmt", "other_freeway_dvmt",
                     "principal_arterial_dvmt", "minor_arterial_dvmt",
                     "collector_dvmt", "local_dvmt", "total_dvmt")

  hm71.1 <- process_hm_df(hm71.1)

  # not an efficient way
  if(is.null(hm71)) hm71 <- hm71.1
  else hm71 <- bind_rows(hm71, hm71.1)
}

hm72 <- NULL
for (sheet in 1:9) {
  hm72.1 <- readxl::read_excel("inst/extdata/hm72.xls", sheet = sheet, col_names = FALSE, skip = 14)
  names(hm72.1) <- c("UZA", "State", "total_miles",
                     "total_dvmt", "pop1000",
                     "land_area", "persons_per_sqm",
                     "total_miles_per_1000person", "dvmt_per_caipta", "freeway_miles",
                     "freeway_dvmt", "percent_freeway_miles",
                     "percent_freeway_dvmt", "aadt_freeway",
                     "freeway_lane_miles", "aadt_per_freeway_lane_miles")

  hm72.1 <- process_hm_df(hm72.1)
  if(is.null(hm72)) hm72 <- hm72.1
  else hm72 <- bind_rows(hm72, hm72.1)
}

#UA <- read_excel("inst/extdata/ua_list_ua.xls")
ua_census <- read_fwf("inst/extdata/ua_list_all.txt",
                      col_positions = fwf_positions(start=c(1, 11, 76, 90, 104, 123, 137, 156, 170, 184),
                                                    end=  c(5, 70, 84, 98, 117, 131, 150, 164, 178, 185),
                                                    col_names=c("UACE", "NAME", "POP", "HU", "AREALAND", "AREALANDSQMI",
                                                                "AREAWATER", "AREAWATERSQMI", "POPDEN", "LSADC")),
                      skip=1)

ua_census <- ua_census %>%
  rename(UA_NAME=NAME) %>%
  dplyr::select(UACE, UA_NAME)

UA <- ua_census %>% mutate(NAME1=str_replace_all(UA_NAME, "--", "-"),
                           NAME1=str_replace_all(NAME1, ",", ""),
                           NAME1 = dplyr::recode(NAME1,
                                                 "Albany-Schenectady NY" = "Albany NY",
                                                 "Allentown PA-NJ" = "Allentown-Bethlehem PA-NJ",
                                                 "Boise City ID" = "Boise ID",
                                                 "Urban Honolulu HI" = "Honolulu HI",
                                                 "Indio-Cathedral City CA" = "Indio-Cathedral City-Palm Springs CA",
                                                 "Las Vegas-Henderson NV" = "Las Vegas NV",
                                                 "Los Angeles-Long Beach-Anaheim CA" = "Los Angeles-Long Beach-Santa Ana CA",
                                                 "Louisville/Jefferson County KY-IN" = "Louisville KY-IN",
                                                 "Minneapolis-St. Paul MN-WI" = "Minneapolis-St. Paul MN",
                                                 "Nashville-Davidson TN" = "Nashville TN",
                                                 "Poughkeepsie-Newburgh NY-NJ" = "Poughkeepsie-Newburgh NY",
                                                 "Phoenix-Mesa AZ"="Phoenix AZ",
                                                 "Salt Lake City-West Valley City UT" = "Salt Lake City UT",
                                                 "Washington DC-VA-MD" = "Washington VA-MD-DC",
                                                 "Hartford CT" = "Hartford-Middletown CT",
                                                 "Mission Viejo-Lake Forest-San Clemente CA" ="Mission Viejo CA",
                                                 "New Haven CT" = "New Haven-Meridian CT",
                                                 "Murrieta-Temecula-Menifee CA" = "Temecula-Murrieta CA",
                                                 "Victorville-Hesperia CA"="Victorville-Hesperia-Apple Valley CA",
                                                 "Aguadilla-Isabela-San Sebasti�n PR"="Aguadilla-Isabela-San Sebastian PR",
                                                 "Augusta-Richmond County GA-SC"="Augusta GA-SC",
                                                 "Bonita Springs FL"="Bonita Springs-Naples FL",
                                                 "Palm Coast-Daytona Beach-Port Orange FL"="Daytona Beach-Port Orange FL",
                                                 "Little Rock AR"="Little Rock-N. Little Rock AR",
                                                 "Oxnard CA"="Oxnard-Ventura CA",
                                                 "Reno NV-CA"="Reno NV",
                                                 "Scranton PA"="Scranton-Wilkes-Barre PA",
                                                 "Aberdeen-Bel Air South-Bel Air North MD"="Aberdeen-Havre de Grace-Bel Air MD",
                                                 "Davenport IA-IL"="Davenport IL-IA",
                                                 "Fayetteville-Springdale-Rogers AR-MO"="Fayetteville-Springdale AR",
                                                 "Gulfport MS"="Gulfport-Biloxi MS",
                                                 "Kennewick-Pasco WA"="Kennewick-Richland WA",
                                                 "Norwich-New London CT-RI"="New London-Norwich CT",
                                                 "Athens-Clarke County GA"="Athens GA",
                                                 "Avondale-Goodyear AZ"="Avondale AZ",
                                                 "Fargo ND-MN"="Fargo-Moorhead ND-MN",
                                                 "Fort Walton Beach-Navarre-Wright FL"="Fort Walton Beach FL",
                                                 "Gastonia NC-SC"="Gastonia NC",
                                                 "Leesburg-Eustis-Tavares FL"="Leesburg-Eustis FL",
                                                 "Myrtle Beach-Socastee SC-NC"="Myrtle Beach SC",
                                                 "North Port-Port Charlotte FL"="North Port-Punta Gorda FL",
                                                 "Sebastian-Vero Beach South-Florida Ridge FL"="Vero Beach-Sebastian FL",
                                                 "Kenosha WI-IL"="Kenosha WI",
                                                 "Portsmouth NH-ME"="Portsmouth-Dover-Rochester NH-ME",
                                                 "San Germ�n-Cabo Rojo-Sabana Grande PR"="San German-Cabo Rojo-Sabana Grande PR",
                                                 "Seaside-Monterey CA"="Seaside-Monterey-Marina CA",
                                                 "South Lyon-Howell MI"="South Lyon-Howell-Brighton MI",
                                                 "Anniston-Oxford AL"="Anniston AL",
                                                 "El Centro-Calexico CA"="El Centro CA",
                                                 "Kailua (Honolulu County)-Kaneohe HI"="Kailua-Kaneohe HI",
                                                 "Prescott Valley-Prescott AZ"="Prescott AZ",
                                                 "Elizabethtown-Radcliff KY"="Radcliffe-Elizabethtown KY",
                                                 "Vineland NJ"="Vineland-Millville NJ",
                                                 "El Paso de Robles (Paso Robles)-Atascadero CA"="Atascadero-El Paso de Robles CA",
                                                 #"Florence SC"="Florence AL-SC",
                                                 "Florida-Imb�ry-Barceloneta PR"="Florida-Barceloneta-Bajadero PR",
                                                 "Twin Rivers-Hightstown NJ"="Hightstown NJ",
                                                 "Lady Lake-The Villages FL"="Lady Lake FL",
                                                 "Lewiston ME"="Lewiston-Auburn ME",
                                                 "Michigan City-La Porte IN-MI"="Michigan City IN-MI",
                                                 "Monessen-California PA"="Monessen PA",
                                                 "Round Lake Beach-McHenry-Grayslake IL-WI"="Round Lake Beach-McHenry-Grayslake WI-IL",
                                                 "Texarkana-Texarkana TX-AR"="Texarkana TX-AR",
                                                 "Conroe-The Woodlands TX"="The Woodlands TX",
                                                 "Weirton-Steubenville WV-OH-PA"="Weirton-Steubenville OH-WV-PA",
                                                 "Westminster-Eldersburg MD"="Westminster MD",
                                                 "Alton IL-MO"="Alton IL",
                                                 "Benton Harbor-St. Joseph-Fair Plain MI"="Benton Harbor-St. Joseph MI",
                                                 "Bristol-Bristol TN-VA"="Bristol TN-VA",
                                                 "Danville IL"="Danville VA-IL",
                                                 "Juana D�az PR"="Juana Diaz PR",
                                                 "Lafayette-Louisville-Erie CO"="Lafayette-Louisville CO",
                                                 "Bismarck ND"="Bismark-Mandan ND"
                           )
)

hm71 <- hm71 %>% left_join(UA %>% dplyr::select(NAME1, UACE), by=c("UZAState"="NAME1"))
hm72 <- hm72 %>% left_join(UA %>% dplyr::select(NAME1, UACE), by=c("UZAState"="NAME1"))

rm(hm71.1, hm72.1)

# Cannot find Brooksville FL/Mayaguez PR/St. Charles MD/Bismark-Mandan ND/
# Wildwood-North Wildwood-Cape May NJ in ua_list_all.xls, so these UZAs are not matched.
hm71 %>% filter(is.na(UACE)) %>% dplyr::select(UZAState, UACE) %>% as.data.frame()
hm72 %>% filter(is.na(UACE)) %>% dplyr::select(UZAState, UACE) %>% as.data.frame()

hm72 <- hm72 %>%
  filter(!is.na(UACE))%>%
  dplyr::select(UACE, UZAFWLM=freeway_lane_miles)

SLD_df <- SLD_df %>% left_join(hm72, by="UACE")

## load place types
load("inst/extdata/PlaceType.Rda")
placetype <- Outputs_df %>%
  #dplyr::select(-c(SFIPS, CBSA, CBSA_Name, HH, EMPTOT, TOTPOP10, E5_RET10, E5_SVC10, D1D, D2A_JPHH, D3amm, D3apo, D4a, D4c, D4d)) %>% #those are loaded from SLD
  transmute(GEOID10,
            AreaType=as.character(AreaType),  # convert from factor to characters
            Diversity1, Diversity2,
            LocationType=as.character(LocationType),
            DevelopmentType=as.character(DevelopmentType),
            ACCESS = (2 * EMPTOT_2 * TOTPOP10_5) / (10000 * (EMPTOT_2 + TOTPOP10_5)),
            TOTPOP10_0.25,TOTPOP10_1,TOTPOP10_10,TOTPOP10_15,TOTPOP10_2,TOTPOP10_5,
            EMPTOT_0.25,EMPTOT_1,EMPTOT_10,EMPTOT_15,EMPTOT_2,EMPTOT_5)
#rm(Outputs_df)

SLD_df %<>% left_join(placetype, by="GEOID10") %>%
  rename(D5=ACCESS)

## Doesn't work without confidential data
Hh_df <- Hh_df %>% left_join(SLD_df, by="GEOID10")



Hh_df <- Hh_df %>% mutate(
  metro=ifelse(is.na(UZAAVRM) | is.na(UZAFWLM), "non_metro", "metro"),
  TranRevMiPC=UZAAVRM/UZAPOP,
  FwyLaneMiPC=UZAFWLM/UZAPOP,

  TranRevMiP1k = 1000 * TranRevMiPC,
  FwyLaneMiP1k = 1000 * FwyLaneMiPC,

  TRPOPDEN=TRPOP/TRAREA,
  TRHUDEN=TRHU/TRAREA,
  TREMPDEN=TREMP/TRAREA,
  TRACTDEN=TRACT/TRAREA,
  TRJOBPOP=ifelse(TRPOP==0, 0, TREMP/TRPOP),
  TRJOBHH=ifelse(TRHU==0, 0, TREMP/TRHU),

  #normalize hh weights
  hhwgt=WTHHFIN * n()/sum(WTHHFIN) ) %>%
  dplyr::select(
    HhId=HOUSEID,
    Age0to14,
    Age65Plus,
    AADVMT,
    BikeAvgTripDist,
    TransitAvgTripDist,
    WalkAvgTripDist,
    CENSUS_R,
    D1B, D1C, D2A_EPHHM, D2A_WRKEMP, D3bpo4, D4c, D5,
    Drivers,
    DrvAgePop,
    FwyLaneMiPC,
    HhSize,
    hhwgt,
    LifeCycle,
    LogIncome,
    metro,
    BikeTrips,
    TransitTrips,
    WalkTrips,
    BikePMT,
    TransitPMT,
    WalkPMT,
    TranRevMiPC,
    VehPerDriver,
    Vehicles,
    Workers
  )


#' household data frame for model estimation
#'
#' @format The main data frame \code{Hh_df} has 130509 rows and 33 variables:
#' \describe{
#'   \item{HhId}{Household ID}
#'   \item{Age0to14}{Number of household members younger than 14}
#'   \item{Age65Plus}{Number of household members older than 65}
#'   \item{AADVMT}{Annual average daily VMT}
#'   \item{BikeAvgTripDist}{Average distance of biking trips}
#'   \item{TransitAvgTripDist}{Average distance of transit trips}
#'   \item{WalkAvgTripDist}{Average distance of walking trips}
#'   \item{CENSUS_R}{Census region: NE, MW, S, or W}
#'   \item{D1B}{Gross block group population density (people/acre) on unprotected land}
#'   \item{D1C}{Gross block group employment density (jobs/acre) on unprotected land}
#'   \item{D2A_EPHHM}{Employment and household entropy. See https://www.epa.gov/sites/production/files/2014-03/documents/sld_userguide.pdf page 19 for more details}
#'   \item{D2A_WRKEMP}{Household Workers per Job, by CBG}
#'   \item{D3bpo4}{Intersection density in terms of pedestrianoriented intersections having four or more legs per square mile}
#'   \item{D4c}{Aggregate frequency of transit service within 0.25 miles of block group boundary per hour during evening peak period}
#'   \item{D5}{Accessibility measure from Place Types ``ACCESS = (2 * EMPTOT_2 * TOTPOP10_5) / 10000 * (EMPTOT_2 + TOTPOP10_5)``, where ``EMPTOT_2`` is employment within 2-mile radius, and ``TOTPOP10_5`` is total 2010 population within 5-mile radius. See https://github.com/gregorbj/Placetypes_USA for more details}
#'   \item{Drivers}{Number of drivers in household}
#'   \item{DrvAgePop}{Number of household members of driving age (>14)}
#'   \item{FwyLaneMiPC}{UZA freeway lane miles per capita, from HPMS Table HM72}
#'   \item{HhSize}{Household size}
#'   \item{hhwgt}{Household weights, calculated by ORNL}
#'   \item{LifeCycle}{Life cycle stage: "01"="Single", "02"="Couple w/o children", c("00", "03"-"08")="Couple w/ children", c("09", "10")="Empty Nester"}
#'   \item{LogIncome}{log of household income, offset by +1 to fix issue with zero income households}
#'   \item{metro}{Whether household's residential block group is in a metro or non-metro area, defined by whether its UZA is included in NTD and HPMS}
#'   \item{BikeTrips}{Number of biking trips}
#'   \item{TransitTrips}{Number of transit trips}
#'   \item{WalkTrips}{Number of walking trips}
#'   \item{BikePMT}{Total person miles travelled by bike}
#'   \item{TransitPMT}{Total person miles travelled by transit}
#'   \item{WalkPMT}{Total person miles travelled by walking}
#'   \item{TranRevMiPC}{UZA transit revenue miles per capita}
#'   \item{VehPerDriver}{Number of vehicles per driver}
#'   \item{Vehicles}{Number of vehicles in household}
#'   \item{Workers}{Number of workers in household}
#'   }
#'
#' @examples
#' str(Hh_df)
#' head(Hh_df)
#' summary(Hh_df)
#'
"Hh_df"
