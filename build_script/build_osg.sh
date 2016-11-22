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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/osg
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    OSG_VERSION=OpenSceneGraph-3.5.3
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=${OSG_VERSION} https://github.com/openscenegraph/OpenSceneGraph.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=$OSG_VERSION https://github.com/openscenegraph/OpenSceneGraph.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q https://github.com/openscenegraph/OpenSceneGraph/archive/${OSG_VERSION}.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q https://github.com/openscenegraph/OpenSceneGraph/archive/${OSG_VERSION}.zip
        unzip -q ${OSG_VERSION}.zip
        mv OpenSceneGraph-${OSG_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f OpenSceneGraph-${OSG_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
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
    CMAKE_PARA="-DDYNAMIC_OPENSCENEGRAPH=OFF" 
else
    CMAKE_PARA="-DDYNAMIC_OPENSCENEGRAPH=ON"
fi
MAKE_PARA="-- ${RABBIT_MAKE_JOB_PARA} VERBOSE=1"
case ${RABBIT_BUILD_TARGERT} in
    android)
        export ANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-${RABBIT_BUILD_TOOLCHAIN_VERSION}
        export ANDROID_NATIVE_API_LEVEL=android-${RABBIT_BUILD_PLATFORMS_VERSION}
        CMAKE_PARA="-DBUILD_SHARED_LIBS=OFF -DDYNAMIC_OPENTHREADS=OFF"
        CMAKE_PARA="${CMAKE_PARA} -DDYNAMIC_OPENSCENEGRAPH=OFF"
        CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-android.cmake"
        CMAKE_PARA="${CMAKE_PARA} -DBUILD_OSG_APPLICATIONS=OFF -DOSG_BUILD_PLATFORM_ANDROID=ON"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_NATIVE_API_LEVEL=android-${RABBIT_BUILD_PLATFORMS_VERSION}"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_TOOLCHAIN_NAME=${RABBIT_BUILD_CROSS_HOST}-${RABBIT_BUILD_TOOLCHAIN_VERSION}"
        CMAKE_PARA="${CMAKE_PARA} -DANDROID_NDK_ABI_NAME=${ANDROID_NDK_ABI_NAME}"
        CMAKE_PARA="${CMAKE_PARA} -DOSG_GL1_AVAILABLE=OFF -DOSG_GL2_AVAILABLE=OFF -DOSG_GL3_AVAILABLE=OFF -DOSG_GLES1_AVAILABLE=OFF"
        CMAKE_PARA="${CMAKE_PARA} -DOSG_GLES2_AVAILABLE=ON -DOSG_GL_LIBRARY_STATIC=OFF -DOSG_GL_DISPLAYLISTS_AVAILABLE=OFF"
        CMAKE_PARA="${CMAKE_PARA} -DOSG_GL_MATRICES_AVAILABLE=OFF -DOSG_GL_VERTEX_FUNCS_AVAILABLE=OFF -DOSG_GL_VERTEX_ARRAY_FUNCS_AVAILABLE=OFF -DOSG_GL_FIXED_FUNCTION_AVAILABLE=OFF"
        CMAKE_PARA="${CMAKE_PARA} -DBUILD_OSG_APPLICATIONS=OFF -DBUILD_OSG_PACKAGES=OFF"
        if [ -n "$RABBIT_CMAKE_MAKE_PROGRAM" ]; then
            CMAKE_PARA="${CMAKE_PARA} -DCMAKE_MAKE_PROGRAM=$RABBIT_CMAKE_MAKE_PROGRAM" 
        fi
        ;;
    unix)
        ;;
    windows_msvc)
        #GENERATORS="Visual Studio 12 2013"
        export OSG_3RDPARTY_DIR=$RABBIT_BUILD_PREFIX
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

CMAKE_PARA="${CMAKE_PARA} -DBUILD_DOCUMENTATION=OFF -DBUILD_OSG_EXAMPLES=OFF -DBUILD_OSG_APPLICATIONS=OFF"
CMAKE_PARA="${CMAKE_PARA} -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5 -DWIN32_USE_MP=ON"
CMAKE_PARA="${CMAKE_PARA} -DCMAKE_VERBOSE_MAKEFILE=ON"
CMAKE_PARA="${CMAKE_PARA} -DCMAKE_MODULE_PATH=$RABBIT_BUILD_PREFIX/lib/cmake"

echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${GENERATORS}\" ${CMAKE_PARA}"
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
    -DCMAKE_BUILD_TYPE="Release" \
    -G"${GENERATORS}" ${CMAKE_PARA}

if [ -z "$CI" ]; then
    cmake --build . --target install --config Debug ${MAKE_PARA}
else
    cmake --build . --target install --config Release ${MAKE_PARA}
fi

cd $CUR_DIR
