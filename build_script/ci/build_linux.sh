#!/bin/bash
set -e

RABBIT_LIBRARYS_before[0]="zlib"
RABBIT_LIBRARYS_backgroud[0]="protobuf libpng jpeg libyuv libvpx libopus speexdsp speex seeta libfacedetection ncnn"
RABBIT_LIBRARYS[0]="change_prefix openssl ffmpeg dlib opencv"
#RABBIT_LIBRARYS_backgroud[1]=""
RABBIT_LIBRARYS[1]="qxmpp qzxing"

SOURCE_DIR=$(cd `dirname $0`; pwd)/../..
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi
TOOLS_DIR=${SOURCE_DIR}/Tools
export RABBIT_BUILD_PREFIX=${SOURCE_DIR}/build

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

cd ${SOURCE_DIR}

if [ "$BUILD_TARGERT" = "android" ]; then
    if [ -n "${ANDROID_HOME}" ]; then
        export ANDROID_SDK_ROOT=${ANDROID_HOME}
    else
        export ANDROID_SDK_ROOT=${TOOLS_DIR}/android-sdk
    fi
    export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-ndk
    if [ -n "$APPVEYOR" ]; then
        #export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
        export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-sdk/ndk-bundle
    fi
    #if [ "$TRAVIS" = "true" ]; then
        #export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    #fi
    if [ -z "${JAVA_HOME}" -a -d ${TOOLS_DIR}/android-studio/jre ]; then
        export JAVA_HOME=${TOOLS_DIR}/android-studio/jre
    fi
    
    if version_ge $QT_VERSION_DIR 5.14 ; then
        export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android
    else
        case $BUILD_ARCH in
            arm)
                QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_armv7
                ;;
            arm64)
                QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_arm64_v8a/
                ;;
            x86)
                QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_x86
                ;;
            x86_64)
                QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_x86_64
                ;;
        esac
        if [ -d ${QT_ROOT} ]; then
            export QT_ROOT=${QT_ROOT}
        else
            export QT_ROOT=
        fi
    fi
    export PATH=${TOOLS_DIR}/apache-ant/bin:$JAVA_HOME/bin:$PATH
    export ANDROID_SDK=${ANDROID_SDK_ROOT}
    export ANDROID_NDK=${ANDROID_NDK_ROOT}
fi

if [ "${BUILD_TARGERT}" = "unix" ]; then
    if [ "$DOWNLOAD_QT" = "APT" ]; then
        export QT_ROOT=/usr/lib/`uname -m`-linux-gnu/qt5
        export QT_VERSION=`${QT_ROOT}/bin/qmake -query QT_VERSION`
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
echo "=== PATH:$PATH"
echo "=== PKG_CONFIG:$PKG_CONFIG"
cd ${SOURCE_DIR}/build_script

bash ci/backgroud_echo.sh &

for b in ${RABBIT_LIBRARYS_before[$RABBIT_NUMBER]}
do
    bash ./build_$b.sh ${BUILD_TARGERT} > /dev/null
done

for b in ${RABBIT_LIBRARYS_backgroud[$RABBIT_NUMBER]}
do
    bash ./build_$b.sh ${BUILD_TARGERT} > /dev/null &
done

for v in ${RABBIT_LIBRARYS[$RABBIT_NUMBER]}
do
    echo "bash ./build_$v.sh ${BUILD_TARGERT}"
    bash ./build_$v.sh ${BUILD_TARGERT} > /dev/null
done

echo "RABBIT_LIBRARYS size:${#RABBIT_LIBRARYS[@]}"
if [ ${#RABBIT_LIBRARYS[@]} -eq `expr $RABBIT_NUMBER + 1` ]; then
    if [ "$TRAVIS_TAG" != "" ]; then
        TAR_NAME=${BUILD_TARGERT}_${BUILD_ARCH}
        if [ -n "$QT_VERSION" ]; then
            TAR_NAME=${TAR_NAME}_Qt${QT_VERSION}
        fi
        if [ -n "${TRAVIS_TAG}" ]; then
            TAR_NAME=${TAR_NAME}_${TRAVIS_TAG}
        fi
        if [ "$BUILD_TARGERT" = "android" ]; then
            TAR_FILE=${TAR_NAME}_in_linux.tar.gz
        else
            TAR_FILE=${TAR_NAME}.tar.gz
        fi
        #cd $(dirname ${RABBIT_BUILD_PREFIX})
        cd ${RABBIT_BUILD_PREFIX}
        tar czfv ${SOURCE_DIR}/${TAR_FILE} .
        export UPLOADTOOL_BODY="Release ${TRAVIS_TAG}"
        wget -c https://github.com/probonopd/uploadtool/raw/master/upload.sh
        chmod u+x upload.sh
        ./upload.sh ${SOURCE_DIR}/${TAR_FILE}
    fi
fi
