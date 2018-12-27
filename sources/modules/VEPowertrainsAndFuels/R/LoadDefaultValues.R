#===================
#LoadDefaultValues.R
#===================

#<doc>
#
### LoadDefaultValues
#### November 25, 2018
#
#Powertrain and fuels data are some of the most complex datasets used in VisionEval models to develop. To simplify matters for the user, default datasets are included in the package and are processed when the package is built. The user can then work with a simpler set of input files to develop scenarios. Documentation for the *Initialize* module describes the user inputs in detail. Although this simplifies model applications, it does constrain the powertrain and fuel factors that the average user can vary in scenarios. It is anticipated that this limitation will diminish over time as sufficiently knowledgeable users develop variants of the VEPowertrainsAndFuels package that include different default datasets. For example, one package may include data files representing a business-as-usual (BAU) scenario while another package represents a California zero-emissions vehicle (ZEV) rules scenario. A different default scenario can be made by altering files in the `inst/extdata` directory of the source package. Each file is documented with a correspondingly named text file. Following are brief descriptions of each of the default datasets:
#
#* **carbon_intensity.csv**: This file includes values for the carbon intensity of motor vehicle fuels and electricity by fuel type. Carbon intensity is measured in grams of carbon dioxide equivalents per megajoule of energy. Note that the carbon intensity values may be well-to-wheels or tank-to-wheels estimates/forecasts. Well-to-wheels values include the carbon emissions to produce and transport the fuels as well as the emissions that result from using the fuels. Tank-to-wheels values only include the carbon emissions resulting from using the fuels. If the estimates are tank-to-wheels, the 'Electricity' values would be zero. VE-RSPM and VE-State models are almost always run with well-to-wheels values as this provides a more complete assessment of the effects of transportation decisions and provides a fairer assessment of the effects of electric vehicles which depends on the source of electric power. Data are provided by year for gasoline, diesel, compressed natural gas, liquified natural gas, ethanol, biodiesel, renewable natural gas, and electricity.
#
#* **carsvc_fuel.csv**: This file contains values for the proportions of hydrocarbon fuels used to power car service vehicles by fuel type (gasoline, diesel, compressed natural gas) and vehicle type (auto, light truck). Note that these include fuel blends (e.g. gasoline blended with ethanol). Blending proportions are specified in the "ldv_biofuel_mix.csv" file. The data in these files as well as in the "carbon_intensity.csv" file are used to calculate the average carbon intensity of hydrocarbon fuels used by car service vehicles. Note that the proportions in this file do **not** represent volumetric proportions (e.g. gallons), they represent energy proportions (e.g. gasoline gallon equivalents) or DVMT proportions.
#
#* **carsvc_powertrain_prop.csv**: This file contains values for the proportions of vehicle powertrain (ICEV, HEV, BEV) by vehicle type (auto, light truck) used by car services (e.g. taxi, TNC). The proportions represent the proportions of daily vehicle miles traveled (DVMT) rather than the proportions of vehicles. Note that the powertrain use proportions must add to 1 for each vehicle type. Also note that there is no category for plug-in hybrid electric vehicles (PHEV). The reason for this is that the model has no built-in mechanism for determining the proportion of PHEV travel which is powered by electricity vs. the proportion of travel powered by fuel.
#
#* **comsvc_fuel.csv**: This file contains values for the proportions of hydrocarbon fuels used to power commercial service vehicles by fuel type (gasoline, diesel, compressed natural gas) and vehicle type (auto, light truck). Note that these include fuel blends (e.g. gasoline blended with ethanol). Blending proportions are specified in the "ldv_biofuel_mix.csv" file. The data in these files as well as in the "carbon_intensity.csv" file are used to calculate the average carbon intensity of hydrocarbon fuels used by commercial service vehicles. Note that the proportions in this file do **not** represent volumetric proportions (e.g. gallons), they represent energy proportions (e.g. gasoline gallon equivalents) or DVMT proportions.
#
#* **comsvc_powertrain_prop.csv**: This file contains values for the proportions of vehicle powertrain (ICEV, HEV, BEV) use by vehicle type (auto, light truck) used by commercial service vehicles (e.g. parcel delivery, contractor). The proportions represent the proportions of daily vehicle miles traveled (DVMT) rather than the proportions of vehicles. Note that the powertrain use proportions must add to 1 for each vehicle type. Also note that there is no category for plug-in hybrid electric vehicles (PHEV). The reason for this is that the model has no built-in mechanism for determining the proportion of PHEV travel which is powered by electricity vs. the proportion of travel powered by fuel.
#
#* **congestion_efficiency.csv**: This file contains values for the relative 'fuel efficiency' of different vehicle powertrains in congestion. The impact of congestion on vehicle fuel economy was modeled for 145 vehicle configurations using the Environmental Protection Agency's PERE model (Alex Bigazzi and Kelly Clifton. Refining GreenSTEP: Impacts of Vehicle Technologies and ITS/Operational Improvements on Travel Speed and Fuel Consumption Curves. Final Report on Task 1: Advanced Vehicle Fuel-Speed Curves, November 2011, Portland State University). The vehicle configurations that perform 'best' and 'worst' in congestion were identified for 4 light-duty vehicle powertrains and one heavy duty vehicle powertrain. The congestion efficiency values in this file identify assumptions about the average congestion performance of each powertrain relative to the 'best' and 'worst' values. The values can range from 0 to 1 where 0 means that it is the 'worst' performance, 1 means that it is the 'best' performance, and 0.5 is midway between.
#
#* **hh_fuel.csv**: This file contains values for the proportions of hydrocarbon fuels used to power household vehicles by fuel type (gasoline, diesel, compressed natural gas) and vehicle type (auto, light truck). Note that these include fuel blends (e.g. gasoline blended with ethanol). Blending proportions are specified in the "ldv_biofuel_mix.csv" file. The data in these files as well as in the "carbon_intensity.csv" file are used to calculate the average carbon intensity of hydrocarbon fuels used by household vehicles. Note that the proportions in this file do not represent volumetric proportions (e.g. gallons), they represent energy proportions (e.g. gasoline gallon equivalents) or DVMT proportions.
#
#* **hh_powertrain_prop.csv**: This file contains values for household vehicle powertrain (ICEV, HEV, PHEV, BEV) proportions by vehicle type (auto, light truck), and vehicle model year. Note that the powertrain use proportions need add to 1 for each vehicle type.
#
#* **hvytrk_biofuel_mix.csv**: This file contains values for the biofuel proportions of hydrocarbon fuels used by heavy trucks. For example if the gasoline used by heavy trucks is 5% ethanol, the ethanol proportion of gasoline (EthanolPropGasoline) would be 0.05.
#
#* **hvytrk_fuel.csv**: This file contains values for the proportions of hydrocarbon fuels used to power heavy trucks by fuel type (gasoline, diesel, liquified natural gas). Note that these include fuel blends (e.g. gasoline blended with ethanol). Blending proportions are specified in the "hvytrk_biofuel_mix.csv" file. The data in these files as well as in the "carbon_intensity.csv" file are used to calculate the average carbon intensity of hydrocarbon fuels used by heavy trucks. Note that the proportions in this file do **not** represent volumetric proportions (e.g. gallons), they represent energy proportions (e.g. gasoline gallon equivalents) or DVMT proportions.
#
#* **hvytrk_powertrain_characteristics.csv**: This file contains values for key powertrain characteristics for the heavy truck fleet that are used in calculating amounts of fuel and electric power consumed.
#
#* **hvytrk_powertrain_prop.csv**: This file contains values for the proportions of vehicle powertrain (ICEV, HEV, BEV) use by heavy trucks. The proportions represent the proportions of daily vehicle miles traveled (DVMT) rather than the proportions of vehicles. Note that the powertrain use proportions must add to 1 for each vehicle type. Also note that there is no category for plug-in hybrid electric vehicles (PHEV). The reason for this is that the model has no built-in mechanism for determining the proportion of PHEV travel which is powered by electricity vs. the proportion of travel powered by fuel.
#
#* **ldv_biofuel_mix.csv**: This file contains values for the biofuel proportions of hydrocarbon fuels used by light-duty vehicles. For example if the gasoline used by light-duty vehicles is 5% ethanol, the ethanol proportion of gasoline (EthanolPropGasoline) would be 0.05.
#
#* **ldv_powertrain_characteristics.csv**: This file contains values for key powertrain characteristics for light-duty vehicles by vehicle model year that are used in calculating amounts of fuel and electric power consumed.
#
#* **transit_biofuel_mix.csv**: This file contains values for the biofuel proportions of hydrocarbon fuels used by public transit vehicles. For example if the gasoline used by thes vehicles is on average is 5% ethanol, the ethanol proportion of gasoline (EthanolPropGasoline) would be 0.05.
#
#* **transit_fuel.csv**: This file contains values for the proportions of hydrocarbon fuels used to power transit vehicles by fuel type (gasoline, diesel, compressed natural gas) and vehicle type (van, bus, rail). Note that these include fuel blends (e.g. gasoline blended with ethanol). Blending proportions are specified in the "transit_biofuel_mix.csv" file. The data in these files as well as in the "carbon_intensity.csv" file are used to calculate the average carbon intensity of hydrocarbon fuels used by transit vehicles. Note that the proportions in this file do **not** represent volumetric proportions (e.g. gallons), they represent energy proportions (e.g. gasoline gallon equivalents) or DVMT proportions.
#
#* **transit_powertrain_characteristics.csv**: This file contains values for key powertrain characteristics for the public transit fleet vehicles that are used in calculating amounts of fuel and electric power consumed.
#
#* **transit_powertrain_prop.csv**: This file contains values for the proportions of vehicle powertrain (ICEV, HEV, BEV) use by public transit vehicles. The proportions represent the proportions of daily vehicle miles traveled (DVMT) rather than the proportions of vehicles. Note that the powertrain use proportions must add to 1 for each vehicle type. Also note that there is no category for plug-in hybrid electric vehicles (PHEV). The reason for this is that the model has no built-in mechanism for determining the proportion of PHEV travel which is powered by electricity vs. the proportion of travel powered by fuel.
#
#</doc>

