#!/bin/bash
#bash用法：
#   在用一sh进程中执行脚本script.sh:
#   source script.sh
#   . script.sh
#   注意这种用法，script.sh开头一行不能包含 #!/bin/sh

#   新建一个sh进程执行脚本script.sh:
#   sh script.sh
#   ./script.sh
#   注意这种用法，script.sh开头一行必须包含 #!/bin/sh

#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
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
    RABBIT_BUILD_SOURCE_CODE=${RABBIT_BUILD_PREFIX}/../src/ffmpeg
fi

CUR_DIR=`pwd`

#下载源码:
if [ ! -d ${RABBIT_BUILD_SOURCE_CODE} ]; then
    FFMPEG_VERSION=n4.2.2
    if [ "TRUE" = "${RABBIT_USE_REPOSITORIES}" ]; then
        echo "git clone git://source.ffmpeg.org/ffmpeg.git ${RABBIT_BUILD_SOURCE_CODE}"
        #git clone -q -b ${FFMPEG_VERSION} git://source.ffmpeg.org/ffmpeg.git ${RABBIT_BUILD_SOURCE_CODE}
        git clone -q -b ${FFMPEG_VERSION} git://source.ffmpeg.org/ffmpeg.git ${RABBIT_BUILD_SOURCE_CODE}
    else
        echo "wget -q https://github.com/FFmpeg/FFmpeg/archive/${FFMPEG_VERSION}.zip"
        mkdir -p ${RABBIT_BUILD_SOURCE_CODE}
        cd ${RABBIT_BUILD_SOURCE_CODE}
        wget -q -c https://github.com/FFmpeg/FFmpeg/archive/${FFMPEG_VERSION}.zip
        echo "unzip ${FFMPEG_VERSION}.zip"
        unzip -q ${FFMPEG_VERSION}.zip
        mv FFmpeg-${FFMPEG_VERSION} ..
        rm -fr *
        cd ..
        rm -fr ${RABBIT_BUILD_SOURCE_CODE}
        mv -f FFmpeg-${FFMPEG_VERSION} ${RABBIT_BUILD_SOURCE_CODE}
    fi
fi

cd ${RABBIT_BUILD_SOURCE_CODE}

echo "----------------------------------------------------------------------------"
echo "==== BUILD_TARGERT:${BUILD_TARGERT}"
echo "==== RABBIT_BUILD_SOURCE_CODE:$RABBIT_BUILD_SOURCE_CODE"
echo "==== CUR_DIR:`pwd`"
echo "==== RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "==== RABBIT_BUILD_HOST:$RABBIT_BUILD_HOST"
echo "==== RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "==== RABBIT_BUILD_CROSS_PREFIX:$RABBIT_BUILD_CROSS_PREFIX"
echo "==== RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "==== RABBIT_BUILD_STATIC:$RABBIT_BUILD_STATIC"
echo "==== PKG_CONFIG_PATH:${PKG_CONFIG_PATH}"
echo "==== PKG_CONFIG_LIBDIR:${PKG_CONFIG_LIBDIR}"
echo "----------------------------------------------------------------------------"

if [ "$RABBIT_CLEAN" = "TRUE" ]; then
    if [ -d ".git" ]; then
        git clean -xdf
    elif [ -f "config.mak" ]; then
        make distclean
    fi
fi

echo "configure ..."
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    CONFIG_PARA="--disable-shared"
    LDFLAGS="-static"
else
    CONFIG_PARA="--disable-static --enable-shared"
fi
#THIRD_LIB="--enable-libx264"
case ${BUILD_TARGERT} in
    android)
        CONFIG_PARA="${CONFIG_PARA} --enable-cross-compile"
        CONFIG_PARA="${CONFIG_PARA} --disable-w32threads"
        CONFIG_PARA="${CONFIG_PARA} --cross-prefix=${RABBIT_BUILD_CROSS_PREFIX}"
        CONFIG_PARA="${CONFIG_PARA} --sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
        CONFIG_PARA="${CONFIG_PARA} --cc=${CC} --cxx=${CXX}"
        #CONFIG_PARA="${CONFIG_PARA} --pkg-config="${PKG_CONFIG}"
        CONFIG_PARA="${CONFIG_PARA} --pkgconfigdir=${RABBIT_BUILD_PREFIX}/lib/pkgconfig"
        #CONFIG_PARA="${CONFIG_PARA} ${THIRD_LIB}"

        CONFIG_PARA="${CONFIG_PARA} --target-os=android"
        CONFIG_PARA="${CONFIG_PARA} --arch=$BUILD_ARCH"
        
        case $BUILD_ARCH in
            arm*)
                CONFIG_PARA="${CONFIG_PARA} --cpu=armv7-a --enable-neon"
                ;;
            x86*)
                #CONFIG_PARA="${CONFIG_PARA} --cpu=i586"
                CONFIG_PARA="${CONFIG_PARA} --x86asmexe==$YASM"
            ;;
        esac
        
        CONFIG_PARA="${CONFIG_PARA} --host-os=$RABBIT_BUILD_CROSS_HOST"
        CFLAGS="${RABBIT_CFLAGS}"
        CPPFLAGS="${RABBIT_CPPFLAGS}"
        #有 libvpx 才使用
        #LDFLAGS="${RABBIT_LDFLAGS} -lcpu-features"
        ;;
    unix)
        CONFIG_PARA="${CONFIG_PARA} ${THIRD_LIB}"
        ;;
    windows_msvc)
        if [ "$BUILD_ARCH" = "x64" ]; then
            CONFIG_PARA="${CONFIG_PARA} --target-os=win64 --arch=x86_64 --cpu=i686"
        else
            CONFIG_PARA="${CONFIG_PARA} --target-os=win32 --arch=i686 --cpu=i686"
        fi
        
        CONFIG_PARA="${CONFIG_PARA} --toolchain=msvc --enable-cross-compile"
        ;;
    windows_mingw)
        CONFIG_PARA="${CONFIG_PARA} --enable-cross-compile --target-os=mingw32 --arch=i686 --cpu=i686"
        CONFIG_PARA="${CONFIG_PARA} ${THIRD_LIB}"
        case `uname -s` in
            MINGW*|MSYS*)
                ;;
            Linux*|Unix*|CYGWIN*|*)
                CONFIG_PARA="${CONFIG_PARA} --cross-prefix=${RABBIT_BUILD_CROSS_PREFIX}"
                #CONFIG_PARA="${CONFIG_PARA} --pkg-config=${PKG_CONFIG}"
                CONFIG_PARA="${CONFIG_PARA} --pkgconfigdir=${RABBIT_BUILD_PREFIX}/lib/pkgconfig"
                ;;
            *)
            echo "Don't support tagert:`uname -s`, please see build_ffmpeg.sh"
            exit 3
        esac
        ;;
    *)
        echo "${HELP_STRING}"
        cd $CUR_DIR
        exit 2
        ;;
