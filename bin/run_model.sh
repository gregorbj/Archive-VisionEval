cd $FOLDER
if ( [ $TYPE == "model" ] ); then  Rscript -e "tryCatch( source( '$SCRIPT' ) )"; fi