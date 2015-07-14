## RSPM Framework Coding Style Guidelines  
**Brian Gregor, Oregon Systems Analytics LLC**  
**July 14, 2015**  

The RSPM framework is intended to become a large open collaborative project for developing disaggregate strategic planning models. Model developers will create and document models that may be combined with the models of other developers in a "plug-and-play" manner. Models will be distributed in standard R packages. These packages will include the code used to estimate the models as well as code for implementing the models. Making model estimation and implementation code open will encourage innovation and make models more robust. 

This open collaborative approach increases the importance of coding style guidelines. The purpose of this memo is to describe the coding style guidelines for packages built for the RSPM framework. For the most part, these guidelines follow [Google's R Style Guide](https://google-styleguide.googlecode.com/svn/trunk/Rguide.xml) fairly closely. They also draw from [Hadley Wickham's recommended style guidelines](http://r-pkgs.had.co.nz/r.html). While those guidelines are similar, they differ with respect to object naming and function documentation. Rather than duplicate all of Google's and Wickham's guidelines and example, this memo summarizes the guidelines except where there are significant differences with the two. In addition, the following guidelines establish a system for naming objects so that it is possible to understand the basic structure of the objects from their names.

###File Names###
Punctuation in names should be limited to underscores and hyphens. Avoid using capital letters because the Windows file system ignores letter case but other file systems do not. Don't use spaces in names.

The names for R scripts should identify the purpose of the script. The file extension should be ".R". For example:
`estimate_income_model.R`

A binary R files should be named using the object name that will be created when it is loaded. The file extension should be ".RData". For example:  
`PopGrowth_UaYr.RData`  
See the next section for an explanation of the object name in this example. 

###Object Names###
Google and Wickham recommend different styles for object names. Google recommends using periods (`.`) or camel case (e.g. `CamelCase`) to distinguish 'words' in a name, whereas Wickham recommends using underscores (`_`) or camel case. Wickham recommends against using periods because periods are often used to denote S3 methods (e.g. `print.lm`). Object naming for the RSPM framework should only use camel case to distinguish words in a name. Periods should only be used to denote S3 methods. Underscores should only be used to describe object structure as described below. 

Names should be concise and descriptive. Nouns should be used in the names of objects that are not functions. The first letter of the name should be capitalized. For example:  
`DailyTrips`  
Function names should start with a verb. The first letter should not be capitalized to further distinguish functions from other objects. For example:  
`calcAveTripRate`  
  
Although this approach to capitalization is opposite Google's (which recommends capitalization of functions but not variables), there is good reason for it. The capability in R to operate on the language offers opportunities for programmatically combining objects and creating associated names by concatenating the object names. When this is done using objects that are named using the RSPM framework style guidelines, the resulting names will meet the style guidelines as well. For example, combining `BikeTrp` and `WalkTrp` would result in `BikeTrpWalkTrp`. The Google naming approach will not result in names that meet the style guidelines (e.g. `bikeTrpwalkTrp`). Since functions wouldn't be combined in this way, it is not a liability to start their names with small letters.

It is recommended the names of constants start with `k`. This is what Google recommends. For example:  
`kMegajoulesPerGallon`  

As noted above, underscores are used to represent object structure. One of the reasons why the R language is so capable for data analysis is that it includes a number of different object structures for representing data. These include vectors, two-dimensional matrices, n-dimensional arrays, lists, and data frames (as well as data structures enabled by add-on packages such as the data.table package). Moreover, the R language has a number of functions which facilitate iterating over these data structures. One downside of this flexibility is that in order to understand code that someone else has written (or that you may have written months or years ago), it is necessary to understand the structure of the objects being operated on. This is not always easy to do. For example, an object named `DailyTrips` might be a vector of daily trips by trip purpose, a matrix of daily trips by origin and destination, or perhaps at data frame of trips by person identifying origin, destination and purpose. To improve code readability, these naming guidelines use the underscore character and abbreviations to describe the structure of a data object.

The underscore is used to note that an object is more complex than a scalar. (Strictly speaking, there are no scalars in R. A scalar is a vector having a length of 1. However, it can be useful to consider some objects to be scalars and to name them so that they are considered in that way.) For example `DailyTrips` would denote a single value while `DailyTrips_` would denote a more complex set of values. A 2-letter abbreviation is used after the underscore to indicate the structure of the object where: 
 
- vc = vector  
- mx = matrix  
- ar = array  
- ls = list  
- df = data frame  
- dt = data table  

So for example, a vector of daily trips by trip purpose could be named `DailyTrips_vc` while a matrix of daily trips by origin and destination could be named `DailyTrips_mx`.

If the object represents a certain class such as a linear model then the abbreviation after the underscore should identify the class. The meaning of the abbreviation should be described in a comment unless it is commonly understood. For example, `DvmtModel_lm` would identify a linear model object. In some cases the class abbreviation will need to be longer than two letters to adequately distinguish it from objects of another class.

Often several objects used in model calculations have one or more dimensions that are the same. For example, a matrix may contain daily trip productions by model zone (rows) and trip purpose (columns). One calculation may need to sum up the trip productions by model zone. Another calculation may need to sum up by trip purpose. In situations like this, it is very handy and informative to denote each dimension by a 2-letter abbreviation and to use those abbreviations to describe the structure of the data objects. So, for example, if model zones are denoted as `Zn` and trip purposes as `Pr`, then the matrix of trip productions by model zone and purpose could be named `Trips_mx_ZnPr`. The corresponding vectors of trip productions by zone and by purpose would be `Trips_vc_Zn` and `Trips_vc_Pr` respectively. Where the structure of a vector, matrix or array would be completely described with these abbreviations, it is unnecessary to include the abbreviation for the class. For example, you could use `Trips_ZnPr` instead of `Trips_mx_ZnPr`. 

Furthermore, it is strongly encouraged, that naming vectors be defined in the code to associate dimension names with each of these vectors. For example:  
```
Pr <- c("Work", "Shopping", "School", "Other")  #Trip purposes
Zn <- c("101", "102", "201", "202", "203", "301", "302")  #Model Zones
```
Doing this not only makes it easier for everyone to understand the code, it also makes it easier to name the dimensions of objects consistently and to make sure that objects conform to one another. For example:  
```
rownames(Trips_ZnPr) <- Zn
colnames(Trips_ZnPr) <- Pr
WorkTrips_ZnZn <- array(0, dim=c(length(Zn), length(Zn)),   
                        dimnames=list(Zn, Zn))
for (zn in Zn ) {
  do something here
}
```
In the cases of data frames and data tables, the rows may often correspond to records for some population and columns to attributes of the population. For example, rows might correspond to model zones and columns might refer to attributes of the zones. In such a case, the row dimension might be named. For example, a data frame which contains various land use attributes for model zones might be named `LandUse_df_Zn`.  

Since the columns of data frames and data tables hold various types of data which don't usually correspond to regular dimension, it is usually unnecessary to name that dimension. If the columns as well as rows do correspond to a regular dimension, then it probably would be better to represent the object as a matrix rather than a data frame or data table.

It should be noted that this object naming approach differs from the approach previously used by ODOT in the GreenSTEP and RSPM models. While the approach used previously also used two character abbreviations to denote dimensions, it also used periods in the naming system to distinguish between various data structures. The use of periods has been dropped and replaced with underscores and abbreviations to avoid conflicting with the use of the period to denote S3 methods.  

###Line Length and Indentation  

Lines should not exceed 80 characters in length. Lines that are longer in length should be split. 

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

###Spacing  

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

###Statements, Code Blocks, and Curly Braces###

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

###Assignment  

Use the `<-` operator to assign values. The `=` operator should be reserved for associating values with function arguments in function calls. For example:  
```
kMegajoulesPerGallon <- 121
rep(c("a", "b", "c"), each=3)
```

###Comments and Function Documentation  

Comment lines should start with a `#` and a space:  
```
# Example of a comment
```

All functions should be documented using 'roxygen2' syntax. This will enable documentation to be automatically generated using the 'devtools' package. The resulting documentation will be consistent with R package requirements. Refer to [R Packages](http://r-pkgs.had.co.nz/man.html) for more information.
