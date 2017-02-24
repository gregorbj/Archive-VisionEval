# VisionEval GUI
VisionEval R Shiny GUI and Scenario Viewer (Visualizer) 

# Installation
  1. Install [R](https://cran.r-project.org) in a location where you have write access.
  2. Start R
  3. Run the following commands to download and install the required libraries and their dependencies:

```
install.packages("shiny")
install.packages("shinyFiles")
```

# Running VE GUI
  1. Start R
  2. Run the following commands to download and run VE GUI:

```
library("shiny")
library("shinyFiles")
runGitHub( "gregorbj/VisionEval", subdir="sources/VEGUI")
```

  3. Or run it from within R with:

```
library("shiny")
library("shinyFiles")

full_path_to_VEGUI = "C:/projects/development/VisionEval/sources/VEGUI"
setwd(full_path_to_VEGUI)
runApp('../VEGUI')
```
  4. Navigate to the VERPAT run_model.R script
  5. Run the model