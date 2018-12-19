# VERPAT Scenarios 
VisionEval RPAT Scenario Runs

## Run the Example
  - setwd("sources/models/VERPAT_Scenarios")
  - source("run_model.R")

## Running Multiple Scenarios
  - The scenario_inputs folder contains the multiple scenarios (see below) to build and run
  - The scenarios defined by B * C * D * L * P * T equal 324 scenarios 
  - To test, try just 2 scenarios from B + 1 scenario from each other letter (i.e. 2 total scenarios)
  - Set *NWorkers* in defs/model_parameters.json to the number of concurrent model runs at once
  
## Scenario 1-Letter Codes
  - B - BikesOrLightVehicles (region_light_vehicles.csv)
    - 1 - Base TargetProp and PropSuitable
    - 2 - Double TargetProp and PropSuitable
  - C - Cost (model_parameters.json)
    - 1 - Base, no charge
    - 2 - 5 cents per mile
    - 3 - 9 cents per mile
  - D - DemandManagement (region_commute_options.csv)
    - 1 - Base
    - 2 - Double all participation rates	
    - 3 - Double all participation rates and transit subsidy level
  - L - LandUse (bzone_pop_emp_prop.csv)
    - 1 - Base, growth proportions same as base proportions
    - 2 - Half suburban population and employment growth (-20%, -15%), distribute to urban core R/E (+5%, +3.75%), urban core MU (+10%, +7.5%), and close in communities R/E (+5%, +3.75%)
  - P - ParkingGrowth (marea_parking_growth.csv)
    - 1 - Base, existing costs and proportions paid
    - 2 - Increase parking fees to 20% of workforce and 20% of other
    - 3 - Same as 2 but double parking cost
  - T - TransportationSupply (model_parameters.json)
    - 1 - Base, supply stays at present level
    - 2 - Double transit supply
    - 3 - Triple transit supply
