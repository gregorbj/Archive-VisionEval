#install framework
cd sources/framework/visioneval
Rscript -e 'devtools::install_deps(".")'
R CMD INSTALL .
cd ../../..