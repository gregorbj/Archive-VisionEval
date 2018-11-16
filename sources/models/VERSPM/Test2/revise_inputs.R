#revise_inputs.R
#
#Revise the Geo_df file
DefsInpDir <- "../Test1/defs"
Geo_df <- read.csv(file.path(DefsInpDir, "geo.csv"))
renameZones <- function(Geo_df, AzoneSuffix, BzoneSuffix, MareaSuffix) {
  Geo_df$Azone <- paste0(Geo_df$Azone, AzoneSuffix)
  Geo_df$Bzone <- paste0(Geo_df$Bzone, BzoneSuffix)
  Geo_df$Marea <- paste0(Geo_df$Marea, MareaSuffix)
  Geo_df
}
RevGeo_df <- rbind(
  renameZones(Geo_df, "A", "A", "X"),
  renameZones(Geo_df, "B", "B", "X"),
  renameZones(Geo_df, "C", "C", "Y")
)
write.csv(RevGeo_df, file = "defs/geo.csv", row.names = FALSE)

#Revise input files
reviseZones <- function(Geo_df) {
  renameZones <- function(Geo_df, Suffix) {
    RevGeo_df <- Geo_df
    RevGeo_df$Geo <- paste0(RevGeo_df$Geo, Suffix)
    RevGeo_df
  }
  rbind(
    renameZones(Geo_df, "A"),
    renameZones(Geo_df, "B"),
    renameZones(Geo_df, "C")
  )
}
reviseMareas <- function(Geo_df) {
  renameMareas <- function(Geo_df, Suffix) {
    RevGeo_df <- Geo_df
    RevGeo_df$Geo <- paste0(RevGeo_df$Geo, Suffix)
    RevGeo_df
  }
  rbind(
    renameMareas(Geo_df, "X"),
    renameMareas(Geo_df, "Y")
  )
}
#Iterate through input files and edit
FileInpDir <- "../Test1/inputs"
Files_ <- dir(FileInpDir)
for (File in Files_) {
  Geo <- unlist(strsplit(File, "_"))[1]
  if (Geo %in% c("azone", "bzone", "marea", "region")) {
    Data_df <- read.csv(file.path(FileInpDir, File))
    if (!is.null(Data_df$Year)) {
      Data_ls_df <- split(Data_df, Data_df$Year)
    } else {
      Data_ls_df <- list(Data_df)
    }
    RevData_ls_df <- lapply(Data_ls_df, function(x) {
      if (Geo %in% c("azone", "bzone")) {
        RevData_df <- reviseZones(x)
      }
      if (Geo == "marea") {
        RevData_df <- reviseMareas(x)
      }
      if (Geo == "region") {
        RevData_df <- x
      }
      RevData_df
    })
    RevData_df <- do.call(rbind, RevData_ls_df)
    rownames(RevData_df) <- NULL
    write.csv(RevData_df, file = file.path("inputs", File), row.names = FALSE)
  } else {
    file.copy(file.path(FileInpDir, File), file.path("inputs", File), overwrite = TRUE)
  }
}
#Revise the bzone_lat_lon.csv file
#Offset latitude for copied records
LatLon_df <- read.csv("../Test1/inputs/bzone_lat_lon.csv")
LatRngDiff <- diff(range(LatLon_df$Latitude))
LatOffset <- 1.1 * LatRngDiff

reviseLatLonDataset <- function(Geo_df, Suffix, LatOffset) {
  RevGeo_df <- Geo_df
  RevGeo_df$Geo <- paste0(Geo_df$Geo, Suffix)
  RevGeo_df$Latitude <- Geo_df$Latitude + LatOffset
  RevGeo_df
}
RevLatLon_df <- rbind(
  reviseLatLonDataset(LatLon_df, "A", 0),
  reviseLatLonDataset(LatLon_df, "B", LatOffset),
  reviseLatLonDataset(LatLon_df, "C", 2 * LatOffset)
)
#Check RevLatLon_df
#Check that latitudes are properly offset
Test_df <- split(RevLatLon_df, RevLatLon_df$Year)[[1]]
Type_ <- unlist(sapply(strsplit(Test_df$Geo, ""), function(x) {
  tail(x,1)
}))
plot(Test_df$Longitude[Type_ == "A"], 
     Test_df$Latitude[Type_ == "A"],
     ylim = range(Test_df$Latitude)
     )
points(Test_df$Longitude[Type_ == "B"],
       Test_df$Latitude[Type_ == "B"],
       col = "red"
)
points(Test_df$Longitude[Type_ == "C"],
       Test_df$Latitude[Type_ == "C"],
       col = "green"
)
#Save the revised file
write.csv(RevLatLon_df, file = "inputs/bzone_lat_lon.csv", row.names = FALSE)







