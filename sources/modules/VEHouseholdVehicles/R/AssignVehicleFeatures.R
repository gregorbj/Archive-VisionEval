#========================
#AssignVehicleFeatures.R
#========================

# This module is a vehicle model from RPAT version.

# This module assigns household vehicle ownership, vehicle types, and ages to
# each household vehicle, based on household, land use,
# and transportation system characteristics. Vehicles are classified as either
# a passenger car (automobile) or a light truck (pickup trucks, sport utility
# vehicles, vans, etc.). A 'Vehicle' table is created which has a record for
# each household vehicle. The type and age of each vehicle owned or leased by
# households is assigned to this table along with the household ID (HhId)to
# enable this table to be joined with the household table.


library(visioneval)


#=============================================
#SECTION 1: ESTIMATE AND SAVE MODEL PARAMETERS
#=============================================

## Current implementation
### The current version implements the models used in the RPAT (GreenSTEP)
### ecosystem.



## Future Development
## Use estimation data set to create models


#Create a list to store models
#-----------------------------
VehOwnModels_ls <-
  list(
    Metro = list(),
    NonMetro = list()
  )

#Model metropolitan households
#--------------------------------

#Model number of vehicles of zero vehicle households
VehOwnModels_ls$Metro$ZeroVeh <- list(
  Drv1 =  "-0.683066027512409 * Intercept + -0.000110405079404259 * Income + 0.000109523364706169 * Htppopdn + -0.0362183493862117 * TranRevMiPC + 1.02639925083899 * Urban + 9.06402787257681e-10 * Income * Htppopdn + 9.50409353343535e-07 * Income * TranRevMiPC + 1.97250624441449e-05 * Income * Urban + 9.62725737852278e-07 * Htppopdn * TranRevMiPC + -5.50575031443288e-05 * Htppopdn * Urban + -0.000119303596393078 * Htppopdn * FwyLaneMiPC + 0.0576992095172837 * TranRevMiPC * FwyLaneMiPC",
  Drv2 = "-1.4293517976947 * Intercept + -6.79093838399447e-05 * Income + 1.41665886075373e-09 * Income * Htppopdn + -3.55383842559826e-05 * Income * OnlyElderly + 1.8466993140076e-06 * Htppopdn * TranRevMiPC",
  Drv3Plus = "-3.49217773065969 * Intercept + -4.90381809989654e-05 * Income + 9.71850941935639e-05 * Htppopdn + 7.30707905255008e-10 * Income * Htppopdn + 0.0755278977577806 * TranRevMiPC * FwyLaneMiPC"
)


#Model number of vehicles of non-zero vehicle households
VehOwnModels_ls$Metro$Lt1Veh <- list(
  Drv1 =  "",
  Drv2 =  "-0.262626375528877 * Intercept + -4.58681084909702e-05 * Income + 5.64785771813055e-05 * Htppopdn + 1.73603587364938 * OnlyElderly + 1.1917191888469e-09 * Income * Htppopdn + 3.34293693717104e-07 * Income * TranRevMiPC + 9.3557681020969e-06 * Income * OnlyElderly + -1.42790321639082e-06 * Htppopdn * TranRevMiPC + -4.75313220359081e-05 * Htppopdn * Urban + -2.71105219349876e-05 * Htppopdn * OnlyElderly + 0.0294466696415345 * TranRevMiPC * Urban + -0.0128985388647686 * OnlyElderly * TranRevMiPC + -1.3804854873109 * OnlyElderly * FwyLaneMiPC",
  Drv3Plus = "0.933669750357049 * Intercept + -1.83215625824184e-05 * Income + 5.20539935712135 * OnlyElderly + 1.66132852613514e-07 * Income * TranRevMiPC + 1.3111834256491e-05 * Income * Urban + -0.000120261225684946 * Income * OnlyElderly + -4.89311638774344e-05 * Urban * Htppopdn + 8.93280811716929e-05 * Htppopdn * FwyLaneMiPC + -0.689141713914993 * Urban * FwyLaneMiPC"
)

VehOwnModels_ls$Metro$Eq1Veh <- list(
  Drv1 =  "0.622159878280685 * Intercept + 0.0232811570547427 * TranRevMiPC + 1.13264996954536e-09 * Income * Htppopdn + -2.76056054149383e-07 * TranRevMiPC * Income + 7.20250709137754e-06 * Income * OnlyElderly + -1.66385909721084e-06 * TranRevMiPC * Htppopdn + -4.53660587597949e-05 * Htppopdn * Urban + 4.08259184719694e-05 * Htppopdn * FwyLaneMiPC + -0.00775538966573374 * TranRevMiPC * OnlyElderly",
  Drv2 =  "0.153082400390944 * Intercept + 5.78895700138807e-06 * Income + 4.02264718027797e-05 * Htppopdn + -0.381431776917538 * Urban + -0.554254682651229 * OnlyElderly + 2.40943544880577e-10 * Income * Htppopdn + 8.177337031634e-06 * Income * Urban + 7.11276258043345e-06 * Income * OnlyElderly + -1.79078088259691e-06 * Htppopdn * TranRevMiPC + -4.94241128932145e-05 * Htppopdn * Urban",
  Drv3Plus = "-1.27880272409382 * Intercept + 7.91127896877896e-06 * Income + -5.76306938765975e-05 * Htppopdn + 5.38360019771969e-10 * Income * Htppopdn + -0.020367512046482 * TranRevMiPC * Urban"
)

VehOwnModels_ls$Metro$Gt1Veh <- list(
  Drv1 =  "-1.74721412860086 * Intercept + 1.60836795971674e-05 * Income + -5.67320500238617e-05 * Htppopdn + -1.02035843794378 * OnlyElderly + -1.18456725053079e-06 * Htppopdn * TranRevMiPC + 4.53069297238042e-05 * Htppopdn * Urban + -0.945719667714273 * Urban * FwyLaneMiPC + 1.10732632310419 * OnlyElderly * FwyLaneMiPC",
  Drv2 =  "-1.96276543220691 * Intercept + 7.56898242720771e-06 * Income + 0.763451405045493 * FwyLaneMiPC + -0.664923337309273 * OnlyElderly + 5.78135381384015e-10 * Income * Htppopdn + -1.26532421138555e-06 * Htppopdn * TranRevMiPC + 2.86474240245699e-05 * Htppopdn * Urban + -0.000155933456154834 * FwyLaneMiPC * Htppopdn + -0.0227377982023876 * TranRevMiPC * Urban",
  Drv3Plus = "-1.00067958301458 * Intercept + -0.000301228344551957 * Htppopdn + -0.0128522840241981 * TranRevMiPC + 2.2049921814377e-09 * Htppopdn * Income"
)


#Model nonmetropolitan households
#--------------------------------
#Model number of vehicles of zero vehicle households
VehOwnModels_ls$NonMetro$ZeroVeh <- list(
  Drv1 =  "-0.764715628588422 * Intercept + -9.48827446956255e-05 * Income + 5.58814902852511e-05 * Htppopdn + 1.55132601403919e-09 * Income * Htppopdn + 3.4451381859651e-05 * Htppopdn * OnlyElderly",
  Drv2 = "-1.97205206585201 * Intercept + -8.50026389808778e-05 * Income + 9.49295735533233e-05 * Htppopdn + -0.750964480544973 * OnlyElderly + 6.90609260578997e-05 * Htppopdn * OnlyElderly",
  Drv3Plus = "-3.18298947122106 * Intercept + -4.99724157628643e-05 * Income + 0.000133417162883283 * Htppopdn"
)


#Model number of vehicles of non-zero vehicle households
VehOwnModels_ls$NonMetro$Lt1Veh <- list(
  Drv1 =  "",
  Drv2 =  "-0.413852820133151 * Intercept + -3.93168014848633e-05 * Income + 4.70561991697599e-05 * Htppopdn + 0.303576772835546 * OnlyElderly + 9.67749108418644e-10 * Income * Htppopdn + 1.53896829737995e-05 * Income * OnlyElderly",
  Drv3Plus = "0.481480595107626 * Intercept + -1.26210114521176e-05 * Income + 9.04571259805652e-05 * Htppopdn + 1.8315332036188 * OnlyElderly"
)

VehOwnModels_ls$NonMetro$Eq1Veh <- list(
  Drv1 =  "0.97339495471904 * Intercept + -9.71792328180977e-06 * Income + -2.84379049251932e-05 * Htppopdn + 0.254612141830117 * OnlyElderly + 1.49373110013838e-09 * Income * Htppopdn + 6.46030086496407e-06 * Income * OnlyElderly + -2.75839770071071e-05 * Htppopdn * OnlyElderly",
  Drv2 =  "0.244148864158161 * Intercept + 2.21438456787939e-06 * Income + -5.87127032906745e-05 * Htppopdn + -0.362435899095522 * OnlyElderly + 1.28716650265866e-09 * Income * Htppopdn + 7.83539837773637e-06 * Income * OnlyElderly + -5.57742722741945e-05 * Htppopdn * OnlyElderly",
  Drv3Plus = "-1.08784722177374 * Intercept + 7.31474110901786e-06 * Income + -5.23190355127079e-05 * Htppopdn"
)

VehOwnModels_ls$NonMetro$Gt1Veh <- list(
  Drv1 =  "-1.50974586088385 * Intercept + 1.97797131824946e-05 * Income + -0.000101101429017305 * Htppopdn + -0.502532799087163 * OnlyElderly + -8.9312428414856e-05 * Htppopdn * OnlyElderly",
  Drv2 =  "-1.2918177391397 * Intercept + 9.12997143307265e-06 * Income + -0.000127456736295507 * Htppopdn + -0.588810459958171 * OnlyElderly + -6.49054938175107e-05 * Htppopdn * OnlyElderly",
  Drv3Plus = "-1.89372144360687 * Intercept + 1.03322804417105e-05 * Income + -0.000128048150374047 * Htppopdn"
)