#=================================
#Packages used in code development
#=================================
#Uncomment following lines during code development. Recomment when done.
# library(visioneval)


#============================================================
#READ IN AND PROCESS DEFAULT VEHICLE AND FUEL CHARACTERISTICS
#============================================================
#Default vehicle, fuel, and carbon intensity assumptions

PowertrainFuelDefaults_ls <- list()

#---------------------
#Congestion efficiency
#---------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("LdIce",
            "LdHev",
            "LdEv",
            "LdFcv",
            "HdIce"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
CongestionEfficiency_df <-
  processEstimationInputs(
    Inp_ls,
    "congestion_efficiency.csv",
    "LoadDefaultValues.R")
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$CongestionEfficiency_df <- CongestionEfficiency_df
rm(Inp_ls, CongestionEfficiency_df)

#----------------
#Carbon intensity
#----------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("Gasoline",
            "Diesel",
            "Cng",
            "Lng",
            "Ethanol",
            "Biodiesel",
            "Rng",
            "Electricity"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
CarbonIntensity_df <-
  processEstimationInputs(
    Inp_ls,
    "carbon_intensity.csv",
    "LoadDefaultValues.R")
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$CarbonIntensity_df <- CarbonIntensity_df
rm(Inp_ls, CarbonIntensity_df)

#------------------------------------
#Car service vehicle fuel proportions
#------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoPropGasoline",
            "AutoPropDiesel",
            "AutoPropCng",
            "LtTrkPropGasoline",
            "LtTrkPropDiesel",
            "LtTrkPropCng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
CarSvcFuel_df <-
  processEstimationInputs(
    Inp_ls,
    "carsvc_fuel.csv",
    "LoadDefaultValues.R")
#Check and adjust auto values
AutoNames_ <- c("AutoPropGasoline", "AutoPropDiesel", "AutoPropCng")
AutoCols_ <-  which(names(CarSvcFuel_df) %in% AutoNames_)
if (any(abs(1 - rowSums(CarSvcFuel_df[AutoCols_])) > 0.01)) {
  stop("Auto proportion values in 'carsvc_fuel.csv' do not sum to 1.")
}
CarSvcFuel_df[,AutoCols_] <-
  sweep(CarSvcFuel_df[,AutoCols_], 1, rowSums(CarSvcFuel_df[,AutoCols_]), "*")
