#================
#SplitHDComDvmt.R
#================
#This module splits commercial heavy-duty DVMT into components by vehicle type,
#age, and powertrain.

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
#This model creates a table of vehicle age proportions as a function of vehicle
#type using the 2001 NHTS vehicle dataset. This is the starting point for
#establishing the age distribution for the commercial light-duty vehicle fleet.
#The module adjusts this distribution based on inputs of average vehicle age
#by vehicle type.

#Prepare 2001 NHTS data
#----------------------
#Load 2001 NHTS vehicle data
Veh_df <- VE2001NHTS::Veh_df
#Create a vehicle age variable
Veh_df$VehAge <- 2002 - Veh_df$Vehyear
#Recode the vehicle type field
Veh_df$Type[Veh_df$Type == "LightTruck"] <- "LtTrk"
#Select age and type fields with complete cases
Veh_df <-
  Veh_df[complete.cases(Veh_df[,c("Type", "VehAge")]),c("Type", "VehAge")]
#Limit to vehicles 30 years old or less
Veh_df <- Veh_df[Veh_df$VehAge <= 30,]

#Make table of vehicle age proportions by vehicle type
#-----------------------------------------------------
LDVeh_AgTy <- table(list(Age = Veh_df$VehAge, Type = Veh_df$Type))
LDVehAgeProp_AgTy <- sweep(LDVeh_AgTy, 2, colSums(LDVeh_AgTy), "/")
LDVehAgeCDF_AgTy <- apply(LDVehAgeProp_AgTy, 2, cumsum)
rm(Veh_df, LDVeh_AgTy)