VehOwnModels_ls$Lt1Prop <- list(Region = c("Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro"),
                                DrvAgePop = c(2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4,
                                              4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6,
                                              6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8,
                                              8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10,
                                              10, 10, 10, 10, 10, 10, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3,
                                              3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5,
                                              5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7,
                                              7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9,
                                              9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10),
                                NumVeh = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2,
                                           3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4,
                                           5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6,
                                           7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8,
                                           9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1,
                                           2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3,
                                           4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5,
                                           6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4, 5, 6, 7,
                                           8, 9),
                                Prob = c(1, 0, 0, 0, 0, 0, 0, 0, 0, 0.183231171, 0.816768829, 0, 0, 0,
                                         0, 0, 0, 0, 0.12420466, 0.268025187, 0.607770154, 0, 0, 0, 0,
                                         0, 0, 0.096819919, 0.201427563, 0.339206509, 0.36254601, 0, 0,
                                         0, 0, 0, 0.092307692, 0.131405437, 0.263930806, 0.390372785,
                                         0.12198328, 0, 0, 0, 0, 0, 0.112268915, 0.156849382, 0.309075249,
                                         0.421806454, 0, 0, 0, 0, 0, 0, 0.117035892, 0.161650327,
                                         0.314736954, 0.406576827, 0, 0, 0, 0, 0, 0, 0.120445326,
                                         0.165084054, 0.318786314, 0.395684306, 0, 0, 0, 0, 0, 0,
                                         0.123004839, 0.167661805, 0.321826229, 0.387507127, 0, 1, 0, 0,
                                         0, 0, 0, 0, 0, 0, 0.16946333, 0.83053667, 0, 0, 0, 0, 0, 0, 0,
                                         0.136026313, 0.256328159, 0.607645528, 0, 0, 0, 0, 0, 0,
                                         0.039726027, 0.233880892, 0.34112275, 0.385270332, 0, 0, 0, 0, 0,
                                         0.04, 0.056, 0.323977401, 0.416610169, 0.163412429, 0, 0, 0, 0,
                                         0, 0.050882254, 0.069963099, 0.400994203, 0.478160444, 0, 0, 0,
                                         0, 0, 0, 0.052920317, 0.071971631, 0.410114516, 0.464993537, 0, 0,
                                         0, 0, 0, 0, 0.054372218, 0.073402494, 0.41661176, 0.455613528, 0,
                                         0, 0, 0, 0, 0, 0.055459041, 0.074473569, 0.421475284, 0.448592106, 0))


VehOwnModels_ls$Gt1Prop <- list(Region = c("Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "Metro", "Metro", "Metro", "Metro",
                                           "Metro", "Metro", "Metro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro", "NonMetro", "NonMetro", "NonMetro",
                                           "NonMetro", "NonMetro"),
                                DrvAgePop = c(1, 1, 1, 1, 1,1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2,
                                              2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
                                              3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
                                              5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6,
                                              6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
                                              7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
                                              9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10,
                                              10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 1, 1, 1, 1, 1, 1,
                                              1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
                                              2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4,
                                              4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,5, 5, 5, 5, 5, 5, 5, 5, 5,
                                              5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,
                                              7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8,
                                              8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
                                              9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
                                              10, 10),
                                NumVeh = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5,
                                           6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                                           11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
                                           15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4,
                                           5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9,
                                           10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
                                           14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3,
                                           4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9,
                                           10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
                                           14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3,
                                           4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8,
                                           9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
                                           13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1,
                                           2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6,
                                           7, 8, 9, 10, 11, 12, 13, 14, 15, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                                           12, 13, 14, 15),
                                Prob = c(0, 0.775279374, 0.162294427, 0.052671587, 0.005884979, 0.003869632, 0,
                                         0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.757435732, 0.171245803, 0.047837229,
                                         0.018166133, 0.005315104, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.739651341,
                                         0.180167454, 0.043018924, 0.030406505, 0.006755776, 0, 0, 0, 0, 0, 0,
                                         0, 0, 0, 0, 0, 0.721925907, 0.18905953, 0.038216592, 0.042606299,
                                         0.008191672, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.704259138, 0.197922177,
                                         0.033430153, 0.054765717, 0.009622816, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                         0.686650742, 0.206755539, 0.02865953, 0.066884958, 0.011049231, 0, 0,
                                         0, 0, 0, 0, 0, 0, 0, 0, 0, 0.669100431, 0.215559764, 0.023904644,
                                         0.078964221, 0.01247094, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                         0.651607918, 0.224334993, 0.019165417, 0.091003704, 0.013887968, 0, 0, 0,
                                         0, 0, 0, 0, 0, 0, 0, 0, 0.634172918, 0.233081371, 0.014441772,
                                         0.103003603, 0.015300337, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.616795147,
                                         0.24179904, 0.009733631, 0.114964113, 0.016708069, 0, 0.730629429,
                                         0.19399416, 0.046990461, 0.018239586, 0.010146364, 0, 0, 0, 0, 0, 0,
                                         0, 0, 0, 0, 0, 0.705375095, 0.197029044, 0.066418387, 0.021235067,
                                         0.009942406, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.679876149, 0.200093323,
                                         0.086034492, 0.024259563, 0.009736473, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                         0.654129018, 0.203187428, 0.105841523, 0.027313496, 0.009528535, 0, 0,
                                         0, 0, 0, 0, 0, 0, 0, 0, 0, 0.628130062, 0.206311795, 0.12584228, 0.0303973,
                                         0.009318563, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.601875569, 0.20946687,
                                         0.14603962, 0.033511413, 0.009106528, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                         0.575361751, 0.21265311, 0.166436456, 0.036656285, 0.008892398, 0, 0,
                                         0, 0, 0, 0, 0, 0, 0, 0, 0, 0.548584749, 0.215870977, 0.187035758,
                                         0.039832374, 0.008676143, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.521540622,
                                         0.219120945, 0.207840555, 0.043040148, 0.00845773, 0, 0, 0, 0, 0, 0, 0,
                                         0, 0, 0, 0, 0.494225356, 0.222403496, 0.228853938, 0.046280082,
                                         0.008237128))

VehOwnModels_ls$VehAgeCumProp <- list(
  VehAge = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
              25, 26, 27, 28, 29, 30, 31, 32),
  AutoCumProp = c(0.00724546108586627, 0.0633739867828944, 0.119650972204074, 0.17611122166644,
                  0.232667582964325, 0.289199954803858, 0.345617046159784, 0.401737816752557,
                  0.457237242995719, 0.511652012961637, 0.564438982852735, 0.615095740239273,
                  0.663196422706258, 0.708413717884405, 0.750527299266295, 0.789346447215604,
                  0.824733327139707, 0.856591128291726, 0.884862169633443, 0.909512678464861,
                  0.930571533414323, 0.948161069415711, 0.962492561634571, 0.973843661565155,
                  0.982540832889983, 0.98894634671769, 0.993442489536914, 0.996413562605098,
                  0.998226715786565, 0.999219121039642, 0.999694273408949, 0.999897830319654,
                  1),
  LtTruckCumProp = c(0, 0.048277482736719, 0.107670020148356, 0.167527807358529, 0.227700646451007,
                     0.287846652232274, 0.347541228736457, 0.406363143639488, 0.463882006009692,
                     0.519622882139033, 0.573035876335912, 0.62356258341566, 0.670766808493439,
                     0.71433657362547, 0.754117353917857, 0.790045820369363, 0.82214023489062,
                     0.850562311494895, 0.875613461230561, 0.897628382073419, 0.916911315076227,
                     0.933705656901347, 0.948213197450025, 0.960581641231327, 0.970894255427227,
                     0.979229359810599, 0.985708983591426, 0.99053128989766, 0.993954610499349,
                     0.996282138540566, 0.997858849151264, 0.99901290898164, 1))

