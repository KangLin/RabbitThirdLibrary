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
HELP_STRING="Usage $0 PLATFORM(android|windows_msvc|windows_mingw|unix) [qmake] [SOURCE_CODE_ROOT_DIRECTORY] "

BUILD_TARGET=$1
case $BUILD_TARGET in
    android|windows_msvc|windows_mingw|unix)
        BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

RABBIT_BUILD_SOURCE_CODE=$3

echo ". `pwd`/build_envsetup_${BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${BUILD_TARGERT}.sh

if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../..
fi

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    echo "git clone https://github.com/KangLin/RabbitIm.git"
    git clone -q https://github.com/KangLin/RabbitIm.git ${RABBIT_BUILD_SOURCE_CODE}
fi

CUR_DIR=`pwd`
cd ${RABBIT_BUILD_SOURCE_CODE}

echo "BUILD_TARGERT:${BUILD_TARGERT}"
echo "RABBIT_BUILD_SOURCE_CODE:$RABBIT_BUILD_SOURCE_CODE"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "RABBIT_BUILD_CROSS_PREFIX:$RABBIT_BUILD_CROSS_PREFIX"
echo "RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "RABBIT_BUILD_HOST:$RABBIT_BUILD_HOST"
echo "PKG_CONFIG:$PKG_CONFIG"
echo "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo "RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo "QMAKE:$QMAKE"
echo "MAKE:$MAKE"
echo "PATH:$PATH"

mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

echo "CUR_DIR:`pwd`"
echo ""

if [ "$2" = "cmake" ]; then

  #  if [ "${RABBIT_BUILD_STATIC}" = "static" ]; then
  #      PARA="${PARA} -DOPTION_RABBIT_USE_STATIC=ON"
  #  fi
    MAKE_PARA="-- ${BUILD_JOB_PARA} VERBOSE=1"
    case $BUILD_TARGET in
        android)
            CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-android.cmake"
            CMAKE_PARA="${CMAKE_PARA} -DLIBRARY_OUTPUT_PATH:PATH=`pwd`"
            #CMAKE_PARA="${CMAKE_PARA} -DOPTION_RABBIT_USE_LIBCURL=OFF -DOPTION_RABBIT_USE_OPENSSL=OFF"
            CMAKE_PARA="${CMAKE_PARA} -DANT=${ANT}"
            export ANDROID_ABI="${ANDROID_ABI}" 
            ;;
        unix)
            ;;
        windows_msvc)
            MAKE_PARA=""
            ;;
        windows_mingw)
            case `uname -s` in
                Linux*|Unix*|CYGWIN*)
                    CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=${RABBIT_BUILD_SOURCE_CODE}/cmake/platforms/toolchain-mingw.cmake"
                    ;;
                *)
                ;;
            esac
            ;;
        *)
            echo "${HELP_STRING}"
            cd $CUR_DIR
            exit 1
            ;;
    esac

    CMAKE_PARA="${CMAKE_PARA} -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5 -DCMAKE_VERBOSE_MAKEFILE=TRUE"
    CMAKE_PARA="${CMAKE_PARA} -DTHIRD_LIBRARY_PATH=$RABBIT_BUILD_PREFIX"

    cmake .. \
        -DCMAKE_INSTALL_PREFIX="`PWD`/install" \
        -DCMAKE_BUILD_TYPE=${RABBIT_CONFIG} \
        -G"${RABBITIM_GENERATORS}" ${CMAKE_PARA} -DCMAKE_VERBOSE_MAKEFILE=TRUE 

    echo "cmake --build . --target install --config ${RABBIT_CONFIG} ${MAKE_PARA}"
    cmake --build . --target install --config ${RABBIT_CONFIG} ${MAKE_PARA}

else #qmake编译

    case $BUILD_TARGET in
        android)
            export ANDROID_NDK_PLATFORM=android-$ANDROID_NATIVE_API_LEVEL
            export CPPFLAGS=$RABBIT_CPPFLAGS
            export CFLAGS=$RABBIT_CFLAGS
            export LDFLAGS=$RABBIT_LDFLAGS
            #PARA="-r -spec android-g++ " #RABBIT_USE_OPENCV=1
            if [ -n "$RABBIT_CMAKE_MAKE_PROGRAM" ]; then
                MAKE="$RABBIT_CMAKE_MAKE_PROGRAM"
            fi
            if [ -n "$CI" ]; then
                MAKE="/c/msys64/mingw32/bin/mingw32-make ${BUILD_JOB_PARA}"
            fi
            ;;
        unix)
            #PARA="-r -spec linux-g++ "
            MAKE="$MAKE ${BUILD_JOB_PARA}"
            ;;
        windows_msvc)
            ;;
        windows_mingw)
            #PARA="-r -spec win32-g++"
	        MAKE="$MAKE ${BUILD_JOB_PARA}"
            ;;
        *)
            echo "${HELP_STRING}"
            exit 1
            ;;
    esac
   # if [ "${RABBIT_BUILD_STATIC}" = "static" ]; then
   #     PARA="$PARA CONFIG+=static"
   # fi
    PARA="${PARA} -o Makefile"
    if [ "${RABBIT_CONFIG}" = "Debug" -o "${RABBIT_CONFIG}" = "debug" ]; then
        PARA="${PARA} CONFIG-=release CONFIG+=debug"
        #MAKE_PARA="${MAKE_PARA} debug"
    else
        PARA="${PARA} CONFIG-=debug CONFIG+=release"
        #MAKE_PARA="${MAKE_PARA} release"
    fi
    PARA="${PARA} THIRD_LIBRARY_PATH=$RABBIT_BUILD_PREFIX"
    PARA="${PARA} QXMPP_USE_VPX=1"
    PARA="${PARA} RABBIT_USE_FFMPEG=1"
    PARA="${PARA} RABBIT_USE_LIBCURL=1"
    PARA="${PARA} RABBIT_USE_OPENSSL=1"
    echo "$QMAKE ...."
    $QMAKE $PARA ../RabbitIm.pro 
    echo "$MAKE ...."
    if [ "$1" == "android" ]; then
        $MAKE -f Makefile install ${MAKE_PARA} INSTALL_ROOT="`pwd`/android-build"
        ${QT_BIN}/androiddeployqt --input "`pwd`/android-libRABBITApp.so-deployment-settings.json" --output "`pwd`/android-build" --verbose
    else
        $MAKE -f Makefile
        echo "$MAKE install ...."
        $MAKE install ${MAKE_PARA}
    fi
fi

cd $CUR_DIR
