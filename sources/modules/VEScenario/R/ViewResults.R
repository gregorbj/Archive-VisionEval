#=================
#ViewResults.R
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
# Untar the html files



#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

ViewResultsSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Set if any
  # NewSetTable
  # Specify Input data
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
      NAME = "CompleteViewer",
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
#' Specifications list for ViewResults module
#'
#' A list containing specifications for the ViewResults module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source ViewResults.R script.
"ViewResultsSpecifications"
usethis::use_data(ViewResultsSpecifications, overwrite = TRUE)

#Main module function run scenarios
#------------------------------------------------------------------
#' Function to view scenario results.
#'
#' \code{ViewResults} shows the scenario results in a html page.
#'
#' This function shows the results of scneario run in a html page.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name ViewResults
#' @export
ViewResults <- function(L){
  # Setup
  # -------------
  
  # Clear old Visualizer
  if(dir.exists("Visualizer")){
    unlink("Visualizer", recursive = TRUE, force = TRUE)
  }
  dir.create("Visualizer")
  
  # Set input directory
  ModelPath <- getwd()

  # Load html files from tar archive
  if("VEScenario" %in% rownames(installed.packages())){
    HtmlFilePath <- system.file("extdata", "VEScenarioViewer.tar", package = "VEScenario")
    untar(HtmlFilePath, exdir = file.path(ModelPath, "Visualizer"))
  }
  
  JsonFiles <- list.files(file.path(ModelPath, L$Global$Model$ScenarioOutputFolder),
                          recursive = FALSE, pattern = "*.js$", full.names = TRUE)
  
  modelFile <- JsonFiles[grepl("(ve(rpat|rspm|state)).js$", JsonFiles, ignore.case = FALSE)]
  model <- gsub('[.]js$', '', basename(modelFile))

  JsonDir <- file.path(ModelPath, "Visualizer", "data", toupper(model))
  file.copy(JsonFiles, JsonDir, overwrite = TRUE)
  
  htmlPath <- file.path(ModelPath, "Visualizer", paste0(model, '.html'))
  
  # Open file in browser
  browseURL(htmlPath)

  # Clean up
  gc()
  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteViewer = 1L)
  return(Out_ls)
}
