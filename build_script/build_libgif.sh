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

echo ". `pwd`/build_envsetup_${BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${BUILD_TARGERT}.sh

if [ -z "$RABBIT_BUILD_SOURCE_CODE" ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/libgif
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=master
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        #echo "git clone -q --branch=${VERSION} https://git.code.sf.net/p/giflib/code ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q --branch=$VERSION https://git.code.sf.net/p/giflib/code ${RABBIT_BUILD_SOURCE_CODE}
        echo "git clone -q https://github.com/KangLin/giflib.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q https://github.com/KangLin/giflib.git ${RABBIT_BUILD_SOURCE_CODE}
        if [ "$VERSION" != "master" ]; then
            git checkout -b $VERSION $VERSION
        fi
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -nv -c -O giflib-${VERSION}.zip https://github.com/KangLin/giflib/archive/${VERSION}.zip"
        wget -nv -c -O giflib-${VERSION}.zip https://github.com/KangLin/giflib/archive/${VERSION}.zip
        unzip giflib-${VERSION}.zip
        mv giflib-${VERSION} ..
        rm -fr giflib-${VERSION}.zip ${RABBIT_BUILD_SOURCE_CODE}
        cd ..
        mv giflib-${VERSION} ${RABBIT_BUILD_SOURCE_CODE} 
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

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
echo "PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo ""

if [ ! -f configure -a "windows_msvc" != "${BUILD_TARGERT}" ]; then
    echo "sh autogen.sh"
    aclocal
    autoheader
    case `uname` in Darwin*) glibtoolize --automake ;;
      *) libtoolize --automake ;; esac
    automake --add-missing
    autoconf
    automake
fi

mkdir -p build_${BUILD_TARGERT}
cd build_${BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${BUILD_TARGERT} in
    android)
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
        cd ${RABBIT_BUILD_SOURCE_CODE}/lib
        rm -f *.lib *.obj
        echo "" > unistd.h
        cp ../util/qprintf.c ../util/getarg.* . 
        nmake -f Makefile.ms clean
        nmake -f Makefile.ms
        cp -f gif_lib.h $RABBIT_BUILD_PREFIX/include
        mv -f giflib.lib $RABBIT_BUILD_PREFIX/lib/libgif.lib
        rm -f qprintf.c getarg.* unistd.h
        cd $CUR_DIR
        exit 0
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    exit 2
    ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX" #--with-zlib-prefix=$RABBIT_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure ${CONFIG_PARA} \
    CFLAGS="${CFLAGS}" \
    CPPFLAGS="${CPPFLAGS}" \
    CXXFLAGS="${CPPFLAGS}" \
    LDFLAGS="${LDFLAGS}"

echo "make install"
make ${BUILD_JOB_PARA} V=1
make install

cd $CUR_DIR
