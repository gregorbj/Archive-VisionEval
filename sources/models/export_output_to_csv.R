# Load the visioneval library to read data
library(visioneval)
library(data.table)

# Create a function to check if a specified attributes
# belongs to the variable
attributeExist <- function(variable, attr_name){
  if(is.list(variable)){
    if(!is.na(variable[[1]])){
      attr_value <- variable[[attr_name]]
      if(!is.null(attr_value)) return(TRUE)
    }
  }
  return(FALSE)
}

makeDataFrame <- function(Table, GroupTableName, OutputData, OutputAttr){
  OutputAllYr <- data.frame()
  
  for ( year in getYears()){
    OutputIndex <- GroupTableName$Table %in% Table & GroupTableName$Group %in% year
    Output <- OutputData[OutputIndex]
    
    if ( Table %in% c('Azone', 'Bzone', 'Marea') ){
      names(Output) <- paste0(GroupTableName$Name[OutputIndex], "_",
                              OutputAttr[OutputIndex], "_")
    } else if ( Table %in% c('FuelType', 'IncomeGroup') ){
      names(Output) <- paste0(GroupTableName$Name[OutputIndex])
    } else {
      stop(Table, 'not found')
    }
    
    Output <- data.frame(Output, stringsAsFactors = FALSE)
    if( Table %in% c('Azone', 'Bzone', 'Marea') | year != ModelState_ls$BaseYear ){
      Output$Year <- year
      OutputAllYr <- rbindlist(list(OutputAllYr, Output), fill = TRUE)
    }
  }
  return(OutputAllYr)
}

# Get the model state
ModelState_ls <- readModelState()
Datastore <- ModelState_ls$Datastore

# Collect the output of all the modules
InputIndex <- sapply(Datastore$attributes, attributeExist, "FILE")

splitGroupTableName <- strsplit(Datastore[!InputIndex, "groupname"], "/")
maxLength <- max(unlist(lapply(splitGroupTableName, length)))
GroupTableName <- do.call(rbind.data.frame, lapply(splitGroupTableName , function(x) c(x, rep(NA, maxLength-length(x)))))
colnames(GroupTableName) <- c("Group", "Table", "Name")
GroupTableName <- GroupTableName[complete.cases(GroupTableName),]

OutputData <- apply(GroupTableName, 1, function(x) readFromTableRD(Name = x[3], Table = x[2], Group = x[1], ReadAttr = TRUE))
OutputAttr <- lapply(OutputData, function(x) attr(x, "UNITS"))


# Write all the outputs by table

if(!dir.exists("output")){
  dir.create("output")
} else {
  system("rm -rf output")
  dir.create("output")
}

for ( tbl in c("Azone", "Bzone", "Marea", "FuelType", "IncomeGroup") ){
  cat('Writing out', tbl, '\n')
  OutDf <- makeDataFrame(tbl, GroupTableName, OutputData, OutputAttr)
  
  if ( tbl == "IncomeGroup" ) tbl <- "JobAccessibility"
  filename <- file.path("output", paste0(tbl, ".csv"))
  fwrite(OutDf, file = filename)
}





