
# Initialize Module
### January 23, 2019

This module reads and processes roadway DVMT and operations inputs to check for inconsistent values which standard VisionEval data checks will not pick up.

## Model Parameter Estimation

This module has no estimated parameters.

## How the Module Works

This module checks the values in the following input files for missing values and inconsistencies that the standard VisionEval data checks will not identify:

* region_base_year_hvytrk_dvmt.csv

* marea_base_year_dvmt.csv

* marea_dvmt_split_by_road_class.csv

* marea_operations_deployment.csv

* other_ops_effectiveness.csv

* marea_congestion_charges.csv

The `region_base_year_hvytrk_dvmt.csv` and `marea_base_year_dvmt.csv` files are checked to assure that there is enough information to compute base year urban heavy truck DVMT and base year urban light-duty vehicle DVMT. These values are used in the calculation of vehicle travel on urban area roads which is are used in road performance calculations. The values in the 2 files are also checked for consistency. These inputs enable users to either declare explict values for regional heavy truck DVMT, marea urban heavy truck DVMT, and marea urban light-duty vehicle DVMT, or to specify locations (state and/or urbanized area) which are used for calculating DVMT from per capita rates tabulated for the areas from Highway Statistics data by the LoadDefaultRoadDvmtValues.R script. When DVMT input values are not specified, they are calculated from the rates for the state and/or metropolitan areas and the calculated values are used to update the input values. The procedures also check whether the sum of urban heavy truck DVMT for all mareas does not exceed the regional heavy truck DVMT. In addition, a check is made on if the model is likely to be a metropolitan model, not a state model, but a state is specified and state per capita heavy truck DVMT rates are used to calculate regional heavy truck DVMT. The value for StateAbbrLookup in the 'region_base_year_hvytrk_dvmt.csv' file should be NA in metropolitan models rather than a specific state if the regional heavy truck DVMT is not provided because the state rates may not be representative of the metropolitan rates. A warning is issued if this is the case.

If a value, rather than NA, is provided in the `StateAbbrLookup` field of the `region_base_year_hvytrk_dvmt.csv` file, the value must be a standard 2-character postal code for the state.

If a value other than NA is provided in the `UzaNameLookup` field of the `marea_base_year_dvmt.csv` file, it must be a name that is present in the following list of urbanized areas for which per capita rates are available for urban area light-duty vehicle DVMT and for urban area heavy-truck DVMT. Note that if the name of an urbanized area is not found in the list, the user can specify the name of any other urbanized area that is representative of the urbanized area being modeled.


