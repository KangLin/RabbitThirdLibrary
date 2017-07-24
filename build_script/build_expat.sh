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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/expat
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    VERSION=2_2_0
    WGET_VERSION=2.2.0
    #if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
    #    echo "git clone -q --branch=R_${VERSION} git://git.code.sf.net/p/expat/code_git ${RABBIT_BUILD_SOURCE_CODE}"
    #    git clone --branch=R_${VERSION} git://git.code.sf.net/p/expat/code_git ${RABBIT_BUILD_SOURCE_CODE}
    #else
        echo "wget -c -nv -O expat.tar.bz2 https://sourceforge.net/projects/expat/files/expat/${WGET_VERSION}/expat-${WGET_VERSION}.tar.bz2/download"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -c -nv -O expat.tar.bz2 https://sourceforge.net/projects/expat/files/expat/${WGET_VERSION}/expat-${WGET_VERSION}.tar.bz2/download
        tar -xf expat.tar.bz2
        mv expat-${WGET_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f expat-${WGET_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    #fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}
if [ -d expat ]; then
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_SOURCE_CODE}/expat
    cd ${RABBIT_BUILD_SOURCE_CODE}
fi

if [ ! -f configure ]; then
    echo "sh buildconf.sh"
    sh buildconf.sh
fi

mkdir -p build_${RABBIT_BUILD_TARGERT}
cd build_${RABBIT_BUILD_TARGERT}
if [ "$RABBIT_CLEAN" = "TRUE" ]; then
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
echo ""

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。
MAKE_PARA="-- ${RABBIT_MAKE_JOB_PARA}"

if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
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
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        if [ "${RABBIT_ARCH}" = "arm" ]; then
            CFLAGS="-march=armv7-a -mfpu=neon"
            CPPFLAGS="-march=armv7-a -mfpu=neon"
        fi
        CFLAGS="${CFLAGS} --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="${CPPFLAGS} --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
    ;;
    unix)
    ;;
    windows_msvc)
        sed -i "s/add_custom_command.*//g" ../CMakeLists.txt
        CMAKE_PARA="-DBUILD_tests=OFF -DBUILD_examples=OFF -DBUILD_tools=OFF"
        echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBIT_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${GENERATORS}\" ${CMAKE_PARA}"
        cmake .. \
            -DCMAKE_INSTALL_PREFIX="$RABBIT_BUILD_PREFIX" \
            -DCMAKE_BUILD_TYPE="Release" \
            -G"${GENERATORS}" ${CMAKE_PARA} 
        
        cmake --build . --target install --config Release #{MAKE_PARA}
        exit 0
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
                CONFIG_PARA="${CONFIG_PARA} CC=${RABBIT_BUILD_CROSS_PREFIX}gcc"
                CONFIG_PARA="${CONFIG_PARA} --host=${RABBIT_BUILD_CROSS_HOST}"
                ;;
            *)
            ;;
        esac   
        ;;
    *)
    echo "${HELP_STRING}"
    cd $CUR_DIR
    return 2
    ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make ${RABBIT_MAKE_JOB_PARA} 
make install

cd $CUR_DIR
