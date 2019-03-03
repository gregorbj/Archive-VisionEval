#===================
#SimulateD4cValues.R
#===================
#
#### Distance to Transit (D4C) Model
#
#Distance to transit is the last of the 5D measures that need to be attributed to the SimBzones. The measure chosen for use in VisionEval is the *D4c* measure included in the SLD. Following is the description of the measure from the user guide:
#
#>EPA analyzed GTFS data to calculate the frequency of service for each transit route between 4:00 and 7:00 PM on a weekday. Then, for each block group, EPA identified transit routes with service that stops within 0.4 km (0.25 miles). Finally EPA summed total aggregate service frequency by block group. Values for this metric are expressed as service frequency per hour of service.

#The model of D4c is more complex than some of the other models because it needs to be sensitive to the urbanized area transit supply (transit revenue miles per capita). As the urbanized area transit supply increases, the average peak period service accessible at the Bzone level should rise as well. The distribution of D4c values among Bzones is complex and dependent on transit operations and routing as well as well as socio-economic and land use characteristics. The augmented SLD data only contains data on a fraction of the relevant factors, therefore the model is only able to capture a fraction of the observed variability in values. Moreover, data on urbanized area transit supply and D4c is only available for a portion of the named urbanized areas in the SLD. Out of 489 named urbanized areas, transit supply and D4c data is available for only 127 of them.
#
#The D4c model is designed a 2-component model because a significant portion (~ 30%) of the block groups in the 127 urbanized areas in the estimation sample have a value of 0. Therefore the D4c model includes a binomial logit model to predict the likelihood that a SimBzone has no accessible peak period transit service. The second component is a log linear model which predicts the D4c value if it is not 0.
#
#The models need to account for urbanized differences in service areas. That will affect the average density of service (revenue miles per square mile) and therefore affect the average frequency of transit service. The models also need to account for urbanized area transit service and other characteristics that effect how aggregate service miles translate into peak period service frequency. These factors are accounted for by:
#
#* Dividing urbanized area revenue miles by urbanized area land area to calculate service density
#
#* Dividing the D4c value
#
#Approach is to have a 2-step model. One step determines whether a Bzone has a D4c value of 0. The other step determines what the D4c value for a Bzone is if it is not 0.
#
#There are few variables to base the model on. Relevant ones are:
#
#* Transit revenue miles: higher service should result in higher D4c
#
#* Density: higher transit service more likely to be provided to higher density
#
#* Design: higher design neighborhoods more likely to be served by transit
#
#* Accessibility: higher transit service more likely for higher accessibility
#
#The model .
#
#lm(formula = LogD4PerSqMi ~ LogUaRevMiPerSvcSqMi + LogUaSvcAveD4PerSqMi +
#
#</doc>

#Create D4 analysis dataset for urbanized areas
#----------------------------------------------
KeepVars_ <-
  c("UA_NAME", "STATE", "TransitRevMi", "D4c", "TOTACT", "AreaType", "DevType",
    "UZA_SIZE", "AC_LAND", "D1D", "D5", "D2Grp", "D3bpo4")
D4_df <- Ua_df[!(is.na(Ua_df$D4c)) & !(is.na(Ua_df$TransitVehMi)), KeepVars_]
rm(KeepVars_)
names(D4_df) <-
  c("UaName", "State", "TranRevMi", "D4c", "TotAct", "AreaType", "DevType",
    "UaSize", "AcLand", "D1D", "D5", "D2Grp", "D3BPO4")
#Identify which D4 values are 0 and remove urbanized areas that have all 0
Is0D4 <- D4_df$D4c == 0
All0D4_Ua <- tapply(Is0D4, D4_df$UaName, all)
RemoveUaName_ <- names(All0D4_Ua[All0D4_Ua])
Is0D4 <- Is0D4[!(D4_df$UaName %in% RemoveUaName_)]
D4_df <- D4_df[!(D4_df$UaName %in% RemoveUaName_),]
rm(All0D4_Ua, RemoveUaName_)
Is0D4 <- D4_df$D4c == 0
#Calculate D4c per acre
D4_df$D4PerAcre <- D4_df$D4c / D4_df$AcLand
#Calculate power transform for D3bpo to normalize
D3Pow <- findPower(D4_df$D3BPO4[D4_df$D3BPO4 != 0])

