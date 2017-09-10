library(hydroGOF)
library(tidyverse)

source("R/DoPredictions.R")

#' trim from model object objects with large memory/space footprint and unnecessary for
#' model prediction (predict(model, data) call)
#' @param model a R model object
#' @return a trimmed model object with information unnecessary for `predict()` call stripped
#'
TrimModel <- function(model) {
  if ("zeroinfl" %in% class(model)) {
    model$model <- NULL
    environment(model$formula) <- new.env()
    environment(model$terms$full) <- new.env()
    environment(model$terms$zero) <- new.env()
    environment(model$terms$count) <- new.env()
  }

  if ("hurdle" %in% class(model)) {
    model$model <- NULL
    environment(model$formula) <- new.env()
    environment(model$terms$full) <- new.env()
    environment(model$terms$zero) <- new.env()
    environment(model$terms$count) <- new.env()
  }

  if ("polr" %in% class(model)) {
    model$model <- NULL
    environment(model$terms) <- new.env()
    model$fitted.values <- 0.0
    #model$na.action <- NULL
    model$lp <- NULL
    #model$qr$qr <- NULL
  }

  if ("lm" %in% class(model)) {
    model$model <- NULL
    environment(model$terms) <- new.env()
    model$fitted.values <- NULL
    model$residuals <- NULL
    model$qr$qr <- NULL
  }

  model
}

#' estimate models with data and formula arguments
#' needed for estimating models for corresponding formula within purrr::map2() call
#' @param data a list-column of data frame
#' @param formula a list-column of model formula
#' @return a list-column of resulted model object
EstModel <- function(data, formula, ...) {
  `.y(.x)`(data, formula, ...)
}

#' estimate models with a list-column data frame and formula (data frame)
#' @param data a list-column data frame of data to be used for estimation
#' @param fmla_df data a list-column data frame of the model formula
#' @return the list-column data frame `data` with columns for formula, model object, predictions, and model goodness-of-fit information added
EstModelWith <- function(data, fmla_df) {
  data %>%
  left_join(fmla_df) %>%
  mutate(model = map2(train, fmla, EstModel),
         # #y_train = map(train, resample_get, col_name="DVMT"),
         # #preds_train = map2(model, train, predict, type="response"),
         # #bias.adj = map(y_train, preds_train, ~mean(y_train/preds_train, na.rm=TRUE)),
         preds = map2(model, test, ~predict(.x, .y)),
         yhat = map2(preds, post_func, `.y(.x)`),
         y_name = map_chr(model, ~all.vars(terms(.))[1]),
         #y = map2(test, y_name, ~.x[[.y]]),
         y = map2(test, y_name, ~pull(.x, .y)),
         #rmse = map2_dbl(yhat, y, rmse),
         #nrmse = map2_dbl(yhat, y, nrmse),
         AIC=map_dbl(model, AIC),
         BIC=map_dbl(model, BIC)
         # compute McFadden's R2
         #r2_model0 = map2(model, train, ~update(.x, .~1, data=.y)),
         #r2_ll0 = map_dbl(r2_model0, logLik),
         #r2_ll1 = map_dbl(model, logLik),
         #pseudo.r2 = 1 - r2_ll1/r2_ll0
  ) %>%
  #add_pseudo_r2() %>%
  #dplyr::select(-c(test, train)) %>%
  dplyr::select(-starts_with("r2_"))
}

#' Assign names to elments of a list-column with values of specified column(s)
#' @param df data frame
#' @param name_cols a vector of columns whose value will be collapsed to use as name
#' @param col_to_be_named name of column to be named
#' @return data frame with named list-column(s)
#' @examples
#' require(tidyverse)
#' mtcars %>% nest(-c(cyl, vs)) %>%
#' name_list.cols(c("cyl", "vs")) %>%
#' map(names)
#'
name_list.cols <- function(df, name_cols="metro", col_to_be_named=NULL) {
  op_str <- paste0("paste(", paste(name_cols, collapse = ", "), ", sep='.')")
  df <- df %>% mutate_(name_cols=op_str)

  if (!is.null(col_to_be_named)) {
    names(df[[col_to_be_named]]) <- df[["name_cols"]]
  } else {
    #assign names to all list-columns
    for (n in 1:length(df)) {
      if ("list" %in% class(df[[n]]))
        names(df[[n]]) <- df[["name_cols"]]
    }
  }
  df["name_cols"] <- NULL
  df
}
