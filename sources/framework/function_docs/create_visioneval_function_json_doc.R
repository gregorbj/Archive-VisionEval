#create_visioneval_function_json_doc.R

#This script creates a JSON file which documents the visioneval functions and
#their relationships to be used in an interactive visualization. For each function
#

library(jsonlite)
library(Rd2md)
library(tools)
library(purrr)


#Make a vector of function documentation file paths
#--------------------------------------------------
DocFilePath_ <- "man"
FuncDocFiles_ <- file.path(DocFilePath_, dir(DocFilePath_))


#Identify functions called by each function
#------------------------------------------
#Make vector of function names
FuncNames_ <- gsub("man/", "", gsub(".Rd", "", FuncDocFiles_))
#Define function to search for function calls
findFunctionCalls <- function(FuncName, FuncNames_) {
  FuncBody <-
    body(eval(parse(text = paste0("visioneval::", FuncName))))
  IsCalled_ <- sapply(FuncNames_, function(x) {
    Test1 <- length(grep(paste0(x, "\\("), FuncBody)) > 0
    Test2 <- length(grep(paste0(x, " \\("), FuncBody)) > 0
    Test1 | Test2
  })
  FuncNames_[IsCalled_]
}
#Iterate through functions and identify the functions that each function calls
FunctionCalls_ls <- lapply(FuncNames_, function(x){
  findFunctionCalls(x, FuncNames_)
})
names(FunctionCalls_ls) <- FuncNames_


#Iterate through documentation files, parse, find group, add to FunctionDocs_ls
#------------------------------------------------------------------------------
#Initialize a functions documentation list to store documentation by function group
FunctionDocs_ls <- list(
  user = list(),
  developer = list(),
  control = list(),
  datastore = list()
)
#Define function to extract function group name from the function description
getGroup <- function(ParsedRd_ls) {
  Description <- gsub("\n", "", ParsedRd_ls$description)
  GroupCheck_ <- c(
    user = length(grep("model user", Description)) != 0,
    developer = length(grep("module developer", Description)) != 0,
    control = length(grep("control", Description)) != 0,
    datastore = length(grep("datastore connection", Description)) != 0
  )
  names(GroupCheck_)[GroupCheck_]
}
#Iterate through documentation files
for (DocFile in FuncDocFiles_) {
  ParsedRd_ls <- parseRd(parse_Rd(DocFile))
  Group <- getGroup(ParsedRd_ls)
  ParsedRd_ls$group <- Group
  FunctionName <- ParsedRd_ls$name
  ParsedRd_ls$calls <- FunctionCalls_ls[[FunctionName]]
  FunctionDocs_ls[[Group]][[FunctionName]] <- ParsedRd_ls
  rm(ParsedRd_ls, Group, FunctionName)
}
rm(DocFile)

test <- flatten(FunctionDocs_ls)


#Make documentation JSON file
#----------------------------
#Define function to make JSON documentation for a function
makeFunctionJsonDoc <- function(Doc_ls) {
  #Clean out quotes
  Doc_ls <- lapply(Doc_ls, function(x) {
    gsub("\\\"", "", gsub("\\n", "", x))
  })
  #Make JSON list
  JsonDoc_ls <- list()
  JsonDoc_ls$Name <- Doc_ls$name
  JsonDoc_ls$Group <- Doc_ls$group
  JsonDoc_ls$Description <- Doc_ls$description
  JsonDoc_ls$Details <- Doc_ls$details
  JsonDoc_ls$Group <- Doc_ls$group
  JsonDoc_ls$Arguments <- data.frame(
    Name = names(Doc_ls$arguments),
    Description = Doc_ls$arguments
  )
  rownames(JsonDoc_ls$Arguments) <- NULL
  JsonDoc_ls$Return <- Doc_ls$value
  JsonDoc_ls$Calls <- Doc_ls$calls
  #Return JSON list
  JsonDoc_ls
}

JsonDoc_ls <- lapply(flatten(FunctionDocs_ls), makeFunctionJsonDoc)
names(JsonDoc_ls) <- NULL
sink("json.json")
toJSON(JsonDoc_ls)
sink()



test <- FunctionDocs_ls[[1]][[2]]
test <- lapply(test, function(x) {
  gsub("\\\"", "", gsub("\\n", "", x))
  })
test$arguments <- data.frame(
  Name = names(test$arguments),
  Description = test$arguments
)
rownames(test$arguments) <- NULL