#Calculate urbanized area statistics
#-----------------------------------
UaD4_df <- data.frame(
  UaTotAcLand = tapply(D4_df$AcLand, D4_df$UaName, sum),
  UaSvcAcLand = tapply(D4_df$AcLand[!Is0D4], D4_df$UaName[!Is0D4], sum),
  UaTranRevMi = tapply(D4_df$TranRevMi, D4_df$UaName, function(x) x[1]),
  UaSize = tapply(D4_df$UaSize, D4_df$UaName, function(x) x[1]),
  UaTotAct = tapply(D4_df$TotAct, D4_df$UaName, sum)
)
#Calculate transit revenue miles per acre of serviced land
UaD4_df$UaTranRevMiPerAcre <- with(UaD4_df, UaTranRevMi / UaSvcAcLand)
#Calculate overall urbanized area activity density
UaD4_df$UaActDen <- with(UaD4_df, UaTotAct / UaTotAcLand)
#Calculate average serviced D4c per acre for entire urbanized area weighted by activity
UaD4_df$UaSvcAveD4PerAcre <- unlist(lapply(Tmp_Ua_df, function(x) {
  sum(x$D4c) / sum(x$UaTotAcLand)}))
#Calculate ratio of UaSvcAveD4PerAcre and UaTranRevMiPerAcre
UaD4_df$D4ServiceRatio <- with(UaD4_df, UaSvcAveD4PerAcre / UaTranRevMiPerAcre)
#Remove outliers that have unusually large service ratios (Boston, Minneapolis)
HighSvcRatio_ <-
  which(UaD4_df$D4ServiceRatio > quantile(UaD4_df$D4ServiceRatio, probs = 0.99))
UaD4_df <- UaD4_df[-HighSvcRatio_,]
D4_df <- D4_df[D4_df$UaName %in% rownames(UaD4_df),]
Is0D4 <- D4_df$D4c == 0

#Save service ratio parameters values and average values by size for unlisted
#----------------------------------------------------------------------------
D4ServiceRatio_Ux <- UaD4_df$D4ServiceRatio
names(D4ServiceRatio_Ux) <- rownames(UaD4_df)
D4ServiceRatio_Sz <- tapply(UaD4_df$D4ServiceRatio, UaD4_df$UaSize, mean)
names(D4ServiceRatio_Sz) <- Sz
SimBzone_ls$UaProfiles$D4ServiceRatios <- c(D4ServiceRatio_Ux, D4ServiceRatio_Sz)
rm(D4ServiceRatio_Ux, D4ServiceRatio_Sz)

#Make dataset to use for estimating D4c model
#--------------------------------------------
Keep_ <- c("UaName", "D4PerAcre", "D4c", "D1D", "D5", "D2Grp", "D3BPO4", "AcLand")
Test_df <- D4_df[, Keep_]
Test_df$UaTranRevMiPerAcre <- UaD4_df[Test_df$UaName, "UaTranRevMiPerAcre"]
Test_df$UaSvcAveD4PerAcre <- UaD4_df[Test_df$UaName, "UaSvcAveD4PerAcre"]
Test_df$D4ServiceRatio <- UaD4_df[Test_df$UaName, "D4ServiceRatio"]
Test_df$LogUaTranRevMiPerAcre <- log(Test_df$UaTranRevMiPerAcre)
Test_df$LogUaSvcAveD4PerAcre <- log(Test_df$UaSvcAveD4PerAcre)
Test_df$LogD4ServiceRatio <- log(Test_df$D4ServiceRatio)
Test_df$LogD4PerAcre <- log(Test_df$D4PerAcre)
Test_df$LogD1 <- log(Test_df$D1D)
Test_df$LogD5 <- log(Test_df$D5)
Test_df$PowD3 <- Test_df$D3BPO4 ^ D3Pow

