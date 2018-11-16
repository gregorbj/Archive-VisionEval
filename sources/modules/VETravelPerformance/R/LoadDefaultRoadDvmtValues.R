#===========================
#LoadDefaultRoadDvmtValues.R
#===========================
#This module calculates default values for base year roadway DVMT by vehicle
#type (light-duty, heavy truck, bus), the distribution of roadway DVMT by
#vehicle type to roadway classes (freeway, arterial, other), and the ratio of
#commercial service light-duty vehicle travel to household vehicle travel.


#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)
# library(stringr)


#===========================================================================
#SECTION 1A: ESTIMATE AND SAVE MODEL PARAMETERS FOR CALCULATING ROADWAY DVMT
#===========================================================================
RoadDvmtModel_ls <- list()

#------------------------------------------------------------
#Process the Vehicle Type Split for Each Road Class and State
#------------------------------------------------------------
#The following code creates two arrays identifying the proportional split of
#vehicle miles traveled (VMT) among vehicle types (light-duty, heavy truck, bus)
#for each road class (Fwy = freeway, Art = arterial, Oth = other) in each state.
#One array contains data for roadways classified as urban (i.e. located in
#Census urbanized areas) and the other contains data for roadways classified as
#rural. The data in these arrays is compiled from data contained in table VM-4
#of the Highways Statistics data series. Since table VM-4 is a multi-level
#table, it has been split into 6 simpler tables where each table contains the
#data for urban or rural roads of one road class as follows:
#vehicle_type_vmt_split_urban_interstate.csv
#vehicle_type_vmt_split_urban_arterial.csv
#vehicle_type_vmt_split_urban_other.csv
#vehicle_type_vmt_split_rural_interstate.csv
#vehicle_type_vmt_split_rural_arterial.csv
#vehicle_type_vmt_split_rural_other.csv
#The code reads in and processes these tables, and produces the two arrays of
#vehicle type proportions by state and road class -- UrbanVtProps_StVtRc and
#RuralVtProps_StVtRc -- where the rows are states (including Washington DC and
#Puerto Rico), the columns are vehicle types, and the tables (the 3rd dimension)
#are road classes. The abbreviations in the names are as follows:
#Vt = vehicle type
#St = state
#Rc = road class

#Define function to process vehicle type VMT percentage splits
processVmtVtSplitData <- function(UrbanOrRural) {
  #Define road classes
  Rc <- c("interstate", "arterial", "other")
  #Load in and process each road class file
  for (i in 1:length(Rc)) {
    rc <- Rc[i]
    #Identify the file to load
    FileName <- paste0(
      "vehicle_type_vmt_split_", UrbanOrRural, "_", rc, ".csv"
    )
    FilePath <- paste0("inst/extdata/", FileName)
    #Read file and convert to matrix
    Split_df <- read.csv(FilePath)
    row.names(Split_df) <- Split_df$State
    Split_mx <-
      as.matrix(Split_df[, -which(colnames(Split_df) %in% c("State", "Total"))])
    #Convert to proportions and make sure values sum to 1 exactly
    Split_mx <-
      t(apply(Split_mx, 1, function(x) x / sum(x)))
    #Sum up by aggregate vehicle types
    VehTypes_ <- c(
      Motorcycle = "LDV",
      Auto = "LDV",
      LightTruck = "LDV",
      Bus = "Bus",
      SingleTruck = "HvyTrk",
      CombiTruck = "HvyTrk")
    Split_mx <-
      t(apply(Split_mx, 1, function(x) {
        tapply(x, VehTypes_[colnames(Split_mx)], sum)
      }))[, c("LDV", "HvyTrk", "Bus")]
    #If first road class make array to store results
    if (i == 1) {
      SplitByRc_ar <- array(
        0,
        dim = c(nrow(Split_mx), ncol(Split_mx), 3),
        dimnames = list(rownames(Split_mx), colnames(Split_mx), Rc))
    }
    #Put split by road class into array
    SplitByRc_ar[,,rc] <- Split_mx
  }
  #Rename the road classes to names used in model
  dimnames(SplitByRc_ar)[[3]] <- c("Fwy", "Art", "Oth")
  #Return the array of split proportions
  SplitByRc_ar
}

#Create arrays of urban and rural vehicle type splits by state and road class
UrbanVtProps_StVtRc <- processVmtVtSplitData("urban")
RuralVtProps_StVtRc <- processVmtVtSplitData("rural")
rm(processVmtVtSplitData)


