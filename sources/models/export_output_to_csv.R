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

# Get the model state
ModelState_ls <- readModelState()
Datastore <- ModelState_ls$Datastore

# Get the output variables of all the modules
InputIndex <- sapply(Datastore$attributes, attributeExist, "FILE")

splitGroupTableName <- strsplit(Datastore[!InputIndex, "groupname"], "/")
maxLength <- max(unlist(lapply(splitGroupTableName, length)))
GroupTableName <- do.call(rbind.data.frame,lapply(splitGroupTableName , function(x) c(x, rep(NA, maxLength-length(x)))))
colnames(GroupTableName) <- c("Group", "Table", "Name")
GroupTableName <- GroupTableName[complete.cases(GroupTableName),]


OutputData <- apply(GroupTableName,1, function(x) readFromTableRD(Name = x[3], Table = x[2], Group = x[1], ReadAttr = TRUE))
OutputAttr <- lapply(OutputData,function(x) attr(x,"UNITS"))

# Get Azone Results
AzoneOutput <- data.frame()

for(year in getYears()){
  OutputIndex <- GroupTableName$Table %in% "Azone" & GroupTableName$Group %in% year
  Output <- OutputData[OutputIndex]
  names(Output) <- paste0(GroupTableName$Name[OutputIndex],"_",OutputAttr[OutputIndex],"_")
  Output <- data.frame(Output, stringsAsFactors = FALSE)
  Output$Year <- year
  AzoneOutput <- rbindlist(list(AzoneOutput, Output), fill = TRUE)
}

# Get Bzone Results
BzoneOutput <- data.frame()

for(year in getYears()){
  OutputIndex <- GroupTableName$Table %in% "Bzone" & GroupTableName$Group %in% year
  Output <- OutputData[OutputIndex]
  names(Output) <- paste0(GroupTableName$Name[OutputIndex],"_",OutputAttr[OutputIndex],"_")
  Output <- data.frame(Output, stringsAsFactors = FALSE)
  Output$Year <- year
  BzoneOutput <- rbindlist(list(BzoneOutput, Output), fill = TRUE)
}

# Get Marea Results
MareaOutput <- data.frame()

for(year in getYears()){
  OutputIndex <- GroupTableName$Table %in% "Marea" & GroupTableName$Group %in% year
  Output <- OutputData[OutputIndex]
  names(Output) <- paste0(GroupTableName$Name[OutputIndex],"_",OutputAttr[OutputIndex],"_")
  Output <- data.frame(Output, stringsAsFactors = FALSE)
  Output$Year <- year
  MareaOutput <- rbindlist(list(MareaOutput, Output), fill = TRUE)
}

# Get FuelType Results
FuelTypeOutput <- data.frame()

for(year in getYears()){
  OutputIndex <- GroupTableName$Table %in% "FuelType" & GroupTableName$Group %in% year
  Output <- OutputData[OutputIndex]
  names(Output) <- paste0(GroupTableName$Name[OutputIndex])
  Output <- data.frame(Output, stringsAsFactors = FALSE)
  if(year != ModelState_ls$BaseYear){
    Output$Year <- year
    FuelTypeOutput <- rbindlist(list(FuelTypeOutput, Output), fill = TRUE)
  }
}


# Get JobAccessibility Results
JobAccessibilityOutput <- data.frame()

for(year in getYears()){
  OutputIndex <- GroupTableName$Table %in% "IncomeGroup" & GroupTableName$Group %in% year
  Output <- OutputData[OutputIndex]
  names(Output) <- paste0(GroupTableName$Name[OutputIndex])
  Output <- data.frame(Output, stringsAsFactors = FALSE)
  if(year != ModelState_ls$BaseYear){
    Output$Year <- year
    JobAccessibilityOutput <- rbindlist(list(JobAccessibilityOutput, Output), fill = TRUE)
  }
}

# Write all the outputs

if(!dir.exists("output")){
  dir.create("output")
} else {
  system("rm -rf output")
  dir.create("output")
}

filename <- file.path("output","Azone.csv")
fwrite(AzoneOutput, file = filename)

filename <- file.path("output","Bzone.csv")
fwrite(BzoneOutput, file = filename)

filename <- file.path("output","Marea.csv")
fwrite(MareaOutput, file = filename)

filename <- file.path("output","FuleType.csv")
fwrite(FuelTypeOutput, file = filename)

filename <- file.path("output","JobAccessibility.csv")
fwrite(JobAccessibilityOutput, file = filename)




