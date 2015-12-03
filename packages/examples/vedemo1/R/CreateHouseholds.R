#==================
#CreateHouseholds.R
#==================

#This demonstration module creates simulated households for a model where
#geography is minimally specified, i.e. where only Azones and Mareas are
#specified. Simulated households are created using a household size distribution
#for the model area and Azone populations. The module creates a dataset of
#household sizes. A 'Households' table is initialized and populated with the
#household size dataset. Azone locations and household IDs are also added to the
#Household table.

#utility functions
# items <- function(...) {
#   list(...)
# }
# item <- function(...){
#   list(...)
# }
library(visioneval)

#===================================================================
#SECTION 1: DEFINE ALL THE FUNCTIONS THAT WILL BE PART OF THE MODULE
#===================================================================
#Functions defined in this section of the script implement the module model(s).
#They are run when the module is run. Notice that these functions do not take
#any arguments. That is because the functions refer to data that is part of the
#module environment or will be loaded into the module environment by the
#framework when the module is run. Also notice that the functions assign the
#results to the module environment, rather than returning them to the calling
#environment. This is important so that a module function can use the results of
#another module function, and so that the framework can save results that are
#specified in the module's 'Set' component to the datastore.

#This module contains one function, createHouseholds. This function creates
#household-level datasets for household size (HhSize), household ID (HhId), and
#Azone (Azone). It uses a dataframe of household size proportions and Azone
#populations in carrying out the calculations. The dataframe of household size
#proportions is a model parameter that is calculated using the 'calcHhSizeProp'
#function defined in the next section of this script. A vector of Azone
#populations is a scenario input.

#Function that creates simulated households
#------------------------------------------
#This function creates a dataset of simulated household sizes (HhSize). It also
#creates a dataset of household IDs (HhId) and the Azones (Azone) the households
#are assigned to. These are assigned to the module environment. Since the
#household table does not exist, the function calculates a LENGTH value for the
#table and assigns it to the module environment as well. The framework uses this
#information to initialize the Households table. The function also computes the
#maximum numbers of characters in the HhId and Azone datasets and assigns these
#to a SIZE vector in the module environment. This is necessary so that the
#framework can initialize these datasets in the Datastore.
createHouseholds <- function() {
  #Calculate average household size
  AveHhSize <- sum(HhSizeProp_df$Size * HhSizeProp_df$Proportion)
  #Define function to simulate households in a population
  SimHh <- function(Pop, AveHhSize) {
    InitNumHh <- ceiling(Pop / AveHhSize) + 100
    InitHh_ <-
      sample(HhSizeProp_df$Size, InitNumHh, replace = TRUE,
             prob = HhSizeProp_df$Proportion)
    Error_ <- abs(cumsum(InitHh_) - Pop)
    Hh_ <- InitHh_[1:(which(Error_ == min(Error_)))[1]]
    if (sum(Hh_) < Pop) {
      Hh_ <- c(Hh_, Pop - sum(Hh_))
    }
    if (sum(Hh_) > Pop) {
      PopDiff <- sum(Hh_) - Pop
      Hh_ <- Hh_[-which(Hh_ == PopDiff)[1]]
    }
    Hh_
  }
  #Create household sizes of households for all Azones and put in list
  HhSize_ls <- list()
  for (i in 1:length(Azone)) {
    Az <- Azone[i]
    Pop <- Population[i]
    HhSize_ls[[Az]] <- SimHh(Pop, AveHhSize)
  }
  #Create vector of household IDs
  HhId_ <- unlist(sapply(names(HhSize_ls),
                         function(x) paste(x, 1:length(HhSize_ls[[x]]), sep = "")),
                  use.names = FALSE)
  #Assign the household size vector
  assign("HhSize", unlist(HhSize_ls, use.names = FALSE), envir = Module)
  #Assign the corresponding vector of Azone names to Module environment
  assign("Azone", rep(Azone, unlist(lapply(HhSize_ls, length))), envir = Module)
  #Make and assign vector of household ID
  assign("HhId", HhId_, envir = Module)
  #Calculate and assign number of households by Azone
  assign("NumHh", unlist(lapply(HhSize_ls, length), use.names = FALSE), envir = Module)
  #Calculate and assign the total number of households
  #Note use this pattern for returning calculated LENGTH attribute
  LENGTH <- numeric(0)
  LENGTH["Household"] <- sum(sapply(HhSize_ls, length))
  assign("LENGTH", LENGTH, envir = Module)
  #Calculate and assign SIZE attributes for 'Azone' and 'HhId'
  #Note use this pattern for returning calculated SIZE attribute
  SIZE <- numeric(0)
  SIZE["Azone"] <- max(nchar(Azone))
  SIZE["HhId"] <- max(nchar(HhId_))
  assign("SIZE", SIZE, envir = Module)
}

#===================================
#SECTION 2: DEFINE MODULE PARAMETERS
#===================================
#Functions and statements in this section of the script define all of the
#parameters used by the module. Parameters are module inputs that are constant
#for all model runs. Parameters can be put in whatever form that the module
#developer determines works best (e.g. vector, matrix, array, data frame, list,
#etc.). Parameters may be defined in several ways including: 1. By statements
#included in this section (e.g. HhSize <- 2.5); 2. By reading in a data file
#from the "inst/extdata" directory; and, 3. By applying a function which
#estimates the parameters using data in the "inst/extdata" directory.

