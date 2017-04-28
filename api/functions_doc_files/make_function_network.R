#=========================#
# make_function_network.r #
#=========================#

#This script reads in a JSON-formatted VisionEval function documentation file and produces 3 javascript files - nodes.js, edges.js, and details.js - that are used in a vis.js network visualization of the VisionEval functions and their calling relationships.

#Use jsonlite package to read and write JSON
#-------------------------------------------
library(jsonlite)

#Define functions used in the script
#-----------------------------------
#Function to clean square brackets from JSON created by jsonlite toJson function
cleanJSON <- function(JsonStringToClean) {
  OutJson <- gsub("\\[", "", JsonStringToClean)
  gsub("\\]", "", OutJson)
}

#Function to create nodes data js file that can be used by vis.js
writeNodes <- function(Data_ls) {
  Names_ <- Data_ls$Name
  Groups_ <- Data_ls$Group
  Nodes_ls <- list()
  for (i in 1:length(Names_)) {
    Nodes_ls[[i]] <-
      list(id = i, label = Names_[i], group = Groups_[i])
  }
  OutJs_ <- character(length(Nodes_ls) + 2)
  OutJs_[1] <- "var nodes = new vis.DataSet(["
  for (i in 1:length(Nodes_ls)) {
    if (i == length(Nodes_ls)) {
      OutJs_[i + 1] <- cleanJSON(toJSON(Nodes_ls[[i]]))
    } else {
      OutJs_[i + 1] <- paste0(cleanJSON(toJSON(Nodes_ls[[i]])), ",")
    }
  }
  OutJs_[length(Nodes_ls) + 2] <- "]);"
  writeLines(OutJs_, "js/nodes.js")
}

#Function to create edges data js file that can be used by vis.js
writeEdges <- function(Data_ls) {
  Nodes_ <- Data_ls$Name
  Edges_ls <- list()
  for (i in 1:length(Nodes_)) {
    Calls_ <- Data_ls$Calls[[i]]
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
      OutJs_[k + 1] <- cleanJSON(toJSON(Edges_ls[[k]]))
    } else {
      OutJs_[k + 1] <- paste0(cleanJSON(toJSON(Edges_ls[[k]])), ",")
    }
  }
  OutJs_[length(Edges_ls) + 2] <- "]);"
  writeLines(OutJs_, "js/edges.js")
}

#Function to make an HTML tag text string
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

#Make a js object that contains HTML strings which document function details
writeFunctionDetails <- function(Data_ls) {
  Names_ <- Data_ls$Name
  Details_ls <- list() 
  for (i in 1:length(Names_)) {
    Args_ <- 
      apply(Data_ls$Arguments[[i]], 1, function(x) paste0(x[1], ": ", x[2]))
    if (length(Args_) == 0) Args_ <- "None"
    Html_ <-
      c(
        makeHtmlItem("h2", paste0("Function: ", Names_[i])),
        makeHtmlItem("h3", "Description"),
        makeHtmlItem("p", Data_ls$Description[[i]]),
        makeHtmlItem("h3", "Arguments"),
        makeHtmlList("ul", Args_),
        makeHtmlItem("h3", "Return Value"),
        makeHtmlItem("p", Data_ls$Return[[i]])
      )
    Details_ls[[i]] <- 
      list(name = Names_[i], details = paste(Html_, collapse = " "))
  }
  OutJs_ <- character(length(Details_ls) + 2)
  OutJs_[1] <- "var functionDetails = ["
  for (j in 1:length(Details_ls)) {
    if (j == length(Details_ls)) {
      OutJs_[j + 1] <- cleanJSON(toJSON(Details_ls[[j]]))
    } else {
      OutJs_[j + 1] <- paste0(cleanJSON(toJSON(Details_ls[[j]])), ",")
    }
  }
  OutJs_[length(Details_ls) + 2] <- "];"
  writeLines(OutJs_, "js/details.js")
}

#Read functions documentation file and produce nodes.js, edges.js, & details.js
#------------------------------------------------------------------------------
Functions_ls <- fromJSON("functions.json")
writeNodes(Functions_ls)
writeEdges(Functions_ls)
writeFunctionDetails(Functions_ls)
