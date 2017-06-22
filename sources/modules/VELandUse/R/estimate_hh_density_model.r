#estimate_hh_density_model.r
#===========================

#*Author:* Brian Gregor
#*Contact:* Brian.J.Gregor@odot.state.or.us
#*Version:* 1.1
#*Date:* 10/08/10
#*License:* GNU General Public License Version 3


#Purpose
#=======

#Notes:
#Several portions of the GreenSTEP model are estimated using population density at the Census tract level. However, since the model does not operate at that geographic scale, it is necessary to create a means to decompose a forecast of metropolitan area population density into a distribution of census tract densities for each metropolitan area.
#The model also must identify whether a household is in an urban mixed-use tract or non-urban mixed-use tract. The designation refers to centrally located areas that are more likely to have mixed-use development and pedestrian and transit-oriented urban design.
 

#Set up
#======

	library( RColorBrewer )
	library( xtable )
	
	
#Load and prepare household data for model estimation
#====================================================

#Load household data select relevant variables and keep cases with sufficient information
#----------------------------------------------------------------------------------------

#Notes:
#Household records are kept only for households that have complete records for the following household variables: "Houseid", "Census_r", "Htppopdn", "Hhincttl", "Hhsize", "Hhvehcnt", "Msacat", "Ratio16v", "Urban", "Dvmt", "Numcommdrvr", "Age0to14", "Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus"

     load("data/Hh..RData")
	FieldsToKeep. <- c( "Houseid", "Census_r", "Expflhhn", "Hhc_msa", "Hhincttl",
	     "Htppopdn", "Hthur", "Hhsize", "Hhvehcnt", "Msacat", "Ratio16v", "Urban", "Dvmt",
		"Totmiles", "Numcommdrvr", "Age0to14", "Age15to19", "Age20to29", "Age30to54",
		"Age55to64", "Age65Plus", "Roadmicap", "Fwylnmicap", "MsaPopdn", "Tranmilescap" )
     Hh.. <- Hh..[ , FieldsToKeep. ]
     Hh..$Hthur[ Hh..$Hthur == "-9" ] <- NA
	CompleteFields. <- c( "Houseid", "Census_r", "Hhincttl", "Htppopdn", "Hhsize", "Hhvehcnt",
		"Hthur", "Msacat", "Ratio16v", "Urban", "Dvmt", "Numcommdrvr", "Age0to14",
		"Age15to19", "Age20to29", "Age30to54", "Age55to64", "Age65Plus" )
	Hh.. <- Hh..[ complete.cases( Hh..[,CompleteFields.] ), ]

#Make Urban dummy variable
#-------------------------
#Notes:
#The Hthur variable is used as a surrogate for urban form. It has one of 5 values based on the type of area that the census tract of the household is located in (urban represents the central city area. This is the area that is most likely to be mixed use and be more pedestrian and transit friendly). The urban category was found to be helpful in predicting DVMT. It will be used for vehicle modeling too.

	Hh..$Urban <- ( Hh..$Hthur == "U" ) * 1

#Make metroplitan area subset of the data
#----------------------------------------

	attach( Hh.. )
     # Identify which records are within metropolitan areas
     IsMetro <- ( Msacat %in% c("1", "2") )
     # Make metropolitan area subset of the data
	MetroHh.. <- Hh..[IsMetro,]
	# Clean up the workspace
     detach( Hh.. )
     rm( IsMetro, Hh.. )

#Create a correspondence between MSA codes and names
#---------------------------------------------------

	MsaCodeName.. <- read.csv( "data/msa_code_name.csv", colClasses=c( "character", "character" ) )
	MsaCodeName. <- MsaCodeName..$MsaCode
	names(MsaCodeName.) <- MsaCodeName..$Name
	MsaCodeName. <- MsaCodeName.[!(names(MsaCodeName.) %in% "Honolulu")]
	rm(MsaCodeName..)
	MsaNameCode. <- names( MsaCodeName. )
	names( MsaNameCode. ) <- MsaCodeName.


#Census data on overall metropolitan density and tract density for 10 MSAs
#=========================================================================

#Notes:
#Census data for 10 MSAs is used to develop the density model. The data are for census tract populations and density. Population density is calculated for all tracts in the MSA and just for tracts in the urbanized area of the MSA.

	MsaNames. <- c( "Portland", "Salem", "Eugene", "Medford", "LosAngeles", "SanFrancisco",
		"Atlanta", "Dallas", "LasVegas", "Nashville" )
	MsaCensusFiles. <- c( "Portland.txt", "Salem.txt", "Eugene.txt", "Medford.txt",
		"Los_Angeles.txt", "San_Francisco.txt", "Atlanta.txt", "Dallas.txt", "Las_Vegas.txt",
		"Nashville.txt" )
	MsaCensusFiles. <- paste( "data/census/", MsaCensusFiles., sep="" )
	MsaDen_ <- list()
	UbzDen_ <- list()
	MsaPop_ <- list()
	UbzPop_ <- list()
	MsaAveDen. <- numeric(0)
	UbzAveDen. <- numeric(0)
	for( i in 1:length( MsaNames. ) ) {
		ObjName <- paste( MsaNames.[i], "..", sep="" )
		TempIn.. <- read.table( MsaCensusFiles.[i], header=TRUE, sep="\t",
			colClasses=c( "character", "character", "numeric", "numeric", "numeric" ),
			col.names=c( "Tract", "MsaCode", "Population", "AreaSqMi", "PopDensity" )
			)
		MsaDen_[[ MsaNames.[i] ]] <- TempIn..$PopDensity
		UbzDen_[[ MsaNames.[i] ]] <- TempIn..$PopDensity[ TempIn..$PopDensity > 1000 ]
		MsaPop_[[ MsaNames.[i] ]] <- TempIn..$Population
		UbzPop_[[ MsaNames.[i] ]] <- TempIn..$Population[ TempIn..$PopDensity > 1000 ]
		MsaAveDen.[ MsaNames.[i] ] <- sum( TempIn..$Population ) / sum( TempIn..$AreaSqMi )
		UbzAveDen.[ MsaNames.[i] ] <-
               sum( TempIn..$Population[ TempIn..$PopDensity > 1000 ] ) /
			sum( TempIn..$AreaSqMi[ TempIn..$PopDensity > 1000 ] )	
		rm( ObjName, TempIn.. )
	}

#Plot density distributions for selected urbanized areas
#=======================================================

