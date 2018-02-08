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

echo ". `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${RABBIT_BUILD_TARGERT}.sh

if [ -n "$2" ]; then
    RABBIT_BUILD_SOURCE_CODE=$2
else
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/gdal
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    GDAL_VERSION=2.2.3
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone -q --branch=tags/${GDAL_VERSION} https://github.com/OSGeo/gdal.git ${RABBIT_BUILD_SOURCE_CODE}"
        git clone -q --branch=tags/$GDAL_VERSION https://github.com/OSGeo/gdal.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        echo "wget -q https://github.com/OSGeo/gdal/archive/tags/${GDAL_VERSION}.zip"
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/OSGeo/gdal/archive/tags/${GDAL_VERSION}.zip
        unzip -q ${GDAL_VERSION}.zip
        mv gdal-tags-${GDAL_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f gdal-tags-${GDAL_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_SOURCE_CODE}/gdal
cd ${RABBIT_BUILD_SOURCE_CODE}

if [ "${RABBIT_CLEAN}" = "TRUE" ]; then
    if [ -d "../.git" ]; then
        echo "git clean -xdf"
        git clean -xdf
        rm configure
    else
        if [ "${RABBIT_BUILD_TARGERT}" != "windows_msvc" -a -f Makefile ]; then
            ${MAKE} clean
        fi
    fi
fi

if [ ! -f configure ]; then
    ./autogen.sh
fi

#mkdir -p build_${RABBIT_BUILD_TARGERT}
#cd build_${RABBIT_BUILD_TARGERT}
#if [  "${RABBIT_CLEAN}" = "TRUE" ]; then
#    rm -fr *
#fi

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
MAKE=make
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--enable-static --disable-shared --without-ld-shared"
    export LDFLAGS="-static"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
case ${RABBIT_BUILD_TARGERT} in
    unix)
        ;;
    android|windows_mingw)
        #https://github.com/nutiteq/gdal/wiki/AndroidHowto
        #export CC=${RABBIT_BUILD_CROSS_PREFIX}gcc 
        #export CXX=${RABBIT_BUILD_CROSS_PREFIX}g++
        #export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
        #export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
        #export AS=${RABBIT_BUILD_CROSS_PREFIX}as
        #export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
        #export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
        #CONFIG_PARA="CC=${RABBIT_BUILD_CROSS_PREFIX}gcc LD=${RABBIT_BUILD_CROSS_PREFIX}ld"
        CONFIG_PARA="${CONFIG_PARA} --host=$RABBIT_BUILD_CROSS_HOST"
        #CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS} -std=c++11"
        LDFLAGS="$LDFLAGS ${RABBIT_LDFLAGS}" # -lsupc++"
        export LIBS="-lstdc++" #-lsupc++
        ;;

    windows_msvc)
        cd ${RABBIT_BUILD_SOURCE_CODE}
        echo "nmake -f makefile.vc MSVC_VER=${MSVC_VER} GDAL_HOME=${RABBIT_BUILD_PREFIX}"
        nmake -f makefile.vc clean
        #sed -i "s,INSTALL	=	xcopy /y /r /d /f /I,INSTALL=cp -fr,g" nmake.opt
        export MSVC_VER=${MSVC_VER}
        export GDAL_HOME="${RABBIT_BUILD_PREFIX}" 
        export BINDIR=$GDAL_HOME/bin
        export PLUGINDIR=$BINDIR/gdalplugins
        export LIBDIR=$GDAL_HOME/lib
        export INCDIR=$GDAL_HOME/include
        export DATADIR=$GDAL_HOME/data
        export HTMLDIR=$GDAL_HOME/html
        #export GEOS_CFLAGS="-I${RABBIT_BUILD_PREFIX}/include -I${RABBIT_BUILD_PREFIX}/include/geos -DHAVE_GEOS" 
        #export GEOS_LIB="${RABBIT_BUILD_PREFIX}/lib/geos_c_i.lib" 
        export CURL_INC="-I${RABBIT_BUILD_PREFIX}/include"
        export CURL_LIB="${RABBIT_BUILD_PREFIX}/lib/libcurl.lib wsock32.lib wldap32.lib winmm.lib"
        if [ "${RABBIT_ARCH}" = "x64" ]; then
            nmake -f makefile.vc WIN64=YES
        else
            nmake -f makefile.vc
        fi
        cp *.dll ${RABBIT_BUILD_PREFIX}/bin
        cp *.lib ${RABBIT_BUILD_PREFIX}/lib
        cp apps/*.exe ${RABBIT_BUILD_PREFIX}/bin
        cp port/*.h ${RABBIT_BUILD_PREFIX}/include
        cp gcore/*.h ${RABBIT_BUILD_PREFIX}/include
        cp alg/*.h ${RABBIT_BUILD_PREFIX}/include
        cp ogr/*.h ${RABBIT_BUILD_PREFIX}/include
        cp frmts/mem/memdataset.h ${RABBIT_BUILD_PREFIX}/include
        cp frmts/raw/rawdataset.h ${RABBIT_BUILD_PREFIX}/include
        cp frmts/vrt/*.h ${RABBIT_BUILD_PREFIX}/include
        cp ogr/ogrsf_frmts/*.h ${RABBIT_BUILD_PREFIX}/include
        cp gnm/*.h ${RABBIT_BUILD_PREFIX}/include
        cp apps/gdal_utils.h ${RABBIT_BUILD_PREFIX}/include
        cd $CUR_DIR
        exit 0
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 3
        ;;
esac

echo "pwd:`pwd`"
CONFIG_PARA="${CONFIG_PARA} --with-geos=${RABBIT_BUILD_PREFIX}/bin/geos-config"
CONFIG_PARA="${CONFIG_PARA} --with-curl=${RABBIT_BUILD_PREFIX}/bin/curl-config"
CONFIG_PARA="${CONFIG_PARA} --with-png=${RABBIT_BUILD_PREFIX}"
CONFIG_PARA="${CONFIG_PARA} --with-expat=${RABBIT_BUILD_PREFIX}"
CONFIG_PARA="${CONFIG_PARA} --with-gif=${RABBIT_BUILD_PREFIX}"
CONFIG_PARA="${CONFIG_PARA} --with-jpeg=${RABBIT_BUILD_PREFIX}"
CONFIG_PARA="${CONFIG_PARA} --with-libtiff=${RABBIT_BUILD_PREFIX}"
CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX"
echo "../configure ${CONFIG_PARA} CFLAGS=\"${CFLAGS=}\" CPPFLAGS=\"${CPPFLAGS}\" CXXFLAGS=\"${CPPFLAGS}\" LDFLAGS=\"${LDFLAGS}\""
./configure ${CONFIG_PARA} \
    CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" CXXFLAGS="${CPPFLAGS}" \
    LDFLAGS="${LDFLAGS}"

${MAKE} V=1 # ${RABBIT_MAKE_JOB_PARA}
echo "make install ....................................."
${MAKE} install

cd $CUR_DIR