#This module demo shows how a function can be used to estimate parameters. When
#this approach is used, all input data for parameter estimation must be placed
#in the "inst/extdata" directory of the package. The function is written to load
#the data into a suitable data structure and that is then used to estimate the
#needed parameters. This approach enables model builders to substitute regional
#data for the default data that comes with the package. The source of the
#default data is documented in the "inst/extdata" directory. The module vignette
#describes how regional data can be substituted for default data. When the
#package is built, the module will include regionally estimated parameters. The
#example below is a trivial one which reads in a file of numbers of households
#by household size and calculates he proportions of households by household
#size. Most of the function is error checking.

#Estimate household size proportion parameters
#---------------------------------------------
calcHhSizeProp <- function() {
  FileName <- "household_sizes.csv"
  FilePath <- file.path("inst/extdata", FileName)
  Errors_ <- character(0)
  if (!file.exists(FilePath)) {
    Message <- paste0(
      "File ", FileName, " is not present in the 'inst/extdata' directory."
      )
    Errors_ <- c(Errors_, Message)
  } else {
    HhSizes_df <- read.csv(FilePath, as.is = TRUE)
    if (!all.equal(names(HhSizes_df), c("Size", "Number"))) {
      Message <- paste0(
        "Column names of file ", FileName, " are not correct."
      )
      Errors_ <- c(Errors_, Message)
    }
    if (!all(HhSizes_df$Size %in% 1:7)) {
      Message <- "Some values in the Size column are not correct."
      Errors_ <- c(Errors_, Message)
    }
    if (typeof(HhSizes_df$Number) != "integer") {
      Message <- "Some values in the Number column are not correct."
    }
  }
  if (length(Errors_) != 0) {
    Message <- paste( paste(Errors_, collapse = " "),
                      "Check module documentation.")
    stop(Message)
  } else {
    Proportion <- HhSizes_df$Number / sum(HhSizes_df$Number)
    HhSizeProp_df <- data.frame(Size = HhSizes_df$Size,
                                Proportion = Proportion)
  }
  HhSizeProp_df
}


#==============================
#SECTION 3: BUILDING THE MODULE
#==============================
#There are two steps to building a module. The first step is to define a
#'buildModule' function that, when run, creates an environment that contains all
#components needed by the framework to run the module. The second step runs the
#buildModule function and assigns the resulting environment to an object named
#'CreateHouseholdModule'. Then a function named 'CreateHousehold' is defined that
#returns this environment object when it is called. It is this function that is
#exported.
#
#The buildModule function does the following 10 things in order to create a
#proper module environment:
#1. Creates an environment named 'Module'.
#2. Assigns the name of the module to the environment.
#3. Assigns the functions that implement the module to the environment .
#4. Defines a function named 'main' which calls each of the module functions in
#the order in which they need to be called when the module is run.
#5. Assigns all the module parameters to the environment.
#6. Identifies the level of geography over at which the module is to be applied.
#7. Identifies scenario inputs that are to be read from files and loaded into
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
#  TOTAL: the total for all values (e.g. 1) or NA if not applicable.
#8. Identifies data to be loaded from the datastore. The
#following need to be specified for every data item:
#  NAME: the name of the dataset to be loaded;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable.
#9. Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#  NAME: the name of the data item that is to be saved;
#  TABLE: the name of the table that the dataset is a part of;
#  TYPE: the data type (i.e. double, integer, character, logical);
#  UNITS: the measurement units for the data;
#  NAVALUE: the value used to represent NA in the datastore;
#  PROHIBIT: data conditions that are prohibited or "" if not applicable;
#  ISELEMENTOF: allowed categorical data values or "" if not applicable;
#  SIZE: the maximum number of characters (or 0 for numeric data).
#10. Return the Module object

#Define the buildModule() function
#---------------------------------
#' Build the module.
#'
#' \code{buildModule} builds the module that will carry out the demo models.
#'
#' This function builds the module when it is run. The module is created as an
#' environment which contains all of the necessary elements.
buildModule <- function() {
  #1. Create an environment to hold the module components
  Module <- new.env()
  #2. Module name
  #<Replace with the name of your module.>
  Module$Name <- "CreateHouseholds"
  #3. Add functions and assign their environments to be 'Module'
  Module$createHouseholds <- createHouseholds
  environment(Module$createHouseholds) <- Module
  #4. Define a main function which calls the other functions.
  Module$main <- function() {
    Module$createHouseholds()
  }
  #5. Assigns model parameters
  Module$HhSizeProp_df <- calcHhSizeProp()
  #6. Identify the level of geography that is iterated over when running the module
  Module$RunBy <- "All"
  #7. Identify scenario input file specifications
  Module$Inp <- items(
    item(
      NAME = "Population",
      FILE = "azone_population.csv",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = NA
    )
  )
  #8. Identify data to be loaded from data store
  Module$Get <- items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      TYPE = "character",
      UNITS = "none",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Population",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    )
  )
  #9. Identify data to store
  Module$Set <- items(
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      TYPE = "integer",
      UNITS = "households",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME = "HhId",
      TABLE = "Household",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Azone",
      TABLE = "Household",
      TYPE = "character",
      UNITS = "none",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
  #10. Return the Module object
  Module
}

#Run the buildModule function
#----------------------------
CreateHouseholdModule <- buildModule()
#' Build the module.
#'
#' \code{CreateHouseholds} builds the module that will carry out the demo models.
#'
#' This function builds the module when it is run. The module is created as an
#' environment which contains all of the necessary elements.
#' @export
CreateHouseholds <- function() {
  CreateHouseholdModule
}
