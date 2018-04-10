library(visioneval)

TableRequest_ls <- list(
  Marea = c("HvyTrkDvmtGrowthBasis", "UrbanLdvDvmt", "UrbanHvyTrkDvmt",
            "LdvFwyArtDvmtProp", "LdvOthDvmtProp", "HvyTrkFwyDvmtProp",
            "HvyTrkArtDvmtProp", "HvyTrkOthDvmtProp", "BusFwyDvmtProp",
            "BusArtDvmtProp", "BusOthDvmtProp" )
)

readDatastoreTables(
    Tables_ls = TableRequest_ls,
    Group = "Global",
    DstoreLocs_ = "tests/Datastore",
    DstoreType = "RD")


TableRequest_ls <- list(
  Marea = c(
    "FwyNoneCongSpeed",
    "FwyModCongSpeed",
    "FwyHvyCongSpeed",
    "FwySevCongSpeed",
    "FwyExtCongSpeed",
    "ArtNoneCongSpeed",
    "ArtModCongSpeed",
    "ArtHvyCongSpeed",
    "ArtSevCongSpeed",
    "ArtExtCongSpeed",
    "OthSpd")
)

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2010",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

temp <- readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2038",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

TableRequest_ls <- list(
  Marea = c(
    "FwyNoneCongDelay",
    "FwyModCongDelay",
    "FwyHvyCongDelay",
    "FwySevCongDelay",
    "FwyExtCongDelay",
    "ArtNoneCongDelay",
    "ArtModCongDelay",
    "ArtHvyCongDelay",
    "ArtSevCongDelay",
    "ArtExtCongDelay")
)

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2010",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2038",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

TableRequest_ls <- list(
  Marea = c(
    "FwyDvmtPropNoneCong",
    "FwyDvmtPropModCong",
    "FwyDvmtPropHvyCong",
    "FwyDvmtPropSevCong",
    "FwyDvmtPropExtCong",
    "ArtDvmtPropNoneCong",
    "ArtDvmtPropModCong",
    "ArtDvmtPropHvyCong",
    "ArtDvmtPropSevCong",
    "ArtDvmtPropExtCong")
)

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2010",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2038",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

TableRequest_ls <- list(
  Marea = c(
    "AveCongPrice")
)

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2010",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")

readDatastoreTables(
  Tables_ls = TableRequest_ls,
  Group = "2038",
  DstoreLocs_ = "tests/Datastore",
  DstoreType = "RD")
