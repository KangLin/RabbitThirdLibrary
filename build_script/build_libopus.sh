#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBIT_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libopus
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    LIBOPUS_VERSION=1.2.1
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q -b v${LIBOPUS_VERSION} git://git.opus-codec.org/opus.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone  -q -b v${LIBOPUS_VERSION} git://git.opus-codec.org/opus.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q  https://archive.mozilla.org/pub/opus/opus-${LIBOPUS_VERSION}.tar.gz"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://archive.mozilla.org/pub/opus/opus-${LIBOPUS_VERSION}.tar.gz
        tar xzf opus-${LIBOPUS_VERSION}.tar.gz
        mv opus-${LIBOPUS_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f opus-${LIBOPUS_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

if [ "${RABBIT_BUILD_TARGERT}" != "windows_msvc" ]; then
    if [ ! -f configure ]; then
        echo "sh autogen.sh"
        sh autogen.sh
    fi
    
    mkdir -p build_${RABBIT_BUILD_TARGERT}
    cd build_${RABBIT_BUILD_TARGERT}
    if [ "$RABBIT_CLEAN" = "TRUE" ]; then
        rm -fr *
    fi
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
echo "RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo ""

echo "configure ..."

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBIT_BUILD_TARGERT} in
    android|windows_mingw)
        #export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        #export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        #export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
        #export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        #export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        #export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        #export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        #CONFIG_PARA="CC=${RABBIT_BUILD_CROSS_PREFIX}gcc LD=${RABBIT_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
        #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        LDFLAGS="${RABBIT_LDFLAGS}"
    ;;
    unix)
        ;;
    windows_msvc)
        if [  "$RABBIT_TOOLCHAIN_VERSION" -ge "14" ]; then
            if [ "$RABBIT_ARCH" = "x64" ]; then
                ARCH=x64
            else
                ARCH=Win32
            fi
            msbuild.exe -m -v:n -p:Configuration=Release -p:Platform=$ARCH win32/VS2015/opus.sln
            cp win32/VS2015/$ARCH/Release/opus.lib $RABBIT_BUILD_PREFIX/lib
        else
            echo "Don't support $RABBITIM_GENERATORS"
        fi
        cp include/* $RABBIT_BUILD_PREFIX/include
        cd $CUR_DIR
        exit 0
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 3
    ;;
esac

CFLAGS="${CFLAGS} -I$RABBIT_BUILD_PREFIX/include"
LDFLAGS="${LDFLAGS} -L$RABBIT_BUILD_PREFIX/lib"
CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\""
../configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}"

echo "make install"
make ${RABBIT_MAKE_JOB_PARA} VERBOSE=1 
make install

cd $CUR_DIR