VehOwnModels_ls$VehAgeTypeProp <- list(
  VehAge = c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                       21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7, 8,
                       9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
                       28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                       16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 0, 1,
                       2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
                       23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                       11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
                       30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
                       18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 0, 1, 2, 3, 4,
                       5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
                       25, 26, 27, 28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
                       13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
                        32, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
                       20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7,
                       8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
                       27, 28, 29, 30, 31, 32, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
                       15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 0,
                       1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
                       22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32),
                     IncGrp = c("0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                 "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K", "0to20K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K", "20Kto40K",
                                "20Kto40K", "20Kto40K", "20Kto40K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K", "40Kto60K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K", "60Kto80K",
                                "60Kto80K", "60Kto80K", "60Kto80K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K", "80Kto100K",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus", "100KPlus",
                                "100KPlus", "100KPlus", "100KPlus"),
                     VehType = c("Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck",
                                 "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck", "LtTruck"),
                     Prop = c(0.000689072418377973, 0.00544718672262607, 0.005573820659, 0.00585448452531851,
                              0.00622764779157281, 0.00663688404144811, 0.00707275808142761, 0.00753381782978767,
                              0.00802094057368739, 0.00852243254487315, 0.00899898461766469, 0.00939565546417493,
                              0.00965283760217326, 0.00972982281734327, 0.00961575904600694, 0.00931081773253509,
                              0.00884747097809898, 0.00826948080813357, 0.00761973701780499, 0.00694496549095473,
                              0.0062614006265815, 0.00554210815999331, 0.00473226538269605, 0.00379957776442596,
                              0.00279556279083542, 0.0018549655573974, 0.00111250396673203, 0.000615524709362564,
                              0.000327306801354976, 0.000151632625162581, 8.44419095554236e-05,
                              3.90822402062035e-05, 2.15289324199488e-05, 0.00154477949197307, 0.0119987272716887,
                              0.0120600755118829, 0.0121646829184045, 0.0122733615086917,
                              0.0123779523758167, 0.0125107524604092, 0.0126924853138579,
                              0.0129240178443009, 0.0131728701987043, 0.0133690115413486,
                              0.0134343150707507, 0.0132989312713844, 0.0129288951138399,
                              0.0123322075873495, 0.0115264157581094, 0.0105562553545474,
                              0.00946996011443553, 0.00830690496406319, 0.00710811637147281,
                              0.00591167080366636, 0.00476543997464743, 0.00373282850817056,
                              0.00287377764242896, 0.00221187342627564, 0.00171484583605701,
                              0.00131690805009472, 0.000966385624679437, 0.00063560033659038,
                              0.000313561345913695, 0.000163899715492605, 6.71530330193876e-05,
                              3.1484585411017e-05, 0.0014644798767914, 0.0114933927882837,
                              0.0116778235722275, 0.0120721385160842, 0.0125639651049267,
                              0.0130264242861832, 0.0133703278273087, 0.013498895260568,
                              0.0133439442312416, 0.0128939771165672, 0.0122025703260565,
                              0.0113761102307059, 0.0105146070553252, 0.00968242909110126,
                              0.00890220388122561, 0.00814868505520557, 0.00738623207838935,
                              0.00657879516245823, 0.00570302755733387, 0.00476850085541675,
                              0.00381884743407404, 0.00293037693692254, 0.00218749705203173,
                              0.00163594775781987, 0.00125407757378175, 0.000974727158501654,
                              0.000739376190271886, 0.000529056875051061, 0.000343368611644409,
                              0.000173260045179539, 9.65481203738654e-05, 4.3329730301833e-05,
                              2.2964896572695e-05, 0.00095417537936037, 0.00739518459593728,
                              0.00741659342440686, 0.00744016137343708, 0.00744009365088951,
                              0.00739962695884749, 0.00731008734034471, 0.00715166139179415,
                              0.0069061326803548, 0.00656834630151501, 0.00615413299844917,
                              0.00570133921654266, 0.00524858661736029, 0.0048254379474942,
                              0.00444806762402621, 0.00411079009667912, 0.00379849897082272,
                              0.00348539682537693, 0.0031401395345377, 0.00274094339102433,
                              0.00227996792618167, 0.00177475062033578, 0.0012732143806921,
                              0.000837570514917397, 0.000512673368711242, 0.000303525969365387,
                              0.00018173024434768, 0.000111143512905326, 6.68194523435672e-05,
                              3.30276458640684e-05, 1.85330500377375e-05, 8.46599671831481e-06,
                              4.59293402964135e-06, 0.00106559084677346, 0.00821084871497576,
                              0.00818777052670301, 0.00811076753095241, 0.00798350743039848,
                              0.00782354863335691, 0.00763909953395199, 0.00740956224350541,
                              0.00709949684423723, 0.00667771425731305, 0.00613737118201954,
                              0.00550714773842063, 0.00483255530570131, 0.00416191162287883,
                              0.00353630330958244, 0.00297960594794979, 0.00250487872305621,
                              0.0021152748409312, 0.00180497501618103, 0.00156400598931214,
                              0.00138303727359732, 0.00125318111310512, 0.00116072568039656,
                              0.0010806589390157, 0.000980050017070183, 0.000834526539526742,
                              0.00064711044025921, 0.000447898599864268, 0.000268568591526738,
                              0.00012050860482331, 5.79458874188376e-05, 2.22645280338573e-05,
                              9.78316728219075e-06, 0.00152736007753238, 0.0115831631604587,
                              0.0113608799969323, 0.0108179945806139, 0.0100677681679991,
                              0.00926792052077688, 0.00851405378515784, 0.00783433901695236,
                              0.00720488754575223, 0.00657942635233526, 0.00592489960032226,
                              0.00524219359475168, 0.00455317175975956, 0.00388880834088468,
                              0.00327905154750631, 0.00274284603155715, 0.00229355682243919,
                              0.00193890613349032, 0.00167888556238174, 0.00150532505468082,
                              0.00140001207333737, 0.00133066209866674, 0.00125369100566968,
                              0.00113018389787124, 0.000948730108133019, 0.000732390519008171,
                              0.000520808229420525, 0.000343924963271416, 0.000208741011034989,
                              0.000100417130507469, 5.37837458633503e-05, 2.32614140023132e-05,
                              1.18151840190084e-05, 3.8077810976786e-06, 0.00203680796025813,
                              0.00275317795045612, 0.00326530683967088, 0.00397157513355646,
                              0.00478398402103242, 0.00562578617174339, 0.00642151401310924,
                              0.00710516325352591, 0.0076233342504205, 0.00792887143290408,
                              0.007991853586444, 0.00782057732263926, 0.00744897956546535,
                              0.0069384929144641, 0.00635256579898413, 0.00575528039409075,
                              0.00521584903924697, 0.00478705837160902, 0.00446912054264909,
                              0.00429139585416747, 0.00412091585089795, 0.00386808048288927,
                              0.00345176198581435, 0.00286804842828961, 0.00219838127364229,
                              0.00155999682928675, 0.00104493105814636, 0.000682246486858844,
                              0.000445389414575203, 0.000276111329793337, 0.000219845167876759,
                              0.000195898059926785, 1.67697787762053e-05, 0.00823823412294483,
                              0.010300971664961, 0.0106918924283215, 0.0111558219792024,
                              0.0115993796398055, 0.0119732134422882, 0.0122666538757871,
                              0.0124892234715882, 0.012651495759782, 0.0127416422251206,
                              0.0127279556232876, 0.0125780562745348, 0.0122472574709892,
                              0.0117097691886179, 0.0109505135974579, 0.00998951428102941,
                              0.00890070291738937, 0.00777378297439372, 0.00665135320789356,
                              0.00564931737119188, 0.00472017955740638, 0.0039339230683199,
                              0.00330374055047746, 0.00279213830951485, 0.00234623900606025,
                              0.00192976642506856, 0.00153410845928905, 0.00117132184677085,
                              0.000850318166057567, 0.000552417062083501, 0.00044328212045939,
                              0.00039111186736149, 2.00923576308709e-05, 0.0098793171804847,
                              0.012367942720638, 0.0128660038266763, 0.0134475512060206,
                              0.0139580538500004, 0.0142745175130101, 0.0143146686464285,
                              0.014040433755922, 0.0134595627047652, 0.0126190358957302,
                              0.0116122156983839, 0.0105648025041402, 0.00957377039163472,
                              0.00869732826120665, 0.00793350361283225, 0.00724850032695823,
                              0.00661719861511309, 0.00601869089817581, 0.00540510112388933,
                              0.00481253409630462, 0.00415849490479005, 0.00348840357011957,
                              0.00284905541470924, 0.00227298328162639, 0.00177168511507378,
                              0.00134362941882846, 0.000985207340511637, 0.000694914991234696,
                              0.000468501147337864, 0.000286178704138945, 0.000219746731405481,
                              0.000184460511741507, 1.70607010745472e-05, 0.00819276784203495,
                              0.0100092174833612, 0.00992300727401238, 0.00970331686957488,
                              0.00932415307409835, 0.00879752021805181, 0.00817767595846068,
                              0.00753052599411138, 0.00691171973868216, 0.00635526816232545,
                              0.00587614779655191, 0.00547138548757523, 0.00511134981115888,
                              0.00475963196140319, 0.00437824652465188, 0.00394591271909734,
                              0.00347026255541421, 0.00297644154048512, 0.00248220808641527,
                              0.00204001550926865, 0.00164981842675658, 0.00135437090720464,
                              0.00115915903465269, 0.00103093837428987, 0.000922092365862811,
                              0.000797487988842931, 0.000648350066112093, 0.000489900167404267,
                              0.000342619762315172, 0.00021193520192232, 0.000162668441960372,
                              0.000135540920990262, 1.87950455592698e-05, 0.00889839576809104,
                              0.0107488052903663, 0.0104780582428893, 0.0100997389261222,
                              0.00967880908873081, 0.00926822738690466, 0.00889538263699053,
                              0.00853971499137703, 0.00814418924063882, 0.00764177299963316,
                              0.00699402527205009, 0.00621411386607842, 0.0053481190553384,
                              0.00446701784460852, 0.00363654594591005, 0.00290762509356047,
                              0.00231000634693226, 0.00185784759491956, 0.00154003031112137,
                              0.00134626194282073, 0.00121686199927685, 0.00111025914397686,
                              0.000985817218466332, 0.00082703868799364, 0.000645472882576886,
                              0.000466270144004584, 0.000312104302077052, 0.000194295685170027,
                              0.000113223263092296, 5.97935561392987e-05, 4.06772446348605e-05,
                              2.90490243861773e-05, 2.34641811423485e-05, 0.0110270613114104,
                              0.0132064006401036, 0.0126274587818172, 0.0117887554163134,
                              0.0107955628445567, 0.00974930775957254, 0.00874011644299915,
                              0.00780803995343969, 0.00694500185418791, 0.00612107278163661,
                              0.00531947460531039, 0.00455059332896231, 0.00383596022414174,
                              0.00320459290626052, 0.00267352984678448, 0.00224440348938561,
                              0.00190524483247748, 0.00163485157304456, 0.00139921904320423,
                              0.00118571410990477, 0.00096505007551202, 0.000759393123547956,
                              0.000598551063862228, 0.000495391155333501, 0.000434264139223431,
                              0.000383577627813608, 0.000319583192778069, 0.000241241114014662,
                              0.000162668586814352, 9.44685371321714e-05, 6.77263612231927e-05,
                              5.09334702999125e-05))

VehOwnModels_ls$VehicleMpgProp <- list(
  Veh1Value = c(0.05, 0.1, 0.15, 0.2,
                0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75,
                0.8, 0.85, 0.9, 0.95, 1),
  Veh2Value = c(0.05,
                0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65,
                0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1),
  Veh3Value = c(0.05,
                0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65,
                0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1),
  Veh4Value = c(0.05,
                0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65,
                0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1),
  Veh5PlusValue = c(0.05,
                    0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65,
                    0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1),
  Veh1Prob = c(0L,
               0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L, 0L,
               0L, 0L, 1L),
  Veh2Prob = c(0.019114158,
               0.022607435, 0.027814395, 0.034339573, 0.046401265, 0.054574216,
               0.06380174, 0.071381492, 0.081531769, 0.078763511, 0.078104403,
               0.08159768, 0.071315581, 0.06380174, 0.054640127, 0.046401265,
               0.034273662, 0.027814395, 0.022673346, 0.019048247),
  Veh3Prob = c(0.053135889, 0.05937863, 0.069541231,
               0.088704994, 0.095092915, 0.100464576, 0.097996516, 0.094802555,
               0.079268293, 0.065476189, 0.058217189, 0.042682927, 0.031504065,
               0.022357724, 0.016114983, 0.011469222, 0.006097561, 0.004500581,
               0.00261324, 0.00058072),
  Veh4Prob = c(0.073743922,
               0.102917342, 0.111426256, 0.129659643, 0.142625608, 0.112641815,
               0.090356564, 0.070502431, 0.055510535, 0.036871963, 0.029578606,
               0.016207455, 0.010534846, 0.007698541, 0.002025932, 0.006077796,
               0.000810373, 0, 0.000405186, 0.000405186),
  Veh5PlusProb = c(0.131578947, 0.148421053, 0.187368421,
                   0.124210526, 0.128421053, 0.098947368, 0.074736842, 0.037894737,
                   0.022105263, 0.021052631, 0.010526316, 0.002105263, 0.008421053,
                   0.001052632, 0.003157895, 0, 0, 0, 0, 0))



#Save the vehicle ownership model
#-----------------------------
#' Vehicle ownership model
#'
#' A list containing the vehicle ownership model equation and other information
#' needed to implement the vehicle ownership model.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{Metro}{a list containing four models for metropolitan areas: a Zero
#'   component model and three separate models for non-zero component}
#'   \item{NonMetro}{a list containing four models for non-metropolitan areas: a
#'   Zero component model and three separate models for non-zero component}
#' }
#' @source AssignVehicleFeatures.R script.
"VehOwnModels_ls"
devtools::use_data(VehOwnModels_ls, overwrite = TRUE)

# Model LtTrk Ownership
#-------------------------

# LtTrk ownership model
LtTruckModels_ls <- list(OwnModel = "-0.786596031795022 * Intercept + 5.0096283625617e-06 * Income + -0.151743860056697 * LogDen + -0.19343908057384 * Urban + 0.600876902111923 * Hhvehcnt + 0.287299051164498 * HhSize + 1.74355011513854e-06 * Income * HhSize + -3.79266132566609e-06 * Income * Hhvehcnt + -0.0862684834097631 * Hhvehcnt * HhSize")

