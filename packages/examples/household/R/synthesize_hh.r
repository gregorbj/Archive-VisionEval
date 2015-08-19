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

# DEFINE FUNCTION TO CREATE INVENTORY OF HOUSEHOLD AGE TYPES
#===========================================================
#' Create a tabulation of household age types by geographic division.
#'
#' \code{tabulateHhAgeType} Creates an tabulation of household age types to
#' accommodate a population of persons by age group and reflects the household
#' composition of the region.
#'
#' This function creates an inventory of household age types to accommodate a
#' population of persons by age group, which also reflects the household
#' composition of the region. The function works by creating an initial
#' allocation of persons by age to household age types using the matrix of
#' probabilities created by the calcAgeProbByHhType function and then using an
#' iterative proportional fitting (IPF) process to produce the final
#' allocations. The IPF process is necessary because the household type
#' probabilities by age group are calculated as though household type is a
#' characteristic of individual persons, whereas household type is really a
#' joint characteristic of multiple persons in the household. The number of
#' persons allocated to each age group of a household type must be reconciled to
#' be consistent with the definition of the household type. For example,
#' consider the case of a household type defined as having 2 persons aged 0-14
#' and 2 persons aged 20-29. If 1000 persons ages 0-14 are allocated to that
#' household type and 1200 persons aged 20-29 are also allocated, there would be
#' an inconsistency in the number of households of that type (500 vs. 600
#' households). The algorithm uses the mean of the household estimates to
#' determine the reconciled number of households of the type. It then calculates
#' the corresponding reconciled population by age group. The difference in total
#' population by age group between the input and the reconciled population is
#' then reallocated to the households by type. These steps are repeated until
#' the reconciled population of age group is within 0.1% of the input population
#' for the corresponding age group (or until a maximum number of iterations
#' transpires.)
#'
#' @param Age0to14_Dv An integer vector of the number of persons of age from 0
#'   to 14 by division.
#' @param Age15to19_Dv An integer vector of the number of persons of age from 15
#'   to 19 by division.
#' @param Age20to29_Dv An integer vector of the number of persons of age from 20
#'   to 29 by division.
#' @param Age30to54_Dv An integer vector of the number of persons of age from 30
#'   to 54 by division.
#' @param Age55to64_Dv An integer vector of the number of persons of age from 55
#'   to 64 by division.
#' @param Age65Plus_Dv An integer vector of the number of persons of age 65 or
#'   older by division.
#' @param HhSize_Dv A numeric vector of the average household size by division.
#'   If provided, the household type proportions are adjusted to match the
#'   average household size.
#' @param Prop1PerHh_Dv A numeric vector of the one-person household size
#'   proportions by division. If provided, the household type proportions are
#'   adjusted to match this proportion.
#' @param Dv A vector of division names.
#' @param HtProb_HtAp A matrix where rows represent housing types and columns
#'   represent age groups. The values are the proportions of persons in each age
#'   group found in each household type. The sum of each column is 1. The matrix
#'   is created from Census PUMS data using calcAgeProbByHhType.
#' @param MaxIter A scalar integer defining the maximum number of iterations of
#'   the IPF to reconcile household composition and input population by age
#'   group.
#' @return A named list having 3 components: Results_ls, Checks_ls, Messages_.
#'   Results_ls is a list where each component is a vector identifying the
#'   number of households of each household age type for a division. Checks_ls
#'   is a list composed of two components. The first component is a vector
#'   containing the average household size calculated for each division. The
#'   second component is a vector containing the percentage of one person
#'   households calculated for each division. Messages is a vector containing
#'   messages identifying divisions where the balancing population inputs and
#'   household types was terminated at the maximum number of iterations,
#'   MaxIter.
tabulateHhAgeType <- function(Age0to14_Dv = Age0to14,
                              Age15to19_Dv = Age15to19,
                              Age20to29_Dv = Age20to29,
                              Age30to54_Dv = Age30to54,
                              Age55to64_Dv = Age55to64,
                              Age65Plus_Dv = Age65Plus,
                              HhSize_Dv = HhSize,
                              Prop1PerHh_Dv = Prop1PerHh,
                              Dv = ArealUnit,
                              HtProb_HtAp = HtProp_HtAp,
                              MaxIter = 100) {

  # Initialize
  #-----------
  # Naming vectors for ages and household types
  Ap <- colnames(HtProb_HtAp)
  Ht <- rownames(HtProb_HtAp)
  # Make table of factors to convert persons into households and vise verse
  PrsnFactors_Ht_Ap <-
    lapply(strsplit(Ht, "-"), function(x)
      as.numeric(x))
  PrsnFactors_HtAp <- do.call(rbind, PrsnFactors_Ht_Ap)
  dimnames(PrsnFactors_HtAp) <- list(Ht, Ap)
  rm(PrsnFactors_Ht_Ap)
  # Calculate household size by household type
  HhSize_Ht <- rowSums(PrsnFactors_HtAp)
  # List to store results
  HhType_ls <- list()
  # Vectors to store checks
  EstHhSize_Dv <- numeric(length(Dv))
  names(EstHhSize_Dv) <- Dv
  EstProp1PerHh_Dv <- numeric(length(Dv))
  names(EstProp1PerHh_Dv) <- Dv
  # Vector to store messages
  Messages_ <- character(0)
  # List to store messages for log
  Messages_ls <- list()

  # Iterate by division
  #--------------------
  for (dv in Dv) {
    # Select populations for division
    Idx <- which(dv == Dv)
    Prsn_Ap <- c(Age0to14_Dv[Idx], Age15to19_Dv[Idx], Age20to29_Dv[Idx],
                 Age30to54_Dv[Idx], Age55to64_Dv[Idx], Age65Plus_Dv[Idx])
    names(Prsn_Ap) <- Ap
    HhSize <- HhSize_Dv[Idx]
    Prop1PerHh <- Prop1PerHh_Dv[Idx]
    # Place persons by age into household types by multiplying person vector
    # by probabilities
    Prsn_HtAp <- sweep(HtProb_HtAp, 2, Prsn_Ap, "*")
    # Calculate number of households by type on the basis of numbers of persons
    # assigned by age
    Hh_HtAp <- Prsn_HtAp / PrsnFactors_HtAp
    Hh_HtAp[is.na(Hh_HtAp)] <- 0
    # Calculate the maximum households by each type for convergence check
    MaxHh_Ht <- apply(Hh_HtAp, 1, max)

    # Iterate until "balanced" set of households is created
    #------------------------------------------------------
    # Create vector to store convergence indicator
    MaxDiff_ <- numeric(MaxIter)
    for (i in 1:MaxIter) {
      # Resolve conflicting numbers of households by taking the mean value for
      # each household type
      ResolveHh_HtAp <- t(apply(Hh_HtAp, 1, function(x) {
        if (sum(x > 0) > 1) {
          x[x > 0] <- mean(x[x > 0])
        }
        x
      }))
      # Check whether to break out of loop
      ResolveHh_Ht <- apply(ResolveHh_HtAp, 1, max)
      Diff_Ht <- abs(MaxHh_Ht - ResolveHh_Ht)
      PropDiff_Ht <- Diff_Ht / ResolveHh_Ht
      if (all(PropDiff_Ht < 0.001)) break
      MaxDiff_[i] <- max(PropDiff_Ht)
      # Adjust household proportions to match household size target if not NA
      if(!is.na(HhSize)){
        # Calculate average household size and ratio with target household size
        AveHhSize <- sum(ResolveHh_Ht * HhSize_Ht) / sum(ResolveHh_Ht)
        HhSizeAdj <- HhSize / AveHhSize
        # Calculate household adjustment factors and adjust households
        HhAdjFactor_Ht <- HhSize_Ht * 0 + 1 # Start with a vector of ones
        HhAdjFactor_Ht[HhSize_Ht > HhSize] <- HhSizeAdj # Apply HhSizeAdj
        ResolveHh_HtAp <- sweep(ResolveHh_HtAp, 1, HhAdjFactor_Ht, "*")
      }
      # Adjust proportion of 1-person households to match target if not NA
      if(!is.na(Prop1PerHh)) {
        Hh_Ht <- round(apply(ResolveHh_HtAp, 1, max))
        NumHh_Sz <- tapply(Hh_Ht, HhSize_Ht, sum)
        NumHh <- sum(NumHh_Sz)
        Add1PerHh <- (Prop1PerHh * NumHh) - NumHh_Sz[1]
        Is1PerHh_Ht <- HhSize_Ht == 1
        Add1PerHh_Ht <- Add1PerHh * Hh_Ht[Is1PerHh_Ht] / sum(Hh_Ht[Is1PerHh_Ht])
        RmOthHh_Ht <- -Add1PerHh * Hh_Ht[!Is1PerHh_Ht] / sum(Hh_Ht[!Is1PerHh_Ht])
        ResolveHh_HtAp[Is1PerHh_Ht] <- ResolveHh_HtAp[Is1PerHh_Ht] + Add1PerHh_Ht
        ResolveHh_HtAp[!Is1PerHh_Ht] <- ResolveHh_HtAp[!Is1PerHh_Ht] + RmOthHh_Ht
      }
      # Calculate the number of persons by age based on the resolved households
      ResolvePrsn_HtAp <- ResolveHh_HtAp * PrsnFactors_HtAp
      # Calculate the probabilities of a person by age being in a household by
      # type from the allocation of persons by household type and age
      PrsnProb_HtAp <- sweep(ResolvePrsn_HtAp, 2, colSums(ResolvePrsn_HtAp), "/")
      # Calculate the difference in the number of persons by age category
      PrsnDiff_Ap <- Prsn_Ap - colSums(ResolvePrsn_HtAp)
      # Allocate the person difference using the updated probabilities
      AddPrsn_HtAp <- sweep(PrsnProb_HtAp, 2, PrsnDiff_Ap, "*")
      # Add the allocated person difference to the resolved person distribution
      Prsn_HtAp <- ResolvePrsn_HtAp + AddPrsn_HtAp
      # Recalculate number of households by type
      Hh_HtAp <- Prsn_HtAp / PrsnFactors_HtAp
      Hh_HtAp[is.na(Hh_HtAp)] <- 0
      # Calculate the maximum households by each type for convergence check
      MaxHh_Ht <- apply(ResolveHh_HtAp, 1, max)
      # Create message if exit loop because MaxIter reached
      if (i == MaxIter) {
        Message <- paste("Household synthesis for", dv, "stopped at",
                         MaxIter, "iterations.")
        Messages_ <- c(Messages_, Message)
      }
    } # End loop through balancing iterations

    # Add division results to lists
    #------------------------------
    # Division results for number of households by household type
    HhType_ls[[dv]] <- round(apply(ResolveHh_HtAp, 1, max))
    # Division checks
    if (is.na(HhSize)) {
      EstHhSize_Dv[dv] <- NA
    } else {
      EstHhSize_Dv[dv] <- AveHhSize
    }
    if (is.na(Prop1PerHh)) {
      EstProp1PerHh_Dv[dv] <- NA
    } else {
      EstProp1PerHh_Dv[dv] <- NumHh_Sz[1] / sum(NumHh_Sz)
    }

  } # End loop through divisions

  # Return a list with results, checks, and messages
  #-------------------------------------------------
  list(Results_ls = HhType_ls,
       Checks_ls = list(EstHhSize_Dv = EstHhSize_Dv,
                        EstProp1PerHh_Dv = EstProp1PerHh_Dv),
       Messages_ = Messages_)
}




