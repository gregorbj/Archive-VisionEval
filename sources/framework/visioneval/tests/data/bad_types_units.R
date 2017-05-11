items <- item <- list

#Data for checking inputs types and units
GoodBadTestInpSpec_ls <-
  items(
    item(
      NAME = "Dataset1",
      FILE = "Test.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "none",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    ),
    item(
      NAME = "Dataset2",
      FILE = "Test.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "none.1e3",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    ),
    item(
      NAME = "Dataset3",
      FILE = "Test.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2000.1e3",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    )
  )

for (i in 1:length(GoodBadTestInpSpec_ls)) {
  print(paste("Inp specification", i, "test"))
  print(
    checkSpecTypeUnits(
      parseUnitsSpec(
        GoodBadTestInpSpec_ls[[i]]),
      SpecGroup = "Inp")
    )
  print("-------------------------")
}

#Get specifications type and unit tests
GoodBadTestGetSpec_ls <-
  items(
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "Bogus",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons.1e3",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons.2e3",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UnprotectedArea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "ACRE.1e3",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "UnprotectedArea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "area",
      UNITS = "Acres.1e3",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TotalIncome",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010.1e3",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TotalIncome",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010.1000",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "TotalIncome",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    )
  )
for (i in 1:length(GoodBadTestGetSpec_ls)) {
  print(paste("Get specification", i, "test"))
  print(
    checkSpecTypeUnits(
      parseUnitsSpec(
        GoodBadTestGetSpec_ls[[i]]),
      SpecGroup = "Get")
  )
  print("-------------------------")
}


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
