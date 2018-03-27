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


with(Out_ls$Data$Vehicle, summary(Dvmt / MPG))
