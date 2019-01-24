#test_functions.R
#
setUpTests <- function(TestSetup_ls) {
  with(TestSetup_ls, {
    #Copy datastore if required
    if (LoadDatastore) {
      DatastorePath <- file.path(TestDataRepo, DatastoreName)
      file.copy(DatastorePath, file.path("tests", DatastoreName))
      if (DatastoreName == "Datastore.tar") {
        setwd("tests")
        untar("Datastore.tar")
        file.remove("Datastore.tar")
        setwd("..")
      }
    }
    #Copy defs directory
    dir.create("tests/defs")
    DefsPath <- file.path(TestDataRepo, "defs")
    file.copy(DefsPath, "tests", recursive = TRUE)
    #Copy inputs directory
    dir.create("tests/inputs")
    InputsPath <- file.path(TestDataRepo, "inputs")
    file.copy(InputsPath, "tests", recursive = TRUE)
    #Create test documentation directory if it doesn't exist
    if (!file.exists(file.path("tests", TestDocsDir))) {
      dir.create(file.path("tests", TestDocsDir))
      dir.create(file.path("tests", TestDocsDir, "logs"))
    } else {
      #Clear log files if directed
      if (ClearLogs) {
        dir.remove(file.path("tests", TestDocsDir, "logs"))
        dir.create(file.path("tests", TestDocsDir, "logs"))
      }
    }
  })
}

doTests <- function(Tests_ls, TestSetup_ls) {
  ModuleNames_ <- names(Tests_ls)
  TestDocsDir <- TestSetup_ls$TestDocsDir
  for (mn in ModuleNames_) {
    source(paste0("R/", mn, ".R"))
    L <- Tests_ls[[mn]]
    if (!("RunFor" %in% names(L))) {
      testModule(
        ModuleName = mn,
        LoadDatastore = L["LoadDatastore"],
        SaveDatastore = L["SaveDatastore"],
        DoRun = L["DoRun"]
      )
    } else {
      testModule(
        ModuleName = mn,
        LoadDatastore = L["LoadDatastore"],
        SaveDatastore = L["SaveDatastore"],
        DoRun = L["DoRun"],
        RunFor = L["RunFor"]
      )
    }
    LogFile <- paste0("Log_", mn, ".txt")
    file.copy(
      file.path("tests", LogFile),
      file.path("tests", TestDocsDir, "logs", LogFile))
    file.remove(file.path("tests", LogFile))
  }
}

saveTestResults <- function(TestSetup_ls) {
  with(TestSetup_ls, {
    #Tar the datastore directory if DatastoreName is Datastore.tar
    if (DatastoreName == "Datastore.tar") {
      setwd("tests")
      tar("Datastore.tar", "Datastore")
      dir.remove("Datastore")
      setwd("..")
    }
    #Copy the datastore
    file.copy(
      file.path("tests", DatastoreName),
      file.path(TestDataRepo, DatastoreName)
    )
    file.remove(file.path("tests", DatastoreName))
    #Remove the defs directory
    dir.remove("tests/defs")
    #Remove the inputs directory
    dir.remove("tests/inputs")
    #Move the model state file to the test documentation directory
    file.copy(
      file.path("tests", "ModelState.Rda"),
      file.path("tests", TestDocsDir, "ModelState.Rda"))
    file.remove(file.path("tests", "ModelState.Rda"))
  })
}

