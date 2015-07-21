#synthesize_hh.r
#===============

# DEFINE FUNCTION TO CALCULATE AGE PROBABILITIES BY HOUSEHOLD TYPE
#=================================================================
#' Calculate age probabilities by household type.
#'
#' \code{calcAgeProbByHhType} calculates for each age group, the probability
#' that a person is the age category is found in each of the household types.
#'
#' This function tabulates the proportions of persons in each of six age groups
#' residing in each of several hundred household types. The six age groups are 0
#' to 14 years, 15 to 19 years, 20 to 29 years, 30 to 54 years, 55 to 64 years,
#' and 65 or more years. Household types are distinguished by the number of
#' people in each of the age groups in the household. Census Public Use
#' Microsample (PUMS) data for the region are used for the tabulation. Both the
#' person table and the housing unit tables are used. Only the SERIALNO and AGE
#' fields of the person table are used. Only the SERIALNO and HWEIGHT fields of
#' the housing unit table are used. The SERIALNO field is used to relate persons
#' to housing units. After persons are categorized by age group, they are joined
#' together in their respective households. Vacant housing units are removed and
#' households are categorized by the number of persons in each of the age
#' groups. Typically this will result in many hundreds of household types. The
#' total weighted persons by age category are summed by household type. The
#' HWEIGHT field is used to weight the number of persons in each household. The
#' number of household types is reduced by selecting the household types that
#' account for the large majority of households. By default, the threshold is
#' set to select household types which account for 0.99 of all households. This
#' reduces the number of household types to a few hundred. The threshold
#' parameter (Threshold) can be changed to increase or reduce the number of
#' selected households. After the household types have been selected, the
#' function calculates for each age group, the portion of persons in the age
#' group who are in each housing type. The result is a matrix where the rows
#' correspond to housing types and the columns correspond to age groups. Each
#' column sums to 1. The housing type names are the number of persons in each
#' age group (in chronological order) concatenated with hyphens (e.g.
#' 1-1-0-2-0-0).
#'
#' @param Prsn_df A data frame created from a PUMS person table. The columns of
#'   the data frame must be the SERIALNO and AGE fields from the PUMS person
#'   table and must use those names. The function will throw an error and stop
#'   if those columns are not in the data frame. The function will also throw an
#'   error and stop if any values are NA.
#' @param Hh_df A data frame created from a PUMS housing unit table. The columns
#'   of the data frame must be the SERIALNO and HWEIGHT fields from the PUMS
#'   housing unit table and must use those names. The function will throw an
#'   error and stop if those columns are not in the data frame. The function
#'   will also throw an error and stop if any values are NA or negative.
#' @param Threshold A scalar value greater than 0 and less than or equal to 1.
#'   This parameter determines the threshold to use for eliminating household
#'   types that account for a small portion of households. For example, the
#'   default value of 0.99 will keep those household types that account for 99%
#'   percent of households.
#' @return A matrix where rows represent housing types and columns represent age
#'   groups. The values are the proportions of persons in each age group found
#'   in each household type. The sum of each column is 1.
#' @examples
#' \dontrun{
#' PumsPersons_df <- read.csv(system.file("extdata", "pums_person.csv", package="hhage"))
#' PumsHousing_df <- read.csv(system.file("extdata", "pums_housing.csv", package="hhage"))
#' HtProb_HtAp <- calcAgeProbByHhType(PumsPersons_df, PumsHousing_df)
#' }
calcAgeProbByHhType <- function(Prsn_df, Hh_df, Threshold=0.99) {

  # Check and process inputs
  #-------------------------
  # Check that minimum required fields exist
  PrsnFields_vc <- c("SERIALNO", "AGE")
  HasPrsnFields_vc <- PrsnFields_vc %in% names(Prsn_df)
  HhFields_vc <- c("SERIALNO", "HWEIGHT")
  HasHhFields_vc <- HhFields_vc %in% names(Hh_df)
  if (any(!HasPrsnFields_vc) | any(!HasHhFields_vc)) {
    Msg <- paste("Person file must have SERIALNO and AGE fields.",
                  "Household file must have SERIALNO and HWEIGHT fields.")
    stop(Msg)
  }
  # Check that AGE and HWEIGHT have appropriate values
  if (any(is.na(Hh_df$HWEIGHT))) {
    stop("HWEIGHT in Hh_df has NA values.")
  }
  if (any(Hh_df$HWEIGHT < 0)) {
    stop("HWEIGHT in Hh_df has negative values.")
  }
  if (any(is.na (Prsn_df$AGE))) {
    stop("AGE in Prsn_df has NA values.")
  }
  if (any(Prsn_df$AGE < 0)) {
    stop("AGE in Prsn_df has negative values.")
  }
  # Check that Threshold has appropriate value
  if (!(Threshold > 0 & Threshold <= 1)) {
    stop("Threshold must be greater than 0 and less than or equal to 1.")
  }
  # Convert SERIALNO to character
  Prsn_df$SERIALNO <- as.character(Prsn_df$SERIALNO)
  Hh_df$SERIALNO <- as.character(Hh_df$SERIALNO)
  # Remove housing records not associated with persons (i.e. vacant)
  Hh_df <- Hh_df[Hh_df$SERIALNO %in% Prsn_df$SERIALNO, ]

  # Calculate population proportions by household type
  #---------------------------------------------------
  # Assign number of persons by age category to each household
  Ap <- c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64",
          "Age65Plus")
  MaxAge <- max(Prsn_df$AGE)
  AgeBreaks <- c(0, 14, 19, 29, 54, 64, MaxAge)
  Prsn_df$AgeCat <- cut(Prsn_df$AGE, breaks=AgeBreaks, include.lowest=TRUE,
                         right=TRUE, labels=Ap)
  for (ap in Ap) {
    NumAgeCatByHh_vc <- table(Prsn_df$SERIALNO[Prsn_df$AgeCat == ap])
    Hh_df[[ap]] <- 0
    Hh_df[[ap]][match(names(NumAgeCatByHh_vc), Hh_df$SERIALNO)] <-
      NumAgeCatByHh_vc
  }
  # Remove infrequent household categories
  Hh_df$HsldType <- apply(Hh_df[,Ap], 1, function(x) paste(x, collapse = "-"))
  NumHh_Ht <- tapply(Hh_df$HWEIGHT, Hh_df$HsldType, sum)
  PropHsld_Ht <- NumHh_Ht / sum(NumHh_Ht)
  CumProp_Ht <- cumsum(rev(sort(PropHsld_Ht)))
  Ht <- names(CumProp_Ht)[CumProp_Ht <= Threshold]
  Hh_df <- Hh_df[Hh_df$HsldType %in% Ht, ]
  # Calculate and return age proportions by HsldType
  NumPrsn_HhAp <- as.matrix(sweep(Hh_df[, Ap], 1, Hh_df$HWEIGHT, "*"))
  NumPrsn_HtAp <- apply(NumPrsn_HhAp, 2, function(x) {
    tapply(x, Hh_df$HsldType, sum)[Ht]})
  sweep(NumPrsn_HtAp, 2, colSums(NumPrsn_HtAp), "/")
}

