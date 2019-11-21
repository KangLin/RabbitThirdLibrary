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
#    $DIR:源码的位置 

#运行本脚本前,先运行 build_unix_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix）
#   RABBIT_BUILD_PREFIX=`pwd`/../${BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_SOURCE_CODE    #源码目录
#   RABBIT_BUILD_CROSS_PREFIX     #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

set -ev
HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"
DIR=$2
case $1 in
    android|windows_msvc|windows_mingw|unix)
    BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    echo ". `pwd`/build_envsetup_${BUILD_TARGERT}.sh"
    . `pwd`/build_envsetup_${BUILD_TARGERT}.sh
fi
TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        case $1 in
            windows_msvc)
                export PATH=/mingw32/bin:$PATH #因为msys2下的工具不识别winodws路径，所以用mingw32下的工具
                ;;
            windows_mingw|android)
                export PATH=/usr/bin:$PATH
                ;;
        esac
        ;;
 esac

#产生修改前缀脚本
./change_prefix.sh

if [ -n "$DIR" ]; then
    ./build_zlib.sh ${BUILD_TARGERT} $DIR/zlib
    ./build_minizip.sh ${BUILD_TARGERT} $DIR/minizip
    ./build_expat.sh ${BUILD_TARGERT} $DIR/expat
    ./build_libgpx.sh ${BUILD_TARGERT} $DIR/libgpx
    ./build_openssl.sh ${BUILD_TARGERT} $DIR/openssl
    #./build_libsodium.sh ${BUILD_TARGERT} $DIR/libsodium
    #./build_boost.sh ${BUILD_TARGERT} $DIR/boost
    #./build_protobuf.sh ${BUILD_TARGERT} $DIR/protobuf
    #./build_berkeleydb.sh ${BUILD_TARGERT} $DIR/berkeleydb
    ./build_libcurl.sh ${BUILD_TARGERT} $DIR/curl
    ./build_libpng.sh ${BUILD_TARGERT} $DIR/libpng
    ./build_jpeg.sh ${BUILD_TARGERT} $DIR/libjpeg
    ./build_libgif.sh ${BUILD_TARGERT} $DIR/libgif
    ./build_libtiff.sh ${BUILD_TARGERT} $DIR/libtiff
    ./build_freetype.sh ${BUILD_TARGERT} $DIR/freetype
    ./build_libqrencode.sh ${BUILD_TARGERT} $DIR/libqrencode
    #./build_ogg.sh ${BUILD_TARGERT} $DIR/ogg
    #./build_speex.sh ${BUILD_TARGERT} $DIR/speex
    #./build_x264.sh ${BUILD_TARGERT} $DIR/x264
    ./build_libyuv.sh ${BUILD_TARGERT} $DIR/libyuv
    ./build_libvpx.sh ${BUILD_TARGERT} $DIR/libvpx
    ./build_ffmpeg.sh ${BUILD_TARGERT} $DIR/ffmpeg
    ./build_libopus.sh ${BUILD_TARGERT} $DIR/libopus
    #./build_opencv.sh ${BUILD_TARGERT} $DIR/opencv
    #./build_dlib.sh ${BUILD_TARGERT} $DIR/dlib
    #./build_geos.sh ${BUILD_TARGERT} $DIR/geos
    #./build_gdal.sh ${BUILD_TARGERT} $DIR/gdal
    #./build_osg.sh ${BUILD_TARGERT} $DIR/osg
    #./build_OsgQt.sh ${BUILD_TARGERT} $DIR/osgQt
    #./build_osgearth.sh ${BUILD_TARGERT} $DIR/osgearth
    #./build_qt.sh ${BUILD_TARGERT} $DIR/qt5
    ./build_qxmpp.sh ${BUILD_TARGERT} $DIR/qxmpp 
    ./build_qzxing.sh ${BUILD_TARGERT} $DIR/qzxing
else
    ./build_zlib.sh ${BUILD_TARGERT} 
    ./build_minizip.sh ${BUILD_TARGERT}
    ./build_expat.sh ${BUILD_TARGERT}
    ./build_openssl.sh ${BUILD_TARGERT} 
    ./build_libsodium.sh ${BUILD_TARGERT} 
    ./build_boost.sh ${BUILD_TARGERT} 
    ./build_protobuf.sh ${BUILD_TARGERT}
    ./build_berkeleydb.sh ${BUILD_TARGERT} 
    ./build_libcurl.sh ${BUILD_TARGERT} 
    ./build_libpng.sh ${BUILD_TARGERT} 
    ./build_jpeg.sh ${BUILD_TARGERT} 
    ./build_libgif.sh ${BUILD_TARGERT}
    ./build_libtiff.sh ${BUILD_TARGERT}
    ./build_freetype.sh ${BUILD_TARGERT}
    ./build_libqrencode.sh ${BUILD_TARGERT}
    ./build_x264.sh ${BUILD_TARGERT} 
    ./build_libyuv.sh ${BUILD_TARGERT} 
    ./build_libvpx.sh ${BUILD_TARGERT} 
    ./build_ffmpeg.sh ${BUILD_TARGERT} 
    ./build_libopus.sh ${BUILD_TARGERT} 
    ./build_opencv.sh ${BUILD_TARGERT}
    ./build_geos.sh ${BUILD_TARGERT} 
    ./build_gdal.sh ${BUILD_TARGERT} 
    ./build_osg.sh ${BUILD_TARGERT}
    ./build_OsgQt.sh ${BUILD_TARGERT}
    ./build_osgearth.sh ${BUILD_TARGERT}
    #./build_qt.sh ${BUILD_TARGERT}
    ./build_qxmpp.sh ${BUILD_TARGERT}
    ./build_qzxing.sh ${BUILD_TARGERT} 
fi
