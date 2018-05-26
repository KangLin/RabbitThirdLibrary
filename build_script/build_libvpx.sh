#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBIT_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix)
#   RABBIT_BUILD_PREFIX=`pwd`/../${RABBIT_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_SOURCE_CODE    #源码目录
#   RABBIT_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM(android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
        RABBIT_BUILD_TARGERT=$1
        ;;
    *)
        echo "${HELP_STRING}"
        exit 1
        ;;
esac

RABBIT_BUILD_SOURCE_CODE=$2
echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh

if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libvpx
fi

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=v1.7.0 #8446af7e9a12c5725e845564f40272dd9185c1cc
    echo "git clone -q --branch=$VERSION https://chromium.googlesource.com/webm/libvpx ${RABBIT_BUILD_SOURCE_CODE}"
    #git clone -q --branch=$VERSION https://chromium.googlesource.com/webm/libvpx ${RABBIT_BUILD_SOURCE_CODE}
    git clone -q https://chromium.googlesource.com/webm/libvpx ${RABBIT_BUILD_SOURCE_CODE}
    cd ${RABBIT_BUILD_SOURCE_CODE}
    if [ "$VERSION" != "master" ]; then
        git checkout -b $VERSION $VERSION
    fi
fi

CUR_DIR=`pwd`
cd ${RABBIT_BUILD_SOURCE_CODE}

mkdir -p build_${RABBIT_BUILD_TARGERT}
cd build_${RABBIT_BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

echo ""
echo "RABBIT_BUILD_TARGERT:${RABBIT_BUILD_TARGERT}"
echo "RABBIT_BUILD_SOURCE_CODE:$RABBIT_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "RABBIT_BUILD_HOST:$RABBIT_BUILD_HOST"
echo "RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "RABBIT_BUILD_CROSS_PREFIX:$RABBIT_BUILD_CROSS_PREFIX"
echo "RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo ""

echo "configure ..."
case ${RABBIT_BUILD_TARGERT} in
    android)
        export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc
        export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        export AR=${RABBIT_BUILD_CROSS_PREFIX}gcc-ar
        export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        export CROSS=${RABBIT_BUILD_CROSS_PREFIX}
        CONFIG_PARA="--sdk-path=${ANDROID_NDK_ROOT}"
        case ${RABBIT_ARCH} in 
            arm)
                CONFIG_PARA="${CONFIG_PARA} --target=armv7-android-gcc"
                ;;
            x86*|arm64*)
                CONFIG_PARA="${CONFIG_PARA} --as=auto --target=${RABBIT_ARCH}-android-gcc"
                ;;
            *)
                echo "Don't support target ${RABBIT_ARCH}"
                exit 0
            ;;
        esac

        export CFLAGS="${RABBIT_CFLAGS}"
        export CPPFLAGS="${RABBIT_CPPFLAGS}"
        export LDFLAGS="${RABBIT_LDFLAGS}"

        #编译 cpufeatures
        echo "${RABBIT_BUILD_CROSS_PREFIX}gcc -I${ANDROID_NDK_ROOT}/sysroot/usr/include/${RABBIT_BUILD_CROSS_HOST} -c ${ANDROID_NDK_ROOT}/sources/android/cpufeatures/cpu-features.c"
        ${RABBIT_BUILD_CROSS_PREFIX}gcc -I${ANDROID_NDK_ROOT}/sysroot/usr/include/${RABBIT_BUILD_CROSS_HOST} -c ${ANDROID_NDK_ROOT}/sources/android/cpufeatures/cpu-features.c
        ${RABBIT_BUILD_CROSS_PREFIX}ar rcs  libcpu-features.a cpu-features.o
        cp libcpu-features.a ${RABBIT_BUILD_PREFIX}/lib/.
        ;;
    unix)
        if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
            CONFIG_PARA="--enable-static --disable-shared"
        else
            CONFIG_PARA="--disable-static --enable-shared"
        fi
        ;;
    windows_msvc)
        if [ "$RABBIT_ARCH" = "x64" ]; then
            ARCH="x86_64-win64"
        else
            ARCH="x86-win32"
        fi
        CONFIG_PARA="--target=$ARCH-vs${VC_TOOLCHAIN} --enable-static-msvcrt"
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
                export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
                export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
                export LD=${RABBIT_BUILD_CROSS_PREFIX}gcc
                export AS=yasm
                export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
                export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
                
                #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
                CFLAGS="${RABBIT_CFLAGS}"
                CPPFLAGS="${RABBIT_CPPFLAGS}"
                LDFLAGS="${RABBIT_LDFLAGS}"
                ;;
            *)
            ;;
        esac
        CONFIG_PARA=" --target=x86-win32-gcc"
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 2
        ;;
esac

CONFIG_PARA="${CONFIG_PARA} --enable-libs --prefix=$RABBIT_BUILD_PREFIX"
CONFIG_PARA="${CONFIG_PARA} --disable-docs --disable-examples --disable-install-docs"
CONFIG_PARA="${CONFIG_PARA} --disable-install-bins --enable-install-libs"
CONFIG_PARA="${CONFIG_PARA} --disable-unit-tests --disable-debug --disable-debug-libs"
echo "../configure ${CONFIG_PARA} --extra-cflags=\"${CFLAGS=}\""
../configure ${CONFIG_PARA} --extra-cflags="${CFLAGS}" --extra-cxxflags="${CPPFLAGS}"
   
echo "make install"
make ${RABBIT_MAKE_JOB_PARA} 
make install

if [ "${RABBIT_BUILD_TARGERT}" = "windows_msvc" ]; then
    if [ "$RABBIT_ARCH" = "x64" ]; then
        cp ${RABBIT_BUILD_PREFIX}/lib/x64/vpxmt.lib ${RABBIT_BUILD_PREFIX}/lib/vpx.lib
        rm -fr ${RABBIT_BUILD_PREFIX}/lib/x64    
    else
        cp ${RABBIT_BUILD_PREFIX}/lib/Win32/vpxmt.lib ${RABBIT_BUILD_PREFIX}/lib/vpx.lib
        rm -fr ${RABBIT_BUILD_PREFIX}/lib/Win32
    fi
fi

cd $CUR_DIR