#Save the light truck ownership model
#-----------------------------
#' Light truck ownership model
#'
#' A list containing the light truck ownership model equation.
#'
#' @format A list having the following components:
#' \describe{
#'   \item{OwnModel}{The light truck ownership model}
#' }
#' @source AssignVehicleFeatures.R script.
"LtTruckModels_ls"
devtools::use_data(LtTruckModels_ls, overwrite = TRUE)


#================================================
#SECTION 2: DEFINE THE MODULE DATA SPECIFICATIONS
#================================================

#Define the data specifications
#------------------------------
AssignVehicleFeaturesSpecifications <- list(
  #Level of geography module is applied at
  RunBy = "Region",
  #Specify new tables to be created by Inp if any
  #---------------------------
  NewInpTable = items(
    item(
      TABLE = "Vehicles",
      GROUP = "Global"
    )
  ),
  NewSetTable = items(
    item(
      TABLE = "Vehicle",
      GROUP = "Year"
    )
  ),
  #---------------------------
  #Specify new tables to be created by Inp if any
  Inp = items(
    item(
      NAME = items(
        "AutoMpg",
        "LtTruckMpg",
        "TruckMpg",
        "BusMpg",
        "TrainMpg"
      ),
      FILE = "model_veh_mpg_by_year.csv",
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = items(
        "Miles per gallon for automobiles",
        "Miles per gallon for light trucks",
        "Miles per gallon for trucks",
        "Miles per gallon for buses",
        "Miles per gallon for trains")
    ),
    item(
      NAME = "ModelYear",
      FILE = "model_veh_mpg_by_year.csv",
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Years for which the efficiency of vehicle are measured."
    )
  ),
  #---------------------------
  #Specify new tables to be created by Set if any
  #Specify input data
  #Specify data to be loaded from data store
  Get = items(
    # Marea variables
    item(
      NAME = "Marea",
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = items(
        "TranRevMiPC",
        "FwyLaneMiPC"),
      TABLE = "Marea",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    # Bzone variables
    item(
      NAME = "Marea",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Bzone",
      TABLE = "Bzone",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    # Household variables
    item(
      NAME =
        items("HhId",
              "Azone",
              "Marea"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      PROHIBIT = "",
      ISELEMENTOF = ""
    ),
    item(
      NAME = "Income",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "currency",
      UNITS = "USD.2001",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhType",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBIT = "",
      ISELEMENTOF = c("SF", "MF", "GQ")
    ),
    item(
      NAME = "HhSize",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "<= 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME =
        items(
          "Age0to14",
          "Age65Plus"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "people",
      UNITS = "PRSN",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "HhPlaceTypes",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBITED = "NA"
    ),
    item(
      NAME = "DrvLevels",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      PROHIBITED = "NA",
      ISELEMENTOF = c("Drv1", "Drv2", "Drv3Plus")
    ),
    # Global variables
    item(
      NAME = items(
        "AutoMpg",
        "LtTruckMpg",
        "TruckMpg",
        "BusMpg",
        "TrainMpg"
      ),
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "ModelYear",
      TABLE = "Vehicles",
      GROUP = "Global",
      TYPE = "time",
      UNITS = "YR",
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = ""
    ),
    item(
      NAME = "LtTruckProp",
      TABLE = "Model",
      GROUP = "Global",
      TYPE = "double",
      UNITS = "multiplier",
      PROHIBIT = c('NA', '< 0'),
      ISELEMENTOF = ""
    )
  ),
  #---------------------------
  #Specify data to saved in the data store
  Set = items(
    # Vehicle variables
    item(
      NAME =
        items("HhId",
              "VehId",
              "Azone",
              "Marea"),
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "ID",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = "",
      DESCRIPTION =
        items("Unique household ID",
              "Unique vehicle ID",
              "Azone ID",
              "Marea ID")
    ),
    item(
      NAME = "Type",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "character",
      UNITS = "category",
      NAVALUE = -1,
      PROHIBIT = "NA",
      ISELEMENTOF = c("Auto", "LtTrk"),
      SIZE = 5,
      DESCRIPTION = "Vehicle body type: Auto = automobile, LtTrk = light trucks (i.e. pickup, SUV, Van)"
    ),
    item(
      NAME = "Age",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "time",
      UNITS = "YR",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Vehicle age in years"
    ),
    item(
      NAME = "Mileage",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "compound",
      UNITS = "MI/GAL",
      PROHIBIT = c("NA", "<0"),
      ISELEMENTOF = "",
      DESCRIPTION = "Mileage of vehicles (automobiles and light truck)"
    ),
    item(
      NAME = "DvmtProp",
      TABLE = "Vehicle",
      GROUP = "Year",
      TYPE = "double",
      UNITS = "proportion",
      PROHIBIT = c("NA", "<0", "> 1"),
      ISELEMENTOF = "",
      DESCRIPTION = "Proportion of average household DVMT"
    ),
    # Household variables
    item(
      NAME = "Vehicles",
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = "Number of automobiles and light trucks owned or leased by the household"
    ),
    item(
      NAME = items(
        "NumLtTrk",
        "NumAuto"),
      TABLE = "Household",
      GROUP = "Year",
      TYPE = "vehicles",
      UNITS = "VEH",
      NAVALUE = -1,
      PROHIBIT = c("NA", "< 0"),
      ISELEMENTOF = "",
      SIZE = 0,
      DESCRIPTION = items(
        "Number of light trucks (pickup, sport-utility vehicle, and van) owned or leased by household",
        "Number of automobiles (i.e. 4-tire passenger vehicles that are not light trucks) owned or leased by household"
      )
    )
  )
)

#Save the data specifications list
#---------------------------------
#' Specifications list for AssignVehicleFeatures module
#'
#' A list containing specifications for the AssignVehicleFeatures module.
#'
#' @format A list containing 3 components:
#' \describe{
#'  \item{RunBy}{the level of geography that the module is run at}
#'  \item{Get}{module inputs to be read from the datastore}
#'  \item{Set}{module outputs to be written to the datastore}
#' }
#' @source AssignVehicleFeatures.R script.
"AssignVehicleFeaturesSpecifications"
devtools::use_data(AssignVehicleFeaturesSpecifications, overwrite = TRUE)


#=======================================================
#SECTION 3: DEFINE FUNCTIONS THAT IMPLEMENT THE SUBMODEL
#=======================================================

# Function to predict vehicle ownership by region type to match
# the target proportion.
#--------------------------------------------------------
#' Predict vehicle ownership to match the target proportion for a specific
#' region type.
#'
#' \code{predictVehicleOwnership} Predict vehicle ownership to match the
#' target proportion for a specific region type.
#'
#' This function predicts the number of vehicles and the ratio of number of vehicles
#' to the driving age population (ownership ratio).
#'
#' @param Hh_df A household data frame consisting of household attributes.
#' @param ModelType A list of vehicle ownership models.
#' @param  VehProp A list of data frame consisting of distribution of number
#' of vehicles by driving age population for each region type.
#' @param Type A string indicating the region type ("Metro": Default, or "NonMetro")
#' @return A list containing number of vehicles and ownership ratio for each household
#' @export
#'
predictVehicleOwnership <- function( Hh_df, ModelType=VehOwnModels_ls, VehProp = NA, Type="Metro" ) {
  # Define vehicle categories
  VehicleCategory <- c( "Zero", "Lt1", "Eq1", "Gt1" )
  # Define driver levels
  DriverLevels <- c( "Drv1", "Drv2", "Drv3Plus" )
  # Check if proper type specified
  if( !( Type %in% c( "Metro", "NonMetro" ) ) ) {
    stop( "Type must be either 'Metro' or 'NonMetro'" )
  }
  # Extract model components for specified type
  ZeroVehModel <- ModelType[[Type]]$ZeroVeh
  Lt1VehModel <- ModelType[[Type]]$Lt1Veh
  Eq1VehModel <- ModelType[[Type]]$Eq1Veh
  Gt1VehModel <- ModelType[[Type]]$Gt1Veh
  VehProp_ <- VehProp[[Type]]
  # Define an intercept value
  Intercept <- 1
  # Apply the zero vehicle ownership model
  ZeroVehResults_ <- numeric( nrow( Hh_df ) )
  for( dl in DriverLevels ) {
    ZeroVehResults_[ Hh_df$DrvLevel == dl ] <-
      eval( parse( text=ZeroVehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
  }
  ZeroVehOdds_ <- exp( ZeroVehResults_ )
  ZeroVehProbs_ <- ZeroVehOdds_ / (1 + ZeroVehOdds_)
  # Apply the less than one vehicle ownership model
  # Note if DrvLevel == Drv1, then Lt1 can't be true
  Lt1VehResults_ <- numeric( nrow( Hh_df ) )
  Lt1VehResults_[ Hh_df$DrvLevel == "Drv1" ] <- NA
  for( dl in DriverLevels ) {
    if(Lt1VehModel[[dl]]!=""){
      Lt1VehResults_[ Hh_df$DrvLevel == dl ] <-
        eval( parse( text=Lt1VehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
    }
  }
  Lt1VehOdds_ <- exp( Lt1VehResults_ )
  Lt1VehProbs_ <- Lt1VehOdds_ / (1 + Lt1VehOdds_)
  Lt1VehProbs_[ Hh_df$DrvLevel == "Drv1" ] <- 0
  # Apply the equal to one vehicle ownership model
  Eq1VehResults_ <- numeric( nrow( Hh_df ) )
  for( dl in DriverLevels ) {
    Eq1VehResults_[ Hh_df$DrvLevel == dl ] <-
      eval( parse( text=Eq1VehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
  }
  Eq1VehOdds_ <- exp( Eq1VehResults_ )
  Eq1VehProbs_ <- Eq1VehOdds_ / (1 + Eq1VehOdds_)
  # Apply the greater than one vehicle ownership model
  Gt1VehResults_ <- numeric( nrow( Hh_df ) )
  for( dl in DriverLevels ) {
    Gt1VehResults_[ Hh_df$DrvLevel == dl ] <-
      eval( parse( text=Gt1VehModel[[dl]] ), envir=Hh_df[ Hh_df$DrvLevel == dl, ] )
  }
  Gt1VehOdds_ <- exp( Gt1VehResults_ )
  Gt1VehProbs_ <- Gt1VehOdds_ / (1 + Gt1VehOdds_)
  # Combine probability vectors into one matrix
  VehProbs2d <- cbind( ZeroVehProbs_, Lt1VehProbs_, Eq1VehProbs_, Gt1VehProbs_ )
  # Calculate a vehicle choice
  Hh_df$VehChoice <- VehicleCategory[ apply( VehProbs2d, 1, function(x) {
    sample( 1:4, 1, replace=FALSE, prob=x )
  } ) ]
  # Calculate number of vehicles
  NumVeh_ <- numeric( nrow( Hh_df ) )

  NumVeh_[Hh_df$VehChoice == "Zero"] <- 0
  NumVeh_[Hh_df$VehChoice == "Eq1"] <- Hh_df$DrvAgePop[Hh_df$VehChoice == "Eq1"]

  ## Calculate number of vehicles ofr Lt1
  VehChoice <- "Lt1"
  VehProbsNdNv <- VehProp_[[VehChoice]]

  ### Calculate if the driver age population is found in the table
  CheckCondition1 <- Hh_df$VehChoice == "Lt1"
  CheckCondition2 <- (Hh_df$VehChoice == "Lt1") & (as.character(Hh_df$DrvAgePop) %in% as.character(VehProbsNdNv$Lt1DrvAgePop))

  # Modify the sampling function
  customSample <- function(x, ...){
    if(length(x) < 2){
      return(x)
    } else {
      return(sample(x,...))
    }
  }


  if(any(CheckCondition1)){
    NumVeh_[CheckCondition1] <- round(Hh_df$DrvAgePop[CheckCondition1]/2)
  }
  if(any(CheckCondition2)){
    NumVeh_[CheckCondition2] <- sapply(Hh_df$DrvAgePop[CheckCondition2], function(x) customSample(VehProbsNdNv$Lt1NumVeh[VehProbsNdNv$Lt1DrvAgePop == x], 1, prob = VehProbsNdNv$Lt1Prob[VehProbsNdNv$Lt1DrvAgePop==x]))
  }

  ## Calculate number of vehicles ofr Gt1
  VehChoice <- "Gt1"
  VehProbsNdNv <- VehProp_[[VehChoice]]

  ### Calculate if the driver age population is found in the table
  CheckCondition1 <- Hh_df$VehChoice == "Gt1"
  CheckCondition2 <- (Hh_df$VehChoice == "Gt1") & (as.character(Hh_df$DrvAgePop) %in% as.character(VehProbsNdNv$Gt1DrvAgePop))


  if(any(CheckCondition1)){
    NumVeh_[CheckCondition1] <- round(Hh_df$DrvAgePop[CheckCondition1]/2)
  }
  if(any(CheckCondition2)){
    NumVeh_[CheckCondition2] <- sapply(Hh_df$DrvAgePop[CheckCondition2], function(x) customSample(VehProbsNdNv$Gt1NumVeh[VehProbsNdNv$Gt1DrvAgePop == x], 1, prob = VehProbsNdNv$Gt1Prob[VehProbsNdNv$Gt1DrvAgePop==x]))
  }

  # Calculate vehicle ownership ratio
  VehRatio_ <- NumVeh_ / Hh_df$DrvAgePop
  # Return results in a list
  list( VehRatio = as.numeric(VehRatio_), NumVeh = as.integer(NumVeh_) )
}

# Function to predict vehicle type (auto or light truck) for household vehicles
#-----------------------------------------------------------------------------
#' Predict vehicle type (automobile or light truck) for household vehicles.
#'
#' \code{predictVehicleOwnership} Predict vehicle type (automobile or light truck)
#' for household vehicles.
#'
#' This function predict vehicle type (automobile or light truck)
#' for household vehicles based on characterisitics of the household, the place where
#' the household resides, the number of vehicles it owns, and areawide targets for
#' light truck ownership.
#'
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param ModelType A list of light truck ownership model.
#' @param  TruckProp A numeric indicating the target proportion for light truck
#' ownership.
#' @return A list containing vehicle types for each household.
#' @export
#'
predictLtTruckOwn <- function( Hh_df, ModelType=LtTruckModels_ls, TruckProp=NA) {

  # Setup values
  OwnModel <- ModelType$OwnModel
  Hh_df$LogDen <- log( Hh_df$Htppopdn )
  TargetTruckProp <- TruckProp
  LtTruckFactorLo <- -100
  LtTruckFactorMd <- 0
  LtTruckFactorHi <- 100
  Itr <- 0
  Intercept <- 1

  # Function to test convergence
  notConverged <- function( TruckProp, EstTruckProp ) {
    Diff <- abs( TruckProp - EstTruckProp )
    return(Diff > 0.0001)
  }

  # Function to calculate probabilities
  calcVehProbs <- function( Factor ) {
    LtTruckResults_ <- Factor + eval( parse( text=OwnModel ), envir=Hh_df )
    LtTruckOdds_ <- exp( LtTruckResults_ )
    return(LtTruckOdds_ / (1 + LtTruckOdds_))
  }

  # Calculate starting proportion
  LtTruckProbsMd_ <- calcVehProbs( LtTruckFactorMd )
  EstTruckProp <- sum( Hh_df$Hhvehcnt * LtTruckProbsMd_ ) / sum( Hh_df$Hhvehcnt )
  # Continue is there is a target truck proportion to be achieved
  if( !is.na( TruckProp ) ){
    while( notConverged( TruckProp, EstTruckProp ) ) {
      LtTruckProbsLo_ <- calcVehProbs( LtTruckFactorLo )
      LtTruckProbsMd_ <- calcVehProbs( LtTruckFactorMd )
      LtTruckProbsHi_ <- calcVehProbs( LtTruckFactorHi )
      EstTruckPropLo <- sum( Hh_df$Hhvehcnt * LtTruckProbsLo_ ) /
        sum( Hh_df$Hhvehcnt )
      EstTruckPropMd <- sum( Hh_df$Hhvehcnt * LtTruckProbsMd_ ) /
        sum( Hh_df$Hhvehcnt )
      EstTruckPropHi <- sum( Hh_df$Hhvehcnt * LtTruckProbsHi_ ) /
        sum( Hh_df$Hhvehcnt )
      if( TruckProp < EstTruckPropMd ) {
        LtTruckFactorHi <- LtTruckFactorMd
        LtTruckFactorMd <- mean( c( LtTruckFactorHi, LtTruckFactorLo ) )
      }
      if( TruckProp > EstTruckPropMd ) {
        LtTruckFactorLo <- LtTruckFactorMd
        LtTruckFactorMd <- mean( c( LtTruckFactorLo, LtTruckFactorHi ) )
      }
      EstTruckProp <- EstTruckPropMd
      rm( EstTruckPropLo, EstTruckPropMd, EstTruckPropHi )
      if( Itr > 100 ) break
      Itr <- Itr + 1
    }
  }

  # Assign vehicles by type to each household
  VehType_ <- apply( cbind( Hh_df$Hhvehcnt, LtTruckProbsMd_ ), 1, function(x) {
    NumVeh <- x[1]
    Prob <- x[2]
    sample( c( "LtTruck", "Auto" ), NumVeh, replace=TRUE,
            prob=c( Prob, 1-Prob ) )
  } )
  # Return the result
  return(VehType_)
}

#Function which calculates vehicle type distributions by income group
#-------------------------------------------------------------------
#' Calculate vehicle type distributions by income group.
#'
#' \code{calcVehPropByIncome} Calculates vehicle type distributions by
#' household income group.
#'
#' This function calculates vehicle type distributions by household
#' income group. It takes the the number of vehicles, vehicle types, and
#' income groups of each household and calculates the marginal distribution
#' of the vehicle types.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @return A data frame containing the distribution of vehicle types by income
#' groups.
#' @import reshape2
#' @export
#'
calcVehPropByIncome <- function( Hh_df ) {
  VehTabByIg <- table( rep( Hh_df$IncGrp, Hh_df$Hhvehcnt ), unlist( Hh_df$VehType ) )
  VehIgPropByIg <- sweep( VehTabByIg, 2, colSums( VehTabByIg ), "/" )
  VehIgPropByIg <- as.data.frame(VehIgPropByIg)
  VehIgPropByIg <- reshape2::dcast(VehIgPropByIg, Var1~Var2, value.var = "Freq", fill = 0)
  colnames(VehIgPropByIg)[1] <- "IncGrp"
  return(VehIgPropByIg)
}

#Function to adjust cumulative age distribution to match target ratio
#-------------------------------------------------------------------
#' Adjust cumulative age distribution to match target ratio
#'
#' \code{adjAgeDistribution} Adjusts a cumulative age distribution to match a
#' target ratio.
#'
#' This function adjusts a cumulative age distribution to match a target ratio.
#' The function returns the adjusted cumulative age distribution and the
#' corresponding age distribution.
#'
#' @param CumDist A named numeric vector where the names are vehicle ages and
#' the values are the proportion of vehicles that age or younger. The names must
#' be an ordered sequence from 0 to 32.
#' @param AdjRatio A number that is the target ratio value.
#' @return A numeric vector of adjusted distribution.
#' @import stats
#' @export
#'
adjAgeDistribution <- function( CumDist, AdjRatio ) {
  # Calculate the length of the original distribution
  DistLength <- length( CumDist )
  # If 95th percentile age increases, add more ages on the right side of the distribution
  # to enable the distribution to be expanded in that direction
  if( AdjRatio > 1 ) CumDist <- c( CumDist, rep(1,8) )
  # Calculate vehicle ages for the distribution
  Ages_ <- 0:( length( CumDist ) - 1 )
  MaxAge <- Ages_[ length( Ages_ ) ]
  # Find decimal year which is equal to 95th percentile
  LowerIndex <- max( which( CumDist < 0.95 ) )
  UpperIndex <- LowerIndex + 1
  LowerValue <- CumDist[ LowerIndex ]
  UpperValue <- CumDist[ UpperIndex ]
  YearFraction <- ( 0.95 - LowerValue ) / ( UpperValue - LowerValue )
  Year95 <- Ages_[ LowerIndex ] + YearFraction
  # Calculate the adjustment in years
  Target95 <- Year95 * AdjRatio
  LowerShiftRatio <- Target95 / Year95
  UpperShiftRatio <- ( MaxAge - Target95 ) / ( MaxAge - Year95 )
  LowerAdjAges_ <- Ages_[ 0:LowerIndex ] * LowerShiftRatio
  UpperAgeSeq_ <- ( Ages_[ UpperIndex ]:MaxAge )
  UpperAdjAges_ <- MaxAge - rev( UpperAgeSeq_ - UpperAgeSeq_[1] ) * UpperShiftRatio
  AdjAges_ <- c( LowerAdjAges_, UpperAdjAges_ )
  # Calculate new cumulative proportions
  AdjCumDist <- CumDist
  for( i in 2:( length( AdjCumDist ) - 1 ) ) {
    LowerIndex <- max( which( AdjAges_ < Ages_[i] ) )
    UpperIndex <- LowerIndex + 1
    AdjProp <- ( Ages_[i] - AdjAges_[ LowerIndex ] ) /
      ( AdjAges_[ UpperIndex ] - AdjAges_[ LowerIndex ] )
    LowerValue <- CumDist[ LowerIndex ]
    UpperValue <- CumDist[ UpperIndex ]
    AdjCumDist[i] <- LowerValue + AdjProp * ( UpperValue - LowerValue )
  }
  # Smooth out the cumulative distribution
  LowIdx <- 1
  HiIdx <- length( AdjCumDist )
  SmoothTransition_ <- smooth.spline( LowIdx:HiIdx, AdjCumDist[LowIdx:HiIdx], df=4 )$y
  AdjCumDist[ LowIdx:HiIdx ] <- SmoothTransition_
  # Convert cumulative distribution to regular distribution
  AdjDist_ <- AdjCumDist
  for( i in length( AdjDist_ ):2 ) {
    AdjDist_[i] <- AdjDist_[i] - AdjDist_[i-1]
  }
  # Truncate to original distribution length
  AdjDist_ <- AdjDist_[ 1:DistLength ]
  # Adjust so that sum of distribution exactly equals 1
  AdjDist_ <- AdjDist_ * ( 1 / sum( AdjDist_ ) )
  # Return result
  return(AdjDist_)
}

#Function which calculates vehicle age distributions by income group
#-------------------------------------------------------------------
#' Calculate vehicle age distributions by income group.
#'
#' \code{calcVehAgePropByInc} Calculates vehicle age distributions by
#' household income group.
#'
#' This function calculates vehicle age distributions by household income group.
#' It takes marginal distributions of vehicles by age and households by income
#' group along with a data frame of the joint probability distribution of
#' vehicles by age and income group, and then uses iterative proportional
#' fitting to adjust the joint probabilities to match the margins. The
#' probabilities by income group are calculated from the fitted joint
#' probability matrix. The age margin is the proportional distribution of
#' vehicles by age calculated by adjusting the cumulative age distribution
#' for autos or light trucks to match a target mean age. The income
#' margin is the proportional distribution of vehicles by household income group
#' ($0-20K, $20K-40K, $40K-60K, $60K-80K, $80K-100K, $100K or more) calculated
#' from the modeled household values.
#'
#' @param VehAgIgProp A numeric vector of joint probabilities of vehicle by
#' age and income group.
#' @param AgeGrp A numeric vector indicating the vehicle ages.
#' @param  AgeMargin A named numeric vector indicating the marginal distribution
#' of vehicle by age.
#' @param IncGrp A character vector indicating the income groups.
#' @param IncMargin A named numeric vecotr indicating the marginal distribution
#' of vehicle by income groups.
#' @param MaxIter A numeric indicating maximum number of iterations. (Default: 100)
#' @param Closure A numeric indicating the tolerance level for conversion. (Default: 1e-3)
#' @return A numeric vector of joint probabilities of vehicle by age and income group.
#' @export
#'
calcVehAgePropByInc <- function(VehAgIgProp, AgeGrp, AgeMargin, IncGrp, IncMargin, MaxIter=100, Closure=0.001){
  # Replace margin values of zero with 0.001
  if( any( AgeMargin ==0 ) ){
    AgeMargin[ AgeMargin ==0 ] <- 0.0001
  }
  if( any( IncMargin ==0 ) ){
    IncMargin[ IncMargin ==0 ] <- 0.0001
  }
  # Make sure sum of each margin is equal to 1
  AgeMargin <- AgeMargin * ( 1 / sum( AgeMargin ) )
  IncMargin <- IncMargin * ( 1 / sum( IncMargin ) )
  # Set initial values
  Iter <- 0
  MarginChecks <- c( 1, 1 )
  # Iteratively proportion matrix until closure or iteration criteria are met
  while( ( any( MarginChecks > Closure ) ) & ( Iter < MaxIter ) ) {
    AgeSums <- rowsum( VehAgIgProp, group = AgeGrp )[,1]
    AgeCoeff <- AgeMargin / AgeSums
    VehAgIgProp <- AgeCoeff[as.character(AgeGrp)]*VehAgIgProp
    MarginChecks[1] <- sum(abs( 1 - AgeCoeff ))
    IncSums <- rowsum( VehAgIgProp, group = IncGrp )[,1]
    IncCoeff <- IncMargin / IncSums
    VehAgIgProp <- IncCoeff[as.character(IncGrp)]*VehAgIgProp
    MarginChecks[2] <- sum(abs( 1 - IncCoeff ))
    Iter <- Iter + 1
  }
  # Compute proportions for each income group
  IncSums <- rowsum(VehAgIgProp, group = IncGrp)[,1]
  VehAgIgProp <- VehAgIgProp/IncSums[as.character(IncGrp)]
  return(VehAgIgProp)
}

# Function to calculate vehicle type and age for each household
#--------------------------------------------------------
#' Calculate vehicle type and age for each household.
#'
#' \code{calcVehicleAges} Calculates vehicle type and age for each household.
#'
#' This function calculates the vehicle type and age for households. The function
#' uses characteristics of houshold and target marginal proportions to calculate
#' vehicle type and age.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param VProp A list consisting of a cumulative distribution of vehicle age by
#' vehicle type and a joint distribution of vehicle age, type and income group of
#' the household.
#' @param AdjRatio A number that is the target ratio value.
#' @return A list containing the vehicle types and ages for each household.
#' @import reshape2
#' @export
#'
calcVehicleAges <- function(Hh_df, VProp=NULL, AdjRatio = c(Auto = 1, LtTruck = 1)){

  # Compute the vehicle age distribution by income and type
  #--------------------------------------------------------
  # Calculate the distribution of vehicle types by income
  VehPropByInc <- calcVehPropByIncome( Hh_df )
  # Compute the age margin
  AgeType <- colnames( VProp$VehCumPropByAge[,-1] )
  VehPropByAge <- VProp$VehCumPropByAge
  # Adjust the age distribution
  AdjVehProp <- lapply(AgeType, function(x) adjAgeDistribution(VehPropByAge[, x],
                                                                  AdjRatio = AdjRatio[x]))
  names(AdjVehProp) <- AgeType
  VehPropByAge[,AgeType] <- data.frame(AdjVehProp)
  # Compute the age distribution by income and type
  VehPropByAgeIncGrpType <- VProp$VehPropByAgeIncGrpType

  VehPropByAgeIncGrpType <- reshape2::dcast(VehPropByAgeIncGrpType, ...~VehType, value.var = "Prop", fill = 0)

  VehPropByAgeInc_ <- do.call(cbind, lapply(AgeType, function(x) calcVehAgePropByInc(VehAgIgProp = VehPropByAgeIncGrpType[,x], AgeGrp = VehPropByAgeIncGrpType[,"VehAge"], AgeMargin = VehPropByAge[,x], IncGrp = VehPropByAgeIncGrpType[,"IncGrp"], IncMargin = VehPropByInc[,x])))
  VehPropByAgeIncGrpType[,c("Auto","LtTruck")] <- VehPropByAgeInc_


  # Apply ages to vehicles
  #-----------------------
  # Identify the number of autos and light trucks by income group
  NumLtTrucks_ <- sapply( Hh_df$VehType, function(x) sum( x == "LtTruck" ) )
  NumAutos_ <- Hh_df$Hhvehcnt - NumLtTrucks_
  NumLtTruckSamplesByInc <- tapply( NumLtTrucks_, Hh_df$IncGrp, sum )
  NumAutoSamplesByInc <- tapply( NumAutos_, Hh_df$IncGrp, sum )
  # Create age samples for light trucks by income group
  LtTruckSamplesByInc <- lapply(levels(VehPropByAgeIncGrpType$IncGrp),
                                function(x) sample(VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "VehAge"], NumLtTruckSamplesByInc[x], replace = TRUE, prob = VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "LtTruck"]))

  names(LtTruckSamplesByInc) <- levels(VehPropByAgeIncGrpType$IncGrp)
  # Create age samples for autos by income group
  AutoSamplesByInc <- lapply(levels(VehPropByAgeIncGrpType$IncGrp),
                             function(x) sample(VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "VehAge"], NumAutoSamplesByInc[x], replace = TRUE, prob = VehPropByAgeIncGrpType[VehPropByAgeIncGrpType$IncGrp==x, "Auto"]))

  names(AutoSamplesByInc) <- levels(VehPropByAgeIncGrpType$IncGrp)
  # Associate light truck and auto ages with each household
  LtTruckAges_ <- as.list( rep( NA, nrow( Hh_df ) ) )
  for( ig in levels(VehPropByAgeIncGrpType$IncGrp) ) {
    IsIncGrp_ <- Hh_df$IncGrp == ig
    HasLtTrucks_ <- NumLtTrucks_ != 0
    GetsAges_ <- IsIncGrp_ & HasLtTrucks_
    LtTruckAges_[ GetsAges_ ] <- split( LtTruckSamplesByInc[[ig]],
                                        rep( 1:sum( GetsAges_ ), NumLtTrucks_[ GetsAges_ ] ) )
  }
  # Associate auto ages with each household
  AutoAges_ <- as.list( rep( NA, nrow( Hh_df ) ) )
  for( ig in levels(VehPropByAgeIncGrpType$IncGrp) ) {
    IsIncGrp_ <- Hh_df$IncGrp == ig
    HasAuto_ <- NumAutos_ != 0
    GetsAges_ <- IsIncGrp_ & HasAuto_
    AutoAges_[ GetsAges_ ] <- split( AutoSamplesByInc[[ig]],
                                     rep( 1:sum( GetsAges_ ), NumAutos_[ GetsAges_ ] ) )
  }

  # Return the result
  #------------------
  # Combine auto and light truck lists
  VehAge_ <- mapply( c, LtTruckAges_, AutoAges_ )
  VehAge_ <- lapply( VehAge_, function(x) x[ !is.na(x) ] )
  # Make list of vehicle types correspond to ages list
  VehType_ <- apply( cbind( NumLtTrucks_, NumAutos_ ), 1, function(x) {
    rep( c( "LtTruck", "Auto" ), x ) } )
  # Return result as a list
  return(list( VehType = VehType_, VehAge = VehAge_ ))
}

# Function to assign mileage to vehicles in a household
#--------------------------------------------------------
#' Assignes mileage to vehicles in a household
#'
#' \code{assignFuelEconomy} Assignes mileage to vehicles in a household.
#'
#' This function assigns mileage to vehicles in a household based on type
#' age of the vehicles.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param VehMpgYr A data frame of mileage of vehicles by type and year.
#' @param CurrentYear A integer indicating the current year.
#' @return A numeric vector that indicates the mileage of vehicles.
#' @export
#'
assignFuelEconomy <- function( Hh_df, VehMpgYr=NULL, CurrentYear ) {
  # Calculate the sequence of years to use to index fleet average MPG
  if(is.null(VehMpgYr)){
    stop("The function needs mpg data on vehicles.")
  }
  Years <- as.character(VehMpgYr[,"Year"])
  rownames(VehMpgYr) <- Years
  StartYear <- as.numeric( CurrentYear ) - 32
  if( StartYear < 1975 ) {
    YrSeq_ <- Years[ 1:which( Years == CurrentYear ) ]
    NumMissingYr <- 1975 - StartYear
    YrSeq_ <- c( rep( "1975", NumMissingYr ), YrSeq_ )
  } else {
    YrSeq_ <- Years[ which( Years == StartYear ):which( Years == CurrentYear ) ]
  }
  # Calculate auto and light truck MPG by vehicle age
  VehMpgByAge <- VehMpgYr[rev(YrSeq_),]
  rownames( VehMpgByAge ) <- as.character( 0:32 )
  # Combine into vector and assign fuel economy to household vehicles
  VehType_ <- unlist(Hh_df$VehType)
  VehAge_ <- as.character(unlist(Hh_df$VehAge))
  VehMpg_ <- numeric(length(VehType_))
  VehMpg_[VehType_ == "Auto"] <- VehMpgByAge[VehAge_[VehType_ == "Auto"], "Auto"]
  VehMpg_[VehType_ == "LtTruck"] <- VehMpgByAge[VehAge_[VehType_ == "LtTruck"], "LtTruck"]
  # Split back into a list
  ListIndex_ <- rep( 1:nrow(Hh_df), Hh_df$Hhvehcnt )
  VehMpg_ <- split( VehMpg_, ListIndex_ )
  # Return the result
  return(VehMpg_)
}

# Function to assign VMT proportion to household vehicles
#--------------------------------------------------------
#' Assign VMT proportion to household vehicles.
#'
#' \code{apportionDvmt} Assign VMT proportion to household vehicles.
#'
#' This function assigns VMT proportions to household vehicles based on the
#' number of vehicles in the household and the probability distribution of proportion of
#' miles traveled by those vehicles.
#'
#' @param Hh_df A household data frame consisting of household characteristics.
#' @param DvmtProp A data frame of distribution of VMT proportion by number of
#' vehicles in a household.
#' @return A list containing number of vehicles and ownership ratio for each household
#' @export
#'
apportionDvmt <- function( Hh_df, DvmtProp=NULL ) {
  if(is.null(DvmtProp)){
    stop("Probability distribution of mileage proportion assignment
         for n vehicle household is required.")
  }
  # Create a list that stores the output of vehicle DVMT proportions
  VehDvmtPropOutput_ <- lapply( 1:nrow( Hh_df ), function(x) numeric(0) )
  # Nc is a vector of the classes of number of household vehicles
  Nc <- sort( unique( Hh_df$Hhvehcnt ) )
  # Iterate through each number class, get the subset of the data
  # Calculate the vehicle proportions, assign the results to the VehDvmtPropOutput_
  for( nc in Nc ) {
    # Make a subset of the input data
    DataSub_ <- Hh_df[ Hh_df$Hhvehcnt == nc, ]
    # Create a list to store the results for this subset
    VehDvmtProp_ <- lapply( seq_along(DataSub_$HhId), function(x) numeric(nc) )
    # Simplified process where there are only 1 or 2 vehicles in the household
    if( nc <= 2 ) {
      # If there is only one vehicle, then the DVMT proportion is 1
      if( nc == 1 ) {
        VehDvmtProp_ <- lapply( VehDvmtProp_, function(x) x <- 1 )
      } else {
        # If there are 2 vehicles, then sample to get 1st proportion
        # the 2nd proportion is 1 minus the 1st proportion
        # Extract the 2Veh matrix of DvmtProp_
        DvmtProp2d <- DvmtProp[,c("Veh2Value","Veh2Prob")]
        # Calculate the number of samples to be made
        NumSamples <- nrow(DataSub_)
        # Create a matrix to put the results into
        VehDvmtProp2d <- matrix( 0, nrow=NumSamples, ncol=nc )
        # Sample from the probabilities to get the 1st set of values
        VehDvmtProp2d[,1] <- sample( DvmtProp2d[,"Veh2Value"], NumSamples,
                                      replace=TRUE, prob=DvmtProp2d[,"Veh2Prob"] )
        # Calculate 2nd set of values
        VehDvmtProp2d[,2] <- 1 - VehDvmtProp2d[,1]
        # Put the values into the list
        for( i in 1:NumSamples ) VehDvmtProp_[[i]] <- VehDvmtProp2d[i,]
      }
      # General process for 3 or more vehicles in households
    } else {
      # Identify the class name to use to extract the appropriate proportion
      # distribution
      if( nc >= 5 ) {
        VehClassName <- "Veh5Plus"
      } else {
        VehClassName <- paste("Veh",  nc, sep="" )
      }
      # Extract the appropriate proportion distribution from DvmtProp_
      Var_ <- paste0(VehClassName, c("Value","Prob"))
      DvmtProp2d <- DvmtProp[, Var_]
      # Calculate the number of samples to be made
      NumSamples <- nrow(DataSub_)
      # Create a matrix to put the results into
      VehDvmtProp2d <- matrix( 0, nrow=NumSamples, ncol=nc )
      # Sample from probabilities to create values for 1st vehicle
      VehDvmtProp2d[,1] <- sample( DvmtProp2d[,Var_[1]], NumSamples, replace=TRUE,
                                    prob=DvmtProp2d[,Var_[2]] )
      # Iterate through each next vehicle to calculate DVMT proportion
      for( i in 2:nc ) {
        # Iterate through each row of the matrix
        VehDvmtProp2d[,i] <- apply( VehDvmtProp2d, 1, function(x) {
          # The remaining proportion can't be more than 1 minus the
          # sum of the existing proportions
          # Round to make sure that logic checks are correct
          RemProb <- round( 1 - sum(x), 2 )
          # If this is the last row, then the result has to be RemProb
          if( i == nc ) {
            Result <- RemProb
            # Otherwise calculate remaining probability
          } else {
            # If the RemProb is 0 then the result must be 0
            if( RemProb == 0 ) {
              Result <- 0
            } else {
              # If the RemProb is 0.05 then the result must be 0.05
              if( RemProb == 0.05 ) {
                Result <- 0.05
                # Otherwise sample from a limited sample frame
              } else {
                # Identify limited sample values and probabilities
                IsPossProb_ <- DvmtProp2d[,Var_[1]] <= RemProb
                Values_ <- DvmtProp2d[ IsPossProb_, Var_[1] ]
                Prob_ <- DvmtProp2d[ IsPossProb_, Var_[2] ]
                Result <- sample( Values_, 1, replace=TRUE, Prob_ )
              }
            }
          }
          # Return the result for the row which is put into the matrix column
          Result } )
      }
      # Put the results of the matrix into the the list for the vehicle number class
      for( i in 1:NumSamples ) VehDvmtProp_[[i]] <- VehDvmtProp2d[i,]
    }
    # Put the values into the correct locations in the overall output list
    VehDvmtPropOutput_[ Hh_df$Hhvehcnt == nc ] <- VehDvmtProp_
  }
  # Return the overall output list
  return(VehDvmtPropOutput_)
}

#This function generates various .

#Main module function that calculates vehicle features
#------------------------------------------------------
#' Create vehicle table and populate with vehicle type, age, and mileage records.
#'
#' \code{AssignVehicleFeatures} create vehicle table and populate with
#' vehicle type, age, and mileage records.
#'
#' This function creates the 'Vehicle' table in the datastore and populates it
#' with records of vehicle types, ages, mileage, and mileage proportions
#' along with household IDs.
#'
#' @param L A list containing the components listed in the Get specifications
#' for the module.
#' @return A list containing the components specified in the Set
#' specifications for the module.
#' @import visioneval
#' @import stats
#' @export
AssignVehicleFeatures <- function(L) {
  #Set up
  #------
  #Fix seed as synthesis involves sampling
  set.seed(L$G$Seed)
  #Define vector of Mareas
  Ma <- L$Year$Marea$Marea
  Bz <- L$Year$Bzone$Bzone
  #Calculate number of households
  NumHh <- length(L$Year$Household[[1]])

  #Set up data frame of household data needed for model
  #----------------------------------------------------
  Hh_df <- data.frame(L$Year$Household)
  Hh_df$DrvAgePop <- Hh_df$HhSize - Hh_df$Age0to14
  Hh_df$OnlyElderly <- as.numeric(Hh_df$HhSize == Hh_df$Age65Plus)
  # Hh_df$LowInc <- as.numeric(Hh_df$Income <= 20000)
  # Hh_df$LogIncome <- log(Hh_df$Income)
  # Classify households according to income group
  MaxInc <- max( Hh_df$Income )
  IncBreaks_ <- c( 0, 20000, 40000, 60000, 80000, 100000, MaxInc )
  Ig <- c("0to20K", "20Kto40K", "40Kto60K", "60Kto80K", "80Kto100K", "100KPlus")
  names(IncBreaks_) <- Ig
  Hh_df$IncGrp <- cut( Hh_df$Income, breaks=IncBreaks_, labels=Ig, include.lowest=TRUE )


  ######AG to CS/BS Average Density
  ###AG to CS/BS should this be a calculated average for the region?
  Hh_df$Htppopdn <- 500
  ###AG to CS/BS should this be 0 for rural? Or are we just using an average for both density and this var and then adjusting using 5D values?
  Hh_df$Urban <- 1
  # Calculate the natural log of density
  Hh_df$LogDen <- log( Hh_df$Htppopdn )
  # Density_ <- L$Year$Bzone$D1B[match(L$Year$Household$HhPlaceTypes, L$Year$Bzone$Bzone)]
  # Hh_df$LogDensity <- log(Density_)
  FwyLaneMiPC_Bz <- L$Year$Marea$FwyLaneMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$FwyLaneMiPC <- FwyLaneMiPC_Bz[match(L$Year$Household$HhPlaceTypes, L$Year$Bzone$Bzone)]
  TranRevMiPC_Bz <- L$Year$Marea$TranRevMiPC[match(L$Year$Bzone$Marea, L$Year$Marea$Marea)]
  Hh_df$TranRevMiPC <- TranRevMiPC_Bz[match(L$Year$Household$HhPlaceTypes, L$Year$Bzone$Bzone)]

  Lt1VehProp <- data.frame(VehOwnModels_ls$Lt1Prop)
  Gt1VehProp <- data.frame(VehOwnModels_ls$Gt1Prop)

  # Gather vehicle proportions for Lt1 and Gt1
  VehProp <- list(
    Metro = list(),
    NonMetro = list()
  )

  VehProp$Metro$Lt1 <- Lt1VehProp[Lt1VehProp$Region == "Metro", -1]
  VehProp$Metro$Gt1 <- Gt1VehProp[Gt1VehProp$Region == "Metro", -1]
  VehProp$NonMetro$Lt1 <- Lt1VehProp[Lt1VehProp$Region == "NonMetro", -1]
  VehProp$NonMetro$Gt1 <- Gt1VehProp[Gt1VehProp$Region == "NonMetro", -1]

  # Gather vehicle proportions for vehicle types, income groups, etc..
  VehPropByGroups <- list()
  VehPropByGroups$VehCumPropByAge <- data.frame(list(VehAge = VehOwnModels_ls$VehAgeCumProp$VehAge,
                                                     Auto = VehOwnModels_ls$VehAgeCumProp$AutoCumProp,
                                                     LtTruck = VehOwnModels_ls$VehAgeCumProp$LtTruckCumProp))
  VehPropByGroups$VehPropByAgeIncGrpType <- data.frame(list(VehAge = VehOwnModels_ls$VehAgeTypeProp$VehAge,
                                                            IncGrp = VehOwnModels_ls$VehAgeTypeProp$IncGrp,
                                                            VehType = VehOwnModels_ls$VehAgeTypeProp$VehType,
                                                            Prop = VehOwnModels_ls$VehAgeTypeProp$Prop))
  # Relevel the income groups
  VehPropByGroups$VehPropByAgeIncGrpType$IncGrp <- reorder(VehPropByGroups$VehPropByAgeIncGrpType$IncGrp,IncBreaks_[as.character(VehPropByGroups$VehPropByAgeIncGrpType$IncGrp)],FUN = max)


  rm(IncBreaks_, MaxInc, Ig)
  # Identify metropolitan area
  IsMetro_ <- Hh_df$Urban == 1

  # Initialize Hhvehcnt and VehPerDrvAgePop variables
  Hh_df$Hhvehcnt <- 0
  Hh_df$VehPerDrvAgePop <- 0

  #Run the model
  #-------------

  # Predict ownership for metropolitan households if any exist
  if(any(IsMetro_)){
    ModelVar_ <- c( "Income", "Htppopdn", "TranRevMiPC", "Urban",
                    "FwyLaneMiPC", "OnlyElderly", "DrvLevels", "DrvAgePop")
    MetroVehOwn_ <- predictVehicleOwnership( Hh_df[IsMetro_, ModelVar_],
                                   ModelType = VehOwnModels_ls, VehProp = VehProp,
                                   Type="Metro")
    rm(ModelVar_)
  }
  # Predict ownership for nonmetropolitan households if any exist
  if(any(!IsMetro_)){
    ModelVar_ <- c( "Income", "Htppopdn", "OnlyElderly", "DrvLevels", "DrvAgePop" )
    NonMetroVehOwn_ <- predictVehicleOwnership(Hh_df[IsMetro_, ModelVar_],
                                               ModelType = VehOwnModels_ls, VehProp = VehProp,
                                               Type="NonMetro")
    rm(ModelVar_)
  }

  # Assign values to SynPop.. and return the result
  if( any(IsMetro_) ) {
    Hh_df$Hhvehcnt[ IsMetro_ ] <- MetroVehOwn_$NumVeh
    Hh_df$VehPerDrvAgePop[ IsMetro_ ] <- MetroVehOwn_$VehRatio
  }
  if( any(!IsMetro_) ) {
    Hh_df$Hhvehcnt[ !IsMetro_ ] <- NonMetroVehOwn_$NumVeh
    Hh_df$VehPerDrvAgePop[ !IsMetro_ ] <- NonMetroVehOwn_$VehRatio
  }
  # Clean up
  if( exists( "MetroVehOwn_" ) ) rm( MetroVehOwn_ )
  if( exists( "NonMetroVehOwn_" ) ) rm( NonMetroVehOwn_ )

  # Calculate vehicle types, ages, and initial fuel economy
  #========================================================

  # Predict light truck ownership and vehicle ages
  #-----------------------------------------------
  # Apply vehicle type model
  ModelVar_ <- c( "Income", "Htppopdn", "Urban", "Hhvehcnt", "HhSize" )
  #light truck proportion is a single value in parameters_
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  Hh_df$VehType <- predictLtTruckOwn( Hh_df[ , ModelVar_ ], ModelType=LtTruckModels_ls,
                                         TruckProp=L$Global$Model$LtTruckProp )
  rm( ModelVar_ )
  # Apply vehicle age model
  ModelVar_ <- c( "IncGrp", "Hhvehcnt", "VehType" )
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  VehTypeAgeResults_ <- calcVehicleAges(Hh_df = Hh_df[, ModelVar_], VProp = VehPropByGroups)
  rm( ModelVar_ )
  # Add type and age model results
  Hh_df$VehType[ Hh_df$Hhvehcnt == 0 ] <- NA
  Hh_df$VehAge <- VehTypeAgeResults_$VehAge
  Hh_df$VehAge[ Hh_df$Hhvehcnt == 0 ] <- NA
  rm( VehTypeAgeResults_ )

  # Assign initial fuel economy
  #----------------------------
  # Assign fuel economy to vehicles
  HhHasVeh <- Hh_df$Hhvehcnt > 0
  Hh_df$VehMpg <- NA
  ModelVar_ <- c( "VehType", "VehAge", "Hhvehcnt" )
  VehMpgYr <- cbind(Year = ceiling(L$Global$Vehicles$ModelYear), Auto = L$Global$Vehicles$AutoMpg, LtTruck = L$Global$Vehicles$LtTruckMpg)
  Hh_df$VehMpg[HhHasVeh] <- assignFuelEconomy( Hh_df[HhHasVeh, ModelVar_],
                                                     VehMpgYr = VehMpgYr, CurrentYear = L$G$Year)
  rm( ModelVar_ )

  # Assign vehicle mileage proportions to household vehicles
  Hh_df$DvmtProp <- NA
  ModelVar_ <- c("Hhvehcnt", "HhId")
  DvmtProp_ <- data.frame(Veh1Value = VehOwnModels_ls$VehicleMpgProp$Veh1Value,
                         Veh1Prob = VehOwnModels_ls$VehicleMpgProp$Veh1Prob,
                         Veh2Value = VehOwnModels_ls$VehicleMpgProp$Veh2Value,
                         Veh2Prob = VehOwnModels_ls$VehicleMpgProp$Veh2Prob,
                         Veh3Value = VehOwnModels_ls$VehicleMpgProp$Veh3Value,
                         Veh3Prob = VehOwnModels_ls$VehicleMpgProp$Veh3Prob,
                         Veh4Value = VehOwnModels_ls$VehicleMpgProp$Veh4Value,
                         Veh4Prob = VehOwnModels_ls$VehicleMpgProp$Veh4Prob,
                         Veh5PlusValue = VehOwnModels_ls$VehicleMpgProp$Veh5PlusValue,
                         Veh5PlusProb = VehOwnModels_ls$VehicleMpgProp$Veh5PlusProb)
  #fix seed as allocation involves sampling
  set.seed(L$G$Seed)
  Hh_df$DvmtProp[ HhHasVeh ] <- apportionDvmt( Hh_df[ HhHasVeh, ModelVar_],
                                                   DvmtProp=DvmtProp_ )
  rm( ModelVar_ )

  # Count the number of vehicle types per houshold
  #------------------------------------------------

  Hh_df$NumAuto <- unlist(lapply(Hh_df$VehType,function(x) sum(x=="Auto")))
  Hh_df$NumAuto[is.na(Hh_df$NumAuto)] <- 0L
  Hh_df$NumLtTruck <- Hh_df$Hhvehcnt - Hh_df$NumAuto




  #Return the results
  #------------------
  #Identify households having vehicles
  Use <- Hh_df$Hhvehcnt != 0
  #Initialize output list
  Out_ls <- initDataList()
  Out_ls$Year$Vehicle <- list()
  attributes(Out_ls$Year$Vehicle)$LENGTH <- sum(Hh_df$Hhvehcnt)
  Out_ls$Year$Vehicle$HhId <-
    with(L$Year$Household, rep(HhId[Use], Hh_df$Hhvehcnt[Use]))
  attributes(Out_ls$Year$Vehicle$HhId)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$HhId))
  Out_ls$Year$Vehicle$VehId <-
    with(Hh_df,
         paste(rep(HhId[Use], Hhvehcnt[Use]),
               unlist(sapply(Hhvehcnt[Use], function(x) 1:x)),
               sep = "-"))
  attributes(Out_ls$Year$Vehicle$VehId)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$VehId))
  Out_ls$Year$Vehicle$Azone <-
    with(L$Year$Household, rep(Azone[Use], Hh_df$Hhvehcnt[Use]))
  attributes(Out_ls$Year$Vehicle$Azone)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$Azone))
  Out_ls$Year$Vehicle$Marea <-
    with(L$Year$Household, rep(Marea[Use], Hh_df$Hhvehcnt[Use]))
  attributes(Out_ls$Year$Vehicle$Marea)$SIZE <-
    max(nchar(Out_ls$Year$Vehicle$Marea))
  Out_ls$Year$Vehicle$Type <- unlist(Hh_df$VehType[Use])
  Out_ls$Year$Vehicle$Type[Out_ls$Year$Vehicle$Type=="LtTruck"] <- "LtTrk"
  attributes(Out_ls$Year$Vehicle$Type)$SIZE <- max(nchar(Out_ls$Year$Vehicle$Type))
  Out_ls$Year$Vehicle$Age <- unlist(Hh_df$VehAge[Use])
  Out_ls$Year$Vehicle$Mileage <- unlist(Hh_df$VehMpg[Use])
  Out_ls$Year$Vehicle$DvmtProp <- unlist(Hh_df$DvmtProp[Use])

  Out_ls$Year$Household <-
    list(NumLtTrk = Hh_df$NumLtTruck,
         NumAuto = Hh_df$NumAuto,
         Vehicles = Hh_df$Hhvehcnt)


  #Return the outputs list
  Out_ls
}

#================================
#Code to aid development and test
#================================
#Test code to check specifications, loading inputs, and whether datastore
#contains data needed to run module. Return input list (L) to use for developing
#module functions
# #-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleFeatures",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = FALSE,
#   RunFor = "NotBaseYear"
# )
# L <- TestDat_$L

#Test code to check everything including running the module and checking whether
#the outputs are consistent with the 'Set' specifications
#-------------------------------------------------------------------------------
# TestDat_ <- testModule(
#   ModuleName = "AssignVehicleOwnership",
#   LoadDatastore = TRUE,
#   SaveDatastore = TRUE,
#   DoRun = TRUE,
#   RunFor = "NotBaseYear"
# )
