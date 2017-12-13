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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/openssl
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    OPENSLL_BRANCH=OpenSSL_1_1_0g
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=${OPENSLL_BRANCH} https://github.com/openssl/openssl ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=${OPENSLL_BRANCH} https://github.com/openssl/openssl ${RABBIT_BUILD_SOURCE_CODE}
        #git clone -q https://github.com/openssl/openssl ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -q https://github.com/openssl/openssl/archive/${OPENSLL_BRANCH}.zip"
        wget -q -c https://github.com/openssl/openssl/archive/${OPENSLL_BRANCH}.zip
        unzip -q ${OPENSLL_BRANCH}.zip
        mv openssl-${OPENSLL_BRANCH} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f openssl-${OPENSLL_BRANCH} ${RABBIT_BUILD_SOURCE_CODE}
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
echo "PATH:$PATH"
echo ""

if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    if [ -d ".git" ]; then
        git clean -xdf
    else
        if [ "${RABBIT_BUILD_TARGERT}" = "windows_msvc" ]; then
            if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
                if [ -f ms/nt.mak ]; then
                    nmake clean
                fi
            else
                if [ -f ms/ntdll.mak ]; then
                    nmake clean
                fi
            fi
        else
            if [ -f Makefile ]; then
                ${MAKE} clean
            fi
        fi
    fi
fi

if [ "$RABBIT_BUILD_STATIC" != "static" ]; then
    MODE=shared
else
    MODE="no-shared no-pic"
fi

echo "configure ..."
case ${RABBIT_BUILD_TARGERT} in
    android)
        #export ANDROID_DEV="${RABBIT_BUILD_CROSS_SYSROOT}/usr"
        export LDFLAGS="--sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        if [ "${RABBIT_ARCH}" = "arm" ]; then
            CFLAGS="-march=armv7-a -mfpu=neon"
            CPPFLAGS="-march=armv7-a -mfpu=neon"
        fi
        CFLAGS="${CFLAGS} --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="${CPPFLAGS} --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        perl Configure --cross-compile-prefix=${RABBIT_BUILD_CROSS_PREFIX} \
                --prefix=${RABBIT_BUILD_PREFIX} \
                --openssldir=${RABBIT_BUILD_PREFIX} \
                $MODE \
                android-armeabi --sysroot="${RABBIT_BUILD_CROSS_SYSROOT}" -march=armv7-a -mfpu=neon
        ;;
    unix)
        ./config --prefix=${RABBIT_BUILD_PREFIX} --openssldir=${RABBIT_BUILD_PREFIX} $MODE
        ;;
    windows_msvc)
        if [ "$RABBIT_ARCH" = "x64" ]; then
            perl Configure \
                --prefix=${RABBIT_BUILD_PREFIX} \
                --openssldir=${RABBIT_BUILD_PREFIX} \
                VC-WIN64A-masm 
        else
            perl Configure \
                --prefix=${RABBIT_BUILD_PREFIX} \
                --openssldir=${RABBIT_BUILD_PREFIX} \
                VC-WIN32
        fi
        ;;
    windows_mingw)
        if [ "$RABBIT_ARCH" = "x64" ]; then
            ARCH=64
        fi
        case `uname -s` in
            MINGW*|MSYS*)
                perl Configure --prefix=${RABBIT_BUILD_PREFIX} \
                    --openssldir=${RABBIT_BUILD_PREFIX} \
                    $MODE \
                    zlib --with-zlib-lib=${RABBIT_BUILD_PREFIX}/lib \
                    --with-zlib-include=${RABBIT_BUILD_PREFIX}/include \
                    mingw${ARCH}
                ;;
            Linux*|Unix*|CYGWIN*|*)
                perl Configure --prefix=${RABBIT_BUILD_PREFIX} \
                    --openssldir=${RABBIT_BUILD_PREFIX} \
                    --cross-compile-prefix=${RABBIT_BUILD_CROSS_PREFIX} \
                    $MODE \
                    zlib --with-zlib-lib=${RABBIT_BUILD_PREFIX}/lib \
                    --with-zlib-include=${RABBIT_BUILD_PREFIX}/include \
                    mingw${ARCH}
                ;;
        esac
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 3
        ;;
esac

echo "make install"
if [ "${RABBIT_BUILD_TARGERT}" = "windows_msvc" ]; then
    ${MAKE}
else
    ${MAKE} ${RABBIT_MAKE_JOB_PARA}
fi
${MAKE} install

cd $CUR_DIR
