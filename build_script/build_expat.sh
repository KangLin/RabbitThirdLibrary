#!/bin/bash

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBITIM_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix)
#   RABBITIM_BUILD_PREFIX=`pwd`/../${RABBITIM_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBITIM_BUILD_SOURCE_CODE    #源码目录
#   RABBITIM_BUILD_CROSS_PREFIX   #交叉编译前缀
#   RABBITIM_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM(android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
    RABBITIM_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

if [ -z "${RABBITIM_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${RABBITIM_BUILD_TARGERT}.sh
fi

if [ -n "$2" ]; then
    RABBITIM_BUILD_SOURCE_CODE=$2
else
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/expat
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    VERSION=2_2_0
    WGET_VERSION=2.2.0
    #if [ "TRUE" = "${RABBITIM_USE_REPOSITORIES}" ]; then
    #    echo "git clone -q --branch=R_${VERSION} git://git.code.sf.net/p/expat/code_git ${RABBITIM_BUILD_SOURCE_CODE}"
    #    git clone --branch=R_${VERSION} git://git.code.sf.net/p/expat/code_git ${RABBITIM_BUILD_SOURCE_CODE}
    #else
        echo "wget -c -nv -O expat.tar.bz2 https://sourceforge.net/projects/expat/files/expat/${WGET_VERSION}/expat-${WGET_VERSION}.tar.bz2/download"
        mkdir -p ${RABBITIM_BUILD_SOURCE_CODE}
        cd ${RABBITIM_BUILD_SOURCE_CODE}
        wget -c -nv -O expat.tar.bz2 https://sourceforge.net/projects/expat/files/expat/${WGET_VERSION}/expat-${WGET_VERSION}.tar.bz2/download
        tar -xf expat.tar.bz2
        mv expat-${WGET_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBITIM_BUILD_SOURCE_CODE}
        mv -f expat-${WGET_VERSION} ${RABBITIM_BUILD_SOURCE_CODE}
    #fi
fi

cd ${RABBITIM_BUILD_SOURCE_CODE}
if [ -d expat ]; then
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_SOURCE_CODE}/expat
    cd ${RABBITIM_BUILD_SOURCE_CODE}
fi

if [ ! -f configure ]; then
    echo "sh buildconf.sh"
    sh buildconf.sh
fi

mkdir -p build_${RABBITIM_BUILD_TARGERT}
cd build_${RABBITIM_BUILD_TARGERT}
if [ "$RABBITIM_CLEAN" = "TRUE" ]; then
    rm -fr *
fi

echo ""
echo "RABBITIM_BUILD_TARGERT:${RABBITIM_BUILD_TARGERT}"
echo "RABBITIM_BUILD_SOURCE_CODE:$RABBITIM_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBITIM_BUILD_PREFIX:$RABBITIM_BUILD_PREFIX"
echo "RABBITIM_BUILD_HOST:$RABBITIM_BUILD_HOST"
echo "RABBITIM_BUILD_CROSS_HOST:$RABBITIM_BUILD_CROSS_HOST"
echo "RABBITIM_BUILD_CROSS_PREFIX:$RABBITIM_BUILD_CROSS_PREFIX"
echo "RABBITIM_BUILD_CROSS_SYSROOT:$RABBITIM_BUILD_CROSS_SYSROOT"
echo "RABBITIM_BUILD_STATIC:$RABBITIM_BUILD_STATIC"
echo ""

#需要设置 CMAKE_MAKE_PROGRAM 为 make 程序路径。
MAKE_PARA="-- ${RABBITIM_MAKE_JOB_PARA}"

if [ "$RABBITIM_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBITIM_BUILD_TARGERT} in
    android)
        export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
        export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
        export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
        export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
        export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
        CONFIG_PARA="CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc LD=${RABBITIM_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --disable-shared -enable-static --host=$RABBITIM_BUILD_CROSS_HOST"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
    ;;
    unix)
    ;;
    windows_msvc)
        sed -i "s/add_custom_command.*//g" ../CMakeLists.txt
        CMAKE_PARA="-DBUILD_tests=OFF -DBUILD_examples=OFF -DBUILD_tools=OFF"
        echo "cmake .. -DCMAKE_INSTALL_PREFIX=$RABBITIM_BUILD_PREFIX -DCMAKE_BUILD_TYPE=Release -G\"${GENERATORS}\" ${CMAKE_PARA}"
        cmake .. \
            -DCMAKE_INSTALL_PREFIX="$RABBITIM_BUILD_PREFIX" \
            -DCMAKE_BUILD_TYPE="Release" \
            -G"${GENERATORS}" ${CMAKE_PARA} 
        
        cmake --build . --target install --config Release #{MAKE_PARA}
        exit 0
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
                export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
                export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
                export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
                export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
                export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
                export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
                CONFIG_PARA="${CONFIG_PARA} CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc"
                CONFIG_PARA="${CONFIG_PARA} --host=${RABBITIM_BUILD_CROSS_HOST}"
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

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBITIM_BUILD_PREFIX "
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make ${RABBITIM_MAKE_JOB_PARA} 
make install

cd $CUR_DIR
