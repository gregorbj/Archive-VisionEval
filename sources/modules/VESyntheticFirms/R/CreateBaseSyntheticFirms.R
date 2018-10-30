#==========================
#CreateBaseSyntheticFirms.R
#==========================

library(visioneval)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================
#This section creates a list of data specifications for input files, data to be
#loaded from the datastore, and outputs to be saved to the datastore. It also
#identifies the level of geography that is iterated over. For example, a
#congestion module could be applied by Marea. The name that is given to this
#list is the name of the module concatenated with "Specifications". In this
#case, the name is "CreateSyntheticFirmsSpecifications".
#
#The specifications list is saved and exported so that it will be in the
#namespace of the package and can be read by visioneval functions. The
#specifications list must be documented properly (using roxygen2 format) In
#order for it to be exported. The code below shows how to properly define,
#document, and save a module specifications list.

#The components of the specifications list are as follows:

#RunBy: This is the level of geography that the module is to be applied at.
#Acceptable values are "Region", "Azone", "Bzone", "Czone", and "Marea".

#Inp: A list of scenario inputs that are to be read from files and loaded into
#the datastore. The following need to be specified for every data item (i.e.
#column in a table):
#  NAME: the name of a data item in the input table;
#  FILE: the name of the file that contains the table;
#  TABLE: the name of the datastore table the item is to be put into;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  SIZE: the maximum number of characters (or 0 for numeric data)
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  UNLIKELY: data conditions that are unlikely or "" if not applicable;
#  TOTAL: the total for all values (e.g. 1) or "" if not applicable;
#  DESCRIPTION: the description of each data item.

#Get: Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#  NAME: the name of the dataset to be loaded;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable.

#Set: Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#  NAME: the name of the data item that is to be saved;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  SIZE: the maximum number of characters (or 0 for numeric data).

