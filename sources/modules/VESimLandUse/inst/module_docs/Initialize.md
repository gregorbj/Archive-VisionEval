# Initialize Module
### November 27, 2018

Modules in the VESimLandUse package synthesize Bzones and their land use attributes as a function of Azone characteristics as well as data derived from the US Environmental Protection Agency's Smart Location Database (SLD) augmented with US Census housing and household income data, and data from the National Transit Database. Details on these data are included in the VESimLandUseData package. The combined dataset contains a number of land use attributes at the US Census block group level. The goal of Bzone synthesis to generate a set of SimBzones in each Azone that reasonably represent block group land use characteristics given the characteristics of the Azone, the Marea that the Azone is a part of, and scenario inputs provided by the user.

Many of the models and procedures used in Bzone synthesis pivot from profiles developed from these data sources for specific urbanized areas, as well as more general profiles for different urbanized area population size categories, towns, and rural areas. Using these specific and general profiles enables the simulated Bzones (SimBzones) to better represent the areas being modeled and the variety of conditions found in different states. Following is a listing of the urbanized areas for which profiles have been developed. Note that urbanized areas that cross state lines are split into the individual state components. This is done to faciliate the development of state models and to better reflect the characteristics of the urbanized area characteristics in each state.

It is incumbent on the model user to identify the name of the urbanized area profile that will be used for each of the Mareas in the model. This module reads in the names assigned in the "marea_uza_profile_names.csv" file and checks their validity. If any are invalid, input processing will stop and error messages will be written to the log identifying the problem names. The following table identifies the names that may be used.


