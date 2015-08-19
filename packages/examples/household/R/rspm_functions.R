#rspm_functions.r

# Load rhdf5 library
library(rhdf5)

# DEFINE FUNCTION TO INITIALIZE DATA STORE
#-----------------------------------------
#`

initDataStore <- function(ScenDir, ScenYears, ScenName) {

  # Load and check geographic definitions
  GeoDef_df <- read.csv(paste0(ScenDir, "/geo_def.csv"), as.is = TRUE)
  CheckNames <- names(GeoDef_df) %in% c("Division", "District", "MetroArea")
  if (!all(CheckNames)) {
    WrongNames <- paste(names(GeoDef_df)[CheckNames], collapse="&")
    Message <- paste("Names", WrongNames, "are incorrect.")
    stop(Message)
  }
  # Create abbreviation vectors
  Yr <- ScenYears
  Dv <- sort(unique(GeoDef_df$Division))
  Di <- sort(unique(GeoDef_df$District))
  Ma <- sort(unique(GeoDef_df$MetroArea[!is.na(GeoDef_df$MetroArea)]))
  # More checks to be added

  # Create HDF5 data store file
  FileName <- paste0(ScenDir, "/data_store.h5")
  if(file.exists(FileName)) {
    file.remove(FileName)
  }
  H5File <- H5Fcreate(FileName)
  h5writeAttribute(ScenName, H5File, "SCENARIO")
  h5writeAttribute(as.character(Sys.time()), H5File, "DATE")
  H5Fclose(H5File)

  # Create major groupings (Model, Inputs, Outputs)
  h5createGroup(FileName, "Model")
  h5createGroup(FileName, "Inputs")
  h5createGroup(FileName, "Outputs")

  # Store the geographic lookup table in the Model group
  GeoDef_df[is.na(GeoDef_df)] <- "NA"
  h5createDatagroup(FileName, "Model/GeoLookup", nrow(GeoDef_df))

}

  for (name in names(GeoDef_df)) {
    DatasetName <- paste("Model/GeoLookup/", name, sep = "")
    h5createDataset(FileName, DatasetName, dims = nrow(GeoDef_df),
                    storage.mode = "character", size = 40)
    h5write(GeoDef_df[[name]], FileName, DatasetName)
  }
}


  # Create input groups and write year and geography fields
  #--------------------------------------------------------
  # Create Inputs group
  h5createGroup(H5File, "Inputs")
  # Create Inputs/Region group and add Year and GeoId data
  h5createGroup(H5File, "Inputs/Region")
  h5createDataset(H5File, "Inputs/Region/Year", dims = length(Yr),
                  storage.mode = "integer")
  h5write(Yr, H5File, "Inputs/Region/Year")
  h5createDataset(H5File, "Inputs/Region/GeoId", dims = length(Yr),
                  storage.mode = "character", size = 40)
  h5write(rep("Region", length(Yr)), H5File, "Inputs/Region/GeoId")
  # Create Inputs/Division group and add Year and GeoId data
  h5createGroup(H5File, "Inputs/Division")
  h5createDataset(H5File, "Inputs/Division/Year",
                  dims = length(Yr) * length(Dv),
                  storage.mode = "integer")
  h5write(rep(Yr, each = length(Dv)), H5File, "Inputs/Division/Year")
  h5createDataset(H5File, "Inputs/Division/GeoId",
                  dims = length(Yr) * length(Dv),
                  storage.mode = "character", size = 40)
  h5write(rep(Dv, length(Yr)), H5File, "Inputs/Division/GeoId")
  # Create Inputs/District group and add Year and GeoId data
  h5createGroup(H5File, "Inputs/District")
  if (length(Di) != 0) {
    h5createDataset(H5File, "Inputs/District/Year",
                    dims = length(Yr) * length(Di),
                    storage.mode = "integer")
    h5write(rep(Yr, each = length(Di)), H5File, "Inputs/District/Year")
    h5createDataset(H5File, "Inputs/District/GeoId",
                    dims = length(Yr) * length(Di),
                    storage.mode = "character", size = 40)
    h5write(rep(Di, length(Yr)), H5File, "Inputs/District/GeoId")
  }
  # Create Inputs/MetroArea group and add Year and GeoId data
  h5createGroup(H5File, "Inputs/MetroArea")
  h5createDataset(H5File, "Inputs/MetroArea/Year",
                  dims = length(Yr) * length(Ma),
                  storage.mode = "integer")
  h5write(rep(Yr, each = length(Ma)), H5File, "Inputs/MetroArea/Year")
  h5createDataset(H5File, "Inputs/MetroArea/GeoId",
                  dims = length(Yr) * length(Ma),
                  storage.mode = "character", size = 40)
  h5write(rep(Ma, length(Yr)), H5File, "Inputs/MetroArea/GeoId")

  # Create output groups
  #---------------------
  h5createGroup(H5File,"Outputs")
  for(yr in as.character(ScenYears)) {
    YearGroup <- paste0("Outputs/", yr)
    h5createGroup(H5File, YearGroup)
    OutputGroups <- c("Region", "Metropolitan", "Division", "District", "Household")
    for(group in OutputGroups) {
      GroupName <- paste0(YearGroup, "/", group)
      h5createGroup(H5File, GroupName)
    }
  }

  # Close the file
  #---------------
  H5Fclose(H5File)
  Dv <<- Dv
  Di <<- Di
  Ma <<- Ma
  TRUE
}

