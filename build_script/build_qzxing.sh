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

case $BUILD_TARGERT in
    android)
        case $TARGET_OS in
           MINGW* | CYGWIN* | MSYS*)
               MAKE="$ANDROID_NDK/prebuilt/${RABBIT_BUILD_HOST}/bin/make ${BUILD_JOB_PARA} VERBOSE=1" #在windows下编译
           ;;
        *)
           ;;
        esac
         
        MAKE_PARA=" INSTALL_ROOT=\"${RABBIT_BUILD_PREFIX}\""
        ;;
    unix)
        ;;
    windows_msvc)
        BUILD_JOB_PARA=""
        ;;
    windows_mingw)
        #PARA="-r -spec win32-g++" # CROSS_COMPILE=${RABBIT_BUILD_CROSS_PREFIX}"
        ;;
    *)
        echo "Usage $0 PLATFORM(android/windows_msvc/windows_mingw/unix) SOURCE_CODE_ROOT"
        cd $CUR_DIR
        exit 2
        ;;
esac

PARA="${PARA} INCLUDEPATH+=${RABBIT_BUILD_PREFIX}/include"
PARA="${PARA} LIBS+=-L${RABBIT_BUILD_PREFIX}/lib"
PARA="${PARA} PREFIX=${RABBIT_BUILD_PREFIX}"

if [ "${RABBIT_CONFIG}" = "Debug" -o "${RABBIT_CONFIG}" = "debug" ]; then
    RELEASE_PARA="${PARA} CONFIG-=release CONFIG+=debug"
else
    RELEASE_PARA="${PARA} CONFIG-=debug CONFIG+=release"
fi

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    RELEASE_PARA="${RELEASE_PARA} CONFIG+=staticlib"
fi

echo "$QMAKE ${RELEASE_PARA}"
$QMAKE ${RELEASE_PARA} ..
${MAKE} -f Makefile install ${MAKE_PARA} ${BUILD_JOB_PARA}

if [ "$BUILD_TARGERT" = "windows_mingw" ]; then
    cp ${RABBIT_CONFIG}/pkgconfig/QZXing.pc ${RABBIT_BUILD_PREFIX}/lib/pkgconfig/.
fi

cd $CUR_DIR
