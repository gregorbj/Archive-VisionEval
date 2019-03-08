#Set directory to inst/extdata
setwd("inst/extdata")
#Download Consumer Expenditure Survey file if not done
if (!file.exists("ces.txt")) {
  download.file(
    "https://download.bls.gov/pub/time.series/cx/cx.data.1.AllData",
    "ces.txt")
}
#Read in Consumer Expenditure Survey file
Ces_df <- read.table( "ces.txt", sep="\t", skip=1, as.is = TRUE)
#Trim spaces from series names
Ces_df$V1 <- gsub(" ", "", Ces_df$V1)
#Identify income groups and corresponding CES codes
Ig <- c(
  "LT5K",
  "GE5K_LT10K",
  "GE10K_LT15K",
  "GE15K_LT20K",
  "GE20K_LT30K",
  "GE30K_LT40K",
  "GE40K_LT50K",
  "GE50K_LT70K",
  "GE70K_LT80K",
  "GE80K_LT100K",
  "GE100K_LT120K",
  "GE120K_LT150K",
  "GE150K"
)
IncomeId_ <- c(
  "LB0202M",
  "LB0203M",
  "LB0204M",
  "LB0205M",
  "LB0206M",
  "LB0207M",
  "LB0208M",
  "LB0209M",
  "LB0212M",
  "LB0213M",
  "LB0215M",
  "LB0216M",
  "LB0217M"
)
names(IncomeId_) <- Ig
#Identify years and define corresponding names
Years_ <- 2003:2015
Yr <- as.character(Years_)
#Define function to extract data by income group and year
extractCostByIncAndYear <- function(TranId_) {
  SeriesId_ <- paste0("CXU", TranId_, IncomeId_)
  Data_ <- Ces_df[Ces_df$V1 %in% SeriesId_ & Ces_df$V2 %in% Years_, "V4"]
  array(Data_, dim = c(length(Yr), length(Ig)), dimnames = list(Yr, Ig))
}
#Extract gas and oil expenses data
GasOil_YrIg <- extractCostByIncAndYear("GASOIL")
#Extract maintenance and repair expenses data
Repair_YrIg <- extractCostByIncAndYear("CAREPAIR")
#Extract other vehicle expenses
VehOthExp_YrIg <- extractCostByIncAndYear("VEHOTHXP")
#Sum the operating cost expenses
CesOpCosts_YrIg <- GasOil_YrIg + Repair_YrIg + VehOthExp_YrIg
#Save the operating cost matrix
CesOpCosts_df <- data.frame(cbind(
  Year = Years_,
  CesOpCosts_YrIg))
write.table(CesOpCosts_df, "ces_vehicle_op-cost.csv", row.names = FALSE, col.names = TRUE, sep = ",")
#Remove the downloaded data
file.remove("ces.txt")
setwd("../..")

