library(shinytest)
library(testthat)

tests_dir <- file.path(".","tests")
tests_dir <- normalizePath(tests_dir)

if(dir.exists(tests_dir)){
  test_that("Application Runs",{
    source(file.path(tests_dir,"opentest.R"))
  })
} else {
  stop("Tests do not exist!")
}

