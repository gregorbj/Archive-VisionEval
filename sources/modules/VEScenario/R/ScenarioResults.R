#=================
#ScenarioResults.R
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

library(visioneval)
library(data.table)

#=================================================
#SECTION 1: ESTIMATE AND SAVE Scenario PARAMETERS
#=================================================


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

ScenarioResultsSpecifications <- list(
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
#' Specifications list for ScenarioResults module
#'
#' A list containing specifications for the ScenarioResults module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source ScenarioResults.R script.
"ScenarioResultsSpecifications"
devtools::use_data(ScenarioResultsSpecifications, overwrite = TRUE)


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
  Outputs_dt <- DataStore_dt[,.(Output=lapply(.SD,function(x){
    maxLength <- max(unlist(lapply(x, length)))
    x <- lapply(x, function(y) y[1:maxLength])
    as.data.table(x, stringsAsFactors=FALSE)
  })),.(Table), .SDcols=c("Value")]
  OutputNames_dt <- DataStore_dt[Outputs_dt,.(Names=list(Name)),on=.(Table),by=.EACHI]
  OutputUnits_dt <- DataStore_dt[Outputs_dt, .(Units=list(Units)), on=.(Table), by=.EACHI]
  Outputs_dt[OutputNames_dt,Names:=i.Names,on=.(Table)]
  Outputs_dt[OutputUnits_dt,Units:=i.Units,on=.(Table)]
  Results_dt <- Outputs_dt[,.(Result={Output <- Output[[1]]
  setnames(Output, colnames(Output), unlist(Names))
  .((Output), unlist(Units, recursive = FALSE))}), by=.(Table)]
  Results_dt[,Type:=rep(c("Data","Units"),times=.N/2)]
  Results_dt <- dcast.data.table(Results_dt, Table~Type, value.var = "Result")
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
#' \code{ScenarioResults} gather scenario results.
#'
#' This function gather results from scenarios asynchronously.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import jsonlite future data.table
#' @export
ScenarioResults <- function(L){
  # Setup
  # -------------
  # Set input directory
  ModelPath <- getwd()
  ScenariosPath_ar <- list.dirs(file.path(ModelPath,
                                          L$Global$Model$ScenarioOutputFolder),
                                recursive = FALSE)
  # Set future processors
  NWorkers <- L$Global$Model$NWorkers
  plan(multiprocess, workers = NWorkers, gc=TRUE)

  Results_env <- new.env()
  for(sc_path in ScenariosPath_ar){
    Results_env[[basename(sc_path)]] %<-% getScenarioResults(
      ScenarioPath = sc_path,
      Output = L$Global$Tables$Name,
      Year = L$G$Year,
      Table = TRUE
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
  ScenTab_dt <- ScenTab_dt[FinalResults_dt,on=.(Scenario)][order(B,C,D,L,P,T)]
  ScenTab_dt <- ScenTab_dt[,{Bzone <- Data[Table=="Bzone"][[1]]
               Marea <- Data[Table=="Marea"][[1]]
               Azone <- Data[Table=="Azone"][[1]]
               #Get the population to compute per capita values
               Pop <- sum(Bzone$UrbanPop)
               #Calculate fatalities and injuries per 1000 persons by scenario
               FatalityInjury <- sum(Marea[,.(FatalIncidentMetric, InjuryIncidentMetric)])
               FatalityInjuryRate <- 1000 * FatalityInjury / Pop
               #Calculate average cost per person
               Cost <- sum(Bzone$CostsMetric)
               AveCost <- Cost / Pop
               #Calculate average DVMT per person
               Dvmt <- sum(Bzone$DvmtPolicy)
               AveDvmt <- Dvmt / Pop
               #Calculate average emissions per person
               Emissions <- sum(Bzone$EmissionsMetric)
               AveEmissions <- 365 * Emissions / Pop
               #Calculate average fuel consumed per person
               Fuel <- sum(Bzone$FuelMetric)
               AveFuel <- 365 * Fuel / Pop
               #Calculate average vehicle hours per person
               VehHr <- Marea$VehHrLtVehPolicy
               AveVehHr <- VehHr / Pop
               .(FatalityInjuryRate=FatalityInjuryRate, AveCost=AveCost,
                 AveDvmt=AveDvmt, AveEmissions=AveEmissions,
                 AveFuel=AveFuel, AveVehHr=AveVehHr)
              },.(Scenario,Bike=B,
                  VmtChrg=C,DemandMgt=D,LandUse=L,Parking=P,
                  Transit=T)]
  # Write the output to JSON file
  JSON <- toJSON(ScenTab_dt)
  JSON <- paste("var data = ", JSON, ";", sep="")
  File <- file(file.path(ModelPath, L$Global$Model$ScenarioOutputFolder, "verpat.js"), "w")
  writeLines(JSON, con=File)
  close(File)

  # Clean up
  gc()
  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteResult = 1L)
  return(Out_ls)
}