#---------------------------------------------
#Process VMT Data by Road Class for Each State
#---------------------------------------------
#The following code creates two matrices tabulating annual vehicle miles
#traveled (VMT) (in millions) for each road class (Fwy = freeway, Art =
#arterial, Oth = other) in each state. One matrix contains data for roadways
#classified as urban (i.e. located in Census urbanized areas) and the other
#contains data for roadways classified as rural. The data in these matrices is
#compiled from data contained in table VM-2 of the Highways Statistics data
#series. Since table VM-2 is a multi-level table, it has been split into 2
#simpler tables where each table contains the data for urban or rural roads as
#follows:
#functional_class_vmt_split_urban.csv
#functional_class_vmt_split_urban.csv
#The code reads in and processes these tables, and produces the two matrices of
#VMT by state and road class -- UrbanVmt_StRc and RuralVmt_StRc -- where the
#rows are states (including Washington DC and Puerto Rico) and the columns are
#are road classes. The abbreviations in the names are as follows:
#St = state
#Rc = road class

#Define function to process VMT by functional class data
processVmtByFcData <- function(UrbanOrRural) {
  #Identify the file to load
  FileName <- paste0(
    "functional_class_vmt_split_", UrbanOrRural, ".csv"
  )
  FilePath <- paste0("inst/extdata/", FileName)
  #Load file and convert into matrix
  Vmt_df <- read.csv(FilePath)
  Vmt_mx <- as.matrix(Vmt_df[, -which(names(Vmt_df) %in% c("State", "Total"))])
  row.names(Vmt_mx) <- Vmt_df$State
  #Sum values by road class
  RoadClass_ <- c(
    Interstate = "Fwy",
    OthFwyExp = "Fwy",
    OthPrinArt = "Art",
    MinArt = "Art",
    MajColl = "Oth",
    MinColl = "Oth",
    Local = "Oth"
  )
  Vmt_mx <-
    t(apply(Vmt_mx, 1, function(x) {
      tapply(x, RoadClass_[colnames(Vmt_mx)], sum)
    }))[, c("Fwy", "Art", "Oth")]
}

#Create matrices of urban and rual VMT by state and road class
UrbanVmt_StRc <- processVmtByFcData("urban")
RuralVmt_StRc <- processVmtByFcData("rural")
Vmt_StRc <- UrbanVmt_StRc + RuralVmt_StRc
rm(processVmtByFcData)


#--------------------------------------------------
#Process DVMT Data by Urbanized Area and Road Class
#--------------------------------------------------
#The following code creates a matrix tabulating daily vehicle miles traveled
#(DVMT) (in thousands) for each road class (Fwy = freeway, Art = arterial, Oth =
#other) in each urbanized area. The data in this matrix is compiled from data
#contained in table HM-71 of the Highways Statistics data series. Since table
#HM-71 is a complex table containing data on multiple sheets, it has been
#simplified into the file 'urbanized_area_dvmt.csv'. The code reads in and
#processes this file, and produces the matrix of DVMT by urbanized area and road
#class -- UzaDvmt_UaRc -- where the rows are urbanized areas and the columns are
#are road classes. The abbreviations in the names are as follows:
#Ua = urbanized area
#Rc = road class
#This matrix also has the following attached attributes:
#State = the primary state where the urbanized area is located
#Population = the population of the urbanized area
#Total = the total DVMT on urbanized area roads
#The elements of each of these attributes correspond to the rows in the matrix.

#Load urbanized area DVMT data and make into matrix
UzaDvmt_df <- read.csv("inst/extdata/urbanized_area_dvmt.csv", as.is = TRUE)
#Define road classes
RoadClass_ <- c(
  Interstate = "Fwy",
  OthFwyExp = "Fwy",
  OthPrinArt = "Art",
  MinArt = "Art",
  MajColl = "Oth",
  MinColl = "Oth",
  Local = "Oth"
)
#Convert into matrix
UzaDvmt_mx <- as.matrix(UzaDvmt_df[,names(RoadClass_)])
#Aggregate into road classes
UzaDvmt_UaRc <-
  t(apply(UzaDvmt_mx, 1, function(x) {
    tapply(x, RoadClass_[colnames(UzaDvmt_mx)], sum)
  }))[, c("Fwy", "Art", "Oth")]
