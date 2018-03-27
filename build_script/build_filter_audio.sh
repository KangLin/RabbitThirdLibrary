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

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/filter_audio
fi

echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    if [ "TRUE" = "$RABBIT_USE_REPOSITORIES" ]; then
        echo "git clone -q https://github.com/irungentoo/filter_audio.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q  https://github.com/irungentoo/filter_audio.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q  https://github.com/irungentoo/filter_audio/archive/master.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/irungentoo/filter_audio/archive/master.zip
        unzip -q  master.zip
        mv filter_audio-master ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f filter_audio-master ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

#清理
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    if [ -d ".git" ]; then
        echo "clean ..."
        git clean -xdf
    fi
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

echo "configure ..."

case ${RABBIT_BUILD_TARGERT} in
    android)
        export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
        export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="${CFLAGS}"
    ;;
    unix)
        ;;
    windows_msvc)
        echo "build_speex.sh don't support windows_msvc. please manually use msvc ide complie"
        cd $CUR_DIR
        exit 2
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
                export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
                export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
                export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
                export AS=${RABBIT_BUILD_CROSS_PREFIX}as
                export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
                export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        esac
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 3
    ;;
esac

echo "make install"
make ${RABBIT_MAKE_JOB_PARA} VERBOSE=1 && make install PREFIX=${RABBIT_BUILD_PREFIX}
if [ -f "${RABBIT_BUILD_PREFIX}/lib/libfilteraudio.dll" ]; then
    mv ${RABBIT_BUILD_PREFIX}/lib/libfilteraudio.dll ${RABBIT_BUILD_PREFIX}/bin
fi

cd $CUR_DIR