|Column 1                                |Column 2                               |Column 3                                       |
|:---------------------------------------|:--------------------------------------|:----------------------------------------------|
|Anchorage/AK                            |Fairbanks/AK                           |Anniston/AL                                    |
|Auburn/AL                               |Birmingham/AL                          |Decatur/AL                                     |
|Dothan/AL                               |Florence/AL                            |Gadsden/AL                                     |
|Huntsville/AL                           |Mobile/AL                              |Montgomery/AL                                  |
|Tuscaloosa/AL                           |Fayetteville--Springdale/AR            |Fort Smith/AR                                  |
|Hot Springs/AR                          |Jonesboro/AR                           |Little Rock/AR                                 |
|Pine Bluff/AR                           |Avondale/AZ                            |Flagstaff/AZ                                   |
|Phoenix--Mesa/AZ                        |Prescott/AZ                            |Tucson/AZ                                      |
|Yuma/AZ                                 |Antioch/CA                             |Atascadero--El Paso de Robles (Paso Robles)/CA |
|Bakersfield/CA                          |Camarillo/CA                           |Chico/CA                                       |
|Concord/CA                              |Davis/CA                               |El Centro/CA                                   |
|Fairfield/CA                            |Fresno/CA                              |Gilroy--Morgan Hill/CA                         |
|Hemet/CA                                |Indio--Cathedral City--Palm Springs/CA |Lancaster--Palmdale/CA                         |
|Livermore/CA                            |Lodi/CA                                |Lompoc/CA                                      |
|Los Angeles--Long Beach--Santa Ana/CA   |Madera/CA                              |Manteca/CA                                     |
|Merced/CA                               |Mission Viejo/CA                       |Modesto/CA                                     |
|Napa/CA                                 |Oxnard/CA                              |Petaluma/CA                                    |
|Porterville/CA                          |Redding/CA                             |Riverside--San Bernardino/CA                   |
|Sacramento/CA                           |Salinas/CA                             |San Diego/CA                                   |
|San Francisco--Oakland/CA               |San Jose/CA                            |San Luis Obispo/CA                             |
|Santa Barbara/CA                        |Santa Clarita/CA                       |Santa Cruz/CA                                  |
|Santa Maria/CA                          |Santa Rosa/CA                          |Seaside--Monterey--Marina/CA                   |
|Simi Valley/CA                          |Stockton/CA                            |Temecula--Murrieta/CA                          |
|Thousand Oaks/CA                        |Tracy/CA                               |Turlock/CA                                     |
|Vacaville/CA                            |Vallejo/CA                             |Victorville--Hesperia--Apple Valley/CA         |
|Visalia/CA                              |Watsonville/CA                         |Yuba City/CA                                   |
|Boulder/CO                              |Colorado Springs/CO                    |Denver--Aurora/CO                              |
|Fort Collins/CO                         |Grand Junction/CO                      |Greeley/CO                                     |
|Lafayette--Louisville/CO                |Longmont/CO                            |Pueblo/CO                                      |
|Bridgeport--Stamford/CT                 |Danbury/CT                             |Hartford/CT                                    |
|New Haven/CT                            |Norwich--New London/CT                 |Waterbury/CT                                   |
|Washington/DC                           |Dover/DE                               |Bonita Springs--Naples/FL                      |
|Brooksville/FL                          |Cape Coral/FL                          |Daytona Beach--Port Orange/FL                  |
|Deltona/FL                              |Fort Walton Beach/FL                   |Gainesville/FL                                 |
|Jacksonville/FL                         |Kissimmee/FL                           |Lady Lake/FL                                   |
|Lakeland/FL                             |Leesburg--Eustis/FL                    |Miami/FL                                       |
|North Port--Punta Gorda/FL              |Ocala/FL                               |Orlando/FL                                     |
|Palm Bay--Melbourne/FL                  |Panama City/FL                         |Pensacola/FL                                   |
|Port St. Lucie/FL                       |Sarasota--Bradenton/FL                 |St. Augustine/FL                               |
|Tallahassee/FL                          |Tampa--St. Petersburg/FL               |Titusville/FL                                  |
|Vero Beach--Sebastian/FL                |Winter Haven/FL                        |Zephyrhills/FL                                 |
|Albany/GA                               |Athens-Clarke County/GA                |Atlanta/GA                                     |
|Augusta-Richmond County/GA              |Brunswick/GA                           |Columbus/GA                                    |
|Dalton/GA                               |Gainesville/GA                         |Hinesville/GA                                  |
|Macon/GA                                |Rome/GA                                |Savannah/GA                                    |
|Valdosta/GA                             |Warner Robins/GA                       |Honolulu/HI                                    |
|Kailua (Honolulu County)--Kaneohe/HI    |Ames/IA                                |Cedar Rapids/IA                                |
|Davenport/IA                            |Des Moines/IA                          |Dubuque/IA                                     |
|Iowa City/IA                            |Sioux City/IA                          |Waterloo/IA                                    |
|Boise City/ID                           |Coeur d'Alene/ID                       |Idaho Falls/ID                                 |
|Lewiston/ID                             |Nampa/ID                               |Pocatello/ID                                   |
|Bloomington--Normal/IL                  |Champaign/IL                           |Chicago/IL                                     |
|Danville/IL                             |Decatur/IL                             |DeKalb/IL                                      |
|Kankakee/IL                             |Peoria/IL                              |Rockford/IL                                    |
|Round Lake Beach--McHenry--Grayslake/IL |Springfield/IL                         |Anderson/IN                                    |
|Bloomington/IN                          |Columbus/IN                            |Elkhart/IN                                     |
|Evansville/IN                           |Fort Wayne/IN                          |Indianapolis/IN                                |
|Kokomo/IN                               |Lafayette/IN                           |Michigan City/IN                               |
|Muncie/IN                               |South Bend/IN                          |Terre Haute/IN                                 |
|Lawrence/KS                             |Topeka/KS                              |Wichita/KS                                     |
|Bowling Green/KY                        |Lexington-Fayette/KY                   |Louisville/KY                                  |
|Owensboro/KY                            |Radcliff--Elizabethtown/KY             |Alexandria/LA                                  |
|Baton Rouge/LA                          |Houma/LA                               |Lafayette/LA                                   |
|Lake Charles/LA                         |Mandeville--Covington/LA               |Monroe/LA                                      |
|New Orleans/LA                          |Shreveport/LA                          |Slidell/LA                                     |
|Barnstable Town/MA                      |Boston/MA                              |Leominster--Fitchburg/MA                       |
|New Bedford/MA                          |Pittsfield/MA                          |Springfield/MA                                 |
|Worcester/MA                            |Aberdeen--Havre de Grace--Bel Air/MD   |Baltimore/MD                                   |
|Cumberland/MD                           |Frederick/MD                           |Hagerstown/MD                                  |
|Salisbury/MD                            |St. Charles/MD                         |Westminster/MD                                 |
|Bangor/ME                               |Lewiston/ME                            |Portland/ME                                    |
|Ann Arbor/MI                            |Battle Creek/MI                        |Bay City/MI                                    |
|Benton Harbor--St. Joseph/MI            |Detroit/MI                             |Flint/MI                                       |
|Grand Rapids/MI                         |Holland/MI                             |Jackson/MI                                     |
|Kalamazoo/MI                            |Lansing/MI                             |Monroe/MI                                      |
|Muskegon/MI                             |Port Huron/MI                          |Saginaw/MI                                     |
|South Lyon--Howell--Brighton/MI         |Duluth/MN                              |Minneapolis--St. Paul/MN                       |
|Rochester/MN                            |St. Cloud/MN                           |Columbia/MO                                    |
|Jefferson City/MO                       |Joplin/MO                              |Kansas City/MO                                 |
|Springfield/MO                          |St. Joseph/MO                          |St. Louis/MO                                   |
|Gulfport--Biloxi/MS                     |Hattiesburg/MS                         |Jackson/MS                                     |
|Pascagoula/MS                           |Billings/MT                            |Great Falls/MT                                 |
|Missoula/MT                             |Asheville/NC                           |Burlington/NC                                  |
|Charlotte/NC                            |Concord/NC                             |Durham/NC                                      |
|Fayetteville/NC                         |Gastonia/NC                            |Goldsboro/NC                                   |
|Greensboro/NC                           |Greenville/NC                          |Hickory/NC                                     |
|High Point/NC                           |Jacksonville/NC                        |Raleigh/NC                                     |
|Rocky Mount/NC                          |Wilmington/NC                          |Winston-Salem/NC                               |
|Bismarck/ND                             |Fargo/ND                               |Grand Forks/ND                                 |
|Lincoln/NE                              |Omaha/NE                               |Dover--Rochester/NH                            |
|Manchester/NH                           |Nashua/NH                              |Portsmouth/NH                                  |
|Atlantic City/NJ                        |Hightstown/NJ                          |Trenton/NJ                                     |
|Vineland/NJ                             |Wildwood--North Wildwood--Cape May/NJ  |Albuquerque/NM                                 |
|Farmington/NM                           |Las Cruces/NM                          |Santa Fe/NM                                    |
|Carson City/NV                          |Las Vegas/NV                           |Reno/NV                                        |
|Albany/NY                               |Binghamton/NY                          |Buffalo/NY                                     |
|Elmira/NY                               |Glens Falls/NY                         |Ithaca/NY                                      |
|Kingston/NY                             |New York--Newark/NY                    |Poughkeepsie--Newburgh/NY                      |
|Rochester/NY                            |Saratoga Springs/NY                    |Syracuse/NY                                    |
|Utica/NY                                |Akron/OH                               |Canton/OH                                      |
|Cincinnati/OH                           |Cleveland/OH                           |Columbus/OH                                    |
|Dayton/OH                               |Lima/OH                                |Lorain--Elyria/OH                              |
|Mansfield/OH                            |Middletown/OH                          |Newark/OH                                      |
|Sandusky/OH                             |Springfield/OH                         |Toledo/OH                                      |
|Youngstown/OH                           |Lawton/OK                              |Oklahoma City/OK                               |
|Tulsa/OK                                |Bend/OR                                |Corvallis/OR                                   |
|Eugene/OR                               |Medford/OR                             |Portland/OR                                    |
|Salem/OR                                |Allentown--Bethlehem/PA                |Altoona/PA                                     |
|Erie/PA                                 |Harrisburg/PA                          |Hazleton/PA                                    |
|Johnstown/PA                            |Lancaster/PA                           |Lebanon/PA                                     |
|Monessen/PA                             |Philadelphia/PA                        |Pittsburgh/PA                                  |
|Pottstown/PA                            |Reading/PA                             |Scranton/PA                                    |
|State College/PA                        |Uniontown--Connellsville/PA            |Williamsport/PA                                |
|York/PA                                 |Aguadilla--Isabela--San Sebastian/PR   |Arecibo/PR                                     |
|Fajardo/PR                              |Florida--Barceloneta--Bajadero/PR      |Guayama/PR                                     |
|Juana Diaz/PR                           |Mayaguez/PR                            |Ponce/PR                                       |
|San German--Cabo Rojo--Sabana Grande/PR |San Juan/PR                            |Yauco/PR                                       |
|Providence/RI                           |Anderson/SC                            |Charleston--North Charleston/SC                |
|Columbia/SC                             |Florence/SC                            |Greenville/SC                                  |
|Mauldin--Simpsonville/SC                |Myrtle Beach/SC                        |Rock Hill/SC                                   |
|Spartanburg/SC                          |Sumter/SC                              |Rapid City/SD                                  |
|Sioux Falls/SD                          |Bristol/TN                             |Chattanooga/TN                                 |
|Clarksville/TN                          |Cleveland/TN                           |Jackson/TN                                     |
|Johnson City/TN                         |Kingsport/TN                           |Knoxville/TN                                   |
|Memphis/TN                              |Morristown/TN                          |Nashville-Davidson/TN                          |
|Abilene/TX                              |Amarillo/TX                            |Austin/TX                                      |
|Beaumont/TX                             |Brownsville/TX                         |College Station--Bryan/TX                      |
|Corpus Christi/TX                       |Dallas--Fort Worth--Arlington/TX       |Denton--Lewisville/TX                          |
|El Paso/TX                              |Galveston/TX                           |Harlingen/TX                                   |
|Houston/TX                              |Killeen/TX                             |Lake Jackson--Angleton/TX                      |
|Laredo/TX                               |Longview/TX                            |Lubbock/TX                                     |
|McAllen/TX                              |McKinney/TX                            |Midland/TX                                     |
|Odessa/TX                               |San Angelo/TX                          |San Antonio/TX                                 |
|Sherman/TX                              |Temple/TX                              |Texarkana/TX                                   |
|Texas City/TX                           |The Woodlands/TX                       |Tyler/TX                                       |
|Victoria/TX                             |Waco/TX                                |Wichita Falls/TX                               |
|Logan/UT                                |Ogden--Layton/UT                       |Provo--Orem/UT                                 |
|Salt Lake City/UT                       |St. George/UT                          |Blacksburg/VA                                  |
|Charlottesville/VA                      |Danville/VA                            |Fredericksburg/VA                              |
|Harrisonburg/VA                         |Lynchburg/VA                           |Richmond/VA                                    |
|Roanoke/VA                              |Virginia Beach/VA                      |Winchester/VA                                  |
|Burlington/VT                           |Bellingham/WA                          |Bremerton/WA                                   |
|Kennewick--Richland/WA                  |Longview/WA                            |Mount Vernon/WA                                |
|Olympia--Lacey/WA                       |Seattle/WA                             |Spokane/WA                                     |
|Wenatchee/WA                            |Yakima/WA                              |Appleton/WI                                    |
|Beloit/WI                               |Eau Claire/WI                          |Fond du Lac/WI                                 |
|Green Bay/WI                            |Janesville/WI                          |Kenosha/WI                                     |
|La Crosse/WI                            |Madison/WI                             |Milwaukee/WI                                   |
|Oshkosh/WI                              |Racine/WI                              |Sheboygan/WI                                   |
|Wausau/WI                               |Charleston/WV                          |Huntington/WV                                  |
|Morgantown/WV                           |Parkersburg/WV                         |Weirton--Steubenville/WV                       |
|Wheeling/WV                             |Casper/WY                              |Cheyenne/WY                                    |
|                                        |                                       |                                               |

