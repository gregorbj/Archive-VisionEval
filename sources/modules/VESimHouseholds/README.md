# VESimHouseholds
Household simulation package for VisionEval
This package will contain a number of modules that work in the VisionEval framework to simulate households and their characteristics.

# Installation
  1. Install [R](https://cran.r-project.org) in a location where you have write access.
  2. Start R
  3. Run the following commands to download and install the required libraries and their dependencies:

```
install.packagessource("http://bioconductor.org/biocLite.R")
biocLite()
biocLite("rhdf5")
install.packages("devtools")
library("devtools")
install_github("gregorbj/VisionEval/sources/framework/visioneval")
```
