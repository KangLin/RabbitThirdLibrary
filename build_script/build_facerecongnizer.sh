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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/FaceRecongnizer
fi

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=master
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q https://github.com/KangLin/FaceRecongnizer.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/KangLin/FaceRecognizer.git ${RABBIT_BUILD_SOURCE_CODE}
        if [ "$VERSION" != "master" ]; then
            git checkout -b $VERSION $VERSION
        fi
    else
        echo "wget -q -c https://github.com/KangLin/FaceRecongnizer/archive/${VERSION}.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/KangLin/FaceRecongnizer/archive/${VERSION}.zip
        unzip -q ${VERSION}.zip
        mv FaceRecongnizer-${VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f FaceRecongnizer-${VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi


CUR_DIR=`pwd`
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
echo "BUILD_JOB_PARA:$BUILD_JOB_PARA"
echo "RABBIT_CMAKE_MAKE_PROGRAM:$RABBIT_CMAKE_MAKE_PROGRAM"
echo ""

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。

MAKE_PARA="-- ${BUILD_JOB_PARA}"
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
    return 2
    ;;
esac

CMAKE_PARA="${CMAKE_PARA} -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5
        -DQt5Core_DIR=${QT_ROOT}/lib/cmake/Qt5Core
        -DQt5Gui_DIR=${QT_ROOT}/lib/cmake/Qt5Gui
        -DQt5Widgets_DIR=${QT_ROOT}/lib/cmake/Qt5Widgets
        -DQt5Xml_DIR=${QT_ROOT}/lib/cmake/Qt5Xml
        -DQt5Network_DIR=${QT_ROOT}/lib/cmake/Qt5Network
        -DQt5Multimedia_DIR=${QT_ROOT}/lib/cmake/Qt5Multimedia
        -DQt5Sql_DIR=${QT_ROOT}/lib/cmake/Qt5Sql
        -DQt5LinguistTools_DIR=${QT_ROOT}/lib/cmake/Qt5LinguistTools
        -DQt5AndroidExtras_DIR=${QT_ROOT}/lib/cmake/Qt5AndroidExtras"
        
CMAKE_PARA="${CMAKE_PARA} -DSeetaFace_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake 
        -DSeetaNet_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake 
        -DSeetaFaceDetector_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake 
        -DSeetaFaceLandmarker_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake 
        -DSeetaFaceRecognizer_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake 
        -DSeetaFaceTracker_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake 
        -DSeetaQualityAssessor_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake "
        
CMAKE_PARA="${CMAKE_PARA} -DYUV_DIR=${RABBIT_BUILD_PREFIX}/lib/cmake"
CMAKE_PARA="${CMAKE_PARA} -DOPENCV_DIR=${RABBIT_BUILD_PREFIX}"

echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} -G\"${GENERATORS}\" ${CMAKE_PARA} -DANDROID_ABI=\"${ANDROID_ABI}\""
if [ "${BUILD_TARGERT}" = "android" ]; then
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX"/FaceRecongnizer \
        -DCMAKE_VERBOSE_MAKEFILE=OFF -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${GENERATORS}" ${CMAKE_PARA} -DANDROID_ABI="${ANDROID_ABI}"
        
    cmake --build . --config ${RABBIT_CONFIG} ${MAKE_PARA}
    cmake --build . --config ${RABBIT_CONFIG} --target install ${MAKE_PARA}
    cmake --build . --config ${RABBIT_CONFIG} --target APK
else
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
        -DCMAKE_VERBOSE_MAKEFILE=OFF -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${GENERATORS}" ${CMAKE_PARA}    
    cmake --build . --config ${RABBIT_CONFIG} ${MAKE_PARA}
    cmake --build . --config ${RABBIT_CONFIG} --target install ${MAKE_PARA}
fi


cd $CUR_DIR
