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
#zip -rq rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.zip ${BUILD_TARGERT}
#expect ${SCRIPT_DIR}/ci/scp.exp frs.sourceforge.net kl222,rabbitthirdlibrary ${PASSWORD} rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.zip pfs/Release/.
tar czf rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.tar.gz ${BUILD_TARGERT}_${RABBIT_ARCH}
md5sum rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.tar.gz
expect ${SCRIPT_DIR}/ci/scp.exp frs.sourceforge.net kl222,rabbitthirdlibrary ${PASSWORD} rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.tar.gz pfs/Release/.

if [ -n "${BUILD_END}" ]; then
    expect ${SCRIPT_DIR}/ci/scp.exp frs.sourceforge.net kl222,rabbitthirdlibrary ${PASSWORD} rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}_v${BUILD_VERSION}.tar.gz pfs/rabbit_${BUILD_TARGERT}${TOOLCHAIN_VERSION}_${RABBIT_ARCH}_${QT_VERSION}.tar.gz    
fi
