# VERPAT
VisionEval RPAT

# Installation
  1. Install [R 3.3+](https://cran.r-project.org) in a location where you have write access.
  2. Start R
  3. Run the following commands to download and install the required libraries and their dependencies:

```
source("http://bioconductor.org/biocLite.R")
biocLite()
biocLite("rhdf5")
install.packages("devtools")
install.packages("plyr")
install.packages("shiny")
install.packages("shinyFiles")
library("devtools")
install_github("gregorbj/VisionEval/sources/framework/visioneval")
install_github("gregorbj/VisionEval/sources/modules/VESyntheticFirms")
```

# Running the Pilot VE RPAT from within R
  1. Git Clone (i.e. copy) this repository to your computer.
  1. Start R
  3. Run the following commands:

```
#point to the location of the cloned repository, not the location of the auto-installed R packages
full_path_to_VERPAT = "C:/projects/development/VisionEval/sources/models/VERPAT"
setwd(full_path_to_VERPAT)
source("run_model.R")
```

The Pilot VE RPAT can also be run with the [Pilot VE GUI](https://github.com/gregorbj/VisionEval/tree/master/sources/VEGUI).