#Save the vehicle age table
#--------------------------
#' Vehicle age table
#'
#' A table of light-duty vehicle age proportions by vehicle type.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{LDVehAgeCDF_AgTy}{a table of vehicle cumulative age proportions by vehicle type}
#' }
#' @source SplitLDComDvmt.R script.
"LDVehAgeCDF_AgTy"
devtools::use_data(LDVehAgeCDF_AgTy, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
SplitLDComDvmtSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  NewInpTable = items(
    item(
      TABLE = "LDComPowertrainProportions",
      GROUP = "Global"
    )
  ),
  #Specify new tables to be created by Set if any
  NewSetTable = items(
    item(
      TABLE = "ComVehicle",
      GROUP = "Year"
    )
  ),
  #Specify input data
  Inp = items(
    item(
      NAME = items(
        "ComAutoMeanAge",
        "ComLtTrkMeanAge"),
      FILE = "region_ldcom_mean_age.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 5", ">= 14"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Mean age of automobiles in commercial service",
        "Mean age of light trucks in commercial service")
    ),
    item(
      NAME = "ComLtTrkProp",
      FILE = "region_ldcom_lttrk_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION =
        "Proportion of commercial light-duty vehicles that are light trucks (pickup, SUV, van)"
    ),
    item(
      NAME = "ModelYear",
      FILE = "region_ldcom_powertrain_prop.csv",
      TABLE = "LDComPowertrainProportions",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "year",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = "Vehicle model year"
    ),
    item(
      NAME = items(
        "AutoPropICEV",
        "AutoPropHEV",
        "AutoPropBEV",
        "LtTrkPropICEV",
        "LtTrkPropHEV",
        "LtTrkPropBEV"
      ),
      FILE = "region_ldcom_powertrain_prop.csv",
      TABLE = "LDComPowertrainProportions",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      NAVALUE = -1,
      SIZE = 0,
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = "",
      UNLIKELY = "",
      TOTAL = "",
      DESCRIPTION = items(
        "Proportion of model year automobiles that have non-hybrid internal combustion engines",
        "Proportion of model year automobiles that are hybrid electric vehicles",
        "Proportion of model year automobiles that are battery electric vehicles",
        "Proportion of model year light trucks that have non-hybrid internal combustion engines",
        "Proportion of model year light trucks that are hybrid electric vehicles",
        "Proportion of model year light trucks that are battery electric vehicles"
      )
    )
  ),
  #Specify data to be loaded from data store
  Get = items(
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "NA",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LDComDvmt",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "ComAutoMeanAge",
        "ComLtTrkMeanAge"),
      FILE = "region_ldcom_mean_age.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 5", ">= 14"),
      ISELEMENTOF = "",
      UNLIKELY = ""
    ),
    item(
      NAME = "ComLtTrkProp",
      FILE = "region_ldcom_lttrk_prop.csv",
      TABLE = "Region",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<= 0", ">= 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      FILE = "region_hh_veh_powertrain_prop.csv",
      TABLE = "LDComPowertrainProportions",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "year",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "AutoPropICEV",
        "AutoPropHEV",
        "AutoPropBEV",
        "LtTrkPropICEV",
        "LtTrkPropHEV",
        "LtTrkPropBEV"
      ),
      FILE = "region_ldcom_powertrain_prop.csv",
      TABLE = "LDComPowertrainProportions",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "< 0", "> 1"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      TABLE = "LDVPowertrainCharacteristics",
      GROUP = "Global",
      TYPE = "integer",
      UNITS = "year",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "AutoIcevMpg",
        "LtTrkIcevMpg",
        "AutoHevMpg",
        "LtTrkHevMpg",
        "AutoBevMpkwh",
        "LtTrkBevMpkwh"
      ),
      TABLE = "LDVPowertrainCharacteristics",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GGE",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    )
  ),
  #Specify data to saved in the data store
  Set = items(
    item(
      NAME = "Marea",
      TABLE = "ComVehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = "NA",
      PROHIBIT = "NA",
      ISELEMENT = "",
      DESCRIPTION = "Marea ID"
    ),
    item(
      NAME = "Age",
      TABLE = "ComVehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Vehicle age in years"
    ),
    item(
      NAME = items(
        "ComAutoICEVDvmt",
        "ComAutoHEVDvmt",
        "ComAutoBEVDvmt",
        "ComLtTrkICEVDvmt",
        "ComLtTrkHEVDvmt",
        "ComLtTrkBEVDvmt"
      ),
      TABLE = "ComVehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/DAY",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Commercial auto internal combustion engine vehicle DVMT by vehicle age",
        "Commercial auto hybrid electric vehicle DVMT by vehicle age",
        "Commercial auto battery electric vehicle DVMT by vehicle age",
        "Commercial light truck internal combustion engine vehicle DVMT by vehicle age",
        "Commercial light truck hybrid electric vehicle DVMT by vehicle age",
        "Commercial light truck battery electric vehicle DVMT by vehicle age"
      )
    ),
    item(
      NAME = items(
        "ComAutoICEVMPGe",
        "ComAutoHEVMPGe",
        "ComAutoBEVMPGe",
        "ComLtTrkICEVMPGe",
        "ComLtTrkHEVMPGe",
        "ComLtTrkBEVMPGe"
      ),
      TABLE = "ComVehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GGE",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Commercial auto internal combustion engine vehicle miles per gas gallon equivalent",
        "Commercial auto hybrid electric vehicle miles per gas gallon equivalent",
        "Commercial auto battery electric vehicle miles per gas gallon equivalent",
        "Commercial light truck internal combustion miles per gas gallon equivalent",
        "Commercial light truck hybrid electric vehicle miles per gas gallon equivalent",
        "Commercial light truck battery electric vehicle miles per gas gallon equivalent"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for SplitLDComDvmt module
#'
#' A list containing specifications for the SplitLDComDvmt module.
#'
#' @format A list containing 6 components:
#' \describe{
#'  \item{NewInpTable}{table to be created}
#'  \item{NewSetTable}{table to be created}
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Inp}{model inputs to be saved to the datastore}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source SplitLDComDvmt.R script.
"SplitLDComDvmtSpecifications"
devtools::use_data(SplitLDComDvmtSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

#Main module function to create and populate vehicle table of types and ages
#---------------------------------------------------------------------------
#' Create vehicle table and populate with vehicle type and age records.
#'
#' \code{AssignVehicleAge} create the vehicle table and populate with vehicle
#' age and type records.
#'
#' This function creates the 'Vehicle' table in the datastore and populates it
#' with records of vehicle types and ages along with household IDs.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @export
#'
SplitLDComDvmt <- function(L) {
  #Set up for making calculations
  #------------------------------
  #Define function to remove attributes from dataset
  rmAttr <- function(X) {
    attributes(X) <- NULL
    X
  }
  #Make naming vectors for types, powertrains, and ages
  Ty <- c("Auto", "LtTrk")
  Pt <- c("ICEV", "HEV", "BEV")
  Ag <- as.character(0:30)
  Ma <- rmAttr(L$Year$Marea$Marea)
  #Make an index to powertrain proportions data by model year
  PtPropIdx_ <- local({
    My <- as.integer(L$G$Year) - as.integer(Ag)
    ModelYear_ <- L$Global$LDComPowertrainProportions$ModelYear
    My[My < min(as.integer(ModelYear_))] <- min(as.integer(ModelYear_))
    match(My, ModelYear_)
  })
  #Make an index to powertrain characteristics data by model year
  PtCharIdx_ <- local({
    My <- as.integer(L$G$Year) - as.integer(Ag)
    ModelYear_ <- L$Global$LDVPowertrainCharacteristics$ModelYear
    My[My < min(as.integer(ModelYear_))] <- min(as.integer(ModelYear_))
    match(My, ModelYear_)
  })

  #Define a function to calculate DVMT by age for a vehicle and powertrain type
  #----------------------------------------------------------------------------
  calcDvmtByTypePowerAge <- function(ty, pt) {
    TypeProp <- switch(
      ty,
      Auto = 1 - rmAttr(L$Year$Region$ComLtTrkProp),
      LtTrk = rmAttr(L$Year$Region$ComLtTrkProp)
      )
    AgeCDF_Ag <- LDVehAgeCDF_AgTy[,ty]
    MeanAge <- rmAttr(L$Year$Region[[paste0("Com", ty, "MeanAge")]])
    AgeProp_Ag <- adjustAgeDistribution(AgeCDF_Ag, MeanAge)$Dist
    PwrtnProp_Ag <-
      rmAttr(L$Global$LDComPowertrainProportions[[paste0(ty, "Prop", pt)]])[PtPropIdx_]
    Dvmt * TypeProp * AgeProp_Ag * PwrtnProp_Ag
  }

  #Define a function to calculate MPGe by age for a vehicle and powertrain type
  #----------------------------------------------------------------------------
  calcMPGeByTypePowerAge <- function(ty, pt) {
    PwrtrnEnrgName <- switch(
      pt,
      ICEV = "IcevMpg",
      HEV = "HevMpg",
      BEV = "BevMpkwh"
    )
    Dname <- paste0(ty, PwrtrnEnrgName)
    L$Global$LDVPowertrainCharacteristics[[Dname]][PtCharIdx_]
  }

  #Populate output list with Marea, Age, and DVMT calculations
  #-----------------------------------------------------------
  #Initialize output list
  Out_ls <- initDataList()
  #Create ComVehicle table
  Out_ls$Year$ComVehicle <- list()
  attributes(Out_ls$Year$ComVehicle) <- list(LENGTH = length(Ma) * length(Ag))
  #Create Marea dataset
  Out_ls$Year$ComVehicle$Marea <- rep(Ma, each = length(Ag))
  attributes(Out_ls$Year$ComVehicle$Marea) <-
    list(SIZE = max(nchar(Out_ls$Year$ComVehicle$Marea)))
  #Create Age dataset
  Out_ls$Year$ComVehicle$Age <- rep(as.numeric(Ag), length(Ma))
  #Initialize DVMT datasets
  DsetNames_ <-
    c(
      "ComAutoICEVDvmt",
      "ComAutoHEVDvmt",
      "ComAutoBEVDvmt",
      "ComLtTrkICEVDvmt",
      "ComLtTrkHEVDvmt",
      "ComLtTrkBEVDvmt"
    )
  for (dname in DsetNames_) {
    Out_ls$Year$ComVehicle[[dname]] <- rep(NA, length(Ma) * length(Ag))
  }
  rm(dname)
  #Initialize MPGe datasets
  DsetNames_ <-
    c(
      "ComAutoICEVMPGe",
      "ComAutoHEVMPGe",
      "ComAutoBEVMPGe",
      "ComLtTrkICEVMPGe",
      "ComLtTrkHEVMPGe",
      "ComLtTrkBEVMPGe"
    )
  for (dname in DsetNames_) {
    Out_ls$Year$ComVehicle[[dname]] <- rep(NA, length(Ma) * length(Ag))
  }
  rm(dname)
  #Calculate DVMT and populate output list
  for (ma in Ma) {
    Dvmt <-
      rmAttr(L$Year$Marea$LDComDvmt[L$Year$Marea$Marea == ma])
    for (ty in Ty) {
      for (pt in Pt) {
        dname1 <- paste0("Com", ty, pt, "Dvmt")
        Out_ls$Year$ComVehicle[[dname1]][Out_ls$Year$ComVehicle$Marea == ma] <-
          calcDvmtByTypePowerAge(ty, pt)
        dname2 <- paste0("Com", ty, pt, "MPGe")
        Out_ls$Year$ComVehicle[[dname2]][Out_ls$Year$ComVehicle$Marea == ma] <-
          calcMPGeByTypePowerAge(ty, pt)
        rm(dname1, dname2)
      }
    }
  }

  #Return the output list
  #----------------------
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
#   ModuleName = "SplitLDComDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "SplitLDComDvmt",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE
# )
