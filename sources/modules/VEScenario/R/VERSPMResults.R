#=================
#VERSPMResults.R
#=================
# This module gathers the output of scenario runs in data.table and returns
# it as a list.

# Copyright [2017] [AASHTO]
# Based in part on works previously copyrighted by the Oregon Department of
# Transportation and made available under the Apache License, Version 2.0 and
# compatible open-source licenses.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# library(visioneval)
# library(data.table)

#=================================================
#SECTION 1: ESTIMATE AND SAVE Scenario PARAMETERS
#=================================================

# Save VERSPM OUTPUT config file

verspm_output_config_txt <-
'[
  {
    "NAME": "GHG Target Reduction",
    "LABEL": "GHG Target Reduction",
    "DESCRIPTION": "Placeholder - 2005-2038 percentage reduction in light-duty vehicle GHG emissions (beyond what is anticipated to occur due to baseline assumptions regarding improvements to vehiles and fuels). RVMPO has a 2005 - 2035 state-set GHG reduction target of 19%",
    "INSTRUCTIONS": "Placeholder - 2005-2038 percentage reduction in light-duty vehicle GHG emissions (beyond what is anticipated to occur due to baseline assumptions regarding improvements to vehiles and fuels). RVMPO has a 2005 - 2035 state-set GHG reduction target of 19%",
    "METRIC": "Average",
    "UNIT": "%",
    "COLUMN": "GHGReduction"
  },
{
    "NAME": "DVMT Per Capita",
  "LABEL": "Daily Vehicle Miles Traveled",
  "DESCRIPTION": "daily vehicle miles of travel of residents divided by population.",
  "INSTRUCTIONS": "daily vehicle miles of travel of residents divided by population.",
  "METRIC": "Average",
  "UNIT": "daily miles",
    "COLUMN": "DVMTPerCapita"
},
{
  "NAME": "Walk Trips Per Capita",
  "LABEL": "Walk Travel Per Capita",
  "DESCRIPTION": "annual residents walk trips (not including recreation or walk to transit) divided by population",
  "INSTRUCTIONS": "annual residents walk trips (not including recreation or walk to transit) divided by population",
  "METRIC": "Average",
  "UNIT": "annual trips",
    "COLUMN": "WalkTravelPerCapita"
  },
{
    "NAME": "Air Pollution Emissions",
  "LABEL": "Air Pollution Emissions",
  "DESCRIPTION": "daily metric tons of pollutants emitted from all light-duty vehicle travel (including hydrocarbons, carbon monoxide, nitrogen dioxide, and particulates).",
  "INSTRUCTIONS": "daily metric tons of pollutants emitted from all light-duty vehicle travel (including hydrocarbons, carbon monoxide, nitrogen dioxide, and particulates).",
  "METRIC": "Average",
  "UNIT": "daily metric tons",
    "COLUMN": "AirPollutionEm"
},
{
    "NAME": "Annual Fuel Use",
  "LABEL": "Annual Fuel Use",
  "DESCRIPTION": "annual million gallons of gasoline and other fuels consumed by all light-duty vehicle travel.",
  "INSTRUCTIONS": "annual million gallons of gasoline and other fuels consumed by all light-duty vehicle travel.",
  "METRIC": "Average",
  "UNIT": "million gallons",
    "COLUMN": "FuelUse"
},
{
    "NAME": "Truck Delay",
  "LABEL": "Truck Delay",
  "DESCRIPTION": "daily vehicle-hours of delay for heavy truck travel on area roads.",
  "INSTRUCTIONS": "daily vehicle-hours of delay for heavy truck travel on area roads.",
  "METRIC": "Average",
  "UNIT": "daily vehicle hr.",
    "COLUMN": "TruckDelay"
},
{
    "NAME": "Household Vehicle Cost as Percentage of Income",
  "LABEL": "Vehicle Cost % (All Income)",
  "DESCRIPTION": "average percentage of income spent by all households on owning and operating light-duty vehicles.",
  "INSTRUCTIONS": "average percentage of income spent by all households on owning and operating light-duty vehicles.",
  "METRIC": "Average",
  "UNIT": "%",
    "COLUMN": "VehicleCost"
},
{
    "NAME": "Low Income Household Vehicle Cost as Percentage of Income",
  "LABEL": "Vehicle Cost % (Low Income)",
  "DESCRIPTION": "average percentage of income spent by low-income (< $20,000 USD2005) households on owning and operating light-duty vehicles.",
  "INSTRUCTIONS": "average percentage of income spent by low-income (< $20,000 USD2005) households on owning and operating light-duty vehicles.",
  "METRIC": "Average",
  "UNIT": "%",
    "COLUMN": "VehicleCostLow"
  }
]'

  VERSPMOutputConfig <- list(
    VERSPM = verspm_output_config_txt
  )
  #Save the config specifications list
  #---------------------------------
  #' Scenario output configurations for VERSPM model
  #'
  #' A list containing output configurations for VERSPM model.
  #'
  #' @format A list containing configuration for models in json format:
  #' \describe{
  #'  \item{VERSPM}{Scenario output configuration for VERSPM model}
  #' }
  #' @source VERSPMResults.R script.
  "VERSPMOutputConfig"
  usethis::use_data(VERSPMOutputConfig, overwrite = TRUE)





