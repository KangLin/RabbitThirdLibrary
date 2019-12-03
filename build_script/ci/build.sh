#!/bin/bash
set -ev

SOURCE_DIR=$(cd `dirname $0`; pwd)/../..
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi
TOOLS_DIR=${SOURCE_DIR}/Tools

cd ${SOURCE_DIR}

if [ "$BUILD_TARGERT" = "android" ]; then
    export ANDROID_SDK_ROOT=${TOOLS_DIR}/android-sdk
    export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-ndk
    if [ -n "$APPVEYOR" ]; then
        export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
        export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-sdk/ndk-bundle
    fi
    if [ "$TRAVIS" = "true" ]; then
        export JAVA_HOME=${TOOLS_DIR}/android-studio/jre
        #export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    fi
    case $BUILD_ARCH in
        arm*)
            export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_armv7
            ;;
        x86)
            export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_x86
            ;;
    esac
    export PATH=${TOOLS_DIR}/apache-ant/bin:$JAVA_HOME:$PATH
    export ANDROID_SDK=${ANDROID_SDK_ROOT}
    export ANDROID_NDK=${ANDROID_NDK_ROOT}
fi

if [ "${BUILD_TARGERT}" = "unix" ]; then
    if [ "$DOWNLOAD_QT" = "TRUE" ]; then
        QT_DIR=${TOOLS_DIR}/Qt/${QT_VERSION}
        export QT_ROOT=${QT_DIR}/${QT_VERSION}/gcc_64
    else
        #source /opt/qt${QT_VERSION_DIR}/bin/qt${QT_VERSION_DIR}-env.sh
        export QT_ROOT=/opt/qt${QT_VERSION_DIR}
    fi
    export PATH=$QT_ROOT/bin:$PATH
    export LD_LIBRARY_PATH=$QT_ROOT/lib/i386-linux-gnu:$QT_ROOT/lib:$LD_LIBRARY_PATH
    export PKG_CONFIG_PATH=$QT_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
fi

if [ "$BUILD_TARGERT" = "windows_mingw" \
    -a -n "$APPVEYOR" ]; then
    export PATH=/C/Qt/Tools/mingw${TOOLCHAIN_VERSION}/bin:$PATH
fi

if [ "$BUILD_TARGERT" = "windows_msvc" ]; then
    export PATH=/C/Perl/bin:$PATH
fi

export PATH=${QT_ROOT}/bin:$PATH
echo "PATH:$PATH"
echo "PKG_CONFIG:$PKG_CONFIG"
cd ${SOURCE_DIR}/build_script

./build_zlib.sh ${BUILD_TARGERT} > /dev/null
./build_openssl.sh ${BUILD_TARGERT} > /dev/null
./build_libpng.sh ${BUILD_TARGERT} > /dev/null
./build_jpeg.sh ${BUILD_TARGERT} > /dev/null
./build_libgif.sh ${BUILD_TARGERT} > /dev/null
./build_libtiff.sh ${BUILD_TARGERT} > /dev/null
./build_libyuv.sh ${BUILD_TARGERT} > /dev/null
./build_libvpx.sh ${BUILD_TARGERT} > /dev/null
./build_libopus.sh ${BUILD_TARGERT} > /dev/null
./build_speex.sh ${BUILD_TARGERT} > /dev/null
./build_ffmpeg.sh ${BUILD_TARGERT} > /dev/null
./build_opencv.sh ${BUILD_TARGERT} #> /dev/null
./build_dlib.sh ${BUILD_TARGERT}
#./build_qxmpp.sh ${BUILD_TARGERT}
#./build_qzxing.sh ${BUILD_TARGERT}

if [ "$TRAVIS_TAG" != "" ]; then
    . build_envsetup_${BUILD_TARGERT}.sh
    TAR_FILE=$(basename ${RABBIT_BUILD_PREFIX}).tar.gz
    cd $(dirname ${RABBIT_BUILD_PREFIX})
    tar czf ${TAR_FILE} $(basename ${RABBIT_BUILD_PREFIX})
    wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
    chmod u+x upload.sh
    ./upload.sh ${TAR_FILE}
fi