#Define several functions for plotting density distributions
#-----------------------------------------------------------

	plotDensity <- function( Names., UbzDen_, Colors., ... ) {
		for( i in 1:length(Names.) ) {
			Data. <- UbzDen_[[Names.[i]]]                                         
			par( bg="gray" )
			if( i == 1 ) {
				plot( density( Data. ), col=Colors.[i], lwd=2, ... )
			} else {
				lines( density( Data. ), col=Colors.[i], lwd=2 )
			}
		}
		legend( "topright", legend=Names., col=Colors., lwd=2 )
	} 

	plotLogDensity <- function( Names., UbzDen_, Colors., ... ) {
		for( i in 1:length(Names.) ) {
			Data. <- log(UbzDen_[[Names.[i]]])
			par( bg="gray" )
			if( i == 1 ) {
				plot( density( Data. ), col=Colors.[i], lwd=2, ... )
			} else {
				lines( density( Data. ), col=Colors.[i], lwd=2 )
			}
		}
		legend( "topright", legend=Names., col=Colors., lwd=2 )
	}

	plotWeightDensity <- function( Names., UbzDen_, UbzPop_, Colors., ... ) {
		for( i in 1:length(Names.) ) {
			Data. <- UbzDen_[[Names.[i]]]
			Weights. <- UbzPop_[[Names.[i]]]
			Weights. <- Weights. / sum( Weights. )
			par( bg="gray" )
			if( i == 1 ) {
				plot( density( Data., weights=Weights. ), col=Colors.[i], lwd=2, ... )
			} else {
				lines( density( Data., weights=Weights. ), col=Colors.[i], lwd=2 )
			}
		}
		legend( "topright", legend=Names., col=Colors., lwd=2 )
	}

	plotWeightLogDensity <- function( Names., UbzDen_, UbzPop_, Colors., ... ) {
		for( i in 1:length(Names.) ) {
			Data. <- log( UbzDen_[[Names.[i]]] )
			Weights. <- UbzPop_[[Names.[i]]]
			Weights. <- Weights. / sum( Weights. )
			par( bg="gray" )
			if( i == 1 ) {
				plot( density( Data., weights=Weights. ), col=Colors.[i], lwd=2, ... )
			} else {
				lines( density( Data., weights=Weights. ), col=Colors.[i], lwd=2 )
			}
		}
		legend( "topright", legend=Names., col=Colors., lwd=2 )
	}

#Plot density distributions
#--------------------------

	Names. <- c( "Atlanta", "Nashville", "Medford", "Eugene", "Salem", "Portland",
		"SanFrancisco", "LosAngeles" )
	Colors. <- brewer.pal( 8, "Set1" )

	# Plot density distribution of census tracts in urbanized area on normal scale
	png( "documentation/pop_density_distributions.png", width=800, height=800 )
	par( cex=1.5 )
	plotDensity( Names., UbzDen_, Colors., ylab="Probability", xlab="Persons Per Square Mile", 
		main="Census Tract Density Distribution for Selected Urbanized Areas" )
	dev.off()

     # Plot density distribution of census tracts in urbanized area on log scale
	png( "documentation/pop_log_density_distributions.png", width=800, height=800 )
	par( cex=1.5 )
	plotLogDensity( Names., UbzDen_, Colors.,
          ylab="Probability", xlab="Persons Per Square Mile",
		main="Census Tract Log Density Distribution for Selected Urbanized Areas" )
	dev.off()

	# Plot population weighted density distribution of urbanized area census tracts on normal scale
	png( "documentation/wtd_pop_density_distributions.png", width=800, height=800 )
	par( cex=1.5 )
	plotWeightDensity( Names., UbzDen_, UbzPop_, Colors., ylab="Probability",
          xlab="Persons Per Square Mile",
		main="Population Weighted Density Distribution for Selected Urbanized Areas" )
	dev.off()

	# Plot population weighted density distribution of urbanized area census tracts on log scale
	png( "documentation/wtd_log_pop_density_distributions.png", width=800, height=800 )
	par( cex=1.5 )
	plotWeightLogDensity( Names., UbzDen_, UbzPop_, Colors., ylab="Probability",
          xlab="Persons Per Square Mile",
		main="Population Weighted Density Distribution for Selected Urbanized Areas" )
	dev.off()

#Produce a model for forecasting density distribution as a function of overall density
#=====================================================================================

#Notes:
#Earlier versions of the model used the urban area data as prototypes and interpolated between the prototypes. Data for the Atlanta, Portland, San Francisco and Los Angeles urbanized areas were used as the prototypes. Lower density prototypes were developed by shifting the Atlanta distribution leftward. Higher density prototypes were generated by shifting the Los Angeles distribution rightward. The data for other metropolitan areas was not used either because the urban areas are small (e.g. Salem, Eugene) or showed analmolous patterns (e.g. double-humped pattern for Nashville). This worked well for statewide application, but did not for metropolitan GreenSTEP because it would not predict high enough densities when applied to portions of the Portland metropolitan area that had high overall densities (e.g. downtown).
#The approach in this script is to normalize the log distribution of population density by the log of the average urbanized area population density. The resulting distributions of normalized density for the four prototype metropolitan areas are similar. An average normalized distribution is created from these prototypes and used as the template for predicting population distribution for any average population distribution.

#Define a function to calculate the harmonic mean
#------------------------------------------------

     harmonicMean <- function( Probs., Values. ) {
          1 / sum( Probs. / Values. )
          }

#Select only the data for the 4 urbanized areas
#----------------------------------------------

	UbzNames. <- c( "Portland", "LosAngeles", "SanFrancisco", "Atlanta", "Eugene", "Salem", "Medford" )
	UbzDen_ <- UbzDen_[ UbzNames. ]
	UbzPop_ <- UbzPop_[ UbzNames. ]
	UbzAveDen. <- UbzAveDen.[ UbzNames. ]

#Calculate and normalized distributions of the natural log of population density
#-------------------------------------------------------------------------------

#The distributions of census tract population density are approximately lognormal. The log density distributions are normalized by dividing by the natural log of overall urban area density. The resulting normalized distributions for the four urbanized areas are similar to one another.
	
	calcNormLogDen <- function( Den., Pop. ) {
		MeanDen <- harmonicMean( Pop./sum(Pop.), Den. )
		log( Den. )/log( MeanDen )
	}
	
	UbzNormLogDen_ <- mapply( calcNormLogDen, UbzDen_, UbzPop_ )

	calcMeanNormLogDen <- function( NormLogDen., Pop. ) {
		sum( NormLogDen. * Pop. ) / sum( Pop. )
	}
	
	MeanNormLogDen. <- mapply( calcMeanNormLogDen, UbzNormLogDen_, UbzPop_ )

	calcSdNormLogDen <- function( NormLogDen., Pop. ) {
		MeanNormLogDen <- sum( NormLogDen. * Pop. ) / sum( Pop. )
		SqDiff. <- ( NormLogDen. - MeanNormLogDen ) ^ 2
		SumSqDiff. <- sum( SqDiff. * Pop. )
		Num <- sum( Pop. )
		sqrt( SumSqDiff. / Num )
	}
	
	SdNormLogDen. <- mapply( calcSdNormLogDen, UbzNormLogDen_, UbzPop_ )				
		