The `marea_dvmt_split_by_road_class.csv` input file specifies the proportions of DVMT by road class for light-duty vehicles, for heavy trucks, and for buses. While this file is not optional, the user may leave entries blank. Where values are not provided, the model computes the splits using data tabulated for urbanized areas from Highway Statistics data by the LoadDefaultRoadDvmtValues.R script. The UzaNameLookup must be specified in the 'marea_base_year_dvmt.csv' for any marea for which complete data are not specified. The procedures check whether values are present for each marea or can be computed using name lookups. If values are provided, the procedures check that the sum of the splits for each vehicle type are equal to 1. If the sum is off by 1% or more, an error is flagged and a message to the log identifies the problem. If the sum is off by less than 1%, the splits are adjusted so that they sum to 1 and a warning message is written to the log. Input values are updated using values calculated from name lookups where necessary.

The `marea_operations_deployment.csv` and `other_ops_effectiveness.csv` are checked for consistency if the `other_ops_effectiveness.csv` file, which is optional, is present. If the `other_ops_effectiveness.csv` file is not present, then the values for the 'OtherFwyOpsDeployProp' and 'OtherArtOpsDeployProp' fields of the `marea_operations_deployment.csv` must be zero. If the `other_ops_effectiveness.csv` file is present but the values for delay reduction for freeways and/or arterials are 0, then the respective freeway and arterial values in the `marea_operations_deployment.csv` file must be 0 as well.

