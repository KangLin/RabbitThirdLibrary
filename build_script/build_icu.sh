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

echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/icu
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        #echo "git clone -q  https://github.com/svn2github/libicu.git ${RABBIT_BUILD_SOURCE_CODE}/source"
        #git clone -q  https://github.com/svn2github/libicu.git ${RABBIT_BUILD_SOURCE_CODE}
        echo "svn co http://source.icu-project.org/repos/icu/icu/trunk/ ${RABBIT_BUILD_SOURCE_CODE}"
        svn co http://source.icu-project.org/repos/icu/icu/trunk/ ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c http://download.icu-project.org/files/icu4c/56.1/icu4c-56_1-src.zip ${RABBIT_BUILD_SOURCE_CODE}
        mv icu4c-56_1-src.tgz ..
        cd ..
        rm -fr icu
        tar xf icu4c-56_1-src.tgz
        cd icu
        rm icu4c-56_1-src.tgz
    fi
fi

SOURCE_DIR=${RABBIT_BUILD_SOURCE_CODE}/source     #源代码目录
CONFIG_DIR=${RABBIT_BUILD_SOURCE_CODE}/temp_${RABBIT_BUILD_TARGERT}_Config #配置目录
BUILD_DIR=${RABBIT_BUILD_SOURCE_CODE}/temp_${RABBIT_BUILD_TARGERT}_Build   #编译目录
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr ${CONFIG_DIR} ${BUILD_DIR}
    mkdir -p ${BUILD_DIR} ${CONFIG_DIR}
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
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
    LDFLAGS="-static"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
MAKE=make
case ${RABBIT_BUILD_TARGERT} in
    android)
    ;;
    unix)
        cd ${CONFIG_DIR}
        ${SOURCE_DIR}/runConfigureICU Linux/gcc --prefix=${RABBIT_BUILD_PREFIX} ${CONFIG_PARA}
        ${MAKE}
        ${MAKE} install
        ;;
    windows_msvc)
        cd ${CONFIG_DIR}
        case `uname -s` in
            CYGWIN*)
            platform=Cygwin/MSVC
            ;;
            MINGW*|MSYS*)
            platform=MSYS/MSVC
            ;;
        esac
        ${SOURCE_DIR}/runConfigureICU ${platform} --prefix=${RABBIT_BUILD_PREFIX} ${CONFIG_PARA}
        ${MAKE}
        ${MAKE} install 
        if [ "$RABBIT_BUILD_STATIC" != "static" ]; then
            mv ${RABBIT_BUILD_PREFIX}/lib/icu*.dll ${RABBIT_BUILD_PREFIX}/bin/.
        fi
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                cd ${CONFIG_DIR}
                ${SOURCE_DIR}/runConfigureICU MinGW
                make ${RABBIT_MAKE_JOB_PARA}
                cd ${BUILD_DIR}
                ${SOURCE_DIR}/configure --host=${RABBIT_BUILD_CROSS_HOST} --with-cross_build=${CONFIG_DIR} --prefix=${RABBIT_BUILD_PREFIX} ${CONFIG_PARA}
                ${MAKE} ${RABBIT_MAKE_JOB_PARA} 
                ${MAKE} install 
                if [ "$RABBIT_BUILD_STATIC" != "static" ]; then
                    mv ${RABBIT_BUILD_PREFIX}/lib/icu*.dll ${RABBIT_BUILD_PREFIX}/bin/.
                fi
                ;;
            MINGW*|MSYS*)
                cd ${CONFIG_DIR}
                ${SOURCE_DIR}/runConfigureICU MinGW --prefix=${RABBIT_BUILD_PREFIX} ${CONFIG_PARA} LDFLAGS=${LDFLAGS}
                ${MAKE} 
                ${MAKE} install 
                if [ "$RABBIT_BUILD_STATIC" != "static" ]; then
                    mv ${RABBIT_BUILD_PREFIX}/lib/icu*.dll ${RABBIT_BUILD_PREFIX}/bin/.
                fi
                ;;
        esac
        ;;
    *)
        echo "${HELP_STRING}"
        exit 2
        ;;
esac

cd $CUR_DIR
