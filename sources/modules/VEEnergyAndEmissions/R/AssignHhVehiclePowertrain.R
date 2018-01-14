#=========================
#AssignVehiclePowertrain.R
#=========================
#This module assigns powertrain types to household vehicles. The powertrain
#types are internal combustion engine vehicle (ICEV), hybrid electric vehicle
#(HEV), plug-in hybrid electric vehicle (PHEV), and battery electric vehicles
#(BEV).

# Copyright [2017] [AASHTO]
# Based in part on works previously copyrighted by the Oregon Department of
# Transportation and made available under the Apache License, Version 2.0 and
# compatible open-source licenses.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================
#This module does not have any estimated model parameters.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignHhVehiclePowertrainSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Azone",
  #Specify new tables to be created by Inp if any
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "HhId",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HouseType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    ),
    item(
      NAME =
        items("HhId",
              "VehId"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk")
    ),
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = c("ICEV", "HEV", "PHEV", "BEV"),
      SIZE = 4,
      DESCRIPTION = "Vehicle powertrain type: ICEV = internal combustion engine vehicle, HEV = hybrid electric vehicle, PHEV = plug-in hybrid electric vehicle, BEV = battery electric vehicle"
    ),
    item(
      NAME = "MPG",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Miles per gasoline equivalent gallons for travel using gasoline, diesel, or other fuel"
    ),
    item(
      NAME = "MPKWH",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/KWH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Miles per kilowatt-hour for travel using stored electricity"
    ),
    item(
      NAME = "MPGe",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Miles per gasoline equivalent gallons calculated assuming household average DVMT split evenly across all household vehicles and full battery (for PHEV and BEV) at start of average day travel"
    ),
    item(
      NAME = "BatRng",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Miles of travel possible on fully charged battery"
    )
  ),
  #Specify call status of module
  Call = items(
    CalcDvmt = "VEHouseholdTravel::CalculateHouseholdDvmt"
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignHhVehiclePowertrain module
#'
#' A list containing specifications for the AssignHhVehiclePowertrain module.
#'
#' @format A list containing 4 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignHhVehiclePowertrain.R script.
"AssignHhVehiclePowertrainSpecifications"
devtools::use_data(AssignHhVehiclePowertrainSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function assigns powertrain types and several powertrain characteristics
#to household vehicles including:
#Powertrain - ICEV, HEV, PHEV, or BEV
#MPG - fuel economy for the vehicle powertrain, type, and model year for travel
#that is powered by gasoline or other fuel. It is 0 for BEV.
#MPKWH - electric energy efficiency for the vehicle powertrain, type, and model
#year for travel that is powered by stored electricity. It is 0 for ICEV and
#HEV.
#MPGe - Miles per gasoline equivalent gallon for all vehicles where travel using
#stored electricity is converted into gasoline gallon equivalents (based on
#energy content) and the average is calculated by weighting by the proportions
#of vehicle travel using stored electricity and not using stored electricity.
#The proportion of travel using electricity is calculated by split average DVMT
#equally across all household vehicles and comparing to the battery range of the
#vehicle.
#BatRng - The battery range of the vehicle in miles.

#Main module function that household vehicle powertrain type
#-----------------------------------------------------------
#' Assign powertrain types to household vehicles.
#'
#' \code{AssignHhVehiclePowertrain} assigns the powertrain type to each household
#' vehicle.
#'
#' This function assigns the powertrain type (ICEV, HEV, PHEV, BEV) to each
#' household vehicle.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @param M A list the module functions of modules called by this module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'

AssignHhVehiclePowertrain <- function(L, M) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)

  #Set up matrices of vehicle powertrain data
  #------------------------------------------
  #Define naming vectors for vehicle types, powertrains, and model years
  Ty <- c("Auto", "LtTrk")
  Pt <- c("ICEV", "HEV", "PHEV", "BEV") #Powertrains
  My <- as.character(EnergyEmissionsDefaults_ls$HhPowertrain_df$ModelYear)
  #Create array of auto and light truck powertrain proportions by model year
  Prop_MyPtTy <-
    array(0,
          dim = c(length(My), length(Pt), length(Ty)),
          dimnames = list(My, Pt, Ty))
  Cols_ <- c("PropIcev", "PropHev", "PropPhev", "PropBev")
  Prop_MyPtTy[,,"Auto"] <-
    as.matrix(EnergyEmissionsDefaults_ls$HhPowertrain_df[, paste0("Auto", Cols_)])
  Prop_MyPtTy[,,"LtTrk"] <-
    as.matrix(EnergyEmissionsDefaults_ls$HhPowertrain_df[, paste0("LtTrk", Cols_)])
  rm(Cols_)

  #Make variables for identifying EV ownership
  #-------------------------------------------
  #Run the household DVMT model
  Dvmt_ls <- M$CalcDvmt(L$CalcDvmt)
  #Calculate average DVMT per household vehicle
  VehDvmt_Hh <-
    Dvmt_ls$Year$Household$Dvmt / L$Year$Household$Vehicles
  VehDvmt_ <-
    VehDvmt_Hh[match(L$Year$Vehicle$HhId, L$Year$Household$HhId)]
  rm(VehDvmt_Hh)
  #Calculate 95th percentile DVMT per household vehicle
  VehDvmt95th_Hh <-
    Dvmt_ls$Year$Household$Dvmt95th / L$Year$Household$Vehicles
  VehDvmt95th_ <-
    VehDvmt95th_Hh[match(L$Year$Vehicle$HhId, L$Year$Household$HhId)]
  rm(VehDvmt95th_Hh)
  #Identify which households have single family dwellings
  #Most likely to be able to accommodate charging equipment
  IsSF_Hh <- L$Year$Household$HouseType == "SF"
  IsSF_ <- IsSF_Hh[match(L$Year$Vehicle$HhId, L$Year$Household$HhId)]
  rm(IsSF_Hh)

  #Make powertrain characteristics data frame
  #------------------------------------------
  Char_df <- EnergyEmissionsDefaults_ls$LdvPowertrainCharacteristics_df
  rownames(Char_df) <- Char_df$ModelYear

  #Assign vehicle powertrains, MPG, MPKWH, and battery range
  #---------------------------------------------------------
  #Initialize vector of results
  NumVeh <- length(L$Year$Vehicle$HhId)
  Powertrain_ <- character(NumVeh)
  MPG_ <- numeric(NumVeh)
  MPKWH_ <- numeric(NumVeh)
  BatRng_ <- numeric(NumVeh)
  #Convert vehicle age to vehicle model year
  ModelYear_ <- as.integer(L$G$Year) - as.integer(L$Year$Vehicle$Age)
  ModelYear_[ModelYear_ < min(as.integer(My))] <- min(as.integer(My))
  ModelYear_ <- as.character(ModelYear_)
  #Iterate through vehicle types and model years and assign powertrains, MPG,
  #MPKWH, and battery range
  for (ty in Ty) {
    for (my in unique(ModelYear_)) {
      IsSelection_ <- L$Year$Vehicle$Type == ty & ModelYear_ == my
      #Identify suitability for EV
      BevRange <- Char_df[my, paste0(ty, "BevRange")]
      IsBevSuitable_ <- VehDvmt95th_ <= BevRange & IsSF_
      #Allocate powertrains with BEV combined into PHEV
      NumVeh <- sum(IsSelection_)
      Prop_Pt <- Prop_MyPtTy[my,Pt,ty]
      Prop_Pt["PHEV"] <- Prop_Pt["PHEV"] + Prop_Pt["BEV"]
      Prop_Pt["BEV"] <- 0
      NumVeh_Pt <- floor(NumVeh * Prop_Pt)
      VehDiff <- NumVeh - sum(NumVeh_Pt)
      if (VehDiff > 0) {
        VehDiff_Pt <- 0 * NumVeh_Pt
        VehDiffTab_Px <-
          table(sample(Pt, VehDiff, replace = TRUE, Prop_Pt))
        VehDiff_Pt[names(VehDiffTab_Px)] <- VehDiffTab_Px
        NumVeh_Pt <- NumVeh_Pt + VehDiff_Pt
      }
      PwrtrnSel_ <- sample(rep(Pt, NumVeh_Pt))
      #Split out BEV from PHEV
      if (Prop_Pt["PHEV"] > 0) {
        BevProp <-
          Prop_MyPtTy[my,"BEV",ty] / sum(Prop_MyPtTy[my,c("BEV", "PHEV"),ty])
        IsPhev_ <- PwrtrnSel_ == "PHEV"
        CanBeBev_ <- IsBevSuitable_[IsSelection_]
        PhevCanBeBev_ <- IsPhev_ & CanBeBev_
        NumBev <- round(sum(IsPhev_) * BevProp)
        if (sum(PhevCanBeBev_) <= NumBev) {
          PwrtrnSel_[PhevCanBeBev_] <- "BEV"
        } else {
          PwrtrnSel_[sample(which(PhevCanBeBev_), NumBev)] <- "BEV"
        }
      }
      #Calculate the MPG, MPKWH, and battery range for each vehicle
      MPG_Pt <- numeric(length(Pt))
      names(MPG_Pt) <- Pt
      MPG_Pt[c("ICEV", "HEV", "PHEV")] <-
        unlist(Char_df[my, paste0(ty, c("IcevMpg", "HevMpg", "PhevMpg"))])
      MPKWH_Pt <- numeric(length(Pt))
      names(MPKWH_Pt) <- Pt
      MPKWH_Pt[c("PHEV", "BEV")] <-
        unlist(Char_df[my, paste0(ty, c("PhevMpkwh", "BevMpkwh"))])
      BatRng_Pt <- numeric(length(Pt))
      names(BatRng_Pt) <- Pt
      BatRng_Pt[c("PHEV", "BEV")] <-
        unlist(Char_df[my, paste0(ty, c("PhevRange", "BevRange"))])
      #Return the results for the vehicle type and model year
      Powertrain_[IsSelection_] <- PwrtrnSel_
      MPG_[IsSelection_] <- MPG_Pt[PwrtrnSel_]
      MPKWH_[IsSelection_] <- MPKWH_Pt[PwrtrnSel_]
      BatRng_[IsSelection_] <- BatRng_Pt[PwrtrnSel_]
    }
  }

  #Calculate MPGe
  #--------------
  #Calculate proportion of average DVMT using electricity
  PropElectric_ <- numeric(NumVeh)
  HasBat_ <- BatRng_ != 0
  PropElectric_[HasBat_] <-
    pmin(VehDvmt_[HasBat_], BatRng_[HasBat_]) / VehDvmt_[HasBat_]
  PropElectric_[!HasBat_] <- 0
  #Calculate MPGe
  MPGe_ <-
    MPG_ * (1 - PropElectric_) +
    convertUnits(MPKWH_, "compound", "MI/KWH", "MI/GGE")$Values * PropElectric_

  #Return the results
  #------------------
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list()
  Out_ls$Year$Vehicle$Powertrain <- Powertrain_
  Out_ls$Year$Vehicle$MPG <- MPG_
  Out_ls$Year$Vehicle$MPKWH <- MPKWH_
  Out_ls$Year$Vehicle$MPGe <- MPGe_
  Out_ls$Year$Vehicle$BatRng <- BatRng_
  #Return the outputs list
  Out_ls
}


#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
#-------------------------------------------------------------------------------
# load("data/EnergyEmissionsDefaults_ls$HhPowertrain_df.rda")
# load("data/EnergyEmissionsDefaults_ls$LdvPowertrainCharacteristics_df.rda")
# TestDat_ <- testModule(
#   ModuleName = "AssignVehiclePowertrain",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# M <- TestDat_$M
# TestOut_ls <- AssignVehiclePowertrain(L, M)

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehiclePowertrain",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
#
# setwd("tests")
# untar("Datastore.tar")
# setwd("..")