The `marea_congestion_charges.csv` is checked to determine whether congestion charges increase with congestion level (if they are not 0). If higher charges are found at lower levels than at higher levels, warnings are written to the log identifying the issue.


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### region_base_year_dvmt.csv
|NAME                  |TYPE      |UNITS  |PROHIBIT |ISELEMENTOF                                                                                                                                                                                                        |UNLIKELY |DESCRIPTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
|:---------------------|:---------|:------|:--------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|StateAbbrLookup       |character |ID     |         |AL, AK, AZ, AR, CA, CO, CT, DE, FL, GA, HI, ID, IL, IN, IA, KS, KY, LA, ME, MD, MA, MI, MN, MS, MO, MT, NE, NV, NH, NJ, NM, NY, NC, ND, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VT, VA, WA, WV, WI, WY, DC, PR, NA |         |Postal code abbreviation of state where the region is located. It is recommended that the value be NA if the model is not a state model (i.e. is a model for a metropolitan area). See the module documentation for details.                                                                                                                                                                                                                                                                                                                |
|HvyTrkDvmtGrowthBasis |character |ID     |         |Income, Population                                                                                                                                                                                                 |         |Factor used to grow heavy truck DVMT from base year value                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|HvyTrkDvmt            |compound  |MI/DAY |< 0      |                                                                                                                                                                                                                   |         |Average daily vehicle miles of travel on roadways in the region by heavy trucks during the base year. The value for this input may be NA instead of number. In that case, if a state abbreviation is provided, the base year value is calculated from the state per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year population. If the state abbreviation is NA (as for a metropolitan model) the base year value is calculated from metropolitan area per capita rates and metropolitan area population. |
|ComSvcDvmtGrowthBasis |character |ID     |         |HhDvmt, Income, Population                                                                                                                                                                                         |         |Factor used to grow commercial service vehicle DVMT in Marea from base year value                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
### marea_base_year_dvmt.csv
|   |NAME            |TYPE      |UNITS  |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                                                                                                                                                                                                                                             |
|:--|:---------------|:---------|:------|:--------|:-----------|:--------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|1  |Geo             |          |       |         |Mareas      |         |Must contain a record for each Marea which is applied to all years.                                                                                                                                                                                                                                                                                                     |
|5  |UzaNameLookup   |character |ID     |         |            |         |Name(s) of urbanized area(s) in default tables corresponding to the Marea(s). This may be omitted if values are provided for both UrbanLdvDvmt and UrbanHvyTrkDvmt. The name(s) must be consistent with names in the urbanized area names in the default data. See module documentation for a listing.                                                                  |
|6  |UrbanLdvDvmt    |compound  |MI/DAY |< 0      |            |         |Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by light-duty vehicles during the base year. This value may be omitted if a value for UzaNameLookup is provided so that a value may be computed from the urbanized area per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year urban population. |
|7  |UrbanHvyTrkDvmt |compound  |MI/DAY |< 0      |            |         |Average daily vehicle miles of travel on roadways in the urbanized portion of the Marea by heavy trucks during he base year. This value may be omitted if a value for UzaNameLookup is provided so that a value may be computed from the urbanized area per capita rate tabulated by the LoadDefaultRoadDvmtValues.R script and the base year urban population.         |
### marea_dvmt_split_by_road_class.csv
|   |NAME              |TYPE   |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                  |
|:--|:-----------------|:------|:----------|:--------|:-----------|:--------|:----------------------------------------------------------------------------------------------------------------------------|
|1  |Geo               |       |           |         |Mareas      |         |Must contain a record for each Marea which is applied to all years.                                                          |
|8  |LdvFwyDvmtProp    |double |proportion |< 0, > 1 |            |         |Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways           |
|9  |LdvArtDvmtProp    |double |proportion |< 0, > 1 |            |         |Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways  |
|10 |LdvOthDvmtProp    |double |proportion |< 0, > 1 |            |         |Proportion of light-duty daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways     |
|11 |HvyTrkFwyDvmtProp |double |proportion |< 0, > 1 |            |         |Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways          |
|12 |HvyTrkArtDvmtProp |double |proportion |< 0, > 1 |            |         |Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways |
|13 |HvyTrkOthDvmtProp |double |proportion |< 0, > 1 |            |         |Proportion of heavy truck daily vehicle miles of travel in the urbanized portion of the Marea occurring on other roadways    |
|14 |BusFwyDvmtProp    |double |proportion |< 0, > 1 |            |         |Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on freeways                  |
|15 |BusArtDvmtProp    |double |proportion |< 0, > 1 |            |         |Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occurring on arterial roadways         |
|16 |BusOthDvmtProp    |double |proportion |< 0, > 1 |            |         |Proportion of bus daily vehicle miles of travel in the urbanized portion of the Marea occuring on other roadways             |
### marea_operations_deployment.csv
|   |NAME                  |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                           |
|:--|:---------------------|:------|:----------|:------------|:-----------|:--------|:-----------------------------------------------------------------------------------------------------|
|1  |Geo                   |       |           |             |Mareas      |         |Must contain a record for each Marea and model run year.                                              |
|11 |Year                  |       |           |             |            |         |Must contain a record for each Marea and model run year.                                              |
|17 |RampMeterDeployProp   |double |proportion |< 0, > 1, NA |            |         |Proportion of freeway DVMT affected by ramp metering deployment                                       |
|18 |IncidentMgtDeployProp |double |proportion |< 0, > 1, NA |            |         |Proportion of freeway DVMT affected by incident management deployment                                 |
|19 |SignalCoordDeployProp |double |proportion |< 0, > 1, NA |            |         |Proportion of arterial DVMT affected by signal coordination deployment                                |
|20 |AccessMgtDeployProp   |double |proportion |< 0, > 1, NA |            |         |Proportion of arterial DVMT affected by access management deployment                                  |
|21 |OtherFwyOpsDeployProp |double |proportion |< 0, > 1, NA |            |         |Proportion of freeway DVMT affected by deployment of other user-defined freeway operations measures   |
|22 |OtherArtOpsDeployProp |double |proportion |< 0, > 1, NA |            |         |Proportion of arterial DVMT affected by deployment of other user-defined arterial operations measures |
### other_ops_effectiveness.csv
This input file is OPTIONAL.

