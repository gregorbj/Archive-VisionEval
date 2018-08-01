#=================
#BuildScenarios.R
#=================
# This module builds scenarios from the combinations scenario input levels.

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
library(jsonlite)

#=================================================
#SECTION 1: ESTIMATE AND SAVE Scenario PARAMETERS
#=================================================


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

BuildScenariosSpecifications <- list(
  # Level of geography module is applied at
  RunBy = "Region",
  # Specify new tables to be created by Inp if any
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
      NAME = "ModelFolder",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      SIZE = 20,
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = "CompleteBuild",
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
#' Specifications list for BuildScenarios module
#'
#' A list containing specifications for the BuildScenarios module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source BuildScenarios.R script.
"BuildScenariosSpecifications"
devtools::use_data(BuildScenariosSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================


#Main module function builds scenarios
#------------------------------------------------------------------
#' Function to build scenarios.
#'
#' \code{BuildScenarios} builds structure to run mulitple scenarios.
#'
#' This function builds scenarios from scenario input levels. The folder names
#' in the scenario input folder is used for naming scenarios. The function
#' creates folder for each scneario, copy the model files to the scenario folder,
#' and replaces the model files with relevant scenario inputs.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @export
BuildScenarios <- function(L){
  # Setup
  # -------------
  # Set input directory
  RunDir <- getwd()
  ModelPath <- file.path(RunDir, L$Global$Model$ModelFolder)
  ScenarioInputPath <- file.path(RunDir, L$Global$Model$ScenarioInputFolder)
  # Gather Scenario file structure and names
  ScenarioFiles_ar <- list.files(path = ScenarioInputPath, recursive = TRUE)
  LevelDef_ar <- dirname(ScenarioFiles_ar)
  if(any(duplicated(LevelDef_ar))){
    stop("More than one file exists in the scenario inputs.")
  }

  # Create scenario combinations
  LevelDef_ls <- split(LevelDef_ar, dirname(LevelDef_ar), drop = TRUE)
  ScenarioDef_df <- expand.grid(LevelDef_ls, stringsAsFactors = FALSE)
  ScenarioNames_ar <- apply(ScenarioDef_df, 1, function(x) {
    Name <- paste(x, collapse = "/")
    gsub("/", "", Name)
  })
  rownames(ScenarioDef_df) <- ScenarioNames_ar

  #Iterate through scenarios and build inputs
  if(dir.exists(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))){
    unlink(file.path(RunDir, L$Global$Model$ScenarioOutputFolder),
           recursive = TRUE)
  }
  dir.create(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
  commonfiles_ar <- file.path(ModelPath, c("defs", "inputs", "run_model.R"))
  # cat("Bulding Scenarios\n")
  for (sc_ in ScenarioNames_ar) {
    # cat(paste0(sc_, "\n"))
    #Make scenario directory
    ScenarioPath <- file.path(RunDir, L$Global$Model$ScenarioOutputFolder, sc_)
    dir.create(ScenarioPath)
    #Copy common files into scenario directory
    file.copy(commonfiles_ar, ScenarioPath, recursive = TRUE)
    # Read model_parameters.json file to replace the content
    ModelParameterJsonPath <- file.path(ScenarioPath, "defs", "model_parameters.json")
    ModelParameterContent <- fromJSON(ModelParameterJsonPath)
    #Copy each specialty file into scenario directory
    ScenarioInputPath_ar <- file.path(ScenarioInputPath, ScenarioDef_df[sc_,])
    for (Path in ScenarioInputPath_ar) {
      File <- list.files(Path, full.names = TRUE)
      # If a csv file then copy and overwrite existing file
      # If a json file then replace the existing values with new values
      if(grepl("\\.csv$", File)){
        file.copy(File, file.path(ScenarioPath, "inputs"), overwrite = TRUE)
      } else if (grepl("\\.json$", File)){
        NewModelParameterContent <- fromJSON(File)
        ModelParameterContent[match(NewModelParameterContent$NAME,
                                    ModelParameterContent$NAME), "VALUE"] <-
          NewModelParameterContent$VALUE
        rm(NewModelParameterContent)
      } else {
        stop(paste0("Scenario input file not recognized: ", basename(File)))
      }
    }
    write_json(ModelParameterContent, path = file.path(ScenarioPath, "defs", "model_parameters.json"),
               pretty=TRUE)
  }
  # Clean up
  gc()
  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteBuild = 1L)
  return(Out_ls)
}
