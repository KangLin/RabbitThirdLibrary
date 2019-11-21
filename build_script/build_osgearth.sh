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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/osgearth
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    OSG_VERSION=osgearth-2.10
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

mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
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
echo ""

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CMAKE_PARA="-DDYNAMIC_OSGEARTH=OFF" # -DCMAKE_EXE_LINKER_FLAGS=-static -DCMAKE_MODULE_LINKER_FLAGS_RELEASE=-static -DCMAKE_STATIC_LINKER_FLAGS=-static"
else
    CMAKE_PARA="-DDYNAMIC_OSGEARTH=ON"
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
        #RABBITIM_GENERATORS="Visual Studio 12 2013"
        MAKE_PARA=""
        CMAKE_PARA="${CMAKE_PARA} -DWIN32_USE_MP=ON"
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

#CMAKE_PARA="${CMAKE_PARA} -DDESIRED_QT_VERSION=5"
CMAKE_PARA="${CMAKE_PARA} -DOSGEARTH_QT_BUILD=ON"
CMAKE_PARA="${CMAKE_PARA} -DQt5Widgets_DIR=${QT_ROOT}/lib/cmake/Qt5Widgets"
CMAKE_PARA="${CMAKE_PARA} -DQt5Core_DIR=${QT_ROOT}/lib/cmake/Qt5Core"
CMAKE_PARA="${CMAKE_PARA} -DQt5Gui_DIR=${QT_ROOT}/lib/cmake/Qt5Gui"
CMAKE_PARA="${CMAKE_PARA} -DQt5OpenGL_DIR=${QT_ROOT}/lib/cmake/Qt5OpenGL"
CMAKE_PARA="${CMAKE_PARA} -DQt5OpenGLExtensions_DIR=${QT_ROOT}/lib/cmake/Qt5OpenGLExtensions"
CMAKE_PARA="${CMAKE_PARA} -DCMAKE_VERBOSE_MAKEFILE=TRUE"
CMAKE_PARA="${CMAKE_PARA} -DTHIRD_PARTY_DIR=${RABBIT_BUILD_PREFIX} -DOSG_DIR=${RABBIT_BUILD_PREFIX}"
CMAKE_PARA="${CMAKE_PARA} -DBUILD_OSGEARTH_EXAMPLES=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG}"
echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${RABBITIM_GENERATORS}\" ${CMAKE_PARA}"
cmake ..  \
    -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
    -G"${RABBITIM_GENERATORS}" ${CMAKE_PARA}
    
cmake --build . --config ${RABBIT_CONFIG} ${MAKE_PARA}
cmake --build . --config ${RABBIT_CONFIG}  --target install ${MAKE_PARA}

cd $CUR_DIR