|   |NAME       |TYPE      |UNITS      |PROHIBIT   |ISELEMENTOF              |UNLIKELY |DESCRIPTION                                                                                                                                   |
|:--|:----------|:---------|:----------|:----------|:------------------------|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------|
|23 |Level      |character |category   |           |None, Mod, Hvy, Sev, Ext |         |Congestion levels: None = none, Mod = moderate, Hvy = heavy, Sev = severe, Ext = extreme                                                      |
|24 |Art_Rcr    |double    |percentage |< 0, > 100 |                         |         |Percentage reduction of recurring arterial delay that would occur with full deployment of other user-defined arterial operations measures     |
|25 |Art_NonRcr |double    |percentage |< 0, > 100 |                         |         |Percentage reduction of non-recurring arterial delay that would occur with full deployment of other user-defined arterial operations measures |
|26 |Fwy_Rcr    |double    |percentage |< 0, > 100 |                         |         |Percentage reduction of recurring freeway delay that would occur with full deployment of other user-defined freeway operations measures       |
|27 |Fwy_NonRcr |double    |percentage |< 0, > 100 |                         |         |Percentage reduction of non-recurring freeway delay that would occur with full deployment of other user-defined freeway operations measures   |
### marea_congestion_charges.csv
|   |NAME           |TYPE     |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                         |
|:--|:--------------|:--------|:-----|:--------|:-----------|:--------|:---------------------------------------------------------------------------------------------------|
|1  |Geo            |         |      |         |Mareas      |         |Must contain a record for each Marea and model run year.                                            |
|11 |Year           |         |      |         |            |         |Must contain a record for each Marea and model run year.                                            |
|28 |FwyNoneCongChg |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of no congestion        |
|29 |FwyModCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of moderate congestion  |
|30 |FwyHvyCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of heavy congestion     |
|31 |FwySevCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of severe congestion    |
|32 |FwyExtCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on freeways during periods of extreme congestion   |
|33 |ArtNoneCongChg |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of no congestion       |
|34 |ArtModCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of moderate congestion |
|35 |ArtHvyCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of heavy congestion    |
|36 |ArtSevCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of severe congestion   |
|37 |ArtExtCongChg  |currency |USD   |< 0      |            |         |Charge per mile (U.S. dollars) of vehicle travel on arterials during periods of extreme congestion  |

