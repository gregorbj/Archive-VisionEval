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
    ),
    item(
      NAME = "InputLabels",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION = "Category labels for inputs"
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
usethis::use_data(BuildScenariosSpecifications, overwrite = TRUE)


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
#' @name BuildScenarios
#' @import jsonlite
#' @export
BuildScenarios <- function(L){
  # Setup
  # -------------
  # Set input directory
  RunDir <- getwd()
  ModelPath <- file.path(RunDir, L$Global$Model$ModelFolder)
  ScenarioInputPath <- file.path(RunDir, L$Global$Model$ScenarioInputFolder)
  # Gather Scenario file structure and names
  InputLabels_ar <- list.dirs(path = ScenarioInputPath, recursive = FALSE,
                              full.names = FALSE)
  ScenarioFiles_ar <- grep(list.files(path = ScenarioInputPath, recursive = TRUE),
                           pattern = "config", value = TRUE, invert = TRUE)

  LevelDef_ar <- dirname(ScenarioFiles_ar)
  # if(any(duplicated(LevelDef_ar))){
  #   stop("More than one file exists in the scenario inputs.")
  # }
  LevelDef_ar <- unique(LevelDef_ar)

  # Gather scenario and category config files
  if(!dir.exists(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))) { 
    if(file.exists(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))){
      file.remove(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
    }
    dir.create(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
  }
  if(file.exists(file.path(ScenarioInputPath,"scenario_config.json"))){
    file.copy(file.path(ScenarioInputPath, "scenario_config.json"),
              file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
    ScenarioConfig_ls <- fromJSON(file.path(ScenarioInputPath, "scenario_config.json"))
  }

  if(file.exists(file.path(ScenarioInputPath,"category_config.json"))){
    file.copy(file.path(ScenarioInputPath, "category_config.json"),
              file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
    CategoryConfig_ls <- fromJSON(file.path(ScenarioInputPath, "category_config.json"))
    # Filter to only scenarios mentioned in categories config file
    # Structure of Category files
    # DF of Category Names and LEVELS
    # LEVELS is a list of DF of LEVEL NAMES and INPUTS
    # INPUTS is a list of DF of Scenario NAMES and LEVEL
    CategoryLevels_df <- do.call(rbind,
                                 lapply(CategoryConfig_ls$LEVELS, function(x) {
                                   y <- lapply(seq_along(x$NAME),
                                               function(z) {
                                                 inputtable <- x$INPUTS[[z]]
                                                 inputtable$CATLEVEL <- x$NAME[[z]]
                                                 return(inputtable)
                                               })
                                   do.call(rbind, y)
                                 }
                                 )
    )
    CategoryLevels_df$PATH <- paste0(CategoryLevels_df$NAME,
                                     "/",
                                     CategoryLevels_df$LEVEL)

    # Check if all the scenario level inputs exists
    InputsExists_ar <- sapply(CategoryLevels_df$PATH,
                             function(path) dir.exists(file.path(ScenarioInputPath, path)))
    if(!all(InputsExists_ar)){
      simpleWarning("Scenario level inputs are missing")
      simpleMessage(paste0("Missing Inputs: ",paste0(names(InputsExists_ar[!InputsExists_ar]),
                                     collapse = ", ")))
    }

    Categories_ls <- lapply(CategoryConfig_ls$LEVELS, function(categories){
      lapply(categories$INPUTS, function(inputlevel){
        sort(apply(inputlevel,1,paste0,collapse="/"))
        }
      )
    })
    # Create scenario combinations from categories
    Scenarios_df <- expand.grid(Categories_ls)
    Scenarios_mx <- t(do.call(rbind,list(apply(Scenarios_df,1,unlist))))
    colnames(Scenarios_mx) <- gsub("\\d|\\W","",Scenarios_mx[1,])
    Scenarios_mx <- Scenarios_mx[,sort(colnames(Scenarios_mx))]
    ScenarioDef_df <- data.frame(Scenarios_mx, stringsAsFactors = FALSE)
  } else {
    # Create scenario combinations
    LevelDef_ls <- split(LevelDef_ar, dirname(LevelDef_ar), drop = TRUE)
    ScenarioDef_df <- expand.grid(LevelDef_ls, stringsAsFactors = FALSE)
  }

  ScenarioNames_ar <- apply(ScenarioDef_df, 1, function(x) {
    Name <- paste(x, collapse = "/")
    gsub("/", "", Name)
  })
  rownames(ScenarioDef_df) <- ScenarioNames_ar



  # Iterate through scenarios and build inputs
  if(dir.exists(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))){
    unlink(file.path(RunDir, L$Global$Model$ScenarioOutputFolder),
           recursive = TRUE)
  }
  tryCatch({
    if(dir.exists(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))){
      stop("Cannot delete the scenario output directory. Please delete manually!")
    }
  },
  warning = function(w) print(w),
  error = function(e) print(e))
  dir.create(file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
  if(file.exists(file.path(ScenarioInputPath,"scenario_config.json"))){
    # file.copy(file.path(ScenarioInputPath, "scenario_config.json"),
    #           file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
    scenconfig_ls <- fromJSON(file.path(ScenarioInputPath,"scenario_config.json"),
                              simplifyDataFrame = FALSE)
    scenconfig_ch <- paste0("var scenconfig = ",
                            toJSON(scenconfig_ls, pretty = TRUE), ";")
    write(scenconfig_ch, file = file.path(RunDir,
                                          L$Global$Model$ScenarioOutputFolder,
                                          "scenario-cfg.js"))
  }
  if(file.exists(file.path(ScenarioInputPath,"category_config.json"))){
    # file.copy(file.path(ScenarioInputPath, "category_config.json"),
    #           file.path(RunDir, L$Global$Model$ScenarioOutputFolder))
    catconfig_ls <- fromJSON(file.path(ScenarioInputPath,"category_config.json"),
                              simplifyDataFrame = FALSE)
    catconfig_ch <- paste0("var catconfig = ",
                            toJSON(catconfig_ls, pretty = TRUE), ";")
    write(catconfig_ch, file = file.path(RunDir,
                                         L$Global$Model$ScenarioOutputFolder,
                                         "category-cfg.js"))
  }
  commonfiles_ar <- file.path(ModelPath, c("defs", "inputs", "run_model.R"))

  # Create/Save a file to store the results of scenario builds, runs,
  # and results
  Scenarios_df <- data.frame(Name=ScenarioNames_ar,
                             Build="NA",
                             Run="NA",
                             Results="NA", stringsAsFactors = FALSE)

  # cat("Bulding Scenarios\n")
  for (sc_ in ScenarioNames_ar) {
    # cat(paste0(sc_, "\n"))
    #Make scenario directory
    ScenarioPath <- file.path(RunDir, L$Global$Model$ScenarioOutputFolder, sc_)
    dir.create(ScenarioPath)
    #Copy common files into scenario directory
    file.copy(commonfiles_ar, ScenarioPath, recursive = TRUE)
    #Create a flag to make sure files are changed according to scenario
    #inputs
    FilesChanged <- FALSE
    # Read model_parameters.json file to replace the content
    tryCatch({
      ModelParameterJsonPath <- file.path(ScenarioPath, "defs", "model_parameters.json")
      ModelParameterContent <- fromJSON(ModelParameterJsonPath)
      #Copy each specialty file into scenario directory
      ScenarioInputPath_ar <- file.path(ScenarioInputPath, ScenarioDef_df[sc_,])
      for (Path in ScenarioInputPath_ar) {
        File <- list.files(Path, full.names = TRUE)
        # If a csv file then copy and overwrite existing file
        # If a json file then replace the existing values with new values
        if(any(grepl("\\.csv$", File))){
          if(!any(file.exists(file.path(ScenarioPath, "inputs", basename(File))))){
            stop(paste0("Scenario input file not recognized: ", basename(File)))
          }
          file.copy(File[grepl("\\.csv$", File)], file.path(ScenarioPath, "inputs"), overwrite = TRUE)
        } else if (any(grepl("\\.json$", File))){
          if(!any(file.exists(file.path(ScenarioPath, "defs", basename(File))))){
            stop(paste0("Scenario defs file not recognized: ", basename(File)))
          }
          NewModelParameterContent <- fromJSON(File)
          if(any(is.na(match(NewModelParameterContent$NAME,
                             ModelParameterContent$NAME)))){
            stop(paste0("Scenario defs variable in file not recognized: ",
                        basename(File)))
          }
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
      FilesChanged <- TRUE
    },
    warning = function(w) print(w),
    error = function(e) print(e))
    # Update and save the Scenario Progress to a csv file
    if(FilesChanged){
      Scenarios_df$Build[which(Scenarios_df$Name==sc_)] <- "Completed"
    } else {
      Scenarios_df$Build[which(Scenarios_df$Name==sc_)] <- "Build Error"
    }
  }
  # Clean up
  gc()
  #Return the results
  #------------------
  # Write/Save Scenario Progress Report
  write.csv(Scenarios_df, file = file.path(RunDir,
                                           L$Global$Model$ScenarioOutputFolder,
                                           "ScenarioProgressReport.csv"),
            row.names = FALSE)
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteBuild = 1L,
                              InputLabels = InputLabels_ar)
  return(Out_ls)
}
