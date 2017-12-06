#=============================
#CalculateVehicleEnergySplit.R
#=============================
#This module calculates the proportions of DVMT of each vehicle that is powered
#by on-board hydrocarbon (HC) fuels such as gasoline or natural gas vs that
#which is powered by electricity stored in the vehicle battery.

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
#This module has no separate estimated model. It uses the models estimated by
#the CalculateHouseholdDvmt module that predict DVMT by each 5% quantile as a
#function of average DVMT. Is is assumed that same models can be used to
#predict the quantile distribution of DVMT of individual vehicles. These models
#are used to calculate the proportions of DVMT of PHEVs that are powered by
#energy stored in the battery vs. energy stored in on-board hydrocarbon fuel.


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
CalculateVehicleEnergySplitSpecifications <- list(
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
      NAME = "DevType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("Urban", "Rural")
    ),
    item(
      NAME = "Marea",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhId",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Dvmt",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Powertrain",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "NA",
      ISELEMENTOF = c("ICEV", "HEV", "PHEV", "BEV")
    ),
    item(
      NAME = "BatRng",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "distance",
      UNITS = "MI",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = items(
        "HcDvmtProp",
        "EvDvmtProp"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Proportion of vehicle DVMT powered by on-board hydrocarbon fuel",
        "Proportion of vehicle DVMT powered by electricity stored in the vehicle battery")
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for CalculateVehicleEnergySplit module
#'
#' A list containing specifications for the CalculateVehicleEnergySplit module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source CalculateVehicleEnergySplit.R script.
"CalculateVehicleEnergySplitSpecifications"
devtools::use_data(CalculateVehicleEnergySplitSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================
#This function calculates the portions of vehicle DVMT that are powered by
#on-board hydrocarbon fuels vs. electricity stored in the vehicle battery. For
#ICEV and HEV, the hydrocarbon proportion is 1 and the electric proportion is
#0. For BEV, the hydrocarbon proportion is 0 and the electric proportion is 1.
#For PHEV, the hydrocarbon and electric proportions depend on the battery range
#of the vehicle and the average DVMT of the vehicle.

#Main module function that calculates energy type proportions of vehicles
#------------------------------------------------------------------------
#' Calculate energy type use proportions of household vehicles.
#'
#' \code{CalculateVehicleEnergySplit} calculates the energy type (electric vs.
#' hydrocarbon) use proportion of household vehicles.
#'
#' This function calculates the proportion of DVMT of each household vehicle
#' that is powered by on-board hydrocarbon fuel such as gasoline and the portion
#' that is powered by electricity stored in the vehicle's battery.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
CalculateVehicleEnergySplit <- function(L) {
  #Calculate proportions for ICEV, HEV, and BEV
  #--------------------------------------------
  #Initialize proportion vectors
  HcDvmtProp_ <- rep(NA, length(L$Year$Vehicle$Powertrain))
  EvDvmtProp_ <- rep(NA, length(L$Year$Vehicle$Powertrain))
  Powertrain_ <- L$Year$Vehicle$Powertrain
  #Assign proportions for ICEV and HEV
  HcDvmtProp_[Powertrain_ %in% c("ICEV", "HEV")] <- 1
  EvDvmtProp_[Powertrain_ %in% c("ICEV", "HEV")] <- 0
  #Assign proportions for BEV
  HcDvmtProp_[Powertrain_ == "BEV"] <- 0
  EvDvmtProp_[Powertrain_ == "BEV"] <- 1

  #Calculate proportions for PHEV
  #------------------------------
  #Identify metropolitan and non-metropolitan PHEV
  L$Year$Vehicle$DevType <-
    L$Year$Household$DevType[match(L$Year$Vehicle$HhId, L$Year$Household$HhId)]
  IsMetro_ <-
    with(L$Year$Vehicle, DevType == "Urban" & Marea != "None")
  IsPhev_ <- L$Year$Vehicle$Powertrain == "PHEV"
  Select_ls <-
    list(
      Metro = IsMetro_ & IsPhev_,
      NonMetro = !IsMetro_ & IsPhev_
    )
  #Make vector of model names
  PctlModelNames_ <- paste0("Pctl", as.character(c(seq(5, 95, 5), 99)))
  #Define function to calculate electrically powered proportion
  calcElecProp <- function(PctlDvmt_, BatRng) {
    IsInRange_ <- PctlDvmt_ <= BatRng
    (sum(PctlDvmt_[IsInRange_]) + BatRng * sum(!IsInRange_)) / sum(PctlDvmt_)
  }
  #Calculate metropolitan PHEV energy proportions
  DoSelect_ <- IsMetro_ & IsPhev_
  if (sum(DoSelect_) > 0) {
    Dvmt_ <- L$Year$Vehicle$Dvmt[DoSelect_]
    Data_df <- data.frame(
      Dvmt = Dvmt_,
      DvmtSq = Dvmt_ ^ 2,
      DvmtCu = Dvmt_ ^ 3,
      Intercept = rep(1, length(Dvmt_))
    )
    PctlModels_ <- DvmtModel_ls[["Metro"]][PctlModelNames_]
    DvmtByPctl_PcVh <-
      do.call(cbind, lapply(PctlModels_, function(x) {
        eval(parse(text = x), envir = Data_df)
      }))
    DvmtByPctl_PcVh[DvmtByPctl_PcVh < 0] <- 0
    BatRng_ <- L$Year$Vehicle$BatRng[DoSelect_]
    EvProp_ <- rep(0, length(BatRng_))
    for (n in 1:length(EvProp_)) {
      EvProp_[n] <- calcElecProp(DvmtByPctl_PcVh[n,], BatRng_[n])
    }
    HcDvmtProp_[DoSelect_] <- 1 - EvProp_
    EvDvmtProp_[DoSelect_] <- EvProp_
    rm(DoSelect_, Dvmt_, Data_df, PctlModels_, DvmtByPctl_PcVh, BatRng_,
       EvProp_, n)
  }
  #Calculate nonmetropolitan PHEV energy proportions
  DoSelect_ <- !IsMetro_ & IsPhev_
  if (sum(DoSelect_) > 1) {
    Dvmt_ <- L$Year$Vehicle$Dvmt[DoSelect_]
    Data_df <- data.frame(
      Dvmt = Dvmt_,
      DvmtSq = Dvmt_ ^ 2,
      DvmtCu = Dvmt_ ^ 3,
      Intercept = rep(1, length(Dvmt_))
    )
    PctlModels_ <- DvmtModel_ls[["NonMetro"]][PctlModelNames_]
    DvmtByPctl_PcVh <-
      do.call(cbind, lapply(PctlModels_, function(x) {
        eval(parse(text = x), envir = Data_df)
      }))
    DvmtByPctl_PcVh[DvmtByPctl_PcVh < 0] <- 0
    BatRng_ <- L$Year$Vehicle$BatRng[DoSelect_]
    EvProp_ <- rep(0, length(BatRng_))
    for (n in 1:length(EvProp_)) {
      EvProp_[n] <- calcElecProp(DvmtByPctl_PcVh[n,], BatRng_[n])
    }
    HcDvmtProp_[DoSelect_] <- 1 - EvProp_
    EvDvmtProp_[DoSelect_] <- EvProp_
    rm(DoSelect_, Dvmt_, Data_df, PctlModels_, DvmtByPctl_PcVh, BatRng_, EvProp_, n)
  }

  #Return the results
  #------------------
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <-
    list(HcDvmtProp = HcDvmtProp_,
         EvDvmtProp = EvDvmtProp_)
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
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleEnergySplit",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L
# load("data/DvmtModel_ls.rda")
# R <- CalculateVehicleEnergySplit(L)


#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# load("data/DvmtModel_ls.rda")
# TestDat_ <- testModule(
#   ModuleName = "CalculateVehicleEnergySplit",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
