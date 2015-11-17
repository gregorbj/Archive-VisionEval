#=============
#demo_module.r
#=============

#The R package building process runs all of the scripts in the "R" directory
#when the package is built. Each module that will be included in the package is
#created by a script like this one. The script is organized in 3 sections which
#carry out the essential tasks that must be accomplished in order to produce a
#module for the VisionEval framework. They are as follows:

#Section 1 - This section defines all functions that will be called when the
#module is run. There are a couple of things that are important to recognize
#about these functions. First, because they will be invoked within an
#environment created by the VisionEval framework, the results of the function
#are not returned in the customary way. Instead, they are assigned to the
#"Module" environment. The module will only work if the results are returned in
#this way. Second, because all the inputs needed by these functions will either
#be contained within the module, loaded by the framework in accordance with the
#module specifications, or be intermediate results returned by a module
#function, the functions should not have any arguments. All function inputs
#should be parameters or inputs specified by the "Get" components (see section
#3) of the module definition.

#Section 2 - Functions and statements in this section define all of the
#parameters used by the module. Parameters are module inputs that are constant
#for all model runs. Parameters can be put in whatever form that the module
#developer determines works best (e.g. vector, matrix, array, data frame, list,
#etc.) Parameters may be defined by simple assignment statements or by more
#complex calculations that are wrapped in functions. The latter is particularly
#the case when region-specific parameters need to be calculated for the region
#for which the module is to be applied. For example, a vehicle age distribution
#might be calculated using vehicle age data gathered for the state that the
#model is being built for. All datasets that are used to calculate parameters
#(and not defined directly in this script) must be put in the the "inst/extdata"
#directory of the package. The module vignette must include descriptions of
#these datasets and also must include instructions on any changes that need to be
#made in order to estimate parameters for the region where the model is to be
#applied.

#Section 3 - This section defines a module that builds the module and
#saves the results.

#utility functions

items <- function(...) {
  list(...)
}

item <- function(...){
  list(...)
}


#===================================================================
#SECTION 1: DEFINE ALL THE FUNCTIONS THAT WILL BE PART OF THE MODULE
#===================================================================
#The functions defined in this section are functions that run when the module is
#run. There are two types of functions that can be included: 1) A function that
#will return an intermediate result that is used by other functions in the
#module. These functions can return any type of R data structure (e.g. vector,
#matrix, list, data frame, etc.). These functions are not intended to return
#results to be saved in the model datastore. 2) Functions that will return a
#result that will be saved in the model datastore. These functions can only
#return vector or matrix (Note that scalars in R are vectors of length 1).

#It is very important to note is that unlike most R functions, you do not return
#a value to the calling environment. Instead, you explicitly assign the return
#value to the "Module" environment. In addition, because all the inputs to the
#function are either parameters that are included in the module, are data that
#are loaded into the execution environment from the datastore based on module
#specifications, or are intermediate results returned to the execution
#environment by module functions, the function should not have any formal
#arguments. However, even though there are no formal arguments, the function
#documentation should include documentation of all function inputs as though
#they were function arguments.

#Demo function that returns an intermediate calculation result
#-------------------------------------------------------------
#' Demo Function <Replace this with a title for the function.>
#' 
#' This shows how a function to be included in a module would be defined and
#' documented <Replace this with a short description of the function.>
#'
#' This demo function shows the basic structure and formatting of a function and
#' documentation. This is a function that returns a result that other functions
#' in the module use and is not saved to the datastore. Note that the return
#' value is not return in the normal way for functions. Instead it is assigned
#' to a name in the Module environment. Also note that in the documentation
#' section that this function is not exported. This means that the function can
#' not be called directly by package users. It is not necessary for users
#' because the copy that is included in the module will be called
#' instead.<Replace this with a detailed description of the function and how it
#' is used.>
#' 
#' @param MyArg1 a numeric value that means nothing <Replace with the name of
#'   the first argument, its type and a description.>
#' @param <Do the same thing for every other function argument.>
#' @return A list with two string values. <Describe the tyupe and meaning of the
#'   return value of the function.
demo1 <- function() {
  #Do calculations
  MyIntermediateResult <- list(Input1, Input2)
  #Return the result. This is a result used by other module functions, not to be
  #saved in the datastore. Results are returned as follows.
  assign("MyIntermediateResult", MyIntermediateResult, envir = Module)
}

#Demo function 2
#---------------
#' Demo Function <Replace this with a title for the function.>
#' 
#' \code{demo2} a demo function <Replace this with a very short description of 
#' the function.>
#' 
#' This demo function shows the basic structure and formatting of a function and
#' documentation. This is a function that returns a result that is saved to the
#' datastore.<Replace this with a longer description of the function.>
#' 
#' @param MyArg1 a numeric value that means nothing <Replace with the name of
#'   the first argument, its type, and a description.>
#' @param <Do the same thing for every other function argument.>
#' @return A string vector. <Describe the type and meaning of
#'   the return value of the function.>
#'   
demo2 <- function() {
  #Do calculations
  MyFinalResult <- c(Input1, Input2)
  #Return the result. This is a result that will be saved in the datastore.
  #Results are returned as follows. Note that the data type is explicitly set.
  #This needs to match the type declared in the module for this data item (see
  #section 3).
  storage.mode(MyFinalResult) <- "double"
  assign("MyFinalResult", MyFinalResult, envir = Module)
}

