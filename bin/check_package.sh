cd $FOLDER
if ( [ $TYPE == "module" ] ); then  Rscript -e 'devtools::check(".")'; fi