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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/opencv
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    OPENCV_VERSION=3.4.0-rc
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q  https://github.com/opencv/opencv.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=${OPENCV_VERSION} https://github.com/opencv/opencv.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q -c https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
        unzip -q ${OPENCV_VERSION}.zip
        mv opencv-${OPENCV_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f opencv-${OPENCV_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi
#opencv versoin > 3.0
RABBIT_BUILD_CONTRIB_SOURCE_CODE=${RABBIT_BUILD_SOURCE_CODE}/../opencv_contrib
if [ ! -d ${RABBIT_BUILD_CONTRIB_SOURCE_CODE} ]; then
    CONTRIB_VERSION=3.4.0
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q https://github.com/opencv/opencv_contrib.git ${RABBIT_BUILD_CONTRIB_SOURCE_CODE}"
        git clone -q --branch=${CONTRIB_VERSION} https://github.com/opencv/opencv_contrib.git ${RABBIT_BUILD_CONTRIB_SOURCE_CODE}
    else
        echo "wget -q -c https://github.com/opencv/opencv_contrib/archive/${CONTRIB_VERSION}.zip"
        mkdir -p ${RABBIT_BUILD_CONTRIB_SOURCE_CODE}
        cd ${RABBIT_BUILD_CONTRIB_SOURCE_CODE}
        wget -q -c https://github.com/opencv/opencv_contrib/archive/${CONTRIB_VERSION}.zip
        unzip -q ${CONTRIB_VERSION}.zip
        mv opencv_contrib-${CONTRIB_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_CONTRIB_SOURCE_CODE}
        mv -f opencv_contrib-${CONTRIB_VERSION} ${RABBIT_BUILD_CONTRIB_SOURCE_CODE}
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
    CMAKE_PARA="-DBUILD_SHARED_LIBS=OFF"
else
    CMAKE_PARA="-DBUILD_SHARED_LIBS=ON"
fi
MAKE_PARA="-- ${RABBIT_MAKE_JOB_PARA} VERBOSE=1"
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
        #RABBITIM_GENERATORS="Visual Studio 12 2013"
        MAKE_PARA=""
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-mingw.cmake"
                ;;
            *)
            CMAKE_PARA="${CMAKE_PARA} -DWITH_DSHOW=OFF"
            ;;
        esac
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

CMAKE_PARA="${CMAKE_PARA} -DBUILD_DOCS=OFF -DBUILD_opencv_apps=OFF -DBUILD_EXAMPLES=OFF -DBUILD_ANDROID_EXAMPLES=OFF"
CMAKE_PARA="${CMAKE_PARA} -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DBUILD_FAT_JAVA_LIB=OFF" # -DBUILD_JASPER=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DBUILD_opencv_world=ON"
#CMAKE_PARA="${CMAKE_PARA} -DBUILD_OPENEXR=OFF -DBUILD_PACKAGE=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DBUILD_TBB=OFF -DBUILD_TIFF=OFF -DBUILD_WITH_DEBUG_INFO=OFF -DWITH_OPENCL=OFF -DBUILD_opencv_ts=OFF"
CMAKE_PARA="${CMAKE_PARA} -DBUILD_opencv_java=OFF"
CMAKE_PARA="${CMAKE_PARA} -DWITH_WIN32UI=OFF -DWITH_VTK=OFF -DWITH_GTK=OFF"
CMAKE_PARA="${CMAKE_PARA} -DWITH_FFMPEG=OFF -DWITH_GSTREAMER=OFF -DWITH_1394=OFF -DWITH_IPP=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DWITH_GIGEAPI=OFF -DWITH_TIFF=OFF -DWITH_OPENEXR=OFF"
CMAKE_PARA="${CMAKE_PARA} -DWITH_PVAPI=OFF -DWITH_JASPER=OFF -DWITH_OPENCLAMDFFT=OFF -DWITH_OPENCLAMDBLAS=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DBUILD_opencv_video=ON"
#CMAKE_PARA="${CMAKE_PARA} -DWITH_JPEG=ON -DWITH_PNG=ON -DBUILD_opencv_videostab=ON"
#CMAKE_PARA="${CMAKE_PARA} -DBUILD_opencv_highgui=ON"
#CMAKE_PARA="${CMAKE_PARA} -DWITH_EIGEN=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DBUILD_opencv_videoio=ON -DWITH_WEBP=OFF -DWITH_IPP_A=OFF"
#CMAKE_PARA="${CMAKE_PARA} -DCMAKE_VERBOSE_MAKEFILE=TRUE" #显示编译详细信息
CMAKE_PARA="${CMAKE_PARA} -DWITH_CUDA=OFF -DWITH_MATLAB=OFF -DWITH_OPENCL=OFF"
CMAKE_PARA="${CMAKE_PARA} -DENABLE_PRECOMPILED_HEADERS=OFF"
CMAKE_PARA="${CMAKE_PARA} -DOPENCV_EXTRA_MODULES_PATH=${RABBIT_BUILD_CONTRIB_SOURCE_CODE}/modules"
CMAKE_PARA="${CMAKE_PARA} -DBUILD_opencv_xfeatures2d=OFF"

echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${RABBITIM_GENERATORS}\" ${CMAKE_PARA}"
cmake .. \
    -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
    -DCMAKE_VERBOSE=ON \
    -G"${RABBITIM_GENERATORS}" ${CMAKE_PARA}

cmake --build . --target install --config ${RABBIT_CONFIG} ${MAKE_PARA}

cd $CUR_DIR
