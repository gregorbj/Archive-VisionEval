## Package Development for the RSPM Framework  
**Brian Gregor, Oregon Systems Analytics LLC**  
**July 19, 2015**  

This document establishes standards for developing packages for use in the RSPM framework. These standards will evolve as the development of the RSPM framework proceeds.

All model modules are to be distributed in standard R packages that pass the requirements of the Comprehensive R Archive Network (CRAN). The RSPM framework standards do not address standards necessary to comply with CRAN requirements. Package developers have a number of resources to help them with that, such as Hadley Wickham's *R Packages* book and associated [website](http://r-pkgs.had.co.nz/). In addition, software tools are available to simplify the process of developing compliant packages. Foremost among these is RStudio, an IDE for developing R language software. This program, along with the devtools and roxygen 2 packages simplify the process of package development including documentation. 

What the RSPM framework package standards do is specify the minimum content that a package needs to have. The goals of these standards are to produce packages that:  
- Contain model objects that will work in the RSPM framework  
- Thoroughly document model estimation so that others can understand how the models were developed and can replicate all calculations  
- Provide technical documentation of all models that can be compiled in reports  
- Provide instructions and functions for users to modify the package as needed for the models to reflect regional data  

An example package (source and binary) has been developed to go along with these standards. It is called *household* and is located in the *packages/examples* directory of the RSPM repository. 

###Model Code
All model code is to be included in R scripts in the *R* directory of the source package. There should be at least one script for each model module in the package. For example, if a package named *household* contains three modules named *SynthesizeHh*, *PredictIncome*, and *AssignLandUse*, it should have scripts named *synthesize_hh.r*, *predict_income.r*, and *assign_land_use.r*. Other scripts may be included as well if necessary to improve code organization. For example, a *utilities.r* script might define a number of utility functions that are called by the other scripts.   

Each module script will define all of the key functions utilized by the module. It will also define a function named `buildModel` This function creates a model object that includes all of the components that are needed in order for the model to work in the RSPM framework. This function will also perform calculations needed to estimate key model parameters. The last line of code in each module script must invoke the `buildModel` function and assign the results to the model object name that will be used when calling the module. For example:  
`SynthesizeHh <- buildModel()`  

If customized parameters need to be estimated in order for a model to be representative of the region where it is to be applied, the `buildModel` function needs to include procedures that will load information provided by the user about the region and estimate the relevant parameters. The user, working with the source package, will place the required data files in the *inst/extdata* directory of the package as instructed by the package documentation. After that has been done, the user will build a binary package. The package build process will invoke the `buildModel` function which will estimate the parameters and save them in the model object that is created.

All of the functions in these scripts are to be documented using *roxygen* syntax so that help files can be automatically generated when the code is run. Please refer to the *synthesize_hh.r* example.

###Model Documentation
The package needs to include documentation on each module in addition to the documentation that is included in the R scripts. This documentation is to be included as standard R vignettes in the *vignettes* directory of the source package. The minimum documentation that needs to be included is as follows:  
- A vignette for the package as a whole. The name of this vignette will be the same as the package name. In the *household* example package this vignette is named `household.Rmd`. The package documentation includes a brief description of the modules included in the package. It also includes a brief explanation of what the user needs to do to customize the modules for their model region.  
- A vignette for each module in the package. Each vignette will be named with the same name as the corresponding R script (with the exception of the file extension). The vignette will describe how the model is used in the RSPM framework including how it is invoked, what data it uses from the data store, and what data it provides to the data store. The vignette will also provide detailed instructions for the user on what to do to customize the model parameters to reflect the model region. These instructions must thoroughly describe what information needs to be provided, potential sources, how to format the files, and where to place the files. The instructions must also tell the user how they can build the binary package that will include their customized parameters. See the *synthesize_hh* vignette for an example.
- A vignette for each module which provides technical documentation for the model. This vignette will explain the technical rationale for the model, the technical details on how the model work, and information about model performance (e.g. comparing model results with observed data).