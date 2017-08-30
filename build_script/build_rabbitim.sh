#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBIT_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
#   RABBIT_BUILD_PREFIX=`pwd`/../${RABBIT_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_SOURCE_CODE    #源码目录
#   RABBIT_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM(android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY] [qmake]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    RABBIT_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

#运行本脚本前,先运行 build_${RABBIT_BUILD_TARGERT}_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBIT_BUILD_PREFIX= #修改这里为安装前缀
#   QMAKE=  #设置用于相应平台编译的 QMAKE
#   JOM=    #QT 自带的类似 make 的工具
if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../..
fi

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    echo "git clone https://github.com/KangLin/RABBIT.git"
    git clone -q https://github.com/KangLin/RABBIT.git ${RABBIT_BUILD_SOURCE_CODE}
fi

CUR_DIR=`pwd`
cd ${RABBIT_BUILD_SOURCE_CODE}

echo ""
echo "RABBIT_BUILD_TARGERT:${RABBIT_BUILD_TARGERT}"
echo "RABBIT_BUILD_SOURCE_CODE:$RABBIT_BUILD_SOURCE_CODE"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "RABBIT_BUILD_CROSS_PREFIX:$RABBIT_BUILD_CROSS_PREFIX"
echo "RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "RABBIT_BUILD_HOST:$RABBIT_BUILD_HOST"
echo "PKG_CONFIG:$PKG_CONFIG"
echo "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo "RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo "PATH:$PATH"

mkdir -p build_${RABBIT_BUILD_TARGERT}
cd build_${RABBIT_BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

echo "CUR_DIR:`pwd`"
echo ""

if [ "$3" = "cmake" ]; then

    CMAKE_PARA="--target package"
    PARA="-DCMAKE_BUILD_TYPE=Release -DQt5_DIR=${QT_ROOT}/lib/cmake/Qt5 -DCMAKE_VERBOSE_MAKEFILE=TRUE"
  #  if [ "${RABBIT_BUILD_STATIC}" = "static" ]; then
  #      PARA="${PARA} -DOPTION_RABBIT_USE_STATIC=ON"
  #  fi
    MAKE_PARA="-- ${RABBIT_MAKE_JOB_PARA} VERBOSE=1"
    case $1 in
        android)
            #export ANDROID_NATIVE_API_LEVEL=android-${RABBIT_BUILD_PLATFORMS_VERSION}
            #export ANDROID_TOOLCHAIN_NAME=${RABBIT_BUILD_CROSS_HOST}-${RABBIT_BUILD_TOOLCHAIN_VERSION}
            #export ANDROID_NDK_ABI_NAME="armeabi-v7a with NEON"
            CMAKE_PARA="${CMAKE_PARA} -DCMAKE_TOOLCHAIN_FILE=$RABBIT_BUILD_PREFIX/../build_script/cmake/platforms/toolchain-android.cmake"
            PARA="${PARA} -DANDROID_NATIVE_API_LEVEL=android-${RABBIT_BUILD_PLATFORMS_VERSION}"
            PARA="${PARA} -DANDROID_TOOLCHAIN_NAME=${RABBIT_BUILD_CROSS_HOST}-${RABBIT_BUILD_TOOLCHAIN_VERSION}"
            PARA="${PARA} -DANDROID_NDK_ABI_NAME=${ANDROID_NDK_ABI_NAME}"
            PARA="${PARA} -DLIBRARY_OUTPUT_PATH:PATH=`pwd`"
            PARA="${PARA} -DOPTION_RABBIT_USE_OPENCV=OFF"
            #PARA="${PARA} -DOPTION_RABBIT_USE_LIBCURL=OFF -DOPTION_RABBIT_USE_OPENSSL=OFF"
            PARA="${PARA} -DANT=${ANT}"
            CMAKE_PARA=""
            ;;
        unix)
            PARA="${PARA} -DCMAKE_INSTALL_PREFIX=/usr/local/RABBIT"  #设置打包的安装路径
            ;;
        windows_msvc)
            #因为用Visual Studio 2013生成的目标路径与配置有关，这影响到安装文件的生成，所以用nmake生成
            GENERATORS="NMake Makefiles" #GENERATORS="Visual Studio 12 2013"
            #PARA="${PARA} -DOPTION_RABBIT_USE_LIBCURL=OFF -DOPTION_RABBIT_USE_OPENSSL=OFF"
            PARA="${PARA} -DOPTION_RABBIT_USE_OPENCV=OFF"
            MAKE_PARA=""
            ;;
        windows_mingw)
            case `uname -s` in
                Linux*|Unix*|CYGWIN*)
                    PARA="${PARA} -DCMAKE_TOOLCHAIN_FILE=${RABBIT_BUILD_SOURCE_CODE}/cmake/platforms/toolchain-mingw.cmake"
                    CMAKE_PARA=""
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

    echo "cmake .. -G\"${GENERATORS}\" $PARA"
    cmake .. -G"${GENERATORS}" $PARA # --debug-output
    echo "build ...."
    echo "cmake --build . --config Release ${CMAKE_PARA} ${MAKE_PARA}"
    cmake --build . --config Release ${CMAKE_PARA} ${MAKE_PARA}

else #qmake编译

    MAKE="make ${RABBIT_MAKE_JOB_PARA}"
    case $1 in
        android)
            export ANDROID_NDK_PLATFORM=$ANDROID_API_VERSION
            #PARA="-r -spec android-g++ " #RABBIT_USE_OPENCV=1
            if [ -n "$RABBIT_CMAKE_MAKE_PROGRAM" ]; then
                MAKE="$RABBIT_CMAKE_MAKE_PROGRAM"
            fi
            
            if [ "${RABBIT_BUILD_HOST}"="windows" ]; then
                MAKE="make" # ${RABBIT_MAKE_JOB_PARA}"
            fi
            
            ;;
        unix)
            #PARA="-r -spec linux-g++ "
            ;;
        windows_msvc)
            MAKE=nmake
            ;;
        windows_mingw)
            #PARA="-r -spec win32-g++"
	    MAKE="mingw32-make ${RABBIT_MAKE_JOB_PARA}"
            ;;
        *)
            echo "${HELP_STRING}"
            exit 1
            ;;
    esac
   # if [ "${RABBIT_BUILD_STATIC}" = "static" ]; then
   #     PARA="$PARA CONFIG+=static"
   # fi
    echo "qmake ...."
    $QMAKE ../RabbitIm.pro  $PARA "CONFIG+=release"  \
           INCLUDEPATH+=${RABBIT_BUILD_PREFIX}/include \
           LIBS+=-L${RABBIT_BUILD_PREFIX}/lib \
           QXMPP_USE_VPX=1 \
           RABBIT_USE_FFMPEG=1 \
           RABBIT_USE_LIBCURL=1 \
           RABBIT_USE_OPENSSL=1
    echo "$MAKE ...."
    if [ "$1" == "android" ]; then
        $MAKE -f Makefile install INSTALL_ROOT="`pwd`/android-build"
        ${QT_BIN}/androiddeployqt --input "`pwd`/android-libRABBITApp.so-deployment-settings.json" --output "`pwd`/android-build" --verbose
    else
        $MAKE -f Makefile
        echo "$MAKE install ...."
        $MAKE install
    fi
fi

cd $CUR_DIR
