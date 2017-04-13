# VisionEval #
VisionEval (VE) is a model system and supporting software framework for building collaborative disaggregate strategic planning models. Background information is available on the project [webpage](https://gregorbj.github.io/VisionEval/) and project administration is available on the linked [wiki](https://github.com/gregorbj/VisionEval/wiki).

The VE software framework is written in the R programming language for statistical computing and graphics. The software framework is available as a R package, *visioneval*. The purpose of the model system and framework is to enable models be created in a plug-and-play fashion from modules that are also distributed as R packages. A simple R script is used to implement a model by initializing the model environment and then calling modules successively. This repository contains currently contains a demonstration module package and demonstration model script and associated resources. In the future, the repository will hold a number of working modules, model scripts, and resources that implement the GreenSTEP model and related strategic planning models.

This repository is organized into two directories:
- The **sources** directory contains four directories:
  - [visioneval framework](https://github.com/gregorbj/VisionEval/tree/master/sources/framework/visioneval) package
  - [VE modules](https://github.com/gregorbj/VisionEval/tree/master/sources/modules) such as VESimHouseholds and VESyntheticFirms
  - VE models such as the pilot version of [VERPAT](https://github.com/gregorbj/VisionEval/tree/master/sources/models/VERPAT)
  - [VE GUI](https://github.com/gregorbj/VisionEval/tree/master/sources/VEGUI) graphical user interface and scenario viewer / visualizer for running and viewing results of VE models
- The **api** directory contains documentation of the model system. The [model system design](https://github.com/gregorbj/VisionEval/blob/master/api/model_system_design.md) document is the most complete at the present time.

# Getting Started

## Installation and Setup
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
install.packages("shinyjs")
install.packages("shinyFiles")
install.packages("data.table")
install.packages("shinyBS")
install.packages("future")
install.packages("testit")
install.packages("jsonlite")

#https://github.com/tdhock/namedCapture
devtools::install_github("tdhock/namedCapture")
library(namedCapture)
devtools::install_github("trestletech/shinyTree")
library(shinyTree)

devtools::install_github("gregorbj/VisionEval/sources/framework/visioneval")
devtools::install_github("gregorbj/VisionEval/sources/modules/VESyntheticFirms")
devtools::install_github("gregorbj/VisionEval/sources/modules/VESimHouseholds")
```

## Running the Pilot VE RPAT from within R
  1. Git Clone (i.e. copy) this repository https://github.com/gregorbj/VisionEval.git to your computer.
  2. Start R
  3. Run the following commands:

```
#point to the location of the cloned repository, not the location of the auto-installed R packages
full_path_to_VERPAT = "C:/projects/development/VisionEval/sources/models/VERPAT"
setwd(full_path_to_VERPAT)
source("run_model.R")
```

## Running the Pilot VE GUI to run Pilot VE RPAT
  1. Git Clone (i.e. copy) this repository to your computer.
  1. Start R
  2. Run the following commands:

```
library("shiny")
library("shinyFiles")
runGitHub( "gregorbj/VisionEval", subdir="sources/VEGUI")
```
  3. Navigate to the VERPAT run_model.R script in the copy of this repository on your computer
  4. Run the model

For those new to R, we recommend installing [R Studio](https://www.rstudio.com/home/).
