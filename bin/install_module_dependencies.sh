# Install modules the package is dependent on
IFS=',' read -r -a packages <<< $DEPENDS
for element in ${packages[@]}
do
  if ( [ $element != "." ] ); then
	cd sources/modules/$element
	Rscript -e 'devtools::install_deps(".")'
	Rscript -e 'devtools::document()'
	R CMD INSTALL .
	cd ../../..
  fi
done