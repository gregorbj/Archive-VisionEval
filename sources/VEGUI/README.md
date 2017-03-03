# VisionEval GUI
VisionEval R Shiny GUI and Scenario Viewer (Visualizer) 

# Installation
  1. Install [R 3.3+](https://cran.r-project.org) in a location where you have write access.
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

# Running VE GUI from within the cloned repository on your computer
  1. Git Clone (i.e. copy) this repository to your computer.
  1. Start R
  2. Run the following commands to run VE GUI:

```
library("shiny")
library("shinyFiles")

#point to the location of the cloned repository, not the location of the auto-installed R packages
full_path_to_VEGUI = "C:/projects/development/VisionEval/sources/VEGUI"
setwd(full_path_to_VEGUI)
runApp('../VEGUI')
```
  4. Navigate to the VERPAT run_model.R script in the copy of this repository on your computer
  5. Run the model
  