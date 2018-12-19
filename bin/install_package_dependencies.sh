# Install the dependencies for the package
cd $FOLDER
if ( [ $TYPE == "module" ] ); then  Rscript -e 'devtools::install_deps(".")'; fi