#MakeTestData.R
library(visioneval)
CreateHouseholds_L_Yr <- local({
  #Read in data
  PopByAge_df <- read.csv("tests/data/pop_by_age.csv", as.is = TRUE)
  PopTargets_df <-
    read.csv("tests/data/pop_targets.csv", as.is = TRUE)
  GrpPopByAge_df <- read.csv("tests/data/group_pop_by_age.csv", as.is = TRUE)
  #Merge
  CreateHouseholdsInp_df <- merge(PopByAge_df, PopTargets_df)
  CreateHouseholdsInp_df <- merge(CreateHouseholdsInp_df, GrpPopByAge_df)
  names(CreateHouseholdsInp_df)[names(CreateHouseholdsInp_df) == "Geo"] <-
    "Azone"
  #Initialize a list to hold inputs by year
  Yr <- as.character(CreateHouseholdsInp_df$Year)
  CreateHouseholds_L_Yr <- list()
  for (yr in Yr)
    CreateHouseholds_L_Yr[[yr]] <- initDataList()
  #Populate with input data
  for (yr in Yr) {
    ToRemove <- which(names(CreateHouseholdsInp_df) %in% c("Year"))
    Data_df <-
      CreateHouseholdsInp_df[CreateHouseholdsInp_df$Year == yr,-ToRemove]
    CreateHouseholds_L_Yr[[yr]]$Year$Azone <-
      as.list(Data_df)
  }
  CreateHouseholds_L_Yr
})
#Save the test data
save(CreateHouseholds_L_Yr,
     file = "tests/data/CreateHouseholds_L_Yr.RData")
rm(CreateHouseholds_L_Yr)


