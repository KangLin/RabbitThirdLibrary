#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix)
#   RABBIT_BUILD_PREFIX=`pwd`/../${BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_SOURCE_CODE    #源码目录
#   RABBIT_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM(android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

RABBIT_BUILD_SOURCE_CODE=$2
echo ". `pwd`/build_envsetup_${BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${BUILD_TARGERT}.sh

if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libpng
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=1.6.37
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=v${VERSION} https://github.com/glennrp/libpng.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=v$VERSION https://github.com/glennrp/libpng.git ${RABBIT_BUILD_SOURCE_CODE}
        #echo "git clone -q --branch=v$VERSION https://git.code.sf.net/p/libpng/code ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q --branch=v$VERSION https://git.code.sf.net/p/libpng/code ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -nv -c https://github.com/glennrp/libpng/archive/v${VERSION}.zip"
        wget -nv -c https://github.com/glennrp/libpng/archive/v${VERSION}.zip
        unzip -q v${VERSION}.zip
        mv libpng-${VERSION} ..
        rm -fr v${VERSION}.zip ${RABBIT_BUILD_SOURCE_CODE}
        cd ..
        mv libpng-${VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

echo ""
echo "BUILD_TARGERT:${BUILD_TARGERT}"
echo "RABBIT_BUILD_SOURCE_CODE:$RABBIT_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "RABBIT_BUILD_HOST:$RABBIT_BUILD_HOST"
echo "RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "RABBIT_BUILD_CROSS_PREFIX:$RABBIT_BUILD_CROSS_PREFIX"
echo "RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo "PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo ""

if [ ! -f configure ]; then
    echo "sh autogen.sh"
    sh autogen.sh
else
    if [ -f Makefile ]; then
        make distclean
    fi
fi

mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CMAKE_PARA="${CMAKE_PARA} -DPNG_STATIC=ON -DPNG_SHARED=OFF"
else
    CMAKE_PARA="${CMAKE_PARA} -DPNG_STATIC=OFF -DPNG_SHARED=ON"
fi
case ${BUILD_TARGERT} in
    android)
        if [ -n "$RABBIT_CMAKE_MAKE_PROGRAM" ]; then
            CMAKE_PARA="${CMAKE_PARA} -DCMAKE_MAKE_PROGRAM=$RABBIT_CMAKE_MAKE_PROGRAM" 
        fi
        if [ -n "$ANDROID_ARM_NEON" ]; then
            CMAKE_PARA="${CMAKE_PARA} -DANDROID_ARM_NEON=$ANDROID_ARM_NEON"
        fi
        CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_PLATFORM=${ANDROID_PLATFORM}"
        ;;   
    unix)
        ;;
    windows_mingw)
        CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-mingw.cmake"
        ;;
    windows_msvc)
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

CMAKE_PARA="${CMAKE_PARA} -DPNG_HARDWARE_OPTIMIZATIONS=ON"
CMAKE_PARA="${CMAKE_PARA} -DZLIB_ROOT=$RABBIT_BUILD_PREFIX"
echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} -G\"${GENERATORS}\" ${CMAKE_PARA} -DANDROID_ABI=\"${ANDROID_ABI}\""
if [ "${BUILD_TARGERT}" = "android" ]; then
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
        -DCMAKE_VERBOSE_MAKEFILE=OFF -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${GENERATORS}" ${CMAKE_PARA} -DANDROID_ABI="${ANDROID_ABI}"
else
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
        -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${GENERATORS}" ${CMAKE_PARA}
fi
cmake --build . --config ${RABBIT_CONFIG} ${MAKE_PARA}
cmake --build . --config ${RABBIT_CONFIG}  --target install ${MAKE_PARA}

cd $CUR_DIR
