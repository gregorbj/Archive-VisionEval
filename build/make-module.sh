#!/bin/bash
set -ev

BUILD_LIB=${VE_LIBRARY:-$TRAVIS_BUILD_DIR/ve-lib}
[ -d ${BUILD_LIB} ] || mkdir -p ${BUILD_LIB}

if [ -n "${BUILD_LIB}" ]
then
  export R_LIBS_USER=${BUILD_LIB}:${R_LIBS_USER}
fi

echo Operating in $(pwd)
pushd $1
TEST_SCRIPT=${2:-${VE_SCRIPT:-tests/scripts/test.R}}
echo TEST_SCRIPT=${TEST_SCRIPT}
Rscript -e "devtools::check('.')"
echo Executing ${TEST_SCRIPT} in $(pwd)
Rscript -e "tryCatch( source('${TEST_SCRIPT}') )"
echo Installing to ${BUILD_LIB}
R CMD INSTALL -l "${BUILD_LIB}" . # Save the installed package for later use
popd
