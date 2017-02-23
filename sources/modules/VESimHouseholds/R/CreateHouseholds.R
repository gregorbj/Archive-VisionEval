#==================
#CreateHouseholds.R
#==================
#This module creates simulated households for a model using inputs of population
#by age group for each Azone and year.

library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This model has just one parameter object, a matrix of the probability that a
#person in each age group is in one of 524 household types. Each household type
#is denoted by the number of persons in each age group in the household. The
#rows of the matrix correspond to the household types. The columns of the matrix
#correspond to the 6 age groups. Each column of the matrix sums to 1. This
#matrix is calculated using Census PUMS data tables. The default data included
#in this package is from the 2000 PUMS data for Oregon. Substitute PUMS data for
#the region to be modeled to customize the table for the region.

#Describe specifications for data that is to be used in estimating parameters
#----------------------------------------------------------------------------
#PUMS household data
PumsHhInp_ls <- items(
  item(
    NAME =
      items("Age0to14",
            "Age15to19",
            "Age20to29",
            "Age30to54",
            "Age55to64",
            "Age65Plus"),
    TYPE = "integer",
    PROHIBIT = c("NA", "< 0"),
    ISELEMENTOF = "",
    UNLIKELY = "",
    TOTAL = ""
  )
)

#Define a function to estimate household size proportion parameters
#------------------------------------------------------------------
#' Calculate proportions of households by household size
#'
#' \code{calcHhAgeTypes} creates a matrix of household types and age
#' probabilities.
#'
#' This function produces a matrix of probabilities that a person in one of six
#' age groups is in one of 524 household types where each household type is
#' determined by the number of persons in each age category.
#'
#' @param Inp_ls A list containing the specifications for
#' the estimation data contained in "pums_hh.csv".
#' @return A matrix where the rows are the household types and the columns are
#' the age categories and the values are the number of persons.
calcHhAgeTypes <- function(Inp_ls = PumsHhInp_ls) {
  #Check and load household size estimation data
  PumsHh_df <- processEstimationInputs(Inp_ls,
                                        "pums_hh.csv",
                                        "CreateHouseholds")
  #Remove household records that only have persons in 0 to 14 age group
  HasOlderPersons_ <- rowSums(PumsHh_df[, 2:6]) > 0
  PumsHh_df <- PumsHh_df[HasOlderPersons_, ]
  #Cap the number of persons in each age category
  PumsHh_df$Age0to14[PumsHh_df$Age0to14 > 4] <- 4
  PumsHh_df$Age15to19[PumsHh_df$Age15to19 > 2] <- 2
  PumsHh_df$Age20to29[PumsHh_df$Age20to29 > 2] <- 2
  PumsHh_df$Age30to54[PumsHh_df$Age30to54 > 2] <- 2
  PumsHh_df$Age55to64[PumsHh_df$Age55to64 > 2] <- 2
  PumsHh_df$Age65Plus[PumsHh_df$Age65Plus > 2] <- 2
  #Create vector of household type names
  HhTypes_ <- apply(PumsHh_df, 1, function(x) paste(x, collapse = "-"))
  #Tabulate persons by age group by household type
  AgeTab_ls <- lapply(PumsHh_df, function(x) {
    tapply(x, HhTypes_, sum)
  })
  AgeTab_HtAp <- do.call(cbind, AgeTab_ls)
  #Calculate and return matrix of probabilities
  sweep(AgeTab_HtAp, 2, colSums(AgeTab_HtAp), "/")
}

