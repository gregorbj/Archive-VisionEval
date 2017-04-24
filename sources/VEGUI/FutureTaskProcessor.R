if (!require(future)) install.packages("future")
library(future)
#FutureTaskProcessor.R https://gist.github.com/PeterVermont/a4a29d2c6b88e4ee012a869dedb5099c#file-futuretaskprocessor-r

#NOTE: the file that 'source's this should also call plan(multiprocess, workers=<desired number of workers>) for example:
#plan(multiprocess, workers=min((myNumTasks+1), MAX_PROCESSES))
#it is not required to specify workers -- if not then it will default to future::availableCores()
#use myNumTasks+1 because future uses one process for itself.

asyncTasksRunning <- list()

startAsyncTask <-
  function(asyncTaskName,
           futureObj,
           callback = NULL,
           debug = FALSE) {
    submitTime = Sys.time()

    if (futureObj$lazy) {
      warning(
        paste0(
          "startAsyncTask futureObj  has lazy=TRUE! '",
          asyncTaskName,
          "' will not be started until processRunningTasks is called with wait=TRUE and will then only run one item at a time!"
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
    asyncTasksRunning[[asyncTaskName]] <<- asyncTaskObject
  } #end startAsyncTask


getRunningTasksStatus <- function() {
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
  runningTasksStatus <-
    paste(
      Sys.time(),
      ": # of running tasks: ",
      length(asyncTasksRunning),
      paste0(collapse = ", ", lapply(
        asyncTasksRunning, getRunningTaskStatus
      ))
    )
  return(runningTasksStatus)
} #end getRunningTasksStatus

#' Meant to called periodically, this will check all running asyncTasks for completion
#' Returns number of remaining tasks so could be used as a boolean
processRunningTasks <-
  function(wait = FALSE,
           catchErrors = TRUE,
           debug = FALSE,
           maximumTasksToResolve = NULL)
  {
    if (!is.null(maximumTasksToResolve) &&
        (maximumTasksToResolve < 1)) {
      stop(
        paste0(
          "processRunningTasks called with maximumTasksToResolve=",
          maximumTasksToResolve,
          " which does not make sense. It must be greater than 0 if specified"
        )
      )
    }

    functionStartTime <- Sys.time()
    numTasksResolved <- 0
    for (asyncTaskName in names(asyncTasksRunning)) {
      if (!is.null(maximumTasksToResolve) &&
          (numTasksResolved >= maximumTasksToResolve)) {
        if (debug)
          print(
            paste0(
              Sys.time(),
              ": processRunningTasks: stopping checking for resolved tasks because maximumTasksToResolve (",
              maximumTasksToResolve,
              ") already resolved."
            )
          )
        break
      } #end checking if need to break because of maximumTasksToResolve
      asyncTaskObject <- asyncTasksRunning[[asyncTaskName]]
      asyncFutureObject <- asyncTaskObject[["futureObj"]]
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
        taskResult <- NULL
        numTasksResolved <- numTasksResolved + 1
        #NOTE future will send any errors it caught when we ask it for the value -- same as if we had evaluated the expression ourselves
        caughtError <- NULL
        caughtWarning <- NULL
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
        }
        rm(asyncFutureObject)
        submitTime <- asyncTaskObject[["submitTime"]]
        endTime <- Sys.time()
        elapsedTime <- format(endTime - submitTime)
        if (debug)
          print(
            paste0(
              Sys.time(),
              ": processRunningTasks finished: '",
              asyncTaskName,
              "'. submitTime: ",
              submitTime,
              ", endTime: ",
              endTime,
              "', elapsed time: ",
              elapsedTime
            )
          )
        callback <- asyncTaskObject[["callback"]]
        asyncTasksRunning[[asyncTaskName]] <<- NULL
        if (!is.null(callback)) {
          callback(
            list(
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
    return(length(asyncTasksRunning))
  } # end processRunningTasks

fakeDataProcessing <- function(name, duration, sys_sleep = FALSE) {
  if (sys_sleep) {
    Sys.sleep(duration)
  } else {
    start_time <- Sys.time()
    repeat {
      elapsed_time = Sys.time() - start_time
      print(paste0(
        Sys.time(),
        ": ",
        name,
        " elapsed time: ",
        format(elapsed_time)
      ))
      if (elapsed_time < duration) {
        Sys.sleep(1)
      } else {
        break
      }
    } #end repeat
  } #end else not using long sleep
  return(data.frame(name = name, test = Sys.time()))
} #end fakeDataProcessing


testAsync <- function(loops = future::availableCores() - 1) {
  plan(multiprocess)
  print(paste0("future::availableCores(): ", future::availableCores()))
  loops <- 10 #
  baseWait <- 3
  for (loopNumber in 1:loops) {
    duration <- baseWait + loopNumber
    dataName <-
      paste0("FAKE_PROCESSED_DATA_testLoop-",
             loopNumber,
             "_duration-",
             duration)
    startAsyncTask(
      dataName,
      futureObj = future(lazy = FALSE, expr = fakeDataProcessing(dataName, duration)),
      debug = TRUE
    )

    #NOTE: if the future is created with lazy=TRUE then the process will not be kicked off until value() is called on it. resolved(futureObj) does not kick it off
    processRunningTasks(wait = FALSE, debug = TRUE)
  } #end loop

  #wait until all tasks are finished
  processRunningTasks(wait = TRUE, debug = TRUE)

  print(paste0(
    "At the end the status should have no running tasks: ",
    getRunningTasksStatus()
  ))
} #end testAsync
#testAsync()
