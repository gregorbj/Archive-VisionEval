
## LoadDefaultRoadDvmtValues
### January 23, 2019

This script calculates default values for base year roadway DVMT by vehicle type (light-duty, heavy truck, bus), the distribution of roadway DVMT by vehicle type to roadway classes (freeway, arterial, other), and the ratio of commercial service light-duty vehicle travel to household vehicle travel. These values are calculated at the state level and at the urbanized area level. This simplifies how the modules in the VETravelPerformance package are used because the user may elect to use default data for their metropolitan or state model or they may supply their own data as user inputs. The following datasets are saved as a components of the RoadDvmtModel_ls list:

* HvyTrkDvmtPC_St: the ratio of heavy truck DVMT to population by state;

* HvyTrkDvmtUrbanProp_St: the proportion of heavy truck DVMT occurring within urban areas of each state;

* UzaHvyTrkDvmtPC_Ua: the ratio of heavy truck DVMT to population by urbanized area;

* UzaLDVDvmtPC_Ua: the ratio of light-duty vehicle DVMT to population by urbanized area;

* UrbanRcProps_StVtRc: the proportional split of DVMT by vehicle type and road class in each state;

* UzaRcProps_UaVtRc: the proportional split of DVMT by vehicle type and road class in each urbanized area; and,

* ComSvcDvmtFactor: the factor to calculate light-duty commercial service vehicle DVMT from household DVMT.

### How the Datasets are Produced

The datasets listed above are produced in the following steps:

#### Process the Vehicle Type Split for Each Road Class and State

Two arrays are created which identify the proportional split of vehicle miles traveled (VMT) among vehicle types (light-duty, heavy truck, bus) for each road class (Fwy = freeway, Art = arterial, Oth = other) in each state. One array contains data for roadways classified as urban (i.e. located in Census urbanized areas) and the other contains data for roadways classified as rural. The data in these arrays is compiled from data contained in table VM-4 of the Highways Statistics data series. Since table VM-4 is a multi-level table, it has been split into 6 simpler tables where each table contains the data for urban or rural roads of one road class as follows:

* vehicle_type_vmt_split_urban_interstate.csv

* vehicle_type_vmt_split_urban_arterial.csv

* vehicle_type_vmt_split_urban_other.csv

* vehicle_type_vmt_split_rural_interstate.csv

* vehicle_type_vmt_split_rural_arterial.csv

* vehicle_type_vmt_split_rural_other.csv

These files are in and processed to produce two arrays of vehicle type proportions by state and road class -- UrbanVtProps_StVtRc and RuralVtProps_StVtRc -- where the rows are states (including Washington DC and Puerto Rico), the columns are vehicle types, and the tables (the 3rd dimension) are road classes. The abbreviations in the names are as follows:

* Vt = vehicle type

* St = state

* Rc = road class

#### Process VMT Data by Road Class for Each State

Two matrices are created which tabulate annual vehicle miles traveled (VMT) (in millions) for each road class (Fwy = freeway, Art = arterial, Oth = other) in each state. One matrix contains data for roadways classified as urban (i.e. located in Census urbanized areas) and the other contains data for roadways classified as rural. The data in these matrices is compiled from data contained in table VM-2 of the Highways Statistics data series. Since table VM-2 is a multi-level table, it has been split into 2 simpler tables where each table contains the data for urban or rural roads as follows:

* functional_class_vmt_split_rural.csv

* functional_class_vmt_split_urban.csv

These files are read in and processed to produce the two matrices of VMT by state and road class -- UrbanVmt_StRc and RuralVmt_StRc -- where the rows are states (including Washington DC and Puerto Rico) and the columns are are road classes. The abbreviations in the names are as follows:

* St = state

* Rc = road class

#### Process DVMT Data by Urbanized Area and Road Class

A matrix is created which tabulates daily vehicle miles traveled (DVMT) (in thousands) for each road class (Fwy = freeway, Art = arterial, Oth = other) in each urbanized area. The data in this matrix is compiled from data contained in table HM-71 of the Highways Statistics data series. Since table HM-71 is a complex table containing data on multiple sheets, it has been simplified into the file 'urbanized_area_dvmt.csv'. The code reads in and processes this file, and produces the matrix of DVMT by urbanized area and road class -- UzaDvmt_UaRc -- where the rows are urbanized areas and the columns are are road classes. The abbreviations in the names are as follows:

* Ua = urbanized area

* Rc = road class

