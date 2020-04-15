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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libsodium
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    LIBSODIUM_VERSION=1.0.18
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q https://github.com/jedisct1/libsodium.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/jedisct1/libsodium.git ${RABBIT_BUILD_SOURCE_CODE}
        #echo "git clone -q https://github.com/KangLin/libsodium.git ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q https://github.com/KangLin/libsodium.git ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        if [ "$LIBSODIUM_VERSION" != "master" ]; then
            git checkout -b $LIBSODIUM_VERSION $LIBSODIUM_VERSION
        fi
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -q https://github.com/jedisct1/libsodium/archive/${LIBSODIUM_VERSION}.zip"
        wget -c -q https://github.com/jedisct1/libsodium/archive/${LIBSODIUM_VERSION}.zip
        #echo "wget -c -q https://github.com/KangLin/libsodium/archive/${LIBSODIUM_VERSION}.zip"
        #wget -c -q https://github.com/KangLin/libsodium/archive/${LIBSODIUM_VERSION}.zip
        unzip -q ${LIBSODIUM_VERSION}.zip
        mv libsodium-${LIBSODIUM_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f libsodium-${LIBSODIUM_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    if [ "${BUILD_TARGERT}" != "windows_msvc" ]; then
        if [ -d ".git" ]; then
            git clean -xdf
        fi
    fi 
fi
if [ ! -f configure ]; then
    echo "sh autogen.sh"
    sh autogen.sh
fi

mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
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
echo "==== PATH:$PATH"
echo ""

echo "configure ..."

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${BUILD_TARGERT} in
    android)
        export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        export AR=${RABBIT_BUILD_CROSS_PREFIX}gcc-ar
        export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        CONFIG_PARA="${CONFIG_PARA} CC=${RABBIT_BUILD_CROSS_PREFIX}gcc LD=${RABBIT_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
        #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        LDFLAGS="${RABBIT_LDFLAGS}"
    ;;
    unix)
        ;;
    windows_mingw)
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
        #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        LDFLAGS="${RABBIT_LDFLAGS}"
        ;;
    windows_msvc)
        cd ${RABBIT_BUILD_SOURCE_CODE}
        if [ -d ".git" ]; then
            git clean -xdf
        fi
        
        if [ "Debug" = "$RABBIT_CONFIG" ]; then
            Configuration=DynDebug
        else
            Configuration=DynRelease
        fi
        if [  "$TOOLCHAIN_VERSION" = "15" ]; then
            if [ "$BUILD_ARCH" = "x64" ]; then
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=x64 builds/msvc/vs2017/libsodium.sln
                cp bin/x64/$RABBIT_CONFIG/v141/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/x64/$RABBIT_CONFIG/v141/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            else
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=Win32 builds/msvc/vs2017/libsodium.sln
                cp bin/Win32/$RABBIT_CONFIG/v141/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/Win32/$RABBIT_CONFIG/v141/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            fi
        fi
        if [  "$TOOLCHAIN_VERSION" = "12" ]; then
            if [ "$BUILD_ARCH" = "x64" ]; then
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=x64 builds/msvc/vs2013/libsodium.sln
                cp bin/x64/$RABBIT_CONFIG/v120/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/x64/$RABBIT_CONFIG/v120/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            else
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=Win32 builds/msvc/vs2013/libsodium.sln
                cp bin/Win32/$RABBIT_CONFIG/v120/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/Win32/$RABBIT_CONFIG/v120/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            fi
        fi
        if [  "$TOOLCHAIN_VERSION" = "14" ]; then
            if [ "$BUILD_ARCH" = "x64" ]; then
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=x64 builds/msvc/vs2015/libsodium.sln
                cp bin/x64/$RABBIT_CONFIG/v140/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/x64/$RABBIT_CONFIG/v140/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            else
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=Win32 builds/msvc/vs2015/libsodium.sln
                cp bin/Win32/$RABBIT_CONFIG/v140/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/Win32/$RABBIT_CONFIG/v140/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            fi
        fi
        
        echo "cp -fr src/libsodium/include/* $RABBIT_BUILD_PREFIX"
        cp -fr src/libsodium/include/* $RABBIT_BUILD_PREFIX/include
        cd $CUR_DIR
        exit 0
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 3
    ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX"
CONFIG_PARA="${CONFIG_PARA} --disable-soname-versions"
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\" CXXFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\""
../configure ${CONFIG_PARA} \
    CFLAGS="${CFLAGS}" \
    CPPFLAGS="${CPPFLAGS}" \
    CXXFLAGS="${CPPFLAGS}" \
    LDFLAGS="${LDFLAGS}"

echo "make install"
make VERBOSE=1 ${BUILD_JOB_PARA} 
make install

cd $CUR_DIR