|Column 1                                 |Column 2                                       |Column 3                                               |
|:----------------------------------------|:----------------------------------------------|:------------------------------------------------------|
|Aberdeen-Bel Air South-Bel Air North, MD |Abilene, TX                                    |Akron, OH                                              |
|Albany-Schenectady, NY                   |Albany, GA                                     |Albany, OR                                             |
|Albuquerque, NM                          |Alexandria, LA                                 |Allentown, NJ                                          |
|Allentown, PA                            |Alton, IL                                      |Altoona, PA                                            |
|Amarillo, TX                             |Ames, IA                                       |Anchorage, AK                                          |
|Anderson, IN                             |Anderson, SC                                   |Ann Arbor, MI                                          |
|Anniston-Oxford, AL                      |Antioch, CA                                    |Appleton, WI                                           |
|Arroyo Grande-Grover Beach, CA           |Asheville, NC                                  |Athens-Clarke County, GA                               |
|Atlanta, GA                              |Atlantic City, NJ                              |Auburn, AL                                             |
|Augusta-Richmond County, GA              |Augusta-Richmond County, SC                    |Austin, TX                                             |
|Avondale-Goodyear, AZ                    |Bakersfield, CA                                |Baltimore, MD                                          |
|Bangor, ME                               |Barnstable Town, MA                            |Baton Rouge, LA                                        |
|Battle Creek, MI                         |Bay City, MI                                   |Beaumont, TX                                           |
|Beckley, WV                              |Bellingham, WA                                 |Beloit, IL                                             |
|Beloit, WI                               |Bend, OR                                       |Benton Harbor-St. Joseph-Fair Plain, MI                |
|Billings, MT                             |Binghamton, NY                                 |Binghamton, PA                                         |
|Birmingham, AL                           |Bismarck, ND                                   |Blacksburg, VA                                         |
|Bloomington-Normal, IL                   |Bloomington, IN                                |Boise City, ID                                         |
|Bonita Springs, FL                       |Boston, MA                                     |Boston, NH                                             |
|Boulder, CO                              |Bowling Green, KY                              |Bremerton, WA                                          |
|Bridgeport-Stamford, CT                  |Bridgeport-Stamford, NY                        |Bristol-Bristol, TN                                    |
|Bristol-Bristol, VA                      |Brownsville, TX                                |Brunswick, GA                                          |
|Buffalo, NY                              |Burlington, NC                                 |Burlington, VT                                         |
|Camarillo, CA                            |Canton, OH                                     |Cape Coral, FL                                         |
|Cape Girardeau, MO                       |Carbondale, IL                                 |Carson City, NV                                        |
|Cartersville, GA                         |Casa Grande, AZ                                |Casper, WY                                             |
|Cedar Rapids, IA                         |Chambersburg, PA                               |Champaign, IL                                          |
|Charleston-North Charleston, SC          |Charleston, WV                                 |Charlotte, NC                                          |
|Charlotte, SC                            |Charlottesville, VA                            |Chattanooga, GA                                        |
|Chattanooga, TN                          |Cheyenne, WY                                   |Chicago, IL                                            |
|Chicago, IN                              |Chico, CA                                      |Cincinnati, IN                                         |
|Cincinnati, KY                           |Cincinnati, OH                                 |Clarksville, KY                                        |
|Clarksville, TN                          |Cleveland, OH                                  |Cleveland, TN                                          |
|Coeur d'Alene, ID                        |College Station-Bryan, TX                      |Colorado Springs, CO                                   |
|Columbia, MO                             |Columbia, SC                                   |Columbus, AL                                           |
|Columbus, GA                             |Columbus, IN                                   |Columbus, OH                                           |
|Concord, CA                              |Concord, NC                                    |Conroe-The Woodlands, TX                               |
|Conway, AR                               |Cookeville, TN                                 |Corpus Christi, TX                                     |
|Corvallis, OR                            |Cumberland, MD                                 |Cumberland, WV                                         |
|Dallas-Fort Worth-Arlington, TX          |Dalton, GA                                     |Danbury, CT                                            |
|Danbury, NY                              |Davenport, IA                                  |Davenport, IL                                          |
|Davis, CA                                |Dayton, OH                                     |Decatur, AL                                            |
|Decatur, IL                              |DeKalb, IL                                     |Deltona, FL                                            |
|Denton-Lewisville, TX                    |Denver-Aurora, CO                              |Des Moines, IA                                         |
|Detroit, MI                              |Dothan, AL                                     |Dover-Rochester, ME                                    |
|Dover-Rochester, NH                      |Dover, DE                                      |Dubuque, IA                                            |
|Dubuque, IL                              |Duluth, MN                                     |Duluth, WI                                             |
|Durham, NC                               |East Stroudsburg, PA                           |Eau Claire, WI                                         |
|El Centro-Calexico, CA                   |El Paso de Robles (Paso Robles)-Atascadero, CA |El Paso, NM                                            |
|El Paso, TX                              |Elizabethtown-Radcliff, KY                     |Elkhart, IN                                            |
|Elmira, NY                               |Enid, OK                                       |Erie, PA                                               |
|Eugene, OR                               |Evansville, IN                                 |Evansville, KY                                         |
|Fairbanks, AK                            |Fairfield, CA                                  |Fargo, MN                                              |
|Fargo, ND                                |Fayetteville-Springdale-Rogers, AR             |Fayetteville, NC                                       |
|Flagstaff, AZ                            |Flint, MI                                      |Florence, AL                                           |
|Florence, SC                             |Fond du Lac, WI                                |Fort Collins, CO                                       |
|Fort Smith, AR                           |Fort Smith, OK                                 |Fort Walton Beach-Navarre-Wright, FL                   |
|Fort Wayne, IN                           |Frederick, MD                                  |Fredericksburg, VA                                     |
|Fresno, CA                               |Gadsden, AL                                    |Gainesville, FL                                        |
|Gainesville, GA                          |Gastonia, NC                                   |Gilroy-Morgan Hill, CA                                 |
|Goldsboro, NC                            |Grand Forks, MN                                |Grand Forks, ND                                        |
|Grand Island, NE                         |Grand Junction, CO                             |Grand Rapids, MI                                       |
|Grants Pass, OR                          |Great Falls, MT                                |Greeley, CO                                            |
|Green Bay, WI                            |Greensboro, NC                                 |Greenville, NC                                         |
|Greenville, SC                           |Gulfport, MS                                   |Hagerstown, MD                                         |
|Hagerstown, PA                           |Hagerstown, WV                                 |Hammond, LA                                            |
|Hanford, CA                              |Hanover, PA                                    |Harlingen, TX                                          |
|Harrisburg, PA                           |Harrisonburg, VA                               |Hartford, CT                                           |
|Hattiesburg, MS                          |Hazleton, PA                                   |Hemet, CA                                              |
|Hickory, NC                              |High Point, NC                                 |Hilton Head Island, SC                                 |
|Holland, MI                              |Hollister, CA                                  |Homosassa Springs-Beverly Hills-Citrus Springs, FL     |
|Hot Springs, AR                          |Houma, LA                                      |Houston, TX                                            |
|Huntington, KY                           |Huntington, OH                                 |Huntington, WV                                         |
|Huntsville, AL                           |Idaho Falls, ID                                |Indianapolis, IN                                       |
|Indio-Cathedral City, CA                 |Iowa City, IA                                  |Ithaca, NY                                             |
|Jackson, MI                              |Jackson, MS                                    |Jackson, TN                                            |
|Jacksonville, FL                         |Jacksonville, NC                               |Jamestown, NY                                          |
|Janesville, WI                           |Jefferson City, MO                             |Johnson City, TN                                       |
|Johnstown, PA                            |Jonesboro, AR                                  |Joplin, MO                                             |
|Kahului, HI                              |Kailua (Honolulu County)-Kaneohe, HI           |Kalamazoo, MI                                          |
|Kankakee, IL                             |Kansas City, KS                                |Kansas City, MO                                        |
|Kennewick-Pasco, WA                      |Kenosha, WI                                    |Killeen, TX                                            |
|Kingman, AZ                              |Kingsport, TN                                  |Kingston, NY                                           |
|Kissimmee, FL                            |Knoxville, TN                                  |Kokomo, IN                                             |
|La Crosse, MN                            |La Crosse, WI                                  |Lady Lake-The Villages, FL                             |
|Lafayette-Louisville-Erie, CO            |Lafayette, IN                                  |Lafayette, LA                                          |
|Lake Charles, LA                         |Lake Havasu City, AZ                           |Lake Jackson-Angleton, TX                              |
|Lakeland, FL                             |Lancaster-Palmdale, CA                         |Lancaster, PA                                          |
|Lansing, MI                              |Laredo, TX                                     |Las Cruces, NM                                         |
|Las Vegas-Henderson, NV                  |Lawrence, KS                                   |Lawton, OK                                             |
|Lebanon, PA                              |Lee's Summit, MO                               |Leesburg-Eustis-Tavares, FL                            |
|Leominster-Fitchburg, MA                 |Lewiston, ID                                   |Lewiston, ME                                           |
|Lewiston, WA                             |Lexington-Fayette, KY                          |Lexington Park-California-Chesapeake Ranch Estates, MD |
|Lima, OH                                 |Lincoln, NE                                    |Little Rock, AR                                        |
|Livermore, CA                            |Lodi, CA                                       |Logan, UT                                              |
|Lompoc, CA                               |Longmont, CO                                   |Longview, OR                                           |
|Longview, TX                             |Longview, WA                                   |Lorain-Elyria, OH                                      |
|Los Angeles-Long Beach-Anaheim, CA       |Los Lunas, NM                                  |Louisville/Jefferson County, IN                        |
|Louisville/Jefferson County, KY          |Lubbock, TX                                    |Lynchburg, VA                                          |
|Macon, GA                                |Madera, CA                                     |Madison, WI                                            |
|Manchester, NH                           |Mandeville-Covington, LA                       |Manhattan, KS                                          |
|Mankato, MN                              |Mansfield, OH                                  |Manteca, CA                                            |
|Marion, OH                               |Marysville, WA                                 |Mauldin-Simpsonville, SC                               |
|McAllen, TX                              |McKinney, TX                                   |Medford, OR                                            |
|Memphis, AR                              |Memphis, MS                                    |Memphis, TN                                            |
|Merced, CA                               |Miami, FL                                      |Michigan City-La Porte, IN                             |
|Middletown, NY                           |Middletown, OH                                 |Midland, MI                                            |
|Midland, TX                              |Milwaukee, WI                                  |Minneapolis-St. Paul, MN                               |
|Minot, ND                                |Mission Viejo-Lake Forest-San Clemente, CA     |Missoula, MT                                           |
|Mobile, AL                               |Modesto, CA                                    |Monessen-California, PA                                |
|Monroe, LA                               |Monroe, MI                                     |Montgomery, AL                                         |
|Morgantown, WV                           |Mount Vernon, WA                               |Muncie, IN                                             |
|Murfreesboro, TN                         |Murrieta-Temecula-Menifee, CA                  |Muskegon, MI                                           |
|Myrtle Beach-Socastee, NC                |Myrtle Beach-Socastee, SC                      |Nampa, ID                                              |
|Napa, CA                                 |Nashua, NH                                     |Nashville-Davidson, TN                                 |
|New Bedford, MA                          |New Haven, CT                                  |New Orleans, LA                                        |
|New York-Newark, NJ                      |New York-Newark, NY                            |Newark, OH                                             |
|Norman, OK                               |North Port-Port Charlotte, FL                  |Norwich-New London, CT                                 |
|Norwich-New London, RI                   |Ocala, FL                                      |Odessa, TX                                             |
|Ogden-Layton, UT                         |Oklahoma City, OK                              |Olympia-Lacey, WA                                      |
|Omaha, IA                                |Omaha, NE                                      |Orlando, FL                                            |
|Oshkosh, WI                              |Owensboro, KY                                  |Oxnard, CA                                             |
|Paducah, KY                              |Palm Bay-Melbourne, FL                         |Palm Coast-Daytona Beach-Port Orange, FL               |
|Panama City, FL                          |Parkersburg, OH                                |Parkersburg, WV                                        |
|Pensacola, AL                            |Pensacola, FL                                  |Peoria, IL                                             |
|Petaluma, CA                             |Philadelphia, DE                               |Philadelphia, MD                                       |
|Philadelphia, NJ                         |Philadelphia, PA                               |Phoenix-Mesa, AZ                                       |
|Pine Bluff, AR                           |Pittsburgh, PA                                 |Pittsfield, MA                                         |
|Pocatello, ID                            |Port Arthur, TX                                |Port Huron, MI                                         |
|Port St. Lucie, FL                       |Porterville, CA                                |Portland, ME                                           |
|Portland, OR                             |Portland, WA                                   |Portsmouth, ME                                         |
|Portsmouth, NH                           |Pottstown, PA                                  |Poughkeepsie-Newburgh, NJ                              |
|Poughkeepsie-Newburgh, NY                |Prescott Valley-Prescott, AZ                   |Providence, MA                                         |
|Providence, RI                           |Provo-Orem, UT                                 |Pueblo, CO                                             |
|Quincy, IL                               |Racine, WI                                     |Raleigh, NC                                            |
|Rapid City, SD                           |Reading, PA                                    |Redding, CA                                            |
|Reedley-Dinuba, CA                       |Reno, NV                                       |Richmond, VA                                           |
|Riverside-San Bernardino, CA             |Roanoke, VA                                    |Rochester, MN                                          |
|Rochester, NY                            |Rock Hill, SC                                  |Rockford, IL                                           |
|Rocky Mount, NC                          |Rome, GA                                       |Round Lake Beach-McHenry-Grayslake, IL                 |
|Round Lake Beach-McHenry-Grayslake, WI   |Sacramento, CA                                 |Saginaw, MI                                            |
|Salem, OR                                |Salina, KS                                     |Salinas, CA                                            |
|Salisbury, DE                            |Salisbury, MD                                  |Salt Lake City-West Valley City, UT                    |
|San Angelo, TX                           |San Antonio, TX                                |San Diego, CA                                          |
|San Francisco-Oakland, CA                |San Jose, CA                                   |San Luis Obispo, CA                                    |
|San Marcos, TX                           |Santa Barbara, CA                              |Santa Clarita, CA                                      |
|Santa Cruz, CA                           |Santa Fe, NM                                   |Santa Maria, CA                                        |
|Santa Rosa, CA                           |Sarasota-Bradenton, FL                         |Saratoga Springs, NY                                   |
|Savannah, GA                             |Scranton, PA                                   |Seaside-Monterey, CA                                   |
|Seattle, WA                              |Sebastian-Vero Beach South-Florida Ridge, FL   |Sebring-Avon Park, FL                                  |
|Selma, CA                                |Sheboygan, WI                                  |Sherman, TX                                            |
|Shreveport, LA                           |Sierra Vista, AZ                               |Simi Valley, CA                                        |
|Sioux City, IA                           |Sioux City, NE                                 |Sioux Falls, SD                                        |
|Slidell, LA                              |South Bend, IN                                 |South Bend, MI                                         |
|South Lyon-Howell, MI                    |Spartanburg, SC                                |Spokane, WA                                            |
|Spring Hill, FL                          |Springfield, CT                                |Springfield, IL                                        |
|Springfield, MA                          |Springfield, MO                                |Springfield, OH                                        |
|St. Augustine, FL                        |St. Cloud, MN                                  |St. George, UT                                         |
|St. Joseph, KS                           |St. Joseph, MO                                 |St. Louis, IL                                          |
|St. Louis, MO                            |State College, PA                              |Staunton-Waynesboro, VA                                |
|Stillwater, OK                           |Stockton, CA                                   |Sumter, SC                                             |
|Syracuse, NY                             |Tallahassee, FL                                |Tampa-St. Petersburg, FL                               |
|Temple, TX                               |Terre Haute, IN                                |Texarkana-Texarkana, AR                                |
|Texarkana-Texarkana, TX                  |Texas City, TX                                 |Thousand Oaks, CA                                      |
|Titusville, FL                           |Toledo, MI                                     |Toledo, OH                                             |
|Topeka, KS                               |Tracy, CA                                      |Trenton, NJ                                            |
|Tucson, AZ                               |Tulsa, OK                                      |Turlock, CA                                            |
|Tuscaloosa, AL                           |Twin Falls, ID                                 |Twin Rivers-Hightstown, NJ                             |
|Tyler, TX                                |Uniontown-Connellsville, PA                    |Urban Honolulu, HI                                     |
|Utica, NY                                |Vacaville, CA                                  |Valdosta, GA                                           |
|Vallejo, CA                              |Victoria, TX                                   |Victorville-Hesperia, CA                               |
|Vineland, NJ                             |Virginia Beach, VA                             |Visalia, CA                                            |
|Waco, TX                                 |Waldorf, MD                                    |Walla Walla, OR                                        |
|Walla Walla, WA                          |Warner Robins, GA                              |Washington, DC                                         |
|Washington, MD                           |Washington, VA                                 |Waterbury, CT                                          |
|Waterloo, IA                             |Watertown, NY                                  |Watsonville, CA                                        |
|Wausau, WI                               |Weirton-Steubenville, OH                       |Weirton-Steubenville, WV                               |
|Wenatchee, WA                            |West Bend, WI                                  |Westminster-Eldersburg, MD                             |
|Wheeling, OH                             |Wheeling, WV                                   |Wichita Falls, TX                                      |
|Wichita, KS                              |Williamsburg, VA                               |Williamsport, PA                                       |
|Wilmington, NC                           |Winchester, VA                                 |Winston-Salem, NC                                      |
|Winter Haven, FL                         |Woodland, CA                                   |Worcester, CT                                          |
|Worcester, MA                            |Yakima, WA                                     |York, PA                                               |
|Youngstown, OH                           |Youngstown, PA                                 |Yuba City, CA                                          |
|Yuma, AZ                                 |Zephyrhills, FL                                |small                                                  |
|medium-small                             |medium                                         |medium-large                                           |
|large                                    |very-large                                     |                                                       |

