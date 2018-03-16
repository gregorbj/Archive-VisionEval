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
    ),
    item(
      NAME = "AutoPropHEV",
      TABLE = "HHPowertrainProportions",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA",  "< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "DatasetNotThere",
      TABLE = "HHPowertrainProportions",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA",  "< 0", "> 1"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "HhId",
      TABLE = "Vehicle",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    ),
    item(
      NAME = "DatasetNotThere",
      TABLE = "Vehicle",
      GROUP = "BaseYear",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  )
)


#Second set of specifications to test if OPTIONAl attribute is retained for
#Get and Set specs.

PredictWorkersSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME =
        items("RelEmp15to19",
              "RelEmp20to29",
              "RelEmp30to54",
              "RelEmp55to64",
              "RelEmp65Plus"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("< 0"),
      ISELEMENTOF = "",
      OPTIONAL = TRUE
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME =
        items("Wkr15to19",
              "Wkr20to29",
              "Wkr30to54",
              "Wkr55to64",
              "Wkr65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION =
        items("Workers in 15 to 19 year old age group",
              "Workers in 20 to 29 year old age group",
              "Workers in 30 to 54 year old age group",
              "Workers in 55 to 64 year old age group",
              "Workers in 65 or older age group"),
      OPTIONAL = TRUE
    )
  )
)
setwd("tests")
ProcessedSpec_ls <- processModuleSpecs(PredictWorkersSpecifications)
all(unlist(lapply(ProcessedSpec_ls$Get, function(x) {
  x$OPTIONAL == TRUE
})))
all(unlist(lapply(ProcessedSpec_ls$Set, function(x) {
  x$OPTIONAL == TRUE
})))
rm(ProcessedSpec_ls)
setwd("..")
