#=================
#VERPATResults.R
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

# library(visioneval)
# library(data.table)

#=================================================
#SECTION 1: ESTIMATE AND SAVE Scenario PARAMETERS
#=================================================

# Save VERPAT OUTPUT config file

verpat_output_config_txt <-
'[
  {
    "NAME": "Fatalities & Injuries",
    "LABEL": "Fatalities & Injuries",
    "DESCRIPTION": "Annual traffic fatalities and injuries per 1000 persons.",
    "INSTRUCTIONS": "annual traffic fatalities and injuries per 1000 persons.",
    "METRIC": "Average",
    "UNIT": "annual per 1000 pop",
    "COLUMN": "FatalityInjuryRate"
  },
{
    "NAME": "Vehicle Cost Per Capita",
  "LABEL": "Cost Per Capita",
  "DESCRIPTION": "Annual vehicle costs per capita.",
  "INSTRUCTIONS": "average annual cost for owning & operating vehicles per person.",
  "METRIC": "Average",
  "UNIT": "annual per capita",
    "COLUMN": "AveCost"
},
{
    "NAME": "DVMT Per Capita",
  "LABEL": "Daily Vehicle Miles Traveled",
  "DESCRIPTION": "daily miles of vehicle travel per person.",
  "INSTRUCTIONS": "average daily vehicle miles traveled per person.",
  "METRIC": "Average",
  "UNIT": "daily per capita",
    "COLUMN": "AveDvmt"
},
{
    "NAME": "GHG Emissions Per Capita",
  "LABEL": "GHG Emissions",
  "DESCRIPTION": "annual metric tons greenhouse gas emissions per capita.",
  "INSTRUCTIONS": "average annual metric tons of greenhouse gas emissions per person.",
  "METRIC": "Average",
  "UNIT": "annual per capita",
    "COLUMN": "AveEmissions"
},
{
    "NAME": "Fuel Consumption",
  "LABEL": "Fuel Consumption",
  "DESCRIPTION": "average annual gallons of fuel consumed per capita.",
  "INSTRUCTIONS": "average annual gallons of gasoline and other fuels consumed per person.",
  "METRIC": "Average",
  "UNIT": "annual per capita",
    "COLUMN": "AveFuel"
},
{
    "NAME": "DVHT Per Capita",
  "LABEL": "Vehicle Hours of Travel",
  "DESCRIPTION": "daily vehicle hours of travel per capita.",
  "INSTRUCTIONS": "average daily vehicle hours of travel per person.",
  "METRIC": "Average",
  "UNIT": "daily per capita",
    "COLUMN": "AveVehHr"
  }
]'

VERPATOutputConfig <- list(
  VERPAT = verpat_output_config_txt
)
#Save the config specifications list
#---------------------------------
#' Scenario output configurations for VERPAT model
#'
#' A list containing output configurations for VERPAT model.
#'
#' @format A list containing configuration for models in json format:
#' \describe{
#'  \item{VERPAT}{Scenario output configuration for VERPAT model}
#' }
#' @source VERPATResults.R script.
"VERPATOutputConfig"
usethis::use_data(VERPATOutputConfig, overwrite = TRUE)





#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