rownames(UzaDvmt_UaRc) <- paste0(
  UzaDvmt_df$UrbanizedArea, "/", UzaDvmt_df$PrimaryState
)
#Attach urbanized area primary state and population as attributes
attributes(UzaDvmt_UaRc)$State <- UzaDvmt_df$PrimaryState
attributes(UzaDvmt_UaRc)$Population <- UzaDvmt_df$Population
attributes(UzaDvmt_UaRc)$Total <- UzaDvmt_df$Total
#Clean up
rm(UzaDvmt_df, RoadClass_, UzaDvmt_mx)


#-------------------------------------------------------
#Split State VMT and Urbanized Area DVMT by Vehicle Type
#-------------------------------------------------------
#State VMT by road class is split into vehicle type components by applying the
#vehicle type proportions by road class. Urbanized are DVMT is split into
#vehicle type components by applying the urban vehicle type proportions by road
#class for the principle state where the urbanized area is located. These data
#are used to calculate how VMT of each vehicle type is split across roadway
#classes. It is also used to calculate the ratio of heavy truck VMT to
#population which is used in the model to calculate base year heavy truck VMT
#and from that the ratio of heavy truck VMT to income which is used to predict
#future heavy truck VMT.

#Calculate urban VMT by state, vehicle type, and road class
UrbanVmt_StVtRc <- sweep(UrbanVtProps_StVtRc, c(1,3), UrbanVmt_StRc, "*")
#Calculate rural VMT by state, vehicle type, and road class
RuralVmt_StVtRc <- sweep(RuralVtProps_StVtRc, c(1,3), RuralVmt_StRc, "*")
#Expand the state urban vehicle type props to urbanized areas
UzaVtProps_UaVtRc <- UrbanVtProps_StVtRc[attributes(UzaDvmt_UaRc)$State,,]
#Calculate the urbanized area DVMT by vehicle type and road class
UzaDvmt_UaVtRc <- sweep(UzaVtProps_UaVtRc, c(1,3), UzaDvmt_UaRc, "*")
rownames(UzaDvmt_UaVtRc) <- rownames(UzaDvmt_UaRc)
attributes(UzaDvmt_UaVtRc)$State <- attributes(UzaDvmt_UaRc)$State
attributes(UzaDvmt_UaVtRc)$Population <- attributes(UzaDvmt_UaRc)$Population
attributes(UzaDvmt_UaVtRc)$Total <- attributes(UzaDvmt_UaRc)$Total


#------------------------------------------------------------------
#Calculate Light-Duty Vehicle (LDV) and Heavy Truck DVMT Per Capita
#------------------------------------------------------------------
#LDV and heavy truck DVMT per capita parameters are used as the basis for
#calculating roadway DVMT totals that are then allocated to road classes.

#The default method for computing LDV roadway DVMT for an urbanized area is to
#multiply the LDV per capita parameter by the base year urbanized area
#population. This method is used unless the model user provides an estimate of
#base year LDV DVMT or is the user provides a total DVMT estimate (in which case
#the estimated LDV DVMT proportion parameter is appied to the total). The model
#uses the calculated LDV roadway DVMT and the modeled DVMT for urbanized area
#households (along with commercial service and transit LDV DVMT) to calculate a
#ratio between the roadway LDV DVMT and the overall demand for LDV travel
#generated by urbanized area households. This ratio is then applied to future
#calculations of overall LDV DVMT generated by urbanized area households to
#calculate the LDV DVMT on the urbanized area roads.

#Heavy truck DVMT is predicted is a similar manner. Per capita heavy truck DVMT
#is calculated at the state level and at the urbanized area level. In addition,
#the urban proportion of state heavy truck DVMT is calculated. If the model is
#run only for a metropolitan area, the urbanized area per capita value is used
#to calculate a base year heavy truck DVMT which is used to calculate the ratio
#of heavy truck DVMT to total household income. The model user can choose to
#either grow heavy truck DVMT in the future in proportion to the growth of
#urbanized area population or in proportion to urbanized area income. If the
#model is run at the state level, the per capita DVMT parameter for the state is
#used to calculate base year heavy truck DVMT in the state (unless the user
#supplies the base year heavy truck DVMT or provides total DVMT, in which heavy
#truck DVMT is calculated by the estimated heavy truck DVMT proportion
#calculated for the state). The model then calculates the ratio of heavy truck
#DVMT to total state income so that the user can choose to calculate future
#heavy truck DVMT as a function of population growth or income growth. The state
#heavy truck DVMT then is used as a control total for heavy truck DVMT in
#urbanized areas in the state.

