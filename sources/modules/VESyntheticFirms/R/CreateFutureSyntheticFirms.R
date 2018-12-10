#============================
#CreateFutureSyntheticFirms.R
#============================

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
#  TOTAL: the total for all values (e.g. 1) or "" if not applicable.

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
CreateFutureSyntheticFirmsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Business",
      GROUP = "Year"
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "EmploymentGrowth",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "naics",
      TABLE = "Business",
      GROUP = "BaseYear",
      TYPE = "integer",
      UNITS = "naics",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "esizecat",
      TABLE = "Business",
      GROUP = "BaseYear",
      TYPE = "integer",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "numbus",
      TABLE = "Business",
      GROUP = "BaseYear",
      TYPE = "integer",
      UNITS = "businesses",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "emp",
      TABLE = "Business",
      GROUP = "BaseYear",
      TYPE = "integer",
      UNITS = "employees",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ), #end GET
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
      DESCRIPTION = "The employment size category.",
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

) #end CreateFutureSyntheticFirmsSpecifications list

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateFutureSyntheticFirms module
#'
#' A list containing specifications for the CreateFutureSyntheticFirms module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{NewSetTable}{new table to be created for datasets specified in the
#'  'Set' specifications}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateFutureSyntheticFirms.R script.
"CreateFutureSyntheticFirmsSpecifications"
usethis::use_data(CreateFutureSyntheticFirmsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#Functions defined in this section of the script implement the submodel. One of
#these functions is the main function that is called by the software framework.
#That function may call other functions. The main function is assigned the
#same name as the module. In this case it is "CreateBaseSyntheticFirms". The main
#function returns a list containing all the data that are to be saved in the
#datastore. Those data must conform with the module specifications.

#Function that creates simulated businesses in the future year
#-------------------------------------------------------------
#' Creates a set of simulated businesses
#'
#' \code{CreateFutureSyntheticFirms} creates a set of simulated businesses
#'
#' @param L A list
#' @return A list
#' @import visioneval stats
#' @export
CreateFutureSyntheticFirms <- function(L) {
  #Load the employment growth factor
  EmploymentGrowth <- L$Global$Model$EmploymentGrowth
  #Convert base year business list into data frame
  SynBiz_df <- data.frame(L$BaseYear$Business, stringsAsFactors = FALSE)
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Sample to either create extra businesses if there is growth or
  #select businesses to keep if there is decline
  if (EmploymentGrowth > 1) { #there is growth
    NewBiz <- nrow(SynBiz_df) * (EmploymentGrowth - 1)
    SynBizNew_ <-
      sample(row.names(SynBiz_df), NewBiz, replace = TRUE)
    SynBiz_df <-
      rbind(SynBiz_df, SynBiz_df[SynBizNew_,])
    rm(SynBizNew_)
  } else { #there is decline
    RemainingBiz <-
      round(nrow(SynBiz_df) * EmploymentGrowth, 0)
    SynBizRemaining_ <-
      sample(row.names(SynBiz_df), RemainingBiz, replace = FALSE)
    SynBiz_df <- SynBiz_df[SynBizRemaining_,]
    rm(SynBizRemaining_)
  }
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
} #end CreateFutureSyntheticFirms