#Define function to estimate D4c model if D4c is not 0
#-----------------------------------------------------
estimateD4cModel <- function(Data_df, StartTerms_, Pow) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <- function(In_df) {
    Out_df <- In_df
    Out_df$LogUaTranRevMiPerAcre <- log(In_df$UaTranRevMiPerAcre)
    Out_df$LogUaSvcAveD4PerAcre <- log(In_df$UaSvcAveD4PerAcre)
    Out_df$LogD4ServiceRatio <- log(In_df$D4ServiceRatio)
    Out_df$LogAveD4Service <- with(In_df, log(UaTranRevMiPerAcre * D4ServiceRatio))
    Out_df$LogD1 <- log(In_df$D1D)
    Out_df$PowD3 <- In_df$D3BPO4 ^ D3Pow
    Out_df$LogD5 <- log(In_df$D5)
    Out_df$largely.hh <- as.numeric(In_df$D2Grp == "largely-hh")
    Out_df$mixed <- as.numeric(In_df$D2Grp == "mixed")
    Out_df$largely.job <- as.numeric(In_df$D2Grp == "largely-job")
    Out_df$primarily.job <- as.numeric(In_df$D2Grp == "primarily-job")
    Out_df$Intercept <- 1
    Out_df
  }
  #Prepare estimation data
  EstData_df <- prepIndepVar(Data_df)
  EstData_df$LogD4PerAcre <- log(Data_df$D4PerAcre)
  #Define function to make a model formula
  makeFormula <-
    function(Terms_) {
      FormulaString <-
        paste("LogD4PerAcre ~ ", paste(Terms_, collapse = "+"))
      as.formula(FormulaString)
    }
  D4CModel_LM <-
    lm(makeFormula(StartTerms_), data = EstData_df)
  Coeff_mx <- coefficients(summary(D4CModel_LM))
  EndTerms_ <- rownames(Coeff_mx)[Coeff_mx[, "Pr(>|t|)"] <= 0.05]
  if ("(Intercept)" %in% EndTerms_) {
    EndTerms_ <- EndTerms_[-grep("(Intercept)", EndTerms_)]
  }
  D4CModel_LM <- lm(makeFormula(EndTerms_), data = EstData_df)
  #Define function to transform model outputs
  transformResult <- function(Result_) {
    exp(Result_) * EstData_df$AcLand
  }
  #Return model
  list(
    Type = "linear",
    Formula = makeModelFormulaString(D4CModel_LM),
    PrepFun = prepIndepVar,
    OutFun = transformResult,
    Summary = capture.output(summary(D4CModel_LM))
  )
}

#Estimate D4C model if D4c is not 0
#----------------------------------
SimBzone_ls$UaProfiles$D4CModel <- estimateD4cModel(
  Data_df = Test_df[!Is0D4,],
  StartTerms_ = c(
    "LogUaTranRevMiPerAcre", "LogD4ServiceRatio", "LogD1", "PowD3", "LogD5",
    "largely.hh", "mixed", "largely.job", "primarily.job"),
  Pow = D3Pow)
SimBzone_ls$UaProfiles$D4CModel <- estimateD4cModel(
  Data_df = Test_df[!Is0D4,],
  StartTerms_ = c(
    "LogAveD4Service", "LogD1", "PowD3", "LogD5",
    "largely.hh", "mixed", "largely.job", "primarily.job"),
  Pow = D3Pow)
SimBzone_ls$UaProfiles$D4CModel$Summary

#Define function to estimate model to predict probability that D4c is zero
#-------------------------------------------------------------------------
estimateZeroD4Model <- function(EstData_df, StartTerms_, Pow) {
  #Define function to prepare inputs for estimating model
  prepIndepVar <-
    function(In_df) {
      Out_df <- In_df
      Out_df$LogUaSvcAveD4PerAcre <- log(In_df$UaSvcAveD4PerAcre)
      Out_df$LogD1 <- log(In_df$D1D)
      Out_df$PowD3 <- In_df$D3BPO4 ^ D3Pow
      Out_df$LogD5 <- log(In_df$D5)
      Out_df$Intercept <- 1
      Out_df
    }
  EstData_df <- prepIndepVar(EstData_df)
  #Define function to make the model formula
  makeFormula <-
    function(StartTerms_) {
      FormulaString <-
        paste("Is0D4 ~ ", paste(StartTerms_, collapse = "+"))
      as.formula(FormulaString)
    }
  #Estimate model
  ZeroD4Model <-
    glm(makeFormula(StartTerms_), family = binomial, data = EstData_df)
  #Return model
  list(
    Type = "binomial",
    Formula = makeModelFormulaString(ZeroD4Model),
    Choices = c("ZeroD4", "NonZeroD4"),
    PrepFun = prepIndepVar,
    Summary = capture.output(summary(ZeroD4Model))
  )
}

#Estimate model to predict probability that D4c is zero
#------------------------------------------------------
SimBzone_ls$UaProfiles$ZeroD4Model <- estimateZeroD4Model(
  EstData_df <- Test_df,
  StartTerms_ = c("LogUaSvcAveD4PerAcre", "LogD1", "PowD3", "LogD5"),
  Pow = PowD3
)
SimBzone_ls$UaProfiles$ZeroD4Model$Summary
,
"LogUaTranRevMiPerAcre"





