#!/bin/bash

#bash用法：
#   在用一sh进程中执行脚本script.sh:
#   source script.sh
#   . script.sh
#   注意这种用法，script.sh开头一行不能包含 #!/bin/bash

#   新建一个sh进程执行脚本script.sh:
#   sh script.sh
#   ./script.sh
#   注意这种用法，script.sh开头一行必须包含 #!/bin/bash

#作者：康林

#参数:
#    $1:编译目标
#    $2:源码的位置 

#运行本脚本前,先运行 build_unix_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBIT_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
#   RABBIT_BUILD_PREFIX=`pwd`/../${RABBIT_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_SOURCE_CODE    #源码目录
#   RABBIT_BUILD_CROSS_PREFIX     #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -e
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

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
TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        case $1 in
            windows_msvc)
                export PATH=/mingw32/bin:$PATH #因为mingw32下的工具不识别winodws路径，所以用mingw32下的工具
                ;;
            windows_mingw)
                export PATH=/usr/bin:$PATH
                ;;
        esac
        ;;
 esac

#产生修改前缀脚本
./change_prefix.sh

if [ -n "$2" ]; then
    ./build_zlib.sh ${RABBIT_BUILD_TARGERT} $2/zlib 
    ./build_minizip.sh ${RABBIT_BUILD_TARGERT} $2/minizip
    ./build_openssl.sh ${RABBIT_BUILD_TARGERT} $2/openssl 
    ./build_libsodium.sh ${RABBIT_BUILD_TARGERT} $2/libsodium
    ./build_libcurl.sh ${RABBIT_BUILD_TARGERT} $2/curl 
    ./build_libpng.sh ${RABBIT_BUILD_TARGERT} $2/libpng
    ./build_jpeg.sh ${RABBIT_BUILD_TARGERT} $2/libjpeg
    ./build_libgif.sh ${RABBIT_BUILD_TARGERT} $2/libgif
    ./build_libtiff.sh ${RABBIT_BUILD_TARGERT} $2/libtiff
    ./build_freetype.sh ${RABBIT_BUILD_TARGERT} $2/freetype
    ./build_libqrencode.sh ${RABBIT_BUILD_TARGERT} $2/libqrencode
    ./build_x264.sh ${RABBIT_BUILD_TARGERT} $2/x264 
    ./build_libyuv.sh ${RABBIT_BUILD_TARGERT} $2/libyuv 
    ./build_libvpx.sh ${RABBIT_BUILD_TARGERT} $2/libvpx 
    ./build_ffmpeg.sh ${RABBIT_BUILD_TARGERT} $2/ffmpeg 
    ./build_libopus.sh ${RABBIT_BUILD_TARGERT} $2/libopus 
    ./build_opencv.sh ${RABBIT_BUILD_TARGERT} $2/opencv
    ./build_gdal.sh ${RABBIT_BUILD_TARGERT} $2/gdal
    ./build_osg.sh ${RABBIT_BUILD_TARGERT} $2/osg
    #./build_geos.sh ${RABBIT_BUILD_TARGERT} $2/geos
    ./build_OsgQt.sh ${RABBIT_BUILD_TARGERT} $2/osgQt
    ./build_osgearth.sh ${RABBIT_BUILD_TARGERT} $2/osgearth
    #./build_qt.sh ${RABBIT_BUILD_TARGERT} $2/qt5 
    ./build_qxmpp.sh ${RABBIT_BUILD_TARGERT} $2/qxmpp 
    ./build_qzxing.sh ${RABBIT_BUILD_TARGERT} $2/qzxing
else
    ./build_zlib.sh ${RABBIT_BUILD_TARGERT} 
    ./build_minizip.sh ${RABBIT_BUILD_TARGERT}
    ./build_openssl.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libsodium.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libcurl.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libpng.sh ${RABBIT_BUILD_TARGERT} 
    ./build_jpeg.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libgif.sh ${RABBIT_BUILD_TARGERT}
    ./build_libtiff.sh ${RABBIT_BUILD_TARGERT}
    ./build_freetype.sh ${RABBIT_BUILD_TARGERT}
    ./build_libqrencode.sh ${RABBIT_BUILD_TARGERT}
    ./build_x264.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libyuv.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libvpx.sh ${RABBIT_BUILD_TARGERT} 
    ./build_ffmpeg.sh ${RABBIT_BUILD_TARGERT} 
    ./build_libopus.sh ${RABBIT_BUILD_TARGERT} 
    ./build_opencv.sh ${RABBIT_BUILD_TARGERT}
    ./build_gdal.sh ${RABBIT_BUILD_TARGERT} 
    ./build_osg.sh ${RABBIT_BUILD_TARGERT}
    ./build_OsgQt.sh ${RABBIT_BUILD_TARGERT}
    #./build_geos.sh ${RABBIT_BUILD_TARGERT} 
    ./build_osgearth.sh ${RABBIT_BUILD_TARGERT}
    #./build_qt.sh ${RABBIT_BUILD_TARGERT}
    ./build_qxmpp.sh ${RABBIT_BUILD_TARGERT}
    ./build_qzxing.sh ${RABBIT_BUILD_TARGERT} 
fi


exit 0


if [ -n "$2" ]; then
    echo "Source dir:$2"
    if [ "${RABBIT_BUILD_TARGERT}" != "windows_msvc" ]; then
        echo "building ......"
        ./build_libopus.sh ${RABBIT_BUILD_TARGERT} $2/libopus && \
        ./build_speexdsp.sh ${RABBIT_BUILD_TARGERT} $2/speexdsp && \
        ./build_speex.sh ${RABBIT_BUILD_TARGERT} $2/speex && \
        ./build_libsodium.sh ${RABBIT_BUILD_TARGERT} $2/libsodium && \
        ./build_filter_audio.sh ${RABBIT_BUILD_TARGERT} $2/filter_audio && \
        ./build_toxcore.sh ${RABBIT_BUILD_TARGERT} $2/toxcore
    fi
    ./build_opencv.sh ${RABBIT_BUILD_TARGERT} $2/opencv && \
    # ./build_pjsip.sh ${RABBIT_BUILD_TARGERT} $2/pjsip && \
    # ./build_icu.sh ${RABBIT_BUILD_TARGERT} $2/icu && \
    ./build_gdal.sh ${RABBIT_BUILD_TARGERT} $2/gdal && \
    ./build_osg.sh ${RABBIT_BUILD_TARGERT} $2/osg && \
    ./build_osgearth.sh ${RABBIT_BUILD_TARGERT} $2/osgearth
else
    if [ "${RABBIT_BUILD_TARGERT}" != "windows_msvc" ]; then
        ./build_libqrencode.sh ${RABBIT_BUILD_TARGERT} && \
        ./build_speexdsp.sh ${RABBIT_BUILD_TARGERT} && \
        ./build_speex.sh ${RABBIT_BUILD_TARGERT} && \
        ./build_libopus.sh ${RABBIT_BUILD_TARGERT} && \
        ./build_libsodium.sh ${RABBIT_BUILD_TARGERT} && \
        ./build_toxcore.sh ${RABBIT_BUILD_TARGERT}
    fi
    ./build_opencv.sh ${RABBIT_BUILD_TARGERT} && \
    # ./build_pjsip.sh ${RABBIT_BUILD_TARGERT} && \
    # ./build_icu.sh ${RABBIT_BUILD_TARGERT} && \
    ./build_gdal.sh ${RABBIT_BUILD_TARGERT} && \
    ./build_osg.sh ${RABBIT_BUILD_TARGERT} && \
    ./build_osgearth.sh ${RABBIT_BUILD_TARGERT}
fi
