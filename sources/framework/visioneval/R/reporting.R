#===========
#reporting.R
#===========

#This script defines functions that are used to create reports from model run
#results by reading from one or more tables in datastores and preparing
#summaries.

#READ MULTIPLE DATASETS FROM DATASTORES
#======================================
#' Read multiple datasets from multiple tables in datastores
#'
#' \code{readDatastoreTables} a visioneval framework model user function that
#' reads datasets from one or more tables in a specified group in one or more
#' datastores
#'
#' This function can read multiple datasets in one or more tables in a group.
#' More than one datastore my be specified so that if datastore references are
#' used in a model run, datasets from the referenced datastores may be queried
#' as well. Note that the capability for querying multiple datastores is only
#' for the purpose of querying datastores for a single model scenario. This
#' capability should not be used to compare multiple scenarios. The function
#' does not segregate datasets by datastore. Attempting to use this function to
#' compare multiple scenarios could produce unpredictable results.
#'
#' @param Tables_ls a named list where the name of each component is the name of
#' a table in a datastore group and the value is a string vector of the names
#' of the datasets to be retrieved.
#' @param Group a string that is the name of the group to retrieve the table
#' datasets from.
#' @param DstoreLocs_ a string vector identifying the paths to all of the
#' datastores to extract the datasets from. Each entry must be the full relative
#' path to a datastore (e.g. 'tests/Datastore').
#' @param DstoreType a string identifying the type of datastore
#' (e.g. 'RD', 'H5'). Note
#' @return A named list having two components. The 'Data' component is a list
#' containing the datasets from the datastores where the name of each component
#' of the list is the name of a table from which identified datasets are
#' retrieved and the value is a data frame containing the identified datasets.
#' The 'Missing' component is a list which identifies the datasets that are
#' missing in each table.
#' @export
readDatastoreTables <- function(Tables_ls, Group, DstoreLocs_, DstoreType) {
  #Check that DstoreTypes are supported
  AllowedDstoreTypes_ <- c("RD", "H5")
  if (!DstoreType %in% AllowedDstoreTypes_) {
    Msg <-
      paste0("Specified 'DatastoreType' in the 'run_parameters.json' file - ",
             DstoreType, " - is not a recognized type. ",
             "Recognized datastore types are: ",
             paste(AllowedDstoreTypes_, collapse = ", "), ".")
    stop(Msg)
  }
  #Check that DstoreLocs_ are correct
  DstoreLocsExist_ <- sapply(DstoreLocs_, function(x) file.exists(x))
  if (any(!DstoreLocsExist_)) {
    Msg <-
      paste0("One or more of the specified DstoreLocs_ can not be found. ",
             "Maybe they are misspecified. Check the following: ",
             DstoreLocs_[!DstoreLocsExist_])
    stop(Msg)
  }
  #Assign datastore reading functions
  DstoreFuncs_ <- c("readFromTable", "listDatastore")
  for(DstoreFunc in DstoreFuncs_) {
    assign(DstoreFunc, get(paste0(DstoreFunc, DstoreType)))
  }
  #Get model states for each datastore
  MS_ls <- lapply(DstoreLocs_, function(x) {
    SplitRef_ <- unlist(strsplit(x, "/"))
    RefHead <- paste(SplitRef_[-length(SplitRef_)], collapse = "/")
    if (RefHead == "") {
      ModelStateFile <- "ModelState.Rda"
    } else {
      ModelStateFile <- paste(RefHead, "ModelState.Rda", sep = "/")
    }
    readModelState(FileName = ModelStateFile)$Datastore
  })
  names(MS_ls) <- DstoreLocs_
  #Get data from table
  Tb <- names(Tables_ls)
  Out_ls <- list()
  for (tb in Tb) {
    Out_ls[[tb]] <- list()
    Ds <- Tables_ls[[tb]]
    for (Loc in DstoreLocs_) {
      HasTable <- checkTableExistence(tb, Group, MS_ls[[Loc]])
      if (HasTable) {
        for (ds in Ds) {
          HasDataset <- checkDataset(ds, tb, Group, MS_ls[[Loc]])
          if (HasDataset) {
            if (is.null(Out_ls[[tb]][[ds]])) {
              Out_ls[[tb]][[ds]] <- readFromTable(ds, tb, Group, Loc, ReadAttr = TRUE)
            }
          }
        }
      }
    }
    Out_ls[[tb]] <- data.frame(Out_ls[[tb]])
  }
  #Identify missing datasets
  OutDsetNames_ls <- lapply(Out_ls, names)
  Missing_ls <- Tables_ls
  for (tb in Tb) {
    Missing_ls[[tb]] <- Tables_ls[[tb]][!(Tables_ls[[tb]] %in% OutDsetNames_ls[[tb]])]
  }
  #Return the table data
  list(Data = Out_ls, Missing = Missing_ls)
}

#Example
#-------
# TableRequest_ls <- list(
#   Household = c("Bzone", "HhSize", "Workers", "Income", "Dvmt", "NumVeh"),
#   Bzone = c("Bzone", "D1B", "MFDU", "SFDU"),
#   Qzone = c("Bzone", "Azone")
# )
# TableResults_ls <-
#   readDatastoreTables(
#     Tables_ls = TableRequest_ls,
#     Group = "2010",
#     DstoreLocs_ = c("tests/Datastore", "../VELandUse/tests/Datastore"),
#     DstoreType = "RD")
# lapply(TableResults_ls$Data, head)
