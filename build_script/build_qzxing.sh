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

#运行本脚本前,先运行 build_${BUILD_TARGERT}_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   PREFIX= #修改这里为安装前缀
#   QMAKE=  #设置用于相应平台编译的 QMAKE
echo ". `pwd`/build_envsetup_${BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${BUILD_TARGERT}.sh

if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/qzxing
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=master #29d7e2e6b2b6997db5d419c3c06ec1f01e6e40f6 
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        #echo "git clone -q https://github.com/ftylitak/qzxing.git ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q https://github.com/ftylitak/qzxing.git ${RABBIT_BUILD_SOURCE_CODE}
        echo "git clone -q https://github.com/KangLin/qzxing.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/KangLin/qzxing.git ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        if [ "$VERSION" != "master" ]; then
            git checkout -b ${VERSION} ${VERSION}
        fi
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        #echo "wget -q -c -nv -O qzxing.zip https://github.com/ftylitak/qzxing/archive/${VERSION}.zip"
        #wget -q -c -nv -O qzxing.zip https://github.com/ftylitak/qzxing/archive/${VERSION}.zip
        echo "wget -q -c -nv -O qzxing.zip https://github.com/KangLin/qzxing/archive/${VERSION}.zip"
        wget -q -c -nv -O qzxing.zip https://github.com/KangLin/qzxing/archive/${VERSION}.zip
        unzip -q qzxing.zip
        mv qzxing-${VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f qzxing-${VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

if [ -d "${RABBIT_BUILD_SOURCE_CODE}/src" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_SOURCE_CODE}/src
fi
cd ${RABBIT_BUILD_SOURCE_CODE}

if [ ! -d build_${BUILD_TARGERT} ]; then
    mkdir -p build_${BUILD_TARGERT}
fi
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

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CMAKE_PARA="${CMAKE_PARA} -DBUILD_SHARED_LIBS=OFF"
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
        CMAKE_PARA="${CMAKE_PARA} -DWITH_GSTREAMER=TRUE"
        ;;
    windows_msvc)
        MAKE_PARA=""
        #CMAKE_PARA="${CMAKE_PARA} -DWIN32_USE_DYNAMICBASE=ON"
        ;;
    windows_mingw)
        CMAKE_PARA="${CMAKE_PARA} -DOPENTHREADS_ATOMIC_USE_MUTEX=ON -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-mingw.cmake"
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

CMAKE_PARA="${CMAKE_PARA} -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5"
CMAKE_PARA="${CMAKE_PARA} -DQt5Core_DIR=${QT_ROOT}/lib/cmake/Qt5Core"
CMAKE_PARA="${CMAKE_PARA} -DQt5Gui_DIR=${QT_ROOT}/lib/cmake/Qt5Gui"
CMAKE_PARA="${CMAKE_PARA} -DQt5Widgets_DIR=${QT_ROOT}/lib/cmake/Qt5Widgets"
CMAKE_PARA="${CMAKE_PARA} -DQt5Svg_DIR=${QT_ROOT}/lib/cmake/Qt5Svg"
#CMAKE_PARA="${CMAKE_PARA} -DQt5Quick_DIR=${QT_ROOT}/lib/cmake/Qt5Quick"
#CMAKE_PARA="${CMAKE_PARA} -DQt5Qml_DIR=${QT_ROOT}/lib/cmake/Qt5Qml"
CMAKE_PARA="${CMAKE_PARA} -DQt5Network_DIR=${QT_ROOT}/lib/cmake/Qt5Network"
CMAKE_PARA="${CMAKE_PARA} -DQt5Multimedia_DIR=${QT_ROOT}/lib/cmake/Qt5Multimedia"
CMAKE_PARA="${CMAKE_PARA} -DQZXING_ENABLE_ENCODER=ON"
CMAKE_PARA="${CMAKE_PARA} -DQZXING_MULTIMEDIA=OFF -DQZXING_QML=OFF"

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
    cmake --build . --config ${RABBIT_CONFIG} --target install ${MAKE_PARA}
else
    cmake --build . --config ${RABBIT_CONFIG} --target install/strip ${MAKE_PARA}
fi

cd $CUR_DIR
