library(visioneval)

TableRequest_ls <- list(
  Household = c(
    "Dvmt",
    "HhSize",
    "AveGPM",
    "AveKWHPM",
    "DailyCO2e",
    "AveCO2ePM",
    "HhId",
    "VehicleTrips",
    "WalkTrips",
    "BikeTrips",
    "TransitTrips"),
  Vehicle = c(
    "GPM",
    "MPG",
    "FuelCO2ePM",
    "ElecCO2ePM",
    "VehicleAccess",
    "DvmtProp",
    "HhId"
  )
)

temp <- readDatastoreTables(
    Tables_ls = TableRequest_ls,
    Group = "2010",
    DstoreLocs_ = "tests/Datastore",
    DstoreType = "RD")

summary(temp$Data$Household$AveCO2ePM)
summary(1 / temp$Data$Household$AveGPM)
with(temp$Data$Household, summary(Dvmt / HhSize))
with(temp$Data$Household, summary(convertUnits(DailyCO2e, "compound", "KG/DAY", "MT/YR")$Values))
with(temp$Data$Household, summary(DailyCO2e * 365 / 1e3))
with(temp$Data$Household, summary(Dvmt * AveCO2ePM * 365 / 1e3))
with(temp$Data$Household, summary(convertUnits(DailyCO2e, "compound", "KG/DAY", "MT/YR")$Values / HhSize))
summary(temp$Data$Household$VehicleTrips)
summary(temp$Data$Household$WalkTrips)
summary(temp$Data$Household$BikeTrips)
summary(temp$Data$Household$TransitTrips)