#===================================
#SECTION 2: DEFINE MODULE PARAMETERS
#===================================
#Functions and statements in this section define all of the parameters used by
#the module. Parameters are module inputs that are constant for all model runs.
#Parameters can be put in whatever form that the module developer determines works
#best (e.g. vector, matrix, array, data frame, list, etc.). The parameter
#examples below include single numbers that are hard-coded in the script, a
#matrix of values that are read from a data file and assigned, and a string
#representation of a model that is estimated from data that is read in from a
#file. The latter are possible examples of how parameters that are specific to a
#region might be calculated. All datasets that are used to calculate parameters
#must be put in the "inst/extdata"directory of the package. The module
#vignette must include descriptions of these datasets and also must include
#instructions on any changes that need to be made to the datasets in order to
#estimate parameters for the region where the model is to be applied. NOTE: when
#you read in data from a file, it is important to recognize that the default
#behavior of read.table and read.csv is to convert strings into factors.
#Although you may have set the 'stringsAsFactors' option on your system to FALSE
#to stop this from happening, you should not assume that others who will be 
#building a binary package will have done so as well. Therefore always set the
#'as.is' argument equal to TRUE or use the 'colClasses' argument to specify the
#data types.

#Example of simple parameters that are hard-coded in the script
#--------------------------------------------------------------
BazRate <- 0.85
BarFactor <- 1.4

#Example of parameters read in from a file
#-----------------------------------------
BazAges_df <- read.csv("inst/extdata/baz_age_data.csv")

#Example of parameters estimated from data read in from a file
#-------------------------------------------------------------
estimateFoobarModel <- function() {
  Foobar_df <- read.csv("inst/extdata/foobar_data.csv", as.is=TRUE)
  Foobar_LM <- lm(bar ~ foo, data = Foobar_df)
  makeModelString <- function(Model_LM) {
    ModelCoeff_vc <- coefficients(Model_LM)
    InterceptIdx <- which(names(ModelCoeff_vc) == "(Intercept)")
    ModelString <- paste(paste(names(ModelCoeff_vc)[-InterceptIdx],
                               ModelCoeff_vc[-InterceptIdx], sep = " * "),
                         collapse = " + ")
    ModelString <- paste(ModelCoeff_vc[InterceptIdx], ModelString, sep = " + ")
    ModelString
  }
  makeModelString(Foobar_LM)
}
FooBarModel <- estimateFoobarModel()

#==============================
#SECTION 3: BUILDING THE MODULE
#==============================
#There are two steps to building a module. The first is to define a
#'buildModule' function. The second is to invoke the function and assign the
#result to the module name.

#The buildModule function defines an environment that does the following 10
#things: 

#1. Create an environment named 'Module'. 

#2. Assigns the name of the module.

#3. Assigns the functions that implement the module to the environment .

#4. Defines a function named 'main' which calls each of the module functions in
#the order in which they need to be called when the module is run.

#5. Assigns all the module parameters to the environment.

#6. Identifies the level of geography over at which the module is to be applied.
#The framework iterates over each each unit of the designated geographic level,
#loads the corresponding data from the datastore, runs the module, and saves the
#result(s) to the datastore. The level of geography may be chosen because the
#model was meant to run at that level of geography (e.g. congestion model runs
#at the metropolitan level). It may also be chosen to limit the size of data
#loaded into memory.

#7. Identifies scenario inputs that are to be read from files and loaded into
#the datastore. Most modules will be developed in order to evaluate the
#consequences of some policy scenario (e.g. parking pricing) or other future
#condition (e.g. fuel prices). The data specifying the policy/condition values
#corresponding to a scenario are the scenario inputs. This section of the
#buildModule function provides all of the specifications for proper inputs. The
#framework uses these specifications to read in the data, check it for
#correctness, and save it to the datastore. The data the module needs is then
#reloaded from the datastore into the execution environment where it can be used
#by the module. The following need to be specified for every data item (i.e.
#column in a table):
#NAME: the name for the data item in the input table and which will be used in
#the datastore
#FILE: the name of the file that contains the table
#GEO: the level of geography at which the values are specified
#TYPE: the data type (i.e. double, integer, character, logical)
#UNITS: the measurement units for the data (e.g. miles, acres, gallons, etc.)
#NAVALUE: the value that is to be used to represent NA when the data are saved
#in the datastore
#PROHIBIT: a vector specifying continuous data conditions that are prohibited or
#NULL (see developers guide)
#ISELEMENTOF: a vector specifying categorical data values that are allowed or
#NULL (see developers guide)
#UNLIKELY: a vector specifying continuous data conditions that are unlikely to
#occur or NULL (see developers guide)
#TOTAL: the total for all values or NULL (typically used if the inputs are
#proportions or percentages that must add up to 1 or 100)

