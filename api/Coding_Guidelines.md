## VisionEval Coding Style Guidelines  
**Brian Gregor, Oregon Systems Analytics LLC**  
**February 19, 2019**  

The RSPM framework is intended to become a large open collaborative project for developing disaggregate strategic planning models. Model developers will create and document models that may be combined with the models of other developers in a "plug-and-play" manner. Models will be distributed in standard R packages. These packages will include the code used to estimate the models as well as code for implementing the models. Making model estimation and implementation code open will encourage innovation and make models more robust. 

This open collaborative approach increases the importance of coding style guidelines. The purpose of this memo is to describe the coding style guidelines for packages built for the RSPM framework. For the most part, these guidelines follow [Google's R Style Guide](https://google-styleguide.googlecode.com/svn/trunk/Rguide.xml) fairly closely. They also draw from [Hadley Wickham's recommended style guidelines](http://r-pkgs.had.co.nz/r.html). While those guidelines are similar, they differ with respect to object naming and function documentation. Rather than duplicate all of Google's and Wickham's guidelines and examples, this memo summarizes the guidelines except where there are significant differences with the two. In addition, the following guidelines establish a system for naming objects so that it is possible to understand the basic structure of the objects from their names.

### File Names  
The conventions for naming model input files and the files in modules scripts differ and are described in the following sections.

#### Model Input Files - User Inputs and Model Estimation Data
Punctuation in names should be limited to underscores and hyphens. Avoid using capital letters because the Windows file system ignores letter case but other file systems do not. Don't use spaces in names. The names of model user input files follow the convention of starting the name with the level of geography that inputs are provided for followed by name that conveys the type of data included in the file. For example:

* region_base_year_dvmt.csv

* marea_congestion_charges.csv

* azone_carsvc_availability.csv

* bzone_employment.csv

Several packages enable advanced users to provide model estimation data for the model region so that customized model parameters are estimated to reflect the characteristics of the region. Those files are found in the *inst/extdata* folder of the subject package (e.g. VESimHouseholds package). Those files follow the same naming conventions as the user input files except that there is no geography prefix. Documentation in the *inst/extdata* folder for the package identifies the required file name(s).

#### Module Script Files and Data Files
Scripts that estimate model parameters and implement modules are named using Pascal Case. With this naming convention file names are made up of several words where there is no separation between words and the first letter of each word is capitalized. The names of modules describe what the module does. The name of the R script which defines a module (i.e. estimates model parameters, defines module specifications, implements the module, and documents the module) is the name of the module with a *.R* suffix. Following are some examples:

* CreateHouseholds.R

* PredictIncome.R

* AssignVehicleOwnership.R

* CalculateHouseholdDvmt.R

Module scripts create data files to store model parameters and algorithms. These data files are named using the object naming convention described in the following section. Module developers should use the These files all have an *.rda* extension. The `usethis::use_data` should be used in the module script to save model files. There are plenty of examples of how this is done in existing VisionEval packages. 

The main function for implementing a module has the same name as the module definition script without the *.R* suffix (e.g. CreateHouseholds). The module specifications (see *model_system_design.md* for details) for a module have the same name as the module with the word 'Specifications' appended to the end (e.g. CreateHouseholdsSpecifications). 

### Object Names  
Google and Wickham recommend different styles for object names. Google recommends using periods (`.`) or camel case (e.g. `CamelCase`) to distinguish 'words' in a name, whereas Wickham recommends using underscores (`_`) or camel case. Wickham recommends against using periods because periods are often used to denote S3 methods (e.g. `print.lm`). Object naming for the RSPM framework should only use camel case to distinguish words in a name. Periods should only be used to denote S3 methods. Underscores should only be used to describe object structure as described below. 

Names should be concise and descriptive. Nouns should be used in the names of objects that are not functions. The first letter of the name should be capitalized. For example:  
`DailyTrips`  
Function names should start with a verb. The first letter should not be capitalized to further distinguish functions from other objects. For example:  
`calcAveTripRate`. There is one very important exception to this rule. The name of the main function which implements a module always starts with a capital letter, for example: *CreateHouseholds*.
  
Although this approach to capitalization is opposite Google's (which recommends capitalization of functions but not variables), there is good reason for it. The capability in R to operate on the language offers opportunities for programmatically combining objects and creating associated names by concatenating the object names. When this is done using objects that are named using the RSPM framework style guidelines, the resulting names will meet the style guidelines as well. For example, combining `BikeTrp` and `WalkTrp` would result in `BikeTrpWalkTrp`. The Google naming approach will not result in names that meet the style guidelines (e.g. `bikeTrpwalkTrp`). Since functions wouldn't be combined in this way, it is not a liability to start their names with small letters.

As noted above, underscores are used to represent object structure. One of the reasons why the R language is so capable for data analysis is that it includes a number of different object structures for representing data. These include vectors, two-dimensional matrices, n-dimensional arrays, lists, and data frames (as well as data structures enabled by add-on packages such as the data.table package). Moreover, the R language has a number of functions which facilitate iterating over these data structures. One downside of this flexibility is that in order to understand code that someone else has written (or that you may have written months or years ago), it is necessary to understand the structure of the objects being operated on. This is not always easy to do. For example, an object named `DailyTrips` might be a vector of daily trips by trip purpose, a matrix of daily trips by origin and destination, or perhaps at data frame of trips by person identifying origin, destination and purpose. To improve code readability, these naming guidelines use the underscore character and abbreviations to describe the structure of a data object.

The underscore is used to note that an object is more complex than a scalar. (Strictly speaking, there are no scalars in R. A scalar is a vector having a length of 1. However, it can be useful to consider some objects to be scalars and to name them so that they are considered in that way.) For example `DailyTrips` would denote a single value while `DailyTrips_` would denote a more complex set of values. A 2-letter abbreviation is used after the underscore to indicate the structure of the object where: 
 
- vc = vector  
- mx = matrix  
- ar = array  
- ls = list  
- df = data frame  
- dt = data table  

So for example, a vector of daily trips by trip purpose could be named `DailyTrips_vc` while a matrix of daily trips by origin and destination could be named `DailyTrips_mx`.

For vectors, the `vc` suffix can be omitted. For example, `DailyTrips_` would have the same meaning as `DailyTrips_vc`. Don't omit the suffix in the name of any of the other data structures listed above. If the vector is a logical vector used to select values from vectors, matrices etc., you can dispense with the underscore (`_`) for brevity, but the name of the vector should indicate its *logical* nature. For example, the following code iterates through Azones and selects values for households located in the Azone. Note that the name of the logical selection vector identifies the nature of the selection.

```
for (az in Az) {
  IsAzHh <- L$Year$Household$Azone == az
  Hh_df <- data.frame(lapply(L$Year$Household, function(x) x[IsAzHh]), stringsAsFactors = FALSE)
  #More code goes here
}
```

If the object represents a certain class such as a linear model then the abbreviation after the underscore should identify the class. The meaning of the abbreviation should be described in a comment unless it is commonly understood. For example, `DvmtModel_LM` would identify a linear model object and `HousingChoiceModel_GLM` would identify a generalized linear model object. In some cases the class abbreviation will need to be longer than two letters to adequately distinguish it from objects of another class.

Often several objects used in model calculations have one or more dimensions that are the same. For example, an array that holds average speed data by metropolitan area, congestion level, and road class might be named `Speed_MaClRc`. Usually this naming approach is only used for vectors, matrices, and arrays because these data structures store data of a consistent type whereas lists, data frames, and data tables store mixed data. Often when this naming approach is used, it is accompanied by vectors of names corresponding to the dimension names. These vectors are named with the same 2-letter abbreviations such as:

* Ma <- c("Portland", "Salem", "Eugene")

* Cl <- c("none", "mod", "hvy", "sev", "ext")

* Rc <- c("fwy", "art", "oth")

This approach makes the code easier to understand and simpler. The approach documents the structure of objects and makes it easier to define corresponding objects. For example, a corresponding array of daily vehicle miles of travel could be initialized as follows:

```
Dvmt_MaClRc <- array(0, dim = c(length(Ma), length(Cl), length(Rc)), dimnames = list(Ma, Cl, Rc))
```

Sometimes a module will operate on a portion of a vector, matrix, or array. In the `for` loop above for example, the code operates on households located in one Azone at a time. In such circumstances objects that represent a selection of the whole set should be named to identify the relationship to the whole. This is commonly done by replacing the last letter of a 2-letter dimension with the letter `x`. For example, code that iterates through households by Azone and calculates household average daily vehicle miles traveled might look something like this:

```
Hh <- L$Year$Household$HhId
Dvmt_Hh <- setNames(numeric(length(Hh)), Hh)
for (az in Az) {
  IsAzHh <- L$Year$Household$Azone == az
  Hh_df <- data.frame(lapply(L$Year$Household, function(x) x[IsAzHh]), stringsAsFactors = FALSE)
  Hx <- Hh_df$HhId
  Dvmt_Hx <- applyLinearModel(DvmtModel_ls, Hh_df)
  Dvmt_Hh[Hx] <- Dvmt_Hx
}
```

Although the naming convention using suffix abbreviations is used mainly for vectors, matrices, and arrays, there are some instances where it may be used with lists, data frames, or data tables to improve readability. Say for example you have a data frame of the characteristics of a set of Census block groups located in a number of urbanized areas (`BlkGrp_df`) and you want to perform some set of calculations for the block groups in each urbanized areas. One approach for accomplishing this is to split the data frame by urbanized area, making a list where each component is a data frame for an urbanized area. In this case, the code to create the list of urbanized area data frames could be structured as follows:

```
BlkGrp_Ua_df <- split(BlkGrp_df, BlkGrp_df$UzaName)
```

The reader knows that split will create a list and the name of the object to which is assigned lets the reader know wherever it is referred to that this is a list of data frames and that each data frame corresponds to an urbanized area.

It should be noted that this object naming approach differs from the approach previously used by ODOT in the GreenSTEP and RSPM models. While the approach used previously also used two character abbreviations to denote dimensions, it also used periods in the naming system to distinguish between various data structures. The use of periods has been dropped and replaced with underscores and abbreviations to avoid conflicting with the use of the period to denote S3 methods.  

### Line Length and Indentation  

Lines should not ordinarily exceed 80 characters in length. Lines that are longer in length should be split unless they would be easier to read unsplit. 

Indentation should be used to group code that exists in a code block defined by curly braces (`{}`) such as code that is included in a function definition or in a program control block (e.g. if, else, for, while). Two spaces should be used for each level of indentation. For example:  
```  
if (Income <= 0) {  
  stop("Income must be greater than zero.")  
}
for(i in 1:10) {
  for(j in 1:10) {
    x[i, j] <- i * j
  }
}
```  

Indentation within the parentheses of function calls should be lined up within the parentheses. For example:  
```  
plot(mtcars$mpg ~ mtcars$wt,
     xlab="Vehicle Weight (1000 pounds)",
     ylab="Miles Per Gallon",
     main="Relationship Between Vehicle Fuel Economy and Weight")
```

Only spaces (not tabs) should be used for indentation.

Indentation will be taken care of automatically when RStudio is used to write code and when the global options are set appropriately.  

### Spacing  

Spaces should be placed around all infix operators with the following exceptions:  
- Don't put spaces around the `:` operator  
- Spaces may be omitted around the `=` operator in function calls  
For example:  
```
TonnesCO2e <- Gallons * kMegajoulesPerGallon * CarbonIntensity / 1e6
for (i in 1:100)
lm(Dvmt ~ Income + Density, data=Nhts_df)
```

A space should precede an opening parenthesis except for a function call. For example:  
```
if (Income < 0)
plot(1:10, 1:10, pch=1:10)
```

Don't use spaces to separate code that is within parentheses from the parentheses. Same goes for square brackets. Do place a space after a comma. Following are correct examples:
```
Trips.ZnZn <- sweep(TripProb.ZnZn, TripRates.Zn, 1, "*")
Trips.ZnZn[, 5] <- 0
```

### Statements, Code Blocks, and Curly Braces  

Although it is possible to put more than one statement on a line by using a semicolon to separate the statements, don't do this. Statements should be separated using line breaks and semicolons should not be used.

Code blocks should always be delimited using curly braces. The opening curly brace should be placed on the line preceding the code block. The lines of the code block should be indented 2 spaces from the start of the line on which the opening curly brace is located. The closing curly brace should be located on the line following the last statement in the code block and should line up with the beginning of the line where the opening curly brace is located.  
```
if (AutosOwned == 0) {
  OwnershipCategory <- "ZeroVehHh"
  CarshareLikelihood <- "Moderate"
  CostPerMile <- 5 * AveCostPerMile
}
```

The following style should be used for if/else statements:  
```
if (HousingType == "SingleFamily" & Tenure == "Owner") {  
  ChargingPotential <- "High"
} else {
  ChargingPotential <- "Low"
}
```

### Assignment  

Use the `<-` operator to assign values. The `=` operator should be reserved for associating values with function arguments in function calls. For example:  
```
kMegajoulesPerGallon <- 121
rep(c("a", "b", "c"), each=3)
```

### Comments and Function Documentation  

Comment lines should start with a `#` and a space:  
```
# Example of a comment
```

All functions should be documented using 'roxygen2' syntax. This will enable documentation to be automatically generated using the 'devtools' package. The resulting documentation will be consistent with R package requirements. Refer to [R Packages](http://r-pkgs.had.co.nz/man.html) for more information.
