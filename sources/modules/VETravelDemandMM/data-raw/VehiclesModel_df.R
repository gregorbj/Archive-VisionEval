library(MASS)
library(tidyverse)
library(splines)
library(hydroGOF)

source("data-raw/EstModels.R")
if (!exists("Hh_df"))
  source("data-raw/LoadDataforModelEst.R")

#' convert Drivers and Vehicles to factor (require by polr)
Hh_df <- Hh_df %>%
  mutate(
    Drivers_f = as.factor(Drivers),
    Vehicles_f = as.factor(Vehicles)
  )

#' converting household data.frame to a list-column data frame
Model_df <- tibble(.id=1,
                train=list(Hh_df),
                test=train)

#' model formula as a tibble (data.frame), also include a
#' `post_func` column with functions de-transforming predictions to the original
#' scale of the dependent variable
Fmlas_df <- tribble(
  ~.id, ~model_name, ~post_func, ~fmla,
  1,       "ologit",  function(y) as.integer(as.character(y)),   ~polr(Vehicles_f ~ DrvAgePop + Workers + LogIncome + LifeCycle,
                                                                   data=., weights=.$hhwgt, na.action=na.exclude, Hess=TRUE)
)

#' call function to estimate models
Model_df <- Model_df %>%
  EstModelWith(Fmlas_df)

#' print model summary and goodness of fit
Model_df$model %>% map(summary)

#' trim model object to save space
VehiclesModel_df <- Model_df %>%
  dplyr::select(model, post_func) %>%
  mutate(model=map(model, TrimModel))

#' save Model_df to `data/`
devtools::use_data(VehiclesModel_df, overwrite = TRUE)
