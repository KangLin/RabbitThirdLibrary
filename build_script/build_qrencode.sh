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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libqrencode
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=3.4.3
    #if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q https://github.com/fukuchi/libqrencode.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/fukuchi/libqrencode.git ${RABBIT_BUILD_SOURCE_CODE}
    #else
    #    echo "wget -q https://github.com/fukuchi/libqrencode/archive/v${VERSION}.tar.gz"
    #    mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
    #    cd ${RABBIT_BUILD_SOURCE_CODE}
    #    wget -q -c http://fukuchi.org/works/qrencode/qrencode-3.4.4.tar.gz
    #    tar xf qrencode-3.4.4.tar.gz
    #    mv qrencode-3.4.4  ..
    #    rm -fr *
    #    cd ..
    #    rm -fr ${RABBIT_BUILD_SOURCE_CODE}
    #    mv -f qrencode-3.4.4 ${RABBIT_BUILD_SOURCE_CODE}
    #fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    if [ -d ".git" ]; then
        echo "git clean -xdf"
        git clean -xdf
    fi
fi

if [ ! -f configure -a "windows_msvc" != "${RABBIT_BUILD_TARGERT}" ]; then
    mkdir -p m4
    echo "sh autogen.sh"
    sh autogen.sh
fi

mkdir -p build_${RABBIT_BUILD_TARGERT}
cd build_${RABBIT_BUILD_TARGERT}
if [ -n "$RABBIT_CLEAN" ]; then
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
echo "PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo "PATH:${PATH}"
echo ""

echo "configure ..."
MAKE=make

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
MAKE_PARA=" ${RABBIT_MAKE_JOB_PARA} "
case ${RABBIT_BUILD_TARGERT} in
    android)
        export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
        export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        CONFIG_PARA="CC=${RABBIT_BUILD_CROSS_PREFIX}gcc LD=${RABBIT_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --disable-shared -enable-static --host=$RABBIT_BUILD_CROSS_HOST"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_PREFIX}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        ;;
    unix)
        ;;
    windows_msvc)
        cmake .. -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
            -DCMAKE_BUILD_TYPE="Release" \
            -G"${GENERATORS}" -DWITH_TOOLS=OFF \
            -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
        cmake --build . --target install --config Release 
        cd $CUR_DIR
        exit 0
        ;;
    windows_mingw)
        CONFIG_PARA="${CONFIG_PARA} CC=${RABBIT_BUILD_CROSS_PREFIX}gcc --host=${RABBIT_BUILD_CROSS_HOST} "
        CONFIG_PARA="${CONFIG_PARA} --with-gnu-ld"
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 3
        ;;
esac

echo "make install"
echo "pwd:`pwd`"
CONFIG_PARA="${CONFIG_PARA} --prefix=${RABBIT_BUILD_PREFIX} "
CONFIG_PARA="${CONFIG_PARA} --without-tools" # --without-png --without-sdl"

if [ "${RABBIT_BUILD_TARGERT}" = android ]; then
    echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\""
    CFLAGS="-mthumb" CXXFLAGS="-mthumb" ../configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"
else
    echo "../configure ${CONFIG_PARA}"
    ../configure ${CONFIG_PARA}
fi

${MAKE} ${MAKE_PARA}
${MAKE} install

if [ "${RABBIT_BUILD_TARGERT}" = "windows_msvc" ]; then
    cd ${RABBIT_BUILD_PREFIX}/lib
    mv libqrencode.a qrencode.lib
fi

cd $CUR_DIR
