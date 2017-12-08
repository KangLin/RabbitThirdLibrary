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

if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/berkeleydb
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=6.2.32.NC
    
    mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
    cd ${RABBIT_BUILD_SOURCE_CODE}
    echo "wget -nv -c http://download.oracle.com/berkeley-db/db-${VERSION}.tar.gz"
    wget -nv -c http://download.oracle.com/berkeley-db/db-${VERSION}.tar.gz
    tar xzf db-${VERSION}.tar.gz
    mv db-${VERSION} ..
    rm -fr db-${VERSION}.tar.gz ${RABBIT_BUILD_SOURCE_CODE}
    cd ..
    mv db-${VERSION} ${RABBIT_BUILD_SOURCE_CODE} 
fi


cd ${RABBIT_BUILD_SOURCE_CODE}

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
echo "PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo "PATH:${PATH}"
echo ""

echo "configure ..."

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
MAKE_PARA=" ${RABBIT_MAKE_JOB_PARA} "
case ${RABBIT_BUILD_TARGERT} in
    android)
       ;;
    unix)
        cd ${RABBIT_BUILD_SOURCE_CODE}/build_unix
        if [ "$RABBIT_CLEAN" = "TRUE" ]; then
            rm -fr *
        fi
        ../dist/configure --prefix=${RABBIT_BUILD_PREFIX} \
            --enable-cxx ${CONFIG_PARA}
        ;;
    windows_msvc)
        cd ${RABBIT_BUILD_SOURCE_CODE}/build_windows
        if [ "Debug" = "$RABBIT_CONFIG" ]; then
            Configuration=Debug
        else
            Configuration=Release
        fi
        if [  "$RABBIT_TOOLCHAIN_VERSION" = "15" ]; then
            if [ "$RABBIT_ARCH" = "x64" ]; then
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=x64 Berkeley_DB_vs2012.sln
                cp bin/x64/$RABBIT_CONFIG/v141/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/x64/$RABBIT_CONFIG/v141/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            else
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=Win32 Berkeley_DB_vs2012.sln
                cp bin/Win32/$RABBIT_CONFIG/v141/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/Win32/$RABBIT_CONFIG/v141/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            fi
        fi
        if [  "$RABBIT_TOOLCHAIN_VERSION" = "12" ]; then
            if [ "$RABBIT_ARCH" = "x64" ]; then
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=x64 Berkeley_DB_vs2012.sln
                cp bin/x64/$RABBIT_CONFIG/v120/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/x64/$RABBIT_CONFIG/v120/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            else
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=Win32 Berkeley_DB_vs2012.sln
                cp bin/Win32/$RABBIT_CONFIG/v120/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/Win32/$RABBIT_CONFIG/v120/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            fi
        fi
        if [  "$RABBIT_TOOLCHAIN_VERSION" = "14" ]; then
            if [ "$RABBIT_ARCH" = "x64" ]; then
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=x64 Berkeley_DB_vs2012.sln
                cp bin/x64/$RABBIT_CONFIG/v140/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/x64/$RABBIT_CONFIG/v140/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            else
                msbuild.exe -m -v:n -p:Configuration=${Configuration} -p:Platform=Win32 Berkeley_DB_vs2012.sln
                cp bin/Win32/$RABBIT_CONFIG/v140/dynamic/*.dll $RABBIT_BUILD_PREFIX/bin
                cp bin/Win32/$RABBIT_CONFIG/v140/dynamic/*.lib $RABBIT_BUILD_PREFIX/lib
            fi
        fi
        cd $CUR_DIR
        exit 0
        ;;
    windows_mingw)
        cd ${RABBIT_BUILD_SOURCE_CODE}/build_unix
        if [ "$RABBIT_CLEAN" = "TRUE" ]; then
            rm -fr *
        fi
        ../dist/configure --prefix=${RABBIT_BUILD_PREFIX} --enable-mingw \
            --enable-cxx ${CONFIG_PARA}

        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 3
        ;;
esac

${MAKE} ${MAKE_PARA}
${MAKE} install

cd $CUR_DIR