VERPATResultsSpecifications <- list(
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
    ),
    item(
      NAME = "InputLabels",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "character",
      UNITS = "NA",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
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
#' Specifications list for VERPATResults module
#'
#' A list containing specifications for the VERPATResults module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source VERPATResults.R script.
"VERPATResultsSpecifications"
usethis::use_data(VERPATResultsSpecifications, overwrite = TRUE)


# TableNames <- c("Azone", "Bzone", "Marea", "IncomeGroup", "FuelType")


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function gather scenario results
#------------------------------------------------------------------
#' Function to gather scenario results.
#'
#' \code{VERPATResults} gather scenario results.
#'
#' This function gather results from scenarios asynchronously.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name VERPATResults
#' @import jsonlite future data.table
#' @export
VERPATResults <- function(L){
  # Setup
  # -------------
  # Set input directory
  ModelPath <- getwd()
  ScenariosPath_ar <- list.dirs(file.path(ModelPath,
                                          L$Global$Model$ScenarioOutputFolder),
                                recursive = FALSE)

  # Update the Scenario Progress Report
  Scenarios_df  <- read.csv(file.path(ModelPath,
                                      L$Global$Model$ScenarioOutputFolder,
                                      "ScenarioProgressReport.csv"),
                            stringsAsFactors = FALSE)

  InputLabels_ar <- L$Global$Model$InputLabels

  # Set future processors
  if ( exists('planType') && planType == 'multiprocess'){
    NWorkers <- L$Global$Model$NWorkers
    NWorkers <- min(max(availableCores()-1, 1), NWorkers)
    plan(multiprocess, workers = NWorkers, gc=TRUE)
    message("Executing with ", NWorkers, " processors\n")
  } else {
    plan(sequential)
    message("Executing with sequential processing\n")
  }

  # Make sure that child processes inherit the libraries from master
  libs <- .libPaths() # Set .libPaths(libs) in call to child process
  
  Results_env <- new.env()
  for(sc_path in ScenariosPath_ar){
    message('Getting results for ', basename(sc_path), '\n')
    Results_env[[basename(sc_path)]] <- data.table(Scenario=basename(sc_path),
                                                   Table=NA,
                                                   Data=NA,
                                                   Units=NA)
    Results_env[[basename(sc_path)]] %<-% tryCatch({

      # Ensure libraries from master process are inherited
      .libPaths(libs)
      ScResults <- getScenarioResults(
        ScenarioPath = sc_path,
        Output = L$Global$Tables$Name,
        Year = L$G$Year,
        Table = TRUE
      )
      Scenarios_df$Results[which(Scenarios_df$Name==basename(sc_path))] <<- "Completed"
      ScResults
    },
    warning = function(w) print(w),
    error = function(e) {print(e)
      Scenarios_df$Results[which(Scenarios_df$Name==basename(sc_path))] <<- "Result Error"}
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
  ScenTab_dt <- ScenTab_dt[FinalResults_dt,on=.(Scenario)]
  message('Summarizing results across scenarios\n')
  ScenTab_dt <- ScenTab_dt[, {
    Bzone <- Data[Table=="Bzone"][[1]]
    Marea <- Data[Table=="Marea"][[1]]
    Azone <- Data[Table=="Azone"][[1]]
    BzoneUnits <- Units[Table=="Bzone"][[1]]
    MareaUnits <- Units[Table=="Marea"][[1]]
    AzoneUnits <- Units[Table=="Azone"][[1]]
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
    AveDvmt <- convertUnits(AveDvmt, "compound",
                            BzoneUnits[which(colnames(Bzone)=="DvmtPolicy")],
                            "MI/DAY")$Value
    #Calculate average emissions per person
    # Withouth EV
    # Emissions <- sum(Bzone$EmissionsMetric)
    # AveEmissions <- 365 * Emissions / Pop
    # AveEmissions <- convertUnits(AveEmissions, "compound",
    #                              BzoneUnits[which(colnames(Bzone)=="EmissionsMetric")],
    #                              "MT/YR")$Value
    FuelEmissions <- sum(Bzone$FuelEmissionsMetric)
    PowerEmissions <- sum(Bzone$PowerEmissionsMetric)
    AveFuelEmissions <- 365 * FuelEmissions / Pop
    AvePowerEmissions <- 365 * PowerEmissions / Pop
    AveEmissions <- convertUnits(AveFuelEmissions, "compound",
                                 BzoneUnits[which(colnames(Bzone)=="FuelEmissionsMetric")],
                                 "MT/DAY")$Value +
      convertUnits(AvePowerEmissions, "compound",
                   BzoneUnits[which(colnames(Bzone)=="PowerEmissionsMetric")],
                   "MT/YR")$Value
    #Calculate average fuel consumed per person
    Fuel <- sum(Bzone$FuelMetric)
    AveFuel <- 365 * Fuel / Pop
    AveFuel <- convertUnits(AveFuel, "compound",
                            BzoneUnits[which(colnames(Bzone)=="FuelMetric")],
                            "GAL/DAY")$Value
    #Calculate average vehicle hours per person
    VehHr <- Marea$VehHrLtVehPolicy
    AveVehHr <- VehHr / Pop
    AveVehHr <- convertUnits(AveVehHr, "time",
                             BzoneUnits[which(colnames(Bzone)=="VehHrLtVehPolicy")],
                             "HR")$Value
    .(FatalityInjuryRate=FatalityInjuryRate, AveCost=AveCost,
      AveDvmt=AveDvmt, AveEmissions=AveEmissions,
      AveFuel=AveFuel, AveVehHr=AveVehHr)
  },
  by=c("Scenario", InputLabels_ar)]

  # Write the output to JSON file
  JSON <- toJSON(ScenTab_dt)
  JSON <- paste("var data = ", JSON, ";", sep="")
  File <- file(file.path(ModelPath, L$Global$Model$ScenarioOutputFolder, "verpat.js"), "w")
  message('Writing results to ', File, '\n')
  writeLines(JSON, con=File)
  close(File)

  # Write the output configuration file
  JSON <- paste("var outputconfig = ", VERPATOutputConfig$VERPAT, ";", sep="")
  File <- file(file.path(ModelPath, L$Global$Model$ScenarioOutputFolder, "output-cfg.js"), "w")
  message('Writing output configuration to', File, '\n')
  writeLines(JSON, con=File)
  close(File)

  # Write scenario progress report
  message('Writing scenario progress report\n')
  write.csv(Scenarios_df, file.path(ModelPath,
                                    L$Global$Model$ScenarioOutputFolder,
                                    "ScenarioProgressReport.csv"),
            row.names = FALSE)

  # Clean up
  gc()
  # Close all the future processors
  closeAllConnections()
  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteResult = 1L)
  return(Out_ls)
}