#Test Model
#----------
NObs <- nrow(Test_df)
Est_ <- runif(NObs) < Test_GLM$fitted.values
Comp_df <- data.frame(
  Obs = Test_df$Is0D4,
  Est = as.numeric(Est_),
  UaName = D4_df$UaName,
  State = D4_df$State
)
table(Comp_df$Obs)
table(Comp_df$Est)
with(Comp_df, table(Obs, Est))
PropIs0D4_Ua2 <-
  do.call(rbind, lapply(split(Comp_df, Comp_df$UaName), function(x) {
    c(
      Obs = sum(x$Obs) / length(x$Obs),
      Est = sum(x$Est) / length(x$Est)
    )
  }))
with(data.frame(PropIs0D4_Ua2), plot(Obs, Est))
abline(0, 1, lty = 2)
UaProp0_LM <- lm(Est ~ Obs, data = data.frame(PropIs0D4_Ua2))
abline(UaProp0_LM)



#Test Model
#----------
#Predict values
predictD4 <- function(D4_LM, D4_GLM, NewData_df) {
  Est_ <- predict(D4_LM, newdata = NewData_df)
  Prob_ <- predict(D4_GLM, type = "response", newdata = NewData_df)
  IsNot0D4_ <- runif(length(Prob_)) > Prob_
  Est_ *  as.numeric(IsNot0D4_)
}
obsD4 <- function(Obs_) {
  Obs_[is.infinite(Obs_)] <- 0
  Obs_
}
Comp_df <- data.frame(
  Obs = obsD4(Test_df$LogD4PerSqMi),
  Est = predictD4(Test_LM, Test_GLM, Test_df),
  UaName = D4_df$UaName,
  State = D4_df$State
)
sink("data/compare_D4_lm_stats.txt")
cat("Observed (SLD) Values for LogD4SqMi\n")
summary(Comp_df$Obs)
cat("\n")
cat("Modeled Values for LogD4SqMi\n")
summary(Comp_df$Est)
sink()
#Scatterplot of observed and estimated values
png("data/D4_obs-vs-est_scatterplot.png", width = 480, height = 480)
plot(Comp_df$Obs, Comp_df$Est, xlab = "Observed LogD4SqMi",
     ylab = "Modeled LogD4SqMi")
abline(0, 1, col = "red")
dev.off()
#Compare urbanized area mean values
CompMeans_Ua2 <-
  do.call(rbind, lapply(split(Comp_df, Comp_df$UaName), function(x) {
    c(Obs = mean(x$Obs), Est = mean(x$Est))}))
png("data/est-vs-obs-d4_ua-means.png", width = 480, height = 480)
with(data.frame(CompMeans_Ua2),
     plot(Obs, Est, xlab = "Observed", ylab = "Modeled",
          main = "Urbanized Area Average LogD4SqMi",
          pch = 20, col = "darkgrey", cex = 1.5)
)
abline(0, 1, lty = 2)
AveD4_LM <- lm(Est ~ Obs, data = data.frame(CompMeans_Ua2))
abline(AveD4_LM)
legend("bottomright", lty = c(1, 3), bty = "n",
       legend = c("Modeled ~ Observed", "1:1 slope"))
dev.off()
rm(CompMeans_Ua2)
#Compare overall distributions
png("data/est-vs-obs_dists_all-ua.png", width = 480, height = 480)
plot(density(Comp_df$Est),
     main = paste0("Probability Distributions of Modeled and Observed LogD4SqMi",
                   "\nFor all Urbanized Area Block Groups"))
lines(density(Comp_df$Obs), lty = 2)
legend("topleft", lty = c(1, 2), bty = "n", legend = c("Modeled", "Observed"))
dev.off()
#Function to plot comparative distributions for up to 9 urbanized areas
multiDistCompare <-
  function(UaToPlot_, Obs_Ua, Est_Ua, UaNames_Ua, Title = "") {
    Opar_ls <- par(mfrow = c(3,3), oma = c(0,0,3,0))
    for (nm in UaToPlot_) {
      IsUa <- UaNames_Ua == nm
      plot(density(Est_Ua[IsUa]), xlab = "log(D4c / SqMi)",
           main = nm)
      lines(density(Obs_Ua[IsUa]), lty = 2)
      lines(density(Est_Ua[IsUa]))
    }
    mtext(text = Title, side = 3, outer = TRUE)
    par(Opar_ls)
  }
