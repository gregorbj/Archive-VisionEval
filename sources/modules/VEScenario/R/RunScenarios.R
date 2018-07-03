#====================
#run_many_scenarios.r
#====================
#Brian Gregor, Oregon Systems Analytics LLC

#This script runs RPAT for multiple scenarios that have the same parameters but different input files. The scenarios are contained in a folder named "scenarios". The parameters files are contained in a folder named "parameters" and all of the RPAT scripts are contained in a folder named "scripts". 
#Define a function to clean up work space after running each scenario
#--------------------------------------------------------------------
resetEnv <- function() {
  Objects <- ls(pos = 1)
  ToKeep_ <- c("MasterDir", "resetEnv", "Sc", "ScenNames", "assignLoad")
  rm(list = Objects[!(Objects %in% ToKeep_)], pos = 1)
  detach("Parameters_")
  detach("GreenSTEP_")
  detach("Abbr_")
  detach("Dir_")
}

assignLoad <- function(filename){
  load(filename)
  get(ls()[ls() != "filename"])
}


#Save the master directory and get names of all scenario directories
#-------------------------------------------------------------------
MasterDir <- getwd()
Sc <- list.dirs("scenarios", recursive = FALSE)
ScenNames <- unlist(lapply(strsplit(Sc, "/"), function(x) x[2]))

#Run all the scenarios in the scenarios directory
#------------------------------------------------
for (sc in Sc) {
  print(sc)
  setwd(sc)
  source("../../scripts/SmartGAP.r")
  resetEnv()
  setwd(MasterDir)
}

#Create summary tables of all the output measures
#------------------------------------------------
OutputFiles <-
  c( 
    "Access.Ma", "Accidents.As", "AveSpeed.MaTy", "Costs.Pt",
    "DelayVehHr.MaTy", "Dvmt.Pt", "Emissions.Pt", "Emp.Pt",
    "Equity.Ig", "Fuel.Pt", "HighwayCost.Ma", "Inc.Pt", "Pop.Pt",
    "TransitCapCost.Ma", "TransitOpCost.Ma", "TransitTrips.Pt",
    "VehHr.MaTy", "VehicleTrips.Pt", "Walking.Ma"
  )
#Iterate through outputs and scenarios and create tables
#-------------------------------------------------------
for (i in 1:length(OutputFiles)) {
  File <- OutputFiles[i]
  Name <- unlist(strsplit(File, "\\."))[1]
  for (j in 1:length(Sc)) {
    sc <- ScenNames[j]
    Path <- paste0("scenarios/", sc, "/outputs/", File, ".RData")
    Data <- assignLoad(Path)
    Class <- class(Data)
    if (Class == "matrix") {
      NumRow <- max(dim(Data))
      NumCol <- length(Sc)
      if (j == 1) {
        Results <- matrix(0, nrow = NumRow, ncol = NumCol)
        rownames(Results) <- dimnames(Data)[[which(dim(Data) == max(dim(Data)))]]
        colnames(Results) <- ScenNames
      }
      if (dim(Data)[1] == NumRow) {
        Results[, sc] <- Data[, 1]
      } else {
        Results[, sc] <- Data[1, ]
      }
    }
    if (Class == "numeric"){
      if (length(Data) > 1) {
        NumRow <- length(Data)
        NumCol <- length(Sc)
        if (j == 1) {
          Results <- matrix(0, nrow = NumRow, ncol = NumCol)
          rownames(Results) <- names(Data)
          colnames(Results) <- ScenNames
        }
        Results[, sc] <- Data
      } else {
        if (j == 1) {
          Results <- numeric(length(Sc))
          names(Results) <- ScenNames  
        }
        Results[sc] <- Data
      }
    }
    rm(sc, Path, Data, Class)
    if (exists("NumRow")) rm(NumRow)
    if (exists("NumCol")) rm(NumCol)
  }
  SaveFileName <- paste0("scenarios/", Name, ".csv")
  write.table(Results, SaveFileName, row.names = TRUE, col.names = TRUE, sep = ",")
  rm(File, Name, Results)
}

#Create summary comparison js file
#---------------------------------

#Build data frame of scenario levels
LvlDef_ls <- list(Bike = 1:2,
                  VmtChrg = 1:3,
                  DemandMgt = 1:3,
                  LandUse = 1:2,
                  Parking = 1:3,
                  Transit = 1:3)
ScenTab_df <- expand.grid(LvlDef_ls)
#Vector of scenario names
Sc <- apply(ScenTab_df, 1, function(x) {
  paste(paste0(c("B", "C", "D", "L", "P", "T"), x), collapse = "")
})
#Get the population to compute per capita values
Pop_Sc <- colSums(as.matrix(read.csv("scenarios/Pop.csv")))[Sc]
#Calculate fatalities and injuries per 1000 persons by scenario
FatalityInjury_Sc <- colSums(as.matrix(read.csv("scenarios/Accidents.csv"))[1:2,Sc])
ScenTab_df$FatalityInjuryRate <- 1000 * FatalityInjury_Sc / Pop_Sc
rm(FatalityInjury_Sc)
#Calculate average cost per person
Cost_Sc <- colSums(as.matrix(read.csv("scenarios/Costs.csv")))[Sc]
ScenTab_df$AveCost <- Cost_Sc / Pop_Sc
rm(Cost_Sc)
#Calculate average DVMT per person
Dvmt_Sc <- colSums(as.matrix(read.csv("scenarios/Dvmt.csv")))[Sc]
ScenTab_df$AveDvmt <- Dvmt_Sc / Pop_Sc
rm(Dvmt_Sc)
#Calculate average emissions per person
Emissions_Sc <- colSums(as.matrix(read.csv("scenarios/Emissions.csv")))[Sc]
ScenTab_df$AveEmissions <- 365 * Emissions_Sc / Pop_Sc
rm(Emissions_Sc)
#Calculate average fuel consumed per person
Fuel_Sc <- colSums(as.matrix(read.csv("scenarios/Fuel.csv")))[Sc]
ScenTab_df$AveFuel <- 365 * Fuel_Sc / Pop_Sc
rm(Fuel_Sc)
#Calculate average vehicle hours per person
VehHr_Sc <- as.matrix(read.csv("scenarios/VehHr.csv"))[1,Sc]
ScenTab_df$AveVehHr <- VehHr_Sc / Pop_Sc
rm(VehHr_Sc)

#Convert to JS format and save
#-----------------------------
library(jsonlite)
rownames(ScenTab_df) <- NULL
JSON <- toJSON(ScenTab_df)
JSON <- paste("var data = ", JSON, ";", sep="")
File <- file("scenarios/metro-measures.js", "w")
writeLines(JSON, con=File)
close(File)

#Save as text file
#-----------------
write.table(ScenTab_df, file="scenarios/summary_comparison.csv", 
            row.names = FALSE, col.names = TRUE, sep = ",")
