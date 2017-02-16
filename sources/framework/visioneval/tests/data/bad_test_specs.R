BadTestSpec_ls <- list(
  #Level of geography module is applied at
  RunBy = "Dzone",
  #Specify new input table
  NewInpTable = items(
    item(
      TABLE = "This",
      GROUP = "BaseYear"
    )
  ),
  #Specify new set table
  NewSetTable = items(
    item(
      TABLE = "",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME =
        items("Metropolitan",
              "Town",
              "Rural"),
      FILE = "devtype_proportions.txt",
      TABLE = "Azone",
      GROUP = "BaseYear",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Marea",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "none",
      UNITS = "none",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Metropolitan",
              "Town",
              "Rural"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("Bzone",
              "Azone",
              "Marea"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "DevType",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = c("Metropolitan", "Town", "Rural")
    ),
    item(
      NAME = "NumHh",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "none",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)
