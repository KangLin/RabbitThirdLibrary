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

echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh

RABBIT_BUILD_SOURCE_CODE=$2
if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/freetype
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=2.9
    GITVERSION=VER-2-9
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        #echo "git clone -q --branch=${GITVERSION} http://git.sv.nongnu.org/r/freetype/freetype2.git ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q --branch=${GITVERSION} http://git.sv.nongnu.org/r/freetype/freetype2.git ${RABBIT_BUILD_SOURCE_CODE}
        echo "git clone -q -b ${GITVERSION} https://github.com/KangLin/freetype.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q -b ${GITVERSION} https://github.com/KangLin/freetype.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        #echo "wget -nv -c https://sourceforge.net/projects/freetype/files/freetype2/${VERSION}/freetype-${VERSION}.tar.gz/download"
        #wget -nv -c -O freetype-${VERSION}.tar.gz https://sourceforge.net/projects/freetype/files/freetype2/${VERSION}/freetype-${VERSION}.tar.gz/download
        wget -nv -O freetype-${VERSION}.tar.gz https://github.com/KangLin/freetype/archive/${GITVERSION}.tar.gz
        tar xvzf freetype-${VERSION}.tar.gz
        mv freetype-${GITVERSION} ..
        rm -fr freetype-${VERSION}.tar.gz ${RABBIT_BUILD_SOURCE_CODE}
        cd ..
        mv freetype-${GITVERSION} ${RABBIT_BUILD_SOURCE_CODE} 
    fi
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
echo ""

if [ ! -f configure -a "windows_msvc" != "${RABBIT_BUILD_TARGERT}" ]; then
    echo "sh autogen.sh"
    sh autogen.sh
fi

mkdir -p build_${RABBIT_BUILD_TARGERT}
cd build_${RABBIT_BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。

MAKE_PARA="-- ${RABBIT_MAKE_JOB_PARA}"
case ${RABBIT_BUILD_TARGERT} in
    android)
        if [ -n "$RABBIT_CMAKE_MAKE_PROGRAM" ]; then
            CMAKE_PARA="${CMAKE_PARA} -DCMAKE_MAKE_PROGRAM=$RABBIT_CMAKE_MAKE_PROGRAM" 
        fi
        CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-android.cmake"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL}"
        #CMAKE_PARA="${CMAKE_PARA} -DANDROID_ABI=${ANDROID_ABI}"  
    ;;
    unix)
    ;;
    windows_msvc)
        MAKE_PARA=""
        CMAKE_PARA="${CMAKE_PARA} -DWITH_PNG=OFF"
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../../cmake/platforms/toolchain-mingw.cmake"
                ;;
            *)
            ;;
        esac
        CMAKE_PARA="${CMAKE_PARA} -DWITH_PNG=OFF"
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    return 2
    ;;
esac

CMAKE_PARA="${CMAKE_PARA} -DWITH_BZip2=OFF -DWITH_HarfBuzz=OFF"
echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${RABBITIM_GENERATORS}\" ${CMAKE_PARA}"
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
    -G"${RABBITIM_GENERATORS}" ${CMAKE_PARA}  

cmake --build . --target install --config ${RABBIT_CONFIG} ${MAKE_PARA}

cd $CUR_DIR