#Load state population data
StatePop_df <- read.csv("inst/extdata/state_population.csv", as.is = TRUE)
Pop_St <- StatePop_df$Total
names(Pop_St) <- StatePop_df$Abbreviation
#Tabulate state heavy truck DVMT
UrbanHvyTrkDvmt_St <-
  apply(UrbanVmt_StVtRc[,"HvyTrk",], 1, sum, na.rm = TRUE) * 1e6 / 365
RuralHvyTrkDvmt_St <-
  apply(RuralVmt_StVtRc[,"HvyTrk",], 1, sum, na.rm = TRUE) * 1e6 / 365
HvyTrkDvmt_St <- UrbanHvyTrkDvmt_St + RuralHvyTrkDvmt_St
#Calculate state heavy truck DVMT per capita
RoadDvmtModel_ls$HvyTrkDvmtPC_St <- HvyTrkDvmt_St / Pop_St[names(HvyTrkDvmt_St)]
#Calculate the urban portion of state heavy truck DVMT
RoadDvmtModel_ls$HvyTrkDvmtUrbanProp_St <- UrbanHvyTrkDvmt_St / HvyTrkDvmt_St
#Tabulate urbanized area heavy truck DVMT
UzaHvyTrkDvmt_Ua <- apply(UzaDvmt_UaVtRc[,"HvyTrk",], 1, sum) * 1000
#Calculate urbanized area heavy truck DVMT per capita
RoadDvmtModel_ls$UzaHvyTrkDvmtPC_Ua <-
  UzaHvyTrkDvmt_Ua / attributes(UzaDvmt_UaVtRc)$Population
#Calculate urbanized area LDV DVMT
UzaLDVDvmt_Ua <- apply(UzaDvmt_UaVtRc[,"LDV",], 1, sum) * 1000
#Calculate urbanized area LDV DVMT per capita
RoadDvmtModel_ls$UzaLDVDvmtPC_Ua <- UzaLDVDvmt_Ua /
  attributes(UzaDvmt_UaVtRc)$Population
#Clean up
rm(StatePop_df, Pop_St, UrbanHvyTrkDvmt_St, RuralHvyTrkDvmt_St,
   UzaHvyTrkDvmt_Ua, UzaLDVDvmt_Ua)


#--------------------------------------------------------------------
#Calculate the Split of DVMT of Each Vehicle Type Across Road Classes
#--------------------------------------------------------------------
#After roadway DVMT by vehicle type has been calculated, that DVMT is assigned
#to road classes. For heavy truck and bus DVMT, it is assumed that the
#distribution of travel across road types reflects logistics and routing
#considerations rather than congestion. Likewise, it is assumed that the
#proportion of LDV on roads other than freeways and arterials is determined
#largely by the need to access properties and is relatively fixed. The
#proportions of LDV on freeways and arterial is not assumed to be fixed and will
#reflect relative congestion and costs (i.e. congestion pricing) on those
#roadways. The AssignLDVTraffic module allocates LDV travel between freeways and
#arterials. The following code calculates the average distributions for urban
#areas for each state. Users may use these distributions instead of urbanized
#area specific values if desired. The code also calculates the distributions by
#urbanized area.

#Calculate state urban vehicle type proportions by road class
UrbanRcProps_StVtRc <-
  sweep(UrbanVmt_StVtRc, c(1,2), apply(UrbanVmt_StVtRc, c(1,2), sum), "/")
#Compute state mean urban values and apply where values are NA
UrbanRcProps_VtRc <- apply(UrbanRcProps_StVtRc, c(2,3), mean, na.rm = TRUE)
for (i in 1:nrow(UrbanRcProps_StVtRc)) {
  UrbanRcProps_StVtRc[i,,][is.na(UrbanRcProps_StVtRc[i,,])] <-
    UrbanRcProps_VtRc[is.na(UrbanRcProps_StVtRc[i,,])]
}
rm(i)
RoadDvmtModel_ls$UrbanRcProps_StVtRc <- UrbanRcProps_StVtRc
#Calculate urbanized area vehicle type proportions by road class
UzaRcProps_UaVtRc <-
  sweep(UzaDvmt_UaVtRc, c(1,2), apply(UzaDvmt_UaVtRc, c(1,2), sum), "/")