Note that at the bottom of the table are 6 generic names for urbanized areas of different sizes. If an urbanized area being modeled is not listed in the table, the user may substitute one of these generic names, or may use the name of a different urbanized area that the user believes has similar characteristics. The generic categories represent urbanized areas of different sizes measured by the total numbers of households and jobs in the area as follows:

* **small**: 0 - 50,000 households and jobs

* **medium-small**: 50,001 - 100,000 households and jobs

* **medium**: 100,001 - 500,000 households and jobs

* **medium-large**: 500,001 - 1,000,000 households and jobs

* **large**: 1,000,001 - 5,000,000 households and jobs

* **very-large**: More than 5,000,000 households and jobs


## User Inputs
The following table(s) document each input file that must be provided in order for the module to run correctly. User input files are comma-separated valued (csv) formatted text files. Each row in the table(s) describes a field (column) in the input file. The table names and their meanings are as follows:

NAME - The field (column) name in the input file. Note that if the 'TYPE' is 'currency' the field name must be followed by a period and the year that the currency is denominated in. For example if the NAME is 'HHIncomePC' (household per capita income) and the input values are in 2010 dollars, the field name in the file must be 'HHIncomePC.2010'. The framework uses the embedded date information to convert the currency into base year currency amounts. The user may also embed a magnitude indicator if inputs are in thousand, millions, etc. The VisionEval model system design and users guide should be consulted on how to do that.

