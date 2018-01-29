#=======================
#create_functions_docs.R
#=======================

#This script creates supplemental documentation files for the visioneval
#framework. These include javascript files that are used in a webpage
#visualization of the functions and their calling relationships, and markdown
#files of documentation that can be added to the visioneval framework
#documentation.

#NOTE: The script calls functions from the "jsonlite", "Rd2md", and "purrr"
#packages. It will attempt to install the packages if they are not installed


#-------------------------------------------------------------------------------
#PROCESS FUNCTION DOCUMENTATION RD FILES TO CREATE LISTS OF REQUIRED INFORMATION
#-------------------------------------------------------------------------------

#Install packages used if not present
#------------------------------------
InstalledPkg_ <- installed.packages()[,"Package"]
CalledPkg_ <- c("jsonlite", "Rd2md", "purrr")
IsMissingPkg_ <- !(CalledPkg_ %in% InstalledPkg_)
if (any(IsMissingPkg_)) {
  install.packages(CalledPkg_[IsMissingPkg_])
}


#Make a vector of function documentation file paths
#--------------------------------------------------
DocFilePath_ <- "../visioneval/man"
DocFileNames_ <- dir(DocFilePath_)
FuncNames_ <- gsub(".Rd", "", DocFileNames_)
DocFilePaths_ <- file.path(DocFilePath_, dir(DocFilePath_))


#Identify functions called by each function
#------------------------------------------
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
for (DocFile in DocFilePaths_) {
  ParsedRd_ls <- Rd2md::parseRd(tools::parse_Rd(DocFile))
  Group <- getGroup(ParsedRd_ls)
  ParsedRd_ls$group <- Group
  FunctionName <- ParsedRd_ls$name
  ParsedRd_ls$calls <- FunctionCalls_ls[[FunctionName]]
  FunctionDocs_ls[[Group]][[FunctionName]] <- ParsedRd_ls
  rm(ParsedRd_ls, Group, FunctionName)
}
rm(DocFile)


#--------------------------------------------
#CREATE WEB VISUALIZATION DOCUMENTATION FILES
#--------------------------------------------

#Make list with information needed for function visualization
#------------------------------------------------------------
#Convert datastore functions to generic function names
VisDocs_ls <- FunctionDocs_ls
FuncToKeep_ <- c(
  "initDatasetRD", "initDatastoreRD", "initTableRD", "listDatastoreRD",
  "readFromTableRD", "writeToTableRD"
)
VisDocs_ls$datastore <- FunctionDocs_ls$datastore[FuncToKeep_]
#Define function to make visualization documentation list for a function
makeVisList <- function(Doc_ls) {
  #Clean out quotes
  Doc_ls <- lapply(Doc_ls, function(x) {
    gsub("\\\"", "", gsub("\\n", "", x))
  })
  #Make JSON list
  Vis_ls <- list()
  Vis_ls$Name <- Doc_ls$name
  Vis_ls$Group <- Doc_ls$group
  Vis_ls$Description <- Doc_ls$description
  Vis_ls$Details <- Doc_ls$details
  Vis_ls$Group <- Doc_ls$group
  Vis_ls$Arguments <- data.frame(
    Name = names(Doc_ls$arguments),
    Description = Doc_ls$arguments
  )
  rownames(Vis_ls$Arguments) <- NULL
  Vis_ls$Return <- Doc_ls$value
  Vis_ls$Calls <- Doc_ls$calls
  #Return function visualization documentation list
  Vis_ls
}
#Process list in correct form with correct information
Vis_ls <- lapply(purrr::flatten(VisDocs_ls), makeVisList)


#Define function to clean brackets from JSON created by jsonlite toJson function
#-------------------------------------------------------------------------------
cleanJSON <- function(JsonStringToClean) {
  OutJson <- gsub("\\[", "", JsonStringToClean)
  gsub("\\]", "", OutJson)
}

