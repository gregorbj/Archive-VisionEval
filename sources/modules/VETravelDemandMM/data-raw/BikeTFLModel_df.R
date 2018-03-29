#' Estimate BikeTFL (trip frequency and length) Models for households
#'
library(tidyverse)
library(splines)
library(hydroGOF)

source("data-raw/EstModels.R")
if (!exists("Hh_df"))
  source("data-raw/LoadDataforModelEst.R")

#' converting household data.frame to a list-column data frame segmented by
#' metro ("metro" and "non-metro")
mm_df <- Hh_df %>%
  nest(-metro) %>%
  rename(train=data) %>%
  mutate(test=train) # use the same data for train & test

#' model formula for each segment as a tibble (data.frame), also include a
#' `post_func` column with functions de-transforming predictions to the original
#' scale of the dependent variable
fmlas_df <- tribble(
  ~metro,  ~step, ~post_func,      ~fmla,
  "metro",    1,  function(y) y,   ~pscl::hurdle(BikeTrips ~ AADVMT + Age0to14 + Age65Plus + D1B + D3bpo4 + Workers + LogIncome |
                                                   log1p(AADVMT) + HhSize + LifeCycle + Age0to14 + Age65Plus + D2A_EPHHM + D3bpo4 +
                                                   Workers + FwyLaneMiPC + TranRevMiPC + LogIncome,
                                                   data= ., weights=.$hhwgt, na.action=na.exclude),
  "metro",    2,  function(y) exp(y), ~lm(log(BikeAvgTripDist) ~ AADVMT + VehPerDriver + Age0to14 +
                                            Age65Plus + LogIncome + LifeCycle + D2A_EPHHM +
                                            D1B + D3bpo4 + TranRevMiPC + TranRevMiPC:D4c,
                                          data= ., weights=.$hhwgt, subset=(BikeAvgTripDist > 0), na.action=na.exclude),
  "non_metro",1,  function(y) y,   ~pscl::hurdle(BikeTrips ~  AADVMT + VehPerDriver + HhSize + LifeCycle + Age0to14 + Age65Plus + D1B +
                                                   Workers + LogIncome + D3bpo4 |
                                                   AADVMT + VehPerDriver + LifeCycle + Age0to14 + Age65Plus + D2A_EPHHM +
                                                   D5 + Workers + LogIncome + D3bpo4,
                                                         data= ., weights=.$hhwgt, na.action=na.exclude),
  "non_metro",2,  function(y) exp(y),  ~lm(log(BikeAvgTripDist) ~ AADVMT + Age0to14 +
                                             Age65Plus + LogIncome + LifeCycle + D2A_EPHHM + D1B + D5,
                                           data= ., weights=.$hhwgt, subset=(BikeAvgTripDist > 0), na.action=na.exclude)
)

#' call function to estimate models for each segment and add name for each
#' segment
model_df <- mm_df %>%
  EstModelWith(fmlas_df)   %>%
  name_list.cols(name_cols=c("metro", "step"))

#' print model summary and goodness of fit
model_df$model %>% map(summary)
model_df #%>%
  #dplyr::select(metro, ends_with("rmse"), ends_with("r2")) %>%
  #group_by(metro) %>%
  #summarize_all(funs(mean))

#' trim model object of information unnecessary for predictions to save space
BikeTFLModel_df <- model_df %>%
  dplyr::select(metro, model, post_func) %>%
  mutate(model=map(model, TrimModel))

#' save model_df to `data/`
devtools::use_data(BikeTFLModel_df, overwrite = TRUE)
