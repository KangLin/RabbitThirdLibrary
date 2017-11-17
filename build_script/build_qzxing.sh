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

#运行本脚本前,先运行 build_${RABBIT_BUILD_TARGERT}_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   PREFIX= #修改这里为安装前缀
#   QMAKE=  #设置用于相应平台编译的 QMAKE
if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/qzxing
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=master
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q https://github.com/ftylitak/qzxing.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/KangLin/qzxing.git ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        git checkout -b ${VERSION} ${VERSION}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/ftylitak/qzxing/archive/${VERSION}.zip
        unzip -q ${VERSION}.zip
        mv qzxing-${FFMPEG_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f qzxing-${FFMPEG_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

if [ -d "${RABBIT_BUILD_SOURCE_CODE}/src" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_SOURCE_CODE}/src
fi
cd ${RABBIT_BUILD_SOURCE_CODE}

if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    git clean -xdf
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

case $RABBIT_BUILD_TARGERT in
    android)
        PARA="-r -spec android-g++"
        case $TARGET_OS in
            MINGW* | CYGWIN* | MSYS*)
                MAKE="$ANDROID_NDK/prebuilt/${RABBIT_BUILD_HOST}/bin/make ${RABBIT_MAKE_JOB_PARA} VERBOSE=1" #在windows下编译
                ;;
            *)
            ;;
         esac
         ;;
    unix)
        ;;
    windows_msvc)
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

PARA="${PARA} -o Makefile INCLUDEPATH+=${RABBIT_BUILD_PREFIX}/include"
PARA="${PARA} LIBS+=-L${RABBIT_BUILD_PREFIX}/lib"
if [ "$RABBIT_BUILD_TARGERT" != "android"  ]; then
    PARA="${PARA} PREFIX=${RABBIT_BUILD_PREFIX}"
fi
RELEASE_PARA="${PARA} CONFIG*=${RABBIT_CONFIG}"
if [ "$RABBIT_BUILD_STATIC" = "static" -o "$RABBIT_BUILD_TARGERT" = "android" ]; then
    RELEASE_PARA="${RELEASE_PARA} CONFIG+=static"
fi
if [ "$RABBIT_BUILD_TARGERT" = "android"  ]; then
    MAKE_PARA=" INSTALL_ROOT=\"${RABBIT_BUILD_PREFIX}\""
fi
echo "$QMAKE ${RELEASE_PARA}"
$QMAKE ${RELEASE_PARA}
${MAKE} -f Makefile install ${MAKE_PARA}


cd $CUR_DIR
