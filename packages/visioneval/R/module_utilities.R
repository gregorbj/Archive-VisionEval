#==================
#module_utilities.R
#==================

#This script defines functions that may be used by modules. Presently it only
#includes functions for formatting input, get and set specifications, and a
#function to log messages. This script will be expanded to include functions
#that will assist module developers to develop and test their modules and
#packages.

#DEFINE ALIASES FOR LIST FUNCTION
#================================
#' Alias for list function.
#'
#' \code{item} is an alias for the list function whose purpose is to make
#' module specifications easier to read.
#'
#' This function defines an alternate name for list. It is used in module
#' specifications to identify data items in the Inp, Get, and Set portions of
#' the specifications.
#'
#' @return a list.
#' @export
item <- function(...) {
  list(...)
}

#' Alias for list function.
#'
#' \code{items} is an alias for the list function whose purpose is to make
#' module specifications easier to read.
#'
#' This function defines an alternate name for list. It is used in module
#' specifications to identify a group of data items in the Inp, Get, and Set
#' portions of the specifications.
#'
#' @return a list.
#' @export
items <- function(...) {
  list(...)
}

#DEFINE FUNCTION FOR WRITING A MESSAGE TO THE LOG
#================================================
#' Writes message to run log.
#'
#' \code{writeLog} writes a message to the run log.
#'
#' This function writes a message in the form of a string to the run log. It
#' logs the time as well as the message to the run log.
#'
#' @param Msg A character string.
#' @return The function has no return value. It appends the time and the message
#'   text to the run log.
#' @export
writeLog <- function(Msg = "") {
  Con <- file(E$LogFile, open = "a")
  Time <- as.character(Sys.time())
  Content <- paste(Time, ":", Msg, "\n")
  writeLines(Content, Con)
  close(Con)
}
