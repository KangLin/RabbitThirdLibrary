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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libcurl
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
	CURL_FILE=curl-7_68_0
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q https://github.com/curl/curl.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=$CURL_FILE https://github.com/curl/curl.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget  -q https://github.com/bagder/curl/archive/${CURL_FILE}.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -c -q https://github.com/bagder/curl/archive/${CURL_FILE}.zip
        unzip -q  ${CURL_FILE}.zip
        mv curl-${CURL_FILE} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f curl-${CURL_FILE} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}
if [ -n "$RABBIT_CLEAN" ]; then
    rm -fr *
fi

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
echo "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo ""

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CMAKE_PARA="${CMAKE_PARA} -DBUILD_SHARED_LIBS=OFF"
    CMAKE_PARA="${CMAKE_PARA} -DOPENSSL_USE_STATIC_LIBS=TRUE"
else
    CMAKE_PARA="${CMAKE_PARA} -DBUILD_SHARED_LIBS=ON"
fi

MAKE_PARA="-- ${BUILD_JOB_PARA} VERBOSE=1"
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

#CMAKE_PARA="${CMAKE_PARA} -DCMAKE_USE_OPENSSL=OFF -DCURL_CA_PATH=none -DOPENSSL_ROOT_DIR=$RABBIT_BUILD_PREFIX"
CMAKE_PARA="${CMAKE_PARA} -DCMAKE_USE_OPENSSL=ON -DOPENSSL_ROOT_DIR=$RABBIT_BUILD_PREFIX"
echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} -G\"${GENERATORS}\" ${CMAKE_PARA}"
if [ "${BUILD_TARGERT}" = "android" ]; then
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
        -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${GENERATORS}" ${CMAKE_PARA} -DANDROID_ABI="${ANDROID_ABI}"
else
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
        -DCMAKE_VERBOSE_MAKEFILE=ON -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${GENERATORS}" ${CMAKE_PARA} 
fi
cmake --build . --config ${RABBIT_CONFIG} ${MAKE_PARA}
if [ "android" != "${BUILD_TARGERT}" ]; then
    cmake --build . --config ${RABBIT_CONFIG}  --target install ${MAKE_PARA}
else
    cmake --build . --config ${RABBIT_CONFIG}  --target install/strip ${MAKE_PARA}
fi

cd $CUR_DIR
