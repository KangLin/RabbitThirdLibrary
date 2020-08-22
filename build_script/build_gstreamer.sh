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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/gstreamer
fi

CUR_DIR=`pwd`
#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=1.16.2
    
    echo "git clone -q https://github.com/GStreamer/gst-build.git ${RABBIT_BUILD_SOURCE_CODE}"
    if [ "$VERSION" = "master" ]; then
        git clone -q https://github.com/GStreamer/gst-build.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        git clone -b ${VERSION} https://github.com/GStreamer/gst-build.git ${RABBIT_BUILD_SOURCE_CODE}
    fi
    
fi

cd ${RABBIT_BUILD_SOURCE_CODE}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr build_${BUILD_TARGERT}
    git clean -xdf
fi

echo ""
echo "==== BUILD_TARGERT:${BUILD_TARGERT}"
echo "==== RABBIT_BUILD_SOURCE_CODE:$RABBIT_BUILD_SOURCE_CODE"
echo "==== CUR_DIR:`pwd`"
echo "==== RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "==== RABBIT_BUILD_HOST:$RABBIT_BUILD_HOST"
echo "==== RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "==== RABBIT_BUILD_CROSS_PREFIX:$RABBIT_BUILD_CROSS_PREFIX"
echo "==== RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "==== RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo "==== BUILD_JOB_PARA:${BUILD_JOB_PARA}"
echo ""

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。

MAKE_PARA="-- ${BUILD_JOB_PARA}"
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
    windows_msvc)
        MAKE_PARA=""
        ;;
    windows_mingw)
        CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-mingw.cmake"
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

if [ "$RABBIT_CONFIG" = "Release" ]; then
    PARA="${PARA} --buildtype=release --strip"
else
    PARA="${PARA} --buildtype=debug"
fi
PARA="${PARA} -Dexamples=disabled -Dgst-examples=disabled -Dtests=disabled"
echo "meson --prefix=${RABBIT_BUILD_PREFIX} --libdir=lib ${PARA} build_${BUILD_TARGERT}"
meson --prefix=${RABBIT_BUILD_PREFIX} --libdir=lib ${PARA} build_${BUILD_TARGERT}
echo "meson compile ${BUILD_JOB_PARA} -C build_${BUILD_TARGERT}"
meson compile -C build_${BUILD_TARGERT} --verbose
echo "meson install -C build_${BUILD_TARGERT}"
meson install -C build_${BUILD_TARGERT} 

cd $CUR_DIR
