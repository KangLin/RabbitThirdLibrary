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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/osgearth
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    OSG_VERSION=105be1e4581d76ab6f5dd4390fd055b0f55c5efb #osgearth-2.8
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=${OSG_VERSION} https://github.com/gwaldron/osgearth.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/gwaldron/osgearth.git ${RABBIT_BUILD_SOURCE_CODE}
        #echo "git clone -q https://github.com/KangLin/osgearth.git ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q https://github.com/KangLin/osgearth.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -q https://github.com/gwaldron/osgearth/archive/${OSG_VERSION}.zip"
        wget -nv -c https://github.com/gwaldron/osgearth/archive/${OSG_VERSION}.zip
        #echo "wget -q https://github.com/KangLin/osgearth/archive/${OSG_VERSION}.zip"
        #wget -nv -c https://github.com/KangLin/osgearth/archive/${OSG_VERSION}.zip
        echo "unzip -q ${OSG_VERSION}.zip"
        unzip -q ${OSG_VERSION}.zip
        mv osgearth-${OSG_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f osgearth-${OSG_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

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
echo "RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo ""

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CMAKE_PARA="-DDYNAMIC_OSGEARTH=OFF" # -DCMAKE_EXE_LINKER_FLAGS=-static -DCMAKE_MODULE_LINKER_FLAGS_RELEASE=-static -DCMAKE_STATIC_LINKER_FLAGS=-static"
else
    CMAKE_PARA="-DDYNAMIC_OSGEARTH=ON"
fi
MAKE_PARA="-- ${RABBIT_MAKE_JOB_PARA} VERBOSE=1"

case ${RABBIT_BUILD_TARGERT} in
    android)
        export ANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-${RABBIT_BUILD_TOOLCHAIN_VERSION}
        export ANDROID_NATIVE_API_LEVEL=android-${RABBIT_BUILD_PLATFORMS_VERSION}
        CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-android.cmake"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_NATIVE_API_LEVEL=android-${RABBIT_BUILD_PLATFORMS_VERSION}"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_TOOLCHAIN_NAME=${RABBIT_BUILD_CROSS_HOST}-${RABBIT_BUILD_TOOLCHAIN_VERSION}"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_NDK_ABI_NAME=${ANDROID_NDK_ABI_NAME}"

        if [ -n "$RABBIT_CMAKE_MAKE_PROGRAM" ]; then
            CMAKE_PARA="${CMAKE_PARA} -DCMAKE_MAKE_PROGRAM=$RABBIT_CMAKE_MAKE_PROGRAM" 
        fi
        ;;
    unix)
        ;;
    windows_msvc)
        #RABBITIM_GENERATORS="Visual Studio 12 2013"
        MAKE_PARA=""
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-mingw.cmake"
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

CMAKE_PARA="${CMAKE_PARA} -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5 -DCMAKE_VERBOSE_MAKEFILE=TRUE -DOSGEARTH_USE_QT=ON"
CMAKE_PARA="${CMAKE_PARA} -DTHIRD_PARTY_DIR=${RABBIT_BUILD_PREFIX} -DOSG_DIR=${RABBIT_BUILD_PREFIX} -DWIN32_USE_MP=ON"
CMAKE_PARA="${CMAKE_PARA} -DBUILD_OSGEARTH_EXAMPLES=OFF"
echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${RABBITIM_GENERATORS}\" ${CMAKE_PARA}"
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
    -G"${RABBITIM_GENERATORS}" ${CMAKE_PARA}
    
cmake --build . --target install --config ${RABBIT_CONFIG} ${MAKE_PARA}

cd $CUR_DIR