#Plot the comparison
#-------------------

#The graphs show that the distributions of the normalized natural log of population density for the four urban areas are fairly similar and each can be approximated by normal distributions. The values for mean and sd for the Portland and Atlanta areas are very close to one another. (Portland: mean=1.02, sd=0.069; Atlanta: mean=1.02, sd=0.067) The mean values for the San Francisco and Los Angeles areas are close to one another and slightly higher than the Portland and Atlanta values. The sd values for those areas are substantially higher. (San Francisco: mean=1.04, sd=0.101; Los Angeles: mean=1.04, sd=0.088) It can be seen that a long left-hand tail for the San Francisco and Los Angeles distributions contributes to the much higher sd values and that the central portions of the distributions are similar to the Portland and Atlanta distributions.


	win.metafile( file="documentation/compare_norm_log_density.wmf", width=7, height=7 )
	par( mfrow=c( 3, 2 ), oma=c( 1, 1, 2, 1 ) )		
  # Plot Portland
  hist( rep( UbzNormLogDen_$Portland, UbzPop_$Portland ), freq=FALSE, xlim=c(0.8,1.4), ylim=c(0,6.5), xlab="Normalized Log of Population Density", main="Portland", cex.main=0.9 )
  lines( density( rnorm( 1000000, mean=MeanNormLogDen.["Portland"], sd=SdNormLogDen.["Portland"] ) ), col="red", lty=2 )
  text( 1.15, 5.5, paste( "mean = ", round( MeanNormLogDen.[ "Portland" ], 2 ) ), pos=4 )
	text( 1.15, 5, paste( "sd = ", round( SdNormLogDen.[ "Portland" ], 3 ) ), pos=4 )
  # Plot Atlanta  
  hist( rep( UbzNormLogDen_$Atlanta, UbzPop_$Atlanta ), freq=FALSE, xlim=c(0.8,1.4), ylim=c(0,6.5), xlab="Normalized Log of Population Density", main="Atlanta", cex.main=0.9  )
  lines( density( rnorm( 1000000, mean=MeanNormLogDen.["Atlanta"], sd=SdNormLogDen.["Atlanta"] ) ), col="red", lty=2 )
  text( 1.15, 5.5, paste( "mean = ", round( MeanNormLogDen.[ "Atlanta" ], 2 ) ), pos=4 )
	text( 1.15, 5, paste( "sd = ", round( SdNormLogDen.[ "Atlanta" ], 3 ) ), pos=4 )
  # Plot San Francisco
  hist( rep( UbzNormLogDen_$SanFrancisco, UbzPop_$SanFrancisco ), freq=FALSE, xlim=c(0.8,1.4), ylim=c(0,6.5), xlab="Normalized Log of Population Density", main="SanFrancisco", cex.main=0.9 )
  lines( density( rnorm( 1000000, mean=MeanNormLogDen.["SanFrancisco"], sd=SdNormLogDen.["SanFrancisco"] ) ), col="red", lty=2 )
  text( 1.15, 5.5, paste( "mean = ", round( MeanNormLogDen.[ "SanFrancisco" ], 2 ) ), pos=4 )
	text( 1.15, 5, paste( "sd = ", round( SdNormLogDen.[ "SanFrancisco" ], 3 ) ), pos=4 )
  hist( rep( UbzNormLogDen_$LosAngeles, UbzPop_$LosAngeles ), freq=FALSE, xlim=c(0.8,1.4), ylim=c(0,6.5), xlab="Normalized Log of Population Density", main="LosAngeles", cex.main=0.9  )
  lines( density( rnorm( 1000000, mean=MeanNormLogDen.["LosAngeles"], sd=SdNormLogDen.["LosAngeles"] ) ), col="red", lty=2 )
  text( 1.15, 5.5, paste( "mean = ", round( MeanNormLogDen.[ "LosAngeles" ], 2 ) ), pos=4 )
	text( 1.15, 5, paste( "sd = ", round( SdNormLogDen.[ "LosAngeles" ], 3 ) ), pos=4 )
	mtext( "Comparison of Normalized Population Density Distributions", side=3, outer=TRUE, line=0 )
  dev.off()

  # Make table to compare means and standardard deviations of log normalized census tract population densities
  MeanSdValues.2d <- cbind( Mean=MeanNormLogDen., SD=SdNormLogDen. )
  CompXtable <- xtable(MeanSdValues.2d, align=rep("l", 3),
                     digits=c( 0, 3, 4 ),
                     caption="Mean and Standard Deviation Values for Normalized Distributions" )
  print(CompXtable, type="html", file="documentation/density_means_sd.html",
      caption.placement="top", include.colnames=TRUE, include.rownames=TRUE)

  # Compare the normalized distributions
  MeanNormLogDen. <- c( MeanNormLogDen., Ave=mean( MeanNormLogDen. ) )
  SdNormLogDen. <- c( SdNormLogDen., Ave=mean( SdNormLogDen. ) )
  for( i in 1:length( MeanNormLogDen. ) ) {
      if( i == 1 ){
          plot( density( rnorm( 1000000, mean=MeanNormLogDen.[i], sd=SdNormLogDen.[i] ) ), col=i, lty=1 )
      } else {
          lines( density( rnorm( 1000000, mean=MeanNormLogDen.[i], sd=SdNormLogDen.[i] ) ), col=i, lty=1 )
      }
  }
  lines( density( rnorm( 1000000, mean=UbzDenModel_$Mean, sd=UbzDenModel_$Sd ) ), lty=2, lwd=2 )  
  legend( "topleft", lty=1, col=1:length( MeanNormLogDen. ), legend=names(MeanNormLogDen.) )

#Define a model to calculate a population density distribution from an overall metropolitan average 
#--------------------------------------------------------------------------------------------------

#The model for calculating the distribution of households by neighborhood population density uses the normalized distribution of the log of  population density illustrated in the previous set of graphs. As the graphs show, the distribution can be well described by a normal distribution using specified parameters for the mean and standard deviation. The average values for all four urbanized areas are used as the default values for this model.

     UbzDenModel_ <- list()
     UbzDenModel_$Mean <- 1.02 #mean( MeanNormLogDen. )
     UbzDenModel_$Sd <- 0.07 #mean( SdNormLogDen. )
     
