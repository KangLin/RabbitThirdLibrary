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
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

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
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/gdal
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    GDAL_VERSION=2.1.2
    if [ "TRUE" = "${RABBITIM_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=tags/${GDAL_VERSION} https://github.com/OSGeo/gdal ${RABBITIM_BUILD_SOURCE_CODE}"
        git clone -q --branch=tags/$GDAL_VERSION https://github.com/OSGeo/gdal ${RABBITIM_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBITIM_BUILD_SOURCE_CODE}
        echo "wget -q https://github.com/OSGeo/gdal/archive/tags/${GDAL_VERSION}.zip"
        cd ${RABBITIM_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/OSGeo/gdal/archive/tags/${GDAL_VERSION}.zip
        unzip -q ${GDAL_VERSION}.zip
        mv gdal-tags-${GDAL_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBITIM_BUILD_SOURCE_CODE}
        mv -f gdal-tags-${GDAL_VERSION} ${RABBITIM_BUILD_SOURCE_CODE}
    fi
fi

RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_SOURCE_CODE}/gdal
cd ${RABBITIM_BUILD_SOURCE_CODE}

if [ "${RABBITIM_CLEAN}" = "TRUE" ]; then
    if [ -d "../.git" ]; then
        echo "git clean -xdf"
        git clean -xdf
    else
        if [ "${RABBITIM_BUILD_TARGERT}" != "windows_msvc" -a -f Makefile ]; then
            ${MAKE} clean
        fi
    fi
fi
#mkdir -p build_${RABBITIM_BUILD_TARGERT}
#cd build_${RABBITIM_BUILD_TARGERT}
#if [ -n "$RABBITIM_CLEAN" ]; then
#    rm -fr *
#fi

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

echo "configure ..."
MAKE=make
if [ "$RABBITIM_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared --without-ld-shared"
    export LDFLAGS="-static"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBITIM_BUILD_TARGERT} in
    android)
        #https://github.com/nutiteq/gdal/wiki/AndroidHowto
        export CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc 
        export CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++
        export AR=${RABBITIM_BUILD_CROSS_PREFIX}ar
        export LD=${RABBITIM_BUILD_CROSS_PREFIX}ld
        export AS=${RABBITIM_BUILD_CROSS_PREFIX}as
        export STRIP=${RABBITIM_BUILD_CROSS_PREFIX}strip
        export NM=${RABBITIM_BUILD_CROSS_PREFIX}nm
        LIBS="-lstdc++"
        CONFIG_PARA="CXX=${RABBITIM_BUILD_CROSS_PREFIX}g++ LD=${RABBITIM_BUILD_CROSS_PREFIX}ld"
        #CONFIG_PARA="${CONFIG_PARA} --disable-shared -enable-static"
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBITIM_BUILD_CROSS_HOST"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        #CONFIG_PARA="$CONFIG_PARA --with-curl=$RABBITIM_BUILD_PREFIX/bin"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT} "
        CXXFLAGS="-march=armv7-a -mfpu=neon -std=c++0x --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT} ${RABBITIM_BUILD_CROSS_STL_INCLUDE_FLAGS}"
        CPPFLAGS=${CXXFLAGS}
        if [ -n "${RABBITIM_BUILD_CROSS_STL_LIBS}" ]; then
            LDFLAGS="-L${RABBITIM_BUILD_CROSS_STL_LIBS}"
        fi
        ;;
    unix)
        ;;
    windows_msvc)
        cd ${RABBITIM_BUILD_SOURCE_CODE}
        echo "nmake -f makefile.vc MSVC_VER=${MSVC_VER} GDAL_HOME=${RABBITIM_BUILD_PREFIX}"
        nmake -f makefile.vc clean
        #sed -i "s,INSTALL	=	xcopy /y /r /d /f /I,INSTALL=cp -fr,g" nmake.opt
        export MSVC_VER=${MSVC_VER}
        export GDAL_HOME="${RABBITIM_BUILD_PREFIX}" 
        export BINDIR=$GDAL_HOME/bin
        export PLUGINDIR=$BINDIR/gdalplugins
        export LIBDIR=$GDAL_HOME/lib
        export INCDIR=$GDAL_HOME/include
        export DATADIR=$GDAL_HOME/data
        export HTMLDIR=$GDAL_HOME/html
        #export GEOS_CFLAGS="-I${RABBITIM_BUILD_PREFIX}/include -I${RABBITIM_BUILD_PREFIX}/include/geos -DHAVE_GEOS" 
        #export GEOS_LIB="${RABBITIM_BUILD_PREFIX}/lib/geos_c_i.lib" 
        export CURL_INC="-I${RABBITIM_BUILD_PREFIX}/include"
        export CURL_LIB="${RABBITIM_BUILD_PREFIX}/lib/libcurl.lib wsock32.lib wldap32.lib winmm.lib"
        nmake -f makefile.vc
        cp *.dll ${RABBITIM_BUILD_PREFIX}/bin
        cp *.lib ${RABBITIM_BUILD_PREFIX}/lib
        cp apps/*.exe ${RABBITIM_BUILD_PREFIX}/bin
        cp port/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp gcore/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp alg/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp ogr/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp frmts/mem/memdataset.h ${RABBITIM_BUILD_PREFIX}/include
        cp frmts/raw/rawdataset.h ${RABBITIM_BUILD_PREFIX}/include
        cp frmts/vrt/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp ogr/ogrsf_frmts/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp gnm/*.h ${RABBITIM_BUILD_PREFIX}/include
        cp apps/gdal_utils.h ${RABBITIM_BUILD_PREFIX}/include
        cd $CUR_DIR
        exit 0
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*)
                CONFIG_PARA="${CONFIG_PARA} CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc --host=${RABBITIM_BUILD_CROSS_HOST} "
                CONFIG_PARA="${CONFIG_PARA}"
                ;;
            MINGW* | MSYS*)
                ;;
            *)
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
echo "pwd:`pwd`"
CONFIG_PARA="${CONFIG_PARA} --prefix=${RABBITIM_BUILD_PREFIX} "

echo "./configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" 
     CPPFLAGS=\"${CPPFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\" 
     LDFLAGS=\"$LDFLAGS\" LIBS=\"$LIBS\""
./configure ${CONFIG_PARA} CFLAGS="${CFLAGS}" \
    CPPFLAGS="${CPPFLAGS}" CXXFLAGS="${CXXFLAGS}" \
    LDFLAGS="$LDFLAGS" LIBS="$LIBS" --with-curl=${RABBITIM_BUILD_PREFIX}/bin/curl-config #\
    #--with-geos=${RABBITIM_BUILD_PREFIX}/bin/geos-config

${MAKE} ${RABBITIM_MAKE_JOB_PARA}
${MAKE} install

cd $CUR_DIR
