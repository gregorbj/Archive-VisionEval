# VERPAT
VisionEval RPAT

# Installation
  1. Install [R](https://cran.r-project.org) in a location where you have write access.
  2. Start R
  3. Run the following commands to download and install the required libraries and their dependencies:

```
source("http://bioconductor.org/biocLite.R")
biocLite()
biocLite("rhdf5")
install.packages("devtools")
library("devtools")
install_github("gregorbj/VisionEval/sources/framework/visioneval")
install_github("gregorbj/VisionEval/sources/modules/VESyntheticFirms")
```

# Running the Pilot VE RPAT
  1. Start R
  3. Run the following commands:

```
full_path_to_VERPAT = "C:/projects/development/VisionEval/sources/models/VERPAT"
setwd(full_path_to_VERPAT)
source("run_model.R")
```