#Define function to create nodes data js file that can be used by vis.js
#-----------------------------------------------------------------------
writeNodes <- function(Data_ls) {
  Names_ <- unname(unlist(lapply(Data_ls, function(x) x$Name)))
  Groups_ <- unname(unlist(lapply(Data_ls, function(x) x$Group)))
  Nodes_ls <- list()
  for (i in 1:length(Names_)) {
    Nodes_ls[[i]] <-
      list(id = i, label = Names_[i], group = Groups_[i])
  }
  OutJs_ <- character(length(Nodes_ls) + 2)
  OutJs_[1] <- "var nodes = new vis.DataSet(["
  for (i in 1:length(Nodes_ls)) {
    if (i == length(Nodes_ls)) {
      OutJs_[i + 1] <- cleanJSON(jsonlite::toJSON(Nodes_ls[[i]]))
    } else {
      OutJs_[i + 1] <- paste0(cleanJSON(jsonlite::toJSON(Nodes_ls[[i]])), ",")
    }
  }
  OutJs_[length(Nodes_ls) + 2] <- "]);"
  writeLines(OutJs_, "functions_doc_files/js/nodes.js")
}

#Define function to create edges data js file that can be used by vis.js
#-----------------------------------------------------------------------
writeEdges <- function(Data_ls) {
  Nodes_ <- unname(unlist(lapply(Data_ls, function(x) x$Name)))
  Edges_ls <- list()
  for (i in 1:length(Nodes_)) {
    Calls_ <- Data_ls[[i]]$Calls
    if (length(Calls_) == 0) next()
    for (j in 1:length(Calls_)) {
      Edges_ls[[length(Edges_ls) + 1]] <- 
        list(from = i, to = which(Nodes_ == Calls_[j]), arrows = "to")
    }
  }
  OutJs_ <- character(length(Edges_ls) + 2)
  OutJs_[1] <- "var edges = new vis.DataSet(["
  for (k in 1:length(Edges_ls)) {
    if (k == length(Edges_ls)) {
      OutJs_[k + 1] <- cleanJSON(jsonlite::toJSON(Edges_ls[[k]]))
    } else {
      OutJs_[k + 1] <- paste0(cleanJSON(jsonlite::toJSON(Edges_ls[[k]])), ",")
    }
  }
  OutJs_[length(Edges_ls) + 2] <- "]);"
  writeLines(OutJs_, "functions_doc_files/js/edges.js")
}

#Define function to make an HTML tag text string
#-----------------------------------------------
makeHtmlItem <- 
  function(Tag, Text, Id = NULL) {
    if (is.null(Id)) {
      OpenTag <- 
        paste0("<", Tag, ">")
    } else {
      OpenTag <-
        paste0("<", Tag, " id=", Id, ">")
    }
    CloseTag <- paste0("</", Tag, ">")
    paste0(OpenTag, Text, CloseTag)
  }

#Function to make an HTML list text string
makeHtmlList <- 
  function(Type, Text_, Id = NULL) {
    if (is.null(Id)) {
      OpenTag <- 
        paste0("<", Type, ">")
    } else {
      OpenTag <-
        paste0("<", Type, " id=", Id, ">")
    }
    Html_ <- OpenTag
    for (i in 1:length(Text_)) {
      Html_ <-
        c(Html_, makeHtmlItem("li", Text_[i]))
    }
    Html_ <-
      c(Html_, paste0("</", Type, ">"))
    Html_
  }

#Define function to make a js object that contains HTML strings which document function details
#----------------------------------------------------------------------------------------------
writeFunctionDetails <- function(Data_ls) {
  Names_ <- unname(unlist(lapply(Data_ls, function(x) x$Name)))
  Details_ls <- list() 
  for (i in 1:length(Names_)) {
    Args_ <- 
      apply(Data_ls[[i]]$Arguments, 1, function(x) paste0(x[1], ": ", x[2]))
    if (length(Args_) == 0) Args_ <- "None"
    Html_ <-
      c(
        makeHtmlItem("h2", paste0("Function: ", Names_[i])),
        makeHtmlItem("h3", "Description"),
        makeHtmlItem("p", Data_ls[[i]]$Description),
        makeHtmlItem("h3", "Details"),
        makeHtmlItem("p", Data_ls[[i]]$Details),
        makeHtmlItem("h3", "Arguments"),
        makeHtmlList("ul", Args_),
        makeHtmlItem("h3", "Return Value"),
        makeHtmlItem("p", Data_ls[[i]]$Return)
      )
    Details_ls[[i]] <- 
      list(name = Names_[i], details = paste(Html_, collapse = " "))
  }
  OutJs_ <- character(length(Details_ls) + 2)
  OutJs_[1] <- "var functionDetails = ["
  for (j in 1:length(Details_ls)) {
    if (j == length(Details_ls)) {
      OutJs_[j + 1] <- cleanJSON(jsonlite::toJSON(Details_ls[[j]]))
    } else {
      OutJs_[j + 1] <- paste0(cleanJSON(jsonlite::toJSON(Details_ls[[j]])), ",")
    }
  }
  OutJs_[length(Details_ls) + 2] <- "];"
  writeLines(OutJs_, "functions_doc_files/js/details.js")
}

