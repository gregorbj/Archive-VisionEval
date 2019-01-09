#=================
#RunScenarios.R
#=================
# This module runs multiple scenarios that have the different input files.

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

#=================================================
#SECTION 1: ESTIMATE AND SAVE Scenario PARAMETERS
#=================================================


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

RunScenariosSpecifications <- list(
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
      NAME = "NWorkers",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "NA",
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  Set = items(
    item(
      NAME = "CompleteRun",
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
#' Specifications list for RunScenarios module
#'
#' A list containing specifications for the RunScenarios module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source RunScenarios.R script.
"RunScenariosSpecifications"
usethis::use_data(RunScenariosSpecifications, overwrite = TRUE)



#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

# Function to start asynchronous task
#------------------------------------------------------------------
#' Function to start asynchronous task.
#'
#' \code{startAsyncTask} calculates performance metrics.
#'
#' This function starts/queues a future task.
#'
#' @param asyncTasksRunning A list of asynchronous tasks running currently.
#' @param asyncTaskName A string indicating the name of the task.
#' @param futureObj An object of class future.
#' @param callback A post processing function when the future returns
#' a value.
#' @param debug A logical. TRUE if want to print more intermediate messages.
#' @return A list containing all the parameters to the function.
#' @import future
startAsyncTask <-  function(asyncTasksRunning = vector(mode = "list"), asyncTaskName, futureObj,
                            callback = NULL, debug = FALSE){
  # Record start time
  submitTime <- Sys.time()
  if (futureObj$lazy) {
    warning(
      paste0(
        "startAsyncTask futureObj  has lazy=TRUE! '",
        asyncTaskName,
        "' will not be started until processRunningTasks ",
        "is called with wait=TRUE and will then only run one item at a time!"
      )
    )
  }
  if (debug)
    print(paste0(
      submitTime,
      ": startAsyncTask asyncTaskName '",
      asyncTaskName,
      "' called. There are now ", length(asyncTasksRunning)+1, " current tasks."
    ))

  if (exists(asyncTaskName, asyncTasksRunning)) {
    stop(
      "Error: A task with the same asyncTaskName '",
      asyncTaskName,
      "' is already running. It is not known if it is running the same task"
    )
  }
  asyncTaskObject <- list(
    futureObj = futureObj,
    taskName = asyncTaskName,
    callback = callback,
    submitTime = submitTime
  )
  # asyncTasksRunning[[asyncTaskName]] <<- asyncTaskObject
  return(asyncTaskObject)
} #end startAsyncTask

# Function that returns the number of current future tasks
#------------------------------------------------------------------
#' Function that returns the number of current future tasks.
#'
#' \code{getNumberOfRunningTasks} returns the number of tasks running
#' currently.
#'
#' This function returns the number of tasks running currently.
#'
#' @param asyncTasksRunning A list of asynchronous tasks running currently.
#' @return An integer indicating the number of tasks currently running
#' @import future
getNumberOfRunningTasks <- function(asyncTasksRunning = vector(mode = "list")) {
  return(min(length(asyncTasksRunning)-1,nbrOfWorkers()))
}

# Function that returns the status of tasks running
#------------------------------------------------------------------
#' Function that returns the status of tasks running currently
#'
#' \code{getRunningTasksStatus} returns the status of tasks running
#' currently.
#'
#' This function returns the status of tasks running currently.
#'
#' @param asyncTasksRunning A list of asynchronous tasks running currently.
#' @return A string indicating the status of the tasks running currently
#' @import future
getRunningTasksStatus <- function(asyncTasksRunning = vector(mode = "list")) {
  # Function to return the status of single task
  getRunningTaskStatus <- function(asyncTaskObject) {
    if (is.null(asyncTaskObject) ||
        length(names(asyncTaskObject)) < 4) {
      runningTaskStatus <- "[NULL]"
    } else {
      runningTaskStatus <-
        paste0(
          "[",
          asyncTaskObject[["taskName"]],
          "'s elapsed time: ",
          format(Sys.time() - asyncTaskObject[["submitTime"]]),
          ", Finished?: ",
          resolved(asyncTaskObject[["futureObj"]]),
          "]"
        )
    }
    return(runningTaskStatus)
  }
  runningTasksStatus <- paste(Sys.time(),
                              ": # of running tasks: ",
                              length(asyncTasksRunning),
                              paste0(collapse = ", ",
                                     lapply(asyncTasksRunning, getRunningTaskStatus)
                              )
  )
  return(runningTasksStatus)
} #end getRunningTasksStatus


# Function that processes the tasks running currently
#------------------------------------------------------------------
#' Function that processes the tasks running currently
#'
#' \code{processRunningTasks} processes the tasks running
#' currently.
#'
#' This function is called periodically, this will check all running asyncTasks
#' for completion. Returns number of remaining tasks so could be used as a boolean
#'
#' @param asyncTasksRunning A list of asynchronous tasks running currently.
#' @param wait A logical. TRUE if the processor needs to wait for all the results.
#' @param catchErrors A logical. Set to TRUE if want to catch the errors resulted
#' in futures.
#' @param debug A logical. Set to TRUE if need to print intermediate results.
#' @param maximumTaskToResolve An integer for the maximum number of tasks to resolve.
#' @return An integer indicating the number of tasks currently running
#' @import future
processRunningTasks <- function(asyncTasksRunning = vector(mode = "list"),
                                wait = FALSE, catchErrors = TRUE,
                                debug = FALSE, maximumTasksToResolve = NULL){
  # Check if maximumTasksToResolve has a value less than 1
  if (!is.null(maximumTasksToResolve) && (maximumTasksToResolve < 1)) {
    stop(
      paste0(
        "processRunningTasks called with maximumTasksToResolve=",
        maximumTasksToResolve,
        " which does not make sense. It must be greater than 0 if specified"
      )
    )
  }
  # Initiation variables
  functionStartTime <- Sys.time()
  numTasksResolved <- 0
  # Loop over async object to check which are resolved
  for (asyncTaskName in names(asyncTasksRunning)) {
    # If maximumTasksToResolve has a value then break if
    # numTasksResolved >= maximumTasksToResolve
    if (!is.null(maximumTasksToResolve) &&
        (numTasksResolved >= maximumTasksToResolve)) {
      break
    } #end checking if need to break because of maximumTasksToResolve
    asyncTaskObject_ls <- asyncTasksRunning[[asyncTaskName]]
    asyncFutureObject <- asyncTaskObject_ls[["futureObj"]]
    isObjectResolved <- resolved(asyncFutureObject)
    if (isObjectResolved || wait) {
      if (debug && !isObjectResolved) {
        print(
          paste0(
            Sys.time(),
            ": processRunningTasks about to wait for task '",
            asyncTaskName,
            "' to finish. ", length(asyncTasksRunning), " tasks still running."
          )
        )
      }
      taskResult <- NA
      numTasksResolved <- numTasksResolved + 1
      #NOTE future will send any errors it caught when we ask it for the value -- same as if we had evaluated the expression ourselves
      caughtError <- NULL
      caughtWarning <- NULL
      # Use try catch to continue running the scenarios w/o
      # interruptions
      tryCatch({
        if (catchErrors) {
          withCallingHandlers(
            expr = {
              taskResult <- value(asyncFutureObject)
            },
            warning = function(w) {
              caughtWarning <- w
              print(
                paste0(
                  Sys.time(),
                  ": ***WARNING*** processRunningTasks: '",
                  asyncTaskName,
                  "' returned a warning: ",
                  w
                )
              )
              print(sys.calls())
            },
            error = function(e) {
              caughtError <- e
              print(
                paste0(
                  Sys.time(),
                  ": ***ERROR*** processRunningTasks: '",
                  asyncTaskName,
                  "' returned an error: ",
                  e
                )
              )
              print(sys.calls())
            }
          )#end withCallingHandlers
        } #end if catch errors
        else {
          #simply fetch the value -- if exceptions happened they will be thrown by the Future library when we call value and
          #therefore will propagate to the caller
          taskResult <- value(asyncFutureObject)
        }},
        warning = function(w) print(w),
        error = function(e) print(e)
      )
      rm(asyncFutureObject)
      submitTime <- asyncTaskObject_ls[["submitTime"]]
      endTime <- Sys.time()
      elapsedTime <- format(endTime - submitTime)
      if (debug)
        print(
          paste0(
            Sys.time(),
            ": processRunningTasks finished: '",
            asyncTaskName,
            "' and there are ",
            getNumberOfRunningTasks(asyncTasksRunning = asyncTasksRunning),
            " additional task still running.",
            # " submitTime: ",
            # submitTime,
            # ", endTime: ",
            # endTime,
            " Elapsed time since submitted: ",
            elapsedTime
          )
        )
      callback <- asyncTaskObject_ls[["callback"]]
      asyncTasksRunning[[asyncTaskName]] <- NULL
      if (!is.null(callback)) {
        callback(
          list(
            asyncTasksRunning = asyncTasksRunning,
            asyncTaskName = asyncTaskName,
            taskResult = taskResult,
            submitTime = submitTime,
            endTime = endTime,
            elapsedTime = elapsedTime,
            caughtError = caughtError,
            caughtWarning = caughtWarning
          )
        )
      }
    } #end if resolved
  }#end loop over async data items being loaded
  #Any more asynchronous data items being loaded?
  if (debug && (numTasksResolved > 0)) {
    print(
      paste0(
        Sys.time(),
        ": processRunningTasks with wait=",
        wait,
        " exiting after resolving: ",
        numTasksResolved,
        " tasks. Elapsed time in function: ",
        format(Sys.time() - functionStartTime),
        " tasks still running: ",
        length(asyncTasksRunning)
      )
    )
  }
  return(
    list(
      RunningTasks = min(length(asyncTasksRunning), nbrOfWorkers()),
      asyncTasksRunning = asyncTasksRunning
    )
  )
} # end processRunningTasks


#Main module function run scenarios
#------------------------------------------------------------------
#' Function to run scenarios.
#'
#' \code{RunScenarios} runs all scenarios.
#'
#' This function runs scenarios in parallel. It uses the future package and
#' run scenarios asynchronously.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name RunScenarios
#' @import future
#' @export
RunScenarios <- function(L){
  # Setup
  # -------------
  # Set input directory
  ModelPath <- getwd()
  ScenarioInputPath <- file.path(ModelPath, L$Global$Model$ScenarioOutputFolder)

  # Gather Scenario file structure and names
  ScenariosPath_ar <- list.dirs(ScenarioInputPath, recursive = FALSE)
  ScenarioNames_ar <- basename(ScenariosPath_ar)

  # A list to store currently running scenarios
  ScenarioInProcess_ls <- list()
  NWorkers <- L$Global$Model$NWorkers
  NWorkers <- min(max(availableCores()-1, 1), NWorkers)
#  plan(multiprocess, workers = NWorkers, gc=TRUE)
  plan(sequential, workers = NWorkers, gc=TRUE)
  # Update the Scenario Progress Report
  Scenarios_df  <- read.csv(file.path(ModelPath,
                                      L$Global$Model$ScenarioOutputFolder,
                                      "ScenarioProgressReport.csv"),
                            stringsAsFactors = FALSE)
  RunScenariosFlag_ar <- vector(mode="logical",
                                length = nrow(Scenarios_df))
  RunScenariosFlag_ar <- Scenarios_df$Build %in% "Completed"
  names(RunScenariosFlag_ar) <- Scenarios_df$Name

  RunScenariosFinishFlag_ar <- vector(mode="logical",
                                      length = nrow(Scenarios_df))
  names(RunScenariosFinishFlag_ar) <- Scenarios_df$Name

  for(index in seq_along(ScenariosPath_ar)){
    ScenarioName_ <- ScenarioNames_ar[index]
    # Check if Scenario build is completed
    if(!RunScenariosFlag_ar[ScenarioName_]){
      ScenarioPath_ <- ScenariosPath_ar[index]
      if(dir.exists(ScenarioPath_)){
        unlink(ScenarioPath_, recursive = TRUE)
      }
      ScenarioLogFile <- paste0(ScenarioName_, ".txt")
      ScenarioLogFilePath <- file.path(ScenarioInputPath, ScenarioLogFile)
      if(file.exists(ScenarioLogFilePath)){
        file.remove(ScenarioLogFilePath)
      }
      next
    }
    ScenarioPath_ <- ScenariosPath_ar[index]
    ScenarioInProcess_ls[[ScenarioName_]] <- list()
    ScenarioLogFile <- paste0(ScenarioName_, ".txt")
    ScenarioLogFilePath <- file.path(ScenarioInputPath, ScenarioLogFile)
    if(file.exists(ScenarioLogFilePath)){
      file.remove(ScenarioLogFilePath)
    }
    file.create(ScenarioLogFilePath)
    write(print(paste0(Sys.time(),": Starting scenario: ",
                       ScenarioName_)), file = ScenarioLogFilePath, append = TRUE)
    taskName <- paste0("Scenario_", ScenarioName_)
    write(print(paste0(Sys.time(), ": Submitting scenario '",
                       ScenarioName_, "' to join ",
                       getNumberOfRunningTasks(asyncTasksRunning = ScenarioInProcess_ls),
                       " currently running tasks")), file = ScenarioLogFilePath,
          append = TRUE)
    ScenarioInProcess_ls[[ScenarioName_]] <-
      startAsyncTask(asyncTasksRunning = ScenarioInProcess_ls,
                     asyncTaskName = taskName,
                     futureObj = future({
                       currWd <- getwd()
                       on.exit(setwd(currWd))
                       write(print(paste0(Sys.time(),
                                          ": Running scenario: ",
                                          ScenarioName_)),
                             file = ScenarioLogFilePath, append = TRUE)
                       setwd(ScenarioPath_)
                       LogFile <- list.files(".",pattern = "Log")
                       if(length(LogFile) > 0){
                         file.remove(LogFile)
                       }
                       output <- capture.output(source("run_model.R"),
                                                file = file.path("..",
                                                                 paste0(
                                                                   ScenarioName_,
                                                                   ".txt")),
                                                append = TRUE)
                       return(output)
                     },
                     label = ScenarioName_,
                     globals = TRUE),
                     callback = function(asyncResults){
                       # asyncResults is: list(asyncTaskName,
                       #                        taskResult,
                       #                        startTime,
                       #                        endTime,
                       #                        elapsedTime,
                       #                        caughtError,
                       #                        caughtWarning)
                       # Check if the model run is finished by looking at the log
                       taskName_ <- asyncResults[["asyncTaskName"]]
                       taskResult <- asyncResults[["taskResult"]]
                       ScenarioName_ <- gsub("Scenario_", "", taskName_)
                       # Check if the log file exists
                       LogFilePath_ <- list.files(file.path(ModelPath,
                                                            L$Global$Model$ScenarioOutputFolder,
                                                            ScenarioName_),
                                                  pattern = "^Log")
                       msg <- ""
                       if(length(LogFilePath_)==0){
                         msg <- paste0("***ERROR*** Did not find the expected log file ",
                                       "for scenario: ", ScenarioName_)
                         print(msg)
                       } else if (length(LogFilePath_) > 1){
                         msg <- paste0("***ERROR*** More than 1 log file found.")
                         stop(msg)
                       }
                       ScenarioLogFile <- list.files(file.path(ModelPath,
                                                               L$Global$Model$ScenarioOutputFolder),
                                                     pattern = paste0(ScenarioName_,".txt"))
                       ScenarioLogFilePath <- file.path(ModelPath,
                                                        L$Global$Model$ScenarioOutputFolder,
                                                        ScenarioLogFile)
                       write(paste0("Log File: ", LogFilePath_),
                             file = ScenarioLogFilePath, append = TRUE)
                       if(is.null(taskResult)){
                         write(print(paste0(Sys.time(),
                                            ": Completed running scenario '",
                                            ScenarioName_, "'")),
                               file = ScenarioLogFilePath, append = TRUE)
                         RunScenariosFinishFlag_ar[ScenarioName_] <<- TRUE
                       } else {
                         write(print(msg),
                               file = ScenarioLogFilePath, append = TRUE)
                       }
                     },
                     debug = FALSE
      ) # end call to startAsyncTask
    # Update the scenario progress tracker
    Scenarios_df$Run[which(Scenarios_df$Name==ScenarioName_)] <- "Submitted"
    RunningTaskResults_ls <- processRunningTasks(
      asyncTasksRunning = ScenarioInProcess_ls,
      wait = FALSE,
      debug = TRUE,
      maximumTasksToResolve = 1
    )
    ScenarioInProcess_ls <- RunningTaskResults_ls[["asyncTasksRunning"]]

    # Update scenarios that are finished
    ScenarioNames_ <- gsub("Scenario_", "", names(ScenarioInProcess_ls))
    Scenarios_df$Run[!(Scenarios_df$Name %in% ScenarioNames_) &
                       Scenarios_df$Run %in% "Submitted" &
                       RunScenariosFinishFlag_ar[Scenarios_df$Name]] <- "Completed"
    Scenarios_df$Run[!(Scenarios_df$Name %in% ScenarioNames_) &
                       Scenarios_df$Run %in% "Submitted" &
                       !RunScenariosFinishFlag_ar[Scenarios_df$Name]] <- "Run Error"

    write.csv(Scenarios_df, file.path(ModelPath,
                                      L$Global$Model$ScenarioOutputFolder,
                                      "ScenarioProgressReport.csv"),
              row.names = FALSE)
  }

  RunningTaskResults_ls <- processRunningTasks(asyncTasksRunning = ScenarioInProcess_ls,
                                               wait = TRUE, debug = TRUE)

  ScenarioInProcess_ls <- RunningTaskResults_ls[["asyncTasksRunning"]]
  # Update scenarios that are finished
  ScenarioNames_ <- gsub("Scenario_", "", names(ScenarioInProcess_ls))
  Scenarios_df$Run[!(Scenarios_df$Name %in% ScenarioNames_) &
                     Scenarios_df$Run %in% "Submitted" &
                     RunScenariosFinishFlag_ar[Scenarios_df$Name]] <- "Completed"
  Scenarios_df$Run[!(Scenarios_df$Name %in% ScenarioNames_) &
                     Scenarios_df$Run %in% "Submitted" &
                     !RunScenariosFinishFlag_ar[Scenarios_df$Name]] <- "Run Error"
  write.csv(Scenarios_df, file.path(ModelPath,
                                    L$Global$Model$ScenarioOutputFolder,
                                    "ScenarioProgressReport.csv"),
            row.names = FALSE)

  # Close the future processors
  closeAllConnections()

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Global$Model <- list(CompleteRun = 1L)
  return(Out_ls)
}