#Cities in Ohio have no bus proportions replace with urbanized area average
#Note, this method should be improved in the future by applying a weighted
#average of urbanized areas that are similar in population and in the
#distribution of road miles by road class
UzaRcProps_VtRc <- apply(UzaRcProps_UaVtRc, c(2,3), mean, na.rm = TRUE)
for (i in 1:nrow(UzaRcProps_UaVtRc)) {
  UzaRcProps_UaVtRc[i,,][is.na(UzaRcProps_UaVtRc[i,,])] <-
    UzaRcProps_VtRc[is.na(UzaRcProps_UaVtRc[i,,])]
}
rm(i)
RoadDvmtModel_ls$UzaRcProps_UaVtRc <- UzaRcProps_UaVtRc
#Clean up
rm(UrbanRcProps_VtRc)


#----------------------------------------------------------------------------
#Estimate Factor to Calculate Commercial Service LDV DVMT from Household DVMT
#----------------------------------------------------------------------------
#Commercial service (ComSvcDvmt) light-duty vehicle DVMT is calculated as a
#function of household DVMT for the base year. Once ComSvcDvmt has been
#calculated for an urbanized are, the model also calculates ratios of ComSvcDvmt
#to population and to total household. The model user can choose whether future
#ComSvcDvmt growth with household DVMT, urbanized area population, or urbanized
#area income.
#The ratio of commercial service fleet DVMT to household DVMT is calculated from
#the following national data:
#1) Estimates of average DVMT for commercial fleet light-duty vehicles and for
#all light-duty vehicles; and
#2) Estimates of the numbers of vehicles in fleets having 4 or more vehicles and
#estimates of all light-duty vehicles

#Calculate the commercial service LDV DVMT Factor
RoadDvmtModel_ls$ComSvcDvmtFactor <- local({
  MiPerVeh_df <- read.csv("inst/extdata/ave_vmt_per_vehicle_2010.csv")
  NumVeh_df <- read.csv("inst/extdata/ldv_numbers_2010.csv")
  NumLdv <- NumVeh_df$Number[NumVeh_df$Category == "All LDV"]
  NumFleet <- NumVeh_df$Number[NumVeh_df$Category == "Fleet Automobiles"]
  IsFleet_ <- MiPerVeh_df$Category %in%
    c("Fleet Compact Cars", "Fleet Intermediate Cars", "Fleet Pickup Trucks",
      "Fleet Minivans", "Fleet Sport utility vehicles", "Fleet Full-size vans")
  AveLdvMiPerVeh <- mean(MiPerVeh_df$AnnualVmtPerVehicle[!IsFleet_])
  AveFleetMiPerVeh <- mean(MiPerVeh_df$AnnualVmtPerVehicle[IsFleet_])
  FleetMi <- NumFleet * AveFleetMiPerVeh
  LdvMi <- NumLdv * AveLdvMiPerVeh
  HhMi <- LdvMi - FleetMi
  FleetMi / HhMi
})

#-------------------------------------------
#Save the Default Road DVMT Model Parameters
#-------------------------------------------
#' Roadway DVMT models
#'
#' A list of components used to predict the roadway DVMT by vehicle type and
#' road class in urbanized areas.
#'
#' @format A list having the following components:
#' HvyTrkDvmtPC_St: the ratio of heavy truck DVMT to population by state;
#' HvyTrkDvmtUrbanProp_St: the proportion of heavy truck DVMT occurring within
#' urban areas of each state;
#' UzaHvyTrkDvmtPC_Ua: the ratio of heavy truck DVMT to population by urbanized
#' area;
#' UzaLDVDvmtPC_Ua: the ratio of light-duty vehicle DVMT to population by
#' urbanized area;
#' UrbanRcProps_StVtRc: the proportional split of each type of DVMT by urban
#' road class in each state;
#' UzaRcProps_UaVtRc: the proportional split of each type of DVMT by urban
#' road class in each urbanized area;
#' ComSvcDvmtFactor: the factor to calculate light-duty commercial service
#' vehicle DVMT from household DVMT.
#' @source CalculateRoadDVMT.R
"RoadDvmtModel_ls"
usethis::use_data(RoadDvmtModel_ls, overwrite = TRUE)

rm("HvyTrkDvmt_St", "RuralVmt_StRc", "RuralVmt_StVtRc", "RuralVtProps_StVtRc",
   "UrbanRcProps_StVtRc", "UrbanVmt_StRc", "UrbanVmt_StVtRc",
   "UrbanVtProps_StVtRc", "UzaDvmt_UaRc", "UzaDvmt_UaVtRc", "UzaRcProps_UaVtRc",
   "UzaRcProps_VtRc", "UzaVtProps_UaVtRc", "Vmt_StRc")