#Check and adjust light truck values
LtTrkNames_ <- c("LtTrkPropGasoline", "LtTrkPropDiesel", "LtTrkPropCng")
LtTrkCols_ <-  which(names(CarSvcFuel_df) %in% LtTrkNames_)
if (any(abs(1 - rowSums(CarSvcFuel_df[LtTrkCols_])) > 0.01)) {
  stop("LtTrk proportion values in 'carsvc_fuel.csv' do not sum to 1.")
}
CarSvcFuel_df[,LtTrkCols_] <-
  sweep(CarSvcFuel_df[,LtTrkCols_], 1, rowSums(CarSvcFuel_df[,LtTrkCols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(CarSvcFuel_df$Year %in% Years_)) {
  stop(paste(
    "File 'carsvc_fuel.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$CarSvcFuel_df <- CarSvcFuel_df
rm(Inp_ls, AutoNames_, AutoCols_, LtTrkNames_, LtTrkCols_, Years_, CarSvcFuel_df)

#-------------------------------------------
#Commercial service vehicle fuel proportions
#-------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoPropGasoline",
            "AutoPropDiesel",
            "AutoPropCng",
            "LtTrkPropGasoline",
            "LtTrkPropDiesel",
            "LtTrkPropCng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
ComSvcFuel_df <-
  processEstimationInputs(
    Inp_ls,
    "comsvc_fuel.csv",
    "LoadDefaultValues.R")
#Check and adjust auto values
AutoNames_ <- c("AutoPropGasoline", "AutoPropDiesel", "AutoPropCng")
AutoCols_ <-  which(names(ComSvcFuel_df) %in% AutoNames_)
if (any(abs(1 - rowSums(ComSvcFuel_df[AutoCols_])) > 0.01)) {
  stop("Auto proportion values in 'comsvc_fuel.csv' do not sum to 1.")
}
ComSvcFuel_df[,AutoCols_] <-
  sweep(ComSvcFuel_df[,AutoCols_], 1, rowSums(ComSvcFuel_df[,AutoCols_]), "*")
#Check and adjust light truck values
LtTrkNames_ <- c("LtTrkPropGasoline", "LtTrkPropDiesel", "LtTrkPropCng")
LtTrkCols_ <-  which(names(ComSvcFuel_df) %in% LtTrkNames_)
if (any(abs(1 - rowSums(ComSvcFuel_df[LtTrkCols_])) > 0.01)) {
  stop("LtTrk proportion values in 'comsvc_fuel.csv' do not sum to 1.")
}
ComSvcFuel_df[,LtTrkCols_] <-
  sweep(ComSvcFuel_df[,LtTrkCols_], 1, rowSums(ComSvcFuel_df[,LtTrkCols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(ComSvcFuel_df$Year %in% Years_)) {
  stop(paste(
    "File 'ComSvc_fuel.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$ComSvcFuel_df <- ComSvcFuel_df
rm(Inp_ls, AutoNames_, AutoCols_, LtTrkNames_, LtTrkCols_, Years_, ComSvcFuel_df)


#----------------------------------
#Household vehicle fuel proportions
#----------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoPropGasoline",
            "AutoPropDiesel",
            "AutoPropCng",
            "LtTrkPropGasoline",
            "LtTrkPropDiesel",
            "LtTrkPropCng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
HhFuel_df <-
  processEstimationInputs(
    Inp_ls,
    "hh_fuel.csv",
    "LoadDefaultValues.R")
#Check and adjust auto values
AutoNames_ <- c("AutoPropGasoline", "AutoPropDiesel", "AutoPropCng")
AutoCols_ <-  which(names(HhFuel_df) %in% AutoNames_)
if (any(abs(1 - rowSums(HhFuel_df[AutoCols_])) > 0.01)) {
  stop("Auto proportion values in 'hh_fuel.csv' do not sum to 1.")
}
HhFuel_df[,AutoCols_] <-
  sweep(HhFuel_df[,AutoCols_], 1, rowSums(HhFuel_df[,AutoCols_]), "*")
#Check and adjust light truck values
LtTrkNames_ <- c("LtTrkPropGasoline", "LtTrkPropDiesel", "LtTrkPropCng")
LtTrkCols_ <-  which(names(HhFuel_df) %in% LtTrkNames_)
if (any(abs(1 - rowSums(HhFuel_df[LtTrkCols_])) > 0.01)) {
  stop("LtTrk proportion values in 'hh_fuel.csv' do not sum to 1.")
}
HhFuel_df[,LtTrkCols_] <-
  sweep(HhFuel_df[,LtTrkCols_], 1, rowSums(HhFuel_df[,LtTrkCols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(HhFuel_df$Year %in% Years_)) {
  stop(paste(
    "File 'hh_fuel.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$HhFuel_df <- HhFuel_df
rm(Inp_ls, AutoNames_, AutoCols_, LtTrkNames_, LtTrkCols_, Years_, HhFuel_df)

#------------------------------
#Light-duty vehicle biofuel mix
#------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("EthanolPropGasoline",
            "BiodieselPropDiesel",
            "RngPropCng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
LdvBiofuelMix_df <-
  processEstimationInputs(
    Inp_ls,
    "ldv_biofuel_mix.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(LdvBiofuelMix_df$Year %in% Years_)) {
  stop(paste(
    "File 'ldv_biofuel_mix.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$LdvBiofuelMix_df <- LdvBiofuelMix_df
rm(Inp_ls, LdvBiofuelMix_df)

#---------------------------------------------
#Light-duty vehicle powertrain characteristics
#---------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "ModelYear",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoIcevMpg",
            "LtTrkIcevMpg",
            "AutoHevMpg",
            "LtTrkHevMpg",
            "AutoPhevMpg",
            "AutoPhevMpkwh",
            "AutoPhevRange",
            "LtTrkPhevMpg",
            "LtTrkPhevMpkwh",
            "LtTrkPhevRange",
            "AutoBevMpkwh",
            "AutoBevRange",
            "LtTrkBevMpkwh",
            "LtTrkBevRange"),
    TYPE = "double",
    PROHIBIT = c("<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
LdvPowertrainCharacteristics_df <-
  processEstimationInputs(
    Inp_ls,
    "ldv_powertrain_characteristics.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- 1975:2050
if (!all(LdvPowertrainCharacteristics_df$ModelYear %in% Years_)) {
  stop(paste(
    "File 'ldv_powertrain_characteristics.csv' must have values for the years",
    "from 1975 through 2050", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df <-
  LdvPowertrainCharacteristics_df
rm(Inp_ls, LdvPowertrainCharacteristics_df)

#----------------------------------------
#Household vehicle powertrain proportions
#----------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "ModelYear",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoPropIcev",
            "AutoPropHev",
            "AutoPropPhev",
            "AutoPropBev",
            "LtTrkPropIcev",
            "LtTrkPropHev",
            "LtTrkPropPhev",
            "LtTrkPropBev"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
HhPowertrain_df <-
  processEstimationInputs(
    Inp_ls,
    "hh_powertrain_prop.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- 1975:2050
if (!all(HhPowertrain_df$ModelYear %in% Years_)) {
  stop(paste(
    "File 'hh_powertrain_prop.csv' must have values for the years",
    "from 1975 through 2050", sep = " "))
}
#Check that powertrain proportion are 0 when powertrain characteristics are NA
Msg_ <- character(0)
for (ty in c("Auto", "LtTrk")) {
  for (pt in c("Icev", "Hev", "Phev", "Bev")) {
    PtType <- paste0(ty, pt)
    PropName <- paste0(ty, "Prop", pt)
    CharName <- paste0(ty, pt, "Mpg")
    if (pt == "Bev") CharName <- paste0(ty, pt, "Mpkwh")
    Prop_ <- HhPowertrain_df[[PropName]]
    Char_ <- PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df[[CharName]]
    if (any(Prop_[is.na(Char_)] != 0)) {
      Msg <- paste0(
        "hh_powertrain_prop.csv file error. Non-zero proportion(s) for ",
        PropName, " where NA values in ldv_powertrain_characteristics.csv for ",
        CharName)
      Msg_ <- c(Msg_, Msg)
    }
  }
}
if (length(Msg_) != 0) {
  stop(paste(Msg_, collapse = ", "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$HhPowertrain_df <- HhPowertrain_df
rm(Inp_ls, HhPowertrain_df)

#------------------------------------------
#Car service vehicle powertrain proportions
#------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoPropIcev",
            "AutoPropHev",
            "AutoPropBev",
            "LtTrkPropIcev",
            "LtTrkPropHev",
            "LtTrkPropBev"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
CarSvcPowertrain_df <-
  processEstimationInputs(
    Inp_ls,
    "carsvc_powertrain_prop.csv",
    "LoadDefaultValues.R")
#Check and adjust auto values
AutoNames_ <- c("AutoPropIcev", "AutoPropHev", "AutoPropBev")
AutoCols_ <-  which(names(CarSvcPowertrain_df) %in% AutoNames_)
if (any(abs(1 - rowSums(CarSvcPowertrain_df[AutoCols_])) > 0.01)) {
  stop("Auto proportion values in 'carsvc_powertrain_prop.csv' do not sum to 1.")
}
CarSvcPowertrain_df[,AutoCols_] <-
  sweep(CarSvcPowertrain_df[,AutoCols_], 1,
        rowSums(CarSvcPowertrain_df[,AutoCols_]), "*")
#Check and adjust light truck values
LtTrkNames_ <- c("LtTrkPropIcev", "LtTrkPropHev", "LtTrkPropBev")
LtTrkCols_ <-  which(names(CarSvcPowertrain_df) %in% LtTrkNames_)
if (any(abs(1 - rowSums(CarSvcPowertrain_df[LtTrkCols_])) > 0.01)) {
  stop("LtTrk proportion values in 'carsvc_powertrain_prop.csv' do not sum to 1.")
}
CarSvcPowertrain_df[,LtTrkCols_] <-
  sweep(CarSvcPowertrain_df[,LtTrkCols_], 1,
        rowSums(CarSvcPowertrain_df[,LtTrkCols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(CarSvcPowertrain_df$Year %in% Years_)) {
  stop(paste(
    "File 'carsvc_powertrain_prop.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Check that powertrain proportion are 0 when powertrain characteristics are NA
Msg_ <- character(0)
for (ty in c("Auto", "LtTrk")) {
  for (pt in c("Icev", "Hev", "Bev")) {
    PtType <- paste0(ty, pt)
    PropName <- paste0(ty, "Prop", pt)
    CharName <- paste0(ty, pt, "Mpg")
    if (pt == "Bev") CharName <- paste0(ty, pt, "Mpkwh")
    Prop_ <- CarSvcPowertrain_df[[PropName]]
    names(Prop_) <- CarSvcPowertrain_df$Year
    Char_ <- PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df[[CharName]]
    names(Char_) <- PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df$ModelYear
    Char_ <- Char_[names(Prop_)]
    if (any(Prop_[is.na(Char_)] != 0)) {
      Msg <- paste0(
        "carsvc_powertrain_prop.csv file error. Non-zero proportion(s) for ",
        PropName, " where NA values in ldv_powertrain_characteristics.csv for ",
        CharName)
      Msg_ <- c(Msg_, Msg)
    }
    rm(PtType, PropName, CharName, Prop_, Char_)
    if (exists("Msg")) rm(Msg)
  }
}
if (length(Msg_) != 0) {
  stop(paste(Msg_, collapse = ", "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$CarSvcPowertrain_df <- CarSvcPowertrain_df
rm(Inp_ls, AutoNames_, AutoCols_, LtTrkNames_, LtTrkCols_, Years_, Msg_, ty,
   pt, CarSvcPowertrain_df)

#-------------------------------------------------
#Commercial service vehicle powertrain proportions
#-------------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("AutoPropIcev",
            "AutoPropHev",
            "AutoPropBev",
            "LtTrkPropIcev",
            "LtTrkPropHev",
            "LtTrkPropBev"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
ComSvcPowertrain_df <-
  processEstimationInputs(
    Inp_ls,
    "comsvc_powertrain_prop.csv",
    "LoadDefaultValues.R")
#Check and adjust auto values
AutoNames_ <- c("AutoPropIcev", "AutoPropHev", "AutoPropBev")
AutoCols_ <-  which(names(ComSvcPowertrain_df) %in% AutoNames_)
if (any(abs(1 - rowSums(ComSvcPowertrain_df[AutoCols_])) > 0.01)) {
  stop("Auto proportion values in 'comsvc_powertrain_prop.csv' do not sum to 1.")
}
ComSvcPowertrain_df[,AutoCols_] <-
  sweep(ComSvcPowertrain_df[,AutoCols_], 1,
        rowSums(ComSvcPowertrain_df[,AutoCols_]), "*")
#Check and adjust light truck values
LtTrkNames_ <- c("LtTrkPropIcev", "LtTrkPropHev", "LtTrkPropBev")
LtTrkCols_ <-  which(names(ComSvcPowertrain_df) %in% LtTrkNames_)
if (any(abs(1 - rowSums(ComSvcPowertrain_df[LtTrkCols_])) > 0.01)) {
  stop("LtTrk proportion values in 'comsvc_powertrain_prop.csv' do not sum to 1.")
}
ComSvcPowertrain_df[,LtTrkCols_] <-
  sweep(ComSvcPowertrain_df[,LtTrkCols_], 1,
        rowSums(ComSvcPowertrain_df[,LtTrkCols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(ComSvcPowertrain_df$Year %in% Years_)) {
  stop(paste(
    "File 'comsvc_fuel.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Check that powertrain proportion are 0 when powertrain characteristics are NA
Msg_ <- character(0)
for (ty in c("Auto", "LtTrk")) {
  for (pt in c("Icev", "Hev", "Bev")) {
    PtType <- paste0(ty, pt)
    PropName <- paste0(ty, "Prop", pt)
    CharName <- paste0(ty, pt, "Mpg")
    if (pt == "Bev") CharName <- paste0(ty, pt, "Mpkwh")
    Prop_ <- ComSvcPowertrain_df[[PropName]]
    names(Prop_) <- ComSvcPowertrain_df$Year
    Char_ <- PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df[[CharName]]
    names(Char_) <- PowertrainFuelDefaults_ls$LdvPowertrainCharacteristics_df$ModelYear
    Char_ <- Char_[names(Prop_)]
    if (any(Prop_[is.na(Char_)] != 0)) {
      Msg <- paste0(
        "comsvc_powertrain_prop.csv file error. Non-zero proportion(s) for ",
        PropName, " where NA values in ldv_powertrain_characteristics.csv for ",
        CharName)
      Msg_ <- c(Msg_, Msg)
    }
    rm(PtType, PropName, CharName, Prop_, Char_)
    if (exists("Msg")) rm(Msg)
  }
}
if (length(Msg_) != 0) {
  stop(paste(Msg_, collapse = ", "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$ComSvcPowertrain_df <- ComSvcPowertrain_df
rm(Inp_ls, AutoNames_, AutoCols_, LtTrkNames_, LtTrkCols_, Years_, Msg_, ty,
   pt, ComSvcPowertrain_df)

#------------------------------------
#Heavy truck vehicle fuel proportions
#------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items(
            "PropDiesel",
            "PropGasoline",
            "PropLng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
HvyTrkFuel_df <-
  processEstimationInputs(
    Inp_ls,
    "hvytrk_fuel.csv",
    "LoadDefaultValues.R")
#Check and adjust values
Names_ <- c("PropGasoline", "PropDiesel", "PropLng")
Cols_ <-  which(names(HvyTrkFuel_df) %in% Names_)
if (any(abs(1 - rowSums(HvyTrkFuel_df[Cols_])) > 0.01)) {
  stop("Proportion values in 'hvytrk_fuel.csv' do not sum to 1.")
}
HvyTrkFuel_df[,Cols_] <-
  sweep(HvyTrkFuel_df[,Cols_], 1, rowSums(HvyTrkFuel_df[,Cols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(HvyTrkFuel_df$Year %in% Years_)) {
  stop(paste(
    "File 'hvytrk_fuel.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$HvyTrkFuel_df <- HvyTrkFuel_df
rm(Inp_ls, Names_, Cols_, Years_, HvyTrkFuel_df)

#-----------------------
#Heavy truck biofuel mix
#-----------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("EthanolPropGasoline",
            "BiodieselPropDiesel",
            "RngPropLng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
HvyTrkBiofuelMix_df <-
  processEstimationInputs(
    Inp_ls,
    "hvytrk_biofuel_mix.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(HvyTrkBiofuelMix_df$Year %in% Years_)) {
  stop(paste(
    "File 'hvytrk_biofuel_mix.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$HvyTrkBiofuelMix_df <- HvyTrkBiofuelMix_df
rm(Inp_ls, HvyTrkBiofuelMix_df)

#--------------------------------------
#Heavy truck powertrain characteristics
#--------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("HvyTrkIcevMpg",
            "HvyTrkHevMpg",
            "HvyTrkBevMpkwh"),
    TYPE = "double",
    PROHIBIT = c("<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
HvyTrkPowertrainCharacteristics_df <-
  processEstimationInputs(
    Inp_ls,
    "hvytrk_powertrain_characteristics.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(HvyTrkPowertrainCharacteristics_df$Year %in% Years_)) {
  stop(paste(
    "File 'hvytrk_powertrain_characteristics.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$HvyTrkPowertrainCharacteristics_df <-
  HvyTrkPowertrainCharacteristics_df
rm(Inp_ls, HvyTrkPowertrainCharacteristics_df)

#----------------------------------
#Heavy truck powertrain proportions
#----------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("HvyTrkPropIcev",
            "HvyTrkPropHev",
            "HvyTrkPropBev"),
    TYPE = "double",
    PROHIBIT = c("< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
HvyTrkPowertrain_df <-
  processEstimationInputs(
    Inp_ls,
    "hvytrk_powertrain_prop.csv",
    "LoadDefaultValues.R")
#Check and adjust auto values
Names_ <- c("HvyTrkPropIcev", "HvyTrkPropHev", "HvyTrkPropBev")
Cols_ <-  which(names(HvyTrkPowertrain_df) %in% Names_)
if (any(abs(1 - rowSums(HvyTrkPowertrain_df[Cols_])) > 0.01)) {
  stop("Heavy truck proportion values in 'hvytrk_powertrain_prop.csv' do not sum to 1.")
}
HvyTrkPowertrain_df[,Cols_] <-
  sweep(HvyTrkPowertrain_df[,Cols_], 1,
        rowSums(HvyTrkPowertrain_df[,Cols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(HvyTrkPowertrain_df$Year %in% Years_)) {
  stop(paste(
    "File 'hvytrk_powertrain_prop.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Check that powertrain proportion are 0 when powertrain characteristics are NA
Msg_ <- character(0)
for (pt in c("Icev", "Hev", "Bev")) {
  PropName <- paste0("HvyTrkProp", pt)
  CharName <- paste0("HvyTrk", pt, "Mpg")
  if (pt == "Bev") CharName <- paste0("HvyTrk", pt, "Mpkwh")
  Prop_ <- HvyTrkPowertrain_df[[PropName]]
  names(Prop_) <- HvyTrkPowertrain_df$Year
  Char_ <- PowertrainFuelDefaults_ls$HvyTrkPowertrainCharacteristics_df[[CharName]]
  names(Char_) <- PowertrainFuelDefaults_ls$HvyTrkPowertrainCharacteristics_df$Year
  Char_ <- Char_[names(Prop_)]
  if (any(Prop_[is.na(Char_)] != 0)) {
    Msg <- paste0(
      "hvytrk_powertrain_prop.csv file error. Non-zero proportion(s) for ",
      PropName, " where NA values in hvytrk_powertrain_characteristics.csv for ",
      CharName)
    Msg_ <- c(Msg_, Msg)
  }
  rm(PropName, CharName, Prop_, Char_)
  if (exists("Msg")) rm(Msg)
}
if (length(Msg_) != 0) {
  stop(paste(Msg_, collapse = ", "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$HvyTrkPowertrain_df <- HvyTrkPowertrain_df
rm(Inp_ls, Names_, Cols_, Years_, Msg_, pt, HvyTrkPowertrain_df)

#--------------------------------
#Transit vehicle fuel proportions
#--------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items(
        "VanPropDiesel",
        "VanPropGasoline",
        "VanPropCng",
        "BusPropDiesel",
        "BusPropGasoline",
        "BusPropCng",
        "RailPropDiesel",
        "RailPropGasoline"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
TransitFuel_df <-
  processEstimationInputs(
    Inp_ls,
    "transit_fuel.csv",
    "LoadDefaultValues.R")
#Check and adjust van values
Names_ <- c("VanPropDiesel", "VanPropGasoline", "VanPropCng")
Cols_ <-  which(names(TransitFuel_df) %in% Names_)
if (any(abs(1 - rowSums(TransitFuel_df[Cols_])) > 0.01)) {
  stop("Proportion values for vans in 'transit_fuel.csv' do not sum to 1.")
}
TransitFuel_df[,Cols_] <-
  sweep(TransitFuel_df[,Cols_], 1, rowSums(TransitFuel_df[,Cols_]), "*")
#Check and adjust bus values
Names_ <- c("BusPropDiesel", "BusPropGasoline", "BusPropCng")
Cols_ <-  which(names(TransitFuel_df) %in% Names_)
if (any(abs(1 - rowSums(TransitFuel_df[Cols_])) > 0.01)) {
  stop("Proportion values for buses in 'transit_fuel.csv' do not sum to 1.")
}
TransitFuel_df[,Cols_] <-
  sweep(TransitFuel_df[,Cols_], 1, rowSums(TransitFuel_df[,Cols_]), "*")
#Check and adjust rail values
Names_ <- c("RailPropDiesel", "RailPropGasoline")
Cols_ <-  which(names(TransitFuel_df) %in% Names_)
if (any(abs(1 - rowSums(TransitFuel_df[Cols_])) > 0.01)) {
  stop("Proportion values for rail in 'transit_fuel.csv' do not sum to 1.")
}
TransitFuel_df[,Cols_] <-
  sweep(TransitFuel_df[,Cols_], 1, rowSums(TransitFuel_df[,Cols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(TransitFuel_df$Year %in% Years_)) {
  stop(paste(
    "File 'transit_fuel.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$TransitFuel_df <- TransitFuel_df
rm(Inp_ls, Names_, Cols_, Years_, TransitFuel_df)

#-------------------
#Transit biofuel mix
#-------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("EthanolPropGasoline",
            "BiodieselPropDiesel",
            "RngPropCng"),
    TYPE = "double",
    PROHIBIT = c("NA", "< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
TransitBiofuelMix_df <-
  processEstimationInputs(
    Inp_ls,
    "transit_biofuel_mix.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(TransitBiofuelMix_df$Year %in% Years_)) {
  stop(paste(
    "File 'transit_biofuel_mix.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$TransitBiofuelMix_df <- TransitBiofuelMix_df
rm(Inp_ls, TransitBiofuelMix_df)

#------------------------------------------
#Transit vehicle powertrain characteristics
#------------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("VanIcevMpg",
            "VanHevMpg",
            "VanBevMpkwh",
            "BusIcevMpg",
            "BusHevMpg",
            "BusBevMpkwh",
            "RailIcevMpg",
            "RailHevMpg",
            "RailEvMpkwh"),
    TYPE = "double",
    PROHIBIT = c("<= 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
TransitPowertrainCharacteristics_df <-
  processEstimationInputs(
    Inp_ls,
    "transit_powertrain_characteristics.csv",
    "LoadDefaultValues.R")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(TransitPowertrainCharacteristics_df$Year %in% Years_)) {
  stop(paste(
    "File 'transit_powertrain_characteristics.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$TransitPowertrainCharacteristics_df <-
  TransitPowertrainCharacteristics_df
rm(Inp_ls, TransitPowertrainCharacteristics_df)

#--------------------------------------
#Transit vehicle powertrain proportions
#--------------------------------------
#Specify input file attributes
Inp_ls <- items(
  item(
    NAME = "Year",
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  ),
  item(
    NAME =
      items("VanPropIcev",
            "VanPropHev",
            "VanPropBev",
            "BusPropIcev",
            "BusPropHev",
            "BusPropBev",
            "RailPropIcev",
            "RailPropHev",
            "RailPropEv"),
    TYPE = "double",
    PROHIBIT = c("< 0", "> 1"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)
#Load and process data
TransitPowertrain_df <-
  processEstimationInputs(
    Inp_ls,
    "transit_powertrain_prop.csv",
    "LoadDefaultValues.R")
#Check and adjust van values
Names_ <- c("VanPropIcev", "VanPropHev", "VanPropBev")
Cols_ <-  which(names(TransitPowertrain_df) %in% Names_)
if (any(abs(1 - rowSums(TransitPowertrain_df[Cols_])) > 0.01)) {
  stop("Transit van proportion values in 'transit_powertrain_prop.csv' do not sum to 1.")
}
TransitPowertrain_df[,Cols_] <-
  sweep(TransitPowertrain_df[,Cols_], 1,
        rowSums(TransitPowertrain_df[,Cols_]), "*")
#Check and adjust bus values
Names_ <- c("BusPropIcev", "BusPropHev", "BusPropBev")
Cols_ <-  which(names(TransitPowertrain_df) %in% Names_)
if (any(abs(1 - rowSums(TransitPowertrain_df[Cols_])) > 0.01)) {
  stop("Transit bus proportion values in 'transit_powertrain_prop.csv' do not sum to 1.")
}
TransitPowertrain_df[,Cols_] <-
  sweep(TransitPowertrain_df[,Cols_], 1,
        rowSums(TransitPowertrain_df[,Cols_]), "*")
#Check and adjust rail values
Names_ <- c("RailPropIcev", "RailPropHev", "RailPropEv")
Cols_ <-  which(names(TransitPowertrain_df) %in% Names_)
if (any(abs(1 - rowSums(TransitPowertrain_df[Cols_])) > 0.01)) {
  stop("Transit rail proportion values in 'transit_powertrain_prop.csv' do not sum to 1.")
}
TransitPowertrain_df[,Cols_] <-
  sweep(TransitPowertrain_df[,Cols_], 1,
        rowSums(TransitPowertrain_df[,Cols_]), "*")
#Check whether all years are present
Years_ <- c(1990, 2000, 2005, 2010, 2020, 2030, 2040, 2050)
if (!all(TransitPowertrain_df$Year %in% Years_)) {
  stop(paste(
    "File 'transit_powertrain_prop.csv' must have values for the years",
    "1990, 2000, 2010, 2020, 2030, 2040, 2050.", sep = " "))
}
#Check that powertrain proportion are 0 when powertrain characteristics are NA
Msg_ <- character(0)
for (ty in c("Van", "Bus", "Rail")) {
  for (pt in c("Icev", "Hev", "Bev")) {
    if (ty == "Rail" & pt == "Bev") pt <- "Ev"
    PtType <- paste0(ty, pt)
    PropName <- paste0(ty, "Prop", pt)
    CharName <- paste0(ty, pt, "Mpg")
    if (pt == "Bev" | pt == "Ev") CharName <- paste0(ty, pt, "Mpkwh")
    Prop_ <- TransitPowertrain_df[[PropName]]
    names(Prop_) <- TransitPowertrain_df$Year
    Char_ <- PowertrainFuelDefaults_ls$TransitPowertrainCharacteristics_df[[CharName]]
    names(Char_) <- PowertrainFuelDefaults_ls$TransitPowertrainCharacteristics_df$Year
    Char_ <- Char_[names(Prop_)]
    if (any(Prop_[is.na(Char_)] != 0)) {
      Msg <- paste0(
        "transit_powertrain_prop.csv file error. Non-zero proportion(s) for ",
        PropName, " where NA values in transit_powertrain_characteristics.csv for ",
        CharName)
      Msg_ <- c(Msg_, Msg)
    }
    rm(PtType, PropName, CharName, Prop_, Char_)
    if (exists("Msg")) rm(Msg)
  }
}
if (length(Msg_) != 0) {
  stop(paste(Msg_, collapse = ", "))
}
#Add to PowertrainFuelDefaults_ls and clean up
PowertrainFuelDefaults_ls$TransitPowertrain_df <- TransitPowertrain_df
rm(Inp_ls, Names_, Cols_, Years_, Msg_, ty, pt, TransitPowertrain_df)


#==========================================================
#DOCUMENT AND SAVE DEFAULT VEHICLE AND FUEL CHARACTERISTICS
#==========================================================

#' Default energy and emissions data
#'
#' A list of datasets containing default assumptions about fuel and electricity
#' carbon intensities, vehicle fuel mixess, vehicle powertrain mixes, and
#' vehicle powertrain mixes by transportation and vehicle type.
#'
#' @format A list containing 17 data frames:
#' \describe{
#'   \item{CongestionEfficiency_df}{the relative efficiency of vehicle types in congestion by year}
#'     \item{LdIce}{congestion efficiency of light-duty internal combustion engine vehicles}
#'     \item{LdHev}{congestion efficiency of light-duty hybrid-electric engine vehicles}
#'     \item{LdEv}{congestion efficiency of light-duty battery electric vehicles}
#'     \item{LdFcv}{congestion efficiency of light-duty fuel cell vehicles}
#'     \item{HdIce}{congestion efficiency of heavy-duty internal combustion engine vehicles}
#'   \item{CarbonIntensity_df}{a data frame of the carbon intensities of vehicle energy sources by year}
#'     \item{Year}{calendar year}
#'     \item{Gasoline}{carbon intensity of gasoline}
#'     \item{Diesel}{carbon intensity of diesel}
#'     \item{Cng}{carbon intensity of compressed natural gas}
#'     \item{Lng}{carbon intensity of liquified natural gas}
#'     \item{Ethanol}{carbon intensity of ethanol}
#'     \item{Biodiesel}{carbon intensity of biodiesel}
#'     \item{Rng}{carbon intensity of renewable natural gas}
#'     \item{Electricity}{carbon intensity of electricity}
#'   \item{CarSvcFuel_df}{a data frame of fuel proportions by fuel type used by car service vehicles by year}
#'     \item{Year}{calendar year}
#'     \item{AutoPropGasoline}{gasoline proportion auto fuel}
#'     \item{AutoPropDiesel}{diesel proportion of auto fuel}
#'     \item{AutoPropCng}{compressed natural gas proportion of auto fuel}
#'     \item{LtTrkPropGasoline}{gasoline proportion of light truck fuel}
#'     \item{LtTrkPropDiesel}{diesel proportion of light truck fuel}
#'     \item{LtTrkPropCng}{compressed natural gas proportion of light truck fuel}
#'   \item{ComSvcFuel_df}{a data frame of fuel proportions by fuel type used by commercial service vehicles by year}
#'     \item{Year}{calendar year}
#'     \item{AutoPropGasoline}{gasoline proportion auto fuel}
#'     \item{AutoPropDiesel}{diesel proportion of auto fuel}
#'     \item{AutoPropCng}{compressed natural gas proportion of auto fuel}
#'     \item{LtTrkPropGasoline}{gasoline proportion of light truck fuel}
#'     \item{LtTrkPropDiesel}{diesel proportion of light truck fuel}
#'     \item{LtTrkPropCng}{compressed natural gas proportion of light truck fuel}
#'   \item{HhFuel_df}{a data frame of fuel proportions by fuel type used by household vehicles by year}
#'     \item{Year}{calendar year}
#'     \item{AutoPropGasoline}{gasoline proportion auto fuel}
#'     \item{AutoPropDiesel}{diesel proportion of auto fuel}
#'     \item{AutoPropCng}{compressed natural gas proportion of auto fuel}
#'     \item{LtTrkPropGasoline}{gasoline proportion of light truck fuel}
#'     \item{LtTrkPropDiesel}{diesel proportion of light truck fuel}
#'     \item{LtTrkPropCng}{compressed natural gas proportion of light truck fuel}
#'   \item{LdvBiofuelMix_df}{a data frame of biofuel proportions for light-duty vehicle fuels by year}
#'     \item{Year}{calendar year}
#'     \item{EthanolPropGasoline}{ethanol proportion of gasoline}
#'     \item{BiodieselPropDiesel}{biodiesel proportion of diesel}
#'     \item{RngPropCng}{renewable natural gas proportion of compressed natural gas}
#'   \item{LdvPowertrainCharacteristics_df}{a data frame of light-duty vehicle powertrain characteristics by vehicle model year}
#'     \item{ModelYear}{Model year}
#'     \item{AutoIcevMpg}{Average fuel economy of automobiles having internal combustion engines (miles per gallon)}
#'     \item{LtTrkIcevMpg}{Average fuel economy of light trucks having internal combustion engines (miles per gallon)}
#'     \item{AutoHevMpg}{Average fuel economy of automobiles having hybrid electric powertrains (miles per gallon)}
#'     \item{LtTrkHevMpg}{Average fuel economy of light trucks having hybrid electric powertrains (miles per gallon)}
#'     \item{AutoPhevMpg}{Average fuel economy of automobiles having plug-in hybrid electric powertrains (miles per gallon)}
#'     \item{AutoPhevMpkwh}{Average power economy of automobiles having plug-in hybrid electric powertrains (miles per kilowatt hour)}
#'     \item{AutoPhevRange}{Average battery range of automobiles having plug-in hybrid electric powertrains (miles)}
#'     \item{LtTrkPhevMpg}{Average fuel economy of light trucks having plug-in hybrid electric powertrains (miles per gallon)}
#'     \item{LtTrkPhevMpkwh}{Average power economy of light trucks having plug-in hybrid electric powertrains (miles per kilowatt hour)}
#'     \item{LtTrkPhevRange}{Average battery range of light trucks having plug-in hybrid electric powertrains (miles)}
#'     \item{AutoBevMpkwh}{Average power economy of automobiles having battery electric powertrains (miles per kilowatt hour)}
#'     \item{AutoBevRange}{Average battery range of automobiles having battery electric powertrains (miles)}
#'     \item{LtTrkBevMpkwh}{Average power economy of light trucks having battery electric powertrains (miles per kilowatt hour)}
#'     \item{LtTrkBevRange}{Average battery range of light trucks having battery electric powertrains (miles)}
#'   \item{HhPowertrain_df}{a data frame of household vehicle powertrain proportions by vehicle model year}
#'     \item{ModelYear}{Model year}
#'     \item{AutoPropIcev}{Proportion of automobiles that have internal combustion engine powertrains}
#'     \item{AutoPropHev}{Proportion of automobiles that have hybrid electric powertrains}
#'     \item{AutoPropPhev}{Proportion of automobiles that have plug-in hybrid electric powertrains}
#'     \item{AutoPropBev}{Proportion of automobiles that have battery electric powertrains}
#'     \item{LtTrkPropIcev}{Proportion of light trucks that have internal combustion engine powertrains}
#'     \item{LtTrkPropHev}{Proportion of light trucks that have hybrid electric powertrains}
#'     \item{LtTrkPropPhev}{Proportion of light trucks that have plug-in hybrid electric powertrains}
#'     \item{LtTrkPropBev}{Proportion of light trucks that have battery electric powertrains}
#'   \item{CarSvcPowertrain_df}{a data frame of powertrain proportions of car service vehicles by year}
#'     \item{Year}{calendar year}
#'     \item{AutoPropIcev}{Proportion of automobiles that have internal combustion engine powertrains}
#'     \item{AutoPropHev}{Proportion of automobiles that have hybrid electric powertrains}
#'     \item{AutoPropBev}{Proportion of automobiles that have battery electric powertrains}
#'     \item{LtTrkPropIcev}{Proportion of light trucks that have internal combustion engine powertrains}
#'     \item{LtTrkPropHev}{Proportion of light trucks that have hybrid electric powertrains}
#'     \item{LtTrkPropBev}{Proportion of light trucks that have battery electric powertrains}
#'   \item{ComSvcPowertrain_df}{a data frame of powertrain proportions of commercial service vehicles by year}
#'     \item{Year}{calendar year}
#'     \item{AutoPropIcev}{Proportion of automobiles that have internal combustion engine powertrains}
#'     \item{AutoPropHev}{Proportion of automobiles that have hybrid electric powertrains}
#'     \item{AutoPropBev}{Proportion of automobiles that have battery electric powertrains}
#'     \item{LtTrkPropIcev}{Proportion of light trucks that have internal combustion engine powertrains}
#'     \item{LtTrkPropHev}{Proportion of light trucks that have hybrid electric powertrains}
#'     \item{LtTrkPropBev}{Proportion of light trucks that have battery electric powertrains}
#'   \item{HvyTrkFuel_df}{a data frame of fuel proportions by fuel type used by heavy trucks by year}
#'     \item{Year}{calendar year}
#'     \item{PropDiesel}{diesel proportion of heavy truck fuel}
#'     \item{PropGasoline}{gasoline proportion heavy truck fuel}
#'     \item{PropLng}{liquified natural gas proportion of heavy truck fuel}
#'   \item{HvyTrkBiofuelMix_df}{a data frame of biofuel proportions for heavy truck fuels by year}
#'     \item{Year}{calendar year}
#'     \item{EthanolPropGasoline}{ethanol proportion of gasoline}
#'     \item{BiodieselPropDiesel}{biodiesel proportion of diesel}
#'     \item{RngPropLng}{renewable natural gas proportion of liquified natural gas}
#'   \item{HvyTrkPowertrainCharacteristics_df}{a data frame of heavy truck powertrain characteristics by year}
#'     \item{Year}{calendar year}
#'     \item{HvyTrkIcevMpg}{Average fuel economy of heavy trucks having internal combustion engines (miles per gallon)}
#'     \item{HvyTrkHevMpg}{Average fuel economy of heavy trucks having hybrid electric powertrains (miles per gallon)}
#'     \item{HvyTrkBevMpkwh}{Average power economy of heavy trucks having battery electric powertrains (miles per kilowatt hour)}
#'   \item{HvyTrkPowertrain_df}{a data frame of heavy truck powertrain proportions by year}
#'     \item{Year}{calendar year}
#'     \item{HvyTrkPropIcev}{Proportion of heavy trucks that have internal combustion engine powertrains}
#'     \item{HvyTrkPropBev}{Proportion of heavy trucks that have battery electric powertrains}
#'   \item{TransitFuel_df}{a data frame of fuel proportions by fuel type for each transit vehicle type by year}
#'     \item{Year}{calendar year}
#'     \item{VanPropDiesel}{diesel proportion of transit van fuel}
#'     \item{VanPropGasoline}{gasoline proportion of transit van fuel}
#'     \item{VanPropCng}{liquified natural gas proportion of transit van fuel}
#'     \item{BusPropDiesel}{diesel proportion of transit bus fuel}
#'     \item{BusPropGasoline}{gasoline proportion of transit bus fuel}
#'     \item{BusPropCng}{liquified natural gas proportion of transit bus fuel}
#'     \item{RailPropDiesel}{diesel proportion of rail transit fuel}
#'     \item{RailPropGasoline}{gasoline proportion of rail transit fuel}
#'   \item{TransitBiofuelMix_df}{a data frame of biofuel proportions for transit fuels by year}
#'     \item{Year}{calendar year}
#'     \item{EthanolPropGasoline}{ethanol proportion of gasoline}
#'     \item{BiodieselPropDiesel}{biodiesel proportion of diesel}
#'     \item{RngPropLng}{renewable natural gas proportion of liquified natural gas}
#'   \item{TransitPowertrainCharacteristics_df}{a data frame of transit vehicle powertrain characteristics by year}
#'     \item{Year}{Calendar year}
#'     \item{VanIcevMpg}{Average fuel economy of transit vans having internal combustion engines (miles per gallon)}
#'     \item{VanHevMpg}{Average fuel economy of transit vans having hybrid electric powertrains (miles per gallon)}
#'     \item{VanBevMpkwh}{Average power economy of transit vans having battery electric powertrains (miles per kilowatt hour)}
#'     \item{BusIcevMpg}{Average fuel economy of transit buses having internal combustion engines (miles per gallon)}
#'     \item{BusHevMpg}{Average fuel economy of transit buses having hybrid electric powertrains (miles per gallon)}
#'     \item{BusBevMpkwh}{Average power economy of transit buses having battery electric powertrains (miles per kilowatt hour)}
#'     \item{RailIcevMpg}{Average fuel economy of transit rail vehicles having internal combustion engines (miles per gallon)}
#'     \item{RailHevMpg}{Average fuel economy of transit rail vehicles having hybrid electric powertrains (miles per gallon)}
#'     \item{RailEvMpkwh}{Average power economy of transit rail vehicles having electric powertrains (miles per kilowatt hour)}
#'   \item{TransitPowertrain_df}{a data frame of powertrain proportions of transit vehicles by year}
#'     \item{Year}{calendar year}
#'     \item{VanPropIcev}{Proportion of transit vans that have internal combustion engine powertrains}
#'     \item{VanTrkPropHev}{Proportion of transit vans that have hybrid electric powertrains}
#'     \item{VanTrkPropBev}{Proportion of transit vans that have battery electric powertrains}
#'     \item{BusPropIcev}{Proportion of transit buses that have internal combustion engine powertrains}
#'     \item{BusTrkPropHev}{Proportion of transit buses that have hybrid electric powertrains}
#'     \item{BusTrkPropBev}{Proportion of transit buses that have battery electric powertrains}
#'     \item{RailPropIcev}{Proportion of rail transit vehicles that have internal combustion engine powertrains}
#'     \item{RailTrkPropHev}{Proportion of rail transit vehicles that have hybrid electric powertrains}
#'     \item{RailTrkPropEv}{Proportion of rail transit vehicles that have electric powertrains}
#' }
#' @source LoadDefaultValues.R script.
"PowertrainFuelDefaults_ls"
usethis::use_data(PowertrainFuelDefaults_ls, overwrite = TRUE)
rm(PowertrainFuelDefaults_ls)
