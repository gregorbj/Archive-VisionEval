cd $FOLDER
if ( [ $TYPE == "module" ] ); then  Rscript -e "tryCatch( source( '$SCRIPT' ) )"; fi