# DEFINE FUNCTION TO
# DEFINE FUNCTION TO CREATE SYNTHETIC HOUSEHOLDS
#===============================================
#' Create synthetic households
#'
#' \code{createSynthHh} Creates synthetic households from table of number of households by household type.
#'

Hh_Ht <- Test_$Results_ls[[1]]
createSynthHh <- function(NumHh_Ht) {
  # Define dimension names
  Ap <- c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64",
          "Age65Plus")
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
  # Add to list of household attributes
  SynthHh_ls <- list(HhId = 1:nrow(Hh_HhAp),
                     Age0to14 = Hh_HhAp[, "Age0to14"],
                     Age15to19 = Hh_HhAp[, "Age15to19"],
                     Age20to29 = Hh_HhAp[, "Age20to29"],
                     Age30to54 = Hh_HhAp[, "Age30to54"],
                     Age55to64 = Hh_HhAp[, "Age55to64"],
                     Age65Plus = Hh_HhAp[, "Age65Plus"],
                     HhSize = HhSize_Hh)
list(Results_ls = HhType_ls,
     Checks_ls = list(AveHhSize_Dv = AveHhSize_Dv,
                      Prop1PerHh_Dv = Prop1PerHh_Dv),
     Messages_ls = Messages_ls)

}


Model <- new.env()
# Identify scenario input file and characteristics
Model$Inp_ls <- list()
Model$Inp_ls$InpFile <- "pop_age_inputs.csv"
Model$Inp_ls$GeoLvl <- "Division"
Model$Inp_ls$Field_ls <- list()
Model$Inp_ls$Field_ls$Age0to14 <-
  list(Type = "integer",
       Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age15to19 <-
  list(Type = "integer",
       Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age20to29 <-
  list(Type = "integer",
       Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age35to54 <-
  list(Type = "integer",
       Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age55to64 <-
  list(Type = "integer",
       Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$Age65Plus <-
  list(Type = "integer",
       Prohibit = c("NA", "< 0"))
Model$Inp_ls$Field_ls$HhSize <-
  list(Type = "double",
       Prohibit = c("< 1"))
Model$Inp_ls$Field_ls$Prop1PerHh <-
  list(Type = "double",
       Prohibit = c("<= 0", "> 1"))



# BUILD THE MODEL
#================
#' Build the model object
#'
#' \code{buildModel} Creates a RSPM model object to implement the household age model.
#'
#' The buildModel function creates a model object which can be applied in the RSPM framework. The calcAgeProbByHhType function is invoked to estimate a household probability table which represents the region. The user must put the required inputs in the "inst/extdata" directory. The table is added as a parameter to the model object. The createHhByAge function is
buildModel <- function() {
  # Initialize list to store model components
  Model <- new.env()
  # Identify scenario input file and characteristics
  Model$Inp_ls <- list()
  Model$Inp_ls$InpFile <- "pop_age_inputs.csv"
  Model$Inp_ls$GeoLvl <- "Division"
  Model$Inp_ls$Field_ls <- list()
  Model$Inp_ls$Field_ls$Age0to14 <-
    list(Type = "integer",
         Prohibit = c("NA", "< 0"))
  Model$Inp_ls$Field_ls$Age15to19 <-
    list(Type = "integer",
         Prohibit = c("NA", "< 0"))
  Model$Inp_ls$Field_ls$Age20to29 <-
    list(Type = "integer",
         Prohibit = c("NA", "< 0"))
  Model$Inp_ls$Field_ls$Age35to54 <-
    list(Type = "integer",
         Prohibit = c("NA", "< 0"))
  Model$Inp_ls$Field_ls$Age55to64 <-
    list(Type = "integer",
         Prohibit = c("NA", "< 0"))
  Model$Inp_ls$Field_ls$Age65Plus <-
    list(Type = "integer",
         Prohibit = c("NA", "< 0"))
  Model$Inp_ls$Field_ls$HhSize <-
    list(Type = "double",
         Prohibit = c("< 1"))
  Model$Inp_ls$Field_ls$Prop1PerHh <-
    list(Type = "double",
         Prohibit = c("<= 0", "> 1"))
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



PopInput_df <- read.csv("inst/extdata/pop_age_inputs.csv", as.is = TRUE)
PopInput_df <- PopInput_df[PopInput_df$Year == 2010,]
PopInput_ls <- as.list(PopInput_df)
rm(PopInput_df)
PrsnInput_df <- read.csv("inst/extdata/pums_person.csv", as.is=TRUE)
HhInput_df <- read.csv("inst/extdata/pums_housing.csv", as.is=TRUE)
PopInput_ls$HtProp_HtAp <- as.data.frame(calcAgeProbByHhType(PrsnInput_df, HhInput_df))
e <- new.env()
for (name in names(PopInput_ls)) {
  e[[name]] <- PopInput_ls[[name]]
}
environment(tabulateHhAgeType) <- e
rm(HhInput_df, PrsnInput_df, PopInput_ls, name)
Test_ <- tabulateHhAgeType()

rm(PopInput_ls, IsYear, PrsnInput_df, HhInput_df, HtProb_HtAp)

