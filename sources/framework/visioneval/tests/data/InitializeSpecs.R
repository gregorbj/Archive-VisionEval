InitializeSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Time frame
  RunFor = "AllYears",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "ElectricityCI",
      FILE = "azone_electricity_carbon_intensity.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Carbon intensity of electricity at point of consumption (grams CO2e per megajoule)",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      FILE = "marea_transit_ave_fuel_carbon_intensity.csv",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuel used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuel used by transit rail vehicles (grams CO2e per megajoule)"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitEthanolPropGasoline",
          "TransitBiodieselPropDiesel",
          "TransitRngPropCng"
        ),
      FILE = "marea_transit_biofuel_mix.csv",
      TABLE = "Marea",
      GROUP = "Year",
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
          "Ethanol proportion of gasoline used by transit vehicles",
          "Biodiesel proportion of diesel used by transit vehicles",
          "Renewable natural gas proportion of compressed natural gas used by transit vehicles"
        ),
      OPTIONAL = TRUE
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
          "RailPropGasoline"
        ),
      FILE = "marea_transit_fuel.csv",
      TABLE = "Marea",
      GROUP = "Year",
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
          "Proportion of non-electric transit van travel powered by diesel",
          "Proportion of non-electric transit van travel powered by gasoline",
          "Proportion of non-electric transit van travel powered by compressed natural gas",
          "Proportion of non-electric transit bus travel powered by diesel",
          "Proportion of non-electric transit bus travel powered by gasoline",
          "Proportion of non-electric transit bus travel powered by compressed natural gas",
          "Proportion of non-electric transit rail travel powered by diesel",
          "Proportion of non-electric transit rail travel powered by gasoline"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropIcev",
          "VanPropHev",
          "VanPropBev",
          "BusPropIcev",
          "BusPropHev",
          "BusPropBev",
          "RailPropIcev",
          "RailPropHev",
          "RailPropEv"
        ),
      FILE = "marea_transit_powertrain_prop.csv",
      TABLE = "Marea",
      GROUP = "Year",
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
          "Proportion of transit van travel using internal combustion engine powertrains",
          "Proportion of transit van travel using hybrid electric powertrains",
          "Proportion of transit van travel using battery electric powertrains",
          "Proportion of transit bus travel using internal combustion engine powertrains",
          "Proportion of transit bus travel using hybrid electric powertrains",
          "Proportion of transit bus travel using battery electric powertrains",
          "Proportion of transit rail travel using internal combustion engine powertrains",
          "Proportion of transit rail travel using hybrid electric powertrains",
          "Proportion of transit rail travel using electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HhFuelCI",
          "CarSvcFuelCI",
          "ComSvcFuelCI",
          "HvyTrkFuelCI",
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      FILE = "region_ave_fuel_carbon_intensity.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        items(
          "Average carbon intensity of fuels used by household vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by car service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by commercial service vehicles (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by heavy trucks (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit vans (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit buses (grams CO2e per megajoule)",
          "Average carbon intensity of fuels used by transit rail vehicles (grams CO2e per megajoule)"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "CarSvcAutoPropIcev",
          "CarSvcAutoPropHev",
          "CarSvcAutoPropBev",
          "CarSvcLtTrkPropIcev",
          "CarSvcLtTrkPropHev",
          "CarSvcLtTrkPropBev"
        ),
      FILE = "region_carsvc_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
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
          "Proportion of car service automobile travel powered by internal combustion engine powertrains",
          "Proportion of car service automobile travel powered by hybrid electric powertrains",
          "Proportion of car service automobile travel powered by battery electric powertrains",
          "Proportion of car service light truck travel powered by internal combustion engine powertrains",
          "Proportion of car service light truck travel powered by hybrid electric powertrains",
          "Proportion of car service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "ComSvcAutoPropIcev",
          "ComSvcAutoPropHev",
          "ComSvcAutoPropBev",
          "ComSvcLtTrkPropIcev",
          "ComSvcLtTrkPropHev",
          "ComSvcLtTrkPropBev"
        ),
      FILE = "region_comsvc_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
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
          "Proportion of commercial service automobile travel powered by internal combustion engine powertrains",
          "Proportion of commercial service automobile travel powered by hybrid electric powertrains",
          "Proportion of commercial service automobile travel powered by battery electric powertrains",
          "Proportion of commercial service light truck travel powered by internal combustion engine powertrains",
          "Proportion of commercial service light truck travel powered by hybrid electric powertrains",
          "Proportion of commercial service light truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HvyTrkPropIcev",
          "HvyTrkPropHev",
          "HvyTrkPropBev"
        ),
      FILE = "region_hvytrk_powertrain_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
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
          "Proportion of heavy truck travel powered by internal combustion engine powertrains",
          "Proportion of heavy truck travel powered by hybrid electric powertrains",
          "Proportion of heavy truck travel powered by battery electric powertrains"
        ),
      OPTIONAL = TRUE
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "ElectricityCI",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "TransitEthanolPropGasoline",
          "TransitBiodieselPropDiesel",
          "TransitRngPropCng"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
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
          "RailPropGasoline"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "VanPropIcev",
          "VanPropHev",
          "VanPropBev",
          "BusPropIcev",
          "BusPropHev",
          "BusPropBev",
          "RailPropIcev",
          "RailPropHev",
          "RailPropEv"
        ),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HhFuelCI",
          "CarSvcFuelCI",
          "ComSvcFuelCI",
          "HvyTrkFuelCI",
          "TransitVanFuelCI",
          "TransitBusFuelCI",
          "TransitRailFuelCI"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "GM/MJ",
      PROHIBIT = "< 0",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "CarSvcAutoPropIcev",
          "CarSvcAutoPropHev",
          "CarSvcAutoPropBev",
          "CarSvcLtTrkPropIcev",
          "CarSvcLtTrkPropHev",
          "CarSvcLtTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "ComSvcAutoPropIcev",
          "ComSvcAutoPropHev",
          "ComSvcAutoPropBev",
          "ComSvcLtTrkPropIcev",
          "ComSvcLtTrkPropHev",
          "ComSvcLtTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME =
        items(
          "HvyTrkPropIcev",
          "HvyTrkPropHev",
          "HvyTrkPropBev"
        ),
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  ),
  #Specify data to saved in the data store
  Set = items(
  )
)
