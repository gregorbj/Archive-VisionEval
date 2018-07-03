#make_scenarios.r

#Define scenarios
LvlDef_ls <- list(paste("B", 1:2, sep="/"),
                  paste("C", 1:3, sep="/"),
                  paste("D", 1:3, sep="/"),
                  paste("L", 1:2, sep="/"),
                  paste("P", 1:3, sep="/"),
                  paste("T", 1:3, sep="/"))
ScenDef_df <- expand.grid(LvlDef_ls)
Sc <- apply(ScenDef_df, 1, function(x) {
  Name <- paste(x, collapse = "/")
  gsub("/", "", Name)
})
rownames(ScenDef_df) <- Sc

#Iterate through scenarios and build inputs
for (sc in Sc) {
  #Make scenario directory
  ScenPath <- paste("scenarios", sc, sep = "/")
  dir.create(ScenPath)
  ScenPath <- paste(ScenPath, "inputs", sep="/")
  dir.create(ScenPath)
  #Copy common files into scenario directory
  CommonFiles_vc <- list.files("factors/common",
                               full.names = TRUE)
  file.copy(CommonFiles_vc, ScenPath)
  #Copy each specialty file into scenario directory
  InputPaths_vc <- paste("factors/unique",
                         unlist(ScenDef_df[sc,]), sep="/")
  for (Path in InputPaths_vc) {
    File <- list.files(Path, full.names = TRUE)
    file.copy(File, ScenPath)
  }
}