## Datasets Used by the Module
The following table documents each dataset that is retrieved from the datastore and used by the module. Each row in the table describes a dataset. All the datasets must be present in the datastore. One or more of these datasets may be entered into the datastore from the user input files. The table names and their meanings are as follows:

NAME - The dataset name.

TABLE - The table in the datastore that the data is retrieved from.

GROUP - The group in the datastore where the table is located. Note that the datastore has a group named 'Global' and groups for every model run year. For example, if the model run years are 2010 and 2050, then the datastore will have a group named '2010' and a group named '2050'. If the value for 'GROUP' is 'Year', then the dataset will exist in each model run year group. If the value for 'GROUP' is 'BaseYear' then the dataset will only exist in the base year group (e.g. '2010'). If the value for 'GROUP' is 'Global' then the dataset will only exist in the 'Global' group.

TYPE - The data type. The framework uses the type to check units and inputs. Refer to the model system design and users guide for information on allowed types.

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values in the datastore do not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Values in the datastore are one or more of the listed values.

|NAME     |TABLE |GROUP |TYPE      |UNITS |PROHIBIT |ISELEMENTOF |
|:--------|:-----|:-----|:---------|:-----|:--------|:-----------|
|RuralPop |Marea |Year  |people    |PRSN  |NA, < 0  |            |
|TownPop  |Marea |Year  |people    |PRSN  |NA, < 0  |            |
|UrbanPop |Marea |Year  |people    |PRSN  |NA, < 0  |            |
|Marea    |Marea |Year  |character |ID    |         |            |

## Datasets Produced by the Module
This module produces no datasets to store in the datastore.