#Compare modeled and observed distributions for metropolitan areas

UbzDen_ <- UbzDen_[ UbzNames. ]
UbzPop_ <- UbzPop_[ UbzNames. ]
UbzAveDen. <- UbzAveDen.[ UbzNames. ]

  densityModelTest <- function( ForecastDen, UbzDenModel_, MaxDenSd=3, MinDenSd=3 ) {
      
    # Calculate the density distribution
    #-----------------------------------
    # Create a distribution of normalized values using the model parameters
    Num <- 1e6
    NormLogDenDist. <- rnorm( Num, mean=UbzDenModel_$Mean, sd=UbzDenModel_$Sd )
    # Constrain the maximum and minimum density values according to the specified limit
    MaxVal <- UbzDenModel_$Mean + MaxDenSd * UbzDenModel_$Sd
    MinVal <- UbzDenModel_$Mean - MinDenSd * UbzDenModel_$Sd
    NormLogDenDist.[ NormLogDenDist. > MaxVal ] <- MaxVal
    NormLogDenDist.[ NormLogDenDist. < MinVal ] <- MinVal
    # Define initial lower and upper bounds for binary search to find the populated weighted average density
    LowerDenBnd <- ForecastDen / 4 
    UpperDenBnd <- ForecastDen * 4
    # Iterate to find the population weighted density that results in a match to the average density
    MidDen. <- numeric(0)
    AveDen. <- numeric(0)
    for( i in 1:100 ) {
      # Calculate midpoint between lower and upper bounds
      MidDen <- ( LowerDenBnd + UpperDenBnd ) / 2
      MidDen.[i] <- MidDen
      # Calculate the density distributions for the lower, upper and middle average density values
      DenDist. <- exp( NormLogDenDist. * log( MidDen ) )
      # Calculate overall density for middle value
      AveDen <- Num / sum( 1/DenDist. )
      AveDen.[i] <- AveDen
      # Break out of loop if AveDen is close to ForecastDen
      if( abs( ( AveDen - ForecastDen ) / ForecastDen ) < 0.001 ) break
      # Substitute the middle density for the upper or lower boundary depending on whether
      # the average density is greater or less than the forecast density
      if( AveDen < ForecastDen ) LowerDenBnd <- MidDen
      if( AveDen > ForecastDen ) UpperDenBnd <- MidDen
    }

    # Create a distribution of the normalized log of population density
    #------------------------------------------------------------------
  
    DenBreaks. <- seq( min( DenDist. ), max( DenDist. ), length=40 )
    DenCut. <- cut( DenDist., DenBreaks. )
    MidPoints. <- DenBreaks.[ - length( DenBreaks. ) ] + diff( DenBreaks. )
    DenProbs. <- as.vector( table( DenCut. ) ) / sum( table( DenCut. ) )

    # Adjust the population density distribution so that the forecast density is achieved
    #------------------------------------------------------------------------------------
    #AveDen <- harmonicMean( DenProbs., MidPoints. )
    #DenAdj <- ForecastDen / AveDen
    #MidPoints. <- MidPoints. * DenAdj
    Result_ <- list( DenProbs.=DenProbs., DenValues.=MidPoints., DenBreaks.=DenBreaks., DenDist.=DenDist., Iter=i )
    Result_

  }

# County test
  ObsAveDen.Ma <- numeric(0)
  ObsWtAveDen.Ma <- numeric(0)
  ObsHiDen.Ma <- numeric(0)
  ModWtAveDen.Ma <- numeric(0)
  ModAveDen.Ma <- numeric(0)
  ModHiDen.Ma <- numeric(0)
  ObsLoDen.Ma <- numeric(0)
  ModLoDen.Ma <- numeric(0)
  HiPercentile <- 0.75
  LoPercentile <- 0.25

