# VESyntheticFirms
VisionEval Synthetic Firms module

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
library("devtools")
install_github("gregorbj/VisionEval/sources/framework/visioneval")
install_github("gregorbj/VisionEval/sources/modules/VESyntheticFirms")
```