esac

CONFIG_PARA="${CONFIG_PARA} --prefix=$RABBIT_BUILD_PREFIX --enable-gpl --enable-pic --disable-doc --disable-htmlpages"
CONFIG_PARA="${CONFIG_PARA} --disable-manpages --disable-podpages --disable-txtpages  --disable-ffprobe"
CONFIG_PARA="${CONFIG_PARA} --disable-ffplay --disable-programs"
CONFIG_PARA="${CONFIG_PARA} --enable-runtime-cpudetect"
#CONFIG_PARA="${CONFIG_PARA} --enable-avresample"
if [ "Debug" = "$RABBIT_CONFIG" ]; then
    CONFIG_PARA="${CONFIG_PARA} --disable-stripping --enable-debug "
else
    CONFIG_PARA="${CONFIG_PARA} --disable-debug --enable-stripping"
fi
CFLAGS="${CFLAGS} -I$RABBIT_BUILD_PREFIX/include" 
LDFLAGS="${LDFLAGS} -L$RABBIT_BUILD_PREFIX/lib" 


case ${BUILD_TARGERT} in
    android)
        echo "./configure ${CONFIG_PARA} --extra-cflags=\"${CFLAGS}\" --extra-ldflags=\"${LDFLAGS}\"" --pkg-config="\"${PKG_CONFIG}\""
        ./configure ${CONFIG_PARA} --extra-cflags="${CFLAGS}" --extra-ldflags="${LDFLAGS}" --pkg-config="${PKG_CONFIG}"
        ;;
    windows_mingw)
        case `uname -s` in
            Linux*|Unix*|CYGWIN*|*)
            echo "./configure ${CONFIG_PARA} --extra-cflags=\"${CFLAGS}\" --extra-ldflags=\"${LDFLAGS}\"" --pkg-config="\"${PKG_CONFIG}\""
            ./configure ${CONFIG_PARA} --extra-cflags="${CFLAGS}" --extra-ldflags="${LDFLAGS}" --pkg-config="${PKG_CONFIG}"
            ;;
        esac
        ;;
    *)
        echo "./configure ${CONFIG_PARA} --extra-cflags=\"${CFLAGS}\" --extra-ldflags=\"${LDFLAGS}\""
        ./configure ${CONFIG_PARA} --extra-cflags="${CFLAGS}" --extra-ldflags="${LDFLAGS}"
        ;;
esac

echo "make install"
make ${BUILD_JOB_PARA} V=1
make install
if [ "${BUILD_TARGERT}" = "windows_msvc" ]; then
    if [ "${RABBIT_BUILD_STATIC}" = "static" ]; then
        cd ${RABBIT_BUILD_PREFIX}/lib
        mv libavcodec.a avcodec.lib
        mv libavutil.a avutil.lib
        mv libpostproc.a postproc.lib
        mv libavfilter.a avfilter.lib
        mv libswresample.a swresample.lib
        mv libavformat.a avformat.lib
        mv libswscale.a swscale.lib
        if [ -f libavresample.a ]; then
            mv libavresample.a avresample.lib
        fi
    else
        mv ${RABBIT_BUILD_PREFIX}/bin/*.lib ${RABBIT_BUILD_PREFIX}/lib/.
    fi
fi

if [ "${BUILD_TARGERT}" = "windows_mingw" ]; then
    if [ "${RABBIT_BUILD_STATIC}" != "static" ]; then
        mv ${RABBIT_BUILD_PREFIX}/bin/*.lib ${RABBIT_BUILD_PREFIX}/lib/.
    fi
fi

cd $CUR_DIR