This matrix also has the following attached attributes:

* State = the primary state where the urbanized area is located

* Population = the population of the urbanized area

* Total = the total DVMT on urbanized area roads

The elements of each of these attributes correspond to the rows in the matrix.

#### Split State VMT and Urbanized Area DVMT by Vehicle Type

State VMT by road class is split into vehicle type components by applying the vehicle type proportions by road class. Urbanized are DVMT is split into vehicle type components by applying the urban vehicle type proportions by road class for the principle state where the urbanized area is located. These data are used to calculate how VMT of each vehicle type is split across roadway classes. It is also used to calculate the ratio of heavy truck VMT to population which is used in the model to calculate base year heavy truck VMT and from that the ratio of heavy truck VMT to income which is used to predict future heavy truck VMT.

#### Calculate Light-Duty Vehicle (LDV) and Heavy Truck DVMT Per Capita

LDV and heavy truck DVMT per capita parameters are used as the basis for calculating roadway DVMT totals that are then allocated to road classes.

The default method for computing LDV roadway DVMT for an urbanized area is to multiply the LDV per capita parameter by the base year urbanized area population. This method is used unless the model user provides an estimate of base year LDV DVMT or is the user provides a total DVMT estimate (in which case the estimated LDV DVMT proportion parameter is appied to the total). The model uses the calculated LDV roadway DVMT and the modeled DVMT for urbanized area households (along with commercial service and transit LDV DVMT) to calculate a
ratio between the roadway LDV DVMT and the overall demand for LDV travel generated by urbanized area households. This ratio is then applied to future calculations of overall LDV DVMT generated by urbanized area households to calculate the LDV DVMT on the urbanized area roads.

Heavy truck DVMT is predicted is a similar manner. Per capita heavy truck DVMT is calculated at the state level and at the urbanized area level. In addition, the urban proportion of state heavy truck DVMT is calculated. If the model is run only for a metropolitan area, the urbanized area per capita value is used to calculate a base year heavy truck DVMT which is used to calculate the ratio
of heavy truck DVMT to total household income. The model user can choose to either grow heavy truck DVMT in the future in proportion to the growth of urbanized area population or in proportion to urbanized area income. If the model is run at the state level, the per capita DVMT parameter for the state is used to calculate base year heavy truck DVMT in the state (unless the user supplies the base year heavy truck DVMT or provides total DVMT, in which heavy truck DVMT is calculated by the estimated heavy truck DVMT proportion
calculated for the state). The model then calculates the ratio of heavy truck DVMT to total state income so that the user can choose to calculate future heavy truck DVMT as a function of population growth or income growth. The state heavy truck DVMT then is used as a control total for heavy truck DVMT in urbanized areas in the state.

#### Calculate the Split of DVMT of Each Vehicle Type Across Road Classes

After roadway DVMT by vehicle type has been calculated, that DVMT is assigned to road classes. For heavy truck and bus DVMT, it is assumed that the distribution of travel across road types reflects logistics and routing considerations rather than congestion. Likewise, it is assumed that the proportion of LDV on roads other than freeways and arterials is determined largely by the need to access properties and is relatively fixed. The proportions of LDV on freeways and arterial is not assumed to be fixed and will reflect relative congestion and costs (i.e. congestion pricing) on those roadways. The AssignLDVTraffic module allocates LDV travel between freeways and arterials. Default distributions are calculated for urban areas for each state. Users may use these distributions instead of urbanized area specific values if desired. The distributions by urbanized area are also calculated.

#### Estimate Factor to Calculate Commercial Service LDV DVMT from Household DVMT

Commercial service (ComSvcDvmt) light-duty vehicle DVMT is calculated as a function of household DVMT for the base year. Once ComSvcDvmt has been calculated for an urbanized are, the model also calculates ratios of ComSvcDvmt to population, income, and household DVMT. The model user can choose whether future ComSvcDvmt growth with household DVMT, urbanized area population, or urbanized area income.

The default ratio of commercial service fleet DVMT to household DVMT is calculated from the following national data:

1) Estimates of average DVMT for commercial fleet light-duty vehicles and for all light-duty vehicles; and

2) Estimates of the numbers of vehicles in fleets having 4 or more vehicles and estimates of all light-duty vehicles


## User Inputs
This module has no user input requirements.

## Datasets Used by the Module
This module uses no datasets that are in the datastore.

## Datasets Produced by the Module
This module produces no datasets to store in the datastore.