#Create and save household size proportions parameters
#-----------------------------------------------------
system.time(HtProb_HtAp <- calcHhAgeTypes())
HtProb_HtAp <- calcHhAgeTypes()
#' Household size proportions
#'
#' A dataset containing the proportions of households by household size.
#'
#' @format A matrix having 524 rows and 6 colums:
#' @source CreateHouseholds.R script.
"HtProb_HtAp"
devtools::use_data(HtProb_HtAp, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CreateHouseholdsSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "Household",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME =
        items("Age0to14",
              "Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
      FILE = "pop_by_age.csv",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = ""
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Azone",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "id",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Age0to14",
              "Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "NumHh",
      TABLE = "Azone",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "households",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME =
        items("HhId",
              "Azone"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "id",
      NAVALUE = "NA",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Hhsize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = "",
      SIZE = 0
    ),
    item(
      NAME =
        items("Age0to14",
              "Age15to19",
              "Age20to29",
              "Age30to54",
              "Age55to64",
              "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "persons",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CreateHouseholds module
#'
#' A list containing specifications for the CreateHouseholds module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{NewSetTable}{new table to be created for datasets specified in the
#'  'Set' specifications}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CreateHouseholds.R script.
"CreateHouseholdsSpecifications"
devtools::use_data(CreateHouseholdsSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function creates households for the entire model region. A household table
#is created and this is populated with the household size and persons by age
#characteristics of all the households.

#Function that creates set of households for an Azone
#----------------------------------------------------
#' Create simulated households for an Azone
#'
#' \code{createHhByAge} creates a set of simulated households for an Azone that
#' reasonably represents a population census or forecast of persons in each of 6
#' age categories.
#'
#' This function creates a set of simulated households for an Azone that
#' reasonably represents the population census or forecast of persons in each of
#' 6 age categories: 0 to 14, 15 to 19, 20 to 29, 30 to 54, 55 to 64, and 65
#' plus. The function uses a matrix of probabilities that a person in each age
#' group might be present in each of 524 household types. This matrix
#' (HtProb_HtAp) is estimated by the calcHhAgeTypes function which is described
#' above. Household types are distinguished by the number of persons in each age
#' category in the household. The function fits the distribution of households
#' by type by iteratively applying the probability matrix to the population,
#' reconciling households allocated by type based on the population assigned,
#' recomputing the assigned population, calculating the difference between the
#' assigned population by age and the input population by age, recalculating the
#' probabilities, and assigning the population difference. This process
#' continues until the difference between the assigned population and the input
#' population by age group is less than 0.1%. After the households are
#' synthesized, the size of each household is calculated.
#'
#' @param Prsn_Ap A named vector containing the number of persons in each age
#'   category.
#' @param MaxIter An integer specifying the maximum number of iterations the
#' algorithm should use to balance and reconcile the population allocation to
#' household types.
#' @return A list containing 7 components. Each component is a vector where each
#'   element of a vector corresponds to a simulated household. The components
#'   are as follows:
#' Age0to14 - number of persons age 0 to 14 in the household
#' Age15to19 - number of persons age 15 to 19 in the household
#' Age20to29 - number of persons age 20 to 29 in the household
#' Age30to54 - number of persons age 30 to 54 in the household
#' Age 55to64 - number of persons age 55 to 64 in the household
#' Age65Plus - number of persons 65 or older in the household
#' Hhsize - total number of persons in the household
#' @export
createHhByAge <- function(Prsn_Ap, MaxIter=100){
  #Dimension names
  Ap <- colnames( HtProb_HtAp )
  Ht <- rownames( HtProb_HtAp )
  #Place persons by age into household types by multiplying person vector
  #by probabilities
  Prsn_HtAp <- sweep(HtProb_HtAp, 2, Prsn_Ap, "*")
  #Make table of factors to convert persons into households and vice verse
  PrsnFactors_Ht_Ap <- lapply(strsplit(Ht, "-" ), function(x) as.numeric(x))
  PrsnFactors_HtAp <- do.call(rbind, PrsnFactors_Ht_Ap)
  dimnames(PrsnFactors_HtAp ) <- dimnames( Prsn_HtAp )
  rm(PrsnFactors_Ht_Ap)
  #Iterate until "balanced" set of households is created
  #-----------------------------------------------------
  MaxDiff_ <- numeric(MaxIter)
  for(i in 1:MaxIter) {
    #Convert population into households. Each row of Hsld_HtAp contains an
    #estimate of the number of household of the type given the number of persons
    #assigned to the household type
    Hsld_HtAp <- Prsn_HtAp / PrsnFactors_HtAp
    Hsld_HtAp[is.na(Hsld_HtAp)] <- 0
    #Resolve differences in household type estimates. For each household type
    #if there is more than one estimate of the number of households, take the
    #mean value of the estimates that are non-zero to determine the number of
    #households of the type.
      ResolveHh_HtAp <- t(apply(Hsld_HtAp, 1, function(x) {
        if(sum(x > 0) > 1){
          x[x > 0] <- mean(x[x > 0])
        }
        x
      }))
    # Exit if the difference between the maximum estimate for each
    # household type is not too different than the resolved estimate
    # for each household type
    MaxHh_Ht <- apply(Hsld_HtAp, 1, max)
    ResolveHh_Ht <- apply(ResolveHh_HtAp, 1, max)
    Diff_Ht <- abs(MaxHh_Ht - ResolveHh_Ht)
    PropDiff_Ht <- Diff_Ht / ResolveHh_Ht
    if(all(PropDiff_Ht < 0.001)) break
    MaxDiff_[i] <- max(PropDiff_Ht)
    #Calculate the number of persons by age group consistent with the resolved
    #numbers of households of each household type
    ResolvePrsn_HtAp <- ResolveHh_HtAp * PrsnFactors_HtAp
    #Convert the resolved persons tabulation into probabilities
    PrsnProb_HtAp <- sweep(ResolvePrsn_HtAp, 2, colSums(ResolvePrsn_HtAp), "/")
    #Calculate the difference in the number of persons by age category
    PrsnDiff_Ap <- Prsn_Ap - colSums(ResolvePrsn_HtAp)
    #Allocate extra persons to households based on probabilities
    AddPrsn_HtAp <- sweep(PrsnProb_HtAp, 2, PrsnDiff_Ap, "*")
    #Add the reallocated persons to the resolved persons matrix
    Prsn_HtAp <- ResolvePrsn_HtAp + AddPrsn_HtAp
  }
  #Calculate number of households by household type
  Hsld_Ht <- round(apply(ResolveHh_HtAp, 1, max))
  #Calculate persons by age group and household type
  Prsn_HtAp <- sweep(PrsnFactors_HtAp, 1, Hsld_Ht, "*")
  #Convert into a matrix of households
  Hsld_Hh <- rep(names(Hsld_Ht), Hsld_Ht)
  Hsld_Hh_Ap <- strsplit(Hsld_Hh, "-")
  Hsld_Hh_Ap <- lapply(Hsld_Hh_Ap, function(x) as.numeric(x))
  Hsld_df <- data.frame(do.call(rbind, Hsld_Hh_Ap))
  names(Hsld_df) <- Ap
  Hsld_df$Hhsize <- rowSums(Hsld_df)
  #Randomly order the rows of the matrix and convert into a list of
  #corresponding vectors by age group
  RandomSort <- sample( 1:nrow(Hsld_df), nrow(Hsld_df), replace=FALSE )
  Hsld_ls <- as.list(data.frame(Hsld_df[RandomSort,]))
  # Return a list of corresponding age group vectors
  Hsld_ls
}

#Main module function that creates simulated households
#------------------------------------------------------
#' Main module function to create simulated households
#'
#' \code{CreateHouseholds} creates a set of simulated households that each have
#' a unique household ID, an Azone to which it is assigned, household
#' size (number of people in the household), and numbers of persons in each of
#' 6 age categories.
#'
#' This function creates a set of simulated households for the model region
#' where each household is assigned a household size, an Azone, a unique ID, and
#' numbers of persons in each of 6 age categories. The function calls the
#' createHhByAge function for each Azone to create simulated households
#' containing persons by age category from a vector of persons by age category
#' for the Azone. The list of vectors produced by the Create Households function
#' are to be stored in the "Household" table. Since this table does not exist,
#' the function calculates a LENGTH value for the table and returns that as
#' well. The framework uses this information to initialize the Households table.
#' The function also computes the maximum numbers of characters in the HhId and
#' Azone datasets and assigns these to a SIZE vector. This is necessary so that
#' the framework can initialize these datasets in the datastore. All the results
#' are returned in a list.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module along with:
#' LENGTH: A named integer vector having a single named element, "Household",
#' which identifies the length (number of rows) of the Household table to be
#' created in the datastore.
#' SIZE: A named integer vector having two elements. The first element, "Azone",
#' identifies the size of the longest Azone name. The second element, "HhId",
#' identifies the size of the longest HhId.
#' @export
CreateHouseholds <- function(L) {
  Ap <-
    c("Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus")
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Azone$NumHh <- numeric(0)
  Out_ls$Year$Household <-
    list(
      Azone = character(0),
      HhId = character(0),
      Hhsize = numeric(0),
      Age0to14 = numeric(0),
      Age15to19 = numeric(0),
      Age20to29 = numeric(0),
      Age30to54 = numeric(0),
      Age55to64 = numeric(0),
      Age65Plus = numeric(0)
    )
    #Make matrix of persons by Azone and age group
    Prsn_AzAg <-
      as.matrix(data.frame(L$Year$Azone, stringsAsFactors = FALSE)[,Ap])
    rownames(Prsn_AzAg) <- L$Year$Azone$Azone
    #Simulate households for each Azone and add to output list
    for (i in 1:nrow(Prsn_AzAg)) {
      Prsn_Ag <- Prsn_AzAg[i]
      Hh_ls <- createHhByAge(Prsn_Ag, MaxIter=100)
      Azone <- rownames(Prsn_AzAg)[i]
      NumHh <- length(Hh_ls[[1]])
      Out_ls$Year$Household$Azone <-
        c(Out_ls$Year$Household$Azone, rep(Azone, NumHh))
      Out_ls$Year$Household$HhId <-
        c(Out_ls$Year$Household$HhId, paste(rep(Azone, NumHh), 1:NumHh, sep = "-"))
      Out_ls$Year$Household$Hhsize <-
        c(Out_ls$Year$Household$Hhsize, Hh_ls$Hhsize)
      Out_ls$Year$Household$Age0to14 <-
        c(Out_ls$Year$Household$Age0to14, Hh_ls$Age0to14)
      Out_ls$Year$Household$Age15to19 <-
        c(Out_ls$Year$Household$Age15to19, Hh_ls$Age15to19)
      Out_ls$Year$Household$Age20to29 <-
        c(Out_ls$Year$Household$Age20to29, Hh_ls$Age20to29)
      Out_ls$Year$Household$Age30to54 <-
        c(Out_ls$Year$Household$Age30to54, Hh_ls$Age30to54)
      Out_ls$Year$Household$Age55to64 <-
        c(Out_ls$Year$Household$Age55to64, Hh_ls$Age55to64)
      Out_ls$Year$Household$Age65Plus <-
        c(Out_ls$Year$Household$Age65Plus, Hh_ls$Age65Plus)
      Out_ls$Year$Azone$NumHh <-
        c(Out_ls$Year$Azone$NumHh, NumHh)
    }
    #Calculate LENGTH attribute for Household table
    attributes(Out_ls$Year$Household)$LENGTH <-
      length(Out_ls$Year$Household$HhId)
    #Calculate SIZE attributes for 'Household$Azone' and 'Household$HhId'
    attributes(Out_ls$Year$Household$Azone)$SIZE <-
      max(nchar(Out_ls$Year$Household$Azone))
    attributes(Out_ls$Year$Household$HhId)$SIZE <-
      max(nchar(Out_ls$Year$Household$HhId))
    #Return the list
    Out_ls
}