# DEFINE FUNCTION TO SYNTHESIZE HOUSEHOLDS FROM COUNT OF PERSONS BY AGE GROUP
#============================================================================
#' Synthesize a set of households from count of persons by age group.
#'
#' \code{createHhByAge} Creates a set of households to accommodate a population
#' of persons by age group and reflects the household composition of the region.
#'
#' This function creates a set of households to accommodate a population of
#' persons by age group, which also reflects the household composition of the
#' region. The function works by creating an initial allocation of persons by age
#' to household types using the matrix of probabilities created by the
#' calcAgeProbByHhType function and then using an iterative proportional fitting
#' (IPF) process to produce the final allocations. The IPF process is necessary
#' because the household type probabilities by age group are calculated as though
#' household type is a characteristic of individual persons, whereas household
#' type is really a joint characteristic of multiple persons in the household.
#' The number of persons allocated to each age group of a household type must be
#' reconciled to be consistent with the definition of the household type. For
#' example, consider the case of a household type defined as having 2 persons
#' aged 0-14 and 2 persons aged 20-29. If 1000 persons ages 0-14 are allocated to
#' that household type and 1200 persons aged 20-29 are also allocated, there
#' would be an inconsistency in the number of households of that type (500 vs.
#' 600 households). The algorithm uses the mean of the household estimates to
#' determine the reconciled number of households of the type. It then calculates
#' the corresponding reconciled population by age group. The difference in total
#' population by age group between the input and the reconciled population is
#' then reallocated to the households by type. These steps are repeated until the
#' reconciled population of age group is within 0.1% of the input population for
#' the corresponding age group (or until a maximum number of iterations
#' transpires.)
#'
#' @param Prsn_Ap A named vector of the number of persons by age group. The names
#'   must correspond to the age group names.
#' @param HtProb_HtAp A matrix where rows represent housing types and columns
#'   represent age groups. The values are the proportions of persons in each age
#'   group found in each household type. The sum of each column is 1. The matrix
#'   is created from Census PUMS data using calcAgeProbByHhType.
#' @param MaxIter A scalar integer defining the maximum number of iterations of
#'   the IPF to reconcile household composition and input population by age
#'   group.
#' @return A list of synthetic households having 7 components. Each component is
#'   a vector where the each element is the value for a household. The first
#'   component contains household ID numbers. The next 6 components contain the
#'   numbers of persons in each of the 6 age groups ("Age0to14", "Age15to19",
#'   "Age20to29", "Age30to54", "Age55to64","Age65Plus").
createHhByAge <- function(Prsn_Ap = c(Age0to14, Age15to19, Age20to29,
                                      Age30to54, Age55to64, Age65Plus),
                          HtProb_HtAp, MaxIter = 100) {
  # Initialize
  #-----------
  Ap <- colnames(HtProb_HtAp)
  Ht <- rownames(HtProb_HtAp)
  # Place persons by age into household types by multiplying person vector
  # by probabilities
  Prsn_HtAp <- sweep(HtProb_HtAp, 2, Prsn_Ap, "*")
  # Make table of factors to convert persons into households and vise verse
  PrsnFactors_Ht_Ap <-
    lapply(strsplit(Ht, "-"), function(x)
      as.numeric(x))
  PrsnFactors_HtAp <- do.call(rbind, PrsnFactors_Ht_Ap)
  dimnames(PrsnFactors_HtAp) <- dimnames(Prsn_HtAp)
  rm(PrsnFactors_Ht_Ap)

  # Iterate until "balanced" set of households is created
  #------------------------------------------------------
  # Create vector to store convergence indicator
  MaxDiff_ <- numeric(MaxIter)
  for (i in 1:MaxIter) {
    # Convert population into households
    Hh_HtAp <- Prsn_HtAp / PrsnFactors_HtAp
    Hh_HtAp[is.na(Hh_HtAp)] <- 0
    # Resolve differences in household type estimates
    # Do not include zero household estimates
    ResolveHh_HtAp <- t(apply(Hh_HtAp, 1, function(x) {
      if (sum(x > 0) > 1) {
        x[x > 0] <- mean(x[x > 0])
      }
      x
    }))
    # Exit if the difference between the maximum estimate for each
    # household type is not too different than the resolved estimate
    # for each household type
    MaxHh_Ht <- apply(Hh_HtAp, 1, max)
    ResolveHh_Ht <- apply(ResolveHh_HtAp, 1, max)
    Diff_Ht <- abs(MaxHh_Ht - ResolveHh_Ht)
    PropDiff_Ht <- Diff_Ht / ResolveHh_Ht
    if (all(PropDiff_Ht < 0.001))
      break
    MaxDiff_[i] <- max(PropDiff_Ht)
    # Calculate the number of persons for mean households
    ResolvePrsn_HtAp <- ResolveHh_HtAp * PrsnFactors_HtAp
    # Convert the mean persons tabulation into probabilities
    PrsnProb_HtAp <-
      sweep(ResolvePrsn_HtAp, 2, colSums(ResolvePrsn_HtAp), "/")
    # Calculate the difference in the number of persons by age category
    PrsnDiff_Ap <- Prsn_Ap - colSums(ResolvePrsn_HtAp)
    # Allocate extra persons to households based on probabilities
    AddPrsn_HtAp <- sweep(PrsnProb_HtAp, 2, PrsnDiff_Ap, "*")
    # Add to the persons in the mean households
    Prsn_HtAp <- ResolvePrsn_HtAp + AddPrsn_HtAp
    # Warn if exit loop because MaxIter reached
    if (i == MaxIter) {
      warning("No convergence of household synthesis after 100 iterations.")
    }
  }

  # Convert to synthetic households
  #--------------------------------
  # Calculate number of households by household type
  Hh_Ht <- round(apply(ResolveHh_HtAp, 1, max))
  # Calculate persons by age group and household type
  Prsn_HtAp <- sweep(PrsnFactors_HtAp, 1, Hh_Ht, "*")
  # Convert into a synthetic population of households
  Hh_Hh <- rep(names(Hh_Ht), Hh_Ht)
  Hh_Hh_Ap <- strsplit(Hh_Hh, "-")
  Hh_Hh_Ap <- lapply(Hh_Hh_Ap, function(x)
    as.numeric(x))
  Hh_HhAp <- do.call(rbind, Hh_Hh_Ap)
  colnames(Hh_HhAp) <- Ap
  # Put in random order
  Hh_HhAp <- Hh_HhAp[sample(1:nrow(Hh_HhAp), nrow(Hh_HhAp), replace = FALSE),]
  # Calculate household size
  HhSize_Hh <- rowSums(Hh_HhAp)
  # Return a list with the household attributes
  list(HhId = 1:nrow(Hh_HhAp), Age0to14 = Hh_HhAp[, "Age0to14"],
       Age15to19 = Hh_HhAp[, "Age15to19"], Age20to29 = Hh_HhAp[, "Age20to29"],
       Age30to54 = Hh_HhAp[, "Age30to54"], Age55to64 = Hh_HhAp[, "Age55to64"],
       Age65Plus = Hh_HhAp[, "Age65Plus"], HhSize = HhSize_Hh)
}

