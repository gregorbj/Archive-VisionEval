#==============
#test_modules.R
#==============

#This script demonstrates how modules are tested. For each module, a list is
#created which contains the needed module input data. By convention, this list
#is named "L". If the module has a "RunBy" specification that is not "Region",
#in other words if the module is run in units of geography (e.g. Marea), then
#the input list needs to be split by the subject unit of geography and the
#module needs to be applied by the subject unit of geography. The code for
#running the "CreateBzoneDev" module shows how this can be done.

#The test data is stored in the "tests/data" directory. In this example, the
#modules are run in the order in which they will be executed in a model. This
#greatly reduces the amount of data that needs to be placed in the "tests/data"
#directory. The first module (CreateHouseholds) uses data in the "tests/data"
#directory. The second module (CreateBzones) uses data returned by the
#CreateHouseholds module. The third module (CreateBzoneDev) uses data returned
#by the CreateBzones module and data in the "tests/data" directory.

#After the test data is loaded from the "tests/data" directory each module is
#tested in sequence. Testing a module is done in 3 steps. First, a list
#containing the input data for the module is created. Second, the "testModule"
#function is called to run the module and check that the outputs meet all the
#output specifications declared for the module. The arguments for the
#"testModule" function are the name of the module (as a quoted string) and the
#input list. The return value of this function is assigned to a variable so that
#the outputs may be used in testing the next module. Third, the "hasErrors"
#function is called to check whether the results of the module test contain any
#error messages. If there are any error messages, execution stops and the error
#messages are displayed in the console. Otherwise execution proceeds to test
#the next module.

library(visioneval)

#Load geography data
#-------------------
#Relationship between Azones and Mareas
AzoneGeo_df <- read.csv("data/azone_geo.csv", as.is = TRUE)

#Test the CreateHouseholds Module
#--------------------------------
#1) Create the list of inputs for testing module
AzonePop_df <- read.csv("data/azone_population.csv", as.is = TRUE) #Scenario inputs
L <- list(Azone = AzonePop_df$Azone, Population = AzonePop_df$Population)
#2) Run the module check
CreateHouseholdsCheck_ls <- testModule("CreateHouseholds", L,
                                       CreateHouseholdsSpecifications)
#3) Check whether any specifications errors exist
hasErrors(CreateHouseholdsCheck_ls)

#Test the CreateBzones Module
#----------------------------
#1) Create list of inputs for testing module
DevTypeProportions_df <- read.csv("data/devtype_proportions.csv", as.is = TRUE) #Scenario inputs
L <- list(NumHh = CreateHouseholdsCheck_ls$Results$NumHh,
          Azone = AzoneGeo_df$Azone,
          Marea = AzoneGeo_df$Marea,
          Metropolitan = DevTypeProportions_df$Metropolitan,
          Town = DevTypeProportions_df$Town,
          Rural = DevTypeProportions_df$Rural)
#2) Run the module check
CreateBzonesCheck_ls <- testModule("CreateBzones", L, CreateBzonesSpecifications)
#3) Check whether any specifications errors exist
hasErrors(CreateBzonesCheck_ls)

#Check the CreateBzoneDev Module
#-------------------------------
#This module is "RunBy" Marea so the inputs list needs to be split into a
#separate component for each Marea. The "lapply" function is then used to
#apply the "testModule" function to each component of the inputs list. The
#output is also a list where each component is the test result for the
#corresponding component of the input list. The "lapply" function is used to
#check whether any of the components of the test result list have errors.
#1) Create datasets for testing module
MareaArea_df <- read.csv("tests/data/marea_area.csv") #Scenario inputs
L <- data.frame(Bzone = CreateBzonesCheck_ls$Results$Bzone,
                DevType = CreateBzonesCheck_ls$Results$DevType,
                NumHh = CreateBzonesCheck_ls$Results$NumHh,
                stringsAsFactors = FALSE)
L <- split(L, CreateBzonesCheck_ls$Results$Marea)
L <- lapply(L, function(x) as.list(x))
for (name in names(L)) {
  L[[name]]$Marea <- name
  L[[name]]$Area <- MareaArea_df$Area[MareaArea_df$Marea == name]
}
#2) Run the module check
CreateBzoneDevCheck_ls <- lapply(L, function(x) {
  testModule("CreateBzoneDev", x, CreateBzoneDevSpecifications)})
#3) Check whether any specifications errors exist
lapply(CreateBzoneDevCheck_ls, function(x) hasErrors(x))

