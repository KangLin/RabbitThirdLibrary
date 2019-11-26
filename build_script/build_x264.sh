#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/x264
fi

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    X264_VERSION=stable
    echo "git clone -q git://git.videolan.org/x264.git ${RABBIT_BUILD_SOURCE_CODE}"
    #git clone -q git://git.videolan.org/x264.git ${RABBIT_BUILD_SOURCE_CODE}
    git clone -q -b ${X264_VERSION} git://git.videolan.org/x264.git ${RABBIT_BUILD_SOURCE_CODE}
fi

CUR_DIR=`pwd`
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
echo ""

if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    if [ -d ".git" ]; then
        git clean -xdf
    else
        make distclean
    fi
fi

echo "configure ..."
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--enable-shared --disable-static"
fi
case ${BUILD_TARGERT} in
    android)
        CONFIG_PARA="${CONFIG_PARA} --cross-prefix=${RABBIT_BUILD_CROSS_PREFIX} --enable-static --host=$RABBIT_BUILD_CROSS_HOST"
        CONFIG_PARA="${CONFIG_PARA} --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        if [ "x86" = "${BUILD_ARCH}" -o "x86_64" = "${BUILD_ARCH}" ]; then
            CONFIG_PARA="${CONFIG_PARA} --disable-asm"
        fi
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        ASFLAGS="${RABBIT_CFLAGS}"
        LDFLAGS="${RABBIT_LDFLAGS}"
        ;;
    unix)
    ;;
    windows_msvc)
        cd $CUR_DIR
        exit 0
        export MSYSTEM=MINGW32
        export CC=cl
    ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                CONFIG_PARA="${CONFIG_PARA} --cross-prefix=${RABBIT_BUILD_CROSS_PREFIX} --host=$RABBIT_BUILD_CROSS_HOST"
                ;;
            MSYS*|MINGW*)
                CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
                ;;
        *)
            ;;
        esac
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 2
        ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX --disable-cli --disable-opencl --enable-pic "

echo "./configure ${CONFIG_PARA} --extra-cflags=\"${CFLAGS}\" --extra-asflags=\"${ASFLAGS}\""
if [ -n "$ASFLAGS" ]; then
    ./configure ${CONFIG_PARA} --extra-cflags="${CFLAGS}" --extra-asflags="${ASFLAGS}"
else
    ./configure ${CONFIG_PARA} --extra-cflags="${CFLAGS}" 
fi

echo "make install"
make ${BUILD_JOB_PARA} 
make install

cd $CUR_DIR