#Define the data specifications
#------------------------------
CreateBaseSyntheticFirmsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "Employment",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Business",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME = "county",
      FILE = "azone_employment_by_naics.csv",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "county",
      DESCRIPTION = "Name of the county.",
      NAVALUE = "",
      SIZE = 50,
      PROHIBIT = "",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    ),
    item(
      NAME = "year",
      FILE = "azone_employment_by_naics.csv",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "year",
      DESCRIPTION = "The year in which the data was collected.",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = "",
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    ),
    item(
      NAME = "naics",
      FILE = "azone_employment_by_naics.csv",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "naics",
      DESCRIPTION = "The six digit naics code.",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    ),
    item(
      NAME =
        items("emp",
              "est",
              "n1_4",
              "n5_9",
              "n10_19",
              "n20_49",
              "n50_99",
              "n100_249",
              "n250_499",
              "n500_999",
              "n1000",
              "n1000_1",
              "n1000_2",
              "n1000_3",
              "n1000_4"),
      FILE = "azone_employment_by_naics.csv",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "employees",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items("Total number of employees",
                          "Total number of establishments",
                          "Total number of establishments with 1-4 employees",
                          "Total number of establishments with 5-9 employees",
                          "Total number of establishments with 10-19 employees",
                          "Total number of establishments with 20-49 employees",
                          "Total number of establishments with 50-99 employees",
                          "Total number of establishments with 100-249 employees",
                          "Total number of establishments with 250-499 employees",
                          "Total number of establishments with 500-999 employees",
                          "Total number of establishments with 1,000-9,999 employees",
                          "Total number of establishments with 10,000-99,999 employees",
                          "Total number of establishments with 100,000-999,999 employees",
                          "Total number of establishments with 1,000,000-9,999,999 employees",
                          "Total number of establishments with 10,000,000+ employees")
    )
  ), #end Inp
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "county",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "county",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "year",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "year",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "naics",
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "naics",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("emp",
              "est",
              "n1_4",
              "n5_9",
              "n10_19",
              "n20_49",
              "n50_99",
              "n100_249",
              "n250_499",
              "n500_999",
              "n1000",
              "n1000_1",
              "n1000_2",
              "n1000_3",
              "n1000_4"),
      TABLE = "Employment",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "employees",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ), #end Get
  #Specify data to be saved in the data store
  Set = items(
    item(
      NAME = "naics",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "naics",
      DESCRIPTION = "The six digit naics code.",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "esizecat",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "category",
      DESCRIPTION = "The employment size category",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "numbus",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "businesses",
      DESCRIPTION = "The number of businesses.",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "emp",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "employees",
      DESCRIPTION = "The number of employees in a business.",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  ) #end SET

) #end CreateBaseSyntheticFirmsSpecifications list

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateBaseSyntheticFirms module
#'
#' A list containing specifications for the CreateBaseSyntheticFirms module.
#'
#' @format A list containing 6 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{NewInpTable}{new table to be created for datasets specified in the
#'  'Inp' specifications}
#'  \item{NewSetTable}{new table to be created for datasets specified in the
#'  'Set' specifications}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateBaseSyntheticFirms.R script.
"CreateBaseSyntheticFirmsSpecifications"
usethis::use_data(CreateBaseSyntheticFirmsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateBaseSyntheticFirms". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#Function that creates biz table
#------------------------------------------
#' Create biz table
#'
#' \code{createBiz} Take the list of businesses by industry and employee size, reshape it
#'  to a long table with rows for each combination of industry and employee size, expand
#'  the list out so there is a row per business
#'
#' @param Biz_IsEs A list of business by industry and employee size
#' @return A list
#' @name createBiz
#' @import reshape
#' @export
createBiz <- function(Biz_IsEs) {
  BizList_IsEs <- melt(Biz_IsEs[, -c(1, 3:4, 13)], id.vars = c("naics"))
  names(BizList_IsEs)[which(names(BizList_IsEs) == "variable")] <- "esizecat"
  names(BizList_IsEs)[which(names(BizList_IsEs) == "value")] <- "numbus"
  BizList_IsEs <- BizList_IsEs[rep(seq_len(nrow(BizList_IsEs)), BizList_IsEs$numbus), ]
  list(BizList_IsEs[sample(1:nrow(BizList_IsEs), nrow(BizList_IsEs), replace = FALSE), ])
}

#This module has a main function, CreateBaseSyntheticFirms. This function creates SynBiz.IsEs.

#Function that creates simulated businesses in the base year
#-----------------------------------------------------------
#' Creates a set of simulated businesses
#'
#' \code{CreateBaseSyntheticFirms} creates a set of simulated businesses
#'
#' @param L A list
#' @return A list
#' @name CreateBaseSyntheticFirms
#' @import visioneval stats
#' @export
CreateBaseSyntheticFirms <- function(L) {
  #Convert employment data into data frame
  Cbp_df <- data.frame(L$Global$Employment, stringsAsFactors = FALSE)
  #fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Create synthetic businesses for the region
  yr <- as.numeric(L$G$Year)
  SynBiz_df <- createBiz(Cbp_df[Cbp_df$year == yr,-2])[[1]]
  #Assign a specific employment amount to each business
  SizeMinMax_mx <-
    matrix(
      c(1,4,5,9,10,19,20,49,50,99,100,249,250,499,500,999,1000,1499,1500,2499,2500,4999,5000,9999),
      nrow = 12,
      ncol = 2,
      byrow = TRUE,
      dimnames = list(
        levels(SynBiz_df$esizecat),
        c("sizemin", "sizemax")
      )
    )
  Draws_ <- runif(nrow(SynBiz_df))
  SynBizSize_mx <- SizeMinMax_mx[SynBiz_df$esizecat,]
  SynBiz_df$emp <-
    SynBizSize_mx[, "sizemin"] + round(Draws_ * (SynBizSize_mx[, "sizemax"] - SynBizSize_mx[, "sizemin"]), 0)
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Business <-
    list(
      naics = SynBiz_df$naics,
      esizecat = as.integer(SynBiz_df$esizecat),
      numbus = SynBiz_df$numbus,
      emp = as.integer(SynBiz_df$emp)
    )
  #Calculate LENGTH attribute for Business table
  attributes(Out_ls$Year$Business)$LENGTH <-
    length(Out_ls$Year$Business$naics)
  #Return the result
  Out_ls
} #end CreateBaseSyntheticFirms