#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

VERSPMResultsSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "Tables",
      GROUP = "Global"
    )
  ),
  # Specify new tables to be created by Set if any
  # NewSetTable
  # Specify Input data
  Inp = items(
    item(
      NAME = "Name",
      FILE = "model_tables_to_export.csv",
      TABLE = "Tables",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      SIZE = 20,
      PROHIBIT = "NA",
      ISELMENTOF = "",
      DESCRIPTION = "Name of the tables to export"
    )
  ),
  # Specify data to be loaded from the datastore
  Get = items(
    item(
      NAME = "ScenarioInputFolder",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      SIZE = 20,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ScenarioOutputFolder",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      SIZE = 20,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "NWorkers",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "NA",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Name",
      TABLE = "Tables",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      SIZE = 20,
      PROHIBIT = "NA",
      ISELMENTOF = ""
    ),
    item(
      NAME = "InputLabels",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = "CompleteResult",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = "Returns 1 if completes build"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for VERSPMResults module
#'
#' A list containing specifications for the VERSPMResults module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source VERSPMResults.R script.
"VERSPMResultsSpecifications"
usethis::use_data(VERSPMResultsSpecifications, overwrite = TRUE)


# TableNames <- c("Azone", "Bzone", "Marea", "IncomeGroup", "FuelType")


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

# Module funciton that read tables from specific scenario
# -------------------------------------------------------
#' Function to read tables from given scenario
#' \code{readTables} reads tables from a specified scenario.
#'
#' This function takes scenario name, a list of tables and read them into
#' data.table format and returns a list of data.tables.
#'
#' @param Year A string indicating the year for which the output needs to
#' be obtained.
#' @param Scenario A string for name of the scenario to be read into.
#' @param Output An array of character. If specified as 'All' then
#' all the tables are read in.
#' @param Table A logical indicating whether the 'Output' option contains
#' variable names or table names. Defaults to TRUE indicating table names.
#' @import visioneval
#' @return A data.table containing all the specified tables.

readTables <- function(Year = NULL, Scenario = "Base", Output = "All", Table=TRUE){
  if(is.null(Output)){
    msg <- "No output was selected to export"
    stop(msg)
  }
  if(any(is.na(Output))){
    msg <- "No output was selected to export"
    stop(msg)
  }
  if(!(file.exists("ModelState.Rda") | dir.exists("Datastore"))){
    return(data.table(Scenario=Scenario,
                      Table=NA,
                      Data=NA,
                      Units=NA))
  }
  # Read the model state to gather information
  ModelState_ls <<- readModelState()
  # Define readFromTable Function
  if(ModelState_ls$DatastoreType=="RD"){
    readFromTable <- readFromTableRD
  } else {
    readFromTable <- readFromTableH5
  }
  # Gather Datastore attributes
  DataStoreName <- ModelState_ls$DatastoreName
  DataStore_dt <- data.table(ModelState_ls$Datastore)
  DataStore_dt[,c("Empty", "Group", "Table"):=tstrsplit(group, "/")]
  DataStore_dt <- DataStore_dt[Group!="Global"&!is.na(Table)& Group==Year,
                               .(Group,Table,Name=name,Attributes=attributes)]
  DataStore_dt[,Units:=lapply(Attributes, function(x) x[["UNITS"]]),.(Group,Table,Name)]
  DataStore_dt[,Attributes:=NULL]
  TableNames <- unique(DataStore_dt$Table)
  ColumnToSearch <- "Table"
  if(!Table){
    ColumnToSearch <- "Name"
  }
  if(any(Output=="All")){
    Output <- TableNames
    ColumnToSearch <- "Table"
  }
  FilterDatastore_ar <- DataStore_dt[[ColumnToSearch]] %in% Output
  DataStore_dt <- DataStore_dt[FilterDatastore_ar]
  DataStore_dt[,Value:=.(list(readFromTable(Name,Table,Group))),.(Group,Table,Name,Units)]
  Results_dt <- DataStore_dt[,{
    Outputs_dt <- data.table(data.frame(Value))
    setnames(Outputs_dt,colnames(Outputs_dt),Name)
    Units_ls <- list(Units)
    .(Data=list(Outputs_dt),Units=Units_ls)
  },.(Table)]
  Results_dt[,Scenario:=Scenario]
  return(Results_dt[,.(Scenario, Table, Data, Units)])
}

# Module funciton that read model run results from a scenario directory
# ---------------------------------------------------------------------
#' Function to read all the results from a scenario directory
#' \code{readTables} reads all the model run results from a specified
#' directory.
#'
#' This function takes the model path and returns a data.table containing
#' all the results. The additional arguments are passed to \code{readTables}
#' function.
#'
#' @param ScenarioPath A string identifying the path in which model files are
#' stored.
#' @return A data.table containing all the tables.
getScenarioResults <- function(ScenarioPath, ...){
  currDir <- getwd()
  on.exit(setwd(currDir))
  setwd(ScenarioPath)
  ScenarioName_ <- basename(ScenarioPath)
  ScenarioResult_dt <- readTables(Scenario = ScenarioName_, ...)
  return(ScenarioResult_dt)
}

#Main module function gather scenario results
#------------------------------------------------------------------
#' Function to gather scenario results.
#'
#' \code{VERSPMResults} gather scenario results.
#'
#' This function gather results from scenarios asynchronously.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name VERSPMResults
#' @import jsonlite future data.table
#' @export
VERSPMResults <- function(L){
  # Setup
  # -------------
  # Set input directory
  ModelPath <- getwd()
  ScenariosPath_ar <- list.dirs(file.path(ModelPath,
                                          L$Global$Model$ScenarioOutputFolder),
                                recursive = FALSE)

  # Update the Scenario Progress Report
  Scenarios_df  <- read.csv(file.path(ModelPath,
                                      L$Global$Model$ScenarioOutputFolder,
                                      "ScenarioProgressReport.csv"),
                            stringsAsFactors = FALSE)

  InputLabels_ar <- L$Global$Model$InputLabels

  # Set future processors
  if ( exists('planType') && planType == 'multiprocess'){
    NWorkers <- L$Global$Model$NWorkers
    NWorkers <- min(max(availableCores()-1, 1), NWorkers)
    plan(multiprocess, workers = NWorkers, gc=TRUE)
    
    # Make sure that child processes inherit the libraries from master
    libs <- .libPaths() # Set .libPaths(libs) in call to child process
  } else {
    plan(sequential)
  }
  
  Results_env <- new.env()
  for(sc_path in ScenariosPath_ar){
    Results_env[[basename(sc_path)]] <- data.table(Scenario=basename(sc_path),
                                                   Table=NA,
                                                   Data=NA,
                                                   Units=NA)
    Results_env[[basename(sc_path)]] %<-% tryCatch({
      
      # Ensure libraries from master process are inherited
      .libPaths(libs)
      
      ScResults <- getScenarioResults(
        ScenarioPath = sc_path,
        Output = L$Global$Tables$Name,
        Year = L$G$Year,
        Table = FALSE
      )
      Scenarios_df$Results[which(Scenarios_df$Name==basename(sc_path))] <<- "Completed"
      ScResults
    },
    warning = function(w) print(w),
    error = function(e) {print(e)
      Scenarios_df$Results[which(Scenarios_df$Name==basename(sc_path))] <<- "Result Error"}
    )
  }

  FinalResults_dt <- rbindlist(as.list(Results_env))
  rm(Results_env)
  gc()

  ScenNames_ar <- basename(ScenariosPath_ar)
  ScenTab_dt <- data.table(Scenario = ScenNames_ar)
  Levels_dt <- ScenTab_dt[,tstrsplit(Scenario,"\\D")]
  Levels_dt[,V1:=NULL]
  LevelNames_ar <- strsplit(ScenNames_ar[1],"\\d")[[1]]
  setnames(Levels_dt,colnames(Levels_dt),LevelNames_ar)
  ScenTab_dt <- cbind(ScenTab_dt,Levels_dt)
  ScenTab_dt <- ScenTab_dt[FinalResults_dt,on=.(Scenario)][order(Scenario)]
  BaseYear <- L$G$BaseYear
  ModelState_ls <<- readModelState()
  ScenTab_dt <- ScenTab_dt[,{
                            Bzone <- Data[Table=="Bzone"][[1]]
                            Marea <- Data[Table=="Marea"][[1]]
                            Household <- Data[Table=="Household"][[1]]
                            Vehicle <- Data[Table=="Vehicle"][[1]]
                            BzoneUnits <- Units[Table=="Bzone"][[1]]
                            MareaUnits <- Units[Table=="Marea"][[1]]
                            HouseholdUnits <- Units[Table=="Household"][[1]]
                            VehicleUnits <- Units[Table=="Vehicle"][[1]]

                            #GHG Reduction Placeholder
                            GHGReduction <- 0

                            #Get the DVMT per capita
                            DVMTPerCapita <- sum(Household$Dvmt)/sum(Bzone$Pop)
                            #Walk travel per capita
                            WalkTravelPerCapita <- sum(Household$WalkTrips)/sum(Bzone$Pop)
                            #Air pollution emiisions placeholder
                            AirPollutionEm <- sum(Household$DailyCO2e) #incorrect calculations
                            #Annual fuel use
                            FuelUse <- (sum(Household$DailyGGE) +
                                          sum(Marea$ComSvcUrbanGGE) +
                                          sum(Marea$ComSvcRuralGGE)
                            ) * 365

                            #Truck Delay Placeholder
                            TruckDelay <- 0
                            #Vehicle ownership cost as percentage of income
                            OperationCost <- Household$AveVehCostPM  * Household$Dvmt
                            OwnCost <- Household$OwnCost
                            TotalCost <- OwnCost+OperationCost
                            VehicleCost <- sum(TotalCost)/sum(Household$Income) * 100

                            #Vehicle ownership cost as percentage of income for low income people
                            #“low income” assumption is defined as  <$20K (2005$).
                            Income2005 <- deflateCurrency(Household$Income,BaseYear,"2005")
                            IsLowIncome <- Income2005 < 20000
                            VehicleCostLow <- sum(TotalCost[IsLowIncome])/sum(Household$Income[IsLowIncome]) * 100

                            .(GHGReduction=GHGReduction,DVMTPerCapita=DVMTPerCapita,
                              WalkTravelPerCapita=WalkTravelPerCapita, TruckDelay=TruckDelay,
                              AirPollutionEm=AirPollutionEm, FuelUse=FuelUse,
                              VehicleCost=VehicleCost, VehicleCostLow=VehicleCostLow)
                          },by=c("Scenario", InputLabels_ar)]

  # Write the output to JSON file
  JSON <- toJSON(ScenTab_dt)
  JSON <- paste("var data = ", JSON, ";", sep="")
  File <- file(file.path(ModelPath, L$Global$Model$ScenarioOutputFolder, "verspm.js"), "w")
  writeLines(JSON, con=File)
  close(File)

  # Write the output configuration file
  JSON <- paste("var outputcfg = ", VERSPMOutputConfig$VERSPM, ";", sep="")
  File <- file(file.path(ModelPath, L$Global$Model$ScenarioOutputFolder, "output-cfg.js"), "w")
  writeLines(JSON, con=File)
  close(File)

  # Write scenario progress report
  write.csv(Scenarios_df, file.path(ModelPath,
                                    L$Global$Model$ScenarioOutputFolder,
                                    "ScenarioProgressReport.csv"),
            row.names = FALSE)

  # Clean up
  gc()
  # Close all the future processors
  closeAllConnections()
  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteResult = 1L)
  return(Out_ls)
}
