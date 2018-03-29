#' Estimate TransitTFL (trip frequency and length) Models for households
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
  filter(AADVMT<quantile(AADVMT, .99, na.rm=T)) %>%
  nest(-metro) %>%
  rename(train=data) %>%
  mutate(test=train) # use the same data for train & test

#' model formula for each segment as a tibble (data.frame), also include a
#' `post_func` column with functions de-transforming predictions to the original
#' scale of the dependent variable
fmlas_df <- tribble(
  ~metro,  ~step, ~post_func,      ~fmla,
  "metro",    1,  function(y) y,   ~pscl::hurdle(TransitTrips ~ AADVMT+HhSize+LifeCycle+
                                                   Age0to14+D1B+TranRevMiPC+D4c |
                                                   AADVMT+VehPerDriver+HhSize+Workers+LifeCycle+Age0to14+D1B+
                                                   FwyLaneMiPC+TranRevMiPC:D4c,
                                                 data=., weights=.$hhwgt, na.action=na.omit),
  "metro",    2,  function(y) exp(y), ~lm(log(TransitAvgTripDist) ~ AADVMT + VehPerDriver + Age0to14 +
                                            Age65Plus + LogIncome + LifeCycle + D2A_EPHHM +
                                            D1B + D3bpo4 + D5 + TranRevMiPC + TranRevMiPC:D4c,
                                          data=., subset=(TransitAvgTripDist > 0), weights=.$hhwgt, na.action=na.omit),
  "non_metro",1,  function(y) y,   ~pscl::hurdle(TransitTrips ~  log1p(AADVMT)+log1p(VehPerDriver)+HhSize+LifeCycle+
                                                   Age0to14+LogIncome+D1B |
                                                   log1p(AADVMT)+log1p(VehPerDriver)+Workers+LifeCycle+Age0to14+D1B+D3bpo4+
                                                   LogIncome,
                                                 data=., weights=.$hhwgt, na.action=na.omit),
  "non_metro",2,  function(y) exp(y),  ~lm(log(TransitAvgTripDist) ~ AADVMT + Age0to14 +
                                             Age65Plus + LogIncome + LifeCycle + D2A_EPHHM +
                                             D1B + D5,
                                           data=., subset=(TransitAvgTripDist > 0), weights=.$hhwgt, na.action=na.omit)
)

#' call function to estimate models for each segment and add name for each
#' segment
model_df <- mm_df %>%
  EstModelWith(fmlas_df) %>%
  name_list.cols(name_cols=c("metro", "step"))

#' print model summary and goodness of fit
model_df$model %>% map(summary)
model_df #%>%
  #dplyr::select(metro, ends_with("rmse"), ends_with("r2")) %>%
  #group_by(metro) %>%
  #summarize_all(funs(mean))

#' trim model object to save space
TransitTFLModel_df <- model_df %>%
  dplyr::select(metro, model, post_func) %>%
  mutate(model=map(model, TrimModel))

#' save model_df to `data/`
devtools::use_data(TransitTFLModel_df, overwrite = TRUE)