TYPE - The data type. The framework uses the type to check units and inputs. The user can generally ignore this, but it is important to know whether the 'TYPE' is 'currency'

UNITS - The units that input values need to represent. Some data types have defined units that are represented as abbreviations or combinations of abbreviations. For example 'MI/HR' means miles per hour. Many of these abbreviations are self evident, but the VisionEval model system design and users guide should be consulted.

PROHIBIT - Values that are prohibited. Values may not meet any of the listed conditions.

ISELEMENTOF - Categorical values that are permitted. Value must be one of the listed values.

UNLIKELY - Values that are unlikely. Values that meet any of the listed conditions are permitted but a warning message will be given when the input data are processed.

DESCRIPTION - A description of the data.

### marea_uza_profile_names.csv
|NAME           |TYPE      |UNITS |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                                                        |
|:--------------|:---------|:-----|:--------|:-----------|:--------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|Geo            |          |      |         |Mareas      |         |Must contain a record for each Marea which is applied to all years.                                                                                                                |
|UzaProfileName |character |ID    |         |            |         |Name of a specific urbanized area for the urbanized area profile to use in SimBzone creation or one of the following: small, medium-small, medium, medium-large, large, very-large |
### azone_hh_loc_type_prop.csv
|NAME        |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                 |
|:-----------|:------|:----------|:------------|:-----------|:--------|:-------------------------------------------------------------------------------------------|
|Geo         |       |           |             |Azones      |         |Must contain a record for each Azone and model run year.                                    |
|Year        |       |           |             |            |         |Must contain a record for each Azone and model run year.                                    |
|PropMetroHh |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in the metropolitan (i.e. urbanized) part of the Azone    |
|PropTownHh  |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in towns (i.e. urban-like but not urbanized) in the Azone |
|PropRuralHh |double |proportion |NA, < 0, > 1 |            |         |Proportion of households residing in rural (i.e. not urbanized or town) parts of the Azone  |
### azone_wkr_loc_type_prop.csv
|   |NAME               |TYPE   |UNITS      |PROHIBIT     |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                 |
|:--|:------------------|:------|:----------|:------------|:-----------|:--------|:-------------------------------------------------------------------------------------------------------------------------------------------|
|1  |Geo                |       |           |             |Azones      |         |Must contain a record for each Azone and model run year.                                                                                    |
|11 |Year               |       |           |             |            |         |Must contain a record for each Azone and model run year.                                                                                    |
|5  |PropWkrInMetroJobs |double |proportion |NA, < 0, > 1 |            |         |Proportion of workers residing in the Azone who work at jobs in the metropolitan (i.e. urbanized) area associated with the Azone            |
|6  |PropWkrInTownJobs  |double |proportion |NA, < 0, > 1 |            |         |Proportion of workers residing in the Azone who work at jobs in towns (i.e. urban-like but not urbanized) in the Azone                      |
|7  |PropWkrInRuralJobs |double |proportion |NA, < 0, > 1 |            |         |Proportion of workers residing in the Azone who work at jobs in rural (i.e. not urbanized or town) parts of the Azone                       |
|8  |PropMetroJobs      |double |proportion |NA, < 0, > 1 |            |         |Proportion of the jobs of the metropolitan area that the Azone is associated with that are located in the metropolitan portion of the Azone |
### azone_loc_type_land_area.csv
|   |NAME            |TYPE     |UNITS      |PROHIBIT |ISELEMENTOF |UNLIKELY |DESCRIPTION                                                                                                                                                                                                                              |
|:--|:---------------|:--------|:----------|:--------|:-----------|:--------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|1  |Geo             |         |           |         |Azones      |         |Must contain a record for each Azone and model run year.                                                                                                                                                                                 |
|12 |Year            |         |           |         |            |         |Must contain a record for each Azone and model run year.                                                                                                                                                                                 |
|9  |MetroLandArea   |area     |SQMI       |NA, < 0  |            |         |Land area (excluding large water bodies and large tracts of undevelopable land) in the metropolitan (i.e. urbanized) portion of the Azone                                                                                                |
|10 |TownLandArea    |area     |SQMI       |NA, < 0  |            |         |Land area (excluding large water bodies and large tracts of undevelopable land) in towns (i.e. urban-like but not urbanized) in the Azone                                                                                                |
|11 |RuralAveDensity |compound |HHJOB/ACRE |NA, < 0  |            |> 0.5    |Average activity density (households and jobs per acre) of rural (i.e. not metropolitan or town) portions of the Azone not including large waterbodies or large tracts of agricultural lands, forest lands, or otherwise protected lands |

## Datasets Used by the Module
This module uses no datasets that are in the datastore.

## Datasets Produced by the Module
This module produces no datasets to store in the datastore.