initDataStore(ScenDir = "../../../../test_scenario",
              ScenYears = c("2010", "2035"),
              ScenName = "Test Scenario" )

h5ls("../../../../test_scenario/data_store.h5")

# DEFINE FUNCTION TO MAKE A DATAGROUP
#-------------------------------------
# A datagroup is a representation in an HDF5 file of a data frame. A datagroup is simply a group in an HDF5 file that is used to store datasets that are all vectors and all have equal lengths. The datagroup has a "LENGTH" attribute. This is used to create datasets within the datagroup.
h5createDatagroup <- function(FileName, Group, Length = 0) {
  H5File <- H5Fopen(FileName)
  H5Group <- H5Gcreate(H5File, Group)
  h5writeAttribute(Length, H5Group, "LENGTH")
  H5Gclose(H5Group)
  H5Fclose(H5File)
}

h5createDataset(FileName, DatasetName, dims = nrow(GeoDef_df),
                storage.mode = "character", size = 40)


# DEFINE FUNCTION TO LOAD INPUT DATA FOR A MODEL
#-----------------------------------------------
Inp_ls <- Model$Inp_ls
ScenDir <- "../../../../test_scenario"
Year <- 2010
loadModelInputs <- function(Inp_ls = Model$Inp_ls, ScenDir) {

  # Load input file if present
  #---------------------------
  # Check if input file exists and if so read into data frame
  InputFile <- paste(ScenDir, "inputs", Inp_ls$InpFile, sep = "/")
  if (file.exists(InputFile)) {
    Inputs_df <- read.csv(InputFile, as.is = TRUE)
  } else {
    Message <- paste("Scenario input file", InputFile,
                     "does not exist in the inputs folder.")
  }

  # Check correctness of input file
  #--------------------------------
  # Check that has all required field names
  RequiredFields <- c("ArealUnit", "Year", names(Inp_ls$Field_ls))
  Fields <- names(Inputs_df)
  HasFields <- RequiredFields %in% Fields
  if (!all(HasFields)) {
    MissingFields <- paste(RequiredFields[!HasFields], collapse = " & ")
    Message <- paste(Inp_ls$InpFile, "is missing", MissingFields)
    stop(Message)
  }
  # Check that Year field has proper values
  Years_ <- unique(Inputs_df$Year)
  if (!all(Years_ %in% Yr)) {
    Message <- paste("Years in", Inp_ls$InpFile,
                     "not consistent with scenario specification.")
    stop(Message)
  }
  if (!all(Yr %in% Years_)) {
    Message <- paste("Years in", Inp_ls$InpFile,
                     "not consistent with scenario specification.")
    stop(Message)
  }
  # Check that ArealUnit field has proper values
  GeoLvls_ <- c("Division", "District", "MetroArea", "Region")
  GeoAbbr_ <- c(Dv, Di, Ma, NA)
  GeoAbbr <- GeoAbbr_[Inp_ls$GeoLvl %in% GeoLvls_]
  if (!is.na(GeoAbbr)) {
    for (yr in Yr) {
      ArealUnits_ <- Inputs_df$ArealUnit[Inputs_df$Year == yr]
      if (!all(GeoAbbr %in% ArealUnits_)) {
        Message <- paste("Inputs missing for one or more ",
                         tolower(Inp_ls$GeoLvl), "s for Year ",
                         yr, sep = "")
        stop(Message)
      }
      if (!all(ArealUnits_ %in% GeoAbbr)) {
        WrongUnits <- paste(ArealUnits[!(ArealUnits_ %in% GeoAbbr)],
                            collapse = " & ")
        Message <- paste(WrongUnits, "are incorrect", tolower(Inp_ls$GeoLvl),
                         "names.")
        stop(Message)
      }
    }
  }
  # Check that all other fields have proper values
  for (Field in names(Inp_ls$Field_ls)) {
    if( typeof(Inputs_df[[Field]]) != Input_ls$Field_ls[[Field]][["Type"]]) {
      Message <- paste("Wrong type for", Field)
      stop(Message)
    }
  }

  #

}





# Read in population age forecasts
#---------------------------------
PopAgeFcst_df <- read.csv("inst/extdata/pop_age_inputs.csv", as.is = TRUE)
