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
tar czf rabbit_$(BUILD_TARGERT)$(RABBIT_TOOLCHAIN_VERSION)_$(RABBIT_ARCH)_qt$(QT_VERSION)_$(RABBIT_CONFIG)_v${BUILD_VERSION}.tar.gz $(BUILD_TARGERT)$(RABBIT_TOOLCHAIN_VERSION)_$(RABBIT_ARCH)_qt$(QT_VERSION)_$(RABBIT_CONFIG)
#md5sum rabbit_$(BUILD_TARGERT)$(RABBIT_TOOLCHAIN_VERSION)_$(RABBIT_ARCH)_qt$(QT_VERSION)_$(RABBIT_CONFIG)_v${BUILD_VERSION}.tar.gz
expect ${SCRIPT_DIR}/ci/scp.exp frs.sourceforge.net kl222,rabbitthirdlibrary ${PASSWORD} rabbit_$(BUILD_TARGERT)$(RABBIT_TOOLCHAIN_VERSION)_$(RABBIT_ARCH)_qt$(QT_VERSION)_$(RABBIT_CONFIG)_v${BUILD_VERSION}.tar.gz  pfs/Release/.

if [ -n "${BUILD_END}" ]; then
    expect ${SCRIPT_DIR}/ci/scp.exp frs.sourceforge.net kl222,rabbitthirdlibrary ${PASSWORD} rabbit_$(BUILD_TARGERT)$(RABBIT_TOOLCHAIN_VERSION)_$(RABBIT_ARCH)_qt$(QT_VERSION)_$(RABBIT_CONFIG)_v${BUILD_VERSION}.tar.gz  pfs/rabbit_$(BUILD_TARGERT)$(RABBIT_TOOLCHAIN_VERSION)_$(RABBIT_ARCH)_qt$(QT_VERSION)_$(RABBIT_CONFIG)_v${BUILD_VERSION}.tar.gz 
