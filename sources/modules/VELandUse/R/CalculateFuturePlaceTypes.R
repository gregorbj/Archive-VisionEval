#================
#CalculateFuturePlaceTypes.R
#================
# This module calculates place types for households and firms for future year.
# There are thirteen place types which comprise of a combination of
# four area types (urban core, close-in community, suburban, and rural)
# and five development categories (residential, commercial, mixed-use,
# transit-oriented development, and greenfield)


# library(visioneval)

#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

## Suggest to do : Household allocation model estimation
load("./data/HhAllocationModelCoeff.rda")
HhAllocationModelCoeff_df <- HhAllocationModelCoeff
rm(HhAllocationModelCoeff)

# Save the household allocation model coefficients
#--------------------------------------------------
#' Household Allocation Model
#'
#' A data.frame containing coefficients of variables needed to
#' implement household allocation model
#'
#' @format A data.frame having the following components
#' \describe{
#'   \item{CHID}{a numeric indicating a area type}
#'   \item{CHDESC}{a string indicating a area type (City, Rural, Suburban, Town, and Urban)}
#'   \item{VAR}{a string indicating the variable names (ASC, Singleton, Children, CoupleNoKids,
#'   OnlyElderly, HhIncome1000)}
#'   \item{COEFF}{a numeric value for coefficients}
#' }
#' @source CalculateFuturePlaceTypes.R script.
"HhAllocationModelCoeff_df"
usethis::use_data(HhAllocationModelCoeff_df, overwrite = TRUE)

