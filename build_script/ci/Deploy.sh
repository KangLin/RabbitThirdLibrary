#!/bin/bash

set -e

#分发包到sourceforge.net  

SOURCE_DIR=`pwd`
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi

SCRIPT_DIR=${SOURCE_DIR}/build_script
if [ -d ${SOURCE_DIR}/ThirdLibrary/build_script ]; then
    SCRIPT_DIR=${SOURCE_DIR}/ThirdLibrary/build_script
fi

cd ${SOURCE_DIR}
zip -rq rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${AUTOBUILD_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.zip ${BUILD_TARGERT}
expect ${SCRIPT_DIR}/ci/scp.exp frs.sourceforge.net kl222,rabbitthirdlibrary ${PASSWORD} rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${AUTOBUILD_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.zip pfs/Release/.
