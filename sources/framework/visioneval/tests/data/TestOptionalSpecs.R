#===================
#TestOptionalSpecs.R
#===================
#Define the data specifications
#------------------------------
TestOptionalSpecs <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  Inp = items(
    item(
      NAME = "LtTrkProp",
      FILE = "azone_lttrk_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Proportion of household vehicles that are light trucks (pickup, SUV, van)",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "LtTrkProp",
      FILE = "azone_lttrk_prop.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Proportion of household vehicles that are light trucks (pickup, SUV, van)",
      OPTIONAL = FALSE
    ),
    item(
      NAME = "LtTrkProp",
      FILE = "file_not_there.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Proportion of household vehicles that are light trucks (pickup, SUV, van)",
      OPTIONAL = TRUE
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "LtTrkProp",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "LtTrkProp",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      OPTIONAL = FALSE
    ),
    item(
      NAME = "DatasetNotThere",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  )
)

