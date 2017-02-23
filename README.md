# VisionEval #
VisionEval (VE) is a model system and supporting software framework for building collaborative disaggregate strategic planning models. Background information is available on the project [webpage](https://gregorbj.github.io/VisionEval/) and project administration is available on the linked [wiki](https://github.com/gregorbj/VisionEval/wiki).

The VE software framework is written in the R programming language for statistical computing and graphics. The software framework is available as a R package, *visioneval*. The purpose of the model system and framework is to enable models be created in a plug-and-play fashion from modules that are also distributed as R packages. A simple R script is used to implement a model by initializing the model environment and then calling modules successively. This repository contains currently contains a demonstration module package and demonstration model script and associated resources. In the future, the repository will hold a number of working modules, model scripts, and resources that implement the GreenSTEP model and related strategic planning models.

This repository is organized into two directories
- The **sources** directory contains four directories:
  - [visioneval framework](https://github.com/gregorbj/VisionEval/tree/master/sources/framework/visioneval) package
  - [VE modules](https://github.com/gregorbj/VisionEval/tree/master/sources/modules) such as VESimHouseholds and VESyntheticFirms
  - VE models(https://github.com/gregorbj/VisionEval/tree/master/sources/models/VERPAT) such as the pilot version of [VERPAT](https://github.com/gregorbj/VisionEval/tree/master/sources/models/VERPAT)
  - [VE GUI](https://github.com/gregorbj/VisionEval/tree/master/sources/VEGUI) graphical user interface and scenario viewer / visualizer for running and viewing results of VE models
- The **api** directory contains documentation of the model system. The *model_system_design.md* document is the most complete at the present time.

# Getting Started
The installation and setup steps are:
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
install_github("gregorbj/VisionEval/sources/modules/VESimHouseholds")
install_github("gregorbj/VisionEval/sources/models/VERPAT")
```

For those new to R, we recommend installing [R Studio](https://www.rstudio.com/home/).