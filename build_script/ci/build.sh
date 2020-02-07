#!/bin/bash
set -ev

SOURCE_DIR=$(cd `dirname $0`; pwd)/../..
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi
TOOLS_DIR=${SOURCE_DIR}/Tools
export RABBIT_BUILD_PREFIX=${SOURCE_DIR}/${BUILD_TARGERT}${TOOLCHAIN_VERSION}
if [ -n "$BUILD_ARCH" ]; then
    export RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}_${BUILD_ARCH}
fi

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

cd ${SOURCE_DIR}

if [ "$BUILD_TARGERT" = "android" ]; then
    export ANDROID_SDK_ROOT=${TOOLS_DIR}/android-sdk
    export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-ndk
    if [ -n "$APPVEYOR" ]; then
        #export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
        export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-sdk/ndk-bundle
    fi
    #if [ "$TRAVIS" = "true" ]; then
        #export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    #fi
    export JAVA_HOME=${TOOLS_DIR}/android-studio/jre
    
    if version_ge $QT_VERSION_DIR 5.14 ; then
        export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android
    else
        case $BUILD_ARCH in
            arm*)
                export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_armv7
                ;;
            x86)
            export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_x86
            ;;
        esac
    fi
    export PATH=${TOOLS_DIR}/apache-ant/bin:$JAVA_HOME/bin:$PATH
    export ANDROID_SDK=${ANDROID_SDK_ROOT}
    export ANDROID_NDK=${ANDROID_NDK_ROOT}
fi

if [ "${BUILD_TARGERT}" = "unix" ]; then
    if [ "$DOWNLOAD_QT" = "APT" ]; then
        export QT_ROOT=/usr/lib/`uname -m`-linux-gnu/qt5
    elif [ "$DOWNLOAD_QT" = "TRUE" ]; then
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

if [ "$BUILD_TARGERT" != "windows_msvc" ]; then
    RABBIT_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBIT_MAKE_JOB_PARA" = "-j1" ];then
        RABBIT_MAKE_JOB_PARA=""
    fi
fi

if [ "$BUILD_TARGERT" = "windows_mingw" \
    -a -n "$APPVEYOR" ]; then
    export PATH=/C/Qt/Tools/mingw${TOOLCHAIN_VERSION}/bin:$PATH
fi

if [ "$BUILD_TARGERT" = "windows_msvc" ]; then
    export PATH=/C/Perl/bin:$PATH
fi

TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        export PKG_CONFIG=/c/msys64/mingw32/bin/pkg-config.exe
        RABBIT_BUILD_HOST="windows"
        if [ "$BUILD_TARGERT" = "android" ]; then
            ANDROID_NDK_HOST=windows-x86_64
            if [ ! -d $ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST} ]; then
                ANDROID_NDK_HOST=windows
            fi
            CONFIG_PARA="${CONFIG_PARA} -DCMAKE_MAKE_PROGRAM=make" #${ANDROID_NDK}/prebuilt/${ANDROID_NDK_HOST}/bin/make.exe"
        fi
        ;;
    Linux* | Unix*)
    ;;
    *)
    ;;
esac

export PATH=${QT_ROOT}/bin:$PATH
echo "PATH:$PATH"
echo "PKG_CONFIG:$PKG_CONFIG"
cd ${SOURCE_DIR}/build_script


bash ci/backgroud_echo.sh &

./build_zlib.sh ${BUILD_TARGERT} > /dev/null
#./build_openblas.sh ${BUILD_TARGERT} > /dev/null
./build_openssl.sh ${BUILD_TARGERT} > /dev/null
#./build_libpng.sh ${BUILD_TARGERT} > /dev/null
#./build_jpeg.sh ${BUILD_TARGERT} > /dev/null
#./build_libgif.sh ${BUILD_TARGERT} > /dev/null
#./build_libtiff.sh ${BUILD_TARGERT} > /dev/null
./build_libyuv.sh ${BUILD_TARGERT} > /dev/null
./build_libvpx.sh ${BUILD_TARGERT} > /dev/null
./build_libopus.sh ${BUILD_TARGERT} > /dev/null
#./build_speexdsp.sh ${BUILD_TARGERT} > /dev/null
#./build_speex.sh ${BUILD_TARGERT} > /dev/null
#./build_ffmpeg.sh ${BUILD_TARGERT} > /dev/null
./build_opencv.sh ${BUILD_TARGERT} > /dev/null
#./build_seeta.sh ${BUILD_TARGERT} > /dev/null
#./build_dlib.sh ${BUILD_TARGERT} > /dev/null
#./build_qxmpp.sh ${BUILD_TARGERT}
#./build_qzxing.sh ${BUILD_TARGERT}

#if [ "$TRAVIS_TAG" != "" ]; then
    . build_envsetup_${BUILD_TARGERT}.sh
    TAR_NAME=$(basename ${RABBIT_BUILD_PREFIX})
    TAR_FILE=${TAR_NAME}.tar.gz
    #cd $(dirname ${RABBIT_BUILD_PREFIX})
    cd ${RABBIT_BUILD_PREFIX}
    tar czfv ../${TAR_FILE} .
#    wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
#    chmod u+x upload.sh
#    ./upload.sh ${TAR_FILE}
#fi
