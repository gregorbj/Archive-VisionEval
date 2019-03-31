#! /bin/bash
set -ev

BUILD_LIB=${VE_LIBRARY:-$TRAVIS_BUILD_DIR/ve-lib}
[ -d ${BUILD_LIB} ] || mkdir -p ${BUILD_LIB}

if [ -n "${BUILD_LIB}" ]
then
  export R_LIBS_USER=${BUILD_LIB}:${R_LIBS_USER}
fi

MODEL_DIR=$(dirname $1)
MODEL_DIR=${MODEL_DIR:-.}

pushd ${MODEL_DIR}
Rscript -e "tryCatch( source('$(basename $1)') )"
popd