#8. Identifies data to be loaded from the datastore. The data loaded from the
#datastore includes scenario input data that was put there by the framework
#using the input specifications, and data produced by other modules. The
#following need to be specified for every data item:
#NAME: the name of the dataset to be loaded 
#TABLE: the name of the table that the dataset is a part of
#TYPE: the data type (i.e. double, integer, character, logical)
#UNITS: the measurement units for the data (e.g. miles, acres, gallons, etc.)
#PROHIBIT: a vector specifying continuous data conditions that are prohibited or 
#NULL (see developers guide)     
#ISELEMENTOF: a vector specifying categorical data values that are allowed or
#NULL (see developers guide)

#9. Identifies data that is produced by the module that is to be saved in the
#datastore. The following need to be specified for every data item:
#NAME: the name of the data item that is to be saved. This is also the name that
#the dataset will be stored under in the datastore
#TABLE: the name of the table in the datastore that the dataset will be made a
#part of
#TYPE: the data type (i.e. double, integer, character, logical)
#UNITS: the measurement units for the data (e.g. miles, acres, gallons, etc.)
#NAVALUE: the value that is to be used to represent NA when the data are saved
#in the datastore
#PROHIBIT: a vector specifying continuous data conditions that are prohibited or 
#NULL (see developers guide)  
#ISELEMENTOF: a vector specifying categorical data values that are allowed or
#NULL (see developers guide)
#SIZE = if the TYPE is character, then the maximum number of characters in an
#entry needs to be specified. Enter 0 for non-character data.

#Define the buildModule() function
#---------------------------------
#' Build the module.
#' 
#' \code{buildModule} builds the module that will carry out the demo models.
#' 
#' This function builds the demo module that simulates foobar behavior. This is done by creating an
#' environment in which the functions, parameters and specifications are
#' assigned as described above.
buildModule <- function() {
  #1. Create an environment to hold the module components
  Module <- new.env()
  #2. Module name 
  #<Replace with the name of your module.>
  Module$Name <- "Demo"
  #3. Add functions and assign their environments to be 'Module'
  #<Replace with your functions.>
  Module$demo1 <- demo1
  environment(Module$demo1) <- Module
  Module$demo2 <- demo2
  environment(Module$demo2) <- Module
  #4. Define a main function which calls the other functions.
  #<Replace with your functions. Note must be in the calling order.>
  Module$main <- function() {
    Module$demo1()
    Module$demo2()
  }
  #5. Assigns model parameters
  #<Replace with the parameters for your module.>
  Module$BazRate <- BazRate
  Module$BarFactor <- BarFactor
  Module$BazAges_df <- BazAges_df
  Module$FooBarModel <- FooBarModel
  #6. Identify the level of geography that is iterated over when running the module
  Module$RunBy <- "Azone"
  #7. Identify scenario input file specifications
  Module$Inp <- items(
    item(
         NAME = "BeBopProp",
         FILE = "dodad.csv",
         GEO = "Azone",
         TYPE = "double",
         UNITS = "None",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0", "> 1"),
         ISELEMENTOF = NULL,
         UNLIKELY = NULL,
         TOTAL = 1
        ),
    item(
         NAME = "BoPeepSheep",
         FILE = "dodad.csv",
         GEO = "Azone",
         TYPE = "integer",
         UNITS = "sheep",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0"),
         ISELEMENTOF = NULL,
         UNLIKELY = c("> 100"),
         TOTAL = NULL
        )
  )       
  #8. Identify data to be loaded from data store
  Module$Get <- items(
    item(
         NAME = "BeBopProp", 
         TABLE = "Azone",
         TYPE = "double",
         UNITS = "None",
         PROHIBIT = c("NA", "< 0", "> 1"),      
         ISELEMENTOF = NULL
    ),
    item(
         NAME = "BoPeepSheep",
         TABLE = "Azone",
         TYPE = "integer",
         UNITS = "sheep",
         PROHIBIT = c("NA", "< 0"),
         ISELEMENTOF = NULL
    ),
    item(
         NAME = "DevType", 
         TABLE = "Bzone",
         TYPE = "character",
         UNITS = "None",
         PROHIBIT = NULL,      
         ISELEMENTOF = c("Baz", "Bar", "Mixed")
    )
  )    
  #9. Identify data to store
  Module$Set <- items(
    item(
         NAME = "NumBar",
         TABLE = "Household",
         TYPE = "double",
         UNITS = "Gallons",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0"),
         ISELEMENTOF = NULL,
         SIZE = 0
        ),
    item(
         NAME = "NumBop",
         TABLE = "Household",
         TYPE = "integer",
         UNITS = "Vehicles",
         NAVALUE = -9999,
         PROHIBIT = c("NA", "< 0", "> 1"),
         ISELEMENTOF = NULL,
         SIZE = 0
        )
  )
  #10. Return the Module object
  Module
}

#Run the buildModule function
#----------------------------
Demo <- buildModule()

#Clean up all other objects because your package only needs the module
#---------------------------------------------------------------------
# rm(demo1, demo2, BazRate, BarFactor, BazAges_df, estimateFoobarModel, 
#    FooBarModel)