#Read functions documentation file and produce nodes.js, edges.js, & details.js
#------------------------------------------------------------------------------
writeNodes(Vis_ls)
writeEdges(Vis_ls)
writeFunctionDetails(Vis_ls)


#--------------------------------------------
#CREATE FUNCTION DOCUMENTATION MARKDOWN FILES
#--------------------------------------------

#Make lists of function names and paths to Rd files by group
#-----------------------------------------------------------
#Function names by group
FuncNames_ls <- lapply(FunctionDocs_ls, function(x) {
  unlist(lapply(x, function(y) {
    y$name
  }))
})
#Rd file paths by group
DocFilePaths_ls <- lapply(FunctionDocs_ls, function(x) {
  unlist(lapply(x, function(y) {
    paste0(DocFilePath_, "/", y$name, ".Rd")
  }))
})

#Function to compose markdown for a function
#-------------------------------------------
makeFunctionMarkdown <- function(RdFilePath, FunctionCalls_) {
  #Convert function Rd file to markdown and save to temporary file
  Rd2md::Rd2markdown(rdfile = RdFilePath, outfile = "temp.md")
  #Read the contents of the temporary file
  MdContents_ <- readLines("temp.md")
  #Add 2 levels to each heading
  WhichHeadings_ <- grep("#", MdContents_)
  MdContents_[WhichHeadings_] <- paste0("##", MdContents_[WhichHeadings_])
  #Add function calls information
  c(MdContents_, "#### Calls", paste(FunctionCalls_, collapse = ", "), "", "")
}

#Write user function documentation
#---------------------------------
writeLines(
  c("### Appendix G: VisionEval Model User Functions", "", ""), 
  "markdown_files/user.md"
  )
Con <- file("markdown_files/user.md", "a")
for (i in 1:length(DocFilePaths_ls$user)) {
  Markdown_ <- makeFunctionMarkdown(
    DocFilePaths_ls$user[i], 
    FunctionCalls_ls[[FuncNames_ls$user[i]]]
    )
  writeLines(Markdown_, Con)
}
close(Con)
  
#Write developer function documentation
#--------------------------------------
writeLines(
  c("### Appendix H: VisionEval Module Developer Functions", "", ""), 
  "markdown_files/developer.md"
)
Con <- file("markdown_files/developer.md", "a")
for (i in 1:length(DocFilePaths_ls$developer)) {
  Markdown_ <- makeFunctionMarkdown(
    DocFilePaths_ls$developer[i], 
    FunctionCalls_ls[[FuncNames_ls$developer[i]]]
  )
  writeLines(Markdown_, Con)
}
close(Con)

#Write control function documentation
#------------------------------------
writeLines(
  c("### Appendix I: VisionEval Framework Control Functions", "", ""), 
  "markdown_files/control.md"
)
Con <- file("markdown_files/control.md", "a")
for (i in 1:length(DocFilePaths_ls$control)) {
  Markdown_ <- makeFunctionMarkdown(
    DocFilePaths_ls$control[i], 
    FunctionCalls_ls[[FuncNames_ls$control[i]]]
  )
  writeLines(Markdown_, Con)
}
close(Con)

#Write datastore function documentation
#--------------------------------------
writeLines(
  c("### Appendix J: VisionEval Framework Datastore Functions", "", ""), 
  "markdown_files/datastore.md"
)
Con <- file("markdown_files/datastore.md", "a")
for (i in 1:length(DocFilePaths_ls$datastore)) {
  Markdown_ <- makeFunctionMarkdown(
    DocFilePaths_ls$datastore[i], 
    FunctionCalls_ls[[FuncNames_ls$datastore[i]]]
  )
  writeLines(Markdown_, Con)
}
close(Con)


