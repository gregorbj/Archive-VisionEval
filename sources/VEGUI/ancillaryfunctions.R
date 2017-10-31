#=======
# ancillaryfunctions.R
#=======

# This script contains the definition of functions needed to successfully run the application

########################################
### shinyFiles is incompatible with R v3.4.1. Two functions are overridden to make it compatible
### with R v3.4.1. The definitions of
### file.info() (base package) and fileGetter() (shinyFiles package) are written below
### Only override the functions if running R >= v3.4
#########################################
if(R.version$minor >= 4){
  # Define fileGetter (package: shinyFiles)
  fileGetter <-  function (roots, restrictions, filetypes, hidden = FALSE){
    if (missing(filetypes))
      filetypes <- NULL
    if (missing(restrictions))
      restrictions <- NULL
    function(dir, root) {
      currentRoots <- if (class(roots) == "function")
        roots()
      else roots
      if (is.null(names(currentRoots)))
        stop("Roots must be a named vector or a function returning one")
      if (missing(root))
        root <- names(currentRoots)[1]
      fulldir <- file.path(currentRoots[root], dir)
      writable <- as.logical(file.access(fulldir, 2) == 0)
      files <- list.files(fulldir, all.files = hidden, full.names = TRUE,
                          no.. = TRUE)
      files <- gsub(pattern = "//*", "/", files, perl = TRUE)
      if (!is.null(restrictions) && length(files) != 0) {
        if (length(files) == 1) {
          keep <- !any(sapply(restrictions, function(x) {
            grepl(x, files, fixed = T)
          }))
        }
        else {
          keep <- !apply(sapply(restrictions, function(x) {
            grepl(x, files, fixed = T)
          }), 1, any)
        }
        files <- files[keep]
      }
      # Changes to the original fileGetter are marked by # Changed
      fileInfo <- (file.info(files))
      fileInfo$filename <- basename(files)
      fileInfo$extension <- tolower(tools::file_ext(files)) # Changed
      validIndex <- which(!is.na(fileInfo$mtime)) # Changed
      fileInfo <- fileInfo[validIndex,] # Changed
      fileInfo$mtime <- format(fileInfo$mtime, format = "%Y-%m-%d-%H-%M")
      fileInfo$ctime <- format(fileInfo$ctime, format = "%Y-%m-%d-%H-%M")
      fileInfo$atime <- format(fileInfo$atime, format = "%Y-%m-%d-%H-%M")
      if (!is.null(filetypes)) {
        matchedFiles <- tolower(fileInfo$extension) %in%
          tolower(filetypes) & fileInfo$extension != ""
        fileInfo$isdir[matchedFiles] <- FALSE
        fileInfo <- fileInfo[matchedFiles | fileInfo$isdir,
                             ]
      }
      rownames(fileInfo) <- NULL
      breadcrumps <- strsplit(dir, .Platform$file.sep)[[1]]
      list(files = fileInfo[, c("filename", "extension", "isdir",
                                "size", "mtime", "ctime", "atime")], writable = writable,
           exist = file.exists(fulldir), breadcrumps = I(c("",
                                                           breadcrumps[breadcrumps != ""])), roots = I(names(currentRoots)),
           root = root)
    }
  } # end fileGetter

  # Override the original definition of fileGetter
  unlockBinding("fileGetter", getNamespace("shinyFiles"))
  assign("fileGetter",fileGetter,getNamespace("shinyFiles"))

  # Define fileGetter (package: base)
  file.info <- function (..., extra_cols = TRUE){
    suppressWarnings(res <- .Internal(file.info(fn <- c(...), extra_cols))) # Changed
    res$mtime <- .POSIXct(res$mtime)
    res$ctime <- .POSIXct(res$ctime)
    res$atime <- .POSIXct(res$atime)
    class(res) <- "data.frame"
    attr(res, "row.names") <- fn
    res
  } #end file.info

  # Override the original definition of fileGetter
  unlockBinding("file.info", getNamespace("base"))
  assign("file.info",file.info,getNamespace("base"))
} ### End of custom definitions for R >v3.4
