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

if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libsodium
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    LIBSODIUM_VERSION=1.0.12
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q  -b ${LIBSODIUM_VERSION} https://github.com/jedisct1/libsodium.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q  -b ${LIBSODIUM_VERSION} https://github.com/jedisct1/libsodium.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q https://github.com/jedisct1/libsodium/archive/${LIBSODIUM_VERSION}.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -c -q https://github.com/jedisct1/libsodium/archive/${LIBSODIUM_VERSION}.zip
        unzip -q ${LIBSODIUM_VERSION}.zip
        mv libsodium-${LIBSODIUM_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f libsodium-${LIBSODIUM_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
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
    android)
        export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
        export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        CONFIG_PARA="CC=${RABBIT_BUILD_CROSS_PREFIX}gcc --disable-shared -enable-static --host=$RABBIT_BUILD_CROSS_HOST"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
    ;;
    unix)
        ;;
    windows_msvc)
        if [ "$GENERATORS" = "Visual Studio 12 2013" ]; then
           msbuild.exe -m -v:n -p:Configuration=DynRelease -p:Platform=Win32 builds/msvc/vs2013/libsodium.sln
           cp bin/Win32/Release/v120/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
           cp bin/Win32/Release/v120/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
        fi
        if [ "$GENERATORS" = "Visual Studio 14 2015" ]; then
           msbuild.exe -m -v:n -p:Configuration=DynRelease -p:Platform=Win32 builds/msvc/vs2015/libsodium.sln
           cp bin/Win32/Release/v140/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
           cp bin/Win32/Release/v140/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
        fi
        echo "cp -fr src/libsodium/include/* $RABBIT_BUILD_PREFIX"
        cp -fr src/libsodium/include/* $RABBIT_BUILD_PREFIX/include
        cd $CUR_DIR
        exit 0
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
                export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
                export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
                export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
                export AS=${RABBIT_BUILD_CROSS_PREFIX}as
                export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
                export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
                CONFIG_PARA="${CONFIG_PARA} CC=${RABBIT_BUILD_CROSS_PREFIX}gcc"
                CONFIG_PARA="${CONFIG_PARA} --host=${RABBIT_BUILD_CROSS_HOST}"
                ;;
            *)
            ;;
        esac
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 3
    ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make ${RABBIT_MAKE_JOB_PARA} VERBOSE=1 
make install

cd $CUR_DIR