#Compare distributions for selection of medium urbanized areas
png("data/est-vs-obs_dists_med-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Bakersfield, CA",
    "Durham, NC",
    "Eugene, OR",
    "Madison, WI",
    "Medford, OR",
    "New Haven, CT",
    "Olympia-Lacey, WA",
    "Salem, OR",
    "Spokane, WA"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Medium Metropolitan Areas")
)
dev.off()
#Compare distributions for selection of medium-large urbanized areas
png("data/est-vs-obs_dists_med-lrg-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Albuquerque, NM",
    "Birmingham, AL",
    "Bridgeport-Stamford, CT-NY",
    "Buffalo, NY",
    "Nashville-Davidson, TN",
    "Providence, RI-MA",
    "Raleigh, NC",
    "Rochester, NY",
    "Salt Lake City-West Valley City, UT"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Medium-Large Metropolitan Areas")
)
dev.off()
#Compare distributions for selection of large metropolitan areas
png("data/est-vs-obs_dists_lrg-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Atlanta, GA",
    "Baltimore, MD",
    "Boston, MA-NH-RI",
    "Cincinnati, OH-KY-IN",
    "Dallas-Fort Worth-Arlington, TX",
    "Denver-Aurora, CO",
    "Portland, OR-WA",
    "Sacramento, CA",
    "Seattle, WA"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Large Metropolitan Areas")
)
dev.off()
#Compare distributions for selection of very large metropolitan areas
png("data/est-vs-obs_dists_vry-lrg-ua.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "Philadelphia, PA-NJ-DE-MD",
    "Chicago, IL-IN",
    "Los Angeles-Long Beach-Anaheim, CA",
    "New York-Newark, NY-NJ-CT"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$UaName,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of Very Large Metropolitan Areas")
)
dev.off()
#Compare distributions for first selection of states
png("data/est-vs-obs_dists_state1.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "CA",
    "CO",
    "FL",
    "GA",
    "IL",
    "IN",
    "KY",
    "MA",
    "MD"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$State,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of States")
)
dev.off()
#Compare distributions for 2nd selection of states
png("data/est-vs-obs_dists_state2.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "MI",
    "MN",
    "MO",
    "NJ",
    "NV",
    "NY",
    "OH",
    "OR",
    "PA"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$State,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of States")
)
dev.off()
#Compare distributions for 3rd selections of states
png("data/est-vs-obs_dists_state3.png", width = 600, height = 600)
multiDistCompare(
  UaToPlot_ = c(
    "TX",
    "VA",
    "WA",
    "WI"
  ),
  Obs_Ua = Comp_df$Obs,
  Est_Ua = Comp_df$Est,
  UaNames_Ua = Comp_df$State,
  Title = paste0("Modeled (solid) vs. Observed (dashed) D4c Distributions\n",
                 "For Section of States")
)
dev.off()

#Model to predict probability that D4c is zero
#---------------------------------------------
D4_df$LogPeakRevMiSqMi <- log(D4_df$PeakRevMiSqMi)
D3Pow <- findPower(D4_df$D3[D4_df$D3 != 0])
UaToBg_ <- match(D4_df$UaName, rownames(UaD4_df))

Test_df <- data.frame(
  Is0D4 = as.numeric(Is0D4),
  PropActSvc = UaD4_df$UaPropActSvc[UaToBg_],
  LogUaRevMiPerSvcSqMi = log(UaD4_df$UaRevMiPerSvcSqMi[UaToBg_]),
  LogD1 = log(D4_df$D1),
  PowD3 = D4_df$D3 ^ D3Pow,
  LogD5 = log(D4_df$D5),
  D2Grp = D4_df$D2Grp
)

Test_GLM <- glm(Is0D4 ~
                  PropActSvc +
                  LogUaRevMiPerSvcSqMi +
                  LogD1 +
                  PowD3 +
                  LogD5 +
                  LogD5:LogD1,
                family = binomial,
                data = Test_df)
summary(Test_GLM)

#Test Model
#----------
NObs <- nrow(Test_df)
Est_ <- runif(NObs) < Test_GLM$fitted.values
Comp_df <- data.frame(
  Obs = Test_df$Is0D4,
  Est = as.numeric(Est_),
  UaName = D4_df$UaName,
  State = D4_df$State
)
table(Comp_df$Obs)
table(Comp_df$Est)
with(Comp_df, table(Obs, Est))
PropIs0D4_Ua2 <-
  do.call(rbind, lapply(split(Comp_df, Comp_df$UaName), function(x) {
    c(
      Obs = sum(x$Obs) / length(x$Obs),
      Est = sum(x$Est) / length(x$Est)
    )
  }))
with(data.frame(PropIs0D4_Ua2), plot(Obs, Est))
abline(0, 1, lty = 2)
UaProp0_LM <- lm(Est ~ Obs, data = data.frame(PropIs0D4_Ua2))
abline(UaProp0_LM)