# Test for Portland
  PortlandTest_ <- densityModelTest( ForecastDen=UbzAveDen.["Portland"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$Portland, freq=FALSE )
  lines( density( PortlandTest_$DenDist.), col="red")
  # Compare averages
  ObsAveDen.Ma["Portland"] <- UbzAveDen.["Portland"]
  ObsWtAveDen.Ma["Portland"] <- sum( UbzDen_$Portland * UbzPop_$Portland ) / sum( UbzPop_$Portland )
  ModAveDen.Ma["Portland"] <- length( PortlandTest_$DenDist. ) / sum( 1/PortlandTest_$DenDist. )
  ModWtAveDen.Ma["Portland"] <- mean( PortlandTest_$DenDist.)
  ObsHiDen.Ma["Portland"] <- quantile( UbzDen_$Portland, HiPercentile )
  ModHiDen.Ma["Portland"] <- quantile( PortlandTest_$DenDist., HiPercentile )
  ObsLoDen.Ma["Portland"] <- quantile( UbzDen_$Portland, LoPercentile )
  ModLoDen.Ma["Portland"] <- quantile( PortlandTest_$DenDist., LoPercentile )

  SalemTest_ <- densityModelTest( ForecastDen=UbzAveDen.["Salem"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$Salem, freq=FALSE )
  lines( density( SalemTest_$DenDist.), col="red")
  # Compare averages
  ObsAveDen.Ma["Salem"] <- UbzAveDen.["Salem"]
  ObsWtAveDen.Ma["Salem"] <- sum( UbzDen_$Salem * UbzPop_$Salem ) / sum( UbzPop_$Salem )
  ModAveDen.Ma["Salem"] <- length( SalemTest_$DenDist. ) / sum( 1/SalemTest_$DenDist. )
  ModWtAveDen.Ma["Salem"] <- mean( SalemTest_$DenDist.)
  ObsHiDen.Ma["Salem"] <- quantile( UbzDen_$Salem, HiPercentile )
  ModHiDen.Ma["Salem"] <- quantile( SalemTest_$DenDist., HiPercentile )
  ObsLoDen.Ma["Salem"] <- quantile( UbzDen_$Salem, LoPercentile )
  ModLoDen.Ma["Salem"] <- quantile( SalemTest_$DenDist., LoPercentile )

  EugeneTest_ <- densityModelTest( ForecastDen=UbzAveDen.["Eugene"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$Eugene, freq=FALSE )
  lines( density( EugeneTest_$DenDist.), col="red")
  # Compare averages
  ObsAveDen.Ma["Eugene"] <- UbzAveDen.["Eugene"]
  ObsWtAveDen.Ma["Eugene"] <- sum( UbzDen_$Eugene * UbzPop_$Eugene ) / sum( UbzPop_$Eugene )
  ModAveDen.Ma["Eugene"] <- length( EugeneTest_$DenDist. ) / sum( 1/EugeneTest_$DenDist. )
  ModWtAveDen.Ma["Eugene"] <- mean( EugeneTest_$DenDist.)
ObsHiDen.Ma["Eugene"] <- quantile( UbzDen_$Eugene, HiPercentile )
ModHiDen.Ma["Eugene"] <- quantile( EugeneTest_$DenDist., HiPercentile )
ObsLoDen.Ma["Eugene"] <- quantile( UbzDen_$Eugene, LoPercentile )
  ModLoDen.Ma["Eugene"] <- quantile( EugeneTest_$DenDist., LoPercentile )

  MedfordTest_ <- densityModelTest( UbzAveDen.["Medford"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$Medford, freq=FALSE )
  lines( density( MedfordTest_$DenDist.), col="red")
  # Compare averages
  ObsAveDen.Ma["Medford"] <- UbzAveDen.["Medford"]
  ObsWtAveDen.Ma["Medford"] <- sum( UbzDen_$Medford * UbzPop_$Medford ) / sum( UbzPop_$Medford )
  ModAveDen.Ma["Medford"] <- length( MedfordTest_$DenDist. ) / sum( 1/MedfordTest_$DenDist. )
  ModWtAveDen.Ma["Medford"] <- mean( MedfordTest_$DenDist.)
ObsHiDen.Ma["Medford"] <- quantile( UbzDen_$Medford, HiPercentile )
ModHiDen.Ma["Medford"] <- quantile( MedfordTest_$DenDist., HiPercentile )
ObsLoDen.Ma["Medford"] <- quantile( UbzDen_$Medford, LoPercentile )
ModLoDen.Ma["Medford"] <- quantile( MedfordTest_$DenDist., LoPercentile )

  DenDist_Ma <- list( UbzDen_$Portland, sample( PortlandTest_$DenDist., 1000 ),
                      UbzDen_$Eugene, sample( EugeneTest_$DenDist., 1000 ),
                      UbzDen_$Salem, sample( SalemTest_$DenDist., 1000 ),
                      UbzDen_$Medford, sample( MedfordTest_$DenDist., 1000 ))
  boxplot( DenDist_Ma )

# Portland data set identifying tract and county
PortlandTracts.. <- read.delim( "data/census/Portland.txt", sep="\t" )
PortlandTracts.. <- PortlandTracts..[ PortlandTracts..$PopDensity >= 1000, ]
Names. <- as.character( PortlandTracts..[,1] )
NamesSplit_ <- strsplit( Names., " ")
NamesSplit.. <- data.frame( do.call( rbind, NamesSplit_ ) )
head( NamesSplit.. )
PortlandTracts..$Tract <- NamesSplit..[,3]
PortlandTracts..$County <- NamesSplit..[,4]
rm( Names., NamesSplit_, NamesSplit.. )
# Split by County
PortlandTracts_Co.. <- split( PortlandTracts.., PortlandTracts..$County )
names( PortlandTracts_Co.. )
# Calculate the average density and population weighted average density by county
PortlandAveDen_Co. <- lapply( PortlandTracts_Co.., function(x) {
  AveDen <- sum( x$Population ) / sum( x$AreaSqMi )
  WtAveDen <- sum( x$Population * x$PopDen ) / sum( x$Population )
  HiDen <- quantile( x$PopDen, HiPercentile ); names( HiDen ) <- NULL
  LoDen <- quantile( x$PopDen, LoPercentile ); names( LoDen ) <- NULL
  c( AveDen=AveDen, WtAveDen=WtAveDen, HiDen=HiDen, LoDen=LoDen )
})
# Model the distribution by County
PortlandModelDen_Co. <- lapply( PortlandAveDen_Co., function(x) {
  densityModelTest( x["AveDen"], UbzDenModel_ )$DenDist.
})
# Calculate the Average Density and Population Weighted Average Density for the Model
PortlandModelAveDen_Co. <- lapply( PortlandModelDen_Co., function(x) {
  AveDen <- length(x)/sum(1/x)
  WtAveDen <- mean(x)
  HiDen <- quantile( x, HiPercentile ); names( HiDen ) <- NULL
  LoDen <- quantile( x, LoPercentile ); names( LoDen ) <- NULL
  c( AveDen=AveDen, WtAveDen=WtAveDen, HiDen=HiDen, LoDen=LoDen )
})
# Plot comparison of observed and modeled density distributions
Co <- names( PortlandModelDen_Co. )
par( mfrow=c(3,2) )
for( co in Co ){
  hist(PortlandTracts_Co..[[co]]$PopDensity, freq=FALSE, main=co )
  lines( density( PortlandModelDen_Co.[[co]]) )
}


win.metafile( file="documentation/compare_density.wmf", width=8, height=5)
par( mfrow=c(1,2) )
# Plot results of metropolitan area test
Ci <- c( "Medford", "Salem", "Portland", "Eugene" )
Colors. <- c( "brown", "blue", "red", "forestgreen")
plot( ObsWtAveDen.Ma[Ci], ModWtAveDen.Ma[Ci],
      xlim=c(1000,7000), ylim=c(1000,7000), xlab="Observed Density (persons/sq mi)",
      ylab="Modeled Density (persons/sq mi)", pch=1, col=Colors., lwd=2,
      main="Metropolitan Area Comparison")
points( ObsAveDen.Ma[Ci], ModAveDen.Ma[Ci], pch=2, col=Colors., lwd=2)
points( ObsLoDen.Ma[Ci], ModLoDen.Ma[Ci], pch=3, col=Colors., lwd=2)
points( ObsHiDen.Ma[Ci], ModHiDen.Ma[Ci], pch=4, col=Colors., lwd=2)
abline( 1, 1, lty=2 )
legend( "topleft", pch=c(20,20,20,20,2,1,3,4), col=c(Colors.,"grey30", "grey30", "grey30", "grey30"), 
        legend=c(Ci,"Ave. Density", "Weighted Ave. Density", "25th Percentile", "75th Percentile" ), 
        pt.lwd=2, cex=0.8, pt.cex=1, bty="n"  )


# Plot comparison of observed and modeled average density and weighted average density
Ci <- c( "Clark", "Clackamas", "Multnomah", "Washington" )
Colors. <- c( "brown", "blue", "red", "forestgreen")
plot( unlist( lapply( PortlandAveDen_Co.[Ci], function(x) x["WtAveDen"] ) ),
      unlist( lapply( PortlandModelAveDen_Co.[Ci], function(x) x["WtAveDen"] ) ),
      xlim=c(1000,8700), ylim=c(1000,8700), xlab="Observed Average Density (persons/sq mi)",
      ylab="Modeled Average Density (persons/sq mi)", pch=1, col=Colors., lwd=2,
      main="Portland Subarea Comparison")
points( unlist( lapply( PortlandAveDen_Co.[Ci], function(x) x["AveDen"] ) ),
        unlist( lapply( PortlandModelAveDen_Co.[Ci], function(x) x["AveDen"] ) ),
        pch=2, col=Colors., lwd=2)
points( unlist( lapply( PortlandAveDen_Co.[Ci], function(x) x["LoDen"] ) ),
        unlist( lapply( PortlandModelAveDen_Co.[Ci], function(x) x["LoDen"] ) ),
        pch=3, col=Colors., lwd=2)
points( unlist( lapply( PortlandAveDen_Co.[Ci], function(x) x["HiDen"] ) ),
        unlist( lapply( PortlandModelAveDen_Co.[Ci], function(x) x["HiDen"] ) ),
        pch=4, col=Colors., lwd=2)
abline( 1, 1, lty=2 )
legend( "topleft", pch=c(20,20,20,20,2,1,3,4), col=c(Colors.,"grey30", "grey30", "grey30", "grey30"), 
        legend=c(Ci,"Ave. Density", "Weighted Ave. Density", "25th Percentile", "75th Percentile" ), 
        pt.lwd=2, cex=0.8, pt.cex=1, bty="n"  )
dev.off()


AtlantaTest_ <- densityModelTest( UbzAveDen.["Atlanta"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$Atlanta, freq=FALSE )
  lines( density( AtlantaTest_$DenDist.), col="red")
  # Compare averages
  length( AtlantaTest_$DenDist. ) / sum( 1/AtlantaTest_$DenDist. )
  UbzAveDen.["Atlanta"]
  AtlantaTest_$Iter
summary( AtlantaTest_$DenDist. )
summary( UbzDen_$Atlanta)

  SanFranciscoTest_ <- densityModelTest( UbzAveDen.["SanFrancisco"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$SanFrancisco, freq=FALSE )
  plot( density( UbzDen_$SanFrancisco))
  lines( density( SanFranciscoTest_$DenDist.), col="red")
  # Compare averages
  length( SanFranciscoTest_$DenDist. ) / sum( 1/SanFranciscoTest_$DenDist. )
  UbzAveDen.["SanFrancisco"]
  SanFranciscoTest_$Iter
summary( SanFranciscoTest_$DenDist. )
summary( UbzDen_$SanFrancisco)

  LosAngelesTest_ <- densityModelTest( UbzAveDen.["LosAngeles"], UbzDenModel_ )
  # Compare distributions
  hist( UbzDen_$LosAngeles, freq=FALSE )
  plot( density( UbzDen_$LosAngeles))
  lines( density( LosAngelesTest_$DenDist.), col="red")
  # Compare averages
  length( LosAngelesTest_$DenDist. ) / sum( 1/LosAngelesTest_$DenDist. )
  UbzAveDen.["LosAngeles"]
  LosAngelesTest_$Iter
summary( LosAngelesTest_$DenDist. )
summary( UbzDen_$LosAngeles)


#Produce a model for forecasting whether household is located in "Urban" setting
#===============================================================================

#Notes:
#A simple model is estimated to predict the odds that a household is located in an "Urban" tract based on the population density of the tract.

#Estimate binomial logit model which predicts Urban based on overall MSA density and tract density
#-------------------------------------------------------------------------------------------------

     TestHh.. <- MetroHh..
	UrbanModel1 <- glm( Urban ~ Htppopdn,
		family=binomial, data=TestHh.. )
	rm( TestHh.. )
	summary( UrbanModel1 )
	
	#Write out the model summary
	sink( "documentation/urban_model_summary.txt", append=TRUE )
	cat( "URBAN MODEL SUMMARY\n" )
	summary( UrbanModel1 )
	sink()


#Extract the model coefficients for the chosen model
#---------------------------------------------------

	# Extract the model coefficients
	UrbanModelCoeff. <- coefficients( UrbanModel1 )
	# Make the model formula
	UrbanModel <- gsub( ":", " * ", names( UrbanModelCoeff. ) )
	UrbanModel[ 1 ] <- "Intercept"
	UrbanModel <- paste( UrbanModelCoeff., UrbanModel, sep=" * " )
	UrbanModel <- paste( UrbanModel, collapse= " + " )
	rm( UrbanModel1 )

#Save density/urban model and define a function to implement the model
#=====================================================================

#Save the model data
#-------------------

	# Add the Urban model to the UbzDenModel_
	UbzDenModel_ <- c( UbzDenModel_, UrbanModel=UrbanModel )
	# Save the model
     save( UbzDenModel_, file="model/UbzDenModel_.RData" )

#Define function to implement the density and urban model
#--------------------------------------------------------

#Notes:
#This function creates a probabilitiy distributions for census tract population density and urban probability by census tract population density.
#Function arguments are ForecastDen (the overall metropolitan area population density), UbzDenModel_ which is the list containing the density and urban model information, and a target proportion of population that is urban. 
#The function returns a list containing a vector of probabilities by density level, a vector of the average density corresponding to each density level, and vector of urban probabilities for each density level.
#The density model is run iteratively to create a distribution whose harmonic mean equals the forecast density for the area.
#The function applies the UrbanModel and a target proportion of households living in an "urban" setting to estimate a probability for each density level that a tract at that density is urban mixed-use development. The UrbanModel is a simple binomial logit model which is a function of population density. The UrbProp argument is used to establish a target for the proportion of households that reside in an urban mixed use setting. If this argument is not specified, the function will apply the UrbanModel with no adjustments. If the argument is specified the function will iteratively adjust the intercept of the UrbanModel until the overall proportion is within 1% of the specified target. If this 1% closure cannot be met within 100 iterations, the target will be adjusted upwards (if less than 0.5) or downwards (if greater than or equal to 0.5) until the 1% closure can be achieved within 100 iterations.

	predictDensityUrban <- function( ForecastDen, UbzDenModel_, UrbProp=NA ) {

		# Define a function to calculate a harmonic mean
		#-----------------------------------------------
		# This is used to adjust the density distribution so that the overall forecast density is achieved
     	harmonicMean <- function( Probs., Values. ) {
          	1 / sum( Probs. / Values. )
          }

		# Create a distribution of the normalized log of population density
		#------------------------------------------------------------------
		NormLogDenDist. <- rnorm( 1000000, mean=UbzDenModel_$Mean, sd=UbzDenModel_$Sd )
		# Don't let any values be greater than 4 standard deviations above the mean
		MaxVal <- UbzDenModel_$Mean + 4 * UbzDenModel_$Sd
		NormLogDenDist.[ NormLogDenDist. > MaxVal ] <- MaxVal
		# Create population density bins and calculate the midpoints and probabilities for each bin
		DenDist. <- exp( NormLogDenDist. * log( ForecastDen ) )
		DenBreaks. <- seq( min( DenDist. ), max( DenDist. ), length=40 )
		DenCut. <- cut( DenDist., DenBreaks. )
		MidPoints. <- DenBreaks.[ - length( DenBreaks. ) ] + diff( DenBreaks. )
		DenProbs. <- as.vector( table( DenCut. ) ) / sum( table( DenCut. ) )
			
		# Adjust the population density distribution so that the forecast density is achieved
		#------------------------------------------------------------------------------------
		AveDen <- harmonicMean( DenProbs., MidPoints. )
		DenAdj <- ForecastDen / AveDen
		MidPoints. <- MidPoints. * DenAdj
          Result_ <- list( DenProbs.=DenProbs., DenValues.=MidPoints., DenBreaks.=DenBreaks. )

          # Compute the urban probability
          #------------------------------
          Result_$UrbanProbs. <- 0
		UrbanData.. <- data.frame( list( Intercept=rep( 1, length( MidPoints. ) ),
			Htppopdn=MidPoints. ) )
		if( is.na( UrbProp ) ) {
		     # Evaluate model
	     	UrbanResults. <- eval( parse( text=UbzDenModel_$UrbanModel ),
				envir=UrbanData.. )
     		# Calculate odds and probabilities
			UrbanOdds. <- exp( UrbanResults. )
     		UrbanProbs. <- UrbanOdds. / (1 + UrbanOdds.)
          	# Add the Urban probabilities to the Result_
          	Result_$UrbanProbs. <- UrbanProbs.
          	i <- 1
		} else {
			Adj <- 1
			PropDiff <- 1
			while( PropDiff > 0.01 ) {
				for( i in 1:100 ) {
					UrbanData..$Intercept <- UrbanData..$Intercept * Adj
					# Evaluate model
	     			UrbanResults. <- eval( parse( text=UbzDenModel_$UrbanModel ),
						envir=UrbanData.. )
     				# Calculate odds and probabilities
					UrbanOdds. <- exp( UrbanResults. )
     				UrbanProbs. <- UrbanOdds. / (1 + UrbanOdds.)
     				# Calculate proportion urban
     				AveProp <- sum( Result_$DenProbs. * UrbanProbs. )
     				# Calculate proportional difference from the target
          			PropDiff <- abs( UrbProp - AveProp ) / UrbProp
          			# Exit if the overall urban probability is close to the target
					if( PropDiff < 0.01 ) break
          			# Recalculate the adjustment
          			Adj <- AveProp / UrbProp
  				}
  				if( UrbProp < 0.5 ) {
  					UrbProp <- UrbProp + 0.05
				} else {
					UrbProp <- UrbProp - 0.05
				}
          		# Add the Urban probabilities to the Result_
          		Result_$UrbanProbs. <- UrbanProbs.
			}
		}
		# Return the result
		Result_$Iter <- i
          Result_
      }

	 # Save the function
	 save( predictDensityUrban, file="model/predictDensityUrban.RData" )


#Test the models
#===============

#Test the density model
#----------------------

#The model predictions of population density distribution are compared to the census data for the Portland, Atlanta, San Francisco, and Los Angeles urbanized areas. 

	pdf( file="documentation/compare_density_model_with_census.pdf", width=7, height=7 )
	par( mfrow=c(2,2), oma=c(1,1,2,1) )
	# Plot Atlanta comparison
     AtlantaModel_ <- predictDensityUrban( UbzAveDen.["Atlanta"], UbzDenModel_ )
	AtlantaPopByDen. <- tapply( UbzPop_$Atlanta, cut( UbzDen_$Atlanta, breaks=AtlantaModel_$DenBreaks. ), sum )
	AtlantaPopByDen.[ is.na( AtlantaPopByDen. ) ] <- 0
	AtlantaPopPropByDen. <- AtlantaPopByDen. / sum( AtlantaPopByDen. )
     plot( AtlantaModel_$DenValues., AtlantaModel_$DenProbs., xlim=c(1000,12000), type="l", ylim=c(0,0.20),
		col="darkgreen", lty=1, lwd=2, xlab="Census Tract Population Density", ylab="Proportion of Population",
		main=paste( "Atlanta \n(", round( UbzAveDen.["Atlanta"] ), " Persons Per Square Mile)", sep="" ), cex.main=0.85 )
	lines( AtlantaModel_$DenValues., AtlantaPopPropByDen., col="purple", lty=2, lwd=2 )
	legend( "topright", legend=c( "Model", "Census" ), col=c( "darkgreen", "purple" ), lty=c(1,2), lwd=2 )
	# Plot Portland comparison 
     PortlandModel_ <- predictDensityUrban( UbzAveDen.["Portland"], UbzDenModel_ )
	PortlandPopByDen. <- tapply( UbzPop_$Portland, cut( UbzDen_$Portland, breaks=PortlandModel_$DenBreaks. ), sum )
	PortlandPopByDen.[ is.na( PortlandPopByDen. ) ] <- 0
	PortlandPopPropByDen. <- PortlandPopByDen. / sum( PortlandPopByDen. )
     plot( PortlandModel_$DenValues., PortlandModel_$DenProbs., type="l", xlim=c(1000,35000), ylim=c(0,0.20), 
		col="darkgreen", lty=1, lwd=2, xlab="Census Tract Population Density", ylab="Proportion of Population",
		main=paste( "Portland \n(", round( UbzAveDen.["Portland"] ), " Persons Per Square Mile)", sep="" ), cex.main=0.85 )
	lines( PortlandModel_$DenValues., PortlandPopPropByDen., col="purple", lty=2, lwd=2 )
	# Plot San Francisco comparison
     SanFranciscoModel_ <- predictDensityUrban( UbzAveDen.["SanFrancisco"], UbzDenModel_ )
	SanFranciscoPopByDen. <- tapply( UbzPop_$SanFrancisco, cut( UbzDen_$SanFrancisco, breaks=SanFranciscoModel_$DenBreaks. ), sum )
	SanFranciscoPopByDen.[ is.na( SanFranciscoPopByDen. ) ] <- 0
	SanFranciscoPopPropByDen. <- SanFranciscoPopByDen. / sum( SanFranciscoPopByDen. )
     plot( SanFranciscoModel_$DenValues., SanFranciscoModel_$DenProbs., type="l", xlim=c(1000,55000), ylim=c(0,0.20), 
		col="darkgreen", lty=1, lwd=2, xlab="Census Tract Population Density", ylab="Proportion of Population",
		main=paste( "SanFrancisco \n(", round( UbzAveDen.["SanFrancisco"] ), " Persons Per Square Mile)", sep="" ), cex.main=0.85 )
	lines( SanFranciscoModel_$DenValues., SanFranciscoPopPropByDen., col="purple", lty=2, lwd=2 )
	# Plot Los Angeles comparison
     LosAngelesModel_ <- predictDensityUrban( UbzAveDen.["LosAngeles"], UbzDenModel_ )
	LosAngelesPopByDen. <- tapply( UbzPop_$LosAngeles, cut( UbzDen_$LosAngeles, breaks=LosAngelesModel_$DenBreaks. ), sum )
	LosAngelesPopByDen.[ is.na( LosAngelesPopByDen. ) ] <- 0
	LosAngelesPopPropByDen. <- LosAngelesPopByDen. / sum( LosAngelesPopByDen. )
     plot( LosAngelesModel_$DenValues., LosAngelesModel_$DenProbs., type="l", xlim=c(1000,80000), ylim=c(0,0.20), 
		col="darkgreen", lty=1, lwd=2, xlab="Census Tract Population Density", ylab="Proportion of Population",
		main=paste( "LosAngeles \n(", round( UbzAveDen.["LosAngeles"] ), " Persons Per Square Mile)", sep="" ), cex.main=0.85 )
	lines( LosAngelesModel_$DenValues., LosAngelesPopPropByDen., col="purple", lty=2, lwd=2 )
	# Figure title
	mtext( "Comparison of Density Model with Census Density Distribution", outer=TRUE, side=3 )
	dev.off()
     
#Test the "Urban" model
#----------------------

#The Urban model is tested by applying it 30 times to the metropolitan household data and comparing the distribution of counts of urban households by metropolitan area to the survey counts. The model distributions by metropolitan area compare very well to the survey counts.

	# Calculate the urban probability for households in the survey
	Intercept <- 1
	UrbanResults. <- eval( parse( text=UbzDenModel_$UrbanModel ), envir=MetroHh.. )
	# Calculate odds and probabilities
	UrbanOdds. <- exp( UrbanResults. )
	UrbanProbs. <- UrbanOdds. / (1 + UrbanOdds.)
	
	# Make 50 urban designation predictions for metropolitan households
     UrbanHh.HhN <- matrix( 0, nrow=length( UrbanProbs. ), ncol=50 )
     for( i in 1:50 ) {
     	UrbanHh.HhN[,i] <- sapply( UrbanProbs., function(x) {
     		sample( c( 1, 0 ), size=1, replace=TRUE, prob=c( x, 1-x ) )
			} )
	} 
		
	# Sum the number of urban predictions by metropolitan area
	UrbanHh.MaN <- apply( UrbanHh.HhN, 2, function(x) {
	     tapply( x, MetroHh..$Hhc_msa, sum )
	     } )
	rownames( UrbanHh.MaN ) <- MsaNameCode.[ rownames( UrbanHh.MaN ) ]

 	# Calculate metropolitan area survey numbers
	SurveyUrban.Ma <- tapply( MetroHh..$Urban, MetroHh..$Hhc_msa, sum )

	# Plot comparison of estimated metropolitan area averages vs. observed
	png( "documentation/metroarea_urban_est_vs_obs.png", width=1000, height=600 )
     par( las=2, mar=c( 8, 4, 3, 2 ) )
     boxplot( data.frame( t( UrbanHh.MaN ) ), ylab="# Urban Households",
		main="Figure 9. Estimated vs. Survey Urban Households by Metropolitan Area\n30 Model Runs" )
     points( SurveyUrban.Ma, col="red", pch=16 )
     legend( "topright", legend="survey", col="red", pch=16 )
     dev.off()

#Test how well model matches the UrbanProp input
#-----------------------------------------------

	# Set up up a vectors of density and urban proportions
	Dn <- seq( 1000, 10000, 1000 )
	Up <- seq( 0.05, 1, 0.05 )
	UrbanIter.DnUp <- array( 0, dim=c( length( Dn ), length( Up ) ), dimnames=list( Dn, Up ) )
	
	# Define a function to run the test
	testUrban <- function( dn, UbzDenModel_, up ){
		DenUrbResult_ <- predictDensityUrban( dn, UbzDenModel_, UrbProp=up )
		sum( DenUrbResult_$DenProbs. * DenUrbResult_$UrbanProbs. )
	}
	
	for( dn in Dn ){
		for( up in Up ) {
			UrbanIter.DnUp[as.character(dn),as.character(up)] <- testUrban( dn, UbzDenModel_, up )
		}
	}

     CompXtable <- xtable(round(UrbanIter.DnUp,2), align=c("l", rep( "r", ncol( UrbanIter.DnUp ) ) ),
          digits=c( 0, rep( 2, ncol( UrbanIter.DnUp ) ) ),
          caption="Test of Urban Proportions" )
     print(CompXtable, type="html", file="documentation/urban_proportions_test.html",
          caption.placement="top", include.colnames=TRUE, include.rownames=TRUE)

#Test the model over a range of input densities
#----------------------------------------------

	DensityTest_ <- list()
	for( dn in seq( 1000, 30000, 2000 ) ) {
		DensityTest_[[as.character(dn)]] <- predictDensityUrban( dn, UbzDenModel_ )
	}
	plot( 0, 0, xlim=c(0,200000), ylim=c(0,0.3), type="n" )
	for( dn in seq( 1000, 30000, 1000 ) ){
		Name <- as.character( dn )
		lines( DensityTest_[[Name]]$DenValues, DensityTest_[[Name]]$DenProbs., col="grey" )
	}
	lines( DensityTest_[["1000"]]$DenValues, DensityTest_[["1000"]]$DenProbs. )
	lines( DensityTest_[["11000"]]$DenValues, DensityTest_[["11000"]]$DenProbs., col="red" )
	lapply( DensityTest_, function(x) sum( x$DenProbs. ) )
			