# DEFINE FUNCTION TO BUILD MODEL
#===============================
#' Build the model object
#'
#' \code{buildModel} Creates a RSPM model object to implement the household age model.
#'
#' The buildModel function creates a model object which can be applied in the RSPM framework. The calcAgeProbByHhType function is invoked to estimate a household probability table which represents the region. The user must put the required inputs in the "inst/extdata" directory. The table is added as a parameter to the model object. The createHhByAge function is
buildModel <- function() {
  # Initialize list to store model components
  Model_ls <- list()
  # Estimate the matrix of age group probabilities
  PrsnInput_df <- read.csv("inst/extdata/pums_person.csv", as.is=TRUE)
  HhInput_df <- read.csv("inst/extdata/pums_housing.csv", as.is=TRUE)
  HtProb_HtAp <- calcAgeProbByHhType(PrsnInput_df, HhInput_df)
  # Add model parameters to list
  Model_ls$HtProb_HtAp <- HtProb_HtAp
  # Add model functions to list
  Model_ls$Main <- createHhByAge
  # Identify the geographic level to iterate over
  Model_ls$RunBy <- "Division"
  # Identify data to be loaded from data store
  Model_ls$Get$Division <- c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64",
                      "Age65Plus")
  # Identify data to store
  Model_ls$Set$Household <- c("HhId", "Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64",
                       "Age65Plus", "HhSize")
  # Return the model object
  Model_ls
}
SynthesizeHh <- buildModel()

