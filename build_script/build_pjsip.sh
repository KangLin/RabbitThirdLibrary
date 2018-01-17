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

if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/pjsip
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    PJSIP_VERSION=2.4
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "svn co http://svn.pjsip.org/repos/pjproject/trunk ${RABBIT_BUILD_SOURCE_CODE}"
        svn co http://svn.pjsip.org/repos/pjproject/trunk ${RABBIT_BUILD_SOURCE_CODE}
        #echo "git svn clone http://svn.pjsip.org/repos/pjproject/tags/2.4/ ${RABBIT_BUILD_SOURCE_CODE}"
        #git svn clone http://svn.pjsip.org/repos/pjproject/tags/2.4/ ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q http://www.pjsip.org/release/${PJSIP_VERSION}/pjproject-${PJSIP_VERSION}.tar.bz2"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c  http://www.pjsip.org/release/${PJSIP_VERSION}/pjproject-${PJSIP_VERSION}.tar.bz2
        tar -jxf pjproject-${PJSIP_VERSION}.tar.bz2
        mv pjproject-${PJSIP_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f pjproject-${PJSIP_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

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


if [ -n "$RABBIT_CLEAN" -a -f "build.mak" ]; then
    echo "make clean"
    make dep;make clean
fi

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX"
case ${RABBIT_BUILD_TARGERT} in
    android)
        echo "#define PJ_CONFIG_ANDROID 1" > ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        echo "#define PJMEDIA_HAS_VIDEO 1" >> ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        echo "#include <pj/config_site_sample.h>" >> ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        export APP_PLATFORM=$ANDROID_NATIVE_API_LEVEL
        export ANDROID_NDK_PLATFORM=$ANDROID_NATIVE_API_LEVEL
        export TARGET_ABI=$ANDROID_ABI
        echo "./configure-android --use-ndk-cflags ${CONFIG_PARA}"
        ./configure-android --use-ndk-cflags ${CONFIG_PARA} 
        ;;
    unix)
        ;;
    windows_msvc)
        echo "#define PJMEDIA_HAS_VIDEO 1" > ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        echo "#define PJMEDIA_VIDEO_DEV_HAS_DSHOW 1" >> ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        msbuild.exe pjproject-vs8.sln -m -t:Rebuild -p:Configuration=Release -p:Platform=Win32
        cd $CUR_DIR
        exit 2
        ;;
    windows_mingw)
    case `uname -s` in
        Linux*|Unix*|CYGWIN*)
            export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
            export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
            export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
            export LD=${RABBIT_BUILD_CROSS_PREFIX}gcc
            export AS=yasm
            export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
            export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
            ;;
        *)
        ;;
    esac
        echo "#define PJMEDIA_HAS_VIDEO 1" > ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        #echo "#define PJMEDIA_VIDEO_DEV_HAS_DSHOW 1" >> ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        echo "#define PJMEDIA_HAS_FFMPEG 1" >> ${RABBIT_BUILD_SOURCE_CODE}/pjlib/include/pj/config_site.h
        echo "./configure ${CONFIG_PARA}"
        ./configure ${CONFIG_PARA}
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 3
    ;;
esac

echo "make install"
make ${RABBIT_MAKE_JOB_PARA} VERBOSE=1 
make install

cd $CUR_DIR
