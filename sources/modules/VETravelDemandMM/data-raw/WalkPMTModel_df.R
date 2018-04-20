#' Estimate TransitPMT Models for households
#'
library(tidyverse)
library(splines)
library(hydroGOF)

source("data-raw/EstModels.R")
if (!exists("Hh_df"))
  source("data-raw/LoadDataforModelEst.R")

#' converting household data.frame to a list-column data frame segmented by
#' metro ("metro" and "non-metro")
Model_df <- Hh_df %>%
  filter(AADVMT<quantile(AADVMT, .99, na.rm=T)) %>%
  nest(-metro) %>%
  rename(train=data) %>%
  mutate(test=train) # use the same data for train & test

int_round <- function(x) as.integer(round(x))
int_cround <- function(x) as.integer(ifelse(x<1, ceiling(x), round(x)))
fctr_round1 <- function(x) as.factor(round(x, digits=1))

#' model formula for each segment as a tibble (data.frame), also include a
#' `post_func` column with functions de-transforming predictions to the original
#' scale of the dependent variable
Fmlas_df <- tribble(
  ~name,   ~metro,      ~post_func,      ~fmla,
  "hurdle", "metro",    function(y) y,   ~pscl::hurdle(int_cround(WalkPMT) ~ AADVMT + Workers + VehPerDriver +
                                                          LifeCycle + Age0to14 + CENSUS_R + D1B+D2A_EPHHM + FwyLaneMiPC + TranRevMiPC:D4c +
                                                            D5 + D3bpo4 |
                                                            AADVMT + Workers + LifeCycle + Age0to14 + CENSUS_R +  D1B:D2A_EPHHM + D3bpo4
                                                          + D5 + TranRevMiPC,
                                                        data= ., weights=.$hhwgt, na.action=na.exclude),
  "hurdle", "non_metro",function(y) y,   ~pscl::hurdle(int_cround(WalkPMT) ~ AADVMT + HhSize + VehPerDriver +
                                                              LifeCycle + Age0to14 + Age65Plus + CENSUS_R + D1B + D1B:D2A_EPHHM + D3bpo4 |
                                                              AADVMT + Workers + LogIncome + HhSize +
                                                              Age0to14 + CENSUS_R + D3bpo4 + D5,
                                                            data= ., weights=.$hhwgt, na.action=na.exclude)
)

#' call function to estimate models for each segment and add name for each
#' segment
Model_df <- Model_df %>%
  EstModelWith(Fmlas_df) %>%
  name_list.cols(name_cols=c("metro"))

#' print model summary and goodness of fit
Model_df$model %>% map(summary)
Model_df #%>% dplyr::select(name, metro, preds, yhat, y)

#' trim model object to save space
WalkPMTModel_df <-  Model_df %>%
  dplyr::select(metro, model, post_func) %>%
  mutate(model=map(model, TrimModel))

#' save Model_df to `data/`
devtools::use_data(WalkPMTModel_df, overwrite = TRUE)
