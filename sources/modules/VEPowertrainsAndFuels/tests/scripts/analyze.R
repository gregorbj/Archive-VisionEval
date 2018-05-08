assignDatastoreFunctions(readModelState(FileName = "tests/ModelState.rda")$DatastoreType)

TableRequest_ls <- list(
  Household = c("HhSize", "GGE", "KWH", "CO2e"),
  Vehicle = c("Dvmt", "MPG", "GGE", "KWH", "CO2e")
)
Out_ls <-
  readDatastoreTables(
    Tables_ls = TableRequest_ls,
    Group = "2010",
    DstoreLocs_ = "tests/Datastore",
    DstoreType = "RD")
lapply(Out_ls$Data, head)

Req_ls <- list(
  Vehicle = c("VehicleAccess", "Type", "Powertrain", "BatRng", "MPG", "GPM",
              "MPKWH", "KWHPM", "MPGe", "FuelCO2ePM", "ElecCO2ePM",
              "ElecDvmtProp"),
  Household = "IsEcoDrive"
)
Out2010_ls <-
  readDatastoreTables(
    Tables_ls = Req_ls,
    Group = "2010",
    DstoreLocs_ = c("tests/Datastore"),
    DstoreType = "RD")
Out2038_ls <-
  readDatastoreTables(
    Tables_ls = Req_ls,
    Group = "2038",
    DstoreLocs_ = c("tests/Datastore"),
    DstoreType = "RD")