#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateFuturePlaceTypesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items("Pop",
              "Emp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "NA",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item("HhId"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
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
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = item("Income"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.1999",
      NAVALUE = -1,
      PROHIBIT = c("NA","< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        item("naics"),
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "naics",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "esizecat",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "category",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "numbus",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "businesses",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "emp",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "integer",
      UNITS = "employees",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items("UrbanPop",
                   "UrbanEmp"),
      TABLE = "Bzone",
      GROUP = "BaseYear",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "DrvLevels",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Drv1", "Drv2", "Drv3Plus"),
      UNLIKELY = "",
      DESCRIPTION = "The number of people who can drive"
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      DESCRIPTION = "A list of place types as assigned to the households"
    ),
    item(
      NAME = "EmpPlaceTypes",
      TABLE = "Business",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "",
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      UNLIKELY = "",
      DESCRIPTION = "A list of place types as assigned to the businesses"
    ),
    item(
      NAME = items("UrbanPop",
                   "UrbanEmp"),
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      NAVALUE = -1,
      PROHIBIT = c("NA","< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items("Total population by place types",
                          "Total employees by place types")
    ),
    item(
      NAME = "UrbanIncome",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2010",
      NAVALUE = -1,
      PROHIBIT = c("NA","< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Total income by place types"
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateFuturePlaceTypes module
#'
#' A list containing specifications for the CalculateFuturePlaceTypes module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{scenario input data to be loaded into the datastore for this
#'  module}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateFuturePlaceTypes.R script.
"CalculateFuturePlaceTypesSpecifications"
usethis::use_data(CalculateFuturePlaceTypesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

# This function allocates households and firms to the thirteen
# placetypes for the future year and requires base year population and
# employment data. First, the total population and
# total employment for each place type is calculated using the
# population and employment distribution provided as input and
# base year employment and population. The firms
# are then randomly assigned to the place types. The households are
# allocated to the place types using a linear model. This model utilizes
# characteristics of a household like couple with no kids, couple with children,
# single, and only elderly to make allocations.


#---------------------------------------------------------------------------
#' Main module function that assigns the place-types (Bzone) to each
#' household and firm.
#'
#' \code{CalculateFuturePlaceTypes} assigns place-types to each household and firm.
#'
#' This function allocates placetypes to households and firms. It randomly assigns
#' firms to the placetypes and uses a linear model built on features of a household
#' to assign a household to a placetype.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @name CalculateFuturePlaceTypes
#' @import visioneval
#' @export
CalculateFuturePlaceTypes <- function(L) {
  # Set up
  #-----------
  # Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  # Get the houhold data into a data.frame
  Hhlds <- cbind.data.frame(L$Year$Household)

  # Get the age groups
  Ag <- grep("^Ag", colnames(Hhlds), value = TRUE)

  #Calculate total population, households, and employment.
  TotalPop <- sum(colSums(Hhlds[ ,Ag]))
  TotalHhld <- nrow(Hhlds)
  TotalEmp <- sum(L$Year$Business$emp)

  # Get the base year population and employment
  BasePop_Pt <- L$BaseYear$Bzone$UrbanPop
  BaseEmp_Pt <- L$BaseYear$Bzone$UrbanEmp

  # Calculate the place type population and employment proportions
  PopGrowth_ <- TotalPop - sum(BasePop_Pt)
  EmpGrowth_ <- TotalEmp - sum(BaseEmp_Pt)
  PopGrowth_Pt <- PopGrowth_ * L$Year$Bzone$Pop
  EmpGrowth_Pt <- EmpGrowth_ * L$Year$Bzone$Emp
  TotalPop_Pt <- BasePop_Pt + PopGrowth_Pt
  TotalEmp_Pt <- BaseEmp_Pt + EmpGrowth_Pt
  names(TotalPop_Pt) <- L$Year$Bzone$Bzone
  names(TotalEmp_Pt) <- L$Year$Bzone$Bzone

  rm(BasePop_Pt, BaseEmp_Pt, PopGrowth_Pt, EmpGrowth_Pt, PopGrowth_, EmpGrowth_)

  # Round population to a whole number
  TotalPop_Pt <- round(TotalPop_Pt)

  # Correct the rounding error
  if(sum(TotalPop_Pt) != TotalPop) {
    PopDiff <- TotalPop - sum(TotalPop_Pt)
    Sign <- sign(PopDiff)
    Probs_Pt <- TotalPop_Pt / sum(TotalPop_Pt)
    PopDiff_ <- sample(L$Year$Bzone$Bzone, abs(PopDiff), replace = TRUE, prob = Probs_Pt)
    PopDiff_Pt <- Sign * table(PopDiff_)[ L$Year$Bzone$Bzone ]
    names(PopDiff_Pt) <- L$Year$Bzone$Bzone
    PopDiff_Pt[ is.na(PopDiff_Pt) ] <- 0
    TotalPop_Pt_attr <- attributes(TotalPop_Pt)
    TotalPop_Pt <- TotalPop_Pt + PopDiff_Pt
    attributes(TotalPop_Pt) <- TotalPop_Pt_attr
    rm(PopDiff, Sign, Probs_Pt, PopDiff_, PopDiff_Pt, TotalPop_Pt_attr)
  }
  # Further correction of rounding error
  if(any(TotalPop_Pt < 0)) {
    PopDiff <- sum(TotalPop_Pt[ TotalPop_Pt < 0 ])
    TotalPop_Pt[ TotalPop_Pt < 0 ] <- 0
    Probs_Pt <- TotalPop_Pt / sum(TotalPop_Pt)
    PopDiff_ <- sample(L$Year$Bzone$Bzone, abs(PopDiff), replace = TRUE, prob = Probs_Pt)
    PopDiff_Pt <- table(PopDiff_)[ L$Year$Bzone$Bzone ]
    names(PopDiff_Pt) <- L$Year$Bzone$Bzone
    PopDiff_Pt[ is.na(PopDiff_Pt) ] <- 0
    TotalPop_Pt_attr <- attributes(TotalPop_Pt)
    TotalPop_Pt <- TotalPop_Pt - PopDiff_Pt
    attributes(TotalPop_Pt) <- TotalPop_Pt_attr
    rm(PopDiff, Probs_Pt, PopDiff_, PopDiff_Pt, TotalPop_Pt_attr)
  }

  # Round employment to a whole number
  TotalEmp_Pt <- round(TotalEmp_Pt)

  # Correct the rounding error
  if(sum(TotalEmp_Pt) != TotalEmp) {
    EmpDiff <- TotalEmp - sum(TotalEmp_Pt)
    Sign <- sign(EmpDiff)
    Probs_Pt <- TotalEmp_Pt / sum(TotalEmp_Pt)
    EmpDiff_ <- sample(L$Year$Bzone$Bzone, abs(EmpDiff), replace = TRUE, prob = Probs_Pt)
    EmpDiff_Pt <- Sign * table(EmpDiff_)[ L$Year$Bzone$Bzone ]
    names(EmpDiff_Pt) <- L$Year$Bzone$Bzone
    EmpDiff_Pt[ is.na(EmpDiff_Pt) ] <- 0
    TotalEmp_Pt_attr <- attributes(TotalEmp_Pt)
    TotalEmp_Pt <- TotalEmp_Pt + EmpDiff_Pt
    attributes(TotalEmp_Pt) <- TotalEmp_Pt_attr
    rm(EmpDiff, Sign, Probs_Pt, EmpDiff_, EmpDiff_Pt, TotalEmp_Pt_attr)
  }
  # Further correction of rounding error
  if(any(TotalEmp_Pt < 0)) {
    EmpDiff <- sum(TotalEmp_Pt[ TotalEmp_Pt < 0 ])
    TotalEmp_Pt[ TotalEmp_Pt < 0 ] <- 0
    Probs_Pt <- TotalEmp_Pt / sum(TotalEmp_Pt)
    EmpDiff_ <- sample(L$Year$Bzone$Bzone, abs(EmpDiff), replace = TRUE, prob = Probs_Pt)
    EmpDiff_Pt <- table(EmpDiff_)[ L$Year$Bzone$Bzone ]
    names(EmpDiff_Pt) <- L$Year$Bzone$Bzone
    EmpDiff_Pt[ is.na(EmpDiff_Pt) ] <- 0
    TotalEmp_Pt_attr <- attributes(TotalEmp_Pt)
    TotalEmp_Pt <- TotalEmp_Pt - EmpDiff_Pt
    attributes(TotalEmp_Pt) <- TotalEmp_Pt_attr
    rm(EmpDiff, Probs_Pt, EmpDiff_, EmpDiff_Pt, TotalEmp_Pt_attr)
  }

  # Fix the seed again to get similar results as RPAT
  set.seed(L$G$Seed)

  # Assign employment locations randomly to the place types
  Prob_Pt <- TotalEmp_Pt / sum(TotalEmp_Pt)
  Prob_Pt[Prob_Pt < 0]  <- 0
  Emp_Pt <- sample(L$Year$Bzone$Bzone, length(L$Year$Business$emp), replace = TRUE, prob = Prob_Pt)
  rm(Prob_Pt)

  ## Get the area and development types for place types
  PlaceTypes <- do.call(rbind.data.frame, strsplit(L$Year$Bzone$Bzone, "_", fixed = TRUE))
  colnames(PlaceTypes) <- c("At", "DevT")
  PlaceTypes$At <- as.character(PlaceTypes$At)
  PlaceTypes$DevT <- as.character(PlaceTypes$DevT)

  # Calculate area type targets for the Hhld allocation (Works only with thirteen placetypes)
  Target_At <- rowsum(TotalPop_Pt, PlaceTypes$At)[,1]
  # Replace zero values with a small value
  Target_At[Target_At == 0] <- 1

  # Initialize population by area types
  TotalPop_At <- Target_At * 0
  AreaTypes <- names(TotalPop_At)

  # Apply HHAllocationModel
  # Create all the variables that are required for simulating the choice

  # Add structure to the household data.frame
  Hhlds <- addHhldStructure(Hhld = Hhlds)
  Hhlds$ASC <- 1
  Hhlds$HhIncome1000 <- Hhlds$Income/1E3

  # Define the model variables
  ModelVar_ <- c("ASC",
                 "Singleton",
                 "Children",
                 "CoupleNoKids",
                 "OnlyElderly",
                 "HhIncome1000")

  # Define the correspondence between choices in model coefficients and the area types
  ModelCoeffs_CHDESC <- c("City", "Rural", "Suburban", "Town", "Urban")
  ModelCoeffs_At <- c("CIC", "Rur", "Sub", "Rur", "UC")
  ModelCoeffs_corresp <- cbind(ModelCoeffs_CHDESC,ModelCoeffs_At)
  rm(ModelCoeffs_CHDESC, ModelCoeffs_At)

  # Fix the seed again to get similar results as RPAT
  set.seed(L$G$Seed)

  # Assign area types to households
  Hhlds$AreaType <- runLogit(HhldPop = Hhlds[ ,Ag], ModelData = Hhlds[ ,ModelVar_],
                             ModelCoeffs = HhAllocationModelCoeff_df, TargetPop = Target_At,
                             TargetGroups = ModelCoeffs_corresp[,2])

  rm(ModelCoeffs_corresp)
  # Reassign any housholds assigned to an area where there should be zero
  Target_AtR <- rowsum(TotalPop_Pt, PlaceTypes$At)[,1]
  Hhlds$AreaType[Hhlds$AreaType == names(Target_AtR[Target_AtR == 0])] <- names(Target_AtR[which.max(Target_AtR)])[1]

  rm(Target_AtR)

  # Assign development types to households: draw randomly for each area type
  # Calculate development type targets for the hh allocation
  #
  Target_Pt <- Target_At[PlaceTypes$At]
  Prob_Pt <- TotalPop_Pt/Target_Pt
  names(Prob_Pt) <- PlaceTypes$At

  for(At in AreaTypes){
    if(sum(Prob_Pt[PlaceTypes$At == At]) > 0){
      # Fix the seed again to get similar results as RPAT
      set.seed(L$G$Seed)

      Hhlds$DevType[Hhlds$AreaType == At] <- sample(PlaceTypes$DevT[PlaceTypes$At == At], sum(Hhlds$AreaType == At),
                                                    replace = TRUE, prob = Prob_Pt[PlaceTypes$At == At])
    }
  }
  rm(Prob_Pt, Target_At)

  # Assign place type based on area type and development type
  Hhlds$PlaceType <- paste0(Hhlds$AreaType,"_",Hhlds$DevType)
  Hhlds$PlaceType[Hhlds$AreaType == "Rur"] <- "Rur"

  ###
  ### Do not know if following is needed for now?
  ###

  # # Average Density
  # ## Should this be a calculate average for the region (by CS from older RPAT)?
  # Hhlds$Htppopdn <- 500 # AG Is this a model parameter?
  #
  # ## Should this be 0 for rural? Or are we just using an average for both density and this var and then adjusting using 5D values? (By CS from older RPAT)
  # Hhlds$Urban <- 1 # AG Is this a model parameter?
  #
  # # Calculate the natural log of density
  # Hhlds$LogDen <- log(Hhlds$Htppopdn)

  # Update TotalPop_Pt and TotalEmp_Pt so they reflect actual assigned population and employment rather than input proportions.
  TotalPop_Pt[L$Year$Bzone$Bzone] <- rowSums(rowsum(Hhlds[ ,Ag], Hhlds$PlaceType))[L$Year$Bzone$Bzone]
  TotalPop_Pt[is.na(TotalPop_Pt)] <- 0

  TotalEmp_Pt[L$Year$Bzone$Bzone] <- rowsum(L$Year$Business$emp, Emp_Pt)[,1][L$Year$Bzone$Bzone]
  TotalEmp_Pt[is.na(TotalEmp_Pt)] <- 0

  # Sum income by development type
  TotalIncome_Pt <- rep(0, length(L$Year$Bzone$Bzone))
  names(TotalIncome_Pt) <- L$Year$Bzone$Bzone
  TotalIncome_Pt[L$Year$Bzone$Bzone] <- rowsum(Hhlds$Income, Hhlds$PlaceType)[,1][L$Year$Bzone$Bzone]
  TotalIncome_Pt[is.na(TotalIncome_Pt)] <- 0

  # Return list of results
  #----------------------
  # Initialize output list
  Out_ls <- initDataList()

  Out_ls$Year$Household <- items(
    DrvLevels = Hhlds$DrvLevels,
    HhPlaceTypes = Hhlds$PlaceType
  )

  Out_ls$Year$Business$EmpPlaceTypes <- Emp_Pt

  attributes(Out_ls$Year$Household$DrvLevels)$SIZE <- max(nchar(Out_ls$Year$Household$DrvLevels))
  attributes(Out_ls$Year$Household$HhPlaceTypes)$SIZE <- max(nchar(Out_ls$Year$Household$HhPlaceTypes))
  attributes(Out_ls$Year$Business$EmpPlaceTypes)$SIZE <- max(nchar(Out_ls$Year$Business$EmpPlaceTypes))

  attributes(TotalPop_Pt) <- NULL
  attributes(TotalEmp_Pt) <- NULL
  attributes(TotalIncome_Pt) <- NULL

  Out_ls$Year$Bzone <- items(
    UrbanPop = TotalPop_Pt,
    UrbanEmp = TotalEmp_Pt,
    UrbanIncome = TotalIncome_Pt
  )


  rm(Hhlds, TotalPop_Pt, TotalEmp_Pt, TotalIncome_Pt)

  # Return the list
  return(Out_ls)

}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "PredictHousing",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )

