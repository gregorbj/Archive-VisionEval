library(visioneval)
library(data.table)
# source("R/FutureTaskProcessor.R")

TableNames <- c("Azone", "Bzone", "Marea", "IncomeGroup", "FuelType")

readTables <- function(Scenario = "Base", Output = "All", Table=TRUE){
  if(is.null(Output)){
    msg <- "No output was selected to export"
    stop(msg)
  }
  if(is.na(Output)){
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
  DataStoreName <- ModelState_ls$DatastoreName
  DataStore_dt <- data.table(ModelState_ls$Datastore)
  ColumnToSearch <- "group"
  if(!Table){
    ColumnToSearch <- "groupname"
  }
  if(any(Output=="All")){
    Output <- Output[Output!="All"]
    Output <- c(Output, setdiff(TableNames, Output))
    ColumnToSearch <- "group"
  }
  Year_ <- "2035"
  FilterDatastore_ar <- apply(sapply(Output, grepl,
                                     x=DataStore_dt[[ColumnToSearch]]),
                              MARGIN = 1,
                              FUN = any) & grepl(Year_, DataStore_dt[[ColumnToSearch]])
  DataStore_dt <- DataStore_dt[FilterDatastore_ar]
  DataStore_dt[,c("Group","Table","Name"):=tstrsplit(groupname, "/")]
  DataStore_dt <- DataStore_dt[!is.na(Name)]
  DataStore_dt[,Value:=list(list(readFromTable(Name, Table, Group))),
               by=groupname]
  DataStore_dt[,Units:=lapply(attributes, function(x) x[["UNITS"]])]
  Outputs_dt <- DataStore_dt[,.(Output=lapply(.SD,as.data.table, stringsAsFactors=FALSE)),.(Table), .SDcols=c("Value")]
  OutputNames_dt <- DataStore_dt[Outputs_dt,list(list(Name)),on=.(Table),by=.EACHI]
  OutputUnits_dt <- DataStore_dt[Outputs_dt, list(list(Units)), on=.(Table), by=.EACHI]
  Outputs_dt[OutputNames_dt,Names:=list(V1),on=.(Table)]
  Outputs_dt[OutputUnits_dt,Units:=list(V1),on=.(Table)]
  Results_dt <- Outputs_dt[,.(Result={Output <- Output[[1]]
  setnames(Output, colnames(Output), unlist(Names))
  .((Output), unlist(Units, recursive = FALSE))}), by=.(Table)]
  Results_dt[,Type:=rep(c("Data","Units"),times=.N/2)]
  Results_dt <- dcast.data.table(Results_dt, Table~Type, value.var = "Result")
  Results_dt[,Scenario:=Scenario]
  return(Results_dt)
}


ModelPath <- file.path("..", "..", "models", "VERPAT_Scenarios")
ScenariosPath_ar <- list.dirs(file.path(ModelPath, "scenarios"), recursive = FALSE)

# ScenarioInProcess <- list()
#
# NWorkers <- 6
#
# plan(multiprocess, workers = NWorkers, gc=TRUE)

getScenarioResults <- function(ScenarioPath, ...){
  currDir <- getwd()
  on.exit(setwd(currDir))
  setwd(ScenarioPath)
  ScenarioName_ <- basename(ScenarioPath)
  ScenarioResult_dt <- readTables(Scenario = ScenarioName_, ...)
  return(ScenarioResult_dt)
}


FinalResults_dt <- rbindlist(lapply(ScenariosPath_ar, getScenarioResults, Output=c("Marea","Azone"), Table=TRUE))

# for(index in seq_along(ScenariosPath_ar)){
#   ScenarioName_ <- ScenarioNames_ar[index]
#   ScenarioPath_ <- ScenariosPath_ar[index]
#   ScenarioInProcess[[ScenarioName_]] <- list()
#
# }
