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

RABBIT_BUILD_SOURCE_CODE=$2
echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh

if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libpng
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=1.6.34
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=v${VERSION} https://github.com/glennrp/libpng.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=v$VERSION https://github.com/glennrp/libpng.git ${RABBIT_BUILD_SOURCE_CODE}
        #echo "git clone -q --branch=v$VERSION https://git.code.sf.net/p/libpng/code ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q --branch=v$VERSION https://git.code.sf.net/p/libpng/code ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -nv -c https://github.com/glennrp/libpng/archive/v${VERSION}.zip"
        wget -nv -c https://github.com/glennrp/libpng/archive/v${VERSION}.zip
        unzip -q v${VERSION}.zip
        mv libpng-${VERSION} ..
        rm -fr v${VERSION}.zip ${RABBIT_BUILD_SOURCE_CODE}
        cd ..
        mv libpng-${VERSION} ${RABBIT_BUILD_SOURCE_CODE}
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
echo "PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo ""

if [ ! -f configure ]; then
    echo "sh autogen.sh"
    sh autogen.sh
else
    if [ -f Makefile ]; then
        make distclean
    fi
fi

mkdir -p build_${RABBIT_BUILD_TARGERT}
cd build_${RABBIT_BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBIT_BUILD_TARGERT} in
    android)
        CONFIG_PARA="--enable-static --disable-shared"
        #export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        #export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        #export AR=${RABBIT_BUILD_CROSS_PREFIX}gcc-ar
        #export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        #export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        #export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        #export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        CONFIG_PARA="CC=${RABBIT_BUILD_CROSS_PREFIX}gcc LD=${RABBIT_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
        #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        LDFLAGS="${RABBIT_LDFLAGS}"
        ;;   
    unix)
        ;;
    windows_mingw)
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
        #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        LDFLAGS="${RABBIT_LDFLAGS}"
        ;;
    windows_msvc)
        if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
            CMAKE_PARA="-DPNG_STATIC=ON -DPNG_SHARED=OFF"
        else
            CMAKE_PARA="-DPNG_STATIC=OFF -DPNG_SHARED=ON"
        fi
        echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${RABBITIM_GENERATORS}\" ${CMAKE_PARA}"
        cmake .. \
            -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
            -G"${RABBITIM_GENERATORS}" ${CMAKE_PARA} 
        
        cmake --build . --target install --config Release ${MAKE_PARA}
        cd $CUR_DIR
        exit 0
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

CONFIG_PARA="${CONFIG_PARA} --with-zlib-prefix=$RABBIT_BUILD_PREFIX "
CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\" CXXFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\""
../configure ${CONFIG_PARA} \
    CFLAGS="${CFLAGS}" \
    CPPFLAGS="${CPPFLAGS}" \
    CXXFLAGS="${CPPFLAGS}" \
    LDFLAGS="${LDFLAGS}"
    
echo "make install"
make V=1 ${RABBIT_MAKE_JOB_PARA} 
make install

cd $CUR_DIR
